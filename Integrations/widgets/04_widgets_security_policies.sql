-- Crystal Social Widgets System - Security Policies
-- File: 04_widgets_security_policies.sql
-- Purpose: Row Level Security policies for comprehensive widget system protection

-- =============================================================================
-- SAFE POLICY CREATION FUNCTIONS (DEFINED FIRST)
-- =============================================================================

-- Function to safely create user policies with type validation
CREATE OR REPLACE FUNCTION create_user_policy_safe(
    p_table_name TEXT,
    p_policy_name TEXT,
    p_operation TEXT,
    p_user_column TEXT DEFAULT 'user_id'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    table_exists BOOLEAN;
    column_exists BOOLEAN;
    column_type TEXT;
    using_clause TEXT;
    with_check_clause TEXT;
BEGIN
    -- Check if table exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = p_table_name
    ) INTO table_exists;
    
    IF NOT table_exists THEN
        RAISE NOTICE 'Table % does not exist, skipping policy %', p_table_name, p_policy_name;
        RETURN FALSE;
    END IF;
    
    -- Check if column exists and get its type
    SELECT data_type INTO column_type
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = p_table_name 
    AND column_name = p_user_column;
    
    column_exists := FOUND;
    
    IF NOT column_exists THEN
        RAISE NOTICE 'Column %.% does not exist, skipping policy %', p_table_name, p_user_column, p_policy_name;
        RETURN FALSE;
    END IF;
    
    -- Validate column type is UUID
    IF column_type != 'uuid' THEN
        RAISE NOTICE 'Column %.% is type %, expected uuid, skipping policy %', p_table_name, p_user_column, column_type, p_policy_name;
        RETURN FALSE;
    END IF;
    
    -- Check if policy already exists
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = p_table_name 
        AND policyname = p_policy_name
    ) THEN
        RAISE NOTICE 'Policy % already exists on table %, skipping', p_policy_name, p_table_name;
        RETURN TRUE;
    END IF;
    
    -- Build the policy clauses with proper column reference
    using_clause := format('auth.uid()::UUID = %I', p_user_column);
    with_check_clause := format('auth.uid()::UUID = %I', p_user_column);
    
    -- Create policy based on operation type
    CASE p_operation
        WHEN 'SELECT' THEN
            EXECUTE format('CREATE POLICY %I ON %I FOR SELECT USING (%s)', 
                p_policy_name, p_table_name, using_clause);
        WHEN 'INSERT' THEN
            EXECUTE format('CREATE POLICY %I ON %I FOR INSERT WITH CHECK (%s)', 
                p_policy_name, p_table_name, with_check_clause);
        WHEN 'UPDATE' THEN
            EXECUTE format('CREATE POLICY %I ON %I FOR UPDATE USING (%s) WITH CHECK (%s)', 
                p_policy_name, p_table_name, using_clause, with_check_clause);
        WHEN 'DELETE' THEN
            EXECUTE format('CREATE POLICY %I ON %I FOR DELETE USING (%s)', 
                p_policy_name, p_table_name, using_clause);
        WHEN 'ALL' THEN
            EXECUTE format('CREATE POLICY %I ON %I FOR ALL USING (%s) WITH CHECK (%s)', 
                p_policy_name, p_table_name, using_clause, with_check_clause);
        ELSE
            RAISE NOTICE 'Unknown operation type: %, skipping policy creation', p_operation;
            RETURN FALSE;
    END CASE;
    
    RAISE NOTICE 'Successfully created policy % on table %', p_policy_name, p_table_name;
    RETURN TRUE;
END;
$$;

-- =============================================================================
-- ENABLE ROW LEVEL SECURITY (CONDITIONAL)
-- =============================================================================

-- Enable RLS on widget tables only if they exist
DO $$
BEGIN
    -- Enable RLS conditionally for each table
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'stickers' AND table_schema = 'public') THEN
        ALTER TABLE stickers ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'recent_stickers' AND table_schema = 'public') THEN
        ALTER TABLE recent_stickers ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sticker_collections' AND table_schema = 'public') THEN
        ALTER TABLE sticker_collections ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'emoticon_categories' AND table_schema = 'public') THEN
        ALTER TABLE emoticon_categories ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'custom_emoticons' AND table_schema = 'public') THEN
        ALTER TABLE custom_emoticons ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'emoticon_usage' AND table_schema = 'public') THEN
        ALTER TABLE emoticon_usage ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'emoticon_favorites' AND table_schema = 'public') THEN
        ALTER TABLE emoticon_favorites ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'chat_backgrounds' AND table_schema = 'public') THEN
        ALTER TABLE chat_backgrounds ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_chat_backgrounds' AND table_schema = 'public') THEN
        ALTER TABLE user_chat_backgrounds ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'message_bubbles' AND table_schema = 'public') THEN
        ALTER TABLE message_bubbles ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'message_reactions' AND table_schema = 'public') THEN
        ALTER TABLE message_reactions ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_widget_preferences' AND table_schema = 'public') THEN
        ALTER TABLE user_widget_preferences ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'widget_usage_analytics' AND table_schema = 'public') THEN
        ALTER TABLE widget_usage_analytics ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'daily_widget_stats' AND table_schema = 'public') THEN
        ALTER TABLE daily_widget_stats ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'message_analysis_results' AND table_schema = 'public') THEN
        ALTER TABLE message_analysis_results ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'gem_unlock_analytics' AND table_schema = 'public') THEN
        ALTER TABLE gem_unlock_analytics ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'glimmer_posts' AND table_schema = 'public') THEN
        ALTER TABLE glimmer_posts ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_local_sync' AND table_schema = 'public') THEN
        ALTER TABLE user_local_sync ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'widget_performance_metrics' AND table_schema = 'public') THEN
        ALTER TABLE widget_performance_metrics ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'widget_cache_entries' AND table_schema = 'public') THEN
        ALTER TABLE widget_cache_entries ENABLE ROW LEVEL SECURITY;
    END IF;
    
    RAISE NOTICE 'Row Level Security enabled on existing widget tables';
END
$$;

-- =============================================================================
-- STICKER SYSTEM POLICIES (CONDITIONAL CREATION)
-- =============================================================================

-- Create sticker policies safely only if table exists with correct schema
DO $$
BEGIN
    -- Basic user policies for stickers table
    PERFORM create_user_policy_safe('stickers', 'Users can view own stickers', 'SELECT');
    PERFORM create_user_policy_safe('stickers', 'Users can insert own stickers', 'INSERT');
    PERFORM create_user_policy_safe('stickers', 'Users can update own stickers', 'UPDATE');
    PERFORM create_user_policy_safe('stickers', 'Users can delete own stickers', 'DELETE');
    
    -- Create additional policies if stickers table exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'stickers' AND table_schema = 'public') THEN
        
        -- Users can view public approved stickers
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'stickers' AND policyname = 'Users can view public approved stickers') THEN
            CREATE POLICY "Users can view public approved stickers"
            ON stickers FOR SELECT
            USING (is_public = true AND is_approved = true);
        END IF;
        
        -- Moderators can view all stickers
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'stickers' AND policyname = 'Moderators can view all stickers') THEN
            CREATE POLICY "Moderators can view all stickers"
            ON stickers FOR SELECT
            USING (
                EXISTS (
                    SELECT 1 FROM auth.users u
                    WHERE u.id = auth.uid()::UUID 
                    AND u.raw_user_meta_data->>'role' IN ('admin', 'moderator')
                )
            );
        END IF;
        
        -- Moderators can update sticker approval status
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'stickers' AND policyname = 'Moderators can update sticker approval') THEN
            CREATE POLICY "Moderators can update sticker approval"
            ON stickers FOR UPDATE
            USING (
                EXISTS (
                    SELECT 1 FROM auth.users u
                    WHERE u.id = auth.uid()::UUID 
                    AND u.raw_user_meta_data->>'role' IN ('admin', 'moderator')
                )
            )
            WITH CHECK (
                EXISTS (
                    SELECT 1 FROM auth.users u
                    WHERE u.id = auth.uid()::UUID 
                    AND u.raw_user_meta_data->>'role' IN ('admin', 'moderator')
                )
            );
        END IF;
        
    END IF;
    
    -- Recent stickers policies
    PERFORM create_user_policy_safe('recent_stickers', 'Users can view own recent stickers', 'SELECT');
    PERFORM create_user_policy_safe('recent_stickers', 'Users can manage own recent stickers', 'ALL');
    
    -- Sticker collections policies
    PERFORM create_user_policy_safe('sticker_collections', 'Users can manage own sticker collections', 'ALL');
    
    -- Public sticker collections view policy
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sticker_collections' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'sticker_collections' AND policyname = 'Users can view public sticker collections') THEN
            CREATE POLICY "Users can view public sticker collections"
            ON sticker_collections FOR SELECT
            USING (is_public = true);
        END IF;
    END IF;
    
    RAISE NOTICE 'Sticker system policies created conditionally';
END
$$;

-- =============================================================================
-- EMOTICON SYSTEM POLICIES (CONDITIONAL CREATION)
-- =============================================================================

-- Create emoticon policies safely only if tables exist with correct schema
DO $$
BEGIN
    -- Emoticon categories policies - public read access
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'emoticon_categories' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'emoticon_categories' AND policyname = 'Anyone can read emoticon categories') THEN
            CREATE POLICY "Anyone can read emoticon categories"
            ON emoticon_categories FOR SELECT
            USING (is_active = true);
        END IF;
        
        -- Only admins can manage emoticon categories
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'emoticon_categories' AND policyname = 'Admins can manage emoticon categories') THEN
            CREATE POLICY "Admins can manage emoticon categories"
            ON emoticon_categories FOR ALL
            USING (
                EXISTS (
                    SELECT 1 FROM auth.users u
                    WHERE u.id = auth.uid()::UUID 
                    AND u.raw_user_meta_data->>'role' = 'admin'
                )
            );
        END IF;
    END IF;

    -- Custom emoticons policies
    PERFORM create_user_policy_safe('custom_emoticons', 'Users can view own custom emoticons', 'SELECT');
    PERFORM create_user_policy_safe('custom_emoticons', 'Users can create custom emoticons', 'INSERT');
    PERFORM create_user_policy_safe('custom_emoticons', 'Users can update own custom emoticons', 'UPDATE');
    PERFORM create_user_policy_safe('custom_emoticons', 'Users can delete own custom emoticons', 'DELETE');
    
    -- Additional custom emoticon policies
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'custom_emoticons' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'custom_emoticons' AND policyname = 'Users can view public approved custom emoticons') THEN
            CREATE POLICY "Users can view public approved custom emoticons"
            ON custom_emoticons FOR SELECT
            USING (is_public = true AND is_approved = true);
        END IF;
    END IF;

    -- Emoticon usage tracking policies
    PERFORM create_user_policy_safe('emoticon_usage', 'Users can view own emoticon usage', 'SELECT');
    PERFORM create_user_policy_safe('emoticon_usage', 'Users can record own emoticon usage', 'INSERT');
    
    -- System service role policy for emoticon usage
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'emoticon_usage' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'emoticon_usage' AND policyname = 'System can manage emoticon usage') THEN
            CREATE POLICY "System can manage emoticon usage"
            ON emoticon_usage FOR ALL
            USING (auth.role() = 'service_role');
        END IF;
    END IF;

    -- Emoticon favorites policies
    PERFORM create_user_policy_safe('emoticon_favorites', 'Users can manage own emoticon favorites', 'ALL');
    
    RAISE NOTICE 'Emoticon system policies created conditionally';
END
$$;

-- =============================================================================
-- BACKGROUND SYSTEM POLICIES (CONDITIONAL CREATION)
-- =============================================================================

-- Create background policies safely only if tables exist with correct schema
DO $$
BEGIN
    -- Chat backgrounds policies
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'chat_backgrounds' AND table_schema = 'public') THEN
        -- Public background view policy
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'chat_backgrounds' AND policyname = 'Users can view public backgrounds') THEN
            CREATE POLICY "Users can view public backgrounds"
            ON chat_backgrounds FOR SELECT
            USING (is_public = true);
        END IF;
        
        -- Created backgrounds policies using safe function
        PERFORM create_user_policy_safe('chat_backgrounds', 'Users can view own created backgrounds', 'SELECT', 'created_by');
        PERFORM create_user_policy_safe('chat_backgrounds', 'Users can update own backgrounds', 'UPDATE', 'created_by');
        PERFORM create_user_policy_safe('chat_backgrounds', 'Users can delete own backgrounds', 'DELETE', 'created_by');
        
        -- Special insert policy for backgrounds (allows null created_by)
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'chat_backgrounds' AND policyname = 'Users can create backgrounds') THEN
            CREATE POLICY "Users can create backgrounds"
            ON chat_backgrounds FOR INSERT
            WITH CHECK (auth.uid()::UUID = created_by OR created_by IS NULL);
        END IF;
        
        -- Admin preset management policy
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'chat_backgrounds' AND policyname = 'Admins can manage preset backgrounds') THEN
            CREATE POLICY "Admins can manage preset backgrounds"
            ON chat_backgrounds FOR ALL
            USING (
                is_preset = true AND
                EXISTS (
                    SELECT 1 FROM auth.users u
                    WHERE u.id = auth.uid()::UUID 
                    AND u.raw_user_meta_data->>'role' = 'admin'
                )
            );
        END IF;
    END IF;

    -- User chat background preferences
    PERFORM create_user_policy_safe('user_chat_backgrounds', 'Users can manage own chat backgrounds', 'ALL');
    
    RAISE NOTICE 'Background system policies created conditionally';
END
$$;

-- =============================================================================
-- MESSAGE SYSTEM POLICIES (CONDITIONAL CREATION)
-- =============================================================================

-- Create message system policies safely only if tables exist with correct schema
DO $$
BEGIN
    -- Message bubbles basic user policies
    PERFORM create_user_policy_safe('message_bubbles', 'Users can view own messages', 'SELECT');
    PERFORM create_user_policy_safe('message_bubbles', 'Users can create own messages', 'INSERT');
    PERFORM create_user_policy_safe('message_bubbles', 'Users can update own messages', 'UPDATE');
    PERFORM create_user_policy_safe('message_bubbles', 'Users can delete own messages', 'DELETE');
    
    -- Additional message policies
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'message_bubbles' AND table_schema = 'public') THEN
        -- Users can view messages in their chats (simplified for now)
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'message_bubbles' AND policyname = 'Users can view messages in their chats') THEN
            CREATE POLICY "Users can view messages in their chats"
            ON message_bubbles FOR SELECT
            USING (
                -- Users can view messages in chats where they are participants
                -- For now, allow viewing if the user exists (to be expanded with proper chat membership)
                auth.uid() IS NOT NULL
            );
        END IF;
    END IF;

    -- Message reactions policies
    PERFORM create_user_policy_safe('message_reactions', 'Users can manage own reactions', 'INSERT');
    PERFORM create_user_policy_safe('message_reactions', 'Users can update own reactions', 'UPDATE');
    PERFORM create_user_policy_safe('message_reactions', 'Users can delete own reactions', 'DELETE');
    
    -- Additional message reaction policies
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'message_reactions' AND table_schema = 'public') THEN
        -- Users can view reactions on accessible messages
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'message_reactions' AND policyname = 'Users can view reactions on accessible messages') THEN
            CREATE POLICY "Users can view reactions on accessible messages"
            ON message_reactions FOR SELECT
            USING (
                -- Allow viewing reactions on messages the user created or can access
                EXISTS (
                    SELECT 1 FROM message_bubbles 
                    WHERE message_bubbles.message_id::UUID = message_reactions.message_id::UUID
                    AND message_bubbles.user_id = auth.uid()::UUID
                )
            );
        END IF;
    END IF;
    
    RAISE NOTICE 'Message system policies created conditionally';
END
$$;

-- =============================================================================
-- USER PREFERENCES POLICIES (CONDITIONAL CREATION)
-- =============================================================================

-- Create user preferences policies safely only if tables exist with correct schema
DO $$
BEGIN
    -- User widget preferences policies
    PERFORM create_user_policy_safe('user_widget_preferences', 'Users can view own widget preferences', 'SELECT');
    PERFORM create_user_policy_safe('user_widget_preferences', 'Users can manage own widget preferences', 'INSERT');
    PERFORM create_user_policy_safe('user_widget_preferences', 'Users can update own widget preferences', 'UPDATE');
    
    RAISE NOTICE 'User preferences policies created conditionally';
END
$$;

-- =============================================================================
-- ANALYTICS POLICIES (CONDITIONAL CREATION)
-- =============================================================================

-- Create analytics policies safely only if tables exist with correct schema
DO $$
BEGIN
    -- Widget usage analytics policies
    PERFORM create_user_policy_safe('widget_usage_analytics', 'Users can view own analytics', 'SELECT');
    PERFORM create_user_policy_safe('widget_usage_analytics', 'Users can record own analytics', 'INSERT');
    
    -- System service role policies for analytics
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'widget_usage_analytics' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'widget_usage_analytics' AND policyname = 'System can manage analytics') THEN
            CREATE POLICY "System can manage analytics"
            ON widget_usage_analytics FOR ALL
            USING (auth.role() = 'service_role');
        END IF;
    END IF;

    -- Daily widget stats (admin/analyst access only)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'daily_widget_stats' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'daily_widget_stats' AND policyname = 'Admins can view daily stats') THEN
            CREATE POLICY "Admins can view daily stats"
            ON daily_widget_stats FOR SELECT
            USING (
                EXISTS (
                    SELECT 1 FROM auth.users u
                    WHERE u.id = auth.uid()::UUID 
                    AND u.raw_user_meta_data->>'role' IN ('admin', 'analyst')
                )
            );
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'daily_widget_stats' AND policyname = 'System can manage daily stats') THEN
            CREATE POLICY "System can manage daily stats"
            ON daily_widget_stats FOR ALL
            USING (auth.role() = 'service_role');
        END IF;
    END IF;
    
    RAISE NOTICE 'Analytics policies created conditionally';
END
$$;

-- =============================================================================
-- GEMSTONE INTEGRATION POLICIES (CONDITIONAL CREATION)
-- =============================================================================

-- Create gemstone integration policies safely only if tables exist with correct schema
DO $$
BEGIN
    -- Message analysis results policies
    PERFORM create_user_policy_safe('message_analysis_results', 'Users can view own message analysis', 'SELECT');
    
    -- System service role policy for message analysis
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'message_analysis_results' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'message_analysis_results' AND policyname = 'System can manage message analysis') THEN
            CREATE POLICY "System can manage message analysis"
            ON message_analysis_results FOR ALL
            USING (auth.role() = 'service_role');
        END IF;
    END IF;

    -- Gem unlock analytics policies
    PERFORM create_user_policy_safe('gem_unlock_analytics', 'Users can view own gem unlocks', 'SELECT');
    
    -- System service role policy for gem unlock analytics
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'gem_unlock_analytics' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'gem_unlock_analytics' AND policyname = 'System can manage gem unlock analytics') THEN
            CREATE POLICY "System can manage gem unlock analytics"
            ON gem_unlock_analytics FOR ALL
            USING (auth.role() = 'service_role');
        END IF;
    END IF;
    
    RAISE NOTICE 'Gemstone integration policies created conditionally';
END
$$;

-- =============================================================================
-- GLIMMER INTEGRATION POLICIES (CONDITIONAL CREATION)
-- =============================================================================

-- Create glimmer integration policies safely only if tables exist with correct schema
DO $$
BEGIN
    -- Glimmer posts basic user policies
    PERFORM create_user_policy_safe('glimmer_posts', 'Users can view own glimmer posts', 'SELECT');
    PERFORM create_user_policy_safe('glimmer_posts', 'Users can create glimmer posts', 'INSERT');
    PERFORM create_user_policy_safe('glimmer_posts', 'Users can update own glimmer posts', 'UPDATE');
    PERFORM create_user_policy_safe('glimmer_posts', 'Users can delete own glimmer posts', 'DELETE');
    
    -- Additional glimmer policies
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'glimmer_posts' AND table_schema = 'public') THEN
        -- Check which columns exist and create appropriate policy
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'glimmer_posts' AND column_name = 'moderation_status' AND table_schema = 'public') THEN
            -- Using widgets schema (has moderation_status)
            IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'glimmer_posts' AND policyname = 'Users can view approved glimmer posts') THEN
                CREATE POLICY "Users can view approved glimmer posts"
                ON glimmer_posts FOR SELECT
                USING (moderation_status = 'approved');
            END IF;
        ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'glimmer_posts' AND column_name = 'is_published' AND table_schema = 'public') THEN
            -- Using services schema (has is_published)
            IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'glimmer_posts' AND policyname = 'Users can view published glimmer posts') THEN
                CREATE POLICY "Users can view published glimmer posts"
                ON glimmer_posts FOR SELECT
                USING (is_published = true);
            END IF;
        ELSE
            -- Fallback: allow viewing all glimmer posts
            IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'glimmer_posts' AND policyname = 'Users can view glimmer posts') THEN
                CREATE POLICY "Users can view glimmer posts"
                ON glimmer_posts FOR SELECT
                USING (true);
            END IF;
        END IF;
    END IF;
    
    RAISE NOTICE 'Glimmer integration policies created conditionally';
    
    -- Additional moderator policy for glimmer posts
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'glimmer_posts' AND table_schema = 'public') THEN
        -- Check which columns exist and create appropriate moderator policy
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'glimmer_posts' AND column_name = 'moderation_status' AND table_schema = 'public') THEN
            -- Using widgets schema (has moderation_status)
            IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'glimmer_posts' AND policyname = 'Moderators can manage glimmer moderation') THEN
                CREATE POLICY "Moderators can manage glimmer moderation"
                ON glimmer_posts FOR UPDATE
                USING (
                    EXISTS (
                        SELECT 1 FROM auth.users u
                        WHERE u.id = auth.uid()::UUID 
                        AND u.raw_user_meta_data->>'role' IN ('admin', 'moderator')
                    )
                )
                WITH CHECK (
                    EXISTS (
                        SELECT 1 FROM auth.users u
                        WHERE u.id = auth.uid()::UUID 
                        AND u.raw_user_meta_data->>'role' IN ('admin', 'moderator')
                    )
                );
            END IF;
        ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'glimmer_posts' AND column_name = 'is_published' AND table_schema = 'public') THEN
            -- Using services schema (has is_published)
            IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'glimmer_posts' AND policyname = 'Moderators can manage glimmer publishing') THEN
                CREATE POLICY "Moderators can manage glimmer publishing"
                ON glimmer_posts FOR UPDATE
                USING (
                    EXISTS (
                        SELECT 1 FROM auth.users u
                        WHERE u.id = auth.uid()::UUID 
                        AND u.raw_user_meta_data->>'role' IN ('admin', 'moderator')
                    )
                )
                WITH CHECK (
                    EXISTS (
                        SELECT 1 FROM auth.users u
                        WHERE u.id = auth.uid()::UUID 
                        AND u.raw_user_meta_data->>'role' IN ('admin', 'moderator')
                    )
                );
            END IF;
        END IF;
    END IF;
END
$$;

-- =============================================================================
-- SYNC AND CACHE POLICIES (CONDITIONAL CREATION)
-- =============================================================================

-- Create sync and cache policies safely only if tables exist with correct schema
DO $$
BEGIN
    -- User local sync policies
    PERFORM create_user_policy_safe('user_local_sync', 'Users can manage own sync data', 'ALL');

    -- Widget performance metrics (system and admin access)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'widget_performance_metrics' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'widget_performance_metrics' AND policyname = 'System can manage performance metrics') THEN
            CREATE POLICY "System can manage performance metrics"
            ON widget_performance_metrics FOR ALL
            USING (auth.role() = 'service_role');
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'widget_performance_metrics' AND policyname = 'Admins can view performance metrics') THEN
            CREATE POLICY "Admins can view performance metrics"
            ON widget_performance_metrics FOR SELECT
            USING (
                EXISTS (
                    SELECT 1 FROM auth.users u
                    WHERE u.id = auth.uid()::UUID 
                    AND u.raw_user_meta_data->>'role' IN ('admin', 'developer')
                )
            );
        END IF;
    END IF;

    -- Widget cache entries (system managed)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'widget_cache_entries' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'widget_cache_entries' AND policyname = 'System can manage cache entries') THEN
            CREATE POLICY "System can manage cache entries"
            ON widget_cache_entries FOR ALL
            USING (auth.role() = 'service_role');
        END IF;
    END IF;
    
    RAISE NOTICE 'Sync and cache policies created conditionally';
END
$$;

-- =============================================================================
-- SAFE UUID CONVERSION FUNCTION
-- =============================================================================

-- Safe UUID conversion function to handle various input types and prevent type mismatches
CREATE OR REPLACE FUNCTION standardize_uuid(input_value ANYELEMENT)
RETURNS UUID
LANGUAGE plpgsql
IMMUTABLE
STRICT
AS $$
BEGIN
    -- Handle NULL input
    IF input_value IS NULL THEN
        RETURN NULL;
    END IF;
    
    -- If already UUID, return as-is
    IF pg_typeof(input_value) = 'uuid'::regtype THEN
        RETURN input_value::UUID;
    END IF;
    
    -- Handle text/varchar input with validation
    IF pg_typeof(input_value) IN ('text'::regtype, 'character varying'::regtype, 'varchar'::regtype) THEN
        -- Validate UUID format before conversion
        IF input_value::TEXT ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
            RETURN input_value::UUID;
        ELSE
            RAISE EXCEPTION 'Invalid UUID format: %', input_value;
        END IF;
    END IF;
    
    -- For other types, attempt conversion with error handling
    BEGIN
        RETURN input_value::TEXT::UUID;
    EXCEPTION WHEN others THEN
        RAISE EXCEPTION 'Cannot convert % of type % to UUID', input_value, pg_typeof(input_value);
    END;
END;
$$;

-- Grant execution permissions for the safe UUID function
GRANT EXECUTE ON FUNCTION standardize_uuid TO authenticated;
GRANT EXECUTE ON FUNCTION standardize_uuid TO service_role;

-- =============================================================================
-- SECURITY FUNCTIONS
-- =============================================================================

-- Rate limiting function for widget actions
CREATE OR REPLACE FUNCTION check_widget_rate_limit(
    p_user_id UUID,
    p_widget_type TEXT,
    p_action_type TEXT,
    p_time_window INTERVAL DEFAULT INTERVAL '1 hour',
    p_max_actions INTEGER DEFAULT 100
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    action_count INTEGER;
BEGIN
    -- Count recent actions
    SELECT COUNT(*) INTO action_count
    FROM widget_usage_analytics
    WHERE user_id = p_user_id
    AND widget_type = p_widget_type
    AND action_type = p_action_type
    AND usage_timestamp >= NOW() - p_time_window;
    
    -- Return true if under limit
    RETURN action_count < p_max_actions;
END;
$$;

-- Content moderation function
CREATE OR REPLACE FUNCTION moderate_widget_content(
    p_content TEXT,
    p_content_type TEXT DEFAULT 'text'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    moderation_result JSON;
    requires_review BOOLEAN := false;
    auto_approve BOOLEAN := true;
    issues TEXT[] := '{}';
BEGIN
    -- Basic content checks
    IF LENGTH(p_content) > 1000 THEN
        requires_review := true;
        auto_approve := false;
        issues := array_append(issues, 'content_too_long');
    END IF;
    
    -- Check for URLs (potential spam)
    IF p_content ~* 'https?://|www\.' THEN
        requires_review := true;
        auto_approve := false;
        issues := array_append(issues, 'contains_url');
    END IF;
    
    -- Check for excessive special characters
    IF LENGTH(regexp_replace(p_content, '[^!@#$%^&*()_+={}|:"<>?`~\[\]\\;'',./]', '', 'g')) > LENGTH(p_content) * 0.3 THEN
        requires_review := true;
        issues := array_append(issues, 'excessive_special_chars');
    END IF;
    
    -- Sticker-specific checks
    IF p_content_type = 'sticker_name' THEN
        IF p_content ~* '(download|free|click|buy|sale|offer)' THEN
            requires_review := true;
            auto_approve := false;
            issues := array_append(issues, 'promotional_content');
        END IF;
    END IF;
    
    moderation_result := json_build_object(
        'requires_review', requires_review,
        'auto_approve', auto_approve,
        'issues', issues,
        'moderation_score', CASE 
            WHEN auto_approve THEN 10
            WHEN requires_review THEN 5
            ELSE 1
        END
    );
    
    RETURN moderation_result;
END;
$$;

-- Security audit logging function
CREATE OR REPLACE FUNCTION log_widget_security_event(
    p_user_id UUID,
    p_event_type TEXT,
    p_widget_type TEXT,
    p_details JSONB DEFAULT '{}'
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO widget_usage_analytics (
        user_id, widget_type, action_type, metadata, usage_timestamp
    ) VALUES (
        p_user_id, p_widget_type, 'security_event', 
        jsonb_build_object(
            'event_type', p_event_type,
            'details', p_details,
            'ip_address', COALESCE(current_setting('request.headers', true)::json->>'x-forwarded-for', 'unknown'),
            'user_agent', COALESCE(current_setting('request.headers', true)::json->>'user-agent', 'unknown')
        ),
        NOW()
    );
END;
$$;

-- Function to check user permissions for widget actions
CREATE OR REPLACE FUNCTION check_widget_permission(
    p_user_id UUID,
    p_widget_type TEXT,
    p_action_type TEXT,
    p_resource_id TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_role TEXT;
    has_permission BOOLEAN := true;
BEGIN
    -- Get user role
    SELECT u.raw_user_meta_data->>'role' INTO user_role
    FROM auth.users u
    WHERE u.id = p_user_id;
    
    -- Check specific permissions based on action
    CASE p_action_type
        WHEN 'moderate_content' THEN
            has_permission := user_role IN ('admin', 'moderator');
        WHEN 'manage_presets' THEN
            has_permission := user_role = 'admin';
        WHEN 'view_analytics' THEN
            has_permission := user_role IN ('admin', 'analyst');
        WHEN 'bulk_operations' THEN
            has_permission := user_role IN ('admin', 'moderator');
        ELSE
            -- Default permissions for regular users
            has_permission := true;
    END CASE;
    
    -- Log permission check if denied
    IF NOT has_permission THEN
        PERFORM log_widget_security_event(
            p_user_id, 
            'permission_denied',
            p_widget_type,
            jsonb_build_object(
                'action_type', p_action_type,
                'resource_id', p_resource_id,
                'user_role', user_role
            )
        );
    END IF;
    
    RETURN has_permission;
END;
$$;

-- =============================================================================
-- GRANT PERMISSIONS FOR SECURITY FUNCTIONS
-- =============================================================================

GRANT EXECUTE ON FUNCTION check_widget_rate_limit TO authenticated;
GRANT EXECUTE ON FUNCTION moderate_widget_content TO authenticated;
GRANT EXECUTE ON FUNCTION log_widget_security_event TO service_role;
GRANT EXECUTE ON FUNCTION check_widget_permission TO authenticated;

-- =============================================================================
-- SECURITY MONITORING
-- =============================================================================

-- Create security events table for monitoring
CREATE TABLE IF NOT EXISTS widget_security_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    event_type TEXT NOT NULL,
    widget_type TEXT NOT NULL,
    severity TEXT DEFAULT 'info', -- info, warning, error, critical
    details JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_severity CHECK (severity IN ('info', 'warning', 'error', 'critical'))
);

-- Enable RLS on security events
ALTER TABLE widget_security_events ENABLE ROW LEVEL SECURITY;

-- Only admins can view security events
CREATE POLICY "Admins can view security events"
ON widget_security_events FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM auth.users u
        WHERE u.id = auth.uid()::UUID 
        AND u.raw_user_meta_data->>'role' = 'admin'
    )
);

-- System can write security events
CREATE POLICY "System can write security events"
ON widget_security_events FOR INSERT
WITH CHECK (auth.role() = 'service_role');

-- =============================================================================
-- AUTOMATED SECURITY TRIGGERS
-- =============================================================================

-- Function to detect suspicious widget activity
CREATE OR REPLACE FUNCTION detect_suspicious_widget_activity()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    recent_actions INTEGER;
    user_creation_date TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Check for rapid-fire actions (potential bot activity)
    SELECT COUNT(*) INTO recent_actions
    FROM widget_usage_analytics
    WHERE user_id = NEW.user_id
    AND widget_type = NEW.widget_type
    AND usage_timestamp >= NOW() - INTERVAL '1 minute';
    
    IF recent_actions > 20 THEN
        INSERT INTO widget_security_events (
            user_id, event_type, widget_type, severity, details
        ) VALUES (
            NEW.user_id, 'rapid_fire_activity', NEW.widget_type, 'warning',
            jsonb_build_object('actions_per_minute', recent_actions)
        );
    END IF;
    
    -- Check for new user suspicious activity
    SELECT u.created_at INTO user_creation_date
    FROM auth.users u
    WHERE u.id = NEW.user_id;
    
    IF user_creation_date >= NOW() - INTERVAL '1 hour' AND recent_actions > 10 THEN
        INSERT INTO widget_security_events (
            user_id, event_type, widget_type, severity, details
        ) VALUES (
            NEW.user_id, 'new_user_suspicious_activity', NEW.widget_type, 'error',
            jsonb_build_object(
                'user_age_minutes', EXTRACT(EPOCH FROM (NOW() - user_creation_date)) / 60,
                'actions_count', recent_actions
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger for suspicious activity detection
CREATE TRIGGER detect_suspicious_widget_activity_trigger
    AFTER INSERT ON widget_usage_analytics
    FOR EACH ROW
    EXECUTE FUNCTION detect_suspicious_widget_activity();

-- =============================================================================
-- PERFORMANCE INDEXES FOR UUID COLUMNS
-- =============================================================================

-- Essential indexes for UUID columns to optimize RLS policy performance
-- Note: Using regular CREATE INDEX for transaction-safe execution
CREATE INDEX IF NOT EXISTS idx_stickers_user_id ON stickers(user_id);
CREATE INDEX IF NOT EXISTS idx_recent_stickers_user_id ON recent_stickers(user_id);
CREATE INDEX IF NOT EXISTS idx_sticker_collections_user_id ON sticker_collections(user_id);
CREATE INDEX IF NOT EXISTS idx_custom_emoticons_user_id ON custom_emoticons(user_id);
CREATE INDEX IF NOT EXISTS idx_emoticon_usage_user_id ON emoticon_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_emoticon_favorites_user_id ON emoticon_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_backgrounds_created_by ON chat_backgrounds(created_by);
CREATE INDEX IF NOT EXISTS idx_user_chat_backgrounds_user_id ON user_chat_backgrounds(user_id);
CREATE INDEX IF NOT EXISTS idx_message_bubbles_user_id ON message_bubbles(user_id);
CREATE INDEX IF NOT EXISTS idx_message_reactions_user_id ON message_reactions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_widget_preferences_user_id ON user_widget_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_widget_usage_analytics_user_id ON widget_usage_analytics(user_id);
CREATE INDEX IF NOT EXISTS idx_message_analysis_results_user_id ON message_analysis_results(user_id);
CREATE INDEX IF NOT EXISTS idx_gem_unlock_analytics_user_id ON gem_unlock_analytics(user_id);
CREATE INDEX IF NOT EXISTS idx_glimmer_posts_user_id ON glimmer_posts(user_id);

-- Conditional composite index based on available columns
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'glimmer_posts' AND column_name = 'moderation_status' AND table_schema = 'public') THEN
        -- Widgets schema version with moderation_status
        CREATE INDEX IF NOT EXISTS idx_glimmer_posts_user_moderation ON glimmer_posts(user_id, moderation_status);
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'glimmer_posts' AND column_name = 'is_published' AND table_schema = 'public') THEN
        -- Services schema version with is_published
        CREATE INDEX IF NOT EXISTS idx_glimmer_posts_user_published ON glimmer_posts(user_id, is_published);
    END IF;
END
$$;
CREATE INDEX IF NOT EXISTS idx_user_local_sync_user_id ON user_local_sync(user_id);
CREATE INDEX IF NOT EXISTS idx_widget_security_events_user_id ON widget_security_events(user_id);

-- Composite indexes for common query patterns in RLS policies
CREATE INDEX IF NOT EXISTS idx_stickers_user_public_approved ON stickers(user_id, is_public, is_approved);
CREATE INDEX IF NOT EXISTS idx_emoticon_usage_user_date ON emoticon_usage(user_id, used_at);
CREATE INDEX IF NOT EXISTS idx_widget_analytics_user_type_timestamp ON widget_usage_analytics(user_id, widget_type, usage_timestamp);
CREATE INDEX IF NOT EXISTS idx_security_events_user_type_severity ON widget_security_events(user_id, event_type, severity);

-- Note: Cannot create indexes on auth.users table as it's owned by Supabase system
-- Performance optimization for auth.users queries should be handled by Supabase

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON FUNCTION check_widget_rate_limit IS 'Check if user is within rate limits for widget actions';
COMMENT ON FUNCTION moderate_widget_content IS 'Automatically moderate widget content for approval';
COMMENT ON FUNCTION log_widget_security_event IS 'Log security-related events for audit trail';
COMMENT ON FUNCTION check_widget_permission IS 'Check user permissions for widget actions';
COMMENT ON FUNCTION detect_suspicious_widget_activity IS 'Detect and log suspicious widget usage patterns';
COMMENT ON FUNCTION standardize_uuid IS 'Safe UUID conversion function that handles various input types and prevents type mismatches';
COMMENT ON TABLE widget_security_events IS 'Security events log for widget system monitoring';

-- Setup completion message
SELECT 'Widgets Security Policies Setup Complete!' as status, NOW() as setup_completed_at;

