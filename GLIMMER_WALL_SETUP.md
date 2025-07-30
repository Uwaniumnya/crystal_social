# Glimmer Wall Database Setup

This guide will help you set up the database for the Glimmer Wall feature in your Crystal Social app.

## Prerequisites

1. **Supabase Account**: Sign up at [supabase.com](https://supabase.com)
2. **Docker Desktop** (for local development): [Install Docker](https://docs.docker.com/desktop/)

## Quick Setup (Recommended)

### Option 1: Use Supabase Cloud (Easiest)

1. **Create a new Supabase project**:
   - Go to [supabase.com](https://supabase.com)
   - Click "New Project"
   - Enter project details and wait for setup to complete

2. **Run the migrations**:
   ```bash
   # Install Supabase CLI if not already installed
   npm install -g @supabase/cli
   
   # Login to Supabase
   supabase login
   
   # Link your project (get project ref from Supabase dashboard)
   supabase link --project-ref YOUR_PROJECT_REF
   
   # Run migrations
   supabase db push
   ```

3. **Update your Flutter app configuration**:
   - Copy your Supabase URL and anon key from the project dashboard
   - Update your Supabase configuration in `main.dart`

### Option 2: Local Development with Docker

1. **Start local Supabase**:
   ```bash
   # Make sure Docker Desktop is running first
   supabase start
   ```

2. **The migrations will run automatically** when you start the local instance.

## Database Schema

The following tables will be created:

### `glimmer_posts`
- Stores all glimmer posts with images, titles, descriptions, categories, and tags
- Links to user accounts via `user_id`

### `glimmer_likes`
- Tracks which users liked which posts
- Prevents duplicate likes with unique constraint

### `glimmer_comments`
- Stores comments on glimmer posts
- Links to both posts and users

### `glimmer-images` Storage Bucket
- Stores uploaded images
- Public read access, authenticated write access
- User-specific folders for organization

## Features Included

✅ **Image Upload**: Full Supabase Storage integration  
✅ **Real-time Data**: Live database queries  
✅ **User Authentication**: Row Level Security (RLS) policies  
✅ **Like System**: Toggle likes with real-time updates  
✅ **Comments System**: Add and view comments  
✅ **Search & Filter**: Category and text-based filtering  
✅ **User Permissions**: Users can only edit/delete their own content

## Security Features

- **Row Level Security (RLS)** enabled on all tables
- **Authentication required** for creating content
- **User isolation**: Users can only modify their own posts
- **Storage policies**: Images organized by user ID

## Troubleshooting

### If you see "failed to inspect container health" error:
1. Make sure Docker Desktop is installed and running
2. Try running Docker Desktop as administrator
3. Alternative: Use Supabase Cloud instead of local development

### If migrations fail:
1. Check your internet connection
2. Verify you're logged into Supabase CLI: `supabase auth status`
3. Make sure your project is linked: `supabase projects list`

### If the app shows mock data:
- The app automatically falls back to mock data if the database isn't set up
- Once you run the migrations, restart the app to use real data

## Need Help?

- [Supabase Documentation](https://supabase.com/docs)
- [Flutter Supabase Guide](https://supabase.com/docs/guides/getting-started/tutorials/with-flutter)
- Check the console logs in your Flutter app for specific error messages

---

## Manual Migration (Advanced)

If you prefer to set up the database manually, you can copy and paste the SQL from these files into your Supabase SQL editor:

1. `supabase/migrations/20250726000001_create_glimmer_tables.sql`
2. `supabase/migrations/20250726000002_create_glimmer_views_functions.sql`
3. `supabase/migrations/20250726000003_create_storage_bucket.sql`

Run them in order in the Supabase dashboard SQL editor.
