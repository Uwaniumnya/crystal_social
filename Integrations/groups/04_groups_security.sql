-- =====================================================
-- CRYSTAL SOCIAL - GROUPS SYSTEM SECURITY
-- =====================================================
-- Row Level Security policies for group management
-- =====================================================

-- Enable RLS on all group tables
ALTER TABLE group_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_event_attendees ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_message_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_moderation_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_analytics ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- GROUP DETAILS POLICIES
-- =====================================================

-- Users can view groups they are members of, and public groups
CREATE POLICY "Users can view accessible groups" ON group_details
    FOR SELECT
    USING (
        is_public = true 
        OR chat_id IN (
            SELECT group_id FROM group_members 
            WHERE user_id = auth.uid() AND is_active = true
        )
    );

-- Only group owners can update group details
CREATE POLICY "Only owners can update group details" ON group_details
    FOR UPDATE
    USING (
        chat_id IN (
            SELECT group_id FROM group_members 
            WHERE user_id = auth.uid() 
              AND role = 'owner' 
              AND is_active = true
        )
    );

-- Users can create groups (handled by function with proper validation)
CREATE POLICY "Authenticated users can create groups" ON group_details
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- Only owners can delete groups
CREATE POLICY "Only owners can delete groups" ON group_details
    FOR DELETE
    USING (
        chat_id IN (
            SELECT group_id FROM group_members 
            WHERE user_id = auth.uid() 
              AND role = 'owner' 
              AND is_active = true
        )
    );

-- =====================================================
-- GROUP MEMBERS POLICIES
-- =====================================================

-- Users can view members of groups they belong to
CREATE POLICY "Users can view group members" ON group_members
    FOR SELECT
    USING (
        group_id IN (
            SELECT group_id FROM group_members gm2
            WHERE gm2.user_id = auth.uid() AND gm2.is_active = true
        )
        OR group_id IN (
            SELECT chat_id FROM group_details WHERE is_public = true
        )
    );

-- Users can join groups through invitations (handled by functions)
CREATE POLICY "Users can join groups" ON group_members
    FOR INSERT
    WITH CHECK (
        user_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = group_members.group_id 
              AND user_id = auth.uid() 
              AND is_active = true
              AND (role IN ('owner', 'admin') OR permissions->>'can_invite_members' = 'true')
        )
    );

-- Users can update their own member status or admins can update others
CREATE POLICY "Users can update member status" ON group_members
    FOR UPDATE
    USING (
        user_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM group_members gm2
            WHERE gm2.group_id = group_members.group_id
              AND gm2.user_id = auth.uid()
              AND gm2.is_active = true
              AND (gm2.role IN ('owner', 'admin') OR gm2.permissions->>'can_remove_members' = 'true')
        )
    );

-- Members can leave groups, admins can remove others
CREATE POLICY "Users can leave or be removed from groups" ON group_members
    FOR DELETE
    USING (
        user_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM group_members gm2
            WHERE gm2.group_id = group_members.group_id
              AND gm2.user_id = auth.uid()
              AND gm2.is_active = true
              AND (gm2.role IN ('owner', 'admin') OR gm2.permissions->>'can_remove_members' = 'true')
        )
    );

-- =====================================================
-- GROUP INVITATIONS POLICIES
-- =====================================================

-- Users can view invitations they sent or received
CREATE POLICY "Users can view their invitations" ON group_invitations
    FOR SELECT
    USING (
        inviter_id = auth.uid()
        OR invitee_id = auth.uid()
        OR (invitation_type = 'public' AND status = 'pending')
    );

-- Users can create invitations if they have permission
CREATE POLICY "Users can create invitations" ON group_invitations
    FOR INSERT
    WITH CHECK (
        inviter_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = group_invitations.group_id 
              AND user_id = auth.uid() 
              AND is_active = true
              AND (role IN ('owner', 'admin') OR permissions->>'can_invite_members' = 'true')
        )
    );

-- Users can update invitations they sent or received
CREATE POLICY "Users can update their invitations" ON group_invitations
    FOR UPDATE
    USING (
        inviter_id = auth.uid()
        OR invitee_id = auth.uid()
    );

-- Users can delete invitations they sent
CREATE POLICY "Users can delete their sent invitations" ON group_invitations
    FOR DELETE
    USING (inviter_id = auth.uid());

-- =====================================================
-- GROUP ANNOUNCEMENTS POLICIES
-- =====================================================

-- Group members can view announcements
CREATE POLICY "Members can view group announcements" ON group_announcements
    FOR SELECT
    USING (
        group_id IN (
            SELECT group_id FROM group_members 
            WHERE user_id = auth.uid() AND is_active = true
        )
    );

-- Only admins and owners can create announcements
CREATE POLICY "Admins can create announcements" ON group_announcements
    FOR INSERT
    WITH CHECK (
        author_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = group_announcements.group_id 
              AND user_id = auth.uid() 
              AND is_active = true
              AND (role IN ('owner', 'admin', 'moderator') OR permissions->>'can_pin_messages' = 'true')
        )
    );

-- Authors and group admins can update announcements
CREATE POLICY "Authors and admins can update announcements" ON group_announcements
    FOR UPDATE
    USING (
        author_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = group_announcements.group_id 
              AND user_id = auth.uid() 
              AND is_active = true
              AND role IN ('owner', 'admin')
        )
    );

-- Authors and group admins can delete announcements
CREATE POLICY "Authors and admins can delete announcements" ON group_announcements
    FOR DELETE
    USING (
        author_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = group_announcements.group_id 
              AND user_id = auth.uid() 
              AND is_active = true
              AND role IN ('owner', 'admin')
        )
    );

-- =====================================================
-- GROUP EVENTS POLICIES
-- =====================================================

-- Group members can view events
CREATE POLICY "Members can view group events" ON group_events
    FOR SELECT
    USING (
        group_id IN (
            SELECT group_id FROM group_members 
            WHERE user_id = auth.uid() AND is_active = true
        )
    );

-- Group members can create events
CREATE POLICY "Members can create events" ON group_events
    FOR INSERT
    WITH CHECK (
        organizer_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = group_events.group_id 
              AND user_id = auth.uid() 
              AND is_active = true
        )
    );

-- Event organizers and group admins can update events
CREATE POLICY "Organizers and admins can update events" ON group_events
    FOR UPDATE
    USING (
        organizer_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = group_events.group_id 
              AND user_id = auth.uid() 
              AND is_active = true
              AND role IN ('owner', 'admin')
        )
    );

-- Event organizers and group admins can delete events
CREATE POLICY "Organizers and admins can delete events" ON group_events
    FOR DELETE
    USING (
        organizer_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = group_events.group_id 
              AND user_id = auth.uid() 
              AND is_active = true
              AND role IN ('owner', 'admin')
        )
    );

-- =====================================================
-- GROUP EVENT ATTENDEES POLICIES
-- =====================================================

-- Users can view event attendees for events in their groups
CREATE POLICY "Members can view event attendees" ON group_event_attendees
    FOR SELECT
    USING (
        event_id IN (
            SELECT ge.id FROM group_events ge
            JOIN group_members gm ON ge.group_id = gm.group_id
            WHERE gm.user_id = auth.uid() AND gm.is_active = true
        )
    );

-- Users can RSVP to events in their groups
CREATE POLICY "Members can RSVP to events" ON group_event_attendees
    FOR INSERT
    WITH CHECK (
        user_id = auth.uid()
        AND event_id IN (
            SELECT ge.id FROM group_events ge
            JOIN group_members gm ON ge.group_id = gm.group_id
            WHERE gm.user_id = auth.uid() AND gm.is_active = true
        )
    );

-- Users can update their own RSVP
CREATE POLICY "Users can update their RSVP" ON group_event_attendees
    FOR UPDATE
    USING (user_id = auth.uid());

-- Users can remove their own RSVP
CREATE POLICY "Users can remove their RSVP" ON group_event_attendees
    FOR DELETE
    USING (user_id = auth.uid());

-- =====================================================
-- GROUP MEDIA POLICIES
-- =====================================================

-- Group members can view media
CREATE POLICY "Members can view group media" ON group_media
    FOR SELECT
    USING (
        group_id IN (
            SELECT group_id FROM group_members 
            WHERE user_id = auth.uid() AND is_active = true
        )
    );

-- Group members can upload media
CREATE POLICY "Members can upload media" ON group_media
    FOR INSERT
    WITH CHECK (
        uploader_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = group_media.group_id 
              AND user_id = auth.uid() 
              AND is_active = true
              AND (permissions->>'can_send_media' = 'true')
        )
    );

-- Uploaders and admins can update media metadata
CREATE POLICY "Uploaders and admins can update media" ON group_media
    FOR UPDATE
    USING (
        uploader_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = group_media.group_id 
              AND user_id = auth.uid() 
              AND is_active = true
              AND role IN ('owner', 'admin')
        )
    );

-- Uploaders and admins can delete media
CREATE POLICY "Uploaders and admins can delete media" ON group_media
    FOR DELETE
    USING (
        uploader_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = group_media.group_id 
              AND user_id = auth.uid() 
              AND is_active = true
              AND (role IN ('owner', 'admin') OR permissions->>'can_delete_messages' = 'true')
        )
    );

-- =====================================================
-- GROUP MESSAGE REACTIONS POLICIES
-- =====================================================

-- Group members can view reactions
CREATE POLICY "Members can view message reactions" ON group_message_reactions
    FOR SELECT
    USING (
        group_id IN (
            SELECT group_id FROM group_members 
            WHERE user_id = auth.uid() AND is_active = true
        )
    );

-- Group members can add reactions
CREATE POLICY "Members can add reactions" ON group_message_reactions
    FOR INSERT
    WITH CHECK (
        user_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = group_message_reactions.group_id 
              AND user_id = auth.uid() 
              AND is_active = true
        )
    );

-- Users can remove their own reactions
CREATE POLICY "Users can remove their reactions" ON group_message_reactions
    FOR DELETE
    USING (user_id = auth.uid());

-- =====================================================
-- GROUP RULES POLICIES
-- =====================================================

-- Group members can view rules
CREATE POLICY "Members can view group rules" ON group_rules
    FOR SELECT
    USING (
        group_id IN (
            SELECT group_id FROM group_members 
            WHERE user_id = auth.uid() AND is_active = true
        )
        OR group_id IN (
            SELECT chat_id FROM group_details WHERE is_public = true
        )
    );

-- Only admins and owners can create rules
CREATE POLICY "Admins can create rules" ON group_rules
    FOR INSERT
    WITH CHECK (
        created_by = auth.uid()
        AND EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = group_rules.group_id 
              AND user_id = auth.uid() 
              AND is_active = true
              AND role IN ('owner', 'admin')
        )
    );

-- Rule creators and group owners can update rules
CREATE POLICY "Creators and owners can update rules" ON group_rules
    FOR UPDATE
    USING (
        created_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = group_rules.group_id 
              AND user_id = auth.uid() 
              AND is_active = true
              AND role = 'owner'
        )
    );

-- Rule creators and group owners can delete rules
CREATE POLICY "Creators and owners can delete rules" ON group_rules
    FOR DELETE
    USING (
        created_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = group_rules.group_id 
              AND user_id = auth.uid() 
              AND is_active = true
              AND role = 'owner'
        )
    );

-- =====================================================
-- GROUP MODERATION LOGS POLICIES
-- =====================================================

-- Group admins and affected users can view moderation logs
CREATE POLICY "Admins and affected users can view moderation logs" ON group_moderation_logs
    FOR SELECT
    USING (
        target_user_id = auth.uid()
        OR moderator_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = group_moderation_logs.group_id 
              AND user_id = auth.uid() 
              AND is_active = true
              AND role IN ('owner', 'admin')
        )
    );

-- Only moderators and above can create moderation logs
CREATE POLICY "Moderators can create moderation logs" ON group_moderation_logs
    FOR INSERT
    WITH CHECK (
        moderator_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = group_moderation_logs.group_id 
              AND user_id = auth.uid() 
              AND is_active = true
              AND (role IN ('owner', 'admin', 'moderator') OR permissions->>'can_remove_members' = 'true')
        )
    );

-- Only moderators who created the log or higher-level admins can update
CREATE POLICY "Moderators can update their logs" ON group_moderation_logs
    FOR UPDATE
    USING (
        moderator_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = group_moderation_logs.group_id 
              AND user_id = auth.uid() 
              AND is_active = true
              AND role IN ('owner', 'admin')
        )
    );

-- =====================================================
-- GROUP ANALYTICS POLICIES
-- =====================================================

-- Only group admins and owners can view analytics
CREATE POLICY "Admins can view group analytics" ON group_analytics
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = group_analytics.group_id 
              AND user_id = auth.uid() 
              AND is_active = true
              AND role IN ('owner', 'admin')
        )
    );

-- Analytics are automatically created by triggers
CREATE POLICY "System can create analytics" ON group_analytics
    FOR INSERT
    WITH CHECK (true);

-- Analytics are automatically updated by triggers
CREATE POLICY "System can update analytics" ON group_analytics
    FOR UPDATE
    USING (true);

-- Only group owners can delete analytics (for cleanup)
CREATE POLICY "Owners can delete analytics" ON group_analytics
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = group_analytics.group_id 
              AND user_id = auth.uid() 
              AND is_active = true
              AND role = 'owner'
        )
    );

-- =====================================================
-- FUNCTION PERMISSIONS
-- =====================================================

-- Grant execute permissions on functions to authenticated users
GRANT EXECUTE ON FUNCTION create_group TO authenticated;
GRANT EXECUTE ON FUNCTION add_group_member TO authenticated;
GRANT EXECUTE ON FUNCTION remove_group_member TO authenticated;
GRANT EXECUTE ON FUNCTION update_member_role TO authenticated;
GRANT EXECUTE ON FUNCTION create_group_invitation TO authenticated;
GRANT EXECUTE ON FUNCTION accept_group_invitation TO authenticated;
GRANT EXECUTE ON FUNCTION get_group_statistics TO authenticated;
GRANT EXECUTE ON FUNCTION cleanup_expired_group_data TO authenticated;

-- Grant function execution to service role for automated tasks
GRANT EXECUTE ON FUNCTION cleanup_expired_group_data TO service_role;
