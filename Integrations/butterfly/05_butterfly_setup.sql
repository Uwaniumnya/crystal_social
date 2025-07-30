-- Butterfly System Setup and Configuration
-- Final setup, triggers, maintenance procedures, and system integration

-- System configuration table for butterfly settings
CREATE TABLE IF NOT EXISTS butterfly_system_config (
    config_key TEXT PRIMARY KEY,
    config_value JSONB NOT NULL,
    description TEXT,
    category TEXT DEFAULT 'general',
    is_public BOOLEAN DEFAULT false,
    updated_by UUID REFERENCES user_profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Insert default butterfly system configuration
INSERT INTO butterfly_system_config (config_key, config_value, description, category, is_public) VALUES
('discovery_cooldown_minutes', '15', 'Cooldown between butterfly discoveries', 'gameplay', false),
('max_daily_discoveries', '10', 'Maximum discoveries per day per user', 'gameplay', false),
('discovery_success_base_rate', '0.3', 'Base success rate for discoveries', 'gameplay', false),
('favorite_limit_per_user', '50', 'Maximum favorites per user', 'limits', false),
('enable_trading', 'false', 'Enable butterfly trading between users', 'features', true),
('enable_weather_effects', 'true', 'Enable weather effects on discovery', 'features', true),
('enable_seasonal_bonuses', 'true', 'Enable seasonal discovery bonuses', 'features', true),
('cache_duration_minutes', '60', 'Default cache duration in minutes', 'performance', false),
('analytics_enabled', 'true', 'Enable analytics collection', 'analytics', false),
('error_logging_enabled', 'true', 'Enable error logging', 'monitoring', false),
('recommendation_engine_enabled', 'true', 'Enable recommendation engine', 'features', false),
('maintenance_mode', 'false', 'Enable maintenance mode', 'system', true),
('system_version', '"1.0.0"', 'Current butterfly system version', 'system', true),
('audio_enabled_default', 'true', 'Default audio enabled state for new users', 'user_experience', true),
('animation_enabled_default', 'true', 'Default animation enabled state for new users', 'user_experience', true)
ON CONFLICT (config_key) DO NOTHING;

-- Maintenance schedules and automated tasks
CREATE TABLE IF NOT EXISTS butterfly_maintenance_tasks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    task_name TEXT UNIQUE NOT NULL,
    task_type TEXT NOT NULL CHECK (task_type IN (
        'cleanup',
        'analytics_update',
        'cache_refresh',
        'statistics_calculation',
        'recommendation_generation',
        'backup',
        'optimization'
    )),
    schedule_cron TEXT, -- Cron expression for scheduling
    is_active BOOLEAN DEFAULT true,
    last_run TIMESTAMP WITH TIME ZONE,
    next_run TIMESTAMP WITH TIME ZONE,
    run_duration_seconds INTEGER,
    success_count INTEGER DEFAULT 0,
    failure_count INTEGER DEFAULT 0,
    task_config JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Insert default maintenance tasks
INSERT INTO butterfly_maintenance_tasks (task_name, task_type, schedule_cron, task_config) VALUES
('daily_analytics_update', 'analytics_update', '0 1 * * *', '{"description": "Update daily butterfly analytics"}'),
('cache_cleanup', 'cleanup', '0 */6 * * *', '{"description": "Clean expired cache entries every 6 hours"}'),
('weekly_statistics_update', 'statistics_calculation', '0 2 * * 0', '{"description": "Weekly statistics calculation"}'),
('monthly_data_cleanup', 'cleanup', '0 3 1 * *', '{"description": "Monthly cleanup of old data"}'),
('daily_recommendations', 'recommendation_generation', '0 4 * * *', '{"description": "Generate daily recommendations for active users"}')
ON CONFLICT (task_name) DO NOTHING;

-- System health monitoring
CREATE TABLE IF NOT EXISTS butterfly_system_health (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    check_name TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('healthy', 'warning', 'critical', 'unknown')),
    message TEXT,
    metrics JSONB DEFAULT '{}',
    checked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Integration with main profile system
-- Add butterfly-specific columns to profiles if they do not exist
DO $$
BEGIN
    -- Add butterfly discovery notification preference
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'user_profiles' AND column_name = 'butterfly_notifications') THEN
        ALTER TABLE user_profiles ADD COLUMN butterfly_notifications BOOLEAN DEFAULT true;
    END IF;
    
    -- Add butterfly tutorial completion
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'user_profiles' AND column_name = 'butterfly_tutorial_completed') THEN
        ALTER TABLE user_profiles ADD COLUMN butterfly_tutorial_completed BOOLEAN DEFAULT false;
    END IF;
    
    -- Add butterfly feature enabled flag
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'user_profiles' AND column_name = 'butterfly_feature_enabled') THEN
        ALTER TABLE user_profiles ADD COLUMN butterfly_feature_enabled BOOLEAN DEFAULT true;
    END IF;
END $$;

-- Create indexes for profile butterfly columns
CREATE INDEX IF NOT EXISTS idx_user_profiles_butterfly_notifications ON user_profiles(butterfly_notifications) WHERE butterfly_notifications = true;
CREATE INDEX IF NOT EXISTS idx_user_profiles_butterfly_feature_enabled ON user_profiles(butterfly_feature_enabled) WHERE butterfly_feature_enabled = true;

-- Enable RLS on configuration tables
ALTER TABLE butterfly_system_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE butterfly_maintenance_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE butterfly_system_health ENABLE ROW LEVEL SECURITY;

-- RLS Policies for configuration

-- Drop existing policies if they exist to prevent conflicts
DROP POLICY IF EXISTS "Anyone can view public butterfly config" ON butterfly_system_config;
DROP POLICY IF EXISTS "Admins can view all butterfly config" ON butterfly_system_config;
DROP POLICY IF EXISTS "Admins can manage butterfly config" ON butterfly_system_config;
DROP POLICY IF EXISTS "Admins can view maintenance tasks" ON butterfly_maintenance_tasks;
DROP POLICY IF EXISTS "Admins can view system health" ON butterfly_system_health;

CREATE POLICY "Anyone can view public butterfly config" ON butterfly_system_config
    FOR SELECT USING (is_public = true);

CREATE POLICY "Admins can view all butterfly config" ON butterfly_system_config
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM user_profiles WHERE id = auth.uid() AND username IN ('admin', 'moderator')
    ));

CREATE POLICY "Admins can manage butterfly config" ON butterfly_system_config
    FOR ALL USING (EXISTS (
        SELECT 1 FROM user_profiles WHERE id = auth.uid() AND username IN ('admin', 'moderator')
    ));

-- Maintenance tasks - admins only
CREATE POLICY "Admins can view maintenance tasks" ON butterfly_maintenance_tasks
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM user_profiles WHERE id = auth.uid() AND username IN ('admin', 'moderator')
    ));

-- System health - admins only
CREATE POLICY "Admins can view system health" ON butterfly_system_health
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM user_profiles WHERE id = auth.uid() AND username IN ('admin', 'moderator')
    ));

-- Comprehensive initialization function

-- Drop existing functions if they exist to prevent conflicts
DROP FUNCTION IF EXISTS initialize_butterfly_system_for_user(UUID) CASCADE;
DROP FUNCTION IF EXISTS get_butterfly_config(TEXT) CASCADE;
DROP FUNCTION IF EXISTS set_butterfly_config(TEXT, JSONB, UUID) CASCADE;
DROP FUNCTION IF EXISTS check_butterfly_system_health() CASCADE;
DROP FUNCTION IF EXISTS run_butterfly_maintenance() CASCADE;
DROP FUNCTION IF EXISTS calculate_butterfly_discovery_probability(UUID, TEXT, UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS trigger_initialize_butterfly_user() CASCADE;
DROP FUNCTION IF EXISTS get_butterfly_system_status() CASCADE;
DROP TRIGGER IF EXISTS initialize_butterfly_system_on_user_creation ON user_profiles;

CREATE OR REPLACE FUNCTION initialize_butterfly_system_for_user(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Initialize user stats
    INSERT INTO butterfly_user_stats (user_id)
    VALUES (p_user_id)
    ON CONFLICT (user_id) DO NOTHING;
    
    -- Initialize user preferences
    PERFORM init_butterfly_user_preferences(p_user_id);
    
    -- Initialize daily rewards
    INSERT INTO butterfly_daily_rewards (user_id)
    VALUES (p_user_id)
    ON CONFLICT (user_id, reward_date) DO NOTHING;
    
    -- Unlock default habitats
    INSERT INTO butterfly_user_habitats (user_id, habitat_id)
    SELECT p_user_id, bh.id
    FROM butterfly_habitats bh
    WHERE bh.is_unlocked_by_default = true
    ON CONFLICT (user_id, habitat_id) DO NOTHING;
    
    -- Generate initial recommendations
    PERFORM generate_butterfly_recommendations(p_user_id);
    
    -- Track system initialization
    PERFORM track_butterfly_feature_usage(
        p_user_id, 
        'system_initialization', 
        jsonb_build_object('timestamp', NOW())
    );
END;
$$ LANGUAGE plpgsql;

-- System configuration getter/setter functions
CREATE OR REPLACE FUNCTION get_butterfly_config(config_key TEXT)
RETURNS JSONB AS $$
DECLARE
    config_value JSONB;
BEGIN
    SELECT bsc.config_value INTO config_value 
    FROM butterfly_system_config bsc 
    WHERE bsc.config_key = get_butterfly_config.config_key;
    
    RETURN COALESCE(config_value, 'null'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION set_butterfly_config(
    config_key TEXT,
    config_value JSONB,
    admin_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    INSERT INTO butterfly_system_config (config_key, config_value, updated_by)
    VALUES (config_key, config_value, admin_id)
    ON CONFLICT (config_key) DO UPDATE SET
        config_value = EXCLUDED.config_value,
        updated_by = EXCLUDED.updated_by,
        updated_at = NOW();
        
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- System health check function
CREATE OR REPLACE FUNCTION check_butterfly_system_health()
RETURNS JSONB AS $$
DECLARE
    health_status JSONB := '{}';
    total_users INTEGER;
    active_users_24h INTEGER;
    total_discoveries_24h INTEGER;
    error_count_24h INTEGER;
    cache_hit_rate DECIMAL;
BEGIN
    -- Check basic metrics
    SELECT COUNT(*) INTO total_users FROM butterfly_user_stats;
    
    SELECT COUNT(DISTINCT user_id) INTO active_users_24h 
    FROM butterfly_user_analytics 
    WHERE date >= CURRENT_DATE - INTERVAL '1 day';
    
    SELECT COUNT(*) INTO total_discoveries_24h 
    FROM butterfly_discoveries 
    WHERE time_of_discovery >= NOW() - INTERVAL '24 hours';
    
    SELECT COUNT(*) INTO error_count_24h 
    FROM butterfly_error_logs 
    WHERE created_at >= NOW() - INTERVAL '24 hours' 
    AND severity IN ('error', 'critical');
    
    -- Calculate cache hit rate
    SELECT CASE 
        WHEN COUNT(*) > 0 THEN AVG(access_count)::DECIMAL / COUNT(*)
        ELSE 0 
    END INTO cache_hit_rate
    FROM butterfly_cache
    WHERE last_accessed >= NOW() - INTERVAL '24 hours';
    
    -- Build health status
    health_status := jsonb_build_object(
        'overall_status', CASE 
            WHEN error_count_24h > 100 THEN 'critical'
            WHEN error_count_24h > 10 THEN 'warning'
            ELSE 'healthy'
        END,
        'total_users', total_users,
        'active_users_24h', active_users_24h,
        'discoveries_24h', total_discoveries_24h,
        'errors_24h', error_count_24h,
        'cache_hit_rate', cache_hit_rate,
        'last_checked', NOW()
    );
    
    -- Log health check
    INSERT INTO butterfly_system_health (check_name, status, message, metrics)
    VALUES (
        'daily_health_check',
        (health_status->>'overall_status'),
        'Automated daily health check',
        health_status
    );
    
    RETURN health_status;
END;
$$ LANGUAGE plpgsql;

-- Comprehensive maintenance function
CREATE OR REPLACE FUNCTION run_butterfly_maintenance()
RETURNS JSONB AS $$
DECLARE
    maintenance_results JSONB := '{}';
    cleanup_count INTEGER;
    analytics_updated BOOLEAN;
    recommendations_generated INTEGER;
BEGIN
    -- Clean up old data
    PERFORM cleanup_butterfly_analytics();
    GET DIAGNOSTICS cleanup_count = ROW_COUNT;
    
    -- Update analytics
    PERFORM update_butterfly_daily_analytics();
    analytics_updated := true;
    
    -- Generate recommendations for active users
    INSERT INTO butterfly_recommendations (user_id, recommendation_type, recommended_item_id, recommendation_score, reasoning)
    SELECT 
        bus.user_id,
        'daily_discovery',
        (SELECT id FROM butterfly_species 
         WHERE is_active = true 
         AND id NOT IN (SELECT butterfly_id FROM butterfly_album WHERE user_id = bus.user_id)
         ORDER BY RANDOM() LIMIT 1),
        0.8,
        '{"reason": "Daily discovery suggestion", "generated_at": "' || NOW() || '"}'
    FROM butterfly_user_stats bus
    WHERE bus.last_discovery >= NOW() - INTERVAL '7 days'
    ON CONFLICT DO NOTHING;
    
    GET DIAGNOSTICS recommendations_generated = ROW_COUNT;
    
    -- Update system health
    PERFORM check_butterfly_system_health();
    
    maintenance_results := jsonb_build_object(
        'cleanup_records_removed', cleanup_count,
        'analytics_updated', analytics_updated,
        'recommendations_generated', recommendations_generated,
        'maintenance_completed_at', NOW()
    );
    
    RETURN maintenance_results;
END;
$$ LANGUAGE plpgsql;

-- Discovery probability calculation with all modifiers
CREATE OR REPLACE FUNCTION calculate_butterfly_discovery_probability(
    p_user_id UUID,
    p_butterfly_id TEXT,
    p_habitat_id UUID DEFAULT NULL,
    p_weather_type TEXT DEFAULT 'sunny'
)
RETURNS DECIMAL AS $$
DECLARE
    base_chance DECIMAL;
    final_probability DECIMAL;
    seasonal_bonus DECIMAL := 1.0;
    habitat_bonus DECIMAL := 1.0;
    weather_modifier DECIMAL := 1.0;
    user_level INTEGER;
    rarity_modifier DECIMAL := 1.0;
BEGIN
    -- Get base discovery chance
    SELECT discovery_chance INTO base_chance 
    FROM butterfly_species 
    WHERE id = p_butterfly_id;
    
    IF base_chance IS NULL THEN
        RETURN 0.0;
    END IF;
    
    -- Get user level for bonus
    SELECT collection_level INTO user_level 
    FROM butterfly_user_stats 
    WHERE user_id = p_user_id;
    
    user_level := COALESCE(user_level, 1);
    
    -- Apply seasonal bonus
    SELECT COALESCE(seasonal_bonus, 1.0) INTO seasonal_bonus
    FROM get_seasonal_discovery_modifiers()
    WHERE butterfly_id = p_butterfly_id;
    
    -- Apply habitat bonus
    IF p_habitat_id IS NOT NULL THEN
        SELECT COALESCE(discovery_bonus, 1.0) INTO habitat_bonus
        FROM butterfly_habitats
        WHERE id = p_habitat_id;
    END IF;
    
    -- Apply weather modifier
    SELECT COALESCE(discovery_modifier, 1.0) INTO weather_modifier
    FROM butterfly_weather_effects
    WHERE weather_type = p_weather_type;
    
    -- Calculate final probability
    final_probability := base_chance * 
                        seasonal_bonus * 
                        habitat_bonus * 
                        weather_modifier * 
                        (1.0 + (user_level - 1) * 0.05); -- 5% bonus per level
    
    -- Cap at maximum probability
    final_probability := LEAST(final_probability, 0.95);
    
    RETURN final_probability;
END;
$$ LANGUAGE plpgsql;

-- Trigger to initialize butterfly system for new users
CREATE OR REPLACE FUNCTION trigger_initialize_butterfly_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Initialize butterfly system for new user
    PERFORM initialize_butterfly_system_for_user(NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new user initialization
CREATE TRIGGER initialize_butterfly_system_on_user_creation
    AFTER INSERT ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION trigger_initialize_butterfly_user();

-- Function to get butterfly system status
CREATE OR REPLACE FUNCTION get_butterfly_system_status()
RETURNS JSONB AS $$
DECLARE
    system_status JSONB;
    maintenance_mode BOOLEAN;
    total_species INTEGER;
    total_users INTEGER;
    discoveries_today INTEGER;
BEGIN
    -- Check maintenance mode
    SELECT (config_value)::BOOLEAN INTO maintenance_mode
    FROM butterfly_system_config
    WHERE config_key = 'maintenance_mode';
    
    -- Get basic stats
    SELECT COUNT(*) INTO total_species FROM butterfly_species WHERE is_active = true;
    SELECT COUNT(*) INTO total_users FROM butterfly_user_stats;
    SELECT COUNT(*) INTO discoveries_today 
    FROM butterfly_discoveries 
    WHERE DATE(time_of_discovery) = CURRENT_DATE;
    
    system_status := jsonb_build_object(
        'maintenance_mode', COALESCE(maintenance_mode, false),
        'total_species', total_species,
        'total_users', total_users,
        'discoveries_today', discoveries_today,
        'system_version', get_butterfly_config('system_version'),
        'last_updated', NOW()
    );
    
    RETURN system_status;
END;
$$ LANGUAGE plpgsql;

-- Insert default weather effects
INSERT INTO butterfly_weather_effects (weather_type, affected_rarities, discovery_modifier, description) VALUES
('sunny', '{"common", "uncommon"}', 1.2, 'Sunny weather increases common butterfly activity'),
('cloudy', '{"rare", "epic"}', 1.1, 'Cloudy skies bring out rarer butterflies'),
('rainy', '{"epic", "legendary"}', 0.8, 'Rain reduces most butterfly activity but favors magical species'),
('stormy', '{"legendary", "mythical"}', 1.5, 'Storms awaken the most powerful butterflies'),
('misty', '{"mythical"}', 2.0, 'Mystical conditions perfect for mythical encounters'),
('snowy', '{"legendary"}', 0.5, 'Snow limits most activity but legendary butterflies love winter')
ON CONFLICT DO NOTHING;

-- Final system health check and initialization log
DO $$
BEGIN
    -- Check if the log_system_event function exists before calling it
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'log_system_event') THEN
        PERFORM log_system_event(
            p_event_type := 'butterfly_system_initialized'::TEXT,
            p_event_category := 'system'::TEXT,
            p_severity := 'info'::TEXT,
            p_message := 'Butterfly collection system has been fully initialized'::TEXT,
            p_details := jsonb_build_object(
                'version', '1.0.0',
                'total_species', (SELECT COUNT(*) FROM butterfly_species),
                'total_rarities', (SELECT COUNT(*) FROM butterfly_rarity_config),
                'default_habitats', (SELECT COUNT(*) FROM butterfly_habitats WHERE is_unlocked_by_default = true),
                'initialized_at', NOW()
            )
        );
    ELSE
        -- If the function doesn't exist, just raise a notice
        RAISE NOTICE 'Butterfly system initialized successfully. log_system_event function not available.';
    END IF;
END $$;
