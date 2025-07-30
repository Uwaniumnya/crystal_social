-- Crystal Social Prerequisites Setup
-- File: 00_prerequisites_setup.sql
-- Purpose: Ensure all required schemas, tables, and dependencies exist before importing other SQL files
-- This file MUST be imported FIRST before any other integration files

-- =============================================================================
-- SUPABASE AUTH SCHEMA VERIFICATION
-- =============================================================================

-- Verify auth schema exists (Supabase requirement)
DO $$
BEGIN
    -- Check if auth schema exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'auth') THEN
        RAISE EXCEPTION 'AUTH SCHEMA MISSING: Supabase auth schema not found. Please ensure Supabase is properly initialized.';
    END IF;
    
    -- Check if auth.users table exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables 
                   WHERE table_schema = 'auth' AND table_name = 'users') THEN
        RAISE EXCEPTION 'AUTH.USERS TABLE MISSING: Supabase auth.users table not found. Please ensure Supabase auth is properly set up.';
    END IF;
    
    RAISE NOTICE 'AUTH SCHEMA VERIFICATION: ✓ Supabase auth schema and auth.users table found';
END $$;

-- =============================================================================
-- CORE PROFILES TABLE CREATION
-- =============================================================================

-- Create the main profiles table that all other integrations depend on
-- This consolidates user profile information in a single table
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username VARCHAR(50) UNIQUE,
    display_name VARCHAR(100),
    bio TEXT,
    avatar_url TEXT,
    avatar_decoration VARCHAR(100),
    location VARCHAR(100),
    website VARCHAR(255),
    zodiac_sign VARCHAR(20),
    interests TEXT[], -- Array of interests
    social_links JSONB DEFAULT '{}'::jsonb, -- {twitter, instagram, etc.}
    profile_theme VARCHAR(50) DEFAULT 'default',
    
    -- Privacy and verification
    is_private BOOLEAN DEFAULT false,
    is_verified BOOLEAN DEFAULT false,
    
    -- Admin and moderation (required by other integrations)
    is_admin BOOLEAN DEFAULT false,
    is_moderator BOOLEAN DEFAULT false,
    admin_notes TEXT,
    last_admin_action TIMESTAMP WITH TIME ZONE,
    
    -- Statistics and engagement
    reputation_score INTEGER DEFAULT 0,
    profile_completion_percentage DECIMAL(5,2) DEFAULT 0.0,
    total_messages_sent INTEGER DEFAULT 0,
    total_reactions_given INTEGER DEFAULT 0,
    total_reactions_received INTEGER DEFAULT 0,
    
    -- Timestamps
    last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT username_length CHECK (LENGTH(username) >= 3),
    CONSTRAINT bio_length CHECK (LENGTH(bio) <= 500),
    CONSTRAINT website_format CHECK (website IS NULL OR website ~* '^https?://'),
    CONSTRAINT interests_limit CHECK (array_length(interests, 1) <= 20)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles(username);
CREATE INDEX IF NOT EXISTS idx_profiles_is_admin ON profiles(is_admin) WHERE is_admin = true;
CREATE INDEX IF NOT EXISTS idx_profiles_is_moderator ON profiles(is_moderator) WHERE is_moderator = true;
CREATE INDEX IF NOT EXISTS idx_profiles_last_active ON profiles(last_active_at);
CREATE INDEX IF NOT EXISTS idx_profiles_created_at ON profiles(created_at);
CREATE INDEX IF NOT EXISTS idx_profiles_reputation ON profiles(reputation_score);

-- =============================================================================
-- AUTO-PROFILE CREATION FUNCTION
-- =============================================================================

-- Function to automatically create profile when user signs up
CREATE OR REPLACE FUNCTION create_profile_for_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO profiles (id, username, display_name, created_at, updated_at)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substring(NEW.id::text, 1, 8)),
        COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email),
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$;

-- Create trigger for auto-profile creation
DROP TRIGGER IF EXISTS create_profile_trigger ON auth.users;
CREATE TRIGGER create_profile_trigger
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION create_profile_for_new_user();

-- =============================================================================
-- PROFILE VALIDATION AND CLEANUP
-- =============================================================================

-- Function to validate profile data
CREATE OR REPLACE FUNCTION validate_profile_data()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Ensure username is provided
    IF NEW.username IS NULL OR LENGTH(trim(NEW.username)) < 3 THEN
        NEW.username := 'user_' || substring(NEW.id::text, 1, 8);
    END IF;
    
    -- Sanitize username (alphanumeric and underscores only)
    NEW.username := regexp_replace(lower(NEW.username), '[^a-z0-9_]', '', 'g');
    
    -- Ensure display name
    IF NEW.display_name IS NULL OR LENGTH(trim(NEW.display_name)) = 0 THEN
        NEW.display_name := NEW.username;
    END IF;
    
    -- Update timestamp
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$;

-- Create validation trigger
DROP TRIGGER IF EXISTS validate_profile_trigger ON profiles;
CREATE TRIGGER validate_profile_trigger
    BEFORE INSERT OR UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION validate_profile_data();

-- =============================================================================
-- ROW LEVEL SECURITY SETUP
-- =============================================================================

-- Enable RLS on profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view public profiles or their own profile
CREATE POLICY "Users can view profiles" ON profiles
    FOR SELECT USING (
        is_private = false OR id = auth.uid()
    );

-- Policy: Users can only update their own profile
CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

-- Policy: Users can insert their own profile
CREATE POLICY "Users can create own profile" ON profiles
    FOR INSERT WITH CHECK (id = auth.uid());

-- Policy: Admins can view and modify all profiles
CREATE POLICY "Admins can manage all profiles" ON profiles
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles admin_profile
            WHERE admin_profile.id = auth.uid()
            AND admin_profile.is_admin = true
        )
    );

-- =============================================================================
-- ESSENTIAL SYSTEM TABLES
-- =============================================================================

-- Create system configuration table
CREATE TABLE IF NOT EXISTS system_config (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create notification preferences table (commonly referenced)
CREATE TABLE IF NOT EXISTS user_notification_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    email_notifications BOOLEAN DEFAULT true,
    push_notifications BOOLEAN DEFAULT true,
    in_app_notifications BOOLEAN DEFAULT true,
    marketing_emails BOOLEAN DEFAULT false,
    notification_settings JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id)
);

-- Create basic user settings table
CREATE TABLE IF NOT EXISTS user_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    theme VARCHAR(20) DEFAULT 'default',
    language VARCHAR(10) DEFAULT 'en',
    timezone VARCHAR(50) DEFAULT 'UTC',
    privacy_level VARCHAR(20) DEFAULT 'public',
    settings_data JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id)
);

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_system_config_key ON system_config(key);
CREATE INDEX IF NOT EXISTS idx_user_notification_preferences_user_id ON user_notification_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_user_settings_user_id ON user_settings(user_id);

-- =============================================================================
-- ROW LEVEL SECURITY FOR SUPPORTING TABLES
-- =============================================================================

-- RLS for notification preferences
ALTER TABLE user_notification_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own notification preferences" ON user_notification_preferences
    FOR ALL USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- RLS for user settings
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own settings" ON user_settings
    FOR ALL USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- RLS for system config (read-only for authenticated users)
ALTER TABLE system_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read system config" ON system_config
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Admins can manage system config" ON system_config
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND is_admin = true
        )
    );

-- =============================================================================
-- PERMISSIONS GRANTS
-- =============================================================================

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated, anon;
GRANT ALL ON profiles TO authenticated;
GRANT ALL ON user_notification_preferences TO authenticated;
GRANT ALL ON user_settings TO authenticated;
GRANT SELECT ON system_config TO authenticated;
GRANT ALL ON system_config TO service_role;

-- Grant sequence permissions
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- =============================================================================
-- INITIAL SYSTEM CONFIGURATION
-- =============================================================================

-- Insert default system configuration
INSERT INTO system_config (key, value, description) VALUES
    ('app_version', '"1.0.0"', 'Current application version'),
    ('maintenance_mode', 'false', 'Whether the app is in maintenance mode'),
    ('max_profile_bio_length', '500', 'Maximum length for profile bio'),
    ('max_username_length', '50', 'Maximum length for username'),
    ('default_theme', '"default"', 'Default theme for new users'),
    ('features_enabled', '{"chat": true, "groups": true, "rewards": true}', 'Enabled features'),
    ('rate_limits', '{"messages": 100, "profile_updates": 10}', 'Rate limiting configuration')
ON CONFLICT (key) DO NOTHING;

-- =============================================================================
-- VERIFICATION AND COMPLETION
-- =============================================================================

-- Verification function to check all prerequisites
CREATE OR REPLACE FUNCTION verify_prerequisites()
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    missing_items TEXT[] := ARRAY[]::TEXT[];
BEGIN
    -- Check auth schema
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'auth') THEN
        missing_items := array_append(missing_items, 'auth schema');
    END IF;
    
    -- Check auth.users table
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
        missing_items := array_append(missing_items, 'auth.users table');
    END IF;
    
    -- Check profiles table
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles') THEN
        missing_items := array_append(missing_items, 'profiles table');
    END IF;
    
    -- Check essential functions exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'update_updated_at_column') THEN
        missing_items := array_append(missing_items, 'update_updated_at_column function');
    END IF;
    
    -- Report results
    IF array_length(missing_items, 1) > 0 THEN
        RAISE NOTICE 'MISSING PREREQUISITES: %', array_to_string(missing_items, ', ');
        RETURN false;
    ELSE
        RAISE NOTICE 'PREREQUISITES VERIFICATION: ✓ All prerequisites are satisfied';
        RETURN true;
    END IF;
END;
$$;

-- Run verification
SELECT verify_prerequisites();

-- Final completion message
DO $$
BEGIN
    RAISE NOTICE '====================================================';
    RAISE NOTICE 'CRYSTAL SOCIAL PREREQUISITES SETUP COMPLETE!';
    RAISE NOTICE '====================================================';
    RAISE NOTICE '✓ Supabase auth schema verified';
    RAISE NOTICE '✓ Core profiles table created';
    RAISE NOTICE '✓ Auto-profile creation trigger installed';
    RAISE NOTICE '✓ Row Level Security policies configured';
    RAISE NOTICE '✓ Essential system tables created';
    RAISE NOTICE '✓ Default system configuration loaded';
    RAISE NOTICE '';
    RAISE NOTICE 'Ready to import shared utilities and other integration files!';
    RAISE NOTICE 'Next step: Import 00_shared_utilities.sql';
    RAISE NOTICE '====================================================';
END $$;
