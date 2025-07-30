-- =====================================================
-- CRYSTAL SOCIAL - CHAT SYSTEM VIEWS
-- =====================================================
-- Optimized views for common chat queries and analytics
-- =====================================================

-- ===== COMPREHENSIVE CHAT LIST VIEW =====

CREATE OR REPLACE VIEW chat_list_view AS
SELECT DISTINCT
    c.id as chat_id,
    c.name as chat_name,
    c.chat_type,
    c.is_group,
    c.is_private,
    c.background_url as chat_background_url,
    c.theme as chat_theme,
    c.created_at as chat_created_at,
    c.updated_at as chat_updated_at,
    c.last_message_at,
    c.message_count as total_messages,
    
    -- Participant info
    cp.user_id as current_user_id,
    cp.role as current_user_role,
    cp.joined_at as current_user_joined_at,
    cp.is_muted as is_muted_by_user,
    cp.is_pinned as is_pinned_by_user,
    cp.last_read_at as current_user_last_read_at,
    cp.notification_settings as current_user_notifications,
    cp.custom_nickname as current_user_nickname,
    
    -- Last message info
    lm.id as last_message_id,
    lm.content as last_message_content,
    lm.message_type as last_message_type,
    lm.created_at as last_message_created_at,
    lm.sender_id as last_message_sender_id,
    lm_sender.username as last_message_sender_username,
    lm_sender.avatar_url as last_message_sender_avatar,
    
    -- Unread count for current user
    COALESCE(unread_counts.unread_count, 0) as unread_count,
    
    -- Participant count
    participant_counts.participant_count,
    
    -- For direct chats: other participant info
    CASE 
        WHEN NOT c.is_group THEN other_participant.user_id 
        ELSE NULL 
    END as other_participant_id,
    CASE 
        WHEN NOT c.is_group THEN other_participant.username 
        ELSE NULL 
    END as other_participant_username,
    CASE 
        WHEN NOT c.is_group THEN other_participant.avatar_url 
        ELSE NULL 
    END as other_participant_avatar_url,
    CASE 
        WHEN NOT c.is_group THEN other_participant.bio 
        ELSE NULL 
    END as other_participant_bio,
    CASE 
        WHEN NOT c.is_group THEN other_participant_cp.custom_nickname 
        ELSE NULL 
    END as other_participant_nickname,
    
    -- Recent activity indicators
    CASE 
        WHEN c.last_message_at > NOW() - INTERVAL '1 hour' THEN true 
        ELSE false 
    END as has_recent_activity,
    
    -- Online status for direct chats
    CASE 
        WHEN NOT c.is_group THEN NULL 
        ELSE NULL 
    END as other_participant_online

FROM chats c
JOIN chat_participants cp ON c.id = cp.chat_id AND cp.is_active = true

-- Get last message
LEFT JOIN LATERAL (
    SELECT m.*
    FROM messages m
    WHERE m.chat_id = c.id AND m.is_deleted = false
    ORDER BY m.created_at DESC
    LIMIT 1
) lm ON true

-- Get last message sender info
LEFT JOIN profiles lm_sender ON lm.sender_id = lm_sender.id

-- Get unread count
LEFT JOIN LATERAL (
    SELECT COUNT(*) as unread_count
    FROM messages m
    LEFT JOIN message_delivery_status mds ON (
        mds.message_id = m.id AND mds.user_id = cp.user_id
    )
    WHERE m.chat_id = c.id 
    AND m.sender_id != cp.user_id
    AND m.is_deleted = false
    AND (mds.status IS NULL OR mds.status != 'read')
    AND m.created_at > cp.last_read_at
) unread_counts ON true

-- Get participant count
LEFT JOIN LATERAL (
    SELECT COUNT(*) as participant_count
    FROM chat_participants cp2
    WHERE cp2.chat_id = c.id AND cp2.is_active = true
) participant_counts ON true

-- For direct chats: get other participant info
LEFT JOIN LATERAL (
    SELECT cp2.user_id, p.username, p.avatar_url, p.bio, cp2.custom_nickname
    FROM chat_participants cp2
    JOIN profiles p ON cp2.user_id = p.id
    WHERE cp2.chat_id = c.id 
    AND cp2.user_id != cp.user_id 
    AND cp2.is_active = true
    AND NOT c.is_group
    LIMIT 1
) other_participant ON true

-- Get other participant's settings
LEFT JOIN chat_participants other_participant_cp ON (
    other_participant_cp.chat_id = c.id 
    AND other_participant_cp.user_id = other_participant.user_id
    AND NOT c.is_group
)

WHERE c.is_active = true;

-- ===== MESSAGE DETAILS VIEW =====

CREATE OR REPLACE VIEW message_details_view AS
SELECT 
    m.id as message_id,
    m.chat_id,
    m.sender_id,
    p.username as sender_username,
    p.avatar_url as sender_avatar_url,
    p.display_name as sender_display_name,
    
    -- Message content
    m.content,
    m.message_type,
    m.image_url,
    m.video_url,
    m.audio_url,
    m.file_url,
    m.sticker_url,
    m.gif_url,
    m.file_name,
    m.file_size,
    m.file_type,
    
    -- Timestamps
    m.created_at,
    m.updated_at,
    m.edited_at,
    m.is_edited,
    m.is_deleted,
    
    -- Message status
    m.status,
    m.delivered_at,
    m.read_at,
    
    -- Reply information
    m.reply_to_message_id,
    m.reply_to_content,
    m.reply_to_username,
    
    -- Special features
    m.is_forwarded,
    m.forward_count,
    m.is_important,
    m.is_secret,
    m.expires_at,
    
    -- Rich content
    m.mentions,
    m.hashtags,
    m.metadata,
    
    -- Visual effects
    m.effect,
    m.mood,
    m.aura_color,
    
    -- Location data
    m.latitude,
    m.longitude,
    m.location_name,
    
    -- Poll data
    m.poll_question,
    m.poll_options,
    m.poll_results,
    m.poll_expires_at,
    m.poll_multiple_choice,
    
    -- Contact data
    m.contact_name,
    m.contact_phone,
    m.contact_email,
    
    -- Aggregated reactions
    COALESCE(
        (SELECT jsonb_object_agg(
            reaction_type, 
            jsonb_build_object(
                'count', count,
                'users', users
            )
        )
        FROM (
            SELECT 
                mr.reaction_type,
                COUNT(*) as count,
                jsonb_agg(
                    jsonb_build_object(
                        'user_id', mr.user_id,
                        'username', rp.username,
                        'avatar_url', rp.avatar_url,
                        'created_at', mr.created_at
                    )
                ) as users
            FROM message_reactions mr
            JOIN profiles rp ON mr.user_id = rp.id
            WHERE mr.message_id = m.id
            GROUP BY mr.reaction_type
        ) reactions_agg),
        '{}'::jsonb
    ) as reactions,
    
    -- Delivery status summary
    COALESCE(
        (SELECT jsonb_object_agg(
            status,
            count
        )
        FROM (
            SELECT 
                mds.status,
                COUNT(*) as count
            FROM message_delivery_status mds
            WHERE mds.message_id = m.id
            GROUP BY mds.status
        ) delivery_agg),
        '{}'::jsonb
    ) as delivery_summary

FROM messages m
JOIN profiles p ON m.sender_id = p.id
WHERE m.is_deleted = false;

-- ===== CHAT ANALYTICS VIEW =====

CREATE OR REPLACE VIEW chat_analytics_view AS
SELECT 
    c.id as chat_id,
    c.name as chat_name,
    c.chat_type,
    c.is_group,
    c.created_at as chat_created_at,
    
    -- Message statistics
    COUNT(DISTINCT m.id) as total_messages,
    COUNT(DISTINCT CASE WHEN m.message_type IN ('image', 'video', 'audio', 'file', 'gif') THEN m.id END) as media_messages,
    COUNT(DISTINCT CASE WHEN m.message_type = 'text' THEN m.id END) as text_messages,
    
    -- Participant statistics
    COUNT(DISTINCT cp.user_id) as total_participants,
    COUNT(DISTINCT CASE WHEN cp.is_active = true THEN cp.user_id END) as active_participants,
    
    -- Activity statistics
    COUNT(DISTINCT DATE(m.created_at)) as active_days,
    COUNT(DISTINCT CASE 
        WHEN m.created_at > NOW() - INTERVAL '7 days' 
        THEN m.sender_id 
    END) as active_users_last_7_days,
    COUNT(DISTINCT CASE 
        WHEN m.created_at > NOW() - INTERVAL '1 day' 
        THEN m.sender_id 
    END) as active_users_last_24_hours,
    
    -- Message frequency
    CASE 
        WHEN c.created_at > NOW() - INTERVAL '1 day' THEN 
            COUNT(DISTINCT m.id) / GREATEST(EXTRACT(EPOCH FROM (NOW() - c.created_at)) / 3600, 1)
        ELSE 
            COUNT(DISTINCT m.id) / GREATEST(EXTRACT(EPOCH FROM (NOW() - c.created_at)) / 86400, 1)
    END as messages_per_day_avg,
    
    -- Reaction statistics
    COUNT(DISTINCT mr.id) as total_reactions,
    COUNT(DISTINCT mr.user_id) as users_who_reacted,
    
    -- Recent activity
    MAX(m.created_at) as last_activity,
    COUNT(CASE WHEN m.created_at > NOW() - INTERVAL '1 hour' THEN 1 END) as messages_last_hour,
    COUNT(CASE WHEN m.created_at > NOW() - INTERVAL '1 day' THEN 1 END) as messages_last_day,
    COUNT(CASE WHEN m.created_at > NOW() - INTERVAL '7 days' THEN 1 END) as messages_last_week

FROM chats c
LEFT JOIN chat_participants cp ON c.id = cp.chat_id
LEFT JOIN messages m ON c.id = m.chat_id AND m.is_deleted = false
LEFT JOIN message_reactions mr ON m.id = mr.message_id
WHERE c.is_active = true
GROUP BY c.id, c.name, c.chat_type, c.is_group, c.created_at;

-- ===== USER CHAT ACTIVITY VIEW =====

CREATE OR REPLACE VIEW user_chat_activity_view AS
SELECT 
    cp.user_id,
    p.username,
    p.avatar_url,
    cp.chat_id,
    c.name as chat_name,
    c.chat_type,
    
    -- User's role and status in chat
    cp.role,
    cp.is_active,
    cp.is_muted,
    cp.is_pinned,
    cp.joined_at,
    cp.left_at,
    cp.last_read_at,
    
    -- Message statistics for this user in this chat
    COUNT(DISTINCT m.id) as messages_sent,
    COUNT(DISTINCT CASE WHEN m.message_type IN ('image', 'video', 'audio', 'file', 'gif') THEN m.id END) as media_shared,
    COUNT(DISTINCT mr_given.id) as reactions_given,
    COUNT(DISTINCT mr_received.id) as reactions_received,
    
    -- Recent activity
    MAX(m.created_at) as last_message_at,
    COUNT(CASE WHEN m.created_at > NOW() - INTERVAL '1 day' THEN 1 END) as messages_last_day,
    COUNT(CASE WHEN m.created_at > NOW() - INTERVAL '7 days' THEN 1 END) as messages_last_week,
    
    -- Unread messages for this user in this chat
    COUNT(DISTINCT unread_messages.id) as unread_count

FROM chat_participants cp
JOIN profiles p ON cp.user_id = p.id
JOIN chats c ON cp.chat_id = c.id
LEFT JOIN messages m ON (cp.chat_id = m.chat_id AND cp.user_id = m.sender_id AND m.is_deleted = false)
LEFT JOIN message_reactions mr_given ON (m.id = mr_given.message_id AND cp.user_id = mr_given.user_id)
LEFT JOIN message_reactions mr_received ON (m.sender_id = cp.user_id AND mr_received.message_id = m.id)
LEFT JOIN LATERAL (
    SELECT m2.id
    FROM messages m2
    LEFT JOIN message_delivery_status mds ON (mds.message_id = m2.id AND mds.user_id = cp.user_id)
    WHERE m2.chat_id = cp.chat_id 
    AND m2.sender_id != cp.user_id
    AND m2.is_deleted = false
    AND (mds.status IS NULL OR mds.status != 'read')
    AND m2.created_at > cp.last_read_at
) unread_messages ON true

WHERE c.is_active = true
GROUP BY 
    cp.user_id, p.username, p.avatar_url, cp.chat_id, c.name, c.chat_type,
    cp.role, cp.is_active, cp.is_muted, cp.is_pinned, 
    cp.joined_at, cp.left_at, cp.last_read_at;

-- ===== TRENDING CONTENT VIEW =====

CREATE OR REPLACE VIEW trending_content_view AS
SELECT 
    'hashtag' as content_type,
    hashtag as content,
    COUNT(DISTINCT m.id) as usage_count,
    COUNT(DISTINCT m.chat_id) as chat_count,
    COUNT(DISTINCT m.sender_id) as user_count,
    MAX(m.created_at) as last_used,
    COUNT(CASE WHEN m.created_at > NOW() - INTERVAL '24 hours' THEN 1 END) as usage_last_24h,
    COUNT(CASE WHEN m.created_at > NOW() - INTERVAL '7 days' THEN 1 END) as usage_last_7d
FROM messages m
CROSS JOIN LATERAL unnest(m.hashtags) as hashtag
WHERE m.is_deleted = false 
AND m.created_at > NOW() - INTERVAL '30 days'
GROUP BY hashtag

UNION ALL

SELECT 
    'mention' as content_type,
    mention as content,
    COUNT(DISTINCT m.id) as usage_count,
    COUNT(DISTINCT m.chat_id) as chat_count,
    COUNT(DISTINCT m.sender_id) as user_count,
    MAX(m.created_at) as last_used,
    COUNT(CASE WHEN m.created_at > NOW() - INTERVAL '24 hours' THEN 1 END) as usage_last_24h,
    COUNT(CASE WHEN m.created_at > NOW() - INTERVAL '7 days' THEN 1 END) as usage_last_7d
FROM messages m
CROSS JOIN LATERAL unnest(m.mentions) as mention
WHERE m.is_deleted = false 
AND m.created_at > NOW() - INTERVAL '30 days'
GROUP BY mention

ORDER BY usage_last_7d DESC, usage_count DESC;

-- ===== SHARED MEDIA SUMMARY VIEW =====

CREATE OR REPLACE VIEW shared_media_summary_view AS
SELECT 
    sm.chat_id,
    c.name as chat_name,
    sm.media_type,
    COUNT(*) as media_count,
    SUM(sm.file_size) as total_size_bytes,
    MIN(sm.created_at) as first_shared,
    MAX(sm.created_at) as last_shared,
    COUNT(DISTINCT sm.user_id) as unique_sharers,
    
    -- Recent activity
    COUNT(CASE WHEN sm.created_at > NOW() - INTERVAL '7 days' THEN 1 END) as shared_last_7d,
    COUNT(CASE WHEN sm.created_at > NOW() - INTERVAL '30 days' THEN 1 END) as shared_last_30d

FROM shared_media sm
JOIN chats c ON sm.chat_id = c.id
WHERE c.is_active = true
GROUP BY sm.chat_id, c.name, sm.media_type
ORDER BY sm.chat_id, sm.media_type;

-- ===== PERFORMANCE INDEXES FOR VIEWS =====

-- Indexes to optimize view performance
CREATE INDEX IF NOT EXISTS idx_chat_list_view_user_active 
ON chat_participants(user_id, is_active, last_read_at);

CREATE INDEX IF NOT EXISTS idx_message_details_view_chat_created 
ON messages(chat_id, created_at DESC, is_deleted);

CREATE INDEX IF NOT EXISTS idx_analytics_view_created_deleted 
ON messages(created_at, is_deleted, message_type);

CREATE INDEX IF NOT EXISTS idx_trending_content_hashtags 
ON messages USING gin(hashtags) WHERE is_deleted = false;

CREATE INDEX IF NOT EXISTS idx_trending_content_mentions 
ON messages USING gin(mentions) WHERE is_deleted = false;

-- =====================================================
-- VIEW DOCUMENTATION
-- =====================================================

COMMENT ON VIEW chat_list_view IS 'Comprehensive chat list with participant info, unread counts, and last message details';
COMMENT ON VIEW message_details_view IS 'Complete message information with sender details and aggregated reactions';
COMMENT ON VIEW chat_analytics_view IS 'Chat-level analytics including message counts, activity metrics, and engagement stats';
COMMENT ON VIEW user_chat_activity_view IS 'Per-user activity statistics within each chat';
COMMENT ON VIEW trending_content_view IS 'Trending hashtags and mentions across all chats';
COMMENT ON VIEW shared_media_summary_view IS 'Summary of shared media by chat and type with size and frequency stats';

-- Grant access to views
GRANT SELECT ON chat_list_view TO authenticated;
GRANT SELECT ON message_details_view TO authenticated;
GRANT SELECT ON chat_analytics_view TO authenticated;
GRANT SELECT ON user_chat_activity_view TO authenticated;
GRANT SELECT ON trending_content_view TO authenticated;
GRANT SELECT ON shared_media_summary_view TO authenticated;
