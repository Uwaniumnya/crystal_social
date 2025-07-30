-- Crystal Social Tabs System - Business Logic and Functions
-- File: 02_tabs_business_logic.sql
-- Purpose: Stored procedures, functions, and business logic for comprehensive tabs functionality

-- =============================================================================
-- TAB MANAGEMENT FUNCTIONS
-- =============================================================================

-- Register a new tab in the system
CREATE OR REPLACE FUNCTION register_tab(
    p_tab_name VARCHAR(100),
    p_display_name VARCHAR(255),
    p_description TEXT DEFAULT NULL,
    p_icon_path VARCHAR(500) DEFAULT NULL,
    p_tab_order INTEGER DEFAULT 0,
    p_is_production_ready BOOLEAN DEFAULT false,
    p_requires_auth BOOLEAN DEFAULT true
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_tab_id UUID;
BEGIN
    -- Insert new tab definition
    INSERT INTO tab_definitions (
        tab_name, display_name, description, icon_path, tab_order,
        is_production_ready, requires_authentication
    ) VALUES (
        p_tab_name, p_display_name, p_description, p_icon_path, p_tab_order,
        p_is_production_ready, p_requires_auth
    ) RETURNING id INTO v_tab_id;
    
    -- Create default user preferences for existing users
    INSERT INTO user_tab_preferences (user_id, tab_name)
    SELECT id, p_tab_name
    FROM auth.users
    ON CONFLICT (user_id, tab_name) DO NOTHING;
    
    RETURN v_tab_id;
END;
$$;

-- Update user tab preferences
CREATE OR REPLACE FUNCTION update_tab_preferences(
    p_user_id UUID,
    p_tab_name VARCHAR(100),
    p_is_favorite BOOLEAN DEFAULT NULL,
    p_is_hidden BOOLEAN DEFAULT NULL,
    p_custom_order INTEGER DEFAULT NULL,
    p_notifications_enabled BOOLEAN DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Insert or update user preferences
    INSERT INTO user_tab_preferences (
        user_id, tab_name, is_favorite, is_hidden, custom_order, notifications_enabled
    ) VALUES (
        p_user_id, p_tab_name, 
        COALESCE(p_is_favorite, false),
        COALESCE(p_is_hidden, false),
        p_custom_order,
        COALESCE(p_notifications_enabled, true)
    )
    ON CONFLICT (user_id, tab_name)
    DO UPDATE SET
        is_favorite = COALESCE(p_is_favorite, user_tab_preferences.is_favorite),
        is_hidden = COALESCE(p_is_hidden, user_tab_preferences.is_hidden),
        custom_order = COALESCE(p_custom_order, user_tab_preferences.custom_order),
        notifications_enabled = COALESCE(p_notifications_enabled, user_tab_preferences.notifications_enabled),
        updated_at = NOW();
    
    RETURN true;
END;
$$;

-- Track tab usage for analytics
CREATE OR REPLACE FUNCTION track_tab_usage(
    p_user_id UUID,
    p_tab_name VARCHAR(100),
    p_session_duration_seconds INTEGER DEFAULT 0,
    p_interactions_count INTEGER DEFAULT 0,
    p_load_time_ms INTEGER DEFAULT 0
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_usage_id UUID;
    v_session_end TIMESTAMPTZ;
BEGIN
    -- Calculate session end time
    v_session_end := NOW() - (p_session_duration_seconds || ' seconds')::INTERVAL + (p_session_duration_seconds || ' seconds')::INTERVAL;
    
    -- Insert usage record
    INSERT INTO tab_usage_analytics (
        user_id, tab_name, session_start, session_end,
        interactions_count, load_time_ms
    ) VALUES (
        p_user_id, p_tab_name, 
        NOW() - (p_session_duration_seconds || ' seconds')::INTERVAL,
        v_session_end,
        p_interactions_count, p_load_time_ms
    ) RETURNING id INTO v_usage_id;
    
    -- Update user preferences with usage data
    UPDATE user_tab_preferences 
    SET 
        last_accessed_at = NOW(),
        access_count = access_count + 1,
        total_time_spent_minutes = total_time_spent_minutes + CEIL(p_session_duration_seconds / 60.0),
        session_count = session_count + 1,
        last_session_duration_minutes = CEIL(p_session_duration_seconds / 60.0),
        updated_at = NOW()
    WHERE user_id = p_user_id AND tab_name = p_tab_name;
    
    RETURN v_usage_id;
END;
$$;

-- =============================================================================
-- HOME SCREEN MANAGEMENT FUNCTIONS
-- =============================================================================

-- Add or update home screen app
CREATE OR REPLACE FUNCTION manage_home_screen_app(
    p_app_name VARCHAR(100),
    p_display_title VARCHAR(255),
    p_subtitle TEXT DEFAULT NULL,
    p_icon_path VARCHAR(500) DEFAULT NULL,
    p_color_scheme VARCHAR(7) DEFAULT '#8A2BE2',
    p_grid_position INTEGER DEFAULT 0,
    p_target_tab VARCHAR(100) DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_app_id UUID;
BEGIN
    -- Insert or update home screen app
    INSERT INTO home_screen_apps (
        app_name, display_title, subtitle, icon_path, color_scheme,
        grid_position, target_tab
    ) VALUES (
        p_app_name, p_display_title, p_subtitle, p_icon_path, p_color_scheme,
        p_grid_position, p_target_tab
    )
    ON CONFLICT (app_name)
    DO UPDATE SET
        display_title = p_display_title,
        subtitle = p_subtitle,
        icon_path = COALESCE(p_icon_path, home_screen_apps.icon_path),
        color_scheme = p_color_scheme,
        grid_position = p_grid_position,
        target_tab = COALESCE(p_target_tab, home_screen_apps.target_tab),
        updated_at = NOW()
    RETURNING id INTO v_app_id;
    
    RETURN v_app_id;
END;
$$;

-- Track app launch from home screen
CREATE OR REPLACE FUNCTION track_app_launch(
    p_user_id UUID,
    p_app_name VARCHAR(100)
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Update app launch statistics
    UPDATE home_screen_apps 
    SET 
        total_launches = total_launches + 1,
        last_launched_at = NOW(),
        updated_at = NOW()
    WHERE app_name = p_app_name;
    
    -- Track user-specific usage if layout exists
    UPDATE user_home_screen_layout 
    SET updated_at = NOW()
    WHERE user_id = p_user_id 
    AND app_id = (SELECT id FROM home_screen_apps WHERE app_name = p_app_name);
    
    RETURN true;
END;
$$;

-- Customize user home screen layout
CREATE OR REPLACE FUNCTION customize_home_layout(
    p_user_id UUID,
    p_app_name VARCHAR(100),
    p_custom_position INTEGER DEFAULT NULL,
    p_is_hidden BOOLEAN DEFAULT false,
    p_is_pinned BOOLEAN DEFAULT false,
    p_custom_size VARCHAR(20) DEFAULT 'normal'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_app_id UUID;
BEGIN
    -- Get app ID
    SELECT id INTO v_app_id FROM home_screen_apps WHERE app_name = p_app_name;
    
    IF v_app_id IS NULL THEN
        RAISE EXCEPTION 'App not found: %', p_app_name;
    END IF;
    
    -- Insert or update user layout
    INSERT INTO user_home_screen_layout (
        user_id, app_id, custom_position, is_hidden, is_pinned, custom_size
    ) VALUES (
        p_user_id, v_app_id, p_custom_position, p_is_hidden, p_is_pinned, p_custom_size
    )
    ON CONFLICT (user_id, app_id)
    DO UPDATE SET
        custom_position = COALESCE(p_custom_position, user_home_screen_layout.custom_position),
        is_hidden = p_is_hidden,
        is_pinned = p_is_pinned,
        custom_size = p_custom_size,
        updated_at = NOW();
    
    RETURN true;
END;
$$;

-- =============================================================================
-- GLITTER BOARD SOCIAL FUNCTIONS
-- =============================================================================

-- Create a new Glitter Board post
CREATE OR REPLACE FUNCTION create_glitter_post(
    p_user_id UUID,
    p_text_content TEXT,
    p_mood VARCHAR(10) DEFAULT '✨',
    p_image_url TEXT DEFAULT NULL,
    p_tags TEXT[] DEFAULT '{}',
    p_location VARCHAR(255) DEFAULT NULL,
    p_visibility VARCHAR(20) DEFAULT 'public'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_post_id UUID;
BEGIN
    -- Validate content length
    IF char_length(p_text_content) > 2000 THEN
        RAISE EXCEPTION 'Post content too long (max 2000 characters)';
    END IF;
    
    -- Insert new post
    INSERT INTO glitter_posts (
        user_id, text_content, mood, image_url, tags, location, visibility
    ) VALUES (
        p_user_id, p_text_content, p_mood, p_image_url, p_tags, p_location, p_visibility
    ) RETURNING id INTO v_post_id;
    
    RETURN v_post_id;
END;
$$;

-- Add comment to Glitter Board post
CREATE OR REPLACE FUNCTION add_glitter_comment(
    p_user_id UUID,
    p_post_id UUID,
    p_text_content TEXT,
    p_parent_comment_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_comment_id UUID;
BEGIN
    -- Validate content length
    IF char_length(p_text_content) > 1000 THEN
        RAISE EXCEPTION 'Comment too long (max 1000 characters)';
    END IF;
    
    -- Verify post exists and is not deleted
    IF NOT EXISTS (
        SELECT 1 FROM glitter_posts 
        WHERE id = p_post_id AND is_deleted = false
    ) THEN
        RAISE EXCEPTION 'Post not found or deleted';
    END IF;
    
    -- Insert comment
    INSERT INTO glitter_comments (
        post_id, user_id, text_content, parent_comment_id
    ) VALUES (
        p_post_id, p_user_id, p_text_content, p_parent_comment_id
    ) RETURNING id INTO v_comment_id;
    
    -- Update parent comment reply count if this is a reply
    IF p_parent_comment_id IS NOT NULL THEN
        UPDATE glitter_comments 
        SET replies_count = replies_count + 1
        WHERE id = p_parent_comment_id;
    END IF;
    
    RETURN v_comment_id;
END;
$$;

-- React to a post or comment
CREATE OR REPLACE FUNCTION add_glitter_reaction(
    p_user_id UUID,
    p_target_type VARCHAR(20),
    p_target_id UUID,
    p_reaction_type VARCHAR(20) DEFAULT 'like'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Validate target type
    IF p_target_type NOT IN ('post', 'comment') THEN
        RAISE EXCEPTION 'Invalid target type: %', p_target_type;
    END IF;
    
    -- Insert or update reaction
    INSERT INTO glitter_reactions (
        user_id, target_type, target_id, reaction_type
    ) VALUES (
        p_user_id, p_target_type, p_target_id, p_reaction_type
    )
    ON CONFLICT (user_id, target_type, target_id)
    DO UPDATE SET
        reaction_type = p_reaction_type,
        created_at = NOW();
    
    RETURN true;
END;
$$;

-- Remove reaction from post or comment
CREATE OR REPLACE FUNCTION remove_glitter_reaction(
    p_user_id UUID,
    p_target_type VARCHAR(20),
    p_target_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM glitter_reactions
    WHERE user_id = p_user_id 
    AND target_type = p_target_type 
    AND target_id = p_target_id;
    
    RETURN FOUND;
END;
$$;

-- =============================================================================
-- HOROSCOPE SYSTEM FUNCTIONS
-- =============================================================================

-- Get or create user horoscope preferences
CREATE OR REPLACE FUNCTION setup_user_horoscope(
    p_user_id UUID,
    p_zodiac_sign_name VARCHAR(50),
    p_daily_notifications BOOLEAN DEFAULT true,
    p_preferred_reading_time TIME DEFAULT '09:00:00'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_zodiac_sign_id UUID;
    v_preference_id UUID;
BEGIN
    -- Get zodiac sign ID
    SELECT id INTO v_zodiac_sign_id 
    FROM zodiac_signs 
    WHERE sign_name = p_zodiac_sign_name;
    
    IF v_zodiac_sign_id IS NULL THEN
        RAISE EXCEPTION 'Invalid zodiac sign: %', p_zodiac_sign_name;
    END IF;
    
    -- Insert or update user preferences
    INSERT INTO user_horoscope_preferences (
        user_id, zodiac_sign_id, daily_notifications, preferred_reading_time
    ) VALUES (
        p_user_id, v_zodiac_sign_id, p_daily_notifications, p_preferred_reading_time
    )
    ON CONFLICT (user_id)
    DO UPDATE SET
        zodiac_sign_id = v_zodiac_sign_id,
        daily_notifications = p_daily_notifications,
        preferred_reading_time = p_preferred_reading_time,
        updated_at = NOW()
    RETURNING id INTO v_preference_id;
    
    RETURN v_preference_id;
END;
$$;

-- Get daily horoscope for user
CREATE OR REPLACE FUNCTION get_daily_horoscope(
    p_user_id UUID,
    p_reading_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    general_reading TEXT,
    love_reading TEXT,
    career_reading TEXT,
    health_reading TEXT,
    financial_reading TEXT,
    lucky_numbers INTEGER[],
    lucky_colors TEXT[],
    overall_energy INTEGER,
    daily_affirmation TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_zodiac_sign_id UUID;
BEGIN
    -- Get user's zodiac sign
    SELECT zodiac_sign_id INTO v_zodiac_sign_id
    FROM user_horoscope_preferences
    WHERE user_id = p_user_id;
    
    IF v_zodiac_sign_id IS NULL THEN
        RAISE EXCEPTION 'User horoscope preferences not found';
    END IF;
    
    -- Return horoscope reading
    RETURN QUERY
    SELECT 
        hr.general_reading,
        hr.love_reading,
        hr.career_reading,
        hr.health_reading,
        hr.financial_reading,
        hr.lucky_numbers,
        hr.lucky_colors,
        hr.overall_energy,
        hr.daily_affirmation
    FROM horoscope_readings hr
    WHERE hr.zodiac_sign_id = v_zodiac_sign_id
    AND hr.reading_date = p_reading_date;
    
    -- Track reading view
    UPDATE user_horoscope_preferences
    SET 
        total_readings_viewed = total_readings_viewed + 1,
        last_reading_date = p_reading_date,
        streak_days = CASE 
            WHEN last_reading_date = p_reading_date - INTERVAL '1 day' THEN streak_days + 1
            WHEN last_reading_date = p_reading_date THEN streak_days
            ELSE 1
        END,
        updated_at = NOW()
    WHERE user_id = p_user_id;
END;
$$;

-- Award horoscope coins to user
CREATE OR REPLACE FUNCTION award_horoscope_coins(
    p_user_id UUID,
    p_coin_amount INTEGER,
    p_reason VARCHAR(255) DEFAULT 'Daily horoscope reading'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Update user horoscope coins
    UPDATE user_horoscope_preferences
    SET 
        coins_earned = coins_earned + p_coin_amount,
        updated_at = NOW()
    WHERE user_id = p_user_id;
    
    -- Could also integrate with main rewards system here
    -- INSERT INTO user_currency_transactions...
    
    RETURN FOUND;
END;
$$;

-- =============================================================================
-- TAROT READING FUNCTIONS
-- =============================================================================

-- Perform tarot reading for user
CREATE OR REPLACE FUNCTION perform_tarot_reading(
    p_user_id UUID,
    p_deck_id UUID,
    p_reading_type VARCHAR(50),
    p_question TEXT DEFAULT NULL,
    p_cards_drawn JSONB DEFAULT '[]'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_reading_id UUID;
    v_interpretation TEXT;
    v_overall_theme VARCHAR(100);
    v_guidance_message TEXT;
BEGIN
    -- Validate reading type
    IF p_reading_type NOT IN ('single', 'three_card', 'celtic_cross', 'daily', 'relationship') THEN
        RAISE EXCEPTION 'Invalid reading type: %', p_reading_type;
    END IF;
    
    -- Verify deck exists
    IF NOT EXISTS (SELECT 1 FROM tarot_decks WHERE id = p_deck_id) THEN
        RAISE EXCEPTION 'Tarot deck not found';
    END IF;
    
    -- Generate interpretation based on cards (simplified)
    v_interpretation := 'The cards reveal insights about your current path...';
    v_overall_theme := 'Transformation and growth';
    v_guidance_message := 'Trust in your inner wisdom and follow your intuition.';
    
    -- Insert tarot reading
    INSERT INTO tarot_readings (
        user_id, deck_id, reading_type, question, cards_drawn,
        interpretation, overall_theme, guidance_message
    ) VALUES (
        p_user_id, p_deck_id, p_reading_type, p_question, p_cards_drawn,
        v_interpretation, v_overall_theme, v_guidance_message
    ) RETURNING id INTO v_reading_id;
    
    RETURN v_reading_id;
END;
$$;

-- Get tarot reading history for user
CREATE OR REPLACE FUNCTION get_user_tarot_history(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    reading_id UUID,
    reading_type VARCHAR(50),
    question TEXT,
    overall_theme VARCHAR(100),
    guidance_message TEXT,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tr.id,
        tr.reading_type,
        tr.question,
        tr.overall_theme,
        tr.guidance_message,
        tr.created_at
    FROM tarot_readings tr
    WHERE tr.user_id = p_user_id
    ORDER BY tr.created_at DESC
    LIMIT p_limit;
END;
$$;

-- =============================================================================
-- ORACLE SYSTEM FUNCTIONS
-- =============================================================================

-- Get oracle guidance for user
CREATE OR REPLACE FUNCTION get_oracle_guidance(
    p_user_id UUID,
    p_question_category VARCHAR(100) DEFAULT NULL,
    p_emotional_state VARCHAR(50) DEFAULT NULL
)
RETURNS TABLE (
    message_text TEXT,
    message_type VARCHAR(50),
    element VARCHAR(20),
    energy_level INTEGER,
    crystal_recommendations TEXT[],
    consultation_id UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_selected_message oracle_messages%ROWTYPE;
    v_consultation_id UUID;
    v_weight_filter NUMERIC;
BEGIN
    -- Select appropriate oracle message based on context
    -- Use weighted random selection based on energy level and previous usage
    SELECT * INTO v_selected_message
    FROM oracle_messages om
    WHERE (
        p_question_category IS NULL OR 
        p_question_category = ANY(om.theme_tags)
    )
    ORDER BY 
        -- Prefer less frequently used messages
        (1.0 / GREATEST(om.times_delivered, 1)) * RANDOM(),
        -- Prefer higher energy messages for positive states
        CASE WHEN p_emotional_state IN ('excited', 'hopeful', 'peaceful') 
             THEN om.energy_level ELSE 6 - om.energy_level END DESC,
        RANDOM()
    LIMIT 1;
    
    IF v_selected_message.id IS NULL THEN
        RAISE EXCEPTION 'No oracle messages available';
    END IF;
    
    -- Record consultation
    INSERT INTO oracle_consultations (
        user_id, oracle_message_id, question_category, emotional_state
    ) VALUES (
        p_user_id, v_selected_message.id, p_question_category, p_emotional_state
    ) RETURNING id INTO v_consultation_id;
    
    -- Update message delivery count
    UPDATE oracle_messages 
    SET 
        times_delivered = times_delivered + 1,
        last_delivered_at = NOW(),
        updated_at = NOW()
    WHERE id = v_selected_message.id;
    
    -- Return oracle guidance
    RETURN QUERY
    SELECT 
        v_selected_message.message_text,
        v_selected_message.message_type,
        v_selected_message.element,
        v_selected_message.energy_level,
        v_selected_message.crystal_recommendations,
        v_consultation_id;
END;
$$;

-- Rate oracle consultation
CREATE OR REPLACE FUNCTION rate_oracle_consultation(
    p_consultation_id UUID,
    p_user_rating INTEGER,
    p_was_helpful BOOLEAN DEFAULT NULL,
    p_user_feedback TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Validate rating
    IF p_user_rating < 1 OR p_user_rating > 5 THEN
        RAISE EXCEPTION 'Rating must be between 1 and 5';
    END IF;
    
    -- Update consultation with feedback
    UPDATE oracle_consultations
    SET 
        user_rating = p_user_rating,
        was_helpful = p_was_helpful,
        user_feedback = p_user_feedback
    WHERE id = p_consultation_id;
    
    RETURN FOUND;
END;
$$;

-- =============================================================================
-- ENTERTAINMENT SYSTEM FUNCTIONS
-- =============================================================================

-- Get Magic 8-Ball response
CREATE OR REPLACE FUNCTION get_8ball_response(
    p_user_id UUID,
    p_user_question TEXT DEFAULT NULL,
    p_question_category VARCHAR(100) DEFAULT NULL,
    p_user_mood VARCHAR(50) DEFAULT NULL
)
RETURNS TABLE (
    response_text VARCHAR(255),
    response_type VARCHAR(20),
    response_category VARCHAR(50),
    text_color VARCHAR(7),
    background_color VARCHAR(7),
    consultation_id UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_selected_response magic_8ball_responses%ROWTYPE;
    v_consultation_id UUID;
BEGIN
    -- Select response with weighted randomization
    SELECT * INTO v_selected_response
    FROM magic_8ball_responses
    ORDER BY 
        -- Slight preference for responses matching user mood
        CASE 
            WHEN p_user_mood IN ('hopeful', 'excited') AND response_type = 'positive' THEN 2
            WHEN p_user_mood IN ('sad', 'anxious') AND response_type = 'negative' THEN 0.5
            ELSE 1
        END * RANDOM()
    LIMIT 1;
    
    -- Record consultation
    INSERT INTO magic_8ball_consultations (
        user_id, response_id, user_question, question_category, user_mood
    ) VALUES (
        p_user_id, v_selected_response.id, p_user_question, p_question_category, p_user_mood
    ) RETURNING id INTO v_consultation_id;
    
    -- Update response usage statistics
    UPDATE magic_8ball_responses
    SET times_shown = times_shown + 1
    WHERE id = v_selected_response.id;
    
    -- Return response
    RETURN QUERY
    SELECT 
        v_selected_response.response_text,
        v_selected_response.response_type,
        v_selected_response.response_category,
        v_selected_response.text_color,
        v_selected_response.background_color,
        v_consultation_id;
END;
$$;

-- Submit confession
CREATE OR REPLACE FUNCTION submit_confession(
    p_user_id UUID,
    p_confession_text TEXT,
    p_confession_category VARCHAR(100) DEFAULT NULL,
    p_mood_emoji VARCHAR(10) DEFAULT '😔',
    p_is_anonymous BOOLEAN DEFAULT true
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_confession_id UUID;
    v_final_user_id UUID;
BEGIN
    -- Validate content length
    IF char_length(p_confession_text) > 2000 THEN
        RAISE EXCEPTION 'Confession too long (max 2000 characters)';
    END IF;
    
    -- Set user ID to NULL if anonymous
    v_final_user_id := CASE WHEN p_is_anonymous THEN NULL ELSE p_user_id END;
    
    -- Insert confession
    INSERT INTO confessions (
        user_id, confession_text, confession_category, mood_emoji, is_anonymous
    ) VALUES (
        v_final_user_id, p_confession_text, p_confession_category, p_mood_emoji, p_is_anonymous
    ) RETURNING id INTO v_confession_id;
    
    RETURN v_confession_id;
END;
$$;

-- =============================================================================
-- POLLING SYSTEM FUNCTIONS
-- =============================================================================

-- Create a new poll
CREATE OR REPLACE FUNCTION create_poll(
    p_creator_id UUID,
    p_poll_title VARCHAR(255),
    p_poll_description TEXT DEFAULT NULL,
    p_poll_category VARCHAR(100) DEFAULT NULL,
    p_is_multiple_choice BOOLEAN DEFAULT false,
    p_is_anonymous_voting BOOLEAN DEFAULT false,
    p_ends_at TIMESTAMPTZ DEFAULT NULL,
    p_poll_options TEXT[] DEFAULT '{}'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_poll_id UUID;
    v_option_text TEXT;
    v_option_order INTEGER := 0;
BEGIN
    -- Validate poll title
    IF char_length(p_poll_title) < 3 THEN
        RAISE EXCEPTION 'Poll title too short (minimum 3 characters)';
    END IF;
    
    -- Insert poll
    INSERT INTO polls (
        creator_id, poll_title, poll_description, poll_category,
        is_multiple_choice, is_anonymous_voting, ends_at
    ) VALUES (
        p_creator_id, p_poll_title, p_poll_description, p_poll_category,
        p_is_multiple_choice, p_is_anonymous_voting, p_ends_at
    ) RETURNING id INTO v_poll_id;
    
    -- Add poll options
    FOREACH v_option_text IN ARRAY p_poll_options
    LOOP
        INSERT INTO poll_options (poll_id, option_text, option_order)
        VALUES (v_poll_id, v_option_text, v_option_order);
        v_option_order := v_option_order + 1;
    END LOOP;
    
    RETURN v_poll_id;
END;
$$;

-- Vote on a poll
CREATE OR REPLACE FUNCTION vote_on_poll(
    p_user_id UUID,
    p_poll_id UUID,
    p_option_ids UUID[],
    p_is_anonymous BOOLEAN DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_option_id UUID;
    v_is_multiple_choice BOOLEAN;
    v_is_anonymous_voting BOOLEAN;
    v_final_anonymous BOOLEAN;
    v_poll_active BOOLEAN;
BEGIN
    -- Check if poll exists and is active
    SELECT is_multiple_choice, is_anonymous_voting, is_active
    INTO v_is_multiple_choice, v_is_anonymous_voting, v_poll_active
    FROM polls 
    WHERE id = p_poll_id AND (ends_at IS NULL OR ends_at > NOW());
    
    IF NOT FOUND OR NOT v_poll_active THEN
        RAISE EXCEPTION 'Poll not found, inactive, or expired';
    END IF;
    
    -- Check if multiple choice is allowed
    IF NOT v_is_multiple_choice AND array_length(p_option_ids, 1) > 1 THEN
        RAISE EXCEPTION 'Multiple choice not allowed for this poll';
    END IF;
    
    -- Determine if vote should be anonymous
    v_final_anonymous := COALESCE(p_is_anonymous, v_is_anonymous_voting);
    
    -- Remove existing votes for this user and poll (for vote updates)
    DELETE FROM poll_votes WHERE poll_id = p_poll_id AND user_id = p_user_id;
    
    -- Insert new votes
    FOREACH v_option_id IN ARRAY p_option_ids
    LOOP
        -- Verify option belongs to this poll
        IF NOT EXISTS (SELECT 1 FROM poll_options WHERE id = v_option_id AND poll_id = p_poll_id) THEN
            RAISE EXCEPTION 'Invalid option for this poll';
        END IF;
        
        INSERT INTO poll_votes (poll_id, user_id, option_id, is_anonymous)
        VALUES (p_poll_id, p_user_id, v_option_id, v_final_anonymous);
    END LOOP;
    
    RETURN true;
END;
$$;

-- =============================================================================
-- ANALYTICS AND REPORTING FUNCTIONS
-- =============================================================================

-- Generate daily usage summary for user
CREATE OR REPLACE FUNCTION generate_daily_usage_summary(
    p_user_id UUID,
    p_target_date DATE DEFAULT CURRENT_DATE
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_session_data RECORD;
    v_total_sessions INTEGER;
    v_total_time INTEGER;
    v_unique_tabs INTEGER;
    v_most_used_tab VARCHAR(100);
    v_total_interactions INTEGER;
    v_top_tabs JSONB;
BEGIN
    -- Calculate daily metrics
    SELECT 
        COUNT(*) as session_count,
        SUM(COALESCE(session_duration_seconds, 0)) as total_time,
        COUNT(DISTINCT tab_name) as unique_tabs,
        SUM(COALESCE(interactions_count, 0)) as total_interactions
    INTO v_session_data
    FROM tab_usage_analytics
    WHERE user_id = p_user_id 
    AND DATE(session_start) = p_target_date;
    
    -- Get most used tab
    SELECT tab_name INTO v_most_used_tab
    FROM tab_usage_analytics
    WHERE user_id = p_user_id 
    AND DATE(session_start) = p_target_date
    GROUP BY tab_name
    ORDER BY SUM(COALESCE(session_duration_seconds, 0)) DESC
    LIMIT 1;
    
    -- Generate top tabs JSON
    SELECT json_agg(
        json_build_object(
            'tab_name', tab_name,
            'duration', SUM(COALESCE(session_duration_seconds, 0)),
            'sessions', COUNT(*)
        ) ORDER BY SUM(COALESCE(session_duration_seconds, 0)) DESC
    ) INTO v_top_tabs
    FROM tab_usage_analytics
    WHERE user_id = p_user_id 
    AND DATE(session_start) = p_target_date
    GROUP BY tab_name
    LIMIT 5;
    
    -- Insert or update daily summary
    INSERT INTO daily_tab_usage_summary (
        user_id, usage_date, total_session_time_seconds, total_sessions,
        unique_tabs_visited, most_used_tab, total_interactions, top_tabs
    ) VALUES (
        p_user_id, p_target_date, 
        COALESCE(v_session_data.total_time, 0),
        COALESCE(v_session_data.session_count, 0),
        COALESCE(v_session_data.unique_tabs, 0),
        v_most_used_tab,
        COALESCE(v_session_data.total_interactions, 0),
        COALESCE(v_top_tabs, '[]')
    )
    ON CONFLICT (user_id, usage_date)
    DO UPDATE SET
        total_session_time_seconds = EXCLUDED.total_session_time_seconds,
        total_sessions = EXCLUDED.total_sessions,
        unique_tabs_visited = EXCLUDED.unique_tabs_visited,
        most_used_tab = EXCLUDED.most_used_tab,
        total_interactions = EXCLUDED.total_interactions,
        top_tabs = EXCLUDED.top_tabs,
        updated_at = NOW();
    
    RETURN true;
END;
$$;

-- Get user engagement analytics
CREATE OR REPLACE FUNCTION get_user_engagement_analytics(
    p_user_id UUID,
    p_days_back INTEGER DEFAULT 30
)
RETURNS TABLE (
    total_time_minutes INTEGER,
    average_session_minutes DECIMAL(10,2),
    favorite_tabs TEXT[],
    engagement_score INTEGER,
    most_active_hour INTEGER,
    streak_days INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_start_date DATE;
    v_total_time INTEGER;
    v_avg_session DECIMAL(10,2);
    v_favorite_tabs TEXT[];
    v_engagement_score INTEGER;
    v_most_active_hour INTEGER;
    v_streak_days INTEGER;
BEGIN
    v_start_date := CURRENT_DATE - p_days_back;
    
    -- Calculate metrics
    SELECT 
        SUM(total_session_time_seconds) / 60,
        AVG(CASE WHEN total_sessions > 0 THEN total_session_time_seconds::DECIMAL / total_sessions ELSE 0 END) / 60
    INTO v_total_time, v_avg_session
    FROM daily_tab_usage_summary
    WHERE user_id = p_user_id AND usage_date >= v_start_date;
    
    -- Get favorite tabs
    SELECT array_agg(tab_name ORDER BY total_time DESC)
    INTO v_favorite_tabs
    FROM (
        SELECT tab_name, SUM(COALESCE(session_duration_seconds, 0)) as total_time
        FROM tab_usage_analytics
        WHERE user_id = p_user_id AND session_start >= v_start_date
        GROUP BY tab_name
        LIMIT 5
    ) t;
    
    -- Calculate engagement score (0-100)
    v_engagement_score := LEAST(100, GREATEST(0, 
        (COALESCE(v_total_time, 0) / 60) + -- Minutes -> hours factor
        (COALESCE(v_avg_session, 0) * 2) -- Session quality factor
    ))::INTEGER;
    
    -- Get most active hour
    SELECT EXTRACT(HOUR FROM session_start)::INTEGER
    INTO v_most_active_hour
    FROM tab_usage_analytics
    WHERE user_id = p_user_id AND session_start >= v_start_date
    GROUP BY EXTRACT(HOUR FROM session_start)
    ORDER BY COUNT(*) DESC
    LIMIT 1;
    
    -- Calculate streak days (consecutive days with activity)
    WITH daily_activity AS (
        SELECT usage_date,
               ROW_NUMBER() OVER (ORDER BY usage_date DESC) as rn,
               usage_date - ROW_NUMBER() OVER (ORDER BY usage_date DESC) * INTERVAL '1 day' as group_date
        FROM daily_tab_usage_summary
        WHERE user_id = p_user_id 
        AND usage_date <= CURRENT_DATE
        AND total_sessions > 0
        ORDER BY usage_date DESC
    )
    SELECT COUNT(*)
    INTO v_streak_days
    FROM daily_activity
    WHERE group_date = (
        SELECT group_date FROM daily_activity WHERE rn = 1
    );
    
    RETURN QUERY
    SELECT 
        COALESCE(v_total_time, 0),
        COALESCE(v_avg_session, 0),
        COALESCE(v_favorite_tabs, '{}'),
        COALESCE(v_engagement_score, 0),
        COALESCE(v_most_active_hour, 12),
        COALESCE(v_streak_days, 0);
END;
$$;

-- =============================================================================
-- MAINTENANCE AND CLEANUP FUNCTIONS
-- =============================================================================

-- Daily maintenance for tabs system
CREATE OR REPLACE FUNCTION daily_tabs_maintenance()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_old_analytics INTEGER;
    v_expired_polls INTEGER;
    v_updated_summaries INTEGER;
    v_result TEXT;
BEGIN
    -- Clean up old analytics data (older than 90 days)
    DELETE FROM tab_usage_analytics 
    WHERE session_start < NOW() - INTERVAL '90 days';
    GET DIAGNOSTICS v_old_analytics = ROW_COUNT;
    
    -- Deactivate expired polls
    UPDATE polls 
    SET is_active = false 
    WHERE ends_at < NOW() AND is_active = true;
    GET DIAGNOSTICS v_expired_polls = ROW_COUNT;
    
    -- Generate daily summaries for yesterday
    WITH summary_generation AS (
        SELECT generate_daily_usage_summary(user_id, CURRENT_DATE - 1)
        FROM auth.users
        WHERE EXISTS (
            SELECT 1 FROM tab_usage_analytics 
            WHERE user_id = auth.users.id 
            AND DATE(session_start) = CURRENT_DATE - 1
        )
    )
    SELECT COUNT(*) INTO v_updated_summaries FROM summary_generation;
    
    v_result := format(
        'Tabs maintenance completed: %s old analytics cleaned, %s polls expired, %s summaries updated',
        v_old_analytics, v_expired_polls, v_updated_summaries
    );
    
    RETURN v_result;
END;
$$;

-- =============================================================================
-- GRANT PERMISSIONS
-- =============================================================================

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION register_tab TO service_role;
GRANT EXECUTE ON FUNCTION update_tab_preferences TO authenticated;
GRANT EXECUTE ON FUNCTION track_tab_usage TO authenticated;
GRANT EXECUTE ON FUNCTION manage_home_screen_app TO service_role;
GRANT EXECUTE ON FUNCTION track_app_launch TO authenticated;
GRANT EXECUTE ON FUNCTION customize_home_layout TO authenticated;
GRANT EXECUTE ON FUNCTION create_glitter_post TO authenticated;
GRANT EXECUTE ON FUNCTION add_glitter_comment TO authenticated;
GRANT EXECUTE ON FUNCTION add_glitter_reaction TO authenticated;
GRANT EXECUTE ON FUNCTION remove_glitter_reaction TO authenticated;
GRANT EXECUTE ON FUNCTION setup_user_horoscope TO authenticated;
GRANT EXECUTE ON FUNCTION get_daily_horoscope TO authenticated;
GRANT EXECUTE ON FUNCTION award_horoscope_coins TO authenticated;
GRANT EXECUTE ON FUNCTION perform_tarot_reading TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_tarot_history TO authenticated;
GRANT EXECUTE ON FUNCTION get_oracle_guidance TO authenticated;
GRANT EXECUTE ON FUNCTION rate_oracle_consultation TO authenticated;
GRANT EXECUTE ON FUNCTION get_8ball_response TO authenticated;
GRANT EXECUTE ON FUNCTION submit_confession TO authenticated;
GRANT EXECUTE ON FUNCTION create_poll TO authenticated;
GRANT EXECUTE ON FUNCTION vote_on_poll TO authenticated;
GRANT EXECUTE ON FUNCTION generate_daily_usage_summary TO service_role;
GRANT EXECUTE ON FUNCTION get_user_engagement_analytics TO authenticated;
GRANT EXECUTE ON FUNCTION daily_tabs_maintenance TO service_role;

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON FUNCTION register_tab IS 'Register a new tab in the system with default user preferences';
COMMENT ON FUNCTION track_tab_usage IS 'Track user tab usage for analytics and personalization';
COMMENT ON FUNCTION create_glitter_post IS 'Create a new social media post on Glitter Board';
COMMENT ON FUNCTION get_daily_horoscope IS 'Get personalized daily horoscope reading for user';
COMMENT ON FUNCTION perform_tarot_reading IS 'Perform tarot card reading with interpretation';
COMMENT ON FUNCTION get_oracle_guidance IS 'Get personalized oracle wisdom and guidance';
COMMENT ON FUNCTION create_poll IS 'Create a new community poll with options';
COMMENT ON FUNCTION generate_daily_usage_summary IS 'Generate daily analytics summary for user engagement';
COMMENT ON FUNCTION daily_tabs_maintenance IS 'Daily maintenance routine for tabs system optimization';

-- Setup completion message
SELECT 'Tabs Business Logic Setup Complete!' as status, NOW() as setup_completed_at;
