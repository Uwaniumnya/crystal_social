-- Crystal Social Widgets System - Business Logic
-- File: 02_widgets_business_logic.sql
-- Purpose: Business logic functions for comprehensive widget system operations

-- =============================================================================
-- STICKER MANAGEMENT FUNCTIONS
-- =============================================================================

-- Upload and process a new sticker
CREATE OR REPLACE FUNCTION upload_sticker(
    p_user_id UUID,
    p_sticker_name TEXT,
    p_sticker_url TEXT,
    p_category TEXT DEFAULT 'Other',
    p_is_gif BOOLEAN DEFAULT false,
    p_file_size INTEGER DEFAULT 0,
    p_width INTEGER DEFAULT 0,
    p_height INTEGER DEFAULT 0,
    p_format TEXT DEFAULT 'png',
    p_tags TEXT[] DEFAULT '{}'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    sticker_id UUID;
    result JSON;
BEGIN
    -- Validate input
    IF p_sticker_name IS NULL OR LENGTH(TRIM(p_sticker_name)) = 0 THEN
        RETURN json_build_object('success', false, 'error', 'Sticker name is required');
    END IF;
    
    IF p_sticker_url IS NULL OR LENGTH(TRIM(p_sticker_url)) = 0 THEN
        RETURN json_build_object('success', false, 'error', 'Sticker URL is required');
    END IF;
    
    -- Insert sticker
    INSERT INTO stickers (
        user_id, sticker_name, sticker_url, category, is_gif,
        file_size, width, height, format, tags, upload_source
    ) VALUES (
        p_user_id, TRIM(p_sticker_name), p_sticker_url, p_category, p_is_gif,
        p_file_size, p_width, p_height, p_format, p_tags, 'user'
    ) RETURNING id INTO sticker_id;
    
    -- Log analytics
    INSERT INTO widget_usage_analytics (
        user_id, widget_type, action_type, item_identifier, category
    ) VALUES (
        p_user_id, 'sticker_picker', 'create', p_sticker_url, p_category
    );
    
    result := json_build_object(
        'success', true,
        'sticker_id', sticker_id,
        'message', 'Sticker uploaded successfully'
    );
    
    RETURN result;
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', 'Failed to upload sticker: ' || SQLERRM
    );
END;
$$;

-- Get user stickers with filtering and pagination
CREATE OR REPLACE FUNCTION get_user_stickers(
    p_user_id UUID,
    p_category TEXT DEFAULT NULL,
    p_search_term TEXT DEFAULT NULL,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    stickers_data JSON;
    total_count INTEGER;
BEGIN
    -- Get filtered stickers
    WITH filtered_stickers AS (
        SELECT 
            id, sticker_name, sticker_url, category, is_gif,
            file_size, width, height, format, tags, usage_count,
            created_at, updated_at
        FROM stickers
        WHERE user_id = p_user_id
        AND (p_category IS NULL OR category = p_category)
        AND (p_search_term IS NULL OR 
             sticker_name ILIKE '%' || p_search_term || '%' OR
             category ILIKE '%' || p_search_term || '%' OR
             p_search_term = ANY(tags))
        ORDER BY usage_count DESC, created_at DESC
        LIMIT p_limit OFFSET p_offset
    ),
    count_query AS (
        SELECT COUNT(*) as total
        FROM stickers
        WHERE user_id = p_user_id
        AND (p_category IS NULL OR category = p_category)
        AND (p_search_term IS NULL OR 
             sticker_name ILIKE '%' || p_search_term || '%' OR
             category ILIKE '%' || p_search_term || '%' OR
             p_search_term = ANY(tags))
    )
    SELECT 
        json_build_object(
            'stickers', json_agg(
                json_build_object(
                    'id', fs.id,
                    'name', fs.sticker_name,
                    'url', fs.sticker_url,
                    'category', fs.category,
                    'is_gif', fs.is_gif,
                    'file_size', fs.file_size,
                    'dimensions', json_build_object('width', fs.width, 'height', fs.height),
                    'format', fs.format,
                    'tags', fs.tags,
                    'usage_count', fs.usage_count,
                    'created_at', fs.created_at
                )
            ),
            'total_count', cq.total,
            'has_more', (p_offset + p_limit) < cq.total
        )
    INTO stickers_data
    FROM filtered_stickers fs
    CROSS JOIN count_query cq;
    
    RETURN COALESCE(stickers_data, json_build_object('stickers', '[]', 'total_count', 0, 'has_more', false));
END;
$$;

-- Record sticker usage and update recent list
CREATE OR REPLACE FUNCTION use_sticker(
    p_user_id UUID,
    p_sticker_url TEXT,
    p_context_type TEXT DEFAULT 'message'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Update sticker usage count
    UPDATE stickers 
    SET usage_count = usage_count + 1,
        updated_at = NOW()
    WHERE sticker_url = p_sticker_url;
    
    -- Add to recent stickers (upsert)
    INSERT INTO recent_stickers (user_id, sticker_url, used_at, context_type)
    VALUES (p_user_id, p_sticker_url, NOW(), p_context_type)
    ON CONFLICT (user_id, sticker_url) 
    DO UPDATE SET used_at = NOW(), context_type = EXCLUDED.context_type;
    
    -- Log analytics
    INSERT INTO widget_usage_analytics (
        user_id, widget_type, action_type, item_identifier, metadata
    ) VALUES (
        p_user_id, 'sticker_picker', 'select', p_sticker_url, 
        json_build_object('context_type', p_context_type)
    );
    
    RETURN json_build_object('success', true, 'message', 'Sticker usage recorded');
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- =============================================================================
-- EMOTICON MANAGEMENT FUNCTIONS
-- =============================================================================

-- Create custom emoticon
CREATE OR REPLACE FUNCTION create_custom_emoticon(
    p_user_id UUID,
    p_emoticon_text TEXT,
    p_emoticon_name TEXT DEFAULT NULL,
    p_category_name TEXT DEFAULT 'Custom'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    category_id UUID;
    emoticon_id UUID;
BEGIN
    -- Validate emoticon text
    IF p_emoticon_text IS NULL OR LENGTH(TRIM(p_emoticon_text)) = 0 THEN
        RETURN json_build_object('success', false, 'error', 'Emoticon text is required');
    END IF;
    
    -- Get or create category
    SELECT id INTO category_id
    FROM emoticon_categories
    WHERE category_name = p_category_name;
    
    IF category_id IS NULL THEN
        INSERT INTO emoticon_categories (category_name, display_name, is_active)
        VALUES (p_category_name, p_category_name, true)
        RETURNING id INTO category_id;
    END IF;
    
    -- Insert custom emoticon
    INSERT INTO custom_emoticons (
        user_id, emoticon_text, emoticon_name, category_id
    ) VALUES (
        p_user_id, TRIM(p_emoticon_text), p_emoticon_name, category_id
    ) RETURNING id INTO emoticon_id;
    
    -- Log analytics
    INSERT INTO widget_usage_analytics (
        user_id, widget_type, action_type, item_identifier, category
    ) VALUES (
        p_user_id, 'emoticon_picker', 'create', p_emoticon_text, p_category_name
    );
    
    RETURN json_build_object(
        'success', true,
        'emoticon_id', emoticon_id,
        'message', 'Custom emoticon created successfully'
    );
    
EXCEPTION 
    WHEN unique_violation THEN
        RETURN json_build_object('success', false, 'error', 'Emoticon already exists');
    WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- Record emoticon usage
CREATE OR REPLACE FUNCTION use_emoticon(
    p_user_id UUID,
    p_emoticon_text TEXT,
    p_category_name TEXT DEFAULT NULL,
    p_context_type TEXT DEFAULT 'message'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Record usage
    INSERT INTO emoticon_usage (user_id, emoticon_text, category_name, used_at, context_type)
    VALUES (p_user_id, p_emoticon_text, p_category_name, NOW(), p_context_type);
    
    -- Update custom emoticon usage count if applicable
    UPDATE custom_emoticons 
    SET usage_count = usage_count + 1
    WHERE user_id = p_user_id AND emoticon_text = p_emoticon_text;
    
    -- Log analytics
    INSERT INTO widget_usage_analytics (
        user_id, widget_type, action_type, item_identifier, category, metadata
    ) VALUES (
        p_user_id, 'emoticon_picker', 'select', p_emoticon_text, p_category_name,
        json_build_object('context_type', p_context_type)
    );
    
    RETURN json_build_object('success', true, 'message', 'Emoticon usage recorded');
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- Get user's recent emoticons
CREATE OR REPLACE FUNCTION get_recent_emoticons(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 20
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_agg(
        json_build_object(
            'emoticon_text', emoticon_text,
            'category_name', category_name,
            'last_used', used_at,
            'usage_count', usage_count
        ) ORDER BY used_at DESC
    )
    INTO result
    FROM (
        SELECT 
            emoticon_text,
            category_name,
            MAX(used_at) as used_at,
            COUNT(*) as usage_count
        FROM emoticon_usage
        WHERE user_id = p_user_id
        GROUP BY emoticon_text, category_name
        ORDER BY MAX(used_at) DESC
        LIMIT p_limit
    ) recent;
    
    RETURN COALESCE(result, '[]'::JSON);
END;
$$;

-- =============================================================================
-- BACKGROUND MANAGEMENT FUNCTIONS
-- =============================================================================

-- Set chat background for user
CREATE OR REPLACE FUNCTION set_chat_background(
    p_user_id UUID,
    p_chat_id TEXT,
    p_background_id UUID DEFAULT NULL,
    p_custom_opacity DECIMAL DEFAULT 1.0,
    p_custom_blur DECIMAL DEFAULT 0.0,
    p_custom_effects JSONB DEFAULT '{}'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Validate background exists if provided
    IF p_background_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM chat_backgrounds WHERE id = p_background_id
    ) THEN
        RETURN json_build_object('success', false, 'error', 'Background not found');
    END IF;
    
    -- Upsert user chat background
    INSERT INTO user_chat_backgrounds (
        user_id, chat_id, background_id, custom_opacity, custom_blur, custom_effects
    ) VALUES (
        p_user_id, p_chat_id, p_background_id, p_custom_opacity, p_custom_blur, p_custom_effects
    ) ON CONFLICT (user_id, chat_id) 
    DO UPDATE SET 
        background_id = EXCLUDED.background_id,
        custom_opacity = EXCLUDED.custom_opacity,
        custom_blur = EXCLUDED.custom_blur,
        custom_effects = EXCLUDED.custom_effects,
        set_at = NOW();
    
    -- Update background usage count
    IF p_background_id IS NOT NULL THEN
        UPDATE chat_backgrounds 
        SET usage_count = usage_count + 1
        WHERE id = p_background_id;
    END IF;
    
    -- Log analytics
    INSERT INTO widget_usage_analytics (
        user_id, widget_type, action_type, item_identifier, metadata
    ) VALUES (
        p_user_id, 'background_picker', 'select', p_background_id::TEXT,
        json_build_object(
            'chat_id', p_chat_id,
            'opacity', p_custom_opacity,
            'blur', p_custom_blur
        )
    );
    
    RETURN json_build_object('success', true, 'message', 'Background set successfully');
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- Create custom background
CREATE OR REPLACE FUNCTION create_custom_background(
    p_user_id UUID,
    p_background_name TEXT,
    p_background_type TEXT,
    p_background_data JSONB,
    p_preview_url TEXT DEFAULT NULL,
    p_category TEXT DEFAULT 'Custom',
    p_is_public BOOLEAN DEFAULT false
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    background_id UUID;
BEGIN
    -- Validate input
    IF p_background_name IS NULL OR LENGTH(TRIM(p_background_name)) = 0 THEN
        RETURN json_build_object('success', false, 'error', 'Background name is required');
    END IF;
    
    -- Insert background
    INSERT INTO chat_backgrounds (
        background_name, background_type, background_data, preview_url,
        category, is_preset, is_public, created_by
    ) VALUES (
        TRIM(p_background_name), p_background_type, p_background_data, p_preview_url,
        p_category, false, p_is_public, p_user_id
    ) RETURNING id INTO background_id;
    
    -- Log analytics
    INSERT INTO widget_usage_analytics (
        user_id, widget_type, action_type, item_identifier, category
    ) VALUES (
        p_user_id, 'background_picker', 'create', background_id::TEXT, p_category
    );
    
    RETURN json_build_object(
        'success', true,
        'background_id', background_id,
        'message', 'Custom background created successfully'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- =============================================================================
-- MESSAGE MANAGEMENT FUNCTIONS
-- =============================================================================

-- Create enhanced message bubble
CREATE OR REPLACE FUNCTION create_message_bubble(
    p_user_id UUID,
    p_message_id TEXT,
    p_chat_id TEXT,
    p_message_type TEXT DEFAULT 'text',
    p_content TEXT DEFAULT NULL,
    p_media_url TEXT DEFAULT NULL,
    p_sticker_url TEXT DEFAULT NULL,
    p_gif_url TEXT DEFAULT NULL,
    p_effect_type TEXT DEFAULT 'none',
    p_is_secret BOOLEAN DEFAULT false,
    p_mood TEXT DEFAULT NULL,
    p_importance_level TEXT DEFAULT 'normal',
    p_reply_to_message_id TEXT DEFAULT NULL,
    p_mentions TEXT[] DEFAULT '{}',
    p_hashtags TEXT[] DEFAULT '{}',
    p_metadata JSONB DEFAULT '{}'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    bubble_id UUID;
BEGIN
    -- Insert message bubble
    INSERT INTO message_bubbles (
        message_id, user_id, chat_id, message_type, content, media_url,
        sticker_url, gif_url, effect_type, is_secret, mood, importance_level,
        reply_to_message_id, mentions, hashtags, metadata
    ) VALUES (
        p_message_id, p_user_id, p_chat_id, p_message_type, p_content, p_media_url,
        p_sticker_url, p_gif_url, p_effect_type, p_is_secret, p_mood, p_importance_level,
        p_reply_to_message_id, p_mentions, p_hashtags, p_metadata
    ) RETURNING id INTO bubble_id;
    
    -- Log analytics
    INSERT INTO widget_usage_analytics (
        user_id, widget_type, action_type, item_identifier, metadata
    ) VALUES (
        p_user_id, 'message_bubble', 'create', p_message_id,
        json_build_object(
            'message_type', p_message_type,
            'effect_type', p_effect_type,
            'importance_level', p_importance_level
        )
    );
    
    RETURN json_build_object(
        'success', true,
        'bubble_id', bubble_id,
        'message', 'Message bubble created successfully'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- Add reaction to message
CREATE OR REPLACE FUNCTION add_widget_message_reaction(
    p_user_id UUID,
    p_message_id TEXT,
    p_reaction_emoji TEXT,
    p_reaction_type TEXT DEFAULT 'emoji'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Insert or update reaction
    INSERT INTO message_reactions (message_id, user_id, reaction_emoji, reaction_type)
    VALUES (p_message_id, p_user_id, p_reaction_emoji, p_reaction_type)
    ON CONFLICT (message_id, user_id, reaction_emoji)
    DO UPDATE SET 
        reaction_type = EXCLUDED.reaction_type,
        reacted_at = NOW();
    
    -- Log analytics
    INSERT INTO widget_usage_analytics (
        user_id, widget_type, action_type, item_identifier, metadata
    ) VALUES (
        p_user_id, 'message_bubble', 'react', p_message_id,
        json_build_object(
            'reaction_emoji', p_reaction_emoji,
            'reaction_type', p_reaction_type
        )
    );
    
    RETURN json_build_object('success', true, 'message', 'Reaction added successfully');
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- =============================================================================
-- PREFERENCE MANAGEMENT FUNCTIONS
-- =============================================================================

-- Update user widget preferences
CREATE OR REPLACE FUNCTION update_widget_preferences(
    p_user_id UUID,
    p_preferences JSONB
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    pref_keys TEXT[];
    pref_key TEXT;
    pref_value JSONB;
BEGIN
    -- Get all keys from preferences JSON
    pref_keys := ARRAY(SELECT jsonb_object_keys(p_preferences));
    
    -- Upsert user preferences
    INSERT INTO user_widget_preferences (user_id) 
    VALUES (p_user_id)
    ON CONFLICT (user_id) DO NOTHING;
    
    -- Update specific preference fields
    FOREACH pref_key IN ARRAY pref_keys
    LOOP
        pref_value := p_preferences -> pref_key;
        
        CASE pref_key
            WHEN 'favorite_sticker_categories' THEN
                UPDATE user_widget_preferences 
                SET favorite_sticker_categories = jsonb_array_to_text_array(pref_value)
                WHERE user_id = p_user_id;
            WHEN 'sticker_auto_suggest' THEN
                UPDATE user_widget_preferences 
                SET sticker_auto_suggest = (pref_value #>> '{}')::BOOLEAN
                WHERE user_id = p_user_id;
            WHEN 'enable_message_effects' THEN
                UPDATE user_widget_preferences 
                SET enable_message_effects = (pref_value #>> '{}')::BOOLEAN
                WHERE user_id = p_user_id;
            WHEN 'bubble_corner_radius' THEN
                UPDATE user_widget_preferences 
                SET bubble_corner_radius = (pref_value #>> '{}')::INTEGER
                WHERE user_id = p_user_id;
            -- Add more cases as needed
        END CASE;
    END LOOP;
    
    -- Update timestamp
    UPDATE user_widget_preferences 
    SET updated_at = NOW() 
    WHERE user_id = p_user_id;
    
    RETURN json_build_object('success', true, 'message', 'Preferences updated successfully');
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- =============================================================================
-- ANALYTICS FUNCTIONS
-- =============================================================================

-- Get widget usage analytics
CREATE OR REPLACE FUNCTION get_widget_analytics(
    p_user_id UUID DEFAULT NULL,
    p_widget_type TEXT DEFAULT NULL,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL,
    p_limit INTEGER DEFAULT 100
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    analytics_data JSON;
BEGIN
    WITH filtered_analytics AS (
        SELECT 
            widget_type,
            action_type,
            item_identifier,
            category,
            usage_timestamp,
            metadata
        FROM widget_usage_analytics
        WHERE (p_user_id IS NULL OR user_id = p_user_id)
        AND (p_widget_type IS NULL OR widget_type = p_widget_type)
        AND (p_start_date IS NULL OR DATE(usage_timestamp) >= p_start_date)
        AND (p_end_date IS NULL OR DATE(usage_timestamp) <= p_end_date)
        ORDER BY usage_timestamp DESC
        LIMIT p_limit
    )
    SELECT json_build_object(
        'analytics', json_agg(
            json_build_object(
                'widget_type', widget_type,
                'action_type', action_type,
                'item_identifier', item_identifier,
                'category', category,
                'timestamp', usage_timestamp,
                'metadata', metadata
            )
        ),
        'summary', json_build_object(
            'total_events', COUNT(*),
            'widget_types', json_agg(DISTINCT widget_type),
            'most_used_category', (
                SELECT category 
                FROM filtered_analytics 
                WHERE category IS NOT NULL 
                GROUP BY category 
                ORDER BY COUNT(*) DESC 
                LIMIT 1
            )
        )
    )
    INTO analytics_data
    FROM filtered_analytics;
    
    RETURN COALESCE(analytics_data, json_build_object('analytics', '[]', 'summary', '{}'));
END;
$$;

-- Generate daily widget statistics
CREATE OR REPLACE FUNCTION generate_daily_widget_stats(
    p_target_date DATE DEFAULT CURRENT_DATE
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    stats_generated INTEGER := 0;
    widget_types TEXT[] := ARRAY[
        'sticker_picker', 'emoticon_picker', 'background_picker', 
        'message_bubble', 'glimmer_upload', 'coin_earning'
    ];
    widget_type TEXT;
BEGIN
    -- Generate stats for each widget type
    FOREACH widget_type IN ARRAY widget_types
    LOOP
        INSERT INTO daily_widget_stats (
            stat_date, widget_type, total_opens, unique_users, 
            total_selections, total_creations, category_usage,
            avg_session_duration, avg_items_per_session
        )
        SELECT 
            p_target_date,
            widget_type,
            COUNT(CASE WHEN action_type = 'open' THEN 1 END) as total_opens,
            COUNT(DISTINCT user_id) as unique_users,
            COUNT(CASE WHEN action_type = 'select' THEN 1 END) as total_selections,
            COUNT(CASE WHEN action_type = 'create' THEN 1 END) as total_creations,
            jsonb_object_agg(
                COALESCE(category, 'unknown'), 
                COUNT(CASE WHEN category IS NOT NULL THEN 1 END)
            ) as category_usage,
            AVG(
                EXTRACT(EPOCH FROM (
                    LEAD(usage_timestamp) OVER (PARTITION BY user_id, session_id ORDER BY usage_timestamp) 
                    - usage_timestamp
                ))
            )::INTEGER * INTERVAL '1 second' as avg_session_duration,
            AVG(session_actions.actions_per_session) as avg_items_per_session
        FROM widget_usage_analytics wa
        LEFT JOIN (
            SELECT 
                session_id, 
                COUNT(*) as actions_per_session
            FROM widget_usage_analytics
            WHERE DATE(usage_timestamp) = p_target_date
            AND widget_type = widget_type
            GROUP BY session_id
        ) session_actions ON wa.session_id = session_actions.session_id
        WHERE DATE(wa.usage_timestamp) = p_target_date
        AND wa.widget_type = widget_type
        GROUP BY wa.widget_type
        ON CONFLICT (stat_date, widget_type) 
        DO UPDATE SET
            total_opens = EXCLUDED.total_opens,
            unique_users = EXCLUDED.unique_users,
            total_selections = EXCLUDED.total_selections,
            total_creations = EXCLUDED.total_creations,
            category_usage = EXCLUDED.category_usage,
            avg_session_duration = EXCLUDED.avg_session_duration,
            avg_items_per_session = EXCLUDED.avg_items_per_session;
        
        GET DIAGNOSTICS stats_generated = ROW_COUNT;
    END LOOP;
    
    RETURN json_build_object(
        'success', true,
        'date', p_target_date,
        'stats_generated', stats_generated,
        'message', 'Daily widget statistics generated successfully'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- =============================================================================
-- CACHE MANAGEMENT FUNCTIONS
-- =============================================================================

-- Clean expired cache entries
CREATE OR REPLACE FUNCTION clean_expired_cache()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Delete expired cache entries
    DELETE FROM widget_cache_entries
    WHERE expires_at IS NOT NULL 
    AND expires_at < NOW();
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- Also clean least recently used entries if cache is too large
    WITH cache_size AS (
        SELECT COUNT(*) as total_entries,
               SUM(file_size) as total_size
        FROM widget_cache_entries
    ),
    entries_to_delete AS (
        SELECT id
        FROM widget_cache_entries
        ORDER BY last_accessed ASC
        OFFSET 10000  -- Keep only 10k most recent entries
    )
    DELETE FROM widget_cache_entries
    WHERE id IN (SELECT id FROM entries_to_delete);
    
    RETURN json_build_object(
        'success', true,
        'expired_entries_deleted', deleted_count,
        'message', 'Cache cleanup completed successfully'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

-- Helper function to convert JSONB array to TEXT array
CREATE OR REPLACE FUNCTION jsonb_array_to_text_array(jsonb_array JSONB)
RETURNS TEXT[]
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    result TEXT[];
    item JSONB;
BEGIN
    IF jsonb_typeof(jsonb_array) != 'array' THEN
        RETURN NULL;
    END IF;
    
    FOR item IN SELECT jsonb_array_elements(jsonb_array)
    LOOP
        result := array_append(result, item #>> '{}');
    END LOOP;
    
    RETURN result;
END;
$$;

-- Get trending stickers based on recent usage
CREATE OR REPLACE FUNCTION get_trending_stickers(
    p_days INTEGER DEFAULT 7,
    p_limit INTEGER DEFAULT 20
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    trending_data JSON;
BEGIN
    WITH recent_usage AS (
        SELECT 
            s.id,
            s.sticker_name,
            s.sticker_url,
            s.category,
            s.is_gif,
            COUNT(rs.id) as recent_uses,
            COUNT(DISTINCT rs.user_id) as unique_users
        FROM stickers s
        INNER JOIN recent_stickers rs ON s.sticker_url = rs.sticker_url
        WHERE rs.used_at >= NOW() - (p_days || ' days')::INTERVAL
        AND s.is_public = true
        GROUP BY s.id, s.sticker_name, s.sticker_url, s.category, s.is_gif
        ORDER BY recent_uses DESC, unique_users DESC
        LIMIT p_limit
    )
    SELECT json_agg(
        json_build_object(
            'id', id,
            'name', sticker_name,
            'url', sticker_url,
            'category', category,
            'is_gif', is_gif,
            'recent_uses', recent_uses,
            'unique_users', unique_users,
            'trending_score', (recent_uses * 0.7 + unique_users * 0.3)
        ) ORDER BY (recent_uses * 0.7 + unique_users * 0.3) DESC
    )
    INTO trending_data
    FROM recent_usage;
    
    RETURN COALESCE(trending_data, '[]'::JSON);
END;
$$;

-- =============================================================================
-- GRANT PERMISSIONS
-- =============================================================================

-- Grant execution permissions to authenticated users
GRANT EXECUTE ON FUNCTION upload_sticker TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_stickers TO authenticated;
GRANT EXECUTE ON FUNCTION use_sticker TO authenticated;
GRANT EXECUTE ON FUNCTION create_custom_emoticon TO authenticated;
GRANT EXECUTE ON FUNCTION use_emoticon TO authenticated;
GRANT EXECUTE ON FUNCTION get_recent_emoticons TO authenticated;
GRANT EXECUTE ON FUNCTION set_chat_background TO authenticated;
GRANT EXECUTE ON FUNCTION create_custom_background TO authenticated;
GRANT EXECUTE ON FUNCTION create_message_bubble TO authenticated;
GRANT EXECUTE ON FUNCTION add_widget_message_reaction TO authenticated;
GRANT EXECUTE ON FUNCTION update_widget_preferences TO authenticated;
GRANT EXECUTE ON FUNCTION get_widget_analytics TO authenticated;
GRANT EXECUTE ON FUNCTION get_trending_stickers TO authenticated;

-- Grant system functions to service role
GRANT EXECUTE ON FUNCTION generate_daily_widget_stats TO service_role;
GRANT EXECUTE ON FUNCTION clean_expired_cache TO service_role;

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON FUNCTION upload_sticker IS 'Upload and process a new sticker with metadata and analytics tracking';
COMMENT ON FUNCTION get_user_stickers IS 'Get user stickers with filtering, search, and pagination';
COMMENT ON FUNCTION use_sticker IS 'Record sticker usage and update recent list';
COMMENT ON FUNCTION create_custom_emoticon IS 'Create user-defined custom emoticon';
COMMENT ON FUNCTION use_emoticon IS 'Record emoticon usage for analytics and recommendations';
COMMENT ON FUNCTION get_recent_emoticons IS 'Get users recently used emoticons';
COMMENT ON FUNCTION set_chat_background IS 'Set background for specific chat with custom settings';
COMMENT ON FUNCTION create_custom_background IS 'Create custom background (gradient, image, pattern)';
COMMENT ON FUNCTION create_message_bubble IS 'Create enhanced message bubble with effects and metadata';
COMMENT ON FUNCTION add_widget_message_reaction IS 'Add emoji or sticker reaction to message with widget analytics';
COMMENT ON FUNCTION update_widget_preferences IS 'Update user preferences for all widget systems';
COMMENT ON FUNCTION get_widget_analytics IS 'Retrieve widget usage analytics with filtering';
COMMENT ON FUNCTION generate_daily_widget_stats IS 'Generate daily statistics for all widget types';
COMMENT ON FUNCTION get_trending_stickers IS 'Get trending stickers based on recent usage patterns';
COMMENT ON FUNCTION clean_expired_cache IS 'Clean expired cache entries and manage cache size';

-- Setup completion message
SELECT 'Widgets Business Logic Setup Complete!' as status, NOW() as setup_completed_at;
