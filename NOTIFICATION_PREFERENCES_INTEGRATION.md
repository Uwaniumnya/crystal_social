# Notification Preferences Integration Guide

Your enhanced notification system is now ready! Here's how to integrate it:

## ✅ What's Been Created

### 1. **Notification Preferences Service** (`lib/services/notification_preferences_service.dart`)
- Manages user notification preferences in Supabase
- Handles quiet hours, notification types, sound settings
- Provides easy-to-use API for updating preferences

### 2. **Dedicated Preferences Screen** (`lib/tabs/notification_preferences_screen.dart`)  
- Beautiful, comprehensive notification settings UI
- Real-time preference updates with visual feedback
- Test notification functionality
- Quiet hours with time picker
- Sound selection dialog

### 3. **Updated Push Notification Service**
- Now uses your Firebase Web API Key: `AIzaSyDd89JRRHAoKSChIoMfM3zZzkrVOyI4tjA`
- Edge Function deployed successfully to Supabase
- Fallback mechanisms for reliability

## 🚀 Quick Integration Steps

### Step 1: Add Environment Variable
In your Supabase Dashboard → Project Settings → Edge Functions:
```
FIREBASE_WEB_API_KEY=AIzaSyDd89JRRHAoKSChIoMfM3zZzkrVOyI4tjA
```

### Step 2: Create Database Tables
Run this SQL in your Supabase SQL Editor:

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
    show_preview BOOLEAN DEFAULT true,
    group_notifications BOOLEAN DEFAULT false,
    max_notifications_per_hour INTEGER DEFAULT 10,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Row Level Security
ALTER TABLE user_notification_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own notification preferences" ON user_notification_preferences
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Service role full access to notification_preferences" ON user_notification_preferences
    FOR ALL USING (current_setting('role') = 'service_role');
```

### Step 3: Add Navigation Button
Add this to your existing settings screen (in the notifications section):

```dart
// Add this import at the top
import 'notification_preferences_screen.dart';

// Add this button in your notifications tab
ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.purple.shade600,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 12),
  ),
  icon: const Icon(Icons.tune),
  label: const Text('Advanced Notification Settings'),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationPreferencesScreen(userId: widget.userId),
      ),
    );
  },
),
```

## 🎯 Usage Examples

### Test Notifications
```dart
import '../services/push_notification_service.dart';

// Send different types of notifications
await PushNotificationService.instance.sendChatNotification(
  receiverUserId: 'user-id',
  senderUsername: 'Alice',
  messagePreview: 'Hey there! 👋',
);

await PushNotificationService.instance.sendAchievementNotification(
  receiverUserId: 'user-id',
  achievementName: 'First Login',
);

await PushNotificationService.instance.sendPetNotification(
  receiverUserId: 'user-id',
  petName: 'Fluffy',
  action: 'needs feeding! 🍎',
);
```

### Check User Preferences
```dart
import '../services/notification_preferences_service.dart';

// Check if user wants message notifications
final wantsMessages = await NotificationPreferencesService.instance
    .isNotificationTypeEnabled('user-id', 'message');

// Check if user is in quiet hours
final isQuietTime = await NotificationPreferencesService.instance
    .isInQuietHours('user-id');
```

## 🎨 Features Included

### **Notification Types**
- ✅ Messages (chat, DMs)
- ✅ Achievements (rewards, level ups)
- ✅ Friend Requests
- ✅ Pet Interactions
- ✅ Support & System

### **Sound & Vibration**
- ✅ Custom notification sounds
- ✅ Vibration control
- ✅ Message preview toggle
- ✅ Sound picker dialog

### **Quiet Hours**
- ✅ Enable/disable quiet hours
- ✅ Custom start/end times
- ✅ Visual time picker
- ✅ Automatic enforcement

### **Advanced Features**
- ✅ Test notification button
- ✅ Real-time preference sync
- ✅ Beautiful UI with proper feedback
- ✅ Edge Function integration
- ✅ Fallback mechanisms

## 🔧 Customization

You can easily customize:
- **Colors**: Change `Colors.purple.shade600` to your theme color
- **Sounds**: Add more sounds to the picker dialog
- **Notification Types**: Add new types in the service and UI
- **Quiet Hours Logic**: Modify enforcement rules in the Edge Function

## 🚨 Important Notes

1. **Environment Variable**: Make sure to set `FIREBASE_WEB_API_KEY` in Supabase
2. **Database Tables**: Create the notification preferences table
3. **Edge Function**: Already deployed and ready to use
4. **Testing**: Use the test button to verify everything works

Your Crystal Social notification system is now enterprise-ready with user-friendly controls! 🎉
