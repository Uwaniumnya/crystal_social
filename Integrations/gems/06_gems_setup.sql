-- =====================================================
-- CRYSTAL SOCIAL - GEMS SYSTEM SETUP
-- =====================================================
-- Initial data setup and configuration for gems system
-- =====================================================

-- Insert initial gem discovery methods
INSERT INTO gem_discovery_methods (
    method_name, display_name, description, discovery_chance, rarity_weights,
    cooldown_minutes, required_level, cost_coins, cost_gems, is_active
) VALUES 
(
    'daily_login', 'Daily Login Bonus', 'Receive a gem for logging in daily', 0.8,
    '{"common": 70, "uncommon": 20, "rare": 8, "epic": 2, "legendary": 0, "mythic": 0}'::jsonb,
    1440, 1, 0, 0, true
),
(
    'random_discovery', 'Random Discovery', 'Find gems through exploration', 0.3,
    '{"common": 50, "uncommon": 30, "rare": 15, "epic": 4, "legendary": 1, "mythic": 0}'::jsonb,
    60, 1, 0, 0, true
),
(
    'premium_discovery', 'Premium Discovery', 'Enhanced discovery with gems', 0.6,
    '{"common": 30, "uncommon": 35, "rare": 25, "epic": 8, "legendary": 2, "mythic": 0}'::jsonb,
    30, 5, 0, 10, true
),
(
    'legendary_hunt', 'Legendary Hunt', 'Rare chance for legendary gems', 0.1,
    '{"common": 0, "uncommon": 10, "rare": 40, "epic": 35, "legendary": 14, "mythic": 1}'::jsonb,
    180, 10, 1000, 50, true
),
(
    'achievement_reward', 'Achievement Reward', 'Gems earned from achievements', 1.0,
    '{"common": 40, "uncommon": 30, "rare": 20, "epic": 8, "legendary": 2, "mythic": 0}'::jsonb,
    0, 1, 0, 0, true
),
(
    'quest_completion', 'Quest Completion', 'Gems earned from completing quests', 0.9,
    '{"common": 60, "uncommon": 25, "rare": 12, "epic": 3, "legendary": 0, "mythic": 0}'::jsonb,
    0, 1, 0, 0, true
),
(
    'special_event', 'Special Event', 'Limited-time event discoveries', 0.4,
    '{"common": 20, "uncommon": 30, "rare": 30, "epic": 15, "legendary": 4, "mythic": 1}'::jsonb,
    60, 1, 0, 0, false
),
(
    'social_discovery', 'Social Discovery', 'Find gems through social activities', 0.25,
    '{"common": 55, "uncommon": 25, "rare": 15, "epic": 4, "legendary": 1, "mythic": 0}'::jsonb,
    120, 3, 0, 0, true
);

-- Insert sample gemstones
INSERT INTO enhanced_gemstones (
    name, description, image_path, rarity, element, power, value, source, category,
    tags, sparkle_intensity, seasonal_availability, special_effects, animation_type, discovery_weight
) VALUES 
-- Common Fire gems
(
    'Ruby Shard', 'A small fragment of a brilliant ruby with inner fire', 
    'assets/gems/ruby_shard.png', 'common', 'fire', 25, 100, 'mining',
    'precious', '["fire", "red", "common"]'::jsonb, 1.2,
    '["spring", "summer", "fall", "winter"]'::jsonb, '["heat_resistance"]'::jsonb, 'glow', 1.0
),
(
    'Flame Opal', 'An opal that burns with eternal flame',
    'assets/gems/flame_opal.png', 'common', 'fire', 30, 120, 'volcanic',
    'precious', '["fire", "orange", "opal"]'::jsonb, 1.5,
    '["summer", "fall"]'::jsonb, '["flame_aura"]'::jsonb, 'glow', 0.9
),
(
    'Ember Crystal', 'A crystal that glows like cooling embers',
    'assets/gems/ember_crystal.png', 'common', 'fire', 20, 80, 'forge',
    'crystal', '["fire", "amber", "warm"]'::jsonb, 1.0,
    '["fall", "winter"]'::jsonb, '["warmth"]'::jsonb, 'pulse', 1.1
),

-- Common Water gems
(
    'Aquamarine Drop', 'A clear blue gem reminiscent of ocean depths',
    'assets/gems/aquamarine_drop.png', 'common', 'water', 22, 90, 'ocean',
    'precious', '["water", "blue", "clear"]'::jsonb, 1.1,
    '["spring", "summer"]'::jsonb, '["water_breathing"]'::jsonb, 'float', 1.0
),
(
    'Sea Glass', 'Smooth glass polished by endless waves',
    'assets/gems/sea_glass.png', 'common', 'water', 18, 70, 'beach',
    'natural', '["water", "green", "smooth"]'::jsonb, 0.8,
    '["spring", "summer", "fall"]'::jsonb, '["calm_waters"]'::jsonb, 'float', 1.2
),

-- Common Earth gems
(
    'Moss Agate', 'An agate with beautiful moss-like inclusions',
    'assets/gems/moss_agate.png', 'common', 'earth', 28, 110, 'forest',
    'agate', '["earth", "green", "nature"]'::jsonb, 0.9,
    '["spring", "summer"]'::jsonb, '["plant_growth"]'::jsonb, 'bounce', 1.0
),
(
    'Smooth Pebble', 'A perfectly smooth stone worn by time',
    'assets/gems/smooth_pebble.png', 'common', 'earth', 15, 50, 'river',
    'natural', '["earth", "gray", "simple"]'::jsonb, 0.5,
    '["spring", "summer", "fall", "winter"]'::jsonb, '["stability"]'::jsonb, 'bounce', 1.5
),

-- Uncommon gems
(
    'Sapphire Star', 'A sapphire with a perfect six-pointed star',
    'assets/gems/sapphire_star.png', 'uncommon', 'water', 45, 250, 'mountain',
    'precious', '["water", "blue", "star", "sapphire"]'::jsonb, 1.8,
    '["fall", "winter"]'::jsonb, '["star_navigation", "wisdom"]'::jsonb, 'shimmer', 0.7
),
(
    'Emerald Heart', 'A heart-shaped emerald with perfect clarity',
    'assets/gems/emerald_heart.png', 'uncommon', 'earth', 50, 300, 'mine',
    'precious', '["earth", "green", "heart", "emerald"]'::jsonb, 1.6,
    '["spring", "summer"]'::jsonb, '["healing", "love"]'::jsonb, 'pulse', 0.6
),
(
    'Thunder Topaz', 'A topaz that crackles with electric energy',
    'assets/gems/thunder_topaz.png', 'uncommon', 'lightning', 55, 280, 'storm',
    'precious', '["lightning", "yellow", "electric"]'::jsonb, 2.0,
    '["spring", "summer"]'::jsonb, '["lightning_bolt", "speed"]'::jsonb, 'sparkle', 0.5
),
(
    'Moonstone Crescent', 'A crescent-shaped moonstone with ethereal glow',
    'assets/gems/moonstone_crescent.png', 'uncommon', 'light', 40, 220, 'moon',
    'precious', '["light", "white", "moon", "crescent"]'::jsonb, 1.4,
    '["fall", "winter"]'::jsonb, '["moon_blessing", "night_vision"]'::jsonb, 'shimmer', 0.8
),

-- Rare gems
(
    'Phoenix Feather Ruby', 'A ruby that contains the essence of a phoenix feather',
    'assets/gems/phoenix_feather_ruby.png', 'rare', 'fire', 85, 600, 'phoenix',
    'legendary', '["fire", "phoenix", "red", "feather"]'::jsonb, 2.5,
    '["summer", "fall"]'::jsonb, '["rebirth", "fire_immunity", "healing"]'::jsonb, 'glow', 0.3
),
(
    'Kraken Pearl', 'A massive pearl from the depths of the ocean',
    'assets/gems/kraken_pearl.png', 'rare', 'water', 80, 650, 'deep_sea',
    'pearl', '["water", "pearl", "white", "kraken"]'::jsonb, 1.9,
    '["winter"]'::jsonb, '["tidal_wave", "sea_command", "pressure_resistance"]'::jsonb, 'float', 0.2
),
(
    'Dragon Scale Emerald', 'An emerald formed from an ancient dragon scale',
    'assets/gems/dragon_scale_emerald.png', 'rare', 'earth', 90, 700, 'dragon',
    'legendary', '["earth", "dragon", "green", "scale"]'::jsonb, 2.2,
    '["spring"]'::jsonb, '["dragon_strength", "earth_control", "protection"]'::jsonb, 'bounce', 0.25
),
(
    'Storm Eye Sapphire', 'A sapphire that holds the calm center of a storm',
    'assets/gems/storm_eye_sapphire.png', 'rare', 'air', 75, 580, 'hurricane',
    'precious', '["air", "storm", "blue", "eye"]'::jsonb, 2.1,
    '["spring", "summer"]'::jsonb, '["wind_control", "storm_immunity", "flight"]'::jsonb, 'shimmer', 0.3
),

-- Epic gems
(
    'Celestial Diamond', 'A diamond that contains the light of stars',
    'assets/gems/celestial_diamond.png', 'epic', 'light', 150, 1500, 'cosmos',
    'divine', '["light", "diamond", "celestial", "stars"]'::jsonb, 2.5,
    '["winter"]'::jsonb, '["starlight", "divine_protection", "purification", "time_dilation"]'::jsonb, 'sparkle', 0.1
),
(
    'Void Obsidian', 'An obsidian that absorbs all light and energy',
    'assets/gems/void_obsidian.png', 'epic', 'dark', 140, 1400, 'void',
    'divine', '["dark", "obsidian", "void", "black"]'::jsonb, 0.1,
    '["winter"]'::jsonb, '["void_step", "energy_absorption", "shadow_mastery", "invisibility"]'::jsonb, 'pulse', 0.08
),
(
    'Temporal Quartz', 'A quartz crystal that exists outside of time',
    'assets/gems/temporal_quartz.png', 'epic', 'cosmic', 160, 1600, 'time_rift',
    'cosmic', '["cosmic", "quartz", "temporal", "clear"]'::jsonb, 2.8,
    '["spring", "summer", "fall", "winter"]'::jsonb, '["time_manipulation", "precognition", "temporal_immunity"]'::jsonb, 'rainbow', 0.05
),

-- Legendary gems
(
    'Heart of the Universe', 'The very essence of creation crystallized',
    'assets/gems/heart_of_universe.png', 'legendary', 'cosmic', 300, 5000, 'creation',
    'artifact', '["cosmic", "universe", "heart", "rainbow"]'::jsonb, 2.9,
    '["spring", "summer", "fall", "winter"]'::jsonb, 
    '["reality_manipulation", "omniscience", "infinite_power", "creation", "destruction"]'::jsonb, 'rainbow', 0.01
),
(
    'Soul of Eternity', 'A gem containing the collective memory of all souls',
    'assets/gems/soul_of_eternity.png', 'legendary', 'light', 280, 4500, 'afterlife',
    'artifact', '["light", "soul", "eternity", "golden"]'::jsonb, 2.7,
    '["spring", "summer", "fall", "winter"]'::jsonb,
    '["soul_sight", "resurrection", "eternal_life", "memory_access", "spirit_communication"]'::jsonb, 'sparkle', 0.008
),

-- Mythic gems (ultra rare)
(
    'Genesis Stone', 'The first gem ever created, containing infinite potential',
    'assets/gems/genesis_stone.png', 'mythic', 'cosmic', 500, 10000, 'beginning',
    'primordial', '["cosmic", "genesis", "creation", "infinite"]'::jsonb, 3.0,
    '["spring", "summer", "fall", "winter"]'::jsonb,
    '["universe_creation", "absolute_power", "omnipotence", "reality_rewrite", "dimensional_travel"]'::jsonb, 'rainbow', 0.001
);

-- Create helper function to generate user collection stats
CREATE OR REPLACE FUNCTION initialize_gem_system_for_user(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Create initial collection stats
    INSERT INTO gem_collection_stats (user_id) 
    VALUES (p_user_id)
    ON CONFLICT (user_id) DO NOTHING;
    
    -- The triggers will automatically create achievements and quests
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to give starter gems to new users
CREATE OR REPLACE FUNCTION give_starter_gems(p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_starter_gems UUID[];
    v_gem_id UUID;
    v_results JSONB := '[]'::jsonb;
    v_unlock_result JSONB;
BEGIN
    -- Select 3 random common gems as starter gems
    SELECT ARRAY_AGG(id) INTO v_starter_gems
    FROM (
        SELECT id FROM enhanced_gemstones 
        WHERE rarity = 'common' AND is_active = true
        ORDER BY random()
        LIMIT 3
    ) starter;
    
    -- Unlock each starter gem
    FOREACH v_gem_id IN ARRAY v_starter_gems
    LOOP
        v_unlock_result := unlock_gem(p_user_id, v_gem_id, 'starter_pack', '{"is_starter": true}'::jsonb);
        v_results := v_results || jsonb_build_array(v_unlock_result);
    END LOOP;
    
    RETURN jsonb_build_object(
        'success', true,
        'starter_gems', v_results,
        'message', 'Welcome to Crystal Social! You received 3 starter gems.'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to reset daily quests
CREATE OR REPLACE FUNCTION reset_gem_daily_quests()
RETURNS INTEGER AS $$
DECLARE
    quest_count INTEGER := 0;
    user_record RECORD;
BEGIN
    -- Remove old quests
    DELETE FROM gem_daily_quests WHERE quest_date < CURRENT_DATE;
    
    -- Create new quests for all active users
    FOR user_record IN 
        SELECT DISTINCT gcs.user_id, COALESCE(p.level, 1) as user_level
        FROM gem_collection_stats gcs
        JOIN profiles p ON gcs.user_id = p.id
        WHERE gcs.updated_at > NOW() - INTERVAL '7 days' -- Active users only
    LOOP
        -- Discover gems quest
        INSERT INTO gem_daily_quests (
            user_id, quest_type, quest_name, description, target_value,
            reward_coins, reward_gems, reward_experience, quest_date
        ) VALUES (
            user_record.user_id, 'discover_gems', 'Daily Discovery',
            'Discover ' || LEAST(user_record.user_level, 3) || ' new gems today',
            LEAST(user_record.user_level, 3), 200 + (user_record.user_level * 20), 
            5 + (user_record.user_level / 2), 50 + (user_record.user_level * 10), CURRENT_DATE
        ) ON CONFLICT (user_id, quest_type, quest_date) DO NOTHING;
        
        -- View gems quest
        INSERT INTO gem_daily_quests (
            user_id, quest_type, quest_name, description, target_value,
            reward_coins, reward_experience, quest_date
        ) VALUES (
            user_record.user_id, 'view_gems', 'Gem Admirer',
            'View ' || (user_record.user_level * 3) || ' gems today',
            user_record.user_level * 3, 100 + (user_record.user_level * 10), 
            25 + (user_record.user_level * 5), CURRENT_DATE
        ) ON CONFLICT (user_id, quest_type, quest_date) DO NOTHING;
        
        -- Enhancement quest (for higher levels)
        IF user_record.user_level >= 5 THEN
            INSERT INTO gem_daily_quests (
                user_id, quest_type, quest_name, description, target_value,
                reward_coins, reward_gems, quest_date
            ) VALUES (
                user_record.user_id, 'enhance_gems', 'Enhancement Master',
                'Successfully enhance ' || CEIL(user_record.user_level / 5.0) || ' gems today',
                CEIL(user_record.user_level / 5.0), 300 + (user_record.user_level * 30), 
                10 + (user_record.user_level / 3), CURRENT_DATE
            ) ON CONFLICT (user_id, quest_type, quest_date) DO NOTHING;
        END IF;
        
        quest_count := quest_count + 1;
    END LOOP;
    
    RETURN quest_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function for seasonal gem events
CREATE OR REPLACE FUNCTION trigger_seasonal_gem_event(
    p_event_name VARCHAR,
    p_duration_hours INTEGER DEFAULT 24,
    p_bonus_rarity_weights JSONB DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    affected_methods INTEGER := 0;
BEGIN
    -- Update discovery methods with seasonal bonuses
    UPDATE gem_discovery_methods 
    SET 
        discovery_chance = discovery_chance * 1.5,
        rarity_weights = COALESCE(p_bonus_rarity_weights, rarity_weights),
        seasonal_bonuses = jsonb_build_object(
            'event_name', p_event_name,
            'started_at', NOW(),
            'ends_at', NOW() + (p_duration_hours || ' hours')::INTERVAL,
            'bonus_active', true
        )
    WHERE is_active = true;
    
    GET DIAGNOSTICS affected_methods = ROW_COUNT;
    
    -- Activate special event method
    UPDATE gem_discovery_methods
    SET is_active = true
    WHERE method_name = 'special_event';
    
    RETURN affected_methods;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to end seasonal events
CREATE OR REPLACE FUNCTION end_seasonal_gem_events()
RETURNS INTEGER AS $$
DECLARE
    affected_methods INTEGER := 0;
BEGIN
    -- Reset discovery methods to normal
    UPDATE gem_discovery_methods 
    SET 
        discovery_chance = discovery_chance / 1.5,
        seasonal_bonuses = '{}'::jsonb
    WHERE seasonal_bonuses->>'bonus_active' = 'true'
    AND (seasonal_bonuses->>'ends_at')::timestamptz <= NOW();
    
    GET DIAGNOSTICS affected_methods = ROW_COUNT;
    
    -- Deactivate special event method
    UPDATE gem_discovery_methods
    SET is_active = false
    WHERE method_name = 'special_event';
    
    RETURN affected_methods;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create performance indexes
CREATE INDEX IF NOT EXISTS idx_enhanced_gemstones_rarity_active 
ON enhanced_gemstones(rarity, is_active) WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_user_gemstones_user_unlocked 
ON user_gemstones(user_id, unlocked_at DESC);

CREATE INDEX IF NOT EXISTS idx_gem_discovery_events_user_recent 
ON gem_discovery_events(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_gem_achievements_user_incomplete 
ON gem_achievements(user_id, is_completed, progress_percentage DESC) WHERE NOT is_completed;

CREATE INDEX IF NOT EXISTS idx_gem_daily_quests_user_date 
ON gem_daily_quests(user_id, quest_date, is_completed);

CREATE INDEX IF NOT EXISTS idx_gem_analytics_date_user 
ON gem_analytics(date DESC, user_id);

CREATE INDEX IF NOT EXISTS idx_gem_trades_active_expires 
ON gem_trades(status, expires_at) WHERE status = 'active';

CREATE INDEX IF NOT EXISTS idx_gem_social_shares_public_recent 
ON gem_social_shares(is_public, created_at DESC) WHERE is_public = true;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION initialize_gem_system_for_user TO authenticated;
GRANT EXECUTE ON FUNCTION give_starter_gems TO authenticated;
GRANT EXECUTE ON FUNCTION reset_gem_daily_quests TO authenticated;
GRANT EXECUTE ON FUNCTION trigger_seasonal_gem_event TO authenticated;
GRANT EXECUTE ON FUNCTION end_seasonal_gem_events TO authenticated;

-- Create notification for successful setup
DO $$
BEGIN
    RAISE NOTICE 'Gem system setup completed successfully!';
    RAISE NOTICE 'Created % gemstones', (SELECT COUNT(*) FROM enhanced_gemstones);
    RAISE NOTICE 'Created % discovery methods', (SELECT COUNT(*) FROM gem_discovery_methods);
    RAISE NOTICE 'Rarity distribution:';
    RAISE NOTICE '  Common: %', (SELECT COUNT(*) FROM enhanced_gemstones WHERE rarity = 'common');
    RAISE NOTICE '  Uncommon: %', (SELECT COUNT(*) FROM enhanced_gemstones WHERE rarity = 'uncommon');
    RAISE NOTICE '  Rare: %', (SELECT COUNT(*) FROM enhanced_gemstones WHERE rarity = 'rare');
    RAISE NOTICE '  Epic: %', (SELECT COUNT(*) FROM enhanced_gemstones WHERE rarity = 'epic');
    RAISE NOTICE '  Legendary: %', (SELECT COUNT(*) FROM enhanced_gemstones WHERE rarity = 'legendary');
    RAISE NOTICE '  Mythic: %', (SELECT COUNT(*) FROM enhanced_gemstones WHERE rarity = 'mythic');
    RAISE NOTICE 'All tables, functions, triggers, and security policies are in place.';
END $$;
