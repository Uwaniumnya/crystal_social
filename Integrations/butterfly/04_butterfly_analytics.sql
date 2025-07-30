-- Butterfly Analytics and Performance Optimization
-- Handles analytics, caching, performance monitoring, and optimization features

-- Butterfly discovery analytics
CREATE TABLE IF NOT EXISTS butterfly_analytics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    date DATE DEFAULT CURRENT_DATE,
    butterfly_id TEXT REFERENCES butterfly_species(id),
    total_discoveries INTEGER DEFAULT 0,
    unique_discoverers INTEGER DEFAULT 0,
    average_discovery_time DECIMAL(8,2), -- Average time to discover in minutes
    discovery_success_rate DECIMAL(5,4), -- Success rate as decimal (0.0 to 1.0)
    favorite_count INTEGER DEFAULT 0,
    interaction_count INTEGER DEFAULT 0,
    rarity TEXT,
    habitat_discoveries JSONB DEFAULT '{}', -- Discoveries per habitat
    time_of_day_discoveries JSONB DEFAULT '{}', -- Discoveries by time of day
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    UNIQUE(date, butterfly_id)
);

-- User engagement analytics
CREATE TABLE IF NOT EXISTS butterfly_user_analytics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    date DATE DEFAULT CURRENT_DATE,
    session_duration INTEGER DEFAULT 0, -- Total time spent in minutes
    discoveries_made INTEGER DEFAULT 0,
    butterflies_interacted INTEGER DEFAULT 0,
    favorites_added INTEGER DEFAULT 0,
    favorites_removed INTEGER DEFAULT 0,
    quests_completed INTEGER DEFAULT 0,
    events_participated INTEGER DEFAULT 0,
    screen_views JSONB DEFAULT '{}', -- Track which screens were viewed
    actions_performed JSONB DEFAULT '{}', -- Track user actions
    UNIQUE(user_id, date)
);

-- Performance metrics for the butterfly system
CREATE TABLE IF NOT EXISTS butterfly_performance_metrics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    metric_name TEXT NOT NULL,
    metric_value DECIMAL(12,4),
    metric_unit TEXT,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    context JSONB DEFAULT '{}' -- Additional context data
);

-- Butterfly system cache for frequently accessed data
CREATE TABLE IF NOT EXISTS butterfly_cache (
    cache_key TEXT PRIMARY KEY,
    cache_data JSONB NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    last_accessed TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    access_count INTEGER DEFAULT 1
);

-- User butterfly preferences and recommendations
CREATE TABLE IF NOT EXISTS butterfly_user_preferences (
    user_id UUID PRIMARY KEY REFERENCES user_profiles(id) ON DELETE CASCADE,
    preferred_rarities TEXT[] DEFAULT '{}',
    preferred_habitats TEXT[] DEFAULT '{}',
    preferred_colors TEXT[] DEFAULT '{}',
    discovery_frequency TEXT DEFAULT 'normal' CHECK (discovery_frequency IN ('low', 'normal', 'high')),
    notification_preferences JSONB DEFAULT '{}',
    gameplay_style TEXT DEFAULT 'balanced' CHECK (gameplay_style IN ('casual', 'balanced', 'collector', 'completionist')),
    accessibility_settings JSONB DEFAULT '{}',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- A/B testing for butterfly features
CREATE TABLE IF NOT EXISTS butterfly_ab_tests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    test_name TEXT UNIQUE NOT NULL,
    description TEXT,
    variants JSONB NOT NULL, -- Different test variants
    traffic_allocation JSONB NOT NULL, -- Traffic allocation per variant
    start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    success_metrics TEXT[] DEFAULT '{}', -- Metrics to track for success
    created_by UUID REFERENCES user_profiles(id)
);

-- User assignments to A/B test variants
CREATE TABLE IF NOT EXISTS butterfly_ab_test_assignments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    test_id UUID REFERENCES butterfly_ab_tests(id) ON DELETE CASCADE,
    variant TEXT NOT NULL,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    UNIQUE(user_id, test_id)
);

-- Butterfly system error logs and monitoring
CREATE TABLE IF NOT EXISTS butterfly_error_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    error_type TEXT NOT NULL,
    error_message TEXT NOT NULL,
    stack_trace TEXT,
    user_id UUID REFERENCES user_profiles(id),
    user_agent TEXT,
    device_info JSONB,
    error_context JSONB DEFAULT '{}',
    severity TEXT DEFAULT 'error' CHECK (severity IN ('debug', 'info', 'warning', 'error', 'critical')),
    resolved BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Butterfly feature usage tracking
CREATE TABLE IF NOT EXISTS butterfly_feature_usage (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    feature_name TEXT NOT NULL,
    user_id UUID REFERENCES user_profiles(id),
    usage_count INTEGER DEFAULT 1,
    first_used TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    last_used TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    session_id TEXT,
    feature_context JSONB DEFAULT '{}',
    UNIQUE(user_id, feature_name)
);

-- Discovery pattern analysis
CREATE TABLE IF NOT EXISTS butterfly_discovery_patterns (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    pattern_name TEXT NOT NULL,
    pattern_type TEXT NOT NULL CHECK (pattern_type IN (
        'time_based',
        'rarity_based',
        'habitat_based',
        'user_behavior',
        'seasonal'
    )),
    pattern_data JSONB NOT NULL,
    confidence_score DECIMAL(3,2), -- 0.00 to 1.00
    sample_size INTEGER,
    date_analyzed DATE DEFAULT CURRENT_DATE,
    is_active BOOLEAN DEFAULT true
);

-- Recommendation engine data
CREATE TABLE IF NOT EXISTS butterfly_recommendations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    recommendation_type TEXT NOT NULL CHECK (recommendation_type IN (
        'next_butterfly',
        'habitat_explore',
        'quest_suggestion',
        'collection_theme',
        'trading_opportunity'
    )),
    recommended_item_id TEXT, -- ID of butterfly, habitat, quest, etc.
    recommendation_score DECIMAL(5,3), -- 0.000 to 1.000
    reasoning JSONB DEFAULT '{}', -- Why this was recommended
    presented_at TIMESTAMP WITH TIME ZONE,
    clicked BOOLEAN DEFAULT false,
    acted_upon BOOLEAN DEFAULT false,
    feedback_score INTEGER, -- User feedback 1-5
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days')
);

-- Indexes for analytics and performance
CREATE INDEX IF NOT EXISTS idx_butterfly_analytics_date ON butterfly_analytics(date);
CREATE INDEX IF NOT EXISTS idx_butterfly_analytics_butterfly_id ON butterfly_analytics(butterfly_id);
CREATE INDEX IF NOT EXISTS idx_butterfly_analytics_rarity ON butterfly_analytics(rarity);

CREATE INDEX IF NOT EXISTS idx_butterfly_user_analytics_user_date ON butterfly_user_analytics(user_id, date);
CREATE INDEX IF NOT EXISTS idx_butterfly_user_analytics_date ON butterfly_user_analytics(date);

CREATE INDEX IF NOT EXISTS idx_butterfly_performance_metrics_name ON butterfly_performance_metrics(metric_name);
CREATE INDEX IF NOT EXISTS idx_butterfly_performance_metrics_recorded_at ON butterfly_performance_metrics(recorded_at);

CREATE INDEX IF NOT EXISTS idx_butterfly_cache_expires_at ON butterfly_cache(expires_at);
CREATE INDEX IF NOT EXISTS idx_butterfly_cache_last_accessed ON butterfly_cache(last_accessed);

CREATE INDEX IF NOT EXISTS idx_butterfly_error_logs_severity ON butterfly_error_logs(severity);
CREATE INDEX IF NOT EXISTS idx_butterfly_error_logs_created_at ON butterfly_error_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_butterfly_error_logs_resolved ON butterfly_error_logs(resolved);

CREATE INDEX IF NOT EXISTS idx_butterfly_feature_usage_feature ON butterfly_feature_usage(feature_name);
CREATE INDEX IF NOT EXISTS idx_butterfly_feature_usage_user ON butterfly_feature_usage(user_id);

CREATE INDEX IF NOT EXISTS idx_butterfly_recommendations_user ON butterfly_recommendations(user_id);
CREATE INDEX IF NOT EXISTS idx_butterfly_recommendations_type ON butterfly_recommendations(recommendation_type);
CREATE INDEX IF NOT EXISTS idx_butterfly_recommendations_expires ON butterfly_recommendations(expires_at);

-- Enable RLS
ALTER TABLE butterfly_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE butterfly_user_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE butterfly_performance_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE butterfly_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE butterfly_user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE butterfly_ab_tests ENABLE ROW LEVEL SECURITY;
ALTER TABLE butterfly_ab_test_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE butterfly_error_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE butterfly_feature_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE butterfly_discovery_patterns ENABLE ROW LEVEL SECURITY;
ALTER TABLE butterfly_recommendations ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Drop existing policies if they exist to prevent conflicts
DROP POLICY IF EXISTS "Admins can view butterfly analytics" ON butterfly_analytics;
DROP POLICY IF EXISTS "Users can view own user analytics" ON butterfly_user_analytics;
DROP POLICY IF EXISTS "Admins can view performance metrics" ON butterfly_performance_metrics;
DROP POLICY IF EXISTS "System can access cache" ON butterfly_cache;
DROP POLICY IF EXISTS "Users can manage own preferences" ON butterfly_user_preferences;
DROP POLICY IF EXISTS "Anyone can view active A/B tests" ON butterfly_ab_tests;
DROP POLICY IF EXISTS "Users can view own A/B assignments" ON butterfly_ab_test_assignments;
DROP POLICY IF EXISTS "Admins can view error logs" ON butterfly_error_logs;
DROP POLICY IF EXISTS "Anyone can log errors" ON butterfly_error_logs;
DROP POLICY IF EXISTS "Users can view own feature usage" ON butterfly_feature_usage;
DROP POLICY IF EXISTS "Admins can view discovery patterns" ON butterfly_discovery_patterns;
DROP POLICY IF EXISTS "Users can view own recommendations" ON butterfly_recommendations;

-- Analytics - admins only
CREATE POLICY "Admins can view butterfly analytics" ON butterfly_analytics
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM user_profiles WHERE id = auth.uid() AND username IN ('admin', 'moderator')
    ));

-- User analytics - users can see their own
CREATE POLICY "Users can view own user analytics" ON butterfly_user_analytics
    FOR SELECT USING (user_id = auth.uid() OR EXISTS (
        SELECT 1 FROM user_profiles WHERE id = auth.uid() AND username IN ('admin', 'moderator')
    ));

-- Performance metrics - admins only
CREATE POLICY "Admins can view performance metrics" ON butterfly_performance_metrics
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM user_profiles WHERE id = auth.uid() AND username IN ('admin', 'moderator')
    ));

-- Cache - system access only (no RLS needed for cache)
CREATE POLICY "System can access cache" ON butterfly_cache
    FOR ALL USING (true);

-- User preferences - users can manage their own
CREATE POLICY "Users can manage own preferences" ON butterfly_user_preferences
    FOR ALL USING (user_id = auth.uid());

-- A/B tests - public readable for active tests
CREATE POLICY "Anyone can view active A/B tests" ON butterfly_ab_tests
    FOR SELECT USING (is_active = true);

-- A/B test assignments - users can see their own
CREATE POLICY "Users can view own A/B assignments" ON butterfly_ab_test_assignments
    FOR SELECT USING (user_id = auth.uid());

-- Error logs - admins only
CREATE POLICY "Admins can view error logs" ON butterfly_error_logs
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM user_profiles WHERE id = auth.uid() AND username IN ('admin', 'moderator')
    ));

CREATE POLICY "Anyone can log errors" ON butterfly_error_logs
    FOR INSERT WITH CHECK (true);

-- Feature usage - users can see their own
CREATE POLICY "Users can view own feature usage" ON butterfly_feature_usage
    FOR SELECT USING (user_id = auth.uid() OR EXISTS (
        SELECT 1 FROM user_profiles WHERE id = auth.uid() AND username IN ('admin', 'moderator')
    ));

-- Discovery patterns - admins only
CREATE POLICY "Admins can view discovery patterns" ON butterfly_discovery_patterns
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM user_profiles WHERE id = auth.uid() AND username IN ('admin', 'moderator')
    ));

-- Recommendations - users can see their own
CREATE POLICY "Users can view own recommendations" ON butterfly_recommendations
    FOR SELECT USING (user_id = auth.uid());

-- Functions

-- Drop existing functions if they exist to prevent conflicts
DROP FUNCTION IF EXISTS update_butterfly_daily_analytics() CASCADE;
DROP FUNCTION IF EXISTS get_butterfly_cache(TEXT) CASCADE;
DROP FUNCTION IF EXISTS set_butterfly_cache(TEXT, JSONB, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS clean_butterfly_cache() CASCADE;
DROP FUNCTION IF EXISTS track_butterfly_feature_usage(UUID, TEXT, JSONB) CASCADE;
DROP FUNCTION IF EXISTS log_butterfly_error(TEXT, TEXT, TEXT, UUID, TEXT, JSONB) CASCADE;
DROP FUNCTION IF EXISTS generate_butterfly_recommendations(UUID) CASCADE;
DROP FUNCTION IF EXISTS record_butterfly_performance_metric(TEXT, DECIMAL, TEXT, JSONB) CASCADE;
DROP FUNCTION IF EXISTS cleanup_butterfly_analytics() CASCADE;
DROP FUNCTION IF EXISTS init_butterfly_user_preferences(UUID) CASCADE;

-- Update daily analytics
CREATE OR REPLACE FUNCTION update_butterfly_daily_analytics()
RETURNS VOID AS $$
DECLARE
    today DATE := CURRENT_DATE;
    butterfly_record RECORD;
BEGIN
    -- Update analytics for each butterfly
    FOR butterfly_record IN
        SELECT bs.id, bs.rarity
        FROM butterfly_species bs
        WHERE bs.is_active = true
    LOOP
        INSERT INTO butterfly_analytics (
            date, butterfly_id, rarity,
            total_discoveries, unique_discoverers, favorite_count, interaction_count
        )
        SELECT 
            today,
            butterfly_record.id,
            butterfly_record.rarity,
            COUNT(ba.id) as total_discoveries,
            COUNT(DISTINCT ba.user_id) as unique_discoverers,
            COUNT(bf.id) as favorite_count,
            COUNT(bd.id) as interaction_count
        FROM butterfly_species bs
        LEFT JOIN butterfly_album ba ON bs.id = ba.butterfly_id AND DATE(ba.discovered_at) = today
        LEFT JOIN butterfly_favorites bf ON bs.id = bf.butterfly_id AND DATE(bf.favorited_at) = today
        LEFT JOIN butterfly_discoveries bd ON bs.id = bd.butterfly_id AND DATE(bd.time_of_discovery) = today
        WHERE bs.id = butterfly_record.id
        GROUP BY bs.id
        ON CONFLICT (date, butterfly_id) DO UPDATE SET
            total_discoveries = EXCLUDED.total_discoveries,
            unique_discoverers = EXCLUDED.unique_discoverers,
            favorite_count = EXCLUDED.favorite_count,
            interaction_count = EXCLUDED.interaction_count;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Cache management functions
CREATE OR REPLACE FUNCTION get_butterfly_cache(p_cache_key TEXT)
RETURNS JSONB AS $$
DECLARE
    cache_record RECORD;
BEGIN
    SELECT cache_data, expires_at INTO cache_record
    FROM butterfly_cache
    WHERE cache_key = p_cache_key;
    
    IF NOT FOUND THEN
        RETURN NULL;
    END IF;
    
    -- Check if cache has expired
    IF cache_record.expires_at IS NOT NULL AND cache_record.expires_at <= NOW() THEN
        DELETE FROM butterfly_cache WHERE cache_key = p_cache_key;
        RETURN NULL;
    END IF;
    
    -- Update access statistics
    UPDATE butterfly_cache SET
        last_accessed = NOW(),
        access_count = access_count + 1
    WHERE cache_key = p_cache_key;
    
    RETURN cache_record.cache_data;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION set_butterfly_cache(
    p_cache_key TEXT,
    p_cache_data JSONB,
    p_expires_in_minutes INTEGER DEFAULT 60
)
RETURNS BOOLEAN AS $$
BEGIN
    INSERT INTO butterfly_cache (cache_key, cache_data, expires_at)
    VALUES (
        p_cache_key,
        p_cache_data,
        NOW() + (p_expires_in_minutes || ' minutes')::INTERVAL
    )
    ON CONFLICT (cache_key) DO UPDATE SET
        cache_data = EXCLUDED.cache_data,
        expires_at = EXCLUDED.expires_at,
        last_accessed = NOW(),
        access_count = butterfly_cache.access_count + 1;
    
    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Clean expired cache entries
CREATE OR REPLACE FUNCTION clean_butterfly_cache()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM butterfly_cache 
    WHERE expires_at IS NOT NULL AND expires_at <= NOW();
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Track feature usage
CREATE OR REPLACE FUNCTION track_butterfly_feature_usage(
    p_user_id UUID,
    p_feature_name TEXT,
    p_context JSONB DEFAULT '{}'
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO butterfly_feature_usage (user_id, feature_name, feature_context)
    VALUES (p_user_id, p_feature_name, p_context)
    ON CONFLICT (user_id, feature_name) DO UPDATE SET
        usage_count = butterfly_feature_usage.usage_count + 1,
        last_used = NOW(),
        feature_context = p_context;
END;
$$ LANGUAGE plpgsql;

-- Log butterfly system errors
CREATE OR REPLACE FUNCTION log_butterfly_error(
    p_error_type TEXT,
    p_error_message TEXT,
    p_stack_trace TEXT DEFAULT NULL,
    p_user_id UUID DEFAULT NULL,
    p_severity TEXT DEFAULT 'error',
    p_context JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
    error_id UUID;
BEGIN
    INSERT INTO butterfly_error_logs (
        error_type, error_message, stack_trace, user_id, severity, error_context
    ) VALUES (
        p_error_type, p_error_message, p_stack_trace, p_user_id, p_severity, p_context
    ) RETURNING id INTO error_id;
    
    RETURN error_id;
END;
$$ LANGUAGE plpgsql;

-- Generate butterfly recommendations for user
CREATE OR REPLACE FUNCTION generate_butterfly_recommendations(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
    user_stats RECORD;
    recommendation_record RECORD;
BEGIN
    -- Get user statistics
    SELECT * INTO user_stats 
    FROM butterfly_user_stats 
    WHERE user_id = p_user_id;
    
    IF NOT FOUND THEN
        RETURN;
    END IF;
    
    -- Clear old recommendations
    DELETE FROM butterfly_recommendations 
    WHERE user_id = p_user_id AND expires_at <= NOW();
    
    -- Recommend next butterfly based on rarity preference
    INSERT INTO butterfly_recommendations (
        user_id, recommendation_type, recommended_item_id, 
        recommendation_score, reasoning
    )
    SELECT 
        p_user_id,
        'next_butterfly',
        bs.id,
        (1.0 - (brc.sort_order::DECIMAL / 6.0)) as score, -- Higher score for lower rarity
        jsonb_build_object(
            'reason', 'Based on collection progress',
            'rarity', bs.rarity,
            'discovery_chance', bs.discovery_chance
        )
    FROM butterfly_species bs
    JOIN butterfly_rarity_config brc ON bs.rarity = brc.rarity
    WHERE bs.is_active = true
    AND bs.id NOT IN (
        SELECT ba.butterfly_id 
        FROM butterfly_album ba 
        WHERE ba.user_id = p_user_id
    )
    ORDER BY bs.discovery_chance DESC
    LIMIT 3;
    
    -- Recommend collection themes
    INSERT INTO butterfly_recommendations (
        user_id, recommendation_type, recommended_item_id,
        recommendation_score, reasoning
    )
    SELECT 
        p_user_id,
        'collection_theme',
        bct.id::TEXT,
        (but.progress::DECIMAL / array_length(bct.butterfly_ids, 1)) as score,
        jsonb_build_object(
            'reason', 'Partially completed theme',
            'progress', but.progress,
            'total', array_length(bct.butterfly_ids, 1),
            'theme_name', bct.theme_name
        )
    FROM butterfly_collection_themes bct
    JOIN butterfly_user_themes but ON bct.id = but.theme_id
    WHERE but.user_id = p_user_id
    AND but.completed_at IS NULL
    AND but.progress > 0
    ORDER BY (but.progress::DECIMAL / array_length(bct.butterfly_ids, 1)) DESC
    LIMIT 2;
END;
$$ LANGUAGE plpgsql;

-- Performance monitoring trigger
CREATE OR REPLACE FUNCTION record_butterfly_performance_metric(
    p_metric_name TEXT,
    p_metric_value DECIMAL,
    p_metric_unit TEXT DEFAULT '',
    p_context JSONB DEFAULT '{}'
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO butterfly_performance_metrics (
        metric_name, metric_value, metric_unit, context
    ) VALUES (
        p_metric_name, p_metric_value, p_metric_unit, p_context
    );
END;
$$ LANGUAGE plpgsql;

-- Clean old analytics and performance data
CREATE OR REPLACE FUNCTION cleanup_butterfly_analytics()
RETURNS VOID AS $$
BEGIN
    -- Keep analytics for 2 years
    DELETE FROM butterfly_analytics WHERE created_at < NOW() - INTERVAL '2 years';
    
    -- Keep user analytics for 1 year
    DELETE FROM butterfly_user_analytics WHERE date < CURRENT_DATE - INTERVAL '1 year';
    
    -- Keep performance metrics for 6 months
    DELETE FROM butterfly_performance_metrics WHERE recorded_at < NOW() - INTERVAL '6 months';
    
    -- Keep error logs for 1 year (except critical ones - keep 3 years)
    DELETE FROM butterfly_error_logs 
    WHERE created_at < NOW() - INTERVAL '1 year' 
    AND severity != 'critical';
    
    DELETE FROM butterfly_error_logs 
    WHERE created_at < NOW() - INTERVAL '3 years' 
    AND severity = 'critical';
    
    -- Clean old cache entries
    PERFORM clean_butterfly_cache();
    
    -- Keep feature usage for 2 years
    DELETE FROM butterfly_feature_usage WHERE first_used < NOW() - INTERVAL '2 years';
    
    -- Clean expired recommendations
    DELETE FROM butterfly_recommendations WHERE expires_at <= NOW();
END;
$$ LANGUAGE plpgsql;

-- Initialize default user preferences
CREATE OR REPLACE FUNCTION init_butterfly_user_preferences(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
    INSERT INTO butterfly_user_preferences (user_id)
    VALUES (p_user_id)
    ON CONFLICT (user_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql;
