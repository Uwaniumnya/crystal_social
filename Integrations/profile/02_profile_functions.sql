-- =====================================================
-- CRYSTAL SOCIAL - PROFILE SYSTEM FUNCTIONS
-- =====================================================
-- Business logic functions for profile management
-- =====================================================

-- =====================================================
-- PROFILE MANAGEMENT FUNCTIONS
-- =====================================================

-- Create or update user profile
CREATE OR REPLACE FUNCTION create_or_update_user_profile(
    p_user_id UUID,
    p_username VARCHAR(50),
    p_display_name VARCHAR(100) DEFAULT NULL,
    p_bio TEXT DEFAULT NULL,
    p_avatar_url TEXT DEFAULT NULL,
    p_location VARCHAR(100) DEFAULT NULL,
    p_website VARCHAR(255) DEFAULT NULL,
    p_zodiac_sign VARCHAR(20) DEFAULT NULL,
    p_interests TEXT[] DEFAULT NULL,
    p_social_links JSONB DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_profile_id UUID;
    v_result JSON;
BEGIN
    -- Insert or update profile
    INSERT INTO user_profiles (
        user_id, username, display_name, bio, avatar_url,
        location, website, zodiac_sign, interests, social_links,
        updated_at
    ) VALUES (
        p_user_id, p_username, p_display_name, p_bio, p_avatar_url,
        p_location, p_website, p_zodiac_sign, p_interests, p_social_links,
        NOW()
    )
    ON CONFLICT (user_id) DO UPDATE SET
        username = EXCLUDED.username,
        display_name = EXCLUDED.display_name,
        bio = EXCLUDED.bio,
        avatar_url = EXCLUDED.avatar_url,
        location = EXCLUDED.location,
        website = EXCLUDED.website,
        zodiac_sign = EXCLUDED.zodiac_sign,
        interests = EXCLUDED.interests,
        social_links = EXCLUDED.social_links,
        updated_at = NOW()
    RETURNING id INTO v_profile_id;

    -- Calculate and update profile completion
    PERFORM update_profile_completion(p_user_id);

    -- Initialize activity stats if needed
    INSERT INTO user_activity_stats (user_id)
    VALUES (p_user_id)
    ON CONFLICT (user_id) DO NOTHING;

    -- Initialize sound settings if needed
    INSERT INTO user_sound_settings (user_id)
    VALUES (p_user_id)
    ON CONFLICT (user_id) DO NOTHING;

    v_result := json_build_object(
        'success', true,
        'profile_id', v_profile_id,
        'completion_percentage', get_profile_completion_percentage(p_user_id)
    );

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Calculate profile completion percentage
CREATE OR REPLACE FUNCTION get_profile_completion_percentage(p_user_id UUID)
RETURNS DECIMAL AS $$
DECLARE
    v_total_fields INTEGER := 8;
    v_completed_fields INTEGER := 0;
    v_profile RECORD;
BEGIN
    SELECT * INTO v_profile
    FROM user_profiles
    WHERE user_id = p_user_id;

    IF NOT FOUND THEN
        RETURN 0.0;
    END IF;

    -- Check required fields
    IF v_profile.username IS NOT NULL AND LENGTH(v_profile.username) > 0 THEN
        v_completed_fields := v_completed_fields + 1;
    END IF;
    
    IF v_profile.display_name IS NOT NULL AND LENGTH(v_profile.display_name) > 0 THEN
        v_completed_fields := v_completed_fields + 1;
    END IF;
    
    IF v_profile.bio IS NOT NULL AND LENGTH(v_profile.bio) > 0 THEN
        v_completed_fields := v_completed_fields + 1;
    END IF;
    
    IF v_profile.avatar_url IS NOT NULL AND LENGTH(v_profile.avatar_url) > 0 THEN
        v_completed_fields := v_completed_fields + 1;
    END IF;
    
    IF v_profile.location IS NOT NULL AND LENGTH(v_profile.location) > 0 THEN
        v_completed_fields := v_completed_fields + 1;
    END IF;
    
    IF v_profile.zodiac_sign IS NOT NULL AND LENGTH(v_profile.zodiac_sign) > 0 THEN
        v_completed_fields := v_completed_fields + 1;
    END IF;
    
    IF v_profile.interests IS NOT NULL AND array_length(v_profile.interests, 1) > 0 THEN
        v_completed_fields := v_completed_fields + 1;
    END IF;
    
    IF v_profile.social_links IS NOT NULL AND jsonb_object_keys(v_profile.social_links) IS NOT NULL THEN
        v_completed_fields := v_completed_fields + 1;
    END IF;

    RETURN ROUND((v_completed_fields::DECIMAL / v_total_fields) * 100, 2);
END;
$$ LANGUAGE plpgsql;

-- Update profile completion percentage
CREATE OR REPLACE FUNCTION update_profile_completion(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
    v_completion_percentage DECIMAL;
BEGIN
    v_completion_percentage := get_profile_completion_percentage(p_user_id);
    
    UPDATE user_profiles 
    SET profile_completion_percentage = v_completion_percentage,
        updated_at = NOW()
    WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- USER STATISTICS FUNCTIONS
-- =====================================================

-- Update user activity statistics
CREATE OR REPLACE FUNCTION update_user_activity_stats(
    p_user_id UUID,
    p_stat_updates JSONB
)
RETURNS BOOLEAN AS $$
DECLARE
    v_key TEXT;
    v_value NUMERIC;
BEGIN
    -- Update each statistic provided
    FOR v_key, v_value IN SELECT * FROM jsonb_each_text(p_stat_updates)
    LOOP
        -- Use dynamic SQL to update the specific column
        EXECUTE format('
            INSERT INTO user_activity_stats (user_id, %I)
            VALUES ($1, $2)
            ON CONFLICT (user_id) DO UPDATE SET
                %I = user_activity_stats.%I + $2,
                updated_at = NOW()
        ', v_key, v_key, v_key)
        USING p_user_id, v_value::NUMERIC;
    END LOOP;

    -- Update user level based on experience
    PERFORM update_user_level(p_user_id);

    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Calculate and update user level
CREATE OR REPLACE FUNCTION update_user_level(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_experience INTEGER;
    v_new_level INTEGER;
    v_old_level INTEGER;
BEGIN
    SELECT experience_points, user_level INTO v_experience, v_old_level
    FROM user_activity_stats
    WHERE user_id = p_user_id;

    IF NOT FOUND THEN
        RETURN 1;
    END IF;

    -- Calculate level based on experience (each level requires 100 * level XP)
    v_new_level := GREATEST(1, FLOOR(SQRT(v_experience / 50.0)) + 1);

    IF v_new_level != v_old_level THEN
        UPDATE user_activity_stats
        SET user_level = v_new_level,
            updated_at = NOW()
        WHERE user_id = p_user_id;

        -- Check for level-based achievements
        PERFORM check_level_achievements(p_user_id, v_new_level);
    END IF;

    RETURN v_new_level;
END;
$$ LANGUAGE plpgsql;

-- Get user leaderboard position
CREATE OR REPLACE FUNCTION get_user_leaderboard_position(
    p_user_id UUID,
    p_metric VARCHAR(50) DEFAULT 'experience_points'
)
RETURNS JSON AS $$
DECLARE
    v_position INTEGER;
    v_total_users INTEGER;
    v_user_value NUMERIC;
    v_result JSON;
BEGIN
    -- Get user's current value for the metric
    EXECUTE format('SELECT %I FROM user_activity_stats WHERE user_id = $1', p_metric)
    INTO v_user_value USING p_user_id;

    -- Get user's position
    EXECUTE format('
        SELECT COUNT(*) + 1
        FROM user_activity_stats
        WHERE %I > $1
    ', p_metric)
    INTO v_position USING v_user_value;

    -- Get total number of users
    SELECT COUNT(*) INTO v_total_users FROM user_activity_stats;

    v_result := json_build_object(
        'position', v_position,
        'total_users', v_total_users,
        'percentile', ROUND(((v_total_users - v_position + 1)::DECIMAL / v_total_users) * 100, 2),
        'user_value', v_user_value
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- AVATAR DECORATION FUNCTIONS
-- =====================================================

-- Unlock avatar decoration for user
CREATE OR REPLACE FUNCTION unlock_avatar_decoration(
    p_user_id UUID,
    p_decoration_id VARCHAR(100),
    p_unlock_method VARCHAR(50) DEFAULT 'purchase'
)
RETURNS BOOLEAN AS $$
DECLARE
    v_decoration RECORD;
    v_user_level INTEGER;
    v_user_currency INTEGER;
BEGIN
    -- Get decoration details
    SELECT * INTO v_decoration
    FROM avatar_decorations_catalog
    WHERE decoration_id = p_decoration_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Decoration not found: %', p_decoration_id;
    END IF;

    -- Check if user already owns this decoration
    IF EXISTS (
        SELECT 1 FROM user_avatar_decorations
        WHERE user_id = p_user_id AND decoration_id = p_decoration_id
    ) THEN
        RETURN TRUE; -- Already owned
    END IF;

    -- Check unlock requirements
    IF v_decoration.unlock_requirements IS NOT NULL AND v_decoration.unlock_requirements != '{}'::jsonb THEN
        -- Check level requirement
        IF v_decoration.unlock_requirements ? 'level' THEN
            SELECT user_level INTO v_user_level
            FROM user_activity_stats
            WHERE user_id = p_user_id;

            IF v_user_level < (v_decoration.unlock_requirements->>'level')::INTEGER THEN
                RAISE EXCEPTION 'Level requirement not met. Required: %, Current: %', 
                    (v_decoration.unlock_requirements->>'level')::INTEGER, v_user_level;
            END IF;
        END IF;

        -- Check achievement requirements
        IF v_decoration.unlock_requirements ? 'achievements' THEN
            -- This would check against user achievements
            -- Implementation depends on achievement system
        END IF;
    END IF;

    -- Handle cost for purchased decorations
    IF p_unlock_method = 'purchase' AND v_decoration.cost > 0 THEN
        -- This would integrate with currency system
        -- For now, assume purchase is valid
        NULL;
    END IF;

    -- Unlock the decoration
    INSERT INTO user_avatar_decorations (
        user_id, decoration_id, unlock_method, unlocked_at
    ) VALUES (
        p_user_id, p_decoration_id, p_unlock_method, NOW()
    );

    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to unlock decoration: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Equip avatar decoration
CREATE OR REPLACE FUNCTION equip_avatar_decoration(
    p_user_id UUID,
    p_decoration_id VARCHAR(100)
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if user owns the decoration
    IF NOT EXISTS (
        SELECT 1 FROM user_avatar_decorations
        WHERE user_id = p_user_id AND decoration_id = p_decoration_id
    ) THEN
        RAISE EXCEPTION 'User does not own decoration: %', p_decoration_id;
    END IF;

    -- Unequip all other decorations
    UPDATE user_avatar_decorations
    SET is_equipped = false
    WHERE user_id = p_user_id AND is_equipped = true;

    -- Equip the selected decoration
    UPDATE user_avatar_decorations
    SET is_equipped = true,
        total_times_equipped = total_times_equipped + 1
    WHERE user_id = p_user_id AND decoration_id = p_decoration_id;

    -- Update user profile
    UPDATE user_profiles
    SET avatar_decoration = p_decoration_id,
        updated_at = NOW()
    WHERE user_id = p_user_id;

    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Remove avatar decoration
CREATE OR REPLACE FUNCTION remove_avatar_decoration(p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- Unequip all decorations
    UPDATE user_avatar_decorations
    SET is_equipped = false
    WHERE user_id = p_user_id AND is_equipped = true;

    -- Clear decoration from profile
    UPDATE user_profiles
    SET avatar_decoration = NULL,
        updated_at = NOW()
    WHERE user_id = p_user_id;

    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- SOUND SETTINGS FUNCTIONS
-- =====================================================

-- Update user sound settings
CREATE OR REPLACE FUNCTION update_user_sound_settings(
    p_user_id UUID,
    p_settings JSONB
)
RETURNS BOOLEAN AS $$
BEGIN
    INSERT INTO user_sound_settings (user_id)
    VALUES (p_user_id)
    ON CONFLICT (user_id) DO NOTHING;

    -- Update provided settings
    UPDATE user_sound_settings
    SET default_ringtone = COALESCE((p_settings->>'default_ringtone'), default_ringtone),
        default_notification_sound = COALESCE((p_settings->>'default_notification_sound'), default_notification_sound),
        default_message_sound = COALESCE((p_settings->>'default_message_sound'), default_message_sound),
        notification_sound_preferences = COALESCE((p_settings->'notification_sound_preferences'), notification_sound_preferences),
        ringtone_volume = COALESCE((p_settings->>'ringtone_volume')::DECIMAL, ringtone_volume),
        notification_volume = COALESCE((p_settings->>'notification_volume')::DECIMAL, notification_volume),
        enable_sound_effects = COALESCE((p_settings->>'enable_sound_effects')::BOOLEAN, enable_sound_effects),
        enable_haptic_feedback = COALESCE((p_settings->>'enable_haptic_feedback')::BOOLEAN, enable_haptic_feedback),
        quiet_hours_enabled = COALESCE((p_settings->>'quiet_hours_enabled')::BOOLEAN, quiet_hours_enabled),
        quiet_hours_start = COALESCE((p_settings->>'quiet_hours_start')::TIME, quiet_hours_start),
        quiet_hours_end = COALESCE((p_settings->>'quiet_hours_end')::TIME, quiet_hours_end),
        updated_at = NOW()
    WHERE user_id = p_user_id;

    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Set per-user ringtone
CREATE OR REPLACE FUNCTION set_per_user_ringtone(
    p_owner_id UUID,
    p_sender_id UUID,
    p_ringtone VARCHAR(255)
)
RETURNS BOOLEAN AS $$
BEGIN
    INSERT INTO per_user_ringtones (owner_id, sender_id, ringtone)
    VALUES (p_owner_id, p_sender_id, p_ringtone)
    ON CONFLICT (owner_id, sender_id) DO UPDATE SET
        ringtone = EXCLUDED.ringtone,
        is_enabled = true,
        updated_at = NOW();

    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- SOCIAL CONNECTION FUNCTIONS
-- =====================================================

-- Send connection request
CREATE OR REPLACE FUNCTION send_connection_request(
    p_user_id UUID,
    p_target_user_id UUID,
    p_connection_type VARCHAR(50) DEFAULT 'friend'
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    -- Check if connection already exists
    IF EXISTS (
        SELECT 1 FROM user_connections
        WHERE (user_id = p_user_id AND connected_user_id = p_target_user_id)
           OR (user_id = p_target_user_id AND connected_user_id = p_user_id)
    ) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Connection already exists'
        );
    END IF;

    -- Create pending connection
    INSERT INTO user_connections (
        user_id, connected_user_id, connection_type, status
    ) VALUES (
        p_user_id, p_target_user_id, p_connection_type, 'pending'
    );

    -- Update daily stats
    INSERT INTO profile_daily_stats (user_id, date, connection_requests_sent)
    VALUES (p_user_id, CURRENT_DATE, 1)
    ON CONFLICT (user_id, date) DO UPDATE SET
        connection_requests_sent = profile_daily_stats.connection_requests_sent + 1;

    INSERT INTO profile_daily_stats (user_id, date, connection_requests_received)
    VALUES (p_target_user_id, CURRENT_DATE, 1)
    ON CONFLICT (user_id, date) DO UPDATE SET
        connection_requests_received = profile_daily_stats.connection_requests_received + 1;

    v_result := json_build_object(
        'success', true,
        'message', 'Connection request sent'
    );

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Accept connection request
CREATE OR REPLACE FUNCTION accept_connection_request(
    p_user_id UUID,
    p_requester_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Update the connection status
    UPDATE user_connections
    SET status = 'accepted',
        updated_at = NOW()
    WHERE user_id = p_requester_id 
      AND connected_user_id = p_user_id 
      AND status = 'pending';

    -- Create the reciprocal connection
    INSERT INTO user_connections (
        user_id, connected_user_id, connection_type, status
    ) VALUES (
        p_user_id, p_requester_id, 'friend', 'accepted'
    );

    -- Update friend counts
    UPDATE user_activity_stats
    SET friends_count = friends_count + 1
    WHERE user_id IN (p_user_id, p_requester_id);

    -- Update daily stats
    INSERT INTO profile_daily_stats (user_id, date, new_connections)
    VALUES (p_user_id, CURRENT_DATE, 1), (p_requester_id, CURRENT_DATE, 1)
    ON CONFLICT (user_id, date) DO UPDATE SET
        new_connections = profile_daily_stats.new_connections + 1;

    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- ACHIEVEMENT FUNCTIONS
-- =====================================================

-- Check and update achievement progress
CREATE OR REPLACE FUNCTION update_achievement_progress(
    p_user_id UUID,
    p_achievement_id VARCHAR(100),
    p_progress_increment DECIMAL DEFAULT 1
)
RETURNS BOOLEAN AS $$
DECLARE
    v_achievement RECORD;
    v_user_achievement RECORD;
    v_new_progress DECIMAL;
    v_completion_percentage DECIMAL;
BEGIN
    -- Get achievement details
    SELECT * INTO v_achievement
    FROM profile_achievements
    WHERE achievement_id = p_achievement_id;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    -- Get or create user achievement progress
    INSERT INTO user_profile_achievements (
        user_id, achievement_id, target_progress, current_progress
    ) VALUES (
        p_user_id, p_achievement_id, 
        (v_achievement.requirement_data->>'target')::DECIMAL, 0
    )
    ON CONFLICT (user_id, achievement_id) DO NOTHING;

    -- Update progress
    UPDATE user_profile_achievements
    SET current_progress = LEAST(current_progress + p_progress_increment, target_progress),
        last_progress_at = NOW(),
        completion_percentage = ROUND((LEAST(current_progress + p_progress_increment, target_progress) / target_progress) * 100, 2)
    WHERE user_id = p_user_id AND achievement_id = p_achievement_id
    RETURNING * INTO v_user_achievement;

    -- Check if achievement is completed
    IF v_user_achievement.current_progress >= v_user_achievement.target_progress AND NOT v_user_achievement.is_completed THEN
        -- Mark as completed
        UPDATE user_profile_achievements
        SET is_completed = true,
            completed_at = NOW(),
            completion_percentage = 100.0
        WHERE user_id = p_user_id AND achievement_id = p_achievement_id;

        -- Award rewards
        PERFORM award_achievement_rewards(p_user_id, p_achievement_id);

        -- Update daily stats
        INSERT INTO profile_daily_stats (user_id, date, achievement_unlocks)
        VALUES (p_user_id, CURRENT_DATE, 1)
        ON CONFLICT (user_id, date) DO UPDATE SET
            achievement_unlocks = profile_daily_stats.achievement_unlocks + 1;
    END IF;

    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Award achievement rewards
CREATE OR REPLACE FUNCTION award_achievement_rewards(
    p_user_id UUID,
    p_achievement_id VARCHAR(100)
)
RETURNS VOID AS $$
DECLARE
    v_achievement RECORD;
    v_unlock_item TEXT;
BEGIN
    SELECT * INTO v_achievement
    FROM profile_achievements
    WHERE achievement_id = p_achievement_id;

    -- Award experience points
    IF v_achievement.experience_reward > 0 THEN
        PERFORM update_user_activity_stats(
            p_user_id,
            json_build_object('experience_points', v_achievement.experience_reward)::jsonb
        );
    END IF;

    -- Award reputation
    IF v_achievement.reputation_reward > 0 THEN
        UPDATE user_profiles
        SET reputation_score = reputation_score + v_achievement.reputation_reward
        WHERE user_id = p_user_id;
    END IF;

    -- Unlock decorations, themes, etc.
    IF v_achievement.unlock_rewards IS NOT NULL THEN
        FOREACH v_unlock_item IN ARRAY v_achievement.unlock_rewards
        LOOP
            -- Check if it's a decoration
            IF v_unlock_item LIKE 'decoration_%' THEN
                PERFORM unlock_avatar_decoration(
                    p_user_id, 
                    REPLACE(v_unlock_item, 'decoration_', ''), 
                    'achievement'
                );
            END IF;
            
            -- Add more unlock types as needed (themes, etc.)
        END LOOP;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Check level-based achievements
CREATE OR REPLACE FUNCTION check_level_achievements(
    p_user_id UUID,
    p_new_level INTEGER
)
RETURNS VOID AS $$
DECLARE
    v_achievement RECORD;
BEGIN
    -- Check for level milestone achievements
    FOR v_achievement IN 
        SELECT * FROM profile_achievements
        WHERE category = 'milestones' 
          AND requirement_type = 'level_threshold'
          AND (requirement_data->>'level')::INTEGER <= p_new_level
    LOOP
        PERFORM update_achievement_progress(p_user_id, v_achievement.achievement_id, p_new_level);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- ANALYTICS AND REPORTING FUNCTIONS
-- =====================================================

-- Record profile view
CREATE OR REPLACE FUNCTION record_profile_view(
    p_profile_owner_id UUID,
    p_viewer_id UUID DEFAULT NULL,
    p_view_source VARCHAR(50) DEFAULT 'direct',
    p_sections_viewed TEXT[] DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Record the view
    INSERT INTO profile_view_history (
        profile_owner_id, viewer_id, view_source, sections_viewed, viewed_at
    ) VALUES (
        p_profile_owner_id, p_viewer_id, p_view_source, p_sections_viewed, NOW()
    );

    -- Update daily stats
    INSERT INTO profile_daily_stats (user_id, date, profile_views)
    VALUES (p_profile_owner_id, CURRENT_DATE, 1)
    ON CONFLICT (user_id, date) DO UPDATE SET
        profile_views = profile_daily_stats.profile_views + 1;

    -- Update unique views if it's a new viewer today
    IF p_viewer_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM profile_view_history
        WHERE profile_owner_id = p_profile_owner_id
          AND viewer_id = p_viewer_id
          AND viewed_at::DATE = CURRENT_DATE
          AND viewed_at < NOW() - INTERVAL '1 minute' -- Exclude this current view
    ) THEN
        UPDATE profile_daily_stats
        SET profile_views_unique = profile_views_unique + 1
        WHERE user_id = p_profile_owner_id AND date = CURRENT_DATE;
    END IF;

    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get profile analytics summary
CREATE OR REPLACE FUNCTION get_profile_analytics_summary(
    p_user_id UUID,
    p_days_back INTEGER DEFAULT 30
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
    v_start_date DATE := CURRENT_DATE - p_days_back;
BEGIN
    SELECT json_build_object(
        'profile_views', json_build_object(
            'total', COALESCE(SUM(profile_views), 0),
            'unique', COALESCE(SUM(profile_views_unique), 0),
            'daily_average', ROUND(COALESCE(AVG(profile_views), 0), 2)
        ),
        'activity', json_build_object(
            'messages_sent', COALESCE(SUM(messages_sent), 0),
            'reactions_given', COALESCE(SUM(reactions_given), 0),
            'reactions_received', COALESCE(SUM(reactions_received), 0),
            'active_minutes', COALESCE(SUM(active_minutes), 0)
        ),
        'social', json_build_object(
            'new_connections', COALESCE(SUM(new_connections), 0),
            'connection_requests_sent', COALESCE(SUM(connection_requests_sent), 0),
            'connection_requests_received', COALESCE(SUM(connection_requests_received), 0)
        ),
        'achievements', json_build_object(
            'unlocks', COALESCE(SUM(achievement_unlocks), 0),
            'experience_gained', COALESCE(SUM(experience_gained), 0)
        )
    ) INTO v_result
    FROM profile_daily_stats
    WHERE user_id = p_user_id
      AND date >= v_start_date;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- SEARCH AND DISCOVERY FUNCTIONS
-- =====================================================

-- Search user profiles
CREATE OR REPLACE FUNCTION search_user_profiles(
    p_search_query TEXT,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    user_id UUID,
    username VARCHAR(50),
    display_name VARCHAR(100),
    bio TEXT,
    avatar_url TEXT,
    avatar_decoration VARCHAR(100),
    reputation_score INTEGER,
    is_verified BOOLEAN,
    rank REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        up.user_id,
        up.username,
        up.display_name,
        up.bio,
        up.avatar_url,
        up.avatar_decoration,
        up.reputation_score,
        up.is_verified,
        ts_rank(
            to_tsvector('english', 
                coalesce(up.display_name, '') || ' ' || 
                coalesce(up.bio, '') || ' ' || 
                coalesce(up.username, '')
            ),
            plainto_tsquery('english', p_search_query)
        ) as rank
    FROM user_profiles up
    WHERE to_tsvector('english', 
            coalesce(up.display_name, '') || ' ' || 
            coalesce(up.bio, '') || ' ' || 
            coalesce(up.username, '')
          ) @@ plainto_tsquery('english', p_search_query)
       OR up.username ILIKE '%' || p_search_query || '%'
       OR up.display_name ILIKE '%' || p_search_query || '%'
    ORDER BY rank DESC, up.reputation_score DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION create_or_update_user_profile(UUID, VARCHAR, VARCHAR, TEXT, TEXT, VARCHAR, VARCHAR, VARCHAR, TEXT[], JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION get_profile_completion_percentage(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_profile_completion(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_user_activity_stats(UUID, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION update_user_level(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_leaderboard_position(UUID, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION unlock_avatar_decoration(UUID, VARCHAR, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION equip_avatar_decoration(UUID, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION remove_avatar_decoration(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_user_sound_settings(UUID, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION set_per_user_ringtone(UUID, UUID, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION send_connection_request(UUID, UUID, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION accept_connection_request(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_achievement_progress(UUID, VARCHAR, DECIMAL) TO authenticated;
GRANT EXECUTE ON FUNCTION record_profile_view(UUID, UUID, VARCHAR, TEXT[]) TO authenticated;
GRANT EXECUTE ON FUNCTION get_profile_analytics_summary(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION search_user_profiles(TEXT, INTEGER, INTEGER) TO authenticated;

-- =====================================================
-- END OF PROFILE FUNCTIONS
-- =====================================================
