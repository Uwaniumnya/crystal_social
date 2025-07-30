-- Admin Integration Setup and Configuration
-- This file sets up the admin system integration and initial configuration

-- Add admin-related columns to profiles table if they don't exist
DO $$
BEGIN
    -- Add is_admin column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'is_admin') THEN
        ALTER TABLE profiles ADD COLUMN is_admin BOOLEAN DEFAULT false;
    END IF;
    
    -- Add is_moderator column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'is_moderator') THEN
        ALTER TABLE profiles ADD COLUMN is_moderator BOOLEAN DEFAULT false;
    END IF;
    
    -- Add admin_notes column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'admin_notes') THEN
        ALTER TABLE profiles ADD COLUMN admin_notes TEXT;
    END IF;
    
    -- Add last_admin_action column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'last_admin_action') THEN
        ALTER TABLE profiles ADD COLUMN last_admin_action TIMESTAMP WITH TIME ZONE;
    END IF;
END $$;

-- Create indexes for admin-related profile columns
CREATE INDEX IF NOT EXISTS idx_profiles_is_admin ON profiles(is_admin) WHERE is_admin = true;
CREATE INDEX IF NOT EXISTS idx_profiles_is_moderator ON profiles(is_moderator) WHERE is_moderator = true;

-- Admin configuration settings
CREATE TABLE IF NOT EXISTS admin_config (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    config_key TEXT UNIQUE NOT NULL,
    config_value JSONB NOT NULL,
    description TEXT,
    category TEXT DEFAULT 'general',
    is_public BOOLEAN DEFAULT false, -- whether non-admins can read this setting
    updated_by UUID REFERENCES profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Insert default admin configuration
INSERT INTO admin_config (config_key, config_value, description, category, is_public) VALUES
('support_email', '"support@crystalsocial.com"', 'Primary support email address', 'contact', true),
('auto_moderation_enabled', 'true', 'Enable automatic content moderation', 'moderation', false),
('max_support_requests_per_user_per_day', '5', 'Maximum support requests per user per day', 'limits', false),
('admin_session_timeout_minutes', '60', 'Admin session timeout in minutes', 'security', false),
('require_2fa_for_admins', 'true', 'Require 2FA for admin accounts', 'security', false),
('content_review_threshold', '3', 'Number of reports before content requires review', 'moderation', false),
('new_user_verification_required', 'false', 'Require email verification for new users', 'registration', true),
('maintenance_mode', 'false', 'Enable maintenance mode', 'system', true),
('backup_retention_days', '90', 'Number of days to retain backups', 'backup', false)
ON CONFLICT (config_key) DO NOTHING;

-- Admin quick actions/shortcuts
CREATE TABLE IF NOT EXISTS admin_quick_actions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    action_type TEXT NOT NULL CHECK (action_type IN (
        'sql_query',
        'api_call',
        'function_call',
        'batch_operation'
    )),
    action_config JSONB NOT NULL,
    category TEXT DEFAULT 'general',
    icon TEXT DEFAULT 'settings',
    requires_confirmation BOOLEAN DEFAULT true,
    required_permissions TEXT[] DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Insert common admin quick actions
INSERT INTO admin_quick_actions (name, description, action_type, action_config, category, icon, requires_confirmation, required_permissions) VALUES
('Clear Cache', 'Clear application cache', 'api_call', '{"endpoint": "/admin/cache/clear", "method": "POST"}', 'system', 'cached', true, ARRAY['system.edit']),
('Generate Backup', 'Create database backup', 'function_call', '{"function": "create_backup", "params": {}}', 'backup', 'backup', true, ARRAY['system.backup']),
('Send System Notification', 'Send notification to all users', 'api_call', '{"endpoint": "/admin/notifications/broadcast", "method": "POST"}', 'communication', 'notifications', true, ARRAY['admin.edit']),
('Export User Data', 'Export user data for compliance', 'function_call', '{"function": "export_user_data", "params": {"user_id": null}}', 'compliance', 'download', true, ARRAY['users.view']),
('Reset User Password', 'Reset user password and send email', 'function_call', '{"function": "reset_user_password", "params": {"user_id": null}}', 'user_management', 'lock_reset', true, ARRAY['users.edit'])
ON CONFLICT DO NOTHING;

-- Admin dashboard widgets configuration
CREATE TABLE IF NOT EXISTS admin_dashboard_widgets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    admin_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    widget_type TEXT NOT NULL CHECK (widget_type IN (
        'stats_card',
        'chart',
        'table',
        'alert_list',
        'quick_actions',
        'recent_activity'
    )),
    widget_config JSONB NOT NULL,
    position_x INTEGER DEFAULT 0,
    position_y INTEGER DEFAULT 0,
    width INTEGER DEFAULT 1,
    height INTEGER DEFAULT 1,
    is_visible BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Admin saved filters for various views
CREATE TABLE IF NOT EXISTS admin_saved_filters (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    admin_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    filter_name TEXT NOT NULL,
    view_type TEXT NOT NULL, -- 'support_requests', 'moderation_queue', 'users', etc.
    filter_config JSONB NOT NULL,
    is_default BOOLEAN DEFAULT false,
    is_shared BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- System health checks configuration
CREATE TABLE IF NOT EXISTS system_health_checks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    check_name TEXT UNIQUE NOT NULL,
    check_type TEXT NOT NULL,
    check_config JSONB NOT NULL,
    frequency_minutes INTEGER DEFAULT 5,
    timeout_seconds INTEGER DEFAULT 30,
    is_active BOOLEAN DEFAULT true,
    alert_on_failure BOOLEAN DEFAULT true,
    failure_threshold INTEGER DEFAULT 3, -- consecutive failures before alert
    last_run_at TIMESTAMP WITH TIME ZONE,
    last_status TEXT DEFAULT 'unknown',
    last_result JSONB,
    consecutive_failures INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Add constraints after table creation to avoid syntax issues
ALTER TABLE system_health_checks ADD CONSTRAINT check_type_values 
    CHECK (check_type IN ('db_connection', 'api_endpoint', 'service_status', 'disk_space', 'memory_usage', 'custom_query'));

ALTER TABLE system_health_checks ADD CONSTRAINT check_status_values 
    CHECK (last_status IN ('healthy', 'warning', 'critical', 'unknown'));

-- Insert default health checks
INSERT INTO system_health_checks (check_name, check_type, check_config, frequency_minutes, alert_on_failure) VALUES
('Database Connection', 'db_connection', '{"query": "SELECT 1", "expected_result": "1"}', 1, true),
('Support Requests Response Time', 'custom_query', '{"query": "SELECT AVG(EXTRACT(EPOCH FROM (resolved_at - created_at))/3600) FROM support_requests WHERE resolved_at > NOW() - INTERVAL ''24 hours''", "warning_threshold": 24, "critical_threshold": 48}', 60, true),
('Active User Sessions', 'custom_query', '{"query": "SELECT COUNT(*) FROM admin_sessions WHERE is_active = true AND last_activity_at > NOW() - INTERVAL ''1 hour''", "warning_threshold": 100, "critical_threshold": 500}', 15, false),
('Unresolved Alerts', 'custom_query', '{"query": "SELECT COUNT(*) FROM admin_alerts WHERE status = ''active''", "warning_threshold": 10, "critical_threshold": 50}', 5, true)
ON CONFLICT (check_name) DO NOTHING;

-- Enable RLS
ALTER TABLE admin_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_quick_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_dashboard_widgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_saved_filters ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_health_checks ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Config - admins can view non-public, everyone can view public
CREATE POLICY "Anyone can view public config" ON admin_config
    FOR SELECT USING (is_public = true);

CREATE POLICY "Admins can view all config" ON admin_config
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

CREATE POLICY "Admins can manage config" ON admin_config
    FOR ALL USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

-- Quick actions - admins only
CREATE POLICY "Admins can view quick actions" ON admin_quick_actions
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

-- Dashboard widgets - users can manage their own
CREATE POLICY "Admins can manage own dashboard widgets" ON admin_dashboard_widgets
    FOR ALL USING (admin_id = auth.uid() AND EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

-- Saved filters - users can manage their own and view shared ones
CREATE POLICY "Admins can view relevant filters" ON admin_saved_filters
    FOR SELECT USING ((admin_id = auth.uid() OR is_shared = true) AND EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

CREATE POLICY "Admins can manage own filters" ON admin_saved_filters
    FOR ALL USING (admin_id = auth.uid() AND EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

-- Health checks - admins only
CREATE POLICY "Admins can view health checks" ON system_health_checks
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

-- Helper Functions

-- Get admin configuration value
CREATE OR REPLACE FUNCTION get_admin_config(config_key TEXT)
RETURNS JSONB AS $$
DECLARE
    config_value JSONB;
BEGIN
    SELECT ac.config_value INTO config_value 
    FROM admin_config ac 
    WHERE ac.config_key = get_admin_config.config_key;
    
    RETURN COALESCE(config_value, 'null'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Set admin configuration value
CREATE OR REPLACE FUNCTION set_admin_config(
    config_key TEXT,
    config_value JSONB,
    admin_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    INSERT INTO admin_config (config_key, config_value, updated_by)
    VALUES (config_key, config_value, admin_id)
    ON CONFLICT (config_key) DO UPDATE SET
        config_value = EXCLUDED.config_value,
        updated_by = EXCLUDED.updated_by,
        updated_at = NOW();
        
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check system health
CREATE OR REPLACE FUNCTION run_health_check(check_id UUID)
RETURNS JSONB AS $$
DECLARE
    check_record RECORD;
    result JSONB;
    status TEXT := 'healthy';
    error_message TEXT;
BEGIN
    SELECT * INTO check_record FROM system_health_checks WHERE id = check_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('error', 'Health check not found');
    END IF;
    
    BEGIN
        CASE check_record.check_type
            WHEN 'db_connection' THEN
                -- Simple database connectivity check
                EXECUTE check_record.check_config->>'query';
                result := jsonb_build_object('status', 'healthy', 'message', 'Database connection successful');
                
            WHEN 'custom_query' THEN
                -- Custom query with thresholds
                DECLARE
                    query_result NUMERIC;
                    warning_threshold NUMERIC := (check_record.check_config->>'warning_threshold')::NUMERIC;
                    critical_threshold NUMERIC := (check_record.check_config->>'critical_threshold')::NUMERIC;
                BEGIN
                    EXECUTE check_record.check_config->>'query' INTO query_result;
                    
                    IF critical_threshold IS NOT NULL AND query_result >= critical_threshold THEN
                        status := 'critical';
                    ELSIF warning_threshold IS NOT NULL AND query_result >= warning_threshold THEN
                        status := 'warning';
                    END IF;
                    
                    result := jsonb_build_object(
                        'status', status, 
                        'value', query_result,
                        'warning_threshold', warning_threshold,
                        'critical_threshold', critical_threshold
                    );
                END;
                
            ELSE
                result := jsonb_build_object('error', 'Unsupported check type');
                status := 'unknown';
        END CASE;
        
    EXCEPTION WHEN OTHERS THEN
        error_message := SQLERRM;
        result := jsonb_build_object('error', error_message);
        status := 'critical';
    END;
    
    -- Update the health check record
    UPDATE system_health_checks SET
        last_run_at = NOW(),
        last_status = status,
        last_result = result,
        consecutive_failures = CASE 
            WHEN status IN ('critical', 'warning') THEN consecutive_failures + 1 
            ELSE 0 
        END
    WHERE id = check_id;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Initialize default admin user (call this manually with appropriate user ID)
CREATE OR REPLACE FUNCTION make_user_admin(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- Update user profile
    UPDATE profiles SET 
        is_admin = true,
        last_admin_action = NOW()
    WHERE id = user_id;
    
    -- Assign super admin role
    INSERT INTO admin_user_roles (user_id, role_id, assigned_by)
    SELECT user_id, ar.id, user_id
    FROM admin_roles ar
    WHERE ar.name = 'super_admin'
    ON CONFLICT (user_id, role_id) DO NOTHING;
    
    -- Create default notification settings
    INSERT INTO admin_notification_settings (admin_id)
    VALUES (user_id)
    ON CONFLICT (admin_id) DO NOTHING;
    
    -- Log the action
    PERFORM log_admin_action(
        user_id,
        'user_promotion',
        'user_management',
        'user',
        user_id,
        'Admin promotion',
        jsonb_build_object('promoted_to', 'super_admin')
    );
    
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply updated_at triggers to admin tables
-- Note: update_updated_at_column() function is defined in 00_shared_utilities.sql
CREATE TRIGGER update_admin_config_updated_at BEFORE UPDATE ON admin_config FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_admin_dashboard_widgets_updated_at BEFORE UPDATE ON admin_dashboard_widgets FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Admin setup complete
SELECT 'Admin Integration Setup Complete!' as setup_status, NOW() as completed_at;
