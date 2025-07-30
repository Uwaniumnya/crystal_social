-- =====================================================
-- CRYSTAL SOCIAL - NOTES SYSTEM SECURITY
-- =====================================================
-- Row Level Security policies for notes system
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE note_folders ENABLE ROW LEVEL SECURITY;
ALTER TABLE note_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE note_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE note_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE note_revisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE note_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE note_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE note_bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE note_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE note_user_settings ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- NOTES TABLE POLICIES
-- =====================================================

-- Users can view their own notes and shared notes
CREATE POLICY "Users can view own notes" ON notes
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can view shared notes" ON notes
    FOR SELECT USING (
        id IN (
            SELECT note_id FROM note_shares 
            WHERE is_active = true 
            AND (expires_at IS NULL OR expires_at > NOW())
            AND (
                share_token IS NOT NULL OR
                shared_with = auth.uid() OR
                share_type = 'public'
            )
        )
    );

-- Users can insert their own notes
CREATE POLICY "Users can insert own notes" ON notes
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Users can update their own notes and notes shared with edit permissions
CREATE POLICY "Users can update own notes" ON notes
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can update shared notes with edit permission" ON notes
    FOR UPDATE USING (
        id IN (
            SELECT note_id FROM note_shares 
            WHERE shared_with = auth.uid()
            AND is_active = true 
            AND (expires_at IS NULL OR expires_at > NOW())
            AND can_write = true
        )
    );

-- Users can delete their own notes (soft delete)
CREATE POLICY "Users can delete own notes" ON notes
    FOR DELETE USING (user_id = auth.uid());

-- =====================================================
-- NOTE FOLDERS TABLE POLICIES
-- =====================================================

-- Users can view their own folders
CREATE POLICY "Users can view own folders" ON note_folders
    FOR SELECT USING (user_id = auth.uid());

-- Users can insert their own folders
CREATE POLICY "Users can insert own folders" ON note_folders
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Users can update their own folders
CREATE POLICY "Users can update own folders" ON note_folders
    FOR UPDATE USING (user_id = auth.uid());

-- Users can delete their own folders
CREATE POLICY "Users can delete own folders" ON note_folders
    FOR DELETE USING (user_id = auth.uid());

-- =====================================================
-- NOTE TEMPLATES TABLE POLICIES
-- =====================================================

-- Users can view their own templates and public templates
CREATE POLICY "Users can view own templates" ON note_templates
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can view public templates" ON note_templates
    FOR SELECT USING (is_public = true);

-- Users can insert their own templates
CREATE POLICY "Users can insert own templates" ON note_templates
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Users can update their own templates
CREATE POLICY "Users can update own templates" ON note_templates
    FOR UPDATE USING (user_id = auth.uid());

-- Users can delete their own templates
CREATE POLICY "Users can delete own templates" ON note_templates
    FOR DELETE USING (user_id = auth.uid());

-- =====================================================
-- NOTE SHARES TABLE POLICIES
-- =====================================================

-- Users can view shares they created or shares that include them
CREATE POLICY "Users can view own shares" ON note_shares
    FOR SELECT USING (
        shared_by = auth.uid() OR 
        shared_with = auth.uid()
    );

-- Users can create shares for their own notes
CREATE POLICY "Users can create shares for own notes" ON note_shares
    FOR INSERT WITH CHECK (
        shared_by = auth.uid() AND
        note_id IN (SELECT id FROM notes WHERE user_id = auth.uid())
    );

-- Users can update their own shares
CREATE POLICY "Users can update own shares" ON note_shares
    FOR UPDATE USING (shared_by = auth.uid());

-- Users can delete their own shares
CREATE POLICY "Users can delete own shares" ON note_shares
    FOR DELETE USING (shared_by = auth.uid());

-- =====================================================
-- NOTE COMMENTS TABLE POLICIES
-- =====================================================

-- Users can view comments on notes they can access
CREATE POLICY "Users can view comments on accessible notes" ON note_comments
    FOR SELECT USING (
        note_id IN (
            SELECT id FROM notes WHERE user_id = auth.uid()
            UNION
            SELECT note_id FROM note_shares 
            WHERE (shared_with = auth.uid() OR share_type = 'public')
            AND is_active = true 
            AND (expires_at IS NULL OR expires_at > NOW())
        )
    );

-- Users can insert comments on notes they can access
CREATE POLICY "Users can insert comments on accessible notes" ON note_comments
    FOR INSERT WITH CHECK (
        user_id = auth.uid() AND
        note_id IN (
            SELECT id FROM notes WHERE user_id = auth.uid()
            UNION
            SELECT note_id FROM note_shares 
            WHERE (shared_with = auth.uid() OR share_type = 'public')
            AND is_active = true 
            AND (expires_at IS NULL OR expires_at > NOW())
            AND can_comment = true
        )
    );

-- Users can update their own comments
CREATE POLICY "Users can update own comments" ON note_comments
    FOR UPDATE USING (user_id = auth.uid());

-- Users can delete their own comments or comments on their notes
CREATE POLICY "Users can delete own comments" ON note_comments
    FOR DELETE USING (
        user_id = auth.uid() OR
        note_id IN (SELECT id FROM notes WHERE user_id = auth.uid())
    );

-- =====================================================
-- NOTE REVISIONS TABLE POLICIES
-- =====================================================

-- Users can view revisions of notes they can access
CREATE POLICY "Users can view revisions of accessible notes" ON note_revisions
    FOR SELECT USING (
        note_id IN (
            SELECT id FROM notes WHERE user_id = auth.uid()
            UNION
            SELECT note_id FROM note_shares 
            WHERE shared_with = auth.uid()
            AND is_active = true 
            AND (expires_at IS NULL OR expires_at > NOW())
        )
    );

-- System can insert revisions (typically through triggers)
CREATE POLICY "System can insert revisions" ON note_revisions
    FOR INSERT WITH CHECK (true);

-- Only allow deleting very old revisions by note owners
CREATE POLICY "Users can delete old revisions of own notes" ON note_revisions
    FOR DELETE USING (
        created_at < NOW() - INTERVAL '30 days' AND
        note_id IN (SELECT id FROM notes WHERE user_id = auth.uid())
    );

-- =====================================================
-- NOTE TAGS TABLE POLICIES
-- =====================================================

-- Users can view their own tags
CREATE POLICY "Users can view own tags" ON note_tags
    FOR SELECT USING (user_id = auth.uid());

-- Users can insert their own tags
CREATE POLICY "Users can insert own tags" ON note_tags
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Users can update their own tags
CREATE POLICY "Users can update own tags" ON note_tags
    FOR UPDATE USING (user_id = auth.uid());

-- Users can delete their own tags
CREATE POLICY "Users can delete own tags" ON note_tags
    FOR DELETE USING (user_id = auth.uid());

-- =====================================================
-- NOTE ATTACHMENTS TABLE POLICIES
-- =====================================================

-- Users can view attachments on notes they can access
CREATE POLICY "Users can view attachments on accessible notes" ON note_attachments
    FOR SELECT USING (
        note_id IN (
            SELECT id FROM notes WHERE user_id = auth.uid()
            UNION
            SELECT note_id FROM note_shares 
            WHERE (shared_with = auth.uid() OR share_type = 'public')
            AND is_active = true 
            AND (expires_at IS NULL OR expires_at > NOW())
        )
    );

-- Users can upload attachments to notes they can edit
CREATE POLICY "Users can upload attachments to editable notes" ON note_attachments
    FOR INSERT WITH CHECK (
        uploaded_by = auth.uid() AND
        note_id IN (
            SELECT id FROM notes WHERE user_id = auth.uid()
            UNION
            SELECT note_id FROM note_shares 
            WHERE shared_with = auth.uid()
            AND is_active = true 
            AND (expires_at IS NULL OR expires_at > NOW())
            AND can_write = true
        )
    );

-- Users can update attachments they uploaded or on their notes
CREATE POLICY "Users can update own attachments" ON note_attachments
    FOR UPDATE USING (
        uploaded_by = auth.uid() OR
        note_id IN (SELECT id FROM notes WHERE user_id = auth.uid())
    );

-- Users can delete attachments they uploaded or on their notes
CREATE POLICY "Users can delete own attachments" ON note_attachments
    FOR DELETE USING (
        uploaded_by = auth.uid() OR
        note_id IN (SELECT id FROM notes WHERE user_id = auth.uid())
    );

-- =====================================================
-- NOTE BOOKMARKS TABLE POLICIES
-- =====================================================

-- Users can view their own bookmarks
CREATE POLICY "Users can view own bookmarks" ON note_bookmarks
    FOR SELECT USING (user_id = auth.uid());

-- Users can insert their own bookmarks for accessible notes
CREATE POLICY "Users can insert own bookmarks" ON note_bookmarks
    FOR INSERT WITH CHECK (
        user_id = auth.uid() AND
        note_id IN (
            SELECT id FROM notes WHERE user_id = auth.uid()
            UNION
            SELECT note_id FROM note_shares 
            WHERE (shared_with = auth.uid() OR share_type = 'public')
            AND is_active = true 
            AND (expires_at IS NULL OR expires_at > NOW())
        )
    );

-- Users can update their own bookmarks
CREATE POLICY "Users can update own bookmarks" ON note_bookmarks
    FOR UPDATE USING (user_id = auth.uid());

-- Users can delete their own bookmarks
CREATE POLICY "Users can delete own bookmarks" ON note_bookmarks
    FOR DELETE USING (user_id = auth.uid());

-- =====================================================
-- NOTE ANALYTICS TABLE POLICIES
-- =====================================================

-- Users can view their own analytics
CREATE POLICY "Users can view own analytics" ON note_analytics
    FOR SELECT USING (user_id = auth.uid());

-- System can insert analytics data
CREATE POLICY "System can insert analytics" ON note_analytics
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- System can update analytics data
CREATE POLICY "System can update analytics" ON note_analytics
    FOR UPDATE USING (user_id = auth.uid());

-- Allow cleanup of old analytics data
CREATE POLICY "Allow cleanup of old analytics" ON note_analytics
    FOR DELETE USING (date < CURRENT_DATE - INTERVAL '365 days');

-- =====================================================
-- NOTE USER SETTINGS TABLE POLICIES
-- =====================================================

-- Users can view their own settings
CREATE POLICY "Users can view own settings" ON note_user_settings
    FOR SELECT USING (user_id = auth.uid());

-- Users can insert their own settings
CREATE POLICY "Users can insert own settings" ON note_user_settings
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Users can update their own settings
CREATE POLICY "Users can update own settings" ON note_user_settings
    FOR UPDATE USING (user_id = auth.uid());

-- Users can delete their own settings
CREATE POLICY "Users can delete own settings" ON note_user_settings
    FOR DELETE USING (user_id = auth.uid());

-- =====================================================
-- ADDITIONAL SECURITY FUNCTIONS
-- =====================================================

-- Function to check if user can access a note
CREATE OR REPLACE FUNCTION can_access_note(p_note_id UUID, p_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        -- User owns the note
        SELECT 1 FROM notes 
        WHERE id = p_note_id AND user_id = p_user_id
        
        UNION
        
        -- Note is shared with user or publicly
        SELECT 1 FROM note_shares 
        WHERE note_id = p_note_id
        AND is_active = true 
        AND (expires_at IS NULL OR expires_at > NOW())
        AND (
            shared_with = p_user_id OR
            share_type = 'public'
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user can edit a note
CREATE OR REPLACE FUNCTION can_edit_note(p_note_id UUID, p_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        -- User owns the note
        SELECT 1 FROM notes 
        WHERE id = p_note_id AND user_id = p_user_id
        
        UNION
        
        -- Note is shared with edit permission
        SELECT 1 FROM note_shares 
        WHERE note_id = p_note_id
        AND shared_with = p_user_id
        AND is_active = true 
        AND (expires_at IS NULL OR expires_at > NOW())
        AND can_write = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's note access level
CREATE OR REPLACE FUNCTION get_note_access_level(p_note_id UUID, p_user_id UUID DEFAULT auth.uid())
RETURNS TEXT AS $$
DECLARE
    v_access_level TEXT := 'none';
    v_can_read BOOLEAN := false;
    v_can_write BOOLEAN := false;
    v_can_comment BOOLEAN := false;
BEGIN
    -- Check if user owns the note
    IF EXISTS (SELECT 1 FROM notes WHERE id = p_note_id AND user_id = p_user_id) THEN
        RETURN 'owner';
    END IF;
    
    -- Check shared access
    SELECT can_read, can_write, can_comment 
    INTO v_can_read, v_can_write, v_can_comment
    FROM note_shares 
    WHERE note_id = p_note_id
    AND shared_with = p_user_id
    AND is_active = true 
    AND (expires_at IS NULL OR expires_at > NOW())
    LIMIT 1;
    
    -- Determine access level based on permissions
    IF v_can_write THEN
        v_access_level := 'edit';
    ELSIF v_can_comment THEN
        v_access_level := 'comment';
    ELSIF v_can_read THEN
        v_access_level := 'read';
    END IF;
    
    -- Check public access if no direct share found
    IF v_access_level = 'none' AND EXISTS (
        SELECT 1 FROM note_shares 
        WHERE note_id = p_note_id
        AND share_type = 'public'
        AND is_active = true 
        AND (expires_at IS NULL OR expires_at > NOW())
    ) THEN
        v_access_level := 'read';
    END IF;
    
    RETURN v_access_level;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

-- Grant usage on schema
GRANT USAGE ON SCHEMA public TO authenticated;

-- Grant permissions on tables
GRANT SELECT, INSERT, UPDATE, DELETE ON notes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON note_folders TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON note_templates TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON note_shares TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON note_comments TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON note_revisions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON note_tags TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON note_attachments TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON note_bookmarks TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON note_analytics TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON note_user_settings TO authenticated;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION can_access_note(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION can_edit_note(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_note_access_level(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION ensure_user_note_settings(UUID) TO authenticated;

-- Grant execute on all note-related functions to authenticated users
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
