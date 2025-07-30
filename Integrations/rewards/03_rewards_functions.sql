-- Crystal Social Rewards System - Business Logic Functions
-- File: 03_rewards_functions.sql
-- Purpose: Stored functions for rewards operations, purchases, and calculations

-- =============================================================================
-- USER REWARDS INITIALIZATION AND MANAGEMENT
-- =============================================================================

-- Function to initialize user rewards
CREATE OR REPLACE FUNCTION initialize_user_rewards(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
    v_existing_record user_rewards%ROWTYPE;
BEGIN
    -- Check if user already has rewards record
    SELECT * INTO v_existing_record FROM user_rewards WHERE user_id = p_user_id;
    
    IF v_existing_record.user_id IS NULL THEN
        -- Create new rewards record with starting bonus
        INSERT INTO user_rewards (
            user_id, 
            coins, 
            points, 
            gems, 
            experience, 
            level,
            last_login,
            created_at
        ) VALUES (
            p_user_id, 
            100, -- Starting coins
            50,  -- Starting points
            10,  -- Starting gems
            0,   -- Starting experience
            1,   -- Starting level
            NOW(),
            NOW()
        );
        
        -- Initialize level progress
        INSERT INTO user_level_progress (
            user_id,
            current_level,
            current_experience,
            total_experience,
            next_level_experience
        ) VALUES (
            p_user_id,
            1,
            0,
            0,
            100 -- Experience needed for level 2
        );
        
        -- Initialize achievement stats
        INSERT INTO user_achievement_stats (user_id) VALUES (p_user_id);
        
        -- Initialize booster pack stats
        INSERT INTO booster_pack_statistics (user_id) VALUES (p_user_id);
        
        v_result := json_build_object(
            'success', true,
            'message', 'User rewards initialized',
            'starting_coins', 100,
            'starting_points', 50,
            'starting_gems', 10
        );
    ELSE
        v_result := json_build_object(
            'success', true,
            'message', 'User rewards already exist',
            'coins', v_existing_record.coins,
            'points', v_existing_record.points,
            'gems', v_existing_record.gems
        );
    END IF;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user rewards with calculated fields
CREATE OR REPLACE FUNCTION get_user_rewards_detailed(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    v_rewards user_rewards%ROWTYPE;
    v_level_progress user_level_progress%ROWTYPE;
    v_achievement_stats user_achievement_stats%ROWTYPE;
    v_result JSON;
BEGIN
    -- Get rewards data
    SELECT * INTO v_rewards FROM user_rewards WHERE user_id = p_user_id;
    
    IF v_rewards.user_id IS NULL THEN
        -- Initialize if doesn't exist
        PERFORM initialize_user_rewards(p_user_id);
        SELECT * INTO v_rewards FROM user_rewards WHERE user_id = p_user_id;
    END IF;
    
    -- Get level progress
    SELECT * INTO v_level_progress FROM user_level_progress WHERE user_id = p_user_id;
    
    -- Get achievement stats
    SELECT * INTO v_achievement_stats FROM user_achievement_stats WHERE user_id = p_user_id;
    
    -- Build comprehensive result
    v_result := json_build_object(
        'user_id', v_rewards.user_id,
        'coins', v_rewards.coins,
        'points', v_rewards.points,
        'gems', v_rewards.gems,
        'experience', v_rewards.experience,
        'level', v_rewards.level,
        'current_streak', v_rewards.current_streak,
        'total_purchased', v_rewards.total_purchased,
        'total_spent', v_rewards.total_spent,
        'last_login', v_rewards.last_login,
        'level_progress', json_build_object(
            'current_level', COALESCE(v_level_progress.current_level, 1),
            'current_experience', COALESCE(v_level_progress.current_experience, 0),
            'total_experience', COALESCE(v_level_progress.total_experience, 0),
            'next_level_experience', COALESCE(v_level_progress.next_level_experience, 100),
            'progress_percentage', COALESCE(v_level_progress.progress_percentage, 0.00),
            'level_up_count', COALESCE(v_level_progress.level_up_count, 0)
        ),
        'achievement_stats', json_build_object(
            'total_achievements', COALESCE(v_achievement_stats.total_achievements, 0),
            'achievement_score', COALESCE(v_achievement_stats.achievement_score, 0),
            'completion_percentage', COALESCE(v_achievement_stats.completion_percentage, 0.00),
            'coins_from_achievements', COALESCE(v_achievement_stats.total_coins_from_achievements, 0)
        )
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- PURCHASE SYSTEM FUNCTIONS
-- =============================================================================

-- Function to process item purchase
CREATE OR REPLACE FUNCTION process_item_purchase(
    p_user_id UUID,
    p_item_id INTEGER,
    p_purchase_attempt_id UUID DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_user_rewards user_rewards%ROWTYPE;
    v_shop_item shop_items%ROWTYPE;
    v_existing_item user_inventory%ROWTYPE;
    v_transaction_id UUID;
    v_result JSON;
    v_can_afford BOOLEAN := FALSE;
    v_attempt_id UUID;
BEGIN
    -- Generate attempt ID if not provided
    v_attempt_id := COALESCE(p_purchase_attempt_id, uuid_generate_v4());
    
    -- Get user rewards
    SELECT * INTO v_user_rewards FROM user_rewards WHERE user_id = p_user_id;
    
    IF v_user_rewards.user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User rewards not found');
    END IF;
    
    -- Get shop item
    SELECT * INTO v_shop_item FROM shop_items WHERE id = p_item_id AND is_available = true;
    
    IF v_shop_item.id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Item not found or not available');
    END IF;
    
    -- Check if user can afford the item
    v_can_afford := v_user_rewards.coins >= v_shop_item.price;
    
    IF NOT v_can_afford THEN
        -- Log failed purchase attempt
        INSERT INTO purchase_audit (
            user_id, item_id, purchase_attempt_id, status, payment_amount, 
            currency_type, error_code, error_message
        ) VALUES (
            p_user_id, p_item_id, v_attempt_id, 'failed', v_shop_item.price,
            'coins', 'INSUFFICIENT_FUNDS', 'User does not have enough coins'
        );
        
        RETURN json_build_object(
            'success', false, 
            'error', 'Insufficient coins',
            'required', v_shop_item.price,
            'available', v_user_rewards.coins
        );
    END IF;
    
    -- Check if user already owns the item (for non-stackable items)
    SELECT * INTO v_existing_item FROM user_inventory 
    WHERE user_id = p_user_id AND item_id = p_item_id;
    
    -- Begin transaction processing
    BEGIN
        -- Create transaction record
        v_transaction_id := uuid_generate_v4();
        
        INSERT INTO reward_transactions (
            id, user_id, transaction_type, amount, item_id, source,
            before_balance, after_balance, created_at
        ) VALUES (
            v_transaction_id, p_user_id, 'coins', -v_shop_item.price, p_item_id, 'purchase',
            v_user_rewards.coins, v_user_rewards.coins - v_shop_item.price, NOW()
        );
        
        -- Update user coins
        UPDATE user_rewards 
        SET 
            coins = coins - v_shop_item.price,
            total_purchased = total_purchased + 1,
            total_spent = total_spent + v_shop_item.price,
            updated_at = NOW()
        WHERE user_id = p_user_id;
        
        -- Add item to inventory or update quantity
        IF v_existing_item.id IS NULL THEN
            INSERT INTO user_inventory (
                user_id, item_id, quantity, source, purchased_at
            ) VALUES (
                p_user_id, p_item_id, 1, 'purchase', NOW()
            );
        ELSE
            UPDATE user_inventory 
            SET quantity = quantity + 1, purchased_at = NOW()
            WHERE user_id = p_user_id AND item_id = p_item_id;
        END IF;
        
        -- Log successful purchase
        INSERT INTO purchase_audit (
            user_id, item_id, purchase_attempt_id, attempt_timestamp, 
            completion_timestamp, status, payment_amount, currency_type
        ) VALUES (
            p_user_id, p_item_id, v_attempt_id, NOW(), NOW(),
            'completed', v_shop_item.price, 'coins'
        );
        
        -- Check for purchase-related achievements
        PERFORM check_purchase_achievements(p_user_id);
        
        v_result := json_build_object(
            'success', true,
            'message', 'Purchase completed successfully',
            'item_name', v_shop_item.name,
            'price_paid', v_shop_item.price,
            'remaining_coins', v_user_rewards.coins - v_shop_item.price,
            'transaction_id', v_transaction_id
        );
        
    EXCEPTION WHEN OTHERS THEN
        -- Log failed purchase
        INSERT INTO purchase_audit (
            user_id, item_id, purchase_attempt_id, status, payment_amount,
            currency_type, error_code, error_message
        ) VALUES (
            p_user_id, p_item_id, v_attempt_id, 'failed', v_shop_item.price,
            'coins', 'TRANSACTION_ERROR', SQLERRM
        );
        
        RETURN json_build_object(
            'success', false,
            'error', 'Transaction failed: ' || SQLERRM
        );
    END;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- EXPERIENCE AND LEVELING FUNCTIONS
-- =============================================================================

-- Function to add experience and handle level ups
CREATE OR REPLACE FUNCTION add_user_experience(
    p_user_id UUID,
    p_experience INTEGER,
    p_source VARCHAR(100) DEFAULT 'activity'
)
RETURNS JSON AS $$
DECLARE
    v_level_progress user_level_progress%ROWTYPE;
    v_user_rewards user_rewards%ROWTYPE;
    v_new_experience INTEGER;
    v_new_total_experience INTEGER;
    v_current_level INTEGER;
    v_level_ups INTEGER := 0;
    v_coins_rewarded INTEGER := 0;
    v_result JSON;
BEGIN
    -- Get current progress
    SELECT * INTO v_level_progress FROM user_level_progress WHERE user_id = p_user_id;
    SELECT * INTO v_user_rewards FROM user_rewards WHERE user_id = p_user_id;
    
    IF v_level_progress.user_id IS NULL THEN
        -- Initialize if doesn't exist
        PERFORM initialize_user_rewards(p_user_id);
        SELECT * INTO v_level_progress FROM user_level_progress WHERE user_id = p_user_id;
        SELECT * INTO v_user_rewards FROM user_rewards WHERE user_id = p_user_id;
    END IF;
    
    -- Calculate new experience
    v_new_experience := v_level_progress.current_experience + p_experience;
    v_new_total_experience := v_level_progress.total_experience + p_experience;
    v_current_level := v_level_progress.current_level;
    
    -- Check for level ups (simple formula: level * 100 experience per level)
    WHILE v_new_experience >= (v_current_level * 100) LOOP
        v_new_experience := v_new_experience - (v_current_level * 100);
        v_current_level := v_current_level + 1;
        v_level_ups := v_level_ups + 1;
        v_coins_rewarded := v_coins_rewarded + 100; -- 100 coins per level up
    END LOOP;
    
    -- Update level progress
    UPDATE user_level_progress 
    SET 
        current_level = v_current_level,
        current_experience = v_new_experience,
        total_experience = v_new_total_experience,
        level_up_count = level_up_count + v_level_ups,
        next_level_experience = v_current_level * 100,
        progress_percentage = (v_new_experience::DECIMAL / (v_current_level * 100)) * 100,
        last_level_up = CASE WHEN v_level_ups > 0 THEN NOW() ELSE last_level_up END,
        updated_at = NOW()
    WHERE user_id = p_user_id;
    
    -- Update user rewards with new level and experience
    UPDATE user_rewards 
    SET 
        level = v_current_level,
        experience = v_new_total_experience,
        coins = CASE WHEN v_level_ups > 0 THEN coins + v_coins_rewarded ELSE coins END,
        updated_at = NOW()
    WHERE user_id = p_user_id;
    
    -- Log experience transaction
    INSERT INTO reward_transactions (
        user_id, transaction_type, amount, source, description, created_at
    ) VALUES (
        p_user_id, 'experience', p_experience, p_source, 
        'Experience gained from ' || p_source, NOW()
    );
    
    -- Log level up rewards if any
    IF v_level_ups > 0 THEN
        INSERT INTO reward_transactions (
            user_id, transaction_type, amount, source, description, created_at
        ) VALUES (
            p_user_id, 'coins', v_coins_rewarded, 'level_up',
            'Level up rewards for reaching level ' || v_current_level, NOW()
        );
    END IF;
    
    v_result := json_build_object(
        'success', true,
        'experience_added', p_experience,
        'new_level', v_current_level,
        'level_ups', v_level_ups,
        'coins_rewarded', v_coins_rewarded,
        'current_experience', v_new_experience,
        'next_level_experience', v_current_level * 100,
        'progress_percentage', (v_new_experience::DECIMAL / (v_current_level * 100)) * 100
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- DAILY REWARD SYSTEM
-- =============================================================================

-- Function to claim daily reward
CREATE OR REPLACE FUNCTION claim_daily_reward(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    v_user_rewards user_rewards%ROWTYPE;
    v_last_claim user_daily_reward_claims%ROWTYPE;
    v_current_date DATE := CURRENT_DATE;
    v_yesterday DATE := CURRENT_DATE - INTERVAL '1 day';
    v_consecutive_days INTEGER := 1;
    v_day_number INTEGER := 1;
    v_daily_reward daily_rewards%ROWTYPE;
    v_coins_reward INTEGER := 50; -- Base daily reward
    v_already_claimed BOOLEAN := FALSE;
    v_result JSON;
BEGIN
    -- Get user rewards
    SELECT * INTO v_user_rewards FROM user_rewards WHERE user_id = p_user_id;
    
    IF v_user_rewards.user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User rewards not found');
    END IF;
    
    -- Check if already claimed today
    SELECT * INTO v_last_claim 
    FROM user_daily_reward_claims 
    WHERE user_id = p_user_id AND claim_date = v_current_date;
    
    IF v_last_claim.id IS NOT NULL THEN
        v_already_claimed := TRUE;
    END IF;
    
    IF v_already_claimed THEN
        RETURN json_build_object(
            'success', false,
            'already_claimed', true,
            'message', 'Daily reward already claimed today'
        );
    END IF;
    
    -- Get last claim to calculate consecutive days
    SELECT * INTO v_last_claim 
    FROM user_daily_reward_claims 
    WHERE user_id = p_user_id 
    ORDER BY claim_date DESC 
    LIMIT 1;
    
    IF v_last_claim.id IS NOT NULL THEN
        IF v_last_claim.claim_date = v_yesterday THEN
            -- Consecutive day
            v_consecutive_days := v_last_claim.consecutive_days + 1;
        ELSE
            -- Streak broken
            v_consecutive_days := 1;
        END IF;
    END IF;
    
    -- Calculate day number (cycle 1-30)
    v_day_number := ((v_consecutive_days - 1) % 30) + 1;
    
    -- Get daily reward configuration
    SELECT * INTO v_daily_reward FROM daily_rewards WHERE day_number = v_day_number;
    
    IF v_daily_reward.id IS NOT NULL THEN
        v_coins_reward := v_daily_reward.coins_reward;
    END IF;
    
    -- Apply consecutive day bonus (10% per day up to 100%)
    v_coins_reward := v_coins_reward + (v_coins_reward * LEAST(v_consecutive_days - 1, 10) * 0.1)::INTEGER;
    
    -- Process the reward
    BEGIN
        -- Update user coins
        UPDATE user_rewards 
        SET 
            coins = coins + v_coins_reward,
            current_streak = v_consecutive_days,
            daily_reward_claimed_at = NOW(),
            last_login = NOW(),
            updated_at = NOW()
        WHERE user_id = p_user_id;
        
        -- Record the claim
        INSERT INTO user_daily_reward_claims (
            user_id, claim_date, day_number, coins_earned, 
            consecutive_days, claimed_at
        ) VALUES (
            p_user_id, v_current_date, v_day_number, v_coins_reward,
            v_consecutive_days, NOW()
        );
        
        -- Log transaction
        INSERT INTO reward_transactions (
            user_id, transaction_type, amount, source, description, created_at
        ) VALUES (
            p_user_id, 'coins', v_coins_reward, 'daily_login',
            'Daily reward for day ' || v_consecutive_days, NOW()
        );
        
        v_result := json_build_object(
            'success', true,
            'coins_earned', v_coins_reward,
            'consecutive_days', v_consecutive_days,
            'day_number', v_day_number,
            'next_claim_available', v_current_date + INTERVAL '1 day',
            'streak_bonus', LEAST(v_consecutive_days - 1, 10) * 10 || '%'
        );
        
    EXCEPTION WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Failed to claim daily reward: ' || SQLERRM
        );
    END;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- ACHIEVEMENT CHECKING FUNCTIONS
-- =============================================================================

-- Function to check and update achievement progress
CREATE OR REPLACE FUNCTION check_purchase_achievements(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
    v_user_rewards user_rewards%ROWTYPE;
    v_achievement RECORD;
    v_progress user_achievement_progress%ROWTYPE;
BEGIN
    -- Get user rewards
    SELECT * INTO v_user_rewards FROM user_rewards WHERE user_id = p_user_id;
    
    -- Check purchase-related achievements
    FOR v_achievement IN 
        SELECT * FROM achievements 
        WHERE achievement_type IN ('purchase_count', 'spending_amount') 
        AND is_active = true
    LOOP
        -- Get current progress
        SELECT * INTO v_progress 
        FROM user_achievement_progress 
        WHERE user_id = p_user_id AND achievement_id = v_achievement.id;
        
        -- Initialize progress if doesn't exist
        IF v_progress.id IS NULL THEN
            INSERT INTO user_achievement_progress (
                user_id, achievement_id, target_value, current_progress
            ) VALUES (
                p_user_id, v_achievement.id, v_achievement.target_value, 0
            );
            
            SELECT * INTO v_progress 
            FROM user_achievement_progress 
            WHERE user_id = p_user_id AND achievement_id = v_achievement.id;
        END IF;
        
        -- Update progress based on achievement type
        IF v_achievement.achievement_type = 'purchase_count' THEN
            UPDATE user_achievement_progress 
            SET 
                current_progress = v_user_rewards.total_purchased,
                progress_percentage = (v_user_rewards.total_purchased::DECIMAL / v_achievement.target_value) * 100,
                is_completed = v_user_rewards.total_purchased >= v_achievement.target_value,
                completed_at = CASE 
                    WHEN v_user_rewards.total_purchased >= v_achievement.target_value 
                    AND NOT is_completed THEN NOW() 
                    ELSE completed_at 
                END,
                updated_at = NOW()
            WHERE user_id = p_user_id AND achievement_id = v_achievement.id;
            
        ELSIF v_achievement.achievement_type = 'spending_amount' THEN
            UPDATE user_achievement_progress 
            SET 
                current_progress = v_user_rewards.total_spent,
                progress_percentage = (v_user_rewards.total_spent::DECIMAL / v_achievement.target_value) * 100,
                is_completed = v_user_rewards.total_spent >= v_achievement.target_value,
                completed_at = CASE 
                    WHEN v_user_rewards.total_spent >= v_achievement.target_value 
                    AND NOT is_completed THEN NOW() 
                    ELSE completed_at 
                END,
                updated_at = NOW()
            WHERE user_id = p_user_id AND achievement_id = v_achievement.id;
        END IF;
        
        -- If achievement was just completed, award rewards
        IF v_user_rewards.total_purchased >= v_achievement.target_value OR 
           v_user_rewards.total_spent >= v_achievement.target_value THEN
            
            -- Check if we need to record completion
            IF NOT EXISTS (SELECT 1 FROM user_achievements WHERE user_id = p_user_id AND achievement_id = v_achievement.id) THEN
                PERFORM complete_achievement(p_user_id, v_achievement.id);
            END IF;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to complete an achievement and award rewards
CREATE OR REPLACE FUNCTION complete_achievement(
    p_user_id UUID,
    p_achievement_id INTEGER
)
RETURNS JSON AS $$
DECLARE
    v_achievement achievements%ROWTYPE;
    v_coins_earned INTEGER := 0;
    v_points_earned INTEGER := 0;
    v_result JSON;
BEGIN
    -- Get achievement details
    SELECT * INTO v_achievement FROM achievements WHERE id = p_achievement_id;
    
    IF v_achievement.id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Achievement not found');
    END IF;
    
    -- Check if already completed
    IF EXISTS (SELECT 1 FROM user_achievements WHERE user_id = p_user_id AND achievement_id = p_achievement_id) THEN
        RETURN json_build_object('success', false, 'error', 'Achievement already completed');
    END IF;
    
    v_coins_earned := COALESCE(v_achievement.coins_reward, 0);
    v_points_earned := COALESCE(v_achievement.points_reward, 0);
    
    BEGIN
        -- Record achievement completion
        INSERT INTO user_achievements (
            user_id, achievement_id, completion_progress, 
            coins_earned, points_earned, item_received
        ) VALUES (
            p_user_id, p_achievement_id, v_achievement.target_value,
            v_coins_earned, v_points_earned, v_achievement.item_reward
        );
        
        -- Award coins and points
        IF v_coins_earned > 0 OR v_points_earned > 0 THEN
            UPDATE user_rewards 
            SET 
                coins = coins + v_coins_earned,
                points = points + v_points_earned,
                updated_at = NOW()
            WHERE user_id = p_user_id;
        END IF;
        
        -- Log reward transactions
        IF v_coins_earned > 0 THEN
            INSERT INTO reward_transactions (
                user_id, transaction_type, amount, source, description
            ) VALUES (
                p_user_id, 'coins', v_coins_earned, 'achievement',
                'Achievement reward: ' || v_achievement.name
            );
        END IF;
        
        IF v_points_earned > 0 THEN
            INSERT INTO reward_transactions (
                user_id, transaction_type, amount, source, description
            ) VALUES (
                p_user_id, 'points', v_points_earned, 'achievement',
                'Achievement reward: ' || v_achievement.name
            );
        END IF;
        
        -- Update user achievement stats
        UPDATE user_achievement_stats 
        SET 
            total_achievements = total_achievements + 1,
            achievement_score = achievement_score + (
                CASE v_achievement.rarity 
                    WHEN 'common' THEN 10
                    WHEN 'uncommon' THEN 25
                    WHEN 'rare' THEN 50
                    WHEN 'epic' THEN 100
                    WHEN 'legendary' THEN 250
                    ELSE 10
                END
            ),
            total_coins_from_achievements = total_coins_from_achievements + v_coins_earned,
            total_points_from_achievements = total_points_from_achievements + v_points_earned,
            last_achievement_at = NOW(),
            updated_at = NOW()
        WHERE user_id = p_user_id;
        
        v_result := json_build_object(
            'success', true,
            'achievement_name', v_achievement.name,
            'coins_earned', v_coins_earned,
            'points_earned', v_points_earned,
            'rarity', v_achievement.rarity
        );
        
    EXCEPTION WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Failed to complete achievement: ' || SQLERRM
        );
    END;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- PERFORMANCE AND MAINTENANCE FUNCTIONS
-- =============================================================================

-- Function to clean up expired cache and old data
CREATE OR REPLACE FUNCTION cleanup_rewards_data()
RETURNS VOID AS $$
BEGIN
    -- Clean up old purchase audit records (older than 1 year)
    DELETE FROM purchase_audit 
    WHERE attempt_timestamp < NOW() - INTERVAL '1 year';
    
    -- Clean up old transaction records (older than 2 years)
    DELETE FROM reward_transactions 
    WHERE created_at < NOW() - INTERVAL '2 years';
    
    -- Clean up old booster pack openings (older than 1 year)
    DELETE FROM booster_pack_openings 
    WHERE opened_at < NOW() - INTERVAL '1 year';
    
    -- Clean up expired quests
    DELETE FROM user_quests 
    WHERE expires_at < NOW() AND is_completed = false;
    
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
        last_completed_at = (
            SELECT MAX(completed_at) FROM user_achievements 
            WHERE achievement_id = achievement_statistics.achievement_id
        ),
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- GRANT PERMISSIONS
-- =============================================================================

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION initialize_user_rewards(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_rewards_detailed(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION process_item_purchase(UUID, INTEGER, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION add_user_experience(UUID, INTEGER, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION claim_daily_reward(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION complete_achievement(UUID, INTEGER) TO authenticated;

-- Grant maintenance function to service role only
GRANT EXECUTE ON FUNCTION cleanup_rewards_data() TO service_role;
