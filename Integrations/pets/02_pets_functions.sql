-- =====================================================
-- CRYSTAL SOCIAL - PETS SYSTEM FUNCTIONS
-- =====================================================
-- Advanced functions for pet management, care, activities,
-- breeding, achievements and social interactions
-- =====================================================

-- Drop existing functions to prevent conflicts
DROP FUNCTION IF EXISTS create_user_pet CASCADE;
DROP FUNCTION IF EXISTS update_pet_vitals CASCADE;
DROP FUNCTION IF EXISTS determine_pet_mood CASCADE;
DROP FUNCTION IF EXISTS feed_pet CASCADE;
DROP FUNCTION IF EXISTS start_pet_activity CASCADE;
DROP FUNCTION IF EXISTS complete_pet_activity CASCADE;
DROP FUNCTION IF EXISTS start_pet_breeding CASCADE;
DROP FUNCTION IF EXISTS complete_pet_breeding CASCADE;
DROP FUNCTION IF EXISTS update_pet_achievement_progress CASCADE;
DROP FUNCTION IF EXISTS update_pet_friendship CASCADE;
DROP FUNCTION IF EXISTS get_user_pet_statistics CASCADE;
DROP FUNCTION IF EXISTS get_pets_needing_attention CASCADE;

-- =====================================================
-- PET CREATION AND MANAGEMENT FUNCTIONS
-- =====================================================

-- Create a new pet for a user
CREATE OR REPLACE FUNCTION create_user_pet(
    p_user_id UUID,
    p_pet_type VARCHAR(50),
    p_pet_name VARCHAR(100),
    p_rarity VARCHAR(20) DEFAULT 'common',
    p_personality VARCHAR(20) DEFAULT 'friendly'
)
RETURNS UUID AS $$
DECLARE
    v_pet_id UUID;
    v_template pet_templates%ROWTYPE;
BEGIN
    -- Get pet template
    SELECT * INTO v_template
    FROM pet_templates 
    WHERE pet_type = p_pet_type;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pet type % not found', p_pet_type;
    END IF;
    
    -- Create the pet
    INSERT INTO user_pets (
        user_id, pet_type, pet_name, rarity, personality,
        health, happiness, energy, current_mood,
        hatched_at, last_active_at
    ) VALUES (
        p_user_id, p_pet_type, p_pet_name, p_rarity, p_personality,
        (v_template.base_stats->>'health')::DECIMAL,
        (v_template.base_stats->>'happiness')::DECIMAL,
        (v_template.base_stats->>'energy')::DECIMAL,
        'content',
        NOW(), NOW()
    )
    RETURNING id INTO v_pet_id;
    
    -- Initialize daily stats
    INSERT INTO pet_daily_stats (user_pet_id, user_id, date)
    VALUES (v_pet_id, p_user_id, CURRENT_DATE)
    ON CONFLICT (user_pet_id, date) DO NOTHING;
    
    -- Ensure user has pet settings
    INSERT INTO user_pet_settings (user_id)
    VALUES (p_user_id)
    ON CONFLICT (user_id) DO NOTHING;
    
    RETURN v_pet_id;
END;
$$ LANGUAGE plpgsql;

-- Update pet vital statistics
CREATE OR REPLACE FUNCTION update_pet_vitals(
    p_pet_id UUID,
    p_health_change DECIMAL DEFAULT 0,
    p_happiness_change DECIMAL DEFAULT 0,
    p_energy_change DECIMAL DEFAULT 0,
    p_hunger_change DECIMAL DEFAULT 0
)
RETURNS TABLE(
    new_health DECIMAL,
    new_happiness DECIMAL,
    new_energy DECIMAL,
    new_hunger DECIMAL,
    mood_changed BOOLEAN
) AS $$
DECLARE
    v_pet user_pets%ROWTYPE;
    v_old_mood VARCHAR(20);
    v_new_mood VARCHAR(20);
BEGIN
    -- Get current pet state
    SELECT * INTO v_pet FROM user_pets WHERE id = p_pet_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pet with ID % not found', p_pet_id;
    END IF;
    
    v_old_mood := v_pet.current_mood;
    
    -- Update vitals with bounds checking
    UPDATE user_pets SET
        health = GREATEST(0, LEAST(100, health + p_health_change)),
        happiness = GREATEST(0, LEAST(100, happiness + p_happiness_change)),
        energy = GREATEST(0, LEAST(100, energy + p_energy_change)),
        hunger = GREATEST(0, LEAST(100, hunger + p_hunger_change)),
        last_active_at = NOW(),
        updated_at = NOW()
    WHERE id = p_pet_id;
    
    -- Get updated values
    SELECT health, happiness, energy, hunger INTO new_health, new_happiness, new_energy, new_hunger
    FROM user_pets WHERE id = p_pet_id;
    
    -- Determine new mood based on stats
    v_new_mood := determine_pet_mood(new_health, new_happiness, new_energy, new_hunger);
    
    -- Update mood if changed
    IF v_new_mood != v_old_mood THEN
        UPDATE user_pets SET current_mood = v_new_mood WHERE id = p_pet_id;
        mood_changed := true;
    ELSE
        mood_changed := false;
    END IF;
    
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- Determine pet mood based on vital statistics
CREATE OR REPLACE FUNCTION determine_pet_mood(
    p_health DECIMAL,
    p_happiness DECIMAL,
    p_energy DECIMAL,
    p_hunger DECIMAL
)
RETURNS VARCHAR(20) AS $$
BEGIN
    -- Sick condition (low health)
    IF p_health < 30 THEN
        RETURN 'sick';
    END IF;
    
    -- Extremely hungry
    IF p_hunger > 80 THEN
        RETURN 'hungry';
    END IF;
    
    -- Very tired (low energy)
    IF p_energy < 20 THEN
        RETURN 'sleepy';
    END IF;
    
    -- Very unhappy
    IF p_happiness < 25 THEN
        RETURN 'sad';
    END IF;
    
    -- Angry (multiple low stats)
    IF p_health < 50 AND p_happiness < 50 AND p_energy < 50 THEN
        RETURN 'angry';
    END IF;
    
    -- Excited (very high happiness and energy)
    IF p_happiness > 90 AND p_energy > 80 THEN
        RETURN 'excited';
    END IF;
    
    -- Happy (high happiness)
    IF p_happiness > 75 THEN
        RETURN 'happy';
    END IF;
    
    -- Playful (high energy, good happiness)
    IF p_energy > 70 AND p_happiness > 60 THEN
        RETURN 'playful';
    END IF;
    
    -- Default content mood
    RETURN 'content';
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- PET FEEDING FUNCTIONS
-- =====================================================

-- Feed a pet with specific food
CREATE OR REPLACE FUNCTION feed_pet(
    p_user_id UUID,
    p_pet_id UUID,
    p_food_id UUID,
    p_quantity INTEGER DEFAULT 1
)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    health_change DECIMAL,
    happiness_change DECIMAL,
    energy_change DECIMAL,
    hunger_change DECIMAL,
    effectiveness_rating INTEGER,
    pet_reaction VARCHAR(50)
) AS $$
DECLARE
    v_pet user_pets%ROWTYPE;
    v_food pet_foods%ROWTYPE;
    v_effectiveness INTEGER;
    v_reaction VARCHAR(50);
    v_health_change DECIMAL;
    v_happiness_change DECIMAL;
    v_energy_change DECIMAL;
    v_hunger_change DECIMAL;
    v_type_preference BOOLEAN;
BEGIN
    -- Get pet and food details
    SELECT * INTO v_pet FROM user_pets WHERE id = p_pet_id AND user_id = p_user_id;
    SELECT * INTO v_food FROM pet_foods WHERE id = p_food_id;
    
    IF NOT FOUND THEN
        success := false;
        message := 'Pet or food not found';
        RETURN NEXT;
        RETURN;
    END IF;
    
    -- Check if pet's type has preference for this food
    v_type_preference := v_pet.pet_type = ANY(v_food.preferred_by_types);
    
    -- Calculate effectiveness based on preferences and current stats
    v_effectiveness := CASE
        WHEN v_pet.pet_type = ANY(v_food.disliked_by_types) THEN 1
        WHEN v_type_preference THEN 5
        WHEN v_pet.hunger > 70 THEN 4  -- Very hungry pets appreciate any food
        WHEN v_pet.happiness < 50 THEN 3  -- Unhappy pets get some boost
        ELSE 3  -- Neutral reaction
    END;
    
    -- Determine pet reaction
    v_reaction := CASE v_effectiveness
        WHEN 5 THEN 'loved'
        WHEN 4 THEN 'liked'
        WHEN 3 THEN 'neutral'
        WHEN 2 THEN 'disliked'
        ELSE 'hated'
    END;
    
    -- Calculate stat changes with effectiveness multiplier
    v_health_change := (v_food.health_boost * p_quantity * v_effectiveness / 3.0);
    v_happiness_change := (v_food.happiness_boost * p_quantity * v_effectiveness / 3.0);
    v_energy_change := (v_food.energy_boost * p_quantity * v_effectiveness / 3.0);
    v_hunger_change := -(v_food.hunger_reduction * p_quantity); -- Negative because it reduces hunger
    
    -- Apply feeding effects
    PERFORM update_pet_vitals(
        p_pet_id, 
        v_health_change, 
        v_happiness_change, 
        v_energy_change, 
        v_hunger_change
    );
    
    -- Update last fed time
    UPDATE user_pets SET last_fed_at = NOW() WHERE id = p_pet_id;
    
    -- Record feeding history
    INSERT INTO pet_feeding_history (
        user_pet_id, food_id, user_id, quantity,
        effectiveness_rating, pet_reaction,
        health_change, happiness_change, energy_change, hunger_change
    ) VALUES (
        p_pet_id, p_food_id, p_user_id, p_quantity,
        v_effectiveness, v_reaction,
        v_health_change, v_happiness_change, v_energy_change, v_hunger_change
    );
    
    -- Update daily stats
    UPDATE pet_daily_stats SET
        feeding_count = feeding_count + 1,
        happiness_gained = happiness_gained + GREATEST(0, v_happiness_change),
        health_change = health_change + v_health_change
    WHERE user_pet_id = p_pet_id AND date = CURRENT_DATE;
    
    -- Return results
    success := true;
    message := format('Fed %s with %s. Pet reaction: %s', v_pet.pet_name, v_food.name, v_reaction);
    health_change := v_health_change;
    happiness_change := v_happiness_change;
    energy_change := v_energy_change;
    hunger_change := v_hunger_change;
    effectiveness_rating := v_effectiveness;
    pet_reaction := v_reaction;
    
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- PET ACTIVITY AND MINI-GAME FUNCTIONS
-- =====================================================

-- Start a pet activity session
CREATE OR REPLACE FUNCTION start_pet_activity(
    p_user_id UUID,
    p_pet_id UUID,
    p_activity_id UUID
)
RETURNS TABLE(
    session_id UUID,
    success BOOLEAN,
    message TEXT,
    energy_required DECIMAL,
    estimated_rewards JSONB
) AS $$
DECLARE
    v_pet user_pets%ROWTYPE;
    v_activity pet_activities%ROWTYPE;
    v_session_id UUID;
    v_last_activity TIMESTAMP;
    v_cooldown_remaining INTEGER;
BEGIN
    -- Get pet and activity details
    SELECT * INTO v_pet FROM user_pets WHERE id = p_pet_id AND user_id = p_user_id;
    SELECT * INTO v_activity FROM pet_activities WHERE id = p_activity_id AND is_active = true;
    
    IF v_pet.id IS NULL THEN
        success := false;
        message := 'Pet not found or not owned by user';
        RETURN NEXT;
        RETURN;
    END IF;
    
    IF v_activity.id IS NULL THEN
        success := false;
        message := 'Activity not found or not available';
        RETURN NEXT;
        RETURN;
    END IF;
    
    -- Check pet level requirement
    IF v_pet.level < v_activity.minimum_pet_level THEN
        success := false;
        message := format('Pet level %s required (current: %s)', v_activity.minimum_pet_level, v_pet.level);
        RETURN NEXT;
        RETURN;
    END IF;
    
    -- Check energy requirement
    IF v_pet.energy < v_activity.minimum_energy THEN
        success := false;
        message := format('Pet needs at least %s energy (current: %s)', v_activity.minimum_energy, v_pet.energy);
        RETURN NEXT;
        RETURN;
    END IF;
    
    -- Check cooldown
    SELECT MAX(completed_at) INTO v_last_activity
    FROM pet_activity_sessions
    WHERE user_pet_id = p_pet_id AND activity_id = p_activity_id;
    
    IF v_last_activity IS NOT NULL THEN
        v_cooldown_remaining := v_activity.cooldown_minutes - EXTRACT(EPOCH FROM (NOW() - v_last_activity)) / 60;
        IF v_cooldown_remaining > 0 THEN
            success := false;
            message := format('Activity on cooldown for %s more minutes', v_cooldown_remaining);
            RETURN NEXT;
            RETURN;
        END IF;
    END IF;
    
    -- Create activity session
    INSERT INTO pet_activity_sessions (
        user_pet_id, activity_id, user_id, started_at
    ) VALUES (
        p_pet_id, p_activity_id, p_user_id, NOW()
    ) RETURNING id INTO v_session_id;
    
    -- Return success response
    session_id := v_session_id;
    success := true;
    message := format('Started activity: %s', v_activity.name);
    energy_required := v_activity.energy_cost;
    estimated_rewards := jsonb_build_object(
        'happiness', v_activity.base_happiness_reward,
        'experience', v_activity.base_experience_reward,
        'bond_xp', v_activity.base_bond_xp_reward
    );
    
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- Complete a pet activity session with results
CREATE OR REPLACE FUNCTION complete_pet_activity(
    p_session_id UUID,
    p_score DECIMAL DEFAULT 0,
    p_performance_rating DECIMAL DEFAULT 0.5,
    p_game_data JSONB DEFAULT '{}'
)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    rewards_earned JSONB,
    achievements_unlocked TEXT[]
) AS $$
DECLARE
    v_session pet_activity_sessions%ROWTYPE;
    v_activity pet_activities%ROWTYPE;
    v_pet user_pets%ROWTYPE;
    v_happiness_gained DECIMAL;
    v_experience_gained INTEGER;
    v_bond_xp_gained INTEGER;
    v_energy_spent DECIMAL;
    v_duration INTEGER;
    v_achievements TEXT[] := ARRAY[]::TEXT[];
    v_level_before INTEGER;
    v_level_after INTEGER;
BEGIN
    -- Get session details
    SELECT * INTO v_session FROM pet_activity_sessions WHERE id = p_session_id AND completed_at IS NULL;
    
    IF NOT FOUND THEN
        success := false;
        message := 'Session not found or already completed';
        RETURN NEXT;
        RETURN;
    END IF;
    
    -- Get activity details
    SELECT * INTO v_activity FROM pet_activities WHERE id = v_session.activity_id;
    
    -- Get pet details
    SELECT * INTO v_pet FROM user_pets WHERE id = v_session.user_pet_id;
    
    -- Calculate duration
    v_duration := EXTRACT(EPOCH FROM (NOW() - v_session.started_at));
    
    -- Calculate rewards based on performance
    v_happiness_gained := v_activity.base_happiness_reward * (0.5 + p_performance_rating * 0.5);
    v_experience_gained := ROUND(v_activity.base_experience_reward * (0.7 + p_performance_rating * 0.6));
    v_bond_xp_gained := ROUND(v_activity.base_bond_xp_reward * (0.8 + p_performance_rating * 0.4));
    v_energy_spent := v_activity.energy_cost;
    
    v_level_before := v_pet.level;
    
    -- Update pet stats
    PERFORM update_pet_vitals(
        v_session.user_pet_id,
        0, -- health change
        v_happiness_gained,
        -v_energy_spent,
        0 -- hunger change
    );
    
    -- Update experience and bond XP
    UPDATE user_pets SET
        experience_points = experience_points + v_experience_gained,
        level = 1 + (experience_points + v_experience_gained) / 100, -- Level up every 100 XP
        bond_xp = bond_xp + v_bond_xp_gained,
        bond_level = 1 + (bond_xp + v_bond_xp_gained) / 50, -- Bond level up every 50 XP
        total_interactions = total_interactions + 1,
        last_played_at = NOW()
    WHERE id = v_session.user_pet_id;
    
    -- Check for level up
    SELECT level INTO v_level_after FROM user_pets WHERE id = v_session.user_pet_id;
    
    -- Complete the session
    UPDATE pet_activity_sessions SET
        completed_at = NOW(),
        duration_seconds = v_duration,
        score = p_score,
        performance_rating = p_performance_rating,
        happiness_gained = v_happiness_gained,
        energy_spent = v_energy_spent,
        experience_gained = v_experience_gained,
        bond_xp_gained = v_bond_xp_gained,
        game_data = p_game_data,
        session_status = 'completed'
    WHERE id = p_session_id;
    
    -- Update daily stats
    INSERT INTO pet_daily_stats (user_pet_id, user_id, date, playing_count, happiness_gained, energy_spent, experience_gained, bond_xp_gained, game_time_minutes)
    VALUES (v_session.user_pet_id, v_session.user_id, CURRENT_DATE, 1, v_happiness_gained, v_energy_spent, v_experience_gained, v_bond_xp_gained, CEIL(v_duration / 60.0))
    ON CONFLICT (user_pet_id, date) DO UPDATE SET
        playing_count = pet_daily_stats.playing_count + 1,
        happiness_gained = pet_daily_stats.happiness_gained + EXCLUDED.happiness_gained,
        energy_spent = pet_daily_stats.energy_spent + EXCLUDED.energy_spent,
        experience_gained = pet_daily_stats.experience_gained + EXCLUDED.experience_gained,
        bond_xp_gained = pet_daily_stats.bond_xp_gained + EXCLUDED.bond_xp_gained,
        game_time_minutes = pet_daily_stats.game_time_minutes + EXCLUDED.game_time_minutes;
    
    -- Check for level up achievement
    IF v_level_after > v_level_before THEN
        v_achievements := array_append(v_achievements, format('Level Up! Reached level %s', v_level_after));
    END IF;
    
    -- Return results
    success := true;
    message := format('Completed %s! Score: %s', v_activity.name, p_score);
    rewards_earned := jsonb_build_object(
        'happiness', v_happiness_gained,
        'experience', v_experience_gained,
        'bond_xp', v_bond_xp_gained,
        'energy_spent', v_energy_spent
    );
    achievements_unlocked := v_achievements;
    
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- PET BREEDING FUNCTIONS
-- =====================================================

-- Start breeding process between two pets
CREATE OR REPLACE FUNCTION start_pet_breeding(
    p_user_id UUID,
    p_parent1_id UUID,
    p_parent2_id UUID,
    p_breeding_method VARCHAR(50) DEFAULT 'natural'
)
RETURNS TABLE(
    breeding_id UUID,
    success BOOLEAN,
    message TEXT,
    estimated_completion TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    v_parent1 user_pets%ROWTYPE;
    v_parent2 user_pets%ROWTYPE;
    v_breeding_id UUID;
    v_incubation_time INTEGER;
    v_completion_time TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Verify both pets exist and belong to user (or check breeding permissions)
    SELECT * INTO v_parent1 FROM user_pets WHERE id = p_parent1_id;
    SELECT * INTO v_parent2 FROM user_pets WHERE id = p_parent2_id;
    
    IF v_parent1.id IS NULL OR v_parent2.id IS NULL THEN
        success := false;
        message := 'One or both parent pets not found';
        RETURN NEXT;
        RETURN;
    END IF;
    
    -- Check breeding eligibility (level, health, etc.)
    IF v_parent1.level < 5 OR v_parent2.level < 5 THEN
        success := false;
        message := 'Both pets must be at least level 5 to breed';
        RETURN NEXT;
        RETURN;
    END IF;
    
    IF v_parent1.health < 80 OR v_parent2.health < 80 THEN
        success := false;
        message := 'Both pets must have at least 80% health to breed';
        RETURN NEXT;
        RETURN;
    END IF;
    
    -- Check if pets are already breeding
    IF EXISTS (SELECT 1 FROM pet_breeding WHERE (parent1_id = p_parent1_id OR parent2_id = p_parent1_id OR parent1_id = p_parent2_id OR parent2_id = p_parent2_id) AND breeding_status = 'in_progress') THEN
        success := false;
        message := 'One or both pets are already involved in breeding';
        RETURN NEXT;
        RETURN;
    END IF;
    
    -- Calculate incubation time based on pet rarities and method
    v_incubation_time := CASE p_breeding_method
        WHEN 'magical' THEN 720  -- 12 hours
        WHEN 'laboratory' THEN 360  -- 6 hours
        ELSE 1440  -- 24 hours for natural
    END;
    
    -- Adjust time based on parent rarities
    IF v_parent1.rarity IN ('legendary', 'mythical') OR v_parent2.rarity IN ('legendary', 'mythical') THEN
        v_incubation_time := v_incubation_time * 2;
    END IF;
    
    v_completion_time := NOW() + INTERVAL '1 minute' * v_incubation_time;
    
    -- Create breeding record
    INSERT INTO pet_breeding (
        parent1_id, parent2_id, user_id, breeding_method,
        incubation_time_minutes, breeding_completed_at
    ) VALUES (
        p_parent1_id, p_parent2_id, p_user_id, p_breeding_method,
        v_incubation_time, v_completion_time
    ) RETURNING id INTO v_breeding_id;
    
    -- Return success
    breeding_id := v_breeding_id;
    success := true;
    message := format('Breeding started between %s and %s', v_parent1.pet_name, v_parent2.pet_name);
    estimated_completion := v_completion_time;
    
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- Complete breeding and generate offspring
CREATE OR REPLACE FUNCTION complete_pet_breeding(p_breeding_id UUID)
RETURNS TABLE(
    offspring_id UUID,
    success BOOLEAN,
    message TEXT,
    offspring_traits JSONB
) AS $$
DECLARE
    v_breeding pet_breeding%ROWTYPE;
    v_parent1 user_pets%ROWTYPE;
    v_parent2 user_pets%ROWTYPE;
    v_offspring_id UUID;
    v_offspring_type VARCHAR(50);
    v_offspring_rarity VARCHAR(20);
    v_offspring_personality VARCHAR(20);
    v_offspring_name VARCHAR(100);
    v_traits JSONB := '{}';
BEGIN
    -- Get breeding details
    SELECT * INTO v_breeding FROM pet_breeding WHERE id = p_breeding_id AND breeding_status = 'in_progress';
    
    IF NOT FOUND THEN
        success := false;
        message := 'Breeding not found or already completed';
        RETURN NEXT;
        RETURN;
    END IF;
    
    -- Check if breeding time is complete
    IF NOW() < v_breeding.breeding_completed_at THEN
        success := false;
        message := 'Breeding not yet complete';
        RETURN NEXT;
        RETURN;
    END IF;
    
    -- Get parent details
    SELECT * INTO v_parent1 FROM user_pets WHERE id = v_breeding.parent1_id;
    SELECT * INTO v_parent2 FROM user_pets WHERE id = v_breeding.parent2_id;
    
    -- Determine offspring characteristics (simplified genetics)
    -- Choose dominant parent type (could be more complex)
    v_offspring_type := CASE WHEN random() < 0.5 THEN v_parent1.pet_type ELSE v_parent2.pet_type END;
    
    -- Determine rarity (chance for rarity upgrade)
    v_offspring_rarity := CASE
        WHEN v_parent1.rarity = 'mythical' OR v_parent2.rarity = 'mythical' THEN
            CASE WHEN random() < 0.3 THEN 'mythical' ELSE 'legendary' END
        WHEN v_parent1.rarity = 'legendary' OR v_parent2.rarity = 'legendary' THEN
            CASE WHEN random() < 0.2 THEN 'legendary' ELSE 'epic' END
        WHEN v_parent1.rarity = 'epic' OR v_parent2.rarity = 'epic' THEN
            CASE WHEN random() < 0.3 THEN 'epic' ELSE 'rare' END
        ELSE 'common'
    END;
    
    -- Combine personalities
    v_offspring_personality := CASE WHEN random() < 0.5 THEN v_parent1.personality ELSE v_parent2.personality END;
    
    -- Generate offspring name
    v_offspring_name := format('%s Jr.', CASE WHEN random() < 0.5 THEN v_parent1.pet_name ELSE v_parent2.pet_name END);
    
    -- Create offspring
    v_offspring_id := create_user_pet(
        v_breeding.user_id,
        v_offspring_type,
        v_offspring_name,
        v_offspring_rarity,
        v_offspring_personality
    );
    
    -- Build traits JSON
    v_traits := jsonb_build_object(
        'parent1_type', v_parent1.pet_type,
        'parent2_type', v_parent2.pet_type,
        'inherited_rarity', v_offspring_rarity,
        'inherited_personality', v_offspring_personality,
        'breeding_method', v_breeding.breeding_method
    );
    
    -- Update breeding record
    UPDATE pet_breeding SET
        breeding_status = 'completed',
        offspring_pet_id = v_offspring_id,
        offspring_traits = v_traits
    WHERE id = p_breeding_id;
    
    -- Return results
    offspring_id := v_offspring_id;
    success := true;
    message := format('Successfully bred %s!', v_offspring_name);
    offspring_traits := v_traits;
    
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- PET ACHIEVEMENT FUNCTIONS
-- =====================================================

-- Check and update achievement progress for a user
CREATE OR REPLACE FUNCTION update_pet_achievement_progress(
    p_user_id UUID,
    p_achievement_type VARCHAR(50),
    p_progress_value DECIMAL DEFAULT 1,
    p_pet_id UUID DEFAULT NULL
)
RETURNS TABLE(
    achievements_completed TEXT[],
    rewards_earned JSONB
) AS $$
DECLARE
    v_achievement pet_achievements%ROWTYPE;
    v_progress user_pet_achievements%ROWTYPE;
    v_completed_achievements TEXT[] := ARRAY[]::TEXT[];
    v_total_rewards JSONB := '{}';
    v_achievement_reward JSONB;
BEGIN
    -- Loop through relevant achievements
    FOR v_achievement IN 
        SELECT * FROM pet_achievements 
        WHERE 
            (p_achievement_type = 'all' OR 
             category = p_achievement_type OR 
             requirement_type = p_achievement_type)
            AND (NOT is_secret OR p_achievement_type = 'all')
    LOOP
        -- Get or create progress record
        INSERT INTO user_pet_achievements (user_id, achievement_id, user_pet_id, target_progress)
        VALUES (p_user_id, v_achievement.id, p_pet_id, (v_achievement.requirement_data->>'target')::DECIMAL)
        ON CONFLICT (user_id, achievement_id, user_pet_id) DO NOTHING;
        
        SELECT * INTO v_progress 
        FROM user_pet_achievements 
        WHERE user_id = p_user_id AND achievement_id = v_achievement.id 
        AND (user_pet_id = p_pet_id OR (user_pet_id IS NULL AND p_pet_id IS NULL));
        
        -- Update progress if not completed
        IF v_progress.is_completed = false THEN
            UPDATE user_pet_achievements SET
                current_progress = current_progress + p_progress_value,
                last_updated_at = NOW()
            WHERE id = v_progress.id;
            
            -- Check if achievement is now completed
            IF v_progress.current_progress + p_progress_value >= v_progress.target_progress THEN
                UPDATE user_pet_achievements SET
                    is_completed = true,
                    completed_at = NOW(),
                    completion_count = completion_count + 1
                WHERE id = v_progress.id;
                
                -- Add to completed list
                v_completed_achievements := array_append(v_completed_achievements, v_achievement.name);
                
                -- Build reward object
                v_achievement_reward := jsonb_build_object(
                    'experience', v_achievement.reward_experience,
                    'bond_xp', v_achievement.reward_bond_xp,
                    'currency', v_achievement.reward_currency,
                    'items', v_achievement.reward_items
                );
                
                -- Accumulate rewards
                v_total_rewards := v_total_rewards || v_achievement_reward;
            END IF;
        END IF;
    END LOOP;
    
    achievements_completed := v_completed_achievements;
    rewards_earned := v_total_rewards;
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- PET SOCIAL FUNCTIONS
-- =====================================================

-- Create or update pet friendship
CREATE OR REPLACE FUNCTION update_pet_friendship(
    p_pet1_id UUID,
    p_pet2_id UUID,
    p_interaction_xp INTEGER DEFAULT 1
)
RETURNS TABLE(
    friendship_level INTEGER,
    friendship_xp INTEGER,
    level_up BOOLEAN
) AS $$
DECLARE
    v_friendship pet_friendships%ROWTYPE;
    v_old_level INTEGER;
    v_new_level INTEGER;
BEGIN
    -- Ensure consistent ordering (smaller ID first)
    IF p_pet1_id > p_pet2_id THEN
        -- Swap the IDs
        SELECT p_pet2_id, p_pet1_id INTO p_pet1_id, p_pet2_id;
    END IF;
    
    -- Get existing friendship or create new one
    INSERT INTO pet_friendships (pet1_id, pet2_id, friendship_xp, total_interactions)
    VALUES (p_pet1_id, p_pet2_id, p_interaction_xp, 1)
    ON CONFLICT (pet1_id, pet2_id) DO UPDATE SET
        friendship_xp = pet_friendships.friendship_xp + p_interaction_xp,
        total_interactions = pet_friendships.total_interactions + 1,
        last_interaction_at = NOW();
    
    -- Get updated friendship
    SELECT * INTO v_friendship FROM pet_friendships WHERE pet1_id = p_pet1_id AND pet2_id = p_pet2_id;
    
    v_old_level := v_friendship.friendship_level;
    v_new_level := 1 + (v_friendship.friendship_xp / 20); -- Level up every 20 XP
    
    -- Update level if changed
    IF v_new_level != v_old_level THEN
        UPDATE pet_friendships SET friendship_level = v_new_level WHERE pet1_id = p_pet1_id AND pet2_id = p_pet2_id;
    END IF;
    
    friendship_level := v_new_level;
    friendship_xp := v_friendship.friendship_xp;
    level_up := v_new_level > v_old_level;
    
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- PET STATISTICS AND ANALYTICS FUNCTIONS
-- =====================================================

-- Get comprehensive pet statistics for a user
CREATE OR REPLACE FUNCTION get_user_pet_statistics(p_user_id UUID, p_days_back INTEGER DEFAULT 30)
RETURNS TABLE(
    total_pets INTEGER,
    active_pets INTEGER,
    total_interactions INTEGER,
    total_feeding_sessions INTEGER,
    total_play_sessions INTEGER,
    average_happiness DECIMAL,
    average_health DECIMAL,
    average_energy DECIMAL,
    highest_level INTEGER,
    total_achievements INTEGER,
    recent_activity JSONB
) AS $$
DECLARE
    v_start_date DATE;
BEGIN
    v_start_date := CURRENT_DATE - INTERVAL '1 day' * p_days_back;
    
    SELECT 
        COUNT(*)::INTEGER,
        COUNT(*) FILTER (WHERE last_active_at > NOW() - INTERVAL '7 days')::INTEGER,
        SUM(total_interactions)::INTEGER,
        COALESCE(SUM(daily_stats.feeding_count), 0)::INTEGER,
        COALESCE(SUM(daily_stats.playing_count), 0)::INTEGER,
        ROUND(AVG(up.happiness), 2),
        ROUND(AVG(up.health), 2),
        ROUND(AVG(up.energy), 2),
        MAX(up.level)::INTEGER,
        COUNT(upa.id)::INTEGER
    INTO 
        total_pets, active_pets, total_interactions, 
        total_feeding_sessions, total_play_sessions,
        average_happiness, average_health, average_energy,
        highest_level, total_achievements
    FROM user_pets up
    LEFT JOIN (
        SELECT user_pet_id, SUM(feeding_count) as feeding_count, SUM(playing_count) as playing_count
        FROM pet_daily_stats 
        WHERE user_id = p_user_id AND date >= v_start_date
        GROUP BY user_pet_id
    ) daily_stats ON up.id = daily_stats.user_pet_id
    LEFT JOIN user_pet_achievements upa ON up.user_id = upa.user_id AND upa.is_completed = true
    WHERE up.user_id = p_user_id;
    
    -- Get recent activity summary
    SELECT jsonb_agg(
        jsonb_build_object(
            'date', date,
            'interactions', interactions_count,
            'happiness_gained', happiness_gained,
            'experience_gained', experience_gained
        ) ORDER BY date DESC
    ) INTO recent_activity
    FROM pet_daily_stats
    WHERE user_id = p_user_id AND date >= v_start_date;
    
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- Daily pet care reminder check
CREATE OR REPLACE FUNCTION get_pets_needing_attention(p_user_id UUID)
RETURNS TABLE(
    pet_id UUID,
    pet_name VARCHAR(100),
    attention_reasons TEXT[],
    urgency_level INTEGER
) AS $$
DECLARE
    v_pet user_pets%ROWTYPE;
    v_reasons TEXT[];
    v_urgency INTEGER;
BEGIN
    FOR v_pet IN 
        SELECT * FROM user_pets WHERE user_id = p_user_id
    LOOP
        v_reasons := ARRAY[]::TEXT[];
        v_urgency := 0;
        
        -- Check various care needs
        IF v_pet.health < 50 THEN
            v_reasons := array_append(v_reasons, 'Low health');
            v_urgency := v_urgency + 3;
        END IF;
        
        IF v_pet.happiness < 40 THEN
            v_reasons := array_append(v_reasons, 'Unhappy');
            v_urgency := v_urgency + 2;
        END IF;
        
        IF v_pet.energy < 30 THEN
            v_reasons := array_append(v_reasons, 'Low energy');
            v_urgency := v_urgency + 1;
        END IF;
        
        IF v_pet.hunger > 70 THEN
            v_reasons := array_append(v_reasons, 'Very hungry');
            v_urgency := v_urgency + 2;
        END IF;
        
        IF v_pet.last_fed_at < NOW() - INTERVAL '12 hours' THEN
            v_reasons := array_append(v_reasons, 'Hasn''t been fed recently');
            v_urgency := v_urgency + 1;
        END IF;
        
        IF v_pet.last_played_at < NOW() - INTERVAL '24 hours' THEN
            v_reasons := array_append(v_reasons, 'Needs playtime');
            v_urgency := v_urgency + 1;
        END IF;
        
        -- Return pets that need attention
        IF array_length(v_reasons, 1) > 0 THEN
            pet_id := v_pet.id;
            pet_name := v_pet.pet_name;
            attention_reasons := v_reasons;
            urgency_level := v_urgency;
            RETURN NEXT;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
