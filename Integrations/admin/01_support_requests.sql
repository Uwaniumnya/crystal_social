-- Support Requests System
-- Handles user support tickets, bug reports, and feature requests

-- Main support requests table
CREATE TABLE IF NOT EXISTS support_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    subject TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN (
        'Bug Report',
        'Feature Request', 
        'General Question',
        'Account Issue',
        'Technical Problem',
        'Feedback',
        'Other'
    )),
    priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('urgent', 'high', 'medium', 'low')),
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
    admin_response TEXT,
    admin_id UUID REFERENCES profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    resolved_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}',
    attachments JSONB DEFAULT '[]'
);

-- Support request updates/history
CREATE TABLE IF NOT EXISTS support_request_updates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    request_id UUID REFERENCES support_requests(id) ON DELETE CASCADE,
    admin_id UUID REFERENCES profiles(id),
    update_type TEXT NOT NULL CHECK (update_type IN (
        'status_change',
        'priority_change',
        'category_change',
        'admin_response',
        'internal_note',
        'assignment'
    )),
    previous_value TEXT,
    new_value TEXT,
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Support categories configuration
CREATE TABLE IF NOT EXISTS support_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    color TEXT DEFAULT '#3B82F6',
    icon TEXT DEFAULT 'help',
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    auto_assign_to UUID REFERENCES profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Insert default categories
INSERT INTO support_categories (name, description, color, icon) VALUES
('Bug Report', 'Technical issues and bugs', '#EF4444', 'bug_report'),
('Feature Request', 'New feature suggestions', '#10B981', 'lightbulb'),
('General Question', 'General inquiries and questions', '#3B82F6', 'help'),
('Account Issue', 'Account-related problems', '#F59E0B', 'account_circle'),
('Technical Problem', 'Technical difficulties', '#EF4444', 'build'),
('Feedback', 'User feedback and suggestions', '#8B5CF6', 'feedback')
ON CONFLICT (name) DO NOTHING;

-- Support request attachments
CREATE TABLE IF NOT EXISTS support_attachments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    request_id UUID REFERENCES support_requests(id) ON DELETE CASCADE,
    filename TEXT NOT NULL,
    file_url TEXT NOT NULL,
    file_size BIGINT,
    mime_type TEXT,
    uploaded_by UUID REFERENCES profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Support FAQ
CREATE TABLE IF NOT EXISTS support_faq (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    category_id UUID REFERENCES support_categories(id),
    tags TEXT[] DEFAULT '{}',
    is_published BOOLEAN DEFAULT false,
    view_count INTEGER DEFAULT 0,
    helpful_count INTEGER DEFAULT 0,
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_support_requests_user_id ON support_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_support_requests_status ON support_requests(status);
CREATE INDEX IF NOT EXISTS idx_support_requests_priority ON support_requests(priority);
CREATE INDEX IF NOT EXISTS idx_support_requests_category ON support_requests(category);
CREATE INDEX IF NOT EXISTS idx_support_requests_created_at ON support_requests(created_at);
CREATE INDEX IF NOT EXISTS idx_support_requests_admin_id ON support_requests(admin_id);

CREATE INDEX IF NOT EXISTS idx_support_request_updates_request_id ON support_request_updates(request_id);
CREATE INDEX IF NOT EXISTS idx_support_request_updates_created_at ON support_request_updates(created_at);

CREATE INDEX IF NOT EXISTS idx_support_attachments_request_id ON support_attachments(request_id);

-- Enable RLS
ALTER TABLE support_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_request_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_faq ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Support requests - users can see their own, admins can see all
CREATE POLICY "Users can view own support requests" ON support_requests
    FOR SELECT USING (auth.uid() = user_id OR EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

CREATE POLICY "Users can create support requests" ON support_requests
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own support requests" ON support_requests
    FOR UPDATE USING (auth.uid() = user_id OR EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

-- Admins only for updates
CREATE POLICY "Admins can update any support request" ON support_request_updates
    FOR ALL USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

-- Categories are public readable, admin writable
CREATE POLICY "Anyone can view support categories" ON support_categories
    FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage support categories" ON support_categories
    FOR ALL USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

-- Attachments follow same rules as requests
CREATE POLICY "Users can view own attachments" ON support_attachments
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM support_requests 
        WHERE id = request_id AND (user_id = auth.uid() OR EXISTS (
            SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
        ))
    ));

-- FAQ is public readable
CREATE POLICY "Anyone can view published FAQ" ON support_faq
    FOR SELECT USING (is_published = true);

CREATE POLICY "Admins can manage FAQ" ON support_faq
    FOR ALL USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
    ));

-- Functions

-- Update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_support_request_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc'::text, NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for updated_at
CREATE TRIGGER update_support_requests_updated_at
    BEFORE UPDATE ON support_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_support_request_updated_at();

-- Function to log support request changes
CREATE OR REPLACE FUNCTION log_support_request_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Log status changes
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO support_request_updates (request_id, admin_id, update_type, previous_value, new_value)
        VALUES (NEW.id, auth.uid(), 'status_change', OLD.status, NEW.status);
    END IF;
    
    -- Log priority changes
    IF OLD.priority IS DISTINCT FROM NEW.priority THEN
        INSERT INTO support_request_updates (request_id, admin_id, update_type, previous_value, new_value)
        VALUES (NEW.id, auth.uid(), 'priority_change', OLD.priority, NEW.priority);
    END IF;
    
    -- Log admin responses
    IF OLD.admin_response IS DISTINCT FROM NEW.admin_response AND NEW.admin_response IS NOT NULL THEN
        INSERT INTO support_request_updates (request_id, admin_id, update_type, new_value)
        VALUES (NEW.id, auth.uid(), 'admin_response', NEW.admin_response);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for logging changes
CREATE TRIGGER log_support_request_changes
    AFTER UPDATE ON support_requests
    FOR EACH ROW
    EXECUTE FUNCTION log_support_request_change();
