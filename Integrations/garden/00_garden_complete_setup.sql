-- =====================================================
-- CRYSTAL SOCIAL - COMPLETE GARDEN SYSTEM SETUP
-- =====================================================
-- This file combines all garden SQL files in correct order
-- to prevent deadlock and dependency issues
-- =====================================================

-- First, ensure all extensions are available
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- TABLES CREATION (from 01_garden_tables.sql)
-- =====================================================

-- Drop existing tables if they exist to prevent column conflicts
DROP TABLE IF EXISTS garden_shares CASCADE;
DROP TABLE IF EXISTS garden_analytics CASCADE;
DROP TABLE IF EXISTS garden_quest_progress CASCADE;
DROP TABLE IF EXISTS garden_daily_quests CASCADE;
DROP TABLE IF EXISTS garden_purchases CASCADE;
DROP TABLE IF EXISTS garden_achievements CASCADE;
DROP TABLE IF EXISTS garden_visitor_instances CASCADE;
DROP TABLE IF EXISTS garden_weather_events CASCADE;
DROP TABLE IF EXISTS garden_inventory CASCADE;
DROP TABLE IF EXISTS flowers CASCADE;
DROP TABLE IF EXISTS garden_shop_items CASCADE;
DROP TABLE IF EXISTS garden_visitors CASCADE;
DROP TABLE IF EXISTS flower_species CASCADE;
DROP TABLE IF EXISTS gardens CASCADE;

-- Main gardens table
CREATE TABLE gardens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Garden properties
    name VARCHAR(100) NOT NULL DEFAULT 'My Garden',
    size VARCHAR(20) DEFAULT 'small' CHECK (size IN ('small', 'medium', 'large')),
    theme VARCHAR(50) DEFAULT 'classic',
    level INTEGER DEFAULT 1,
    experience INTEGER DEFAULT 0,
    
    -- Resources
    coins INTEGER DEFAULT 100,
    gems INTEGER DEFAULT 10,
    water_level INTEGER DEFAULT 100,
    happiness_level INTEGER DEFAULT 50,
    
    -- Status
    last_watered TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id)  -- One garden per user for now
);

-- Flower species (reference data)
CREATE TABLE flower_species (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    
    -- Growing requirements
    water_frequency_hours INTEGER DEFAULT 8,
    growth_time_hours INTEGER DEFAULT 24,
    min_happiness INTEGER DEFAULT 20,
    
    -- Appearance
    sprite_path VARCHAR(255),
    color_variants JSONB DEFAULT '[]'::jsonb,
    rarity VARCHAR(20) DEFAULT 'common' CHECK (rarity IN ('common', 'uncommon', 'rare', 'epic', 'legendary')),
    
    -- Rewards when fully grown
    coin_reward INTEGER DEFAULT 10,
    experience_reward INTEGER DEFAULT 5,
    happiness_boost INTEGER DEFAULT 10,
    
    -- Growing stages
    total_stages INTEGER DEFAULT 4,
    stage_sprites JSONB DEFAULT '[]'::jsonb,
    
    -- Special properties
    special_effects JSONB DEFAULT '{}'::jsonb,
    seasonal_availability JSONB DEFAULT '[]'::jsonb,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Individual flowers in gardens
CREATE TABLE flowers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    garden_id UUID REFERENCES gardens(id) ON DELETE CASCADE,
    species_id UUID REFERENCES flower_species(id),
    
    -- Position in garden
    position_x INTEGER NOT NULL,
    position_y INTEGER NOT NULL,
    
    -- Growth status
    current_stage INTEGER DEFAULT 0,
    health INTEGER DEFAULT 100,
    last_watered TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    planted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Special states
    is_withered BOOLEAN DEFAULT false,
    is_diseased BOOLEAN DEFAULT false,
    has_pests BOOLEAN DEFAULT false,
    
    -- Growth tracking
    water_count INTEGER DEFAULT 0,
    fertilizer_count INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(garden_id, position_x, position_y)
);

-- Garden inventory for items/tools
CREATE TABLE garden_inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    garden_id UUID REFERENCES gardens(id) ON DELETE CASCADE,
    
    item_type VARCHAR(50) NOT NULL,
    item_name VARCHAR(100) NOT NULL,
    quantity INTEGER DEFAULT 1,
    
    -- Item properties
    rarity VARCHAR(20) DEFAULT 'common',
    durability INTEGER DEFAULT 100,
    effects JSONB DEFAULT '{}'::jsonb,
    
    acquired_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_used TIMESTAMP WITH TIME ZONE,
    
    UNIQUE(garden_id, item_type, item_name)
);

-- Garden weather events
CREATE TABLE garden_weather_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    garden_id UUID REFERENCES gardens(id) ON DELETE CASCADE,
    weather_type VARCHAR(50) NOT NULL,
    
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    duration_minutes INTEGER DEFAULT 60,
    ends_at TIMESTAMP WITH TIME ZONE,
    
    -- Weather effects
    water_bonus DECIMAL(3,2) DEFAULT 1.0,
    growth_bonus DECIMAL(3,2) DEFAULT 1.0,
    happiness_bonus INTEGER DEFAULT 0,
    pest_chance_modifier DECIMAL(3,2) DEFAULT 1.0,
    
    -- Special effects
    auto_water_flowers BOOLEAN DEFAULT false,
    prevents_wilting BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Garden achievements
CREATE TABLE garden_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    garden_id UUID REFERENCES gardens(id) ON DELETE CASCADE,
    
    achievement_type VARCHAR(100) NOT NULL,
    achievement_name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Achievement criteria
    target_value INTEGER,
    current_value INTEGER DEFAULT 0,
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Rewards
    reward_coins INTEGER DEFAULT 0,
    reward_gems INTEGER DEFAULT 0,
    reward_experience INTEGER DEFAULT 0,
    reward_items JSONB DEFAULT '[]'::jsonb,
    
    -- Achievement properties
    rarity VARCHAR(20) DEFAULT 'common',
    icon_path VARCHAR(255),
    is_hidden BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Garden visitor types (reference data)
CREATE TABLE garden_visitors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    
    -- Appearance
    sprite_path VARCHAR(255),
    animation_frames JSONB DEFAULT '[]'::jsonb,
    
    -- Behavior
    visit_frequency_hours INTEGER DEFAULT 24,
    stay_duration_minutes INTEGER DEFAULT 30,
    rarity VARCHAR(20) DEFAULT 'common',
    
    -- Interaction rewards
    coin_reward INTEGER DEFAULT 5,
    experience_reward INTEGER DEFAULT 3,
    item_rewards JSONB DEFAULT '[]'::jsonb,
    
    -- Requirements to appear
    min_garden_level INTEGER DEFAULT 1,
    required_flowers JSONB DEFAULT '[]'::jsonb,
    seasonal_availability JSONB DEFAULT '[]'::jsonb,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Garden visitor instances (when visitors appear)
CREATE TABLE garden_visitor_instances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    garden_id UUID REFERENCES gardens(id) ON DELETE CASCADE,
    visitor_id UUID REFERENCES garden_visitors(id),
    
    -- Visit details
    appeared_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    will_leave_at TIMESTAMP WITH TIME ZONE,
    has_been_interacted BOOLEAN DEFAULT false,
    interaction_count INTEGER DEFAULT 0,
    
    -- Dynamic properties
    mood VARCHAR(20) DEFAULT 'neutral',
    special_message TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Garden shop items
CREATE TABLE garden_shop_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    item_type VARCHAR(50) NOT NULL,
    item_name VARCHAR(100) NOT NULL,
    description TEXT,
    
    -- Pricing
    cost_coins INTEGER DEFAULT 0,
    cost_gems INTEGER DEFAULT 0,
    
    -- Availability
    is_available BOOLEAN DEFAULT true,
    stock_quantity INTEGER DEFAULT -1, -- -1 means unlimited
    
    -- Item properties
    rarity VARCHAR(20) DEFAULT 'common',
    category VARCHAR(50) DEFAULT 'tool',
    effects JSONB DEFAULT '{}'::jsonb,
    icon_path VARCHAR(255),
    
    -- Requirements
    min_level_required INTEGER DEFAULT 1,
    prerequisite_achievements JSONB DEFAULT '[]'::jsonb,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(item_type, item_name)
);

-- Garden purchase history
CREATE TABLE garden_purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    garden_id UUID REFERENCES gardens(id) ON DELETE CASCADE,
    shop_item_id UUID REFERENCES garden_shop_items(id),
    
    quantity INTEGER DEFAULT 1,
    total_cost_coins INTEGER DEFAULT 0,
    total_cost_gems INTEGER DEFAULT 0,
    
    purchased_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Daily quests for gardens
CREATE TABLE garden_daily_quests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    garden_id UUID REFERENCES gardens(id) ON DELETE CASCADE,
    
    quest_type VARCHAR(100) NOT NULL,
    quest_name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Quest parameters
    target_count INTEGER NOT NULL,
    current_progress INTEGER DEFAULT 0,
    
    -- Quest timing
    quest_date DATE DEFAULT CURRENT_DATE,
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_DATE + INTERVAL '1 day'),
    
    -- Rewards
    reward_coins INTEGER DEFAULT 0,
    reward_gems INTEGER DEFAULT 0,
    reward_experience INTEGER DEFAULT 5,
    reward_items JSONB DEFAULT '[]'::jsonb,
    
    -- Availability
    difficulty VARCHAR(20) DEFAULT 'easy' CHECK (difficulty IN ('easy', 'medium', 'hard')),
    min_level_required INTEGER DEFAULT 1,
    
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User progress on daily quests
CREATE TABLE garden_quest_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    garden_id UUID REFERENCES gardens(id) ON DELETE CASCADE,
    quest_id UUID REFERENCES garden_daily_quests(id) ON DELETE CASCADE,
    
    -- Progress tracking
    current_progress INTEGER DEFAULT 0,
    target_progress INTEGER NOT NULL,
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Rewards claimed
    rewards_claimed BOOLEAN DEFAULT false,
    claimed_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(garden_id, quest_id)
);

-- Garden analytics and statistics
CREATE TABLE garden_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    garden_id UUID REFERENCES gardens(id) ON DELETE CASCADE,
    
    -- Time period
    period_type VARCHAR(20) NOT NULL CHECK (period_type IN ('daily', 'weekly', 'monthly')),
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    
    -- Activity metrics
    flowers_planted INTEGER DEFAULT 0,
    flowers_watered INTEGER DEFAULT 0,
    flowers_harvested INTEGER DEFAULT 0,
    visitors_interacted INTEGER DEFAULT 0,
    quests_completed INTEGER DEFAULT 0,
    
    -- Resource metrics
    coins_earned INTEGER DEFAULT 0,
    coins_spent INTEGER DEFAULT 0,
    gems_earned INTEGER DEFAULT 0,
    gems_spent INTEGER DEFAULT 0,
    experience_gained INTEGER DEFAULT 0,
    
    -- Engagement metrics
    time_spent_minutes INTEGER DEFAULT 0,
    login_count INTEGER DEFAULT 0,
    last_activity TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(garden_id, period_type, period_start)
);

-- Garden sharing system
CREATE TABLE garden_shares (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    garden_id UUID REFERENCES gardens(id) ON DELETE CASCADE,
    
    -- Share details
    share_type VARCHAR(50) NOT NULL DEFAULT 'snapshot',
    title VARCHAR(255),
    description TEXT,
    
    -- Content
    image_url TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Engagement
    views INTEGER DEFAULT 0,
    likes INTEGER DEFAULT 0,
    
    -- Privacy
    allowed_viewers JSONB DEFAULT '[]'::jsonb, -- Array of user IDs
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Gardens indexes
CREATE INDEX IF NOT EXISTS idx_gardens_user_id ON gardens(user_id);
CREATE INDEX IF NOT EXISTS idx_gardens_level ON gardens(level);

-- Flowers indexes
CREATE INDEX IF NOT EXISTS idx_flowers_garden_id ON flowers(garden_id);
CREATE INDEX IF NOT EXISTS idx_flowers_species_id ON flowers(species_id);
CREATE INDEX IF NOT EXISTS idx_flowers_position ON flowers(garden_id, position_x, position_y);
CREATE INDEX IF NOT EXISTS idx_flowers_stage ON flowers(current_stage);

-- Garden inventory indexes
CREATE INDEX IF NOT EXISTS idx_garden_inventory_garden_id ON garden_inventory(garden_id);
CREATE INDEX IF NOT EXISTS idx_garden_inventory_type ON garden_inventory(item_type);

-- Weather events indexes
CREATE INDEX IF NOT EXISTS idx_garden_weather_garden_id ON garden_weather_events(garden_id);
CREATE INDEX IF NOT EXISTS idx_garden_weather_time ON garden_weather_events(garden_id, ends_at);

-- Visitor instances indexes
CREATE INDEX IF NOT EXISTS idx_garden_visitors_garden_id ON garden_visitor_instances(garden_id);
CREATE INDEX IF NOT EXISTS idx_garden_visitors_active ON garden_visitor_instances(garden_id, will_leave_at);

-- Shop items indexes
CREATE INDEX IF NOT EXISTS idx_garden_shop_available ON garden_shop_items(is_available, category);
CREATE INDEX IF NOT EXISTS idx_garden_shop_cost ON garden_shop_items(cost_coins, cost_gems);

-- Purchases indexes
CREATE INDEX IF NOT EXISTS idx_garden_purchases_garden_id ON garden_purchases(garden_id);
CREATE INDEX IF NOT EXISTS idx_garden_purchases_date ON garden_purchases(purchased_at DESC);

-- Quests indexes
CREATE INDEX IF NOT EXISTS idx_garden_quests_garden_id ON garden_daily_quests(garden_id);
CREATE INDEX IF NOT EXISTS idx_garden_quests_active ON garden_daily_quests(garden_id, quest_date) WHERE is_active = true;

-- Analytics indexes
CREATE INDEX IF NOT EXISTS idx_garden_analytics_garden_id ON garden_analytics(garden_id);
CREATE INDEX IF NOT EXISTS idx_garden_analytics_period ON garden_analytics(period_type, period_start DESC);

-- Shares indexes
CREATE INDEX IF NOT EXISTS idx_garden_shares_garden_id ON garden_shares(garden_id);
CREATE INDEX IF NOT EXISTS idx_garden_shares_created ON garden_shares(created_at DESC);

-- =====================================================
-- FUNCTIONS (from 02_garden_functions.sql)
-- =====================================================

-- Drop existing functions to prevent conflicts
DROP FUNCTION IF EXISTS create_garden CASCADE;
DROP FUNCTION IF EXISTS plant_flower CASCADE;
DROP FUNCTION IF EXISTS water_flower CASCADE;
DROP FUNCTION IF EXISTS fertilize_flower CASCADE;
DROP FUNCTION IF EXISTS try_grow_flower CASCADE;
DROP FUNCTION IF EXISTS try_spawn_visitor CASCADE;
DROP FUNCTION IF EXISTS interact_with_visitor CASCADE;
DROP FUNCTION IF EXISTS purchase_garden_item CASCADE;
DROP FUNCTION IF EXISTS get_garden_status CASCADE;
DROP FUNCTION IF EXISTS check_garden_level_up CASCADE;
DROP FUNCTION IF EXISTS is_garden_owner CASCADE;

-- Function to create a new garden
CREATE OR REPLACE FUNCTION create_garden(
    p_user_id UUID,
    p_name VARCHAR(100) DEFAULT 'My Garden',
    p_theme VARCHAR(50) DEFAULT 'classic'
)
RETURNS UUID AS $$
DECLARE
    new_garden_id UUID;
BEGIN
    INSERT INTO gardens (user_id, name, theme)
    VALUES (p_user_id, p_name, p_theme)
    RETURNING id INTO new_garden_id;
    
    -- Add starter items to inventory
    INSERT INTO garden_inventory (garden_id, item_type, item_name, quantity)
    VALUES 
        (new_garden_id, 'tool', 'Basic Watering Can', 1),
        (new_garden_id, 'seed', 'Sunflower Seed', 3),
        (new_garden_id, 'fertilizer', 'Basic Fertilizer', 2);
    
    RETURN new_garden_id;
END;
$$ LANGUAGE plpgsql;

-- Function to plant a flower
CREATE OR REPLACE FUNCTION plant_flower(
    p_garden_id UUID,
    p_species_id UUID,
    p_position_x INTEGER,
    p_position_y INTEGER
)
RETURNS UUID AS $$
DECLARE
    new_flower_id UUID;
    garden_record RECORD;
BEGIN
    -- Check if position is occupied
    IF EXISTS (
        SELECT 1 FROM flowers 
        WHERE garden_id = p_garden_id 
        AND position_x = p_position_x 
        AND position_y = p_position_y
    ) THEN
        RAISE EXCEPTION 'Position already occupied';
    END IF;
    
    -- Get garden info
    SELECT * INTO garden_record FROM gardens WHERE id = p_garden_id;
    
    -- Check if user has enough resources (simplified)
    IF garden_record.coins < 10 THEN
        RAISE EXCEPTION 'Not enough coins to plant flower';
    END IF;
    
    -- Plant the flower
    INSERT INTO flowers (garden_id, species_id, position_x, position_y)
    VALUES (p_garden_id, p_species_id, p_position_x, p_position_y)
    RETURNING id INTO new_flower_id;
    
    -- Deduct costs
    UPDATE gardens SET coins = coins - 10 WHERE id = p_garden_id;
    
    RETURN new_flower_id;
END;
$$ LANGUAGE plpgsql;

-- Function to water a flower
CREATE OR REPLACE FUNCTION water_flower(p_flower_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    flower_record RECORD;
    garden_record RECORD;
BEGIN
    -- Get flower and garden info
    SELECT f.*, g.water_level INTO flower_record
    FROM flowers f
    JOIN gardens g ON f.garden_id = g.id
    WHERE f.id = p_flower_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Flower not found';
    END IF;
    
    -- Check if garden has water
    IF flower_record.water_level < 10 THEN
        RAISE EXCEPTION 'Not enough water in garden';
    END IF;
    
    -- Water the flower
    UPDATE flowers SET 
        last_watered = NOW(),
        water_count = water_count + 1,
        health = LEAST(health + 10, 100)
    WHERE id = p_flower_id;
    
    -- Reduce garden water level
    UPDATE gardens SET water_level = water_level - 10 
    WHERE id = flower_record.garden_id;
    
    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Function to fertilize a flower
CREATE OR REPLACE FUNCTION fertilize_flower(p_flower_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    flower_record RECORD;
    has_fertilizer BOOLEAN;
BEGIN
    -- Get flower info
    SELECT f.*, g.id as garden_id INTO flower_record
    FROM flowers f
    JOIN gardens g ON f.garden_id = g.id
    WHERE f.id = p_flower_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Flower not found';
    END IF;
    
    -- Check if garden has fertilizer
    SELECT EXISTS(
        SELECT 1 FROM garden_inventory 
        WHERE garden_id = flower_record.garden_id 
        AND item_type = 'fertilizer' 
        AND quantity > 0
    ) INTO has_fertilizer;
    
    IF NOT has_fertilizer THEN
        RAISE EXCEPTION 'No fertilizer available';
    END IF;
    
    -- Apply fertilizer
    UPDATE flowers SET 
        fertilizer_count = fertilizer_count + 1,
        health = LEAST(health + 20, 100)
    WHERE id = p_flower_id;
    
    -- Consume fertilizer
    UPDATE garden_inventory SET quantity = quantity - 1
    WHERE garden_id = flower_record.garden_id 
    AND item_type = 'fertilizer' 
    AND quantity > 0;
    
    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Function to try growing a flower to next stage
CREATE OR REPLACE FUNCTION try_grow_flower(p_flower_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    flower_record RECORD;
    species_record RECORD;
    hours_since_watered INTEGER;
    can_grow BOOLEAN := false;
BEGIN
    -- Get flower info
    SELECT * INTO flower_record FROM flowers WHERE id = p_flower_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Flower not found';
    END IF;
    
    -- Get species info
    SELECT * INTO species_record FROM flower_species WHERE id = flower_record.species_id;
    
    -- Check if flower can grow
    hours_since_watered := EXTRACT(EPOCH FROM (NOW() - flower_record.last_watered)) / 3600;
    
    IF flower_record.current_stage < species_record.total_stages 
       AND hours_since_watered <= species_record.water_frequency_hours 
       AND flower_record.health > 50 THEN
        can_grow := true;
    END IF;
    
    IF can_grow THEN
        UPDATE flowers SET 
            current_stage = current_stage + 1,
            updated_at = NOW()
        WHERE id = p_flower_id;
        
        -- If fully grown, give rewards
        IF flower_record.current_stage + 1 >= species_record.total_stages THEN
            UPDATE gardens SET 
                coins = coins + species_record.coin_reward,
                experience = experience + species_record.experience_reward,
                happiness_level = LEAST(happiness_level + species_record.happiness_boost, 100)
            WHERE id = flower_record.garden_id;
        END IF;
    END IF;
    
    RETURN can_grow;
END;
$$ LANGUAGE plpgsql;

-- Function to spawn garden visitors
CREATE OR REPLACE FUNCTION try_spawn_visitor(p_garden_id UUID)
RETURNS UUID AS $$
DECLARE
    garden_record RECORD;
    visitor_record RECORD;
    new_instance_id UUID;
    spawn_chance DECIMAL;
BEGIN
    -- Get garden info
    SELECT * INTO garden_record FROM gardens WHERE id = p_garden_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Garden not found';
    END IF;
    
    -- Check if there's already an active visitor
    IF EXISTS (
        SELECT 1 FROM garden_visitor_instances 
        WHERE garden_id = p_garden_id 
        AND will_leave_at > NOW()
    ) THEN
        RETURN NULL; -- Already has a visitor
    END IF;
    
    -- Random chance to spawn visitor (10% base chance)
    spawn_chance := random();
    IF spawn_chance > 0.1 THEN
        RETURN NULL;
    END IF;
    
    -- Find a suitable visitor
    SELECT * INTO visitor_record
    FROM garden_visitors 
    WHERE min_garden_level <= garden_record.level
    ORDER BY random()
    LIMIT 1;
    
    IF FOUND THEN
        INSERT INTO garden_visitor_instances (
            garden_id, visitor_id, will_leave_at
        ) VALUES (
            p_garden_id, visitor_record.id, 
            NOW() + (visitor_record.stay_duration_minutes || ' minutes')::INTERVAL
        ) RETURNING id INTO new_instance_id;
        
        RETURN new_instance_id;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Function to interact with visitor
CREATE OR REPLACE FUNCTION interact_with_visitor(p_instance_id UUID)
RETURNS JSONB AS $$
DECLARE
    instance_record RECORD;
    visitor_record RECORD;
    garden_record RECORD;
    rewards JSONB;
BEGIN
    -- Get visitor instance info
    SELECT * INTO instance_record FROM garden_visitor_instances WHERE id = p_instance_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Visitor instance not found';
    END IF;
    
    -- Check if visitor is still present
    IF instance_record.will_leave_at <= NOW() THEN
        RAISE EXCEPTION 'Visitor has already left';
    END IF;
    
    -- Get visitor and garden info
    SELECT * INTO visitor_record FROM garden_visitors WHERE id = instance_record.visitor_id;
    SELECT * INTO garden_record FROM gardens WHERE id = instance_record.garden_id;
    
    -- Calculate rewards
    rewards := jsonb_build_object(
        'coins', visitor_record.coin_reward,
        'experience', visitor_record.experience_reward,
        'items', visitor_record.item_rewards
    );
    
    -- Give rewards to garden
    UPDATE gardens SET 
        coins = coins + visitor_record.coin_reward,
        experience = experience + visitor_record.experience_reward
    WHERE id = instance_record.garden_id;
    
    -- Mark interaction
    UPDATE garden_visitor_instances SET 
        has_been_interacted = true,
        interaction_count = interaction_count + 1
    WHERE id = p_instance_id;
    
    RETURN rewards;
END;
$$ LANGUAGE plpgsql;

-- Function to purchase garden item
CREATE OR REPLACE FUNCTION purchase_garden_item(
    p_garden_id UUID,
    p_shop_item_id UUID,
    p_quantity INTEGER DEFAULT 1
)
RETURNS BOOLEAN AS $$
DECLARE
    garden_record RECORD;
    shop_item_record RECORD;
    total_cost_coins INTEGER;
    total_cost_gems INTEGER;
BEGIN
    -- Get garden and shop item info
    SELECT * INTO garden_record FROM gardens WHERE id = p_garden_id;
    SELECT * INTO shop_item_record FROM garden_shop_items WHERE id = p_shop_item_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Garden or shop item not found';
    END IF;
    
    -- Check if item is available
    IF NOT shop_item_record.is_available THEN
        RAISE EXCEPTION 'Item not available for purchase';
    END IF;
    
    -- Calculate total cost
    total_cost_coins := shop_item_record.cost_coins * p_quantity;
    total_cost_gems := shop_item_record.cost_gems * p_quantity;
    
    -- Check if garden has enough resources
    IF garden_record.coins < total_cost_coins OR garden_record.gems < total_cost_gems THEN
        RAISE EXCEPTION 'Insufficient resources';
    END IF;
    
    -- Process purchase
    UPDATE gardens SET 
        coins = coins - total_cost_coins,
        gems = gems - total_cost_gems
    WHERE id = p_garden_id;
    
    -- Add item to inventory
    INSERT INTO garden_inventory (garden_id, item_type, item_name, quantity)
    VALUES (p_garden_id, shop_item_record.item_type, shop_item_record.item_name, p_quantity)
    ON CONFLICT (garden_id, item_type, item_name)
    DO UPDATE SET quantity = garden_inventory.quantity + p_quantity;
    
    -- Record purchase
    INSERT INTO garden_purchases (garden_id, shop_item_id, quantity, total_cost_coins, total_cost_gems)
    VALUES (p_garden_id, p_shop_item_id, p_quantity, total_cost_coins, total_cost_gems);
    
    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Function to get garden status
CREATE OR REPLACE FUNCTION get_garden_status(p_garden_id UUID)
RETURNS JSONB AS $$
DECLARE
    garden_record RECORD;
    flower_count INTEGER;
    active_visitors INTEGER;
    result JSONB;
BEGIN
    -- Get garden info
    SELECT * INTO garden_record FROM gardens WHERE id = p_garden_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Garden not found';
    END IF;
    
    -- Count flowers
    SELECT COUNT(*) INTO flower_count FROM flowers WHERE garden_id = p_garden_id;
    
    -- Count active visitors
    SELECT COUNT(*) INTO active_visitors 
    FROM garden_visitor_instances 
    WHERE garden_id = p_garden_id AND will_leave_at > NOW();
    
    -- Build result
    result := jsonb_build_object(
        'garden', row_to_json(garden_record),
        'flower_count', flower_count,
        'active_visitors', active_visitors,
        'needs_water', EXISTS(
            SELECT 1 FROM flowers 
            WHERE garden_id = p_garden_id 
            AND last_watered < NOW() - INTERVAL '8 hours'
        )
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to check garden level up
CREATE OR REPLACE FUNCTION check_garden_level_up(p_garden_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    garden_record RECORD;
    required_exp INTEGER;
    leveled_up BOOLEAN := false;
BEGIN
    SELECT * INTO garden_record FROM gardens WHERE id = p_garden_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Garden not found';
    END IF;
    
    -- Calculate required experience for next level (simple formula)
    required_exp := garden_record.level * 100;
    
    -- Check if garden can level up
    WHILE garden_record.experience >= required_exp LOOP
        UPDATE gardens SET 
            level = level + 1,
            experience = experience - required_exp,
            gems = gems + 5  -- Level up bonus
        WHERE id = p_garden_id;
        
        leveled_up := true;
        
        -- Recalculate for next level
        garden_record.level := garden_record.level + 1;
        garden_record.experience := garden_record.experience - required_exp;
        required_exp := garden_record.level * 100;
    END LOOP;
    
    RETURN leveled_up;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TRIGGERS (from 03_garden_triggers.sql) 
-- =====================================================

-- Drop existing triggers and functions to prevent conflicts
DROP TRIGGER IF EXISTS trigger_update_garden_timestamp ON gardens;
DROP TRIGGER IF EXISTS trigger_garden_level_check ON gardens;
DROP TRIGGER IF EXISTS trigger_weather_effects ON garden_weather_events;
DROP TRIGGER IF EXISTS trigger_weather_cleanup ON garden_weather_events;
DROP TRIGGER IF EXISTS trigger_flower_quest_check ON flowers;
DROP TRIGGER IF EXISTS trigger_visitor_quest_check ON garden_visitor_instances;

DROP FUNCTION IF EXISTS update_garden_timestamp CASCADE;
DROP FUNCTION IF EXISTS trigger_check_level_up CASCADE;
DROP FUNCTION IF EXISTS apply_weather_effects CASCADE;
DROP FUNCTION IF EXISTS cleanup_expired_weather CASCADE;
DROP FUNCTION IF EXISTS check_quest_completion CASCADE;

-- Trigger to update garden updated_at timestamp
CREATE OR REPLACE FUNCTION update_garden_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_garden_timestamp
    BEFORE UPDATE ON gardens
    FOR EACH ROW
    EXECUTE FUNCTION update_garden_timestamp();

-- Trigger to check garden level up after experience gain
CREATE OR REPLACE FUNCTION trigger_check_level_up()
RETURNS TRIGGER AS $$
BEGIN
    -- Only check if experience increased
    IF NEW.experience > OLD.experience THEN
        PERFORM check_garden_level_up(NEW.id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_garden_level_check
    AFTER UPDATE OF experience ON gardens
    FOR EACH ROW
    EXECUTE FUNCTION trigger_check_level_up();

-- Trigger to auto-apply weather effects
CREATE OR REPLACE FUNCTION apply_weather_effects()
RETURNS TRIGGER AS $$
DECLARE
    weather_record RECORD;
BEGIN
    -- Get weather details
    SELECT * INTO weather_record FROM garden_weather_events WHERE id = NEW.id;
    
    -- Apply weather effects based on type
    CASE weather_record.weather_type
        WHEN 'rain' THEN
            -- Rain auto-waters flowers
            IF weather_record.auto_water_flowers THEN
                UPDATE flowers SET 
                    last_watered = NOW(),
                    health = LEAST(health + 5, 100)
                WHERE garden_id = weather_record.garden_id;
            END IF;
            
        WHEN 'sunshine' THEN
            -- Sunshine boosts growth
            UPDATE flowers SET 
                health = LEAST(health + 3, 100)
            WHERE garden_id = weather_record.garden_id
            AND current_stage < (
                SELECT total_stages FROM flower_species 
                WHERE id = flowers.species_id
            );
            
        WHEN 'storm' THEN
            -- Storms can damage flowers but also provide water
            UPDATE flowers SET 
                health = GREATEST(health - 5, 10),
                last_watered = NOW()
            WHERE garden_id = weather_record.garden_id;
    END CASE;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_weather_effects
    AFTER INSERT ON garden_weather_events
    FOR EACH ROW
    EXECUTE FUNCTION apply_weather_effects();

-- Trigger to remove expired weather events
CREATE OR REPLACE FUNCTION cleanup_expired_weather()
RETURNS TRIGGER AS $$
BEGIN
    -- This could be called by a scheduled job instead
    DELETE FROM garden_weather_events 
    WHERE ends_at < NOW() - INTERVAL '1 hour';
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger that runs when weather ends_at is updated
CREATE TRIGGER trigger_weather_cleanup
    AFTER UPDATE OF ends_at ON garden_weather_events
    FOR EACH ROW
    WHEN (NEW.ends_at <= NOW())
    EXECUTE FUNCTION cleanup_expired_weather();

-- Trigger to auto-complete quests
CREATE OR REPLACE FUNCTION check_quest_completion()
RETURNS TRIGGER AS $$
DECLARE
    quest_record RECORD;
BEGIN
    -- Find related quests that might be completed
    FOR quest_record IN 
        SELECT qp.* FROM garden_quest_progress qp
        JOIN garden_daily_quests q ON qp.quest_id = q.id
        WHERE qp.garden_id = NEW.garden_id 
        AND qp.is_completed = false
        AND q.is_active = true
    LOOP
        -- Check if quest is now complete
        IF quest_record.current_progress >= quest_record.target_progress THEN
            UPDATE garden_quest_progress SET 
                is_completed = true,
                completed_at = NOW()
            WHERE id = quest_record.id;
        END IF;
    END LOOP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply quest check trigger to relevant tables
CREATE TRIGGER trigger_flower_quest_check
    AFTER INSERT OR UPDATE ON flowers
    FOR EACH ROW
    EXECUTE FUNCTION check_quest_completion();

CREATE TRIGGER trigger_visitor_quest_check
    AFTER UPDATE ON garden_visitor_instances
    FOR EACH ROW
    EXECUTE FUNCTION check_quest_completion();

-- =====================================================
-- SECURITY POLICIES (from 04_garden_security.sql)
-- =====================================================

-- Enable RLS on all garden tables
ALTER TABLE gardens ENABLE ROW LEVEL SECURITY;
ALTER TABLE flowers ENABLE ROW LEVEL SECURITY;
ALTER TABLE flower_species ENABLE ROW LEVEL SECURITY;
ALTER TABLE garden_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE garden_visitors ENABLE ROW LEVEL SECURITY;
ALTER TABLE garden_visitor_instances ENABLE ROW LEVEL SECURITY;
ALTER TABLE garden_weather_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE garden_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE garden_shop_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE garden_purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE garden_daily_quests ENABLE ROW LEVEL SECURITY;
ALTER TABLE garden_quest_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE garden_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE garden_shares ENABLE ROW LEVEL SECURITY;

-- Gardens policies
CREATE POLICY "Users can view own gardens" ON gardens
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own gardens" ON gardens
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own gardens" ON gardens
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own gardens" ON gardens
    FOR DELETE USING (auth.uid() = user_id);

-- Flowers policies
CREATE POLICY "Users can view flowers in own gardens" ON flowers
    FOR SELECT USING (
        garden_id IN (SELECT id FROM gardens WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can plant flowers in own gardens" ON flowers
    FOR INSERT WITH CHECK (
        garden_id IN (SELECT id FROM gardens WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can update flowers in own gardens" ON flowers
    FOR UPDATE USING (
        garden_id IN (SELECT id FROM gardens WHERE user_id = auth.uid())
    ) WITH CHECK (
        garden_id IN (SELECT id FROM gardens WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can remove flowers from own gardens" ON flowers
    FOR DELETE USING (
        garden_id IN (SELECT id FROM gardens WHERE user_id = auth.uid())
    );

-- Flower species policies (reference data)
CREATE POLICY "Everyone can view flower species" ON flower_species
    FOR SELECT USING (true);

-- Garden inventory policies
CREATE POLICY "Users can view inventory in own gardens" ON garden_inventory
    FOR SELECT USING (
        garden_id IN (SELECT id FROM gardens WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can manage inventory in own gardens" ON garden_inventory
    FOR ALL USING (
        garden_id IN (SELECT id FROM gardens WHERE user_id = auth.uid())
    ) WITH CHECK (
        garden_id IN (SELECT id FROM gardens WHERE user_id = auth.uid())
    );

-- Weather events policies
CREATE POLICY "Users can view weather in own gardens" ON garden_weather_events
    FOR SELECT USING (
        garden_id IN (SELECT id FROM gardens WHERE user_id = auth.uid())
    );

CREATE POLICY "System can create weather events" ON garden_weather_events
    FOR INSERT WITH CHECK (true);

CREATE POLICY "System can update weather events" ON garden_weather_events
    FOR UPDATE USING (true) WITH CHECK (true);

-- Shop items policies
CREATE POLICY "Everyone can view shop items" ON garden_shop_items
    FOR SELECT USING (is_available = true);

-- Purchases policies
CREATE POLICY "Users can view own purchases" ON garden_purchases
    FOR SELECT USING (
        garden_id IN (SELECT id FROM gardens WHERE user_id = auth.uid())
    );

CREATE POLICY "System can create purchases" ON garden_purchases
    FOR INSERT WITH CHECK (
        garden_id IN (SELECT id FROM gardens WHERE user_id = auth.uid())
    );

-- Visitor types policies (reference data)
CREATE POLICY "Everyone can view visitor types" ON garden_visitors
    FOR SELECT USING (true);

-- Visitor instances policies
CREATE POLICY "Users can view visitors in own gardens" ON garden_visitor_instances
    FOR SELECT USING (
        garden_id IN (SELECT id FROM gardens WHERE user_id = auth.uid())
    );

CREATE POLICY "System can create visitor instances" ON garden_visitor_instances
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can interact with visitors in own gardens" ON garden_visitor_instances
    FOR UPDATE USING (
        garden_id IN (SELECT id FROM gardens WHERE user_id = auth.uid())
    ) WITH CHECK (
        garden_id IN (SELECT id FROM gardens WHERE user_id = auth.uid())
    );

-- Achievements policies
CREATE POLICY "Users can view achievements in own gardens" ON garden_achievements
    FOR SELECT USING (
        garden_id IN (SELECT id FROM gardens WHERE user_id = auth.uid())
    );

CREATE POLICY "System can manage achievements" ON garden_achievements
    FOR ALL USING (true) WITH CHECK (true);

-- Daily quests policies
CREATE POLICY "Users can view quests in own gardens" ON garden_daily_quests
    FOR SELECT USING (
        garden_id IN (SELECT id FROM gardens WHERE user_id = auth.uid())
    );

CREATE POLICY "System can manage quests" ON garden_daily_quests
    FOR ALL USING (true) WITH CHECK (true);

-- Quest progress policies
CREATE POLICY "Users can view quest progress for own gardens" ON garden_quest_progress
    FOR SELECT USING (
        garden_id IN (SELECT id FROM gardens WHERE user_id = auth.uid())
    );

CREATE POLICY "System can manage quest progress" ON garden_quest_progress
    FOR ALL USING (true) WITH CHECK (true);

-- Analytics policies
CREATE POLICY "Users can view analytics for own gardens" ON garden_analytics
    FOR SELECT USING (
        garden_id IN (SELECT id FROM gardens WHERE user_id = auth.uid())
    );

CREATE POLICY "System can manage analytics" ON garden_analytics
    FOR ALL USING (true) WITH CHECK (true);

-- Shares policies
CREATE POLICY "Users can view shares for own gardens" ON garden_shares
    FOR SELECT USING (
        garden_id IN (SELECT id FROM gardens WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can create shares for own gardens" ON garden_shares
    FOR INSERT WITH CHECK (
        garden_id IN (SELECT id FROM gardens WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can update own shares" ON garden_shares
    FOR UPDATE USING (
        garden_id IN (SELECT id FROM gardens WHERE user_id = auth.uid())
    ) WITH CHECK (
        garden_id IN (SELECT id FROM gardens WHERE user_id = auth.uid())
    );

-- Helper functions for security
CREATE OR REPLACE FUNCTION is_garden_owner(p_garden_id UUID, p_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(SELECT 1 FROM gardens WHERE id = p_garden_id AND user_id = p_user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON FUNCTION create_garden TO authenticated;
GRANT EXECUTE ON FUNCTION plant_flower TO authenticated;
GRANT EXECUTE ON FUNCTION water_flower TO authenticated;
GRANT EXECUTE ON FUNCTION fertilize_flower TO authenticated;
GRANT EXECUTE ON FUNCTION try_grow_flower TO authenticated;
GRANT EXECUTE ON FUNCTION try_spawn_visitor TO authenticated;
GRANT EXECUTE ON FUNCTION interact_with_visitor TO authenticated;
GRANT EXECUTE ON FUNCTION purchase_garden_item TO authenticated;
GRANT EXECUTE ON FUNCTION get_garden_status TO authenticated;
GRANT EXECUTE ON FUNCTION check_garden_level_up TO authenticated;
GRANT EXECUTE ON FUNCTION is_garden_owner TO authenticated;

-- Grant select permissions for reference tables
GRANT SELECT ON flower_species TO anon;
GRANT SELECT ON garden_visitors TO anon;
GRANT SELECT ON garden_shop_items TO anon;

-- =====================================================
-- SAMPLE DATA SETUP
-- =====================================================

-- Insert sample flower species
INSERT INTO flower_species (name, water_frequency_hours, growth_time_hours, coin_reward, experience_reward) VALUES
    ('Sunflower', 8, 24, 15, 10),
    ('Rose', 6, 36, 25, 15),
    ('Tulip', 12, 18, 10, 8),
    ('Daisy', 10, 20, 12, 9),
    ('Lavender', 14, 48, 30, 20)
ON CONFLICT (name) DO NOTHING;

-- Insert sample garden visitors
INSERT INTO garden_visitors (name, coin_reward, experience_reward, min_garden_level) VALUES
    ('Butterfly', 5, 3, 1),
    ('Bee', 8, 5, 2),
    ('Bird', 12, 8, 3),
    ('Squirrel', 15, 10, 5),
    ('Fairy', 25, 15, 10)
ON CONFLICT (name) DO NOTHING;

-- Insert sample shop items
INSERT INTO garden_shop_items (item_type, item_name, description, cost_coins, cost_gems, category) VALUES
    ('tool', 'Premium Watering Can', 'Waters multiple flowers at once', 100, 0, 'tool'),
    ('tool', 'Super Fertilizer', 'Boosts growth significantly', 50, 0, 'consumable'),
    ('seed', 'Rare Orchid Seed', 'Grows into a valuable orchid', 0, 5, 'seed'),
    ('decoration', 'Garden Gnome', 'Increases happiness generation', 200, 0, 'decoration'),
    ('tool', 'Pest Spray', 'Removes pests from flowers', 30, 0, 'consumable')
ON CONFLICT (item_type, item_name) DO NOTHING;
