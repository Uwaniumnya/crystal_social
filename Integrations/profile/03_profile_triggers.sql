-- =====================================================
-- CRYSTAL SOCIAL - PROFILE SYSTEM TRIGGERS
-- =====================================================
-- Automated triggers for profile maintenance and analytics
-- =====================================================

-- =====================================================
-- PROFILE MAINTENANCE TRIGGERS
-- =====================================================

-- Trigger function to update profile completion on profile changes
CREATE OR REPLACE FUNCTION trigger_update_profile_completion()
RETURNS TRIGGER AS $$
BEGIN
    -- Update completion percentage when profile is modified
    NEW.profile_completion_percentage := get_profile_completion_percentage(NEW.user_id);
    NEW.updated_at := NOW();
    
    -- Check for profile completion achievements
    IF OLD.profile_completion_percentage < 50 AND NEW.profile_completion_percentage >= 50 THEN
        PERFORM update_achievement_progress(NEW.user_id, 'profile_half_complete', 1);
    END IF;
    
    IF OLD.profile_completion_percentage < 80 AND NEW.profile_completion_percentage >= 80 THEN
        PERFORM update_achievement_progress(NEW.user_id, 'profile_mostly_complete', 1);
    END IF;
    
    IF OLD.profile_completion_percentage < 100 AND NEW.profile_completion_percentage >= 100 THEN
        PERFORM update_achievement_progress(NEW.user_id, 'profile_complete', 1);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to user_profiles table
DROP TRIGGER IF EXISTS trigger_profile_completion_update ON user_profiles;
CREATE TRIGGER trigger_profile_completion_update
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_profile_completion();

-- =====================================================
-- ACTIVITY STATISTICS TRIGGERS
-- =====================================================

-- Trigger function to update last_active_at when stats change
CREATE OR REPLACE FUNCTION trigger_update_user_activity()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    
    -- Update last active in profile
    UPDATE user_profiles 
    SET last_active_at = NOW()
    WHERE user_id = NEW.user_id;
    
    -- Update current day stats
    INSERT INTO profile_daily_stats (
        user_id, date, messages_sent, reactions_given, reactions_received,
        active_minutes, experience_gained
    ) VALUES (
        NEW.user_id, CURRENT_DATE,
        GREATEST(0, NEW.total_messages_sent - COALESCE(OLD.total_messages_sent, 0)),
        GREATEST(0, NEW.total_reactions_given - COALESCE(OLD.total_reactions_given, 0)),
        GREATEST(0, NEW.total_reactions_received - COALESCE(OLD.total_reactions_received, 0)),
        0, -- Active minutes would be calculated separately
        GREATEST(0, NEW.experience_points - COALESCE(OLD.experience_points, 0))
    )
    ON CONFLICT (user_id, date) DO UPDATE SET
        messages_sent = profile_daily_stats.messages_sent + GREATEST(0, NEW.total_messages_sent - COALESCE(OLD.total_messages_sent, 0)),
        reactions_given = profile_daily_stats.reactions_given + GREATEST(0, NEW.total_reactions_given - COALESCE(OLD.total_reactions_given, 0)),
        reactions_received = profile_daily_stats.reactions_received + GREATEST(0, NEW.total_reactions_received - COALESCE(OLD.total_reactions_received, 0)),
        experience_gained = profile_daily_stats.experience_gained + GREATEST(0, NEW.experience_points - COALESCE(OLD.experience_points, 0));

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to user_activity_stats table
DROP TRIGGER IF EXISTS trigger_activity_stats_update ON user_activity_stats;
CREATE TRIGGER trigger_activity_stats_update
    BEFORE UPDATE ON user_activity_stats
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_user_activity();

-- =====================================================
-- AVATAR DECORATION TRIGGERS
-- =====================================================

-- Trigger function to handle decoration equipment changes
CREATE OR REPLACE FUNCTION trigger_decoration_equipment_change()
RETURNS TRIGGER AS $$
BEGIN
    -- When a decoration is equipped, update the profile
    IF NEW.is_equipped = true AND (OLD.is_equipped = false OR OLD.is_equipped IS NULL) THEN
        UPDATE user_profiles
        SET avatar_decoration = NEW.decoration_id,
            updated_at = NOW()
        WHERE user_id = NEW.user_id;
        
        -- Increment equipment count
        NEW.total_times_equipped := COALESCE(OLD.total_times_equipped, 0) + 1;
        
        -- Update daily stats
        INSERT INTO profile_daily_stats (user_id, date, decoration_changes)
        VALUES (NEW.user_id, CURRENT_DATE, 1)
        ON CONFLICT (user_id, date) DO UPDATE SET
            decoration_changes = profile_daily_stats.decoration_changes + 1;
    END IF;
    
    -- When a decoration is unequipped, clear from profile if it was the active one
    IF NEW.is_equipped = false AND OLD.is_equipped = true THEN
        UPDATE user_profiles
        SET avatar_decoration = NULL,
            updated_at = NOW()
        WHERE user_id = NEW.user_id 
          AND avatar_decoration = NEW.decoration_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to user_avatar_decorations table
DROP TRIGGER IF EXISTS trigger_decoration_equipment ON user_avatar_decorations;
CREATE TRIGGER trigger_decoration_equipment
    BEFORE UPDATE ON user_avatar_decorations
    FOR EACH ROW
    EXECUTE FUNCTION trigger_decoration_equipment_change();

-- =====================================================
-- CONNECTION TRIGGERS
-- =====================================================

-- Trigger function to update connection statistics
CREATE OR REPLACE FUNCTION trigger_connection_stats_update()
RETURNS TRIGGER AS $$
BEGIN
    -- When connection is accepted, update friend counts
    IF TG_OP = 'UPDATE' AND NEW.status = 'accepted' AND OLD.status = 'pending' THEN
        -- Update friend count for the requester
        UPDATE user_activity_stats
        SET friends_count = friends_count + 1
        WHERE user_id = NEW.user_id;
        
        -- Update friend count for the accepter
        UPDATE user_activity_stats
        SET friends_count = friends_count + 1
        WHERE user_id = NEW.connected_user_id;
        
        -- Check for social achievements
        PERFORM update_achievement_progress(NEW.user_id, 'first_friend', 1);
        PERFORM update_achievement_progress(NEW.connected_user_id, 'first_friend', 1);
        PERFORM update_achievement_progress(NEW.user_id, 'social_butterfly', 1);
        PERFORM update_achievement_progress(NEW.connected_user_id, 'social_butterfly', 1);
    END IF;
    
    -- When connection is deleted, update friend counts
    IF TG_OP = 'DELETE' AND OLD.status = 'accepted' THEN
        UPDATE user_activity_stats
        SET friends_count = GREATEST(0, friends_count - 1)
        WHERE user_id IN (OLD.user_id, OLD.connected_user_id);
        
        RETURN OLD;
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to user_connections table
DROP TRIGGER IF EXISTS trigger_connection_update ON user_connections;
CREATE TRIGGER trigger_connection_update
    AFTER UPDATE ON user_connections
    FOR EACH ROW
    EXECUTE FUNCTION trigger_connection_stats_update();

DROP TRIGGER IF EXISTS trigger_connection_delete ON user_connections;
CREATE TRIGGER trigger_connection_delete
    AFTER DELETE ON user_connections
    FOR EACH ROW
    EXECUTE FUNCTION trigger_connection_stats_update();

-- =====================================================
-- ACHIEVEMENT TRIGGERS
-- =====================================================

-- Trigger function to award achievement rewards automatically
CREATE OR REPLACE FUNCTION trigger_achievement_completion()
RETURNS TRIGGER AS $$
BEGIN
    -- When an achievement is completed, award rewards
    IF NEW.is_completed = true AND (OLD.is_completed = false OR OLD.is_completed IS NULL) THEN
        PERFORM award_achievement_rewards(NEW.user_id, NEW.achievement_id);
        
        -- Update reputation for completing achievements
        UPDATE user_profiles
        SET reputation_score = reputation_score + 5,
            updated_at = NOW()
        WHERE user_id = NEW.user_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to user_profile_achievements table
DROP TRIGGER IF EXISTS trigger_achievement_complete ON user_profile_achievements;
CREATE TRIGGER trigger_achievement_complete
    AFTER UPDATE ON user_profile_achievements
    FOR EACH ROW
    EXECUTE FUNCTION trigger_achievement_completion();

-- =====================================================
-- REPUTATION TRIGGERS
-- =====================================================

-- Trigger function to update user reputation based on reviews
CREATE OR REPLACE FUNCTION trigger_reputation_update()
RETURNS TRIGGER AS $$
DECLARE
    v_avg_rating DECIMAL;
    v_review_count INTEGER;
    v_reputation_score INTEGER;
BEGIN
    -- Calculate new average rating and reputation
    SELECT 
        ROUND(AVG(rating), 2),
        COUNT(*),
        LEAST(1000, GREATEST(0, ROUND(AVG(rating) * 100 + COUNT(*) * 10)))
    INTO v_avg_rating, v_review_count, v_reputation_score
    FROM profile_reputation
    WHERE user_id = COALESCE(NEW.user_id, OLD.user_id);
    
    -- Update user profile with new reputation
    UPDATE user_profiles
    SET reputation_score = v_reputation_score,
        updated_at = NOW()
    WHERE user_id = COALESCE(NEW.user_id, OLD.user_id);
    
    -- Check for reputation achievements
    IF TG_OP = 'INSERT' THEN
        PERFORM update_achievement_progress(NEW.user_id, 'first_review', 1);
        
        IF v_reputation_score >= 100 THEN
            PERFORM update_achievement_progress(NEW.user_id, 'trusted_member', 1);
        END IF;
        
        IF v_reputation_score >= 500 THEN
            PERFORM update_achievement_progress(NEW.user_id, 'community_leader', 1);
        END IF;
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to profile_reputation table
DROP TRIGGER IF EXISTS trigger_reputation_insert ON profile_reputation;
CREATE TRIGGER trigger_reputation_insert
    AFTER INSERT ON profile_reputation
    FOR EACH ROW
    EXECUTE FUNCTION trigger_reputation_update();

DROP TRIGGER IF EXISTS trigger_reputation_update_change ON profile_reputation;
CREATE TRIGGER trigger_reputation_update_change
    AFTER UPDATE ON profile_reputation
    FOR EACH ROW
    EXECUTE FUNCTION trigger_reputation_update();

DROP TRIGGER IF EXISTS trigger_reputation_delete ON profile_reputation;
CREATE TRIGGER trigger_reputation_delete
    AFTER DELETE ON profile_reputation
    FOR EACH ROW
    EXECUTE FUNCTION trigger_reputation_update();

-- =====================================================
-- ANALYTICS TRIGGERS
-- =====================================================

-- Trigger function to update profile view analytics
CREATE OR REPLACE FUNCTION trigger_profile_view_analytics()
RETURNS TRIGGER AS $$
BEGIN
    -- Update profile analytics when views are recorded
    INSERT INTO profile_daily_stats (user_id, date, profile_views, profile_views_unique)
    VALUES (NEW.profile_owner_id, CURRENT_DATE, 1, 
            CASE WHEN NEW.viewer_id IS NOT NULL THEN 1 ELSE 0 END)
    ON CONFLICT (user_id, date) DO UPDATE SET
        profile_views = profile_daily_stats.profile_views + 1,
        profile_views_unique = profile_daily_stats.profile_views_unique + 
            CASE WHEN NEW.viewer_id IS NOT NULL THEN 1 ELSE 0 END;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to profile_view_history table
DROP TRIGGER IF EXISTS trigger_view_analytics ON profile_view_history;
CREATE TRIGGER trigger_view_analytics
    AFTER INSERT ON profile_view_history
    FOR EACH ROW
    EXECUTE FUNCTION trigger_profile_view_analytics();

-- =====================================================
-- CLEANUP AND MAINTENANCE TRIGGERS
-- =====================================================

-- Trigger function for automatic cleanup of old data
CREATE OR REPLACE FUNCTION trigger_cleanup_old_data()
RETURNS TRIGGER AS $$
BEGIN
    -- Clean up old profile view history (keep only 90 days)
    DELETE FROM profile_view_history
    WHERE viewed_at < NOW() - INTERVAL '90 days';
    
    -- Clean up old daily stats (keep only 365 days)
    DELETE FROM profile_daily_stats
    WHERE date < CURRENT_DATE - INTERVAL '365 days';

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- STREAK CALCULATION TRIGGERS
-- =====================================================

-- Trigger function to calculate activity streaks
CREATE OR REPLACE FUNCTION trigger_calculate_streaks()
RETURNS TRIGGER AS $$
DECLARE
    v_yesterday_active BOOLEAN;
    v_current_streak INTEGER;
    v_longest_streak INTEGER;
BEGIN
    -- Check if user was active yesterday
    SELECT EXISTS (
        SELECT 1 FROM profile_daily_stats
        WHERE user_id = NEW.user_id
          AND date = CURRENT_DATE - INTERVAL '1 day'
          AND (messages_sent > 0 OR active_minutes > 0)
    ) INTO v_yesterday_active;
    
    -- Get current streaks
    SELECT current_streak_days, longest_streak_days
    INTO v_current_streak, v_longest_streak
    FROM user_activity_stats
    WHERE user_id = NEW.user_id;
    
    -- Update streaks based on activity
    IF NEW.messages_sent > 0 OR NEW.active_minutes > 0 THEN
        -- User is active today
        IF v_yesterday_active THEN
            -- Continue streak
            v_current_streak := v_current_streak + 1;
        ELSE
            -- Start new streak
            v_current_streak := 1;
        END IF;
        
        -- Update longest streak if needed
        v_longest_streak := GREATEST(v_longest_streak, v_current_streak);
        
        -- Update user stats
        UPDATE user_activity_stats
        SET current_streak_days = v_current_streak,
            longest_streak_days = v_longest_streak,
            total_login_days = total_login_days + 1
        WHERE user_id = NEW.user_id;
        
        -- Check for streak achievements
        IF v_current_streak = 7 THEN
            PERFORM update_achievement_progress(NEW.user_id, 'weekly_warrior', 1);
        ELSIF v_current_streak = 30 THEN
            PERFORM update_achievement_progress(NEW.user_id, 'monthly_master', 1);
        ELSIF v_current_streak = 100 THEN
            PERFORM update_achievement_progress(NEW.user_id, 'streak_legend', 1);
        END IF;
    ELSE
        -- User not active today - streak might be broken
        -- This would be handled by a daily cleanup job
        NULL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to profile_daily_stats table
DROP TRIGGER IF EXISTS trigger_streak_calculation ON profile_daily_stats;
CREATE TRIGGER trigger_streak_calculation
    AFTER INSERT OR UPDATE ON profile_daily_stats
    FOR EACH ROW
    EXECUTE FUNCTION trigger_calculate_streaks();

-- =====================================================
-- NOTIFICATION TRIGGERS
-- =====================================================

-- Trigger function to send notifications for profile events
CREATE OR REPLACE FUNCTION trigger_profile_notifications()
RETURNS TRIGGER AS $$
BEGIN
    -- Profile view notifications (if enabled)
    IF TG_TABLE_NAME = 'profile_view_history' AND NEW.viewer_id IS NOT NULL THEN
        -- Could integrate with notification system here
        -- For now, just log the event
        NULL;
    END IF;
    
    -- Connection request notifications
    IF TG_TABLE_NAME = 'user_connections' AND NEW.status = 'pending' THEN
        -- Send notification to target user about friend request
        -- Integration with notification system would go here
        NULL;
    END IF;
    
    -- Achievement unlock notifications
    IF TG_TABLE_NAME = 'user_profile_achievements' AND NEW.is_completed = true AND OLD.is_completed = false THEN
        -- Send notification about achievement unlock
        -- Integration with notification system would go here
        NULL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply notification triggers (these would be activated when notification system is ready)
-- CREATE TRIGGER trigger_profile_view_notification
--     AFTER INSERT ON profile_view_history
--     FOR EACH ROW
--     EXECUTE FUNCTION trigger_profile_notifications();

-- CREATE TRIGGER trigger_connection_notification
--     AFTER INSERT ON user_connections
--     FOR EACH ROW
--     EXECUTE FUNCTION trigger_profile_notifications();

-- CREATE TRIGGER trigger_achievement_notification
--     AFTER UPDATE ON user_profile_achievements
--     FOR EACH ROW
--     EXECUTE FUNCTION trigger_profile_notifications();

-- =====================================================
-- VALIDATION TRIGGERS
-- =====================================================

-- Trigger function to validate profile data
CREATE OR REPLACE FUNCTION trigger_validate_profile_data()
RETURNS TRIGGER AS $$
BEGIN
    -- Validate username format
    IF NEW.username IS NOT NULL AND NEW.username !~ '^[a-zA-Z0-9_-]+$' THEN
        RAISE EXCEPTION 'Username can only contain letters, numbers, underscores, and hyphens';
    END IF;
    
    -- Validate bio length
    IF NEW.bio IS NOT NULL AND LENGTH(NEW.bio) > 500 THEN
        RAISE EXCEPTION 'Bio cannot exceed 500 characters';
    END IF;
    
    -- Validate website URL format
    IF NEW.website IS NOT NULL AND NEW.website !~ '^https?://' THEN
        RAISE EXCEPTION 'Website must be a valid HTTP or HTTPS URL';
    END IF;
    
    -- Validate interests array
    IF NEW.interests IS NOT NULL AND array_length(NEW.interests, 1) > 20 THEN
        RAISE EXCEPTION 'Cannot have more than 20 interests';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply validation trigger to user_profiles table
DROP TRIGGER IF EXISTS trigger_profile_validation ON user_profiles;
CREATE TRIGGER trigger_profile_validation
    BEFORE INSERT OR UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION trigger_validate_profile_data();

-- =====================================================
-- PERFORMANCE OPTIMIZATION TRIGGERS
-- =====================================================

-- Trigger function to update computed fields and caches
CREATE OR REPLACE FUNCTION trigger_update_computed_fields()
RETURNS TRIGGER AS $$
BEGIN
    -- Update timestamps
    NEW.updated_at := NOW();
    
    -- Update computed fields based on table
    IF TG_TABLE_NAME = 'user_profiles' THEN
        -- Update profile completion percentage
        NEW.profile_completion_percentage := get_profile_completion_percentage(NEW.user_id);
    END IF;
    
    IF TG_TABLE_NAME = 'user_activity_stats' THEN
        -- Update user level based on experience
        NEW.user_level := GREATEST(1, FLOOR(SQRT(NEW.experience_points / 50.0)) + 1);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply computed fields trigger
DROP TRIGGER IF EXISTS trigger_computed_fields_profile ON user_profiles;
CREATE TRIGGER trigger_computed_fields_profile
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_computed_fields();

DROP TRIGGER IF EXISTS trigger_computed_fields_stats ON user_activity_stats;
CREATE TRIGGER trigger_computed_fields_stats
    BEFORE UPDATE ON user_activity_stats
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_computed_fields();

-- =====================================================
-- AUDIT TRIGGERS
-- =====================================================

-- Trigger function for audit logging
CREATE OR REPLACE FUNCTION trigger_audit_profile_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- Log significant profile changes for audit purposes
    IF TG_OP = 'UPDATE' AND (
        OLD.username IS DISTINCT FROM NEW.username OR
        OLD.avatar_url IS DISTINCT FROM NEW.avatar_url OR
        OLD.is_verified IS DISTINCT FROM NEW.is_verified
    ) THEN
        -- Could log to audit table here
        -- For now, just ensure timestamps are updated
        NEW.updated_at := NOW();
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply audit trigger to sensitive profile data
DROP TRIGGER IF EXISTS trigger_profile_audit ON user_profiles;
CREATE TRIGGER trigger_profile_audit
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION trigger_audit_profile_changes();

-- =====================================================
-- SCHEDULED MAINTENANCE FUNCTIONS
-- =====================================================

-- Function to be called by scheduled job for daily maintenance
CREATE OR REPLACE FUNCTION daily_profile_maintenance()
RETURNS VOID AS $$
BEGIN
    -- Clean up old data
    DELETE FROM profile_view_history
    WHERE viewed_at < NOW() - INTERVAL '90 days';
    
    DELETE FROM profile_daily_stats
    WHERE date < CURRENT_DATE - INTERVAL '365 days';
    
    -- Update streak calculations for users who weren't active
    UPDATE user_activity_stats
    SET current_streak_days = 0
    WHERE user_id NOT IN (
        SELECT DISTINCT user_id
        FROM profile_daily_stats
        WHERE date = CURRENT_DATE - INTERVAL '1 day'
          AND (messages_sent > 0 OR active_minutes > 0)
    ) AND current_streak_days > 0;
    
    -- Update most active day/hour statistics
    UPDATE user_activity_stats
    SET most_active_day_of_week = (
        SELECT EXTRACT(DOW FROM date)::INTEGER
        FROM profile_daily_stats
        WHERE user_id = user_activity_stats.user_id
          AND date >= CURRENT_DATE - INTERVAL '30 days'
        GROUP BY EXTRACT(DOW FROM date)
        ORDER BY SUM(messages_sent + active_minutes) DESC
        LIMIT 1
    );
    
    -- Vacuum and analyze tables for performance
    -- Note: These would typically be run by a database administrator
    -- VACUUM ANALYZE user_profiles;
    -- VACUUM ANALYZE user_activity_stats;
    -- VACUUM ANALYZE profile_daily_stats;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission for maintenance function
GRANT EXECUTE ON FUNCTION daily_profile_maintenance() TO service_role;

-- =====================================================
-- END OF PROFILE TRIGGERS
-- =====================================================
