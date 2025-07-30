# Crystal Social Android Configuration

This document outlines the comprehensive Android configuration for Crystal Social app.

## 🔧 Permissions Added

### Core Permissions
- `INTERNET` - Network access for backend communication
- `ACCESS_NETWORK_STATE` - Check network connectivity
- `WAKE_LOCK` - Keep device awake during important operations

### Notifications
- `POST_NOTIFICATIONS` - Send push notifications (Android 13+)
- `VIBRATE` - Vibration for notifications
- `RECEIVE_BOOT_COMPLETED` - Restart services after device reboot

### Media & Storage
- `READ_MEDIA_IMAGES` - Access image files (Android 13+)
- `READ_MEDIA_VIDEO` - Access video files (Android 13+)
- `READ_MEDIA_AUDIO` - Access audio files (Android 13+)
- `READ_EXTERNAL_STORAGE` - Legacy storage access (max SDK 32)
- `WRITE_EXTERNAL_STORAGE` - Legacy storage write (max SDK 28)

### Camera & Audio
- `CAMERA` - Take photos and videos
- `RECORD_AUDIO` - Record voice messages and audio
- `MODIFY_AUDIO_SETTINGS` - Adjust audio settings for calls

### Real-time Communication (Agora SDK)
- `ACCESS_WIFI_STATE` - WiFi state for call quality
- `CHANGE_WIFI_STATE` - Optimize WiFi for calls
- `BLUETOOTH` - Bluetooth audio devices
- `BLUETOOTH_ADMIN` - Manage Bluetooth connections
- `BLUETOOTH_CONNECT` - Connect to Bluetooth devices

### Additional Features
- `ACCESS_COARSE_LOCATION` - Location-based features
- `SYSTEM_ALERT_WINDOW` - Overlay windows
- `FOREGROUND_SERVICE` - Background audio/messaging services

## 🎯 Hardware Features
- Camera (optional)
- Autofocus (optional)
- Microphone (optional)
- Bluetooth (optional)

## 🔗 Intent Filters

### Deep Links
- Custom scheme: `crystalapp://callback`
- Auto-verification enabled for secure deep linking

### Share Integration
- Text sharing support
- Image sharing support
- File sharing through FileProvider

### Launch & Main
- Main launcher activity
- Single-top launch mode for optimal performance

## 📱 App Configuration

### Application Settings
- App name: "Crystal Social"
- Large heap enabled for media processing
- Hardware acceleration enabled
- Legacy external storage support
- Clear text traffic allowed for development

### Activity Configuration
- Portrait orientation locked
- Single-top launch mode
- Proper config changes handling
- Optimized window input mode

## 🔔 Firebase & Push Notifications

### Firebase Messaging
- Default notification channel: `default_channel`
- Custom notification icon: `@drawable/ic_notification`
- Brand notification color: `@color/notification_color`
- Dedicated messaging service configured

### OneSignal Support
- App ID placeholder (needs configuration)
- Google project number placeholder (needs configuration)

## 🎵 Audio Services

### Audio Session Service
- Media playback foreground service
- Media button receiver for hardware controls
- Background audio playback support

## 📁 File Provider

### Secure File Sharing
- Authority: `${applicationId}.fileprovider`
- Multiple path configurations:
  - Internal files
  - External files
  - Cache directories
  - Downloads
  - Pictures
  - Camera images
  - Audio files

## 🎨 Theme & Styling

### Launch Theme
- Custom splash screen
- Proper status bar colors
- Navigation bar styling

### Normal Theme
- Light/dark mode support
- Brand color integration
- Proper window handling

### Status Bar
- Dark status bar with brand colors
- Navigation bar optimization
- System bar drawing enabled

## 📱 Package Visibility (Android 11+)

### Query Support
- Text processing apps
- Web browsers
- Email clients
- Phone dialers
- Media apps
- Camera apps
- Spotify integration

## 🔧 Required Configuration

### Before Release
1. Replace placeholder values:
   - `your_onesignal_app_id_here`
   - `your_google_project_number_here`
   - `your_agora_app_id_here`

2. Test all permissions on different Android versions
3. Verify deep link handling
4. Test file sharing functionality
5. Confirm notification appearance

### Optional Enhancements
- Add adaptive icon support
- Configure notification channels
- Add widgets support
- Implement app shortcuts

## 🎯 Features Supported

✅ **Social Features**
- Chat with media sharing
- Group conversations
- Profile management
- Real-time communication

✅ **Media Features**
- Photo capture and sharing
- Audio recording
- Video playback
- File downloads

✅ **Gaming Features**
- Background audio
- In-app purchases ready
- Game state persistence

✅ **Mystical Features**
- Tarot reading apps
- Horoscope notifications
- Oracle card sharing

✅ **Virtual Spaces**
- Garden management
- Pet care reminders
- Achievement notifications

✅ **Rewards System**
- Push notifications for rewards
- In-app currency management
- Achievement unlocks

This configuration provides comprehensive support for all Crystal Social features while maintaining security and performance standards.
