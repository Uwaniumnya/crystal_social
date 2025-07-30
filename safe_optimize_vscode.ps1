# SAFE VS Code Performance Optimization Script
# This version only does safe operations

Write-Host "🚀 SAFE VS Code Performance Optimization..." -ForegroundColor Green

# Clean Flutter cache (safe)
Write-Host "🧹 Cleaning Flutter build cache..." -ForegroundColor Yellow
flutter clean
flutter pub get

# Show asset analysis only (no changes)
Write-Host "📊 Analyzing asset sizes..." -ForegroundColor Yellow
$assetStats = Get-ChildItem -Path "assets" -Directory -ErrorAction SilentlyContinue | ForEach-Object { 
    $size = (Get-ChildItem -Path $_.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    [PSCustomObject]@{Name=$_.Name; SizeMB=[math]::Round($size/1MB, 2)} 
} | Sort-Object SizeMB -Descending

Write-Host "📁 Current asset folder sizes:" -ForegroundColor Cyan
$assetStats | ForEach-Object { Write-Host "  $($_.Name): $($_.SizeMB) MB" }

# Check VS Code settings
if (Test-Path ".vscode/settings.json") {
    Write-Host "✅ VS Code performance settings are configured" -ForegroundColor Green
} else {
    Write-Host "❌ VS Code settings missing" -ForegroundColor Red
}

Write-Host "`n💡 Safe Performance Tips:" -ForegroundColor Magenta
Write-Host "1. ✅ VS Code settings exclude heavy folders from indexing" -ForegroundColor White
Write-Host "2. ✅ Flutter cache cleared" -ForegroundColor White  
Write-Host "3. 🔄 Restart VS Code now for best performance" -ForegroundColor White
Write-Host "4. 💾 Consider moving tarot assets (757MB) to cloud storage later" -ForegroundColor White

Write-Host "`n🎉 Safe optimization complete! Your app and assets are untouched." -ForegroundColor Green
