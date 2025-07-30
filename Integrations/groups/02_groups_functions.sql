-- =====================================================
-- CRYSTAL SOCIAL - GROUPS SYSTEM FUNCTIONS
-- =====================================================
-- Advanced operations for group management and features
-- =====================================================

-- Function to create a new group with validation
CREATE OR REPLACE FUNCTION create_group(
    p_creator_id UUID,
    p_chat_id UUID,
    p_display_name VARCHAR(100),
    p_description TEXT DEFAULT NULL,
    p_emoji VARCHAR(10) DEFAULT '💬',
    p_is_public BOOLEAN DEFAULT false,
    p_category VARCHAR(50) DEFAULT 'general',
    p_max_members INTEGER DEFAULT 256,
    p_initial_member_ids UUID[] DEFAULT ARRAY[]::UUID[]
) RETURNS JSONB AS $$
DECLARE
    v_group_id UUID;
    v_member_id UUID;
    v_result JSONB;
BEGIN
    -- Validate inputs
    IF LENGTH(TRIM(p_display_name)) < 1 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Group name is required');
    END IF;
    
    IF p_max_members < 2 OR p_max_members > 1000 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Max members must be between 2 and 1000');
    END IF;
    
    -- Create group details
    INSERT INTO group_details (
        chat_id, display_name, description, emoji, is_public, is_discoverable,
        category, max_members, total_messages, active_members_count, last_activity_at
    ) VALUES (
        p_chat_id, TRIM(p_display_name), p_description, p_emoji, p_is_public, p_is_public,
        p_category, p_max_members, 0, 1, NOW()
    ) RETURNING chat_id INTO v_group_id;
    
    -- Add creator as owner
    INSERT INTO group_members (
        group_id, user_id, role, permissions, is_active, message_count,
        invited_by, invited_at, joined_at
    ) VALUES (
        v_group_id, p_creator_id, 'owner',
        '{
            "can_send_messages": true,
            "can_send_media": true,
            "can_invite_members": true,
            "can_remove_members": true,
            "can_edit_group": true,
            "can_manage_roles": true,
            "can_pin_messages": true,
            "can_delete_messages": true
        }'::jsonb,
        true, 0, p_creator_id, NOW(), NOW()
    );
    
    -- Add initial members
    FOREACH v_member_id IN ARRAY p_initial_member_ids
    LOOP
        IF v_member_id != p_creator_id THEN
            INSERT INTO group_members (
                group_id, user_id, role, invited_by, invited_at, joined_at
            ) VALUES (
                v_group_id, v_member_id, 'member', p_creator_id, NOW(), NOW()
            ) ON CONFLICT (group_id, user_id) DO NOTHING;
        END IF;
    END LOOP;
    
    -- Update member count
    UPDATE group_details 
    SET active_members_count = (
        SELECT COUNT(*) FROM group_members 
        WHERE group_id = v_group_id AND is_active = true
    )
    WHERE chat_id = v_group_id;
    
    -- Create default welcome rule
    INSERT INTO group_rules (
        group_id, created_by, title, description, rule_number, category
    ) VALUES (
        v_group_id, p_creator_id, 'Be Respectful', 
        'Treat all members with respect and kindness.', 1, 'general'
    );
    
    RETURN jsonb_build_object(
        'success', true,
        'group_id', v_group_id,
        'member_count', array_length(p_initial_member_ids, 1) + 1,
        'message', 'Group created successfully'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Failed to create group: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to add member to group with validation
CREATE OR REPLACE FUNCTION add_group_member(
    p_group_id UUID,
    p_user_id UUID,
    p_inviter_id UUID,
    p_role VARCHAR(20) DEFAULT 'member',
    p_skip_permission_check BOOLEAN DEFAULT false
) RETURNS JSONB AS $$
DECLARE
    v_group_details RECORD;
    v_inviter_permissions JSONB;
    v_current_member_count INTEGER;
BEGIN
    -- Get group details
    SELECT * INTO v_group_details FROM group_details WHERE chat_id = p_group_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Group not found');
    END IF;
    
    -- Check if user is already a member
    IF EXISTS (SELECT 1 FROM group_members WHERE group_id = p_group_id AND user_id = p_user_id AND is_active = true) THEN
        RETURN jsonb_build_object('success', false, 'error', 'User is already a member');
    END IF;
    
    -- Check member limit
    SELECT COUNT(*) INTO v_current_member_count 
    FROM group_members 
    WHERE group_id = p_group_id AND is_active = true;
    
    IF v_current_member_count >= v_group_details.max_members THEN
        RETURN jsonb_build_object('success', false, 'error', 'Group has reached maximum member limit');
    END IF;
    
    -- Check inviter permissions (unless skipping)
    IF NOT p_skip_permission_check THEN
        SELECT permissions INTO v_inviter_permissions 
        FROM group_members 
        WHERE group_id = p_group_id AND user_id = p_inviter_id AND is_active = true;
        
        IF NOT FOUND OR NOT (v_inviter_permissions->>'can_invite_members')::boolean THEN
            RETURN jsonb_build_object('success', false, 'error', 'Insufficient permissions to invite members');
        END IF;
    END IF;
    
    -- Add member
    INSERT INTO group_members (
        group_id, user_id, role, invited_by, invited_at, joined_at
    ) VALUES (
        p_group_id, p_user_id, p_role, p_inviter_id, NOW(), NOW()
    ) ON CONFLICT (group_id, user_id) DO UPDATE SET
        is_active = true,
        left_at = NULL,
        invited_by = EXCLUDED.invited_by,
        invited_at = EXCLUDED.invited_at,
        joined_at = EXCLUDED.joined_at;
    
    -- Update group analytics
    UPDATE group_details 
    SET 
        active_members_count = active_members_count + 1,
        last_activity_at = NOW()
    WHERE chat_id = p_group_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Member added successfully',
        'new_member_count', v_current_member_count + 1
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Failed to add member: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to remove member from group
CREATE OR REPLACE FUNCTION remove_group_member(
    p_group_id UUID,
    p_user_id UUID,
    p_remover_id UUID,
    p_reason TEXT DEFAULT NULL,
    p_ban BOOLEAN DEFAULT false
) RETURNS JSONB AS $$
DECLARE
    v_target_role VARCHAR(20);
    v_remover_permissions JSONB;
    v_is_owner BOOLEAN := false;
BEGIN
    -- Get target member role
    SELECT role INTO v_target_role 
    FROM group_members 
    WHERE group_id = p_group_id AND user_id = p_user_id AND is_active = true;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'User is not a member of this group');
    END IF;
    
    -- Check if remover is owner
    SELECT true INTO v_is_owner 
    FROM group_members 
    WHERE group_id = p_group_id AND user_id = p_remover_id AND role = 'owner';
    
    -- Get remover permissions
    SELECT permissions INTO v_remover_permissions 
    FROM group_members 
    WHERE group_id = p_group_id AND user_id = p_remover_id AND is_active = true;
    
    -- Validate permissions
    IF NOT v_is_owner AND NOT (v_remover_permissions->>'can_remove_members')::boolean THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient permissions to remove members');
    END IF;
    
    -- Cannot remove owner unless self-leaving
    IF v_target_role = 'owner' AND p_user_id != p_remover_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'Cannot remove group owner');
    END IF;
    
    -- Update member status
    UPDATE group_members 
    SET 
        is_active = false,
        is_banned = p_ban,
        left_at = NOW(),
        ban_reason = CASE WHEN p_ban THEN p_reason ELSE NULL END
    WHERE group_id = p_group_id AND user_id = p_user_id;
    
    -- Log moderation action
    INSERT INTO group_moderation_logs (
        group_id, moderator_id, target_user_id, action_type, reason
    ) VALUES (
        p_group_id, p_remover_id, p_user_id, 
        CASE WHEN p_ban THEN 'ban' ELSE 'kick' END, 
        p_reason
    );
    
    -- Update group member count
    UPDATE group_details 
    SET 
        active_members_count = active_members_count - 1,
        last_activity_at = NOW()
    WHERE chat_id = p_group_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', CASE WHEN p_ban THEN 'Member banned successfully' ELSE 'Member removed successfully' END
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Failed to remove member: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update member role and permissions
CREATE OR REPLACE FUNCTION update_member_role(
    p_group_id UUID,
    p_target_user_id UUID,
    p_updater_id UUID,
    p_new_role VARCHAR(20),
    p_custom_permissions JSONB DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_updater_role VARCHAR(20);
    v_target_role VARCHAR(20);
    v_default_permissions JSONB;
BEGIN
    -- Get current roles
    SELECT role INTO v_updater_role 
    FROM group_members 
    WHERE group_id = p_group_id AND user_id = p_updater_id AND is_active = true;
    
    SELECT role INTO v_target_role 
    FROM group_members 
    WHERE group_id = p_group_id AND user_id = p_target_user_id AND is_active = true;
    
    IF v_updater_role IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'You are not a member of this group');
    END IF;
    
    IF v_target_role IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Target user is not a member of this group');
    END IF;
    
    -- Only owners can change roles
    IF v_updater_role != 'owner' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Only group owners can change member roles');
    END IF;
    
    -- Cannot change owner role
    IF v_target_role = 'owner' OR p_new_role = 'owner' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Cannot change owner role');
    END IF;
    
    -- Set default permissions based on role
    v_default_permissions := CASE p_new_role
        WHEN 'admin' THEN '{
            "can_send_messages": true,
            "can_send_media": true,
            "can_invite_members": true,
            "can_remove_members": true,
            "can_edit_group": true,
            "can_manage_roles": false,
            "can_pin_messages": true,
            "can_delete_messages": true
        }'::jsonb
        WHEN 'moderator' THEN '{
            "can_send_messages": true,
            "can_send_media": true,
            "can_invite_members": true,
            "can_remove_members": false,
            "can_edit_group": false,
            "can_manage_roles": false,
            "can_pin_messages": true,
            "can_delete_messages": true
        }'::jsonb
        WHEN 'member' THEN '{
            "can_send_messages": true,
            "can_send_media": true,
            "can_invite_members": false,
            "can_remove_members": false,
            "can_edit_group": false,
            "can_manage_roles": false,
            "can_pin_messages": false,
            "can_delete_messages": false
        }'::jsonb
        ELSE '{
            "can_send_messages": false,
            "can_send_media": false,
            "can_invite_members": false,
            "can_remove_members": false,
            "can_edit_group": false,
            "can_manage_roles": false,
            "can_pin_messages": false,
            "can_delete_messages": false
        }'::jsonb
    END;
    
    -- Update member role and permissions
    UPDATE group_members 
    SET 
        role = p_new_role,
        permissions = COALESCE(p_custom_permissions, v_default_permissions),
        updated_at = NOW()
    WHERE group_id = p_group_id AND user_id = p_target_user_id;
    
    -- Log the action
    INSERT INTO group_moderation_logs (
        group_id, moderator_id, target_user_id, action_type, 
        reason, action_data
    ) VALUES (
        p_group_id, p_updater_id, p_target_user_id, 'edit_permissions',
        'Role changed from ' || v_target_role || ' to ' || p_new_role,
        jsonb_build_object('old_role', v_target_role, 'new_role', p_new_role)
    );
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Member role updated successfully',
        'old_role', v_target_role,
        'new_role', p_new_role
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Failed to update role: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create group invitation
CREATE OR REPLACE FUNCTION create_group_invitation(
    p_group_id UUID,
    p_inviter_id UUID,
    p_invitee_id UUID DEFAULT NULL,
    p_invitation_type VARCHAR(20) DEFAULT 'direct',
    p_message TEXT DEFAULT NULL,
    p_expires_hours INTEGER DEFAULT 168, -- 7 days
    p_max_uses INTEGER DEFAULT 1
) RETURNS JSONB AS $$
DECLARE
    v_invitation_id UUID;
    v_invitation_code VARCHAR(50);
    v_inviter_permissions JSONB;
BEGIN
    -- Check inviter permissions
    SELECT permissions INTO v_inviter_permissions 
    FROM group_members 
    WHERE group_id = p_group_id AND user_id = p_inviter_id AND is_active = true;
    
    IF NOT FOUND OR NOT (v_inviter_permissions->>'can_invite_members')::boolean THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient permissions to invite members');
    END IF;
    
    -- Generate invitation code for link invitations
    IF p_invitation_type = 'link' THEN
        v_invitation_code := 'group_' || SUBSTR(p_group_id::text, 1, 8) || '_' || 
                            SUBSTR(gen_random_uuid()::text, 1, 8);
    END IF;
    
    -- Create invitation
    INSERT INTO group_invitations (
        group_id, inviter_id, invitee_id, invitation_type, invitation_code,
        message, expires_at, max_uses
    ) VALUES (
        p_group_id, p_inviter_id, p_invitee_id, p_invitation_type, v_invitation_code,
        p_message, NOW() + (p_expires_hours || ' hours')::INTERVAL, p_max_uses
    ) RETURNING id INTO v_invitation_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'invitation_id', v_invitation_id,
        'invitation_code', v_invitation_code,
        'expires_at', NOW() + (p_expires_hours || ' hours')::INTERVAL,
        'message', 'Invitation created successfully'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Failed to create invitation: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to accept group invitation
CREATE OR REPLACE FUNCTION accept_group_invitation(
    p_invitation_id UUID DEFAULT NULL,
    p_invitation_code VARCHAR(50) DEFAULT NULL,
    p_user_id UUID DEFAULT NULL,
    p_response_message TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_invitation RECORD;
    v_add_result JSONB;
BEGIN
    -- Find invitation by ID or code
    IF p_invitation_id IS NOT NULL THEN
        SELECT * INTO v_invitation FROM group_invitations WHERE id = p_invitation_id;
    ELSIF p_invitation_code IS NOT NULL THEN
        SELECT * INTO v_invitation FROM group_invitations WHERE invitation_code = p_invitation_code;
    ELSE
        RETURN jsonb_build_object('success', false, 'error', 'No invitation identifier provided');
    END IF;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invitation not found');
    END IF;
    
    -- Check invitation status and expiry
    IF v_invitation.status != 'pending' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invitation is no longer valid');
    END IF;
    
    IF v_invitation.expires_at < NOW() THEN
        UPDATE group_invitations SET status = 'expired' WHERE id = v_invitation.id;
        RETURN jsonb_build_object('success', false, 'error', 'Invitation has expired');
    END IF;
    
    -- Check usage limits
    IF v_invitation.current_uses >= v_invitation.max_uses THEN
        UPDATE group_invitations SET status = 'expired' WHERE id = v_invitation.id;
        RETURN jsonb_build_object('success', false, 'error', 'Invitation has reached maximum usage');
    END IF;
    
    -- For direct invitations, validate invitee
    IF v_invitation.invitation_type = 'direct' AND v_invitation.invitee_id != p_user_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'This invitation is not for you');
    END IF;
    
    -- Add member to group
    v_add_result := add_group_member(
        v_invitation.group_id, 
        p_user_id, 
        v_invitation.inviter_id,
        'member',
        true -- skip permission check
    );
    
    IF NOT (v_add_result->>'success')::boolean THEN
        RETURN v_add_result;
    END IF;
    
    -- Update invitation
    UPDATE group_invitations 
    SET 
        status = 'accepted',
        current_uses = current_uses + 1,
        responded_at = NOW(),
        response_message = p_response_message
    WHERE id = v_invitation.id;
    
    RETURN jsonb_build_object(
        'success', true,
        'group_id', v_invitation.group_id,
        'message', 'Successfully joined the group'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Failed to accept invitation: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get group statistics
CREATE OR REPLACE FUNCTION get_group_statistics(p_group_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_stats JSONB;
    v_member_count INTEGER;
    v_active_today INTEGER;
    v_messages_today INTEGER;
    v_top_contributors JSONB;
BEGIN
    -- Get basic member count
    SELECT COUNT(*) INTO v_member_count 
    FROM group_members 
    WHERE group_id = p_group_id AND is_active = true;
    
    -- Get active members today
    SELECT COUNT(*) INTO v_active_today 
    FROM group_members 
    WHERE group_id = p_group_id 
      AND is_active = true 
      AND last_seen_at >= CURRENT_DATE;
    
    -- Get messages today
    SELECT COUNT(*) INTO v_messages_today 
    FROM messages m
    JOIN chats c ON m.chat_id = c.id
    WHERE c.id = p_group_id 
      AND DATE(m.timestamp) = CURRENT_DATE;
    
    -- Get top contributors this week
    SELECT jsonb_agg(
        jsonb_build_object(
            'user_id', gm.user_id,
            'message_count', gm.message_count,
            'reaction_count', gm.reaction_count
        )
    ) INTO v_top_contributors
    FROM (
        SELECT user_id, message_count, reaction_count
        FROM group_members 
        WHERE group_id = p_group_id AND is_active = true
        ORDER BY (message_count + reaction_count) DESC
        LIMIT 5
    ) gm;
    
    v_stats := jsonb_build_object(
        'total_members', v_member_count,
        'active_today', v_active_today,
        'messages_today', v_messages_today,
        'top_contributors', COALESCE(v_top_contributors, '[]'::jsonb),
        'generated_at', NOW()
    );
    
    RETURN v_stats;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'error', 'Failed to generate statistics: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
