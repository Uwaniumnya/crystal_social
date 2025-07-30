-- Crystal Social Rewards System - Achievement System
-- File: 02_rewards_achievements.sql
-- Purpose: Comprehensive achievement system with progress tracking and rewards

-- =============================================================================
-- ACHIEVEMENT DEFINITIONS
-- =============================================================================

-- Achievement categories table
CREATE TABLE IF NOT EXISTS achievement_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    icon_name VARCHAR(50),
    color_code VARCHAR(7),
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default achievement categories
INSERT INTO achievement_categories (name, description, icon_name, color_code, sort_order) VALUES
('Social', 'Achievements related to social interactions and friendships', 'people', '#E91E63', 1),
('Gaming', 'Achievements related to games and entertainment features', 'games', '#2196F3', 2),
('Collecting', 'Achievements for collecting items and building inventory', 'inventory', '#4CAF50', 3),
('Progress', 'Achievements for general progress and milestones', 'trending_up', '#FF9800', 4),
('Special', 'Special limited-time or unique achievements', 'star', '#9C27B0', 5)
ON CONFLICT (name) DO NOTHING;

-- Achievements table
CREATE TABLE IF NOT EXISTS achievements (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    category_id INTEGER NOT NULL REFERENCES achievement_categories(id),
    achievement_type VARCHAR(100) NOT NULL, -- message_count, login_streak, purchase_amount, etc.
    target_value INTEGER NOT NULL CHECK (target_value > 0),
    coins_reward INTEGER DEFAULT 0 CHECK (coins_reward >= 0),
    points_reward INTEGER DEFAULT 0 CHECK (points_reward >= 0),
    item_reward INTEGER REFERENCES shop_items(id),
    badge_icon VARCHAR(100),
    badge_color VARCHAR(7),
    rarity VARCHAR(50) DEFAULT 'common' CHECK (rarity IN ('common', 'uncommon', 'rare', 'epic', 'legendary')),
    is_hidden BOOLEAN DEFAULT FALSE,
    is_repeatable BOOLEAN DEFAULT FALSE,
    requires_level INTEGER DEFAULT 1 CHECK (requires_level >= 1),
    unlock_condition JSONB DEFAULT '{}', -- Additional unlock conditions
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for achievements
CREATE INDEX IF NOT EXISTS idx_achievements_category ON achievements(category_id);
CREATE INDEX IF NOT EXISTS idx_achievements_type ON achievements(achievement_type);
CREATE INDEX IF NOT EXISTS idx_achievements_rarity ON achievements(rarity);
CREATE INDEX IF NOT EXISTS idx_achievements_active ON achievements(is_active);
CREATE INDEX IF NOT EXISTS idx_achievements_level ON achievements(requires_level);

-- =============================================================================
-- USER ACHIEVEMENT PROGRESS
-- =============================================================================

-- User achievement progress table
CREATE TABLE IF NOT EXISTS user_achievement_progress (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    achievement_id INTEGER NOT NULL REFERENCES achievements(id),
    current_progress INTEGER DEFAULT 0 CHECK (current_progress >= 0),
    target_value INTEGER NOT NULL,
    progress_percentage DECIMAL(5,2) DEFAULT 0.00,
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP WITH TIME ZONE,
    notified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Unique constraint on user-achievement combination
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_achievement_progress_unique ON user_achievement_progress(user_id, achievement_id);

-- Indexes for achievement progress queries
CREATE INDEX IF NOT EXISTS idx_user_achievement_progress_user_id ON user_achievement_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievement_progress_completed ON user_achievement_progress(is_completed);
CREATE INDEX IF NOT EXISTS idx_user_achievement_progress_percentage ON user_achievement_progress(progress_percentage);
CREATE INDEX IF NOT EXISTS idx_user_achievement_progress_updated ON user_achievement_progress(updated_at);

-- User completed achievements table
CREATE TABLE IF NOT EXISTS user_achievements (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    achievement_id INTEGER NOT NULL REFERENCES achievements(id),
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completion_progress INTEGER NOT NULL,
    coins_earned INTEGER DEFAULT 0,
    points_earned INTEGER DEFAULT 0,
    item_received INTEGER REFERENCES shop_items(id),
    notification_sent BOOLEAN DEFAULT FALSE,
    celebration_shown BOOLEAN DEFAULT FALSE,
    metadata JSONB DEFAULT '{}'
);

-- Unique constraint on user-achievement combination for completed achievements
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_achievements_unique ON user_achievements(user_id, achievement_id);

-- Indexes for completed achievements
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_completed_at ON user_achievements(completed_at);
CREATE INDEX IF NOT EXISTS idx_user_achievements_achievement_id ON user_achievements(achievement_id);

-- =============================================================================
-- ACHIEVEMENT STATISTICS AND LEADERBOARDS
-- =============================================================================

-- Achievement statistics table
CREATE TABLE IF NOT EXISTS achievement_statistics (
    achievement_id INTEGER NOT NULL REFERENCES achievements(id) PRIMARY KEY,
    total_completions INTEGER DEFAULT 0,
    total_attempts INTEGER DEFAULT 0,
    completion_rate DECIMAL(5,2) DEFAULT 0.00,
    average_completion_time_hours DECIMAL(10,2),
    fastest_completion_hours DECIMAL(10,2),
    first_completed_by UUID REFERENCES profiles(id),
    first_completed_at TIMESTAMP WITH TIME ZONE,
    last_completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User achievement statistics table
CREATE TABLE IF NOT EXISTS user_achievement_stats (
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE PRIMARY KEY,
    total_achievements INTEGER DEFAULT 0,
    common_achievements INTEGER DEFAULT 0,
    uncommon_achievements INTEGER DEFAULT 0,
    rare_achievements INTEGER DEFAULT 0,
    epic_achievements INTEGER DEFAULT 0,
    legendary_achievements INTEGER DEFAULT 0,
    social_achievements INTEGER DEFAULT 0,
    gaming_achievements INTEGER DEFAULT 0,
    collecting_achievements INTEGER DEFAULT 0,
    progress_achievements INTEGER DEFAULT 0,
    special_achievements INTEGER DEFAULT 0,
    achievement_score INTEGER DEFAULT 0,
    completion_percentage DECIMAL(5,2) DEFAULT 0.00,
    total_coins_from_achievements INTEGER DEFAULT 0,
    total_points_from_achievements INTEGER DEFAULT 0,
    first_achievement_at TIMESTAMP WITH TIME ZONE,
    last_achievement_at TIMESTAMP WITH TIME ZONE,
    fastest_achievement_time_hours DECIMAL(10,2),
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================================================
-- BESTIE BOND SYSTEM
-- =============================================================================

-- Bestie bonds table
CREATE TABLE IF NOT EXISTS bestie_bonds (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    friend_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    bond_level INTEGER DEFAULT 1 CHECK (bond_level >= 1 AND bond_level <= 10),
    experience_points INTEGER DEFAULT 0 CHECK (experience_points >= 0),
    level_progress DECIMAL(5,2) DEFAULT 0.00,
    total_interactions INTEGER DEFAULT 0,
    shared_activities INTEGER DEFAULT 0,
    gifts_exchanged INTEGER DEFAULT 0,
    messages_sent INTEGER DEFAULT 0,
    level_up_rewards_claimed BOOLEAN DEFAULT FALSE,
    last_interaction TIMESTAMP WITH TIME ZONE,
    bond_started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure users can't have bond with themselves
    CONSTRAINT check_different_users CHECK (user_id != friend_id)
);

-- Unique constraint ensuring one bond per user pair (regardless of order)
CREATE UNIQUE INDEX IF NOT EXISTS idx_bestie_bonds_unique_pair ON bestie_bonds(LEAST(user_id, friend_id), GREATEST(user_id, friend_id));

-- Indexes for bestie bonds
CREATE INDEX IF NOT EXISTS idx_bestie_bonds_user_id ON bestie_bonds(user_id);
CREATE INDEX IF NOT EXISTS idx_bestie_bonds_friend_id ON bestie_bonds(friend_id);
CREATE INDEX IF NOT EXISTS idx_bestie_bonds_level ON bestie_bonds(bond_level);
CREATE INDEX IF NOT EXISTS idx_bestie_bonds_last_interaction ON bestie_bonds(last_interaction);

-- Bestie bond activities table
CREATE TABLE IF NOT EXISTS bestie_bond_activities (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    bond_id UUID NOT NULL REFERENCES bestie_bonds(id) ON DELETE CASCADE,
    activity_type VARCHAR(100) NOT NULL, -- message, game, gift, shared_post, etc.
    experience_gained INTEGER DEFAULT 0,
    description TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for bond activities
CREATE INDEX IF NOT EXISTS idx_bestie_bond_activities_bond_id ON bestie_bond_activities(bond_id);
CREATE INDEX IF NOT EXISTS idx_bestie_bond_activities_type ON bestie_bond_activities(activity_type);
CREATE INDEX IF NOT EXISTS idx_bestie_bond_activities_created_at ON bestie_bond_activities(created_at);

-- =============================================================================
-- BOOSTER PACK SYSTEM
-- =============================================================================

-- Booster pack openings table
CREATE TABLE IF NOT EXISTS booster_pack_openings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    booster_item_id INTEGER NOT NULL REFERENCES shop_items(id),
    opened_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    items_received JSONB NOT NULL DEFAULT '[]', -- Array of item objects
    rare_items_count INTEGER DEFAULT 0,
    epic_items_count INTEGER DEFAULT 0,
    legendary_items_count INTEGER DEFAULT 0,
    total_value INTEGER DEFAULT 0, -- Total coin value of received items
    opening_animation VARCHAR(100) DEFAULT 'default',
    celebration_level VARCHAR(50) DEFAULT 'normal', -- normal, exciting, legendary
    metadata JSONB DEFAULT '{}'
);

-- Indexes for booster pack openings
CREATE INDEX IF NOT EXISTS idx_booster_pack_openings_user_id ON booster_pack_openings(user_id);
CREATE INDEX IF NOT EXISTS idx_booster_pack_openings_item_id ON booster_pack_openings(booster_item_id);
CREATE INDEX IF NOT EXISTS idx_booster_pack_openings_opened_at ON booster_pack_openings(opened_at);

-- Booster pack statistics table
CREATE TABLE IF NOT EXISTS booster_pack_statistics (
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE PRIMARY KEY,
    total_packs_opened INTEGER DEFAULT 0,
    total_items_received INTEGER DEFAULT 0,
    common_items_received INTEGER DEFAULT 0,
    uncommon_items_received INTEGER DEFAULT 0,
    rare_items_received INTEGER DEFAULT 0,
    epic_items_received INTEGER DEFAULT 0,
    legendary_items_received INTEGER DEFAULT 0,
    total_value_received INTEGER DEFAULT 0,
    best_pack_value INTEGER DEFAULT 0,
    lucky_streak INTEGER DEFAULT 0,
    longest_lucky_streak INTEGER DEFAULT 0,
    first_pack_opened_at TIMESTAMP WITH TIME ZONE,
    last_pack_opened_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================================================
-- CURRENCY EARNING ACTIVITIES
-- =============================================================================

-- Currency earning activities table
CREATE TABLE IF NOT EXISTS currency_earning_activities (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    activity_type VARCHAR(100) NOT NULL, -- spin_wheel, hourly_bonus, quest_completion, etc.
    coins_earned INTEGER DEFAULT 0,
    points_earned INTEGER DEFAULT 0,
    gems_earned INTEGER DEFAULT 0,
    bonus_multiplier DECIMAL(3,2) DEFAULT 1.00,
    activity_metadata JSONB DEFAULT '{}',
    next_available_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for currency earning activities
CREATE INDEX IF NOT EXISTS idx_currency_earning_user_id ON currency_earning_activities(user_id);
CREATE INDEX IF NOT EXISTS idx_currency_earning_activity_type ON currency_earning_activities(activity_type);
CREATE INDEX IF NOT EXISTS idx_currency_earning_completed_at ON currency_earning_activities(completed_at);
CREATE INDEX IF NOT EXISTS idx_currency_earning_next_available ON currency_earning_activities(next_available_at);

-- Quests and challenges table
CREATE TABLE IF NOT EXISTS user_quests (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    quest_type VARCHAR(100) NOT NULL, -- daily, weekly, monthly, special
    quest_name VARCHAR(200) NOT NULL,
    description TEXT,
    target_value INTEGER NOT NULL,
    current_progress INTEGER DEFAULT 0,
    coins_reward INTEGER DEFAULT 0,
    points_reward INTEGER DEFAULT 0,
    item_reward INTEGER REFERENCES shop_items(id),
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for user quests
CREATE INDEX IF NOT EXISTS idx_user_quests_user_id ON user_quests(user_id);
CREATE INDEX IF NOT EXISTS idx_user_quests_type ON user_quests(quest_type);
CREATE INDEX IF NOT EXISTS idx_user_quests_completed ON user_quests(is_completed);
CREATE INDEX IF NOT EXISTS idx_user_quests_expires_at ON user_quests(expires_at);

-- =============================================================================
-- ROW LEVEL SECURITY
-- =============================================================================

-- Enable RLS on achievement-related tables
ALTER TABLE user_achievement_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievement_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE bestie_bonds ENABLE ROW LEVEL SECURITY;
ALTER TABLE bestie_bond_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE booster_pack_openings ENABLE ROW LEVEL SECURITY;
ALTER TABLE booster_pack_statistics ENABLE ROW LEVEL SECURITY;
ALTER TABLE currency_earning_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_quests ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for achievements
CREATE POLICY "Users can view their own achievement progress" ON user_achievement_progress FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own achievement progress" ON user_achievement_progress FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own completed achievements" ON user_achievements FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own completed achievements" ON user_achievements FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own achievement stats" ON user_achievement_stats FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update their own achievement stats" ON user_achievement_stats FOR UPDATE USING (auth.uid() = user_id);

-- RLS policies for bestie bonds
CREATE POLICY "Users can view bonds they're part of" ON bestie_bonds FOR SELECT USING (auth.uid() = user_id OR auth.uid() = friend_id);
CREATE POLICY "Users can manage bonds they're part of" ON bestie_bonds FOR ALL USING (auth.uid() = user_id OR auth.uid() = friend_id);

CREATE POLICY "Users can view bond activities they're part of" ON bestie_bond_activities 
FOR SELECT USING (EXISTS (SELECT 1 FROM bestie_bonds WHERE id = bond_id AND (user_id = auth.uid() OR friend_id = auth.uid())));

-- RLS policies for booster packs
CREATE POLICY "Users can view their own booster openings" ON booster_pack_openings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own booster openings" ON booster_pack_openings FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own booster statistics" ON booster_pack_statistics FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update their own booster statistics" ON booster_pack_statistics FOR UPDATE USING (auth.uid() = user_id);

-- RLS policies for currency earning
CREATE POLICY "Users can view their own currency activities" ON currency_earning_activities FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own currency activities" ON currency_earning_activities FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own quests" ON user_quests FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own quests" ON user_quests FOR ALL USING (auth.uid() = user_id);

-- Public access for achievement definitions
CREATE POLICY "Achievement categories are viewable by everyone" ON achievement_categories FOR SELECT USING (true);
CREATE POLICY "Achievements are viewable by everyone" ON achievements FOR SELECT USING (true);
CREATE POLICY "Achievement statistics are viewable by everyone" ON achievement_statistics FOR SELECT USING (true);

-- =============================================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- =============================================================================

-- Apply update triggers to tables with updated_at columns
CREATE TRIGGER update_achievements_updated_at BEFORE UPDATE ON achievements FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_achievement_progress_updated_at BEFORE UPDATE ON user_achievement_progress FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_achievement_statistics_updated_at BEFORE UPDATE ON achievement_statistics FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_achievement_stats_updated_at BEFORE UPDATE ON user_achievement_stats FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_bestie_bonds_updated_at BEFORE UPDATE ON bestie_bonds FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_booster_pack_statistics_updated_at BEFORE UPDATE ON booster_pack_statistics FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_quests_updated_at BEFORE UPDATE ON user_quests FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE achievement_categories IS 'Categories for organizing different types of achievements';
COMMENT ON TABLE achievements IS 'Achievement definitions with requirements and rewards';
COMMENT ON TABLE user_achievement_progress IS 'User progress towards completing achievements';
COMMENT ON TABLE user_achievements IS 'Completed achievements with earned rewards';
COMMENT ON TABLE achievement_statistics IS 'Global statistics for achievement completion rates';
COMMENT ON TABLE user_achievement_stats IS 'Comprehensive achievement statistics per user';
COMMENT ON TABLE bestie_bonds IS 'Friendship level system between users';
COMMENT ON TABLE bestie_bond_activities IS 'Activities that strengthen bestie bonds';
COMMENT ON TABLE booster_pack_openings IS 'Record of booster pack openings and rewards received';
COMMENT ON TABLE booster_pack_statistics IS 'User statistics for booster pack opening history';
COMMENT ON TABLE currency_earning_activities IS 'Activities that reward users with currency';
COMMENT ON TABLE user_quests IS 'Daily, weekly, and special quest system for users';
