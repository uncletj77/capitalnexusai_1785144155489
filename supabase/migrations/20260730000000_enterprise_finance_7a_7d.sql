-- ============================================================
-- CAPITAL NEXUS AI — Enterprise Finance Rectification
-- Prompts 7A–7D: Finance, Transactions, Assets, Savings & Loans
-- Migration: 20260730000000_enterprise_finance_7a_7d.sql
-- ============================================================

-- ─── PHASE 1: CHART OF ACCOUNTS ──────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.chart_of_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  account_code TEXT NOT NULL,
  account_name TEXT NOT NULL,
  account_type TEXT NOT NULL CHECK (account_type IN (
    'asset','liability','equity','revenue','expense',
    'cost_of_sales','other_income','other_expense'
  )),
  account_subtype TEXT,
  parent_account_id UUID REFERENCES public.chart_of_accounts(id) ON DELETE SET NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  is_system BOOLEAN DEFAULT FALSE,
  normal_balance TEXT NOT NULL DEFAULT 'debit' CHECK (normal_balance IN ('debit','credit')),
  currency TEXT DEFAULT 'TZS',
  opening_balance NUMERIC(20,2) DEFAULT 0,
  current_balance NUMERIC(20,2) DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, account_code)
);

CREATE INDEX IF NOT EXISTS idx_coa_user_id ON public.chart_of_accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_coa_account_type ON public.chart_of_accounts(account_type);
CREATE INDEX IF NOT EXISTS idx_coa_parent ON public.chart_of_accounts(parent_account_id);

ALTER TABLE public.chart_of_accounts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "coa_user_policy" ON public.chart_of_accounts;
CREATE POLICY "coa_user_policy" ON public.chart_of_accounts
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ─── FINANCIAL PERIODS ───────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.financial_periods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  period_name TEXT NOT NULL,
  period_type TEXT NOT NULL DEFAULT 'monthly' CHECK (period_type IN ('monthly','quarterly','annual')),
  fiscal_year INTEGER NOT NULL,
  period_number INTEGER NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','closed','locked')),
  closed_at TIMESTAMPTZ,
  closed_by UUID REFERENCES auth.users(id),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fp_user_id ON public.financial_periods(user_id);
CREATE INDEX IF NOT EXISTS idx_fp_status ON public.financial_periods(status);
CREATE INDEX IF NOT EXISTS idx_fp_dates ON public.financial_periods(start_date, end_date);

ALTER TABLE public.financial_periods ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "fp_user_policy" ON public.financial_periods;
CREATE POLICY "fp_user_policy" ON public.financial_periods
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ─── JOURNAL ENTRIES ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.journal_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  journal_number TEXT NOT NULL,
  journal_date DATE NOT NULL DEFAULT CURRENT_DATE,
  journal_type TEXT NOT NULL DEFAULT 'manual' CHECK (journal_type IN (
    'manual','automatic','adjusting','reversing','closing','recurring'
  )),
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','approved','posted','locked','reversed')),
  description TEXT NOT NULL,
  reference TEXT,
  period_id UUID REFERENCES public.financial_periods(id) ON DELETE SET NULL,
  source_module TEXT,
  source_entity_id UUID,
  total_debit NUMERIC(20,2) DEFAULT 0,
  total_credit NUMERIC(20,2) DEFAULT 0,
  is_balanced BOOLEAN DEFAULT FALSE,
  reversal_of_id UUID REFERENCES public.journal_entries(id) ON DELETE SET NULL,
  reversed_by_id UUID REFERENCES public.journal_entries(id) ON DELETE SET NULL,
  posted_at TIMESTAMPTZ,
  posted_by UUID REFERENCES auth.users(id),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, journal_number)
);

CREATE INDEX IF NOT EXISTS idx_je_user_id ON public.journal_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_je_status ON public.journal_entries(status);
CREATE INDEX IF NOT EXISTS idx_je_date ON public.journal_entries(journal_date);
CREATE INDEX IF NOT EXISTS idx_je_source ON public.journal_entries(source_module, source_entity_id);

ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "je_user_policy" ON public.journal_entries;
CREATE POLICY "je_user_policy" ON public.journal_entries
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ─── JOURNAL ENTRY LINES ─────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.journal_entry_lines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  journal_entry_id UUID NOT NULL REFERENCES public.journal_entries(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  coa_account_id UUID REFERENCES public.chart_of_accounts(id) ON DELETE SET NULL,
  account_code TEXT,
  account_name TEXT,
  description TEXT,
  debit_amount NUMERIC(20,2) DEFAULT 0,
  credit_amount NUMERIC(20,2) DEFAULT 0,
  currency TEXT DEFAULT 'TZS',
  line_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_jel_journal_id ON public.journal_entry_lines(journal_entry_id);
CREATE INDEX IF NOT EXISTS idx_jel_user_id ON public.journal_entry_lines(user_id);
CREATE INDEX IF NOT EXISTS idx_jel_coa ON public.journal_entry_lines(coa_account_id);

ALTER TABLE public.journal_entry_lines ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "jel_user_policy" ON public.journal_entry_lines;
CREATE POLICY "jel_user_policy" ON public.journal_entry_lines
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ─── GENERAL LEDGER ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.general_ledger (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  coa_account_id UUID REFERENCES public.chart_of_accounts(id) ON DELETE SET NULL,
  account_code TEXT NOT NULL,
  account_name TEXT NOT NULL,
  journal_entry_id UUID REFERENCES public.journal_entries(id) ON DELETE SET NULL,
  journal_line_id UUID REFERENCES public.journal_entry_lines(id) ON DELETE SET NULL,
  posting_date DATE NOT NULL DEFAULT CURRENT_DATE,
  description TEXT,
  debit_amount NUMERIC(20,2) DEFAULT 0,
  credit_amount NUMERIC(20,2) DEFAULT 0,
  running_balance NUMERIC(20,2) DEFAULT 0,
  period_id UUID REFERENCES public.financial_periods(id) ON DELETE SET NULL,
  source_module TEXT,
  source_entity_id UUID,
  currency TEXT DEFAULT 'TZS',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_gl_user_id ON public.general_ledger(user_id);
CREATE INDEX IF NOT EXISTS idx_gl_account ON public.general_ledger(coa_account_id);
CREATE INDEX IF NOT EXISTS idx_gl_date ON public.general_ledger(posting_date);
CREATE INDEX IF NOT EXISTS idx_gl_journal ON public.general_ledger(journal_entry_id);

ALTER TABLE public.general_ledger ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "gl_user_policy" ON public.general_ledger;
CREATE POLICY "gl_user_policy" ON public.general_ledger
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ─── FINANCIAL AUDIT TRAIL ───────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.financial_audit_trail (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  entity_type TEXT NOT NULL,
  entity_id UUID NOT NULL,
  action TEXT NOT NULL CHECK (action IN ('create','update','delete','archive','restore','post','reverse','approve','close','lock')),
  old_values JSONB,
  new_values JSONB,
  changed_fields TEXT[],
  description TEXT,
  source_module TEXT,
  performed_by UUID REFERENCES auth.users(id),
  performed_at TIMESTAMPTZ DEFAULT NOW(),
  ip_address TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fat_user_id ON public.financial_audit_trail(user_id);
CREATE INDEX IF NOT EXISTS idx_fat_entity ON public.financial_audit_trail(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_fat_action ON public.financial_audit_trail(action);
CREATE INDEX IF NOT EXISTS idx_fat_date ON public.financial_audit_trail(performed_at);

ALTER TABLE public.financial_audit_trail ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "fat_user_policy" ON public.financial_audit_trail;
CREATE POLICY "fat_user_policy" ON public.financial_audit_trail
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ─── PHASE 2: ENTERPRISE TRANSACTION LIFECYCLE ───────────────────────────────

-- Add lifecycle columns to financial_transactions if not present
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'financial_transactions' AND table_schema = 'public') THEN
    -- Add lifecycle status
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='financial_transactions' AND column_name='lifecycle_status' AND table_schema='public') THEN
      ALTER TABLE public.financial_transactions ADD COLUMN lifecycle_status TEXT DEFAULT 'completed'
        CHECK (lifecycle_status IN ('draft','pending','approved','posted','completed','cancelled','reversed','archived'));
    END IF;
    -- Add journal entry link
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='financial_transactions' AND column_name='journal_entry_id' AND table_schema='public') THEN
      ALTER TABLE public.financial_transactions ADD COLUMN journal_entry_id UUID REFERENCES public.journal_entries(id) ON DELETE SET NULL;
    END IF;
    -- Add reversal link
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='financial_transactions' AND column_name='reversal_of_id' AND table_schema='public') THEN
      ALTER TABLE public.financial_transactions ADD COLUMN reversal_of_id UUID REFERENCES public.financial_transactions(id) ON DELETE SET NULL;
    END IF;
    -- Add batch number
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='financial_transactions' AND column_name='batch_number' AND table_schema='public') THEN
      ALTER TABLE public.financial_transactions ADD COLUMN batch_number TEXT;
    END IF;
    -- Add period link
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='financial_transactions' AND column_name='period_id' AND table_schema='public') THEN
      ALTER TABLE public.financial_transactions ADD COLUMN period_id UUID REFERENCES public.financial_periods(id) ON DELETE SET NULL;
    END IF;
    -- Add is_archived if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='financial_transactions' AND column_name='is_archived' AND table_schema='public') THEN
      ALTER TABLE public.financial_transactions ADD COLUMN is_archived BOOLEAN DEFAULT FALSE;
    END IF;
    -- Add title
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='financial_transactions' AND column_name='title' AND table_schema='public') THEN
      ALTER TABLE public.financial_transactions ADD COLUMN title TEXT;
    END IF;
    -- Add source_account_id
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='financial_transactions' AND column_name='source_account_id' AND table_schema='public') THEN
      ALTER TABLE public.financial_transactions ADD COLUMN source_account_id UUID REFERENCES public.financial_accounts(id) ON DELETE SET NULL;
    END IF;
    -- Add destination_account_id
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='financial_transactions' AND column_name='destination_account_id' AND table_schema='public') THEN
      ALTER TABLE public.financial_transactions ADD COLUMN destination_account_id UUID REFERENCES public.financial_accounts(id) ON DELETE SET NULL;
    END IF;
    -- Add tags
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='financial_transactions' AND column_name='tags' AND table_schema='public') THEN
      ALTER TABLE public.financial_transactions ADD COLUMN tags TEXT[];
    END IF;
    -- Add reference_number
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='financial_transactions' AND column_name='reference_number' AND table_schema='public') THEN
      ALTER TABLE public.financial_transactions ADD COLUMN reference_number TEXT;
    END IF;
    -- Add linked_transfer_id
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='financial_transactions' AND column_name='linked_transfer_id' AND table_schema='public') THEN
      ALTER TABLE public.financial_transactions ADD COLUMN linked_transfer_id UUID REFERENCES public.financial_transactions(id) ON DELETE SET NULL;
    END IF;
    -- Add currency
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='financial_transactions' AND column_name='currency' AND table_schema='public') THEN
      ALTER TABLE public.financial_transactions ADD COLUMN currency TEXT DEFAULT 'TZS';
    END IF;
    -- Add related_loan_id
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='financial_transactions' AND column_name='related_loan_id' AND table_schema='public') THEN
      ALTER TABLE public.financial_transactions ADD COLUMN related_loan_id UUID;
    END IF;
    -- Add related_investment_id
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='financial_transactions' AND column_name='related_investment_id' AND table_schema='public') THEN
      ALTER TABLE public.financial_transactions ADD COLUMN related_investment_id UUID;
    END IF;
    -- Add related_business_id
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='financial_transactions' AND column_name='related_business_id' AND table_schema='public') THEN
      ALTER TABLE public.financial_transactions ADD COLUMN related_business_id UUID;
    END IF;
    -- Add related_goal_id
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='financial_transactions' AND column_name='related_goal_id' AND table_schema='public') THEN
      ALTER TABLE public.financial_transactions ADD COLUMN related_goal_id UUID;
    END IF;
    -- Add related_module
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='financial_transactions' AND column_name='related_module' AND table_schema='public') THEN
      ALTER TABLE public.financial_transactions ADD COLUMN related_module TEXT;
    END IF;
    -- Add related_entity_id
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='financial_transactions' AND column_name='related_entity_id' AND table_schema='public') THEN
      ALTER TABLE public.financial_transactions ADD COLUMN related_entity_id UUID;
    END IF;
    -- Ensure transaction_type is text (not enum) for enterprise types
    -- Add status column
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='financial_transactions' AND column_name='status' AND table_schema='public') THEN
      ALTER TABLE public.financial_transactions ADD COLUMN status TEXT DEFAULT 'completed';
    END IF;
  END IF;
END $$;

-- ─── PHASE 3: ASSET DEPRECIATION ENGINE ──────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.asset_depreciation_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  asset_registry_id UUID REFERENCES public.master_asset_registry(id) ON DELETE CASCADE,
  asset_id UUID,
  depreciation_method TEXT NOT NULL DEFAULT 'straight_line' CHECK (depreciation_method IN (
    'straight_line','declining_balance','double_declining','units_of_production','custom'
  )),
  acquisition_cost NUMERIC(20,2) NOT NULL DEFAULT 0,
  salvage_value NUMERIC(20,2) DEFAULT 0,
  useful_life_years NUMERIC(8,2) DEFAULT 5,
  depreciation_rate NUMERIC(8,4) DEFAULT 0,
  annual_depreciation NUMERIC(20,2) DEFAULT 0,
  monthly_depreciation NUMERIC(20,2) DEFAULT 0,
  accumulated_depreciation NUMERIC(20,2) DEFAULT 0,
  current_book_value NUMERIC(20,2) DEFAULT 0,
  start_date DATE NOT NULL DEFAULT CURRENT_DATE,
  end_date DATE,
  last_depreciation_date DATE,
  next_depreciation_date DATE,
  is_active BOOLEAN DEFAULT TRUE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ads_user_id ON public.asset_depreciation_schedules(user_id);
CREATE INDEX IF NOT EXISTS idx_ads_asset ON public.asset_depreciation_schedules(asset_registry_id);

ALTER TABLE public.asset_depreciation_schedules ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "ads_user_policy" ON public.asset_depreciation_schedules;
CREATE POLICY "ads_user_policy" ON public.asset_depreciation_schedules
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Asset Depreciation Postings
CREATE TABLE IF NOT EXISTS public.asset_depreciation_postings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  schedule_id UUID REFERENCES public.asset_depreciation_schedules(id) ON DELETE CASCADE,
  asset_registry_id UUID REFERENCES public.master_asset_registry(id) ON DELETE CASCADE,
  posting_date DATE NOT NULL DEFAULT CURRENT_DATE,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  depreciation_amount NUMERIC(20,2) NOT NULL DEFAULT 0,
  accumulated_before NUMERIC(20,2) DEFAULT 0,
  accumulated_after NUMERIC(20,2) DEFAULT 0,
  book_value_before NUMERIC(20,2) DEFAULT 0,
  book_value_after NUMERIC(20,2) DEFAULT 0,
  journal_entry_id UUID REFERENCES public.journal_entries(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_adp_user_id ON public.asset_depreciation_postings(user_id);
CREATE INDEX IF NOT EXISTS idx_adp_schedule ON public.asset_depreciation_postings(schedule_id);

ALTER TABLE public.asset_depreciation_postings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "adp_user_policy" ON public.asset_depreciation_postings;
CREATE POLICY "adp_user_policy" ON public.asset_depreciation_postings
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Asset Maintenance Records
CREATE TABLE IF NOT EXISTS public.asset_maintenance_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  asset_registry_id UUID REFERENCES public.master_asset_registry(id) ON DELETE CASCADE,
  maintenance_type TEXT NOT NULL DEFAULT 'corrective' CHECK (maintenance_type IN ('preventive','corrective','inspection','upgrade')),
  title TEXT NOT NULL,
  description TEXT,
  maintenance_date DATE NOT NULL DEFAULT CURRENT_DATE,
  next_maintenance_date DATE,
  cost NUMERIC(20,2) DEFAULT 0,
  vendor TEXT,
  status TEXT DEFAULT 'completed' CHECK (status IN ('scheduled','in_progress','completed','cancelled')),
  journal_entry_id UUID REFERENCES public.journal_entries(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_amr_user_id ON public.asset_maintenance_records(user_id);
CREATE INDEX IF NOT EXISTS idx_amr_asset ON public.asset_maintenance_records(asset_registry_id);

ALTER TABLE public.asset_maintenance_records ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "amr_user_policy" ON public.asset_maintenance_records;
CREATE POLICY "amr_user_policy" ON public.asset_maintenance_records
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Asset Disposal Records
CREATE TABLE IF NOT EXISTS public.asset_disposal_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  asset_registry_id UUID REFERENCES public.master_asset_registry(id) ON DELETE SET NULL,
  disposal_type TEXT NOT NULL DEFAULT 'sale' CHECK (disposal_type IN ('sale','donation','scrap','loss','theft','transfer','write_off')),
  disposal_date DATE NOT NULL DEFAULT CURRENT_DATE,
  book_value_at_disposal NUMERIC(20,2) DEFAULT 0,
  disposal_proceeds NUMERIC(20,2) DEFAULT 0,
  gain_loss NUMERIC(20,2) DEFAULT 0,
  description TEXT,
  journal_entry_id UUID REFERENCES public.journal_entries(id) ON DELETE SET NULL,
  transaction_id UUID REFERENCES public.financial_transactions(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_adr_user_id ON public.asset_disposal_records(user_id);

ALTER TABLE public.asset_disposal_records ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "adr_user_policy" ON public.asset_disposal_records;
CREATE POLICY "adr_user_policy" ON public.asset_disposal_records
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Enhance master_asset_registry with depreciation fields
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'master_asset_registry' AND table_schema = 'public') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='master_asset_registry' AND column_name='depreciation_method' AND table_schema='public') THEN
      ALTER TABLE public.master_asset_registry ADD COLUMN depreciation_method TEXT DEFAULT 'straight_line';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='master_asset_registry' AND column_name='useful_life_years' AND table_schema='public') THEN
      ALTER TABLE public.master_asset_registry ADD COLUMN useful_life_years NUMERIC(8,2) DEFAULT 5;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='master_asset_registry' AND column_name='salvage_value' AND table_schema='public') THEN
      ALTER TABLE public.master_asset_registry ADD COLUMN salvage_value NUMERIC(20,2) DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='master_asset_registry' AND column_name='accumulated_depreciation' AND table_schema='public') THEN
      ALTER TABLE public.master_asset_registry ADD COLUMN accumulated_depreciation NUMERIC(20,2) DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='master_asset_registry' AND column_name='book_value' AND table_schema='public') THEN
      ALTER TABLE public.master_asset_registry ADD COLUMN book_value NUMERIC(20,2) DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='master_asset_registry' AND column_name='market_value' AND table_schema='public') THEN
      ALTER TABLE public.master_asset_registry ADD COLUMN market_value NUMERIC(20,2) DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='master_asset_registry' AND column_name='condition' AND table_schema='public') THEN
      ALTER TABLE public.master_asset_registry ADD COLUMN condition TEXT DEFAULT 'good';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='master_asset_registry' AND column_name='serial_number' AND table_schema='public') THEN
      ALTER TABLE public.master_asset_registry ADD COLUMN serial_number TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='master_asset_registry' AND column_name='department' AND table_schema='public') THEN
      ALTER TABLE public.master_asset_registry ADD COLUMN department TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='master_asset_registry' AND column_name='custodian' AND table_schema='public') THEN
      ALTER TABLE public.master_asset_registry ADD COLUMN custodian TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='master_asset_registry' AND column_name='disposal_date' AND table_schema='public') THEN
      ALTER TABLE public.master_asset_registry ADD COLUMN disposal_date DATE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='master_asset_registry' AND column_name='disposal_type' AND table_schema='public') THEN
      ALTER TABLE public.master_asset_registry ADD COLUMN disposal_type TEXT;
    END IF;
  END IF;
END $$;

-- ─── PHASE 4: LOAN AMORTIZATION & ENTERPRISE LOAN TABLES ─────────────────────

CREATE TABLE IF NOT EXISTS public.loan_amortization_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  loan_id UUID,
  payment_number INTEGER NOT NULL,
  payment_date DATE NOT NULL,
  opening_balance NUMERIC(20,2) NOT NULL DEFAULT 0,
  payment_amount NUMERIC(20,2) NOT NULL DEFAULT 0,
  principal_component NUMERIC(20,2) NOT NULL DEFAULT 0,
  interest_component NUMERIC(20,2) NOT NULL DEFAULT 0,
  closing_balance NUMERIC(20,2) NOT NULL DEFAULT 0,
  is_paid BOOLEAN DEFAULT FALSE,
  paid_date DATE,
  paid_amount NUMERIC(20,2) DEFAULT 0,
  transaction_id UUID REFERENCES public.financial_transactions(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_las_user_id ON public.loan_amortization_schedules(user_id);
CREATE INDEX IF NOT EXISTS idx_las_loan_id ON public.loan_amortization_schedules(loan_id);
CREATE INDEX IF NOT EXISTS idx_las_payment_date ON public.loan_amortization_schedules(payment_date);

ALTER TABLE public.loan_amortization_schedules ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "las_user_policy" ON public.loan_amortization_schedules;
CREATE POLICY "las_user_policy" ON public.loan_amortization_schedules
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Loan Interest Accruals
CREATE TABLE IF NOT EXISTS public.loan_interest_accruals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  loan_id UUID NOT NULL,
  accrual_date DATE NOT NULL DEFAULT CURRENT_DATE,
  accrual_period_start DATE NOT NULL,
  accrual_period_end DATE NOT NULL,
  principal_balance NUMERIC(20,2) NOT NULL DEFAULT 0,
  interest_rate NUMERIC(8,4) NOT NULL DEFAULT 0,
  accrued_interest NUMERIC(20,2) NOT NULL DEFAULT 0,
  is_posted BOOLEAN DEFAULT FALSE,
  journal_entry_id UUID REFERENCES public.journal_entries(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_lia_user_id ON public.loan_interest_accruals(user_id);
CREATE INDEX IF NOT EXISTS idx_lia_loan_id ON public.loan_interest_accruals(loan_id);

ALTER TABLE public.loan_interest_accruals ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "lia_user_policy" ON public.loan_interest_accruals;
CREATE POLICY "lia_user_policy" ON public.loan_interest_accruals
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Enhance loans table with enterprise fields
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'loans' AND table_schema = 'public') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='loans' AND column_name='outstanding_balance' AND table_schema='public') THEN
      ALTER TABLE public.loans ADD COLUMN outstanding_balance NUMERIC(20,2) DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='loans' AND column_name='accrued_interest' AND table_schema='public') THEN
      ALTER TABLE public.loans ADD COLUMN accrued_interest NUMERIC(20,2) DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='loans' AND column_name='penalty_balance' AND table_schema='public') THEN
      ALTER TABLE public.loans ADD COLUMN penalty_balance NUMERIC(20,2) DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='loans' AND column_name='disbursement_date' AND table_schema='public') THEN
      ALTER TABLE public.loans ADD COLUMN disbursement_date DATE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='loans' AND column_name='maturity_date' AND table_schema='public') THEN
      ALTER TABLE public.loans ADD COLUMN maturity_date DATE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='loans' AND column_name='linked_account_id' AND table_schema='public') THEN
      ALTER TABLE public.loans ADD COLUMN linked_account_id UUID REFERENCES public.financial_accounts(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='loans' AND column_name='journal_entry_id' AND table_schema='public') THEN
      ALTER TABLE public.loans ADD COLUMN journal_entry_id UUID REFERENCES public.journal_entries(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='loans' AND column_name='is_archived' AND table_schema='public') THEN
      ALTER TABLE public.loans ADD COLUMN is_archived BOOLEAN DEFAULT FALSE;
    END IF;
  END IF;
END $$;

-- Enhance savings_accounts with enterprise fields
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'savings_accounts' AND table_schema = 'public') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='savings_accounts' AND column_name='account_number' AND table_schema='public') THEN
      ALTER TABLE public.savings_accounts ADD COLUMN account_number TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='savings_accounts' AND column_name='compounding_frequency' AND table_schema='public') THEN
      ALTER TABLE public.savings_accounts ADD COLUMN compounding_frequency TEXT DEFAULT 'monthly';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='savings_accounts' AND column_name='interest_method' AND table_schema='public') THEN
      ALTER TABLE public.savings_accounts ADD COLUMN interest_method TEXT DEFAULT 'simple';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='savings_accounts' AND column_name='minimum_balance' AND table_schema='public') THEN
      ALTER TABLE public.savings_accounts ADD COLUMN minimum_balance NUMERIC(20,2) DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='savings_accounts' AND column_name='maximum_balance' AND table_schema='public') THEN
      ALTER TABLE public.savings_accounts ADD COLUMN maximum_balance NUMERIC(20,2) DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='savings_accounts' AND column_name='currency' AND table_schema='public') THEN
      ALTER TABLE public.savings_accounts ADD COLUMN currency TEXT DEFAULT 'TZS';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='savings_accounts' AND column_name='is_archived' AND table_schema='public') THEN
      ALTER TABLE public.savings_accounts ADD COLUMN is_archived BOOLEAN DEFAULT FALSE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='savings_accounts' AND column_name='total_interest_earned' AND table_schema='public') THEN
      ALTER TABLE public.savings_accounts ADD COLUMN total_interest_earned NUMERIC(20,2) DEFAULT 0;
    END IF;
  END IF;
END $$;

-- ─── ACCOUNTING ENGINE FUNCTIONS ─────────────────────────────────────────────

-- Function: Generate next journal number
CREATE OR REPLACE FUNCTION public.generate_journal_number(p_user_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_count INTEGER;
  v_year TEXT;
BEGIN
  v_year := TO_CHAR(CURRENT_DATE, 'YYYY');
  SELECT COUNT(*) + 1 INTO v_count
  FROM public.journal_entries
  WHERE user_id = p_user_id
    AND EXTRACT(YEAR FROM journal_date) = EXTRACT(YEAR FROM CURRENT_DATE);
  RETURN 'JE-' || v_year || '-' || LPAD(v_count::TEXT, 5, '0');
END;
$$;

-- Function: Post journal entry to general ledger
CREATE OR REPLACE FUNCTION public.post_journal_to_ledger(p_journal_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_journal RECORD;
  v_line RECORD;
  v_running_balance NUMERIC(20,2);
BEGIN
  SELECT * INTO v_journal FROM public.journal_entries WHERE id = p_journal_id;
  IF NOT FOUND THEN RETURN FALSE; END IF;
  IF v_journal.total_debit != v_journal.total_credit THEN RETURN FALSE; END IF;

  FOR v_line IN
    SELECT * FROM public.journal_entry_lines WHERE journal_entry_id = p_journal_id ORDER BY line_order
  LOOP
    -- Calculate running balance for this account
    SELECT COALESCE(SUM(debit_amount - credit_amount), 0) INTO v_running_balance
    FROM public.general_ledger
    WHERE user_id = v_journal.user_id AND account_code = v_line.account_code;

    v_running_balance := v_running_balance + v_line.debit_amount - v_line.credit_amount;

    INSERT INTO public.general_ledger (
      user_id, coa_account_id, account_code, account_name,
      journal_entry_id, journal_line_id, posting_date, description,
      debit_amount, credit_amount, running_balance,
      period_id, source_module, source_entity_id, currency
    ) VALUES (
      v_journal.user_id, v_line.coa_account_id, v_line.account_code, v_line.account_name,
      p_journal_id, v_line.id, v_journal.journal_date, v_line.description,
      v_line.debit_amount, v_line.credit_amount, v_running_balance,
      v_journal.period_id, v_journal.source_module, v_journal.source_entity_id, v_line.currency
    );

    -- Update COA balance
    UPDATE public.chart_of_accounts
    SET current_balance = current_balance + v_line.debit_amount - v_line.credit_amount,
        updated_at = NOW()
    WHERE id = v_line.coa_account_id AND user_id = v_journal.user_id;
  END LOOP;

  -- Mark journal as posted
  UPDATE public.journal_entries
  SET status = 'posted', posted_at = NOW(), posted_by = v_journal.user_id
  WHERE id = p_journal_id;

  RETURN TRUE;
END;
$$;

-- Function: Validate journal balance
CREATE OR REPLACE FUNCTION public.validate_journal_balance(p_journal_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total_debit NUMERIC(20,2);
  v_total_credit NUMERIC(20,2);
BEGIN
  SELECT
    COALESCE(SUM(debit_amount), 0),
    COALESCE(SUM(credit_amount), 0)
  INTO v_total_debit, v_total_credit
  FROM public.journal_entry_lines
  WHERE journal_entry_id = p_journal_id;

  UPDATE public.journal_entries
  SET total_debit = v_total_debit,
      total_credit = v_total_credit,
      is_balanced = (ABS(v_total_debit - v_total_credit) < 0.01),
      updated_at = NOW()
  WHERE id = p_journal_id;

  RETURN ABS(v_total_debit - v_total_credit) < 0.01;
END;
$$;

-- Function: Get trial balance
CREATE OR REPLACE FUNCTION public.get_trial_balance(p_user_id UUID, p_as_of_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE(
  account_code TEXT,
  account_name TEXT,
  account_type TEXT,
  debit_total NUMERIC,
  credit_total NUMERIC,
  balance NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    gl.account_code,
    gl.account_name,
    coa.account_type,
    COALESCE(SUM(gl.debit_amount), 0) AS debit_total,
    COALESCE(SUM(gl.credit_amount), 0) AS credit_total,
    COALESCE(SUM(gl.debit_amount - gl.credit_amount), 0) AS balance
  FROM public.general_ledger gl
  LEFT JOIN public.chart_of_accounts coa ON coa.id = gl.coa_account_id
  WHERE gl.user_id = p_user_id
    AND gl.posting_date <= p_as_of_date
  GROUP BY gl.account_code, gl.account_name, coa.account_type
  ORDER BY gl.account_code;
END;
$$;

-- Function: Calculate loan amortization schedule
CREATE OR REPLACE FUNCTION public.generate_loan_amortization(
  p_user_id UUID,
  p_loan_id UUID,
  p_principal NUMERIC,
  p_annual_rate NUMERIC,
  p_term_months INTEGER,
  p_start_date DATE
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_monthly_rate NUMERIC;
  v_monthly_payment NUMERIC;
  v_balance NUMERIC;
  v_interest NUMERIC;
  v_principal_comp NUMERIC;
  v_payment_date DATE;
  v_count INTEGER := 0;
BEGIN
  -- Delete existing schedule
  DELETE FROM public.loan_amortization_schedules
  WHERE user_id = p_user_id AND loan_id = p_loan_id;

  v_monthly_rate := p_annual_rate / 100.0 / 12.0;
  v_balance := p_principal;

  IF v_monthly_rate > 0 THEN
    v_monthly_payment := p_principal * v_monthly_rate * POWER(1 + v_monthly_rate, p_term_months)
                         / (POWER(1 + v_monthly_rate, p_term_months) - 1);
  ELSE
    v_monthly_payment := p_principal / p_term_months;
  END IF;

  FOR i IN 1..p_term_months LOOP
    v_payment_date := p_start_date + (i * INTERVAL '1 month');
    v_interest := v_balance * v_monthly_rate;
    v_principal_comp := LEAST(v_monthly_payment - v_interest, v_balance);
    IF i = p_term_months THEN
      v_principal_comp := v_balance;
      v_monthly_payment := v_principal_comp + v_interest;
    END IF;

    INSERT INTO public.loan_amortization_schedules (
      user_id, loan_id, payment_number, payment_date,
      opening_balance, payment_amount, principal_component,
      interest_component, closing_balance
    ) VALUES (
      p_user_id, p_loan_id, i, v_payment_date,
      ROUND(v_balance, 2), ROUND(v_monthly_payment, 2),
      ROUND(v_principal_comp, 2), ROUND(v_interest, 2),
      ROUND(GREATEST(v_balance - v_principal_comp, 0), 2)
    );

    v_balance := GREATEST(v_balance - v_principal_comp, 0);
    v_count := v_count + 1;
    IF v_balance <= 0 THEN EXIT; END IF;
  END LOOP;

  RETURN v_count;
END;
$$;

-- Function: Calculate straight-line depreciation
CREATE OR REPLACE FUNCTION public.calculate_depreciation(
  p_acquisition_cost NUMERIC,
  p_salvage_value NUMERIC,
  p_useful_life_years NUMERIC,
  p_method TEXT DEFAULT 'straight_line'
)
RETURNS TABLE(annual_depreciation NUMERIC, monthly_depreciation NUMERIC, depreciation_rate NUMERIC)
LANGUAGE plpgsql
AS $$
DECLARE
  v_annual NUMERIC;
  v_rate NUMERIC;
BEGIN
  IF p_method = 'straight_line' THEN
    v_annual := (p_acquisition_cost - p_salvage_value) / NULLIF(p_useful_life_years, 0);
    v_rate := 1.0 / NULLIF(p_useful_life_years, 0);
  ELSIF p_method = 'declining_balance' THEN
    v_rate := 1.0 / NULLIF(p_useful_life_years, 0);
    v_annual := p_acquisition_cost * v_rate;
  ELSIF p_method = 'double_declining' THEN
    v_rate := 2.0 / NULLIF(p_useful_life_years, 0);
    v_annual := p_acquisition_cost * v_rate;
  ELSE
    v_annual := (p_acquisition_cost - p_salvage_value) / NULLIF(p_useful_life_years, 0);
    v_rate := 1.0 / NULLIF(p_useful_life_years, 0);
  END IF;

  RETURN QUERY SELECT
    ROUND(COALESCE(v_annual, 0), 2),
    ROUND(COALESCE(v_annual, 0) / 12.0, 2),
    ROUND(COALESCE(v_rate, 0), 6);
END;
$$;

-- ─── INDEXES FOR PERFORMANCE ──────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_ft_lifecycle ON public.financial_transactions(lifecycle_status) WHERE lifecycle_status IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_ft_journal ON public.financial_transactions(journal_entry_id) WHERE journal_entry_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_ft_source_account ON public.financial_transactions(source_account_id) WHERE source_account_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_ft_dest_account ON public.financial_transactions(destination_account_id) WHERE destination_account_id IS NOT NULL;
