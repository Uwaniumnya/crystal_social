-- =====================================================
-- CRYSTAL SOCIAL - GARDEN SYSTEM SETUP
-- =====================================================
-- Initial data setup and configuration for garden system
-- =====================================================

-- Insert flower species data
INSERT INTO flower_species (
    name, category, description, rarity, growth_time_hours, bloom_chance,
    water_frequency_hours, fertilizer_frequency_hours, base_health, base_happiness,
    base_experience, base_coins, bloom_experience, bloom_coins,
    seasonal_preference, special_effects, image_url
) VALUES 
-- Common flowers
(
    'Sunny Daisy', 'daisy', 'A cheerful yellow daisy that loves sunny weather', 'common',
    4, 0.8, 6, 12, 70, 60, 10, 5, 25, 15,
    '["spring", "summer"]', '["happiness_boost"]',
    'assets/garden/flowers/daisy_yellow.png'
),
(
    'Pink Rose', 'rose', 'A classic pink rose with a sweet fragrance', 'common',
    6, 0.7, 4, 8, 80, 70, 15, 8, 30, 20,
    '["spring", "summer", "fall"]', '["fragrance", "beauty_boost"]',
    'assets/garden/flowers/rose_pink.png'
),
(
    'Blue Tulip', 'tulip', 'An elegant blue tulip that blooms in spring', 'common',
    5, 0.75, 5, 10, 75, 65, 12, 6, 28, 18,
    '["spring"]', '["elegance"]',
    'assets/garden/flowers/tulip_blue.png'
),
(
    'White Lily', 'lily', 'A pure white lily with graceful petals', 'common',
    8, 0.6, 4, 8, 85, 75, 18, 10, 35, 25,
    '["spring", "summer"]', '["purity", "grace"]',
    'assets/garden/flowers/lily_white.png'
),
(
    'Sunflower', 'sunflower', 'A tall, bright sunflower that follows the sun', 'common',
    10, 0.8, 8, 16, 90, 80, 20, 12, 40, 30,
    '["summer"]', '["sun_tracking", "height_boost"]',
    'assets/garden/flowers/sunflower.png'
),

-- Rare flowers
(
    'Rainbow Orchid', 'orchid', 'A mystical orchid that shimmers with rainbow colors', 'rare',
    12, 0.4, 3, 6, 95, 90, 50, 25, 100, 75,
    '["spring", "summer", "fall", "winter"]', '["rainbow_effect", "magic_boost"]',
    'assets/garden/flowers/orchid_rainbow.png'
),
(
    'Midnight Rose', 'rose', 'A deep purple rose that only blooms at night', 'rare',
    15, 0.3, 2, 4, 90, 85, 60, 30, 120, 90,
    '["fall", "winter"]', '["night_bloom", "mystery"]',
    'assets/garden/flowers/rose_midnight.png'
),
(
    'Crystal Peony', 'peony', 'A translucent peony that sparkles like crystal', 'rare',
    18, 0.35, 3, 6, 85, 80, 55, 28, 110, 80,
    '["spring"]', '["crystal_effect", "light_reflection"]',
    'assets/garden/flowers/peony_crystal.png'
),
(
    'Fire Poppy', 'poppy', 'A fiery red poppy that glows with inner warmth', 'rare',
    14, 0.4, 4, 8, 80, 75, 45, 22, 95, 65,
    '["summer", "fall"]', '["fire_effect", "warmth"]',
    'assets/garden/flowers/poppy_fire.png'
),

-- Epic flowers
(
    'Starlight Lotus', 'lotus', 'A legendary lotus that blooms only under starlight', 'epic',
    24, 0.15, 2, 4, 100, 100, 150, 100, 300, 200,
    '["summer"]', '["starlight_bloom", "legendary_aura", "time_manipulation"]',
    'assets/garden/flowers/lotus_starlight.png'
),
(
    'Phoenix Flower', 'exotic', 'A mythical flower that rises from ashes', 'epic',
    30, 0.1, 1, 2, 100, 95, 200, 150, 400, 300,
    '["fall", "winter"]', '["rebirth", "fire_immunity", "phoenix_effect"]',
    'assets/garden/flowers/phoenix_flower.png'
),
(
    'Aurora Blossom', 'exotic', 'A magical flower that displays aurora-like colors', 'epic',
    36, 0.08, 1, 3, 95, 100, 250, 200, 500, 400,
    '["winter"]', '["aurora_display", "weather_control", "magic_amplifier"]',
    'assets/garden/flowers/aurora_blossom.png'
);

-- Insert garden visitor data
INSERT INTO garden_visitors (
    name, visitor_type, description, rarity, image_url, animation_type,
    stay_duration_minutes, visit_chance, required_flowers, min_garden_level,
    seasonal_availability, reward_type, reward_amount, reward_items, special_abilities
) VALUES 
-- Common visitors
(
    'Busy Bee', 'beneficial', 'A friendly bee that helps pollinate your flowers', 'common',
    'assets/garden/visitors/bee.png', 'flying',
    30, 0.3, 2, 1, '["spring", "summer"]', 'coins', 10, null,
    '["pollination", "flower_health_boost"]'
),
(
    'Garden Butterfly', 'beneficial', 'A colorful butterfly that brings joy to your garden', 'common',
    'assets/garden/visitors/butterfly.png', 'flying',
    20, 0.25, 1, 1, '["spring", "summer", "fall"]', 'experience', 15, null,
    '["happiness_boost", "beauty_enhancement"]'
),
(
    'Helpful Robin', 'beneficial', 'A cheerful robin that protects your flowers from pests', 'common',
    'assets/garden/visitors/robin.png', 'hopping',
    45, 0.2, 3, 2, '["spring", "summer", "fall"]', 'coins', 20, null,
    '["pest_control", "morning_song"]'
),
(
    'Garden Gnome', 'beneficial', 'A wise gnome who offers gardening advice', 'common',
    'assets/garden/visitors/gnome.png', 'stationary',
    60, 0.15, 5, 3, '["spring", "summer", "fall", "winter"]', 'items', 0,
    '["fertilizer", "water"]', '["wisdom", "garden_blessing"]'
),

-- Rare visitors
(
    'Rainbow Hummingbird', 'beneficial', 'A magical hummingbird with iridescent feathers', 'rare',
    'assets/garden/visitors/hummingbird_rainbow.png', 'flying',
    15, 0.1, 8, 5, '["spring", "summer"]', 'gems', 5, null,
    '["flower_growth_boost", "rainbow_blessing"]'
),
(
    'Fairy Companion', 'magical', 'A tiny fairy that brings magic to your garden', 'rare',
    'assets/garden/visitors/fairy.png', 'floating',
    25, 0.08, 10, 7, '["spring", "summer", "fall"]', 'experience', 50,
    '["magic_seeds"]', '["magic_enhancement", "flower_transformation"]'
),
(
    'Wise Owl', 'beneficial', 'An ancient owl with knowledge of garden secrets', 'rare',
    'assets/garden/visitors/owl.png', 'perching',
    40, 0.06, 12, 8, '["fall", "winter"]', 'items', 0,
    '["rare_seeds", "ancient_fertilizer"]', '["wisdom", "night_protection"]'
),

-- Epic visitors
(
    'Crystal Dragon', 'legendary', 'A majestic crystal dragon that blesses gardens', 'epic',
    'assets/garden/visitors/dragon_crystal.png', 'flying',
    10, 0.02, 20, 15, '["winter"]', 'gems', 50,
    '["epic_seeds", "dragon_blessing"]', '["legendary_blessing", "crystal_magic", "garden_transformation"]'
),
(
    'Garden Phoenix', 'legendary', 'A mythical phoenix that brings rebirth to gardens', 'epic',
    'assets/garden/visitors/phoenix.png', 'flying',
    8, 0.015, 25, 20, '["fall"]', 'experience', 500,
    '["phoenix_seeds", "rebirth_potion"]', '["rebirth", "fire_blessing", "eternal_growth"]'
),

-- Neutral/Special visitors
(
    'Mischievous Sprite', 'neutral', 'A playful sprite that might help or hinder', 'rare',
    'assets/garden/visitors/sprite.png', 'dancing',
    20, 0.05, 6, 4, '["spring", "summer"]', 'coins', 30,
    '["mystery_seeds"]', '["mischief", "surprise_effects"]'
),
(
    'Time Gardener', 'legendary', 'A mysterious figure who manipulates garden time', 'epic',
    'assets/garden/visitors/time_gardener.png', 'walking',
    5, 0.01, 30, 25, '["spring", "summer", "fall", "winter"]', 'experience', 1000,
    '["time_seeds", "temporal_fertilizer"]', '["time_manipulation", "instant_growth", "temporal_blessing"]'
);

-- Insert garden shop items
INSERT INTO garden_shop_items (
    item_name, display_name, description, category, price_coins, price_gems,
    image_url, rarity, stock_quantity, min_level_required, seasonal_availability,
    special_properties, is_available
) VALUES 
-- Basic resources
('water', 'Fresh Water', 'Pure water for your flowers', 'resource', 5, 0,
 'assets/garden/shop/water.png', 'common', null, 1, '["spring", "summer", "fall", "winter"]',
 '{"effectiveness": 100}', true),
('fertilizer', 'Organic Fertilizer', 'Rich fertilizer for healthy growth', 'resource', 15, 0,
 'assets/garden/shop/fertilizer.png', 'common', null, 1, '["spring", "summer", "fall", "winter"]',
 '{"effectiveness": 100, "duration_hours": 12}', true),
('pesticide', 'Natural Pesticide', 'Protects flowers from harmful pests', 'resource', 25, 0,
 'assets/garden/shop/pesticide.png', 'common', null, 3, '["spring", "summer", "fall", "winter"]',
 '{"effectiveness": 100, "protection_hours": 24}', true),

-- Seeds
('seeds_common', 'Common Flower Seeds', 'A pack of common flower seeds', 'seed', 50, 0,
 'assets/garden/shop/seeds_common.png', 'common', null, 1, '["spring", "summer", "fall", "winter"]',
 '{"varieties": ["daisy", "rose", "tulip", "lily"]}', true),
('seeds_rare', 'Rare Flower Seeds', 'A pack of rare flower seeds', 'seed', 200, 5,
 'assets/garden/shop/seeds_rare.png', 'rare', null, 5, '["spring", "summer", "fall", "winter"]',
 '{"varieties": ["orchid", "crystal_peony", "fire_poppy"]}', true),
('seeds_epic', 'Epic Flower Seeds', 'A pack of legendary flower seeds', 'seed', 1000, 50,
 'assets/garden/shop/seeds_epic.png', 'epic', 5, 15, '["spring", "summer", "fall", "winter"]',
 '{"varieties": ["starlight_lotus", "phoenix_flower", "aurora_blossom"]}', true),

-- Tools and enhancements
('magic_watering_can', 'Magic Watering Can', 'Waters multiple flowers at once', 'tool', 500, 10,
 'assets/garden/shop/watering_can_magic.png', 'rare', null, 8, '["spring", "summer", "fall", "winter"]',
 '{"multi_water": true, "efficiency": 150}', true),
('golden_fertilizer', 'Golden Fertilizer', 'Premium fertilizer with lasting effects', 'resource', 100, 2,
 'assets/garden/shop/fertilizer_golden.png', 'rare', null, 6, '["spring", "summer", "fall", "winter"]',
 '{"effectiveness": 200, "duration_hours": 24}', true),
('growth_booster', 'Growth Booster', 'Accelerates flower growth temporarily', 'enhancement', 150, 5,
 'assets/garden/shop/growth_booster.png', 'rare', null, 10, '["spring", "summer", "fall", "winter"]',
 '{"growth_multiplier": 2.0, "duration_hours": 6}', true),

-- Decorations
('garden_fountain', 'Decorative Fountain', 'A beautiful fountain for your garden', 'decoration', 2000, 25,
 'assets/garden/shop/fountain.png', 'epic', null, 12, '["spring", "summer", "fall", "winter"]',
 '{"happiness_aura": 10, "water_generation": true}', true),
('butterfly_house', 'Butterfly House', 'Attracts more butterflies to your garden', 'decoration', 800, 15,
 'assets/garden/shop/butterfly_house.png', 'rare', null, 7, '["spring", "summer", "fall"]',
 '{"visitor_attraction": "butterfly", "happiness_boost": 5}', true),
('garden_bench', 'Garden Bench', 'A cozy bench for resting in your garden', 'decoration', 300, 5,
 'assets/garden/shop/bench.png', 'common', null, 4, '["spring", "summer", "fall", "winter"]',
 '{"happiness_boost": 3, "rest_spot": true}', true),

-- Seasonal items
('snow_globe', 'Magical Snow Globe', 'Creates a winter wonderland effect', 'seasonal', 1500, 30,
 'assets/garden/shop/snow_globe.png', 'epic', 3, 15, '["winter"]',
 '{"weather_control": "snow", "duration_hours": 24}', true),
('spring_banner', 'Spring Festival Banner', 'Celebrates the arrival of spring', 'seasonal', 200, 3,
 'assets/garden/shop/spring_banner.png', 'rare', null, 5, '["spring"]',
 '{"happiness_boost": 8, "growth_boost": 5}', true),
('autumn_leaves', 'Golden Autumn Leaves', 'Beautiful fallen leaves decoration', 'seasonal', 100, 1,
 'assets/garden/shop/autumn_leaves.png', 'common', null, 3, '["fall"]',
 '{"beauty_boost": 5, "cozy_feeling": true}', true);

-- Create initial weather patterns (these would be managed by admin or system)
INSERT INTO garden_weather_events (garden_id, weather_type, intensity, start_time, end_time)
SELECT 
    g.id,
    'sunny',
    75,
    NOW(),
    NOW() + INTERVAL '6 hours',
    true
FROM gardens g
WHERE g.created_at > NOW() - INTERVAL '1 hour'; -- Apply to recently created gardens

-- Create system configuration
INSERT INTO garden_shop_items (
    item_name, display_name, description, category, price_coins, price_gems,
    image_url, rarity, stock_quantity, min_level_required, seasonal_availability,
    special_properties, is_available
) VALUES 
-- System items (not visible in shop but used for rewards)
('system_reward_coins', 'Bonus Coins', 'Extra coins from achievements', 'system', 0, 0,
 'assets/garden/rewards/coins.png', 'common', null, 0, '["spring", "summer", "fall", "winter"]',
 '{"system_only": true}', false),
('system_reward_gems', 'Bonus Gems', 'Extra gems from special events', 'system', 0, 0,
 'assets/garden/rewards/gems.png', 'rare', null, 0, '["spring", "summer", "fall", "winter"]',
 '{"system_only": true}', false),
('system_reward_experience', 'Experience Boost', 'Extra experience for leveling up', 'system', 0, 0,
 'assets/garden/rewards/experience.png', 'common', null, 0, '["spring", "summer", "fall", "winter"]',
 '{"system_only": true}', false);

-- Add helpful stored procedures for administration
CREATE OR REPLACE FUNCTION reset_garden_daily_quests()
RETURNS INTEGER AS $$
DECLARE
    quest_count INTEGER := 0;
BEGIN
    -- Remove old quests
    DELETE FROM garden_daily_quests WHERE quest_date < CURRENT_DATE;
    
    -- Create new quests for all active gardens
    INSERT INTO garden_daily_quests (
        garden_id, quest_type, quest_name, description, target_value,
        reward_coins, reward_experience, quest_date
    )
    SELECT 
        g.id,
        'water_flowers',
        'Daily Watering',
        'Water ' || (g.level * 2) || ' flowers today',
        g.level * 2,
        30 + (g.level * 5),
        15 + (g.level * 3),
        CURRENT_DATE
    FROM gardens g
    WHERE g.updated_at > NOW() - INTERVAL '7 days' -- Active gardens only
    AND NOT EXISTS (
        SELECT 1 FROM garden_daily_quests 
        WHERE garden_id = g.id AND quest_date = CURRENT_DATE
    );
    
    GET DIAGNOSTICS quest_count = ROW_COUNT;
    RETURN quest_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION trigger_random_weather()
RETURNS INTEGER AS $$
DECLARE
    weather_count INTEGER := 0;
    weather_types TEXT[] := ARRAY['sunny', 'rainy', 'windy', 'misty'];
    selected_weather TEXT;
    garden_record RECORD;
BEGIN
    selected_weather := weather_types[1 + floor(random() * array_length(weather_types, 1))];
    
    -- Apply weather to random selection of active gardens
    FOR garden_record IN 
        SELECT id FROM gardens 
        WHERE updated_at > NOW() - INTERVAL '24 hours'
        AND random() < 0.3 -- 30% chance per garden
        LIMIT 20 -- Max 20 gardens at once
    LOOP
        INSERT INTO garden_weather_events (
            garden_id, weather_type, intensity, start_time, end_time
        ) VALUES (
            garden_record.id,
            selected_weather,
            50 + floor(random() * 50), -- Random intensity 50-100
            NOW(),
            NOW() + INTERVAL '2 hours' + (random() * INTERVAL '4 hours'), -- 2-6 hours
            true
        );
        weather_count := weather_count + 1;
    END LOOP;
    
    RETURN weather_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_gardens_user_id ON gardens(user_id);
-- Remove this index since is_public column doesn't exist
-- CREATE INDEX IF NOT EXISTS idx_gardens_public ON gardens(is_public) WHERE is_public = true;
CREATE INDEX IF NOT EXISTS idx_gardens_level ON gardens(level);
CREATE INDEX IF NOT EXISTS idx_flowers_garden_id ON flowers(garden_id);
CREATE INDEX IF NOT EXISTS idx_flowers_species_id ON flowers(species_id);
CREATE INDEX IF NOT EXISTS idx_flowers_growth_stage ON flowers(growth_stage);
CREATE INDEX IF NOT EXISTS idx_flowers_rarity ON flowers(rarity);
CREATE INDEX IF NOT EXISTS idx_flowers_last_watered ON flowers(last_watered_at);
CREATE INDEX IF NOT EXISTS idx_garden_inventory_garden_id ON garden_inventory(garden_id);
CREATE INDEX IF NOT EXISTS idx_garden_inventory_item ON garden_inventory(item_type, item_name);
CREATE INDEX IF NOT EXISTS idx_garden_visitors_active ON garden_visitor_instances(garden_id, will_leave_at) WHERE will_leave_at > NOW();
CREATE INDEX IF NOT EXISTS idx_garden_weather_time ON garden_weather_events(garden_id, ends_at) WHERE ends_at > NOW();
CREATE INDEX IF NOT EXISTS idx_garden_achievements_garden ON garden_achievements(garden_id, is_completed);
CREATE INDEX IF NOT EXISTS idx_garden_quests_date ON garden_daily_quests(garden_id, quest_date);
CREATE INDEX IF NOT EXISTS idx_garden_analytics_date ON garden_analytics(garden_id, date);
CREATE INDEX IF NOT EXISTS idx_garden_shop_available ON garden_shop_items(category, is_available) WHERE is_available = true;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION reset_garden_daily_quests TO authenticated;
GRANT EXECUTE ON FUNCTION trigger_random_weather TO authenticated;

-- Create notification for successful setup
DO $$
BEGIN
    RAISE NOTICE 'Garden system setup completed successfully!';
    RAISE NOTICE 'Created % flower species', (SELECT COUNT(*) FROM flower_species);
    RAISE NOTICE 'Created % visitor types', (SELECT COUNT(*) FROM garden_visitors);
    RAISE NOTICE 'Created % shop items', (SELECT COUNT(*) FROM garden_shop_items WHERE is_available = true);
    RAISE NOTICE 'All tables, functions, triggers, and security policies are in place.';
END $$;
