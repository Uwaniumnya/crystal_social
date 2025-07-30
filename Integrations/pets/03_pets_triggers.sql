-- =====================================================
-- CRYSTAL SOCIAL - PETS SYSTEM TRIGGERS
-- =====================================================
-- Automated triggers for pet care, statistics tracking,
-- achievements, and system maintenance
-- =====================================================

-- =====================================================
-- PET STATE MANAGEMENT TRIGGERS
-- =====================================================

-- Trigger to automatically update pet timestamps
CREATE OR REPLACE FUNCTION update_pet_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_pet_updated_at
    BEFORE UPDATE ON user_pets
    FOR EACH ROW
    EXECUTE FUNCTION update_pet_timestamp();

-- Trigger to update last_active_at when pet stats change
CREATE OR REPLACE FUNCTION update_pet_last_active()
RETURNS TRIGGER AS $$
BEGIN
    -- Update last_active_at when significant interactions occur
    IF TG_OP = 'UPDATE' AND (
        OLD.health != NEW.health OR 
        OLD.happiness != NEW.happiness OR 
        OLD.energy != NEW.energy OR
        OLD.hunger != NEW.hunger OR
        OLD.total_interactions != NEW.total_interactions
    ) THEN
        NEW.last_active_at = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_pet_activity_tracking
    BEFORE UPDATE ON user_pets
    FOR EACH ROW
    EXECUTE FUNCTION update_pet_last_active();

-- =====================================================
-- PET VITALS DECAY SYSTEM
-- =====================================================

-- Function to naturally decay pet vitals over time
CREATE OR REPLACE FUNCTION decay_pet_vitals()
RETURNS TRIGGER AS $$
DECLARE
    v_hours_since_last_active INTEGER;
    v_decay_rate DECIMAL;
    v_hunger_increase DECIMAL;
    v_energy_decrease DECIMAL;
    v_happiness_decrease DECIMAL;
BEGIN
    -- Only apply decay if pet has been inactive
    v_hours_since_last_active := EXTRACT(EPOCH FROM (NOW() - OLD.last_active_at)) / 3600;
    
    -- Apply decay only if more than 2 hours have passed
    IF v_hours_since_last_active >= 2 THEN
        -- Calculate decay rates (slower for higher bond levels)
        v_decay_rate := GREATEST(0.1, 1.0 - (OLD.bond_level * 0.05));
        
        -- Calculate changes
        v_hunger_increase := LEAST(20, v_hours_since_last_active * 0.5 * v_decay_rate);
        v_energy_decrease := LEAST(15, v_hours_since_last_active * 0.3 * v_decay_rate);
        v_happiness_decrease := LEAST(10, v_hours_since_last_active * 0.2 * v_decay_rate);
        
        -- Apply decay with bounds
        NEW.hunger = LEAST(100, OLD.hunger + v_hunger_increase);
        NEW.energy = GREATEST(0, OLD.energy - v_energy_decrease);
        
        -- Happiness decreases faster if pet is hungry or tired
        IF OLD.hunger > 60 OR OLD.energy < 30 THEN
            v_happiness_decrease := v_happiness_decrease * 1.5;
        END IF;
        
        NEW.happiness = GREATEST(0, OLD.happiness - v_happiness_decrease);
        
        -- Update mood based on new stats
        NEW.current_mood = determine_pet_mood(NEW.health, NEW.happiness, NEW.energy, NEW.hunger);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Only apply decay when reading pet data (not on every update)
-- This prevents excessive decay during active play sessions
CREATE OR REPLACE TRIGGER trigger_pet_vitals_decay
    BEFORE UPDATE ON user_pets
    FOR EACH ROW
    WHEN (OLD.last_active_at < NEW.last_active_at - INTERVAL '2 hours')
    EXECUTE FUNCTION decay_pet_vitals();

-- =====================================================
-- DAILY STATISTICS TRACKING
-- =====================================================

-- Trigger to ensure daily stats record exists
CREATE OR REPLACE FUNCTION ensure_daily_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Ensure daily stats record exists for today
    INSERT INTO pet_daily_stats (user_pet_id, user_id, date)
    VALUES (NEW.id, NEW.user_id, CURRENT_DATE)
    ON CONFLICT (user_pet_id, date) DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_ensure_daily_stats
    AFTER INSERT OR UPDATE ON user_pets
    FOR EACH ROW
    EXECUTE FUNCTION ensure_daily_stats();

-- Trigger to update daily interaction counters
CREATE OR REPLACE FUNCTION update_daily_interaction_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Update interaction count when total_interactions increases
    IF TG_OP = 'UPDATE' AND NEW.total_interactions > OLD.total_interactions THEN
        UPDATE pet_daily_stats 
        SET interactions_count = interactions_count + (NEW.total_interactions - OLD.total_interactions)
        WHERE user_pet_id = NEW.id AND date = CURRENT_DATE;
    END IF;
    
    -- Update petting count when last_pet_at changes
    IF TG_OP = 'UPDATE' AND (OLD.last_pet_at IS NULL OR NEW.last_pet_at > OLD.last_pet_at) THEN
        UPDATE pet_daily_stats 
        SET petting_count = petting_count + 1
        WHERE user_pet_id = NEW.id AND date = CURRENT_DATE;
    END IF;
    
    -- Update end-of-day vitals
    UPDATE pet_daily_stats 
    SET 
        end_happiness = NEW.happiness,
        end_energy = NEW.energy,
        end_health = NEW.health
    WHERE user_pet_id = NEW.id AND date = CURRENT_DATE;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_daily_interaction_stats
    AFTER UPDATE ON user_pets
    FOR EACH ROW
    EXECUTE FUNCTION update_daily_interaction_stats();

-- =====================================================
-- PET ACHIEVEMENT TRACKING
-- =====================================================

-- Trigger to automatically track achievements
CREATE OR REPLACE FUNCTION track_pet_achievements()
RETURNS TRIGGER AS $$
DECLARE
    v_achievement_results record;
BEGIN
    -- Track level-based achievements
    IF TG_OP = 'UPDATE' AND NEW.level > OLD.level THEN
        SELECT * INTO v_achievement_results 
        FROM update_achievement_progress(NEW.user_id, 'level_up', NEW.level, NEW.id);
    END IF;
    
    -- Track bond level achievements
    IF TG_OP = 'UPDATE' AND NEW.bond_level > OLD.bond_level THEN
        SELECT * INTO v_achievement_results 
        FROM update_achievement_progress(NEW.user_id, 'bond_level', NEW.bond_level, NEW.id);
    END IF;
    
    -- Track interaction achievements
    IF TG_OP = 'UPDATE' AND NEW.total_interactions > OLD.total_interactions THEN
        SELECT * INTO v_achievement_results 
        FROM update_achievement_progress(NEW.user_id, 'interactions', 1, NEW.id);
    END IF;
    
    -- Track care achievements (when pet reaches high happiness/health)
    IF TG_OP = 'UPDATE' AND NEW.happiness >= 90 AND OLD.happiness < 90 THEN
        SELECT * INTO v_achievement_results 
        FROM update_achievement_progress(NEW.user_id, 'high_happiness', 1, NEW.id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_pet_achievement_tracking
    AFTER UPDATE ON user_pets
    FOR EACH ROW
    EXECUTE FUNCTION track_pet_achievements();

-- =====================================================
-- FEEDING SYSTEM TRIGGERS
-- =====================================================

-- Trigger to track feeding achievements
CREATE OR REPLACE FUNCTION track_feeding_achievements()
RETURNS TRIGGER AS $$
DECLARE
    v_achievement_results record;
BEGIN
    -- Track total feeding achievements
    SELECT * INTO v_achievement_results 
    FROM update_achievement_progress(NEW.user_id, 'feeding', 1);
    
    -- Track food type specific achievements
    IF NEW.effectiveness_rating >= 4 THEN
        SELECT * INTO v_achievement_results 
        FROM update_achievement_progress(NEW.user_id, 'successful_feeding', 1);
    END IF;
    
    -- Track perfect feeding streaks
    IF NEW.effectiveness_rating = 5 THEN
        SELECT * INTO v_achievement_results 
        FROM update_achievement_progress(NEW.user_id, 'perfect_feeding', 1);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_feeding_achievements
    AFTER INSERT ON pet_feeding_history
    FOR EACH ROW
    EXECUTE FUNCTION track_feeding_achievements();

-- =====================================================
-- ACTIVITY SESSION TRIGGERS
-- =====================================================

-- Trigger to track activity and gaming achievements
CREATE OR REPLACE FUNCTION track_activity_achievements()
RETURNS TRIGGER AS $$
DECLARE
    v_achievement_results record;
BEGIN
    -- Only process completed sessions
    IF NEW.session_status = 'completed' THEN
        -- Track total gaming sessions
        SELECT * INTO v_achievement_results 
        FROM update_achievement_progress(NEW.user_id, 'gaming', 1, NEW.user_pet_id);
        
        -- Track high performance achievements
        IF NEW.performance_rating >= 0.8 THEN
            SELECT * INTO v_achievement_results 
            FROM update_achievement_progress(NEW.user_id, 'high_performance', 1, NEW.user_pet_id);
        END IF;
        
        -- Track perfect performance
        IF NEW.performance_rating >= 0.95 THEN
            SELECT * INTO v_achievement_results 
            FROM update_achievement_progress(NEW.user_id, 'perfect_performance', 1, NEW.user_pet_id);
        END IF;
        
        -- Track long gaming sessions
        IF NEW.duration_seconds >= 300 THEN -- 5 minutes
            SELECT * INTO v_achievement_results 
            FROM update_achievement_progress(NEW.user_id, 'long_session', 1, NEW.user_pet_id);
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_activity_achievements
    AFTER UPDATE ON pet_activity_sessions
    FOR EACH ROW
    WHEN (OLD.session_status IS DISTINCT FROM NEW.session_status)
    EXECUTE FUNCTION track_activity_achievements();

-- =====================================================
-- BREEDING SYSTEM TRIGGERS
-- =====================================================

-- Trigger to track breeding achievements
CREATE OR REPLACE FUNCTION track_breeding_achievements()
RETURNS TRIGGER AS $$
DECLARE
    v_achievement_results record;
BEGIN
    -- Track breeding attempts
    IF TG_OP = 'INSERT' THEN
        SELECT * INTO v_achievement_results 
        FROM update_achievement_progress(NEW.user_id, 'breeding_attempts', 1);
    END IF;
    
    -- Track successful breeding
    IF TG_OP = 'UPDATE' AND OLD.breeding_status = 'in_progress' AND NEW.breeding_status = 'completed' THEN
        SELECT * INTO v_achievement_results 
        FROM update_achievement_progress(NEW.user_id, 'successful_breeding', 1);
        
        -- Track rare offspring
        IF NEW.offspring_traits->>'inherited_rarity' IN ('epic', 'legendary', 'mythical') THEN
            SELECT * INTO v_achievement_results 
            FROM update_achievement_progress(NEW.user_id, 'rare_offspring', 1);
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_breeding_achievements
    AFTER INSERT OR UPDATE ON pet_breeding
    FOR EACH ROW
    EXECUTE FUNCTION track_breeding_achievements();

-- =====================================================
-- SOCIAL SYSTEM TRIGGERS
-- =====================================================

-- Trigger to track friendship achievements
CREATE OR REPLACE FUNCTION track_friendship_achievements()
RETURNS TRIGGER AS $$
DECLARE
    v_achievement_results record;
    v_pet1_user_id UUID;
    v_pet2_user_id UUID;
BEGIN
    -- Get user IDs for both pets
    SELECT user_id INTO v_pet1_user_id FROM user_pets WHERE id = NEW.pet1_id;
    SELECT user_id INTO v_pet2_user_id FROM user_pets WHERE id = NEW.pet2_id;
    
    -- Track friendship formation
    IF TG_OP = 'INSERT' THEN
        SELECT * INTO v_achievement_results 
        FROM update_achievement_progress(v_pet1_user_id, 'friendships', 1);
        
        IF v_pet2_user_id != v_pet1_user_id THEN
            SELECT * INTO v_achievement_results 
            FROM update_achievement_progress(v_pet2_user_id, 'friendships', 1);
        END IF;
    END IF;
    
    -- Track friendship level ups
    IF TG_OP = 'UPDATE' AND NEW.friendship_level > OLD.friendship_level THEN
        SELECT * INTO v_achievement_results 
        FROM update_achievement_progress(v_pet1_user_id, 'friendship_levels', NEW.friendship_level);
        
        IF v_pet2_user_id != v_pet1_user_id THEN
            SELECT * INTO v_achievement_results 
            FROM update_achievement_progress(v_pet2_user_id, 'friendship_levels', NEW.friendship_level);
        END IF;
        
        -- Track best friend achievement
        IF NEW.friendship_level >= 10 THEN
            SELECT * INTO v_achievement_results 
            FROM update_achievement_progress(v_pet1_user_id, 'best_friends', 1);
            
            IF v_pet2_user_id != v_pet1_user_id THEN
                SELECT * INTO v_achievement_results 
                FROM update_achievement_progress(v_pet2_user_id, 'best_friends', 1);
            END IF;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_friendship_achievements
    AFTER INSERT OR UPDATE ON pet_friendships
    FOR EACH ROW
    EXECUTE FUNCTION track_friendship_achievements();

-- =====================================================
-- COLLECTION ACHIEVEMENTS TRIGGERS
-- =====================================================

-- Trigger to track pet collection achievements
CREATE OR REPLACE FUNCTION track_collection_achievements()
RETURNS TRIGGER AS $$
DECLARE
    v_achievement_results record;
    v_user_pet_count INTEGER;
    v_user_rare_pet_count INTEGER;
    v_user_pet_types TEXT[];
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Count total pets for user
        SELECT COUNT(*) INTO v_user_pet_count
        FROM user_pets WHERE user_id = NEW.user_id;
        
        SELECT * INTO v_achievement_results 
        FROM update_achievement_progress(NEW.user_id, 'pet_collection', v_user_pet_count);
        
        -- Count rare pets
        SELECT COUNT(*) INTO v_user_rare_pet_count
        FROM user_pets 
        WHERE user_id = NEW.user_id AND rarity IN ('epic', 'legendary', 'mythical');
        
        SELECT * INTO v_achievement_results 
        FROM update_achievement_progress(NEW.user_id, 'rare_collection', v_user_rare_pet_count);
        
        -- Track pet type diversity
        SELECT array_agg(DISTINCT pet_type) INTO v_user_pet_types
        FROM user_pets WHERE user_id = NEW.user_id;
        
        SELECT * INTO v_achievement_results 
        FROM update_achievement_progress(NEW.user_id, 'pet_diversity', array_length(v_user_pet_types, 1));
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_collection_achievements
    AFTER INSERT ON user_pets
    FOR EACH ROW
    EXECUTE FUNCTION track_collection_achievements();

-- =====================================================
-- ACCESSORY SYSTEM TRIGGERS
-- =====================================================

-- Trigger to track accessory achievements
CREATE OR REPLACE FUNCTION track_accessory_achievements()
RETURNS TRIGGER AS $$
DECLARE
    v_achievement_results record;
    v_accessory_count INTEGER;
BEGIN
    -- Count user's total accessories
    SELECT COUNT(*) INTO v_accessory_count
    FROM user_pet_accessories WHERE user_id = NEW.user_id;
    
    SELECT * INTO v_achievement_results 
    FROM update_achievement_progress(NEW.user_id, 'accessory_collection', v_accessory_count);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_accessory_achievements
    AFTER INSERT ON user_pet_accessories
    FOR EACH ROW
    EXECUTE FUNCTION track_accessory_achievements();

-- =====================================================
-- SYSTEM MAINTENANCE TRIGGERS
-- =====================================================

-- Trigger to update template timestamps
CREATE OR REPLACE FUNCTION update_template_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_template_updated_at
    BEFORE UPDATE ON pet_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_template_timestamp();

CREATE OR REPLACE TRIGGER trigger_accessory_updated_at
    BEFORE UPDATE ON pet_accessories
    FOR EACH ROW
    EXECUTE FUNCTION update_template_timestamp();

CREATE OR REPLACE TRIGGER trigger_food_updated_at
    BEFORE UPDATE ON pet_foods
    FOR EACH ROW
    EXECUTE FUNCTION update_template_timestamp();

CREATE OR REPLACE TRIGGER trigger_activity_updated_at
    BEFORE UPDATE ON pet_activities
    FOR EACH ROW
    EXECUTE FUNCTION update_template_timestamp();

-- Trigger to update achievement timestamps
CREATE OR REPLACE FUNCTION update_achievement_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_achievement_progress_updated_at
    BEFORE UPDATE ON user_pet_achievements
    FOR EACH ROW
    EXECUTE FUNCTION update_achievement_timestamp();

-- =====================================================
-- DATA CONSISTENCY TRIGGERS
-- =====================================================

-- Trigger to prevent invalid pet state
CREATE OR REPLACE FUNCTION validate_pet_state()
RETURNS TRIGGER AS $$
BEGIN
    -- Ensure stats are within valid ranges
    NEW.health := GREATEST(0, LEAST(100, NEW.health));
    NEW.happiness := GREATEST(0, LEAST(100, NEW.happiness));
    NEW.energy := GREATEST(0, LEAST(100, NEW.energy));
    NEW.hunger := GREATEST(0, LEAST(100, NEW.hunger));
    
    -- Ensure level is consistent with experience
    IF NEW.experience_points >= 0 THEN
        NEW.level := GREATEST(1, 1 + (NEW.experience_points / 100));
    END IF;
    
    -- Ensure bond level is consistent with bond XP
    IF NEW.bond_xp >= 0 THEN
        NEW.bond_level := GREATEST(1, 1 + (NEW.bond_xp / 50));
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_validate_pet_state
    BEFORE INSERT OR UPDATE ON user_pets
    FOR EACH ROW
    EXECUTE FUNCTION validate_pet_state();

-- Trigger to prevent breeding between incompatible pets
CREATE OR REPLACE FUNCTION validate_breeding()
RETURNS TRIGGER AS $$
DECLARE
    v_parent1 user_pets%ROWTYPE;
    v_parent2 user_pets%ROWTYPE;
BEGIN
    SELECT * INTO v_parent1 FROM user_pets WHERE id = NEW.parent1_id;
    SELECT * INTO v_parent2 FROM user_pets WHERE id = NEW.parent2_id;
    
    -- Prevent self-breeding
    IF NEW.parent1_id = NEW.parent2_id THEN
        RAISE EXCEPTION 'A pet cannot breed with itself';
    END IF;
    
    -- Check minimum levels
    IF v_parent1.level < 5 OR v_parent2.level < 5 THEN
        RAISE EXCEPTION 'Both pets must be at least level 5 to breed';
    END IF;
    
    -- Check health requirements
    IF v_parent1.health < 80 OR v_parent2.health < 80 THEN
        RAISE EXCEPTION 'Both pets must have at least 80%% health to breed';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_validate_breeding
    BEFORE INSERT ON pet_breeding
    FOR EACH ROW
    EXECUTE FUNCTION validate_breeding();

-- =====================================================
-- AUTOMATED MAINTENANCE FUNCTIONS
-- =====================================================

-- Function to clean up old data (to be called by scheduled job)
CREATE OR REPLACE FUNCTION cleanup_old_pet_data()
RETURNS TABLE(
    cleaned_sessions INTEGER,
    cleaned_daily_stats INTEGER,
    cleaned_feeding_history INTEGER
) AS $$
DECLARE
    v_cleaned_sessions INTEGER := 0;
    v_cleaned_daily_stats INTEGER := 0;
    v_cleaned_feeding_history INTEGER := 0;
BEGIN
    -- Clean up old activity sessions (keep only last 90 days)
    DELETE FROM pet_activity_sessions 
    WHERE started_at < NOW() - INTERVAL '90 days';
    GET DIAGNOSTICS v_cleaned_sessions = ROW_COUNT;
    
    -- Clean up old daily stats (keep only last 365 days)
    DELETE FROM pet_daily_stats 
    WHERE date < CURRENT_DATE - INTERVAL '365 days';
    GET DIAGNOSTICS v_cleaned_daily_stats = ROW_COUNT;
    
    -- Clean up old feeding history (keep only last 180 days)
    DELETE FROM pet_feeding_history 
    WHERE fed_at < NOW() - INTERVAL '180 days';
    GET DIAGNOSTICS v_cleaned_feeding_history = ROW_COUNT;
    
    -- Update vacuum statistics
    ANALYZE pet_activity_sessions;
    ANALYZE pet_daily_stats;
    ANALYZE pet_feeding_history;
    
    cleaned_sessions := v_cleaned_sessions;
    cleaned_daily_stats := v_cleaned_daily_stats;
    cleaned_feeding_history := v_cleaned_feeding_history;
    
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- Function to complete expired breeding processes
CREATE OR REPLACE FUNCTION complete_expired_breeding()
RETURNS INTEGER AS $$
DECLARE
    v_breeding_record pet_breeding%ROWTYPE;
    v_completed_count INTEGER := 0;
    v_offspring_result record;
BEGIN
    -- Process all breeding that should be completed
    FOR v_breeding_record IN 
        SELECT * FROM pet_breeding 
        WHERE breeding_status = 'in_progress' 
        AND breeding_completed_at <= NOW()
    LOOP
        -- Complete the breeding
        SELECT * INTO v_offspring_result 
        FROM complete_pet_breeding(v_breeding_record.id);
        
        IF v_offspring_result.success THEN
            v_completed_count := v_completed_count + 1;
        END IF;
    END LOOP;
    
    RETURN v_completed_count;
END;
$$ LANGUAGE plpgsql;
