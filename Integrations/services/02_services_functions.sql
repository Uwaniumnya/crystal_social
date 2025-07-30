-- Crystal Social Services System - Business Logic Functions
-- File: 02_services_functions.sql
-- Purpose: Stored procedures and functions for service operations

-- =============================================================================
-- DEVICE REGISTRATION FUNCTIONS
-- =============================================================================

-- Register or update a device for a user
CREATE OR REPLACE FUNCTION register_user_device(
    p_user_id UUID,
    p_device_id VARCHAR(255),
    p_fcm_token TEXT,
    p_device_info JSONB DEFAULT '{}',
    p_platform VARCHAR(50) DEFAULT NULL,
    p_app_version VARCHAR(50) DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_existing_device user_devices%ROWTYPE;
    v_device_count INTEGER;
    v_result JSON;
BEGIN
    -- Check if device already exists for this user
    SELECT * INTO v_existing_device
    FROM user_devices 
    WHERE user_id = p_user_id AND device_id = p_device_id;
    
    IF FOUND THEN
        -- Update existing device registration
        UPDATE user_devices SET
            fcm_token = p_fcm_token,
            device_info = p_device_info,
            platform = COALESCE(p_platform, platform),
            app_version = COALESCE(p_app_version, app_version),
            is_active = true,
            last_active = NOW(),
            updated_at = NOW()
        WHERE user_id = p_user_id AND device_id = p_device_id;
        
        v_result := json_build_object(
            'success', true,
            'action', 'updated',
            'message', 'Device registration updated successfully',
            'device_id', p_device_id
        );
    ELSE
        -- Check device limit per user
        SELECT COUNT(*) INTO v_device_count
        FROM user_devices
        WHERE user_id = p_user_id AND is_active = true;
        
        IF v_device_count >= (
            SELECT config_value::INTEGER 
            FROM service_configurations 
            WHERE service_name = 'push_notifications' 
            AND config_key = 'max_devices_per_user'
            AND environment = 'production'
        ) THEN
            v_result := json_build_object(
                'success', false,
                'error', 'device_limit_exceeded',
                'message', 'Maximum number of devices exceeded for user'
            );
        ELSE
            -- Insert new device registration
            INSERT INTO user_devices (
                user_id, device_id, fcm_token, device_info, 
                platform, app_version, is_active, 
                first_login, last_active, created_at, updated_at
            ) VALUES (
                p_user_id, p_device_id, p_fcm_token, p_device_info,
                p_platform, p_app_version, true,
                NOW(), NOW(), NOW(), NOW()
            );
            
            v_result := json_build_object(
                'success', true,
                'action', 'created',
                'message', 'Device registered successfully',
                'device_id', p_device_id
            );
        END IF;
    END IF;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Deactivate a device for a user
CREATE OR REPLACE FUNCTION deactivate_user_device(
    p_user_id UUID,
    p_device_id VARCHAR(255)
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
    v_affected_rows INTEGER;
BEGIN
    UPDATE user_devices SET
        is_active = false,
        last_active = NOW(),
        updated_at = NOW()
    WHERE user_id = p_user_id AND device_id = p_device_id;
    
    GET DIAGNOSTICS v_affected_rows = ROW_COUNT;
    
    IF v_affected_rows > 0 THEN
        v_result := json_build_object(
            'success', true,
            'message', 'Device deactivated successfully',
            'device_id', p_device_id
        );
    ELSE
        v_result := json_build_object(
            'success', false,
            'error', 'device_not_found',
            'message', 'Device not found for user'
        );
    END IF;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get all active devices for a user
CREATE OR REPLACE FUNCTION get_user_active_devices(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_agg(
        json_build_object(
            'id', id,
            'device_id', device_id,
            'fcm_token', fcm_token,
            'platform', platform,
            'app_version', app_version,
            'device_info', device_info,
            'last_active', last_active,
            'first_login', first_login
        )
    ) INTO v_result
    FROM user_devices
    WHERE user_id = p_user_id AND is_active = true
    ORDER BY last_active DESC;
    
    RETURN COALESCE(v_result, '[]'::json);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- DEVICE USER TRACKING FUNCTIONS
-- =============================================================================

-- Track user login on device
CREATE OR REPLACE FUNCTION track_device_user_login(
    p_device_identifier VARCHAR(255),
    p_user_id UUID
)
RETURNS JSON AS $$
DECLARE
    v_existing_record device_user_history%ROWTYPE;
    v_is_first_user BOOLEAN := false;
    v_user_count INTEGER;
    v_result JSON;
BEGIN
    -- Check if this is the first user on this device
    SELECT COUNT(*) INTO v_user_count
    FROM device_user_history
    WHERE device_identifier = p_device_identifier;
    
    IF v_user_count = 0 THEN
        v_is_first_user := true;
    END IF;
    
    -- Clear current user flag for all users on this device
    UPDATE device_user_history SET
        is_current_user = false,
        updated_at = NOW()
    WHERE device_identifier = p_device_identifier;
    
    -- Check if user already exists in history for this device
    SELECT * INTO v_existing_record
    FROM device_user_history
    WHERE device_identifier = p_device_identifier AND user_id = p_user_id;
    
    IF FOUND THEN
        -- Update existing record
        UPDATE device_user_history SET
            is_current_user = true,
            login_count = login_count + 1,
            last_login = NOW(),
            updated_at = NOW()
        WHERE device_identifier = p_device_identifier AND user_id = p_user_id;
    ELSE
        -- Insert new record
        INSERT INTO device_user_history (
            device_identifier, user_id, is_current_user, is_first_user,
            login_count, first_login, last_login, created_at, updated_at
        ) VALUES (
            p_device_identifier, p_user_id, true, v_is_first_user,
            1, NOW(), NOW(), NOW(), NOW()
        );
    END IF;
    
    -- Get updated user count
    SELECT COUNT(*) INTO v_user_count
    FROM device_user_history
    WHERE device_identifier = p_device_identifier;
    
    v_result := json_build_object(
        'success', true,
        'message', 'User login tracked successfully',
        'is_first_user', v_is_first_user,
        'total_users_on_device', v_user_count,
        'has_multiple_users', v_user_count > 1
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Track user logout on device
CREATE OR REPLACE FUNCTION track_device_user_logout(
    p_device_identifier VARCHAR(255),
    p_user_id UUID
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
    v_affected_rows INTEGER;
BEGIN
    UPDATE device_user_history SET
        is_current_user = false,
        last_logout = NOW(),
        updated_at = NOW()
    WHERE device_identifier = p_device_identifier AND user_id = p_user_id;
    
    GET DIAGNOSTICS v_affected_rows = ROW_COUNT;
    
    IF v_affected_rows > 0 THEN
        v_result := json_build_object(
            'success', true,
            'message', 'User logout tracked successfully'
        );
    ELSE
        v_result := json_build_object(
            'success', false,
            'error', 'user_not_found',
            'message', 'User not found in device history'
        );
    END IF;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user should be auto-logged out
CREATE OR REPLACE FUNCTION should_auto_logout_user(
    p_device_identifier VARCHAR(255),
    p_user_id UUID
)
RETURNS JSON AS $$
DECLARE
    v_user_count INTEGER;
    v_is_first_user BOOLEAN := false;
    v_auto_logout_enabled BOOLEAN;
    v_should_logout BOOLEAN := false;
    v_result JSON;
BEGIN
    -- Check if auto-logout is enabled
    SELECT config_value::BOOLEAN INTO v_auto_logout_enabled
    FROM service_configurations
    WHERE service_name = 'user_tracking'
    AND config_key = 'auto_logout_enabled'
    AND environment = 'production';
    
    IF NOT v_auto_logout_enabled THEN
        v_result := json_build_object(
            'should_auto_logout', false,
            'reason', 'auto_logout_disabled'
        );
        RETURN v_result;
    END IF;
    
    -- Get user count and check if first user
    SELECT COUNT(*) INTO v_user_count
    FROM device_user_history
    WHERE device_identifier = p_device_identifier;
    
    SELECT is_first_user INTO v_is_first_user
    FROM device_user_history
    WHERE device_identifier = p_device_identifier AND user_id = p_user_id;
    
    -- Apply auto-logout logic: logout if multiple users and current user is not the first user
    IF v_user_count > 1 AND NOT COALESCE(v_is_first_user, false) THEN
        v_should_logout := true;
    END IF;
    
    v_result := json_build_object(
        'should_auto_logout', v_should_logout,
        'total_users_on_device', v_user_count,
        'is_first_user', COALESCE(v_is_first_user, false),
        'auto_logout_enabled', v_auto_logout_enabled,
        'reason', CASE 
            WHEN v_should_logout THEN 'multiple_users_security'
            WHEN v_user_count = 1 THEN 'only_user'
            WHEN v_is_first_user THEN 'first_user_privilege'
            ELSE 'no_logout_required'
        END
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- PUSH NOTIFICATION FUNCTIONS
-- =============================================================================

-- Send notification to all user devices
CREATE OR REPLACE FUNCTION send_notification_to_user(
    p_receiver_user_id UUID,
    p_notification_type VARCHAR(100),
    p_title VARCHAR(500),
    p_body TEXT,
    p_data JSONB DEFAULT '{}',
    p_sender_user_id UUID DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_notification_id UUID;
    v_devices RECORD;
    v_device_count INTEGER := 0;
    v_type_id INTEGER;
    v_result JSON;
BEGIN
    -- Get notification type ID
    SELECT id INTO v_type_id
    FROM notification_types
    WHERE name = p_notification_type AND is_enabled = true;
    
    IF v_type_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'invalid_notification_type',
            'message', 'Notification type not found or disabled'
        );
    END IF;
    
    -- Count active devices for the user
    SELECT COUNT(*) INTO v_device_count
    FROM user_devices
    WHERE user_id = p_receiver_user_id AND is_active = true AND fcm_token IS NOT NULL;
    
    IF v_device_count = 0 THEN
        RETURN json_build_object(
            'success', false,
            'error', 'no_active_devices',
            'message', 'No active devices found for user'
        );
    END IF;
    
    -- Create notification log entry
    INSERT INTO notification_logs (
        receiver_user_id, sender_user_id, notification_type_id,
        title, body, data, devices_targeted, status, created_at
    ) VALUES (
        p_receiver_user_id, p_sender_user_id, v_type_id,
        p_title, p_body, p_data, v_device_count, 'pending', NOW()
    ) RETURNING id INTO v_notification_id;
    
    -- Create device log entries for each active device
    INSERT INTO notification_device_logs (
        notification_log_id, device_id, fcm_token, status, created_at
    )
    SELECT 
        v_notification_id, ud.id, ud.fcm_token, 'pending', NOW()
    FROM user_devices ud
    WHERE ud.user_id = p_receiver_user_id 
    AND ud.is_active = true 
    AND ud.fcm_token IS NOT NULL;
    
    -- Update notification status to sent
    UPDATE notification_logs SET
        status = 'sent',
        sent_at = NOW()
    WHERE id = v_notification_id;
    
    v_result := json_build_object(
        'success', true,
        'notification_id', v_notification_id,
        'devices_targeted', v_device_count,
        'message', 'Notification queued for delivery'
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update notification delivery status
CREATE OR REPLACE FUNCTION update_notification_delivery_status(
    p_device_log_id UUID,
    p_status VARCHAR(50),
    p_response_data JSONB DEFAULT '{}',
    p_error_code VARCHAR(100) DEFAULT NULL,
    p_error_message TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_notification_log_id UUID;
    v_delivered_count INTEGER;
    v_failed_count INTEGER;
    v_total_count INTEGER;
    v_result JSON;
BEGIN
    -- Update device log status
    UPDATE notification_device_logs SET
        status = p_status,
        response_data = p_response_data,
        error_code = p_error_code,
        error_message = p_error_message,
        delivered_at = CASE WHEN p_status = 'delivered' THEN NOW() ELSE delivered_at END,
        sent_at = CASE WHEN p_status IN ('sent', 'delivered') THEN COALESCE(sent_at, NOW()) ELSE sent_at END
    WHERE id = p_device_log_id
    RETURNING notification_log_id INTO v_notification_log_id;
    
    -- Update notification log summary
    SELECT 
        COUNT(*) FILTER (WHERE status = 'delivered') as delivered,
        COUNT(*) FILTER (WHERE status = 'failed') as failed,
        COUNT(*) as total
    INTO v_delivered_count, v_failed_count, v_total_count
    FROM notification_device_logs
    WHERE notification_log_id = v_notification_log_id;
    
    UPDATE notification_logs SET
        devices_delivered = v_delivered_count,
        devices_failed = v_failed_count,
        status = CASE 
            WHEN v_delivered_count + v_failed_count = v_total_count THEN 'delivered'
            WHEN v_failed_count = v_total_count THEN 'failed'
            ELSE 'sent'
        END,
        delivered_at = CASE 
            WHEN v_delivered_count + v_failed_count = v_total_count THEN NOW()
            ELSE delivered_at
        END
    WHERE id = v_notification_log_id;
    
    v_result := json_build_object(
        'success', true,
        'notification_log_id', v_notification_log_id,
        'devices_delivered', v_delivered_count,
        'devices_failed', v_failed_count,
        'delivery_complete', v_delivered_count + v_failed_count = v_total_count
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- GLIMMER SERVICE FUNCTIONS
-- =============================================================================

-- Create a new Glimmer post
CREATE OR REPLACE FUNCTION create_glimmer_post(
    p_user_id UUID,
    p_title VARCHAR(500),
    p_description TEXT,
    p_image_url TEXT,
    p_image_path TEXT,
    p_category_name VARCHAR(100),
    p_tags TEXT[] DEFAULT '{}'
)
RETURNS JSON AS $$
DECLARE
    v_post_id UUID;
    v_category_id INTEGER;
    v_result JSON;
BEGIN
    -- Get category ID
    SELECT id INTO v_category_id
    FROM glimmer_categories
    WHERE name = p_category_name AND is_active = true;
    
    IF v_category_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'invalid_category',
            'message', 'Category not found or inactive'
        );
    END IF;
    
    -- Insert the post
    INSERT INTO glimmer_posts (
        user_id, title, description, image_url, image_path,
        category_id, tags, is_published, created_at, updated_at
    ) VALUES (
        p_user_id, p_title, p_description, p_image_url, p_image_path,
        v_category_id, p_tags, true, NOW(), NOW()
    ) RETURNING id INTO v_post_id;
    
    v_result := json_build_object(
        'success', true,
        'post_id', v_post_id,
        'message', 'Glimmer post created successfully'
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Like or unlike a Glimmer post
CREATE OR REPLACE FUNCTION toggle_glimmer_post_like(
    p_post_id UUID,
    p_user_id UUID
)
RETURNS JSON AS $$
DECLARE
    v_existing_like UUID;
    v_action VARCHAR(10);
    v_like_count INTEGER;
    v_result JSON;
BEGIN
    -- Check if like already exists
    SELECT id INTO v_existing_like
    FROM glimmer_post_likes
    WHERE post_id = p_post_id AND user_id = p_user_id;
    
    IF FOUND THEN
        -- Remove like
        DELETE FROM glimmer_post_likes
        WHERE id = v_existing_like;
        v_action := 'unliked';
    ELSE
        -- Add like
        INSERT INTO glimmer_post_likes (post_id, user_id, created_at)
        VALUES (p_post_id, p_user_id, NOW());
        v_action := 'liked';
    END IF;
    
    -- Update like count on post
    SELECT COUNT(*) INTO v_like_count
    FROM glimmer_post_likes
    WHERE post_id = p_post_id;
    
    UPDATE glimmer_posts SET
        like_count = v_like_count,
        updated_at = NOW()
    WHERE id = p_post_id;
    
    v_result := json_build_object(
        'success', true,
        'action', v_action,
        'like_count', v_like_count,
        'message', 'Post ' || v_action || ' successfully'
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add comment to Glimmer post
CREATE OR REPLACE FUNCTION add_glimmer_post_comment(
    p_post_id UUID,
    p_user_id UUID,
    p_content TEXT,
    p_parent_comment_id UUID DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_comment_id UUID;
    v_comment_count INTEGER;
    v_result JSON;
BEGIN
    -- Insert comment
    INSERT INTO glimmer_post_comments (
        post_id, user_id, content, parent_comment_id, created_at, updated_at
    ) VALUES (
        p_post_id, p_user_id, p_content, p_parent_comment_id, NOW(), NOW()
    ) RETURNING id INTO v_comment_id;
    
    -- Update comment count on post
    SELECT COUNT(*) INTO v_comment_count
    FROM glimmer_post_comments
    WHERE post_id = p_post_id AND is_approved = true;
    
    UPDATE glimmer_posts SET
        comment_count = v_comment_count,
        updated_at = NOW()
    WHERE id = p_post_id;
    
    v_result := json_build_object(
        'success', true,
        'comment_id', v_comment_id,
        'comment_count', v_comment_count,
        'message', 'Comment added successfully'
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- ANALYTICS AND MAINTENANCE FUNCTIONS
-- =============================================================================

-- Generate daily service analytics
CREATE OR REPLACE FUNCTION generate_daily_service_analytics(
    p_analytics_date DATE DEFAULT CURRENT_DATE
)
RETURNS JSON AS $$
DECLARE
    v_services TEXT[] := ARRAY['device_registration', 'push_notifications', 'user_tracking', 'glimmer_service'];
    v_service_name TEXT;
    v_operations INTEGER;
    v_success_operations INTEGER;
    v_failed_operations INTEGER;
    v_unique_users INTEGER;
    v_avg_response_time DECIMAL;
    v_max_response_time INTEGER;
    v_min_response_time INTEGER;
    v_result JSON;
    v_analytics_count INTEGER := 0;
BEGIN
    -- Process each service
    FOREACH v_service_name IN ARRAY v_services
    LOOP
        -- Get operation metrics
        SELECT 
            COUNT(*),
            COUNT(*) FILTER (WHERE status = 'success'),
            COUNT(*) FILTER (WHERE status IN ('error', 'timeout', 'cancelled')),
            COUNT(DISTINCT user_id),
            AVG(duration_ms),
            MAX(duration_ms),
            MIN(duration_ms)
        INTO v_operations, v_success_operations, v_failed_operations, 
             v_unique_users, v_avg_response_time, v_max_response_time, v_min_response_time
        FROM service_operation_logs
        WHERE service_name = v_service_name
        AND DATE(created_at) = p_analytics_date;
        
        -- Insert or update analytics record
        INSERT INTO daily_service_analytics (
            analytics_date, service_name, total_operations, successful_operations,
            failed_operations, unique_users, avg_response_time_ms,
            max_response_time_ms, min_response_time_ms, created_at, updated_at
        ) VALUES (
            p_analytics_date, v_service_name, v_operations, v_success_operations,
            v_failed_operations, v_unique_users, v_avg_response_time,
            v_max_response_time, v_min_response_time, NOW(), NOW()
        ) ON CONFLICT (analytics_date, service_name) DO UPDATE SET
            total_operations = EXCLUDED.total_operations,
            successful_operations = EXCLUDED.successful_operations,
            failed_operations = EXCLUDED.failed_operations,
            unique_users = EXCLUDED.unique_users,
            avg_response_time_ms = EXCLUDED.avg_response_time_ms,
            max_response_time_ms = EXCLUDED.max_response_time_ms,
            min_response_time_ms = EXCLUDED.min_response_time_ms,
            updated_at = NOW();
            
        v_analytics_count := v_analytics_count + 1;
    END LOOP;
    
    -- Update notification-specific metrics
    UPDATE daily_service_analytics SET
        notifications_sent = (
            SELECT COUNT(*) FROM notification_logs 
            WHERE DATE(created_at) = p_analytics_date
        ),
        notifications_delivered = (
            SELECT COUNT(*) FROM notification_logs 
            WHERE DATE(created_at) = p_analytics_date AND status = 'delivered'
        )
    WHERE analytics_date = p_analytics_date AND service_name = 'push_notifications';
    
    -- Update device metrics
    UPDATE daily_service_analytics SET
        total_devices = (
            SELECT COUNT(*) FROM user_devices 
            WHERE DATE(created_at) <= p_analytics_date
        ),
        active_devices = (
            SELECT COUNT(*) FROM user_devices 
            WHERE is_active = true AND DATE(last_active) = p_analytics_date
        ),
        new_device_registrations = (
            SELECT COUNT(*) FROM user_devices 
            WHERE DATE(created_at) = p_analytics_date
        )
    WHERE analytics_date = p_analytics_date AND service_name = 'device_registration';
    
    v_result := json_build_object(
        'success', true,
        'analytics_date', p_analytics_date,
        'services_processed', v_analytics_count,
        'message', 'Daily analytics generated successfully'
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Cleanup old service data
CREATE OR REPLACE FUNCTION cleanup_service_data()
RETURNS JSON AS $$
DECLARE
    v_notification_cleanup_days INTEGER;
    v_inactive_device_days INTEGER;
    v_operation_log_days INTEGER;
    v_cleaned_notifications INTEGER;
    v_cleaned_devices INTEGER;
    v_cleaned_logs INTEGER;
    v_result JSON;
BEGIN
    -- Get cleanup configuration
    SELECT config_value::INTEGER INTO v_notification_cleanup_days
    FROM service_configurations
    WHERE service_name = 'maintenance' AND config_key = 'max_notification_log_days';
    
    SELECT config_value::INTEGER INTO v_inactive_device_days
    FROM service_configurations
    WHERE service_name = 'maintenance' AND config_key = 'max_inactive_device_days';
    
    v_operation_log_days := 30; -- Default to 30 days for operation logs
    
    -- Cleanup old notification logs
    DELETE FROM notification_logs
    WHERE created_at < NOW() - INTERVAL '1 day' * COALESCE(v_notification_cleanup_days, 90);
    GET DIAGNOSTICS v_cleaned_notifications = ROW_COUNT;
    
    -- Cleanup inactive devices
    DELETE FROM user_devices
    WHERE is_active = false 
    AND last_active < NOW() - INTERVAL '1 day' * COALESCE(v_inactive_device_days, 90);
    GET DIAGNOSTICS v_cleaned_devices = ROW_COUNT;
    
    -- Cleanup old operation logs
    DELETE FROM service_operation_logs
    WHERE created_at < NOW() - INTERVAL '1 day' * v_operation_log_days;
    GET DIAGNOSTICS v_cleaned_logs = ROW_COUNT;
    
    v_result := json_build_object(
        'success', true,
        'cleaned_notifications', v_cleaned_notifications,
        'cleaned_devices', v_cleaned_devices,
        'cleaned_operation_logs', v_cleaned_logs,
        'cleanup_completed_at', NOW()
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- GRANT PERMISSIONS
-- =============================================================================

-- Device registration functions
GRANT EXECUTE ON FUNCTION register_user_device(UUID, VARCHAR, TEXT, JSONB, VARCHAR, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION deactivate_user_device(UUID, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_active_devices(UUID) TO authenticated;

-- Device user tracking functions
GRANT EXECUTE ON FUNCTION track_device_user_login(VARCHAR, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION track_device_user_logout(VARCHAR, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION should_auto_logout_user(VARCHAR, UUID) TO authenticated;

-- Push notification functions
GRANT EXECUTE ON FUNCTION send_notification_to_user(UUID, VARCHAR, VARCHAR, TEXT, JSONB, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_notification_delivery_status(UUID, VARCHAR, JSONB, VARCHAR, TEXT) TO service_role;

-- Glimmer service functions
GRANT EXECUTE ON FUNCTION create_glimmer_post(UUID, VARCHAR, TEXT, TEXT, TEXT, VARCHAR, TEXT[]) TO authenticated;
GRANT EXECUTE ON FUNCTION toggle_glimmer_post_like(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION add_glimmer_post_comment(UUID, UUID, TEXT, UUID) TO authenticated;

-- Analytics and maintenance functions
GRANT EXECUTE ON FUNCTION generate_daily_service_analytics(DATE) TO service_role;
GRANT EXECUTE ON FUNCTION cleanup_service_data() TO service_role;

-- =============================================================================
-- FUNCTION DOCUMENTATION
-- =============================================================================

COMMENT ON FUNCTION register_user_device(UUID, VARCHAR, TEXT, JSONB, VARCHAR, VARCHAR) IS 'Register or update a device for push notifications';
COMMENT ON FUNCTION deactivate_user_device(UUID, VARCHAR) IS 'Deactivate a device when user logs out';
COMMENT ON FUNCTION get_user_active_devices(UUID) IS 'Get all active devices for a user';
COMMENT ON FUNCTION track_device_user_login(VARCHAR, UUID) IS 'Track user login on device for auto-logout functionality';
COMMENT ON FUNCTION track_device_user_logout(VARCHAR, UUID) IS 'Track user logout on device';
COMMENT ON FUNCTION should_auto_logout_user(VARCHAR, UUID) IS 'Check if user should be auto-logged out based on device history';
COMMENT ON FUNCTION send_notification_to_user(UUID, VARCHAR, VARCHAR, TEXT, JSONB, UUID) IS 'Send push notification to all user devices';
COMMENT ON FUNCTION update_notification_delivery_status(UUID, VARCHAR, JSONB, VARCHAR, TEXT) IS 'Update notification delivery status from FCM response';
COMMENT ON FUNCTION create_glimmer_post(UUID, VARCHAR, TEXT, TEXT, TEXT, VARCHAR, TEXT[]) IS 'Create a new Glimmer wall post';
COMMENT ON FUNCTION toggle_glimmer_post_like(UUID, UUID) IS 'Like or unlike a Glimmer post';
COMMENT ON FUNCTION add_glimmer_post_comment(UUID, UUID, TEXT, UUID) IS 'Add comment to Glimmer post';
COMMENT ON FUNCTION generate_daily_service_analytics(DATE) IS 'Generate daily analytics for all services';
COMMENT ON FUNCTION cleanup_service_data() IS 'Clean up old service data according to retention policies';
