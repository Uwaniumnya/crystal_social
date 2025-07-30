-- =====================================================
-- CRYSTAL SOCIAL - CHAT SYSTEM TABLES
-- =====================================================
-- Core tables for comprehensive chat functionality
-- Includes: Messages, Chats, Typing Status, Reactions, and More
-- =====================================================

-- Chat rooms/conversations table
CREATE TABLE IF NOT EXISTS chats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255),
    description TEXT,
    chat_type VARCHAR(50) DEFAULT 'direct' CHECK (chat_type IN ('direct', 'group', 'channel')),
    is_group BOOLEAN DEFAULT false,
    is_private BOOLEAN DEFAULT true,
    max_participants INTEGER DEFAULT 2,
    background_url TEXT,
    theme VARCHAR(50) DEFAULT 'classic',
    created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    last_message_at TIMESTAMP WITH TIME ZONE,
    message_count INTEGER DEFAULT 0,
    encryption_enabled BOOLEAN DEFAULT false,
    auto_delete_messages_after INTERVAL,
    settings JSONB DEFAULT '{}'::jsonb
);

-- Chat participants/members
CREATE TABLE IF NOT EXISTS chat_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    role VARCHAR(50) DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'moderator', 'member')),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    left_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    is_muted BOOLEAN DEFAULT false,
    is_pinned BOOLEAN DEFAULT false,
    last_read_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notification_settings JSONB DEFAULT '{
        "sound": true,
        "vibration": true,
        "preview": true,
        "mentions_only": false
    }'::jsonb,
    custom_nickname VARCHAR(100),
    permissions JSONB DEFAULT '{
        "send_messages": true,
        "send_media": true,
        "add_reactions": true,
        "mention_all": false
    }'::jsonb,
    UNIQUE(chat_id, user_id)
);

-- Core messages table with comprehensive features
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    content TEXT,
    message_type VARCHAR(50) DEFAULT 'text' CHECK (message_type IN (
        'text', 'image', 'video', 'audio', 'file', 'sticker', 
        'gif', 'location', 'contact', 'poll', 'butterfly', 'system'
    )),
    
    -- Media and file URLs
    image_url TEXT,
    video_url TEXT,
    audio_url TEXT,
    file_url TEXT,
    sticker_url TEXT,
    gif_url TEXT,
    
    -- Message metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    edited_at TIMESTAMP WITH TIME ZONE,
    is_edited BOOLEAN DEFAULT false,
    is_deleted BOOLEAN DEFAULT false,
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    -- Message status and delivery
    status VARCHAR(50) DEFAULT 'sent' CHECK (status IN ('sending', 'sent', 'delivered', 'read', 'failed')),
    delivered_at TIMESTAMP WITH TIME ZONE,
    read_at TIMESTAMP WITH TIME ZONE,
    
    -- Reply and threading
    reply_to_message_id UUID REFERENCES messages(id) ON DELETE SET NULL,
    reply_to_content TEXT,
    reply_to_username VARCHAR(255),
    thread_id UUID,
    
    -- Special features
    is_forwarded BOOLEAN DEFAULT false,
    forward_count INTEGER DEFAULT 0,
    is_important BOOLEAN DEFAULT false,
    is_secret BOOLEAN DEFAULT false,
    expires_at TIMESTAMP WITH TIME ZONE,
    
    -- Rich content
    mentions TEXT[], -- Array of mentioned usernames
    hashtags TEXT[], -- Array of hashtags
    reactions JSONB DEFAULT '{}'::jsonb,
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Visual effects
    effect VARCHAR(50),
    mood VARCHAR(50),
    aura_color VARCHAR(7), -- Hex color code
    
    -- Location data (for location messages)
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    location_name VARCHAR(255),
    
    -- Poll data (for poll messages)
    poll_question TEXT,
    poll_options JSONB,
    poll_results JSONB DEFAULT '{}'::jsonb,
    poll_expires_at TIMESTAMP WITH TIME ZONE,
    poll_multiple_choice BOOLEAN DEFAULT false,
    
    -- Contact data (for contact messages)
    contact_name VARCHAR(255),
    contact_phone VARCHAR(50),
    contact_email VARCHAR(255),
    
    -- File metadata
    file_name VARCHAR(255),
    file_size BIGINT,
    file_type VARCHAR(100),
    
    -- Search optimization
    search_vector tsvector
);

-- Message reactions table for detailed reaction tracking
CREATE TABLE IF NOT EXISTS message_reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    reaction_type VARCHAR(100) NOT NULL, -- emoji or reaction name
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(message_id, user_id, reaction_type)
);

-- Message delivery status for group chats
CREATE TABLE IF NOT EXISTS message_delivery_status (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'sent' CHECK (status IN ('sent', 'delivered', 'read')),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(message_id, user_id)
);

-- Typing status for real-time indicators
CREATE TABLE IF NOT EXISTS typing_status (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    status INTEGER DEFAULT 0 CHECK (status IN (0, 1, 2, 3)), -- 0=none, 1=typing, 2=recording, 3=thinking
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '10 seconds'),
    UNIQUE(chat_id, user_id)
);

-- Chat settings per user
CREATE TABLE IF NOT EXISTS chat_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
    theme VARCHAR(50) DEFAULT 'classic',
    background_url TEXT,
    font_size DECIMAL(3,1) DEFAULT 16.0,
    enable_effects BOOLEAN DEFAULT true,
    enable_sounds BOOLEAN DEFAULT true,
    notification_sound VARCHAR(255),
    custom_settings JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, chat_id)
);

-- Voice/Video calls table
CREATE TABLE IF NOT EXISTS calls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
    caller_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    receiver_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    call_type VARCHAR(20) DEFAULT 'audio' CHECK (call_type IN ('audio', 'video')),
    channel_id VARCHAR(255) UNIQUE NOT NULL,
    is_video BOOLEAN DEFAULT false,
    
    -- Call status
    status VARCHAR(50) DEFAULT 'calling' CHECK (status IN ('calling', 'ringing', 'accepted', 'rejected', 'ended', 'missed')),
    accepted BOOLEAN DEFAULT false,
    ended BOOLEAN DEFAULT false,
    
    -- Timing
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    answered_at TIMESTAMP WITH TIME ZONE,
    ended_at TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER DEFAULT 0,
    
    -- Quality metrics
    quality_rating INTEGER CHECK (quality_rating BETWEEN 1 AND 5),
    connection_quality VARCHAR(20) CHECK (connection_quality IN ('poor', 'fair', 'good', 'excellent')),
    
    -- Additional data
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Custom ringtones per contact
CREATE TABLE IF NOT EXISTS user_ringtones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    sound VARCHAR(255) NOT NULL, -- filename in notification_sounds folder
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(owner_id, sender_id)
);

-- Message drafts (auto-save feature)
CREATE TABLE IF NOT EXISTS message_drafts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT,
    reply_to_message_id UUID REFERENCES messages(id) ON DELETE SET NULL,
    attachments JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(chat_id, user_id)
);

-- Shared media index for quick access
CREATE TABLE IF NOT EXISTS shared_media (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
    message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    media_type VARCHAR(50) NOT NULL CHECK (media_type IN ('image', 'video', 'audio', 'file', 'gif')),
    media_url TEXT NOT NULL,
    file_name VARCHAR(255),
    file_size BIGINT,
    thumbnail_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Chat analytics for insights
CREATE TABLE IF NOT EXISTS chat_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    date DATE DEFAULT CURRENT_DATE,
    message_count INTEGER DEFAULT 0,
    media_shared INTEGER DEFAULT 0,
    reactions_given INTEGER DEFAULT 0,
    reactions_received INTEGER DEFAULT 0,
    call_duration_seconds INTEGER DEFAULT 0,
    time_spent_seconds INTEGER DEFAULT 0,
    UNIQUE(chat_id, user_id, date)
);

-- =====================================================
-- INDEXES FOR PERFORMANCE OPTIMIZATION
-- =====================================================

-- Primary performance indexes
CREATE INDEX IF NOT EXISTS idx_messages_chat_created ON messages(chat_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_type ON messages(message_type);
CREATE INDEX IF NOT EXISTS idx_messages_status ON messages(status);
CREATE INDEX IF NOT EXISTS idx_messages_reply ON messages(reply_to_message_id);

-- Chat participant indexes
CREATE INDEX IF NOT EXISTS idx_chat_participants_user ON chat_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_participants_active ON chat_participants(chat_id, is_active);

-- Search optimization
CREATE INDEX IF NOT EXISTS idx_messages_search ON messages USING gin(search_vector);
CREATE INDEX IF NOT EXISTS idx_messages_content_search ON messages USING gin(to_tsvector('english', content));

-- Delivery and reactions
CREATE INDEX IF NOT EXISTS idx_message_reactions_message ON message_reactions(message_id);
CREATE INDEX IF NOT EXISTS idx_message_delivery_message ON message_delivery_status(message_id);

-- Typing status optimization
CREATE INDEX IF NOT EXISTS idx_typing_status_chat ON typing_status(chat_id, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_typing_status_expires ON typing_status(expires_at);

-- Call indexes
CREATE INDEX IF NOT EXISTS idx_calls_participants ON calls(caller_id, receiver_id);
CREATE INDEX IF NOT EXISTS idx_calls_chat ON calls(chat_id, created_at DESC);

-- Media and analytics
CREATE INDEX IF NOT EXISTS idx_shared_media_chat ON shared_media(chat_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_analytics_date ON chat_analytics(date, chat_id);

-- Cleanup expired data
CREATE INDEX IF NOT EXISTS idx_messages_expires ON messages(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_typing_expires ON typing_status(expires_at);

-- =====================================================
-- COMMENTS AND DOCUMENTATION
-- =====================================================

COMMENT ON TABLE chats IS 'Core chat rooms and conversations';
COMMENT ON TABLE chat_participants IS 'User membership in chats with roles and settings';
COMMENT ON TABLE messages IS 'All chat messages with comprehensive features and metadata';
COMMENT ON TABLE message_reactions IS 'Individual reactions to messages';
COMMENT ON TABLE message_delivery_status IS 'Delivery tracking for group messages';
COMMENT ON TABLE typing_status IS 'Real-time typing indicators';
COMMENT ON TABLE chat_settings IS 'Per-user chat customization settings';
COMMENT ON TABLE calls IS 'Voice and video call records';
COMMENT ON TABLE user_ringtones IS 'Custom ringtones per contact';
COMMENT ON TABLE message_drafts IS 'Auto-saved message drafts';
COMMENT ON TABLE shared_media IS 'Index of shared media for quick access';
COMMENT ON TABLE chat_analytics IS 'Chat usage analytics and insights';
