-- =====================================================
-- CRYSTAL SOCIAL - GEMS SYSTEM FUNCTIONS
-- =====================================================
-- Stored functions for gem operations and collection logic
-- =====================================================

-- Function to unlock a new gem for a user
CREATE OR REPLACE FUNCTION unlock_gem(
    p_user_id UUID,
    p_gem_id UUID,
    p_unlock_source VARCHAR DEFAULT 'manual',
    p_unlock_context JSONB DEFAULT '{}'::jsonb
) RETURNS JSONB AS $$
DECLARE
    v_gem RECORD;
    v_user_stats RECORD;
    v_discovery_event_id UUID;
    v_experience_gained INTEGER := 0;
    v_coins_gained INTEGER := 0;
    v_gems_gained INTEGER := 0;
    v_was_rare_unlock BOOLEAN := false;
    v_result JSONB;
BEGIN
    -- Check if gem exists and is active
    SELECT * INTO v_gem FROM enhanced_gemstones WHERE id = p_gem_id AND is_active = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Gem not found or not active';
    END IF;
    
    -- Check if user already has this gem
    IF EXISTS(SELECT 1 FROM user_gemstones WHERE user_id = p_user_id AND gem_id = p_gem_id) THEN
        RAISE EXCEPTION 'User already owns this gem';
    END IF;
    
    -- Determine if this is a rare unlock
    v_was_rare_unlock := v_gem.rarity IN ('epic', 'legendary', 'mythic');
    
    -- Calculate rewards based on rarity
    v_experience_gained := CASE v_gem.rarity
        WHEN 'mythic' THEN 500
        WHEN 'legendary' THEN 250
        WHEN 'epic' THEN 100
        WHEN 'rare' THEN 50
        WHEN 'uncommon' THEN 25
        ELSE 10
    END;
    
    v_coins_gained := CASE v_gem.rarity
        WHEN 'mythic' THEN 1000
        WHEN 'legendary' THEN 500
        WHEN 'epic' THEN 200
        WHEN 'rare' THEN 100
        WHEN 'uncommon' THEN 50
        ELSE 25
    END;
    
    v_gems_gained := CASE v_gem.rarity
        WHEN 'mythic' THEN 50
        WHEN 'legendary' THEN 25
        WHEN 'epic' THEN 10
        WHEN 'rare' THEN 5
        WHEN 'uncommon' THEN 2
        ELSE 0
    END;
    
    -- Add gem to user's collection
    INSERT INTO user_gemstones (
        user_id,
        gem_id,
        unlock_source,
        unlock_context,
        power_level
    ) VALUES (
        p_user_id,
        p_gem_id,
        p_unlock_source,
        p_unlock_context,
        1
    );
    
    -- Record discovery event
    INSERT INTO gem_discovery_events (
        user_id,
        gem_id,
        discovery_method,
        discovery_location,
        discovery_context,
        was_rare_unlock,
        experience_gained,
        coins_gained,
        gems_gained
    ) VALUES (
        p_user_id,
        p_gem_id,
        p_unlock_source,
        COALESCE(p_unlock_context->>'location', 'unknown'),
        p_unlock_context,
        v_was_rare_unlock,
        v_experience_gained,
        v_coins_gained,
        v_gems_gained
    ) RETURNING id INTO v_discovery_event_id;
    
    -- Update user's profile with rewards
    UPDATE profiles SET
        coins = coins + v_coins_gained,
        gems = gems + v_gems_gained,
        experience = experience + v_experience_gained,
        updated_at = NOW()
    WHERE id = p_user_id;
    
    -- Update gem collection statistics
    PERFORM update_gem_collection_stats(p_user_id);
    
    -- Update analytics
    INSERT INTO gem_analytics (user_id, date, gems_discovered, total_value_gained, total_power_gained)
    VALUES (p_user_id, CURRENT_DATE, 1, v_gem.value, v_gem.power)
    ON CONFLICT (user_id, date)
    DO UPDATE SET 
        gems_discovered = gem_analytics.gems_discovered + 1,
        total_value_gained = gem_analytics.total_value_gained + v_gem.value,
        total_power_gained = gem_analytics.total_power_gained + v_gem.power;
    
    -- Check for achievement unlocks
    PERFORM check_gem_achievements(p_user_id);
    
    -- Build result
    v_result := jsonb_build_object(
        'success', true,
        'gem', to_jsonb(v_gem),
        'discovery_event_id', v_discovery_event_id,
        'rewards', jsonb_build_object(
            'experience', v_experience_gained,
            'coins', v_coins_gained,
            'gems', v_gems_gained
        ),
        'was_rare_unlock', v_was_rare_unlock
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to discover random gems based on method
CREATE OR REPLACE FUNCTION discover_random_gem(
    p_user_id UUID,
    p_discovery_method VARCHAR DEFAULT 'random',
    p_discovery_context JSONB DEFAULT '{}'::jsonb
) RETURNS JSONB AS $$
DECLARE
    v_method RECORD;
    v_available_gems UUID[];
    v_selected_gem_id UUID;
    v_rarity_roll DECIMAL;
    v_selected_rarity VARCHAR;
    v_result JSONB;
BEGIN
    -- Get discovery method details
    SELECT * INTO v_method 
    FROM gem_discovery_methods 
    WHERE method_name = p_discovery_method AND is_active = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Discovery method not found or not active: %', p_discovery_method;
    END IF;
    
    -- Check cooldown and requirements here if needed
    
    -- Determine rarity based on weights
    v_rarity_roll := random() * 100;
    
    IF v_rarity_roll <= (v_method.rarity_weights->>'mythic')::decimal THEN
        v_selected_rarity := 'mythic';
    ELSIF v_rarity_roll <= (v_method.rarity_weights->>'legendary')::decimal + (v_method.rarity_weights->>'mythic')::decimal THEN
        v_selected_rarity := 'legendary';
    ELSIF v_rarity_roll <= (v_method.rarity_weights->>'epic')::decimal + (v_method.rarity_weights->>'legendary')::decimal + (v_method.rarity_weights->>'mythic')::decimal THEN
        v_selected_rarity := 'epic';
    ELSIF v_rarity_roll <= 40 THEN
        v_selected_rarity := 'rare';
    ELSIF v_rarity_roll <= 70 THEN
        v_selected_rarity := 'uncommon';
    ELSE
        v_selected_rarity := 'common';
    END IF;
    
    -- Get available gems of selected rarity that user doesn't have
    SELECT ARRAY_AGG(eg.id) INTO v_available_gems
    FROM enhanced_gemstones eg
    WHERE eg.rarity = v_selected_rarity
    AND eg.is_active = true
    AND NOT EXISTS (
        SELECT 1 FROM user_gemstones ug 
        WHERE ug.user_id = p_user_id AND ug.gem_id = eg.id
    );
    
    -- If no gems available of that rarity, try lower rarities
    IF v_available_gems IS NULL OR array_length(v_available_gems, 1) = 0 THEN
        SELECT ARRAY_AGG(eg.id) INTO v_available_gems
        FROM enhanced_gemstones eg
        WHERE eg.is_active = true
        AND NOT EXISTS (
            SELECT 1 FROM user_gemstones ug 
            WHERE ug.user_id = p_user_id AND ug.gem_id = eg.id
        )
        ORDER BY 
            CASE eg.rarity
                WHEN 'mythic' THEN 6
                WHEN 'legendary' THEN 5
                WHEN 'epic' THEN 4
                WHEN 'rare' THEN 3
                WHEN 'uncommon' THEN 2
                ELSE 1
            END DESC
        LIMIT 50;
    END IF;
    
    -- If still no gems available, return failure
    IF v_available_gems IS NULL OR array_length(v_available_gems, 1) = 0 THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'No gems available for discovery'
        );
    END IF;
    
    -- Randomly select a gem
    v_selected_gem_id := v_available_gems[1 + floor(random() * array_length(v_available_gems, 1))];
    
    -- Unlock the selected gem
    v_result := unlock_gem(
        p_user_id,
        v_selected_gem_id,
        p_discovery_method,
        p_discovery_context
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to enhance a user's gem
CREATE OR REPLACE FUNCTION enhance_gem(
    p_user_id UUID,
    p_user_gem_id UUID,
    p_enhancement_type VARCHAR DEFAULT 'power',
    p_enhancement_materials JSONB DEFAULT '[]'::jsonb,
    p_cost_coins INTEGER DEFAULT 0,
    p_cost_gems INTEGER DEFAULT 0
) RETURNS JSONB AS $$
DECLARE
    v_user_gem RECORD;
    v_user_profile RECORD;
    v_enhancement_id UUID;
    v_power_boost INTEGER := 0;
    v_value_boost INTEGER := 0;
    v_success_rate DECIMAL := 95.0;
    v_was_successful BOOLEAN;
    v_result JSONB;
BEGIN
    -- Get user gem details
    SELECT ug.*, eg.name, eg.rarity, eg.power, eg.value
    INTO v_user_gem
    FROM user_gemstones ug
    JOIN enhanced_gemstones eg ON ug.gem_id = eg.id
    WHERE ug.id = p_user_gem_id AND ug.user_id = p_user_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'User gem not found or access denied';
    END IF;
    
    -- Check if user can afford enhancement
    SELECT coins, gems INTO v_user_profile FROM profiles WHERE id = p_user_id;
    
    IF v_user_profile.coins < p_cost_coins OR v_user_profile.gems < p_cost_gems THEN
        RAISE EXCEPTION 'Insufficient funds for enhancement';
    END IF;
    
    -- Calculate enhancement effects
    v_power_boost := CASE p_enhancement_type
        WHEN 'power' THEN 10 + (v_user_gem.enhancement_level * 5)
        WHEN 'value' THEN 5 + (v_user_gem.enhancement_level * 2)
        WHEN 'special' THEN 15 + (v_user_gem.enhancement_level * 8)
        ELSE 10
    END;
    
    v_value_boost := CASE p_enhancement_type
        WHEN 'value' THEN 50 + (v_user_gem.enhancement_level * 25)
        WHEN 'power' THEN 20 + (v_user_gem.enhancement_level * 10)
        WHEN 'special' THEN 30 + (v_user_gem.enhancement_level * 15)
        ELSE 20
    END;
    
    -- Calculate success rate (decreases with higher enhancement levels)
    v_success_rate := GREATEST(50.0, 95.0 - (v_user_gem.enhancement_level * 5.0));
    
    -- Determine success
    v_was_successful := random() * 100 <= v_success_rate;
    
    -- Deduct costs
    UPDATE profiles SET
        coins = coins - p_cost_coins,
        gems = gems - p_cost_gems,
        updated_at = NOW()
    WHERE id = p_user_id;
    
    -- Record enhancement attempt
    INSERT INTO gem_enhancements (
        user_gem_id,
        enhancement_type,
        enhancement_level,
        enhancement_materials,
        enhancement_cost_coins,
        enhancement_cost_gems,
        power_boost,
        value_boost,
        enhanced_by,
        success_rate,
        was_successful
    ) VALUES (
        p_user_gem_id,
        p_enhancement_type,
        v_user_gem.enhancement_level + 1,
        p_enhancement_materials,
        p_cost_coins,
        p_cost_gems,
        CASE WHEN v_was_successful THEN v_power_boost ELSE 0 END,
        CASE WHEN v_was_successful THEN v_value_boost ELSE 0 END,
        p_user_id,
        v_success_rate,
        v_was_successful
    ) RETURNING id INTO v_enhancement_id;
    
    -- Update gem if successful
    IF v_was_successful THEN
        UPDATE user_gemstones SET
            enhancement_level = enhancement_level + 1,
            power_level = power_level + v_power_boost,
            updated_at = NOW()
        WHERE id = p_user_gem_id;
        
        -- Update analytics
        INSERT INTO gem_analytics (user_id, date, gems_enhanced, gems_spent_on_enhancements, total_power_gained)
        VALUES (p_user_id, CURRENT_DATE, 1, p_cost_gems, v_power_boost)
        ON CONFLICT (user_id, date)
        DO UPDATE SET 
            gems_enhanced = gem_analytics.gems_enhanced + 1,
            gems_spent_on_enhancements = gem_analytics.gems_spent_on_enhancements + p_cost_gems,
            total_power_gained = gem_analytics.total_power_gained + v_power_boost;
    END IF;
    
    -- Update collection stats
    PERFORM update_gem_collection_stats(p_user_id);
    
    v_result := jsonb_build_object(
        'success', v_was_successful,
        'enhancement_id', v_enhancement_id,
        'enhancement_level', v_user_gem.enhancement_level + CASE WHEN v_was_successful THEN 1 ELSE 0 END,
        'power_boost', CASE WHEN v_was_successful THEN v_power_boost ELSE 0 END,
        'value_boost', CASE WHEN v_was_successful THEN v_value_boost ELSE 0 END,
        'success_rate', v_success_rate
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update gem collection statistics
CREATE OR REPLACE FUNCTION update_gem_collection_stats(p_user_id UUID) RETURNS VOID AS $$
DECLARE
    v_stats RECORD;
    v_rarity_stats JSONB := '{}'::jsonb;
    v_element_stats JSONB := '{}'::jsonb;
    v_total_gems INTEGER;
    v_completion_percentage DECIMAL;
    v_rarest_gem VARCHAR;
BEGIN
    -- Calculate basic stats
    SELECT 
        COUNT(*) as total_unlocked,
        COUNT(DISTINCT gem_id) as unique_collected,
        SUM(eg.value + COALESCE(ug.enhancement_level * 50, 0)) as total_value,
        SUM(eg.power + COALESCE(ug.power_level - 1, 0)) as total_power,
        SUM(CASE WHEN ug.is_favorite THEN 1 ELSE 0 END) as favorites_count,
        MIN(ug.unlocked_at) as first_unlock,
        MAX(ug.unlocked_at) as last_unlock,
        (SELECT gem_id FROM user_gemstones ug2 JOIN enhanced_gemstones eg2 ON ug2.gem_id = eg2.id 
         WHERE ug2.user_id = p_user_id ORDER BY eg2.value DESC LIMIT 1) as most_valuable_gem
    INTO v_stats
    FROM user_gemstones ug
    JOIN enhanced_gemstones eg ON ug.gem_id = eg.id
    WHERE ug.user_id = p_user_id;
    
    -- Calculate rarity distribution
    SELECT jsonb_object_agg(rarity, gem_count) INTO v_rarity_stats
    FROM (
        SELECT eg.rarity, COUNT(*) as gem_count
        FROM user_gemstones ug
        JOIN enhanced_gemstones eg ON ug.gem_id = eg.id
        WHERE ug.user_id = p_user_id
        GROUP BY eg.rarity
    ) rarity_counts;
    
    -- Calculate element distribution
    SELECT jsonb_object_agg(element, gem_count) INTO v_element_stats
    FROM (
        SELECT eg.element, COUNT(*) as gem_count
        FROM user_gemstones ug
        JOIN enhanced_gemstones eg ON ug.gem_id = eg.id
        WHERE ug.user_id = p_user_id
        GROUP BY eg.element
    ) element_counts;
    
    -- Calculate completion percentage
    SELECT COUNT(*) INTO v_total_gems FROM enhanced_gemstones WHERE is_active = true;
    v_completion_percentage := CASE 
        WHEN v_total_gems > 0 THEN (v_stats.unique_collected::DECIMAL / v_total_gems) * 100
        ELSE 0
    END;
    
    -- Get rarest gem unlocked
    SELECT eg.rarity INTO v_rarest_gem
    FROM user_gemstones ug
    JOIN enhanced_gemstones eg ON ug.gem_id = eg.id
    WHERE ug.user_id = p_user_id
    ORDER BY 
        CASE eg.rarity
            WHEN 'mythic' THEN 6
            WHEN 'legendary' THEN 5
            WHEN 'epic' THEN 4
            WHEN 'rare' THEN 3
            WHEN 'uncommon' THEN 2
            ELSE 1
        END DESC
    LIMIT 1;
    
    -- Update or insert statistics
    INSERT INTO gem_collection_stats (
        user_id,
        total_gems_unlocked,
        unique_gems_collected,
        total_collection_value,
        total_collection_power,
        favorite_gems_count,
        rarity_stats,
        element_stats,
        completion_percentage,
        first_gem_unlocked_at,
        last_gem_unlocked_at,
        most_valuable_gem_id,
        rarest_gem_unlocked
    ) VALUES (
        p_user_id,
        COALESCE(v_stats.total_unlocked, 0),
        COALESCE(v_stats.unique_collected, 0),
        COALESCE(v_stats.total_value, 0),
        COALESCE(v_stats.total_power, 0),
        COALESCE(v_stats.favorites_count, 0),
        COALESCE(v_rarity_stats, '{}'::jsonb),
        COALESCE(v_element_stats, '{}'::jsonb),
        v_completion_percentage,
        v_stats.first_unlock,
        v_stats.last_unlock,
        v_stats.most_valuable_gem,
        v_rarest_gem
    )
    ON CONFLICT (user_id)
    DO UPDATE SET
        total_gems_unlocked = EXCLUDED.total_gems_unlocked,
        unique_gems_collected = EXCLUDED.unique_gems_collected,
        total_collection_value = EXCLUDED.total_collection_value,
        total_collection_power = EXCLUDED.total_collection_power,
        favorite_gems_count = EXCLUDED.favorite_gems_count,
        rarity_stats = EXCLUDED.rarity_stats,
        element_stats = EXCLUDED.element_stats,
        completion_percentage = EXCLUDED.completion_percentage,
        first_gem_unlocked_at = EXCLUDED.first_gem_unlocked_at,
        last_gem_unlocked_at = EXCLUDED.last_gem_unlocked_at,
        most_valuable_gem_id = EXCLUDED.most_valuable_gem_id,
        rarest_gem_unlocked = EXCLUDED.rarest_gem_unlocked,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check and unlock gem achievements
CREATE OR REPLACE FUNCTION check_gem_achievements(p_user_id UUID) RETURNS INTEGER AS $$
DECLARE
    v_achievement RECORD;
    v_current_value INTEGER;
    v_unlocked_count INTEGER := 0;
    v_stats RECORD;
BEGIN
    -- Get current user stats
    SELECT * INTO v_stats FROM gem_collection_stats WHERE user_id = p_user_id;
    
    IF NOT FOUND THEN
        PERFORM update_gem_collection_stats(p_user_id);
        SELECT * INTO v_stats FROM gem_collection_stats WHERE user_id = p_user_id;
    END IF;
    
    -- Check each incomplete achievement
    FOR v_achievement IN 
        SELECT * FROM gem_achievements 
        WHERE user_id = p_user_id AND NOT is_completed
    LOOP
        v_current_value := 0;
        
        -- Calculate current value based on achievement type
        CASE v_achievement.achievement_type
            WHEN 'first_gem' THEN
                v_current_value := CASE WHEN v_stats.total_gems_unlocked > 0 THEN 1 ELSE 0 END;
                
            WHEN 'gem_collector' THEN
                v_current_value := v_stats.unique_gems_collected;
                
            WHEN 'rarity_collector' THEN
                -- Check specific rarity achievements
                v_current_value := COALESCE((v_stats.rarity_stats->>v_achievement.unlock_requirements->>'rarity')::integer, 0);
                
            WHEN 'element_master' THEN
                -- Check specific element achievements
                v_current_value := COALESCE((v_stats.element_stats->>v_achievement.unlock_requirements->>'element')::integer, 0);
                
            WHEN 'power_accumulator' THEN
                v_current_value := v_stats.total_collection_power;
                
            WHEN 'value_accumulator' THEN
                v_current_value := v_stats.total_collection_value;
                
            WHEN 'enhancer' THEN
                SELECT COUNT(*) INTO v_current_value
                FROM gem_enhancements ge
                JOIN user_gemstones ug ON ge.user_gem_id = ug.id
                WHERE ug.user_id = p_user_id AND ge.was_successful = true;
                
            WHEN 'completionist' THEN
                v_current_value := FLOOR(v_stats.completion_percentage);
                
            ELSE
                CONTINUE; -- Unknown achievement type
        END CASE;
        
        -- Update achievement progress
        UPDATE gem_achievements
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
            UPDATE profiles
            SET 
                coins = coins + v_achievement.reward_coins,
                gems = gems + v_achievement.reward_gems,
                updated_at = NOW()
            WHERE id = p_user_id;
            
            v_unlocked_count := v_unlocked_count + 1;
        END IF;
    END LOOP;
    
    RETURN v_unlocked_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to toggle gem favorite status
CREATE OR REPLACE FUNCTION toggle_gem_favorite(
    p_user_id UUID,
    p_gem_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
    v_current_status BOOLEAN;
    v_new_status BOOLEAN;
BEGIN
    -- Get current favorite status
    SELECT is_favorite INTO v_current_status
    FROM user_gemstones
    WHERE user_id = p_user_id AND gem_id = p_gem_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'User does not own this gem';
    END IF;
    
    v_new_status := NOT v_current_status;
    
    -- Update favorite status
    UPDATE user_gemstones
    SET 
        is_favorite = v_new_status,
        updated_at = NOW()
    WHERE user_id = p_user_id AND gem_id = p_gem_id;
    
    -- Update analytics
    INSERT INTO gem_analytics (user_id, date, favorites_added, favorites_removed)
    VALUES (
        p_user_id, 
        CURRENT_DATE, 
        CASE WHEN v_new_status THEN 1 ELSE 0 END,
        CASE WHEN v_new_status THEN 0 ELSE 1 END
    )
    ON CONFLICT (user_id, date)
    DO UPDATE SET 
        favorites_added = gem_analytics.favorites_added + CASE WHEN v_new_status THEN 1 ELSE 0 END,
        favorites_removed = gem_analytics.favorites_removed + CASE WHEN v_new_status THEN 0 ELSE 1 END;
    
    -- Update collection stats
    PERFORM update_gem_collection_stats(p_user_id);
    
    RETURN v_new_status;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get gem collection overview
CREATE OR REPLACE FUNCTION get_gem_collection_overview(p_user_id UUID)
RETURNS TABLE (
    collection_stats JSONB,
    recent_discoveries JSONB,
    achievement_progress JSONB,
    daily_quest_progress JSONB,
    recommendations JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        -- Collection statistics
        to_jsonb(gcs.*) as collection_stats,
        
        -- Recent discoveries (last 10)
        (SELECT jsonb_agg(
            jsonb_build_object(
                'gem_name', eg.name,
                'gem_rarity', eg.rarity,
                'gem_element', eg.element,
                'discovered_at', gde.created_at,
                'discovery_method', gde.discovery_method,
                'was_rare_unlock', gde.was_rare_unlock
            )
        )
        FROM gem_discovery_events gde
        JOIN enhanced_gemstones eg ON gde.gem_id = eg.id
        WHERE gde.user_id = p_user_id
        ORDER BY gde.created_at DESC
        LIMIT 10) as recent_discoveries,
        
        -- Achievement progress (incomplete achievements)
        (SELECT jsonb_agg(
            jsonb_build_object(
                'name', achievement_name,
                'description', description,
                'current_value', current_value,
                'target_value', target_value,
                'progress_percentage', progress_percentage,
                'reward_coins', reward_coins,
                'reward_gems', reward_gems
            )
        )
        FROM gem_achievements
        WHERE user_id = p_user_id AND NOT is_completed
        ORDER BY progress_percentage DESC
        LIMIT 5) as achievement_progress,
        
        -- Today's quest progress
        (SELECT jsonb_agg(
            jsonb_build_object(
                'name', quest_name,
                'description', description,
                'current_value', current_value,
                'target_value', target_value,
                'progress_percentage', progress_percentage,
                'is_completed', is_completed,
                'reward_coins', reward_coins,
                'reward_gems', reward_gems
            )
        )
        FROM gem_daily_quests
        WHERE user_id = p_user_id AND quest_date = CURRENT_DATE) as daily_quest_progress,
        
        -- Gem recommendations (gems user doesn't have, ordered by discovery weight)
        (SELECT jsonb_agg(
            jsonb_build_object(
                'id', eg.id,
                'name', eg.name,
                'description', eg.description,
                'rarity', eg.rarity,
                'element', eg.element,
                'image_path', eg.image_path,
                'discovery_weight', eg.discovery_weight
            )
        )
        FROM enhanced_gemstones eg
        WHERE eg.is_active = true
        AND NOT EXISTS (
            SELECT 1 FROM user_gemstones ug 
            WHERE ug.user_id = p_user_id AND ug.gem_id = eg.id
        )
        ORDER BY eg.discovery_weight DESC, random()
        LIMIT 10) as recommendations
        
    FROM gem_collection_stats gcs
    WHERE gcs.user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
