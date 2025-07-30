-- Crystal Social Profile-Dependent Utilities
-- File: 01_profile_dependent_utilities.sql
-- Purpose: Utility functions that depend on the profiles table
-- This file MUST be imported AFTER the profiles table is created

-- =============================================================================
-- PROFILE-DEPENDENT UTILITY FUNCTIONS
-- =============================================================================

-- Function to check if profile exists
CREATE OR REPLACE FUNCTION profile_exists(user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = user_id
    );
$$;

-- Function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin(user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = user_id 
        AND is_admin = true
    );
$$;

-- Function to check if user is moderator
CREATE OR REPLACE FUNCTION is_moderator(user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = user_id 
        AND (is_moderator = true OR is_admin = true)
    );
$$;

-- Function to check if user is admin or moderator
CREATE OR REPLACE FUNCTION is_admin_or_moderator(user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = user_id 
        AND (is_admin = true OR is_moderator = true)
    );
$$;

-- Function to get user's current role
CREATE OR REPLACE FUNCTION get_user_role(user_id UUID)
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT CASE 
        WHEN is_admin = true THEN 'admin'
        WHEN is_moderator = true THEN 'moderator'
        ELSE 'user'
    END
    FROM profiles 
    WHERE id = user_id;
$$;

-- =============================================================================
-- PERMISSIONS AND GRANTS
-- =============================================================================

-- Grant execute permissions to authenticated users for profile-dependent functions
GRANT EXECUTE ON FUNCTION profile_exists(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION is_admin(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION is_moderator(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION is_admin_or_moderator(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_role(UUID) TO authenticated;

-- Grant additional permissions to service role
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO service_role;

-- =============================================================================
-- PROFILE-DEPENDENT RLS POLICIES
-- =============================================================================

-- Add admin policy for activity logs (requires profiles table)
CREATE POLICY "Admins can view all activity logs" ON activity_logs
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND is_admin = true
        )
    );

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON FUNCTION profile_exists IS 'Checks if a profile exists for the given user ID';
COMMENT ON FUNCTION is_admin IS 'Checks if user has admin privileges';
COMMENT ON FUNCTION is_moderator IS 'Checks if user has moderator or admin privileges';
COMMENT ON FUNCTION is_admin_or_moderator IS 'Checks if user has admin or moderator privileges';
COMMENT ON FUNCTION get_user_role IS 'Returns the role of the user (admin, moderator, or user)';

-- Setup completion message
DO $$
BEGIN
    RAISE NOTICE 'Crystal Social Profile-Dependent Utilities Setup Complete!';
    RAISE NOTICE 'Profile-dependent functions are now available.';
END $$;
