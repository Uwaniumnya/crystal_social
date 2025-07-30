-- =====================================================
-- CRYSTAL SOCIAL - GARDEN SYSTEM VIEWS
-- =====================================================
-- Optimized views for garden system queries
-- =====================================================

-- View for garden overview with summary statistics
CREATE OR REPLACE VIEW garden_overview AS
SELECT 
    g.id,
    g.user_id,
    g.name,
    g.level,
    g.experience,
    g.coins,
    g.gems,
    g.theme,
    g.season,
    g.background_image,
    g.max_flowers,
    g.created_at,
    g.updated_at,
    
    -- Flower statistics
    COALESCE(fs.total_flowers, 0) as total_flowers,
    COALESCE(fs.flowers_by_stage, '{}'::jsonb) as flowers_by_stage,
    COALESCE(fs.avg_health, 0) as avg_flower_health,
    COALESCE(fs.avg_happiness, 0) as avg_flower_happiness,
    COALESCE(fs.flowers_needing_water, 0) as flowers_needing_water,
    COALESCE(fs.flowers_needing_fertilizer, 0) as flowers_needing_fertilizer,
    COALESCE(fs.wilting_flowers, 0) as wilting_flowers,
    
    -- Inventory summary
    COALESCE(inv.inventory_summary, '{}'::jsonb) as inventory_summary,
    
    -- Active visitors
    COALESCE(vis.active_visitors, 0) as active_visitors,
    
    -- Achievement progress
    COALESCE(ach.total_achievements, 0) as total_achievements,
    COALESCE(ach.completed_achievements, 0) as completed_achievements,
    COALESCE(ach.achievement_completion_rate, 0) as achievement_completion_rate,
    
    -- Quest progress
    COALESCE(quest.todays_quests, 0) as todays_quests,
    COALESCE(quest.completed_todays_quests, 0) as completed_todays_quests,
    
    -- Weather info
    weather.current_weather,
    weather.weather_ends_at
    
FROM gardens g

LEFT JOIN (
    SELECT 
        garden_id,
        COUNT(*) as total_flowers,
        jsonb_object_agg(growth_stage, stage_count) as flowers_by_stage,
        ROUND(AVG(health), 1) as avg_health,
        ROUND(AVG(happiness), 1) as avg_happiness,
        SUM(CASE WHEN last_watered_at IS NULL OR NOW() - last_watered_at > INTERVAL '4 hours' THEN 1 ELSE 0 END) as flowers_needing_water,
        SUM(CASE WHEN last_fertilized_at IS NULL OR NOW() - last_fertilized_at > INTERVAL '12 hours' THEN 1 ELSE 0 END) as flowers_needing_fertilizer,
        SUM(CASE WHEN is_wilting THEN 1 ELSE 0 END) as wilting_flowers
    FROM (
        SELECT 
            garden_id,
            growth_stage,
            COUNT(*) as stage_count,
            health,
            happiness,
            last_watered_at,
            last_fertilized_at,
            is_wilting
        FROM flowers 
        WHERE NOT is_dead
        GROUP BY garden_id, growth_stage, health, happiness, last_watered_at, last_fertilized_at, is_wilting
    ) flower_stats
    GROUP BY garden_id
) fs ON g.id = fs.garden_id

LEFT JOIN (
    SELECT 
        garden_id,
        jsonb_object_agg(
            item_type,
            jsonb_object_agg(item_name, quantity)
        ) as inventory_summary
    FROM garden_inventory
    WHERE quantity > 0
    GROUP BY garden_id
) inv ON g.id = inv.garden_id

LEFT JOIN (
    SELECT 
        garden_id,
        COUNT(*) as active_visitors
    FROM garden_visitor_instances
    WHERE will_leave_at > NOW()
    GROUP BY garden_id
) vis ON g.id = vis.garden_id

LEFT JOIN (
    SELECT 
        garden_id,
        COUNT(*) as total_achievements,
        SUM(CASE WHEN is_completed THEN 1 ELSE 0 END) as completed_achievements,
        ROUND(
            (SUM(CASE WHEN is_completed THEN 1 ELSE 0 END)::DECIMAL / COUNT(*)) * 100, 
            1
        ) as achievement_completion_rate
    FROM garden_achievements
    GROUP BY garden_id
) ach ON g.id = ach.garden_id

LEFT JOIN (
    SELECT 
        garden_id,
        COUNT(*) as todays_quests,
        SUM(CASE WHEN is_completed THEN 1 ELSE 0 END) as completed_todays_quests
    FROM garden_daily_quests
    WHERE quest_date = CURRENT_DATE
    GROUP BY garden_id
) quest ON g.id = quest.garden_id

LEFT JOIN (
    SELECT DISTINCT ON (garden_id)
        garden_id,
        weather_type as current_weather,
        end_time as weather_ends_at
    FROM garden_weather_events
    WHERE q.is_active = true
    ORDER BY garden_id, created_at DESC
) weather ON g.id = weather.garden_id;

-- View for flower details with species information
CREATE OR REPLACE VIEW flower_details AS
SELECT 
    f.id,
    f.garden_id,
    f.species_id,
    f.x_position,
    f.y_position,
    f.growth_stage,
    f.health,
    f.happiness,
    f.current_size,
    f.is_wilting,
    f.is_dead,
    f.has_bloomed,
    f.has_special_effect,
    f.rarity,
    f.total_waterings,
    f.total_fertilizations,
    f.growth_events,
    f.last_watered_at,
    f.last_fertilized_at,
    f.first_bloom_at,
    f.created_at,
    f.updated_at,
    
    -- Species information
    fs.name as species_name,
    fs.category as species_category,
    fs.description as species_description,
    fs.growth_time_hours,
    fs.bloom_chance,
    fs.water_frequency_hours,
    fs.fertilizer_frequency_hours,
    fs.base_health,
    fs.base_happiness,
    fs.base_experience,
    fs.base_coins,
    fs.bloom_experience,
    fs.bloom_coins,
    fs.seasonal_preference,
    fs.special_effects,
    fs.image_url as species_image,
    
    -- Garden information
    g.user_id as garden_owner,
    g.name as garden_name,
    g.level as garden_level,
    g.season as garden_season,
    
    -- Care status
    CASE 
        WHEN f.last_watered_at IS NULL THEN 'never_watered'
        WHEN NOW() - f.last_watered_at > INTERVAL '8 hours' THEN 'needs_water'
        WHEN NOW() - f.last_watered_at > INTERVAL '4 hours' THEN 'thirsty'
        ELSE 'hydrated'
    END as water_status,
    
    CASE 
        WHEN f.last_fertilized_at IS NULL THEN 'never_fertilized'
        WHEN NOW() - f.last_fertilized_at > INTERVAL '24 hours' THEN 'needs_fertilizer'
        WHEN NOW() - f.last_fertilized_at > INTERVAL '12 hours' THEN 'could_use_fertilizer'
        ELSE 'well_fed'
    END as fertilizer_status,
    
    -- Growth prediction
    CASE 
        WHEN f.growth_stage = 'bloomed' THEN 'fully_grown'
        WHEN f.health < 30 THEN 'unhealthy'
        WHEN f.is_wilting THEN 'wilting'
        WHEN f.last_watered_at IS NULL OR NOW() - f.last_watered_at > INTERVAL '2 hours' THEN 'needs_care'
        ELSE 'growing_well'
    END as growth_status
    
FROM flowers f
LEFT JOIN flower_species fs ON f.species_id = fs.id
LEFT JOIN gardens g ON f.garden_id = g.id;

-- View for active garden visitors with details
CREATE OR REPLACE VIEW active_garden_visitors AS
SELECT 
    gvi.id as instance_id,
    gvi.garden_id,
    gvi.visitor_id,
    gvi.arrived_at,
    gvi.will_leave_at,
    gvi.x_position,
    gvi.y_position,
    gvi.has_given_reward,
    gvi.reward_claimed_at,
    gvi.times_interacted,
    
    -- Visitor details
    gv.name as visitor_name,
    gv.visitor_type,
    gv.description as visitor_description,
    gv.rarity as visitor_rarity,
    gv.image_url as visitor_image,
    gv.animation_type,
    gv.stay_duration_minutes,
    gv.visit_chance,
    gv.required_flowers,
    gv.min_garden_level,
    gv.seasonal_availability,
    gv.reward_type,
    gv.reward_amount,
    gv.reward_items,
    gv.special_abilities,
    
    -- Garden info
    g.user_id as garden_owner,
    g.name as garden_name,
    g.level as garden_level,
    
    -- Time remaining
    EXTRACT(EPOCH FROM (gvi.will_leave_at - NOW())) / 60 as minutes_until_leaves,
    
    -- Status
    CASE 
        WHEN gvi.will_leave_at <= NOW() THEN 'departed'
        WHEN gvi.has_given_reward THEN 'rewarded'
        WHEN gvi.times_interacted > 0 THEN 'interacted'
        ELSE 'waiting'
    END as status
    
FROM garden_visitor_instances gvi
LEFT JOIN garden_visitors gv ON gvi.visitor_id = gv.id
LEFT JOIN gardens g ON gvi.garden_id = g.id
WHERE gvi.will_leave_at > NOW();

-- View for garden shop with availability
CREATE OR REPLACE VIEW garden_shop_available AS
SELECT 
    gsi.id,
    gsi.item_name,
    gsi.display_name,
    gsi.description,
    gsi.category,
    gsi.price_coins,
    gsi.price_gems,
    gsi.image_url,
    gsi.rarity,
    gsi.stock_quantity,
    gsi.min_level_required,
    gsi.seasonal_availability,
    gsi.special_properties,
    gsi.total_sold,
    gsi.created_at,
    
    -- Availability status
    CASE 
        WHEN NOT gsi.is_available THEN 'unavailable'
        WHEN gsi.stock_quantity IS NOT NULL AND gsi.stock_quantity <= 0 THEN 'out_of_stock'
        WHEN gsi.stock_quantity IS NOT NULL AND gsi.stock_quantity <= 5 THEN 'low_stock'
        ELSE 'in_stock'
    END as availability_status,
    
    -- Popularity
    CASE 
        WHEN gsi.total_sold >= 1000 THEN 'very_popular'
        WHEN gsi.total_sold >= 100 THEN 'popular'
        WHEN gsi.total_sold >= 10 THEN 'common'
        ELSE 'new'
    END as popularity
    
FROM garden_shop_items gsi
WHERE gsi.is_available = true
ORDER BY 
    gsi.category,
    gsi.rarity DESC,
    gsi.price_coins ASC;

-- View for garden achievements with progress
CREATE OR REPLACE VIEW garden_achievement_progress AS
SELECT 
    ga.id,
    ga.garden_id,
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
    ga.created_at,
    ga.updated_at,
    
    -- Garden info
    g.user_id as garden_owner,
    g.name as garden_name,
    g.level as garden_level,
    
    -- Progress status
    CASE 
        WHEN ga.is_completed THEN 'completed'
        WHEN ga.progress_percentage >= 80 THEN 'almost_complete'
        WHEN ga.progress_percentage >= 50 THEN 'halfway'
        WHEN ga.progress_percentage >= 25 THEN 'started'
        ELSE 'not_started'
    END as progress_status,
    
    -- Difficulty
    CASE 
        WHEN ga.target_value >= 1000 THEN 'legendary'
        WHEN ga.target_value >= 100 THEN 'epic'
        WHEN ga.target_value >= 50 THEN 'hard'
        WHEN ga.target_value >= 10 THEN 'medium'
        ELSE 'easy'
    END as difficulty
    
FROM garden_achievements ga
LEFT JOIN gardens g ON ga.garden_id = g.id
ORDER BY ga.is_completed, ga.progress_percentage DESC;

-- View for daily quest progress
CREATE OR REPLACE VIEW garden_daily_quest_progress AS
SELECT 
    gdq.id,
    gdq.garden_id,
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
    gdq.created_at,
    gdq.updated_at,
    
    -- Garden info
    g.user_id as garden_owner,
    g.name as garden_name,
    g.level as garden_level,
    
    -- Time remaining for quest
    CASE 
        WHEN gdq.quest_date < CURRENT_DATE THEN 0
        ELSE EXTRACT(EPOCH FROM (CURRENT_DATE + INTERVAL '1 day' - NOW())) / 3600
    END as hours_remaining,
    
    -- Quest status
    CASE 
        WHEN gdq.quest_date < CURRENT_DATE THEN 'expired'
        WHEN gdq.is_completed THEN 'completed'
        WHEN gdq.progress_percentage >= 80 THEN 'almost_complete'
        WHEN gdq.progress_percentage >= 50 THEN 'halfway'
        ELSE 'in_progress'
    END as status
    
FROM garden_daily_quests gdq
LEFT JOIN gardens g ON gdq.garden_id = g.id
WHERE gdq.quest_date >= CURRENT_DATE - INTERVAL '1 day'
ORDER BY gdq.quest_date DESC, gdq.is_completed, gdq.progress_percentage DESC;

-- View for garden analytics summary
CREATE OR REPLACE VIEW garden_analytics_summary AS
SELECT 
    ga.garden_id,
    ga.date,
    ga.flowers_planted,
    ga.flowers_watered,
    ga.flowers_fertilized,
    ga.flowers_bloomed,
    ga.visitors_received,
    ga.coins_earned,
    ga.coins_spent,
    ga.gems_spent,
    ga.experience_gained,
    ga.achievements_unlocked,
    ga.quests_completed,
    
    -- Garden info
    g.user_id as garden_owner,
    g.name as garden_name,
    g.level as garden_level,
    
    -- Calculated metrics
    CASE 
        WHEN ga.flowers_planted > 0 THEN ROUND((ga.flowers_bloomed::DECIMAL / ga.flowers_planted) * 100, 1)
        ELSE 0
    END as bloom_success_rate,
    
    CASE 
        WHEN ga.coins_spent > 0 THEN ROUND((ga.coins_earned::DECIMAL / ga.coins_spent) * 100, 1)
        ELSE ga.coins_earned
    END as coin_efficiency,
    
    ga.flowers_watered + ga.flowers_fertilized as total_care_actions,
    
    -- Activity level
    CASE 
        WHEN (ga.flowers_planted + ga.flowers_watered + ga.flowers_fertilized) >= 20 THEN 'very_active'
        WHEN (ga.flowers_planted + ga.flowers_watered + ga.flowers_fertilized) >= 10 THEN 'active'
        WHEN (ga.flowers_planted + ga.flowers_watered + ga.flowers_fertilized) >= 5 THEN 'moderate'
        WHEN (ga.flowers_planted + ga.flowers_watered + ga.flowers_fertilized) > 0 THEN 'light'
        ELSE 'inactive'
    END as activity_level
    
FROM garden_analytics ga
LEFT JOIN gardens g ON ga.garden_id = g.id
ORDER BY ga.date DESC;
