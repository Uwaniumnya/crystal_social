-- Crystal Social Services System - Security and Policies
-- File: 04_services_security.sql
-- Purpose: Row Level Security policies and security configurations

-- =============================================================================
-- ENABLE ROW LEVEL SECURITY
-- =============================================================================

-- Enable RLS on all service tables
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_user_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_device_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE glimmer_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE glimmer_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE glimmer_post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE glimmer_post_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_configurations ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_health_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_operation_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_service_analytics ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- USER DEVICES POLICIES
-- =============================================================================

-- Users can only view and manage their own devices
CREATE POLICY "Users can view their own devices" ON user_devices
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own devices" ON user_devices
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own devices" ON user_devices
    FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own devices" ON user_devices
    FOR DELETE USING (user_id = auth.uid());

-- Service role can manage all devices for system operations
CREATE POLICY "Service role can manage all devices" ON user_devices
    FOR ALL USING (auth.role() = 'service_role');

-- =============================================================================
-- DEVICE USER HISTORY POLICIES
-- =============================================================================

-- Users can view their own device history
CREATE POLICY "Users can view their own device history" ON device_user_history
    FOR SELECT USING (user_id = auth.uid());

-- Only service role can insert/update device history (system managed)
CREATE POLICY "Service role can manage device history" ON device_user_history
    FOR ALL USING (auth.role() = 'service_role');

-- =============================================================================
-- NOTIFICATION POLICIES
-- =============================================================================

-- Notification types - read-only for authenticated users
CREATE POLICY "Authenticated users can view notification types" ON notification_types
    FOR SELECT USING (auth.role() = 'authenticated');

-- Only service role can manage notification types
CREATE POLICY "Service role can manage notification types" ON notification_types
    FOR ALL USING (auth.role() = 'service_role');

-- Notification templates - read-only for authenticated users
CREATE POLICY "Authenticated users can view notification templates" ON notification_templates
    FOR SELECT USING (auth.role() = 'authenticated');

-- Only service role can manage notification templates
CREATE POLICY "Service role can manage notification templates" ON notification_templates
    FOR ALL USING (auth.role() = 'service_role');

-- Notification logs - users can view notifications they received or sent
CREATE POLICY "Users can view their notification logs" ON notification_logs
    FOR SELECT USING (
        receiver_user_id = auth.uid() OR 
        sender_user_id = auth.uid()
    );

-- Only service role can insert/update notification logs
CREATE POLICY "Service role can manage notification logs" ON notification_logs
    FOR ALL USING (auth.role() = 'service_role');

-- Notification device logs - only service role access
CREATE POLICY "Service role can manage notification device logs" ON notification_device_logs
    FOR ALL USING (auth.role() = 'service_role');

-- =============================================================================
-- GLIMMER POSTS POLICIES
-- =============================================================================

-- Glimmer categories - read-only for authenticated users
CREATE POLICY "Authenticated users can view glimmer categories" ON glimmer_categories
    FOR SELECT USING (auth.role() = 'authenticated');

-- Only service role can manage glimmer categories
CREATE POLICY "Service role can manage glimmer categories" ON glimmer_categories
    FOR ALL USING (auth.role() = 'service_role');

-- Glimmer posts - users can view published posts, manage their own posts
CREATE POLICY "Users can view published glimmer posts" ON glimmer_posts
    FOR SELECT USING (
        is_published = true AND is_approved = true
        OR user_id = auth.uid()
    );

CREATE POLICY "Users can insert their own glimmer posts" ON glimmer_posts
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own glimmer posts" ON glimmer_posts
    FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own glimmer posts" ON glimmer_posts
    FOR DELETE USING (user_id = auth.uid());

-- Service role can manage all glimmer posts for moderation
CREATE POLICY "Service role can manage all glimmer posts" ON glimmer_posts
    FOR ALL USING (auth.role() = 'service_role');

-- Glimmer post likes - users can view all likes, manage their own likes
CREATE POLICY "Users can view glimmer post likes" ON glimmer_post_likes
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can manage their own glimmer post likes" ON glimmer_post_likes
    FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Glimmer post comments - users can view approved comments, manage their own comments
CREATE POLICY "Users can view approved glimmer post comments" ON glimmer_post_comments
    FOR SELECT USING (
        is_approved = true 
        OR user_id = auth.uid()
    );

CREATE POLICY "Users can insert their own glimmer post comments" ON glimmer_post_comments
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own glimmer post comments" ON glimmer_post_comments
    FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own glimmer post comments" ON glimmer_post_comments
    FOR DELETE USING (user_id = auth.uid());

-- Service role can manage all comments for moderation
CREATE POLICY "Service role can manage all glimmer post comments" ON glimmer_post_comments
    FOR ALL USING (auth.role() = 'service_role');

-- =============================================================================
-- SERVICE CONFIGURATION POLICIES
-- =============================================================================

-- Service configurations - read-only for authenticated users (non-sensitive only)
CREATE POLICY "Users can view non-sensitive service configurations" ON service_configurations
    FOR SELECT USING (
        auth.role() = 'authenticated' 
        AND is_sensitive = false
    );

-- Service role can manage all service configurations
CREATE POLICY "Service role can manage all service configurations" ON service_configurations
    FOR ALL USING (auth.role() = 'service_role');

-- =============================================================================
-- ANALYTICS AND MONITORING POLICIES
-- =============================================================================

-- Service health checks - only service role access
CREATE POLICY "Service role can manage service health checks" ON service_health_checks
    FOR ALL USING (auth.role() = 'service_role');

-- Service operation logs - users can view their own operation logs
CREATE POLICY "Users can view their own service operation logs" ON service_operation_logs
    FOR SELECT USING (user_id = auth.uid());

-- Service role can manage all operation logs
CREATE POLICY "Service role can manage all service operation logs" ON service_operation_logs
    FOR ALL USING (auth.role() = 'service_role');

-- Daily service analytics - only service role access
CREATE POLICY "Service role can manage daily service analytics" ON daily_service_analytics
    FOR ALL USING (auth.role() = 'service_role');

-- =============================================================================
-- SECURITY FUNCTIONS
-- =============================================================================

-- Function to check if user is admin or service role
CREATE OR REPLACE FUNCTION is_admin_or_service()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN auth.role() = 'service_role' OR 
           EXISTS (
               SELECT 1 FROM profiles 
               WHERE user_id = auth.uid() 
               AND role = 'admin'
           );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user can access another user's data
CREATE OR REPLACE FUNCTION can_access_user_data(target_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- Users can access their own data
    IF target_user_id = auth.uid() THEN
        RETURN true;
    END IF;
    
    -- Service role can access any data
    IF auth.role() = 'service_role' THEN
        RETURN true;
    END IF;
    
    -- Admins can access any data
    IF EXISTS (
        SELECT 1 FROM profiles 
        WHERE user_id = auth.uid() 
        AND role = 'admin'
    ) THEN
        RETURN true;
    END IF;
    
    RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to validate notification access
CREATE OR REPLACE FUNCTION can_access_notification(
    p_receiver_user_id UUID,
    p_sender_user_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Service role can access all notifications
    IF auth.role() = 'service_role' THEN
        RETURN true;
    END IF;
    
    -- Users can access notifications they received or sent
    IF p_receiver_user_id = auth.uid() OR p_sender_user_id = auth.uid() THEN
        RETURN true;
    END IF;
    
    -- Admins can access all notifications
    IF is_admin_or_service() THEN
        RETURN true;
    END IF;
    
    RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- AUDIT LOGGING TRIGGERS
-- =============================================================================

-- Create audit log table for sensitive operations
CREATE TABLE service_audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name VARCHAR(100) NOT NULL,
    operation VARCHAR(20) NOT NULL, -- INSERT, UPDATE, DELETE
    user_id UUID REFERENCES auth.users(id),
    user_role VARCHAR(50),
    old_values JSONB,
    new_values JSONB,
    changed_columns TEXT[],
    client_info JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on audit logs
ALTER TABLE service_audit_logs ENABLE ROW LEVEL SECURITY;

-- Only service role and admins can view audit logs
CREATE POLICY "Admins and service role can view audit logs" ON service_audit_logs
    FOR SELECT USING (is_admin_or_service());

-- Only service role can insert audit logs
CREATE POLICY "Service role can insert audit logs" ON service_audit_logs
    FOR INSERT WITH CHECK (auth.role() = 'service_role');

-- Audit trigger function
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
DECLARE
    v_old_data JSONB := NULL;
    v_new_data JSONB := NULL;
    v_changed_columns TEXT[] := ARRAY[]::TEXT[];
    v_column_name TEXT;
BEGIN
    -- Capture old and new data
    IF TG_OP = 'DELETE' THEN
        v_old_data := to_jsonb(OLD);
    ELSIF TG_OP = 'UPDATE' THEN
        v_old_data := to_jsonb(OLD);
        v_new_data := to_jsonb(NEW);
        
        -- Identify changed columns
        FOR v_column_name IN SELECT jsonb_object_keys(v_new_data)
        LOOP
            IF v_old_data->>v_column_name IS DISTINCT FROM v_new_data->>v_column_name THEN
                v_changed_columns := array_append(v_changed_columns, v_column_name);
            END IF;
        END LOOP;
    ELSIF TG_OP = 'INSERT' THEN
        v_new_data := to_jsonb(NEW);
    END IF;
    
    -- Insert audit record
    INSERT INTO service_audit_logs (
        table_name, operation, user_id, user_role,
        old_values, new_values, changed_columns, created_at
    ) VALUES (
        TG_TABLE_NAME, TG_OP, auth.uid(), auth.role(),
        v_old_data, v_new_data, v_changed_columns, NOW()
    );
    
    -- Return appropriate record
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply audit triggers to sensitive tables
CREATE TRIGGER audit_user_devices_trigger
    AFTER INSERT OR UPDATE OR DELETE ON user_devices
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_notification_logs_trigger
    AFTER INSERT OR UPDATE OR DELETE ON notification_logs
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_service_configurations_trigger
    AFTER INSERT OR UPDATE OR DELETE ON service_configurations
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_glimmer_posts_trigger
    AFTER INSERT OR UPDATE OR DELETE ON glimmer_posts
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- =============================================================================
-- SECURITY VALIDATION FUNCTIONS
-- =============================================================================

-- Function to validate service security configuration
CREATE OR REPLACE FUNCTION validate_service_security()
RETURNS JSON AS $$
DECLARE
    v_rls_enabled_count INTEGER;
    v_total_tables INTEGER;
    v_policy_count INTEGER;
    v_audit_trigger_count INTEGER;
    v_result JSON;
    v_warnings TEXT[] := ARRAY[]::TEXT[];
    v_errors TEXT[] := ARRAY[]::TEXT[];
BEGIN
    -- Check RLS is enabled on all service tables
    SELECT COUNT(*) INTO v_rls_enabled_count
    FROM pg_class c
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE n.nspname = 'public'
    AND c.relname IN (
        'user_devices', 'device_user_history', 'notification_types', 'notification_templates',
        'notification_logs', 'notification_device_logs', 'glimmer_categories', 'glimmer_posts',
        'glimmer_post_likes', 'glimmer_post_comments', 'service_configurations',
        'service_health_checks', 'service_operation_logs', 'daily_service_analytics'
    )
    AND c.relrowsecurity = true;
    
    SELECT COUNT(*) INTO v_total_tables
    FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name IN (
        'user_devices', 'device_user_history', 'notification_types', 'notification_templates',
        'notification_logs', 'notification_device_logs', 'glimmer_categories', 'glimmer_posts',
        'glimmer_post_likes', 'glimmer_post_comments', 'service_configurations',
        'service_health_checks', 'service_operation_logs', 'daily_service_analytics'
    );
    
    -- Check policy count
    SELECT COUNT(*) INTO v_policy_count
    FROM pg_policies
    WHERE schemaname = 'public'
    AND tablename IN (
        'user_devices', 'device_user_history', 'notification_types', 'notification_templates',
        'notification_logs', 'notification_device_logs', 'glimmer_categories', 'glimmer_posts',
        'glimmer_post_likes', 'glimmer_post_comments', 'service_configurations',
        'service_health_checks', 'service_operation_logs', 'daily_service_analytics'
    );
    
    -- Check audit triggers
    SELECT COUNT(*) INTO v_audit_trigger_count
    FROM information_schema.triggers
    WHERE trigger_schema = 'public'
    AND trigger_name LIKE '%audit%';
    
    -- Generate warnings and errors
    IF v_rls_enabled_count < v_total_tables THEN
        v_errors := array_append(v_errors, 
            'RLS not enabled on all service tables: ' || v_rls_enabled_count || '/' || v_total_tables
        );
    END IF;
    
    IF v_policy_count < 20 THEN
        v_warnings := array_append(v_warnings, 
            'Low policy count detected: ' || v_policy_count || ' policies found'
        );
    END IF;
    
    IF v_audit_trigger_count < 4 THEN
        v_warnings := array_append(v_warnings, 
            'Missing audit triggers: ' || v_audit_trigger_count || ' triggers found'
        );
    END IF;
    
    v_result := json_build_object(
        'security_status', CASE WHEN array_length(v_errors, 1) IS NULL THEN 'secure' ELSE 'insecure' END,
        'rls_enabled_tables', v_rls_enabled_count,
        'total_service_tables', v_total_tables,
        'total_policies', v_policy_count,
        'audit_triggers', v_audit_trigger_count,
        'warnings', v_warnings,
        'errors', v_errors,
        'validation_timestamp', NOW()
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- GRANT PERMISSIONS FOR SECURITY FUNCTIONS
-- =============================================================================

GRANT EXECUTE ON FUNCTION is_admin_or_service() TO authenticated;
GRANT EXECUTE ON FUNCTION can_access_user_data(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION can_access_notification(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION validate_service_security() TO service_role;

-- =============================================================================
-- SECURITY INDEXES
-- =============================================================================

-- Indexes for audit logs
CREATE INDEX idx_service_audit_logs_table_operation ON service_audit_logs(table_name, operation);
CREATE INDEX idx_service_audit_logs_user ON service_audit_logs(user_id, created_at DESC);
CREATE INDEX idx_service_audit_logs_timestamp ON service_audit_logs(created_at DESC);

-- =============================================================================
-- SECURITY DOCUMENTATION
-- =============================================================================

COMMENT ON FUNCTION is_admin_or_service() IS 'Check if current user is admin or service role';
COMMENT ON FUNCTION can_access_user_data(UUID) IS 'Check if current user can access another users data';
COMMENT ON FUNCTION can_access_notification(UUID, UUID) IS 'Validate notification access permissions';
COMMENT ON FUNCTION validate_service_security() IS 'Comprehensive security validation for all service tables';
COMMENT ON FUNCTION audit_trigger_function() IS 'Audit trigger function to log all changes to sensitive tables';
COMMENT ON TABLE service_audit_logs IS 'Audit trail for all sensitive service operations';

-- =============================================================================
-- SECURITY VALIDATION REPORT
-- =============================================================================

-- Run initial security validation
SELECT validate_service_security() as security_validation_report;
