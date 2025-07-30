-- Crystal Social Widgets System - Triggers and Automation
-- File: 05_widgets_triggers_automation.sql
-- Purpose: Database triggers and automation for widget system lifecycle management

-- =============================================================================
-- UTILITY FUNCTIONS FOR TRIGGERS
-- =============================================================================

-- Function to generate widget cache key
CREATE OR REPLACE FUNCTION generate_widget_cache_key(
    p_widget_type TEXT,
    p_user_id UUID,
    p_additional_params JSONB DEFAULT '{}'
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN CONCAT(
        'widget:',
        p_widget_type,
        ':user:',
        p_user_id,
        ':',
        md5(p_additional_params::text)
    );
END;
$$;

-- Function to invalidate widget caches
CREATE OR REPLACE FUNCTION invalidate_widget_cache(
    p_widget_type TEXT,
    p_user_id UUID DEFAULT NULL,
    p_pattern TEXT DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    IF p_pattern IS NOT NULL THEN
        -- Delete by pattern
        DELETE FROM widget_cache_entries
        WHERE cache_key LIKE p_pattern;
    ELSIF p_user_id IS NOT NULL THEN
        -- Delete user-specific cache
        DELETE FROM widget_cache_entries
        WHERE cache_key LIKE CONCAT('widget:', p_widget_type, ':user:', p_user_id, '%');
    ELSE
        -- Delete all cache for widget type
        DELETE FROM widget_cache_entries
        WHERE cache_key LIKE CONCAT('widget:', p_widget_type, '%');
    END IF;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$;

-- =============================================================================
-- STICKER SYSTEM TRIGGERS
-- =============================================================================

-- Update sticker timestamps and invalidate cache
CREATE OR REPLACE FUNCTION sticker_trigger_function()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Handle different trigger operations
    IF TG_OP = 'INSERT' THEN
        -- Set created_at and updated_at for new stickers
        NEW.created_at := COALESCE(NEW.created_at, NOW());
        NEW.updated_at := NOW();
        
        -- Auto-approve stickers from trusted users (example logic)
        IF EXISTS (
            SELECT 1 FROM auth.users 
            WHERE id = NEW.user_id 
            AND raw_user_meta_data->>'trusted_creator' = 'true'
        ) THEN
            NEW.is_approved := true;
            NEW.approved_at := NOW();
        END IF;
        
        -- Track sticker creation analytics
        INSERT INTO widget_usage_analytics (
            user_id, widget_type, action_type, metadata, usage_timestamp
        ) VALUES (
            NEW.user_id, 'sticker_picker', 'sticker_created',
            jsonb_build_object(
                'sticker_id', NEW.id,
                'category', NEW.category,
                'is_gif', NEW.is_gif,
                'is_public', NEW.is_public
            ),
            NOW()
        );
        
        RETURN NEW;
        
    ELSIF TG_OP = 'UPDATE' THEN
        -- Update timestamp
        NEW.updated_at := NOW();
        
        -- Handle approval status changes
        IF OLD.is_approved IS DISTINCT FROM NEW.is_approved THEN
            IF NEW.is_approved THEN
                NEW.approved_at := NOW();
                
                -- Track approval analytics
                INSERT INTO widget_usage_analytics (
                    user_id, widget_type, action_type, metadata, usage_timestamp
                ) VALUES (
                    NEW.user_id, 'sticker_picker', 'sticker_approved',
                    jsonb_build_object(
                        'sticker_id', NEW.id,
                        'category', NEW.category,
                        'approved_by', auth.uid()::UUID
                    ),
                    NOW()
                );
            ELSE
                NEW.approved_at := NULL;
            END IF;
        END IF;
        
        -- Invalidate relevant caches
        PERFORM invalidate_widget_cache('sticker_picker', NEW.user_id);
        IF NEW.is_public THEN
            PERFORM invalidate_widget_cache('sticker_picker', NULL, 'widget:sticker_picker:public%');
        END IF;
        
        RETURN NEW;
        
    ELSIF TG_OP = 'DELETE' THEN
        -- Track deletion analytics
        INSERT INTO widget_usage_analytics (
            user_id, widget_type, action_type, metadata, usage_timestamp
        ) VALUES (
            OLD.user_id, 'sticker_picker', 'sticker_deleted',
            jsonb_build_object(
                'sticker_id', OLD.id,
                'category', OLD.category,
                'was_public', OLD.is_public
            ),
            NOW()
        );
        
        -- Invalidate caches
        PERFORM invalidate_widget_cache('sticker_picker', OLD.user_id);
        IF OLD.is_public THEN
            PERFORM invalidate_widget_cache('sticker_picker', NULL, 'widget:sticker_picker:public%');
        END IF;
        
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$;

-- Create triggers for stickers table
CREATE TRIGGER sticker_lifecycle_trigger
    BEFORE INSERT OR UPDATE OR DELETE ON stickers
    FOR EACH ROW
    EXECUTE FUNCTION sticker_trigger_function();

-- =============================================================================
-- EMOTICON SYSTEM TRIGGERS
-- =============================================================================

-- Emoticon management trigger function
CREATE OR REPLACE FUNCTION emoticon_trigger_function()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.created_at := COALESCE(NEW.created_at, NOW());
        NEW.updated_at := NOW();
        
        -- Track emoticon creation
        INSERT INTO widget_usage_analytics (
            user_id, widget_type, action_type, metadata, usage_timestamp
        ) VALUES (
            NEW.user_id, 'emoticon_picker', 'emoticon_created',
            jsonb_build_object(
                'emoticon_id', NEW.id,
                'category_id', NEW.category_id,
                'is_public', NEW.is_public
            ),
            NOW()
        );
        
        RETURN NEW;
        
    ELSIF TG_OP = 'UPDATE' THEN
        NEW.updated_at := NOW();
        
        -- Handle approval changes
        IF OLD.is_approved IS DISTINCT FROM NEW.is_approved AND NEW.is_approved THEN
            NEW.approved_at := NOW();
        END IF;
        
        -- Invalidate emoticon caches
        PERFORM invalidate_widget_cache('emoticon_picker', NEW.user_id);
        
        RETURN NEW;
        
    ELSIF TG_OP = 'DELETE' THEN
        -- Clean up related data
        DELETE FROM emoticon_usage WHERE emoticon_id = OLD.id;
        DELETE FROM emoticon_favorites WHERE emoticon_id = OLD.id;
        
        -- Track deletion
        INSERT INTO widget_usage_analytics (
            user_id, widget_type, action_type, metadata, usage_timestamp
        ) VALUES (
            OLD.user_id, 'emoticon_picker', 'emoticon_deleted',
            jsonb_build_object('emoticon_id', OLD.id),
            NOW()
        );
        
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$;

CREATE TRIGGER emoticon_lifecycle_trigger
    BEFORE INSERT OR UPDATE OR DELETE ON custom_emoticons
    FOR EACH ROW
    EXECUTE FUNCTION emoticon_trigger_function();

-- =============================================================================
-- BACKGROUND SYSTEM TRIGGERS
-- =============================================================================

-- Background management trigger function
CREATE OR REPLACE FUNCTION background_trigger_function()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.created_at := COALESCE(NEW.created_at, NOW());
        NEW.updated_at := NOW();
        
        -- Track background creation
        INSERT INTO widget_usage_analytics (
            user_id, widget_type, action_type, metadata, usage_timestamp
        ) VALUES (
            COALESCE(NEW.created_by, auth.uid()::UUID), 'background_picker', 'background_created',
            jsonb_build_object(
                'background_id', NEW.id,
                'background_type', NEW.background_type,
                'is_preset', NEW.is_preset,
                'is_public', NEW.is_public
            ),
            NOW()
        );
        
        RETURN NEW;
        
    ELSIF TG_OP = 'UPDATE' THEN
        NEW.updated_at := NOW();
        
        -- Invalidate background caches
        PERFORM invalidate_widget_cache('background_picker');
        
        RETURN NEW;
        
    ELSIF TG_OP = 'DELETE' THEN
        -- Clean up user selections
        DELETE FROM user_chat_backgrounds WHERE background_id = OLD.id;
        
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$;

CREATE TRIGGER background_lifecycle_trigger
    BEFORE INSERT OR UPDATE OR DELETE ON chat_backgrounds
    FOR EACH ROW
    EXECUTE FUNCTION background_trigger_function();

-- =============================================================================
-- MESSAGE SYSTEM TRIGGERS
-- =============================================================================

-- Message bubble trigger function
CREATE OR REPLACE FUNCTION message_bubble_trigger_function()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    analysis_result JSONB;
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.created_at := COALESCE(NEW.created_at, NOW());
        NEW.updated_at := NOW();
        
        -- Trigger message analysis asynchronously (if content exists)
        IF NEW.content IS NOT NULL AND LENGTH(NEW.content) > 0 THEN
            -- Insert into analysis queue
            INSERT INTO message_analysis_results (
                message_id, user_id, analysis_status, created_at
            ) VALUES (
                NEW.id, NEW.user_id, 'pending', NOW()
            );
        END IF;
        
        -- Track message creation
        INSERT INTO widget_usage_analytics (
            user_id, widget_type, action_type, metadata, usage_timestamp
        ) VALUES (
            NEW.user_id, 'message_bubble', 'message_sent',
            jsonb_build_object(
                'message_id', NEW.id,
                'chat_id', NEW.chat_id,
                'has_effects', NEW.effects IS NOT NULL,
                'content_length', LENGTH(COALESCE(NEW.content, ''))
            ),
            NOW()
        );
        
        RETURN NEW;
        
    ELSIF TG_OP = 'UPDATE' THEN
        NEW.updated_at := NOW();
        
        -- Track message edits
        IF OLD.content IS DISTINCT FROM NEW.content THEN
            INSERT INTO widget_usage_analytics (
                user_id, widget_type, action_type, metadata, usage_timestamp
            ) VALUES (
                NEW.user_id, 'message_bubble', 'message_edited',
                jsonb_build_object(
                    'message_id', NEW.id,
                    'edit_count', COALESCE(NEW.edit_count, 0)
                ),
                NOW()
            );
        END IF;
        
        RETURN NEW;
        
    ELSIF TG_OP = 'DELETE' THEN
        -- Clean up related data
        DELETE FROM message_reactions WHERE message_id = OLD.id;
        DELETE FROM message_analysis_results WHERE message_id = OLD.id;
        
        -- Track message deletion
        INSERT INTO widget_usage_analytics (
            user_id, widget_type, action_type, metadata, usage_timestamp
        ) VALUES (
            OLD.user_id, 'message_bubble', 'message_deleted',
            jsonb_build_object('message_id', OLD.id),
            NOW()
        );
        
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$;

CREATE TRIGGER message_bubble_lifecycle_trigger
    BEFORE INSERT OR UPDATE OR DELETE ON message_bubbles
    FOR EACH ROW
    EXECUTE FUNCTION message_bubble_trigger_function();

-- =============================================================================
-- REACTION SYSTEM TRIGGERS
-- =============================================================================

-- Message reaction trigger function
CREATE OR REPLACE FUNCTION message_reaction_trigger_function()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.created_at := COALESCE(NEW.created_at, NOW());
        
        -- Track reaction usage
        INSERT INTO widget_usage_analytics (
            user_id, widget_type, action_type, metadata, usage_timestamp
        ) VALUES (
            NEW.user_id, 'message_bubble', 'reaction_added',
            jsonb_build_object(
                'message_id', NEW.message_id,
                'reaction_type', NEW.reaction_type,
                'is_custom', NEW.custom_emoticon_id IS NOT NULL
            ),
            NOW()
        );
        
        -- Update emoticon usage if custom emoticon
        IF NEW.custom_emoticon_id IS NOT NULL THEN
            INSERT INTO emoticon_usage (user_id, emoticon_id, usage_timestamp)
            VALUES (NEW.user_id, NEW.custom_emoticon_id, NOW())
            ON CONFLICT (user_id, emoticon_id, DATE(usage_timestamp))
            DO UPDATE SET usage_count = emoticon_usage.usage_count + 1;
        END IF;
        
        RETURN NEW;
        
    ELSIF TG_OP = 'DELETE' THEN
        -- Track reaction removal
        INSERT INTO widget_usage_analytics (
            user_id, widget_type, action_type, metadata, usage_timestamp
        ) VALUES (
            OLD.user_id, 'message_bubble', 'reaction_removed',
            jsonb_build_object(
                'message_id', OLD.message_id,
                'reaction_type', OLD.reaction_type
            ),
            NOW()
        );
        
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$;

CREATE TRIGGER message_reaction_lifecycle_trigger
    BEFORE INSERT OR DELETE ON message_reactions
    FOR EACH ROW
    EXECUTE FUNCTION message_reaction_trigger_function();

-- =============================================================================
-- USAGE ANALYTICS AUTOMATION
-- =============================================================================

-- Function to aggregate daily widget statistics
CREATE OR REPLACE FUNCTION aggregate_daily_widget_stats()
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    target_date DATE := CURRENT_DATE - INTERVAL '1 day';
BEGIN
    -- Insert daily stats summary
    INSERT INTO daily_widget_stats (
        date, widget_type, total_users, total_actions, top_actions, avg_session_duration
    )
    SELECT 
        target_date as date,
        widget_type,
        COUNT(DISTINCT user_id) as total_users,
        COUNT(*) as total_actions,
        (
            SELECT jsonb_object_agg(action_type, action_count)
            FROM (
                SELECT action_type, COUNT(*) as action_count
                FROM widget_usage_analytics w2
                WHERE w2.widget_type = w1.widget_type
                AND DATE(w2.usage_timestamp) = target_date
                GROUP BY action_type
                ORDER BY action_count DESC
                LIMIT 10
            ) top_actions_subquery
        ) as top_actions,
        EXTRACT(EPOCH FROM AVG(
            CASE 
                WHEN LAG(usage_timestamp) OVER (
                    PARTITION BY user_id, widget_type 
                    ORDER BY usage_timestamp
                ) IS NOT NULL 
                THEN usage_timestamp - LAG(usage_timestamp) OVER (
                    PARTITION BY user_id, widget_type 
                    ORDER BY usage_timestamp
                )
                ELSE NULL
            END
        )) as avg_session_duration
    FROM widget_usage_analytics w1
    WHERE DATE(usage_timestamp) = target_date
    GROUP BY widget_type
    ON CONFLICT (date, widget_type) 
    DO UPDATE SET
        total_users = EXCLUDED.total_users,
        total_actions = EXCLUDED.total_actions,
        top_actions = EXCLUDED.top_actions,
        avg_session_duration = EXCLUDED.avg_session_duration,
        updated_at = NOW();
    
END;
$$;

-- =============================================================================
-- CACHE MANAGEMENT AUTOMATION
-- =============================================================================

-- Function to clean up expired cache entries
CREATE OR REPLACE FUNCTION cleanup_expired_cache()
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM widget_cache_entries
    WHERE expires_at < NOW();
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- Log cleanup
    INSERT INTO widget_usage_analytics (
        user_id, widget_type, action_type, metadata, usage_timestamp
    ) VALUES (
        NULL, 'system', 'cache_cleanup',
        jsonb_build_object('deleted_entries', deleted_count),
        NOW()
    );
    
    RETURN deleted_count;
END;
$$;

-- Function to optimize widget cache based on usage patterns
CREATE OR REPLACE FUNCTION optimize_widget_cache()
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    popular_widgets JSONB;
BEGIN
    -- Get popular widgets from last 24 hours
    SELECT jsonb_object_agg(widget_type, usage_count) INTO popular_widgets
    FROM (
        SELECT 
            widget_type, 
            COUNT(*) as usage_count
        FROM widget_usage_analytics
        WHERE usage_timestamp >= NOW() - INTERVAL '24 hours'
        GROUP BY widget_type
        ORDER BY usage_count DESC
        LIMIT 10
    ) popular;
    
    -- Pre-cache popular widget data (implementation would depend on specific needs)
    -- This is a placeholder for cache warming logic
    
    -- Log optimization
    INSERT INTO widget_usage_analytics (
        user_id, widget_type, action_type, metadata, usage_timestamp
    ) VALUES (
        NULL, 'system', 'cache_optimization',
        jsonb_build_object('popular_widgets', popular_widgets),
        NOW()
    );
END;
$$;

-- =============================================================================
-- PERFORMANCE MONITORING AUTOMATION
-- =============================================================================

-- Function to track widget performance metrics
CREATE OR REPLACE FUNCTION track_widget_performance()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    execution_time INTERVAL;
    memory_usage BIGINT;
BEGIN
    -- Calculate execution time (if metadata contains timing info)
    IF NEW.metadata ? 'execution_time_ms' THEN
        execution_time := (NEW.metadata->>'execution_time_ms')::INTEGER * INTERVAL '1 millisecond';
    END IF;
    
    -- Track performance metrics
    INSERT INTO widget_performance_metrics (
        widget_type, action_type, execution_time, memory_usage, 
        user_count, timestamp, metadata
    ) VALUES (
        NEW.widget_type, NEW.action_type, execution_time, memory_usage,
        1, NEW.usage_timestamp, NEW.metadata
    )
    ON CONFLICT (widget_type, action_type, DATE(timestamp))
    DO UPDATE SET
        avg_execution_time = (
            widget_performance_metrics.avg_execution_time * widget_performance_metrics.sample_count + 
            COALESCE(EXCLUDED.execution_time, INTERVAL '0')
        ) / (widget_performance_metrics.sample_count + 1),
        sample_count = widget_performance_metrics.sample_count + 1,
        last_updated = NOW();
    
    RETURN NEW;
END;
$$;

CREATE TRIGGER track_performance_trigger
    AFTER INSERT ON widget_usage_analytics
    FOR EACH ROW
    EXECUTE FUNCTION track_widget_performance();

-- =============================================================================
-- GLIMMER INTEGRATION AUTOMATION
-- =============================================================================

-- Glimmer post trigger function
CREATE OR REPLACE FUNCTION glimmer_post_trigger_function()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    moderation_result JSONB;
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.created_at := COALESCE(NEW.created_at, NOW());
        NEW.updated_at := NOW();
        
        -- Auto-moderate content
        SELECT moderate_widget_content(NEW.caption, 'glimmer_caption') INTO moderation_result;
        
        IF (moderation_result->>'auto_approve')::BOOLEAN THEN
            NEW.moderation_status := 'approved';
            NEW.moderated_at := NOW();
        ELSE
            NEW.moderation_status := 'pending';
        END IF;
        
        -- Store moderation details
        NEW.moderation_details := moderation_result;
        
        -- Track glimmer post creation
        INSERT INTO widget_usage_analytics (
            user_id, widget_type, action_type, metadata, usage_timestamp
        ) VALUES (
            NEW.user_id, 'glimmer_upload', 'post_created',
            jsonb_build_object(
                'post_id', NEW.id,
                'media_type', NEW.media_type,
                'moderation_status', NEW.moderation_status,
                'auto_approved', (moderation_result->>'auto_approve')::BOOLEAN
            ),
            NOW()
        );
        
        RETURN NEW;
        
    ELSIF TG_OP = 'UPDATE' THEN
        NEW.updated_at := NOW();
        
        -- Track moderation status changes
        IF OLD.moderation_status IS DISTINCT FROM NEW.moderation_status THEN
            NEW.moderated_at := NOW();
            
            INSERT INTO widget_usage_analytics (
                user_id, widget_type, action_type, metadata, usage_timestamp
            ) VALUES (
                NEW.user_id, 'glimmer_upload', 'moderation_changed',
                jsonb_build_object(
                    'post_id', NEW.id,
                    'old_status', OLD.moderation_status,
                    'new_status', NEW.moderation_status,
                    'moderated_by', auth.uid()::UUID
                ),
                NOW()
            );
        END IF;
        
        RETURN NEW;
        
    ELSIF TG_OP = 'DELETE' THEN
        -- Track post deletion
        INSERT INTO widget_usage_analytics (
            user_id, widget_type, action_type, metadata, usage_timestamp
        ) VALUES (
            OLD.user_id, 'glimmer_upload', 'post_deleted',
            jsonb_build_object(
                'post_id', OLD.id,
                'was_public', OLD.is_public,
                'moderation_status', OLD.moderation_status
            ),
            NOW()
        );
        
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$;

CREATE TRIGGER glimmer_post_lifecycle_trigger
    BEFORE INSERT OR UPDATE OR DELETE ON glimmer_posts
    FOR EACH ROW
    EXECUTE FUNCTION glimmer_post_trigger_function();

-- =============================================================================
-- SYNC SYSTEM AUTOMATION
-- =============================================================================

-- User sync trigger function
CREATE OR REPLACE FUNCTION user_sync_trigger_function()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        NEW.last_sync := NOW();
        
        -- Invalidate user-specific caches when sync data changes
        PERFORM invalidate_widget_cache('all', NEW.user_id);
        
        RETURN NEW;
    END IF;
    
    RETURN NULL;
END;
$$;

CREATE TRIGGER user_sync_update_trigger
    BEFORE INSERT OR UPDATE ON user_local_sync
    FOR EACH ROW
    EXECUTE FUNCTION user_sync_trigger_function();

-- =============================================================================
-- SCHEDULED MAINTENANCE FUNCTIONS
-- =============================================================================

-- Function to be called by cron for daily maintenance
CREATE OR REPLACE FUNCTION daily_widget_maintenance()
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    maintenance_log JSONB := '{}';
    cache_cleaned INTEGER;
    stats_processed INTEGER;
BEGIN
    -- Clean expired cache
    SELECT cleanup_expired_cache() INTO cache_cleaned;
    maintenance_log := maintenance_log || jsonb_build_object('cache_cleaned', cache_cleaned);
    
    -- Aggregate daily statistics
    PERFORM aggregate_daily_widget_stats();
    maintenance_log := maintenance_log || jsonb_build_object('stats_aggregated', true);
    
    -- Optimize cache
    PERFORM optimize_widget_cache();
    maintenance_log := maintenance_log || jsonb_build_object('cache_optimized', true);
    
    -- Clean old analytics data (keep last 90 days)
    DELETE FROM widget_usage_analytics 
    WHERE usage_timestamp < NOW() - INTERVAL '90 days';
    GET DIAGNOSTICS stats_processed = ROW_COUNT;
    maintenance_log := maintenance_log || jsonb_build_object('old_analytics_cleaned', stats_processed);
    
    -- Log maintenance completion
    INSERT INTO widget_usage_analytics (
        user_id, widget_type, action_type, metadata, usage_timestamp
    ) VALUES (
        NULL, 'system', 'daily_maintenance',
        maintenance_log,
        NOW()
    );
END;
$$;

-- =============================================================================
-- ERROR HANDLING AND RECOVERY
-- =============================================================================

-- Function to handle widget system errors
CREATE OR REPLACE FUNCTION handle_widget_error(
    p_error_context TEXT,
    p_error_details JSONB,
    p_user_id UUID DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    -- Log the error
    INSERT INTO widget_usage_analytics (
        user_id, widget_type, action_type, metadata, usage_timestamp
    ) VALUES (
        p_user_id, 'system', 'error_logged',
        jsonb_build_object(
            'error_context', p_error_context,
            'error_details', p_error_details,
            'error_timestamp', NOW()
        ),
        NOW()
    );
    
    -- Attempt recovery actions based on error context
    CASE p_error_context
        WHEN 'cache_failure' THEN
            -- Clear potentially corrupted cache
            PERFORM invalidate_widget_cache('all');
        WHEN 'sticker_upload_failure' THEN
            -- Clean up orphaned sticker records
            DELETE FROM stickers 
            WHERE created_at > NOW() - INTERVAL '1 hour' 
            AND file_url IS NULL;
        WHEN 'analysis_failure' THEN
            -- Reset failed analysis records
            UPDATE message_analysis_results 
            SET analysis_status = 'failed', 
                error_details = p_error_details 
            WHERE analysis_status = 'processing' 
            AND updated_at < NOW() - INTERVAL '30 minutes';
    END CASE;
END;
$$;

-- =============================================================================
-- GRANT PERMISSIONS
-- =============================================================================

-- Grant execute permissions for automation functions
GRANT EXECUTE ON FUNCTION generate_widget_cache_key TO authenticated;
GRANT EXECUTE ON FUNCTION invalidate_widget_cache TO authenticated;
GRANT EXECUTE ON FUNCTION aggregate_daily_widget_stats TO service_role;
GRANT EXECUTE ON FUNCTION cleanup_expired_cache TO service_role;
GRANT EXECUTE ON FUNCTION optimize_widget_cache TO service_role;
GRANT EXECUTE ON FUNCTION daily_widget_maintenance TO service_role;
GRANT EXECUTE ON FUNCTION handle_widget_error TO authenticated;

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON FUNCTION sticker_trigger_function IS 'Manages sticker lifecycle events and cache invalidation';
COMMENT ON FUNCTION emoticon_trigger_function IS 'Handles emoticon creation, updates, and cleanup';
COMMENT ON FUNCTION background_trigger_function IS 'Manages background lifecycle and cache invalidation';
COMMENT ON FUNCTION message_bubble_trigger_function IS 'Handles message events and triggers analysis';
COMMENT ON FUNCTION message_reaction_trigger_function IS 'Tracks reactions and updates emoticon usage';
COMMENT ON FUNCTION glimmer_post_trigger_function IS 'Manages Glimmer post lifecycle and moderation';
COMMENT ON FUNCTION aggregate_daily_widget_stats IS 'Creates daily usage statistics summaries';
COMMENT ON FUNCTION cleanup_expired_cache IS 'Removes expired cache entries';
COMMENT ON FUNCTION optimize_widget_cache IS 'Optimizes cache based on usage patterns';
COMMENT ON FUNCTION daily_widget_maintenance IS 'Performs scheduled maintenance tasks';
COMMENT ON FUNCTION handle_widget_error IS 'Handles errors and attempts recovery';

-- Setup completion message
SELECT 'Widgets Triggers and Automation Setup Complete!' as status, NOW() as setup_completed_at;
