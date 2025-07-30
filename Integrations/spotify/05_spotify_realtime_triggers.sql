-- Crystal Social Spotify System - Real-time Features and Triggers
-- File: 05_spotify_realtime_triggers.sql
-- Purpose: Real-time synchronization, triggers, and automated processes for the Spotify system

-- =============================================================================
-- REAL-TIME SYNCHRONIZATION INFRASTRUCTURE
-- =============================================================================

-- Enable necessary extensions for real-time features
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Create notification channels for real-time updates
DO $$
BEGIN
    -- Check if channels exist, create if not (PostgreSQL doesn't have CREATE CHANNEL IF NOT EXISTS)
    PERFORM 1;
END $$;

-- =============================================================================
-- REAL-TIME NOTIFICATION FUNCTIONS
-- =============================================================================

-- Generic notification function for real-time updates
CREATE OR REPLACE FUNCTION notify_realtime_update(
    channel TEXT,
    event_type TEXT,
    data JSONB DEFAULT '{}'
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    notification JSONB;
BEGIN
    -- Construct notification payload
    notification := jsonb_build_object(
        'event', event_type,
        'timestamp', extract(epoch from now()),
        'data', data
    );
    
    -- Send notification
    PERFORM pg_notify(channel, notification::TEXT);
END;
$$;

-- Room state change notifications
CREATE OR REPLACE FUNCTION notify_room_update(
    p_room_id UUID,
    p_event_type TEXT,
    p_data JSONB DEFAULT '{}'
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    room_channel TEXT;
BEGIN
    -- Create room-specific channel
    room_channel := 'room_' || p_room_id::TEXT;
    
    -- Send notification with room context
    PERFORM notify_realtime_update(
        room_channel, 
        p_event_type, 
        jsonb_build_object(
            'room_id', p_room_id,
            'details', p_data
        )
    );
    
    -- Also send to global rooms channel for dashboard updates
    PERFORM notify_realtime_update(
        'rooms_global',
        p_event_type,
        jsonb_build_object(
            'room_id', p_room_id,
            'details', p_data
        )
    );
END;
$$;

-- User activity notifications
CREATE OR REPLACE FUNCTION notify_user_activity(
    p_user_id UUID,
    p_event_type TEXT,
    p_data JSONB DEFAULT '{}'
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_channel TEXT;
BEGIN
    -- Create user-specific channel
    user_channel := 'user_' || p_user_id::TEXT;
    
    -- Send notification
    PERFORM notify_realtime_update(
        user_channel,
        p_event_type,
        jsonb_build_object(
            'user_id', p_user_id,
            'details', p_data
        )
    );
END;
$$;

-- =============================================================================
-- ROOM STATE SYNCHRONIZATION TRIGGERS
-- =============================================================================

-- Trigger for room sync updates
CREATE OR REPLACE FUNCTION trigger_room_sync_update()
RETURNS TRIGGER AS $$
DECLARE
    sync_data JSONB;
BEGIN
    -- Prepare sync data
    sync_data := jsonb_build_object(
        'track_uri', NEW.track_uri,
        'track_name', NEW.track_name,
        'artist_name', NEW.artist_name,
        'album_name', NEW.album_name,
        'track_image_url', NEW.track_image_url,
        'track_duration_ms', NEW.track_duration_ms,
        'position_ms', NEW.position_ms,
        'is_playing', NEW.is_playing,
        'timestamp', NEW.timestamp,
        'sequence_number', NEW.sequence_number,
        'sync_source', NEW.sync_source
    );
    
    -- Notify room participants of sync update
    PERFORM notify_room_update(
        NEW.room_id,
        'playback_sync',
        sync_data
    );
    
    -- Update room's current state
    UPDATE music_rooms 
    SET 
        current_track_uri = NEW.track_uri,
        current_track_name = NEW.track_name,
        current_artist_name = NEW.artist_name,
        current_track_image_url = NEW.track_image_url,
        current_position_ms = NEW.position_ms,
        is_playing = NEW.is_playing,
        last_sync_at = NEW.timestamp,
        last_activity_at = NOW(),
        updated_at = NOW()
    WHERE id = NEW.room_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_room_sync_realtime
    AFTER INSERT OR UPDATE ON room_sync
    FOR EACH ROW EXECUTE FUNCTION trigger_room_sync_update();

-- =============================================================================
-- ROOM PARTICIPANT ACTIVITY TRIGGERS
-- =============================================================================

-- Trigger for participant join/leave events
CREATE OR REPLACE FUNCTION trigger_participant_activity()
RETURNS TRIGGER AS $$
DECLARE
    event_type TEXT;
    participant_data JSONB;
    room_data JSONB;
BEGIN
    -- Determine event type
    IF TG_OP = 'INSERT' THEN
        event_type := 'participant_joined';
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.is_active = true AND NEW.is_active = false THEN
            event_type := 'participant_left';
        ELSIF OLD.is_active = false AND NEW.is_active = true THEN
            event_type := 'participant_rejoined';
        ELSE
            event_type := 'participant_updated';
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        event_type := 'participant_removed';
    END IF;
    
    -- Prepare participant data
    participant_data := jsonb_build_object(
        'user_id', COALESCE(NEW.user_id, OLD.user_id),
        'role', COALESCE(NEW.role, OLD.role),
        'is_active', COALESCE(NEW.is_active, false),
        'username', (
            SELECT username FROM user_profiles 
            WHERE user_id = COALESCE(NEW.user_id, OLD.user_id)
        )
    );
    
    -- Get room data for context
    SELECT jsonb_build_object(
        'room_id', id,
        'room_name', name,
        'listener_count', listener_count
    ) INTO room_data
    FROM music_rooms 
    WHERE id = COALESCE(NEW.room_id, OLD.room_id);
    
    -- Notify room of participant change
    PERFORM notify_room_update(
        COALESCE(NEW.room_id, OLD.room_id),
        event_type,
        jsonb_build_object(
            'participant', participant_data,
            'room', room_data
        )
    );
    
    -- Update participant's last activity time
    IF TG_OP IN ('INSERT', 'UPDATE') AND NEW.is_active = true THEN
        NEW.last_active_at := NOW();
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_participant_activity_realtime
    AFTER INSERT OR UPDATE OR DELETE ON room_participants
    FOR EACH ROW EXECUTE FUNCTION trigger_participant_activity();

-- =============================================================================
-- MUSIC QUEUE MANAGEMENT TRIGGERS
-- =============================================================================

-- Trigger for queue updates
CREATE OR REPLACE FUNCTION trigger_queue_update()
RETURNS TRIGGER AS $$
DECLARE
    event_type TEXT;
    queue_data JSONB;
BEGIN
    -- Determine event type
    IF TG_OP = 'INSERT' THEN
        event_type := 'track_added';
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.is_played = false AND NEW.is_played = true THEN
            event_type := 'track_played';
        ELSIF OLD.is_skipped = false AND NEW.is_skipped = true THEN
            event_type := 'track_skipped';
        ELSIF OLD.queue_position != NEW.queue_position THEN
            event_type := 'queue_reordered';
        ELSE
            event_type := 'track_updated';
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        event_type := 'track_removed';
    END IF;
    
    -- Prepare queue data
    queue_data := jsonb_build_object(
        'track_id', COALESCE(NEW.id, OLD.id),
        'track_uri', COALESCE(NEW.track_uri, OLD.track_uri),
        'track_name', COALESCE(NEW.track_name, OLD.track_name),
        'artist_name', COALESCE(NEW.artist_name, OLD.artist_name),
        'queue_position', COALESCE(NEW.queue_position, OLD.queue_position),
        'vote_score', COALESCE(NEW.vote_score, OLD.vote_score),
        'added_by', COALESCE(NEW.added_by, OLD.added_by),
        'added_by_username', (
            SELECT username FROM user_profiles 
            WHERE user_id = COALESCE(NEW.added_by, OLD.added_by)
        )
    );
    
    -- Notify room of queue change
    PERFORM notify_room_update(
        COALESCE(NEW.room_id, OLD.room_id),
        event_type,
        jsonb_build_object(
            'queue_item', queue_data,
            'total_queue_length', (
                SELECT COUNT(*) FROM music_queue 
                WHERE room_id = COALESCE(NEW.room_id, OLD.room_id) 
                AND NOT is_played AND NOT is_skipped
            )
        )
    );
    
    -- Update room activity
    UPDATE music_rooms 
    SET 
        last_activity_at = NOW(),
        updated_at = NOW(),
        total_tracks_played = CASE 
            WHEN event_type = 'track_played' THEN total_tracks_played + 1
            ELSE total_tracks_played
        END
    WHERE id = COALESCE(NEW.room_id, OLD.room_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_queue_update_realtime
    AFTER INSERT OR UPDATE OR DELETE ON music_queue
    FOR EACH ROW EXECUTE FUNCTION trigger_queue_update();

-- =============================================================================
-- VOTING SYSTEM TRIGGERS
-- =============================================================================

-- Trigger for track voting updates
CREATE OR REPLACE FUNCTION trigger_vote_update()
RETURNS TRIGGER AS $$
DECLARE
    vote_data JSONB;
    track_data JSONB;
BEGIN
    -- Get track information
    SELECT jsonb_build_object(
        'track_id', id,
        'track_name', track_name,
        'artist_name', artist_name,
        'queue_position', queue_position,
        'upvotes', upvotes,
        'downvotes', downvotes,
        'vote_score', vote_score
    ) INTO track_data
    FROM music_queue 
    WHERE id = COALESCE(NEW.track_id, OLD.track_id);
    
    -- Prepare vote data
    vote_data := jsonb_build_object(
        'voter_id', COALESCE(NEW.user_id, OLD.user_id),
        'is_upvote', COALESCE(NEW.is_upvote, OLD.is_upvote),
        'voter_username', (
            SELECT username FROM user_profiles 
            WHERE user_id = COALESCE(NEW.user_id, OLD.user_id)
        ),
        'track', track_data
    );
    
    -- Notify room of vote change
    PERFORM notify_room_update(
        COALESCE(NEW.room_id, OLD.room_id),
        CASE 
            WHEN TG_OP = 'INSERT' THEN 'vote_added'
            WHEN TG_OP = 'UPDATE' THEN 'vote_changed'
            ELSE 'vote_removed'
        END,
        vote_data
    );
    
    -- Check if queue should be reordered (if enough votes changed)
    IF track_data->>'vote_score' != '0' AND track_data->>'queue_position' != '1' THEN
        -- Auto-reorder if vote score changes significantly
        PERFORM reorder_queue_by_votes(COALESCE(NEW.room_id, OLD.room_id));
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_vote_update_realtime
    AFTER INSERT OR UPDATE OR DELETE ON track_votes
    FOR EACH ROW EXECUTE FUNCTION trigger_vote_update();

-- =============================================================================
-- REACTION SYSTEM TRIGGERS
-- =============================================================================

-- Trigger for real-time reactions
CREATE OR REPLACE FUNCTION trigger_reaction_added()
RETURNS TRIGGER AS $$
DECLARE
    reaction_data JSONB;
BEGIN
    -- Only trigger for new reactions
    IF TG_OP != 'INSERT' THEN
        RETURN NEW;
    END IF;
    
    -- Prepare reaction data
    reaction_data := jsonb_build_object(
        'reaction_id', NEW.id,
        'user_id', NEW.user_id,
        'reaction', NEW.reaction,
        'track_uri', NEW.track_uri,
        'track_position_ms', NEW.track_position_ms,
        'animation_type', NEW.animation_type,
        'start_position', NEW.start_position,
        'expires_at', extract(epoch from NEW.expires_at),
        'username', (
            SELECT username FROM user_profiles 
            WHERE user_id = NEW.user_id
        )
    );
    
    -- Notify room of new reaction
    PERFORM notify_room_update(
        NEW.room_id,
        'reaction_added',
        reaction_data
    );
    
    -- Increment reaction counter for user
    UPDATE room_participants 
    SET reactions_sent = reactions_sent + 1
    WHERE room_id = NEW.room_id AND user_id = NEW.user_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_reaction_added_realtime
    AFTER INSERT ON music_reactions
    FOR EACH ROW EXECUTE FUNCTION trigger_reaction_added();

-- =============================================================================
-- LISTENING ACTIVITY TRIGGERS
-- =============================================================================

-- Trigger for listening history updates
CREATE OR REPLACE FUNCTION trigger_listening_activity()
RETURNS TRIGGER AS $$
DECLARE
    activity_data JSONB;
BEGIN
    -- Only trigger for new listening sessions
    IF TG_OP != 'INSERT' THEN
        RETURN NEW;
    END IF;
    
    -- Prepare activity data
    activity_data := jsonb_build_object(
        'user_id', NEW.user_id,
        'track_name', NEW.track_name,
        'artist_name', NEW.artist_name,
        'room_id', NEW.room_id,
        'completion_percentage', NEW.completion_percentage,
        'started_at', NEW.started_at
    );
    
    -- Notify user's activity channel
    PERFORM notify_user_activity(
        NEW.user_id,
        'track_listened',
        activity_data
    );
    
    -- If in a room, notify room as well
    IF NEW.room_id IS NOT NULL THEN
        PERFORM notify_room_update(
            NEW.room_id,
            'user_listening',
            jsonb_build_object(
                'user_id', NEW.user_id,
                'track_name', NEW.track_name,
                'artist_name', NEW.artist_name,
                'username', (
                    SELECT username FROM user_profiles 
                    WHERE user_id = NEW.user_id
                )
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_listening_activity_realtime
    AFTER INSERT ON listening_history
    FOR EACH ROW EXECUTE FUNCTION trigger_listening_activity();

-- =============================================================================
-- ROOM HEARTBEAT AND ACTIVITY TRACKING
-- =============================================================================

-- Function to update participant heartbeat
CREATE OR REPLACE FUNCTION update_participant_heartbeat(
    p_user_id UUID,
    p_room_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Update last active time
    UPDATE room_participants 
    SET last_active_at = NOW()
    WHERE room_id = p_room_id 
    AND user_id = p_user_id 
    AND is_active = true;
    
    -- Update room activity
    UPDATE music_rooms 
    SET last_activity_at = NOW()
    WHERE id = p_room_id;
    
    RETURN FOUND;
END;
$$;

-- Automated cleanup function for inactive participants
CREATE OR REPLACE FUNCTION cleanup_inactive_participants()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    participant_record RECORD;
    deactivated_count INTEGER := 0;
BEGIN
    -- Find participants inactive for more than 30 minutes
    FOR participant_record IN
        SELECT rp.room_id, rp.user_id, rp.role
        FROM room_participants rp
        WHERE rp.is_active = true 
        AND rp.last_active_at < NOW() - INTERVAL '30 minutes'
    LOOP
        -- Deactivate participant
        UPDATE room_participants 
        SET 
            is_active = false,
            left_at = NOW()
        WHERE room_id = participant_record.room_id 
        AND user_id = participant_record.user_id;
        
        -- If host was deactivated, transfer ownership
        IF participant_record.role = 'host' THEN
            PERFORM transfer_room_ownership(participant_record.room_id);
        END IF;
        
        deactivated_count := deactivated_count + 1;
    END LOOP;
    
    RETURN deactivated_count;
END;
$$;

-- =============================================================================
-- AUTOMATED MAINTENANCE AND CLEANUP
-- =============================================================================

-- Function to perform real-time system maintenance
CREATE OR REPLACE FUNCTION realtime_system_maintenance()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    inactive_participants INTEGER;
    expired_reactions INTEGER;
    room_analytics_updated INTEGER;
    result TEXT;
BEGIN
    -- Clean up inactive participants
    SELECT cleanup_inactive_participants() INTO inactive_participants;
    
    -- Clean up expired reactions
    SELECT cleanup_expired_reactions() INTO expired_reactions;
    
    -- Update room analytics for active rooms
    WITH analytics_update AS (
        UPDATE room_analytics 
        SET 
            peak_concurrent_users = GREATEST(
                peak_concurrent_users, 
                (SELECT listener_count FROM music_rooms WHERE id = room_id)
            ),
            updated_at = NOW()
        WHERE analytics_date = CURRENT_DATE
        AND room_id IN (
            SELECT id FROM music_rooms 
            WHERE is_active = true 
            AND last_activity_at >= NOW() - INTERVAL '1 hour'
        )
        RETURNING 1
    )
    SELECT COUNT(*) INTO room_analytics_updated FROM analytics_update;
    
    -- Prepare result message
    result := format(
        'Real-time maintenance: %s inactive participants cleaned, %s expired reactions removed, %s room analytics updated',
        inactive_participants, expired_reactions, room_analytics_updated
    );
    
    -- Notify system channel of maintenance completion
    PERFORM notify_realtime_update(
        'system_maintenance',
        'maintenance_completed',
        jsonb_build_object(
            'inactive_participants', inactive_participants,
            'expired_reactions', expired_reactions,
            'room_analytics_updated', room_analytics_updated
        )
    );
    
    RETURN result;
END;
$$;

-- =============================================================================
-- PERFORMANCE MONITORING TRIGGERS
-- =============================================================================

-- Function to track query performance for optimization
CREATE OR REPLACE FUNCTION track_query_performance()
RETURNS TRIGGER AS $$
DECLARE
    slow_query_threshold INTERVAL := '5 seconds';
    query_duration INTERVAL;
BEGIN
    -- This would be implemented with actual performance monitoring
    -- For now, it's a placeholder for performance tracking
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- SCHEDULED JOBS AND CRON FUNCTIONS
-- =============================================================================

-- Function to be called by external scheduler (every minute)
CREATE OR REPLACE FUNCTION minute_maintenance()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Quick cleanup of expired reactions and inactive participants
    PERFORM cleanup_expired_reactions();
    PERFORM cleanup_inactive_participants();
    
    RETURN 'Minute maintenance completed at ' || NOW()::TEXT;
END;
$$;

-- Function to be called by external scheduler (every hour)
CREATE OR REPLACE FUNCTION hourly_maintenance()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- More comprehensive maintenance
    PERFORM realtime_system_maintenance();
    PERFORM cleanup_rate_limits();
    
    -- Update room analytics
    PERFORM generate_room_analytics(room_id, CURRENT_DATE)
    FROM music_rooms 
    WHERE is_active = true 
    AND last_activity_at >= CURRENT_DATE;
    
    RETURN 'Hourly maintenance completed at ' || NOW()::TEXT;
END;
$$;

-- =============================================================================
-- WEBSOCKET CONNECTION MANAGEMENT
-- =============================================================================

-- Function to handle websocket connection events
CREATE OR REPLACE FUNCTION handle_websocket_connection(
    p_user_id UUID,
    p_connection_type TEXT, -- 'connect' or 'disconnect'
    p_room_id UUID DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF p_connection_type = 'connect' THEN
        -- Update user's last active time if in a room
        IF p_room_id IS NOT NULL THEN
            PERFORM update_participant_heartbeat(p_user_id, p_room_id);
        END IF;
        
        -- Notify user activity
        PERFORM notify_user_activity(
            p_user_id,
            'user_connected',
            jsonb_build_object('room_id', p_room_id)
        );
        
    ELSIF p_connection_type = 'disconnect' THEN
        -- Handle disconnection gracefully
        IF p_room_id IS NOT NULL THEN
            -- Don't immediately remove from room, just mark as inactive
            UPDATE room_participants 
            SET last_active_at = NOW() - INTERVAL '5 minutes'
            WHERE room_id = p_room_id AND user_id = p_user_id;
        END IF;
        
        -- Notify user activity
        PERFORM notify_user_activity(
            p_user_id,
            'user_disconnected',
            jsonb_build_object('room_id', p_room_id)
        );
    END IF;
    
    RETURN true;
END;
$$;

-- =============================================================================
-- GRANT PERMISSIONS
-- =============================================================================

-- Grant permissions for real-time functions
GRANT EXECUTE ON FUNCTION notify_realtime_update TO authenticated;
GRANT EXECUTE ON FUNCTION notify_room_update TO authenticated;
GRANT EXECUTE ON FUNCTION notify_user_activity TO authenticated;
GRANT EXECUTE ON FUNCTION update_participant_heartbeat TO authenticated;
GRANT EXECUTE ON FUNCTION handle_websocket_connection TO authenticated;
GRANT EXECUTE ON FUNCTION minute_maintenance TO service_role;
GRANT EXECUTE ON FUNCTION hourly_maintenance TO service_role;
GRANT EXECUTE ON FUNCTION realtime_system_maintenance TO service_role;
GRANT EXECUTE ON FUNCTION cleanup_inactive_participants TO service_role;

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON FUNCTION notify_realtime_update IS 'Generic function for sending real-time notifications via PostgreSQL NOTIFY';
COMMENT ON FUNCTION notify_room_update IS 'Sends real-time notifications for room state changes';
COMMENT ON FUNCTION notify_user_activity IS 'Sends real-time notifications for user activity';
COMMENT ON FUNCTION update_participant_heartbeat IS 'Updates participant heartbeat for activity tracking';
COMMENT ON FUNCTION cleanup_inactive_participants IS 'Automatically deactivates participants who have been inactive';
COMMENT ON FUNCTION realtime_system_maintenance IS 'Performs comprehensive real-time system maintenance';
COMMENT ON FUNCTION handle_websocket_connection IS 'Handles websocket connection and disconnection events';

-- =============================================================================
-- REAL-TIME MONITORING SETUP
-- =============================================================================

-- Create table for real-time system status
CREATE TABLE spotify_realtime_status (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    active_connections INTEGER DEFAULT 0,
    active_rooms INTEGER DEFAULT 0,
    total_listeners INTEGER DEFAULT 0,
    notifications_sent_per_minute INTEGER DEFAULT 0,
    last_heartbeat TIMESTAMPTZ DEFAULT NOW(),
    system_health VARCHAR(20) DEFAULT 'healthy', -- healthy, warning, critical
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert initial status record
INSERT INTO spotify_realtime_status (active_connections, active_rooms, total_listeners)
VALUES (0, 0, 0);

-- Function to update real-time status
CREATE OR REPLACE FUNCTION update_realtime_status()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_rooms INTEGER;
    current_listeners INTEGER;
    system_status VARCHAR(20);
BEGIN
    -- Get current metrics
    SELECT COUNT(*) INTO current_rooms
    FROM music_rooms 
    WHERE is_active = true;
    
    SELECT SUM(listener_count) INTO current_listeners
    FROM music_rooms 
    WHERE is_active = true;
    
    -- Determine system health
    system_status := CASE 
        WHEN current_listeners > 1000 THEN 'warning'
        WHEN current_listeners > 5000 THEN 'critical'
        ELSE 'healthy'
    END;
    
    -- Update status
    UPDATE spotify_realtime_status 
    SET 
        active_rooms = current_rooms,
        total_listeners = COALESCE(current_listeners, 0),
        system_health = system_status,
        last_heartbeat = NOW(),
        updated_at = NOW()
    WHERE id = (SELECT id FROM spotify_realtime_status ORDER BY created_at DESC LIMIT 1);
END;
$$;

-- Setup completion message
SELECT 
    'Spotify Real-time Features and Triggers Setup Complete!' as status,
    (SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_name LIKE '%realtime%' OR trigger_name LIKE '%room%' OR trigger_name LIKE '%queue%') as triggers_created,
    (SELECT COUNT(*) FROM information_schema.routines WHERE routine_name LIKE '%notify%' OR routine_name LIKE '%realtime%') as functions_created,
    NOW() as setup_completed_at;
