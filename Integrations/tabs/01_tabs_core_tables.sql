-- Crystal Social Tabs System - Core Tables and Infrastructure
-- File: 01_tabs_core_tables.sql
-- Purpose: Foundation tables for the comprehensive tabs navigation and content system

-- =============================================================================
-- TABS CORE INFRASTRUCTURE
-- =============================================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For text search optimization
CREATE EXTENSION IF NOT EXISTS "btree_gin"; -- For multi-column indexes

-- =============================================================================
-- TAB CONFIGURATION AND MANAGEMENT
-- =============================================================================

-- Tab definitions and configurations
CREATE TABLE tab_definitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tab_name VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    description TEXT,
    icon_path VARCHAR(500),
    tab_order INTEGER DEFAULT 0,
    
    -- Tab properties
    is_enabled BOOLEAN DEFAULT true,
    is_production_ready BOOLEAN DEFAULT false,
    requires_authentication BOOLEAN DEFAULT true,
    requires_premium BOOLEAN DEFAULT false,
    minimum_app_version VARCHAR(20),
    
    -- Configuration settings
    tab_config JSONB DEFAULT '{}',
    feature_flags JSONB DEFAULT '{}',
    performance_config JSONB DEFAULT '{}',
    
    -- Environment settings
    show_in_production BOOLEAN DEFAULT true,
    show_in_development BOOLEAN DEFAULT true,
    show_in_testing BOOLEAN DEFAULT true,
    
    -- Access control
    required_permissions TEXT[] DEFAULT '{}',
    blocked_permissions TEXT[] DEFAULT '{}',
    age_restriction INTEGER DEFAULT 0, -- Minimum age required
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CHECK (tab_order >= 0),
    CHECK (age_restriction >= 0 AND age_restriction <= 18)
);

-- User tab preferences and customization
CREATE TABLE user_tab_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    tab_name VARCHAR(100) NOT NULL REFERENCES tab_definitions(tab_name) ON DELETE CASCADE,
    
    -- User customization
    is_favorite BOOLEAN DEFAULT false,
    is_hidden BOOLEAN DEFAULT false,
    custom_order INTEGER,
    last_accessed_at TIMESTAMPTZ,
    access_count INTEGER DEFAULT 0,
    
    -- Notification settings
    notifications_enabled BOOLEAN DEFAULT true,
    push_notifications BOOLEAN DEFAULT true,
    email_notifications BOOLEAN DEFAULT false,
    
    -- Display preferences
    custom_display_name VARCHAR(255),
    custom_icon_path VARCHAR(500),
    theme_color VARCHAR(7), -- Hex color code
    
    -- Usage tracking
    total_time_spent_minutes INTEGER DEFAULT 0,
    session_count INTEGER DEFAULT 0,
    last_session_duration_minutes INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(user_id, tab_name),
    CHECK (custom_order >= 0)
);

-- Tab categories for organization
CREATE TABLE tab_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_name VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    description TEXT,
    icon_path VARCHAR(500),
    category_order INTEGER DEFAULT 0,
    color_scheme VARCHAR(7) DEFAULT '#8A2BE2',
    
    -- Visibility settings
    is_visible BOOLEAN DEFAULT true,
    requires_premium BOOLEAN DEFAULT false,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CHECK (category_order >= 0)
);

-- Junction table for tab-category relationships
CREATE TABLE tab_category_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tab_name VARCHAR(100) NOT NULL REFERENCES tab_definitions(tab_name) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES tab_categories(id) ON DELETE CASCADE,
    assignment_order INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(tab_name, category_id),
    CHECK (assignment_order >= 0)
);

-- =============================================================================
-- HOME SCREEN AND APP GRID SYSTEM
-- =============================================================================

-- App items displayed on home screen
CREATE TABLE home_screen_apps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    app_name VARCHAR(100) UNIQUE NOT NULL,
    display_title VARCHAR(255) NOT NULL,
    subtitle TEXT,
    icon_path VARCHAR(500),
    color_scheme VARCHAR(7) DEFAULT '#8A2BE2',
    
    -- App properties
    is_enabled BOOLEAN DEFAULT true,
    is_new BOOLEAN DEFAULT false,
    is_premium BOOLEAN DEFAULT false,
    requires_auth BOOLEAN DEFAULT true,
    
    -- Grid positioning
    grid_position INTEGER DEFAULT 0,
    category_id UUID REFERENCES tab_categories(id),
    
    -- Navigation target
    target_tab VARCHAR(100) REFERENCES tab_definitions(tab_name),
    target_screen VARCHAR(255), -- For external navigation
    target_url TEXT, -- For web links
    
    -- Display metadata
    notification_count INTEGER DEFAULT 0,
    badge_text VARCHAR(50),
    badge_color VARCHAR(7),
    
    -- Usage analytics
    total_launches INTEGER DEFAULT 0,
    last_launched_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CHECK (grid_position >= 0),
    CHECK (notification_count >= 0)
);

-- User customization of home screen
CREATE TABLE user_home_screen_layout (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    app_id UUID NOT NULL REFERENCES home_screen_apps(id) ON DELETE CASCADE,
    
    -- Layout customization
    custom_position INTEGER,
    is_hidden BOOLEAN DEFAULT false,
    is_pinned BOOLEAN DEFAULT false,
    custom_size VARCHAR(20) DEFAULT 'normal', -- small, normal, large
    
    -- User-specific metadata
    personal_nickname VARCHAR(255),
    personal_notes TEXT,
    usage_priority INTEGER DEFAULT 0, -- User-defined priority
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(user_id, app_id),
    CHECK (custom_position >= 0),
    CHECK (usage_priority >= 0),
    CHECK (custom_size IN ('small', 'normal', 'large'))
);

-- =============================================================================
-- GLITTER BOARD SOCIAL PLATFORM
-- =============================================================================

-- Main posts table for Glitter Board
CREATE TABLE glitter_posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Post content
    text_content TEXT NOT NULL,
    mood VARCHAR(10) DEFAULT '✨',
    image_url TEXT,
    image_alt_text TEXT,
    video_url TEXT,
    
    -- Post metadata
    tags TEXT[] DEFAULT '{}',
    location VARCHAR(255),
    is_pinned BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,
    
    -- Engagement metrics
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    shares_count INTEGER DEFAULT 0,
    views_count INTEGER DEFAULT 0,
    
    -- Content moderation
    is_deleted BOOLEAN DEFAULT false,
    is_reported BOOLEAN DEFAULT false,
    moderation_status VARCHAR(20) DEFAULT 'approved', -- pending, approved, rejected
    moderation_reason TEXT,
    moderated_by UUID REFERENCES auth.users(id),
    moderated_at TIMESTAMPTZ,
    
    -- Privacy settings
    visibility VARCHAR(20) DEFAULT 'public', -- public, friends, private
    allow_comments BOOLEAN DEFAULT true,
    allow_shares BOOLEAN DEFAULT true,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CHECK (char_length(text_content) <= 2000),
    CHECK (likes_count >= 0),
    CHECK (comments_count >= 0),
    CHECK (shares_count >= 0),
    CHECK (views_count >= 0),
    CHECK (moderation_status IN ('pending', 'approved', 'rejected')),
    CHECK (visibility IN ('public', 'friends', 'private'))
);

-- Comments on Glitter Board posts
CREATE TABLE glitter_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES glitter_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    parent_comment_id UUID REFERENCES glitter_comments(id) ON DELETE CASCADE,
    
    -- Comment content
    text_content TEXT NOT NULL,
    image_url TEXT,
    
    -- Engagement
    likes_count INTEGER DEFAULT 0,
    replies_count INTEGER DEFAULT 0,
    
    -- Moderation
    is_deleted BOOLEAN DEFAULT false,
    is_reported BOOLEAN DEFAULT false,
    moderation_status VARCHAR(20) DEFAULT 'approved',
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CHECK (char_length(text_content) <= 1000),
    CHECK (likes_count >= 0),
    CHECK (replies_count >= 0),
    CHECK (moderation_status IN ('pending', 'approved', 'rejected'))
);

-- Likes and reactions for posts and comments
CREATE TABLE glitter_reactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    target_type VARCHAR(20) NOT NULL, -- post, comment
    target_id UUID NOT NULL,
    
    -- Reaction details
    reaction_type VARCHAR(20) DEFAULT 'like', -- like, love, laugh, sad, angry
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(user_id, target_type, target_id),
    CHECK (target_type IN ('post', 'comment')),
    CHECK (reaction_type IN ('like', 'love', 'laugh', 'sad', 'angry'))
);

-- =============================================================================
-- HOROSCOPE AND SPIRITUAL FEATURES
-- =============================================================================

-- Zodiac signs and their properties
CREATE TABLE zodiac_signs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sign_name VARCHAR(50) UNIQUE NOT NULL,
    sign_symbol VARCHAR(10) NOT NULL,
    element VARCHAR(20) NOT NULL, -- fire, earth, air, water
    quality VARCHAR(20) NOT NULL, -- cardinal, fixed, mutable
    ruling_planet VARCHAR(50),
    
    -- Date ranges
    start_date VARCHAR(10) NOT NULL, -- MM-DD format
    end_date VARCHAR(10) NOT NULL,
    
    -- Characteristics
    positive_traits TEXT[] DEFAULT '{}',
    negative_traits TEXT[] DEFAULT '{}',
    compatible_signs TEXT[] DEFAULT '{}',
    
    -- Display properties
    color_scheme VARCHAR(7) DEFAULT '#8A2BE2',
    icon_path VARCHAR(500),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CHECK (element IN ('fire', 'earth', 'air', 'water')),
    CHECK (quality IN ('cardinal', 'fixed', 'mutable'))
);

-- Daily horoscope readings
CREATE TABLE horoscope_readings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    zodiac_sign_id UUID NOT NULL REFERENCES zodiac_signs(id) ON DELETE CASCADE,
    reading_date DATE NOT NULL,
    
    -- Reading content
    general_reading TEXT NOT NULL,
    love_reading TEXT,
    career_reading TEXT,
    health_reading TEXT,
    financial_reading TEXT,
    
    -- Cosmic influences
    lucky_numbers INTEGER[] DEFAULT '{}',
    lucky_colors TEXT[] DEFAULT '{}',
    lucky_days TEXT[] DEFAULT '{}',
    moon_phase VARCHAR(50),
    planetary_influences JSONB DEFAULT '{}',
    
    -- Quality ratings (1-5 stars)
    overall_energy INTEGER DEFAULT 3,
    love_energy INTEGER DEFAULT 3,
    career_energy INTEGER DEFAULT 3,
    health_energy INTEGER DEFAULT 3,
    financial_energy INTEGER DEFAULT 3,
    
    -- Metadata
    cosmic_message TEXT,
    daily_affirmation TEXT,
    recommended_crystals TEXT[] DEFAULT '{}',
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(zodiac_sign_id, reading_date),
    CHECK (overall_energy >= 1 AND overall_energy <= 5),
    CHECK (love_energy >= 1 AND love_energy <= 5),
    CHECK (career_energy >= 1 AND career_energy <= 5),
    CHECK (health_energy >= 1 AND health_energy <= 5),
    CHECK (financial_energy >= 1 AND financial_energy <= 5)
);

-- User horoscope preferences and tracking
CREATE TABLE user_horoscope_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    zodiac_sign_id UUID NOT NULL REFERENCES zodiac_signs(id),
    
    -- Preferences
    daily_notifications BOOLEAN DEFAULT true,
    preferred_reading_time TIME DEFAULT '09:00:00',
    favorite_reading_types TEXT[] DEFAULT '{"general", "love"}',
    
    -- Tracking
    total_readings_viewed INTEGER DEFAULT 0,
    streak_days INTEGER DEFAULT 0,
    last_reading_date DATE,
    coins_earned INTEGER DEFAULT 0,
    
    -- Customization
    preferred_cosmic_theme VARCHAR(50) DEFAULT 'stars',
    enable_animations BOOLEAN DEFAULT true,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(user_id),
    CHECK (total_readings_viewed >= 0),
    CHECK (streak_days >= 0),
    CHECK (coins_earned >= 0)
);

-- =============================================================================
-- TAROT AND ORACLE SYSTEMS
-- =============================================================================

-- Tarot card definitions
CREATE TABLE tarot_cards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    card_name VARCHAR(100) UNIQUE NOT NULL,
    card_number INTEGER,
    suit VARCHAR(20), -- major_arcana, cups, swords, wands, pentacles
    
    -- Card imagery
    card_image_url TEXT,
    card_back_image_url TEXT,
    symbol_description TEXT,
    
    -- Meanings
    upright_meaning TEXT NOT NULL,
    reversed_meaning TEXT NOT NULL,
    short_meaning TEXT NOT NULL,
    keywords TEXT[] DEFAULT '{}',
    
    -- Categorization
    card_type VARCHAR(20) DEFAULT 'minor', -- major, minor
    element VARCHAR(20), -- fire, earth, air, water, spirit
    astrological_association VARCHAR(100),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CHECK (suit IN ('major_arcana', 'cups', 'swords', 'wands', 'pentacles')),
    CHECK (card_type IN ('major', 'minor')),
    CHECK (element IN ('fire', 'earth', 'air', 'water', 'spirit'))
);

-- Tarot decks available to users
CREATE TABLE tarot_decks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    deck_name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    deck_theme VARCHAR(100),
    
    -- Deck properties
    total_cards INTEGER DEFAULT 78,
    card_back_design_url TEXT,
    deck_icon VARCHAR(10) DEFAULT '🔮',
    
    -- Availability
    is_free BOOLEAN DEFAULT true,
    unlock_cost INTEGER DEFAULT 0, -- In coins
    required_level INTEGER DEFAULT 1,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CHECK (total_cards > 0),
    CHECK (unlock_cost >= 0),
    CHECK (required_level >= 1)
);

-- User tarot reading history
CREATE TABLE tarot_readings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    deck_id UUID NOT NULL REFERENCES tarot_decks(id),
    
    -- Reading details
    reading_type VARCHAR(50) NOT NULL, -- single, three_card, celtic_cross
    question TEXT,
    cards_drawn JSONB NOT NULL, -- Array of card objects with positions
    
    -- Reading results
    interpretation TEXT,
    overall_theme VARCHAR(100),
    guidance_message TEXT,
    
    -- Metadata
    reading_duration_seconds INTEGER DEFAULT 0,
    cards_revealed_order INTEGER[] DEFAULT '{}',
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CHECK (reading_duration_seconds >= 0),
    CHECK (reading_type IN ('single', 'three_card', 'celtic_cross', 'daily', 'relationship'))
);

-- Oracle messages and wisdom
CREATE TABLE oracle_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_text TEXT NOT NULL,
    message_type VARCHAR(50) NOT NULL, -- wisdom, guidance, warning, blessing
    element VARCHAR(20) NOT NULL, -- fire, earth, air, water, spirit
    
    -- Message properties
    energy_level INTEGER DEFAULT 3, -- 1-5 scale
    theme_tags TEXT[] DEFAULT '{}',
    associated_colors TEXT[] DEFAULT '{}',
    crystal_recommendations TEXT[] DEFAULT '{}',
    
    -- Display properties
    icon_symbol VARCHAR(10) DEFAULT '✨',
    background_color VARCHAR(7) DEFAULT '#8A2BE2',
    
    -- Usage tracking
    times_delivered INTEGER DEFAULT 0,
    last_delivered_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CHECK (char_length(message_text) <= 500),
    CHECK (message_type IN ('wisdom', 'guidance', 'warning', 'blessing', 'insight')),
    CHECK (element IN ('fire', 'earth', 'air', 'water', 'spirit')),
    CHECK (energy_level >= 1 AND energy_level <= 5),
    CHECK (times_delivered >= 0)
);

-- User oracle consultation history
CREATE TABLE oracle_consultations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    oracle_message_id UUID NOT NULL REFERENCES oracle_messages(id),
    
    -- Consultation context
    question_category VARCHAR(100),
    user_question TEXT,
    emotional_state VARCHAR(50), -- peaceful, anxious, excited, confused
    
    -- Response tracking
    user_rating INTEGER, -- 1-5 stars
    was_helpful BOOLEAN,
    user_feedback TEXT,
    
    -- Session details
    consultation_duration_seconds INTEGER DEFAULT 0,
    meditation_time_seconds INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CHECK (user_rating IS NULL OR (user_rating >= 1 AND user_rating <= 5)),
    CHECK (consultation_duration_seconds >= 0),
    CHECK (meditation_time_seconds >= 0),
    CHECK (emotional_state IN ('peaceful', 'anxious', 'excited', 'confused', 'hopeful', 'sad'))
);

-- =============================================================================
-- ENTERTAINMENT AND INTERACTIVE FEATURES
-- =============================================================================

-- Magic 8-Ball responses
CREATE TABLE magic_8ball_responses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    response_text VARCHAR(255) NOT NULL,
    response_type VARCHAR(20) NOT NULL, -- positive, negative, neutral
    response_category VARCHAR(50) NOT NULL, -- certain, uncertain, optimistic, realistic
    
    -- Display properties
    text_color VARCHAR(7) DEFAULT '#FFFFFF',
    background_color VARCHAR(7) DEFAULT '#000000',
    animation_style VARCHAR(50) DEFAULT 'shake',
    
    -- Usage tracking
    times_shown INTEGER DEFAULT 0,
    user_satisfaction_avg DECIMAL(3,2) DEFAULT 3.0,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CHECK (response_type IN ('positive', 'negative', 'neutral')),
    CHECK (response_category IN ('certain', 'uncertain', 'optimistic', 'realistic')),
    CHECK (times_shown >= 0),
    CHECK (user_satisfaction_avg >= 0 AND user_satisfaction_avg <= 5)
);

-- User 8-ball consultation history
CREATE TABLE magic_8ball_consultations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    response_id UUID NOT NULL REFERENCES magic_8ball_responses(id),
    
    -- Consultation details
    user_question TEXT,
    question_category VARCHAR(100),
    user_mood VARCHAR(50),
    
    -- Feedback
    user_rating INTEGER, -- 1-5 stars
    was_accurate BOOLEAN,
    followed_advice BOOLEAN,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CHECK (user_rating IS NULL OR (user_rating >= 1 AND user_rating <= 5))
);

-- Confession system for anonymous sharing
CREATE TABLE confessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- Nullable for anonymity
    
    -- Confession content
    confession_text TEXT NOT NULL,
    confession_category VARCHAR(100),
    mood_emoji VARCHAR(10) DEFAULT '😔',
    
    -- Anonymity and privacy
    is_anonymous BOOLEAN DEFAULT true,
    anonymous_display_name VARCHAR(100) DEFAULT 'Anonymous Soul',
    
    -- Engagement
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    support_reactions_count INTEGER DEFAULT 0,
    
    -- Moderation
    is_approved BOOLEAN DEFAULT false,
    is_flagged BOOLEAN DEFAULT false,
    moderation_notes TEXT,
    moderated_by UUID REFERENCES auth.users(id),
    moderated_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CHECK (char_length(confession_text) <= 2000),
    CHECK (likes_count >= 0),
    CHECK (comments_count >= 0),
    CHECK (support_reactions_count >= 0)
);

-- Polling system for community engagement
CREATE TABLE polls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Poll content
    poll_title VARCHAR(255) NOT NULL,
    poll_description TEXT,
    poll_category VARCHAR(100),
    
    -- Poll configuration
    is_multiple_choice BOOLEAN DEFAULT false,
    is_anonymous_voting BOOLEAN DEFAULT false,
    allow_custom_options BOOLEAN DEFAULT false,
    
    -- Timing
    starts_at TIMESTAMPTZ DEFAULT NOW(),
    ends_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    
    -- Engagement
    total_votes INTEGER DEFAULT 0,
    total_participants INTEGER DEFAULT 0,
    
    -- Visibility
    is_public BOOLEAN DEFAULT true,
    featured_priority INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CHECK (total_votes >= 0),
    CHECK (total_participants >= 0),
    CHECK (featured_priority >= 0)
);

-- Poll options
CREATE TABLE poll_options (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    poll_id UUID NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
    
    -- Option content
    option_text VARCHAR(500) NOT NULL,
    option_emoji VARCHAR(10),
    option_color VARCHAR(7) DEFAULT '#8A2BE2',
    
    -- Option ordering
    option_order INTEGER DEFAULT 0,
    
    -- Vote tracking
    vote_count INTEGER DEFAULT 0,
    vote_percentage DECIMAL(5,2) DEFAULT 0.0,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CHECK (option_order >= 0),
    CHECK (vote_count >= 0),
    CHECK (vote_percentage >= 0 AND vote_percentage <= 100)
);

-- User votes on polls
CREATE TABLE poll_votes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    poll_id UUID NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    option_id UUID NOT NULL REFERENCES poll_options(id) ON DELETE CASCADE,
    
    -- Vote details
    is_anonymous BOOLEAN DEFAULT false,
    vote_strength INTEGER DEFAULT 1, -- For weighted voting
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(poll_id, user_id, option_id), -- Prevent duplicate votes (unless multiple choice)
    CHECK (vote_strength >= 1 AND vote_strength <= 5)
);

-- =============================================================================
-- PERFORMANCE AND ANALYTICS TRACKING
-- =============================================================================

-- Tab usage analytics
CREATE TABLE tab_usage_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    tab_name VARCHAR(100) NOT NULL REFERENCES tab_definitions(tab_name),
    
    -- Session tracking
    session_start TIMESTAMPTZ NOT NULL,
    session_end TIMESTAMPTZ,
    session_duration_seconds INTEGER,
    
    -- Interaction tracking
    interactions_count INTEGER DEFAULT 0,
    scroll_distance_pixels INTEGER DEFAULT 0,
    clicks_count INTEGER DEFAULT 0,
    
    -- Performance metrics
    load_time_ms INTEGER DEFAULT 0,
    memory_usage_mb DECIMAL(10,2) DEFAULT 0,
    network_requests INTEGER DEFAULT 0,
    
    -- Device context
    device_type VARCHAR(50), -- mobile, tablet, desktop
    platform VARCHAR(50), -- android, ios, web
    app_version VARCHAR(20),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CHECK (interactions_count >= 0),
    CHECK (scroll_distance_pixels >= 0),
    CHECK (clicks_count >= 0),
    CHECK (load_time_ms >= 0),
    CHECK (memory_usage_mb >= 0),
    CHECK (network_requests >= 0)
);

-- Daily tab usage summaries
CREATE TABLE daily_tab_usage_summary (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    usage_date DATE NOT NULL,
    
    -- Daily metrics
    total_session_time_seconds INTEGER DEFAULT 0,
    total_sessions INTEGER DEFAULT 0,
    unique_tabs_visited INTEGER DEFAULT 0,
    most_used_tab VARCHAR(100),
    total_interactions INTEGER DEFAULT 0,
    
    -- Top tabs (JSON array of {tab_name, duration, sessions})
    top_tabs JSONB DEFAULT '[]',
    
    -- Performance averages
    avg_load_time_ms DECIMAL(10,2) DEFAULT 0,
    avg_memory_usage_mb DECIMAL(10,2) DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(user_id, usage_date),
    CHECK (total_session_time_seconds >= 0),
    CHECK (total_sessions >= 0),
    CHECK (unique_tabs_visited >= 0),
    CHECK (total_interactions >= 0)
);

-- =============================================================================
-- INDEXES FOR PERFORMANCE OPTIMIZATION
-- =============================================================================

-- Tab system indexes
CREATE INDEX idx_tab_definitions_name ON tab_definitions(tab_name);
CREATE INDEX idx_tab_definitions_enabled ON tab_definitions(is_enabled, is_production_ready);
CREATE INDEX idx_tab_definitions_order ON tab_definitions(tab_order, is_enabled);

-- User preferences indexes
CREATE INDEX idx_user_tab_preferences_user ON user_tab_preferences(user_id);
CREATE INDEX idx_user_tab_preferences_tab ON user_tab_preferences(tab_name);
CREATE INDEX idx_user_tab_preferences_favorites ON user_tab_preferences(user_id, is_favorite) WHERE is_favorite = true;
CREATE INDEX idx_user_tab_preferences_usage ON user_tab_preferences(last_accessed_at DESC, access_count DESC);

-- Home screen indexes
CREATE INDEX idx_home_screen_apps_position ON home_screen_apps(grid_position, is_enabled);
CREATE INDEX idx_home_screen_apps_category ON home_screen_apps(category_id, grid_position);
CREATE INDEX idx_user_home_layout_user ON user_home_screen_layout(user_id, custom_position);

-- Glitter Board indexes
CREATE INDEX idx_glitter_posts_user ON glitter_posts(user_id, created_at DESC);
CREATE INDEX idx_glitter_posts_visibility ON glitter_posts(visibility, is_deleted, created_at DESC) WHERE is_deleted = false;
CREATE INDEX idx_glitter_posts_text_search ON glitter_posts USING gin(to_tsvector('english', text_content));
CREATE INDEX idx_glitter_posts_featured ON glitter_posts(is_featured, created_at DESC) WHERE is_featured = true;
CREATE INDEX idx_glitter_posts_tags ON glitter_posts USING gin(tags);

CREATE INDEX idx_glitter_comments_post ON glitter_comments(post_id, created_at DESC);
CREATE INDEX idx_glitter_comments_user ON glitter_comments(user_id, created_at DESC);
CREATE INDEX idx_glitter_comments_parent ON glitter_comments(parent_comment_id, created_at DESC);

CREATE INDEX idx_glitter_reactions_target ON glitter_reactions(target_type, target_id, reaction_type);
CREATE INDEX idx_glitter_reactions_user ON glitter_reactions(user_id, created_at DESC);

-- Horoscope indexes
CREATE INDEX idx_zodiac_signs_name ON zodiac_signs(sign_name);
CREATE INDEX idx_horoscope_readings_sign_date ON horoscope_readings(zodiac_sign_id, reading_date DESC);
CREATE INDEX idx_user_horoscope_user ON user_horoscope_preferences(user_id);

-- Tarot and Oracle indexes
CREATE INDEX idx_tarot_cards_suit ON tarot_cards(suit, card_number);
CREATE INDEX idx_tarot_cards_type ON tarot_cards(card_type, suit);
CREATE INDEX idx_tarot_readings_user ON tarot_readings(user_id, created_at DESC);
CREATE INDEX idx_oracle_messages_type ON oracle_messages(message_type, element);
CREATE INDEX idx_oracle_consultations_user ON oracle_consultations(user_id, created_at DESC);

-- Entertainment indexes
CREATE INDEX idx_8ball_responses_type ON magic_8ball_responses(response_type, response_category);
CREATE INDEX idx_8ball_consultations_user ON magic_8ball_consultations(user_id, created_at DESC);
CREATE INDEX idx_confessions_approved ON confessions(is_approved, created_at DESC) WHERE is_approved = true;
CREATE INDEX idx_confessions_text_search ON confessions USING gin(to_tsvector('english', confession_text));

-- Polling indexes
CREATE INDEX idx_polls_active ON polls(is_active, is_public, ends_at DESC) WHERE is_active = true;
CREATE INDEX idx_polls_creator ON polls(creator_id, created_at DESC);
CREATE INDEX idx_polls_text_search ON polls USING gin(to_tsvector('english', COALESCE(poll_title, '') || ' ' || COALESCE(poll_description, '')));
CREATE INDEX idx_poll_options_poll ON poll_options(poll_id, option_order);
CREATE INDEX idx_poll_votes_poll ON poll_votes(poll_id, created_at DESC);
CREATE INDEX idx_poll_votes_user ON poll_votes(user_id, created_at DESC);

-- Analytics indexes
CREATE INDEX idx_tab_usage_user_tab ON tab_usage_analytics(user_id, tab_name, session_start DESC);
CREATE INDEX idx_tab_usage_performance ON tab_usage_analytics(tab_name, load_time_ms, memory_usage_mb);
CREATE INDEX idx_daily_usage_summary_user_date ON daily_tab_usage_summary(user_id, usage_date DESC);

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE tab_definitions IS 'Core tab configuration and metadata for the Crystal Social navigation system';
COMMENT ON TABLE user_tab_preferences IS 'User-specific tab customization and usage preferences';
COMMENT ON TABLE home_screen_apps IS 'App grid items displayed on the main home screen';
COMMENT ON TABLE glitter_posts IS 'Main social media posts for the Glitter Board platform';
COMMENT ON TABLE horoscope_readings IS 'Daily horoscope content for all zodiac signs';
COMMENT ON TABLE tarot_readings IS 'User tarot card reading history and results';
COMMENT ON TABLE oracle_consultations IS 'Oracle wisdom consultations and guidance sessions';
COMMENT ON TABLE confessions IS 'Anonymous confession sharing system';
COMMENT ON TABLE polls IS 'Community polling and voting system';
COMMENT ON TABLE tab_usage_analytics IS 'Detailed tab usage analytics for performance optimization';

-- =============================================================================
-- INITIAL SETUP COMPLETION
-- =============================================================================

SELECT 
    'Tabs Core Tables Setup Complete!' as status,
    (SELECT COUNT(*) FROM information_schema.tables WHERE table_name LIKE '%tab%' OR table_name LIKE '%glitter%' OR table_name LIKE '%horoscope%' OR table_name LIKE '%tarot%' OR table_name LIKE '%oracle%' OR table_name LIKE '%poll%' OR table_name LIKE '%confession%') as tables_created,
    (SELECT COUNT(*) FROM pg_indexes WHERE indexname LIKE '%tab%' OR indexname LIKE '%glitter%' OR indexname LIKE '%horoscope%' OR indexname LIKE '%tarot%' OR indexname LIKE '%oracle%') as indexes_created,
    NOW() as setup_completed_at;
