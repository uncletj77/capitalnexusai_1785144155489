-- ============================================================
-- UNIVERSAL REGISTRATION WIZARD (URW) & TRANSACTION INTELLIGENCE ENGINE (TIE)
-- Migration: 20260727200000_universal_registration_wizard.sql
-- ============================================================

-- ─── REGISTRATION DRAFTS ─────────────────────────────────────────────────────
-- Stores in-progress registrations so users can resume after interruption
CREATE TABLE IF NOT EXISTS public.registration_drafts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  draft_key TEXT NOT NULL,                    -- unique key per user+registration type
  registration_category TEXT NOT NULL,        -- 'transaction', 'business', 'investment', 'asset', 'loan', 'organization'
  registration_type TEXT NOT NULL,            -- e.g. 'income', 'expense', 'loan_receivable', etc.
  current_step INTEGER NOT NULL DEFAULT 0,
  form_data JSONB NOT NULL DEFAULT '{}',      -- all entered field values
  selected_relationships JSONB DEFAULT '{}',  -- linked entities (business_id, account_id, etc.)
  validation_state JSONB DEFAULT '{}',        -- which fields passed/failed
  is_complete BOOLEAN NOT NULL DEFAULT FALSE,
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days'),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, draft_key)
);

-- ─── REGISTRATION AUDIT LOG ──────────────────────────────────────────────────
-- Immutable audit trail for every financial registration event
CREATE TABLE IF NOT EXISTS public.registration_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  registration_id UUID,                       -- ID of the created record (transaction, asset, etc.)
  registration_category TEXT NOT NULL,
  registration_type TEXT NOT NULL,
  action TEXT NOT NULL,                       -- 'initiated', 'draft_saved', 'validated', 'committed', 'rolled_back', 'failed'
  entity_table TEXT,                          -- which table the record was written to
  entity_id UUID,                             -- the created/updated record ID
  snapshot JSONB DEFAULT '{}',                -- full data snapshot at time of action
  related_modules TEXT[] DEFAULT '{}',        -- modules that were synced
  error_message TEXT,
  ip_address TEXT,
  device_info TEXT,
  duration_ms INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── REGISTRATION SYNC LOG ───────────────────────────────────────────────────
-- Tracks which modules were updated after each registration commit
CREATE TABLE IF NOT EXISTS public.registration_sync_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  registration_audit_id UUID REFERENCES public.registration_audit_log(id) ON DELETE CASCADE,
  entity_id UUID NOT NULL,
  entity_table TEXT NOT NULL,
  synced_modules JSONB DEFAULT '[]',          -- array of {module, status, synced_at}
  sync_status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'partial', 'complete', 'failed'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── INDEXES ─────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_reg_drafts_user ON public.registration_drafts(user_id);
CREATE INDEX IF NOT EXISTS idx_reg_drafts_user_key ON public.registration_drafts(user_id, draft_key);
CREATE INDEX IF NOT EXISTS idx_reg_drafts_incomplete ON public.registration_drafts(user_id, is_complete) WHERE is_complete = FALSE;
CREATE INDEX IF NOT EXISTS idx_reg_audit_user ON public.registration_audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_reg_audit_entity ON public.registration_audit_log(entity_id);
CREATE INDEX IF NOT EXISTS idx_reg_audit_created ON public.registration_audit_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reg_sync_user ON public.registration_sync_log(user_id);
CREATE INDEX IF NOT EXISTS idx_reg_sync_entity ON public.registration_sync_log(entity_id);

-- ─── RLS POLICIES ────────────────────────────────────────────────────────────
ALTER TABLE public.registration_drafts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.registration_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.registration_sync_log ENABLE ROW LEVEL SECURITY;

-- Drafts: users own their drafts
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'registration_drafts' AND policyname = 'drafts_owner_all'
  ) THEN
    CREATE POLICY drafts_owner_all ON public.registration_drafts
      FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- Audit log: users can read their own audit log (insert via service role)
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'registration_audit_log' AND policyname = 'audit_owner_select'
  ) THEN
    CREATE POLICY audit_owner_select ON public.registration_audit_log
      FOR SELECT USING (auth.uid() = user_id);
    CREATE POLICY audit_owner_insert ON public.registration_audit_log
      FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- Sync log: users can read their own sync log
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'registration_sync_log' AND policyname = 'sync_owner_all'
  ) THEN
    CREATE POLICY sync_owner_all ON public.registration_sync_log
      FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- ─── HELPER: Clean expired drafts ────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.cleanup_expired_drafts()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM public.registration_drafts
  WHERE expires_at < NOW() AND is_complete = FALSE;
END;
$$;
