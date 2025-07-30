-- Admin Audit Logs and System Monitoring
-- Tracks all admin actions, system events, and security logs

-- Admin action logs
CREATE TABLE IF NOT EXISTS admin_action_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    admin_id UUID REFERENCES profiles(id),
    action_type TEXT NOT NULL,
    action_category TEXT NOT NULL CHECK (action_category IN (
        'user_management',
        'content_moderation',
        'support_management',
        'system_administration',
        'security',
        'configuration'
    )),
    target_type TEXT, -- e.g., 'user', 'post', 'support_request'
    target_id UUID,
    target_identifier TEXT, -- human-readable identifier
    action_details JSONB DEFAULT '{}',
    before_state JSONB,
    after_state JSONB,
    ip_address INET,
    user_agent TEXT,
    success BOOLEAN DEFAULT true,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- System event logs
CREATE TABLE IF NOT EXISTS system_event_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    event_type TEXT NOT NULL,
    event_category TEXT NOT NULL CHECK (event_category IN (
        'authentication',
        'authorization',
        'database',
        'api',
        'storage',
        'notification',
        'backup',
        'security',
        'error'
    )),
    severity TEXT NOT NULL DEFAULT 'info' CHECK (severity IN ('debug', 'info', 'warning', 'error', 'critical')),
    message TEXT NOT NULL,
    details JSONB DEFAULT '{}',
    source TEXT, -- component/service that generated the event
    user_id UUID REFERENCES profiles(id),
    session_id TEXT,
    ip_address INET,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Security logs for sensitive operations
CREATE TABLE IF NOT EXISTS security_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id),
    event_type TEXT NOT NULL CHECK (event_type IN (
        'login_success',
        'login_failure',
        'logout',
        'password_change',
        'email_change',
        'admin_access',
        'permission_escalation',
        'suspicious_activity',
        'account_lockout',
        'data_export',
        'data_deletion'
    )),
    risk_level TEXT DEFAULT 'low' CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
    details JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    location_country TEXT,
    location_city TEXT,
    requires_review BOOLEAN DEFAULT false,
    reviewed_by UUID REFERENCES profiles(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Admin session tracking
CREATE TABLE IF NOT EXISTS admin_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    admin_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    session_token TEXT UNIQUE NOT NULL,
    ip_address INET,
    user_agent TEXT,
    location_country TEXT,
    location_city TEXT,
    permissions_snapshot JSONB,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    ended_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true
);

-- Database change tracking for critical tables
CREATE TABLE IF NOT EXISTS data_change_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    table_name TEXT NOT NULL,
    operation TEXT NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    record_id UUID,
    changed_by UUID REFERENCES profiles(id),
    old_values JSONB,
    new_values JSONB,
    changed_fields TEXT[],
    change_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Automated alert rules
CREATE TABLE IF NOT EXISTS admin_alert_rules (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    rule_type TEXT NOT NULL CHECK (rule_type IN (
        'threshold',
        'pattern',
        'anomaly',
        'time_based',
        'custom'
    )),
    conditions JSONB NOT NULL,
    action_type TEXT NOT NULL CHECK (action_type IN (
        'email',
        'push_notification',
        'slack',
        'webhook',
        'auto_action'
    )),
    action_config JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Alert instances
CREATE TABLE IF NOT EXISTS admin_alerts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    rule_id UUID REFERENCES admin_alert_rules(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    severity TEXT NOT NULL CHECK (severity IN ('info', 'warning', 'error', 'critical')),
    data JSONB DEFAULT '{}',
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'acknowledged', 'resolved', 'dismissed')),
    acknowledged_by UUID REFERENCES profiles(id),
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    resolved_by UUID REFERENCES profiles(id),
    resolved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Performance metrics tracking
CREATE TABLE IF NOT EXISTS performance_metrics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    metric_name TEXT NOT NULL,
    metric_value NUMERIC,
    metric_unit TEXT,
    tags JSONB DEFAULT '{}',
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Backup and maintenance logs
CREATE TABLE IF NOT EXISTS maintenance_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    operation_type TEXT NOT NULL CHECK (operation_type IN (
        'backup',
        'restore',
        'migration',
        'cleanup',
        'index_rebuild',
        'vacuum',
        'update',
        'maintenance'
    )),
    status TEXT NOT NULL CHECK (status IN ('started', 'in_progress', 'completed', 'failed', 'cancelled')),
    details JSONB DEFAULT '{}',
    started_by UUID REFERENCES profiles(id),
    started_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    duration_seconds INTEGER
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_admin_action_logs_admin_id ON admin_action_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_action_logs_action_type ON admin_action_logs(action_type);
CREATE INDEX IF NOT EXISTS idx_admin_action_logs_created_at ON admin_action_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_admin_action_logs_target ON admin_action_logs(target_type, target_id);

CREATE INDEX IF NOT EXISTS idx_system_event_logs_event_type ON system_event_logs(event_type);
CREATE INDEX IF NOT EXISTS idx_system_event_logs_severity ON system_event_logs(severity);
CREATE INDEX IF NOT EXISTS idx_system_event_logs_created_at ON system_event_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_system_event_logs_user_id ON system_event_logs(user_id);

CREATE INDEX IF NOT EXISTS idx_security_logs_user_id ON security_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_security_logs_event_type ON security_logs(event_type);
CREATE INDEX IF NOT EXISTS idx_security_logs_risk_level ON security_logs(risk_level);
CREATE INDEX IF NOT EXISTS idx_security_logs_created_at ON security_logs(created_at);

CREATE INDEX IF NOT EXISTS idx_admin_sessions_admin_id ON admin_sessions(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_sessions_is_active ON admin_sessions(is_active);
CREATE INDEX IF NOT EXISTS idx_admin_sessions_last_activity ON admin_sessions(last_activity_at);

CREATE INDEX IF NOT EXISTS idx_data_change_logs_table_name ON data_change_logs(table_name);
CREATE INDEX IF NOT EXISTS idx_data_change_logs_record_id ON data_change_logs(record_id);
CREATE INDEX IF NOT EXISTS idx_data_change_logs_changed_by ON data_change_logs(changed_by);
CREATE INDEX IF NOT EXISTS idx_data_change_logs_created_at ON data_change_logs(created_at);

CREATE INDEX IF NOT EXISTS idx_admin_alerts_status ON admin_alerts(status);
CREATE INDEX IF NOT EXISTS idx_admin_alerts_severity ON admin_alerts(severity);
CREATE INDEX IF NOT EXISTS idx_admin_alerts_created_at ON admin_alerts(created_at);

CREATE INDEX IF NOT EXISTS idx_performance_metrics_name ON performance_metrics(metric_name);
CREATE INDEX IF NOT EXISTS idx_performance_metrics_recorded_at ON performance_metrics(recorded_at);

-- Enable RLS
ALTER TABLE admin_action_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_event_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE security_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE data_change_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_alert_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE performance_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies (All admin-only)
CREATE POLICY "Admins can view action logs" ON admin_action_logs
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

CREATE POLICY "Admins can view system logs" ON system_event_logs
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

CREATE POLICY "Admins can view security logs" ON security_logs
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

CREATE POLICY "Admins can view admin sessions" ON admin_sessions
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

CREATE POLICY "Admins can view data change logs" ON data_change_logs
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

CREATE POLICY "Admins can manage alert rules" ON admin_alert_rules
    FOR ALL USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

CREATE POLICY "Admins can manage alerts" ON admin_alerts
    FOR ALL USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

CREATE POLICY "Admins can view performance metrics" ON performance_metrics
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

CREATE POLICY "Admins can view maintenance logs" ON maintenance_logs
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

-- Functions

-- Log admin action
CREATE OR REPLACE FUNCTION log_admin_action(
    p_admin_id UUID,
    p_action_type TEXT,
    p_action_category TEXT,
    p_target_type TEXT DEFAULT NULL,
    p_target_id UUID DEFAULT NULL,
    p_target_identifier TEXT DEFAULT NULL,
    p_action_details JSONB DEFAULT '{}',
    p_before_state JSONB DEFAULT NULL,
    p_after_state JSONB DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_success BOOLEAN DEFAULT true,
    p_error_message TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    log_id UUID;
BEGIN
    INSERT INTO admin_action_logs (
        admin_id, action_type, action_category, target_type, target_id,
        target_identifier, action_details, before_state, after_state,
        ip_address, user_agent, success, error_message
    ) VALUES (
        p_admin_id, p_action_type, p_action_category, p_target_type, p_target_id,
        p_target_identifier, p_action_details, p_before_state, p_after_state,
        p_ip_address, p_user_agent, p_success, p_error_message
    ) RETURNING id INTO log_id;
    
    RETURN log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Log system event
CREATE OR REPLACE FUNCTION log_system_event(
    p_event_type TEXT,
    p_event_category TEXT,
    p_severity TEXT DEFAULT 'info',
    p_message TEXT DEFAULT '',
    p_details JSONB DEFAULT '{}',
    p_source TEXT DEFAULT NULL,
    p_user_id UUID DEFAULT NULL,
    p_session_id TEXT DEFAULT NULL,
    p_ip_address INET DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    log_id UUID;
BEGIN
    INSERT INTO system_event_logs (
        event_type, event_category, severity, message, details,
        source, user_id, session_id, ip_address
    ) VALUES (
        p_event_type, p_event_category, p_severity, p_message, p_details,
        p_source, p_user_id, p_session_id, p_ip_address
    ) RETURNING id INTO log_id;
    
    RETURN log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Log security event
CREATE OR REPLACE FUNCTION log_security_event(
    p_user_id UUID,
    p_event_type TEXT,
    p_risk_level TEXT DEFAULT 'low',
    p_details JSONB DEFAULT '{}',
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_location_country TEXT DEFAULT NULL,
    p_location_city TEXT DEFAULT NULL,
    p_requires_review BOOLEAN DEFAULT false
)
RETURNS UUID AS $$
DECLARE
    log_id UUID;
BEGIN
    INSERT INTO security_logs (
        user_id, event_type, risk_level, details, ip_address,
        user_agent, location_country, location_city, requires_review
    ) VALUES (
        p_user_id, p_event_type, p_risk_level, p_details, p_ip_address,
        p_user_agent, p_location_country, p_location_city, p_requires_review
    ) RETURNING id INTO log_id;
    
    -- Check if this should trigger an alert
    IF p_risk_level IN ('high', 'critical') OR p_requires_review THEN
        INSERT INTO admin_alerts (title, message, severity, data)
        VALUES (
            'Security Event: ' || p_event_type,
            'High-risk security event detected for user ' || COALESCE(p_user_id::text, 'unknown'),
            CASE WHEN p_risk_level = 'critical' THEN 'critical' ELSE 'warning' END,
            jsonb_build_object('security_log_id', log_id, 'user_id', p_user_id, 'event_type', p_event_type)
        );
    END IF;
    
    RETURN log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Clean old logs
CREATE OR REPLACE FUNCTION cleanup_old_logs()
RETURNS VOID AS $$
BEGIN
    -- Keep logs for different periods based on type
    DELETE FROM admin_action_logs WHERE created_at < NOW() - INTERVAL '2 years';
    DELETE FROM system_event_logs WHERE created_at < NOW() - INTERVAL '1 year' AND severity NOT IN ('error', 'critical');
    DELETE FROM security_logs WHERE created_at < NOW() - INTERVAL '3 years';
    DELETE FROM performance_metrics WHERE recorded_at < NOW() - INTERVAL '6 months';
    DELETE FROM data_change_logs WHERE created_at < NOW() - INTERVAL '1 year';
    
    -- Keep critical events longer
    DELETE FROM system_event_logs WHERE created_at < NOW() - INTERVAL '3 years' AND severity IN ('error', 'critical');
END;
$$ LANGUAGE plpgsql;

-- Get admin dashboard summary
CREATE OR REPLACE FUNCTION get_admin_dashboard_summary()
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'active_alerts', (SELECT COUNT(*) FROM admin_alerts WHERE status = 'active'),
        'pending_reports', (SELECT COUNT(*) FROM user_reports WHERE status = 'pending'),
        'open_support_requests', (SELECT COUNT(*) FROM support_requests WHERE status IN ('open', 'in_progress')),
        'recent_security_events', (SELECT COUNT(*) FROM security_logs WHERE created_at > NOW() - INTERVAL '24 hours' AND risk_level IN ('high', 'critical')),
        'system_errors_today', (SELECT COUNT(*) FROM system_event_logs WHERE created_at > NOW() - INTERVAL '24 hours' AND severity IN ('error', 'critical')),
        'active_admin_sessions', (SELECT COUNT(*) FROM admin_sessions WHERE is_active = true AND last_activity_at > NOW() - INTERVAL '30 minutes')
    ) INTO result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
