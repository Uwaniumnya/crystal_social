-- Create support_requests table for user support tickets
CREATE TABLE IF NOT EXISTS public.support_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT NOT NULL,
    email TEXT,
    category TEXT NOT NULL CHECK (category IN ('Bug Report', 'Feature Request', 'General Question', 'Account Issue', 'Technical Problem', 'Feedback')),
    subject TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
    priority TEXT NOT NULL DEFAULT 'low' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    device_info JSONB,
    app_version TEXT,
    admin_response TEXT,
    admin_user_id UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- Add RLS (Row Level Security) policies
ALTER TABLE public.support_requests ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own support requests
CREATE POLICY "Users can view own support requests" ON public.support_requests
    FOR SELECT USING (auth.uid() = user_id);

-- Policy: Users can insert their own support requests
CREATE POLICY "Users can create support requests" ON public.support_requests
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own support requests (for adding more info)
CREATE POLICY "Users can update own support requests" ON public.support_requests
    FOR UPDATE USING (auth.uid() = user_id);

-- Policy: Admins can view all support requests (you'll need to define admin users)
-- For now, allowing specific user IDs - replace with your admin user ID
-- CREATE POLICY "Admins can view all support requests" ON public.support_requests
--     FOR ALL USING (auth.uid() IN ('your-admin-user-id-here'));

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_support_requests_user_id ON public.support_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_support_requests_status ON public.support_requests(status);
CREATE INDEX IF NOT EXISTS idx_support_requests_category ON public.support_requests(category);
CREATE INDEX IF NOT EXISTS idx_support_requests_priority ON public.support_requests(priority);
CREATE INDEX IF NOT EXISTS idx_support_requests_created_at ON public.support_requests(created_at);

-- Function to automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at
CREATE TRIGGER update_support_requests_updated_at 
    BEFORE UPDATE ON public.support_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Optional: Create a view for admins to easily see support request summaries
CREATE OR REPLACE VIEW public.support_requests_summary AS
SELECT 
    id,
    username,
    email,
    category,
    subject,
    status,
    priority,
    created_at,
    updated_at,
    CASE 
        WHEN created_at > now() - interval '1 hour' THEN 'New'
        WHEN created_at > now() - interval '1 day' THEN 'Recent'
        WHEN created_at > now() - interval '1 week' THEN 'This Week'
        ELSE 'Older'
    END as time_category,
    LENGTH(description) as description_length
FROM public.support_requests
ORDER BY 
    CASE priority 
        WHEN 'urgent' THEN 1
        WHEN 'high' THEN 2
        WHEN 'medium' THEN 3
        WHEN 'low' THEN 4
    END,
    created_at DESC;
