-- ============================================================
-- CAPITAL NEXUS AI — Asset Intelligence Engine
-- Migration: 20260725220000_asset_intelligence_engine.sql
-- ============================================================

-- ============================================================
-- 1. ENUM TYPES
-- ============================================================

DROP TYPE IF EXISTS public.asset_category CASCADE;
CREATE TYPE public.asset_category AS ENUM (
  'fixed', 'current', 'permanent_strategic', 'temporary'
);

DROP TYPE IF EXISTS public.asset_type CASCADE;
CREATE TYPE public.asset_type AS ENUM (
  'land', 'building', 'vehicle', 'machinery', 'equipment',
  'inventory', 'cash', 'receivable', 'investment', 'business',
  'intangible', 'other'
);

DROP TYPE IF EXISTS public.asset_condition CASCADE;
CREATE TYPE public.asset_condition AS ENUM (
  'new', 'good', 'fair', 'poor', 'requires_replacement'
);

DROP TYPE IF EXISTS public.asset_status CASCADE;
CREATE TYPE public.asset_status AS ENUM (
  'active', 'under_maintenance', 'disposed', 'transferred'
);

DROP TYPE IF EXISTS public.ownership_type CASCADE;
CREATE TYPE public.ownership_type AS ENUM (
  'individual', 'joint', 'business', 'organization'
);

DROP TYPE IF EXISTS public.funding_source CASCADE;
CREATE TYPE public.funding_source AS ENUM (
  'cash', 'loan', 'investment', 'business_income', 'gift', 'other'
);

DROP TYPE IF EXISTS public.lifecycle_stage CASCADE;
CREATE TYPE public.lifecycle_stage AS ENUM (
  'acquisition', 'active', 'maintenance', 'replacement_due', 'disposed'
);

DROP TYPE IF EXISTS public.maintenance_type CASCADE;
CREATE TYPE public.maintenance_type AS ENUM (
  'routine', 'repair', 'overhaul', 'inspection', 'insurance', 'other'
);

-- ============================================================
-- 2. CORE ASSET TABLES
-- ============================================================

-- Main Assets Table
CREATE TABLE IF NOT EXISTS public.assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    asset_name TEXT NOT NULL,
    asset_category public.asset_category NOT NULL DEFAULT 'fixed',
    asset_type public.asset_type NOT NULL DEFAULT 'other',
    description TEXT,
    asset_condition public.asset_condition NOT NULL DEFAULT 'good',
    asset_status public.asset_status NOT NULL DEFAULT 'active',
    lifecycle_stage public.lifecycle_stage NOT NULL DEFAULT 'active',
    -- Financial
    purchase_price DECIMAL(18,2) NOT NULL DEFAULT 0,
    current_value DECIMAL(18,2) NOT NULL DEFAULT 0,
    market_value DECIMAL(18,2),
    currency TEXT NOT NULL DEFAULT 'TZS',
    purchase_date DATE,
    funding_source public.funding_source NOT NULL DEFAULT 'cash',
    related_loan_id UUID,
    -- Depreciation
    useful_life_years INTEGER DEFAULT 10,
    depreciation_rate DECIMAL(5,2) DEFAULT 10.0,
    -- Ownership
    ownership_type public.ownership_type NOT NULL DEFAULT 'individual',
    owner_name TEXT,
    -- Location
    country TEXT DEFAULT 'Tanzania',
    region TEXT,
    address TEXT,
    gps_lat DECIMAL(10,7),
    gps_lng DECIMAL(10,7),
    -- Income tracking
    monthly_income DECIMAL(18,2) DEFAULT 0,
    monthly_expenses DECIMAL(18,2) DEFAULT 0,
    -- Metadata
    icon TEXT DEFAULT 'real_estate_agent',
    color TEXT DEFAULT '#1A5F7A',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Asset Ownership (joint/business ownership)
CREATE TABLE IF NOT EXISTS public.asset_ownership (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id UUID NOT NULL REFERENCES public.assets(id) ON DELETE CASCADE,
    owner_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    owner_name TEXT NOT NULL,
    ownership_percentage DECIMAL(5,2) NOT NULL DEFAULT 100.0,
    contribution_amount DECIMAL(18,2) DEFAULT 0,
    ownership_type public.ownership_type NOT NULL DEFAULT 'individual',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Asset Transactions (income/expense linked to asset)
CREATE TABLE IF NOT EXISTS public.asset_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id UUID NOT NULL REFERENCES public.assets(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    transaction_type TEXT NOT NULL DEFAULT 'income',
    amount DECIMAL(18,2) NOT NULL,
    description TEXT,
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Asset Maintenance Records
CREATE TABLE IF NOT EXISTS public.asset_maintenance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id UUID NOT NULL REFERENCES public.assets(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    maintenance_type public.maintenance_type NOT NULL DEFAULT 'routine',
    service_description TEXT NOT NULL,
    cost DECIMAL(18,2) NOT NULL DEFAULT 0,
    service_date DATE NOT NULL DEFAULT CURRENT_DATE,
    next_service_date DATE,
    service_provider TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Asset Valuation History
CREATE TABLE IF NOT EXISTS public.asset_valuations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id UUID NOT NULL REFERENCES public.assets(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    previous_value DECIMAL(18,2) NOT NULL DEFAULT 0,
    new_value DECIMAL(18,2) NOT NULL,
    valuation_date DATE NOT NULL DEFAULT CURRENT_DATE,
    valuation_method TEXT DEFAULT 'manual',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 3. SYSTEM CONNECTIVITY: Net Worth Auto-Update Function
-- ============================================================

-- Function to recalculate and snapshot net worth when assets change
CREATE OR REPLACE FUNCTION public.recalculate_net_worth(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
DECLARE
    v_total_assets DECIMAL(18,2) := 0;
    v_total_liabilities DECIMAL(18,2) := 0;
    v_net_worth DECIMAL(18,2) := 0;
BEGIN
    -- Sum all active asset values
    SELECT COALESCE(SUM(current_value), 0)
    INTO v_total_assets
    FROM public.assets
    WHERE user_id = p_user_id AND asset_status != 'disposed';

    -- Add financial account balances
    SELECT v_total_assets + COALESCE(SUM(balance), 0)
    INTO v_total_assets
    FROM public.financial_accounts
    WHERE user_id = p_user_id AND is_active = true;

    -- Sum liabilities (from financial transactions of type loan_activity outgoing)
    -- Use a simple estimate: total_assets * 0.235 as placeholder until loan module
    v_total_liabilities := v_total_assets * 0.235;

    v_net_worth := v_total_assets - v_total_liabilities;

    -- Upsert today's snapshot
    INSERT INTO public.net_worth_snapshots (user_id, total_assets, total_liabilities, net_worth, snapshot_date)
    VALUES (p_user_id, v_total_assets, v_total_liabilities, v_net_worth, CURRENT_DATE)
    ON CONFLICT (user_id, snapshot_date)
    DO UPDATE SET
        total_assets = EXCLUDED.total_assets,
        total_liabilities = EXCLUDED.total_liabilities,
        net_worth = EXCLUDED.net_worth;
END;
$func$;

-- Unique index for net_worth_snapshots upsert
CREATE UNIQUE INDEX IF NOT EXISTS idx_net_worth_snapshots_user_date
    ON public.net_worth_snapshots(user_id, snapshot_date);

-- Trigger function: when asset value changes, update net worth
CREATE OR REPLACE FUNCTION public.trg_asset_net_worth_sync()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM public.recalculate_net_worth(OLD.user_id);
    ELSE
        PERFORM public.recalculate_net_worth(NEW.user_id);
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$func$;

DROP TRIGGER IF EXISTS trg_assets_net_worth ON public.assets;
CREATE TRIGGER trg_assets_net_worth
    AFTER INSERT OR UPDATE OR DELETE ON public.assets
    FOR EACH ROW EXECUTE FUNCTION public.trg_asset_net_worth_sync();

-- Trigger function: when financial transaction is added, update account balance
CREATE OR REPLACE FUNCTION public.trg_transaction_balance_sync()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
BEGIN
    IF NEW.account_id IS NOT NULL THEN
        IF NEW.transaction_type = 'income' THEN
            UPDATE public.financial_accounts
            SET balance = balance + NEW.amount, updated_at = CURRENT_TIMESTAMP
            WHERE id = NEW.account_id;
        ELSIF NEW.transaction_type = 'expense' THEN
            UPDATE public.financial_accounts
            SET balance = balance - NEW.amount, updated_at = CURRENT_TIMESTAMP
            WHERE id = NEW.account_id;
        END IF;
        -- Recalculate net worth after balance change
        PERFORM public.recalculate_net_worth(NEW.user_id);
    END IF;
    RETURN NEW;
END;
$func$;

DROP TRIGGER IF EXISTS trg_financial_transactions_balance ON public.financial_transactions;
CREATE TRIGGER trg_financial_transactions_balance
    AFTER INSERT ON public.financial_transactions
    FOR EACH ROW EXECUTE FUNCTION public.trg_transaction_balance_sync();

-- ============================================================
-- 4. INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_assets_user_id ON public.assets(user_id);
CREATE INDEX IF NOT EXISTS idx_assets_category ON public.assets(asset_category);
CREATE INDEX IF NOT EXISTS idx_assets_status ON public.assets(asset_status);
CREATE INDEX IF NOT EXISTS idx_asset_ownership_asset_id ON public.asset_ownership(asset_id);
CREATE INDEX IF NOT EXISTS idx_asset_transactions_asset_id ON public.asset_transactions(asset_id);
CREATE INDEX IF NOT EXISTS idx_asset_transactions_user_id ON public.asset_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_asset_maintenance_asset_id ON public.asset_maintenance(asset_id);
CREATE INDEX IF NOT EXISTS idx_asset_valuations_asset_id ON public.asset_valuations(asset_id);

-- ============================================================
-- 5. ENABLE RLS
-- ============================================================

ALTER TABLE public.assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.asset_ownership ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.asset_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.asset_maintenance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.asset_valuations ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 6. RLS POLICIES
-- ============================================================

DROP POLICY IF EXISTS "users_manage_own_assets" ON public.assets;
CREATE POLICY "users_manage_own_assets" ON public.assets
FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_asset_ownership" ON public.asset_ownership;
CREATE POLICY "users_manage_own_asset_ownership" ON public.asset_ownership
FOR ALL TO authenticated
USING (asset_id IN (SELECT id FROM public.assets WHERE user_id = auth.uid()))
WITH CHECK (asset_id IN (SELECT id FROM public.assets WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "users_manage_own_asset_transactions" ON public.asset_transactions;
CREATE POLICY "users_manage_own_asset_transactions" ON public.asset_transactions
FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_asset_maintenance" ON public.asset_maintenance;
CREATE POLICY "users_manage_own_asset_maintenance" ON public.asset_maintenance
FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_asset_valuations" ON public.asset_valuations;
CREATE POLICY "users_manage_own_asset_valuations" ON public.asset_valuations
FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- ============================================================
-- 7. UPDATED_AT TRIGGER
-- ============================================================

CREATE OR REPLACE FUNCTION public.update_assets_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_assets_updated_at ON public.assets;
CREATE TRIGGER trg_assets_updated_at
    BEFORE UPDATE ON public.assets
    FOR EACH ROW EXECUTE FUNCTION public.update_assets_updated_at();

-- ============================================================
-- 8. MOCK DATA
-- ============================================================

DO $$
DECLARE
    demo_user_id UUID;
    asset_land UUID := gen_random_uuid();
    asset_bus UUID := gen_random_uuid();
    asset_apt UUID := gen_random_uuid();
    asset_biz UUID := gen_random_uuid();
    asset_forex UUID := gen_random_uuid();
    asset_equip UUID := gen_random_uuid();
BEGIN
    SELECT id INTO demo_user_id FROM public.user_profiles LIMIT 1;

    IF demo_user_id IS NOT NULL THEN

        -- Core Assets
        INSERT INTO public.assets (
            id, user_id, asset_name, asset_category, asset_type,
            description, asset_condition, asset_status, lifecycle_stage,
            purchase_price, current_value, market_value, purchase_date,
            funding_source, useful_life_years, depreciation_rate,
            ownership_type, monthly_income, monthly_expenses,
            region, address, icon, color
        ) VALUES
        (
            asset_land, demo_user_id,
            'Kijitonyama Land Plot', 'permanent_strategic', 'land',
            '800 sqm residential plot in prime Kijitonyama area',
            'good', 'active', 'active',
            85000000, 142000000, 155000000, '2019-06-10',
            'cash', 50, 0,
            'individual', 0, 0,
            'Dar es Salaam', 'Kijitonyama, Dar es Salaam',
            'landscape', '#8B5CF6'
        ),
        (
            asset_bus, demo_user_id,
            'Toyota Hiace Bus', 'fixed', 'vehicle',
            '14-seater minibus used for transport business operations',
            'good', 'active', 'active',
            65000000, 48000000, 46000000, '2021-01-20',
            'loan', 8, 12.5,
            'individual', 3000000, 800000,
            'Dar es Salaam', 'Dar es Salaam',
            'directions_bus', '#F59E0B'
        ),
        (
            asset_apt, demo_user_id,
            'Mbezi Beach Apartment', 'permanent_strategic', 'building',
            '3-bedroom apartment generating rental income',
            'good', 'active', 'active',
            180000000, 245000000, 260000000, '2018-11-05',
            'loan', 50, 0,
            'individual', 4500000, 300000,
            'Dar es Salaam', 'Mbezi Beach, Dar es Salaam',
            'apartment', '#1A5F7A'
        ),
        (
            asset_biz, demo_user_id,
            'Transport Business', 'permanent_strategic', 'business',
            'Fleet transport company with 3 buses and 2 bajajis',
            'good', 'active', 'active',
            120000000, 228400000, 240000000, '2020-08-01',
            'business_income', 20, 0,
            'individual', 18500000, 12200000,
            'Dar es Salaam', 'Kariakoo, Dar es Salaam',
            'business', '#10B981'
        ),
        (
            asset_forex, demo_user_id,
            'Forex Investment (USD)', 'temporary', 'investment',
            'USD/TZS forex trading position',
            'good', 'active', 'active',
            30000000, 38500000, 38500000, '2024-05-20',
            'investment', 1, 0,
            'individual', 2100000, 150000,
            'Online', 'Online Trading Platform',
            'currency_exchange', '#2D9CDB'
        ),
        (
            asset_equip, demo_user_id,
            'Dell Laptop & Equipment', 'current', 'equipment',
            'Business computing equipment',
            'fair', 'active', 'active',
            4500000, 2800000, 2500000, '2023-02-14',
            'cash', 4, 25,
            'individual', 0, 50000,
            'Dar es Salaam', 'Office, Dar es Salaam',
            'computer', '#EC4899'
        )
        ON CONFLICT (id) DO NOTHING;

        -- Asset Ownership records
        INSERT INTO public.asset_ownership (asset_id, owner_id, owner_name, ownership_percentage, contribution_amount, ownership_type)
        VALUES
            (asset_land, demo_user_id, 'Jonathan', 100, 85000000, 'individual'),
            (asset_bus, demo_user_id, 'Jonathan', 100, 65000000, 'individual'),
            (asset_apt, demo_user_id, 'Jonathan', 100, 180000000, 'individual'),
            (asset_biz, demo_user_id, 'Jonathan', 80, 96000000, 'business'),
            (asset_forex, demo_user_id, 'Jonathan', 100, 30000000, 'individual'),
            (asset_equip, demo_user_id, 'Jonathan', 100, 4500000, 'individual')
        ON CONFLICT (id) DO NOTHING;

        -- Asset Transactions (income/expense per asset)
        INSERT INTO public.asset_transactions (asset_id, user_id, transaction_type, amount, description, transaction_date)
        VALUES
            (asset_bus, demo_user_id, 'income', 3000000, 'Monthly transport revenue', CURRENT_DATE - INTERVAL '5 days'),
            (asset_bus, demo_user_id, 'expense', 800000, 'Fuel and maintenance', CURRENT_DATE - INTERVAL '5 days'),
            (asset_apt, demo_user_id, 'income', 4500000, 'Monthly rental income', CURRENT_DATE - INTERVAL '3 days'),
            (asset_apt, demo_user_id, 'expense', 300000, 'Property maintenance', CURRENT_DATE - INTERVAL '3 days'),
            (asset_biz, demo_user_id, 'income', 18500000, 'Business revenue', CURRENT_DATE - INTERVAL '2 days'),
            (asset_biz, demo_user_id, 'expense', 12200000, 'Business operating costs', CURRENT_DATE - INTERVAL '2 days'),
            (asset_forex, demo_user_id, 'income', 2100000, 'Forex profit', CURRENT_DATE - INTERVAL '10 days')
        ON CONFLICT (id) DO NOTHING;

        -- Maintenance Records
        INSERT INTO public.asset_maintenance (asset_id, user_id, maintenance_type, service_description, cost, service_date, next_service_date, service_provider)
        VALUES
            (asset_bus, demo_user_id, 'routine', 'Oil change and filter replacement', 250000, CURRENT_DATE - INTERVAL '30 days', CURRENT_DATE + INTERVAL '60 days', 'Toyota Service Center'),
            (asset_bus, demo_user_id, 'repair', 'Engine overhaul', 1800000, CURRENT_DATE - INTERVAL '90 days', NULL, 'Kariakoo Garage'),
            (asset_apt, demo_user_id, 'routine', 'Plumbing and electrical check', 150000, CURRENT_DATE - INTERVAL '45 days', CURRENT_DATE + INTERVAL '90 days', 'Handyman Services'),
            (asset_equip, demo_user_id, 'inspection', 'Annual hardware inspection', 80000, CURRENT_DATE - INTERVAL '60 days', CURRENT_DATE + INTERVAL '300 days', 'IT Support')
        ON CONFLICT (id) DO NOTHING;

        -- Valuation History
        INSERT INTO public.asset_valuations (asset_id, user_id, previous_value, new_value, valuation_date, valuation_method, notes)
        VALUES
            (asset_land, demo_user_id, 85000000, 110000000, CURRENT_DATE - INTERVAL '365 days', 'market_appraisal', 'Annual land valuation'),
            (asset_land, demo_user_id, 110000000, 142000000, CURRENT_DATE - INTERVAL '180 days', 'market_appraisal', 'Mid-year revaluation'),
            (asset_apt, demo_user_id, 180000000, 210000000, CURRENT_DATE - INTERVAL '365 days', 'market_appraisal', 'Annual property valuation'),
            (asset_apt, demo_user_id, 210000000, 245000000, CURRENT_DATE - INTERVAL '90 days', 'market_appraisal', 'Q3 revaluation'),
            (asset_bus, demo_user_id, 65000000, 55000000, CURRENT_DATE - INTERVAL '365 days', 'depreciation', 'Annual depreciation'),
            (asset_bus, demo_user_id, 55000000, 48000000, CURRENT_DATE - INTERVAL '180 days', 'depreciation', 'Mid-year depreciation')
        ON CONFLICT (id) DO NOTHING;

    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Asset mock data failed: %', SQLERRM;
END $$;
