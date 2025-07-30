-- =====================================================
-- CRYSTAL SOCIAL - CHAT SYSTEM TRIGGERS
-- =====================================================
-- Automated triggers for chat system maintenance and features
-- =====================================================

-- ===== MESSAGE TRIGGERS =====

-- Trigger to update search vector when message content changes
CREATE OR REPLACE FUNCTION update_message_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector := to_tsvector('english', COALESCE(NEW.content, ''));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_message_search_vector
    BEFORE INSERT OR UPDATE OF content ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_message_search_vector();

-- Trigger to update message timestamps
CREATE OR REPLACE FUNCTION update_message_timestamps()
RETURNS TRIGGER AS $$
BEGIN
    -- Set updated_at on updates
    IF TG_OP = 'UPDATE' THEN
        NEW.updated_at := NOW();
        
        -- Set edited timestamp if content changed
        IF OLD.content IS DISTINCT FROM NEW.content THEN
            NEW.edited_at := NOW();
            NEW.is_edited := true;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_message_timestamps
    BEFORE UPDATE ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_message_timestamps();

-- Trigger to update chat last_message_at when new message is added
CREATE OR REPLACE FUNCTION update_chat_last_message()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE chats 
        SET 
            last_message_at = NEW.created_at,
            message_count = message_count + 1,
            updated_at = NOW()
        WHERE id = NEW.chat_id;
        
        -- Create delivery status entries for all other participants
        INSERT INTO message_delivery_status (message_id, user_id, status)
        SELECT NEW.id, cp.user_id, 'sent'
        FROM chat_participants cp
        WHERE cp.chat_id = NEW.chat_id 
        AND cp.user_id != NEW.sender_id 
        AND cp.is_active = true;
        
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE chats 
        SET message_count = GREATEST(message_count - 1, 0)
        WHERE id = OLD.chat_id;
        
        -- Update last_message_at to the most recent remaining message
        UPDATE chats 
        SET last_message_at = (
            SELECT MAX(created_at) 
            FROM messages 
            WHERE chat_id = OLD.chat_id AND is_deleted = false
        )
        WHERE id = OLD.chat_id;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_chat_last_message
    AFTER INSERT OR DELETE ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_chat_last_message();

-- Trigger to create shared media entries for media messages
CREATE OR REPLACE FUNCTION create_shared_media_entry()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert into shared_media for media messages
    IF NEW.message_type IN ('image', 'video', 'audio', 'file', 'gif') THEN
        INSERT INTO shared_media (
            chat_id,
            message_id,
            user_id,
            media_type,
            media_url,
            file_name,
            file_size,
            created_at
        ) VALUES (
            NEW.chat_id,
            NEW.id,
            NEW.sender_id,
            NEW.message_type,
            COALESCE(NEW.image_url, NEW.video_url, NEW.audio_url, NEW.file_url, NEW.gif_url),
            NEW.file_name,
            NEW.file_size,
            NEW.created_at
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_create_shared_media_entry
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION create_shared_media_entry();

-- ===== CHAT PARTICIPANT TRIGGERS =====

-- Trigger to update chat participant counts and timestamps
CREATE OR REPLACE FUNCTION update_chat_participants()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Update chat updated_at
        UPDATE chats SET updated_at = NOW() WHERE id = NEW.chat_id;
        
    ELSIF TG_OP = 'UPDATE' THEN
        -- Update timestamps
        UPDATE chats SET updated_at = NOW() WHERE id = NEW.chat_id;
        
        -- If user left chat, set left_at timestamp
        IF OLD.is_active = true AND NEW.is_active = false THEN
            NEW.left_at := NOW();
        END IF;
        
    ELSIF TG_OP = 'DELETE' THEN
        -- Update chat updated_at
        UPDATE chats SET updated_at = NOW() WHERE id = OLD.chat_id;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_chat_participants
    BEFORE INSERT OR UPDATE OR DELETE ON chat_participants
    FOR EACH ROW
    EXECUTE FUNCTION update_chat_participants();

-- ===== REACTION TRIGGERS =====

-- Trigger to update message reactions JSONB field
CREATE OR REPLACE FUNCTION update_message_reactions()
RETURNS TRIGGER AS $$
DECLARE
    v_reactions JSONB;
BEGIN
    -- Rebuild reactions JSONB for the message
    SELECT COALESCE(
        jsonb_object_agg(
            reaction_type, 
            jsonb_agg(
                jsonb_build_object(
                    'user_id', user_id,
                    'username', (SELECT username FROM profiles WHERE id = user_id),
                    'created_at', created_at
                )
            )
        ),
        '{}'::jsonb
    ) INTO v_reactions
    FROM message_reactions
    WHERE message_id = COALESCE(NEW.message_id, OLD.message_id)
    GROUP BY message_id;
    
    -- Update the message
    UPDATE messages 
    SET reactions = v_reactions 
    WHERE id = COALESCE(NEW.message_id, OLD.message_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_message_reactions
    AFTER INSERT OR UPDATE OR DELETE ON message_reactions
    FOR EACH ROW
    EXECUTE FUNCTION update_message_reactions();

-- ===== TYPING STATUS TRIGGERS =====

-- Trigger to auto-expire typing status
CREATE OR REPLACE FUNCTION cleanup_expired_typing_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Delete expired typing statuses
    DELETE FROM typing_status WHERE expires_at <= NOW();
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create a periodic cleanup trigger (requires pg_cron extension)
-- Note: This would need to be set up separately with pg_cron
-- SELECT cron.schedule('cleanup-typing-status', '*/30 * * * * *', 'SELECT cleanup_expired_typing_status();');

-- ===== CHAT ANALYTICS TRIGGERS =====

-- Trigger to update chat analytics
CREATE OR REPLACE FUNCTION update_chat_analytics()
RETURNS TRIGGER AS $$
DECLARE
    v_date DATE := CURRENT_DATE;
    v_is_media BOOLEAN := false;
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Check if message contains media
        v_is_media := NEW.message_type IN ('image', 'video', 'audio', 'file', 'gif');
        
        -- Update or insert analytics record
        INSERT INTO chat_analytics (
            chat_id, 
            user_id, 
            date, 
            message_count, 
            media_shared
        ) VALUES (
            NEW.chat_id,
            NEW.sender_id,
            v_date,
            1,
            CASE WHEN v_is_media THEN 1 ELSE 0 END
        )
        ON CONFLICT (chat_id, user_id, date)
        DO UPDATE SET
            message_count = chat_analytics.message_count + 1,
            media_shared = chat_analytics.media_shared + CASE WHEN v_is_media THEN 1 ELSE 0 END;
            
    ELSIF TG_OP = 'DELETE' THEN
        -- Decrease counters (but don't go below 0)
        v_is_media := OLD.message_type IN ('image', 'video', 'audio', 'file', 'gif');
        
        UPDATE chat_analytics
        SET 
            message_count = GREATEST(message_count - 1, 0),
            media_shared = GREATEST(media_shared - CASE WHEN v_is_media THEN 1 ELSE 0 END, 0)
        WHERE chat_id = OLD.chat_id 
        AND user_id = OLD.sender_id 
        AND date = OLD.created_at::date;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_chat_analytics
    AFTER INSERT OR DELETE ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_chat_analytics();

-- Trigger to update reaction analytics
CREATE OR REPLACE FUNCTION update_reaction_analytics()
RETURNS TRIGGER AS $$
DECLARE
    v_date DATE := CURRENT_DATE;
    v_message_sender_id UUID;
BEGIN
    -- Get the message sender
    SELECT sender_id INTO v_message_sender_id
    FROM messages WHERE id = COALESCE(NEW.message_id, OLD.message_id);
    
    IF TG_OP = 'INSERT' THEN
        -- Update analytics for reaction giver
        INSERT INTO chat_analytics (
            chat_id, 
            user_id, 
            date, 
            reactions_given
        ) VALUES (
            (SELECT chat_id FROM messages WHERE id = NEW.message_id),
            NEW.user_id,
            v_date,
            1
        )
        ON CONFLICT (chat_id, user_id, date)
        DO UPDATE SET reactions_given = chat_analytics.reactions_given + 1;
        
        -- Update analytics for reaction receiver
        INSERT INTO chat_analytics (
            chat_id, 
            user_id, 
            date, 
            reactions_received
        ) VALUES (
            (SELECT chat_id FROM messages WHERE id = NEW.message_id),
            v_message_sender_id,
            v_date,
            1
        )
        ON CONFLICT (chat_id, user_id, date)
        DO UPDATE SET reactions_received = chat_analytics.reactions_received + 1;
        
    ELSIF TG_OP = 'DELETE' THEN
        -- Decrease counters
        UPDATE chat_analytics
        SET reactions_given = GREATEST(reactions_given - 1, 0)
        WHERE chat_id = (SELECT chat_id FROM messages WHERE id = OLD.message_id)
        AND user_id = OLD.user_id 
        AND date = v_date;
        
        UPDATE chat_analytics
        SET reactions_received = GREATEST(reactions_received - 1, 0)
        WHERE chat_id = (SELECT chat_id FROM messages WHERE id = OLD.message_id)
        AND user_id = v_message_sender_id 
        AND date = v_date;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_reaction_analytics
    AFTER INSERT OR DELETE ON message_reactions
    FOR EACH ROW
    EXECUTE FUNCTION update_reaction_analytics();

-- ===== CALL TRIGGERS =====

-- Trigger to update call duration when call ends
CREATE OR REPLACE FUNCTION update_call_duration()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.ended = false AND NEW.ended = true THEN
        NEW.ended_at := NOW();
        
        -- Calculate duration if call was answered
        IF NEW.answered_at IS NOT NULL THEN
            NEW.duration_seconds := EXTRACT(EPOCH FROM (NEW.ended_at - NEW.answered_at))::INTEGER;
            
            -- Update analytics for call participants
            INSERT INTO chat_analytics (
                chat_id, 
                user_id, 
                date, 
                call_duration_seconds
            ) VALUES 
                (NEW.chat_id, NEW.caller_id, CURRENT_DATE, NEW.duration_seconds),
                (NEW.chat_id, NEW.receiver_id, CURRENT_DATE, NEW.duration_seconds)
            ON CONFLICT (chat_id, user_id, date)
            DO UPDATE SET call_duration_seconds = chat_analytics.call_duration_seconds + NEW.duration_seconds;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_call_duration
    BEFORE UPDATE ON calls
    FOR EACH ROW
    EXECUTE FUNCTION update_call_duration();

-- ===== DRAFT CLEANUP TRIGGERS =====

-- Trigger to clean up drafts when message is sent
CREATE OR REPLACE FUNCTION cleanup_message_draft()
RETURNS TRIGGER AS $$
BEGIN
    -- Delete any existing draft for this chat/user when a message is sent
    DELETE FROM message_drafts 
    WHERE chat_id = NEW.chat_id 
    AND user_id = NEW.sender_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_cleanup_message_draft
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION cleanup_message_draft();

-- ===== VALIDATION TRIGGERS =====

-- Trigger to validate chat participant limits
CREATE OR REPLACE FUNCTION validate_chat_participant_limit()
RETURNS TRIGGER AS $$
DECLARE
    v_max_participants INTEGER;
    v_current_count INTEGER;
BEGIN
    IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.is_active = false AND NEW.is_active = true) THEN
        -- Get max participants for this chat
        SELECT max_participants INTO v_max_participants
        FROM chats WHERE id = NEW.chat_id;
        
        -- Count current active participants
        SELECT COUNT(*) INTO v_current_count
        FROM chat_participants 
        WHERE chat_id = NEW.chat_id AND is_active = true;
        
        -- Include the new participant if this is an insert
        IF TG_OP = 'INSERT' THEN
            v_current_count := v_current_count + 1;
        END IF;
        
        -- Check limit
        IF v_current_count > v_max_participants THEN
            RAISE EXCEPTION 'Chat has reached maximum participant limit of %', v_max_participants;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_chat_participant_limit
    BEFORE INSERT OR UPDATE ON chat_participants
    FOR EACH ROW
    EXECUTE FUNCTION validate_chat_participant_limit();

-- ===== AUTOMATIC CLEANUP TRIGGERS =====

-- Function to be called periodically for cleanup
CREATE OR REPLACE FUNCTION periodic_chat_cleanup()
RETURNS INTEGER AS $$
DECLARE
    v_cleaned_count INTEGER := 0;
BEGIN
    -- Clean up expired typing status
    DELETE FROM typing_status WHERE expires_at <= NOW();
    GET DIAGNOSTICS v_cleaned_count = ROW_COUNT;
    
    -- Clean up expired messages
    DELETE FROM messages WHERE expires_at IS NOT NULL AND expires_at <= NOW();
    
    -- Clean up old drafts (older than 7 days)
    DELETE FROM message_drafts WHERE updated_at < NOW() - INTERVAL '7 days';
    
    -- Clean up delivery status for deleted messages
    DELETE FROM message_delivery_status mds
    WHERE NOT EXISTS (
        SELECT 1 FROM messages m WHERE m.id = mds.message_id
    );
    
    -- Clean up reactions for deleted messages
    DELETE FROM message_reactions mr
    WHERE NOT EXISTS (
        SELECT 1 FROM messages m WHERE m.id = mr.message_id
    );
    
    -- Clean up shared media for deleted messages
    DELETE FROM shared_media sm
    WHERE NOT EXISTS (
        SELECT 1 FROM messages m WHERE m.id = sm.message_id
    );
    
    RETURN v_cleaned_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- TRIGGER DOCUMENTATION
-- =====================================================

COMMENT ON FUNCTION update_message_search_vector() IS 'Updates search vector for message content indexing';
COMMENT ON FUNCTION update_message_timestamps() IS 'Manages message update and edit timestamps';
COMMENT ON FUNCTION update_chat_last_message() IS 'Updates chat metadata when messages are added/removed';
COMMENT ON FUNCTION create_shared_media_entry() IS 'Creates shared media index entries for media messages';
COMMENT ON FUNCTION update_chat_participants() IS 'Manages chat participant metadata and timestamps';
COMMENT ON FUNCTION update_message_reactions() IS 'Synchronizes reaction data between tables';
COMMENT ON FUNCTION update_chat_analytics() IS 'Updates real-time chat analytics';
COMMENT ON FUNCTION update_reaction_analytics() IS 'Tracks reaction analytics for users';
COMMENT ON FUNCTION update_call_duration() IS 'Calculates and stores call duration when calls end';
COMMENT ON FUNCTION cleanup_message_draft() IS 'Removes drafts when messages are sent';
COMMENT ON FUNCTION validate_chat_participant_limit() IS 'Enforces chat participant limits';
COMMENT ON FUNCTION periodic_chat_cleanup() IS 'Performs periodic cleanup of expired and orphaned data';
