-- =====================================================
-- CRYSTAL SOCIAL - GARDEN SYSTEM SECURITY POLICIES
-- =====================================================
-- Row Level Security policies for garden system
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

-- =====================================================
-- GARDENS TABLE POLICIES
-- =====================================================

-- Users can view their own gardens
CREATE POLICY "Users can view own gardens" ON gardens
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own gardens
CREATE POLICY "Users can create own gardens" ON gardens
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own gardens
CREATE POLICY "Users can update own gardens" ON gardens
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own gardens
CREATE POLICY "Users can delete own gardens" ON gardens
    FOR DELETE
    USING (auth.uid() = user_id);

-- =====================================================
-- FLOWERS TABLE POLICIES
-- =====================================================

-- Users can view flowers in their gardens
CREATE POLICY "Users can view flowers in own gardens" ON flowers
    FOR SELECT
    USING (
        garden_id IN (
            SELECT id FROM gardens WHERE user_id = auth.uid()
        )
    );

-- Users can plant flowers in their gardens
CREATE POLICY "Users can plant flowers in own gardens" ON flowers
    FOR INSERT
    WITH CHECK (
        garden_id IN (
            SELECT id FROM gardens WHERE user_id = auth.uid()
        )
    );

-- Users can update flowers in their gardens
CREATE POLICY "Users can update flowers in own gardens" ON flowers
    FOR UPDATE
    USING (
        garden_id IN (
            SELECT id FROM gardens WHERE user_id = auth.uid()
        )
    )
    WITH CHECK (
        garden_id IN (
            SELECT id FROM gardens WHERE user_id = auth.uid()
        )
    );

-- Users can remove flowers from their gardens
CREATE POLICY "Users can remove flowers from own gardens" ON flowers
    FOR DELETE
    USING (
        garden_id IN (
            SELECT id FROM gardens WHERE user_id = auth.uid()
        )
    );

-- =====================================================
-- FLOWER SPECIES TABLE POLICIES
-- =====================================================

-- Everyone can read flower species (reference data)
CREATE POLICY "Everyone can view flower species" ON flower_species
    FOR SELECT
    USING (true);

-- Only admins can manage flower species
CREATE POLICY "Only admins can manage flower species" ON flower_species
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND username IN ('admin', 'moderator')
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND username IN ('admin', 'moderator')
        )
    );

-- =====================================================
-- GARDEN INVENTORY TABLE POLICIES
-- =====================================================

-- Users can view inventory in their gardens
CREATE POLICY "Users can view inventory in own gardens" ON garden_inventory
    FOR SELECT
    USING (
        garden_id IN (
            SELECT id FROM gardens WHERE user_id = auth.uid()
        )
    );

-- Users can manage inventory in their gardens
CREATE POLICY "Users can manage inventory in own gardens" ON garden_inventory
    FOR ALL
    USING (
        garden_id IN (
            SELECT id FROM gardens WHERE user_id = auth.uid()
        )
    )
    WITH CHECK (
        garden_id IN (
            SELECT id FROM gardens WHERE user_id = auth.uid()
        )
    );

-- =====================================================
-- GARDEN VISITORS TABLE POLICIES
-- =====================================================

-- Everyone can read visitor types (reference data)
CREATE POLICY "Everyone can view visitor types" ON garden_visitors
    FOR SELECT
    USING (true);

-- Only admins can manage visitor types
CREATE POLICY "Only admins can manage visitor types" ON garden_visitors
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND username IN ('admin', 'moderator')
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND username IN ('admin', 'moderator')
        )
    );

-- =====================================================
-- GARDEN VISITOR INSTANCES TABLE POLICIES
-- =====================================================

-- Users can view visitors in their gardens
CREATE POLICY "Users can view visitors in own gardens" ON garden_visitor_instances
    FOR SELECT
    USING (
        garden_id IN (
            SELECT id FROM gardens WHERE user_id = auth.uid()
        )
    );

-- System can create visitor instances
CREATE POLICY "System can create visitor instances" ON garden_visitor_instances
    FOR INSERT
    WITH CHECK (true); -- This should be called by system functions only

-- Users can interact with visitors in their gardens
CREATE POLICY "Users can interact with visitors in own gardens" ON garden_visitor_instances
    FOR UPDATE
    USING (
        garden_id IN (
            SELECT id FROM gardens WHERE user_id = auth.uid()
        )
    )
    WITH CHECK (
        garden_id IN (
            SELECT id FROM gardens WHERE user_id = auth.uid()
        )
    );

-- =====================================================
-- GARDEN WEATHER EVENTS TABLE POLICIES
-- =====================================================

-- Users can view weather in their gardens
CREATE POLICY "Users can view weather in own gardens" ON garden_weather_events
    FOR SELECT
    USING (
        garden_id IN (
            SELECT id FROM gardens WHERE user_id = auth.uid()
        )
    );

-- System can create weather events
CREATE POLICY "System can create weather events" ON garden_weather_events
    FOR INSERT
    WITH CHECK (true); -- This should be called by system functions only

-- System can update weather events
CREATE POLICY "System can update weather events" ON garden_weather_events
    FOR UPDATE
    USING (true)
    WITH CHECK (true);

-- =====================================================
-- GARDEN ACHIEVEMENTS TABLE POLICIES
-- =====================================================

-- Users can view achievements in their gardens
CREATE POLICY "Users can view achievements in own gardens" ON garden_achievements
    FOR SELECT
    USING (
        garden_id IN (
            SELECT id FROM gardens WHERE user_id = auth.uid()
        )
    );

-- System can manage achievements
CREATE POLICY "System can manage achievements" ON garden_achievements
    FOR ALL
    USING (true) -- This should be called by system functions only
    WITH CHECK (true);

-- =====================================================
-- GARDEN SHOP ITEMS TABLE POLICIES
-- =====================================================

-- Everyone can view available shop items
CREATE POLICY "Everyone can view shop items" ON garden_shop_items
    FOR SELECT
    USING (is_available = true);

-- Only admins can manage shop items
CREATE POLICY "Only admins can manage shop items" ON garden_shop_items
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND username IN ('admin', 'moderator')
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND username IN ('admin', 'moderator')
        )
    );

-- =====================================================
-- GARDEN PURCHASES TABLE POLICIES
-- =====================================================

-- Users can view their own purchases
CREATE POLICY "Users can view own purchases" ON garden_purchases
    FOR SELECT
    USING (
        garden_id IN (
            SELECT id FROM gardens WHERE user_id = auth.uid()
        )
    );

-- System can create purchase records
CREATE POLICY "System can create purchases" ON garden_purchases
    FOR INSERT
    WITH CHECK (
        garden_id IN (
            SELECT id FROM gardens WHERE user_id = auth.uid()
        )
    );

-- =====================================================
-- GARDEN DAILY QUESTS TABLE POLICIES
-- =====================================================

-- Users can view quests in their gardens
CREATE POLICY "Users can view quests in own gardens" ON garden_daily_quests
    FOR SELECT
    USING (
        garden_id IN (
            SELECT id FROM gardens WHERE user_id = auth.uid()
        )
    );

-- System can manage quests
CREATE POLICY "System can manage quests" ON garden_daily_quests
    FOR ALL
    USING (true) -- This should be called by system functions only
    WITH CHECK (true);

-- =====================================================
-- GARDEN ANALYTICS TABLE POLICIES
-- =====================================================

-- Users can view analytics for their gardens
CREATE POLICY "Users can view analytics for own gardens" ON garden_analytics
    FOR SELECT
    USING (
        garden_id IN (
            SELECT id FROM gardens WHERE user_id = auth.uid()
        )
    );

-- System can manage analytics
CREATE POLICY "System can manage analytics" ON garden_analytics
    FOR ALL
    USING (true) -- This should be called by system functions only
    WITH CHECK (true);

-- Admins can view all analytics
CREATE POLICY "Admins can view all analytics" ON garden_analytics
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND username IN ('admin', 'moderator')
        )
    );

-- =====================================================
-- GARDEN QUEST PROGRESS TABLE POLICIES
-- =====================================================

-- Users can view quest progress for their gardens
CREATE POLICY "Users can view quest progress for own gardens" ON garden_quest_progress
    FOR SELECT
    USING (
        garden_id IN (
            SELECT id FROM gardens WHERE user_id = auth.uid()
        )
    );

-- System can manage quest progress
CREATE POLICY "System can manage quest progress" ON garden_quest_progress
    FOR ALL
    USING (true) -- This should be called by system functions only
    WITH CHECK (true);

-- =====================================================
-- GARDEN SHARES TABLE POLICIES
-- =====================================================

-- Users can view shares for their gardens
CREATE POLICY "Users can view shares for own gardens" ON garden_shares
    FOR SELECT
    USING (
        garden_id IN (
            SELECT id FROM gardens WHERE user_id = auth.uid()
        )
    );

-- Users can create shares for their gardens
CREATE POLICY "Users can create shares for own gardens" ON garden_shares
    FOR INSERT
    WITH CHECK (
        garden_id IN (
            SELECT id FROM gardens WHERE user_id = auth.uid()
        )
    );

-- Users can update their own shares
CREATE POLICY "Users can update own shares" ON garden_shares
    FOR UPDATE
    USING (
        garden_id IN (
            SELECT id FROM gardens WHERE user_id = auth.uid()
        )
    )
    WITH CHECK (
        garden_id IN (
            SELECT id FROM gardens WHERE user_id = auth.uid()
        )
    );

-- =====================================================
-- HELPER FUNCTIONS FOR SECURITY
-- =====================================================

-- Function to check if user is garden owner
CREATE OR REPLACE FUNCTION is_garden_owner(p_garden_id UUID, p_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1 FROM gardens 
        WHERE id = p_garden_id AND user_id = p_user_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin(p_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1 FROM user_profiles 
        WHERE id = p_user_id AND username IN ('admin', 'moderator')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- GRANTS AND PERMISSIONS
-- =====================================================

-- Grant usage on sequences
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO anon;

-- Grant execute permissions on functions
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

-- Grant execute permissions on helper functions
GRANT EXECUTE ON FUNCTION is_garden_owner TO authenticated;
GRANT EXECUTE ON FUNCTION is_admin TO authenticated;

-- Revoke all permissions from anon users on sensitive tables
REVOKE ALL ON garden_purchases FROM anon;
REVOKE ALL ON garden_analytics FROM anon;

-- Grant select permissions for reference tables to anon users
GRANT SELECT ON flower_species TO anon;
GRANT SELECT ON garden_visitors TO anon;
GRANT SELECT ON garden_shop_items TO anon;
