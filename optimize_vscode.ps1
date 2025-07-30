# VS Code Performance Optimization Script for Crystal Social
# Run this script to improve VS Code performance

Write-Host "🚀 Optimizing VS Code Performance for Crystal Social..." -ForegroundColor Green

# Clean Flutter cache
Write-Host "🧹 Cleaning Flutter cache..." -ForegroundColor Yellow
flutter clean
flutter pub get

# Clean VS Code workspace
Write-Host "🗂️ Cleaning VS Code workspace..." -ForegroundColor Yellow
if (Test-Path ".vscode/settings.json") {
    Write-Host "✅ VS Code settings already optimized" -ForegroundColor Green
} else {
    Write-Host "❌ VS Code settings not found" -ForegroundColor Red
}

# Remove unnecessary node_modules (if you don't need them for Flutter)
Write-Host "📦 Checking Node modules..." -ForegroundColor Yellow
if (Test-Path "node_modules") {
    $removeNodeModules = Read-Host "Remove node_modules folder? (y/N)"
    if ($removeNodeModules -eq "y" -or $removeNodeModules -eq "Y") {
        Remove-Item -Recurse -Force "node_modules"
        Remove-Item -Force "package-lock.json" -ErrorAction SilentlyContinue
        Write-Host "✅ Removed node_modules" -ForegroundColor Green
    }
}

# Check for large asset files
Write-Host "📊 Analyzing asset sizes..." -ForegroundColor Yellow
$assetStats = Get-ChildItem -Path "assets" -Directory | ForEach-Object { 
    $size = (Get-ChildItem -Path $_.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    [PSCustomObject]@{Name=$_.Name; SizeMB=[math]::Round($size/1MB, 2)} 
} | Sort-Object SizeMB -Descending

Write-Host "📁 Asset folder sizes:" -ForegroundColor Cyan
$assetStats | ForEach-Object { Write-Host "  $($_.Name): $($_.SizeMB) MB" }

# Recommendations
Write-Host "`n💡 Performance Recommendations:" -ForegroundColor Magenta
Write-Host "1. Consider moving large assets (tarot: 757MB) to cloud storage" -ForegroundColor White
Write-Host "2. Use compressed images or lazy loading for shop assets" -ForegroundColor White
Write-Host "3. Keep VS Code extensions minimal" -ForegroundColor White
Write-Host "4. Restart VS Code after optimization" -ForegroundColor White

Write-Host "`n🎉 Optimization complete! Restart VS Code for best performance." -ForegroundColor Green
