-- Crystal Social UserInfo System - Triggers and Automation
-- File: 05_userinfo_triggers_automation.sql
-- Purpose: Database triggers, automation, and real-time updates for user information system

-- =============================================================================
-- PROFILE COMPLETION TRACKING TRIGGERS
-- =============================================================================

-- Function to update profile completion when user_info changes
DROP FUNCTION IF EXISTS update_profile_completion;
DROP FUNCTION IF EXISTS update_profile_completion();
DROP FUNCTION IF EXISTS update_profile_completion(UUID);
CREATE OR REPLACE FUNCTION update_profile_completion()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    total_categories INTEGER := 0;
    total_items INTEGER := 0;
    has_free_text BOOLEAN := false;
    has_avatar BOOLEAN := false;
    has_bio BOOLEAN := false;
    completion_percent DECIMAL := 0;
    quality_score DECIMAL := 0;
    target_user_id UUID;
BEGIN
    -- Determine the user_id to update
    IF TG_OP = 'DELETE' THEN
        target_user_id := OLD.user_id;
    ELSE
        target_user_id := NEW.user_id;
    END IF;
    
    -- Calculate category usage
    SELECT 
        COUNT(DISTINCT category),
        COUNT(*),
        COUNT(CASE WHEN info_type = 'free_text' THEN 1 END) > 0
    INTO total_categories, total_items, has_free_text
    FROM user_info
    WHERE user_id = target_user_id;
    
    -- Check avatar and bio from auth.users
    SELECT 
        raw_user_meta_data->>'avatar_url' IS NOT NULL,
        raw_user_meta_data->>'bio' IS NOT NULL AND LENGTH(raw_user_meta_data->>'bio') > 0
    INTO has_avatar, has_bio
    FROM auth.users
    WHERE id = target_user_id;
    
    -- Calculate completion percentage (out of 100)
    completion_percent := ROUND(
        (total_categories * 4.0) +  -- Each category worth 4 points (17 categories = 68 points max)
        (CASE WHEN has_free_text THEN 15 ELSE 0 END) +  -- Free text worth 15 points
        (CASE WHEN has_avatar THEN 10 ELSE 0 END) +     -- Avatar worth 10 points
        (CASE WHEN has_bio THEN 7 ELSE 0 END),          -- Bio worth 7 points
        2
    );
    
    -- Cap at 100%
    completion_percent := LEAST(completion_percent, 100.0);
    
    -- Calculate quality score (1-10 scale)
    quality_score := ROUND(
        LEAST(10.0,
            (total_categories * 0.3) +  -- Category diversity
            (total_items * 0.1) +       -- Content volume
            (CASE WHEN has_free_text THEN 2.0 ELSE 0 END) +  -- Personal expression
            (CASE WHEN has_avatar THEN 1.5 ELSE 0 END) +     -- Visual identity
            (CASE WHEN has_bio THEN 1.0 ELSE 0 END) +        -- Description
            (CASE WHEN completion_percent > 80 THEN 2.0 
                  WHEN completion_percent > 50 THEN 1.0 ELSE 0 END)  -- Completion bonus
        ), 2
    );
    
    -- Update or insert profile completion record
    INSERT INTO user_profile_completion (
        user_id,
        completion_percentage,
        total_categories_used,
        total_items_count,
        has_free_text,
        has_avatar,
        has_bio,
        completion_score,
        profile_quality_score,
        last_updated_at
    ) VALUES (
        target_user_id,
        completion_percent,
        total_categories,
        total_items,
        has_free_text,
        has_avatar,
        has_bio,
        completion_percent,
        quality_score,
        NOW()
    )
    ON CONFLICT (user_id) 
    DO UPDATE SET
        completion_percentage = EXCLUDED.completion_percentage,
        total_categories_used = EXCLUDED.total_categories_used,
        total_items_count = EXCLUDED.total_items_count,
        has_free_text = EXCLUDED.has_free_text,
        has_avatar = EXCLUDED.has_avatar,
        has_bio = EXCLUDED.has_bio,
        completion_score = EXCLUDED.completion_score,
        profile_quality_score = EXCLUDED.profile_quality_score,
        last_updated_at = EXCLUDED.last_updated_at;
    
    -- Log the completion update
    PERFORM log_security_event(
        target_user_id,
        'profile_completion_updated',
        'user_profile_completion',
        target_user_id::text,
        true,
        'Completion: ' || completion_percent || '%, Quality: ' || quality_score
    );
    
    -- Return appropriate record based on operation
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$;

-- Create triggers for profile completion updates
CREATE TRIGGER trigger_update_profile_completion_insert
    AFTER INSERT ON user_info
    FOR EACH ROW
    EXECUTE FUNCTION update_profile_completion();

CREATE TRIGGER trigger_update_profile_completion_update
    AFTER UPDATE ON user_info
    FOR EACH ROW
    EXECUTE FUNCTION update_profile_completion();

CREATE TRIGGER trigger_update_profile_completion_delete
    AFTER DELETE ON user_info
    FOR EACH ROW
    EXECUTE FUNCTION update_profile_completion();

-- =============================================================================
-- CONTENT MODERATION AUTOMATION TRIGGERS
-- =============================================================================

-- Function to automatically moderate new content
CREATE OR REPLACE FUNCTION auto_moderate_content()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    needs_review BOOLEAN := false;
    auto_score DECIMAL := 5.0;
    sensitive_detected BOOLEAN := false;
    moderation_reason TEXT := '';
BEGIN
    -- Check if content needs moderation
    needs_review := check_content_moderation_required(NEW.content);
    
    -- Calculate automated moderation score (1-10, higher is better)
    auto_score := 5.0;  -- Start with neutral score
    
    -- Content length factors
    IF LENGTH(NEW.content) < 10 THEN
        auto_score := auto_score - 1.0;
        moderation_reason := moderation_reason || 'Very short content; ';
    ELSIF LENGTH(NEW.content) > 500 THEN
        auto_score := auto_score - 0.5;
        moderation_reason := moderation_reason || 'Long content; ';
    END IF;
    
    -- URL detection
    IF NEW.content ~* 'https?://|www\.|\.com|\.org|\.net' THEN
        auto_score := auto_score - 2.0;
        sensitive_detected := true;
        moderation_reason := moderation_reason || 'Contains URLs; ';
    END IF;
    
    -- Contact information detection
    IF NEW.content ~* '\d{3}[-.]?\d{3}[-.]?\d{4}|@\w+\.\w+' THEN
        auto_score := auto_score - 2.0;
        sensitive_detected := true;
        moderation_reason := moderation_reason || 'Contains contact info; ';
    END IF;
    
    -- Excessive capitalization
    IF LENGTH(NEW.content) > 20 AND 
       LENGTH(regexp_replace(NEW.content, '[^A-Z]', '', 'g')) > LENGTH(NEW.content) * 0.5 THEN
        auto_score := auto_score - 1.0;
        moderation_reason := moderation_reason || 'Excessive caps; ';
    END IF;
    
    -- Repetitive content detection
    IF NEW.content ~* '(.)\1{4,}' THEN  -- Same character repeated 5+ times
        auto_score := auto_score - 1.0;
        moderation_reason := moderation_reason || 'Repetitive content; ';
    END IF;
    
    -- Basic profanity/inappropriate content (simple keyword check)
    IF NEW.content ~* 'spam|scam|hack|cheat|fraud|fake|illegal' THEN
        auto_score := auto_score - 3.0;
        sensitive_detected := true;
        moderation_reason := moderation_reason || 'Flagged keywords; ';
    END IF;
    
    -- Ensure score stays in valid range
    auto_score := GREATEST(1.0, LEAST(10.0, auto_score));
    
    -- Determine moderation status
    DECLARE
        mod_status TEXT := 'approved';
    BEGIN
        IF auto_score < 3.0 OR needs_review THEN
            mod_status := 'pending';
        ELSIF auto_score < 5.0 THEN
            mod_status := 'flagged';
        END IF;
        
        -- Insert moderation record
        INSERT INTO user_info_moderation (
            user_info_id,
            moderation_status,
            moderation_reason,
            automated_score,
            contains_sensitive_content,
            flag_count,
            created_at
        ) VALUES (
            NEW.id,
            mod_status,
            TRIM(moderation_reason),
            auto_score,
            sensitive_detected,
            0,
            NOW()
        );
    END;
    
    -- Log moderation event
    PERFORM log_security_event(
        NEW.user_id,
        'content_auto_moderated',
        'user_info',
        NEW.id::text,
        true,
        'Status: ' || mod_status || ', Score: ' || auto_score
    );
    
    RETURN NEW;
END;
$$;

-- Create trigger for automatic content moderation
CREATE TRIGGER trigger_auto_moderate_content
    AFTER INSERT ON user_info
    FOR EACH ROW
    EXECUTE FUNCTION auto_moderate_content();

-- =============================================================================
-- USER INTERACTION TRACKING TRIGGERS
-- =============================================================================

-- Function to update analytics when interactions occur
CREATE OR REPLACE FUNCTION update_interaction_analytics()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    today_date DATE := CURRENT_DATE;
BEGIN
    -- Update or create analytics record for the viewed user
    INSERT INTO user_info_analytics (
        user_id,
        analysis_date,
        total_profile_views,
        unique_viewers,
        category_views,
        search_appearances,
        avg_view_duration,
        engagement_score,
        discovery_rank
    ) VALUES (
        NEW.viewed_user_id,
        today_date,
        CASE WHEN NEW.interaction_type = 'profile_view' THEN 1 ELSE 0 END,
        1,  -- Will be recalculated below
        CASE WHEN NEW.interaction_type = 'category_view' THEN 1 ELSE 0 END,
        CASE WHEN NEW.interaction_type = 'search' THEN 1 ELSE 0 END,
        COALESCE(NEW.view_duration_seconds, 0),
        1.0,  -- Base engagement score
        0     -- Will be calculated later
    )
    ON CONFLICT (user_id, analysis_date)
    DO UPDATE SET
        total_profile_views = user_info_analytics.total_profile_views + 
            CASE WHEN NEW.interaction_type = 'profile_view' THEN 1 ELSE 0 END,
        category_views = user_info_analytics.category_views + 
            CASE WHEN NEW.interaction_type = 'category_view' THEN 1 ELSE 0 END,
        search_appearances = user_info_analytics.search_appearances + 
            CASE WHEN NEW.interaction_type = 'search' THEN 1 ELSE 0 END,
        avg_view_duration = (
            (user_info_analytics.avg_view_duration * user_info_analytics.total_profile_views) + 
            COALESCE(NEW.view_duration_seconds, 0)
        ) / (user_info_analytics.total_profile_views + 1),
        updated_at = NOW();
    
    -- Update unique viewers count (requires separate calculation)
    UPDATE user_info_analytics 
    SET unique_viewers = (
        SELECT COUNT(DISTINCT viewer_user_id)
        FROM user_info_interactions
        WHERE viewed_user_id = NEW.viewed_user_id
        AND DATE(created_at) = today_date
    )
    WHERE user_id = NEW.viewed_user_id 
    AND analysis_date = today_date;
    
    -- Calculate engagement score
    UPDATE user_info_analytics 
    SET engagement_score = ROUND(
        (total_profile_views * 1.0) +
        (unique_viewers * 2.0) +
        (category_views * 0.5) +
        (search_appearances * 1.5) +
        (avg_view_duration / 60.0)  -- Minutes viewed
    , 2)
    WHERE user_id = NEW.viewed_user_id 
    AND analysis_date = today_date;
    
    RETURN NEW;
END;
$$;

-- Create trigger for interaction analytics
CREATE TRIGGER trigger_update_interaction_analytics
    AFTER INSERT ON user_info_interactions
    FOR EACH ROW
    EXECUTE FUNCTION update_interaction_analytics();

-- =============================================================================
-- CATEGORY PREFERENCES AUTOMATION
-- =============================================================================

-- Function to auto-create category preferences when user first uses a category
CREATE OR REPLACE FUNCTION auto_create_category_preferences()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Only process category-type user info
    IF NEW.info_type = 'category' THEN
        -- Create category preference if it doesn't exist
        INSERT INTO user_category_preferences (
            user_id,
            category_name,
            is_favorite,
            is_hidden,
            custom_order,
            access_count,
            last_accessed_at,
            created_at
        ) VALUES (
            NEW.user_id,
            NEW.category,
            false,  -- Default not favorite
            false,  -- Default not hidden
            NULL,   -- Use default order
            1,      -- First access
            NOW(),
            NOW()
        )
        ON CONFLICT (user_id, category_name) 
        DO UPDATE SET
            access_count = user_category_preferences.access_count + 1,
            last_accessed_at = NOW();
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger for category preferences
CREATE TRIGGER trigger_auto_create_category_preferences
    AFTER INSERT ON user_info
    FOR EACH ROW
    EXECUTE FUNCTION auto_create_category_preferences();

-- Update access count when category content is updated
CREATE OR REPLACE FUNCTION update_category_access()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Only update if content actually changed and it's a category
    IF NEW.info_type = 'category' AND OLD.content != NEW.content THEN
        UPDATE user_category_preferences
        SET 
            access_count = access_count + 1,
            last_accessed_at = NOW()
        WHERE user_id = NEW.user_id 
        AND category_name = NEW.category;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger for category access updates
CREATE TRIGGER trigger_update_category_access
    AFTER UPDATE ON user_info
    FOR EACH ROW
    EXECUTE FUNCTION update_category_access();

-- =============================================================================
-- DISCOVERY SETTINGS AUTOMATION
-- =============================================================================

-- Function to create default discovery settings for new users
CREATE OR REPLACE FUNCTION create_default_discovery_settings()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Create default discovery settings for new user
    INSERT INTO user_discovery_settings (
        user_id,
        is_discoverable,
        privacy_level,
        allow_profile_views,
        show_completion_percentage,
        auto_accept_connections,
        created_at
    ) VALUES (
        NEW.id,
        true,      -- Default discoverable
        'public',  -- Default public
        true,      -- Default allow views
        true,      -- Default show completion
        false,     -- Default manual connections
        NOW()
    )
    ON CONFLICT (user_id) DO NOTHING;  -- Don't overwrite existing settings
    
    RETURN NEW;
END;
$$;

-- Create trigger for default discovery settings (on auth.users)
-- Note: This requires superuser privileges in production
-- CREATE TRIGGER trigger_create_default_discovery_settings
--     AFTER INSERT ON auth.users
--     FOR EACH ROW
--     EXECUTE FUNCTION create_default_discovery_settings();

-- =============================================================================
-- NOTIFICATION AND REAL-TIME TRIGGERS
-- =============================================================================

-- Function to send real-time notifications for profile interactions
CREATE OR REPLACE FUNCTION notify_profile_interaction()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    notification_payload JSON;
    viewer_info JSON;
BEGIN
    -- Only notify for profile views (not searches or category views)
    IF NEW.interaction_type = 'profile_view' THEN
        -- Get viewer information
        SELECT json_build_object(
            'user_id', id,
            'email', email,
            'avatar_url', raw_user_meta_data->>'avatar_url',
            'display_name', raw_user_meta_data->>'display_name'
        ) INTO viewer_info
        FROM auth.users
        WHERE id = NEW.viewer_user_id;
        
        -- Build notification payload
        notification_payload := json_build_object(
            'type', 'profile_view',
            'interaction_id', NEW.id,
            'viewed_user_id', NEW.viewed_user_id,
            'viewer_info', viewer_info,
            'category_name', NEW.category_name,
            'view_duration', NEW.view_duration_seconds,
            'timestamp', NEW.created_at
        );
        
        -- Send real-time notification
        PERFORM pg_notify(
            'user_profile_interactions',
            notification_payload::text
        );
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger for real-time notifications
CREATE TRIGGER trigger_notify_profile_interaction
    AFTER INSERT ON user_info_interactions
    FOR EACH ROW
    EXECUTE FUNCTION notify_profile_interaction();

-- Function to notify when moderation status changes
CREATE OR REPLACE FUNCTION notify_moderation_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    notification_payload JSON;
    user_info_data JSON;
BEGIN
    -- Only notify on status changes
    IF TG_OP = 'UPDATE' AND OLD.moderation_status != NEW.moderation_status THEN
        -- Get user info data
        SELECT json_build_object(
            'user_id', user_id,
            'category', category,
            'content_preview', LEFT(content, 100)
        ) INTO user_info_data
        FROM user_info
        WHERE id = NEW.user_info_id;
        
        -- Build notification payload
        notification_payload := json_build_object(
            'type', 'moderation_update',
            'user_info_id', NEW.user_info_id,
            'old_status', OLD.moderation_status,
            'new_status', NEW.moderation_status,
            'moderation_reason', NEW.moderation_reason,
            'user_info', user_info_data,
            'timestamp', NOW()
        );
        
        -- Send notification to moderation channel
        PERFORM pg_notify(
            'content_moderation_updates',
            notification_payload::text
        );
        
        -- Send notification to user channel if approved/rejected
        IF NEW.moderation_status IN ('approved', 'rejected', 'removed') THEN
            PERFORM pg_notify(
                'user_content_updates',
                notification_payload::text
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger for moderation notifications
CREATE TRIGGER trigger_notify_moderation_update
    AFTER UPDATE ON user_info_moderation
    FOR EACH ROW
    EXECUTE FUNCTION notify_moderation_update();

-- =============================================================================
-- CLEANUP AND MAINTENANCE TRIGGERS
-- =============================================================================

-- Function to clean up old analytics data
CREATE OR REPLACE FUNCTION cleanup_old_analytics()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    deleted_count INTEGER := 0;
    temp_count INTEGER;
    cutoff_date DATE := CURRENT_DATE - INTERVAL '365 days';
BEGIN
    -- Delete analytics older than 1 year
    DELETE FROM user_info_analytics
    WHERE analysis_date < cutoff_date;
    
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_count := deleted_count + temp_count;
    
    -- Delete old interaction records (keep 6 months)
    DELETE FROM user_info_interactions
    WHERE created_at < CURRENT_DATE - INTERVAL '180 days';
    
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_count := deleted_count + temp_count;
    
    -- Delete old security logs (keep 1 year)
    DELETE FROM user_info_security_log
    WHERE created_at < CURRENT_DATE - INTERVAL '365 days';
    
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_count := deleted_count + temp_count;
    
    RETURN 'Cleaned up ' || deleted_count || ' old records';
END;
$$;

-- Function to update discovery rankings
CREATE OR REPLACE FUNCTION update_discovery_rankings()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Update discovery rankings based on recent engagement
    WITH ranked_users AS (
        SELECT 
            user_id,
            ROW_NUMBER() OVER (
                ORDER BY 
                    engagement_score DESC,
                    total_profile_views DESC,
                    unique_viewers DESC
            ) as new_rank
        FROM user_info_analytics
        WHERE analysis_date >= CURRENT_DATE - INTERVAL '30 days'
    )
    UPDATE user_info_analytics
    SET discovery_rank = ranked_users.new_rank
    FROM ranked_users
    WHERE user_info_analytics.user_id = ranked_users.user_id
    AND user_info_analytics.analysis_date >= CURRENT_DATE - INTERVAL '30 days';
    
    RETURN 'Discovery rankings updated for ' || 
           (SELECT COUNT(*) FROM user_info_analytics 
            WHERE analysis_date >= CURRENT_DATE - INTERVAL '30 days') || 
           ' users';
END;
$$;

-- =============================================================================
-- SCHEDULED MAINTENANCE FUNCTIONS
-- =============================================================================

-- Grant permissions for maintenance functions
GRANT EXECUTE ON FUNCTION cleanup_old_analytics TO service_role;
GRANT EXECUTE ON FUNCTION update_discovery_rankings TO service_role;

-- Create maintenance scheduler function (to be called by external cron job)
CREATE OR REPLACE FUNCTION run_daily_maintenance()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    cleanup_result TEXT;
    ranking_result TEXT;
    refresh_result TEXT;
BEGIN
    -- Run cleanup
    SELECT cleanup_old_analytics() INTO cleanup_result;
    
    -- Update rankings
    SELECT update_discovery_rankings() INTO ranking_result;
    
    -- Refresh materialized views
    SELECT refresh_daily_user_activity() INTO refresh_result;
    
    -- Log maintenance completion
    PERFORM log_security_event(
        NULL,
        'daily_maintenance_completed',
        'system',
        NULL,
        true,
        'Cleanup: ' || cleanup_result || '; Rankings: ' || ranking_result
    );
    
    RETURN 'Daily maintenance completed: ' || cleanup_result || '; ' || ranking_result;
END;
$$;

-- Weekly maintenance function
CREATE OR REPLACE FUNCTION run_weekly_maintenance()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    trends_result TEXT;
BEGIN
    -- Refresh weekly trends
    SELECT refresh_weekly_category_trends() INTO trends_result;
    
    -- Analyze and update category popularity
    UPDATE user_info_categories
    SET category_order = new_order.order_num
    FROM (
        SELECT 
            category_name,
            ROW_NUMBER() OVER (ORDER BY unique_users DESC, total_items DESC) as order_num
        FROM category_analytics
    ) new_order
    WHERE user_info_categories.category_name = new_order.category_name;
    
    RETURN 'Weekly maintenance completed: ' || trends_result;
END;
$$;

-- Grant permissions for scheduled functions
GRANT EXECUTE ON FUNCTION run_daily_maintenance TO service_role;
GRANT EXECUTE ON FUNCTION run_weekly_maintenance TO service_role;

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON FUNCTION update_profile_completion IS 'Automatically updates profile completion statistics when user_info changes';
COMMENT ON FUNCTION auto_moderate_content IS 'Automatically analyzes and moderates new user content';
COMMENT ON FUNCTION update_interaction_analytics IS 'Updates analytics when user interactions occur';
COMMENT ON FUNCTION auto_create_category_preferences IS 'Creates category preferences when user first uses a category';
COMMENT ON FUNCTION notify_profile_interaction IS 'Sends real-time notifications for profile interactions';
COMMENT ON FUNCTION notify_moderation_update IS 'Sends notifications when content moderation status changes';
COMMENT ON FUNCTION cleanup_old_analytics IS 'Removes old analytics and interaction data';
COMMENT ON FUNCTION update_discovery_rankings IS 'Updates user discovery rankings based on engagement';
COMMENT ON FUNCTION run_daily_maintenance IS 'Performs daily system maintenance tasks';
COMMENT ON FUNCTION run_weekly_maintenance IS 'Performs weekly system maintenance tasks';

-- Setup completion message
SELECT 'UserInfo Triggers and Automation Setup Complete!' as status, NOW() as setup_completed_at;
