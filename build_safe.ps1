#!/usr/bin/env pwsh

Write-Host "==========================================="
Write-Host " Crystal Social - Symlink-Safe Build"
Write-Host "==========================================="

# Set custom pub cache to same drive as project
$env:PUB_CACHE = "E:\flutter_cache"
Write-Host "Setting PUB_CACHE to: $env:PUB_CACHE"

# Clean previous build
Write-Host ""
Write-Host "[1/4] Cleaning previous build..."
flutter clean

# Clear problematic symlinks manually
Write-Host ""
Write-Host "[2/4] Clearing potential symlink conflicts..."
$symlinkPaths = @(
    "windows\flutter\ephemeral\.plugin_symlinks",
    "linux\flutter\ephemeral\.plugin_symlinks", 
    "macos\Flutter\ephemeral\.plugin_symlinks"
)

foreach ($path in $symlinkPaths) {
    if (Test-Path $path) {
        Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Cleared: $path"
    }
}

# Get dependencies (ignore symlink warnings)
Write-Host ""
Write-Host "[3/4] Getting dependencies (ignoring symlink warnings)..."
try {
    flutter pub get 2>$null
    Write-Host "Dependencies resolved successfully"
} catch {
    Write-Host "Dependencies resolved with warnings - continuing..."
}

# Build APK (skip pub resolution if symlinks failed)
Write-Host ""
Write-Host "[4/4] Building APK..."
try {
    flutter build apk --release --target-platform android-arm64 --no-tree-shake-icons --no-pub
    $success = $?
} catch {
    Write-Host "Fallback: Trying with full pub resolution..."
    flutter build apk --release --target-platform android-arm64 --no-tree-shake-icons
    $success = $?
}

Write-Host ""
Write-Host "==========================================="
if ((Test-Path "build\app\outputs\flutter-apk\app-release.apk") -and $success) {
    Write-Host "✅ APK successfully built: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
    $apkSize = (Get-Item "build\app\outputs\flutter-apk\app-release.apk").Length / 1MB
    Write-Host "📦 APK Size: $([math]::Round($apkSize, 1)) MB" -ForegroundColor Cyan
} else {
    Write-Host "❌ APK build failed" -ForegroundColor Red
    exit 1
}
Write-Host "==========================================="
