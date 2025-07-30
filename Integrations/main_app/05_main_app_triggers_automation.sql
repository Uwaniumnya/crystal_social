-- Crystal Social Main Application System - Triggers and Automation
-- File: 05_main_app_triggers_automation.sql
-- Purpose: Database triggers and automation for main application system lifecycle management

-- =============================================================================
-- UTILITY FUNCTIONS FOR TRIGGERS
-- =============================================================================

-- Function to send real-time notification
CREATE OR REPLACE FUNCTION send_realtime_notification(
    p_channel TEXT,
    p_event TEXT,
    p_payload JSONB
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    PERFORM pg_notify(p_channel, json_build_object(
        'event', p_event,
        'payload', p_payload,
        'timestamp', NOW()
    )::text);
END;
$$;

-- Function to update multi-user device stats
CREATE OR REPLACE FUNCTION update_multi_user_device_stats(
    p_device_id TEXT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_users INTEGER;
    v_active_users INTEGER;
BEGIN
    -- Count users for this device
    SELECT 
        COUNT(DISTINCT user_id),
        COUNT(DISTINCT user_id) FILTER (WHERE is_active = true)
    INTO v_total_users, v_active_users
    FROM user_devices
    WHERE device_id = p_device_id;
    
    -- Update multi-user device record
    INSERT INTO multi_user_devices (
        device_id, total_users_count, active_users_count,
        is_shared_device, auto_logout_enabled, last_activity_at
    ) VALUES (
        p_device_id, v_total_users, v_active_users,
        v_total_users > 1, v_total_users > 1, NOW()
    )
    ON CONFLICT (device_id)
    DO UPDATE SET
        total_users_count = EXCLUDED.total_users_count,
        active_users_count = EXCLUDED.active_users_count,
        is_shared_device = EXCLUDED.is_shared_device,
        auto_logout_enabled = EXCLUDED.auto_logout_enabled,
        last_activity_at = EXCLUDED.last_activity_at,
        updated_at = NOW();
END;
$$;

-- =============================================================================
-- APP STATE MANAGEMENT TRIGGERS
-- =============================================================================

-- App state change trigger function
CREATE OR REPLACE FUNCTION app_state_change_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_state_change JSONB;
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Log app state creation
        INSERT INTO app_lifecycle_events (
            user_id, device_id, session_id, event_type, 
            app_version, metadata
        ) VALUES (
            NEW.user_id, NEW.device_id, NEW.session_id, 'app_state_created',
            NEW.app_version, jsonb_build_object(
                'theme_mode', NEW.theme_mode,
                'theme_color', NEW.selected_theme_color,
                'is_initialized', NEW.is_initialized
            )
        );
        
        -- Send real-time notification
        PERFORM send_realtime_notification(
            'app_state_changes',
            'app_state_created',
            jsonb_build_object(
                'user_id', NEW.user_id,
                'device_id', NEW.device_id,
                'session_id', NEW.session_id
            )
        );
        
        RETURN NEW;
        
    ELSIF TG_OP = 'UPDATE' THEN
        -- Track what changed
        v_state_change := jsonb_build_object();
        
        IF OLD.is_online IS DISTINCT FROM NEW.is_online THEN
            v_state_change := v_state_change || jsonb_build_object(
                'connectivity_changed', true,
                'new_online_status', NEW.is_online
            );
            
            -- Log connectivity change
            INSERT INTO connectivity_logs (
                user_id, device_id, session_id, connection_type, is_online
            ) VALUES (
                NEW.user_id, NEW.device_id, NEW.session_id,
                CASE WHEN NEW.is_online THEN 'wifi' ELSE 'none' END,
                NEW.is_online
            );
        END IF;
        
        IF OLD.theme_mode IS DISTINCT FROM NEW.theme_mode 
           OR OLD.selected_theme_color IS DISTINCT FROM NEW.selected_theme_color THEN
            v_state_change := v_state_change || jsonb_build_object(
                'theme_changed', true,
                'new_theme_mode', NEW.theme_mode,
                'new_theme_color', NEW.selected_theme_color
            );
            
            -- Update user preferences in auth.users
            UPDATE auth.users SET
                raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb) || 
                jsonb_build_object(
                    'theme_mode', NEW.theme_mode,
                    'theme_color', NEW.selected_theme_color
                )
            WHERE id = NEW.user_id;
        END IF;
        
        IF OLD.is_initialized IS DISTINCT FROM NEW.is_initialized AND NEW.is_initialized THEN
            v_state_change := v_state_change || jsonb_build_object(
                'app_initialized', true
            );
            
            -- Update initialization log
            UPDATE app_initialization_logs SET
                initialization_end = NOW(),
                initialization_successful = true,
                total_duration_ms = EXTRACT(EPOCH FROM (NOW() - initialization_start)) * 1000
            WHERE user_id = NEW.user_id 
            AND device_id = NEW.device_id 
            AND session_id = NEW.session_id
            AND initialization_end IS NULL;
            
            -- Log lifecycle event
            INSERT INTO app_lifecycle_events (
                user_id, device_id, session_id, event_type, metadata
            ) VALUES (
                NEW.user_id, NEW.device_id, NEW.session_id, 'app_initialized',
                v_state_change
            );
        END IF;
        
        IF OLD.last_error IS DISTINCT FROM NEW.last_error AND NEW.last_error IS NOT NULL THEN
            v_state_change := v_state_change || jsonb_build_object(
                'error_occurred', true,
                'error_message', NEW.last_error,
                'error_count', NEW.error_count
            );
        END IF;
        
        -- Send real-time notification if significant changes occurred
        IF jsonb_array_length(jsonb_object_keys(v_state_change)) > 0 THEN
            PERFORM send_realtime_notification(
                'app_state_changes',
                'app_state_updated',
                jsonb_build_object(
                    'user_id', NEW.user_id,
                    'device_id', NEW.device_id,
                    'changes', v_state_change
                )
            );
        END IF;
        
        RETURN NEW;
        
    ELSIF TG_OP = 'DELETE' THEN
        -- Log app state deletion
        INSERT INTO app_lifecycle_events (
            user_id, device_id, event_type, metadata
        ) VALUES (
            OLD.user_id, OLD.device_id, 'app_state_deleted',
            jsonb_build_object('session_id', OLD.session_id)
        );
        
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$;

-- Create app state triggers
CREATE TRIGGER app_state_change_trigger
    AFTER INSERT OR UPDATE OR DELETE ON app_states
    FOR EACH ROW
    EXECUTE FUNCTION app_state_change_trigger();

-- =============================================================================
-- USER DEVICE MANAGEMENT TRIGGERS
-- =============================================================================

-- User device registration trigger function
CREATE OR REPLACE FUNCTION user_device_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Set as primary device if it's the user's first device
        IF NOT EXISTS (
            SELECT 1 FROM user_devices 
            WHERE user_id = NEW.user_id 
            AND is_primary_device = true
            AND id != NEW.id
        ) THEN
            NEW.is_primary_device := true;
        END IF;
        
        -- Update multi-user device tracking
        PERFORM update_multi_user_device_stats(NEW.device_id);
        
        -- Log device registration
        INSERT INTO app_lifecycle_events (
            user_id, device_id, event_type, platform, metadata
        ) VALUES (
            NEW.user_id, NEW.device_id, 'device_registered', NEW.platform,
            jsonb_build_object(
                'device_model', NEW.device_model,
                'device_brand', NEW.device_brand,
                'app_version', NEW.app_version,
                'is_primary', NEW.is_primary_device
            )
        );
        
        RETURN NEW;
        
    ELSIF TG_OP = 'UPDATE' THEN
        -- Handle primary device changes
        IF OLD.is_primary_device IS DISTINCT FROM NEW.is_primary_device AND NEW.is_primary_device THEN
            -- Ensure only one primary device per user
            UPDATE user_devices SET
                is_primary_device = false,
                updated_at = NOW()
            WHERE user_id = NEW.user_id 
            AND id != NEW.id 
            AND is_primary_device = true;
        END IF;
        
        -- Update FCM token in users table if changed
        IF OLD.fcm_token IS DISTINCT FROM NEW.fcm_token AND NEW.fcm_token IS NOT NULL THEN
            UPDATE auth.users SET
                raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb) || 
                jsonb_build_object('fcm_token', NEW.fcm_token)
            WHERE id = NEW.user_id;
        END IF;
        
        -- Track security violations
        IF OLD.security_violations IS DISTINCT FROM NEW.security_violations THEN
            INSERT INTO app_lifecycle_events (
                user_id, device_id, event_type, metadata
            ) VALUES (
                NEW.user_id, NEW.device_id, 'security_violation',
                jsonb_build_object(
                    'old_violations', OLD.security_violations,
                    'new_violations', NEW.security_violations
                )
            );
        END IF;
        
        -- Update multi-user device tracking
        PERFORM update_multi_user_device_stats(NEW.device_id);
        
        RETURN NEW;
        
    ELSIF TG_OP = 'DELETE' THEN
        -- Update multi-user device tracking
        PERFORM update_multi_user_device_stats(OLD.device_id);
        
        -- Log device removal
        INSERT INTO app_lifecycle_events (
            user_id, device_id, event_type, metadata
        ) VALUES (
            OLD.user_id, OLD.device_id, 'device_removed',
            jsonb_build_object('was_primary', OLD.is_primary_device)
        );
        
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$;

-- Create user device triggers
CREATE TRIGGER user_device_trigger
    BEFORE INSERT OR UPDATE OR DELETE ON user_devices
    FOR EACH ROW
    EXECUTE FUNCTION user_device_trigger();

-- =============================================================================
-- SESSION MANAGEMENT TRIGGERS
-- =============================================================================

-- User session trigger function
CREATE OR REPLACE FUNCTION user_session_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_session_duration INTEGER;
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Log session start
        INSERT INTO app_lifecycle_events (
            user_id, device_id, session_id, event_type, platform, app_version, metadata
        ) VALUES (
            NEW.user_id, NEW.device_id, NEW.id, 'session_started', 
            NEW.platform, NEW.app_version,
            jsonb_build_object(
                'session_token', LEFT(NEW.session_token, 8) || '...',
                'auto_logout_enabled', NEW.is_auto_logout_enabled,
                'timeout_minutes', NEW.inactivity_timeout_minutes
            )
        );
        
        RETURN NEW;
        
    ELSIF TG_OP = 'UPDATE' THEN
        -- Handle session end
        IF OLD.is_active IS DISTINCT FROM NEW.is_active AND NOT NEW.is_active THEN
            v_session_duration := EXTRACT(EPOCH FROM (COALESCE(NEW.session_end, NOW()) - NEW.session_start)) / 60;
            
            -- Log session end
            INSERT INTO app_lifecycle_events (
                user_id, device_id, session_id, event_type, metadata
            ) VALUES (
                NEW.user_id, NEW.device_id, NEW.id, 'session_ended',
                jsonb_build_object(
                    'session_duration_minutes', v_session_duration,
                    'logout_reason', NEW.force_logout_reason
                )
            );
            
            -- Send real-time notification
            PERFORM send_realtime_notification(
                'user_sessions',
                'session_ended',
                jsonb_build_object(
                    'user_id', NEW.user_id,
                    'device_id', NEW.device_id,
                    'session_id', NEW.id,
                    'duration_minutes', v_session_duration
                )
            );
        END IF;
        
        -- Track suspicious activity (rapid session changes)
        IF OLD.last_activity IS DISTINCT FROM NEW.last_activity THEN
            -- Check for rapid activity updates (potential bot behavior)
            IF EXISTS (
                SELECT 1 FROM user_sessions 
                WHERE user_id = NEW.user_id 
                AND updated_at >= NOW() - INTERVAL '1 minute'
                AND id != NEW.id
            ) THEN
                INSERT INTO error_reports (
                    user_id, device_id, session_id, error_type, error_message,
                    severity_level, context_description
                ) VALUES (
                    NEW.user_id, NEW.device_id, NEW.id, 'security',
                    'Rapid session activity detected',
                    'warning', 'Potential bot behavior or session abuse'
                );
            END IF;
        END IF;
        
        RETURN NEW;
        
    ELSIF TG_OP = 'DELETE' THEN
        -- Log session deletion
        INSERT INTO app_lifecycle_events (
            user_id, device_id, event_type, metadata
        ) VALUES (
            OLD.user_id, OLD.device_id, 'session_deleted',
            jsonb_build_object('session_id', OLD.id)
        );
        
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$;

-- Create user session triggers
CREATE TRIGGER user_session_trigger
    AFTER INSERT OR UPDATE OR DELETE ON user_sessions
    FOR EACH ROW
    EXECUTE FUNCTION user_session_trigger();

-- =============================================================================
-- FRONTING CHANGES TRIGGERS
-- =============================================================================

-- Fronting changes trigger function
CREATE OR REPLACE FUNCTION fronting_changes_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_notification_payload JSONB;
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Validate alter name
        IF LENGTH(TRIM(NEW.alter_name)) = 0 THEN
            RAISE EXCEPTION 'Alter name cannot be empty';
        END IF;
        
        -- Set timezone if not provided
        IF NEW.timezone IS NULL THEN
            NEW.timezone := current_setting('TIMEZONE');
        END IF;
        
        -- Auto-verify system changes
        IF NEW.change_type = 'system' THEN
            NEW.verified_by_system := true;
            NEW.verification_timestamp := NOW();
        END IF;
        
        -- Prepare notification payload
        v_notification_payload := jsonb_build_object(
            'user_id', NEW.user_id,
            'alter_name', NEW.alter_name,
            'previous_alter', NEW.previous_alter_name,
            'change_type', NEW.change_type,
            'timestamp', NEW.change_timestamp,
            'emotional_state', NEW.emotional_state,
            'stress_level', NEW.stress_level
        );
        
        -- Send real-time notification to fronting changes channel
        PERFORM send_realtime_notification(
            'fronting_changes',
            'alter_changed',
            v_notification_payload
        );
        
        -- Log lifecycle event
        INSERT INTO app_lifecycle_events (
            user_id, device_id, event_type, metadata
        ) VALUES (
            NEW.user_id, NULL, 'fronting_changed',
            v_notification_payload
        );
        
        -- Schedule push notification if enabled
        IF NOT NEW.notification_sent THEN
            INSERT INTO background_messages (
                user_id, message_type, title, body, data_payload,
                processing_status
            ) VALUES (
                NEW.user_id, 'fronting_change',
                'New Fronting Alter',
                NEW.alter_name || ' is now fronting! 🔄',
                jsonb_build_object(
                    'fronting_id', NEW.id,
                    'alter_name', NEW.alter_name,
                    'change_type', NEW.change_type
                ),
                'pending'
            );
        END IF;
        
        RETURN NEW;
        
    ELSIF TG_OP = 'UPDATE' THEN
        -- Handle notification status changes
        IF OLD.notification_sent IS DISTINCT FROM NEW.notification_sent AND NEW.notification_sent THEN
            NEW.notification_timestamp := COALESCE(NEW.notification_timestamp, NOW());
            
            -- Update background message status
            UPDATE background_messages SET
                processing_status = 'completed',
                processed_at = NOW()
            WHERE user_id = NEW.user_id
            AND message_type = 'fronting_change'
            AND data_payload->>'fronting_id' = NEW.id::text
            AND processing_status = 'pending';
        END IF;
        
        -- Handle verification changes
        IF OLD.verified_by_system IS DISTINCT FROM NEW.verified_by_system AND NEW.verified_by_system THEN
            NEW.verification_timestamp := NOW();
        END IF;
        
        RETURN NEW;
        
    ELSIF TG_OP = 'DELETE' THEN
        -- Log fronting change deletion
        INSERT INTO app_lifecycle_events (
            user_id, device_id, event_type, metadata
        ) VALUES (
            OLD.user_id, NULL, 'fronting_change_deleted',
            jsonb_build_object(
                'fronting_id', OLD.id,
                'alter_name', OLD.alter_name
            )
        );
        
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$;

-- Create fronting changes triggers
CREATE TRIGGER fronting_changes_trigger
    BEFORE INSERT OR UPDATE OR DELETE ON fronting_changes
    FOR EACH ROW
    EXECUTE FUNCTION fronting_changes_trigger();

-- =============================================================================
-- ERROR REPORTING TRIGGERS
-- =============================================================================

-- Error reporting trigger function
CREATE OR REPLACE FUNCTION error_reports_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_alert_threshold INTEGER := 10;
    v_recent_errors INTEGER;
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Set default values
        NEW.first_occurred_at := COALESCE(NEW.first_occurred_at, NOW());
        NEW.last_occurred_at := COALESCE(NEW.last_occurred_at, NOW());
        
        -- Auto-categorize certain errors
        IF NEW.error_message ILIKE '%network%' OR NEW.error_message ILIKE '%connection%' THEN
            NEW.error_type := 'network';
        ELSIF NEW.error_message ILIKE '%auth%' OR NEW.error_message ILIKE '%permission%' THEN
            NEW.error_type := 'authentication';
        ELSIF NEW.error_message ILIKE '%database%' OR NEW.error_message ILIKE '%sql%' THEN
            NEW.error_type := 'database';
        END IF;
        
        -- Check for error spike (alert threshold)
        SELECT COUNT(*) INTO v_recent_errors
        FROM error_reports
        WHERE user_id = NEW.user_id
        AND severity_level IN ('error', 'critical')
        AND created_at >= NOW() - INTERVAL '10 minutes';
        
        IF v_recent_errors >= v_alert_threshold THEN
            -- Create alert for support team
            INSERT INTO background_messages (
                user_id, message_type, title, body, data_payload,
                processing_status
            ) VALUES (
                NEW.user_id, 'system_update',
                'Error Spike Alert',
                'User experiencing high error rate',
                jsonb_build_object(
                    'error_count', v_recent_errors,
                    'time_window', '10 minutes',
                    'latest_error', NEW.error_message
                ),
                'pending'
            );
        END IF;
        
        -- Send real-time notification for critical errors
        IF NEW.severity_level = 'critical' OR NEW.is_fatal THEN
            PERFORM send_realtime_notification(
                'critical_errors',
                'critical_error_reported',
                jsonb_build_object(
                    'user_id', NEW.user_id,
                    'device_id', NEW.device_id,
                    'error_type', NEW.error_type,
                    'error_message', NEW.error_message,
                    'is_fatal', NEW.is_fatal
                )
            );
        END IF;
        
        RETURN NEW;
        
    ELSIF TG_OP = 'UPDATE' THEN
        -- Handle resolution
        IF OLD.resolved_at IS DISTINCT FROM NEW.resolved_at AND NEW.resolved_at IS NOT NULL THEN
            -- Log resolution
            INSERT INTO app_lifecycle_events (
                user_id, device_id, event_type, metadata
            ) VALUES (
                NEW.user_id, NEW.device_id, 'error_resolved',
                jsonb_build_object(
                    'error_id', NEW.id,
                    'error_type', NEW.error_type,
                    'resolution_time_minutes', 
                    EXTRACT(EPOCH FROM (NEW.resolved_at - NEW.created_at)) / 60,
                    'resolved_by', NEW.resolved_by
                )
            );
        END IF;
        
        RETURN NEW;
        
    ELSIF TG_OP = 'DELETE' THEN
        -- Prevent deletion of unresolved critical errors
        IF OLD.resolved_at IS NULL AND OLD.severity_level = 'critical' THEN
            RAISE EXCEPTION 'Cannot delete unresolved critical error';
        END IF;
        
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$;

-- Create error reporting triggers
CREATE TRIGGER error_reports_trigger
    BEFORE INSERT OR UPDATE OR DELETE ON error_reports
    FOR EACH ROW
    EXECUTE FUNCTION error_reports_trigger();

-- =============================================================================
-- BACKGROUND MESSAGE PROCESSING TRIGGERS
-- =============================================================================

-- Background message processing trigger
CREATE OR REPLACE FUNCTION background_messages_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Set default processing status
        NEW.processing_status := COALESCE(NEW.processing_status, 'pending');
        NEW.received_at := COALESCE(NEW.received_at, NOW());
        
        -- Send real-time notification to processing queue
        PERFORM send_realtime_notification(
            'background_message_queue',
            'new_message',
            jsonb_build_object(
                'message_id', NEW.id,
                'message_type', NEW.message_type,
                'user_id', NEW.user_id,
                'priority', CASE NEW.message_type
                    WHEN 'fronting_change' THEN 'high'
                    WHEN 'system_update' THEN 'medium'
                    ELSE 'normal'
                END
            )
        );
        
        RETURN NEW;
        
    ELSIF TG_OP = 'UPDATE' THEN
        -- Handle processing status changes
        IF OLD.processing_status IS DISTINCT FROM NEW.processing_status THEN
            CASE NEW.processing_status
                WHEN 'processing' THEN
                    -- Mark processing start time if not set
                    IF NEW.processed_at IS NULL THEN
                        NEW.processed_at := NOW();
                    END IF;
                    
                WHEN 'completed' THEN
                    -- Calculate processing duration
                    IF NEW.processing_duration_ms IS NULL AND NEW.processed_at IS NOT NULL THEN
                        NEW.processing_duration_ms := 
                            EXTRACT(EPOCH FROM (NOW() - NEW.processed_at)) * 1000;
                    END IF;
                    
                WHEN 'failed' THEN
                    -- Increment error count
                    NEW.error_count := COALESCE(NEW.error_count, 0) + 1;
                    
                    -- Schedule retry for certain message types
                    IF NEW.message_type IN ('fronting_change', 'system_update') 
                       AND NEW.error_count < 3 THEN
                        -- Create retry message
                        INSERT INTO background_messages (
                            user_id, device_id, message_type, title, body,
                            data_payload, processing_status
                        ) VALUES (
                            NEW.user_id, NEW.device_id, NEW.message_type,
                            NEW.title, NEW.body, NEW.data_payload, 'pending'
                        );
                    END IF;
            END CASE;
        END IF;
        
        RETURN NEW;
        
    ELSIF TG_OP = 'DELETE' THEN
        -- Log message deletion
        INSERT INTO app_lifecycle_events (
            user_id, device_id, event_type, metadata
        ) VALUES (
            OLD.user_id, OLD.device_id, 'background_message_deleted',
            jsonb_build_object(
                'message_id', OLD.id,
                'message_type', OLD.message_type,
                'processing_status', OLD.processing_status
            )
        );
        
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$;

-- Create background message triggers
CREATE TRIGGER background_messages_trigger
    BEFORE INSERT OR UPDATE OR DELETE ON background_messages
    FOR EACH ROW
    EXECUTE FUNCTION background_messages_trigger();

-- =============================================================================
-- AUTOMATED CLEANUP AND MAINTENANCE
-- =============================================================================

-- Function to cleanup old data automatically
CREATE OR REPLACE FUNCTION automated_cleanup()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    cleanup_results RECORD;
    total_cleaned INTEGER := 0;
    rows_affected INTEGER;
BEGIN
    -- Clean up old connectivity logs (older than 30 days)
    DELETE FROM connectivity_logs 
    WHERE recorded_at < NOW() - INTERVAL '30 days';
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    total_cleaned := total_cleaned + rows_affected;
    
    -- Clean up old lifecycle events (older than 90 days)
    DELETE FROM app_lifecycle_events 
    WHERE event_timestamp < NOW() - INTERVAL '90 days';
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    total_cleaned := total_cleaned + rows_affected;
    
    -- Clean up completed background messages (older than 7 days)
    DELETE FROM background_messages 
    WHERE processing_status = 'completed' 
    AND processed_at < NOW() - INTERVAL '7 days';
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    total_cleaned := total_cleaned + rows_affected;
    
    -- Clean up old initialization logs (older than 30 days)
    DELETE FROM app_initialization_logs 
    WHERE created_at < NOW() - INTERVAL '30 days';
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    total_cleaned := total_cleaned + rows_affected;
    
    -- Clean up old push notification analytics (older than 180 days)
    DELETE FROM push_notification_analytics 
    WHERE created_at < NOW() - INTERVAL '180 days';
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    total_cleaned := total_cleaned + rows_affected;
    
    -- Clean up inactive sessions (older than 7 days)
    DELETE FROM user_sessions 
    WHERE is_active = false 
    AND session_end < NOW() - INTERVAL '7 days';
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    total_cleaned := total_cleaned + rows_affected;
    
    -- Update device last seen for inactive devices
    UPDATE user_devices SET
        is_active = false,
        updated_at = NOW()
    WHERE last_seen_at < NOW() - INTERVAL '30 days'
    AND is_active = true;
    
    -- Log cleanup completion
    INSERT INTO app_lifecycle_events (
        user_id, device_id, event_type, metadata
    ) VALUES (
        NULL, NULL, 'automated_cleanup_completed',
        jsonb_build_object(
            'records_cleaned', total_cleaned,
            'cleanup_timestamp', NOW()
        )
    );
    
    -- Refresh materialized views
    BEGIN
        REFRESH MATERIALIZED VIEW daily_app_metrics;
    EXCEPTION WHEN undefined_table THEN
        -- View doesn't exist, ignore error
        NULL;
    END;
END;
$$;

-- Function to update daily metrics
CREATE OR REPLACE FUNCTION update_daily_metrics()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Refresh daily metrics materialized view
    BEGIN
        REFRESH MATERIALIZED VIEW daily_app_metrics;
    EXCEPTION WHEN undefined_table THEN
        -- View doesn't exist, ignore error
        NULL;
    END;
    
    -- Update app configuration with current stats
    INSERT INTO app_configurations (
        config_key, config_value, config_type, description
    ) VALUES (
        'last_metrics_update', to_jsonb(NOW()), 'system',
        'Timestamp of last metrics update'
    )
    ON CONFLICT (config_key)
    DO UPDATE SET
        config_value = EXCLUDED.config_value,
        updated_at = NOW();
END;
$$;

-- =============================================================================
-- SESSION TIMEOUT AUTOMATION
-- =============================================================================

-- Function to handle session timeouts
CREATE OR REPLACE FUNCTION handle_session_timeouts()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_expired_sessions INTEGER := 0;
    session_record RECORD;
BEGIN
    -- Find and handle expired sessions
    FOR session_record IN
        SELECT s.id, s.user_id, s.device_id, s.inactivity_timeout_minutes
        FROM user_sessions s
        WHERE s.is_active = true
        AND s.last_activity < NOW() - (s.inactivity_timeout_minutes || ' minutes')::INTERVAL
    LOOP
        -- End the expired session
        PERFORM end_user_session(
            session_record.user_id, 
            session_record.device_id, 
            session_record.id, 
            'session_timeout'
        );
        
        v_expired_sessions := v_expired_sessions + 1;
    END LOOP;
    
    RETURN v_expired_sessions;
END;
$$;

-- =============================================================================
-- REALTIME SUBSCRIPTION HELPERS
-- =============================================================================

-- Function to setup realtime subscriptions
CREATE OR REPLACE FUNCTION setup_realtime_subscriptions()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Enable realtime for key tables
    -- Note: This would typically be done through Supabase dashboard or CLI
    
    -- Log the setup
    INSERT INTO app_lifecycle_events (
        user_id, device_id, event_type, metadata
    ) VALUES (
        NULL, NULL, 'realtime_subscriptions_setup',
        jsonb_build_object(
            'timestamp', NOW(),
            'tables_enabled', ARRAY[
                'app_states', 'fronting_changes', 'user_sessions',
                'background_messages', 'error_reports'
            ]
        )
    );
END;
$$;

-- =============================================================================
-- GRANT PERMISSIONS
-- =============================================================================

-- Grant execute permissions for automation functions
GRANT EXECUTE ON FUNCTION send_realtime_notification TO authenticated;
GRANT EXECUTE ON FUNCTION update_multi_user_device_stats TO authenticated;
GRANT EXECUTE ON FUNCTION automated_cleanup TO service_role;
GRANT EXECUTE ON FUNCTION update_daily_metrics TO service_role;
GRANT EXECUTE ON FUNCTION handle_session_timeouts TO service_role;
GRANT EXECUTE ON FUNCTION setup_realtime_subscriptions TO service_role;

-- =============================================================================
-- SCHEDULED JOBS SETUP
-- =============================================================================

-- Note: These would typically be set up as cron jobs or scheduled functions
-- Examples shown as comments for documentation:

-- Daily cleanup (run at 2 AM)
-- SELECT cron.schedule('daily-cleanup', '0 2 * * *', 'SELECT automated_cleanup();');

-- Handle session timeouts (run every 15 minutes)  
-- SELECT cron.schedule('session-timeouts', '0,15,30,45 * * * *', 'SELECT handle_session_timeouts();');

-- Update daily metrics (run at midnight)
-- SELECT cron.schedule('daily-metrics', '0 0 * * *', 'SELECT update_daily_metrics();');

-- Refresh materialized views (run every hour)
-- SELECT cron.schedule('refresh-views', '0 * * * *', 'REFRESH MATERIALIZED VIEW daily_app_metrics;');

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON FUNCTION app_state_change_trigger IS 'Handles app state changes and sends realtime notifications';
COMMENT ON FUNCTION user_device_trigger IS 'Manages device registration and multi-user tracking';
COMMENT ON FUNCTION user_session_trigger IS 'Handles session lifecycle and security monitoring';
COMMENT ON FUNCTION fronting_changes_trigger IS 'Processes fronting changes and notifications';
COMMENT ON FUNCTION error_reports_trigger IS 'Manages error reporting and alerting';
COMMENT ON FUNCTION background_messages_trigger IS 'Handles background message processing';
COMMENT ON FUNCTION automated_cleanup IS 'Performs automated cleanup of old data';
COMMENT ON FUNCTION handle_session_timeouts IS 'Handles expired user sessions';
COMMENT ON FUNCTION send_realtime_notification IS 'Sends realtime notifications via pg_notify';

-- Setup completion message
SELECT 'Main App Triggers and Automation Setup Complete!' as status, NOW() as setup_completed_at;
