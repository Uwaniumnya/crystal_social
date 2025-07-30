-- =====================================================
-- CRYSTAL SOCIAL - PROFILE SYSTEM SETUP
-- =====================================================
-- Initial data and system configuration for profiles
-- =====================================================

-- =====================================================
-- AVATAR DECORATIONS CATALOG SETUP
-- =====================================================

-- Function to create default avatar decorations
CREATE OR REPLACE FUNCTION create_default_avatar_decorations()
RETURNS VOID AS $$
BEGIN
    INSERT INTO avatar_decorations_catalog (
        decoration_id, name, description, category, image_path, icon_emoji, 
        rarity, cost, is_premium, special_effects
    ) VALUES
    
    -- Cute Animals Category
    ('cat_white', 'White Cat', 'Adorable white cat animation that adds charm to your avatar', 'cute', 
     'assets/decorations/Cat_White.gif', '🐱', 'common', 0, false, '{"animation": "gentle_bounce"}'::jsonb),
    
    ('dog_brown_white', 'Brown Dog', 'Playful brown and white dog that shows your friendly nature', 'cute', 
     'assets/decorations/Dog_Brown_&_White.gif', '🐕', 'common', 0, false, '{"animation": "tail_wag"}'::jsonb),
    
    ('pink_cat', 'Pink Cat', 'Sweet pink cat decoration for those who love all things cute', 'cute', 
     'assets/decorations/pink_cat.gif', '🐱', 'common', 50, false, '{"glow": "soft_pink"}'::jsonb),
    
    ('black_cat', 'Black Cat', 'Mysterious black cat that brings good luck', 'cute', 
     'assets/decorations/black_cat.gif', '🐈‍⬛', 'uncommon', 100, false, '{"mystery_aura": true}'::jsonb),
    
    ('kitten', 'Playful Kitten', 'An energetic kitten that loves to play', 'cute', 
     'assets/decorations/kitten.gif', '🐾', 'common', 75, false, '{"playful_bounce": true}'::jsonb),
    
    ('bunny', 'Cute Bunny', 'Adorable bunny that hops around your avatar', 'cute', 
     'assets/decorations/bunny.gif', '🐰', 'common', 60, false, '{"hop_animation": true}'::jsonb),
    
    ('easter_bunny', 'Easter Bunny', 'Special seasonal bunny for Easter celebrations', 'cute', 
     'assets/decorations/easter_bunny.gif', '🐰', 'rare', 200, false, 
     '{"seasonal": true, "sparkles": "pastel"}'::jsonb),
    
    ('bear_frame', 'Bear Frame', 'Cozy bear frame that hugs your avatar', 'cute', 
     'assets/decorations/bear_frame.gif', '🐻', 'common', 80, false, '{"warm_glow": true}'::jsonb),
    
    ('pink_bear_frame', 'Pink Bear', 'Soft pink teddy bear for extra cuteness', 'cute', 
     'assets/decorations/pink_bear_frame.gif', '🧸', 'uncommon', 120, false, 
     '{"cuddle_aura": true, "soft_glow": "pink"}'::jsonb),
    
    ('gummy_bears', 'Gummy Bears', 'Colorful gummy bears dancing around your avatar', 'cute', 
     'assets/decorations/gummy_bears.gif', '🧸', 'rare', 150, false, 
     '{"rainbow_sparkles": true, "dance_animation": true}'::jsonb),
    
    -- Hearts & Love Category
    ('heart', 'Heart', 'Classic animated heart showing your loving nature', 'love', 
     'assets/decorations/heart.gif', '💖', 'common', 25, false, '{"pulse_animation": true}'::jsonb),
    
    ('hearts', 'Multiple Hearts', 'Floating hearts that show extra love', 'love', 
     'assets/decorations/hearts.gif', '💕', 'common', 40, false, '{"floating_hearts": true}'::jsonb),
    
    ('pink_heart', 'Pink Heart', 'Soft pink heart with gentle glow', 'love', 
     'assets/decorations/pink_heart.gif', '💗', 'common', 35, false, '{"soft_glow": "pink"}'::jsonb),
    
    ('heart_eyes', 'Heart Eyes', 'Express your love with heart-shaped eyes', 'love', 
     'assets/decorations/heart_eyes.gif', '😍', 'uncommon', 90, false, '{"love_beam": true}'::jsonb),
    
    ('cupid_arrow', 'Cupid Arrow', 'Magical arrow from Cupid for true love', 'love', 
     'assets/decorations/cupid_arrow.gif', '💘', 'rare', 180, false, 
     '{"magic_sparkles": true, "love_magic": true}'::jsonb),
    
    -- Sparkles & Magic Category
    ('sparkles', 'Sparkles', 'Magical sparkles that make everything shimmer', 'sparkles', 
     'assets/decorations/sparkles.gif', '✨', 'common', 30, false, '{"shimmer_effect": true}'::jsonb),
    
    ('stars', 'Stars', 'Twinkling stars that light up your avatar', 'sparkles', 
     'assets/decorations/stars.gif', '⭐', 'common', 45, false, '{"twinkle_animation": true}'::jsonb),
    
    ('magic_wand', 'Magic Wand', 'Enchanted wand for casting spells', 'sparkles', 
     'assets/decorations/magic_wand.gif', '🪄', 'epic', 300, true, 
     '{"spell_casting": true, "magic_particles": true}'::jsonb),
    
    ('rainbow', 'Rainbow', 'Beautiful rainbow arc full of colors', 'sparkles', 
     'assets/decorations/rainbow.gif', '🌈', 'rare', 220, false, 
     '{"color_shift": true, "rainbow_glow": true}'::jsonb),
    
    ('fairy_dust', 'Fairy Dust', 'Magical fairy dust that grants wishes', 'sparkles', 
     'assets/decorations/fairy_dust.gif', '🧚', 'legendary', 500, true, 
     '{"wish_granting": true, "ethereal_glow": true}'::jsonb),
    
    -- Nature Category
    ('flower_crown', 'Flower Crown', 'Beautiful crown made of fresh flowers', 'nature', 
     'assets/decorations/flower_crown.gif', '🌸', 'uncommon', 110, false, 
     '{"natural_beauty": true, "seasonal_bloom": true}'::jsonb),
    
    ('butterfly', 'Butterfly', 'Graceful butterfly that dances around you', 'nature', 
     'assets/decorations/butterfly.gif', '🦋', 'rare', 160, false, 
     '{"flutter_animation": true, "garden_magic": true}'::jsonb),
    
    ('cherry_blossoms', 'Cherry Blossoms', 'Delicate cherry blossom petals falling gently', 'nature', 
     'assets/decorations/cherry_blossoms.gif', '🌸', 'rare', 180, false, 
     '{"petal_fall": true, "spring_essence": true}'::jsonb),
    
    ('sunflower', 'Sunflower', 'Bright sunflower that follows the light', 'nature', 
     'assets/decorations/sunflower.gif', '🌻', 'uncommon', 95, false, 
     '{"sun_tracking": true, "warm_glow": "yellow"}'::jsonb),
    
    -- Premium Category
    ('crown_gold', 'Golden Crown', 'Majestic golden crown fit for royalty', 'premium', 
     'assets/decorations/crown_gold.gif', '👑', 'legendary', 1000, true, 
     '{"royal_aura": true, "golden_glow": true, "prestige_boost": 50}'::jsonb),
    
    ('diamond_ring', 'Diamond Ring', 'Sparkling diamond ring showing luxury', 'premium', 
     'assets/decorations/diamond_ring.gif', '💎', 'epic', 750, true, 
     '{"diamond_sparkle": true, "luxury_aura": true}'::jsonb),
    
    ('angel_halo', 'Angel Halo', 'Divine halo showing your pure heart', 'premium', 
     'assets/decorations/angel_halo.gif', '😇', 'epic', 600, true, 
     '{"divine_light": true, "blessing_aura": true}'::jsonb),
    
    ('phoenix_flame', 'Phoenix Flame', 'Mythical phoenix flame of rebirth', 'premium', 
     'assets/decorations/phoenix_flame.gif', '🔥', 'mythical', 2000, true, 
     '{"rebirth_power": true, "eternal_flame": true, "legendary_aura": true}'::jsonb)
    
    ON CONFLICT (decoration_id) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- PROFILE THEMES SETUP
-- =====================================================

-- Function to create default profile themes
CREATE OR REPLACE FUNCTION create_default_profile_themes()
RETURNS VOID AS $$
BEGIN
    INSERT INTO profile_themes (
        theme_id, name, description, preview_image, category,
        color_scheme, typography, layout_config, cost
    ) VALUES
    
    ('default', 'Crystal Default', 'Clean and modern default theme', 
     'assets/themes/default_preview.png', 'general',
     '{"primary": "#6366f1", "secondary": "#8b5cf6", "accent": "#06b6d4", "background": "#f8fafc"}'::jsonb,
     '{"font_family": "Inter", "heading_size": "24px", "body_size": "16px"}'::jsonb,
     '{"layout": "modern", "card_style": "elevated", "spacing": "comfortable"}'::jsonb, 0),
    
    ('dark_mode', 'Dark Crystal', 'Sleek dark theme for night owls', 
     'assets/themes/dark_preview.png', 'general',
     '{"primary": "#818cf8", "secondary": "#a78bfa", "accent": "#22d3ee", "background": "#0f172a"}'::jsonb,
     '{"font_family": "Inter", "heading_size": "24px", "body_size": "16px"}'::jsonb,
     '{"layout": "modern", "card_style": "dark", "spacing": "cozy"}'::jsonb, 0),
    
    ('nature_green', 'Forest Dreams', 'Peaceful green theme inspired by nature', 
     'assets/themes/nature_preview.png', 'general',
     '{"primary": "#10b981", "secondary": "#34d399", "accent": "#fbbf24", "background": "#f0fdf4"}'::jsonb,
     '{"font_family": "Poppins", "heading_size": "26px", "body_size": "16px"}'::jsonb,
     '{"layout": "organic", "card_style": "natural", "spacing": "breathable"}'::jsonb, 100),
    
    ('ocean_blue', 'Ocean Depths', 'Calming blue theme like deep ocean waters', 
     'assets/themes/ocean_preview.png', 'general',
     '{"primary": "#0ea5e9", "secondary": "#38bdf8", "accent": "#f59e0b", "background": "#f0f9ff"}'::jsonb,
     '{"font_family": "Nunito", "heading_size": "25px", "body_size": "16px"}'::jsonb,
     '{"layout": "fluid", "card_style": "wave", "spacing": "flowing"}'::jsonb, 150),
    
    ('sunset_orange', 'Sunset Glow', 'Warm orange theme like a beautiful sunset', 
     'assets/themes/sunset_preview.png', 'general',
     '{"primary": "#f97316", "secondary": "#fb923c", "accent": "#eab308", "background": "#fffbeb"}'::jsonb,
     '{"font_family": "Quicksand", "heading_size": "24px", "body_size": "16px"}'::jsonb,
     '{"layout": "warm", "card_style": "glowing", "spacing": "cozy"}'::jsonb, 120),
    
    ('royal_purple', 'Royal Majesty', 'Elegant purple theme for those who love luxury', 
     'assets/themes/royal_preview.png', 'premium',
     '{"primary": "#7c3aed", "secondary": "#a855f7", "accent": "#fbbf24", "background": "#faf5ff"}'::jsonb,
     '{"font_family": "Playfair Display", "heading_size": "28px", "body_size": "17px"}'::jsonb,
     '{"layout": "elegant", "card_style": "luxury", "spacing": "refined"}'::jsonb, 300),
    
    ('cherry_blossom', 'Cherry Blossom', 'Delicate pink theme inspired by spring', 
     'assets/themes/cherry_preview.png', 'seasonal',
     '{"primary": "#ec4899", "secondary": "#f472b6", "accent": "#10b981", "background": "#fdf2f8"}'::jsonb,
     '{"font_family": "Dancing Script", "heading_size": "26px", "body_size": "16px"}'::jsonb,
     '{"layout": "delicate", "card_style": "petals", "spacing": "airy"}'::jsonb, 200),
    
    ('galaxy', 'Cosmic Galaxy', 'Mysterious space theme with cosmic colors', 
     'assets/themes/galaxy_preview.png', 'premium',
     '{"primary": "#312e81", "secondary": "#6366f1", "accent": "#e879f9", "background": "#1e1b4b"}'::jsonb,
     '{"font_family": "Orbitron", "heading_size": "24px", "body_size": "16px"}'::jsonb,
     '{"layout": "cosmic", "card_style": "stellar", "spacing": "infinite"}'::jsonb, 500),
    
    ('autumn_leaves', 'Autumn Leaves', 'Warm autumn theme with golden colors', 
     'assets/themes/autumn_preview.png', 'seasonal',
     '{"primary": "#d97706", "secondary": "#f59e0b", "accent": "#dc2626", "background": "#fffbeb"}'::jsonb,
     '{"font_family": "Merriweather", "heading_size": "25px", "body_size": "16px"}'::jsonb,
     '{"layout": "rustic", "card_style": "leaves", "spacing": "harvest"}'::jsonb, 180),
    
    ('winter_frost', 'Winter Frost', 'Cool winter theme with icy blues and whites', 
     'assets/themes/winter_preview.png', 'seasonal',
     '{"primary": "#0891b2", "secondary": "#06b6d4", "accent": "#64748b", "background": "#f1f5f9"}'::jsonb,
     '{"font_family": "Montserrat", "heading_size": "24px", "body_size": "16px"}'::jsonb,
     '{"layout": "crisp", "card_style": "frost", "spacing": "arctic"}'::jsonb, 160)
    
    ON CONFLICT (theme_id) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- PROFILE ACHIEVEMENTS SETUP
-- =====================================================

-- Function to create default profile achievements
CREATE OR REPLACE FUNCTION create_default_profile_achievements()
RETURNS VOID AS $$
BEGIN
    INSERT INTO profile_achievements (
        achievement_id, name, description, category, requirement_type, requirement_data,
        difficulty_level, experience_reward, reputation_reward, currency_reward,
        unlock_rewards, badge_color, is_secret
    ) VALUES
    
    -- Profile Completion Achievements
    ('profile_created', 'Welcome Aboard!', 'Successfully create your profile', 'profile_completion',
     'profile_creation', '{"target": 1}'::jsonb, 1, 50, 5, 100, 
     ARRAY['decoration_sparkles'], 'bronze', false),
    
    ('profile_half_complete', 'Getting Started', 'Complete 50% of your profile', 'profile_completion',
     'completion_percentage', '{"target": 50}'::jsonb, 2, 100, 10, 200,
     ARRAY['decoration_heart'], 'bronze', false),
    
    ('profile_mostly_complete', 'Almost There', 'Complete 80% of your profile', 'profile_completion',
     'completion_percentage', '{"target": 80}'::jsonb, 3, 200, 20, 300,
     ARRAY['decoration_stars'], 'silver', false),
    
    ('profile_complete', 'Perfectionist', 'Complete 100% of your profile', 'profile_completion',
     'completion_percentage', '{"target": 100}'::jsonb, 3, 500, 50, 500,
     ARRAY['decoration_crown_gold'], 'gold', false),
    
    ('avatar_decorator', 'Style Icon', 'Equip your first avatar decoration', 'profile_completion',
     'decoration_equipped', '{"target": 1}'::jsonb, 2, 75, 15, 150,
     ARRAY['theme_nature_green'], 'bronze', false),
    
    ('theme_changer', 'Theme Explorer', 'Change your profile theme for the first time', 'profile_completion',
     'theme_changed', '{"target": 1}'::jsonb, 2, 75, 15, 150,
     ARRAY['decoration_rainbow'], 'bronze', false),
    
    -- Social Achievements
    ('first_friend', 'Making Friends', 'Make your first friend connection', 'social',
     'friend_count', '{"target": 1}'::jsonb, 2, 100, 20, 200,
     ARRAY['decoration_hearts'], 'bronze', false),
    
    ('social_butterfly', 'Social Butterfly', 'Connect with 10 friends', 'social',
     'friend_count', '{"target": 10}'::jsonb, 3, 300, 30, 600,
     ARRAY['decoration_butterfly'], 'silver', false),
    
    ('community_member', 'Community Member', 'Connect with 25 friends', 'social',
     'friend_count', '{"target": 25}'::jsonb, 4, 500, 50, 1000,
     ARRAY['decoration_flower_crown'], 'gold', false),
    
    ('social_hub', 'Social Hub', 'Connect with 50 friends', 'social',
     'friend_count', '{"target": 50}'::jsonb, 5, 1000, 100, 2000,
     ARRAY['decoration_angel_halo'], 'diamond', false),
    
    ('first_review', 'Helpful Member', 'Give your first profile review', 'social',
     'review_given', '{"target": 1}'::jsonb, 2, 150, 25, 250,
     NULL, 'bronze', false),
    
    ('trusted_reviewer', 'Trusted Reviewer', 'Give 10 helpful profile reviews', 'social',
     'reviews_given', '{"target": 10}'::jsonb, 3, 400, 40, 800,
     ARRAY['decoration_sunflower'], 'silver', false),
    
    -- Activity Achievements
    ('early_bird', 'Early Bird', 'Be active for 7 consecutive days', 'activity',
     'streak_days', '{"target": 7}'::jsonb, 3, 200, 30, 400,
     ARRAY['decoration_cherry_blossoms'], 'silver', false),
    
    ('dedicated_user', 'Dedicated User', 'Maintain a 30-day activity streak', 'activity',
     'streak_days', '{"target": 30}'::jsonb, 4, 750, 75, 1500,
     ARRAY['decoration_phoenix_flame'], 'gold', false),
    
    ('streak_legend', 'Streak Legend', 'Achieve a 100-day activity streak', 'activity',
     'streak_days', '{"target": 100}'::jsonb, 5, 2000, 200, 4000,
     ARRAY['decoration_fairy_dust'], 'diamond', false),
    
    ('message_sender', 'Conversationalist', 'Send 100 messages', 'activity',
     'messages_sent', '{"target": 100}'::jsonb, 2, 150, 20, 300,
     NULL, 'bronze', false),
    
    ('active_chatter', 'Active Chatter', 'Send 1000 messages', 'activity',
     'messages_sent', '{"target": 1000}'::jsonb, 3, 500, 50, 1000,
     ARRAY['theme_ocean_blue'], 'silver', false),
    
    ('communication_master', 'Communication Master', 'Send 5000 messages', 'activity',
     'messages_sent', '{"target": 5000}'::jsonb, 4, 1500, 150, 3000,
     ARRAY['decoration_magic_wand'], 'gold', false),
    
    -- Milestone Achievements
    ('level_5', 'Rising Star', 'Reach user level 5', 'milestones',
     'level_threshold', '{"level": 5}'::jsonb, 2, 200, 25, 400,
     ARRAY['decoration_stars'], 'bronze', false),
    
    ('level_10', 'Experienced User', 'Reach user level 10', 'milestones',
     'level_threshold', '{"level": 10}'::jsonb, 3, 500, 50, 1000,
     ARRAY['theme_sunset_orange'], 'silver', false),
    
    ('level_25', 'Veteran Member', 'Reach user level 25', 'milestones',
     'level_threshold', '{"level": 25}'::jsonb, 4, 1000, 100, 2000,
     ARRAY['decoration_diamond_ring'], 'gold', false),
    
    ('level_50', 'Elite User', 'Reach user level 50', 'milestones',
     'level_threshold', '{"level": 50}'::jsonb, 5, 2500, 250, 5000,
     ARRAY['theme_royal_purple'], 'diamond', false),
    
    ('reputation_100', 'Trusted Member', 'Earn 100 reputation points', 'milestones',
     'reputation_threshold', '{"reputation": 100}'::jsonb, 3, 300, 30, 600,
     NULL, 'silver', false),
    
    ('reputation_500', 'Community Leader', 'Earn 500 reputation points', 'milestones',
     'reputation_threshold', '{"reputation": 500}'::jsonb, 4, 750, 75, 1500,
     ARRAY['theme_galaxy'], 'gold', false),
    
    ('reputation_1000', 'Legendary Member', 'Earn 1000 reputation points', 'milestones',
     'reputation_threshold', '{"reputation": 1000}'::jsonb, 5, 2000, 200, 4000,
     ARRAY['decoration_phoenix_flame'], 'diamond', false),
    
    -- Special/Secret Achievements
    ('profile_viewed_100', 'Popular Profile', 'Have your profile viewed 100 times', 'special',
     'profile_views', '{"target": 100}'::jsonb, 3, 400, 40, 800,
     ARRAY['decoration_sparkles'], 'silver', true),
    
    ('decoration_collector', 'Decoration Collector', 'Own 10 different avatar decorations', 'special',
     'decoration_collection', '{"target": 10}'::jsonb, 4, 600, 60, 1200,
     ARRAY['decoration_gummy_bears'], 'gold', false),
    
    ('theme_enthusiast', 'Theme Enthusiast', 'Unlock 5 different profile themes', 'special',
     'theme_collection', '{"target": 5}'::jsonb, 4, 500, 50, 1000,
     ARRAY['decoration_rainbow'], 'gold', false),
    
    ('early_adopter', 'Early Adopter', 'Be one of the first 100 users', 'special',
     'early_user', '{"rank": 100}'::jsonb, 5, 1000, 100, 2000,
     ARRAY['decoration_crown_gold'], 'platinum', true),
    
    ('beta_tester', 'Beta Tester', 'Participate in beta testing', 'special',
     'beta_participation', '{"participated": true}'::jsonb, 4, 800, 80, 1600,
     ARRAY['decoration_fairy_dust'], 'diamond', true)
    
    ON CONFLICT (achievement_id) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- STARTER DATA FUNCTIONS
-- =====================================================

-- Function to set up new user profile system
CREATE OR REPLACE FUNCTION setup_new_user_profile(
    p_user_id UUID,
    p_username VARCHAR(50)
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
    v_profile_id UUID;
BEGIN
    -- Create basic profile
    INSERT INTO user_profiles (
        user_id, username, display_name, profile_completion_percentage,
        created_at, updated_at
    ) VALUES (
        p_user_id, p_username, p_username, 12.5, -- Username is 1/8 of completion
        NOW(), NOW()
    ) RETURNING id INTO v_profile_id;
    
    -- Initialize activity stats
    INSERT INTO user_activity_stats (user_id, created_at, updated_at)
    VALUES (p_user_id, NOW(), NOW());
    
    -- Initialize sound settings with defaults
    INSERT INTO user_sound_settings (
        user_id, default_ringtone, default_notification_sound,
        ringtone_volume, notification_volume, created_at, updated_at
    ) VALUES (
        p_user_id, 'default_ringtone.mp3', 'default_notification.mp3',
        0.8, 0.6, NOW(), NOW()
    );
    
    -- Give starter decorations (free ones)
    INSERT INTO user_avatar_decorations (user_id, decoration_id, unlock_method, unlocked_at)
    SELECT p_user_id, decoration_id, 'starter_pack', NOW()
    FROM avatar_decorations_catalog
    WHERE cost = 0 AND rarity = 'common'
    LIMIT 3;
    
    -- Give default themes
    INSERT INTO user_profile_themes (user_id, theme_id, unlock_method, unlocked_at)
    VALUES 
    (p_user_id, 'default', 'starter_pack', NOW()),
    (p_user_id, 'dark_mode', 'starter_pack', NOW());
    
    -- Set default theme as active
    UPDATE user_profile_themes
    SET is_active = true
    WHERE user_id = p_user_id AND theme_id = 'default';
    
    -- Initialize achievement progress for starter achievements
    INSERT INTO user_profile_achievements (
        user_id, achievement_id, target_progress, current_progress,
        completion_percentage, started_at, last_progress_at
    )
    SELECT 
        p_user_id, achievement_id, 
        (requirement_data->>'target')::DECIMAL,
        CASE WHEN achievement_id = 'profile_created' THEN 1 ELSE 0 END,
        CASE WHEN achievement_id = 'profile_created' THEN 100 ELSE 0 END,
        NOW(), NOW()
    FROM profile_achievements
    WHERE achievement_id IN (
        'profile_created', 'profile_half_complete', 'profile_complete',
        'first_friend', 'social_butterfly', 'early_bird', 'level_5'
    );
    
    -- Complete the profile creation achievement
    UPDATE user_profile_achievements
    SET is_completed = true, completed_at = NOW()
    WHERE user_id = p_user_id AND achievement_id = 'profile_created';
    
    -- Award initial experience and reputation
    UPDATE user_activity_stats
    SET experience_points = 50, user_level = 1
    WHERE user_id = p_user_id;
    
    UPDATE user_profiles
    SET reputation_score = 5
    WHERE user_id = p_user_id;
    
    v_result := json_build_object(
        'success', true,
        'profile_id', v_profile_id,
        'message', 'Profile system initialized successfully',
        'starter_decorations', 3,
        'starter_themes', 2,
        'initial_achievements', 1
    );
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- DEMO DATA FUNCTION
-- =====================================================

-- Function to create demo/test data (for development)
CREATE OR REPLACE FUNCTION create_demo_profile_data()
RETURNS VOID AS $$
DECLARE
    v_demo_user_id UUID;
BEGIN
    -- This function would only be used in development environments
    -- to create sample data for testing
    
    -- Note: In production, this should not be executed
    -- It's included here for development and testing purposes
    
    RAISE NOTICE 'Demo data creation function defined but not executed';
    RAISE NOTICE 'To create demo data, call this function explicitly in development environment';
    
    /*
    -- Example demo data creation:
    
    v_demo_user_id := gen_random_uuid();
    
    PERFORM setup_new_user_profile(v_demo_user_id, 'demo_user');
    
    -- Add more demo profile data
    UPDATE user_profiles
    SET display_name = 'Demo User',
        bio = 'This is a demo profile for testing purposes',
        location = 'Demo City',
        interests = ARRAY['technology', 'gaming', 'music'],
        profile_completion_percentage = 87.5
    WHERE user_id = v_demo_user_id;
    
    -- Add demo activity
    UPDATE user_activity_stats
    SET total_messages_sent = 150,
        experience_points = 1250,
        user_level = 5,
        friends_count = 12,
        current_streak_days = 5
    WHERE user_id = v_demo_user_id;
    */
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- SYSTEM CONFIGURATION
-- =====================================================

-- Function to configure profile system settings
CREATE OR REPLACE FUNCTION configure_profile_system()
RETURNS VOID AS $$
BEGIN
    -- Create system configuration table if it doesn't exist
    CREATE TABLE IF NOT EXISTS profile_system_config (
        config_key VARCHAR(100) PRIMARY KEY,
        config_value JSONB NOT NULL,
        description TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    
    -- Insert default configuration
    INSERT INTO profile_system_config (config_key, config_value, description) VALUES
    ('max_interests', '20', 'Maximum number of interests a user can have'),
    ('max_bio_length', '500', 'Maximum character length for user bio'),
    ('max_username_length', '50', 'Maximum character length for username'),
    ('min_username_length', '3', 'Minimum character length for username'),
    ('profile_view_retention_days', '90', 'How long to keep profile view history'),
    ('daily_stats_retention_days', '365', 'How long to keep daily statistics'),
    ('achievement_notification_enabled', 'true', 'Whether to send achievement notifications'),
    ('friend_suggestion_enabled', 'true', 'Whether to show friend suggestions'),
    ('profile_completion_rewards', 'true', 'Whether to give rewards for profile completion'),
    ('max_decorations_per_user', '100', 'Maximum decorations a user can own'),
    ('max_themes_per_user', '50', 'Maximum themes a user can own'),
    ('reputation_decay_enabled', 'false', 'Whether reputation decays over time'),
    ('streak_break_grace_hours', '24', 'Hours of grace period before breaking streak')
    ON CONFLICT (config_key) DO UPDATE SET
        config_value = EXCLUDED.config_value,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- INITIALIZATION FUNCTIONS
-- =====================================================

-- Master initialization function
CREATE OR REPLACE FUNCTION initialize_profile_system()
RETURNS JSON AS $$
DECLARE
    v_result JSON;
    v_decorations_count INTEGER;
    v_themes_count INTEGER;
    v_achievements_count INTEGER;
BEGIN
    -- Create all default data
    PERFORM create_default_avatar_decorations();
    PERFORM create_default_profile_themes();
    PERFORM create_default_profile_achievements();
    PERFORM configure_profile_system();
    
    -- Get counts for confirmation
    SELECT COUNT(*) INTO v_decorations_count FROM avatar_decorations_catalog;
    SELECT COUNT(*) INTO v_themes_count FROM profile_themes;
    SELECT COUNT(*) INTO v_achievements_count FROM profile_achievements;
    
    v_result := json_build_object(
        'success', true,
        'message', 'Profile system initialized successfully',
        'decorations_created', v_decorations_count,
        'themes_created', v_themes_count,
        'achievements_created', v_achievements_count,
        'system_configured', true
    );
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- MAINTENANCE FUNCTIONS
-- =====================================================

-- Daily maintenance function for profile system
CREATE OR REPLACE FUNCTION daily_profile_system_maintenance()
RETURNS JSON AS $$
DECLARE
    v_cleaned_views INTEGER;
    v_cleaned_stats INTEGER;
    v_updated_streaks INTEGER;
    v_result JSON;
BEGIN
    -- Clean old profile view history
    DELETE FROM profile_view_history
    WHERE viewed_at < NOW() - INTERVAL '90 days';
    GET DIAGNOSTICS v_cleaned_views = ROW_COUNT;
    
    -- Clean old daily stats
    DELETE FROM profile_daily_stats
    WHERE date < CURRENT_DATE - INTERVAL '365 days';
    GET DIAGNOSTICS v_cleaned_stats = ROW_COUNT;
    
    -- Reset streaks for inactive users
    UPDATE user_activity_stats
    SET current_streak_days = 0
    WHERE user_id NOT IN (
        SELECT DISTINCT user_id
        FROM profile_daily_stats
        WHERE date >= CURRENT_DATE - INTERVAL '2 days'
          AND (messages_sent > 0 OR active_minutes > 0)
    ) AND current_streak_days > 0;
    GET DIAGNOSTICS v_updated_streaks = ROW_COUNT;
    
    -- Update most active hours/days
    UPDATE user_activity_stats
    SET most_active_day_of_week = (
        SELECT EXTRACT(DOW FROM date)::INTEGER
        FROM profile_daily_stats
        WHERE user_id = user_activity_stats.user_id
          AND date >= CURRENT_DATE - INTERVAL '30 days'
        GROUP BY EXTRACT(DOW FROM date)
        ORDER BY SUM(messages_sent + active_minutes) DESC
        LIMIT 1
    );
    
    v_result := json_build_object(
        'success', true,
        'cleaned_views', v_cleaned_views,
        'cleaned_stats', v_cleaned_stats,
        'updated_streaks', v_updated_streaks,
        'maintenance_completed_at', NOW()
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- SYSTEM STATUS FUNCTION
-- =====================================================

-- Function to get profile system status and health
CREATE OR REPLACE FUNCTION get_profile_system_status()
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_build_object(
        'total_users', (SELECT COUNT(*) FROM user_profiles),
        'active_users_24h', (
            SELECT COUNT(*) FROM user_profiles 
            WHERE last_active_at > NOW() - INTERVAL '24 hours'
        ),
        'completed_profiles', (
            SELECT COUNT(*) FROM user_profiles 
            WHERE profile_completion_percentage = 100
        ),
        'total_decorations', (SELECT COUNT(*) FROM avatar_decorations_catalog),
        'total_themes', (SELECT COUNT(*) FROM profile_themes),
        'total_achievements', (SELECT COUNT(*) FROM profile_achievements),
        'completed_achievements_today', (
            SELECT COUNT(*) FROM user_profile_achievements 
            WHERE completed_at::DATE = CURRENT_DATE
        ),
        'new_connections_today', (
            SELECT COUNT(*) FROM user_connections 
            WHERE created_at::DATE = CURRENT_DATE AND status = 'accepted'
        ),
        'system_health', 'operational',
        'last_maintenance', (
            SELECT MAX(updated_at) FROM profile_system_config
        )
    ) INTO v_result;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- EXECUTE SYSTEM INITIALIZATION
-- =====================================================

-- Initialize the profile system with all default data
SELECT initialize_profile_system();

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

GRANT EXECUTE ON FUNCTION setup_new_user_profile(UUID, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION create_demo_profile_data() TO service_role;
GRANT EXECUTE ON FUNCTION daily_profile_system_maintenance() TO service_role;
GRANT EXECUTE ON FUNCTION get_profile_system_status() TO authenticated;
GRANT EXECUTE ON FUNCTION initialize_profile_system() TO service_role;

-- =====================================================
-- FINAL SYSTEM VERIFICATION
-- =====================================================

-- Function to verify system setup
CREATE OR REPLACE FUNCTION verify_profile_system_setup()
RETURNS JSON AS $$
DECLARE
    v_checks JSON;
    v_tables_exist BOOLEAN;
    v_data_populated BOOLEAN;
    v_functions_exist BOOLEAN;
    v_triggers_exist BOOLEAN;
BEGIN
    -- Check if all tables exist
    SELECT (
        SELECT COUNT(*) FROM information_schema.tables 
        WHERE table_name IN (
            'user_profiles', 'user_activity_stats', 'avatar_decorations_catalog',
            'user_avatar_decorations', 'profile_themes', 'profile_achievements'
        )
    ) = 6 INTO v_tables_exist;
    
    -- Check if data is populated
    SELECT (
        (SELECT COUNT(*) FROM avatar_decorations_catalog) > 0 AND
        (SELECT COUNT(*) FROM profile_themes) > 0 AND
        (SELECT COUNT(*) FROM profile_achievements) > 0
    ) INTO v_data_populated;
    
    -- Check if key functions exist
    SELECT (
        SELECT COUNT(*) FROM information_schema.routines 
        WHERE routine_name IN (
            'setup_new_user_profile', 'update_profile_completion',
            'unlock_avatar_decoration', 'update_achievement_progress'
        )
    ) >= 4 INTO v_functions_exist;
    
    -- Check if triggers exist
    SELECT (
        SELECT COUNT(*) FROM information_schema.triggers 
        WHERE trigger_name LIKE '%profile%'
    ) > 0 INTO v_triggers_exist;
    
    v_checks := json_build_object(
        'tables_exist', v_tables_exist,
        'data_populated', v_data_populated,
        'functions_exist', v_functions_exist,
        'triggers_exist', v_triggers_exist,
        'overall_status', (
            v_tables_exist AND v_data_populated AND 
            v_functions_exist AND v_triggers_exist
        ),
        'verification_timestamp', NOW()
    );
    
    RETURN v_checks;
END;
$$ LANGUAGE plpgsql;

-- Run verification
SELECT verify_profile_system_setup();

-- =====================================================
-- END OF PROFILE SETUP
-- =====================================================
