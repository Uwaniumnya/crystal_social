-- Crystal Social UserInfo System - Security Policies
-- File: 04_userinfo_security_policies.sql
-- Purpose: Row Level Security (RLS) policies for user information system

-- =============================================================================
-- ENABLE ROW LEVEL SECURITY
-- =============================================================================

-- Enable RLS on all userinfo tables
ALTER TABLE user_info ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_info_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_category_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_discovery_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profile_completion ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_info_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_info_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_info_moderation ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- USER_INFO TABLE POLICIES
-- =============================================================================

-- Users can view their own user info
CREATE POLICY "Users can view own user info"
ON user_info FOR SELECT
USING (auth.uid() = user_id);

-- Users can insert their own user info
CREATE POLICY "Users can insert own user info"
ON user_info FOR INSERT
WITH CHECK (
    auth.uid() = user_id 
    AND user_id IS NOT NULL
);

-- Users can update their own user info
CREATE POLICY "Users can update own user info"
ON user_info FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Users can delete their own user info
CREATE POLICY "Users can delete own user info"
ON user_info FOR DELETE
USING (auth.uid() = user_id);

-- Public users can view discoverable user info (filtered)
CREATE POLICY "Public can view discoverable user info"
ON user_info FOR SELECT
USING (
    user_id IN (
        SELECT user_id 
        FROM user_discovery_settings 
        WHERE is_discoverable = true 
        AND privacy_level = 'public'
        AND allow_profile_views = true
    )
);

-- Admins can view all user info
CREATE POLICY "Admins can view all user info"
ON user_info FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND raw_user_meta_data->>'role' = 'admin'
    )
);

-- Moderators can view user info for moderation
CREATE POLICY "Moderators can view user info for moderation"
ON user_info FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND raw_user_meta_data->>'role' IN ('admin', 'moderator')
    )
);

-- =============================================================================
-- USER_INFO_CATEGORIES TABLE POLICIES
-- =============================================================================

-- Anyone can read active categories (they're public reference data)
CREATE POLICY "Anyone can read active categories"
ON user_info_categories FOR SELECT
USING (is_active = true);

-- Only admins can modify categories
CREATE POLICY "Admins can manage categories"
ON user_info_categories FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND raw_user_meta_data->>'role' = 'admin'
    )
);

-- =============================================================================
-- USER_CATEGORY_PREFERENCES TABLE POLICIES
-- =============================================================================

-- Users can view their own category preferences
CREATE POLICY "Users can view own category preferences"
ON user_category_preferences FOR SELECT
USING (auth.uid() = user_id);

-- Users can manage their own category preferences
CREATE POLICY "Users can manage own category preferences"
ON user_category_preferences FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own category preferences"
ON user_category_preferences FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own category preferences"
ON user_category_preferences FOR DELETE
USING (auth.uid() = user_id);

-- =============================================================================
-- USER_DISCOVERY_SETTINGS TABLE POLICIES
-- =============================================================================

-- Users can view their own discovery settings
CREATE POLICY "Users can view own discovery settings"
ON user_discovery_settings FOR SELECT
USING (auth.uid() = user_id);

-- Users can manage their own discovery settings
CREATE POLICY "Users can insert own discovery settings"
ON user_discovery_settings FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own discovery settings"
ON user_discovery_settings FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Admins can view all discovery settings for analytics
CREATE POLICY "Admins can view all discovery settings"
ON user_discovery_settings FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND raw_user_meta_data->>'role' = 'admin'
    )
);

-- =============================================================================
-- USER_PROFILE_COMPLETION TABLE POLICIES
-- =============================================================================

-- Users can view their own completion stats
CREATE POLICY "Users can view own completion stats"
ON user_profile_completion FOR SELECT
USING (auth.uid() = user_id);

-- System can update completion stats (via service role)
CREATE POLICY "System can manage completion stats"
ON user_profile_completion FOR ALL
USING (auth.role() = 'service_role');

-- Discoverable users' completion stats are visible to others
CREATE POLICY "Discoverable completion stats are public"
ON user_profile_completion FOR SELECT
USING (
    user_id IN (
        SELECT user_id 
        FROM user_discovery_settings 
        WHERE is_discoverable = true 
        AND show_completion_percentage = true
    )
);

-- =============================================================================
-- USER_INFO_INTERACTIONS TABLE POLICIES
-- =============================================================================

-- Users can view interactions where they are the viewer
CREATE POLICY "Users can view own viewing activity"
ON user_info_interactions FOR SELECT
USING (auth.uid() = viewer_user_id);

-- Users can view interactions on their profile (who viewed them)
CREATE POLICY "Users can view their profile interactions"
ON user_info_interactions FOR SELECT
USING (auth.uid() = viewed_user_id);

-- Users can record their own interactions
CREATE POLICY "Users can record own interactions"
ON user_info_interactions FOR INSERT
WITH CHECK (
    auth.uid() = viewer_user_id 
    AND viewer_user_id != viewed_user_id  -- Can't view your own profile
);

-- System can manage interactions for analytics
CREATE POLICY "System can manage interactions"
ON user_info_interactions FOR ALL
USING (auth.role() = 'service_role');

-- Admins can view all interactions
CREATE POLICY "Admins can view all interactions"
ON user_info_interactions FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND raw_user_meta_data->>'role' = 'admin'
    )
);

-- =============================================================================
-- USER_INFO_ANALYTICS TABLE POLICIES
-- =============================================================================

-- Users can view their own analytics
CREATE POLICY "Users can view own analytics"
ON user_info_analytics FOR SELECT
USING (auth.uid() = user_id);

-- System can manage analytics
CREATE POLICY "System can manage analytics"
ON user_info_analytics FOR ALL
USING (auth.role() = 'service_role');

-- Admins can view all analytics
CREATE POLICY "Admins can view all analytics"
ON user_info_analytics FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND raw_user_meta_data->>'role' = 'admin'
    )
);

-- =============================================================================
-- USER_INFO_MODERATION TABLE POLICIES
-- =============================================================================

-- Moderators and admins can view moderation data
CREATE POLICY "Moderators can view moderation data"
ON user_info_moderation FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND raw_user_meta_data->>'role' IN ('admin', 'moderator')
    )
);

-- Moderators can manage moderation records
CREATE POLICY "Moderators can manage moderation records"
ON user_info_moderation FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND raw_user_meta_data->>'role' IN ('admin', 'moderator')
    )
);

-- System can create automated moderation records
CREATE POLICY "System can create moderation records"
ON user_info_moderation FOR INSERT
WITH CHECK (auth.role() = 'service_role');

-- Users can view moderation status of their own content
CREATE POLICY "Users can view own content moderation status"
ON user_info_moderation FOR SELECT
USING (
    user_info_id IN (
        SELECT id FROM user_info WHERE user_id = auth.uid()
    )
);

-- =============================================================================
-- FUNCTION-BASED SECURITY
-- =============================================================================

-- Security function to check if user can view another user's profile
DROP FUNCTION IF EXISTS can_view_user_profile;
DROP FUNCTION IF EXISTS can_view_user_profile(UUID);
DROP FUNCTION IF EXISTS can_view_user_profile(text);
CREATE OR REPLACE FUNCTION can_view_user_profile(target_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    viewer_id UUID := auth.uid();
    is_discoverable BOOLEAN := false;
    privacy_level TEXT;
    allow_views BOOLEAN := false;
    is_admin BOOLEAN := false;
BEGIN
    -- Can always view own profile
    IF viewer_id = target_user_id THEN
        RETURN true;
    END IF;
    
    -- Check if viewer is admin
    SELECT raw_user_meta_data->>'role' = 'admin' INTO is_admin
    FROM auth.users WHERE id = viewer_id;
    
    IF is_admin THEN
        RETURN true;
    END IF;
    
    -- Check discovery settings
    SELECT 
        ds.is_discoverable,
        ds.privacy_level,
        ds.allow_profile_views
    INTO is_discoverable, privacy_level, allow_views
    FROM user_discovery_settings ds
    WHERE ds.user_id = target_user_id;
    
    -- Return true if user is discoverable and allows profile views
    RETURN COALESCE(is_discoverable, false) 
           AND COALESCE(allow_views, false) 
           AND COALESCE(privacy_level, 'private') = 'public';
END;
$$;

-- Security function to check content moderation level
CREATE OR REPLACE FUNCTION check_content_moderation_required(content_text TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    requires_review BOOLEAN := false;
    content_lower TEXT;
    word_count INTEGER;
BEGIN
    -- Basic content checks
    content_lower := LOWER(content_text);
    word_count := array_length(string_to_array(content_text, ' '), 1);
    
    -- Flag for review if:
    -- 1. Very long content (potential spam)
    IF LENGTH(content_text) > 1000 THEN
        requires_review := true;
    END IF;
    
    -- 2. Contains URLs (potential spam/phishing)
    IF content_lower ~ 'https?://|www\.|\.com|\.org|\.net' THEN
        requires_review := true;
    END IF;
    
    -- 3. Contains contact information patterns
    IF content_lower ~ '\d{3}[-.]?\d{3}[-.]?\d{4}|@\w+\.\w+' THEN
        requires_review := true;
    END IF;
    
    -- 4. Excessive capitalization (potential shouting/spam)
    IF LENGTH(content_text) > 20 AND 
       LENGTH(regexp_replace(content_text, '[^A-Z]', '', 'g')) > LENGTH(content_text) * 0.5 THEN
        requires_review := true;
    END IF;
    
    RETURN requires_review;
END;
$$;

-- Security function to check rate limiting
CREATE OR REPLACE FUNCTION check_user_rate_limit(user_id UUID, action_type TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    rate_limit_exceeded BOOLEAN := false;
    recent_actions INTEGER;
    time_window INTERVAL;
    max_actions INTEGER;
BEGIN
    -- Set rate limits based on action type
    CASE action_type
        WHEN 'create_user_info' THEN
            time_window := INTERVAL '1 hour';
            max_actions := 20;  -- 20 new items per hour
        WHEN 'update_user_info' THEN
            time_window := INTERVAL '1 hour';
            max_actions := 50;  -- 50 updates per hour
        WHEN 'profile_view' THEN
            time_window := INTERVAL '1 hour';
            max_actions := 100; -- 100 profile views per hour
        ELSE
            time_window := INTERVAL '1 hour';
            max_actions := 10;  -- Default conservative limit
    END CASE;
    
    -- Count recent actions based on type
    IF action_type = 'create_user_info' THEN
        SELECT COUNT(*) INTO recent_actions
        FROM user_info
        WHERE user_id = check_user_rate_limit.user_id
        AND created_at >= NOW() - time_window;
        
    ELSIF action_type = 'update_user_info' THEN
        SELECT COUNT(*) INTO recent_actions
        FROM user_info
        WHERE user_id = check_user_rate_limit.user_id
        AND updated_at >= NOW() - time_window;
        
    ELSIF action_type = 'profile_view' THEN
        SELECT COUNT(*) INTO recent_actions
        FROM user_info_interactions
        WHERE viewer_user_id = check_user_rate_limit.user_id
        AND interaction_type = 'profile_view'
        AND created_at >= NOW() - time_window;
    END IF;
    
    -- Check if rate limit exceeded
    rate_limit_exceeded := recent_actions >= max_actions;
    
    RETURN NOT rate_limit_exceeded;
END;
$$;

-- =============================================================================
-- PRIVACY AND DATA PROTECTION FUNCTIONS
-- =============================================================================

-- Function to anonymize user data for analytics
DROP FUNCTION IF EXISTS anonymize_user_data(UUID);
CREATE OR REPLACE FUNCTION anonymize_user_data(user_id UUID)
RETURNS TABLE(
    anonymous_id TEXT,
    completion_percentage DECIMAL,
    total_categories INTEGER,
    profile_quality_score DECIMAL,
    created_date DATE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'user_' || SUBSTR(MD5(user_id::TEXT), 1, 8) as anonymous_id,
        pc.completion_percentage,
        pc.total_categories_used as total_categories,
        pc.profile_quality_score,
        DATE(u.created_at) as created_date
    FROM auth.users u
    LEFT JOIN user_profile_completion pc ON u.id = pc.user_id
    WHERE u.id = anonymize_user_data.user_id;
END;
$$;

-- Function to export user data for GDPR compliance
DROP FUNCTION IF EXISTS export_user_data;
DROP FUNCTION IF EXISTS export_user_data(UUID);
DROP FUNCTION IF EXISTS export_user_data(text);
CREATE OR REPLACE FUNCTION export_user_data(target_user_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_data JSON;
    requester_id UUID := auth.uid();
BEGIN
    -- Only allow users to export their own data or admins
    IF requester_id != target_user_id AND 
       NOT EXISTS (
           SELECT 1 FROM auth.users 
           WHERE id = requester_id 
           AND raw_user_meta_data->>'role' = 'admin'
       ) THEN
        RAISE EXCEPTION 'Unauthorized: Can only export own data';
    END IF;
    
    -- Compile user data
    SELECT json_build_object(
        'user_profile', (
            SELECT json_build_object(
                'user_id', id,
                'email', email,
                'created_at', created_at,
                'updated_at', updated_at,
                'metadata', raw_user_meta_data
            ) FROM auth.users WHERE id = target_user_id
        ),
        'user_info', (
            SELECT json_agg(
                json_build_object(
                    'category', category,
                    'content', content,
                    'info_type', info_type,
                    'created_at', created_at,
                    'updated_at', updated_at
                )
            ) FROM user_info WHERE user_id = target_user_id
        ),
        'category_preferences', (
            SELECT json_agg(
                json_build_object(
                    'category_name', category_name,
                    'is_favorite', is_favorite,
                    'is_hidden', is_hidden,
                    'custom_order', custom_order,
                    'access_count', access_count
                )
            ) FROM user_category_preferences WHERE user_id = target_user_id
        ),
        'discovery_settings', (
            SELECT json_build_object(
                'is_discoverable', is_discoverable,
                'privacy_level', privacy_level,
                'allow_profile_views', allow_profile_views,
                'show_completion_percentage', show_completion_percentage
            ) FROM user_discovery_settings WHERE user_id = target_user_id
        ),
        'profile_completion', (
            SELECT json_build_object(
                'completion_percentage', completion_percentage,
                'total_categories_used', total_categories_used,
                'total_items_count', total_items_count,
                'profile_quality_score', profile_quality_score
            ) FROM user_profile_completion WHERE user_id = target_user_id
        ),
        'interaction_history', (
            SELECT json_agg(
                json_build_object(
                    'interaction_type', interaction_type,
                    'viewed_user_id', viewed_user_id,
                    'category_name', category_name,
                    'view_duration_seconds', view_duration_seconds,
                    'created_at', created_at
                )
            ) FROM user_info_interactions WHERE viewer_user_id = target_user_id
        )
    ) INTO user_data;
    
    RETURN user_data;
END;
$$;

-- Function to delete user data for GDPR compliance
DROP FUNCTION IF EXISTS delete_user_data;
DROP FUNCTION IF EXISTS delete_user_data(UUID);
DROP FUNCTION IF EXISTS delete_user_data(text);
CREATE OR REPLACE FUNCTION delete_user_data(target_user_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    requester_id UUID := auth.uid();
    items_deleted INTEGER := 0;
    temp_count INTEGER;
BEGIN
    -- Only allow users to delete their own data or admins
    IF requester_id != target_user_id AND 
       NOT EXISTS (
           SELECT 1 FROM auth.users 
           WHERE id = requester_id 
           AND raw_user_meta_data->>'role' = 'admin'
       ) THEN
        RAISE EXCEPTION 'Unauthorized: Can only delete own data';
    END IF;
    
    -- Delete user data in order (respecting foreign keys)
    DELETE FROM user_info_interactions WHERE viewer_user_id = target_user_id OR viewed_user_id = target_user_id;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    items_deleted := items_deleted + temp_count;
    
    DELETE FROM user_info_analytics WHERE user_id = target_user_id;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    items_deleted := items_deleted + temp_count;
    
    DELETE FROM user_info_moderation WHERE user_info_id IN (
        SELECT id FROM user_info WHERE user_id = target_user_id
    );
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    items_deleted := items_deleted + temp_count;
    
    DELETE FROM user_profile_completion WHERE user_id = target_user_id;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    items_deleted := items_deleted + temp_count;
    
    DELETE FROM user_discovery_settings WHERE user_id = target_user_id;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    items_deleted := items_deleted + temp_count;
    
    DELETE FROM user_category_preferences WHERE user_id = target_user_id;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    items_deleted := items_deleted + temp_count;
    
    DELETE FROM user_info WHERE user_id = target_user_id;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    items_deleted := items_deleted + temp_count;
    
    RETURN 'Successfully deleted ' || items_deleted || ' records for user ' || target_user_id;
END;
$$;

-- =============================================================================
-- GRANT PERMISSIONS FOR SECURITY FUNCTIONS
-- =============================================================================

-- Grant permissions for security functions
GRANT EXECUTE ON FUNCTION can_view_user_profile TO authenticated;
GRANT EXECUTE ON FUNCTION check_content_moderation_required TO authenticated;
GRANT EXECUTE ON FUNCTION check_user_rate_limit TO authenticated;
GRANT EXECUTE ON FUNCTION anonymize_user_data TO service_role;
GRANT EXECUTE ON FUNCTION export_user_data TO authenticated;
GRANT EXECUTE ON FUNCTION delete_user_data TO authenticated;

-- =============================================================================
-- SECURITY MONITORING AND LOGGING
-- =============================================================================

-- Create security audit log table
CREATE TABLE IF NOT EXISTS user_info_security_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    action_type TEXT NOT NULL,
    resource_type TEXT NOT NULL,
    resource_id TEXT,
    success BOOLEAN NOT NULL DEFAULT true,
    error_message TEXT,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on security log
ALTER TABLE user_info_security_log ENABLE ROW LEVEL SECURITY;

-- Only admins can view security logs
CREATE POLICY "Admins can view security logs"
ON user_info_security_log FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND raw_user_meta_data->>'role' = 'admin'
    )
);

-- System can write to security log
CREATE POLICY "System can write security logs"
ON user_info_security_log FOR INSERT
WITH CHECK (auth.role() = 'service_role');

-- Function to log security events
CREATE OR REPLACE FUNCTION log_security_event(
    p_user_id UUID,
    p_action_type TEXT,
    p_resource_type TEXT,
    p_resource_id TEXT DEFAULT NULL,
    p_success BOOLEAN DEFAULT true,
    p_error_message TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO user_info_security_log (
        user_id,
        action_type,
        resource_type,
        resource_id,
        success,
        error_message,
        ip_address,
        user_agent
    ) VALUES (
        p_user_id,
        p_action_type,
        p_resource_type,
        p_resource_id,
        p_success,
        p_error_message,
        COALESCE(current_setting('request.headers', true)::json->>'x-forwarded-for', '0.0.0.0')::inet,
        current_setting('request.headers', true)::json->>'user-agent'
    );
END;
$$;

-- Grant execution permission
GRANT EXECUTE ON FUNCTION log_security_event TO service_role;

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON FUNCTION can_view_user_profile IS 'Check if authenticated user can view another users profile based on privacy settings';
COMMENT ON FUNCTION check_content_moderation_required IS 'Analyze content to determine if moderation review is required';
COMMENT ON FUNCTION check_user_rate_limit IS 'Check if user has exceeded rate limits for specific actions';
COMMENT ON FUNCTION anonymize_user_data IS 'Return anonymized user data for analytics while protecting privacy';
COMMENT ON FUNCTION export_user_data IS 'Export all user data in JSON format for GDPR compliance';
COMMENT ON FUNCTION delete_user_data IS 'Permanently delete all user data for GDPR compliance';
COMMENT ON FUNCTION log_security_event IS 'Log security-related events for audit trail';

COMMENT ON TABLE user_info_security_log IS 'Audit log for security events in the userinfo system';

-- Setup completion message
SELECT 'UserInfo Security Policies Setup Complete!' as status, NOW() as setup_completed_at;
