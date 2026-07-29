-- ============================================================
-- CAPITAL NEXUS AI — Business Intelligence Operating System
-- Migration: 20260725240000_business_intelligence_engine.sql
-- ============================================================

-- ─── ENUMS ───────────────────────────────────────────────────
DROP TYPE IF EXISTS public.business_status CASCADE;
CREATE TYPE public.business_status AS ENUM ('startup','growing','mature','expanding','closed');

DROP TYPE IF EXISTS public.business_industry CASCADE;
CREATE TYPE public.business_industry AS ENUM (
  'transport','agriculture','healthcare','retail','manufacturing',
  'technology','real_estate','hospitality','education','services','other'
);

DROP TYPE IF EXISTS public.business_transaction_type CASCADE;
CREATE TYPE public.business_transaction_type AS ENUM (
  'revenue','expense','transfer','investment','loan_payment'
);

DROP TYPE IF EXISTS public.employee_status CASCADE;
CREATE TYPE public.employee_status AS ENUM ('active','on_leave','terminated');

-- ─── BUSINESSES ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.businesses (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id          UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  name              TEXT NOT NULL,
  industry          public.business_industry NOT NULL DEFAULT 'services',
  business_type     TEXT NOT NULL DEFAULT 'sole_proprietorship',
  registration_no   TEXT,
  description       TEXT,
  status            public.business_status NOT NULL DEFAULT 'startup',
  date_established  DATE,
  country           TEXT DEFAULT 'Tanzania',
  region            TEXT,
  address           TEXT,
  phone             TEXT,
  email             TEXT,
  website           TEXT,
  logo_url          TEXT,
  is_active         BOOLEAN DEFAULT TRUE,
  created_at        TIMESTAMPTZ DEFAULT now(),
  updated_at        TIMESTAMPTZ DEFAULT now()
);

-- ─── BRANCHES ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.business_branches (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  location    TEXT,
  region      TEXT,
  manager     TEXT,
  phone       TEXT,
  is_active   BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- ─── DEPARTMENTS ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.business_departments (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  branch_id   UUID REFERENCES public.business_branches(id) ON DELETE SET NULL,
  name        TEXT NOT NULL,
  description TEXT,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- ─── EMPLOYEES ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.business_employees (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id     UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  branch_id       UUID REFERENCES public.business_branches(id) ON DELETE SET NULL,
  department_id   UUID REFERENCES public.business_departments(id) ON DELETE SET NULL,
  employee_code   TEXT,
  full_name       TEXT NOT NULL,
  position        TEXT NOT NULL,
  email           TEXT,
  phone           TEXT,
  salary          NUMERIC(15,2) DEFAULT 0,
  salary_currency TEXT DEFAULT 'TZS',
  employment_date DATE,
  emp_status      public.employee_status DEFAULT 'active',
  notes           TEXT,
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

-- ─── BUSINESS TRANSACTIONS ───────────────────────────────────
CREATE TABLE IF NOT EXISTS public.business_transactions (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id      UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  branch_id        UUID REFERENCES public.business_branches(id) ON DELETE SET NULL,
  transaction_type public.business_transaction_type NOT NULL,
  category         TEXT NOT NULL,
  sub_category     TEXT,
  amount           NUMERIC(15,2) NOT NULL,
  currency         TEXT DEFAULT 'TZS',
  description      TEXT,
  reference        TEXT,
  customer_client  TEXT,
  transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at       TIMESTAMPTZ DEFAULT now()
);

-- ─── INVENTORY ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.business_inventory (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id   UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  branch_id     UUID REFERENCES public.business_branches(id) ON DELETE SET NULL,
  product_name  TEXT NOT NULL,
  sku           TEXT,
  category      TEXT,
  unit          TEXT DEFAULT 'pcs',
  quantity      NUMERIC(15,2) DEFAULT 0,
  reorder_level NUMERIC(15,2) DEFAULT 0,
  unit_cost     NUMERIC(15,2) DEFAULT 0,
  unit_price    NUMERIC(15,2) DEFAULT 0,
  is_active     BOOLEAN DEFAULT TRUE,
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now()
);

-- ─── BUSINESS KPIs ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.business_kpis (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  metric      TEXT NOT NULL,
  value       NUMERIC(20,4) DEFAULT 0,
  period      TEXT,
  kpi_date    DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- ─── BUSINESS SIMULATIONS ────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.business_simulations (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id     UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  simulation_type TEXT NOT NULL,
  parameters      JSONB DEFAULT '{}',
  results         JSONB DEFAULT '{}',
  notes           TEXT,
  created_at      TIMESTAMPTZ DEFAULT now()
);

-- ─── INDEXES ─────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_businesses_owner_id ON public.businesses(owner_id);
CREATE INDEX IF NOT EXISTS idx_businesses_status ON public.businesses(status);
CREATE INDEX IF NOT EXISTS idx_business_branches_business_id ON public.business_branches(business_id);
CREATE INDEX IF NOT EXISTS idx_business_departments_business_id ON public.business_departments(business_id);
CREATE INDEX IF NOT EXISTS idx_business_employees_business_id ON public.business_employees(business_id);
CREATE INDEX IF NOT EXISTS idx_business_transactions_business_id ON public.business_transactions(business_id);
CREATE INDEX IF NOT EXISTS idx_business_transactions_date ON public.business_transactions(transaction_date);
CREATE INDEX IF NOT EXISTS idx_business_transactions_type ON public.business_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_business_inventory_business_id ON public.business_inventory(business_id);
CREATE INDEX IF NOT EXISTS idx_business_kpis_business_id ON public.business_kpis(business_id);

-- ─── UPDATED_AT TRIGGER ──────────────────────────────────────
CREATE OR REPLACE FUNCTION public.update_business_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_businesses_updated_at ON public.businesses;
CREATE TRIGGER trg_businesses_updated_at
  BEFORE UPDATE ON public.businesses
  FOR EACH ROW EXECUTE FUNCTION public.update_business_updated_at();

DROP TRIGGER IF EXISTS trg_business_employees_updated_at ON public.business_employees;
CREATE TRIGGER trg_business_employees_updated_at
  BEFORE UPDATE ON public.business_employees
  FOR EACH ROW EXECUTE FUNCTION public.update_business_updated_at();

DROP TRIGGER IF EXISTS trg_business_inventory_updated_at ON public.business_inventory;
CREATE TRIGGER trg_business_inventory_updated_at
  BEFORE UPDATE ON public.business_inventory
  FOR EACH ROW EXECUTE FUNCTION public.update_business_updated_at();

-- ─── NET WORTH SYNC TRIGGER ──────────────────────────────────
-- When business transactions change, recalculate net worth snapshot
CREATE OR REPLACE FUNCTION public.sync_net_worth_on_business_transaction()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_owner_id UUID;
  v_total_assets NUMERIC := 0;
  v_total_liabilities NUMERIC := 0;
  v_net_worth NUMERIC := 0;
BEGIN
  SELECT owner_id INTO v_owner_id FROM public.businesses WHERE id = NEW.business_id;
  IF v_owner_id IS NULL THEN RETURN NEW; END IF;

  SELECT COALESCE(SUM(current_value),0) INTO v_total_assets
  FROM public.assets WHERE owner_id = v_owner_id;

  SELECT COALESCE(SUM(balance),0) INTO v_total_assets
  FROM public.financial_accounts WHERE user_id = v_owner_id AND is_active = TRUE;

  SELECT COALESCE(SUM(remaining_balance),0) INTO v_total_liabilities
  FROM public.loans WHERE borrower_id = v_owner_id AND loan_status != 'paid_off';

  v_net_worth := v_total_assets - v_total_liabilities;

  INSERT INTO public.net_worth_snapshots (user_id, total_assets, total_liabilities, net_worth, snapshot_date)
  VALUES (v_owner_id, v_total_assets, v_total_liabilities, v_net_worth, CURRENT_DATE)
  ON CONFLICT (user_id, snapshot_date) DO UPDATE
    SET total_assets = EXCLUDED.total_assets,
        total_liabilities = EXCLUDED.total_liabilities,
        net_worth = EXCLUDED.net_worth;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_net_worth_business ON public.business_transactions;
CREATE TRIGGER trg_sync_net_worth_business
  AFTER INSERT OR UPDATE OR DELETE ON public.business_transactions
  FOR EACH ROW EXECUTE FUNCTION public.sync_net_worth_on_business_transaction();

-- ─── RLS ─────────────────────────────────────────────────────
ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_kpis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_simulations ENABLE ROW LEVEL SECURITY;

-- Businesses
DROP POLICY IF EXISTS "users_manage_own_businesses" ON public.businesses;
CREATE POLICY "users_manage_own_businesses" ON public.businesses
  FOR ALL TO authenticated USING (owner_id = auth.uid()) WITH CHECK (owner_id = auth.uid());

-- Branches (via business ownership)
DROP POLICY IF EXISTS "users_manage_own_business_branches" ON public.business_branches;
CREATE POLICY "users_manage_own_business_branches" ON public.business_branches
  FOR ALL TO authenticated
  USING (business_id IN (SELECT id FROM public.businesses WHERE owner_id = auth.uid()))
  WITH CHECK (business_id IN (SELECT id FROM public.businesses WHERE owner_id = auth.uid()));

-- Departments
DROP POLICY IF EXISTS "users_manage_own_business_departments" ON public.business_departments;
CREATE POLICY "users_manage_own_business_departments" ON public.business_departments
  FOR ALL TO authenticated
  USING (business_id IN (SELECT id FROM public.businesses WHERE owner_id = auth.uid()))
  WITH CHECK (business_id IN (SELECT id FROM public.businesses WHERE owner_id = auth.uid()));

-- Employees
DROP POLICY IF EXISTS "users_manage_own_business_employees" ON public.business_employees;
CREATE POLICY "users_manage_own_business_employees" ON public.business_employees
  FOR ALL TO authenticated
  USING (business_id IN (SELECT id FROM public.businesses WHERE owner_id = auth.uid()))
  WITH CHECK (business_id IN (SELECT id FROM public.businesses WHERE owner_id = auth.uid()));

-- Transactions
DROP POLICY IF EXISTS "users_manage_own_business_transactions" ON public.business_transactions;
CREATE POLICY "users_manage_own_business_transactions" ON public.business_transactions
  FOR ALL TO authenticated
  USING (business_id IN (SELECT id FROM public.businesses WHERE owner_id = auth.uid()))
  WITH CHECK (business_id IN (SELECT id FROM public.businesses WHERE owner_id = auth.uid()));

-- Inventory
DROP POLICY IF EXISTS "users_manage_own_business_inventory" ON public.business_inventory;
CREATE POLICY "users_manage_own_business_inventory" ON public.business_inventory
  FOR ALL TO authenticated
  USING (business_id IN (SELECT id FROM public.businesses WHERE owner_id = auth.uid()))
  WITH CHECK (business_id IN (SELECT id FROM public.businesses WHERE owner_id = auth.uid()));

-- KPIs
DROP POLICY IF EXISTS "users_manage_own_business_kpis" ON public.business_kpis;
CREATE POLICY "users_manage_own_business_kpis" ON public.business_kpis
  FOR ALL TO authenticated
  USING (business_id IN (SELECT id FROM public.businesses WHERE owner_id = auth.uid()))
  WITH CHECK (business_id IN (SELECT id FROM public.businesses WHERE owner_id = auth.uid()));

-- Simulations
DROP POLICY IF EXISTS "users_manage_own_business_simulations" ON public.business_simulations;
CREATE POLICY "users_manage_own_business_simulations" ON public.business_simulations
  FOR ALL TO authenticated
  USING (business_id IN (SELECT id FROM public.businesses WHERE owner_id = auth.uid()))
  WITH CHECK (business_id IN (SELECT id FROM public.businesses WHERE owner_id = auth.uid()));

-- ─── DEMO DATA ───────────────────────────────────────────────
DO $$
DECLARE
  v_user_id       UUID;
  v_biz1_id       UUID := gen_random_uuid();
  v_biz2_id       UUID := gen_random_uuid();
  v_biz3_id       UUID := gen_random_uuid();
  v_branch1_id    UUID := gen_random_uuid();
  v_branch2_id    UUID := gen_random_uuid();
  v_branch3_id    UUID := gen_random_uuid();
  v_dept1_id      UUID := gen_random_uuid();
  v_dept2_id      UUID := gen_random_uuid();
  v_dept3_id      UUID := gen_random_uuid();
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='user_profiles') THEN
    RAISE NOTICE 'user_profiles table not found, skipping demo data';
    RETURN;
  END IF;

  SELECT id INTO v_user_id FROM public.user_profiles LIMIT 1;
  IF v_user_id IS NULL THEN
    RAISE NOTICE 'No users found, skipping demo data';
    RETURN;
  END IF;

  -- Businesses
  INSERT INTO public.businesses (id, owner_id, name, industry, business_type, status, date_established, region, description)
  VALUES
    (v_biz1_id, v_user_id, 'Nexus Transport Ltd', 'transport', 'limited_company', 'growing', '2019-03-15', 'Dar es Salaam', 'Passenger and cargo transport across Tanzania'),
    (v_biz2_id, v_user_id, 'Capital Real Estate', 'real_estate', 'partnership', 'mature', '2017-06-01', 'Mwanza', 'Property development and rental management'),
    (v_biz3_id, v_user_id, 'Green Harvest Farms', 'agriculture', 'sole_proprietorship', 'growing', '2021-01-10', 'Arusha', 'Maize, rice and vegetable farming')
  ON CONFLICT (id) DO NOTHING;

  -- Branches for Transport
  INSERT INTO public.business_branches (id, business_id, name, location, region, manager)
  VALUES
    (v_branch1_id, v_biz1_id, 'Mwanza Branch', 'Mwanza City Centre', 'Mwanza', 'Amina Juma'),
    (v_branch2_id, v_biz1_id, 'Dar es Salaam HQ', 'Kariakoo, Dar es Salaam', 'Dar es Salaam', 'Jonathan Mwangi'),
    (v_branch3_id, v_biz1_id, 'Arusha Branch', 'Arusha Town', 'Arusha', 'Peter Kimani')
  ON CONFLICT (id) DO NOTHING;

  -- Departments
  INSERT INTO public.business_departments (id, business_id, branch_id, name)
  VALUES
    (v_dept1_id, v_biz1_id, v_branch2_id, 'Operations'),
    (v_dept2_id, v_biz1_id, v_branch2_id, 'Finance'),
    (v_dept3_id, v_biz1_id, v_branch2_id, 'Maintenance')
  ON CONFLICT (id) DO NOTHING;

  -- Employees
  INSERT INTO public.business_employees (business_id, branch_id, department_id, employee_code, full_name, position, salary, employment_date, emp_status)
  VALUES
    (v_biz1_id, v_branch2_id, v_dept1_id, 'EMP001', 'Jonathan Mwangi', 'General Manager', 2500000, '2019-03-15', 'active'),
    (v_biz1_id, v_branch1_id, v_dept1_id, 'EMP002', 'Amina Juma', 'Branch Manager', 1800000, '2020-01-10', 'active'),
    (v_biz1_id, v_branch2_id, v_dept3_id, 'EMP003', 'Hassan Salim', 'Head Mechanic', 1200000, '2019-06-01', 'active'),
    (v_biz1_id, v_branch3_id, v_dept1_id, 'EMP004', 'Peter Kimani', 'Branch Manager', 1600000, '2021-03-01', 'active'),
    (v_biz1_id, v_branch2_id, v_dept2_id, 'EMP005', 'Grace Mushi', 'Accountant', 1400000, '2020-09-15', 'active'),
    (v_biz2_id, NULL, NULL, 'EMP006', 'David Osei', 'Property Manager', 2000000, '2018-01-01', 'active'),
    (v_biz3_id, NULL, NULL, 'EMP007', 'Mary Ndege', 'Farm Supervisor', 900000, '2021-02-01', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- Business Transactions — last 6 months
  INSERT INTO public.business_transactions (business_id, branch_id, transaction_type, category, amount, description, transaction_date)
  VALUES
    -- Transport revenues
    (v_biz1_id, v_branch1_id, 'revenue', 'Passenger Fares', 18500000, 'Monthly passenger revenue Mwanza', CURRENT_DATE - INTERVAL '5 days'),
    (v_biz1_id, v_branch2_id, 'revenue', 'Cargo Transport', 12000000, 'Cargo delivery contracts', CURRENT_DATE - INTERVAL '8 days'),
    (v_biz1_id, v_branch3_id, 'revenue', 'Passenger Fares', 9800000, 'Arusha route revenue', CURRENT_DATE - INTERVAL '10 days'),
    (v_biz1_id, v_branch2_id, 'revenue', 'Charter Services', 5500000, 'Private charter bookings', CURRENT_DATE - INTERVAL '15 days'),
    -- Transport expenses
    (v_biz1_id, v_branch2_id, 'expense', 'Fuel', 8200000, 'Monthly fuel costs all branches', CURRENT_DATE - INTERVAL '3 days'),
    (v_biz1_id, v_branch2_id, 'expense', 'Salaries', 9400000, 'Monthly payroll', CURRENT_DATE - INTERVAL '1 day'),
    (v_biz1_id, v_branch3_id, 'expense', 'Maintenance', 2100000, 'Vehicle servicing and repairs', CURRENT_DATE - INTERVAL '12 days'),
    (v_biz1_id, v_branch2_id, 'expense', 'Insurance', 1500000, 'Fleet insurance premium', CURRENT_DATE - INTERVAL '20 days'),
    (v_biz1_id, v_branch2_id, 'expense', 'Rent', 800000, 'Office and depot rent', CURRENT_DATE - INTERVAL '2 days'),
    -- Real estate revenues
    (v_biz2_id, NULL, 'revenue', 'Rental Income', 22000000, 'Monthly rental collection', CURRENT_DATE - INTERVAL '4 days'),
    (v_biz2_id, NULL, 'revenue', 'Property Sale', 85000000, 'Sale of plot in Mwanza', CURRENT_DATE - INTERVAL '30 days'),
    -- Real estate expenses
    (v_biz2_id, NULL, 'expense', 'Maintenance', 3200000, 'Property maintenance and repairs', CURRENT_DATE - INTERVAL '7 days'),
    (v_biz2_id, NULL, 'expense', 'Salaries', 2000000, 'Staff salaries', CURRENT_DATE - INTERVAL '1 day'),
    (v_biz2_id, NULL, 'expense', 'Property Tax', 1800000, 'Annual property tax installment', CURRENT_DATE - INTERVAL '25 days'),
    -- Agriculture revenues
    (v_biz3_id, NULL, 'revenue', 'Crop Sales', 14500000, 'Maize and rice harvest sales', CURRENT_DATE - INTERVAL '20 days'),
    (v_biz3_id, NULL, 'revenue', 'Vegetable Sales', 3200000, 'Weekly vegetable market sales', CURRENT_DATE - INTERVAL '6 days'),
    -- Agriculture expenses
    (v_biz3_id, NULL, 'expense', 'Seeds & Fertilizer', 4500000, 'Planting season inputs', CURRENT_DATE - INTERVAL '45 days'),
    (v_biz3_id, NULL, 'expense', 'Labour', 2800000, 'Seasonal farm workers', CURRENT_DATE - INTERVAL '15 days'),
    (v_biz3_id, NULL, 'expense', 'Equipment Fuel', 900000, 'Tractor and pump fuel', CURRENT_DATE - INTERVAL '10 days'),
    -- Previous months
    (v_biz1_id, v_branch1_id, 'revenue', 'Passenger Fares', 17200000, 'Previous month Mwanza', CURRENT_DATE - INTERVAL '35 days'),
    (v_biz1_id, v_branch2_id, 'expense', 'Fuel', 7800000, 'Previous month fuel', CURRENT_DATE - INTERVAL '33 days'),
    (v_biz2_id, NULL, 'revenue', 'Rental Income', 22000000, 'Previous month rentals', CURRENT_DATE - INTERVAL '34 days'),
    (v_biz3_id, NULL, 'revenue', 'Crop Sales', 11000000, 'Previous season sales', CURRENT_DATE - INTERVAL '60 days')
  ON CONFLICT (id) DO NOTHING;

  -- Inventory for Transport
  INSERT INTO public.business_inventory (business_id, branch_id, product_name, category, unit, quantity, reorder_level, unit_cost)
  VALUES
    (v_biz1_id, v_branch2_id, 'Engine Oil (20L)', 'Lubricants', 'drums', 45, 10, 85000),
    (v_biz1_id, v_branch2_id, 'Brake Pads (Set)', 'Spare Parts', 'sets', 28, 5, 120000),
    (v_biz1_id, v_branch2_id, 'Tyres (Bus)', 'Spare Parts', 'pcs', 12, 8, 450000),
    (v_biz3_id, NULL, 'Maize Seeds (50kg)', 'Seeds', 'bags', 200, 50, 35000),
    (v_biz3_id, NULL, 'NPK Fertilizer (50kg)', 'Fertilizer', 'bags', 150, 30, 55000)
  ON CONFLICT (id) DO NOTHING;

  -- KPIs
  INSERT INTO public.business_kpis (business_id, metric, value, period, kpi_date)
  VALUES
    (v_biz1_id, 'monthly_revenue', 45800000, 'current_month', CURRENT_DATE),
    (v_biz1_id, 'monthly_expenses', 22000000, 'current_month', CURRENT_DATE),
    (v_biz1_id, 'net_profit', 23800000, 'current_month', CURRENT_DATE),
    (v_biz1_id, 'health_score', 78, 'current_month', CURRENT_DATE),
    (v_biz2_id, 'monthly_revenue', 107000000, 'current_month', CURRENT_DATE),
    (v_biz2_id, 'monthly_expenses', 7000000, 'current_month', CURRENT_DATE),
    (v_biz2_id, 'net_profit', 100000000, 'current_month', CURRENT_DATE),
    (v_biz2_id, 'health_score', 92, 'current_month', CURRENT_DATE),
    (v_biz3_id, 'monthly_revenue', 17700000, 'current_month', CURRENT_DATE),
    (v_biz3_id, 'monthly_expenses', 8200000, 'current_month', CURRENT_DATE),
    (v_biz3_id, 'net_profit', 9500000, 'current_month', CURRENT_DATE),
    (v_biz3_id, 'health_score', 65, 'current_month', CURRENT_DATE)
  ON CONFLICT (id) DO NOTHING;

EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Business demo data error: %', SQLERRM;
END $$;
