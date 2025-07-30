-- =====================================================
-- CRYSTAL SOCIAL - GARDEN SYSTEM FUNCTIONS
-- =====================================================
-- Stored functions for garden operations and game logic
-- =====================================================

-- Function to create a new garden for a user
CREATE OR REPLACE FUNCTION create_garden(
    p_user_id UUID,
    p_name VARCHAR DEFAULT 'My Garden',
    p_theme VARCHAR DEFAULT 'classic',
    p_background_image VARCHAR DEFAULT 'assets/garden/backgrounds/garden_1.png'
) RETURNS UUID AS $$
DECLARE
    v_garden_id UUID;
BEGIN
    -- Create the garden
    INSERT INTO gardens (
        user_id,
        name,
        theme,
        background_image,
        max_flowers
    ) VALUES (
        p_user_id,
        p_name,
        p_theme,
        p_background_image,
        6 -- Starting max flowers
    ) RETURNING id INTO v_garden_id;
    
    -- Initialize starting inventory
    INSERT INTO garden_inventory (garden_id, item_type, item_name, quantity) VALUES
        (v_garden_id, 'resource', 'water', 10),
        (v_garden_id, 'resource', 'fertilizer', 5),
        (v_garden_id, 'resource', 'pesticide', 3),
        (v_garden_id, 'seed', 'seeds_common', 5),
        (v_garden_id, 'seed', 'seeds_rare', 1);
    
    -- Create initial achievements
    INSERT INTO garden_achievements (garden_id, achievement_type, achievement_name, description, target_value)
    VALUES 
        (v_garden_id, 'first_plant', 'First Bloom', 'Plant your first flower', 1),
        (v_garden_id, 'flower_collector', 'Green Thumb', 'Grow 10 flowers', 10),
        (v_garden_id, 'level_up', 'Garden Master', 'Reach garden level 5', 5),
        (v_garden_id, 'visitor_host', 'Welcoming Garden', 'Receive 5 garden visitors', 5);
    
    RETURN v_garden_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to plant a flower in a garden
CREATE OR REPLACE FUNCTION plant_flower(
    p_garden_id UUID,
    p_species_id UUID,
    p_x_position DECIMAL,
    p_y_position DECIMAL,
    p_user_id UUID
) RETURNS UUID AS $$
DECLARE
    v_flower_id UUID;
    v_max_flowers INTEGER;
    v_current_count INTEGER;
    v_species_rarity VARCHAR;
    v_has_seeds BOOLEAN;
BEGIN
    -- Check if user owns the garden
    IF NOT EXISTS(SELECT 1 FROM gardens WHERE id = p_garden_id AND user_id = p_user_id) THEN
        RAISE EXCEPTION 'User does not own this garden';
    END IF;
    
    -- Check flower capacity
    SELECT max_flowers INTO v_max_flowers FROM gardens WHERE id = p_garden_id;
    SELECT COUNT(*) INTO v_current_count FROM flowers WHERE garden_id = p_garden_id;
    
    IF v_current_count >= v_max_flowers THEN
        RAISE EXCEPTION 'Garden has reached maximum flower capacity';
    END IF;
    
    -- Get species rarity and check if user has seeds
    SELECT rarity INTO v_species_rarity FROM flower_species WHERE id = p_species_id;
    
    SELECT quantity > 0 INTO v_has_seeds 
    FROM garden_inventory 
    WHERE garden_id = p_garden_id 
    AND item_type = 'seed' 
    AND item_name = 'seeds_' || v_species_rarity;
    
    IF NOT v_has_seeds THEN
        RAISE EXCEPTION 'Not enough seeds of rarity: %', v_species_rarity;
    END IF;
    
    -- Use a seed
    UPDATE garden_inventory 
    SET quantity = quantity - 1 
    WHERE garden_id = p_garden_id 
    AND item_type = 'seed' 
    AND item_name = 'seeds_' || v_species_rarity;
    
    -- Plant the flower
    INSERT INTO flowers (
        garden_id,
        species_id,
        x_position,
        y_position,
        rarity
    ) VALUES (
        p_garden_id,
        p_species_id,
        p_x_position,
        p_y_position,
        v_species_rarity
    ) RETURNING id INTO v_flower_id;
    
    -- Update garden statistics
    UPDATE gardens 
    SET 
        total_flowers_grown = total_flowers_grown + 1,
        updated_at = NOW()
    WHERE id = p_garden_id;
    
    -- Track analytics
    INSERT INTO garden_analytics (garden_id, date, flowers_planted)
    VALUES (p_garden_id, CURRENT_DATE, 1)
    ON CONFLICT (garden_id, date)
    DO UPDATE SET flowers_planted = garden_analytics.flowers_planted + 1;
    
    RETURN v_flower_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to water a flower
CREATE OR REPLACE FUNCTION water_flower(
    p_flower_id UUID,
    p_user_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
    v_garden_id UUID;
    v_has_water BOOLEAN;
    v_health_bonus INTEGER := 10;
    v_happiness_bonus INTEGER := 5;
BEGIN
    -- Get garden ID and check ownership
    SELECT g.id INTO v_garden_id
    FROM flowers f
    JOIN gardens g ON f.garden_id = g.id
    WHERE f.id = p_flower_id AND g.user_id = p_user_id;
    
    IF v_garden_id IS NULL THEN
        RAISE EXCEPTION 'Flower not found or access denied';
    END IF;
    
    -- Check if user has water
    SELECT quantity > 0 INTO v_has_water
    FROM garden_inventory
    WHERE garden_id = v_garden_id 
    AND item_type = 'resource' 
    AND item_name = 'water';
    
    IF NOT v_has_water THEN
        RAISE EXCEPTION 'No water available';
    END IF;
    
    -- Use water
    UPDATE garden_inventory
    SET quantity = quantity - 1
    WHERE garden_id = v_garden_id 
    AND item_type = 'resource' 
    AND item_name = 'water';
    
    -- Water the flower
    UPDATE flowers
    SET 
        last_watered_at = NOW(),
        health = LEAST(100, health + v_health_bonus),
        happiness = LEAST(100, happiness + v_happiness_bonus),
        total_waterings = total_waterings + 1,
        is_wilting = false,
        updated_at = NOW()
    WHERE id = p_flower_id;
    
    -- Track analytics
    INSERT INTO garden_analytics (garden_id, date, flowers_watered)
    VALUES (v_garden_id, CURRENT_DATE, 1)
    ON CONFLICT (garden_id, date)
    DO UPDATE SET flowers_watered = garden_analytics.flowers_watered + 1;
    
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to fertilize a flower
CREATE OR REPLACE FUNCTION fertilize_flower(
    p_flower_id UUID,
    p_user_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
    v_garden_id UUID;
    v_has_fertilizer BOOLEAN;
    v_health_bonus INTEGER := 20;
    v_happiness_bonus INTEGER := 15;
BEGIN
    -- Get garden ID and check ownership
    SELECT g.id INTO v_garden_id
    FROM flowers f
    JOIN gardens g ON f.garden_id = g.id
    WHERE f.id = p_flower_id AND g.user_id = p_user_id;
    
    IF v_garden_id IS NULL THEN
        RAISE EXCEPTION 'Flower not found or access denied';
    END IF;
    
    -- Check if user has fertilizer
    SELECT quantity > 0 INTO v_has_fertilizer
    FROM garden_inventory
    WHERE garden_id = v_garden_id 
    AND item_type = 'resource' 
    AND item_name = 'fertilizer';
    
    IF NOT v_has_fertilizer THEN
        RAISE EXCEPTION 'No fertilizer available';
    END IF;
    
    -- Use fertilizer
    UPDATE garden_inventory
    SET quantity = quantity - 1
    WHERE garden_id = v_garden_id 
    AND item_type = 'resource' 
    AND item_name = 'fertilizer';
    
    -- Fertilize the flower
    UPDATE flowers
    SET 
        last_fertilized_at = NOW(),
        health = LEAST(100, health + v_health_bonus),
        happiness = LEAST(100, happiness + v_happiness_bonus),
        total_fertilizations = total_fertilizations + 1,
        updated_at = NOW()
    WHERE id = p_flower_id;
    
    -- Track analytics
    INSERT INTO garden_analytics (garden_id, date, flowers_fertilized)
    VALUES (v_garden_id, CURRENT_DATE, 1)
    ON CONFLICT (garden_id, date)
    DO UPDATE SET flowers_fertilized = garden_analytics.flowers_fertilized + 1;
    
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to try growing a flower (called periodically)
CREATE OR REPLACE FUNCTION try_grow_flower(p_flower_id UUID) RETURNS BOOLEAN AS $$
DECLARE
    v_flower RECORD;
    v_species RECORD;
    v_can_grow BOOLEAN := false;
    v_growth_chance DECIMAL;
    v_new_stage VARCHAR;
    v_bloomed BOOLEAN := false;
    v_experience INTEGER;
    v_coins INTEGER;
BEGIN
    -- Get flower details
    SELECT * INTO v_flower FROM flowers WHERE id = p_flower_id;
    
    IF NOT FOUND THEN
        RETURN false;
    END IF;
    
    -- Get species details
    SELECT * INTO v_species FROM flower_species WHERE id = v_flower.species_id;
    -- Get species details
    SELECT * INTO v_species FROM flower_species WHERE id = v_flower.species_id;
    
    -- Check if flower can grow
    IF v_flower.growth_stage = 'bloomed' THEN
        RETURN false;
    END IF;
    
    -- Check basic growth requirements
    IF v_flower.last_watered_at IS NULL OR 
       NOW() - v_flower.last_watered_at < INTERVAL '1 hour' OR
       v_flower.health < 30 THEN
        RETURN false;
    END IF;
    
    v_can_grow := true;
    
    -- Calculate growth chance based on rarity
    v_growth_chance := CASE v_flower.rarity
        WHEN 'common' THEN 0.8
        WHEN 'rare' THEN 0.4
        WHEN 'epic' THEN 0.3
        ELSE 0.5
    END;
    
    -- Apply fertilizer bonus
    IF v_flower.last_fertilized_at IS NOT NULL AND 
       NOW() - v_flower.last_fertilized_at < INTERVAL '12 hours' THEN
        v_growth_chance := v_growth_chance * 1.5;
    END IF;
    
    -- Apply happiness bonus
    v_growth_chance := v_growth_chance * (0.5 + v_flower.happiness / 200.0);
    
    -- Random chance check
    IF random() > v_growth_chance THEN
        RETURN false;
    END IF;
    
    -- Determine new growth stage
    v_new_stage := CASE v_flower.growth_stage
        WHEN 'seed' THEN 'sprout'
        WHEN 'sprout' THEN 'bud'
        WHEN 'bud' THEN 'bloomed'
        ELSE v_flower.growth_stage
    END;
    
    v_bloomed := (v_new_stage = 'bloomed' AND v_flower.growth_stage != 'bloomed');
    
    -- Update flower
    UPDATE flowers
    SET 
        growth_stage = v_new_stage,
        growth_events = growth_events + 1,
        has_bloomed = has_bloomed OR v_bloomed,
        first_bloom_at = CASE WHEN v_bloomed AND first_bloom_at IS NULL THEN NOW() ELSE first_bloom_at END,
        has_special_effect = CASE WHEN v_bloomed AND rarity = 'epic' THEN true ELSE has_special_effect END,
        current_size = CASE v_new_stage
            WHEN 'sprout' THEN 0.5
            WHEN 'bud' THEN 0.7
            WHEN 'bloomed' THEN 1.0
            ELSE current_size
        END,
        updated_at = NOW()
    WHERE id = p_flower_id;
    
    -- Give rewards
    v_experience := CASE WHEN v_bloomed THEN 
        COALESCE(v_species.bloom_experience, 25) 
    ELSE 
        COALESCE(v_species.base_experience, 10) 
    END;
    
    v_coins := CASE WHEN v_bloomed THEN 
        COALESCE(v_species.bloom_coins, 15) 
    ELSE 
        COALESCE(v_species.base_coins, 5) 
    END;
    
    -- Update garden with rewards
    UPDATE gardens
    SET 
        experience = experience + v_experience,
        coins = coins + v_coins,
        total_flowers_bloomed = total_flowers_bloomed + CASE WHEN v_bloomed THEN 1 ELSE 0 END,
        updated_at = NOW()
    WHERE id = v_flower.garden_id;
    
    -- Check for level up
    PERFORM check_garden_level_up(v_flower.garden_id);
    
    -- Track analytics
    IF v_bloomed THEN
        INSERT INTO garden_analytics (garden_id, date, flowers_bloomed, coins_earned)
        VALUES (v_flower.garden_id, CURRENT_DATE, 1, v_coins)
        ON CONFLICT (garden_id, date)
        DO UPDATE SET 
            flowers_bloomed = garden_analytics.flowers_bloomed + 1,
            coins_earned = garden_analytics.coins_earned + v_coins;
    END IF;
    
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check and handle garden level up
CREATE OR REPLACE FUNCTION check_garden_level_up(p_garden_id UUID) RETURNS INTEGER AS $$
DECLARE
    v_garden RECORD;
    v_new_level INTEGER;
    v_level_ups INTEGER := 0;
    v_required_exp INTEGER;
BEGIN
    SELECT * INTO v_garden FROM gardens WHERE id = p_garden_id;
    
    LOOP
        v_required_exp := v_garden.level * 100;
        
        IF v_garden.experience < v_required_exp THEN
            EXIT;
        END IF;
        
        v_new_level := v_garden.level + 1;
        v_level_ups := v_level_ups + 1;
        
        -- Level up rewards
        UPDATE gardens
        SET 
            level = v_new_level,
            experience = experience - v_required_exp,
            coins = coins + (v_new_level * 50),
            gems = gems + v_new_level,
            max_flowers = 6 + (v_new_level * 2),
            updated_at = NOW()
        WHERE id = p_garden_id;
        
        -- Update for next iteration
        v_garden.level := v_new_level;
        v_garden.experience := v_garden.experience - v_required_exp;
    END LOOP;
    
    RETURN v_level_ups;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to spawn garden visitor
CREATE OR REPLACE FUNCTION try_spawn_visitor(p_garden_id UUID) RETURNS UUID AS $$
DECLARE
    v_garden RECORD;
    v_visitor RECORD;
    v_visitor_id UUID;
    v_instance_id UUID;
    v_required_flowers INTEGER;
    v_current_flowers INTEGER;
BEGIN
    -- Get garden details
    SELECT * INTO v_garden FROM gardens WHERE id = p_garden_id;
    
    IF NOT FOUND THEN
        RETURN NULL;
    END IF;
    
    -- Check if there's already an active visitor
    IF EXISTS(
        SELECT 1 FROM garden_visitor_instances 
        WHERE garden_id = p_garden_id AND will_leave_at > NOW()
    ) THEN
        RETURN NULL;
    END IF;
    
    -- Get current flower count
    SELECT COUNT(*) INTO v_current_flowers FROM flowers WHERE garden_id = p_garden_id;
    
    -- Try to spawn a visitor based on garden level and random chance
    SELECT * INTO v_visitor
    FROM garden_visitors
    WHERE min_garden_level <= v_garden.level
    AND required_flowers <= v_current_flowers
    AND seasonal_availability ? LOWER(v_garden.season)
    AND random() < visit_chance
    ORDER BY random()
    LIMIT 1;
    
    IF NOT FOUND THEN
        RETURN NULL;
    END IF;
    
    -- Spawn the visitor
    INSERT INTO garden_visitor_instances (
        garden_id,
        visitor_id,
        will_leave_at,
        x_position,
        y_position
    ) VALUES (
        p_garden_id,
        v_visitor.id,
        NOW() + (v_visitor.stay_duration_minutes || ' minutes')::INTERVAL,
        random() * 100, -- Random position
        random() * 100
    ) RETURNING id INTO v_instance_id;
    
    -- Track analytics
    INSERT INTO garden_analytics (garden_id, date, visitors_received)
    VALUES (p_garden_id, CURRENT_DATE, 1)
    ON CONFLICT (garden_id, date)
    DO UPDATE SET visitors_received = garden_analytics.visitors_received + 1;
    
    RETURN v_instance_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to interact with garden visitor
CREATE OR REPLACE FUNCTION interact_with_visitor(
    p_instance_id UUID,
    p_user_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_instance RECORD;
    v_visitor RECORD;
    v_garden_id UUID;
    v_reward JSONB := '{}';
BEGIN
    -- Get visitor instance details
    SELECT * INTO v_instance
    FROM garden_visitor_instances vi
    WHERE vi.id = p_instance_id
    AND vi.will_leave_at > NOW()
    AND NOT vi.has_given_reward;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Visitor not found or has already left/been claimed';
    END IF;
    
    -- Get visitor details
    SELECT * INTO v_visitor FROM garden_visitors WHERE id = v_instance.visitor_id;
    
    -- Check garden ownership
    SELECT g.id INTO v_garden_id
    FROM gardens g
    WHERE g.id = v_instance.garden_id AND g.user_id = p_user_id;
    
    IF v_garden_id IS NULL THEN
        RAISE EXCEPTION 'Access denied to this garden';
    END IF;
    
    -- Give rewards
    IF v_visitor.reward_type = 'coins' THEN
        UPDATE gardens SET coins = coins + v_visitor.reward_amount WHERE id = v_garden_id;
        v_reward := jsonb_build_object('type', 'coins', 'amount', v_visitor.reward_amount);
    ELSIF v_visitor.reward_type = 'gems' THEN
        UPDATE gardens SET gems = gems + v_visitor.reward_amount WHERE id = v_garden_id;
        v_reward := jsonb_build_object('type', 'gems', 'amount', v_visitor.reward_amount);
    ELSIF v_visitor.reward_type = 'experience' THEN
        UPDATE gardens SET experience = experience + v_visitor.reward_amount WHERE id = v_garden_id;
        v_reward := jsonb_build_object('type', 'experience', 'amount', v_visitor.reward_amount);
        PERFORM check_garden_level_up(v_garden_id);
    ELSIF v_visitor.reward_type = 'items' THEN
        -- Give random items from reward_items array
        -- This would need more complex logic based on the specific items
        v_reward := jsonb_build_object('type', 'items', 'items', v_visitor.reward_items);
    END IF;
    
    -- Mark as claimed
    UPDATE garden_visitor_instances
    SET 
        has_given_reward = true,
        reward_claimed_at = NOW(),
        times_interacted = times_interacted + 1
    WHERE id = p_instance_id;
    
    RETURN v_reward;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to purchase items from garden shop
CREATE OR REPLACE FUNCTION purchase_garden_item(
    p_garden_id UUID,
    p_shop_item_id UUID,
    p_quantity INTEGER,
    p_user_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
    v_garden RECORD;
    v_item RECORD;
    v_total_coin_cost INTEGER;
    v_total_gem_cost INTEGER;
BEGIN
    -- Get garden and verify ownership
    SELECT * INTO v_garden FROM gardens WHERE id = p_garden_id AND user_id = p_user_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Garden not found or access denied';
    END IF;
    
    -- Get shop item details
    SELECT * INTO v_item FROM garden_shop_items WHERE id = p_shop_item_id AND is_available = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Shop item not found or not available';
    END IF;
    
    -- Check level requirement
    IF v_garden.level < v_item.min_level_required THEN
        RAISE EXCEPTION 'Garden level % required, current level is %', v_item.min_level_required, v_garden.level;
    END IF;
    
    -- Check seasonal availability
    IF NOT (v_item.seasonal_availability ? LOWER(v_garden.season)) THEN
        RAISE EXCEPTION 'Item not available in current season';
    END IF;
    
    -- Calculate costs
    v_total_coin_cost := v_item.price_coins * p_quantity;
    v_total_gem_cost := v_item.price_gems * p_quantity;
    
    -- Check if user can afford it
    IF v_garden.coins < v_total_coin_cost OR v_garden.gems < v_total_gem_cost THEN
        RAISE EXCEPTION 'Insufficient funds';
    END IF;
    
    -- Check stock if limited
    IF v_item.stock_quantity IS NOT NULL AND v_item.stock_quantity < p_quantity THEN
        RAISE EXCEPTION 'Insufficient stock';
    END IF;
    
    -- Process purchase
    UPDATE gardens
    SET 
        coins = coins - v_total_coin_cost,
        gems = gems - v_total_gem_cost,
        updated_at = NOW()
    WHERE id = p_garden_id;
    
    -- Update stock if limited
    IF v_item.stock_quantity IS NOT NULL THEN
        UPDATE garden_shop_items
        SET stock_quantity = stock_quantity - p_quantity
        WHERE id = p_shop_item_id;
    END IF;
    
    -- Add to inventory
    INSERT INTO garden_inventory (garden_id, item_type, item_name, quantity)
    VALUES (p_garden_id, v_item.category, v_item.item_name, p_quantity)
    ON CONFLICT (garden_id, item_type, item_name)
    DO UPDATE SET quantity = garden_inventory.quantity + p_quantity;
    
    -- Record purchase
    INSERT INTO garden_purchases (
        garden_id,
        shop_item_id,
        item_name,
        quantity,
        price_paid_coins,
        price_paid_gems,
        user_level_at_purchase,
        season_at_purchase
    ) VALUES (
        p_garden_id,
        p_shop_item_id,
        v_item.item_name,
        p_quantity,
        v_total_coin_cost,
        v_total_gem_cost,
        v_garden.level,
        v_garden.season
    );
    
    -- Update shop statistics
    UPDATE garden_shop_items
    SET total_sold = total_sold + p_quantity
    WHERE id = p_shop_item_id;
    
    -- Track analytics
    INSERT INTO garden_analytics (garden_id, date, coins_spent, gems_spent)
    VALUES (p_garden_id, CURRENT_DATE, v_total_coin_cost, v_total_gem_cost)
    ON CONFLICT (garden_id, date)
    DO UPDATE SET 
        coins_spent = garden_analytics.coins_spent + v_total_coin_cost,
        gems_spent = garden_analytics.gems_spent + v_total_gem_cost;
    
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get garden status and summary
CREATE OR REPLACE FUNCTION get_garden_status(p_garden_id UUID, p_user_id UUID)
RETURNS TABLE (
    garden_info JSONB,
    flower_summary JSONB,
    inventory_summary JSONB,
    visitor_info JSONB,
    achievement_progress JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        -- Garden basic info
        to_jsonb(g.*) as garden_info,
        
        -- Flower summary
        (SELECT jsonb_build_object(
            'total_flowers', COUNT(*),
            'by_stage', jsonb_object_agg(growth_stage, stage_count),
            'needing_water', SUM(CASE WHEN last_watered_at IS NULL OR NOW() - last_watered_at > INTERVAL '2 hours' THEN 1 ELSE 0 END),
            'needing_fertilizer', SUM(CASE WHEN last_fertilized_at IS NULL OR NOW() - last_fertilized_at > INTERVAL '6 hours' THEN 1 ELSE 0 END),
            'avg_health', ROUND(AVG(health), 1),
            'avg_happiness', ROUND(AVG(happiness), 1)
        )
        FROM (
            SELECT 
                growth_stage,
                COUNT(*) as stage_count,
                health,
                happiness,
                last_watered_at,
                last_fertilized_at
            FROM flowers 
            WHERE garden_id = p_garden_id
            GROUP BY growth_stage, health, happiness, last_watered_at, last_fertilized_at
        ) flower_stats) as flower_summary,
        
        -- Inventory summary
        (SELECT jsonb_object_agg(
            item_type,
            jsonb_object_agg(item_name, quantity)
        )
        FROM garden_inventory 
        WHERE garden_id = p_garden_id) as inventory_summary,
        
        -- Active visitors
        (SELECT jsonb_agg(
            jsonb_build_object(
                'name', gv.name,
                'type', gv.visitor_type,
                'reward_type', gv.reward_type,
                'reward_amount', gv.reward_amount,
                'will_leave_at', gvi.will_leave_at,
                'has_given_reward', gvi.has_given_reward
            )
        )
        FROM garden_visitor_instances gvi
        JOIN garden_visitors gv ON gvi.visitor_id = gv.id
        WHERE gvi.garden_id = p_garden_id AND gvi.will_leave_at > NOW()) as visitor_info,
        
        -- Achievement progress
        (SELECT jsonb_agg(
            jsonb_build_object(
                'name', achievement_name,
                'description', description,
                'current_value', current_value,
                'target_value', target_value,
                'is_completed', is_completed,
                'reward_coins', reward_coins,
                'reward_gems', reward_gems
            )
        )
        FROM garden_achievements
        WHERE garden_id = p_garden_id AND NOT is_completed) as achievement_progress
        
    FROM gardens g
    WHERE g.id = p_garden_id AND g.user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
