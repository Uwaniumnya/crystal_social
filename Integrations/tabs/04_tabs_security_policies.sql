-- Crystal Social Tabs System - Security Policies and Triggers
-- File: 04_tabs_security_policies.sql
-- Purpose: Row Level Security policies, triggers, and security functions for comprehensive tabs system

-- =============================================================================
-- ENABLE ROW LEVEL SECURITY
-- =============================================================================

-- Enable RLS on all tables
ALTER TABLE tab_definitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_tab_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE tab_usage_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_tab_usage_summary ENABLE ROW LEVEL SECURITY;
ALTER TABLE home_screen_apps ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_home_screen_layout ENABLE ROW LEVEL SECURITY;
ALTER TABLE glitter_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE glitter_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE glitter_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE zodiac_signs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_horoscope_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE horoscope_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE tarot_decks ENABLE ROW LEVEL SECURITY;
ALTER TABLE tarot_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE tarot_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE oracle_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE oracle_consultations ENABLE ROW LEVEL SECURITY;
ALTER TABLE magic_8ball_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE magic_8ball_consultations ENABLE ROW LEVEL SECURITY;
ALTER TABLE confessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE poll_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE poll_votes ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- TAB SYSTEM SECURITY POLICIES
-- =============================================================================

-- Tab definitions: Public read for active tabs
CREATE POLICY "tab_definitions_public_read" ON tab_definitions
    FOR SELECT
    USING (is_enabled = true AND is_production_ready = true);

-- Tab definitions: Service role can manage all
CREATE POLICY "tab_definitions_service_manage" ON tab_definitions
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- User tab preferences: Users can manage their own
CREATE POLICY "user_tab_preferences_own_data" ON user_tab_preferences
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Tab usage analytics: Users can insert their own, service can read all
CREATE POLICY "tab_usage_own_insert" ON tab_usage_analytics
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "tab_usage_service_read" ON tab_usage_analytics
    FOR SELECT
    TO service_role
    USING (true);

-- Daily usage summary: Users can read their own, service can manage all
CREATE POLICY "daily_usage_own_read" ON daily_tab_usage_summary
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "daily_usage_service_manage" ON daily_tab_usage_summary
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- =============================================================================
-- HOME SCREEN SECURITY POLICIES
-- =============================================================================

-- Home screen apps: Public read for active apps
CREATE POLICY "home_apps_public_read" ON home_screen_apps
    FOR SELECT
    USING (is_enabled = true);

-- Home screen apps: Service role can manage
CREATE POLICY "home_apps_service_manage" ON home_screen_apps
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- User home layout: Users can manage their own
CREATE POLICY "home_layout_own_data" ON user_home_screen_layout
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- =============================================================================
-- SOCIAL MEDIA SECURITY POLICIES
-- =============================================================================

-- Glitter posts: Public read for non-deleted public posts
CREATE POLICY "glitter_posts_public_read" ON glitter_posts
    FOR SELECT
    USING (
        is_deleted = false AND 
        visibility = 'public'
    );

-- Glitter posts: Users can read their own posts regardless of visibility
CREATE POLICY "glitter_posts_own_read" ON glitter_posts
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- Glitter posts: Users can create their own posts
CREATE POLICY "glitter_posts_own_create" ON glitter_posts
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- Glitter posts: Users can update their own posts
CREATE POLICY "glitter_posts_own_update" ON glitter_posts
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Glitter comments: Public read for non-deleted comments on public posts
CREATE POLICY "glitter_comments_public_read" ON glitter_comments
    FOR SELECT
    USING (
        is_deleted = false AND
        EXISTS (
            SELECT 1 FROM glitter_posts gp 
            WHERE gp.id = post_id 
            AND gp.is_deleted = false 
            AND gp.visibility = 'public'
        )
    );

-- Glitter comments: Users can read comments on their own posts
CREATE POLICY "glitter_comments_own_posts_read" ON glitter_comments
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM glitter_posts gp 
            WHERE gp.id = post_id 
            AND gp.user_id = auth.uid()
        )
    );

-- Glitter comments: Users can create comments on public posts
CREATE POLICY "glitter_comments_create" ON glitter_comments
    FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() = user_id AND
        EXISTS (
            SELECT 1 FROM glitter_posts gp 
            WHERE gp.id = post_id 
            AND gp.is_deleted = false 
            AND gp.visibility = 'public'
        )
    );

-- Glitter comments: Users can update their own comments
CREATE POLICY "glitter_comments_own_update" ON glitter_comments
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Glitter reactions: Public read
CREATE POLICY "glitter_reactions_public_read" ON glitter_reactions
    FOR SELECT
    USING (true);

-- Glitter reactions: Users can manage their own reactions
CREATE POLICY "glitter_reactions_own_manage" ON glitter_reactions
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- =============================================================================
-- HOROSCOPE SYSTEM SECURITY POLICIES
-- =============================================================================

-- Zodiac signs: Public read
CREATE POLICY "zodiac_signs_public_read" ON zodiac_signs
    FOR SELECT
    USING (true);

-- User horoscope preferences: Users can manage their own
CREATE POLICY "horoscope_prefs_own_data" ON user_horoscope_preferences
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Horoscope readings: Public read for current and recent readings
CREATE POLICY "horoscope_readings_public_read" ON horoscope_readings
    FOR SELECT
    USING (reading_date >= CURRENT_DATE - INTERVAL '7 days');

-- =============================================================================
-- TAROT SYSTEM SECURITY POLICIES
-- =============================================================================

-- Tarot decks: Public read for available decks
CREATE POLICY "tarot_decks_public_read" ON tarot_decks
    FOR SELECT
    USING (true);

-- Tarot cards: Public read for available cards
CREATE POLICY "tarot_cards_public_read" ON tarot_cards
    FOR SELECT
    USING (true);

-- Tarot readings: Users can read their own readings
CREATE POLICY "tarot_readings_own_read" ON tarot_readings
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- Tarot readings: Users can create their own readings
CREATE POLICY "tarot_readings_own_create" ON tarot_readings
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- =============================================================================
-- ORACLE SYSTEM SECURITY POLICIES
-- =============================================================================

-- Oracle messages: Public read
CREATE POLICY "oracle_messages_public_read" ON oracle_messages
    FOR SELECT
    USING (true);

-- Oracle consultations: Users can manage their own
CREATE POLICY "oracle_consultations_own_data" ON oracle_consultations
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- =============================================================================
-- MAGIC 8-BALL SECURITY POLICIES
-- =============================================================================

-- Magic 8-ball responses: Public read
CREATE POLICY "magic_8ball_responses_public_read" ON magic_8ball_responses
    FOR SELECT
    USING (true);

-- Magic 8-ball consultations: Users can manage their own
CREATE POLICY "magic_8ball_consultations_own_data" ON magic_8ball_consultations
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- =============================================================================
-- CONFESSION SYSTEM SECURITY POLICIES
-- =============================================================================

-- Confessions: Public read for approved confessions (anonymous protection)
CREATE POLICY "confessions_public_read" ON confessions
    FOR SELECT
    USING (is_approved = true);

-- Confessions: Users can create confessions
CREATE POLICY "confessions_create" ON confessions
    FOR INSERT
    TO authenticated
    WITH CHECK (
        (is_anonymous = true AND user_id IS NULL) OR
        (is_anonymous = false AND auth.uid() = user_id)
    );

-- Confessions: Users can update their own non-anonymous confessions
CREATE POLICY "confessions_own_update" ON confessions
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id AND is_anonymous = false)
    WITH CHECK (auth.uid() = user_id AND is_anonymous = false);

-- =============================================================================
-- POLLING SYSTEM SECURITY POLICIES
-- =============================================================================

-- Polls: Public read for active polls
CREATE POLICY "polls_public_read" ON polls
    FOR SELECT
    USING (is_active = true);

-- Polls: Users can create and manage their own polls
CREATE POLICY "polls_own_manage" ON polls
    FOR ALL
    TO authenticated
    USING (auth.uid() = creator_id)
    WITH CHECK (auth.uid() = creator_id);

-- Poll options: Public read for active poll options
CREATE POLICY "poll_options_public_read" ON poll_options
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM polls p 
            WHERE p.id = poll_id 
            AND p.is_active = true
        )
    );

-- Poll options: Poll creators can manage options
CREATE POLICY "poll_options_creator_manage" ON poll_options
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM polls p 
            WHERE p.id = poll_id 
            AND p.creator_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM polls p 
            WHERE p.id = poll_id 
            AND p.creator_id = auth.uid()
        )
    );

-- Poll votes: Users can read votes for polls they created or voted on
CREATE POLICY "poll_votes_read" ON poll_votes
    FOR SELECT
    TO authenticated
    USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM polls p 
            WHERE p.id = poll_id 
            AND p.creator_id = auth.uid()
        )
    );

-- Poll votes: Users can create their own votes
CREATE POLICY "poll_votes_own_create" ON poll_votes
    FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() = user_id AND
        EXISTS (
            SELECT 1 FROM polls p 
            WHERE p.id = poll_id 
            AND p.is_active = true
            AND (p.ends_at IS NULL OR p.ends_at > NOW())
        )
    );

-- Poll votes: Users can update their own votes
CREATE POLICY "poll_votes_own_update" ON poll_votes
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- =============================================================================
-- SECURITY FUNCTIONS
-- =============================================================================

-- Function to check if user can access tab
CREATE OR REPLACE FUNCTION user_can_access_tab(
    p_user_id UUID,
    p_tab_name VARCHAR(100)
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_requires_auth BOOLEAN;
    v_is_enabled BOOLEAN;
    v_is_production_ready BOOLEAN;
BEGIN
    -- Get tab requirements
    SELECT requires_authentication, is_enabled, is_production_ready
    INTO v_requires_auth, v_is_enabled, v_is_production_ready
    FROM tab_definitions
    WHERE tab_name = p_tab_name;
    
    -- Check if tab exists and is available
    IF NOT FOUND OR NOT v_is_enabled OR NOT v_is_production_ready THEN
        RETURN false;
    END IF;
    
    -- Check authentication requirement
    IF v_requires_auth AND p_user_id IS NULL THEN
        RETURN false;
    END IF;
    
    -- Check if user has hidden the tab
    IF p_user_id IS NOT NULL THEN
        IF EXISTS (
            SELECT 1 FROM user_tab_preferences 
            WHERE user_id = p_user_id 
            AND tab_name = p_tab_name 
            AND is_hidden = true
        ) THEN
            RETURN false;
        END IF;
    END IF;
    
    RETURN true;
END;
$$;

-- Function to sanitize user input for social features
CREATE OR REPLACE FUNCTION sanitize_social_content(
    p_content TEXT
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_cleaned_content TEXT;
BEGIN
    -- Remove potentially dangerous content
    v_cleaned_content := p_content;
    
    -- Remove script tags and javascript
    v_cleaned_content := regexp_replace(v_cleaned_content, '<script[^>]*>.*?</script>', '', 'gi');
    v_cleaned_content := regexp_replace(v_cleaned_content, 'javascript:', '', 'gi');
    v_cleaned_content := regexp_replace(v_cleaned_content, 'on\w+\s*=', '', 'gi');
    
    -- Remove potentially harmful HTML tags
    v_cleaned_content := regexp_replace(v_cleaned_content, '<(iframe|object|embed|form|input)[^>]*>', '', 'gi');
    
    -- Limit content length
    IF char_length(v_cleaned_content) > 2000 THEN
        v_cleaned_content := substring(v_cleaned_content from 1 for 2000);
    END IF;
    
    RETURN v_cleaned_content;
END;
$$;

-- Function to check content moderation
CREATE OR REPLACE FUNCTION check_content_moderation(
    p_content TEXT,
    p_content_type VARCHAR(50) DEFAULT 'post'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_blocked_words TEXT[] := ARRAY[
        'spam', 'scam', 'abuse', 'hate', 'harassment'
        -- Add more moderation keywords as needed
    ];
    v_word TEXT;
    v_lower_content TEXT;
BEGIN
    v_lower_content := lower(p_content);
    
    -- Check for blocked words
    FOREACH v_word IN ARRAY v_blocked_words
    LOOP
        IF position(v_word IN v_lower_content) > 0 THEN
            RETURN false;
        END IF;
    END LOOP;
    
    -- Check content length limits
    CASE p_content_type
        WHEN 'post' THEN
            IF char_length(p_content) > 2000 THEN
                RETURN false;
            END IF;
        WHEN 'comment' THEN
            IF char_length(p_content) > 1000 THEN
                RETURN false;
            END IF;
        WHEN 'confession' THEN
            IF char_length(p_content) > 2000 THEN
                RETURN false;
            END IF;
        WHEN 'poll_option' THEN
            IF char_length(p_content) > 255 THEN
                RETURN false;
            END IF;
    END CASE;
    
    RETURN true;
END;
$$;

-- =============================================================================
-- AUDIT TRIGGERS
-- =============================================================================

-- Create audit log table for sensitive operations
CREATE TABLE IF NOT EXISTS tabs_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name VARCHAR(100) NOT NULL,
    operation VARCHAR(20) NOT NULL,
    user_id UUID REFERENCES auth.users(id),
    old_data JSONB,
    new_data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on audit log
ALTER TABLE tabs_audit_log ENABLE ROW LEVEL SECURITY;

-- Audit log policy (service role only)
CREATE POLICY "audit_log_service_only" ON tabs_audit_log
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Audit trigger function
CREATE OR REPLACE FUNCTION tabs_audit_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Log sensitive table changes
    IF TG_TABLE_NAME IN ('glitter_posts', 'confessions', 'polls', 'user_tab_preferences') THEN
        INSERT INTO tabs_audit_log (
            table_name, operation, user_id, old_data, new_data
        ) VALUES (
            TG_TABLE_NAME,
            TG_OP,
            COALESCE(NEW.user_id, OLD.user_id),
            CASE WHEN TG_OP = 'DELETE' THEN row_to_json(OLD) ELSE NULL END,
            CASE WHEN TG_OP != 'DELETE' THEN row_to_json(NEW) ELSE NULL END
        );
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$;

-- Create audit triggers
CREATE TRIGGER glitter_posts_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON glitter_posts
    FOR EACH ROW EXECUTE FUNCTION tabs_audit_trigger();

CREATE TRIGGER confessions_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON confessions
    FOR EACH ROW EXECUTE FUNCTION tabs_audit_trigger();

CREATE TRIGGER polls_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON polls
    FOR EACH ROW EXECUTE FUNCTION tabs_audit_trigger();

-- =============================================================================
-- CONTENT VALIDATION TRIGGERS
-- =============================================================================

-- Content sanitization trigger for social posts
CREATE OR REPLACE FUNCTION sanitize_social_posts_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Sanitize content
    NEW.text_content := sanitize_social_content(NEW.text_content);
    
    -- Check moderation
    IF NOT check_content_moderation(NEW.text_content, 'post') THEN
        RAISE EXCEPTION 'Content violates community guidelines';
    END IF;
    
    RETURN NEW;
END;
$$;

-- Content sanitization trigger for comments
CREATE OR REPLACE FUNCTION sanitize_comments_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Sanitize content
    NEW.text_content := sanitize_social_content(NEW.text_content);
    
    -- Check moderation
    IF NOT check_content_moderation(NEW.text_content, 'comment') THEN
        RAISE EXCEPTION 'Content violates community guidelines';
    END IF;
    
    RETURN NEW;
END;
$$;

-- Content sanitization trigger for confessions
CREATE OR REPLACE FUNCTION sanitize_confessions_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Sanitize content
    NEW.confession_text := sanitize_social_content(NEW.confession_text);
    
    -- Check moderation
    IF NOT check_content_moderation(NEW.confession_text, 'confession') THEN
        RAISE EXCEPTION 'Content violates community guidelines';
    END IF;
    
    RETURN NEW;
END;
$$;

-- Apply content validation triggers
CREATE TRIGGER glitter_posts_sanitize_trigger
    BEFORE INSERT OR UPDATE ON glitter_posts
    FOR EACH ROW EXECUTE FUNCTION sanitize_social_posts_trigger();

CREATE TRIGGER glitter_comments_sanitize_trigger
    BEFORE INSERT OR UPDATE ON glitter_comments
    FOR EACH ROW EXECUTE FUNCTION sanitize_comments_trigger();

CREATE TRIGGER confessions_sanitize_trigger
    BEFORE INSERT OR UPDATE ON confessions
    FOR EACH ROW EXECUTE FUNCTION sanitize_confessions_trigger();

-- =============================================================================
-- RATE LIMITING FUNCTIONS
-- =============================================================================

-- Rate limiting table
CREATE TABLE IF NOT EXISTS user_rate_limits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    action_type VARCHAR(50) NOT NULL,
    action_count INTEGER DEFAULT 1,
    window_start TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, action_type, window_start)
);

-- Enable RLS on rate limits
ALTER TABLE user_rate_limits ENABLE ROW LEVEL SECURITY;

-- Rate limits policy
CREATE POLICY "rate_limits_own_data" ON user_rate_limits
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Rate limiting function
-- Drop all existing check_rate_limit functions
DO $$
DECLARE
    func_name TEXT;
BEGIN
    FOR func_name IN 
        SELECT format('%s(%s)', p.proname, pg_get_function_identity_arguments(p.oid))
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE p.proname = 'check_rate_limit'
        AND n.nspname = 'public'
    LOOP
        EXECUTE format('DROP FUNCTION IF EXISTS %s', func_name);
    END LOOP;
END
$$;

CREATE OR REPLACE FUNCTION check_rate_limit(
    p_user_id UUID,
    p_action_type VARCHAR(50),
    p_max_actions INTEGER DEFAULT 10,
    p_window_minutes INTEGER DEFAULT 60
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_window_start TIMESTAMPTZ;
    v_current_count INTEGER;
BEGIN
    -- Calculate current window start
    v_window_start := DATE_TRUNC('hour', NOW()) + 
                     (EXTRACT(MINUTE FROM NOW())::INTEGER / p_window_minutes) * 
                     (p_window_minutes || ' minutes')::INTERVAL;
    
    -- Get current count for this window
    SELECT action_count INTO v_current_count
    FROM user_rate_limits
    WHERE user_id = p_user_id
    AND action_type = p_action_type
    AND window_start = v_window_start;
    
    -- If no record exists, create one
    IF v_current_count IS NULL THEN
        INSERT INTO user_rate_limits (user_id, action_type, window_start, action_count)
        VALUES (p_user_id, p_action_type, v_window_start, 1)
        ON CONFLICT (user_id, action_type, window_start)
        DO UPDATE SET 
            action_count = user_rate_limits.action_count + 1,
            updated_at = NOW();
        RETURN true;
    END IF;
    
    -- Check if limit exceeded
    IF v_current_count >= p_max_actions THEN
        RETURN false;
    END IF;
    
    -- Increment counter
    UPDATE user_rate_limits
    SET action_count = action_count + 1, updated_at = NOW()
    WHERE user_id = p_user_id
    AND action_type = p_action_type
    AND window_start = v_window_start;
    
    RETURN true;
END;
$$;

-- =============================================================================
-- CLEANUP FUNCTIONS
-- =============================================================================

-- Clean old audit logs
CREATE OR REPLACE FUNCTION cleanup_old_audit_logs()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    DELETE FROM tabs_audit_log
    WHERE created_at < NOW() - INTERVAL '90 days';
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    RETURN v_deleted_count;
END;
$$;

-- Clean old rate limit records
CREATE OR REPLACE FUNCTION cleanup_old_rate_limits()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    DELETE FROM user_rate_limits
    WHERE window_start < NOW() - INTERVAL '24 hours';
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    RETURN v_deleted_count;
END;
$$;

-- =============================================================================
-- GRANT PERMISSIONS
-- =============================================================================

-- Grant function permissions
GRANT EXECUTE ON FUNCTION user_can_access_tab TO authenticated;
GRANT EXECUTE ON FUNCTION sanitize_social_content TO authenticated;
GRANT EXECUTE ON FUNCTION check_content_moderation TO authenticated;
GRANT EXECUTE ON FUNCTION check_rate_limit TO authenticated;
GRANT EXECUTE ON FUNCTION cleanup_old_audit_logs TO service_role;
GRANT EXECUTE ON FUNCTION cleanup_old_rate_limits TO service_role;

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON FUNCTION user_can_access_tab IS 'Check if user has permission to access specific tab';
COMMENT ON FUNCTION sanitize_social_content IS 'Sanitize user-generated content for security';
COMMENT ON FUNCTION check_content_moderation IS 'Check content against moderation rules';
COMMENT ON FUNCTION check_rate_limit IS 'Implement rate limiting for user actions';
COMMENT ON TABLE tabs_audit_log IS 'Audit trail for sensitive tab system operations';
COMMENT ON TABLE user_rate_limits IS 'Rate limiting tracking for user actions';

-- Setup completion message
SELECT 'Tabs Security and Policies Setup Complete!' as status, NOW() as setup_completed_at;
