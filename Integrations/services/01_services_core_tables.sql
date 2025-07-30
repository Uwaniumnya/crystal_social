-- Crystal Social Services System - Core Tables and Infrastructure
-- File: 01_services_core_tables.sql
-- Purpose: Foundation tables for the comprehensive services system

-- =============================================================================
-- SERVICES CORE INFRASTRUCTURE
-- =============================================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- =============================================================================
-- DEVICE REGISTRATION TABLES
-- =============================================================================

-- User devices table for push notification management
CREATE TABLE IF NOT EXISTS user_devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id VARCHAR(255) NOT NULL,
    fcm_token TEXT,
    device_info JSONB DEFAULT '{}',
    platform VARCHAR(50), -- 'ios', 'android', 'web'
    app_version VARCHAR(50),
    os_version VARCHAR(100),
    device_model VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    first_login TIMESTAMPTZ DEFAULT NOW(),
    last_active TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(user_id, device_id),
    CHECK (platform IN ('ios', 'android', 'web', 'desktop'))
);

-- Device user tracking for auto-logout functionality
CREATE TABLE IF NOT EXISTS device_user_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_identifier VARCHAR(255) NOT NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    is_current_user BOOLEAN DEFAULT false,
    is_first_user BOOLEAN DEFAULT false,
    login_count INTEGER DEFAULT 1,
    first_login TIMESTAMPTZ DEFAULT NOW(),
    last_login TIMESTAMPTZ DEFAULT NOW(),
    last_logout TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(device_identifier, user_id)
);

-- =============================================================================
-- PUSH NOTIFICATION TABLES
-- =============================================================================

-- Notification types and categories
CREATE TABLE IF NOT EXISTS notification_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(200) NOT NULL,
    description TEXT,
    icon_name VARCHAR(100),
    is_enabled BOOLEAN DEFAULT true,
    priority_level INTEGER DEFAULT 1, -- 1=low, 2=medium, 3=high, 4=urgent
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notification templates for consistent messaging
CREATE TABLE IF NOT EXISTS notification_templates (
    id SERIAL PRIMARY KEY,
    type_id INTEGER REFERENCES notification_types(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    title_template TEXT NOT NULL,
    body_template TEXT NOT NULL,
    data_schema JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notification logs for tracking and analytics
CREATE TABLE IF NOT EXISTS notification_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    receiver_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    sender_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    notification_type_id INTEGER REFERENCES notification_types(id),
    title VARCHAR(500) NOT NULL,
    body TEXT NOT NULL,
    data JSONB DEFAULT '{}',
    
    -- Delivery tracking
    devices_targeted INTEGER DEFAULT 0,
    devices_delivered INTEGER DEFAULT 0,
    devices_failed INTEGER DEFAULT 0,
    delivery_rate DECIMAL(5,2) DEFAULT 0,
    
    -- Status tracking
    status VARCHAR(50) DEFAULT 'pending', -- pending, sent, delivered, failed
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    
    -- Timing
    scheduled_at TIMESTAMPTZ DEFAULT NOW(),
    sent_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CHECK (status IN ('pending', 'sent', 'delivered', 'failed', 'cancelled')),
    CHECK (retry_count >= 0 AND retry_count <= 5)
);

-- Individual device delivery tracking
CREATE TABLE IF NOT EXISTS notification_device_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    notification_log_id UUID NOT NULL REFERENCES notification_logs(id) ON DELETE CASCADE,
    device_id UUID NOT NULL REFERENCES user_devices(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    response_data JSONB DEFAULT '{}',
    error_code VARCHAR(100),
    error_message TEXT,
    sent_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    opened_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CHECK (status IN ('pending', 'sent', 'delivered', 'failed', 'opened'))
);

-- =============================================================================
-- GLIMMER SERVICE TABLES
-- =============================================================================

-- Glimmer post categories
CREATE TABLE IF NOT EXISTS glimmer_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(200) NOT NULL,
    description TEXT,
    icon_name VARCHAR(100),
    color_hex VARCHAR(7) DEFAULT '#007AFF',
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Glimmer posts main table
CREATE TABLE IF NOT EXISTS glimmer_posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(500) NOT NULL,
    description TEXT,
    image_url TEXT,
    image_path TEXT,
    category_id INTEGER REFERENCES glimmer_categories(id),
    tags TEXT[] DEFAULT '{}',
    
    -- Engagement metrics
    like_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    view_count INTEGER DEFAULT 0,
    share_count INTEGER DEFAULT 0,
    
    -- Status and visibility
    is_published BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    is_trending BOOLEAN DEFAULT false,
    
    -- Moderation
    is_approved BOOLEAN DEFAULT true,
    moderation_notes TEXT,
    moderated_at TIMESTAMPTZ,
    moderated_by UUID REFERENCES auth.users(id),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Search optimization
    search_vector tsvector
);

-- Glimmer post likes
CREATE TABLE IF NOT EXISTS glimmer_post_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES glimmer_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Prevent duplicate likes
    UNIQUE(post_id, user_id)
);

-- Glimmer post comments
CREATE TABLE IF NOT EXISTS glimmer_post_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES glimmer_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    parent_comment_id UUID REFERENCES glimmer_post_comments(id) ON DELETE CASCADE,
    
    -- Engagement
    like_count INTEGER DEFAULT 0,
    
    -- Moderation
    is_approved BOOLEAN DEFAULT true,
    is_edited BOOLEAN DEFAULT false,
    edited_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- SERVICE CONFIGURATION TABLES
-- =============================================================================

-- Service configuration management
CREATE TABLE IF NOT EXISTS service_configurations (
    id SERIAL PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL,
    config_key VARCHAR(200) NOT NULL,
    config_value TEXT,
    value_type VARCHAR(50) DEFAULT 'string', -- string, boolean, integer, json
    description TEXT,
    is_sensitive BOOLEAN DEFAULT false,
    environment VARCHAR(50) DEFAULT 'production', -- development, staging, production
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(service_name, config_key, environment),
    CHECK (value_type IN ('string', 'boolean', 'integer', 'decimal', 'json'))
);

-- Service health monitoring
CREATE TABLE IF NOT EXISTS service_health_checks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_name VARCHAR(100) NOT NULL,
    check_type VARCHAR(100) NOT NULL,
    status VARCHAR(50) NOT NULL,
    response_time_ms INTEGER,
    error_message TEXT,
    metadata JSONB DEFAULT '{}',
    checked_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CHECK (status IN ('healthy', 'degraded', 'unhealthy', 'timeout'))
);

-- =============================================================================
-- MAINTENANCE AND ANALYTICS TABLES
-- =============================================================================

-- Service operation logs for analytics
CREATE TABLE IF NOT EXISTS service_operation_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_name VARCHAR(100) NOT NULL,
    operation_name VARCHAR(200) NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    
    -- Performance metrics
    duration_ms INTEGER,
    memory_usage_mb DECIMAL(10,2),
    cpu_usage_percent DECIMAL(5,2),
    
    -- Status and results
    status VARCHAR(50) NOT NULL,
    result_data JSONB DEFAULT '{}',
    error_message TEXT,
    
    -- Context
    device_info JSONB DEFAULT '{}',
    app_version VARCHAR(50),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CHECK (status IN ('success', 'error', 'timeout', 'cancelled'))
);

-- Daily service analytics
CREATE TABLE IF NOT EXISTS daily_service_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    analytics_date DATE NOT NULL,
    service_name VARCHAR(100) NOT NULL,
    
    -- Usage metrics
    total_operations INTEGER DEFAULT 0,
    successful_operations INTEGER DEFAULT 0,
    failed_operations INTEGER DEFAULT 0,
    unique_users INTEGER DEFAULT 0,
    
    -- Performance metrics
    avg_response_time_ms DECIMAL(10,2),
    max_response_time_ms INTEGER,
    min_response_time_ms INTEGER,
    
    -- Device metrics
    total_devices INTEGER DEFAULT 0,
    active_devices INTEGER DEFAULT 0,
    new_device_registrations INTEGER DEFAULT 0,
    
    -- Notification metrics (for notification services)
    notifications_sent INTEGER DEFAULT 0,
    notifications_delivered INTEGER DEFAULT 0,
    delivery_rate DECIMAL(5,2) DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Prevent duplicates
    UNIQUE(analytics_date, service_name)
);

-- =============================================================================
-- TRIGGERS FOR AUTOMATIC CALCULATIONS
-- =============================================================================

-- Function to calculate delivery rate for notification logs
CREATE OR REPLACE FUNCTION calculate_notification_delivery_rate()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate delivery rate when devices_targeted or devices_delivered changes
    IF NEW.devices_targeted > 0 THEN
        NEW.delivery_rate := ROUND((NEW.devices_delivered * 100.0 / NEW.devices_targeted), 2);
    ELSE
        NEW.delivery_rate := 0;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to notification_logs table
CREATE OR REPLACE TRIGGER trigger_calculate_delivery_rate
    BEFORE INSERT OR UPDATE OF devices_targeted, devices_delivered
    ON notification_logs
    FOR EACH ROW
    EXECUTE FUNCTION calculate_notification_delivery_rate();

-- Function to update search vector for glimmer posts
CREATE OR REPLACE FUNCTION update_glimmer_posts_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    -- Update search vector when title, description, or tags change
    NEW.search_vector := to_tsvector('english', 
        COALESCE(NEW.title, '') || ' ' || 
        COALESCE(NEW.description, '') || ' ' || 
        array_to_string(COALESCE(NEW.tags, '{}'), ' ')
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to glimmer_posts table
CREATE OR REPLACE TRIGGER trigger_update_search_vector
    BEFORE INSERT OR UPDATE OF title, description, tags
    ON glimmer_posts
    FOR EACH ROW
    EXECUTE FUNCTION update_glimmer_posts_search_vector();

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- User devices indexes (handle potential column name differences)
CREATE INDEX IF NOT EXISTS idx_user_devices_user_id ON user_devices(user_id);
-- Note: Conditional index creation for last_active column (might be named differently in existing table)
DO $$
BEGIN
    -- Try to create index with last_active column
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'user_devices' AND column_name = 'last_active') THEN
        EXECUTE 'CREATE INDEX IF NOT EXISTS idx_user_devices_active ON user_devices(is_active, last_active DESC)';
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'user_devices' AND column_name = 'last_seen_at') THEN
        EXECUTE 'CREATE INDEX IF NOT EXISTS idx_user_devices_active ON user_devices(is_active, last_seen_at DESC)';
    ELSE
        EXECUTE 'CREATE INDEX IF NOT EXISTS idx_user_devices_active ON user_devices(is_active)';
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS idx_user_devices_device_id ON user_devices(device_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_fcm_token ON user_devices(fcm_token) WHERE fcm_token IS NOT NULL;

-- Device user history indexes (handle potential column name differences)
DO $$
BEGIN
    -- Check if device_user_history table exists first
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'device_user_history') THEN
        -- Try to create indexes with device_identifier column
        IF EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'device_user_history' AND column_name = 'device_identifier') THEN
            EXECUTE 'CREATE INDEX IF NOT EXISTS idx_device_user_history_device ON device_user_history(device_identifier)';
            -- Only create current user index if is_current_user column exists
            IF EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'device_user_history' AND column_name = 'is_current_user') THEN
                EXECUTE 'CREATE INDEX IF NOT EXISTS idx_device_user_history_current ON device_user_history(device_identifier, is_current_user) WHERE is_current_user = true';
            END IF;
        ELSIF EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_name = 'device_user_history' AND column_name = 'device_id') THEN
            EXECUTE 'CREATE INDEX IF NOT EXISTS idx_device_user_history_device ON device_user_history(device_id)';
            -- Only create current user index if is_current_user column exists
            IF EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'device_user_history' AND column_name = 'is_current_user') THEN
                EXECUTE 'CREATE INDEX IF NOT EXISTS idx_device_user_history_current ON device_user_history(device_id, is_current_user) WHERE is_current_user = true';
            END IF;
        END IF;
        
        -- User ID index should always work if user_id column exists
        IF EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'device_user_history' AND column_name = 'user_id') THEN
            EXECUTE 'CREATE INDEX IF NOT EXISTS idx_device_user_history_user ON device_user_history(user_id)';
        END IF;
    END IF;
END $$;

-- Notification logs indexes
CREATE INDEX IF NOT EXISTS idx_notification_logs_receiver ON notification_logs(receiver_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notification_logs_type ON notification_logs(notification_type_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notification_logs_status ON notification_logs(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notification_logs_delivery_tracking ON notification_logs(devices_targeted, devices_delivered);

-- Notification device logs indexes
CREATE INDEX IF NOT EXISTS idx_notification_device_logs_notification ON notification_device_logs(notification_log_id);
CREATE INDEX IF NOT EXISTS idx_notification_device_logs_device ON notification_device_logs(device_id);
CREATE INDEX IF NOT EXISTS idx_notification_device_logs_status ON notification_device_logs(status, created_at DESC);

-- Glimmer posts indexes
CREATE INDEX IF NOT EXISTS idx_glimmer_posts_user ON glimmer_posts(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_glimmer_posts_category ON glimmer_posts(category_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_glimmer_posts_published ON glimmer_posts(is_published, created_at DESC) WHERE is_published = true;
CREATE INDEX IF NOT EXISTS idx_glimmer_posts_featured ON glimmer_posts(is_featured, created_at DESC) WHERE is_featured = true;
CREATE INDEX IF NOT EXISTS idx_glimmer_posts_search ON glimmer_posts USING gin(search_vector);
CREATE INDEX IF NOT EXISTS idx_glimmer_posts_engagement ON glimmer_posts(like_count DESC, comment_count DESC);

-- Glimmer likes and comments indexes
CREATE INDEX IF NOT EXISTS idx_glimmer_likes_post ON glimmer_post_likes(post_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_glimmer_likes_user ON glimmer_post_likes(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_glimmer_comments_post ON glimmer_post_comments(post_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_glimmer_comments_user ON glimmer_post_comments(user_id, created_at DESC);

-- Service configuration indexes
CREATE INDEX IF NOT EXISTS idx_service_configs_service ON service_configurations(service_name, environment);
CREATE INDEX IF NOT EXISTS idx_service_configs_active ON service_configurations(is_active) WHERE is_active = true;

-- Service health checks indexes
CREATE INDEX IF NOT EXISTS idx_service_health_service ON service_health_checks(service_name, checked_at DESC);
CREATE INDEX IF NOT EXISTS idx_service_health_status ON service_health_checks(status, checked_at DESC);

-- Analytics indexes
CREATE INDEX IF NOT EXISTS idx_service_operation_logs_service ON service_operation_logs(service_name, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_service_operation_logs_user ON service_operation_logs(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_service_operation_logs_performance ON service_operation_logs(duration_ms DESC, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_daily_service_analytics_date ON daily_service_analytics(analytics_date DESC, service_name);

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE user_devices IS 'Tracks all devices where users have registered for push notifications';
COMMENT ON TABLE device_user_history IS 'Tracks all users who have ever logged in on each device for auto-logout functionality';
COMMENT ON TABLE notification_types IS 'Defines types of notifications that can be sent';
COMMENT ON TABLE notification_templates IS 'Templates for consistent notification messaging';
COMMENT ON TABLE notification_logs IS 'Comprehensive log of all notifications sent through the system';
COMMENT ON TABLE notification_device_logs IS 'Individual device delivery tracking for notifications';
COMMENT ON TABLE glimmer_posts IS 'Main table for Glimmer Wall posts with full-text search';
COMMENT ON TABLE glimmer_post_likes IS 'Tracks likes on Glimmer posts';
COMMENT ON TABLE glimmer_post_comments IS 'Comments and replies on Glimmer posts';
COMMENT ON TABLE service_configurations IS 'Environment-specific configuration management for all services';
COMMENT ON TABLE service_health_checks IS 'Health monitoring and status tracking for all services';
COMMENT ON TABLE service_operation_logs IS 'Detailed operation logs for performance monitoring and debugging';
COMMENT ON TABLE daily_service_analytics IS 'Daily aggregated analytics for all services';

-- =============================================================================
-- INITIAL DATA SETUP
-- =============================================================================

-- Insert default notification types
INSERT INTO notification_types (name, display_name, description, icon_name, priority_level) VALUES
('message', 'Chat Messages', 'Direct messages between users', 'message', 3),
('glimmer_like', 'Glimmer Likes', 'Someone liked your Glimmer post', 'heart', 2),
('glimmer_comment', 'Glimmer Comments', 'Someone commented on your Glimmer post', 'chat_bubble', 2),
('glimmer_new_post', 'New Glimmer Posts', 'New posts from users you follow', 'image', 1),
('friend_request', 'Friend Requests', 'New friend requests', 'person_add', 3),
('system', 'System Notifications', 'Important system announcements', 'info', 4),
('achievement', 'Achievements', 'Achievement unlocked notifications', 'trophy', 2),
('level_up', 'Level Up', 'User level progression notifications', 'star', 2);

-- Insert default Glimmer categories
INSERT INTO glimmer_categories (name, display_name, description, icon_name, color_hex, sort_order) VALUES
('art', 'Art & Design', 'Creative artwork and design pieces', 'palette', '#FF6B6B', 1),
('photography', 'Photography', 'Beautiful photographs and moments', 'camera', '#4ECDC4', 2),
('nature', 'Nature', 'Natural landscapes and wildlife', 'leaf', '#45B7D1', 3),
('lifestyle', 'Lifestyle', 'Daily life and personal moments', 'home', '#96CEB4', 4),
('food', 'Food & Drink', 'Culinary creations and recipes', 'restaurant', '#FFEAA7', 5),
('travel', 'Travel', 'Adventures and destinations', 'flight', '#DDA0DD', 6),
('technology', 'Technology', 'Tech innovations and gadgets', 'computer', '#98D8C8', 7),
('other', 'Other', 'Miscellaneous posts', 'category', '#BDC3C7', 8);

-- Insert default notification templates
INSERT INTO notification_templates (type_id, name, title_template, body_template, data_schema) VALUES
(1, 'direct_message', '{{receiver_username}}', 'You have a message from {{sender_username}}', '{"sender_username": "string", "receiver_username": "string", "message_preview": "string"}'),
(2, 'glimmer_like', '{{receiver_username}}', '{{liker_username}} liked your post: {{post_title}}', '{"liker_username": "string", "receiver_username": "string", "post_title": "string", "post_id": "string"}'),
(3, 'glimmer_comment', '{{receiver_username}}', '{{commenter_username}} commented on your post: {{post_title}}', '{"commenter_username": "string", "receiver_username": "string", "post_title": "string", "comment_preview": "string", "post_id": "string"}'),
(4, 'glimmer_new_post', 'New Post', '{{author_username}} shared a new post: {{post_title}}', '{"author_username": "string", "post_title": "string", "post_id": "string"}'),
(5, 'friend_request', '{{receiver_username}}', 'You have a friend request from {{sender_username}}', '{"sender_username": "string", "receiver_username": "string", "request_id": "string"}'),
(6, 'system_announcement', 'Crystal Social', '{{announcement_message}}', '{"announcement_message": "string", "announcement_type": "string"}'),
(7, 'achievement_unlocked', '{{receiver_username}}', 'Achievement unlocked: {{achievement_name}}!', '{"receiver_username": "string", "achievement_name": "string", "achievement_description": "string"}'),
(8, 'level_up', '{{receiver_username}}', 'Congratulations! You reached level {{new_level}}!', '{"receiver_username": "string", "new_level": "integer", "rewards_earned": "string"}');

-- Insert default service configurations
INSERT INTO service_configurations (service_name, config_key, config_value, value_type, description, environment) VALUES
('push_notifications', 'enabled', 'true', 'boolean', 'Enable push notification service', 'production'),
('push_notifications', 'max_devices_per_user', '10', 'integer', 'Maximum devices per user', 'production'),
('push_notifications', 'notification_timeout_ms', '15000', 'integer', 'Notification timeout in milliseconds', 'production'),
('push_notifications', 'max_retry_attempts', '3', 'integer', 'Maximum retry attempts for failed notifications', 'production'),
('device_registration', 'enabled', 'true', 'boolean', 'Enable device registration service', 'production'),
('device_registration', 'cleanup_inactive_days', '90', 'integer', 'Days after which inactive devices are cleaned up', 'production'),
('user_tracking', 'enabled', 'true', 'boolean', 'Enable device user tracking', 'production'),
('user_tracking', 'auto_logout_enabled', 'true', 'boolean', 'Enable auto-logout for multiple users', 'production'),
('glimmer_service', 'enabled', 'true', 'boolean', 'Enable Glimmer service', 'production'),
('glimmer_service', 'max_image_size_mb', '10', 'integer', 'Maximum image size in MB', 'production'),
('glimmer_service', 'notify_followers_on_new_post', 'true', 'boolean', 'Notify followers when user posts', 'production'),
('performance', 'enable_monitoring', 'true', 'boolean', 'Enable performance monitoring', 'production'),
('performance', 'log_slow_operations_ms', '1000', 'integer', 'Log operations slower than this threshold', 'production'),
('maintenance', 'auto_cleanup_enabled', 'true', 'boolean', 'Enable automatic cleanup', 'production'),
('maintenance', 'cleanup_interval_hours', '24', 'integer', 'Hours between cleanup runs', 'production');

-- =============================================================================
-- SETUP COMPLETION
-- =============================================================================

SELECT 
    'Services Core Tables Setup Complete!' as status,
    (SELECT COUNT(*) FROM information_schema.tables WHERE table_name LIKE '%device%' OR table_name LIKE '%notification%' OR table_name LIKE '%glimmer%' OR table_name LIKE '%service%') as tables_created,
    (SELECT COUNT(*) FROM notification_types) as notification_types_configured,
    (SELECT COUNT(*) FROM glimmer_categories) as glimmer_categories_configured,
    (SELECT COUNT(*) FROM notification_templates) as notification_templates_configured,
    (SELECT COUNT(*) FROM service_configurations) as service_configs_set,
    NOW() as setup_completed_at;
