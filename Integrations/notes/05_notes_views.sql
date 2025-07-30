-- =====================================================
-- CRYSTAL SOCIAL - NOTES SYSTEM VIEWS
-- =====================================================
-- Optimized views for notes system functionality
-- =====================================================

-- =====================================================
-- MAIN NOTES VIEW WITH ENRICHED DATA
-- =====================================================

CREATE OR REPLACE VIEW notes_enriched AS
SELECT 
    n.*,
    -- User information (simplified - would be joined with user profiles in application)
    n.user_id as author_id,
    
    -- Folder information
    f.name as folder_name,
    f.color as folder_color,
    f.icon as folder_icon,
    
    -- Statistics
    COALESCE(comment_stats.comment_count, 0) as comment_count,
    COALESCE(bookmark_stats.bookmark_count, 0) as bookmark_count,
    COALESCE(share_stats.share_count, 0) as share_count,
    COALESCE(revision_stats.revision_count, 0) as revision_count,
    
    -- Share information for current user
    CASE 
        WHEN n.user_id = auth.uid() THEN 'owner'
        WHEN ns.can_write = true THEN 'edit'
        WHEN ns.can_comment = true THEN 'comment'
        WHEN ns.can_read = true THEN 'read'
        ELSE 'none'
    END as access_level,
    
    -- Check if current user has bookmarked this note
    CASE WHEN nb.id IS NOT NULL THEN true ELSE false END as is_bookmarked
    
FROM notes n
LEFT JOIN note_folders f ON n.folder_id = f.id
LEFT JOIN note_shares ns ON n.id = ns.note_id AND ns.shared_with = auth.uid() 
    AND ns.is_active = true AND (ns.expires_at IS NULL OR ns.expires_at > NOW())
LEFT JOIN note_bookmarks nb ON n.id = nb.note_id AND nb.user_id = auth.uid()

-- Aggregate statistics subqueries
LEFT JOIN (
    SELECT note_id, COUNT(*) as comment_count
    FROM note_comments
    GROUP BY note_id
) comment_stats ON n.id = comment_stats.note_id

LEFT JOIN (
    SELECT note_id, COUNT(*) as bookmark_count
    FROM note_bookmarks
    GROUP BY note_id
) bookmark_stats ON n.id = bookmark_stats.note_id

LEFT JOIN (
    SELECT note_id, COUNT(*) as share_count
    FROM note_shares
    WHERE is_active = true
    GROUP BY note_id
) share_stats ON n.id = share_stats.note_id

LEFT JOIN (
    SELECT note_id, COUNT(*) as revision_count
    FROM note_revisions
    GROUP BY note_id
) revision_stats ON n.id = revision_stats.note_id

WHERE NOT n.is_deleted;

-- =====================================================
-- FOLDER TREE VIEW WITH HIERARCHY
-- =====================================================

CREATE OR REPLACE VIEW note_folders_tree AS
WITH RECURSIVE folder_hierarchy AS (
    -- Base case: root folders
    SELECT 
        id,
        name,
        user_id,
        parent_folder_id,
        note_count,
        total_words,
        color,
        icon,
        created_at,
        updated_at,
        0 as level,
        ARRAY[name]::TEXT[] as path,
        name::TEXT as path_string
    FROM note_folders
    WHERE parent_folder_id IS NULL
    
    UNION ALL
    
    -- Recursive case: child folders
    SELECT 
        nf.id,
        nf.name,
        nf.user_id,
        nf.parent_folder_id,
        nf.note_count,
        nf.total_words,
        nf.color,
        nf.icon,
        nf.created_at,
        nf.updated_at,
        fh.level + 1,
        fh.path || nf.name::TEXT,
        fh.path_string || ' > ' || nf.name
    FROM note_folders nf
    JOIN folder_hierarchy fh ON nf.parent_folder_id = fh.id
)
SELECT 
    *,
    -- Calculate total notes including subfolders
    (
        SELECT COALESCE(SUM(note_count), 0)
        FROM note_folders
        WHERE id = folder_hierarchy.id
        OR parent_folder_id = folder_hierarchy.id
    ) as total_notes_recursive
FROM folder_hierarchy
ORDER BY path;

-- =====================================================
-- USER ANALYTICS DASHBOARD VIEW
-- =====================================================

CREATE OR REPLACE VIEW user_notes_dashboard AS
SELECT 
    u.id as user_id,
    
    -- Total counts
    COALESCE(note_stats.total_notes, 0) as total_notes,
    COALESCE(folder_stats.total_folders, 0) as total_folders,
    COALESCE(template_stats.total_templates, 0) as total_templates,
    COALESCE(bookmark_stats.total_bookmarks, 0) as total_bookmarks,
    
    -- Word statistics
    COALESCE(note_stats.total_words, 0) as total_words,
    COALESCE(note_stats.avg_words_per_note, 0) as avg_words_per_note,
    
    -- Content type statistics
    COALESCE(note_stats.notes_with_images, 0) as notes_with_images,
    COALESCE(note_stats.notes_with_audio, 0) as notes_with_audio,
    COALESCE(note_stats.notes_with_attachments, 0) as notes_with_attachments,
    
    -- Activity statistics
    COALESCE(share_stats.total_shares_created, 0) as total_shares_created,
    COALESCE(comment_stats.total_comments, 0) as total_comments,
    
    -- Recent activity
    note_stats.last_note_created,
    note_stats.last_note_updated,
    
    -- Most used tags
    popular_tags.top_tags

FROM auth.users u

-- Note statistics
LEFT JOIN (
    SELECT 
        user_id,
        COUNT(*) as total_notes,
        SUM(word_count) as total_words,
        ROUND(AVG(word_count), 2) as avg_words_per_note,
        COUNT(*) FILTER (WHERE has_images) as notes_with_images,
        COUNT(*) FILTER (WHERE has_audio) as notes_with_audio,
        COUNT(*) FILTER (WHERE has_attachments) as notes_with_attachments,
        MAX(created_at) as last_note_created,
        MAX(updated_at) as last_note_updated
    FROM notes
    WHERE NOT is_deleted
    GROUP BY user_id
) note_stats ON u.id = note_stats.user_id

-- Folder statistics
LEFT JOIN (
    SELECT user_id, COUNT(*) as total_folders
    FROM note_folders
    GROUP BY user_id
) folder_stats ON u.id = folder_stats.user_id

-- Template statistics
LEFT JOIN (
    SELECT user_id, COUNT(*) as total_templates
    FROM note_templates
    GROUP BY user_id
) template_stats ON u.id = template_stats.user_id

-- Bookmark statistics
LEFT JOIN (
    SELECT user_id, COUNT(*) as total_bookmarks
    FROM note_bookmarks
    GROUP BY user_id
) bookmark_stats ON u.id = bookmark_stats.user_id

-- Share statistics
LEFT JOIN (
    SELECT 
        shared_by as user_id,
        COUNT(*) as total_shares_created
    FROM note_shares
    WHERE is_active = true
    GROUP BY shared_by
) share_stats ON u.id = share_stats.user_id

-- Comment statistics
LEFT JOIN (
    SELECT user_id, COUNT(*) as total_comments
    FROM note_comments
    GROUP BY user_id
) comment_stats ON u.id = comment_stats.user_id

-- Popular tags
LEFT JOIN (
    SELECT 
        user_id,
        ARRAY_AGG(name ORDER BY usage_count DESC) as top_tags
    FROM (
        SELECT user_id, name, usage_count,
               ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY usage_count DESC) as rn
        FROM note_tags
        WHERE usage_count > 0
    ) ranked_tags
    WHERE rn <= 5
    GROUP BY user_id
) popular_tags ON u.id = popular_tags.user_id;

-- =====================================================
-- SHARED NOTES VIEW
-- =====================================================

CREATE OR REPLACE VIEW shared_notes_view AS
SELECT 
    n.*,
    ns.shared_with,
    ns.can_read,
    ns.can_write,
    ns.can_comment,
    ns.share_type,
    ns.share_token,
    ns.expires_at,
    ns.current_views,
    ns.max_views,
    ns.created_at as shared_at,
    
    -- User IDs (profiles would be joined in application layer)
    ns.shared_by as sharer_id,
    n.user_id as owner_id,
    
    -- Check if share is still valid
    CASE 
        WHEN ns.expires_at IS NOT NULL AND ns.expires_at <= NOW() THEN false
        WHEN ns.max_views IS NOT NULL AND ns.current_views >= ns.max_views THEN false
        ELSE ns.is_active
    END as is_valid

FROM note_shares ns
JOIN notes n ON ns.note_id = n.id
WHERE NOT n.is_deleted;

-- =====================================================
-- RECENT ACTIVITY VIEW
-- =====================================================

CREATE OR REPLACE VIEW recent_notes_activity AS
SELECT 
    'note_created' as activity_type,
    n.id as item_id,
    n.title as item_title,
    n.user_id,
    n.created_at as activity_time,
    JSONB_BUILD_OBJECT(
        'note_id', n.id,
        'title', n.title,
        'word_count', n.word_count,
        'folder_name', f.name
    ) as activity_data
FROM notes n
LEFT JOIN note_folders f ON n.folder_id = f.id
WHERE NOT n.is_deleted AND n.created_at > NOW() - INTERVAL '30 days'

UNION ALL

SELECT 
    'note_updated' as activity_type,
    n.id as item_id,
    n.title as item_title,
    n.user_id,
    n.updated_at as activity_time,
    JSONB_BUILD_OBJECT(
        'note_id', n.id,
        'title', n.title,
        'word_count', n.word_count,
        'folder_name', f.name
    ) as activity_data
FROM notes n
LEFT JOIN note_folders f ON n.folder_id = f.id
WHERE NOT n.is_deleted 
  AND n.updated_at > NOW() - INTERVAL '30 days'
  AND n.updated_at > n.created_at

UNION ALL

SELECT 
    'note_shared' as activity_type,
    n.id as item_id,
    n.title as item_title,
    ns.shared_by as user_id,
    ns.created_at as activity_time,
    JSONB_BUILD_OBJECT(
        'note_id', n.id,
        'title', n.title,
        'share_type', ns.share_type,
        'can_write', ns.can_write
    ) as activity_data
FROM note_shares ns
JOIN notes n ON ns.note_id = n.id
WHERE NOT n.is_deleted 
  AND ns.created_at > NOW() - INTERVAL '30 days'
  AND ns.is_active = true

UNION ALL

SELECT 
    'comment_added' as activity_type,
    n.id as item_id,
    n.title as item_title,
    nc.user_id,
    nc.created_at as activity_time,
    JSONB_BUILD_OBJECT(
        'note_id', n.id,
        'title', n.title,
        'comment_id', nc.id,
        'comment_preview', LEFT(nc.content, 100)
    ) as activity_data
FROM note_comments nc
JOIN notes n ON nc.note_id = n.id
WHERE NOT n.is_deleted 
  AND nc.created_at > NOW() - INTERVAL '30 days'

ORDER BY activity_time DESC;

-- =====================================================
-- SEARCH RESULTS VIEW
-- =====================================================

CREATE OR REPLACE VIEW note_search_results AS
SELECT 
    n.id,
    n.title,
    n.content,
    n.content_html,
    n.tags,
    n.created_at,
    n.updated_at,
    n.word_count,
    n.user_id,
    
    -- Folder information
    f.name as folder_name,
    f.color as folder_color,
    
    -- Search ranking (to be used with full-text search)
    CASE WHEN n.search_vector IS NOT NULL 
         THEN ts_rank(n.search_vector, plainto_tsquery('')) 
         ELSE 0.0 
    END as search_rank,
    
    -- Highlight matching content (simplified)
    LEFT(n.content, 200) as content_highlight

FROM notes n
LEFT JOIN note_folders f ON n.folder_id = f.id
WHERE NOT n.is_deleted;

-- =====================================================
-- ANALYTICS SUMMARY VIEW
-- =====================================================

CREATE OR REPLACE VIEW notes_analytics_summary AS
SELECT 
    date,
    user_id,
    
    -- Daily totals
    SUM(notes_created) as daily_notes_created,
    SUM(notes_updated) as daily_notes_updated,
    SUM(notes_deleted) as daily_notes_deleted,
    SUM(total_words_written) as daily_words_written,
    SUM(attachments_uploaded) as daily_attachments_uploaded,
    SUM(comments_added) as daily_comments_added,
    
    -- Weekly rolling averages
    AVG(SUM(notes_created)) OVER (
        PARTITION BY user_id 
        ORDER BY date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as weekly_avg_notes_created,
    
    AVG(SUM(total_words_written)) OVER (
        PARTITION BY user_id 
        ORDER BY date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as weekly_avg_words_written

FROM note_analytics na
WHERE note_id IS NULL -- Only daily aggregate records
GROUP BY date, user_id
ORDER BY date DESC, user_id;

-- =====================================================
-- TEMPLATE USAGE VIEW
-- =====================================================

CREATE OR REPLACE VIEW template_usage_stats AS
SELECT 
    nt.id,
    nt.user_id,
    nt.name,
    nt.description,
    nt.icon,
    nt.title_template,
    nt.content_template,
    nt.content_html_template,
    nt.default_category,
    nt.default_tags,
    nt.default_color,
    nt.is_public,
    nt.is_featured,
    nt.created_at,
    nt.updated_at,
    
    -- Usage statistics (note: original usage_count from table, additional stats would be tracked separately)
    nt.usage_count,
    0 as unique_users,
    NULL::timestamptz as last_used,
    0 as avg_words_in_notes

FROM note_templates nt
ORDER BY nt.usage_count DESC;

-- =====================================================
-- GRANT VIEW PERMISSIONS
-- =====================================================

GRANT SELECT ON notes_enriched TO authenticated;
GRANT SELECT ON note_folders_tree TO authenticated;
GRANT SELECT ON user_notes_dashboard TO authenticated;
GRANT SELECT ON shared_notes_view TO authenticated;
GRANT SELECT ON recent_notes_activity TO authenticated;
GRANT SELECT ON note_search_results TO authenticated;
GRANT SELECT ON notes_analytics_summary TO authenticated;
GRANT SELECT ON template_usage_stats TO authenticated;
