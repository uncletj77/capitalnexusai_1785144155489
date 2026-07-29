-- CNA Prompt 3/5: Clear demo/fake data and fix RLS policies
-- Clears all demo transactions from financial_transactions, business_transactions, assets (demo rows)
-- Keeps all loans intact as per user instruction
-- Fixes RLS policies for assets, businesses, investments

-- ─── 1. CLEAR DEMO FINANCIAL TRANSACTIONS ────────────────────────────────────
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'financial_transactions') THEN
    DELETE FROM public.financial_transactions WHERE true;
  END IF;
END $$;

-- ─── 2. CLEAR DEMO BUSINESS TRANSACTIONS ─────────────────────────────────────
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'business_transactions') THEN
    DELETE FROM public.business_transactions WHERE true;
  END IF;
END $$;

-- ─── 3. CLEAR DEMO ASSETS ────────────────────────────────────────────────────
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'assets') THEN
    DELETE FROM public.assets WHERE true;
  END IF;
END $$;

-- ─── 4. CLEAR DEMO BUSINESSES ────────────────────────────────────────────────
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'businesses') THEN
    DELETE FROM public.businesses WHERE true;
  END IF;
END $$;

-- ─── 5. CLEAR DEMO INVESTMENTS ───────────────────────────────────────────────
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'investment_transactions') THEN
    DELETE FROM public.investment_transactions WHERE true;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'investments') THEN
    DELETE FROM public.investments WHERE true;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'investment_portfolios') THEN
    DELETE FROM public.investment_portfolios WHERE true;
  END IF;
END $$;

-- ─── 6. CLEAR DEMO BUSINESS INVENTORY / KPIs ─────────────────────────────────
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'business_inventory') THEN
    DELETE FROM public.business_inventory WHERE true;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'business_kpis') THEN
    DELETE FROM public.business_kpis WHERE true;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'business_employees') THEN
    DELETE FROM public.business_employees WHERE true;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'business_branches') THEN
    DELETE FROM public.business_branches WHERE true;
  END IF;
END $$;

-- ─── 7. FIX RLS POLICIES FOR ASSETS ─────────────────────────────────────────
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'assets') THEN
    DROP POLICY IF EXISTS "users_manage_own_assets" ON public.assets;
    CREATE POLICY "users_manage_own_assets"
    ON public.assets
    FOR ALL
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

-- ─── 8. FIX RLS POLICIES FOR BUSINESSES ──────────────────────────────────────
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'businesses') THEN
    DROP POLICY IF EXISTS "users_manage_own_businesses" ON public.businesses;
    CREATE POLICY "users_manage_own_businesses"
    ON public.businesses
    FOR ALL
    TO authenticated
    USING (owner_id = auth.uid())
    WITH CHECK (owner_id = auth.uid());
  END IF;
END $$;

-- ─── 9. FIX RLS POLICIES FOR BUSINESS_TRANSACTIONS ───────────────────────────
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'business_transactions') THEN
    DROP POLICY IF EXISTS "users_manage_own_business_transactions" ON public.business_transactions;
    CREATE POLICY "users_manage_own_business_transactions"
    ON public.business_transactions
    FOR ALL
    TO authenticated
    USING (
      business_id IN (
        SELECT id FROM public.businesses WHERE owner_id = auth.uid()
      )
    )
    WITH CHECK (
      business_id IN (
        SELECT id FROM public.businesses WHERE owner_id = auth.uid()
      )
    );
  END IF;
END $$;

-- ─── 10. FIX RLS POLICIES FOR INVESTMENTS ────────────────────────────────────
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'investments') THEN
    DROP POLICY IF EXISTS "users_manage_own_investments" ON public.investments;
    CREATE POLICY "users_manage_own_investments"
    ON public.investments
    FOR ALL
    TO authenticated
    USING (owner_id = auth.uid())
    WITH CHECK (owner_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'investment_portfolios') THEN
    DROP POLICY IF EXISTS "users_manage_own_investment_portfolios" ON public.investment_portfolios;
    CREATE POLICY "users_manage_own_investment_portfolios"
    ON public.investment_portfolios
    FOR ALL
    TO authenticated
    USING (owner_id = auth.uid())
    WITH CHECK (owner_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'investment_transactions') THEN
    DROP POLICY IF EXISTS "users_manage_own_investment_transactions" ON public.investment_transactions;
    CREATE POLICY "users_manage_own_investment_transactions"
    ON public.investment_transactions
    FOR ALL
    TO authenticated
    USING (owner_id = auth.uid())
    WITH CHECK (owner_id = auth.uid());
  END IF;
END $$;

-- ─── 11. FIX RLS FOR BUSINESS BRANCHES / EMPLOYEES / KPIS ───────────────────
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'business_branches') THEN
    DROP POLICY IF EXISTS "users_manage_own_business_branches" ON public.business_branches;
    CREATE POLICY "users_manage_own_business_branches"
    ON public.business_branches
    FOR ALL
    TO authenticated
    USING (
      business_id IN (
        SELECT id FROM public.businesses WHERE owner_id = auth.uid()
      )
    )
    WITH CHECK (
      business_id IN (
        SELECT id FROM public.businesses WHERE owner_id = auth.uid()
      )
    );
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'business_employees') THEN
    DROP POLICY IF EXISTS "users_manage_own_business_employees" ON public.business_employees;
    CREATE POLICY "users_manage_own_business_employees"
    ON public.business_employees
    FOR ALL
    TO authenticated
    USING (
      business_id IN (
        SELECT id FROM public.businesses WHERE owner_id = auth.uid()
      )
    )
    WITH CHECK (
      business_id IN (
        SELECT id FROM public.businesses WHERE owner_id = auth.uid()
      )
    );
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'business_kpis') THEN
    DROP POLICY IF EXISTS "users_manage_own_business_kpis" ON public.business_kpis;
    CREATE POLICY "users_manage_own_business_kpis"
    ON public.business_kpis
    FOR ALL
    TO authenticated
    USING (
      business_id IN (
        SELECT id FROM public.businesses WHERE owner_id = auth.uid()
      )
    )
    WITH CHECK (
      business_id IN (
        SELECT id FROM public.businesses WHERE owner_id = auth.uid()
      )
    );
  END IF;
END $$;

-- ─── 12. FIX RLS FOR FINANCIAL_ACCOUNTS ──────────────────────────────────────
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'financial_accounts') THEN
    DROP POLICY IF EXISTS "users_manage_own_financial_accounts" ON public.financial_accounts;
    CREATE POLICY "users_manage_own_financial_accounts"
    ON public.financial_accounts
    FOR ALL
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

-- ─── 13. FIX RLS FOR FINANCIAL_TRANSACTIONS ──────────────────────────────────
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'financial_transactions') THEN
    DROP POLICY IF EXISTS "users_manage_own_financial_transactions" ON public.financial_transactions;
    CREATE POLICY "users_manage_own_financial_transactions"
    ON public.financial_transactions
    FOR ALL
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());
  END IF;
END $$;
