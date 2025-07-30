-- Butterfly Events and Special Features
-- Handles special events, seasons, quests, and temporary butterflies

-- Special butterfly events
CREATE TABLE IF NOT EXISTS butterfly_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    event_name TEXT NOT NULL,
    event_type TEXT NOT NULL CHECK (event_type IN (
        'seasonal',
        'holiday',
        'special_release',
        'community',
        'limited_time',
        'celebration'
    )),
    description TEXT NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    requirements JSONB DEFAULT '{}', -- Requirements to participate
    rewards JSONB DEFAULT '{}', -- Event rewards
    event_config JSONB DEFAULT '{}', -- Event-specific configuration
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Event-specific butterflies that appear only during events
CREATE TABLE IF NOT EXISTS butterfly_event_species (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    event_id UUID REFERENCES butterfly_events(id) ON DELETE CASCADE,
    butterfly_id TEXT REFERENCES butterfly_species(id) ON DELETE CASCADE,
    event_discovery_chance DECIMAL(4,3) DEFAULT 0.050, -- Special event discovery rate
    is_exclusive BOOLEAN DEFAULT false, -- Only available during this event
    bonus_rewards JSONB DEFAULT '{}',
    UNIQUE(event_id, butterfly_id)
);

-- User participation in butterfly events
CREATE TABLE IF NOT EXISTS butterfly_event_participation (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    event_id UUID REFERENCES butterfly_events(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    butterflies_discovered INTEGER DEFAULT 0,
    points_earned INTEGER DEFAULT 0,
    rewards_claimed JSONB DEFAULT '[]',
    completion_status TEXT DEFAULT 'active' CHECK (completion_status IN ('active', 'completed', 'missed')),
    UNIQUE(user_id, event_id)
);

-- Butterfly quests and challenges
CREATE TABLE IF NOT EXISTS butterfly_quests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    quest_name TEXT NOT NULL,
    quest_type TEXT NOT NULL CHECK (quest_type IN (
        'discovery',
        'collection',
        'rarity_hunt',
        'habitat_exploration',
        'daily_challenge',
        'weekly_challenge',
        'achievement'
    )),
    description TEXT NOT NULL,
    requirements JSONB NOT NULL, -- What needs to be accomplished
    rewards JSONB NOT NULL, -- Quest rewards
    difficulty TEXT DEFAULT 'easy' CHECK (difficulty IN ('easy', 'medium', 'hard', 'expert')),
    duration_hours INTEGER, -- NULL for permanent quests
    is_active BOOLEAN DEFAULT true,
    repeatable BOOLEAN DEFAULT false,
    prerequisite_quest_ids UUID[], -- Required completed quests
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- User quest progress and completion
CREATE TABLE IF NOT EXISTS butterfly_quest_progress (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    quest_id UUID REFERENCES butterfly_quests(id) ON DELETE CASCADE,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    progress JSONB DEFAULT '{}', -- Current progress data
    completed_at TIMESTAMP WITH TIME ZONE,
    rewards_claimed BOOLEAN DEFAULT false,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'failed', 'abandoned')),
    UNIQUE(user_id, quest_id)
);

-- Butterfly habitats with special properties
CREATE TABLE IF NOT EXISTS butterfly_habitats (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    habitat_name TEXT UNIQUE NOT NULL,
    description TEXT,
    unlock_requirements JSONB DEFAULT '{}', -- Requirements to unlock this habitat
    special_butterflies TEXT[], -- Butterfly IDs that prefer this habitat
    discovery_bonus DECIMAL(3,2) DEFAULT 1.00, -- Multiplier for discovery chance
    ambiance_music TEXT, -- Background music for this habitat
    background_image TEXT, -- Background image
    weather_effects TEXT[], -- Possible weather in this habitat
    time_preferences TEXT[], -- Best times for discoveries
    is_unlocked_by_default BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0
);

-- User unlocked habitats
CREATE TABLE IF NOT EXISTS butterfly_user_habitats (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    habitat_id UUID REFERENCES butterfly_habitats(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    visit_count INTEGER DEFAULT 0,
    last_visit TIMESTAMP WITH TIME ZONE,
    discoveries_made INTEGER DEFAULT 0,
    UNIQUE(user_id, habitat_id)
);

-- Seasonal butterfly appearances
CREATE TABLE IF NOT EXISTS butterfly_seasonal_config (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    butterfly_id TEXT REFERENCES butterfly_species(id) ON DELETE CASCADE,
    season TEXT NOT NULL CHECK (season IN ('spring', 'summer', 'autumn', 'winter')),
    availability_start DATE, -- When in season this butterfly appears
    availability_end DATE, -- When in season this butterfly disappears
    seasonal_bonus DECIMAL(3,2) DEFAULT 1.00, -- Discovery multiplier during season
    special_behavior JSONB DEFAULT '{}', -- Special behaviors during this season
    UNIQUE(butterfly_id, season)
);

-- Weather effects on butterfly discovery
CREATE TABLE IF NOT EXISTS butterfly_weather_effects (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    weather_type TEXT NOT NULL, -- 'sunny', 'cloudy', 'rainy', 'stormy', 'snowy', etc.
    affected_rarities TEXT[], -- Which rarities are affected
    discovery_modifier DECIMAL(3,2) DEFAULT 1.00, -- Multiplier for discovery chance
    special_butterflies TEXT[], -- Butterflies that appear only in this weather
    description TEXT
);

-- Butterfly trading system (if desired)
CREATE TABLE IF NOT EXISTS butterfly_trades (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    trader_user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    recipient_user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    offered_butterfly_id TEXT REFERENCES butterfly_species(id),
    requested_butterfly_id TEXT REFERENCES butterfly_species(id),
    trade_type TEXT DEFAULT 'butterfly_for_butterfly' CHECK (trade_type IN (
        'butterfly_for_butterfly',
        'butterfly_for_coins',
        'butterfly_for_gems',
        'gift'
    )),
    coin_amount INTEGER DEFAULT 0,
    gem_amount INTEGER DEFAULT 0,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'expired')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Butterfly collection themes and categories
CREATE TABLE IF NOT EXISTS butterfly_collection_themes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    theme_name TEXT UNIQUE NOT NULL,
    description TEXT,
    butterfly_ids TEXT[] NOT NULL, -- List of butterfly IDs in this theme
    unlock_reward JSONB DEFAULT '{}', -- Reward for completing this theme
    theme_color TEXT DEFAULT '#3B82F6',
    theme_icon TEXT DEFAULT 'collection',
    difficulty TEXT DEFAULT 'medium' CHECK (difficulty IN ('easy', 'medium', 'hard', 'expert')),
    is_active BOOLEAN DEFAULT true
);

-- User progress on collection themes
CREATE TABLE IF NOT EXISTS butterfly_user_themes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    theme_id UUID REFERENCES butterfly_collection_themes(id) ON DELETE CASCADE,
    progress INTEGER DEFAULT 0, -- Number of butterflies collected in this theme
    completed_at TIMESTAMP WITH TIME ZONE,
    reward_claimed BOOLEAN DEFAULT false,
    UNIQUE(user_id, theme_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_butterfly_events_active ON butterfly_events(is_active, start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_butterfly_event_participation_user ON butterfly_event_participation(user_id);
CREATE INDEX IF NOT EXISTS idx_butterfly_quests_active ON butterfly_quests(is_active, quest_type);
CREATE INDEX IF NOT EXISTS idx_butterfly_quest_progress_user ON butterfly_quest_progress(user_id, status);
CREATE INDEX IF NOT EXISTS idx_butterfly_habitats_default ON butterfly_habitats(is_unlocked_by_default);
CREATE INDEX IF NOT EXISTS idx_butterfly_user_habitats_user ON butterfly_user_habitats(user_id);
CREATE INDEX IF NOT EXISTS idx_butterfly_seasonal_config_season ON butterfly_seasonal_config(season);
CREATE INDEX IF NOT EXISTS idx_butterfly_trades_status ON butterfly_trades(status, created_at);

-- Enable RLS
ALTER TABLE butterfly_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE butterfly_event_species ENABLE ROW LEVEL SECURITY;
ALTER TABLE butterfly_event_participation ENABLE ROW LEVEL SECURITY;
ALTER TABLE butterfly_quests ENABLE ROW LEVEL SECURITY;
ALTER TABLE butterfly_quest_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE butterfly_habitats ENABLE ROW LEVEL SECURITY;
ALTER TABLE butterfly_user_habitats ENABLE ROW LEVEL SECURITY;
ALTER TABLE butterfly_seasonal_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE butterfly_weather_effects ENABLE ROW LEVEL SECURITY;
ALTER TABLE butterfly_trades ENABLE ROW LEVEL SECURITY;
ALTER TABLE butterfly_collection_themes ENABLE ROW LEVEL SECURITY;
ALTER TABLE butterfly_user_themes ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Drop existing policies if they exist to prevent conflicts
DROP POLICY IF EXISTS "Anyone can view active butterfly events" ON butterfly_events;
DROP POLICY IF EXISTS "Anyone can view event species" ON butterfly_event_species;
DROP POLICY IF EXISTS "Users can view own event participation" ON butterfly_event_participation;
DROP POLICY IF EXISTS "Users can join events" ON butterfly_event_participation;
DROP POLICY IF EXISTS "Users can update own event participation" ON butterfly_event_participation;
DROP POLICY IF EXISTS "Anyone can view active quests" ON butterfly_quests;
DROP POLICY IF EXISTS "Users can view own quest progress" ON butterfly_quest_progress;
DROP POLICY IF EXISTS "Users can manage own quest progress" ON butterfly_quest_progress;
DROP POLICY IF EXISTS "Anyone can view butterfly habitats" ON butterfly_habitats;
DROP POLICY IF EXISTS "Users can view own unlocked habitats" ON butterfly_user_habitats;
DROP POLICY IF EXISTS "Users can unlock habitats" ON butterfly_user_habitats;
DROP POLICY IF EXISTS "Users can update own habitat data" ON butterfly_user_habitats;
DROP POLICY IF EXISTS "Anyone can view seasonal config" ON butterfly_seasonal_config;
DROP POLICY IF EXISTS "Anyone can view weather effects" ON butterfly_weather_effects;
DROP POLICY IF EXISTS "Users can view relevant trades" ON butterfly_trades;
DROP POLICY IF EXISTS "Users can create trades" ON butterfly_trades;
DROP POLICY IF EXISTS "Users can respond to trades" ON butterfly_trades;
DROP POLICY IF EXISTS "Anyone can view collection themes" ON butterfly_collection_themes;
DROP POLICY IF EXISTS "Users can view own theme progress" ON butterfly_user_themes;
DROP POLICY IF EXISTS "Users can track theme progress" ON butterfly_user_themes;

-- Events are public readable
CREATE POLICY "Anyone can view active butterfly events" ON butterfly_events
    FOR SELECT USING (is_active = true AND start_date <= NOW() AND end_date >= NOW());

CREATE POLICY "Anyone can view event species" ON butterfly_event_species
    FOR SELECT USING (true);

-- Event participation - users can only see their own
CREATE POLICY "Users can view own event participation" ON butterfly_event_participation
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can join events" ON butterfly_event_participation
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own event participation" ON butterfly_event_participation
    FOR UPDATE USING (user_id = auth.uid());

-- Quests are public readable
CREATE POLICY "Anyone can view active quests" ON butterfly_quests
    FOR SELECT USING (is_active = true);

-- Quest progress - users can only see their own
CREATE POLICY "Users can view own quest progress" ON butterfly_quest_progress
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can manage own quest progress" ON butterfly_quest_progress
    FOR ALL USING (user_id = auth.uid());

-- Habitats are public readable
CREATE POLICY "Anyone can view butterfly habitats" ON butterfly_habitats
    FOR SELECT USING (true);

-- User habitats - users can only see their own
CREATE POLICY "Users can view own unlocked habitats" ON butterfly_user_habitats
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can unlock habitats" ON butterfly_user_habitats
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own habitat data" ON butterfly_user_habitats
    FOR UPDATE USING (user_id = auth.uid());

-- Seasonal and weather configs are public readable
CREATE POLICY "Anyone can view seasonal config" ON butterfly_seasonal_config
    FOR SELECT USING (true);

CREATE POLICY "Anyone can view weather effects" ON butterfly_weather_effects
    FOR SELECT USING (true);

-- Trading - users can see trades involving them
CREATE POLICY "Users can view relevant trades" ON butterfly_trades
    FOR SELECT USING (trader_user_id = auth.uid() OR recipient_user_id = auth.uid());

CREATE POLICY "Users can create trades" ON butterfly_trades
    FOR INSERT WITH CHECK (trader_user_id = auth.uid());

CREATE POLICY "Users can respond to trades" ON butterfly_trades
    FOR UPDATE USING (recipient_user_id = auth.uid() OR trader_user_id = auth.uid());

-- Collection themes are public readable
CREATE POLICY "Anyone can view collection themes" ON butterfly_collection_themes
    FOR SELECT USING (is_active = true);

-- User theme progress - users can only see their own
CREATE POLICY "Users can view own theme progress" ON butterfly_user_themes
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can track theme progress" ON butterfly_user_themes
    FOR ALL USING (user_id = auth.uid());

-- Functions

-- Drop existing functions and triggers if they exist to prevent conflicts
DROP FUNCTION IF EXISTS is_butterfly_event_active(UUID) CASCADE;
DROP FUNCTION IF EXISTS get_seasonal_discovery_modifiers() CASCADE;
DROP FUNCTION IF EXISTS update_butterfly_theme_progress() CASCADE;
DROP TRIGGER IF EXISTS update_theme_progress_on_discovery ON butterfly_album;

-- Check if butterfly event is currently active
CREATE OR REPLACE FUNCTION is_butterfly_event_active(event_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    event_record RECORD;
BEGIN
    SELECT is_active, start_date, end_date
    INTO event_record
    FROM butterfly_events
    WHERE id = event_id;
    
    IF NOT FOUND THEN
        RETURN false;
    END IF;
    
    RETURN event_record.is_active 
        AND event_record.start_date <= NOW() 
        AND event_record.end_date >= NOW();
END;
$$ LANGUAGE plpgsql;

-- Get current seasonal modifiers for butterfly discovery
CREATE OR REPLACE FUNCTION get_seasonal_discovery_modifiers()
RETURNS TABLE(butterfly_id TEXT, seasonal_bonus DECIMAL) AS $$
DECLARE
    current_season TEXT;
    current_date DATE := CURRENT_DATE;
BEGIN
    -- Determine current season (simple Northern Hemisphere logic)
    current_season := CASE 
        WHEN EXTRACT(MONTH FROM current_date) IN (3, 4, 5) THEN 'spring'
        WHEN EXTRACT(MONTH FROM current_date) IN (6, 7, 8) THEN 'summer'
        WHEN EXTRACT(MONTH FROM current_date) IN (9, 10, 11) THEN 'autumn'
        ELSE 'winter'
    END;
    
    RETURN QUERY
    SELECT bsc.butterfly_id, bsc.seasonal_bonus
    FROM butterfly_seasonal_config bsc
    WHERE bsc.season = current_season
    AND (bsc.availability_start IS NULL OR current_date >= bsc.availability_start)
    AND (bsc.availability_end IS NULL OR current_date <= bsc.availability_end);
END;
$$ LANGUAGE plpgsql;

-- Update user theme progress when butterfly is discovered
CREATE OR REPLACE FUNCTION update_butterfly_theme_progress()
RETURNS TRIGGER AS $$
DECLARE
    theme_record RECORD;
BEGIN
    -- Update progress for all themes that include this butterfly
    FOR theme_record IN
        SELECT bct.id, bct.butterfly_ids
        FROM butterfly_collection_themes bct
        WHERE NEW.butterfly_id = ANY(bct.butterfly_ids)
        AND bct.is_active = true
    LOOP
        -- Insert or update theme progress
        INSERT INTO butterfly_user_themes (user_id, theme_id, progress)
        VALUES (NEW.user_id, theme_record.id, 1)
        ON CONFLICT (user_id, theme_id) DO UPDATE SET
            progress = butterfly_user_themes.progress + 1,
            completed_at = CASE 
                WHEN butterfly_user_themes.progress + 1 >= array_length(theme_record.butterfly_ids, 1)
                THEN NOW()
                ELSE butterfly_user_themes.completed_at
            END;
    END LOOP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for theme progress updates
CREATE TRIGGER update_theme_progress_on_discovery
    AFTER INSERT ON butterfly_album
    FOR EACH ROW
    EXECUTE FUNCTION update_butterfly_theme_progress();

-- Insert default butterfly habitats
INSERT INTO butterfly_habitats (habitat_name, description, special_butterflies, discovery_bonus, sort_order) VALUES
('Crystal Garden', 'A magical garden where crystal butterflies flourish', '{"b10", "b18", "b26"}', 1.20, 1),
('Moonlit Meadow', 'A serene meadow bathed in moonlight', '{"b5", "b24", "b37"}', 1.15, 2),
('Sunrise Field', 'A vibrant field that comes alive at dawn', '{"b2", "b8", "b35"}', 1.10, 3),
('Enchanted Forest', 'An ancient forest full of mysteries', '{"b13", "b30", "b41"}', 1.25, 4),
('Cosmic Observatory', 'A place where stellar butterflies gather', '{"b20", "b43", "b59", "b86"}', 2.00, 5)
ON CONFLICT (habitat_name) DO NOTHING;

-- Insert default collection themes
INSERT INTO butterfly_collection_themes (theme_name, description, butterfly_ids, difficulty) VALUES
('Rainbow Collection', 'Collect butterflies of every color of the rainbow', '{"b1", "b2", "b3", "b6", "b7", "b8", "b16"}', 'easy'),
('Legendary Masters', 'Collect all legendary butterflies', '{"b10", "b17", "b31", "b37", "b49", "b55", "b63", "b69", "b76", "b82", "b89"}', 'expert'),
('Mythical Beings', 'Collect all mythical butterflies', '{"b20", "b43", "b59", "b73", "b86"}', 'expert'),
('Seasonal Wonders', 'Collect butterflies from each season', '{"b3", "b6", "b12", "b28"}', 'medium'),
('Gemstone Collection', 'Collect butterflies named after precious gems', '{"b10", "b17", "b18", "b19", "b55", "b63"}', 'hard')
ON CONFLICT (theme_name) DO NOTHING;

-- Insert sample butterfly events
INSERT INTO butterfly_events (event_name, event_type, description, start_date, end_date, event_config) VALUES
('Spring Awakening', 'seasonal', 'Celebrate the arrival of spring with increased butterfly discoveries!', 
 '2024-03-20 00:00:00+00', '2024-04-20 23:59:59+00',
 '{"discovery_bonus": 1.5, "special_rewards": true}'),
('Mythical Migration', 'special_release', 'Rare mythical butterflies have been spotted! Limited time event.',
 '2024-12-01 00:00:00+00', '2024-12-31 23:59:59+00',
 '{"mythical_bonus": 2.0, "exclusive_butterflies": ["b20", "b43"]}')
ON CONFLICT DO NOTHING;
