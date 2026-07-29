-- ─────────────────────────────────────────────────────────────────────────────
-- ENTERPRISE SYNCHRONIZATION ENGINE (ESE) — MASTER PROMPT 4 SECTION C
-- Migration: 20260727210000_enterprise_sync_engine.sql
-- Creates: enterprise_audit_trail, ese_sync_log, ese_sync_events,
--          notifications enhancements, wealth_projections stale flag,
--          analytics_reports stale flag, ai_memory context_stale flag
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── ENTERPRISE AUDIT TRAIL (IMMUTABLE) ─────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.enterprise_audit_trail (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id        TEXT NOT NULL UNIQUE,
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  entity_type     TEXT NOT NULL,
  entity_id       TEXT,
  entity_table    TEXT,
  action          TEXT NOT NULL CHECK (action IN ('create','update','delete','sync','rollback')),
  before_values   JSONB DEFAULT '{}',
  after_values    JSONB DEFAULT '{}',
  modules_affected TEXT[] DEFAULT '{}',
  module_results  JSONB DEFAULT '{}',
  errors          TEXT[] DEFAULT '{}',
  sync_status     TEXT DEFAULT 'pending' CHECK (sync_status IN ('pending','completed','partial','failed')),
  duration_ms     INTEGER,
  session_id      TEXT,
  ip_address      TEXT,
  device_info     TEXT,
  reason          TEXT,
  approval_status TEXT DEFAULT 'auto' CHECK (approval_status IN ('auto','pending','approved','rejected')),
  timestamp       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at    TIMESTAMPTZ
);

-- Audit trail is append-only — no UPDATE/DELETE for users
ALTER TABLE public.enterprise_audit_trail ENABLE ROW LEVEL SECURITY;

CREATE POLICY "audit_trail_insert_own" ON public.enterprise_audit_trail
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "audit_trail_select_own" ON public.enterprise_audit_trail
  FOR SELECT USING (auth.uid() = user_id);

-- NO UPDATE or DELETE policies — immutable by design

CREATE INDEX IF NOT EXISTS idx_audit_trail_user_time
  ON public.enterprise_audit_trail(user_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_audit_trail_entity
  ON public.enterprise_audit_trail(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_trail_event_id
  ON public.enterprise_audit_trail(event_id);

-- ─── ESE SYNC LOG ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.ese_sync_log (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id        TEXT NOT NULL,
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  entity_type     TEXT NOT NULL,
  entity_id       TEXT,
  modules_count   INTEGER DEFAULT 0,
  success_count   INTEGER DEFAULT 0,
  failure_count   INTEGER DEFAULT 0,
  errors          TEXT[] DEFAULT '{}',
  duration_ms     INTEGER,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.ese_sync_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ese_sync_log_insert_own" ON public.ese_sync_log
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "ese_sync_log_select_own" ON public.ese_sync_log
  FOR SELECT USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_ese_sync_log_user
  ON public.ese_sync_log(user_id, created_at DESC);

-- ─── ESE SYNC EVENTS (REAL-TIME DASHBOARD REFRESH SIGNALS) ──────────────────

CREATE TABLE IF NOT EXISTS public.ese_sync_events (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  event_type      TEXT NOT NULL,
  entity_type     TEXT,
  entity_id       TEXT,
  processed       BOOLEAN DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.ese_sync_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ese_sync_events_all_own" ON public.ese_sync_events
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_ese_sync_events_user_unprocessed
  ON public.ese_sync_events(user_id, processed, created_at DESC);

-- ─── NOTIFICATIONS TABLE (MEANINGFUL INTELLIGENCE NOTIFICATIONS) ─────────────

CREATE TABLE IF NOT EXISTS public.notifications (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  notification_type TEXT NOT NULL DEFAULT 'general',
  priority          TEXT NOT NULL DEFAULT 'normal' CHECK (priority IN ('low','normal','high','critical')),
  title             TEXT NOT NULL,
  message           TEXT NOT NULL,
  entity_type       TEXT,
  entity_id         TEXT,
  action_route      TEXT,
  is_read           BOOLEAN DEFAULT FALSE,
  read_at           TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notifications_all_own" ON public.notifications
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_notifications_user_unread
  ON public.notifications(user_id, is_read, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_entity
  ON public.notifications(entity_type, entity_id);

-- ─── ADD STALE FLAGS TO EXISTING TABLES ──────────────────────────────────────

-- analytics_reports: mark stale after sync
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'analytics_reports' AND column_name = 'is_stale'
  ) THEN
    ALTER TABLE public.analytics_reports ADD COLUMN is_stale BOOLEAN DEFAULT FALSE;
  END IF;
END $$;

-- wealth_projections: mark stale after sync
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'wealth_projections' AND column_name = 'is_stale'
  ) THEN
    ALTER TABLE public.wealth_projections ADD COLUMN is_stale BOOLEAN DEFAULT FALSE;
  END IF;
END $$;

-- ai_memory: context_stale flag so AI refreshes on next query
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'ai_memory' AND column_name = 'context_stale'
  ) THEN
    ALTER TABLE public.ai_memory ADD COLUMN context_stale BOOLEAN DEFAULT FALSE;
  END IF;
END $$;

-- assets: source_type and source_id for auto-registration from loans/investments
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'assets' AND column_name = 'source_type'
  ) THEN
    ALTER TABLE public.assets ADD COLUMN source_type TEXT;
    ALTER TABLE public.assets ADD COLUMN source_id TEXT;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_assets_source
  ON public.assets(source_type, source_id)
  WHERE source_type IS NOT NULL;

-- ─── WEALTH PLANNING INTELLIGENCE TABLE ──────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.wealth_intelligence (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_type         TEXT NOT NULL DEFAULT 'comprehensive',
  net_worth         NUMERIC(20,2) DEFAULT 0,
  total_assets      NUMERIC(20,2) DEFAULT 0,
  total_liabilities NUMERIC(20,2) DEFAULT 0,
  monthly_income    NUMERIC(20,2) DEFAULT 0,
  monthly_expenses  NUMERIC(20,2) DEFAULT 0,
  monthly_savings   NUMERIC(20,2) DEFAULT 0,
  savings_rate      NUMERIC(5,2) DEFAULT 0,
  projected_net_worth_1y  NUMERIC(20,2) DEFAULT 0,
  projected_net_worth_5y  NUMERIC(20,2) DEFAULT 0,
  projected_net_worth_10y NUMERIC(20,2) DEFAULT 0,
  retirement_readiness    NUMERIC(5,2) DEFAULT 0,
  emergency_fund_months   NUMERIC(5,2) DEFAULT 0,
  debt_to_income_ratio    NUMERIC(5,2) DEFAULT 0,
  recommendations   JSONB DEFAULT '[]',
  risk_factors      JSONB DEFAULT '[]',
  opportunities     JSONB DEFAULT '[]',
  milestones        JSONB DEFAULT '[]',
  scenarios         JSONB DEFAULT '[]',
  data_sources      JSONB DEFAULT '{}',
  confidence_level  NUMERIC(5,2) DEFAULT 0,
  generated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_stale          BOOLEAN DEFAULT FALSE,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.wealth_intelligence ENABLE ROW LEVEL SECURITY;

CREATE POLICY "wealth_intelligence_all_own" ON public.wealth_intelligence
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_wealth_intelligence_user
  ON public.wealth_intelligence(user_id, generated_at DESC);

-- ─── GRAPH DRILL-DOWN CACHE ───────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.graph_drill_down_cache (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  graph_type      TEXT NOT NULL,
  period          TEXT NOT NULL,
  filter_params   JSONB DEFAULT '{}',
  data_points     JSONB DEFAULT '[]',
  drill_down_data JSONB DEFAULT '{}',
  generated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at      TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '1 hour')
);

ALTER TABLE public.graph_drill_down_cache ENABLE ROW LEVEL SECURITY;

CREATE POLICY "graph_cache_all_own" ON public.graph_drill_down_cache
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_graph_cache_user_type
  ON public.graph_drill_down_cache(user_id, graph_type, period);

-- ─── CLEANUP FUNCTION ────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.cleanup_ese_data()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Remove processed sync events older than 24 hours
  DELETE FROM public.ese_sync_events
  WHERE processed = TRUE AND created_at < NOW() - INTERVAL '24 hours';

  -- Remove expired graph cache
  DELETE FROM public.graph_drill_down_cache
  WHERE expires_at < NOW();
END;
$$;
