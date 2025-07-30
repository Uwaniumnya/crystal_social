-- =====================================================
-- CRYSTAL SOCIAL - PROFILE SYSTEM TABLES
-- =====================================================
-- Comprehensive profile management with stats, decorations, and customization
-- =====================================================

-- =====================================================
-- PROFILE CORE TABLES
-- =====================================================

-- User profiles table (extends auth.users)
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    username VARCHAR(50) UNIQUE NOT NULL,
    display_name VARCHAR(100),
    bio TEXT,
    avatar_url TEXT,
    avatar_decoration VARCHAR(100),
    location VARCHAR(100),
    website VARCHAR(255),
    zodiac_sign VARCHAR(20),
    interests TEXT[], -- Array of interests
    social_links JSONB DEFAULT '{}'::jsonb, -- {twitter, instagram, etc.}
    profile_theme VARCHAR(50) DEFAULT 'default',
    is_private BOOLEAN DEFAULT false,
    is_verified BOOLEAN DEFAULT false,
    reputation_score INTEGER DEFAULT 0,
    profile_completion_percentage DECIMAL(5,2) DEFAULT 0.0,
    last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT username_length CHECK (LENGTH(username) >= 3),
    CONSTRAINT bio_length CHECK (LENGTH(bio) <= 500),
    CONSTRAINT website_format CHECK (website IS NULL OR website ~* '^https?://'),
    CONSTRAINT interests_limit CHECK (array_length(interests, 1) <= 20)
);

-- User activity statistics
CREATE TABLE IF NOT EXISTS user_activity_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Message statistics
    total_messages_sent INTEGER DEFAULT 0,
    messages_sent_today INTEGER DEFAULT 0,
    messages_sent_this_week INTEGER DEFAULT 0,
    messages_sent_this_month INTEGER DEFAULT 0,
    messages_with_emojis INTEGER DEFAULT 0,
    messages_with_reactions INTEGER DEFAULT 0,
    messages_replied_to INTEGER DEFAULT 0,
    
    -- Engagement metrics
    total_reactions_received INTEGER DEFAULT 0,
    total_reactions_given INTEGER DEFAULT 0,
    average_response_time INTERVAL DEFAULT '0 minutes',
    longest_streak_days INTEGER DEFAULT 0,
    current_streak_days INTEGER DEFAULT 0,
    
    -- Content statistics
    total_stickers_sent INTEGER DEFAULT 0,
    total_images_sent INTEGER DEFAULT 0,
    total_voice_messages INTEGER DEFAULT 0,
    total_video_calls INTEGER DEFAULT 0,
    total_audio_calls INTEGER DEFAULT 0,
    
    -- Social metrics
    friends_count INTEGER DEFAULT 0,
    groups_joined INTEGER DEFAULT 0,
    groups_created INTEGER DEFAULT 0,
    
    -- Time-based analytics
    active_chat_hours DECIMAL(10,2) DEFAULT 0.0,
    most_active_hour INTEGER, -- 0-23
    most_active_day_of_week INTEGER, -- 0-6 (Sunday-Saturday)
    
    -- Popular content
    most_used_emojis JSONB DEFAULT '{}'::jsonb, -- {emoji: count}
    most_common_words JSONB DEFAULT '{}'::jsonb, -- {word: count}
    favorite_stickers TEXT[],
    
    -- Level and experience
    user_level INTEGER DEFAULT 1,
    experience_points INTEGER DEFAULT 0,
    total_login_days INTEGER DEFAULT 0,
    
    last_calculated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT unique_user_stats UNIQUE(user_id)
);

-- Avatar decorations catalog
CREATE TABLE IF NOT EXISTS avatar_decorations_catalog (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    decoration_id VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50) NOT NULL, -- cute, love, sparkles, nature, premium, seasonal
    image_path VARCHAR(255) NOT NULL,
    icon_emoji VARCHAR(10) DEFAULT '✨',
    rarity VARCHAR(20) DEFAULT 'common', -- common, uncommon, rare, epic, legendary
    cost INTEGER DEFAULT 0, -- 0 for free decorations
    is_premium BOOLEAN DEFAULT false,
    is_seasonal BOOLEAN DEFAULT false,
    seasonal_start DATE,
    seasonal_end DATE,
    unlock_requirements JSONB DEFAULT '{}'::jsonb, -- {level: 5, achievements: [...]}
    special_effects JSONB DEFAULT '{}'::jsonb, -- Animation effects, particles
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User's owned avatar decorations
CREATE TABLE IF NOT EXISTS user_avatar_decorations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    decoration_id VARCHAR(100) NOT NULL REFERENCES avatar_decorations_catalog(decoration_id),
    unlock_method VARCHAR(50) NOT NULL, -- purchase, achievement, gift, seasonal, admin
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_equipped BOOLEAN DEFAULT false,
    total_times_equipped INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT unique_user_decoration UNIQUE(user_id, decoration_id)
);

-- =====================================================
-- SOUND & NOTIFICATION CUSTOMIZATION
-- =====================================================

-- User sound preferences
CREATE TABLE IF NOT EXISTS user_sound_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Default sounds
    default_ringtone VARCHAR(255),
    default_notification_sound VARCHAR(255),
    default_message_sound VARCHAR(255),
    
    -- Sound preferences
    notification_sound_preferences JSONB DEFAULT '{}'::jsonb, -- {app_sounds: true, vibration: true}
    ringtone_volume DECIMAL(3,2) DEFAULT 0.8,
    notification_volume DECIMAL(3,2) DEFAULT 0.6,
    
    -- Advanced settings
    enable_sound_effects BOOLEAN DEFAULT true,
    enable_haptic_feedback BOOLEAN DEFAULT true,
    quiet_hours_enabled BOOLEAN DEFAULT false,
    quiet_hours_start TIME,
    quiet_hours_end TIME,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT unique_user_sound_settings UNIQUE(user_id),
    CONSTRAINT volume_range CHECK (ringtone_volume BETWEEN 0.0 AND 1.0),
    CONSTRAINT notification_volume_range CHECK (notification_volume BETWEEN 0.0 AND 1.0)
);

-- Per-user ringtones (custom ringtones for specific contacts)
CREATE TABLE IF NOT EXISTS per_user_ringtones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    ringtone VARCHAR(255) NOT NULL,
    is_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT unique_user_ringtone UNIQUE(owner_id, sender_id)
);

-- =====================================================
-- PROFILE THEMES & CUSTOMIZATION
-- =====================================================

-- Profile themes catalog
CREATE TABLE IF NOT EXISTS profile_themes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    theme_id VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    preview_image VARCHAR(255),
    category VARCHAR(50) DEFAULT 'general', -- general, premium, seasonal, zodiac
    
    -- Theme configuration
    color_scheme JSONB NOT NULL, -- {primary, secondary, accent, background}
    typography JSONB DEFAULT '{}'::jsonb, -- {font_family, sizes}
    layout_config JSONB DEFAULT '{}'::jsonb, -- Layout preferences
    
    -- Availability
    is_premium BOOLEAN DEFAULT false,
    is_seasonal BOOLEAN DEFAULT false,
    cost INTEGER DEFAULT 0,
    unlock_requirements JSONB DEFAULT '{}'::jsonb,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User's unlocked themes
CREATE TABLE IF NOT EXISTS user_profile_themes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    theme_id VARCHAR(100) NOT NULL REFERENCES profile_themes(theme_id),
    is_active BOOLEAN DEFAULT false,
    unlock_method VARCHAR(50) NOT NULL,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT unique_user_theme UNIQUE(user_id, theme_id)
);

-- =====================================================
-- PROFILE ACHIEVEMENTS & PROGRESS
-- =====================================================

-- Profile-specific achievements
CREATE TABLE IF NOT EXISTS profile_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    achievement_id VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(50) NOT NULL, -- profile_completion, social, activity, milestones
    
    -- Achievement criteria
    requirement_type VARCHAR(50) NOT NULL, -- stats_threshold, action_count, special_unlock
    requirement_data JSONB NOT NULL, -- Specific requirements
    difficulty_level INTEGER DEFAULT 1, -- 1-5
    
    -- Rewards
    experience_reward INTEGER DEFAULT 0,
    reputation_reward INTEGER DEFAULT 0,
    currency_reward INTEGER DEFAULT 0,
    unlock_rewards TEXT[], -- decoration_id, theme_id, etc.
    
    -- Display
    badge_icon VARCHAR(100),
    badge_color VARCHAR(50) DEFAULT 'bronze',
    is_secret BOOLEAN DEFAULT false,
    is_repeatable BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User achievement progress
CREATE TABLE IF NOT EXISTS user_profile_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    achievement_id VARCHAR(100) NOT NULL REFERENCES profile_achievements(achievement_id),
    
    -- Progress tracking
    current_progress DECIMAL(10,2) DEFAULT 0,
    target_progress DECIMAL(10,2) NOT NULL,
    is_completed BOOLEAN DEFAULT false,
    completion_percentage DECIMAL(5,2) DEFAULT 0.0,
    
    -- Timestamps
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    last_progress_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT unique_user_achievement UNIQUE(user_id, achievement_id),
    CONSTRAINT progress_valid CHECK (current_progress >= 0 AND current_progress <= target_progress)
);

-- =====================================================
-- SOCIAL CONNECTIONS & REPUTATION
-- =====================================================

-- User connections/friendships
CREATE TABLE IF NOT EXISTS user_connections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    connected_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    connection_type VARCHAR(50) DEFAULT 'friend', -- friend, blocked, following
    status VARCHAR(50) DEFAULT 'pending', -- pending, accepted, declined
    
    -- Connection metadata
    connection_strength INTEGER DEFAULT 1, -- Based on interactions
    mutual_friends_count INTEGER DEFAULT 0,
    interaction_score DECIMAL(10,2) DEFAULT 0.0,
    
    -- Notes and customization
    custom_nickname VARCHAR(100),
    private_notes TEXT,
    is_favorite BOOLEAN DEFAULT false,
    notification_settings JSONB DEFAULT '{}'::jsonb,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT no_self_connection CHECK (user_id != connected_user_id),
    CONSTRAINT unique_connection UNIQUE(user_id, connected_user_id)
);

-- Profile reputation and reviews
CREATE TABLE IF NOT EXISTS profile_reputation (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reviewer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Rating and feedback
    rating INTEGER NOT NULL, -- 1-5 stars
    review_text TEXT,
    review_categories TEXT[], -- helpful, friendly, responsive, etc.
    
    -- Context
    interaction_context VARCHAR(100), -- chat, group, call, etc.
    is_verified_interaction BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_rating CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT no_self_review CHECK (user_id != reviewer_id),
    CONSTRAINT unique_review UNIQUE(user_id, reviewer_id)
);

-- =====================================================
-- PROFILE ANALYTICS & INSIGHTS
-- =====================================================

-- Daily profile analytics
CREATE TABLE IF NOT EXISTS profile_daily_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    
    -- Profile views and interactions
    profile_views INTEGER DEFAULT 0,
    profile_views_unique INTEGER DEFAULT 0,
    decoration_changes INTEGER DEFAULT 0,
    theme_changes INTEGER DEFAULT 0,
    
    -- Activity metrics
    messages_sent INTEGER DEFAULT 0,
    reactions_given INTEGER DEFAULT 0,
    reactions_received INTEGER DEFAULT 0,
    active_minutes INTEGER DEFAULT 0,
    
    -- Social metrics
    new_connections INTEGER DEFAULT 0,
    connection_requests_sent INTEGER DEFAULT 0,
    connection_requests_received INTEGER DEFAULT 0,
    
    -- Engagement
    achievement_unlocks INTEGER DEFAULT 0,
    experience_gained INTEGER DEFAULT 0,
    reputation_change INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT unique_user_date UNIQUE(user_id, date)
);

-- Profile view history
CREATE TABLE IF NOT EXISTS profile_view_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    viewer_id UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- NULL for anonymous views
    
    -- View details
    view_source VARCHAR(50), -- search, direct_link, friend_list, etc.
    view_duration INTEGER, -- Seconds spent viewing
    sections_viewed TEXT[], -- Which profile sections were viewed
    
    -- Context
    viewer_ip_hash VARCHAR(64), -- Hashed IP for anonymous analytics
    user_agent_hash VARCHAR(64), -- Hashed user agent
    referrer_url TEXT,
    
    viewed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- User profiles indexes
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_username ON user_profiles(username);
CREATE INDEX IF NOT EXISTS idx_user_profiles_display_name ON user_profiles(display_name);
CREATE INDEX IF NOT EXISTS idx_user_profiles_is_verified ON user_profiles(is_verified);
CREATE INDEX IF NOT EXISTS idx_user_profiles_last_active ON user_profiles(last_active_at);
CREATE INDEX IF NOT EXISTS idx_user_profiles_reputation ON user_profiles(reputation_score DESC);

-- Activity stats indexes
CREATE INDEX IF NOT EXISTS idx_user_activity_stats_user_id ON user_activity_stats(user_id);
CREATE INDEX IF NOT EXISTS idx_user_activity_stats_level ON user_activity_stats(user_level DESC);
CREATE INDEX IF NOT EXISTS idx_user_activity_stats_experience ON user_activity_stats(experience_points DESC);
CREATE INDEX IF NOT EXISTS idx_user_activity_stats_streak ON user_activity_stats(current_streak_days DESC);

-- Avatar decorations indexes
CREATE INDEX IF NOT EXISTS idx_avatar_decorations_catalog_category ON avatar_decorations_catalog(category);
CREATE INDEX IF NOT EXISTS idx_avatar_decorations_catalog_rarity ON avatar_decorations_catalog(rarity);
CREATE INDEX IF NOT EXISTS idx_avatar_decorations_catalog_cost ON avatar_decorations_catalog(cost);
CREATE INDEX IF NOT EXISTS idx_user_avatar_decorations_user_id ON user_avatar_decorations(user_id);
CREATE INDEX IF NOT EXISTS idx_user_avatar_decorations_equipped ON user_avatar_decorations(user_id, is_equipped);

-- Sound settings indexes
CREATE INDEX IF NOT EXISTS idx_user_sound_settings_user_id ON user_sound_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_per_user_ringtones_owner ON per_user_ringtones(owner_id);
CREATE INDEX IF NOT EXISTS idx_per_user_ringtones_sender ON per_user_ringtones(sender_id);

-- Achievements indexes
CREATE INDEX IF NOT EXISTS idx_profile_achievements_category ON profile_achievements(category);
CREATE INDEX IF NOT EXISTS idx_user_profile_achievements_user_id ON user_profile_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profile_achievements_completed ON user_profile_achievements(is_completed);
CREATE INDEX IF NOT EXISTS idx_user_profile_achievements_progress ON user_profile_achievements(completion_percentage);

-- Connections indexes
CREATE INDEX IF NOT EXISTS idx_user_connections_user_id ON user_connections(user_id);
CREATE INDEX IF NOT EXISTS idx_user_connections_connected_user ON user_connections(connected_user_id);
CREATE INDEX IF NOT EXISTS idx_user_connections_status ON user_connections(status);
CREATE INDEX IF NOT EXISTS idx_user_connections_type ON user_connections(connection_type);

-- Analytics indexes
CREATE INDEX IF NOT EXISTS idx_profile_daily_stats_user_date ON profile_daily_stats(user_id, date);
CREATE INDEX IF NOT EXISTS idx_profile_daily_stats_date ON profile_daily_stats(date);
CREATE INDEX IF NOT EXISTS idx_profile_view_history_owner ON profile_view_history(profile_owner_id);
CREATE INDEX IF NOT EXISTS idx_profile_view_history_viewer ON profile_view_history(viewer_id);
CREATE INDEX IF NOT EXISTS idx_profile_view_history_viewed_at ON profile_view_history(viewed_at);

-- Full-text search indexes
CREATE INDEX IF NOT EXISTS idx_user_profiles_search ON user_profiles 
USING gin(to_tsvector('english', coalesce(display_name, '') || ' ' || coalesce(bio, '') || ' ' || coalesce(username, '')));

CREATE INDEX IF NOT EXISTS idx_user_profiles_interests ON user_profiles USING gin(interests);

-- =====================================================
-- COMMENTS AND DOCUMENTATION
-- =====================================================

COMMENT ON TABLE user_profiles IS 'Extended user profile information and customization settings';
COMMENT ON TABLE user_activity_stats IS 'Comprehensive user activity statistics and engagement metrics';
COMMENT ON TABLE avatar_decorations_catalog IS 'Available avatar decorations with metadata and unlock requirements';
COMMENT ON TABLE user_avatar_decorations IS 'User-owned avatar decorations and equipment status';
COMMENT ON TABLE user_sound_settings IS 'User sound and notification preferences';
COMMENT ON TABLE per_user_ringtones IS 'Custom ringtones assigned to specific contacts';
COMMENT ON TABLE profile_themes IS 'Available profile themes and customization options';
COMMENT ON TABLE user_profile_themes IS 'User-unlocked profile themes';
COMMENT ON TABLE profile_achievements IS 'Profile-related achievements and milestones';
COMMENT ON TABLE user_profile_achievements IS 'User progress on profile achievements';
COMMENT ON TABLE user_connections IS 'Social connections between users with relationship metadata';
COMMENT ON TABLE profile_reputation IS 'User reputation system with peer reviews';
COMMENT ON TABLE profile_daily_stats IS 'Daily aggregated profile activity statistics';
COMMENT ON TABLE profile_view_history IS 'Profile view tracking for analytics';

-- =====================================================
-- END OF PROFILE TABLES
-- =====================================================
