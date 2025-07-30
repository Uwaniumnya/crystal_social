-- Create view for glimmer posts with user info and stats
CREATE OR REPLACE VIEW glimmer_posts_with_stats AS
SELECT 
    p.id,
    p.title,
    p.description,
    p.image_url,
    p.image_path,
    p.category,
    p.user_id,
    p.tags,
    p.created_at,
    p.updated_at,
    u.email as user_email,
    COALESCE(u.raw_user_meta_data->>'username', split_part(u.email, '@', 1)) as username,
    COALESCE(u.raw_user_meta_data->>'avatar_url', '') as avatar_url,
    COALESCE(l.likes_count, 0) as likes_count,
    COALESCE(c.comments_count, 0) as comments_count
FROM glimmer_posts p
LEFT JOIN auth.users u ON p.user_id = u.id
LEFT JOIN (
    SELECT post_id, COUNT(*) as likes_count 
    FROM glimmer_likes 
    GROUP BY post_id
) l ON p.id = l.post_id
LEFT JOIN (
    SELECT post_id, COUNT(*) as comments_count 
    FROM glimmer_comments 
    GROUP BY post_id
) c ON p.id = c.post_id;

-- Create function to check if user liked a post
CREATE OR REPLACE FUNCTION user_liked_post(post_id UUID, user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM glimmer_likes 
        WHERE glimmer_likes.post_id = $1 AND glimmer_likes.user_id = $2
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get posts with user like status
CREATE OR REPLACE FUNCTION get_glimmer_posts_for_user(current_user_id UUID)
RETURNS TABLE (
    id UUID,
    title TEXT,
    description TEXT,
    image_url TEXT,
    image_path TEXT,
    category TEXT,
    user_id UUID,
    tags TEXT[],
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    user_email TEXT,
    username TEXT,
    avatar_url TEXT,
    likes_count BIGINT,
    comments_count BIGINT,
    is_liked_by_user BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.title,
        p.description,
        p.image_url,
        p.image_path,
        p.category,
        p.user_id,
        p.tags,
        p.created_at,
        p.updated_at,
        p.user_email,
        p.username,
        p.avatar_url,
        p.likes_count,
        p.comments_count,
        user_liked_post(p.id, current_user_id) as is_liked_by_user
    FROM glimmer_posts_with_stats p
    ORDER BY p.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
