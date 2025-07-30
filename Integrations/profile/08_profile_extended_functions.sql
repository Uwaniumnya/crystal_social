-- =====================================================
-- CRYSTAL SOCIAL - PROFILE SYSTEM EXTENDED FUNCTIONS
-- =====================================================
-- Additional functions for missing functionality discovered
-- in avatar_picker, sound systems, and production files
-- =====================================================

-- =====================================================
-- AVATAR MANAGEMENT FUNCTIONS
-- =====================================================

-- Get user's preset avatar options
CREATE OR REPLACE FUNCTION get_user_preset_avatars(
    p_user_id UUID,
    p_category VARCHAR(100) DEFAULT NULL
)
RETURNS TABLE(
    avatar_id VARCHAR(100),
    name VARCHAR(200),
    description TEXT,
    file_path VARCHAR(500),
    category VARCHAR(100),
    is_premium BOOLEAN,
    is_unlocked BOOLEAN,
    unlock_cost INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pa.avatar_id,
        pa.name,
        pa.description,
        pa.file_path,
        pa.category,
        pa.is_premium,
        CASE 
            WHEN pa.is_premium = false THEN true
            WHEN ui.user_id IS NOT NULL THEN true
            ELSE false
        END as is_unlocked,
        pa.unlock_cost
    FROM preset_avatars pa
    LEFT JOIN user_inventory ui ON (
        ui.user_id = p_user_id 
        AND ui.item_id = pa.avatar_id 
        AND ui.item_type = 'avatar'
    )
    WHERE pa.is_active = true
    AND (p_category IS NULL OR pa.category = p_category)
    ORDER BY pa.sort_order, pa.name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Upload custom avatar
CREATE OR REPLACE FUNCTION upload_custom_avatar(
    p_user_id UUID,
    p_file_name VARCHAR(255),
    p_file_path VARCHAR(500),
    p_file_size BIGINT,
    p_mime_type VARCHAR(100),
    p_upload_metadata JSONB DEFAULT '{}'
)
RETURNS JSON AS $$
DECLARE
    v_upload_id UUID;
    v_result JSON;
BEGIN
    -- Validate file size (5MB max)
    IF p_file_size > 5242880 THEN
        RETURN json_build_object(
            'success', false,
            'error', 'File size exceeds 5MB limit'
        );
    END IF;
    
    -- Validate mime type
    IF p_mime_type NOT IN ('image/jpeg', 'image/png', 'image/gif', 'image/webp') THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Unsupported file format'
        );
    END IF;
    
    -- Mark previous avatars as not current
    UPDATE user_avatar_uploads
    SET is_current = false
    WHERE user_id = p_user_id;
    
    -- Insert new avatar upload
    INSERT INTO user_avatar_uploads (
        user_id, file_name, file_path, file_size, mime_type,
        upload_status, is_current, upload_metadata
    ) VALUES (
        p_user_id, p_file_name, p_file_path, p_file_size, p_mime_type,
        'processing', true, p_upload_metadata
    ) RETURNING id INTO v_upload_id;
    
    -- Update user profile avatar URL
    UPDATE user_profiles
    SET avatar_url = p_file_path,
        updated_at = NOW()
    WHERE user_id = p_user_id;
    
    v_result := json_build_object(
        'success', true,
        'upload_id', v_upload_id,
        'file_path', p_file_path,
        'message', 'Avatar uploaded successfully'
    );
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get user's avatar decoration inventory
CREATE OR REPLACE FUNCTION get_user_decoration_inventory(
    p_user_id UUID,
    p_equipped_only BOOLEAN DEFAULT false
)
RETURNS TABLE(
    decoration_id VARCHAR(100),
    name VARCHAR(200),
    description TEXT,
    image_path VARCHAR(500),
    category VARCHAR(100),
    rarity VARCHAR(50),
    is_equipped BOOLEAN,
    unlocked_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        adc.decoration_id,
        adc.name,
        adc.description,
        adc.image_path,
        adc.category,
        adc.rarity,
        ui.equipped,
        ui.unlocked_at
    FROM user_inventory ui
    JOIN avatar_decorations_catalog adc ON adc.decoration_id = ui.item_id
    WHERE ui.user_id = p_user_id
    AND ui.item_type = 'decoration'
    AND (p_equipped_only = false OR ui.equipped = true)
    ORDER BY ui.equipped DESC, adc.rarity, adc.name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- SOUND SYSTEM FUNCTIONS
-- =====================================================

-- Get available sounds for user
CREATE OR REPLACE FUNCTION get_user_available_sounds(
    p_user_id UUID,
    p_category VARCHAR(100) DEFAULT NULL,
    p_sound_type VARCHAR(50) DEFAULT NULL -- 'ringtone' or 'notification'
)
RETURNS TABLE(
    sound_id VARCHAR(100),
    name VARCHAR(200),
    description TEXT,
    category VARCHAR(100),
    file_path VARCHAR(500),
    duration_seconds DECIMAL(5,2),
    is_premium BOOLEAN,
    is_owned BOOLEAN,
    is_favorite BOOLEAN,
    icon_name VARCHAR(100),
    color_hex VARCHAR(7)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sc.sound_id,
        sc.name,
        sc.description,
        sc.category,
        sc.file_path,
        sc.duration_seconds,
        sc.is_premium,
        CASE 
            WHEN sc.is_premium = false THEN true
            WHEN usi.user_id IS NOT NULL THEN true
            ELSE false
        END as is_owned,
        COALESCE(usi.is_favorite, false) as is_favorite,
        sc.icon_name,
        sc.color_hex
    FROM sound_catalog sc
    LEFT JOIN user_sound_inventory usi ON (
        usi.user_id = p_user_id 
        AND usi.sound_id = sc.sound_id
    )
    WHERE sc.is_active = true
    AND (p_category IS NULL OR sc.category = p_category)
    AND (p_sound_type IS NULL OR 
         (p_sound_type = 'ringtone' AND sc.is_ringtone = true) OR
         (p_sound_type = 'notification' AND sc.is_notification = true))
    ORDER BY sc.category, sc.sort_order, sc.name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Set user's custom ringtone for specific contact
CREATE OR REPLACE FUNCTION set_custom_ringtone(
    p_owner_id UUID,
    p_contact_id UUID,
    p_sound_id VARCHAR(100),
    p_volume DECIMAL(3,2) DEFAULT 0.7
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    -- Validate volume range
    IF p_volume < 0.0 OR p_volume > 1.0 THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Volume must be between 0.0 and 1.0'
        );
    END IF;
    
    -- Verify user owns the sound (if premium)
    IF NOT EXISTS (
        SELECT 1 FROM sound_catalog sc
        LEFT JOIN user_sound_inventory usi ON (
            usi.user_id = p_owner_id AND usi.sound_id = sc.sound_id
        )
        WHERE sc.sound_id = p_sound_id
        AND (sc.is_premium = false OR usi.user_id IS NOT NULL)
    ) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Sound not available or not owned'
        );
    END IF;
    
    -- Insert or update custom ringtone
    INSERT INTO user_custom_ringtones (
        owner_id, contact_id, sound_id, custom_volume
    ) VALUES (
        p_owner_id, p_contact_id, p_sound_id, p_volume
    )
    ON CONFLICT (owner_id, contact_id)
    DO UPDATE SET
        sound_id = EXCLUDED.sound_id,
        custom_volume = EXCLUDED.custom_volume,
        updated_at = NOW();
    
    -- Update usage count
    UPDATE user_sound_inventory
    SET usage_count = usage_count + 1,
        last_used_at = NOW()
    WHERE user_id = p_owner_id AND sound_id = p_sound_id;
    
    v_result := json_build_object(
        'success', true,
        'message', 'Custom ringtone set successfully'
    );
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- SOCIAL MEDIA INTEGRATION FUNCTIONS
-- =====================================================

-- Update user social media links
CREATE OR REPLACE FUNCTION update_social_links(
    p_user_id UUID,
    p_social_links JSONB
)
RETURNS JSON AS $$
DECLARE
    v_platform VARCHAR(50);
    v_link_data JSONB;
    v_updated_count INTEGER := 0;
    v_result JSON;
BEGIN
    -- Delete existing social links
    DELETE FROM user_social_links WHERE user_id = p_user_id;
    
    -- Insert new social links
    FOR v_platform, v_link_data IN SELECT * FROM jsonb_each(p_social_links)
    LOOP
        IF v_link_data->>'username' IS NOT NULL AND v_link_data->>'username' != '' THEN
            INSERT INTO user_social_links (
                user_id, platform, username, url, is_public, display_order
            ) VALUES (
                p_user_id,
                v_platform,
                v_link_data->>'username',
                v_link_data->>'url',
                COALESCE((v_link_data->>'is_public')::BOOLEAN, true),
                COALESCE((v_link_data->>'display_order')::INTEGER, 0)
            );
            v_updated_count := v_updated_count + 1;
        END IF;
    END LOOP;
    
    -- Update profile completion
    PERFORM update_profile_completion_percentage(p_user_id);
    
    v_result := json_build_object(
        'success', true,
        'updated_links', v_updated_count,
        'message', 'Social links updated successfully'
    );
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- PRIVACY SETTINGS FUNCTIONS
-- =====================================================

-- Update user privacy settings
CREATE OR REPLACE FUNCTION update_privacy_settings(
    p_user_id UUID,
    p_settings JSONB
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    INSERT INTO user_privacy_settings (
        user_id,
        profile_visibility,
        show_online_status,
        show_last_seen,
        show_location,
        show_interests,
        show_social_links,
        show_statistics,
        show_achievements,
        show_activity_feed,
        allow_friend_requests,
        allow_messages,
        allow_profile_comments,
        allow_tagging,
        show_in_search,
        data_sharing_consent,
        analytics_consent,
        marketing_consent
    ) VALUES (
        p_user_id,
        COALESCE(p_settings->>'profile_visibility', 'public'),
        COALESCE((p_settings->>'show_online_status')::BOOLEAN, true),
        COALESCE((p_settings->>'show_last_seen')::BOOLEAN, true),
        COALESCE((p_settings->>'show_location')::BOOLEAN, true),
        COALESCE((p_settings->>'show_interests')::BOOLEAN, true),
        COALESCE((p_settings->>'show_social_links')::BOOLEAN, true),
        COALESCE((p_settings->>'show_statistics')::BOOLEAN, true),
        COALESCE((p_settings->>'show_achievements')::BOOLEAN, true),
        COALESCE((p_settings->>'show_activity_feed')::BOOLEAN, true),
        COALESCE((p_settings->>'allow_friend_requests')::BOOLEAN, true),
        COALESCE((p_settings->>'allow_messages')::BOOLEAN, true),
        COALESCE((p_settings->>'allow_profile_comments')::BOOLEAN, true),
        COALESCE((p_settings->>'allow_tagging')::BOOLEAN, true),
        COALESCE((p_settings->>'show_in_search')::BOOLEAN, true),
        COALESCE((p_settings->>'data_sharing_consent')::BOOLEAN, false),
        COALESCE((p_settings->>'analytics_consent')::BOOLEAN, false),
        COALESCE((p_settings->>'marketing_consent')::BOOLEAN, false)
    )
    ON CONFLICT (user_id)
    DO UPDATE SET
        profile_visibility = EXCLUDED.profile_visibility,
        show_online_status = EXCLUDED.show_online_status,
        show_last_seen = EXCLUDED.show_last_seen,
        show_location = EXCLUDED.show_location,
        show_interests = EXCLUDED.show_interests,
        show_social_links = EXCLUDED.show_social_links,
        show_statistics = EXCLUDED.show_statistics,
        show_achievements = EXCLUDED.show_achievements,
        show_activity_feed = EXCLUDED.show_activity_feed,
        allow_friend_requests = EXCLUDED.allow_friend_requests,
        allow_messages = EXCLUDED.allow_messages,
        allow_profile_comments = EXCLUDED.allow_profile_comments,
        allow_tagging = EXCLUDED.allow_tagging,
        show_in_search = EXCLUDED.show_in_search,
        data_sharing_consent = EXCLUDED.data_sharing_consent,
        analytics_consent = EXCLUDED.analytics_consent,
        marketing_consent = EXCLUDED.marketing_consent,
        updated_at = NOW();
    
    v_result := json_build_object(
        'success', true,
        'message', 'Privacy settings updated successfully'
    );
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- SYSTEM CONFIGURATION FUNCTIONS
-- =====================================================

-- Get system configuration
CREATE OR REPLACE FUNCTION get_system_config(
    p_category VARCHAR(100) DEFAULT NULL,
    p_environment VARCHAR(50) DEFAULT 'production'
)
RETURNS TABLE(
    config_key VARCHAR(200),
    config_value JSONB,
    description TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sc.config_key,
        sc.config_value,
        sc.description
    FROM system_configuration sc
    WHERE (p_category IS NULL OR sc.config_category = p_category)
    AND sc.environment = p_environment
    ORDER BY sc.config_category, sc.config_key;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update system configuration
CREATE OR REPLACE FUNCTION update_system_config(
    p_category VARCHAR(100),
    p_key VARCHAR(200),
    p_value JSONB,
    p_description TEXT DEFAULT NULL,
    p_environment VARCHAR(50) DEFAULT 'production'
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    INSERT INTO system_configuration (
        config_category, config_key, config_value, description, environment
    ) VALUES (
        p_category, p_key, p_value, p_description, p_environment
    )
    ON CONFLICT (config_category, config_key, environment)
    DO UPDATE SET
        config_value = EXCLUDED.config_value,
        description = COALESCE(EXCLUDED.description, system_configuration.description),
        updated_at = NOW();
    
    v_result := json_build_object(
        'success', true,
        'message', 'Configuration updated successfully'
    );
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- PERFORMANCE MONITORING FUNCTIONS
-- =====================================================

-- Record performance metric
CREATE OR REPLACE FUNCTION record_performance_metric(
    p_metric_name VARCHAR(100),
    p_metric_category VARCHAR(50),
    p_metric_value DECIMAL(15,6),
    p_metric_unit VARCHAR(20) DEFAULT NULL,
    p_user_id UUID DEFAULT NULL,
    p_session_id VARCHAR(100) DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
    v_metric_id UUID;
BEGIN
    INSERT INTO performance_metrics (
        metric_name, metric_category, metric_value, metric_unit,
        user_id, session_id, metadata
    ) VALUES (
        p_metric_name, p_metric_category, p_metric_value, p_metric_unit,
        p_user_id, p_session_id, p_metadata
    ) RETURNING id INTO v_metric_id;
    
    RETURN v_metric_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get performance analytics
CREATE OR REPLACE FUNCTION get_performance_analytics(
    p_metric_category VARCHAR(50) DEFAULT NULL,
    p_hours_back INTEGER DEFAULT 24
)
RETURNS TABLE(
    metric_name VARCHAR(100),
    avg_value DECIMAL(15,6),
    min_value DECIMAL(15,6),
    max_value DECIMAL(15,6),
    count_samples BIGINT,
    metric_unit VARCHAR(20)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pm.metric_name,
        AVG(pm.metric_value) as avg_value,
        MIN(pm.metric_value) as min_value,
        MAX(pm.metric_value) as max_value,
        COUNT(*) as count_samples,
        MAX(pm.metric_unit) as metric_unit
    FROM performance_metrics pm
    WHERE pm.recorded_at >= NOW() - INTERVAL '1 hour' * p_hours_back
    AND (p_metric_category IS NULL OR pm.metric_category = p_metric_category)
    GROUP BY pm.metric_name
    ORDER BY pm.metric_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- PREMIUM CONTENT FUNCTIONS
-- =====================================================

-- Get available premium content
CREATE OR REPLACE FUNCTION get_premium_content(
    p_content_type VARCHAR(50) DEFAULT NULL,
    p_user_id UUID DEFAULT NULL
)
RETURNS TABLE(
    content_id VARCHAR(100),
    name VARCHAR(200),
    description TEXT,
    content_type VARCHAR(50),
    price_gems INTEGER,
    price_currency DECIMAL(10,2),
    currency_type VARCHAR(10),
    is_owned BOOLEAN,
    is_available BOOLEAN,
    discount_percentage DECIMAL(5,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pc.content_id,
        pc.name,
        pc.description,
        pc.content_type,
        pc.price_gems,
        pc.price_currency,
        pc.currency_type,
        CASE WHEN upp.user_id IS NOT NULL THEN true ELSE false END as is_owned,
        CASE 
            WHEN pc.availability_start IS NULL OR pc.availability_start <= NOW()
            AND (pc.availability_end IS NULL OR pc.availability_end >= NOW())
            AND (pc.max_purchases IS NULL OR pc.current_purchases < pc.max_purchases)
            THEN true
            ELSE false
        END as is_available,
        pc.discount_percentage
    FROM premium_content pc
    LEFT JOIN user_premium_purchases upp ON (
        upp.content_id = pc.content_id 
        AND upp.user_id = p_user_id
        AND upp.purchase_status = 'completed'
    )
    WHERE pc.is_active = true
    AND (p_content_type IS NULL OR pc.content_type = p_content_type)
    ORDER BY pc.content_type, pc.price_gems;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Purchase premium content
CREATE OR REPLACE FUNCTION purchase_premium_content(
    p_user_id UUID,
    p_content_id VARCHAR(100),
    p_payment_method VARCHAR(50),
    p_transaction_id VARCHAR(200) DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_content RECORD;
    v_user_gems INTEGER;
    v_purchase_id UUID;
    v_result JSON;
BEGIN
    -- Get content details
    SELECT * INTO v_content
    FROM premium_content
    WHERE content_id = p_content_id AND is_active = true;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Content not found or not available'
        );
    END IF;
    
    -- Check if already owned
    IF EXISTS (
        SELECT 1 FROM user_premium_purchases
        WHERE user_id = p_user_id 
        AND content_id = p_content_id
        AND purchase_status = 'completed'
    ) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Content already owned'
        );
    END IF;
    
    -- If paying with gems, check balance
    IF p_payment_method = 'gems' THEN
        SELECT COALESCE(currency_gems, 0) INTO v_user_gems
        FROM user_activity_stats
        WHERE user_id = p_user_id;
        
        IF v_user_gems < v_content.price_gems THEN
            RETURN json_build_object(
                'success', false,
                'error', 'Insufficient gems'
            );
        END IF;
        
        -- Deduct gems
        UPDATE user_activity_stats
        SET currency_gems = currency_gems - v_content.price_gems
        WHERE user_id = p_user_id;
    END IF;
    
    -- Record purchase
    INSERT INTO user_premium_purchases (
        user_id, content_id, purchase_method, 
        amount_paid, currency_type, transaction_id
    ) VALUES (
        p_user_id, p_content_id, p_payment_method,
        CASE WHEN p_payment_method = 'gems' THEN v_content.price_gems 
             ELSE v_content.price_currency END,
        CASE WHEN p_payment_method = 'gems' THEN 'GEMS' 
             ELSE v_content.currency_type END,
        p_transaction_id
    ) RETURNING id INTO v_purchase_id;
    
    -- Add to user inventory
    INSERT INTO user_inventory (
        user_id, item_id, item_type, unlock_method
    ) VALUES (
        p_user_id, p_content_id, v_content.content_type, 'purchase'
    );
    
    -- Update purchase count
    UPDATE premium_content
    SET current_purchases = current_purchases + 1
    WHERE content_id = p_content_id;
    
    v_result := json_build_object(
        'success', true,
        'purchase_id', v_purchase_id,
        'message', 'Purchase completed successfully'
    );
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- PROFILE COMPLETION TRACKING FUNCTIONS
-- =====================================================

-- Update detailed profile completion tracking
CREATE OR REPLACE FUNCTION update_detailed_profile_completion(
    p_user_id UUID
)
RETURNS JSON AS $$
DECLARE
    v_basic_info BOOLEAN := false;
    v_avatar_uploaded BOOLEAN := false;
    v_bio_completed BOOLEAN := false;
    v_interests_added BOOLEAN := false;
    v_social_links_added BOOLEAN := false;
    v_privacy_configured BOOLEAN := false;
    v_theme_selected BOOLEAN := false;
    v_sounds_configured BOOLEAN := false;
    v_decoration_equipped BOOLEAN := false;
    v_friend_added BOOLEAN := false;
    v_completion_percentage DECIMAL(5,2);
    v_result JSON;
BEGIN
    -- Check basic info completion
    SELECT CASE 
        WHEN username IS NOT NULL AND display_name IS NOT NULL 
        THEN true ELSE false 
    END INTO v_basic_info
    FROM user_profiles
    WHERE user_id = p_user_id;
    
    -- Check avatar upload
    SELECT EXISTS (
        SELECT 1 FROM user_avatar_uploads
        WHERE user_id = p_user_id AND upload_status = 'completed'
    ) INTO v_avatar_uploaded;
    
    -- Check bio completion
    SELECT CASE 
        WHEN bio IS NOT NULL AND LENGTH(TRIM(bio)) > 20
        THEN true ELSE false 
    END INTO v_bio_completed
    FROM user_profiles
    WHERE user_id = p_user_id;
    
    -- Check interests
    SELECT CASE 
        WHEN interests IS NOT NULL AND array_length(interests, 1) >= 3
        THEN true ELSE false 
    END INTO v_interests_added
    FROM user_profiles
    WHERE user_id = p_user_id;
    
    -- Check social links
    SELECT EXISTS (
        SELECT 1 FROM user_social_links
        WHERE user_id = p_user_id
    ) INTO v_social_links_added;
    
    -- Check privacy settings
    SELECT EXISTS (
        SELECT 1 FROM user_privacy_settings
        WHERE user_id = p_user_id
    ) INTO v_privacy_configured;
    
    -- Check theme selection
    SELECT EXISTS (
        SELECT 1 FROM user_profile_themes
        WHERE user_id = p_user_id AND is_active = true
    ) INTO v_theme_selected;
    
    -- Check sound configuration
    SELECT EXISTS (
        SELECT 1 FROM user_sound_settings
        WHERE user_id = p_user_id
    ) INTO v_sounds_configured;
    
    -- Check decoration equipped
    SELECT EXISTS (
        SELECT 1 FROM user_inventory
        WHERE user_id = p_user_id AND item_type = 'decoration' AND equipped = true
    ) INTO v_decoration_equipped;
    
    -- Check friend added
    SELECT EXISTS (
        SELECT 1 FROM user_connections
        WHERE (user_id = p_user_id OR connected_user_id = p_user_id) AND status = 'accepted'
    ) INTO v_friend_added;
    
    -- Calculate completion percentage
    v_completion_percentage := (
        CASE WHEN v_basic_info THEN 10 ELSE 0 END +
        CASE WHEN v_avatar_uploaded THEN 15 ELSE 0 END +
        CASE WHEN v_bio_completed THEN 15 ELSE 0 END +
        CASE WHEN v_interests_added THEN 10 ELSE 0 END +
        CASE WHEN v_social_links_added THEN 10 ELSE 0 END +
        CASE WHEN v_privacy_configured THEN 5 ELSE 0 END +
        CASE WHEN v_theme_selected THEN 10 ELSE 0 END +
        CASE WHEN v_sounds_configured THEN 5 ELSE 0 END +
        CASE WHEN v_decoration_equipped THEN 10 ELSE 0 END +
        CASE WHEN v_friend_added THEN 10 ELSE 0 END
    );
    
    -- Update tracking table
    INSERT INTO profile_completion_tracking (
        user_id, basic_info_completed, avatar_uploaded, bio_completed,
        interests_added, social_links_added, privacy_configured,
        theme_selected, sounds_configured, first_decoration_equipped,
        first_friend_added, completion_percentage
    ) VALUES (
        p_user_id, v_basic_info, v_avatar_uploaded, v_bio_completed,
        v_interests_added, v_social_links_added, v_privacy_configured,
        v_theme_selected, v_sounds_configured, v_decoration_equipped,
        v_friend_added, v_completion_percentage
    )
    ON CONFLICT (user_id)
    DO UPDATE SET
        basic_info_completed = EXCLUDED.basic_info_completed,
        avatar_uploaded = EXCLUDED.avatar_uploaded,
        bio_completed = EXCLUDED.bio_completed,
        interests_added = EXCLUDED.interests_added,
        social_links_added = EXCLUDED.social_links_added,
        privacy_configured = EXCLUDED.privacy_configured,
        theme_selected = EXCLUDED.theme_selected,
        sounds_configured = EXCLUDED.sounds_configured,
        first_decoration_equipped = EXCLUDED.first_decoration_equipped,
        first_friend_added = EXCLUDED.first_friend_added,
        completion_percentage = EXCLUDED.completion_percentage,
        last_updated = NOW();
    
    -- Update main profile table
    UPDATE user_profiles
    SET profile_completion_percentage = v_completion_percentage
    WHERE user_id = p_user_id;
    
    v_result := json_build_object(
        'success', true,
        'completion_percentage', v_completion_percentage,
        'completed_items', json_build_object(
            'basic_info', v_basic_info,
            'avatar_uploaded', v_avatar_uploaded,
            'bio_completed', v_bio_completed,
            'interests_added', v_interests_added,
            'social_links_added', v_social_links_added,
            'privacy_configured', v_privacy_configured,
            'theme_selected', v_theme_selected,
            'sounds_configured', v_sounds_configured,
            'decoration_equipped', v_decoration_equipped,
            'friend_added', v_friend_added
        )
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- GRANTS AND PERMISSIONS
-- =====================================================

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION get_user_preset_avatars(UUID, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION upload_custom_avatar(UUID, VARCHAR, VARCHAR, BIGINT, VARCHAR, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_decoration_inventory(UUID, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_available_sounds(UUID, VARCHAR, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION set_custom_ringtone(UUID, UUID, VARCHAR, DECIMAL) TO authenticated;
GRANT EXECUTE ON FUNCTION update_social_links(UUID, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION update_privacy_settings(UUID, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION get_premium_content(VARCHAR, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION purchase_premium_content(UUID, VARCHAR, VARCHAR, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION update_detailed_profile_completion(UUID) TO authenticated;

-- Grant service role permissions for system functions
GRANT EXECUTE ON FUNCTION get_system_config(VARCHAR, VARCHAR) TO service_role;
GRANT EXECUTE ON FUNCTION update_system_config(VARCHAR, VARCHAR, JSONB, TEXT, VARCHAR) TO service_role;
GRANT EXECUTE ON FUNCTION record_performance_metric(VARCHAR, VARCHAR, DECIMAL, VARCHAR, UUID, VARCHAR, JSONB) TO service_role;
GRANT EXECUTE ON FUNCTION get_performance_analytics(VARCHAR, INTEGER) TO service_role;

-- =====================================================
-- END OF EXTENDED FUNCTIONS
-- =====================================================
