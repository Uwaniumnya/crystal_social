-- =====================================================
-- CRYSTAL SOCIAL - NOTES SYSTEM TRIGGERS
-- =====================================================
-- Automated triggers for note operations and analytics
-- =====================================================

-- Trigger to automatically update note timestamps
CREATE OR REPLACE FUNCTION update_note_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_note_updated_at
    BEFORE UPDATE ON notes
    FOR EACH ROW
    EXECUTE FUNCTION update_note_timestamp();

-- Trigger to update folder timestamps
CREATE OR REPLACE FUNCTION update_note_folder_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_note_folder_updated_at
    BEFORE UPDATE ON note_folders
    FOR EACH ROW
    EXECUTE FUNCTION update_note_folder_timestamp();

-- Trigger to maintain folder statistics
CREATE OR REPLACE FUNCTION update_folder_statistics()
RETURNS TRIGGER AS $$
DECLARE
    v_old_folder_id UUID;
    v_new_folder_id UUID;
    v_word_count INTEGER;
BEGIN
    -- Determine folder IDs and word count based on operation
    IF TG_OP = 'INSERT' THEN
        v_new_folder_id := NEW.folder_id;
        v_word_count := NEW.word_count;
    ELSIF TG_OP = 'UPDATE' THEN
        v_old_folder_id := OLD.folder_id;
        v_new_folder_id := NEW.folder_id;
        v_word_count := NEW.word_count;
    ELSIF TG_OP = 'DELETE' THEN
        v_old_folder_id := OLD.folder_id;
        v_word_count := OLD.word_count;
    END IF;
    
    -- Update old folder statistics (for UPDATE and DELETE)
    IF v_old_folder_id IS NOT NULL AND (TG_OP = 'UPDATE' OR TG_OP = 'DELETE') THEN
        UPDATE note_folders 
        SET 
            note_count = note_count - 1,
            total_words = total_words - v_word_count
        WHERE id = v_old_folder_id;
    END IF;
    
    -- Update new folder statistics (for INSERT and UPDATE)
    IF v_new_folder_id IS NOT NULL AND (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        UPDATE note_folders 
        SET 
            note_count = note_count + 1,
            total_words = total_words + v_word_count
        WHERE id = v_new_folder_id;
    END IF;
    
    -- Handle word count changes in UPDATE
    IF TG_OP = 'UPDATE' AND v_new_folder_id IS NOT NULL AND v_old_folder_id = v_new_folder_id THEN
        UPDATE note_folders 
        SET total_words = total_words + (NEW.word_count - OLD.word_count)
        WHERE id = v_new_folder_id;
    END IF;
    
    -- Return appropriate record
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_update_folder_statistics
    AFTER INSERT OR UPDATE OR DELETE ON notes
    FOR EACH ROW
    EXECUTE FUNCTION update_folder_statistics();

-- Trigger to update tag usage statistics
CREATE OR REPLACE FUNCTION update_tag_usage()
RETURNS TRIGGER AS $$
DECLARE
    v_tag TEXT;
    v_old_tags TEXT[];
    v_new_tags TEXT[];
    v_user_id UUID;
BEGIN
    IF TG_OP = 'INSERT' THEN
        v_new_tags := NEW.tags;
        v_user_id := NEW.user_id;
    ELSIF TG_OP = 'UPDATE' THEN
        v_old_tags := OLD.tags;
        v_new_tags := NEW.tags;
        v_user_id := NEW.user_id;
    ELSIF TG_OP = 'DELETE' THEN
        v_old_tags := OLD.tags;
        v_user_id := OLD.user_id;
    END IF;
    
    -- Decrease usage count for removed tags
    IF v_old_tags IS NOT NULL THEN
        FOREACH v_tag IN ARRAY v_old_tags
        LOOP
            -- Only decrease if tag is not in new tags (for UPDATE) or for DELETE
            IF TG_OP = 'DELETE' OR (TG_OP = 'UPDATE' AND NOT (v_tag = ANY(v_new_tags))) THEN
                UPDATE note_tags 
                SET usage_count = GREATEST(0, usage_count - 1)
                WHERE user_id = v_user_id AND name = v_tag;
            END IF;
        END LOOP;
    END IF;
    
    -- Increase usage count for added tags
    IF v_new_tags IS NOT NULL THEN
        FOREACH v_tag IN ARRAY v_new_tags
        LOOP
            -- Only increase if tag is not in old tags (for UPDATE) or for INSERT
            IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND NOT (v_tag = ANY(v_old_tags))) THEN
                INSERT INTO note_tags (user_id, name, usage_count)
                VALUES (v_user_id, v_tag, 1)
                ON CONFLICT (user_id, name) DO UPDATE SET
                    usage_count = note_tags.usage_count + 1;
            END IF;
        END LOOP;
    END IF;
    
    -- Return appropriate record
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_update_tag_usage
    AFTER INSERT OR UPDATE OF tags OR DELETE ON notes
    FOR EACH ROW
    EXECUTE FUNCTION update_tag_usage();

-- Trigger to automatically update content statistics
CREATE OR REPLACE FUNCTION update_content_statistics()
RETURNS TRIGGER AS $$
DECLARE
    v_word_count INTEGER;
    v_character_count INTEGER;
    v_read_time INTEGER;
    v_has_images BOOLEAN := false;
    v_has_audio BOOLEAN := false;
    v_has_attachments BOOLEAN := false;
BEGIN
    -- Only update if content changed
    IF TG_OP = 'INSERT' OR OLD.content IS DISTINCT FROM NEW.content THEN
        -- Calculate word count
        v_word_count := COALESCE(array_length(string_to_array(trim(NEW.content), ' '), 1), 0);
        
        -- Calculate character count
        v_character_count := LENGTH(NEW.content);
        
        -- Calculate estimated reading time (200 words per minute)
        v_read_time := GREATEST(1, CEIL(v_word_count / 200.0));
        
        -- Check for media content in HTML
        IF NEW.content_html IS NOT NULL THEN
            v_has_images := NEW.content_html ~* '<img[^>]*>';
            v_has_audio := NEW.content_html ~* '<audio[^>]*>' OR NEW.audio_path IS NOT NULL;
        END IF;
        
        -- Check for attachments
        v_has_attachments := array_length(NEW.attachments, 1) > 0;
        
        -- Update the record
        NEW.word_count := v_word_count;
        NEW.character_count := v_character_count;
        NEW.estimated_read_time := v_read_time;
        NEW.has_images := v_has_images;
        NEW.has_audio := v_has_audio OR NEW.audio_path IS NOT NULL;
        NEW.has_attachments := v_has_attachments;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_update_content_statistics
    BEFORE INSERT OR UPDATE ON notes
    FOR EACH ROW
    EXECUTE FUNCTION update_content_statistics();

-- Trigger to create default user settings
CREATE OR REPLACE FUNCTION create_default_user_settings()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO note_user_settings (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- This trigger would be on the auth.users table, but since we can't modify that,
-- we'll create a function that can be called when a user first accesses notes
CREATE OR REPLACE FUNCTION ensure_user_note_settings(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
    INSERT INTO note_user_settings (user_id)
    VALUES (p_user_id)
    ON CONFLICT (user_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to update share view counts
CREATE OR REPLACE FUNCTION update_share_view_count()
RETURNS TRIGGER AS $$
BEGIN
    -- This would be called when a shared note is accessed
    -- Implementation depends on how views are tracked in the app
    UPDATE note_shares 
    SET current_views = current_views + 1 
    WHERE id = NEW.share_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to handle note attachment updates
CREATE OR REPLACE FUNCTION update_note_attachment_flags()
RETURNS TRIGGER AS $$
DECLARE
    v_note_id UUID;
    v_has_images BOOLEAN;
    v_has_audio BOOLEAN;
    v_has_attachments BOOLEAN;
BEGIN
    -- Determine note_id based on operation
    IF TG_OP = 'DELETE' THEN
        v_note_id := OLD.note_id;
    ELSE
        v_note_id := NEW.note_id;
    END IF;
    
    -- Recalculate attachment flags for the note
    SELECT 
        COUNT(*) FILTER (WHERE file_type LIKE 'image/%') > 0,
        COUNT(*) FILTER (WHERE file_type LIKE 'audio/%') > 0,
        COUNT(*) > 0
    INTO v_has_images, v_has_audio, v_has_attachments
    FROM note_attachments 
    WHERE note_id = v_note_id;
    
    -- Update note flags
    UPDATE notes 
    SET 
        has_images = v_has_images,
        has_audio = v_has_audio OR audio_path IS NOT NULL,
        has_attachments = v_has_attachments,
        updated_at = NOW()
    WHERE id = v_note_id;
    
    -- Return appropriate record
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_update_note_attachment_flags
    AFTER INSERT OR DELETE ON note_attachments
    FOR EACH ROW
    EXECUTE FUNCTION update_note_attachment_flags();

-- Trigger to automatically create analytics records
CREATE OR REPLACE FUNCTION create_note_analytics()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
    v_note_id UUID;
    v_date DATE := CURRENT_DATE;
    v_word_delta INTEGER := 0;
BEGIN
    -- Determine user_id and note_id based on operation and table
    IF TG_TABLE_NAME = 'notes' THEN
        IF TG_OP = 'DELETE' THEN
            v_user_id := OLD.user_id;
            v_note_id := OLD.id;
        ELSE
            v_user_id := NEW.user_id;
            v_note_id := NEW.id;
            
            -- Calculate word delta for updates
            IF TG_OP = 'UPDATE' THEN
                v_word_delta := NEW.word_count - OLD.word_count;
            END IF;
        END IF;
    ELSIF TG_TABLE_NAME = 'note_attachments' THEN
        v_user_id := NEW.uploaded_by;
        v_note_id := NEW.note_id;
    ELSIF TG_TABLE_NAME = 'note_comments' THEN
        v_user_id := NEW.user_id;
        v_note_id := NEW.note_id;
    END IF;
    
    -- Ensure analytics record exists for the note and date
    IF v_note_id IS NOT NULL THEN
        INSERT INTO note_analytics (user_id, note_id, date)
        VALUES (v_user_id, v_note_id, v_date)
        ON CONFLICT (user_id, note_id, date) DO NOTHING;
    END IF;
    
    -- Ensure daily aggregate analytics record exists
    INSERT INTO note_analytics (user_id, date)
    VALUES (v_user_id, v_date)
    ON CONFLICT (user_id, note_id, date) WHERE note_id IS NULL DO NOTHING;
    
    -- Update specific metrics based on the triggering event
    IF TG_TABLE_NAME = 'notes' THEN
        IF TG_OP = 'INSERT' THEN
            -- New note created
            UPDATE note_analytics 
            SET notes_created = notes_created + 1,
                total_words_written = total_words_written + NEW.word_count
            WHERE user_id = v_user_id AND date = v_date AND note_id IS NULL;
            
        ELSIF TG_OP = 'UPDATE' THEN
            -- Note updated
            UPDATE note_analytics 
            SET edit_count = edit_count + 1,
                word_count_delta = word_count_delta + v_word_delta
            WHERE user_id = v_user_id AND note_id = v_note_id AND date = v_date;
            
            UPDATE note_analytics 
            SET notes_updated = notes_updated + 1,
                total_words_written = total_words_written + GREATEST(0, v_word_delta)
            WHERE user_id = v_user_id AND date = v_date AND note_id IS NULL;
            
        ELSIF TG_OP = 'DELETE' THEN
            -- Note deleted
            UPDATE note_analytics 
            SET notes_deleted = notes_deleted + 1
            WHERE user_id = v_user_id AND date = v_date AND note_id IS NULL;
        END IF;
        
    ELSIF TG_TABLE_NAME = 'note_attachments' AND TG_OP = 'INSERT' THEN
        -- Attachment uploaded
        UPDATE note_analytics 
        SET attachments_uploaded = attachments_uploaded + 1
        WHERE user_id = v_user_id AND date = v_date AND note_id IS NULL;
        
    ELSIF TG_TABLE_NAME = 'note_comments' AND TG_OP = 'INSERT' THEN
        -- Comment added
        UPDATE note_analytics 
        SET comments_added = comments_added + 1
        WHERE user_id = v_user_id AND date = v_date AND note_id IS NULL;
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
CREATE OR REPLACE TRIGGER trigger_analytics_notes
    AFTER INSERT OR UPDATE OR DELETE ON notes
    FOR EACH ROW
    EXECUTE FUNCTION create_note_analytics();

CREATE OR REPLACE TRIGGER trigger_analytics_attachments
    AFTER INSERT ON note_attachments
    FOR EACH ROW
    EXECUTE FUNCTION create_note_analytics();

CREATE OR REPLACE TRIGGER trigger_analytics_comments
    AFTER INSERT ON note_comments
    FOR EACH ROW
    EXECUTE FUNCTION create_note_analytics();

-- Trigger to handle template usage updates
CREATE OR REPLACE FUNCTION update_template_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_note_template_updated_at
    BEFORE UPDATE ON note_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_template_timestamp();

-- Trigger to prevent circular folder references
CREATE OR REPLACE FUNCTION prevent_circular_folder_reference()
RETURNS TRIGGER AS $$
DECLARE
    v_has_circular BOOLEAN;
BEGIN
    -- Check if the new parent would create a circular reference
    IF NEW.parent_folder_id IS NOT NULL THEN
        -- Use a recursive CTE to check for circular references
        WITH RECURSIVE folder_path AS (
            SELECT id, parent_folder_id, 1 as depth
            FROM note_folders 
            WHERE id = NEW.parent_folder_id
            
            UNION ALL
            
            SELECT nf.id, nf.parent_folder_id, fp.depth + 1
            FROM note_folders nf
            JOIN folder_path fp ON nf.id = fp.parent_folder_id
            WHERE fp.depth < 10 -- Prevent infinite recursion
        )
        SELECT EXISTS (
            SELECT 1 FROM folder_path WHERE id = NEW.id
        ) INTO v_has_circular;
        
        IF v_has_circular THEN
            RAISE EXCEPTION 'Circular folder reference detected';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_prevent_circular_folder_reference
    BEFORE INSERT OR UPDATE ON note_folders
    FOR EACH ROW
    EXECUTE FUNCTION prevent_circular_folder_reference();

-- Trigger to update user settings timestamp
CREATE OR REPLACE FUNCTION update_user_settings_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_note_user_settings_updated_at
    BEFORE UPDATE ON note_user_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_user_settings_timestamp();

-- Function to clean up old data (to be called by scheduled job)
CREATE OR REPLACE FUNCTION cleanup_old_note_data()
RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER := 0;
BEGIN
    -- Delete old revisions (keep only latest 10 per note)
    WITH old_revisions AS (
        SELECT id
        FROM (
            SELECT id, 
                   ROW_NUMBER() OVER (PARTITION BY note_id ORDER BY revision_number DESC) as rn
            FROM note_revisions
        ) t
        WHERE rn > 10
    )
    DELETE FROM note_revisions 
    WHERE id IN (SELECT id FROM old_revisions);
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    -- Delete old analytics data (older than 1 year)
    DELETE FROM note_analytics 
    WHERE date < CURRENT_DATE - INTERVAL '365 days';
    
    -- Delete expired shares
    UPDATE note_shares 
    SET is_active = false 
    WHERE expires_at < NOW() AND is_active = true;
    
    -- Permanently delete notes that have been soft-deleted for more than 30 days
    DELETE FROM notes 
    WHERE is_deleted = true 
      AND deleted_at < NOW() - INTERVAL '30 days';
    
    RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql;
