-- Crystal Social UserInfo System - Core Tables and Schema
-- File: 01_userinfo_core_tables.sql
-- Purpose: Complete database schema for comprehensive user information management system

-- =============================================================================
-- CORE USER INFO TABLES
-- =============================================================================

-- Main user info table for categorized and free-text content
CREATE TABLE IF NOT EXISTS user_info (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category VARCHAR(100), -- NULL for free text content
    content TEXT NOT NULL,
    info_type VARCHAR(20) NOT NULL CHECK (info_type IN ('category', 'free_text')),
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User info categories definition table
CREATE TABLE IF NOT EXISTS user_info_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_name VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    description TEXT,
    icon_name VARCHAR(100), -- Material icon name
    color_hex VARCHAR(7) DEFAULT '#8A2BE2', -- Default purple
    category_order INTEGER DEFAULT 0,
    is_system_category BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    max_items INTEGER DEFAULT NULL, -- NULL = unlimited
    is_required BOOLEAN DEFAULT false,
    category_group VARCHAR(50), -- e.g., 'identity', 'personality', 'social'
    validation_rules JSONB DEFAULT '{}', -- JSON validation rules
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User profile completion tracking
CREATE TABLE IF NOT EXISTS user_profile_completion (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    completion_percentage DECIMAL(5,2) DEFAULT 0.00 CHECK (completion_percentage >= 0 AND completion_percentage <= 100),
    total_categories_used INTEGER DEFAULT 0,
    total_items_count INTEGER DEFAULT 0,
    has_free_text BOOLEAN DEFAULT false,
    has_avatar BOOLEAN DEFAULT false,
    has_bio BOOLEAN DEFAULT false,
    last_updated_at TIMESTAMPTZ DEFAULT NOW(),
    completion_score INTEGER DEFAULT 0, -- Detailed scoring system
    profile_quality_score DECIMAL(3,2) DEFAULT 0.00, -- 0-10 quality rating
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User info category preferences (user customization)
CREATE TABLE IF NOT EXISTS user_category_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category_name VARCHAR(100) NOT NULL,
    is_favorite BOOLEAN DEFAULT false,
    is_hidden BOOLEAN DEFAULT false,
    custom_order INTEGER,
    is_expanded BOOLEAN DEFAULT false,
    custom_icon VARCHAR(100), -- Override default icon
    custom_color VARCHAR(7), -- Override default color
    notification_enabled BOOLEAN DEFAULT true,
    last_accessed_at TIMESTAMPTZ,
    access_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, category_name)
);

-- User search and discovery preferences
CREATE TABLE IF NOT EXISTS user_discovery_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    is_discoverable BOOLEAN DEFAULT true,
    allow_profile_views BOOLEAN DEFAULT true,
    show_category_counts BOOLEAN DEFAULT true,
    show_completion_percentage BOOLEAN DEFAULT false,
    searchable_categories TEXT[] DEFAULT '{}', -- Categories to include in search
    privacy_level VARCHAR(20) DEFAULT 'public' CHECK (privacy_level IN ('public', 'friends', 'private')),
    allow_anonymous_views BOOLEAN DEFAULT true,
    profile_view_notifications BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User info interaction tracking
CREATE TABLE IF NOT EXISTS user_info_interactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    viewer_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    viewed_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    interaction_type VARCHAR(50) NOT NULL, -- 'profile_view', 'category_view', 'search'
    category_name VARCHAR(100), -- NULL for general profile views
    interaction_details JSONB DEFAULT '{}',
    session_id UUID, -- Track user sessions
    ip_address INET,
    user_agent TEXT,
    referrer TEXT,
    view_duration_seconds INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User info content moderation
CREATE TABLE IF NOT EXISTS user_info_moderation (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_info_id UUID NOT NULL REFERENCES user_info(id) ON DELETE CASCADE,
    moderator_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    moderation_status VARCHAR(20) DEFAULT 'pending' CHECK (moderation_status IN ('pending', 'approved', 'flagged', 'removed')),
    moderation_reason VARCHAR(255),
    moderation_notes TEXT,
    automated_score DECIMAL(3,2), -- 0-10 automated content score
    contains_sensitive_content BOOLEAN DEFAULT false,
    requires_review BOOLEAN DEFAULT false,
    flagged_by_users UUID[] DEFAULT '{}',
    flag_count INTEGER DEFAULT 0,
    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User info analytics and insights
CREATE TABLE IF NOT EXISTS user_info_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    analysis_date DATE DEFAULT CURRENT_DATE,
    total_profile_views INTEGER DEFAULT 0,
    unique_viewers INTEGER DEFAULT 0,
    category_interactions JSONB DEFAULT '{}', -- Per-category interaction counts
    search_appearances INTEGER DEFAULT 0,
    profile_completion_history JSONB DEFAULT '[]', -- Historical completion data
    popular_categories TEXT[] DEFAULT '{}',
    engagement_score DECIMAL(5,2) DEFAULT 0.00,
    discovery_rank INTEGER DEFAULT 0,
    content_freshness_score DECIMAL(3,2) DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, analysis_date)
);

-- User info backup and versioning
CREATE TABLE IF NOT EXISTS user_info_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    version_number INTEGER DEFAULT 1,
    backup_data JSONB NOT NULL, -- Complete profile backup
    backup_reason VARCHAR(100), -- 'manual', 'scheduled', 'pre_update'
    backup_size_bytes INTEGER DEFAULT 0,
    is_complete_backup BOOLEAN DEFAULT true,
    restoration_count INTEGER DEFAULT 0,
    expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '1 year',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- PREDEFINED CATEGORIES DATA
-- =============================================================================

-- Insert system-defined categories with enhanced metadata
INSERT INTO user_info_categories (
    category_name, display_name, description, icon_name, color_hex, 
    category_order, category_group, max_items
) VALUES
-- Core Identity (Group 1)
('Role', 'Role', 'System role or function within the collective', 'badge', '#2196F3', 1, 'identity', 5),
('Pronouns', 'Pronouns', 'Preferred pronouns and gender identity', 'person', '#9C27B0', 2, 'identity', 3),
('Age', 'Age', 'Age or age range information', 'cake', '#FF9800', 3, 'identity', 2),
('Sexuality', 'Sexuality', 'Sexual orientation and romantic preferences', 'favorite', '#E91E63', 4, 'identity', 5),

-- System/Collective Related (Group 2)
('Animal embodied', 'Animal Embodied', 'Animal forms, connections, or embodiments', 'pets', '#795548', 5, 'system', 10),
('Fronting Frequency', 'Fronting Frequency', 'How often this individual fronts or is active', 'schedule', '#3F51B5', 6, 'system', 3),
('Rank', 'Rank', 'Hierarchy, rank, or status within the system', 'military_tech', '#FFC107', 7, 'system', 5),
('Barrier level', 'Barrier Level', 'Communication barriers, amnesia, or co-consciousness level', 'shield', '#607D8B', 8, 'system', 3),

-- Personality & Psychology (Group 3)
('Personality', 'Personality', 'General personality traits and characteristics', 'psychology', '#009688', 9, 'personality', 15),
('MBTI', 'MBTI Type', 'Myers-Briggs personality type indicator', 'psychology_alt', '#673AB7', 10, 'personality', 2),
('Alignment chart', 'Alignment Chart', 'D&D style moral and ethical alignment', 'grid_on', '#546E7A', 11, 'personality', 2),
('Trigger', 'Triggers', 'Triggers, warnings, and sensitive topics', 'warning', '#F44336', 12, 'personality', 20),

-- Beliefs & Social (Group 4)
('Belief system', 'Belief System', 'Religious, spiritual, or philosophical beliefs', 'auto_awesome', '#FF5722', 13, 'social', 10),
('Cliques', 'Communities', 'Social groups, cliques, or communities involved with', 'group', '#4CAF50', 14, 'social', 15),
('Purpose', 'Life Purpose', 'Life purpose, goals, or role within the system', 'star', '#FFEB3B', 15, 'social', 5),

-- Personal/Intimate (Group 5)
('Sex positioning', 'Sexual Preferences', 'Sexual positioning and intimate preferences', 'bedtime', '#FF4081', 16, 'intimate', 10),
('Song', 'Theme Songs', 'Theme songs, favorite music, or musical identity', 'music_note', '#00BCD4', 17, 'personal', 20)

ON CONFLICT (category_name) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    description = EXCLUDED.description,
    icon_name = EXCLUDED.icon_name,
    color_hex = EXCLUDED.color_hex,
    category_order = EXCLUDED.category_order,
    category_group = EXCLUDED.category_group,
    max_items = EXCLUDED.max_items,
    updated_at = NOW();

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- Primary indexes for user_info table
CREATE INDEX IF NOT EXISTS idx_user_info_user_id ON user_info(user_id);
CREATE INDEX IF NOT EXISTS idx_user_info_category ON user_info(category);
CREATE INDEX IF NOT EXISTS idx_user_info_type ON user_info(info_type);
CREATE INDEX IF NOT EXISTS idx_user_info_created_at ON user_info(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_info_user_category ON user_info(user_id, category);
CREATE INDEX IF NOT EXISTS idx_user_info_content_search ON user_info USING gin(to_tsvector('english', content));

-- Indexes for user_info_categories
CREATE INDEX IF NOT EXISTS idx_user_info_categories_active ON user_info_categories(is_active);
CREATE INDEX IF NOT EXISTS idx_user_info_categories_group ON user_info_categories(category_group);
CREATE INDEX IF NOT EXISTS idx_user_info_categories_order ON user_info_categories(category_order);

-- Indexes for profile completion
CREATE INDEX IF NOT EXISTS idx_profile_completion_user ON user_profile_completion(user_id);
CREATE INDEX IF NOT EXISTS idx_profile_completion_percentage ON user_profile_completion(completion_percentage DESC);
CREATE INDEX IF NOT EXISTS idx_profile_completion_score ON user_profile_completion(completion_score DESC);
CREATE INDEX IF NOT EXISTS idx_profile_completion_updated ON user_profile_completion(last_updated_at DESC);

-- Indexes for category preferences
CREATE INDEX IF NOT EXISTS idx_category_prefs_user ON user_category_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_category_prefs_category ON user_category_preferences(category_name);
CREATE INDEX IF NOT EXISTS idx_category_prefs_favorites ON user_category_preferences(user_id, is_favorite) WHERE is_favorite = true;
CREATE INDEX IF NOT EXISTS idx_category_prefs_hidden ON user_category_preferences(user_id, is_hidden) WHERE is_hidden = true;

-- Indexes for discovery settings
CREATE INDEX IF NOT EXISTS idx_discovery_discoverable ON user_discovery_settings(is_discoverable) WHERE is_discoverable = true;
CREATE INDEX IF NOT EXISTS idx_discovery_privacy ON user_discovery_settings(privacy_level);

-- Indexes for interactions tracking
CREATE INDEX IF NOT EXISTS idx_interactions_viewer ON user_info_interactions(viewer_user_id);
CREATE INDEX IF NOT EXISTS idx_interactions_viewed ON user_info_interactions(viewed_user_id);
CREATE INDEX IF NOT EXISTS idx_interactions_type ON user_info_interactions(interaction_type);
CREATE INDEX IF NOT EXISTS idx_interactions_created ON user_info_interactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_interactions_session ON user_info_interactions(session_id) WHERE session_id IS NOT NULL;

-- Indexes for moderation
CREATE INDEX IF NOT EXISTS idx_moderation_status ON user_info_moderation(moderation_status);
CREATE INDEX IF NOT EXISTS idx_moderation_pending ON user_info_moderation(moderation_status, created_at) WHERE moderation_status = 'pending';
CREATE INDEX IF NOT EXISTS idx_moderation_flagged ON user_info_moderation(flag_count DESC) WHERE flag_count > 0;

-- Indexes for analytics
CREATE INDEX IF NOT EXISTS idx_analytics_user_date ON user_info_analytics(user_id, analysis_date);
CREATE INDEX IF NOT EXISTS idx_analytics_engagement ON user_info_analytics(engagement_score DESC);
CREATE INDEX IF NOT EXISTS idx_analytics_rank ON user_info_analytics(discovery_rank) WHERE discovery_rank > 0;

-- Indexes for versions
CREATE INDEX IF NOT EXISTS idx_versions_user ON user_info_versions(user_id);
CREATE INDEX IF NOT EXISTS idx_versions_created ON user_info_versions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_versions_expires ON user_info_versions(expires_at) WHERE expires_at IS NOT NULL;

-- =============================================================================
-- FULL-TEXT SEARCH CONFIGURATION
-- =============================================================================

-- Create custom text search configuration for user content
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_ts_config WHERE cfgname = 'user_content_search'
    ) THEN
        CREATE TEXT SEARCH CONFIGURATION user_content_search (COPY = english);
    END IF;
END $$;

-- Full-text search index for user content
CREATE INDEX IF NOT EXISTS idx_user_info_fulltext_search 
ON user_info USING gin(to_tsvector('user_content_search', 
    COALESCE(category, '') || ' ' || COALESCE(content, '')
));

-- =============================================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- =============================================================================

-- Apply updated_at triggers to all relevant tables
-- Note: update_updated_at_column() function is defined in 00_shared_utilities.sql
CREATE TRIGGER update_user_info_updated_at
    BEFORE UPDATE ON user_info
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_info_categories_updated_at
    BEFORE UPDATE ON user_info_categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_profile_completion_updated_at
    BEFORE UPDATE ON user_profile_completion
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_category_preferences_updated_at
    BEFORE UPDATE ON user_category_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_discovery_settings_updated_at
    BEFORE UPDATE ON user_discovery_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_info_moderation_updated_at
    BEFORE UPDATE ON user_info_moderation
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_info_analytics_updated_at
    BEFORE UPDATE ON user_info_analytics
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- CONSTRAINTS AND VALIDATIONS
-- =============================================================================

-- Additional check constraints
ALTER TABLE user_info ADD CONSTRAINT check_content_length 
    CHECK (char_length(content) > 0 AND char_length(content) <= 2000);

ALTER TABLE user_info ADD CONSTRAINT check_category_or_free_text 
    CHECK (
        (info_type = 'category' AND category IS NOT NULL) OR 
        (info_type = 'free_text' AND category IS NULL)
    );

ALTER TABLE user_profile_completion ADD CONSTRAINT check_completion_bounds 
    CHECK (completion_percentage >= 0 AND completion_percentage <= 100);

ALTER TABLE user_profile_completion ADD CONSTRAINT check_score_bounds 
    CHECK (completion_score >= 0 AND profile_quality_score >= 0 AND profile_quality_score <= 10);

ALTER TABLE user_category_preferences ADD CONSTRAINT check_custom_order_positive 
    CHECK (custom_order IS NULL OR custom_order >= 0);

ALTER TABLE user_info_analytics ADD CONSTRAINT check_analytics_positive_values 
    CHECK (
        total_profile_views >= 0 AND 
        unique_viewers >= 0 AND 
        search_appearances >= 0 AND
        engagement_score >= 0 AND
        discovery_rank >= 0 AND
        content_freshness_score >= 0 AND
        content_freshness_score <= 10
    );

-- =============================================================================
-- PARTITIONING FOR LARGE TABLES
-- =============================================================================

-- Partition user_info_interactions by month for better performance
-- Note: This would be implemented if the table grows very large
-- CREATE TABLE user_info_interactions_y2024m01 PARTITION OF user_info_interactions
-- FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE user_info IS 'Core table storing user profile information in categories and free text';
COMMENT ON TABLE user_info_categories IS 'System-defined and custom categories for organizing user information';
COMMENT ON TABLE user_profile_completion IS 'Tracks user profile completion status and quality metrics';
COMMENT ON TABLE user_category_preferences IS 'User-specific customization preferences for categories';
COMMENT ON TABLE user_discovery_settings IS 'User privacy and discovery preferences';
COMMENT ON TABLE user_info_interactions IS 'Tracks profile views and interactions for analytics';
COMMENT ON TABLE user_info_moderation IS 'Content moderation tracking for user information';
COMMENT ON TABLE user_info_analytics IS 'Daily analytics and insights for user profiles';
COMMENT ON TABLE user_info_versions IS 'Profile backup and versioning system';

COMMENT ON COLUMN user_info.info_type IS 'Either "category" for categorized content or "free_text" for open writing';
COMMENT ON COLUMN user_info_categories.validation_rules IS 'JSON object containing validation rules for category content';
COMMENT ON COLUMN user_profile_completion.completion_score IS 'Detailed scoring system considering content quality and completeness';
COMMENT ON COLUMN user_discovery_settings.privacy_level IS 'Controls who can discover and view the user profile';
COMMENT ON COLUMN user_info_interactions.view_duration_seconds IS 'How long the user spent viewing the profile/category';
COMMENT ON COLUMN user_info_moderation.automated_score IS 'AI/automated content safety score from 0-10';
COMMENT ON COLUMN user_info_analytics.engagement_score IS 'Overall engagement score based on views, interactions, and content quality';

-- Setup completion message
SELECT 'UserInfo Core Tables Setup Complete!' as status, NOW() as setup_completed_at;
