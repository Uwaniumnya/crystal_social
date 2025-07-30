-- =====================================================
-- CRYSTAL SOCIAL - NOTES SYSTEM SETUP
-- =====================================================
-- Initial data and system configuration for notes
-- =====================================================

-- =====================================================
-- DEFAULT CATEGORIES AND TAGS
-- =====================================================

-- Function to create default categories for a user
CREATE OR REPLACE FUNCTION create_default_note_categories(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Create default categories with different colors
    INSERT INTO note_folders (user_id, name, color, icon, description) VALUES
        (p_user_id, 'Personal', '#FF6B6B', 'person', 'Personal notes and thoughts'),
        (p_user_id, 'Work', '#4ECDC4', 'work', 'Work-related notes and projects'),
        (p_user_id, 'Ideas', '#45B7D1', 'lightbulb', 'Creative ideas and brainstorming'),
        (p_user_id, 'Learning', '#96CEB4', 'school', 'Study notes and learning materials'),
        (p_user_id, 'Projects', '#FFEAA7', 'folder', 'Project documentation and planning'),
        (p_user_id, 'Archive', '#DDA0DD', 'archive', 'Archived and old notes')
    ON CONFLICT DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- DEFAULT TEMPLATES
-- =====================================================

-- Function to create default templates
CREATE OR REPLACE FUNCTION create_default_note_templates()
RETURNS VOID AS $$
BEGIN
    -- Create system user if it doesn't exist (for system-wide templates)
    INSERT INTO auth.users (id, email, created_at) 
    VALUES ('00000000-0000-0000-0000-000000000000', 'system@crystalsocial.app', NOW())
    ON CONFLICT (id) DO NOTHING;
    
    -- Create system-wide default templates
    INSERT INTO note_templates (
        user_id, 
        name, 
        description, 
        title_template,
        content_template, 
        content_html_template,
        default_category,
        is_public
    ) VALUES
    (
        '00000000-0000-0000-0000-000000000000', -- System user ID
        'Daily Journal',
        'A simple template for daily journaling',
        'Daily Journal - {{date}}',
        E'# Daily Journal - {{date}}\n\n## Today''s Goals\n- \n- \n- \n\n## What Happened\n\n\n## Reflections\n\n\n## Tomorrow''s Plan\n- \n- \n- ',
        '<h1>Daily Journal - {{date}}</h1><h2>Today''s Goals</h2><ul><li></li><li></li><li></li></ul><h2>What Happened</h2><p></p><h2>Reflections</h2><p></p><h2>Tomorrow''s Plan</h2><ul><li></li><li></li><li></li></ul>',
        'Personal',
        true
    ),
    (
        '00000000-0000-0000-0000-000000000000',
        'Meeting Notes',
        'Template for capturing meeting discussions and action items',
        'Meeting Notes - {{title}}',
        E'# Meeting Notes - {{title}}\n\n**Date:** {{date}}\n**Attendees:** \n**Duration:** \n\n## Agenda\n1. \n2. \n3. \n\n## Discussion Points\n\n\n## Decisions Made\n\n\n## Action Items\n- [ ] \n- [ ] \n- [ ] \n\n## Next Meeting\n**Date:** \n**Topics:** ',
        '<h1>Meeting Notes - {{title}}</h1><p><strong>Date:</strong> {{date}}<br><strong>Attendees:</strong><br><strong>Duration:</strong></p><h2>Agenda</h2><ol><li></li><li></li><li></li></ol><h2>Discussion Points</h2><p></p><h2>Decisions Made</h2><p></p><h2>Action Items</h2><ul><li><input type="checkbox"> </li><li><input type="checkbox"> </li><li><input type="checkbox"> </li></ul><h2>Next Meeting</h2><p><strong>Date:</strong><br><strong>Topics:</strong></p>',
        'Work',
        true
    ),
    (
        '00000000-0000-0000-0000-000000000000',
        'Project Planning',
        'Comprehensive template for project planning and tracking',
        'Project: {{project_name}}',
        E'# Project: {{project_name}}\n\n## Overview\n**Start Date:** {{start_date}}\n**End Date:** \n**Status:** Planning\n**Priority:** \n\n## Objectives\n\n\n## Scope\n### In Scope\n- \n- \n\n### Out of Scope\n- \n- \n\n## Timeline\n\n| Phase | Tasks | Deadline | Status |\n|-------|-------|----------|--------|\n| | | | |\n\n## Resources\n\n\n## Risks & Mitigation\n\n\n## Success Criteria\n- \n- \n- ',
        '<h1>Project: {{project_name}}</h1><h2>Overview</h2><p><strong>Start Date:</strong> {{start_date}}<br><strong>End Date:</strong><br><strong>Status:</strong> Planning<br><strong>Priority:</strong></p><h2>Objectives</h2><p></p><h2>Scope</h2><h3>In Scope</h3><ul><li></li><li></li></ul><h3>Out of Scope</h3><ul><li></li><li></li></ul><h2>Timeline</h2><table><thead><tr><th>Phase</th><th>Tasks</th><th>Deadline</th><th>Status</th></tr></thead><tbody><tr><td></td><td></td><td></td><td></td></tr></tbody></table><h2>Resources</h2><p></p><h2>Risks &amp; Mitigation</h2><p></p><h2>Success Criteria</h2><ul><li></li><li></li><li></li></ul>',
        'Projects',
        true
    ),
    (
        '00000000-0000-0000-0000-000000000000',
        'Study Notes',
        'Template for organized study and learning notes',
        'Study Notes: {{subject}} - {{topic}}',
        E'# {{subject}} - {{topic}}\n\n**Date:** {{date}}\n**Source:** \n**Chapter/Section:** \n\n## Key Concepts\n\n\n## Important Definitions\n\n\n## Examples\n\n\n## Questions\n- \n- \n- \n\n## Summary\n\n\n## Review Date\n**Next Review:** \n**Difficulty:** \n**Confidence:** ',
        '<h1>{{subject}} - {{topic}}</h1><p><strong>Date:</strong> {{date}}<br><strong>Source:</strong><br><strong>Chapter/Section:</strong></p><h2>Key Concepts</h2><p></p><h2>Important Definitions</h2><p></p><h2>Examples</h2><p></p><h2>Questions</h2><ul><li></li><li></li><li></li></ul><h2>Summary</h2><p></p><h2>Review Date</h2><p><strong>Next Review:</strong><br><strong>Difficulty:</strong><br><strong>Confidence:</strong></p>',
        'Learning',
        true
    ),
    (
        '00000000-0000-0000-0000-000000000000',
        'Creative Brief',
        'Template for creative projects and ideas',
        'Creative Brief: {{project_title}}',
        E'# Creative Brief: {{project_title}}\n\n## Concept\n\n\n## Inspiration\n\n\n## Target Audience\n\n\n## Goals\n- \n- \n- \n\n## Style Direction\n**Mood:** \n**Colors:** \n**Typography:** \n**Visual Style:** \n\n## Content Requirements\n\n\n## Timeline\n**Concept:** \n**First Draft:** \n**Revisions:** \n**Final:** \n\n## Resources Needed\n\n\n## Success Metrics\n- \n- \n- ',
        '<h1>Creative Brief: {{project_title}}</h1><h2>Concept</h2><p></p><h2>Inspiration</h2><p></p><h2>Target Audience</h2><p></p><h2>Goals</h2><ul><li></li><li></li><li></li></ul><h2>Style Direction</h2><p><strong>Mood:</strong><br><strong>Colors:</strong><br><strong>Typography:</strong><br><strong>Visual Style:</strong></p><h2>Content Requirements</h2><p></p><h2>Timeline</h2><p><strong>Concept:</strong><br><strong>First Draft:</strong><br><strong>Revisions:</strong><br><strong>Final:</strong></p><h2>Resources Needed</h2><p></p><h2>Success Metrics</h2><ul><li></li><li></li><li></li></ul>',
        'Ideas',
        true
    ),
    (
        '00000000-0000-0000-0000-000000000000',
        'Recipe',
        'Template for cooking recipes and food notes',
        'Recipe: {{recipe_name}}',
        E'# {{recipe_name}}\n\n**Prep Time:** \n**Cook Time:** \n**Servings:** \n**Difficulty:** \n\n## Ingredients\n\n\n## Instructions\n1. \n2. \n3. \n\n## Notes\n\n\n## Variations\n\n\n## Source\n\n\n## Rating\n**Taste:** ⭐⭐⭐⭐⭐\n**Difficulty:** ⭐⭐⭐⭐⭐\n**Would Make Again:** Yes/No',
        '<h1>{{recipe_name}}</h1><p><strong>Prep Time:</strong><br><strong>Cook Time:</strong><br><strong>Servings:</strong><br><strong>Difficulty:</strong></p><h2>Ingredients</h2><p></p><h2>Instructions</h2><ol><li></li><li></li><li></li></ol><h2>Notes</h2><p></p><h2>Variations</h2><p></p><h2>Source</h2><p></p><h2>Rating</h2><p><strong>Taste:</strong> ⭐⭐⭐⭐⭐<br><strong>Difficulty:</strong> ⭐⭐⭐⭐⭐<br><strong>Would Make Again:</strong> Yes/No</p>',
        'Personal',
        true
    )
    ON CONFLICT DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- COMMON TAGS SETUP
-- =====================================================

-- Function to create common tags for a user
CREATE OR REPLACE FUNCTION create_common_tags(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Insert common tags that users might find useful
    INSERT INTO note_tags (user_id, name, color, usage_count) VALUES
        (p_user_id, 'important', '#FF6B6B', 0),
        (p_user_id, 'urgent', '#FF4757', 0),
        (p_user_id, 'todo', '#5352ED', 0),
        (p_user_id, 'idea', '#FFA502', 0),
        (p_user_id, 'draft', '#747D8C', 0),
        (p_user_id, 'review', '#2F3542', 0),
        (p_user_id, 'completed', '#2ED573', 0),
        (p_user_id, 'reference', '#3742FA', 0),
        (p_user_id, 'personal', '#FF6348', 0),
        (p_user_id, 'work', '#1E90FF', 0)
    ON CONFLICT DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- USER ONBOARDING FUNCTION
-- =====================================================

-- Complete onboarding function for new users
CREATE OR REPLACE FUNCTION setup_user_notes_system(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Create user settings
    PERFORM ensure_user_note_settings(p_user_id);
    
    -- Create default folders
    PERFORM create_default_note_categories(p_user_id);
    
    -- Create common tags
    PERFORM create_common_tags(p_user_id);
    
    -- Create a welcome note
    INSERT INTO notes (
        user_id,
        title,
        content,
        content_html,
        folder_id,
        tags,
        is_pinned
    ) VALUES (
        p_user_id,
        'Welcome to Crystal Social Notes! 📝',
        E'# Welcome to Crystal Social Notes!\n\nWe''re excited to have you here! This powerful note-taking system is designed to help you capture, organize, and share your thoughts seamlessly.\n\n## Getting Started\n\n### 🗂️ Folders\nWe''ve created some default folders to help you organize your notes:\n- **Personal** - For your personal thoughts and ideas\n- **Work** - For work-related notes and projects\n- **Ideas** - For creative brainstorming and inspiration\n- **Learning** - For study notes and educational content\n- **Projects** - For project planning and documentation\n- **Archive** - For older notes you want to keep\n\n### 🏷️ Tags\nUse tags to categorize your notes across folders. We''ve added some common tags to get you started:\n#important #urgent #todo #idea #draft #review #completed #reference\n\n### 📋 Templates\nCheck out our templates to quickly create structured notes for:\n- Daily journaling\n- Meeting notes\n- Project planning\n- Study notes\n- Creative briefs\n- Recipes\n\n### ✨ Features to Explore\n\n**Rich Text Editing**: Format your notes with headers, lists, links, and more\n\n**Collaboration**: Share notes with friends and collaborate in real-time\n\n**Voice Notes**: Record audio directly in your notes\n\n**Attachments**: Add images, documents, and files to your notes\n\n**Search**: Find any note quickly with our powerful search\n\n**Analytics**: Track your writing progress and habits\n\n## Tips for Success\n\n1. **Start Simple**: Begin with basic notes and gradually explore advanced features\n2. **Stay Organized**: Use folders and tags consistently\n3. **Regular Reviews**: Set aside time to review and organize your notes\n4. **Share Wisely**: Use our sharing features to collaborate with others\n5. **Backup Important Notes**: Pin important notes and use our revision history\n\n## Need Help?\n\nIf you have any questions or need assistance, don''t hesitate to reach out to our support team. We''re here to help you make the most of your note-taking experience!\n\nHappy note-taking! 🚀',
        '<h1>Welcome to Crystal Social Notes!</h1><p>We''re excited to have you here! This powerful note-taking system is designed to help you capture, organize, and share your thoughts seamlessly.</p><h2>Getting Started</h2><h3>🗂️ Folders</h3><p>We''ve created some default folders to help you organize your notes:</p><ul><li><strong>Personal</strong> - For your personal thoughts and ideas</li><li><strong>Work</strong> - For work-related notes and projects</li><li><strong>Ideas</strong> - For creative brainstorming and inspiration</li><li><strong>Learning</strong> - For study notes and educational content</li><li><strong>Projects</strong> - For project planning and documentation</li><li><strong>Archive</strong> - For older notes you want to keep</li></ul><h3>🏷️ Tags</h3><p>Use tags to categorize your notes across folders. We''ve added some common tags to get you started:</p><p>#important #urgent #todo #idea #draft #review #completed #reference</p><h3>📋 Templates</h3><p>Check out our templates to quickly create structured notes for:</p><ul><li>Daily journaling</li><li>Meeting notes</li><li>Project planning</li><li>Study notes</li><li>Creative briefs</li><li>Recipes</li></ul><h3>✨ Features to Explore</h3><p><strong>Rich Text Editing</strong>: Format your notes with headers, lists, links, and more</p><p><strong>Collaboration</strong>: Share notes with friends and collaborate in real-time</p><p><strong>Voice Notes</strong>: Record audio directly in your notes</p><p><strong>Attachments</strong>: Add images, documents, and files to your notes</p><p><strong>Search</strong>: Find any note quickly with our powerful search</p><p><strong>Analytics</strong>: Track your writing progress and habits</p><h2>Tips for Success</h2><ol><li><strong>Start Simple</strong>: Begin with basic notes and gradually explore advanced features</li><li><strong>Stay Organized</strong>: Use folders and tags consistently</li><li><strong>Regular Reviews</strong>: Set aside time to review and organize your notes</li><li><strong>Share Wisely</strong>: Use our sharing features to collaborate with others</li><li><strong>Backup Important Notes</strong>: Pin important notes and use our revision history</li></ol><h2>Need Help?</h2><p>If you have any questions or need assistance, don''t hesitate to reach out to our support team. We''re here to help you make the most of your note-taking experience!</p><p>Happy note-taking! 🚀</p>',
        (SELECT id FROM note_folders WHERE user_id = p_user_id AND name = 'Personal' LIMIT 1),
        ARRAY['welcome', 'getting-started', 'important'],
        true
    );
    
    EXCEPTION WHEN OTHERS THEN
        -- Log error but don't fail the entire setup
        RAISE NOTICE 'Error setting up user notes system: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- SYSTEM CONFIGURATION
-- =====================================================

-- Create default templates (call once during setup)
SELECT create_default_note_templates();

-- =====================================================
-- MAINTENANCE FUNCTIONS
-- =====================================================

-- Function to update note statistics (can be run periodically)
CREATE OR REPLACE FUNCTION update_notes_statistics()
RETURNS TABLE(
    updated_notes INTEGER,
    updated_folders INTEGER,
    cleaned_shares INTEGER
) AS $$
DECLARE
    v_updated_notes INTEGER := 0;
    v_updated_folders INTEGER := 0;
    v_cleaned_shares INTEGER := 0;
BEGIN
    -- Update note statistics that might have gotten out of sync
    UPDATE notes SET
        word_count = COALESCE(array_length(string_to_array(trim(content), ' '), 1), 0),
        character_count = LENGTH(content),
        estimated_read_time = GREATEST(1, CEIL(COALESCE(array_length(string_to_array(trim(content), ' '), 1), 0) / 200.0))
    WHERE word_count != COALESCE(array_length(string_to_array(trim(content), ' '), 1), 0)
       OR character_count != LENGTH(content);
    
    GET DIAGNOSTICS v_updated_notes = ROW_COUNT;
    
    -- Update folder statistics
    WITH folder_stats AS (
        SELECT 
            folder_id,
            COUNT(*) as note_count,
            SUM(word_count) as total_words
        FROM notes 
        WHERE NOT is_deleted AND folder_id IS NOT NULL
        GROUP BY folder_id
    )
    UPDATE note_folders SET
        note_count = COALESCE(folder_stats.note_count, 0),
        total_words = COALESCE(folder_stats.total_words, 0)
    FROM folder_stats
    WHERE note_folders.id = folder_stats.folder_id;
    
    GET DIAGNOSTICS v_updated_folders = ROW_COUNT;
    
    -- Clean up expired shares
    UPDATE note_shares SET is_active = false
    WHERE is_active = true 
      AND expires_at IS NOT NULL 
      AND expires_at < NOW();
    
    GET DIAGNOSTICS v_cleaned_shares = ROW_COUNT;
    
    RETURN QUERY SELECT v_updated_notes, v_updated_folders, v_cleaned_shares;
END;
$$ LANGUAGE plpgsql;

-- Function to get system statistics
CREATE OR REPLACE FUNCTION get_notes_system_stats()
RETURNS TABLE(
    total_users INTEGER,
    total_notes INTEGER,
    total_folders INTEGER,
    total_templates INTEGER,
    total_shares INTEGER,
    total_comments INTEGER,
    total_words BIGINT,
    avg_notes_per_user NUMERIC,
    avg_words_per_note NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(DISTINCT user_id)::INTEGER FROM notes)::INTEGER as total_users,
        (SELECT COUNT(*)::INTEGER FROM notes WHERE NOT is_deleted)::INTEGER as total_notes,
        (SELECT COUNT(*)::INTEGER FROM note_folders)::INTEGER as total_folders,
        (SELECT COUNT(*)::INTEGER FROM note_templates)::INTEGER as total_templates,
        (SELECT COUNT(*)::INTEGER FROM note_shares WHERE is_active = true)::INTEGER as total_shares,
        (SELECT COUNT(*)::INTEGER FROM note_comments)::INTEGER as total_comments,
        (SELECT COALESCE(SUM(word_count), 0) FROM notes WHERE NOT is_deleted)::BIGINT as total_words,
        (SELECT ROUND(COUNT(*)::NUMERIC / NULLIF(COUNT(DISTINCT user_id), 0), 2) FROM notes WHERE NOT is_deleted)::NUMERIC as avg_notes_per_user,
        (SELECT ROUND(AVG(word_count), 2) FROM notes WHERE NOT is_deleted AND word_count > 0)::NUMERIC as avg_words_per_note;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- GRANT PERMISSIONS ON SETUP FUNCTIONS
-- =====================================================

GRANT EXECUTE ON FUNCTION setup_user_notes_system(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_default_note_categories(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_common_tags(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_notes_statistics() TO service_role;
GRANT EXECUTE ON FUNCTION get_notes_system_stats() TO authenticated;

-- =====================================================
-- SAMPLE DATA (OPTIONAL - FOR DEVELOPMENT)
-- =====================================================

-- Uncomment and modify the following section if you want to create sample data for development

/*
-- Create sample user and data (only for development environments)
DO $$
DECLARE
    sample_user_id UUID := '12345678-1234-1234-1234-123456789012';
BEGIN
    -- Setup the sample user
    PERFORM setup_user_notes_system(sample_user_id);
    
    -- Create some sample notes
    INSERT INTO notes (user_id, title, content, content_html, folder_id, tags) VALUES
    (
        sample_user_id,
        'My First Note',
        'This is my first note in Crystal Social! I''m excited to start organizing my thoughts here.',
        '<p>This is my first note in Crystal Social! I''m excited to start organizing my thoughts here.</p>',
        (SELECT id FROM note_folders WHERE user_id = sample_user_id AND name = 'Personal' LIMIT 1),
        ARRAY['first', 'personal']
    ),
    (
        sample_user_id,
        'Project Alpha Planning',
        E'# Project Alpha\n\n## Goals\n- Improve user experience\n- Increase performance\n- Add new features\n\n## Timeline\n- Week 1: Research\n- Week 2: Design\n- Week 3-4: Development\n- Week 5: Testing',
        '<h1>Project Alpha</h1><h2>Goals</h2><ul><li>Improve user experience</li><li>Increase performance</li><li>Add new features</li></ul><h2>Timeline</h2><ul><li>Week 1: Research</li><li>Week 2: Design</li><li>Week 3-4: Development</li><li>Week 5: Testing</li></ul>',
        (SELECT id FROM note_folders WHERE user_id = sample_user_id AND name = 'Work' LIMIT 1),
        ARRAY['project', 'planning', 'work']
    );
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Could not create sample data: %', SQLERRM;
END $$;
*/
