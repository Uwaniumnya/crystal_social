-- Crystal Social Main Application System - Security Policies
-- File: 04_main_app_security_policies.sql
-- Purpose: Row Level Security policies for main application system data protection

-- =============================================================================
-- ENABLE ROW LEVEL SECURITY
-- =============================================================================

-- Enable RLS on all main app tables
ALTER TABLE app_states ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_configurations ENABLE ROW LEVEL SECURITY;
ALTER TABLE connectivity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_lifecycle_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE multi_user_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_user_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_initialization_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE fronting_changes ENABLE ROW LEVEL SECURITY;
ALTER TABLE background_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_notification_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE error_reports ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- APP STATE SECURITY POLICIES
-- =============================================================================

-- Users can only access their own app states
CREATE POLICY "Users can access own app states"
ON app_states FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- System can access all app states for monitoring
CREATE POLICY "System can access all app states"
ON app_states FOR ALL
USING (auth.role() = 'service_role');

-- =============================================================================
-- APP CONFIGURATION SECURITY POLICIES
-- =============================================================================

-- Users can read user-configurable settings
CREATE POLICY "Users can read user-configurable settings"
ON app_configurations FOR SELECT
USING (is_user_configurable = true);

-- Users can update their own configurable settings
CREATE POLICY "Users can update user-configurable settings"
ON app_configurations FOR UPDATE
USING (
    is_user_configurable = true 
    AND auth.uid() IS NOT NULL
)
WITH CHECK (
    is_user_configurable = true 
    AND auth.uid() IS NOT NULL
);

-- Admins can manage all configurations
CREATE POLICY "Admins can manage all configurations"
ON app_configurations FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND raw_user_meta_data->>'role' = 'admin'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND raw_user_meta_data->>'role' = 'admin'
    )
);

-- System can read all configurations
CREATE POLICY "System can read all configurations"
ON app_configurations FOR SELECT
USING (auth.role() = 'service_role');

-- =============================================================================
-- CONNECTIVITY LOGS SECURITY POLICIES
-- =============================================================================

-- Users can access their own connectivity logs
CREATE POLICY "Users can access own connectivity logs"
ON connectivity_logs FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- System can access all connectivity logs
CREATE POLICY "System can access all connectivity logs"
ON connectivity_logs FOR ALL
USING (auth.role() = 'service_role');

-- =============================================================================
-- APP LIFECYCLE EVENTS SECURITY POLICIES
-- =============================================================================

-- Users can access their own lifecycle events
CREATE POLICY "Users can access own lifecycle events"
ON app_lifecycle_events FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- System can access all lifecycle events
CREATE POLICY "System can access all lifecycle events"
ON app_lifecycle_events FOR ALL
USING (auth.role() = 'service_role');

-- =============================================================================
-- USER SESSIONS SECURITY POLICIES
-- =============================================================================

-- Users can access their own sessions
CREATE POLICY "Users can access own sessions"
ON user_sessions FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- System can access all sessions for management
CREATE POLICY "System can access all sessions"
ON user_sessions FOR ALL
USING (auth.role() = 'service_role');

-- =============================================================================
-- USER DEVICES SECURITY POLICIES
-- =============================================================================

-- Users can access their own devices
CREATE POLICY "Users can access own devices"
ON user_devices FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- System can access all devices for management
CREATE POLICY "System can access all devices"
ON user_devices FOR ALL
USING (auth.role() = 'service_role');

-- Admins can view device information for support
CREATE POLICY "Admins can view device information"
ON user_devices FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND raw_user_meta_data->>'role' IN ('admin', 'support')
    )
);

-- =============================================================================
-- MULTI-USER DEVICE SECURITY POLICIES
-- =============================================================================

-- System manages multi-user device tracking
CREATE POLICY "System manages multi-user devices"
ON multi_user_devices FOR ALL
USING (auth.role() = 'service_role');

-- Users can read multi-user device status for their devices
CREATE POLICY "Users can read own device multi-user status"
ON multi_user_devices FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM user_devices 
        WHERE device_id = multi_user_devices.device_id 
        AND user_id = auth.uid()
    )
);

-- Admins can view all multi-user device data
CREATE POLICY "Admins can view multi-user device data"
ON multi_user_devices FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND raw_user_meta_data->>'role' = 'admin'
    )
);

-- =============================================================================
-- DEVICE USER HISTORY SECURITY POLICIES
-- =============================================================================

-- Users can access their own device history
CREATE POLICY "Users can access own device history"
ON device_user_history FOR SELECT
USING (auth.uid() = user_id);

-- System can manage all device history
CREATE POLICY "System can manage device history"
ON device_user_history FOR ALL
USING (auth.role() = 'service_role');

-- Users can insert their own device history
CREATE POLICY "Users can insert own device history"
ON device_user_history FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Admins can view device history for security auditing
CREATE POLICY "Admins can view device history"
ON device_user_history FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND raw_user_meta_data->>'role' IN ('admin', 'security')
    )
);

-- =============================================================================
-- APP INITIALIZATION LOGS SECURITY POLICIES
-- =============================================================================

-- Users can access their own initialization logs
CREATE POLICY "Users can access own initialization logs"
ON app_initialization_logs FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- System can access all initialization logs
CREATE POLICY "System can access all initialization logs"
ON app_initialization_logs FOR ALL
USING (auth.role() = 'service_role');

-- Developers can read initialization logs for debugging
CREATE POLICY "Developers can read initialization logs"
ON app_initialization_logs FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND raw_user_meta_data->>'role' IN ('admin', 'developer')
    )
);

-- =============================================================================
-- FRONTING CHANGES SECURITY POLICIES
-- =============================================================================

-- Users can access their own fronting changes
CREATE POLICY "Users can access own fronting changes"
ON fronting_changes FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- System can access all fronting changes for notifications
CREATE POLICY "System can access all fronting changes"
ON fronting_changes FOR ALL
USING (auth.role() = 'service_role');

-- Trusted contacts can view fronting changes (if implemented)
CREATE POLICY "Trusted contacts can view fronting changes"
ON fronting_changes FOR SELECT
USING (
    auth.uid() = ANY(notification_recipients)
    OR EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND raw_user_meta_data->>'role' IN ('admin', 'support')
    )
);

-- =============================================================================
-- BACKGROUND MESSAGES SECURITY POLICIES
-- =============================================================================

-- Users can access their own background messages
CREATE POLICY "Users can access own background messages"
ON background_messages FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- System can access all background messages for processing
CREATE POLICY "System can access all background messages"
ON background_messages FOR ALL
USING (auth.role() = 'service_role');

-- =============================================================================
-- PUSH NOTIFICATION ANALYTICS SECURITY POLICIES
-- =============================================================================

-- Users can access their own notification analytics
CREATE POLICY "Users can access own notification analytics"
ON push_notification_analytics FOR SELECT
USING (auth.uid() = user_id);

-- System can manage all notification analytics
CREATE POLICY "System can manage notification analytics"
ON push_notification_analytics FOR ALL
USING (auth.role() = 'service_role');

-- Marketing team can read notification analytics for campaigns
CREATE POLICY "Marketing can read notification analytics"
ON push_notification_analytics FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND raw_user_meta_data->>'role' IN ('admin', 'marketing', 'analyst')
    )
);

-- =============================================================================
-- ERROR REPORTS SECURITY POLICIES
-- =============================================================================

-- Users can access their own error reports
CREATE POLICY "Users can access own error reports"
ON error_reports FOR SELECT
USING (auth.uid() = user_id);

-- Users can create error reports
CREATE POLICY "Users can create error reports"
ON error_reports FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- System can manage all error reports
CREATE POLICY "System can manage all error reports"
ON error_reports FOR ALL
USING (auth.role() = 'service_role');

-- Developers and support can access error reports for resolution
CREATE POLICY "Developers can access error reports"
ON error_reports FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND raw_user_meta_data->>'role' IN ('admin', 'developer', 'support')
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND raw_user_meta_data->>'role' IN ('admin', 'developer', 'support')
    )
);

-- =============================================================================
-- ADVANCED SECURITY FUNCTIONS
-- =============================================================================

-- Rate limiting function for API calls
CREATE OR REPLACE FUNCTION check_api_rate_limit(
    p_user_id UUID,
    p_action_type TEXT,
    p_time_window INTERVAL DEFAULT INTERVAL '1 hour',
    p_max_requests INTEGER DEFAULT 1000
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    request_count INTEGER;
BEGIN
    -- Count recent requests (using lifecycle events as proxy)
    SELECT COUNT(*) INTO request_count
    FROM app_lifecycle_events
    WHERE user_id = p_user_id
    AND event_type = p_action_type
    AND event_timestamp >= NOW() - p_time_window;
    
    -- Return true if under limit
    RETURN request_count < p_max_requests;
END;
$$;

-- Device security validation
CREATE OR REPLACE FUNCTION validate_device_security(
    p_device_id TEXT,
    p_user_id UUID,
    p_device_fingerprint TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    device_record RECORD;
    security_result JSON;
    is_trusted BOOLEAN := false;
    risk_score INTEGER := 0;
    risk_factors TEXT[] := '{}';
BEGIN
    -- Get device information
    SELECT * INTO device_record
    FROM user_devices
    WHERE device_id = p_device_id AND user_id = p_user_id;
    
    IF NOT FOUND THEN
        risk_score := risk_score + 50;
        risk_factors := array_append(risk_factors, 'unknown_device');
    ELSE
        is_trusted := device_record.is_trusted;
        
        -- Check for security violations
        IF device_record.security_violations > 0 THEN
            risk_score := risk_score + (device_record.security_violations * 10);
            risk_factors := array_append(risk_factors, 'previous_violations');
        END IF;
        
        -- Check device fingerprint consistency
        IF p_device_fingerprint IS NOT NULL 
           AND device_record.device_fingerprint IS NOT NULL 
           AND p_device_fingerprint != device_record.device_fingerprint THEN
            risk_score := risk_score + 30;
            risk_factors := array_append(risk_factors, 'fingerprint_mismatch');
        END IF;
        
        -- Check if device is used by multiple users
        IF EXISTS (
            SELECT 1 FROM multi_user_devices 
            WHERE device_id = p_device_id 
            AND is_shared_device = true
        ) THEN
            risk_score := risk_score + 20;
            risk_factors := array_append(risk_factors, 'shared_device');
        END IF;
    END IF;
    
    -- Check for recent suspicious activity
    IF EXISTS (
        SELECT 1 FROM error_reports 
        WHERE device_id = p_device_id 
        AND error_type = 'security'
        AND created_at >= NOW() - INTERVAL '24 hours'
    ) THEN
        risk_score := risk_score + 25;
        risk_factors := array_append(risk_factors, 'recent_security_errors');
    END IF;
    
    security_result := json_build_object(
        'is_trusted', is_trusted,
        'risk_score', LEAST(risk_score, 100),
        'risk_level', CASE 
            WHEN risk_score <= 20 THEN 'low'
            WHEN risk_score <= 50 THEN 'medium'
            WHEN risk_score <= 80 THEN 'high'
            ELSE 'critical'
        END,
        'risk_factors', risk_factors,
        'requires_additional_auth', risk_score > 50,
        'allow_access', risk_score < 80
    );
    
    RETURN security_result;
END;
$$;

-- Session security validation
CREATE OR REPLACE FUNCTION validate_session_security(
    p_user_id UUID,
    p_device_id TEXT,
    p_session_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    session_record RECORD;
    is_valid BOOLEAN := false;
BEGIN
    -- Get session information
    SELECT * INTO session_record
    FROM user_sessions
    WHERE id = p_session_id
    AND user_id = p_user_id
    AND device_id = p_device_id
    AND is_active = true;
    
    IF FOUND THEN
        -- Check if session is within timeout
        IF session_record.last_activity >= NOW() - 
           (session_record.inactivity_timeout_minutes || ' minutes')::INTERVAL THEN
            is_valid := true;
            
            -- Update last activity
            UPDATE user_sessions SET
                last_activity = NOW(),
                updated_at = NOW()
            WHERE id = p_session_id;
        ELSE
            -- Session expired, deactivate it
            UPDATE user_sessions SET
                is_active = false,
                session_end = NOW(),
                force_logout_reason = 'session_timeout',
                updated_at = NOW()
            WHERE id = p_session_id;
        END IF;
    END IF;
    
    RETURN is_valid;
END;
$$;

-- Log security event
-- Drop all possible variations of log_security_event function
DO $$ 
BEGIN
    -- Drop any existing log_security_event functions with different signatures
    DROP FUNCTION IF EXISTS log_security_event(UUID, TEXT, TEXT, TEXT, JSONB) CASCADE;
    DROP FUNCTION IF EXISTS log_security_event(UUID, VARCHAR, JSONB) CASCADE;
    DROP FUNCTION IF EXISTS log_security_event(UUID, VARCHAR, JSONB, INET, TEXT) CASCADE;
    DROP FUNCTION IF EXISTS log_security_event(UUID, TEXT, JSONB) CASCADE;
    DROP FUNCTION IF EXISTS log_security_event CASCADE;
EXCEPTION WHEN OTHERS THEN
    -- Ignore any errors during cleanup
    NULL;
END $$;

CREATE OR REPLACE FUNCTION log_main_app_security_event(
    p_user_id UUID,
    p_device_id TEXT,
    p_event_type TEXT,
    p_severity TEXT DEFAULT 'warning',
    p_details JSONB DEFAULT '{}'
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Log as error report
    INSERT INTO error_reports (
        user_id, device_id, error_type, error_message, severity_level,
        context_description, metadata, is_fatal
    ) VALUES (
        p_user_id, p_device_id, 'security', 
        'Security event: ' || p_event_type,
        p_severity, 'Security monitoring',
        p_details, false
    );
    
    -- Update device security violations if this is a violation
    IF p_severity IN ('error', 'critical') THEN
        UPDATE user_devices SET
            security_violations = security_violations + 1,
            updated_at = NOW()
        WHERE user_id = p_user_id AND device_id = p_device_id;
    END IF;
END;
$$;

-- =============================================================================
-- PRIVACY AND DATA PROTECTION
-- =============================================================================

-- Anonymize user data for analytics
CREATE OR REPLACE FUNCTION anonymize_user_data(
    p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    anonymous_id UUID := gen_random_uuid();
BEGIN
    -- This function would be used for GDPR compliance
    -- Update records to remove personally identifiable information
    
    -- Update app states
    UPDATE app_states SET
        user_preferences = '{}',
        last_error = NULL
    WHERE user_id = p_user_id;
    
    -- Update error reports
    UPDATE error_reports SET
        user_action = 'anonymized',
        screen_name = 'anonymized'
    WHERE user_id = p_user_id;
    
    -- Note: This is a simplified example
    -- In practice, you'd need to carefully consider what data to anonymize
    -- and what to delete based on your privacy policy and legal requirements
    
    RETURN true;
END;
$$;

-- Delete user data (GDPR right to be forgotten)
CREATE OR REPLACE FUNCTION delete_user_data(
    p_user_id UUID,
    p_keep_anonymous_analytics BOOLEAN DEFAULT true
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Only allow users to delete their own data or admins
    IF auth.uid() != p_user_id AND NOT EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND raw_user_meta_data->>'role' = 'admin'
    ) THEN
        RAISE EXCEPTION 'Unauthorized to delete user data';
    END IF;
    
    IF p_keep_anonymous_analytics THEN
        -- Anonymize instead of delete
        PERFORM anonymize_user_data(p_user_id);
    ELSE
        -- Complete deletion
        DELETE FROM app_states WHERE user_id = p_user_id;
        DELETE FROM connectivity_logs WHERE user_id = p_user_id;
        DELETE FROM app_lifecycle_events WHERE user_id = p_user_id;
        DELETE FROM user_sessions WHERE user_id = p_user_id;
        DELETE FROM user_devices WHERE user_id = p_user_id;
        DELETE FROM device_user_history WHERE user_id = p_user_id;
        DELETE FROM app_initialization_logs WHERE user_id = p_user_id;
        DELETE FROM fronting_changes WHERE user_id = p_user_id;
        DELETE FROM background_messages WHERE user_id = p_user_id;
        DELETE FROM push_notification_analytics WHERE user_id = p_user_id;
        DELETE FROM error_reports WHERE user_id = p_user_id;
    END IF;
    
    RETURN true;
END;
$$;

-- =============================================================================
-- AUDIT AND COMPLIANCE
-- =============================================================================

-- Create audit log table for sensitive operations
CREATE TABLE IF NOT EXISTS security_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    action TEXT NOT NULL,
    target_table TEXT,
    target_id TEXT,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    session_id UUID,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on audit log
ALTER TABLE security_audit_log ENABLE ROW LEVEL SECURITY;

-- Only admins can read audit logs
CREATE POLICY "Admins can read audit logs"
ON security_audit_log FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND raw_user_meta_data->>'role' = 'admin'
    )
);

-- System can write audit logs
CREATE POLICY "System can write audit logs"
ON security_audit_log FOR INSERT
WITH CHECK (auth.role() = 'service_role');

-- =============================================================================
-- GRANT PERMISSIONS FOR SECURITY FUNCTIONS
-- =============================================================================

GRANT EXECUTE ON FUNCTION check_api_rate_limit TO authenticated;
GRANT EXECUTE ON FUNCTION validate_device_security TO authenticated;
GRANT EXECUTE ON FUNCTION validate_session_security TO authenticated;
GRANT EXECUTE ON FUNCTION log_main_app_security_event TO authenticated;
GRANT EXECUTE ON FUNCTION delete_user_data TO authenticated;

-- Admin-only functions
GRANT EXECUTE ON FUNCTION anonymize_user_data TO service_role;

-- =============================================================================
-- SECURITY MONITORING TRIGGERS
-- =============================================================================

-- Function to detect suspicious login patterns
CREATE OR REPLACE FUNCTION detect_suspicious_login()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    recent_logins INTEGER;
    different_locations INTEGER;
BEGIN
    -- Count recent logins from this user
    SELECT COUNT(*) INTO recent_logins
    FROM device_user_history
    WHERE user_id = NEW.user_id
    AND login_timestamp >= NOW() - INTERVAL '1 hour';
    
    -- Count different approximate locations
    SELECT COUNT(DISTINCT location_approximate) INTO different_locations
    FROM device_user_history
    WHERE user_id = NEW.user_id
    AND login_timestamp >= NOW() - INTERVAL '24 hours'
    AND location_approximate IS NOT NULL;
    
    -- Flag suspicious activity
    IF recent_logins > 5 THEN
        PERFORM log_main_app_security_event(
            NEW.user_id, NEW.device_id, 'rapid_logins',
            'warning', 
            jsonb_build_object('login_count', recent_logins, 'time_window', '1 hour')
        );
    END IF;
    
    IF different_locations > 3 THEN
        PERFORM log_main_app_security_event(
            NEW.user_id, NEW.device_id, 'multiple_locations',
            'warning',
            jsonb_build_object('location_count', different_locations, 'time_window', '24 hours')
        );
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger for suspicious login detection
CREATE TRIGGER detect_suspicious_login_trigger
    AFTER INSERT ON device_user_history
    FOR EACH ROW
    EXECUTE FUNCTION detect_suspicious_login();

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON FUNCTION check_api_rate_limit IS 'Check if user is within API rate limits';
COMMENT ON FUNCTION validate_device_security IS 'Validate device security and calculate risk score';
COMMENT ON FUNCTION validate_session_security IS 'Validate session security and handle timeouts';
COMMENT ON FUNCTION log_main_app_security_event IS 'Log security events for monitoring and auditing';
COMMENT ON FUNCTION delete_user_data IS 'Delete or anonymize user data for GDPR compliance';
COMMENT ON TABLE security_audit_log IS 'Audit log for sensitive security operations';

-- Setup completion message
SELECT 'Main App Security Policies Setup Complete!' as status, NOW() as setup_completed_at;
