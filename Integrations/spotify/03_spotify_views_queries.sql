-- Crystal Social Spotify System - Views and Queries
-- File: 03_spotify_views_queries.sql
-- Purpose: Database views and optimized queries for the Spotify music social platform

-- =============================================================================
-- ROOM AND PARTICIPANT VIEWS
-- =============================================================================

-- Comprehensive room information with current state
CREATE OR REPLACE VIEW v_music_rooms_detailed AS
SELECT 
    mr.id,
    mr.name,
    mr.description,
    mr.host_id,
    host_profile.username as host_username,
    host_profile.display_name as host_display_name,
    mr.is_public,
    mr.is_active,
    mr.max_participants,
    mr.listener_count,
    mr.mood,
    mr.theme_color,
    mr.background_type,
    
    -- Current track information
    mr.current_track_uri,
    mr.current_track_name,
    mr.current_artist_name,
    mr.current_track_image_url,
    mr.current_position_ms,
    mr.is_playing,
    
    -- Activity metrics
    mr.total_tracks_played,
    mr.total_listen_time_minutes,
    mr.peak_listener_count,
    
    -- Queue information
    queue_stats.total_queued,
    queue_stats.next_track_name,
    queue_stats.next_artist_name,
    
    -- Sync information
    rs.sequence_number as current_sync_sequence,
    rs.timestamp as last_sync_timestamp,
    
    -- Timestamps
    mr.created_at,
    mr.updated_at,
    mr.last_activity_at,
    
    -- Computed fields
    EXTRACT(EPOCH FROM (NOW() - mr.last_activity_at)) / 60 as minutes_since_activity,
    CASE 
        WHEN mr.last_activity_at > NOW() - INTERVAL '5 minutes' THEN 'active'
        WHEN mr.last_activity_at > NOW() - INTERVAL '30 minutes' THEN 'recent'
        ELSE 'inactive'
    END as activity_status,
    
    -- Host Spotify connection status
    spotify_acc.is_connected as host_spotify_connected,
    spotify_acc.is_premium as host_is_premium

FROM music_rooms mr
LEFT JOIN auth.users host_user ON host_user.id = mr.host_id
LEFT JOIN user_profiles host_profile ON host_profile.user_id = mr.host_id
LEFT JOIN spotify_user_accounts spotify_acc ON spotify_acc.user_id = mr.host_id
LEFT JOIN room_sync rs ON rs.room_id = mr.id
LEFT JOIN (
    SELECT 
        room_id,
        COUNT(*) as total_queued,
        MIN(CASE WHEN queue_position = (SELECT MIN(queue_position) FROM music_queue mq2 WHERE mq2.room_id = mq.room_id AND NOT is_played AND NOT is_skipped) THEN track_name END) as next_track_name,
        MIN(CASE WHEN queue_position = (SELECT MIN(queue_position) FROM music_queue mq2 WHERE mq2.room_id = mq.room_id AND NOT is_played AND NOT is_skipped) THEN artist_name END) as next_artist_name
    FROM music_queue mq
    WHERE NOT is_played AND NOT is_skipped
    GROUP BY room_id
) queue_stats ON queue_stats.room_id = mr.id;

-- Active room participants with user details
CREATE OR REPLACE VIEW v_room_participants_active AS
SELECT 
    rp.id,
    rp.room_id,
    rp.user_id,
    rp.role,
    rp.is_active,
    rp.joined_at,
    rp.last_active_at,
    
    -- User profile information
    up.username,
    up.display_name,
    up.avatar_url,
    
    -- Spotify account information
    spa.spotify_username,
    spa.display_name as spotify_display_name,
    spa.is_premium as spotify_premium,
    spa.profile_image_url as spotify_avatar,
    
    -- Participation statistics
    rp.tracks_added,
    rp.reactions_sent,
    rp.votes_cast,
    rp.messages_sent,
    
    -- Session information
    EXTRACT(EPOCH FROM (NOW() - rp.joined_at)) / 60 as session_minutes,
    CASE 
        WHEN rp.last_active_at > NOW() - INTERVAL '2 minutes' THEN 'online'
        WHEN rp.last_active_at > NOW() - INTERVAL '10 minutes' THEN 'away'
        ELSE 'offline'
    END as presence_status,
    
    -- Room context
    mr.name as room_name,
    mr.mood as room_mood

FROM room_participants rp
JOIN music_rooms mr ON mr.id = rp.room_id
LEFT JOIN user_profiles up ON up.user_id = rp.user_id
LEFT JOIN spotify_user_accounts spa ON spa.user_id = rp.user_id
WHERE rp.is_active = true;

-- Room queue with voting information
CREATE OR REPLACE VIEW v_room_queue_detailed AS
SELECT 
    mq.id,
    mq.room_id,
    mq.track_uri,
    mq.track_name,
    mq.artist_name,
    mq.album_name,
    mq.track_image_url,
    mq.duration_ms,
    mq.queue_position,
    mq.added_by,
    mq.is_played,
    mq.is_skipped,
    mq.added_at,
    mq.played_at,
    mq.estimated_play_time,
    
    -- Vote information
    mq.upvotes,
    mq.downvotes,
    mq.vote_score,
    
    -- User who added the track
    up.username as added_by_username,
    up.display_name as added_by_display_name,
    up.avatar_url as added_by_avatar,
    
    -- Spotify track cache information
    stc.popularity as spotify_popularity,
    stc.explicit_content,
    stc.audio_features,
    
    -- Computed fields
    ROUND(mq.duration_ms / 1000.0 / 60, 2) as duration_minutes,
    CASE 
        WHEN mq.is_played THEN 'played'
        WHEN mq.is_skipped THEN 'skipped'
        WHEN mq.queue_position = 1 THEN 'current'
        ELSE 'queued'
    END as status,
    
    -- Time until track plays (estimated)
    CASE 
        WHEN mq.queue_position = 1 AND NOT mq.is_played THEN '0 minutes'
        WHEN mq.queue_position > 1 THEN 
            ROUND(
                (SELECT SUM(duration_ms) FROM music_queue mq2 
                 WHERE mq2.room_id = mq.room_id 
                 AND mq2.queue_position < mq.queue_position 
                 AND NOT mq2.is_played AND NOT mq2.is_skipped) / 1000.0 / 60, 1
            ) || ' minutes'
        ELSE 'N/A'
    END as estimated_wait_time

FROM music_queue mq
LEFT JOIN user_profiles up ON up.user_id = mq.added_by
LEFT JOIN spotify_tracks_cache stc ON stc.track_uri = mq.track_uri
ORDER BY mq.room_id, mq.queue_position;

-- =============================================================================
-- LISTENING ANALYTICS VIEWS
-- =============================================================================

-- User listening dashboard
CREATE OR REPLACE VIEW v_user_listening_dashboard AS
SELECT 
    u.id as user_id,
    up.username,
    up.display_name,
    
    -- Spotify account info
    spa.spotify_username,
    spa.is_premium,
    spa.is_connected as spotify_connected,
    
    -- Today's stats
    today_stats.tracks_today,
    today_stats.minutes_today,
    today_stats.rooms_joined_today,
    
    -- This week's stats
    week_stats.tracks_this_week,
    week_stats.minutes_this_week,
    week_stats.unique_artists_week,
    
    -- This month's stats
    month_stats.tracks_this_month,
    month_stats.minutes_this_month,
    month_stats.unique_artists_month,
    
    -- All-time stats
    alltime_stats.total_tracks_alltime,
    alltime_stats.total_minutes_alltime,
    alltime_stats.unique_artists_alltime,
    
    -- Recent activity
    recent_activity.last_track_name,
    recent_activity.last_artist_name,
    recent_activity.last_listened_at,
    recent_activity.last_room_name,
    
    -- Preferences
    prefs.current_mood,
    prefs.preferred_genres,
    prefs.visualizer_enabled

FROM auth.users u
LEFT JOIN user_profiles up ON up.user_id = u.id
LEFT JOIN spotify_user_accounts spa ON spa.user_id = u.id
LEFT JOIN spotify_user_preferences prefs ON prefs.user_id = u.id

-- Today's listening stats
LEFT JOIN (
    SELECT 
        user_id,
        total_tracks as tracks_today,
        total_listen_time_minutes as minutes_today,
        rooms_joined as rooms_joined_today
    FROM daily_listening_stats 
    WHERE listen_date = CURRENT_DATE
) today_stats ON today_stats.user_id = u.id

-- This week's stats
LEFT JOIN (
    SELECT 
        user_id,
        SUM(total_tracks) as tracks_this_week,
        SUM(total_listen_time_minutes) as minutes_this_week,
        COUNT(DISTINCT unique_artists) as unique_artists_week
    FROM daily_listening_stats 
    WHERE listen_date >= CURRENT_DATE - INTERVAL '7 days'
    GROUP BY user_id
) week_stats ON week_stats.user_id = u.id

-- This month's stats
LEFT JOIN (
    SELECT 
        user_id,
        SUM(total_tracks) as tracks_this_month,
        SUM(total_listen_time_minutes) as minutes_this_month,
        COUNT(DISTINCT unique_artists) as unique_artists_month
    FROM daily_listening_stats 
    WHERE listen_date >= DATE_TRUNC('month', CURRENT_DATE)
    GROUP BY user_id
) month_stats ON month_stats.user_id = u.id

-- All-time stats
LEFT JOIN (
    SELECT 
        user_id,
        COUNT(*) as total_tracks_alltime,
        SUM(played_duration_ms) / 60000 as total_minutes_alltime,
        COUNT(DISTINCT artist_name) as unique_artists_alltime
    FROM listening_history
    GROUP BY user_id
) alltime_stats ON alltime_stats.user_id = u.id

-- Recent activity
LEFT JOIN (
    SELECT DISTINCT ON (user_id)
        user_id,
        track_name as last_track_name,
        artist_name as last_artist_name,
        started_at as last_listened_at,
        (SELECT name FROM music_rooms WHERE id = lh.room_id) as last_room_name
    FROM listening_history lh
    ORDER BY user_id, started_at DESC
) recent_activity ON recent_activity.user_id = u.id

WHERE spa.id IS NOT NULL; -- Only users with Spotify accounts

-- Top tracks and artists analytics
CREATE OR REPLACE VIEW v_listening_analytics_summary AS
SELECT 
    'tracks' as category,
    track_name as name,
    artist_name as secondary_info,
    COUNT(*) as play_count,
    SUM(played_duration_ms) / 60000 as total_minutes,
    ROUND(AVG(completion_percentage), 2) as avg_completion_rate,
    COUNT(DISTINCT user_id) as unique_listeners,
    
    -- Time-based metrics
    COUNT(*) FILTER (WHERE started_at >= CURRENT_DATE - INTERVAL '7 days') as plays_this_week,
    COUNT(*) FILTER (WHERE started_at >= CURRENT_DATE - INTERVAL '30 days') as plays_this_month,
    
    MAX(started_at) as last_played_at
    
FROM listening_history
WHERE started_at >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY track_name, artist_name

UNION ALL

SELECT 
    'artists' as category,
    artist_name as name,
    COUNT(DISTINCT track_name)::TEXT as secondary_info,
    COUNT(*) as play_count,
    SUM(played_duration_ms) / 60000 as total_minutes,
    ROUND(AVG(completion_percentage), 2) as avg_completion_rate,
    COUNT(DISTINCT user_id) as unique_listeners,
    
    COUNT(*) FILTER (WHERE started_at >= CURRENT_DATE - INTERVAL '7 days') as plays_this_week,
    COUNT(*) FILTER (WHERE started_at >= CURRENT_DATE - INTERVAL '30 days') as plays_this_month,
    
    MAX(started_at) as last_played_at
    
FROM listening_history
WHERE started_at >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY artist_name

ORDER BY play_count DESC;

-- Room performance analytics
CREATE OR REPLACE VIEW v_room_analytics_summary AS
SELECT 
    mr.id as room_id,
    mr.name as room_name,
    mr.host_id,
    up.username as host_username,
    mr.mood,
    mr.created_at,
    
    -- Current metrics
    mr.listener_count as current_listeners,
    mr.total_tracks_played,
    mr.total_listen_time_minutes,
    mr.peak_listener_count,
    
    -- Recent analytics (last 7 days)
    recent_analytics.avg_daily_participants,
    recent_analytics.avg_daily_tracks,
    recent_analytics.avg_session_minutes,
    recent_analytics.total_reactions_week,
    
    -- Growth metrics
    CASE 
        WHEN mr.created_at >= CURRENT_DATE - INTERVAL '7 days' THEN 'new'
        WHEN mr.last_activity_at >= CURRENT_DATE - INTERVAL '24 hours' THEN 'active'
        WHEN mr.last_activity_at >= CURRENT_DATE - INTERVAL '7 days' THEN 'moderate'
        ELSE 'inactive'
    END as activity_level,
    
    -- Engagement score (0-100)
    LEAST(100, GREATEST(0, 
        (COALESCE(recent_analytics.avg_daily_participants, 0) * 10) +
        (COALESCE(recent_analytics.avg_session_minutes, 0) / 2) +
        (COALESCE(recent_analytics.total_reactions_week, 0) / 10)
    ))::INTEGER as engagement_score

FROM music_rooms mr
LEFT JOIN user_profiles up ON up.user_id = mr.host_id
LEFT JOIN (
    SELECT 
        room_id,
        AVG(unique_participants) as avg_daily_participants,
        AVG(tracks_played) as avg_daily_tracks,
        AVG(average_session_minutes) as avg_session_minutes,
        SUM(total_reactions) as total_reactions_week
    FROM room_analytics 
    WHERE analytics_date >= CURRENT_DATE - INTERVAL '7 days'
    GROUP BY room_id
) recent_analytics ON recent_analytics.room_id = mr.id

WHERE mr.is_active = true
ORDER BY engagement_score DESC, mr.listener_count DESC;

-- =============================================================================
-- REAL-TIME ACTIVITY VIEWS
-- =============================================================================

-- Current room activity for real-time updates
CREATE OR REPLACE VIEW v_room_activity_realtime AS
SELECT 
    mr.id as room_id,
    mr.name as room_name,
    mr.listener_count,
    mr.is_playing,
    mr.current_track_name,
    mr.current_artist_name,
    mr.current_track_image_url,
    mr.current_position_ms,
    mr.last_sync_at,
    
    -- Recent reactions (last 30 seconds)
    recent_reactions.reaction_count,
    recent_reactions.latest_reactions,
    
    -- Queue info
    queue_info.next_tracks,
    queue_info.queue_length,
    
    -- Active participants
    active_participants.participant_list,
    
    -- Room sync sequence
    rs.sequence_number,
    rs.timestamp as last_sync_timestamp

FROM music_rooms mr
LEFT JOIN room_sync rs ON rs.room_id = mr.id

-- Recent reactions aggregation
LEFT JOIN (
    SELECT 
        room_id,
        COUNT(*) as reaction_count,
        JSON_AGG(
            JSON_BUILD_OBJECT(
                'reaction', reaction,
                'user_id', user_id,
                'created_at', created_at
            ) ORDER BY created_at DESC
        ) FILTER (WHERE created_at >= NOW() - INTERVAL '30 seconds') as latest_reactions
    FROM music_reactions 
    WHERE is_visible = true 
    AND created_at >= NOW() - INTERVAL '30 seconds'
    GROUP BY room_id
) recent_reactions ON recent_reactions.room_id = mr.id

-- Queue information
LEFT JOIN (
    SELECT 
        room_id,
        COUNT(*) as queue_length,
        JSON_AGG(
            JSON_BUILD_OBJECT(
                'track_name', track_name,
                'artist_name', artist_name,
                'queue_position', queue_position,
                'vote_score', vote_score
            ) ORDER BY queue_position
        ) FILTER (WHERE NOT is_played AND NOT is_skipped) as next_tracks
    FROM music_queue 
    WHERE NOT is_played AND NOT is_skipped
    GROUP BY room_id
) queue_info ON queue_info.room_id = mr.id

-- Active participants list
LEFT JOIN (
    SELECT 
        room_id,
        JSON_AGG(
            JSON_BUILD_OBJECT(
                'user_id', rp.user_id,
                'username', up.username,
                'role', rp.role,
                'last_active', rp.last_active_at
            ) ORDER BY rp.role, rp.joined_at
        ) as participant_list
    FROM room_participants rp
    LEFT JOIN user_profiles up ON up.user_id = rp.user_id
    WHERE is_active = true
    GROUP BY room_id
) active_participants ON active_participants.room_id = mr.id

WHERE mr.is_active = true;

-- Live reactions feed
CREATE OR REPLACE VIEW v_live_reactions_feed AS
SELECT 
    mr_react.id,
    mr_react.room_id,
    mr_react.user_id,
    mr_react.reaction,
    mr_react.track_uri,
    mr_react.track_position_ms,
    mr_react.created_at,
    mr_react.expires_at,
    mr_react.animation_type,
    mr_react.start_position,
    
    -- User info
    up.username,
    up.display_name,
    up.avatar_url,
    
    -- Room context
    mr.name as room_name,
    mr.current_track_name,
    mr.current_artist_name,
    
    -- Time calculations
    EXTRACT(EPOCH FROM (mr_react.expires_at - NOW())) as seconds_until_expire,
    EXTRACT(EPOCH FROM (NOW() - mr_react.created_at)) as seconds_since_created

FROM music_reactions mr_react
JOIN music_rooms mr ON mr.id = mr_react.room_id
LEFT JOIN user_profiles up ON up.user_id = mr_react.user_id
WHERE mr_react.is_visible = true 
AND mr_react.expires_at > NOW()
ORDER BY mr_react.created_at DESC;

-- =============================================================================
-- DISCOVERY AND RECOMMENDATION VIEWS
-- =============================================================================

-- Popular tracks across all rooms
CREATE OR REPLACE VIEW v_popular_tracks_global AS
SELECT 
    lh.track_uri,
    lh.track_name,
    lh.artist_name,
    lh.album_name,
    COUNT(DISTINCT lh.user_id) as unique_listeners,
    COUNT(*) as total_plays,
    SUM(lh.played_duration_ms) / 60000 as total_minutes,
    ROUND(AVG(lh.completion_percentage), 2) as avg_completion_rate,
    
    -- Recent popularity
    COUNT(*) FILTER (WHERE lh.started_at >= CURRENT_DATE - INTERVAL '7 days') as plays_this_week,
    COUNT(DISTINCT lh.user_id) FILTER (WHERE lh.started_at >= CURRENT_DATE - INTERVAL '7 days') as listeners_this_week,
    
    -- Spotify metrics
    stc.popularity as spotify_popularity,
    stc.explicit_content,
    stc.album_image_url as track_image_url,
    
    -- Calculated popularity score
    (
        (COUNT(DISTINCT lh.user_id) * 10) +
        (COUNT(*) FILTER (WHERE lh.started_at >= CURRENT_DATE - INTERVAL '7 days') * 5) +
        (ROUND(AVG(lh.completion_percentage), 0) * 2) +
        COALESCE(stc.popularity, 0)
    ) as popularity_score

FROM listening_history lh
LEFT JOIN spotify_tracks_cache stc ON stc.track_uri = lh.track_uri
WHERE lh.started_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY 
    lh.track_uri, lh.track_name, lh.artist_name, lh.album_name,
    stc.popularity, stc.explicit_content, stc.album_image_url
HAVING COUNT(*) >= 3 -- Minimum 3 plays to be considered
ORDER BY popularity_score DESC;

-- User music taste similarity
CREATE OR REPLACE VIEW v_user_music_similarity AS
WITH user_artists AS (
    SELECT 
        user_id,
        artist_name,
        COUNT(*) as play_count,
        RANK() OVER (PARTITION BY user_id ORDER BY COUNT(*) DESC) as artist_rank
    FROM listening_history 
    WHERE started_at >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY user_id, artist_name
),
artist_overlap AS (
    SELECT 
        ua1.user_id as user1_id,
        ua2.user_id as user2_id,
        COUNT(*) as shared_artists,
        SUM(LEAST(ua1.play_count, ua2.play_count)) as overlap_score
    FROM user_artists ua1
    JOIN user_artists ua2 ON ua1.artist_name = ua2.artist_name 
        AND ua1.user_id < ua2.user_id
    WHERE ua1.artist_rank <= 20 AND ua2.artist_rank <= 20
    GROUP BY ua1.user_id, ua2.user_id
    HAVING COUNT(*) >= 3
)
SELECT 
    ao.user1_id,
    ao.user2_id,
    up1.username as user1_username,
    up2.username as user2_username,
    ao.shared_artists,
    ao.overlap_score,
    ROUND((ao.overlap_score::DECIMAL / GREATEST(
        (SELECT SUM(play_count) FROM user_artists WHERE user_id = ao.user1_id AND artist_rank <= 20),
        (SELECT SUM(play_count) FROM user_artists WHERE user_id = ao.user2_id AND artist_rank <= 20)
    )) * 100, 2) as similarity_percentage

FROM artist_overlap ao
LEFT JOIN user_profiles up1 ON up1.user_id = ao.user1_id
LEFT JOIN user_profiles up2 ON up2.user_id = ao.user2_id
ORDER BY similarity_percentage DESC;

-- =============================================================================
-- SEARCH AND DISCOVERY QUERIES
-- =============================================================================

-- Music room search function
CREATE OR REPLACE FUNCTION search_music_rooms(
    p_search_query TEXT DEFAULT NULL,
    p_mood_filter VARCHAR(100) DEFAULT NULL,
    p_is_public BOOLEAN DEFAULT NULL,
    p_min_listeners INTEGER DEFAULT 0,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    room_id UUID,
    room_name VARCHAR(255),
    description TEXT,
    host_username VARCHAR(255),
    listener_count INTEGER,
    mood VARCHAR(100),
    theme_color VARCHAR(7),
    current_track_name VARCHAR(500),
    current_artist_name VARCHAR(500),
    activity_status TEXT,
    engagement_score INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        vrd.id,
        vrd.name,
        vrd.description,
        vrd.host_username,
        vrd.listener_count,
        vrd.mood,
        vrd.theme_color,
        vrd.current_track_name,
        vrd.current_artist_name,
        vrd.activity_status,
        (COALESCE(vrd.listener_count, 0) * 10 + 
         CASE WHEN vrd.activity_status = 'active' THEN 50 ELSE 0 END)::INTEGER
    FROM v_music_rooms_detailed vrd
    WHERE vrd.is_active = true
    AND (p_is_public IS NULL OR vrd.is_public = p_is_public)
    AND (p_mood_filter IS NULL OR vrd.mood = p_mood_filter)
    AND (p_search_query IS NULL OR (
        vrd.search_vector @@ plainto_tsquery('english', p_search_query) OR
        vrd.name ILIKE '%' || p_search_query || '%' OR
        vrd.current_track_name ILIKE '%' || p_search_query || '%' OR
        vrd.current_artist_name ILIKE '%' || p_search_query || '%'
    ))
    AND vrd.listener_count >= p_min_listeners
    ORDER BY 
        CASE WHEN p_search_query IS NOT NULL THEN
            ts_rank(vrd.search_vector, plainto_tsquery('english', p_search_query))
        ELSE 0 END DESC,
        vrd.listener_count DESC,
        vrd.last_activity_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- Track search in cache
CREATE OR REPLACE FUNCTION search_cached_tracks(
    p_search_query TEXT,
    p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    track_uri VARCHAR(255),
    track_name VARCHAR(500),
    artist_name VARCHAR(500),
    album_name VARCHAR(500),
    track_image_url TEXT,
    duration_ms INTEGER,
    popularity INTEGER,
    play_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        stc.track_uri,
        stc.name,
        stc.primary_artist_name,
        stc.album_name,
        stc.album_image_url,
        stc.duration_ms,
        stc.popularity,
        COALESCE(lh_stats.play_count, 0)
    FROM spotify_tracks_cache stc
    LEFT JOIN (
        SELECT track_uri, COUNT(*) as play_count
        FROM listening_history 
        WHERE started_at >= CURRENT_DATE - INTERVAL '30 days'
        GROUP BY track_uri
    ) lh_stats ON lh_stats.track_uri = stc.track_uri
    WHERE stc.search_vector @@ plainto_tsquery('english', p_search_query)
    AND stc.cache_expires_at > NOW()
    ORDER BY 
        ts_rank(stc.search_vector, plainto_tsquery('english', p_search_query)) DESC,
        stc.popularity DESC,
        COALESCE(lh_stats.play_count, 0) DESC
    LIMIT p_limit;
END;
$$;

-- =============================================================================
-- PERFORMANCE MONITORING VIEWS
-- =============================================================================

-- System performance metrics
CREATE OR REPLACE VIEW v_spotify_system_metrics AS
SELECT 
    -- Room metrics
    (SELECT COUNT(*) FROM music_rooms WHERE is_active = true) as active_rooms,
    (SELECT COUNT(*) FROM room_participants WHERE is_active = true) as active_participants,
    (SELECT SUM(listener_count) FROM music_rooms WHERE is_active = true) as total_listeners,
    
    -- Queue metrics
    (SELECT COUNT(*) FROM music_queue WHERE NOT is_played AND NOT is_skipped) as total_queued_tracks,
    (SELECT AVG(vote_score) FROM music_queue WHERE NOT is_played AND NOT is_skipped) as avg_vote_score,
    
    -- Activity metrics
    (SELECT COUNT(*) FROM music_reactions WHERE created_at >= NOW() - INTERVAL '1 hour') as reactions_last_hour,
    (SELECT COUNT(*) FROM listening_history WHERE started_at >= NOW() - INTERVAL '1 hour') as tracks_played_last_hour,
    
    -- Cache metrics
    (SELECT COUNT(*) FROM spotify_tracks_cache WHERE cache_expires_at > NOW()) as cached_tracks,
    (SELECT COUNT(*) FROM spotify_artists_cache WHERE cache_expires_at > NOW()) as cached_artists,
    (SELECT AVG(access_count) FROM spotify_tracks_cache WHERE last_accessed_at >= CURRENT_DATE) as avg_cache_hits,
    
    -- User metrics
    (SELECT COUNT(*) FROM spotify_user_accounts WHERE is_connected = true) as connected_users,
    (SELECT COUNT(*) FROM spotify_user_accounts WHERE is_premium = true) as premium_users,
    
    -- Performance indicators
    CASE 
        WHEN (SELECT COUNT(*) FROM room_sync WHERE timestamp >= NOW() - INTERVAL '1 minute') > 0 THEN 'active'
        ELSE 'idle'
    END as sync_status,
    
    NOW() as metrics_timestamp;

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON VIEW v_music_rooms_detailed IS 'Comprehensive room information with current state and activity metrics';
COMMENT ON VIEW v_room_participants_active IS 'Active room participants with user and Spotify account details';
COMMENT ON VIEW v_room_queue_detailed IS 'Room queue with voting information and track details';
COMMENT ON VIEW v_user_listening_dashboard IS 'User listening dashboard with statistics and recent activity';
COMMENT ON VIEW v_listening_analytics_summary IS 'Top tracks and artists analytics across the platform';
COMMENT ON VIEW v_room_analytics_summary IS 'Room performance analytics with engagement scoring';
COMMENT ON VIEW v_room_activity_realtime IS 'Real-time room activity for live updates';
COMMENT ON VIEW v_live_reactions_feed IS 'Live emoji reactions feed for real-time display';
COMMENT ON VIEW v_popular_tracks_global IS 'Popular tracks across all rooms with popularity scoring';
COMMENT ON FUNCTION search_music_rooms IS 'Advanced search function for discovering music rooms';
COMMENT ON FUNCTION search_cached_tracks IS 'Search function for cached Spotify tracks';
COMMENT ON VIEW v_spotify_system_metrics IS 'System-wide performance and activity metrics';

-- Setup completion message
SELECT 'Spotify Views and Queries Setup Complete!' as status, NOW() as setup_completed_at;
