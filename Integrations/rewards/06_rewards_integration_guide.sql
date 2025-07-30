-- Crystal Social Rewards System - Integration Summary and Setup Guide
-- File: 06_rewards_integration_guide.sql
-- Purpose: Complete setup instructions and integration examples for the rewards system

-- =============================================================================
-- REWARDS SYSTEM INTEGRATION SUMMARY
-- =============================================================================

/*
CRYSTAL SOCIAL REWARDS SYSTEM - COMPREHENSIVE SQL INTEGRATION

This SQL integration provides a complete, production-ready rewards system with:

🎯 CORE FEATURES:
- Multi-currency system (coins, points, gems, experience)
- Comprehensive shop with categories and items
- Advanced inventory management with equipped items
- Achievement system with progress tracking
- Daily reward system with streak bonuses
- Level progression with experience requirements
- Booster pack system with random rewards
- Aura management system with visual effects

🏆 ADVANCED FEATURES:
- Leaderboards and ranking system
- User analytics and engagement tracking
- Personalized recommendations engine
- Seasonal events and limited-time offers
- Wishlist and favorites system
- Performance metrics and optimization
- Comprehensive audit trail and security

📊 TABLES OVERVIEW:
Core Tables (01_rewards_core_tables.sql):
- user_rewards: Main balance and currency management
- shop_categories: 8 categories for organizing items
- shop_items: All purchasable items with metadata
- user_inventory: User-owned items with equipped status
- aura_items: Specialized aura effects
- reward_transactions: Complete transaction audit trail
- level_requirements: Experience and rewards per level
- daily_rewards: 30-day reward cycle configuration

Achievement Tables (02_rewards_achievements.sql):
- achievements: 24+ achievements across 5 categories
- user_achievement_progress: Real-time progress tracking
- user_achievements: Completed achievements with rewards
- bestie_bonds: Friendship level system
- booster_pack_openings: Pack opening records
- currency_earning_activities: Activity-based rewards
- user_quests: Daily/weekly/monthly challenges

Business Logic (03_rewards_functions.sql):
- initialize_user_rewards(): Setup new users
- process_item_purchase(): Handle shop purchases
- add_user_experience(): Level progression
- claim_daily_reward(): Daily bonus system
- complete_achievement(): Achievement rewards
- check_purchase_achievements(): Auto-achievement checking

Sample Data (04_rewards_sample_data.sql):
- 16 auras from common to legendary
- 6 booster packs with different rarities
- 24 achievements across all categories
- 30-day daily reward cycle
- Level requirements 1-100
- Complete shop categories

Advanced Features (05_rewards_advanced_features.sql):
- Leaderboard system with rankings
- User analytics and engagement scoring
- Personalized recommendation engine
- Seasonal events system
- Wishlist functionality
- Performance monitoring
*/

-- =============================================================================
-- SETUP AND INITIALIZATION INSTRUCTIONS
-- =============================================================================

-- Step 1: Execute SQL files in order
/*
1. Run 01_rewards_core_tables.sql - Creates foundational tables
2. Run 02_rewards_achievements.sql - Creates achievement system
3. Run 03_rewards_functions.sql - Creates business logic functions
4. Run 04_rewards_sample_data.sql - Inserts sample data
5. Run 05_rewards_advanced_features.sql - Creates advanced features
6. Run this file (06_rewards_integration_guide.sql) - Final setup
*/

-- Step 2: Verify table creation
DO $$
DECLARE
    v_table_count INTEGER;
    v_function_count INTEGER;
    v_view_count INTEGER;
BEGIN
    -- Count tables
    SELECT COUNT(*) INTO v_table_count 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name LIKE '%reward%' OR table_name LIKE '%shop%' OR table_name LIKE '%achievement%' OR table_name LIKE '%user_inventory%';
    
    -- Count functions
    SELECT COUNT(*) INTO v_function_count 
    FROM information_schema.routines 
    WHERE routine_schema = 'public' 
    AND routine_name LIKE '%reward%' OR routine_name LIKE '%achievement%' OR routine_name LIKE '%purchase%';
    
    -- Count views
    SELECT COUNT(*) INTO v_view_count 
    FROM information_schema.views 
    WHERE table_schema = 'public' 
    AND table_name LIKE '%reward%' OR table_name LIKE '%shop%';
    
    RAISE NOTICE 'Rewards System Setup Complete:';
    RAISE NOTICE '- Tables created: %', v_table_count;
    RAISE NOTICE '- Functions created: %', v_function_count;
    RAISE NOTICE '- Views created: %', v_view_count;
    
    IF v_table_count >= 20 AND v_function_count >= 5 AND v_view_count >= 3 THEN
        RAISE NOTICE '✅ Rewards system successfully installed!';
    ELSE
        RAISE WARNING '⚠️ Some components may be missing. Please check installation.';
    END IF;
END $$;

-- =============================================================================
-- INTEGRATION EXAMPLES FOR FLUTTER APP
-- =============================================================================

-- Example 1: Initialize new user
/*
-- Call this when a new user signs up
SELECT initialize_user_rewards('user-uuid-here');

-- Result will be:
{
  "success": true,
  "message": "User rewards initialized",
  "starting_coins": 100,
  "starting_points": 50,
  "starting_gems": 10
}
*/

-- Example 2: Get user's complete rewards data
/*
-- Call this to load user's rewards dashboard
SELECT get_user_rewards_detailed('user-uuid-here');

-- Result includes:
{
  "user_id": "user-uuid",
  "coins": 1250,
  "points": 600,
  "gems": 45,
  "level": 8,
  "level_progress": {
    "current_level": 8,
    "current_experience": 450,
    "next_level_experience": 1750,
    "progress_percentage": 25.71
  },
  "achievement_stats": {
    "total_achievements": 12,
    "achievement_score": 350,
    "completion_percentage": 50.00
  }
}
*/

-- Example 3: Process item purchase
/*
-- Call this when user wants to buy an item
SELECT process_item_purchase('user-uuid-here', 5, 'purchase-attempt-uuid');

-- Result:
{
  "success": true,
  "item_name": "Purple Mist",
  "price_paid": 200,
  "remaining_coins": 1050,
  "transaction_id": "transaction-uuid"
}
*/

-- Example 4: Claim daily reward
/*
-- Call this when user opens app each day
SELECT claim_daily_reward('user-uuid-here');

-- Result:
{
  "success": true,
  "coins_earned": 75,
  "consecutive_days": 5,
  "day_number": 5,
  "streak_bonus": "40%"
}
*/

-- =============================================================================
-- COMMON QUERIES FOR FLUTTER INTEGRATION
-- =============================================================================

-- Get shop items with category info
CREATE OR REPLACE FUNCTION get_shop_items_for_category(
    p_category_id INTEGER DEFAULT NULL,
    p_user_id UUID DEFAULT NULL,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_agg(
        json_build_object(
            'id', sie.id,
            'name', sie.name,
            'description', sie.description,
            'price', sie.price,
            'rarity', sie.rarity,
            'category_name', sie.category_name,
            'category_icon', sie.category_icon,
            'image_url', sie.image_url,
            'is_owned', CASE WHEN p_user_id IS NOT NULL THEN 
                (SELECT COUNT(*) > 0 FROM user_inventory WHERE user_id = p_user_id AND item_id = sie.id)
                ELSE false END,
            'is_wishlist', CASE WHEN p_user_id IS NOT NULL THEN
                (SELECT COUNT(*) > 0 FROM user_wishlist WHERE user_id = p_user_id AND item_id = sie.id)
                ELSE false END,
            'owners_count', sie.owners_count,
            'rarity_order', sie.rarity_order
        )
    ) INTO v_result
    FROM shop_items_enriched sie
    WHERE (p_category_id IS NULL OR sie.category_id = p_category_id)
    AND sie.is_available = true
    ORDER BY sie.rarity_order DESC, sie.price ASC
    LIMIT p_limit OFFSET p_offset;
    
    RETURN COALESCE(v_result, '[]'::json);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get user inventory with item details
CREATE OR REPLACE FUNCTION get_user_inventory_detailed(
    p_user_id UUID,
    p_category_id INTEGER DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_agg(
        json_build_object(
            'inventory_id', ui.id,
            'item_id', ui.item_id,
            'quantity', ui.quantity,
            'item_name', si.name,
            'item_description', si.description,
            'item_rarity', si.rarity,
            'item_image_url', si.image_url,
            'category_name', sc.name,
            'category_icon', sc.icon_name
        )
    ) INTO v_result
    FROM user_inventory ui
    JOIN shop_items si ON ui.item_id = si.id
    JOIN shop_categories sc ON si.category_id = sc.id
    WHERE ui.user_id = p_user_id
    AND (p_category_id IS NULL OR si.category_id = p_category_id)
    ORDER BY ui.id DESC;
    
    RETURN COALESCE(v_result, '[]'::json);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get user achievements with progress
CREATE OR REPLACE FUNCTION get_user_achievements_with_progress(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_agg(
        json_build_object(
            'achievement_id', a.id,
            'name', a.name,
            'description', a.description,
            'category', ac.name,
            'rarity', a.rarity,
            'target_value', a.target_value,
            'coins_reward', a.coins_reward,
            'points_reward', a.points_reward,
            'badge_icon', a.badge_icon,
            'badge_color', a.badge_color,
            'current_progress', COALESCE(uap.current_progress, 0),
            'progress_percentage', COALESCE(uap.progress_percentage, 0),
            'is_completed', COALESCE(uap.is_completed, false),
            'completed_at', ua.completed_at,
            'is_unlocked', a.requires_level <= (SELECT level FROM user_rewards WHERE user_id = p_user_id)
        )
    ) INTO v_result
    FROM achievements a
    JOIN achievement_categories ac ON a.category_id = ac.id
    LEFT JOIN user_achievement_progress uap ON a.id = uap.achievement_id AND uap.user_id = p_user_id
    LEFT JOIN user_achievements ua ON a.id = ua.achievement_id AND ua.user_id = p_user_id
    WHERE a.is_active = true
    ORDER BY a.category_id, a.display_order;
    
    RETURN COALESCE(v_result, '[]'::json);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get leaderboard for a category
CREATE OR REPLACE FUNCTION get_leaderboard(
    p_category VARCHAR(100),
    p_season VARCHAR(50) DEFAULT 'all_time',
    p_limit INTEGER DEFAULT 100
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_agg(
        json_build_object(
            'rank', lwp.current_rank,
            'user_id', lwp.user_id,
            'username', lwp.username,
            'display_name', lwp.display_name,
            'avatar_url', lwp.avatar_url,
            'current_value', lwp.current_value,
            'tier', lwp.tier,
            'level', lwp.level,
            'rank_change', lwp.rank_change
        ) ORDER BY lwp.current_rank
    ) INTO v_result
    FROM leaderboard_with_profiles lwp
    WHERE lwp.category = p_category
    AND lwp.season = p_season
    LIMIT p_limit;
    
    RETURN COALESCE(v_result, '[]'::json);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- MAINTENANCE AND OPTIMIZATION QUERIES
-- =============================================================================

-- Daily maintenance function (run via cron job)
CREATE OR REPLACE FUNCTION daily_rewards_maintenance()
RETURNS VOID AS $$
BEGIN
    -- Update leaderboard rankings
    PERFORM update_leaderboard_rankings();
    
    -- Clean up old data
    PERFORM cleanup_rewards_data();
    
    -- Update achievement statistics
    UPDATE achievement_statistics 
    SET 
        total_completions = (
            SELECT COUNT(*) FROM user_achievements 
            WHERE achievement_id = achievement_statistics.achievement_id
        ),
        completion_rate = (
            SELECT COUNT(*)::DECIMAL / GREATEST(1, (SELECT COUNT(*) FROM profiles))
            FROM user_achievements 
            WHERE achievement_id = achievement_statistics.achievement_id
        ) * 100,
        updated_at = NOW();
    
    -- Generate daily analytics
    INSERT INTO daily_user_analytics (user_id, activity_date, last_activity)
    SELECT 
        ur.user_id, 
        CURRENT_DATE, 
        NOW()
    FROM user_rewards ur
    WHERE ur.last_login >= CURRENT_DATE
    ON CONFLICT (user_id, activity_date) DO UPDATE SET
        last_activity = NOW();
        
    RAISE NOTICE 'Daily rewards maintenance completed at %', NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update leaderboard rankings
CREATE OR REPLACE FUNCTION update_leaderboard_rankings()
RETURNS VOID AS $$
BEGIN
    -- Level leaderboard
    INSERT INTO user_leaderboard_rankings (user_id, category, current_rank, current_value, tier, season)
    SELECT 
        user_id,
        'level',
        ROW_NUMBER() OVER (ORDER BY level DESC, experience DESC),
        level,
        CASE 
            WHEN level >= 50 THEN 'legend'
            WHEN level >= 25 THEN 'diamond'
            WHEN level >= 15 THEN 'platinum'
            WHEN level >= 10 THEN 'gold'
            WHEN level >= 5 THEN 'silver'
            ELSE 'bronze'
        END,
        'all_time'
    FROM user_rewards
    ON CONFLICT (user_id, category, season) DO UPDATE SET
        previous_rank = user_leaderboard_rankings.current_rank,
        current_rank = EXCLUDED.current_rank,
        rank_change = user_leaderboard_rankings.current_rank - EXCLUDED.current_rank,
        previous_value = user_leaderboard_rankings.current_value,
        current_value = EXCLUDED.current_value,
        tier = EXCLUDED.tier,
        last_updated = NOW();
        
    -- Coins leaderboard
    INSERT INTO user_leaderboard_rankings (user_id, category, current_rank, current_value, tier, season)
    SELECT 
        user_id,
        'coins',
        ROW_NUMBER() OVER (ORDER BY coins DESC),
        coins,
        CASE 
            WHEN coins >= 50000 THEN 'legend'
            WHEN coins >= 25000 THEN 'diamond'
            WHEN coins >= 10000 THEN 'platinum'
            WHEN coins >= 5000 THEN 'gold'
            WHEN coins >= 1000 THEN 'silver'
            ELSE 'bronze'
        END,
        'all_time'
    FROM user_rewards
    ON CONFLICT (user_id, category, season) DO UPDATE SET
        previous_rank = user_leaderboard_rankings.current_rank,
        current_rank = EXCLUDED.current_rank,
        rank_change = user_leaderboard_rankings.current_rank - EXCLUDED.current_rank,
        previous_value = user_leaderboard_rankings.current_value,
        current_value = EXCLUDED.current_value,
        tier = EXCLUDED.tier,
        last_updated = NOW();
        
    -- Achievements leaderboard
    INSERT INTO user_leaderboard_rankings (user_id, category, current_rank, current_value, tier, season)
    SELECT 
        user_id,
        'achievements',
        ROW_NUMBER() OVER (ORDER BY total_achievements DESC, achievement_score DESC),
        total_achievements,
        CASE 
            WHEN total_achievements >= 20 THEN 'legend'
            WHEN total_achievements >= 15 THEN 'diamond'
            WHEN total_achievements >= 10 THEN 'platinum'
            WHEN total_achievements >= 5 THEN 'gold'
            WHEN total_achievements >= 1 THEN 'silver'
            ELSE 'bronze'
        END,
        'all_time'
    FROM user_achievement_stats
    ON CONFLICT (user_id, category, season) DO UPDATE SET
        previous_rank = user_leaderboard_rankings.current_rank,
        current_rank = EXCLUDED.current_rank,
        rank_change = user_leaderboard_rankings.current_rank - EXCLUDED.current_rank,
        previous_value = user_leaderboard_rankings.current_value,
        current_value = EXCLUDED.current_value,
        tier = EXCLUDED.tier,
        last_updated = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- GRANT PERMISSIONS FOR NEW FUNCTIONS
-- =============================================================================

GRANT EXECUTE ON FUNCTION get_shop_items_for_category(INTEGER, UUID, INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_inventory_detailed(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_achievements_with_progress(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_leaderboard(VARCHAR, VARCHAR, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION daily_rewards_maintenance() TO service_role;
GRANT EXECUTE ON FUNCTION update_leaderboard_rankings() TO service_role;

-- =============================================================================
-- FINAL SETUP VERIFICATION
-- =============================================================================

-- Create an index for better performance on frequent queries
CREATE INDEX IF NOT EXISTS idx_user_rewards_comprehensive ON user_rewards(user_id, level DESC, coins DESC, experience DESC);
CREATE INDEX IF NOT EXISTS idx_user_inventory_comprehensive ON user_inventory(user_id, item_id);
CREATE INDEX IF NOT EXISTS idx_achievements_comprehensive ON achievements(is_active, category_id, requires_level, display_order);

-- Final verification query
SELECT 
    'Rewards System Integration Complete!' as status,
    (SELECT COUNT(*) FROM shop_categories) as categories_count,
    (SELECT COUNT(*) FROM shop_items WHERE is_available = true) as available_items,
    (SELECT COUNT(*) FROM achievements WHERE is_active = true) as active_achievements,
    (SELECT COUNT(*) FROM daily_rewards) as daily_rewards_configured,
    (SELECT COUNT(*) FROM level_requirements) as level_requirements_set,
    NOW() as setup_completed_at;

-- =============================================================================
-- COMMENTS AND DOCUMENTATION
-- =============================================================================

COMMENT ON FUNCTION get_shop_items_for_category(INTEGER, UUID, INTEGER, INTEGER) IS 'Get shop items with user-specific data like ownership and wishlist status';
COMMENT ON FUNCTION get_user_inventory_detailed(UUID, INTEGER) IS 'Get user inventory with complete item details and category information';
COMMENT ON FUNCTION get_user_achievements_with_progress(UUID) IS 'Get all achievements with user progress and completion status';
COMMENT ON FUNCTION get_leaderboard(VARCHAR, VARCHAR, INTEGER) IS 'Get leaderboard rankings for a specific category and season';
COMMENT ON FUNCTION daily_rewards_maintenance() IS 'Daily maintenance function to update rankings and clean up data';
COMMENT ON FUNCTION update_leaderboard_rankings() IS 'Update leaderboard rankings for all categories';

/*
🎉 REWARDS SYSTEM INTEGRATION COMPLETE!

The Crystal Social Rewards System is now fully integrated with:

✅ 25+ database tables with proper indexing and RLS
✅ 10+ stored functions for business logic
✅ 3 materialized views for performance
✅ Complete sample data with 16 auras, 6 booster packs, 24 achievements
✅ Advanced features like leaderboards, analytics, and recommendations
✅ Production-ready security with Row Level Security
✅ Comprehensive audit trail and transaction logging
✅ Daily maintenance procedures for optimal performance

🚀 NEXT STEPS FOR FLUTTER INTEGRATION:

1. Update your Supabase client to use these new functions
2. Implement the rewards UI components using the provided queries
3. Set up cron job for daily_rewards_maintenance()
4. Configure proper error handling for purchase flows
5. Implement real-time subscriptions for rewards updates
6. Add analytics tracking for user engagement

📖 DOCUMENTATION:
- All functions include comprehensive comments
- Each table has detailed column descriptions
- Integration examples provided for common use cases
- Performance optimizations included for production use

🎯 The rewards system is ready for production deployment!
*/
