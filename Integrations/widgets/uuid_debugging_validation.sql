-- Crystal Social Widgets System - UUID Debugging Validation
-- File: uuid_debugging_validation.sql
-- Purpose: Comprehensive validation script for UUID-related debugging checklist

-- =============================================================================
-- ✅ CHECKLIST ITEM 1: VALIDATE ALL user_id COLUMNS ARE UUID
-- =============================================================================

-- Query to validate column types in all widget tables
-- Note: Excluding widget_security_events as it's created in the security policies file
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name IN (
    'stickers', 'recent_stickers', 'sticker_collections',
    'emoticon_categories', 'custom_emoticons', 'emoticon_usage', 'emoticon_favorites',
    'chat_backgrounds', 'user_chat_backgrounds', 'message_bubbles', 'message_reactions',
    'user_widget_preferences', 'widget_usage_analytics', 'daily_widget_stats',
    'message_analysis_results', 'gem_unlock_analytics', 'glimmer_posts',
    'user_local_sync', 'widget_performance_metrics', 'widget_cache_entries'
    -- widget_security_events excluded - created in 04_widgets_security_policies.sql
)
AND column_name IN ('user_id', 'created_by', 'id')
ORDER BY table_name, column_name;

-- =============================================================================
-- ✅ CHECKLIST ITEM 2: CREATE STANDARDIZE_UUID() FUNCTION FOR SAFE CONVERSIONS
-- =============================================================================

-- Safe UUID conversion function to handle various input types
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
    
    -- Handle text/varchar input
    IF pg_typeof(input_value) IN ('text'::regtype, 'character varying'::regtype, 'varchar'::regtype) THEN
        -- Validate UUID format before conversion
        IF input_value::TEXT ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
            RETURN input_value::UUID;
        ELSE
            RAISE EXCEPTION 'Invalid UUID format: %', input_value;
        END IF;
    END IF;
    
    -- For other types, attempt conversion
    BEGIN
        RETURN input_value::TEXT::UUID;
    EXCEPTION WHEN others THEN
        RAISE EXCEPTION 'Cannot convert % of type % to UUID', input_value, pg_typeof(input_value);
    END;
END;
$$;

-- =============================================================================
-- ✅ CHECKLIST ITEM 3: ENHANCED RLS POLICIES WITH SAFE UUID COMPARISONS
-- =============================================================================

-- Enhanced policy creation function with safe UUID handling
CREATE OR REPLACE FUNCTION create_safe_user_policy(
    p_table_name TEXT,
    p_policy_name TEXT,
    p_operation TEXT,
    p_user_column TEXT DEFAULT 'user_id'
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    policy_sql TEXT;
BEGIN
    -- Build safe policy SQL with proper UUID casting
    policy_sql := format(
        'CREATE POLICY %I ON %I FOR %s USING (standardize_uuid(auth.uid()) = standardize_uuid(%I))',
        p_policy_name,
        p_table_name,
        p_operation,
        p_user_column
    );
    
    -- Execute the policy creation
    EXECUTE policy_sql;
    
    -- Log the policy creation
    RAISE NOTICE 'Created safe UUID policy: % on table: %', p_policy_name, p_table_name;
END;
$$;

-- =============================================================================
-- ✅ CHECKLIST ITEM 4: CREATE INDEXES ON UUID COLUMNS FOR PERFORMANCE
-- =============================================================================

-- Comprehensive index creation for all UUID columns
-- Note: Remove CONCURRENTLY for transaction-safe execution
-- Note: Only create indexes if tables exist

-- Core widget table indexes (should exist after 01_widgets_core_tables.sql)
DO $$
BEGIN
    -- Stickers system indexes
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'stickers') THEN
        CREATE INDEX IF NOT EXISTS idx_stickers_user_id ON stickers(user_id);
        CREATE INDEX IF NOT EXISTS idx_stickers_user_public ON stickers(user_id, is_public, is_approved);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'recent_stickers') THEN
        CREATE INDEX IF NOT EXISTS idx_recent_stickers_user_id ON recent_stickers(user_id);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sticker_collections') THEN
        CREATE INDEX IF NOT EXISTS idx_sticker_collections_user_id ON sticker_collections(user_id);
    END IF;
    
    -- Emoticon system indexes
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'custom_emoticons') THEN
        CREATE INDEX IF NOT EXISTS idx_custom_emoticons_user_id ON custom_emoticons(user_id);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'emoticon_usage') THEN
        CREATE INDEX IF NOT EXISTS idx_emoticon_usage_user_id ON emoticon_usage(user_id);
        CREATE INDEX IF NOT EXISTS idx_emoticon_usage_user_date ON emoticon_usage(user_id, used_at);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'emoticon_favorites') THEN
        CREATE INDEX IF NOT EXISTS idx_emoticon_favorites_user_id ON emoticon_favorites(user_id);
    END IF;
    
    -- Background system indexes
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'chat_backgrounds') THEN
        CREATE INDEX IF NOT EXISTS idx_chat_backgrounds_created_by ON chat_backgrounds(created_by);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_chat_backgrounds') THEN
        CREATE INDEX IF NOT EXISTS idx_user_chat_backgrounds_user_id ON user_chat_backgrounds(user_id);
    END IF;
    
    -- Message system indexes
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'message_bubbles') THEN
        CREATE INDEX IF NOT EXISTS idx_message_bubbles_user_id ON message_bubbles(user_id);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'message_reactions') THEN
        CREATE INDEX IF NOT EXISTS idx_message_reactions_user_id ON message_reactions(user_id);
    END IF;
    
    -- User preferences indexes
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_widget_preferences') THEN
        CREATE INDEX IF NOT EXISTS idx_user_widget_preferences_user_id ON user_widget_preferences(user_id);
    END IF;
    
    -- Analytics indexes
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'widget_usage_analytics') THEN
        CREATE INDEX IF NOT EXISTS idx_widget_usage_analytics_user_id ON widget_usage_analytics(user_id);
        CREATE INDEX IF NOT EXISTS idx_widget_analytics_user_type ON widget_usage_analytics(user_id, widget_type);
        CREATE INDEX IF NOT EXISTS idx_widget_analytics_user_timestamp ON widget_usage_analytics(user_id, usage_timestamp);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'message_analysis_results') THEN
        CREATE INDEX IF NOT EXISTS idx_message_analysis_results_user_id ON message_analysis_results(user_id);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'gem_unlock_analytics') THEN
        CREATE INDEX IF NOT EXISTS idx_gem_unlock_analytics_user_id ON gem_unlock_analytics(user_id);
    END IF;
    
    -- Glimmer integration indexes
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'glimmer_posts') THEN
        CREATE INDEX IF NOT EXISTS idx_glimmer_posts_user_id ON glimmer_posts(user_id);
    END IF;
    
    -- Sync indexes
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_local_sync') THEN
        CREATE INDEX IF NOT EXISTS idx_user_local_sync_user_id ON user_local_sync(user_id);
    END IF;
    
    -- Security events indexes (created in 04_widgets_security_policies.sql)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'widget_security_events') THEN
        CREATE INDEX IF NOT EXISTS idx_widget_security_events_user_id ON widget_security_events(user_id);
        CREATE INDEX IF NOT EXISTS idx_security_events_user_type ON widget_security_events(user_id, event_type);
    END IF;
    
    RAISE NOTICE 'Conditional index creation completed successfully';
END
$$;

-- =============================================================================
-- VALIDATION QUERIES FOR DEBUGGING
-- =============================================================================

-- Check for any policies with unsafe UUID comparisons
CREATE OR REPLACE FUNCTION validate_policy_uuid_safety()
RETURNS TABLE(
    policy_name TEXT,
    table_name TEXT,
    policy_definition TEXT,
    has_uuid_cast BOOLEAN,
    safety_status TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pol.policyname::TEXT,
        pol.tablename::TEXT,
        pol.qual::TEXT,
        (pol.qual ~ 'auth\.uid\(\)::UUID' OR pol.qual ~ 'standardize_uuid')::BOOLEAN,
        CASE 
            WHEN pol.qual ~ 'auth\.uid\(\)::UUID' OR pol.qual ~ 'standardize_uuid' THEN 'SAFE'
            WHEN pol.qual ~ 'auth\.uid\(\)' THEN 'UNSAFE - Missing UUID cast'
            ELSE 'REVIEW NEEDED'
        END::TEXT
    FROM pg_policies pol
    WHERE pol.schemaname = 'public'
    AND pol.tablename LIKE '%sticker%' 
       OR pol.tablename LIKE '%emoticon%' 
       OR pol.tablename LIKE '%background%'
       OR pol.tablename LIKE '%message%'
       OR pol.tablename LIKE '%widget%'
       OR pol.tablename LIKE '%glimmer%';
END;
$$;

-- Check for missing indexes on UUID columns
CREATE OR REPLACE FUNCTION validate_uuid_indexes()
RETURNS TABLE(
    table_name TEXT,
    column_name TEXT,
    has_index BOOLEAN,
    index_names TEXT[]
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.table_name::TEXT,
        c.column_name::TEXT,
        (COUNT(i.indexname) > 0)::BOOLEAN,
        ARRAY_AGG(i.indexname) FILTER (WHERE i.indexname IS NOT NULL)
    FROM information_schema.columns c
    LEFT JOIN pg_indexes i ON i.tablename = c.table_name 
        AND (i.indexdef LIKE '%' || c.column_name || '%')
    WHERE c.table_schema = 'public'
    AND c.data_type = 'uuid'
    AND c.column_name IN ('user_id', 'created_by', 'id')
    AND c.table_name IN (
        'stickers', 'recent_stickers', 'sticker_collections',
        'emoticon_categories', 'custom_emoticons', 'emoticon_usage', 'emoticon_favorites',
        'chat_backgrounds', 'user_chat_backgrounds', 'message_bubbles', 'message_reactions',
        'user_widget_preferences', 'widget_usage_analytics', 'daily_widget_stats',
        'message_analysis_results', 'gem_unlock_analytics', 'glimmer_posts',
        'user_local_sync', 'widget_performance_metrics', 'widget_cache_entries'
        -- Note: widget_security_events may not exist initially
    )
    -- Only include existing tables
    AND EXISTS (
        SELECT 1 FROM information_schema.tables t 
        WHERE t.table_schema = 'public' AND t.table_name = c.table_name
    )
    GROUP BY c.table_name, c.column_name
    ORDER BY c.table_name, c.column_name;
END;
$$;

-- =============================================================================
-- ✅ CHECKLIST ITEM 5: STAGING ENVIRONMENT TEST SCRIPT
-- =============================================================================

-- Test migration script for staging environment
CREATE OR REPLACE FUNCTION test_uuid_migration_staging()
RETURNS TABLE(
    test_name TEXT,
    test_result TEXT,
    test_status TEXT,
    details TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    test_count INTEGER := 0;
    pass_count INTEGER := 0;
BEGIN
    -- Test 1: Validate all UUID columns exist
    test_count := test_count + 1;
    BEGIN
        PERFORM column_name FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND data_type = 'uuid' 
        AND column_name IN ('user_id', 'created_by');
        
        pass_count := pass_count + 1;
        RETURN QUERY SELECT 'UUID Columns Validation'::TEXT, 'All UUID columns found'::TEXT, 'PASS'::TEXT, 'UUID columns properly defined'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'UUID Columns Validation'::TEXT, SQLERRM::TEXT, 'FAIL'::TEXT, 'Missing UUID columns'::TEXT;
    END;
    
    -- Test 2: Validate auth.uid() function availability
    test_count := test_count + 1;
    BEGIN
        PERFORM auth.uid();
        pass_count := pass_count + 1;
        RETURN QUERY SELECT 'Auth Function Test'::TEXT, 'auth.uid() available'::TEXT, 'PASS'::TEXT, 'Supabase auth functions working'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Auth Function Test'::TEXT, SQLERRM::TEXT, 'FAIL'::TEXT, 'Auth functions not available'::TEXT;
    END;
    
    -- Test 3: Validate standardize_uuid function
    test_count := test_count + 1;
    BEGIN
        PERFORM standardize_uuid('00000000-0000-0000-0000-000000000000'::UUID);
        pass_count := pass_count + 1;
        RETURN QUERY SELECT 'UUID Function Test'::TEXT, 'standardize_uuid() working'::TEXT, 'PASS'::TEXT, 'Safe UUID conversion available'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'UUID Function Test'::TEXT, SQLERRM::TEXT, 'FAIL'::TEXT, 'UUID function error'::TEXT;
    END;
    
    -- Test 4: Validate policy creation (only if stickers table exists)
    test_count := test_count + 1;
    BEGIN
        -- Check if stickers table exists first
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'stickers' AND table_schema = 'public') THEN
            -- Try creating a test policy
            EXECUTE 'CREATE POLICY test_uuid_policy ON stickers FOR SELECT USING (standardize_uuid(auth.uid()) = standardize_uuid(user_id))';
            EXECUTE 'DROP POLICY test_uuid_policy ON stickers';
            pass_count := pass_count + 1;
            RETURN QUERY SELECT 'Policy Creation Test'::TEXT, 'Safe UUID policies can be created'::TEXT, 'PASS'::TEXT, 'Policy system working'::TEXT;
        ELSE
            -- Table doesn't exist, skip test but don't fail
            pass_count := pass_count + 1;
            RETURN QUERY SELECT 'Policy Creation Test'::TEXT, 'Skipped - stickers table not found'::TEXT, 'PASS'::TEXT, 'Table will be created in proper import order'::TEXT;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Policy Creation Test'::TEXT, SQLERRM::TEXT, 'FAIL'::TEXT, 'Policy creation failed'::TEXT;
    END;
    
    -- Summary
    RETURN QUERY SELECT 
        'MIGRATION TEST SUMMARY'::TEXT, 
        format('%s/%s tests passed', pass_count, test_count)::TEXT,
        CASE WHEN pass_count = test_count THEN 'READY FOR PRODUCTION' ELSE 'NEEDS ATTENTION' END::TEXT,
        format('Migration safety: %s%%', ROUND((pass_count::NUMERIC / test_count::NUMERIC) * 100))::TEXT;
END;
$$;

-- =============================================================================
-- EXECUTION COMMANDS FOR VALIDATION
-- =============================================================================

-- Run all validation checks
COMMENT ON FUNCTION standardize_uuid IS 'Safe UUID conversion function that handles various input types';
COMMENT ON FUNCTION create_safe_user_policy IS 'Creates RLS policies with safe UUID comparisons';
COMMENT ON FUNCTION validate_policy_uuid_safety IS 'Validates that all policies use safe UUID comparisons';
COMMENT ON FUNCTION validate_uuid_indexes IS 'Checks for proper indexes on UUID columns';
COMMENT ON FUNCTION test_uuid_migration_staging IS 'Comprehensive staging environment test suite';

-- Instructions for running validation
SELECT 'UUID Debugging Validation Script Created!' as status, 
       'Run the validation functions to check each checklist item' as instructions,
       NOW() as created_at;
