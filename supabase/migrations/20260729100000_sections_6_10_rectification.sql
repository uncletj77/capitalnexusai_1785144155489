-- SECTIONS 6-10 RECTIFICATION MIGRATION
-- Fixes schema issues for Transaction Engine, Asset Intelligence, Business, Investment, Accounts

-- ─── FINANCIAL TRANSACTIONS ENHANCEMENTS ────────────────────────────────────
-- Add missing columns to financial_transactions if not present
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='financial_transactions' AND column_name='title') THEN
    ALTER TABLE public.financial_transactions ADD COLUMN title TEXT;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='financial_transactions' AND column_name='source_account_id') THEN
    ALTER TABLE public.financial_transactions ADD COLUMN source_account_id UUID REFERENCES public.financial_accounts(id) ON DELETE SET NULL;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='financial_transactions' AND column_name='destination_account_id') THEN
    ALTER TABLE public.financial_transactions ADD COLUMN destination_account_id UUID REFERENCES public.financial_accounts(id) ON DELETE SET NULL;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='financial_transactions' AND column_name='tags') THEN
    ALTER TABLE public.financial_transactions ADD COLUMN tags TEXT[] DEFAULT '{}';
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='financial_transactions' AND column_name='reference_number') THEN
    ALTER TABLE public.financial_transactions ADD COLUMN reference_number TEXT;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='financial_transactions' AND column_name='linked_transfer_id') THEN
    ALTER TABLE public.financial_transactions ADD COLUMN linked_transfer_id UUID;
  END IF;
END $$;

-- ─── BUSINESSES TABLE FIXES ──────────────────────────────────────────────────
-- Ensure businesses has user_id column (some queries use user_id, table uses owner_id)
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='businesses') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='businesses' AND column_name='user_id') THEN
      ALTER TABLE public.businesses ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
      -- Sync user_id from owner_id
      UPDATE public.businesses SET user_id = owner_id WHERE user_id IS NULL;
    END IF;
  END IF;
END $$;

-- Ensure businesses has is_deleted column for soft delete
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='businesses') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='businesses' AND column_name='is_deleted') THEN
      ALTER TABLE public.businesses ADD COLUMN is_deleted BOOLEAN DEFAULT FALSE;
    END IF;
  END IF;
END $$;

-- Ensure businesses has business_value column
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='businesses') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='businesses' AND column_name='business_value') THEN
      ALTER TABLE public.businesses ADD COLUMN business_value NUMERIC(20,2) DEFAULT 0;
    END IF;
  END IF;
END $$;

-- Ensure businesses has initial_capital column
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='businesses') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='businesses' AND column_name='initial_capital') THEN
      ALTER TABLE public.businesses ADD COLUMN initial_capital NUMERIC(20,2) DEFAULT 0;
    END IF;
  END IF;
END $$;

-- ─── BUSINESS TRANSACTIONS ENHANCEMENTS ─────────────────────────────────────
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='business_transactions') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='business_transactions' AND column_name='is_archived') THEN
      ALTER TABLE public.business_transactions ADD COLUMN is_archived BOOLEAN DEFAULT FALSE;
    END IF;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='business_transactions') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='business_transactions' AND column_name='financial_transaction_id') THEN
      ALTER TABLE public.business_transactions ADD COLUMN financial_transaction_id UUID REFERENCES public.financial_transactions(id) ON DELETE SET NULL;
    END IF;
  END IF;
END $$;

-- ─── INVESTMENTS TABLE FIXES ─────────────────────────────────────────────────
-- Ensure investments has user_id column (only if table exists)
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='investments') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='investments' AND column_name='user_id') THEN
      ALTER TABLE public.investments ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
      UPDATE public.investments SET user_id = owner_id WHERE user_id IS NULL AND owner_id IS NOT NULL;
    END IF;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='investments') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='investments' AND column_name='is_deleted') THEN
      ALTER TABLE public.investments ADD COLUMN is_deleted BOOLEAN DEFAULT FALSE;
    END IF;
  END IF;
END $$;

-- ─── MASTER ASSET REGISTRY FIXES ────────────────────────────────────────────
-- Ensure master_asset_registry has all needed columns
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='master_asset_registry') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='master_asset_registry' AND column_name='linked_business_id') THEN
      ALTER TABLE public.master_asset_registry ADD COLUMN linked_business_id UUID;
    END IF;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='master_asset_registry') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='master_asset_registry' AND column_name='linked_investment_id') THEN
      ALTER TABLE public.master_asset_registry ADD COLUMN linked_investment_id UUID;
    END IF;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='master_asset_registry') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='master_asset_registry' AND column_name='is_auto_registered') THEN
      ALTER TABLE public.master_asset_registry ADD COLUMN is_auto_registered BOOLEAN DEFAULT FALSE;
    END IF;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='master_asset_registry') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='master_asset_registry' AND column_name='last_valuation_date') THEN
      ALTER TABLE public.master_asset_registry ADD COLUMN last_valuation_date DATE;
    END IF;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='master_asset_registry') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='master_asset_registry' AND column_name='asset_id') THEN
      ALTER TABLE public.master_asset_registry ADD COLUMN asset_id UUID;
    END IF;
  END IF;
END $$;

-- ─── FINANCIAL ACCOUNTS FIXES ────────────────────────────────────────────────
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='financial_accounts') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='financial_accounts' AND column_name='is_deleted') THEN
      ALTER TABLE public.financial_accounts ADD COLUMN is_deleted BOOLEAN DEFAULT FALSE;
    END IF;
  END IF;
END $$;

-- ─── RLS POLICIES FOR BUSINESSES (user_id) ──────────────────────────────────
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='businesses') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_policies WHERE tablename = 'businesses' AND policyname = 'businesses_user_id_select'
    ) THEN
      CREATE POLICY businesses_user_id_select ON public.businesses
        FOR SELECT USING (auth.uid() = owner_id OR auth.uid() = user_id);
    END IF;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='businesses') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_policies WHERE tablename = 'businesses' AND policyname = 'businesses_user_id_update'
    ) THEN
      CREATE POLICY businesses_user_id_update ON public.businesses
        FOR UPDATE USING (auth.uid() = owner_id OR auth.uid() = user_id);
    END IF;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='businesses') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_policies WHERE tablename = 'businesses' AND policyname = 'businesses_user_id_delete'
    ) THEN
      CREATE POLICY businesses_user_id_delete ON public.businesses
        FOR DELETE USING (auth.uid() = owner_id OR auth.uid() = user_id);
    END IF;
  END IF;
END $$;

-- ─── RLS POLICIES FOR INVESTMENTS (user_id) ──────────────────────────────────
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='investments') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_policies WHERE tablename = 'investments' AND policyname = 'investments_user_id_select'
    ) THEN
      CREATE POLICY investments_user_id_select ON public.investments
        FOR SELECT USING (auth.uid() = owner_id OR auth.uid() = user_id);
    END IF;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='investments') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_policies WHERE tablename = 'investments' AND policyname = 'investments_user_id_update'
    ) THEN
      CREATE POLICY investments_user_id_update ON public.investments
        FOR UPDATE USING (auth.uid() = owner_id OR auth.uid() = user_id);
    END IF;
  END IF;
END $$;

-- ─── TRANSACTION SYNC FUNCTION ───────────────────────────────────────────────
-- Function to sync business transaction to financial_transactions
CREATE OR REPLACE FUNCTION public.sync_business_transaction_to_ledger(
  p_business_transaction_id UUID,
  p_user_id UUID
) RETURNS UUID AS $$
DECLARE
  v_bt RECORD;
  v_ft_id UUID;
  v_tx_type TEXT;
BEGIN
  SELECT * INTO v_bt FROM public.business_transactions WHERE id = p_business_transaction_id;
  IF NOT FOUND THEN RETURN NULL; END IF;

  v_tx_type := CASE v_bt.transaction_type
    WHEN 'revenue' THEN 'business_income'
    WHEN 'expense' THEN 'business_expense'
    ELSE v_bt.transaction_type
  END;

  -- Check if already synced
  IF v_bt.financial_transaction_id IS NOT NULL THEN
    -- Update existing
    UPDATE public.financial_transactions SET
      amount = v_bt.amount,
      description = COALESCE(v_bt.description, v_bt.category),
      transaction_date = v_bt.transaction_date,
      updated_at = NOW()
    WHERE id = v_bt.financial_transaction_id;
    RETURN v_bt.financial_transaction_id;
  END IF;

  -- Insert new
  INSERT INTO public.financial_transactions (
    user_id, transaction_type, category, amount, description,
    transaction_date, related_business_id, status, is_archived, currency
  ) VALUES (
    p_user_id, v_tx_type, v_bt.category, v_bt.amount,
    COALESCE(v_bt.description, v_bt.category),
    v_bt.transaction_date,
    v_bt.business_id, 'completed', FALSE, 'TZS'
  ) RETURNING id INTO v_ft_id;

  -- Link back
  UPDATE public.business_transactions SET financial_transaction_id = v_ft_id
  WHERE id = p_business_transaction_id;

  RETURN v_ft_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
