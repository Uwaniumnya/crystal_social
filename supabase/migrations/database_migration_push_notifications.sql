-- Database Schema for Enhanced Push Notification System
-- This script creates the necessary tables for device registration and notification tracking

-- Table to track all devices where users have ever logged in
CREATE TABLE IF NOT EXISTS user_devices (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id TEXT NOT NULL,
    fcm_token TEXT NOT NULL,
    device_info JSONB,
    is_active BOOLEAN DEFAULT true,
    first_login TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_active TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure one record per user-device combination
    UNIQUE(user_id, device_id)
);

-- Table to log all notifications sent
CREATE TABLE IF NOT EXISTS notification_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    receiver_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    sender_username TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    device_count INTEGER DEFAULT 0,
    success_count INTEGER DEFAULT 0,
    notification_data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_devices_user_id ON user_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_device_id ON user_devices(device_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_active ON user_devices(is_active);
CREATE INDEX IF NOT EXISTS idx_user_devices_last_active ON user_devices(last_active);
CREATE INDEX IF NOT EXISTS idx_notification_logs_receiver ON notification_logs(receiver_user_id);
CREATE INDEX IF NOT EXISTS idx_notification_logs_created_at ON notification_logs(created_at);

-- Row Level Security (RLS) Policies
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_logs ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own device registrations
CREATE POLICY "Users can view their own devices" ON user_devices
    FOR SELECT USING (auth.uid() = user_id);

-- Policy: Users can insert their own device registrations
CREATE POLICY "Users can register their own devices" ON user_devices
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own device registrations
CREATE POLICY "Users can update their own devices" ON user_devices
    FOR UPDATE USING (auth.uid() = user_id);

-- Policy: Users can delete their own device registrations
CREATE POLICY "Users can delete their own devices" ON user_devices
    FOR DELETE USING (auth.uid() = user_id);

-- Policy: Users can view their notification history
CREATE POLICY "Users can view their notification logs" ON notification_logs
    FOR SELECT USING (auth.uid() = receiver_user_id);

-- Policy: Allow service to insert notification logs (admin role)
CREATE POLICY "Service can insert notification logs" ON notification_logs
    FOR INSERT WITH CHECK (true);

-- Function to automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at on user_devices
CREATE TRIGGER update_user_devices_updated_at 
    BEFORE UPDATE ON user_devices 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Function to clean up old devices (older than 90 days)
CREATE OR REPLACE FUNCTION cleanup_old_devices()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM user_devices 
    WHERE last_active < NOW() - INTERVAL '90 days'
    AND is_active = false;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Function to get all FCM tokens for a user
CREATE OR REPLACE FUNCTION get_user_fcm_tokens(target_user_id UUID)
RETURNS TABLE(fcm_token TEXT, device_info JSONB) AS $$
BEGIN
    RETURN QUERY
    SELECT ud.fcm_token, ud.device_info
    FROM user_devices ud
    WHERE ud.user_id = target_user_id 
    AND ud.is_active = true
    AND ud.fcm_token IS NOT NULL;
END;
$$ LANGUAGE plpgsql;

-- Function to deactivate all devices for a user (for logout)
CREATE OR REPLACE FUNCTION deactivate_user_devices(target_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    updated_count INTEGER;
BEGIN
    UPDATE user_devices 
    SET is_active = false, 
        last_active = NOW(),
        updated_at = NOW()
    WHERE user_id = target_user_id;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RETURN updated_count;
END;
$$ LANGUAGE plpgsql;

-- Function to get notification statistics
CREATE OR REPLACE FUNCTION get_notification_stats(target_user_id UUID)
RETURNS TABLE(
    total_notifications BIGINT,
    total_devices_reached BIGINT,
    total_successful_sends BIGINT,
    last_notification TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_notifications,
        SUM(nl.device_count) as total_devices_reached,
        SUM(nl.success_count) as total_successful_sends,
        MAX(nl.created_at) as last_notification
    FROM notification_logs nl
    WHERE nl.receiver_user_id = target_user_id;
END;
$$ LANGUAGE plpgsql;

-- Sample data for testing (uncomment to use)
/*
-- Insert sample device registrations
INSERT INTO user_devices (user_id, device_id, fcm_token, device_info, is_active) VALUES
('00000000-0000-0000-0000-000000000001', 'device_test_001', 'fcm_token_sample_001', '{"platform": "Android", "model": "Test Device"}', true),
('00000000-0000-0000-0000-000000000002', 'device_test_002', 'fcm_token_sample_002', '{"platform": "iOS", "model": "Test iPhone"}', true);

-- Insert sample notification logs
INSERT INTO notification_logs (receiver_user_id, sender_username, title, body, device_count, success_count) VALUES
('00000000-0000-0000-0000-000000000001', 'TestUser', 'TestUser', 'You have a message from TestSender', 1, 1),
('00000000-0000-0000-0000-000000000002', 'TestUser2', 'TestUser2', 'You have a message from TestSender2', 1, 1);
*/

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON user_devices TO authenticated;
GRANT SELECT, INSERT ON notification_logs TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_fcm_tokens TO authenticated;
GRANT EXECUTE ON FUNCTION deactivate_user_devices TO authenticated;
GRANT EXECUTE ON FUNCTION get_notification_stats TO authenticated;

-- Create a scheduled job to clean up old devices (run weekly)
-- Note: This requires the pg_cron extension to be enabled
/*
SELECT cron.schedule(
    'cleanup-old-devices',
    '0 2 * * 0',  -- Every Sunday at 2 AM
    'SELECT cleanup_old_devices();'
);
*/

-- Verification queries to test the setup
-- Uncomment these to verify everything is working:

/*
-- Check if tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('user_devices', 'notification_logs');

-- Check if functions exist
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('get_user_fcm_tokens', 'deactivate_user_devices', 'get_notification_stats', 'cleanup_old_devices');

-- Test device registration (replace with real user ID)
-- SELECT * FROM user_devices WHERE user_id = 'your-user-id-here';

-- Test notification logs (replace with real user ID)
-- SELECT * FROM notification_logs WHERE receiver_user_id = 'your-user-id-here';
*/
