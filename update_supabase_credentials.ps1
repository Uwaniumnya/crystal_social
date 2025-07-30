# Crystal Social: Supabase Credentials Update Script
# =====================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$NewProjectUrl,
    
    [Parameter(Mandatory=$true)]
    [string]$NewAnonKey
)

Write-Host "Crystal Social: Updating Supabase Credentials" -ForegroundColor Cyan
Write-Host "=============================================="
Write-Host ""
Write-Host "New Project URL: $NewProjectUrl" -ForegroundColor Green
Write-Host "New Anon Key: $($NewAnonKey.Substring(0,20))..." -ForegroundColor Green
Write-Host ""

# Validate inputs
if (-not $NewProjectUrl.Contains("supabase.co")) {
    Write-Host "Error: Project URL must contain 'supabase.co'" -ForegroundColor Red
    exit 1
}

if (-not $NewAnonKey.StartsWith("eyJ")) {
    Write-Host "Error: Anon key should start with 'eyJ'" -ForegroundColor Red
    exit 1
}

# Extract old credentials for replacement
$oldUrl = "https://syymhweqggvpdseugwvi.supabase.co"
$oldKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN5eW1od2VxZ2d2cGRzZXVnd3ZpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI1ODUwMTgsImV4cCI6MjA2ODE2MTAxOH0.5sQ0UH_FLR6UxC9WR7UOz0v6wrFW8SUsJA0dW8iKzwY"

Write-Host "Updating files..." -ForegroundColor Yellow

# File 1: Main Environment Configuration
$envConfigPath = "lib\config\environment_config.dart"
if (Test-Path $envConfigPath) {
    Write-Host "📂 Updating $envConfigPath" -ForegroundColor White
    
    $content = Get-Content $envConfigPath -Raw
    $content = $content -replace [regex]::Escape($oldUrl), $NewProjectUrl
    $content = $content -replace [regex]::Escape($oldKey), $NewAnonKey
    Set-Content $envConfigPath $content -NoNewline
    
    Write-Host "   ✅ Environment config updated" -ForegroundColor Green
} else {
    Write-Host "   ⚠️ File not found: $envConfigPath" -ForegroundColor Yellow
}

# File 2: Shop Sync Configuration  
$shopSyncPath = "lib\rewards\shop_sync_main.dart"
if (Test-Path $shopSyncPath) {
    Write-Host "📂 Updating $shopSyncPath" -ForegroundColor White
    
    $content = Get-Content $shopSyncPath -Raw
    $content = $content -replace [regex]::Escape($oldUrl), $NewProjectUrl
    $content = $content -replace [regex]::Escape($oldKey), $NewAnonKey
    Set-Content $shopSyncPath $content -NoNewline
    
    Write-Host "   ✅ Shop sync config updated" -ForegroundColor Green
} else {
    Write-Host "   ⚠️ File not found: $shopSyncPath" -ForegroundColor Yellow
}

# File 3: Sticker Picker URLs
$stickerPickerPath = "lib\widgets\sticker_picker.dart"
if (Test-Path $stickerPickerPath) {
    Write-Host "📂 Updating $stickerPickerPath" -ForegroundColor White
    
    $content = Get-Content $stickerPickerPath -Raw
    $content = $content -replace [regex]::Escape($oldUrl), $NewProjectUrl
    Set-Content $stickerPickerPath $content -NoNewline
    
    Write-Host "   ✅ Sticker picker URLs updated" -ForegroundColor Green
} else {
    Write-Host "   ⚠️ File not found: $stickerPickerPath" -ForegroundColor Yellow
}

# File 4: Chat Screen Agora URLs (update placeholder)
$chatScreenPath = "lib\chat\chat_screen.dart"
if (Test-Path $chatScreenPath) {
    Write-Host "📂 Updating $chatScreenPath" -ForegroundColor White
    
    $content = Get-Content $chatScreenPath -Raw
    $content = $content -replace "https://your-supabase-url.supabase.co", $NewProjectUrl
    Set-Content $chatScreenPath $content -NoNewline
    
    Write-Host "   ✅ Chat screen URLs updated" -ForegroundColor Green
} else {
    Write-Host "   ⚠️ File not found: $chatScreenPath" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=============================================="
Write-Host "✅ CREDENTIAL UPDATE COMPLETE!" -ForegroundColor Green
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Go to your new Supabase project SQL Editor" -ForegroundColor White
Write-Host "2. Import SQL files in this order:" -ForegroundColor White
Write-Host "   - CLEAN_001_FOUNDATION.sql" -ForegroundColor Cyan
Write-Host "   - CLEAN_002_CHAT_SYSTEM.sql" -ForegroundColor Cyan
Write-Host "   - CLEAN_003_REWARDS_ECONOMY.sql" -ForegroundColor Cyan
Write-Host "   - CLEAN_004_NOTIFICATIONS_SOCIAL.sql" -ForegroundColor Cyan
Write-Host "3. Build and test your app!" -ForegroundColor White
Write-Host ""
Write-Host "Your app is now connected to the new Supabase project! 🚀" -ForegroundColor Green
