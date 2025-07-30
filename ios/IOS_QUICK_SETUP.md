# Crystal Social iOS Quick Setup Guide

This guide will help you quickly configure the iOS project for Crystal Social.

## 🚀 Quick Start

### 1. Prerequisites
- Xcode 14.0 or later
- iOS 12.0+ target device
- Valid Apple Developer Account
- CocoaPods installed (`sudo gem install cocoapods`)

### 2. Initial Setup
```bash
cd ios
pod install
```

### 3. Open Project
```bash
open Runner.xcworkspace  # Always use .xcworkspace, not .xcodeproj
```

## 🔧 Required Configuration

### 1. Firebase Setup
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create/select your project
3. Add iOS app with your bundle ID
4. Download `GoogleService-Info.plist`
5. Drag it into `ios/Runner/` directory in Xcode

### 2. Replace Placeholder Values in Info.plist

#### OneSignal Configuration
```xml
<key>OneSignalAppId</key>
<string>your_actual_onesignal_app_id</string>
```

#### Agora Configuration
```xml
<key>AgoraAppId</key>
<string>your_actual_agora_app_id</string>
```

#### Spotify Configuration
```xml
<key>SpotifyClientId</key>
<string>your_actual_spotify_client_id</string>
```

### 3. Push Notifications Setup

#### Development
- Info.plist already configured with `aps-environment: development`
- No additional changes needed for testing

#### Production
Change in Info.plist:
```xml
<key>aps-environment</key>
<string>production</string>
```

## 📱 Testing Checklist

### Permission Testing
- [ ] Camera access works
- [ ] Microphone access works
- [ ] Photo library access works
- [ ] Location access works (if needed)
- [ ] Contacts access works
- [ ] Push notifications work

### Deep Link Testing
- [ ] Custom URL schemes work (`crystalapp://`)
- [ ] Universal links work (if configured)
- [ ] App handles deep links correctly

### Background Features
- [ ] Audio plays in background
- [ ] Push notifications received in background
- [ ] App refreshes data in background

## 🔍 Common Issues & Solutions

### Issue: "Module not found"
**Solution:** Make sure you're opening `.xcworkspace` not `.xcodeproj`

### Issue: Firebase not working
**Solution:** Ensure `GoogleService-Info.plist` is added to the project target

### Issue: Push notifications not working
**Solution:** 
1. Check `aps-environment` in Info.plist
2. Verify Apple Push Notification certificate
3. Test on physical device (not simulator)

### Issue: Deep links not working
**Solution:** 
1. Verify URL schemes in Info.plist
2. Check associated domains in Apple Developer Console
3. Test with Safari or other apps

### Issue: Camera/Microphone permissions
**Solution:** Test on physical device (simulator has limited permission support)

## 🎯 Deployment Steps

### App Store Connect Setup
1. Create app in App Store Connect
2. Configure app information
3. Add screenshots
4. Set app privacy details
5. Submit for review

### Certificate Management
1. Create iOS Development/Distribution certificates
2. Create App Store provisioning profile
3. Configure in Xcode signing settings

### Build Configuration
1. Set deployment target to iOS 12.0+
2. Choose Release configuration
3. Archive and upload to App Store Connect

## 📋 Pre-Submission Checklist

### Code
- [ ] All placeholder values replaced
- [ ] Firebase configured correctly
- [ ] Push notifications tested
- [ ] Deep links tested
- [ ] Permissions work correctly

### Assets
- [ ] App icons added (all sizes)
- [ ] Launch screen configured
- [ ] Screenshots prepared
- [ ] App Store description written

### Legal
- [ ] Privacy policy created and linked
- [ ] Terms of service created
- [ ] App Store guidelines reviewed
- [ ] Age rating configured

## 🆘 Need Help?

### Resources
- [iOS Configuration Documentation](IOS_CONFIGURATION.md)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Firebase iOS Setup Guide](https://firebase.google.com/docs/ios/setup)

### Run Setup Script
```bash
cd ios/Runner
chmod +x ../ios_setup.sh
../ios_setup.sh
```

This will check your configuration and provide specific guidance.

## 🎉 Success!

Once everything is configured:
1. Your app will support all Crystal Social features
2. Push notifications will work seamlessly  
3. Deep linking will route users correctly
4. Background audio will continue playing
5. All permissions will be properly requested

The iOS version of Crystal Social is now ready for development and deployment! 🚀✨
