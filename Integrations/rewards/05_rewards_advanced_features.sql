-- Crystal Social Rewards System - Advanced Features
-- File: 05_rewards_advanced_features.sql
-- Purpose: Advanced features including leaderboards, statistics, analytics, and optimization

-- =============================================================================
-- LEADERBOARDS AND RANKINGS
-- =============================================================================

-- User leaderboard rankings table
CREATE TABLE IF NOT EXISTS user_leaderboard_rankings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    category VARCHAR(100) NOT NULL, -- level, coins, achievements, purchases, etc.
    current_rank INTEGER NOT NULL CHECK (current_rank > 0),
    previous_rank INTEGER,
    rank_change INTEGER DEFAULT 0,
    current_value INTEGER NOT NULL,
    previous_value INTEGER,
    percentile DECIMAL(5,2),
    tier VARCHAR(50), -- bronze, silver, gold, platinum, diamond, legend
    season VARCHAR(50) DEFAULT 'all_time',
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for leaderboard rankings
CREATE INDEX IF NOT EXISTS idx_user_leaderboard_category ON user_leaderboard_rankings(category);
CREATE INDEX IF NOT EXISTS idx_user_leaderboard_rank ON user_leaderboard_rankings(current_rank);
CREATE INDEX IF NOT EXISTS idx_user_leaderboard_user_id ON user_leaderboard_rankings(user_id);
CREATE INDEX IF NOT EXISTS idx_user_leaderboard_season ON user_leaderboard_rankings(season);
CREATE INDEX IF NOT EXISTS idx_user_leaderboard_tier ON user_leaderboard_rankings(tier);

-- Leaderboard snapshots for historical tracking
CREATE TABLE IF NOT EXISTS leaderboard_snapshots (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    category VARCHAR(100) NOT NULL,
    season VARCHAR(50) NOT NULL,
    snapshot_date DATE NOT NULL,
    top_users JSONB NOT NULL, -- Array of top users with their stats
    total_participants INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for leaderboard snapshots
CREATE INDEX IF NOT EXISTS idx_leaderboard_snapshots_category ON leaderboard_snapshots(category);
CREATE INDEX IF NOT EXISTS idx_leaderboard_snapshots_date ON leaderboard_snapshots(snapshot_date);
CREATE INDEX IF NOT EXISTS idx_leaderboard_snapshots_season ON leaderboard_snapshots(season);

-- =============================================================================
-- COMPREHENSIVE ANALYTICS
-- =============================================================================

-- Daily user activity analytics
CREATE TABLE IF NOT EXISTS daily_user_analytics (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    activity_date DATE NOT NULL,
    coins_earned INTEGER DEFAULT 0,
    coins_spent INTEGER DEFAULT 0,
    points_earned INTEGER DEFAULT 0,
    experience_gained INTEGER DEFAULT 0,
    items_purchased INTEGER DEFAULT 0,
    achievements_unlocked INTEGER DEFAULT 0,
    daily_login_claimed BOOLEAN DEFAULT FALSE,
    booster_packs_opened INTEGER DEFAULT 0,
    messages_sent INTEGER DEFAULT 0,
    games_played INTEGER DEFAULT 0,
    friends_added INTEGER DEFAULT 0,
    time_spent_minutes INTEGER DEFAULT 0,
    sessions_count INTEGER DEFAULT 0,
    last_activity TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Unique constraint on user-date combination
CREATE UNIQUE INDEX IF NOT EXISTS idx_daily_user_analytics_user_date ON daily_user_analytics(user_id, activity_date);

-- Indexes for analytics queries
CREATE INDEX IF NOT EXISTS idx_daily_user_analytics_user_id ON daily_user_analytics(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_user_analytics_date ON daily_user_analytics(activity_date);
CREATE INDEX IF NOT EXISTS idx_daily_user_analytics_coins_earned ON daily_user_analytics(coins_earned);
CREATE INDEX IF NOT EXISTS idx_daily_user_analytics_achievements ON daily_user_analytics(achievements_unlocked);

-- Weekly user analytics summary
CREATE TABLE IF NOT EXISTS weekly_user_analytics (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    week_start_date DATE NOT NULL,
    week_end_date DATE NOT NULL,
    total_coins_earned INTEGER DEFAULT 0,
    total_coins_spent INTEGER DEFAULT 0,
    total_points_earned INTEGER DEFAULT 0,
    total_experience_gained INTEGER DEFAULT 0,
    total_items_purchased INTEGER DEFAULT 0,
    total_achievements_unlocked INTEGER DEFAULT 0,
    days_logged_in INTEGER DEFAULT 0,
    total_booster_packs_opened INTEGER DEFAULT 0,
    total_messages_sent INTEGER DEFAULT 0,
    total_games_played INTEGER DEFAULT 0,
    total_friends_added INTEGER DEFAULT 0,
    total_time_spent_minutes INTEGER DEFAULT 0,
    average_session_length_minutes DECIMAL(8,2) DEFAULT 0,
    engagement_score DECIMAL(5,2) DEFAULT 0, -- Calculated engagement metric
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Unique constraint on user-week combination
CREATE UNIQUE INDEX IF NOT EXISTS idx_weekly_user_analytics_user_week ON weekly_user_analytics(user_id, week_start_date);

-- =============================================================================
-- REWARD OPTIMIZATION AND PERSONALIZATION
-- =============================================================================

-- User preference tracking for personalized rewards
CREATE TABLE IF NOT EXISTS user_reward_preferences (
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE PRIMARY KEY,
    preferred_categories JSONB DEFAULT '[]', -- Array of preferred shop categories
    favorite_item_types JSONB DEFAULT '[]', -- Array of favorite item types
    spending_pattern VARCHAR(50) DEFAULT 'balanced', -- conservative, balanced, spender
    reward_motivation VARCHAR(50) DEFAULT 'achievement', -- achievement, collection, social, competition
    notification_preferences JSONB DEFAULT '{}', -- Notification settings
    activity_patterns JSONB DEFAULT '{}', -- Peak activity times, preferred activities
    goal_orientation VARCHAR(50) DEFAULT 'progression', -- progression, social, collection, completion
    risk_tolerance VARCHAR(50) DEFAULT 'medium', -- low, medium, high (for booster packs)
    personalization_score DECIMAL(5,2) DEFAULT 0.00,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Personalized reward recommendations
CREATE TABLE IF NOT EXISTS personalized_reward_recommendations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    recommendation_type VARCHAR(100) NOT NULL, -- item, achievement, activity, pack
    target_item_id INTEGER REFERENCES shop_items(id),
    target_achievement_id INTEGER REFERENCES achievements(id),
    recommendation_reason TEXT,
    confidence_score DECIMAL(5,2) NOT NULL CHECK (confidence_score >= 0 AND confidence_score <= 100),
    priority_level INTEGER DEFAULT 1 CHECK (priority_level >= 1 AND priority_level <= 5),
    estimated_interest DECIMAL(5,2) DEFAULT 50.00,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_shown BOOLEAN DEFAULT FALSE,
    is_clicked BOOLEAN DEFAULT FALSE,
    is_purchased BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for recommendations
CREATE INDEX IF NOT EXISTS idx_personalized_recommendations_user_id ON personalized_reward_recommendations(user_id);
CREATE INDEX IF NOT EXISTS idx_personalized_recommendations_type ON personalized_reward_recommendations(recommendation_type);
CREATE INDEX IF NOT EXISTS idx_personalized_recommendations_confidence ON personalized_reward_recommendations(confidence_score);
CREATE INDEX IF NOT EXISTS idx_personalized_recommendations_expires ON personalized_reward_recommendations(expires_at);

-- =============================================================================
-- SEASONAL EVENTS AND LIMITED TIME OFFERS
-- =============================================================================

-- Seasonal events table
CREATE TABLE IF NOT EXISTS seasonal_events (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    event_type VARCHAR(100) NOT NULL, -- holiday, special, tournament, challenge
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    bonus_multiplier DECIMAL(3,2) DEFAULT 1.00,
    special_currency VARCHAR(50), -- event tokens, special coins
    theme_colors JSONB DEFAULT '{}',
    exclusive_items JSONB DEFAULT '[]', -- Array of exclusive item IDs
    participation_requirements JSONB DEFAULT '{}',
    rewards_config JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User participation in seasonal events
CREATE TABLE IF NOT EXISTS user_seasonal_participation (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    event_id INTEGER NOT NULL REFERENCES seasonal_events(id),
    participation_start TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    progress_data JSONB DEFAULT '{}',
    rewards_earned JSONB DEFAULT '[]',
    completion_percentage DECIMAL(5,2) DEFAULT 0.00,
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP WITH TIME ZONE,
    special_currency_earned INTEGER DEFAULT 0,
    ranking_position INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Unique constraint on user-event combination
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_seasonal_participation_unique ON user_seasonal_participation(user_id, event_id);

-- =============================================================================
-- WISHLIST AND FAVORITES SYSTEM
-- =============================================================================

-- User wishlist for shop items
CREATE TABLE IF NOT EXISTS user_wishlist (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    item_id INTEGER NOT NULL REFERENCES shop_items(id),
    priority_level INTEGER DEFAULT 1 CHECK (priority_level >= 1 AND priority_level <= 5),
    notes TEXT,
    price_alert_threshold INTEGER, -- Notify if price drops below this
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_viewed TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Unique constraint on user-item combination
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_wishlist_unique ON user_wishlist(user_id, item_id);

-- Indexes for wishlist queries
CREATE INDEX IF NOT EXISTS idx_user_wishlist_user_id ON user_wishlist(user_id);
CREATE INDEX IF NOT EXISTS idx_user_wishlist_priority ON user_wishlist(priority_level);
CREATE INDEX IF NOT EXISTS idx_user_wishlist_price_alert ON user_wishlist(price_alert_threshold);

-- =============================================================================
-- REWARDS PERFORMANCE METRICS
-- =============================================================================

-- System performance metrics for rewards
CREATE TABLE IF NOT EXISTS rewards_performance_metrics (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    metric_date DATE NOT NULL,
    metric_type VARCHAR(100) NOT NULL, -- purchase_rate, engagement, retention, etc.
    metric_value DECIMAL(10,2) NOT NULL,
    metric_target DECIMAL(10,2),
    performance_percentage DECIMAL(5,2),
    additional_data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance metrics
CREATE INDEX IF NOT EXISTS idx_rewards_performance_date ON rewards_performance_metrics(metric_date);
CREATE INDEX IF NOT EXISTS idx_rewards_performance_type ON rewards_performance_metrics(metric_type);

-- =============================================================================
-- VIEWS FOR EASY DATA ACCESS
-- =============================================================================

-- View for user rewards with calculated fields
CREATE OR REPLACE VIEW user_rewards_summary AS
SELECT 
    ur.user_id,
    ur.coins,
    ur.points,
    ur.gems,
    ur.experience,
    ur.level,
    ur.current_streak,
    ur.total_purchased,
    ur.total_spent,
    ur.last_login,
    ulp.current_experience,
    ulp.next_level_experience,
    ulp.progress_percentage,
    ulp.level_up_count,
    uas.total_achievements,
    uas.achievement_score,
    uas.completion_percentage as achievement_completion,
    CASE 
        WHEN ur.current_streak >= 30 THEN 'Legend'
        WHEN ur.current_streak >= 14 THEN 'Dedicated'
        WHEN ur.current_streak >= 7 THEN 'Consistent' 
        WHEN ur.current_streak >= 3 THEN 'Regular'
        ELSE 'Casual'
    END as streak_tier,
    CASE 
        WHEN ur.level >= 50 THEN 'Master'
        WHEN ur.level >= 25 THEN 'Expert'
        WHEN ur.level >= 10 THEN 'Advanced'
        WHEN ur.level >= 5 THEN 'Intermediate'
        ELSE 'Beginner'
    END as level_tier
FROM user_rewards ur
LEFT JOIN user_level_progress ulp ON ur.user_id = ulp.user_id
LEFT JOIN user_achievement_stats uas ON ur.user_id = uas.user_id;

-- View for shop items with enriched data
CREATE OR REPLACE VIEW shop_items_enriched AS
SELECT 
    si.*,
    sc.name as category_name,
    sc.icon_name as category_icon,
    sc.color_code as category_color,
    CASE si.rarity
        WHEN 'common' THEN 1
        WHEN 'uncommon' THEN 2
        WHEN 'rare' THEN 3
        WHEN 'epic' THEN 4
        WHEN 'legendary' THEN 5
        WHEN 'mythic' THEN 6
        ELSE 0
    END as rarity_order,
    (SELECT COUNT(*) FROM user_inventory WHERE item_id::INTEGER = si.id::INTEGER) as owners_count,
    (SELECT COUNT(*) FROM user_wishlist WHERE item_id::INTEGER = si.id::INTEGER) as wishlist_count
FROM shop_items si
LEFT JOIN shop_categories sc ON si.category_id = sc.id;

-- View for leaderboard with user details
CREATE OR REPLACE VIEW leaderboard_with_profiles AS
SELECT 
    ulr.*,
    p.username,
    p.display_name,
    p.avatar_url,
    ur.level,
    ur.coins
FROM user_leaderboard_rankings ulr
LEFT JOIN profiles p ON ulr.user_id = p.id
LEFT JOIN user_rewards ur ON ulr.user_id = ur.user_id
ORDER BY ulr.current_rank;

-- =============================================================================
-- ADVANCED STORED FUNCTIONS
-- =============================================================================

-- Function to calculate user engagement score
CREATE OR REPLACE FUNCTION calculate_user_engagement_score(p_user_id UUID)
RETURNS DECIMAL(5,2) AS $$
DECLARE
    v_engagement_score DECIMAL(5,2) := 0;
    v_login_frequency DECIMAL(5,2);
    v_purchase_activity DECIMAL(5,2);
    v_social_activity DECIMAL(5,2);
    v_achievement_progress DECIMAL(5,2);
    v_days_since_join INTEGER;
    v_weekly_data weekly_user_analytics%ROWTYPE;
BEGIN
    -- Get recent weekly data
    SELECT * INTO v_weekly_data 
    FROM weekly_user_analytics 
    WHERE user_id = p_user_id 
    ORDER BY week_start_date DESC 
    LIMIT 1;
    
    -- Calculate login frequency (0-25 points)
    IF v_weekly_data.days_logged_in IS NOT NULL THEN
        v_login_frequency := (v_weekly_data.days_logged_in::DECIMAL / 7) * 25;
    END IF;
    
    -- Calculate purchase activity (0-25 points)
    IF v_weekly_data.total_items_purchased IS NOT NULL THEN
        v_purchase_activity := LEAST(v_weekly_data.total_items_purchased * 5, 25);
    END IF;
    
    -- Calculate social activity (0-25 points)
    IF v_weekly_data.total_messages_sent IS NOT NULL THEN
        v_social_activity := LEAST(v_weekly_data.total_messages_sent * 0.5, 25);
    END IF;
    
    -- Calculate achievement progress (0-25 points)
    IF v_weekly_data.total_achievements_unlocked IS NOT NULL THEN
        v_achievement_progress := LEAST(v_weekly_data.total_achievements_unlocked * 10, 25);
    END IF;
    
    -- Sum up engagement score
    v_engagement_score := COALESCE(v_login_frequency, 0) + 
                         COALESCE(v_purchase_activity, 0) + 
                         COALESCE(v_social_activity, 0) + 
                         COALESCE(v_achievement_progress, 0);
    
    -- Cap at 100
    v_engagement_score := LEAST(v_engagement_score, 100);
    
    RETURN v_engagement_score;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to generate personalized recommendations
CREATE OR REPLACE FUNCTION generate_personalized_recommendations(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    v_user_rewards user_rewards%ROWTYPE;
    v_preferences user_reward_preferences%ROWTYPE;
    v_recommendations JSON;
    v_recommended_items JSONB := '[]';
    v_item RECORD;
    v_confidence DECIMAL(5,2);
BEGIN
    -- Get user data
    SELECT * INTO v_user_rewards FROM user_rewards WHERE user_id = p_user_id;
    SELECT * INTO v_preferences FROM user_reward_preferences WHERE user_id = p_user_id;
    
    IF v_user_rewards.user_id IS NULL THEN
        RETURN json_build_object('error', 'User not found');
    END IF;
    
    -- Clear old recommendations
    DELETE FROM personalized_reward_recommendations 
    WHERE user_id = p_user_id AND expires_at < NOW();
    
    -- Generate item recommendations based on user preferences and affordability
    FOR v_item IN 
        SELECT si.*, sc.name as category_name
        FROM shop_items si
        JOIN shop_categories sc ON si.category_id = sc.id
        WHERE si.is_available = true
        AND si.price <= v_user_rewards.coins * 2 -- Include items up to 2x current coins
        AND si.requires_level <= v_user_rewards.level
        AND NOT EXISTS (
            SELECT 1 FROM user_inventory 
            WHERE user_id = p_user_id AND item_id = si.id
        )
        ORDER BY RANDOM()
        LIMIT 10
    LOOP
        -- Calculate confidence based on affordability and user preferences
        v_confidence := 50; -- Base confidence
        
        -- Boost if affordable
        IF v_item.price <= v_user_rewards.coins THEN
            v_confidence := v_confidence + 30;
        END IF;
        
        -- Boost if in wishlist
        IF EXISTS (SELECT 1 FROM user_wishlist WHERE user_id = p_user_id AND item_id = v_item.id) THEN
            v_confidence := v_confidence + 40;
        END IF;
        
        -- Boost based on rarity preference (assuming users like rare items)
        CASE v_item.rarity
            WHEN 'rare' THEN v_confidence := v_confidence + 10;
            WHEN 'epic' THEN v_confidence := v_confidence + 15;
            WHEN 'legendary' THEN v_confidence := v_confidence + 20;
            ELSE v_confidence := v_confidence + 5;
        END CASE;
        
        -- Cap confidence at 95
        v_confidence := LEAST(v_confidence, 95);
        
        -- Add to recommendations if confidence is high enough
        IF v_confidence >= 60 THEN
            INSERT INTO personalized_reward_recommendations (
                user_id, recommendation_type, target_item_id, 
                recommendation_reason, confidence_score, 
                estimated_interest, expires_at
            ) VALUES (
                p_user_id, 'item', v_item.id,
                'Based on your level, coins, and preferences',
                v_confidence, v_confidence,
                NOW() + INTERVAL '7 days'
            );
            
            v_recommended_items := v_recommended_items || jsonb_build_object(
                'item_id', v_item.id,
                'name', v_item.name,
                'price', v_item.price,
                'rarity', v_item.rarity,
                'category', v_item.category_name,
                'confidence', v_confidence
            );
        END IF;
    END LOOP;
    
    v_recommendations := json_build_object(
        'user_id', p_user_id,
        'generated_at', NOW(),
        'recommendations', v_recommended_items,
        'total_count', jsonb_array_length(v_recommended_items)
    );
    
    RETURN v_recommendations;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- ROW LEVEL SECURITY
-- =============================================================================

-- Enable RLS on advanced tables
ALTER TABLE user_leaderboard_rankings ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_user_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_user_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_reward_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE personalized_reward_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_seasonal_participation ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_wishlist ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own leaderboard data" ON user_leaderboard_rankings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can view their own analytics" ON daily_user_analytics FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can view their own weekly analytics" ON weekly_user_analytics FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own preferences" ON user_reward_preferences FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can view their own recommendations" ON personalized_reward_recommendations FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can view their own event participation" ON user_seasonal_participation FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own wishlist" ON user_wishlist FOR ALL USING (auth.uid() = user_id);

-- Public access for seasonal events and performance metrics
CREATE POLICY "Seasonal events are viewable by everyone" ON seasonal_events FOR SELECT USING (true);
CREATE POLICY "Performance metrics are viewable by authenticated users" ON rewards_performance_metrics FOR SELECT USING (auth.role() = 'authenticated');

-- =============================================================================
-- GRANT PERMISSIONS
-- =============================================================================

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION calculate_user_engagement_score(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION generate_personalized_recommendations(UUID) TO authenticated;

-- Grant view access
GRANT SELECT ON user_rewards_summary TO authenticated;
GRANT SELECT ON shop_items_enriched TO authenticated;
GRANT SELECT ON leaderboard_with_profiles TO authenticated;

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE user_leaderboard_rankings IS 'Rankings and leaderboard positions for users across different categories';
COMMENT ON TABLE daily_user_analytics IS 'Daily activity tracking for comprehensive user analytics';
COMMENT ON TABLE weekly_user_analytics IS 'Weekly summary analytics with engagement scoring';
COMMENT ON TABLE user_reward_preferences IS 'User preferences for personalized reward recommendations';
COMMENT ON TABLE personalized_reward_recommendations IS 'AI-generated personalized recommendations for users';
COMMENT ON TABLE seasonal_events IS 'Special events and limited-time challenges';
COMMENT ON TABLE user_wishlist IS 'User wishlist for tracking desired shop items';
COMMENT ON VIEW user_rewards_summary IS 'Comprehensive view of user rewards with calculated tiers';
COMMENT ON VIEW shop_items_enriched IS 'Shop items with additional metadata and popularity metrics';
COMMENT ON FUNCTION calculate_user_engagement_score(UUID) IS 'Calculates a 0-100 engagement score based on user activity';
COMMENT ON FUNCTION generate_personalized_recommendations(UUID) IS 'Generates personalized item recommendations based on user behavior';
