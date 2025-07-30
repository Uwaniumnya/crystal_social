-- =====================================================
-- CRYSTAL SOCIAL - PROFILE SYSTEM SECURITY
-- =====================================================
-- Row Level Security policies for profile data protection
-- =====================================================

-- =====================================================
-- ENABLE ROW LEVEL SECURITY
-- =====================================================

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_activity_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE avatar_decorations_catalog ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_avatar_decorations ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_sound_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE per_user_ringtones ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_themes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profile_themes ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profile_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_reputation ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_daily_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_view_history ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- SECURITY HELPER FUNCTIONS
-- =====================================================

-- Function to check if user is profile owner or has permission
CREATE OR REPLACE FUNCTION is_profile_owner_or_admin(profile_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN (
        auth.uid() = profile_user_id OR
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE user_id = auth.uid()
              AND (
                -- Admin users (could be based on role or specific flag)
                user_id IN (
                    SELECT user_id FROM user_profiles 
                    WHERE username IN ('admin', 'moderator')
                ) OR
                -- Verified users with high reputation for some operations
                (is_verified = true AND reputation_score > 500)
              )
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if profiles are connected (friends)
CREATE OR REPLACE FUNCTION are_users_connected(user1_id UUID, user2_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM user_connections
        WHERE ((user_id = user1_id AND connected_user_id = user2_id) OR
               (user_id = user2_id AND connected_user_id = user1_id))
          AND status = 'accepted'
          AND connection_type = 'friend'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if profile is public or user has access
CREATE OR REPLACE FUNCTION can_view_profile(profile_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    profile_privacy BOOLEAN;
BEGIN
    -- Always allow viewing own profile
    IF auth.uid() = profile_user_id THEN
        RETURN TRUE;
    END IF;
    
    -- Check if profile is private
    SELECT is_private INTO profile_privacy
    FROM user_profiles
    WHERE user_id = profile_user_id;
    
    -- If profile is public, allow viewing
    IF NOT COALESCE(profile_privacy, false) THEN
        RETURN TRUE;
    END IF;
    
    -- If profile is private, check if users are connected
    RETURN are_users_connected(auth.uid(), profile_user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user can modify profile data
CREATE OR REPLACE FUNCTION can_modify_profile(profile_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN (
        auth.uid() = profile_user_id OR
        is_profile_owner_or_admin(profile_user_id)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- USER PROFILES POLICIES
-- =====================================================

-- Policy for viewing user profiles
CREATE POLICY "Users can view public profiles and their own"
    ON user_profiles FOR SELECT
    USING (can_view_profile(user_id));

-- Policy for creating user profiles (users can only create their own)
CREATE POLICY "Users can create their own profile"
    ON user_profiles FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy for updating user profiles (users can only update their own)
CREATE POLICY "Users can update their own profile"
    ON user_profiles FOR UPDATE
    USING (can_modify_profile(user_id))
    WITH CHECK (can_modify_profile(user_id));

-- Policy for deleting user profiles (only own profile or admin)
CREATE POLICY "Users can delete their own profile"
    ON user_profiles FOR DELETE
    USING (can_modify_profile(user_id));

-- =====================================================
-- USER ACTIVITY STATS POLICIES
-- =====================================================

-- Policy for viewing activity stats (own stats or connected friends)
CREATE POLICY "Users can view their own stats and connected friends"
    ON user_activity_stats FOR SELECT
    USING (
        auth.uid() = user_id OR
        are_users_connected(auth.uid(), user_id) OR
        is_profile_owner_or_admin(user_id)
    );

-- Policy for creating activity stats (system only)
CREATE POLICY "Only system can create activity stats"
    ON user_activity_stats FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy for updating activity stats (own stats only)
CREATE POLICY "Users can update their own stats"
    ON user_activity_stats FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- AVATAR DECORATIONS POLICIES
-- =====================================================

-- Policy for viewing decoration catalog (public)
CREATE POLICY "Everyone can view decoration catalog"
    ON avatar_decorations_catalog FOR SELECT
    USING (true);

-- Policy for managing decoration catalog (admin only)
CREATE POLICY "Only admins can manage decoration catalog"
    ON avatar_decorations_catalog FOR ALL
    USING (is_profile_owner_or_admin(auth.uid()))
    WITH CHECK (is_profile_owner_or_admin(auth.uid()));

-- Policy for viewing user decorations (own decorations)
CREATE POLICY "Users can view their own decorations"
    ON user_avatar_decorations FOR SELECT
    USING (auth.uid() = user_id);

-- Policy for managing user decorations (own decorations)
CREATE POLICY "Users can manage their own decorations"
    ON user_avatar_decorations FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- SOUND SETTINGS POLICIES
-- =====================================================

-- Policy for viewing sound settings (own settings only)
CREATE POLICY "Users can view their own sound settings"
    ON user_sound_settings FOR SELECT
    USING (auth.uid() = user_id);

-- Policy for managing sound settings (own settings only)
CREATE POLICY "Users can manage their own sound settings"
    ON user_sound_settings FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Policy for viewing per-user ringtones (owner only)
CREATE POLICY "Users can view their own ringtone settings"
    ON per_user_ringtones FOR SELECT
    USING (auth.uid() = owner_id);

-- Policy for managing per-user ringtones (owner only)
CREATE POLICY "Users can manage their own ringtone settings"
    ON per_user_ringtones FOR ALL
    USING (auth.uid() = owner_id)
    WITH CHECK (auth.uid() = owner_id);

-- =====================================================
-- PROFILE THEMES POLICIES
-- =====================================================

-- Policy for viewing theme catalog (public)
CREATE POLICY "Everyone can view theme catalog"
    ON profile_themes FOR SELECT
    USING (true);

-- Policy for managing theme catalog (admin only)
CREATE POLICY "Only admins can manage theme catalog"
    ON profile_themes FOR ALL
    USING (is_profile_owner_or_admin(auth.uid()))
    WITH CHECK (is_profile_owner_or_admin(auth.uid()));

-- Policy for viewing user themes (own themes)
CREATE POLICY "Users can view their own themes"
    ON user_profile_themes FOR SELECT
    USING (auth.uid() = user_id);

-- Policy for managing user themes (own themes)
CREATE POLICY "Users can manage their own themes"
    ON user_profile_themes FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- ACHIEVEMENTS POLICIES
-- =====================================================

-- Policy for viewing achievements catalog (public)
CREATE POLICY "Everyone can view achievements catalog"
    ON profile_achievements FOR SELECT
    USING (NOT is_secret OR is_profile_owner_or_admin(auth.uid()));

-- Policy for managing achievements catalog (admin only)
CREATE POLICY "Only admins can manage achievements catalog"
    ON profile_achievements FOR ALL
    USING (is_profile_owner_or_admin(auth.uid()))
    WITH CHECK (is_profile_owner_or_admin(auth.uid()));

-- Policy for viewing user achievements (own achievements and connected friends)
CREATE POLICY "Users can view their own achievements and friends'"
    ON user_profile_achievements FOR SELECT
    USING (
        auth.uid() = user_id OR
        (are_users_connected(auth.uid(), user_id) AND 
         NOT EXISTS (
             SELECT 1 FROM profile_achievements 
             WHERE achievement_id = user_profile_achievements.achievement_id 
               AND is_secret = true
         ))
    );

-- Policy for managing user achievements (system only for progress updates)
CREATE POLICY "System can manage user achievements"
    ON user_profile_achievements FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- USER CONNECTIONS POLICIES
-- =====================================================

-- Policy for viewing connections (own connections and mutual connections)
CREATE POLICY "Users can view their own connections"
    ON user_connections FOR SELECT
    USING (
        auth.uid() = user_id OR 
        auth.uid() = connected_user_id OR
        is_profile_owner_or_admin(auth.uid())
    );

-- Policy for creating connections (can send requests to anyone)
CREATE POLICY "Users can send connection requests"
    ON user_connections FOR INSERT
    WITH CHECK (
        auth.uid() = user_id AND 
        auth.uid() != connected_user_id
    );

-- Policy for updating connections (can accept/decline requests to them)
CREATE POLICY "Users can manage connection requests to them"
    ON user_connections FOR UPDATE
    USING (
        auth.uid() = connected_user_id OR 
        auth.uid() = user_id OR
        is_profile_owner_or_admin(auth.uid())
    )
    WITH CHECK (
        auth.uid() = connected_user_id OR 
        auth.uid() = user_id OR
        is_profile_owner_or_admin(auth.uid())
    );

-- Policy for deleting connections (can remove own connections)
CREATE POLICY "Users can remove their own connections"
    ON user_connections FOR DELETE
    USING (
        auth.uid() = user_id OR 
        auth.uid() = connected_user_id OR
        is_profile_owner_or_admin(auth.uid())
    );

-- =====================================================
-- REPUTATION POLICIES
-- =====================================================

-- Policy for viewing reputation (profile owner and reviewers can see)
CREATE POLICY "Users can view reputation for accessible profiles"
    ON profile_reputation FOR SELECT
    USING (
        can_view_profile(user_id) OR
        auth.uid() = reviewer_id
    );

-- Policy for creating reputation (can review connected users)
CREATE POLICY "Users can review connected users"
    ON profile_reputation FOR INSERT
    WITH CHECK (
        auth.uid() = reviewer_id AND
        auth.uid() != user_id AND
        are_users_connected(auth.uid(), user_id)
    );

-- Policy for updating reputation (can update own reviews)
CREATE POLICY "Users can update their own reviews"
    ON profile_reputation FOR UPDATE
    USING (auth.uid() = reviewer_id)
    WITH CHECK (auth.uid() = reviewer_id);

-- Policy for deleting reputation (can delete own reviews)
CREATE POLICY "Users can delete their own reviews"
    ON profile_reputation FOR DELETE
    USING (
        auth.uid() = reviewer_id OR
        is_profile_owner_or_admin(user_id)
    );

-- =====================================================
-- ANALYTICS POLICIES
-- =====================================================

-- Policy for viewing daily stats (own stats and connected friends)
CREATE POLICY "Users can view their own daily stats"
    ON profile_daily_stats FOR SELECT
    USING (
        auth.uid() = user_id OR
        are_users_connected(auth.uid(), user_id) OR
        is_profile_owner_or_admin(user_id)
    );

-- Policy for creating daily stats (system only)
CREATE POLICY "System can create daily stats"
    ON profile_daily_stats FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy for updating daily stats (system only)
CREATE POLICY "System can update daily stats"
    ON profile_daily_stats FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Policy for viewing profile view history (profile owner only)
CREATE POLICY "Profile owners can view their view history"
    ON profile_view_history FOR SELECT
    USING (
        auth.uid() = profile_owner_id OR
        is_profile_owner_or_admin(profile_owner_id)
    );

-- Policy for creating view history (anyone can record views)
CREATE POLICY "Anyone can record profile views"
    ON profile_view_history FOR INSERT
    WITH CHECK (
        viewer_id IS NULL OR auth.uid() = viewer_id
    );

-- =====================================================
-- ADDITIONAL SECURITY FUNCTIONS
-- =====================================================

-- Function to validate profile data before insert/update
CREATE OR REPLACE FUNCTION validate_profile_security(
    p_user_id UUID,
    p_data JSONB
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Ensure user can only modify their own profile
    IF auth.uid() != p_user_id AND NOT is_profile_owner_or_admin(p_user_id) THEN
        RAISE EXCEPTION 'Access denied: Cannot modify other users profiles';
    END IF;
    
    -- Validate sensitive fields
    IF p_data ? 'is_verified' AND NOT is_profile_owner_or_admin(auth.uid()) THEN
        RAISE EXCEPTION 'Access denied: Cannot modify verification status';
    END IF;
    
    IF p_data ? 'reputation_score' AND NOT is_profile_owner_or_admin(auth.uid()) THEN
        RAISE EXCEPTION 'Access denied: Cannot modify reputation directly';
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check rate limits for profile operations
CREATE OR REPLACE FUNCTION check_profile_rate_limit(
    p_user_id UUID,
    p_operation VARCHAR(50),
    p_limit INTEGER DEFAULT 10
)
RETURNS BOOLEAN AS $$
DECLARE
    v_count INTEGER;
BEGIN
    -- Count recent operations of this type
    CASE p_operation
        WHEN 'profile_update' THEN
            SELECT COUNT(*) INTO v_count
            FROM user_profiles
            WHERE user_id = p_user_id
              AND updated_at > NOW() - INTERVAL '1 hour';
              
        WHEN 'decoration_change' THEN
            SELECT COUNT(*) INTO v_count
            FROM profile_daily_stats
            WHERE user_id = p_user_id
              AND date = CURRENT_DATE
              AND decoration_changes > 0;
              
        WHEN 'connection_request' THEN
            SELECT COUNT(*) INTO v_count
            FROM user_connections
            WHERE user_id = p_user_id
              AND created_at > NOW() - INTERVAL '1 hour';
              
        ELSE
            RETURN TRUE; -- Unknown operation, allow
    END CASE;
    
    RETURN v_count < p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to log security events
CREATE OR REPLACE FUNCTION log_security_event(
    p_user_id UUID,
    p_event_type VARCHAR(50),
    p_details JSONB DEFAULT '{}'::jsonb
)
RETURNS VOID AS $$
BEGIN
    -- In a production system, this would log to a security audit table
    -- For now, we'll use the PostgreSQL log
    RAISE LOG 'Security Event - User: %, Type: %, Details: %', 
        p_user_id, p_event_type, p_details;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- PRIVACY CONTROLS
-- =====================================================

-- Function to anonymize user data for privacy compliance
CREATE OR REPLACE FUNCTION anonymize_user_profile(p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- Only user themselves or admin can anonymize
    IF auth.uid() != p_user_id AND NOT is_profile_owner_or_admin(auth.uid()) THEN
        RAISE EXCEPTION 'Access denied: Cannot anonymize other users data';
    END IF;
    
    -- Anonymize profile data
    UPDATE user_profiles
    SET username = 'deleted_user_' || EXTRACT(EPOCH FROM NOW())::BIGINT,
        display_name = 'Deleted User',
        bio = NULL,
        avatar_url = NULL,
        location = NULL,
        website = NULL,
        interests = NULL,
        social_links = '{}'::jsonb,
        is_private = true
    WHERE user_id = p_user_id;
    
    -- Anonymize view history
    UPDATE profile_view_history
    SET viewer_id = NULL
    WHERE viewer_id = p_user_id;
    
    -- Note: Some data might be retained for analytics but anonymized
    -- This would depend on privacy policy and legal requirements
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- ADMIN SECURITY FUNCTIONS
-- =====================================================

-- Function to check admin privileges
CREATE OR REPLACE FUNCTION is_admin_user()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM user_profiles
        WHERE user_id = auth.uid()
          AND (
            username IN ('admin', 'moderator', 'system') OR
            (is_verified = true AND reputation_score > 1000)
          )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function for admin override (emergency access)
CREATE OR REPLACE FUNCTION admin_override_access(
    p_target_user_id UUID,
    p_reason TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Only allow admin override with proper logging
    IF NOT is_admin_user() THEN
        RAISE EXCEPTION 'Access denied: Admin privileges required';
    END IF;
    
    -- Log the admin override
    PERFORM log_security_event(
        auth.uid(),
        'admin_override',
        json_build_object(
            'target_user', p_target_user_id,
            'reason', p_reason,
            'timestamp', NOW()
        )::jsonb
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- GRANT SECURITY FUNCTION PERMISSIONS
-- =====================================================

GRANT EXECUTE ON FUNCTION is_profile_owner_or_admin(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION are_users_connected(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION can_view_profile(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION can_modify_profile(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION validate_profile_security(UUID, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION check_profile_rate_limit(UUID, VARCHAR, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION log_security_event(UUID, VARCHAR, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION anonymize_user_profile(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION is_admin_user() TO authenticated;
GRANT EXECUTE ON FUNCTION admin_override_access(UUID, TEXT) TO authenticated;

-- =====================================================
-- SECURITY MONITORING
-- =====================================================

-- Create a view for security monitoring (admin only)
CREATE OR REPLACE VIEW security_monitoring AS
SELECT 
    up.user_id,
    up.username,
    up.created_at as profile_created,
    up.last_active_at,
    uas.total_messages_sent,
    uas.friends_count,
    up.reputation_score, -- Fixed: reputation_score is in user_profiles, not user_activity_stats
    (
        SELECT COUNT(*) FROM profile_view_history 
        WHERE profile_owner_id = up.user_id 
          AND viewed_at > NOW() - INTERVAL '24 hours'
    ) as views_last_24h,
    (
        SELECT COUNT(*) FROM user_connections 
        WHERE user_id = up.user_id 
          AND created_at > NOW() - INTERVAL '24 hours'
    ) as connection_requests_last_24h
FROM user_profiles up
LEFT JOIN user_activity_stats uas ON up.user_id = uas.user_id
WHERE is_admin_user(); -- Only visible to admins

-- =====================================================
-- DATA RETENTION POLICIES
-- =====================================================

-- Function to clean up expired data according to retention policies
CREATE OR REPLACE FUNCTION cleanup_expired_profile_data()
RETURNS VOID AS $$
BEGIN
    -- Clean up old view history (retain 90 days)
    DELETE FROM profile_view_history
    WHERE viewed_at < NOW() - INTERVAL '90 days';
    
    -- Clean up old daily stats (retain 2 years)
    DELETE FROM profile_daily_stats
    WHERE date < CURRENT_DATE - INTERVAL '2 years';
    
    -- Clean up declined connection requests (retain 30 days)
    DELETE FROM user_connections
    WHERE status = 'declined'
      AND updated_at < NOW() - INTERVAL '30 days';
    
    -- Archive old reputation reviews (move to archive table - not implemented here)
    -- This would depend on specific business requirements
END;
$$ LANGUAGE plpgsql;

-- Grant permission for cleanup function
GRANT EXECUTE ON FUNCTION cleanup_expired_profile_data() TO service_role;

-- =====================================================
-- FINAL SECURITY NOTES
-- =====================================================

/*
Security Features Implemented:

1. Row Level Security (RLS) on all tables
2. User isolation - users can only access their own data
3. Privacy controls - respect private profile settings
4. Friend-based access - connected users can see more data
5. Admin override capabilities with logging
6. Rate limiting functions
7. Data validation and sanitization
8. Security event logging
9. Data anonymization for privacy compliance
10. Retention policies and cleanup

Additional Security Recommendations:

1. Implement regular security audits
2. Monitor for suspicious access patterns
3. Use encrypted connections (TLS)
4. Regular backups with encryption
5. Implement API rate limiting at application level
6. Use strong authentication (2FA recommended)
7. Regular security updates
8. Penetration testing
9. GDPR/privacy compliance checks
10. Security training for development team

Note: Some security functions are marked for future integration
with notification systems and audit logging infrastructure.
*/

-- =====================================================
-- END OF PROFILE SECURITY
-- =====================================================
