-- ============================================================
-- ADVANCED DECISION ENGINE — Part 10/15
-- Tables: decision_scenarios, scenario_inputs, simulation_results, decision_recommendations
-- ============================================================

-- 1. TABLES

CREATE TABLE IF NOT EXISTS public.decision_scenarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL DEFAULT 'other',
    description TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.scenario_inputs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scenario_id UUID NOT NULL REFERENCES public.decision_scenarios(id) ON DELETE CASCADE,
    input_name VARCHAR(255) NOT NULL,
    input_value DECIMAL(15,2) NOT NULL DEFAULT 0,
    input_type VARCHAR(100) NOT NULL DEFAULT 'amount',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.simulation_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scenario_id UUID NOT NULL REFERENCES public.decision_scenarios(id) ON DELETE CASCADE,
    cash_flow_effect DECIMAL(15,2) DEFAULT 0,
    networth_effect DECIMAL(15,2) DEFAULT 0,
    risk_score INTEGER DEFAULT 50,
    success_probability INTEGER DEFAULT 50,
    opportunity_score INTEGER DEFAULT 50,
    affordability_score INTEGER DEFAULT 50,
    final_decision_score INTEGER DEFAULT 50,
    result_summary TEXT,
    timeline_months INTEGER DEFAULT 12,
    break_even_months INTEGER,
    monthly_impact DECIMAL(15,2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.decision_recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scenario_id UUID REFERENCES public.decision_scenarios(id) ON DELETE CASCADE,
    recommendation TEXT NOT NULL,
    reasoning TEXT,
    risk_level VARCHAR(50) DEFAULT 'medium',
    confidence_score INTEGER DEFAULT 70,
    advantages TEXT,
    disadvantages TEXT,
    suggested_actions TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. INDEXES

CREATE INDEX IF NOT EXISTS idx_decision_scenarios_user_id ON public.decision_scenarios(user_id);
CREATE INDEX IF NOT EXISTS idx_decision_scenarios_category ON public.decision_scenarios(category);
CREATE INDEX IF NOT EXISTS idx_scenario_inputs_scenario_id ON public.scenario_inputs(scenario_id);
CREATE INDEX IF NOT EXISTS idx_simulation_results_scenario_id ON public.simulation_results(scenario_id);
CREATE INDEX IF NOT EXISTS idx_decision_recommendations_scenario_id ON public.decision_recommendations(scenario_id);

-- 3. UPDATED_AT TRIGGER FUNCTION

CREATE OR REPLACE FUNCTION public.update_decision_scenario_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_decision_scenarios_updated_at ON public.decision_scenarios;
CREATE TRIGGER trg_decision_scenarios_updated_at
    BEFORE UPDATE ON public.decision_scenarios
    FOR EACH ROW EXECUTE FUNCTION public.update_decision_scenario_updated_at();

-- 4. ENABLE RLS

ALTER TABLE public.decision_scenarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scenario_inputs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.simulation_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.decision_recommendations ENABLE ROW LEVEL SECURITY;

-- 5. RLS POLICIES

DROP POLICY IF EXISTS "users_manage_own_decision_scenarios" ON public.decision_scenarios;
CREATE POLICY "users_manage_own_decision_scenarios"
ON public.decision_scenarios
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_scenario_inputs" ON public.scenario_inputs;
CREATE POLICY "users_manage_own_scenario_inputs"
ON public.scenario_inputs
FOR ALL
TO authenticated
USING (
    scenario_id IN (
        SELECT id FROM public.decision_scenarios WHERE user_id = auth.uid()
    )
)
WITH CHECK (
    scenario_id IN (
        SELECT id FROM public.decision_scenarios WHERE user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "users_manage_own_simulation_results" ON public.simulation_results;
CREATE POLICY "users_manage_own_simulation_results"
ON public.simulation_results
FOR ALL
TO authenticated
USING (
    scenario_id IN (
        SELECT id FROM public.decision_scenarios WHERE user_id = auth.uid()
    )
)
WITH CHECK (
    scenario_id IN (
        SELECT id FROM public.decision_scenarios WHERE user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "users_manage_own_decision_recommendations" ON public.decision_recommendations;
CREATE POLICY "users_manage_own_decision_recommendations"
ON public.decision_recommendations
FOR ALL
TO authenticated
USING (
    scenario_id IN (
        SELECT id FROM public.decision_scenarios WHERE user_id = auth.uid()
    )
)
WITH CHECK (
    scenario_id IN (
        SELECT id FROM public.decision_scenarios WHERE user_id = auth.uid()
    )
);

-- 6. DEMO DATA — Jonathan's Transport Vehicle Purchase Scenario

DO $$
DECLARE
    existing_user_id UUID;
    scenario_uuid UUID := gen_random_uuid();
    scenario2_uuid UUID := gen_random_uuid();
    scenario3_uuid UUID := gen_random_uuid();
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'user_profiles'
    ) THEN
        SELECT id INTO existing_user_id FROM public.user_profiles LIMIT 1;

        IF existing_user_id IS NOT NULL THEN

            -- Scenario 1: Transport Vehicle Purchase (Jonathan's demo)
            INSERT INTO public.decision_scenarios (id, user_id, name, category, description, status)
            VALUES (
                scenario_uuid,
                existing_user_id,
                'Purchase Transport Vehicle',
                'asset_purchase',
                'Evaluate purchasing a transport bus worth TSh 80 million to generate monthly income of TSh 6 million.',
                'simulated'
            ) ON CONFLICT (id) DO NOTHING;

            INSERT INTO public.scenario_inputs (scenario_id, input_name, input_value, input_type)
            VALUES
                (scenario_uuid, 'Purchase Price', 80000000, 'amount'),
                (scenario_uuid, 'Loan Amount', 50000000, 'amount'),
                (scenario_uuid, 'Interest Rate (%)', 18, 'percentage'),
                (scenario_uuid, 'Loan Duration (months)', 36, 'months'),
                (scenario_uuid, 'Expected Monthly Income', 6000000, 'amount'),
                (scenario_uuid, 'Monthly Operating Costs', 1500000, 'amount'),
                (scenario_uuid, 'Down Payment', 30000000, 'amount')
            ON CONFLICT (id) DO NOTHING;

            INSERT INTO public.simulation_results (
                scenario_id, cash_flow_effect, networth_effect, risk_score,
                success_probability, opportunity_score, affordability_score,
                final_decision_score, result_summary, timeline_months,
                break_even_months, monthly_impact
            ) VALUES (
                scenario_uuid,
                -30000000,
                50000000,
                42,
                72,
                78,
                65,
                67,
                'The transport vehicle purchase shows positive long-term potential. Expected monthly income of TSh 6M exceeds monthly loan repayment of TSh 1.8M and operating costs of TSh 1.5M, yielding a net monthly surplus of TSh 2.7M. Break-even is projected at 30 months. Initial cash reduction of TSh 30M (down payment) is manageable given current assets of TSh 300M.',
                36,
                30,
                2700000
            ) ON CONFLICT (id) DO NOTHING;

            INSERT INTO public.decision_recommendations (
                scenario_id, recommendation, reasoning, risk_level,
                confidence_score, advantages, disadvantages, suggested_actions
            ) VALUES (
                scenario_uuid,
                'PROCEED WITH CAUTION — The purchase is financially viable but requires careful cash flow management.',
                'Your current assets of TSh 300M and monthly income of TSh 8M provide a strong foundation. The vehicle will generate TSh 6M monthly against TSh 3.3M in total obligations, creating a TSh 2.7M monthly surplus. However, your debt ratio will increase from 16.7% to 29.4% after the loan.',
                'medium',
                72,
                'Positive monthly cash flow of TSh 2.7M after all costs. Asset appreciates operational capacity. Loan-to-income ratio remains manageable. Break-even in 30 months is reasonable.',
                'Debt ratio increases significantly. Initial TSh 30M cash outflow reduces liquidity. Vehicle maintenance costs may increase over time. Market demand uncertainty.',
                'Negotiate loan interest rate below 18%. Secure transport contracts before purchase. Maintain TSh 20M emergency reserve. Review after 6 months of operation.'
            ) ON CONFLICT (id) DO NOTHING;

            -- Scenario 2: Business Expansion
            INSERT INTO public.decision_scenarios (id, user_id, name, category, description, status)
            VALUES (
                scenario2_uuid,
                existing_user_id,
                'Expand Transport Business',
                'business_expansion',
                'Add second vehicle and hire additional driver to double transport capacity.',
                'draft'
            ) ON CONFLICT (id) DO NOTHING;

            INSERT INTO public.scenario_inputs (scenario_id, input_name, input_value, input_type)
            VALUES
                (scenario2_uuid, 'Expansion Cost', 120000000, 'amount'),
                (scenario2_uuid, 'Expected Revenue Increase', 10000000, 'amount'),
                (scenario2_uuid, 'Additional Monthly Expenses', 3000000, 'amount'),
                (scenario2_uuid, 'Additional Employees', 2, 'count')
            ON CONFLICT (id) DO NOTHING;

            -- Scenario 3: Investment Simulator
            INSERT INTO public.decision_scenarios (id, user_id, name, category, description, status)
            VALUES (
                scenario3_uuid,
                existing_user_id,
                'Real Estate Investment',
                'investment',
                'Invest TSh 50M in commercial real estate with expected 15% annual return.',
                'draft'
            ) ON CONFLICT (id) DO NOTHING;

            INSERT INTO public.scenario_inputs (scenario_id, input_name, input_value, input_type)
            VALUES
                (scenario3_uuid, 'Investment Amount', 50000000, 'amount'),
                (scenario3_uuid, 'Expected Annual Return (%)', 15, 'percentage'),
                (scenario3_uuid, 'Investment Period (years)', 5, 'years'),
                (scenario3_uuid, 'Risk Level', 3, 'scale')
            ON CONFLICT (id) DO NOTHING;

        ELSE
            RAISE NOTICE 'No users found. Run auth migration first.';
        END IF;
    ELSE
        RAISE NOTICE 'Table user_profiles does not exist.';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Decision engine demo data failed: %', SQLERRM;
END $$;
