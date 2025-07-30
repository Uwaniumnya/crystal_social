-- Crystal Social Rewards System - Complete Shop Items from Dart
-- File: 07_shop_items_from_dart.sql
-- Purpose: All shop items from shop_item_sync.dart file integrated into SQL

-- =============================================================================
-- CLEAR EXISTING SAMPLE DATA (OPTIONAL)
-- =============================================================================

-- Uncomment these lines if you want to replace the basic sample data
-- DELETE FROM user_inventory WHERE item_id IN (SELECT id FROM shop_items WHERE id < 1000);
-- DELETE FROM aura_items WHERE id < 1000;
-- DELETE FROM shop_items WHERE id < 1000;

-- =============================================================================
-- BOOSTER PACKS (Category 7)
-- =============================================================================

INSERT INTO shop_items (name, description, category_id, price, rarity, image_url, requires_level, metadata) VALUES
-- Booster Packs with category reference for contents
('Booster Pack - Avatar Decorations', 'To up your decorations game! Contains 3-5 random avatar decorations.', 7, 500, 'rare', 'assets/booster/deco.png', 1, '{"category_reference_id": 1, "contains": [{"rarity": "common", "min": 2, "max": 3}, {"rarity": "uncommon", "min": 1, "max": 2}]}'),
('Booster Pack - Auras', 'Unlock Auras Plenty! Contains mystical aura effects.', 7, 500, 'rare', 'assets/booster/aura.png', 5, '{"category_reference_id": 2, "contains": [{"rarity": "common", "min": 1, "max": 2}, {"rarity": "uncommon", "min": 1, "max": 1}, {"rarity": "rare", "min": 0, "max": 1}]}'),
('Booster Pack - Pets', 'New Friends, For You! Discover adorable companion pets.', 7, 1500, 'epic', 'assets/booster/pets.png', 10, '{"category_reference_id": 3, "contains": [{"rarity": "uncommon", "min": 1, "max": 2}, {"rarity": "rare", "min": 1, "max": 1}], "max_per_user": 10}'),
('Booster Pack - Pet Accessories', 'Get Your Pet Something Pretty! Stylish accessories for your companions.', 7, 600, 'rare', 'assets/booster/accessories.png', 8, '{"category_reference_id": 4, "contains": [{"rarity": "common", "min": 2, "max": 3}, {"rarity": "uncommon", "min": 1, "max": 1}]}'),
('Booster Pack - Furniture', 'For Your Home, Homely! Beautiful furniture for your virtual space.', 7, 300, 'common', 'assets/booster/furniture.png', 3, '{"category_reference_id": 5, "contains": [{"rarity": "common", "min": 3, "max": 4}, {"rarity": "uncommon", "min": 0, "max": 1}]}'),
('Booster Packs - Tarot Decks', 'Reading the Future with Style! Mystical tarot cards with special powers.', 7, 800, 'legendary', 'assets/booster/tarot.png', 15, '{"category_reference_id": 6, "contains": [{"rarity": "rare", "min": 1, "max": 1}, {"rarity": "epic", "min": 0, "max": 1}]}');

-- =============================================================================
-- AURAS (Category 2) - Nature & Elemental
-- =============================================================================

INSERT INTO shop_items (name, description, category_id, price, rarity, image_url, requires_level, color_code, effect_type) VALUES
-- Basic Auras
('Sunset Meadow Aura', 'A calming aura of golden sunset that brings peace to your presence.', 2, 100, 'common', 'assets/shop/auras/sunset_meadow_aura.png', 1, '#FFD700', 'glow'),
('Ocean Breeze Aura', 'A refreshing blue aura that flows like gentle ocean waves.', 2, 120, 'common', 'assets/shop/auras/ocean_breeze_aura.png', 3, '#87CEEB', 'wave'),
('Forest Spirit Aura', 'Emerald green aura surrounded by dancing leaf particles.', 2, 150, 'common', 'assets/shop/auras/forest_spirit_aura.png', 5, '#90EE90', 'pulse'),

-- Elemental Auras
('Lightning Storm Aura', 'Electric purple aura crackling with lightning energy.', 2, 250, 'uncommon', 'assets/shop/auras/lightning_storm_aura.png', 10, '#9370DB', 'spark'),
('Volcanic Ember Aura', 'Fiery red-orange aura with floating ember particles.', 2, 300, 'uncommon', 'assets/shop/auras/volcanic_ember_aura.png', 12, '#FF4500', 'fire'),

-- Cosmic & Mystical Auras
('Starlight Shimmer Aura', 'Deep blue aura filled with twinkling stars and cosmic dust.', 2, 400, 'rare', 'assets/shop/auras/starlight_shimmer_aura.png', 15, '#191970', 'starlight'),
('Moonbeam Glow Aura', 'Silvery-white aura that glows like moonlight on water.', 2, 350, 'uncommon', 'assets/shop/auras/moonbeam_glow_aura.png', 13, '#C0C0C0', 'glow'),
('Galaxy Spiral Aura', 'Magnificent purple and pink aura swirling like a galaxy.', 2, 600, 'rare', 'assets/shop/auras/galaxy_spiral_aura.png', 20, '#8A2BE2', 'galaxy'),
('Nebula Dreams Aura', 'Multi-colored cosmic aura with swirling nebula patterns.', 2, 800, 'epic', 'assets/shop/auras/nebula_dreams_aura.png', 25, '#FF69B4', 'nebula'),

-- Crystal & Gemstone Auras
('Crystal Prism Aura', 'Rainbow aura that refracts light like a crystal prism.', 2, 450, 'rare', 'assets/shop/auras/crystal_prism_aura.png', 18, '#FFFFFF', 'prism'),
('Amethyst Glow Aura', 'Rich purple aura with crystalline amethyst formations.', 2, 320, 'uncommon', 'assets/shop/auras/amethyst_glow_aura.png', 14, '#9966CC', 'crystal'),
('Diamond Radiance Aura', 'Brilliant white aura sparkling with diamond-like brilliance.', 2, 900, 'epic', 'assets/shop/auras/diamond_radiance_aura.png', 30, '#E8E8E8', 'radiance'),

-- Seasonal Auras
('Cherry Blossom Aura', 'Soft pink aura with floating cherry blossom petals.', 2, 280, 'uncommon', 'assets/shop/auras/cherry_blossom_aura.png', 8, '#FFB6C1', 'petal'),
('Autumn Leaves Aura', 'Warm orange and gold aura with swirling autumn leaves.', 2, 260, 'uncommon', 'assets/shop/auras/autumn_leaves_aura.png', 11, '#FF8C00', 'leaves'),
('Winter Frost Aura', 'Icy blue aura with crystalline snowflake patterns.', 2, 290, 'uncommon', 'assets/shop/auras/winter_frost_aura.png', 9, '#B0E0E6', 'frost'),

-- Mythical Auras
('Phoenix Fire Aura', 'Blazing golden-red aura with phoenix flame patterns.', 2, 1200, 'epic', 'assets/shop/auras/phoenix_fire_aura.png', 35, '#DC143C', 'phoenix'),
('Dragon Soul Aura', 'Powerful dark purple aura with dragon scale patterns.', 2, 1500, 'legendary', 'assets/shop/auras/dragon_soul_aura.png', 25, '#8B0000', 'dragon'),
('Angel Wings Aura', 'Heavenly white and gold aura with ethereal feather particles.', 2, 700, 'rare', 'assets/shop/auras/angel_wings_aura.png', 22, '#FFFACD', 'divine'),
('Shadow Mist Aura', 'Dark purple aura with swirling shadow tendrils.', 2, 520, 'rare', 'assets/shop/auras/shadow_mist_aura.png', 19, '#4B0082', 'mist'),

-- Special Event Auras
('Cosmic Eclipse Aura', 'Rare black and gold aura that pulses with eclipse energy.', 2, 2000, 'legendary', 'assets/shop/auras/cosmic_eclipse_aura.png', 30, '#000000', 'eclipse'),
('Rainbow Butterfly Aura', 'Colorful aura with hundreds of tiny rainbow butterflies.', 2, 650, 'rare', 'assets/shop/auras/rainbow_butterfly_aura.png', 21, '#FF69B4', 'butterfly'),
('Stardust Trail Aura', 'Shimmering golden aura that leaves a trail of stardust.', 2, 750, 'epic', 'assets/shop/auras/stardust_trail_aura.png', 27, '#FFD700', 'stardust'),

-- Fun & Whimsical Auras
('Candy Cloud Aura', 'Sweet pastel aura that looks like cotton candy clouds.', 2, 180, 'common', 'assets/shop/auras/candy_cloud_aura.png', 6, '#FFB6C1', 'cloud'),
('Disco Ball Aura', 'Sparkling aura that reflects light like a disco ball.', 2, 380, 'uncommon', 'assets/shop/auras/disco_ball_aura.png', 16, '#C0C0C0', 'disco'),
('Neon Pulse Aura', 'Bright neon aura that pulses with electronic beats.', 2, 420, 'rare', 'assets/shop/auras/neon_pulse_aura.png', 17, '#00FFFF', 'neon'),

-- Zen & Meditation Auras
('Zen Garden Aura', 'Peaceful green aura with floating lotus petals.', 2, 220, 'common', 'assets/shop/auras/zen_garden_aura.png', 7, '#90EE90', 'zen'),
('Healing Light Aura', 'Soft white aura that emanates healing energy and warmth.', 2, 340, 'uncommon', 'assets/shop/auras/healing_light_aura.png', 15, '#F0F8FF', 'healing');

-- =============================================================================
-- TAROT DECKS (Category 6)
-- =============================================================================

INSERT INTO shop_items (name, description, category_id, price, rarity, image_url, requires_level) VALUES
('Water-Colored Deck', 'Multi-colored cosmic aura with swirling nebula patterns.', 6, 200, 'common', 'assets/shop/tarot/water_colored_deck.png', 1),
('Merlin Deck', 'Deck inspired by the legendary wizard Merlin.', 6, 350, 'rare', 'assets/shop/tarot/merlin_deck.png', 5),
('Enchanted Deck', 'Deck featuring enchanted Cards.', 6, 500, 'epic', 'assets/shop/tarot/enchanted_deck.png', 10),
('Forest Spirits Deck', 'Deck inspired by the mystical forest.', 6, 350, 'rare', 'assets/shop/tarot/forest_spirits_deck.png', 10),
('Golden Bit Deck', 'A special Deck, infused with golden Energies and the Pixels that build the Universe.', 6, 500, 'epic', 'assets/shop/tarot/golden_bit_deck.png', 15);

-- =============================================================================
-- PET ACCESSORIES (Category 4)
-- =============================================================================

INSERT INTO shop_items (name, description, category_id, price, rarity, image_url, requires_level) VALUES
-- Headwear & Crowns
('Royal Crown', 'Majestic golden crown fit for a royal pet.', 4, 600, 'epic', 'assets/shop/accessories/crown.png', 25),
('Elegant Top Hat', 'Sophisticated black top hat for distinguished pets.', 4, 220, 'uncommon', 'assets/shop/accessories/top_hat.png', 10),
('Magical Unicorn Horn', 'Enchanted unicorn horn that grants mystical powers.', 4, 550, 'epic', 'assets/shop/accessories/unicorn_horn.png', 22),

-- Cute Animal Ears & Features
('Adorable Cat Ears', 'Cute cat ears that make your pet look even more adorable.', 4, 180, 'common', 'assets/shop/accessories/cat_ears.png', 3),
('Bunny Headset', 'Playful bunny ears headset for energetic pets.', 4, 200, 'uncommon', 'assets/shop/accessories/bunny_headset.png', 6),
('Busy Bee Headpiece', 'Buzzing bee headpiece with tiny wings and antennae.', 4, 240, 'uncommon', 'assets/shop/accessories/bee_headpiece.png', 8),

-- Flowers & Nature
('Delicate Flower Crown', 'Beautiful flower crown that makes your pet look like royalty.', 4, 160, 'common', 'assets/shop/accessories/flower_crown.png', 5),
('Elegant Flower Hairpiece', 'Sophisticated floral hairpiece for special occasions.', 4, 190, 'uncommon', 'assets/shop/accessories/flower_hairpiece.png', 7);

-- =============================================================================
-- UPDATE AURA_ITEMS TABLE WITH NEW AURAS
-- =============================================================================

-- Insert corresponding aura_items for each aura
INSERT INTO aura_items (shop_item_id, name, description, color_code, effect_type, rarity, price, unlock_level, is_animated, preview_url)
SELECT 
    si.id,
    si.name,
    si.description,
    si.color_code,
    si.effect_type,
    si.rarity,
    si.price,
    si.requires_level,
    CASE 
        WHEN si.effect_type IN ('spark', 'pulse', 'fire', 'wave', 'starlight', 'galaxy', 'nebula', 'phoenix', 'dragon', 'disco', 'neon') THEN true
        ELSE false
    END as is_animated,
    REPLACE(si.image_url, '.png', '_preview.png') as preview_url
FROM shop_items si
WHERE si.category_id = 2  -- Auras category
AND NOT EXISTS (
    SELECT 1 FROM aura_items ai WHERE ai.shop_item_id = si.id
);

-- =============================================================================
-- ADD TAGS FOR BETTER CATEGORIZATION
-- =============================================================================

-- Add tags column if it doesn't exist
ALTER TABLE shop_items ADD COLUMN IF NOT EXISTS tags TEXT[];

-- Update tags for auras
UPDATE shop_items SET tags = ARRAY['aura', 'sunset', 'peaceful'] WHERE name = 'Sunset Meadow Aura';
UPDATE shop_items SET tags = ARRAY['aura', 'ocean', 'water', 'peaceful'] WHERE name = 'Ocean Breeze Aura';
UPDATE shop_items SET tags = ARRAY['aura', 'nature', 'forest', 'earth'] WHERE name = 'Forest Spirit Aura';
UPDATE shop_items SET tags = ARRAY['aura', 'lightning', 'electric', 'powerful'] WHERE name = 'Lightning Storm Aura';
UPDATE shop_items SET tags = ARRAY['aura', 'fire', 'volcano', 'powerful'] WHERE name = 'Volcanic Ember Aura';
UPDATE shop_items SET tags = ARRAY['aura', 'cosmic', 'stars', 'mystical'] WHERE name = 'Starlight Shimmer Aura';
UPDATE shop_items SET tags = ARRAY['aura', 'moon', 'silver', 'mystical'] WHERE name = 'Moonbeam Glow Aura';
UPDATE shop_items SET tags = ARRAY['aura', 'galaxy', 'cosmic', 'spiral'] WHERE name = 'Galaxy Spiral Aura';
UPDATE shop_items SET tags = ARRAY['aura', 'nebula', 'cosmic', 'colorful'] WHERE name = 'Nebula Dreams Aura';
UPDATE shop_items SET tags = ARRAY['aura', 'crystal', 'rainbow', 'prism'] WHERE name = 'Crystal Prism Aura';
UPDATE shop_items SET tags = ARRAY['aura', 'amethyst', 'purple', 'crystal'] WHERE name = 'Amethyst Glow Aura';
UPDATE shop_items SET tags = ARRAY['aura', 'diamond', 'brilliant', 'white'] WHERE name = 'Diamond Radiance Aura';
UPDATE shop_items SET tags = ARRAY['aura', 'cherry', 'blossom', 'spring'] WHERE name = 'Cherry Blossom Aura';
UPDATE shop_items SET tags = ARRAY['aura', 'autumn', 'leaves', 'seasonal'] WHERE name = 'Autumn Leaves Aura';
UPDATE shop_items SET tags = ARRAY['aura', 'winter', 'frost', 'ice'] WHERE name = 'Winter Frost Aura';
UPDATE shop_items SET tags = ARRAY['aura', 'phoenix', 'fire', 'mythical'] WHERE name = 'Phoenix Fire Aura';
UPDATE shop_items SET tags = ARRAY['aura', 'dragon', 'soul', 'legendary'] WHERE name = 'Dragon Soul Aura';
UPDATE shop_items SET tags = ARRAY['aura', 'angel', 'wings', 'divine'] WHERE name = 'Angel Wings Aura';
UPDATE shop_items SET tags = ARRAY['aura', 'shadow', 'dark', 'mysterious'] WHERE name = 'Shadow Mist Aura';
UPDATE shop_items SET tags = ARRAY['aura', 'eclipse', 'cosmic', 'rare'] WHERE name = 'Cosmic Eclipse Aura';
UPDATE shop_items SET tags = ARRAY['aura', 'butterfly', 'rainbow', 'nature'] WHERE name = 'Rainbow Butterfly Aura';
UPDATE shop_items SET tags = ARRAY['aura', 'stardust', 'golden', 'trail'] WHERE name = 'Stardust Trail Aura';
UPDATE shop_items SET tags = ARRAY['aura', 'candy', 'sweet', 'pastel'] WHERE name = 'Candy Cloud Aura';
UPDATE shop_items SET tags = ARRAY['aura', 'disco', 'sparkle', 'party'] WHERE name = 'Disco Ball Aura';
UPDATE shop_items SET tags = ARRAY['aura', 'neon', 'pulse', 'electronic'] WHERE name = 'Neon Pulse Aura';
UPDATE shop_items SET tags = ARRAY['aura', 'zen', 'peaceful', 'meditation'] WHERE name = 'Zen Garden Aura';
UPDATE shop_items SET tags = ARRAY['aura', 'healing', 'light', 'peaceful'] WHERE name = 'Healing Light Aura';

-- Update tags for booster packs
UPDATE shop_items SET tags = ARRAY['booster', 'decoration', 'avatar'] WHERE name = 'Booster Pack - Avatar Decorations';
UPDATE shop_items SET tags = ARRAY['booster', 'aura', 'effects'] WHERE name = 'Booster Pack - Auras';
UPDATE shop_items SET tags = ARRAY['booster', 'pets', 'companions'] WHERE name = 'Booster Pack - Pets';
UPDATE shop_items SET tags = ARRAY['booster', 'accessories', 'pet-gear'] WHERE name = 'Booster Pack - Pet Accessories';
UPDATE shop_items SET tags = ARRAY['booster', 'furniture', 'home'] WHERE name = 'Booster Pack - Furniture';
UPDATE shop_items SET tags = ARRAY['booster', 'tarot', 'mystical'] WHERE name = 'Booster Packs - Tarot Decks';

-- Update tags for tarot decks
UPDATE shop_items SET tags = ARRAY['tarot', 'colorful'] WHERE name = 'Water-Colored Deck';
UPDATE shop_items SET tags = ARRAY['tarot', 'colorful', 'mystical'] WHERE name = 'Merlin Deck';
UPDATE shop_items SET tags = ARRAY['tarot', 'enchanted'] WHERE name = 'Enchanted Deck';
UPDATE shop_items SET tags = ARRAY['tarot', 'nature', 'mystical'] WHERE name = 'Forest Spirits Deck';
UPDATE shop_items SET tags = ARRAY['tarot', 'golden', 'pixel'] WHERE name = 'Golden Bit Deck';

-- Update tags for pet accessories
UPDATE shop_items SET tags = ARRAY['accessory', 'crown', 'royal', 'golden'] WHERE name = 'Royal Crown';
UPDATE shop_items SET tags = ARRAY['accessory', 'hat', 'elegant', 'formal'] WHERE name = 'Elegant Top Hat';
UPDATE shop_items SET tags = ARRAY['accessory', 'horn', 'unicorn', 'magical'] WHERE name = 'Magical Unicorn Horn';
UPDATE shop_items SET tags = ARRAY['accessory', 'ears', 'cat', 'cute'] WHERE name = 'Adorable Cat Ears';
UPDATE shop_items SET tags = ARRAY['accessory', 'bunny', 'headset', 'playful'] WHERE name = 'Bunny Headset';
UPDATE shop_items SET tags = ARRAY['accessory', 'bee', 'wings', 'nature'] WHERE name = 'Busy Bee Headpiece';
UPDATE shop_items SET tags = ARRAY['accessory', 'crown', 'flowers', 'nature'] WHERE name = 'Delicate Flower Crown';
UPDATE shop_items SET tags = ARRAY['accessory', 'flower', 'hairpiece', 'elegant'] WHERE name = 'Elegant Flower Hairpiece';

-- =============================================================================
-- CREATE INDEXES FOR PERFORMANCE
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_shop_items_tags ON shop_items USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_shop_items_rarity_category ON shop_items(rarity, category_id);
CREATE INDEX IF NOT EXISTS idx_shop_items_price_range ON shop_items(price) WHERE is_available = true;
CREATE INDEX IF NOT EXISTS idx_shop_items_level_requirement ON shop_items(requires_level) WHERE is_available = true;

-- =============================================================================
-- VERIFICATION QUERY
-- =============================================================================

-- Check the results
SELECT 
    'Shop Items Integration from Dart Complete!' as status,
    (SELECT COUNT(*) FROM shop_items WHERE category_id = 2) as auras_count,
    (SELECT COUNT(*) FROM shop_items WHERE category_id = 6) as tarot_decks_count,
    (SELECT COUNT(*) FROM shop_items WHERE category_id = 4) as pet_accessories_count,
    (SELECT COUNT(*) FROM shop_items WHERE category_id = 7) as booster_packs_count,
    (SELECT COUNT(*) FROM shop_items WHERE tags IS NOT NULL) as items_with_tags,
    NOW() as integration_completed_at;

-- Show sample of integrated items
SELECT 
    si.name,
    si.category_id,
    sc.name as category_name,
    si.price,
    si.rarity,
    si.requires_level,
    array_to_string(si.tags, ', ') as tags
FROM shop_items si
JOIN shop_categories sc ON si.category_id = sc.id
WHERE si.image_url LIKE 'assets/shop/%' OR si.image_url LIKE 'assets/booster/%'
ORDER BY si.category_id, si.price;
