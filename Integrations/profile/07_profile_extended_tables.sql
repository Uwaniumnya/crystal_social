-- =====================================================
-- CRYSTAL SOCIAL - PROFILE SYSTEM EXTENDED TABLES
-- =====================================================
-- Additional tables for missing functionality discovered
-- in avatar_picker, sound systems, and production files
-- =====================================================

-- =====================================================
-- ASSET MANAGEMENT SYSTEM
-- =====================================================

-- Preset avatars catalog
CREATE TABLE preset_avatars (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    avatar_id VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    file_path VARCHAR(500) NOT NULL,
    category VARCHAR(100) DEFAULT 'general',
    is_premium BOOLEAN DEFAULT false,
    unlock_level INTEGER DEFAULT 1,
    unlock_cost INTEGER DEFAULT 0,
    rarity VARCHAR(50) DEFAULT 'common',
    tags TEXT[] DEFAULT '{}',
    metadata JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User avatar uploads history
CREATE TABLE user_avatar_uploads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    upload_status VARCHAR(50) DEFAULT 'processing',
    is_current BOOLEAN DEFAULT false,
    moderation_status VARCHAR(50) DEFAULT 'pending',
    moderation_notes TEXT,
    upload_metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Sound catalog system
CREATE TABLE sound_catalog (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sound_id VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    file_path VARCHAR(500) NOT NULL,
    category VARCHAR(100) NOT NULL,
    subcategory VARCHAR(100),
    is_premium BOOLEAN DEFAULT false,
    unlock_cost INTEGER DEFAULT 0,
    rarity VARCHAR(50) DEFAULT 'common',
    duration_seconds DECIMAL(5,2),
    file_size BIGINT,
    mime_type VARCHAR(100),
    volume_level DECIMAL(3,2) DEFAULT 0.7,
    is_ringtone BOOLEAN DEFAULT false,
    is_notification BOOLEAN DEFAULT true,
    tags TEXT[] DEFAULT '{}',
    metadata JSONB DEFAULT '{}',
    icon_name VARCHAR(100),
    color_hex VARCHAR(7),
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User sound inventory
CREATE TABLE user_sound_inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    sound_id VARCHAR(100) NOT NULL REFERENCES sound_catalog(sound_id) ON DELETE CASCADE,
    unlock_method VARCHAR(100) NOT NULL,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_favorite BOOLEAN DEFAULT false,
    custom_volume DECIMAL(3,2),
    usage_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}'
);

-- =====================================================
-- USER INVENTORY SYSTEM (Referenced by avatar_picker)
-- =====================================================

-- User inventory for all items (decorations, themes, sounds, etc.)
CREATE TABLE user_inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    item_id VARCHAR(100) NOT NULL,
    item_type VARCHAR(50) NOT NULL, -- 'decoration', 'theme', 'sound', 'avatar'
    item_category VARCHAR(100),
    quantity INTEGER DEFAULT 1,
    equipped BOOLEAN DEFAULT false,
    unlock_method VARCHAR(100) NOT NULL,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    is_tradeable BOOLEAN DEFAULT false,
    trade_value INTEGER,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- ENHANCED PROFILE FIELDS
-- =====================================================

-- User social media links
CREATE TABLE user_social_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    platform VARCHAR(50) NOT NULL,
    username VARCHAR(200),
    url VARCHAR(500),
    is_verified BOOLEAN DEFAULT false,
    is_public BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, platform)
);

-- Enhanced user profile extensions
CREATE TABLE user_profile_extensions (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    zodiac_sign VARCHAR(20),
    birth_month INTEGER CHECK (birth_month BETWEEN 1 AND 12),
    birth_day INTEGER CHECK (birth_day BETWEEN 1 AND 31),
    show_zodiac BOOLEAN DEFAULT true,
    show_birthday BOOLEAN DEFAULT false,
    relationship_status VARCHAR(50),
    show_relationship_status BOOLEAN DEFAULT false,
    occupation VARCHAR(200),
    show_occupation BOOLEAN DEFAULT true,
    education VARCHAR(200),
    show_education BOOLEAN DEFAULT true,
    personality_traits TEXT[],
    favorite_quote TEXT,
    life_motto TEXT,
    custom_fields JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Profile privacy settings
CREATE TABLE user_privacy_settings (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    profile_visibility VARCHAR(20) DEFAULT 'public', -- 'public', 'friends', 'private'
    show_online_status BOOLEAN DEFAULT true,
    show_last_seen BOOLEAN DEFAULT true,
    show_location BOOLEAN DEFAULT true,
    show_interests BOOLEAN DEFAULT true,
    show_social_links BOOLEAN DEFAULT true,
    show_statistics BOOLEAN DEFAULT true,
    show_achievements BOOLEAN DEFAULT true,
    show_activity_feed BOOLEAN DEFAULT true,
    allow_friend_requests BOOLEAN DEFAULT true,
    allow_messages BOOLEAN DEFAULT true,
    allow_profile_comments BOOLEAN DEFAULT true,
    allow_tagging BOOLEAN DEFAULT true,
    show_in_search BOOLEAN DEFAULT true,
    data_sharing_consent BOOLEAN DEFAULT false,
    analytics_consent BOOLEAN DEFAULT false,
    marketing_consent BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Profile edit history
CREATE TABLE profile_edit_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    field_name VARCHAR(100) NOT NULL,
    old_value TEXT,
    new_value TEXT,
    change_type VARCHAR(50) NOT NULL, -- 'create', 'update', 'delete'
    ip_address INET,
    user_agent TEXT,
    edited_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- SYSTEM CONFIGURATION AND MONITORING
-- =====================================================

-- System configuration storage
CREATE TABLE system_configuration (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    config_category VARCHAR(100) NOT NULL,
    config_key VARCHAR(200) NOT NULL,
    config_value JSONB NOT NULL,
    description TEXT,
    is_sensitive BOOLEAN DEFAULT false,
    requires_restart BOOLEAN DEFAULT false,
    version VARCHAR(20),
    environment VARCHAR(50) DEFAULT 'production',
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(config_category, config_key, environment)
);

-- Performance metrics tracking
CREATE TABLE performance_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_name VARCHAR(100) NOT NULL,
    metric_category VARCHAR(50) NOT NULL,
    metric_value DECIMAL(15,6) NOT NULL,
    metric_unit VARCHAR(20),
    user_id UUID REFERENCES auth.users(id),
    session_id VARCHAR(100),
    endpoint VARCHAR(200),
    operation_type VARCHAR(100),
    duration_ms INTEGER,
    memory_usage_mb DECIMAL(10,2),
    cpu_usage_percent DECIMAL(5,2),
    metadata JSONB DEFAULT '{}',
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- System validation logs
CREATE TABLE validation_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    validation_type VARCHAR(100) NOT NULL,
    component_name VARCHAR(100) NOT NULL,
    validation_result VARCHAR(20) NOT NULL, -- 'passed', 'failed', 'warning'
    error_messages TEXT[],
    warning_messages TEXT[],
    validation_metadata JSONB DEFAULT '{}',
    validator_version VARCHAR(20),
    performed_by UUID REFERENCES auth.users(id),
    performed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- PREMIUM CONTENT SYSTEM
-- =====================================================

-- Premium content catalog
CREATE TABLE premium_content (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_id VARCHAR(100) UNIQUE NOT NULL,
    content_type VARCHAR(50) NOT NULL, -- 'decoration', 'theme', 'sound', 'feature'
    name VARCHAR(200) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    price_gems INTEGER,
    price_currency DECIMAL(10,2),
    currency_type VARCHAR(10) DEFAULT 'USD',
    unlock_requirements JSONB DEFAULT '{}',
    availability_start TIMESTAMP WITH TIME ZONE,
    availability_end TIMESTAMP WITH TIME ZONE,
    is_limited_edition BOOLEAN DEFAULT false,
    max_purchases INTEGER,
    current_purchases INTEGER DEFAULT 0,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User premium purchases
CREATE TABLE user_premium_purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content_id VARCHAR(100) NOT NULL REFERENCES premium_content(content_id),
    purchase_method VARCHAR(50) NOT NULL, -- 'gems', 'currency', 'reward'
    amount_paid DECIMAL(10,2),
    currency_type VARCHAR(10),
    transaction_id VARCHAR(200),
    purchase_status VARCHAR(50) DEFAULT 'completed',
    purchased_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    refunded_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}'
);

-- =====================================================
-- ADVANCED FEATURES
-- =====================================================

-- Profile themes extended
CREATE TABLE profile_theme_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    theme_id VARCHAR(100) NOT NULL REFERENCES profile_themes(theme_id),
    asset_type VARCHAR(50) NOT NULL, -- 'background', 'pattern', 'accent', 'font'
    asset_name VARCHAR(200) NOT NULL,
    asset_path VARCHAR(500) NOT NULL,
    asset_metadata JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User custom ringtones per contact
CREATE TABLE user_custom_ringtones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    contact_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    sound_id VARCHAR(100) REFERENCES sound_catalog(sound_id),
    custom_volume DECIMAL(3,2) DEFAULT 0.7,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(owner_id, contact_id)
);

-- Profile completion tracking extended
CREATE TABLE profile_completion_tracking (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    basic_info_completed BOOLEAN DEFAULT false,
    avatar_uploaded BOOLEAN DEFAULT false,
    bio_completed BOOLEAN DEFAULT false,
    interests_added BOOLEAN DEFAULT false,
    social_links_added BOOLEAN DEFAULT false,
    privacy_configured BOOLEAN DEFAULT false,
    theme_selected BOOLEAN DEFAULT false,
    sounds_configured BOOLEAN DEFAULT false,
    first_decoration_equipped BOOLEAN DEFAULT false,
    first_friend_added BOOLEAN DEFAULT false,
    completion_percentage DECIMAL(5,2) DEFAULT 0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completion_rewards_claimed JSONB DEFAULT '{}',
    milestones_reached JSONB DEFAULT '{}'
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Preset avatars indexes
CREATE INDEX idx_preset_avatars_category ON preset_avatars(category);
CREATE INDEX idx_preset_avatars_premium ON preset_avatars(is_premium);
CREATE INDEX idx_preset_avatars_active ON preset_avatars(is_active);

-- User avatar uploads indexes
CREATE INDEX idx_user_avatar_uploads_user ON user_avatar_uploads(user_id);
CREATE INDEX idx_user_avatar_uploads_current ON user_avatar_uploads(user_id, is_current);
CREATE INDEX idx_user_avatar_uploads_status ON user_avatar_uploads(upload_status);

-- Sound catalog indexes
CREATE INDEX idx_sound_catalog_category ON sound_catalog(category);
CREATE INDEX idx_sound_catalog_premium ON sound_catalog(is_premium);
CREATE INDEX idx_sound_catalog_type ON sound_catalog(is_ringtone, is_notification);

-- User inventory indexes
CREATE INDEX idx_user_inventory_user_type ON user_inventory(user_id, item_type);
CREATE INDEX idx_user_inventory_equipped ON user_inventory(user_id, equipped);
CREATE INDEX idx_user_inventory_item ON user_inventory(item_id, item_type);

-- Social links indexes
CREATE INDEX idx_user_social_links_user ON user_social_links(user_id);
CREATE INDEX idx_user_social_links_platform ON user_social_links(platform);
CREATE INDEX idx_user_social_links_public ON user_social_links(is_public);

-- Performance metrics indexes
CREATE INDEX idx_performance_metrics_name_time ON performance_metrics(metric_name, recorded_at);
CREATE INDEX idx_performance_metrics_category ON performance_metrics(metric_category);
CREATE INDEX idx_performance_metrics_user ON performance_metrics(user_id);

-- Premium content indexes
CREATE INDEX idx_premium_content_type ON premium_content(content_type);
CREATE INDEX idx_premium_content_active ON premium_content(is_active);
CREATE INDEX idx_premium_purchases_user ON user_premium_purchases(user_id);

-- =====================================================
-- CONSTRAINTS AND VALIDATION
-- =====================================================

-- Avatar upload constraints
ALTER TABLE user_avatar_uploads ADD CONSTRAINT chk_file_size 
    CHECK (file_size <= 5242880); -- 5MB max

ALTER TABLE user_avatar_uploads ADD CONSTRAINT chk_upload_status 
    CHECK (upload_status IN ('processing', 'completed', 'failed', 'rejected'));

-- Sound catalog constraints
ALTER TABLE sound_catalog ADD CONSTRAINT chk_volume_range 
    CHECK (volume_level >= 0.0 AND volume_level <= 1.0);

ALTER TABLE sound_catalog ADD CONSTRAINT chk_duration_positive 
    CHECK (duration_seconds > 0);

-- Privacy settings constraints
ALTER TABLE user_privacy_settings ADD CONSTRAINT chk_profile_visibility 
    CHECK (profile_visibility IN ('public', 'friends', 'private'));

-- Performance metrics constraints
ALTER TABLE performance_metrics ADD CONSTRAINT chk_cpu_range 
    CHECK (cpu_usage_percent >= 0 AND cpu_usage_percent <= 100);

-- Premium content constraints
ALTER TABLE premium_content ADD CONSTRAINT chk_price_positive 
    CHECK (price_gems >= 0 AND price_currency >= 0);

ALTER TABLE premium_content ADD CONSTRAINT chk_discount_range 
    CHECK (discount_percentage >= 0 AND discount_percentage <= 100);

-- =====================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- =====================================================

-- Update profile completion when changes occur
CREATE OR REPLACE FUNCTION update_profile_completion_extended()
RETURNS TRIGGER AS $$
BEGIN
    -- This will be implemented in the triggers file
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Track profile edit history
CREATE OR REPLACE FUNCTION track_profile_edit_history()
RETURNS TRIGGER AS $$
BEGIN
    -- This will be implemented in the triggers file
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON TABLE preset_avatars IS 'Catalog of preset avatar options available to users';
COMMENT ON TABLE user_avatar_uploads IS 'History of user-uploaded custom avatars';
COMMENT ON TABLE sound_catalog IS 'Complete catalog of available sounds for notifications and ringtones';
COMMENT ON TABLE user_inventory IS 'User inventory for all collectible items (decorations, themes, sounds)';
COMMENT ON TABLE user_social_links IS 'User social media profile links and verification status';
COMMENT ON TABLE user_privacy_settings IS 'Granular privacy controls for profile visibility';
COMMENT ON TABLE system_configuration IS 'System-wide configuration storage for production settings';
COMMENT ON TABLE performance_metrics IS 'Performance monitoring and metrics collection';
COMMENT ON TABLE premium_content IS 'Catalog of premium purchasable content and pricing';
COMMENT ON TABLE profile_completion_tracking IS 'Detailed tracking of profile completion progress';

-- =====================================================
-- END OF EXTENDED TABLES
-- =====================================================
