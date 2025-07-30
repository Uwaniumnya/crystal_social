-- Crystal Social UserInfo System - Views and Analytics
-- File: 03_userinfo_views_analytics.sql
-- Purpose: Database views, materialized views, and analytics for comprehensive user information system

-- =============================================================================
-- USER PROFILE OVERVIEW VIEWS
-- =============================================================================

-- Comprehensive user profile view with completion and statistics
CREATE OR REPLACE VIEW user_profile_overview AS
SELECT 
    u.id as user_id,
    u.email as username,
    u.raw_user_meta_data->>'avatar_url' as avatar_url,
    u.raw_user_meta_data->>'avatar_decoration' as avatar_decoration,
    u.raw_user_meta_data->>'bio' as bio,
    u.created_at as user_created_at,
    u.updated_at as last_active,
    
    -- Profile completion data
    pc.completion_percentage,
    pc.total_categories_used,
    pc.total_items_count,
    pc.has_free_text,
    pc.has_avatar,
    pc.has_bio,
    pc.completion_score,
    pc.profile_quality_score,
    pc.last_updated_at as profile_last_updated,
    
    -- Discovery settings
    ds.is_discoverable,
    ds.privacy_level,
    ds.allow_profile_views,
    ds.show_completion_percentage,
    
    -- Analytics summary
    COALESCE(ua.total_profile_views, 0) as total_profile_views,
    COALESCE(ua.unique_viewers, 0) as unique_viewers,
    COALESCE(ua.engagement_score, 0) as engagement_score,
    COALESCE(ua.discovery_rank, 0) as discovery_rank,
    
    -- Profile categorization
    CASE 
        WHEN pc.completion_percentage >= 80 THEN 'complete'
        WHEN pc.completion_percentage >= 50 THEN 'partial'
        WHEN pc.completion_percentage >= 20 THEN 'basic'
        ELSE 'minimal'
    END as profile_completeness_level,
    
    CASE
        WHEN pc.profile_quality_score >= 8 THEN 'excellent'
        WHEN pc.profile_quality_score >= 6 THEN 'good'
        WHEN pc.profile_quality_score >= 4 THEN 'fair'
        ELSE 'needs_improvement'
    END as profile_quality_level

FROM auth.users u
LEFT JOIN user_profile_completion pc ON u.id = pc.user_id
LEFT JOIN user_discovery_settings ds ON u.id = ds.user_id
LEFT JOIN (
    SELECT 
        user_id,
        SUM(total_profile_views) as total_profile_views,
        SUM(unique_viewers) as unique_viewers,
        AVG(engagement_score) as engagement_score,
        MAX(discovery_rank) as discovery_rank
    FROM user_info_analytics
    WHERE analysis_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY user_id
) ua ON u.id = ua.user_id;

-- User category summary view
CREATE OR REPLACE VIEW user_category_summary AS
SELECT 
    u.id as user_id,
    u.email as username,
    cat.category_name,
    cat.display_name,
    cat.category_group,
    cat.icon_name,
    cat.color_hex,
    
    -- Item counts
    COUNT(ui.id) as item_count,
    MIN(ui.created_at) as first_item_added,
    MAX(ui.updated_at) as last_item_updated,
    
    -- User preferences
    cp.is_favorite,
    cp.is_hidden,
    cp.custom_order,
    cp.custom_icon,
    cp.custom_color,
    cp.last_accessed_at,
    cp.access_count,
    
    -- Category popularity
    COALESCE(cat_stats.total_users, 0) as category_total_users,
    COALESCE(cat_stats.avg_items_per_user, 0) as category_avg_items,
    
    -- Recent activity
    COUNT(CASE WHEN ui.created_at >= NOW() - INTERVAL '7 days' THEN 1 END) as items_added_7d,
    COUNT(CASE WHEN ui.updated_at >= NOW() - INTERVAL '7 days' THEN 1 END) as items_updated_7d

FROM auth.users u
CROSS JOIN user_info_categories cat
LEFT JOIN user_info ui ON u.id = ui.user_id AND cat.category_name = ui.category AND ui.info_type = 'category'
LEFT JOIN user_category_preferences cp ON u.id = cp.user_id AND cat.category_name = cp.category_name
LEFT JOIN (
    SELECT 
        category,
        COUNT(DISTINCT user_id) as total_users,
        AVG(COUNT(*)) OVER (PARTITION BY category) as avg_items_per_user
    FROM user_info
    WHERE info_type = 'category'
    GROUP BY category, user_id
) cat_stats ON cat.category_name = cat_stats.category
WHERE cat.is_active = true
GROUP BY 
    u.id, u.email, cat.category_name, cat.display_name, cat.category_group,
    cat.icon_name, cat.color_hex, cat.category_order, cp.is_favorite, cp.is_hidden, cp.custom_order,
    cp.custom_icon, cp.custom_color, cp.last_accessed_at, cp.access_count,
    cat_stats.total_users, cat_stats.avg_items_per_user
ORDER BY 
    u.email, 
    COALESCE(cp.custom_order, cat.category_order), 
    cat.category_name;

-- Discovery-ready users view
CREATE OR REPLACE VIEW discoverable_users AS
SELECT 
    upo.user_id,
    upo.username,
    upo.avatar_url,
    upo.avatar_decoration,
    upo.bio,
    upo.completion_percentage,
    upo.total_categories_used,
    upo.total_items_count,
    upo.profile_quality_score,
    upo.total_profile_views,
    upo.engagement_score,
    upo.profile_completeness_level,
    upo.profile_quality_level,
    upo.last_active,
    
    -- Popular categories for this user
    COALESCE(popular_cats.categories, '{}') as popular_categories,
    
    -- Recent activity indicator
    CASE 
        WHEN upo.last_active >= NOW() - INTERVAL '7 days' THEN 'very_recent'
        WHEN upo.last_active >= NOW() - INTERVAL '30 days' THEN 'recent'
        WHEN upo.last_active >= NOW() - INTERVAL '90 days' THEN 'moderate'
        ELSE 'inactive'
    END as activity_level

FROM user_profile_overview upo
LEFT JOIN (
    SELECT 
        user_id,
        array_agg(category ORDER BY item_count DESC) as categories
    FROM (
        SELECT 
            user_id,
            category,
            COUNT(*) as item_count
        FROM user_info
        WHERE info_type = 'category'
        GROUP BY user_id, category
        ORDER BY COUNT(*) DESC
        LIMIT 5
    ) top_cats
    GROUP BY user_id
) popular_cats ON upo.user_id = popular_cats.user_id
WHERE 
    upo.is_discoverable = true
    AND upo.privacy_level = 'public'
    AND upo.completion_percentage > 10  -- Minimum completion for discovery
ORDER BY 
    upo.engagement_score DESC,
    upo.profile_quality_score DESC,
    upo.last_active DESC;

-- =============================================================================
-- CATEGORY ANALYTICS VIEWS
-- =============================================================================

-- Category popularity and usage statistics
CREATE OR REPLACE VIEW category_analytics AS
SELECT 
    cat.category_name,
    cat.display_name,
    cat.description,
    cat.category_group,
    cat.icon_name,
    cat.color_hex,
    cat.category_order,
    cat.max_items,
    
    -- Usage statistics
    COUNT(DISTINCT ui.user_id) as unique_users,
    COUNT(ui.id) as total_items,
    ROUND(COUNT(ui.id)::DECIMAL / NULLIF(COUNT(DISTINCT ui.user_id), 0), 2) as avg_items_per_user,
    
    -- Popularity metrics
    ROUND(100.0 * COUNT(DISTINCT ui.user_id) / NULLIF(total_users.total, 0), 2) as adoption_percentage,
    
    -- Content quality metrics
    ROUND(AVG(LENGTH(ui.content)), 0) as avg_content_length,
    MIN(LENGTH(ui.content)) as min_content_length,
    MAX(LENGTH(ui.content)) as max_content_length,
    
    -- Activity metrics
    COUNT(CASE WHEN ui.created_at >= NOW() - INTERVAL '7 days' THEN 1 END) as items_added_7d,
    COUNT(CASE WHEN ui.created_at >= NOW() - INTERVAL '30 days' THEN 1 END) as items_added_30d,
    COUNT(CASE WHEN ui.updated_at >= NOW() - INTERVAL '7 days' THEN 1 END) as items_updated_7d,
    
    -- User preference metrics
    COUNT(DISTINCT CASE WHEN cp.is_favorite = true THEN cp.user_id END) as favorited_by_users,
    COUNT(DISTINCT CASE WHEN cp.is_hidden = true THEN cp.user_id END) as hidden_by_users,
    ROUND(AVG(cp.access_count), 1) as avg_access_count,
    
    -- Ranking
    ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT ui.user_id) DESC) as popularity_rank,
    ROW_NUMBER() OVER (ORDER BY COUNT(ui.id) DESC) as content_volume_rank

FROM user_info_categories cat
LEFT JOIN user_info ui ON cat.category_name = ui.category AND ui.info_type = 'category'
LEFT JOIN user_category_preferences cp ON cat.category_name = cp.category_name
CROSS JOIN (SELECT COUNT(DISTINCT id) as total FROM auth.users) total_users
WHERE cat.is_active = true
GROUP BY 
    cat.category_name, cat.display_name, cat.description, cat.category_group,
    cat.icon_name, cat.color_hex, cat.category_order, cat.max_items, total_users.total
ORDER BY popularity_rank;

-- Category group summary
CREATE OR REPLACE VIEW category_group_summary AS
SELECT 
    category_group,
    COUNT(*) as total_categories,
    SUM(unique_users) as total_unique_users,
    SUM(total_items) as total_items,
    ROUND(AVG(adoption_percentage), 2) as avg_adoption_percentage,
    ROUND(AVG(avg_items_per_user), 2) as avg_items_per_user,
    SUM(items_added_7d) as items_added_7d,
    SUM(items_added_30d) as items_added_30d,
    ROUND(AVG(avg_content_length), 0) as avg_content_length,
    
    -- Group popularity
    ROW_NUMBER() OVER (ORDER BY SUM(unique_users) DESC) as group_popularity_rank
    
FROM category_analytics
GROUP BY category_group
ORDER BY group_popularity_rank;

-- =============================================================================
-- USER ENGAGEMENT AND INTERACTION VIEWS
-- =============================================================================

-- User interaction summary
CREATE OR REPLACE VIEW user_interaction_summary AS
SELECT 
    ui.viewed_user_id as user_id,
    
    -- View statistics
    COUNT(*) as total_interactions,
    COUNT(DISTINCT ui.viewer_user_id) as unique_viewers,
    COUNT(CASE WHEN ui.interaction_type = 'profile_view' THEN 1 END) as profile_views,
    COUNT(CASE WHEN ui.interaction_type = 'category_view' THEN 1 END) as category_views,
    COUNT(CASE WHEN ui.interaction_type = 'search' THEN 1 END) as search_appearances,
    
    -- Recent activity
    COUNT(CASE WHEN ui.created_at >= NOW() - INTERVAL '24 hours' THEN 1 END) as interactions_24h,
    COUNT(CASE WHEN ui.created_at >= NOW() - INTERVAL '7 days' THEN 1 END) as interactions_7d,
    COUNT(CASE WHEN ui.created_at >= NOW() - INTERVAL '30 days' THEN 1 END) as interactions_30d,
    
    -- Engagement quality
    ROUND(AVG(ui.view_duration_seconds), 1) as avg_view_duration,
    MAX(ui.view_duration_seconds) as max_view_duration,
    
    -- Popular categories
    array_agg(DISTINCT ui.category_name ORDER BY ui.category_name) 
        FILTER (WHERE ui.category_name IS NOT NULL) as viewed_categories,
    
    -- Timing patterns
    MIN(ui.created_at) as first_interaction,
    MAX(ui.created_at) as latest_interaction,
    
    -- Viewer diversity
    COUNT(DISTINCT DATE(ui.created_at)) as active_days,
    ROUND(COUNT(*)::DECIMAL / NULLIF(COUNT(DISTINCT DATE(ui.created_at)), 0), 1) as avg_interactions_per_day

FROM user_info_interactions ui
WHERE ui.created_at >= NOW() - INTERVAL '90 days'  -- Last 90 days
GROUP BY ui.viewed_user_id
ORDER BY total_interactions DESC;

-- Top viewed profiles
CREATE OR REPLACE VIEW top_viewed_profiles AS
SELECT 
    upo.user_id,
    upo.username,
    upo.avatar_url,
    upo.completion_percentage,
    upo.profile_quality_score,
    upo.total_categories_used,
    upo.total_items_count,
    
    -- Interaction metrics
    uis.total_interactions,
    uis.unique_viewers,
    uis.profile_views,
    uis.interactions_7d,
    uis.avg_view_duration,
    uis.viewed_categories,
    
    -- Engagement rate
    ROUND(uis.total_interactions::DECIMAL / NULLIF(upo.total_profile_views, 0) * 100, 2) as interaction_rate,
    
    -- Activity recency
    EXTRACT(days FROM NOW() - uis.latest_interaction) as days_since_last_view,
    
    -- Ranking
    ROW_NUMBER() OVER (ORDER BY uis.total_interactions DESC) as interaction_rank,
    ROW_NUMBER() OVER (ORDER BY uis.unique_viewers DESC) as viewer_rank

FROM user_profile_overview upo
INNER JOIN user_interaction_summary uis ON upo.user_id = uis.user_id
WHERE 
    upo.is_discoverable = true 
    AND uis.total_interactions > 0
ORDER BY uis.total_interactions DESC
LIMIT 100;

-- =============================================================================
-- CONTENT QUALITY AND MODERATION VIEWS
-- =============================================================================

-- Content moderation overview
CREATE OR REPLACE VIEW content_moderation_overview AS
SELECT 
    ui.id as user_info_id,
    ui.user_id,
    users.email as username,
    ui.category,
    LEFT(ui.content, 100) as content_preview,
    LENGTH(ui.content) as content_length,
    ui.info_type,
    ui.created_at,
    ui.updated_at,
    
    -- Moderation status
    COALESCE(um.moderation_status, 'unreviewed') as moderation_status,
    um.moderation_reason,
    um.automated_score,
    um.contains_sensitive_content,
    um.flag_count,
    um.moderator_user_id,
    um.approved_at,
    
    -- Content analysis
    CASE 
        WHEN LENGTH(ui.content) < 10 THEN 'very_short'
        WHEN LENGTH(ui.content) < 50 THEN 'short'
        WHEN LENGTH(ui.content) < 200 THEN 'medium'
        ELSE 'long'
    END as content_length_category,
    
    -- Priority for review
    CASE 
        WHEN um.flag_count > 3 THEN 'high'
        WHEN um.automated_score < 3 THEN 'high'
        WHEN um.contains_sensitive_content THEN 'medium'
        WHEN um.moderation_status = 'pending' THEN 'medium'
        ELSE 'low'
    END as review_priority

FROM user_info ui
LEFT JOIN user_info_moderation um ON ui.id = um.user_info_id
LEFT JOIN auth.users users ON ui.user_id = users.id
WHERE ui.created_at >= NOW() - INTERVAL '30 days'  -- Recent content only
ORDER BY 
    CASE 
        WHEN um.flag_count > 3 THEN 1
        WHEN um.automated_score < 3 THEN 2
        WHEN um.contains_sensitive_content THEN 3
        ELSE 4
    END,
    ui.created_at DESC;

-- User content quality metrics
CREATE OR REPLACE VIEW user_content_quality AS
SELECT 
    ui.user_id,
    users.email as username,
    
    -- Content volume
    COUNT(*) as total_content_items,
    COUNT(CASE WHEN ui.info_type = 'category' THEN 1 END) as category_items,
    COUNT(CASE WHEN ui.info_type = 'free_text' THEN 1 END) as free_text_items,
    
    -- Content quality metrics
    ROUND(AVG(LENGTH(ui.content)), 1) as avg_content_length,
    MIN(LENGTH(ui.content)) as min_content_length,
    MAX(LENGTH(ui.content)) as max_content_length,
    SUM(LENGTH(ui.content)) as total_content_length,
    
    -- Moderation metrics
    COUNT(CASE WHEN um.moderation_status = 'approved' THEN 1 END) as approved_items,
    COUNT(CASE WHEN um.moderation_status = 'flagged' THEN 1 END) as flagged_items,
    COUNT(CASE WHEN um.moderation_status = 'removed' THEN 1 END) as removed_items,
    SUM(COALESCE(um.flag_count, 0)) as total_flags_received,
    ROUND(AVG(COALESCE(um.automated_score, 5)), 2) as avg_automated_score,
    
    -- Content freshness
    MAX(ui.updated_at) as last_content_update,
    COUNT(CASE WHEN ui.updated_at >= NOW() - INTERVAL '7 days' THEN 1 END) as updates_7d,
    COUNT(CASE WHEN ui.created_at >= NOW() - INTERVAL '30 days' THEN 1 END) as items_added_30d,
    
    -- Quality score calculation
    ROUND(
        LEAST(10.0, 
            (COUNT(*) * 0.5) +  -- Volume factor
            (AVG(LENGTH(ui.content)) / 50.0) +  -- Length factor
            (COUNT(CASE WHEN um.moderation_status = 'approved' THEN 1 END) * 2.0) -  -- Approved bonus
            (COUNT(CASE WHEN um.moderation_status = 'flagged' THEN 1 END) * 1.0)  -- Flagged penalty
        ), 2
    ) as content_quality_score

FROM user_info ui
LEFT JOIN user_info_moderation um ON ui.id = um.user_info_id
LEFT JOIN auth.users users ON ui.user_id = users.id
GROUP BY ui.user_id, users.email
ORDER BY content_quality_score DESC;

-- =============================================================================
-- COMMUNITY AND TRENDING VIEWS
-- =============================================================================

-- Active community members
CREATE OR REPLACE VIEW active_community_members AS
SELECT 
    upo.user_id,
    upo.username,
    upo.avatar_url,
    upo.completion_percentage,
    upo.total_categories_used,
    upo.total_items_count,
    upo.profile_quality_score,
    
    -- Activity level calculation
    CASE 
        WHEN upo.last_active >= NOW() - INTERVAL '7 days' THEN 'very_recent'
        WHEN upo.last_active >= NOW() - INTERVAL '30 days' THEN 'recent'
        WHEN upo.last_active >= NOW() - INTERVAL '90 days' THEN 'moderate'
        ELSE 'inactive'
    END as activity_level,
    
    -- Recent activity metrics
    COALESCE(recent_activity.items_added_7d, 0) as items_added_7d,
    COALESCE(recent_activity.items_updated_7d, 0) as items_updated_7d,
    COALESCE(recent_activity.categories_active_7d, 0) as categories_active_7d,
    
    -- Social metrics
    COALESCE(uis.interactions_7d, 0) as profile_views_7d,
    COALESCE(uis.unique_viewers, 0) as total_unique_viewers,
    
    -- Community engagement score
    ROUND(
        (COALESCE(recent_activity.items_added_7d, 0) * 2.0) +
        (COALESCE(recent_activity.items_updated_7d, 0) * 1.0) +
        (COALESCE(uis.interactions_7d, 0) * 0.5) +
        (upo.profile_quality_score * 2.0)
    , 2) as community_engagement_score

FROM user_profile_overview upo
LEFT JOIN (
    SELECT 
        user_id,
        COUNT(CASE WHEN created_at >= NOW() - INTERVAL '7 days' THEN 1 END) as items_added_7d,
        COUNT(CASE WHEN updated_at >= NOW() - INTERVAL '7 days' THEN 1 END) as items_updated_7d,
        COUNT(DISTINCT CASE WHEN updated_at >= NOW() - INTERVAL '7 days' THEN category END) as categories_active_7d
    FROM user_info
    WHERE info_type = 'category'
    GROUP BY user_id
) recent_activity ON upo.user_id = recent_activity.user_id
LEFT JOIN user_interaction_summary uis ON upo.user_id = uis.user_id
WHERE 
    upo.is_discoverable = true
    AND (upo.last_active >= NOW() - INTERVAL '30 days')  -- Recent activity filter
    AND upo.completion_percentage > 20
ORDER BY community_engagement_score DESC
LIMIT 50;

-- Trending content and categories
CREATE OR REPLACE VIEW trending_content AS
SELECT 
    'category' as trend_type,
    ui.category as item_identifier,
    cat.display_name as item_name,
    cat.category_group as item_group,
    
    -- Trend metrics
    COUNT(*) as total_items,
    COUNT(DISTINCT ui.user_id) as unique_contributors,
    COUNT(CASE WHEN ui.created_at >= NOW() - INTERVAL '7 days' THEN 1 END) as items_7d,
    COUNT(CASE WHEN ui.created_at >= NOW() - INTERVAL '30 days' THEN 1 END) as items_30d,
    
    -- Growth rate
    ROUND(
        COUNT(CASE WHEN ui.created_at >= NOW() - INTERVAL '7 days' THEN 1 END)::DECIMAL /
        NULLIF(COUNT(CASE WHEN ui.created_at >= NOW() - INTERVAL '14 days' AND ui.created_at < NOW() - INTERVAL '7 days' THEN 1 END), 0) * 100 - 100,
        1
    ) as growth_rate_7d,
    
    -- Trending score
    ROUND(
        (COUNT(CASE WHEN ui.created_at >= NOW() - INTERVAL '7 days' THEN 1 END) * 3.0) +
        (COUNT(DISTINCT ui.user_id) * 2.0) +
        (COUNT(*) * 0.1)
    , 2) as trending_score

FROM user_info ui
INNER JOIN user_info_categories cat ON ui.category = cat.category_name
WHERE 
    ui.info_type = 'category'
    AND ui.created_at >= NOW() - INTERVAL '30 days'
GROUP BY ui.category, cat.display_name, cat.category_group
HAVING COUNT(CASE WHEN ui.created_at >= NOW() - INTERVAL '7 days' THEN 1 END) > 0
ORDER BY trending_score DESC
LIMIT 20;

-- =============================================================================
-- MATERIALIZED VIEWS FOR PERFORMANCE
-- =============================================================================

-- Daily user activity summary (refresh daily)
CREATE MATERIALIZED VIEW daily_user_activity AS
SELECT 
    DATE(ui.created_at) as activity_date,
    COUNT(DISTINCT ui.user_id) as active_users,
    COUNT(*) as total_items_created,
    COUNT(CASE WHEN ui.info_type = 'category' THEN 1 END) as category_items_created,
    COUNT(CASE WHEN ui.info_type = 'free_text' THEN 1 END) as free_text_items_created,
    COUNT(DISTINCT ui.category) as categories_used,
    ROUND(AVG(LENGTH(ui.content)), 1) as avg_content_length,
    
    -- User engagement
    COUNT(DISTINCT interactions.viewer_user_id) as profile_viewers,
    COUNT(interactions.id) as total_interactions
    
FROM user_info ui
LEFT JOIN user_info_interactions interactions ON DATE(ui.created_at) = DATE(interactions.created_at)
WHERE ui.created_at >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY DATE(ui.created_at)
ORDER BY activity_date DESC;

-- Weekly category trends (refresh weekly)
CREATE MATERIALIZED VIEW weekly_category_trends AS
SELECT 
    DATE_TRUNC('week', ui.created_at) as week_start,
    ui.category,
    cat.display_name,
    cat.category_group,
    COUNT(*) as items_created,
    COUNT(DISTINCT ui.user_id) as unique_users,
    ROUND(AVG(LENGTH(ui.content)), 1) as avg_content_length,
    
    -- Calculate week-over-week growth
    LAG(COUNT(*)) OVER (PARTITION BY ui.category ORDER BY DATE_TRUNC('week', ui.created_at)) as prev_week_items,
    ROUND(
        (COUNT(*) - LAG(COUNT(*)) OVER (PARTITION BY ui.category ORDER BY DATE_TRUNC('week', ui.created_at)))::DECIMAL /
        NULLIF(LAG(COUNT(*)) OVER (PARTITION BY ui.category ORDER BY DATE_TRUNC('week', ui.created_at)), 0) * 100,
        1
    ) as week_over_week_growth

FROM user_info ui
INNER JOIN user_info_categories cat ON ui.category = cat.category_name
WHERE 
    ui.info_type = 'category'
    AND ui.created_at >= DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '12 weeks'
GROUP BY DATE_TRUNC('week', ui.created_at), ui.category, cat.display_name, cat.category_group
ORDER BY week_start DESC, items_created DESC;

-- =============================================================================
-- VIEW PERMISSIONS AND INDEXES
-- =============================================================================

-- Grant permissions for views
GRANT SELECT ON user_profile_overview TO authenticated;
GRANT SELECT ON user_category_summary TO authenticated;
GRANT SELECT ON discoverable_users TO authenticated;
GRANT SELECT ON category_analytics TO service_role;
GRANT SELECT ON category_group_summary TO service_role;
GRANT SELECT ON user_interaction_summary TO authenticated;
GRANT SELECT ON top_viewed_profiles TO authenticated;
GRANT SELECT ON content_moderation_overview TO service_role;
GRANT SELECT ON user_content_quality TO authenticated;
GRANT SELECT ON active_community_members TO authenticated;
GRANT SELECT ON trending_content TO authenticated;
GRANT SELECT ON daily_user_activity TO service_role;
GRANT SELECT ON weekly_category_trends TO service_role;

-- Create indexes for materialized views
CREATE UNIQUE INDEX idx_daily_user_activity_date 
ON daily_user_activity (activity_date);

CREATE UNIQUE INDEX idx_weekly_category_trends_week_category 
ON weekly_category_trends (week_start, category);

-- =============================================================================
-- REFRESH FUNCTIONS FOR MATERIALIZED VIEWS
-- =============================================================================

-- Refresh daily activity stats (call daily)
CREATE OR REPLACE FUNCTION refresh_daily_user_activity()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY daily_user_activity;
    RETURN 'Daily user activity refreshed at ' || NOW();
END;
$$;

-- Refresh weekly trends (call weekly)
CREATE OR REPLACE FUNCTION refresh_weekly_category_trends()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY weekly_category_trends;
    RETURN 'Weekly category trends refreshed at ' || NOW();
END;
$$;

-- Grant execution permissions
GRANT EXECUTE ON FUNCTION refresh_daily_user_activity TO service_role;
GRANT EXECUTE ON FUNCTION refresh_weekly_category_trends TO service_role;

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON VIEW user_profile_overview IS 'Comprehensive user profile information with completion and analytics';
COMMENT ON VIEW user_category_summary IS 'Detailed category usage and preferences for each user';
COMMENT ON VIEW discoverable_users IS 'Public users available for community discovery with quality metrics';
COMMENT ON VIEW category_analytics IS 'Popularity and usage statistics for all categories';
COMMENT ON VIEW user_interaction_summary IS 'User profile interaction and engagement metrics';
COMMENT ON VIEW content_moderation_overview IS 'Content requiring moderation review with priority scoring';
COMMENT ON VIEW active_community_members IS 'Most engaged community members with activity metrics';
COMMENT ON VIEW trending_content IS 'Trending categories and content with growth metrics';
COMMENT ON MATERIALIZED VIEW daily_user_activity IS 'Daily aggregated user activity metrics (refresh daily)';
COMMENT ON MATERIALIZED VIEW weekly_category_trends IS 'Weekly category usage trends (refresh weekly)';

-- Setup completion message
SELECT 'UserInfo Views and Analytics Setup Complete!' as status, NOW() as setup_completed_at;
