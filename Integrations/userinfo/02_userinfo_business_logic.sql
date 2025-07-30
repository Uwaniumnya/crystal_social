-- Crystal Social UserInfo System - Business Logic and Functions
-- File: 02_userinfo_business_logic.sql
-- Purpose: Stored procedures, functions, and business logic for comprehensive user information management

-- =============================================================================
-- USER INFO CORE FUNCTIONS
-- =============================================================================

-- Get complete user information with categories and free text
CREATE OR REPLACE FUNCTION get_user_info(
    p_user_id UUID
)
RETURNS TABLE (
    user_id UUID,
    username TEXT,
    avatar_url TEXT,
    avatar_decoration TEXT,
    bio TEXT,
    categories JSONB,
    free_text TEXT,
    completion_percentage DECIMAL(5,2),
    total_items INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_data RECORD;
    v_categories JSONB := '{}';
    v_free_text TEXT := '';
    v_completion DECIMAL(5,2) := 0.00;
    v_total_items INTEGER := 0;
BEGIN
    -- Get basic user data
    SELECT u.id, u.email as username, u.raw_user_meta_data->>'avatar_url' as avatar_url,
           u.raw_user_meta_data->>'avatar_decoration' as avatar_decoration,
           u.raw_user_meta_data->>'bio' as bio
    INTO v_user_data
    FROM auth.users u
    WHERE u.id = p_user_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found: %', p_user_id;
    END IF;
    
    -- Build categories JSON with items
    SELECT json_object_agg(
        cat.category_name,
        json_build_object(
            'display_name', cat.display_name,
            'description', cat.description,
            'icon_name', cat.icon_name,
            'color_hex', cat.color_hex,
            'category_group', cat.category_group,
            'items', COALESCE(items.category_items, '[]'::json),
            'item_count', COALESCE(items.item_count, 0),
            'is_expanded', COALESCE(prefs.is_expanded, false),
            'is_favorite', COALESCE(prefs.is_favorite, false),
            'custom_order', COALESCE(prefs.custom_order, cat.category_order)
        )
    )
    INTO v_categories
    FROM user_info_categories cat
    LEFT JOIN (
        SELECT 
            ui.category,
            json_agg(ui.content ORDER BY ui.created_at) as category_items,
            COUNT(*) as item_count
        FROM user_info ui
        WHERE ui.user_id = p_user_id AND ui.info_type = 'category'
        GROUP BY ui.category
    ) items ON cat.category_name = items.category
    LEFT JOIN user_category_preferences prefs ON cat.category_name = prefs.category_name 
        AND prefs.user_id = p_user_id
    WHERE cat.is_active = true
    ORDER BY COALESCE(prefs.custom_order, cat.category_order);
    
    -- Get free text content
    SELECT ui.content INTO v_free_text
    FROM user_info ui
    WHERE ui.user_id = p_user_id AND ui.info_type = 'free_text'
    ORDER BY ui.created_at DESC
    LIMIT 1;
    
    -- Get profile completion and total items
    SELECT 
        COALESCE(pc.completion_percentage, 0),
        COALESCE(pc.total_items_count, 0)
    INTO v_completion, v_total_items
    FROM user_profile_completion pc
    WHERE pc.user_id = p_user_id;
    
    -- Return combined data
    RETURN QUERY
    SELECT 
        p_user_id,
        v_user_data.username,
        v_user_data.avatar_url,
        v_user_data.avatar_decoration,
        v_user_data.bio,
        COALESCE(v_categories, '{}'::jsonb),
        COALESCE(v_free_text, ''),
        v_completion,
        v_total_items;
END;
$$;

-- Add item to a category
CREATE OR REPLACE FUNCTION add_category_item(
    p_user_id UUID,
    p_category_name VARCHAR(100),
    p_content TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_item_id UUID;
    v_category_max_items INTEGER;
    v_current_items INTEGER;
    v_validation_rules JSONB;
BEGIN
    -- Validate category exists and is active
    SELECT max_items, validation_rules 
    INTO v_category_max_items, v_validation_rules
    FROM user_info_categories 
    WHERE category_name = p_category_name AND is_active = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Category not found or inactive: %', p_category_name;
    END IF;
    
    -- Validate content
    IF validate_category_content(p_content, v_validation_rules) IS NOT NULL THEN
        RAISE EXCEPTION 'Content validation failed: %', validate_category_content(p_content, v_validation_rules);
    END IF;
    
    -- Check max items limit
    IF v_category_max_items IS NOT NULL THEN
        SELECT COUNT(*) INTO v_current_items
        FROM user_info 
        WHERE user_id = p_user_id AND category = p_category_name AND info_type = 'category';
        
        IF v_current_items >= v_category_max_items THEN
            RAISE EXCEPTION 'Maximum items limit (%) reached for category: %', v_category_max_items, p_category_name;
        END IF;
    END IF;
    
    -- Insert the item
    INSERT INTO user_info (user_id, category, content, info_type)
    VALUES (p_user_id, p_category_name, p_content, 'category')
    RETURNING id INTO v_item_id;
    
    -- Update profile completion
    PERFORM update_profile_completion(p_user_id);
    
    -- Log interaction
    PERFORM log_user_interaction(p_user_id, p_user_id, 'category_item_add', p_category_name, 
        json_build_object('item_id', v_item_id, 'content_length', length(p_content)));
    
    RETURN v_item_id;
END;
$$;

-- Remove item from a category
CREATE OR REPLACE FUNCTION remove_category_item(
    p_user_id UUID,
    p_category_name VARCHAR(100),
    p_content TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_item_id UUID;
BEGIN
    -- Find and delete the item
    DELETE FROM user_info 
    WHERE user_id = p_user_id 
    AND category = p_category_name 
    AND content = p_content 
    AND info_type = 'category'
    RETURNING id INTO v_item_id;
    
    IF v_item_id IS NULL THEN
        RETURN false;
    END IF;
    
    -- Update profile completion
    PERFORM update_profile_completion(p_user_id);
    
    -- Log interaction
    PERFORM log_user_interaction(p_user_id, p_user_id, 'category_item_remove', p_category_name,
        json_build_object('item_id', v_item_id, 'content', p_content));
    
    RETURN true;
END;
$$;

-- Save or update free text content
CREATE OR REPLACE FUNCTION save_free_text(
    p_user_id UUID,
    p_content TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_item_id UUID;
    v_existing_id UUID;
BEGIN
    -- Validate content length
    IF length(p_content) > 2000 THEN
        RAISE EXCEPTION 'Free text content too long (max 2000 characters)';
    END IF;
    
    -- Check for existing free text entry
    SELECT id INTO v_existing_id
    FROM user_info 
    WHERE user_id = p_user_id AND info_type = 'free_text'
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF p_content = '' OR p_content IS NULL THEN
        -- Delete existing free text if content is empty
        IF v_existing_id IS NOT NULL THEN
            DELETE FROM user_info WHERE id = v_existing_id;
        END IF;
        v_item_id := NULL;
    ELSE
        IF v_existing_id IS NOT NULL THEN
            -- Update existing entry
            UPDATE user_info 
            SET content = p_content, updated_at = NOW()
            WHERE id = v_existing_id;
            v_item_id := v_existing_id;
        ELSE
            -- Create new entry
            INSERT INTO user_info (user_id, content, info_type)
            VALUES (p_user_id, p_content, 'free_text')
            RETURNING id INTO v_item_id;
        END IF;
    END IF;
    
    -- Update profile completion
    PERFORM update_profile_completion(p_user_id);
    
    -- Log interaction
    PERFORM log_user_interaction(p_user_id, p_user_id, 'free_text_update', NULL,
        json_build_object('content_length', length(COALESCE(p_content, '')), 'has_content', p_content IS NOT NULL AND p_content != ''));
    
    RETURN v_item_id;
END;
$$;

-- =============================================================================
-- USER SEARCH AND DISCOVERY FUNCTIONS
-- =============================================================================

-- Search users with advanced filtering
CREATE OR REPLACE FUNCTION search_users(
    p_search_query TEXT DEFAULT '',
    p_category_filters TEXT[] DEFAULT '{}',
    p_min_completion INTEGER DEFAULT 0,
    p_max_completion INTEGER DEFAULT 100,
    p_include_private BOOLEAN DEFAULT false,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    user_id UUID,
    username TEXT,
    avatar_url TEXT,
    avatar_decoration TEXT,
    bio TEXT,
    completion_percentage DECIMAL(5,2),
    total_items INTEGER,
    category_count INTEGER,
    has_free_text BOOLEAN,
    profile_quality_score DECIMAL(3,2),
    last_active TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.email as username,
        u.raw_user_meta_data->>'avatar_url' as avatar_url,
        u.raw_user_meta_data->>'avatar_decoration' as avatar_decoration,
        u.raw_user_meta_data->>'bio' as bio,
        COALESCE(pc.completion_percentage, 0) as completion_percentage,
        COALESCE(pc.total_items_count, 0) as total_items,
        COALESCE(pc.total_categories_used, 0) as category_count,
        COALESCE(pc.has_free_text, false) as has_free_text,
        COALESCE(pc.profile_quality_score, 0) as profile_quality_score,
        u.updated_at as last_active
    FROM auth.users u
    LEFT JOIN user_profile_completion pc ON u.id = pc.user_id
    LEFT JOIN user_discovery_settings ds ON u.id = ds.user_id
    WHERE 
        -- Privacy filters
        (p_include_private OR COALESCE(ds.is_discoverable, true) = true)
        AND (p_include_private OR COALESCE(ds.privacy_level, 'public') = 'public')
        
        -- Completion filters
        AND COALESCE(pc.completion_percentage, 0) >= p_min_completion
        AND COALESCE(pc.completion_percentage, 0) <= p_max_completion
        
        -- Text search
        AND (
            p_search_query = '' OR
            u.email ILIKE '%' || p_search_query || '%' OR
            u.raw_user_meta_data->>'bio' ILIKE '%' || p_search_query || '%' OR
            EXISTS (
                SELECT 1 FROM user_info ui 
                WHERE ui.user_id = u.id 
                AND ui.content ILIKE '%' || p_search_query || '%'
            )
        )
        
        -- Category filters
        AND (
            array_length(p_category_filters, 1) IS NULL OR
            EXISTS (
                SELECT 1 FROM user_info ui 
                WHERE ui.user_id = u.id 
                AND ui.category = ANY(p_category_filters)
            )
        )
    ORDER BY 
        pc.profile_quality_score DESC NULLS LAST,
        pc.completion_percentage DESC NULLS LAST,
        u.updated_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- Get user discovery statistics
CREATE OR REPLACE FUNCTION get_user_discovery_stats(
    p_user_id UUID
)
RETURNS TABLE (
    total_profile_views INTEGER,
    unique_viewers INTEGER,
    recent_views_7d INTEGER,
    popular_categories TEXT[],
    discovery_rank INTEGER,
    engagement_score DECIMAL(5,2),
    profile_completeness DECIMAL(5,2)
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(SUM(ua.total_profile_views), 0)::INTEGER as total_profile_views,
        COALESCE(SUM(ua.unique_viewers), 0)::INTEGER as unique_viewers,
        COALESCE(COUNT(DISTINCT ui.viewer_user_id) FILTER (WHERE ui.created_at >= NOW() - INTERVAL '7 days'), 0)::INTEGER as recent_views_7d,
        COALESCE(ARRAY_AGG(DISTINCT elem) FILTER (WHERE elem IS NOT NULL), '{}') as popular_categories,
        COALESCE(MAX(ua.discovery_rank), 0)::INTEGER as discovery_rank,
        COALESCE(MAX(ua.engagement_score), 0) as engagement_score,
        COALESCE(MAX(pc.completion_percentage), 0) as profile_completeness
    FROM user_profile_completion pc
    LEFT JOIN user_info_analytics ua ON pc.user_id = ua.user_id
    LEFT JOIN user_info_interactions ui ON pc.user_id = ui.viewed_user_id
    LEFT JOIN LATERAL unnest(ua.popular_categories) as elem ON true
    WHERE pc.user_id = p_user_id
    GROUP BY pc.user_id;
END;
$$;

-- =============================================================================
-- PROFILE COMPLETION AND QUALITY FUNCTIONS
-- =============================================================================

-- Calculate and update profile completion
DROP FUNCTION IF EXISTS update_profile_completion(UUID);
CREATE OR REPLACE FUNCTION update_profile_completion(
    p_user_id UUID
)
RETURNS DECIMAL(5,2)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_completion_score INTEGER := 0;
    v_completion_percentage DECIMAL(5,2);
    v_quality_score DECIMAL(3,2) := 0.0;
    v_total_items INTEGER := 0;
    v_categories_used INTEGER := 0;
    v_has_free_text BOOLEAN := false;
    v_has_avatar BOOLEAN := false;
    v_has_bio BOOLEAN := false;
    v_user_data RECORD;
BEGIN
    -- Get basic user data
    SELECT 
        u.raw_user_meta_data->>'avatar_url' IS NOT NULL as has_avatar,
        u.raw_user_meta_data->>'bio' IS NOT NULL AND u.raw_user_meta_data->>'bio' != '' as has_bio
    INTO v_user_data
    FROM auth.users u
    WHERE u.id = p_user_id;
    
    v_has_avatar := COALESCE(v_user_data.has_avatar, false);
    v_has_bio := COALESCE(v_user_data.has_bio, false);
    
    -- Count category items and categories used
    SELECT 
        COUNT(*) as total_items,
        COUNT(DISTINCT category) as categories_used
    INTO v_total_items, v_categories_used
    FROM user_info
    WHERE user_id = p_user_id AND info_type = 'category';
    
    -- Check for free text
    SELECT EXISTS(
        SELECT 1 FROM user_info 
        WHERE user_id = p_user_id AND info_type = 'free_text' AND content IS NOT NULL AND content != ''
    ) INTO v_has_free_text;
    
    -- Calculate completion score (0-100 points)
    -- Basic profile info (30 points max)
    IF v_has_avatar THEN v_completion_score := v_completion_score + 10; END IF;
    IF v_has_bio THEN v_completion_score := v_completion_score + 20; END IF;
    
    -- Category content (50 points max)
    v_completion_score := v_completion_score + LEAST(50, v_categories_used * 3 + v_total_items);
    
    -- Free text (20 points max)
    IF v_has_free_text THEN v_completion_score := v_completion_score + 20; END IF;
    
    v_completion_percentage := LEAST(100.0, v_completion_score::DECIMAL(5,2));
    
    -- Calculate quality score (0-10 based on content richness)
    v_quality_score := LEAST(10.0, 
        (v_completion_percentage / 10.0) + 
        (v_categories_used * 0.2) + 
        (CASE WHEN v_has_free_text THEN 1.0 ELSE 0.0 END)
    );
    
    -- Update or insert profile completion record
    INSERT INTO user_profile_completion (
        user_id, completion_percentage, total_categories_used, total_items_count,
        has_free_text, has_avatar, has_bio, completion_score, profile_quality_score,
        last_updated_at
    ) VALUES (
        p_user_id, v_completion_percentage, v_categories_used, v_total_items,
        v_has_free_text, v_has_avatar, v_has_bio, v_completion_score, v_quality_score,
        NOW()
    )
    ON CONFLICT (user_id)
    DO UPDATE SET
        completion_percentage = v_completion_percentage,
        total_categories_used = v_categories_used,
        total_items_count = v_total_items,
        has_free_text = v_has_free_text,
        has_avatar = v_has_avatar,
        has_bio = v_has_bio,
        completion_score = v_completion_score,
        profile_quality_score = v_quality_score,
        last_updated_at = NOW();
    
    RETURN v_completion_percentage;
END;
$$;

-- Get profile completion insights
CREATE OR REPLACE FUNCTION get_profile_insights(
    p_user_id UUID
)
RETURNS TABLE (
    completion_percentage DECIMAL(5,2),
    quality_score DECIMAL(3,2),
    missing_elements TEXT[],
    suggestions TEXT[],
    strengths TEXT[],
    category_distribution JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_completion RECORD;
    v_missing TEXT[] := '{}';
    v_suggestions TEXT[] := '{}';
    v_strengths TEXT[] := '{}';
    v_category_dist JSONB := '{}';
BEGIN
    -- Get current completion data
    SELECT * INTO v_completion
    FROM user_profile_completion
    WHERE user_id = p_user_id;
    
    -- Identify missing elements
    IF NOT COALESCE(v_completion.has_avatar, false) THEN
        v_missing := array_append(v_missing, 'profile_avatar');
        v_suggestions := array_append(v_suggestions, 'Add a profile picture to help others recognize you');
    END IF;
    
    IF NOT COALESCE(v_completion.has_bio, false) THEN
        v_missing := array_append(v_missing, 'bio');
        v_suggestions := array_append(v_suggestions, 'Write a brief bio to introduce yourself');
    END IF;
    
    IF NOT COALESCE(v_completion.has_free_text, false) THEN
        v_missing := array_append(v_missing, 'free_text');
        v_suggestions := array_append(v_suggestions, 'Share more about yourself in the free writing section');
    END IF;
    
    IF COALESCE(v_completion.total_categories_used, 0) < 5 THEN
        v_missing := array_append(v_missing, 'category_diversity');
        v_suggestions := array_append(v_suggestions, 'Add information to more categories to showcase different aspects of yourself');
    END IF;
    
    -- Identify strengths
    IF COALESCE(v_completion.total_items_count, 0) > 10 THEN
        v_strengths := array_append(v_strengths, 'detailed_profile');
    END IF;
    
    IF COALESCE(v_completion.total_categories_used, 0) > 8 THEN
        v_strengths := array_append(v_strengths, 'diverse_categories');
    END IF;
    
    IF COALESCE(v_completion.has_free_text, false) THEN
        v_strengths := array_append(v_strengths, 'personal_expression');
    END IF;
    
    -- Get category distribution
    SELECT json_object_agg(category, item_count)
    INTO v_category_dist
    FROM (
        SELECT category, COUNT(*) as item_count
        FROM user_info
        WHERE user_id = p_user_id AND info_type = 'category'
        GROUP BY category
    ) dist;
    
    RETURN QUERY
    SELECT 
        COALESCE(v_completion.completion_percentage, 0),
        COALESCE(v_completion.profile_quality_score, 0),
        v_missing,
        v_suggestions,
        v_strengths,
        COALESCE(v_category_dist, '{}'::jsonb);
END;
$$;

-- =============================================================================
-- CATEGORY MANAGEMENT FUNCTIONS
-- =============================================================================

-- Update user category preferences
CREATE OR REPLACE FUNCTION update_category_preferences(
    p_user_id UUID,
    p_category_name VARCHAR(100),
    p_is_favorite BOOLEAN DEFAULT NULL,
    p_is_hidden BOOLEAN DEFAULT NULL,
    p_is_expanded BOOLEAN DEFAULT NULL,
    p_custom_order INTEGER DEFAULT NULL,
    p_custom_icon VARCHAR(100) DEFAULT NULL,
    p_custom_color VARCHAR(7) DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Verify category exists
    IF NOT EXISTS (SELECT 1 FROM user_info_categories WHERE category_name = p_category_name AND is_active = true) THEN
        RAISE EXCEPTION 'Category not found: %', p_category_name;
    END IF;
    
    -- Insert or update preferences
    INSERT INTO user_category_preferences (
        user_id, category_name, is_favorite, is_hidden, is_expanded, 
        custom_order, custom_icon, custom_color
    ) VALUES (
        p_user_id, p_category_name, 
        COALESCE(p_is_favorite, false),
        COALESCE(p_is_hidden, false),
        COALESCE(p_is_expanded, false),
        p_custom_order, p_custom_icon, p_custom_color
    )
    ON CONFLICT (user_id, category_name)
    DO UPDATE SET
        is_favorite = COALESCE(p_is_favorite, user_category_preferences.is_favorite),
        is_hidden = COALESCE(p_is_hidden, user_category_preferences.is_hidden),
        is_expanded = COALESCE(p_is_expanded, user_category_preferences.is_expanded),
        custom_order = COALESCE(p_custom_order, user_category_preferences.custom_order),
        custom_icon = COALESCE(p_custom_icon, user_category_preferences.custom_icon),
        custom_color = COALESCE(p_custom_color, user_category_preferences.custom_color),
        last_accessed_at = NOW(),
        access_count = user_category_preferences.access_count + 1;
    
    RETURN true;
END;
$$;

-- Get category statistics across all users
CREATE OR REPLACE FUNCTION get_category_statistics()
RETURNS TABLE (
    category_name VARCHAR(100),
    display_name VARCHAR(255),
    total_users INTEGER,
    total_items INTEGER,
    avg_items_per_user DECIMAL(5,2),
    popularity_rank INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    WITH category_stats AS (
        SELECT 
            cat.category_name,
            cat.display_name,
            COUNT(DISTINCT ui.user_id) as total_users,
            COUNT(ui.id) as total_items,
            ROUND(COUNT(ui.id)::DECIMAL / NULLIF(COUNT(DISTINCT ui.user_id), 0), 2) as avg_items_per_user
        FROM user_info_categories cat
        LEFT JOIN user_info ui ON cat.category_name = ui.category AND ui.info_type = 'category'
        WHERE cat.is_active = true
        GROUP BY cat.category_name, cat.display_name
    )
    SELECT 
        cs.category_name,
        cs.display_name,
        cs.total_users::INTEGER,
        cs.total_items::INTEGER,
        cs.avg_items_per_user,
        ROW_NUMBER() OVER (ORDER BY cs.total_users DESC, cs.total_items DESC)::INTEGER as popularity_rank
    FROM category_stats cs
    ORDER BY cs.total_users DESC, cs.total_items DESC;
END;
$$;

-- =============================================================================
-- VALIDATION AND UTILITY FUNCTIONS
-- =============================================================================

-- Validate category content against rules
CREATE OR REPLACE FUNCTION validate_category_content(
    p_content TEXT,
    p_validation_rules JSONB DEFAULT '{}'
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_min_length INTEGER;
    v_max_length INTEGER;
    v_allowed_patterns TEXT[];
    v_blocked_words TEXT[];
    v_word TEXT;
BEGIN
    -- Basic length validation
    IF p_content IS NULL OR trim(p_content) = '' THEN
        RETURN 'Content cannot be empty';
    END IF;
    
    -- Get validation rules
    v_min_length := COALESCE((p_validation_rules->>'min_length')::INTEGER, 1);
    v_max_length := COALESCE((p_validation_rules->>'max_length')::INTEGER, 200);
    v_blocked_words := COALESCE(array(SELECT jsonb_array_elements_text(p_validation_rules->'blocked_words')), '{}');
    
    -- Length validation
    IF length(trim(p_content)) < v_min_length THEN
        RETURN format('Content must be at least %s characters', v_min_length);
    END IF;
    
    IF length(p_content) > v_max_length THEN
        RETURN format('Content must be less than %s characters', v_max_length);
    END IF;
    
    -- Check for blocked words
    FOREACH v_word IN ARRAY v_blocked_words
    LOOP
        IF lower(p_content) LIKE '%' || lower(v_word) || '%' THEN
            RETURN 'Content contains inappropriate language';
        END IF;
    END LOOP;
    
    RETURN NULL; -- No validation errors
END;
$$;

-- Log user interaction for analytics
CREATE OR REPLACE FUNCTION log_user_interaction(
    p_viewer_user_id UUID,
    p_viewed_user_id UUID,
    p_interaction_type VARCHAR(50),
    p_category_name VARCHAR(100) DEFAULT NULL,
    p_interaction_details JSONB DEFAULT '{}'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_interaction_id UUID;
BEGIN
    INSERT INTO user_info_interactions (
        viewer_user_id, viewed_user_id, interaction_type, category_name, interaction_details
    ) VALUES (
        p_viewer_user_id, p_viewed_user_id, p_interaction_type, p_category_name, p_interaction_details
    ) RETURNING id INTO v_interaction_id;
    
    RETURN v_interaction_id;
END;
$$;

-- Create profile backup
CREATE OR REPLACE FUNCTION create_profile_backup(
    p_user_id UUID,
    p_backup_reason VARCHAR(100) DEFAULT 'manual'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_backup_id UUID;
    v_backup_data JSONB;
    v_version_number INTEGER;
BEGIN
    -- Get current version number
    SELECT COALESCE(MAX(version_number), 0) + 1
    INTO v_version_number
    FROM user_info_versions
    WHERE user_id = p_user_id;
    
    -- Build complete backup data
    SELECT json_build_object(
        'user_info', json_agg(json_build_object(
            'id', ui.id,
            'category', ui.category,
            'content', ui.content,
            'info_type', ui.info_type,
            'created_at', ui.created_at,
            'updated_at', ui.updated_at
        )),
        'category_preferences', (
            SELECT json_agg(json_build_object(
                'category_name', cp.category_name,
                'is_favorite', cp.is_favorite,
                'is_hidden', cp.is_hidden,
                'custom_order', cp.custom_order,
                'custom_icon', cp.custom_icon,
                'custom_color', cp.custom_color
            ))
            FROM user_category_preferences cp
            WHERE cp.user_id = p_user_id
        ),
        'discovery_settings', (
            SELECT row_to_json(ds)
            FROM user_discovery_settings ds
            WHERE ds.user_id = p_user_id
        ),
        'profile_completion', (
            SELECT row_to_json(pc)
            FROM user_profile_completion pc
            WHERE pc.user_id = p_user_id
        ),
        'backup_metadata', json_build_object(
            'version', v_version_number,
            'created_at', NOW(),
            'reason', p_backup_reason
        )
    )
    INTO v_backup_data
    FROM user_info ui
    WHERE ui.user_id = p_user_id;
    
    -- Insert backup record
    INSERT INTO user_info_versions (
        user_id, version_number, backup_data, backup_reason, 
        backup_size_bytes
    ) VALUES (
        p_user_id, v_version_number, v_backup_data, p_backup_reason,
        length(v_backup_data::text)
    ) RETURNING id INTO v_backup_id;
    
    RETURN v_backup_id;
END;
$$;

-- =============================================================================
-- ANALYTICS AND INSIGHTS FUNCTIONS
-- =============================================================================

-- Update daily analytics for a user
CREATE OR REPLACE FUNCTION update_user_analytics(
    p_user_id UUID,
    p_analysis_date DATE DEFAULT CURRENT_DATE
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_profile_views INTEGER := 0;
    v_unique_viewers INTEGER := 0;
    v_category_interactions JSONB := '{}';
    v_search_appearances INTEGER := 0;
    v_engagement_score DECIMAL(5,2) := 0.00;
    v_content_freshness DECIMAL(3,2) := 0.00;
    v_popular_categories TEXT[] := '{}';
BEGIN
    -- Calculate profile views for the date
    SELECT 
        COUNT(*),
        COUNT(DISTINCT viewer_user_id)
    INTO v_profile_views, v_unique_viewers
    FROM user_info_interactions
    WHERE viewed_user_id = p_user_id 
    AND DATE(created_at) = p_analysis_date
    AND interaction_type = 'profile_view';
    
    -- Calculate category interaction breakdown
    SELECT json_object_agg(category_name, interaction_count)
    INTO v_category_interactions
    FROM (
        SELECT 
            category_name,
            COUNT(*) as interaction_count
        FROM user_info_interactions
        WHERE viewed_user_id = p_user_id
        AND DATE(created_at) = p_analysis_date
        AND category_name IS NOT NULL
        GROUP BY category_name
    ) cat_stats;
    
    -- Calculate engagement score
    v_engagement_score := (v_profile_views * 1.0) + (v_unique_viewers * 2.0);
    
    -- Calculate content freshness (days since last update)
    SELECT 10.0 - LEAST(10.0, EXTRACT(days FROM NOW() - MAX(updated_at)))
    INTO v_content_freshness
    FROM user_info
    WHERE user_id = p_user_id;
    
    -- Get popular categories (most viewed)
    SELECT array_agg(category_name ORDER BY interaction_count DESC)
    INTO v_popular_categories
    FROM (
        SELECT 
            category_name,
            COUNT(*) as interaction_count
        FROM user_info_interactions
        WHERE viewed_user_id = p_user_id
        AND category_name IS NOT NULL
        GROUP BY category_name
        LIMIT 5
    ) popular;
    
    -- Insert or update analytics record
    INSERT INTO user_info_analytics (
        user_id, analysis_date, total_profile_views, unique_viewers,
        category_interactions, search_appearances, engagement_score,
        content_freshness_score, popular_categories
    ) VALUES (
        p_user_id, p_analysis_date, v_profile_views, v_unique_viewers,
        COALESCE(v_category_interactions, '{}'::jsonb), v_search_appearances,
        v_engagement_score, COALESCE(v_content_freshness, 0.00),
        COALESCE(v_popular_categories, '{}')
    )
    ON CONFLICT (user_id, analysis_date)
    DO UPDATE SET
        total_profile_views = v_profile_views,
        unique_viewers = v_unique_viewers,
        category_interactions = COALESCE(v_category_interactions, '{}'::jsonb),
        engagement_score = v_engagement_score,
        content_freshness_score = COALESCE(v_content_freshness, 0.00),
        popular_categories = COALESCE(v_popular_categories, '{}'),
        updated_at = NOW();
    
    RETURN true;
END;
$$;

-- =============================================================================
-- GRANT PERMISSIONS
-- =============================================================================

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION get_user_info TO authenticated;
GRANT EXECUTE ON FUNCTION add_category_item TO authenticated;
GRANT EXECUTE ON FUNCTION remove_category_item TO authenticated;
GRANT EXECUTE ON FUNCTION save_free_text TO authenticated;
GRANT EXECUTE ON FUNCTION search_users TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_discovery_stats TO authenticated;
GRANT EXECUTE ON FUNCTION update_profile_completion TO authenticated;
GRANT EXECUTE ON FUNCTION get_profile_insights TO authenticated;
GRANT EXECUTE ON FUNCTION update_category_preferences TO authenticated;
GRANT EXECUTE ON FUNCTION get_category_statistics TO service_role;
GRANT EXECUTE ON FUNCTION validate_category_content TO authenticated;
GRANT EXECUTE ON FUNCTION log_user_interaction TO authenticated;
GRANT EXECUTE ON FUNCTION create_profile_backup TO authenticated;
GRANT EXECUTE ON FUNCTION update_user_analytics TO service_role;

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON FUNCTION get_user_info IS 'Retrieve complete user profile information with categories and completion status';
COMMENT ON FUNCTION add_category_item IS 'Add an item to a user profile category with validation';
COMMENT ON FUNCTION remove_category_item IS 'Remove an item from a user profile category';
COMMENT ON FUNCTION save_free_text IS 'Save or update user free text content';
COMMENT ON FUNCTION search_users IS 'Advanced user search with filtering and pagination';
COMMENT ON FUNCTION update_profile_completion IS 'Calculate and update user profile completion percentage';
COMMENT ON FUNCTION get_profile_insights IS 'Get profile completion insights and suggestions';
COMMENT ON FUNCTION update_category_preferences IS 'Update user preferences for categories';
COMMENT ON FUNCTION validate_category_content IS 'Validate content against category rules';
COMMENT ON FUNCTION create_profile_backup IS 'Create a complete backup of user profile data';
COMMENT ON FUNCTION update_user_analytics IS 'Update daily analytics for user profile engagement';

-- Setup completion message
SELECT 'UserInfo Business Logic Setup Complete!' as status, NOW() as setup_completed_at;
