-- =====================================================
-- CRYSTAL SOCIAL - CHAT SYSTEM SETUP & TESTING
-- =====================================================
-- Setup procedures and test data for chat system
-- =====================================================

-- ===== INITIAL SETUP FUNCTION =====

CREATE OR REPLACE FUNCTION setup_chat_system()
RETURNS TEXT AS $$
DECLARE
    v_result TEXT := '';
BEGIN
    -- Create initial chat system data
    v_result := v_result || 'Setting up Crystal Social Chat System...' || E'\n';
    
    -- Insert default chat themes
    INSERT INTO chat_settings (user_id, chat_id, theme, font_size, enable_effects, enable_sounds)
    SELECT 
        p.id,
        NULL, -- Global settings
        'classic',
        16.0,
        true,
        true
    FROM profiles p
    ON CONFLICT DO NOTHING;
    
    v_result := v_result || 'Default chat settings created for existing users.' || E'\n';
    
    -- Create system-wide announcement chat (optional)
    INSERT INTO chats (
        id,
        name,
        description,
        chat_type,
        is_group,
        is_private,
        max_participants,
        created_by
    ) VALUES (
        gen_random_uuid(),
        'Crystal Social Announcements',
        'Official announcements and updates',
        'channel',
        true,
        false,
        1000,
        (SELECT id FROM profiles WHERE email = 'admin@crystalsocial.com' LIMIT 1)
    )
    ON CONFLICT DO NOTHING;
    
    v_result := v_result || 'System announcement channel created.' || E'\n';
    
    -- Set up periodic cleanup job (requires pg_cron extension)
    -- This would be set up separately by a database administrator
    v_result := v_result || 'Note: Set up periodic cleanup with pg_cron:' || E'\n';
    v_result := v_result || 'SELECT cron.schedule(''cleanup-chat-data'', ''0 2 * * *'', ''SELECT periodic_chat_cleanup();'');' || E'\n';
    
    v_result := v_result || 'Chat system setup complete!' || E'\n';
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===== TEST DATA CREATION =====

CREATE OR REPLACE FUNCTION create_chat_test_data()
RETURNS TEXT AS $$
DECLARE
    v_user1_id UUID;
    v_user2_id UUID;
    v_user3_id UUID;
    v_chat_id UUID;
    v_group_chat_id UUID;
    v_message_id UUID;
    v_result TEXT := '';
BEGIN
    v_result := v_result || 'Creating test data for chat system...' || E'\n';
    
    -- Get or create test users
    SELECT id INTO v_user1_id FROM profiles WHERE username = 'test_user_1' LIMIT 1;
    SELECT id INTO v_user2_id FROM profiles WHERE username = 'test_user_2' LIMIT 1;
    SELECT id INTO v_user3_id FROM profiles WHERE username = 'test_user_3' LIMIT 1;
    
    -- Create test users if they don't exist
    IF v_user1_id IS NULL THEN
        INSERT INTO profiles (username, email, display_name, bio)
        VALUES ('test_user_1', 'test1@example.com', 'Test User One', 'First test user for chat system')
        RETURNING id INTO v_user1_id;
    END IF;
    
    IF v_user2_id IS NULL THEN
        INSERT INTO profiles (username, email, display_name, bio)
        VALUES ('test_user_2', 'test2@example.com', 'Test User Two', 'Second test user for chat system')
        RETURNING id INTO v_user2_id;
    END IF;
    
    IF v_user3_id IS NULL THEN
        INSERT INTO profiles (username, email, display_name, bio)
        VALUES ('test_user_3', 'test3@example.com', 'Test User Three', 'Third test user for chat system')
        RETURNING id INTO v_user3_id;
    END IF;
    
    v_result := v_result || 'Test users created/found.' || E'\n';
    
    -- Create a direct chat between user1 and user2
    SELECT create_chat(
        v_user1_id,
        NULL,
        'direct',
        false,
        ARRAY[v_user2_id]
    ) INTO v_chat_id;
    
    v_result := v_result || 'Direct chat created: ' || v_chat_id || E'\n';
    
    -- Create a group chat
    SELECT create_chat(
        v_user1_id,
        'Test Group Chat',
        'group',
        true,
        ARRAY[v_user2_id, v_user3_id]
    ) INTO v_group_chat_id;
    
    v_result := v_result || 'Group chat created: ' || v_group_chat_id || E'\n';
    
    -- Send some test messages
    SELECT send_message(
        v_chat_id,
        v_user1_id,
        'Hello! This is the first message in our chat.',
        'text'
    ) INTO v_message_id;
    
    SELECT send_message(
        v_chat_id,
        v_user2_id,
        'Hi there! Nice to chat with you! 😊',
        'text'
    ) INTO v_message_id;
    
    SELECT send_message(
        v_group_chat_id,
        v_user1_id,
        'Welcome to our group chat everyone!',
        'text'
    ) INTO v_message_id;
    
    SELECT send_message(
        v_group_chat_id,
        v_user2_id,
        'Thanks for creating this group! #excited',
        'text',
        NULL,
        '{"hashtags": ["excited"]}'::jsonb
    ) INTO v_message_id;
    
    SELECT send_message(
        v_group_chat_id,
        v_user3_id,
        'Looking forward to chatting with everyone @test_user_1 @test_user_2',
        'text',
        NULL,
        '{"mentions": ["test_user_1", "test_user_2"]}'::jsonb
    ) INTO v_message_id;
    
    v_result := v_result || 'Test messages sent.' || E'\n';
    
    -- Add some reactions
    PERFORM add_message_reaction(v_message_id, v_user1_id, '👍');
    PERFORM add_message_reaction(v_message_id, v_user2_id, '❤️');
    
    v_result := v_result || 'Test reactions added.' || E'\n';
    
    -- Create some chat settings
    INSERT INTO chat_settings (user_id, chat_id, theme, font_size, enable_effects, enable_sounds)
    VALUES 
        (v_user1_id, v_chat_id, 'neon', 18.0, true, true),
        (v_user2_id, v_chat_id, 'nature', 16.0, false, true),
        (v_user1_id, v_group_chat_id, 'space', 20.0, true, false)
    ON CONFLICT DO NOTHING;
    
    v_result := v_result || 'Test chat settings created.' || E'\n';
    
    -- Simulate some typing status
    PERFORM update_typing_status(v_chat_id, v_user1_id, 1);
    
    v_result := v_result || 'Test typing status added.' || E'\n';
    
    v_result := v_result || 'Chat test data creation complete!' || E'\n';
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===== PERFORMANCE TEST FUNCTION =====

CREATE OR REPLACE FUNCTION test_chat_performance(
    p_num_chats INTEGER DEFAULT 10,
    p_num_messages INTEGER DEFAULT 100
)
RETURNS TABLE (
    test_name TEXT,
    execution_time_ms NUMERIC,
    records_processed INTEGER,
    avg_time_per_record_ms NUMERIC
) AS $$
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_duration NUMERIC;
    v_test_user_id UUID;
    v_test_chat_id UUID;
    i INTEGER;
BEGIN
    -- Get a test user
    SELECT id INTO v_test_user_id FROM profiles LIMIT 1;
    
    IF v_test_user_id IS NULL THEN
        INSERT INTO profiles (username, email, display_name)
        VALUES ('perf_test_user', 'perftest@example.com', 'Performance Test User')
        RETURNING id INTO v_test_user_id;
    END IF;
    
    -- Test 1: Chat creation performance
    v_start_time := clock_timestamp();
    
    FOR i IN 1..p_num_chats LOOP
        SELECT create_chat(
            v_test_user_id,
            'Performance Test Chat ' || i,
            'group',
            true,
            ARRAY[]::UUID[]
        ) INTO v_test_chat_id;
    END LOOP;
    
    v_end_time := clock_timestamp();
    v_duration := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    
    RETURN QUERY SELECT 
        'Chat Creation'::TEXT,
        v_duration,
        p_num_chats,
        v_duration / p_num_chats;
    
    -- Test 2: Message sending performance
    v_start_time := clock_timestamp();
    
    FOR i IN 1..p_num_messages LOOP
        PERFORM send_message(
            v_test_chat_id,
            v_test_user_id,
            'Performance test message number ' || i,
            'text'
        );
    END LOOP;
    
    v_end_time := clock_timestamp();
    v_duration := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    
    RETURN QUERY SELECT 
        'Message Sending'::TEXT,
        v_duration,
        p_num_messages,
        v_duration / p_num_messages;
    
    -- Test 3: Message retrieval performance
    v_start_time := clock_timestamp();
    
    PERFORM * FROM get_chat_messages(v_test_chat_id, v_test_user_id, 50, 0);
    
    v_end_time := clock_timestamp();
    v_duration := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    
    RETURN QUERY SELECT 
        'Message Retrieval'::TEXT,
        v_duration,
        50,
        v_duration / 50;
    
    -- Test 4: Chat list performance
    v_start_time := clock_timestamp();
    
    PERFORM * FROM get_user_chats(v_test_user_id, 50, 0);
    
    v_end_time := clock_timestamp();
    v_duration := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    
    RETURN QUERY SELECT 
        'Chat List Retrieval'::TEXT,
        v_duration,
        1,
        v_duration;
    
    -- Clean up test data
    DELETE FROM chats WHERE created_by = v_test_user_id AND name LIKE 'Performance Test Chat%';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===== DATA INTEGRITY CHECK =====

CREATE OR REPLACE FUNCTION check_chat_data_integrity()
RETURNS TABLE (
    check_name TEXT,
    status TEXT,
    details TEXT
) AS $$
BEGIN
    -- Check 1: Orphaned messages
    RETURN QUERY SELECT 
        'Orphaned Messages'::TEXT,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'Found ' || COUNT(*) || ' messages without valid chat_id'
    FROM messages m
    LEFT JOIN chats c ON m.chat_id = c.id
    WHERE c.id IS NULL;
    
    -- Check 2: Orphaned participants
    RETURN QUERY SELECT 
        'Orphaned Participants'::TEXT,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'Found ' || COUNT(*) || ' participants without valid chat_id'
    FROM chat_participants cp
    LEFT JOIN chats c ON cp.chat_id = c.id
    WHERE c.id IS NULL;
    
    -- Check 3: Invalid message reactions
    RETURN QUERY SELECT 
        'Invalid Reactions'::TEXT,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'Found ' || COUNT(*) || ' reactions for non-existent messages'
    FROM message_reactions mr
    LEFT JOIN messages m ON mr.message_id = m.id
    WHERE m.id IS NULL;
    
    -- Check 4: Chat message count accuracy
    RETURN QUERY SELECT 
        'Message Count Accuracy'::TEXT,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'Found ' || COUNT(*) || ' chats with incorrect message counts'
    FROM (
        SELECT c.id
        FROM chats c
        LEFT JOIN (
            SELECT chat_id, COUNT(*) as actual_count
            FROM messages
            WHERE is_deleted = false
            GROUP BY chat_id
        ) mc ON c.id = mc.chat_id
        WHERE COALESCE(mc.actual_count, 0) != c.message_count
    ) mismatched;
    
    -- Check 5: Expired typing status
    RETURN QUERY SELECT 
        'Expired Typing Status'::TEXT,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'WARNING' END,
        'Found ' || COUNT(*) || ' expired typing status records'
    FROM typing_status
    WHERE expires_at <= NOW();
    
    -- Check 6: Chat participant consistency
    RETURN QUERY SELECT 
        'Chat Ownership Consistency'::TEXT,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'Found ' || COUNT(*) || ' chats where creator is not a participant'
    FROM chats c
    LEFT JOIN chat_participants cp ON (
        c.id = cp.chat_id 
        AND c.created_by = cp.user_id 
        AND cp.is_active = true
    )
    WHERE c.created_by IS NOT NULL AND cp.user_id IS NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===== MAINTENANCE UTILITIES =====

CREATE OR REPLACE FUNCTION optimize_chat_tables()
RETURNS TEXT AS $$
DECLARE
    v_result TEXT := '';
BEGIN
    -- Vacuum and analyze all chat tables
    VACUUM ANALYZE chats;
    VACUUM ANALYZE chat_participants;
    VACUUM ANALYZE messages;
    VACUUM ANALYZE message_reactions;
    VACUUM ANALYZE message_delivery_status;
    VACUUM ANALYZE typing_status;
    VACUUM ANALYZE chat_settings;
    VACUUM ANALYZE calls;
    VACUUM ANALYZE shared_media;
    VACUUM ANALYZE chat_analytics;
    
    v_result := v_result || 'All chat tables vacuumed and analyzed.' || E'\n';
    
    -- Update search vectors for all messages
    UPDATE messages SET search_vector = to_tsvector('english', COALESCE(content, ''))
    WHERE search_vector IS NULL;
    
    v_result := v_result || 'Search vectors updated.' || E'\n';
    
    -- Clean up expired data
    PERFORM periodic_chat_cleanup();
    
    v_result := v_result || 'Expired data cleaned up.' || E'\n';
    
    v_result := v_result || 'Chat table optimization complete.' || E'\n';
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===== MIGRATION HELPER =====

CREATE OR REPLACE FUNCTION migrate_legacy_chat_data()
RETURNS TEXT AS $$
DECLARE
    v_result TEXT := '';
    v_migrated_count INTEGER := 0;
BEGIN
    -- This function would contain logic to migrate from legacy chat systems
    -- Placeholder implementation
    
    v_result := v_result || 'Starting legacy chat data migration...' || E'\n';
    
    -- Example: Migrate old message format
    /*
    UPDATE messages 
    SET content = legacy_text, 
        message_type = 'text'
    WHERE content IS NULL AND legacy_text IS NOT NULL;
    
    GET DIAGNOSTICS v_migrated_count = ROW_COUNT;
    v_result := v_result || 'Migrated ' || v_migrated_count || ' legacy messages.' || E'\n';
    */
    
    v_result := v_result || 'Legacy chat data migration complete.' || E'\n';
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===== USAGE STATISTICS =====

CREATE OR REPLACE FUNCTION get_chat_system_stats()
RETURNS TABLE (
    metric_name TEXT,
    metric_value BIGINT,
    description TEXT
) AS $$
BEGIN
    RETURN QUERY SELECT 
        'Total Chats'::TEXT,
        COUNT(*)::BIGINT,
        'Total number of chats in the system'
    FROM chats WHERE is_active = true;
    
    RETURN QUERY SELECT 
        'Active Chats (24h)'::TEXT,
        COUNT(DISTINCT chat_id)::BIGINT,
        'Chats with activity in the last 24 hours'
    FROM messages WHERE created_at > NOW() - INTERVAL '24 hours';
    
    RETURN QUERY SELECT 
        'Total Messages'::TEXT,
        COUNT(*)::BIGINT,
        'Total number of messages sent'
    FROM messages WHERE is_deleted = false;
    
    RETURN QUERY SELECT 
        'Messages Today'::TEXT,
        COUNT(*)::BIGINT,
        'Messages sent today'
    FROM messages WHERE created_at::date = CURRENT_DATE AND is_deleted = false;
    
    RETURN QUERY SELECT 
        'Total Users in Chats'::TEXT,
        COUNT(DISTINCT user_id)::BIGINT,
        'Unique users who have participated in chats'
    FROM chat_participants WHERE is_active = true;
    
    RETURN QUERY SELECT 
        'Media Messages'::TEXT,
        COUNT(*)::BIGINT,
        'Total media messages (images, videos, audio, files)'
    FROM messages 
    WHERE message_type IN ('image', 'video', 'audio', 'file', 'gif') 
    AND is_deleted = false;
    
    RETURN QUERY SELECT 
        'Total Reactions'::TEXT,
        COUNT(*)::BIGINT,
        'Total reactions given to messages'
    FROM message_reactions;
    
    RETURN QUERY SELECT 
        'Group Chats'::TEXT,
        COUNT(*)::BIGINT,
        'Total number of group chats'
    FROM chats WHERE is_group = true AND is_active = true;
    
    RETURN QUERY SELECT 
        'Direct Chats'::TEXT,
        COUNT(*)::BIGINT,
        'Total number of direct chats'
    FROM chats WHERE is_group = false AND is_active = true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===== GRANT PERMISSIONS =====

GRANT EXECUTE ON FUNCTION setup_chat_system TO authenticated;
GRANT EXECUTE ON FUNCTION create_chat_test_data TO authenticated;
GRANT EXECUTE ON FUNCTION test_chat_performance TO authenticated;
GRANT EXECUTE ON FUNCTION check_chat_data_integrity TO authenticated;
GRANT EXECUTE ON FUNCTION optimize_chat_tables TO authenticated;
GRANT EXECUTE ON FUNCTION migrate_legacy_chat_data TO authenticated;
GRANT EXECUTE ON FUNCTION get_chat_system_stats TO authenticated;

-- =====================================================
-- SETUP DOCUMENTATION
-- =====================================================

COMMENT ON FUNCTION setup_chat_system IS 'Initializes the chat system with default settings and system chats';
COMMENT ON FUNCTION create_chat_test_data IS 'Creates sample test data for development and testing';
COMMENT ON FUNCTION test_chat_performance IS 'Runs performance tests on core chat operations';
COMMENT ON FUNCTION check_chat_data_integrity IS 'Performs data integrity checks across chat tables';
COMMENT ON FUNCTION optimize_chat_tables IS 'Optimizes chat tables for better performance';
COMMENT ON FUNCTION migrate_legacy_chat_data IS 'Helper function for migrating from legacy chat systems';
COMMENT ON FUNCTION get_chat_system_stats IS 'Returns key metrics and statistics about chat system usage';

-- =====================================================
-- READY TO USE
-- =====================================================

-- Run the setup function to initialize the system
-- SELECT setup_chat_system();

-- Optionally create test data for development
-- SELECT create_chat_test_data();
