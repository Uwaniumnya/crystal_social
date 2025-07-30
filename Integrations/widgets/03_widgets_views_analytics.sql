-- Crystal Social Widgets System - Views and Analytics
-- File: 03_widgets_views_analytics.sql
-- Purpose: Database views and analytics for comprehensive widget usage insights

-- =============================================================================
-- STICKER ANALYTICS VIEWS
-- =============================================================================

-- Comprehensive sticker overview with usage metrics
CREATE OR REPLACE VIEW sticker_analytics_overview AS
SELECT 
    s.id,
    s.sticker_name,
    s.sticker_url,
    s.category,
    s.is_gif,
    s.file_size,
    s.format,
    s.tags,
    s.is_public,
    s.is_approved,
    s.upload_source,
    s.usage_count,
    s.created_at,
    
    -- User information
    u.email as uploader_email,
    
    -- Recent usage metrics
    COALESCE(recent_stats.recent_uses_7d, 0) as recent_uses_7d,
    COALESCE(recent_stats.recent_uses_30d, 0) as recent_uses_30d,
    COALESCE(recent_stats.unique_users_7d, 0) as unique_users_7d,
    COALESCE(recent_stats.unique_users_30d, 0) as unique_users_30d,
    
    -- Popularity metrics
    CASE 
        WHEN s.usage_count > 1000 THEN 'viral'
        WHEN s.usage_count > 100 THEN 'popular'
        WHEN s.usage_count > 10 THEN 'moderate'
        ELSE 'low'
    END as popularity_level,
    
    -- File efficiency
    CASE 
        WHEN s.file_size > 0 THEN ROUND(s.usage_count::DECIMAL / s.file_size * 1000, 2)
        ELSE 0
    END as usage_per_kb,
    
    -- Category ranking
    ROW_NUMBER() OVER (PARTITION BY s.category ORDER BY s.usage_count DESC) as category_rank

FROM stickers s
LEFT JOIN auth.users u ON s.user_id = u.id
LEFT JOIN (
    SELECT 
        sticker_url,
        COUNT(CASE WHEN used_at >= NOW() - INTERVAL '7 days' THEN 1 END) as recent_uses_7d,
        COUNT(CASE WHEN used_at >= NOW() - INTERVAL '30 days' THEN 1 END) as recent_uses_30d,
        COUNT(DISTINCT CASE WHEN used_at >= NOW() - INTERVAL '7 days' THEN user_id END) as unique_users_7d,
        COUNT(DISTINCT CASE WHEN used_at >= NOW() - INTERVAL '30 days' THEN user_id END) as unique_users_30d
    FROM recent_stickers
    GROUP BY sticker_url
) recent_stats ON s.sticker_url = recent_stats.sticker_url
ORDER BY s.usage_count DESC;

-- Sticker category performance
CREATE OR REPLACE VIEW sticker_category_performance AS
SELECT 
    category,
    COUNT(*) as total_stickers,
    COUNT(CASE WHEN is_public = true THEN 1 END) as public_stickers,
    COUNT(CASE WHEN is_approved = true THEN 1 END) as approved_stickers,
    
    -- Usage statistics
    SUM(usage_count) as total_usage,
    AVG(usage_count) as avg_usage_per_sticker,
    MAX(usage_count) as max_usage,
    MIN(usage_count) as min_usage,
    
    -- File statistics
    AVG(file_size) as avg_file_size,
    COUNT(CASE WHEN is_gif = true THEN 1 END) as gif_count,
    COUNT(CASE WHEN is_gif = false THEN 1 END) as static_count,
    
    -- Recent activity
    COUNT(CASE WHEN created_at >= NOW() - INTERVAL '7 days' THEN 1 END) as new_stickers_7d,
    COUNT(CASE WHEN created_at >= NOW() - INTERVAL '30 days' THEN 1 END) as new_stickers_30d,
    
    -- Quality metrics
    ROUND(
        COUNT(CASE WHEN is_approved = true THEN 1 END)::DECIMAL / 
        NULLIF(COUNT(CASE WHEN is_public = true THEN 1 END), 0) * 100, 2
    ) as approval_rate_percent

FROM stickers
GROUP BY category
ORDER BY total_usage DESC;

-- Top sticker creators
CREATE OR REPLACE VIEW top_sticker_creators AS
SELECT 
    u.id as user_id,
    u.email as username,
    
    -- Creation statistics
    COUNT(s.id) as total_stickers_created,
    COUNT(CASE WHEN s.is_public = true THEN 1 END) as public_stickers,
    COUNT(CASE WHEN s.is_approved = true THEN 1 END) as approved_stickers,
    
    -- Usage statistics
    SUM(s.usage_count) as total_sticker_usage,
    AVG(s.usage_count) as avg_usage_per_sticker,
    MAX(s.usage_count) as most_popular_usage,
    
    -- Quality metrics
    ROUND(
        COUNT(CASE WHEN s.is_approved = true THEN 1 END)::DECIMAL / 
        NULLIF(COUNT(CASE WHEN s.is_public = true THEN 1 END), 0) * 100, 2
    ) as approval_rate,
    
    -- Recent activity
    COUNT(CASE WHEN s.created_at >= NOW() - INTERVAL '30 days' THEN 1 END) as stickers_created_30d,
    
    -- Creator score
    ROUND(
        (SUM(s.usage_count) * 0.4) + 
        (COUNT(CASE WHEN s.is_approved = true THEN 1 END) * 10) +
        (COUNT(s.id) * 0.1), 2
    ) as creator_score

FROM auth.users u
INNER JOIN stickers s ON u.id = s.user_id
GROUP BY u.id, u.email
HAVING COUNT(s.id) > 0
ORDER BY creator_score DESC;

-- =============================================================================
-- EMOTICON ANALYTICS VIEWS
-- =============================================================================

-- Emoticon usage patterns
CREATE OR REPLACE VIEW emoticon_usage_patterns AS
SELECT 
    eu.emoticon_text,
    eu.category_name,
    
    -- Usage statistics
    COUNT(*) as total_uses,
    COUNT(DISTINCT eu.user_id) as unique_users,
    COUNT(DISTINCT DATE(eu.used_at)) as active_days,
    
    -- Timing patterns
    MIN(eu.used_at) as first_used,
    MAX(eu.used_at) as last_used,
    
    -- Recent activity
    COUNT(CASE WHEN eu.used_at >= NOW() - INTERVAL '7 days' THEN 1 END) as uses_7d,
    COUNT(CASE WHEN eu.used_at >= NOW() - INTERVAL '30 days' THEN 1 END) as uses_30d,
    
    -- Context analysis
    COUNT(CASE WHEN eu.context_type = 'message' THEN 1 END) as message_uses,
    COUNT(CASE WHEN eu.context_type = 'comment' THEN 1 END) as comment_uses,
    COUNT(CASE WHEN eu.context_type = 'reaction' THEN 1 END) as reaction_uses,
    
    -- Popularity score
    ROUND(
        (COUNT(*) * 0.3) + 
        (COUNT(DISTINCT eu.user_id) * 2) + 
        (COUNT(CASE WHEN eu.used_at >= NOW() - INTERVAL '7 days' THEN 1 END) * 5), 2
    ) as popularity_score

FROM emoticon_usage eu
GROUP BY eu.emoticon_text, eu.category_name
ORDER BY popularity_score DESC;

-- Custom emoticon performance
CREATE OR REPLACE VIEW custom_emoticon_performance AS
SELECT 
    ce.id,
    ce.emoticon_text,
    ce.emoticon_name,
    ce.is_public,
    ce.is_approved,
    ce.usage_count,
    ce.created_at,
    
    -- Creator info
    u.email as creator_email,
    
    -- Category info
    ec.display_name as category_display_name,
    
    -- Usage metrics from tracking table
    COALESCE(usage_stats.tracked_uses, 0) as tracked_usage,
    COALESCE(usage_stats.unique_users, 0) as unique_users,
    COALESCE(usage_stats.recent_uses_7d, 0) as recent_uses_7d,
    
    -- Performance rating
    CASE 
        WHEN ce.usage_count > 100 THEN 'excellent'
        WHEN ce.usage_count > 50 THEN 'good'
        WHEN ce.usage_count > 10 THEN 'moderate'
        ELSE 'low'
    END as performance_rating

FROM custom_emoticons ce
LEFT JOIN auth.users u ON ce.user_id = u.id
LEFT JOIN emoticon_categories ec ON ce.category_id = ec.id
LEFT JOIN (
    SELECT 
        emoticon_text,
        COUNT(*) as tracked_uses,
        COUNT(DISTINCT user_id) as unique_users,
        COUNT(CASE WHEN used_at >= NOW() - INTERVAL '7 days' THEN 1 END) as recent_uses_7d
    FROM emoticon_usage
    GROUP BY emoticon_text
) usage_stats ON ce.emoticon_text = usage_stats.emoticon_text
ORDER BY ce.usage_count DESC;

-- =============================================================================
-- BACKGROUND ANALYTICS VIEWS
-- =============================================================================

-- Background usage analytics
CREATE OR REPLACE VIEW background_usage_analytics AS
SELECT 
    cb.id,
    cb.background_name,
    cb.background_type,
    cb.category,
    cb.is_preset,
    cb.is_public,
    cb.usage_count,
    cb.created_at,
    
    -- Creator info
    u.email as creator_email,
    
    -- Active usage metrics
    COUNT(ucb.id) as active_users,
    COUNT(DISTINCT ucb.chat_id) as active_chats,
    
    -- Recent activity
    COUNT(CASE WHEN ucb.set_at >= NOW() - INTERVAL '7 days' THEN 1 END) as new_adoptions_7d,
    COUNT(CASE WHEN ucb.set_at >= NOW() - INTERVAL '30 days' THEN 1 END) as new_adoptions_30d,
    
    -- Customization patterns
    AVG(ucb.custom_opacity) as avg_opacity,
    AVG(ucb.custom_blur) as avg_blur,
    COUNT(CASE WHEN ucb.custom_opacity != 1.0 THEN 1 END) as users_with_custom_opacity,
    COUNT(CASE WHEN ucb.custom_blur != 0.0 THEN 1 END) as users_with_blur,
    
    -- Popularity ranking
    ROW_NUMBER() OVER (ORDER BY cb.usage_count DESC) as popularity_rank

FROM chat_backgrounds cb
LEFT JOIN auth.users u ON cb.created_by = u.id
LEFT JOIN user_chat_backgrounds ucb ON cb.id = ucb.background_id
GROUP BY cb.id, cb.background_name, cb.background_type, cb.category, 
         cb.is_preset, cb.is_public, cb.usage_count, cb.created_at, u.email
ORDER BY cb.usage_count DESC;

-- Background type distribution
CREATE OR REPLACE VIEW background_type_distribution AS
SELECT 
    background_type,
    COUNT(*) as total_backgrounds,
    COUNT(CASE WHEN is_preset = true THEN 1 END) as preset_count,
    COUNT(CASE WHEN is_preset = false THEN 1 END) as custom_count,
    COUNT(CASE WHEN is_public = true THEN 1 END) as public_count,
    
    -- Usage statistics
    SUM(usage_count) as total_usage,
    AVG(usage_count) as avg_usage,
    MAX(usage_count) as max_usage,
    
    -- Active usage
    COUNT(DISTINCT ucb.user_id) as active_users,
    COUNT(DISTINCT ucb.chat_id) as active_chats,
    
    -- Market share
    ROUND(
        SUM(usage_count)::DECIMAL / 
        NULLIF((SELECT SUM(usage_count) FROM chat_backgrounds), 0) * 100, 2
    ) as usage_share_percent

FROM chat_backgrounds cb
LEFT JOIN user_chat_backgrounds ucb ON cb.id = ucb.background_id
GROUP BY background_type
ORDER BY total_usage DESC;

-- =============================================================================
-- MESSAGE ANALYTICS VIEWS
-- =============================================================================

-- Message type analytics
CREATE OR REPLACE VIEW message_type_analytics AS
SELECT 
    message_type,
    COUNT(*) as total_messages,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT chat_id) as unique_chats,
    
    -- Effect usage
    COUNT(CASE WHEN effect_type != 'none' THEN 1 END) as messages_with_effects,
    COUNT(CASE WHEN is_secret = true THEN 1 END) as secret_messages,
    COUNT(CASE WHEN importance_level = 'high' THEN 1 END) as high_importance,
    COUNT(CASE WHEN importance_level = 'urgent' THEN 1 END) as urgent_messages,
    
    -- Rich content
    COUNT(CASE WHEN array_length(mentions, 1) > 0 THEN 1 END) as messages_with_mentions,
    COUNT(CASE WHEN array_length(hashtags, 1) > 0 THEN 1 END) as messages_with_hashtags,
    COUNT(CASE WHEN reply_to_message_id IS NOT NULL THEN 1 END) as reply_messages,
    COUNT(CASE WHEN is_forwarded = true THEN 1 END) as forwarded_messages,
    
    -- Recent activity
    COUNT(CASE WHEN created_at >= NOW() - INTERVAL '7 days' THEN 1 END) as messages_7d,
    COUNT(CASE WHEN created_at >= NOW() - INTERVAL '30 days' THEN 1 END) as messages_30d,
    
    -- Average metrics
    AVG(array_length(mentions, 1)) as avg_mentions_per_message,
    AVG(array_length(hashtags, 1)) as avg_hashtags_per_message

FROM message_bubbles
GROUP BY message_type
ORDER BY total_messages DESC;

-- Message effect popularity
CREATE OR REPLACE VIEW message_effect_popularity AS
SELECT 
    effect_type,
    COUNT(*) as usage_count,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT chat_id) as unique_chats,
    
    -- Message type breakdown
    COUNT(CASE WHEN message_type = 'text' THEN 1 END) as text_messages,
    COUNT(CASE WHEN message_type = 'image' THEN 1 END) as image_messages,
    COUNT(CASE WHEN message_type = 'sticker' THEN 1 END) as sticker_messages,
    
    -- Recent usage
    COUNT(CASE WHEN created_at >= NOW() - INTERVAL '7 days' THEN 1 END) as uses_7d,
    COUNT(CASE WHEN created_at >= NOW() - INTERVAL '30 days' THEN 1 END) as uses_30d,
    
    -- Popularity percentage
    ROUND(
        COUNT(*)::DECIMAL / 
        NULLIF((SELECT COUNT(*) FROM message_bubbles WHERE effect_type != 'none'), 0) * 100, 2
    ) as popularity_percent

FROM message_bubbles
WHERE effect_type != 'none'
GROUP BY effect_type
ORDER BY usage_count DESC;

-- =============================================================================
-- USER BEHAVIOR ANALYTICS VIEWS
-- =============================================================================

-- User widget engagement summary
CREATE OR REPLACE VIEW user_widget_engagement AS
SELECT 
    u.id as user_id,
    u.email as username,
    u.created_at as user_joined,
    
    -- Widget usage counts
    COALESCE(sticker_stats.stickers_created, 0) as stickers_created,
    COALESCE(sticker_stats.stickers_used, 0) as stickers_used,
    COALESCE(emoticon_stats.custom_emoticons, 0) as custom_emoticons_created,
    COALESCE(emoticon_stats.emoticons_used, 0) as emoticons_used,
    COALESCE(background_stats.backgrounds_created, 0) as backgrounds_created,
    COALESCE(background_stats.background_changes, 0) as background_changes,
    COALESCE(message_stats.messages_sent, 0) as messages_sent,
    COALESCE(message_stats.reactions_given, 0) as reactions_given,
    
    -- Analytics tracking
    COALESCE(analytics_stats.total_widget_actions, 0) as total_widget_actions,
    COALESCE(analytics_stats.unique_widget_types, 0) as unique_widget_types_used,
    
    -- Engagement score calculation
    ROUND(
        (COALESCE(sticker_stats.stickers_used, 0) * 1) +
        (COALESCE(emoticon_stats.emoticons_used, 0) * 1) +
        (COALESCE(message_stats.messages_sent, 0) * 2) +
        (COALESCE(message_stats.reactions_given, 0) * 0.5) +
        (COALESCE(sticker_stats.stickers_created, 0) * 5) +
        (COALESCE(emoticon_stats.custom_emoticons, 0) * 5) +
        (COALESCE(background_stats.backgrounds_created, 0) * 3), 2
    ) as engagement_score

FROM auth.users u
LEFT JOIN (
    SELECT 
        user_id,
        COUNT(*) as stickers_created,
        COALESCE(SUM(usage_count), 0) as stickers_used
    FROM stickers
    GROUP BY user_id
) sticker_stats ON u.id = sticker_stats.user_id
LEFT JOIN (
    SELECT 
        ce.user_id,
        COUNT(DISTINCT ce.id) as custom_emoticons,
        COUNT(eu.id) as emoticons_used
    FROM custom_emoticons ce
    FULL OUTER JOIN emoticon_usage eu ON ce.user_id = eu.user_id
    GROUP BY ce.user_id
) emoticon_stats ON u.id = emoticon_stats.user_id
LEFT JOIN (
    SELECT 
        created_by as user_id,
        COUNT(*) as backgrounds_created,
        COALESCE(SUM(usage_count), 0) as background_changes
    FROM chat_backgrounds
    WHERE created_by IS NOT NULL
    GROUP BY created_by
) background_stats ON u.id = background_stats.user_id
LEFT JOIN (
    SELECT 
        mb.user_id,
        COUNT(DISTINCT mb.id) as messages_sent,
        COUNT(mr.id) as reactions_given
    FROM message_bubbles mb
    FULL OUTER JOIN message_reactions mr ON mb.user_id = mr.user_id
    GROUP BY mb.user_id
) message_stats ON u.id = message_stats.user_id
LEFT JOIN (
    SELECT 
        user_id,
        COUNT(*) as total_widget_actions,
        COUNT(DISTINCT widget_type) as unique_widget_types
    FROM widget_usage_analytics
    GROUP BY user_id
) analytics_stats ON u.id = analytics_stats.user_id
ORDER BY engagement_score DESC;

-- Power users identification
CREATE OR REPLACE VIEW widget_power_users AS
SELECT 
    uwe.user_id,
    uwe.username,
    uwe.engagement_score,
    
    -- Classification
    CASE 
        WHEN uwe.engagement_score > 1000 THEN 'super_user'
        WHEN uwe.engagement_score > 500 THEN 'power_user'
        WHEN uwe.engagement_score > 100 THEN 'active_user'
        WHEN uwe.engagement_score > 10 THEN 'casual_user'
        ELSE 'new_user'
    END as user_classification,
    
    -- Specializations
    CASE 
        WHEN uwe.stickers_created > 10 THEN true
        ELSE false
    END as is_sticker_creator,
    
    CASE 
        WHEN uwe.custom_emoticons_created > 5 THEN true
        ELSE false
    END as is_emoticon_creator,
    
    CASE 
        WHEN uwe.backgrounds_created > 3 THEN true
        ELSE false
    END as is_background_creator,
    
    -- Usage patterns
    ROUND(uwe.messages_sent::DECIMAL / NULLIF(EXTRACT(days FROM NOW() - uwe.user_joined), 0), 2) as avg_messages_per_day,
    
    -- Recent activity indicator
    CASE 
        WHEN analytics_recent.recent_actions > 50 THEN 'very_active'
        WHEN analytics_recent.recent_actions > 20 THEN 'active'
        WHEN analytics_recent.recent_actions > 5 THEN 'moderate'
        ELSE 'inactive'
    END as recent_activity_level

FROM user_widget_engagement uwe
LEFT JOIN (
    SELECT 
        user_id,
        COUNT(*) as recent_actions
    FROM widget_usage_analytics
    WHERE usage_timestamp >= NOW() - INTERVAL '7 days'
    GROUP BY user_id
) analytics_recent ON uwe.user_id = analytics_recent.user_id
WHERE uwe.engagement_score > 0
ORDER BY uwe.engagement_score DESC;

-- =============================================================================
-- TRENDING AND DISCOVERY VIEWS
-- =============================================================================

-- Trending content across all widgets
CREATE OR REPLACE VIEW trending_widget_content AS
SELECT 
    'sticker' as content_type,
    s.sticker_url as content_identifier,
    s.sticker_name as content_name,
    s.category,
    recent_stats.recent_uses_7d as recent_activity,
    recent_stats.unique_users_7d as unique_users,
    s.usage_count as total_usage,
    ROUND(
        (recent_stats.recent_uses_7d * 3) + 
        (recent_stats.unique_users_7d * 5) + 
        (s.usage_count * 0.1), 2
    ) as trending_score
FROM stickers s
INNER JOIN (
    SELECT 
        sticker_url,
        COUNT(*) as recent_uses_7d,
        COUNT(DISTINCT user_id) as unique_users_7d
    FROM recent_stickers
    WHERE used_at >= NOW() - INTERVAL '7 days'
    GROUP BY sticker_url
) recent_stats ON s.sticker_url = recent_stats.sticker_url
WHERE recent_stats.recent_uses_7d > 0

UNION ALL

SELECT 
    'emoticon' as content_type,
    ep.emoticon_text as content_identifier,
    ep.emoticon_text as content_name,
    ep.category_name as category,
    ep.uses_7d as recent_activity,
    ep.unique_users as unique_users,
    ep.total_uses as total_usage,
    ep.popularity_score as trending_score
FROM emoticon_usage_patterns ep
WHERE ep.uses_7d > 0

UNION ALL

SELECT 
    'background' as content_type,
    cb.id::TEXT as content_identifier,
    cb.background_name as content_name,
    cb.category,
    bua.new_adoptions_7d as recent_activity,
    bua.active_users as unique_users,
    cb.usage_count as total_usage,
    ROUND(
        (bua.new_adoptions_7d * 4) + 
        (bua.active_users * 2) + 
        (cb.usage_count * 0.2), 2
    ) as trending_score
FROM chat_backgrounds cb
INNER JOIN background_usage_analytics bua ON cb.id = bua.id
WHERE bua.new_adoptions_7d > 0

ORDER BY trending_score DESC
LIMIT 50;

-- =============================================================================
-- PERFORMANCE VIEWS
-- =============================================================================

-- Widget performance metrics summary
CREATE OR REPLACE VIEW widget_performance_summary AS
SELECT 
    widget_type,
    metric_name,
    
    -- Statistical measures
    COUNT(*) as sample_count,
    AVG(metric_value) as avg_value,
    MIN(metric_value) as min_value,
    MAX(metric_value) as max_value,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY metric_value) as median_value,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY metric_value) as p95_value,
    STDDEV(metric_value) as std_deviation,
    
    -- Recent performance
    AVG(CASE WHEN recorded_at >= NOW() - INTERVAL '7 days' THEN metric_value END) as avg_7d,
    AVG(CASE WHEN recorded_at >= NOW() - INTERVAL '30 days' THEN metric_value END) as avg_30d,
    
    -- Performance trend
    CASE 
        WHEN AVG(CASE WHEN recorded_at >= NOW() - INTERVAL '7 days' THEN metric_value END) >
             AVG(CASE WHEN recorded_at >= NOW() - INTERVAL '14 days' AND recorded_at < NOW() - INTERVAL '7 days' THEN metric_value END)
        THEN 'improving'
        WHEN AVG(CASE WHEN recorded_at >= NOW() - INTERVAL '7 days' THEN metric_value END) <
             AVG(CASE WHEN recorded_at >= NOW() - INTERVAL '14 days' AND recorded_at < NOW() - INTERVAL '7 days' THEN metric_value END)
        THEN 'degrading'
        ELSE 'stable'
    END as performance_trend

FROM widget_performance_metrics
WHERE recorded_at >= NOW() - INTERVAL '30 days'
GROUP BY widget_type, metric_name
ORDER BY widget_type, metric_name;

-- =============================================================================
-- GRANT PERMISSIONS
-- =============================================================================

-- Grant select permissions on views to authenticated users
GRANT SELECT ON sticker_analytics_overview TO authenticated;
GRANT SELECT ON sticker_category_performance TO authenticated;
GRANT SELECT ON top_sticker_creators TO authenticated;
GRANT SELECT ON emoticon_usage_patterns TO authenticated;
GRANT SELECT ON custom_emoticon_performance TO authenticated;
GRANT SELECT ON background_usage_analytics TO authenticated;
GRANT SELECT ON background_type_distribution TO authenticated;
GRANT SELECT ON message_type_analytics TO authenticated;
GRANT SELECT ON message_effect_popularity TO authenticated;
GRANT SELECT ON user_widget_engagement TO authenticated;
GRANT SELECT ON widget_power_users TO authenticated;
GRANT SELECT ON trending_widget_content TO authenticated;

-- Grant select permissions on performance views to service role
GRANT SELECT ON widget_performance_summary TO service_role;

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON VIEW sticker_analytics_overview IS 'Comprehensive sticker analytics with usage metrics and popularity rankings';
COMMENT ON VIEW sticker_category_performance IS 'Performance metrics and statistics for each sticker category';
COMMENT ON VIEW top_sticker_creators IS 'Top sticker creators ranked by usage and approval metrics';
COMMENT ON VIEW emoticon_usage_patterns IS 'Emoticon usage patterns and popularity analysis';
COMMENT ON VIEW custom_emoticon_performance IS 'Performance metrics for user-created custom emoticons';
COMMENT ON VIEW background_usage_analytics IS 'Background usage analytics with customization patterns';
COMMENT ON VIEW background_type_distribution IS 'Distribution and market share of different background types';
COMMENT ON VIEW message_type_analytics IS 'Analytics for different message types and features';
COMMENT ON VIEW message_effect_popularity IS 'Popularity rankings for message effects and animations';
COMMENT ON VIEW user_widget_engagement IS 'Comprehensive user engagement metrics across all widgets';
COMMENT ON VIEW widget_power_users IS 'Identification and classification of power users';
COMMENT ON VIEW trending_widget_content IS 'Trending content across all widget types';
COMMENT ON VIEW widget_performance_summary IS 'Performance metrics summary for optimization';

-- Setup completion message
SELECT 'Widgets Views and Analytics Setup Complete!' as status, NOW() as setup_completed_at;
