-- Crystal Social Main Application System - Views and Analytics
-- File: 03_main_app_views_analytics.sql
-- Purpose: Analytics views and reporting for main application system performance and usage

-- =============================================================================
-- APP STATE ANALYTICS VIEWS
-- =============================================================================

-- Current app states overview
CREATE OR REPLACE VIEW app_states_overview AS
SELECT 
    a.user_id,
    u.email as user_email,
    a.device_id,
    a.session_id,
    a.is_online,
    a.is_initialized,
    a.theme_mode,
    a.selected_theme_color,
    a.is_loading,
    a.last_error,
    a.error_count,
    a.app_version,
    a.last_seen_at,
    a.created_at as session_started_at,
    EXTRACT(EPOCH FROM (NOW() - a.last_seen_at)) / 60 as minutes_since_last_seen,
    CASE 
        WHEN a.last_seen_at > NOW() - INTERVAL '5 minutes' THEN 'active'
        WHEN a.last_seen_at > NOW() - INTERVAL '30 minutes' THEN 'idle'
        ELSE 'inactive'
    END as activity_status
FROM app_states a
LEFT JOIN auth.users u ON a.user_id = u.id;

-- User session analytics
CREATE OR REPLACE VIEW user_session_analytics AS
SELECT 
    s.user_id,
    s.device_id,
    s.platform,
    s.app_version,
    COUNT(*) as total_sessions,
    AVG(EXTRACT(EPOCH FROM (COALESCE(s.session_end, NOW()) - s.session_start)) / 3600) as avg_session_hours,
    SUM(EXTRACT(EPOCH FROM (COALESCE(s.session_end, NOW()) - s.session_start)) / 3600) as total_session_hours,
    COUNT(*) FILTER (WHERE s.is_active = true) as active_sessions,
    COUNT(*) FILTER (WHERE s.force_logout_reason IS NOT NULL) as forced_logouts,
    MAX(s.last_activity) as last_activity,
    MIN(s.session_start) as first_session,
    COUNT(DISTINCT DATE(s.session_start)) as days_active
FROM user_sessions s
GROUP BY s.user_id, s.device_id, s.platform, s.app_version;

-- Device usage statistics
CREATE OR REPLACE VIEW device_usage_stats AS
SELECT 
    d.device_id,
    d.platform,
    d.device_model,
    d.device_brand,
    COUNT(DISTINCT d.user_id) as unique_users,
    COUNT(*) as total_registrations,
    MAX(d.last_seen_at) as last_activity,
    MIN(d.first_seen_at) as first_seen,
    EXTRACT(EPOCH FROM (MAX(d.last_seen_at) - MIN(d.first_seen_at))) / 86400 as days_in_use,
    AVG(CASE WHEN d.is_active THEN 1 ELSE 0 END) as active_ratio,
    md.is_shared_device,
    md.auto_logout_enabled,
    md.security_level
FROM user_devices d
LEFT JOIN multi_user_devices md ON d.device_id = md.device_id
GROUP BY d.device_id, d.platform, d.device_model, d.device_brand, 
         md.is_shared_device, md.auto_logout_enabled, md.security_level;

-- =============================================================================
-- CONNECTIVITY ANALYTICS VIEWS
-- =============================================================================

-- Connectivity quality overview
CREATE OR REPLACE VIEW connectivity_quality_overview AS
SELECT 
    c.user_id,
    c.device_id,
    c.connection_type,
    COUNT(*) as total_connections,
    COUNT(*) FILTER (WHERE c.is_online = true) as online_connections,
    COUNT(*) FILTER (WHERE c.is_online = false) as offline_connections,
    (COUNT(*) FILTER (WHERE c.is_online = true) * 100.0 / COUNT(*)) as uptime_percentage,
    AVG(c.latency_ms) as avg_latency_ms,
    MIN(c.latency_ms) as min_latency_ms,
    MAX(c.latency_ms) as max_latency_ms,
    AVG(c.download_speed_kbps) as avg_download_speed_kbps,
    AVG(c.upload_speed_kbps) as avg_upload_speed_kbps,
    MODE() WITHIN GROUP (ORDER BY c.network_quality) as most_common_quality,
    DATE_TRUNC('day', c.recorded_at) as date
FROM connectivity_logs c
WHERE c.recorded_at >= NOW() - INTERVAL '30 days'
GROUP BY c.user_id, c.device_id, c.connection_type, DATE_TRUNC('day', c.recorded_at);

-- Network performance trends
CREATE OR REPLACE VIEW network_performance_trends AS
SELECT 
    DATE_TRUNC('hour', c.recorded_at) as hour,
    c.connection_type,
    COUNT(*) as measurements,
    AVG(c.latency_ms) as avg_latency_ms,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY c.latency_ms) as p95_latency_ms,
    AVG(c.download_speed_kbps) as avg_download_speed,
    AVG(c.upload_speed_kbps) as avg_upload_speed,
    COUNT(*) FILTER (WHERE c.is_online = false) as disconnection_count,
    COUNT(DISTINCT c.user_id) as unique_users
FROM connectivity_logs c
WHERE c.recorded_at >= NOW() - INTERVAL '7 days'
GROUP BY DATE_TRUNC('hour', c.recorded_at), c.connection_type
ORDER BY hour DESC;

-- =============================================================================
-- APP LIFECYCLE ANALYTICS VIEWS
-- =============================================================================

-- App lifecycle event summary
CREATE OR REPLACE VIEW app_lifecycle_summary AS
SELECT 
    l.user_id,
    l.device_id,
    l.platform,
    l.event_type,
    COUNT(*) as event_count,
    AVG(l.duration_in_state_seconds) as avg_duration_seconds,
    MAX(l.duration_in_state_seconds) as max_duration_seconds,
    MIN(l.event_timestamp) as first_occurrence,
    MAX(l.event_timestamp) as last_occurrence,
    DATE_TRUNC('day', l.event_timestamp) as date
FROM app_lifecycle_events l
WHERE l.event_timestamp >= NOW() - INTERVAL '30 days'
GROUP BY l.user_id, l.device_id, l.platform, l.event_type, DATE_TRUNC('day', l.event_timestamp);

-- User engagement patterns
CREATE OR REPLACE VIEW user_engagement_patterns AS
SELECT 
    l.user_id,
    l.device_id,
    COUNT(*) FILTER (WHERE l.event_type = 'app_start') as app_starts,
    COUNT(*) FILTER (WHERE l.event_type = 'app_resume') as app_resumes,
    COUNT(*) FILTER (WHERE l.event_type = 'app_pause') as app_pauses,
    COUNT(*) FILTER (WHERE l.event_type = 'app_background') as backgrounded,
    COUNT(*) FILTER (WHERE l.event_type = 'user_login') as logins,
    COUNT(*) FILTER (WHERE l.event_type = 'user_logout') as logouts,
    AVG(CASE WHEN l.event_type = 'app_pause' THEN l.duration_in_state_seconds END) as avg_session_duration_seconds,
    COUNT(DISTINCT DATE(l.event_timestamp)) as active_days,
    MAX(l.event_timestamp) as last_activity,
    EXTRACT(EPOCH FROM (MAX(l.event_timestamp) - MIN(l.event_timestamp))) / 86400 as total_usage_days
FROM app_lifecycle_events l
WHERE l.event_timestamp >= NOW() - INTERVAL '30 days'
GROUP BY l.user_id, l.device_id;

-- =============================================================================
-- ERROR ANALYTICS VIEWS
-- =============================================================================

-- Error reports summary
CREATE OR REPLACE VIEW error_reports_summary AS
SELECT 
    e.error_type,
    e.severity_level,
    COUNT(*) as total_errors,
    COUNT(DISTINCT e.user_id) as affected_users,
    COUNT(DISTINCT e.device_id) as affected_devices,
    SUM(e.occurrence_count) as total_occurrences,
    AVG(e.occurrence_count) as avg_occurrences_per_report,
    COUNT(*) FILTER (WHERE e.is_fatal = true) as fatal_errors,
    COUNT(*) FILTER (WHERE e.resolved_at IS NOT NULL) as resolved_errors,
    COUNT(*) FILTER (WHERE e.resolved_at IS NULL) as unresolved_errors,
    MIN(e.first_occurred_at) as first_seen,
    MAX(e.last_occurred_at) as last_seen,
    MODE() WITHIN GROUP (ORDER BY e.app_version) as most_common_version,
    MODE() WITHIN GROUP (ORDER BY e.platform) as most_common_platform
FROM error_reports e
WHERE e.created_at >= NOW() - INTERVAL '30 days'
GROUP BY e.error_type, e.severity_level;

-- Top error messages
CREATE OR REPLACE VIEW top_error_messages AS
SELECT 
    e.error_message,
    e.error_type,
    e.function_name,
    e.screen_name,
    COUNT(*) as report_count,
    SUM(e.occurrence_count) as total_occurrences,
    COUNT(DISTINCT e.user_id) as unique_users,
    COUNT(*) FILTER (WHERE e.is_fatal = true) as fatal_count,
    AVG(e.occurrence_count) as avg_occurrences,
    MIN(e.first_occurred_at) as first_seen,
    MAX(e.last_occurred_at) as last_seen,
    COUNT(*) FILTER (WHERE e.resolved_at IS NOT NULL) as resolved_count,
    STRING_AGG(DISTINCT e.app_version, ', ' ORDER BY e.app_version) as affected_versions
FROM error_reports e
WHERE e.created_at >= NOW() - INTERVAL '30 days'
GROUP BY e.error_message, e.error_type, e.function_name, e.screen_name
ORDER BY total_occurrences DESC;

-- =============================================================================
-- FRONTING CHANGES ANALYTICS VIEWS
-- =============================================================================

-- Fronting changes analytics
CREATE OR REPLACE VIEW fronting_changes_analytics AS
WITH fronting_durations AS (
    SELECT 
        f.user_id,
        f.alter_name,
        f.change_timestamp,
        f.change_type,
        f.change_trigger,
        f.stress_level,
        f.notification_sent,
        EXTRACT(EPOCH FROM (LEAD(f.change_timestamp) OVER (
            PARTITION BY f.user_id ORDER BY f.change_timestamp
        ) - f.change_timestamp)) / 3600 as fronting_duration_hours
    FROM fronting_changes f
    WHERE f.change_timestamp >= NOW() - INTERVAL '30 days'
)
SELECT 
    fd.user_id,
    fd.alter_name,
    COUNT(*) as change_count,
    MIN(fd.change_timestamp) as first_fronting,
    MAX(fd.change_timestamp) as last_fronting,
    AVG(fd.fronting_duration_hours) as avg_fronting_duration_hours,
    MODE() WITHIN GROUP (ORDER BY fd.change_type) as most_common_change_type,
    MODE() WITHIN GROUP (ORDER BY fd.change_trigger) as most_common_trigger,
    AVG(fd.stress_level) as avg_stress_level,
    COUNT(*) FILTER (WHERE fd.notification_sent = true) as notifications_sent,
    COUNT(DISTINCT DATE(fd.change_timestamp)) as active_days
FROM fronting_durations fd
GROUP BY fd.user_id, fd.alter_name;

-- Daily fronting activity
CREATE OR REPLACE VIEW daily_fronting_activity AS
SELECT 
    DATE_TRUNC('day', f.change_timestamp) as date,
    COUNT(*) as total_changes,
    COUNT(DISTINCT f.user_id) as active_users,
    COUNT(DISTINCT f.alter_name) as unique_alters,
    AVG(f.stress_level) as avg_stress_level,
    COUNT(*) FILTER (WHERE f.change_type = 'emergency') as emergency_changes,
    COUNT(*) FILTER (WHERE f.notification_sent = true) as notifications_sent
FROM fronting_changes f
WHERE f.change_timestamp >= NOW() - INTERVAL '30 days'
GROUP BY DATE_TRUNC('day', f.change_timestamp)
ORDER BY date DESC;

-- =============================================================================
-- PUSH NOTIFICATION ANALYTICS VIEWS
-- =============================================================================

-- Push notification performance
CREATE OR REPLACE VIEW push_notification_performance AS
SELECT 
    p.notification_type,
    p.campaign_id,
    COUNT(*) as total_sent,
    COUNT(*) FILTER (WHERE p.delivered_at IS NOT NULL) as delivered,
    COUNT(*) FILTER (WHERE p.opened_at IS NOT NULL) as opened,
    COUNT(*) FILTER (WHERE p.dismissed_at IS NOT NULL) as dismissed,
    (COUNT(*) FILTER (WHERE p.delivered_at IS NOT NULL) * 100.0 / COUNT(*)) as delivery_rate,
    (COUNT(*) FILTER (WHERE p.opened_at IS NOT NULL) * 100.0 / 
     COUNT(*) FILTER (WHERE p.delivered_at IS NOT NULL)) as open_rate,
    AVG(p.delivery_latency_ms) as avg_delivery_latency_ms,
    AVG(p.time_to_open_seconds) as avg_time_to_open_seconds,
    COUNT(DISTINCT p.user_id) as unique_recipients
FROM push_notification_analytics p
WHERE p.sent_at >= NOW() - INTERVAL '30 days'
GROUP BY p.notification_type, p.campaign_id;

-- User notification engagement
CREATE OR REPLACE VIEW user_notification_engagement AS
SELECT 
    p.user_id,
    p.device_id,
    COUNT(*) as total_notifications,
    COUNT(*) FILTER (WHERE p.delivered_at IS NOT NULL) as delivered,
    COUNT(*) FILTER (WHERE p.opened_at IS NOT NULL) as opened,
    COUNT(*) FILTER (WHERE p.dismissed_at IS NOT NULL) as dismissed,
    COUNT(*) FILTER (WHERE p.action_taken = 'no_action') as ignored,
    (COUNT(*) FILTER (WHERE p.opened_at IS NOT NULL) * 100.0 / 
     COUNT(*) FILTER (WHERE p.delivered_at IS NOT NULL)) as personal_open_rate,
    AVG(p.time_to_open_seconds) as avg_time_to_open,
    COUNT(DISTINCT p.notification_type) as notification_types_received,
    MAX(p.sent_at) as last_notification_sent
FROM push_notification_analytics p
WHERE p.sent_at >= NOW() - INTERVAL '30 days'
GROUP BY p.user_id, p.device_id;

-- =============================================================================
-- BACKGROUND MESSAGE ANALYTICS VIEWS
-- =============================================================================

-- Background message processing stats
CREATE OR REPLACE VIEW background_message_stats AS
SELECT 
    b.message_type,
    b.app_state,
    COUNT(*) as total_messages,
    COUNT(*) FILTER (WHERE b.processing_status = 'completed') as completed,
    COUNT(*) FILTER (WHERE b.processing_status = 'failed') as failed,
    COUNT(*) FILTER (WHERE b.processing_status = 'pending') as pending,
    (COUNT(*) FILTER (WHERE b.processing_status = 'completed') * 100.0 / COUNT(*)) as success_rate,
    AVG(b.processing_duration_ms) as avg_processing_time_ms,
    MAX(b.processing_duration_ms) as max_processing_time_ms,
    COUNT(DISTINCT b.user_id) as unique_users,
    DATE_TRUNC('hour', b.received_at) as hour
FROM background_messages b
WHERE b.received_at >= NOW() - INTERVAL '24 hours'
GROUP BY b.message_type, b.app_state, DATE_TRUNC('hour', b.received_at)
ORDER BY hour DESC;

-- =============================================================================
-- APP INITIALIZATION ANALYTICS VIEWS
-- =============================================================================

-- App initialization performance
CREATE OR REPLACE VIEW app_initialization_performance AS
SELECT 
    i.platform,
    i.app_version,
    i.environment,
    COUNT(*) as total_initializations,
    COUNT(*) FILTER (WHERE i.initialization_successful = true) as successful,
    COUNT(*) FILTER (WHERE i.initialization_successful = false) as failed,
    (COUNT(*) FILTER (WHERE i.initialization_successful = true) * 100.0 / COUNT(*)) as success_rate,
    AVG(i.total_duration_ms) as avg_total_duration_ms,
    AVG(i.firebase_init_duration_ms) as avg_firebase_init_ms,
    AVG(i.supabase_init_duration_ms) as avg_supabase_init_ms,
    AVG(i.hive_init_duration_ms) as avg_hive_init_ms,
    AVG(i.notifications_init_duration_ms) as avg_notifications_init_ms,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY i.total_duration_ms) as p95_total_duration_ms,
    MODE() WITHIN GROUP (ORDER BY i.failed_services[1]) as most_common_failure
FROM app_initialization_logs i
WHERE i.created_at >= NOW() - INTERVAL '7 days'
GROUP BY i.platform, i.app_version, i.environment;

-- =============================================================================
-- MULTI-USER DEVICE ANALYTICS VIEWS
-- =============================================================================

-- Multi-user device insights
CREATE OR REPLACE VIEW multi_user_device_insights AS
SELECT 
    md.device_id,
    md.platform,
    md.total_users_count,
    md.active_users_count,
    md.is_shared_device,
    md.auto_logout_enabled,
    md.security_level,
    COUNT(DISTINCT dh.user_id) as historical_user_count,
    AVG(dh.session_duration_minutes) as avg_session_duration_minutes,
    COUNT(*) FILTER (WHERE dh.logout_type = 'auto_logout') as auto_logout_count,
    COUNT(*) FILTER (WHERE dh.logout_type = 'manual') as manual_logout_count,
    MAX(dh.login_timestamp) as last_login,
    EXTRACT(EPOCH FROM (MAX(dh.login_timestamp) - MIN(dh.login_timestamp))) / 86400 as device_age_days
FROM multi_user_devices md
LEFT JOIN device_user_history dh ON md.device_id = dh.device_id
GROUP BY md.device_id, md.platform, md.total_users_count, md.active_users_count, 
         md.is_shared_device, md.auto_logout_enabled, md.security_level;

-- =============================================================================
-- COMPREHENSIVE DASHBOARD VIEWS
-- =============================================================================

-- App health dashboard
CREATE OR REPLACE VIEW app_health_dashboard AS
SELECT 
    'Active Users (Last 24h)' as metric,
    COUNT(DISTINCT a.user_id)::TEXT as value,
    'users' as unit
FROM app_states a
WHERE a.last_seen_at >= NOW() - INTERVAL '24 hours'

UNION ALL

SELECT 
    'Active Devices (Last 24h)' as metric,
    COUNT(DISTINCT d.device_id)::TEXT as value,
    'devices' as unit
FROM user_devices d
WHERE d.last_seen_at >= NOW() - INTERVAL '24 hours'

UNION ALL

SELECT 
    'Error Rate (Last 24h)' as metric,
    ROUND((COUNT(*) FILTER (WHERE e.severity_level IN ('error', 'critical')) * 100.0 / 
           NULLIF(COUNT(*), 0)), 2)::TEXT as value,
    '%' as unit
FROM error_reports e
WHERE e.last_occurred_at >= NOW() - INTERVAL '24 hours'

UNION ALL

SELECT 
    'Average Session Duration' as metric,
    ROUND(AVG(EXTRACT(EPOCH FROM (COALESCE(s.session_end, NOW()) - s.session_start)) / 60), 1)::TEXT as value,
    'minutes' as unit
FROM user_sessions s
WHERE s.session_start >= NOW() - INTERVAL '7 days'

UNION ALL

SELECT 
    'Push Notification Open Rate' as metric,
    ROUND((COUNT(*) FILTER (WHERE p.opened_at IS NOT NULL) * 100.0 / 
           NULLIF(COUNT(*) FILTER (WHERE p.delivered_at IS NOT NULL), 0)), 1)::TEXT as value,
    '%' as unit
FROM push_notification_analytics p
WHERE p.sent_at >= NOW() - INTERVAL '24 hours';

-- Platform usage distribution
CREATE OR REPLACE VIEW platform_usage_distribution AS
SELECT 
    d.platform,
    COUNT(DISTINCT d.user_id) as unique_users,
    COUNT(DISTINCT d.device_id) as unique_devices,
    AVG(EXTRACT(EPOCH FROM (d.last_seen_at - d.first_seen_at)) / 86400) as avg_usage_days,
    COUNT(*) FILTER (WHERE d.is_active = true) as active_devices,
    STRING_AGG(DISTINCT d.app_version, ', ' ORDER BY d.app_version) as app_versions
FROM user_devices d
WHERE d.first_seen_at >= NOW() - INTERVAL '30 days'
GROUP BY d.platform
ORDER BY unique_users DESC;

-- =============================================================================
-- MATERIALIZED VIEWS FOR PERFORMANCE
-- =============================================================================

-- Daily app metrics (materialized for performance)
CREATE MATERIALIZED VIEW IF NOT EXISTS daily_app_metrics AS
SELECT 
    DATE_TRUNC('day', NOW()) as date,
    COUNT(DISTINCT a.user_id) as daily_active_users,
    COUNT(DISTINCT a.device_id) as daily_active_devices,
    COUNT(DISTINCT s.id) as daily_sessions,
    AVG(EXTRACT(EPOCH FROM (COALESCE(s.session_end, NOW()) - s.session_start)) / 60) as avg_session_minutes,
    COUNT(DISTINCT e.id) as daily_errors,
    COUNT(DISTINCT f.id) as daily_fronting_changes,
    COUNT(DISTINCT p.id) as daily_push_notifications
FROM app_states a
LEFT JOIN user_sessions s ON a.user_id = s.user_id AND a.device_id = s.device_id
LEFT JOIN error_reports e ON a.user_id = e.user_id AND DATE(e.created_at) = CURRENT_DATE
LEFT JOIN fronting_changes f ON a.user_id = f.user_id AND DATE(f.change_timestamp) = CURRENT_DATE
LEFT JOIN push_notification_analytics p ON a.user_id = p.user_id AND DATE(p.sent_at) = CURRENT_DATE
WHERE a.last_seen_at >= CURRENT_DATE;

-- Create refresh function for materialized view
CREATE OR REPLACE FUNCTION refresh_daily_app_metrics()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW daily_app_metrics;
END;
$$;

-- =============================================================================
-- GRANT PERMISSIONS
-- =============================================================================

-- Grant select permissions on views to authenticated users
GRANT SELECT ON app_states_overview TO authenticated;
GRANT SELECT ON user_session_analytics TO authenticated;
GRANT SELECT ON connectivity_quality_overview TO authenticated;
GRANT SELECT ON app_lifecycle_summary TO authenticated;
GRANT SELECT ON user_engagement_patterns TO authenticated;
GRANT SELECT ON fronting_changes_analytics TO authenticated;
GRANT SELECT ON push_notification_performance TO authenticated;
GRANT SELECT ON user_notification_engagement TO authenticated;
GRANT SELECT ON platform_usage_distribution TO authenticated;

-- Grant admin-level views to service role and specific roles
GRANT SELECT ON device_usage_stats TO service_role;
GRANT SELECT ON error_reports_summary TO service_role;
GRANT SELECT ON top_error_messages TO service_role;
GRANT SELECT ON background_message_stats TO service_role;
GRANT SELECT ON app_initialization_performance TO service_role;
GRANT SELECT ON multi_user_device_insights TO service_role;
GRANT SELECT ON app_health_dashboard TO service_role;
GRANT SELECT ON network_performance_trends TO service_role;
GRANT SELECT ON daily_fronting_activity TO service_role;
GRANT SELECT ON daily_app_metrics TO service_role;

-- Grant refresh function to service role
GRANT EXECUTE ON FUNCTION refresh_daily_app_metrics TO service_role;

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON VIEW app_states_overview IS 'Current app states with user activity status';
COMMENT ON VIEW user_session_analytics IS 'Aggregated user session statistics and engagement metrics';
COMMENT ON VIEW connectivity_quality_overview IS 'Network connectivity quality and performance metrics';
COMMENT ON VIEW error_reports_summary IS 'Error reports grouped by type and severity with resolution status';
COMMENT ON VIEW fronting_changes_analytics IS 'DID system fronting changes with patterns and triggers';
COMMENT ON VIEW app_health_dashboard IS 'Key app health metrics for monitoring dashboard';
COMMENT ON VIEW platform_usage_distribution IS 'Usage distribution across different platforms';
COMMENT ON MATERIALIZED VIEW daily_app_metrics IS 'Daily aggregated app metrics for performance reporting';

-- Setup completion message
SELECT 'Main App Views and Analytics Setup Complete!' as status, NOW() as setup_completed_at;
