-- Crystal Social Tabs System - Real-time Subscriptions and Notifications
-- File: 05_tabs_realtime_subscriptions.sql
-- Purpose: Real-time subscriptions, notification triggers, and live update system for comprehensive tabs functionality

-- =============================================================================
-- NOTIFICATION INFRASTRUCTURE
-- =============================================================================

-- Create notification channels table
CREATE TABLE IF NOT EXISTS notification_channels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    channel_name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    max_subscribers INTEGER DEFAULT 1000,
    current_subscribers INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default notification channels
INSERT INTO notification_channels (channel_name, description, max_subscribers) VALUES
('tabs_updates', 'Tab system updates and changes', 5000),
('social_activity', 'Glitter Board posts, comments, and reactions', 3000),
('horoscope_daily', 'Daily horoscope updates', 2000),
('entertainment_updates', 'Tarot, Oracle, and Magic 8-Ball activities', 1500),
('poll_updates', 'Poll creation and voting updates', 1000),
('user_achievements', 'User milestones and achievements', 2000),
('system_maintenance', 'System maintenance and announcements', 5000),
('confession_activity', 'New confessions (anonymized)', 500)
ON CONFLICT (channel_name) DO NOTHING;

-- User notification subscriptions
CREATE TABLE IF NOT EXISTS user_notification_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    channel_name VARCHAR(100) NOT NULL REFERENCES notification_channels(channel_name),
    is_subscribed BOOLEAN DEFAULT true,
    notification_preferences JSONB DEFAULT '{}',
    last_notified_at TIMESTAMPTZ,
    subscription_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, channel_name)
);

-- Real-time notification queue
CREATE TABLE IF NOT EXISTS realtime_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    channel_name VARCHAR(100) NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    payload JSONB DEFAULT '{}',
    target_user_id UUID REFERENCES auth.users(id), -- NULL for broadcast
    is_read BOOLEAN DEFAULT false,
    expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '24 hours',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    sent_at TIMESTAMPTZ
);

-- Enable RLS on notification tables
ALTER TABLE notification_channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_notification_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE realtime_notifications ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- NOTIFICATION SECURITY POLICIES
-- =============================================================================

-- Notification channels: Public read
CREATE POLICY "notification_channels_public_read" ON notification_channels
    FOR SELECT
    USING (is_active = true);

-- User subscriptions: Users can manage their own
CREATE POLICY "user_subscriptions_own_data" ON user_notification_subscriptions
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Real-time notifications: Users can read their own notifications
CREATE POLICY "realtime_notifications_own_read" ON realtime_notifications
    FOR SELECT
    TO authenticated
    USING (
        target_user_id = auth.uid() OR 
        target_user_id IS NULL  -- Broadcast notifications
    );

-- Real-time notifications: Service can manage all
CREATE POLICY "realtime_notifications_service_manage" ON realtime_notifications
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- =============================================================================
-- REAL-TIME NOTIFICATION FUNCTIONS
-- =============================================================================

-- Subscribe user to notification channel
CREATE OR REPLACE FUNCTION subscribe_to_channel(
    p_user_id UUID,
    p_channel_name VARCHAR(100),
    p_preferences JSONB DEFAULT '{}'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_max_subscribers INTEGER;
    v_current_subscribers INTEGER;
BEGIN
    -- Check if channel exists and has capacity
    SELECT max_subscribers, current_subscribers
    INTO v_max_subscribers, v_current_subscribers
    FROM notification_channels
    WHERE channel_name = p_channel_name AND is_active = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Notification channel not found: %', p_channel_name;
    END IF;
    
    IF v_current_subscribers >= v_max_subscribers THEN
        RAISE EXCEPTION 'Channel at maximum capacity: %', p_channel_name;
    END IF;
    
    -- Subscribe user
    INSERT INTO user_notification_subscriptions (
        user_id, channel_name, notification_preferences
    ) VALUES (
        p_user_id, p_channel_name, p_preferences
    )
    ON CONFLICT (user_id, channel_name)
    DO UPDATE SET
        is_subscribed = true,
        notification_preferences = p_preferences,
        updated_at = NOW();
    
    -- Update subscriber count
    UPDATE notification_channels
    SET 
        current_subscribers = current_subscribers + 1,
        updated_at = NOW()
    WHERE channel_name = p_channel_name;
    
    RETURN true;
END;
$$;

-- Unsubscribe user from notification channel
CREATE OR REPLACE FUNCTION unsubscribe_from_channel(
    p_user_id UUID,
    p_channel_name VARCHAR(100)
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Unsubscribe user
    UPDATE user_notification_subscriptions
    SET 
        is_subscribed = false,
        updated_at = NOW()
    WHERE user_id = p_user_id AND channel_name = p_channel_name;
    
    IF FOUND THEN
        -- Update subscriber count
        UPDATE notification_channels
        SET 
            current_subscribers = GREATEST(0, current_subscribers - 1),
            updated_at = NOW()
        WHERE channel_name = p_channel_name;
        
        RETURN true;
    END IF;
    
    RETURN false;
END;
$$;

-- Send notification to channel
CREATE OR REPLACE FUNCTION send_notification(
    p_channel_name VARCHAR(100),
    p_notification_type VARCHAR(50),
    p_title VARCHAR(255),
    p_message TEXT,
    p_payload JSONB DEFAULT '{}',
    p_target_user_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_notification_id UUID;
    v_user_record RECORD;
BEGIN
    -- Validate channel exists
    IF NOT EXISTS (
        SELECT 1 FROM notification_channels 
        WHERE channel_name = p_channel_name AND is_active = true
    ) THEN
        RAISE EXCEPTION 'Invalid notification channel: %', p_channel_name;
    END IF;
    
    -- If targeting specific user, send directly
    IF p_target_user_id IS NOT NULL THEN
        INSERT INTO realtime_notifications (
            channel_name, notification_type, title, message, payload, target_user_id
        ) VALUES (
            p_channel_name, p_notification_type, p_title, p_message, p_payload, p_target_user_id
        ) RETURNING id INTO v_notification_id;
        
        -- Send real-time notification
        PERFORM pg_notify(
            'notification_' || p_target_user_id::TEXT,
            json_build_object(
                'notification_id', v_notification_id,
                'channel', p_channel_name,
                'type', p_notification_type,
                'title', p_title,
                'message', p_message,
                'payload', p_payload
            )::TEXT
        );
    ELSE
        -- Broadcast to all subscribed users
        FOR v_user_record IN
            SELECT user_id
            FROM user_notification_subscriptions
            WHERE channel_name = p_channel_name AND is_subscribed = true
        LOOP
            INSERT INTO realtime_notifications (
                channel_name, notification_type, title, message, payload, target_user_id
            ) VALUES (
                p_channel_name, p_notification_type, p_title, p_message, p_payload, v_user_record.user_id
            ) RETURNING id INTO v_notification_id;
            
            -- Send real-time notification
            PERFORM pg_notify(
                'notification_' || v_user_record.user_id::TEXT,
                json_build_object(
                    'notification_id', v_notification_id,
                    'channel', p_channel_name,
                    'type', p_notification_type,
                    'title', p_title,
                    'message', p_message,
                    'payload', p_payload
                )::TEXT
            );
        END LOOP;
    END IF;
    
    RETURN v_notification_id;
END;
$$;

-- Mark notification as read
CREATE OR REPLACE FUNCTION mark_notification_read(
    p_notification_id UUID,
    p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE realtime_notifications
    SET is_read = true
    WHERE id = p_notification_id 
    AND (target_user_id = p_user_id OR target_user_id IS NULL);
    
    RETURN FOUND;
END;
$$;

-- =============================================================================
-- REAL-TIME TRIGGER FUNCTIONS
-- =============================================================================

-- Notification trigger for new Glitter Board posts
CREATE OR REPLACE FUNCTION notify_new_glitter_post()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_author_email TEXT;
BEGIN
    -- Get author email for notification
    SELECT email INTO v_author_email
    FROM auth.users
    WHERE id = NEW.user_id;
    
    -- Send notification to social activity channel
    PERFORM send_notification(
        'social_activity',
        'new_post',
        'New Glitter Board Post',
        COALESCE(v_author_email, 'Someone') || ' shared a new post: ' || 
        substring(NEW.text_content from 1 for 100) || 
        CASE WHEN length(NEW.text_content) > 100 THEN '...' ELSE '' END,
        json_build_object(
            'post_id', NEW.id,
            'user_id', NEW.user_id,
            'mood', NEW.mood,
            'tags', NEW.tags
        )
    );
    
    RETURN NEW;
END;
$$;

-- Notification trigger for new comments
CREATE OR REPLACE FUNCTION notify_new_comment()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_post_author_id UUID;
    v_commenter_email TEXT;
BEGIN
    -- Get post author
    SELECT user_id INTO v_post_author_id
    FROM glitter_posts
    WHERE id = NEW.post_id;
    
    -- Get commenter email
    SELECT email INTO v_commenter_email
    FROM auth.users
    WHERE id = NEW.user_id;
    
    -- Notify post author if comment is from someone else
    IF v_post_author_id IS NOT NULL AND v_post_author_id != NEW.user_id THEN
        PERFORM send_notification(
            'social_activity',
            'new_comment',
            'New Comment on Your Post',
            COALESCE(v_commenter_email, 'Someone') || ' commented on your post: ' ||
            substring(NEW.text_content from 1 for 100) ||
            CASE WHEN length(NEW.text_content) > 100 THEN '...' ELSE '' END,
            json_build_object(
                'comment_id', NEW.id,
                'post_id', NEW.post_id,
                'commenter_id', NEW.user_id
            ),
            v_post_author_id
        );
    END IF;
    
    RETURN NEW;
END;
$$;

-- Notification trigger for new reactions
CREATE OR REPLACE FUNCTION notify_new_reaction()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_target_author_id UUID;
    v_reactor_email TEXT;
    v_target_type_text TEXT;
BEGIN
    -- Get target author based on target type
    IF NEW.target_type = 'post' THEN
        SELECT user_id INTO v_target_author_id
        FROM glitter_posts
        WHERE id = NEW.target_id;
        v_target_type_text := 'post';
    ELSIF NEW.target_type = 'comment' THEN
        SELECT user_id INTO v_target_author_id
        FROM glitter_comments
        WHERE id = NEW.target_id;
        v_target_type_text := 'comment';
    END IF;
    
    -- Get reactor email
    SELECT email INTO v_reactor_email
    FROM auth.users
    WHERE id = NEW.user_id;
    
    -- Notify target author if reaction is from someone else
    IF v_target_author_id IS NOT NULL AND v_target_author_id != NEW.user_id THEN
        PERFORM send_notification(
            'social_activity',
            'new_reaction',
            'Someone Reacted to Your ' || initcap(v_target_type_text),
            COALESCE(v_reactor_email, 'Someone') || ' reacted with ' || NEW.reaction_type || ' to your ' || v_target_type_text,
            json_build_object(
                'reaction_id', NEW.id,
                'target_type', NEW.target_type,
                'target_id', NEW.target_id,
                'reaction_type', NEW.reaction_type,
                'reactor_id', NEW.user_id
            ),
            v_target_author_id
        );
    END IF;
    
    RETURN NEW;
END;
$$;

-- Notification trigger for new polls
CREATE OR REPLACE FUNCTION notify_new_poll()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_creator_email TEXT;
BEGIN
    -- Get creator email
    SELECT email INTO v_creator_email
    FROM auth.users
    WHERE id = NEW.creator_id;
    
    -- Send notification to poll updates channel
    PERFORM send_notification(
        'poll_updates',
        'new_poll',
        'New Community Poll',
        COALESCE(v_creator_email, 'Someone') || ' created a new poll: ' || NEW.poll_title,
        json_build_object(
            'poll_id', NEW.id,
            'poll_title', NEW.poll_title,
            'poll_category', NEW.poll_category,
            'creator_id', NEW.creator_id,
            'ends_at', NEW.ends_at
        )
    );
    
    RETURN NEW;
END;
$$;

-- Notification trigger for daily horoscope
CREATE OR REPLACE FUNCTION notify_daily_horoscope()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_sign_name VARCHAR(50);
BEGIN
    -- Get zodiac sign name
    SELECT sign_name INTO v_sign_name
    FROM zodiac_signs
    WHERE id = NEW.zodiac_sign_id;
    
    -- Send notification to horoscope channel
    PERFORM send_notification(
        'horoscope_daily',
        'daily_horoscope',
        'Your Daily ' || v_sign_name || ' Horoscope',
        'Your daily horoscope reading is now available. Energy level: ' || NEW.overall_energy || '/10',
        json_build_object(
            'reading_id', NEW.id,
            'zodiac_sign_id', NEW.zodiac_sign_id,
            'sign_name', v_sign_name,
            'reading_date', NEW.reading_date,
            'overall_energy', NEW.overall_energy
        )
    );
    
    RETURN NEW;
END;
$$;

-- Notification trigger for entertainment activity
CREATE OR REPLACE FUNCTION notify_entertainment_activity()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_activity_type TEXT;
    v_message TEXT;
    v_user_email TEXT;
BEGIN
    -- Determine activity type based on table
    CASE TG_TABLE_NAME
        WHEN 'tarot_readings' THEN
            v_activity_type := 'tarot_reading';
            v_message := 'completed a ' || NEW.reading_type || ' tarot reading';
        WHEN 'oracle_consultations' THEN
            v_activity_type := 'oracle_consultation';
            v_message := 'received oracle guidance';
        WHEN 'magic_8ball_consultations' THEN
            v_activity_type := 'magic_8ball';
            v_message := 'asked the Magic 8-Ball a question';
        ELSE
            RETURN NEW;
    END CASE;
    
    -- Get user email
    SELECT email INTO v_user_email
    FROM auth.users
    WHERE id = NEW.user_id;
    
    -- Send notification (sample of activity, not personal details)
    PERFORM send_notification(
        'entertainment_updates',
        v_activity_type,
        'Mystical Activity',
        'Someone ' || v_message || ' in the entertainment section',
        json_build_object(
            'activity_type', v_activity_type,
            'timestamp', NOW()
        )
    );
    
    RETURN NEW;
END;
$$;

-- Notification trigger for user achievements
CREATE OR REPLACE FUNCTION notify_user_achievement()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_achievement_message TEXT;
    v_user_email TEXT;
BEGIN
    -- Get user email
    SELECT email INTO v_user_email
    FROM auth.users
    WHERE id = NEW.user_id;
    
    -- Check for achievements based on updated data
    -- First time setting horoscope preferences
    IF TG_TABLE_NAME = 'user_horoscope_preferences' AND TG_OP = 'INSERT' THEN
        PERFORM send_notification(
            'user_achievements',
            'horoscope_setup',
            'Welcome to the Cosmic Journey!',
            'You''ve set up your horoscope preferences. Your daily readings await!',
            json_build_object(
                'achievement', 'horoscope_setup',
                'user_id', NEW.user_id
            ),
            NEW.user_id
        );
    END IF;
    
    -- Horoscope reading streaks
    IF TG_TABLE_NAME = 'user_horoscope_preferences' AND TG_OP = 'UPDATE' THEN
        IF NEW.streak_days >= 7 AND (OLD.streak_days < 7 OR OLD.streak_days IS NULL) THEN
            PERFORM send_notification(
                'user_achievements',
                'horoscope_streak_7',
                'Cosmic Dedication!',
                'You''ve maintained a 7-day horoscope reading streak! The stars are aligned in your favor.',
                json_build_object(
                    'achievement', 'horoscope_streak_7',
                    'streak_days', NEW.streak_days,
                    'user_id', NEW.user_id
                ),
                NEW.user_id
            );
        ELSIF NEW.streak_days >= 30 AND (OLD.streak_days < 30 OR OLD.streak_days IS NULL) THEN
            PERFORM send_notification(
                'user_achievements',
                'horoscope_streak_30',
                'Celestial Master!',
                'Amazing! You''ve read your horoscope for 30 days straight. You''re truly connected to the cosmos!',
                json_build_object(
                    'achievement', 'horoscope_streak_30',
                    'streak_days', NEW.streak_days,
                    'user_id', NEW.user_id
                ),
                NEW.user_id
            );
        END IF;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$;

-- =============================================================================
-- CREATE NOTIFICATION TRIGGERS
-- =============================================================================

-- Social activity triggers
CREATE TRIGGER notify_new_glitter_post_trigger
    AFTER INSERT ON glitter_posts
    FOR EACH ROW EXECUTE FUNCTION notify_new_glitter_post();

CREATE TRIGGER notify_new_comment_trigger
    AFTER INSERT ON glitter_comments
    FOR EACH ROW EXECUTE FUNCTION notify_new_comment();

CREATE TRIGGER notify_new_reaction_trigger
    AFTER INSERT ON glitter_reactions
    FOR EACH ROW EXECUTE FUNCTION notify_new_reaction();

-- Community triggers
CREATE TRIGGER notify_new_poll_trigger
    AFTER INSERT ON polls
    FOR EACH ROW EXECUTE FUNCTION notify_new_poll();

-- Entertainment triggers
CREATE TRIGGER notify_daily_horoscope_trigger
    AFTER INSERT ON horoscope_readings
    FOR EACH ROW EXECUTE FUNCTION notify_daily_horoscope();

CREATE TRIGGER notify_tarot_activity_trigger
    AFTER INSERT ON tarot_readings
    FOR EACH ROW EXECUTE FUNCTION notify_entertainment_activity();

CREATE TRIGGER notify_oracle_activity_trigger
    AFTER INSERT ON oracle_consultations
    FOR EACH ROW EXECUTE FUNCTION notify_entertainment_activity();

CREATE TRIGGER notify_8ball_activity_trigger
    AFTER INSERT ON magic_8ball_consultations
    FOR EACH ROW EXECUTE FUNCTION notify_entertainment_activity();

-- Achievement triggers
CREATE TRIGGER notify_horoscope_achievements_trigger
    AFTER INSERT OR UPDATE ON user_horoscope_preferences
    FOR EACH ROW EXECUTE FUNCTION notify_user_achievement();

-- =============================================================================
-- REAL-TIME SUBSCRIPTION MANAGEMENT
-- =============================================================================

-- Get user's active subscriptions
CREATE OR REPLACE FUNCTION get_user_subscriptions(p_user_id UUID)
RETURNS TABLE (
    channel_name VARCHAR(100),
    is_subscribed BOOLEAN,
    notification_preferences JSONB,
    subscription_count INTEGER,
    last_notified_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        uns.channel_name,
        uns.is_subscribed,
        uns.notification_preferences,
        uns.subscription_count,
        uns.last_notified_at
    FROM user_notification_subscriptions uns
    WHERE uns.user_id = p_user_id
    ORDER BY uns.channel_name;
END;
$$;

-- Get unread notifications for user
CREATE OR REPLACE FUNCTION get_unread_notifications(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
    notification_id UUID,
    channel_name VARCHAR(100),
    notification_type VARCHAR(50),
    title VARCHAR(255),
    message TEXT,
    payload JSONB,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        rn.id,
        rn.channel_name,
        rn.notification_type,
        rn.title,
        rn.message,
        rn.payload,
        rn.created_at
    FROM realtime_notifications rn
    WHERE (rn.target_user_id = p_user_id OR rn.target_user_id IS NULL)
    AND rn.is_read = false
    AND rn.expires_at > NOW()
    ORDER BY rn.created_at DESC
    LIMIT p_limit;
END;
$$;

-- Auto-subscribe new users to default channels
CREATE OR REPLACE FUNCTION auto_subscribe_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_default_channels TEXT[] := ARRAY[
        'tabs_updates',
        'social_activity', 
        'horoscope_daily',
        'entertainment_updates',
        'user_achievements'
    ];
    v_channel TEXT;
BEGIN
    -- Subscribe to default channels
    FOREACH v_channel IN ARRAY v_default_channels
    LOOP
        INSERT INTO user_notification_subscriptions (user_id, channel_name)
        VALUES (NEW.id, v_channel)
        ON CONFLICT (user_id, channel_name) DO NOTHING;
    END LOOP;
    
    RETURN NEW;
END;
$$;

-- Create trigger for auto-subscription (if users table exists)
-- Note: This assumes auth.users table exists and we can create triggers on it
-- CREATE TRIGGER auto_subscribe_new_user_trigger
--     AFTER INSERT ON auth.users
--     FOR EACH ROW EXECUTE FUNCTION auto_subscribe_new_user();

-- =============================================================================
-- NOTIFICATION CLEANUP AND MAINTENANCE
-- =============================================================================

-- Clean expired notifications
CREATE OR REPLACE FUNCTION cleanup_expired_notifications()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    DELETE FROM realtime_notifications
    WHERE expires_at < NOW();
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    RETURN v_deleted_count;
END;
$$;

-- Update notification statistics
CREATE OR REPLACE FUNCTION update_notification_stats()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_channel_record RECORD;
    v_subscriber_count INTEGER;
BEGIN
    -- Update subscriber counts for all channels
    FOR v_channel_record IN
        SELECT channel_name FROM notification_channels WHERE is_active = true
    LOOP
        SELECT COUNT(*)
        INTO v_subscriber_count
        FROM user_notification_subscriptions
        WHERE channel_name = v_channel_record.channel_name AND is_subscribed = true;
        
        UPDATE notification_channels
        SET 
            current_subscribers = v_subscriber_count,
            updated_at = NOW()
        WHERE channel_name = v_channel_record.channel_name;
    END LOOP;
    
    RETURN 'Notification statistics updated for ' || 
           (SELECT COUNT(*) FROM notification_channels WHERE is_active = true) || ' channels';
END;
$$;

-- =============================================================================
-- GRANT PERMISSIONS
-- =============================================================================

-- Grant function permissions
GRANT EXECUTE ON FUNCTION subscribe_to_channel TO authenticated;
GRANT EXECUTE ON FUNCTION unsubscribe_from_channel TO authenticated;
GRANT EXECUTE ON FUNCTION send_notification TO service_role;
GRANT EXECUTE ON FUNCTION mark_notification_read TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_subscriptions TO authenticated;
GRANT EXECUTE ON FUNCTION get_unread_notifications TO authenticated;
GRANT EXECUTE ON FUNCTION cleanup_expired_notifications TO service_role;
GRANT EXECUTE ON FUNCTION update_notification_stats TO service_role;

-- Grant table permissions
GRANT SELECT ON notification_channels TO authenticated;
GRANT SELECT, INSERT, UPDATE ON user_notification_subscriptions TO authenticated;
GRANT SELECT ON realtime_notifications TO authenticated;

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE notification_channels IS 'Available notification channels for real-time updates';
COMMENT ON TABLE user_notification_subscriptions IS 'User subscriptions to notification channels';
COMMENT ON TABLE realtime_notifications IS 'Queue for real-time notifications to users';
COMMENT ON FUNCTION send_notification IS 'Send real-time notification to channel subscribers';
COMMENT ON FUNCTION subscribe_to_channel IS 'Subscribe user to notification channel';
COMMENT ON FUNCTION get_unread_notifications IS 'Get unread notifications for user';

-- Setup completion message
SELECT 'Tabs Real-time Subscriptions and Notifications Setup Complete!' as status, NOW() as setup_completed_at;
