-- Crystal Social Widgets System - Core Tables
-- File: 01_widgets_core_tables.sql
-- Purpose: Database schema for comprehensive widget system including stickers, emoticons, backgrounds, analytics, and user preferences

-- =============================================================================
-- ENABLE EXTENSIONS
-- =============================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- STICKER SYSTEM TABLES
-- =============================================================================

-- Main stickers table with metadata and categorization
CREATE TABLE IF NOT EXISTS stickers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    sticker_name TEXT NOT NULL,
    sticker_url TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'Other',
    is_gif BOOLEAN DEFAULT false,
    file_size INTEGER DEFAULT 0,
    width INTEGER DEFAULT 0,
    height INTEGER DEFAULT 0,
    format TEXT DEFAULT 'png', -- png, jpg, gif, webp
    is_public BOOLEAN DEFAULT false,
    is_approved BOOLEAN DEFAULT false,
    upload_source TEXT DEFAULT 'user', -- user, preset, import
    tags TEXT[], -- searchable tags
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_category CHECK (category IN (
        'Emotions', 'Animals', 'Nature', 'Food', 'Activities', 
        'Objects', 'Travel', 'Sports', 'Symbols', 'Other'
    )),
    CONSTRAINT valid_format CHECK (format IN ('png', 'jpg', 'jpeg', 'gif', 'webp')),
    CONSTRAINT positive_file_size CHECK (file_size >= 0),
    CONSTRAINT positive_dimensions CHECK (width >= 0 AND height >= 0)
);

-- Recent stickers usage tracking
CREATE TABLE IF NOT EXISTS recent_stickers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    sticker_url TEXT NOT NULL,
    used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    context_type TEXT DEFAULT 'message', -- message, comment, reaction
    
    UNIQUE(user_id, sticker_url)
);

-- Sticker collections/favorites
CREATE TABLE IF NOT EXISTS sticker_collections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    collection_name TEXT NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT false,
    sticker_ids UUID[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, collection_name)
);

-- =============================================================================
-- EMOTICON SYSTEM TABLES
-- =============================================================================

-- Emoticon categories and presets
CREATE TABLE IF NOT EXISTS emoticon_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_name TEXT NOT NULL UNIQUE,
    display_name TEXT NOT NULL,
    emoji_icon TEXT,
    category_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Custom emoticons created by users
CREATE TABLE IF NOT EXISTS custom_emoticons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    emoticon_text TEXT NOT NULL,
    emoticon_name TEXT,
    category_id UUID REFERENCES emoticon_categories(id),
    is_public BOOLEAN DEFAULT false,
    is_approved BOOLEAN DEFAULT false,
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, emoticon_text)
);

-- Emoticon usage tracking
CREATE TABLE IF NOT EXISTS emoticon_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    emoticon_text TEXT NOT NULL,
    category_name TEXT,
    used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    context_type TEXT DEFAULT 'message'
);

-- User emoticon favorites
CREATE TABLE IF NOT EXISTS emoticon_favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    emoticon_text TEXT NOT NULL,
    favorited_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, emoticon_text)
);

-- =============================================================================
-- BACKGROUND SYSTEM TABLES
-- =============================================================================

-- Chat background presets and custom backgrounds
CREATE TABLE IF NOT EXISTS chat_backgrounds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    background_name TEXT NOT NULL,
    background_type TEXT NOT NULL, -- gradient, image, pattern, solid
    background_data JSONB NOT NULL, -- stores gradient colors, image URL, pattern config, etc.
    preview_url TEXT,
    category TEXT DEFAULT 'Custom',
    is_preset BOOLEAN DEFAULT false,
    is_public BOOLEAN DEFAULT false,
    created_by UUID REFERENCES auth.users(id),
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_background_type CHECK (background_type IN (
        'gradient', 'image', 'pattern', 'solid'
    ))
);

-- User background preferences per chat
CREATE TABLE IF NOT EXISTS user_chat_backgrounds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    chat_id TEXT NOT NULL,
    background_id UUID REFERENCES chat_backgrounds(id),
    custom_opacity DECIMAL(3,2) DEFAULT 1.0,
    custom_blur DECIMAL(4,1) DEFAULT 0.0,
    custom_effects JSONB DEFAULT '{}',
    set_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, chat_id),
    CONSTRAINT valid_opacity CHECK (custom_opacity >= 0.0 AND custom_opacity <= 1.0),
    CONSTRAINT valid_blur CHECK (custom_blur >= 0.0 AND custom_blur <= 50.0)
);

-- =============================================================================
-- MESSAGE SYSTEM TABLES
-- =============================================================================

-- Enhanced message bubbles with metadata
CREATE TABLE IF NOT EXISTS message_bubbles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    chat_id TEXT NOT NULL,
    message_type TEXT DEFAULT 'text', -- text, image, audio, video, sticker, gif
    content TEXT,
    media_url TEXT,
    sticker_url TEXT,
    gif_url TEXT,
    effect_type TEXT, -- pulse, float, bounce, shake, none
    is_secret BOOLEAN DEFAULT false,
    mood TEXT,
    importance_level TEXT DEFAULT 'normal', -- low, normal, high, urgent
    
    -- Reply system
    reply_to_message_id TEXT,
    reply_to_text TEXT,
    reply_to_username TEXT,
    
    -- Message status
    is_edited BOOLEAN DEFAULT false,
    is_forwarded BOOLEAN DEFAULT false,
    forward_count INTEGER DEFAULT 0,
    
    -- Rich content
    mentions TEXT[] DEFAULT '{}',
    hashtags TEXT[] DEFAULT '{}',
    metadata JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_message_type CHECK (message_type IN (
        'text', 'image', 'audio', 'video', 'sticker', 'gif'
    )),
    CONSTRAINT valid_effect CHECK (effect_type IN (
        'pulse', 'float', 'bounce', 'shake', 'none'
    )),
    CONSTRAINT valid_importance CHECK (importance_level IN (
        'low', 'normal', 'high', 'urgent'
    ))
);

-- Message reactions system
CREATE TABLE IF NOT EXISTS message_reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    reaction_emoji TEXT NOT NULL,
    reaction_type TEXT DEFAULT 'emoji', -- emoji, sticker, custom
    reacted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(message_id, user_id, reaction_emoji)
);

-- =============================================================================
-- USER PREFERENCES AND SETTINGS
-- =============================================================================

-- Comprehensive user widget preferences
CREATE TABLE IF NOT EXISTS user_widget_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Sticker preferences
    favorite_sticker_categories TEXT[] DEFAULT '{}',
    sticker_auto_suggest BOOLEAN DEFAULT true,
    sticker_size_preference TEXT DEFAULT 'medium', -- small, medium, large
    
    -- Emoticon preferences  
    favorite_emoticon_categories TEXT[] DEFAULT '{}',
    emoticon_auto_suggest BOOLEAN DEFAULT true,
    show_emoticon_preview BOOLEAN DEFAULT true,
    
    -- Background preferences
    default_chat_background_id UUID REFERENCES chat_backgrounds(id),
    background_auto_change BOOLEAN DEFAULT false,
    background_sync_across_chats BOOLEAN DEFAULT false,
    
    -- Message bubble preferences
    enable_message_effects BOOLEAN DEFAULT true,
    auto_play_gifs BOOLEAN DEFAULT true,
    show_message_previews BOOLEAN DEFAULT true,
    bubble_corner_radius INTEGER DEFAULT 12,
    
    -- Performance preferences
    reduce_animations BOOLEAN DEFAULT false,
    limit_gif_size BOOLEAN DEFAULT true,
    compress_images BOOLEAN DEFAULT true,
    
    -- Privacy preferences
    share_stickers_publicly BOOLEAN DEFAULT false,
    share_emoticons_publicly BOOLEAN DEFAULT false,
    allow_sticker_suggestions BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_sticker_size CHECK (sticker_size_preference IN ('small', 'medium', 'large')),
    CONSTRAINT valid_corner_radius CHECK (bubble_corner_radius >= 0 AND bubble_corner_radius <= 50)
);

-- =============================================================================
-- ANALYTICS AND USAGE TRACKING
-- =============================================================================

-- Widget usage analytics
CREATE TABLE IF NOT EXISTS widget_usage_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    widget_type TEXT NOT NULL, -- sticker_picker, emoticon_picker, background_picker, etc.
    action_type TEXT NOT NULL, -- open, select, create, share, favorite
    item_identifier TEXT, -- sticker URL, emoticon text, background ID
    category TEXT,
    usage_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    session_id TEXT,
    metadata JSONB DEFAULT '{}',
    
    CONSTRAINT valid_widget_type CHECK (widget_type IN (
        'sticker_picker', 'emoticon_picker', 'background_picker', 
        'message_bubble', 'glimmer_upload', 'coin_earning'
    )),
    CONSTRAINT valid_action_type CHECK (action_type IN (
        'open', 'select', 'create', 'share', 'favorite', 'search', 'category_change'
    ))
);

-- Daily widget statistics
CREATE TABLE IF NOT EXISTS daily_widget_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stat_date DATE NOT NULL,
    widget_type TEXT NOT NULL,
    
    -- Usage metrics
    total_opens INTEGER DEFAULT 0,
    unique_users INTEGER DEFAULT 0,
    total_selections INTEGER DEFAULT 0,
    total_creations INTEGER DEFAULT 0,
    
    -- Category breakdown
    category_usage JSONB DEFAULT '{}',
    
    -- Performance metrics
    avg_session_duration INTERVAL,
    avg_items_per_session DECIMAL(5,2) DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(stat_date, widget_type)
);

-- =============================================================================
-- GEMSTONE INTEGRATION TABLES
-- =============================================================================

-- Message analysis and gemstone triggers
CREATE TABLE IF NOT EXISTS message_analysis_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    message_content TEXT NOT NULL,
    analysis_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Analysis results
    detected_keywords TEXT[] DEFAULT '{}',
    sentiment_score DECIMAL(3,2), -- -1.0 to 1.0
    emotion_categories TEXT[] DEFAULT '{}',
    
    -- Gemstone triggers
    triggered_gems TEXT[] DEFAULT '{}',
    gems_unlocked INTEGER DEFAULT 0,
    
    -- Context
    chat_id TEXT,
    message_context JSONB DEFAULT '{}',
    
    CONSTRAINT valid_sentiment CHECK (sentiment_score >= -1.0 AND sentiment_score <= 1.0)
);

-- Gem unlock analytics through message analysis
CREATE TABLE IF NOT EXISTS gem_unlock_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    gem_id TEXT NOT NULL,
    gem_name TEXT NOT NULL,
    trigger_type TEXT NOT NULL, -- message_keyword, emotion_analysis, pattern_match
    message_content TEXT, -- truncated for privacy
    unlock_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    analysis_metadata JSONB DEFAULT '{}'
);

-- =============================================================================
-- GLIMMER INTEGRATION TABLES
-- =============================================================================

-- Glimmer uploads and posts
CREATE TABLE IF NOT EXISTS glimmer_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    image_url TEXT NOT NULL,
    category TEXT NOT NULL,
    tags TEXT[] DEFAULT '{}',
    
    -- Engagement metrics
    view_count INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    share_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    
    -- Status
    is_public BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    moderation_status TEXT DEFAULT 'pending', -- pending, approved, rejected
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_moderation_status CHECK (moderation_status IN (
        'pending', 'approved', 'rejected'
    ))
);

-- =============================================================================
-- LOCAL STORAGE SYNC TABLES
-- =============================================================================

-- User data synchronization between local and cloud storage
CREATE TABLE IF NOT EXISTS user_local_sync (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    data_type TEXT NOT NULL, -- preferences, favorites, recent_usage
    local_data JSONB NOT NULL,
    cloud_data JSONB,
    last_sync_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sync_status TEXT DEFAULT 'pending', -- pending, synced, conflict
    conflict_resolution TEXT DEFAULT 'cloud_wins', -- cloud_wins, local_wins, manual
    
    UNIQUE(user_id, data_type),
    CONSTRAINT valid_sync_status CHECK (sync_status IN ('pending', 'synced', 'conflict')),
    CONSTRAINT valid_resolution CHECK (conflict_resolution IN (
        'cloud_wins', 'local_wins', 'manual'
    ))
);

-- =============================================================================
-- PERFORMANCE AND CACHING TABLES
-- =============================================================================

-- Widget performance metrics
CREATE TABLE IF NOT EXISTS widget_performance_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    widget_type TEXT NOT NULL,
    metric_name TEXT NOT NULL, -- load_time, render_time, memory_usage, crash_count
    metric_value DECIMAL(10,2) NOT NULL,
    device_info JSONB DEFAULT '{}',
    app_version TEXT,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_metric_value CHECK (metric_value >= 0)
);

-- Cache management for widgets
CREATE TABLE IF NOT EXISTS widget_cache_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cache_key TEXT NOT NULL UNIQUE,
    cache_type TEXT NOT NULL, -- image, data, preferences
    cached_data JSONB,
    cached_url TEXT,
    file_size INTEGER DEFAULT 0,
    expires_at TIMESTAMP WITH TIME ZONE,
    last_accessed TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    access_count INTEGER DEFAULT 1,
    
    CONSTRAINT valid_cache_type CHECK (cache_type IN ('image', 'data', 'preferences')),
    CONSTRAINT positive_file_size CHECK (file_size >= 0)
);

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- Stickers indexes
CREATE INDEX IF NOT EXISTS idx_stickers_user_id ON stickers(user_id);
CREATE INDEX IF NOT EXISTS idx_stickers_category ON stickers(category);
CREATE INDEX IF NOT EXISTS idx_stickers_public_approved ON stickers(is_public, is_approved) WHERE is_public = true;
CREATE INDEX IF NOT EXISTS idx_stickers_usage_count ON stickers(usage_count DESC);
CREATE INDEX IF NOT EXISTS idx_stickers_tags ON stickers USING GIN(tags);

-- Recent stickers indexes
CREATE INDEX IF NOT EXISTS idx_recent_stickers_user_used ON recent_stickers(user_id, used_at DESC);

-- Emoticons indexes
CREATE INDEX IF NOT EXISTS idx_emoticon_usage_user_date ON emoticon_usage(user_id, used_at DESC);
CREATE INDEX IF NOT EXISTS idx_emoticon_favorites_user ON emoticon_favorites(user_id);

-- Backgrounds indexes
CREATE INDEX IF NOT EXISTS idx_chat_backgrounds_type ON chat_backgrounds(background_type);
CREATE INDEX IF NOT EXISTS idx_chat_backgrounds_public ON chat_backgrounds(is_public) WHERE is_public = true;
CREATE INDEX IF NOT EXISTS idx_user_chat_backgrounds_user_chat ON user_chat_backgrounds(user_id, chat_id);

-- Messages indexes
CREATE INDEX IF NOT EXISTS idx_message_bubbles_chat_created ON message_bubbles(chat_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_message_bubbles_user ON message_bubbles(user_id);
CREATE INDEX IF NOT EXISTS idx_message_reactions_message ON message_reactions(message_id);

-- Analytics indexes
CREATE INDEX IF NOT EXISTS idx_widget_analytics_user_timestamp ON widget_usage_analytics(user_id, usage_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_widget_analytics_type_action ON widget_usage_analytics(widget_type, action_type);
CREATE INDEX IF NOT EXISTS idx_daily_stats_date_widget ON daily_widget_stats(stat_date DESC, widget_type);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_widget_cache_key ON widget_cache_entries(cache_key);
CREATE INDEX IF NOT EXISTS idx_widget_cache_expires ON widget_cache_entries(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_widget_cache_accessed ON widget_cache_entries(last_accessed DESC);

-- =============================================================================
-- POPULATE DEFAULT DATA
-- =============================================================================

-- Insert default emoticon categories
INSERT INTO emoticon_categories (category_name, display_name, emoji_icon, category_order) VALUES
('Happy', 'Happy & Joy', '😊', 1),
('Love', 'Love & Heart', '❤️', 2),
('Funny', 'Funny & Silly', '😄', 3),
('Sad', 'Sad & Disappointed', '😢', 4),
('Cool', 'Cool & Awesome', '😎', 5),
('Animals', 'Animals & Creatures', '🐱', 6)
ON CONFLICT (category_name) DO NOTHING;

-- Insert default background presets
INSERT INTO chat_backgrounds (background_name, background_type, background_data, category, is_preset) VALUES
('Sunset Gradient', 'gradient', '{"colors": ["#FF6B6B", "#FFE66D", "#4ECDC4"], "direction": "topLeft"}', 'Gradients', true),
('Ocean Waves', 'gradient', '{"colors": ["#667eea", "#764ba2"], "direction": "topCenter"}', 'Gradients', true),
('Forest Dream', 'gradient', '{"colors": ["#134E5E", "#71B280"], "direction": "topLeft"}', 'Gradients', true),
('Cherry Blossom', 'gradient', '{"colors": ["#FFB6C1", "#FFE4E1", "#FFB6C1"], "direction": "topCenter"}', 'Gradients', true),
('Midnight Blue', 'solid', '{"color": "#191970"}', 'Solid Colors', true),
('Soft Pink', 'solid', '{"color": "#FFB6C1"}', 'Solid Colors', true),
('Deep Purple', 'solid', '{"color": "#483D8B"}', 'Solid Colors', true)
ON CONFLICT DO NOTHING;

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE stickers IS 'Main stickers table with categorization and metadata for user-uploaded and preset stickers';
COMMENT ON TABLE recent_stickers IS 'Tracking recently used stickers per user for quick access';
COMMENT ON TABLE sticker_collections IS 'User-created sticker collections and favorites';
COMMENT ON TABLE emoticon_categories IS 'Predefined emoticon categories for organization';
COMMENT ON TABLE custom_emoticons IS 'User-created custom emoticons with approval system';
COMMENT ON TABLE emoticon_usage IS 'Tracking emoticon usage for analytics and recommendations';
COMMENT ON TABLE chat_backgrounds IS 'Chat background presets and custom backgrounds';
COMMENT ON TABLE user_chat_backgrounds IS 'User-specific background settings per chat';
COMMENT ON TABLE message_bubbles IS 'Enhanced message data with effects, reactions, and metadata';
COMMENT ON TABLE message_reactions IS 'User reactions to messages (emoji, stickers, custom)';
COMMENT ON TABLE user_widget_preferences IS 'Comprehensive user preferences for all widget systems';
COMMENT ON TABLE widget_usage_analytics IS 'Detailed analytics for widget usage patterns';
COMMENT ON TABLE message_analysis_results IS 'Message analysis results for gemstone triggers and sentiment';
COMMENT ON TABLE glimmer_posts IS 'Glimmer posts uploaded through widget system';
COMMENT ON TABLE user_local_sync IS 'Synchronization data between local and cloud storage';
COMMENT ON TABLE widget_performance_metrics IS 'Performance monitoring for widget optimization';
COMMENT ON TABLE widget_cache_entries IS 'Cache management for improved widget performance';

-- Setup completion message
SELECT 'Widgets Core Tables Setup Complete!' as status, NOW() as setup_completed_at;
