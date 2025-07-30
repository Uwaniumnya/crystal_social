# Crystal Social Services Integration

This directory contains a comprehensive, integrated service system for Crystal Social that allows all services to work together smoothly.

## 🚀 Quick Start

```dart
import 'package:crystal_social/services/services.dart';

// Initialize all services at app startup
await Services.initialize();

// Handle user login
await Services.login(userId);

// Send a message notification
await Services.notifyMessage(
  receiverUserId: 'receiver123',
  senderUsername: 'John',
  messagePreview: 'Hello there!',
);

// Handle user logout
await Services.logout(userId);
```

## 📁 Service Architecture

### Core Services
- **`device_registration_service.dart`** - Manages device registration for push notifications
- **`push_notification_service.dart`** - Handles push notification sending
- **`enhanced_push_notification_integration.dart`** - Enhanced notification wrapper
- **`device_user_tracking_service.dart`** - Tracks users on devices for security
- **`glimmer_service.dart`** - Manages Glimmer Wall posts and interactions

### Integration Layer
- **`unified_service_manager.dart`** - Coordinates all services to work together
- **`service_integration_helper.dart`** - Provides easy-to-use wrapper methods
- **`service_initializer.dart`** - Handles proper initialization of all services
- **`service_config.dart`** - Centralized configuration for all services

### Usage Examples
- **`service_integration_example.dart`** - Comprehensive examples of service usage
- **`services.dart`** - Main export file for easy imports

## 🔧 Features

### ✅ Unified Service Management
- Single initialization point for all services
- Coordinated login/logout flows
- Integrated notification system
- Automatic service dependency management

### ✅ Enhanced Notifications
- Message notifications with user context
- Group message notifications
- Friend request notifications
- System notifications
- Glimmer post interaction notifications

### ✅ Security & Device Management
- Multi-user device tracking
- Auto-logout for shared devices
- Device registration management
- Security-based access control

### ✅ Glimmer Integration
- Post creation with follower notifications
- Like/comment notifications to post owners
- Personalized feed generation
- Comprehensive post interaction tracking

### ✅ Service Health & Maintenance
- System health monitoring
- Automatic maintenance tasks
- Service verification
- Comprehensive status reporting

## 🛠️ Usage Examples

### Initialize Services
```dart
// At app startup (usually in main.dart)
await ServiceInitializer.initializeAllServices();

// Or use the convenience method
await Services.initialize();
```

### Handle User Authentication
```dart
// Complete login flow
await Services.login(userId);

// Check if auto-logout should be applied
final shouldAutoLogout = await Services.helper.shouldUserBeAutoLoggedOut(userId);

// Complete logout flow
await Services.logout(userId);
```

### Send Notifications
```dart
// Message notification
await Services.helper.sendChatMessageWithNotification(
  receiverUserId: 'receiver123',
  senderUsername: 'John',
  messageContent: 'Hello there!',
);

// Friend request notification
await Services.helper.sendFriendRequestWithNotification(
  receiverUserId: 'receiver123',
  senderUsername: 'John',
);

// Group message notifications
await Services.helper.sendGroupMessageWithNotifications(
  memberUserIds: ['user1', 'user2', 'user3'],
  senderUsername: 'John',
  groupName: 'Study Group',
  messageContent: 'Meeting at 3 PM!',
);
```

### Glimmer Integration
```dart
// Create post with follower notifications
final postId = await Services.helper.createGlimmerPostWithIntegration(
  title: 'Beautiful sunset',
  description: 'Amazing view from my window',
  imageFile: imageFile,
  category: 'nature',
  userId: userId,
  tags: ['sunset', 'photography'],
  notifyFollowers: true,
);

// Like post with owner notification
await Services.helper.likeGlimmerPostWithNotification(
  postId: postId,
  userId: userId,
  currentlyLiked: false,
  notifyPostOwner: true,
);

// Get personalized feed
final feed = await Services.helper.getPersonalizedGlimmerFeed(
  userId: userId,
  category: 'nature',
);
```

### System Monitoring
```dart
// Get comprehensive user status
final userStatus = await Services.helper.getUserComprehensiveStatus(userId);

// Get system health
final healthStatus = await Services.helper.getSystemHealthStatus();

// Perform maintenance
await Services.helper.performSystemMaintenance();

// Get service status
final serviceStatus = await Services.getStatus();
```

## ⚙️ Configuration

Customize service behavior in `service_config.dart`:

```dart
class ServiceConfig {
  // Enable/disable features
  static const bool enablePushNotifications = true;
  static const bool enableAutoLogout = true;
  static const bool notifyFollowersOnNewPost = true;
  
  // Performance settings
  static const Duration serviceInitializationTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  
  // Maintenance settings
  static const Duration maintenanceInterval = Duration(hours: 24);
  static const int maxNotificationLogDays = 30;
}
```

## 🔄 Service Dependencies

```
Services (service_initializer.dart)
    ↓
ServiceIntegrationHelper (service_integration_helper.dart)
    ↓
UnifiedServiceManager (unified_service_manager.dart)
    ↓
Individual Services:
    ├── DeviceRegistrationService
    ├── PushNotificationService
    ├── EnhancedPushNotificationIntegration
    ├── DeviceUserTrackingService
    └── GlimmerService
```

## 📱 Widget Integration

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: Services.initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LoadingScreen();
        }
        
        if (snapshot.data == true) {
          return MainApp();
        }
        
        return ErrorScreen();
      },
    );
  }
}
```

## 🛡️ Error Handling

All services include comprehensive error handling:

```dart
try {
  await Services.login(userId);
} catch (e) {
  // Handle login error
  print('Login failed: $e');
}

// Services also provide status information
final status = await Services.getStatus();
if (status['health_status']['status'] != 'healthy') {
  // Handle service health issues
}
```

## 🔍 Debugging

Enable debug logging in `service_config.dart`:

```dart
static const bool enableDebugLogging = true;
static const bool logServiceOperations = true;
```

View initialization logs:
```dart
final logs = ServiceInitializer.initializationLog;
for (final log in logs) {
  print(log);
}
```

## 🚨 Important Notes

1. **Initialize Once**: Call `Services.initialize()` only once at app startup
2. **Error Handling**: Always wrap service calls in try-catch blocks
3. **Permissions**: Ensure notification permissions are granted
4. **Configuration**: Review `service_config.dart` for your app's needs
5. **Testing**: Use the examples in `service_integration_example.dart` for testing

## 📋 Checklist for Integration

- [ ] Add services import to your main.dart
- [ ] Initialize services at app startup
- [ ] Handle user login/logout flows
- [ ] Set up notification permissions
- [ ] Configure service settings
- [ ] Test notification delivery
- [ ] Verify service health monitoring
- [ ] Implement error handling
- [ ] Test auto-logout functionality
- [ ] Verify Glimmer integration

## 🎯 Best Practices

1. **Always check service readiness** before operations
2. **Use the helper methods** for common operations
3. **Monitor service health** regularly
4. **Handle errors gracefully** with user feedback
5. **Test on multiple devices** for device tracking
6. **Review logs** for debugging issues
7. **Update configuration** based on app needs

The services are now fully integrated and work together smoothly! 🎉
