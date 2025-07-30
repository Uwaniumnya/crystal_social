-- Diagnostic script to find type mismatch issues
-- Run this to identify which specific comparison is causing the error

-- Check column types for all referenced tables
SELECT 
    t.table_name,
    c.column_name,
    c.data_type,
    c.udt_name
FROM information_schema.tables t
JOIN information_schema.columns c ON t.table_name = c.table_name
WHERE t.table_schema = 'public'
AND t.table_name IN (
    'stickers', 'recent_stickers', 'sticker_collections',
    'emoticon_categories', 'custom_emoticons', 'emoticon_usage', 'emoticon_favorites',
    'chat_backgrounds', 'user_chat_backgrounds', 'message_bubbles', 'message_reactions',
    'user_widget_preferences', 'widget_usage_analytics', 'daily_widget_stats',
    'message_analysis_results', 'gem_unlock_analytics', 'glimmer_posts',
    'user_local_sync', 'widget_performance_metrics', 'widget_cache_entries'
)
AND c.column_name IN ('user_id', 'created_by', 'id')
ORDER BY t.table_name, c.column_name;

-- Check auth.users table structure
SELECT column_name, data_type, udt_name 
FROM information_schema.columns 
WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = 'id';
