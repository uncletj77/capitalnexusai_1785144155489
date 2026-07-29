-- ============================================================
-- CAPITAL NEXUS AI — Personal Financial Operating System
-- Migration: 20260725210000_financial_system.sql
-- ============================================================

-- ============================================================
-- 1. ENUM TYPES
-- ============================================================

DROP TYPE IF EXISTS public.account_category CASCADE;
CREATE TYPE public.account_category AS ENUM ('bank', 'mobile_money', 'cash', 'investment', 'other');

DROP TYPE IF EXISTS public.transaction_type CASCADE;
CREATE TYPE public.transaction_type AS ENUM ('income', 'expense', 'transfer', 'investment', 'loan_activity');

DROP TYPE IF EXISTS public.income_frequency CASCADE;
CREATE TYPE public.income_frequency AS ENUM ('daily', 'weekly', 'monthly', 'quarterly', 'annually', 'one_time');

DROP TYPE IF EXISTS public.budget_period CASCADE;
CREATE TYPE public.budget_period AS ENUM ('weekly', 'monthly', 'quarterly', 'annually');

DROP TYPE IF EXISTS public.goal_status CASCADE;
CREATE TYPE public.goal_status AS ENUM ('active', 'completed', 'paused', 'cancelled');

-- ============================================================
-- 2. CORE TABLES
-- ============================================================

-- Financial Accounts
CREATE TABLE IF NOT EXISTS public.financial_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    account_name TEXT NOT NULL,
    account_category public.account_category NOT NULL DEFAULT 'bank',
    provider TEXT,
    account_number TEXT,
    currency TEXT NOT NULL DEFAULT 'TZS',
    balance DECIMAL(18,2) NOT NULL DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    color TEXT DEFAULT '#1A5F7A',
    icon TEXT DEFAULT 'account_balance',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Income Sources
CREATE TABLE IF NOT EXISTS public.income_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'other',
    amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    frequency public.income_frequency NOT NULL DEFAULT 'monthly',
    reliability_score INTEGER DEFAULT 80 CHECK (reliability_score BETWEEN 0 AND 100),
    is_active BOOLEAN DEFAULT true,
    description TEXT,
    started_at DATE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Transactions
CREATE TABLE IF NOT EXISTS public.financial_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    account_id UUID REFERENCES public.financial_accounts(id) ON DELETE SET NULL,
    transaction_type public.transaction_type NOT NULL DEFAULT 'expense',
    category TEXT NOT NULL DEFAULT 'other',
    amount DECIMAL(18,2) NOT NULL,
    description TEXT,
    notes TEXT,
    reference_id TEXT,
    related_asset_id UUID,
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    is_recurring BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Budgets
CREATE TABLE IF NOT EXISTS public.budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    planned_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    period public.budget_period NOT NULL DEFAULT 'monthly',
    period_start DATE NOT NULL DEFAULT DATE_TRUNC('month', CURRENT_DATE)::DATE,
    period_end DATE NOT NULL DEFAULT (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month - 1 day')::DATE,
    is_active BOOLEAN DEFAULT true,
    color TEXT DEFAULT '#1A5F7A',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Financial Goals
CREATE TABLE IF NOT EXISTS public.financial_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    target_amount DECIMAL(18,2) NOT NULL,
    current_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    monthly_contribution DECIMAL(18,2) DEFAULT 0,
    deadline DATE,
    goal_status public.goal_status NOT NULL DEFAULT 'active',
    category TEXT DEFAULT 'savings',
    icon TEXT DEFAULT 'flag',
    color TEXT DEFAULT '#1A5F7A',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Net Worth Snapshots (for history tracking)
CREATE TABLE IF NOT EXISTS public.net_worth_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    total_assets DECIMAL(18,2) NOT NULL DEFAULT 0,
    total_liabilities DECIMAL(18,2) NOT NULL DEFAULT 0,
    net_worth DECIMAL(18,2) NOT NULL DEFAULT 0,
    snapshot_date DATE NOT NULL DEFAULT CURRENT_DATE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 3. INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_financial_accounts_user_id ON public.financial_accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_income_sources_user_id ON public.income_sources(user_id);
CREATE INDEX IF NOT EXISTS idx_financial_transactions_user_id ON public.financial_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_financial_transactions_date ON public.financial_transactions(transaction_date);
CREATE INDEX IF NOT EXISTS idx_financial_transactions_type ON public.financial_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_budgets_user_id ON public.budgets(user_id);
CREATE INDEX IF NOT EXISTS idx_financial_goals_user_id ON public.financial_goals(user_id);
CREATE INDEX IF NOT EXISTS idx_net_worth_snapshots_user_id ON public.net_worth_snapshots(user_id);
CREATE INDEX IF NOT EXISTS idx_net_worth_snapshots_date ON public.net_worth_snapshots(snapshot_date);

-- ============================================================
-- 4. ENABLE RLS
-- ============================================================

ALTER TABLE public.financial_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.income_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.net_worth_snapshots ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 5. RLS POLICIES
-- ============================================================

DROP POLICY IF EXISTS "users_manage_own_financial_accounts" ON public.financial_accounts;
CREATE POLICY "users_manage_own_financial_accounts" ON public.financial_accounts
FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_income_sources" ON public.income_sources;
CREATE POLICY "users_manage_own_income_sources" ON public.income_sources
FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_financial_transactions" ON public.financial_transactions;
CREATE POLICY "users_manage_own_financial_transactions" ON public.financial_transactions
FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_budgets" ON public.budgets;
CREATE POLICY "users_manage_own_budgets" ON public.budgets
FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_financial_goals" ON public.financial_goals;
CREATE POLICY "users_manage_own_financial_goals" ON public.financial_goals
FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_net_worth_snapshots" ON public.net_worth_snapshots;
CREATE POLICY "users_manage_own_net_worth_snapshots" ON public.net_worth_snapshots
FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- ============================================================
-- 6. UPDATED_AT TRIGGER FUNCTION
-- ============================================================

CREATE OR REPLACE FUNCTION public.update_financial_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_financial_accounts_updated_at ON public.financial_accounts;
CREATE TRIGGER trg_financial_accounts_updated_at
    BEFORE UPDATE ON public.financial_accounts
    FOR EACH ROW EXECUTE FUNCTION public.update_financial_updated_at();

DROP TRIGGER IF EXISTS trg_income_sources_updated_at ON public.income_sources;
CREATE TRIGGER trg_income_sources_updated_at
    BEFORE UPDATE ON public.income_sources
    FOR EACH ROW EXECUTE FUNCTION public.update_financial_updated_at();

DROP TRIGGER IF EXISTS trg_financial_transactions_updated_at ON public.financial_transactions;
CREATE TRIGGER trg_financial_transactions_updated_at
    BEFORE UPDATE ON public.financial_transactions
    FOR EACH ROW EXECUTE FUNCTION public.update_financial_updated_at();

DROP TRIGGER IF EXISTS trg_budgets_updated_at ON public.budgets;
CREATE TRIGGER trg_budgets_updated_at
    BEFORE UPDATE ON public.budgets
    FOR EACH ROW EXECUTE FUNCTION public.update_financial_updated_at();

DROP TRIGGER IF EXISTS trg_financial_goals_updated_at ON public.financial_goals;
CREATE TRIGGER trg_financial_goals_updated_at
    BEFORE UPDATE ON public.financial_goals
    FOR EACH ROW EXECUTE FUNCTION public.update_financial_updated_at();

-- ============================================================
-- 7. MOCK DATA
-- ============================================================

DO $$
DECLARE
    demo_user_id UUID;
    acc_crdb UUID := gen_random_uuid();
    acc_mpesa UUID := gen_random_uuid();
    acc_cash UUID := gen_random_uuid();
    acc_invest UUID := gen_random_uuid();
BEGIN
    SELECT id INTO demo_user_id FROM public.user_profiles LIMIT 1;

    IF demo_user_id IS NOT NULL THEN

        -- Financial Accounts
        INSERT INTO public.financial_accounts (id, user_id, account_name, account_category, provider, balance, currency, color, icon) VALUES
            (acc_crdb, demo_user_id, 'CRDB Main Account', 'bank', 'CRDB Bank', 18500000, 'TZS', '#1A5F7A', 'account_balance'),
            (acc_mpesa, demo_user_id, 'M-Pesa Wallet', 'mobile_money', 'Vodacom', 3200000, 'TZS', '#4CAF50', 'phone_android'),
            (acc_cash, demo_user_id, 'Office Cash', 'cash', NULL, 1500000, 'TZS', '#F59E0B', 'payments'),
            (acc_invest, demo_user_id, 'Investment Portfolio', 'investment', 'DSE', 22000000, 'TZS', '#8B5CF6', 'trending_up')
        ON CONFLICT (id) DO NOTHING;

        -- Income Sources
        INSERT INTO public.income_sources (user_id, name, category, amount, frequency, reliability_score, description) VALUES
            (demo_user_id, 'Transport Business Revenue', 'business', 4500000, 'monthly', 85, 'Monthly revenue from transport operations'),
            (demo_user_id, 'Rental Income - Kariakoo', 'rental', 1800000, 'monthly', 95, 'Rental from commercial property'),
            (demo_user_id, 'Stock Dividends', 'investment', 450000, 'quarterly', 70, 'DSE portfolio dividends'),
            (demo_user_id, 'Consulting Fees', 'consulting', 800000, 'monthly', 60, 'Business consulting services')
        ON CONFLICT (id) DO NOTHING;

        -- Transactions (last 3 months)
        INSERT INTO public.financial_transactions (user_id, account_id, transaction_type, category, amount, description, transaction_date) VALUES
            (demo_user_id, acc_crdb, 'income', 'business', 4500000, 'Transport Business Revenue - July', CURRENT_DATE - INTERVAL '2 days'),
            (demo_user_id, acc_crdb, 'income', 'rental', 1800000, 'Kariakoo Rental Income', CURRENT_DATE - INTERVAL '3 days'),
            (demo_user_id, acc_mpesa, 'expense', 'fuel', 650000, 'Fuel for transport fleet', CURRENT_DATE - INTERVAL '4 days'),
            (demo_user_id, acc_crdb, 'expense', 'salaries', 1200000, 'Driver salaries - July', CURRENT_DATE - INTERVAL '5 days'),
            (demo_user_id, acc_crdb, 'expense', 'utilities', 180000, 'Electricity & Water bills', CURRENT_DATE - INTERVAL '6 days'),
            (demo_user_id, acc_mpesa, 'expense', 'food', 320000, 'Monthly groceries', CURRENT_DATE - INTERVAL '7 days'),
            (demo_user_id, acc_crdb, 'investment', 'stocks', 500000, 'DSE stock purchase', CURRENT_DATE - INTERVAL '10 days'),
            (demo_user_id, acc_crdb, 'expense', 'maintenance', 420000, 'Vehicle maintenance', CURRENT_DATE - INTERVAL '12 days'),
            (demo_user_id, acc_crdb, 'income', 'consulting', 800000, 'Consulting fee - ABC Ltd', CURRENT_DATE - INTERVAL '15 days'),
            (demo_user_id, acc_mpesa, 'expense', 'transport', 95000, 'Personal transport', CURRENT_DATE - INTERVAL '16 days'),
            (demo_user_id, acc_crdb, 'income', 'business', 4500000, 'Transport Business Revenue - June', CURRENT_DATE - INTERVAL '32 days'),
            (demo_user_id, acc_crdb, 'income', 'rental', 1800000, 'Kariakoo Rental Income - June', CURRENT_DATE - INTERVAL '33 days'),
            (demo_user_id, acc_crdb, 'expense', 'loan_payment', 750000, 'Vehicle loan repayment', CURRENT_DATE - INTERVAL '35 days'),
            (demo_user_id, acc_crdb, 'expense', 'insurance', 280000, 'Vehicle insurance premium', CURRENT_DATE - INTERVAL '40 days'),
            (demo_user_id, acc_invest, 'income', 'dividends', 450000, 'DSE Quarterly Dividends', CURRENT_DATE - INTERVAL '45 days')
        ON CONFLICT (id) DO NOTHING;

        -- Budgets
        INSERT INTO public.budgets (user_id, name, category, planned_amount, period, color) VALUES
            (demo_user_id, 'Housing & Rent', 'housing', 800000, 'monthly', '#1A5F7A'),
            (demo_user_id, 'Food & Groceries', 'food', 500000, 'monthly', '#4CAF50'),
            (demo_user_id, 'Transport', 'transport', 300000, 'monthly', '#F59E0B'),
            (demo_user_id, 'Utilities', 'utilities', 200000, 'monthly', '#EC4899'),
            (demo_user_id, 'Savings', 'savings', 1000000, 'monthly', '#8B5CF6'),
            (demo_user_id, 'Investments', 'investments', 700000, 'monthly', '#2D9CDB'),
            (demo_user_id, 'Business Operations', 'business', 1500000, 'monthly', '#10B981'),
            (demo_user_id, 'Entertainment', 'entertainment', 150000, 'monthly', '#F97316')
        ON CONFLICT (id) DO NOTHING;

        -- Financial Goals
        INSERT INTO public.financial_goals (user_id, name, description, target_amount, current_amount, monthly_contribution, deadline, category, icon, color) VALUES
            (demo_user_id, 'Buy Land in Dodoma', 'Purchase 2 acres of agricultural land', 25000000, 8500000, 1000000, CURRENT_DATE + INTERVAL '18 months', 'property', 'landscape', '#10B981'),
            (demo_user_id, 'Emergency Fund', '6 months of living expenses', 15000000, 6200000, 500000, CURRENT_DATE + INTERVAL '18 months', 'savings', 'savings', '#1A5F7A'),
            (demo_user_id, 'Business Expansion', 'Add 2 more vehicles to transport fleet', 40000000, 12000000, 2000000, CURRENT_DATE + INTERVAL '24 months', 'business', 'business', '#8B5CF6'),
            (demo_user_id, 'Education Fund', 'University fees for children', 20000000, 3500000, 800000, CURRENT_DATE + INTERVAL '36 months', 'education', 'school', '#F59E0B')
        ON CONFLICT (id) DO NOTHING;

        -- Net Worth Snapshots (6 months history)
        INSERT INTO public.net_worth_snapshots (user_id, total_assets, total_liabilities, net_worth, snapshot_date) VALUES
            (demo_user_id, 780000000, 215000000, 565000000, CURRENT_DATE - INTERVAL '5 months'),
            (demo_user_id, 800000000, 210000000, 590000000, CURRENT_DATE - INTERVAL '4 months'),
            (demo_user_id, 820000000, 208000000, 612000000, CURRENT_DATE - INTERVAL '3 months'),
            (demo_user_id, 835000000, 205000000, 630000000, CURRENT_DATE - INTERVAL '2 months'),
            (demo_user_id, 845000000, 202000000, 643000000, CURRENT_DATE - INTERVAL '1 month'),
            (demo_user_id, 850000000, 200000000, 650000000, CURRENT_DATE)
        ON CONFLICT (id) DO NOTHING;

    ELSE
        RAISE NOTICE 'No user found in user_profiles. Run auth migration first.';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Financial mock data insertion failed: %', SQLERRM;
END $$;
