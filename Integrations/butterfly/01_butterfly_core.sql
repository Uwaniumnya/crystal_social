-- Butterfly Collection System Core Tables
-- Handles butterfly species, user collections, and discovery mechanics

-- Butterfly species master data
CREATE TABLE IF NOT EXISTS butterfly_species (
    id TEXT PRIMARY KEY, -- e.g., 'b1', 'b2', etc.
    name TEXT NOT NULL,
    image_path TEXT NOT NULL,
    rarity TEXT NOT NULL CHECK (rarity IN ('common', 'uncommon', 'rare', 'epic', 'legendary', 'mythical')),
    description TEXT DEFAULT 'A beautiful butterfly waiting to be discovered...',
    habitats TEXT[] DEFAULT '{"Garden", "Forest"}',
    discovery_chance DECIMAL(4,3) DEFAULT 0.100, -- Base discovery chance (0.001 to 1.000)
    collection_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    audio_effect TEXT, -- Sound effect for this butterfly
    special_effects JSONB DEFAULT '{}', -- Animation/visual effects
    lore TEXT, -- Extended butterfly lore/story
    scientific_name TEXT,
    wingspan_cm DECIMAL(4,1),
    flight_pattern TEXT,
    preferred_flowers TEXT[],
    season TEXT DEFAULT 'all' CHECK (season IN ('spring', 'summer', 'autumn', 'winter', 'all')),
    time_of_day TEXT DEFAULT 'all' CHECK (time_of_day IN ('dawn', 'morning', 'afternoon', 'dusk', 'night', 'all')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- User butterfly collections (unlocked butterflies)
CREATE TABLE IF NOT EXISTS butterfly_album (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    butterfly_id TEXT REFERENCES butterfly_species(id) ON DELETE CASCADE,
    discovered_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    discovery_method TEXT DEFAULT 'random' CHECK (discovery_method IN (
        'random',
        'daily_reward',
        'special_event',
        'gift',
        'purchase',
        'quest_reward',
        'milestone_reward'
    )),
    discovery_location TEXT,
    first_sighting BOOLEAN DEFAULT true,
    times_spotted INTEGER DEFAULT 1,
    last_interaction TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
    notes TEXT, -- User's personal notes about this butterfly
    UNIQUE(user_id, butterfly_id)
);

-- User favorite butterflies
CREATE TABLE IF NOT EXISTS butterfly_favorites (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    butterfly_id TEXT REFERENCES butterfly_species(id) ON DELETE CASCADE,
    favorited_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    UNIQUE(user_id, butterfly_id)
);

-- Butterfly discovery history and statistics
CREATE TABLE IF NOT EXISTS butterfly_discoveries (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    butterfly_id TEXT REFERENCES butterfly_species(id) ON DELETE CASCADE,
    discovery_type TEXT DEFAULT 'sighting' CHECK (discovery_type IN (
        'sighting',
        'capture',
        'release',
        'interaction',
        'photograph'
    )),
    location TEXT,
    weather_condition TEXT,
    time_of_discovery TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    experience_points INTEGER DEFAULT 0,
    coins_earned INTEGER DEFAULT 0,
    gems_earned INTEGER DEFAULT 0,
    special_reward JSONB,
    discovery_context JSONB DEFAULT '{}' -- Additional context data
);

-- Daily discovery tracking
CREATE TABLE IF NOT EXISTS butterfly_daily_rewards (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    reward_date DATE DEFAULT CURRENT_DATE,
    discoveries_available INTEGER DEFAULT 3,
    discoveries_used INTEGER DEFAULT 0,
    bonus_active BOOLEAN DEFAULT false,
    bonus_multiplier DECIMAL(3,2) DEFAULT 1.00,
    last_claim TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
    streak_count INTEGER DEFAULT 1,
    UNIQUE(user_id, reward_date)
);

-- Butterfly collection milestones and achievements
CREATE TABLE IF NOT EXISTS butterfly_milestones (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    milestone_type TEXT NOT NULL CHECK (milestone_type IN (
        'total_collected',
        'rarity_complete',
        'habitat_complete',
        'season_complete',
        'daily_streak',
        'favorite_count',
        'interaction_count'
    )),
    milestone_value INTEGER NOT NULL, -- e.g., 10, 25, 50 butterflies
    achieved_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    reward_claimed BOOLEAN DEFAULT false,
    reward_type TEXT CHECK (reward_type IN ('coins', 'gems', 'special_butterfly', 'title', 'decoration')),
    reward_amount INTEGER,
    reward_data JSONB,
    UNIQUE(user_id, milestone_type, milestone_value)
);

-- User butterfly collection statistics
CREATE TABLE IF NOT EXISTS butterfly_user_stats (
    user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    total_discovered INTEGER DEFAULT 0,
    total_favorites INTEGER DEFAULT 0,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    last_discovery TIMESTAMP WITH TIME ZONE,
    rarity_counts JSONB DEFAULT '{"common": 0, "uncommon": 0, "rare": 0, "epic": 0, "legendary": 0, "mythical": 0}',
    preferred_habitat TEXT,
    total_interactions INTEGER DEFAULT 0,
    total_experience INTEGER DEFAULT 0,
    collection_level INTEGER DEFAULT 1,
    collection_title TEXT DEFAULT 'Beginner Collector',
    achievement_points INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Butterfly rarity configuration
CREATE TABLE IF NOT EXISTS butterfly_rarity_config (
    rarity TEXT PRIMARY KEY,
    display_name TEXT NOT NULL,
    color_hex TEXT NOT NULL,
    discovery_weight INTEGER NOT NULL, -- Used for weighted random selection
    base_experience INTEGER DEFAULT 10,
    base_coins INTEGER DEFAULT 5,
    base_gems INTEGER DEFAULT 0,
    sound_effect TEXT,
    particle_effect TEXT,
    description TEXT,
    sort_order INTEGER DEFAULT 0
);

-- Insert default rarity configurations
INSERT INTO butterfly_rarity_config (rarity, display_name, color_hex, discovery_weight, base_experience, base_coins, base_gems, sound_effect, description, sort_order) VALUES
('common', 'Common', '#9E9E9E', 450, 10, 5, 0, 'chimes.mp3', 'Easy to discover, basic butterflies', 1),
('uncommon', 'Uncommon', '#4CAF50', 250, 20, 10, 1, 'chimes.mp3', 'Slightly rare, colorful butterflies', 2),
('rare', 'Rare', '#2196F3', 150, 50, 25, 2, 'chimes.mp3', 'Rare discoveries, beautiful butterflies', 3),
('epic', 'Epic', '#9C27B0', 100, 100, 50, 5, 'magical_chime.mp3', 'Epic finds, magical butterflies', 4),
('legendary', 'Legendary', '#FF9800', 40, 250, 100, 10, 'legendary_bell.mp3', 'Legendary creatures, special effects', 5),
('mythical', 'Mythical', '#E91E63', 10, 500, 250, 25, 'mythical_sparkle.mp3', 'Ultra rare, mythical beings', 6)
ON CONFLICT (rarity) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    color_hex = EXCLUDED.color_hex,
    discovery_weight = EXCLUDED.discovery_weight,
    base_experience = EXCLUDED.base_experience,
    base_coins = EXCLUDED.base_coins,
    base_gems = EXCLUDED.base_gems,
    sound_effect = EXCLUDED.sound_effect,
    description = EXCLUDED.description,
    sort_order = EXCLUDED.sort_order;

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_butterfly_species_rarity ON butterfly_species(rarity);
CREATE INDEX IF NOT EXISTS idx_butterfly_species_active ON butterfly_species(is_active);
CREATE INDEX IF NOT EXISTS idx_butterfly_species_collection_order ON butterfly_species(collection_order);

CREATE INDEX IF NOT EXISTS idx_butterfly_album_user_id ON butterfly_album(user_id);
CREATE INDEX IF NOT EXISTS idx_butterfly_album_butterfly_id ON butterfly_album(butterfly_id);
CREATE INDEX IF NOT EXISTS idx_butterfly_album_discovered_at ON butterfly_album(discovered_at);

CREATE INDEX IF NOT EXISTS idx_butterfly_favorites_user_id ON butterfly_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_butterfly_favorites_butterfly_id ON butterfly_favorites(butterfly_id);

CREATE INDEX IF NOT EXISTS idx_butterfly_discoveries_user_id ON butterfly_discoveries(user_id);
CREATE INDEX IF NOT EXISTS idx_butterfly_discoveries_butterfly_id ON butterfly_discoveries(butterfly_id);
CREATE INDEX IF NOT EXISTS idx_butterfly_discoveries_time ON butterfly_discoveries(time_of_discovery);

CREATE INDEX IF NOT EXISTS idx_butterfly_daily_rewards_user_date ON butterfly_daily_rewards(user_id, reward_date);

CREATE INDEX IF NOT EXISTS idx_butterfly_milestones_user_id ON butterfly_milestones(user_id);
CREATE INDEX IF NOT EXISTS idx_butterfly_milestones_type ON butterfly_milestones(milestone_type);

-- Enable RLS
ALTER TABLE butterfly_species ENABLE ROW LEVEL SECURITY;
ALTER TABLE butterfly_album ENABLE ROW LEVEL SECURITY;
ALTER TABLE butterfly_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE butterfly_discoveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE butterfly_daily_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE butterfly_milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE butterfly_user_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE butterfly_rarity_config ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Butterfly species - public readable
CREATE POLICY "Anyone can view butterfly species" ON butterfly_species
    FOR SELECT USING (is_active = true);

-- User collections - users can only see their own
CREATE POLICY "Users can view own butterfly album" ON butterfly_album
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can manage own butterfly album" ON butterfly_album
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Favorites - users can only manage their own
CREATE POLICY "Users can view own butterfly favorites" ON butterfly_favorites
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can manage own butterfly favorites" ON butterfly_favorites
    FOR ALL USING (user_id = auth.uid());

-- Discoveries - users can only see their own
CREATE POLICY "Users can view own butterfly discoveries" ON butterfly_discoveries
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can add own butterfly discoveries" ON butterfly_discoveries
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Daily rewards - users can only see their own
CREATE POLICY "Users can view own daily rewards" ON butterfly_daily_rewards
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can manage own daily rewards" ON butterfly_daily_rewards
    FOR ALL USING (user_id = auth.uid());

-- Milestones - users can only see their own
CREATE POLICY "Users can view own milestones" ON butterfly_milestones
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can achieve milestones" ON butterfly_milestones
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- User stats - users can only see their own
CREATE POLICY "Users can view own butterfly stats" ON butterfly_user_stats
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can update own butterfly stats" ON butterfly_user_stats
    FOR ALL USING (user_id = auth.uid());

-- Rarity config - public readable
CREATE POLICY "Anyone can view rarity config" ON butterfly_rarity_config
    FOR SELECT USING (true);

-- Functions

-- Update user stats when butterfly is discovered
CREATE OR REPLACE FUNCTION update_butterfly_user_stats()
RETURNS TRIGGER AS $$
DECLARE
    butterfly_rarity TEXT;
    rarity_counts JSONB;
    total_count INTEGER;
BEGIN
    -- Get butterfly rarity
    SELECT rarity INTO butterfly_rarity FROM butterfly_species WHERE id = NEW.butterfly_id;
    
    -- Initialize or update user stats
    INSERT INTO butterfly_user_stats (user_id)
    VALUES (NEW.user_id)
    ON CONFLICT (user_id) DO NOTHING;
    
    -- Get current rarity counts
    SELECT COALESCE(bus.rarity_counts, '{"common": 0, "uncommon": 0, "rare": 0, "epic": 0, "legendary": 0, "mythical": 0}'::jsonb)
    INTO rarity_counts
    FROM butterfly_user_stats bus
    WHERE bus.user_id = NEW.user_id;
    
    -- Update rarity count
    rarity_counts := jsonb_set(
        rarity_counts,
        ARRAY[butterfly_rarity],
        to_jsonb((rarity_counts->butterfly_rarity)::integer + 1)
    );
    
    -- Calculate total discovered
    SELECT COUNT(*) INTO total_count
    FROM butterfly_album
    WHERE user_id = NEW.user_id;
    
    -- Update user stats
    UPDATE butterfly_user_stats SET
        total_discovered = total_count,
        rarity_counts = rarity_counts,
        last_discovery = NEW.discovered_at,
        total_interactions = total_interactions + 1,
        updated_at = NOW()
    WHERE user_id = NEW.user_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for updating user stats
CREATE TRIGGER update_butterfly_stats_on_discovery
    AFTER INSERT ON butterfly_album
    FOR EACH ROW
    EXECUTE FUNCTION update_butterfly_user_stats();

-- Update favorite count when favorite is added/removed
CREATE OR REPLACE FUNCTION update_butterfly_favorite_stats()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE butterfly_user_stats SET
            total_favorites = total_favorites + 1,
            updated_at = NOW()
        WHERE user_id = NEW.user_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE butterfly_user_stats SET
            total_favorites = GREATEST(0, total_favorites - 1),
            updated_at = NOW()
        WHERE user_id = OLD.user_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Triggers for favorite stats
CREATE TRIGGER update_butterfly_favorite_stats_insert
    AFTER INSERT ON butterfly_favorites
    FOR EACH ROW
    EXECUTE FUNCTION update_butterfly_favorite_stats();

CREATE TRIGGER update_butterfly_favorite_stats_delete
    AFTER DELETE ON butterfly_favorites
    FOR EACH ROW
    EXECUTE FUNCTION update_butterfly_favorite_stats();

-- Function to get random butterfly for discovery
CREATE OR REPLACE FUNCTION get_random_butterfly_for_discovery(p_user_id UUID)
RETURNS TEXT AS $$
DECLARE
    available_butterflies TEXT[];
    weighted_selection TEXT[];
    rarity_weights RECORD;
    butterfly RECORD;
    selected_butterfly TEXT;
BEGIN
    -- Get butterflies not yet discovered by user
    SELECT ARRAY(
        SELECT bs.id
        FROM butterfly_species bs
        WHERE bs.is_active = true
        AND bs.id NOT IN (
            SELECT ba.butterfly_id
            FROM butterfly_album ba
            WHERE ba.user_id = p_user_id
        )
    ) INTO available_butterflies;
    
    -- If no butterflies available, return null
    IF array_length(available_butterflies, 1) IS NULL THEN
        RETURN NULL;
    END IF;
    
    -- Build weighted selection array based on rarity
    weighted_selection := ARRAY[]::TEXT[];
    
    FOR butterfly IN
        SELECT bs.id, bs.rarity, brc.discovery_weight
        FROM butterfly_species bs
        JOIN butterfly_rarity_config brc ON bs.rarity = brc.rarity
        WHERE bs.id = ANY(available_butterflies)
    LOOP
        -- Add butterfly ID to weighted array based on discovery weight
        FOR i IN 1..butterfly.discovery_weight LOOP
            weighted_selection := array_append(weighted_selection, butterfly.id);
        END LOOP;
    END LOOP;
    
    -- Select random butterfly from weighted array
    IF array_length(weighted_selection, 1) > 0 THEN
        selected_butterfly := weighted_selection[
            1 + floor(random() * array_length(weighted_selection, 1))::int
        ];
    ELSE
        -- Fallback to first available
        selected_butterfly := available_butterflies[1];
    END IF;
    
    RETURN selected_butterfly;
END;
$$ LANGUAGE plpgsql;

-- Function to check and award milestones
CREATE OR REPLACE FUNCTION check_butterfly_milestones(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
    user_stats RECORD;
    milestone_record RECORD;
BEGIN
    -- Get current user stats
    SELECT * INTO user_stats FROM butterfly_user_stats WHERE user_id = p_user_id;
    
    IF NOT FOUND THEN
        RETURN;
    END IF;
    
    -- Check total collection milestones
    FOR milestone_record IN
        SELECT * FROM (VALUES
            (10, 'coins', 100),
            (25, 'gems', 5),
            (50, 'coins', 500),
            (75, 'gems', 10),
            (90, 'special_butterfly', 1)
        ) AS milestones(count, reward_type, reward_amount)
        WHERE milestones.count <= user_stats.total_discovered
    LOOP
        INSERT INTO butterfly_milestones (
            user_id, milestone_type, milestone_value, reward_type, reward_amount
        ) VALUES (
            p_user_id, 'total_collected', milestone_record.count,
            milestone_record.reward_type, milestone_record.reward_amount
        ) ON CONFLICT (user_id, milestone_type, milestone_value) DO NOTHING;
    END LOOP;
    
    -- Check rarity completion milestones
    IF (user_stats.rarity_counts->>'mythical')::int > 0 THEN
        INSERT INTO butterfly_milestones (
            user_id, milestone_type, milestone_value, reward_type, reward_amount
        ) VALUES (
            p_user_id, 'rarity_complete', 6, 'gems', 50
        ) ON CONFLICT (user_id, milestone_type, milestone_value) DO NOTHING;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Trigger to check milestones after stats update
CREATE OR REPLACE FUNCTION trigger_milestone_check()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM check_butterfly_milestones(NEW.user_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_milestones_on_stats_update
    AFTER UPDATE ON butterfly_user_stats
    FOR EACH ROW
    EXECUTE FUNCTION trigger_milestone_check();
