# Crystal Social iOS Configuration

This document outlines the comprehensive iOS configuration for Crystal Social app.

## 🍎 Info.plist Enhancements

### 🔐 Privacy Permissions

#### Camera & Media
- **NSCameraUsageDescription** - Take photos for profile, share moments, capture memories
- **NSMicrophoneUsageDescription** - Record voice messages, participate in audio chats
- **NSPhotoLibraryUsageDescription** - Share images, set profile pictures, save memories
- **NSPhotoLibraryAddUsageDescription** - Save magical moments and tarot readings

#### Social Features
- **NSContactsUsageDescription** - Find friends who are using Crystal Social
- **NSLocationWhenInUseUsageDescription** - Location-based horoscope insights
- **NSCalendarsUsageDescription** - Astrological event reminders
- **NSRemindersUsageDescription** - Daily horoscope and pet care reminders

#### Advanced Features
- **NSAppleMusicUsageDescription** - Personalized soundtracks for meditation
- **NSSpeechRecognitionUsageDescription** - Voice-to-text conversion
- **NSBluetoothAlwaysUsageDescription** - Audio accessories and meditation devices
- **NSFaceIDUsageDescription** - Secure authentication for mystical data

### 🔗 URL Schemes & Deep Linking

#### Custom URL Schemes
- `crystalapp://` - Primary deep linking scheme
- `crystal-social://` - Alternative scheme
- `https://` - Universal links support

#### Supported URL Actions
- Profile sharing: `crystalapp://profile/[user-id]`
- Tarot readings: `crystalapp://tarot/reading/[reading-id]`
- Group invites: `crystalapp://groups/invite/[group-id]`
- Pet sharing: `crystalapp://pets/share/[pet-id]`
- Horoscope sharing: `crystalapp://horoscope/[date]`

### 📱 App Configuration

#### Identity & Branding
- **Display Name**: "Crystal Social" (updated from "Crystal")
- **Bundle Name**: "Crystal Social" (professional branding)
- **Category**: Social Networking app
- **Minimum iOS**: 12.0 (wide compatibility)

#### Interface Support
- **iPhone**: Portrait orientation only (focused experience)
- **iPad**: All orientations (flexible tablet usage)
- **Device Support**: iPhone and iPad universal

#### Performance Optimizations
- **High Frame Rate**: Enabled for smooth animations
- **Indirect Input**: Enabled for Apple Pencil support
- **File Sharing**: Enabled for content sharing
- **Documents**: Support for images and audio files

### 🌐 Network Configuration

#### App Transport Security
- **Supabase.co**: Configured for backend communication
- **Firebase.com**: Push notifications and analytics
- **Agora.io**: Real-time voice/video communication
- **Arbitrary Loads**: Enabled for development flexibility

#### Background Modes
- **Audio**: Background music and voice calls
- **Background Processing**: Data sync and notifications
- **Background Fetch**: Content updates
- **Remote Notifications**: Push notification handling
- **VoIP**: Voice over IP communication

### 🎵 Media & Content Support

#### Document Types
- **Images**: JPEG, PNG support with editing capabilities
- **Audio**: MP3, AAC support for voice messages
- **Custom Types**: Tarot reading files (.cstarot)

#### External App Integration
- **Spotify**: Music integration ready
- **Social Media**: Instagram, Twitter, TikTok, Snapchat
- **Communication**: WhatsApp, Telegram, Discord
- **Navigation**: Maps, Google Maps
- **System**: Mail, Phone, SMS

### 🔔 Push Notifications

#### Configuration
- **Environment**: Development (change to production for release)
- **Firebase Analytics**: Enabled for user insights
- **Firebase Crashlytics**: Enabled for crash reporting
- **OneSignal**: Third-party notification service ready

### 🔧 Third-Party SDK Configuration

#### Placeholder Values (Replace Before Release)
- **OneSignal App ID**: `your_onesignal_app_id_here`
- **Agora App ID**: `your_agora_app_id_here`
- **Spotify Client ID**: `your_spotify_client_id_here`

#### SDK Features Enabled
- **Spotify SDK**: Music integration and playlists
- **Agora SDK**: Real-time voice/video calls
- **OneSignal**: Enhanced push notifications

### 📊 Analytics & Security

#### App Store Configuration
- **Non-Exempt Encryption**: False (no custom encryption)
- **Analytics Collection**: Enabled for user behavior insights
- **Crashlytics**: Enabled for stability monitoring

#### Security Features
- **Face ID/Touch ID**: Biometric authentication support
- **Secure URL Schemes**: Proper deep link validation
- **Network Security**: TLS encryption required

## 🎯 Features Fully Supported

### ✅ Core Social Features
- Chat with voice messages and media sharing
- Group conversations with real-time communication
- Profile management with photo library integration
- Friend discovery through contacts integration

### ✅ Mystical & Spiritual Features
- Tarot reading with custom file format support
- Daily horoscope with calendar integration
- Moon phase tracking with location services
- Oracle cards with personalized experiences

### ✅ Virtual Spaces & Gaming
- Pet care with reminder notifications
- Crystal garden with background audio
- Butterfly garden with media integration
- Achievement system with push notifications

### ✅ Media & Communication
- Voice message recording and playback
- Photo capture and sharing
- Background audio for meditation
- Real-time voice/video calls via Agora

### ✅ Integration & Sharing
- Social media sharing (Instagram, Twitter, etc.)
- Music integration with Spotify
- Calendar and reminder integration
- Universal link sharing

## 🚀 Deployment Checklist

### Before App Store Submission
1. **Replace all placeholder values** with actual API keys
2. **Change aps-environment** from "development" to "production"
3. **Test all permissions** on physical iOS devices
4. **Verify deep link handling** works correctly
5. **Test background modes** functionality
6. **Validate universal links** with associated domains

### App Store Review Preparation
1. **Privacy Policy**: Document all data collection
2. **Permission Justification**: Explain why each permission is needed
3. **Age Rating**: Set appropriate content rating
4. **App Category**: Confirm "Social Networking" is correct
5. **Screenshots**: Show permission dialogs in action

### Optional Enhancements
- Add App Clips support for quick sharing
- Implement Siri Shortcuts for common actions
- Add Apple Watch companion app
- Support for Handoff between devices
- Implement Screen Time controls

## 🔍 Testing Requirements

### Permission Testing
- Test each permission request flow
- Verify graceful handling of denied permissions
- Test permission restoration after app reinstall

### Deep Link Testing
- Test all URL scheme variations
- Verify universal link handling
- Test sharing between apps

### Background Mode Testing
- Test audio playback in background
- Verify push notification delivery
- Test VoIP call handling

This comprehensive iOS configuration ensures Crystal Social works seamlessly across all iOS devices and integrates properly with the iOS ecosystem while maintaining user privacy and security standards.
