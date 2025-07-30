-- Content Moderation System
-- Handles content filtering, automated moderation, and admin content management

-- Content moderation rules
CREATE TABLE IF NOT EXISTS moderation_rules (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    rule_type TEXT NOT NULL CHECK (rule_type IN (
        'keyword_filter',
        'regex_pattern',
        'length_limit',
        'link_detection',
        'spam_detection',
        'ai_classification',
        'user_reports_threshold'
    )),
    content_types TEXT[] DEFAULT '{}', -- ['post', 'comment', 'message', 'profile']
    pattern TEXT, -- keyword, regex, or detection pattern
    action TEXT NOT NULL CHECK (action IN (
        'flag',
        'auto_hide',
        'auto_delete',
        'require_approval',
        'warn_user',
        'escalate'
    )),
    severity TEXT DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    is_active BOOLEAN DEFAULT true,
    auto_action BOOLEAN DEFAULT false,
    threshold_value INTEGER,
    config JSONB DEFAULT '{}',
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Content flagging and moderation queue
CREATE TABLE IF NOT EXISTS content_moderation_queue (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    content_type TEXT NOT NULL, -- 'post', 'comment', 'message', 'profile'
    content_id UUID NOT NULL,
    author_id UUID REFERENCES profiles(id),
    flag_type TEXT NOT NULL CHECK (flag_type IN (
        'inappropriate',
        'spam',
        'harassment',
        'violence',
        'hate_speech',
        'copyright',
        'fake_news',
        'adult_content',
        'other'
    )),
    flag_reason TEXT,
    auto_flagged BOOLEAN DEFAULT false,
    flagged_by_rule_id UUID REFERENCES moderation_rules(id),
    flagged_by_user_id UUID REFERENCES profiles(id),
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    status TEXT DEFAULT 'pending' CHECK (status IN (
        'pending',
        'under_review',
        'approved',
        'rejected',
        'escalated'
    )),
    moderator_id UUID REFERENCES profiles(id),
    moderator_action TEXT CHECK (moderator_action IN (
        'approve',
        'hide',
        'delete',
        'edit',
        'warn_user',
        'ban_user',
        'escalate'
    )),
    moderator_notes TEXT,
    content_snapshot JSONB, -- snapshot of content when flagged
    ai_confidence_score DECIMAL(3,2), -- 0.00 to 1.00
    ai_classification JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- Automated content analysis results
CREATE TABLE IF NOT EXISTS content_analysis (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    content_type TEXT NOT NULL,
    content_id UUID NOT NULL,
    analysis_type TEXT NOT NULL CHECK (analysis_type IN (
        'toxicity',
        'spam',
        'sentiment',
        'language_detection',
        'content_classification',
        'image_analysis',
        'link_analysis'
    )),
    confidence_score DECIMAL(3,2), -- 0.00 to 1.00
    classification JSONB,
    raw_response JSONB,
    processing_time_ms INTEGER,
    model_version TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Allow/block list management
CREATE TABLE IF NOT EXISTS moderation_lists (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    list_type TEXT NOT NULL,
    item_type TEXT NOT NULL,
    value TEXT NOT NULL,
    reason TEXT,
    is_active BOOLEAN DEFAULT true,
    added_by UUID REFERENCES profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    UNIQUE(list_type, item_type, value)
);

-- Add constraints after table creation to avoid syntax issues
ALTER TABLE moderation_lists ADD CONSTRAINT check_list_type 
    CHECK (list_type IN ('permitted', 'forbidden'));

ALTER TABLE moderation_lists ADD CONSTRAINT check_item_type 
    CHECK (item_type IN ('keyword', 'domain', 'url', 'email', 'ip_address', 'user_agent', 'phrase'));

-- Content appeal system
CREATE TABLE IF NOT EXISTS content_appeals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    moderation_queue_id UUID REFERENCES content_moderation_queue(id),
    user_id UUID REFERENCES profiles(id),
    appeal_reason TEXT NOT NULL,
    additional_info TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'under_review', 'upheld', 'overturned')),
    reviewed_by UUID REFERENCES profiles(id),
    review_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    reviewed_at TIMESTAMP WITH TIME ZONE
);

-- Moderation statistics and metrics
CREATE TABLE IF NOT EXISTS moderation_statistics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    date DATE DEFAULT CURRENT_DATE,
    total_content_flagged INTEGER DEFAULT 0,
    auto_flagged INTEGER DEFAULT 0,
    user_reported INTEGER DEFAULT 0,
    approved INTEGER DEFAULT 0,
    rejected INTEGER DEFAULT 0,
    deleted INTEGER DEFAULT 0,
    appeals_submitted INTEGER DEFAULT 0,
    appeals_upheld INTEGER DEFAULT 0,
    avg_resolution_time_minutes INTEGER DEFAULT 0,
    moderator_actions JSONB DEFAULT '{}',
    flag_types JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    UNIQUE(date)
);

-- Content tags for organization
CREATE TABLE IF NOT EXISTS content_tags (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    content_type TEXT NOT NULL,
    content_id UUID NOT NULL,
    tag_name TEXT NOT NULL,
    tag_value TEXT,
    tagged_by UUID REFERENCES profiles(id),
    confidence DECIMAL(3,2),
    is_auto_generated BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    UNIQUE(content_type, content_id, tag_name)
);

-- Trusted users who can help with moderation
CREATE TABLE IF NOT EXISTS community_moderators (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    permissions JSONB DEFAULT '{}',
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'revoked')),
    appointed_by UUID REFERENCES profiles(id),
    appointed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    actions_taken INTEGER DEFAULT 0,
    accuracy_score DECIMAL(3,2), -- based on admin review of their actions
    last_action_at TIMESTAMP WITH TIME ZONE
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_moderation_rules_rule_type ON moderation_rules(rule_type);
CREATE INDEX IF NOT EXISTS idx_moderation_rules_active ON moderation_rules(is_active);

CREATE INDEX IF NOT EXISTS idx_moderation_queue_content ON content_moderation_queue(content_type, content_id);
CREATE INDEX IF NOT EXISTS idx_moderation_queue_status ON content_moderation_queue(status);
CREATE INDEX IF NOT EXISTS idx_moderation_queue_priority ON content_moderation_queue(priority);
CREATE INDEX IF NOT EXISTS idx_moderation_queue_created_at ON content_moderation_queue(created_at);
CREATE INDEX IF NOT EXISTS idx_moderation_queue_moderator ON content_moderation_queue(moderator_id);
CREATE INDEX IF NOT EXISTS idx_moderation_queue_author ON content_moderation_queue(author_id);

CREATE INDEX IF NOT EXISTS idx_content_analysis_content ON content_analysis(content_type, content_id);
CREATE INDEX IF NOT EXISTS idx_content_analysis_type ON content_analysis(analysis_type);
CREATE INDEX IF NOT EXISTS idx_content_analysis_created_at ON content_analysis(created_at);

CREATE INDEX IF NOT EXISTS idx_moderation_lists_type_value ON moderation_lists(list_type, item_type, value);
CREATE INDEX IF NOT EXISTS idx_moderation_lists_active ON moderation_lists(is_active);

CREATE INDEX IF NOT EXISTS idx_content_appeals_moderation_queue ON content_appeals(moderation_queue_id);
CREATE INDEX IF NOT EXISTS idx_content_appeals_user ON content_appeals(user_id);
CREATE INDEX IF NOT EXISTS idx_content_appeals_status ON content_appeals(status);

CREATE INDEX IF NOT EXISTS idx_content_tags_content ON content_tags(content_type, content_id);
CREATE INDEX IF NOT EXISTS idx_content_tags_name ON content_tags(tag_name);

-- Enable RLS
ALTER TABLE moderation_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_moderation_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_analysis ENABLE ROW LEVEL SECURITY;
ALTER TABLE moderation_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_appeals ENABLE ROW LEVEL SECURITY;
ALTER TABLE moderation_statistics ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_moderators ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Admins and moderators can view moderation rules
CREATE POLICY "Moderators can view moderation rules" ON moderation_rules
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND (is_admin = true OR is_moderator = true)
    ));

-- Moderation queue - admins and moderators
CREATE POLICY "Moderators can view moderation queue" ON content_moderation_queue
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND (is_admin = true OR is_moderator = true)
    ));

CREATE POLICY "Moderators can update moderation queue" ON content_moderation_queue
    FOR UPDATE USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND (is_admin = true OR is_moderator = true)
    ));

-- Content analysis - admins and moderators can view
CREATE POLICY "Moderators can view content analysis" ON content_analysis
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND (is_admin = true OR is_moderator = true)
    ));

-- Appeals - users can view their own, moderators can view all
CREATE POLICY "Users can view own appeals" ON content_appeals
    FOR SELECT USING (user_id = auth.uid() OR EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND (is_admin = true OR is_moderator = true)
    ));

CREATE POLICY "Users can create appeals" ON content_appeals
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Other tables - admin/moderator only
CREATE POLICY "Moderators can view moderation lists" ON moderation_lists
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND (is_admin = true OR is_moderator = true)
    ));

CREATE POLICY "Moderators can view statistics" ON moderation_statistics
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND (is_admin = true OR is_moderator = true)
    ));

CREATE POLICY "Moderators can view tags" ON content_tags
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND (is_admin = true OR is_moderator = true)
    ));

-- Functions

-- Check content against moderation rules
CREATE OR REPLACE FUNCTION check_content_moderation(
    p_content_type TEXT,
    p_content_id UUID,
    p_content_text TEXT,
    p_author_id UUID
)
RETURNS JSONB AS $$
DECLARE
    rule_record RECORD;
    flagged_rules JSONB := '[]';
    highest_severity TEXT := 'low';
    should_auto_action BOOLEAN := false;
BEGIN
    -- Check against active moderation rules
    FOR rule_record IN 
        SELECT * FROM moderation_rules 
        WHERE is_active = true 
        AND (content_types = '{}' OR p_content_type = ANY(content_types))
    LOOP
        -- Simple keyword matching (can be enhanced with regex/AI)
        IF rule_record.rule_type = 'keyword_filter' AND 
           LOWER(p_content_text) LIKE '%' || LOWER(rule_record.pattern) || '%' THEN
            
            flagged_rules := flagged_rules || jsonb_build_object(
                'rule_id', rule_record.id,
                'rule_name', rule_record.name,
                'severity', rule_record.severity,
                'action', rule_record.action,
                'auto_action', rule_record.auto_action
            );
            
            -- Track highest severity
            IF rule_record.severity = 'critical' OR 
               (rule_record.severity = 'high' AND highest_severity != 'critical') OR
               (rule_record.severity = 'medium' AND highest_severity = 'low') THEN
                highest_severity := rule_record.severity;
            END IF;
            
            -- Check if auto action needed
            IF rule_record.auto_action THEN
                should_auto_action := true;
            END IF;
        END IF;
    END LOOP;
    
    -- If flagged, add to moderation queue
    IF jsonb_array_length(flagged_rules) > 0 THEN
        INSERT INTO content_moderation_queue (
            content_type, content_id, author_id, flag_type, flag_reason,
            auto_flagged, flagged_by_rule_id, priority, content_snapshot
        ) VALUES (
            p_content_type, p_content_id, p_author_id, 'inappropriate', 
            'Flagged by moderation rules',
            true, (flagged_rules->0->>'rule_id')::UUID,
            CASE highest_severity 
                WHEN 'critical' THEN 'urgent'
                WHEN 'high' THEN 'high'
                ELSE 'medium'
            END,
            jsonb_build_object('content_text', p_content_text, 'flagged_rules', flagged_rules)
        );
    END IF;
    
    RETURN jsonb_build_object(
        'flagged', jsonb_array_length(flagged_rules) > 0,
        'rules_triggered', flagged_rules,
        'highest_severity', highest_severity,
        'auto_action_required', should_auto_action
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Process moderation action
CREATE OR REPLACE FUNCTION process_moderation_action(
    p_queue_id UUID,
    p_moderator_id UUID,
    p_action TEXT,
    p_notes TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    queue_record RECORD;
BEGIN
    -- Get the moderation queue item
    SELECT * INTO queue_record FROM content_moderation_queue WHERE id = p_queue_id;
    
    IF NOT FOUND THEN
        RETURN false;
    END IF;
    
    -- Update the queue item
    UPDATE content_moderation_queue SET
        status = 'resolved',
        moderator_id = p_moderator_id,
        moderator_action = p_action,
        moderator_notes = p_notes,
        reviewed_at = NOW(),
        resolved_at = NOW()
    WHERE id = p_queue_id;
    
    -- Log the admin action
    PERFORM log_admin_action(
        p_moderator_id,
        'moderation_action',
        'content_moderation',
        queue_record.content_type,
        queue_record.content_id,
        NULL,
        jsonb_build_object(
            'action', p_action,
            'queue_id', p_queue_id,
            'original_flag_type', queue_record.flag_type
        )
    );
    
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update moderation statistics
CREATE OR REPLACE FUNCTION update_moderation_statistics()
RETURNS VOID AS $$
DECLARE
    today DATE := CURRENT_DATE;
    stats_record RECORD;
BEGIN
    SELECT 
        COUNT(*) FILTER (WHERE DATE(created_at) = today) as total_flagged,
        COUNT(*) FILTER (WHERE DATE(created_at) = today AND auto_flagged = true) as auto_flagged,
        COUNT(*) FILTER (WHERE DATE(created_at) = today AND flagged_by_user_id IS NOT NULL) as user_reported,
        COUNT(*) FILTER (WHERE DATE(resolved_at) = today AND moderator_action = 'approve') as approved,
        COUNT(*) FILTER (WHERE DATE(resolved_at) = today AND moderator_action IN ('hide', 'delete')) as rejected,
        COUNT(*) FILTER (WHERE DATE(resolved_at) = today AND moderator_action = 'delete') as deleted,
        EXTRACT(EPOCH FROM AVG(resolved_at - created_at))/60 as avg_resolution_minutes
    INTO stats_record
    FROM content_moderation_queue;
    
    INSERT INTO moderation_statistics (
        date, total_content_flagged, auto_flagged, user_reported,
        approved, rejected, deleted, avg_resolution_time_minutes
    ) VALUES (
        today, stats_record.total_flagged, stats_record.auto_flagged, stats_record.user_reported,
        stats_record.approved, stats_record.rejected, stats_record.deleted, 
        COALESCE(stats_record.avg_resolution_minutes::INTEGER, 0)
    )
    ON CONFLICT (date) DO UPDATE SET
        total_content_flagged = EXCLUDED.total_content_flagged,
        auto_flagged = EXCLUDED.auto_flagged,
        user_reported = EXCLUDED.user_reported,
        approved = EXCLUDED.approved,
        rejected = EXCLUDED.rejected,
        deleted = EXCLUDED.deleted,
        avg_resolution_time_minutes = EXCLUDED.avg_resolution_time_minutes;
END;
$$ LANGUAGE plpgsql;

-- Insert default moderation rules
INSERT INTO moderation_rules (name, description, rule_type, pattern, action, severity, auto_action) VALUES
('Spam Keywords', 'Common spam keywords', 'keyword_filter', 'free money|click here|limited time', 'flag', 'medium', false),
('Harassment', 'Harassment and bullying terms', 'keyword_filter', 'hate|die|kill yourself', 'auto_hide', 'high', true),
('Adult Content', 'Adult content keywords', 'keyword_filter', 'explicit content patterns', 'require_approval', 'medium', false)
ON CONFLICT DO NOTHING;
