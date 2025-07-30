# Enhanced Push Notification System Setup Guide

## Overview

This enhanced push notification system tracks all devices where users have ever logged in and sends notifications to **all** devices for a user, even if they're not currently logged in. The notification format follows your requirement: **"Receiver": You have a message from "Sender"**.

## 🏗️ Architecture

```
┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
│   Device A          │    │   Device B          │    │   Device C          │
│   (User logged in)  │    │   (User logged out) │    │   (User logged in)  │
└─────────────────────┘    └─────────────────────┘    └─────────────────────┘
           │                           │                           │
           │                           │                           │
           └───────────────────────────┼───────────────────────────┘
                                       │
                    ┌─────────────────────────────────────┐
                    │     Crystal Social Backend         │
                    │  • Device Registration Service     │
                    │  • Push Notification Service       │
                    │  • Supabase Database               │
                    │  • Firebase Cloud Messaging        │
                    └─────────────────────────────────────┘
```

## 🚀 Quick Setup

### 1. Database Setup

Execute the SQL migration to create required tables:

```bash
# Run in Supabase SQL Editor
# Copy content from: database_migration_push_notifications.sql
```

Key tables created:
- `user_devices` - Tracks all devices where users logged in
- `notification_logs` - Logs all sent notifications

### 2. Firebase Configuration

1. Get your FCM Server Key from Firebase Console
2. Update the key in `push_notification_service.dart`:

```dart
static const String _fcmServerKey = 'YOUR_ACTUAL_FCM_SERVER_KEY';
```

### 3. Supabase Edge Function (Optional)

Deploy the edge function for server-side notification sending:

```bash
# Deploy to Supabase
supabase functions deploy send-push-notification
```

Set environment variables:
```bash
supabase secrets set FCM_SERVER_KEY=your_fcm_server_key_here
```

## 📱 Integration Guide

### 1. Initialize the System

The system automatically initializes when your app starts:

```dart
// In main.dart - already integrated
await EnhancedPushNotificationIntegration.instance.initialize();
```

### 2. User Login Integration

When users log in, their device gets registered:

```dart
// In enhanced_login_screen.dart - already integrated
await EnhancedPushNotificationIntegration.instance.onUserLogin(user.id);
```

### 3. Send Notifications

Use the unified service to send notifications:

```dart
// Send message notification
final success = await EnhancedPushNotificationIntegration.instance
    .sendMessageNotification(
  receiverUserId: receiverUserId,
  senderUsername: senderUsername,
  messagePreview: messageContent,
);

// Send group message notification
final results = await EnhancedPushNotificationIntegration.instance
    .sendGroupMessageNotification(
  receiverUserIds: groupMemberIds,
  senderUsername: senderUsername,
  groupName: groupName,
  messagePreview: messageContent,
);
```

## 🔧 Key Features

### ✅ Multi-Device Support
- Tracks all devices where a user has ever logged in
- Sends notifications to **all active devices**
- Automatically cleans up old/inactive devices

### ✅ Smart Notification Format
```
Title: "ReceiverUsername"
Body: "You have a message from SenderUsername"
```

### ✅ Comprehensive Device Management
- Device registration on login
- Device deactivation on logout
- FCM token refresh handling
- Device cleanup (90+ days inactive)

### ✅ Notification Types
- Direct messages: `"You have a message from John"`
- Group messages: `"New message in Group Chat from John"`
- Friend requests: `"John sent you a friend request"`
- System notifications: Custom messages

### ✅ Analytics & Monitoring
- Track notification delivery rates
- Monitor device counts per user
- Log all notification attempts
- User notification statistics

## 📊 Database Schema

### user_devices Table
```sql
- id: UUID (Primary Key)
- user_id: UUID (Foreign Key to auth.users)
- device_id: TEXT (Unique device identifier)
- fcm_token: TEXT (Firebase token)
- device_info: JSONB (Device details)
- is_active: BOOLEAN (Active status)
- first_login: TIMESTAMPTZ (First registration)
- last_active: TIMESTAMPTZ (Last activity)
```

### notification_logs Table
```sql
- id: UUID (Primary Key)
- receiver_user_id: UUID (Who received)
- sender_username: TEXT (Who sent)
- title: TEXT (Notification title)
- body: TEXT (Notification body)
- device_count: INTEGER (Devices targeted)
- success_count: INTEGER (Successfully delivered)
- created_at: TIMESTAMPTZ (When sent)
```

## 🔐 Security Features

### Row Level Security (RLS)
- Users can only see their own devices
- Users can only view their notification history
- Service can insert notifications with proper permissions

### Token Management
- Secure FCM token storage
- Automatic token refresh handling
- Token invalidation on logout

## 🧪 Testing

### Send Test Notification
```dart
await EnhancedPushNotificationIntegration.instance
    .sendTestNotification(userId);
```

### Check Notification Status
```dart
final enabled = await EnhancedPushNotificationIntegration.instance
    .areNotificationsEnabled();
```

### Get Statistics
```dart
final stats = await EnhancedPushNotificationIntegration.instance
    .getUserNotificationStats(userId);
```

## 🛠️ Maintenance

### Automatic Cleanup
The system automatically cleans up devices inactive for 90+ days:

```sql
-- Runs weekly via scheduled job
SELECT cleanup_old_devices();
```

### Manual Maintenance
```dart
await EnhancedPushNotificationIntegration.instance.performMaintenance();
```

## 📱 Notification Flow Example

### Scenario: Alice sends message to Bob

1. **Alice types message and hits send**
2. **Message saved to database**
3. **System finds all Bob's devices:**
   - Bob's iPhone (last active: today) ✅
   - Bob's iPad (last active: yesterday) ✅
   - Bob's old Android (last active: 100 days ago) ❌ (cleaned up)

4. **Notifications sent:**
   ```
   To iPhone: "Bob" - "You have a message from Alice"
   To iPad:   "Bob" - "You have a message from Alice"
   ```

5. **Bob receives notifications on both devices**
6. **Bob can open the app on any device to see the message**

## 🚨 Troubleshooting

### Common Issues

1. **Notifications not sending**
   - Check FCM Server Key
   - Verify user has active devices
   - Check Firebase Console for errors

2. **Device not registering**
   - Ensure user is authenticated
   - Check Firebase permissions
   - Verify Supabase connection

3. **Duplicate notifications**
   - Check for multiple device registrations
   - Verify FCM token uniqueness

### Debug Commands

```dart
// Check device registration
final devices = await EnhancedPushNotificationIntegration.instance
    .getCurrentUserDevices();

// View notification history
final stats = await EnhancedPushNotificationIntegration.instance
    .getUserNotificationStats(userId);
```

## 🎯 Next Steps

1. **Deploy database migration**
2. **Configure FCM Server Key**
3. **Test with real devices**
4. **Monitor notification delivery rates**
5. **Implement custom notification types as needed**

## 📚 Files Overview

- `device_registration_service.dart` - Device management
- `push_notification_service.dart` - Notification sending
- `enhanced_push_notification_integration.dart` - Unified interface
- `database_migration_push_notifications.sql` - Database setup
- `supabase/functions/send-push-notification/index.ts` - Edge function
- `examples/push_notification_usage_example.dart` - Usage examples

The system is now ready to send notifications to all devices where users have ever logged in, with the exact format you requested: **"Receiver": You have a message from "Sender"** 🎉
