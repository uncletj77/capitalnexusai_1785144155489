-- ============================================================
-- CAPITAL NEXUS AI — Finance Engine Repair
-- Migration: 20260726180000_finance_engine_repair.sql
-- Repairs: calculated balances, categories, transaction integrity
-- ============================================================

-- ============================================================
-- 1. ADD MISSING COLUMNS TO FINANCIAL_TRANSACTIONS
-- ============================================================

ALTER TABLE public.financial_transactions
  ADD COLUMN IF NOT EXISTS organization_id UUID,
  ADD COLUMN IF NOT EXISTS related_entity_id UUID,
  ADD COLUMN IF NOT EXISTS related_module TEXT,
  ADD COLUMN IF NOT EXISTS currency TEXT NOT NULL DEFAULT 'TZS',
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'completed',
  ADD COLUMN IF NOT EXISTS is_archived BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT ARRAY[]::TEXT[];

-- ============================================================
-- 2. ADD MISSING COLUMNS TO FINANCIAL_ACCOUNTS
-- ============================================================

-- current_balance is calculated; keep balance as initial/manual balance
ALTER TABLE public.financial_accounts
  ADD COLUMN IF NOT EXISTS initial_balance DECIMAL(18,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_archived BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS connection_status TEXT NOT NULL DEFAULT 'manual';

-- Sync initial_balance from existing balance column
UPDATE public.financial_accounts
SET initial_balance = balance
WHERE initial_balance = 0 AND balance != 0;

-- ============================================================
-- 3. TRANSACTION CATEGORIES TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.transaction_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    slug TEXT NOT NULL,
    category_type TEXT NOT NULL DEFAULT 'expense',
    icon TEXT DEFAULT 'category',
    color TEXT DEFAULT '#1A5F7A',
    is_system BOOLEAN NOT NULL DEFAULT false,
    parent_id UUID REFERENCES public.transaction_categories(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_transaction_categories_user_id ON public.transaction_categories(user_id);
CREATE INDEX IF NOT EXISTS idx_transaction_categories_slug ON public.transaction_categories(slug);

ALTER TABLE public.transaction_categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users_manage_own_transaction_categories" ON public.transaction_categories;
CREATE POLICY "users_manage_own_transaction_categories" ON public.transaction_categories
FOR ALL TO authenticated
USING (user_id = auth.uid() OR is_system = true)
WITH CHECK (user_id = auth.uid());

-- ============================================================
-- 4. CALCULATED BALANCE FUNCTION
-- Returns real-time balance = initial_balance + sum of transactions
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_account_balance(p_account_id UUID)
RETURNS DECIMAL(18,2)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT COALESCE(
    (SELECT fa.initial_balance FROM public.financial_accounts fa WHERE fa.id = p_account_id),
    0
  ) +
  COALESCE(
    (SELECT SUM(
      CASE
        WHEN ft.transaction_type IN ('income') THEN ft.amount
        WHEN ft.transaction_type IN ('expense', 'loan_activity') THEN -ft.amount
        ELSE 0
      END
    )
    FROM public.financial_transactions ft
    WHERE ft.account_id = p_account_id
      AND ft.status != 'cancelled'
      AND ft.is_archived = false),
    0
  );
$$;

-- ============================================================
-- 5. NET WORTH CALCULATION FUNCTION
-- Calculates net worth from real assets, accounts, loans
-- ============================================================

CREATE OR REPLACE FUNCTION public.calculate_net_worth(p_user_id UUID)
RETURNS TABLE(
  total_assets DECIMAL(18,2),
  total_liabilities DECIMAL(18,2),
  net_worth DECIMAL(18,2)
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_account_balance DECIMAL(18,2) := 0;
  v_asset_value DECIMAL(18,2) := 0;
  v_loan_balance DECIMAL(18,2) := 0;
BEGIN
  -- Sum all account balances
  SELECT COALESCE(SUM(public.get_account_balance(fa.id)), 0)
  INTO v_account_balance
  FROM public.financial_accounts fa
  WHERE fa.user_id = p_user_id AND fa.is_active = true AND fa.is_archived = false;

  -- Sum all asset values (if assets table exists)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'assets') THEN
    SELECT COALESCE(SUM(a.current_value), 0)
    INTO v_asset_value
    FROM public.assets a
    WHERE a.user_id = p_user_id AND a.asset_status != 'disposed';
  END IF;

  -- Sum all outstanding loan balances (if user_loans table exists)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user_loans') THEN
    SELECT COALESCE(SUM(ul.outstanding_balance), 0)
    INTO v_loan_balance
    FROM public.user_loans ul
    WHERE ul.user_id = p_user_id AND ul.loan_status = 'active';
  END IF;

  total_assets := v_account_balance + v_asset_value;
  total_liabilities := v_loan_balance;
  net_worth := total_assets - total_liabilities;

  RETURN NEXT;
END;
$$;

-- ============================================================
-- 6. CASH FLOW SUMMARY FUNCTION
-- Returns income/expense totals for a date range
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_cash_flow_summary(
  p_user_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE(
  total_income DECIMAL(18,2),
  total_expenses DECIMAL(18,2),
  net_cash_flow DECIMAL(18,2),
  transaction_count INTEGER
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT
    COALESCE(SUM(CASE WHEN ft.transaction_type = 'income' THEN ft.amount ELSE 0 END), 0) AS total_income,
    COALESCE(SUM(CASE WHEN ft.transaction_type = 'expense' THEN ft.amount ELSE 0 END), 0) AS total_expenses,
    COALESCE(SUM(CASE WHEN ft.transaction_type = 'income' THEN ft.amount ELSE -ft.amount END), 0) AS net_cash_flow,
    COUNT(*)::INTEGER AS transaction_count
  FROM public.financial_transactions ft
  WHERE ft.user_id = p_user_id
    AND ft.transaction_date BETWEEN p_start_date AND p_end_date
    AND ft.status != 'cancelled'
    AND ft.is_archived = false;
$$;

-- ============================================================
-- 7. MONTHLY CASH FLOW HISTORY FUNCTION
-- Returns last N months of income/expense data
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_monthly_cash_flow(
  p_user_id UUID,
  p_months INTEGER DEFAULT 6
)
RETURNS TABLE(
  month_year TEXT,
  month_start DATE,
  total_income DECIMAL(18,2),
  total_expenses DECIMAL(18,2),
  net_cash_flow DECIMAL(18,2)
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT
    TO_CHAR(DATE_TRUNC('month', ft.transaction_date), 'Mon YYYY') AS month_year,
    DATE_TRUNC('month', ft.transaction_date)::DATE AS month_start,
    COALESCE(SUM(CASE WHEN ft.transaction_type = 'income' THEN ft.amount ELSE 0 END), 0) AS total_income,
    COALESCE(SUM(CASE WHEN ft.transaction_type = 'expense' THEN ft.amount ELSE 0 END), 0) AS total_expenses,
    COALESCE(SUM(CASE WHEN ft.transaction_type = 'income' THEN ft.amount ELSE -ft.amount END), 0) AS net_cash_flow
  FROM public.financial_transactions ft
  WHERE ft.user_id = p_user_id
    AND ft.transaction_date >= (DATE_TRUNC('month', CURRENT_DATE) - (p_months - 1) * INTERVAL '1 month')::DATE
    AND ft.status != 'cancelled'
    AND ft.is_archived = false
  GROUP BY DATE_TRUNC('month', ft.transaction_date)
  ORDER BY month_start ASC;
$$;

-- ============================================================
-- 8. BUDGET SPENDING FUNCTION
-- Returns actual spending per category for current period
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_budget_spending(
  p_user_id UUID,
  p_period_start DATE,
  p_period_end DATE
)
RETURNS TABLE(
  category TEXT,
  actual_spent DECIMAL(18,2)
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT
    ft.category,
    SUM(ft.amount) AS actual_spent
  FROM public.financial_transactions ft
  WHERE ft.user_id = p_user_id
    AND ft.transaction_type = 'expense'
    AND ft.transaction_date BETWEEN p_period_start AND p_period_end
    AND ft.status != 'cancelled'
    AND ft.is_archived = false
  GROUP BY ft.category;
$$;

-- ============================================================
-- 9. SYSTEM CATEGORIES SEED DATA
-- ============================================================

DO $$
DECLARE
  existing_user_id UUID;
BEGIN
  SELECT id INTO existing_user_id FROM public.user_profiles LIMIT 1;

  -- Insert system income categories (no user_id = system-wide)
  INSERT INTO public.transaction_categories (id, user_id, name, slug, category_type, icon, color, is_system) VALUES
    (gen_random_uuid(), NULL, 'Salary', 'salary', 'income', 'wallet', '#10B981', true),
    (gen_random_uuid(), NULL, 'Business Revenue', 'business', 'income', 'business_center', '#1A5F7A', true),
    (gen_random_uuid(), NULL, 'Rental Income', 'rental', 'income', 'apartment', '#2D9CDB', true),
    (gen_random_uuid(), NULL, 'Investment Return', 'investment', 'income', 'trending_up', '#8B5CF6', true),
    (gen_random_uuid(), NULL, 'Dividends', 'dividends', 'income', 'show_chart', '#4BB8A0', true),
    (gen_random_uuid(), NULL, 'Consulting', 'consulting', 'income', 'work', '#F59E0B', true),
    (gen_random_uuid(), NULL, 'Freelance', 'freelance', 'income', 'laptop', '#EC4899', true),
    (gen_random_uuid(), NULL, 'Other Income', 'other_income', 'income', 'add_circle', '#6B7280', true),
    -- Expense categories
    (gen_random_uuid(), NULL, 'Food & Groceries', 'food', 'expense', 'restaurant', '#EF4444', true),
    (gen_random_uuid(), NULL, 'Transport', 'transport', 'expense', 'directions_car', '#F97316', true),
    (gen_random_uuid(), NULL, 'Fuel', 'fuel', 'expense', 'local_gas_station', '#F59E0B', true),
    (gen_random_uuid(), NULL, 'Utilities', 'utilities', 'expense', 'bolt', '#6B7280', true),
    (gen_random_uuid(), NULL, 'Housing & Rent', 'housing', 'expense', 'home', '#1A5F7A', true),
    (gen_random_uuid(), NULL, 'Healthcare', 'healthcare', 'expense', 'local_hospital', '#EC4899', true),
    (gen_random_uuid(), NULL, 'Education', 'education', 'expense', 'school', '#8B5CF6', true),
    (gen_random_uuid(), NULL, 'Entertainment', 'entertainment', 'expense', 'movie', '#F97316', true),
    (gen_random_uuid(), NULL, 'Salaries & Payroll', 'salaries', 'expense', 'people', '#EF4444', true),
    (gen_random_uuid(), NULL, 'Loan Payment', 'loan_payment', 'expense', 'account_balance', '#DC2626', true),
    (gen_random_uuid(), NULL, 'Insurance', 'insurance', 'expense', 'shield', '#2D9CDB', true),
    (gen_random_uuid(), NULL, 'Maintenance', 'maintenance', 'expense', 'build', '#6B7280', true),
    (gen_random_uuid(), NULL, 'Marketing', 'marketing', 'expense', 'campaign', '#4BB8A0', true),
    (gen_random_uuid(), NULL, 'Subscriptions', 'subscriptions', 'expense', 'subscriptions', '#8B5CF6', true),
    (gen_random_uuid(), NULL, 'Taxes', 'taxes', 'expense', 'receipt_long', '#EF4444', true),
    (gen_random_uuid(), NULL, 'Other Expense', 'other', 'expense', 'more_horiz', '#6B7280', true)
  ON CONFLICT DO NOTHING;

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Category seed failed: %', SQLERRM;
END $$;

-- ============================================================
-- 10. ADDITIONAL INDEXES FOR PERFORMANCE
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_financial_transactions_account_id ON public.financial_transactions(account_id);
CREATE INDEX IF NOT EXISTS idx_financial_transactions_status ON public.financial_transactions(status);
CREATE INDEX IF NOT EXISTS idx_financial_transactions_archived ON public.financial_transactions(is_archived);
CREATE INDEX IF NOT EXISTS idx_financial_transactions_category ON public.financial_transactions(category);
CREATE INDEX IF NOT EXISTS idx_financial_transactions_user_date ON public.financial_transactions(user_id, transaction_date DESC);
