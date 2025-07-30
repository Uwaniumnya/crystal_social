-- Crystal Social Spotify System - Core Tables and Infrastructure
-- File: 01_spotify_core_tables.sql
-- Purpose: Foundation tables for the comprehensive Spotify integration system

-- =============================================================================
-- SPOTIFY CORE INFRASTRUCTURE
-- =============================================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For text search optimization

-- =============================================================================
-- SPOTIFY AUTHENTICATION AND USER INTEGRATION
-- =============================================================================

-- Spotify user accounts and authentication
CREATE TABLE spotify_user_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    spotify_user_id VARCHAR(255) UNIQUE NOT NULL,
    spotify_username VARCHAR(255),
    display_name VARCHAR(255),
    email VARCHAR(255),
    country VARCHAR(10),
    product VARCHAR(50), -- free, premium
    follower_count INTEGER DEFAULT 0,
    
    -- Authentication tokens
    access_token TEXT,
    refresh_token TEXT,
    token_expires_at TIMESTAMPTZ,
    scope TEXT[], -- List of granted permissions
    
    -- Connection status
    is_connected BOOLEAN DEFAULT true,
    is_premium BOOLEAN DEFAULT false,
    last_connected_at TIMESTAMPTZ DEFAULT NOW(),
    connection_count INTEGER DEFAULT 1,
    
    -- Profile data from Spotify
    profile_image_url TEXT,
    external_urls JSONB DEFAULT '{}',
    spotify_profile_data JSONB DEFAULT '{}',
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(user_id, spotify_user_id)
);

-- User listening preferences and settings
CREATE TABLE spotify_user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    spotify_account_id UUID REFERENCES spotify_user_accounts(id) ON DELETE CASCADE,
    
    -- Playback preferences
    shuffle_mode BOOLEAN DEFAULT false,
    repeat_mode INTEGER DEFAULT 0, -- 0=off, 1=track, 2=context
    volume_level INTEGER DEFAULT 50, -- 0-100
    auto_play_enabled BOOLEAN DEFAULT true,
    
    -- Social preferences
    share_listening_activity BOOLEAN DEFAULT true,
    allow_room_invites BOOLEAN DEFAULT true,
    show_current_track BOOLEAN DEFAULT true,
    auto_join_friend_rooms BOOLEAN DEFAULT false,
    
    -- Mood and genre preferences
    preferred_genres TEXT[] DEFAULT '{}',
    current_mood VARCHAR(100) DEFAULT 'Vibing',
    mood_history JSONB DEFAULT '[]',
    
    -- Display preferences
    visualizer_enabled BOOLEAN DEFAULT true,
    animated_backgrounds BOOLEAN DEFAULT true,
    pet_reactions_enabled BOOLEAN DEFAULT true,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(user_id),
    CHECK (repeat_mode >= 0 AND repeat_mode <= 2),
    CHECK (volume_level >= 0 AND volume_level <= 100)
);

-- =============================================================================
-- MUSIC ROOMS AND SOCIAL LISTENING
-- =============================================================================

-- Music rooms for collaborative listening
CREATE TABLE music_rooms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    host_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Room configuration
    is_public BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    max_participants INTEGER DEFAULT 50,
    requires_password BOOLEAN DEFAULT false,
    password_hash TEXT,
    
    -- Current state
    current_track_uri VARCHAR(255),
    current_track_name VARCHAR(500),
    current_artist_name VARCHAR(500),
    current_track_image_url TEXT,
    current_position_ms INTEGER DEFAULT 0,
    is_playing BOOLEAN DEFAULT false,
    last_sync_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Room mood and theme
    mood VARCHAR(100) DEFAULT 'Vibing',
    theme_color VARCHAR(7) DEFAULT '#FF6B9D',
    background_type VARCHAR(50) DEFAULT 'animated',
    
    -- Statistics
    listener_count INTEGER DEFAULT 0,
    total_tracks_played INTEGER DEFAULT 0,
    total_listen_time_minutes INTEGER DEFAULT 0,
    peak_listener_count INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_activity_at TIMESTAMPTZ DEFAULT NOW()
);

-- Room participants tracking
CREATE TABLE room_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    room_id UUID NOT NULL REFERENCES music_rooms(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Participation details
    role VARCHAR(50) DEFAULT 'listener', -- host, moderator, listener
    is_active BOOLEAN DEFAULT true,
    is_muted BOOLEAN DEFAULT false,
    
    -- Activity tracking
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    last_active_at TIMESTAMPTZ DEFAULT NOW(),
    left_at TIMESTAMPTZ,
    total_time_minutes INTEGER DEFAULT 0,
    
    -- Interaction stats
    tracks_added INTEGER DEFAULT 0,
    reactions_sent INTEGER DEFAULT 0,
    votes_cast INTEGER DEFAULT 0,
    messages_sent INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(room_id, user_id),
    CHECK (role IN ('host', 'moderator', 'listener'))
);

-- Real-time room synchronization
CREATE TABLE room_sync (
    room_id UUID PRIMARY KEY REFERENCES music_rooms(id) ON DELETE CASCADE,
    
    -- Current playback state
    track_uri VARCHAR(255),
    track_name VARCHAR(500),
    artist_name VARCHAR(500),
    album_name VARCHAR(500),
    track_image_url TEXT,
    track_duration_ms INTEGER DEFAULT 0,
    
    -- Playback position and status
    position_ms INTEGER DEFAULT 0,
    is_playing BOOLEAN DEFAULT false,
    is_shuffling BOOLEAN DEFAULT false,
    repeat_mode INTEGER DEFAULT 0,
    
    -- Sync metadata
    sync_source UUID REFERENCES auth.users(id), -- Who triggered the sync
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    sequence_number BIGINT DEFAULT 0, -- For ordering events
    
    -- Quality control
    sync_confidence DECIMAL(3,2) DEFAULT 1.0, -- How confident we are in this sync
    latency_ms INTEGER DEFAULT 0,
    
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- MUSIC QUEUE AND PLAYLIST MANAGEMENT
-- =============================================================================

-- Music queue for rooms
CREATE TABLE music_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    room_id UUID NOT NULL REFERENCES music_rooms(id) ON DELETE CASCADE,
    
    -- Track information
    track_uri VARCHAR(255) NOT NULL,
    track_name VARCHAR(500) NOT NULL,
    artist_name VARCHAR(500) NOT NULL,
    album_name VARCHAR(500),
    track_image_url TEXT,
    duration_ms INTEGER DEFAULT 0,
    
    -- Queue management
    queue_position INTEGER NOT NULL,
    added_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    is_played BOOLEAN DEFAULT false,
    is_skipped BOOLEAN DEFAULT false,
    
    -- Voting system
    upvotes INTEGER DEFAULT 0,
    downvotes INTEGER DEFAULT 0,
    vote_score INTEGER GENERATED ALWAYS AS (upvotes - downvotes) STORED,
    
    -- Timing
    added_at TIMESTAMPTZ DEFAULT NOW(),
    played_at TIMESTAMPTZ,
    estimated_play_time TIMESTAMPTZ,
    
    -- Metadata
    spotify_track_data JSONB DEFAULT '{}',
    explicit_content BOOLEAN DEFAULT false,
    popularity_score INTEGER DEFAULT 0, -- Spotify popularity 0-100
    
    -- Constraints
    UNIQUE(room_id, queue_position),
    CHECK (queue_position >= 0),
    CHECK (popularity_score >= 0 AND popularity_score <= 100)
);

-- Track voting for queue management
CREATE TABLE track_votes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    track_id UUID NOT NULL REFERENCES music_queue(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    room_id UUID NOT NULL REFERENCES music_rooms(id) ON DELETE CASCADE,
    
    -- Vote details
    is_upvote BOOLEAN NOT NULL,
    vote_weight DECIMAL(3,2) DEFAULT 1.0, -- For weighted voting systems
    
    -- Timing
    voted_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(track_id, user_id)
);

-- =============================================================================
-- MUSIC REACTIONS AND SOCIAL FEATURES
-- =============================================================================

-- Real-time reactions during music playback
CREATE TABLE music_reactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    room_id UUID NOT NULL REFERENCES music_rooms(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Reaction details
    reaction VARCHAR(10) NOT NULL, -- Emoji reactions
    track_uri VARCHAR(255),
    track_position_ms INTEGER DEFAULT 0,
    
    -- Reaction context
    reaction_type VARCHAR(50) DEFAULT 'track', -- track, room, user
    target_user_id UUID REFERENCES auth.users(id), -- For user-specific reactions
    
    -- Timing and display
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '30 seconds'),
    is_visible BOOLEAN DEFAULT true,
    
    -- Animation data
    animation_type VARCHAR(50) DEFAULT 'float',
    start_position JSONB DEFAULT '{}', -- {x, y} coordinates
    
    -- Constraints
    CHECK (char_length(reaction) <= 10)
);

-- Music chat for rooms (optional social feature)
CREATE TABLE music_chat (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    room_id UUID NOT NULL REFERENCES music_rooms(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Message content
    message TEXT NOT NULL,
    message_type VARCHAR(50) DEFAULT 'text', -- text, reaction, system
    
    -- Message context
    track_uri VARCHAR(255), -- Associated track if any
    reply_to_id UUID REFERENCES music_chat(id), -- For threaded conversations
    
    -- Moderation
    is_edited BOOLEAN DEFAULT false,
    is_deleted BOOLEAN DEFAULT false,
    edited_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CHECK (char_length(message) <= 1000),
    CHECK (message_type IN ('text', 'reaction', 'system', 'track_share'))
);

-- =============================================================================
-- LISTENING HISTORY AND ANALYTICS
-- =============================================================================

-- User listening history
CREATE TABLE listening_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    spotify_account_id UUID REFERENCES spotify_user_accounts(id) ON DELETE SET NULL,
    
    -- Track information
    track_uri VARCHAR(255) NOT NULL,
    track_name VARCHAR(500) NOT NULL,
    artist_name VARCHAR(500) NOT NULL,
    album_name VARCHAR(500),
    track_image_url TEXT,
    duration_ms INTEGER DEFAULT 0,
    
    -- Listen context
    room_id UUID REFERENCES music_rooms(id) ON DELETE SET NULL,
    listen_source VARCHAR(50) DEFAULT 'room', -- room, solo, queue
    device_type VARCHAR(50), -- mobile, desktop, web
    
    -- Listen metrics
    played_duration_ms INTEGER DEFAULT 0,
    completion_percentage DECIMAL(5,2) GENERATED ALWAYS AS (
        CASE WHEN duration_ms > 0 THEN (played_duration_ms * 100.0 / duration_ms) ELSE 0 END
    ) STORED,
    was_skipped BOOLEAN DEFAULT false,
    skip_reason VARCHAR(100),
    
    -- User interaction
    was_liked BOOLEAN DEFAULT false,
    was_shared BOOLEAN DEFAULT false,
    reaction_given VARCHAR(10),
    
    -- Timing
    started_at TIMESTAMPTZ DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    
    -- Spotify integration data
    spotify_play_data JSONB DEFAULT '{}',
    
    -- Constraints
    CHECK (played_duration_ms >= 0),
    CHECK (completion_percentage >= 0 AND completion_percentage <= 100)
);

-- Daily listening statistics per user
CREATE TABLE daily_listening_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    listen_date DATE NOT NULL,
    
    -- Daily metrics
    total_tracks INTEGER DEFAULT 0,
    total_listen_time_minutes INTEGER DEFAULT 0,
    unique_artists INTEGER DEFAULT 0,
    unique_albums INTEGER DEFAULT 0,
    
    -- Activity metrics
    rooms_joined INTEGER DEFAULT 0,
    rooms_hosted INTEGER DEFAULT 0,
    tracks_queued INTEGER DEFAULT 0,
    reactions_sent INTEGER DEFAULT 0,
    
    -- Discovery metrics
    new_tracks_discovered INTEGER DEFAULT 0,
    repeat_tracks INTEGER DEFAULT 0,
    average_completion_rate DECIMAL(5,2) DEFAULT 0,
    
    -- Social metrics
    time_in_rooms_minutes INTEGER DEFAULT 0,
    friends_listened_with INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(user_id, listen_date)
);

-- Room analytics and performance metrics
CREATE TABLE room_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    room_id UUID NOT NULL REFERENCES music_rooms(id) ON DELETE CASCADE,
    analytics_date DATE NOT NULL,
    
    -- Engagement metrics
    unique_participants INTEGER DEFAULT 0,
    total_join_events INTEGER DEFAULT 0,
    average_session_minutes DECIMAL(10,2) DEFAULT 0,
    peak_concurrent_users INTEGER DEFAULT 0,
    
    -- Content metrics
    tracks_played INTEGER DEFAULT 0,
    tracks_skipped INTEGER DEFAULT 0,
    total_playback_minutes INTEGER DEFAULT 0,
    unique_artists INTEGER DEFAULT 0,
    
    -- Interaction metrics
    total_reactions INTEGER DEFAULT 0,
    total_votes INTEGER DEFAULT 0,
    total_chat_messages INTEGER DEFAULT 0,
    queue_additions INTEGER DEFAULT 0,
    
    -- Performance metrics
    average_sync_latency_ms DECIMAL(10,2) DEFAULT 0,
    sync_accuracy_percentage DECIMAL(5,2) DEFAULT 100,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(room_id, analytics_date)
);

-- =============================================================================
-- SPOTIFY TRACK AND ARTIST CACHE
-- =============================================================================

-- Cached Spotify track information
CREATE TABLE spotify_tracks_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    track_uri VARCHAR(255) UNIQUE NOT NULL,
    
    -- Basic track info
    track_id VARCHAR(100) NOT NULL,
    name VARCHAR(500) NOT NULL,
    duration_ms INTEGER NOT NULL,
    explicit_content BOOLEAN DEFAULT false,
    popularity INTEGER DEFAULT 0,
    preview_url TEXT,
    
    -- Album information
    album_id VARCHAR(100),
    album_name VARCHAR(500),
    album_image_url TEXT,
    album_release_date DATE,
    album_total_tracks INTEGER DEFAULT 0,
    
    -- Artist information (stored as JSONB for multiple artists)
    artists JSONB NOT NULL DEFAULT '[]',
    primary_artist_name VARCHAR(500),
    primary_artist_id VARCHAR(100),
    
    -- Audio features from Spotify API
    audio_features JSONB DEFAULT '{}',
    
    -- Cache metadata
    cache_created_at TIMESTAMPTZ DEFAULT NOW(),
    cache_updated_at TIMESTAMPTZ DEFAULT NOW(),
    cache_expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '30 days'),
    access_count INTEGER DEFAULT 0,
    last_accessed_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CHECK (popularity >= 0 AND popularity <= 100)
);

-- Cached Spotify artist information
CREATE TABLE spotify_artists_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    artist_id VARCHAR(100) UNIQUE NOT NULL,
    artist_uri VARCHAR(255) UNIQUE NOT NULL,
    
    -- Artist information
    name VARCHAR(500) NOT NULL,
    genres TEXT[] DEFAULT '{}',
    popularity INTEGER DEFAULT 0,
    follower_count INTEGER DEFAULT 0,
    
    -- Images and external links
    image_url TEXT,
    external_urls JSONB DEFAULT '{}',
    
    -- Cache metadata
    cache_created_at TIMESTAMPTZ DEFAULT NOW(),
    cache_updated_at TIMESTAMPTZ DEFAULT NOW(),
    cache_expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days'),
    access_count INTEGER DEFAULT 0,
    last_accessed_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CHECK (popularity >= 0 AND popularity <= 100)
);

-- =============================================================================
-- INDEXES FOR PERFORMANCE OPTIMIZATION
-- =============================================================================

-- Spotify user accounts indexes
CREATE INDEX idx_spotify_accounts_user_id ON spotify_user_accounts(user_id);
CREATE INDEX idx_spotify_accounts_spotify_user_id ON spotify_user_accounts(spotify_user_id);
CREATE INDEX idx_spotify_accounts_connected ON spotify_user_accounts(is_connected, last_connected_at DESC) WHERE is_connected = true;
CREATE INDEX idx_spotify_accounts_premium ON spotify_user_accounts(is_premium) WHERE is_premium = true;

-- User preferences indexes
CREATE INDEX idx_spotify_preferences_user_id ON spotify_user_preferences(user_id);
CREATE INDEX idx_spotify_preferences_social ON spotify_user_preferences(share_listening_activity, allow_room_invites) WHERE share_listening_activity = true;

-- Music rooms indexes
CREATE INDEX idx_music_rooms_host ON music_rooms(host_id, created_at DESC);
CREATE INDEX idx_music_rooms_active ON music_rooms(is_active, is_public, last_activity_at DESC) WHERE is_active = true;
CREATE INDEX idx_music_rooms_name ON music_rooms(name);
CREATE INDEX idx_music_rooms_mood ON music_rooms(mood, created_at DESC);
CREATE INDEX idx_music_rooms_listeners ON music_rooms(listener_count DESC, created_at DESC);

-- Room participants indexes
CREATE INDEX idx_room_participants_room ON room_participants(room_id, is_active, joined_at DESC);
CREATE INDEX idx_room_participants_user ON room_participants(user_id, is_active, joined_at DESC);
CREATE INDEX idx_room_participants_active ON room_participants(room_id, user_id) WHERE is_active = true;

-- Room sync indexes
CREATE INDEX idx_room_sync_timestamp ON room_sync(timestamp DESC);
CREATE INDEX idx_room_sync_sequence ON room_sync(sequence_number DESC);

-- Music queue indexes
CREATE INDEX idx_music_queue_room_position ON music_queue(room_id, queue_position);
CREATE INDEX idx_music_queue_added_by ON music_queue(added_by, added_at DESC);
CREATE INDEX idx_music_queue_unplayed ON music_queue(room_id, queue_position) WHERE is_played = false AND is_skipped = false;
CREATE INDEX idx_music_queue_votes ON music_queue(vote_score DESC, added_at DESC);

-- Track votes indexes
CREATE INDEX idx_track_votes_track ON track_votes(track_id);
CREATE INDEX idx_track_votes_user ON track_votes(user_id, voted_at DESC);
CREATE INDEX idx_track_votes_room ON track_votes(room_id, voted_at DESC);

-- Music reactions indexes
CREATE INDEX idx_music_reactions_room ON music_reactions(room_id, created_at DESC);
CREATE INDEX idx_music_reactions_user ON music_reactions(user_id, created_at DESC);
CREATE INDEX idx_music_reactions_track ON music_reactions(track_uri, created_at DESC);
CREATE INDEX idx_music_reactions_active ON music_reactions(room_id, is_visible, expires_at) WHERE is_visible = true;

-- Music chat indexes
CREATE INDEX idx_music_chat_room ON music_chat(room_id, created_at DESC);
CREATE INDEX idx_music_chat_user ON music_chat(user_id, created_at DESC);
CREATE INDEX idx_music_chat_track ON music_chat(track_uri, created_at DESC) WHERE track_uri IS NOT NULL;

-- Listening history indexes
CREATE INDEX idx_listening_history_user ON listening_history(user_id, started_at DESC);
CREATE INDEX idx_listening_history_track ON listening_history(track_uri, started_at DESC);
CREATE INDEX idx_listening_history_room ON listening_history(room_id, started_at DESC) WHERE room_id IS NOT NULL;
CREATE INDEX idx_listening_history_completion ON listening_history(completion_percentage DESC, started_at DESC);

-- Daily stats indexes
CREATE INDEX idx_daily_listening_stats_user_date ON daily_listening_stats(user_id, listen_date DESC);
CREATE INDEX idx_daily_listening_stats_date ON daily_listening_stats(listen_date DESC);
CREATE INDEX idx_room_analytics_room_date ON room_analytics(room_id, analytics_date DESC);
CREATE INDEX idx_room_analytics_date ON room_analytics(analytics_date DESC);

-- Cache indexes
CREATE INDEX idx_spotify_tracks_cache_uri ON spotify_tracks_cache(track_uri);
CREATE INDEX idx_spotify_tracks_cache_name ON spotify_tracks_cache(name);
CREATE INDEX idx_spotify_tracks_cache_artist ON spotify_tracks_cache(primary_artist_name, popularity DESC);
CREATE INDEX idx_spotify_tracks_cache_expires ON spotify_tracks_cache(cache_expires_at);
CREATE INDEX idx_spotify_artists_cache_id ON spotify_artists_cache(artist_id);
CREATE INDEX idx_spotify_artists_cache_name ON spotify_artists_cache(name);
CREATE INDEX idx_spotify_artists_cache_popularity ON spotify_artists_cache(popularity DESC);

-- =============================================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- =============================================================================

-- Update room participant count
CREATE OR REPLACE FUNCTION update_room_listener_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE music_rooms 
    SET 
        listener_count = (
            SELECT COUNT(*) 
            FROM room_participants 
            WHERE room_id = COALESCE(NEW.room_id, OLD.room_id) 
            AND is_active = true
        ),
        last_activity_at = NOW(),
        updated_at = NOW()
    WHERE id = COALESCE(NEW.room_id, OLD.room_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_room_listener_count
    AFTER INSERT OR UPDATE OR DELETE ON room_participants
    FOR EACH ROW EXECUTE FUNCTION update_room_listener_count();

-- Update queue vote scores
CREATE OR REPLACE FUNCTION update_queue_vote_scores()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE music_queue 
    SET 
        upvotes = (
            SELECT COUNT(*) 
            FROM track_votes 
            WHERE track_id = COALESCE(NEW.track_id, OLD.track_id) 
            AND is_upvote = true
        ),
        downvotes = (
            SELECT COUNT(*) 
            FROM track_votes 
            WHERE track_id = COALESCE(NEW.track_id, OLD.track_id) 
            AND is_upvote = false
        )
    WHERE id = COALESCE(NEW.track_id, OLD.track_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_queue_vote_scores
    AFTER INSERT OR UPDATE OR DELETE ON track_votes
    FOR EACH ROW EXECUTE FUNCTION update_queue_vote_scores();

-- Update cache access tracking
CREATE OR REPLACE FUNCTION update_cache_access()
RETURNS TRIGGER AS $$
BEGIN
    NEW.access_count = OLD.access_count + 1;
    NEW.last_accessed_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_tracks_cache_access
    BEFORE UPDATE ON spotify_tracks_cache
    FOR EACH ROW EXECUTE FUNCTION update_cache_access();

CREATE TRIGGER trigger_update_artists_cache_access
    BEFORE UPDATE ON spotify_artists_cache
    FOR EACH ROW EXECUTE FUNCTION update_cache_access();

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE spotify_user_accounts IS 'Spotify account integration and authentication for Crystal Social users';
COMMENT ON TABLE spotify_user_preferences IS 'User preferences for Spotify integration and music listening';
COMMENT ON TABLE music_rooms IS 'Collaborative music listening rooms with real-time synchronization';
COMMENT ON TABLE room_participants IS 'Tracks users participating in music rooms with activity metrics';
COMMENT ON TABLE room_sync IS 'Real-time synchronization data for music room playback state';
COMMENT ON TABLE music_queue IS 'Music queue for rooms with voting and management features';
COMMENT ON TABLE track_votes IS 'User votes on queued tracks for democratic queue management';
COMMENT ON TABLE music_reactions IS 'Real-time emoji reactions during music playback';
COMMENT ON TABLE music_chat IS 'Chat functionality for music rooms (optional feature)';
COMMENT ON TABLE listening_history IS 'Comprehensive user listening history with analytics';
COMMENT ON TABLE daily_listening_stats IS 'Daily aggregated listening statistics per user';
COMMENT ON TABLE room_analytics IS 'Daily analytics and performance metrics for music rooms';
COMMENT ON TABLE spotify_tracks_cache IS 'Cached Spotify track information for performance optimization';
COMMENT ON TABLE spotify_artists_cache IS 'Cached Spotify artist information for performance optimization';

-- =============================================================================
-- INITIAL SETUP COMPLETION
-- =============================================================================

SELECT 
    'Spotify Core Tables Setup Complete!' as status,
    (SELECT COUNT(*) FROM information_schema.tables WHERE table_name LIKE '%spotify%' OR table_name LIKE '%music%' OR table_name LIKE '%room%' OR table_name LIKE '%listening%') as tables_created,
    (SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_name LIKE '%room%' OR trigger_name LIKE '%music%' OR trigger_name LIKE '%cache%') as triggers_created,
    NOW() as setup_completed_at;
