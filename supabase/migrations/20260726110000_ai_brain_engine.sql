-- CNA Central AI Brain Engine Migration
-- Tables: ai_conversations, ai_messages, ai_memory, ai_recommendations, ai_actions

-- ============================================================
-- 1. TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.ai_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  title VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.ai_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.ai_conversations(id) ON DELETE CASCADE,
  role VARCHAR(50) NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
  content TEXT NOT NULL,
  agent_type VARCHAR(100),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.ai_memory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  memory_type VARCHAR(100) NOT NULL,
  content TEXT NOT NULL,
  importance_score INTEGER DEFAULT 5 CHECK (importance_score BETWEEN 1 AND 10),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.ai_recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  category VARCHAR(100) NOT NULL,
  recommendation TEXT NOT NULL,
  priority VARCHAR(50) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
  status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'viewed', 'accepted', 'dismissed')),
  agent_type VARCHAR(100),
  related_module VARCHAR(100),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.ai_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  action_type VARCHAR(100) NOT NULL,
  description TEXT NOT NULL,
  parameters JSONB DEFAULT '{}',
  completed BOOLEAN DEFAULT FALSE,
  approved BOOLEAN DEFAULT FALSE,
  rejected BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- 2. INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_ai_conversations_user_id ON public.ai_conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_conversations_created_at ON public.ai_conversations(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_messages_conversation_id ON public.ai_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_ai_messages_created_at ON public.ai_messages(created_at);
CREATE INDEX IF NOT EXISTS idx_ai_memory_user_id ON public.ai_memory(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_memory_importance ON public.ai_memory(importance_score DESC);
CREATE INDEX IF NOT EXISTS idx_ai_recommendations_user_id ON public.ai_recommendations(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_recommendations_status ON public.ai_recommendations(status);
CREATE INDEX IF NOT EXISTS idx_ai_actions_user_id ON public.ai_actions(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_actions_completed ON public.ai_actions(completed);

-- ============================================================
-- 3. ENABLE RLS
-- ============================================================

ALTER TABLE public.ai_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_memory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_actions ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 4. RLS POLICIES
-- ============================================================

DROP POLICY IF EXISTS "users_manage_own_ai_conversations" ON public.ai_conversations;
CREATE POLICY "users_manage_own_ai_conversations"
ON public.ai_conversations FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_ai_messages" ON public.ai_messages;
CREATE POLICY "users_manage_own_ai_messages"
ON public.ai_messages FOR ALL TO authenticated
USING (
  conversation_id IN (
    SELECT id FROM public.ai_conversations WHERE user_id = auth.uid()
  )
)
WITH CHECK (
  conversation_id IN (
    SELECT id FROM public.ai_conversations WHERE user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "users_manage_own_ai_memory" ON public.ai_memory;
CREATE POLICY "users_manage_own_ai_memory"
ON public.ai_memory FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_ai_recommendations" ON public.ai_recommendations;
CREATE POLICY "users_manage_own_ai_recommendations"
ON public.ai_recommendations FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_ai_actions" ON public.ai_actions;
CREATE POLICY "users_manage_own_ai_actions"
ON public.ai_actions FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- ============================================================
-- 5. DEMO DATA FOR JONATHAN
-- ============================================================

DO $$
DECLARE
  jonathan_id UUID;
  conv_id UUID;
BEGIN
  SELECT id INTO jonathan_id FROM public.user_profiles LIMIT 1;

  IF jonathan_id IS NOT NULL THEN
    -- Create a sample conversation
    INSERT INTO public.ai_conversations (id, user_id, title, created_at)
    VALUES (gen_random_uuid(), jonathan_id, 'Financial Health Analysis', NOW() - INTERVAL '1 hour')
    ON CONFLICT (id) DO NOTHING;

    SELECT id INTO conv_id FROM public.ai_conversations WHERE user_id = jonathan_id LIMIT 1;

    IF conv_id IS NOT NULL THEN
      INSERT INTO public.ai_messages (conversation_id, role, content, agent_type, created_at)
      VALUES
        (conv_id, 'user', 'How is my financial situation?', NULL, NOW() - INTERVAL '55 minutes'),
        (conv_id, 'assistant', 'Your financial health is STRONG with a score of 78/100. Assets (TZS 850M) exceed liabilities (TZS 200M) by 4.25x. Monthly income (TZS 28.5M) covers expenses (TZS 12.3M) comfortably. Transport business is your top performer at 34% ROI. Recommend allocating TZS 5M/month to emergency fund.', 'financial_analyst', NOW() - INTERVAL '54 minutes'),
        (conv_id, 'user', 'Should I buy another vehicle?', NULL, NOW() - INTERVAL '30 minutes'),
        (conv_id, 'assistant', 'Analysis: YES, with conditions. Adding 1 bus generates +TZS 1.5M/week revenue, -TZS 400K fuel = net +TZS 1.1M/week. Cash purchase of TZS 45M is feasible. A 14-seater minibus gives best ROI at current fuel prices.', 'asset_intelligence', NOW() - INTERVAL '29 minutes')
      ON CONFLICT (id) DO NOTHING;
    END IF;

    -- Long-term memory entries
    INSERT INTO public.ai_memory (user_id, memory_type, content, importance_score, created_at)
    VALUES
      (jonathan_id, 'financial_goal', 'User wants to reach TZS 1 billion net worth by 2029', 9, NOW() - INTERVAL '7 days'),
      (jonathan_id, 'business_preference', 'Transport business is primary income source — user prefers fleet expansion', 8, NOW() - INTERVAL '5 days'),
      (jonathan_id, 'risk_profile', 'Moderate risk tolerance — prefers asset-backed investments', 7, NOW() - INTERVAL '3 days'),
      (jonathan_id, 'reporting_style', 'User prefers concise summaries with specific TZS figures', 6, NOW() - INTERVAL '2 days')
    ON CONFLICT (id) DO NOTHING;

    -- AI Recommendations
    INSERT INTO public.ai_recommendations (user_id, category, recommendation, priority, status, agent_type, related_module, created_at)
    VALUES
      (jonathan_id, 'expense_optimization', 'Fuel costs increased 20% this month. Implement route optimization to save TZS 640K/month.', 'high', 'pending', 'financial_analyst', 'business', NOW() - INTERVAL '2 hours'),
      (jonathan_id, 'asset_expansion', 'Your transport fleet ROI is 34%. Adding one 14-seater bus could generate TZS 1.1M net/week.', 'high', 'pending', 'asset_intelligence', 'assets', NOW() - INTERVAL '1 hour'),
      (jonathan_id, 'debt_management', '2 loan repayments due next month totaling TZS 3.6M. Current cash (TZS 45M) covers this 12x.', 'medium', 'viewed', 'debt_advisor', 'loans', NOW() - INTERVAL '3 hours'),
      (jonathan_id, 'investment_opportunity', 'Based on cash flow, you can invest TZS 5M more this month without affecting operations.', 'medium', 'pending', 'investment_analyst', 'investments', NOW() - INTERVAL '4 hours'),
      (jonathan_id, 'wealth_planning', 'At current growth rate of 20%/year, you will reach TZS 1B by 2029. Stay on track.', 'low', 'pending', 'planning_agent', 'wealth', NOW() - INTERVAL '6 hours')
    ON CONFLICT (id) DO NOTHING;

    -- AI Actions
    INSERT INTO public.ai_actions (user_id, action_type, description, parameters, completed, approved, created_at)
    VALUES
      (jonathan_id, 'create_budget', 'Create monthly fuel budget cap of TZS 2.5M for transport fleet', '{"module": "finance", "amount": 2500000, "category": "fuel"}', FALSE, FALSE, NOW() - INTERVAL '2 hours'),
      (jonathan_id, 'schedule_maintenance', 'Schedule preventive maintenance for Bus #3 (overdue by 2 weeks)', '{"module": "assets", "asset": "Bus #3", "type": "preventive"}', FALSE, FALSE, NOW() - INTERVAL '1 hour'),
      (jonathan_id, 'review_expense', 'Review and categorize TZS 1.8M driver overtime expenses from last month', '{"module": "business", "category": "overtime", "amount": 1800000}', TRUE, TRUE, NOW() - INTERVAL '5 hours')
    ON CONFLICT (id) DO NOTHING;

  ELSE
    RAISE NOTICE 'No user profiles found. Run identity migration first.';
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'AI Brain demo data insertion failed: %', SQLERRM;
END $$;
