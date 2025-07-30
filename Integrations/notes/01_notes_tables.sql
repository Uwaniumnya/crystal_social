-- =====================================================
-- CRYSTAL SOCIAL - NOTES SYSTEM TABLES
-- =====================================================
-- Core database schema for comprehensive note management
-- =====================================================

-- Note folders/collections (must come before notes table due to FK reference)
CREATE TABLE IF NOT EXISTS note_folders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    parent_folder_id UUID REFERENCES note_folders(id) ON DELETE CASCADE,
    
    -- Folder properties
    name VARCHAR(100) NOT NULL,
    description TEXT,
    color INTEGER,
    icon VARCHAR(50) DEFAULT 'folder',
    
    -- Organization
    sort_order INTEGER DEFAULT 0,
    is_default BOOLEAN DEFAULT false,
    
    -- Statistics (updated by triggers)
    note_count INTEGER DEFAULT 0,
    total_words INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_folder_name CHECK (LENGTH(TRIM(name)) > 0),
    CONSTRAINT no_self_parent CHECK (id != parent_folder_id)
);

-- Core Notes table
CREATE TABLE IF NOT EXISTS notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Content
    title TEXT NOT NULL DEFAULT '',
    content TEXT NOT NULL DEFAULT '',
    content_html TEXT, -- Rich text content in HTML format
    content_delta JSONB, -- Rich text content in Delta format (Quill)
    
    -- Organization
    category VARCHAR(100),
    tags TEXT[] DEFAULT '{}',
    folder_id UUID REFERENCES note_folders(id) ON DELETE SET NULL,
    
    -- Status and properties
    is_favorite BOOLEAN DEFAULT false,
    is_pinned BOOLEAN DEFAULT false,
    is_archived BOOLEAN DEFAULT false,
    is_deleted BOOLEAN DEFAULT false,
    color INTEGER, -- Color value for note theming
    
    -- Content metadata
    word_count INTEGER DEFAULT 0,
    character_count INTEGER DEFAULT 0,
    estimated_read_time INTEGER DEFAULT 0, -- in minutes
    
    -- Media attachments
    audio_path TEXT,
    attachments TEXT[] DEFAULT '{}',
    has_audio BOOLEAN DEFAULT false,
    has_images BOOLEAN DEFAULT false,
    has_attachments BOOLEAN DEFAULT false,
    
    -- Security and access
    is_encrypted BOOLEAN DEFAULT false,
    encryption_key_hash TEXT,
    is_shared BOOLEAN DEFAULT false,
    share_permissions JSONB DEFAULT '{"read": false, "write": false, "comment": false}'::jsonb,
    
    -- Versioning
    version INTEGER DEFAULT 1,
    parent_note_id UUID REFERENCES notes(id) ON DELETE SET NULL,
    
    -- Collaboration
    collaborative_session_id UUID,
    last_editor_id UUID REFERENCES auth.users(id),
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    last_viewed_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Search optimization
    search_vector tsvector,
    
    CONSTRAINT valid_word_count CHECK (word_count >= 0),
    CONSTRAINT valid_character_count CHECK (character_count >= 0),
    CONSTRAINT valid_read_time CHECK (estimated_read_time >= 0),
    CONSTRAINT valid_version CHECK (version > 0)
);

-- Note templates for quick creation
CREATE TABLE IF NOT EXISTS note_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Template properties
    name VARCHAR(100) NOT NULL,
    description TEXT,
    icon VARCHAR(50) DEFAULT 'note',
    
    -- Template content
    title_template TEXT DEFAULT '',
    content_template TEXT DEFAULT '',
    content_html_template TEXT,
    default_category VARCHAR(100),
    default_tags TEXT[] DEFAULT '{}',
    default_color INTEGER,
    
    -- Settings
    is_public BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,
    usage_count INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_template_name CHECK (LENGTH(TRIM(name)) > 0)
);

-- Note sharing and collaboration
CREATE TABLE IF NOT EXISTS note_shares (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    note_id UUID NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
    shared_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    shared_with UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Share details
    share_type VARCHAR(20) DEFAULT 'private', -- private, link, public
    share_token VARCHAR(100) UNIQUE,
    
    -- Permissions
    can_read BOOLEAN DEFAULT true,
    can_write BOOLEAN DEFAULT false,
    can_comment BOOLEAN DEFAULT false,
    can_reshare BOOLEAN DEFAULT false,
    
    -- Link sharing settings
    expires_at TIMESTAMPTZ,
    password_hash TEXT,
    max_views INTEGER,
    current_views INTEGER DEFAULT 0,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_share_type CHECK (share_type IN ('private', 'link', 'public')),
    CONSTRAINT valid_max_views CHECK (max_views IS NULL OR max_views > 0)
);

-- Note comments for collaboration
CREATE TABLE IF NOT EXISTS note_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    note_id UUID NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    parent_comment_id UUID REFERENCES note_comments(id) ON DELETE CASCADE,
    
    -- Comment content
    content TEXT NOT NULL,
    content_html TEXT,
    
    -- Position in note (for inline comments)
    position_start INTEGER,
    position_end INTEGER,
    selected_text TEXT,
    
    -- Status
    is_resolved BOOLEAN DEFAULT false,
    resolved_by UUID REFERENCES auth.users(id),
    resolved_at TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_comment_content CHECK (LENGTH(TRIM(content)) > 0),
    CONSTRAINT valid_position CHECK (
        (position_start IS NULL AND position_end IS NULL) OR 
        (position_start IS NOT NULL AND position_end IS NOT NULL AND position_start <= position_end)
    )
);

-- Note revisions/history
CREATE TABLE IF NOT EXISTS note_revisions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    note_id UUID NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
    editor_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Revision content
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    content_html TEXT,
    content_delta JSONB,
    
    -- Revision metadata
    revision_number INTEGER NOT NULL,
    change_summary TEXT,
    change_type VARCHAR(20) DEFAULT 'edit', -- create, edit, delete, restore
    
    -- Content statistics
    word_count INTEGER DEFAULT 0,
    character_count INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_revision_number CHECK (revision_number > 0),
    CONSTRAINT valid_change_type CHECK (change_type IN ('create', 'edit', 'delete', 'restore'))
);

-- Note tags management
CREATE TABLE IF NOT EXISTS note_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Tag properties
    name VARCHAR(50) NOT NULL,
    color INTEGER,
    description TEXT,
    
    -- Usage statistics
    usage_count INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_tag_name CHECK (LENGTH(TRIM(name)) > 0),
    CONSTRAINT unique_user_tag UNIQUE(user_id, name)
);

-- Note attachments and media
CREATE TABLE IF NOT EXISTS note_attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    note_id UUID NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
    uploaded_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- File information
    filename VARCHAR(255) NOT NULL,
    original_filename VARCHAR(255) NOT NULL,
    file_type VARCHAR(50) NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    
    -- Storage information
    storage_bucket VARCHAR(100) NOT NULL DEFAULT 'note-attachments',
    storage_path TEXT NOT NULL,
    file_url TEXT NOT NULL,
    thumbnail_url TEXT,
    
    -- Media metadata
    width INTEGER,
    height INTEGER,
    duration INTEGER, -- for audio/video in seconds
    metadata JSONB DEFAULT '{}',
    
    -- Processing status
    is_processed BOOLEAN DEFAULT false,
    processing_status VARCHAR(20) DEFAULT 'pending',
    
    -- Security
    is_encrypted BOOLEAN DEFAULT false,
    encryption_key_hash TEXT,
    
    -- Analytics
    download_count INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_file_size CHECK (file_size > 0),
    CONSTRAINT valid_processing_status CHECK (processing_status IN ('pending', 'processing', 'completed', 'failed'))
);

-- Note bookmarks for quick access
CREATE TABLE IF NOT EXISTS note_bookmarks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    note_id UUID NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
    
    -- Bookmark properties
    bookmark_name VARCHAR(100),
    position_in_note INTEGER DEFAULT 0,
    context_text TEXT,
    
    -- Organization
    bookmark_group VARCHAR(50),
    sort_order INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_user_note_bookmark UNIQUE(user_id, note_id, position_in_note)
);

-- Note analytics and usage statistics
CREATE TABLE IF NOT EXISTS note_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    note_id UUID REFERENCES notes(id) ON DELETE CASCADE,
    date DATE DEFAULT CURRENT_DATE,
    
    -- Individual note metrics (when note_id is specified)
    view_count INTEGER DEFAULT 0,
    edit_count INTEGER DEFAULT 0,
    time_spent_minutes INTEGER DEFAULT 0,
    word_count_delta INTEGER DEFAULT 0,
    
    -- Daily aggregate metrics (when note_id is NULL)
    notes_created INTEGER DEFAULT 0,
    notes_updated INTEGER DEFAULT 0,
    notes_deleted INTEGER DEFAULT 0,
    total_words_written INTEGER DEFAULT 0,
    total_time_spent_minutes INTEGER DEFAULT 0,
    attachments_uploaded INTEGER DEFAULT 0,
    comments_added INTEGER DEFAULT 0,
    
    -- Engagement metrics
    notes_shared INTEGER DEFAULT 0,
    notes_favorited INTEGER DEFAULT 0,
    templates_used INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_user_note_date UNIQUE(user_id, note_id, date)
);

-- User notes preferences and settings
CREATE TABLE IF NOT EXISTS note_user_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    
    -- Display preferences
    default_view_mode VARCHAR(20) DEFAULT 'grid', -- grid, list, timeline
    default_sort_order VARCHAR(20) DEFAULT 'updated_desc',
    notes_per_page INTEGER DEFAULT 20,
    default_font_family VARCHAR(50) DEFAULT 'Inter',
    default_font_size INTEGER DEFAULT 14,
    
    -- Editor preferences
    auto_save_enabled BOOLEAN DEFAULT true,
    auto_save_interval INTEGER DEFAULT 30, -- seconds
    spell_check_enabled BOOLEAN DEFAULT true,
    markdown_enabled BOOLEAN DEFAULT true,
    rich_text_enabled BOOLEAN DEFAULT true,
    
    -- Privacy and security
    encryption_enabled BOOLEAN DEFAULT false,
    share_analytics_enabled BOOLEAN DEFAULT true,
    
    -- Backup and sync
    auto_backup_enabled BOOLEAN DEFAULT true,
    backup_frequency VARCHAR(20) DEFAULT 'daily',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_view_mode CHECK (default_view_mode IN ('grid', 'list', 'timeline')),
    CONSTRAINT valid_sort_order CHECK (default_sort_order IN ('created_asc', 'created_desc', 'updated_asc', 'updated_desc', 'title_asc', 'title_desc')),
    CONSTRAINT valid_notes_per_page CHECK (notes_per_page BETWEEN 10 AND 100),
    CONSTRAINT valid_font_size CHECK (default_font_size BETWEEN 10 AND 24),
    CONSTRAINT valid_auto_save_interval CHECK (auto_save_interval BETWEEN 10 AND 300),
    CONSTRAINT valid_backup_frequency CHECK (backup_frequency IN ('daily', 'weekly', 'monthly'))
);

-- Create indexes for performance optimization
CREATE INDEX IF NOT EXISTS idx_notes_user_id ON notes(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_user_updated ON notes(user_id, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_notes_user_created ON notes(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notes_user_category ON notes(user_id, category);
CREATE INDEX IF NOT EXISTS idx_notes_user_favorite ON notes(user_id, is_favorite) WHERE is_favorite = true;
CREATE INDEX IF NOT EXISTS idx_notes_user_pinned ON notes(user_id, is_pinned) WHERE is_pinned = true;
CREATE INDEX IF NOT EXISTS idx_notes_user_archived ON notes(user_id, is_archived);
CREATE INDEX IF NOT EXISTS idx_notes_user_deleted ON notes(user_id, is_deleted) WHERE is_deleted = true;
CREATE INDEX IF NOT EXISTS idx_notes_folder ON notes(folder_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notes_tags ON notes USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_notes_search ON notes USING GIN(search_vector);
CREATE INDEX IF NOT EXISTS idx_notes_shared ON notes(is_shared, created_at DESC) WHERE is_shared = true;

CREATE INDEX IF NOT EXISTS idx_note_folders_user_parent ON note_folders(user_id, parent_folder_id);
CREATE INDEX IF NOT EXISTS idx_note_folders_sort ON note_folders(user_id, sort_order);

CREATE INDEX IF NOT EXISTS idx_note_templates_user_public ON note_templates(user_id, is_public);
CREATE INDEX IF NOT EXISTS idx_note_templates_featured ON note_templates(is_featured, usage_count DESC) WHERE is_featured = true;

CREATE INDEX IF NOT EXISTS idx_note_shares_note ON note_shares(note_id, is_active);
CREATE INDEX IF NOT EXISTS idx_note_shares_user ON note_shares(shared_with, is_active);
CREATE INDEX IF NOT EXISTS idx_note_shares_token ON note_shares(share_token) WHERE share_token IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_note_comments_note ON note_comments(note_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_note_comments_user ON note_comments(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_note_comments_parent ON note_comments(parent_comment_id);

CREATE INDEX IF NOT EXISTS idx_note_revisions_note ON note_revisions(note_id, revision_number DESC);
CREATE INDEX IF NOT EXISTS idx_note_revisions_editor ON note_revisions(editor_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_note_tags_user ON note_tags(user_id, name);
CREATE INDEX IF NOT EXISTS idx_note_tags_usage ON note_tags(usage_count DESC);

CREATE INDEX IF NOT EXISTS idx_note_attachments_note ON note_attachments(note_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_note_attachments_user ON note_attachments(uploaded_by, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_note_attachments_type ON note_attachments(file_type, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_note_bookmarks_user ON note_bookmarks(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_note_bookmarks_note ON note_bookmarks(note_id, position_in_note);

CREATE INDEX IF NOT EXISTS idx_note_analytics_user_date ON note_analytics(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_note_analytics_note_date ON note_analytics(note_id, date DESC) WHERE note_id IS NOT NULL;
