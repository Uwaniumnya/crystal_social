-- =====================================================
-- CRYSTAL SOCIAL - PETS SYSTEM VIEWS
-- =====================================================
-- Optimized views for pets system functionality
-- =====================================================

-- =====================================================
-- MAIN PETS VIEW WITH ENRICHED DATA
-- =====================================================

CREATE OR REPLACE VIEW pets_enriched AS
SELECT 
    up.*,
    -- Template information
    pt.display_name as pet_type_name,
    pt.description as pet_type_description,
    pt.base_asset_path,
    pt.icon_asset_path,
    
    -- Current accessory information
    pa.name as accessory_name,
    pa.description as accessory_description,
    pa.category as accessory_category,
    pa.rarity as accessory_rarity,
    
    -- Calculated status
    CASE 
        WHEN up.health + up.happiness + up.energy > 240 THEN 'excellent'
        WHEN up.health + up.happiness + up.energy > 180 THEN 'good'
        WHEN up.health + up.happiness + up.energy > 120 THEN 'fair'
        ELSE 'poor'
    END as overall_status,
    
    -- Care needs assessment
    CASE 
        WHEN up.hunger > 70 THEN 4  -- Very hungry
        WHEN up.health < 30 THEN 4  -- Very sick
        WHEN up.energy < 20 THEN 3  -- Very tired
        WHEN up.happiness < 25 THEN 3  -- Very sad
        WHEN up.hunger > 50 OR up.health < 50 OR up.happiness < 50 OR up.energy < 40 THEN 2  -- Needs attention
        WHEN up.hunger > 30 OR up.health < 70 OR up.happiness < 70 OR up.energy < 60 THEN 1  -- Could use care
        ELSE 0  -- Doing well
    END as care_urgency,
    
    -- Time since last activities
    EXTRACT(EPOCH FROM (NOW() - up.last_fed_at)) / 3600 as hours_since_fed,
    EXTRACT(EPOCH FROM (NOW() - up.last_played_at)) / 3600 as hours_since_played,
    EXTRACT(EPOCH FROM (NOW() - up.last_pet_at)) / 3600 as hours_since_petted,
    EXTRACT(EPOCH FROM (NOW() - up.last_active_at)) / 3600 as hours_since_active,
    
    -- Progress to next levels
    CASE 
        WHEN up.experience_points % 100 = 0 THEN 0
        ELSE up.experience_points % 100
    END as xp_to_next_level,
    CASE 
        WHEN up.bond_xp % 50 = 0 THEN 0
        ELSE up.bond_xp % 50
    END as bond_xp_to_next_level,
    
    -- Today's activity stats
    COALESCE(daily_stats.interactions_count, 0) as today_interactions,
    COALESCE(daily_stats.feeding_count, 0) as today_feedings,
    COALESCE(daily_stats.playing_count, 0) as today_play_sessions,
    COALESCE(daily_stats.petting_count, 0) as today_pettings,
    COALESCE(daily_stats.happiness_gained, 0) as today_happiness_gained,
    COALESCE(daily_stats.experience_gained, 0) as today_experience_gained,
    
    -- Social stats
    COALESCE(friendship_stats.friend_count, 0) as friend_count,
    COALESCE(breeding_stats.offspring_count, 0) as offspring_count

FROM user_pets up
LEFT JOIN pet_templates pt ON up.pet_type = pt.pet_type
LEFT JOIN pet_accessories pa ON up.selected_accessory_id = pa.id
LEFT JOIN (
    SELECT 
        user_pet_id,
        interactions_count,
        feeding_count,
        playing_count,
        petting_count,
        happiness_gained,
        experience_gained
    FROM pet_daily_stats 
    WHERE date = CURRENT_DATE
) daily_stats ON up.id = daily_stats.user_pet_id
LEFT JOIN (
    SELECT 
        pet_id,
        COUNT(*) as friend_count
    FROM (
        SELECT pet1_id as pet_id FROM pet_friendships
        UNION ALL
        SELECT pet2_id as pet_id FROM pet_friendships
    ) friends
    GROUP BY pet_id
) friendship_stats ON up.id = friendship_stats.pet_id
LEFT JOIN (
    SELECT 
        parent1_id as pet_id,
        COUNT(*) as offspring_count
    FROM pet_breeding 
    WHERE breeding_status = 'completed'
    GROUP BY parent1_id
    UNION ALL
    SELECT 
        parent2_id as pet_id,
        COUNT(*) as offspring_count
    FROM pet_breeding 
    WHERE breeding_status = 'completed'
    GROUP BY parent2_id
) breeding_stats ON up.id = breeding_stats.pet_id;

-- =====================================================
-- PET CARE DASHBOARD VIEW
-- =====================================================

CREATE OR REPLACE VIEW pet_care_dashboard AS
SELECT 
    up.user_id,
    COUNT(*) as total_pets,
    COUNT(*) FILTER (WHERE care_urgency >= 3) as pets_needing_urgent_care,
    COUNT(*) FILTER (WHERE care_urgency >= 1) as pets_needing_care,
    COUNT(*) FILTER (WHERE overall_status = 'excellent') as excellent_pets,
    COUNT(*) FILTER (WHERE overall_status = 'poor') as struggling_pets,
    
    -- Average stats across all pets
    ROUND(AVG(up.health), 2) as avg_health,
    ROUND(AVG(up.happiness), 2) as avg_happiness,
    ROUND(AVG(up.energy), 2) as avg_energy,
    ROUND(AVG(up.hunger), 2) as avg_hunger,
    
    -- Highest level pet
    MAX(up.level) as highest_level,
    MAX(up.bond_level) as highest_bond_level,
    
    -- Recent activity summary
    SUM(COALESCE(daily_stats.interactions_count, 0)) as total_interactions_today,
    SUM(COALESCE(daily_stats.feeding_count, 0)) as total_feedings_today,
    SUM(COALESCE(daily_stats.playing_count, 0)) as total_play_sessions_today,
    
    -- Pets that haven't been cared for recently
    COUNT(*) FILTER (WHERE up.last_fed_at < NOW() - INTERVAL '12 hours') as pets_not_fed_recently,
    COUNT(*) FILTER (WHERE up.last_played_at < NOW() - INTERVAL '24 hours') as pets_not_played_recently,
    COUNT(*) FILTER (WHERE up.last_active_at < NOW() - INTERVAL '48 hours') as inactive_pets

FROM pets_enriched up
LEFT JOIN pet_daily_stats daily_stats ON up.id = daily_stats.user_pet_id AND daily_stats.date = CURRENT_DATE
GROUP BY up.user_id;

-- =====================================================
-- PET ACTIVITIES SUMMARY VIEW
-- =====================================================

CREATE OR REPLACE VIEW pet_activities_summary AS
SELECT 
    pas.user_id,
    pas.user_pet_id,
    up.pet_name,
    pa.name as activity_name,
    pa.activity_type,
    pa.difficulty_level,
    
    -- Session statistics
    COUNT(*) as total_sessions,
    COUNT(*) FILTER (WHERE pas.session_status = 'completed') as completed_sessions,
    COUNT(*) FILTER (WHERE pas.session_status = 'abandoned') as abandoned_sessions,
    
    -- Performance metrics
    ROUND(AVG(pas.performance_rating), 3) as avg_performance,
    ROUND(AVG(pas.score), 2) as avg_score,
    MAX(pas.score) as best_score,
    
    -- Rewards earned
    SUM(pas.happiness_gained) as total_happiness_earned,
    SUM(pas.experience_gained) as total_experience_earned,
    SUM(pas.bond_xp_gained) as total_bond_xp_earned,
    
    -- Recent activity
    MAX(pas.started_at) as last_played,
    COUNT(*) FILTER (WHERE pas.started_at > NOW() - INTERVAL '7 days') as sessions_this_week,
    COUNT(*) FILTER (WHERE pas.started_at > NOW() - INTERVAL '1 day') as sessions_today

FROM pet_activity_sessions pas
JOIN user_pets up ON pas.user_pet_id = up.id
JOIN pet_activities pa ON pas.activity_id = pa.id
GROUP BY pas.user_id, pas.user_pet_id, up.pet_name, pas.activity_id, pa.name, pa.activity_type, pa.difficulty_level
ORDER BY pas.user_id, up.pet_name, pa.name;

-- =====================================================
-- PET FEEDING ANALYSIS VIEW
-- =====================================================

CREATE OR REPLACE VIEW pet_feeding_analysis AS
SELECT 
    pfh.user_id,
    pfh.user_pet_id,
    up.pet_name,
    up.pet_type,
    pf.name as food_name,
    pf.category as food_category,
    pf.rarity as food_rarity,
    
    -- Feeding statistics
    COUNT(*) as times_fed,
    ROUND(AVG(pfh.effectiveness_rating), 2) as avg_effectiveness,
    
    -- Pet reaction distribution
    COUNT(*) FILTER (WHERE pfh.pet_reaction = 'loved') as loved_count,
    COUNT(*) FILTER (WHERE pfh.pet_reaction = 'liked') as liked_count,
    COUNT(*) FILTER (WHERE pfh.pet_reaction = 'neutral') as neutral_count,
    COUNT(*) FILTER (WHERE pfh.pet_reaction = 'disliked') as disliked_count,
    COUNT(*) FILTER (WHERE pfh.pet_reaction = 'hated') as hated_count,
    
    -- Effect totals
    SUM(pfh.health_change) as total_health_gained,
    SUM(pfh.happiness_change) as total_happiness_gained,
    SUM(pfh.energy_change) as total_energy_gained,
    
    -- Recent feeding
    MAX(pfh.fed_at) as last_fed_this_food,
    COUNT(*) FILTER (WHERE pfh.fed_at > NOW() - INTERVAL '7 days') as times_fed_this_week

FROM pet_feeding_history pfh
JOIN user_pets up ON pfh.user_pet_id = up.id
JOIN pet_foods pf ON pfh.food_id = pf.id
GROUP BY pfh.user_id, pfh.user_pet_id, up.pet_name, up.pet_type, pfh.food_id, pf.name, pf.category, pf.rarity
ORDER BY pfh.user_id, up.pet_name, avg_effectiveness DESC;

-- =====================================================
-- PET ACHIEVEMENTS PROGRESS VIEW
-- =====================================================

CREATE OR REPLACE VIEW pet_achievements_progress AS
SELECT 
    upa.user_id,
    pa.name as achievement_name,
    pa.description as achievement_description,
    pa.category as achievement_category,
    pa.difficulty_level,
    pa.badge_color,
    
    -- Progress information
    upa.current_progress,
    upa.target_progress,
    upa.progress_percentage,
    upa.is_completed,
    upa.completed_at,
    upa.completion_count,
    
    -- Reward information
    pa.reward_experience,
    pa.reward_bond_xp,
    pa.reward_currency,
    pa.reward_items,
    
    -- Pet-specific achievement
    CASE 
        WHEN upa.user_pet_id IS NOT NULL THEN up.pet_name
        ELSE NULL
    END as pet_name,
    
    -- Time tracking
    upa.started_at,
    upa.last_updated_at,
    
    -- Completion rate for repeatable achievements
    CASE 
        WHEN pa.is_repeatable AND upa.completion_count > 0 THEN 
            ROUND(upa.completion_count::DECIMAL / NULLIF(EXTRACT(DAYS FROM (NOW() - upa.started_at)), 0), 2)
        ELSE NULL
    END as completion_rate_per_day

FROM user_pet_achievements upa
JOIN pet_achievements pa ON upa.achievement_id = pa.id
LEFT JOIN user_pets up ON upa.user_pet_id = up.id
ORDER BY upa.user_id, pa.category, pa.difficulty_level, upa.progress_percentage DESC;

-- =====================================================
-- PET SOCIAL NETWORK VIEW
-- =====================================================

CREATE OR REPLACE VIEW pet_social_network AS
SELECT 
    pf.id as friendship_id,
    
    -- Pet 1 information
    up1.id as pet1_id,
    up1.pet_name as pet1_name,
    up1.pet_type as pet1_type,
    up1.user_id as pet1_user_id,
    
    -- Pet 2 information
    up2.id as pet2_id,
    up2.pet_name as pet2_name,
    up2.pet_type as pet2_type,
    up2.user_id as pet2_user_id,
    
    -- Friendship details
    pf.friendship_level,
    pf.friendship_xp,
    pf.compatibility_score,
    pf.friendship_status,
    pf.total_interactions,
    pf.first_meeting_at,
    pf.last_interaction_at,
    
    -- Cross-user friendship indicator
    CASE 
        WHEN up1.user_id != up2.user_id THEN true
        ELSE false
    END as is_cross_user_friendship,
    
    -- Time since last interaction
    EXTRACT(DAYS FROM (NOW() - pf.last_interaction_at)) as days_since_interaction,
    
    -- Friend activity levels
    CASE 
        WHEN pf.last_interaction_at > NOW() - INTERVAL '1 day' THEN 'very_active'
        WHEN pf.last_interaction_at > NOW() - INTERVAL '7 days' THEN 'active'
        WHEN pf.last_interaction_at > NOW() - INTERVAL '30 days' THEN 'somewhat_active'
        ELSE 'inactive'
    END as friendship_activity_level

FROM pet_friendships pf
JOIN user_pets up1 ON pf.pet1_id = up1.id
JOIN user_pets up2 ON pf.pet2_id = up2.id
ORDER BY pf.friendship_level DESC, pf.last_interaction_at DESC;

-- =====================================================
-- PET BREEDING OVERVIEW VIEW
-- =====================================================

CREATE OR REPLACE VIEW pet_breeding_overview AS
SELECT 
    pb.id as breeding_id,
    pb.user_id,
    
    -- Parent information
    up1.pet_name as parent1_name,
    up1.pet_type as parent1_type,
    up1.rarity as parent1_rarity,
    up1.level as parent1_level,
    
    up2.pet_name as parent2_name,
    up2.pet_type as parent2_type,
    up2.rarity as parent2_rarity,
    up2.level as parent2_level,
    
    -- Breeding process
    pb.breeding_method,
    pb.breeding_status,
    pb.breeding_started_at,
    pb.breeding_completed_at,
    pb.incubation_time_minutes,
    
    -- Time calculations
    CASE 
        WHEN pb.breeding_status = 'in_progress' THEN
            GREATEST(0, EXTRACT(EPOCH FROM (pb.breeding_completed_at - NOW())) / 60)
        ELSE 0
    END as minutes_remaining,
    
    CASE 
        WHEN pb.breeding_status = 'completed' THEN
            EXTRACT(EPOCH FROM (pb.breeding_completed_at - pb.breeding_started_at)) / 60
        ELSE NULL
    END as actual_duration_minutes,
    
    -- Offspring information (if completed)
    CASE 
        WHEN pb.breeding_status = 'completed' THEN up3.pet_name
        ELSE NULL
    END as offspring_name,
    
    CASE 
        WHEN pb.breeding_status = 'completed' THEN up3.pet_type
        ELSE NULL
    END as offspring_type,
    
    CASE 
        WHEN pb.breeding_status = 'completed' THEN up3.rarity
        ELSE NULL
    END as offspring_rarity,
    
    pb.offspring_traits,
    pb.genetic_combination,
    
    -- Special breeding indicators
    pb.is_special_breeding,
    pb.breeding_bonuses

FROM pet_breeding pb
JOIN user_pets up1 ON pb.parent1_id = up1.id
JOIN user_pets up2 ON pb.parent2_id = up2.id
LEFT JOIN user_pets up3 ON pb.offspring_pet_id = up3.id
ORDER BY pb.breeding_started_at DESC;

-- =====================================================
-- PET HEALTH TRENDS VIEW
-- =====================================================

CREATE OR REPLACE VIEW pet_health_trends AS
SELECT 
    pds.user_pet_id,
    up.pet_name,
    up.pet_type,
    up.user_id,
    
    -- Weekly averages
    DATE_TRUNC('week', pds.date) as week_start,
    COUNT(*) as days_recorded,
    
    ROUND(AVG(pds.end_happiness), 2) as avg_happiness,
    ROUND(AVG(pds.end_energy), 2) as avg_energy,
    ROUND(AVG(pds.end_health), 2) as avg_health,
    
    -- Activity totals for the week
    SUM(pds.interactions_count) as weekly_interactions,
    SUM(pds.feeding_count) as weekly_feedings,
    SUM(pds.playing_count) as weekly_play_sessions,
    SUM(pds.petting_count) as weekly_pettings,
    
    -- Care time totals
    SUM(pds.total_active_minutes) as weekly_active_minutes,
    SUM(pds.game_time_minutes) as weekly_game_minutes,
    SUM(pds.care_time_minutes) as weekly_care_minutes,
    
    -- Progress totals
    SUM(pds.happiness_gained) as weekly_happiness_gained,
    SUM(pds.experience_gained) as weekly_experience_gained,
    SUM(pds.bond_xp_gained) as weekly_bond_xp_gained,
    SUM(pds.achievements_unlocked) as weekly_achievements,
    
    -- Trend indicators
    CASE 
        WHEN AVG(pds.end_happiness) > LAG(AVG(pds.end_happiness)) OVER (PARTITION BY pds.user_pet_id ORDER BY DATE_TRUNC('week', pds.date)) THEN 'improving'
        WHEN AVG(pds.end_happiness) < LAG(AVG(pds.end_happiness)) OVER (PARTITION BY pds.user_pet_id ORDER BY DATE_TRUNC('week', pds.date)) THEN 'declining'
        ELSE 'stable'
    END as happiness_trend

FROM pet_daily_stats pds
JOIN user_pets up ON pds.user_pet_id = up.id
WHERE pds.date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY pds.user_pet_id, up.pet_name, up.pet_type, up.user_id, DATE_TRUNC('week', pds.date)
ORDER BY pds.user_pet_id, week_start DESC;

-- =====================================================
-- PET LEADERBOARDS VIEW
-- =====================================================

CREATE OR REPLACE VIEW pet_leaderboards AS
SELECT 
    'highest_level' as leaderboard_type,
    up.id as pet_id,
    up.pet_name,
    up.pet_type,
    up.user_id,
    up.level::DECIMAL as score,
    up.experience_points as secondary_score,
    ROW_NUMBER() OVER (ORDER BY up.level DESC, up.experience_points DESC) as rank
FROM user_pets up
WHERE up.level > 1

UNION ALL

SELECT 
    'highest_bond',
    up.id,
    up.pet_name,
    up.pet_type,
    up.user_id,
    up.bond_level::DECIMAL,
    up.bond_xp,
    ROW_NUMBER() OVER (ORDER BY up.bond_level DESC, up.bond_xp DESC)
FROM user_pets up
WHERE up.bond_level > 1

UNION ALL

SELECT 
    'most_interactions',
    up.id,
    up.pet_name,
    up.pet_type,
    up.user_id,
    up.total_interactions::DECIMAL,
    NULL,
    ROW_NUMBER() OVER (ORDER BY up.total_interactions DESC)
FROM user_pets up
WHERE up.total_interactions > 0

UNION ALL

SELECT 
    'best_overall_health',
    up.id,
    up.pet_name,
    up.pet_type,
    up.user_id,
    ROUND((up.health + up.happiness + up.energy) / 3, 2),
    NULL,
    ROW_NUMBER() OVER (ORDER BY (up.health + up.happiness + up.energy) DESC)
FROM user_pets up
WHERE (up.health + up.happiness + up.energy) > 150

ORDER BY leaderboard_type, rank;

-- =====================================================
-- GRANT VIEW PERMISSIONS
-- =====================================================

GRANT SELECT ON pets_enriched TO authenticated;
GRANT SELECT ON pet_care_dashboard TO authenticated;
GRANT SELECT ON pet_activities_summary TO authenticated;
GRANT SELECT ON pet_feeding_analysis TO authenticated;
GRANT SELECT ON pet_achievements_progress TO authenticated;
GRANT SELECT ON pet_social_network TO authenticated;
GRANT SELECT ON pet_breeding_overview TO authenticated;
GRANT SELECT ON pet_health_trends TO authenticated;
GRANT SELECT ON pet_leaderboards TO authenticated;
