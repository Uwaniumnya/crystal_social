-- Crystal Social Rewards System - Core Tables
-- File: 01_rewards_core_tables.sql
-- Purpose: Foundational database tables for the comprehensive rewards system

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- CORE CURRENCY AND BALANCE MANAGEMENT
-- =============================================================================

-- User rewards balances table
CREATE TABLE IF NOT EXISTS user_rewards (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    coins INTEGER DEFAULT 0 CHECK (coins >= 0),
    points INTEGER DEFAULT 0 CHECK (points >= 0),
    gems INTEGER DEFAULT 0 CHECK (gems >= 0),
    experience INTEGER DEFAULT 0 CHECK (experience >= 0),
    level INTEGER DEFAULT 1 CHECK (level >= 1),
    current_streak INTEGER DEFAULT 0 CHECK (current_streak >= 0),
    last_login TIMESTAMP WITH TIME ZONE,
    daily_reward_claimed_at TIMESTAMP WITH TIME ZONE,
    weekly_challenge_completed_at TIMESTAMP WITH TIME ZONE,
    monthly_challenge_completed_at TIMESTAMP WITH TIME ZONE,
    last_spin_wheel TIMESTAMP WITH TIME ZONE,
    last_hourly_bonus TIMESTAMP WITH TIME ZONE,
    total_purchased INTEGER DEFAULT 0 CHECK (total_purchased >= 0),
    total_spent INTEGER DEFAULT 0 CHECK (total_spent >= 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Unique constraint on user_id
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_rewards_user_id ON user_rewards(user_id);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_rewards_level ON user_rewards(level);
CREATE INDEX IF NOT EXISTS idx_user_rewards_coins ON user_rewards(coins);
CREATE INDEX IF NOT EXISTS idx_user_rewards_last_login ON user_rewards(last_login);

-- =============================================================================
-- SHOP ITEMS AND CATEGORIES
-- =============================================================================

-- Shop categories table
CREATE TABLE IF NOT EXISTS shop_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    icon_name VARCHAR(50),
    color_code VARCHAR(7), -- Hex color codes
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Shop items table
CREATE TABLE IF NOT EXISTS shop_items (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    category_id INTEGER NOT NULL REFERENCES shop_categories(id),
    price INTEGER NOT NULL CHECK (price >= 0),
    rarity VARCHAR(50) DEFAULT 'common' CHECK (rarity IN ('common', 'uncommon', 'rare', 'epic', 'legendary', 'mythic')),
    image_url TEXT,
    asset_path TEXT,
    effect_type VARCHAR(100),
    color_code VARCHAR(7),
    is_available BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    requires_level INTEGER DEFAULT 1 CHECK (requires_level >= 1),
    max_purchases INTEGER, -- NULL means unlimited
    sort_order INTEGER DEFAULT 0,
    metadata JSONB DEFAULT '{}',
    unlocked_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for shop items
CREATE INDEX IF NOT EXISTS idx_shop_items_category ON shop_items(category_id);
CREATE INDEX IF NOT EXISTS idx_shop_items_price ON shop_items(price);
CREATE INDEX IF NOT EXISTS idx_shop_items_rarity ON shop_items(rarity);
CREATE INDEX IF NOT EXISTS idx_shop_items_available ON shop_items(is_available);
CREATE INDEX IF NOT EXISTS idx_shop_items_featured ON shop_items(is_featured);
CREATE INDEX IF NOT EXISTS idx_shop_items_level ON shop_items(requires_level);

-- =============================================================================
-- USER INVENTORY SYSTEM
-- =============================================================================

-- User inventory table
CREATE TABLE IF NOT EXISTS user_inventory (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    item_id INTEGER NOT NULL REFERENCES shop_items(id),
    quantity INTEGER DEFAULT 1 CHECK (quantity > 0),
    equipped_at TIMESTAMP WITH TIME ZONE,
    purchased_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    source VARCHAR(100) DEFAULT 'purchase', -- purchase, achievement, gift, admin, etc.
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Composite index for user-item lookup
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_inventory_user_item ON user_inventory(user_id, item_id);

-- Indexes for inventory queries
CREATE INDEX IF NOT EXISTS idx_user_inventory_user_id ON user_inventory(user_id);

-- =============================================================================
-- AURA SYSTEM
-- =============================================================================

-- Aura items table (subset of shop_items with category_id = 2)
CREATE TABLE IF NOT EXISTS aura_items (
    id SERIAL PRIMARY KEY,
    shop_item_id INTEGER NOT NULL REFERENCES shop_items(id),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    color_code VARCHAR(7) NOT NULL,
    effect_type VARCHAR(100) DEFAULT 'glow',
    rarity VARCHAR(50) DEFAULT 'common',
    price INTEGER NOT NULL CHECK (price >= 0),
    unlock_level INTEGER DEFAULT 1 CHECK (unlock_level >= 1),
    is_animated BOOLEAN DEFAULT FALSE,
    animation_duration INTEGER, -- in milliseconds
    preview_url TEXT,
    unlocked_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User aura purchases table
CREATE TABLE IF NOT EXISTS user_aura_purchases (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    aura_item_id INTEGER NOT NULL REFERENCES aura_items(id),
    purchased_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    equipped_at TIMESTAMP WITH TIME ZONE,
    source VARCHAR(100) DEFAULT 'purchase'
);

-- User equipped aura table
CREATE TABLE IF NOT EXISTS user_equipped_aura (
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE PRIMARY KEY,
    aura_color VARCHAR(7),
    aura_item_id INTEGER REFERENCES aura_items(id),
    equipped_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for aura system
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_aura_purchases_user_item ON user_aura_purchases(user_id, aura_item_id);
CREATE INDEX IF NOT EXISTS idx_aura_items_color ON aura_items(color_code);
CREATE INDEX IF NOT EXISTS idx_aura_items_rarity ON aura_items(rarity);

-- =============================================================================
-- TRANSACTION AND AUDIT LOGGING
-- =============================================================================

-- Reward transactions table
CREATE TABLE IF NOT EXISTS reward_transactions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    transaction_type VARCHAR(50) NOT NULL CHECK (transaction_type IN ('coins', 'points', 'gems', 'item', 'achievement')),
    amount INTEGER NOT NULL,
    item_id INTEGER REFERENCES shop_items(id),
    source VARCHAR(100) NOT NULL, -- purchase, achievement, daily_login, message_reward, etc.
    description TEXT,
    metadata JSONB DEFAULT '{}',
    before_balance INTEGER,
    after_balance INTEGER,
    is_successful BOOLEAN DEFAULT TRUE,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for transaction queries
CREATE INDEX IF NOT EXISTS idx_reward_transactions_user_id ON reward_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_reward_transactions_type ON reward_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_reward_transactions_source ON reward_transactions(source);
CREATE INDEX IF NOT EXISTS idx_reward_transactions_created_at ON reward_transactions(created_at);
CREATE INDEX IF NOT EXISTS idx_reward_transactions_user_date ON reward_transactions(user_id, created_at);

-- Purchase audit table
CREATE TABLE IF NOT EXISTS purchase_audit (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profiles(id),
    item_id INTEGER NOT NULL REFERENCES shop_items(id),
    purchase_attempt_id UUID UNIQUE,
    attempt_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completion_timestamp TIMESTAMP WITH TIME ZONE,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),
    payment_amount INTEGER NOT NULL,
    currency_type VARCHAR(20) DEFAULT 'coins',
    error_code VARCHAR(100),
    error_message TEXT,
    ip_address INET,
    user_agent TEXT,
    session_data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for purchase audit
CREATE INDEX IF NOT EXISTS idx_purchase_audit_user_id ON purchase_audit(user_id);
CREATE INDEX IF NOT EXISTS idx_purchase_audit_status ON purchase_audit(status);
CREATE INDEX IF NOT EXISTS idx_purchase_audit_timestamp ON purchase_audit(attempt_timestamp);

-- =============================================================================
-- LEVEL AND PROGRESS SYSTEM
-- =============================================================================

-- Level requirements table
CREATE TABLE IF NOT EXISTS level_requirements (
    level INTEGER PRIMARY KEY CHECK (level >= 1),
    experience_required INTEGER NOT NULL CHECK (experience_required >= 0),
    coins_reward INTEGER DEFAULT 0 CHECK (coins_reward >= 0),
    points_reward INTEGER DEFAULT 0 CHECK (points_reward >= 0),
    title VARCHAR(100),
    badge_icon VARCHAR(100),
    unlocks_feature VARCHAR(200),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User level progress table
CREATE TABLE IF NOT EXISTS user_level_progress (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    current_level INTEGER NOT NULL DEFAULT 1,
    current_experience INTEGER NOT NULL DEFAULT 0,
    total_experience INTEGER NOT NULL DEFAULT 0,
    level_up_count INTEGER DEFAULT 0,
    last_level_up TIMESTAMP WITH TIME ZONE,
    next_level_experience INTEGER,
    progress_percentage DECIMAL(5,2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Unique constraint on user_id
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_level_progress_user_id ON user_level_progress(user_id);

-- Indexes for level queries
CREATE INDEX IF NOT EXISTS idx_user_level_progress_level ON user_level_progress(current_level);
CREATE INDEX IF NOT EXISTS idx_user_level_progress_experience ON user_level_progress(current_experience);

-- =============================================================================
-- DAILY AND PERIODIC REWARDS
-- =============================================================================

-- Daily rewards table
CREATE TABLE IF NOT EXISTS daily_rewards (
    id SERIAL PRIMARY KEY,
    day_number INTEGER NOT NULL UNIQUE CHECK (day_number >= 1 AND day_number <= 30),
    coins_reward INTEGER DEFAULT 0 CHECK (coins_reward >= 0),
    points_reward INTEGER DEFAULT 0 CHECK (points_reward >= 0),
    item_id INTEGER REFERENCES shop_items(id),
    is_special_day BOOLEAN DEFAULT FALSE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User daily reward claims table
CREATE TABLE IF NOT EXISTS user_daily_reward_claims (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    claim_date DATE NOT NULL,
    day_number INTEGER NOT NULL,
    coins_earned INTEGER DEFAULT 0,
    points_earned INTEGER DEFAULT 0,
    item_received INTEGER REFERENCES shop_items(id),
    consecutive_days INTEGER DEFAULT 1,
    claimed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Unique constraint on user daily claims
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_daily_claims_user_date ON user_daily_reward_claims(user_id, claim_date);

-- Indexes for daily reward queries
CREATE INDEX IF NOT EXISTS idx_user_daily_claims_user_id ON user_daily_reward_claims(user_id);
CREATE INDEX IF NOT EXISTS idx_user_daily_claims_consecutive ON user_daily_reward_claims(consecutive_days);

-- =============================================================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================================================

-- Enable RLS on all user-specific tables
ALTER TABLE user_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_aura_purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_equipped_aura ENABLE ROW LEVEL SECURITY;
ALTER TABLE reward_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_level_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_daily_reward_claims ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own rewards" ON user_rewards FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update their own rewards" ON user_rewards FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own inventory" ON user_inventory FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own inventory" ON user_inventory FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own aura purchases" ON user_aura_purchases FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own aura purchases" ON user_aura_purchases FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own equipped aura" ON user_equipped_aura FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update their own equipped aura" ON user_equipped_aura FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own transactions" ON reward_transactions FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own level progress" ON user_level_progress FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update their own level progress" ON user_level_progress FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own daily claims" ON user_daily_reward_claims FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own daily claims" ON user_daily_reward_claims FOR ALL USING (auth.uid() = user_id);

-- Public access for shop data
CREATE POLICY "Shop categories are viewable by everyone" ON shop_categories FOR SELECT USING (true);
CREATE POLICY "Shop items are viewable by everyone" ON shop_items FOR SELECT USING (true);
CREATE POLICY "Aura items are viewable by everyone" ON aura_items FOR SELECT USING (true);
CREATE POLICY "Level requirements are viewable by everyone" ON level_requirements FOR SELECT USING (true);
CREATE POLICY "Daily rewards are viewable by everyone" ON daily_rewards FOR SELECT USING (true);

-- =============================================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- =============================================================================

-- Apply triggers to tables with updated_at columns
-- Note: update_updated_at_column() function is defined in 00_shared_utilities.sql
CREATE TRIGGER update_user_rewards_updated_at BEFORE UPDATE ON user_rewards FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_shop_categories_updated_at BEFORE UPDATE ON shop_categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_shop_items_updated_at BEFORE UPDATE ON shop_items FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_aura_items_updated_at BEFORE UPDATE ON aura_items FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_equipped_aura_updated_at BEFORE UPDATE ON user_equipped_aura FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_level_progress_updated_at BEFORE UPDATE ON user_level_progress FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE user_rewards IS 'Core user balance and currency management for the rewards system';
COMMENT ON TABLE shop_categories IS 'Categories for organizing shop items (auras, pets, decorations, etc.)';
COMMENT ON TABLE shop_items IS 'All purchasable items in the shop with pricing and metadata';
COMMENT ON TABLE user_inventory IS 'User-owned items with equipped status and purchase history';
COMMENT ON TABLE aura_items IS 'Specialized aura effects with visual properties';
COMMENT ON TABLE user_aura_purchases IS 'User purchases of aura items';
COMMENT ON TABLE user_equipped_aura IS 'Currently equipped aura for each user';
COMMENT ON TABLE reward_transactions IS 'Complete audit trail of all reward transactions';
COMMENT ON TABLE purchase_audit IS 'Detailed purchase attempt tracking for security and debugging';
COMMENT ON TABLE level_requirements IS 'Experience requirements and rewards for each level';
COMMENT ON TABLE user_level_progress IS 'User level progression and experience tracking';
COMMENT ON TABLE daily_rewards IS 'Daily reward configuration for consecutive login bonuses';
COMMENT ON TABLE user_daily_reward_claims IS 'User daily reward claim history and streaks';
