-- =====================================================
-- NOTES SYSTEM IMPORT TEST
-- =====================================================
-- This script tests if all notes SQL files can be imported
-- without syntax errors in PostgreSQL

-- Create test database schema
CREATE SCHEMA IF NOT EXISTS notes_test;
SET search_path TO notes_test, public;

-- Create minimal auth.users table for testing (simulating Supabase auth)
CREATE TABLE IF NOT EXISTS auth.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Test importing all notes files in order
\echo 'Testing 01_notes_tables.sql...'
\i 01_notes_tables.sql

\echo 'Testing 02_notes_functions.sql...'
\i 02_notes_functions.sql

\echo 'Testing 03_notes_triggers.sql...'
\i 03_notes_triggers.sql

\echo 'Testing 04_notes_security.sql...'
\i 04_notes_security.sql

\echo 'Testing 05_notes_views.sql...'
\i 05_notes_views.sql

\echo 'Testing 06_notes_setup.sql...'
\i 06_notes_setup.sql

\echo 'All notes SQL files imported successfully!'

-- Clean up test schema
DROP SCHEMA notes_test CASCADE;
