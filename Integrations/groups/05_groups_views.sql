-- =====================================================
-- CRYSTAL SOCIAL - GROUPS SYSTEM VIEWS
-- =====================================================
-- Optimized views for group operations and analytics
-- =====================================================

-- Comprehensive group overview with member and activity stats
CREATE OR REPLACE VIEW group_overview AS
SELECT 
    gd.chat_id as group_id,
    gd.display_name,
    gd.description,
    gd.emoji,
    gd.banner_url,
    gd.icon_url,
    gd.is_public,
    gd.is_discoverable,
    gd.category,
    gd.tags,
    gd.max_members,
    gd.total_messages,
    gd.active_members_count,
    gd.last_activity_at,
    gd.created_at,
    
    -- Owner information
    owner_profile.username as owner_username,
    owner_profile.avatar_url as owner_avatar,
    
    -- Activity metrics
    CASE 
        WHEN gd.last_activity_at > NOW() - INTERVAL '1 hour' THEN 'very_active'
        WHEN gd.last_activity_at > NOW() - INTERVAL '24 hours' THEN 'active'
        WHEN gd.last_activity_at > NOW() - INTERVAL '7 days' THEN 'moderate'
        ELSE 'inactive'
    END as activity_level,
    
    -- Member statistics
    (SELECT COUNT(*) FROM group_members WHERE group_id = gd.chat_id AND role = 'admin') as admin_count,
    (SELECT COUNT(*) FROM group_members WHERE group_id = gd.chat_id AND role = 'moderator') as moderator_count,
    (SELECT COUNT(*) FROM group_members WHERE group_id = gd.chat_id AND last_seen_at > NOW() - INTERVAL '24 hours') as active_today,
    (SELECT COUNT(*) FROM group_members WHERE group_id = gd.chat_id AND last_seen_at > NOW() - INTERVAL '7 days') as active_week,
    
    -- Recent activity
    (SELECT COUNT(*) FROM messages m JOIN chats c ON m.chat_id = c.id 
     WHERE c.id = gd.chat_id AND m.created_at > NOW() - INTERVAL '24 hours') as messages_today,
    (SELECT COUNT(*) FROM messages m JOIN chats c ON m.chat_id = c.id 
     WHERE c.id = gd.chat_id AND m.created_at > NOW() - INTERVAL '7 days') as messages_week,
    
    -- Latest announcement
    (SELECT title FROM group_announcements WHERE group_id = gd.chat_id AND is_pinned = true 
     ORDER BY published_at DESC LIMIT 1) as latest_announcement,
    
    -- Upcoming events
    (SELECT COUNT(*) FROM group_events WHERE group_id = gd.chat_id AND start_time > NOW() AND status = 'scheduled') as upcoming_events

FROM group_details gd
LEFT JOIN group_members gm_owner ON gd.chat_id = gm_owner.group_id AND gm_owner.role = 'owner'
LEFT JOIN auth.users owner ON gm_owner.user_id = owner.id
LEFT JOIN profiles owner_profile ON gm_owner.user_id = owner_profile.id;

-- Group member details with roles and activity
CREATE OR REPLACE VIEW group_member_details AS
SELECT 
    gm.id,
    gm.group_id,
    gm.user_id,
    gm.role,
    gm.permissions,
    gm.is_active,
    gm.is_muted,
    gm.is_banned,
    gm.muted_until,
    gm.ban_reason,
    gm.last_seen_at,
    gm.message_count,
    gm.reaction_count,
    gm.invited_by,
    gm.invited_at,
    gm.joined_at,
    gm.left_at,
    
    -- User information
    p.username,
    p.avatar_url,
    u.email as user_email,
    
    -- Activity metrics
    CASE 
        WHEN gm.last_seen_at > NOW() - INTERVAL '5 minutes' THEN 'online'
        WHEN gm.last_seen_at > NOW() - INTERVAL '1 hour' THEN 'recently_active'
        WHEN gm.last_seen_at > NOW() - INTERVAL '24 hours' THEN 'today'
        WHEN gm.last_seen_at > NOW() - INTERVAL '7 days' THEN 'this_week'
        ELSE 'inactive'
    END as activity_status,
    
    -- Engagement score
    (gm.message_count + gm.reaction_count) as engagement_score,
    
    -- Tenure
    EXTRACT(DAYS FROM NOW() - gm.joined_at) as days_in_group,
    
    -- Inviter information
    inviter_profile.username as inviter_username,
    
    -- Group information
    gd.display_name as group_name,
    gd.category as group_category

FROM group_members gm
JOIN auth.users u ON gm.user_id = u.id
JOIN profiles p ON gm.user_id = p.id
LEFT JOIN auth.users inviter ON gm.invited_by = inviter.id
LEFT JOIN profiles inviter_profile ON gm.invited_by = inviter_profile.id
LEFT JOIN group_details gd ON gm.group_id = gd.chat_id
WHERE gm.is_active = true;

-- Active group invitations with metadata
CREATE OR REPLACE VIEW active_group_invitations AS
SELECT 
    gi.id,
    gi.group_id,
    gi.inviter_id,
    gi.invitee_id,
    gi.invitation_type,
    gi.invitation_code,
    gi.message,
    gi.status,
    gi.expires_at,
    gi.max_uses,
    gi.current_uses,
    gi.created_at,
    
    -- Group information
    gd.display_name as group_name,
    gd.emoji as group_emoji,
    gd.active_members_count,
    gd.is_public,
    
    -- Inviter information
    inviter_profile.username as inviter_username,
    inviter_profile.avatar_url as inviter_avatar,
    
    -- Invitee information (for direct invitations)
    invitee_profile.username as invitee_username,
    invitee_profile.avatar_url as invitee_avatar,
    
    -- Expiry status
    CASE 
        WHEN gi.expires_at < NOW() THEN true
        ELSE false
    END as is_expired,
    
    -- Time remaining
    EXTRACT(HOURS FROM gi.expires_at - NOW()) as hours_remaining,
    
    -- Usage status
    CASE 
        WHEN gi.current_uses >= gi.max_uses THEN 'exhausted'
        WHEN gi.current_uses > 0 THEN 'partially_used'
        ELSE 'unused'
    END as usage_status

FROM group_invitations gi
JOIN group_details gd ON gi.group_id = gd.chat_id
LEFT JOIN auth.users inviter ON gi.inviter_id = inviter.id
LEFT JOIN profiles inviter_profile ON gi.inviter_id = inviter_profile.id
LEFT JOIN auth.users invitee ON gi.invitee_id = invitee.id
LEFT JOIN profiles invitee_profile ON gi.invitee_id = invitee_profile.id
WHERE gi.status = 'pending' AND gi.expires_at > NOW();

-- Group events with attendance information
CREATE OR REPLACE VIEW group_events_with_attendance AS
SELECT 
    ge.id,
    ge.group_id,
    ge.organizer_id,
    ge.title,
    ge.description,
    ge.event_type,
    ge.location,
    ge.virtual_link,
    ge.start_time,
    ge.end_time,
    ge.timezone,
    ge.max_attendees,
    ge.is_recurring,
    ge.requires_approval,
    ge.status,
    ge.attendee_count,
    ge.interested_count,
    ge.created_at,
    
    -- Group information
    gd.display_name as group_name,
    gd.emoji as group_emoji,
    
    -- Organizer information
    organizer_profile.username as organizer_username,
    organizer_profile.avatar_url as organizer_avatar,
    
    -- Event timing
    CASE 
        WHEN ge.start_time > NOW() THEN 'upcoming'
        WHEN ge.start_time <= NOW() AND (ge.end_time IS NULL OR ge.end_time > NOW()) THEN 'ongoing'
        WHEN ge.end_time <= NOW() THEN 'completed'
    END as event_timing,
    
    -- Time calculations
    EXTRACT(HOURS FROM ge.start_time - NOW()) as hours_until_start,
    CASE 
        WHEN ge.end_time IS NOT NULL THEN EXTRACT(HOURS FROM ge.end_time - ge.start_time)
        ELSE NULL
    END as duration_hours,
    
    -- Availability
    CASE 
        WHEN ge.max_attendees IS NOT NULL THEN ge.max_attendees - ge.attendee_count
        ELSE NULL
    END as spots_available,
    
    -- Attendance percentage
    CASE 
        WHEN gd.active_members_count > 0 THEN 
            ROUND((ge.attendee_count * 100.0) / gd.active_members_count, 2)
        ELSE 0
    END as attendance_percentage

FROM group_events ge
JOIN group_details gd ON ge.group_id = gd.chat_id
LEFT JOIN auth.users organizer ON ge.organizer_id = organizer.id
LEFT JOIN profiles organizer_profile ON ge.organizer_id = organizer_profile.id;

-- Group analytics dashboard view
CREATE OR REPLACE VIEW group_analytics_dashboard AS
SELECT 
    ga.group_id,
    ga.date,
    ga.messages_sent,
    ga.unique_active_members,
    ga.new_members,
    ga.members_left,
    ga.reactions_given,
    ga.media_shared,
    ga.events_created,
    ga.announcements_made,
    ga.total_members,
    ga.active_members_7d,
    ga.retention_rate,
    
    -- Group information
    gd.display_name as group_name,
    gd.category,
    
    -- Calculated metrics
    CASE 
        WHEN ga.total_members > 0 THEN 
            ROUND((ga.unique_active_members * 100.0) / ga.total_members, 2)
        ELSE 0
    END as daily_activity_rate,
    
    CASE 
        WHEN ga.unique_active_members > 0 THEN 
            ROUND(ga.messages_sent::DECIMAL / ga.unique_active_members, 2)
        ELSE 0
    END as messages_per_active_member,
    
    -- Growth metrics
    (ga.new_members - ga.members_left) as net_member_growth,
    
    -- Weekly comparisons (compare with same day previous week)
    LAG(ga.messages_sent, 7) OVER (
        PARTITION BY ga.group_id ORDER BY ga.date
    ) as messages_sent_week_ago,
    
    LAG(ga.unique_active_members, 7) OVER (
        PARTITION BY ga.group_id ORDER BY ga.date
    ) as active_members_week_ago,
    
    -- Moving averages (7-day)
    AVG(ga.messages_sent) OVER (
        PARTITION BY ga.group_id 
        ORDER BY ga.date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as messages_7d_avg,
    
    AVG(ga.unique_active_members) OVER (
        PARTITION BY ga.group_id 
        ORDER BY ga.date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as active_members_7d_avg

FROM group_analytics ga
JOIN group_details gd ON ga.group_id = gd.chat_id
ORDER BY ga.group_id, ga.date DESC;

-- Group moderation summary
CREATE OR REPLACE VIEW group_moderation_summary AS
SELECT 
    gml.group_id,
    
    -- Group information
    gd.display_name as group_name,
    
    -- Moderation statistics
    COUNT(*) as total_actions,
    COUNT(*) FILTER (WHERE gml.action_type = 'warn') as warnings,
    COUNT(*) FILTER (WHERE gml.action_type = 'mute') as mutes,
    COUNT(*) FILTER (WHERE gml.action_type = 'kick') as kicks,
    COUNT(*) FILTER (WHERE gml.action_type = 'ban') as bans,
    COUNT(*) FILTER (WHERE gml.action_type = 'delete_message') as message_deletions,
    
    -- Recent activity (last 7 days)
    COUNT(*) FILTER (WHERE gml.created_at > NOW() - INTERVAL '7 days') as actions_last_7d,
    COUNT(*) FILTER (WHERE gml.created_at > NOW() - INTERVAL '24 hours') as actions_last_24h,
    
    -- Active moderation
    COUNT(*) FILTER (WHERE gml.is_active = true) as active_actions,
    
    -- Most recent action
    MAX(gml.created_at) as last_action_at,
    
    -- Most active moderators
    (SELECT jsonb_agg(
        jsonb_build_object(
            'moderator_id', top_mods.moderator_id,
            'username', top_mods.username,
            'action_count', top_mods.action_count
        )
    ) FROM (
        SELECT 
            gml2.moderator_id,
            p.username,
            COUNT(*) as action_count
        FROM group_moderation_logs gml2
        JOIN auth.users u ON gml2.moderator_id = u.id
        JOIN profiles p ON gml2.moderator_id = p.id
        WHERE gml2.group_id = gml.group_id
          AND gml2.created_at > NOW() - INTERVAL '30 days'
        GROUP BY gml2.moderator_id, p.username
        ORDER BY action_count DESC
        LIMIT 3
    ) top_mods) as top_moderators

FROM group_moderation_logs gml
JOIN group_details gd ON gml.group_id = gd.chat_id
GROUP BY gml.group_id, gd.display_name;

-- Public groups discovery view
CREATE OR REPLACE VIEW public_groups_discovery AS
SELECT 
    gd.chat_id as group_id,
    gd.display_name,
    gd.description,
    gd.emoji,
    gd.banner_url,
    gd.category,
    gd.tags,
    gd.active_members_count,
    gd.max_members,
    gd.last_activity_at,
    gd.created_at,
    
    -- Owner information (limited)
    owner_profile.username as owner_username,
    
    -- Activity level
    CASE 
        WHEN gd.last_activity_at > NOW() - INTERVAL '1 hour' THEN 'very_active'
        WHEN gd.last_activity_at > NOW() - INTERVAL '24 hours' THEN 'active'
        WHEN gd.last_activity_at > NOW() - INTERVAL '7 days' THEN 'moderate'
        ELSE 'inactive'
    END as activity_level,
    
    -- Capacity status
    CASE 
        WHEN gd.active_members_count >= gd.max_members THEN 'full'
        WHEN gd.active_members_count >= (gd.max_members * 0.8) THEN 'nearly_full'
        ELSE 'open'
    END as capacity_status,
    
    -- Member growth (last 7 days)
    (SELECT COALESCE(SUM(new_members - members_left), 0) 
     FROM group_analytics 
     WHERE group_id = gd.chat_id 
       AND date >= CURRENT_DATE - INTERVAL '7 days') as growth_last_7d,
    
    -- Recent activity metrics
    (SELECT COUNT(*) FROM messages m JOIN chats c ON m.chat_id = c.id 
     WHERE c.id = gd.chat_id AND m.created_at > NOW() - INTERVAL '24 hours') as messages_today,
    
    -- Member engagement score
    CASE 
        WHEN gd.active_members_count > 0 THEN 
            (SELECT AVG(message_count + reaction_count) 
             FROM group_members 
             WHERE group_id = gd.chat_id AND is_active = true)
        ELSE 0
    END as avg_member_engagement

FROM group_details gd
LEFT JOIN group_members gm_owner ON gd.chat_id = gm_owner.group_id AND gm_owner.role = 'owner'
LEFT JOIN auth.users owner ON gm_owner.user_id = owner.id
LEFT JOIN profiles owner_profile ON gm_owner.user_id = owner_profile.id
WHERE gd.is_public = true AND gd.is_discoverable = true
ORDER BY gd.active_members_count DESC, gd.last_activity_at DESC;

-- User's group membership summary
CREATE OR REPLACE VIEW user_group_memberships AS
SELECT 
    gm.user_id,
    gm.group_id,
    gm.role,
    gm.is_muted,
    gm.last_seen_at,
    gm.message_count,
    gm.reaction_count,
    gm.joined_at,
    
    -- Group information
    gd.display_name as group_name,
    gd.emoji as group_emoji,
    gd.category,
    gd.is_public,
    gd.active_members_count,
    gd.last_activity_at as group_last_activity,
    
    -- Activity level in this group
    CASE 
        WHEN gm.last_seen_at > NOW() - INTERVAL '5 minutes' THEN 'online'
        WHEN gm.last_seen_at > NOW() - INTERVAL '1 hour' THEN 'recently_active'
        WHEN gm.last_seen_at > NOW() - INTERVAL '24 hours' THEN 'today'
        WHEN gm.last_seen_at > NOW() - INTERVAL '7 days' THEN 'this_week'
        ELSE 'inactive'
    END as activity_status,
    
    -- Permissions summary
    (gm.permissions->>'can_send_messages')::boolean as can_send_messages,
    (gm.permissions->>'can_invite_members')::boolean as can_invite_members,
    (gm.permissions->>'can_edit_group')::boolean as can_edit_group,
    
    -- Engagement metrics
    (gm.message_count + gm.reaction_count) as total_engagement,
    EXTRACT(DAYS FROM NOW() - gm.joined_at) as days_in_group,
    
    -- Group health indicators
    CASE 
        WHEN gd.last_activity_at > NOW() - INTERVAL '24 hours' THEN 'healthy'
        WHEN gd.last_activity_at > NOW() - INTERVAL '7 days' THEN 'moderate'
        ELSE 'inactive'
    END as group_health,
    
    -- Unread indicators (would need to be calculated based on last seen vs latest messages)
    (SELECT COUNT(*) FROM messages m JOIN chats c ON m.chat_id = c.id 
     WHERE c.id = gm.group_id AND m.created_at > gm.last_seen_at) as unread_messages

FROM group_members gm
JOIN group_details gd ON gm.group_id = gd.chat_id
WHERE gm.is_active = true
ORDER BY gm.last_seen_at DESC;
