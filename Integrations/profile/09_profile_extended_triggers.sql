-- =====================================================
-- CRYSTAL SOCIAL - PROFILE SYSTEM EXTENDED TRIGGERS
-- =====================================================
-- Additional triggers for missing functionality discovered
-- in avatar_picker, sound systems, and production files
-- =====================================================

-- =====================================================
-- PROFILE EDIT HISTORY TRACKING
-- =====================================================

-- Function to track profile edit history
CREATE OR REPLACE FUNCTION track_profile_edit_history()
RETURNS TRIGGER AS $$
DECLARE
    v_field_name VARCHAR(100);
    v_old_value TEXT;
    v_new_value TEXT;
BEGIN
    -- Track changes to user_profiles table
    IF TG_TABLE_NAME = 'user_profiles' THEN
        -- Track username changes
        IF OLD.username IS DISTINCT FROM NEW.username THEN
            INSERT INTO profile_edit_history (
                user_id, field_name, old_value, new_value, change_type
            ) VALUES (
                NEW.user_id, 'username', OLD.username, NEW.username, 'update'
            );
        END IF;
        
        -- Track display name changes
        IF OLD.display_name IS DISTINCT FROM NEW.display_name THEN
            INSERT INTO profile_edit_history (
                user_id, field_name, old_value, new_value, change_type
            ) VALUES (
                NEW.user_id, 'display_name', OLD.display_name, NEW.display_name, 'update'
            );
        END IF;
        
        -- Track bio changes
        IF OLD.bio IS DISTINCT FROM NEW.bio THEN
            INSERT INTO profile_edit_history (
                user_id, field_name, old_value, new_value, change_type
            ) VALUES (
                NEW.user_id, 'bio', OLD.bio, NEW.bio, 'update'
            );
        END IF;
        
        -- Track location changes
        IF OLD.location IS DISTINCT FROM NEW.location THEN
            INSERT INTO profile_edit_history (
                user_id, field_name, old_value, new_value, change_type
            ) VALUES (
                NEW.user_id, 'location', OLD.location, NEW.location, 'update'
            );
        END IF;
        
        -- Track avatar URL changes
        IF OLD.avatar_url IS DISTINCT FROM NEW.avatar_url THEN
            INSERT INTO profile_edit_history (
                user_id, field_name, old_value, new_value, change_type
            ) VALUES (
                NEW.user_id, 'avatar_url', OLD.avatar_url, NEW.avatar_url, 'update'
            );
        END IF;
        
        -- Track interests changes
        IF OLD.interests IS DISTINCT FROM NEW.interests THEN
            INSERT INTO profile_edit_history (
                user_id, field_name, old_value, new_value, change_type
            ) VALUES (
                NEW.user_id, 'interests', 
                COALESCE(array_to_string(OLD.interests, ','), ''),
                COALESCE(array_to_string(NEW.interests, ','), ''),
                'update'
            );
        END IF;
    END IF;
    
    -- Track changes to user_profile_extensions table
    IF TG_TABLE_NAME = 'user_profile_extensions' THEN
        -- Track zodiac sign changes
        IF OLD.zodiac_sign IS DISTINCT FROM NEW.zodiac_sign THEN
            INSERT INTO profile_edit_history (
                user_id, field_name, old_value, new_value, change_type
            ) VALUES (
                NEW.user_id, 'zodiac_sign', OLD.zodiac_sign, NEW.zodiac_sign, 'update'
            );
        END IF;
        
        -- Track relationship status changes
        IF OLD.relationship_status IS DISTINCT FROM NEW.relationship_status THEN
            INSERT INTO profile_edit_history (
                user_id, field_name, old_value, new_value, change_type
            ) VALUES (
                NEW.user_id, 'relationship_status', OLD.relationship_status, NEW.relationship_status, 'update'
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for profile edit history
CREATE TRIGGER trigger_track_profile_edits
    AFTER UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION track_profile_edit_history();

CREATE TRIGGER trigger_track_profile_extensions_edits
    AFTER UPDATE ON user_profile_extensions
    FOR EACH ROW
    EXECUTE FUNCTION track_profile_edit_history();

-- =====================================================
-- AUTOMATED PROFILE COMPLETION UPDATES
-- =====================================================

-- Function to automatically update profile completion
CREATE OR REPLACE FUNCTION auto_update_profile_completion()
RETURNS TRIGGER AS $$
BEGIN
    -- Update profile completion tracking when relevant changes occur
    PERFORM update_detailed_profile_completion(
        CASE 
            WHEN TG_TABLE_NAME = 'user_profiles' THEN NEW.user_id
            WHEN TG_TABLE_NAME = 'user_social_links' THEN NEW.user_id
            WHEN TG_TABLE_NAME = 'user_privacy_settings' THEN NEW.user_id
            WHEN TG_TABLE_NAME = 'user_profile_themes' THEN NEW.user_id
            WHEN TG_TABLE_NAME = 'user_inventory' THEN NEW.user_id
            WHEN TG_TABLE_NAME = 'user_connections' THEN NEW.user_id
            ELSE NULL
        END
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for automatic profile completion updates
CREATE TRIGGER trigger_auto_update_completion_profiles
    AFTER INSERT OR UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION auto_update_profile_completion();

CREATE TRIGGER trigger_auto_update_completion_social
    AFTER INSERT OR UPDATE OR DELETE ON user_social_links
    FOR EACH ROW
    EXECUTE FUNCTION auto_update_profile_completion();

CREATE TRIGGER trigger_auto_update_completion_privacy
    AFTER INSERT OR UPDATE ON user_privacy_settings
    FOR EACH ROW
    EXECUTE FUNCTION auto_update_profile_completion();

CREATE TRIGGER trigger_auto_update_completion_themes
    AFTER INSERT OR UPDATE ON user_profile_themes
    FOR EACH ROW
    EXECUTE FUNCTION auto_update_profile_completion();

CREATE TRIGGER trigger_auto_update_completion_inventory
    AFTER INSERT OR UPDATE ON user_inventory
    FOR EACH ROW
    EXECUTE FUNCTION auto_update_profile_completion();

CREATE TRIGGER trigger_auto_update_completion_connections
    AFTER INSERT OR UPDATE ON user_connections
    FOR EACH ROW
    EXECUTE FUNCTION auto_update_profile_completion();

-- =====================================================
-- AVATAR UPLOAD PROCESSING
-- =====================================================

-- Function to handle avatar upload status changes
CREATE OR REPLACE FUNCTION process_avatar_upload_status()
RETURNS TRIGGER AS $$
BEGIN
    -- When avatar upload is completed successfully
    IF NEW.upload_status = 'completed' AND OLD.upload_status != 'completed' THEN
        -- Update user profile with new avatar URL
        UPDATE user_profiles
        SET avatar_url = NEW.file_path,
            updated_at = NOW()
        WHERE user_id = NEW.user_id;
        
        -- Mark other avatars as not current
        UPDATE user_avatar_uploads
        SET is_current = false
        WHERE user_id = NEW.user_id AND id != NEW.id;
        
        -- Update profile completion tracking
        PERFORM update_detailed_profile_completion(NEW.user_id);
        
        -- Award achievement if this is first custom avatar
        IF NOT EXISTS (
            SELECT 1 FROM user_avatar_uploads
            WHERE user_id = NEW.user_id 
            AND upload_status = 'completed' 
            AND id != NEW.id
        ) THEN
            PERFORM update_achievement_progress(NEW.user_id, 'first_custom_avatar', 1);
        END IF;
    END IF;
    
    -- When avatar upload fails
    IF NEW.upload_status = 'failed' AND OLD.upload_status != 'failed' THEN
        -- Log the failure (could be used for analytics)
        INSERT INTO validation_logs (
            validation_type, component_name, validation_result,
            error_messages, validation_metadata
        ) VALUES (
            'avatar_upload', 'AvatarUploadProcessor', 'failed',
            ARRAY['Avatar upload failed for user ' || NEW.user_id::TEXT],
            json_build_object('upload_id', NEW.id, 'file_size', NEW.file_size)::jsonb
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for avatar upload processing
CREATE TRIGGER trigger_process_avatar_upload
    AFTER UPDATE ON user_avatar_uploads
    FOR EACH ROW
    EXECUTE FUNCTION process_avatar_upload_status();

-- =====================================================
-- SOUND INVENTORY MANAGEMENT
-- =====================================================

-- Function to manage sound inventory updates
CREATE OR REPLACE FUNCTION manage_sound_inventory()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- When user gets a new sound, update their sound settings if it's their first
        IF NOT EXISTS (
            SELECT 1 FROM user_sound_inventory
            WHERE user_id = NEW.user_id AND id != NEW.id
        ) THEN
            -- Set as default notification sound if none set
            UPDATE user_sound_settings
            SET default_notification_sound = (
                SELECT file_path FROM sound_catalog 
                WHERE sound_id = NEW.sound_id
            )
            WHERE user_id = NEW.user_id 
            AND default_notification_sound IS NULL;
        END IF;
    END IF;
    
    IF TG_OP = 'UPDATE' THEN
        -- When sound is marked as favorite
        IF NEW.is_favorite = true AND OLD.is_favorite = false THEN
            -- Limit to 10 favorites per user
            IF (SELECT COUNT(*) FROM user_sound_inventory 
                WHERE user_id = NEW.user_id AND is_favorite = true) > 10 THEN
                -- Remove oldest favorite using a subquery
                UPDATE user_sound_inventory
                SET is_favorite = false
                WHERE id = (
                    SELECT id FROM user_sound_inventory
                    WHERE user_id = NEW.user_id 
                    AND is_favorite = true
                    AND id != NEW.id
                    ORDER BY unlocked_at ASC
                    LIMIT 1
                );
            END IF;
        END IF;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Create trigger for sound inventory management
CREATE TRIGGER trigger_manage_sound_inventory
    AFTER INSERT OR UPDATE ON user_sound_inventory
    FOR EACH ROW
    EXECUTE FUNCTION manage_sound_inventory();

-- =====================================================
-- SOCIAL LINKS VALIDATION
-- =====================================================

-- Function to validate social media links
CREATE OR REPLACE FUNCTION validate_social_links()
RETURNS TRIGGER AS $$
BEGIN
    -- Validate Instagram username (alphanumeric, dots, underscores only)
    IF NEW.platform = 'instagram' AND NEW.username IS NOT NULL THEN
        IF NOT NEW.username ~ '^[a-zA-Z0-9_.]+$' THEN
            RAISE EXCEPTION 'Invalid Instagram username format';
        END IF;
        
        -- Auto-generate URL if not provided
        IF NEW.url IS NULL THEN
            NEW.url := 'https://instagram.com/' || NEW.username;
        END IF;
    END IF;
    
    -- Validate Twitter username (alphanumeric and underscores only)
    IF NEW.platform = 'twitter' AND NEW.username IS NOT NULL THEN
        IF NOT NEW.username ~ '^[a-zA-Z0-9_]+$' THEN
            RAISE EXCEPTION 'Invalid Twitter username format';
        END IF;
        
        -- Auto-generate URL if not provided
        IF NEW.url IS NULL THEN
            NEW.url := 'https://twitter.com/' || NEW.username;
        END IF;
    END IF;
    
    -- Validate website URL format
    IF NEW.platform = 'website' AND NEW.url IS NOT NULL THEN
        IF NOT NEW.url ~ '^https?://' THEN
            NEW.url := 'https://' || NEW.url;
        END IF;
    END IF;
    
    -- Limit to 5 social links per user
    IF TG_OP = 'INSERT' THEN
        IF (SELECT COUNT(*) FROM user_social_links WHERE user_id = NEW.user_id) >= 5 THEN
            RAISE EXCEPTION 'Maximum 5 social links allowed per user';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for social links validation
CREATE TRIGGER trigger_validate_social_links
    BEFORE INSERT OR UPDATE ON user_social_links
    FOR EACH ROW
    EXECUTE FUNCTION validate_social_links();

-- =====================================================
-- PREMIUM PURCHASE PROCESSING
-- =====================================================

-- Function to process premium purchases
CREATE OR REPLACE FUNCTION process_premium_purchase()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.purchase_status = 'completed' THEN
        -- Add purchased item to user inventory
        INSERT INTO user_inventory (
            user_id, item_id, item_type, unlock_method, metadata
        )
        SELECT 
            NEW.user_id,
            NEW.content_id,
            pc.content_type,
            'premium_purchase',
            json_build_object('purchase_id', NEW.id)::jsonb
        FROM premium_content pc
        WHERE pc.content_id = NEW.content_id;
        
        -- Update purchase count
        UPDATE premium_content
        SET current_purchases = current_purchases + 1
        WHERE content_id = NEW.content_id;
        
        -- Award achievements for premium purchases
        PERFORM update_achievement_progress(NEW.user_id, 'first_premium_purchase', 1);
        PERFORM update_achievement_progress(NEW.user_id, 'premium_spender', 1);
    END IF;
    
    IF TG_OP = 'UPDATE' AND NEW.purchase_status = 'refunded' AND OLD.purchase_status != 'refunded' THEN
        -- Remove item from user inventory on refund
        DELETE FROM user_inventory
        WHERE user_id = NEW.user_id 
        AND item_id = NEW.content_id
        AND unlock_method = 'premium_purchase';
        
        -- Restore gems if paid with gems
        IF NEW.currency_type = 'GEMS' THEN
            UPDATE user_activity_stats
            SET currency_gems = currency_gems + NEW.amount_paid::INTEGER
            WHERE user_id = NEW.user_id;
        END IF;
        
        -- Update purchase count
        UPDATE premium_content
        SET current_purchases = GREATEST(current_purchases - 1, 0)
        WHERE content_id = NEW.content_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for premium purchase processing
CREATE TRIGGER trigger_process_premium_purchase
    AFTER INSERT OR UPDATE ON user_premium_purchases
    FOR EACH ROW
    EXECUTE FUNCTION process_premium_purchase();

-- =====================================================
-- PERFORMANCE METRICS COLLECTION
-- =====================================================

-- Function to automatically collect performance metrics
CREATE OR REPLACE FUNCTION collect_performance_metrics()
RETURNS TRIGGER AS $$
DECLARE
    v_operation_duration INTEGER;
BEGIN
    -- Calculate operation duration if timestamps are available
    IF TG_TABLE_NAME = 'user_avatar_uploads' AND NEW.upload_status = 'completed' THEN
        v_operation_duration := EXTRACT(EPOCH FROM (NOW() - NEW.created_at)) * 1000;
        
        PERFORM record_performance_metric(
            'avatar_upload_duration',
            'media_processing',
            v_operation_duration,
            'milliseconds',
            NEW.user_id,
            NULL,
            json_build_object('file_size', NEW.file_size, 'mime_type', NEW.mime_type)::jsonb
        );
    END IF;
    
    -- Track profile update frequency
    IF TG_TABLE_NAME = 'user_profiles' AND TG_OP = 'UPDATE' THEN
        PERFORM record_performance_metric(
            'profile_update_frequency',
            'user_activity',
            1,
            'count',
            NEW.user_id,
            NULL,
            json_build_object('updated_fields', 
                CASE 
                    WHEN OLD.display_name != NEW.display_name THEN 'display_name'
                    WHEN OLD.bio != NEW.bio THEN 'bio'
                    WHEN OLD.location != NEW.location THEN 'location'
                    ELSE 'other'
                END
            )::jsonb
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for performance metrics collection
CREATE TRIGGER trigger_collect_avatar_metrics
    AFTER UPDATE ON user_avatar_uploads
    FOR EACH ROW
    EXECUTE FUNCTION collect_performance_metrics();

CREATE TRIGGER trigger_collect_profile_metrics
    AFTER UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION collect_performance_metrics();

-- =====================================================
-- INVENTORY MANAGEMENT
-- =====================================================

-- Function to manage user inventory
CREATE OR REPLACE FUNCTION manage_user_inventory()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Limit inventory size per item type
        DECLARE
            v_max_items INTEGER;
            v_current_count INTEGER;
        BEGIN
            -- Set max limits based on item type
            v_max_items := CASE NEW.item_type
                WHEN 'decoration' THEN 100
                WHEN 'theme' THEN 50
                WHEN 'sound' THEN 50
                ELSE 200
            END;
            
            -- Count current items of this type
            SELECT COUNT(*) INTO v_current_count
            FROM user_inventory
            WHERE user_id = NEW.user_id AND item_type = NEW.item_type;
            
            -- Check if limit exceeded
            IF v_current_count >= v_max_items THEN
                RAISE EXCEPTION 'Maximum % items of type % reached', v_max_items, NEW.item_type;
            END IF;
        END;
        
        -- Auto-equip first decoration/theme
        IF NEW.item_type IN ('decoration', 'theme') THEN
            IF NOT EXISTS (
                SELECT 1 FROM user_inventory
                WHERE user_id = NEW.user_id 
                AND item_type = NEW.item_type 
                AND equipped = true
            ) THEN
                NEW.equipped := true;
            END IF;
        END IF;
    END IF;
    
    IF TG_OP = 'UPDATE' THEN
        -- When equipping an item, unequip others of the same type
        IF NEW.equipped = true AND OLD.equipped = false THEN
            -- For decorations and themes, only one can be equipped at a time
            IF NEW.item_type IN ('decoration', 'theme') THEN
                UPDATE user_inventory
                SET equipped = false
                WHERE user_id = NEW.user_id 
                AND item_type = NEW.item_type 
                AND id != NEW.id
                AND equipped = true;
            END IF;
            
            -- Update profile when decoration is equipped
            IF NEW.item_type = 'decoration' THEN
                UPDATE user_profiles
                SET avatar_decoration = NEW.item_id,
                    updated_at = NOW()
                WHERE user_id = NEW.user_id;
            END IF;
            
            -- Update profile when theme is equipped
            IF NEW.item_type = 'theme' THEN
                -- Update theme in user_profile_themes table
                UPDATE user_profile_themes
                SET is_active = false
                WHERE user_id = NEW.user_id;
                
                UPDATE user_profile_themes
                SET is_active = true
                WHERE user_id = NEW.user_id AND theme_id = NEW.item_id;
            END IF;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for inventory management
CREATE TRIGGER trigger_manage_user_inventory
    BEFORE INSERT OR UPDATE ON user_inventory
    FOR EACH ROW
    EXECUTE FUNCTION manage_user_inventory();

-- =====================================================
-- SYSTEM CONFIGURATION VALIDATION
-- =====================================================

-- Function to validate system configuration changes
CREATE OR REPLACE FUNCTION validate_system_config()
RETURNS TRIGGER AS $$
BEGIN
    -- Validate configuration values based on category and key
    IF NEW.config_category = 'profile' THEN
        IF NEW.config_key = 'max_bio_length' THEN
            IF (NEW.config_value::TEXT)::INTEGER < 100 OR (NEW.config_value::TEXT)::INTEGER > 2000 THEN
                RAISE EXCEPTION 'Max bio length must be between 100 and 2000 characters';
            END IF;
        END IF;
        
        IF NEW.config_key = 'max_interests' THEN
            IF (NEW.config_value::TEXT)::INTEGER < 5 OR (NEW.config_value::TEXT)::INTEGER > 50 THEN
                RAISE EXCEPTION 'Max interests must be between 5 and 50';
            END IF;
        END IF;
    END IF;
    
    IF NEW.config_category = 'media' THEN
        IF NEW.config_key = 'max_avatar_size' THEN
            IF (NEW.config_value::TEXT)::BIGINT < 1048576 OR (NEW.config_value::TEXT)::BIGINT > 10485760 THEN
                RAISE EXCEPTION 'Max avatar size must be between 1MB and 10MB';
            END IF;
        END IF;
    END IF;
    
    -- Log configuration changes
    INSERT INTO validation_logs (
        validation_type, component_name, validation_result,
        validation_metadata
    ) VALUES (
        'config_change', 'SystemConfiguration', 'passed',
        json_build_object(
            'category', NEW.config_category,
            'key', NEW.config_key,
            'old_value', OLD.config_value,
            'new_value', NEW.config_value
        )::jsonb
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for system configuration validation
CREATE TRIGGER trigger_validate_system_config
    BEFORE UPDATE ON system_configuration
    FOR EACH ROW
    EXECUTE FUNCTION validate_system_config();

-- =====================================================
-- CLEANUP AND MAINTENANCE TRIGGERS
-- =====================================================

-- Function for automatic cleanup of old data
CREATE OR REPLACE FUNCTION cleanup_old_data()
RETURNS TRIGGER AS $$
BEGIN
    -- Clean old performance metrics (keep last 30 days)
    IF TG_TABLE_NAME = 'performance_metrics' THEN
        DELETE FROM performance_metrics
        WHERE recorded_at < NOW() - INTERVAL '30 days';
    END IF;
    
    -- Clean old profile edit history (keep last 90 days)
    IF TG_TABLE_NAME = 'profile_edit_history' THEN
        DELETE FROM profile_edit_history
        WHERE edited_at < NOW() - INTERVAL '90 days';
    END IF;
    
    -- Clean old validation logs (keep last 60 days)
    IF TG_TABLE_NAME = 'validation_logs' THEN
        DELETE FROM validation_logs
        WHERE performed_at < NOW() - INTERVAL '60 days';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Note: These cleanup triggers would typically be scheduled jobs rather than row-level triggers
-- But we can create them as periodic maintenance functions

-- =====================================================
-- NOTIFICATION TRIGGERS
-- =====================================================

-- Function to send notifications for important events
CREATE OR REPLACE FUNCTION send_profile_notifications()
RETURNS TRIGGER AS $$
BEGIN
    -- Notify when profile completion milestones are reached
    IF TG_TABLE_NAME = 'profile_completion_tracking' THEN
        IF NEW.completion_percentage >= 50 AND OLD.completion_percentage < 50 THEN
            -- Could integrate with notification system here
            PERFORM update_achievement_progress(NEW.user_id, 'profile_half_complete', 1);
        END IF;
        
        IF NEW.completion_percentage >= 100 AND OLD.completion_percentage < 100 THEN
            PERFORM update_achievement_progress(NEW.user_id, 'profile_complete', 1);
        END IF;
    END IF;
    
    -- Notify when premium purchases are completed
    IF TG_TABLE_NAME = 'user_premium_purchases' AND NEW.purchase_status = 'completed' THEN
        -- Could send purchase confirmation notification
        NULL; -- Placeholder for notification logic
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for notifications
CREATE TRIGGER trigger_profile_completion_notifications
    AFTER UPDATE ON profile_completion_tracking
    FOR EACH ROW
    EXECUTE FUNCTION send_profile_notifications();

CREATE TRIGGER trigger_premium_purchase_notifications
    AFTER INSERT OR UPDATE ON user_premium_purchases
    FOR EACH ROW
    EXECUTE FUNCTION send_profile_notifications();

-- =====================================================
-- TRIGGER MANAGEMENT FUNCTIONS
-- =====================================================

-- Function to disable all profile triggers (for maintenance)
CREATE OR REPLACE FUNCTION disable_profile_triggers()
RETURNS VOID AS $$
BEGIN
    ALTER TABLE user_profiles DISABLE TRIGGER ALL;
    ALTER TABLE user_avatar_uploads DISABLE TRIGGER ALL;
    ALTER TABLE user_inventory DISABLE TRIGGER ALL;
    ALTER TABLE user_social_links DISABLE TRIGGER ALL;
    ALTER TABLE user_premium_purchases DISABLE TRIGGER ALL;
    ALTER TABLE profile_completion_tracking DISABLE TRIGGER ALL;
    ALTER TABLE system_configuration DISABLE TRIGGER ALL;
END;
$$ LANGUAGE plpgsql;

-- Function to enable all profile triggers
CREATE OR REPLACE FUNCTION enable_profile_triggers()
RETURNS VOID AS $$
BEGIN
    ALTER TABLE user_profiles ENABLE TRIGGER ALL;
    ALTER TABLE user_avatar_uploads ENABLE TRIGGER ALL;
    ALTER TABLE user_inventory ENABLE TRIGGER ALL;
    ALTER TABLE user_social_links ENABLE TRIGGER ALL;
    ALTER TABLE user_premium_purchases ENABLE TRIGGER ALL;
    ALTER TABLE profile_completion_tracking ENABLE TRIGGER ALL;
    ALTER TABLE system_configuration ENABLE TRIGGER ALL;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- GRANTS AND PERMISSIONS
-- =====================================================

-- Grant permissions for maintenance functions
GRANT EXECUTE ON FUNCTION disable_profile_triggers() TO service_role;
GRANT EXECUTE ON FUNCTION enable_profile_triggers() TO service_role;

-- =====================================================
-- END OF EXTENDED TRIGGERS
-- =====================================================
