-- ============================================================
-- Capital NEXUS AI — Identity System Migration
-- Part 2/15: Users, Organizations, Roles, Permissions, Security
-- ============================================================

-- ─── 1. ENUM TYPES ───────────────────────────────────────────
DROP TYPE IF EXISTS public.account_type CASCADE;
CREATE TYPE public.account_type AS ENUM ('personal', 'family', 'business', 'organization');

DROP TYPE IF EXISTS public.account_status CASCADE;
CREATE TYPE public.account_status AS ENUM ('active', 'suspended', 'pending_verification', 'deactivated');

DROP TYPE IF EXISTS public.subscription_level CASCADE;
CREATE TYPE public.subscription_level AS ENUM ('free', 'basic', 'premium', 'enterprise');

DROP TYPE IF EXISTS public.org_type CASCADE;
CREATE TYPE public.org_type AS ENUM ('company', 'hospital', 'school', 'ngo', 'government', 'family', 'other');

DROP TYPE IF EXISTS public.default_role CASCADE;
CREATE TYPE public.default_role AS ENUM ('owner', 'administrator', 'manager', 'accountant', 'employee', 'viewer');

DROP TYPE IF EXISTS public.permission_module CASCADE;
CREATE TYPE public.permission_module AS ENUM ('finance', 'assets', 'business', 'investments', 'loans', 'reports', 'settings', 'users', 'ai');

DROP TYPE IF EXISTS public.permission_action CASCADE;
CREATE TYPE public.permission_action AS ENUM ('view', 'create', 'edit', 'delete', 'approve', 'export');

DROP TYPE IF EXISTS public.audit_severity CASCADE;
CREATE TYPE public.audit_severity AS ENUM ('low', 'medium', 'high', 'critical');

-- ─── 2. CORE TABLES ──────────────────────────────────────────

-- User Profiles (linked to auth.users)
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL DEFAULT '',
    email TEXT NOT NULL UNIQUE,
    phone TEXT,
    alternative_contact TEXT,
    profile_photo_url TEXT,
    date_of_birth DATE,
    gender TEXT,
    country TEXT DEFAULT 'Tanzania',
    preferred_language TEXT DEFAULT 'English',
    time_zone TEXT DEFAULT 'Africa/Dar_es_Salaam',
    account_type public.account_type DEFAULT 'personal'::public.account_type,
    account_status public.account_status DEFAULT 'active'::public.account_status,
    subscription_level public.subscription_level DEFAULT 'free'::public.subscription_level,
    email_verified BOOLEAN DEFAULT false,
    phone_verified BOOLEAN DEFAULT false,
    two_factor_enabled BOOLEAN DEFAULT false,
    biometric_enabled BOOLEAN DEFAULT false,
    security_level INTEGER DEFAULT 1,
    personalization_goals JSONB DEFAULT '[]'::jsonb,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Organizations
CREATE TABLE IF NOT EXISTS public.organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    org_type public.org_type DEFAULT 'company'::public.org_type,
    industry TEXT,
    registration_number TEXT,
    address TEXT,
    city TEXT,
    country TEXT DEFAULT 'Tanzania',
    website TEXT,
    logo_url TEXT,
    owner_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Departments (within organizations)
CREATE TABLE IF NOT EXISTS public.departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    manager_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Roles
CREATE TABLE IF NOT EXISTS public.roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    default_role public.default_role,
    is_system_role BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Permissions
CREATE TABLE IF NOT EXISTS public.permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    module public.permission_module NOT NULL,
    action public.permission_action NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Role Permissions (junction)
CREATE TABLE IF NOT EXISTS public.role_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_id UUID NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES public.permissions(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Organization Members
CREATE TABLE IF NOT EXISTS public.organization_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    role_id UUID REFERENCES public.roles(id) ON DELETE SET NULL,
    department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
    joined_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- Audit Logs
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    organization_id UUID REFERENCES public.organizations(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    module TEXT,
    entity_type TEXT,
    entity_id UUID,
    previous_value JSONB,
    new_value JSONB,
    ip_address TEXT,
    device_info TEXT,
    severity public.audit_severity DEFAULT 'low'::public.audit_severity,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- User Sessions
CREATE TABLE IF NOT EXISTS public.user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    device_name TEXT,
    device_type TEXT,
    ip_address TEXT,
    location TEXT,
    is_active BOOLEAN DEFAULT true,
    last_active_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Security Alerts
CREATE TABLE IF NOT EXISTS public.security_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    alert_type TEXT NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    severity public.audit_severity DEFAULT 'medium'::public.audit_severity,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ─── 3. INDEXES ──────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_profiles_account_type ON public.user_profiles(account_type);
CREATE INDEX IF NOT EXISTS idx_organizations_owner_id ON public.organizations(owner_id);
CREATE INDEX IF NOT EXISTS idx_org_members_user_id ON public.organization_members(user_id);
CREATE INDEX IF NOT EXISTS idx_org_members_org_id ON public.organization_members(organization_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON public.audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON public.user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_security_alerts_user_id ON public.security_alerts(user_id);

-- ─── 4. FUNCTIONS ────────────────────────────────────────────

-- Auto-create user_profiles on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.user_profiles (
        id, email, full_name, phone, account_type, account_status, email_verified
    ) VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'phone', NULL),
        COALESCE(NEW.raw_user_meta_data->>'account_type', 'personal')::public.account_type,
        'active'::public.account_status,
        true
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$;

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- ─── 5. ENABLE RLS ───────────────────────────────────────────
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organization_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.security_alerts ENABLE ROW LEVEL SECURITY;

-- ─── 6. RLS POLICIES ─────────────────────────────────────────

-- user_profiles: own row only
DROP POLICY IF EXISTS "users_manage_own_user_profiles" ON public.user_profiles;
CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles FOR ALL TO authenticated
USING (id = auth.uid()) WITH CHECK (id = auth.uid());

-- organizations: owner can manage, members can view
DROP POLICY IF EXISTS "org_owner_manage" ON public.organizations;
CREATE POLICY "org_owner_manage"
ON public.organizations FOR ALL TO authenticated
USING (owner_id = auth.uid()) WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS "org_member_view" ON public.organizations;
CREATE POLICY "org_member_view"
ON public.organizations FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.organization_members om
        WHERE om.organization_id = id AND om.user_id = auth.uid() AND om.is_active = true
    )
);

-- departments: org members can view
DROP POLICY IF EXISTS "dept_member_view" ON public.departments;
CREATE POLICY "dept_member_view"
ON public.departments FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.organization_members om
        WHERE om.organization_id = organization_id AND om.user_id = auth.uid() AND om.is_active = true
    )
);

DROP POLICY IF EXISTS "dept_owner_manage" ON public.departments;
CREATE POLICY "dept_owner_manage"
ON public.departments FOR ALL TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.organizations o
        WHERE o.id = organization_id AND o.owner_id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.organizations o
        WHERE o.id = organization_id AND o.owner_id = auth.uid()
    )
);

-- roles: org members can view
DROP POLICY IF EXISTS "roles_member_view" ON public.roles;
CREATE POLICY "roles_member_view"
ON public.roles FOR SELECT TO authenticated
USING (
    organization_id IS NULL OR
    EXISTS (
        SELECT 1 FROM public.organization_members om
        WHERE om.organization_id = organization_id AND om.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "roles_owner_manage" ON public.roles;
CREATE POLICY "roles_owner_manage"
ON public.roles FOR ALL TO authenticated
USING (
    organization_id IS NULL OR
    EXISTS (
        SELECT 1 FROM public.organizations o
        WHERE o.id = organization_id AND o.owner_id = auth.uid()
    )
)
WITH CHECK (
    organization_id IS NULL OR
    EXISTS (
        SELECT 1 FROM public.organizations o
        WHERE o.id = organization_id AND o.owner_id = auth.uid()
    )
);

-- permissions: all authenticated can view
DROP POLICY IF EXISTS "permissions_view_all" ON public.permissions;
CREATE POLICY "permissions_view_all"
ON public.permissions FOR SELECT TO authenticated
USING (true);

-- role_permissions: org members can view
DROP POLICY IF EXISTS "role_permissions_view" ON public.role_permissions;
CREATE POLICY "role_permissions_view"
ON public.role_permissions FOR SELECT TO authenticated
USING (true);

-- organization_members: own membership or org owner
DROP POLICY IF EXISTS "org_members_own_view" ON public.organization_members;
CREATE POLICY "org_members_own_view"
ON public.organization_members FOR SELECT TO authenticated
USING (
    user_id = auth.uid() OR
    EXISTS (
        SELECT 1 FROM public.organizations o
        WHERE o.id = organization_id AND o.owner_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "org_members_owner_manage" ON public.organization_members;
CREATE POLICY "org_members_owner_manage"
ON public.organization_members FOR ALL TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.organizations o
        WHERE o.id = organization_id AND o.owner_id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.organizations o
        WHERE o.id = organization_id AND o.owner_id = auth.uid()
    )
);

-- audit_logs: own logs only
DROP POLICY IF EXISTS "audit_logs_own_view" ON public.audit_logs;
CREATE POLICY "audit_logs_own_view"
ON public.audit_logs FOR SELECT TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "audit_logs_insert" ON public.audit_logs;
CREATE POLICY "audit_logs_insert"
ON public.audit_logs FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid());

-- user_sessions: own sessions
DROP POLICY IF EXISTS "sessions_own_manage" ON public.user_sessions;
CREATE POLICY "sessions_own_manage"
ON public.user_sessions FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- security_alerts: own alerts
DROP POLICY IF EXISTS "alerts_own_manage" ON public.security_alerts;
CREATE POLICY "alerts_own_manage"
ON public.security_alerts FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- ─── 7. TRIGGERS ─────────────────────────────────────────────
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_organizations_updated_at ON public.organizations;
CREATE TRIGGER update_organizations_updated_at
    BEFORE UPDATE ON public.organizations
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ─── 8. SEED PERMISSIONS ─────────────────────────────────────
DO $$
BEGIN
    INSERT INTO public.permissions (module, action, description) VALUES
        ('finance', 'view', 'View financial data'),
        ('finance', 'create', 'Create transactions'),
        ('finance', 'edit', 'Edit transactions'),
        ('finance', 'delete', 'Delete transactions'),
        ('finance', 'approve', 'Approve payments'),
        ('finance', 'export', 'Export financial reports'),
        ('assets', 'view', 'View assets'),
        ('assets', 'create', 'Add new assets'),
        ('assets', 'edit', 'Edit asset details'),
        ('assets', 'delete', 'Delete assets'),
        ('business', 'view', 'View business data'),
        ('business', 'create', 'Create businesses'),
        ('business', 'edit', 'Edit business details'),
        ('business', 'delete', 'Delete businesses'),
        ('investments', 'view', 'View investments'),
        ('investments', 'create', 'Add investments'),
        ('investments', 'edit', 'Edit investments'),
        ('loans', 'view', 'View loans'),
        ('loans', 'create', 'Create loans'),
        ('loans', 'edit', 'Edit loans'),
        ('reports', 'view', 'View reports'),
        ('reports', 'export', 'Export reports'),
        ('settings', 'view', 'View settings'),
        ('settings', 'edit', 'Edit settings'),
        ('users', 'view', 'View users'),
        ('users', 'create', 'Invite users'),
        ('users', 'edit', 'Edit user roles'),
        ('users', 'delete', 'Remove users'),
        ('ai', 'view', 'Use AI assistant')
    ON CONFLICT DO NOTHING;
END $$;

-- ─── 9. MOCK DATA ─────────────────────────────────────────────
DO $$
DECLARE
    demo_uuid UUID := gen_random_uuid();
    org_uuid UUID := gen_random_uuid();
    dept_finance UUID := gen_random_uuid();
    dept_ops UUID := gen_random_uuid();
    role_owner UUID := gen_random_uuid();
    role_manager UUID := gen_random_uuid();
    role_accountant UUID := gen_random_uuid();
BEGIN
    -- Demo auth user
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES (
        demo_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'jonathan@capitalnexus.ai', crypt('Nexus@2026', gen_salt('bf', 10)), now(), now(), now(),
        jsonb_build_object('full_name', 'Jonathan Mwangi', 'account_type', 'business', 'phone', '+255712345678'),
        jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
        false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
    ) ON CONFLICT (id) DO NOTHING;

    -- Organization
    INSERT INTO public.organizations (id, name, org_type, industry, address, city, country, owner_id)
    VALUES (org_uuid, 'Mwangi Holdings Ltd', 'company'::public.org_type, 'Transport & Logistics', 'Kariakoo Street 45', 'Dar es Salaam', 'Tanzania', demo_uuid)
    ON CONFLICT (id) DO NOTHING;

    -- Departments
    INSERT INTO public.departments (id, organization_id, name, description) VALUES
        (dept_finance, org_uuid, 'Finance', 'Financial management and accounting'),
        (dept_ops, org_uuid, 'Operations', 'Day-to-day business operations')
    ON CONFLICT (id) DO NOTHING;

    -- Roles
    INSERT INTO public.roles (id, organization_id, name, description, default_role, is_system_role) VALUES
        (role_owner, org_uuid, 'Owner', 'Full access to all modules', 'owner'::public.default_role, true),
        (role_manager, org_uuid, 'Manager', 'Manage departments and approve workflows', 'manager'::public.default_role, true),
        (role_accountant, org_uuid, 'Accountant', 'Access to financial data and reports', 'accountant'::public.default_role, true)
    ON CONFLICT (id) DO NOTHING;

    -- Org membership for demo user
    INSERT INTO public.organization_members (organization_id, user_id, role_id, department_id)
    VALUES (org_uuid, demo_uuid, role_owner, dept_finance)
    ON CONFLICT DO NOTHING;

    -- Demo sessions
    INSERT INTO public.user_sessions (user_id, device_name, device_type, ip_address, location, is_active, last_active_at)
    VALUES
        (demo_uuid, 'Samsung Galaxy S23', 'Android', '196.216.1.45', 'Dar es Salaam, TZ', true, now()),
        (demo_uuid, 'MacBook Pro', 'Desktop', '196.216.1.46', 'Dar es Salaam, TZ', false, now() - interval '1 day')
    ON CONFLICT DO NOTHING;

    -- Demo audit logs
    INSERT INTO public.audit_logs (user_id, action, module, entity_type, severity)
    VALUES
        (demo_uuid, 'User signed in', 'settings', 'session', 'low'::public.audit_severity),
        (demo_uuid, 'Profile updated', 'settings', 'user_profile', 'low'::public.audit_severity),
        (demo_uuid, 'Organization created', 'business', 'organization', 'medium'::public.audit_severity),
        (demo_uuid, 'Asset added: Land in Dodoma', 'assets', 'asset', 'medium'::public.audit_severity),
        (demo_uuid, 'Transaction approved: TZS 5,000,000', 'finance', 'transaction', 'high'::public.audit_severity)
    ON CONFLICT DO NOTHING;

    -- Demo security alerts
    INSERT INTO public.security_alerts (user_id, alert_type, message, severity, is_read)
    VALUES
        (demo_uuid, 'new_login', 'New login from MacBook Pro in Dar es Salaam', 'low'::public.audit_severity, true),
        (demo_uuid, 'permission_change', 'Role permissions updated for Accountant role', 'medium'::public.audit_severity, false),
        (demo_uuid, 'suspicious_activity', 'Multiple failed login attempts detected', 'high'::public.audit_severity, false)
    ON CONFLICT DO NOTHING;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Mock data error: %', SQLERRM;
END $$;
