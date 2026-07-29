-- ============================================================
-- INVESTMENT INTELLIGENCE ENGINE
-- Migration: 20260725250000_investment_intelligence_engine.sql
-- ============================================================

-- Investment Portfolios
CREATE TABLE IF NOT EXISTS public.investment_portfolios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  purpose TEXT DEFAULT 'general',
  description TEXT,
  currency TEXT DEFAULT 'TZS',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Investments
CREATE TABLE IF NOT EXISTS public.investments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  portfolio_id UUID NOT NULL REFERENCES public.investment_portfolios(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('real_estate','business','stocks','agriculture','digital','other')),
  description TEXT,
  initial_value NUMERIC(18,2) NOT NULL DEFAULT 0,
  current_value NUMERIC(18,2) NOT NULL DEFAULT 0,
  currency TEXT DEFAULT 'TZS',
  ownership_percentage NUMERIC(5,2) DEFAULT 100,
  expected_return_rate NUMERIC(5,2) DEFAULT 0,
  investment_date DATE NOT NULL DEFAULT CURRENT_DATE,
  target_exit_date DATE,
  status TEXT DEFAULT 'active' CHECK (status IN ('active','exited','paused','monitoring')),
  risk_level TEXT DEFAULT 'medium' CHECK (risk_level IN ('low','medium','high','very_high')),
  location TEXT,
  notes TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Investment Transactions (contributions, distributions, dividends)
CREATE TABLE IF NOT EXISTS public.investment_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  investment_id UUID NOT NULL REFERENCES public.investments(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('contribution','distribution','dividend','rental_income','sale_proceeds','other')),
  amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  description TEXT,
  transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Returns History (periodic value snapshots)
CREATE TABLE IF NOT EXISTS public.investment_returns_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  investment_id UUID NOT NULL REFERENCES public.investments(id) ON DELETE CASCADE,
  value NUMERIC(18,2) NOT NULL DEFAULT 0,
  profit NUMERIC(18,2) NOT NULL DEFAULT 0,
  roi_percentage NUMERIC(8,4) DEFAULT 0,
  snapshot_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Risk Analysis
CREATE TABLE IF NOT EXISTS public.investment_risk_analysis (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  investment_id UUID NOT NULL REFERENCES public.investments(id) ON DELETE CASCADE,
  risk_score NUMERIC(5,2) DEFAULT 50,
  market_risk NUMERIC(5,2) DEFAULT 50,
  liquidity_risk NUMERIC(5,2) DEFAULT 50,
  operational_risk NUMERIC(5,2) DEFAULT 50,
  concentration_risk NUMERIC(5,2) DEFAULT 50,
  factors JSONB DEFAULT '[]',
  recommendations TEXT,
  analysis_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_investment_portfolios_owner ON public.investment_portfolios(owner_id);
CREATE INDEX IF NOT EXISTS idx_investments_portfolio ON public.investments(portfolio_id);
CREATE INDEX IF NOT EXISTS idx_investments_owner ON public.investments(owner_id);
CREATE INDEX IF NOT EXISTS idx_investment_transactions_investment ON public.investment_transactions(investment_id);
CREATE INDEX IF NOT EXISTS idx_investment_returns_investment ON public.investment_returns_history(investment_id);
CREATE INDEX IF NOT EXISTS idx_investment_risk_investment ON public.investment_risk_analysis(investment_id);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE public.investment_portfolios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.investments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.investment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.investment_returns_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.investment_risk_analysis ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='investment_portfolios' AND policyname='investment_portfolios_owner') THEN
    CREATE POLICY investment_portfolios_owner ON public.investment_portfolios FOR ALL USING (auth.uid() = owner_id) WITH CHECK (auth.uid() = owner_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='investments' AND policyname='investments_owner') THEN
    CREATE POLICY investments_owner ON public.investments FOR ALL USING (auth.uid() = owner_id) WITH CHECK (auth.uid() = owner_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='investment_transactions' AND policyname='investment_transactions_owner') THEN
    CREATE POLICY investment_transactions_owner ON public.investment_transactions FOR ALL USING (auth.uid() = owner_id) WITH CHECK (auth.uid() = owner_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='investment_returns_history' AND policyname='investment_returns_history_owner') THEN
    CREATE POLICY investment_returns_history_owner ON public.investment_returns_history FOR ALL USING (
      investment_id IN (SELECT id FROM public.investments WHERE owner_id = auth.uid())
    );
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='investment_risk_analysis' AND policyname='investment_risk_analysis_owner') THEN
    CREATE POLICY investment_risk_analysis_owner ON public.investment_risk_analysis FOR ALL USING (
      investment_id IN (SELECT id FROM public.investments WHERE owner_id = auth.uid())
    );
  END IF;
END $$;

-- ============================================================
-- TRIGGER: Update net_worth_snapshots when investments change
-- ============================================================
CREATE OR REPLACE FUNCTION public.sync_investment_net_worth()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_owner_id UUID;
  v_total_investments NUMERIC(18,2);
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_owner_id := OLD.owner_id;
  ELSE
    v_owner_id := NEW.owner_id;
  END IF;

  SELECT COALESCE(SUM(current_value), 0)
    INTO v_total_investments
    FROM public.investments
   WHERE owner_id = v_owner_id AND is_active = true AND status = 'active';

  INSERT INTO public.net_worth_snapshots (user_id, total_investments, snapshot_date)
  VALUES (v_owner_id, v_total_investments, CURRENT_DATE)
  ON CONFLICT (user_id, snapshot_date)
  DO UPDATE SET
    total_investments = EXCLUDED.total_investments,
    updated_at = now();

  RETURN COALESCE(NEW, OLD);
EXCEPTION WHEN OTHERS THEN
  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_investment_net_worth ON public.investments;
CREATE TRIGGER trg_investment_net_worth
  AFTER INSERT OR UPDATE OR DELETE ON public.investments
  FOR EACH ROW EXECUTE FUNCTION public.sync_investment_net_worth();

-- ============================================================
-- DEMO DATA
-- ============================================================
DO $$
DECLARE
  v_user_id UUID;
  v_portfolio1_id UUID;
  v_portfolio2_id UUID;
  v_inv1_id UUID;
  v_inv2_id UUID;
  v_inv3_id UUID;
  v_inv4_id UUID;
  v_inv5_id UUID;
BEGIN
  SELECT id INTO v_user_id FROM auth.users LIMIT 1;
  IF v_user_id IS NULL THEN RETURN; END IF;

  -- Portfolios
  INSERT INTO public.investment_portfolios (id, owner_id, name, purpose, description)
  VALUES
    (gen_random_uuid(), v_user_id, 'Personal Wealth Portfolio', 'wealth_building', 'Long-term personal wealth accumulation'),
    (gen_random_uuid(), v_user_id, 'Business Investment Portfolio', 'business_growth', 'Strategic business and expansion investments')
  ON CONFLICT DO NOTHING
  RETURNING id INTO v_portfolio1_id;

  SELECT id INTO v_portfolio1_id FROM public.investment_portfolios WHERE owner_id = v_user_id AND name = 'Personal Wealth Portfolio' LIMIT 1;
  SELECT id INTO v_portfolio2_id FROM public.investment_portfolios WHERE owner_id = v_user_id AND name = 'Business Investment Portfolio' LIMIT 1;

  IF v_portfolio1_id IS NULL OR v_portfolio2_id IS NULL THEN RETURN; END IF;

  -- Check if investments already exist
  IF EXISTS (SELECT 1 FROM public.investments WHERE owner_id = v_user_id LIMIT 1) THEN RETURN; END IF;

  -- Investments
  v_inv1_id := gen_random_uuid();
  v_inv2_id := gen_random_uuid();
  v_inv3_id := gen_random_uuid();
  v_inv4_id := gen_random_uuid();
  v_inv5_id := gen_random_uuid();

  INSERT INTO public.investments (id, portfolio_id, owner_id, name, category, description, initial_value, current_value, ownership_percentage, expected_return_rate, investment_date, target_exit_date, status, risk_level, location)
  VALUES
    (v_inv1_id, v_portfolio1_id, v_user_id, 'Mikocheni Residential Plot', 'real_estate', '500 sqm residential land in Mikocheni, Dar es Salaam', 45000000, 72000000, 100, 15, '2022-03-15', '2027-03-15', 'active', 'low', 'Mikocheni, Dar es Salaam'),
    (v_inv2_id, v_portfolio1_id, v_user_id, 'Nexus Transport Ltd Shares', 'business', '35% ownership stake in Nexus Transport Ltd', 30000000, 48500000, 35, 22, '2021-06-01', '2026-12-31', 'active', 'medium', 'Dar es Salaam'),
    (v_inv3_id, v_portfolio1_id, v_user_id, 'Maize Farm – Morogoro', 'agriculture', '10-acre maize farm with seasonal harvests', 12000000, 15800000, 100, 28, '2023-01-10', '2025-12-31', 'active', 'medium', 'Morogoro Region'),
    (v_inv4_id, v_portfolio2_id, v_user_id, 'Arusha Commercial Building', 'real_estate', 'Ground-floor commercial space generating rental income', 80000000, 95000000, 60, 12, '2020-09-20', '2030-09-20', 'active', 'low', 'Arusha CBD'),
    (v_inv5_id, v_portfolio2_id, v_user_id, 'Bitcoin & Crypto Holdings', 'digital', 'Diversified crypto portfolio – BTC, ETH, USDT', 8000000, 11200000, 100, 40, '2023-07-01', NULL, 'active', 'very_high', 'Digital');

  -- Transactions
  INSERT INTO public.investment_transactions (investment_id, owner_id, type, amount, description, transaction_date)
  VALUES
    (v_inv1_id, v_user_id, 'contribution', 45000000, 'Initial land purchase', '2022-03-15'),
    (v_inv2_id, v_user_id, 'contribution', 30000000, 'Initial stake purchase', '2021-06-01'),
    (v_inv2_id, v_user_id, 'dividend', 3500000, 'Annual profit distribution Q4 2024', '2024-12-31'),
    (v_inv2_id, v_user_id, 'dividend', 4200000, 'Annual profit distribution Q4 2023', '2023-12-31'),
    (v_inv3_id, v_user_id, 'contribution', 12000000, 'Farm setup and first season', '2023-01-10'),
    (v_inv3_id, v_user_id, 'distribution', 4800000, 'Harvest revenue Season 1', '2023-08-15'),
    (v_inv3_id, v_user_id, 'distribution', 5600000, 'Harvest revenue Season 2', '2024-08-20'),
    (v_inv4_id, v_user_id, 'contribution', 80000000, 'Building acquisition', '2020-09-20'),
    (v_inv4_id, v_user_id, 'rental_income', 2400000, 'Monthly rental – Jan 2025', '2025-01-31'),
    (v_inv4_id, v_user_id, 'rental_income', 2400000, 'Monthly rental – Feb 2025', '2025-02-28'),
    (v_inv4_id, v_user_id, 'rental_income', 2400000, 'Monthly rental – Mar 2025', '2025-03-31'),
    (v_inv5_id, v_user_id, 'contribution', 8000000, 'Initial crypto purchase', '2023-07-01');

  -- Returns history (monthly snapshots)
  INSERT INTO public.investment_returns_history (investment_id, value, profit, roi_percentage, snapshot_date)
  VALUES
    (v_inv1_id, 50000000, 5000000, 11.11, '2022-12-31'),
    (v_inv1_id, 58000000, 13000000, 28.89, '2023-12-31'),
    (v_inv1_id, 65000000, 20000000, 44.44, '2024-06-30'),
    (v_inv1_id, 72000000, 27000000, 60.00, '2025-01-31'),
    (v_inv2_id, 35000000, 5000000, 16.67, '2022-12-31'),
    (v_inv2_id, 40000000, 10000000, 33.33, '2023-12-31'),
    (v_inv2_id, 44000000, 14000000, 46.67, '2024-06-30'),
    (v_inv2_id, 48500000, 18500000, 61.67, '2025-01-31'),
    (v_inv3_id, 13500000, 1500000, 12.50, '2023-08-31'),
    (v_inv3_id, 15000000, 3000000, 25.00, '2024-08-31'),
    (v_inv3_id, 15800000, 3800000, 31.67, '2025-01-31'),
    (v_inv4_id, 82000000, 2000000, 2.50, '2021-09-30'),
    (v_inv4_id, 86000000, 6000000, 7.50, '2022-09-30'),
    (v_inv4_id, 90000000, 10000000, 12.50, '2023-09-30'),
    (v_inv4_id, 95000000, 15000000, 18.75, '2025-01-31'),
    (v_inv5_id, 6000000, -2000000, -25.00, '2023-12-31'),
    (v_inv5_id, 9500000, 1500000, 18.75, '2024-06-30'),
    (v_inv5_id, 11200000, 3200000, 40.00, '2025-01-31');

  -- Risk analysis
  INSERT INTO public.investment_risk_analysis (investment_id, risk_score, market_risk, liquidity_risk, operational_risk, concentration_risk, recommendations, analysis_date)
  VALUES
    (v_inv1_id, 25, 20, 35, 15, 30, 'Low-risk land investment. Consider developing to increase rental yield.', CURRENT_DATE),
    (v_inv2_id, 48, 50, 55, 40, 45, 'Moderate risk. Business performance is strong but monitor fuel cost trends.', CURRENT_DATE),
    (v_inv3_id, 55, 60, 50, 65, 40, 'Seasonal risk is high. Diversify crops to reduce weather dependency.', CURRENT_DATE),
    (v_inv4_id, 30, 25, 40, 20, 35, 'Stable rental income. Ensure lease renewals are secured 6 months ahead.', CURRENT_DATE),
    (v_inv5_id, 82, 90, 70, 75, 85, 'Very high volatility. Limit crypto to max 10% of total portfolio.', CURRENT_DATE);

END $$;
