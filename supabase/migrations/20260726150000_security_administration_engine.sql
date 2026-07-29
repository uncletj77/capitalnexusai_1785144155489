-- ============================================================
-- CNA SECURITY, AUTHENTICATION, PERMISSIONS, AUDIT LOGS,
-- BACKUP, SYNCHRONIZATION & ENTERPRISE ADMINISTRATION ENGINE
-- Migration: 20260726150000_security_administration_engine.sql
-- ============================================================

-- ─── TABLES ──────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  owner_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.departments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  is_system_role BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  permission_key VARCHAR(255) UNIQUE NOT NULL,
  module VARCHAR(100),
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.role_permissions (
  role_id UUID NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
  permission_id UUID NOT NULL REFERENCES public.permissions(id) ON DELETE CASCADE,
  PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE IF NOT EXISTS public.user_roles (
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  role_id UUID NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  assigned_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  PRIMARY KEY (user_id, role_id, organization_id)
);

CREATE TABLE IF NOT EXISTS public.audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  organization_id UUID REFERENCES public.organizations(id) ON DELETE SET NULL,
  module VARCHAR(100),
  action VARCHAR(100),
  entity_type VARCHAR(100),
  entity_id UUID,
  ip_address TEXT,
  device_info TEXT,
  old_value JSONB,
  new_value JSONB,
  severity VARCHAR(50) DEFAULT 'info',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.active_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  device_name TEXT,
  device_type TEXT,
  ip_address TEXT,
  location TEXT,
  last_activity TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.backup_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  organization_id UUID REFERENCES public.organizations(id) ON DELETE SET NULL,
  backup_type VARCHAR(100),
  status VARCHAR(50) DEFAULT 'pending',
  size_bytes BIGINT,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.security_monitoring_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  organization_id UUID REFERENCES public.organizations(id) ON DELETE SET NULL,
  event_type VARCHAR(100) NOT NULL,
  severity VARCHAR(50) DEFAULT 'medium',
  description TEXT,
  metadata JSONB,
  is_resolved BOOLEAN DEFAULT FALSE,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── INDEXES ─────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON public.audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_org_id ON public.audit_logs(organization_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_active_sessions_user_id ON public.active_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_active_sessions_is_active ON public.active_sessions(is_active);
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON public.user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_org_id ON public.user_roles(organization_id);
CREATE INDEX IF NOT EXISTS idx_backup_jobs_user_id ON public.backup_jobs(user_id);
CREATE INDEX IF NOT EXISTS idx_security_events_user_id ON public.security_monitoring_events(user_id);
CREATE INDEX IF NOT EXISTS idx_organizations_owner_id ON public.organizations(owner_id);

-- ─── ENABLE RLS ───────────────────────────────────────────────

ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.active_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.backup_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.security_monitoring_events ENABLE ROW LEVEL SECURITY;

-- ─── RLS POLICIES ────────────────────────────────────────────

DROP POLICY IF EXISTS "users_manage_own_organizations" ON public.organizations;
CREATE POLICY "users_manage_own_organizations"
ON public.organizations FOR ALL TO authenticated
USING (owner_id = auth.uid()) WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS "org_members_view_organizations" ON public.organizations;
CREATE POLICY "org_members_view_organizations"
ON public.organizations FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.user_roles ur
    WHERE ur.organization_id = organizations.id
    AND ur.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "users_view_org_departments" ON public.departments;
CREATE POLICY "users_view_org_departments"
ON public.departments FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.user_roles ur
    WHERE ur.organization_id = departments.organization_id
    AND ur.user_id = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.organizations o
    WHERE o.id = departments.organization_id
    AND o.owner_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "users_manage_org_departments" ON public.departments;
CREATE POLICY "users_manage_org_departments"
ON public.departments FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.organizations o
    WHERE o.id = departments.organization_id
    AND o.owner_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.organizations o
    WHERE o.id = departments.organization_id
    AND o.owner_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "users_view_roles" ON public.roles;
CREATE POLICY "users_view_roles"
ON public.roles FOR SELECT TO authenticated
USING (
  is_system_role = TRUE
  OR organization_id IS NULL
  OR EXISTS (
    SELECT 1 FROM public.user_roles ur
    WHERE ur.organization_id = roles.organization_id
    AND ur.user_id = auth.uid()
  )
  OR EXISTS (
    SELECT 1 FROM public.organizations o
    WHERE o.id = roles.organization_id
    AND o.owner_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "owners_manage_roles" ON public.roles;
CREATE POLICY "owners_manage_roles"
ON public.roles FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.organizations o
    WHERE o.id = roles.organization_id
    AND o.owner_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.organizations o
    WHERE o.id = roles.organization_id
    AND o.owner_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "authenticated_view_permissions" ON public.permissions;
CREATE POLICY "authenticated_view_permissions"
ON public.permissions FOR SELECT TO authenticated
USING (TRUE);

DROP POLICY IF EXISTS "authenticated_view_role_permissions" ON public.role_permissions;
CREATE POLICY "authenticated_view_role_permissions"
ON public.role_permissions FOR SELECT TO authenticated
USING (TRUE);

DROP POLICY IF EXISTS "users_view_own_roles" ON public.user_roles;
CREATE POLICY "users_view_own_roles"
ON public.user_roles FOR SELECT TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "owners_manage_user_roles" ON public.user_roles;
CREATE POLICY "owners_manage_user_roles"
ON public.user_roles FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.organizations o
    WHERE o.id = user_roles.organization_id
    AND o.owner_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.organizations o
    WHERE o.id = user_roles.organization_id
    AND o.owner_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "users_view_own_audit_logs" ON public.audit_logs;
CREATE POLICY "users_view_own_audit_logs"
ON public.audit_logs FOR SELECT TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "system_insert_audit_logs" ON public.audit_logs;
CREATE POLICY "system_insert_audit_logs"
ON public.audit_logs FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_sessions" ON public.active_sessions;
CREATE POLICY "users_manage_own_sessions"
ON public.active_sessions FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_backups" ON public.backup_jobs;
CREATE POLICY "users_manage_own_backups"
ON public.backup_jobs FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_view_own_security_events" ON public.security_monitoring_events;
CREATE POLICY "users_view_own_security_events"
ON public.security_monitoring_events FOR SELECT TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "system_insert_security_events" ON public.security_monitoring_events;
CREATE POLICY "system_insert_security_events"
ON public.security_monitoring_events FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid());

-- ─── DEMO DATA ────────────────────────────────────────────────

DO $$
DECLARE
  existing_user_id UUID;
  org_id UUID := gen_random_uuid();
  dept_finance UUID := gen_random_uuid();
  dept_ops UUID := gen_random_uuid();
  dept_invest UUID := gen_random_uuid();
  dept_admin UUID := gen_random_uuid();
  role_owner UUID := gen_random_uuid();
  role_admin UUID := gen_random_uuid();
  role_manager UUID := gen_random_uuid();
  role_accountant UUID := gen_random_uuid();
  role_employee UUID := gen_random_uuid();
  role_auditor UUID := gen_random_uuid();
  role_viewer UUID := gen_random_uuid();
  perm_finance_read UUID := gen_random_uuid();
  perm_finance_write UUID := gen_random_uuid();
  perm_finance_delete UUID := gen_random_uuid();
  perm_loan_read UUID := gen_random_uuid();
  perm_loan_write UUID := gen_random_uuid();
  perm_loan_delete UUID := gen_random_uuid();
  perm_investment_read UUID := gen_random_uuid();
  perm_investment_write UUID := gen_random_uuid();
  perm_investment_export UUID := gen_random_uuid();
  perm_asset_read UUID := gen_random_uuid();
  perm_asset_update UUID := gen_random_uuid();
  perm_ai_execute UUID := gen_random_uuid();
  perm_reports_export UUID := gen_random_uuid();
  perm_users_manage UUID := gen_random_uuid();
  perm_workflows_manage UUID := gen_random_uuid();
  session1_id UUID := gen_random_uuid();
  session2_id UUID := gen_random_uuid();
  backup1_id UUID := gen_random_uuid();
  backup2_id UUID := gen_random_uuid();
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'user_profiles'
  ) THEN
    RAISE NOTICE 'user_profiles table not found, skipping demo data';
    RETURN;
  END IF;

  SELECT id INTO existing_user_id FROM public.user_profiles LIMIT 1;

  IF existing_user_id IS NULL THEN
    RAISE NOTICE 'No users found, skipping demo data';
    RETURN;
  END IF;

  -- Organization
  INSERT INTO public.organizations (id, name, description, owner_id, is_active)
  VALUES (org_id, 'Capital Nexus Holdings', 'Enterprise financial management organization for CNA platform', existing_user_id, TRUE)
  ON CONFLICT (id) DO NOTHING;

  -- Departments
  INSERT INTO public.departments (id, organization_id, name, description) VALUES
    (dept_finance, org_id, 'Finance', 'Financial management and accounting department'),
    (dept_ops, org_id, 'Operations', 'Day-to-day operational management'),
    (dept_invest, org_id, 'Investments', 'Investment portfolio and strategy management'),
    (dept_admin, org_id, 'Administration', 'Enterprise administration and HR')
  ON CONFLICT (id) DO NOTHING;

  -- System Roles
  INSERT INTO public.roles (id, organization_id, name, description, is_system_role) VALUES
    (role_owner, org_id, 'Owner', 'Full system access and ownership rights', TRUE),
    (role_admin, org_id, 'Administrator', 'System administration with full configuration access', TRUE),
    (role_manager, org_id, 'Manager', 'Department management and reporting access', FALSE),
    (role_accountant, org_id, 'Accountant', 'Financial records management and reporting', FALSE),
    (role_employee, org_id, 'Employee', 'Basic read access to assigned modules', FALSE),
    (role_auditor, org_id, 'Auditor', 'Read-only access to all financial records and audit logs', FALSE),
    (role_viewer, org_id, 'Viewer', 'Read-only access to dashboards and reports', FALSE)
  ON CONFLICT (id) DO NOTHING;

  -- Permissions
  INSERT INTO public.permissions (id, permission_key, module, description) VALUES
    (perm_finance_read, 'finance.read', 'Finance', 'View financial transactions and records'),
    (perm_finance_write, 'finance.write', 'Finance', 'Create and edit financial records'),
    (perm_finance_delete, 'finance.delete', 'Finance', 'Delete financial records'),
    (perm_loan_read, 'loan.read', 'Loans', 'View loan information'),
    (perm_loan_write, 'loan.write', 'Loans', 'Create and manage loans'),
    (perm_loan_delete, 'loan.delete', 'Loans', 'Delete loan records'),
    (perm_investment_read, 'investment.read', 'Investments', 'View investment portfolio'),
    (perm_investment_write, 'investment.write', 'Investments', 'Manage investment records'),
    (perm_investment_export, 'investment.export', 'Investments', 'Export investment reports'),
    (perm_asset_read, 'asset.read', 'Assets', 'View asset information'),
    (perm_asset_update, 'asset.update', 'Assets', 'Update asset records'),
    (perm_ai_execute, 'ai.execute', 'AI', 'Execute AI recommendations and actions'),
    (perm_reports_export, 'reports.export', 'Reports', 'Export financial and business reports'),
    (perm_users_manage, 'users.manage', 'Administration', 'Manage organization users and roles'),
    (perm_workflows_manage, 'workflows.manage', 'Automation', 'Create and manage automation workflows')
  ON CONFLICT (permission_key) DO NOTHING;

  -- Role-Permission assignments (Owner gets all)
  INSERT INTO public.role_permissions (role_id, permission_id) VALUES
    (role_owner, perm_finance_read), (role_owner, perm_finance_write), (role_owner, perm_finance_delete),
    (role_owner, perm_loan_read), (role_owner, perm_loan_write), (role_owner, perm_loan_delete),
    (role_owner, perm_investment_read), (role_owner, perm_investment_write), (role_owner, perm_investment_export),
    (role_owner, perm_asset_read), (role_owner, perm_asset_update),
    (role_owner, perm_ai_execute), (role_owner, perm_reports_export),
    (role_owner, perm_users_manage), (role_owner, perm_workflows_manage),
    -- Admin
    (role_admin, perm_finance_read), (role_admin, perm_finance_write),
    (role_admin, perm_loan_read), (role_admin, perm_loan_write),
    (role_admin, perm_investment_read), (role_admin, perm_investment_write),
    (role_admin, perm_asset_read), (role_admin, perm_asset_update),
    (role_admin, perm_ai_execute), (role_admin, perm_reports_export),
    (role_admin, perm_users_manage), (role_admin, perm_workflows_manage),
    -- Manager
    (role_manager, perm_finance_read), (role_manager, perm_finance_write),
    (role_manager, perm_loan_read), (role_manager, perm_investment_read),
    (role_manager, perm_asset_read), (role_manager, perm_reports_export),
    -- Accountant
    (role_accountant, perm_finance_read), (role_accountant, perm_finance_write),
    (role_accountant, perm_loan_read), (role_accountant, perm_reports_export),
    -- Employee
    (role_employee, perm_finance_read), (role_employee, perm_asset_read),
    -- Auditor
    (role_auditor, perm_finance_read), (role_auditor, perm_loan_read),
    (role_auditor, perm_investment_read), (role_auditor, perm_asset_read),
    (role_auditor, perm_reports_export),
    -- Viewer
    (role_viewer, perm_finance_read), (role_viewer, perm_asset_read)
  ON CONFLICT (role_id, permission_id) DO NOTHING;

  -- Assign owner role to existing user
  INSERT INTO public.user_roles (user_id, role_id, organization_id)
  VALUES (existing_user_id, role_owner, org_id)
  ON CONFLICT (user_id, role_id, organization_id) DO NOTHING;

  -- Demo active sessions
  INSERT INTO public.active_sessions (id, user_id, device_name, device_type, ip_address, location, last_activity, expires_at, is_active) VALUES
    (session1_id, existing_user_id, 'Chrome on Windows', 'desktop', '197.250.10.45', 'Dar es Salaam, TZ', NOW() - INTERVAL '5 minutes', NOW() + INTERVAL '7 days', TRUE),
    (session2_id, existing_user_id, 'CNA Mobile App', 'mobile', '197.250.10.46', 'Dar es Salaam, TZ', NOW() - INTERVAL '2 hours', NOW() + INTERVAL '30 days', TRUE)
  ON CONFLICT (id) DO NOTHING;

  -- Demo audit logs
  INSERT INTO public.audit_logs (id, user_id, organization_id, module, action, entity_type, ip_address, device_info, severity) VALUES
    (gen_random_uuid(), existing_user_id, org_id, 'Auth', 'login', 'session', '197.250.10.45', 'Chrome on Windows', 'info'),
    (gen_random_uuid(), existing_user_id, org_id, 'Finance', 'create', 'transaction', '197.250.10.45', 'Chrome on Windows', 'info'),
    (gen_random_uuid(), existing_user_id, org_id, 'Assets', 'update', 'asset', '197.250.10.46', 'CNA Mobile App', 'info'),
    (gen_random_uuid(), existing_user_id, org_id, 'Investments', 'export', 'report', '197.250.10.45', 'Chrome on Windows', 'warning'),
    (gen_random_uuid(), existing_user_id, org_id, 'Auth', 'login', 'session', '197.250.10.46', 'CNA Mobile App', 'info')
  ON CONFLICT (id) DO NOTHING;

  -- Demo backup jobs
  INSERT INTO public.backup_jobs (id, user_id, organization_id, backup_type, status, size_bytes, started_at, completed_at, metadata) VALUES
    (backup1_id, existing_user_id, org_id, 'full', 'completed', 52428800, NOW() - INTERVAL '1 day', NOW() - INTERVAL '23 hours', jsonb_build_object('modules', ARRAY['finance', 'assets', 'loans', 'investments'], 'records', 1247)),
    (backup2_id, existing_user_id, org_id, 'incremental', 'completed', 5242880, NOW() - INTERVAL '6 hours', NOW() - INTERVAL '5 hours 55 minutes', jsonb_build_object('modules', ARRAY['finance', 'transactions'], 'records', 89))
  ON CONFLICT (id) DO NOTHING;

  -- Demo security monitoring events
  INSERT INTO public.security_monitoring_events (id, user_id, organization_id, event_type, severity, description, is_resolved) VALUES
    (gen_random_uuid(), existing_user_id, org_id, 'new_device_login', 'medium', 'Login detected from new device: CNA Mobile App from Dar es Salaam', TRUE),
    (gen_random_uuid(), existing_user_id, org_id, 'large_export', 'warning', 'Investment report exported — 847 records', FALSE),
    (gen_random_uuid(), existing_user_id, org_id, 'permission_check', 'info', 'AI recommendation approved for financial simulation', TRUE)
  ON CONFLICT (id) DO NOTHING;

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Security demo data insertion failed: %', SQLERRM;
END $$;
