-- ============================================================
-- PROMPT 3/8: Production Recovery & Enhancement Migration
-- Repairs DB integrity, adds indexes, fixes RLS, adds global search support
-- ============================================================

-- 1. Ensure loans_receivable table exists (from prompt 2/8, safe to re-run)
CREATE TABLE IF NOT EXISTS public.loans_receivable (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  borrower_name TEXT NOT NULL,
  borrower_contact TEXT,
  amount NUMERIC(15,2) NOT NULL DEFAULT 0,
  interest_rate NUMERIC(5,2) DEFAULT 0,
  date_given DATE NOT NULL DEFAULT CURRENT_DATE,
  due_date DATE,
  remaining_balance NUMERIC(15,2) NOT NULL DEFAULT 0,
  total_repaid NUMERIC(15,2) NOT NULL DEFAULT 0,
  currency TEXT DEFAULT 'TZS',
  loan_status TEXT DEFAULT 'active' CHECK (loan_status IN ('active','partially_paid','paid','overdue','defaulted')),
  notes TEXT,
  related_transaction_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.loan_receivable_repayments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  loan_receivable_id UUID NOT NULL REFERENCES public.loans_receivable(id) ON DELETE CASCADE,
  amount NUMERIC(15,2) NOT NULL,
  payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Add missing columns to financial_transactions (safe with IF NOT EXISTS)
ALTER TABLE public.financial_transactions
  ADD COLUMN IF NOT EXISTS related_business_id UUID,
  ADD COLUMN IF NOT EXISTS related_investment_id UUID,
  ADD COLUMN IF NOT EXISTS related_loan_id UUID,
  ADD COLUMN IF NOT EXISTS related_loan_receivable_id UUID,
  ADD COLUMN IF NOT EXISTS related_goal_id UUID,
  ADD COLUMN IF NOT EXISTS related_module TEXT,
  ADD COLUMN IF NOT EXISTS related_entity_id UUID,
  ADD COLUMN IF NOT EXISTS is_archived BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS reference_id TEXT;

-- 3. Add missing columns to financial_goals (safe)
ALTER TABLE public.financial_goals
  ADD COLUMN IF NOT EXISTS priority TEXT DEFAULT 'medium' CHECK (priority IN ('low','medium','high','critical')),
  ADD COLUMN IF NOT EXISTS funding_source TEXT,
  ADD COLUMN IF NOT EXISTS funding_account_id UUID,
  ADD COLUMN IF NOT EXISTS color TEXT DEFAULT '#1A5F7A',
  ADD COLUMN IF NOT EXISTS icon TEXT DEFAULT 'flag',
  ADD COLUMN IF NOT EXISTS goal_status TEXT DEFAULT 'active' CHECK (goal_status IN ('active','paused','completed','archived'));

-- 4. Performance indexes
CREATE INDEX IF NOT EXISTS idx_financial_transactions_user_date
  ON public.financial_transactions(user_id, transaction_date DESC);

CREATE INDEX IF NOT EXISTS idx_financial_transactions_user_type
  ON public.financial_transactions(user_id, transaction_type);

CREATE INDEX IF NOT EXISTS idx_financial_transactions_user_archived
  ON public.financial_transactions(user_id, is_archived);

CREATE INDEX IF NOT EXISTS idx_financial_transactions_related_business
  ON public.financial_transactions(related_business_id) WHERE related_business_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_financial_transactions_related_loan
  ON public.financial_transactions(related_loan_id) WHERE related_loan_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_assets_user_status
  ON public.assets(user_id, asset_status);

CREATE INDEX IF NOT EXISTS idx_loans_user_status
  ON public.loans(user_id, status);

CREATE INDEX IF NOT EXISTS idx_loans_receivable_user_status
  ON public.loans_receivable(user_id, loan_status);

-- businesses uses owner_id (not user_id)
CREATE INDEX IF NOT EXISTS idx_businesses_owner_active
  ON public.businesses(owner_id, is_active);

-- investments index: wrapped in DO block in case the table does not yet exist
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'investments'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_indexes
      WHERE schemaname = 'public' AND tablename = 'investments' AND indexname = 'idx_investments_owner'
    ) THEN
      CREATE INDEX idx_investments_owner ON public.investments(owner_id);
    END IF;
  END IF;
END;
$$;

CREATE INDEX IF NOT EXISTS idx_net_worth_snapshots_user_date
  ON public.net_worth_snapshots(user_id, snapshot_date DESC);

-- 5. RLS Policies for loans_receivable
ALTER TABLE public.loans_receivable ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loan_receivable_repayments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "loans_receivable_user_policy" ON public.loans_receivable;
CREATE POLICY "loans_receivable_user_policy" ON public.loans_receivable
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "loan_receivable_repayments_user_policy" ON public.loan_receivable_repayments;
CREATE POLICY "loan_receivable_repayments_user_policy" ON public.loan_receivable_repayments
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 6. Repair calculate_net_worth RPC to include all asset types
CREATE OR REPLACE FUNCTION public.calculate_net_worth(p_user_id UUID)
RETURNS TABLE(total_assets NUMERIC, total_liabilities NUMERIC, net_worth NUMERIC)
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_cash NUMERIC := 0;
  v_asset_value NUMERIC := 0;
  v_investment_value NUMERIC := 0;
  v_receivables NUMERIC := 0;
  v_loans NUMERIC := 0;
  v_total_assets NUMERIC := 0;
  v_total_liabilities NUMERIC := 0;
BEGIN
  -- Cash from accounts (calculated balances)
  SELECT COALESCE(SUM(
    COALESCE(fa.balance, 0) +
    COALESCE((SELECT SUM(CASE WHEN ft.transaction_type = 'income' THEN ft.amount ELSE -ft.amount END)
              FROM financial_transactions ft
              WHERE ft.account_id = fa.id AND ft.is_archived = FALSE AND ft.status != 'cancelled'), 0)
  ), 0) INTO v_cash
  FROM financial_accounts fa
  WHERE fa.user_id = p_user_id AND fa.is_active = TRUE AND fa.is_archived = FALSE;

  -- Asset values (assets table uses user_id)
  SELECT COALESCE(SUM(current_value), 0) INTO v_asset_value
  FROM assets
  WHERE user_id = p_user_id AND asset_status != 'disposed';

  -- Investment values (investments table uses owner_id) — guarded in case table absent
  BEGIN
    SELECT COALESCE(SUM(current_value), 0) INTO v_investment_value
    FROM investments
    WHERE owner_id = p_user_id;
  EXCEPTION WHEN undefined_table THEN
    v_investment_value := 0;
  END;

  -- Loan receivables (money owed to user = asset)
  SELECT COALESCE(SUM(remaining_balance), 0) INTO v_receivables
  FROM loans_receivable
  WHERE user_id = p_user_id AND loan_status IN ('active', 'partially_paid', 'overdue');

  -- Loans payable (money user owes = liability)
  SELECT COALESCE(SUM(remaining_balance), 0) INTO v_loans
  FROM loans
  WHERE user_id = p_user_id AND status = 'active';

  v_total_assets := v_cash + v_asset_value + v_investment_value + v_receivables;
  v_total_liabilities := v_loans;

  RETURN QUERY SELECT v_total_assets, v_total_liabilities, (v_total_assets - v_total_liabilities);
END;
$$;

-- 7. Global search function
CREATE OR REPLACE FUNCTION public.global_search(p_user_id UUID, p_query TEXT)
RETURNS TABLE(
  result_type TEXT,
  result_id UUID,
  title TEXT,
  subtitle TEXT,
  amount NUMERIC,
  route TEXT,
  created_at TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_query TEXT := '%' || lower(p_query) || '%';
BEGIN
  -- Search transactions
  RETURN QUERY
  SELECT
    'transaction'::TEXT,
    ft.id,
    COALESCE(ft.description, ft.category) AS title,
    ft.transaction_type AS subtitle,
    ft.amount,
    '/transaction-history-screen'::TEXT,
    ft.created_at
  FROM financial_transactions ft
  WHERE ft.user_id = p_user_id
    AND ft.is_archived = FALSE
    AND (lower(COALESCE(ft.description,'')) LIKE v_query OR lower(ft.category) LIKE v_query)
  ORDER BY ft.created_at DESC
  LIMIT 5;

  -- Search assets (assets uses user_id)
  RETURN QUERY
  SELECT
    'asset'::TEXT,
    a.id,
    a.asset_name AS title,
    a.asset_type AS subtitle,
    a.current_value,
    '/asset-dashboard'::TEXT,
    a.created_at
  FROM assets a
  WHERE a.user_id = p_user_id
    AND (lower(a.asset_name) LIKE v_query OR lower(COALESCE(a.asset_type,'')) LIKE v_query)
  ORDER BY a.created_at DESC
  LIMIT 5;

  -- Search businesses (businesses uses owner_id)
  RETURN QUERY
  SELECT
    'business'::TEXT,
    b.id,
    b.name AS title,
    b.business_type AS subtitle,
    0::NUMERIC,
    '/business-dashboard'::TEXT,
    b.created_at
  FROM businesses b
  WHERE b.owner_id = p_user_id
    AND (lower(b.name) LIKE v_query OR lower(COALESCE(b.business_type,'')) LIKE v_query)
  ORDER BY b.created_at DESC
  LIMIT 5;

  -- Search investments (investments uses owner_id; columns: name, category)
  RETURN QUERY
  SELECT
    'investment'::TEXT,
    i.id,
    i.name AS title,
    i.category AS subtitle,
    COALESCE(i.current_value, 0),
    '/investment-dashboard'::TEXT,
    i.created_at
  FROM investments i
  WHERE i.owner_id = p_user_id
    AND (lower(i.name) LIKE v_query OR lower(COALESCE(i.category,'')) LIKE v_query)
  ORDER BY i.created_at DESC
  LIMIT 5;

  -- Search loans (loans uses user_id)
  RETURN QUERY
  SELECT
    'loan'::TEXT,
    l.id,
    l.loan_name AS title,
    l.loan_category AS subtitle,
    COALESCE(l.remaining_balance, 0),
    '/loan-dashboard'::TEXT,
    l.created_at
  FROM loans l
  WHERE l.user_id = p_user_id
    AND (lower(l.loan_name) LIKE v_query OR lower(COALESCE(l.loan_category,'')) LIKE v_query)
  ORDER BY l.created_at DESC
  LIMIT 5;

  -- Search loan receivables
  RETURN QUERY
  SELECT
    'loan_receivable'::TEXT,
    lr.id,
    lr.borrower_name AS title,
    lr.loan_status AS subtitle,
    COALESCE(lr.remaining_balance, 0),
    '/loans-receivable'::TEXT,
    lr.created_at
  FROM loans_receivable lr
  WHERE lr.user_id = p_user_id
    AND lower(lr.borrower_name) LIKE v_query
  ORDER BY lr.created_at DESC
  LIMIT 5;
END;
$$;

-- 8. Grant execute permissions
GRANT EXECUTE ON FUNCTION public.calculate_net_worth(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.global_search(UUID, TEXT) TO authenticated;
