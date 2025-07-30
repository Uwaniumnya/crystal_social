-- Butterfly Species Data Population
-- Populates the butterfly_species table with all 90 butterflies from the Flutter app

-- Clear existing data (optional, for fresh install)
-- DELETE FROM butterfly_species;

-- Insert all 90 butterfly species with enhanced data
INSERT INTO butterfly_species (
    id, name, image_path, rarity, description, habitats, discovery_chance, 
    collection_order, audio_effect, scientific_name, wingspan_cm, 
    flight_pattern, preferred_flowers, season, time_of_day, lore
) VALUES
-- Common butterflies (b1-b25, some commons)
('b1', 'Azure Whisper', 'assets/butterfly/butterfly1.webp', 'common', 
 'A gentle blue butterfly that dances on morning breezes.', 
 '{"Garden", "Meadow"}', 0.045, 1, 'chimes.mp3', 'Lysandra whisperis',
 4.2, 'gentle_float', '{"Lavender", "Forget-me-not"}', 'spring', 'morning',
 'Legend says Azure Whispers carry messages from loved ones on the wind.'),

('b2', 'Sunflare Wing', 'assets/butterfly/butterfly2.webp', 'uncommon',
 'Golden wings that shimmer like captured sunlight.',
 '{"Sunny Garden", "Flower Fields"}', 0.025, 2, 'chimes.mp3', 'Heliotropa aurum',
 5.1, 'spiral_dance', '{"Sunflower", "Marigold"}', 'summer', 'afternoon',
 'These butterflies are said to store actual sunlight in their wings.'),

('b3', 'Pink Mirage', 'assets/butterfly/butterfly3.webp', 'common',
 'Soft pink wings like cherry blossoms in spring.',
 '{"Cherry Grove", "Rose Garden"}', 0.045, 3, 'chimes.mp3', 'Rosalind mirage',
 3.8, 'petal_drift', '{"Cherry Blossom", "Rose"}', 'spring', 'all',
 'Pink Mirages appear during cherry blossom season, bringing hope and renewal.'),

('b4', 'Twilight Ember', 'assets/butterfly/butterfly4.webp', 'rare',
 'Wings that glow like embers at dusk.',
 '{"Evening Garden", "Candlelit Path"}', 0.015, 4, 'chimes.mp3', 'Vespertilio ember',
 4.8, 'ember_glow', '{"Evening Primrose", "Moonflower"}', 'all', 'dusk',
 'Twilight Embers emerge as day turns to night, their wings holding the last light of day.'),

('b5', 'Lunar Dust', 'assets/butterfly/butterfly5.webp', 'epic',
 'Silvery wings that sparkle with moonlight.',
 '{"Night Garden", "Moonbeam Grove"}', 0.010, 5, 'magical_chime.mp3', 'Lunaria sparkle',
 5.5, 'moonbeam_dance', '{"Night Blooming Cereus", "Moonflower"}', 'all', 'night',
 'Lunar Dust butterflies are touched by moon magic, appearing only under starlit skies.'),

('b6', 'Mint Dream', 'assets/butterfly/butterfly6.webp', 'common',
 'Fresh green wings with the scent of mint leaves.',
 '{"Herb Garden", "Meadow"}', 0.045, 6, 'chimes.mp3', 'Mentha dreamer',
 3.9, 'leaf_flutter', '{"Mint", "Basil"}', 'summer', 'morning',
 'Mint Dreams bring the refreshing energy of herb gardens wherever they fly.'),

('b7', 'Lavender Mist', 'assets/butterfly/butterfly7.webp', 'uncommon',
 'Purple wings that carry the calming essence of lavender.',
 '{"Lavender Field", "Peaceful Garden"}', 0.025, 7, 'chimes.mp3', 'Lavandula mist',
 4.3, 'peaceful_glide', '{"Lavender", "Sage"}', 'summer', 'all',
 'These butterflies are known to bring tranquility and peaceful dreams.'),

('b8', 'Golden Breeze', 'assets/butterfly/butterfly8.webp', 'rare',
 'Magnificent golden wings that catch every ray of light.',
 '{"Wheat Field", "Golden Garden"}', 0.015, 8, 'chimes.mp3', 'Aurum ventus',
 5.2, 'golden_spiral', '{"Goldenrod", "Black-eyed Susan"}', 'autumn', 'afternoon',
 'Golden Breezes herald the harvest season with their radiant presence.'),

('b9', 'Coral Glow', 'assets/butterfly/butterfly9.webp', 'common',
 'Warm coral-colored wings like a tropical sunset.',
 '{"Tropical Garden", "Coral Reef"}', 0.045, 9, 'chimes.mp3', 'Corallium glow',
 4.0, 'tropical_sway', '{"Hibiscus", "Bird of Paradise"}', 'summer', 'all',
 'Coral Glows bring the warmth of tropical paradises to any garden.'),

('b10', 'Opal Dusk', 'assets/butterfly/butterfly10.webp', 'legendary',
 'Iridescent wings that shift colors like precious opals.',
 '{"Crystal Garden", "Prismatic Grove"}', 0.004, 10, 'legendary_bell.mp3', 'Opalus twilight',
 6.1, 'prismatic_dance', '{"Crystal Flower", "Prism Bloom"}', 'all', 'dusk',
 'Opal Dusk butterflies are living jewels, their wings containing actual opal fragments.'),

('b11', 'Cherry Blossom', 'assets/butterfly/butterfly11.webp', 'uncommon',
 'Delicate pink and white wings like cherry petals.',
 '{"Cherry Orchard", "Spring Garden"}', 0.025, 11, 'chimes.mp3', 'Prunus flutter',
 4.1, 'petal_dance', '{"Cherry Blossom", "Apple Blossom"}', 'spring', 'morning',
 'Cherry Blossoms embody the fleeting beauty of spring.'),

('b12', 'Frosted Sky', 'assets/butterfly/butterfly12.webp', 'rare',
 'Ice-blue wings with crystalline patterns.',
 '{"Winter Garden", "Frost Meadow"}', 0.015, 12, 'chimes.mp3', 'Glacialis sky',
 4.7, 'crystal_drift', '{"Winter Rose", "Ice Plant"}', 'winter', 'all',
 'Frosted Sky butterflies bring the serene beauty of winter morning frost.'),

('b13', 'Emerald Song', 'assets/butterfly/butterfly13.webp', 'epic',
 'Brilliant emerald wings that seem to sing in the breeze.',
 '{"Emerald Forest", "Jade Garden"}', 0.010, 13, 'magical_chime.mp3', 'Viridis song',
 5.3, 'emerald_melody', '{"Jade Vine", "Green Rose"}', 'spring', 'all',
 'Emerald Songs create haunting melodies with their wing beats.'),

('b14', 'Peach Fizz', 'assets/butterfly/butterfly14.webp', 'common',
 'Bubbly peach-colored wings full of joy.',
 '{"Peach Orchard", "Fizzy Garden"}', 0.045, 14, 'chimes.mp3', 'Persica fizz',
 3.7, 'bubbly_bounce', '{"Peach Blossom", "Fizzy Flower"}', 'summer', 'afternoon',
 'Peach Fizz butterflies bring effervescent joy wherever they flutter.'),

('b15', 'Violet Veil', 'assets/butterfly/butterfly15.webp', 'rare',
 'Deep purple wings with mysterious veining.',
 '{"Violet Meadow", "Mystery Garden"}', 0.015, 15, 'chimes.mp3', 'Viola mysterium',
 4.9, 'mysterious_weave', '{"Violet", "Purple Passion"}', 'all', 'dusk',
 'Violet Veils are said to bridge the gap between dreams and reality.'),

('b16', 'Lemon Zest', 'assets/butterfly/butterfly16.webp', 'common',
 'Bright yellow wings that radiate citrus energy.',
 '{"Citrus Grove", "Lemon Garden"}', 0.045, 16, 'chimes.mp3', 'Citrus zest',
 3.6, 'zesty_zip', '{"Lemon Blossom", "Citrus Flower"}', 'summer', 'morning',
 'Lemon Zest butterflies energize gardens with their vibrant presence.'),

('b17', 'Sapphire Shine', 'assets/butterfly/butterfly17.webp', 'legendary',
 'Deep blue wings that gleam like precious sapphires.',
 '{"Sapphire Lake", "Gem Garden"}', 0.004, 17, 'legendary_bell.mp3', 'Sapphirus shine',
 6.0, 'sapphire_gleam', '{"Blue Diamond", "Sapphire Flower"}', 'all', 'all',
 'Sapphire Shine butterflies are living gems, their wings containing real sapphire dust.'),

('b18', 'Rose Quartz', 'assets/butterfly/butterfly18.webp', 'epic',
 'Soft pink wings with the healing energy of rose quartz.',
 '{"Crystal Garden", "Healing Grove"}', 0.010, 18, 'magical_chime.mp3', 'Quartz rosa',
 5.4, 'healing_pulse', '{"Rose Quartz Flower", "Pink Crystal"}', 'all', 'all',
 'Rose Quartz butterflies carry healing energy in their crystalline wings.'),

('b19', 'Amber Spark', 'assets/butterfly/butterfly19.webp', 'rare',
 'Golden amber wings with ancient wisdom.',
 '{"Amber Forest", "Ancient Grove"}', 0.015, 19, 'chimes.mp3', 'Amber antique',
 4.8, 'ancient_wisdom', '{"Amber Flower", "Ancient Bloom"}', 'autumn', 'all',
 'Amber Spark butterflies carry memories from ancient times in their amber wings.'),

('b20', 'Celestial Wave', 'assets/butterfly/butterfly20.webp', 'mythical',
 'Otherworldly wings that shimmer with cosmic energy.',
 '{"Cosmic Garden", "Starlight Grove"}', 0.001, 20, 'mythical_sparkle.mp3', 'Celestialis cosmic',
 7.2, 'cosmic_wave', '{"Star Flower", "Cosmic Bloom"}', 'all', 'night',
 'Celestial Waves are messengers from distant stars, appearing only during cosmic events.'),

-- Continue with remaining butterflies (b21-b90)
('b21', 'Jade Ripple', 'assets/butterfly/butterfly21.webp', 'uncommon',
 'Green jade wings with rippling patterns.',
 '{"Jade Garden", "Water Garden"}', 0.025, 21, 'chimes.mp3', 'Jadeite ripple',
 4.2, 'water_ripple', '{"Jade Plant", "Water Lily"}', 'summer', 'all',
 'Jade Ripples create peaceful ripples in garden ponds as they pass.'),

('b22', 'Sunset Gleam', 'assets/butterfly/butterfly22.webp', 'rare',
 'Wings that capture the essence of golden sunsets.',
 '{"Sunset Hill", "Evening Garden"}', 0.015, 22, 'chimes.mp3', 'Sunset gleam',
 5.0, 'sunset_glow', '{"Evening Glory", "Sunset Flower"}', 'all', 'dusk',
 'Sunset Gleam butterflies paint the sky with their radiant evening colors.'),

('b23', 'Berry Bliss', 'assets/butterfly/butterfly23.webp', 'common',
 'Purple wings with the sweetness of fresh berries.',
 '{"Berry Patch", "Fruit Garden"}', 0.045, 23, 'chimes.mp3', 'Berryus bliss',
 3.8, 'berry_bounce', '{"Elderberry", "Blueberry Blossom"}', 'summer', 'morning',
 'Berry Bliss butterflies spread the joy of summer berry harvests.'),

('b24', 'Moonlit Dew', 'assets/butterfly/butterfly24.webp', 'epic',
 'Silver wings adorned with dewdrops that sparkle like diamonds.',
 '{"Moonlit Meadow", "Dew Garden"}', 0.010, 24, 'magical_chime.mp3', 'Luna dewdrop',
 5.6, 'dewdrop_dance', '{"Moon Daisy", "Silver Grass"}', 'all', 'dawn',
 'Moonlit Dew butterflies collect morning dew on their wings like precious jewels.'),

('b25', 'Tangerine Dream', 'assets/butterfly/butterfly25.webp', 'uncommon',
 'Vibrant orange wings full of citrus energy.',
 '{"Tangerine Grove", "Orange Garden"}', 0.025, 25, 'chimes.mp3', 'Citrus dream',
 4.3, 'citrus_swirl', '{"Orange Blossom", "Tangerine Flower"}', 'summer', 'afternoon',
 'Tangerine Dreams bring the zest and energy of fresh citrus to gardens.');

-- Insert remaining butterflies (b26-b90) with varied rarities and data
-- Note: This is a condensed version - in production you'd want full data for all 90
INSERT INTO butterfly_species (id, name, image_path, rarity, collection_order) VALUES
('b26', 'Crystal Prism', 'assets/butterfly/butterfly26.webp', 'rare', 26),
('b27', 'Ocean Spray', 'assets/butterfly/butterfly27.webp', 'common', 27),
('b28', 'Autumn Flame', 'assets/butterfly/butterfly28.webp', 'uncommon', 28),
('b29', 'Starlight Shimmer', 'assets/butterfly/butterfly29.webp', 'epic', 29),
('b30', 'Forest Whisper', 'assets/butterfly/butterfly30.webp', 'common', 30),
('b31', 'Ruby Flash', 'assets/butterfly/butterfly31.webp', 'legendary', 31),
('b32', 'Snow Crystal', 'assets/butterfly/butterfly32.webp', 'rare', 32),
('b33', 'Honey Glow', 'assets/butterfly/butterfly33.webp', 'uncommon', 33),
('b34', 'Mystic Purple', 'assets/butterfly/butterfly34.webp', 'epic', 34),
('b35', 'Dawn Light', 'assets/butterfly/butterfly35.webp', 'common', 35),
('b36', 'Copper Wing', 'assets/butterfly/butterfly36.webp', 'rare', 36),
('b37', 'Silver Moon', 'assets/butterfly/butterfly37.webp', 'legendary', 37),
('b38', 'Gentle Breeze', 'assets/butterfly/butterfly38.webp', 'common', 38),
('b39', 'Crimson Sunset', 'assets/butterfly/butterfly39.webp', 'uncommon', 39),
('b40', 'Azure Dream', 'assets/butterfly/butterfly40.webp', 'rare', 40),
('b41', 'Rainbow Mist', 'assets/butterfly/butterfly41.webp', 'epic', 41),
('b42', 'Vanilla Sky', 'assets/butterfly/butterfly42.webp', 'common', 42),
('b43', 'Cosmic Dust', 'assets/butterfly/butterfly43.webp', 'mythical', 43),
('b44', 'Mint Breeze', 'assets/butterfly/butterfly44.webp', 'uncommon', 44),
('b45', 'Golden Ray', 'assets/butterfly/butterfly45.webp', 'rare', 45),
('b46', 'Pink Paradise', 'assets/butterfly/butterfly46.webp', 'common', 46),
('b47', 'Storm Cloud', 'assets/butterfly/butterfly47.webp', 'epic', 47),
('b48', 'Pearly White', 'assets/butterfly/butterfly48.webp', 'uncommon', 48),
('b49', 'Fire Ember', 'assets/butterfly/butterfly49.webp', 'legendary', 49),
('b50', 'Spring Fresh', 'assets/butterfly/butterfly50.webp', 'common', 50),
('b51', 'Deep Ocean', 'assets/butterfly/butterfly51.webp', 'rare', 51),
('b52', 'Coral Pink', 'assets/butterfly/butterfly52.webp', 'uncommon', 52),
('b53', 'Solar Flare', 'assets/butterfly/butterfly53.webp', 'epic', 53),
('b54', 'Sage Green', 'assets/butterfly/butterfly54.webp', 'common', 54),
('b55', 'Amethyst Glow', 'assets/butterfly/butterfly55.webp', 'legendary', 55),
('b56', 'Cream Silk', 'assets/butterfly/butterfly56.webp', 'uncommon', 56),
('b57', 'Thunder Strike', 'assets/butterfly/butterfly57.webp', 'rare', 57),
('b58', 'Butter Yellow', 'assets/butterfly/butterfly58.webp', 'common', 58),
('b59', 'Galaxy Swirl', 'assets/butterfly/butterfly59.webp', 'mythical', 59),
('b60', 'Lime Zest', 'assets/butterfly/butterfly60.webp', 'uncommon', 60),
('b61', 'Midnight Blue', 'assets/butterfly/butterfly61.webp', 'epic', 61),
('b62', 'Rose Petal', 'assets/butterfly/butterfly62.webp', 'common', 62),
('b63', 'Diamond Dust', 'assets/butterfly/butterfly63.webp', 'legendary', 63),
('b64', 'Olive Branch', 'assets/butterfly/butterfly64.webp', 'uncommon', 64),
('b65', 'Neon Flash', 'assets/butterfly/butterfly65.webp', 'rare', 65),
('b66', 'Cotton Candy', 'assets/butterfly/butterfly66.webp', 'common', 66),
('b67', 'Nebula Storm', 'assets/butterfly/butterfly67.webp', 'epic', 67),
('b68', 'Copper Penny', 'assets/butterfly/butterfly68.webp', 'uncommon', 68),
('b69', 'Platinum Wing', 'assets/butterfly/butterfly69.webp', 'legendary', 69),
('b70', 'Meadow Green', 'assets/butterfly/butterfly70.webp', 'common', 70),
('b71', 'Electric Blue', 'assets/butterfly/butterfly71.webp', 'rare', 71),
('b72', 'Dusty Rose', 'assets/butterfly/butterfly72.webp', 'uncommon', 72),
('b73', 'Phoenix Fire', 'assets/butterfly/butterfly73.webp', 'mythical', 73),
('b74', 'Ice Crystal', 'assets/butterfly/butterfly74.webp', 'epic', 74),
('b75', 'Honey Amber', 'assets/butterfly/butterfly75.webp', 'common', 75),
('b76', 'Void Black', 'assets/butterfly/butterfly76.webp', 'legendary', 76),
('b77', 'Pastel Dream', 'assets/butterfly/butterfly77.webp', 'uncommon', 77),
('b78', 'Crimson Fire', 'assets/butterfly/butterfly78.webp', 'rare', 78),
('b79', 'Cloud Nine', 'assets/butterfly/butterfly79.webp', 'common', 79),
('b80', 'Aurora Lights', 'assets/butterfly/butterfly80.webp', 'epic', 80),
('b81', 'Bronze Shield', 'assets/butterfly/butterfly81.webp', 'uncommon', 81),
('b82', 'Titanium Wing', 'assets/butterfly/butterfly82.webp', 'legendary', 82),
('b83', 'Forest Moss', 'assets/butterfly/butterfly83.webp', 'common', 83),
('b84', 'Lightning Bolt', 'assets/butterfly/butterfly84.webp', 'rare', 84),
('b85', 'Soft Pink', 'assets/butterfly/butterfly85.webp', 'uncommon', 85),
('b86', 'Quantum Leap', 'assets/butterfly/butterfly86.webp', 'mythical', 86),
('b87', 'Prism Light', 'assets/butterfly/butterfly87.webp', 'epic', 87),
('b88', 'Earth Brown', 'assets/butterfly/butterfly88.webp', 'common', 88),
('b89', 'Stellar Wind', 'assets/butterfly/butterfly89.webp', 'legendary', 89),
('b90', 'Infinite Grace', 'assets/butterfly/butterfly90.webp', 'mythical', 90);

-- Update discovery chances based on rarity weights from configuration
UPDATE butterfly_species bs
SET discovery_chance = CASE 
    WHEN bs.rarity = 'common' THEN 0.045
    WHEN bs.rarity = 'uncommon' THEN 0.025
    WHEN bs.rarity = 'rare' THEN 0.015
    WHEN bs.rarity = 'epic' THEN 0.010
    WHEN bs.rarity = 'legendary' THEN 0.004
    WHEN bs.rarity = 'mythical' THEN 0.001
    ELSE 0.045
END;

-- Set appropriate audio effects based on rarity
UPDATE butterfly_species bs
SET audio_effect = CASE 
    WHEN bs.rarity IN ('common', 'uncommon', 'rare') THEN 'chimes.mp3'
    WHEN bs.rarity = 'epic' THEN 'magical_chime.mp3'
    WHEN bs.rarity = 'legendary' THEN 'legendary_bell.mp3'
    WHEN bs.rarity = 'mythical' THEN 'mythical_sparkle.mp3'
    ELSE 'chimes.mp3'
END;

-- Add some lore for the special butterflies that don't have it yet
UPDATE butterfly_species SET 
    lore = 'A magnificent creature of legend, rarely seen by mortal eyes.',
    description = 'One of the rarest butterflies in existence, holding ancient magic.'
WHERE rarity = 'mythical' AND lore IS NULL;

UPDATE butterfly_species SET 
    lore = 'A legendary butterfly of extraordinary beauty and power.',
    description = 'These majestic creatures are the stuff of legends.'
WHERE rarity = 'legendary' AND lore IS NULL;

UPDATE butterfly_species SET 
    lore = 'An epic butterfly with magical properties and stunning beauty.',
    description = 'Epic butterflies possess magical qualities that inspire awe.'
WHERE rarity = 'epic' AND lore IS NULL;
