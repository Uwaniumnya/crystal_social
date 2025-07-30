-- Crystal Social Tabs System - Views and Analytics
-- File: 03_tabs_views_analytics.sql
-- Purpose: Database views, materialized views, and analytics for comprehensive tabs functionality

-- =============================================================================
-- TAB MANAGEMENT VIEWS
-- =============================================================================

-- Active tabs with user preference summary
CREATE OR REPLACE VIEW active_tabs_summary AS
SELECT 
    td.id,
    td.tab_name,
    td.display_name,
    td.description,
    td.icon_path,
    td.tab_order,
    td.is_production_ready,
    td.requires_authentication,
    COUNT(DISTINCT utp.user_id) as users_count,
    COUNT(DISTINCT CASE WHEN utp.is_favorite THEN utp.user_id END) as favorites_count,
    COUNT(DISTINCT CASE WHEN utp.is_hidden THEN utp.user_id END) as hidden_count,
    AVG(COALESCE(utp.access_count, 0))::DECIMAL(10,2) as avg_access_count,
    AVG(COALESCE(utp.total_time_spent_minutes, 0))::DECIMAL(10,2) as avg_time_spent_minutes,
    td.created_at,
    td.updated_at
FROM tab_definitions td
LEFT JOIN user_tab_preferences utp ON td.tab_name = utp.tab_name
WHERE td.is_enabled = true
GROUP BY td.id, td.tab_name, td.display_name, td.description, td.icon_path, 
         td.tab_order, td.is_production_ready, td.requires_authentication, 
         td.created_at, td.updated_at
ORDER BY td.tab_order, td.display_name;

-- User tab dashboard view with personalized metrics
CREATE OR REPLACE VIEW user_tab_dashboard AS
SELECT 
    u.id as user_id,
    u.email,
    td.tab_name,
    td.display_name,
    td.icon_path,
    utp.is_favorite,
    utp.is_hidden,
    utp.custom_order,
    utp.notifications_enabled,
    utp.access_count,
    utp.total_time_spent_minutes,
    utp.session_count,
    utp.last_accessed_at,
    utp.last_session_duration_minutes,
    CASE 
        WHEN utp.last_accessed_at >= NOW() - INTERVAL '1 day' THEN 'today'
        WHEN utp.last_accessed_at >= NOW() - INTERVAL '7 days' THEN 'this_week'
        WHEN utp.last_accessed_at >= NOW() - INTERVAL '30 days' THEN 'this_month'
        ELSE 'older'
    END as last_activity_period,
    COALESCE(td.tab_order, 999) as default_order
FROM auth.users u
CROSS JOIN tab_definitions td
LEFT JOIN user_tab_preferences utp ON u.id = utp.user_id AND td.tab_name = utp.tab_name
WHERE td.is_enabled = true AND td.is_production_ready = true
ORDER BY u.email, COALESCE(utp.custom_order, td.tab_order), td.display_name;

-- Tab performance analytics view
CREATE OR REPLACE VIEW tab_performance_analytics AS
SELECT 
    td.tab_name,
    td.display_name,
    COUNT(DISTINCT tua.user_id) as unique_users,
    COUNT(DISTINCT tua.id) as total_sessions,
    SUM(COALESCE(tua.session_duration_seconds, 0)) / 60 as total_minutes,
    AVG(COALESCE(tua.session_duration_seconds, 0)) / 60 as avg_session_minutes,
    AVG(COALESCE(tua.load_time_ms, 0)) as avg_load_time_ms,
    SUM(COALESCE(tua.interactions_count, 0)) as total_interactions,
    AVG(COALESCE(tua.interactions_count, 0))::DECIMAL(10,2) as avg_interactions_per_session,
    COUNT(DISTINCT DATE(tua.session_start)) as active_days,
    MIN(tua.session_start) as first_usage,
    MAX(tua.session_start) as last_usage
FROM tab_definitions td
LEFT JOIN tab_usage_analytics tua ON td.tab_name = tua.tab_name
WHERE td.is_enabled = true
GROUP BY td.tab_name, td.display_name
ORDER BY total_minutes DESC, unique_users DESC;

-- =============================================================================
-- HOME SCREEN VIEWS
-- =============================================================================

-- Home screen apps with user customization
CREATE OR REPLACE VIEW home_screen_dashboard AS
SELECT 
    hsa.id,
    hsa.app_name,
    hsa.display_title,
    hsa.subtitle,
    hsa.icon_path,
    hsa.color_scheme,
    hsa.grid_position,
    hsa.target_tab,
    hsa.is_enabled,
    hsa.total_launches,
    hsa.last_launched_at,
    COUNT(DISTINCT uhsl.user_id) as users_with_customization,
    COUNT(DISTINCT CASE WHEN uhsl.is_pinned THEN uhsl.user_id END) as pinned_by_users,
    COUNT(DISTINCT CASE WHEN uhsl.is_hidden THEN uhsl.user_id END) as hidden_by_users,
    AVG(CASE WHEN uhsl.custom_position IS NOT NULL THEN uhsl.custom_position::DECIMAL END) as avg_custom_position
FROM home_screen_apps hsa
LEFT JOIN user_home_screen_layout uhsl ON hsa.id = uhsl.app_id
GROUP BY hsa.id, hsa.app_name, hsa.display_title, hsa.subtitle, hsa.icon_path,
         hsa.color_scheme, hsa.grid_position, hsa.target_tab, hsa.is_enabled,
         hsa.total_launches, hsa.last_launched_at
ORDER BY hsa.grid_position, hsa.display_title;

-- User home screen layout with app details
CREATE OR REPLACE VIEW user_home_layout AS
SELECT 
    u.id as user_id,
    u.email,
    hsa.app_name,
    hsa.display_title,
    hsa.subtitle,
    hsa.icon_path,
    hsa.color_scheme,
    hsa.target_tab,
    COALESCE(uhsl.custom_position, hsa.grid_position) as display_position,
    COALESCE(uhsl.is_hidden, false) as is_hidden,
    COALESCE(uhsl.is_pinned, false) as is_pinned,
    COALESCE(uhsl.custom_size, 'normal') as display_size,
    uhsl.created_at as customized_at,
    uhsl.updated_at as last_modified_at
FROM auth.users u
CROSS JOIN home_screen_apps hsa
LEFT JOIN user_home_screen_layout uhsl ON u.id = uhsl.user_id AND hsa.id = uhsl.app_id
WHERE hsa.is_enabled = true
ORDER BY u.email, display_position, hsa.display_title;

-- =============================================================================
-- GLITTER BOARD SOCIAL VIEWS
-- =============================================================================

-- Social content overview with engagement metrics
CREATE OR REPLACE VIEW glitter_board_overview AS
SELECT 
    gp.id,
    gp.user_id,
    CASE 
        WHEN gp.user_id IS NOT NULL THEN u.email 
        ELSE 'Anonymous User'
    END as author_email,
    gp.text_content,
    gp.mood,
    gp.image_url,
    gp.tags,
    gp.location,
    gp.visibility,
    gp.is_deleted,
    COUNT(DISTINCT gc.id) as comments_count,
    COUNT(DISTINCT gr.id) as reactions_count,
    COUNT(DISTINCT CASE WHEN gr.reaction_type = 'like' THEN gr.id END) as likes_count,
    COUNT(DISTINCT CASE WHEN gr.reaction_type = 'love' THEN gr.id END) as loves_count,
    COUNT(DISTINCT CASE WHEN gr.reaction_type = 'laugh' THEN gr.id END) as laughs_count,
    gp.views_count,
    gp.created_at,
    gp.updated_at,
    EXTRACT(EPOCH FROM (NOW() - gp.created_at)) / 3600 as hours_since_posted
FROM glitter_posts gp
LEFT JOIN auth.users u ON gp.user_id = u.id
LEFT JOIN glitter_comments gc ON gp.id = gc.post_id AND gc.is_deleted = false
LEFT JOIN glitter_reactions gr ON gp.id = gr.target_id AND gr.target_type = 'post'
WHERE gp.is_deleted = false
GROUP BY gp.id, gp.user_id, u.email, gp.text_content, gp.mood, gp.image_url,
         gp.tags, gp.location, gp.visibility, gp.is_deleted, gp.views_count,
         gp.created_at, gp.updated_at
ORDER BY gp.created_at DESC;

-- User social activity summary
CREATE OR REPLACE VIEW user_social_activity AS
SELECT 
    u.id as user_id,
    u.email,
    COUNT(DISTINCT gp.id) as posts_created,
    COUNT(DISTINCT gc.id) as comments_made,
    COUNT(DISTINCT gr.id) as reactions_given,
    COUNT(DISTINCT pr.id) as posts_reactions_received,
    COUNT(DISTINCT cr.id) as comments_reactions_received,
    SUM(COALESCE(gp.views_count, 0)) as total_post_views,
    MAX(gp.created_at) as last_post_date,
    MAX(gc.created_at) as last_comment_date,
    MAX(gr.created_at) as last_reaction_date
FROM auth.users u
LEFT JOIN glitter_posts gp ON u.id = gp.user_id AND gp.is_deleted = false
LEFT JOIN glitter_comments gc ON u.id = gc.user_id AND gc.is_deleted = false
LEFT JOIN glitter_reactions gr ON u.id = gr.user_id
LEFT JOIN glitter_reactions pr ON gp.id = pr.target_id AND pr.target_type = 'post'
LEFT JOIN glitter_reactions cr ON gc.id = cr.target_id AND cr.target_type = 'comment'
GROUP BY u.id, u.email
ORDER BY posts_created DESC, comments_made DESC;

-- Trending posts view (last 24 hours)
CREATE OR REPLACE VIEW trending_glitter_posts AS
SELECT 
    gp.id,
    gp.text_content,
    gp.mood,
    gp.tags,
    gp.created_at,
    COUNT(DISTINCT gr.id) as recent_reactions,
    COUNT(DISTINCT gc.id) as recent_comments,
    gp.views_count,
    -- Engagement score calculation
    (COUNT(DISTINCT gr.id) * 3 + COUNT(DISTINCT gc.id) * 5 + gp.views_count * 0.1) as engagement_score,
    -- Trending score (time-weighted)
    (COUNT(DISTINCT gr.id) * 3 + COUNT(DISTINCT gc.id) * 5 + gp.views_count * 0.1) / 
    GREATEST(EXTRACT(EPOCH FROM (NOW() - gp.created_at)) / 3600, 1) as trending_score
FROM glitter_posts gp
LEFT JOIN glitter_reactions gr ON gp.id = gr.target_id 
    AND gr.target_type = 'post' 
    AND gr.created_at >= NOW() - INTERVAL '24 hours'
LEFT JOIN glitter_comments gc ON gp.id = gc.post_id 
    AND gc.is_deleted = false 
    AND gc.created_at >= NOW() - INTERVAL '24 hours'
WHERE gp.is_deleted = false 
AND gp.visibility = 'public'
AND gp.created_at >= NOW() - INTERVAL '7 days'
GROUP BY gp.id, gp.text_content, gp.mood, gp.tags, gp.created_at, gp.views_count
HAVING (COUNT(DISTINCT gr.id) * 3 + COUNT(DISTINCT gc.id) * 5 + gp.views_count * 0.1) > 0
ORDER BY trending_score DESC, engagement_score DESC
LIMIT 50;

-- =============================================================================
-- ENTERTAINMENT VIEWS
-- =============================================================================

-- Horoscope user engagement overview
CREATE OR REPLACE VIEW horoscope_engagement_overview AS
SELECT 
    zs.sign_name,
    zs.element,
    zs.quality,
    COUNT(DISTINCT uhp.user_id) as total_users,
    COUNT(DISTINCT CASE WHEN uhp.daily_notifications THEN uhp.user_id END) as notification_users,
    AVG(COALESCE(uhp.total_readings_viewed, 0))::DECIMAL(10,2) as avg_readings_per_user,
    AVG(COALESCE(uhp.streak_days, 0))::DECIMAL(10,2) as avg_streak_days,
    AVG(COALESCE(uhp.coins_earned, 0))::DECIMAL(10,2) as avg_coins_earned,
    SUM(COALESCE(uhp.coins_earned, 0)) as total_coins_distributed,
    MAX(uhp.streak_days) as max_streak,
    MAX(uhp.total_readings_viewed) as max_readings
FROM zodiac_signs zs
LEFT JOIN user_horoscope_preferences uhp ON zs.id = uhp.zodiac_sign_id
GROUP BY zs.id, zs.sign_name, zs.element, zs.quality
ORDER BY total_users DESC, avg_readings_per_user DESC;

-- Daily horoscope reading analytics
CREATE OR REPLACE VIEW daily_horoscope_analytics AS
SELECT 
    hr.reading_date,
    zs.sign_name,
    hr.overall_energy,
    COUNT(DISTINCT uhp.user_id) as potential_users,
    -- We'd need to track actual readings to get accurate view counts
    0 as actual_readers, -- Placeholder - would need reading tracking table
    ARRAY_LENGTH(hr.lucky_numbers, 1) as lucky_numbers_count,
    ARRAY_LENGTH(hr.lucky_colors, 1) as lucky_colors_count,
    hr.created_at,
    hr.updated_at
FROM horoscope_readings hr
JOIN zodiac_signs zs ON hr.zodiac_sign_id = zs.id
LEFT JOIN user_horoscope_preferences uhp ON zs.id = uhp.zodiac_sign_id
WHERE hr.reading_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY hr.id, hr.reading_date, zs.sign_name, hr.overall_energy, hr.lucky_numbers,
         hr.lucky_colors, hr.created_at, hr.updated_at
ORDER BY hr.reading_date DESC, zs.sign_name;

-- Tarot reading statistics
CREATE OR REPLACE VIEW tarot_reading_analytics AS
SELECT 
    td.deck_name,
    tr.reading_type,
    COUNT(*) as total_readings,
    COUNT(DISTINCT tr.user_id) as unique_users,
    COUNT(DISTINCT DATE(tr.created_at)) as active_days,
    AVG(CHAR_LENGTH(tr.interpretation)) as avg_interpretation_length,
    COUNT(DISTINCT tr.overall_theme) as unique_themes,
    MIN(tr.created_at) as first_reading,
    MAX(tr.created_at) as latest_reading
FROM tarot_readings tr
JOIN tarot_decks td ON tr.deck_id = td.id
GROUP BY td.deck_name, tr.reading_type
ORDER BY total_readings DESC, unique_users DESC;

-- Oracle consultation insights
CREATE OR REPLACE VIEW oracle_consultation_insights AS
SELECT 
    om.message_type,
    om.element,
    COUNT(DISTINCT oc.id) as total_consultations,
    COUNT(DISTINCT oc.user_id) as unique_users,
    AVG(COALESCE(oc.user_rating, 0))::DECIMAL(3,2) as avg_rating,
    COUNT(CASE WHEN oc.was_helpful = true THEN 1 END) as helpful_count,
    COUNT(CASE WHEN oc.was_helpful = false THEN 1 END) as not_helpful_count,
    COUNT(CASE WHEN oc.user_feedback IS NOT NULL THEN 1 END) as feedback_count,
    AVG(COALESCE(om.energy_level, 0))::DECIMAL(3,2) as avg_energy_level,
    om.times_delivered,
    om.last_delivered_at
FROM oracle_messages om
LEFT JOIN oracle_consultations oc ON om.id = oc.oracle_message_id
GROUP BY om.id, om.message_type, om.element, om.times_delivered, om.last_delivered_at
ORDER BY total_consultations DESC, avg_rating DESC;

-- Magic 8-Ball response analytics
CREATE OR REPLACE VIEW magic_8ball_analytics AS
SELECT 
    mr.response_type,
    mr.response_category,
    COUNT(DISTINCT mc.id) as total_consultations,
    COUNT(DISTINCT mc.user_id) as unique_users,
    mr.times_shown,
    AVG(CHAR_LENGTH(COALESCE(mc.user_question, ''))) as avg_question_length,
    COUNT(DISTINCT mc.question_category) as unique_question_categories,
    COUNT(DISTINCT mc.user_mood) as unique_user_moods,
    MIN(mc.created_at) as first_consultation,
    MAX(mc.created_at) as latest_consultation
FROM magic_8ball_responses mr
LEFT JOIN magic_8ball_consultations mc ON mr.id = mc.response_id
GROUP BY mr.id, mr.response_type, mr.response_category, mr.times_shown
ORDER BY total_consultations DESC, unique_users DESC;

-- =============================================================================
-- POLLING AND COMMUNITY VIEWS
-- =============================================================================

-- Active polls with engagement metrics
CREATE OR REPLACE VIEW active_polls_overview AS
SELECT 
    p.id,
    p.poll_title,
    p.poll_description,
    p.poll_category,
    p.is_multiple_choice,
    p.is_anonymous_voting,
    p.ends_at,
    p.is_active,
    u.email as creator_email,
    COUNT(DISTINCT po.id) as total_options,
    COUNT(DISTINCT pv.id) as total_votes,
    COUNT(DISTINCT pv.user_id) as unique_voters,
    COUNT(DISTINCT CASE WHEN pv.is_anonymous = false THEN pv.user_id END) as public_voters,
    p.created_at,
    p.updated_at,
    CASE 
        WHEN p.ends_at IS NULL THEN 'permanent'
        WHEN p.ends_at > NOW() THEN 'active'
        ELSE 'expired'
    END as poll_status
FROM polls p
LEFT JOIN auth.users u ON p.creator_id = u.id
LEFT JOIN poll_options po ON p.id = po.poll_id
LEFT JOIN poll_votes pv ON p.id = pv.poll_id
WHERE p.is_active = true
GROUP BY p.id, p.poll_title, p.poll_description, p.poll_category, p.is_multiple_choice,
         p.is_anonymous_voting, p.ends_at, p.is_active, u.email, p.created_at, p.updated_at
ORDER BY total_votes DESC, p.created_at DESC;

-- Poll results with detailed breakdown
CREATE OR REPLACE VIEW poll_results_detailed AS
SELECT 
    p.id as poll_id,
    p.poll_title,
    po.option_text,
    po.option_order,
    COUNT(pv.id) as vote_count,
    COUNT(DISTINCT pv.user_id) as unique_voters,
    ROUND(
        100.0 * COUNT(pv.id) / NULLIF(
            (SELECT COUNT(*) FROM poll_votes WHERE poll_id = p.id), 0
        ), 2
    ) as vote_percentage,
    COUNT(CASE WHEN pv.is_anonymous = false THEN 1 END) as public_votes,
    COUNT(CASE WHEN pv.is_anonymous = true THEN 1 END) as anonymous_votes
FROM polls p
JOIN poll_options po ON p.id = po.poll_id
LEFT JOIN poll_votes pv ON po.id = pv.option_id
GROUP BY p.id, p.poll_title, po.id, po.option_text, po.option_order
ORDER BY p.id, po.option_order;

-- User voting activity summary
CREATE OR REPLACE VIEW user_voting_activity AS
SELECT 
    u.id as user_id,
    u.email,
    COUNT(DISTINCT pv.poll_id) as polls_participated,
    COUNT(DISTINCT pv.id) as total_votes_cast,
    COUNT(DISTINCT CASE WHEN pv.is_anonymous = false THEN pv.id END) as public_votes,
    COUNT(DISTINCT CASE WHEN pv.is_anonymous = true THEN pv.id END) as anonymous_votes,
    COUNT(DISTINCT p.id) as polls_created,
    MAX(pv.created_at) as last_vote_date,
    MAX(p.created_at) as last_poll_created_date
FROM auth.users u
LEFT JOIN poll_votes pv ON u.id = pv.user_id
LEFT JOIN polls p ON u.id = p.creator_id
GROUP BY u.id, u.email
ORDER BY polls_participated DESC, total_votes_cast DESC;

-- =============================================================================
-- CONFESSION SYSTEM VIEWS
-- =============================================================================

-- Confession analytics overview
CREATE OR REPLACE VIEW confession_analytics AS
SELECT 
    c.confession_category,
    c.mood_emoji,
    COUNT(*) as total_confessions,
    COUNT(DISTINCT c.user_id) as unique_confessors,
    COUNT(CASE WHEN c.is_anonymous = true THEN 1 END) as anonymous_confessions,
    COUNT(CASE WHEN c.is_anonymous = false THEN 1 END) as public_confessions,
    AVG(CHAR_LENGTH(c.confession_text)) as avg_confession_length,
    MIN(c.created_at) as first_confession_date,
    MAX(c.created_at) as latest_confession_date
FROM confessions c
WHERE c.is_approved = true
GROUP BY c.confession_category, c.mood_emoji
ORDER BY total_confessions DESC;

-- Recent confessions for moderation (anonymized)
CREATE OR REPLACE VIEW confessions_moderation AS
SELECT 
    c.id,
    c.confession_category,
    c.mood_emoji,
    LEFT(c.confession_text, 100) || '...' as confession_preview,
    CHAR_LENGTH(c.confession_text) as content_length,
    c.is_anonymous,
    c.is_approved,
    c.created_at,
    EXTRACT(EPOCH FROM (NOW() - c.created_at)) / 3600 as hours_since_posted
FROM confessions c
WHERE c.created_at >= NOW() - INTERVAL '7 days'
ORDER BY c.created_at DESC;

-- =============================================================================
-- COMPREHENSIVE ANALYTICS VIEWS
-- =============================================================================

-- Daily tabs system overview
CREATE OR REPLACE VIEW daily_system_overview AS
SELECT 
    CURRENT_DATE as report_date,
    COUNT(DISTINCT tua.user_id) as active_users,
    COUNT(DISTINCT tua.tab_name) as tabs_used,
    SUM(COALESCE(tua.session_duration_seconds, 0)) / 60 as total_minutes,
    COUNT(DISTINCT tua.id) as total_sessions,
    SUM(COALESCE(tua.interactions_count, 0)) as total_interactions,
    AVG(COALESCE(tua.load_time_ms, 0)) as avg_load_time_ms,
    COUNT(DISTINCT gp.id) as new_posts,
    COUNT(DISTINCT gc.id) as new_comments,
    COUNT(DISTINCT gr.id) as new_reactions,
    COUNT(DISTINCT tr.id) as tarot_readings,
    COUNT(DISTINCT oc.id) as oracle_consultations,
    COUNT(DISTINCT mc.id) as magic_8ball_uses,
    COUNT(DISTINCT pv.id) as poll_votes,
    COUNT(DISTINCT cf.id) as new_confessions
FROM tab_usage_analytics tua
LEFT JOIN glitter_posts gp ON DATE(gp.created_at) = CURRENT_DATE
LEFT JOIN glitter_comments gc ON DATE(gc.created_at) = CURRENT_DATE
LEFT JOIN glitter_reactions gr ON DATE(gr.created_at) = CURRENT_DATE
LEFT JOIN tarot_readings tr ON DATE(tr.created_at) = CURRENT_DATE
LEFT JOIN oracle_consultations oc ON DATE(oc.created_at) = CURRENT_DATE
LEFT JOIN magic_8ball_consultations mc ON DATE(mc.created_at) = CURRENT_DATE
LEFT JOIN poll_votes pv ON DATE(pv.created_at) = CURRENT_DATE
LEFT JOIN confessions cf ON DATE(cf.created_at) = CURRENT_DATE
WHERE DATE(tua.session_start) = CURRENT_DATE;

-- User engagement summary with all features
CREATE OR REPLACE VIEW user_engagement_summary AS
SELECT 
    u.id as user_id,
    u.email,
    -- Tab usage metrics
    COUNT(DISTINCT tua.tab_name) as tabs_used,
    SUM(COALESCE(tua.session_duration_seconds, 0)) / 60 as total_minutes,
    COUNT(DISTINCT tua.id) as total_sessions,
    -- Social activity metrics
    COUNT(DISTINCT gp.id) as posts_created,
    COUNT(DISTINCT gc.id) as comments_made,
    COUNT(DISTINCT gr.id) as reactions_given,
    -- Entertainment metrics
    COUNT(DISTINCT tr.id) as tarot_readings,
    COUNT(DISTINCT oc.id) as oracle_consultations,
    COUNT(DISTINCT mc.id) as magic_8ball_uses,
    -- Community metrics
    COUNT(DISTINCT pv.id) as poll_votes_cast,
    COUNT(DISTINCT p.id) as polls_created,
    COUNT(DISTINCT cf.id) as confessions_shared,
    -- Engagement scoring (0-100)
    LEAST(100, GREATEST(0,
        COALESCE(SUM(tua.session_duration_seconds) / 3600, 0) * 10 + -- Time factor
        COALESCE(COUNT(DISTINCT gp.id), 0) * 5 + -- Content creation
        COALESCE(COUNT(DISTINCT gc.id), 0) * 2 + -- Social interaction
        COALESCE(COUNT(DISTINCT gr.id), 0) * 1 + -- Reactions
        (COALESCE(COUNT(DISTINCT tr.id), 0) + COALESCE(COUNT(DISTINCT oc.id), 0) + COALESCE(COUNT(DISTINCT mc.id), 0)) * 3 -- Entertainment engagement
    ))::INTEGER as engagement_score,
    -- Activity timestamps
    MAX(tua.session_start) as last_activity,
    MIN(tua.session_start) as first_activity
FROM auth.users u
LEFT JOIN tab_usage_analytics tua ON u.id = tua.user_id
LEFT JOIN glitter_posts gp ON u.id = gp.user_id AND gp.is_deleted = false
LEFT JOIN glitter_comments gc ON u.id = gc.user_id AND gc.is_deleted = false
LEFT JOIN glitter_reactions gr ON u.id = gr.user_id
LEFT JOIN tarot_readings tr ON u.id = tr.user_id
LEFT JOIN oracle_consultations oc ON u.id = oc.user_id
LEFT JOIN magic_8ball_consultations mc ON u.id = mc.user_id
LEFT JOIN poll_votes pv ON u.id = pv.user_id
LEFT JOIN polls p ON u.id = p.creator_id
LEFT JOIN confessions cf ON u.id = cf.user_id
GROUP BY u.id, u.email
ORDER BY engagement_score DESC, total_minutes DESC;

-- =============================================================================
-- MATERIALIZED VIEWS FOR PERFORMANCE
-- =============================================================================

-- Daily stats materialized view (refresh daily)
CREATE MATERIALIZED VIEW daily_tabs_stats AS
SELECT 
    DATE(tua.session_start) as stats_date,
    tua.tab_name,
    COUNT(DISTINCT tua.user_id) as unique_users,
    COUNT(*) as total_sessions,
    SUM(COALESCE(tua.session_duration_seconds, 0)) as total_seconds,
    AVG(COALESCE(tua.session_duration_seconds, 0)) as avg_session_seconds,
    SUM(COALESCE(tua.interactions_count, 0)) as total_interactions,
    AVG(COALESCE(tua.load_time_ms, 0)) as avg_load_time_ms
FROM tab_usage_analytics tua
WHERE tua.session_start >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY DATE(tua.session_start), tua.tab_name;

-- Weekly user activity summary (refresh weekly)
CREATE MATERIALIZED VIEW weekly_user_activity AS
SELECT 
    DATE_TRUNC('week', tua.session_start) as week_start,
    tua.user_id,
    COUNT(DISTINCT tua.tab_name) as tabs_used,
    COUNT(*) as total_sessions,
    SUM(COALESCE(tua.session_duration_seconds, 0)) / 60 as total_minutes,
    AVG(COALESCE(tua.session_duration_seconds, 0)) / 60 as avg_session_minutes,
    COUNT(DISTINCT DATE(tua.session_start)) as active_days
FROM tab_usage_analytics tua
WHERE tua.session_start >= CURRENT_DATE - INTERVAL '12 weeks'
GROUP BY DATE_TRUNC('week', tua.session_start), tua.user_id;

-- =============================================================================
-- VIEW PERMISSIONS AND INDEXES
-- =============================================================================

-- Grant permissions for views
GRANT SELECT ON active_tabs_summary TO authenticated;
GRANT SELECT ON user_tab_dashboard TO authenticated;
GRANT SELECT ON tab_performance_analytics TO service_role;
GRANT SELECT ON home_screen_dashboard TO authenticated;
GRANT SELECT ON user_home_layout TO authenticated;
GRANT SELECT ON glitter_board_overview TO authenticated;
GRANT SELECT ON user_social_activity TO authenticated;
GRANT SELECT ON trending_glitter_posts TO authenticated;
GRANT SELECT ON horoscope_engagement_overview TO service_role;
GRANT SELECT ON daily_horoscope_analytics TO service_role;
GRANT SELECT ON tarot_reading_analytics TO service_role;
GRANT SELECT ON oracle_consultation_insights TO service_role;
GRANT SELECT ON magic_8ball_analytics TO service_role;
GRANT SELECT ON active_polls_overview TO authenticated;
GRANT SELECT ON poll_results_detailed TO authenticated;
GRANT SELECT ON user_voting_activity TO authenticated;
GRANT SELECT ON confession_analytics TO service_role;
GRANT SELECT ON confessions_moderation TO service_role;
GRANT SELECT ON daily_system_overview TO service_role;
GRANT SELECT ON user_engagement_summary TO authenticated;
GRANT SELECT ON daily_tabs_stats TO service_role;
GRANT SELECT ON weekly_user_activity TO service_role;

-- Create indexes for materialized views
CREATE UNIQUE INDEX idx_daily_tabs_stats_date_tab 
ON daily_tabs_stats (stats_date, tab_name);

CREATE UNIQUE INDEX idx_weekly_user_activity_week_user 
ON weekly_user_activity (week_start, user_id);

-- =============================================================================
-- REFRESH FUNCTIONS FOR MATERIALIZED VIEWS
-- =============================================================================

-- Refresh daily stats (call daily)
CREATE OR REPLACE FUNCTION refresh_daily_tabs_stats()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY daily_tabs_stats;
    RETURN 'Daily tabs stats refreshed at ' || NOW();
END;
$$;

-- Refresh weekly stats (call weekly)
CREATE OR REPLACE FUNCTION refresh_weekly_user_activity()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY weekly_user_activity;
    RETURN 'Weekly user activity refreshed at ' || NOW();
END;
$$;

-- Grant execution permissions
GRANT EXECUTE ON FUNCTION refresh_daily_tabs_stats TO service_role;
GRANT EXECUTE ON FUNCTION refresh_weekly_user_activity TO service_role;

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON VIEW active_tabs_summary IS 'Overview of all active tabs with user engagement metrics';
COMMENT ON VIEW user_tab_dashboard IS 'Personalized tab dashboard for each user with preferences';
COMMENT ON VIEW glitter_board_overview IS 'Social media posts with engagement metrics and reactions';
COMMENT ON VIEW trending_glitter_posts IS 'Top performing posts in the last 24 hours';
COMMENT ON VIEW horoscope_engagement_overview IS 'Horoscope system usage by zodiac sign';
COMMENT ON VIEW active_polls_overview IS 'Active community polls with voting statistics';
COMMENT ON VIEW user_engagement_summary IS 'Comprehensive user engagement across all features';
COMMENT ON MATERIALIZED VIEW daily_tabs_stats IS 'Daily aggregated statistics for tab usage (refresh daily)';
COMMENT ON MATERIALIZED VIEW weekly_user_activity IS 'Weekly user activity patterns (refresh weekly)';

-- Setup completion message
SELECT 'Tabs Views and Analytics Setup Complete!' as status, NOW() as setup_completed_at;
