-- ============================================================
-- CNA AUTOMATION & SMART ASSISTANT ENGINE
-- Migration: 20260726140000_automation_smart_assistant_engine.sql
-- ============================================================

-- ─── TABLE: automation_rules ────────────────────────────────
CREATE TABLE IF NOT EXISTS public.automation_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  trigger_type VARCHAR(100) NOT NULL,
  condition JSONB DEFAULT '{}',
  action JSONB DEFAULT '{}',
  enabled BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_automation_rules_user_id ON public.automation_rules(user_id);
CREATE INDEX IF NOT EXISTS idx_automation_rules_trigger_type ON public.automation_rules(trigger_type);

-- ─── TABLE: automation_events ───────────────────────────────
CREATE TABLE IF NOT EXISTS public.automation_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type VARCHAR(100) NOT NULL,
  entity_type VARCHAR(100),
  entity_id UUID,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  payload JSONB DEFAULT '{}',
  processed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_automation_events_user_id ON public.automation_events(user_id);
CREATE INDEX IF NOT EXISTS idx_automation_events_processed ON public.automation_events(processed);
CREATE INDEX IF NOT EXISTS idx_automation_events_event_type ON public.automation_events(event_type);

-- ─── TABLE: notifications ───────────────────────────────────
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  message TEXT,
  notification_type VARCHAR(100) DEFAULT 'general',
  priority VARCHAR(50) DEFAULT 'normal',
  status VARCHAR(50) DEFAULT 'unread',
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_status ON public.notifications(status);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);

-- ─── TABLE: reminders ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  due_date TIMESTAMPTZ,
  repeat_pattern VARCHAR(100) DEFAULT 'none',
  completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reminders_user_id ON public.reminders(user_id);
CREATE INDEX IF NOT EXISTS idx_reminders_due_date ON public.reminders(due_date);
CREATE INDEX IF NOT EXISTS idx_reminders_completed ON public.reminders(completed);

-- ─── TABLE: tasks ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  task_type VARCHAR(100) DEFAULT 'general',
  priority VARCHAR(50) DEFAULT 'medium',
  status VARCHAR(50) DEFAULT 'pending',
  due_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON public.tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON public.tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_priority ON public.tasks(priority);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON public.tasks(due_date);

-- ─── TABLE: workflow_logs ───────────────────────────────────
CREATE TABLE IF NOT EXISTS public.workflow_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workflow_id UUID,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  status VARCHAR(100) NOT NULL,
  execution_time TIMESTAMPTZ DEFAULT NOW(),
  result JSONB DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_workflow_logs_user_id ON public.workflow_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_workflow_logs_workflow_id ON public.workflow_logs(workflow_id);

-- ─── ENABLE RLS ─────────────────────────────────────────────
ALTER TABLE public.automation_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.automation_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workflow_logs ENABLE ROW LEVEL SECURITY;

-- ─── RLS POLICIES ───────────────────────────────────────────
DROP POLICY IF EXISTS "users_manage_own_automation_rules" ON public.automation_rules;
CREATE POLICY "users_manage_own_automation_rules"
ON public.automation_rules FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_automation_events" ON public.automation_events;
CREATE POLICY "users_manage_own_automation_events"
ON public.automation_events FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_notifications" ON public.notifications;
CREATE POLICY "users_manage_own_notifications"
ON public.notifications FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_reminders" ON public.reminders;
CREATE POLICY "users_manage_own_reminders"
ON public.reminders FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_tasks" ON public.tasks;
CREATE POLICY "users_manage_own_tasks"
ON public.tasks FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_workflow_logs" ON public.workflow_logs;
CREATE POLICY "users_manage_own_workflow_logs"
ON public.workflow_logs FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- ─── DEMO DATA ──────────────────────────────────────────────
DO $$
DECLARE
  existing_user_id UUID;
  rule1_id UUID := gen_random_uuid();
  rule2_id UUID := gen_random_uuid();
  rule3_id UUID := gen_random_uuid();
  notif1_id UUID := gen_random_uuid();
  notif2_id UUID := gen_random_uuid();
  notif3_id UUID := gen_random_uuid();
  notif4_id UUID := gen_random_uuid();
  notif5_id UUID := gen_random_uuid();
  notif6_id UUID := gen_random_uuid();
  reminder1_id UUID := gen_random_uuid();
  reminder2_id UUID := gen_random_uuid();
  reminder3_id UUID := gen_random_uuid();
  task1_id UUID := gen_random_uuid();
  task2_id UUID := gen_random_uuid();
  task3_id UUID := gen_random_uuid();
  task4_id UUID := gen_random_uuid();
  task5_id UUID := gen_random_uuid();
  wf_log1_id UUID := gen_random_uuid();
  wf_log2_id UUID := gen_random_uuid();
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'user_profiles'
  ) THEN
    SELECT id INTO existing_user_id FROM public.user_profiles LIMIT 1;

    IF existing_user_id IS NOT NULL THEN

      -- Demo Automation Rules (3 workflows from spec)
      INSERT INTO public.automation_rules (id, user_id, name, trigger_type, condition, action, enabled)
      VALUES
        (rule1_id, existing_user_id, 'Loan Due Alert',
         'loan_due',
         jsonb_build_object('days_before', 3, 'loan_type', 'any'),
         jsonb_build_object('notify_user', true, 'create_task', true, 'ask_ai', true),
         true),
        (rule2_id, existing_user_id, 'Business Revenue Drop Alert',
         'revenue_drop',
         jsonb_build_object('threshold_percent', 20, 'entity_type', 'business'),
         jsonb_build_object('generate_report', true, 'notify_owner', true, 'create_review_task', true),
         true),
        (rule3_id, existing_user_id, 'Savings Goal Reached',
         'goal_achieved',
         jsonb_build_object('goal_type', 'savings', 'completion_percent', 100),
         jsonb_build_object('congratulate', true, 'suggest_investment', true),
         true)
      ON CONFLICT (id) DO NOTHING;

      -- Demo Automation Events
      INSERT INTO public.automation_events (id, event_type, entity_type, user_id, payload, processed)
      VALUES
        (gen_random_uuid(), 'loan_due', 'loan', existing_user_id,
         jsonb_build_object('loan_name', 'Vehicle Loan', 'days_remaining', 3, 'amount', 2500000),
         false),
        (gen_random_uuid(), 'revenue_drop', 'business', existing_user_id,
         jsonb_build_object('business_name', 'Transport Co', 'drop_percent', 22, 'month', 'July 2026'),
         false),
        (gen_random_uuid(), 'goal_achieved', 'financial_goal', existing_user_id,
         jsonb_build_object('goal_name', 'Emergency Fund', 'target_amount', 10000000),
         true)
      ON CONFLICT (id) DO NOTHING;

      -- Demo Notifications (various categories)
      INSERT INTO public.notifications (id, user_id, title, message, notification_type, priority, status)
      VALUES
        (notif1_id, existing_user_id,
         'Loan Repayment Due in 3 Days',
         'Your vehicle loan repayment of TSh 2,500,000 is due on July 29, 2026. Please ensure sufficient funds.',
         'loan', 'high', 'unread'),
        (notif2_id, existing_user_id,
         'Business Revenue Alert',
         'Transport Co revenue dropped by 22% this month. An executive report has been generated.',
         'business', 'high', 'unread'),
        (notif3_id, existing_user_id,
         'Savings Goal Achieved!',
         'Congratulations! You have reached your Emergency Fund goal of TSh 10,000,000.',
         'ai', 'normal', 'unread'),
        (notif4_id, existing_user_id,
         'Vehicle Insurance Expiring Soon',
         'Your vehicle insurance expires in 7 days. Schedule renewal to avoid coverage gaps.',
         'asset', 'high', 'unread'),
        (notif5_id, existing_user_id,
         'Investment Review Overdue',
         'You have not reviewed your investment portfolio in 90 days. Consider scheduling a review.',
         'investment', 'normal', 'read'),
        (notif6_id, existing_user_id,
         'Monthly Budget Exceeded',
         'Your fuel expenses increased by 18% this month, exceeding the allocated budget.',
         'finance', 'normal', 'read')
      ON CONFLICT (id) DO NOTHING;

      -- Demo Reminders
      INSERT INTO public.reminders (id, user_id, title, description, due_date, repeat_pattern, completed)
      VALUES
        (reminder1_id, existing_user_id,
         'Renew Vehicle Insurance',
         'Contact insurance provider to renew coverage for the transport fleet.',
         NOW() + INTERVAL '7 days', 'yearly', false),
        (reminder2_id, existing_user_id,
         'Monthly Loan Repayment',
         'Transfer TSh 2,500,000 for vehicle loan repayment.',
         NOW() + INTERVAL '3 days', 'monthly', false),
        (reminder3_id, existing_user_id,
         'Quarterly Investment Review',
         'Review investment portfolio performance and rebalance if needed.',
         NOW() + INTERVAL '14 days', 'quarterly', false)
      ON CONFLICT (id) DO NOTHING;

      -- Demo Tasks (AI-generated)
      INSERT INTO public.tasks (id, user_id, title, description, task_type, priority, status, due_date)
      VALUES
        (task1_id, existing_user_id,
         'Review Monthly Expenses',
         'Analyze spending patterns for July 2026 and identify cost reduction opportunities.',
         'finance', 'medium', 'pending',
         NOW() + INTERVAL '1 day'),
        (task2_id, existing_user_id,
         'Renew Fleet Insurance',
         'Contact insurance provider and renew coverage for all transport vehicles.',
         'asset', 'high', 'pending',
         NOW() + INTERVAL '7 days'),
        (task3_id, existing_user_id,
         'Generate Annual Financial Report',
         'Compile comprehensive annual report covering all financial modules.',
         'report', 'low', 'pending',
         NOW() + INTERVAL '30 days'),
        (task4_id, existing_user_id,
         'Loan Repayment - Vehicle Loan',
         'Process TSh 2,500,000 repayment for vehicle loan before due date.',
         'loan', 'high', 'pending',
         NOW() + INTERVAL '3 days'),
        (task5_id, existing_user_id,
         'Business Revenue Review Meeting',
         'Schedule executive review for Transport Co revenue decline analysis.',
         'business', 'high', 'completed',
         NOW() - INTERVAL '2 days')
      ON CONFLICT (id) DO NOTHING;

      -- Demo Workflow Logs
      INSERT INTO public.workflow_logs (id, user_id, workflow_id, status, execution_time, result)
      VALUES
        (wf_log1_id, existing_user_id, rule1_id, 'completed', NOW() - INTERVAL '1 hour',
         jsonb_build_object('actions_executed', 3, 'notification_sent', true, 'task_created', true)),
        (wf_log2_id, existing_user_id, rule3_id, 'completed', NOW() - INTERVAL '2 hours',
         jsonb_build_object('actions_executed', 2, 'notification_sent', true, 'suggestion_generated', true))
      ON CONFLICT (id) DO NOTHING;

    ELSE
      RAISE NOTICE 'No users found. Run identity migration first.';
    END IF;
  ELSE
    RAISE NOTICE 'Table user_profiles does not exist.';
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Automation demo data failed: %', SQLERRM;
END $$;
