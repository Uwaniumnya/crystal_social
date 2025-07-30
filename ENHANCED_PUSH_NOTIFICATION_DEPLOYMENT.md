# Enhanced Push Notification Edge Function Deployment Guide

This guide shows you how to deploy the enhanced push notification Edge Function### 1. Set Environment Variables

**Using Web API Key (Recommended - Simple Setup)**

In your Supabase dashboard, go to Project Settings → Edge Functions and add:

```
FIREBASE_WEB_API_KEY=AIzaSyDd89JRRHAoKSChIoMfM3zZzkrVOyI4tjA
```dvanced features.

## Features Added
- ✅ User notification preferences (types, quiet hours)
- ✅ Bulk notification support
- ✅ Invalid token cleanup
- ✅ Notification analytics logging
- ✅ Scheduled notifications
- ✅ Better error handling
- ✅ CORS support

## Prerequisites

1. **Supabase CLI installed**
   ```bash
   npm install -g supabase
   ```

2. **Environment variables configured**
   - `FIREBASE_SERVICE_ACCOUNT`: Your Firebase Admin SDK service account JSON (as base64 string)
   - `SUPABASE_URL`: Your Supabase project URL
   - `SUPABASE_SERVICE_ROLE_KEY`: Your Supabase service role key

## Required Database Tables

First, create these tables if they don't exist:

```sql
-- User notification preferences
CREATE TABLE IF NOT EXISTS user_notification_preferences (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    messages BOOLEAN DEFAULT true,
    achievements BOOLEAN DEFAULT true,
    support BOOLEAN DEFAULT true,
    system BOOLEAN DEFAULT true,
    friend_requests BOOLEAN DEFAULT true,
    pet_interactions BOOLEAN DEFAULT true,
    sound VARCHAR(50) DEFAULT 'default',
    vibrate BOOLEAN DEFAULT true,
    quiet_hours_enabled BOOLEAN DEFAULT false,
    quiet_hours_start TIME DEFAULT '22:00',
    quiet_hours_end TIME DEFAULT '08:00',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- User devices for FCM tokens
CREATE TABLE IF NOT EXISTS user_devices (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    device_type VARCHAR(20) DEFAULT 'unknown', -- 'ios', 'android', 'web'
    device_name VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(fcm_token)
);

-- Notification logs for analytics
CREATE TABLE IF NOT EXISTS notification_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    receiver_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    sender_username VARCHAR(100),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    notification_type VARCHAR(50) DEFAULT 'message',
    device_count INTEGER DEFAULT 0,
    success_count INTEGER DEFAULT 0,
    notification_data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Scheduled notifications
CREATE TABLE IF NOT EXISTS scheduled_notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    receiver_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    data JSONB DEFAULT '{}',
    notification_type VARCHAR(50) DEFAULT 'message',
    scheduled_for TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'sent', 'failed', 'cancelled'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sent_at TIMESTAMP WITH TIME ZONE
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_devices_user_id ON user_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_active ON user_devices(is_active);
CREATE INDEX IF NOT EXISTS idx_notification_logs_receiver ON notification_logs(receiver_user_id);
CREATE INDEX IF NOT EXISTS idx_scheduled_notifications_time ON scheduled_notifications(scheduled_for, status);
```

## Row Level Security Policies

```sql
-- User notification preferences policies
ALTER TABLE user_notification_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notification preferences" ON user_notification_preferences
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notification preferences" ON user_notification_preferences
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own notification preferences" ON user_notification_preferences
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- User devices policies
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own devices" ON user_devices
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own devices" ON user_devices
    FOR ALL USING (auth.uid() = user_id);

-- Service role can access all for push notifications
CREATE POLICY "Service role full access to user_devices" ON user_devices
    FOR ALL USING (current_setting('role') = 'service_role');

CREATE POLICY "Service role full access to notification_preferences" ON user_notification_preferences
    FOR ALL USING (current_setting('role') = 'service_role');

-- Notification logs (service role only)
ALTER TABLE notification_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role can manage notification logs" ON notification_logs
    FOR ALL USING (current_setting('role') = 'service_role');

-- Scheduled notifications
ALTER TABLE scheduled_notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role can manage scheduled notifications" ON scheduled_notifications
    FOR ALL USING (current_setting('role') = 'service_role');
```

## Deployment Steps

### 1. Set Environment Variables

In your Supabase dashboard, go to Project Settings > Edge Functions and add:

```
FCM_SERVER_KEY=your_firebase_server_key_here
```

### 2. Deploy the Simplified Function

**Option A: Replace the existing function**
```bash
# Navigate to your project root
cd e:\github\crystal_social

# Copy the simplified version over the original
copy "supabase\functions\send-push-notification\index_simple.ts" "supabase\functions\send-push-notification\index.ts"

# Deploy
supabase functions deploy send-push-notification --no-verify-jwt
```

**Option B: Deploy as new function**
```bash
# Deploy the simplified version as-is
supabase functions deploy send-push-notification-simple --no-verify-jwt
```

### 3. Test the Enhanced Function

```dart
// Test the enhanced notification features
Future<void> testEnhancedNotifications() async {
  final service = PushNotificationService();
  
  // Test basic notification
  await service.sendChatNotification(
    receiverUserId: 'user-uuid',
    senderUsername: 'TestUser',
    message: 'Hello from enhanced notifications!',
  );
  
  // Test scheduled notification
  await service.sendNotificationWithFallback(
    receiverUserId: 'user-uuid',
    title: 'Scheduled Reminder',
    body: 'This is your scheduled reminder',
    scheduleTime: DateTime.now().add(Duration(minutes: 5)),
  );
  
  // Test bulk notifications
  await service.sendBulkNotifications([
    {
      'receiver_user_id': 'user1-uuid',
      'title': 'Bulk Message 1',
      'body': 'First bulk message',
    },
    {
      'receiver_user_id': 'user2-uuid',
      'title': 'Bulk Message 2',
      'body': 'Second bulk message',
    },
  ]);
}
```

## Configuration in Flutter App

Update your notification preferences UI:

```dart
// lib/services/notification_preferences_service.dart
class NotificationPreferencesService {
  static const _table = 'user_notification_preferences';
  
  Future<Map<String, dynamic>> getPreferences() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    final response = await Supabase.instance.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    
    return response ?? _defaultPreferences();
  }
  
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    await Supabase.instance.client
        .from(_table)
        .upsert({
          'user_id': userId,
          ...preferences,
          'updated_at': DateTime.now().toIso8601String(),
        });
  }
  
  Map<String, dynamic> _defaultPreferences() => {
    'messages': true,
    'achievements': true,
    'support': true,
    'system': true,
    'friend_requests': true,
    'pet_interactions': true,
    'sound': 'default',
    'vibrate': true,
    'quiet_hours_enabled': false,
    'quiet_hours_start': '22:00',
    'quiet_hours_end': '08:00',
  };
}
```

## Monitoring and Analytics

The enhanced function provides detailed analytics. Query notification performance:

```sql
-- Check notification success rates
SELECT 
    notification_type,
    COUNT(*) as total_sent,
    AVG(success_count::FLOAT / NULLIF(device_count, 0)) as success_rate,
    DATE_TRUNC('day', created_at) as date
FROM notification_logs
WHERE created_at >= NOW() - INTERVAL '7 days'
GROUP BY notification_type, DATE_TRUNC('day', created_at)
ORDER BY date DESC;

-- Check inactive devices that need cleanup
SELECT 
    user_id,
    device_type,
    last_seen,
    fcm_token
FROM user_devices 
WHERE is_active = false 
AND last_seen < NOW() - INTERVAL '30 days';
```

## Scheduled Notifications (Optional)

To process scheduled notifications, create a cron job Edge Function:

```typescript
// supabase/functions/process-scheduled-notifications/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )
  
  // Get pending notifications that are due
  const { data: notifications } = await supabase
    .from('scheduled_notifications')
    .select('*')
    .eq('status', 'pending')
    .lte('scheduled_for', new Date().toISOString())
    .limit(100)
  
  for (const notification of notifications || []) {
    try {
      // Send the notification
      const response = await fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/send-push-notification`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${Deno.env.get('SUPABASE_ANON_KEY')}`
        },
        body: JSON.stringify({
          receiver_user_id: notification.receiver_user_id,
          title: notification.title,
          body: notification.body,
          data: notification.data,
          notification_type: notification.notification_type
        })
      })
      
      // Update status
      await supabase
        .from('scheduled_notifications')
        .update({ 
          status: response.ok ? 'sent' : 'failed',
          sent_at: new Date().toISOString()
        })
        .eq('id', notification.id)
        
    } catch (error) {
      console.error('Failed to send scheduled notification:', error)
      
      await supabase
        .from('scheduled_notifications')
        .update({ status: 'failed' })
        .eq('id', notification.id)
    }
  }
  
  return new Response(JSON.stringify({ processed: notifications?.length || 0 }))
})
```

## Benefits of Enhanced Version

1. **User Control**: Users can customize notification types and quiet hours
2. **Better Reliability**: Automatic cleanup of invalid tokens
3. **Analytics**: Track notification performance and delivery rates
4. **Scheduling**: Support for delayed notifications
5. **Bulk Operations**: Efficient mass notifications
6. **Error Handling**: Comprehensive error reporting and recovery

Your Crystal Social platform now has enterprise-grade push notification capabilities! 🚀
