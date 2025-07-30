-- =====================================================
-- CRYSTAL SOCIAL - GEMS SYSTEM TRIGGERS
-- =====================================================
-- Database triggers for automated gem operations
-- =====================================================

-- Trigger to auto-update timestamps
CREATE OR REPLACE FUNCTION update_gem_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_enhanced_gemstones_updated_at
    BEFORE UPDATE ON enhanced_gemstones
    FOR EACH ROW
    EXECUTE FUNCTION update_gem_timestamp();

CREATE OR REPLACE TRIGGER trg_user_gemstones_updated_at
    BEFORE UPDATE ON user_gemstones
    FOR EACH ROW
    EXECUTE FUNCTION update_gem_timestamp();

CREATE OR REPLACE TRIGGER trg_gem_collection_stats_updated_at
    BEFORE UPDATE ON gem_collection_stats
    FOR EACH ROW
    EXECUTE FUNCTION update_gem_timestamp();

CREATE OR REPLACE TRIGGER trg_gem_trades_updated_at
    BEFORE UPDATE ON gem_trades
    FOR EACH ROW
    EXECUTE FUNCTION update_gem_timestamp();

CREATE OR REPLACE TRIGGER trg_gem_achievements_updated_at
    BEFORE UPDATE ON gem_achievements
    FOR EACH ROW
    EXECUTE FUNCTION update_gem_timestamp();

CREATE OR REPLACE TRIGGER trg_gem_daily_quests_updated_at
    BEFORE UPDATE ON gem_daily_quests
    FOR EACH ROW
    EXECUTE FUNCTION update_gem_timestamp();

CREATE OR REPLACE TRIGGER trg_gem_wishlists_updated_at
    BEFORE UPDATE ON gem_wishlists
    FOR EACH ROW
    EXECUTE FUNCTION update_gem_timestamp();

CREATE OR REPLACE TRIGGER trg_gem_social_shares_updated_at
    BEFORE UPDATE ON gem_social_shares
    FOR EACH ROW
    EXECUTE FUNCTION update_gem_timestamp();

CREATE OR REPLACE TRIGGER trg_gem_discovery_methods_updated_at
    BEFORE UPDATE ON gem_discovery_methods
    FOR EACH ROW
    EXECUTE FUNCTION update_gem_timestamp();

-- Trigger to update gem viewing statistics
CREATE OR REPLACE FUNCTION update_gem_view_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Update view count and timestamps
    NEW.times_viewed = OLD.times_viewed + 1;
    NEW.last_viewed_at = NOW();
    
    -- Set first viewed if not set
    IF OLD.first_viewed_at IS NULL THEN
        NEW.first_viewed_at = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_gem_view_tracking
    BEFORE UPDATE ON user_gemstones
    FOR EACH ROW
    WHEN (NEW.times_viewed > OLD.times_viewed)
    EXECUTE FUNCTION update_gem_view_stats();

-- Trigger to automatically update collection stats when gems are added/removed
CREATE OR REPLACE FUNCTION auto_update_collection_stats()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Get user ID from the operation
    IF TG_OP = 'DELETE' THEN
        v_user_id := OLD.user_id;
    ELSE
        v_user_id := NEW.user_id;
    END IF;
    
    -- Update collection statistics
    PERFORM update_gem_collection_stats(v_user_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_user_gemstones_stats_update
    AFTER INSERT OR UPDATE OR DELETE ON user_gemstones
    FOR EACH ROW
    EXECUTE FUNCTION auto_update_collection_stats();

-- Trigger to check achievements when relevant data changes
CREATE OR REPLACE FUNCTION auto_check_achievements()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Get user ID from the operation
    IF TG_OP = 'DELETE' THEN
        v_user_id := OLD.user_id;
    ELSE
        v_user_id := NEW.user_id;
    END IF;
    
    -- Check for new achievement unlocks
    PERFORM check_gem_achievements(v_user_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_user_gemstones_achievement_check
    AFTER INSERT OR UPDATE ON user_gemstones
    FOR EACH ROW
    EXECUTE FUNCTION auto_check_achievements();

CREATE OR REPLACE TRIGGER trg_gem_enhancements_achievement_check
    AFTER INSERT ON gem_enhancements
    FOR EACH ROW
    EXECUTE FUNCTION auto_check_achievements();

-- Trigger to update analytics when gems are discovered
CREATE OR REPLACE FUNCTION update_gem_analytics()
RETURNS TRIGGER AS $$
DECLARE
    v_gem RECORD;
BEGIN
    -- Get gem details
    SELECT * INTO v_gem FROM enhanced_gemstones WHERE id = NEW.gem_id;
    
    -- Update daily analytics
    INSERT INTO gem_analytics (
        user_id, 
        date, 
        gems_discovered, 
        total_value_gained, 
        total_power_gained,
        session_count
    )
    VALUES (
        NEW.user_id, 
        CURRENT_DATE, 
        1, 
        v_gem.value, 
        v_gem.power,
        1
    )
    ON CONFLICT (user_id, date)
    DO UPDATE SET 
        gems_discovered = gem_analytics.gems_discovered + 1,
        total_value_gained = gem_analytics.total_value_gained + v_gem.value,
        total_power_gained = gem_analytics.total_power_gained + v_gem.power,
        session_count = gem_analytics.session_count + 1;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_gem_discovery_analytics
    AFTER INSERT ON user_gemstones
    FOR EACH ROW
    EXECUTE FUNCTION update_gem_analytics();

-- Trigger to track gem view analytics
CREATE OR REPLACE FUNCTION track_gem_view_analytics()
RETURNS TRIGGER AS $$
BEGIN
    -- Only track if times_viewed actually increased
    IF NEW.times_viewed > OLD.times_viewed THEN
        -- Update daily analytics
        INSERT INTO gem_analytics (user_id, date, gems_viewed, session_count)
        VALUES (NEW.user_id, CURRENT_DATE, 1, 1)
        ON CONFLICT (user_id, date)
        DO UPDATE SET 
            gems_viewed = gem_analytics.gems_viewed + 1,
            session_count = gem_analytics.session_count + 1;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_gem_view_analytics
    AFTER UPDATE ON user_gemstones
    FOR EACH ROW
    WHEN (NEW.times_viewed > OLD.times_viewed)
    EXECUTE FUNCTION track_gem_view_analytics();

-- Trigger to auto-create initial achievements for new users
CREATE OR REPLACE FUNCTION create_initial_gem_achievements()
RETURNS TRIGGER AS $$
BEGIN
    -- Create basic achievements for new users
    INSERT INTO gem_achievements (
        user_id, achievement_type, achievement_name, description, 
        target_value, reward_coins, reward_gems, rarity, category
    ) VALUES 
    (NEW.user_id, 'first_gem', 'First Discovery', 'Unlock your first gem', 
     1, 100, 5, 'common', 'collection'),
    (NEW.user_id, 'gem_collector', 'Novice Collector', 'Collect 10 different gems', 
     10, 500, 25, 'uncommon', 'collection'),
    (NEW.user_id, 'gem_collector', 'Dedicated Collector', 'Collect 25 different gems', 
     25, 1000, 50, 'rare', 'collection'),
    (NEW.user_id, 'gem_collector', 'Master Collector', 'Collect 50 different gems', 
     50, 2500, 100, 'epic', 'collection'),
    (NEW.user_id, 'power_accumulator', 'Power Seeker', 'Accumulate 1000 total gem power', 
     1000, 750, 35, 'uncommon', 'power'),
    (NEW.user_id, 'value_accumulator', 'Treasure Hunter', 'Accumulate 5000 total gem value', 
     5000, 1500, 75, 'rare', 'value'),
    (NEW.user_id, 'enhancer', 'Enhancement Novice', 'Successfully enhance 5 gems', 
     5, 300, 15, 'common', 'enhancement'),
    (NEW.user_id, 'completionist', 'Halfway There', 'Complete 50% of gem collection', 
     50, 5000, 250, 'legendary', 'completion');
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_create_gem_achievements
    AFTER INSERT ON gem_collection_stats
    FOR EACH ROW
    EXECUTE FUNCTION create_initial_gem_achievements();

-- Trigger to auto-create daily quests
CREATE OR REPLACE FUNCTION create_gem_daily_quests()
RETURNS TRIGGER AS $$
DECLARE
    v_user_level INTEGER;
BEGIN
    -- Get user level (assuming it exists in profiles)
    SELECT COALESCE(level, 1) INTO v_user_level FROM profiles WHERE id = NEW.user_id;
    
    -- Create daily quests if none exist for today
    IF NOT EXISTS(
        SELECT 1 FROM gem_daily_quests
        WHERE user_id = NEW.user_id AND quest_date = CURRENT_DATE
    ) THEN
        -- Discover gems quest
        INSERT INTO gem_daily_quests (
            user_id, quest_type, quest_name, description, target_value,
            reward_coins, reward_gems, reward_experience, quest_date
        ) VALUES (
            NEW.user_id, 'discover_gems', 'Daily Discovery',
            'Discover ' || LEAST(v_user_level, 3) || ' new gems today',
            LEAST(v_user_level, 3), 200, 10, 50, CURRENT_DATE
        );
        
        -- View gems quest
        INSERT INTO gem_daily_quests (
            user_id, quest_type, quest_name, description, target_value,
            reward_coins, reward_experience, quest_date
        ) VALUES (
            NEW.user_id, 'view_gems', 'Gem Admirer',
            'View ' || (v_user_level * 5) || ' gems today',
            v_user_level * 5, 100, 25, CURRENT_DATE
        );
        
        -- Enhancement quest (for higher levels)
        IF v_user_level >= 5 THEN
            INSERT INTO gem_daily_quests (
                user_id, quest_type, quest_name, description, target_value,
                reward_coins, reward_gems, quest_date
            ) VALUES (
                NEW.user_id, 'enhance_gems', 'Enhancement Master',
                'Successfully enhance ' || CEIL(v_user_level / 5.0) || ' gems today',
                CEIL(v_user_level / 5.0), 300, 15, CURRENT_DATE
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_create_gem_daily_quests
    AFTER INSERT ON gem_collection_stats
    FOR EACH ROW
    EXECUTE FUNCTION create_gem_daily_quests();

-- Trigger to update quest progress
CREATE OR REPLACE FUNCTION update_gem_quest_progress()
RETURNS TRIGGER AS $$
DECLARE
    v_quest RECORD;
    v_current_value INTEGER;
    v_user_id UUID;
    v_quest_date DATE := CURRENT_DATE;
BEGIN
    -- Determine user_id and relevant data based on trigger table
    IF TG_TABLE_NAME = 'user_gemstones' THEN
        v_user_id := COALESCE(NEW.user_id, OLD.user_id);
    ELSIF TG_TABLE_NAME = 'gem_enhancements' THEN
        SELECT ug.user_id INTO v_user_id
        FROM user_gemstones ug
        WHERE ug.id = NEW.user_gem_id;
    ELSIF TG_TABLE_NAME = 'gem_analytics' THEN
        v_user_id := NEW.user_id;
        v_quest_date := NEW.date;
    ELSE
        RETURN COALESCE(NEW, OLD);
    END IF;
    
    -- Update daily quests for today
    FOR v_quest IN 
        SELECT * FROM gem_daily_quests 
        WHERE user_id = v_user_id 
        AND quest_date = v_quest_date
        AND NOT is_completed
    LOOP
        v_current_value := 0;
        
        -- Calculate current progress based on quest type
        CASE v_quest.quest_type
            WHEN 'discover_gems' THEN
                SELECT COALESCE(gems_discovered, 0) INTO v_current_value
                FROM gem_analytics
                WHERE user_id = v_user_id AND date = v_quest_date;
                
            WHEN 'view_gems' THEN
                SELECT COALESCE(gems_viewed, 0) INTO v_current_value
                FROM gem_analytics
                WHERE user_id = v_user_id AND date = v_quest_date;
                
            WHEN 'enhance_gems' THEN
                SELECT COALESCE(gems_enhanced, 0) INTO v_current_value
                FROM gem_analytics
                WHERE user_id = v_user_id AND date = v_quest_date;
                
            WHEN 'add_favorites' THEN
                SELECT COALESCE(favorites_added, 0) INTO v_current_value
                FROM gem_analytics
                WHERE user_id = v_user_id AND date = v_quest_date;
                
            ELSE
                CONTINUE; -- Unknown quest type
        END CASE;
        
        -- Update quest progress
        UPDATE gem_daily_quests
        SET 
            current_value = v_current_value,
            progress_percentage = LEAST(100, ROUND((v_current_value::DECIMAL / target_value) * 100, 1)),
            is_completed = (v_current_value >= target_value),
            completed_at = CASE 
                WHEN v_current_value >= target_value AND completed_at IS NULL 
                THEN NOW() 
                ELSE completed_at 
            END,
            updated_at = NOW()
        WHERE id = v_quest.id;
        
        -- Give quest rewards if just completed
        IF v_current_value >= v_quest.target_value AND NOT v_quest.is_completed THEN
            UPDATE profiles
            SET 
                coins = coins + COALESCE(v_quest.reward_coins, 0),
                gems = gems + COALESCE(v_quest.reward_gems, 0),
                experience = experience + COALESCE(v_quest.reward_experience, 0),
                updated_at = NOW()
            WHERE id = v_user_id;
        END IF;
    END LOOP;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_gem_quest_progress_analytics
    AFTER INSERT OR UPDATE ON gem_analytics
    FOR EACH ROW
    EXECUTE FUNCTION update_gem_quest_progress();

CREATE OR REPLACE TRIGGER trg_gem_quest_progress_gemstones
    AFTER INSERT ON user_gemstones
    FOR EACH ROW
    EXECUTE FUNCTION update_gem_quest_progress();

CREATE OR REPLACE TRIGGER trg_gem_quest_progress_enhancements
    AFTER INSERT ON gem_enhancements
    FOR EACH ROW
    WHEN (NEW.was_successful = true)
    EXECUTE FUNCTION update_gem_quest_progress();

-- Trigger to handle gem trade status changes
CREATE OR REPLACE FUNCTION handle_gem_trade_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Handle trade completion
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        NEW.completed_at = NOW();
        
        -- Transfer gem ownership if this is a sale
        IF NEW.trade_type = 'offer' AND NEW.buyer_id IS NOT NULL THEN
            -- Remove gem from seller
            DELETE FROM user_gemstones 
            WHERE user_id = NEW.seller_id AND gem_id = NEW.gem_id;
            
            -- Add gem to buyer
            INSERT INTO user_gemstones (user_id, gem_id, unlock_source, unlock_context)
            VALUES (NEW.buyer_id, NEW.gem_id, 'trade', 
                   jsonb_build_object('trade_id', NEW.id, 'seller_id', NEW.seller_id));
            
            -- Update seller's profile with payment
            UPDATE profiles 
            SET 
                coins = coins + NEW.price_coins,
                gems = gems + NEW.price_gems,
                updated_at = NOW()
            WHERE id = NEW.seller_id;
            
            -- Deduct payment from buyer
            UPDATE profiles 
            SET 
                coins = coins - NEW.price_coins,
                gems = gems - NEW.price_gems,
                updated_at = NOW()
            WHERE id = NEW.buyer_id;
        END IF;
    END IF;
    
    -- Handle trade expiration
    IF NEW.expires_at IS NOT NULL AND NEW.expires_at <= NOW() AND NEW.status = 'active' THEN
        NEW.status = 'expired';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_gem_trade_status
    BEFORE UPDATE ON gem_trades
    FOR EACH ROW
    EXECUTE FUNCTION handle_gem_trade_status();

-- Trigger to validate gem enhancement requirements
CREATE OR REPLACE FUNCTION validate_gem_enhancement()
RETURNS TRIGGER AS $$
DECLARE
    v_user_gem RECORD;
    v_user_profile RECORD;
BEGIN
    -- Get user gem details
    SELECT ug.*, eg.rarity 
    INTO v_user_gem
    FROM user_gemstones ug
    JOIN enhanced_gemstones eg ON ug.gem_id = eg.id
    WHERE ug.id = NEW.user_gem_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'User gem not found';
    END IF;
    
    -- Get user profile
    SELECT * INTO v_user_profile FROM profiles WHERE id = v_user_gem.user_id;
    
    -- Check if user can afford enhancement
    IF v_user_profile.coins < NEW.enhancement_cost_coins OR 
       v_user_profile.gems < NEW.enhancement_cost_gems THEN
        RAISE EXCEPTION 'Insufficient funds for enhancement';
    END IF;
    
    -- Check enhancement level limits
    IF v_user_gem.enhancement_level >= 10 THEN
        RAISE EXCEPTION 'Gem has reached maximum enhancement level';
    END IF;
    
    -- Validate enhancement type
    IF NEW.enhancement_type NOT IN ('power', 'value', 'special', 'rarity') THEN
        RAISE EXCEPTION 'Invalid enhancement type';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_validate_gem_enhancement
    BEFORE INSERT ON gem_enhancements
    FOR EACH ROW
    EXECUTE FUNCTION validate_gem_enhancement();

-- Trigger to clean up old data
CREATE OR REPLACE FUNCTION cleanup_old_gem_data()
RETURNS TRIGGER AS $$
BEGIN
    -- Clean up old analytics (keep last 90 days)
    DELETE FROM gem_analytics
    WHERE date < CURRENT_DATE - INTERVAL '90 days';
    
    -- Clean up old daily quests (keep last 7 days)
    DELETE FROM gem_daily_quests
    WHERE quest_date < CURRENT_DATE - INTERVAL '7 days';
    
    -- Clean up expired trades
    DELETE FROM gem_trades
    WHERE status = 'expired' AND created_at < NOW() - INTERVAL '30 days';
    
    -- Clean up old discovery events (keep last 180 days)
    DELETE FROM gem_discovery_events
    WHERE created_at < NOW() - INTERVAL '180 days';
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a weekly cleanup trigger (this would typically be called by a scheduled job)
CREATE OR REPLACE TRIGGER trg_weekly_gem_cleanup
    AFTER INSERT ON gem_analytics
    FOR EACH ROW
    WHEN (EXTRACT(DOW FROM NEW.date) = 0) -- Sunday
    EXECUTE FUNCTION cleanup_old_gem_data();

-- Trigger to update social share statistics
CREATE OR REPLACE FUNCTION update_social_share_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Update likes count when someone likes a share
    IF TG_OP = 'UPDATE' AND NEW.likes_count != OLD.likes_count THEN
        -- Track in analytics if significant change
        IF NEW.likes_count - OLD.likes_count >= 10 THEN
            INSERT INTO gem_analytics (user_id, date, session_count)
            VALUES (NEW.user_id, CURRENT_DATE, 1)
            ON CONFLICT (user_id, date)
            DO UPDATE SET session_count = gem_analytics.session_count + 1;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_social_share_stats
    AFTER UPDATE ON gem_social_shares
    FOR EACH ROW
    EXECUTE FUNCTION update_social_share_stats();
