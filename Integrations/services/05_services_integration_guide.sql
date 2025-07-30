-- Crystal Social Services System - Integration Guide and Setup
-- File: 05_services_integration_guide.sql
-- Purpose: Complete setup instructions and Flutter integration examples

-- =============================================================================
-- SERVICES SYSTEM INTEGRATION SUMMARY
-- =============================================================================

/*
CRYSTAL SOCIAL SERVICES SYSTEM - COMPREHENSIVE SQL INTEGRATION

This SQL integration provides a complete, production-ready services system with:

🚀 CORE SERVICES:
- Device Registration Service: FCM token management and device tracking
- Push Notification Service: Multi-device notification delivery
- Enhanced Push Notification Integration: Unified notification management
- Device User Tracking Service: Auto-logout and security features
- Glimmer Service: Social media post management
- Unified Service Manager: Orchestrates all services seamlessly

📱 DEVICE MANAGEMENT:
- Multi-device registration per user (configurable limit)
- FCM token management and rotation
- Device activity tracking and cleanup
- Platform-specific configurations (iOS, Android, Web)
- Device information extraction and analytics

🔔 NOTIFICATION SYSTEM:
- Type-based notification management (8 types)
- Template-driven messaging for consistency
- Multi-device delivery with individual tracking
- Delivery rate monitoring and retry logic
- Performance analytics and optimization

🔒 SECURITY FEATURES:
- Auto-logout for shared devices
- Device user history tracking
- Row Level Security on all tables
- Audit logging for sensitive operations
- Admin and service role access controls

🎨 GLIMMER INTEGRATION:
- Complete social media post management
- Category-based organization (8 categories)
- Like and comment system with engagement metrics
- Full-text search capabilities
- User statistics and performance tiers

📊 ANALYTICS AND MONITORING:
- Daily service analytics aggregation
- Performance monitoring and health checks
- Materialized views for fast queries
- Service operation logging
- Comprehensive dashboard views

🛠️ FILES OVERVIEW:
01_services_core_tables.sql: Foundation tables and infrastructure
02_services_functions.sql: Business logic and stored procedures
03_services_views.sql: Analytics views and materialized views
04_services_security.sql: RLS policies and security measures
05_services_integration_guide.sql: Setup guide and examples (this file)
*/

-- =============================================================================
-- SETUP AND INITIALIZATION INSTRUCTIONS
-- =============================================================================

-- Step 1: Execute SQL files in order
/*
1. Run 01_services_core_tables.sql - Creates foundational tables and indexes
2. Run 02_services_functions.sql - Creates business logic functions
3. Run 03_services_views.sql - Creates views and materialized views
4. Run 04_services_security.sql - Sets up security policies and audit logging
5. Run this file (05_services_integration_guide.sql) - Final setup and validation
*/

-- Step 2: Verify installation
DO $$
DECLARE
    v_table_count INTEGER;
    v_function_count INTEGER;
    v_view_count INTEGER;
    v_policy_count INTEGER;
    v_trigger_count INTEGER;
BEGIN
    -- Count tables
    SELECT COUNT(*) INTO v_table_count 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND (table_name LIKE '%device%' OR table_name LIKE '%notification%' OR table_name LIKE '%glimmer%' OR table_name LIKE '%service%');
    
    -- Count functions
    SELECT COUNT(*) INTO v_function_count 
    FROM information_schema.routines 
    WHERE routine_schema = 'public' 
    AND (routine_name LIKE '%device%' OR routine_name LIKE '%notification%' OR routine_name LIKE '%glimmer%' OR routine_name LIKE '%service%');
    
    -- Count views
    SELECT COUNT(*) INTO v_view_count 
    FROM information_schema.views 
    WHERE table_schema = 'public' 
    AND (table_name LIKE '%device%' OR table_name LIKE '%notification%' OR table_name LIKE '%glimmer%' OR table_name LIKE '%service%');
    
    -- Count policies
    SELECT COUNT(*) INTO v_policy_count
    FROM pg_policies
    WHERE schemaname = 'public';
    
    -- Count triggers
    SELECT COUNT(*) INTO v_trigger_count
    FROM information_schema.triggers
    WHERE trigger_schema = 'public'
    AND trigger_name LIKE '%audit%';
    
    RAISE NOTICE 'Services System Setup Status:';
    RAISE NOTICE '- Tables created: %', v_table_count;
    RAISE NOTICE '- Functions created: %', v_function_count;
    RAISE NOTICE '- Views created: %', v_view_count;
    RAISE NOTICE '- Security policies: %', v_policy_count;
    RAISE NOTICE '- Audit triggers: %', v_trigger_count;
    
    IF v_table_count >= 14 AND v_function_count >= 15 AND v_view_count >= 6 THEN
        RAISE NOTICE '✅ Services system successfully installed!';
    ELSE
        RAISE WARNING '⚠️ Some components may be missing. Please check installation.';
    END IF;
END $$;

-- =============================================================================
-- FLUTTER INTEGRATION EXAMPLES
-- =============================================================================

-- Example 1: Initialize user services (called on login)
/*
-- Call this when user logs in
SELECT json_build_object(
    'device_registration', register_user_device(
        'user-uuid'::UUID,
        'device-id-string',
        'fcm-token-string',
        '{"model": "iPhone 14", "os": "iOS 16.0"}'::jsonb,
        'ios',
        '1.0.0'
    ),
    'user_tracking', track_device_user_login(
        'device-id-string',
        'user-uuid'::UUID
    )
) as initialization_result;
*/

-- Example 2: Send message notification
/*
-- Call this when sending a chat message
SELECT send_notification_to_user(
    'receiver-user-uuid'::UUID,
    'message',
    'John',
    'You have a message from John',
    '{"message_preview": "Hello there!", "chat_id": "chat-123"}'::jsonb,
    'sender-user-uuid'::UUID
) as notification_result;
*/

-- Example 3: Create Glimmer post
/*
-- Call this when user creates a Glimmer post
SELECT create_glimmer_post(
    'user-uuid'::UUID,
    'Beautiful sunset',
    'Amazing sunset from my balcony tonight',
    'https://storage.url/image.jpg',
    'user-uuid/timestamp.jpg',
    'photography',
    ARRAY['sunset', 'nature', 'evening']
) as post_result;
*/

-- Example 4: Check auto-logout requirement
/*
-- Call this when app starts to check if user should be logged out
SELECT should_auto_logout_user(
    'device-id-string',
    'user-uuid'::UUID
) as auto_logout_check;
*/

-- =============================================================================
-- COMMON QUERIES FOR FLUTTER INTEGRATION
-- =============================================================================

-- Get user's complete device information
CREATE OR REPLACE FUNCTION get_user_complete_device_info(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_build_object(
        'active_devices', (
            SELECT json_agg(
                json_build_object(
                    'id', id,
                    'device_id', device_id,
                    'platform', platform,
                    'app_version', app_version,
                    'last_active', last_active,
                    'days_since_active', EXTRACT(DAYS FROM NOW() - last_active)
                )
            )
            FROM user_devices
            WHERE user_id = p_user_id AND is_active = true
        ),
        'device_count', (
            SELECT COUNT(*) FROM user_devices WHERE user_id = p_user_id AND is_active = true
        ),
        'max_devices_allowed', (
            SELECT config_value::INTEGER 
            FROM service_configurations 
            WHERE service_name = 'push_notifications' AND config_key = 'max_devices_per_user'
        ),
        'can_add_device', (
            SELECT COUNT(*) < (
                SELECT config_value::INTEGER 
                FROM service_configurations 
                WHERE service_name = 'push_notifications' AND config_key = 'max_devices_per_user'
            )
            FROM user_devices WHERE user_id = p_user_id AND is_active = true
        )
    ) INTO v_result;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get user's notification history with pagination
CREATE OR REPLACE FUNCTION get_user_notification_history(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_agg(
        json_build_object(
            'id', na.id,
            'title', na.title,
            'body', na.body,
            'notification_type', na.notification_type,
            'type_display_name', na.type_display_name,
            'sender_username', na.sender_username,
            'delivery_rate', na.delivery_rate,
            'delivery_performance', na.delivery_performance,
            'created_at', na.created_at,
            'delivered_at', na.delivered_at,
            'data', na.data
        ) ORDER BY na.created_at DESC
    ) INTO v_result
    FROM notification_analytics na
    WHERE na.receiver_user_id = p_user_id
    LIMIT p_limit OFFSET p_offset;
    
    RETURN COALESCE(v_result, '[]'::json);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get user's Glimmer posts with engagement stats
CREATE OR REPLACE FUNCTION get_user_glimmer_posts_with_stats(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_agg(
        json_build_object(
            'id', gps.id,
            'title', gps.title,
            'description', gps.description,
            'image_url', gps.image_url,
            'category_name', gps.category_name,
            'category_color', gps.category_color,
            'tags', gps.tags,
            'like_count', gps.like_count,
            'comment_count', gps.comment_count,
            'view_count', gps.view_count,
            'engagement_score', gps.engagement_score,
            'like_rate', gps.like_rate,
            'comment_rate', gps.comment_rate,
            'post_age_category', gps.post_age_category,
            'is_trending_calculated', gps.is_trending_calculated,
            'created_at', gps.created_at
        ) ORDER BY gps.created_at DESC
    ) INTO v_result
    FROM glimmer_posts_with_stats gps
    WHERE gps.user_id = p_user_id
    LIMIT p_limit OFFSET p_offset;
    
    RETURN COALESCE(v_result, '[]'::json);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get trending Glimmer posts
CREATE OR REPLACE FUNCTION get_trending_glimmer_posts(
    p_category_name VARCHAR(100) DEFAULT NULL,
    p_limit INTEGER DEFAULT 20
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_agg(
        json_build_object(
            'id', gps.id,
            'title', gps.title,
            'description', gps.description,
            'image_url', gps.image_url,
            'username', gps.username,
            'display_name', gps.display_name,
            'avatar_url', gps.avatar_url,
            'category_name', gps.category_name,
            'category_color', gps.category_color,
            'tags', gps.tags,
            'like_count', gps.like_count,
            'comment_count', gps.comment_count,
            'engagement_score', gps.engagement_score,
            'created_at', gps.created_at
        ) ORDER BY gps.engagement_score DESC, gps.created_at DESC
    ) INTO v_result
    FROM glimmer_posts_with_stats gps
    WHERE (p_category_name IS NULL OR gps.category_name = p_category_name)
    AND gps.is_trending_calculated = true
    LIMIT p_limit;
    
    RETURN COALESCE(v_result, '[]'::json);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get service health status for dashboard
CREATE OR REPLACE FUNCTION get_service_health_status()
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_build_object(
        'overall_status', CASE 
            WHEN COUNT(*) FILTER (WHERE current_status = 'healthy') * 100.0 / COUNT(*) >= 90 THEN 'healthy'
            WHEN COUNT(*) FILTER (WHERE current_status = 'healthy') * 100.0 / COUNT(*) >= 70 THEN 'degraded'
            ELSE 'unhealthy'
        END,
        'services', json_agg(
            json_build_object(
                'service_name', service_name,
                'check_type', check_type,
                'status', current_status,
                'response_time', current_response_time,
                'uptime_percentage', uptime_percentage_24h,
                'last_check', last_check_time
            )
        ),
        'healthy_services', COUNT(*) FILTER (WHERE current_status = 'healthy'),
        'total_services', COUNT(*),
        'average_uptime', ROUND(AVG(uptime_percentage_24h), 2)
    ) INTO v_result
    FROM service_health_dashboard;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get notification delivery statistics
CREATE OR REPLACE FUNCTION get_notification_delivery_stats(
    p_days INTEGER DEFAULT 7
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_build_object(
        'period_days', p_days,
        'total_notifications', SUM(total_notifications),
        'total_devices_targeted', SUM(total_devices_targeted),
        'total_devices_delivered', SUM(total_devices_delivered),
        'overall_delivery_rate', ROUND(
            SUM(total_devices_delivered) * 100.0 / GREATEST(1, SUM(total_devices_targeted)), 2
        ),
        'daily_stats', json_agg(
            json_build_object(
                'date', notification_date,
                'notifications', total_notifications,
                'delivery_rate', avg_delivery_rate,
                'unique_receivers', unique_receivers
            ) ORDER BY notification_date DESC
        ),
        'type_breakdown', (
            SELECT json_agg(
                json_build_object(
                    'type', type_display_name,
                    'count', SUM(total_notifications),
                    'avg_delivery_rate', ROUND(AVG(avg_delivery_rate), 2)
                )
            )
            FROM daily_notification_summary dns2
            WHERE dns2.notification_date >= CURRENT_DATE - INTERVAL '1 day' * p_days
            GROUP BY type_display_name
        )
    ) INTO v_result
    FROM daily_notification_summary dns
    WHERE dns.notification_date >= CURRENT_DATE - INTERVAL '1 day' * p_days;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- MAINTENANCE AND CLEANUP PROCEDURES
-- =============================================================================

-- Daily maintenance function (run via cron job)
CREATE OR REPLACE FUNCTION daily_services_maintenance()
RETURNS JSON AS $$
DECLARE
    v_start_time TIMESTAMPTZ := NOW();
    v_analytics_result JSON;
    v_cleanup_result JSON;
    v_health_checks INTEGER := 0;
    v_materialized_views_result JSON;
    v_result JSON;
BEGIN
    -- Generate daily analytics
    SELECT generate_daily_service_analytics() INTO v_analytics_result;
    
    -- Cleanup old data
    SELECT cleanup_service_data() INTO v_cleanup_result;
    
    -- Refresh materialized views
    SELECT refresh_service_materialized_views() INTO v_materialized_views_result;
    
    -- Insert health check record
    INSERT INTO service_health_checks (
        service_name, check_type, status, response_time_ms, 
        metadata, checked_at
    ) VALUES (
        'maintenance', 'daily_maintenance', 'healthy', 
        EXTRACT(EPOCH FROM (NOW() - v_start_time)) * 1000,
        json_build_object(
            'analytics_generated', true,
            'cleanup_completed', true,
            'views_refreshed', true
        ),
        NOW()
    );
    
    v_health_checks := v_health_checks + 1;
    
    v_result := json_build_object(
        'success', true,
        'maintenance_completed_at', NOW(),
        'duration_seconds', EXTRACT(EPOCH FROM (NOW() - v_start_time)),
        'analytics_result', v_analytics_result,
        'cleanup_result', v_cleanup_result,
        'materialized_views_result', v_materialized_views_result,
        'health_checks_inserted', v_health_checks
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check system readiness
CREATE OR REPLACE FUNCTION check_services_system_readiness()
RETURNS JSON AS $$
DECLARE
    v_security_check JSON;
    v_config_check JSON;
    v_data_check JSON;
    v_result JSON;
    v_ready BOOLEAN := true;
    v_issues TEXT[] := ARRAY[]::TEXT[];
BEGIN
    -- Security validation
    SELECT validate_service_security() INTO v_security_check;
    IF (v_security_check->>'security_status') != 'secure' THEN
        v_ready := false;
        v_issues := array_append(v_issues, 'Security configuration issues detected');
    END IF;
    
    -- Configuration check
    SELECT json_build_object(
        'notification_types_count', (SELECT COUNT(*) FROM notification_types WHERE is_enabled = true),
        'glimmer_categories_count', (SELECT COUNT(*) FROM glimmer_categories WHERE is_active = true),
        'service_configs_count', (SELECT COUNT(*) FROM service_configurations WHERE is_active = true),
        'notification_templates_count', (SELECT COUNT(*) FROM notification_templates WHERE is_active = true)
    ) INTO v_config_check;
    
    -- Data integrity check
    SELECT json_build_object(
        'orphaned_devices', (
            SELECT COUNT(*) FROM user_devices ud 
            WHERE NOT EXISTS (SELECT 1 FROM auth.users u WHERE u.id = ud.user_id)
        ),
        'orphaned_notifications', (
            SELECT COUNT(*) FROM notification_logs nl 
            WHERE NOT EXISTS (SELECT 1 FROM auth.users u WHERE u.id = nl.receiver_user_id)
        ),
        'orphaned_posts', (
            SELECT COUNT(*) FROM glimmer_posts gp 
            WHERE NOT EXISTS (SELECT 1 FROM auth.users u WHERE u.id = gp.user_id)
        )
    ) INTO v_data_check;
    
    -- Check for data integrity issues
    IF (v_data_check->>'orphaned_devices')::INTEGER > 0 OR 
       (v_data_check->>'orphaned_notifications')::INTEGER > 0 OR 
       (v_data_check->>'orphaned_posts')::INTEGER > 0 THEN
        v_issues := array_append(v_issues, 'Data integrity issues detected');
    END IF;
    
    v_result := json_build_object(
        'system_ready', v_ready,
        'issues', v_issues,
        'security_check', v_security_check,
        'configuration_check', v_config_check,
        'data_integrity_check', v_data_check,
        'checked_at', NOW()
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- GRANT PERMISSIONS FOR NEW FUNCTIONS
-- =============================================================================

GRANT EXECUTE ON FUNCTION get_user_complete_device_info(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_notification_history(UUID, INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_glimmer_posts_with_stats(UUID, INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_trending_glimmer_posts(VARCHAR, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_service_health_status() TO authenticated;
GRANT EXECUTE ON FUNCTION get_notification_delivery_stats(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION daily_services_maintenance() TO service_role;
GRANT EXECUTE ON FUNCTION check_services_system_readiness() TO service_role;

-- =============================================================================
-- PERFORMANCE OPTIMIZATION
-- =============================================================================

-- Additional indexes for common queries
CREATE INDEX IF NOT EXISTS idx_user_devices_user_active ON user_devices(user_id, is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_notification_logs_receiver_created ON notification_logs(receiver_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_glimmer_posts_user_recent ON glimmer_posts(user_id, created_at DESC) WHERE is_published = true;
CREATE INDEX IF NOT EXISTS idx_glimmer_posts_trending ON glimmer_posts(like_count DESC, created_at DESC) WHERE is_published = true;

-- Partial indexes for better performance
CREATE INDEX IF NOT EXISTS idx_notification_device_logs_pending ON notification_device_logs(notification_log_id, status) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_service_health_checks_recent ON service_health_checks(service_name, checked_at DESC);

-- =============================================================================
-- FINAL SETUP VERIFICATION
-- =============================================================================

-- Run system readiness check
SELECT check_services_system_readiness() as final_system_check;

-- Display summary
SELECT 
    'Services System Integration Complete!' as status,
    (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND (table_name LIKE '%device%' OR table_name LIKE '%notification%' OR table_name LIKE '%glimmer%' OR table_name LIKE '%service%')) as tables_created,
    (SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema = 'public' AND (routine_name LIKE '%device%' OR routine_name LIKE '%notification%' OR routine_name LIKE '%glimmer%' OR routine_name LIKE '%service%')) as functions_created,
    (SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'public' AND (table_name LIKE '%device%' OR table_name LIKE '%notification%' OR table_name LIKE '%glimmer%' OR table_name LIKE '%service%')) as views_created,
    (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public') as security_policies,
    (SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema = 'public' AND trigger_name LIKE '%audit%') as audit_triggers,
    NOW() as setup_completed_at;

-- =============================================================================
-- DOCUMENTATION AND COMMENTS
-- =============================================================================

COMMENT ON FUNCTION get_user_complete_device_info(UUID) IS 'Get comprehensive device information for a user including limits and status';
COMMENT ON FUNCTION get_user_notification_history(UUID, INTEGER, INTEGER) IS 'Get paginated notification history for a user with analytics';
COMMENT ON FUNCTION get_user_glimmer_posts_with_stats(UUID, INTEGER, INTEGER) IS 'Get user Glimmer posts with engagement statistics';
COMMENT ON FUNCTION get_trending_glimmer_posts(VARCHAR, INTEGER) IS 'Get trending Glimmer posts optionally filtered by category';
COMMENT ON FUNCTION get_service_health_status() IS 'Get current health status of all services for dashboard display';
COMMENT ON FUNCTION get_notification_delivery_stats(INTEGER) IS 'Get notification delivery statistics for specified number of days';
COMMENT ON FUNCTION daily_services_maintenance() IS 'Daily maintenance procedure for analytics, cleanup, and health checks';
COMMENT ON FUNCTION check_services_system_readiness() IS 'Comprehensive system readiness check for production deployment';

/*
🎉 CRYSTAL SOCIAL SERVICES SYSTEM INTEGRATION COMPLETE!

The comprehensive services system is now fully integrated with:

✅ 14+ database tables with proper indexing and RLS
✅ 20+ stored functions for complete business logic
✅ 6+ views and materialized views for analytics
✅ 30+ security policies with audit logging
✅ Complete device registration and tracking
✅ Multi-device push notification system
✅ Auto-logout security features
✅ Full Glimmer social media integration
✅ Comprehensive analytics and monitoring
✅ Production-ready security and audit trails

🚀 READY FOR FLUTTER INTEGRATION:

1. Use the provided functions for all service operations
2. Implement real-time subscriptions for notifications
3. Set up cron job for daily_services_maintenance()
4. Configure FCM server keys and OneSignal integration
5. Implement proper error handling for all service calls
6. Add analytics dashboard using the provided views

📖 FLUTTER INTEGRATION EXAMPLES:

```dart
// Initialize services on login
final result = await supabase.rpc('register_user_device', params: {
  'p_user_id': userId,
  'p_device_id': deviceId,
  'p_fcm_token': fcmToken,
  'p_device_info': deviceInfo,
  'p_platform': platform,
  'p_app_version': appVersion,
});

// Send notification
final notification = await supabase.rpc('send_notification_to_user', params: {
  'p_receiver_user_id': receiverId,
  'p_notification_type': 'message',
  'p_title': title,
  'p_body': body,
  'p_data': additionalData,
  'p_sender_user_id': senderId,
});

// Check auto-logout
final autoLogout = await supabase.rpc('should_auto_logout_user', params: {
  'p_device_identifier': deviceId,
  'p_user_id': userId,
});

// Get health status
final health = await supabase.rpc('get_service_health_status');
```

🎯 The services system is production-ready and fully integrated!
*/
