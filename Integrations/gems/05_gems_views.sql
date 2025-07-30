-- =====================================================
-- CRYSTAL SOCIAL - GEMS SYSTEM VIEWS
-- =====================================================
-- Optimized views for gem system queries
-- =====================================================

-- View for complete gem collection with user data
CREATE OR REPLACE VIEW gem_collection_overview AS
SELECT 
    ug.id as user_gem_id,
    ug.user_id,
    ug.gem_id,
    ug.unlocked_at,
    ug.unlock_source,
    ug.is_favorite,
    ug.times_viewed,
    ug.first_viewed_at,
    ug.last_viewed_at,
    ug.power_level,
    ug.enhancement_level,
    ug.custom_name,
    ug.notes,
    
    -- Gem details
    eg.name,
    eg.description,
    eg.image_path,
    eg.rarity,
    eg.element,
    eg.power as base_power,
    eg.value as base_value,
    eg.source,
    eg.category,
    eg.tags,
    eg.sparkle_intensity,
    eg.special_effects,
    eg.animation_type,
    
    -- User profile info
    p.username,
    p.display_name,
    p.avatar_url,
    
    -- Calculated values
    (eg.power + (ug.power_level - 1) + (ug.enhancement_level * 10)) as total_power,
    (eg.value + (ug.enhancement_level * 50)) as total_value,
    
    -- Enhancement summary
    COALESCE(enh.enhancement_count, 0) as enhancement_attempts,
    COALESCE(enh.successful_enhancements, 0) as successful_enhancements,
    COALESCE(enh.total_enhancement_cost, 0) as total_enhancement_cost,
    
    -- Rarity rank
    CASE eg.rarity
        WHEN 'mythic' THEN 6
        WHEN 'legendary' THEN 5
        WHEN 'epic' THEN 4
        WHEN 'rare' THEN 3
        WHEN 'uncommon' THEN 2
        ELSE 1
    END as rarity_rank,
    
    -- Time since unlock
    EXTRACT(EPOCH FROM (NOW() - ug.unlocked_at)) / 86400 as days_since_unlock
    
FROM user_gemstones ug
LEFT JOIN enhanced_gemstones eg ON ug.gem_id = eg.id
LEFT JOIN profiles p ON ug.user_id = p.id
LEFT JOIN (
    SELECT 
        user_gem_id,
        COUNT(*) as enhancement_count,
        SUM(CASE WHEN was_successful THEN 1 ELSE 0 END) as successful_enhancements,
        SUM(enhancement_cost_coins + enhancement_cost_gems) as total_enhancement_cost
    FROM gem_enhancements
    GROUP BY user_gem_id
) enh ON ug.id = enh.user_gem_id;

-- View for gem discovery analytics
CREATE OR REPLACE VIEW gem_discovery_analytics AS
SELECT 
    gde.id,
    gde.user_id,
    gde.gem_id,
    gde.discovery_method,
    gde.discovery_location,
    gde.was_rare_unlock,
    gde.experience_gained,
    gde.coins_gained,
    gde.gems_gained,
    gde.discovery_streak,
    gde.created_at,
    
    -- Gem details
    eg.name as gem_name,
    eg.rarity,
    eg.element,
    eg.power,
    eg.value,
    eg.category,
    
    -- User details
    p.username,
    p.display_name,
    
    -- Time-based analytics
    DATE(gde.created_at) as discovery_date,
    EXTRACT(HOUR FROM gde.created_at) as discovery_hour,
    EXTRACT(DOW FROM gde.created_at) as discovery_day_of_week,
    
    -- Discovery method details
    gdm.display_name as method_display_name,
    gdm.discovery_chance,
    
    -- Calculated metrics
    CASE 
        WHEN gde.was_rare_unlock THEN 'RARE'
        ELSE 'NORMAL'
    END as unlock_type,
    
    -- Value efficiency
    CASE 
        WHEN gde.coins_gained > 0 THEN eg.value::DECIMAL / gde.coins_gained
        ELSE 0
    END as value_efficiency
    
FROM gem_discovery_events gde
LEFT JOIN enhanced_gemstones eg ON gde.gem_id = eg.id
LEFT JOIN profiles p ON gde.user_id = p.id
LEFT JOIN gem_discovery_methods gdm ON gde.discovery_method = gdm.method_name
ORDER BY gde.created_at DESC;

-- View for gem collection leaderboards
CREATE OR REPLACE VIEW gem_collection_leaderboard AS
SELECT 
    gcs.user_id,
    p.username,
    p.display_name,
    p.avatar_url,
    gcs.unique_gems_collected,
    gcs.total_collection_value,
    gcs.total_collection_power,
    gcs.completion_percentage,
    gcs.rarity_stats,
    gcs.element_stats,
    gcs.first_gem_unlocked_at,
    gcs.last_gem_unlocked_at,
    gcs.rarest_gem_unlocked,
    
    -- Most valuable gem details
    mvg.name as most_valuable_gem_name,
    mvg.value as most_valuable_gem_value,
    mvg.rarity as most_valuable_gem_rarity,
    
    -- Rankings
    RANK() OVER (ORDER BY gcs.unique_gems_collected DESC) as collection_rank,
    RANK() OVER (ORDER BY gcs.total_collection_value DESC) as value_rank,
    RANK() OVER (ORDER BY gcs.total_collection_power DESC) as power_rank,
    RANK() OVER (ORDER BY gcs.completion_percentage DESC) as completion_rank,
    
    -- Achievement count
    COALESCE(ach.completed_achievements, 0) as completed_achievements,
    COALESCE(ach.total_achievements, 0) as total_achievements,
    
    -- Activity metrics
    COALESCE(recent.recent_discoveries, 0) as recent_discoveries,
    COALESCE(recent.recent_enhancements, 0) as recent_enhancements
    
FROM gem_collection_stats gcs
LEFT JOIN profiles p ON gcs.user_id = p.id
LEFT JOIN enhanced_gemstones mvg ON gcs.most_valuable_gem_id = mvg.id
LEFT JOIN (
    SELECT 
        user_id,
        SUM(CASE WHEN is_completed THEN 1 ELSE 0 END) as completed_achievements,
        COUNT(*) as total_achievements
    FROM gem_achievements
    GROUP BY user_id
) ach ON gcs.user_id = ach.user_id
LEFT JOIN (
    SELECT 
        user_id,
        SUM(gems_discovered) as recent_discoveries,
        SUM(gems_enhanced) as recent_enhancements
    FROM gem_analytics
    WHERE date >= CURRENT_DATE - INTERVAL '7 days'
    GROUP BY user_id
) recent ON gcs.user_id = recent.user_id
ORDER BY gcs.completion_percentage DESC, gcs.unique_gems_collected DESC;

-- View for active gem trades with full details
CREATE OR REPLACE VIEW active_gem_trades AS
SELECT 
    gt.id,
    gt.trade_type,
    gt.seller_id,
    gt.buyer_id,
    gt.gem_id,
    gt.price_coins,
    gt.price_gems,
    gt.price_type,
    gt.status,
    gt.expires_at,
    gt.created_at,
    
    -- Seller details
    seller.username as seller_username,
    seller.display_name as seller_display_name,
    seller.avatar_url as seller_avatar,
    
    -- Buyer details (if any)
    buyer.username as buyer_username,
    buyer.display_name as buyer_display_name,
    buyer.avatar_url as buyer_avatar,
    
    -- Gem details
    eg.name as gem_name,
    eg.description as gem_description,
    eg.image_path as gem_image,
    eg.rarity,
    eg.element,
    eg.power as base_power,
    eg.value as base_value,
    eg.category,
    eg.tags,
    
    -- User gem details (if available)
    ug.enhancement_level,
    ug.power_level,
    ug.custom_name,
    (eg.power + (ug.power_level - 1) + (ug.enhancement_level * 10)) as total_power,
    (eg.value + (ug.enhancement_level * 50)) as total_value,
    
    -- Trade analytics
    EXTRACT(EPOCH FROM (gt.expires_at - NOW())) / 3600 as hours_until_expiry,
    
    -- Price analysis
    CASE 
        WHEN gt.price_coins > 0 AND eg.value > 0 THEN 
            (gt.price_coins::DECIMAL / eg.value) * 100
        ELSE NULL
    END as price_vs_base_value_percentage,
    
    -- Rarity rank for sorting
    CASE eg.rarity
        WHEN 'mythic' THEN 6
        WHEN 'legendary' THEN 5
        WHEN 'epic' THEN 4
        WHEN 'rare' THEN 3
        WHEN 'uncommon' THEN 2
        ELSE 1
    END as rarity_rank
    
FROM gem_trades gt
LEFT JOIN profiles seller ON gt.seller_id = seller.id
LEFT JOIN profiles buyer ON gt.buyer_id = buyer.id
LEFT JOIN enhanced_gemstones eg ON gt.gem_id = eg.id
LEFT JOIN user_gemstones ug ON gt.user_gem_id = ug.id
WHERE gt.status = 'active'
AND (gt.expires_at IS NULL OR gt.expires_at > NOW())
ORDER BY rarity_rank DESC, gt.created_at DESC;

-- View for gem achievement progress with details
CREATE OR REPLACE VIEW gem_achievement_progress AS
SELECT 
    ga.id,
    ga.user_id,
    ga.achievement_type,
    ga.achievement_name,
    ga.description,
    ga.current_value,
    ga.target_value,
    ga.progress_percentage,
    ga.is_completed,
    ga.completed_at,
    ga.reward_coins,
    ga.reward_gems,
    ga.reward_items,
    ga.rarity,
    ga.category,
    ga.is_hidden,
    ga.created_at,
    ga.updated_at,
    
    -- User details
    p.username,
    p.display_name,
    p.avatar_url,
    
    -- Progress status
    CASE 
        WHEN ga.is_completed THEN 'completed'
        WHEN ga.progress_percentage >= 90 THEN 'almost_complete'
        WHEN ga.progress_percentage >= 75 THEN 'good_progress'
        WHEN ga.progress_percentage >= 50 THEN 'halfway'
        WHEN ga.progress_percentage >= 25 THEN 'started'
        ELSE 'not_started'
    END as progress_status,
    
    -- Difficulty assessment
    CASE 
        WHEN ga.target_value >= 1000 THEN 'legendary'
        WHEN ga.target_value >= 100 THEN 'epic'
        WHEN ga.target_value >= 50 THEN 'hard'
        WHEN ga.target_value >= 10 THEN 'medium'
        ELSE 'easy'
    END as difficulty,
    
    -- Time to completion estimate (if trending)
    CASE 
        WHEN ga.progress_percentage > 0 AND NOT ga.is_completed THEN
            EXTRACT(EPOCH FROM (NOW() - ga.created_at)) / ga.progress_percentage * (100 - ga.progress_percentage)
        ELSE NULL
    END as estimated_seconds_to_completion,
    
    -- Rarity rank for rewards
    CASE ga.rarity
        WHEN 'legendary' THEN 5
        WHEN 'epic' THEN 4
        WHEN 'rare' THEN 3
        WHEN 'uncommon' THEN 2
        ELSE 1
    END as rarity_rank
    
FROM gem_achievements ga
LEFT JOIN profiles p ON ga.user_id = p.id
ORDER BY ga.is_completed, ga.progress_percentage DESC, rarity_rank DESC;

-- View for daily quest progress with analytics
CREATE OR REPLACE VIEW gem_daily_quest_progress AS
SELECT 
    gdq.id,
    gdq.user_id,
    gdq.quest_type,
    gdq.quest_name,
    gdq.description,
    gdq.current_value,
    gdq.target_value,
    gdq.progress_percentage,
    gdq.is_completed,
    gdq.completed_at,
    gdq.reward_coins,
    gdq.reward_gems,
    gdq.reward_experience,
    gdq.quest_date,
    gdq.difficulty,
    gdq.bonus_multiplier,
    gdq.auto_generated,
    
    -- User details
    p.username,
    p.display_name,
    
    -- Time analysis
    CASE 
        WHEN gdq.quest_date < CURRENT_DATE THEN 'expired'
        WHEN gdq.is_completed THEN 'completed'
        WHEN gdq.quest_date = CURRENT_DATE THEN 'active'
        ELSE 'future'
    END as quest_status,
    
    -- Time remaining for today's quests
    CASE 
        WHEN gdq.quest_date = CURRENT_DATE AND NOT gdq.is_completed THEN
            EXTRACT(EPOCH FROM (CURRENT_DATE + INTERVAL '1 day' - NOW())) / 3600
        ELSE NULL
    END as hours_remaining,
    
    -- Progress assessment
    CASE 
        WHEN gdq.is_completed THEN 'completed'
        WHEN gdq.progress_percentage >= 80 THEN 'almost_done'
        WHEN gdq.progress_percentage >= 50 THEN 'halfway'
        WHEN gdq.progress_percentage > 0 THEN 'started'
        ELSE 'not_started'
    END as progress_status,
    
    -- Difficulty multiplier
    CASE gdq.difficulty
        WHEN 'legendary' THEN 4.0
        WHEN 'epic' THEN 3.0
        WHEN 'hard' THEN 2.0
        WHEN 'normal' THEN 1.0
        ELSE 0.5
    END as difficulty_multiplier,
    
    -- Total potential rewards (with bonuses)
    (gdq.reward_coins * gdq.bonus_multiplier)::INTEGER as total_coin_reward,
    (gdq.reward_gems * gdq.bonus_multiplier)::INTEGER as total_gem_reward,
    (gdq.reward_experience * gdq.bonus_multiplier)::INTEGER as total_exp_reward
    
FROM gem_daily_quests gdq
LEFT JOIN profiles p ON gdq.user_id = p.id
WHERE gdq.quest_date >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY gdq.quest_date DESC, gdq.is_completed, gdq.progress_percentage DESC;

-- View for gem analytics summary with trends
CREATE OR REPLACE VIEW gem_analytics_summary AS
SELECT 
    ga.user_id,
    ga.date,
    ga.gems_discovered,
    ga.gems_enhanced,
    ga.gems_traded,
    ga.gems_viewed,
    ga.favorites_added,
    ga.favorites_removed,
    ga.coins_spent_on_gems,
    ga.gems_spent_on_enhancements,
    ga.total_value_gained,
    ga.total_power_gained,
    ga.achievements_unlocked,
    ga.quests_completed,
    ga.time_spent_minutes,
    ga.session_count,
    
    -- User details
    p.username,
    p.display_name,
    
    -- Calculated metrics
    CASE 
        WHEN ga.session_count > 0 THEN ga.time_spent_minutes::DECIMAL / ga.session_count
        ELSE 0
    END as avg_session_duration,
    
    CASE 
        WHEN ga.gems_viewed > 0 THEN ga.gems_discovered::DECIMAL / ga.gems_viewed * 100
        ELSE 0
    END as discovery_rate_percentage,
    
    CASE 
        WHEN ga.gems_enhanced > 0 AND ga.gems_spent_on_enhancements > 0 THEN
            ga.total_power_gained::DECIMAL / ga.gems_spent_on_enhancements
        ELSE 0
    END as power_per_gem_spent,
    
    -- Activity level
    CASE 
        WHEN (ga.gems_discovered + ga.gems_enhanced + ga.gems_viewed) >= 50 THEN 'very_active'
        WHEN (ga.gems_discovered + ga.gems_enhanced + ga.gems_viewed) >= 20 THEN 'active'
        WHEN (ga.gems_discovered + ga.gems_enhanced + ga.gems_viewed) >= 10 THEN 'moderate'
        WHEN (ga.gems_discovered + ga.gems_enhanced + ga.gems_viewed) > 0 THEN 'light'
        ELSE 'inactive'
    END as activity_level,
    
    -- Trend analysis (compared to previous day)
    LAG(ga.gems_discovered) OVER (PARTITION BY ga.user_id ORDER BY ga.date) as prev_day_discoveries,
    LAG(ga.total_value_gained) OVER (PARTITION BY ga.user_id ORDER BY ga.date) as prev_day_value,
    
    -- Weekly totals
    SUM(ga.gems_discovered) OVER (
        PARTITION BY ga.user_id 
        ORDER BY ga.date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as weekly_discoveries,
    
    SUM(ga.total_value_gained) OVER (
        PARTITION BY ga.user_id 
        ORDER BY ga.date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as weekly_value_gained
    
FROM gem_analytics ga
LEFT JOIN profiles p ON ga.user_id = p.id
ORDER BY ga.date DESC, ga.user_id;

-- View for public gem showcases
CREATE OR REPLACE VIEW public_gem_showcases AS
SELECT 
    gss.id,
    gss.user_id,
    gss.gem_id,
    gss.share_type,
    gss.share_message,
    gss.share_image_url,
    gss.likes_count,
    gss.comments_count,
    gss.featured_until,
    gss.created_at,
    
    -- User details
    p.username,
    p.display_name,
    p.avatar_url,
    
    -- Gem details
    eg.name as gem_name,
    eg.description as gem_description,
    eg.image_path as gem_image,
    eg.rarity,
    eg.element,
    eg.power,
    eg.value,
    eg.category,
    eg.tags,
    
    -- User gem details (if available)
    ug.enhancement_level,
    ug.power_level,
    ug.custom_name,
    ug.unlocked_at,
    
    -- Calculated metrics
    CASE 
        WHEN gss.created_at > NOW() - INTERVAL '24 hours' THEN 'new'
        WHEN gss.created_at > NOW() - INTERVAL '7 days' THEN 'recent'
        ELSE 'older'
    END as recency,
    
    CASE 
        WHEN gss.likes_count >= 100 THEN 'viral'
        WHEN gss.likes_count >= 50 THEN 'popular'
        WHEN gss.likes_count >= 10 THEN 'liked'
        ELSE 'new'
    END as popularity,
    
    -- Featured status
    CASE 
        WHEN gss.featured_until IS NOT NULL AND gss.featured_until > NOW() THEN true
        ELSE false
    END as is_featured,
    
    -- Engagement rate
    CASE 
        WHEN gss.created_at > NOW() - INTERVAL '1 day' THEN
            gss.likes_count + gss.comments_count
        ELSE
            (gss.likes_count + gss.comments_count)::DECIMAL / 
            EXTRACT(EPOCH FROM (NOW() - gss.created_at)) * 86400
    END as engagement_score
    
FROM gem_social_shares gss
LEFT JOIN profiles p ON gss.user_id = p.id
LEFT JOIN enhanced_gemstones eg ON gss.gem_id = eg.id
LEFT JOIN user_gemstones ug ON gss.user_gem_id = ug.id
WHERE gss.is_public = true
ORDER BY 
    CASE WHEN gss.featured_until IS NOT NULL AND gss.featured_until > NOW() THEN 0 ELSE 1 END,
    gss.likes_count DESC,
    gss.created_at DESC;
