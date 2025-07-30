-- Crystal Social Main Application System - Core Tables
-- File: 01_main_app_core_tables.sql
-- Purpose: Database schema for main application system including app state, lifecycle, themes, and configuration

-- =============================================================================
-- CORE APPLICATION SYSTEM TABLES
-- =============================================================================

-- App State Management
CREATE TABLE IF NOT EXISTS app_states (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id TEXT NOT NULL,
    session_id UUID DEFAULT gen_random_uuid(),
    
    -- State information
    is_online BOOLEAN DEFAULT true,
    is_initialized BOOLEAN DEFAULT false,
    theme_mode TEXT DEFAULT 'light',
    selected_theme_color TEXT DEFAULT 'kawaii_pink',
    
    -- User preferences
    user_preferences JSONB DEFAULT '{}',
    accessibility_settings JSONB DEFAULT '{}',
    
    -- Error tracking
    last_error TEXT,
    error_count INTEGER DEFAULT 0,
    
    -- App status
    is_loading BOOLEAN DEFAULT false,
    app_version TEXT,
    flutter_version TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_seen_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_theme_mode CHECK (theme_mode IN ('light', 'dark', 'system')),
    CONSTRAINT valid_theme_color CHECK (selected_theme_color IN (
        'kawaii_pink', 'blood_red', 'ice_blue', 'forest_green', 
        'royal_purple', 'sunset_orange', 'midnight_black', 'ocean_teal'
    ))
);

-- Application Configuration
CREATE TABLE IF NOT EXISTS app_configurations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    config_key TEXT UNIQUE NOT NULL,
    config_value JSONB NOT NULL,
    config_type TEXT DEFAULT 'setting',
    is_user_configurable BOOLEAN DEFAULT false,
    is_environment_specific BOOLEAN DEFAULT false,
    description TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id),
    
    CONSTRAINT valid_config_type CHECK (config_type IN ('setting', 'feature_flag', 'environment', 'system'))
);

-- Connectivity and Network Status
CREATE TABLE IF NOT EXISTS connectivity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id TEXT NOT NULL,
    session_id UUID,
    
    -- Connectivity information
    connection_type TEXT NOT NULL, -- wifi, cellular, ethernet, none
    is_online BOOLEAN NOT NULL,
    network_quality TEXT, -- excellent, good, fair, poor
    
    -- Performance metrics
    latency_ms INTEGER,
    download_speed_kbps INTEGER,
    upload_speed_kbps INTEGER,
    
    -- Location context (optional)
    approximate_location TEXT,
    
    -- Timestamps
    connected_at TIMESTAMP WITH TIME ZONE,
    disconnected_at TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_connection_type CHECK (connection_type IN ('wifi', 'cellular', 'ethernet', 'vpn', 'none')),
    CONSTRAINT valid_network_quality CHECK (network_quality IN ('excellent', 'good', 'fair', 'poor', 'unknown'))
);

-- Application Lifecycle Events
CREATE TABLE IF NOT EXISTS app_lifecycle_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id TEXT NOT NULL,
    session_id UUID,
    
    -- Event information
    event_type TEXT NOT NULL,
    event_state TEXT,
    
    -- Context
    previous_state TEXT,
    duration_in_state_seconds INTEGER,
    
    -- Additional data
    app_version TEXT,
    platform TEXT,
    metadata JSONB DEFAULT '{}',
    
    -- Timestamps
    event_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_lifecycle_event CHECK (event_type IN (
        'app_start', 'app_resume', 'app_pause', 'app_inactive', 
        'app_detached', 'app_hidden', 'app_terminate', 'user_login', 
        'user_logout', 'app_background', 'app_foreground'
    ))
);

-- User Session Management
CREATE TABLE IF NOT EXISTS user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id TEXT NOT NULL,
    session_token TEXT UNIQUE NOT NULL,
    
    -- Session information
    session_start TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    session_end TIMESTAMP WITH TIME ZONE,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    inactivity_timeout_minutes INTEGER DEFAULT 60,
    
    -- Device and platform info
    platform TEXT NOT NULL,
    app_version TEXT,
    device_info JSONB DEFAULT '{}',
    
    -- Authentication details
    auth_method TEXT,
    fcm_token TEXT,
    onesignal_player_id TEXT,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    is_auto_logout_enabled BOOLEAN DEFAULT false,
    force_logout_reason TEXT,
    
    -- Location and IP (optional)
    ip_address INET,
    approximate_location TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_platform CHECK (platform IN ('android', 'ios', 'web', 'windows', 'macos', 'linux')),
    CONSTRAINT valid_auth_method CHECK (auth_method IN ('email', 'oauth', 'sso', 'guest', 'biometric'))
);

-- User Device Registration
CREATE TABLE IF NOT EXISTS user_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id TEXT NOT NULL,
    
    -- Device information
    device_name TEXT,
    platform TEXT NOT NULL,
    platform_version TEXT,
    device_model TEXT,
    device_brand TEXT,
    
    -- App information
    app_version TEXT,
    build_number TEXT,
    flutter_version TEXT,
    
    -- Push notification tokens
    fcm_token TEXT,
    onesignal_player_id TEXT,
    apns_token TEXT,
    
    -- Device capabilities
    supports_biometric BOOLEAN DEFAULT false,
    supports_push_notifications BOOLEAN DEFAULT false,
    supports_background_refresh BOOLEAN DEFAULT false,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    is_primary_device BOOLEAN DEFAULT false,
    last_seen_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Security
    device_fingerprint TEXT,
    is_trusted BOOLEAN DEFAULT false,
    security_violations INTEGER DEFAULT 0,
    
    -- Timestamps
    first_seen_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, device_id),
    CONSTRAINT valid_platform CHECK (platform IN ('android', 'ios', 'web', 'windows', 'macos', 'linux'))
);

-- Multi-user Device Tracking
CREATE TABLE IF NOT EXISTS multi_user_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id TEXT NOT NULL,
    device_fingerprint TEXT,
    
    -- Device information
    platform TEXT,
    device_model TEXT,
    device_brand TEXT,
    
    -- Usage tracking
    total_users_count INTEGER DEFAULT 0,
    active_users_count INTEGER DEFAULT 0,
    
    -- Security settings
    auto_logout_enabled BOOLEAN DEFAULT false,
    inactivity_timeout_minutes INTEGER DEFAULT 60,
    requires_full_auth BOOLEAN DEFAULT false,
    
    -- Device status
    is_shared_device BOOLEAN DEFAULT false,
    is_public_device BOOLEAN DEFAULT false,
    security_level TEXT DEFAULT 'standard',
    
    -- Timestamps
    first_user_seen_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(device_id),
    CONSTRAINT valid_security_level CHECK (security_level IN ('minimal', 'standard', 'enhanced', 'maximum'))
);

-- Device User History
CREATE TABLE IF NOT EXISTS device_user_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Session information
    login_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    logout_timestamp TIMESTAMP WITH TIME ZONE,
    session_duration_minutes INTEGER,
    
    -- Authentication details
    auth_method TEXT,
    logout_type TEXT, -- manual, auto_logout, forced, expired
    
    -- Context
    app_version TEXT,
    platform TEXT,
    
    -- Security
    ip_address INET,
    location_approximate TEXT,
    security_violations INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_logout_type CHECK (logout_type IN ('manual', 'auto_logout', 'forced', 'expired', 'device_removed'))
);

-- Application Initialization Logs
CREATE TABLE IF NOT EXISTS app_initialization_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id TEXT NOT NULL,
    session_id UUID,
    
    -- Initialization details
    initialization_start TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    initialization_end TIMESTAMP WITH TIME ZONE,
    total_duration_ms INTEGER,
    
    -- Service initialization tracking
    firebase_init_duration_ms INTEGER,
    supabase_init_duration_ms INTEGER,
    hive_init_duration_ms INTEGER,
    notifications_init_duration_ms INTEGER,
    analytics_init_duration_ms INTEGER,
    achievements_init_duration_ms INTEGER,
    
    -- Status
    initialization_successful BOOLEAN,
    failed_services TEXT[], -- Array of failed service names
    
    -- Error details
    error_message TEXT,
    error_stack_trace TEXT,
    
    -- App information
    app_version TEXT,
    platform TEXT,
    flutter_version TEXT,
    
    -- Environment
    is_debug_build BOOLEAN DEFAULT false,
    environment TEXT DEFAULT 'production',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_environment CHECK (environment IN ('development', 'staging', 'production'))
);

-- Fronting Changes (DID System Integration)
CREATE TABLE IF NOT EXISTS fronting_changes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Fronting information
    alter_name TEXT NOT NULL,
    previous_alter_name TEXT,
    
    -- Change details
    change_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    change_type TEXT DEFAULT 'manual', -- manual, automated, scheduled, emergency
    change_trigger TEXT, -- ui_selection, voice_command, schedule, stress_response
    
    -- Notification details
    notification_sent BOOLEAN DEFAULT false,
    notification_recipients UUID[],
    notification_timestamp TIMESTAMP WITH TIME ZONE,
    
    -- Context and metadata
    emotional_state TEXT,
    stress_level INTEGER CHECK (stress_level >= 1 AND stress_level <= 10),
    notes TEXT,
    
    -- Location context (optional)
    location_context TEXT,
    timezone TEXT,
    
    -- Verification
    verified_by_system BOOLEAN DEFAULT true,
    verification_timestamp TIMESTAMP WITH TIME ZONE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_change_type CHECK (change_type IN ('manual', 'automated', 'scheduled', 'emergency', 'system'))
);

-- Background Message Handling
CREATE TABLE IF NOT EXISTS background_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id TEXT,
    
    -- Message details
    message_id TEXT,
    message_type TEXT NOT NULL,
    title TEXT,
    body TEXT,
    
    -- Payload and data
    data_payload JSONB DEFAULT '{}',
    
    -- Processing status
    received_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE,
    processing_status TEXT DEFAULT 'pending',
    
    -- Handling details
    handler_function TEXT,
    processing_duration_ms INTEGER,
    
    -- Error tracking
    error_message TEXT,
    error_count INTEGER DEFAULT 0,
    
    -- Context
    app_state TEXT, -- foreground, background, terminated
    notification_permission_status TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_processing_status CHECK (processing_status IN ('pending', 'processing', 'completed', 'failed', 'skipped')),
    CONSTRAINT valid_message_type CHECK (message_type IN ('fronting_change', 'chat_message', 'system_update', 'achievement', 'generic')),
    CONSTRAINT valid_app_state CHECK (app_state IN ('foreground', 'background', 'terminated', 'unknown'))
);

-- Push Notification Analytics
CREATE TABLE IF NOT EXISTS push_notification_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id TEXT,
    
    -- Notification details
    notification_id TEXT,
    notification_type TEXT NOT NULL,
    campaign_id TEXT,
    
    -- Delivery information
    sent_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    opened_at TIMESTAMP WITH TIME ZONE,
    dismissed_at TIMESTAMP WITH TIME ZONE,
    
    -- User interaction
    action_taken TEXT, -- opened, dismissed, clicked_action, no_action
    action_button_clicked TEXT,
    
    -- Context
    app_state_when_received TEXT,
    device_permission_status TEXT,
    
    -- Performance
    delivery_latency_ms INTEGER,
    time_to_open_seconds INTEGER,
    
    -- A/B Testing
    variant_id TEXT,
    test_group TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_action_taken CHECK (action_taken IN ('opened', 'dismissed', 'clicked_action', 'no_action', 'expired'))
);

-- Error Tracking and Reporting
CREATE TABLE IF NOT EXISTS error_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id TEXT,
    session_id UUID,
    
    -- Error details
    error_type TEXT NOT NULL,
    error_message TEXT NOT NULL,
    error_code TEXT,
    stack_trace TEXT,
    
    -- Context
    context_description TEXT,
    function_name TEXT,
    file_name TEXT,
    line_number INTEGER,
    
    -- App state
    app_version TEXT,
    platform TEXT,
    flutter_version TEXT,
    
    -- User context
    user_action TEXT,
    screen_name TEXT,
    
    -- Environment
    is_debug_build BOOLEAN DEFAULT false,
    environment TEXT DEFAULT 'production',
    
    -- Severity and impact
    severity_level TEXT DEFAULT 'error',
    is_fatal BOOLEAN DEFAULT false,
    affects_core_functionality BOOLEAN DEFAULT false,
    
    -- Resolution
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolution_notes TEXT,
    resolved_by UUID REFERENCES auth.users(id),
    
    -- Occurrence tracking
    occurrence_count INTEGER DEFAULT 1,
    first_occurred_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_occurred_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_error_type CHECK (error_type IN ('network', 'database', 'ui', 'authentication', 'permission', 'system', 'user_action', 'integration')),
    CONSTRAINT valid_severity_level CHECK (severity_level IN ('debug', 'info', 'warning', 'error', 'critical'))
);

-- =============================================================================
-- INDEXES FOR PERFORMANCE OPTIMIZATION
-- =============================================================================

-- App States indexes
CREATE INDEX IF NOT EXISTS idx_app_states_user_device ON app_states(user_id, device_id);
CREATE INDEX IF NOT EXISTS idx_app_states_session ON app_states(session_id);
CREATE INDEX IF NOT EXISTS idx_app_states_last_seen ON app_states(last_seen_at DESC);

-- Connectivity logs indexes
CREATE INDEX IF NOT EXISTS idx_connectivity_user_device ON connectivity_logs(user_id, device_id);
CREATE INDEX IF NOT EXISTS idx_connectivity_recorded_at ON connectivity_logs(recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_connectivity_connection_type ON connectivity_logs(connection_type);

-- Lifecycle events indexes
CREATE INDEX IF NOT EXISTS idx_lifecycle_user_device ON app_lifecycle_events(user_id, device_id);
CREATE INDEX IF NOT EXISTS idx_lifecycle_event_type ON app_lifecycle_events(event_type);
CREATE INDEX IF NOT EXISTS idx_lifecycle_timestamp ON app_lifecycle_events(event_timestamp DESC);

-- User sessions indexes
CREATE INDEX IF NOT EXISTS idx_sessions_user_device ON user_sessions(user_id, device_id);
CREATE INDEX IF NOT EXISTS idx_sessions_active ON user_sessions(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_sessions_last_activity ON user_sessions(last_activity DESC);

-- Device tracking indexes
CREATE INDEX IF NOT EXISTS idx_devices_user ON user_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_devices_device_id ON user_devices(device_id);
CREATE INDEX IF NOT EXISTS idx_devices_active ON user_devices(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_devices_last_seen ON user_devices(last_seen_at DESC);

-- Multi-user device indexes
CREATE INDEX IF NOT EXISTS idx_multi_user_device_id ON multi_user_devices(device_id);
CREATE INDEX IF NOT EXISTS idx_multi_user_shared ON multi_user_devices(is_shared_device) WHERE is_shared_device = true;

-- Device user history indexes
CREATE INDEX IF NOT EXISTS idx_device_history_device ON device_user_history(device_id);
CREATE INDEX IF NOT EXISTS idx_device_history_user ON device_user_history(user_id);
CREATE INDEX IF NOT EXISTS idx_device_history_login ON device_user_history(login_timestamp DESC);

-- Fronting changes indexes
CREATE INDEX IF NOT EXISTS idx_fronting_user ON fronting_changes(user_id);
CREATE INDEX IF NOT EXISTS idx_fronting_timestamp ON fronting_changes(change_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_fronting_alter_name ON fronting_changes(alter_name);

-- Background messages indexes
CREATE INDEX IF NOT EXISTS idx_background_messages_user ON background_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_background_messages_type ON background_messages(message_type);
CREATE INDEX IF NOT EXISTS idx_background_messages_status ON background_messages(processing_status);
CREATE INDEX IF NOT EXISTS idx_background_messages_received ON background_messages(received_at DESC);

-- Error reports indexes
CREATE INDEX IF NOT EXISTS idx_error_reports_user ON error_reports(user_id);
CREATE INDEX IF NOT EXISTS idx_error_reports_type ON error_reports(error_type);
CREATE INDEX IF NOT EXISTS idx_error_reports_severity ON error_reports(severity_level);
CREATE INDEX IF NOT EXISTS idx_error_reports_occurred ON error_reports(last_occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_error_reports_unresolved ON error_reports(resolved_at) WHERE resolved_at IS NULL;

-- =============================================================================
-- CONSTRAINTS AND TRIGGERS
-- =============================================================================

-- Ensure at most one primary device per user
CREATE UNIQUE INDEX IF NOT EXISTS idx_one_primary_device_per_user 
ON user_devices(user_id) WHERE is_primary_device = true;

-- Apply timestamp triggers
-- Note: update_updated_at_column() function is defined in 00_shared_utilities.sql
CREATE TRIGGER update_app_states_updated_at BEFORE UPDATE ON app_states
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_sessions_updated_at BEFORE UPDATE ON user_sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_devices_updated_at BEFORE UPDATE ON user_devices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_multi_user_devices_updated_at BEFORE UPDATE ON multi_user_devices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_fronting_changes_updated_at BEFORE UPDATE ON fronting_changes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_error_reports_updated_at BEFORE UPDATE ON error_reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- INITIAL DATA SETUP
-- =============================================================================

-- Default app configurations
INSERT INTO app_configurations (config_key, config_value, config_type, is_user_configurable, description) VALUES
('default_theme_mode', '"light"', 'setting', true, 'Default theme mode for new users'),
('default_theme_color', '"kawaii_pink"', 'setting', true, 'Default theme color for new users'),
('inactivity_timeout_minutes', '60', 'setting', true, 'Default inactivity timeout in minutes'),
('max_recent_stickers', '50', 'setting', false, 'Maximum number of recent stickers to store'),
('max_cache_size_mb', '100', 'setting', false, 'Maximum cache size in megabytes'),
('splash_duration_seconds', '3', 'setting', false, 'Splash screen duration in seconds'),
('auto_logout_enabled', 'true', 'feature_flag', false, 'Enable automatic logout for shared devices'),
('push_notifications_enabled', 'true', 'feature_flag', true, 'Enable push notifications'),
('analytics_enabled', 'true', 'feature_flag', true, 'Enable analytics tracking'),
('debug_mode_enabled', 'false', 'feature_flag', false, 'Enable debug mode features'),
('maintenance_mode', 'false', 'feature_flag', false, 'Enable maintenance mode'),
('force_app_update', 'false', 'feature_flag', false, 'Force users to update app')
ON CONFLICT (config_key) DO NOTHING;

-- Setup completion message
SELECT 'Main App Core Tables Setup Complete!' as status, NOW() as setup_completed_at;
