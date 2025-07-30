-- Crystal Social Rewards System - Sample Data and Shop Items
-- File: 04_rewards_sample_data.sql
-- Purpose: Insert sample data for shop categories, items, achievements, and daily rewards

-- =============================================================================
-- SHOP CATEGORIES
-- =============================================================================

INSERT INTO shop_categories (id, name, description, icon_name, color_code, sort_order) VALUES
(1, 'Avatar Decorations', 'Decorative items for user avatars', 'person_pin', '#E91E63', 1),
(2, 'Auras', 'Glowing effects around user avatars', 'auto_awesome', '#FFD700', 2),
(3, 'Pets', 'Virtual pets to accompany users', 'pets', '#4CAF50', 3),
(4, 'Pet Accessories', 'Items and accessories for pets', 'diamond', '#9C27B0', 4),
(5, 'Furniture', 'Items for personalizing user spaces', 'chair', '#795548', 5),
(6, 'Tarot Decks', 'Special tarot card designs and themes', 'auto_stories', '#673AB7', 6),
(7, 'Booster Packs', 'Mystery packs containing random items', 'card_giftcard', '#FF5722', 7),
(8, 'Decorations', 'General decorative items and themes', 'palette', '#607D8B', 8)
ON CONFLICT (id) DO UPDATE SET
    description = EXCLUDED.description,
    icon_name = EXCLUDED.icon_name,
    color_code = EXCLUDED.color_code,
    sort_order = EXCLUDED.sort_order;

-- =============================================================================
-- AURA ITEMS
-- =============================================================================

-- First insert shop items for auras
INSERT INTO shop_items (id, name, description, category_id, price, rarity, color_code, effect_type, sort_order) VALUES
-- Common Auras (100-200 coins)
(1, 'Pink Glow', 'A soft pink aura that radiates warmth and friendship', 2, 150, 'common', '#FFB6C1', 'glow', 1),
(2, 'Blue Shimmer', 'A calming blue aura with gentle shimmer effects', 2, 150, 'common', '#87CEEB', 'shimmer', 2),
(3, 'Green Pulse', 'A natural green aura that pulses with life energy', 2, 150, 'common', '#90EE90', 'pulse', 3),
(4, 'Yellow Spark', 'A bright yellow aura with sparkling effects', 2, 150, 'common', '#FFD700', 'spark', 4),
(5, 'Purple Mist', 'A mysterious purple aura with misty effects', 2, 200, 'uncommon', '#DDA0DD', 'mist', 5),

-- Uncommon Auras (200-400 coins)
(6, 'Rainbow Cascade', 'A multi-colored aura that cascades through the spectrum', 2, 350, 'uncommon', '#FF69B4', 'cascade', 6),
(7, 'Silver Frost', 'An icy silver aura with crystalline effects', 2, 300, 'uncommon', '#C0C0C0', 'frost', 7),
(8, 'Golden Radiance', 'A luxurious golden aura that commands attention', 2, 400, 'uncommon', '#FFD700', 'radiance', 8),

-- Rare Auras (500-800 coins)
(9, 'Mystic Fire', 'A rare fiery aura with dancing flame effects', 2, 600, 'rare', '#FF4500', 'fire', 9),
(10, 'Ocean Deep', 'A deep ocean blue aura with wave-like movements', 2, 650, 'rare', '#006994', 'wave', 10),
(11, 'Starlight', 'A celestial aura filled with twinkling stars', 2, 750, 'rare', '#191970', 'starlight', 11),

-- Epic Auras (1000-1500 coins)
(12, 'Phoenix Rising', 'An epic phoenix-themed aura with rebirth energy', 2, 1200, 'epic', '#DC143C', 'phoenix', 12),
(13, 'Galaxy Swirl', 'A cosmic aura with swirling galaxy effects', 2, 1350, 'epic', '#483D8B', 'galaxy', 13),
(14, 'Divine Light', 'A heavenly aura radiating pure divine energy', 2, 1500, 'epic', '#FFFACD', 'divine', 14),

-- Legendary Auras (2000+ coins)
(15, 'Dragon Soul', 'A legendary dragon-powered aura with immense power', 2, 2500, 'legendary', '#8B0000', 'dragon', 15),
(16, 'Crystal Harmony', 'The ultimate crystal-themed aura for true collectors', 2, 3000, 'legendary', '#E6E6FA', 'crystal', 16)

ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    price = EXCLUDED.price,
    rarity = EXCLUDED.rarity,
    color_code = EXCLUDED.color_code,
    effect_type = EXCLUDED.effect_type,
    sort_order = EXCLUDED.sort_order;

-- Insert corresponding aura_items
INSERT INTO aura_items (id, shop_item_id, name, description, color_code, effect_type, rarity, price, unlock_level, is_animated, animation_duration, preview_url) VALUES
(1, 1, 'Pink Glow', 'A soft pink aura that radiates warmth and friendship', '#FFB6C1', 'glow', 'common', 150, 1, false, NULL, '/assets/auras/pink_glow_preview.png'),
(2, 2, 'Blue Shimmer', 'A calming blue aura with gentle shimmer effects', '#87CEEB', 'shimmer', 'common', 150, 1, true, 2000, '/assets/auras/blue_shimmer_preview.png'),
(3, 3, 'Green Pulse', 'A natural green aura that pulses with life energy', '#90EE90', 'pulse', 'common', 150, 1, true, 1500, '/assets/auras/green_pulse_preview.png'),
(4, 4, 'Yellow Spark', 'A bright yellow aura with sparkling effects', '#FFD700', 'spark', 'common', 150, 1, true, 800, '/assets/auras/yellow_spark_preview.png'),
(5, 5, 'Purple Mist', 'A mysterious purple aura with misty effects', '#DDA0DD', 'mist', 'uncommon', 200, 2, true, 3000, '/assets/auras/purple_mist_preview.png'),
(6, 6, 'Rainbow Cascade', 'A multi-colored aura that cascades through the spectrum', '#FF69B4', 'cascade', 'uncommon', 350, 3, true, 2500, '/assets/auras/rainbow_cascade_preview.png'),
(7, 7, 'Silver Frost', 'An icy silver aura with crystalline effects', '#C0C0C0', 'frost', 'uncommon', 300, 3, true, 2000, '/assets/auras/silver_frost_preview.png'),
(8, 8, 'Golden Radiance', 'A luxurious golden aura that commands attention', '#FFD700', 'radiance', 'uncommon', 400, 4, true, 1800, '/assets/auras/golden_radiance_preview.png'),
(9, 9, 'Mystic Fire', 'A rare fiery aura with dancing flame effects', '#FF4500', 'fire', 'rare', 600, 5, true, 1200, '/assets/auras/mystic_fire_preview.png'),
(10, 10, 'Ocean Deep', 'A deep ocean blue aura with wave-like movements', '#006994', 'wave', 'rare', 650, 5, true, 2200, '/assets/auras/ocean_deep_preview.png'),
(11, 11, 'Starlight', 'A celestial aura filled with twinkling stars', '#191970', 'starlight', 'rare', 750, 6, true, 1000, '/assets/auras/starlight_preview.png'),
(12, 12, 'Phoenix Rising', 'An epic phoenix-themed aura with rebirth energy', '#DC143C', 'phoenix', 'epic', 1200, 8, true, 3500, '/assets/auras/phoenix_rising_preview.png'),
(13, 13, 'Galaxy Swirl', 'A cosmic aura with swirling galaxy effects', '#483D8B', 'galaxy', 'epic', 1350, 9, true, 4000, '/assets/auras/galaxy_swirl_preview.png'),
(14, 14, 'Divine Light', 'A heavenly aura radiating pure divine energy', '#FFFACD', 'divine', 'epic', 1500, 10, true, 2800, '/assets/auras/divine_light_preview.png'),
(15, 15, 'Dragon Soul', 'A legendary dragon-powered aura with immense power', '#8B0000', 'dragon', 'legendary', 2500, 15, true, 5000, '/assets/auras/dragon_soul_preview.png'),
(16, 16, 'Crystal Harmony', 'The ultimate crystal-themed aura for true collectors', '#E6E6FA', 'crystal', 'legendary', 3000, 20, true, 6000, '/assets/auras/crystal_harmony_preview.png')

ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    color_code = EXCLUDED.color_code,
    effect_type = EXCLUDED.effect_type,
    rarity = EXCLUDED.rarity,
    price = EXCLUDED.price,
    unlock_level = EXCLUDED.unlock_level,
    is_animated = EXCLUDED.is_animated,
    animation_duration = EXCLUDED.animation_duration,
    preview_url = EXCLUDED.preview_url;

-- =============================================================================
-- BOOSTER PACKS
-- =============================================================================

INSERT INTO shop_items (id, name, description, category_id, price, rarity, sort_order, metadata) VALUES
-- Booster Packs
(50, 'Starter Pack', 'Contains 3 common items and 1 uncommon item', 7, 200, 'common', 1, '{"contains": [{"rarity": "common", "count": 3}, {"rarity": "uncommon", "count": 1}]}'),
(51, 'Explorer Pack', 'Contains 2 common items, 2 uncommon items, and 1 rare item', 7, 500, 'uncommon', 2, '{"contains": [{"rarity": "common", "count": 2}, {"rarity": "uncommon", "count": 2}, {"rarity": "rare", "count": 1}]}'),
(52, 'Adventure Pack', 'Contains 1 common, 2 uncommon, 2 rare, and 1 epic item', 7, 1000, 'rare', 3, '{"contains": [{"rarity": "common", "count": 1}, {"rarity": "uncommon", "count": 2}, {"rarity": "rare", "count": 2}, {"rarity": "epic", "count": 1}]}'),
(53, 'Legend Pack', 'Contains 2 rare, 2 epic, and 1 legendary item', 7, 2000, 'epic', 4, '{"contains": [{"rarity": "rare", "count": 2}, {"rarity": "epic", "count": 2}, {"rarity": "legendary", "count": 1}]}'),
(54, 'Crystal Pack', 'The ultimate pack with guaranteed legendary items', 7, 5000, 'legendary', 5, '{"contains": [{"rarity": "epic", "count": 2}, {"rarity": "legendary", "count": 3}]}'),
(55, 'Mystic Pack', 'Special limited edition pack with exclusive items', 7, 3000, 'epic', 6, '{"contains": [{"rarity": "uncommon", "count": 1}, {"rarity": "rare", "count": 2}, {"rarity": "epic", "count": 2}, {"rarity": "legendary", "count": 1}], "special": true}')

ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    price = EXCLUDED.price,
    rarity = EXCLUDED.rarity,
    sort_order = EXCLUDED.sort_order,
    metadata = EXCLUDED.metadata;

-- =============================================================================
-- PET ITEMS
-- =============================================================================

INSERT INTO shop_items (id, name, description, category_id, price, rarity, sort_order) VALUES
-- Pets
(100, 'Crystal Butterfly', 'A beautiful crystal butterfly companion', 3, 300, 'common', 1),
(101, 'Rainbow Bird', 'A colorful bird that follows you around', 3, 450, 'uncommon', 2),
(102, 'Mystic Cat', 'A magical cat with glowing eyes', 3, 600, 'rare', 3),
(103, 'Fire Dragon', 'A small fire-breathing dragon', 3, 1200, 'epic', 4),
(104, 'Phoenix Companion', 'A legendary phoenix that grants special powers', 3, 2500, 'legendary', 5),

-- Pet Accessories
(150, 'Golden Collar', 'A luxurious golden collar for pets', 4, 100, 'common', 1),
(151, 'Crystal Crown', 'A sparkling crown that makes pets look royal', 4, 250, 'uncommon', 2),
(152, 'Magic Wings', 'Wings that allow pets to fly', 4, 500, 'rare', 3),
(153, 'Elemental Armor', 'Protective armor that changes based on environment', 4, 800, 'epic', 4),
(154, 'Divine Halo', 'A holy halo that grants pets special abilities', 4, 1500, 'legendary', 5)

ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    price = EXCLUDED.price,
    rarity = EXCLUDED.rarity,
    sort_order = EXCLUDED.sort_order;

-- =============================================================================
-- AVATAR DECORATIONS
-- =============================================================================

INSERT INTO shop_items (id, name, description, category_id, price, rarity, sort_order) VALUES
-- Avatar Decorations
(200, 'Simple Frame', 'A basic decorative frame for avatars', 1, 50, 'common', 1),
(201, 'Flower Crown', 'A beautiful crown made of flowers', 1, 150, 'common', 2),
(202, 'Knight Helmet', 'A medieval knight helmet decoration', 1, 200, 'uncommon', 3),
(203, 'Wizard Hat', 'A magical wizard hat with sparkles', 1, 300, 'uncommon', 4),
(204, 'Angel Wings', 'Ethereal angel wings decoration', 1, 500, 'rare', 5),
(205, 'Devil Horns', 'Mischievous devil horns decoration', 1, 500, 'rare', 6),
(206, 'Crystal Tiara', 'An elegant crystal tiara', 1, 800, 'epic', 7),
(207, 'Dragon Horns', 'Powerful dragon horns decoration', 1, 1000, 'epic', 8),
(208, 'Celestial Halo', 'A divine celestial halo', 1, 2000, 'legendary', 9)

ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    price = EXCLUDED.price,
    rarity = EXCLUDED.rarity,
    sort_order = EXCLUDED.sort_order;

-- =============================================================================
-- ACHIEVEMENTS
-- =============================================================================

INSERT INTO achievements (id, name, description, category_id, achievement_type, target_value, coins_reward, points_reward, rarity, display_order) VALUES
-- Social Achievements
(1, 'First Friend', 'Make your first friend on Crystal Social', 1, 'friend_count', 1, 100, 50, 'common', 1),
(2, 'Social Butterfly', 'Make 10 friends', 1, 'friend_count', 10, 250, 100, 'uncommon', 2),
(3, 'Popular Person', 'Make 50 friends', 1, 'friend_count', 50, 500, 250, 'rare', 3),
(4, 'Chatterbox', 'Send 100 messages', 1, 'message_count', 100, 200, 100, 'common', 4),
(5, 'Conversation Master', 'Send 1000 messages', 1, 'message_count', 1000, 1000, 500, 'epic', 5),

-- Gaming Achievements
(6, 'Game On', 'Play your first game', 2, 'game_count', 1, 50, 25, 'common', 6),
(7, 'Gamer', 'Play 50 games', 2, 'game_count', 50, 300, 150, 'uncommon', 7),
(8, 'Game Master', 'Win 100 games', 2, 'game_wins', 100, 600, 300, 'rare', 8),
(9, 'Gaming Legend', 'Win 500 games', 2, 'game_wins', 500, 1500, 750, 'epic', 9),

-- Collecting Achievements
(10, 'First Purchase', 'Make your first shop purchase', 3, 'purchase_count', 1, 100, 50, 'common', 10),
(11, 'Collector', 'Purchase 25 items from the shop', 3, 'purchase_count', 25, 500, 250, 'uncommon', 11),
(12, 'Hoarder', 'Purchase 100 items from the shop', 3, 'purchase_count', 100, 1000, 500, 'rare', 12),
(13, 'Big Spender', 'Spend 5000 coins in the shop', 3, 'spending_amount', 5000, 1000, 500, 'uncommon', 13),
(14, 'Whale', 'Spend 50000 coins in the shop', 3, 'spending_amount', 50000, 5000, 2500, 'legendary', 14),

-- Progress Achievements
(15, 'Level Up', 'Reach level 5', 4, 'level_reached', 5, 200, 100, 'common', 15),
(16, 'Rising Star', 'Reach level 10', 4, 'level_reached', 10, 500, 250, 'uncommon', 16),
(17, 'Elite User', 'Reach level 25', 4, 'level_reached', 25, 1000, 500, 'rare', 17),
(18, 'Legendary Status', 'Reach level 50', 4, 'level_reached', 50, 2500, 1250, 'epic', 18),
(19, 'Crystal Master', 'Reach the maximum level 100', 4, 'level_reached', 100, 10000, 5000, 'legendary', 19),

-- Special Achievements
(20, 'Daily Dedication', 'Log in for 7 consecutive days', 5, 'login_streak', 7, 300, 150, 'uncommon', 20),
(21, 'Loyal User', 'Log in for 30 consecutive days', 5, 'login_streak', 30, 1000, 500, 'rare', 21),
(22, 'Crystal Champion', 'Log in for 100 consecutive days', 5, 'login_streak', 100, 3000, 1500, 'epic', 22),
(23, 'Early Adopter', 'Join Crystal Social in the first month', 5, 'early_adoption', 1, 500, 250, 'rare', 23),
(24, 'Perfectionist', 'Complete all other achievements', 5, 'completion_rate', 100, 10000, 5000, 'legendary', 24)

ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    category_id = EXCLUDED.category_id,
    achievement_type = EXCLUDED.achievement_type,
    target_value = EXCLUDED.target_value,
    coins_reward = EXCLUDED.coins_reward,
    points_reward = EXCLUDED.points_reward,
    rarity = EXCLUDED.rarity,
    display_order = EXCLUDED.display_order;

-- =============================================================================
-- DAILY REWARDS CONFIGURATION
-- =============================================================================

INSERT INTO daily_rewards (day_number, coins_reward, points_reward, is_special_day, description) VALUES
-- Week 1
(1, 50, 25, false, 'Welcome bonus'),
(2, 60, 30, false, 'Day 2 reward'),
(3, 70, 35, false, 'Day 3 reward'),
(4, 80, 40, false, 'Day 4 reward'),
(5, 90, 45, false, 'Day 5 reward'),
(6, 100, 50, false, 'Weekend bonus'),
(7, 150, 75, true, 'Weekly milestone - Extra coins!'),

-- Week 2
(8, 75, 40, false, 'Week 2 begins'),
(9, 85, 45, false, 'Day 9 reward'),
(10, 95, 50, false, 'Day 10 reward'),
(11, 105, 55, false, 'Day 11 reward'),
(12, 115, 60, false, 'Day 12 reward'),
(13, 125, 65, false, 'Day 13 reward'),
(14, 200, 100, true, 'Two weeks strong!'),

-- Week 3
(15, 100, 55, false, 'Halfway point'),
(16, 110, 60, false, 'Day 16 reward'),
(17, 120, 65, false, 'Day 17 reward'),
(18, 130, 70, false, 'Day 18 reward'),
(19, 140, 75, false, 'Day 19 reward'),
(20, 150, 80, false, 'Day 20 reward'),
(21, 250, 125, true, 'Three weeks milestone!'),

-- Week 4
(22, 125, 70, false, 'Final week begins'),
(23, 135, 75, false, 'Day 23 reward'),
(24, 145, 80, false, 'Day 24 reward'),
(25, 155, 85, false, 'Day 25 reward'),
(26, 165, 90, false, 'Day 26 reward'),
(27, 175, 95, false, 'Day 27 reward'),
(28, 300, 150, true, 'Almost there!'),

-- Final days
(29, 200, 100, false, 'Penultimate day'),
(30, 500, 250, true, 'Monthly champion! Huge bonus!')

ON CONFLICT (day_number) DO UPDATE SET
    coins_reward = EXCLUDED.coins_reward,
    points_reward = EXCLUDED.points_reward,
    is_special_day = EXCLUDED.is_special_day,
    description = EXCLUDED.description;

-- =============================================================================
-- LEVEL REQUIREMENTS
-- =============================================================================

INSERT INTO level_requirements (level, experience_required, coins_reward, points_reward, title, badge_icon) VALUES
(1, 0, 0, 0, 'Newcomer', 'star_border'),
(2, 100, 100, 50, 'Explorer', 'star'),
(3, 250, 150, 75, 'Adventurer', 'star'),
(4, 450, 200, 100, 'Traveler', 'star'),
(5, 700, 250, 125, 'Wanderer', 'star'),
(6, 1000, 300, 150, 'Seeker', 'stars'),
(7, 1350, 350, 175, 'Pioneer', 'stars'),
(8, 1750, 400, 200, 'Trailblazer', 'stars'),
(9, 2200, 450, 225, 'Pathfinder', 'stars'),
(10, 2700, 500, 250, 'Navigator', 'stars'),
(11, 3250, 550, 275, 'Guide', 'star_half'),
(12, 3850, 600, 300, 'Leader', 'star_half'),
(13, 4500, 650, 325, 'Champion', 'star_half'),
(14, 5200, 700, 350, 'Hero', 'star_half'),
(15, 5950, 750, 375, 'Legend', 'star_half'),
(16, 6750, 800, 400, 'Myth', 'grade'),
(17, 7600, 850, 425, 'Sage', 'grade'),
(18, 8500, 900, 450, 'Oracle', 'grade'),
(19, 9450, 950, 475, 'Mystic', 'grade'),
(20, 10450, 1000, 500, 'Ascended', 'grade'),
(25, 16000, 1500, 750, 'Elite', 'military_tech'),
(30, 23000, 2000, 1000, 'Master', 'military_tech'),
(35, 31500, 2500, 1250, 'Grandmaster', 'military_tech'),
(40, 41500, 3000, 1500, 'Supreme', 'emoji_events'),
(45, 53000, 3500, 1750, 'Divine', 'emoji_events'),
(50, 66000, 4000, 2000, 'Transcendent', 'emoji_events'),
(60, 96000, 5000, 2500, 'Immortal', 'workspace_premium'),
(70, 132000, 6000, 3000, 'Eternal', 'workspace_premium'),
(80, 174000, 7000, 3500, 'Infinite', 'workspace_premium'),
(90, 222000, 8000, 4000, 'Omnipotent', 'diamond'),
(100, 276000, 10000, 5000, 'Crystal God', 'diamond')

ON CONFLICT (level) DO UPDATE SET
    experience_required = EXCLUDED.experience_required,
    coins_reward = EXCLUDED.coins_reward,
    points_reward = EXCLUDED.points_reward,
    title = EXCLUDED.title,
    badge_icon = EXCLUDED.badge_icon;

-- =============================================================================
-- INITIALIZE ACHIEVEMENT STATISTICS
-- =============================================================================

INSERT INTO achievement_statistics (achievement_id, total_completions, total_attempts, completion_rate)
SELECT id, 0, 0, 0.00 FROM achievements
ON CONFLICT (achievement_id) DO NOTHING;

-- =============================================================================
-- COMMENTS
-- =============================================================================

COMMENT ON TABLE shop_categories IS 'Sample data: 8 main categories for organizing shop items';
COMMENT ON TABLE shop_items IS 'Sample data: Auras, booster packs, pets, and avatar decorations with balanced pricing';
COMMENT ON TABLE aura_items IS 'Sample data: 16 auras from common to legendary with visual effects and animations';
COMMENT ON TABLE achievements IS 'Sample data: 24 achievements across all categories with progressive difficulty';
COMMENT ON TABLE daily_rewards IS 'Sample data: 30-day reward cycle with special milestone bonuses';
COMMENT ON TABLE level_requirements IS 'Sample data: Level progression from 1-100 with titles and rewards';
