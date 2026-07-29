-- Analytics & Executive Intelligence Engine
-- Part 11/15: analytics_metrics, dashboard_preferences, generated_reports, performance_scores

-- TABLE: analytics_metrics
CREATE TABLE IF NOT EXISTS public.analytics_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  metric_name VARCHAR(255) NOT NULL,
  metric_category VARCHAR(100),
  metric_value DECIMAL(15,2),
  measurement_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.analytics_metrics ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own analytics_metrics" ON public.analytics_metrics;
CREATE POLICY "Users can manage own analytics_metrics"
  ON public.analytics_metrics FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- TABLE: dashboard_preferences
CREATE TABLE IF NOT EXISTS public.dashboard_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  dashboard_type VARCHAR(100) NOT NULL,
  layout JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.dashboard_preferences ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own dashboard_preferences" ON public.dashboard_preferences;
CREATE POLICY "Users can manage own dashboard_preferences"
  ON public.dashboard_preferences FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- TABLE: generated_reports
CREATE TABLE IF NOT EXISTS public.generated_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  report_type VARCHAR(100) NOT NULL,
  title VARCHAR(255),
  content JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.generated_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own generated_reports" ON public.generated_reports;
CREATE POLICY "Users can manage own generated_reports"
  ON public.generated_reports FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- TABLE: performance_scores
CREATE TABLE IF NOT EXISTS public.performance_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  category VARCHAR(100) NOT NULL,
  score INTEGER CHECK (score >= 0 AND score <= 100),
  explanation TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.performance_scores ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own performance_scores" ON public.performance_scores;
CREATE POLICY "Users can manage own performance_scores"
  ON public.performance_scores FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_analytics_metrics_user_id ON public.analytics_metrics(user_id);
CREATE INDEX IF NOT EXISTS idx_analytics_metrics_category ON public.analytics_metrics(metric_category);
CREATE INDEX IF NOT EXISTS idx_analytics_metrics_date ON public.analytics_metrics(measurement_date);
CREATE INDEX IF NOT EXISTS idx_dashboard_preferences_user_id ON public.dashboard_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_generated_reports_user_id ON public.generated_reports(user_id);
CREATE INDEX IF NOT EXISTS idx_performance_scores_user_id ON public.performance_scores(user_id);

-- Demo data for Jonathan
DO $$
DECLARE
  v_user_id UUID;
BEGIN
  SELECT id INTO v_user_id FROM public.user_profiles WHERE email = 'jonathan@demo.com' LIMIT 1;

  IF v_user_id IS NOT NULL THEN
    -- Analytics Metrics
    INSERT INTO public.analytics_metrics (user_id, metric_name, metric_category, metric_value, measurement_date)
    SELECT v_user_id, 'Net Worth', 'wealth', 250000000, CURRENT_DATE
    WHERE NOT EXISTS (SELECT 1 FROM public.analytics_metrics WHERE user_id = v_user_id AND metric_name = 'Net Worth');

    INSERT INTO public.analytics_metrics (user_id, metric_name, metric_category, metric_value, measurement_date)
    SELECT v_user_id, 'Monthly Profit', 'income', 4000000, CURRENT_DATE
    WHERE NOT EXISTS (SELECT 1 FROM public.analytics_metrics WHERE user_id = v_user_id AND metric_name = 'Monthly Profit');

    INSERT INTO public.analytics_metrics (user_id, metric_name, metric_category, metric_value, measurement_date)
    SELECT v_user_id, 'Savings Rate', 'savings', 50, CURRENT_DATE
    WHERE NOT EXISTS (SELECT 1 FROM public.analytics_metrics WHERE user_id = v_user_id AND metric_name = 'Savings Rate');

    INSERT INTO public.analytics_metrics (user_id, metric_name, metric_category, metric_value, measurement_date)
    SELECT v_user_id, 'Debt Ratio', 'debt', 16.67, CURRENT_DATE
    WHERE NOT EXISTS (SELECT 1 FROM public.analytics_metrics WHERE user_id = v_user_id AND metric_name = 'Debt Ratio');

    -- Performance Scores
    INSERT INTO public.performance_scores (user_id, category, score, explanation)
    SELECT v_user_id, 'financial_health', 85, 'Strong savings rate and low debt ratio. Cash flow is positive with diversified income sources.'
    WHERE NOT EXISTS (SELECT 1 FROM public.performance_scores WHERE user_id = v_user_id AND category = 'financial_health');

    INSERT INTO public.performance_scores (user_id, category, score, explanation)
    SELECT v_user_id, 'business_health', 78, 'Transport business generating consistent revenue. Operational costs are manageable but fuel expenses trending up.'
    WHERE NOT EXISTS (SELECT 1 FROM public.performance_scores WHERE user_id = v_user_id AND category = 'business_health');

    INSERT INTO public.performance_scores (user_id, category, score, explanation)
    SELECT v_user_id, 'asset_performance', 90, 'Asset portfolio well-diversified. Vehicles generating strong returns relative to acquisition cost.'
    WHERE NOT EXISTS (SELECT 1 FROM public.performance_scores WHERE user_id = v_user_id AND category = 'asset_performance');

    INSERT INTO public.performance_scores (user_id, category, score, explanation)
    SELECT v_user_id, 'investment_performance', 72, 'Investment portfolio growing steadily. Consider diversifying into higher-yield instruments.'
    WHERE NOT EXISTS (SELECT 1 FROM public.performance_scores WHERE user_id = v_user_id AND category = 'investment_performance');

    -- Generated Reports
    INSERT INTO public.generated_reports (user_id, report_type, title, content)
    SELECT v_user_id, 'financial', 'Monthly Financial Report - July 2026',
      '{"income": 8000000, "expenses": 4000000, "assets": 300000000, "liabilities": 50000000, "net_worth": 250000000, "summary": "Strong financial position with positive cash flow and growing asset base."}'::jsonb
    WHERE NOT EXISTS (SELECT 1 FROM public.generated_reports WHERE user_id = v_user_id AND report_type = 'financial');

    INSERT INTO public.generated_reports (user_id, report_type, title, content)
    SELECT v_user_id, 'business', 'Business Performance Report - Q3 2026',
      '{"revenue": 15000000, "expenses": 9000000, "profit": 6000000, "growth_rate": 15, "summary": "Revenue increased 15% this quarter. Operational efficiency improved."}'::jsonb
    WHERE NOT EXISTS (SELECT 1 FROM public.generated_reports WHERE user_id = v_user_id AND report_type = 'business');

    -- Dashboard Preferences
    INSERT INTO public.dashboard_preferences (user_id, dashboard_type, layout)
    SELECT v_user_id, 'executive', '{"widgets": ["net_worth", "cash_flow", "business_revenue", "investment_returns", "health_scores"], "theme": "default"}'::jsonb
    WHERE NOT EXISTS (SELECT 1 FROM public.dashboard_preferences WHERE user_id = v_user_id AND dashboard_type = 'executive');
  END IF;
END $$;
