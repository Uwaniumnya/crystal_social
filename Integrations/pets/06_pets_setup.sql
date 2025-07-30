-- =====================================================
-- CRYSTAL SOCIAL - PETS SYSTEM SETUP
-- =====================================================
-- Initial data and system configuration for pets
-- =====================================================

-- =====================================================
-- PET TEMPLATES SETUP
-- =====================================================

-- Function to create default pet templates
CREATE OR REPLACE FUNCTION create_default_pet_templates()
RETURNS VOID AS $$
BEGIN
    -- Insert pet templates based on actual available pets
    INSERT INTO pet_templates (
        pet_type, display_name, description, lore,
        base_asset_path, icon_asset_path,
        default_rarity, default_personality,
        base_stats, growth_rates,
        speech_lines, mood_speech,
        favorite_activities, disliked_activities,
        shop_price, shop_category, is_available_in_shop
    ) VALUES
    (
        'cat', 'Whiskers', 'A friendly and affectionate cat that loves attention and cuddles.',
        'Once a street cat who found warmth in human kindness, now a loyal companion.',
        'assets/pets/pets/real/cat/cat.png', 'assets/pets/icons/cat_icon.png',
        'common', 'friendly',
        '{"health": 100, "happiness": 100, "energy": 100}'::jsonb,
        '{"health": 1.0, "happiness": 1.2, "energy": 1.1}'::jsonb,
        ARRAY['Meow!', 'Purr...', 'Feed me!', 'Pet me!', 'I love you!'],
        '{"happy": "Purr purr! 😸", "sad": "Meow... 😿", "angry": "Hiss! 😾", "sleepy": "Yawn... meow... 😴", "playful": "Meow! Play with me! 🎾"}'::jsonb,
        ARRAY['petting', 'playing', 'sleeping'],
        ARRAY['bathing', 'loud_noises'],
        100.0, 'pet', true
    ),
    (
        'dog', 'Buddy', 'A loyal and energetic dog that loves companionship.',
        'A faithful companion who brings joy wherever he goes.',
        'assets/pets/pets/real/dog/dog.png', 'assets/pets/icons/dog_icon.png',
        'common', 'friendly',
        '{"health": 110, "happiness": 90, "energy": 120}'::jsonb,
        '{"health": 1.1, "happiness": 1.0, "energy": 1.3}'::jsonb,
        ARRAY['Woof!', 'Good boy!', 'Let''s play!', 'I love walks!'],
        '{"happy": "Wag wag! Arf! 🐕", "sad": "Whimper... 😢", "angry": "Growl! 😤", "sleepy": "Yawn... zzz... 😴", "playful": "Arf arf! Let''s play! 🎾"}'::jsonb,
        ARRAY['walking', 'fetching', 'playing'],
        ARRAY['being_alone', 'storms'],
        150.0, 'pet', true
    ),
    (
        'bunny', 'Cotton', 'An energetic bunny that loves to hop around and explore new places.',
        'Born under a full moon, this bunny brings joy wherever it hops.',
        'assets/pets/pets/real/bunny/bunny.png', 'assets/pets/icons/bunny_icon.png',
        'common', 'playful',
        '{"health": 90, "happiness": 110, "energy": 100}'::jsonb,
        '{"health": 0.9, "happiness": 1.3, "energy": 1.0}'::jsonb,
        ARRAY['Hop hop!', 'Carrot?', 'Binky time!', 'Sniff sniff', 'Boing!'],
        '{"happy": "Binky! Hop hop! 🐰", "sad": "Soft whimper... 😢", "angry": "Thump thump! 😤", "sleepy": "Zzz... twitch... 😴", "playful": "Boing boing! Chase me! 🏃‍♂️"}'::jsonb,
        ARRAY['hopping', 'eating', 'exploring'],
        ARRAY['loud_noises', 'being_picked_up'],
        200.0, 'pet', true
    ),
    (
        'axolotl', 'Bubbles', 'A mystical axolotl with incredible regenerative abilities.',
        'Ancient guardians of underwater realms, known for their healing powers.',
        'assets/pets/pets/real/axelotl/axelotl.png', 'assets/pets/icons/axolotl_icon.png',
        'rare', 'calm',
        '{"health": 120, "happiness": 80, "energy": 70}'::jsonb,
        '{"health": 1.5, "happiness": 0.8, "energy": 0.7}'::jsonb,
        ARRAY['Blub blub', 'Swimming...', 'Regenerating!', 'Aquatic life!', 'Underwater cutie'],
        '{"happy": "Blub blub! *happy wiggle* 🌊", "sad": "Sad bubbles... 💧", "angry": "Aggressive gill fluttering! �", "sleepy": "Floating dreams... 💤", "playful": "Underwater dance! 💃"}'::jsonb,
        ARRAY['swimming', 'resting', 'meditation'],
        ARRAY['dry_environments', 'stress'],
        800.0, 'rare_pet', true
    ),
    (
        'fox', 'Foxy', 'A clever and mischievous fox with ice-like fur patterns.',
        'Born from forest blizzards, this fox brings both wisdom and playful chaos.',
        'assets/pets/pets/real/fox/fox.png', 'assets/pets/icons/fox_icon.png',
        'rare', 'mischievous',
        '{"health": 95, "happiness": 105, "energy": 115}'::jsonb,
        '{"health": 1.0, "happiness": 1.1, "energy": 1.2}'::jsonb,
        ARRAY['Yip yip!', 'Clever fox!', 'Mischief time!', 'So sneaky!', 'Fox magic!'],
        '{"happy": "Yip yip! *tail wag* 🦊", "sad": "Whimper... *ears down* 😢", "angry": "Angry yip! *fur bristled* 😡", "sleepy": "Curled up zzz... 🌙", "playful": "Pounce! Let''s play! 🎮"}'::jsonb,
        ARRAY['exploring', 'puzzle_solving', 'night_walks'],
        ARRAY['water', 'being_ignored'],
        500.0, 'rare_pet', true
    ),
    (
        'panda', 'Bamboo', 'An adorable panda that loves bamboo and rolling around.',
        'Symbol of peace and tranquility, this panda brings calm energy.',
        'assets/pets/pets/real/panda/panda.png', 'assets/pets/icons/panda_icon.png',
        'epic', 'lazy',
        '{"health": 130, "happiness": 120, "energy": 80}'::jsonb,
        '{"health": 1.4, "happiness": 1.3, "energy": 0.8}'::jsonb,
        ARRAY['Munch munch', 'Bamboo please!', 'Rolling around', 'Lazy day'],
        '{"happy": "Happy munching! 🐼", "sleepy": "Rolling sleepily... 😴", "content": "Peaceful bamboo eating... 🎋", "lazy": "Just... five more minutes... 💤"}'::jsonb,
        ARRAY['eating_bamboo', 'rolling', 'sleeping'],
        ARRAY['fast_movement', 'loud_noises'],
        1500.0, 'epic_pet', true
    ),
    (
        'penguin', 'Waddles', 'A charming penguin that loves ice and fish.',
        'From the icy lands, this penguin brings arctic magic.',
        'assets/pets/pets/real/penguin/penguin.png', 'assets/pets/icons/penguin_icon.png',
        'rare', 'playful',
        '{"health": 100, "happiness": 110, "energy": 105}'::jsonb,
        '{"health": 1.1, "happiness": 1.2, "energy": 1.0}'::jsonb,
        ARRAY['Squawk!', 'Slide on ice!', 'Fish time!', 'Waddle waddle'],
        '{"happy": "Happy squawk! �", "playful": "Sliding fun! ⛸️", "content": "Peaceful waddle... �‍♂️", "excited": "Fish time! �"}'::jsonb,
        ARRAY['swimming', 'sliding', 'fish_hunting'],
        ARRAY['warm_weather', 'dry_land'],
        600.0, 'rare_pet', true
    ),
    (
        'raccoon', 'Bandit', 'A clever raccoon with a mask-like face and nimble paws.',
        'Master of midnight adventures and collector of treasures.',
        'assets/pets/pets/real/racoon/racoon.png', 'assets/pets/icons/raccoon_icon.png',
        'uncommon', 'mischievous',
        '{"health": 85, "happiness": 100, "energy": 110}'::jsonb,
        '{"health": 0.9, "happiness": 1.1, "energy": 1.2}'::jsonb,
        ARRAY['Chittering', 'Shiny things!', 'Wash wash', 'Midnight raid'],
        '{"happy": "Happy chittering! 🦝", "mischievous": "Sneaky grin... 😏", "excited": "Shiny treasure! ✨", "content": "Washing food... 🧼"}'::jsonb,
        ARRAY['foraging', 'collecting', 'washing_food'],
        ARRAY['daylight', 'empty_hands'],
        300.0, 'uncommon_pet', true
    ),
    (
        'elephant', 'Trunk', 'A wise elephant with an incredible memory.',
        'Ancient keeper of memories and guardian of wisdom.',
        'assets/pets/pets/real/elephant/elephant.png', 'assets/pets/icons/elephant_icon.png',
        'legendary', 'calm',
        '{"health": 200, "happiness": 110, "energy": 90}'::jsonb,
        '{"health": 2.0, "happiness": 1.2, "energy": 0.9}'::jsonb,
        ARRAY['Trumpet!', 'Never forget', 'Gentle giant', 'Memory keeper'],
        '{"happy": "Gentle trumpet! 🐘", "wise": "Ancient wisdom... 🧠", "protective": "Guardian stance! 🛡️", "content": "Peaceful grazing... 🌿"}'::jsonb,
        ARRAY['remembering', 'protecting', 'water_bathing'],
        ARRAY['forgetting', 'being_rushed'],
        5000.0, 'legendary_pet', true
    ),
    (
        'hedgehog', 'Spike', 'A small hedgehog with protective spines and a gentle heart.',
        'Guardian of garden secrets and midnight wanderer.',
        'assets/pets/pets/real/hedgehog/hedgehog.png', 'assets/pets/icons/hedgehog_icon.png',
        'uncommon', 'shy',
        '{"health": 70, "happiness": 90, "energy": 85}'::jsonb,
        '{"health": 0.8, "happiness": 1.0, "energy": 0.9}'::jsonb,
        ARRAY['Snort snort', 'Roll up!', 'Prickly but cute', 'Night explorer'],
        '{"happy": "Gentle snuffling! 🦔", "shy": "Curled up safely... 😊", "defensive": "Spines up! 🛡️", "content": "Peaceful foraging... 🌿"}'::jsonb,
        ARRAY['rolling_up', 'foraging', 'hiding'],
        ARRAY['predators', 'bright_lights'],
        250.0, 'uncommon_pet', true
    ),
    (
        'koala', 'Sleepy', 'A drowsy koala that spends most of its time sleeping.',
        'Dream keeper of the eucalyptus forests.',
        'assets/pets/pets/real/koala/koala.png', 'assets/pets/icons/koala_icon.png',
        'rare', 'lazy',
        '{"health": 90, "happiness": 100, "energy": 60}'::jsonb,
        '{"health": 1.0, "happiness": 1.1, "energy": 0.6}'::jsonb,
        ARRAY['Zzz...', 'Eucalyptus...', 'Just five more minutes', 'Sleepy time'],
        '{"sleepy": "Zzz... eucalyptus dreams... 💤", "content": "Peaceful tree hugging... 🌳", "lazy": "Too sleepy to move... 😴", "happy": "Drowsy contentment... 😊"}'::jsonb,
        ARRAY['sleeping', 'eating_eucalyptus', 'tree_hugging'],
        ARRAY['being_woken_up', 'activity'],
        700.0, 'rare_pet', true
    ),
    (
        'otter', 'Splash', 'A playful otter that loves water and floating on its back.',
        'Master of river games and aquatic acrobatics.',
        'assets/pets/pets/real/otter/otter.png', 'assets/pets/icons/otter_icon.png',
        'rare', 'playful',
        '{"health": 95, "happiness": 115, "energy": 110}'::jsonb,
        '{"health": 1.0, "happiness": 1.3, "energy": 1.2}'::jsonb,
        ARRAY['Squeaky!', 'Dive time!', 'Shell cracking', 'Float together'],
        '{"happy": "Playful squeaking! 🦦", "playful": "Diving fun! 🌊", "content": "Floating peacefully... 🛟", "social": "Playing together! 👥"}'::jsonb,
        ARRAY['swimming', 'diving', 'floating'],
        ARRAY['dry_land', 'being_alone'],
        650.0, 'rare_pet', true
    ),
    (
        'deer', 'Grace', 'An elegant deer with graceful movements and gentle eyes.',
        'Spirit of the forest, bringing peace and natural magic.',
        'assets/pets/pets/real/deer/deer.png', 'assets/pets/icons/deer_icon.png',
        'epic', 'calm',
        '{"health": 110, "happiness": 130, "energy": 120}'::jsonb,
        '{"health": 1.2, "happiness": 1.4, "energy": 1.3}'::jsonb,
        ARRAY['Gentle snort', 'Forest whisper', 'Graceful bound', 'Nature''s child'],
        '{"happy": "Gentle forest song... 🦌", "calm": "Peaceful grazing... 🌿", "graceful": "Elegant leaping! 🌸", "content": "Nature''s harmony... 🍃"}'::jsonb,
        ARRAY['grazing', 'forest_walks', 'leaping'],
        ARRAY['hunters', 'loud_noises'],
        1200.0, 'epic_pet', true
    ),
    (
        'dolphin', 'Echo', 'An intelligent dolphin with remarkable communication abilities.',
        'Ocean''s messenger, bridging the world between land and sea.',
        'assets/pets/pets/real/dolphin/dolphin.png', 'assets/pets/icons/dolphin_icon.png',
        'legendary', 'friendly',
        '{"health": 140, "happiness": 150, "energy": 160}'::jsonb,
        '{"health": 1.6, "happiness": 1.7, "energy": 1.8}'::jsonb,
        ARRAY['Click click!', 'Sonar ping', 'Jump high!', 'Ocean song'],
        '{"happy": "Joyful clicking! 🐬", "intelligent": "Sonar wisdom... �", "playful": "Spectacular jump! 🌊", "social": "Ocean friendship! �"}'::jsonb,
        ARRAY['jumping', 'echolocation', 'socializing'],
        ARRAY['shallow_water', 'captivity'],
        3000.0, 'legendary_pet', true
    ),
    (
        'seal', 'Flipper', 'A friendly seal that loves to perform and play.',
        'Entertainer of the seas, bringing joy to coastal waters.',
        'assets/pets/pets/real/seal/seal.png', 'assets/pets/icons/seal_icon.png',
        'uncommon', 'playful',
        '{"health": 100, "happiness": 120, "energy": 100}'::jsonb,
        '{"health": 1.1, "happiness": 1.3, "energy": 1.1}'::jsonb,
        ARRAY['Bark bark!', 'Clap clap', 'Fish please!', 'Sunbathing'],
        '{"happy": "Playful barking! 🦭", "performative": "Clap clap performance! 👏", "content": "Sunbathing bliss... ☀️", "hungry": "Fish time! 🐟"}'::jsonb,
        ARRAY['swimming', 'sunbathing', 'clapping'],
        ARRAY['cold_weather', 'no_fish'],
        400.0, 'uncommon_pet', true
    ),
    (
        'octopus', 'Inky', 'A clever octopus with color-changing abilities.',
        'Master of disguise and keeper of ocean mysteries.',
        'assets/pets/pets/real/octopus/octopus.png', 'assets/pets/icons/octopus_icon.png',
        'epic', 'mischievous',
        '{"health": 80, "happiness": 110, "energy": 130}'::jsonb,
        '{"health": 0.9, "happiness": 1.2, "energy": 1.4}'::jsonb,
        ARRAY['Gurgle', 'Eight arms ready!', 'Color change', 'Hidden treasure'],
        '{"happy": "Color-changing joy! 🌈", "mischievous": "Sneaky tentacles... �", "clever": "Problem-solving mode! 🧩", "hidden": "Master of disguise! 👤"}'::jsonb,
        ARRAY['hiding', 'color_changing', 'puzzle_solving'],
        ARRAY['bright_lights', 'open_spaces'],
        1800.0, 'epic_pet', true
    ),
    (
        'rat', 'Squeaky', 'A clever little rat with boundless energy and curiosity.',
        'Street-smart survivor who knows every secret passage.',
        'assets/pets/pets/real/rat/rat.png', 'assets/pets/icons/rat_icon.png',
        'common', 'energetic',
        '{"health": 70, "happiness": 80, "energy": 120}'::jsonb,
        '{"health": 0.8, "happiness": 0.9, "energy": 1.4}'::jsonb,
        ARRAY['Squeak squeak!', 'Cheese please!', 'Scurry time!', 'Quick and clever'],
        '{"happy": "Excited squeaking! 🐭", "energetic": "Scurrying around! 🏃‍♂️", "clever": "Problem solver! 🧠", "content": "Gentle grooming... 🧼"}'::jsonb,
        ARRAY['exploring', 'foraging', 'hiding'],
        ARRAY['cats', 'loud_noises'],
        80.0, 'pet', true
    ),
    (
        'sugar_glider', 'Glide', 'An adorable sugar glider that loves to glide from tree to tree.',
        'Nocturnal acrobat of the forest canopy.',
        'assets/pets/pets/real/sugar_glider/sugar_glider.png', 'assets/pets/icons/sugar_glider_icon.png',
        'rare', 'playful',
        '{"health": 75, "happiness": 125, "energy": 140}'::jsonb,
        '{"health": 0.8, "happiness": 1.4, "energy": 1.6}'::jsonb,
        ARRAY['Chirp chirp!', 'Gliding time!', 'Sweet treats!', 'Night flight'],
        '{"happy": "Joyful chirping! 🐿️", "playful": "Gliding adventure! ✈️", "social": "Colony bonding! 👥", "energetic": "Treetop acrobatics! 🤸‍♂️"}'::jsonb,
        ARRAY['gliding', 'climbing', 'socializing'],
        ARRAY['being_alone', 'daylight'],
        900.0, 'rare_pet', true
    ),
    (
        'fennec', 'Sandy', 'A tiny fennec fox with enormous ears and desert wisdom.',
        'Guardian of the desert sands, master of survival.',
        'assets/pets/pets/real/fennec/fennec.png', 'assets/pets/icons/fennec_icon.png',
        'rare', 'energetic',
        '{"health": 80, "happiness": 100, "energy": 130}'::jsonb,
        '{"health": 0.9, "happiness": 1.1, "energy": 1.5}'::jsonb,
        ARRAY['Yip!', 'Desert winds!', 'Big ears, big heart!', 'Sand runner'],
        '{"happy": "Desert yipping! 🦊", "energetic": "Sand runner! 🏃‍♂️", "alert": "Big ears listening! 👂", "content": "Desert peace... 🏜️"}'::jsonb,
        ARRAY['digging', 'night_hunting', 'listening'],
        ARRAY['cold_weather', 'water'],
        750.0, 'rare_pet', true
    ),
    (
        'honduran_bat', 'Echo', 'A gentle fruit bat with excellent night vision.',
        'Nighttime navigator and fruit forest guardian.',
        'assets/pets/pets/real/honduran_bat/honduran_bat.png', 'assets/pets/icons/bat_icon.png',
        'uncommon', 'shy',
        '{"health": 65, "happiness": 85, "energy": 125}'::jsonb,
        '{"health": 0.7, "happiness": 0.9, "energy": 1.4}'::jsonb,
        ARRAY['Screech!', 'Echolocation!', 'Night flight!', 'Fruit finder'],
        '{"happy": "Gentle chirping! 🦇", "shy": "Hanging quietly... 😌", "active": "Night flight! 🌙", "content": "Fruit feast! 🍇"}'::jsonb,
        ARRAY['flying', 'hanging_upside_down', 'fruit_eating'],
        ARRAY['bright_lights', 'loud_noises'],
        350.0, 'uncommon_pet', true
    ),
    (
        'cheetah', 'Dash', 'The fastest land animal with beautiful spotted fur.',
        'Born to run, master of speed and grace.',
        'assets/pets/pets/real/cheetah/cheetah.png', 'assets/pets/icons/cheetah_icon.png',
        'epic', 'energetic',
        '{"health": 120, "happiness": 100, "energy": 180}'::jsonb,
        '{"health": 1.3, "happiness": 1.1, "energy": 2.0}'::jsonb,
        ARRAY['Fast as lightning!', 'Speed demon!', 'Spotted beauty!', 'Race time!'],
        '{"happy": "Purring with speed! 🐆", "energetic": "Lightning fast! ⚡", "proud": "Spotted magnificence! ✨", "content": "Graceful rest... 😌"}'::jsonb,
        ARRAY['running', 'hunting', 'sunbathing'],
        ARRAY['slow_movement', 'cold_weather'],
        2500.0, 'epic_pet', true
    ),
    (
        'snake', 'Slither', 'A graceful snake with hypnotic movements.',
        'Ancient symbol of wisdom and transformation.',
        'assets/pets/pets/real/snake/snake.png', 'assets/pets/icons/snake_icon.png',
        'rare', 'calm',
        '{"health": 85, "happiness": 70, "energy": 90}'::jsonb,
        '{"health": 1.0, "happiness": 0.8, "energy": 1.0}'::jsonb,
        ARRAY['Hissss...', 'Silent hunter', 'Smooth scales', 'Serpent wisdom'],
        '{"happy": "Content hissing... 🐍", "calm": "Peaceful coiling... 🌀", "wise": "Ancient wisdom... 🧠", "sleepy": "Sunbathing rest... ☀️"}'::jsonb,
        ARRAY['sunbathing', 'hiding', 'meditation'],
        ARRAY['cold_weather', 'being_handled'],
        850.0, 'rare_pet', true
    )
    ON CONFLICT (pet_type) DO UPDATE SET
        display_name = EXCLUDED.display_name,
        description = EXCLUDED.description,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- PET ACCESSORIES SETUP
-- =====================================================

-- Function to create default pet accessories
CREATE OR REPLACE FUNCTION create_default_pet_accessories()
RETURNS VOID AS $$
BEGIN
    INSERT INTO pet_accessories (
        accessory_id, name, description, category, rarity,
        icon_asset_path, shop_price, shop_category,
        is_available_in_shop, stat_bonuses, special_effects
    ) VALUES
    -- Headwear - Royal and Fancy
    ('crown', 'Royal Crown', 'A golden crown fit for pet royalty', 'headwear', 'legendary',
     'assets/pets/accessories/crown.png', 500.0, 'premium_accessory', true,
     '{"happiness": 20, "bond_xp_multiplier": 1.2}'::jsonb, '{"royal_aura": true}'::jsonb),
    
    ('top_hat', 'Top Hat', 'A classy top hat for distinguished pets', 'headwear', 'epic',
     'assets/pets/accessories/top_hat.png', 300.0, 'premium_accessory', true,
     '{"style": 25, "confidence": 15}'::jsonb, '{"gentleman_charm": true}'::jsonb),
    
    ('gem_headpiece', 'Gem Headpiece', 'A sparkling headpiece with precious gems', 'headwear', 'epic',
     'assets/pets/accessories/gem_headpiece.png', 400.0, 'premium_accessory', true,
     '{"happiness": 15, "magic_power": 10}'::jsonb, '{"gem_sparkle": true}'::jsonb),
    
    ('stars_headpiece', 'Stars Headpiece', 'A mystical headpiece adorned with stars', 'headwear', 'rare',
     'assets/pets/accessories/stars_headpiece.png', 250.0, 'magical_accessory', true,
     '{"magic_power": 20, "luck": 10}'::jsonb, '{"star_power": true}'::jsonb),
    
    ('unicorn_horn', 'Unicorn Horn', 'A magical horn that grants mystical powers', 'headwear', 'mythical',
     'assets/pets/accessories/unicorn_horn.png', 1000.0, 'mythical_accessory', true,
     '{"magic_power": 50, "healing": 25}'::jsonb, '{"unicorn_magic": true, "purity_aura": true}'::jsonb),
    
    -- Headwear - Cute and Fun
    ('bow', 'Cute Bow', 'An adorable bow that makes any pet look fashionable', 'headwear', 'common',
     'assets/pets/accessories/bow.png', 25.0, 'accessory', true,
     '{"happiness": 5, "cuteness": 10}'::jsonb, '{}'::jsonb),
    
    ('bow_headband', 'Bow Headband', 'A stylish headband with a decorative bow', 'headwear', 'common',
     'assets/pets/accessories/bow_headband.png', 35.0, 'accessory', true,
     '{"happiness": 8, "style": 5}'::jsonb, '{}'::jsonb),
    
    ('cat_ears', 'Cat Ears', 'Cute cat ears for that feline charm', 'headwear', 'uncommon',
     'assets/pets/accessories/cat_ears.png', 50.0, 'accessory', true,
     '{"cuteness": 15, "agility": 5}'::jsonb, '{"feline_charm": true}'::jsonb),
    
    ('bunny_headset', 'Bunny Headset', 'Adorable bunny ears with a modern twist', 'headwear', 'uncommon',
     'assets/pets/accessories/bunny_headset.png', 75.0, 'accessory', true,
     '{"cuteness": 12, "energy": 8}'::jsonb, '{"bunny_hop": true}'::jsonb),
    
    ('bee_headpiece', 'Bee Headpiece', 'A buzzing bee-themed headpiece', 'headwear', 'uncommon',
     'assets/pets/accessories/bee_headpiece.png', 60.0, 'accessory', true,
     '{"energy": 10, "productivity": 15}'::jsonb, '{"busy_bee": true}'::jsonb),
    
    -- Eyewear
    ('glasses', 'Smart Glasses', 'Intellectual glasses for the scholarly pet', 'eyewear', 'uncommon',
     'assets/pets/accessories/glasses.png', 80.0, 'accessory', true,
     '{"intelligence": 20, "wisdom": 10}'::jsonb, '{"scholar_bonus": true}'::jsonb),
    
    ('sunglasses', 'Cool Sunglasses', 'Stylish sunglasses for the coolest pets', 'eyewear', 'uncommon',
     'assets/pets/accessories/sunglasses.png', 90.0, 'accessory', true,
     '{"coolness": 25, "confidence": 15}'::jsonb, '{"cool_factor": true}'::jsonb),
    
    ('heart_glasses', 'Heart Glasses', 'Adorable heart-shaped glasses', 'eyewear', 'rare',
     'assets/pets/accessories/heart_glasses.png', 120.0, 'accessory', true,
     '{"happiness": 20, "love": 15}'::jsonb, '{"love_vision": true}'::jsonb),
    
    -- Decorative Items
    ('flower_hairpiece', 'Flower Hairpiece', 'A delicate flower for natural beauty', 'decorative', 'common',
     'assets/pets/accessories/flower_hairpiece.png', 40.0, 'accessory', true,
     '{"natural_beauty": 15, "happiness": 8}'::jsonb, '{"nature_connection": true}'::jsonb),
    
    ('flower_crown', 'Flower Crown', 'A beautiful crown of fresh flowers', 'decorative', 'rare',
     'assets/pets/accessories/flower_crown.png', 150.0, 'accessory', true,
     '{"natural_beauty": 25, "happiness": 15}'::jsonb, '{"spring_blessing": true, "growth_boost": 1.3}'::jsonb),
    
    ('fish_clip', 'Fish Clip', 'A cute fish-shaped hair clip', 'decorative', 'common',
     'assets/pets/accessories/fish_clip.png', 30.0, 'accessory', true,
     '{"cuteness": 8, "aquatic_affinity": 5}'::jsonb, '{"fish_friend": true}'::jsonb),
    
    ('cloud_tattoo', 'Cloud Tattoo', 'A temporary cloud-themed tattoo', 'decorative', 'uncommon',
     'assets/pets/accessories/cloud_tattoo.png', 45.0, 'accessory', true,
     '{"dreamy": 10, "air_affinity": 8}'::jsonb, '{"cloud_walking": true}'::jsonb),
    
    -- Toy Accessories
    ('cupcake', 'Cupcake Toy', 'A sweet cupcake accessory for dessert lovers', 'toy', 'common',
     'assets/pets/accessories/cupcake.png', 20.0, 'accessory', true,
     '{"happiness": 12, "sweetness": 10}'::jsonb, '{"sugar_rush": true}'::jsonb),
    
    ('teddy', 'Teddy Bear', 'A comforting teddy bear companion', 'toy', 'uncommon',
     'assets/pets/accessories/teddy.png', 65.0, 'accessory', true,
     '{"comfort": 20, "security": 15}'::jsonb, '{"emotional_support": true}'::jsonb),
    
    ('tea', 'Tea Set', 'An elegant tea set for refined pets', 'toy', 'rare',
     'assets/pets/accessories/tea.png', 110.0, 'accessory', true,
     '{"elegance": 18, "social": 12}'::jsonb, '{"tea_party": true}'::jsonb),
    
    ('drink', 'Fancy Drink', 'A refreshing beverage accessory', 'toy', 'common',
     'assets/pets/accessories/drink.png', 25.0, 'accessory', true,
     '{"energy": 8, "refreshment": 10}'::jsonb, '{"hydration_boost": true}'::jsonb)
    
    ON CONFLICT (accessory_id) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- PET FOODS SETUP
-- =====================================================

-- Function to create default pet foods
CREATE OR REPLACE FUNCTION create_default_pet_foods()
RETURNS VOID AS $$
BEGIN
    INSERT INTO pet_foods (
        food_id, name, description, category,
        asset_path, health_boost, happiness_boost, energy_boost,
        hunger_reduction, preferred_by_types, rarity, shop_price
    ) VALUES
    -- Drinks
    ('water', 'Fresh Water', 'Clean, refreshing water essential for all pets', 'drinks',
     'assets/pets/food/drinks/water.png', 5, 2, 10, 15, ARRAY[]::TEXT[], 'common', 2.0),
    
    ('milk', 'Fresh Milk', 'Creamy, nutritious milk', 'drinks',
     'assets/pets/food/drinks/milk.png', 10, 8, 15, 20, ARRAY['cat', 'bunny']::TEXT[], 'common', 5.0),
    
    ('choco_milk', 'Chocolate Milk', 'Sweet chocolate milk for a treat', 'drinks',
     'assets/pets/food/drinks/choco_milk.png', 8, 15, 20, 18, ARRAY['bunny', 'dog']::TEXT[], 'uncommon', 8.0),
    
    ('orange_juice', 'Orange Juice', 'Fresh squeezed orange juice full of vitamins', 'drinks',
     'assets/pets/food/drinks/orange_juice.png', 12, 10, 25, 20, ARRAY[]::TEXT[], 'common', 6.0),
    
    ('coffee', 'Coffee', 'Energizing coffee for active pets', 'drinks',
     'assets/pets/food/drinks/coffee.png', 2, 5, 40, 10, ARRAY[]::TEXT[], 'uncommon', 12.0),
    
    ('tea', 'Herbal Tea', 'Calming herbal tea for relaxation', 'drinks',
     'assets/pets/food/drinks/tea.png', 8, 12, 5, 12, ARRAY['koala', 'deer']::TEXT[], 'common', 7.0),
    
    ('boba', 'Boba Tea', 'Fun bubble tea with chewy pearls', 'drinks',
     'assets/pets/food/drinks/boba.png', 6, 20, 15, 25, ARRAY[]::TEXT[], 'rare', 15.0),
    
    ('soda', 'Sparkling Soda', 'Fizzy and refreshing soda', 'drinks',
     'assets/pets/food/drinks/soda.png', 0, 15, 30, 20, ARRAY[]::TEXT[], 'common', 4.0),
    
    -- Fruits and Vegetables
    ('apple', 'Red Apple', 'Crisp and sweet apple', 'fruits_and_vegetables',
     'assets/pets/food/fruits_and_vegetables/apple.png', 12, 10, 12, 20, ARRAY['bunny', 'deer']::TEXT[], 'common', 4.0),
    
    ('carrot', 'Fresh Carrot', 'Crunchy orange carrot', 'fruits_and_vegetables',
     'assets/pets/food/fruits_and_vegetables/carrot.png', 8, 12, 8, 25, ARRAY['bunny', 'deer']::TEXT[], 'common', 3.0),
    
    ('banana', 'Banana', 'Sweet and potassium-rich banana', 'fruits_and_vegetables',
     'assets/pets/food/fruits_and_vegetables/banana.png', 10, 15, 20, 22, ARRAY[]::TEXT[], 'common', 5.0),
    
    ('strawberry', 'Strawberry', 'Sweet and juicy strawberry', 'fruits_and_vegetables',
     'assets/pets/food/fruits_and_vegetables/strawberry.png', 8, 18, 12, 18, ARRAY['bunny']::TEXT[], 'common', 6.0),
    
    ('watermelon', 'Watermelon', 'Refreshing watermelon slice', 'fruits_and_vegetables',
     'assets/pets/food/fruits_and_vegetables/watermelon.png', 15, 12, 8, 30, ARRAY[]::TEXT[], 'common', 7.0),
    
    ('blueberry', 'Blueberries', 'Antioxidant-rich blueberries', 'fruits_and_vegetables',
     'assets/pets/food/fruits_and_vegetables/blueberry.png', 12, 10, 15, 15, ARRAY[]::TEXT[], 'uncommon', 8.0),
    
    ('pineapple', 'Pineapple', 'Tropical pineapple chunks', 'fruits_and_vegetables',
     'assets/pets/food/fruits_and_vegetables/pineapple.png', 10, 20, 18, 25, ARRAY[]::TEXT[], 'uncommon', 10.0),
    
    ('avocado', 'Avocado', 'Creamy and nutritious avocado', 'fruits_and_vegetables',
     'assets/pets/food/fruits_and_vegetables/avocado.png', 20, 8, 10, 35, ARRAY[]::TEXT[], 'rare', 12.0),
    
    ('corn', 'Sweet Corn', 'Golden sweet corn kernels', 'fruits_and_vegetables',
     'assets/pets/food/fruits_and_vegetables/corn.png', 15, 10, 25, 30, ARRAY[]::TEXT[], 'common', 5.0),
    
    ('broccoli', 'Broccoli', 'Healthy green broccoli', 'fruits_and_vegetables',
     'assets/pets/food/fruits_and_vegetables/brocoli.png', 18, 5, 12, 28, ARRAY[]::TEXT[], 'common', 4.0),
    
    -- Meals
    ('pizza', 'Pizza Slice', 'Delicious pizza slice with toppings', 'meals',
     'assets/pets/food/meals/pizza.png', 25, 30, 20, 50, ARRAY[]::TEXT[], 'uncommon', 18.0),
    
    ('burger', 'Burger', 'Juicy burger with all the fixings', 'meals',
     'assets/pets/food/meals/burger.png', 30, 25, 35, 55, ARRAY['dog']::TEXT[], 'uncommon', 20.0),
    
    ('sushi', 'Sushi Roll', 'Fresh sushi roll with fish', 'meals',
     'assets/pets/food/meals/sushi.png', 20, 25, 15, 40, ARRAY['cat', 'penguin']::TEXT[], 'rare', 25.0),
    
    ('pasta', 'Spaghetti', 'Classic spaghetti with sauce', 'meals',
     'assets/pets/food/meals/sphagetti.png', 22, 20, 30, 45, ARRAY[]::TEXT[], 'common', 15.0),
    
    ('pancakes', 'Pancakes', 'Fluffy pancakes with syrup', 'meals',
     'assets/pets/food/meals/pancakes.png', 18, 35, 25, 40, ARRAY[]::TEXT[], 'uncommon', 16.0),
    
    ('eggs_bacon', 'Eggs and Bacon', 'Classic breakfast of eggs and bacon', 'meals',
     'assets/pets/food/meals/eggs_and_baacon.png', 25, 15, 30, 50, ARRAY['dog']::TEXT[], 'common', 14.0),
    
    ('salad', 'Fresh Salad', 'Healthy mixed green salad', 'meals',
     'assets/pets/food/meals/salad.png', 15, 8, 10, 35, ARRAY['bunny', 'deer']::TEXT[], 'common', 12.0),
    
    ('rice_bowl', 'Rice Bowl', 'Steaming bowl of rice', 'meals',
     'assets/pets/food/meals/rice_bowl.png', 20, 10, 35, 45, ARRAY[]::TEXT[], 'common', 10.0),
    
    ('taco', 'Taco', 'Tasty taco with fresh ingredients', 'meals',
     'assets/pets/food/meals/taco.png', 22, 22, 25, 42, ARRAY[]::TEXT[], 'uncommon', 17.0),
    
    ('beef_steak', 'Beef Steak', 'Premium grilled beef steak', 'meals',
     'assets/pets/food/meals/beef_steak.png', 35, 20, 25, 60, ARRAY['cheetah', 'dog']::TEXT[], 'rare', 30.0),
    
    -- Meat
    ('chicken_wing', 'Chicken Wing', 'Crispy chicken wing', 'meat',
     'assets/pets/food/meat/chicken_wing.png', 18, 15, 20, 35, ARRAY['cat', 'dog']::TEXT[], 'common', 12.0),
    
    ('bacon', 'Bacon Strips', 'Crispy bacon strips', 'meat',
     'assets/pets/food/meat/bacon.png', 15, 20, 25, 30, ARRAY['dog']::TEXT[], 'common', 10.0),
    
    ('steak', 'Grilled Steak', 'Perfectly grilled steak', 'meat',
     'assets/pets/food/meat/steak.png', 30, 15, 20, 50, ARRAY['cheetah', 'dog']::TEXT[], 'rare', 25.0),
    
    ('sausage', 'Sausage', 'Juicy grilled sausage', 'meat',
     'assets/pets/food/meat/sausage.png', 20, 18, 22, 40, ARRAY['dog']::TEXT[], 'common', 14.0),
    
    ('shrimp', 'Shrimp', 'Fresh cooked shrimp', 'meat',
     'assets/pets/food/meat/shrimp.png', 16, 12, 15, 28, ARRAY['cat', 'penguin', 'seal']::TEXT[], 'uncommon', 16.0),
    
    ('meatball', 'Meatball', 'Tender seasoned meatball', 'meat',
     'assets/pets/food/meat/meatball.png', 22, 16, 18, 38, ARRAY['dog']::TEXT[], 'common', 13.0),
    
    ('ribs', 'BBQ Ribs', 'Smoky barbecue ribs', 'meat',
     'assets/pets/food/meat/rib.png', 28, 25, 15, 55, ARRAY['dog', 'cheetah']::TEXT[], 'rare', 28.0),
    
    -- Sweets
    ('choco_cake', 'Chocolate Cake', 'Rich chocolate cake slice', 'sweets',
     'assets/pets/food/sweets/choco_cake.png', 10, 35, 20, 25, ARRAY[]::TEXT[], 'uncommon', 15.0),
    
    ('honey', 'Pure Honey', 'Sweet, golden honey', 'sweets',
     'assets/pets/food/sweets/honey.png', 5, 20, 25, 15, ARRAY['bunny', 'fox']::TEXT[], 'uncommon', 15.0),
    
    ('cookie', 'Cookie', 'Freshly baked cookie', 'sweets',
     'assets/pets/food/sweets/cookie.png', 8, 25, 15, 20, ARRAY[]::TEXT[], 'common', 8.0),
    
    ('donut', 'Donut', 'Glazed donut with sprinkles', 'sweets',
     'assets/pets/food/sweets/donut.png', 6, 30, 20, 22, ARRAY[]::TEXT[], 'common', 10.0),
    
    ('ice_cream', 'Vanilla Ice Cream', 'Creamy vanilla ice cream', 'sweets',
     'assets/pets/food/sweets/vanilla_ice_cream.png', 8, 28, 12, 20, ARRAY[]::TEXT[], 'uncommon', 12.0),
    
    ('cotton_candy', 'Cotton Candy', 'Fluffy pink cotton candy', 'sweets',
     'assets/pets/food/sweets/cotton_candy.png', 2, 35, 25, 15, ARRAY[]::TEXT[], 'rare', 18.0),
    
    ('lollipop', 'Lollipop', 'Colorful spiral lollipop', 'sweets',
     'assets/pets/food/sweets/lollipop.png', 3, 22, 18, 12, ARRAY[]::TEXT[], 'common', 6.0),
    
    ('muffin', 'Blueberry Muffin', 'Sweet blueberry muffin', 'sweets',
     'assets/pets/food/sweets/muffin.png', 12, 20, 22, 25, ARRAY[]::TEXT[], 'common', 9.0),
    
    ('pie', 'Apple Pie', 'Homemade apple pie slice', 'sweets',
     'assets/pets/food/sweets/pie.png', 15, 25, 18, 30, ARRAY[]::TEXT[], 'uncommon', 14.0),
    
    ('chocolate', 'Chocolate Bar', 'Rich dark chocolate bar', 'sweets',
     'assets/pets/food/sweets/chocolate.png', 5, 30, 20, 18, ARRAY[]::TEXT[], 'uncommon', 11.0)
    
    ON CONFLICT (food_id) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- PET ACTIVITIES SETUP
-- =====================================================

-- Function to create default pet activities
CREATE OR REPLACE FUNCTION create_default_pet_activities()
RETURNS VOID AS $$
BEGIN
    INSERT INTO pet_activities (
        activity_id, name, description, activity_type,
        difficulty_level, duration_seconds, energy_cost,
        base_happiness_reward, base_experience_reward, base_bond_xp_reward,
        minimum_pet_level, minimum_energy, cooldown_minutes
    ) VALUES
    ('fetch', 'Fetch Game', 'Classic fetch game with a ball or stick', 'mini_game',
     1, 60, 15.0, 12.0, 8, 5, 1, 20.0, 5),
    
    ('ball_catch', 'Ball Catch', 'Catch falling balls to score points', 'mini_game',
     2, 90, 20.0, 15.0, 12, 8, 3, 25.0, 10),
    
    ('memory_game', 'Memory Challenge', 'Test your pet''s memory with sequence games', 'mini_game',
     3, 120, 25.0, 18.0, 15, 10, 5, 30.0, 15),
    
    ('agility_course', 'Agility Training', 'Navigate through an obstacle course', 'exercise',
     3, 180, 35.0, 25.0, 20, 15, 8, 40.0, 20),
    
    ('treasure_hunt', 'Treasure Hunt', 'Search for hidden treasures and rewards', 'mini_game',
     4, 240, 30.0, 30.0, 25, 18, 10, 35.0, 25),
    
    ('petting_session', 'Gentle Petting', 'A relaxing petting and bonding session', 'interaction',
     1, 30, 5.0, 20.0, 3, 12, 1, 10.0, 2),
    
    ('grooming', 'Grooming Session', 'Keep your pet clean and beautiful', 'interaction',
     1, 45, 8.0, 15.0, 5, 8, 1, 15.0, 3),
    
    ('training_basic', 'Basic Training', 'Teach your pet basic commands and tricks', 'training',
     2, 150, 20.0, 10.0, 25, 20, 3, 25.0, 30),
    
    ('training_advanced', 'Advanced Training', 'Master complex tricks and behaviors', 'training',
     4, 300, 40.0, 15.0, 40, 35, 12, 45.0, 60),
    
    ('flying_practice', 'Flight Training', 'Practice flying skills for winged pets', 'exercise',
     3, 180, 45.0, 20.0, 30, 25, 8, 50.0, 40),
    
    ('magic_practice', 'Magic Training', 'Develop magical abilities and spells', 'training',
     5, 240, 35.0, 25.0, 35, 30, 15, 40.0, 45),
    
    ('swimming', 'Swimming Session', 'Aquatic exercise for water-loving pets', 'exercise',
     2, 120, 25.0, 18.0, 15, 12, 5, 30.0, 15),
    
    ('meditation', 'Peaceful Meditation', 'Calm the mind and restore inner peace', 'interaction',
     1, 90, 10.0, 25.0, 8, 15, 1, 15.0, 10),
    
    ('adventure', 'Mini Adventure', 'Explore mysterious locations and discover secrets', 'mini_game',
     5, 300, 50.0, 40.0, 50, 40, 20, 60.0, 120),
    
    ('social_play', 'Social Playtime', 'Play with other pets and make friends', 'interaction',
     2, 120, 20.0, 30.0, 12, 15, 3, 25.0, 20)
    
    ON CONFLICT (activity_id) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- PET ACHIEVEMENTS SETUP
-- =====================================================

-- Function to create default pet achievements
CREATE OR REPLACE FUNCTION create_default_pet_achievements()
RETURNS VOID AS $$
BEGIN
    INSERT INTO pet_achievements (
        achievement_id, name, description, category,
        requirement_type, requirement_data, difficulty_level,
        reward_experience, reward_bond_xp, reward_currency,
        badge_color, is_secret, is_repeatable
    ) VALUES
    ('first_pet', 'First Companion', 'Adopt your very first pet', 'collection',
     'pet_count', '{"target": 1}'::jsonb, 1, 50, 25, 100, 'bronze', false, false),
    
    ('pet_collector', 'Pet Collector', 'Own 5 different pets', 'collection',
     'pet_count', '{"target": 5}'::jsonb, 3, 200, 100, 500, 'silver', false, false),
    
    ('menagerie_master', 'Menagerie Master', 'Own 10 different pets', 'collection',
     'pet_count', '{"target": 10}'::jsonb, 5, 500, 250, 1000, 'gold', false, false),
    
    ('level_10', 'Growing Strong', 'Reach level 10 with any pet', 'care',
     'level_milestone', '{"target": 10}'::jsonb, 2, 100, 50, 200, 'bronze', false, false),
    
    ('level_25', 'Experienced Companion', 'Reach level 25 with any pet', 'care',
     'level_milestone', '{"target": 25}'::jsonb, 3, 250, 125, 500, 'silver', false, false),
    
    ('level_50', 'Master''s Pet', 'Reach level 50 with any pet', 'care',
     'level_milestone', '{"target": 50}'::jsonb, 4, 500, 250, 1000, 'gold', false, false),
    
    ('bond_master', 'Unbreakable Bond', 'Reach bond level 20 with any pet', 'bonding',
     'bond_milestone', '{"target": 20}'::jsonb, 3, 300, 200, 750, 'silver', false, false),
    
    ('daily_care', 'Daily Caretaker', 'Care for your pets for 7 consecutive days', 'care',
     'daily_streak', '{"target": 7}'::jsonb, 2, 150, 75, 300, 'bronze', false, true),
    
    ('feeding_expert', 'Feeding Expert', 'Feed your pets 100 times', 'care',
     'feeding_count', '{"target": 100}'::jsonb, 2, 100, 75, 250, 'bronze', false, false),
    
    ('perfect_feeder', 'Perfect Feeder', 'Achieve 10 perfect feeding reactions', 'care',
     'perfect_feeding', '{"target": 10}'::jsonb, 3, 200, 150, 500, 'silver', false, false),
    
    ('game_master', 'Mini-Game Master', 'Complete 50 mini-game sessions', 'training',
     'gaming_sessions', '{"target": 50}'::jsonb, 2, 150, 100, 400, 'bronze', false, false),
    
    ('high_performer', 'High Performer', 'Achieve 90%+ performance in 10 mini-games', 'training',
     'high_performance', '{"target": 10}'::jsonb, 4, 300, 200, 750, 'gold', false, false),
    
    ('social_butterfly', 'Social Butterfly', 'Make friends with 5 different pets', 'social',
     'friendships', '{"target": 5}'::jsonb, 3, 200, 150, 600, 'silver', false, false),
    
    ('breeding_novice', 'Breeding Novice', 'Successfully breed your first pet', 'breeding',
     'successful_breeding', '{"target": 1}'::jsonb, 3, 250, 200, 800, 'silver', false, false),
    
    ('rare_breeder', 'Rare Breeder', 'Breed a rare or higher rarity pet', 'breeding',
     'rare_offspring', '{"target": 1}'::jsonb, 4, 400, 300, 1200, 'gold', false, false),
    
    ('happiness_keeper', 'Happiness Keeper', 'Maintain 90%+ happiness for 24 hours', 'care',
     'happiness_maintenance', '{"target": 24}'::jsonb, 3, 180, 120, 450, 'silver', false, true),
    
    ('energy_manager', 'Energy Manager', 'Never let any pet''s energy drop below 20%', 'care',
     'energy_management', '{"target": 168}'::jsonb, 4, 300, 200, 700, 'gold', false, false),
    
    ('accessory_collector', 'Fashion Forward', 'Unlock 10 different accessories', 'collection',
     'accessory_collection', '{"target": 10}'::jsonb, 3, 200, 100, 500, 'silver', false, false),
    
    ('legendary_owner', 'Legendary Owner', 'Own a legendary or mythical pet', 'collection',
     'legendary_pet', '{"target": 1}'::jsonb, 5, 1000, 500, 2000, 'platinum', false, false),
    
    ('secret_discoverer', 'Secret Discoverer', 'Unlock a hidden pet or accessory', 'special',
     'secret_unlock', '{"target": 1}'::jsonb, 4, 500, 300, 1500, 'diamond', true, false),
    
    ('time_master', 'Time Master', 'Spend 100 hours caring for pets', 'care',
     'total_time', '{"target": 6000}'::jsonb, 4, 400, 250, 1000, 'gold', false, false),
    
    ('interaction_champion', 'Interaction Champion', 'Perform 1000 interactions with pets', 'care',
     'total_interactions', '{"target": 1000}'::jsonb, 3, 300, 200, 800, 'silver', false, false)
    
    ON CONFLICT (achievement_id) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- GENETIC TRAITS SETUP
-- =====================================================

-- Function to create default genetic traits
CREATE OR REPLACE FUNCTION create_default_genetic_traits()
RETURNS VOID AS $$
BEGIN
    INSERT INTO pet_genetic_traits (
        trait_id, name, description, category,
        inheritance_type, rarity_weight,
        stat_modifiers, appearance_changes, behavior_changes, special_abilities
    ) VALUES
    ('strong_constitution', 'Strong Constitution', 'Enhanced health and vitality', 'stats',
     'dominant', 0.3, '{"health": 1.2, "health_regeneration": 1.1}'::jsonb, '{}'::jsonb, '{}'::jsonb, '{}'::jsonb),
    
    ('joyful_spirit', 'Joyful Spirit', 'Naturally higher happiness levels', 'stats',
     'co_dominant', 0.4, '{"happiness": 1.15, "happiness_decay": 0.8}'::jsonb, '{}'::jsonb, '{"cheerful": true}'::jsonb, '{}'::jsonb),
    
    ('endless_energy', 'Endless Energy', 'Superior energy reserves', 'stats',
     'recessive', 0.2, '{"energy": 1.3, "energy_regeneration": 1.2}'::jsonb, '{}'::jsonb, '{"hyperactive": true}'::jsonb, '{}'::jsonb),
    
    ('golden_fur', 'Golden Fur', 'Beautiful golden coloring', 'appearance',
     'recessive', 0.15, '{}'::jsonb, '{"fur_color": "golden", "shine": true}'::jsonb, '{}'::jsonb, '{}'::jsonb),
    
    ('crystal_eyes', 'Crystal Eyes', 'Eyes that sparkle like crystals', 'appearance',
     'recessive', 0.1, '{}'::jsonb, '{"eye_type": "crystal", "sparkle": true}'::jsonb, '{}'::jsonb, '{"enhanced_vision": true}'::jsonb),
    
    ('rainbow_mane', 'Rainbow Mane', 'A mane with all colors of the rainbow', 'appearance',
     'recessive', 0.05, '{}'::jsonb, '{"mane_color": "rainbow", "magical_glow": true}'::jsonb, '{}'::jsonb, '{"color_magic": true}'::jsonb),
    
    ('gentle_soul', 'Gentle Soul', 'Naturally calm and peaceful demeanor', 'behavior',
     'dominant', 0.35, '{}'::jsonb, '{}'::jsonb, '{"gentle": true, "aggression": 0.5}'::jsonb, '{"calming_aura": true}'::jsonb),
    
    ('playful_nature', 'Playful Nature', 'Loves games and activities', 'behavior',
     'co_dominant', 0.4, '{}'::jsonb, '{}'::jsonb, '{"playful": true, "activity_bonus": 1.2}'::jsonb, '{}'::jsonb),
    
    ('loyal_heart', 'Loyal Heart', 'Unwavering loyalty and dedication', 'behavior',
     'dominant', 0.3, '{"bond_xp_multiplier": 1.3}'::jsonb, '{}'::jsonb, '{"loyal": true, "protective": true}'::jsonb, '{}'::jsonb),
    
    ('magic_affinity', 'Magic Affinity', 'Natural talent for magical abilities', 'special',
     'recessive', 0.1, '{"magic_power": 1.5}'::jsonb, '{"magical_aura": true}'::jsonb, '{"mystical": true}'::jsonb, '{"spell_casting": true, "magic_resistance": 0.5}'::jsonb),
    
    ('telepathic_bond', 'Telepathic Bond', 'Can communicate thoughts with owner', 'special',
     'recessive', 0.05, '{"bond_xp_multiplier": 2.0}'::jsonb, '{"glowing_eyes": true}'::jsonb, '{"telepathic": true}'::jsonb, '{"mind_link": true, "emotion_sharing": true}'::jsonb),
    
    ('shapeshifter', 'Shapeshifter', 'Ability to temporarily change appearance', 'special',
     'recessive', 0.02, '{}'::jsonb, '{"changeable": true}'::jsonb, '{"mysterious": true}'::jsonb, '{"shape_change": true, "illusion": true}'::jsonb),
    
    ('time_walker', 'Time Walker', 'Exists slightly outside normal time flow', 'special',
     'recessive', 0.01, '{"all_stats": 1.1, "aging": 0.5}'::jsonb, '{"temporal_shimmer": true}'::jsonb, '{"wise": true, "ancient": true}'::jsonb, '{"time_manipulation": true, "prophecy": true}'::jsonb),
    
    ('elemental_fire', 'Fire Elemental', 'Affinity with fire and heat', 'special',
     'recessive', 0.08, '{"fire_resistance": 1.0}'::jsonb, '{"flame_markings": true, "warm_glow": true}'::jsonb, '{"fiery": true}'::jsonb, '{"fire_magic": true, "heat_immunity": true}'::jsonb),
    
    ('elemental_water', 'Water Elemental', 'Affinity with water and ice', 'special',
     'recessive', 0.08, '{"water_resistance": 1.0}'::jsonb, '{"wave_patterns": true, "cool_aura": true}'::jsonb, '{"fluid": true}'::jsonb, '{"water_magic": true, "aquatic_breathing": true}'::jsonb),
    
    ('star_blessed', 'Star Blessed', 'Touched by cosmic forces', 'special',
     'recessive', 0.03, '{"all_stats": 1.2, "luck": 2.0}'::jsonb, '{"star_markings": true, "celestial_glow": true}'::jsonb, '{"cosmic": true, "wise": true}'::jsonb, '{"cosmic_magic": true, "stellar_communication": true}'::jsonb)
    
    ON CONFLICT (trait_id) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- USER ONBOARDING FUNCTION
-- =====================================================

-- Complete onboarding function for new pet owners
CREATE OR REPLACE FUNCTION setup_user_pet_system(p_user_id UUID)
RETURNS UUID AS $$
DECLARE
    v_starter_pet_id UUID;
BEGIN
    -- Create user pet settings
    INSERT INTO user_pet_settings (user_id)
    VALUES (p_user_id)
    ON CONFLICT (user_id) DO NOTHING;
    
    -- Give user a starter pet (cat)
    v_starter_pet_id := create_user_pet(
        p_user_id,
        'cat',
        'Whiskers',
        'common',
        'friendly'
    );
    
    -- Give some basic accessories
    INSERT INTO user_pet_accessories (user_id, accessory_id, unlock_method)
    SELECT p_user_id, id, 'starter_pack'
    FROM pet_accessories
    WHERE accessory_id IN ('bow', 'collar', 'scarf')
    ON CONFLICT (user_id, accessory_id) DO NOTHING;
    
    -- Initialize some achievement progress
    INSERT INTO user_pet_achievements (user_id, achievement_id, target_progress, current_progress)
    SELECT p_user_id, id, 
           (requirement_data->>'target')::DECIMAL,
           CASE WHEN achievement_id = 'first_pet' THEN 1 ELSE 0 END
    FROM pet_achievements
    WHERE achievement_id IN ('first_pet', 'level_10', 'daily_care', 'feeding_expert', 'game_master')
    ON CONFLICT (user_id, achievement_id, user_pet_id) DO NOTHING;
    
    -- Complete the first pet achievement
    UPDATE user_pet_achievements 
    SET is_completed = true, completed_at = NOW()
    WHERE user_id = p_user_id AND achievement_id = 'first_pet';
    
    RETURN v_starter_pet_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- SYSTEM INITIALIZATION
-- =====================================================

-- Create all default data
SELECT create_default_pet_templates();
SELECT create_default_pet_accessories();
SELECT create_default_pet_foods();
SELECT create_default_pet_activities();
SELECT create_default_pet_achievements();
SELECT create_default_genetic_traits();

-- =====================================================
-- MAINTENANCE FUNCTIONS
-- =====================================================

-- Function to update pet system statistics
CREATE OR REPLACE FUNCTION update_pet_system_statistics()
RETURNS TABLE(
    total_pets INTEGER,
    active_pets INTEGER,
    total_users INTEGER,
    daily_interactions INTEGER,
    completed_achievements INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*)::INTEGER FROM user_pets) as total_pets,
        (SELECT COUNT(*)::INTEGER FROM user_pets WHERE last_active_at > NOW() - INTERVAL '7 days') as active_pets,
        (SELECT COUNT(DISTINCT user_id)::INTEGER FROM user_pets) as total_users,
        (SELECT COALESCE(SUM(interactions_count), 0)::INTEGER FROM pet_daily_stats WHERE date = CURRENT_DATE) as daily_interactions,
        (SELECT COUNT(*)::INTEGER FROM user_pet_achievements WHERE completed_at::DATE = CURRENT_DATE) as completed_achievements;
END;
$$ LANGUAGE plpgsql;

-- Function to get system health status
CREATE OR REPLACE FUNCTION get_pet_system_health()
RETURNS TABLE(
    metric_name TEXT,
    metric_value DECIMAL,
    status TEXT,
    description TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'average_pet_health'::TEXT,
        ROUND(AVG(health), 2),
        CASE WHEN AVG(health) > 80 THEN 'excellent' WHEN AVG(health) > 60 THEN 'good' ELSE 'needs_attention' END,
        'Average health of all pets'::TEXT
    FROM user_pets
    
    UNION ALL
    
    SELECT 
        'average_pet_happiness'::TEXT,
        ROUND(AVG(happiness), 2),
        CASE WHEN AVG(happiness) > 80 THEN 'excellent' WHEN AVG(happiness) > 60 THEN 'good' ELSE 'needs_attention' END,
        'Average happiness of all pets'::TEXT
    FROM user_pets
    
    UNION ALL
    
    SELECT 
        'pets_needing_attention'::TEXT,
        COUNT(*)::DECIMAL,
        CASE WHEN COUNT(*) < 100 THEN 'good' WHEN COUNT(*) < 500 THEN 'moderate' ELSE 'high' END,
        'Number of pets with urgent care needs'::TEXT
    FROM pets_enriched
    WHERE care_urgency >= 3
    
    UNION ALL
    
    SELECT 
        'daily_activity_rate'::TEXT,
        ROUND(AVG(interactions_count), 2),
        CASE WHEN AVG(interactions_count) > 5 THEN 'excellent' WHEN AVG(interactions_count) > 2 THEN 'good' ELSE 'low' END,
        'Average daily interactions per pet'::TEXT
    FROM pet_daily_stats
    WHERE date = CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- GRANT PERMISSIONS ON SETUP FUNCTIONS
-- =====================================================

GRANT EXECUTE ON FUNCTION setup_user_pet_system(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_default_pet_templates() TO service_role;
GRANT EXECUTE ON FUNCTION create_default_pet_accessories() TO service_role;
GRANT EXECUTE ON FUNCTION create_default_pet_foods() TO service_role;
GRANT EXECUTE ON FUNCTION create_default_pet_activities() TO service_role;
GRANT EXECUTE ON FUNCTION create_default_pet_achievements() TO service_role;
GRANT EXECUTE ON FUNCTION create_default_genetic_traits() TO service_role;
GRANT EXECUTE ON FUNCTION update_pet_system_statistics() TO authenticated;
GRANT EXECUTE ON FUNCTION get_pet_system_health() TO authenticated;
