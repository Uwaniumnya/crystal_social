-- =====================================================
-- CRYSTAL SOCIAL - PETS SYSTEM TABLES
-- =====================================================
-- Database schema for virtual pet system with care,
-- breeding, accessories, mini-games and social features
-- =====================================================

-- =====================================================
-- CORE PETS TABLES
-- =====================================================

-- User pets - instances of pets owned by users
CREATE TABLE user_pets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    pet_type VARCHAR(50) NOT NULL, -- cat, dog, bunny, axolotl, dragon, etc.
    pet_name VARCHAR(100) NOT NULL,
    rarity VARCHAR(20) NOT NULL DEFAULT 'common', -- common, uncommon, rare, epic, legendary, mythical
    personality VARCHAR(20) NOT NULL DEFAULT 'friendly', -- playful, calm, energetic, lazy, friendly, shy, brave, mischievous
    
    -- Pet stats and vitals
    level INTEGER NOT NULL DEFAULT 1,
    experience_points INTEGER NOT NULL DEFAULT 0,
    bond_level INTEGER NOT NULL DEFAULT 1,
    bond_xp INTEGER NOT NULL DEFAULT 0,
    
    -- Health and happiness metrics
    health DECIMAL(5,2) NOT NULL DEFAULT 100.00 CHECK (health >= 0 AND health <= 100),
    happiness DECIMAL(5,2) NOT NULL DEFAULT 100.00 CHECK (happiness >= 0 AND happiness <= 100),
    energy DECIMAL(5,2) NOT NULL DEFAULT 100.00 CHECK (energy >= 0 AND energy <= 100),
    hunger DECIMAL(5,2) NOT NULL DEFAULT 0.00 CHECK (hunger >= 0 AND hunger <= 100),
    
    -- Activity tracking
    last_fed_at TIMESTAMP WITH TIME ZONE,
    last_played_at TIMESTAMP WITH TIME ZONE,
    last_pet_at TIMESTAMP WITH TIME ZONE,
    total_interactions INTEGER NOT NULL DEFAULT 0,
    
    -- Current state
    current_mood VARCHAR(20) NOT NULL DEFAULT 'content', -- happy, sad, angry, sleepy, playful, content, excited, sick
    current_activity VARCHAR(50) DEFAULT 'idle', -- idle, eating, playing, sleeping, exploring
    selected_accessory_id UUID,
    
    -- Customization
    custom_color_scheme JSONB DEFAULT '{}',
    personality_traits JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    hatched_at TIMESTAMP WITH TIME ZONE,
    last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(user_id, pet_name)
);

-- Pet templates/types - defines available pet species
CREATE TABLE pet_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pet_type VARCHAR(50) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    lore TEXT,
    
    -- Visual assets
    base_asset_path VARCHAR(500) NOT NULL,
    icon_asset_path VARCHAR(500),
    thumbnail_asset_path VARCHAR(500),
    
    -- Pet characteristics
    default_rarity VARCHAR(20) NOT NULL DEFAULT 'common',
    default_personality VARCHAR(20) NOT NULL DEFAULT 'friendly',
    base_stats JSONB NOT NULL DEFAULT '{"health": 100, "happiness": 100, "energy": 100}',
    growth_rates JSONB NOT NULL DEFAULT '{"health": 1.0, "happiness": 1.0, "energy": 1.0}',
    
    -- Speech and behavior
    speech_lines TEXT[] DEFAULT ARRAY[]::TEXT[],
    mood_speech JSONB DEFAULT '{}',
    favorite_activities TEXT[] DEFAULT ARRAY[]::TEXT[],
    disliked_activities TEXT[] DEFAULT ARRAY[]::TEXT[],
    
    -- Shop configuration
    shop_price DECIMAL(10,2) DEFAULT 100.00,
    shop_category VARCHAR(50) DEFAULT 'pet',
    is_available_in_shop BOOLEAN DEFAULT true,
    unlock_requirements JSONB DEFAULT '{}',
    
    -- Metadata
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Pet accessories system
CREATE TABLE pet_accessories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    accessory_id VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50) NOT NULL, -- headwear, neckwear, clothing, magical, seasonal, premium
    rarity VARCHAR(20) NOT NULL DEFAULT 'common',
    
    -- Visual assets
    icon_asset_path VARCHAR(500) NOT NULL,
    preview_asset_path VARCHAR(500),
    
    -- Compatibility
    compatible_pet_types TEXT[] DEFAULT ARRAY[]::TEXT[], -- empty array means compatible with all
    asset_overrides JSONB DEFAULT '{}', -- pet_type -> custom_asset_path mappings
    
    -- Shop and unlock
    shop_price DECIMAL(10,2) DEFAULT 50.00,
    shop_category VARCHAR(50) DEFAULT 'accessory',
    is_available_in_shop BOOLEAN DEFAULT true,
    unlock_requirements JSONB DEFAULT '{}',
    
    -- Special properties
    is_animated BOOLEAN DEFAULT false,
    stat_bonuses JSONB DEFAULT '{}', -- happiness, health, energy bonuses
    special_effects JSONB DEFAULT '{}',
    
    -- Metadata
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    lore TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User's unlocked accessories
CREATE TABLE user_pet_accessories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    accessory_id UUID NOT NULL REFERENCES pet_accessories(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    unlock_method VARCHAR(100), -- purchase, achievement, event, gift
    
    UNIQUE(user_id, accessory_id)
);

-- =====================================================
-- PET CARE AND FEEDING SYSTEM
-- =====================================================

-- Food items available for pets
CREATE TABLE pet_foods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    food_id VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50) NOT NULL, -- drinks, fruits_and_vegetables, meals, meat, sweets
    
    -- Visual assets
    asset_path VARCHAR(500) NOT NULL,
    icon_path VARCHAR(500),
    
    -- Nutritional effects
    health_boost INTEGER DEFAULT 0,
    happiness_boost INTEGER DEFAULT 0,
    energy_boost INTEGER DEFAULT 0,
    hunger_reduction INTEGER DEFAULT 20,
    
    -- Pet preferences
    preferred_by_types TEXT[] DEFAULT ARRAY[]::TEXT[],
    disliked_by_types TEXT[] DEFAULT ARRAY[]::TEXT[],
    
    -- Shop configuration
    rarity VARCHAR(20) NOT NULL DEFAULT 'common',
    shop_price DECIMAL(10,2) DEFAULT 10.00,
    shop_category VARCHAR(50) DEFAULT 'food',
    is_available_in_shop BOOLEAN DEFAULT true,
    
    -- Special properties
    special_effects JSONB DEFAULT '{}',
    duration_minutes INTEGER DEFAULT 0, -- how long effects last
    
    -- Metadata
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Pet feeding history
CREATE TABLE pet_feeding_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_pet_id UUID NOT NULL REFERENCES user_pets(id) ON DELETE CASCADE,
    food_id UUID NOT NULL REFERENCES pet_foods(id),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Feeding details
    quantity INTEGER DEFAULT 1,
    effectiveness_rating INTEGER CHECK (effectiveness_rating >= 1 AND effectiveness_rating <= 5),
    pet_reaction VARCHAR(50), -- loved, liked, neutral, disliked, hated
    
    -- Effects applied
    health_change DECIMAL(5,2) DEFAULT 0,
    happiness_change DECIMAL(5,2) DEFAULT 0,
    energy_change DECIMAL(5,2) DEFAULT 0,
    hunger_change DECIMAL(5,2) DEFAULT 0,
    
    fed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- PET ACTIVITIES AND MINI-GAMES
-- =====================================================

-- Available activities and mini-games
CREATE TABLE pet_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    activity_type VARCHAR(50) NOT NULL, -- mini_game, interaction, exercise, training
    
    -- Game configuration
    difficulty_level INTEGER DEFAULT 1 CHECK (difficulty_level >= 1 AND difficulty_level <= 5),
    duration_seconds INTEGER DEFAULT 60,
    energy_cost DECIMAL(5,2) DEFAULT 10.00,
    
    -- Rewards configuration
    base_happiness_reward DECIMAL(5,2) DEFAULT 10.00,
    base_experience_reward INTEGER DEFAULT 5,
    base_bond_xp_reward INTEGER DEFAULT 3,
    
    -- Requirements
    minimum_pet_level INTEGER DEFAULT 1,
    minimum_energy DECIMAL(5,2) DEFAULT 10.00,
    cooldown_minutes INTEGER DEFAULT 5,
    
    -- Metadata
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Pet activity/game sessions
CREATE TABLE pet_activity_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_pet_id UUID NOT NULL REFERENCES user_pets(id) ON DELETE CASCADE,
    activity_id UUID NOT NULL REFERENCES pet_activities(id),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Session details
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER,
    
    -- Performance metrics
    score DECIMAL(10,2) DEFAULT 0,
    performance_rating DECIMAL(3,2) DEFAULT 0 CHECK (performance_rating >= 0 AND performance_rating <= 1),
    success_rate DECIMAL(3,2) DEFAULT 0 CHECK (success_rate >= 0 AND success_rate <= 1),
    
    -- Rewards earned
    happiness_gained DECIMAL(5,2) DEFAULT 0,
    energy_spent DECIMAL(5,2) DEFAULT 0,
    experience_gained INTEGER DEFAULT 0,
    bond_xp_gained INTEGER DEFAULT 0,
    
    -- Session data
    game_data JSONB DEFAULT '{}', -- specific game state/results
    achievements_unlocked TEXT[] DEFAULT ARRAY[]::TEXT[],
    
    -- Status
    session_status VARCHAR(20) DEFAULT 'completed' -- completed, abandoned, failed
);

-- =====================================================
-- PET BREEDING AND GENETICS
-- =====================================================

-- Pet breeding pairs and offspring
CREATE TABLE pet_breeding (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent1_id UUID NOT NULL REFERENCES user_pets(id),
    parent2_id UUID NOT NULL REFERENCES user_pets(id),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Breeding process
    breeding_started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    breeding_completed_at TIMESTAMP WITH TIME ZONE,
    incubation_time_minutes INTEGER DEFAULT 1440, -- 24 hours default
    
    -- Offspring details
    offspring_pet_id UUID REFERENCES user_pets(id),
    offspring_traits JSONB DEFAULT '{}',
    genetic_combination JSONB DEFAULT '{}',
    
    -- Special breeding
    is_special_breeding BOOLEAN DEFAULT false,
    breeding_method VARCHAR(50) DEFAULT 'natural', -- natural, magical, laboratory
    breeding_bonuses JSONB DEFAULT '{}',
    
    -- Status
    breeding_status VARCHAR(20) DEFAULT 'in_progress', -- in_progress, completed, failed, cancelled
    
    -- Constraints to prevent self-breeding
    CHECK (parent1_id != parent2_id)
);

-- Genetic traits system
CREATE TABLE pet_genetic_traits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trait_id VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50) NOT NULL, -- appearance, behavior, stats, special
    
    -- Inheritance
    inheritance_type VARCHAR(20) DEFAULT 'recessive', -- dominant, recessive, co_dominant
    rarity_weight DECIMAL(3,2) DEFAULT 0.5 CHECK (rarity_weight >= 0 AND rarity_weight <= 1),
    
    -- Effects
    stat_modifiers JSONB DEFAULT '{}',
    appearance_changes JSONB DEFAULT '{}',
    behavior_changes JSONB DEFAULT '{}',
    special_abilities JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Pet traits mapping
CREATE TABLE user_pet_traits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_pet_id UUID NOT NULL REFERENCES user_pets(id) ON DELETE CASCADE,
    trait_id UUID NOT NULL REFERENCES pet_genetic_traits(id),
    
    -- Trait expression
    expression_strength DECIMAL(3,2) DEFAULT 1.0 CHECK (expression_strength >= 0 AND expression_strength <= 1),
    is_dominant BOOLEAN DEFAULT false,
    inherited_from VARCHAR(20), -- parent1, parent2, mutation, gift
    
    acquired_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_pet_id, trait_id)
);

-- =====================================================
-- PET ACHIEVEMENTS AND PROGRESS
-- =====================================================

-- Achievement definitions
CREATE TABLE pet_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    achievement_id VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    category VARCHAR(50) NOT NULL, -- care, training, bonding, collection, special
    
    -- Requirements
    requirement_type VARCHAR(50) NOT NULL, -- stat_threshold, activity_count, time_based, special
    requirement_data JSONB NOT NULL DEFAULT '{}',
    difficulty_level INTEGER DEFAULT 1 CHECK (difficulty_level >= 1 AND difficulty_level <= 5),
    
    -- Rewards
    reward_experience INTEGER DEFAULT 0,
    reward_bond_xp INTEGER DEFAULT 0,
    reward_currency INTEGER DEFAULT 0,
    reward_items JSONB DEFAULT '{}',
    
    -- Visual
    icon_path VARCHAR(500),
    badge_color VARCHAR(20) DEFAULT 'bronze', -- bronze, silver, gold, platinum, diamond
    
    -- Metadata
    is_secret BOOLEAN DEFAULT false,
    is_repeatable BOOLEAN DEFAULT false,
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User achievement progress
CREATE TABLE user_pet_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    achievement_id UUID NOT NULL REFERENCES pet_achievements(id),
    user_pet_id UUID REFERENCES user_pets(id), -- if achievement is pet-specific
    
    -- Progress tracking
    current_progress DECIMAL(10,2) DEFAULT 0,
    target_progress DECIMAL(10,2) NOT NULL,
    progress_percentage DECIMAL(5,2) GENERATED ALWAYS AS (
        CASE 
            WHEN target_progress > 0 THEN LEAST(100, (current_progress / target_progress) * 100)
            ELSE 0
        END
    ) STORED,
    
    -- Completion
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMP WITH TIME ZONE,
    completion_count INTEGER DEFAULT 0, -- for repeatable achievements
    
    -- Metadata
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, achievement_id, user_pet_id)
);

-- =====================================================
-- PET SOCIAL FEATURES
-- =====================================================

-- Pet friendships and social interactions
CREATE TABLE pet_friendships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pet1_id UUID NOT NULL REFERENCES user_pets(id) ON DELETE CASCADE,
    pet2_id UUID NOT NULL REFERENCES user_pets(id) ON DELETE CASCADE,
    
    -- Friendship details
    friendship_level INTEGER DEFAULT 1 CHECK (friendship_level >= 1 AND friendship_level <= 10),
    friendship_xp INTEGER DEFAULT 0,
    compatibility_score DECIMAL(3,2) DEFAULT 0.5 CHECK (compatibility_score >= 0 AND compatibility_score <= 1),
    
    -- Interaction history
    first_meeting_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_interaction_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    total_interactions INTEGER DEFAULT 0,
    
    -- Status
    friendship_status VARCHAR(20) DEFAULT 'acquainted', -- acquainted, friends, best_friends, rivals
    
    -- Constraint to prevent duplicate friendships
    UNIQUE(pet1_id, pet2_id),
    CHECK (pet1_id != pet2_id)
);

-- Pet playdates and social activities
CREATE TABLE pet_playdates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizer_user_id UUID NOT NULL REFERENCES auth.users(id),
    organizer_pet_id UUID NOT NULL REFERENCES user_pets(id),
    
    -- Playdate details
    title VARCHAR(200),
    description TEXT,
    activity_type VARCHAR(50) DEFAULT 'free_play', -- free_play, mini_game, training, adventure
    
    -- Scheduling
    scheduled_start_time TIMESTAMP WITH TIME ZONE,
    scheduled_end_time TIMESTAMP WITH TIME ZONE,
    actual_start_time TIMESTAMP WITH TIME ZONE,
    actual_end_time TIMESTAMP WITH TIME ZONE,
    
    -- Configuration
    max_participants INTEGER DEFAULT 4,
    current_participants INTEGER DEFAULT 1,
    is_public BOOLEAN DEFAULT true,
    location_name VARCHAR(100),
    
    -- Status
    playdate_status VARCHAR(20) DEFAULT 'scheduled', -- scheduled, active, completed, cancelled
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Playdate participants
CREATE TABLE pet_playdate_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    playdate_id UUID NOT NULL REFERENCES pet_playdates(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    pet_id UUID NOT NULL REFERENCES user_pets(id) ON DELETE CASCADE,
    
    -- Participation details
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    participation_status VARCHAR(20) DEFAULT 'joined', -- joined, left, kicked, completed
    contribution_score DECIMAL(5,2) DEFAULT 0,
    
    -- Rewards
    experience_earned INTEGER DEFAULT 0,
    friendship_xp_earned INTEGER DEFAULT 0,
    
    UNIQUE(playdate_id, user_id, pet_id)
);

-- =====================================================
-- PET ANALYTICS AND STATISTICS
-- =====================================================

-- Daily pet statistics
CREATE TABLE pet_daily_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_pet_id UUID NOT NULL REFERENCES user_pets(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    
    -- Daily metrics
    interactions_count INTEGER DEFAULT 0,
    feeding_count INTEGER DEFAULT 0,
    playing_count INTEGER DEFAULT 0,
    petting_count INTEGER DEFAULT 0,
    
    -- Stat changes
    happiness_gained DECIMAL(5,2) DEFAULT 0,
    energy_spent DECIMAL(5,2) DEFAULT 0,
    health_change DECIMAL(5,2) DEFAULT 0,
    experience_gained INTEGER DEFAULT 0,
    bond_xp_gained INTEGER DEFAULT 0,
    
    -- Activity time
    total_active_minutes INTEGER DEFAULT 0,
    game_time_minutes INTEGER DEFAULT 0,
    care_time_minutes INTEGER DEFAULT 0,
    
    -- Achievements
    achievements_unlocked INTEGER DEFAULT 0,
    
    -- Wellbeing scores (end of day)
    end_happiness DECIMAL(5,2),
    end_energy DECIMAL(5,2),
    end_health DECIMAL(5,2),
    
    UNIQUE(user_pet_id, date)
);

-- User pet preferences and settings
CREATE TABLE user_pet_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Notification preferences
    enable_care_reminders BOOLEAN DEFAULT true,
    enable_activity_suggestions BOOLEAN DEFAULT true,
    enable_achievement_notifications BOOLEAN DEFAULT true,
    reminder_frequency_hours INTEGER DEFAULT 4,
    
    -- Display preferences
    preferred_pet_view VARCHAR(20) DEFAULT 'grid', -- grid, list, card
    show_detailed_stats BOOLEAN DEFAULT true,
    enable_animations BOOLEAN DEFAULT true,
    enable_sound_effects BOOLEAN DEFAULT true,
    enable_haptic_feedback BOOLEAN DEFAULT true,
    
    -- Privacy settings
    allow_pet_visibility BOOLEAN DEFAULT true,
    allow_playdate_invites BOOLEAN DEFAULT true,
    allow_breeding_requests BOOLEAN DEFAULT true,
    
    -- Advanced preferences
    auto_care_enabled BOOLEAN DEFAULT false,
    preferred_difficulty_level INTEGER DEFAULT 2,
    custom_themes JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id)
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- User pets indexes
CREATE INDEX idx_user_pets_user_id ON user_pets(user_id);
CREATE INDEX idx_user_pets_pet_type ON user_pets(pet_type);
CREATE INDEX idx_user_pets_level ON user_pets(level);
CREATE INDEX idx_user_pets_last_active ON user_pets(last_active_at);
CREATE INDEX idx_user_pets_mood ON user_pets(current_mood);

-- Pet accessories indexes
CREATE INDEX idx_pet_accessories_category ON pet_accessories(category);
CREATE INDEX idx_pet_accessories_rarity ON pet_accessories(rarity);
CREATE INDEX idx_pet_accessories_shop ON pet_accessories(is_available_in_shop, shop_price);
CREATE INDEX idx_user_pet_accessories_user_id ON user_pet_accessories(user_id);

-- Pet care indexes
CREATE INDEX idx_pet_feeding_user_pet ON pet_feeding_history(user_pet_id, fed_at);
CREATE INDEX idx_pet_feeding_food_effectiveness ON pet_feeding_history(food_id, effectiveness_rating);

-- Activities and games indexes
CREATE INDEX idx_pet_activities_type ON pet_activities(activity_type, is_active);
CREATE INDEX idx_pet_activity_sessions_pet_date ON pet_activity_sessions(user_pet_id, started_at);
CREATE INDEX idx_pet_activity_sessions_performance ON pet_activity_sessions(activity_id, performance_rating);

-- Social features indexes
CREATE INDEX idx_pet_friendships_pets ON pet_friendships(pet1_id, pet2_id);
CREATE INDEX idx_pet_playdates_status_time ON pet_playdates(playdate_status, scheduled_start_time);
CREATE INDEX idx_playdate_participants_playdate ON pet_playdate_participants(playdate_id);

-- Analytics indexes
CREATE INDEX idx_pet_daily_stats_date ON pet_daily_stats(user_pet_id, date);
CREATE INDEX idx_pet_daily_stats_user_date ON pet_daily_stats(user_id, date);

-- Achievements indexes
CREATE INDEX idx_pet_achievements_category ON pet_achievements(category, difficulty_level);
CREATE INDEX idx_user_achievements_progress ON user_pet_achievements(user_id, is_completed, progress_percentage);
CREATE INDEX idx_user_achievements_pet ON user_pet_achievements(user_pet_id, is_completed);
