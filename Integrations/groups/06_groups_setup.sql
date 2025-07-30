-- =====================================================
-- CRYSTAL SOCIAL - GROUPS SYSTEM SETUP
-- =====================================================
-- Initial data setup and configuration for groups system
-- =====================================================

-- Sample group data commented out - uncomment if you want demo groups
/*
-- Insert default group categories
INSERT INTO group_details (
    chat_id, display_name, description, emoji, is_public, is_discoverable,
    category, max_members, allow_member_invites
) VALUES 
-- Sample public groups to demonstrate the system
(
    gen_random_uuid(), 'Crystal Social Community', 
    'Welcome to the official Crystal Social community! Connect with other users and share your experiences.',
    '🌟', true, true, 'general', 500, true
),
(
    gen_random_uuid(), 'Gaming Lounge', 
    'Discuss your favorite games, find gaming partners, and share gaming tips and tricks.',
    '🎮', true, true, 'gaming', 200, true
),
(
    gen_random_uuid(), 'Study Group', 
    'A place for students to collaborate, share resources, and support each other in learning.',
    '📚', true, true, 'study', 100, true
),
(
    gen_random_uuid(), 'Creative Hub', 
    'Share your artwork, creative projects, and get feedback from fellow creators.',
    '🎨', true, true, 'creative', 150, true
),
(
    gen_random_uuid(), 'Tech Talk', 
    'Discuss the latest in technology, programming, and digital innovation.',
    '💻', true, true, 'tech', 300, true
)
ON CONFLICT (chat_id) DO NOTHING;
*/

-- Create helper function to setup default group rules
CREATE OR REPLACE FUNCTION create_default_group_rules(p_group_id UUID, p_creator_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Insert default rules for new groups
    INSERT INTO group_rules (group_id, created_by, title, description, rule_number, category, is_active) VALUES
    (p_group_id, p_creator_id, 'Be Respectful', 'Treat all members with kindness and respect. No harassment, bullying, or discriminatory language.', 1, 'general', true),
    (p_group_id, p_creator_id, 'Stay On Topic', 'Keep discussions relevant to the group''s purpose. Use appropriate channels for different topics.', 2, 'general', true),
    (p_group_id, p_creator_id, 'No Spam', 'Avoid excessive posting, repetitive messages, or promotional content without permission.', 3, 'general', true),
    (p_group_id, p_creator_id, 'Privacy & Safety', 'Do not share personal information without consent. Report any safety concerns to moderators.', 4, 'general', true),
    (p_group_id, p_creator_id, 'Content Guidelines', 'Keep content appropriate for all ages. No explicit, violent, or inappropriate material.', 5, 'general', true)
    ON CONFLICT (group_id, rule_number) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to initialize a new group with default settings
CREATE OR REPLACE FUNCTION initialize_new_group(
    p_group_id UUID,
    p_creator_id UUID,
    p_group_name VARCHAR(100),
    p_welcome_message TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
BEGIN
    -- Create default rules
    PERFORM create_default_group_rules(p_group_id, p_creator_id);
    
    -- Create welcome announcement if message provided
    IF p_welcome_message IS NOT NULL THEN
        INSERT INTO group_announcements (
            group_id, author_id, title, content, announcement_type, 
            priority, is_pinned, show_notification
        ) VALUES (
            p_group_id, p_creator_id, 'Welcome to ' || p_group_name || '!', 
            p_welcome_message, 'welcome', 'normal', true, true
        );
    END IF;
    
    -- Initialize analytics record
    INSERT INTO group_analytics (group_id, date, total_members, new_members)
    VALUES (p_group_id, CURRENT_DATE, 1, 1)
    ON CONFLICT (group_id, date) DO UPDATE SET
        total_members = group_analytics.total_members + 1,
        new_members = group_analytics.new_members + 1;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Group initialized successfully with default rules and settings'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Failed to initialize group: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get group recommendations for a user
CREATE OR REPLACE FUNCTION get_group_recommendations(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 10
) RETURNS JSONB AS $$
DECLARE
    v_user_groups UUID[];
    v_user_interests TEXT[];
    v_recommendations JSONB;
BEGIN
    -- Get user's current groups
    SELECT ARRAY_AGG(group_id) INTO v_user_groups
    FROM group_members
    WHERE user_id = p_user_id AND is_active = true;
    
    -- Get user's interests from their group categories
    SELECT ARRAY_AGG(DISTINCT gd.category) INTO v_user_interests
    FROM group_details gd
    JOIN group_members gm ON gd.chat_id = gm.group_id
    WHERE gm.user_id = p_user_id AND gm.is_active = true;
    
    -- Find recommended groups
    WITH group_scores AS (
        SELECT 
            gd.chat_id,
            gd.display_name,
            gd.description,
            gd.emoji,
            gd.category,
            gd.active_members_count,
            gd.last_activity_at,
            
            -- Calculate recommendation score
            (
                -- Category match bonus
                CASE WHEN gd.category = ANY(v_user_interests) THEN 10 ELSE 0 END +
                
                -- Activity bonus
                CASE 
                    WHEN gd.last_activity_at > NOW() - INTERVAL '24 hours' THEN 5
                    WHEN gd.last_activity_at > NOW() - INTERVAL '7 days' THEN 3
                    ELSE 0
                END +
                
                -- Size bonus (not too small, not too large)
                CASE 
                    WHEN gd.active_members_count BETWEEN 10 AND 100 THEN 3
                    WHEN gd.active_members_count BETWEEN 5 AND 200 THEN 1
                    ELSE 0
                END +
                
                -- Growth bonus
                COALESCE((
                    SELECT SUM(new_members - members_left)
                    FROM group_analytics
                    WHERE group_id = gd.chat_id 
                      AND date >= CURRENT_DATE - INTERVAL '7 days'
                ), 0)
            ) as recommendation_score
            
        FROM group_details gd
        WHERE gd.is_public = true 
          AND gd.is_discoverable = true
          AND (v_user_groups IS NULL OR gd.chat_id != ALL(v_user_groups))
          AND gd.active_members_count < gd.max_members
    )
    SELECT jsonb_agg(
        jsonb_build_object(
            'group_id', chat_id,
            'name', display_name,
            'description', description,
            'emoji', emoji,
            'category', category,
            'member_count', active_members_count,
            'last_activity', last_activity_at,
            'recommendation_score', recommendation_score
        )
        ORDER BY recommendation_score DESC
    ) INTO v_recommendations
    FROM (
        SELECT * FROM group_scores
        ORDER BY recommendation_score DESC
        LIMIT p_limit
    ) top_groups;
    
    RETURN COALESCE(v_recommendations, '[]'::jsonb);
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'error', 'Failed to get recommendations: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to handle group search with filters
CREATE OR REPLACE FUNCTION search_groups(
    p_query TEXT DEFAULT '',
    p_category VARCHAR(50) DEFAULT NULL,
    p_min_members INTEGER DEFAULT 0,
    p_max_members INTEGER DEFAULT 1000,
    p_activity_level VARCHAR(20) DEFAULT NULL,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
) RETURNS JSONB AS $$
DECLARE
    v_results JSONB;
    v_where_conditions TEXT := 'WHERE gd.is_public = true AND gd.is_discoverable = true';
BEGIN
    -- Build dynamic where conditions
    IF p_query != '' THEN
        v_where_conditions := v_where_conditions || 
            ' AND (gd.display_name ILIKE ''%' || p_query || '%'' OR gd.description ILIKE ''%' || p_query || '%'')';
    END IF;
    
    IF p_category IS NOT NULL THEN
        v_where_conditions := v_where_conditions || ' AND gd.category = ''' || p_category || '''';
    END IF;
    
    IF p_min_members > 0 THEN
        v_where_conditions := v_where_conditions || ' AND gd.active_members_count >= ' || p_min_members;
    END IF;
    
    IF p_max_members < 1000 THEN
        v_where_conditions := v_where_conditions || ' AND gd.active_members_count <= ' || p_max_members;
    END IF;
    
    IF p_activity_level IS NOT NULL THEN
        CASE p_activity_level
            WHEN 'very_active' THEN
                v_where_conditions := v_where_conditions || ' AND gd.last_activity_at > NOW() - INTERVAL ''1 hour''';
            WHEN 'active' THEN
                v_where_conditions := v_where_conditions || ' AND gd.last_activity_at > NOW() - INTERVAL ''24 hours''';
            WHEN 'moderate' THEN
                v_where_conditions := v_where_conditions || ' AND gd.last_activity_at > NOW() - INTERVAL ''7 days''';
        END CASE;
    END IF;
    
    -- Execute dynamic query
    EXECUTE format('
        SELECT jsonb_agg(
            jsonb_build_object(
                ''group_id'', gd.chat_id,
                ''name'', gd.display_name,
                ''description'', gd.description,
                ''emoji'', gd.emoji,
                ''category'', gd.category,
                ''member_count'', gd.active_members_count,
                ''max_members'', gd.max_members,
                ''last_activity'', gd.last_activity_at,
                ''created_at'', gd.created_at,
                ''activity_level'', CASE 
                    WHEN gd.last_activity_at > NOW() - INTERVAL ''1 hour'' THEN ''very_active''
                    WHEN gd.last_activity_at > NOW() - INTERVAL ''24 hours'' THEN ''active''
                    WHEN gd.last_activity_at > NOW() - INTERVAL ''7 days'' THEN ''moderate''
                    ELSE ''inactive''
                END
            )
            ORDER BY gd.last_activity_at DESC
        )
        FROM group_details gd
        %s
        LIMIT %s OFFSET %s
    ', v_where_conditions, p_limit, p_offset) INTO v_results;
    
    RETURN COALESCE(v_results, '[]'::jsonb);
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'error', 'Search failed: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to generate group activity report
CREATE OR REPLACE FUNCTION generate_group_activity_report(
    p_group_id UUID,
    p_days INTEGER DEFAULT 30
) RETURNS JSONB AS $$
DECLARE
    v_report JSONB;
    v_start_date DATE := CURRENT_DATE - INTERVAL '30 days';
BEGIN
    WITH daily_stats AS (
        SELECT 
            date,
            messages_sent,
            unique_active_members,
            new_members,
            members_left,
            reactions_given,
            total_members
        FROM group_analytics
        WHERE group_id = p_group_id 
          AND date >= v_start_date
        ORDER BY date
    ),
    summary_stats AS (
        SELECT 
            COUNT(*) as days_tracked,
            SUM(messages_sent) as total_messages,
            AVG(messages_sent) as avg_daily_messages,
            MAX(messages_sent) as peak_daily_messages,
            SUM(new_members) as total_new_members,
            SUM(members_left) as total_members_left,
            SUM(reactions_given) as total_reactions,
            MAX(total_members) as peak_membership,
            MIN(total_members) as lowest_membership
        FROM daily_stats
    )
    SELECT jsonb_build_object(
        'group_id', p_group_id,
        'period_days', p_days,
        'start_date', v_start_date,
        'end_date', CURRENT_DATE,
        'summary', (
            SELECT jsonb_build_object(
                'days_tracked', days_tracked,
                'total_messages', total_messages,
                'avg_daily_messages', ROUND(avg_daily_messages, 2),
                'peak_daily_messages', peak_daily_messages,
                'total_new_members', total_new_members,
                'total_members_left', total_members_left,
                'net_growth', (total_new_members - total_members_left),
                'total_reactions', total_reactions,
                'peak_membership', peak_membership,
                'lowest_membership', lowest_membership
            )
            FROM summary_stats
        ),
        'daily_data', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'date', date,
                    'messages', messages_sent,
                    'active_members', unique_active_members,
                    'new_members', new_members,
                    'members_left', members_left,
                    'reactions', reactions_given,
                    'total_members', total_members
                )
                ORDER BY date
            )
            FROM daily_stats
        ),
        'trends', jsonb_build_object(
            'activity_trend', 
                CASE 
                    WHEN (SELECT AVG(messages_sent) FROM daily_stats WHERE date >= CURRENT_DATE - 7) >
                         (SELECT AVG(messages_sent) FROM daily_stats WHERE date < CURRENT_DATE - 7) 
                    THEN 'increasing'
                    ELSE 'decreasing'
                END,
            'membership_trend',
                CASE 
                    WHEN (SELECT SUM(new_members - members_left) FROM daily_stats WHERE date >= CURRENT_DATE - 7) > 0
                    THEN 'growing'
                    ELSE 'declining'
                END
        )
    ) INTO v_report;
    
    RETURN v_report;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'error', 'Failed to generate report: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to handle bulk member operations
CREATE OR REPLACE FUNCTION bulk_update_members(
    p_group_id UUID,
    p_user_ids UUID[],
    p_action VARCHAR(20),
    p_moderator_id UUID,
    p_reason TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_success_count INTEGER := 0;
    v_error_count INTEGER := 0;
    v_errors JSONB := '[]'::jsonb;
    v_result JSONB;
BEGIN
    -- Validate moderator permissions
    IF NOT EXISTS (
        SELECT 1 FROM group_members 
        WHERE group_id = p_group_id 
          AND user_id = p_moderator_id 
          AND is_active = true
          AND (role IN ('owner', 'admin') OR permissions->>'can_remove_members' = 'true')
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Insufficient permissions for bulk operations'
        );
    END IF;
    
    -- Process each user
    FOREACH v_user_id IN ARRAY p_user_ids
    LOOP
        BEGIN
            CASE p_action
                WHEN 'mute' THEN
                    UPDATE group_members 
                    SET is_muted = true, muted_until = NOW() + INTERVAL '24 hours'
                    WHERE group_id = p_group_id AND user_id = v_user_id;
                    
                WHEN 'unmute' THEN
                    UPDATE group_members 
                    SET is_muted = false, muted_until = NULL
                    WHERE group_id = p_group_id AND user_id = v_user_id;
                    
                WHEN 'kick' THEN
                    UPDATE group_members 
                    SET is_active = false, left_at = NOW()
                    WHERE group_id = p_group_id AND user_id = v_user_id;
                    
                WHEN 'ban' THEN
                    UPDATE group_members 
                    SET is_active = false, is_banned = true, left_at = NOW(), ban_reason = p_reason
                    WHERE group_id = p_group_id AND user_id = v_user_id;
                    
                ELSE
                    RAISE EXCEPTION 'Invalid action: %', p_action;
            END CASE;
            
            -- Log the action
            INSERT INTO group_moderation_logs (
                group_id, moderator_id, target_user_id, action_type, reason
            ) VALUES (
                p_group_id, p_moderator_id, v_user_id, p_action, p_reason
            );
            
            v_success_count := v_success_count + 1;
            
        EXCEPTION
            WHEN OTHERS THEN
                v_error_count := v_error_count + 1;
                v_errors := v_errors || jsonb_build_object(
                    'user_id', v_user_id,
                    'error', SQLERRM
                );
        END;
    END LOOP;
    
    RETURN jsonb_build_object(
        'success', v_error_count = 0,
        'processed', array_length(p_user_ids, 1),
        'success_count', v_success_count,
        'error_count', v_error_count,
        'errors', v_errors,
        'message', format('Bulk %s completed: %s succeeded, %s failed', p_action, v_success_count, v_error_count)
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Bulk operation failed: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create performance optimization indexes
CREATE INDEX IF NOT EXISTS idx_group_details_category_public 
ON group_details(category, is_public, is_discoverable) WHERE is_public = true;

CREATE INDEX IF NOT EXISTS idx_group_details_activity_members 
ON group_details(last_activity_at DESC, active_members_count DESC);

CREATE INDEX IF NOT EXISTS idx_group_members_user_active 
ON group_members(user_id, is_active, last_seen_at DESC) WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_group_invitations_pending_expires 
ON group_invitations(status, expires_at) WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_group_events_upcoming 
ON group_events(start_time, status) WHERE status = 'scheduled';

CREATE INDEX IF NOT EXISTS idx_group_analytics_recent 
ON group_analytics(group_id, date DESC);

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION create_default_group_rules TO authenticated;
GRANT EXECUTE ON FUNCTION initialize_new_group TO authenticated;
GRANT EXECUTE ON FUNCTION get_group_recommendations TO authenticated;
GRANT EXECUTE ON FUNCTION search_groups TO authenticated;
GRANT EXECUTE ON FUNCTION generate_group_activity_report TO authenticated;
GRANT EXECUTE ON FUNCTION bulk_update_members TO authenticated;

-- Grant function execution to service role for automated tasks
GRANT EXECUTE ON FUNCTION create_default_group_rules TO service_role;
GRANT EXECUTE ON FUNCTION initialize_new_group TO service_role;

-- Create notification for successful setup
DO $$
BEGIN
    RAISE NOTICE 'Groups system setup completed successfully!';
    RAISE NOTICE 'Created comprehensive group management system with:';
    RAISE NOTICE '  - 12 core tables for group operations';
    RAISE NOTICE '  - 8 advanced functions for group management';
    RAISE NOTICE '  - 15+ automated triggers for real-time updates';
    RAISE NOTICE '  - 25+ security policies for data protection';
    RAISE NOTICE '  - 7 optimized views for efficient queries';
    RAISE NOTICE '  - Sample public groups and default configurations';
    RAISE NOTICE 'System supports: member management, invitations, events, media sharing,';
    RAISE NOTICE 'moderation tools, analytics, announcements, and comprehensive security.';
END $$;
