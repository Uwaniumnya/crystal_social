-- =====================================================
-- CRYSTAL SOCIAL - GROUPS SYSTEM TABLES
-- =====================================================
-- Core database schema for comprehensive group management
-- =====================================================

-- Core Groups table (extends existing chats table for groups)
CREATE TABLE IF NOT EXISTS group_details (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    
    -- Group metadata
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    emoji VARCHAR(10) DEFAULT '💬',
    banner_url TEXT,
    icon_url TEXT,
    
    -- Group settings
    is_public BOOLEAN DEFAULT false,
    is_discoverable BOOLEAN DEFAULT false,
    allow_member_invites BOOLEAN DEFAULT true,
    auto_delete_messages_days INTEGER DEFAULT 0,
    max_members INTEGER DEFAULT 256,
    
    -- Group categorization
    category VARCHAR(50) DEFAULT 'general',
    tags TEXT[] DEFAULT '{}',
    
    -- Analytics
    total_messages INTEGER DEFAULT 0,
    active_members_count INTEGER DEFAULT 0,
    last_activity_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT group_details_chat_id_unique UNIQUE(chat_id),
    CONSTRAINT valid_max_members CHECK (max_members > 0 AND max_members <= 1000),
    CONSTRAINT valid_category CHECK (category IN ('general', 'gaming', 'study', 'work', 'hobby', 'social', 'creative', 'sports', 'tech', 'other'))
);

-- Group Members with roles and permissions
CREATE TABLE IF NOT EXISTS group_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES group_details(chat_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Role management
    role VARCHAR(20) DEFAULT 'member',
    permissions JSONB DEFAULT '{
        "can_send_messages": true,
        "can_send_media": true,
        "can_invite_members": false,
        "can_remove_members": false,
        "can_edit_group": false,
        "can_manage_roles": false,
        "can_pin_messages": false,
        "can_delete_messages": false
    }'::jsonb,
    
    -- Member status
    is_active BOOLEAN DEFAULT true,
    is_muted BOOLEAN DEFAULT false,
    is_banned BOOLEAN DEFAULT false,
    muted_until TIMESTAMPTZ,
    ban_reason TEXT,
    
    -- Activity tracking
    last_seen_at TIMESTAMPTZ DEFAULT NOW(),
    message_count INTEGER DEFAULT 0,
    reaction_count INTEGER DEFAULT 0,
    
    -- Invitation details
    invited_by UUID REFERENCES auth.users(id),
    invited_at TIMESTAMPTZ DEFAULT NOW(),
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    left_at TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT group_members_unique UNIQUE(group_id, user_id),
    CONSTRAINT valid_role CHECK (role IN ('owner', 'admin', 'moderator', 'member', 'guest')),
    CONSTRAINT valid_mute_time CHECK (muted_until IS NULL OR muted_until > NOW())
);

-- Group invitations and requests
CREATE TABLE IF NOT EXISTS group_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES group_details(chat_id) ON DELETE CASCADE,
    inviter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    invitee_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Invitation details
    invitation_type VARCHAR(20) DEFAULT 'direct',
    invitation_code VARCHAR(50) UNIQUE,
    message TEXT,
    
    -- Status and expiry
    status VARCHAR(20) DEFAULT 'pending',
    expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '7 days',
    max_uses INTEGER DEFAULT 1,
    current_uses INTEGER DEFAULT 0,
    
    -- Response details
    responded_at TIMESTAMPTZ,
    response_message TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_invitation_type CHECK (invitation_type IN ('direct', 'link', 'public')),
    CONSTRAINT valid_status CHECK (status IN ('pending', 'accepted', 'declined', 'expired', 'cancelled')),
    CONSTRAINT valid_max_uses CHECK (max_uses > 0 AND max_uses <= 1000)
);

-- Group announcements and pinned messages
CREATE TABLE IF NOT EXISTS group_announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES group_details(chat_id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
    
    -- Announcement content
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    announcement_type VARCHAR(20) DEFAULT 'general',
    priority VARCHAR(10) DEFAULT 'normal',
    
    -- Display settings
    is_pinned BOOLEAN DEFAULT true,
    show_notification BOOLEAN DEFAULT true,
    background_color VARCHAR(7) DEFAULT '#e3f2fd',
    
    -- Scheduling
    scheduled_at TIMESTAMPTZ,
    published_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    
    -- Analytics
    view_count INTEGER DEFAULT 0,
    reaction_count INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_announcement_type CHECK (announcement_type IN ('general', 'event', 'rule', 'update', 'welcome')),
    CONSTRAINT valid_priority CHECK (priority IN ('low', 'normal', 'high', 'urgent'))
);

-- Group events and activities
CREATE TABLE IF NOT EXISTS group_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES group_details(chat_id) ON DELETE CASCADE,
    organizer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Event details
    title VARCHAR(200) NOT NULL,
    description TEXT,
    event_type VARCHAR(30) DEFAULT 'meetup',
    location TEXT,
    virtual_link TEXT,
    
    -- Timing
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    timezone VARCHAR(50) DEFAULT 'UTC',
    
    -- Settings
    max_attendees INTEGER,
    is_recurring BOOLEAN DEFAULT false,
    recurrence_pattern JSONB,
    requires_approval BOOLEAN DEFAULT false,
    
    -- Status
    status VARCHAR(20) DEFAULT 'scheduled',
    cancellation_reason TEXT,
    
    -- Analytics
    attendee_count INTEGER DEFAULT 0,
    interested_count INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_event_type CHECK (event_type IN ('meetup', 'gaming', 'study', 'social', 'workshop', 'discussion', 'other')),
    CONSTRAINT valid_status CHECK (status IN ('scheduled', 'ongoing', 'completed', 'cancelled', 'postponed')),
    CONSTRAINT valid_times CHECK (end_time IS NULL OR end_time > start_time)
);

-- Group event attendees
CREATE TABLE IF NOT EXISTS group_event_attendees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES group_events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Attendance status
    status VARCHAR(20) DEFAULT 'interested',
    response_message TEXT,
    
    -- Check-in details
    checked_in_at TIMESTAMPTZ,
    checked_out_at TIMESTAMPTZ,
    attendance_duration INTEGER, -- in minutes
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT event_attendees_unique UNIQUE(event_id, user_id),
    CONSTRAINT valid_attendance_status CHECK (status IN ('interested', 'attending', 'maybe', 'not_attending', 'attended'))
);

-- Group media and file sharing
CREATE TABLE IF NOT EXISTS group_media (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES group_details(chat_id) ON DELETE CASCADE,
    uploader_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
    
    -- File details
    filename VARCHAR(255) NOT NULL,
    original_filename VARCHAR(255),
    file_type VARCHAR(50) NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type VARCHAR(100),
    
    -- Storage details
    storage_bucket VARCHAR(100) NOT NULL,
    storage_path TEXT NOT NULL,
    file_url TEXT NOT NULL,
    thumbnail_url TEXT,
    
    -- Media metadata
    width INTEGER,
    height INTEGER,
    duration INTEGER, -- for videos/audio in seconds
    metadata JSONB DEFAULT '{}',
    
    -- Analytics
    download_count INTEGER DEFAULT 0,
    view_count INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_file_size CHECK (file_size > 0 AND file_size <= 104857600) -- 100MB limit
);

-- Group message reactions and engagement
CREATE TABLE IF NOT EXISTS group_message_reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    group_id UUID NOT NULL REFERENCES group_details(chat_id) ON DELETE CASCADE,
    
    -- Reaction details
    emoji VARCHAR(10) NOT NULL,
    reaction_type VARCHAR(20) DEFAULT 'emoji',
    custom_reaction_url TEXT,
    
    -- Analytics
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT group_message_reactions_unique UNIQUE(message_id, user_id, emoji),
    CONSTRAINT valid_reaction_type CHECK (reaction_type IN ('emoji', 'custom', 'animated'))
);

-- Group rules and moderation
CREATE TABLE IF NOT EXISTS group_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES group_details(chat_id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Rule details
    title VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    rule_number INTEGER NOT NULL,
    category VARCHAR(30) DEFAULT 'general',
    
    -- Enforcement
    is_active BOOLEAN DEFAULT true,
    violation_action VARCHAR(20) DEFAULT 'warn',
    auto_enforce BOOLEAN DEFAULT false,
    
    -- Analytics
    violation_count INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT group_rules_unique UNIQUE(group_id, rule_number),
    CONSTRAINT valid_violation_action CHECK (violation_action IN ('warn', 'mute', 'kick', 'ban', 'delete_message'))
);

-- Group moderation actions and logs
CREATE TABLE IF NOT EXISTS group_moderation_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES group_details(chat_id) ON DELETE CASCADE,
    moderator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    target_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
    
    -- Action details
    action_type VARCHAR(30) NOT NULL,
    reason TEXT,
    rule_violated UUID REFERENCES group_rules(id),
    
    -- Action metadata
    duration_minutes INTEGER, -- for temporary actions
    action_data JSONB DEFAULT '{}',
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    reverted_at TIMESTAMPTZ,
    reverted_by UUID REFERENCES auth.users(id),
    revert_reason TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_action_type CHECK (action_type IN ('warn', 'mute', 'unmute', 'kick', 'ban', 'unban', 'delete_message', 'pin_message', 'unpin_message', 'edit_permissions'))
);

-- Group analytics and statistics
CREATE TABLE IF NOT EXISTS group_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES group_details(chat_id) ON DELETE CASCADE,
    date DATE DEFAULT CURRENT_DATE,
    
    -- Activity metrics
    messages_sent INTEGER DEFAULT 0,
    unique_active_members INTEGER DEFAULT 0,
    new_members INTEGER DEFAULT 0,
    members_left INTEGER DEFAULT 0,
    
    -- Engagement metrics
    reactions_given INTEGER DEFAULT 0,
    media_shared INTEGER DEFAULT 0,
    events_created INTEGER DEFAULT 0,
    announcements_made INTEGER DEFAULT 0,
    
    -- Moderation metrics
    warnings_issued INTEGER DEFAULT 0,
    members_muted INTEGER DEFAULT 0,
    members_kicked INTEGER DEFAULT 0,
    members_banned INTEGER DEFAULT 0,
    
    -- Growth metrics
    total_members INTEGER DEFAULT 0,
    active_members_7d INTEGER DEFAULT 0,
    retention_rate DECIMAL(5,2) DEFAULT 0.00,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT group_analytics_unique UNIQUE(group_id, date)
);

-- Create indexes for performance optimization
CREATE INDEX IF NOT EXISTS idx_group_details_chat_id ON group_details(chat_id);
CREATE INDEX IF NOT EXISTS idx_group_details_public_discoverable ON group_details(is_public, is_discoverable) WHERE is_public = true;
CREATE INDEX IF NOT EXISTS idx_group_details_category ON group_details(category);
CREATE INDEX IF NOT EXISTS idx_group_details_activity ON group_details(last_activity_at DESC);

CREATE INDEX IF NOT EXISTS idx_group_members_group_user ON group_members(group_id, user_id);
CREATE INDEX IF NOT EXISTS idx_group_members_role ON group_members(group_id, role);
CREATE INDEX IF NOT EXISTS idx_group_members_active ON group_members(group_id, is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_group_members_last_seen ON group_members(last_seen_at DESC);

CREATE INDEX IF NOT EXISTS idx_group_invitations_group ON group_invitations(group_id, status);
CREATE INDEX IF NOT EXISTS idx_group_invitations_invitee ON group_invitations(invitee_id, status);
CREATE INDEX IF NOT EXISTS idx_group_invitations_code ON group_invitations(invitation_code) WHERE invitation_code IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_group_invitations_expires ON group_invitations(expires_at) WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_group_announcements_group ON group_announcements(group_id, is_pinned, published_at DESC);
CREATE INDEX IF NOT EXISTS idx_group_announcements_priority ON group_announcements(priority, published_at DESC);

CREATE INDEX IF NOT EXISTS idx_group_events_group_time ON group_events(group_id, start_time);
CREATE INDEX IF NOT EXISTS idx_group_events_status ON group_events(status, start_time);
CREATE INDEX IF NOT EXISTS idx_group_events_upcoming ON group_events(start_time) WHERE status = 'scheduled';

CREATE INDEX IF NOT EXISTS idx_group_event_attendees_event ON group_event_attendees(event_id, status);
CREATE INDEX IF NOT EXISTS idx_group_event_attendees_user ON group_event_attendees(user_id, status);

CREATE INDEX IF NOT EXISTS idx_group_media_group_type ON group_media(group_id, file_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_group_media_uploader ON group_media(uploader_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_group_message_reactions_message ON group_message_reactions(message_id, emoji);
CREATE INDEX IF NOT EXISTS idx_group_message_reactions_user ON group_message_reactions(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_group_rules_group_active ON group_rules(group_id, is_active, rule_number);

CREATE INDEX IF NOT EXISTS idx_group_moderation_logs_group ON group_moderation_logs(group_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_group_moderation_logs_target ON group_moderation_logs(target_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_group_moderation_logs_active ON group_moderation_logs(is_active, created_at DESC) WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_group_analytics_group_date ON group_analytics(group_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_group_analytics_recent ON group_analytics(date DESC);
