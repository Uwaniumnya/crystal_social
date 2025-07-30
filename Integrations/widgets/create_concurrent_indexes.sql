-- Crystal Social Widgets System - Concurrent Index Creation
-- File: create_concurrent_indexes.sql
-- Purpose: Non-blocking index creation for production environments
-- 
-- IMPORTANT: This script should be run OUTSIDE of a transaction block
-- Run each command separately in production to avoid locking

-- =============================================================================
-- CONCURRENT INDEX CREATION FOR PRODUCTION
-- =============================================================================

-- Note: Run these commands individually, not as a batch script
-- Each CREATE INDEX CONCURRENTLY must be executed outside a transaction

-- Primary UUID indexes for RLS policy optimization
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stickers_user_id ON stickers(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_recent_stickers_user_id ON recent_stickers(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_sticker_collections_user_id ON sticker_collections(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_custom_emoticons_user_id ON custom_emoticons(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_emoticon_usage_user_id ON emoticon_usage(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_emoticon_favorites_user_id ON emoticon_favorites(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_chat_backgrounds_created_by ON chat_backgrounds(created_by);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_chat_backgrounds_user_id ON user_chat_backgrounds(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_message_bubbles_user_id ON message_bubbles(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_message_reactions_user_id ON message_reactions(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_widget_preferences_user_id ON user_widget_preferences(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_widget_usage_analytics_user_id ON widget_usage_analytics(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_message_analysis_results_user_id ON message_analysis_results(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_gem_unlock_analytics_user_id ON gem_unlock_analytics(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_glimmer_posts_user_id ON glimmer_posts(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_local_sync_user_id ON user_local_sync(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_widget_security_events_user_id ON widget_security_events(user_id);

-- Composite indexes for complex query patterns
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stickers_user_public_approved ON stickers(user_id, is_public, is_approved);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_emoticon_usage_user_date ON emoticon_usage(user_id, used_at);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_widget_analytics_user_type_timestamp ON widget_usage_analytics(user_id, widget_type, usage_timestamp);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_security_events_user_type_severity ON widget_security_events(user_id, event_type, severity);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_glimmer_posts_user_public_status ON glimmer_posts(user_id, is_public, moderation_status);

-- Auth performance optimization
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_auth_users_metadata_role ON auth.users USING GIN (raw_user_meta_data);

-- =============================================================================
-- USAGE INSTRUCTIONS
-- =============================================================================

/*
PRODUCTION DEPLOYMENT INSTRUCTIONS:

1. For initial setup (development/staging):
   - Use the regular CREATE INDEX statements in the main SQL files
   - These will block but complete faster on smaller datasets

2. For production environments with large datasets:
   - Run each CREATE INDEX CONCURRENTLY command individually
   - Monitor index creation progress with:
     SELECT * FROM pg_stat_progress_create_index;
   - Each index creation will not block normal operations
   - Allow adequate time for completion before running the next

3. Verification after index creation:
   - Check index status: SELECT * FROM pg_indexes WHERE tablename LIKE '%widget%';
   - Verify query performance improvements
   - Monitor for any failed index creations

EXAMPLE INDIVIDUAL EXECUTION:
psql -c "CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stickers_user_id ON stickers(user_id);"
psql -c "CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_recent_stickers_user_id ON recent_stickers(user_id);"
...continue for each index...
*/

-- Mark completion
SELECT 'Concurrent Index Creation Script Ready' as status, 
       'Execute commands individually in production' as instructions,
       NOW() as created_at;
