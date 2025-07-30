-- Crystal Social Prerequisites Verification
-- File: verify_prerequisites.sql
-- Purpose: Quick verification script to check if all prerequisites are met
-- Run this before importing any integration files

-- =============================================================================
-- PREREQUISITE VERIFICATION SCRIPT
-- =============================================================================

\echo '======================================================'
\echo 'CRYSTAL SOCIAL PREREQUISITES VERIFICATION'
\echo '======================================================'

-- Check 1: Supabase Auth Schema
\echo 'Checking Supabase Auth Schema...'
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'auth') THEN
        RAISE EXCEPTION '❌ MISSING: Supabase auth schema not found';
    ELSE
        RAISE NOTICE '✓ FOUND: Supabase auth schema exists';
    END IF;
END $$;

-- Check 2: auth.users table
\echo 'Checking auth.users table...'
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables 
                   WHERE table_schema = 'auth' AND table_name = 'users') THEN
        RAISE EXCEPTION '❌ MISSING: auth.users table not found';
    ELSE
        RAISE NOTICE '✓ FOUND: auth.users table exists';
    END IF;
END $$;

-- Check 3: profiles table
\echo 'Checking profiles table...'
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables 
                   WHERE table_schema = 'public' AND table_name = 'profiles') THEN
        RAISE NOTICE '❌ MISSING: profiles table not found (will be created by prerequisites)';
    ELSE
        RAISE NOTICE '✓ FOUND: profiles table exists';
    END IF;
END $$;

-- Check 4: Common utility functions
\echo 'Checking for utility functions...'
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.routines 
                   WHERE routine_name = 'update_updated_at_column') THEN
        RAISE NOTICE '❌ MISSING: update_updated_at_column function not found (will be created by shared utilities)';
    ELSE
        RAISE NOTICE '✓ FOUND: update_updated_at_column function exists';
    END IF;
END $$;

-- Check 5: activity_logs table (required by shared utilities)
\echo 'Checking activity_logs table...'
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables 
                   WHERE table_schema = 'public' AND table_name = 'activity_logs') THEN
        RAISE NOTICE '❌ MISSING: activity_logs table not found (will be created by shared utilities)';
    ELSE
        RAISE NOTICE '✓ FOUND: activity_logs table exists';
    END IF;
END $$;

-- Summary and recommendations
\echo ''
\echo '======================================================'
\echo 'VERIFICATION COMPLETE'
\echo '======================================================'

DO $$
DECLARE
    auth_schema_exists BOOLEAN;
    auth_users_exists BOOLEAN;
    profiles_exists BOOLEAN;
    function_exists BOOLEAN;
    logs_exists BOOLEAN;
    all_ready BOOLEAN := true;
BEGIN
    -- Check all prerequisites
    SELECT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'auth') INTO auth_schema_exists;
    SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') INTO auth_users_exists;
    SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles') INTO profiles_exists;
    SELECT EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'update_updated_at_column') INTO function_exists;
    SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'activity_logs') INTO logs_exists;
    
    \echo 'PREREQUISITE STATUS:'
    
    IF NOT auth_schema_exists OR NOT auth_users_exists THEN
        all_ready := false;
        \echo '❌ CRITICAL: Supabase not properly initialized'
        \echo '   Action: Initialize Supabase project and auth system'
    END IF;
    
    IF NOT profiles_exists THEN
        all_ready := false;
        \echo '⚠️  MISSING: Core profiles table'
        \echo '   Action: Run 00_prerequisites_setup.sql'
    END IF;
    
    IF NOT function_exists OR NOT logs_exists THEN
        all_ready := false;
        \echo '⚠️  MISSING: Shared utility functions/tables'
        \echo '   Action: Run 00_shared_utilities.sql after prerequisites'
    END IF;
    
    IF all_ready THEN
        \echo '🎉 SUCCESS: All prerequisites are satisfied!';
        \echo '   Ready to import integration files in sequence.';
    ELSE
        \echo '';
        \echo 'RECOMMENDED IMPORT ORDER:';
        \echo '1. \\i 00_prerequisites_setup.sql     (if profiles missing)';
        \echo '2. \\i 00_shared_utilities.sql        (if utilities missing)';
        \echo '3. \\i 01_profile_dependent_utilities.sql';
        \echo '4. Continue with remaining integration files...';
    END IF;
END $$;

\echo '======================================================'
