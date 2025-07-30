-- =====================================================
-- CRYSTAL SOCIAL - CHAT SYSTEM FUNCTIONS
-- =====================================================
-- Stored functions for chat operations and business logic
-- =====================================================

-- Function to create a new chat
CREATE OR REPLACE FUNCTION create_chat(
    p_creator_id UUID,
    p_name VARCHAR DEFAULT NULL,
    p_chat_type VARCHAR DEFAULT 'direct',
    p_is_group BOOLEAN DEFAULT false,
    p_participant_ids UUID[] DEFAULT ARRAY[]::UUID[]
) RETURNS UUID AS $$
DECLARE
    v_chat_id UUID;
    v_participant_id UUID;
BEGIN
    -- Create the chat
    INSERT INTO chats (
        name, 
        chat_type, 
        is_group, 
        created_by,
        max_participants
    ) VALUES (
        p_name, 
        p_chat_type, 
        p_is_group,
        p_creator_id,
        CASE WHEN p_is_group THEN 100 ELSE 2 END
    ) RETURNING id INTO v_chat_id;
    
    -- Add creator as owner
    INSERT INTO chat_participants (chat_id, user_id, role)
    VALUES (v_chat_id, p_creator_id, 'owner');
    
    -- Add other participants
    FOREACH v_participant_id IN ARRAY p_participant_ids
    LOOP
        IF v_participant_id != p_creator_id THEN
            INSERT INTO chat_participants (chat_id, user_id, role)
            VALUES (v_chat_id, v_participant_id, 'member');
        END IF;
    END LOOP;
    
    RETURN v_chat_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to send a message
CREATE OR REPLACE FUNCTION send_message(
    p_chat_id UUID,
    p_sender_id UUID,
    p_content TEXT DEFAULT NULL,
    p_message_type VARCHAR DEFAULT 'text',
    p_reply_to_message_id UUID DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'::jsonb
) RETURNS UUID AS $$
DECLARE
    v_message_id UUID;
    v_participant_exists BOOLEAN;
BEGIN
    -- Check if sender is a participant
    SELECT EXISTS(
        SELECT 1 FROM chat_participants 
        WHERE chat_id = p_chat_id 
        AND user_id = p_sender_id 
        AND is_active = true
    ) INTO v_participant_exists;
    
    IF NOT v_participant_exists THEN
        RAISE EXCEPTION 'User is not a participant in this chat';
    END IF;
    
    -- Insert the message
    INSERT INTO messages (
        chat_id,
        sender_id,
        content,
        message_type,
        reply_to_message_id,
        metadata
    ) VALUES (
        p_chat_id,
        p_sender_id,
        p_content,
        p_message_type,
        p_reply_to_message_id,
        p_metadata
    ) RETURNING id INTO v_message_id;
    
    -- Update chat's last message timestamp and count
    UPDATE chats 
    SET 
        last_message_at = NOW(),
        message_count = message_count + 1,
        updated_at = NOW()
    WHERE id = p_chat_id;
    
    -- Update search vector
    UPDATE messages 
    SET search_vector = to_tsvector('english', COALESCE(content, ''))
    WHERE id = v_message_id;
    
    RETURN v_message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to add reaction to message
CREATE OR REPLACE FUNCTION add_message_reaction(
    p_message_id UUID,
    p_user_id UUID,
    p_reaction_type VARCHAR
) RETURNS BOOLEAN AS $$
DECLARE
    v_chat_id UUID;
    v_participant_exists BOOLEAN;
BEGIN
    -- Get chat ID and check participation
    SELECT m.chat_id INTO v_chat_id
    FROM messages m
    WHERE m.id = p_message_id;
    
    IF v_chat_id IS NULL THEN
        RAISE EXCEPTION 'Message not found';
    END IF;
    
    SELECT EXISTS(
        SELECT 1 FROM chat_participants 
        WHERE chat_id = v_chat_id 
        AND user_id = p_user_id 
        AND is_active = true
    ) INTO v_participant_exists;
    
    IF NOT v_participant_exists THEN
        RAISE EXCEPTION 'User is not a participant in this chat';
    END IF;
    
    -- Insert or update reaction
    INSERT INTO message_reactions (message_id, user_id, reaction_type)
    VALUES (p_message_id, p_user_id, p_reaction_type)
    ON CONFLICT (message_id, user_id, reaction_type) 
    DO NOTHING;
    
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to remove reaction from message
CREATE OR REPLACE FUNCTION remove_message_reaction(
    p_message_id UUID,
    p_user_id UUID,
    p_reaction_type VARCHAR
) RETURNS BOOLEAN AS $$
BEGIN
    DELETE FROM message_reactions
    WHERE message_id = p_message_id 
    AND user_id = p_user_id 
    AND reaction_type = p_reaction_type;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark messages as read
CREATE OR REPLACE FUNCTION mark_messages_as_read(
    p_chat_id UUID,
    p_user_id UUID,
    p_up_to_message_id UUID DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_updated_count INTEGER;
    v_participant_exists BOOLEAN;
BEGIN
    -- Check if user is a participant
    SELECT EXISTS(
        SELECT 1 FROM chat_participants 
        WHERE chat_id = p_chat_id 
        AND user_id = p_user_id 
        AND is_active = true
    ) INTO v_participant_exists;
    
    IF NOT v_participant_exists THEN
        RAISE EXCEPTION 'User is not a participant in this chat';
    END IF;
    
    -- Update delivery status
    INSERT INTO message_delivery_status (message_id, user_id, status)
    SELECT m.id, p_user_id, 'read'
    FROM messages m
    WHERE m.chat_id = p_chat_id
    AND m.sender_id != p_user_id
    AND (p_up_to_message_id IS NULL OR m.created_at <= (
        SELECT created_at FROM messages WHERE id = p_up_to_message_id
    ))
    ON CONFLICT (message_id, user_id)
    DO UPDATE SET status = 'read', timestamp = NOW()
    WHERE message_delivery_status.status != 'read';
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    
    -- Update participant's last read timestamp
    UPDATE chat_participants
    SET last_read_at = NOW()
    WHERE chat_id = p_chat_id AND user_id = p_user_id;
    
    RETURN v_updated_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get chat messages with pagination
CREATE OR REPLACE FUNCTION get_chat_messages(
    p_chat_id UUID,
    p_user_id UUID,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0,
    p_before_message_id UUID DEFAULT NULL
) RETURNS TABLE (
    id UUID,
    sender_id UUID,
    sender_username VARCHAR,
    sender_avatar_url TEXT,
    content TEXT,
    message_type VARCHAR,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    is_edited BOOLEAN,
    reply_to_message_id UUID,
    reply_to_content TEXT,
    reply_to_username VARCHAR,
    reactions JSONB,
    metadata JSONB,
    is_own_message BOOLEAN,
    delivery_status VARCHAR
) AS $$
BEGIN
    -- Check if user is a participant
    IF NOT EXISTS(
        SELECT 1 FROM chat_participants 
        WHERE chat_id = p_chat_id 
        AND user_id = p_user_id 
        AND is_active = true
    ) THEN
        RAISE EXCEPTION 'User is not a participant in this chat';
    END IF;
    
    RETURN QUERY
    SELECT 
        m.id,
        m.sender_id,
        p.username,
        p.avatar_url,
        m.content,
        m.message_type,
        m.created_at,
        m.updated_at,
        m.is_edited,
        m.reply_to_message_id,
        m.reply_to_content,
        m.reply_to_username,
        COALESCE(
            (SELECT jsonb_object_agg(mr.reaction_type, mr.users)
             FROM (
                 SELECT 
                     reaction_type,
                     jsonb_agg(jsonb_build_object(
                         'user_id', user_id,
                         'username', (SELECT username FROM profiles WHERE id = user_id)
                     )) as users
                 FROM message_reactions
                 WHERE message_id = m.id
                 GROUP BY reaction_type
             ) mr),
            '{}'::jsonb
        ) as reactions,
        m.metadata,
        (m.sender_id = p_user_id) as is_own_message,
        COALESCE(mds.status, 'sent') as delivery_status
    FROM messages m
    LEFT JOIN profiles p ON m.sender_id = p.id
    LEFT JOIN message_delivery_status mds ON (
        mds.message_id = m.id AND mds.user_id = p_user_id
    )
    WHERE m.chat_id = p_chat_id
    AND m.is_deleted = false
    AND (p_before_message_id IS NULL OR m.created_at < (
        SELECT created_at FROM messages WHERE id = p_before_message_id
    ))
    ORDER BY m.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update typing status
CREATE OR REPLACE FUNCTION update_typing_status(
    p_chat_id UUID,
    p_user_id UUID,
    p_status INTEGER DEFAULT 1
) RETURNS BOOLEAN AS $$
BEGIN
    -- Check if user is a participant
    IF NOT EXISTS(
        SELECT 1 FROM chat_participants 
        WHERE chat_id = p_chat_id 
        AND user_id = p_user_id 
        AND is_active = true
    ) THEN
        RAISE EXCEPTION 'User is not a participant in this chat';
    END IF;
    
    -- Upsert typing status
    INSERT INTO typing_status (chat_id, user_id, status, updated_at, expires_at)
    VALUES (p_chat_id, p_user_id, p_status, NOW(), NOW() + INTERVAL '10 seconds')
    ON CONFLICT (chat_id, user_id)
    DO UPDATE SET 
        status = p_status,
        updated_at = NOW(),
        expires_at = NOW() + INTERVAL '10 seconds';
    
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's chat list
CREATE OR REPLACE FUNCTION get_user_chats(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
) RETURNS TABLE (
    chat_id UUID,
    chat_name VARCHAR,
    chat_type VARCHAR,
    is_group BOOLEAN,
    last_message_content TEXT,
    last_message_at TIMESTAMP WITH TIME ZONE,
    last_message_sender_username VARCHAR,
    unread_count BIGINT,
    participant_count BIGINT,
    is_muted BOOLEAN,
    is_pinned BOOLEAN,
    other_participant_username VARCHAR,
    other_participant_avatar_url TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id as chat_id,
        c.name as chat_name,
        c.chat_type,
        c.is_group,
        (SELECT content FROM messages 
         WHERE chat_id = c.id AND is_deleted = false 
         ORDER BY created_at DESC LIMIT 1) as last_message_content,
        c.last_message_at,
        (SELECT p.username FROM messages m 
         JOIN profiles p ON m.sender_id = p.id
         WHERE m.chat_id = c.id AND m.is_deleted = false 
         ORDER BY m.created_at DESC LIMIT 1) as last_message_sender_username,
        (SELECT COUNT(*) FROM messages m
         LEFT JOIN message_delivery_status mds ON (
             mds.message_id = m.id AND mds.user_id = p_user_id
         )
         WHERE m.chat_id = c.id 
         AND m.sender_id != p_user_id
         AND m.is_deleted = false
         AND (mds.status IS NULL OR mds.status != 'read')
         AND m.created_at > cp.last_read_at) as unread_count,
        (SELECT COUNT(*) FROM chat_participants WHERE chat_id = c.id AND is_active = true) as participant_count,
        cp.is_muted,
        cp.is_pinned,
        -- For direct chats, get other participant info
        CASE WHEN NOT c.is_group THEN
            (SELECT p.username FROM chat_participants cp2 
             JOIN profiles p ON cp2.user_id = p.id
             WHERE cp2.chat_id = c.id AND cp2.user_id != p_user_id AND cp2.is_active = true
             LIMIT 1)
        END as other_participant_username,
        CASE WHEN NOT c.is_group THEN
            (SELECT p.avatar_url FROM chat_participants cp2 
             JOIN profiles p ON cp2.user_id = p.id
             WHERE cp2.chat_id = c.id AND cp2.user_id != p_user_id AND cp2.is_active = true
             LIMIT 1)
        END as other_participant_avatar_url
    FROM chats c
    JOIN chat_participants cp ON c.id = cp.chat_id
    WHERE cp.user_id = p_user_id 
    AND cp.is_active = true
    AND c.is_active = true
    ORDER BY 
        cp.is_pinned DESC,
        c.last_message_at DESC NULLS LAST,
        c.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to search messages
CREATE OR REPLACE FUNCTION search_messages(
    p_user_id UUID,
    p_search_query TEXT,
    p_chat_id UUID DEFAULT NULL,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
) RETURNS TABLE (
    message_id UUID,
    chat_id UUID,
    chat_name VARCHAR,
    sender_username VARCHAR,
    content TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    rank REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.id as message_id,
        m.chat_id,
        c.name as chat_name,
        p.username as sender_username,
        m.content,
        m.created_at,
        ts_rank(m.search_vector, plainto_tsquery('english', p_search_query)) as rank
    FROM messages m
    JOIN chats c ON m.chat_id = c.id
    JOIN profiles p ON m.sender_id = p.id
    JOIN chat_participants cp ON (c.id = cp.chat_id AND cp.user_id = p_user_id AND cp.is_active = true)
    WHERE m.search_vector @@ plainto_tsquery('english', p_search_query)
    AND m.is_deleted = false
    AND (p_chat_id IS NULL OR m.chat_id = p_chat_id)
    ORDER BY rank DESC, m.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to clean up expired data
CREATE OR REPLACE FUNCTION cleanup_expired_chat_data() RETURNS INTEGER AS $$
DECLARE
    v_cleaned_count INTEGER := 0;
BEGIN
    -- Clean up expired typing status
    DELETE FROM typing_status WHERE expires_at < NOW();
    GET DIAGNOSTICS v_cleaned_count = ROW_COUNT;
    
    -- Clean up expired messages
    DELETE FROM messages WHERE expires_at IS NOT NULL AND expires_at < NOW();
    
    -- Clean up old drafts (older than 7 days)
    DELETE FROM message_drafts WHERE updated_at < NOW() - INTERVAL '7 days';
    
    RETURN v_cleaned_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get chat analytics
CREATE OR REPLACE FUNCTION get_chat_analytics(
    p_chat_id UUID,
    p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
    p_end_date DATE DEFAULT CURRENT_DATE
) RETURNS TABLE (
    date DATE,
    total_messages BIGINT,
    total_media BIGINT,
    total_reactions BIGINT,
    active_users BIGINT,
    avg_response_time_minutes NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.date,
        COALESCE(SUM(ca.message_count), 0) as total_messages,
        COALESCE(SUM(ca.media_shared), 0) as total_media,
        COALESCE(SUM(ca.reactions_given), 0) as total_reactions,
        COUNT(DISTINCT CASE WHEN ca.message_count > 0 THEN ca.user_id END) as active_users,
        -- Calculate average response time (simplified)
        COALESCE(AVG(
            EXTRACT(EPOCH FROM (
                SELECT MIN(m2.created_at) - m1.created_at
                FROM messages m1
                JOIN messages m2 ON m1.chat_id = m2.chat_id
                WHERE m1.chat_id = p_chat_id
                AND m1.created_at::date = d.date
                AND m2.created_at > m1.created_at
                AND m1.sender_id != m2.sender_id
            )) / 60
        ), 0) as avg_response_time_minutes
    FROM generate_series(p_start_date::date, p_end_date::date, '1 day'::interval) d(date)
    LEFT JOIN chat_analytics ca ON ca.date = d.date AND ca.chat_id = p_chat_id
    GROUP BY d.date
    ORDER BY d.date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
