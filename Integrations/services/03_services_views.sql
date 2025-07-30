-- Crystal Social Services System - Views and Advanced Queries
-- File: 03_services_views.sql
-- Purpose: Views, materialized views, and complex queries for services

-- =============================================================================
-- DEVICE AND USER MANAGEMENT VIEWS
-- =============================================================================

-- Comprehensive user device information
CREATE OR REPLACE VIEW user_devices_detailed AS
SELECT 
    ud.id,
    ud.user_id,
    ud.device_id,
    ud.platform,
    ud.app_version,
    ud.platform_version as os_version,
    ud.device_model,
    ud.is_active,
    ud.first_seen_at as first_login,
    ud.last_seen_at as last_active,
    ud.created_at,
    ud.updated_at,
    
    -- User information
    u.email as user_email,
    p.username,
    p.display_name,
    
    -- Device activity metrics
    EXTRACT(DAYS FROM NOW() - ud.last_seen_at) as days_since_last_active,
    CASE 
        WHEN ud.last_seen_at > NOW() - INTERVAL '1 day' THEN 'active'
        WHEN ud.last_seen_at > NOW() - INTERVAL '7 days' THEN 'recent'
        WHEN ud.last_seen_at > NOW() - INTERVAL '30 days' THEN 'inactive'
        ELSE 'dormant'
    END as activity_status,
    
    -- Device info from direct columns (no JSONB device_info in main_app schema)
    ud.device_model as extracted_device_model,
    ud.device_brand as device_brand,
    ud.platform_version as extracted_os_version,
    NULL as screen_resolution,
    NULL as device_timezone
    
FROM user_devices ud
LEFT JOIN auth.users u ON ud.user_id = u.id
LEFT JOIN profiles p ON ud.user_id = p.id;

-- Device user tracking with user details
CREATE OR REPLACE VIEW device_user_tracking_detailed AS
SELECT 
    duh.id,
    duh.device_id as device_identifier,
    duh.user_id,
    false as is_current_user, -- Not available in main_app schema
    false as is_first_user, -- Not available in main_app schema
    1 as login_count, -- Not available in main_app schema
    duh.login_timestamp as first_login,
    duh.login_timestamp as last_login,
    duh.logout_timestamp as last_logout,
    
    -- User information
    p.username,
    p.display_name,
    p.avatar_url,
    
    -- Activity analysis
    EXTRACT(DAYS FROM NOW() - duh.login_timestamp) as days_since_last_login,
    CASE 
        WHEN duh.logout_timestamp IS NULL THEN 'never_logged_out'
        WHEN duh.login_timestamp > duh.logout_timestamp THEN 'currently_logged_in'
        ELSE 'logged_out'
    END as login_status,
    
    -- Device sharing metrics
    COUNT(*) OVER (PARTITION BY duh.device_id) as total_users_on_device,
    ROW_NUMBER() OVER (PARTITION BY duh.device_id ORDER BY duh.login_timestamp) as user_order_on_device
    
FROM device_user_history duh
LEFT JOIN profiles p ON duh.user_id = p.id;

-- =============================================================================
-- NOTIFICATION ANALYTICS VIEWS
-- =============================================================================

-- Comprehensive notification analytics
CREATE OR REPLACE VIEW notification_analytics AS
SELECT 
    nl.id,
    nl.receiver_user_id,
    nl.sender_user_id,
    nl.title,
    nl.body,
    nl.devices_targeted,
    nl.devices_delivered,
    nl.devices_failed,
    nl.delivery_rate,
    nl.status,
    nl.created_at,
    nl.sent_at,
    nl.delivered_at,
    
    -- Notification type information
    nt.name as notification_type,
    nt.display_name as type_display_name,
    nt.priority_level,
    
    -- User information
    receiver.username as receiver_username,
    receiver.display_name as receiver_display_name,
    sender.username as sender_username,
    sender.display_name as sender_display_name,
    
    -- Timing analysis
    EXTRACT(EPOCH FROM (nl.sent_at - nl.created_at)) as queue_time_seconds,
    EXTRACT(EPOCH FROM (nl.delivered_at - nl.sent_at)) as delivery_time_seconds,
    EXTRACT(EPOCH FROM (nl.delivered_at - nl.created_at)) as total_time_seconds,
    
    -- Performance categorization
    CASE 
        WHEN nl.delivery_rate >= 95 THEN 'excellent'
        WHEN nl.delivery_rate >= 80 THEN 'good'
        WHEN nl.delivery_rate >= 60 THEN 'fair'
        ELSE 'poor'
    END as delivery_performance,
    
    -- Retry analysis
    nl.retry_count,
    CASE 
        WHEN nl.retry_count = 0 THEN 'first_attempt_success'
        WHEN nl.retry_count <= 2 THEN 'minor_retries'
        ELSE 'multiple_retries'
    END as retry_category
    
FROM notification_logs nl
LEFT JOIN notification_types nt ON nl.notification_type_id = nt.id
LEFT JOIN profiles receiver ON nl.receiver_user_id = receiver.id
LEFT JOIN profiles sender ON nl.sender_user_id = sender.id;

-- Daily notification summary
CREATE MATERIALIZED VIEW daily_notification_summary AS
SELECT 
    DATE(nl.created_at) as notification_date,
    notification_type_id,
    nt.name as notification_type,
    nt.display_name as type_display_name,
    
    -- Volume metrics
    COUNT(*) as total_notifications,
    SUM(devices_targeted) as total_devices_targeted,
    SUM(devices_delivered) as total_devices_delivered,
    SUM(devices_failed) as total_devices_failed,
    
    -- Performance metrics
    ROUND(AVG(delivery_rate), 2) as avg_delivery_rate,
    ROUND(MAX(delivery_rate), 2) as max_delivery_rate,
    ROUND(MIN(delivery_rate), 2) as min_delivery_rate,
    
    -- Timing metrics
    ROUND(AVG(EXTRACT(EPOCH FROM (delivered_at - nl.created_at))), 2) as avg_total_time_seconds,
    ROUND(MAX(EXTRACT(EPOCH FROM (delivered_at - nl.created_at))), 2) as max_total_time_seconds,
    
    -- Status distribution
    COUNT(*) FILTER (WHERE status = 'delivered') as delivered_count,
    COUNT(*) FILTER (WHERE status = 'failed') as failed_count,
    COUNT(*) FILTER (WHERE status = 'pending') as pending_count,
    
    -- User distribution
    COUNT(DISTINCT receiver_user_id) as unique_receivers,
    COUNT(DISTINCT sender_user_id) as unique_senders
    
FROM notification_logs nl
LEFT JOIN notification_types nt ON nl.notification_type_id = nt.id
GROUP BY DATE(nl.created_at), notification_type_id, nt.name, nt.display_name;

-- Create index for materialized view refresh
CREATE UNIQUE INDEX idx_daily_notification_summary_unique 
ON daily_notification_summary (notification_date, notification_type_id);

-- =============================================================================
-- GLIMMER SERVICE VIEWS
-- =============================================================================

-- Comprehensive Glimmer posts with user and engagement data
CREATE OR REPLACE VIEW glimmer_posts_with_stats AS
SELECT 
    gp.id,
    gp.user_id,
    gp.title,
    gp.description,
    gp.image_url,
    gp.category_id,
    gp.tags,
    gp.like_count,
    gp.comment_count,
    gp.view_count,
    gp.share_count,
    gp.is_published,
    gp.is_featured,
    gp.is_trending,
    gp.created_at,
    gp.updated_at,
    
    -- User information
    p.username,
    p.display_name,
    p.avatar_url,
    
    -- Category information
    gc.name as category_name,
    gc.display_name as category_display_name,
    gc.icon_name as category_icon,
    gc.color_hex as category_color,
    
    -- Engagement metrics
    ROUND((gp.like_count * 1.0 + gp.comment_count * 2.0 + gp.share_count * 3.0), 2) as engagement_score,
    ROUND((gp.like_count * 100.0 / GREATEST(gp.view_count, 1)), 2) as like_rate,
    ROUND((gp.comment_count * 100.0 / GREATEST(gp.view_count, 1)), 2) as comment_rate,
    
    -- Time-based metrics
    EXTRACT(DAYS FROM NOW() - gp.created_at) as days_since_posted,
    CASE 
        WHEN gp.created_at > NOW() - INTERVAL '1 day' THEN 'new'
        WHEN gp.created_at > NOW() - INTERVAL '7 days' THEN 'recent'
        WHEN gp.created_at > NOW() - INTERVAL '30 days' THEN 'current'
        ELSE 'old'
    END as post_age_category,
    
    -- Trending analysis
    CASE 
        WHEN gp.created_at > NOW() - INTERVAL '24 hours' AND gp.like_count >= 10 THEN true
        WHEN gp.created_at > NOW() - INTERVAL '7 days' AND gp.like_count >= 25 THEN true
        ELSE false
    END as is_trending_calculated
    
FROM glimmer_posts gp
LEFT JOIN profiles p ON gp.user_id = p.id
LEFT JOIN glimmer_categories gc ON gp.category_id = gc.id
WHERE gp.is_published = true;

-- User Glimmer statistics
CREATE OR REPLACE VIEW user_glimmer_stats AS
SELECT 
    p.id as user_id,
    p.username,
    p.display_name,
    
    -- Post metrics
    COUNT(gp.id) as total_posts,
    COUNT(gp.id) FILTER (WHERE gp.is_featured = true) as featured_posts,
    COUNT(gp.id) FILTER (WHERE gp.created_at > NOW() - INTERVAL '30 days') as posts_last_30_days,
    COUNT(gp.id) FILTER (WHERE gp.created_at > NOW() - INTERVAL '7 days') as posts_last_7_days,
    
    -- Engagement metrics
    COALESCE(SUM(gp.like_count), 0) as total_likes_received,
    COALESCE(SUM(gp.comment_count), 0) as total_comments_received,
    COALESCE(SUM(gp.view_count), 0) as total_views_received,
    COALESCE(SUM(gp.share_count), 0) as total_shares_received,
    
    -- Average engagement
    ROUND(COALESCE(AVG(gp.like_count), 0), 2) as avg_likes_per_post,
    ROUND(COALESCE(AVG(gp.comment_count), 0), 2) as avg_comments_per_post,
    ROUND(COALESCE(AVG(gp.view_count), 0), 2) as avg_views_per_post,
    
    -- Activity metrics
    MAX(gp.created_at) as last_post_date,
    MIN(gp.created_at) as first_post_date,
    EXTRACT(DAYS FROM NOW() - MAX(gp.created_at)) as days_since_last_post,
    
    -- Category distribution (most used category)
    MODE() WITHIN GROUP (ORDER BY gc.name) as favorite_category,
    
    -- Performance tier
    CASE 
        WHEN COALESCE(SUM(gp.like_count), 0) >= 1000 THEN 'influencer'
        WHEN COALESCE(SUM(gp.like_count), 0) >= 250 THEN 'popular'
        WHEN COALESCE(SUM(gp.like_count), 0) >= 50 THEN 'active'
        WHEN COUNT(gp.id) >= 10 THEN 'regular'
        WHEN COUNT(gp.id) >= 1 THEN 'beginner'
        ELSE 'inactive'
    END as engagement_tier
    
FROM profiles p
LEFT JOIN glimmer_posts gp ON p.id = gp.user_id AND gp.is_published = true
LEFT JOIN glimmer_categories gc ON gp.category_id = gc.id
GROUP BY p.id, p.username, p.display_name;

-- =============================================================================
-- SERVICE PERFORMANCE VIEWS
-- =============================================================================

-- Service health dashboard
CREATE OR REPLACE VIEW service_health_dashboard AS
SELECT 
    shc.service_name,
    shc.check_type,
    
    -- Current status
    shc.status as current_status,
    shc.response_time_ms as current_response_time,
    shc.checked_at as last_check_time,
    
    -- Historical metrics (last 24 hours)
    COUNT(*) OVER (
        PARTITION BY shc.service_name, shc.check_type 
        ORDER BY shc.checked_at 
        RANGE BETWEEN INTERVAL '24 hours' PRECEDING AND CURRENT ROW
    ) as checks_last_24h,
    
    AVG(shc.response_time_ms) OVER (
        PARTITION BY shc.service_name, shc.check_type 
        ORDER BY shc.checked_at 
        RANGE BETWEEN INTERVAL '24 hours' PRECEDING AND CURRENT ROW
    ) as avg_response_time_24h,
    
    COUNT(*) FILTER (WHERE shc.status = 'healthy') OVER (
        PARTITION BY shc.service_name, shc.check_type 
        ORDER BY shc.checked_at 
        RANGE BETWEEN INTERVAL '24 hours' PRECEDING AND CURRENT ROW
    ) as healthy_checks_24h,
    
    -- Uptime calculation
    ROUND(
        COUNT(*) FILTER (WHERE shc.status = 'healthy') OVER (
            PARTITION BY shc.service_name, shc.check_type 
            ORDER BY shc.checked_at 
            RANGE BETWEEN INTERVAL '24 hours' PRECEDING AND CURRENT ROW
        ) * 100.0 / GREATEST(1, COUNT(*) OVER (
            PARTITION BY shc.service_name, shc.check_type 
            ORDER BY shc.checked_at 
            RANGE BETWEEN INTERVAL '24 hours' PRECEDING AND CURRENT ROW
        )), 2
    ) as uptime_percentage_24h
    
FROM service_health_checks shc
WHERE shc.checked_at = (
    SELECT MAX(checked_at) 
    FROM service_health_checks shc2 
    WHERE shc2.service_name = shc.service_name 
    AND shc2.check_type = shc.check_type
);

-- Service operation performance summary
CREATE MATERIALIZED VIEW service_operation_performance AS
SELECT 
    sol.service_name,
    sol.operation_name,
    DATE(sol.created_at) as operation_date,
    
    -- Volume metrics
    COUNT(*) as total_operations,
    COUNT(*) FILTER (WHERE sol.status = 'success') as successful_operations,
    COUNT(*) FILTER (WHERE sol.status = 'error') as failed_operations,
    COUNT(*) FILTER (WHERE sol.status = 'timeout') as timeout_operations,
    
    -- Performance metrics
    ROUND(AVG(sol.duration_ms), 2) as avg_duration_ms,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sol.duration_ms)::numeric, 2) as median_duration_ms,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY sol.duration_ms)::numeric, 2) as p95_duration_ms,
    MAX(sol.duration_ms) as max_duration_ms,
    MIN(sol.duration_ms) as min_duration_ms,
    
    -- Resource metrics
    ROUND(AVG(sol.memory_usage_mb), 2) as avg_memory_usage_mb,
    ROUND(AVG(sol.cpu_usage_percent), 2) as avg_cpu_usage_percent,
    
    -- Success rate
    ROUND(
        COUNT(*) FILTER (WHERE sol.status = 'success') * 100.0 / COUNT(*), 2
    ) as success_rate_percent,
    
    -- User distribution
    COUNT(DISTINCT sol.user_id) as unique_users,
    
    -- Performance classification
    CASE 
        WHEN AVG(sol.duration_ms) <= 100 THEN 'excellent'
        WHEN AVG(sol.duration_ms) <= 500 THEN 'good'
        WHEN AVG(sol.duration_ms) <= 1000 THEN 'acceptable'
        WHEN AVG(sol.duration_ms) <= 2000 THEN 'slow'
        ELSE 'very_slow'
    END as performance_tier
    
FROM service_operation_logs sol
GROUP BY sol.service_name, sol.operation_name, DATE(sol.created_at);

-- Create index for materialized view
CREATE UNIQUE INDEX idx_service_operation_performance_unique 
ON service_operation_performance (service_name, operation_name, operation_date);

-- =============================================================================
-- REFRESH FUNCTION FOR MATERIALIZED VIEWS
-- =============================================================================

-- Function to refresh all materialized views
CREATE OR REPLACE FUNCTION refresh_service_materialized_views()
RETURNS JSON AS $$
DECLARE
    v_start_time TIMESTAMPTZ := NOW();
    v_end_time TIMESTAMPTZ;
    v_result JSON;
BEGIN
    -- Refresh daily notification summary
    REFRESH MATERIALIZED VIEW CONCURRENTLY daily_notification_summary;
    
    -- Refresh service operation performance
    REFRESH MATERIALIZED VIEW CONCURRENTLY service_operation_performance;
    
    v_end_time := NOW();
    
    v_result := json_build_object(
        'success', true,
        'message', 'All materialized views refreshed successfully',
        'start_time', v_start_time,
        'end_time', v_end_time,
        'duration_seconds', EXTRACT(EPOCH FROM (v_end_time - v_start_time)),
        'views_refreshed', ARRAY['daily_notification_summary', 'service_operation_performance']
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- GRANT PERMISSIONS FOR VIEWS
-- =============================================================================

GRANT SELECT ON user_devices_detailed TO authenticated;
GRANT SELECT ON device_user_tracking_detailed TO authenticated;
GRANT SELECT ON notification_analytics TO authenticated;
GRANT SELECT ON daily_notification_summary TO authenticated;
GRANT SELECT ON glimmer_posts_with_stats TO authenticated;
GRANT SELECT ON user_glimmer_stats TO authenticated;
GRANT SELECT ON service_health_dashboard TO authenticated;
GRANT SELECT ON service_operation_performance TO authenticated;

GRANT EXECUTE ON FUNCTION refresh_service_materialized_views() TO service_role;

-- =============================================================================
-- VIEW DOCUMENTATION
-- =============================================================================

COMMENT ON VIEW user_devices_detailed IS 'Comprehensive view of user devices with activity status and extracted device information';
COMMENT ON VIEW device_user_tracking_detailed IS 'Device user tracking with user details and login status analysis';
COMMENT ON VIEW notification_analytics IS 'Comprehensive notification analytics with performance metrics and timing analysis';
COMMENT ON MATERIALIZED VIEW daily_notification_summary IS 'Daily aggregated notification metrics by type with performance statistics';
COMMENT ON VIEW glimmer_posts_with_stats IS 'Glimmer posts with user information, engagement metrics, and trending analysis';
COMMENT ON VIEW user_glimmer_stats IS 'User-level Glimmer statistics and engagement tiers';
COMMENT ON VIEW service_health_dashboard IS 'Real-time service health status with 24-hour historical metrics';
COMMENT ON MATERIALIZED VIEW service_operation_performance IS 'Daily service operation performance metrics with success rates and timing statistics';
COMMENT ON FUNCTION refresh_service_materialized_views() IS 'Refresh all service-related materialized views for updated analytics';
