-- ============================================================
-- CASH FLOW INTELLIGENCE ENGINE (CFIE) - Part 8/15
-- Capital NEXUS AI
-- ============================================================

-- TABLE: cash_flow_forecasts
CREATE TABLE IF NOT EXISTS public.cash_flow_forecasts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    forecast_period DATE NOT NULL,
    expected_income DECIMAL(15,2) DEFAULT 0,
    expected_expenses DECIMAL(15,2) DEFAULT 0,
    expected_loan_payments DECIMAL(15,2) DEFAULT 0,
    expected_investment_returns DECIMAL(15,2) DEFAULT 0,
    expected_business_income DECIMAL(15,2) DEFAULT 0,
    projected_cash_balance DECIMAL(15,2),
    confidence_score INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- TABLE: financial_scenarios
CREATE TABLE IF NOT EXISTS public.financial_scenarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    scenario_name VARCHAR(255),
    scenario_type VARCHAR(100),
    assumptions JSONB,
    result JSONB,
    risk_score INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- TABLE: wealth_projections
CREATE TABLE IF NOT EXISTS public.wealth_projections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    projection_date DATE,
    projected_assets DECIMAL(15,2),
    projected_liabilities DECIMAL(15,2),
    projected_networth DECIMAL(15,2),
    growth_percentage DECIMAL(5,2),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- TABLE: financial_goals
CREATE TABLE IF NOT EXISTS public.financial_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    goal_name VARCHAR(255),
    target_amount DECIMAL(15,2),
    current_amount DECIMAL(15,2),
    target_date DATE,
    priority VARCHAR(50),
    goal_status VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- TABLE: ai_financial_insights
CREATE TABLE IF NOT EXISTS public.ai_financial_insights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    insight_type VARCHAR(100),
    message TEXT,
    severity VARCHAR(50),
    related_module VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- INDEXES
CREATE INDEX IF NOT EXISTS idx_cash_flow_forecasts_user_id ON public.cash_flow_forecasts(user_id);
CREATE INDEX IF NOT EXISTS idx_cash_flow_forecasts_period ON public.cash_flow_forecasts(forecast_period);
CREATE INDEX IF NOT EXISTS idx_financial_scenarios_user_id ON public.financial_scenarios(user_id);
CREATE INDEX IF NOT EXISTS idx_wealth_projections_user_id ON public.wealth_projections(user_id);
CREATE INDEX IF NOT EXISTS idx_financial_goals_user_id ON public.financial_goals(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_financial_insights_user_id ON public.ai_financial_insights(user_id);

-- ENABLE RLS
ALTER TABLE public.cash_flow_forecasts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_scenarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wealth_projections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_financial_insights ENABLE ROW LEVEL SECURITY;

-- RLS POLICIES
DROP POLICY IF EXISTS "users_manage_own_cash_flow_forecasts" ON public.cash_flow_forecasts;
CREATE POLICY "users_manage_own_cash_flow_forecasts"
ON public.cash_flow_forecasts FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_financial_scenarios" ON public.financial_scenarios;
CREATE POLICY "users_manage_own_financial_scenarios"
ON public.financial_scenarios FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_wealth_projections" ON public.wealth_projections;
CREATE POLICY "users_manage_own_wealth_projections"
ON public.wealth_projections FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_financial_goals" ON public.financial_goals;
CREATE POLICY "users_manage_own_financial_goals"
ON public.financial_goals FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_ai_financial_insights" ON public.ai_financial_insights;
CREATE POLICY "users_manage_own_ai_financial_insights"
ON public.ai_financial_insights FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- ============================================================
-- DEMO DATA for Jonathan
-- ============================================================
DO $$
DECLARE
    jonathan_id UUID;
    now_date DATE := CURRENT_DATE;
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'user_profiles'
    ) THEN
        SELECT id INTO jonathan_id FROM public.user_profiles LIMIT 1;

        IF jonathan_id IS NOT NULL THEN
            -- Cash Flow Forecasts (next 6 months)
            INSERT INTO public.cash_flow_forecasts (
                id, user_id, forecast_period, expected_income, expected_expenses,
                expected_loan_payments, expected_investment_returns, expected_business_income,
                projected_cash_balance, confidence_score
            ) VALUES
                (gen_random_uuid(), jonathan_id, now_date + INTERVAL '1 month',
                 8000000, 4000000, 500000, 300000, 4500000, 8300000, 88),
                (gen_random_uuid(), jonathan_id, now_date + INTERVAL '2 months',
                 8000000, 4100000, 500000, 320000, 4600000, 8320000, 85),
                (gen_random_uuid(), jonathan_id, now_date + INTERVAL '3 months',
                 8200000, 4200000, 500000, 340000, 4700000, 8540000, 82),
                (gen_random_uuid(), jonathan_id, now_date + INTERVAL '4 months',
                 8200000, 4300000, 500000, 360000, 4800000, 8560000, 80),
                (gen_random_uuid(), jonathan_id, now_date + INTERVAL '5 months',
                 8400000, 4400000, 500000, 380000, 4900000, 8780000, 78),
                (gen_random_uuid(), jonathan_id, now_date + INTERVAL '6 months',
                 8400000, 4500000, 500000, 400000, 5000000, 8800000, 75)
            ON CONFLICT (id) DO NOTHING;

            -- Wealth Projections (5 years)
            INSERT INTO public.wealth_projections (
                id, user_id, projection_date, projected_assets, projected_liabilities,
                projected_networth, growth_percentage
            ) VALUES
                (gen_random_uuid(), jonathan_id, now_date + INTERVAL '1 year',
                 360000000, 42000000, 318000000, 6.00),
                (gen_random_uuid(), jonathan_id, now_date + INTERVAL '2 years',
                 432000000, 35000000, 397000000, 24.84),
                (gen_random_uuid(), jonathan_id, now_date + INTERVAL '3 years',
                 518400000, 28000000, 490400000, 23.52),
                (gen_random_uuid(), jonathan_id, now_date + INTERVAL '4 years',
                 622080000, 21000000, 601080000, 22.57),
                (gen_random_uuid(), jonathan_id, now_date + INTERVAL '5 years',
                 746496000, 14000000, 732496000, 21.86)
            ON CONFLICT (id) DO NOTHING;

            -- Financial Goals
            INSERT INTO public.financial_goals (
                id, user_id, goal_name, target_amount, current_amount,
                target_date, priority, goal_status
            ) VALUES
                (gen_random_uuid(), jonathan_id, 'Reach TZS 1 Billion Net Worth',
                 1000000000, 650000000, now_date + INTERVAL '3 years', 'high', 'active'),
                (gen_random_uuid(), jonathan_id, 'Buy New Transport Bus',
                 45000000, 28000000, now_date + INTERVAL '6 months', 'high', 'active'),
                (gen_random_uuid(), jonathan_id, 'Emergency Fund',
                 50000000, 15000000, now_date + INTERVAL '1 year', 'medium', 'active'),
                (gen_random_uuid(), jonathan_id, 'Clear All Loans',
                 50000000, 12000000, now_date + INTERVAL '2 years', 'medium', 'active'),
                (gen_random_uuid(), jonathan_id, 'Expand Rental Properties',
                 120000000, 45000000, now_date + INTERVAL '4 years', 'low', 'active')
            ON CONFLICT (id) DO NOTHING;

            -- AI Financial Insights
            INSERT INTO public.ai_financial_insights (
                id, user_id, insight_type, message, severity, related_module
            ) VALUES
                (gen_random_uuid(), jonathan_id, 'liquidity',
                 'Your cash flow is positive at TZS 4.3M/month surplus. You have strong liquidity to cover 3+ months of expenses.',
                 'positive', 'finance'),
                (gen_random_uuid(), jonathan_id, 'debt_pressure',
                 'Loan-to-asset ratio is 16.7% — well within safe limits. Monthly loan payments consume only 6.25% of income.',
                 'positive', 'loans'),
                (gen_random_uuid(), jonathan_id, 'asset_productivity',
                 'Transport business generating 34% ROI. Consider expanding fleet by 1-2 vehicles to maximize asset productivity.',
                 'opportunity', 'assets'),
                (gen_random_uuid(), jonathan_id, 'growth_opportunity',
                 'At current growth rate of 20%/year, you will reach TZS 1 Billion net worth by 2029. Reinvesting 30% of profits accelerates this.',
                 'opportunity', 'investments'),
                (gen_random_uuid(), jonathan_id, 'risk_warning',
                 'Fuel costs increased 12% last month. Route optimization could save TZS 580K/month. Review transport routes.',
                 'warning', 'business'),
                (gen_random_uuid(), jonathan_id, 'savings_rate',
                 'Your savings rate is 46.25% of income — excellent. Allocate TZS 2M/month to investment portfolio for compound growth.',
                 'positive', 'finance')
            ON CONFLICT (id) DO NOTHING;

            -- Sample Scenarios
            INSERT INTO public.financial_scenarios (
                id, user_id, scenario_name, scenario_type, assumptions, result, risk_score
            ) VALUES
                (gen_random_uuid(), jonathan_id, 'Buy New Transport Bus',
                 'asset_purchase',
                 jsonb_build_object(
                     'asset_price', 45000000,
                     'payment_method', 'cash',
                     'expected_weekly_revenue', 1500000,
                     'weekly_fuel_cost', 400000
                 ),
                 jsonb_build_object(
                     'cash_impact', -45000000,
                     'monthly_net_gain', 4400000,
                     'break_even_months', 10.2,
                     'roi_percentage', 29.3,
                     'risk_level', 'low'
                 ),
                 25),
                (gen_random_uuid(), jonathan_id, 'Take Business Expansion Loan',
                 'loan',
                 jsonb_build_object(
                     'loan_amount', 80000000,
                     'interest_rate', 18,
                     'duration_months', 36
                 ),
                 jsonb_build_object(
                     'monthly_repayment', 2888000,
                     'total_interest', 23968000,
                     'debt_to_income_ratio', 0.36,
                     'affordability', 'moderate',
                     'risk_level', 'medium'
                 ),
                 55)
            ON CONFLICT (id) DO NOTHING;

        ELSE
            RAISE NOTICE 'No existing users found. Run auth migration first.';
        END IF;
    ELSE
        RAISE NOTICE 'Table user_profiles does not exist. Run auth migration first.';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'CFIE mock data insertion failed: %', SQLERRM;
END $$;
