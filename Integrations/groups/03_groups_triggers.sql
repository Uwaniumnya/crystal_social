-- =====================================================
-- CRYSTAL SOCIAL - GROUPS SYSTEM TRIGGERS
-- =====================================================
-- Automated triggers for group operations and analytics
-- =====================================================

-- Trigger to automatically update group timestamps
CREATE OR REPLACE FUNCTION update_group_details_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_group_details_updated_at
    BEFORE UPDATE ON group_details
    FOR EACH ROW
    EXECUTE FUNCTION update_group_details_timestamp();

-- Trigger to update group member timestamps
CREATE OR REPLACE FUNCTION update_group_member_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_group_member_updated_at
    BEFORE UPDATE ON group_members
    FOR EACH ROW
    EXECUTE FUNCTION update_group_member_timestamp();

-- Trigger to automatically update group member count
CREATE OR REPLACE FUNCTION update_group_member_count()
RETURNS TRIGGER AS $$
DECLARE
    v_group_id UUID;
    v_new_count INTEGER;
BEGIN
    -- Determine group_id based on operation
    IF TG_OP = 'DELETE' THEN
        v_group_id := OLD.group_id;
    ELSE
        v_group_id := NEW.group_id;
    END IF;
    
    -- Calculate new active member count
    SELECT COUNT(*) INTO v_new_count
    FROM group_members
    WHERE group_id = v_group_id AND is_active = true;
    
    -- Update group details
    UPDATE group_details
    SET 
        active_members_count = v_new_count,
        last_activity_at = NOW()
    WHERE chat_id = v_group_id;
    
    -- Return appropriate record
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_update_group_member_count
    AFTER INSERT OR UPDATE OR DELETE ON group_members
    FOR EACH ROW
    EXECUTE FUNCTION update_group_member_count();

-- Trigger to update member activity when they send messages
CREATE OR REPLACE FUNCTION update_member_activity_on_message()
RETURNS TRIGGER AS $$
DECLARE
    v_group_id UUID;
    v_sender_id UUID;
BEGIN
    -- Only process for group messages
    SELECT c.id INTO v_group_id
    FROM chats c
    WHERE c.id = NEW.chat_id AND c.is_group = true;
    
    IF v_group_id IS NOT NULL THEN
        v_sender_id := NEW.sender_id;
        
        -- Update member's message count and last seen
        UPDATE group_members
        SET 
            message_count = message_count + 1,
            last_seen_at = NOW(),
            updated_at = NOW()
        WHERE group_id = v_group_id AND user_id = v_sender_id;
        
        -- Update group's total message count and last activity
        UPDATE group_details
        SET 
            total_messages = total_messages + 1,
            last_activity_at = NOW(),
            updated_at = NOW()
        WHERE chat_id = v_group_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_update_member_activity_on_message
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_member_activity_on_message();

-- Trigger to update member reaction count
CREATE OR REPLACE FUNCTION update_member_reaction_count()
RETURNS TRIGGER AS $$
DECLARE
    v_group_id UUID;
    v_user_id UUID;
    v_count_change INTEGER := 0;
BEGIN
    -- Determine operation and values
    IF TG_OP = 'INSERT' THEN
        v_group_id := NEW.group_id;
        v_user_id := NEW.user_id;
        v_count_change := 1;
    ELSIF TG_OP = 'DELETE' THEN
        v_group_id := OLD.group_id;
        v_user_id := OLD.user_id;
        v_count_change := -1;
    END IF;
    
    -- Update member's reaction count
    UPDATE group_members
    SET 
        reaction_count = reaction_count + v_count_change,
        last_seen_at = NOW(),
        updated_at = NOW()
    WHERE group_id = v_group_id AND user_id = v_user_id;
    
    -- Return appropriate record
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_update_member_reaction_count
    AFTER INSERT OR DELETE ON group_message_reactions
    FOR EACH ROW
    EXECUTE FUNCTION update_member_reaction_count();

-- Trigger to automatically expire old invitations
CREATE OR REPLACE FUNCTION expire_old_invitations()
RETURNS TRIGGER AS $$
BEGIN
    -- Mark expired invitations
    UPDATE group_invitations
    SET status = 'expired'
    WHERE expires_at < NOW() AND status = 'pending';
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger that runs on invitation table changes
CREATE OR REPLACE TRIGGER trigger_expire_old_invitations
    AFTER INSERT OR UPDATE ON group_invitations
    FOR EACH STATEMENT
    EXECUTE FUNCTION expire_old_invitations();

-- Trigger to update announcement view count
CREATE OR REPLACE FUNCTION increment_announcement_view()
RETURNS TRIGGER AS $$
BEGIN
    -- This would be called when an announcement is viewed
    -- Implementation depends on how views are tracked in the app
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to handle group media upload analytics
CREATE OR REPLACE FUNCTION update_media_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Update group details with media count
    UPDATE group_details
    SET last_activity_at = NOW()
    WHERE chat_id = NEW.group_id;
    
    -- Update member activity
    UPDATE group_members
    SET 
        last_seen_at = NOW(),
        updated_at = NOW()
    WHERE group_id = NEW.group_id AND user_id = NEW.uploader_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_update_media_stats
    AFTER INSERT ON group_media
    FOR EACH ROW
    EXECUTE FUNCTION update_media_stats();

-- Trigger to auto-create daily analytics records
CREATE OR REPLACE FUNCTION create_daily_group_analytics()
RETURNS TRIGGER AS $$
DECLARE
    v_group_id UUID;
    v_date DATE := CURRENT_DATE;
BEGIN
    -- Get group_id based on the triggering table
    IF TG_TABLE_NAME = 'group_members' THEN
        IF TG_OP = 'DELETE' THEN
            v_group_id := OLD.group_id;
        ELSE
            v_group_id := NEW.group_id;
        END IF;
    ELSIF TG_TABLE_NAME = 'messages' THEN
        -- Get group_id from chat if it's a group
        SELECT c.id INTO v_group_id
        FROM chats c
        WHERE c.id = NEW.chat_id AND c.is_group = true;
    ELSIF TG_TABLE_NAME = 'group_message_reactions' THEN
        v_group_id := NEW.group_id;
    END IF;
    
    -- Only proceed if this is a group-related change
    IF v_group_id IS NOT NULL THEN
        -- Ensure analytics record exists for today
        INSERT INTO group_analytics (group_id, date)
        VALUES (v_group_id, v_date)
        ON CONFLICT (group_id, date) DO NOTHING;
        
        -- Update specific metrics based on the triggering event
        IF TG_TABLE_NAME = 'group_members' THEN
            IF TG_OP = 'INSERT' AND NEW.is_active = true THEN
                UPDATE group_analytics
                SET new_members = new_members + 1
                WHERE group_id = v_group_id AND date = v_date;
            ELSIF TG_OP = 'UPDATE' AND OLD.is_active = true AND NEW.is_active = false THEN
                UPDATE group_analytics
                SET members_left = members_left + 1
                WHERE group_id = v_group_id AND date = v_date;
            END IF;
        ELSIF TG_TABLE_NAME = 'messages' THEN
            UPDATE group_analytics
            SET messages_sent = messages_sent + 1
            WHERE group_id = v_group_id AND date = v_date;
        ELSIF TG_TABLE_NAME = 'group_message_reactions' AND TG_OP = 'INSERT' THEN
            UPDATE group_analytics
            SET reactions_given = reactions_given + 1
            WHERE group_id = v_group_id AND date = v_date;
        END IF;
    END IF;
    
    -- Return appropriate record
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for analytics on various tables
CREATE OR REPLACE TRIGGER trigger_analytics_group_members
    AFTER INSERT OR UPDATE OR DELETE ON group_members
    FOR EACH ROW
    EXECUTE FUNCTION create_daily_group_analytics();

CREATE OR REPLACE TRIGGER trigger_analytics_messages
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION create_daily_group_analytics();

CREATE OR REPLACE TRIGGER trigger_analytics_reactions
    AFTER INSERT OR DELETE ON group_message_reactions
    FOR EACH ROW
    EXECUTE FUNCTION create_daily_group_analytics();

-- Trigger to update group analytics with current totals
CREATE OR REPLACE FUNCTION update_group_analytics_totals()
RETURNS TRIGGER AS $$
DECLARE
    v_group_id UUID;
    v_total_members INTEGER;
    v_active_7d INTEGER;
BEGIN
    v_group_id := NEW.group_id;
    
    -- Get current total members
    SELECT COUNT(*) INTO v_total_members
    FROM group_members
    WHERE group_id = v_group_id AND is_active = true;
    
    -- Get active members in last 7 days
    SELECT COUNT(*) INTO v_active_7d
    FROM group_members
    WHERE group_id = v_group_id 
      AND is_active = true 
      AND last_seen_at >= CURRENT_DATE - INTERVAL '7 days';
    
    -- Update today's analytics record
    UPDATE group_analytics
    SET 
        total_members = v_total_members,
        active_members_7d = v_active_7d,
        updated_at = NOW()
    WHERE group_id = v_group_id AND date = CURRENT_DATE;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_update_group_analytics_totals
    AFTER INSERT OR UPDATE ON group_analytics
    FOR EACH ROW
    EXECUTE FUNCTION update_group_analytics_totals();

-- Trigger to handle event attendance updates
CREATE OR REPLACE FUNCTION update_event_attendance_count()
RETURNS TRIGGER AS $$
DECLARE
    v_event_id UUID;
    v_new_attendee_count INTEGER;
    v_new_interested_count INTEGER;
BEGIN
    -- Determine event_id based on operation
    IF TG_OP = 'DELETE' THEN
        v_event_id := OLD.event_id;
    ELSE
        v_event_id := NEW.event_id;
    END IF;
    
    -- Calculate new counts
    SELECT 
        COUNT(*) FILTER (WHERE status = 'attending'),
        COUNT(*) FILTER (WHERE status = 'interested')
    INTO v_new_attendee_count, v_new_interested_count
    FROM group_event_attendees
    WHERE event_id = v_event_id;
    
    -- Update event
    UPDATE group_events
    SET 
        attendee_count = v_new_attendee_count,
        interested_count = v_new_interested_count,
        updated_at = NOW()
    WHERE id = v_event_id;
    
    -- Return appropriate record
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_update_event_attendance_count
    AFTER INSERT OR UPDATE OR DELETE ON group_event_attendees
    FOR EACH ROW
    EXECUTE FUNCTION update_event_attendance_count();

-- Trigger to auto-update moderation log status
CREATE OR REPLACE FUNCTION update_moderation_status()
RETURNS TRIGGER AS $$
BEGIN
    -- For time-based actions (like mutes), automatically expire them
    IF NEW.action_type = 'mute' AND NEW.duration_minutes IS NOT NULL THEN
        -- This could be handled by a scheduled job instead
        -- But we can set up the expiry logic here
        NULL;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_update_moderation_status
    AFTER INSERT ON group_moderation_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_moderation_status();

-- Function to clean up expired data (to be called by scheduled job)
CREATE OR REPLACE FUNCTION cleanup_expired_group_data()
RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER := 0;
BEGIN
    -- Mark expired invitations
    UPDATE group_invitations
    SET status = 'expired'
    WHERE expires_at < NOW() AND status = 'pending';
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    -- Remove old analytics data (older than 1 year)
    DELETE FROM group_analytics
    WHERE date < CURRENT_DATE - INTERVAL '365 days';
    
    -- Expire temporary moderation actions
    UPDATE group_members gm
    SET is_muted = false, muted_until = NULL
    FROM group_moderation_logs gml
    WHERE gml.target_user_id = gm.user_id
      AND gml.action_type = 'mute'
      AND gml.duration_minutes IS NOT NULL
      AND gml.created_at + (gml.duration_minutes || ' minutes')::INTERVAL < NOW()
      AND gm.is_muted = true;
    
    RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Trigger to validate group rules on insert/update
CREATE OR REPLACE FUNCTION validate_group_rule()
RETURNS TRIGGER AS $$
BEGIN
    -- Ensure rule numbers are unique within a group
    IF EXISTS (
        SELECT 1 FROM group_rules 
        WHERE group_id = NEW.group_id 
          AND rule_number = NEW.rule_number 
          AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::UUID)
    ) THEN
        RAISE EXCEPTION 'Rule number % already exists for this group', NEW.rule_number;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_validate_group_rule
    BEFORE INSERT OR UPDATE ON group_rules
    FOR EACH ROW
    EXECUTE FUNCTION validate_group_rule();
