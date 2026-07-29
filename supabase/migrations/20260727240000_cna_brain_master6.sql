-- Migration: CNA Brain Master Prompt 6 — Enterprise AI Intelligence Tables
-- Adds: ai_audit_trail, ai_risk_scores, ai_scenario_analyses, ai_opportunity_log
-- Enhances: ai_recommendations with full lifecycle management

-- ─── AI AUDIT TRAIL ────────────────────────────────────────────────────────
-- Immutable record of every significant AI activity (no UPDATE/DELETE allowed)
CREATE TABLE IF NOT EXISTS public.ai_audit_trail (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  activity_type TEXT NOT NULL,
  -- e.g. 'financial_analysis','executive_briefing','scenario_simulation',
  --      'forecast_generation','recommendation_created','recommendation_accepted',
  --      'recommendation_declined','risk_assessment','opportunity_discovery'
  ai_service TEXT,
  modules_consulted TEXT[],
  result_summary TEXT,
  user_action TEXT,
  -- 'accepted','declined','postponed','viewed','ignored'
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_audit_user_type
  ON public.ai_audit_trail(user_id, activity_type, created_at DESC);

ALTER TABLE public.ai_audit_trail ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'ai_audit_trail' AND policyname = 'ai_audit_trail_select'
  ) THEN
    CREATE POLICY ai_audit_trail_select ON public.ai_audit_trail
      FOR SELECT USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'ai_audit_trail' AND policyname = 'ai_audit_trail_insert'
  ) THEN
    CREATE POLICY ai_audit_trail_insert ON public.ai_audit_trail
      FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;
-- No UPDATE/DELETE policies — immutable audit trail

-- ─── AI RISK SCORES ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.ai_risk_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  score_type TEXT NOT NULL,
  -- 'overall_financial_health','cash_flow_risk','business_risk',
  -- 'investment_risk','loan_risk','wealth_risk','goal_achievement_risk'
  score INTEGER NOT NULL CHECK (score BETWEEN 0 AND 100),
  rating TEXT NOT NULL,
  -- 'excellent','good','fair','poor','critical'
  explanation TEXT,
  improvement_tips TEXT[],
  contributing_factors JSONB DEFAULT '[]',
  calculated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_risk_scores_user
  ON public.ai_risk_scores(user_id, score_type, calculated_at DESC);

ALTER TABLE public.ai_risk_scores ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'ai_risk_scores' AND policyname = 'ai_risk_scores_user_policy'
  ) THEN
    CREATE POLICY ai_risk_scores_user_policy ON public.ai_risk_scores
      FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- ─── AI SCENARIO ANALYSES ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.ai_scenario_analyses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  scenario_type TEXT NOT NULL DEFAULT 'what_if',
  -- 'what_if','buy_asset','sell_asset','start_business','expand_business',
  -- 'repay_loan','new_investment','increase_savings','custom'
  input_parameters JSONB DEFAULT '{}',
  baseline_snapshot JSONB DEFAULT '{}',
  -- snapshot of financial position at time of analysis
  projected_outcomes JSONB DEFAULT '{}',
  -- {net_worth_change, cash_flow_change, monthly_savings_change, ...}
  assumptions TEXT[],
  risks TEXT[],
  opportunities TEXT[],
  confidence_level TEXT DEFAULT 'medium',
  -- 'high','medium','low'
  ai_recommendation TEXT,
  is_applied BOOLEAN DEFAULT FALSE,
  applied_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_scenarios_user
  ON public.ai_scenario_analyses(user_id, created_at DESC);

ALTER TABLE public.ai_scenario_analyses ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'ai_scenario_analyses' AND policyname = 'ai_scenarios_user_policy'
  ) THEN
    CREATE POLICY ai_scenarios_user_policy ON public.ai_scenario_analyses
      FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- ─── AI OPPORTUNITY LOG ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.ai_opportunity_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  opportunity_type TEXT NOT NULL,
  -- 'expense_reduction','income_increase','investment_diversification',
  -- 'debt_optimization','asset_utilization','savings_optimization','business_expansion'
  title TEXT NOT NULL,
  description TEXT,
  estimated_benefit TEXT,
  supporting_evidence TEXT,
  priority TEXT DEFAULT 'medium',
  -- 'high','medium','low'
  status TEXT DEFAULT 'new',
  -- 'new','viewed','accepted','declined','archived'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_opportunity_user
  ON public.ai_opportunity_log(user_id, status, created_at DESC);

ALTER TABLE public.ai_opportunity_log ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'ai_opportunity_log' AND policyname = 'ai_opportunity_user_policy'
  ) THEN
    CREATE POLICY ai_opportunity_user_policy ON public.ai_opportunity_log
      FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- ─── ENHANCE AI_RECOMMENDATIONS ────────────────────────────────────────────
-- Add lifecycle management columns if missing

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'ai_recommendations'
    AND column_name = 'user_action'
  ) THEN
    ALTER TABLE public.ai_recommendations ADD COLUMN user_action TEXT;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'ai_recommendations'
    AND column_name = 'action_taken_at'
  ) THEN
    ALTER TABLE public.ai_recommendations ADD COLUMN action_taken_at TIMESTAMPTZ;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'ai_recommendations'
    AND column_name = 'supporting_evidence'
  ) THEN
    ALTER TABLE public.ai_recommendations ADD COLUMN supporting_evidence TEXT;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'ai_recommendations'
    AND column_name = 'estimated_impact'
  ) THEN
    ALTER TABLE public.ai_recommendations ADD COLUMN estimated_impact TEXT;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'ai_recommendations'
    AND column_name = 'confidence_level'
  ) THEN
    ALTER TABLE public.ai_recommendations ADD COLUMN confidence_level TEXT DEFAULT 'medium';
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'ai_recommendations'
    AND column_name = 'potential_drawbacks'
  ) THEN
    ALTER TABLE public.ai_recommendations ADD COLUMN potential_drawbacks TEXT;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'ai_recommendations'
    AND column_name = 'modules_referenced'
  ) THEN
    ALTER TABLE public.ai_recommendations ADD COLUMN modules_referenced TEXT[];
  END IF;
END $$;

-- ─── AI PERSONALIZATION SETTINGS ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.ai_personalization (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  communication_style TEXT DEFAULT 'balanced',
  -- 'executive_summary','detailed_analysis','beginner_friendly','professional'
  recommendation_style TEXT DEFAULT 'balanced',
  -- 'conservative','balanced','growth_oriented'
  preferred_currency TEXT DEFAULT 'TZS',
  enable_memory BOOLEAN DEFAULT TRUE,
  enable_proactive_insights BOOLEAN DEFAULT TRUE,
  enable_risk_monitoring BOOLEAN DEFAULT TRUE,
  dashboard_preferences JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.ai_personalization ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'ai_personalization' AND policyname = 'ai_personalization_user_policy'
  ) THEN
    CREATE POLICY ai_personalization_user_policy ON public.ai_personalization
      FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;
