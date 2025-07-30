-- Crystal Social Shared Utilities
-- File: 00_shared_utilities.sql
-- Purpose: Common utility functions used across all integrations
-- This file MUST be imported first to avoid function duplication issues

-- =============================================================================
-- COMMON UTILITY FUNCTIONS
-- =============================================================================

-- Function to automatically update updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER 
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- Function to generate UUID v4 (alternative to gen_random_uuid)
CREATE OR REPLACE FUNCTION generate_uuid_v4()
RETURNS UUID
LANGUAGE sql
AS $$
    SELECT gen_random_uuid();
$$;

-- Function to safely get user ID from auth context
CREATE OR REPLACE FUNCTION get_auth_user_id()
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT auth.uid();
$$;

-- Function to check if user exists
CREATE OR REPLACE FUNCTION user_exists(user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = user_id
    );
$$;

-- =============================================================================
-- ACTIVITY LOGS TABLE (required by functions below)
-- =============================================================================

-- Create activity logs table if it doesn't exist
CREATE TABLE IF NOT EXISTS activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    activity_type TEXT NOT NULL,
    activity_details JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_activity_logs_user_id ON activity_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_type ON activity_logs(activity_type);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created_at ON activity_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_activity_logs_user_type_time ON activity_logs(user_id, activity_type, created_at);

-- Enable RLS
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

-- RLS policies for activity logs
CREATE POLICY "Users can view own activity logs" ON activity_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can insert activity logs" ON activity_logs
    FOR INSERT WITH CHECK (true);

-- Note: Admin policy for activity logs will be created after profiles table exists
-- See: 01_profile_dependent_utilities.sql

-- =============================================================================
-- DEFERRED PROFILE-DEPENDENT FUNCTIONS
-- These functions will be created later after profiles table exists
-- =============================================================================

-- Note: Profile-dependent functions are defined in a separate file
-- that should be imported after the profiles table is created.
-- See: 01_profile_dependent_utilities.sql (to be created after profiles table)

-- Function to validate email format
CREATE OR REPLACE FUNCTION is_valid_email(email_address TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN email_address ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';
END;
$$;

-- Function to slugify text (convert to URL-friendly format)
CREATE OR REPLACE FUNCTION slugify(input_text TEXT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN lower(
        regexp_replace(
            regexp_replace(
                regexp_replace(input_text, '[^a-zA-Z0-9\-_\s]', '', 'g'),
                '\s+', '-', 'g'
            ),
            '-+', '-', 'g'
        )
    );
END;
$$;

-- Function to truncate text to specified length
CREATE OR REPLACE FUNCTION truncate_text(input_text TEXT, max_length INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
    IF length(input_text) <= max_length THEN
        RETURN input_text;
    ELSE
        RETURN left(input_text, max_length - 3) || '...';
    END IF;
END;
$$;

-- Function to generate random string
CREATE OR REPLACE FUNCTION generate_random_string(length INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    result TEXT := '';
    i INTEGER;
BEGIN
    FOR i IN 1..length LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::INTEGER, 1);
    END LOOP;
    RETURN result;
END;
$$;

-- Function to calculate age from birthdate
CREATE OR REPLACE FUNCTION calculate_age(birth_date DATE)
RETURNS INTEGER
LANGUAGE sql
AS $$
    SELECT DATE_PART('year', AGE(birth_date))::INTEGER;
$$;

-- Function to format timestamp for display
CREATE OR REPLACE FUNCTION format_timestamp(ts TIMESTAMP WITH TIME ZONE)
RETURNS TEXT
LANGUAGE sql
AS $$
    SELECT to_char(ts, 'YYYY-MM-DD HH24:MI:SS TZ');
$$;

-- Function to get time ago string
CREATE OR REPLACE FUNCTION time_ago(ts TIMESTAMP WITH TIME ZONE)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    interval_text TEXT;
    seconds INTEGER;
    minutes INTEGER;
    hours INTEGER;
    days INTEGER;
BEGIN
    seconds := EXTRACT(EPOCH FROM (NOW() - ts))::INTEGER;
    
    IF seconds < 60 THEN
        RETURN seconds || ' seconds ago';
    ELSIF seconds < 3600 THEN
        minutes := seconds / 60;
        RETURN minutes || ' minutes ago';
    ELSIF seconds < 86400 THEN
        hours := seconds / 3600;
        RETURN hours || ' hours ago';
    ELSE
        days := seconds / 86400;
        RETURN days || ' days ago';
    END IF;
END;
$$;

-- Function to sanitize user input
CREATE OR REPLACE FUNCTION sanitize_input(input_text TEXT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
    -- Remove null bytes and control characters
    RETURN regexp_replace(
        regexp_replace(input_text, E'[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F\\x7F]', '', 'g'),
        E'[\\x80-\\x9F]', '', 'g'
    );
END;
$$;

-- Function to validate JSON structure
CREATE OR REPLACE FUNCTION is_valid_json(json_text TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    BEGIN
        PERFORM json_text::JSONB;
        RETURN TRUE;
    EXCEPTION WHEN OTHERS THEN
        RETURN FALSE;
    END;
END;
$$;

-- Function to merge JSONB objects safely
CREATE OR REPLACE FUNCTION merge_jsonb(base_json JSONB, overlay_json JSONB)
RETURNS JSONB
LANGUAGE sql
AS $$
    SELECT COALESCE(base_json, '{}'::JSONB) || COALESCE(overlay_json, '{}'::JSONB);
$$;

-- Function to log activity
CREATE OR REPLACE FUNCTION log_activity(
    user_id UUID,
    activity_type TEXT,
    activity_details JSONB DEFAULT NULL,
    ip_address INET DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO activity_logs (user_id, activity_type, activity_details, ip_address, created_at)
    VALUES (user_id, activity_type, activity_details, ip_address, NOW())
    ON CONFLICT DO NOTHING;
EXCEPTION WHEN OTHERS THEN
    -- Silently ignore logging errors to not affect main functionality
    NULL;
END;
$$;

-- Function to rate limit actions
CREATE OR REPLACE FUNCTION check_rate_limit(
    user_id UUID,
    action_type TEXT,
    limit_count INTEGER,
    time_window INTERVAL
)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT COUNT(*) < limit_count
    FROM activity_logs
    WHERE user_id = $1
    AND activity_type = $2
    AND created_at > NOW() - $4;
$$;

-- =============================================================================
-- SECURITY HELPER FUNCTIONS
-- =============================================================================

-- Function to hash sensitive data
CREATE OR REPLACE FUNCTION hash_sensitive_data(input_data TEXT, salt TEXT DEFAULT '')
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN encode(digest(input_data || salt, 'sha256'), 'hex');
END;
$$;

-- Function to generate secure token
CREATE OR REPLACE FUNCTION generate_secure_token(length INTEGER DEFAULT 32)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN encode(gen_random_bytes(length), 'hex');
END;
$$;

-- Function to validate password strength
CREATE OR REPLACE FUNCTION is_strong_password(password TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN length(password) >= 8
        AND password ~ '[A-Z]'  -- Has uppercase
        AND password ~ '[a-z]'  -- Has lowercase  
        AND password ~ '[0-9]'  -- Has number
        AND password ~ '[^A-Za-z0-9]'; -- Has special character
END;
$$;

-- =============================================================================
-- DATA VALIDATION FUNCTIONS
-- =============================================================================

-- Function to validate UUID format
CREATE OR REPLACE FUNCTION is_valid_uuid(uuid_text TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    BEGIN
        PERFORM uuid_text::UUID;
        RETURN TRUE;
    EXCEPTION WHEN OTHERS THEN
        RETURN FALSE;
    END;
END;
$$;

-- Function to validate phone number (basic)
CREATE OR REPLACE FUNCTION is_valid_phone(phone_number TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    -- Basic phone validation - at least 10 digits
    RETURN phone_number ~ '^[\+]?[0-9\-\(\)\s]{10,}$';
END;
$$;

-- Function to validate URL format
CREATE OR REPLACE FUNCTION is_valid_url(url_text TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN url_text ~* '^https?://[^\s/$.?#].[^\s]*$';
END;
$$;

-- =============================================================================
-- MATHEMATICAL HELPER FUNCTIONS
-- =============================================================================

-- Function to calculate percentage
CREATE OR REPLACE FUNCTION calculate_percentage(part NUMERIC, total NUMERIC)
RETURNS NUMERIC
LANGUAGE sql
AS $$
    SELECT CASE 
        WHEN total = 0 THEN 0 
        ELSE ROUND((part / total) * 100, 2) 
    END;
$$;

-- Function to calculate average rating
CREATE OR REPLACE FUNCTION calculate_average_rating(total_points NUMERIC, total_ratings INTEGER)
RETURNS NUMERIC
LANGUAGE sql
AS $$
    SELECT CASE 
        WHEN total_ratings = 0 THEN 0 
        ELSE ROUND(total_points / total_ratings, 2) 
    END;
$$;

-- =============================================================================
-- PERMISSIONS AND GRANTS
-- =============================================================================

-- Grant execute permissions to authenticated users for all utility functions
GRANT EXECUTE ON FUNCTION update_updated_at_column() TO authenticated;
GRANT EXECUTE ON FUNCTION generate_uuid_v4() TO authenticated;
GRANT EXECUTE ON FUNCTION get_auth_user_id() TO authenticated;
GRANT EXECUTE ON FUNCTION user_exists(UUID) TO authenticated;
-- Note: Profile-dependent function grants will be in 01_profile_dependent_utilities.sql
GRANT EXECUTE ON FUNCTION is_valid_email(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION slugify(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION truncate_text(TEXT, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION generate_random_string(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_age(DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION format_timestamp(TIMESTAMP WITH TIME ZONE) TO authenticated;
GRANT EXECUTE ON FUNCTION time_ago(TIMESTAMP WITH TIME ZONE) TO authenticated;
GRANT EXECUTE ON FUNCTION sanitize_input(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION is_valid_json(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION merge_jsonb(JSONB, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION log_activity(UUID, TEXT, JSONB, INET) TO authenticated;
GRANT EXECUTE ON FUNCTION check_rate_limit(UUID, TEXT, INTEGER, INTERVAL) TO authenticated;
GRANT EXECUTE ON FUNCTION hash_sensitive_data(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION generate_secure_token(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION is_strong_password(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION is_valid_uuid(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION is_valid_phone(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION is_valid_url(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_percentage(NUMERIC, NUMERIC) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_average_rating(NUMERIC, INTEGER) TO authenticated;

-- Grant additional permissions to service role for system functions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO service_role;

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON FUNCTION update_updated_at_column IS 'Automatically updates updated_at timestamp on row changes';
COMMENT ON FUNCTION get_auth_user_id IS 'Safely retrieves current authenticated user ID';
COMMENT ON FUNCTION user_exists IS 'Checks if user exists in auth.users table';
COMMENT ON FUNCTION is_valid_email IS 'Validates email format using regex pattern';
COMMENT ON FUNCTION slugify IS 'Converts text to URL-friendly slug format';
COMMENT ON FUNCTION truncate_text IS 'Truncates text to specified length with ellipsis';
COMMENT ON FUNCTION generate_random_string IS 'Generates random alphanumeric string of specified length';
COMMENT ON FUNCTION calculate_age IS 'Calculates age in years from birth date';
COMMENT ON FUNCTION format_timestamp IS 'Formats timestamp for display';
COMMENT ON FUNCTION time_ago IS 'Returns human-readable time difference string';
COMMENT ON FUNCTION sanitize_input IS 'Removes potentially harmful characters from user input';
COMMENT ON FUNCTION is_valid_json IS 'Validates if text is valid JSON format';
COMMENT ON FUNCTION merge_jsonb IS 'Safely merges two JSONB objects';
COMMENT ON FUNCTION log_activity IS 'Logs user activity for audit and analytics';
COMMENT ON FUNCTION check_rate_limit IS 'Validates action frequency against rate limits';
COMMENT ON FUNCTION hash_sensitive_data IS 'Hashes sensitive data with optional salt';
COMMENT ON FUNCTION generate_secure_token IS 'Generates cryptographically secure random token';
COMMENT ON FUNCTION is_strong_password IS 'Validates password strength requirements';
COMMENT ON FUNCTION is_valid_uuid IS 'Validates UUID format';
COMMENT ON FUNCTION is_valid_phone IS 'Validates phone number format';
COMMENT ON FUNCTION is_valid_url IS 'Validates URL format';
COMMENT ON FUNCTION calculate_percentage IS 'Calculates percentage with division by zero protection';
COMMENT ON FUNCTION calculate_average_rating IS 'Calculates average rating with division by zero protection';

-- Note: Comments for profile-dependent functions (is_admin, is_moderator, etc.) 
-- are in 01_profile_dependent_utilities.sql

-- Setup completion message
DO $$
BEGIN
    RAISE NOTICE 'Crystal Social Shared Utilities Setup Complete!';
    RAISE NOTICE 'All common functions are now available for use across integrations.';
    RAISE NOTICE 'Import this file FIRST before any other integration files.';
END $$;
