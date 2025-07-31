@echo off
setlocal enabledelayedexpansion

echo ===========================================
echo  Crystal Social - Symlink-Safe Build
echo ===========================================

REM Set custom pub cache to same drive as project
set PUB_CACHE=E:\flutter_cache
echo Setting PUB_CACHE to: %PUB_CACHE%

REM Clean previous build
echo.
echo [1/4] Cleaning previous build...
flutter clean

REM Clear problematic symlinks manually
echo.
echo [2/4] Clearing potential symlink conflicts...
if exist "windows\flutter\ephemeral\.plugin_symlinks" (
    rmdir /s /q "windows\flutter\ephemeral\.plugin_symlinks" 2>nul
)
if exist "linux\flutter\ephemeral\.plugin_symlinks" (
    rmdir /s /q "linux\flutter\ephemeral\.plugin_symlinks" 2>nul
)
if exist "macos\Flutter\ephemeral\.plugin_symlinks" (
    rmdir /s /q "macos\Flutter\ephemeral\.plugin_symlinks" 2>nul
)

REM Get dependencies (ignore symlink warnings)
echo.
echo [3/4] Getting dependencies (ignoring symlink warnings)...
flutter pub get 2>nul || (
    echo Dependencies resolved with warnings - continuing...
)

REM Build APK (skip pub resolution if symlinks failed)
echo.
echo [4/4] Building APK...
flutter build apk --release --target-platform android-arm64 --no-tree-shake-icons --no-pub || (
    echo Fallback: Trying with full pub resolution...
    flutter build apk --release --target-platform android-arm64 --no-tree-shake-icons
)

echo.
echo ===========================================
echo Build process completed!
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo ✅ APK successfully built: build\app\outputs\flutter-apk\app-release.apk
) else (
    echo ❌ APK build failed
    exit /b 1
)
echo ===========================================

pause
