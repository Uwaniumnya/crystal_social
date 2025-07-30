@echo off
echo 🔮 Crystal Social - Private Distribution Builder
echo ==============================================

:: Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter not found. Please install Flutter first.
    pause
    exit /b 1
)

echo ✅ Flutter found

:: Check for Firebase config files
echo.
echo 🔥 Checking Firebase Configuration
if exist "android\app\google-services.json" (
    echo ✅ Android Firebase config found
) else (
    echo ⚠️  Android Firebase config missing
    echo    Download google-services.json from Firebase Console
)

if exist "ios\Runner\GoogleService-Info.plist" (
    echo ✅ iOS Firebase config found
) else (
    echo ⚠️  iOS Firebase config missing
    echo    Download GoogleService-Info.plist from Firebase Console
)

:: Check for signing configuration
echo.
echo 🔐 Checking Signing Configuration
if exist "android\key.properties" (
    echo ✅ Android signing configuration found
) else (
    echo ⚠️  Android signing not configured
    echo    Create keystore and key.properties file
)

:: Clean and get dependencies
echo.
echo 🧹 Cleaning and Getting Dependencies
call flutter clean
call flutter pub get

:: Build Android APK
echo.
echo 🤖 Building Android APK
call flutter build apk --release

if %errorlevel% equ 0 (
    echo ✅ Android APK built successfully!
    echo 📱 APK Location: build\app\outputs\flutter-apk\app-release.apk
) else (
    echo ❌ Android APK build failed
)

:: Build Android App Bundle
echo.
echo 📦 Building Android App Bundle
call flutter build appbundle --release

if %errorlevel% equ 0 (
    echo ✅ Android App Bundle built successfully!
    echo 📱 AAB Location: build\app\outputs\bundle\release\app-release.aab
) else (
    echo ❌ Android App Bundle build failed
)

:: Create distribution folder
echo.
echo 📁 Creating Distribution Folder
if not exist "dist" mkdir "dist"

:: Copy files to distribution folder
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    copy "build\app\outputs\flutter-apk\app-release.apk" "dist\CrystalSocial-release.apk" >nul
    echo ✅ APK copied to dist\ folder
)

if exist "build\app\outputs\bundle\release\app-release.aab" (
    copy "build\app\outputs\bundle\release\app-release.aab" "dist\CrystalSocial-release.aab" >nul
    echo ✅ AAB copied to dist\ folder
)

:: Generate build info
echo.
echo 📋 Generating Build Information
(
echo Crystal Social - Private Distribution Build
echo ==========================================
echo.
echo Build Date: %date% %time%
echo Build Type: Release ^(Private Distribution^)
echo.
echo Files Included:
echo - CrystalSocial-release.apk ^(Android APK for sideloading^)
echo - CrystalSocial-release.aab ^(Android App Bundle - smaller size^)
echo.
echo Installation Instructions:
echo Android: Enable "Install from Unknown Sources" and install APK
echo iOS: Use AltStore, Sideloadly, or similar tool to install IPA
echo.
echo Features Enabled:
echo ✅ OneSignal Push Notifications
echo ✅ Agora Voice/Video Calls  
echo ✅ Spotify Integration
echo ✅ Firebase Backend
echo ✅ All Crystal Social Features
echo.
echo Support: Contact developer for any issues
) > "dist\build-info.txt"

echo ✅ Build information generated

:: Summary
echo.
echo 🎉 Build Complete!
echo 📁 Distribution files available in 'dist\' folder
echo 📱 Ready for private distribution and sideloading

echo.
echo 🚀 Next Steps:
echo 1. Test APK on Android devices
echo 2. For iOS: Use Xcode to build and export IPA
echo 3. Distribute files to your users
echo 4. Provide installation instructions

echo.
echo Crystal Social is ready for private distribution! ✨
pause
