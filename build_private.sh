#!/bin/bash

# Crystal Social Private Distribution Build Script
# This script builds production-ready APK and iOS builds for sideloading

echo "🔮 Crystal Social - Private Distribution Builder"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Error: pubspec.yaml not found. Please run this script from the Flutter project root.${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Pre-build Checks${NC}"

# Check Flutter installation
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter not found. Please install Flutter first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Flutter found: $(flutter --version | head -n1)${NC}"

# Check for Firebase config files
echo -e "\n${BLUE}🔥 Checking Firebase Configuration${NC}"

if [ -f "android/app/google-services.json" ]; then
    echo -e "${GREEN}✅ Android Firebase config found${NC}"
else
    echo -e "${YELLOW}⚠️  Android Firebase config missing (google-services.json)${NC}"
    echo -e "${BLUE}   Download from Firebase Console and place in android/app/${NC}"
fi

if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo -e "${GREEN}✅ iOS Firebase config found${NC}"
else
    echo -e "${YELLOW}⚠️  iOS Firebase config missing (GoogleService-Info.plist)${NC}"
    echo -e "${BLUE}   Download from Firebase Console and add to Xcode project${NC}"
fi

# Check for signing configuration
echo -e "\n${BLUE}🔐 Checking Signing Configuration${NC}"

if [ -f "android/key.properties" ]; then
    echo -e "${GREEN}✅ Android signing configuration found${NC}"
else
    echo -e "${YELLOW}⚠️  Android signing not configured${NC}"
    echo -e "${BLUE}   Create keystore and key.properties file${NC}"
fi

# Clean and get dependencies
echo -e "\n${BLUE}🧹 Cleaning and Getting Dependencies${NC}"
flutter clean
flutter pub get

if [ -d "ios" ]; then
    echo -e "${BLUE}📱 Installing iOS Dependencies${NC}"
    cd ios && pod install && cd ..
fi

# Build Android APK
echo -e "\n${BLUE}🤖 Building Android APK${NC}"
echo -e "${BLUE}Building release APK...${NC}"

if flutter build apk --release; then
    echo -e "${GREEN}✅ Android APK built successfully!${NC}"
    echo -e "${BLUE}📱 APK Location: build/app/outputs/flutter-apk/app-release.apk${NC}"
    
    # Get APK size
    if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
        apk_size=$(du -h "build/app/outputs/flutter-apk/app-release.apk" | cut -f1)
        echo -e "${BLUE}📊 APK Size: $apk_size${NC}"
    fi
else
    echo -e "${RED}❌ Android APK build failed${NC}"
fi

# Build Android App Bundle (optional, for smaller size)
echo -e "\n${BLUE}📦 Building Android App Bundle (AAB)${NC}"
if flutter build appbundle --release; then
    echo -e "${GREEN}✅ Android App Bundle built successfully!${NC}"
    echo -e "${BLUE}📱 AAB Location: build/app/outputs/bundle/release/app-release.aab${NC}"
    
    # Get AAB size
    if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
        aab_size=$(du -h "build/app/outputs/bundle/release/app-release.aab" | cut -f1)
        echo -e "${BLUE}📊 AAB Size: $aab_size${NC}"
    fi
else
    echo -e "${RED}❌ Android App Bundle build failed${NC}"
fi

# Build iOS (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "\n${BLUE}🍎 Building iOS${NC}"
    
    if flutter build ios --release; then
        echo -e "${GREEN}✅ iOS build completed!${NC}"
        echo -e "${BLUE}📱 Next Steps for iOS:${NC}"
        echo -e "${BLUE}   1. Open ios/Runner.xcworkspace in Xcode${NC}"
        echo -e "${BLUE}   2. Select your development team${NC}"
        echo -e "${BLUE}   3. Archive and export for development distribution${NC}"
        echo -e "${BLUE}   4. Share IPA file for sideloading${NC}"
    else
        echo -e "${RED}❌ iOS build failed${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  iOS build skipped (not on macOS)${NC}"
fi

# Create distribution folder
echo -e "\n${BLUE}📁 Creating Distribution Folder${NC}"
mkdir -p "dist"

# Copy APK to distribution folder
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    cp "build/app/outputs/flutter-apk/app-release.apk" "dist/CrystalSocial-v$(flutter --version | head -n1 | cut -d' ' -f2)-release.apk"
    echo -e "${GREEN}✅ APK copied to dist/ folder${NC}"
fi

# Copy AAB to distribution folder
if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    cp "build/app/outputs/bundle/release/app-release.aab" "dist/CrystalSocial-v$(flutter --version | head -n1 | cut -d' ' -f2)-release.aab"
    echo -e "${GREEN}✅ AAB copied to dist/ folder${NC}"
fi

# Generate build info
echo -e "\n${BLUE}📋 Generating Build Information${NC}"
cat > "dist/build-info.txt" << EOF
Crystal Social - Private Distribution Build
==========================================

Build Date: $(date)
Flutter Version: $(flutter --version | head -n1)
Build Type: Release (Private Distribution)

Files Included:
- CrystalSocial-vX.X.X-release.apk (Android APK for sideloading)
- CrystalSocial-vX.X.X-release.aab (Android App Bundle - smaller size)

Installation Instructions:
Android: Enable "Install from Unknown Sources" and install APK
iOS: Use AltStore, Sideloadly, or similar tool to install IPA

Features Enabled:
✅ OneSignal Push Notifications
✅ Agora Voice/Video Calls  
✅ Spotify Integration
✅ Firebase Backend
✅ All Crystal Social Features

Support: Contact developer for any issues
EOF

echo -e "${GREEN}✅ Build information generated${NC}"

# Summary
echo -e "\n${GREEN}🎉 Build Complete!${NC}"
echo -e "${BLUE}📁 Distribution files available in 'dist/' folder${NC}"
echo -e "${BLUE}📱 Ready for private distribution and sideloading${NC}"

if [ -d "dist" ]; then
    echo -e "\n${BLUE}📊 Distribution Summary:${NC}"
    ls -la dist/
fi

echo -e "\n${BLUE}🚀 Next Steps:${NC}"
echo -e "1. Test APK on Android devices"
echo -e "2. For iOS: Complete Xcode archive and export process"  
echo -e "3. Distribute files to your users"
echo -e "4. Provide installation instructions"

echo -e "\n${GREEN}Crystal Social is ready for private distribution! ✨${NC}"
