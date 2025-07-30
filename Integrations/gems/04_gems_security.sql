-- =====================================================
-- CRYSTAL SOCIAL - GEMS SYSTEM SECURITY POLICIES
-- =====================================================
-- Row Level Security policies for gem system
-- =====================================================

-- Enable RLS on all gem tables
ALTER TABLE enhanced_gemstones ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_gemstones ENABLE ROW LEVEL SECURITY;
ALTER TABLE gem_discovery_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE gem_collection_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE gem_enhancements ENABLE ROW LEVEL SECURITY;
ALTER TABLE gem_trades ENABLE ROW LEVEL SECURITY;
ALTER TABLE gem_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE gem_daily_quests ENABLE ROW LEVEL SECURITY;
ALTER TABLE gem_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE gem_wishlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE gem_social_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE gem_discovery_methods ENABLE ROW LEVEL SECURITY;

-- Enable RLS on new tables if they exist
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_gem_stats') THEN
        ALTER TABLE user_gem_stats ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'gem_unlock_analytics') THEN
        ALTER TABLE gem_unlock_analytics ENABLE ROW LEVEL SECURITY;
    END IF;
END $$;

-- =====================================================
-- ENHANCED GEMSTONES TABLE POLICIES
-- =====================================================

-- Everyone can view active gemstones (reference data)
CREATE POLICY "Everyone can view active gemstones" ON enhanced_gemstones
    FOR SELECT
    USING (is_active = true);

-- Only admins can manage gemstones
CREATE POLICY "Only admins can manage gemstones" ON enhanced_gemstones
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
-- USER GEMSTONES TABLE POLICIES
-- =====================================================

-- Users can view their own gemstones
CREATE POLICY "Users can view own gemstones" ON user_gemstones
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can add gemstones to their collection
CREATE POLICY "Users can add own gemstones" ON user_gemstones
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own gemstones
CREATE POLICY "Users can update own gemstones" ON user_gemstones
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can remove their own gemstones (for trading)
CREATE POLICY "Users can remove own gemstones" ON user_gemstones
    FOR DELETE
    USING (auth.uid() = user_id);

-- Public read access for shared collections
CREATE POLICY "Public can view shared gemstones" ON user_gemstones
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM gem_social_shares gss
            WHERE gss.user_id = user_gemstones.user_id
            AND gss.is_public = true
            AND gss.share_type = 'collection'
        )
    );

-- =====================================================
-- GEM DISCOVERY EVENTS TABLE POLICIES
-- =====================================================

-- Users can view their own discovery events
CREATE POLICY "Users can view own discovery events" ON gem_discovery_events
    FOR SELECT
    USING (auth.uid() = user_id);

-- System can create discovery events
CREATE POLICY "System can create discovery events" ON gem_discovery_events
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Admins can view all discovery events for analytics
CREATE POLICY "Admins can view all discovery events" ON gem_discovery_events
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND username IN ('admin', 'moderator')
        )
    );

-- =====================================================
-- GEM COLLECTION STATS TABLE POLICIES
-- =====================================================

-- Users can view their own collection stats
CREATE POLICY "Users can view own collection stats" ON gem_collection_stats
    FOR SELECT
    USING (auth.uid() = user_id);

-- System can manage collection stats
CREATE POLICY "System can manage collection stats" ON gem_collection_stats
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Public read access for leaderboards
CREATE POLICY "Public can view collection stats for leaderboards" ON gem_collection_stats
    FOR SELECT
    USING (true); -- Simplified - allow public leaderboard access

-- =====================================================
-- GEM ENHANCEMENTS TABLE POLICIES
-- =====================================================

-- Users can view enhancements for their gems
CREATE POLICY "Users can view own gem enhancements" ON gem_enhancements
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM user_gemstones ug
            WHERE ug.id = gem_enhancements.user_gem_id
            AND ug.user_id = auth.uid()
        )
    );

-- Users can create enhancements for their gems
CREATE POLICY "Users can create gem enhancements" ON gem_enhancements
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_gemstones ug
            WHERE ug.id = gem_enhancements.user_gem_id
            AND ug.user_id = auth.uid()
        )
    );

-- =====================================================
-- GEM TRADES TABLE POLICIES
-- =====================================================

-- Users can view trades they're involved in
CREATE POLICY "Users can view own trades" ON gem_trades
    FOR SELECT
    USING (
        auth.uid() = seller_id OR 
        auth.uid() = buyer_id OR
        status = 'active' -- Anyone can see active trade listings
    );

-- Users can create trade offers for their gems
CREATE POLICY "Users can create trade offers" ON gem_trades
    FOR INSERT
    WITH CHECK (auth.uid() = seller_id);

-- Users can update their own trades
CREATE POLICY "Users can update own trades" ON gem_trades
    FOR UPDATE
    USING (auth.uid() = seller_id OR auth.uid() = buyer_id)
    WITH CHECK (auth.uid() = seller_id OR auth.uid() = buyer_id);

-- Users can cancel their own trade offers
CREATE POLICY "Users can cancel own trades" ON gem_trades
    FOR DELETE
    USING (auth.uid() = seller_id);

-- =====================================================
-- GEM ACHIEVEMENTS TABLE POLICIES
-- =====================================================

-- Users can view their own achievements
CREATE POLICY "Users can view own gem achievements" ON gem_achievements
    FOR SELECT
    USING (auth.uid() = user_id);

-- System can manage achievements
CREATE POLICY "System can manage gem achievements" ON gem_achievements
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Public read access for showcasing achievements
CREATE POLICY "Public can view showcased achievements" ON gem_achievements
    FOR SELECT
    USING (is_completed = true); -- Simplified - allow public achievement viewing

-- =====================================================
-- GEM DAILY QUESTS TABLE POLICIES
-- =====================================================

-- Users can view their own daily quests
CREATE POLICY "Users can view own gem daily quests" ON gem_daily_quests
    FOR SELECT
    USING (auth.uid() = user_id);

-- System can manage daily quests
CREATE POLICY "System can manage gem daily quests" ON gem_daily_quests
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- GEM ANALYTICS TABLE POLICIES
-- =====================================================

-- Users can view their own analytics
CREATE POLICY "Users can view own gem analytics" ON gem_analytics
    FOR SELECT
    USING (auth.uid() = user_id);

-- System can manage analytics
CREATE POLICY "System can manage gem analytics" ON gem_analytics
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Admins can view all analytics for insights
CREATE POLICY "Admins can view all gem analytics" ON gem_analytics
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND username IN ('admin', 'moderator')
        )
    );

-- =====================================================
-- GEM WISHLISTS TABLE POLICIES
-- =====================================================

-- Users can view their own wishlists
CREATE POLICY "Users can view own gem wishlists" ON gem_wishlists
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can manage their own wishlists
CREATE POLICY "Users can manage own gem wishlists" ON gem_wishlists
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Public read access for shared wishlists
CREATE POLICY "Public can view shared gem wishlists" ON gem_wishlists
    FOR SELECT
    USING (true); -- Simplified - allow public wishlist viewing

-- =====================================================
-- GEM SOCIAL SHARES TABLE POLICIES
-- =====================================================

-- Users can view their own shares
CREATE POLICY "Users can view own gem shares" ON gem_social_shares
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can create their own shares
CREATE POLICY "Users can create gem shares" ON gem_social_shares
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own shares
CREATE POLICY "Users can update own gem shares" ON gem_social_shares
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own shares
CREATE POLICY "Users can delete own gem shares" ON gem_social_shares
    FOR DELETE
    USING (auth.uid() = user_id);

-- Everyone can view public shares
CREATE POLICY "Everyone can view public gem shares" ON gem_social_shares
    FOR SELECT
    USING (is_public = true);

-- =====================================================
-- GEM DISCOVERY METHODS TABLE POLICIES
-- =====================================================

-- Everyone can view active discovery methods
CREATE POLICY "Everyone can view discovery methods" ON gem_discovery_methods
    FOR SELECT
    USING (is_active = true);

-- Only admins can manage discovery methods
CREATE POLICY "Only admins can manage discovery methods" ON gem_discovery_methods
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
-- USER GEM STATS TABLE POLICIES
-- =====================================================

-- Create policies for user_gem_stats if table exists
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_gem_stats') THEN
        -- Users can view their own gem stats
        EXECUTE 'CREATE POLICY "Users can view own gem stats" ON user_gem_stats
            FOR SELECT
            USING (auth.uid() = user_id)';

        -- System can manage gem stats
        EXECUTE 'CREATE POLICY "System can manage gem stats" ON user_gem_stats
            FOR ALL
            USING (auth.uid() = user_id)
            WITH CHECK (auth.uid() = user_id)';

        -- Public read access for leaderboards
        EXECUTE 'CREATE POLICY "Public can view gem stats for leaderboards" ON user_gem_stats
            FOR SELECT
            USING (true)'; -- Simplified - allow public leaderboard access
    END IF;
END $$;

-- =====================================================
-- GEM UNLOCK ANALYTICS TABLE POLICIES
-- =====================================================

-- Create policies for gem_unlock_analytics if table exists
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'gem_unlock_analytics') THEN
        -- Users can view their own unlock analytics
        EXECUTE 'CREATE POLICY "Users can view own unlock analytics" ON gem_unlock_analytics
            FOR SELECT
            USING (auth.uid() = user_id)';

        -- System can create unlock analytics
        EXECUTE 'CREATE POLICY "System can create unlock analytics" ON gem_unlock_analytics
            FOR INSERT
            WITH CHECK (auth.uid() = user_id)';

        -- Admins can view all unlock analytics for insights
        EXECUTE 'CREATE POLICY "Admins can view all unlock analytics" ON gem_unlock_analytics
            FOR SELECT
            USING (
                EXISTS (
                    SELECT 1 FROM user_profiles 
                    WHERE id = auth.uid() 
                    AND username IN (''admin'', ''moderator'')
                )
            )';
    END IF;
END $$;

-- =====================================================
-- HELPER FUNCTIONS FOR SECURITY
-- =====================================================

-- Function to check if user owns a gem
CREATE OR REPLACE FUNCTION user_owns_gem(p_user_id UUID, p_gem_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1 FROM user_gemstones 
        WHERE user_id = p_user_id AND gem_id = p_gem_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is gem admin
CREATE OR REPLACE FUNCTION is_gem_admin(p_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1 FROM user_profiles 
        WHERE id = p_user_id AND username IN ('admin', 'moderator')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if gem collection is public
CREATE OR REPLACE FUNCTION is_gem_collection_public(p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- Simplified - assume all gem collections are public for now
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user can enhance gem
CREATE OR REPLACE FUNCTION can_enhance_gem(p_user_id UUID, p_user_gem_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1 FROM user_gemstones 
        WHERE id = p_user_gem_id 
        AND user_id = p_user_id
        AND enhancement_level < 10
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check trade permissions
CREATE OR REPLACE FUNCTION can_trade_gem(p_user_id UUID, p_gem_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_user_gem RECORD;
BEGIN
    SELECT * INTO v_user_gem
    FROM user_gemstones ug
    JOIN enhanced_gemstones eg ON ug.gem_id = eg.id
    WHERE ug.user_id = p_user_id AND ug.gem_id = p_gem_id;
    
    -- Check if user owns the gem and it's tradeable
    RETURN FOUND AND 
           v_user_gem.enhancement_level <= 5 AND -- Highly enhanced gems may be non-tradeable
           NOT (v_user_gem.special_effects ? 'untradeable');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- GRANTS AND PERMISSIONS
-- =====================================================

-- Grant usage on sequences
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO anon;

-- Grant execute permissions on gem functions
GRANT EXECUTE ON FUNCTION unlock_gem TO authenticated;
GRANT EXECUTE ON FUNCTION discover_random_gem TO authenticated;
GRANT EXECUTE ON FUNCTION enhance_gem TO authenticated;
GRANT EXECUTE ON FUNCTION update_gem_collection_stats TO authenticated;
GRANT EXECUTE ON FUNCTION check_gem_achievements TO authenticated;
GRANT EXECUTE ON FUNCTION toggle_gem_favorite TO authenticated;
GRANT EXECUTE ON FUNCTION get_gem_collection_overview TO authenticated;

-- Grant execute permissions on helper functions
GRANT EXECUTE ON FUNCTION user_owns_gem TO authenticated;
GRANT EXECUTE ON FUNCTION is_gem_admin TO authenticated;
GRANT EXECUTE ON FUNCTION is_gem_collection_public TO authenticated;
GRANT EXECUTE ON FUNCTION can_enhance_gem TO authenticated;
GRANT EXECUTE ON FUNCTION can_trade_gem TO authenticated;

-- Revoke all permissions from anon users on sensitive tables
REVOKE ALL ON user_gemstones FROM anon;
REVOKE ALL ON gem_discovery_events FROM anon;
REVOKE ALL ON gem_collection_stats FROM anon;
REVOKE ALL ON gem_enhancements FROM anon;
REVOKE ALL ON gem_trades FROM anon;
REVOKE ALL ON gem_achievements FROM anon;
REVOKE ALL ON gem_daily_quests FROM anon;
REVOKE ALL ON gem_analytics FROM anon;
REVOKE ALL ON gem_wishlists FROM anon;

-- Revoke permissions on new tables if they exist
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_gem_stats') THEN
        REVOKE ALL ON user_gem_stats FROM anon;
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'gem_unlock_analytics') THEN
        REVOKE ALL ON gem_unlock_analytics FROM anon;
    END IF;
END $$;

-- Grant select permissions for reference tables to anon users
GRANT SELECT ON enhanced_gemstones TO anon;
GRANT SELECT ON gem_discovery_methods TO anon;

-- Grant limited access to public shares for anon users
GRANT SELECT ON gem_social_shares TO anon;

-- =====================================================
-- ADDITIONAL SECURITY CONSTRAINTS
-- =====================================================

-- Ensure users can't create duplicate gem ownership
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_gemstones_unique_ownership 
ON user_gemstones(user_id, gem_id);

-- Ensure trade integrity
ALTER TABLE gem_trades ADD CONSTRAINT chk_trade_users 
CHECK (seller_id != buyer_id);

-- Ensure enhancement levels are reasonable
ALTER TABLE user_gemstones ADD CONSTRAINT chk_enhancement_level_range
CHECK (enhancement_level BETWEEN 0 AND 10);

-- Ensure power levels are reasonable
ALTER TABLE user_gemstones ADD CONSTRAINT chk_power_level_range
CHECK (power_level BETWEEN 1 AND 1000);

-- Ensure achievement progress is valid
ALTER TABLE gem_achievements ADD CONSTRAINT chk_achievement_progress
CHECK (progress_percentage BETWEEN 0 AND 100);

-- Ensure quest progress is valid
ALTER TABLE gem_daily_quests ADD CONSTRAINT chk_quest_progress
CHECK (progress_percentage BETWEEN 0 AND 100);

-- Ensure gem rarity weights are valid
ALTER TABLE gem_discovery_methods ADD CONSTRAINT chk_rarity_weights_format
CHECK (
    (rarity_weights ? 'common') AND
    (rarity_weights ? 'uncommon') AND
    (rarity_weights ? 'rare') AND
    (rarity_weights ? 'epic') AND
    (rarity_weights ? 'legendary')
);

-- Ensure sparkle intensity is reasonable
ALTER TABLE enhanced_gemstones ADD CONSTRAINT chk_sparkle_intensity_range
CHECK (sparkle_intensity BETWEEN 0.1 AND 5.0);

-- Ensure discovery weights are positive
ALTER TABLE enhanced_gemstones ADD CONSTRAINT chk_discovery_weight_positive
CHECK (discovery_weight > 0);

-- Create function to validate gem data integrity
CREATE OR REPLACE FUNCTION validate_gem_data_integrity()
RETURNS TABLE (
    table_name TEXT,
    issue_description TEXT,
    affected_count BIGINT
) AS $$
BEGIN
    -- Check for orphaned user gems
    RETURN QUERY
    SELECT 
        'user_gemstones'::TEXT,
        'Orphaned user gems (gem not in enhanced_gemstones)'::TEXT,
        COUNT(*)
    FROM user_gemstones ug
    LEFT JOIN enhanced_gemstones eg ON ug.gem_id = eg.id
    WHERE eg.id IS NULL;
    
    -- Check for invalid enhancement levels
    RETURN QUERY
    SELECT 
        'user_gemstones'::TEXT,
        'Invalid enhancement levels'::TEXT,
        COUNT(*)
    FROM user_gemstones
    WHERE enhancement_level < 0 OR enhancement_level > 10;
    
    -- Check for achievements with invalid progress
    RETURN QUERY
    SELECT 
        'gem_achievements'::TEXT,
        'Achievements with invalid progress percentage'::TEXT,
        COUNT(*)
    FROM gem_achievements
    WHERE progress_percentage < 0 OR progress_percentage > 100;
    
    -- Check for expired active trades
    RETURN QUERY
    SELECT 
        'gem_trades'::TEXT,
        'Expired trades still marked as active'::TEXT,
        COUNT(*)
    FROM gem_trades
    WHERE status = 'active' AND expires_at IS NOT NULL AND expires_at <= NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on validation function to admins
GRANT EXECUTE ON FUNCTION validate_gem_data_integrity TO authenticated;
