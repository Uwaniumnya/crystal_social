-- =====================================================
-- CRYSTAL SOCIAL - PETS SYSTEM SECURITY
-- =====================================================
-- Row Level Security policies for pets system
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE user_pets ENABLE ROW LEVEL SECURITY;
ALTER TABLE pet_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE pet_accessories ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_pet_accessories ENABLE ROW LEVEL SECURITY;
ALTER TABLE pet_foods ENABLE ROW LEVEL SECURITY;
ALTER TABLE pet_feeding_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE pet_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE pet_activity_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE pet_breeding ENABLE ROW LEVEL SECURITY;
ALTER TABLE pet_genetic_traits ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_pet_traits ENABLE ROW LEVEL SECURITY;
ALTER TABLE pet_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_pet_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE pet_friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE pet_playdates ENABLE ROW LEVEL SECURITY;
ALTER TABLE pet_playdate_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE pet_daily_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_pet_settings ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- USER PETS TABLE POLICIES
-- =====================================================

-- Users can view their own pets and pets in public contexts
CREATE POLICY "Users can view own pets" ON user_pets
    FOR SELECT USING (user_id = auth.uid());

-- Users can view other pets for social features (friendships, playdates)
CREATE POLICY "Users can view pets for social features" ON user_pets
    FOR SELECT USING (
        -- Pet is in a friendship with user's pet
        id IN (
            SELECT pet2_id FROM pet_friendships pf
            JOIN user_pets up ON pf.pet1_id = up.id
            WHERE up.user_id = auth.uid()
            UNION
            SELECT pet1_id FROM pet_friendships pf
            JOIN user_pets up ON pf.pet2_id = up.id
            WHERE up.user_id = auth.uid()
        ) OR
        -- Pet is in a playdate with user's pet
        id IN (
            SELECT ppd.pet_id FROM pet_playdate_participants ppd
            JOIN pet_playdates pd ON ppd.playdate_id = pd.id
            WHERE pd.is_public = true OR 
                  pd.organizer_user_id = auth.uid() OR
                  ppd.user_id = auth.uid()
        )
    );

-- Users can insert their own pets
CREATE POLICY "Users can create own pets" ON user_pets
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Users can update their own pets
CREATE POLICY "Users can update own pets" ON user_pets
    FOR UPDATE USING (user_id = auth.uid());

-- Users can delete their own pets
CREATE POLICY "Users can delete own pets" ON user_pets
    FOR DELETE USING (user_id = auth.uid());

-- =====================================================
-- PET TEMPLATES TABLE POLICIES
-- =====================================================

-- Everyone can view available pet templates
CREATE POLICY "Anyone can view pet templates" ON pet_templates
    FOR SELECT USING (true);

-- Only system/admin can modify templates
CREATE POLICY "System can manage pet templates" ON pet_templates
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid()
            AND username IN ('admin', 'moderator')
        )
    );

-- =====================================================
-- PET ACCESSORIES TABLE POLICIES
-- =====================================================

-- Everyone can view available accessories
CREATE POLICY "Anyone can view pet accessories" ON pet_accessories
    FOR SELECT USING (true);

-- Only system/admin can modify accessories
CREATE POLICY "System can manage pet accessories" ON pet_accessories
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid()
            AND username IN ('admin', 'moderator')
        )
    );

-- =====================================================
-- USER PET ACCESSORIES TABLE POLICIES
-- =====================================================

-- Users can view their own unlocked accessories
CREATE POLICY "Users can view own accessories" ON user_pet_accessories
    FOR SELECT USING (user_id = auth.uid());

-- Users can unlock accessories (typically through purchase/achievement)
CREATE POLICY "Users can unlock accessories" ON user_pet_accessories
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Prevent accidental deletion of unlocked accessories
CREATE POLICY "Users cannot delete unlocked accessories" ON user_pet_accessories
    FOR DELETE USING (false);

-- =====================================================
-- PET FOODS TABLE POLICIES
-- =====================================================

-- Everyone can view available foods
CREATE POLICY "Anyone can view pet foods" ON pet_foods
    FOR SELECT USING (true);

-- Only system/admin can modify foods
CREATE POLICY "System can manage pet foods" ON pet_foods
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid()
            AND username IN ('admin', 'moderator')
        )
    );

-- =====================================================
-- PET FEEDING HISTORY TABLE POLICIES
-- =====================================================

-- Users can view feeding history for their own pets
CREATE POLICY "Users can view own pet feeding history" ON pet_feeding_history
    FOR SELECT USING (user_id = auth.uid());

-- Users can record feeding for their own pets
CREATE POLICY "Users can record feeding for own pets" ON pet_feeding_history
    FOR INSERT WITH CHECK (
        user_id = auth.uid() AND
        user_pet_id IN (SELECT id FROM user_pets WHERE user_id = auth.uid())
    );

-- Feeding history is immutable once recorded
CREATE POLICY "Feeding history is read-only after creation" ON pet_feeding_history
    FOR UPDATE USING (false);

CREATE POLICY "Feeding history cannot be deleted" ON pet_feeding_history
    FOR DELETE USING (false);

-- =====================================================
-- PET ACTIVITIES TABLE POLICIES
-- =====================================================

-- Everyone can view available activities
CREATE POLICY "Anyone can view pet activities" ON pet_activities
    FOR SELECT USING (is_active = true);

-- Only system/admin can modify activities
CREATE POLICY "System can manage pet activities" ON pet_activities
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid()
            AND username IN ('admin', 'moderator')
        )
    );

-- =====================================================
-- PET ACTIVITY SESSIONS TABLE POLICIES
-- =====================================================

-- Users can view activity sessions for their own pets
CREATE POLICY "Users can view own pet activity sessions" ON pet_activity_sessions
    FOR SELECT USING (user_id = auth.uid());

-- Users can create activity sessions for their own pets
CREATE POLICY "Users can create activity sessions for own pets" ON pet_activity_sessions
    FOR INSERT WITH CHECK (
        user_id = auth.uid() AND
        user_pet_id IN (SELECT id FROM user_pets WHERE user_id = auth.uid())
    );

-- Users can update their own activity sessions (for completion)
CREATE POLICY "Users can update own pet activity sessions" ON pet_activity_sessions
    FOR UPDATE USING (user_id = auth.uid());

-- Users can abandon their own sessions
CREATE POLICY "Users can delete own incomplete sessions" ON pet_activity_sessions
    FOR DELETE USING (
        user_id = auth.uid() AND 
        completed_at IS NULL
    );

-- =====================================================
-- PET BREEDING TABLE POLICIES
-- =====================================================

-- Users can view breeding involving their pets
CREATE POLICY "Users can view breeding for own pets" ON pet_breeding
    FOR SELECT USING (
        user_id = auth.uid() OR
        parent1_id IN (SELECT id FROM user_pets WHERE user_id = auth.uid()) OR
        parent2_id IN (SELECT id FROM user_pets WHERE user_id = auth.uid())
    );

-- Users can initiate breeding with their pets
CREATE POLICY "Users can initiate breeding with own pets" ON pet_breeding
    FOR INSERT WITH CHECK (
        user_id = auth.uid() AND
        parent1_id IN (SELECT id FROM user_pets WHERE user_id = auth.uid()) AND
        parent2_id IN (SELECT id FROM user_pets WHERE user_id = auth.uid())
    );

-- Users can update breeding status for their breeding
CREATE POLICY "Users can update own breeding" ON pet_breeding
    FOR UPDATE USING (user_id = auth.uid());

-- Users can cancel their own breeding before completion
CREATE POLICY "Users can cancel own incomplete breeding" ON pet_breeding
    FOR DELETE USING (
        user_id = auth.uid() AND 
        breeding_status = 'in_progress'
    );

-- =====================================================
-- PET GENETIC TRAITS TABLE POLICIES
-- =====================================================

-- Everyone can view genetic traits information
CREATE POLICY "Anyone can view genetic traits" ON pet_genetic_traits
    FOR SELECT USING (true);

-- Only system/admin can modify genetic traits
CREATE POLICY "System can manage genetic traits" ON pet_genetic_traits
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid()
            AND username IN ('admin', 'moderator')
        )
    );

-- =====================================================
-- USER PET TRAITS TABLE POLICIES
-- =====================================================

-- Users can view traits for their own pets
CREATE POLICY "Users can view own pet traits" ON user_pet_traits
    FOR SELECT USING (
        user_pet_id IN (SELECT id FROM user_pets WHERE user_id = auth.uid())
    );

-- System can assign traits during breeding/creation
CREATE POLICY "System can assign pet traits" ON user_pet_traits
    FOR INSERT WITH CHECK (
        user_pet_id IN (SELECT id FROM user_pets WHERE user_id = auth.uid())
    );

-- Traits are generally immutable once assigned
CREATE POLICY "Pet traits are read-only" ON user_pet_traits
    FOR UPDATE USING (false);

CREATE POLICY "Pet traits cannot be deleted" ON user_pet_traits
    FOR DELETE USING (false);

-- =====================================================
-- PET ACHIEVEMENTS TABLE POLICIES
-- =====================================================

-- Everyone can view available achievements
CREATE POLICY "Anyone can view pet achievements" ON pet_achievements
    FOR SELECT USING (NOT is_secret);

-- Users can view secret achievements they've unlocked
CREATE POLICY "Users can view unlocked secret achievements" ON pet_achievements
    FOR SELECT USING (
        is_secret AND id IN (
            SELECT achievement_id FROM user_pet_achievements 
            WHERE user_id = auth.uid() AND is_completed = true
        )
    );

-- Only system/admin can modify achievements
CREATE POLICY "System can manage pet achievements" ON pet_achievements
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid()
            AND username IN ('admin', 'moderator')
        )
    );

-- =====================================================
-- USER PET ACHIEVEMENTS TABLE POLICIES
-- =====================================================

-- Users can view their own achievement progress
CREATE POLICY "Users can view own achievement progress" ON user_pet_achievements
    FOR SELECT USING (user_id = auth.uid());

-- System can create achievement progress records
CREATE POLICY "System can create achievement progress" ON user_pet_achievements
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- System can update achievement progress
CREATE POLICY "System can update achievement progress" ON user_pet_achievements
    FOR UPDATE USING (user_id = auth.uid());

-- Achievement progress cannot be deleted
CREATE POLICY "Achievement progress cannot be deleted" ON user_pet_achievements
    FOR DELETE USING (false);

-- =====================================================
-- PET FRIENDSHIPS TABLE POLICIES
-- =====================================================

-- Users can view friendships involving their pets
CREATE POLICY "Users can view friendships for own pets" ON pet_friendships
    FOR SELECT USING (
        pet1_id IN (SELECT id FROM user_pets WHERE user_id = auth.uid()) OR
        pet2_id IN (SELECT id FROM user_pets WHERE user_id = auth.uid())
    );

-- Users can create friendships for their pets
CREATE POLICY "Users can create friendships for own pets" ON pet_friendships
    FOR INSERT WITH CHECK (
        pet1_id IN (SELECT id FROM user_pets WHERE user_id = auth.uid()) OR
        pet2_id IN (SELECT id FROM user_pets WHERE user_id = auth.uid())
    );

-- Friendships are automatically managed by system
CREATE POLICY "System can update friendships" ON pet_friendships
    FOR UPDATE USING (
        pet1_id IN (SELECT id FROM user_pets WHERE user_id = auth.uid()) OR
        pet2_id IN (SELECT id FROM user_pets WHERE user_id = auth.uid())
    );

-- Users can end friendships involving their pets
CREATE POLICY "Users can end friendships for own pets" ON pet_friendships
    FOR DELETE USING (
        pet1_id IN (SELECT id FROM user_pets WHERE user_id = auth.uid()) OR
        pet2_id IN (SELECT id FROM user_pets WHERE user_id = auth.uid())
    );

-- =====================================================
-- PET PLAYDATES TABLE POLICIES
-- =====================================================

-- Users can view public playdates and their own playdates
CREATE POLICY "Users can view accessible playdates" ON pet_playdates
    FOR SELECT USING (
        is_public = true OR
        organizer_user_id = auth.uid() OR
        id IN (
            SELECT playdate_id FROM pet_playdate_participants 
            WHERE user_id = auth.uid()
        )
    );

-- Users can create playdates
CREATE POLICY "Users can create playdates" ON pet_playdates
    FOR INSERT WITH CHECK (organizer_user_id = auth.uid());

-- Users can update their own playdates
CREATE POLICY "Users can update own playdates" ON pet_playdates
    FOR UPDATE USING (organizer_user_id = auth.uid());

-- Users can cancel their own playdates
CREATE POLICY "Users can cancel own playdates" ON pet_playdates
    FOR DELETE USING (organizer_user_id = auth.uid());

-- =====================================================
-- PET PLAYDATE PARTICIPANTS TABLE POLICIES
-- =====================================================

-- Users can view participants in accessible playdates
CREATE POLICY "Users can view participants in accessible playdates" ON pet_playdate_participants
    FOR SELECT USING (
        playdate_id IN (
            SELECT id FROM pet_playdates 
            WHERE is_public = true OR
                  organizer_user_id = auth.uid() OR
                  id IN (
                      SELECT playdate_id FROM pet_playdate_participants 
                      WHERE user_id = auth.uid()
                  )
        )
    );

-- Users can join playdates with their pets
CREATE POLICY "Users can join playdates with own pets" ON pet_playdate_participants
    FOR INSERT WITH CHECK (
        user_id = auth.uid() AND
        pet_id IN (SELECT id FROM user_pets WHERE user_id = auth.uid())
    );

-- Users can update their own participation
CREATE POLICY "Users can update own participation" ON pet_playdate_participants
    FOR UPDATE USING (user_id = auth.uid());

-- Users can leave playdates
CREATE POLICY "Users can leave playdates" ON pet_playdate_participants
    FOR DELETE USING (user_id = auth.uid());

-- =====================================================
-- PET DAILY STATS TABLE POLICIES
-- =====================================================

-- Users can view daily stats for their own pets
CREATE POLICY "Users can view own pet daily stats" ON pet_daily_stats
    FOR SELECT USING (user_id = auth.uid());

-- System can create daily stats records
CREATE POLICY "System can create daily stats" ON pet_daily_stats
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- System can update daily stats
CREATE POLICY "System can update daily stats" ON pet_daily_stats
    FOR UPDATE USING (user_id = auth.uid());

-- Daily stats cannot be deleted by users
CREATE POLICY "Daily stats cannot be deleted by users" ON pet_daily_stats
    FOR DELETE USING (false);

-- =====================================================
-- USER PET SETTINGS TABLE POLICIES
-- =====================================================

-- Users can view their own pet settings
CREATE POLICY "Users can view own pet settings" ON user_pet_settings
    FOR SELECT USING (user_id = auth.uid());

-- Users can create their own pet settings
CREATE POLICY "Users can create own pet settings" ON user_pet_settings
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Users can update their own pet settings
CREATE POLICY "Users can update own pet settings" ON user_pet_settings
    FOR UPDATE USING (user_id = auth.uid());

-- Users can delete their own pet settings
CREATE POLICY "Users can delete own pet settings" ON user_pet_settings
    FOR DELETE USING (user_id = auth.uid());

-- =====================================================
-- ADDITIONAL SECURITY FUNCTIONS
-- =====================================================

-- Function to check if user owns a pet
CREATE OR REPLACE FUNCTION user_owns_pet(p_pet_id UUID, p_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM user_pets 
        WHERE id = p_pet_id AND user_id = p_user_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user can interact with a pet (owns or has friendship)
CREATE OR REPLACE FUNCTION user_can_interact_with_pet(p_pet_id UUID, p_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        -- User owns the pet
        SELECT 1 FROM user_pets 
        WHERE id = p_pet_id AND user_id = p_user_id
        
        UNION
        
        -- Pet is friend with user's pet
        SELECT 1 FROM pet_friendships pf
        JOIN user_pets up1 ON pf.pet1_id = up1.id
        JOIN user_pets up2 ON pf.pet2_id = up2.id
        WHERE (pf.pet1_id = p_pet_id AND up2.user_id = p_user_id)
           OR (pf.pet2_id = p_pet_id AND up1.user_id = p_user_id)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user can access playdate
CREATE OR REPLACE FUNCTION user_can_access_playdate(p_playdate_id UUID, p_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM pet_playdates 
        WHERE id = p_playdate_id 
        AND (
            is_public = true OR
            organizer_user_id = p_user_id OR
            id IN (
                SELECT playdate_id FROM pet_playdate_participants 
                WHERE user_id = p_user_id
            )
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

-- Grant usage on schema
GRANT USAGE ON SCHEMA public TO authenticated;

-- Grant permissions on tables
GRANT SELECT, INSERT, UPDATE, DELETE ON user_pets TO authenticated;
GRANT SELECT ON pet_templates TO authenticated;
GRANT SELECT ON pet_accessories TO authenticated;
GRANT SELECT, INSERT ON user_pet_accessories TO authenticated;
GRANT SELECT ON pet_foods TO authenticated;
GRANT SELECT, INSERT ON pet_feeding_history TO authenticated;
GRANT SELECT ON pet_activities TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON pet_activity_sessions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON pet_breeding TO authenticated;
GRANT SELECT ON pet_genetic_traits TO authenticated;
GRANT SELECT, INSERT ON user_pet_traits TO authenticated;
GRANT SELECT ON pet_achievements TO authenticated;
GRANT SELECT, INSERT, UPDATE ON user_pet_achievements TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON pet_friendships TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON pet_playdates TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON pet_playdate_participants TO authenticated;
GRANT SELECT, INSERT, UPDATE ON pet_daily_stats TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_pet_settings TO authenticated;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION user_owns_pet(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION user_can_interact_with_pet(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION user_can_access_playdate(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_user_pet(UUID, VARCHAR, VARCHAR, VARCHAR, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION update_pet_vitals(UUID, DECIMAL, DECIMAL, DECIMAL, DECIMAL) TO authenticated;
GRANT EXECUTE ON FUNCTION determine_pet_mood(DECIMAL, DECIMAL, DECIMAL, DECIMAL) TO authenticated;
GRANT EXECUTE ON FUNCTION feed_pet(UUID, UUID, UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION start_pet_activity(UUID, UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION complete_pet_activity(UUID, DECIMAL, DECIMAL, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION start_pet_breeding(UUID, UUID, UUID, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION complete_pet_breeding(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_pet_achievement_progress(UUID, VARCHAR, DECIMAL, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_pet_friendship(UUID, UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_pet_statistics(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_pets_needing_attention(UUID) TO authenticated;

-- Grant execute on maintenance functions to service role
GRANT EXECUTE ON FUNCTION cleanup_old_pet_data() TO service_role;
GRANT EXECUTE ON FUNCTION complete_expired_breeding() TO service_role;

-- Grant execute on all pet-related functions to authenticated users
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
