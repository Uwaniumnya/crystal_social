# Crystal Social - Post-Integration Next Steps
🎉 **Congratulations! You've successfully integrated all SQL files!**

## Phase 1: Verification (CRITICAL - Do This First)

### 1. Run Database Verification
```sql
-- In your PostgreSQL/Supabase SQL editor, run:
\i post_import_verification.sql

-- Or copy/paste the contents of post_import_verification.sql
-- and run it to check for any issues
```

### 2. Check for Critical Issues
The verification script will check for:
- ✅ Missing foreign key references
- ✅ Duplicate function definitions
- ✅ Row Level Security status
- ✅ Essential tables existence
- ✅ Essential functions existence
- ✅ Basic functionality tests

**If any issues are found, fix them before proceeding.**

## Phase 2: Initial Configuration

### 1. Create Your First Admin User
```sql
-- Replace 'your-user-id-here' with your actual Supabase user ID
SELECT make_user_admin('your-user-id-here'::UUID);

-- Verify admin status
SELECT id, email, is_admin, is_moderator 
FROM profiles 
WHERE is_admin = true;
```

### 2. Configure Essential Settings
```sql
-- Update admin configuration with your settings
SELECT set_admin_config('support_email', '"uwaniumnya@gmail.com"');
SELECT set_admin_config('maintenance_mode', 'false');
SELECT set_admin_config('auto_moderation_enabled', 'true');

-- Verify settings
SELECT config_key, config_value 
FROM admin_config 
WHERE is_public = true;
```

### 3. Test Core Functionality
```sql
-- Test widget system
SELECT COUNT(*) as widget_tables 
FROM pg_tables 
WHERE tablename LIKE '%widget%' OR tablename LIKE '%sticker%';

-- Test admin system
SELECT COUNT(*) as admin_tables 
FROM pg_tables 
WHERE tablename LIKE '%admin%' OR tablename LIKE '%support%';

-- Test user system
SELECT COUNT(*) as user_tables 
FROM pg_tables 
WHERE tablename LIKE '%profile%' OR tablename LIKE '%user%';
```

## Phase 3: Supabase-Specific Setup (If Using Supabase)

### 1. Enable Realtime (Optional)
```sql
-- Enable realtime for key tables (only add tables that actually exist)
-- Check which tables exist first:
SELECT tablename FROM pg_tables WHERE schemaname = 'public' 
AND tablename IN ('profiles', 'message_bubbles', 'support_requests', 'admin_alerts', 'widget_usage_analytics', 'fronting_changes', 'admin_notifications', 'system_event_logs');

-- Then enable realtime for existing tables:
ALTER publication supabase_realtime ADD TABLE profiles;
ALTER publication supabase_realtime ADD TABLE message_bubbles; -- This is the actual chat messages table
ALTER publication supabase_realtime ADD TABLE support_requests;
ALTER publication supabase_realtime ADD TABLE widget_usage_analytics;

-- Optional: Add other real-time tables if they exist
-- ALTER publication supabase_realtime ADD TABLE fronting_changes;
-- ALTER publication supabase_realtime ADD TABLE admin_notifications;
-- ALTER publication supabase_realtime ADD TABLE system_event_logs;
```

### 2. Configure Storage Policies (If Using File Uploads)
```sql
-- Create all necessary storage buckets for Crystal Social
INSERT INTO storage.buckets (id, name, public) VALUES

('stickers', 'stickers', true),         -- Widget stickers and emoticons
('backgrounds', 'backgrounds', true),   -- Widget backgrounds and themes
('pets', 'pets', true),                 -- Pet images and animations
('garden', 'garden', true),             -- Garden decorations and plants
('gems', 'gems', true),                 -- Gem and crystal graphics
('rewards', 'rewards', true),           -- Achievement badges and rewards
('audio', 'audio', false),              -- Sound effects and music (private)
('user-content', 'user-content', false), -- User-uploaded content (private)
('admin-uploads', 'admin-uploads', false); -- Admin-only files (private)

-- Create storage policies for each bucket

-- 1. Avatars - Users can upload their own profile pictures
CREATE POLICY "Users can upload own avatar" ON storage.objects
FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view all avatars" ON storage.objects
FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "Users can update own avatar" ON storage.objects
FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- 2. Stickers - Uses local assets folder, users can view
-- Note: Stickers are loaded from local assets/icons/ folder, not uploaded
CREATE POLICY "Everyone can view stickers" ON storage.objects
FOR SELECT USING (bucket_id = 'stickers');

-- 3. Backgrounds - Everyone can upload, but only see their own
-- Note: Run these one at a time to avoid deadlocks, or wrap in a transaction
BEGIN;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Users can upload own backgrounds" ON storage.objects;
DROP POLICY IF EXISTS "Users can view own backgrounds" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own backgrounds" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own backgrounds" ON storage.objects;
DROP POLICY IF EXISTS "Admin can upload backgrounds" ON storage.objects;
DROP POLICY IF EXISTS "Everyone can view backgrounds" ON storage.objects;

-- Create new policies
CREATE POLICY "Users can upload own backgrounds" ON storage.objects
FOR INSERT WITH CHECK (bucket_id = 'backgrounds' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view own backgrounds" ON storage.objects
FOR SELECT USING (bucket_id = 'backgrounds' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can update own backgrounds" ON storage.objects
FOR UPDATE USING (bucket_id = 'backgrounds' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete own backgrounds" ON storage.objects
FOR DELETE USING (bucket_id = 'backgrounds' AND auth.uid()::text = (storage.foldername(name))[1]);

COMMIT;

-- 4. Pets - Uses local assets folder, users can view
-- Note: Pet assets are loaded from local assets/pets/ folder, not uploaded
CREATE POLICY "Everyone can view pet assets" ON storage.objects
FOR SELECT USING (bucket_id = 'pets');

-- 5. Garden - Uses local assets folder, users can view
-- Note: Garden assets are loaded from local assets/garden/ folder, not uploaded
CREATE POLICY "Everyone can view garden assets" ON storage.objects
FOR SELECT USING (bucket_id = 'garden');

-- 6. Gems - Uses local assets folder, users can view
-- Note: Gem assets are loaded from local assets/gems/ folder, not uploaded
CREATE POLICY "Everyone can view gem assets" ON storage.objects
FOR SELECT USING (bucket_id = 'gems');

-- 7. Rewards - Uses local assets folder, users can view
-- Note: Reward assets are loaded from local assets/shop/ folder, not uploaded
CREATE POLICY "Everyone can view reward assets" ON storage.objects
FOR SELECT USING (bucket_id = 'rewards');

-- 8. Audio - Admin uploads, authenticated users can access
CREATE POLICY "Admin can upload audio" ON storage.objects
FOR INSERT WITH CHECK (bucket_id = 'audio' AND EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
));

CREATE POLICY "Authenticated users can access audio" ON storage.objects
FOR SELECT USING (bucket_id = 'audio' AND auth.role() = 'authenticated');

-- 9. User Content - Users can upload own content
CREATE POLICY "Users can upload own content" ON storage.objects
FOR INSERT WITH CHECK (bucket_id = 'user-content' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view own content" ON storage.objects
FOR SELECT USING (bucket_id = 'user-content' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can update own content" ON storage.objects
FOR UPDATE USING (bucket_id = 'user-content' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete own content" ON storage.objects
FOR DELETE USING (bucket_id = 'user-content' AND auth.uid()::text = (storage.foldername(name))[1]);

-- 10. Admin Uploads - Admin only access
CREATE POLICY "Admin only upload access" ON storage.objects
FOR INSERT WITH CHECK (bucket_id = 'admin-uploads' AND EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
));

CREATE POLICY "Admin only view access" ON storage.objects
FOR SELECT USING (bucket_id = 'admin-uploads' AND EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true
));

-- Optional: Set up file size limits (adjust as needed)
-- These would be set in your Supabase dashboard under Storage settings
-- Recommended limits:
-- avatars: 5MB
-- stickers: 2MB per file
-- backgrounds: 10MB per file
-- pets: 5MB per file
-- garden: 5MB per file
-- gems: 2MB per file
-- rewards: 2MB per file
-- audio: 20MB per file
-- user-content: 50MB per file
-- admin-uploads: 100MB per file
```

### 3. Set Up Edge Functions (Optional)

Edge Functions provide serverless processing for your Crystal Social platform. Here are the recommended functions to implement:

#### 📧 Email Notification Function
```typescript
// supabase/functions/send-notification/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const { type, userId, data } = await req.json()
    
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )
    
    switch (type) {
      case 'support_ticket':
        await sendSupportTicketEmail(data)
        break
      case 'admin_alert':
        await sendAdminAlert(data)
        break
      case 'welcome':
        await sendWelcomeEmail(data)
        break
      case 'achievement':
        await sendAchievementEmail(data)
        break
    }
    
    return new Response(JSON.stringify({ success: true }), {
      headers: { "Content-Type": "application/json" },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    })
  }
})
```

#### 🛡️ Content Moderation Function
```typescript
// supabase/functions/moderate-content/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  try {
    const { content, contentType, userId } = await req.json()
    
    // Basic content filtering
    const bannedWords = ['spam', 'inappropriate', 'harmful']
    const hasInappropriateContent = bannedWords.some(word => 
      content.toLowerCase().includes(word)
    )
    
    // Advanced moderation (integrate with AI services)
    const moderationResult = {
      approved: !hasInappropriateContent,
      reason: hasInappropriateContent ? 'Contains inappropriate content' : null,
      confidence: hasInappropriateContent ? 0.9 : 0.1,
      tags: []
    }
    
    // Log moderation result
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )
    
    await supabase.from('content_moderation_logs').insert({
      user_id: userId,
      content_type: contentType,
      content_preview: content.substring(0, 100),
      is_approved: moderationResult.approved,
      reason: moderationResult.reason,
      confidence_score: moderationResult.confidence
    })
    
    return new Response(JSON.stringify(moderationResult), {
      headers: { "Content-Type": "application/json" },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    })
  }
})
```

#### 📊 Analytics Processing Function
```typescript
// supabase/functions/process-analytics/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  try {
    const { event, userId, data, timestamp } = await req.json()
    
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )
    
    // Process different event types
    switch (event) {
      case 'widget_usage':
        await processWidgetAnalytics(supabase, userId, data)
        break
      case 'pet_interaction':
        await processPetAnalytics(supabase, userId, data)
        break
      case 'purchase_event':
        await processPurchaseAnalytics(supabase, userId, data)
        break
      case 'session_event':
        await processSessionAnalytics(supabase, userId, data)
        break
    }
    
    return new Response(JSON.stringify({ processed: true }), {
      headers: { "Content-Type": "application/json" },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    })
  }
})

async function processWidgetAnalytics(supabase, userId, data) {
  await supabase.from('widget_usage_analytics').insert({
    user_id: userId,
    widget_type: data.widgetType,
    action: data.action,
    session_duration: data.duration,
    timestamp: new Date().toISOString()
  })
}
```

#### 🔄 Background Task Scheduler
```typescript
// supabase/functions/background-tasks/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  try {
    const { task } = await req.json()
    
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )
    
    switch (task) {
      case 'daily_cleanup':
        await performDailyCleanup(supabase)
        break
      case 'reward_distribution':
        await distributeRewards(supabase)
        break
      case 'health_check':
        await performHealthCheck(supabase)
        break
      case 'analytics_summary':
        await generateAnalyticsSummary(supabase)
        break
    }
    
    return new Response(JSON.stringify({ taskCompleted: task }), {
      headers: { "Content-Type": "application/json" },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    })
  }
})

async function performDailyCleanup(supabase) {
  // Clean old logs, expired sessions, etc.
  await supabase.from('system_event_logs')
    .delete()
    .lt('created_at', new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString())
}
```

#### 🎮 Game Events Processor
```typescript
// supabase/functions/process-game-events/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  try {
    const { eventType, userId, gameData } = await req.json()
    
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )
    
    switch (eventType) {
      case 'pet_level_up':
        await handlePetLevelUp(supabase, userId, gameData)
        break
      case 'achievement_unlock':
        await handleAchievementUnlock(supabase, userId, gameData)
        break
      case 'garden_harvest':
        await handleGardenHarvest(supabase, userId, gameData)
        break
      case 'reward_claim':
        await handleRewardClaim(supabase, userId, gameData)
        break
    }
    
    return new Response(JSON.stringify({ eventProcessed: true }), {
      headers: { "Content-Type": "application/json" },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    })
  }
})
```

#### 🔧 Deployment Commands

```bash
# Install Supabase CLI
npm install -g supabase

# Deploy individual functions
supabase functions deploy send-notification
supabase functions deploy moderate-content
supabase functions deploy process-analytics
supabase functions deploy background-tasks
supabase functions deploy process-game-events

# Set environment variables
supabase secrets set SMTP_HOST=your-smtp-host
supabase secrets set SMTP_USER=uwaniumnya@gmail.com
supabase secrets set SMTP_PASS=your-smtp-password
supabase secrets set MODERATION_API_KEY=your-moderation-api-key
supabase secrets set FIREBASE_WEB_API_KEY=AIzaSyDd89JRRHAoKSChIoMfM3zZzkrVOyI4tjA
```

#### 🔗 Database Triggers for Edge Functions

```sql
-- Trigger for automatic content moderation
CREATE OR REPLACE FUNCTION trigger_content_moderation()
RETURNS TRIGGER AS $$
BEGIN
  -- Call moderation edge function for new posts
  PERFORM net.http_post(
    url := 'https://zdsjtjbzhiejvpuahnlk.supabase.co/functions/v1/moderate-content',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer ' || current_setting('app.service_role_key') || '"}'::jsonb,
    body := jsonb_build_object(
      'content', NEW.content,
      'contentType', TG_TABLE_NAME,
      'userId', NEW.user_id
    )
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to relevant tables
CREATE TRIGGER moderate_support_requests
  AFTER INSERT ON support_requests
  FOR EACH ROW
  EXECUTE FUNCTION trigger_content_moderation();

-- Trigger for analytics processing
CREATE OR REPLACE FUNCTION trigger_analytics_processing()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM net.http_post(
    url := 'https://zdsjtjbzhiejvpuahnlk.supabase.co/functions/v1/process-analytics',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer ' || current_setting('app.service_role_key') || '"}'::jsonb,
    body := jsonb_build_object(
      'event', 'widget_usage',
      'userId', NEW.user_id,
      'data', row_to_json(NEW),
      'timestamp', NEW.created_at
    )
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER process_widget_analytics
  AFTER INSERT ON widget_usage_analytics
  FOR EACH ROW
  EXECUTE FUNCTION trigger_analytics_processing();
```

#### 📅 Cron Jobs Setup

```sql
-- Set up periodic tasks using pg_cron extension
SELECT cron.schedule('daily-cleanup', '0 2 * * *', 'SELECT net.http_post(url := ''https://zdsjtjbzhiejvpuahnlk.supabase.co/functions/v1/background-tasks'', body := ''{"task": "daily_cleanup"}'')');

SELECT cron.schedule('reward-distribution', '0 0 * * 0', 'SELECT net.http_post(url := ''https://zdsjtjbzhiejvpuahnlk.supabase.co/functions/v1/background-tasks'', body := ''{"task": "reward_distribution"}'')');

SELECT cron.schedule('health-check', '*/15 * * * *', 'SELECT net.http_post(url := ''https://zdsjtjbzhiejvpuahnlk.supabase.co/functions/v1/background-tasks'', body := ''{"task": "health_check"}'')');
```

#### ✅ Edge Functions Checklist

- [ ] **Email notifications** for support tickets and alerts
- [ ] **Content moderation** for user-generated content
- [ ] **Analytics processing** for user behavior tracking
- [ ] **Background tasks** for maintenance and cleanup
- [ ] **Game events processing** for achievements and rewards
- [ ] **Database triggers** connecting functions to table changes
- [ ] **Cron jobs** for scheduled maintenance tasks
- [ ] **Environment variables** configured securely
- [ ] **Error handling** and logging implemented
- [ ] **Rate limiting** and security measures in place

## Phase 4: Application Integration

### 1. Flutter/Dart Integration
```dart
// Update your Supabase client configuration
final supabase = Supabase.initialize(
  url: 'https://zdsjtjbzhiejvpuahnlk.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpkc2p0amJ6aGllanZwdWFobmxrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4MjAyMzYsImV4cCI6MjA2OTM5NjIzNn0.CSPzbngxKJHrHD8oNMFaYzvKXzNzMENFtaWu9Vy2rV0',
);

// Test database connection
final response = await supabase.client
  .from('profiles')
  .select('id, email')
  .limit(1);
```

### 2. Environment Variables
```env
# Add to your .env file
SUPABASE_URL=https://zdsjtjbzhiejvpuahnlk.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpkc2p0amJ6aGllanZwdWFobmxrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4MjAyMzYsImV4cCI6MjA2OTM5NjIzNn0.CSPzbngxKJHrHD8oNMFaYzvKXzNzMENFtaWu9Vy2rV0
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpkc2p0amJ6aGllanZwdWFobmxrIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzgyMDIzNiwiZXhwIjoyMDY5Mzk2MjM2fQ.sOTNug5cmkkC3stzFqgw7v8lEVK_c06BgP-hHbsfj8A
SUPPORT_EMAIL=uwaniumnya@gmail.com
```

### 3. Update App Configuration

#### 🔗 Database Connection Strings
Your database connections are already configured in `lib/config/environment_config.dart`. Verify the configuration:

```dart
// lib/config/environment_config.dart - Already configured! ✅
class EnvironmentConfig {
  static String get supabaseUrl => 'https://zdsjtjbzhiejvpuahnlk.supabase.co';
  static String get supabaseAnonKey => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
}
```

#### 🔐 Configure Authentication Flows
Update your authentication service to handle new user features:

```dart
// lib/services/auth_service.dart - Add this configuration
class AuthService {
  static Future<void> setupNewUserProfile(User user) async {
    // Initialize new user with default preferences
    await NotificationPreferencesService.instance.createDefaultPreferences(user.id);
    
    // Set up default user profile
    await supabase.from('profiles').upsert({
      'id': user.id,
      'email': user.email,
      'display_name': user.email?.split('@')[0] ?? 'User',
      'avatar_url': null,
      'created_at': DateTime.now().toIso8601String(),
    });
    
    // Initialize user settings
    await supabase.from('user_settings').upsert({
      'user_id': user.id,
      'theme': 'kawaii_pink',
      'notifications_enabled': true,
      'language': 'en',
    });
  }
}
```

#### ⚠️ Set Up Error Handling for New Tables
Add error handling for new database tables in your services:

```dart
// lib/services/database_service.dart - Create this file
class DatabaseService {
  static Future<T?> safeQuery<T>(
    Future<T> Function() query,
    String operation,
  ) async {
    try {
      return await query();
    } on PostgrestException catch (e) {
      // Handle database-specific errors
      if (e.code == 'PGRST116') {
        // Table doesn't exist
        debugPrint('⚠️ Table not found for $operation: ${e.message}');
        return null;
      } else if (e.code == '42501') {
        // Permission denied
        debugPrint('🔒 Permission denied for $operation: ${e.message}');
        throw Exception('Access denied. Please check your permissions.');
      }
      throw Exception('Database error in $operation: ${e.message}');
    } catch (e) {
      debugPrint('❌ Unexpected error in $operation: $e');
      throw Exception('Unexpected error in $operation');
    }
  }
}

// Usage example in your services:
Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
  return await DatabaseService.safeQuery(
    () => supabase
        .from('user_notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false),
    'getUserNotifications',
  ) ?? [];
}
```

#### 🌐 Update API Endpoints
Configure your app to use the new Edge Functions and API endpoints:

```dart
// lib/config/api_config.dart - Create this file
class ApiConfig {
  static const String baseUrl = 'https://zdsjtjbzhiejvpuahnlk.supabase.co';
  
  // Edge Function URLs
  static const String sendNotificationUrl = '$baseUrl/functions/v1/send-push-notification';
  static const String moderateContentUrl = '$baseUrl/functions/v1/moderate-content';
  static const String processAnalyticsUrl = '$baseUrl/functions/v1/process-analytics';
  static const String backgroundTasksUrl = '$baseUrl/functions/v1/background-tasks';
  
  // API Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${EnvironmentConfig.supabaseAnonKey}',
  };
  
  static Map<String, String> get serviceHeaders => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${EnvironmentConfig.supabaseServiceRoleKey}',
  };
}
```

#### 📱 Update Main App Initialization
Update your `lib/main.dart` to initialize all new services:

```dart
// lib/main.dart - Add to your initializeApp() method
Future<void> initializeApp() async {
  // Existing Supabase initialization
  await Supabase.initialize(
    url: EnvironmentConfig.supabaseUrl,
    anonKey: EnvironmentConfig.supabaseAnonKey,
  );
  
  // Initialize new services
  await NotificationPreferencesService.instance.initialize();
  await PushNotificationService.instance.initialize();
  
  // Set up error monitoring
  FlutterError.onError = (FlutterErrorDetails details) {
    // Log errors to your monitoring service
    debugPrint('🐛 Flutter Error: ${details.exception}');
  };
}
```

#### 🔄 Update Service Integrations
Ensure all your services work with the new database schema:

```dart
// lib/services/user_service.dart - Update existing service
class UserService {
  // Add method to check for new features
  static Future<bool> hasNewFeatures(String userId) async {
    try {
      // Check if user has notification preferences
      final prefs = await NotificationPreferencesService.instance.getPreferences(userId);
      
      // Check if user has updated profile features
      final profile = await supabase
          .from('profiles')
          .select('updated_at, feature_flags')
          .eq('id', userId)
          .single();
      
      return prefs != null && profile != null;
    } catch (e) {
      return false;
    }
  }
  
  // Migration helper for existing users
  static Future<void> migrateExistingUser(String userId) async {
    await AuthService.setupNewUserProfile(
      supabase.auth.currentUser!
    );
  }
}
```

## Phase 5: Testing & Validation

### 1. Core Features Testing
- [ ] User registration/login
- [ ] Profile creation/editing
- [ ] Admin panel access
- [ ] Support ticket creation
- [ ] Widget functionality
- [ ] Chat system
- [ ] Rewards system

### 2. Security Testing
- [ ] Row Level Security policies
- [ ] Admin-only access controls
- [ ] User data privacy
- [ ] API endpoint security

### 3. Performance Testing
- [ ] Database query performance
- [ ] Index usage verification
- [ ] Connection pooling
- [ ] Realtime subscriptions

## Phase 6: Production Preparation

### 1. Backup Strategy
```sql
-- Set up automated backups
SELECT set_admin_config('backup_retention_days', '90');
SELECT set_admin_config('auto_backup_enabled', 'true');
```

### 2. Monitoring Setup
```sql
-- Enable health checks
UPDATE system_health_checks 
SET is_active = true 
WHERE check_name IN (
    'Database Connection',
    'Support Requests Response Time',
    'Active User Sessions'
);
```

### 3. Documentation
- [ ] API documentation
- [ ] Admin user guide
- [ ] Database schema documentation
- [ ] Deployment procedures

## Phase 7: Go Live! 🚀

### Pre-Launch Checklist
- [ ] All verification tests pass
- [ ] Admin user created and tested
- [ ] Core functionality working
- [ ] Security policies validated
- [ ] Backup system configured
- [ ] Monitoring enabled
- [ ] Documentation complete

### Launch Steps
1. **Enable production mode**
2. **Monitor system health**
3. **Watch for errors in logs**
4. **Be ready for user feedback**
5. **Celebrate your success!** 🎉

## Troubleshooting Common Issues

### Issue: "relation does not exist"
**Solution**: Check import order, ensure prerequisites were imported first

### Issue: "function already exists"
**Solution**: Remove duplicate function definitions from individual files

### Issue: RLS policy errors
**Solution**: Verify user authentication and profile setup

### Issue: Performance problems
**Solution**: Check indexes, analyze query plans, optimize heavy queries

## Support & Resources

- **Database Schema**: All tables documented with comments
- **Function Reference**: All custom functions have inline documentation
- **Security Guide**: RLS policies documented in each integration
- **API Reference**: Generated from database schema

---

## 🎯 You're Ready!

Your Crystal Social database is now fully integrated and ready for production use! The system includes:

- ✅ **Complete user management** (profiles, auth, admin)
- ✅ **Comprehensive admin panel** (support, moderation, analytics)
- ✅ **Rich widget system** (stickers, backgrounds, emoticons)
- ✅ **Social features** (chat, groups, rewards)
- ✅ **Entertainment features** (pets, garden, spotify, gems)
- ✅ **Utility systems** (notes, tabs, services)
- ✅ **Enterprise security** (RLS, audit logs, content moderation)
- ✅ **Production monitoring** (health checks, analytics, alerts)

**Next Step**: Run the verification script and start testing your amazing new social platform! 🚀

---
*Last Updated: July 30, 2025*  
*Status: ✅ Ready for Production*
