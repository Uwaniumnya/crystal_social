-- =====================================================
-- CRYSTAL SOCIAL - PROFILE SYSTEM EXTENDED SECURITY
-- =====================================================
-- Additional security policies for missing functionality
-- discovered in avatar_picker, sound systems, and files
-- =====================================================

-- =====================================================
-- ASSET MANAGEMENT SECURITY
-- =====================================================

-- Row Level Security for preset_avatars
ALTER TABLE preset_avatars ENABLE ROW LEVEL SECURITY;

-- Public read access to active preset avatars
CREATE POLICY "preset_avatars_public_read" ON preset_avatars
    FOR SELECT TO authenticated
    USING (is_active = true);

-- Admin access for preset avatar management
CREATE POLICY "preset_avatars_admin_access" ON preset_avatars
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND is_admin = true
        )
    );

-- Row Level Security for user_avatar_uploads
ALTER TABLE user_avatar_uploads ENABLE ROW LEVEL SECURITY;

-- Users can manage their own avatar uploads
CREATE POLICY "avatar_uploads_user_access" ON user_avatar_uploads
    FOR ALL TO authenticated
    USING (user_id = auth.uid());

-- Admins can view all avatar uploads for moderation
CREATE POLICY "avatar_uploads_admin_view" ON user_avatar_uploads
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND is_admin = true
        )
    );

-- Row Level Security for sound_catalog
ALTER TABLE sound_catalog ENABLE ROW LEVEL SECURITY;

-- Public read access to active sounds
CREATE POLICY "sound_catalog_public_read" ON sound_catalog
    FOR SELECT TO authenticated
    USING (is_active = true);

-- Admin access for sound catalog management
CREATE POLICY "sound_catalog_admin_access" ON sound_catalog
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND is_admin = true
        )
    );

-- Row Level Security for user_sound_inventory
ALTER TABLE user_sound_inventory ENABLE ROW LEVEL SECURITY;

-- Users can manage their own sound inventory
CREATE POLICY "sound_inventory_user_access" ON user_sound_inventory
    FOR ALL TO authenticated
    USING (user_id = auth.uid());

-- =====================================================
-- USER INVENTORY SECURITY
-- =====================================================

-- Row Level Security for user_inventory
ALTER TABLE user_inventory ENABLE ROW LEVEL SECURITY;

-- Users can manage their own inventory
CREATE POLICY "inventory_user_access" ON user_inventory
    FOR ALL TO authenticated
    USING (user_id = auth.uid());

-- Friends can view equipped items for social features
CREATE POLICY "inventory_friends_view_equipped" ON user_inventory
    FOR SELECT TO authenticated
    USING (
        equipped = true AND (
            user_id = auth.uid() OR
            EXISTS (
                SELECT 1 FROM user_connections uc
                WHERE ((uc.user_id = auth.uid() AND uc.connected_user_id = user_inventory.user_id) OR
                       (uc.connected_user_id = auth.uid() AND uc.user_id = user_inventory.user_id))
                AND uc.status = 'accepted'
            )
        )
    );

-- =====================================================
-- ENHANCED PROFILE SECURITY
-- =====================================================

-- Row Level Security for user_social_links
ALTER TABLE user_social_links ENABLE ROW LEVEL SECURITY;

-- Users can manage their own social links
CREATE POLICY "social_links_user_access" ON user_social_links
    FOR ALL TO authenticated
    USING (user_id = auth.uid());

-- Public social links are viewable by all authenticated users
CREATE POLICY "social_links_public_read" ON user_social_links
    FOR SELECT TO authenticated
    USING (is_public = true);

-- Row Level Security for user_profile_extensions
ALTER TABLE user_profile_extensions ENABLE ROW LEVEL SECURITY;

-- Users can manage their own profile extensions
CREATE POLICY "profile_extensions_user_access" ON user_profile_extensions
    FOR ALL TO authenticated
    USING (user_id = auth.uid());

-- Public profile extensions viewable based on privacy settings
CREATE POLICY "profile_extensions_public_read" ON user_profile_extensions
    FOR SELECT TO authenticated
    USING (
        user_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM user_privacy_settings ups
            WHERE ups.user_id = user_profile_extensions.user_id
            AND ups.profile_visibility = 'public'
        ) OR
        EXISTS (
            SELECT 1 FROM user_privacy_settings ups, user_connections uc
            WHERE ups.user_id = user_profile_extensions.user_id
            AND ups.profile_visibility = 'friends'
            AND ((uc.user_id = auth.uid() AND uc.connected_user_id = user_profile_extensions.user_id) OR
                 (uc.connected_user_id = auth.uid() AND uc.user_id = user_profile_extensions.user_id))
            AND uc.status = 'accepted'
        )
    );

-- Row Level Security for user_privacy_settings
ALTER TABLE user_privacy_settings ENABLE ROW LEVEL SECURITY;

-- Users can manage their own privacy settings
CREATE POLICY "privacy_settings_user_access" ON user_privacy_settings
    FOR ALL TO authenticated
    USING (user_id = auth.uid());

-- Row Level Security for profile_edit_history
ALTER TABLE profile_edit_history ENABLE ROW LEVEL SECURITY;

-- Users can view their own edit history
CREATE POLICY "edit_history_user_view" ON profile_edit_history
    FOR SELECT TO authenticated
    USING (user_id = auth.uid());

-- Admins can view all edit history for moderation
CREATE POLICY "edit_history_admin_view" ON profile_edit_history
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND is_admin = true
        )
    );

-- =====================================================
-- SYSTEM CONFIGURATION SECURITY
-- =====================================================

-- Row Level Security for system_configuration
ALTER TABLE system_configuration ENABLE ROW LEVEL SECURITY;

-- Only admins can access system configuration
CREATE POLICY "system_config_admin_only" ON system_configuration
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND is_admin = true
        )
    );

-- Row Level Security for performance_metrics
ALTER TABLE performance_metrics ENABLE ROW LEVEL SECURITY;

-- Users can view their own performance metrics
CREATE POLICY "performance_metrics_user_view" ON performance_metrics
    FOR SELECT TO authenticated
    USING (user_id = auth.uid());

-- Service role can insert performance metrics
CREATE POLICY "performance_metrics_service_insert" ON performance_metrics
    FOR INSERT TO service_role
    WITH CHECK (true);

-- Admins can view all performance metrics
CREATE POLICY "performance_metrics_admin_view" ON performance_metrics
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND is_admin = true
        )
    );

-- Row Level Security for validation_logs
ALTER TABLE validation_logs ENABLE ROW LEVEL SECURITY;

-- Only admins can access validation logs
CREATE POLICY "validation_logs_admin_only" ON validation_logs
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND is_admin = true
        )
    );

-- Service role can insert validation logs
CREATE POLICY "validation_logs_service_insert" ON validation_logs
    FOR INSERT TO service_role
    WITH CHECK (true);

-- =====================================================
-- PREMIUM CONTENT SECURITY
-- =====================================================

-- Row Level Security for premium_content
ALTER TABLE premium_content ENABLE ROW LEVEL SECURITY;

-- Public read access to active premium content
CREATE POLICY "premium_content_public_read" ON premium_content
    FOR SELECT TO authenticated
    USING (is_active = true);

-- Admin access for premium content management
CREATE POLICY "premium_content_admin_access" ON premium_content
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND is_admin = true
        )
    );

-- Row Level Security for user_premium_purchases
ALTER TABLE user_premium_purchases ENABLE ROW LEVEL SECURITY;

-- Users can view their own purchases
CREATE POLICY "premium_purchases_user_view" ON user_premium_purchases
    FOR SELECT TO authenticated
    USING (user_id = auth.uid());

-- Users can insert their own purchases
CREATE POLICY "premium_purchases_user_insert" ON user_premium_purchases
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());

-- Admins can view all purchases for support
CREATE POLICY "premium_purchases_admin_view" ON user_premium_purchases
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND is_admin = true
        )
    );

-- =====================================================
-- ADVANCED FEATURES SECURITY
-- =====================================================

-- Row Level Security for profile_theme_assets
ALTER TABLE profile_theme_assets ENABLE ROW LEVEL SECURITY;

-- Public read access to active theme assets
CREATE POLICY "theme_assets_public_read" ON profile_theme_assets
    FOR SELECT TO authenticated
    USING (is_active = true);

-- Admin access for theme asset management
CREATE POLICY "theme_assets_admin_access" ON profile_theme_assets
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND is_admin = true
        )
    );

-- Row Level Security for user_custom_ringtones
ALTER TABLE user_custom_ringtones ENABLE ROW LEVEL SECURITY;

-- Users can manage their own custom ringtones
CREATE POLICY "custom_ringtones_user_access" ON user_custom_ringtones
    FOR ALL TO authenticated
    USING (owner_id = auth.uid());

-- Row Level Security for profile_completion_tracking
ALTER TABLE profile_completion_tracking ENABLE ROW LEVEL SECURITY;

-- Users can view their own completion tracking
CREATE POLICY "completion_tracking_user_view" ON profile_completion_tracking
    FOR SELECT TO authenticated
    USING (user_id = auth.uid());

-- System can insert completion tracking
CREATE POLICY "completion_tracking_system_insert" ON profile_completion_tracking
    FOR INSERT TO service_role
    WITH CHECK (true);

-- System can update completion tracking
CREATE POLICY "completion_tracking_system_update" ON profile_completion_tracking
    FOR UPDATE TO service_role
    USING (true)
    WITH CHECK (true);

-- =====================================================
-- SECURITY HELPER FUNCTIONS
-- =====================================================

-- Function to check if user can view another user's profile
CREATE OR REPLACE FUNCTION can_view_user_profile(
    p_viewer_id UUID,
    p_profile_user_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_privacy_visibility VARCHAR(20);
    v_is_friend BOOLEAN := false;
BEGIN
    -- User can always view their own profile
    IF p_viewer_id = p_profile_user_id THEN
        RETURN true;
    END IF;
    
    -- Get privacy settings
    SELECT profile_visibility INTO v_privacy_visibility
    FROM user_privacy_settings
    WHERE user_id = p_profile_user_id;
    
    -- Default to public if no privacy settings
    v_privacy_visibility := COALESCE(v_privacy_visibility, 'public');
    
    -- Check if public
    IF v_privacy_visibility = 'public' THEN
        RETURN true;
    END IF;
    
    -- Check if private
    IF v_privacy_visibility = 'private' THEN
        RETURN false;
    END IF;
    
    -- Check if friends only
    IF v_privacy_visibility = 'friends' THEN
        SELECT EXISTS (
            SELECT 1 FROM user_connections
            WHERE ((user_id = p_viewer_id AND connected_user_id = p_profile_user_id) OR
                   (connected_user_id = p_viewer_id AND user_id = p_profile_user_id))
            AND status = 'accepted'
        ) INTO v_is_friend;
        
        RETURN v_is_friend;
    END IF;
    
    RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user can edit content
CREATE OR REPLACE FUNCTION can_edit_content(
    p_user_id UUID,
    p_content_type VARCHAR(50)
)
RETURNS BOOLEAN AS $$
DECLARE
    v_is_admin BOOLEAN;
    v_is_moderator BOOLEAN;
BEGIN
    -- Get user admin/moderator status from profiles table
    SELECT is_admin, is_moderator INTO v_is_admin, v_is_moderator
    FROM profiles
    WHERE id = p_user_id;
    
    -- Admins can edit everything
    IF v_is_admin = true THEN
        RETURN true;
    END IF;
    
    -- Moderators can edit certain content
    IF v_is_moderator = true AND p_content_type IN (
        'user_profiles', 'avatar_uploads', 'social_links'
    ) THEN
        RETURN true;
    END IF;
    
    RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to validate file upload permissions
CREATE OR REPLACE FUNCTION validate_upload_permissions(
    p_user_id UUID,
    p_file_type VARCHAR(50),
    p_file_size BIGINT
)
RETURNS JSON AS $$
DECLARE
    v_max_size BIGINT;
    v_upload_count INTEGER;
    v_result JSON;
BEGIN
    -- Check file size limits
    v_max_size := CASE p_file_type
        WHEN 'avatar' THEN 5242880  -- 5MB
        WHEN 'sound' THEN 1048576   -- 1MB
        ELSE 2097152                -- 2MB default
    END;
    
    IF p_file_size > v_max_size THEN
        RETURN json_build_object(
            'allowed', false,
            'error', 'File size exceeds limit',
            'max_size', v_max_size
        );
    END IF;
    
    -- Check upload frequency (max 10 uploads per hour)
    SELECT COUNT(*) INTO v_upload_count
    FROM user_avatar_uploads
    WHERE user_id = p_user_id
    AND created_at > NOW() - INTERVAL '1 hour';
    
    IF v_upload_count >= 10 THEN
        RETURN json_build_object(
            'allowed', false,
            'error', 'Upload rate limit exceeded',
            'retry_after', '1 hour'
        );
    END IF;
    
    RETURN json_build_object(
        'allowed', true,
        'message', 'Upload permitted'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- DATA VALIDATION FUNCTIONS
-- =====================================================

-- Function to validate profile data integrity
CREATE OR REPLACE FUNCTION validate_profile_data(
    p_user_id UUID
)
RETURNS JSON AS $$
DECLARE
    v_issues TEXT[] := '{}';
    v_warnings TEXT[] := '{}';
    v_profile RECORD;
    v_result JSON;
BEGIN
    -- Get profile data
    SELECT * INTO v_profile
    FROM user_profiles
    WHERE user_id = p_user_id;
    
    IF NOT FOUND THEN
        v_issues := array_append(v_issues, 'Profile not found');
        RETURN json_build_object(
            'valid', false,
            'issues', v_issues,
            'warnings', v_warnings
        );
    END IF;
    
    -- Validate username
    IF v_profile.username IS NULL OR LENGTH(v_profile.username) < 3 THEN
        v_issues := array_append(v_issues, 'Username too short or missing');
    END IF;
    
    IF v_profile.username ~ '[^a-zA-Z0-9_]' THEN
        v_issues := array_append(v_issues, 'Username contains invalid characters');
    END IF;
    
    -- Validate bio length
    IF v_profile.bio IS NOT NULL AND LENGTH(v_profile.bio) > 500 THEN
        v_issues := array_append(v_issues, 'Bio exceeds maximum length');
    END IF;
    
    -- Validate interests count
    IF v_profile.interests IS NOT NULL AND array_length(v_profile.interests, 1) > 20 THEN
        v_warnings := array_append(v_warnings, 'Too many interests selected');
    END IF;
    
    -- Validate completion percentage
    IF v_profile.profile_completion_percentage < 0 OR v_profile.profile_completion_percentage > 100 THEN
        v_issues := array_append(v_issues, 'Invalid completion percentage');
    END IF;
    
    -- Check for orphaned data
    IF NOT EXISTS (SELECT 1 FROM user_privacy_settings WHERE user_id = p_user_id) THEN
        v_warnings := array_append(v_warnings, 'No privacy settings configured');
    END IF;
    
    v_result := json_build_object(
        'valid', array_length(v_issues, 1) = 0,
        'issues', v_issues,
        'warnings', v_warnings,
        'validation_timestamp', NOW()
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- AUDIT AND MONITORING FUNCTIONS
-- =====================================================

-- Function to log security events
CREATE OR REPLACE FUNCTION log_security_event(
    p_user_id UUID,
    p_event_type VARCHAR(100),
    p_event_data JSONB DEFAULT '{}',
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_log_id UUID;
BEGIN
    INSERT INTO validation_logs (
        validation_type, component_name, validation_result,
        validation_metadata, performed_by
    ) VALUES (
        'security_event', p_event_type, 'logged',
        json_build_object(
            'user_id', p_user_id,
            'event_data', p_event_data,
            'ip_address', p_ip_address,
            'user_agent', p_user_agent,
            'timestamp', NOW()
        )::jsonb,
        p_user_id
    ) RETURNING id INTO v_log_id;
    
    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to detect suspicious activity
CREATE OR REPLACE FUNCTION detect_suspicious_activity(
    p_user_id UUID
)
RETURNS JSON AS $$
DECLARE
    v_recent_uploads INTEGER;
    v_recent_edits INTEGER;
    v_suspicious_patterns TEXT[] := '{}';
    v_risk_score INTEGER := 0;
BEGIN
    -- Check upload frequency
    SELECT COUNT(*) INTO v_recent_uploads
    FROM user_avatar_uploads
    WHERE user_id = p_user_id
    AND created_at > NOW() - INTERVAL '1 hour';
    
    IF v_recent_uploads > 5 THEN
        v_suspicious_patterns := array_append(v_suspicious_patterns, 'High upload frequency');
        v_risk_score := v_risk_score + 20;
    END IF;
    
    -- Check profile edit frequency
    SELECT COUNT(*) INTO v_recent_edits
    FROM profile_edit_history
    WHERE user_id = p_user_id
    AND edited_at > NOW() - INTERVAL '1 hour';
    
    IF v_recent_edits > 10 THEN
        v_suspicious_patterns := array_append(v_suspicious_patterns, 'Rapid profile changes');
        v_risk_score := v_risk_score + 15;
    END IF;
    
    -- Log if suspicious
    IF v_risk_score > 20 THEN
        PERFORM log_security_event(
            p_user_id,
            'suspicious_activity_detected',
            json_build_object(
                'risk_score', v_risk_score,
                'patterns', v_suspicious_patterns
            )::jsonb
        );
    END IF;
    
    RETURN json_build_object(
        'suspicious', v_risk_score > 20,
        'risk_score', v_risk_score,
        'patterns', v_suspicious_patterns
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- RATE LIMITING FUNCTIONS
-- =====================================================

-- Function to check rate limits
CREATE OR REPLACE FUNCTION check_rate_limit(
    p_user_id UUID,
    p_action VARCHAR(100),
    p_max_attempts INTEGER,
    p_time_window_minutes INTEGER
)
RETURNS JSON AS $$
DECLARE
    v_attempt_count INTEGER;
    v_allowed BOOLEAN;
BEGIN
    -- Count recent attempts
    SELECT COUNT(*) INTO v_attempt_count
    FROM validation_logs
    WHERE validation_metadata->>'user_id' = p_user_id::TEXT
    AND component_name = p_action
    AND performed_at > NOW() - INTERVAL '1 minute' * p_time_window_minutes;
    
    v_allowed := v_attempt_count < p_max_attempts;
    
    -- Log the attempt
    PERFORM log_security_event(
        p_user_id,
        'rate_limit_check',
        json_build_object(
            'action', p_action,
            'attempts', v_attempt_count,
            'max_attempts', p_max_attempts,
            'allowed', v_allowed
        )::jsonb
    );
    
    RETURN json_build_object(
        'allowed', v_allowed,
        'attempts_remaining', GREATEST(0, p_max_attempts - v_attempt_count),
        'reset_time', NOW() + INTERVAL '1 minute' * p_time_window_minutes
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- GRANTS AND PERMISSIONS
-- =====================================================

-- Grant permissions for security functions
GRANT EXECUTE ON FUNCTION can_view_user_profile(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION can_edit_content(UUID, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION validate_upload_permissions(UUID, VARCHAR, BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION validate_profile_data(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION check_rate_limit(UUID, VARCHAR, INTEGER, INTEGER) TO authenticated;

-- Grant service role permissions for monitoring
GRANT EXECUTE ON FUNCTION log_security_event(UUID, VARCHAR, JSONB, INET, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION detect_suspicious_activity(UUID) TO service_role;

-- =====================================================
-- SECURITY CONFIGURATION
-- =====================================================

-- Create security configuration entries
INSERT INTO system_configuration (config_category, config_key, config_value, description) VALUES
('security', 'max_upload_rate', '10', 'Maximum file uploads per hour per user'),
('security', 'max_profile_edits', '20', 'Maximum profile edits per hour per user'),
('security', 'session_timeout_minutes', '60', 'User session timeout in minutes'),
('security', 'enable_audit_logging', 'true', 'Enable comprehensive audit logging'),
('security', 'suspicious_activity_threshold', '25', 'Risk score threshold for flagging activity')
ON CONFLICT (config_category, config_key, environment) DO NOTHING;

-- =====================================================
-- END OF EXTENDED SECURITY
-- =====================================================
