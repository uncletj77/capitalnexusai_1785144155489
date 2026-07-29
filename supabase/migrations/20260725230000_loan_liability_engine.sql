-- ============================================================
-- LOAN & LIABILITY INTELLIGENCE ENGINE
-- Migration: 20260725230000_loan_liability_engine.sql
-- ============================================================

-- ─── LOANS TABLE ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.loans (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  loan_name           TEXT NOT NULL,
  lender              TEXT NOT NULL,
  loan_category       TEXT NOT NULL CHECK (loan_category IN ('personal','business','asset_financing','investment','mortgage','informal')),
  purpose             TEXT NOT NULL,
  principal_amount    NUMERIC(18,2) NOT NULL DEFAULT 0,
  currency            TEXT NOT NULL DEFAULT 'TZS',
  interest_rate       NUMERIC(8,4) NOT NULL DEFAULT 0,
  interest_type       TEXT NOT NULL DEFAULT 'fixed' CHECK (interest_type IN ('fixed','variable','simple','compound')),
  loan_term_months    INTEGER NOT NULL DEFAULT 12,
  start_date          DATE NOT NULL,
  end_date            DATE,
  payment_frequency   TEXT NOT NULL DEFAULT 'monthly' CHECK (payment_frequency IN ('weekly','bi_weekly','monthly','quarterly','annually')),
  monthly_payment     NUMERIC(18,2) NOT NULL DEFAULT 0,
  remaining_balance   NUMERIC(18,2) NOT NULL DEFAULT 0,
  total_paid          NUMERIC(18,2) NOT NULL DEFAULT 0,
  total_interest_paid NUMERIC(18,2) NOT NULL DEFAULT 0,
  next_due_date       DATE,
  payment_method      TEXT DEFAULT 'bank_transfer',
  status              TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','completed','defaulted','restructured')),
  is_late             BOOLEAN NOT NULL DEFAULT FALSE,
  days_overdue        INTEGER NOT NULL DEFAULT 0,
  collateral_asset_id UUID REFERENCES public.assets(id) ON DELETE SET NULL,
  notes               TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── LOAN REPAYMENTS TABLE ──────────────────────────────────
CREATE TABLE IF NOT EXISTS public.loan_repayments (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  loan_id           UUID NOT NULL REFERENCES public.loans(id) ON DELETE CASCADE,
  user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount_paid       NUMERIC(18,2) NOT NULL DEFAULT 0,
  principal_paid    NUMERIC(18,2) NOT NULL DEFAULT 0,
  interest_paid     NUMERIC(18,2) NOT NULL DEFAULT 0,
  payment_date      DATE NOT NULL,
  due_date          DATE,
  remaining_balance NUMERIC(18,2) NOT NULL DEFAULT 0,
  payment_method    TEXT DEFAULT 'bank_transfer',
  status            TEXT NOT NULL DEFAULT 'completed' CHECK (status IN ('completed','pending','missed','partial')),
  notes             TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── LIABILITIES TABLE ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.liabilities (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  type        TEXT NOT NULL CHECK (type IN ('loan','informal_debt','bill','contract','other')),
  amount      NUMERIC(18,2) NOT NULL DEFAULT 0,
  due_date    DATE,
  creditor    TEXT,
  status      TEXT NOT NULL DEFAULT 'outstanding' CHECK (status IN ('outstanding','paid','overdue','disputed')),
  notes       TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── LOAN ANALYSIS TABLE ────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.loan_analysis (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  loan_id         UUID NOT NULL REFERENCES public.loans(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  risk_score      INTEGER NOT NULL DEFAULT 50 CHECK (risk_score BETWEEN 0 AND 100),
  risk_level      TEXT NOT NULL DEFAULT 'moderate' CHECK (risk_level IN ('healthy','moderate','high_risk','critical')),
  dti_ratio       NUMERIC(8,4) DEFAULT 0,
  dta_ratio       NUMERIC(8,4) DEFAULT 0,
  recommendations JSONB DEFAULT '[]',
  analysis_date   DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── DEBT HEALTH SNAPSHOTS ──────────────────────────────────
CREATE TABLE IF NOT EXISTS public.debt_health_snapshots (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  snapshot_date       DATE NOT NULL DEFAULT CURRENT_DATE,
  total_debt          NUMERIC(18,2) NOT NULL DEFAULT 0,
  total_monthly_payment NUMERIC(18,2) NOT NULL DEFAULT 0,
  monthly_income      NUMERIC(18,2) NOT NULL DEFAULT 0,
  total_assets        NUMERIC(18,2) NOT NULL DEFAULT 0,
  dti_ratio           NUMERIC(8,4) DEFAULT 0,
  dta_ratio           NUMERIC(8,4) DEFAULT 0,
  debt_health_score   INTEGER NOT NULL DEFAULT 50,
  risk_level          TEXT NOT NULL DEFAULT 'moderate',
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, snapshot_date)
);

-- ─── INDEXES ────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_loans_user_id ON public.loans(user_id);
CREATE INDEX IF NOT EXISTS idx_loans_status ON public.loans(status);
CREATE INDEX IF NOT EXISTS idx_loan_repayments_loan_id ON public.loan_repayments(loan_id);
CREATE INDEX IF NOT EXISTS idx_loan_repayments_user_id ON public.loan_repayments(user_id);
CREATE INDEX IF NOT EXISTS idx_liabilities_user_id ON public.liabilities(user_id);
CREATE INDEX IF NOT EXISTS idx_debt_health_user_date ON public.debt_health_snapshots(user_id, snapshot_date);

-- ─── UPDATED_AT TRIGGER ─────────────────────────────────────
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'loans_updated_at') THEN
    CREATE TRIGGER loans_updated_at
      BEFORE UPDATE ON public.loans
      FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
  END IF;
END $$;

-- ─── TRIGGER: update net worth when loan balance changes ────
CREATE OR REPLACE FUNCTION public.sync_net_worth_on_loan_change()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_user_id UUID;
  v_total_assets NUMERIC := 0;
  v_total_liabilities NUMERIC := 0;
  v_net_worth NUMERIC := 0;
BEGIN
  v_user_id := COALESCE(NEW.user_id, OLD.user_id);

  SELECT COALESCE(SUM(current_value), 0) INTO v_total_assets
  FROM public.assets WHERE user_id = v_user_id AND asset_status != 'disposed';

  SELECT COALESCE(SUM(balance), 0) INTO v_total_assets
  FROM public.financial_accounts WHERE user_id = v_user_id AND is_active = TRUE;

  SELECT COALESCE(SUM(remaining_balance), 0) INTO v_total_liabilities
  FROM public.loans WHERE user_id = v_user_id AND status = 'active';

  v_net_worth := v_total_assets - v_total_liabilities;

  INSERT INTO public.net_worth_snapshots (user_id, snapshot_date, net_worth, total_assets, total_liabilities)
  VALUES (v_user_id, CURRENT_DATE, v_net_worth, v_total_assets, v_total_liabilities)
  ON CONFLICT (user_id, snapshot_date) DO UPDATE
    SET net_worth = EXCLUDED.net_worth,
        total_assets = EXCLUDED.total_assets,
        total_liabilities = EXCLUDED.total_liabilities;

  RETURN COALESCE(NEW, OLD);
END;
$$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'loans_sync_net_worth') THEN
    CREATE TRIGGER loans_sync_net_worth
      AFTER INSERT OR UPDATE OR DELETE ON public.loans
      FOR EACH ROW EXECUTE FUNCTION public.sync_net_worth_on_loan_change();
  END IF;
END $$;

-- ─── RLS POLICIES ───────────────────────────────────────────
ALTER TABLE public.loans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loan_repayments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.liabilities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loan_analysis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.debt_health_snapshots ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='loans' AND policyname='loans_owner') THEN
    CREATE POLICY loans_owner ON public.loans FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='loan_repayments' AND policyname='repayments_owner') THEN
    CREATE POLICY repayments_owner ON public.loan_repayments FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='liabilities' AND policyname='liabilities_owner') THEN
    CREATE POLICY liabilities_owner ON public.liabilities FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='loan_analysis' AND policyname='loan_analysis_owner') THEN
    CREATE POLICY loan_analysis_owner ON public.loan_analysis FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='debt_health_snapshots' AND policyname='debt_health_owner') THEN
    CREATE POLICY debt_health_owner ON public.debt_health_snapshots FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- ─── DEMO DATA ──────────────────────────────────────────────
DO $$
DECLARE
  v_user_id UUID;
  v_loan1_id UUID := gen_random_uuid();
  v_loan2_id UUID := gen_random_uuid();
  v_loan3_id UUID := gen_random_uuid();
BEGIN
  SELECT id INTO v_user_id FROM auth.users LIMIT 1;
  IF v_user_id IS NULL THEN RETURN; END IF;

  IF NOT EXISTS (SELECT 1 FROM public.loans WHERE user_id = v_user_id LIMIT 1) THEN

    INSERT INTO public.loans (id, user_id, loan_name, lender, loan_category, purpose,
      principal_amount, currency, interest_rate, interest_type, loan_term_months,
      start_date, end_date, payment_frequency, monthly_payment, remaining_balance,
      total_paid, total_interest_paid, next_due_date, status)
    VALUES
      (v_loan1_id, v_user_id, 'CRDB Business Expansion Loan', 'CRDB Bank', 'business', 'Business expansion',
       80000000, 'TZS', 18.5, 'compound', 36,
       '2025-01-15', '2028-01-15', 'monthly', 2900000, 62000000,
       18000000, 4200000, '2026-08-15', 'active'),
      (v_loan2_id, v_user_id, 'NMB Vehicle Financing', 'NMB Bank', 'asset_financing', 'Asset purchase',
       35000000, 'TZS', 15.0, 'fixed', 48,
       '2024-06-01', '2028-06-01', 'monthly', 975000, 22000000,
       13000000, 2800000, '2026-08-01', 'active'),
      (v_loan3_id, v_user_id, 'Personal Emergency Loan', 'Equity Bank', 'personal', 'Emergency',
       5000000, 'TZS', 24.0, 'simple', 12,
       '2026-03-01', '2027-03-01', 'monthly', 470000, 2800000,
       2200000, 600000, '2026-08-01', 'active');

    INSERT INTO public.loan_repayments (loan_id, user_id, amount_paid, principal_paid, interest_paid,
      payment_date, due_date, remaining_balance, status)
    VALUES
      (v_loan1_id, v_user_id, 2900000, 1800000, 1100000, '2026-07-15', '2026-07-15', 62000000, 'completed'),
      (v_loan1_id, v_user_id, 2900000, 1780000, 1120000, '2026-06-15', '2026-06-15', 64800000, 'completed'),
      (v_loan1_id, v_user_id, 2900000, 1760000, 1140000, '2026-05-15', '2026-05-15', 67600000, 'completed'),
      (v_loan2_id, v_user_id, 975000, 650000, 325000, '2026-07-01', '2026-07-01', 22000000, 'completed'),
      (v_loan2_id, v_user_id, 975000, 640000, 335000, '2026-06-01', '2026-06-01', 22650000, 'completed'),
      (v_loan3_id, v_user_id, 470000, 370000, 100000, '2026-07-01', '2026-07-01', 2800000, 'completed'),
      (v_loan3_id, v_user_id, 470000, 360000, 110000, '2026-06-01', '2026-06-01', 3170000, 'completed');

    INSERT INTO public.loan_analysis (loan_id, user_id, risk_score, risk_level, dti_ratio, dta_ratio, recommendations)
    VALUES
      (v_loan1_id, v_user_id, 72, 'healthy', 0.28, 0.12,
       '[{"action":"Continue regular payments","priority":"low"},{"action":"Consider early repayment if cash flow allows","priority":"medium"}]'),
      (v_loan2_id, v_user_id, 68, 'moderate', 0.28, 0.08,
       '[{"action":"Loan is performing well","priority":"low"},{"action":"Asset generating sufficient income","priority":"low"}]'),
      (v_loan3_id, v_user_id, 45, 'high_risk', 0.28, 0.02,
       '[{"action":"High interest rate — prioritize clearing this loan first","priority":"high"},{"action":"Avoid new personal loans","priority":"high"}]');

    INSERT INTO public.debt_health_snapshots (user_id, snapshot_date, total_debt, total_monthly_payment,
      monthly_income, total_assets, dti_ratio, dta_ratio, debt_health_score, risk_level)
    VALUES
      (v_user_id, CURRENT_DATE, 86800000, 4345000, 15500000, 850000000, 0.28, 0.10, 65, 'moderate'),
      (v_user_id, CURRENT_DATE - 30, 89700000, 4345000, 15000000, 840000000, 0.29, 0.11, 62, 'moderate'),
      (v_user_id, CURRENT_DATE - 60, 92600000, 4345000, 14500000, 830000000, 0.30, 0.11, 60, 'moderate'),
      (v_user_id, CURRENT_DATE - 90, 95500000, 4345000, 14000000, 820000000, 0.31, 0.12, 58, 'moderate');

  END IF;
END $$;
