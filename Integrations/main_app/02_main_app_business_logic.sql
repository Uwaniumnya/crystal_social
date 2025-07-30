-- Crystal Social Main Application System - Business Logic Functions
-- File: 02_main_app_business_logic.sql
-- Purpose: Core business logic functions for main application system management

-- =============================================================================
-- APP STATE MANAGEMENT FUNCTIONS
-- =============================================================================

-- Initialize or update app state for user session
CREATE OR REPLACE FUNCTION initialize_app_state(
    p_user_id UUID,
    p_device_id TEXT,
    p_app_version TEXT DEFAULT NULL,
    p_platform TEXT DEFAULT NULL,
    p_device_info JSONB DEFAULT '{}'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_session_id UUID;
    v_app_state_id UUID;
BEGIN
    -- Generate new session ID
    v_session_id := gen_random_uuid();
    
    -- Insert or update app state
    INSERT INTO app_states (
        user_id, device_id, session_id, is_online, is_initialized,
        app_version, created_at, updated_at, last_seen_at
    ) VALUES (
        p_user_id, p_device_id, v_session_id, true, false,
        p_app_version, NOW(), NOW(), NOW()
    )
    ON CONFLICT (user_id, device_id) 
    DO UPDATE SET 
        session_id = v_session_id,
        is_online = true,
        is_initialized = false,
        app_version = COALESCE(EXCLUDED.app_version, app_states.app_version),
        updated_at = NOW(),
        last_seen_at = NOW()
    RETURNING id INTO v_app_state_id;
    
    -- Register or update device
    PERFORM register_user_device(
        p_user_id, p_device_id, p_platform, p_app_version, p_device_info
    );
    
    -- Create user session
    PERFORM create_user_session(
        p_user_id, p_device_id, v_session_id, p_platform, p_app_version, p_device_info
    );
    
    -- Log initialization start
    INSERT INTO app_initialization_logs (
        user_id, device_id, session_id, app_version, platform,
        initialization_start, is_debug_build
    ) VALUES (
        p_user_id, p_device_id, v_session_id, p_app_version, p_platform,
        NOW(), COALESCE((p_device_info->>'is_debug')::boolean, false)
    );
    
    -- Log lifecycle event
    INSERT INTO app_lifecycle_events (
        user_id, device_id, session_id, event_type, app_version, platform
    ) VALUES (
        p_user_id, p_device_id, v_session_id, 'app_start', p_app_version, p_platform
    );
    
    RETURN v_session_id;
END;
$$;

-- Update app state
CREATE OR REPLACE FUNCTION update_app_state(
    p_user_id UUID,
    p_device_id TEXT,
    p_is_online BOOLEAN DEFAULT NULL,
    p_is_initialized BOOLEAN DEFAULT NULL,
    p_theme_mode TEXT DEFAULT NULL,
    p_theme_color TEXT DEFAULT NULL,
    p_user_preferences JSONB DEFAULT NULL,
    p_is_loading BOOLEAN DEFAULT NULL,
    p_last_error TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE app_states SET
        is_online = COALESCE(p_is_online, is_online),
        is_initialized = COALESCE(p_is_initialized, is_initialized),
        theme_mode = COALESCE(p_theme_mode, theme_mode),
        selected_theme_color = COALESCE(p_theme_color, selected_theme_color),
        user_preferences = COALESCE(p_user_preferences, user_preferences),
        is_loading = COALESCE(p_is_loading, is_loading),
        last_error = COALESCE(p_last_error, last_error),
        error_count = CASE 
            WHEN p_last_error IS NOT NULL THEN error_count + 1
            ELSE error_count
        END,
        updated_at = NOW(),
        last_seen_at = NOW()
    WHERE user_id = p_user_id AND device_id = p_device_id;
    
    RETURN FOUND;
END;
$$;

-- Get current app state
CREATE OR REPLACE FUNCTION get_app_state(
    p_user_id UUID,
    p_device_id TEXT
)
RETURNS TABLE(
    session_id UUID,
    is_online BOOLEAN,
    is_initialized BOOLEAN,
    theme_mode TEXT,
    selected_theme_color TEXT,
    user_preferences JSONB,
    last_error TEXT,
    is_loading BOOLEAN,
    last_seen_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.session_id, a.is_online, a.is_initialized, a.theme_mode,
        a.selected_theme_color, a.user_preferences, a.last_error,
        a.is_loading, a.last_seen_at
    FROM app_states a
    WHERE a.user_id = p_user_id AND a.device_id = p_device_id;
END;
$$;

-- =============================================================================
-- DEVICE MANAGEMENT FUNCTIONS
-- =============================================================================

-- Register or update user device
CREATE OR REPLACE FUNCTION register_user_device(
    p_user_id UUID,
    p_device_id TEXT,
    p_platform TEXT DEFAULT NULL,
    p_app_version TEXT DEFAULT NULL,
    p_device_info JSONB DEFAULT '{}',
    p_fcm_token TEXT DEFAULT NULL,
    p_onesignal_player_id TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_device_record_id UUID;
    v_is_new_device BOOLEAN := false;
BEGIN
    -- Check if device exists for this user
    SELECT id INTO v_device_record_id
    FROM user_devices
    WHERE user_id = p_user_id AND device_id = p_device_id;
    
    IF NOT FOUND THEN
        v_is_new_device := true;
    END IF;
    
    -- Insert or update device record
    INSERT INTO user_devices (
        user_id, device_id, platform, app_version, device_name,
        device_model, device_brand, fcm_token, onesignal_player_id,
        device_fingerprint, is_active, last_seen_at
    ) VALUES (
        p_user_id, p_device_id, p_platform, p_app_version,
        p_device_info->>'device_name',
        p_device_info->>'device_model',
        p_device_info->>'device_brand',
        p_fcm_token, p_onesignal_player_id,
        p_device_info->>'device_fingerprint',
        true, NOW()
    )
    ON CONFLICT (user_id, device_id)
    DO UPDATE SET
        platform = COALESCE(EXCLUDED.platform, user_devices.platform),
        app_version = COALESCE(EXCLUDED.app_version, user_devices.app_version),
        device_name = COALESCE(EXCLUDED.device_name, user_devices.device_name),
        device_model = COALESCE(EXCLUDED.device_model, user_devices.device_model),
        device_brand = COALESCE(EXCLUDED.device_brand, user_devices.device_brand),
        fcm_token = COALESCE(EXCLUDED.fcm_token, user_devices.fcm_token),
        onesignal_player_id = COALESCE(EXCLUDED.onesignal_player_id, user_devices.onesignal_player_id),
        is_active = true,
        last_seen_at = NOW(),
        updated_at = NOW()
    RETURNING id INTO v_device_record_id;
    
    -- Update multi-user device tracking
    PERFORM track_multi_user_device(p_device_id, p_user_id, v_is_new_device);
    
    RETURN v_device_record_id;
END;
$$;

-- Track multi-user device usage
CREATE OR REPLACE FUNCTION track_multi_user_device(
    p_device_id TEXT,
    p_user_id UUID,
    p_is_new_user BOOLEAN DEFAULT false
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_count INTEGER;
    v_should_enable_auto_logout BOOLEAN := false;
BEGIN
    -- Count distinct users for this device
    SELECT COUNT(DISTINCT user_id) INTO v_user_count
    FROM user_devices
    WHERE device_id = p_device_id AND is_active = true;
    
    -- Determine if auto-logout should be enabled
    v_should_enable_auto_logout := v_user_count > 1;
    
    -- Insert or update multi-user device record
    INSERT INTO multi_user_devices (
        device_id, total_users_count, active_users_count,
        auto_logout_enabled, is_shared_device, last_activity_at
    ) VALUES (
        p_device_id, v_user_count, v_user_count,
        v_should_enable_auto_logout, v_user_count > 1, NOW()
    )
    ON CONFLICT (device_id)
    DO UPDATE SET
        total_users_count = GREATEST(multi_user_devices.total_users_count, v_user_count),
        active_users_count = v_user_count,
        auto_logout_enabled = v_should_enable_auto_logout,
        is_shared_device = v_user_count > 1,
        last_activity_at = NOW(),
        updated_at = NOW();
    
    -- Log device user history if new user
    IF p_is_new_user THEN
        INSERT INTO device_user_history (
            device_id, user_id, login_timestamp, auth_method
        ) VALUES (
            p_device_id, p_user_id, NOW(), 'email'
        );
    END IF;
END;
$$;

-- Check if device should apply auto-logout
CREATE OR REPLACE FUNCTION should_apply_auto_logout(
    p_device_id TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_auto_logout_enabled BOOLEAN := false;
BEGIN
    SELECT auto_logout_enabled INTO v_auto_logout_enabled
    FROM multi_user_devices
    WHERE device_id = p_device_id;
    
    RETURN COALESCE(v_auto_logout_enabled, false);
END;
$$;

-- =============================================================================
-- SESSION MANAGEMENT FUNCTIONS
-- =============================================================================

-- Create user session
CREATE OR REPLACE FUNCTION create_user_session(
    p_user_id UUID,
    p_device_id TEXT,
    p_session_id UUID,
    p_platform TEXT DEFAULT NULL,
    p_app_version TEXT DEFAULT NULL,
    p_device_info JSONB DEFAULT '{}',
    p_fcm_token TEXT DEFAULT NULL,
    p_onesignal_player_id TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_session_record_id UUID;
    v_inactivity_timeout INTEGER;
    v_auto_logout_enabled BOOLEAN;
BEGIN
    -- Get auto-logout settings
    SELECT should_apply_auto_logout(p_device_id) INTO v_auto_logout_enabled;
    
    -- Get inactivity timeout from config
    SELECT (config_value::TEXT)::INTEGER INTO v_inactivity_timeout
    FROM app_configurations
    WHERE config_key = 'inactivity_timeout_minutes';
    
    v_inactivity_timeout := COALESCE(v_inactivity_timeout, 60);
    
    -- Create session record
    INSERT INTO user_sessions (
        id, user_id, device_id, session_token, platform, app_version,
        device_info, fcm_token, onesignal_player_id, 
        inactivity_timeout_minutes, is_auto_logout_enabled
    ) VALUES (
        p_session_id, p_user_id, p_device_id, gen_random_uuid()::TEXT,
        p_platform, p_app_version, p_device_info, p_fcm_token,
        p_onesignal_player_id, v_inactivity_timeout, v_auto_logout_enabled
    )
    RETURNING id INTO v_session_record_id;
    
    RETURN v_session_record_id;
END;
$$;

-- Update session activity
CREATE OR REPLACE FUNCTION update_session_activity(
    p_user_id UUID,
    p_device_id TEXT,
    p_session_id UUID DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE user_sessions SET
        last_activity = NOW(),
        updated_at = NOW()
    WHERE user_id = p_user_id 
    AND device_id = p_device_id
    AND (p_session_id IS NULL OR id = p_session_id)
    AND is_active = true;
    
    -- Also update app state last seen
    UPDATE app_states SET
        last_seen_at = NOW(),
        updated_at = NOW()
    WHERE user_id = p_user_id AND device_id = p_device_id;
    
    -- Update device last seen
    UPDATE user_devices SET
        last_seen_at = NOW(),
        updated_at = NOW()
    WHERE user_id = p_user_id AND device_id = p_device_id;
    
    RETURN FOUND;
END;
$$;

-- End user session
CREATE OR REPLACE FUNCTION end_user_session(
    p_user_id UUID,
    p_device_id TEXT,
    p_session_id UUID DEFAULT NULL,
    p_logout_type TEXT DEFAULT 'manual'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_session_start TIMESTAMP WITH TIME ZONE;
    v_duration_minutes INTEGER;
BEGIN
    -- Get session start time and calculate duration
    SELECT session_start INTO v_session_start
    FROM user_sessions
    WHERE user_id = p_user_id 
    AND device_id = p_device_id
    AND (p_session_id IS NULL OR id = p_session_id)
    AND is_active = true;
    
    IF FOUND THEN
        v_duration_minutes := EXTRACT(EPOCH FROM (NOW() - v_session_start)) / 60;
        
        -- End the session
        UPDATE user_sessions SET
            session_end = NOW(),
            is_active = false,
            force_logout_reason = CASE 
                WHEN p_logout_type != 'manual' THEN p_logout_type 
                ELSE NULL 
            END,
            updated_at = NOW()
        WHERE user_id = p_user_id 
        AND device_id = p_device_id
        AND (p_session_id IS NULL OR id = p_session_id)
        AND is_active = true;
        
        -- Update device user history
        UPDATE device_user_history SET
            logout_timestamp = NOW(),
            logout_type = p_logout_type,
            session_duration_minutes = v_duration_minutes
        WHERE device_id = p_device_id 
        AND user_id = p_user_id
        AND logout_timestamp IS NULL;
        
        -- Log lifecycle event
        INSERT INTO app_lifecycle_events (
            user_id, device_id, event_type, metadata
        ) VALUES (
            p_user_id, p_device_id, 'user_logout',
            jsonb_build_object('logout_type', p_logout_type, 'session_duration_minutes', v_duration_minutes)
        );
        
        RETURN true;
    END IF;
    
    RETURN false;
END;
$$;

-- =============================================================================
-- CONNECTIVITY MANAGEMENT FUNCTIONS
-- =============================================================================

-- Log connectivity change
CREATE OR REPLACE FUNCTION log_connectivity_change(
    p_user_id UUID,
    p_device_id TEXT,
    p_connection_type TEXT,
    p_is_online BOOLEAN,
    p_session_id UUID DEFAULT NULL,
    p_network_quality TEXT DEFAULT NULL,
    p_latency_ms INTEGER DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_log_id UUID;
BEGIN
    INSERT INTO connectivity_logs (
        user_id, device_id, session_id, connection_type, is_online,
        network_quality, latency_ms, recorded_at
    ) VALUES (
        p_user_id, p_device_id, p_session_id, p_connection_type, p_is_online,
        p_network_quality, p_latency_ms, NOW()
    )
    RETURNING id INTO v_log_id;
    
    -- Update app state connectivity
    UPDATE app_states SET
        is_online = p_is_online,
        updated_at = NOW(),
        last_seen_at = NOW()
    WHERE user_id = p_user_id AND device_id = p_device_id;
    
    RETURN v_log_id;
END;
$$;

-- Get connectivity statistics
CREATE OR REPLACE FUNCTION get_connectivity_stats(
    p_user_id UUID,
    p_device_id TEXT DEFAULT NULL,
    p_days_back INTEGER DEFAULT 7
)
RETURNS TABLE(
    total_connections INTEGER,
    average_uptime_percentage DECIMAL,
    most_common_connection_type TEXT,
    average_latency_ms INTEGER,
    offline_incidents INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    WITH connectivity_data AS (
        SELECT 
            connection_type,
            is_online,
            latency_ms,
            recorded_at
        FROM connectivity_logs
        WHERE user_id = p_user_id
        AND (p_device_id IS NULL OR device_id = p_device_id)
        AND recorded_at >= NOW() - (p_days_back || ' days')::INTERVAL
    )
    SELECT 
        COUNT(*)::INTEGER as total_connections,
        (COUNT(*) FILTER (WHERE is_online = true) * 100.0 / COUNT(*))::DECIMAL as average_uptime_percentage,
        (SELECT connection_type FROM connectivity_data 
         WHERE connection_type != 'none'
         GROUP BY connection_type 
         ORDER BY COUNT(*) DESC 
         LIMIT 1) as most_common_connection_type,
        AVG(latency_ms)::INTEGER as average_latency_ms,
        COUNT(*) FILTER (WHERE is_online = false)::INTEGER as offline_incidents
    FROM connectivity_data;
END;
$$;

-- =============================================================================
-- LIFECYCLE EVENT MANAGEMENT
-- =============================================================================

-- Log app lifecycle event
CREATE OR REPLACE FUNCTION log_lifecycle_event(
    p_user_id UUID,
    p_device_id TEXT,
    p_event_type TEXT,
    p_event_state TEXT DEFAULT NULL,
    p_session_id UUID DEFAULT NULL,
    p_app_version TEXT DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_event_id UUID;
    v_previous_event RECORD;
    v_duration_seconds INTEGER;
BEGIN
    -- Get the last event for duration calculation
    SELECT event_state, event_timestamp INTO v_previous_event
    FROM app_lifecycle_events
    WHERE user_id = p_user_id AND device_id = p_device_id
    ORDER BY event_timestamp DESC
    LIMIT 1;
    
    -- Calculate duration in previous state
    IF v_previous_event.event_timestamp IS NOT NULL THEN
        v_duration_seconds := EXTRACT(EPOCH FROM (NOW() - v_previous_event.event_timestamp));
    END IF;
    
    INSERT INTO app_lifecycle_events (
        user_id, device_id, session_id, event_type, event_state,
        previous_state, duration_in_state_seconds, app_version,
        metadata, event_timestamp
    ) VALUES (
        p_user_id, p_device_id, p_session_id, p_event_type, p_event_state,
        v_previous_event.event_state, v_duration_seconds, p_app_version,
        p_metadata, NOW()
    )
    RETURNING id INTO v_event_id;
    
    -- Update session activity
    PERFORM update_session_activity(p_user_id, p_device_id, p_session_id);
    
    RETURN v_event_id;
END;
$$;

-- =============================================================================
-- FRONTING CHANGES MANAGEMENT
-- =============================================================================

-- Record fronting change
CREATE OR REPLACE FUNCTION record_fronting_change(
    p_user_id UUID,
    p_alter_name TEXT,
    p_change_type TEXT DEFAULT 'manual',
    p_change_trigger TEXT DEFAULT NULL,
    p_emotional_state TEXT DEFAULT NULL,
    p_stress_level INTEGER DEFAULT NULL,
    p_notes TEXT DEFAULT NULL,
    p_should_notify BOOLEAN DEFAULT true
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_change_id UUID;
    v_previous_alter_name TEXT;
BEGIN
    -- Get the current/previous alter
    SELECT alter_name INTO v_previous_alter_name
    FROM fronting_changes
    WHERE user_id = p_user_id
    ORDER BY change_timestamp DESC
    LIMIT 1;
    
    -- Insert the new fronting change
    INSERT INTO fronting_changes (
        user_id, alter_name, previous_alter_name, change_type,
        change_trigger, emotional_state, stress_level, notes,
        notification_sent, timezone
    ) VALUES (
        p_user_id, p_alter_name, v_previous_alter_name, p_change_type,
        p_change_trigger, p_emotional_state, p_stress_level, p_notes,
        NOT p_should_notify, current_setting('TIMEZONE')
    )
    RETURNING id INTO v_change_id;
    
    -- If notification should be sent, trigger notification process
    IF p_should_notify THEN
        PERFORM send_fronting_notification(v_change_id);
    END IF;
    
    RETURN v_change_id;
END;
$$;

-- Send fronting change notification
CREATE OR REPLACE FUNCTION send_fronting_notification(
    p_change_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_change RECORD;
    v_notification_sent BOOLEAN := false;
BEGIN
    -- Get the fronting change details
    SELECT * INTO v_change
    FROM fronting_changes
    WHERE id = p_change_id;
    
    IF NOT FOUND THEN
        RETURN false;
    END IF;
    
    -- Here you would integrate with your notification service
    -- For now, we'll just mark it as sent
    
    UPDATE fronting_changes SET
        notification_sent = true,
        notification_timestamp = NOW(),
        updated_at = NOW()
    WHERE id = p_change_id;
    
    v_notification_sent := FOUND;
    
    -- Log the notification as a background message
    IF v_notification_sent THEN
        INSERT INTO background_messages (
            user_id, message_type, title, body, data_payload,
            processing_status, app_state
        ) VALUES (
            v_change.user_id, 'fronting_change',
            'New Fronting Alter',
            v_change.alter_name || ' is now fronting! 🔄',
            jsonb_build_object(
                'fronting_name', v_change.alter_name,
                'change_id', v_change.id,
                'timestamp', v_change.change_timestamp
            ),
            'completed', 'background'
        );
    END IF;
    
    RETURN v_notification_sent;
END;
$$;

-- =============================================================================
-- ERROR REPORTING FUNCTIONS
-- =============================================================================

-- Report application error
CREATE OR REPLACE FUNCTION report_app_error(
    p_user_id UUID,
    p_device_id TEXT,
    p_error_type TEXT,
    p_error_message TEXT,
    p_stack_trace TEXT DEFAULT NULL,
    p_context_description TEXT DEFAULT NULL,
    p_function_name TEXT DEFAULT NULL,
    p_session_id UUID DEFAULT NULL,
    p_app_version TEXT DEFAULT NULL,
    p_severity_level TEXT DEFAULT 'error',
    p_is_fatal BOOLEAN DEFAULT false,
    p_user_action TEXT DEFAULT NULL,
    p_screen_name TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_error_id UUID;
    v_existing_error_id UUID;
BEGIN
    -- Check if this error already exists (same message, function, user)
    SELECT id INTO v_existing_error_id
    FROM error_reports
    WHERE user_id = p_user_id
    AND error_message = p_error_message
    AND COALESCE(function_name, '') = COALESCE(p_function_name, '')
    AND resolved_at IS NULL
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF v_existing_error_id IS NOT NULL THEN
        -- Update existing error occurrence
        UPDATE error_reports SET
            occurrence_count = occurrence_count + 1,
            last_occurred_at = NOW(),
            updated_at = NOW()
        WHERE id = v_existing_error_id
        RETURNING id INTO v_error_id;
    ELSE
        -- Create new error report
        INSERT INTO error_reports (
            user_id, device_id, session_id, error_type, error_message,
            stack_trace, context_description, function_name, app_version,
            severity_level, is_fatal, affects_core_functionality,
            user_action, screen_name, environment,
            is_debug_build
        ) VALUES (
            p_user_id, p_device_id, p_session_id, p_error_type, p_error_message,
            p_stack_trace, p_context_description, p_function_name, p_app_version,
            p_severity_level, p_is_fatal, 
            CASE WHEN p_is_fatal THEN true ELSE false END,
            p_user_action, p_screen_name, 'production',
            false
        )
        RETURNING id INTO v_error_id;
    END IF;
    
    -- Update app state error count
    UPDATE app_states SET
        last_error = p_error_message,
        error_count = error_count + 1,
        updated_at = NOW()
    WHERE user_id = p_user_id AND device_id = p_device_id;
    
    RETURN v_error_id;
END;
$$;

-- =============================================================================
-- BACKGROUND MESSAGE PROCESSING
-- =============================================================================

-- Process background message
CREATE OR REPLACE FUNCTION process_background_message(
    p_user_id UUID,
    p_device_id TEXT,
    p_message_type TEXT,
    p_title TEXT DEFAULT NULL,
    p_body TEXT DEFAULT NULL,
    p_data_payload JSONB DEFAULT '{}',
    p_app_state TEXT DEFAULT 'background'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_message_id UUID;
    v_processing_start TIMESTAMP WITH TIME ZONE := NOW();
    v_processing_duration_ms INTEGER;
BEGIN
    -- Insert the background message
    INSERT INTO background_messages (
        user_id, device_id, message_type, title, body,
        data_payload, app_state, processing_status
    ) VALUES (
        p_user_id, p_device_id, p_message_type, p_title, p_body,
        p_data_payload, p_app_state, 'processing'
    )
    RETURNING id INTO v_message_id;
    
    -- Process based on message type
    CASE p_message_type
        WHEN 'fronting_change' THEN
            PERFORM handle_fronting_change_message(v_message_id, p_data_payload);
        WHEN 'chat_message' THEN
            PERFORM handle_chat_message_notification(v_message_id, p_data_payload);
        WHEN 'system_update' THEN
            PERFORM handle_system_update_message(v_message_id, p_data_payload);
        ELSE
            -- Generic message handling
            NULL;
    END CASE;
    
    -- Calculate processing duration and mark as completed
    v_processing_duration_ms := EXTRACT(EPOCH FROM (NOW() - v_processing_start)) * 1000;
    
    UPDATE background_messages SET
        processed_at = NOW(),
        processing_status = 'completed',
        processing_duration_ms = v_processing_duration_ms
    WHERE id = v_message_id;
    
    RETURN v_message_id;
END;
$$;

-- Handle fronting change message
CREATE OR REPLACE FUNCTION handle_fronting_change_message(
    p_message_id UUID,
    p_data_payload JSONB
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Update background message handler function
    UPDATE background_messages SET
        handler_function = 'handle_fronting_change_message'
    WHERE id = p_message_id;
    
    -- Additional fronting change specific processing can be added here
END;
$$;

-- Handle chat message notification
CREATE OR REPLACE FUNCTION handle_chat_message_notification(
    p_message_id UUID,
    p_data_payload JSONB
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Update background message handler function
    UPDATE background_messages SET
        handler_function = 'handle_chat_message_notification'
    WHERE id = p_message_id;
    
    -- Additional chat message specific processing can be added here
END;
$$;

-- Handle system update message
CREATE OR REPLACE FUNCTION handle_system_update_message(
    p_message_id UUID,
    p_data_payload JSONB
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Update background message handler function
    UPDATE background_messages SET
        handler_function = 'handle_system_update_message'
    WHERE id = p_message_id;
    
    -- Additional system update specific processing can be added here
END;
$$;

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

-- Get app configuration value
CREATE OR REPLACE FUNCTION get_app_config(
    p_config_key TEXT,
    p_default_value TEXT DEFAULT NULL
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_config_value TEXT;
BEGIN
    SELECT config_value #>> '{}' INTO v_config_value
    FROM app_configurations
    WHERE config_key = p_config_key;
    
    RETURN COALESCE(v_config_value, p_default_value);
END;
$$;

-- Set app configuration value
CREATE OR REPLACE FUNCTION set_app_config(
    p_config_key TEXT,
    p_config_value JSONB,
    p_config_type TEXT DEFAULT 'setting',
    p_description TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO app_configurations (
        config_key, config_value, config_type, description, created_by
    ) VALUES (
        p_config_key, p_config_value, p_config_type, p_description, auth.uid()
    )
    ON CONFLICT (config_key)
    DO UPDATE SET
        config_value = EXCLUDED.config_value,
        config_type = EXCLUDED.config_type,
        description = COALESCE(EXCLUDED.description, app_configurations.description),
        updated_at = NOW();
    
    RETURN true;
END;
$$;

-- Clean up old data
CREATE OR REPLACE FUNCTION cleanup_old_app_data(
    p_days_to_keep INTEGER DEFAULT 90
)
RETURNS TABLE(
    table_name TEXT,
    records_deleted INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_cutoff_date TIMESTAMP WITH TIME ZONE := NOW() - (p_days_to_keep || ' days')::INTERVAL;
    v_deleted_count INTEGER;
BEGIN
    -- Clean up old connectivity logs
    DELETE FROM connectivity_logs WHERE recorded_at < v_cutoff_date;
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    RETURN QUERY SELECT 'connectivity_logs'::TEXT, v_deleted_count;
    
    -- Clean up old lifecycle events
    DELETE FROM app_lifecycle_events WHERE event_timestamp < v_cutoff_date;
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    RETURN QUERY SELECT 'app_lifecycle_events'::TEXT, v_deleted_count;
    
    -- Clean up old background messages
    DELETE FROM background_messages WHERE received_at < v_cutoff_date;
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    RETURN QUERY SELECT 'background_messages'::TEXT, v_deleted_count;
    
    -- Clean up resolved error reports older than 180 days
    DELETE FROM error_reports 
    WHERE resolved_at IS NOT NULL 
    AND resolved_at < NOW() - INTERVAL '180 days';
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    RETURN QUERY SELECT 'error_reports'::TEXT, v_deleted_count;
    
    -- Clean up old initialization logs
    DELETE FROM app_initialization_logs WHERE created_at < v_cutoff_date;
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    RETURN QUERY SELECT 'app_initialization_logs'::TEXT, v_deleted_count;
END;
$$;

-- =============================================================================
-- GRANT PERMISSIONS
-- =============================================================================

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION initialize_app_state TO authenticated;
GRANT EXECUTE ON FUNCTION update_app_state TO authenticated;
GRANT EXECUTE ON FUNCTION get_app_state TO authenticated;
GRANT EXECUTE ON FUNCTION register_user_device TO authenticated;
GRANT EXECUTE ON FUNCTION track_multi_user_device TO authenticated;
GRANT EXECUTE ON FUNCTION should_apply_auto_logout TO authenticated;
GRANT EXECUTE ON FUNCTION create_user_session TO authenticated;
GRANT EXECUTE ON FUNCTION update_session_activity TO authenticated;
GRANT EXECUTE ON FUNCTION end_user_session TO authenticated;
GRANT EXECUTE ON FUNCTION log_connectivity_change TO authenticated;
GRANT EXECUTE ON FUNCTION get_connectivity_stats TO authenticated;
GRANT EXECUTE ON FUNCTION log_lifecycle_event TO authenticated;
GRANT EXECUTE ON FUNCTION record_fronting_change TO authenticated;
GRANT EXECUTE ON FUNCTION send_fronting_notification TO authenticated;
GRANT EXECUTE ON FUNCTION report_app_error TO authenticated;
GRANT EXECUTE ON FUNCTION process_background_message TO authenticated;
GRANT EXECUTE ON FUNCTION get_app_config TO authenticated;
GRANT EXECUTE ON FUNCTION set_app_config TO authenticated;

-- Grant service role permissions for background processing
GRANT EXECUTE ON FUNCTION handle_fronting_change_message TO service_role;
GRANT EXECUTE ON FUNCTION handle_chat_message_notification TO service_role;
GRANT EXECUTE ON FUNCTION handle_system_update_message TO service_role;
GRANT EXECUTE ON FUNCTION cleanup_old_app_data TO service_role;

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON FUNCTION initialize_app_state IS 'Initialize app state for user session with device registration';
COMMENT ON FUNCTION update_app_state IS 'Update app state parameters for active session';
COMMENT ON FUNCTION get_app_state IS 'Retrieve current app state for user and device';
COMMENT ON FUNCTION register_user_device IS 'Register or update user device information';
COMMENT ON FUNCTION should_apply_auto_logout IS 'Check if device should apply auto-logout based on multi-user usage';
COMMENT ON FUNCTION record_fronting_change IS 'Record DID system fronting change with notification';
COMMENT ON FUNCTION report_app_error IS 'Report application errors with context and tracking';
COMMENT ON FUNCTION process_background_message IS 'Process background messages with type-specific handling';
COMMENT ON FUNCTION cleanup_old_app_data IS 'Clean up old application data to maintain performance';

-- Setup completion message
SELECT 'Main App Business Logic Functions Setup Complete!' as status, NOW() as setup_completed_at;
