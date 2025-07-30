-- Create Glimmer Wall tables
-- Posts table for storing glimmer posts
CREATE TABLE glimmer_posts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    image_url TEXT NOT NULL,
    image_path TEXT, -- for storage reference
    category TEXT NOT NULL DEFAULT 'Art',
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    tags TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Likes table for post likes
CREATE TABLE glimmer_likes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    post_id UUID REFERENCES glimmer_posts(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(post_id, user_id)
);

-- Comments table for post comments
CREATE TABLE glimmer_comments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    post_id UUID REFERENCES glimmer_posts(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_glimmer_posts_user_id ON glimmer_posts(user_id);
CREATE INDEX idx_glimmer_posts_category ON glimmer_posts(category);
CREATE INDEX idx_glimmer_posts_created_at ON glimmer_posts(created_at DESC);
CREATE INDEX idx_glimmer_likes_post_id ON glimmer_likes(post_id);
CREATE INDEX idx_glimmer_likes_user_id ON glimmer_likes(user_id);
CREATE INDEX idx_glimmer_comments_post_id ON glimmer_comments(post_id);

-- Enable Row Level Security (RLS)
ALTER TABLE glimmer_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE glimmer_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE glimmer_comments ENABLE ROW LEVEL SECURITY;

-- Create policies for glimmer_posts
CREATE POLICY "Public can view glimmer posts" ON glimmer_posts
    FOR SELECT USING (true);

CREATE POLICY "Users can insert their own glimmer posts" ON glimmer_posts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own glimmer posts" ON glimmer_posts
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own glimmer posts" ON glimmer_posts
    FOR DELETE USING (auth.uid() = user_id);

-- Create policies for glimmer_likes
CREATE POLICY "Users can view all likes" ON glimmer_likes
    FOR SELECT USING (true);

CREATE POLICY "Users can insert their own likes" ON glimmer_likes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own likes" ON glimmer_likes
    FOR DELETE USING (auth.uid() = user_id);

-- Create policies for glimmer_comments
CREATE POLICY "Users can view all comments" ON glimmer_comments
    FOR SELECT USING (true);

CREATE POLICY "Users can insert their own comments" ON glimmer_comments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own comments" ON glimmer_comments
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own comments" ON glimmer_comments
    FOR DELETE USING (auth.uid() = user_id);
