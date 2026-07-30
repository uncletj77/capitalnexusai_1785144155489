-- ============================================================
-- MASTER PROMPT 6A: Core Financial System Rectification
-- Enterprise Data Reconciliation & Registration Engine
-- ============================================================

-- ─── SAVINGS CENTRE ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.savings_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  account_name TEXT NOT NULL,
  savings_type TEXT NOT NULL DEFAULT 'general'
    CHECK (savings_type IN ('general','emergency','goal_linked','fixed_deposit','locked','investment_savings')),
  linked_account_id UUID REFERENCES public.financial_accounts(id) ON DELETE SET NULL,
  linked_goal_id UUID REFERENCES public.financial_goals(id) ON DELETE SET NULL,
  target_amount NUMERIC(20,2) DEFAULT 0,
  current_balance NUMERIC(20,2) DEFAULT 0,
  monthly_contribution NUMERIC(20,2) DEFAULT 0,
  interest_rate NUMERIC(8,4) DEFAULT 0,
  currency TEXT DEFAULT 'TZS',
  start_date DATE DEFAULT CURRENT_DATE,
  target_date DATE,
  auto_transfer BOOLEAN DEFAULT FALSE,
  auto_transfer_day INTEGER DEFAULT 1,
  is_locked BOOLEAN DEFAULT FALSE,
  lock_until DATE,
  notes TEXT,
  color TEXT DEFAULT '#1A5F7A',
  icon TEXT DEFAULT 'savings',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.savings_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  savings_account_id UUID NOT NULL REFERENCES public.savings_accounts(id) ON DELETE CASCADE,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('deposit','withdrawal','interest','transfer_in','transfer_out')),
  amount NUMERIC(20,2) NOT NULL,
  description TEXT,
  source_account_id UUID REFERENCES public.financial_accounts(id) ON DELETE SET NULL,
  related_transaction_id UUID REFERENCES public.financial_transactions(id) ON DELETE SET NULL,
  transaction_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── MASTER ASSET REGISTRY ───────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.master_asset_registry (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  asset_id UUID REFERENCES public.assets(id) ON DELETE CASCADE,
  registry_name TEXT NOT NULL,
  asset_category TEXT NOT NULL,
  asset_subcategory TEXT,
  source_module TEXT NOT NULL
    CHECK (source_module IN ('assets','businesses','investments','accounts','savings','real_estate','vehicles','equipment','agriculture','digital','precious','receivables','other')),
  source_entity_id UUID,
  source_entity_name TEXT,
  current_value NUMERIC(20,2) DEFAULT 0,
  acquisition_cost NUMERIC(20,2) DEFAULT 0,
  acquisition_date DATE,
  currency TEXT DEFAULT 'TZS',
  asset_status TEXT DEFAULT 'active'
    CHECK (asset_status IN ('active','disposed','depreciated','under_maintenance','inactive')),
  performance_score NUMERIC(5,2) DEFAULT 0,
  annual_return NUMERIC(8,4) DEFAULT 0,
  linked_loan_id UUID,
  linked_business_id UUID,
  linked_investment_id UUID,
  is_auto_registered BOOLEAN DEFAULT FALSE,
  last_valuation_date DATE DEFAULT CURRENT_DATE,
  notes TEXT,
  tags TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── FINANCIAL CLOSING ENGINE ────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.financial_closing_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  period_type TEXT NOT NULL CHECK (period_type IN ('daily','weekly','monthly','quarterly','yearly')),
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  period_label TEXT NOT NULL,
  -- Income Analysis
  total_income NUMERIC(20,2) DEFAULT 0,
  income_breakdown JSONB DEFAULT '{}',
  income_vs_prior NUMERIC(8,4) DEFAULT 0,
  -- Expense Analysis
  total_expenses NUMERIC(20,2) DEFAULT 0,
  expense_breakdown JSONB DEFAULT '{}',
  expense_vs_prior NUMERIC(8,4) DEFAULT 0,
  -- Cash Flow
  net_cash_flow NUMERIC(20,2) DEFAULT 0,
  opening_cash NUMERIC(20,2) DEFAULT 0,
  closing_cash NUMERIC(20,2) DEFAULT 0,
  -- Net Worth
  opening_net_worth NUMERIC(20,2) DEFAULT 0,
  closing_net_worth NUMERIC(20,2) DEFAULT 0,
  net_worth_change NUMERIC(20,2) DEFAULT 0,
  -- Savings
  total_savings_added NUMERIC(20,2) DEFAULT 0,
  savings_rate NUMERIC(8,4) DEFAULT 0,
  -- Assets
  total_asset_value NUMERIC(20,2) DEFAULT 0,
  asset_count INTEGER DEFAULT 0,
  -- Business
  business_revenue NUMERIC(20,2) DEFAULT 0,
  business_expenses NUMERIC(20,2) DEFAULT 0,
  business_profit NUMERIC(20,2) DEFAULT 0,
  -- Investments
  portfolio_value NUMERIC(20,2) DEFAULT 0,
  investment_returns NUMERIC(20,2) DEFAULT 0,
  -- Loans
  loan_payables_balance NUMERIC(20,2) DEFAULT 0,
  loan_receivables_balance NUMERIC(20,2) DEFAULT 0,
  repayments_made NUMERIC(20,2) DEFAULT 0,
  repayments_received NUMERIC(20,2) DEFAULT 0,
  -- Goals
  goals_progress JSONB DEFAULT '[]',
  goals_completed INTEGER DEFAULT 0,
  -- KPIs
  financial_health_score INTEGER DEFAULT 0,
  debt_to_income_ratio NUMERIC(8,4) DEFAULT 0,
  savings_to_income_ratio NUMERIC(8,4) DEFAULT 0,
  profit_margin NUMERIC(8,4) DEFAULT 0,
  -- AI Analysis
  ai_executive_summary TEXT,
  ai_key_insights JSONB DEFAULT '[]',
  ai_risks JSONB DEFAULT '[]',
  ai_opportunities JSONB DEFAULT '[]',
  ai_recommendations JSONB DEFAULT '[]',
  -- Forecasts
  next_period_forecast JSONB DEFAULT '{}',
  -- Milestones
  milestones_achieved JSONB DEFAULT '[]',
  -- Metadata
  generated_at TIMESTAMPTZ DEFAULT NOW(),
  is_finalized BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── ENTERPRISE DATA RECONCILIATION ─────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.reconciliation_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reconciliation_type TEXT NOT NULL,
  module TEXT NOT NULL,
  entity_id UUID,
  entity_name TEXT,
  action_taken TEXT NOT NULL,
  old_value JSONB,
  new_value JSONB,
  status TEXT DEFAULT 'completed' CHECK (status IN ('completed','failed','skipped')),
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.financial_calendar_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  event_title TEXT NOT NULL,
  event_type TEXT NOT NULL
    CHECK (event_type IN ('payment_due','income_expected','goal_deadline','loan_maturity','investment_maturity','budget_review','closing_review','reminder','custom')),
  event_date DATE NOT NULL,
  amount NUMERIC(20,2),
  currency TEXT DEFAULT 'TZS',
  related_module TEXT,
  related_entity_id UUID,
  is_recurring BOOLEAN DEFAULT FALSE,
  recurrence_pattern TEXT,
  is_completed BOOLEAN DEFAULT FALSE,
  notes TEXT,
  color TEXT DEFAULT '#1A5F7A',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── ACCOUNT TRANSFERS ───────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.account_transfers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  from_account_id UUID NOT NULL REFERENCES public.financial_accounts(id) ON DELETE CASCADE,
  to_account_id UUID NOT NULL REFERENCES public.financial_accounts(id) ON DELETE CASCADE,
  amount NUMERIC(20,2) NOT NULL,
  fee NUMERIC(20,2) DEFAULT 0,
  exchange_rate NUMERIC(12,6) DEFAULT 1,
  from_currency TEXT DEFAULT 'TZS',
  to_currency TEXT DEFAULT 'TZS',
  description TEXT,
  transfer_date DATE DEFAULT CURRENT_DATE,
  status TEXT DEFAULT 'completed' CHECK (status IN ('pending','completed','failed','reversed')),
  reference_number TEXT,
  from_transaction_id UUID REFERENCES public.financial_transactions(id) ON DELETE SET NULL,
  to_transaction_id UUID REFERENCES public.financial_transactions(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── TRANSACTION AUDIT TRAIL ─────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.transaction_audit_trail (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  transaction_id UUID REFERENCES public.financial_transactions(id) ON DELETE CASCADE,
  action TEXT NOT NULL CHECK (action IN ('created','updated','deleted','archived','restored','reconciled')),
  old_data JSONB,
  new_data JSONB,
  changed_by UUID REFERENCES auth.users(id),
  change_reason TEXT,
  ip_address TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── INDEXES ─────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_savings_accounts_user ON public.savings_accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_savings_accounts_goal ON public.savings_accounts(linked_goal_id);
CREATE INDEX IF NOT EXISTS idx_savings_transactions_account ON public.savings_transactions(savings_account_id);
CREATE INDEX IF NOT EXISTS idx_master_asset_registry_user ON public.master_asset_registry(user_id);
CREATE INDEX IF NOT EXISTS idx_master_asset_registry_source ON public.master_asset_registry(source_module, source_entity_id);
CREATE INDEX IF NOT EXISTS idx_financial_closing_user_period ON public.financial_closing_reports(user_id, period_type, period_start);
CREATE INDEX IF NOT EXISTS idx_reconciliation_log_user ON public.reconciliation_log(user_id);
CREATE INDEX IF NOT EXISTS idx_financial_calendar_user_date ON public.financial_calendar_events(user_id, event_date);
CREATE INDEX IF NOT EXISTS idx_account_transfers_user ON public.account_transfers(user_id);
CREATE INDEX IF NOT EXISTS idx_transaction_audit_txn ON public.transaction_audit_trail(transaction_id);

-- ─── RLS POLICIES ────────────────────────────────────────────────────────────

ALTER TABLE public.savings_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.savings_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.master_asset_registry ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_closing_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reconciliation_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.account_transfers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transaction_audit_trail ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='savings_accounts' AND policyname='savings_accounts_user_policy') THEN
    CREATE POLICY savings_accounts_user_policy ON public.savings_accounts FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='savings_transactions' AND policyname='savings_transactions_user_policy') THEN
    CREATE POLICY savings_transactions_user_policy ON public.savings_transactions FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='master_asset_registry' AND policyname='master_asset_registry_user_policy') THEN
    CREATE POLICY master_asset_registry_user_policy ON public.master_asset_registry FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='financial_closing_reports' AND policyname='financial_closing_reports_user_policy') THEN
    CREATE POLICY financial_closing_reports_user_policy ON public.financial_closing_reports FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='reconciliation_log' AND policyname='reconciliation_log_user_policy') THEN
    CREATE POLICY reconciliation_log_user_policy ON public.reconciliation_log FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='financial_calendar_events' AND policyname='financial_calendar_events_user_policy') THEN
    CREATE POLICY financial_calendar_events_user_policy ON public.financial_calendar_events FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='account_transfers' AND policyname='account_transfers_user_policy') THEN
    CREATE POLICY account_transfers_user_policy ON public.account_transfers FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='transaction_audit_trail' AND policyname='transaction_audit_trail_user_policy') THEN
    CREATE POLICY transaction_audit_trail_user_policy ON public.transaction_audit_trail FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;
