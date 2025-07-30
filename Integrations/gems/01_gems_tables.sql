-- =====================================================
-- CRYSTAL SOCIAL - GEMS SYSTEM TABLES
-- =====================================================
-- Database schema for comprehensive gem collection system
-- =====================================================

-- Table for available gemstones (master data)
CREATE TABLE IF NOT EXISTS enhanced_gemstones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT NOT NULL,
    image_path VARCHAR(255) NOT NULL,
    rarity VARCHAR(20) NOT NULL CHECK (rarity IN ('common', 'uncommon', 'rare', 'epic', 'legendary', 'mythic')),
    element VARCHAR(20) NOT NULL DEFAULT 'neutral' CHECK (element IN ('neutral', 'fire', 'water', 'earth', 'air', 'light', 'dark', 'cosmic', 'ice', 'lightning')),
    power INTEGER NOT NULL DEFAULT 0 CHECK (power >= 0),
    value INTEGER NOT NULL DEFAULT 0 CHECK (value >= 0),
    source VARCHAR(50) NOT NULL DEFAULT 'unknown',
    category VARCHAR(30) NOT NULL DEFAULT 'standard',
    tags JSONB DEFAULT '[]'::jsonb,
    sparkle_intensity DECIMAL(3,2) NOT NULL DEFAULT 1.0 CHECK (sparkle_intensity BETWEEN 0.1 AND 3.0),
    unlock_requirements JSONB DEFAULT '{}'::jsonb,
    seasonal_availability JSONB DEFAULT '["spring", "summer", "fall", "winter"]'::jsonb,
    special_effects JSONB DEFAULT '[]'::jsonb,
    animation_type VARCHAR(20) DEFAULT 'pulse',
    discovery_weight DECIMAL(5,3) NOT NULL DEFAULT 1.0 CHECK (discovery_weight > 0),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table for user's collected gemstones
CREATE TABLE IF NOT EXISTS user_gemstones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    gem_id UUID NOT NULL REFERENCES enhanced_gemstones(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    unlock_source VARCHAR(50) NOT NULL DEFAULT 'unknown',
    unlock_context JSONB DEFAULT '{}'::jsonb,
    is_favorite BOOLEAN NOT NULL DEFAULT false,
    times_viewed INTEGER NOT NULL DEFAULT 0,
    first_viewed_at TIMESTAMPTZ,
    last_viewed_at TIMESTAMPTZ,
    power_level INTEGER NOT NULL DEFAULT 1 CHECK (power_level BETWEEN 1 AND 100),
    enhancement_level INTEGER NOT NULL DEFAULT 0 CHECK (enhancement_level BETWEEN 0 AND 10),
    custom_name VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(user_id, gem_id)
);

-- Table for gem discovery events and history
CREATE TABLE IF NOT EXISTS gem_discovery_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    gem_id UUID NOT NULL REFERENCES enhanced_gemstones(id) ON DELETE CASCADE,
    discovery_method VARCHAR(50) NOT NULL,
    discovery_location VARCHAR(100),
    discovery_context JSONB DEFAULT '{}'::jsonb,
    rarity_bonus DECIMAL(3,2) DEFAULT 1.0,
    was_rare_unlock BOOLEAN NOT NULL DEFAULT false,
    experience_gained INTEGER DEFAULT 0,
    coins_gained INTEGER DEFAULT 0,
    gems_gained INTEGER DEFAULT 0,
    discovery_streak INTEGER DEFAULT 1,
    time_since_last_discovery INTERVAL,
    discovery_conditions JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table for gem collection statistics
CREATE TABLE IF NOT EXISTS gem_collection_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    total_gems_unlocked INTEGER NOT NULL DEFAULT 0,
    unique_gems_collected INTEGER NOT NULL DEFAULT 0,
    total_collection_value INTEGER NOT NULL DEFAULT 0,
    total_collection_power INTEGER NOT NULL DEFAULT 0,
    favorite_gems_count INTEGER NOT NULL DEFAULT 0,
    rarity_stats JSONB NOT NULL DEFAULT '{
        "common": 0,
        "uncommon": 0,
        "rare": 0,
        "epic": 0,
        "legendary": 0,
        "mythic": 0
    }'::jsonb,
    element_stats JSONB NOT NULL DEFAULT '{}'::jsonb,
    discovery_stats JSONB NOT NULL DEFAULT '{
        "total_discoveries": 0,
        "discoveries_today": 0,
        "discoveries_this_week": 0,
        "longest_streak": 0,
        "current_streak": 0
    }'::jsonb,
    completion_percentage DECIMAL(5,2) NOT NULL DEFAULT 0.0,
    collection_rank INTEGER DEFAULT NULL,
    first_gem_unlocked_at TIMESTAMPTZ,
    last_gem_unlocked_at TIMESTAMPTZ,
    most_valuable_gem_id UUID REFERENCES enhanced_gemstones(id),
    rarest_gem_unlocked VARCHAR(20),
    achievement_milestones JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(user_id)
);

-- Table for gem enhancement and upgrades
CREATE TABLE IF NOT EXISTS gem_enhancements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_gem_id UUID NOT NULL REFERENCES user_gemstones(id) ON DELETE CASCADE,
    enhancement_type VARCHAR(30) NOT NULL,
    enhancement_level INTEGER NOT NULL DEFAULT 1,
    enhancement_materials JSONB DEFAULT '[]'::jsonb,
    enhancement_cost_coins INTEGER DEFAULT 0,
    enhancement_cost_gems INTEGER DEFAULT 0,
    power_boost INTEGER DEFAULT 0,
    value_boost INTEGER DEFAULT 0,
    special_effects JSONB DEFAULT '[]'::jsonb,
    enhanced_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    enhanced_by UUID REFERENCES user_profiles(id),
    success_rate DECIMAL(5,2) DEFAULT 100.0,
    was_successful BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table for gem trading and marketplace
CREATE TABLE IF NOT EXISTS gem_trades (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trade_type VARCHAR(20) NOT NULL CHECK (trade_type IN ('offer', 'request', 'auction')),
    seller_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    buyer_id UUID REFERENCES user_profiles(id) ON DELETE SET NULL,
    gem_id UUID NOT NULL REFERENCES enhanced_gemstones(id) ON DELETE CASCADE,
    user_gem_id UUID REFERENCES user_gemstones(id) ON DELETE SET NULL,
    price_coins INTEGER DEFAULT 0,
    price_gems INTEGER DEFAULT 0,
    price_type VARCHAR(20) NOT NULL DEFAULT 'coins' CHECK (price_type IN ('coins', 'gems', 'both', 'trade')),
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'pending', 'completed', 'cancelled', 'expired')),
    trade_conditions JSONB DEFAULT '{}'::jsonb,
    expires_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    trade_rating INTEGER CHECK (trade_rating BETWEEN 1 AND 5),
    trade_feedback TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table for gem achievements and milestones
CREATE TABLE IF NOT EXISTS gem_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    achievement_type VARCHAR(50) NOT NULL,
    achievement_name VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    icon_path VARCHAR(255),
    current_value INTEGER NOT NULL DEFAULT 0,
    target_value INTEGER NOT NULL,
    progress_percentage DECIMAL(5,2) NOT NULL DEFAULT 0.0,
    is_completed BOOLEAN NOT NULL DEFAULT false,
    completed_at TIMESTAMPTZ,
    reward_coins INTEGER DEFAULT 0,
    reward_gems INTEGER DEFAULT 0,
    reward_items JSONB DEFAULT '[]'::jsonb,
    rarity VARCHAR(20) NOT NULL DEFAULT 'common',
    category VARCHAR(30) NOT NULL DEFAULT 'collection',
    unlock_requirements JSONB DEFAULT '{}'::jsonb,
    is_hidden BOOLEAN NOT NULL DEFAULT false,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(user_id, achievement_type, achievement_name)
);

-- Table for daily gem quests and challenges
CREATE TABLE IF NOT EXISTS gem_daily_quests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    quest_type VARCHAR(30) NOT NULL,
    quest_name VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    current_value INTEGER NOT NULL DEFAULT 0,
    target_value INTEGER NOT NULL,
    progress_percentage DECIMAL(5,2) NOT NULL DEFAULT 0.0,
    is_completed BOOLEAN NOT NULL DEFAULT false,
    completed_at TIMESTAMPTZ,
    reward_coins INTEGER DEFAULT 0,
    reward_gems INTEGER DEFAULT 0,
    reward_experience INTEGER DEFAULT 0,
    reward_items JSONB DEFAULT '[]'::jsonb,
    quest_date DATE NOT NULL DEFAULT CURRENT_DATE,
    difficulty VARCHAR(20) NOT NULL DEFAULT 'normal',
    bonus_multiplier DECIMAL(3,2) DEFAULT 1.0,
    quest_conditions JSONB DEFAULT '{}'::jsonb,
    auto_generated BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(user_id, quest_type, quest_date)
);

-- Table for gem analytics and tracking
CREATE TABLE IF NOT EXISTS gem_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    gems_discovered INTEGER NOT NULL DEFAULT 0,
    gems_enhanced INTEGER NOT NULL DEFAULT 0,
    gems_traded INTEGER NOT NULL DEFAULT 0,
    gems_viewed INTEGER NOT NULL DEFAULT 0,
    favorites_added INTEGER NOT NULL DEFAULT 0,
    favorites_removed INTEGER NOT NULL DEFAULT 0,
    coins_spent_on_gems INTEGER NOT NULL DEFAULT 0,
    gems_spent_on_enhancements INTEGER NOT NULL DEFAULT 0,
    total_value_gained INTEGER NOT NULL DEFAULT 0,
    total_power_gained INTEGER NOT NULL DEFAULT 0,
    achievements_unlocked INTEGER NOT NULL DEFAULT 0,
    quests_completed INTEGER NOT NULL DEFAULT 0,
    time_spent_minutes INTEGER NOT NULL DEFAULT 0,
    session_count INTEGER NOT NULL DEFAULT 0,
    popular_categories JSONB DEFAULT '[]'::jsonb,
    most_viewed_gems JSONB DEFAULT '[]'::jsonb,
    discovery_methods JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(user_id, date)
);

-- Table for gem wishlist and collections
CREATE TABLE IF NOT EXISTS gem_wishlists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    gem_id UUID NOT NULL REFERENCES enhanced_gemstones(id) ON DELETE CASCADE,
    priority_level INTEGER NOT NULL DEFAULT 1 CHECK (priority_level BETWEEN 1 AND 5),
    added_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes TEXT,
    notification_enabled BOOLEAN NOT NULL DEFAULT true,
    target_enhancement_level INTEGER DEFAULT 0,
    willing_to_pay_coins INTEGER DEFAULT 0,
    willing_to_pay_gems INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(user_id, gem_id)
);

-- Table for gem social features and sharing
CREATE TABLE IF NOT EXISTS gem_social_shares (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    gem_id UUID NOT NULL REFERENCES enhanced_gemstones(id) ON DELETE CASCADE,
    user_gem_id UUID REFERENCES user_gemstones(id) ON DELETE SET NULL,
    share_type VARCHAR(20) NOT NULL CHECK (share_type IN ('unlock', 'achievement', 'collection', 'enhancement')),
    share_message TEXT,
    share_image_url VARCHAR(255),
    likes_count INTEGER NOT NULL DEFAULT 0,
    comments_count INTEGER NOT NULL DEFAULT 0,
    is_public BOOLEAN NOT NULL DEFAULT true,
    featured_until TIMESTAMPTZ,
    share_context JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table for gem discovery methods and sources
CREATE TABLE IF NOT EXISTS gem_discovery_methods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    method_name VARCHAR(50) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    discovery_chance DECIMAL(5,3) NOT NULL DEFAULT 0.1,
    rarity_weights JSONB NOT NULL DEFAULT '{
        "common": 50,
        "uncommon": 25,
        "rare": 15,
        "epic": 7,
        "legendary": 2,
        "mythic": 1
    }'::jsonb,
    cooldown_minutes INTEGER DEFAULT 0,
    required_level INTEGER DEFAULT 1,
    cost_coins INTEGER DEFAULT 0,
    cost_gems INTEGER DEFAULT 0,
    special_requirements JSONB DEFAULT '{}'::jsonb,
    seasonal_bonuses JSONB DEFAULT '{}'::jsonb,
    is_active BOOLEAN NOT NULL DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table for user gem statistics (used by Dart service)
CREATE TABLE IF NOT EXISTS user_gem_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    total_gems INTEGER NOT NULL DEFAULT 0,
    total_possible INTEGER NOT NULL DEFAULT 0,
    completion_percentage DECIMAL(5,2) NOT NULL DEFAULT 0.0,
    total_value INTEGER NOT NULL DEFAULT 0,
    total_power INTEGER NOT NULL DEFAULT 0,
    favorites_count INTEGER NOT NULL DEFAULT 0,
    common_count INTEGER NOT NULL DEFAULT 0,
    uncommon_count INTEGER NOT NULL DEFAULT 0,
    rare_count INTEGER NOT NULL DEFAULT 0,
    epic_count INTEGER NOT NULL DEFAULT 0,
    legendary_count INTEGER NOT NULL DEFAULT 0,
    last_updated TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(user_id)
);

-- Table for gem unlock analytics (used by Dart service)
CREATE TABLE IF NOT EXISTS gem_unlock_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    gem_id UUID NOT NULL REFERENCES enhanced_gemstones(id) ON DELETE CASCADE,
    unlock_source VARCHAR(50) NOT NULL DEFAULT 'unknown',
    unlock_context JSONB DEFAULT '{}'::jsonb,
    session_id UUID,
    device_info JSONB DEFAULT '{}'::jsonb,
    location_data JSONB DEFAULT '{}'::jsonb,
    unlock_duration_ms INTEGER,
    user_level INTEGER DEFAULT 1,
    previous_gems_count INTEGER DEFAULT 0,
    is_first_of_rarity BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_enhanced_gemstones_rarity ON enhanced_gemstones(rarity);
CREATE INDEX IF NOT EXISTS idx_enhanced_gemstones_element ON enhanced_gemstones(element);
CREATE INDEX IF NOT EXISTS idx_enhanced_gemstones_active ON enhanced_gemstones(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_enhanced_gemstones_tags ON enhanced_gemstones USING GIN(tags);

CREATE INDEX IF NOT EXISTS idx_user_gemstones_user_id ON user_gemstones(user_id);
CREATE INDEX IF NOT EXISTS idx_user_gemstones_gem_id ON user_gemstones(gem_id);
CREATE INDEX IF NOT EXISTS idx_user_gemstones_favorite ON user_gemstones(user_id, is_favorite) WHERE is_favorite = true;
CREATE INDEX IF NOT EXISTS idx_user_gemstones_unlocked_at ON user_gemstones(unlocked_at DESC);

CREATE INDEX IF NOT EXISTS idx_gem_discovery_events_user_id ON gem_discovery_events(user_id);
CREATE INDEX IF NOT EXISTS idx_gem_discovery_events_gem_id ON gem_discovery_events(gem_id);
CREATE INDEX IF NOT EXISTS idx_gem_discovery_events_created_at ON gem_discovery_events(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_gem_discovery_events_method ON gem_discovery_events(discovery_method);

CREATE INDEX IF NOT EXISTS idx_gem_collection_stats_user_id ON gem_collection_stats(user_id);
CREATE INDEX IF NOT EXISTS idx_gem_collection_stats_completion ON gem_collection_stats(completion_percentage DESC);
CREATE INDEX IF NOT EXISTS idx_gem_collection_stats_rank ON gem_collection_stats(collection_rank) WHERE collection_rank IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_gem_enhancements_user_gem_id ON gem_enhancements(user_gem_id);
CREATE INDEX IF NOT EXISTS idx_gem_enhancements_type ON gem_enhancements(enhancement_type);
CREATE INDEX IF NOT EXISTS idx_gem_enhancements_enhanced_at ON gem_enhancements(enhanced_at DESC);

CREATE INDEX IF NOT EXISTS idx_gem_trades_seller ON gem_trades(seller_id);
CREATE INDEX IF NOT EXISTS idx_gem_trades_buyer ON gem_trades(buyer_id);
CREATE INDEX IF NOT EXISTS idx_gem_trades_status ON gem_trades(status);
CREATE INDEX IF NOT EXISTS idx_gem_trades_active ON gem_trades(status, created_at) WHERE status = 'active';

CREATE INDEX IF NOT EXISTS idx_gem_achievements_user_id ON gem_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_gem_achievements_completed ON gem_achievements(user_id, is_completed);
CREATE INDEX IF NOT EXISTS idx_gem_achievements_type ON gem_achievements(achievement_type);

CREATE INDEX IF NOT EXISTS idx_gem_daily_quests_user_date ON gem_daily_quests(user_id, quest_date);
CREATE INDEX IF NOT EXISTS idx_gem_daily_quests_completed ON gem_daily_quests(user_id, is_completed, quest_date);

CREATE INDEX IF NOT EXISTS idx_gem_analytics_user_date ON gem_analytics(user_id, date);
CREATE INDEX IF NOT EXISTS idx_gem_analytics_date ON gem_analytics(date DESC);

CREATE INDEX IF NOT EXISTS idx_gem_wishlists_user_id ON gem_wishlists(user_id);
CREATE INDEX IF NOT EXISTS idx_gem_wishlists_priority ON gem_wishlists(user_id, priority_level DESC);

CREATE INDEX IF NOT EXISTS idx_gem_social_shares_user_id ON gem_social_shares(user_id);
CREATE INDEX IF NOT EXISTS idx_gem_social_shares_public ON gem_social_shares(is_public, created_at DESC) WHERE is_public = true;
CREATE INDEX IF NOT EXISTS idx_gem_social_shares_gem_id ON gem_social_shares(gem_id);

CREATE INDEX IF NOT EXISTS idx_gem_discovery_methods_active ON gem_discovery_methods(is_active, sort_order) WHERE is_active = true;

-- Indexes for user_gem_stats
CREATE INDEX IF NOT EXISTS idx_user_gem_stats_user_id ON user_gem_stats(user_id);
CREATE INDEX IF NOT EXISTS idx_user_gem_stats_completion ON user_gem_stats(completion_percentage DESC);
CREATE INDEX IF NOT EXISTS idx_user_gem_stats_value ON user_gem_stats(total_value DESC);

-- Indexes for gem_unlock_analytics
CREATE INDEX IF NOT EXISTS idx_gem_unlock_analytics_user_id ON gem_unlock_analytics(user_id);
CREATE INDEX IF NOT EXISTS idx_gem_unlock_analytics_gem_id ON gem_unlock_analytics(gem_id);
CREATE INDEX IF NOT EXISTS idx_gem_unlock_analytics_source ON gem_unlock_analytics(unlock_source);
CREATE INDEX IF NOT EXISTS idx_gem_unlock_analytics_created_at ON gem_unlock_analytics(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_gem_unlock_analytics_session ON gem_unlock_analytics(session_id) WHERE session_id IS NOT NULL;
