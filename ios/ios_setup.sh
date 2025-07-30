#!/bin/bash

# Crystal Social iOS Setup Script
# This script helps configure the iOS project for development and deployment

echo "🍎 Crystal Social iOS Configuration Script"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're in the correct directory
if [ ! -f "Info.plist" ]; then
    echo -e "${RED}❌ Error: Info.plist not found. Please run this script from the ios/Runner directory.${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Checking iOS configuration...${NC}"

# Function to check if a key exists in Info.plist
check_plist_key() {
    local key=$1
    local friendly_name=$2
    
    if /usr/libexec/PlistBuddy -c "Print :$key" Info.plist >/dev/null 2>&1; then
        echo -e "${GREEN}✅ $friendly_name configured${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  $friendly_name not configured${NC}"
        return 1
    fi
}

# Check essential permissions
echo -e "\n${BLUE}🔐 Checking Privacy Permissions:${NC}"
check_plist_key "NSCameraUsageDescription" "Camera Permission"
check_plist_key "NSMicrophoneUsageDescription" "Microphone Permission"
check_plist_key "NSPhotoLibraryUsageDescription" "Photo Library Permission"
check_plist_key "NSLocationWhenInUseUsageDescription" "Location Permission"
check_plist_key "NSContactsUsageDescription" "Contacts Permission"

# Check URL schemes
echo -e "\n${BLUE}🔗 Checking URL Schemes:${NC}"
if /usr/libexec/PlistBuddy -c "Print :CFBundleURLTypes:0:CFBundleURLSchemes:0" Info.plist >/dev/null 2>&1; then
    scheme=$(/usr/libexec/PlistBuddy -c "Print :CFBundleURLTypes:0:CFBundleURLSchemes:0" Info.plist)
    echo -e "${GREEN}✅ URL Scheme configured: $scheme${NC}"
else
    echo -e "${YELLOW}⚠️  URL Schemes not configured${NC}"
fi

# Check background modes
echo -e "\n${BLUE}🔄 Checking Background Modes:${NC}"
if /usr/libexec/PlistBuddy -c "Print :UIBackgroundModes" Info.plist >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Background modes configured${NC}"
    # Count background modes
    count=$(/usr/libexec/PlistBuddy -c "Print :UIBackgroundModes" Info.plist | grep -c "^    ")
    echo -e "${BLUE}   📊 Number of background modes: $count${NC}"
else
    echo -e "${YELLOW}⚠️  Background modes not configured${NC}"
fi

# Check app transport security
echo -e "\n${BLUE}🔒 Checking App Transport Security:${NC}"
check_plist_key "NSAppTransportSecurity" "App Transport Security"

# Check for placeholder values that need to be replaced
echo -e "\n${BLUE}🔧 Checking for Placeholder Values:${NC}"
placeholder_count=0

if grep -q "your_onesignal_app_id_here" Info.plist; then
    echo -e "${YELLOW}⚠️  OneSignal App ID needs to be configured${NC}"
    ((placeholder_count++))
fi

if grep -q "your_agora_app_id_here" Info.plist; then
    echo -e "${YELLOW}⚠️  Agora App ID needs to be configured${NC}"
    ((placeholder_count++))
fi

if grep -q "your_spotify_client_id_here" Info.plist; then
    echo -e "${YELLOW}⚠️  Spotify Client ID needs to be configured${NC}"
    ((placeholder_count++))
fi

if [ $placeholder_count -eq 0 ]; then
    echo -e "${GREEN}✅ No placeholder values found${NC}"
else
    echo -e "${YELLOW}⚠️  $placeholder_count placeholder values need to be configured${NC}"
fi

# Check iOS deployment target
echo -e "\n${BLUE}📱 Checking iOS Deployment Target:${NC}"
cd ..
if [ -f "Podfile" ]; then
    if grep -q "platform :ios, '12.0'" Podfile; then
        echo -e "${GREEN}✅ iOS deployment target set to 12.0${NC}"
    else
        echo -e "${YELLOW}⚠️  iOS deployment target not set to 12.0${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Podfile not found${NC}"
fi

# Check if Firebase is configured
echo -e "\n${BLUE}🔥 Checking Firebase Configuration:${NC}"
if [ -f "GoogleService-Info.plist" ]; then
    echo -e "${GREEN}✅ GoogleService-Info.plist found${NC}"
else
    echo -e "${YELLOW}⚠️  GoogleService-Info.plist not found (add from Firebase Console)${NC}"
fi

# Summary
echo -e "\n${BLUE}📊 Configuration Summary:${NC}"
echo "=================================="

# Check if pods need to be installed
if [ -d "Pods" ]; then
    echo -e "${GREEN}✅ CocoaPods dependencies installed${NC}"
else
    echo -e "${YELLOW}⚠️  CocoaPods dependencies not installed${NC}"
    echo -e "${BLUE}💡 Run 'pod install' to install dependencies${NC}"
fi

# Provide next steps
echo -e "\n${BLUE}🚀 Next Steps:${NC}"
echo "1. Replace placeholder values in Info.plist with actual API keys"
echo "2. Add GoogleService-Info.plist from Firebase Console"
echo "3. Run 'pod install' if dependencies are not installed"
echo "4. Test app permissions on a physical device"
echo "5. Configure App Store Connect for production deployment"

echo -e "\n${GREEN}🎉 iOS configuration check complete!${NC}"
echo -e "${BLUE}📖 See IOS_CONFIGURATION.md for detailed documentation${NC}"
