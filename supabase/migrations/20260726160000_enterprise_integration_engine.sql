-- ============================================================
-- CAPITAL NEXUS AI — Enterprise Integration & Extensibility Engine
-- Migration: 20260726160000_enterprise_integration_engine.sql
-- ============================================================

-- 1. TABLES

CREATE TABLE IF NOT EXISTS public.integrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID,
    provider_name VARCHAR(255) NOT NULL,
    provider_type VARCHAR(100) NOT NULL,
    status VARCHAR(50) DEFAULT 'inactive',
    configuration JSONB DEFAULT '{}'::JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.api_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID,
    organization_id UUID,
    provider_name VARCHAR(255) NOT NULL,
    key_reference TEXT NOT NULL,
    key_label VARCHAR(255),
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.integration_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    integration_id UUID REFERENCES public.integrations(id) ON DELETE SET NULL,
    request_type VARCHAR(100),
    status VARCHAR(50),
    duration_ms INTEGER,
    response_code INTEGER,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.webhook_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_name VARCHAR(255) NOT NULL,
    event_name VARCHAR(255) NOT NULL,
    payload JSONB DEFAULT '{}'::JSONB,
    processed BOOLEAN DEFAULT FALSE,
    processed_at TIMESTAMP,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.import_export_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID,
    job_type VARCHAR(100) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    file_name TEXT,
    file_format VARCHAR(50),
    record_count INTEGER DEFAULT 0,
    error_count INTEGER DEFAULT 0,
    result_summary JSONB DEFAULT '{}'::JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP
);

-- 2. INDEXES

CREATE INDEX IF NOT EXISTS idx_integrations_user ON public.integrations(organization_id);
CREATE INDEX IF NOT EXISTS idx_integrations_status ON public.integrations(status);
CREATE INDEX IF NOT EXISTS idx_api_keys_user ON public.api_keys(user_id);
CREATE INDEX IF NOT EXISTS idx_integration_logs_integration ON public.integration_logs(integration_id);
CREATE INDEX IF NOT EXISTS idx_integration_logs_created ON public.integration_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_webhook_events_processed ON public.webhook_events(processed);
CREATE INDEX IF NOT EXISTS idx_webhook_events_provider ON public.webhook_events(provider_name);
CREATE INDEX IF NOT EXISTS idx_import_export_jobs_user ON public.import_export_jobs(user_id);

-- 3. ENABLE RLS

ALTER TABLE public.integrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.integration_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.webhook_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.import_export_jobs ENABLE ROW LEVEL SECURITY;

-- 4. RLS POLICIES

DROP POLICY IF EXISTS "users_manage_own_integrations" ON public.integrations;
CREATE POLICY "users_manage_own_integrations"
ON public.integrations FOR ALL TO authenticated
USING (organization_id = auth.uid())
WITH CHECK (organization_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_api_keys" ON public.api_keys;
CREATE POLICY "users_manage_own_api_keys"
ON public.api_keys FOR ALL TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_view_own_integration_logs" ON public.integration_logs;
CREATE POLICY "users_view_own_integration_logs"
ON public.integration_logs FOR SELECT TO authenticated
USING (
    integration_id IN (
        SELECT id FROM public.integrations WHERE organization_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "users_insert_integration_logs" ON public.integration_logs;
CREATE POLICY "users_insert_integration_logs"
ON public.integration_logs FOR INSERT TO authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "users_manage_webhook_events" ON public.webhook_events;
CREATE POLICY "users_manage_webhook_events"
ON public.webhook_events FOR ALL TO authenticated
USING (true)
WITH CHECK (true);

DROP POLICY IF EXISTS "users_manage_own_import_export_jobs" ON public.import_export_jobs;
CREATE POLICY "users_manage_own_import_export_jobs"
ON public.import_export_jobs FOR ALL TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 5. DEMO DATA

DO $$
DECLARE
    existing_user_id UUID;
    integration_bank_id UUID := gen_random_uuid();
    integration_mm_id UUID := gen_random_uuid();
    integration_ai_id UUID := gen_random_uuid();
    integration_pay_id UUID := gen_random_uuid();
    integration_acc_id UUID := gen_random_uuid();
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'user_profiles'
    ) THEN
        SELECT id INTO existing_user_id FROM public.user_profiles LIMIT 1;

        IF existing_user_id IS NOT NULL THEN

            -- Demo integrations
            INSERT INTO public.integrations (id, organization_id, provider_name, provider_type, status, configuration)
            VALUES
                (integration_bank_id, existing_user_id, 'Sample Bank', 'banking', 'connected',
                 jsonb_build_object('sync_frequency', 'daily', 'account_types', ARRAY['checking','savings'], 'last_sync', NOW()::TEXT)),
                (integration_mm_id, existing_user_id, 'Sample Mobile Money', 'mobile_money', 'connected',
                 jsonb_build_object('provider', 'M-Pesa', 'phone_number', '+255700000000', 'last_sync', NOW()::TEXT)),
                (integration_ai_id, existing_user_id, 'OpenAI', 'ai_provider', 'configured',
                 jsonb_build_object('model', 'gpt-4o', 'features', ARRAY['chat','embeddings','summaries'])),
                (integration_pay_id, existing_user_id, 'Payment Gateway', 'payment', 'inactive',
                 jsonb_build_object('gateway', 'Stripe', 'currency', 'TZS')),
                (integration_acc_id, existing_user_id, 'Accounting Software', 'accounting', 'inactive',
                 jsonb_build_object('software', 'QuickBooks', 'sync_mode', 'bidirectional'))
            ON CONFLICT (id) DO NOTHING;

            -- Demo API keys
            INSERT INTO public.api_keys (user_id, provider_name, key_reference, key_label, is_active)
            VALUES
                (existing_user_id, 'OpenAI', 'enc:openai_key_ref_001', 'OpenAI Production Key', TRUE),
                (existing_user_id, 'Sample Bank', 'enc:bank_api_ref_002', 'Bank API Key', TRUE),
                (existing_user_id, 'Sample Mobile Money', 'enc:mm_api_ref_003', 'M-Pesa API Key', TRUE)
            ON CONFLICT (id) DO NOTHING;

            -- Demo integration logs
            INSERT INTO public.integration_logs (integration_id, request_type, status, duration_ms, response_code)
            VALUES
                (integration_bank_id, 'account_sync', 'success', 342, 200),
                (integration_bank_id, 'transaction_import', 'success', 1205, 200),
                (integration_mm_id, 'balance_check', 'success', 189, 200),
                (integration_mm_id, 'transaction_sync', 'success', 567, 200),
                (integration_ai_id, 'chat_completion', 'success', 2100, 200),
                (integration_ai_id, 'embedding_generation', 'success', 890, 200),
                (integration_bank_id, 'account_sync', 'error', 5000, 503)
            ON CONFLICT (id) DO NOTHING;

            -- Demo webhook events
            INSERT INTO public.webhook_events (provider_name, event_name, payload, processed)
            VALUES
                ('Sample Mobile Money', 'payment.received',
                 jsonb_build_object('amount', 500000, 'currency', 'TZS', 'sender', '+255711111111', 'reference', 'PAY-001'),
                 TRUE),
                ('Sample Bank', 'transaction.created',
                 jsonb_build_object('amount', 2000000, 'type', 'credit', 'account', 'ACC-001', 'description', 'Salary'),
                 TRUE),
                ('Payment Gateway', 'payment.confirmed',
                 jsonb_build_object('order_id', 'ORD-001', 'amount', 150000, 'status', 'confirmed'),
                 FALSE)
            ON CONFLICT (id) DO NOTHING;

            -- Demo import/export jobs
            INSERT INTO public.import_export_jobs (user_id, job_type, status, file_name, file_format, record_count)
            VALUES
                (existing_user_id, 'import', 'completed', 'transactions_q1_2025.csv', 'csv', 245),
                (existing_user_id, 'export', 'completed', 'executive_financial_report.json', 'json', 1),
                (existing_user_id, 'import', 'completed', 'assets_inventory.xlsx', 'excel', 18),
                (existing_user_id, 'export', 'pending', 'full_analytics_export.csv', 'csv', 0)
            ON CONFLICT (id) DO NOTHING;

        ELSE
            RAISE NOTICE 'No users found. Skipping demo data for integration engine.';
        END IF;
    ELSE
        RAISE NOTICE 'user_profiles table not found. Skipping demo data.';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Integration engine demo data failed: %', SQLERRM;
END $$;
