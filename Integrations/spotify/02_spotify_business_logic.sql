-- Crystal Social Spotify System - Business Logic and Functions
-- File: 02_spotify_business_logic.sql
-- Purpose: Stored procedures, functions, and business logic for comprehensive Spotify integration

-- =============================================================================
-- ROOM MANAGEMENT FUNCTIONS
-- =============================================================================

-- Create a new music room with default settings
CREATE OR REPLACE FUNCTION create_music_room(
    p_host_id UUID,
    p_name VARCHAR(255),
    p_description TEXT DEFAULT NULL,
    p_is_public BOOLEAN DEFAULT true,
    p_mood VARCHAR(100) DEFAULT 'Vibing',
    p_theme_color VARCHAR(7) DEFAULT '#FF6B9D',
    p_max_participants INTEGER DEFAULT 50
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_room_id UUID;
BEGIN
    -- Validate host exists and has Spotify account
    IF NOT EXISTS (
        SELECT 1 FROM spotify_user_accounts 
        WHERE user_id = p_host_id AND is_connected = true
    ) THEN
        RAISE EXCEPTION 'User must have connected Spotify account to host rooms';
    END IF;
    
    -- Create the room
    INSERT INTO music_rooms (
        name, description, host_id, is_public, mood, 
        theme_color, max_participants, listener_count
    ) VALUES (
        p_name, p_description, p_host_id, p_is_public, p_mood,
        p_theme_color, p_max_participants, 0
    ) RETURNING id INTO v_room_id;
    
    -- Add host as first participant
    INSERT INTO room_participants (room_id, user_id, role, is_active)
    VALUES (v_room_id, p_host_id, 'host', true);
    
    -- Initialize room sync
    INSERT INTO room_sync (room_id, sync_source, sequence_number)
    VALUES (v_room_id, p_host_id, 1);
    
    RETURN v_room_id;
END;
$$;

-- Join a music room
CREATE OR REPLACE FUNCTION join_music_room(
    p_user_id UUID,
    p_room_id UUID,
    p_password TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_room_record music_rooms%ROWTYPE;
    v_participant_count INTEGER;
BEGIN
    -- Get room details
    SELECT * INTO v_room_record FROM music_rooms WHERE id = p_room_id AND is_active = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Room not found or inactive';
    END IF;
    
    -- Check password if required
    IF v_room_record.requires_password AND (p_password IS NULL OR crypt(p_password, v_room_record.password_hash) != v_room_record.password_hash) THEN
        RAISE EXCEPTION 'Invalid room password';
    END IF;
    
    -- Check participant limit
    SELECT COUNT(*) INTO v_participant_count 
    FROM room_participants 
    WHERE room_id = p_room_id AND is_active = true;
    
    IF v_participant_count >= v_room_record.max_participants THEN
        RAISE EXCEPTION 'Room is at maximum capacity';
    END IF;
    
    -- Add or reactivate participant
    INSERT INTO room_participants (room_id, user_id, is_active, joined_at, last_active_at)
    VALUES (p_room_id, p_user_id, true, NOW(), NOW())
    ON CONFLICT (room_id, user_id) 
    DO UPDATE SET 
        is_active = true,
        joined_at = NOW(),
        last_active_at = NOW(),
        left_at = NULL;
    
    -- Update room activity
    UPDATE music_rooms 
    SET last_activity_at = NOW(), updated_at = NOW()
    WHERE id = p_room_id;
    
    RETURN true;
END;
$$;

-- Leave a music room
CREATE OR REPLACE FUNCTION leave_music_room(
    p_user_id UUID,
    p_room_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_participant_record room_participants%ROWTYPE;
    v_session_minutes INTEGER;
BEGIN
    -- Get participant record
    SELECT * INTO v_participant_record 
    FROM room_participants 
    WHERE room_id = p_room_id AND user_id = p_user_id AND is_active = true;
    
    IF NOT FOUND THEN
        RETURN false; -- User wasn't in the room
    END IF;
    
    -- Calculate session time
    v_session_minutes := EXTRACT(EPOCH FROM (NOW() - v_participant_record.joined_at)) / 60;
    
    -- Update participant record
    UPDATE room_participants 
    SET 
        is_active = false,
        left_at = NOW(),
        last_active_at = NOW(),
        total_time_minutes = total_time_minutes + v_session_minutes
    WHERE room_id = p_room_id AND user_id = p_user_id;
    
    -- If host is leaving, transfer ownership or deactivate room
    IF v_participant_record.role = 'host' THEN
        PERFORM transfer_room_ownership(p_room_id);
    END IF;
    
    -- Update room activity
    UPDATE music_rooms 
    SET last_activity_at = NOW(), updated_at = NOW()
    WHERE id = p_room_id;
    
    RETURN true;
END;
$$;

-- Transfer room ownership to next moderator or active participant
CREATE OR REPLACE FUNCTION transfer_room_ownership(p_room_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_new_host_id UUID;
BEGIN
    -- Find next host (prefer moderators, then longest-active participant)
    SELECT user_id INTO v_new_host_id
    FROM room_participants
    WHERE room_id = p_room_id AND is_active = true AND role != 'host'
    ORDER BY 
        CASE WHEN role = 'moderator' THEN 1 ELSE 2 END,
        joined_at ASC
    LIMIT 1;
    
    IF v_new_host_id IS NOT NULL THEN
        -- Update room host
        UPDATE music_rooms SET host_id = v_new_host_id WHERE id = p_room_id;
        
        -- Update participant role
        UPDATE room_participants 
        SET role = 'host' 
        WHERE room_id = p_room_id AND user_id = v_new_host_id;
        
        RETURN true;
    ELSE
        -- No participants left, deactivate room
        UPDATE music_rooms SET is_active = false WHERE id = p_room_id;
        RETURN false;
    END IF;
END;
$$;

-- =============================================================================
-- QUEUE MANAGEMENT FUNCTIONS
-- =============================================================================

-- Add track to room queue
CREATE OR REPLACE FUNCTION add_track_to_queue(
    p_room_id UUID,
    p_user_id UUID,
    p_track_uri VARCHAR(255),
    p_track_name VARCHAR(500),
    p_artist_name VARCHAR(500),
    p_album_name VARCHAR(500) DEFAULT NULL,
    p_track_image_url TEXT DEFAULT NULL,
    p_duration_ms INTEGER DEFAULT 0
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_queue_id UUID;
    v_next_position INTEGER;
    v_spotify_data JSONB;
BEGIN
    -- Verify user is in room
    IF NOT EXISTS (
        SELECT 1 FROM room_participants 
        WHERE room_id = p_room_id AND user_id = p_user_id AND is_active = true
    ) THEN
        RAISE EXCEPTION 'User must be in room to add tracks to queue';
    END IF;
    
    -- Get next queue position
    SELECT COALESCE(MAX(queue_position), 0) + 1 
    INTO v_next_position
    FROM music_queue 
    WHERE room_id = p_room_id;
    
    -- Get cached Spotify data if available
    SELECT spotify_track_data INTO v_spotify_data
    FROM spotify_tracks_cache 
    WHERE track_uri = p_track_uri;
    
    -- Insert track into queue
    INSERT INTO music_queue (
        room_id, track_uri, track_name, artist_name, album_name,
        track_image_url, duration_ms, queue_position, added_by,
        spotify_track_data
    ) VALUES (
        p_room_id, p_track_uri, p_track_name, p_artist_name, p_album_name,
        p_track_image_url, p_duration_ms, v_next_position, p_user_id,
        COALESCE(v_spotify_data, '{}')
    ) RETURNING id INTO v_queue_id;
    
    -- Update participant stats
    UPDATE room_participants 
    SET tracks_added = tracks_added + 1
    WHERE room_id = p_room_id AND user_id = p_user_id;
    
    -- Update room activity
    UPDATE music_rooms 
    SET last_activity_at = NOW(), updated_at = NOW()
    WHERE id = p_room_id;
    
    RETURN v_queue_id;
END;
$$;

-- Vote on a queued track
CREATE OR REPLACE FUNCTION vote_on_track(
    p_user_id UUID,
    p_track_id UUID,
    p_is_upvote BOOLEAN
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_room_id UUID;
BEGIN
    -- Get room ID from track
    SELECT room_id INTO v_room_id FROM music_queue WHERE id = p_track_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Track not found in queue';
    END IF;
    
    -- Verify user is in room
    IF NOT EXISTS (
        SELECT 1 FROM room_participants 
        WHERE room_id = v_room_id AND user_id = p_user_id AND is_active = true
    ) THEN
        RAISE EXCEPTION 'User must be in room to vote on tracks';
    END IF;
    
    -- Insert or update vote
    INSERT INTO track_votes (track_id, user_id, room_id, is_upvote)
    VALUES (p_track_id, p_user_id, v_room_id, p_is_upvote)
    ON CONFLICT (track_id, user_id)
    DO UPDATE SET is_upvote = p_is_upvote, voted_at = NOW();
    
    -- Update participant stats
    UPDATE room_participants 
    SET votes_cast = votes_cast + 1
    WHERE room_id = v_room_id AND user_id = p_user_id;
    
    RETURN true;
END;
$$;

-- Reorder queue based on votes and add time
CREATE OR REPLACE FUNCTION reorder_queue_by_votes(p_room_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_track_record RECORD;
    v_new_position INTEGER := 1;
    v_reordered_count INTEGER := 0;
BEGIN
    -- Reorder unplayed tracks by vote score, then by add time
    FOR v_track_record IN
        SELECT id
        FROM music_queue
        WHERE room_id = p_room_id AND is_played = false AND is_skipped = false
        ORDER BY vote_score DESC, added_at ASC
    LOOP
        UPDATE music_queue 
        SET queue_position = v_new_position 
        WHERE id = v_track_record.id;
        
        v_new_position := v_new_position + 1;
        v_reordered_count := v_reordered_count + 1;
    END LOOP;
    
    RETURN v_reordered_count;
END;
$$;

-- =============================================================================
-- SYNCHRONIZATION FUNCTIONS
-- =============================================================================

-- Update room playback state
CREATE OR REPLACE FUNCTION update_room_playback_state(
    p_room_id UUID,
    p_user_id UUID,
    p_track_uri VARCHAR(255),
    p_track_name VARCHAR(500),
    p_artist_name VARCHAR(500),
    p_position_ms INTEGER,
    p_is_playing BOOLEAN,
    p_album_name VARCHAR(500) DEFAULT NULL,
    p_track_image_url TEXT DEFAULT NULL,
    p_track_duration_ms INTEGER DEFAULT 0
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_sequence_number BIGINT;
BEGIN
    -- Verify user can control playback (host or moderator)
    IF NOT EXISTS (
        SELECT 1 FROM room_participants 
        WHERE room_id = p_room_id AND user_id = p_user_id 
        AND is_active = true AND role IN ('host', 'moderator')
    ) THEN
        RAISE EXCEPTION 'Only room hosts and moderators can control playback';
    END IF;
    
    -- Get next sequence number
    SELECT COALESCE(MAX(sequence_number), 0) + 1 
    INTO v_sequence_number
    FROM room_sync 
    WHERE room_id = p_room_id;
    
    -- Update room sync state
    INSERT INTO room_sync (
        room_id, track_uri, track_name, artist_name, album_name,
        track_image_url, track_duration_ms, position_ms, is_playing,
        sync_source, sequence_number, timestamp
    ) VALUES (
        p_room_id, p_track_uri, p_track_name, p_artist_name, p_album_name,
        p_track_image_url, p_track_duration_ms, p_position_ms, p_is_playing,
        p_user_id, v_sequence_number, NOW()
    ) ON CONFLICT (room_id)
    DO UPDATE SET
        track_uri = p_track_uri,
        track_name = p_track_name,
        artist_name = p_artist_name,
        album_name = p_album_name,
        track_image_url = p_track_image_url,
        track_duration_ms = p_track_duration_ms,
        position_ms = p_position_ms,
        is_playing = p_is_playing,
        sync_source = p_user_id,
        sequence_number = v_sequence_number,
        timestamp = NOW(),
        updated_at = NOW();
    
    -- Update room current state
    UPDATE music_rooms 
    SET 
        current_track_uri = p_track_uri,
        current_track_name = p_track_name,
        current_artist_name = p_artist_name,
        current_track_image_url = p_track_image_url,
        current_position_ms = p_position_ms,
        is_playing = p_is_playing,
        last_sync_at = NOW(),
        last_activity_at = NOW(),
        updated_at = NOW()
    WHERE id = p_room_id;
    
    RETURN true;
END;
$$;

-- Get current room playback state
CREATE OR REPLACE FUNCTION get_room_playback_state(p_room_id UUID)
RETURNS TABLE (
    track_uri VARCHAR(255),
    track_name VARCHAR(500),
    artist_name VARCHAR(500),
    album_name VARCHAR(500),
    track_image_url TEXT,
    track_duration_ms INTEGER,
    position_ms INTEGER,
    is_playing BOOLEAN,
    last_sync_timestamp TIMESTAMPTZ,
    sequence_number BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        rs.track_uri,
        rs.track_name,
        rs.artist_name,
        rs.album_name,
        rs.track_image_url,
        rs.track_duration_ms,
        rs.position_ms,
        rs.is_playing,
        rs.timestamp,
        rs.sequence_number
    FROM room_sync rs
    WHERE rs.room_id = p_room_id;
END;
$$;

-- =============================================================================
-- REACTION AND INTERACTION FUNCTIONS
-- =============================================================================

-- Add music reaction
CREATE OR REPLACE FUNCTION add_music_reaction(
    p_room_id UUID,
    p_user_id UUID,
    p_reaction VARCHAR(10),
    p_track_uri VARCHAR(255) DEFAULT NULL,
    p_track_position_ms INTEGER DEFAULT 0,
    p_animation_type VARCHAR(50) DEFAULT 'float'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_reaction_id UUID;
BEGIN
    -- Verify user is in room
    IF NOT EXISTS (
        SELECT 1 FROM room_participants 
        WHERE room_id = p_room_id AND user_id = p_user_id AND is_active = true
    ) THEN
        RAISE EXCEPTION 'User must be in room to send reactions';
    END IF;
    
    -- Insert reaction
    INSERT INTO music_reactions (
        room_id, user_id, reaction, track_uri, track_position_ms, animation_type
    ) VALUES (
        p_room_id, p_user_id, p_reaction, p_track_uri, p_track_position_ms, p_animation_type
    ) RETURNING id INTO v_reaction_id;
    
    -- Update participant stats
    UPDATE room_participants 
    SET reactions_sent = reactions_sent + 1
    WHERE room_id = p_room_id AND user_id = p_user_id;
    
    RETURN v_reaction_id;
END;
$$;

-- Clean up expired reactions
CREATE OR REPLACE FUNCTION cleanup_expired_reactions()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    -- Mark expired reactions as invisible
    UPDATE music_reactions 
    SET is_visible = false 
    WHERE expires_at < NOW() AND is_visible = true;
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    -- Delete old invisible reactions (older than 1 hour)
    DELETE FROM music_reactions 
    WHERE is_visible = false AND created_at < NOW() - INTERVAL '1 hour';
    
    RETURN v_deleted_count;
END;
$$;

-- =============================================================================
-- ANALYTICS AND STATISTICS FUNCTIONS
-- =============================================================================

-- Record listening session
CREATE OR REPLACE FUNCTION record_listening_session(
    p_user_id UUID,
    p_track_uri VARCHAR(255),
    p_track_name VARCHAR(500),
    p_artist_name VARCHAR(500),
    p_album_name VARCHAR(500),
    p_duration_ms INTEGER,
    p_played_duration_ms INTEGER,
    p_room_id UUID DEFAULT NULL,
    p_device_type VARCHAR(50) DEFAULT 'mobile',
    p_was_skipped BOOLEAN DEFAULT false,
    p_skip_reason VARCHAR(100) DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_session_id UUID;
    v_completion_percentage DECIMAL(5,2);
BEGIN
    -- Calculate completion percentage
    v_completion_percentage := CASE 
        WHEN p_duration_ms > 0 THEN (p_played_duration_ms * 100.0 / p_duration_ms)
        ELSE 0 
    END;
    
    -- Insert listening history
    INSERT INTO listening_history (
        user_id, track_uri, track_name, artist_name, album_name,
        duration_ms, played_duration_ms, room_id, device_type,
        was_skipped, skip_reason, started_at, ended_at
    ) VALUES (
        p_user_id, p_track_uri, p_track_name, p_artist_name, p_album_name,
        p_duration_ms, p_played_duration_ms, p_room_id, p_device_type,
        p_was_skipped, p_skip_reason, 
        NOW() - (p_played_duration_ms || ' milliseconds')::INTERVAL, 
        NOW()
    ) RETURNING id INTO v_session_id;
    
    -- Update daily stats
    INSERT INTO daily_listening_stats (user_id, listen_date, total_tracks, total_listen_time_minutes)
    VALUES (p_user_id, CURRENT_DATE, 1, CEIL(p_played_duration_ms / 60000.0))
    ON CONFLICT (user_id, listen_date)
    DO UPDATE SET
        total_tracks = daily_listening_stats.total_tracks + 1,
        total_listen_time_minutes = daily_listening_stats.total_listen_time_minutes + CEIL(p_played_duration_ms / 60000.0),
        updated_at = NOW();
    
    RETURN v_session_id;
END;
$$;

-- Calculate user listening insights
CREATE OR REPLACE FUNCTION get_user_listening_insights(
    p_user_id UUID,
    p_days_back INTEGER DEFAULT 30
)
RETURNS TABLE (
    total_tracks INTEGER,
    total_minutes INTEGER,
    unique_artists INTEGER,
    favorite_genre TEXT,
    average_completion_rate DECIMAL(5,2),
    most_played_artist TEXT,
    discovery_rate DECIMAL(5,2)
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_start_date DATE;
BEGIN
    v_start_date := CURRENT_DATE - p_days_back;
    
    RETURN QUERY
    WITH listening_stats AS (
        SELECT 
            COUNT(*) as track_count,
            SUM(played_duration_ms) / 60000 as total_minutes,
            COUNT(DISTINCT artist_name) as unique_artists,
            AVG(completion_percentage) as avg_completion,
            artist_name,
            COUNT(*) as artist_play_count
        FROM listening_history 
        WHERE user_id = p_user_id 
        AND started_at >= v_start_date
        GROUP BY artist_name
    ),
    artist_ranking AS (
        SELECT 
            artist_name,
            artist_play_count,
            ROW_NUMBER() OVER (ORDER BY artist_play_count DESC) as rank
        FROM listening_stats
    )
    SELECT 
        (SELECT SUM(track_count)::INTEGER FROM listening_stats),
        (SELECT SUM(total_minutes)::INTEGER FROM listening_stats),
        (SELECT COUNT(DISTINCT artist_name)::INTEGER FROM listening_stats),
        'Electronic'::TEXT as favorite_genre, -- Could be enhanced with genre analysis
        (SELECT AVG(avg_completion)::DECIMAL(5,2) FROM listening_stats),
        (SELECT artist_name FROM artist_ranking WHERE rank = 1),
        -- Discovery rate: percentage of tracks played only once
        (SELECT 
            (COUNT(*) FILTER (WHERE artist_play_count = 1) * 100.0 / COUNT(*))::DECIMAL(5,2)
         FROM listening_stats
        )
    LIMIT 1;
END;
$$;

-- Generate room analytics
CREATE OR REPLACE FUNCTION generate_room_analytics(
    p_room_id UUID,
    p_target_date DATE DEFAULT CURRENT_DATE
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_analytics_record room_analytics%ROWTYPE;
BEGIN
    -- Calculate daily analytics
    WITH room_stats AS (
        SELECT 
            COUNT(DISTINCT rp.user_id) as unique_participants,
            COUNT(rp.joined_at) as total_joins,
            AVG(EXTRACT(EPOCH FROM (COALESCE(rp.left_at, NOW()) - rp.joined_at)) / 60) as avg_session_minutes,
            MAX(mr.listener_count) as peak_concurrent
        FROM room_participants rp
        LEFT JOIN music_rooms mr ON mr.id = rp.room_id
        WHERE rp.room_id = p_room_id 
        AND DATE(rp.joined_at) = p_target_date
    ),
    track_stats AS (
        SELECT 
            COUNT(*) FILTER (WHERE is_played = true) as tracks_played,
            COUNT(*) FILTER (WHERE is_skipped = true) as tracks_skipped,
            COUNT(DISTINCT artist_name) as unique_artists
        FROM music_queue 
        WHERE room_id = p_room_id 
        AND DATE(added_at) = p_target_date
    ),
    interaction_stats AS (
        SELECT 
            COUNT(*) as total_reactions
        FROM music_reactions 
        WHERE room_id = p_room_id 
        AND DATE(created_at) = p_target_date
    )
    SELECT 
        p_room_id,
        p_target_date,
        rs.unique_participants,
        rs.total_joins,
        rs.avg_session_minutes,
        rs.peak_concurrent,
        ts.tracks_played,
        ts.tracks_skipped,
        ts.unique_artists,
        is_t.total_reactions
    INTO 
        v_analytics_record.room_id,
        v_analytics_record.analytics_date,
        v_analytics_record.unique_participants,
        v_analytics_record.total_join_events,
        v_analytics_record.average_session_minutes,
        v_analytics_record.peak_concurrent_users,
        v_analytics_record.tracks_played,
        v_analytics_record.tracks_skipped,
        v_analytics_record.unique_artists,
        v_analytics_record.total_reactions
    FROM room_stats rs
    CROSS JOIN track_stats ts
    CROSS JOIN interaction_stats is_t;
    
    -- Insert or update analytics
    INSERT INTO room_analytics (
        room_id, analytics_date, unique_participants, total_join_events,
        average_session_minutes, peak_concurrent_users, tracks_played,
        tracks_skipped, unique_artists, total_reactions
    ) VALUES (
        v_analytics_record.room_id,
        v_analytics_record.analytics_date,
        COALESCE(v_analytics_record.unique_participants, 0),
        COALESCE(v_analytics_record.total_join_events, 0),
        COALESCE(v_analytics_record.average_session_minutes, 0),
        COALESCE(v_analytics_record.peak_concurrent_users, 0),
        COALESCE(v_analytics_record.tracks_played, 0),
        COALESCE(v_analytics_record.tracks_skipped, 0),
        COALESCE(v_analytics_record.unique_artists, 0),
        COALESCE(v_analytics_record.total_reactions, 0)
    ) ON CONFLICT (room_id, analytics_date)
    DO UPDATE SET
        unique_participants = EXCLUDED.unique_participants,
        total_join_events = EXCLUDED.total_join_events,
        average_session_minutes = EXCLUDED.average_session_minutes,
        peak_concurrent_users = EXCLUDED.peak_concurrent_users,
        tracks_played = EXCLUDED.tracks_played,
        tracks_skipped = EXCLUDED.tracks_skipped,
        unique_artists = EXCLUDED.unique_artists,
        total_reactions = EXCLUDED.total_reactions,
        updated_at = NOW();
    
    RETURN true;
END;
$$;

-- =============================================================================
-- CACHE MANAGEMENT FUNCTIONS
-- =============================================================================

-- Cache Spotify track information
CREATE OR REPLACE FUNCTION cache_spotify_track(
    p_track_uri VARCHAR(255),
    p_track_id VARCHAR(100),
    p_name VARCHAR(500),
    p_duration_ms INTEGER,
    p_artists JSONB,
    p_album_data JSONB DEFAULT '{}',
    p_audio_features JSONB DEFAULT '{}',
    p_popularity INTEGER DEFAULT 0
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_primary_artist_name VARCHAR(500);
    v_primary_artist_id VARCHAR(100);
    v_album_image_url TEXT;
BEGIN
    -- Extract primary artist info
    v_primary_artist_name := p_artists->0->>'name';
    v_primary_artist_id := p_artists->0->>'id';
    
    -- Extract album image
    v_album_image_url := p_album_data->'images'->0->>'url';
    
    -- Insert or update cache
    INSERT INTO spotify_tracks_cache (
        track_uri, track_id, name, duration_ms, artists,
        primary_artist_name, primary_artist_id, album_name,
        album_image_url, audio_features, popularity
    ) VALUES (
        p_track_uri, p_track_id, p_name, p_duration_ms, p_artists,
        v_primary_artist_name, v_primary_artist_id, p_album_data->>'name',
        v_album_image_url, p_audio_features, p_popularity
    ) ON CONFLICT (track_uri)
    DO UPDATE SET
        name = p_name,
        duration_ms = p_duration_ms,
        artists = p_artists,
        primary_artist_name = v_primary_artist_name,
        primary_artist_id = v_primary_artist_id,
        album_name = p_album_data->>'name',
        album_image_url = v_album_image_url,
        audio_features = p_audio_features,
        popularity = p_popularity,
        cache_updated_at = NOW(),
        cache_expires_at = NOW() + INTERVAL '30 days';
    
    RETURN true;
END;
$$;

-- Clean up expired cache entries
CREATE OR REPLACE FUNCTION cleanup_expired_cache()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    -- Delete expired tracks
    DELETE FROM spotify_tracks_cache WHERE cache_expires_at < NOW();
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    -- Delete expired artists
    DELETE FROM spotify_artists_cache WHERE cache_expires_at < NOW();
    
    RETURN v_deleted_count;
END;
$$;

-- =============================================================================
-- AUTOMATED MAINTENANCE FUNCTIONS
-- =============================================================================

-- Daily maintenance routine
CREATE OR REPLACE FUNCTION daily_spotify_maintenance()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_expired_reactions INTEGER;
    v_expired_cache INTEGER;
    v_analytics_generated INTEGER;
    v_result TEXT;
BEGIN
    -- Clean up expired reactions
    SELECT cleanup_expired_reactions() INTO v_expired_reactions;
    
    -- Clean up expired cache
    SELECT cleanup_expired_cache() INTO v_expired_cache;
    
    -- Generate analytics for active rooms
    WITH analytics_generation AS (
        INSERT INTO room_analytics (
            room_id, analytics_date, unique_participants,
            total_join_events, tracks_played, total_reactions
        )
        SELECT 
            mr.id,
            CURRENT_DATE - 1,
            COALESCE(COUNT(DISTINCT rp.user_id), 0),
            COALESCE(COUNT(rp.joined_at), 0),
            COALESCE(COUNT(mq.id) FILTER (WHERE mq.is_played = true), 0),
            COALESCE(COUNT(mr_reactions.id), 0)
        FROM music_rooms mr
        LEFT JOIN room_participants rp ON rp.room_id = mr.id 
            AND DATE(rp.joined_at) = CURRENT_DATE - 1
        LEFT JOIN music_queue mq ON mq.room_id = mr.id 
            AND DATE(mq.added_at) = CURRENT_DATE - 1
        LEFT JOIN music_reactions mr_reactions ON mr_reactions.room_id = mr.id 
            AND DATE(mr_reactions.created_at) = CURRENT_DATE - 1
        WHERE mr.is_active = true
        AND mr.last_activity_at >= CURRENT_DATE - 2
        GROUP BY mr.id
        ON CONFLICT (room_id, analytics_date) DO NOTHING
        RETURNING 1
    )
    SELECT COUNT(*) INTO v_analytics_generated FROM analytics_generation;
    
    v_result := format(
        'Daily maintenance completed: %s expired reactions cleaned, %s expired cache entries removed, %s room analytics generated',
        v_expired_reactions, v_expired_cache, v_analytics_generated
    );
    
    RETURN v_result;
END;
$$;

-- =============================================================================
-- PERMISSION AND SECURITY FUNCTIONS
-- =============================================================================

-- Check if user can moderate room
CREATE OR REPLACE FUNCTION can_moderate_room(
    p_user_id UUID,
    p_room_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM room_participants 
        WHERE room_id = p_room_id 
        AND user_id = p_user_id 
        AND is_active = true 
        AND role IN ('host', 'moderator')
    );
END;
$$;

-- Grant/revoke room moderator privileges
CREATE OR REPLACE FUNCTION set_room_moderator(
    p_room_id UUID,
    p_target_user_id UUID,
    p_requesting_user_id UUID,
    p_grant_access BOOLEAN
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_new_role VARCHAR(50);
BEGIN
    -- Check if requesting user is host
    IF NOT EXISTS (
        SELECT 1 FROM room_participants 
        WHERE room_id = p_room_id AND user_id = p_requesting_user_id 
        AND is_active = true AND role = 'host'
    ) THEN
        RAISE EXCEPTION 'Only room host can grant/revoke moderator privileges';
    END IF;
    
    -- Determine new role
    v_new_role := CASE WHEN p_grant_access THEN 'moderator' ELSE 'listener' END;
    
    -- Update participant role
    UPDATE room_participants 
    SET role = v_new_role
    WHERE room_id = p_room_id AND user_id = p_target_user_id AND is_active = true;
    
    RETURN FOUND;
END;
$$;

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON FUNCTION create_music_room IS 'Creates a new music room with host validation and initial setup';
COMMENT ON FUNCTION join_music_room IS 'Handles user joining a music room with capacity and password checks';
COMMENT ON FUNCTION leave_music_room IS 'Manages user leaving a room with ownership transfer if needed';
COMMENT ON FUNCTION add_track_to_queue IS 'Adds tracks to room queue with position management and validation';
COMMENT ON FUNCTION vote_on_track IS 'Handles democratic voting on queued tracks';
COMMENT ON FUNCTION update_room_playback_state IS 'Updates real-time playback synchronization state';
COMMENT ON FUNCTION add_music_reaction IS 'Adds real-time emoji reactions during music playback';
COMMENT ON FUNCTION record_listening_session IS 'Records user listening history with analytics';
COMMENT ON FUNCTION cache_spotify_track IS 'Caches Spotify track data for performance optimization';
COMMENT ON FUNCTION daily_spotify_maintenance IS 'Daily automated maintenance for the Spotify system';

-- Setup completion message
SELECT 'Spotify Business Logic Setup Complete!' as status, NOW() as setup_completed_at;
