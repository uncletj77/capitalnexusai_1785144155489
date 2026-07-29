-- Migration: Executive Dashboard & Reporting Tables
-- Timestamp: 20260727230000

-- Executive Dashboard Snapshots (for historical tracking)
CREATE TABLE IF NOT EXISTS public.executive_dashboard_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  snapshot_date DATE NOT NULL DEFAULT CURRENT_DATE,
  net_worth NUMERIC(20,2) DEFAULT 0,
  total_assets NUMERIC(20,2) DEFAULT 0,
  total_liabilities NUMERIC(20,2) DEFAULT 0,
  available_cash NUMERIC(20,2) DEFAULT 0,
  monthly_income NUMERIC(20,2) DEFAULT 0,
  monthly_expenses NUMERIC(20,2) DEFAULT 0,
  total_investments NUMERIC(20,2) DEFAULT 0,
  total_savings NUMERIC(20,2) DEFAULT 0,
  net_profit NUMERIC(20,2) DEFAULT 0,
  financial_health_score NUMERIC(5,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, snapshot_date)
);

-- KPI Trend Cache
CREATE TABLE IF NOT EXISTS public.kpi_trend_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  metric_name TEXT NOT NULL,
  metric_value NUMERIC(20,2) DEFAULT 0,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  period_type TEXT DEFAULT 'monthly',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Report Archive
CREATE TABLE IF NOT EXISTS public.report_archive (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  report_type TEXT NOT NULL,
  report_title TEXT NOT NULL,
  period_label TEXT,
  period_start DATE,
  period_end DATE,
  report_data JSONB DEFAULT '{}',
  export_format TEXT DEFAULT 'pdf',
  generated_at TIMESTAMPTZ DEFAULT NOW(),
  file_url TEXT
);

-- AI Briefing History
CREATE TABLE IF NOT EXISTS public.ai_briefing_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  briefing_date DATE NOT NULL DEFAULT CURRENT_DATE,
  insights JSONB DEFAULT '[]',
  recommendations JSONB DEFAULT '[]',
  risk_alerts JSONB DEFAULT '[]',
  financial_summary JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Dashboard Personalization
CREATE TABLE IF NOT EXISTS public.dashboard_personalization (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  widget_order JSONB DEFAULT '[]',
  hidden_widgets JSONB DEFAULT '[]',
  pinned_reports JSONB DEFAULT '[]',
  preferred_chart_type TEXT DEFAULT 'line',
  default_period TEXT DEFAULT 'month',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

-- RLS Policies
ALTER TABLE public.executive_dashboard_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kpi_trend_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.report_archive ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_briefing_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dashboard_personalization ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'executive_dashboard_snapshots' AND policyname = 'exec_snapshots_user_policy') THEN
    CREATE POLICY exec_snapshots_user_policy ON public.executive_dashboard_snapshots
      FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'kpi_trend_cache' AND policyname = 'kpi_cache_user_policy') THEN
    CREATE POLICY kpi_cache_user_policy ON public.kpi_trend_cache
      FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'report_archive' AND policyname = 'report_archive_user_policy') THEN
    CREATE POLICY report_archive_user_policy ON public.report_archive
      FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'ai_briefing_history' AND policyname = 'ai_briefing_user_policy') THEN
    CREATE POLICY ai_briefing_user_policy ON public.ai_briefing_history
      FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'dashboard_personalization' AND policyname = 'dashboard_personalization_user_policy') THEN
    CREATE POLICY dashboard_personalization_user_policy ON public.dashboard_personalization
      FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_exec_snapshots_user_date ON public.executive_dashboard_snapshots(user_id, snapshot_date DESC);
CREATE INDEX IF NOT EXISTS idx_kpi_cache_user_metric ON public.kpi_trend_cache(user_id, metric_name, period_start DESC);
CREATE INDEX IF NOT EXISTS idx_report_archive_user ON public.report_archive(user_id, generated_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_briefing_user_date ON public.ai_briefing_history(user_id, briefing_date DESC);
