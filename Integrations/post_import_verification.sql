-- Crystal Social Post-Import Verification Script
-- Run this after importing all SQL files to verify the integration

-- =============================================================================
-- 1. CHECK FOR MISSING FOREIGN KEY REFERENCES
-- =============================================================================

SELECT 'CHECKING FOREIGN KEY REFERENCES...' as step;

SELECT 
    conname AS constraint_name,
    conrelid::regclass AS table_name,
    confrelid::regclass AS referenced_table,
    'MISSING REFERENCE' as issue
FROM pg_constraint 
WHERE contype = 'f' 
AND confrelid::regclass::text NOT IN (
    SELECT tablename FROM pg_tables WHERE schemaname = 'public'
)
AND confrelid::regclass::text NOT LIKE 'auth.%';

-- =============================================================================
-- 2. CHECK FOR DUPLICATE FUNCTION NAMES
-- =============================================================================

SELECT 'CHECKING DUPLICATE FUNCTIONS...' as step;

SELECT 
    proname as function_name, 
    count(*) as duplicate_count,
    'DUPLICATE FUNCTION' as issue
FROM pg_proc 
WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
GROUP BY proname 
HAVING count(*) > 1;

-- =============================================================================
-- 3. CHECK RLS STATUS ON ALL TABLES
-- =============================================================================

SELECT 'CHECKING ROW LEVEL SECURITY...' as step;

SELECT 
    schemaname, 
    tablename,
    'RLS NOT ENABLED' as issue
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename NOT IN (
    SELECT tablename 
    FROM pg_tables t 
    JOIN pg_class c ON c.relname = t.tablename 
    WHERE c.relrowsecurity = true
);

-- =============================================================================
-- 4. CHECK CRITICAL TABLES EXIST
-- =============================================================================

SELECT 'CHECKING CRITICAL TABLES...' as step;

WITH required_tables AS (
    SELECT unnest(ARRAY[
        'profiles', 'admin_config', 'support_requests', 'audit_logs',
        'stickers', 'emoticon_categories', 'chat_backgrounds', 'message_bubbles',
        'user_widget_preferences', 'widget_usage_analytics', 'glimmer_posts',
        'system_health_checks', 'content_moderation_queue', 'moderation_rules'
    ]) as table_name
)
SELECT 
    rt.table_name,
    CASE 
        WHEN pt.tablename IS NULL THEN 'MISSING TABLE'
        ELSE 'EXISTS'
    END as status
FROM required_tables rt
LEFT JOIN pg_tables pt ON pt.tablename = rt.table_name AND pt.schemaname = 'public'
ORDER BY rt.table_name;

-- =============================================================================
-- 5. CHECK ESSENTIAL FUNCTIONS EXIST
-- =============================================================================

SELECT 'CHECKING ESSENTIAL FUNCTIONS...' as step;

WITH required_functions AS (
    SELECT unnest(ARRAY[
        'update_updated_at_column',
        'get_admin_config',
        'set_admin_config',
        'log_admin_action',
        'check_content_moderation',
        'create_user_policy_safe',
        'standardize_uuid'
    ]) as function_name
)
SELECT 
    rf.function_name,
    CASE 
        WHEN pp.proname IS NULL THEN 'MISSING FUNCTION'
        ELSE 'EXISTS'
    END as status
FROM required_functions rf
LEFT JOIN pg_proc pp ON pp.proname = rf.function_name 
    AND pp.pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
ORDER BY rf.function_name;

-- =============================================================================
-- 6. COUNT TABLES BY INTEGRATION
-- =============================================================================

SELECT 'TABLE COUNT BY INTEGRATION...' as step;

SELECT 
    CASE 
        WHEN tablename LIKE '%admin%' OR tablename LIKE '%support%' OR tablename LIKE '%audit%' OR tablename LIKE '%moderation%' THEN 'admin'
        WHEN tablename LIKE '%widget%' OR tablename LIKE '%sticker%' OR tablename LIKE '%emoticon%' OR tablename LIKE '%background%' OR tablename LIKE '%bubble%' THEN 'widgets'
        WHEN tablename LIKE '%chat%' OR tablename LIKE '%message%' THEN 'chat'
        WHEN tablename LIKE '%reward%' OR tablename LIKE '%achievement%' OR tablename LIKE '%badge%' THEN 'rewards'
        WHEN tablename LIKE '%profile%' OR tablename LIKE '%user%' THEN 'profiles'
        WHEN tablename LIKE '%note%' THEN 'notes'
        WHEN tablename LIKE '%garden%' OR tablename LIKE '%plant%' THEN 'garden'
        WHEN tablename LIKE '%pet%' OR tablename LIKE '%butterfly%' THEN 'pets/butterfly'
        WHEN tablename LIKE '%gem%' THEN 'gems'
        WHEN tablename LIKE '%spotify%' THEN 'spotify'
        WHEN tablename LIKE '%group%' THEN 'groups'
        WHEN tablename LIKE '%tab%' THEN 'tabs'
        WHEN tablename LIKE '%service%' THEN 'services'
        ELSE 'other'
    END as integration,
    COUNT(*) as table_count
FROM pg_tables 
WHERE schemaname = 'public'
GROUP BY 1
ORDER BY 2 DESC;

-- =============================================================================
-- 7. CHECK BASIC FUNCTIONALITY
-- =============================================================================

SELECT 'TESTING BASIC FUNCTIONALITY...' as step;

-- Test config functions
SELECT 
    'get_admin_config' as test_function,
    CASE 
        WHEN get_admin_config('support_email') IS NOT NULL THEN 'WORKING'
        ELSE 'ERROR'
    END as status;

-- Test UUID generation
SELECT 
    'UUID generation' as test_function,
    CASE 
        WHEN gen_random_uuid() IS NOT NULL THEN 'WORKING'
        ELSE 'ERROR'
    END as status;

-- =============================================================================
-- 8. INTEGRATION SUMMARY
-- =============================================================================

SELECT 'INTEGRATION SUMMARY' as step;

SELECT 
    (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public') as total_tables,
    (SELECT COUNT(*) FROM pg_proc WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')) as total_functions,
    (SELECT COUNT(*) FROM pg_trigger) as total_triggers,
    (SELECT COUNT(*) FROM pg_policies) as total_policies;

-- =============================================================================
-- SUCCESS MESSAGE
-- =============================================================================

SELECT 
    '🎉 CRYSTAL SOCIAL DATABASE INTEGRATION VERIFICATION COMPLETE!' as message,
    NOW() as verified_at,
    'All SQL files have been processed. Review the results above for any issues.' as next_steps;
