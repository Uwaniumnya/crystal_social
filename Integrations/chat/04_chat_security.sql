-- =====================================================
-- CRYSTAL SOCIAL - CHAT SYSTEM ROW LEVEL SECURITY
-- =====================================================
-- Comprehensive security policies for chat system
-- =====================================================

-- Enable RLS on all chat tables
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_delivery_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE typing_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE calls ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_ringtones ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_drafts ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_analytics ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- CHAT TABLE POLICIES
-- =====================================================

-- Users can view chats they participate in
CREATE POLICY "Users can view their chats" ON chats
    FOR SELECT USING (
        auth.uid() IN (
            SELECT user_id FROM chat_participants 
            WHERE chat_id = id AND is_active = true
        )
    );

-- Users can create new chats
CREATE POLICY "Users can create chats" ON chats
    FOR INSERT WITH CHECK (auth.uid() = created_by);

-- Chat creators and admins can update chat details
CREATE POLICY "Chat admins can update chats" ON chats
    FOR UPDATE USING (
        auth.uid() IN (
            SELECT user_id FROM chat_participants 
            WHERE chat_id = id 
            AND role IN ('owner', 'admin') 
            AND is_active = true
        )
    );

-- Chat owners can delete chats
CREATE POLICY "Chat owners can delete chats" ON chats
    FOR DELETE USING (
        auth.uid() IN (
            SELECT user_id FROM chat_participants 
            WHERE chat_id = id 
            AND role = 'owner' 
            AND is_active = true
        )
    );

-- =====================================================
-- CHAT PARTICIPANTS POLICIES
-- =====================================================

-- Users can view participants of chats they're in
CREATE POLICY "Users can view chat participants" ON chat_participants
    FOR SELECT USING (
        auth.uid() IN (
            SELECT user_id FROM chat_participants cp2
            WHERE cp2.chat_id = chat_id AND cp2.is_active = true
        )
    );

-- Users can join chats (if invited or public)
CREATE POLICY "Users can join chats" ON chat_participants
    FOR INSERT WITH CHECK (
        auth.uid() = user_id AND (
            -- User is joining a chat they created
            auth.uid() IN (SELECT created_by FROM chats WHERE id = chat_id)
            OR
            -- Chat allows new members (not implemented in this example)
            EXISTS (SELECT 1 FROM chats WHERE id = chat_id AND is_private = false)
            OR
            -- User was invited (would need invitation system)
            true -- Placeholder - implement invitation logic
        )
    );

-- Users can update their own participation settings
CREATE POLICY "Users can update their participation" ON chat_participants
    FOR UPDATE USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Chat admins can manage other participants
CREATE POLICY "Chat admins can manage participants" ON chat_participants
    FOR UPDATE USING (
        auth.uid() IN (
            SELECT user_id FROM chat_participants 
            WHERE chat_id = chat_participants.chat_id 
            AND role IN ('owner', 'admin') 
            AND is_active = true
        )
    );

-- Users can leave chats, admins can remove others
CREATE POLICY "Users can leave chats" ON chat_participants
    FOR DELETE USING (
        auth.uid() = user_id 
        OR auth.uid() IN (
            SELECT user_id FROM chat_participants cp2
            WHERE cp2.chat_id = chat_id 
            AND cp2.role IN ('owner', 'admin') 
            AND cp2.is_active = true
        )
    );

-- =====================================================
-- MESSAGES POLICIES
-- =====================================================

-- Users can view messages in chats they participate in
CREATE POLICY "Users can view chat messages" ON messages
    FOR SELECT USING (
        auth.uid() IN (
            SELECT user_id FROM chat_participants 
            WHERE chat_id = messages.chat_id AND is_active = true
        )
    );

-- Users can send messages to chats they participate in
CREATE POLICY "Users can send messages" ON messages
    FOR INSERT WITH CHECK (
        auth.uid() = sender_id AND
        auth.uid() IN (
            SELECT user_id FROM chat_participants 
            WHERE chat_id = messages.chat_id 
            AND is_active = true
            AND permissions->>'send_messages' = 'true'
        )
    );

-- Users can edit their own messages
CREATE POLICY "Users can edit their messages" ON messages
    FOR UPDATE USING (auth.uid() = sender_id)
    WITH CHECK (auth.uid() = sender_id);

-- Users can delete their own messages, admins can delete any
CREATE POLICY "Users can delete messages" ON messages
    FOR DELETE USING (
        auth.uid() = sender_id 
        OR auth.uid() IN (
            SELECT user_id FROM chat_participants 
            WHERE chat_id = messages.chat_id 
            AND role IN ('owner', 'admin', 'moderator') 
            AND is_active = true
        )
    );

-- =====================================================
-- MESSAGE REACTIONS POLICIES
-- =====================================================

-- Users can view reactions in chats they participate in
CREATE POLICY "Users can view message reactions" ON message_reactions
    FOR SELECT USING (
        auth.uid() IN (
            SELECT user_id FROM chat_participants cp
            JOIN messages m ON cp.chat_id = m.chat_id
            WHERE m.id = message_id AND cp.is_active = true
        )
    );

-- Users can add reactions to messages in their chats
CREATE POLICY "Users can add reactions" ON message_reactions
    FOR INSERT WITH CHECK (
        auth.uid() = user_id AND
        auth.uid() IN (
            SELECT user_id FROM chat_participants cp
            JOIN messages m ON cp.chat_id = m.chat_id
            WHERE m.id = message_id 
            AND cp.is_active = true
            AND cp.permissions->>'add_reactions' = 'true'
        )
    );

-- Users can remove their own reactions
CREATE POLICY "Users can remove their reactions" ON message_reactions
    FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- MESSAGE DELIVERY STATUS POLICIES
-- =====================================================

-- Users can view delivery status for messages they sent
CREATE POLICY "Users can view delivery status" ON message_delivery_status
    FOR SELECT USING (
        auth.uid() IN (
            SELECT sender_id FROM messages WHERE id = message_id
        )
        OR auth.uid() = user_id
    );

-- System can insert delivery status
CREATE POLICY "System can insert delivery status" ON message_delivery_status
    FOR INSERT WITH CHECK (true);

-- Users can update their own delivery status
CREATE POLICY "Users can update delivery status" ON message_delivery_status
    FOR UPDATE USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- TYPING STATUS POLICIES
-- =====================================================

-- Users can view typing status in their chats
CREATE POLICY "Users can view typing status" ON typing_status
    FOR SELECT USING (
        auth.uid() IN (
            SELECT user_id FROM chat_participants 
            WHERE chat_id = typing_status.chat_id AND is_active = true
        )
    );

-- Users can update their own typing status
CREATE POLICY "Users can update typing status" ON typing_status
    FOR INSERT WITH CHECK (
        auth.uid() = user_id AND
        auth.uid() IN (
            SELECT user_id FROM chat_participants 
            WHERE chat_id = typing_status.chat_id AND is_active = true
        )
    );

CREATE POLICY "Users can modify their typing status" ON typing_status
    FOR UPDATE USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their typing status" ON typing_status
    FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- CHAT SETTINGS POLICIES
-- =====================================================

-- Users can view and manage their own chat settings
CREATE POLICY "Users can manage their chat settings" ON chat_settings
    FOR ALL USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- CALLS POLICIES
-- =====================================================

-- Users can view calls they're involved in
CREATE POLICY "Users can view their calls" ON calls
    FOR SELECT USING (
        auth.uid() = caller_id 
        OR auth.uid() = receiver_id
        OR auth.uid() IN (
            SELECT user_id FROM chat_participants 
            WHERE chat_id = calls.chat_id AND is_active = true
        )
    );

-- Users can create calls in chats they participate in
CREATE POLICY "Users can create calls" ON calls
    FOR INSERT WITH CHECK (
        auth.uid() = caller_id AND
        auth.uid() IN (
            SELECT user_id FROM chat_participants 
            WHERE chat_id = calls.chat_id AND is_active = true
        )
    );

-- Call participants can update call status
CREATE POLICY "Call participants can update calls" ON calls
    FOR UPDATE USING (
        auth.uid() = caller_id OR auth.uid() = receiver_id
    );

-- =====================================================
-- USER RINGTONES POLICIES
-- =====================================================

-- Users can manage their own ringtone settings
CREATE POLICY "Users can manage their ringtones" ON user_ringtones
    FOR ALL USING (auth.uid() = owner_id)
    WITH CHECK (auth.uid() = owner_id);

-- =====================================================
-- MESSAGE DRAFTS POLICIES
-- =====================================================

-- Users can manage their own drafts
CREATE POLICY "Users can manage their drafts" ON message_drafts
    FOR ALL USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- SHARED MEDIA POLICIES
-- =====================================================

-- Users can view shared media in their chats
CREATE POLICY "Users can view shared media" ON shared_media
    FOR SELECT USING (
        auth.uid() IN (
            SELECT user_id FROM chat_participants 
            WHERE chat_id = shared_media.chat_id AND is_active = true
        )
    );

-- System can insert shared media entries
CREATE POLICY "System can insert shared media" ON shared_media
    FOR INSERT WITH CHECK (true);

-- =====================================================
-- CHAT ANALYTICS POLICIES
-- =====================================================

-- Users can view analytics for chats they participate in
CREATE POLICY "Users can view chat analytics" ON chat_analytics
    FOR SELECT USING (
        auth.uid() IN (
            SELECT user_id FROM chat_participants 
            WHERE chat_id = chat_analytics.chat_id AND is_active = true
        )
    );

-- System can manage analytics
CREATE POLICY "System can manage analytics" ON chat_analytics
    FOR INSERT WITH CHECK (true);

CREATE POLICY "System can update analytics" ON chat_analytics
    FOR UPDATE USING (true);

-- =====================================================
-- HELPER FUNCTIONS FOR RLS
-- =====================================================

-- Function to check if user is chat admin
CREATE OR REPLACE FUNCTION is_chat_admin(p_chat_id UUID, p_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM chat_participants 
        WHERE chat_id = p_chat_id 
        AND user_id = p_user_id 
        AND role IN ('owner', 'admin') 
        AND is_active = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is chat participant
CREATE OR REPLACE FUNCTION is_chat_participant(p_chat_id UUID, p_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM chat_participants 
        WHERE chat_id = p_chat_id 
        AND user_id = p_user_id 
        AND is_active = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check message permissions
CREATE OR REPLACE FUNCTION has_message_permission(
    p_chat_id UUID, 
    p_permission VARCHAR,
    p_user_id UUID DEFAULT auth.uid()
) RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM chat_participants 
        WHERE chat_id = p_chat_id 
        AND user_id = p_user_id 
        AND is_active = true
        AND (permissions->>p_permission)::boolean = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- GRANTS FOR PUBLIC ACCESS
-- =====================================================

-- Grant necessary permissions to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON chats TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON chat_participants TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON messages TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON message_reactions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON message_delivery_status TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON typing_status TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON chat_settings TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON calls TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_ringtones TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON message_drafts TO authenticated;
GRANT SELECT ON shared_media TO authenticated;
GRANT INSERT ON shared_media TO authenticated;
GRANT SELECT ON chat_analytics TO authenticated;

-- Grant access to sequences
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Grant execution of functions
GRANT EXECUTE ON FUNCTION create_chat TO authenticated;
GRANT EXECUTE ON FUNCTION send_message TO authenticated;
GRANT EXECUTE ON FUNCTION add_message_reaction TO authenticated;
GRANT EXECUTE ON FUNCTION remove_message_reaction TO authenticated;
GRANT EXECUTE ON FUNCTION mark_messages_as_read TO authenticated;
GRANT EXECUTE ON FUNCTION get_chat_messages TO authenticated;
GRANT EXECUTE ON FUNCTION update_typing_status TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_chats TO authenticated;
GRANT EXECUTE ON FUNCTION search_messages TO authenticated;
GRANT EXECUTE ON FUNCTION get_chat_analytics TO authenticated;
GRANT EXECUTE ON FUNCTION is_chat_admin TO authenticated;
GRANT EXECUTE ON FUNCTION is_chat_participant TO authenticated;
GRANT EXECUTE ON FUNCTION has_message_permission TO authenticated;

-- =====================================================
-- SECURITY DOCUMENTATION
-- =====================================================

COMMENT ON POLICY "Users can view their chats" ON chats IS 'Users can only see chats where they are active participants';
COMMENT ON POLICY "Users can create chats" ON chats IS 'Users can create new chats they will own';
COMMENT ON POLICY "Chat admins can update chats" ON chats IS 'Only chat owners and admins can modify chat settings';
COMMENT ON POLICY "Users can view chat messages" ON messages IS 'Users can only see messages in chats they participate in';
COMMENT ON POLICY "Users can send messages" ON messages IS 'Users can send messages if they have permission and are active participants';
COMMENT ON POLICY "Users can edit their messages" ON messages IS 'Users can only edit their own messages';

COMMENT ON FUNCTION is_chat_admin IS 'Helper function to check if user has admin privileges in a chat';
COMMENT ON FUNCTION is_chat_participant IS 'Helper function to check if user is an active participant in a chat';
COMMENT ON FUNCTION has_message_permission IS 'Helper function to check specific messaging permissions for a user in a chat';
