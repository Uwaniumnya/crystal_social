-- Admin User Management System
-- Handles admin roles, permissions, and user management features

-- Admin roles definition
CREATE TABLE IF NOT EXISTS admin_roles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    description TEXT,
    permissions JSONB DEFAULT '{}',
    is_system_role BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Insert default admin roles
INSERT INTO admin_roles (name, display_name, description, permissions, is_system_role) VALUES
('super_admin', 'Super Administrator', 'Full system access', '{
    "users": {"view": true, "edit": true, "delete": true, "ban": true},
    "support": {"view": true, "edit": true, "delete": true, "assign": true},
    "content": {"view": true, "edit": true, "delete": true, "moderate": true},
    "analytics": {"view": true},
    "system": {"view": true, "edit": true, "backup": true},
    "admin": {"view": true, "edit": true, "create": true, "delete": true}
}', true),
('admin', 'Administrator', 'General admin access', '{
    "users": {"view": true, "edit": true, "ban": true},
    "support": {"view": true, "edit": true, "assign": true},
    "content": {"view": true, "edit": true, "moderate": true},
    "analytics": {"view": true}
}', true),
('moderator', 'Moderator', 'Content moderation access', '{
    "users": {"view": true, "edit": false},
    "support": {"view": true, "edit": true},
    "content": {"view": true, "moderate": true},
    "analytics": {"view": false}
}', true),
('support_agent', 'Support Agent', 'Support ticket management', '{
    "users": {"view": true, "edit": false},
    "support": {"view": true, "edit": true, "assign": false},
    "content": {"view": true, "moderate": false},
    "analytics": {"view": false}
}', true)
ON CONFLICT (name) DO NOTHING;

-- Admin user assignments
CREATE TABLE IF NOT EXISTS admin_user_roles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    role_id UUID REFERENCES admin_roles(id) ON DELETE CASCADE,
    assigned_by UUID REFERENCES profiles(id),
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    notes TEXT,
    UNIQUE(user_id, role_id)
);

-- User management actions (bans, warnings, etc.)
CREATE TABLE IF NOT EXISTS user_moderation_actions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    target_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    admin_id UUID REFERENCES profiles(id),
    action_type TEXT NOT NULL CHECK (action_type IN (
        'warning',
        'temporary_ban',
        'permanent_ban',
        'unban',
        'content_removal',
        'account_restriction',
        'note'
    )),
    reason TEXT NOT NULL,
    duration_hours INTEGER, -- For temporary bans
    details JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE,
    revoked_at TIMESTAMP WITH TIME ZONE,
    revoked_by UUID REFERENCES profiles(id)
);

-- User reports from other users
CREATE TABLE IF NOT EXISTS user_reports (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    reporter_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    reported_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    report_type TEXT NOT NULL CHECK (report_type IN (
        'harassment',
        'inappropriate_content',
        'spam',
        'fake_account',
        'copyright_violation',
        'other'
    )),
    description TEXT NOT NULL,
    evidence_urls TEXT[] DEFAULT '{}',
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'investigating', 'resolved', 'dismissed')),
    admin_id UUID REFERENCES profiles(id),
    admin_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- Admin dashboard statistics
CREATE TABLE IF NOT EXISTS admin_statistics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    date DATE DEFAULT CURRENT_DATE,
    total_users INTEGER DEFAULT 0,
    new_users_today INTEGER DEFAULT 0,
    active_users_today INTEGER DEFAULT 0,
    total_posts INTEGER DEFAULT 0,
    new_posts_today INTEGER DEFAULT 0,
    total_support_requests INTEGER DEFAULT 0,
    open_support_requests INTEGER DEFAULT 0,
    resolved_support_requests_today INTEGER DEFAULT 0,
    total_reports INTEGER DEFAULT 0,
    pending_reports INTEGER DEFAULT 0,
    resolved_reports_today INTEGER DEFAULT 0,
    metrics JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    UNIQUE(date)
);

-- User activity tracking for admin purposes
CREATE TABLE IF NOT EXISTS user_activity_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    activity_type TEXT NOT NULL,
    activity_details JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Admin notification preferences
CREATE TABLE IF NOT EXISTS admin_notification_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    admin_id UUID REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,
    new_support_requests BOOLEAN DEFAULT true,
    urgent_support_requests BOOLEAN DEFAULT true,
    new_user_reports BOOLEAN DEFAULT true,
    system_alerts BOOLEAN DEFAULT true,
    daily_summary BOOLEAN DEFAULT true,
    email_notifications BOOLEAN DEFAULT true,
    push_notifications BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_admin_user_roles_user_id ON admin_user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_admin_user_roles_role_id ON admin_user_roles(role_id);
CREATE INDEX IF NOT EXISTS idx_admin_user_roles_active ON admin_user_roles(is_active);

CREATE INDEX IF NOT EXISTS idx_user_moderation_actions_target_user ON user_moderation_actions(target_user_id);
CREATE INDEX IF NOT EXISTS idx_user_moderation_actions_admin ON user_moderation_actions(admin_id);
CREATE INDEX IF NOT EXISTS idx_user_moderation_actions_type ON user_moderation_actions(action_type);
CREATE INDEX IF NOT EXISTS idx_user_moderation_actions_active ON user_moderation_actions(is_active);

CREATE INDEX IF NOT EXISTS idx_user_reports_reporter ON user_reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_user_reports_reported_user ON user_reports(reported_user_id);
CREATE INDEX IF NOT EXISTS idx_user_reports_status ON user_reports(status);
CREATE INDEX IF NOT EXISTS idx_user_reports_admin ON user_reports(admin_id);

CREATE INDEX IF NOT EXISTS idx_user_activity_logs_user_id ON user_activity_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_user_activity_logs_type ON user_activity_logs(activity_type);
CREATE INDEX IF NOT EXISTS idx_user_activity_logs_created_at ON user_activity_logs(created_at);

-- Enable RLS
ALTER TABLE admin_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_moderation_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_statistics ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_notification_settings ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Admin roles - only admins can view/modify
CREATE POLICY "Admins can view admin roles" ON admin_roles
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

CREATE POLICY "Super admins can manage admin roles" ON admin_roles
    FOR ALL USING (EXISTS (
        SELECT 1 FROM admin_user_roles aur
        JOIN admin_roles ar ON aur.role_id = ar.id
        WHERE aur.user_id = auth.uid() AND ar.name = 'super_admin' AND aur.is_active = true
    ));

-- User roles - admins can view/modify
CREATE POLICY "Admins can view user roles" ON admin_user_roles
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

CREATE POLICY "Admins can manage user roles" ON admin_user_roles
    FOR ALL USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

-- Moderation actions - admins only
CREATE POLICY "Admins can view moderation actions" ON user_moderation_actions
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

CREATE POLICY "Admins can create moderation actions" ON user_moderation_actions
    FOR INSERT WITH CHECK (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

-- User reports - users can view their own, admins can view all
CREATE POLICY "Users can view own reports" ON user_reports
    FOR SELECT USING (reporter_id = auth.uid() OR EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

CREATE POLICY "Users can create reports" ON user_reports
    FOR INSERT WITH CHECK (reporter_id = auth.uid());

CREATE POLICY "Admins can update reports" ON user_reports
    FOR UPDATE USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

-- Admin statistics - admins only
CREATE POLICY "Admins can view statistics" ON admin_statistics
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

-- Activity logs - admins only
CREATE POLICY "Admins can view activity logs" ON user_activity_logs
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

-- Notification settings - users can manage their own
CREATE POLICY "Admins can manage own notification settings" ON admin_notification_settings
    FOR ALL USING (admin_id = auth.uid() AND EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

-- Functions

-- Check if user has specific admin permission
CREATE OR REPLACE FUNCTION check_admin_permission(user_id UUID, permission_path TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    has_permission BOOLEAN := false;
BEGIN
    SELECT EXISTS (
        SELECT 1 
        FROM admin_user_roles aur
        JOIN admin_roles ar ON aur.role_id = ar.id
        WHERE aur.user_id = user_id 
        AND aur.is_active = true
        AND (aur.expires_at IS NULL OR aur.expires_at > NOW())
        AND ar.permissions #> string_to_array(permission_path, '.') = 'true'::jsonb
    ) INTO has_permission;
    
    RETURN has_permission;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get user's admin permissions
CREATE OR REPLACE FUNCTION get_user_admin_permissions(user_id UUID)
RETURNS JSONB AS $$
DECLARE
    merged_permissions JSONB := '{}';
    role_permissions JSONB;
BEGIN
    FOR role_permissions IN 
        SELECT ar.permissions
        FROM admin_user_roles aur
        JOIN admin_roles ar ON aur.role_id = ar.id
        WHERE aur.user_id = user_id 
        AND aur.is_active = true
        AND (aur.expires_at IS NULL OR aur.expires_at > NOW())
    LOOP
        merged_permissions := merged_permissions || role_permissions;
    END LOOP;
    
    RETURN merged_permissions;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Log user activity
CREATE OR REPLACE FUNCTION log_user_activity(
    user_id UUID,
    activity_type TEXT,
    activity_details JSONB DEFAULT '{}',
    ip_address INET DEFAULT NULL,
    user_agent TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    log_id UUID;
BEGIN
    INSERT INTO user_activity_logs (user_id, activity_type, activity_details, ip_address, user_agent)
    VALUES (user_id, activity_type, activity_details, ip_address, user_agent)
    RETURNING id INTO log_id;
    
    RETURN log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update admin statistics daily
CREATE OR REPLACE FUNCTION update_daily_admin_statistics()
RETURNS VOID AS $$
DECLARE
    today DATE := CURRENT_DATE;
    stats_record RECORD;
BEGIN
    -- Calculate today's statistics
    SELECT 
        (SELECT COUNT(*) FROM profiles) as total_users,
        (SELECT COUNT(*) FROM profiles WHERE DATE(created_at) = today) as new_users_today,
        (SELECT COUNT(DISTINCT user_id) FROM user_activity_logs WHERE DATE(created_at) = today) as active_users_today,
        (SELECT COUNT(*) FROM support_requests) as total_support_requests,
        (SELECT COUNT(*) FROM support_requests WHERE status IN ('open', 'in_progress')) as open_support_requests,
        (SELECT COUNT(*) FROM support_requests WHERE DATE(resolved_at) = today) as resolved_support_requests_today,
        (SELECT COUNT(*) FROM user_reports) as total_reports,
        (SELECT COUNT(*) FROM user_reports WHERE status = 'pending') as pending_reports,
        (SELECT COUNT(*) FROM user_reports WHERE DATE(resolved_at) = today) as resolved_reports_today
    INTO stats_record;
    
    -- Insert or update statistics
    INSERT INTO admin_statistics (
        date, total_users, new_users_today, active_users_today,
        total_support_requests, open_support_requests, resolved_support_requests_today,
        total_reports, pending_reports, resolved_reports_today
    ) VALUES (
        today, stats_record.total_users, stats_record.new_users_today, stats_record.active_users_today,
        stats_record.total_support_requests, stats_record.open_support_requests, stats_record.resolved_support_requests_today,
        stats_record.total_reports, stats_record.pending_reports, stats_record.resolved_reports_today
    )
    ON CONFLICT (date) DO UPDATE SET
        total_users = EXCLUDED.total_users,
        new_users_today = EXCLUDED.new_users_today,
        active_users_today = EXCLUDED.active_users_today,
        total_support_requests = EXCLUDED.total_support_requests,
        open_support_requests = EXCLUDED.open_support_requests,
        resolved_support_requests_today = EXCLUDED.resolved_support_requests_today,
        total_reports = EXCLUDED.total_reports,
        pending_reports = EXCLUDED.pending_reports,
        resolved_reports_today = EXCLUDED.resolved_reports_today;
END;
$$ LANGUAGE plpgsql;
