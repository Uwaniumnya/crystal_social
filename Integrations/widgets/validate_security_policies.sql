-- Crystal Social Widgets System - Security Policies Validation
-- File: validate_security_policies.sql
-- Purpose: Validate the security policies can be executed safely against different schema versions

-- =============================================================================
-- SCHEMA DETECTION AND VALIDATION
-- =============================================================================

-- Function to check glimmer_posts schema compatibility
CREATE OR REPLACE FUNCTION check_glimmer_posts_schema()
RETURNS TABLE (
    table_exists BOOLEAN,
    has_moderation_status BOOLEAN,
    has_is_published BOOLEAN,
    schema_version TEXT,
    recommended_action TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = 'glimmer_posts' AND table_schema = 'public'
        ) as table_exists,
        EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'glimmer_posts' AND column_name = 'moderation_status' AND table_schema = 'public'
        ) as has_moderation_status,
        EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'glimmer_posts' AND column_name = 'is_published' AND table_schema = 'public'
        ) as has_is_published,
        CASE 
            WHEN EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'glimmer_posts' AND column_name = 'moderation_status' AND table_schema = 'public'
            ) THEN 'widgets'
            WHEN EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'glimmer_posts' AND column_name = 'is_published' AND table_schema = 'public'
            ) THEN 'services'
            WHEN EXISTS (
                SELECT 1 FROM information_schema.tables 
                WHERE table_name = 'glimmer_posts' AND table_schema = 'public'
            ) THEN 'unknown'
            ELSE 'table_missing'
        END as schema_version,
        CASE 
            WHEN NOT EXISTS (
                SELECT 1 FROM information_schema.tables 
                WHERE table_name = 'glimmer_posts' AND table_schema = 'public'
            ) THEN 'Create glimmer_posts table first using either widgets or services schema'
            WHEN EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'glimmer_posts' AND column_name = 'moderation_status' AND table_schema = 'public'
            ) THEN 'Widgets schema detected - policies will use moderation_status column'
            WHEN EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'glimmer_posts' AND column_name = 'is_published' AND table_schema = 'public'
            ) THEN 'Services schema detected - policies will use is_published column'
            ELSE 'Unknown schema - policies will create fallback rules'
        END as recommended_action;
END;
$$;

-- =============================================================================
-- VALIDATION TESTS
-- =============================================================================

-- Test the schema detection function
DO $$
DECLARE
    test_result RECORD;
BEGIN
    RAISE NOTICE '=== GLIMMER POSTS SCHEMA VALIDATION ===';
    
    FOR test_result IN SELECT * FROM check_glimmer_posts_schema() LOOP
        RAISE NOTICE 'Table exists: %', test_result.table_exists;
        RAISE NOTICE 'Has moderation_status: %', test_result.has_moderation_status;
        RAISE NOTICE 'Has is_published: %', test_result.has_is_published;
        RAISE NOTICE 'Schema version: %', test_result.schema_version;
        RAISE NOTICE 'Recommended action: %', test_result.recommended_action;
    END LOOP;
    
    RAISE NOTICE '=== VALIDATION COMPLETE ===';
END
$$;

-- Function to validate all widget tables exist
CREATE OR REPLACE FUNCTION validate_widget_tables()
RETURNS TABLE (
    table_name TEXT,
    exists BOOLEAN,
    rls_enabled BOOLEAN,
    policy_count INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH widget_tables AS (
        SELECT unnest(ARRAY[
            'stickers', 'recent_stickers', 'sticker_collections',
            'emoticon_categories', 'custom_emoticons', 'emoticon_usage', 'emoticon_favorites',
            'chat_backgrounds', 'user_chat_backgrounds',
            'message_bubbles', 'message_reactions',
            'user_widget_preferences', 'widget_usage_analytics', 'daily_widget_stats',
            'message_analysis_results', 'gem_unlock_analytics',
            'glimmer_posts', 'user_local_sync',
            'widget_performance_metrics', 'widget_cache_entries', 'widget_security_events'
        ]) as tbl_name
    )
    SELECT 
        wt.tbl_name::TEXT,
        EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = wt.tbl_name AND table_schema = 'public'
        ) as exists,
        CASE 
            WHEN EXISTS (
                SELECT 1 FROM information_schema.tables 
                WHERE table_name = wt.tbl_name AND table_schema = 'public'
            ) THEN 
                (SELECT relrowsecurity FROM pg_class 
                 WHERE relname = wt.tbl_name AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public'))
            ELSE false
        END as rls_enabled,
        COALESCE((
            SELECT COUNT(*)::INTEGER 
            FROM pg_policies 
            WHERE tablename = wt.tbl_name AND schemaname = 'public'
        ), 0) as policy_count
    FROM widget_tables wt
    ORDER BY wt.tbl_name;
END;
$$;

-- Run widget tables validation
DO $$
DECLARE
    table_result RECORD;
    missing_tables INTEGER := 0;
    tables_without_rls INTEGER := 0;
    tables_without_policies INTEGER := 0;
BEGIN
    RAISE NOTICE '=== WIDGET TABLES VALIDATION ===';
    
    FOR table_result IN SELECT * FROM validate_widget_tables() LOOP
        IF NOT table_result.exists THEN
            RAISE NOTICE 'MISSING: Table % does not exist', table_result.table_name;
            missing_tables := missing_tables + 1;
        ELSIF NOT table_result.rls_enabled THEN
            RAISE NOTICE 'NO RLS: Table % exists but RLS not enabled', table_result.table_name;
            tables_without_rls := tables_without_rls + 1;
        ELSIF table_result.policy_count = 0 THEN
            RAISE NOTICE 'NO POLICIES: Table % has RLS but no policies', table_result.table_name;
            tables_without_policies := tables_without_policies + 1;
        ELSE
            RAISE NOTICE 'OK: Table % has RLS enabled with % policies', table_result.table_name, table_result.policy_count;
        END IF;
    END LOOP;
    
    RAISE NOTICE '=== VALIDATION SUMMARY ===';
    RAISE NOTICE 'Missing tables: %', missing_tables;
    RAISE NOTICE 'Tables without RLS: %', tables_without_rls;
    RAISE NOTICE 'Tables without policies: %', tables_without_policies;
    
    IF missing_tables = 0 AND tables_without_rls = 0 AND tables_without_policies = 0 THEN
        RAISE NOTICE 'SUCCESS: All widget tables properly configured!';
    ELSE
        RAISE NOTICE 'ATTENTION: Some tables need attention (see details above)';
    END IF;
END
$$;

-- Clean up validation functions
DROP FUNCTION IF EXISTS check_glimmer_posts_schema();
DROP FUNCTION IF EXISTS validate_widget_tables();

SELECT 'Widgets Security Policies Validation Complete!' as validation_status, NOW() as validated_at;
