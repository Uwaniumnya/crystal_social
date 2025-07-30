-- =====================================================
-- CRYSTAL SOCIAL - PROFILE SYSTEM EXTENDED VIEWS
-- =====================================================
-- Additional views for missing functionality discovered
-- in avatar_picker, sound systems, and production files
-- =====================================================

-- =====================================================
-- ASSET MANAGEMENT VIEWS
-- =====================================================

-- View for user avatar options (preset + custom)
CREATE OR REPLACE VIEW user_avatar_options AS
SELECT 
    'preset' as avatar_type,
    pa.avatar_id as id,
    pa.name,
    pa.description,
    pa.file_path,
    pa.category,
    pa.is_premium,
    CASE 
        WHEN pa.is_premium = false THEN true
        WHEN ui.user_id IS NOT NULL THEN true
        ELSE false
    END as is_unlocked,
    pa.unlock_cost,
    null::uuid as user_id,
    null::timestamp as upload_date,
    pa.sort_order,
    pa.metadata
FROM preset_avatars pa
LEFT JOIN user_inventory ui ON (
    ui.item_id = pa.avatar_id 
    AND ui.item_type = 'avatar'
)
WHERE pa.is_active = true

UNION ALL

SELECT 
    'custom' as avatar_type,
    uau.id::text as id,
    'Custom Avatar' as name,
    'User uploaded avatar' as description,
    uau.file_path,
    'custom' as category,
    false as is_premium,
    true as is_unlocked,
    0 as unlock_cost,
    uau.user_id,
    uau.created_at as upload_date,
    999 as sort_order,
    uau.upload_metadata as metadata
FROM user_avatar_uploads uau
WHERE uau.upload_status = 'completed';

-- View for user sound library with ownership status
CREATE OR REPLACE VIEW user_sound_library AS
SELECT 
    sc.sound_id,
    sc.name,
    sc.description,
    sc.category,
    sc.subcategory,
    sc.file_path,
    sc.duration_seconds,
    sc.is_premium,
    sc.unlock_cost,
    sc.rarity,
    sc.is_ringtone,
    sc.is_notification,
    sc.icon_name,
    sc.color_hex,
    sc.volume_level as default_volume,
    usi.user_id,
    CASE 
        WHEN sc.is_premium = false THEN true
        WHEN usi.user_id IS NOT NULL THEN true
        ELSE false
    END as is_owned,
    COALESCE(usi.is_favorite, false) as is_favorite,
    COALESCE(usi.custom_volume, sc.volume_level) as user_volume,
    usi.usage_count,
    usi.last_used_at,
    sc.sort_order,
    sc.metadata
FROM sound_catalog sc
LEFT JOIN user_sound_inventory usi ON usi.sound_id = sc.sound_id
WHERE sc.is_active = true
ORDER BY sc.category, sc.sort_order, sc.name;

-- View for user inventory with item details
CREATE OR REPLACE VIEW user_inventory_detailed AS
SELECT 
    ui.id,
    ui.user_id,
    ui.item_id,
    ui.item_type,
    ui.item_category,
    ui.quantity,
    ui.equipped,
    ui.unlock_method,
    ui.unlocked_at,
    ui.expires_at,
    ui.is_tradeable,
    ui.trade_value,
    ui.metadata as inventory_metadata,
    
    -- Item details based on type
    CASE 
        WHEN ui.item_type = 'decoration' THEN adc.name
        WHEN ui.item_type = 'theme' THEN pt.name
        WHEN ui.item_type = 'sound' THEN sc.name
        ELSE ui.item_id
    END as item_name,
    
    CASE 
        WHEN ui.item_type = 'decoration' THEN adc.description
        WHEN ui.item_type = 'theme' THEN pt.description
        WHEN ui.item_type = 'sound' THEN sc.description
        ELSE null
    END as item_description,
    
    CASE 
        WHEN ui.item_type = 'decoration' THEN adc.rarity
        WHEN ui.item_type = 'sound' THEN sc.rarity
        ELSE 'common'
    END as item_rarity,
    
    CASE 
        WHEN ui.item_type = 'decoration' THEN adc.image_path
        WHEN ui.item_type = 'theme' THEN pt.preview_image
        WHEN ui.item_type = 'sound' THEN sc.file_path
        ELSE null
    END as item_asset_path,
    
    CASE 
        WHEN ui.item_type = 'decoration' THEN adc.special_effects
        WHEN ui.item_type = 'theme' THEN pt.color_scheme
        WHEN ui.item_type = 'sound' THEN sc.metadata
        ELSE '{}'::jsonb
    END as item_metadata
    
FROM user_inventory ui
LEFT JOIN avatar_decorations_catalog adc ON (ui.item_type = 'decoration' AND ui.item_id = adc.decoration_id)
LEFT JOIN profile_themes pt ON (ui.item_type = 'theme' AND ui.item_id = pt.theme_id)
LEFT JOIN sound_catalog sc ON (ui.item_type = 'sound' AND ui.item_id = sc.sound_id);

-- =====================================================
-- ENHANCED PROFILE VIEWS
-- =====================================================

-- Comprehensive user profile view with all extensions
CREATE OR REPLACE VIEW user_profiles_complete AS
SELECT 
    -- Core profile data
    up.user_id,
    up.username,
    up.display_name,
    up.bio,
    up.location,
    up.website,
    up.avatar_url,
    up.avatar_decoration,
    up.interests,
    up.is_verified,
    up.is_private,
    up.profile_completion_percentage,
    up.reputation_score,
    up.last_active_at,
    up.created_at as profile_created_at,
    up.updated_at as profile_updated_at,
    
    -- Profile extensions
    upe.zodiac_sign,
    upe.birth_month,
    upe.birth_day,
    upe.show_zodiac,
    upe.show_birthday,
    upe.relationship_status,
    upe.show_relationship_status,
    upe.occupation,
    upe.show_occupation,
    upe.education,
    upe.show_education,
    upe.personality_traits,
    upe.favorite_quote,
    upe.life_motto,
    upe.custom_fields,
    
    -- Privacy settings
    ups.profile_visibility,
    ups.show_online_status,
    ups.show_last_seen,
    ups.show_location as privacy_show_location,
    ups.show_interests as privacy_show_interests,
    ups.show_social_links,
    ups.show_statistics,
    ups.show_achievements,
    ups.show_activity_feed,
    ups.allow_friend_requests,
    ups.allow_messages,
    ups.allow_profile_comments,
    ups.allow_tagging,
    ups.show_in_search,
    
    -- Activity stats
    uas.experience_points,
    uas.user_level,
    uas.total_messages_sent,
    uas.friends_count,
    uas.current_streak_days,
    uas.longest_streak_days,
    uas.total_login_days,
    (SELECT COUNT(*) FROM user_profile_achievements upa WHERE upa.user_id = up.user_id AND upa.is_completed = true) as achievements_unlocked,
    uas.most_active_day_of_week,
    
    -- Completion tracking
    pct.basic_info_completed,
    pct.avatar_uploaded,
    pct.bio_completed,
    pct.interests_added,
    pct.social_links_added,
    pct.privacy_configured,
    pct.theme_selected,
    pct.sounds_configured,
    pct.first_decoration_equipped,
    pct.first_friend_added,
    
    -- Current theme
    pt.name as current_theme_name,
    pt.color_scheme as theme_colors,
    
    -- Equipped decoration
    adc.name as decoration_name,
    adc.image_path as decoration_path
    
FROM user_profiles up
LEFT JOIN user_profile_extensions upe ON up.user_id = upe.user_id
LEFT JOIN user_privacy_settings ups ON up.user_id = ups.user_id
LEFT JOIN user_activity_stats uas ON up.user_id = uas.user_id
LEFT JOIN profile_completion_tracking pct ON up.user_id = pct.user_id
LEFT JOIN user_profile_themes upt ON (up.user_id = upt.user_id AND upt.is_active = true)
LEFT JOIN profile_themes pt ON upt.theme_id = pt.theme_id
LEFT JOIN avatar_decorations_catalog adc ON up.avatar_decoration = adc.decoration_id;

-- View for user social presence
CREATE OR REPLACE VIEW user_social_presence AS
SELECT 
    up.user_id,
    up.username,
    up.display_name,
    up.avatar_url,
    up.bio,
    up.is_verified,
    up.reputation_score,
    uas.user_level,
    uas.experience_points,
    uas.friends_count,
    uas.current_streak_days,
    
    -- Social links (only public ones for this view)
    COALESCE(
        json_agg(
            json_build_object(
                'platform', usl.platform,
                'username', usl.username,
                'url', usl.url,
                'is_verified', usl.is_verified
            ) ORDER BY usl.display_order
        ) FILTER (WHERE usl.is_public = true),
        '[]'::json
    ) as public_social_links,
    
    -- Equipped decoration
    adc.name as decoration_name,
    adc.image_path as decoration_image,
    adc.rarity as decoration_rarity,
    
    -- Current theme
    pt.name as theme_name,
    pt.category as theme_category,
    
    -- Privacy visibility
    COALESCE(ups.profile_visibility, 'public') as visibility,
    COALESCE(ups.show_online_status, true) as shows_online_status,
    
    up.last_active_at,
    up.created_at

FROM user_profiles up
LEFT JOIN user_activity_stats uas ON up.user_id = uas.user_id
LEFT JOIN user_social_links usl ON up.user_id = usl.user_id
LEFT JOIN user_privacy_settings ups ON up.user_id = ups.user_id
LEFT JOIN avatar_decorations_catalog adc ON up.avatar_decoration = adc.decoration_id
LEFT JOIN user_profile_themes upt ON (up.user_id = upt.user_id AND upt.is_active = true)
LEFT JOIN profile_themes pt ON upt.theme_id = pt.theme_id
GROUP BY 
    up.user_id, up.username, up.display_name, up.avatar_url, up.bio,
    up.is_verified, up.reputation_score, uas.user_level, uas.experience_points,
    uas.friends_count, uas.current_streak_days, adc.name, adc.image_path,
    adc.rarity, pt.name, pt.category, ups.profile_visibility,
    ups.show_online_status, up.last_active_at, up.created_at;

-- =====================================================
-- SYSTEM MONITORING VIEWS
-- =====================================================

-- Performance metrics dashboard view
CREATE OR REPLACE VIEW performance_dashboard AS
SELECT 
    pm.metric_category,
    pm.metric_name,
    COUNT(*) as sample_count,
    AVG(pm.metric_value) as avg_value,
    MIN(pm.metric_value) as min_value,
    MAX(pm.metric_value) as max_value,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY pm.metric_value) as median_value,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY pm.metric_value) as p95_value,
    STDDEV(pm.metric_value) as std_deviation,
    MAX(pm.metric_unit) as metric_unit,
    DATE_TRUNC('hour', pm.recorded_at) as hour_bucket,
    COUNT(DISTINCT pm.user_id) as unique_users
FROM performance_metrics pm
WHERE pm.recorded_at >= NOW() - INTERVAL '24 hours'
GROUP BY pm.metric_category, pm.metric_name, DATE_TRUNC('hour', pm.recorded_at)
ORDER BY hour_bucket DESC, pm.metric_category, pm.metric_name;

-- System health overview
CREATE OR REPLACE VIEW system_health_overview AS
SELECT 
    -- User activity metrics
    (SELECT COUNT(*) FROM user_profiles WHERE created_at >= CURRENT_DATE) as new_users_today,
    (SELECT COUNT(*) FROM user_profiles WHERE last_active_at >= NOW() - INTERVAL '24 hours') as active_users_24h,
    (SELECT COUNT(*) FROM user_profiles WHERE last_active_at >= NOW() - INTERVAL '1 hour') as active_users_1h,
    
    -- Upload metrics
    (SELECT COUNT(*) FROM user_avatar_uploads WHERE created_at >= CURRENT_DATE) as avatar_uploads_today,
    (SELECT COUNT(*) FROM user_avatar_uploads WHERE upload_status = 'failed' AND created_at >= CURRENT_DATE) as failed_uploads_today,
    
    -- Performance metrics
    (SELECT AVG(metric_value) FROM performance_metrics 
     WHERE metric_name = 'avatar_upload_duration' AND recorded_at >= NOW() - INTERVAL '1 hour') as avg_upload_time_ms,
    
    -- Premium purchases
    (SELECT COUNT(*) FROM user_premium_purchases WHERE purchased_at >= CURRENT_DATE) as premium_purchases_today,
    (SELECT SUM(amount_paid) FROM user_premium_purchases 
     WHERE currency_type = 'USD' AND purchased_at >= CURRENT_DATE) as revenue_today_usd,
    
    -- System configuration status
    (SELECT COUNT(*) FROM system_configuration WHERE environment = 'production') as config_entries,
    
    -- Error rates
    (SELECT COUNT(*) FROM validation_logs 
     WHERE validation_result = 'failed' AND performed_at >= NOW() - INTERVAL '1 hour') as errors_last_hour,
    
    -- Current timestamp
    NOW() as snapshot_time;

-- User engagement analytics view
CREATE OR REPLACE VIEW user_engagement_analytics AS
SELECT 
    DATE_TRUNC('day', up.created_at) as registration_date,
    COUNT(*) as registrations,
    COUNT(*) FILTER (WHERE up.profile_completion_percentage >= 50) as completed_profiles,
    COUNT(*) FILTER (WHERE up.last_active_at >= up.created_at + INTERVAL '1 day') as retained_day_1,
    COUNT(*) FILTER (WHERE up.last_active_at >= up.created_at + INTERVAL '7 days') as retained_day_7,
    COUNT(*) FILTER (WHERE up.last_active_at >= up.created_at + INTERVAL '30 days') as retained_day_30,
    
    -- Average completion metrics
    AVG(up.profile_completion_percentage) as avg_completion,
    AVG(uas.total_messages_sent) as avg_messages,
    AVG(uas.friends_count) as avg_friends,
    
    -- Engagement indicators
    COUNT(*) FILTER (WHERE EXISTS (
        SELECT 1 FROM user_inventory ui 
        WHERE ui.user_id = up.user_id AND ui.equipped = true
    )) as users_with_decorations,
    
    COUNT(*) FILTER (WHERE EXISTS (
        SELECT 1 FROM user_social_links usl 
        WHERE usl.user_id = up.user_id
    )) as users_with_social_links,
    
    COUNT(*) FILTER (WHERE EXISTS (
        SELECT 1 FROM user_premium_purchases upp 
        WHERE upp.user_id = up.user_id AND upp.purchase_status = 'completed'
    )) as paying_users

FROM user_profiles up
LEFT JOIN user_activity_stats uas ON up.user_id = uas.user_id
WHERE up.created_at >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY DATE_TRUNC('day', up.created_at)
ORDER BY registration_date DESC;

-- =====================================================
-- PREMIUM CONTENT VIEWS
-- =====================================================

-- Premium content marketplace view
CREATE OR REPLACE VIEW premium_content_marketplace AS
SELECT 
    pc.content_id,
    pc.content_type,
    pc.name,
    pc.description,
    pc.category,
    pc.price_gems,
    pc.price_currency,
    pc.currency_type,
    pc.discount_percentage,
    CASE 
        WHEN pc.discount_percentage > 0 THEN 
            ROUND(pc.price_gems * (100 - pc.discount_percentage) / 100)
        ELSE pc.price_gems
    END as discounted_price_gems,
    pc.is_limited_edition,
    pc.max_purchases,
    pc.current_purchases,
    CASE 
        WHEN pc.max_purchases IS NULL THEN true
        ELSE pc.current_purchases < pc.max_purchases
    END as is_available,
    pc.availability_start,
    pc.availability_end,
    
    -- Popularity metrics
    COUNT(upp.id) as total_purchases,
    COUNT(upp.id) FILTER (WHERE upp.purchased_at >= NOW() - INTERVAL '7 days') as purchases_last_7_days,
    AVG(5.0) as rating, -- Placeholder for future rating system
    
    -- Asset information
    CASE 
        WHEN pc.content_type = 'decoration' THEN adc.image_path
        WHEN pc.content_type = 'theme' THEN pt.preview_image
        WHEN pc.content_type = 'sound' THEN sc.file_path
        ELSE null
    END as asset_path,
    
    CASE 
        WHEN pc.content_type = 'decoration' THEN adc.rarity
        WHEN pc.content_type = 'sound' THEN sc.rarity
        ELSE 'common'
    END as rarity,
    
    pc.metadata,
    pc.created_at,
    pc.updated_at

FROM premium_content pc
LEFT JOIN user_premium_purchases upp ON pc.content_id = upp.content_id
LEFT JOIN avatar_decorations_catalog adc ON (pc.content_type = 'decoration' AND pc.content_id = adc.decoration_id)
LEFT JOIN profile_themes pt ON (pc.content_type = 'theme' AND pc.content_id = pt.theme_id)
LEFT JOIN sound_catalog sc ON (pc.content_type = 'sound' AND pc.content_id = sc.sound_id)
WHERE pc.is_active = true
AND (pc.availability_start IS NULL OR pc.availability_start <= NOW())
AND (pc.availability_end IS NULL OR pc.availability_end >= NOW())
GROUP BY 
    pc.content_id, pc.content_type, pc.name, pc.description, pc.category,
    pc.price_gems, pc.price_currency, pc.currency_type, pc.discount_percentage,
    pc.is_limited_edition, pc.max_purchases, pc.current_purchases,
    pc.availability_start, pc.availability_end, adc.image_path, pt.preview_image,
    sc.file_path, adc.rarity, sc.rarity, pc.metadata, pc.created_at, pc.updated_at
ORDER BY purchases_last_7_days DESC, total_purchases DESC;

-- User purchase history view
CREATE OR REPLACE VIEW user_purchase_history AS
SELECT 
    upp.user_id,
    upp.content_id,
    pc.name as content_name,
    pc.content_type,
    pc.category,
    upp.purchase_method,
    upp.amount_paid,
    upp.currency_type,
    upp.transaction_id,
    upp.purchase_status,
    upp.purchased_at,
    upp.expires_at,
    upp.refunded_at,
    
    -- Content details
    CASE 
        WHEN pc.content_type = 'decoration' THEN adc.image_path
        WHEN pc.content_type = 'theme' THEN pt.preview_image
        WHEN pc.content_type = 'sound' THEN sc.file_path
        ELSE null
    END as content_asset_path,
    
    CASE 
        WHEN pc.content_type = 'decoration' THEN adc.rarity
        WHEN pc.content_type = 'sound' THEN sc.rarity
        ELSE 'common'
    END as content_rarity,
    
    -- Current ownership status
    EXISTS (
        SELECT 1 FROM user_inventory ui 
        WHERE ui.user_id = upp.user_id 
        AND ui.item_id = upp.content_id
    ) as currently_owned

FROM user_premium_purchases upp
JOIN premium_content pc ON upp.content_id = pc.content_id
LEFT JOIN avatar_decorations_catalog adc ON (pc.content_type = 'decoration' AND pc.content_id = adc.decoration_id)
LEFT JOIN profile_themes pt ON (pc.content_type = 'theme' AND pc.content_id = pt.theme_id)
LEFT JOIN sound_catalog sc ON (pc.content_type = 'sound' AND pc.content_id = sc.sound_id)
ORDER BY upp.purchased_at DESC;

-- =====================================================
-- ANALYTICS AND INSIGHTS VIEWS
-- =====================================================

-- Content popularity analytics
CREATE OR REPLACE VIEW content_popularity_analytics AS
SELECT 
    'decoration' as content_type,
    adc.decoration_id as content_id,
    adc.name,
    adc.category,
    adc.rarity,
    COUNT(ui.id) as users_owned,
    COUNT(ui.id) FILTER (WHERE ui.equipped = true) as users_equipped,
    COUNT(ui.id) FILTER (WHERE ui.unlocked_at >= NOW() - INTERVAL '7 days') as new_unlocks_7d,
    ROUND(COUNT(ui.id) * 100.0 / NULLIF((SELECT COUNT(*) FROM user_profiles), 0), 2) as ownership_percentage
FROM avatar_decorations_catalog adc
LEFT JOIN user_inventory ui ON (ui.item_id = adc.decoration_id AND ui.item_type = 'decoration')
GROUP BY adc.decoration_id, adc.name, adc.category, adc.rarity

UNION ALL

SELECT 
    'theme' as content_type,
    pt.theme_id as content_id,
    pt.name,
    pt.category,
    'common' as rarity,
    COUNT(ui.id) as users_owned,
    COUNT(upt.user_id) as users_equipped,
    COUNT(ui.id) FILTER (WHERE ui.unlocked_at >= NOW() - INTERVAL '7 days') as new_unlocks_7d,
    ROUND(COUNT(ui.id) * 100.0 / NULLIF((SELECT COUNT(*) FROM user_profiles), 0), 2) as ownership_percentage
FROM profile_themes pt
LEFT JOIN user_inventory ui ON (ui.item_id = pt.theme_id AND ui.item_type = 'theme')
LEFT JOIN user_profile_themes upt ON (upt.theme_id = pt.theme_id AND upt.is_active = true)
GROUP BY pt.theme_id, pt.name, pt.category

UNION ALL

SELECT 
    'sound' as content_type,
    sc.sound_id as content_id,
    sc.name,
    sc.category,
    sc.rarity,
    COUNT(usi.id) as users_owned,
    COUNT(usi.id) FILTER (WHERE usi.is_favorite = true) as users_equipped,
    COUNT(usi.id) FILTER (WHERE usi.unlocked_at >= NOW() - INTERVAL '7 days') as new_unlocks_7d,
    ROUND(COUNT(usi.id) * 100.0 / NULLIF((SELECT COUNT(*) FROM user_profiles), 0), 2) as ownership_percentage
FROM sound_catalog sc
LEFT JOIN user_sound_inventory usi ON usi.sound_id = sc.sound_id
GROUP BY sc.sound_id, sc.name, sc.category, sc.rarity

ORDER BY users_owned DESC, users_equipped DESC;

-- Profile completion funnel view
CREATE OR REPLACE VIEW profile_completion_funnel AS
SELECT 
    'Total Users' as step,
    COUNT(*) as user_count,
    100.0 as percentage,
    0 as step_order
FROM user_profiles

UNION ALL

SELECT 
    'Basic Info Completed' as step,
    COUNT(*) as user_count,
    ROUND(COUNT(*) * 100.0 / NULLIF((SELECT COUNT(*) FROM user_profiles), 0), 1) as percentage,
    1 as step_order
FROM profile_completion_tracking
WHERE basic_info_completed = true

UNION ALL

SELECT 
    'Avatar Uploaded' as step,
    COUNT(*) as user_count,
    ROUND(COUNT(*) * 100.0 / NULLIF((SELECT COUNT(*) FROM user_profiles), 0), 1) as percentage,
    2 as step_order
FROM profile_completion_tracking
WHERE avatar_uploaded = true

UNION ALL

SELECT 
    'Bio Completed' as step,
    COUNT(*) as user_count,
    ROUND(COUNT(*) * 100.0 / NULLIF((SELECT COUNT(*) FROM user_profiles), 0), 1) as percentage,
    3 as step_order
FROM profile_completion_tracking
WHERE bio_completed = true

UNION ALL

SELECT 
    'Interests Added' as step,
    COUNT(*) as user_count,
    ROUND(COUNT(*) * 100.0 / NULLIF((SELECT COUNT(*) FROM user_profiles), 0), 1) as percentage,
    4 as step_order
FROM profile_completion_tracking
WHERE interests_added = true

UNION ALL

SELECT 
    'Social Links Added' as step,
    COUNT(*) as user_count,
    ROUND(COUNT(*) * 100.0 / NULLIF((SELECT COUNT(*) FROM user_profiles), 0), 1) as percentage,
    5 as step_order
FROM profile_completion_tracking
WHERE social_links_added = true

UNION ALL

SELECT 
    'First Friend Added' as step,
    COUNT(*) as user_count,
    ROUND(COUNT(*) * 100.0 / NULLIF((SELECT COUNT(*) FROM user_profiles), 0), 1) as percentage,
    6 as step_order
FROM profile_completion_tracking
WHERE first_friend_added = true

UNION ALL

SELECT 
    'Decoration Equipped' as step,
    COUNT(*) as user_count,
    ROUND(COUNT(*) * 100.0 / NULLIF((SELECT COUNT(*) FROM user_profiles), 0), 1) as percentage,
    7 as step_order
FROM profile_completion_tracking
WHERE first_decoration_equipped = true

UNION ALL

SELECT 
    'Profile 100% Complete' as step,
    COUNT(*) as user_count,
    ROUND(COUNT(*) * 100.0 / NULLIF((SELECT COUNT(*) FROM user_profiles), 0), 1) as percentage,
    8 as step_order
FROM profile_completion_tracking
WHERE completion_percentage = 100

ORDER BY step_order;

-- =====================================================
-- MATERIALIZED VIEWS FOR PERFORMANCE
-- =====================================================

-- Materialized view for user leaderboards (refresh daily)
DROP VIEW IF EXISTS user_leaderboards CASCADE;
DROP MATERIALIZED VIEW IF EXISTS user_leaderboards CASCADE;
CREATE MATERIALIZED VIEW user_leaderboards AS
SELECT 
    up.user_id,
    up.username,
    up.display_name,
    up.avatar_url,
    up.reputation_score,
    uas.user_level,
    uas.experience_points,
    uas.current_streak_days,
    uas.friends_count,
    (SELECT COUNT(*) FROM user_profile_achievements upa WHERE upa.user_id = up.user_id AND upa.is_completed = true) as achievements_unlocked,
    adc.name as decoration_name,
    adc.image_path as decoration_image,
    ROW_NUMBER() OVER (ORDER BY uas.experience_points DESC) as xp_rank,
    ROW_NUMBER() OVER (ORDER BY up.reputation_score DESC) as reputation_rank,
    ROW_NUMBER() OVER (ORDER BY uas.current_streak_days DESC) as streak_rank,
    ROW_NUMBER() OVER (ORDER BY uas.friends_count DESC) as social_rank,
    up.last_active_at,
    up.created_at
FROM user_profiles up
JOIN user_activity_stats uas ON up.user_id = uas.user_id
LEFT JOIN avatar_decorations_catalog adc ON up.avatar_decoration = adc.decoration_id
WHERE up.is_private = false
AND up.last_active_at >= NOW() - INTERVAL '30 days';

-- Create index on materialized view
DROP INDEX IF EXISTS idx_user_leaderboards_user_id;
DROP INDEX IF EXISTS idx_user_leaderboards_xp_rank;
DROP INDEX IF EXISTS idx_user_leaderboards_reputation_rank;
CREATE UNIQUE INDEX idx_user_leaderboards_user_id ON user_leaderboards(user_id);
CREATE INDEX idx_user_leaderboards_xp_rank ON user_leaderboards(xp_rank);
CREATE INDEX idx_user_leaderboards_reputation_rank ON user_leaderboards(reputation_rank);

-- =====================================================
-- VIEW REFRESH FUNCTIONS
-- =====================================================

-- Function to refresh materialized views
CREATE OR REPLACE FUNCTION refresh_profile_materialized_views()
RETURNS VOID AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY user_leaderboards;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT EXECUTE ON FUNCTION refresh_profile_materialized_views() TO service_role;

-- =====================================================
-- VIEW DOCUMENTATION
-- =====================================================

-- Add comments to views
COMMENT ON VIEW user_avatar_options IS 'Combined view of preset and custom avatar options for users';
COMMENT ON VIEW user_sound_library IS 'Complete sound library with user ownership and preference data';
COMMENT ON VIEW user_inventory_detailed IS 'Detailed user inventory with full item information';
COMMENT ON VIEW user_profiles_complete IS 'Comprehensive user profile data including all extensions and settings';
COMMENT ON VIEW user_social_presence IS 'Public-facing user profile information for social features';
COMMENT ON VIEW performance_dashboard IS 'Real-time performance metrics dashboard data';
COMMENT ON VIEW system_health_overview IS 'System health and activity overview metrics';
COMMENT ON VIEW premium_content_marketplace IS 'Premium content available for purchase with popularity metrics';
COMMENT ON VIEW content_popularity_analytics IS 'Analytics on content usage and popularity across all types';
COMMENT ON VIEW profile_completion_funnel IS 'Profile completion funnel analysis for user onboarding';
COMMENT ON MATERIALIZED VIEW user_leaderboards IS 'Cached leaderboard rankings for performance (refreshed daily)';

-- =====================================================
-- END OF EXTENDED VIEWS
-- =====================================================
