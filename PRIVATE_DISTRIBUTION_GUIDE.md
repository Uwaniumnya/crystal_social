# Crystal Social - Private Distribution Guide

This guide will help you build and distribute Crystal Social privately without going through app stores.

## 🎯 Quick Start

### Windows Users
```bash
# Run the automated build script
build_private.bat
```

### Mac/Linux Users  
```bash
# Make script executable and run
chmod +x build_private.sh
./build_private.sh
```

## 📋 Prerequisites

### Required Setup
1. **Flutter SDK** installed and configured
2. **Firebase project** created with config files
3. **Android signing key** for release builds
4. **iOS Developer Account** (for iOS sideloading)

### API Keys Already Configured ✅
- OneSignal: `6f262379-2f9e-4d15-a378-25e682b6b78d`
- Agora: `5c1b6094e0eb4ec7820ae6b706b85260`
- Spotify: `1288db98cd1e41a19bd18d721df20fae`

## 🔧 Manual Setup Steps

### 1. Firebase Configuration

#### Download Required Files:
```bash
# Android
# Download google-services.json from Firebase Console
# Place in: android/app/google-services.json

# iOS  
# Download GoogleService-Info.plist from Firebase Console
# Add to: ios/Runner/ (in Xcode project)
```

### 2. Android Signing Setup

#### Create Release Keystore:
```bash
# Generate keystore (run once)
keytool -genkey -v -keystore crystal-social-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias crystal-social

# Move keystore to android folder
mv crystal-social-release-key.jks android/
```

#### Update Key Properties:
Edit `android/key.properties` with your actual passwords:
```properties
storePassword=YOUR_ACTUAL_KEYSTORE_PASSWORD
keyPassword=YOUR_ACTUAL_KEY_PASSWORD
keyAlias=crystal-social
storeFile=../crystal-social-release-key.jks
```

### 3. iOS Development Setup

#### Requirements:
- Apple Developer Account ($99/year)
- Xcode installed on macOS
- iOS Development Certificate
- Development Provisioning Profile

#### Device Registration:
1. Get device UDIDs from target devices
2. Register devices in Apple Developer Portal
3. Create/update Development Provisioning Profile
4. Download and install in Xcode

## 🏗️ Building for Distribution

### Android APK Build
```bash
# Clean build
flutter clean
flutter pub get

# Build release APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (Smaller Size)
```bash
# Build App Bundle
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS IPA Build (macOS only)
```bash
# Build iOS
flutter build ios --release

# Then in Xcode:
# 1. Open ios/Runner.xcworkspace
# 2. Select your development team
# 3. Archive (Product → Archive)
# 4. Export for Development Distribution
# 5. Save IPA file
```

## 📱 Distribution Methods

### Android Installation

#### Method 1: Direct APK Install
1. Enable "Install from Unknown Sources" on device
2. Transfer APK file to device
3. Tap APK file to install

#### Method 2: ADB Install
```bash
# Connect device via USB with debugging enabled
adb install path/to/app-release.apk
```

### iOS Installation

#### Method 1: AltStore (Free)
1. Install AltStore on computer and device
2. Use AltStore to sideload IPA file
3. Refresh every 7 days (free account limitation)

#### Method 2: Sideloadly
1. Download Sideloadly
2. Connect device and install IPA
3. More stable than AltStore

#### Method 3: Xcode (Developer Account)
1. Connect device to Mac
2. Open Xcode → Window → Devices and Simulators
3. Drag IPA to device

## 🔐 Security Considerations

### For Distribution
- ✅ **Signed APK/IPA**: Prevents tampering
- ✅ **Firebase Security**: Database rules configured
- ✅ **API Key Security**: Keys embedded securely
- ✅ **SSL/TLS**: All network traffic encrypted

### User Privacy
- All permissions properly described
- User data stays within Firebase project
- No third-party analytics beyond Firebase
- Local data encrypted on device

## 📊 Build Verification

### Test Checklist
- [ ] App launches successfully
- [ ] Push notifications work (OneSignal)
- [ ] Voice/video calls work (Agora)
- [ ] Spotify integration works
- [ ] Firebase authentication works
- [ ] All Crystal Social features functional
- [ ] No crashes or critical errors

### Performance Check
- [ ] App size reasonable (<100MB ideal)
- [ ] Startup time acceptable (<3 seconds)
- [ ] Memory usage normal
- [ ] Battery drain reasonable

## 🚀 Distribution Package

### What to Share with Users

#### Android Package:
```
📁 CrystalSocial-Android/
  ├── CrystalSocial-release.apk (main installation file)
  ├── CrystalSocial-release.aab (alternative, smaller file)
  ├── install-instructions.txt
  └── build-info.txt
```

#### iOS Package:
```
📁 CrystalSocial-iOS/
  ├── CrystalSocial.ipa (main installation file)
  ├── install-instructions.txt
  ├── build-info.txt
  └── sideloading-tools.txt (links to AltStore, Sideloadly)
```

## 📝 User Instructions Template

### Android Installation
```
Crystal Social - Android Installation

1. Enable "Install from Unknown Sources":
   Settings → Security → Unknown Sources → Enable

2. Install the APK:
   - Transfer APK file to your device
   - Tap the APK file
   - Follow installation prompts

3. Grant Permissions:
   - Allow all requested permissions for full functionality
   - Camera: For photos and profile pictures
   - Microphone: For voice messages and calls
   - Storage: For saving images and files

4. Launch and Enjoy!
   - Open Crystal Social
   - Sign up or log in
   - Start connecting with friends!
```

### iOS Installation
```
Crystal Social - iOS Installation (Sideloading)

Requirements:
- iOS 12.0 or later
- Computer with AltStore or Sideloadly installed

Steps:
1. Install AltStore on your computer and device
2. Connect device to computer
3. Use AltStore to install Crystal Social IPA
4. Trust the developer certificate in Settings
5. Launch Crystal Social

Note: Free Apple ID requires renewal every 7 days
Developer account extends to 1 year
```

## 🆘 Troubleshooting

### Common Issues

#### Android
- **"App not installed"**: Enable unknown sources, check storage space
- **"Parse error"**: Re-download APK, ensure device compatibility
- **Permissions issues**: Manually grant permissions in Settings

#### iOS  
- **"Untrusted Developer"**: Go to Settings → General → Device Management → Trust
- **App expires**: Re-install with AltStore/Sideloadly
- **Won't install**: Check iOS version compatibility

### Support Resources
- Build logs in `build/` directory
- Firebase Console for backend issues  
- Device logs for runtime problems
- Contact developer for specific issues

## 🎉 Success!

Your Crystal Social app is now ready for private distribution! Users can install and enjoy all features including:

- ✨ **Social Features**: Chat, groups, profiles, glitter board
- 🔮 **Mystical Features**: Tarot readings, horoscopes, oracle cards
- 🎮 **Virtual Spaces**: Pet care, crystal garden, butterfly garden
- 🏆 **Rewards System**: Achievements, currency earning, shop
- 🎵 **Media Features**: Voice messages, Spotify integration
- 📱 **Real-time Communication**: Voice/video calls via Agora

Your users will have access to the complete Crystal Social experience through private distribution! 🚀✨
