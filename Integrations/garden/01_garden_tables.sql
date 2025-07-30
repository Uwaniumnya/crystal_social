-- =====================================================
-- CRYSTAL SOCIAL - GARDEN SYSTEM TABLES
-- =====================================================
-- Core tables for comprehensive crystal garden functionality
-- Includes: Gardens, Flowers, Growth, Weather, Inventory, and More
-- =====================================================

-- User gardens table - each user can have multiple gardens
CREATE TABLE IF NOT EXISTS gardens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    name VARCHAR(255) DEFAULT 'My Garden',
    description TEXT,
    background_image VARCHAR(255) DEFAULT 'assets/garden/backgrounds/garden_1.png',
    theme VARCHAR(50) DEFAULT 'classic' CHECK (theme IN ('classic', 'enchanted', 'tropical', 'desert', 'arctic')),
    season VARCHAR(50) DEFAULT 'spring' CHECK (season IN ('spring', 'summer', 'autumn', 'winter')),
    
    -- Garden economy
    coins INTEGER DEFAULT 0,
    gems INTEGER DEFAULT 0,
    level INTEGER DEFAULT 1,
    experience INTEGER DEFAULT 0,
    
    -- Garden environment
    fertility DECIMAL(5,2) DEFAULT 100.0,
    weather VARCHAR(50) DEFAULT 'sunny' CHECK (weather IN ('sunny', 'rainy', 'snowy', 'windy', 'misty')),
    last_weather_change TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Garden features
    has_decoration BOOLEAN DEFAULT false,
    decoration_type VARCHAR(100),
    max_flowers INTEGER DEFAULT 6,
    is_premium BOOLEAN DEFAULT false,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_visited_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Garden settings
    auto_water_enabled BOOLEAN DEFAULT false,
    music_enabled BOOLEAN DEFAULT true,
    sound_effects_enabled BOOLEAN DEFAULT true,
    
    -- Statistics
    total_flowers_grown INTEGER DEFAULT 0,
    total_flowers_bloomed INTEGER DEFAULT 0,
    days_active INTEGER DEFAULT 0,
    
    UNIQUE(user_id, name)
);

-- Flower species definitions
CREATE TABLE IF NOT EXISTS flower_species (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    rarity VARCHAR(20) DEFAULT 'common' CHECK (rarity IN ('common', 'rare', 'epic')),
    base_image_path VARCHAR(255),
    colors JSONB DEFAULT '[]'::jsonb, -- Array of color hex codes
    bloom_sounds JSONB DEFAULT '[]'::jsonb, -- Array of sound file names
    
    -- Growth requirements
    min_water_hours INTEGER DEFAULT 2,
    min_fertilizer_hours INTEGER DEFAULT 6,
    growth_stages INTEGER DEFAULT 4,
    bloom_chance DECIMAL(3,2) DEFAULT 0.80,
    
    -- Special properties
    has_special_effect BOOLEAN DEFAULT false,
    special_effect_type VARCHAR(50),
    seasonal_bonus JSONB DEFAULT '{}'::jsonb, -- Season-specific bonuses
    
    -- Rewards
    base_experience INTEGER DEFAULT 10,
    base_coins INTEGER DEFAULT 5,
    bloom_experience INTEGER DEFAULT 25,
    bloom_coins INTEGER DEFAULT 15,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Individual flowers in gardens
CREATE TABLE IF NOT EXISTS flowers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    garden_id UUID REFERENCES gardens(id) ON DELETE CASCADE,
    species_id UUID REFERENCES flower_species(id) ON DELETE SET NULL,
    
    -- Position in garden
    x_position DECIMAL(5,2) NOT NULL,
    y_position DECIMAL(5,2) NOT NULL,
    
    -- Growth state
    growth_stage VARCHAR(20) DEFAULT 'seed' CHECK (growth_stage IN ('seed', 'sprout', 'bud', 'bloomed')),
    age_hours DECIMAL(8,2) DEFAULT 0.0,
    
    -- Health and care
    health INTEGER DEFAULT 100 CHECK (health BETWEEN 0 AND 100),
    happiness INTEGER DEFAULT 50 CHECK (happiness BETWEEN 0 AND 100),
    
    -- Care history
    last_watered_at TIMESTAMP WITH TIME ZONE,
    last_fertilized_at TIMESTAMP WITH TIME ZONE,
    total_waterings INTEGER DEFAULT 0,
    total_fertilizations INTEGER DEFAULT 0,
    
    -- Special states
    has_bloomed BOOLEAN DEFAULT false,
    has_sung BOOLEAN DEFAULT false,
    is_pest_infected BOOLEAN DEFAULT false,
    has_special_effect BOOLEAN DEFAULT false,
    is_wilting BOOLEAN DEFAULT false,
    
    -- Timestamps
    planted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    first_bloom_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Flower-specific properties
    custom_name VARCHAR(100),
    rarity VARCHAR(20) DEFAULT 'common',
    current_size DECIMAL(3,2) DEFAULT 0.3,
    color_variant VARCHAR(7), -- Hex color code
    
    -- Performance tracking
    growth_events INTEGER DEFAULT 0,
    rewards_generated INTEGER DEFAULT 0
);

-- Garden inventory system
CREATE TABLE IF NOT EXISTS garden_inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    garden_id UUID REFERENCES gardens(id) ON DELETE CASCADE,
    item_type VARCHAR(50) NOT NULL,
    item_name VARCHAR(100) NOT NULL,
    quantity INTEGER DEFAULT 0,
    max_quantity INTEGER DEFAULT 999,
    
    -- Item properties
    item_rarity VARCHAR(20) DEFAULT 'common',
    item_description TEXT,
    item_icon_path VARCHAR(255),
    
    -- Usage tracking
    total_used INTEGER DEFAULT 0,
    last_used_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(garden_id, item_type, item_name)
);

-- Garden visitors (creatures that visit gardens)
CREATE TABLE IF NOT EXISTS garden_visitors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    image_path VARCHAR(255),
    visitor_type VARCHAR(50) DEFAULT 'fairy' CHECK (visitor_type IN ('fairy', 'unicorn', 'gnome', 'butterfly', 'dragon', 'phoenix')),
    rarity VARCHAR(20) DEFAULT 'common' CHECK (rarity IN ('common', 'rare', 'epic', 'legendary')),
    
    -- Visit behavior
    min_garden_level INTEGER DEFAULT 1,
    visit_chance DECIMAL(4,3) DEFAULT 0.100,
    stay_duration_minutes INTEGER DEFAULT 30,
    
    -- Rewards given
    reward_type VARCHAR(50), -- 'coins', 'gems', 'items', 'experience'
    reward_amount INTEGER DEFAULT 10,
    reward_items JSONB DEFAULT '[]'::jsonb,
    
    -- Requirements
    required_flowers INTEGER DEFAULT 1,
    required_flower_types JSONB DEFAULT '[]'::jsonb,
    seasonal_availability JSONB DEFAULT '["spring", "summer", "autumn", "winter"]'::jsonb,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Active visitor instances in gardens
CREATE TABLE IF NOT EXISTS garden_visitor_instances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    garden_id UUID REFERENCES gardens(id) ON DELETE CASCADE,
    visitor_id UUID REFERENCES garden_visitors(id) ON DELETE CASCADE,
    
    arrived_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    will_leave_at TIMESTAMP WITH TIME ZONE NOT NULL,
    has_given_reward BOOLEAN DEFAULT false,
    
    -- Position in garden
    x_position DECIMAL(5,2),
    y_position DECIMAL(5,2),
    
    -- Interaction tracking
    times_interacted INTEGER DEFAULT 0,
    reward_claimed_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Weather events and effects
CREATE TABLE IF NOT EXISTS garden_weather_events (
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

-- Garden achievements and milestones
CREATE TABLE IF NOT EXISTS garden_achievements (
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
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(garden_id, achievement_type, achievement_name)
);

-- Garden shop items
CREATE TABLE IF NOT EXISTS garden_shop_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_name VARCHAR(100) NOT NULL,
    item_type VARCHAR(50) NOT NULL,
    description TEXT,
    icon_path VARCHAR(255),
    
    -- Pricing
    price_coins INTEGER DEFAULT 0,
    price_gems INTEGER DEFAULT 0,
    is_premium BOOLEAN DEFAULT false,
    
    -- Availability
    is_available BOOLEAN DEFAULT true,
    stock_quantity INTEGER, -- NULL = unlimited
    min_level_required INTEGER DEFAULT 1,
    seasonal_availability JSONB DEFAULT '["spring", "summer", "autumn", "winter"]'::jsonb,
    
    -- Item properties
    item_rarity VARCHAR(20) DEFAULT 'common',
    category VARCHAR(50) DEFAULT 'general',
    effects JSONB DEFAULT '{}'::jsonb,
    
    -- Sales tracking
    total_sold INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Garden purchase history
CREATE TABLE IF NOT EXISTS garden_purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    garden_id UUID REFERENCES gardens(id) ON DELETE CASCADE,
    shop_item_id UUID REFERENCES garden_shop_items(id) ON DELETE SET NULL,
    
    -- Purchase details
    item_name VARCHAR(100) NOT NULL,
    quantity INTEGER DEFAULT 1,
    price_paid_coins INTEGER DEFAULT 0,
    price_paid_gems INTEGER DEFAULT 0,
    
    purchased_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Purchase context
    user_level_at_purchase INTEGER,
    season_at_purchase VARCHAR(50)
);

-- Garden daily quests/tasks
CREATE TABLE IF NOT EXISTS garden_daily_quests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quest_name VARCHAR(255) NOT NULL,
    description TEXT,
    quest_type VARCHAR(50) NOT NULL,
    
    -- Quest requirements
    target_action VARCHAR(100) NOT NULL, -- 'water_flowers', 'grow_flower', 'visit_garden', etc.
    target_quantity INTEGER DEFAULT 1,
    target_rarity VARCHAR(20), -- For flower-specific quests
    
    -- Rewards
    reward_coins INTEGER DEFAULT 10,
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
CREATE TABLE IF NOT EXISTS garden_quest_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    garden_id UUID REFERENCES gardens(id) ON DELETE CASCADE,
    quest_id UUID REFERENCES garden_daily_quests(id) ON DELETE CASCADE,
    
    -- Progress tracking
    current_progress INTEGER DEFAULT 0,
    target_progress INTEGER NOT NULL,
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Quest instance (daily)
    quest_date DATE DEFAULT CURRENT_DATE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(garden_id, quest_id, quest_date)
);

-- Garden analytics and statistics
CREATE TABLE IF NOT EXISTS garden_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    garden_id UUID REFERENCES gardens(id) ON DELETE CASCADE,
    
    -- Daily statistics
    date DATE DEFAULT CURRENT_DATE,
    
    -- Activity metrics
    flowers_planted INTEGER DEFAULT 0,
    flowers_watered INTEGER DEFAULT 0,
    flowers_fertilized INTEGER DEFAULT 0,
    flowers_bloomed INTEGER DEFAULT 0,
    visitors_received INTEGER DEFAULT 0,
    
    -- Economy metrics
    coins_earned INTEGER DEFAULT 0,
    coins_spent INTEGER DEFAULT 0,
    gems_earned INTEGER DEFAULT 0,
    gems_spent INTEGER DEFAULT 0,
    
    -- Time metrics
    time_spent_seconds INTEGER DEFAULT 0,
    sessions INTEGER DEFAULT 0,
    
    -- Achievements
    achievements_unlocked INTEGER DEFAULT 0,
    quests_completed INTEGER DEFAULT 0,
    
    UNIQUE(garden_id, date)
);

-- Garden sharing and social features
CREATE TABLE IF NOT EXISTS garden_shares (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    garden_id UUID REFERENCES gardens(id) ON DELETE CASCADE,
    shared_by_user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    
    -- Share details
    share_type VARCHAR(50) DEFAULT 'garden_visit' CHECK (share_type IN ('garden_visit', 'flower_showcase', 'achievement')),
    title VARCHAR(255),
    description TEXT,
    image_url TEXT,
    
    -- Engagement
    views INTEGER DEFAULT 0,
    likes INTEGER DEFAULT 0,
    
    -- Privacy
    allowed_viewers JSONB DEFAULT '[]'::jsonb, -- Array of user IDs
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE
);

-- =====================================================
-- INDEXES FOR PERFORMANCE OPTIMIZATION
-- =====================================================

-- Primary performance indexes
CREATE INDEX IF NOT EXISTS idx_gardens_user_level ON gardens(user_id, level DESC);
CREATE INDEX IF NOT EXISTS idx_gardens_updated ON gardens(updated_at DESC);

-- Flower indexes
CREATE INDEX IF NOT EXISTS idx_flowers_garden_growth ON flowers(garden_id, growth_stage);
CREATE INDEX IF NOT EXISTS idx_flowers_position ON flowers(garden_id, x_position, y_position);
CREATE INDEX IF NOT EXISTS idx_flowers_care_needed ON flowers(garden_id, last_watered_at, last_fertilized_at);
CREATE INDEX IF NOT EXISTS idx_flowers_health ON flowers(health, happiness);

-- Inventory and items
CREATE INDEX IF NOT EXISTS idx_garden_inventory_type ON garden_inventory(garden_id, item_type);
CREATE INDEX IF NOT EXISTS idx_shop_items_available ON garden_shop_items(is_available, category, min_level_required);

-- Visitors and events
CREATE INDEX IF NOT EXISTS idx_visitor_instances_active ON garden_visitor_instances(garden_id, will_leave_at);
CREATE INDEX IF NOT EXISTS idx_weather_events_active ON garden_weather_events(garden_id, ends_at);

-- Analytics and tracking
CREATE INDEX IF NOT EXISTS idx_garden_analytics_date ON garden_analytics(garden_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_quest_progress_active ON garden_quest_progress(garden_id, quest_date, is_completed);

-- Social features
CREATE INDEX IF NOT EXISTS idx_garden_shares_created ON garden_shares(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_garden_shares_user ON garden_shares(shared_by_user_id, created_at DESC);

-- Species and achievements
CREATE INDEX IF NOT EXISTS idx_flower_species_rarity ON flower_species(rarity, name);
CREATE INDEX IF NOT EXISTS idx_achievements_garden ON garden_achievements(garden_id, is_completed, achievement_type);

-- =====================================================
-- COMMENTS AND DOCUMENTATION
-- =====================================================

COMMENT ON TABLE gardens IS 'User-owned gardens with themes, levels, and economy';
COMMENT ON TABLE flower_species IS 'Definitions of different flower types and their properties';
COMMENT ON TABLE flowers IS 'Individual flower instances planted in gardens';
COMMENT ON TABLE garden_inventory IS 'Garden-specific inventory items (seeds, tools, decorations)';
COMMENT ON TABLE garden_visitors IS 'Creature types that can visit gardens';
COMMENT ON TABLE garden_visitor_instances IS 'Active visitor instances in specific gardens';
COMMENT ON TABLE garden_weather_events IS 'Weather effects and their impact on gardens';
COMMENT ON TABLE garden_achievements IS 'Garden-specific achievements and milestones';
COMMENT ON TABLE garden_shop_items IS 'Items available for purchase in the garden shop';
COMMENT ON TABLE garden_purchases IS 'Purchase history for garden items';
COMMENT ON TABLE garden_daily_quests IS 'Daily quest definitions for gardens';
COMMENT ON TABLE garden_quest_progress IS 'User progress on daily garden quests';
COMMENT ON TABLE garden_analytics IS 'Daily analytics and statistics for gardens';
COMMENT ON TABLE garden_shares IS 'Shared garden content and social features';
