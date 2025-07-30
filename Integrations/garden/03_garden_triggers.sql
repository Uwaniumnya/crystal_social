-- =====================================================
-- CRYSTAL SOCIAL - GARDEN SYSTEM TRIGGERS
-- =====================================================
-- Database triggers for automated garden operations
-- =====================================================

-- Trigger to auto-update garden timestamps
CREATE OR REPLACE FUNCTION update_garden_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_gardens_updated_at
    BEFORE UPDATE ON gardens
    FOR EACH ROW
    EXECUTE FUNCTION update_garden_timestamp();

CREATE OR REPLACE TRIGGER trg_flowers_updated_at
    BEFORE UPDATE ON flowers
    FOR EACH ROW
    EXECUTE FUNCTION update_garden_timestamp();

-- Trigger to check for wilting flowers
CREATE OR REPLACE FUNCTION check_flower_wilting()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if flower needs water (hasn't been watered in 8+ hours)
    IF (NEW.last_watered_at IS NULL AND NEW.created_at < NOW() - INTERVAL '8 hours') OR
       (NEW.last_watered_at IS NOT NULL AND NEW.last_watered_at < NOW() - INTERVAL '8 hours') THEN
        NEW.is_wilting = true;
        NEW.health = GREATEST(0, NEW.health - 5); -- Lose health when wilting
    END IF;
    
    -- Check if flower dies (no water for 24+ hours)
    IF (NEW.last_watered_at IS NULL AND NEW.created_at < NOW() - INTERVAL '24 hours') OR
       (NEW.last_watered_at IS NOT NULL AND NEW.last_watered_at < NOW() - INTERVAL '24 hours') THEN
        NEW.is_dead = true;
        NEW.health = 0;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_flower_wilting_check
    BEFORE UPDATE ON flowers
    FOR EACH ROW
    EXECUTE FUNCTION check_flower_wilting();

-- Trigger to update achievement progress
CREATE OR REPLACE FUNCTION update_achievement_progress()
RETURNS TRIGGER AS $$
DECLARE
    v_achievement RECORD;
    v_current_value INTEGER;
    v_garden_id UUID;
BEGIN
    -- Determine which table was updated and get garden_id
    IF TG_TABLE_NAME = 'flowers' THEN
        v_garden_id := COALESCE(NEW.garden_id, OLD.garden_id);
    ELSIF TG_TABLE_NAME = 'gardens' THEN
        v_garden_id := COALESCE(NEW.id, OLD.id);
    ELSIF TG_TABLE_NAME = 'garden_visitor_instances' THEN
        v_garden_id := COALESCE(NEW.garden_id, OLD.garden_id);
    ELSE
        RETURN COALESCE(NEW, OLD);
    END IF;
    
    -- Update achievements based on the trigger
    FOR v_achievement IN 
        SELECT * FROM garden_achievements 
        WHERE garden_id = v_garden_id AND NOT is_completed
    LOOP
        v_current_value := 0;
        
        -- Calculate current value based on achievement type
        CASE v_achievement.achievement_type
            WHEN 'first_plant' THEN
                SELECT COUNT(*) INTO v_current_value
                FROM flowers
                WHERE garden_id = v_garden_id;
                
            WHEN 'flower_collector' THEN
                SELECT total_flowers_grown INTO v_current_value
                FROM gardens
                WHERE id = v_garden_id;
                
            WHEN 'level_up' THEN
                SELECT level INTO v_current_value
                FROM gardens
                WHERE id = v_garden_id;
                
            WHEN 'visitor_host' THEN
                SELECT COUNT(*) INTO v_current_value
                FROM garden_visitor_instances
                WHERE garden_id = v_garden_id AND has_given_reward = true;
                
            WHEN 'bloomer' THEN
                SELECT total_flowers_bloomed INTO v_current_value
                FROM gardens
                WHERE id = v_garden_id;
                
            WHEN 'caretaker' THEN
                SELECT SUM(total_waterings) INTO v_current_value
                FROM flowers
                WHERE garden_id = v_garden_id;
                
            WHEN 'green_thumb' THEN
                SELECT COUNT(*) INTO v_current_value
                FROM flowers
                WHERE garden_id = v_garden_id AND health >= 80;
                
            ELSE
                CONTINUE; -- Unknown achievement type
        END CASE;
        
        -- Update achievement progress
        UPDATE garden_achievements
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
        WHERE id = v_achievement.id;
        
        -- Give achievement rewards if just completed
        IF v_current_value >= v_achievement.target_value AND NOT v_achievement.is_completed THEN
            UPDATE gardens
            SET 
                coins = coins + v_achievement.reward_coins,
                gems = gems + v_achievement.reward_gems,
                total_achievements = total_achievements + 1,
                updated_at = NOW()
            WHERE id = v_garden_id;
        END IF;
    END LOOP;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_flowers_achievement_update
    AFTER INSERT OR UPDATE OR DELETE ON flowers
    FOR EACH ROW
    EXECUTE FUNCTION update_achievement_progress();

CREATE OR REPLACE TRIGGER trg_gardens_achievement_update
    AFTER UPDATE ON gardens
    FOR EACH ROW
    EXECUTE FUNCTION update_achievement_progress();

CREATE OR REPLACE TRIGGER trg_visitors_achievement_update
    AFTER UPDATE ON garden_visitor_instances
    FOR EACH ROW
    WHEN (NEW.has_given_reward = true AND OLD.has_given_reward = false)
    EXECUTE FUNCTION update_achievement_progress();

-- Trigger to handle weather effects on flowers
CREATE OR REPLACE FUNCTION apply_weather_effects()
RETURNS TRIGGER AS $$
DECLARE
    v_flower RECORD;
    v_health_modifier INTEGER := 0;
    v_happiness_modifier INTEGER := 0;
    v_growth_modifier DECIMAL := 1.0;
BEGIN
    -- Apply weather effects to all flowers in affected gardens
    FOR v_flower IN 
        SELECT * FROM flowers 
        WHERE garden_id = NEW.garden_id 
        AND NOT is_dead 
        AND (NEW.ends_at IS NULL OR NEW.ends_at > NOW())
    LOOP
        -- Calculate modifiers based on weather type
        CASE NEW.weather_type
            WHEN 'sunny' THEN
                v_health_modifier := 5;
                v_happiness_modifier := 10;
                v_growth_modifier := 1.2;
                
            WHEN 'rainy' THEN
                v_health_modifier := 8;
                v_happiness_modifier := 5;
                v_growth_modifier := 1.3;
                
            WHEN 'snowy' THEN
                v_health_modifier := -3;
                v_happiness_modifier := -5;
                v_growth_modifier := 0.7;
                
            WHEN 'windy' THEN
                v_health_modifier := -2;
                v_happiness_modifier := 2;
                v_growth_modifier := 0.9;
                
            WHEN 'misty' THEN
                v_health_modifier := 3;
                v_happiness_modifier := 8;
                v_growth_modifier := 1.1;
                
            ELSE
                CONTINUE; -- Unknown weather type
        END CASE;
        
        -- Apply modifiers to flower
        UPDATE flowers
        SET 
            health = GREATEST(0, LEAST(100, health + v_health_modifier)),
            happiness = GREATEST(0, LEAST(100, happiness + v_happiness_modifier)),
            growth_multiplier = v_growth_modifier,
            updated_at = NOW()
        WHERE id = v_flower.id;
    END LOOP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_weather_effects
    AFTER INSERT OR UPDATE ON garden_weather_events
    FOR EACH ROW
    WHEN (NEW.ends_at IS NULL OR NEW.ends_at > NOW())
    EXECUTE FUNCTION apply_weather_effects();

-- Trigger to clean up expired weather events
CREATE OR REPLACE FUNCTION cleanup_expired_weather()
RETURNS TRIGGER AS $$
BEGIN
    -- Set end time for expired weather events that don't have one
    UPDATE garden_weather_events
    SET ends_at = NOW()
    WHERE ends_at IS NULL AND started_at + (duration_minutes || ' minutes')::INTERVAL <= NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_weather_cleanup
    BEFORE INSERT ON garden_weather_events
    FOR EACH ROW
    EXECUTE FUNCTION cleanup_expired_weather();

-- Trigger to auto-remove expired visitors
CREATE OR REPLACE FUNCTION cleanup_expired_visitors()
RETURNS TRIGGER AS $$
BEGIN
    -- Remove visitors that have overstayed
    DELETE FROM garden_visitor_instances
    WHERE will_leave_at <= NOW() - INTERVAL '1 hour';
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_visitor_cleanup
    BEFORE INSERT ON garden_visitor_instances
    FOR EACH ROW
    EXECUTE FUNCTION cleanup_expired_visitors();

-- Trigger to validate flower positioning
CREATE OR REPLACE FUNCTION validate_flower_position()
RETURNS TRIGGER AS $$
DECLARE
    v_max_flowers INTEGER;
    v_current_count INTEGER;
    v_too_close BOOLEAN := false;
BEGIN
    -- Check garden capacity
    SELECT max_flowers INTO v_max_flowers
    FROM gardens
    WHERE id = NEW.garden_id;
    
    SELECT COUNT(*) INTO v_current_count
    FROM flowers
    WHERE garden_id = NEW.garden_id;
    
    IF v_current_count >= v_max_flowers THEN
        RAISE EXCEPTION 'Garden has reached maximum flower capacity of %', v_max_flowers;
    END IF;
    
    -- Check if position is too close to existing flowers (minimum 10 units apart)
    SELECT EXISTS(
        SELECT 1 FROM flowers
        WHERE garden_id = NEW.garden_id
        AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::UUID)
        AND SQRT(
            POWER(x_position - NEW.x_position, 2) + 
            POWER(y_position - NEW.y_position, 2)
        ) < 10
    ) INTO v_too_close;
    
    IF v_too_close THEN
        RAISE EXCEPTION 'Flower position is too close to existing flowers';
    END IF;
    
    -- Ensure position is within garden bounds (0-100)
    IF NEW.x_position < 0 OR NEW.x_position > 100 OR
       NEW.y_position < 0 OR NEW.y_position > 100 THEN
        RAISE EXCEPTION 'Flower position must be between 0 and 100';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_validate_flower_position
    BEFORE INSERT OR UPDATE ON flowers
    FOR EACH ROW
    EXECUTE FUNCTION validate_flower_position();

-- Trigger to auto-create daily quests
CREATE OR REPLACE FUNCTION create_daily_quests()
RETURNS TRIGGER AS $$
DECLARE
    v_garden_id UUID;
    v_garden_level INTEGER;
BEGIN
    -- Get garden details
    IF TG_OP = 'INSERT' THEN
        v_garden_id := NEW.id;
        v_garden_level := NEW.level;
    ELSE
        v_garden_id := NEW.id;
        v_garden_level := NEW.level;
    END IF;
    
    -- Create daily quests if none exist for today
    IF NOT EXISTS(
        SELECT 1 FROM garden_daily_quests
        WHERE garden_id = v_garden_id 
        AND quest_date = CURRENT_DATE
    ) THEN
        -- Plant flowers quest
        INSERT INTO garden_daily_quests (
            garden_id,
            quest_type,
            quest_name,
            description,
            target_value,
            reward_coins,
            reward_experience,
            quest_date
        ) VALUES (
            v_garden_id,
            'plant_flowers',
            'Green Growth',
            'Plant ' || LEAST(v_garden_level, 5) || ' flowers today',
            LEAST(v_garden_level, 5),
            50 + (v_garden_level * 10),
            25 + (v_garden_level * 5),
            CURRENT_DATE
        );
        
        -- Water flowers quest
        INSERT INTO garden_daily_quests (
            garden_id,
            quest_type,
            quest_name,
            description,
            target_value,
            reward_coins,
            reward_experience,
            quest_date
        ) VALUES (
            v_garden_id,
            'water_flowers',
            'Hydration Helper',
            'Water ' || (v_garden_level * 3) || ' flowers today',
            v_garden_level * 3,
            40 + (v_garden_level * 8),
            20 + (v_garden_level * 4),
            CURRENT_DATE
        );
        
        -- Care for flowers quest (only for higher levels)
        IF v_garden_level >= 3 THEN
            INSERT INTO garden_daily_quests (
                garden_id,
                quest_type,
                quest_name,
                description,
                target_value,
                reward_coins,
                reward_gems,
                quest_date
            ) VALUES (
                v_garden_id,
                'care_flowers',
                'Tender Care',
                'Fertilize ' || v_garden_level || ' flowers today',
                v_garden_level,
                60 + (v_garden_level * 12),
                1 + (v_garden_level / 5),
                CURRENT_DATE
            );
        END IF;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_create_daily_quests
    AFTER INSERT OR UPDATE ON gardens
    FOR EACH ROW
    EXECUTE FUNCTION create_daily_quests();

-- Trigger to update quest progress
CREATE OR REPLACE FUNCTION update_quest_progress()
RETURNS TRIGGER AS $$
DECLARE
    v_quest RECORD;
    v_current_value INTEGER;
    v_garden_id UUID;
BEGIN
    -- Determine garden_id from the triggering table
    IF TG_TABLE_NAME = 'flowers' THEN
        v_garden_id := COALESCE(NEW.garden_id, OLD.garden_id);
    ELSIF TG_TABLE_NAME = 'garden_analytics' THEN
        v_garden_id := COALESCE(NEW.garden_id, OLD.garden_id);
    ELSE
        RETURN COALESCE(NEW, OLD);
    END IF;
    
    -- Update daily quests for today
    FOR v_quest IN 
        SELECT * FROM garden_daily_quests 
        WHERE garden_id = v_garden_id 
        AND quest_date = CURRENT_DATE 
        AND NOT is_completed
    LOOP
        v_current_value := 0;
        
        -- Calculate current progress based on quest type
        CASE v_quest.quest_type
            WHEN 'plant_flowers' THEN
                SELECT COALESCE(flowers_planted, 0) INTO v_current_value
                FROM garden_analytics
                WHERE garden_id = v_garden_id AND date = CURRENT_DATE;
                
            WHEN 'water_flowers' THEN
                SELECT COALESCE(flowers_watered, 0) INTO v_current_value
                FROM garden_analytics
                WHERE garden_id = v_garden_id AND date = CURRENT_DATE;
                
            WHEN 'care_flowers' THEN
                SELECT COALESCE(flowers_fertilized, 0) INTO v_current_value
                FROM garden_analytics
                WHERE garden_id = v_garden_id AND date = CURRENT_DATE;
                
            WHEN 'earn_coins' THEN
                SELECT COALESCE(coins_earned, 0) INTO v_current_value
                FROM garden_analytics
                WHERE garden_id = v_garden_id AND date = CURRENT_DATE;
                
            ELSE
                CONTINUE; -- Unknown quest type
        END CASE;
        
        -- Update quest progress
        UPDATE garden_daily_quests
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
            UPDATE gardens
            SET 
                coins = coins + COALESCE(v_quest.reward_coins, 0),
                gems = gems + COALESCE(v_quest.reward_gems, 0),
                experience = experience + COALESCE(v_quest.reward_experience, 0),
                total_quests_completed = total_quests_completed + 1,
                updated_at = NOW()
            WHERE id = v_garden_id;
            
            -- Check for level up after quest completion
            PERFORM check_garden_level_up(v_garden_id);
        END IF;
    END LOOP;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_quest_progress_analytics
    AFTER INSERT OR UPDATE ON garden_analytics
    FOR EACH ROW
    EXECUTE FUNCTION update_quest_progress();

-- Trigger to clean up old data
CREATE OR REPLACE FUNCTION cleanup_old_garden_data()
RETURNS TRIGGER AS $$
BEGIN
    -- Clean up old analytics (keep last 30 days)
    DELETE FROM garden_analytics
    WHERE date < CURRENT_DATE - INTERVAL '30 days';
    
    -- Clean up old quests (keep last 7 days)
    DELETE FROM garden_daily_quests
    WHERE quest_date < CURRENT_DATE - INTERVAL '7 days';
    
    -- Clean up old weather events (keep last 7 days)
    DELETE FROM garden_weather_events
    WHERE created_at < NOW() - INTERVAL '7 days'
    AND (ends_at IS NOT NULL AND ends_at < NOW());
    
    -- Clean up old purchase history (keep last 90 days)
    DELETE FROM garden_purchases
    WHERE purchased_at < NOW() - INTERVAL '90 days';
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Run cleanup weekly (this would typically be called by a scheduled job)
CREATE OR REPLACE TRIGGER trg_weekly_cleanup
    AFTER INSERT ON gardens
    FOR EACH ROW
    WHEN (EXTRACT(DOW FROM NOW()) = 0) -- Sunday
    EXECUTE FUNCTION cleanup_old_garden_data();
