-- Crystal Social Integration Validation Script
-- File: 99_integration_validation.sql
-- Purpose: Validate all integrations are properly set up and identify issues

-- =============================================================================
-- VALIDATION QUERIES
-- =============================================================================

DO $$
DECLARE
    v_table_count INTEGER;
    v_function_count INTEGER;
    v_trigger_count INTEGER;
    v_policy_count INTEGER;
    v_issue_count INTEGER := 0;
    v_issues TEXT := '';
BEGIN
    RAISE NOTICE '====================================================';
    RAISE NOTICE 'Crystal Social Database Integration Validation';
    RAISE NOTICE '====================================================';
    RAISE NOTICE '';

    -- Check table count
    SELECT COUNT(*) INTO v_table_count 
    FROM information_schema.tables 
    WHERE table_schema = 'public';
    
    RAISE NOTICE 'Database Objects Summary:';
    RAISE NOTICE '- Tables: %', v_table_count;
    
    -- Check function count
    SELECT COUNT(*) INTO v_function_count 
    FROM information_schema.routines 
    WHERE routine_schema = 'public';
    
    RAISE NOTICE '- Functions: %', v_function_count;
    
    -- Check trigger count
    SELECT COUNT(*) INTO v_trigger_count 
    FROM information_schema.triggers 
    WHERE trigger_schema = 'public';
    
    RAISE NOTICE '- Triggers: %', v_trigger_count;
    
    -- Check RLS policies count
    SELECT COUNT(*) INTO v_policy_count 
    FROM pg_policies 
    WHERE schemaname = 'public';
    
    RAISE NOTICE '- RLS Policies: %', v_policy_count;
    RAISE NOTICE '';
    
    RAISE NOTICE 'Validation Results:';
    RAISE NOTICE '==================';
END $$;

-- Check 1: Missing foreign key references
DO $$
DECLARE
    missing_ref RECORD;
    issue_found BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '1. Checking for missing foreign key references...';
    
    FOR missing_ref IN
        SELECT 
            conname AS constraint_name,
            conrelid::regclass AS table_name,
            confrelid::regclass AS referenced_table
        FROM pg_constraint 
        WHERE contype = 'f' 
        AND NOT EXISTS (
            SELECT 1 FROM pg_tables 
            WHERE schemaname = 'public' 
            AND tablename = split_part(confrelid::regclass::text, '.', -1)
        )
        AND confrelid::regclass::text NOT LIKE 'auth.%'
    LOOP
        IF NOT issue_found THEN
            RAISE NOTICE '   ❌ ISSUES FOUND:';
            issue_found := TRUE;
        END IF;
        RAISE NOTICE '   - Table % references missing table %', 
            missing_ref.table_name, missing_ref.referenced_table;
    END LOOP;
    
    IF NOT issue_found THEN
        RAISE NOTICE '   ✅ No missing foreign key references found';
    END IF;
END $$;

-- Check 2: Duplicate functions
DO $$
DECLARE
    duplicate_func RECORD;
    issue_found BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '2. Checking for duplicate function definitions...';
    
    FOR duplicate_func IN
        SELECT proname AS function_name, count(*) AS count
        FROM pg_proc 
        WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
        GROUP BY proname 
        HAVING count(*) > 1
        ORDER BY proname
    LOOP
        IF NOT issue_found THEN
            RAISE NOTICE '   ❌ DUPLICATE FUNCTIONS FOUND:';
            issue_found := TRUE;
        END IF;
        RAISE NOTICE '   - Function % appears % times', 
            duplicate_func.function_name, duplicate_func.count;
    END LOOP;
    
    IF NOT issue_found THEN
        RAISE NOTICE '   ✅ No duplicate functions found';
    END IF;
END $$;

-- Check 3: Tables without RLS enabled
DO $$
DECLARE
    no_rls_table RECORD;
    issue_found BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '3. Checking for tables without Row Level Security...';
    
    FOR no_rls_table IN
        SELECT schemaname, tablename 
        FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename NOT IN (
            SELECT tablename 
            FROM pg_tables t 
            JOIN pg_class c ON c.relname = t.tablename 
            WHERE c.relrowsecurity = true
            AND t.schemaname = 'public'
        )
        AND tablename NOT IN ('activity_logs') -- Exempt utility tables
        ORDER BY tablename
    LOOP
        IF NOT issue_found THEN
            RAISE NOTICE '   ⚠️  TABLES WITHOUT RLS:';
            issue_found := TRUE;
        END IF;
        RAISE NOTICE '   - Table % does not have RLS enabled', no_rls_table.tablename;
    END LOOP;
    
    IF NOT issue_found THEN
        RAISE NOTICE '   ✅ All tables have RLS enabled';
    END IF;
END $$;

-- Check 4: Tables without updated_at triggers
DO $$
DECLARE
    no_trigger_table RECORD;
    issue_found BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '4. Checking for tables missing updated_at triggers...';
    
    FOR no_trigger_table IN
        SELECT t.tablename
        FROM pg_tables t
        WHERE t.schemaname = 'public'
        AND EXISTS (
            SELECT 1 FROM information_schema.columns c
            WHERE c.table_schema = 'public'
            AND c.table_name = t.tablename
            AND c.column_name = 'updated_at'
        )
        AND NOT EXISTS (
            SELECT 1 FROM information_schema.triggers tr
            WHERE tr.trigger_schema = 'public'
            AND tr.event_object_table = t.tablename
            AND tr.trigger_name LIKE '%updated_at%'
        )
        ORDER BY t.tablename
    LOOP
        IF NOT issue_found THEN
            RAISE NOTICE '   ⚠️  TABLES MISSING UPDATED_AT TRIGGERS:';
            issue_found := TRUE;
        END IF;
        RAISE NOTICE '   - Table % has updated_at column but no trigger', no_trigger_table.tablename;
    END LOOP;
    
    IF NOT issue_found THEN
        RAISE NOTICE '   ✅ All tables with updated_at have triggers';
    END IF;
END $$;

-- Check 5: Essential tables existence
DO $$
DECLARE
    essential_tables TEXT[] := ARRAY[
        'profiles', 'app_states', 'user_sessions', 'user_devices',
        'fronting_changes', 'error_reports', 'background_messages'
    ];
    table_name TEXT;
    issue_found BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '5. Checking for essential tables...';
    
    FOREACH table_name IN ARRAY essential_tables
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM pg_tables 
            WHERE schemaname = 'public' 
            AND tablename = table_name
        ) THEN
            IF NOT issue_found THEN
                RAISE NOTICE '   ❌ MISSING ESSENTIAL TABLES:';
                issue_found := TRUE;
            END IF;
            RAISE NOTICE '   - Table % is missing', table_name;
        END IF;
    END LOOP;
    
    IF NOT issue_found THEN
        RAISE NOTICE '   ✅ All essential tables found';
    END IF;
END $$;

-- Check 6: Essential functions existence
DO $$
DECLARE
    essential_functions TEXT[] := ARRAY[
        'update_updated_at_column', 'get_auth_user_id', 'is_admin', 
        'is_moderator', 'sanitize_input', 'log_activity'
    ];
    function_name TEXT;
    issue_found BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '6. Checking for essential functions...';
    
    FOREACH function_name IN ARRAY essential_functions
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM pg_proc p
            JOIN pg_namespace n ON p.pronamespace = n.oid
            WHERE n.nspname = 'public' 
            AND p.proname = function_name
        ) THEN
            IF NOT issue_found THEN
                RAISE NOTICE '   ❌ MISSING ESSENTIAL FUNCTIONS:';
                issue_found := TRUE;
            END IF;
            RAISE NOTICE '   - Function % is missing', function_name;
        END IF;
    END LOOP;
    
    IF NOT issue_found THEN
        RAISE NOTICE '   ✅ All essential functions found';
    END IF;
END $$;

-- Check 7: Orphaned records (records referencing non-existent profiles)
DO $$
DECLARE
    orphan_check RECORD;
    issue_found BOOLEAN := FALSE;
    check_query TEXT;
    orphan_count INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '7. Checking for orphaned records...';
    
    -- Check if profiles table exists first
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'profiles') THEN
        RAISE NOTICE '   ⚠️  Profiles table not found - skipping orphaned records check';
        RETURN;
    END IF;
    
    -- Check tables with user_id columns
    FOR orphan_check IN
        SELECT t.table_name, c.column_name
        FROM information_schema.tables t
        JOIN information_schema.columns c ON t.table_name = c.table_name
        WHERE t.table_schema = 'public'
        AND c.table_schema = 'public'
        AND c.column_name IN ('user_id', 'created_by', 'updated_by')
        AND t.table_name != 'profiles'
        ORDER BY t.table_name
    LOOP
        check_query := format('
            SELECT COUNT(*) FROM %I 
            WHERE %I IS NOT NULL 
            AND NOT EXISTS (
                SELECT 1 FROM profiles WHERE id = %I.%I
            )', 
            orphan_check.table_name, 
            orphan_check.column_name,
            orphan_check.table_name,
            orphan_check.column_name
        );
        
        EXECUTE check_query INTO orphan_count;
        
        IF orphan_count > 0 THEN
            IF NOT issue_found THEN
                RAISE NOTICE '   ⚠️  ORPHANED RECORDS FOUND:';
                issue_found := TRUE;
            END IF;
            RAISE NOTICE '   - Table %.% has % orphaned records', 
                orphan_check.table_name, orphan_check.column_name, orphan_count;
        END IF;
    END LOOP;
    
    IF NOT issue_found THEN
        RAISE NOTICE '   ✅ No orphaned records found';
    END IF;
END $$;

-- Check 8: Index coverage for foreign keys
DO $$
DECLARE
    missing_index RECORD;
    issue_found BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '8. Checking for missing indexes on foreign keys...';
    
    FOR missing_index IN
        SELECT 
            t.relname AS table_name,
            a.attname AS column_name
        FROM pg_constraint c
        JOIN pg_attribute a ON a.attnum = ANY(c.conkey) AND a.attrelid = c.conrelid
        JOIN pg_class t ON t.oid = c.conrelid
        JOIN pg_namespace n ON n.oid = t.relnamespace
        WHERE c.contype = 'f'
        AND n.nspname = 'public'
        AND NOT EXISTS (
            SELECT 1 FROM pg_index i
            WHERE i.indrelid = c.conrelid
            AND a.attnum = ANY(i.indkey)
        )
        ORDER BY t.relname, a.attname
    LOOP
        IF NOT issue_found THEN
            RAISE NOTICE '   ⚠️  FOREIGN KEYS WITHOUT INDEXES:';
            issue_found := TRUE;
        END IF;
        RAISE NOTICE '   - Table %.% needs an index', 
            missing_index.table_name, missing_index.column_name;
    END LOOP;
    
    IF NOT issue_found THEN
        RAISE NOTICE '   ✅ All foreign keys have indexes';
    END IF;
END $$;

-- Summary and recommendations
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '====================================================';
    RAISE NOTICE 'VALIDATION COMPLETE';
    RAISE NOTICE '====================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'If any issues were found above, please:';
    RAISE NOTICE '1. Review the Master Integration Guide';
    RAISE NOTICE '2. Follow the proper import order';
    RAISE NOTICE '3. Remove duplicate function definitions';
    RAISE NOTICE '4. Ensure all referenced tables exist';
    RAISE NOTICE '5. Enable RLS on all tables';
    RAISE NOTICE '';
    RAISE NOTICE 'For performance optimization:';
    RAISE NOTICE '- Add missing indexes on foreign keys';
    RAISE NOTICE '- Consider adding indexes on frequently queried columns';
    RAISE NOTICE '- Monitor query performance with EXPLAIN ANALYZE';
    RAISE NOTICE '';
END $$;

-- Performance analysis query (optional)
SELECT 
    'Performance Analysis' AS section,
    COUNT(*) AS total_tables,
    SUM(CASE WHEN reltuples > 1000 THEN 1 ELSE 0 END) AS large_tables,
    COUNT(DISTINCT indexrelid) AS total_indexes
FROM pg_class c
LEFT JOIN pg_stat_user_tables s ON c.oid = s.relid
LEFT JOIN pg_index i ON c.oid = i.indrelid
WHERE c.relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
AND c.relkind = 'r';

-- Show database size
SELECT 
    'Database Size' AS metric,
    pg_size_pretty(pg_database_size(current_database())) AS size;

-- Show largest tables
SELECT 
    'Largest Tables' AS section,
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;
