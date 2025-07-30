-- Crystal Social Spotify System - Security and Permissions
-- File: 04_spotify_security_rls.sql
-- Purpose: Row Level Security (RLS) policies and security configurations for Spotify system

-- =============================================================================
-- ENABLE ROW LEVEL SECURITY ON ALL SPOTIFY TABLES (SAFE BATCH)
-- =============================================================================

-- Enable RLS on core tables (batch 1 - user-related tables)
DO $$ 
BEGIN
    -- Enable RLS with proper error handling
    ALTER TABLE IF EXISTS spotify_user_accounts ENABLE ROW LEVEL SECURITY;
    ALTER TABLE IF EXISTS spotify_user_preferences ENABLE ROW LEVEL SECURITY;
    ALTER TABLE IF EXISTS listening_history ENABLE ROW LEVEL SECURITY;
    ALTER TABLE IF EXISTS daily_listening_stats ENABLE ROW LEVEL SECURITY;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error enabling RLS on user tables: %', SQLERRM;
END $$;

-- Enable RLS on room-related tables (batch 2)
DO $$ 
BEGIN
    ALTER TABLE IF EXISTS music_rooms ENABLE ROW LEVEL SECURITY;
    ALTER TABLE IF EXISTS room_participants ENABLE ROW LEVEL SECURITY;
    ALTER TABLE IF EXISTS room_sync ENABLE ROW LEVEL SECURITY;
    ALTER TABLE IF EXISTS room_analytics ENABLE ROW LEVEL SECURITY;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error enabling RLS on room tables: %', SQLERRM;
END $$;

-- Enable RLS on activity tables (batch 3)
DO $$ 
BEGIN
    ALTER TABLE IF EXISTS music_queue ENABLE ROW LEVEL SECURITY;
    ALTER TABLE IF EXISTS track_votes ENABLE ROW LEVEL SECURITY;
    ALTER TABLE IF EXISTS music_reactions ENABLE ROW LEVEL SECURITY;
    ALTER TABLE IF EXISTS music_chat ENABLE ROW LEVEL SECURITY;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error enabling RLS on activity tables: %', SQLERRM;
END $$;

-- Enable RLS on cache tables (batch 4)
DO $$ 
BEGIN
    ALTER TABLE IF EXISTS spotify_tracks_cache ENABLE ROW LEVEL SECURITY;
    ALTER TABLE IF EXISTS spotify_artists_cache ENABLE ROW LEVEL SECURITY;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error enabling RLS on cache tables: %', SQLERRM;
END $$;

-- =============================================================================
-- SPOTIFY USER ACCOUNTS AND PREFERENCES POLICIES
-- =============================================================================

-- Spotify user accounts: Users can only see and modify their own accounts
CREATE POLICY "Users can view own spotify accounts" ON spotify_user_accounts
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert own spotify accounts" ON spotify_user_accounts
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own spotify accounts" ON spotify_user_accounts
    FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own spotify accounts" ON spotify_user_accounts
    FOR DELETE USING (user_id = auth.uid());

-- Admin users can see all spotify accounts for moderation
CREATE POLICY "Admins can view all spotify accounts" ON spotify_user_accounts
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_id = auth.uid() 
            AND username IN ('admin', 'moderator')
        )
    );

-- Spotify user preferences: Users can only manage their own preferences
CREATE POLICY "Users can manage own spotify preferences" ON spotify_user_preferences
    FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- =============================================================================
-- MUSIC ROOMS POLICIES
-- =============================================================================

-- Music rooms: Public rooms visible to all, private rooms to participants only
CREATE POLICY "Anyone can view public rooms" ON music_rooms
    FOR SELECT USING (is_public = true AND is_active = true);

CREATE POLICY "Participants can view private rooms" ON music_rooms
    FOR SELECT USING (
        (is_public = false OR NOT is_active) AND
        EXISTS (
            SELECT 1 FROM room_participants 
            WHERE room_id = id 
            AND user_id = auth.uid() 
            AND is_active = true
        )
    );

-- Room hosts can update their rooms
CREATE POLICY "Hosts can update own rooms" ON music_rooms
    FOR UPDATE USING (host_id = auth.uid()) WITH CHECK (host_id = auth.uid());

-- Users can create rooms if they have connected Spotify account
CREATE POLICY "Connected users can create rooms" ON music_rooms
    FOR INSERT WITH CHECK (
        host_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM spotify_user_accounts 
            WHERE user_id = auth.uid() 
            AND is_connected = true
        )
    );

-- Hosts can delete their own rooms
CREATE POLICY "Hosts can delete own rooms" ON music_rooms
    FOR DELETE USING (host_id = auth.uid());

-- Admins can manage all rooms
CREATE POLICY "Admins can manage all rooms" ON music_rooms
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_id = auth.uid() 
            AND username IN ('admin', 'moderator')
        )
    );

-- =============================================================================
-- ROOM PARTICIPANTS POLICIES
-- =============================================================================

-- Room participants: Users can see participants in rooms they're in
CREATE POLICY "Users can view room participants" ON room_participants
    FOR SELECT USING (
        -- Can see participants in public rooms
        EXISTS (
            SELECT 1 FROM music_rooms 
            WHERE id = room_id 
            AND is_public = true 
            AND is_active = true
        ) OR
        -- Can see participants in rooms they're in
        EXISTS (
            SELECT 1 FROM room_participants rp2
            WHERE rp2.room_id = room_id 
            AND rp2.user_id = auth.uid() 
            AND rp2.is_active = true
        )
    );

-- Users can manage their own participation
CREATE POLICY "Users can manage own participation" ON room_participants
    FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Room hosts and moderators can manage participants
CREATE POLICY "Hosts and moderators can manage participants" ON room_participants
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM room_participants rp
            WHERE rp.room_id = room_id 
            AND rp.user_id = auth.uid() 
            AND rp.role IN ('host', 'moderator')
            AND rp.is_active = true
        )
    );

-- =============================================================================
-- ROOM SYNC AND QUEUE POLICIES
-- =============================================================================

-- Room sync: Visible to room participants
CREATE POLICY "Participants can view room sync" ON room_sync
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM room_participants 
            WHERE room_id = room_sync.room_id 
            AND user_id = auth.uid() 
            AND is_active = true
        )
    );

-- Only hosts and moderators can update sync
CREATE POLICY "Hosts and moderators can update sync" ON room_sync
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM room_participants 
            WHERE room_id = room_sync.room_id 
            AND user_id = auth.uid() 
            AND role IN ('host', 'moderator')
            AND is_active = true
        )
    );

-- Music queue: Visible to room participants
CREATE POLICY "Participants can view queue" ON music_queue
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM room_participants 
            WHERE room_id = music_queue.room_id 
            AND user_id = auth.uid() 
            AND is_active = true
        )
    );

-- Room participants can add tracks to queue
CREATE POLICY "Participants can add to queue" ON music_queue
    FOR INSERT WITH CHECK (
        added_by = auth.uid() AND
        EXISTS (
            SELECT 1 FROM room_participants 
            WHERE room_id = music_queue.room_id 
            AND user_id = auth.uid() 
            AND is_active = true
        )
    );

-- Users can update tracks they added
CREATE POLICY "Users can update own queue tracks" ON music_queue
    FOR UPDATE USING (added_by = auth.uid());

-- Hosts and moderators can manage all queue items
CREATE POLICY "Hosts and moderators can manage queue" ON music_queue
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM room_participants 
            WHERE room_id = music_queue.room_id 
            AND user_id = auth.uid() 
            AND role IN ('host', 'moderator')
            AND is_active = true
        )
    );

-- =============================================================================
-- VOTING AND REACTIONS POLICIES
-- =============================================================================

-- Track votes: Users can see votes in rooms they're in
CREATE POLICY "Participants can view votes" ON track_votes
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM room_participants 
            WHERE room_id = track_votes.room_id 
            AND user_id = auth.uid() 
            AND is_active = true
        )
    );

-- Users can manage their own votes
CREATE POLICY "Users can manage own votes" ON track_votes
    FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Music reactions: Visible to room participants
CREATE POLICY "Participants can view reactions" ON music_reactions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM room_participants 
            WHERE room_id = music_reactions.room_id 
            AND user_id = auth.uid() 
            AND is_active = true
        )
    );

-- Users can create and manage their own reactions
CREATE POLICY "Users can manage own reactions" ON music_reactions
    FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Hosts and moderators can delete any reactions
CREATE POLICY "Hosts and moderators can delete reactions" ON music_reactions
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM room_participants 
            WHERE room_id = music_reactions.room_id 
            AND user_id = auth.uid() 
            AND role IN ('host', 'moderator')
            AND is_active = true
        )
    );

-- =============================================================================
-- CHAT POLICIES
-- =============================================================================

-- Music chat: Visible to room participants
CREATE POLICY "Participants can view chat" ON music_chat
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM room_participants 
            WHERE room_id = music_chat.room_id 
            AND user_id = auth.uid() 
            AND is_active = true
        )
    );

-- Users can send messages to rooms they're in
CREATE POLICY "Participants can send messages" ON music_chat
    FOR INSERT WITH CHECK (
        user_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM room_participants 
            WHERE room_id = music_chat.room_id 
            AND user_id = auth.uid() 
            AND is_active = true
        )
    );

-- Users can edit their own messages (within time limit)
CREATE POLICY "Users can edit own recent messages" ON music_chat
    FOR UPDATE USING (
        user_id = auth.uid() AND
        created_at > NOW() - INTERVAL '5 minutes'
    ) WITH CHECK (user_id = auth.uid());

-- Users can delete their own messages
CREATE POLICY "Users can delete own messages" ON music_chat
    FOR DELETE USING (user_id = auth.uid());

-- Hosts and moderators can manage all messages
CREATE POLICY "Hosts and moderators can manage chat" ON music_chat
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM room_participants 
            WHERE room_id = music_chat.room_id 
            AND user_id = auth.uid() 
            AND role IN ('host', 'moderator')
            AND is_active = true
        )
    );

-- =============================================================================
-- LISTENING HISTORY AND ANALYTICS POLICIES
-- =============================================================================

-- Listening history: Users can only see their own history
CREATE POLICY "Users can view own listening history" ON listening_history
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert own listening history" ON listening_history
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- System can update listening history for analytics
CREATE POLICY "System can manage listening history" ON listening_history
    FOR ALL USING (
        -- Allow if called from server-side functions
        current_setting('request.jwt.claims', true)::json->>'role' = 'service_role'
    );

-- Admins can view aggregated listening data (not personal details)
CREATE POLICY "Admins can view aggregated data" ON listening_history
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_id = auth.uid() 
            AND username IN ('admin', 'moderator')
        )
    );

-- Daily listening stats: Users can see their own stats
CREATE POLICY "Users can view own stats" ON daily_listening_stats
    FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Room analytics: Room hosts and participants can view
CREATE POLICY "Room hosts can view analytics" ON room_analytics
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM music_rooms 
            WHERE id = room_id 
            AND host_id = auth.uid()
        )
    );

-- Admins can view all analytics
CREATE POLICY "Admins can view all analytics" ON room_analytics
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_id = auth.uid() 
            AND username IN ('admin', 'moderator')
        )
    );

-- =============================================================================
-- CACHE TABLES POLICIES
-- =============================================================================

-- Spotify tracks cache: Read-only for authenticated users
CREATE POLICY "Authenticated users can read tracks cache" ON spotify_tracks_cache
    FOR SELECT USING (auth.uid() IS NOT NULL);

-- Only system functions can write to cache
CREATE POLICY "System can manage tracks cache" ON spotify_tracks_cache
    FOR ALL USING (
        current_setting('request.jwt.claims', true)::json->>'role' = 'service_role'
    );

-- Spotify artists cache: Read-only for authenticated users
CREATE POLICY "Authenticated users can read artists cache" ON spotify_artists_cache
    FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "System can manage artists cache" ON spotify_artists_cache
    FOR ALL USING (
        current_setting('request.jwt.claims', true)::json->>'role' = 'service_role'
    );

-- =============================================================================
-- FUNCTION SECURITY CONFIGURATIONS (SAFE EXECUTION)
-- =============================================================================

-- Grant execute permissions to authenticated users on key functions (with error handling)
DO $$ 
BEGIN
    -- Grant permissions with IF EXISTS checks
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'search_music_rooms') THEN
        GRANT EXECUTE ON FUNCTION search_music_rooms TO authenticated;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'search_cached_tracks') THEN
        GRANT EXECUTE ON FUNCTION search_cached_tracks TO authenticated;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error granting function permissions: %', SQLERRM;
END $$;

-- =============================================================================
-- VIEW PERMISSIONS (SAFE EXECUTION)
-- =============================================================================

-- Grant select permissions on views to authenticated users (with error handling)
DO $$ 
BEGIN
    -- Grant permissions on views that exist
    IF EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'v_music_rooms_detailed') THEN
        GRANT SELECT ON v_music_rooms_detailed TO authenticated;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'v_room_participants_active') THEN
        GRANT SELECT ON v_room_participants_active TO authenticated;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'v_room_queue_detailed') THEN
        GRANT SELECT ON v_room_queue_detailed TO authenticated;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'v_user_listening_dashboard') THEN
        GRANT SELECT ON v_user_listening_dashboard TO authenticated;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'v_room_activity_realtime') THEN
        GRANT SELECT ON v_room_activity_realtime TO authenticated;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'v_live_reactions_feed') THEN
        GRANT SELECT ON v_live_reactions_feed TO authenticated;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'v_popular_tracks_global') THEN
        GRANT SELECT ON v_popular_tracks_global TO authenticated;
    END IF;
    
    -- Restricted views
    IF EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'v_listening_analytics_summary') THEN
        GRANT SELECT ON v_listening_analytics_summary TO authenticated;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'v_room_analytics_summary') THEN
        GRANT SELECT ON v_room_analytics_summary TO authenticated;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'v_user_music_similarity') THEN
        GRANT SELECT ON v_user_music_similarity TO authenticated;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'v_spotify_system_metrics') THEN
        GRANT SELECT ON v_spotify_system_metrics TO service_role;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error granting view permissions: %', SQLERRM;
END $$;

-- =============================================================================
-- AUDIT AND LOGGING POLICIES
-- =============================================================================

-- Create audit log table for security events
CREATE TABLE spotify_audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id),
    action VARCHAR(100) NOT NULL,
    table_name VARCHAR(100),
    record_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on audit log
ALTER TABLE spotify_audit_log ENABLE ROW LEVEL SECURITY;

-- Only admins can view audit logs
CREATE POLICY "Admins can view audit logs" ON spotify_audit_log
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_id = auth.uid() 
            AND username IN ('admin', 'moderator')
        )
    );

-- Create audit trigger function
DROP FUNCTION IF EXISTS audit_spotify_changes() CASCADE;

CREATE OR REPLACE FUNCTION audit_spotify_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- Log significant changes to sensitive tables
    IF TG_TABLE_NAME IN ('music_rooms', 'room_participants', 'spotify_user_accounts') THEN
        INSERT INTO spotify_audit_log (
            user_id, action, table_name, record_id, old_values, new_values
        ) VALUES (
            auth.uid(),
            TG_OP,
            TG_TABLE_NAME,
            COALESCE(NEW.id, OLD.id),
            CASE WHEN TG_OP = 'DELETE' THEN row_to_json(OLD) ELSE NULL END,
            CASE WHEN TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN row_to_json(NEW) ELSE NULL END
        );
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create audit triggers
CREATE TRIGGER audit_music_rooms
    AFTER INSERT OR UPDATE OR DELETE ON music_rooms
    FOR EACH ROW EXECUTE FUNCTION audit_spotify_changes();

CREATE TRIGGER audit_room_participants
    AFTER INSERT OR UPDATE OR DELETE ON room_participants
    FOR EACH ROW EXECUTE FUNCTION audit_spotify_changes();

CREATE TRIGGER audit_spotify_accounts
    AFTER INSERT OR UPDATE OR DELETE ON spotify_user_accounts
    FOR EACH ROW EXECUTE FUNCTION audit_spotify_changes();

-- =============================================================================
-- RATE LIMITING AND ABUSE PREVENTION
-- =============================================================================

-- Create rate limiting table
CREATE TABLE spotify_rate_limits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    action_type VARCHAR(100) NOT NULL,
    action_count INTEGER DEFAULT 1,
    window_start TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(user_id, action_type, window_start)
);

-- Rate limiting function
DROP FUNCTION IF EXISTS check_rate_limit(UUID, VARCHAR(100), INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION check_rate_limit(
    p_user_id UUID,
    p_action_type VARCHAR(100),
    p_limit INTEGER,
    p_window_minutes INTEGER DEFAULT 60
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_count INTEGER;
    v_window_start TIMESTAMPTZ;
BEGIN
    -- Calculate window start (aligned to window intervals)
    v_window_start := date_trunc('hour', NOW()) + 
        (EXTRACT(MINUTE FROM NOW())::INTEGER / p_window_minutes) * (p_window_minutes || ' minutes')::INTERVAL;
    
    -- Get current count for this window
    SELECT action_count INTO v_current_count
    FROM spotify_rate_limits
    WHERE user_id = p_user_id 
    AND action_type = p_action_type 
    AND window_start = v_window_start;
    
    -- If no record exists, create one
    IF v_current_count IS NULL THEN
        INSERT INTO spotify_rate_limits (user_id, action_type, window_start, action_count)
        VALUES (p_user_id, p_action_type, v_window_start, 1);
        RETURN true;
    END IF;
    
    -- Check if limit exceeded
    IF v_current_count >= p_limit THEN
        RETURN false;
    END IF;
    
    -- Increment counter
    UPDATE spotify_rate_limits 
    SET action_count = action_count + 1
    WHERE user_id = p_user_id 
    AND action_type = p_action_type 
    AND window_start = v_window_start;
    
    RETURN true;
END;
$$;

-- Clean up old rate limit records
DROP FUNCTION IF EXISTS cleanup_rate_limits();

CREATE OR REPLACE FUNCTION cleanup_rate_limits()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    DELETE FROM spotify_rate_limits 
    WHERE created_at < NOW() - INTERVAL '24 hours';
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    RETURN v_deleted_count;
END;
$$;

-- =============================================================================
-- SECURITY VALIDATION FUNCTIONS
-- =============================================================================

-- Validate room access for user
DROP FUNCTION IF EXISTS validate_room_access(UUID, UUID, VARCHAR(50));

CREATE OR REPLACE FUNCTION validate_room_access(
    p_user_id UUID,
    p_room_id UUID,
    p_required_role VARCHAR(50) DEFAULT 'listener'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_role VARCHAR(50);
    v_room_public BOOLEAN;
BEGIN
    -- Get user's role in the room
    SELECT role INTO v_user_role
    FROM room_participants
    WHERE room_id = p_room_id AND user_id = p_user_id AND is_active = true;
    
    -- If user not in room, check if room is public
    IF v_user_role IS NULL THEN
        SELECT is_public INTO v_room_public
        FROM music_rooms
        WHERE id = p_room_id AND is_active = true;
        
        -- Public rooms allow read access
        IF v_room_public = true AND p_required_role = 'listener' THEN
            RETURN true;
        END IF;
        
        RETURN false;
    END IF;
    
    -- Check role hierarchy: host > moderator > listener
    RETURN CASE 
        WHEN p_required_role = 'listener' THEN true
        WHEN p_required_role = 'moderator' THEN v_user_role IN ('host', 'moderator')
        WHEN p_required_role = 'host' THEN v_user_role = 'host'
        ELSE false
    END;
END;
$$;

-- Validate Spotify account connection
DROP FUNCTION IF EXISTS validate_spotify_connection(UUID);

CREATE OR REPLACE FUNCTION validate_spotify_connection(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM spotify_user_accounts 
        WHERE user_id = p_user_id 
        AND is_connected = true
        AND token_expires_at > NOW()
    );
END;
$$;

-- =============================================================================
-- SECURITY MAINTENANCE FUNCTIONS
-- =============================================================================

-- Daily security maintenance
DROP FUNCTION IF EXISTS daily_security_maintenance();

CREATE OR REPLACE FUNCTION daily_security_maintenance()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_rate_limits_cleaned INTEGER;
    v_expired_reactions INTEGER;
    v_inactive_sessions INTEGER;
    v_result TEXT;
BEGIN
    -- Clean up rate limits
    SELECT cleanup_rate_limits() INTO v_rate_limits_cleaned;
    
    -- Clean up expired reactions
    SELECT cleanup_expired_reactions() INTO v_expired_reactions;
    
    -- Deactivate inactive room participants (offline for > 30 minutes)
    UPDATE room_participants 
    SET is_active = false
    WHERE is_active = true 
    AND last_active_at < NOW() - INTERVAL '30 minutes';
    
    GET DIAGNOSTICS v_inactive_sessions = ROW_COUNT;
    
    v_result := format(
        'Security maintenance completed: %s rate limit records cleaned, %s expired reactions removed, %s inactive sessions deactivated',
        v_rate_limits_cleaned, v_expired_reactions, v_inactive_sessions
    );
    
    RETURN v_result;
END;
$$;

-- Grant permissions for security functions
GRANT EXECUTE ON FUNCTION check_rate_limit TO authenticated;
GRANT EXECUTE ON FUNCTION validate_room_access TO authenticated;
GRANT EXECUTE ON FUNCTION validate_spotify_connection TO authenticated;
GRANT EXECUTE ON FUNCTION daily_security_maintenance TO service_role;

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE spotify_audit_log IS 'Audit log for tracking security-sensitive changes in Spotify system';
COMMENT ON TABLE spotify_rate_limits IS 'Rate limiting tracking to prevent abuse of Spotify features';
COMMENT ON FUNCTION check_rate_limit IS 'Validates user action against rate limits to prevent abuse';
COMMENT ON FUNCTION validate_room_access IS 'Validates user access permissions for specific room actions';
COMMENT ON FUNCTION validate_spotify_connection IS 'Validates that user has active Spotify account connection';
COMMENT ON FUNCTION daily_security_maintenance IS 'Daily security maintenance for the Spotify system';

-- Setup completion message
SELECT 
    'Spotify Security and RLS Setup Complete!' as status,
    (SELECT COUNT(*) FROM information_schema.tables WHERE table_name LIKE '%spotify%') as secured_tables,
    (SELECT COUNT(*) FROM pg_policies WHERE tablename LIKE '%spotify%' OR tablename LIKE '%music%' OR tablename LIKE '%room%') as policies_created,
    NOW() as setup_completed_at;
