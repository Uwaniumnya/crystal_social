-- =====================================================
-- CRYSTAL SOCIAL - PROFILE SYSTEM VIEWS
-- =====================================================
-- Optimized views for profile dashboards and analytics
-- =====================================================

-- =====================================================
-- PROFILE DASHBOARD VIEWS
-- =====================================================

-- Comprehensive user profile view with all related data
CREATE OR REPLACE VIEW user_profiles_enriched AS
SELECT 
    up.id as profile_id,
    up.user_id,
    up.username,
    up.display_name,
    COALESCE(up.display_name, up.username) as effective_display_name,
    up.bio,
    up.avatar_url,
    up.avatar_decoration,
    up.location,
    up.website,
    up.zodiac_sign,
    up.interests,
    up.social_links,
    up.profile_theme,
    up.is_private,
    up.is_verified,
    up.reputation_score,
    up.profile_completion_percentage,
    up.last_active_at,
    up.created_at as profile_created_at,
    up.updated_at as profile_updated_at,
    
    -- Activity statistics
    uas.user_level,
    uas.experience_points,
    uas.total_messages_sent,
    uas.total_reactions_received,
    uas.total_reactions_given,
    uas.friends_count,
    uas.groups_joined,
    uas.current_streak_days,
    uas.longest_streak_days,
    uas.most_active_hour,
    uas.most_active_day_of_week,
    
    -- Engagement metrics
    CASE 
        WHEN uas.total_messages_sent > 0 
        THEN ROUND((uas.total_reactions_received::DECIMAL / uas.total_messages_sent) * 100, 2)
        ELSE 0
    END as engagement_rate,
    
    -- Activity status
    CASE 
        WHEN up.last_active_at > NOW() - INTERVAL '5 minutes' THEN 'online'
        WHEN up.last_active_at > NOW() - INTERVAL '1 hour' THEN 'recently_active'
        WHEN up.last_active_at > NOW() - INTERVAL '1 day' THEN 'today'
        WHEN up.last_active_at > NOW() - INTERVAL '7 days' THEN 'this_week'
        ELSE 'inactive'
    END as activity_status,
    
    -- Decorations info
    (
        SELECT json_agg(
            json_build_object(
                'decoration_id', uad.decoration_id,
                'name', adc.name,
                'category', adc.category,
                'rarity', adc.rarity,
                'is_equipped', uad.is_equipped,
                'unlocked_at', uad.unlocked_at
            )
        )
        FROM user_avatar_decorations uad
        JOIN avatar_decorations_catalog adc ON uad.decoration_id = adc.decoration_id
        WHERE uad.user_id = up.user_id
    ) as owned_decorations,
    
    -- Achievement summary
    (
        SELECT json_build_object(
            'total_completed', COUNT(*) FILTER (WHERE is_completed = true),
            'total_in_progress', COUNT(*) FILTER (WHERE is_completed = false),
            'total_experience_earned', COALESCE(SUM(
                CASE WHEN is_completed THEN pa.experience_reward ELSE 0 END
            ), 0),
            'completion_percentage', ROUND(
                (COUNT(*) FILTER (WHERE is_completed = true)::DECIMAL / 
                 GREATEST(COUNT(*), 1)) * 100, 2
            )
        )
        FROM user_profile_achievements upa
        JOIN profile_achievements pa ON upa.achievement_id = pa.achievement_id
        WHERE upa.user_id = up.user_id
    ) as achievements_summary
    
FROM user_profiles up
LEFT JOIN user_activity_stats uas ON up.user_id = uas.user_id;

-- Leaderboard view for user rankings
CREATE OR REPLACE VIEW user_leaderboards AS
SELECT 
    up.user_id,
    up.username,
    up.display_name,
    up.avatar_url,
    up.avatar_decoration,
    up.is_verified,
    
    -- Experience leaderboard
    uas.experience_points,
    RANK() OVER (ORDER BY uas.experience_points DESC) as experience_rank,
    
    -- Level leaderboard
    uas.user_level,
    RANK() OVER (ORDER BY uas.user_level DESC, uas.experience_points DESC) as level_rank,
    
    -- Message leaderboard
    uas.total_messages_sent,
    RANK() OVER (ORDER BY uas.total_messages_sent DESC) as message_rank,
    
    -- Streak leaderboard
    uas.current_streak_days,
    RANK() OVER (ORDER BY uas.current_streak_days DESC, uas.longest_streak_days DESC) as streak_rank,
    
    -- Reputation leaderboard
    up.reputation_score,
    RANK() OVER (ORDER BY up.reputation_score DESC) as reputation_rank,
    
    -- Social leaderboard
    uas.friends_count,
    RANK() OVER (ORDER BY uas.friends_count DESC) as social_rank,
    
    -- Engagement rate
    CASE 
        WHEN uas.total_messages_sent > 0 
        THEN ROUND((uas.total_reactions_received::DECIMAL / uas.total_messages_sent) * 100, 2)
        ELSE 0
    END as engagement_rate,
    RANK() OVER (
        ORDER BY 
            CASE 
                WHEN uas.total_messages_sent > 0 
                THEN (uas.total_reactions_received::DECIMAL / uas.total_messages_sent) 
                ELSE 0
            END DESC
    ) as engagement_rank
    
FROM user_profiles up
JOIN user_activity_stats uas ON up.user_id = uas.user_id
WHERE up.last_active_at > NOW() - INTERVAL '30 days' -- Only active users
ORDER BY uas.experience_points DESC;

-- =====================================================
-- ACTIVITY ANALYTICS VIEWS
-- =====================================================

-- Weekly activity summary view
CREATE OR REPLACE VIEW weekly_activity_summary AS
SELECT 
    pds.user_id,
    DATE_TRUNC('week', pds.date) as week_start,
    
    -- Activity metrics
    SUM(pds.messages_sent) as total_messages,
    SUM(pds.reactions_given) as total_reactions_given,
    SUM(pds.reactions_received) as total_reactions_received,
    SUM(pds.active_minutes) as total_active_minutes,
    
    -- Profile engagement
    SUM(pds.profile_views) as total_profile_views,
    SUM(pds.profile_views_unique) as total_unique_profile_views,
    SUM(pds.decoration_changes) as total_decoration_changes,
    
    -- Social activity
    SUM(pds.new_connections) as total_new_connections,
    SUM(pds.connection_requests_sent) as total_connection_requests_sent,
    SUM(pds.connection_requests_received) as total_connection_requests_received,
    
    -- Achievements
    SUM(pds.achievement_unlocks) as total_achievement_unlocks,
    SUM(pds.experience_gained) as total_experience_gained,
    
    -- Daily averages
    ROUND(AVG(pds.messages_sent), 2) as avg_daily_messages,
    ROUND(AVG(pds.active_minutes), 2) as avg_daily_active_minutes,
    
    -- Activity days
    COUNT(*) FILTER (WHERE pds.messages_sent > 0 OR pds.active_minutes > 0) as active_days,
    COUNT(*) as total_days_in_period
    
FROM profile_daily_stats pds
WHERE pds.date >= CURRENT_DATE - INTERVAL '8 weeks'
GROUP BY pds.user_id, DATE_TRUNC('week', pds.date)
ORDER BY week_start DESC;

-- Monthly activity trends view
CREATE OR REPLACE VIEW monthly_activity_trends AS
SELECT 
    pds.user_id,
    DATE_TRUNC('month', pds.date) as month_start,
    
    -- Core metrics
    SUM(pds.messages_sent) as messages_sent,
    SUM(pds.reactions_given) as reactions_given,
    SUM(pds.reactions_received) as reactions_received,
    SUM(pds.active_minutes) as active_minutes,
    
    -- Growth metrics (compared to previous month)
    SUM(pds.messages_sent) - LAG(SUM(pds.messages_sent)) OVER (
        PARTITION BY pds.user_id ORDER BY DATE_TRUNC('month', pds.date)
    ) as messages_growth,
    
    SUM(pds.active_minutes) - LAG(SUM(pds.active_minutes)) OVER (
        PARTITION BY pds.user_id ORDER BY DATE_TRUNC('month', pds.date)
    ) as activity_growth,
    
    -- Engagement metrics
    CASE 
        WHEN SUM(pds.messages_sent) > 0 
        THEN ROUND((SUM(pds.reactions_received)::DECIMAL / SUM(pds.messages_sent)) * 100, 2)
        ELSE 0
    END as engagement_rate,
    
    -- Activity consistency (days active / total days)
    ROUND(
        (COUNT(*) FILTER (WHERE pds.messages_sent > 0 OR pds.active_minutes > 0)::DECIMAL / 
         COUNT(*)) * 100, 2
    ) as consistency_percentage,
    
    COUNT(*) as total_days,
    COUNT(*) FILTER (WHERE pds.messages_sent > 0 OR pds.active_minutes > 0) as active_days
    
FROM profile_daily_stats pds
WHERE pds.date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY pds.user_id, DATE_TRUNC('month', pds.date)
ORDER BY pds.user_id, month_start DESC;

-- =====================================================
-- SOCIAL NETWORK VIEWS
-- =====================================================

-- User connections view with relationship details
CREATE OR REPLACE VIEW user_social_network AS
SELECT 
    uc.user_id,
    uc.connected_user_id,
    uc.connection_type,
    uc.status,
    uc.connection_strength,
    uc.mutual_friends_count,
    uc.interaction_score,
    uc.is_favorite,
    uc.created_at as connection_created_at,
    
    -- Connected user info
    up.username as connected_username,
    up.display_name as connected_display_name,
    up.avatar_url as connected_avatar_url,
    up.avatar_decoration as connected_avatar_decoration,
    up.is_verified as connected_is_verified,
    up.last_active_at as connected_last_active,
    
    -- Activity status of connected user
    CASE 
        WHEN up.last_active_at > NOW() - INTERVAL '5 minutes' THEN 'online'
        WHEN up.last_active_at > NOW() - INTERVAL '1 hour' THEN 'recently_active'
        WHEN up.last_active_at > NOW() - INTERVAL '1 day' THEN 'today'
        WHEN up.last_active_at > NOW() - INTERVAL '7 days' THEN 'this_week'
        ELSE 'inactive'
    END as connected_activity_status,
    
    -- Relationship metrics
    EXTRACT(DAYS FROM NOW() - uc.created_at) as friendship_days,
    
    -- Mutual connections count
    (
        SELECT COUNT(*)
        FROM user_connections uc2
        WHERE uc2.user_id = uc.user_id
          AND uc2.status = 'accepted'
          AND uc2.connected_user_id IN (
              SELECT connected_user_id 
              FROM user_connections uc3
              WHERE uc3.user_id = uc.connected_user_id
                AND uc3.status = 'accepted'
          )
    ) as actual_mutual_friends
    
FROM user_connections uc
JOIN user_profiles up ON uc.connected_user_id = up.user_id
WHERE uc.status = 'accepted';

-- Friend suggestions view
CREATE OR REPLACE VIEW friend_suggestions AS
SELECT DISTINCT
    base_user.user_id,
    suggested_user.user_id as suggested_user_id,
    suggested_user.username as suggested_username,
    suggested_user.display_name as suggested_display_name,
    suggested_user.avatar_url as suggested_avatar_url,
    suggested_user.avatar_decoration as suggested_avatar_decoration,
    suggested_user.is_verified as suggested_is_verified,
    
    -- Suggestion score based on mutual connections
    COUNT(mutual.connected_user_id) as mutual_friends_count,
    
    -- Suggestion strength (higher = better suggestion)
    COUNT(mutual.connected_user_id) * 10 + 
    CASE 
        WHEN array_length(
            array(select unnest(base_user.interests) intersect select unnest(suggested_user.interests)), 1
        ) > 0 
        THEN array_length(
            array(select unnest(base_user.interests) intersect select unnest(suggested_user.interests)), 1
        ) * 5 
        ELSE 0 
    END as suggestion_score,
    
    -- Common interests
    array(
        select unnest(base_user.interests) 
        intersect 
        select unnest(suggested_user.interests)
    ) as common_interests
    
FROM user_profiles base_user
CROSS JOIN user_profiles suggested_user
JOIN user_connections base_connections ON base_user.user_id = base_connections.user_id
JOIN user_connections mutual ON base_connections.connected_user_id = mutual.user_id
JOIN user_connections suggested_connections ON mutual.connected_user_id = suggested_connections.user_id
WHERE base_user.user_id != suggested_user.user_id
  AND suggested_user.user_id = suggested_connections.connected_user_id
  AND base_connections.status = 'accepted'
  AND suggested_connections.status = 'accepted'
  AND NOT EXISTS (
      SELECT 1 FROM user_connections existing
      WHERE existing.user_id = base_user.user_id
        AND existing.connected_user_id = suggested_user.user_id
  )
  AND suggested_user.is_private = false
GROUP BY 
    base_user.user_id, suggested_user.user_id, suggested_user.username,
    suggested_user.display_name, suggested_user.avatar_url, suggested_user.avatar_decoration,
    suggested_user.is_verified, base_user.interests, suggested_user.interests
HAVING COUNT(mutual.connected_user_id) >= 2 -- At least 2 mutual friends
ORDER BY suggestion_score DESC;

-- =====================================================
-- ACHIEVEMENT PROGRESS VIEWS
-- =====================================================

-- User achievement progress dashboard
CREATE OR REPLACE VIEW achievement_progress_dashboard AS
SELECT 
    upa.user_id,
    pa.category,
    
    -- Category statistics
    COUNT(*) as total_achievements_in_category,
    COUNT(*) FILTER (WHERE upa.is_completed = true) as completed_achievements,
    COUNT(*) FILTER (WHERE upa.is_completed = false) as in_progress_achievements,
    
    -- Progress metrics
    ROUND(
        (COUNT(*) FILTER (WHERE upa.is_completed = true)::DECIMAL / COUNT(*)) * 100, 2
    ) as category_completion_percentage,
    
    COALESCE(SUM(pa.experience_reward) FILTER (WHERE upa.is_completed = true), 0) as experience_earned,
    COALESCE(SUM(pa.reputation_reward) FILTER (WHERE upa.is_completed = true), 0) as reputation_earned,
    
    -- Recent progress
    COUNT(*) FILTER (
        WHERE upa.is_completed = true 
          AND upa.completed_at > NOW() - INTERVAL '7 days'
    ) as completed_this_week,
    
    COUNT(*) FILTER (
        WHERE upa.last_progress_at > NOW() - INTERVAL '7 days'
          AND upa.is_completed = false
    ) as progressed_this_week,
    
    -- Next achievable
    (
        SELECT json_agg(
            json_build_object(
                'achievement_id', pa2.achievement_id,
                'name', pa2.name,
                'description', pa2.description,
                'progress_percentage', upa2.completion_percentage,
                'current_progress', upa2.current_progress,
                'target_progress', upa2.target_progress
            ) ORDER BY upa2.completion_percentage DESC
        )
        FROM user_profile_achievements upa2
        JOIN profile_achievements pa2 ON upa2.achievement_id = pa2.achievement_id
        WHERE upa2.user_id = upa.user_id
          AND pa2.category = pa.category
          AND upa2.is_completed = false
          AND upa2.completion_percentage > 0
        LIMIT 3
    ) as next_achievements
    
FROM user_profile_achievements upa
JOIN profile_achievements pa ON upa.achievement_id = pa.achievement_id
GROUP BY upa.user_id, pa.category;

-- Recent achievements view
CREATE OR REPLACE VIEW recent_achievements AS
SELECT 
    upa.user_id,
    up.username,
    up.display_name,
    up.avatar_url,
    up.avatar_decoration,
    pa.achievement_id,
    pa.name as achievement_name,
    pa.description as achievement_description,
    pa.category,
    pa.badge_color,
    pa.badge_icon,
    upa.completed_at,
    pa.experience_reward,
    pa.reputation_reward,
    
    -- Time since completion
    EXTRACT(HOURS FROM NOW() - upa.completed_at) as hours_since_completion,
    
    -- Achievement rarity (based on how many users have it)
    (
        SELECT COUNT(*) 
        FROM user_profile_achievements upa2 
        WHERE upa2.achievement_id = pa.achievement_id 
          AND upa2.is_completed = true
    ) as total_users_with_achievement,
    
    -- Rarity percentage
    ROUND(
        ((SELECT COUNT(*) FROM user_profile_achievements upa2 
          WHERE upa2.achievement_id = pa.achievement_id AND upa2.is_completed = true)::DECIMAL /
         (SELECT COUNT(DISTINCT user_id) FROM user_profile_achievements)::DECIMAL) * 100, 2
    ) as rarity_percentage
    
FROM user_profile_achievements upa
JOIN profile_achievements pa ON upa.achievement_id = pa.achievement_id
JOIN user_profiles up ON upa.user_id = up.user_id
WHERE upa.is_completed = true
  AND upa.completed_at > NOW() - INTERVAL '7 days'
ORDER BY upa.completed_at DESC;

-- =====================================================
-- PROFILE ANALYTICS VIEWS
-- =====================================================

-- Profile engagement analytics
CREATE OR REPLACE VIEW profile_engagement_analytics AS
SELECT 
    up.user_id,
    up.username,
    up.display_name,
    
    -- Profile metrics
    up.profile_completion_percentage,
    up.reputation_score,
    up.last_active_at,
    
    -- View analytics (last 30 days)
    COALESCE(SUM(pds.profile_views), 0) as total_profile_views_30d,
    COALESCE(SUM(pds.profile_views_unique), 0) as unique_profile_views_30d,
    COALESCE(ROUND(AVG(pds.profile_views), 2), 0) as avg_daily_profile_views,
    
    -- Activity analytics
    COALESCE(SUM(pds.messages_sent), 0) as total_messages_30d,
    COALESCE(SUM(pds.reactions_given), 0) as total_reactions_given_30d,
    COALESCE(SUM(pds.reactions_received), 0) as total_reactions_received_30d,
    COALESCE(SUM(pds.active_minutes), 0) as total_active_minutes_30d,
    
    -- Social analytics
    COALESCE(SUM(pds.new_connections), 0) as new_connections_30d,
    uas.friends_count as total_friends,
    
    -- Engagement rates
    CASE 
        WHEN COALESCE(SUM(pds.messages_sent), 0) > 0 
        THEN ROUND((COALESCE(SUM(pds.reactions_received), 0)::DECIMAL / 
                   COALESCE(SUM(pds.messages_sent), 1)) * 100, 2)
        ELSE 0
    END as message_engagement_rate_30d,
    
    CASE 
        WHEN COALESCE(SUM(pds.profile_views), 0) > 0 
        THEN ROUND((COALESCE(SUM(pds.new_connections), 0)::DECIMAL / 
                   COALESCE(SUM(pds.profile_views), 1)) * 100, 2)
        ELSE 0
    END as profile_to_connection_rate_30d,
    
    -- Growth metrics
    COALESCE(SUM(pds.experience_gained), 0) as experience_gained_30d,
    COALESCE(SUM(pds.achievement_unlocks), 0) as achievements_unlocked_30d,
    
    -- Activity consistency
    COUNT(*) FILTER (WHERE pds.messages_sent > 0 OR pds.active_minutes > 0) as active_days_30d,
    ROUND(
        (COUNT(*) FILTER (WHERE pds.messages_sent > 0 OR pds.active_minutes > 0)::DECIMAL / 30) * 100, 2
    ) as activity_consistency_30d
    
FROM user_profiles up
LEFT JOIN user_activity_stats uas ON up.user_id = uas.user_id
LEFT JOIN profile_daily_stats pds ON up.user_id = pds.user_id 
    AND pds.date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY up.user_id, up.username, up.display_name, up.profile_completion_percentage,
         up.reputation_score, up.last_active_at, uas.friends_count;

-- Profile health score view
CREATE OR REPLACE VIEW profile_health_scores AS
SELECT 
    up.user_id,
    up.username,
    up.display_name,
    
    -- Individual health components (0-100 scale)
    up.profile_completion_percentage as profile_completeness_score,
    
    LEAST(100, (up.reputation_score / 10.0)) as reputation_health_score,
    
    CASE 
        WHEN up.last_active_at > NOW() - INTERVAL '1 day' THEN 100
        WHEN up.last_active_at > NOW() - INTERVAL '3 days' THEN 80
        WHEN up.last_active_at > NOW() - INTERVAL '7 days' THEN 60
        WHEN up.last_active_at > NOW() - INTERVAL '30 days' THEN 40
        ELSE 20
    END as activity_recency_score,
    
    LEAST(100, (uas.friends_count * 5)) as social_connection_score,
    
    LEAST(100, (uas.current_streak_days * 10)) as engagement_consistency_score,
    
    -- Recent activity score (based on last 7 days)
    LEAST(100, COALESCE(
        (SELECT SUM(messages_sent + (active_minutes / 10.0))
         FROM profile_daily_stats
         WHERE user_id = up.user_id 
           AND date >= CURRENT_DATE - INTERVAL '7 days'), 0
    )) as recent_activity_score,
    
    -- Overall health score (weighted average)
    ROUND(
        (up.profile_completion_percentage * 0.2 +
         LEAST(100, (up.reputation_score / 10.0)) * 0.15 +
         CASE 
            WHEN up.last_active_at > NOW() - INTERVAL '1 day' THEN 100
            WHEN up.last_active_at > NOW() - INTERVAL '3 days' THEN 80
            WHEN up.last_active_at > NOW() - INTERVAL '7 days' THEN 60
            WHEN up.last_active_at > NOW() - INTERVAL '30 days' THEN 40
            ELSE 20
         END * 0.25 +
         LEAST(100, (uas.friends_count * 5)) * 0.2 +
         LEAST(100, (uas.current_streak_days * 10)) * 0.1 +
         LEAST(100, COALESCE(
            (SELECT SUM(messages_sent + (active_minutes / 10.0))
             FROM profile_daily_stats
             WHERE user_id = up.user_id 
               AND date >= CURRENT_DATE - INTERVAL '7 days'), 0
         )) * 0.1), 2
    ) as overall_health_score,
    
    -- Health status
    CASE 
        WHEN ROUND(
            (up.profile_completion_percentage * 0.2 +
             LEAST(100, (up.reputation_score / 10.0)) * 0.15 +
             CASE 
                WHEN up.last_active_at > NOW() - INTERVAL '1 day' THEN 100
                WHEN up.last_active_at > NOW() - INTERVAL '3 days' THEN 80
                WHEN up.last_active_at > NOW() - INTERVAL '7 days' THEN 60
                WHEN up.last_active_at > NOW() - INTERVAL '30 days' THEN 40
                ELSE 20
             END * 0.25 +
             LEAST(100, (uas.friends_count * 5)) * 0.2 +
             LEAST(100, (uas.current_streak_days * 10)) * 0.1 +
             LEAST(100, COALESCE(
                (SELECT SUM(messages_sent + (active_minutes / 10.0))
                 FROM profile_daily_stats
                 WHERE user_id = up.user_id 
                   AND date >= CURRENT_DATE - INTERVAL '7 days'), 0
             )) * 0.1), 2
        ) >= 80 THEN 'excellent'
        WHEN ROUND(
            (up.profile_completion_percentage * 0.2 +
             LEAST(100, (up.reputation_score / 10.0)) * 0.15 +
             CASE 
                WHEN up.last_active_at > NOW() - INTERVAL '1 day' THEN 100
                WHEN up.last_active_at > NOW() - INTERVAL '3 days' THEN 80
                WHEN up.last_active_at > NOW() - INTERVAL '7 days' THEN 60
                WHEN up.last_active_at > NOW() - INTERVAL '30 days' THEN 40
                ELSE 20
             END * 0.25 +
             LEAST(100, (uas.friends_count * 5)) * 0.2 +
             LEAST(100, (uas.current_streak_days * 10)) * 0.1 +
             LEAST(100, COALESCE(
                (SELECT SUM(messages_sent + (active_minutes / 10.0))
                 FROM profile_daily_stats
                 WHERE user_id = up.user_id 
                   AND date >= CURRENT_DATE - INTERVAL '7 days'), 0
             )) * 0.1), 2
        ) >= 60 THEN 'good'
        WHEN ROUND(
            (up.profile_completion_percentage * 0.2 +
             LEAST(100, (up.reputation_score / 10.0)) * 0.15 +
             CASE 
                WHEN up.last_active_at > NOW() - INTERVAL '1 day' THEN 100
                WHEN up.last_active_at > NOW() - INTERVAL '3 days' THEN 80
                WHEN up.last_active_at > NOW() - INTERVAL '7 days' THEN 60
                WHEN up.last_active_at > NOW() - INTERVAL '30 days' THEN 40
                ELSE 20
             END * 0.25 +
             LEAST(100, (uas.friends_count * 5)) * 0.2 +
             LEAST(100, (uas.current_streak_days * 10)) * 0.1 +
             LEAST(100, COALESCE(
                (SELECT SUM(messages_sent + (active_minutes / 10.0))
                 FROM profile_daily_stats
                 WHERE user_id = up.user_id 
                   AND date >= CURRENT_DATE - INTERVAL '7 days'), 0
             )) * 0.1), 2
        ) >= 40 THEN 'fair'
        ELSE 'needs_improvement'
    END as health_status
    
FROM user_profiles up
LEFT JOIN user_activity_stats uas ON up.user_id = uas.user_id;

-- =====================================================
-- SYSTEM ANALYTICS VIEWS
-- =====================================================

-- Platform overview statistics
CREATE OR REPLACE VIEW platform_overview_stats AS
SELECT 
    -- User statistics
    COUNT(DISTINCT up.user_id) as total_users,
    COUNT(DISTINCT up.user_id) FILTER (WHERE up.created_at > NOW() - INTERVAL '30 days') as new_users_30d,
    COUNT(DISTINCT up.user_id) FILTER (WHERE up.last_active_at > NOW() - INTERVAL '1 day') as daily_active_users,
    COUNT(DISTINCT up.user_id) FILTER (WHERE up.last_active_at > NOW() - INTERVAL '7 days') as weekly_active_users,
    COUNT(DISTINCT up.user_id) FILTER (WHERE up.last_active_at > NOW() - INTERVAL '30 days') as monthly_active_users,
    
    -- Profile statistics
    ROUND(AVG(up.profile_completion_percentage), 2) as avg_profile_completion,
    COUNT(*) FILTER (WHERE up.profile_completion_percentage = 100) as fully_completed_profiles,
    COUNT(*) FILTER (WHERE up.is_verified = true) as verified_users,
    ROUND(AVG(up.reputation_score), 2) as avg_reputation_score,
    
    -- Activity statistics
    COALESCE(SUM(uas.total_messages_sent), 0) as total_messages_platform,
    COALESCE(SUM(uas.total_reactions_given), 0) as total_reactions_platform,
    COALESCE(SUM(uas.friends_count), 0) as total_connections_platform,
    ROUND(AVG(uas.user_level), 2) as avg_user_level,
    
    -- Today's activity
    COALESCE(SUM(pds.messages_sent), 0) as messages_today,
    COALESCE(SUM(pds.reactions_given), 0) as reactions_today,
    COALESCE(SUM(pds.new_connections), 0) as new_connections_today,
    COALESCE(SUM(pds.achievement_unlocks), 0) as achievements_unlocked_today,
    
    -- Engagement metrics
    ROUND(
        CASE 
            WHEN COUNT(DISTINCT up.user_id) > 0 
            THEN (COUNT(DISTINCT up.user_id) FILTER (WHERE up.last_active_at > NOW() - INTERVAL '1 day')::DECIMAL / 
                  COUNT(DISTINCT up.user_id)) * 100
            ELSE 0 
        END, 2
    ) as daily_engagement_rate,
    
    ROUND(
        CASE 
            WHEN COUNT(DISTINCT up.user_id) > 0 
            THEN (COUNT(DISTINCT up.user_id) FILTER (WHERE up.last_active_at > NOW() - INTERVAL '7 days')::DECIMAL / 
                  COUNT(DISTINCT up.user_id)) * 100
            ELSE 0 
        END, 2
    ) as weekly_engagement_rate
    
FROM user_profiles up
LEFT JOIN user_activity_stats uas ON up.user_id = uas.user_id
LEFT JOIN profile_daily_stats pds ON up.user_id = pds.user_id AND pds.date = CURRENT_DATE;

-- =====================================================
-- GRANT PERMISSIONS ON VIEWS
-- =====================================================

-- Grant select permissions to authenticated users for appropriate views
GRANT SELECT ON user_profiles_enriched TO authenticated;
GRANT SELECT ON user_leaderboards TO authenticated;
GRANT SELECT ON weekly_activity_summary TO authenticated;
GRANT SELECT ON monthly_activity_trends TO authenticated;
GRANT SELECT ON user_social_network TO authenticated;
GRANT SELECT ON friend_suggestions TO authenticated;
GRANT SELECT ON achievement_progress_dashboard TO authenticated;
GRANT SELECT ON recent_achievements TO authenticated;
GRANT SELECT ON profile_engagement_analytics TO authenticated;
GRANT SELECT ON profile_health_scores TO authenticated;

-- Platform overview stats should be restricted to admins
-- GRANT SELECT ON platform_overview_stats TO service_role;

-- =====================================================
-- VIEW INDEXES FOR PERFORMANCE
-- =====================================================

-- Create indexes on commonly queried fields in views
-- Note: These are on the underlying tables, but help view performance

-- Additional indexes for view performance
CREATE INDEX IF NOT EXISTS idx_profile_daily_stats_user_date ON profile_daily_stats(user_id, date DESC);

CREATE INDEX IF NOT EXISTS idx_user_connections_mutual_lookup ON user_connections(connected_user_id, status) 
    WHERE status = 'accepted';

CREATE INDEX IF NOT EXISTS idx_user_achievements_completion ON user_profile_achievements(user_id, is_completed, completed_at);

-- =====================================================
-- COMMENTS AND DOCUMENTATION
-- =====================================================

COMMENT ON VIEW user_profiles_enriched IS 'Comprehensive user profile data with statistics and related information for dashboard display';
COMMENT ON VIEW user_leaderboards IS 'User rankings across different metrics (experience, level, messages, etc.)';
COMMENT ON VIEW weekly_activity_summary IS 'Weekly aggregated activity statistics for trend analysis';
COMMENT ON VIEW monthly_activity_trends IS 'Monthly activity trends with growth metrics';
COMMENT ON VIEW user_social_network IS 'Social connections with relationship details and status';
COMMENT ON VIEW friend_suggestions IS 'Intelligent friend suggestions based on mutual connections and interests';
COMMENT ON VIEW achievement_progress_dashboard IS 'Achievement progress by category with completion statistics';
COMMENT ON VIEW recent_achievements IS 'Recently unlocked achievements with rarity information';
COMMENT ON VIEW profile_engagement_analytics IS 'Profile engagement metrics and analytics for the last 30 days';
COMMENT ON VIEW profile_health_scores IS 'Comprehensive profile health scoring based on multiple factors';
COMMENT ON VIEW platform_overview_stats IS 'Platform-wide statistics and metrics for administrative dashboards';

-- =====================================================
-- END OF PROFILE VIEWS
-- =====================================================
