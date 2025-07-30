-- =====================================================
-- CRYSTAL SOCIAL - NOTES SYSTEM FUNCTIONS
-- =====================================================
-- Advanced operations for note management and features
-- =====================================================

-- Function to create a new note with validation and analytics
CREATE OR REPLACE FUNCTION create_note(
    p_user_id UUID,
    p_title TEXT DEFAULT '',
    p_content TEXT DEFAULT '',
    p_content_html TEXT DEFAULT NULL,
    p_category VARCHAR(100) DEFAULT NULL,
    p_tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    p_folder_id UUID DEFAULT NULL,
    p_color INTEGER DEFAULT NULL,
    p_template_id UUID DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_note_id UUID;
    v_word_count INTEGER;
    v_character_count INTEGER;
    v_read_time INTEGER;
    v_result JSONB;
BEGIN
    -- Calculate content statistics
    v_word_count := COALESCE(array_length(string_to_array(trim(p_content), ' '), 1), 0);
    v_character_count := LENGTH(p_content);
    v_read_time := GREATEST(1, CEIL(v_word_count / 200.0)); -- Assume 200 WPM reading speed
    
    -- Validate folder ownership if specified
    IF p_folder_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM note_folders WHERE id = p_folder_id AND user_id = p_user_id) THEN
            RETURN jsonb_build_object('success', false, 'error', 'Invalid folder ID');
        END IF;
    END IF;
    
    -- Create the note
    INSERT INTO notes (
        user_id, title, content, content_html, category, tags, folder_id, color,
        word_count, character_count, estimated_read_time,
        has_audio, has_images, has_attachments
    ) VALUES (
        p_user_id, p_title, p_content, p_content_html, p_category, p_tags, p_folder_id, p_color,
        v_word_count, v_character_count, v_read_time,
        false, false, false
    ) RETURNING id INTO v_note_id;
    
    -- Create initial revision
    INSERT INTO note_revisions (
        note_id, editor_id, title, content, content_html, revision_number,
        change_type, word_count, character_count
    ) VALUES (
        v_note_id, p_user_id, p_title, p_content, p_content_html, 1,
        'create', v_word_count, v_character_count
    );
    
    -- Update template usage count if template was used
    IF p_template_id IS NOT NULL THEN
        UPDATE note_templates 
        SET usage_count = usage_count + 1 
        WHERE id = p_template_id AND user_id = p_user_id;
    END IF;
    
    -- Update analytics
    INSERT INTO note_analytics (user_id, date, notes_created, total_words_written)
    VALUES (p_user_id, CURRENT_DATE, 1, v_word_count)
    ON CONFLICT (user_id, note_id, date) DO UPDATE SET
        notes_created = note_analytics.notes_created + 1,
        total_words_written = note_analytics.total_words_written + v_word_count;
    
    RETURN jsonb_build_object(
        'success', true,
        'note_id', v_note_id,
        'word_count', v_word_count,
        'character_count', v_character_count,
        'estimated_read_time', v_read_time,
        'message', 'Note created successfully'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Failed to create note: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update note content with revision tracking
CREATE OR REPLACE FUNCTION update_note_content(
    p_note_id UUID,
    p_user_id UUID,
    p_title TEXT,
    p_content TEXT,
    p_content_html TEXT DEFAULT NULL,
    p_category VARCHAR(100) DEFAULT NULL,
    p_tags TEXT[] DEFAULT NULL,
    p_change_summary TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_old_note RECORD;
    v_word_count INTEGER;
    v_character_count INTEGER;
    v_read_time INTEGER;
    v_revision_number INTEGER;
    v_word_delta INTEGER;
BEGIN
    -- Get current note data
    SELECT * INTO v_old_note FROM notes WHERE id = p_note_id AND user_id = p_user_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Note not found or access denied');
    END IF;
    
    -- Calculate new content statistics
    v_word_count := COALESCE(array_length(string_to_array(trim(p_content), ' '), 1), 0);
    v_character_count := LENGTH(p_content);
    v_read_time := GREATEST(1, CEIL(v_word_count / 200.0));
    v_word_delta := v_word_count - v_old_note.word_count;
    
    -- Get next revision number
    SELECT COALESCE(MAX(revision_number), 0) + 1 INTO v_revision_number
    FROM note_revisions WHERE note_id = p_note_id;
    
    -- Update the note
    UPDATE notes SET
        title = p_title,
        content = p_content,
        content_html = p_content_html,
        category = COALESCE(p_category, category),
        tags = COALESCE(p_tags, tags),
        word_count = v_word_count,
        character_count = v_character_count,
        estimated_read_time = v_read_time,
        version = version + 1,
        last_editor_id = p_user_id,
        updated_at = NOW()
    WHERE id = p_note_id;
    
    -- Create revision record
    INSERT INTO note_revisions (
        note_id, editor_id, title, content, content_html, revision_number,
        change_summary, change_type, word_count, character_count
    ) VALUES (
        p_note_id, p_user_id, p_title, p_content, p_content_html, v_revision_number,
        p_change_summary, 'edit', v_word_count, v_character_count
    );
    
    -- Update analytics
    INSERT INTO note_analytics (user_id, note_id, date, edit_count, word_count_delta)
    VALUES (p_user_id, p_note_id, CURRENT_DATE, 1, v_word_delta)
    ON CONFLICT (user_id, note_id, date) DO UPDATE SET
        edit_count = note_analytics.edit_count + 1,
        word_count_delta = note_analytics.word_count_delta + v_word_delta;
    
    -- Update daily aggregate analytics
    INSERT INTO note_analytics (user_id, date, notes_updated, total_words_written)
    VALUES (p_user_id, CURRENT_DATE, 1, GREATEST(0, v_word_delta))
    ON CONFLICT (user_id, note_id, date) WHERE note_id IS NULL DO UPDATE SET
        notes_updated = note_analytics.notes_updated + 1,
        total_words_written = note_analytics.total_words_written + GREATEST(0, v_word_delta);
    
    RETURN jsonb_build_object(
        'success', true,
        'revision_number', v_revision_number,
        'word_count', v_word_count,
        'word_delta', v_word_delta,
        'character_count', v_character_count,
        'estimated_read_time', v_read_time,
        'message', 'Note updated successfully'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Failed to update note: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to soft delete notes with recovery option
CREATE OR REPLACE FUNCTION delete_note(
    p_note_id UUID,
    p_user_id UUID,
    p_permanent BOOLEAN DEFAULT false
) RETURNS JSONB AS $$
DECLARE
    v_note RECORD;
    v_folder_id UUID;
BEGIN
    -- Get note details
    SELECT * INTO v_note FROM notes WHERE id = p_note_id AND user_id = p_user_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Note not found or access denied');
    END IF;
    
    v_folder_id := v_note.folder_id;
    
    IF p_permanent THEN
        -- Permanent deletion
        DELETE FROM notes WHERE id = p_note_id;
        
        -- Update analytics
        INSERT INTO note_analytics (user_id, date, notes_deleted)
        VALUES (p_user_id, CURRENT_DATE, 1)
        ON CONFLICT (user_id, note_id, date) WHERE note_id IS NULL DO UPDATE SET
            notes_deleted = note_analytics.notes_deleted + 1;
    ELSE
        -- Soft deletion
        UPDATE notes SET
            is_deleted = true,
            deleted_at = NOW(),
            updated_at = NOW()
        WHERE id = p_note_id;
    END IF;
    
    -- Update folder statistics if note was in a folder
    IF v_folder_id IS NOT NULL THEN
        UPDATE note_folders SET
            note_count = note_count - 1,
            total_words = total_words - v_note.word_count
        WHERE id = v_folder_id;
    END IF;
    
    RETURN jsonb_build_object(
        'success', true,
        'permanent', p_permanent,
        'message', CASE WHEN p_permanent THEN 'Note permanently deleted' ELSE 'Note moved to trash' END
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Failed to delete note: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to restore deleted notes
CREATE OR REPLACE FUNCTION restore_note(
    p_note_id UUID,
    p_user_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_note RECORD;
BEGIN
    -- Get deleted note
    SELECT * INTO v_note FROM notes 
    WHERE id = p_note_id AND user_id = p_user_id AND is_deleted = true;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Deleted note not found');
    END IF;
    
    -- Restore the note
    UPDATE notes SET
        is_deleted = false,
        deleted_at = NULL,
        updated_at = NOW()
    WHERE id = p_note_id;
    
    -- Update folder statistics if note was in a folder
    IF v_note.folder_id IS NOT NULL THEN
        UPDATE note_folders SET
            note_count = note_count + 1,
            total_words = total_words + v_note.word_count
        WHERE id = v_note.folder_id;
    END IF;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Note restored successfully'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Failed to restore note: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to search notes with advanced filtering
CREATE OR REPLACE FUNCTION search_notes(
    p_user_id UUID,
    p_query TEXT DEFAULT '',
    p_category VARCHAR(100) DEFAULT NULL,
    p_tags TEXT[] DEFAULT NULL,
    p_folder_id UUID DEFAULT NULL,
    p_is_favorite BOOLEAN DEFAULT NULL,
    p_is_pinned BOOLEAN DEFAULT NULL,
    p_date_from DATE DEFAULT NULL,
    p_date_to DATE DEFAULT NULL,
    p_sort_by VARCHAR(20) DEFAULT 'updated_desc',
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
) RETURNS JSONB AS $$
DECLARE
    v_sql TEXT;
    v_where_conditions TEXT[];
    v_results JSONB;
BEGIN
    -- Build base query
    v_sql := 'SELECT id, title, content, category, tags, is_favorite, is_pinned, 
              word_count, character_count, created_at, updated_at, last_viewed_at,
              ts_rank(search_vector, plainto_tsquery(''english'', $1)) as rank
              FROM notes WHERE user_id = $2 AND is_deleted = false';
    
    -- Add search conditions
    IF p_query != '' THEN
        v_sql := v_sql || ' AND search_vector @@ plainto_tsquery(''english'', $1)';
    END IF;
    
    IF p_category IS NOT NULL THEN
        v_sql := v_sql || ' AND category = ''' || p_category || '''';
    END IF;
    
    IF p_tags IS NOT NULL THEN
        v_sql := v_sql || ' AND tags @> ARRAY[''' || array_to_string(p_tags, ''',''') || ''']';
    END IF;
    
    IF p_folder_id IS NOT NULL THEN
        v_sql := v_sql || ' AND folder_id = ''' || p_folder_id || '''';
    END IF;
    
    IF p_is_favorite IS NOT NULL THEN
        v_sql := v_sql || ' AND is_favorite = ' || p_is_favorite;
    END IF;
    
    IF p_is_pinned IS NOT NULL THEN
        v_sql := v_sql || ' AND is_pinned = ' || p_is_pinned;
    END IF;
    
    IF p_date_from IS NOT NULL THEN
        v_sql := v_sql || ' AND created_at >= ''' || p_date_from || '''';
    END IF;
    
    IF p_date_to IS NOT NULL THEN
        v_sql := v_sql || ' AND created_at <= ''' || p_date_to || ' 23:59:59''';
    END IF;
    
    -- Add sorting
    v_sql := v_sql || ' ORDER BY ';
    CASE p_sort_by
        WHEN 'created_desc' THEN v_sql := v_sql || 'created_at DESC';
        WHEN 'created_asc' THEN v_sql := v_sql || 'created_at ASC';
        WHEN 'updated_asc' THEN v_sql := v_sql || 'updated_at ASC';
        WHEN 'title_asc' THEN v_sql := v_sql || 'title ASC';
        WHEN 'title_desc' THEN v_sql := v_sql || 'title DESC';
        WHEN 'relevance' THEN v_sql := v_sql || 'rank DESC, updated_at DESC';
        ELSE v_sql := v_sql || 'updated_at DESC';
    END CASE;
    
    -- Add pagination
    v_sql := v_sql || ' LIMIT ' || p_limit || ' OFFSET ' || p_offset;
    
    -- Execute query and return results as JSON
    EXECUTE 'SELECT jsonb_agg(row_to_json(t)) FROM (' || v_sql || ') t'
    INTO v_results
    USING p_query, p_user_id;
    
    RETURN COALESCE(v_results, '[]'::jsonb);
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'error', 'Search failed: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to share a note
CREATE OR REPLACE FUNCTION share_note(
    p_note_id UUID,
    p_user_id UUID,
    p_share_type VARCHAR(20) DEFAULT 'link',
    p_shared_with UUID DEFAULT NULL,
    p_can_read BOOLEAN DEFAULT true,
    p_can_write BOOLEAN DEFAULT false,
    p_can_comment BOOLEAN DEFAULT false,
    p_expires_hours INTEGER DEFAULT NULL,
    p_password TEXT DEFAULT NULL,
    p_max_views INTEGER DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_share_id UUID;
    v_share_token VARCHAR(100);
    v_password_hash TEXT;
    v_expires_at TIMESTAMPTZ;
BEGIN
    -- Verify note ownership
    IF NOT EXISTS (SELECT 1 FROM notes WHERE id = p_note_id AND user_id = p_user_id) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Note not found or access denied');
    END IF;
    
    -- Generate share token for link sharing
    IF p_share_type IN ('link', 'public') THEN
        v_share_token := encode(gen_random_bytes(32), 'base64url');
    END IF;
    
    -- Hash password if provided
    IF p_password IS NOT NULL THEN
        v_password_hash := crypt(p_password, gen_salt('bf'));
    END IF;
    
    -- Calculate expiry
    IF p_expires_hours IS NOT NULL THEN
        v_expires_at := NOW() + (p_expires_hours || ' hours')::INTERVAL;
    END IF;
    
    -- Create share record
    INSERT INTO note_shares (
        note_id, shared_by, shared_with, share_type, share_token,
        can_read, can_write, can_comment, expires_at, password_hash, max_views
    ) VALUES (
        p_note_id, p_user_id, p_shared_with, p_share_type, v_share_token,
        p_can_read, p_can_write, p_can_comment, v_expires_at, v_password_hash, p_max_views
    ) RETURNING id INTO v_share_id;
    
    -- Update note sharing status
    UPDATE notes SET is_shared = true WHERE id = p_note_id;
    
    -- Update analytics
    INSERT INTO note_analytics (user_id, date, notes_shared)
    VALUES (p_user_id, CURRENT_DATE, 1)
    ON CONFLICT (user_id, note_id, date) WHERE note_id IS NULL DO UPDATE SET
        notes_shared = note_analytics.notes_shared + 1;
    
    RETURN jsonb_build_object(
        'success', true,
        'share_id', v_share_id,
        'share_token', v_share_token,
        'share_url', CASE 
            WHEN v_share_token IS NOT NULL THEN 'https://app.crystalsocial.com/notes/shared/' || v_share_token
            ELSE NULL
        END,
        'expires_at', v_expires_at,
        'message', 'Note shared successfully'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Failed to share note: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create a note folder
CREATE OR REPLACE FUNCTION create_note_folder(
    p_user_id UUID,
    p_name VARCHAR(100),
    p_description TEXT DEFAULT NULL,
    p_parent_folder_id UUID DEFAULT NULL,
    p_color INTEGER DEFAULT NULL,
    p_icon VARCHAR(50) DEFAULT 'folder'
) RETURNS JSONB AS $$
DECLARE
    v_folder_id UUID;
BEGIN
    -- Validate parent folder ownership if specified
    IF p_parent_folder_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM note_folders WHERE id = p_parent_folder_id AND user_id = p_user_id) THEN
            RETURN jsonb_build_object('success', false, 'error', 'Invalid parent folder');
        END IF;
    END IF;
    
    -- Check for duplicate folder names in the same parent
    IF EXISTS (
        SELECT 1 FROM note_folders 
        WHERE user_id = p_user_id 
          AND name = p_name 
          AND (parent_folder_id = p_parent_folder_id OR (parent_folder_id IS NULL AND p_parent_folder_id IS NULL))
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Folder name already exists');
    END IF;
    
    -- Create folder
    INSERT INTO note_folders (
        user_id, name, description, parent_folder_id, color, icon
    ) VALUES (
        p_user_id, p_name, p_description, p_parent_folder_id, p_color, p_icon
    ) RETURNING id INTO v_folder_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'folder_id', v_folder_id,
        'message', 'Folder created successfully'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Failed to create folder: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's note statistics
CREATE OR REPLACE FUNCTION get_note_statistics(
    p_user_id UUID,
    p_days INTEGER DEFAULT 30
) RETURNS JSONB AS $$
DECLARE
    v_stats JSONB;
    v_start_date DATE := CURRENT_DATE - p_days;
BEGIN
    WITH note_stats AS (
        SELECT 
            COUNT(*) as total_notes,
            COUNT(*) FILTER (WHERE is_favorite) as favorite_notes,
            COUNT(*) FILTER (WHERE is_pinned) as pinned_notes,
            COUNT(*) FILTER (WHERE is_archived) as archived_notes,
            COUNT(*) FILTER (WHERE created_at >= v_start_date) as recent_notes,
            SUM(word_count) as total_words,
            AVG(word_count) as avg_words_per_note,
            COUNT(DISTINCT category) FILTER (WHERE category IS NOT NULL) as categories_used,
            COUNT(DISTINCT unnest(tags)) as unique_tags
        FROM notes 
        WHERE user_id = p_user_id AND is_deleted = false
    ),
    activity_stats AS (
        SELECT 
            COALESCE(SUM(notes_created), 0) as notes_created_period,
            COALESCE(SUM(notes_updated), 0) as notes_updated_period,
            COALESCE(SUM(total_words_written), 0) as words_written_period,
            COALESCE(SUM(total_time_spent_minutes), 0) as time_spent_period
        FROM note_analytics 
        WHERE user_id = p_user_id 
          AND note_id IS NULL 
          AND date >= v_start_date
    ),
    top_categories AS (
        SELECT jsonb_agg(
            jsonb_build_object(
                'category', category,
                'count', count
            ) ORDER BY count DESC
        ) as categories
        FROM (
            SELECT category, COUNT(*) as count
            FROM notes 
            WHERE user_id = p_user_id 
              AND is_deleted = false 
              AND category IS NOT NULL
            GROUP BY category
            ORDER BY count DESC
            LIMIT 5
        ) t
    )
    SELECT jsonb_build_object(
        'period_days', p_days,
        'total_notes', ns.total_notes,
        'favorite_notes', ns.favorite_notes,
        'pinned_notes', ns.pinned_notes,
        'archived_notes', ns.archived_notes,
        'recent_notes', ns.recent_notes,
        'total_words', ns.total_words,
        'avg_words_per_note', ROUND(ns.avg_words_per_note, 1),
        'categories_used', ns.categories_used,
        'unique_tags', ns.unique_tags,
        'notes_created_period', acs.notes_created_period,
        'notes_updated_period', acs.notes_updated_period,
        'words_written_period', acs.words_written_period,
        'time_spent_period', acs.time_spent_period,
        'avg_daily_words', ROUND(acs.words_written_period::DECIMAL / p_days, 1),
        'top_categories', COALESCE(tc.categories, '[]'::jsonb),
        'generated_at', NOW()
    ) INTO v_stats
    FROM note_stats ns, activity_stats acs, top_categories tc;
    
    RETURN v_stats;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'error', 'Failed to generate statistics: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
