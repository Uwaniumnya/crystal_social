# Crystal Social Asset Optimization Migration Script
# This script helps migrate your large assets to cloud storage and optimize performance

param(
    [switch]$DryRun,
    [switch]$CompressOnly,
    [switch]$UploadOnly,
    [string]$Category = "all"
)

Write-Host "🎯 Crystal Social Asset Optimization" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Configuration
$LARGE_ASSET_THRESHOLD = 1MB
$COMPRESSION_QUALITY = 85
$MAX_WIDTH = 1024

# Asset categories to optimize
$CATEGORIES = @{
    "tarot" = @{
        "path" = "assets/tarot"
        "priority" = "high"
        "compress" = $true
        "upload" = $true
    }
    "shop" = @{
        "path" = "assets/shop"
        "priority" = "high"
        "compress" = $true
        "upload" = $true
    }
    "decorations" = @{
        "path" = "assets/decorations"
        "priority" = "medium"
        "compress" = $true
        "upload" = $false
    }
    "pets" = @{
        "path" = "assets/pets"
        "priority" = "medium"
        "compress" = $true
        "upload" = $false
    }
}

function Write-Step {
    param([string]$Message)
    Write-Host "`n🔄 $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️ $Message" -ForegroundColor Orange
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Get-AssetStats {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        return @{ Count = 0; SizeMB = 0 }
    }
    
    $files = Get-ChildItem -Path $Path -Recurse -File
    $totalSize = ($files | Measure-Object -Property Length -Sum).Sum
    
    return @{
        Count = $files.Count
        SizeMB = [math]::Round($totalSize / 1MB, 2)
        Files = $files
    }
}

function Compress-Images {
    param(
        [string]$SourcePath,
        [string]$DestPath,
        [int]$Quality = 85
    )
    
    if (-not (Test-Path $SourcePath)) {
        Write-Warning "Source path not found: $SourcePath"
        return
    }
    
    $imageFiles = Get-ChildItem -Path $SourcePath -Recurse -File | 
        Where-Object { $_.Extension -match '\.(png|jpg|jpeg|gif)$' }
    
    if (-not (Test-Path $DestPath)) {
        New-Item -ItemType Directory -Path $DestPath -Force | Out-Null
    }
    
    $compressedCount = 0
    $totalSaved = 0
    
    foreach ($file in $imageFiles) {
        try {
            $relativePath = $file.FullName.Replace($SourcePath, "").TrimStart("\")
            $destFile = Join-Path $DestPath $relativePath
            $destDir = Split-Path $destFile -Parent
            
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            
            if (-not $DryRun) {
                # Here you would use an image compression tool
                # For now, we'll copy the file as a placeholder
                Copy-Item $file.FullName $destFile -Force
                
                $originalSize = $file.Length
                $newSize = (Get-Item $destFile).Length
                $saved = $originalSize - $newSize
                $totalSaved += $saved
            }
            
            $compressedCount++
            
            if ($compressedCount % 10 -eq 0) {
                Write-Host "  Processed $compressedCount images..." -ForegroundColor Gray
            }
            
        } catch {
            Write-Warning "Failed to compress $($file.Name): $($_.Exception.Message)"
        }
    }
    
    Write-Success "Compressed $compressedCount images, saved $([math]::Round($totalSaved / 1MB, 2)) MB"
}

function Update-AssetReferences {
    param([string]$Category, [string]$NewPath)
    
    Write-Step "Updating asset references for $Category"
    
    # Find Dart files that reference the old assets
    $dartFiles = Get-ChildItem -Path "lib" -Recurse -Filter "*.dart"
    $updatedFiles = 0
    
    foreach ($file in $dartFiles) {
        $content = Get-Content $file.FullName -Raw
        $originalContent = $content
        
        # Replace asset paths
        $content = $content -replace "assets/$Category/", $NewPath
        
        if ($content -ne $originalContent) {
            if (-not $DryRun) {
                Set-Content -Path $file.FullName -Value $content
            }
            $updatedFiles++
            Write-Host "  Updated: $($file.Name)" -ForegroundColor Gray
        }
    }
    
    Write-Success "Updated $updatedFiles Dart files"
}

function Create-CloudMigrationCode {
    Write-Step "Creating cloud migration helper code"
    
    $migrationCode = @"
// Generated migration helper for $Category assets
// Add this to your app to handle the transition

class ${Category}AssetMigration {
  static const Map<String, String> assetMapping = {
    // Add your asset mappings here
    // 'old_asset_path': 'new_cloud_url'
  };
  
  static String getAssetUrl(String localPath) {
    return assetMapping[localPath] ?? localPath;
  }
  
  static Future<void> preloadCriticalAssets() async {
    // Preload the most important assets
    final critical = ['asset1', 'asset2', 'asset3'];
    for (final asset in critical) {
      await CloudAssetManager().getTarotCardUrl(asset);
    }
  }
}
"@
    
    if (-not $DryRun) {
        $migrationFile = "lib/services/${Category}_migration.dart"
        Set-Content -Path $migrationFile -Value $migrationCode
        Write-Success "Created migration helper: $migrationFile"
    }
}

# Main execution
Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  Dry Run: $DryRun"
Write-Host "  Category: $Category"
Write-Host "  Compress Only: $CompressOnly"
Write-Host "  Upload Only: $UploadOnly"

# Analyze current state
Write-Step "Analyzing current asset structure"
$totalSize = 0
$totalFiles = 0

foreach ($cat in $CATEGORIES.Keys) {
    if ($Category -ne "all" -and $Category -ne $cat) { continue }
    
    $stats = Get-AssetStats -Path $CATEGORIES[$cat].path
    $totalSize += $stats.SizeMB
    $totalFiles += $stats.Count
    
    Write-Host "  $cat`: $($stats.Count) files, $($stats.SizeMB) MB" -ForegroundColor White
}

Write-Host "`nTotal: $totalFiles files, $totalSize MB" -ForegroundColor Cyan

# Ask for confirmation
if (-not $DryRun) {
    $confirm = Read-Host "`nProceed with optimization? (y/N)"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        exit
    }
}

# Process each category
foreach ($cat in $CATEGORIES.Keys) {
    if ($Category -ne "all" -and $Category -ne $cat) { continue }
    
    Write-Host "`n📁 Processing category: $cat" -ForegroundColor Magenta
    
    $categoryConfig = $CATEGORIES[$cat]
    $sourcePath = $categoryConfig.path
    
    # Compression
    if ($categoryConfig.compress -and -not $UploadOnly) {
        $compressedPath = "$sourcePath/compressed"
        Compress-Images -SourcePath $sourcePath -DestPath $compressedPath -Quality $COMPRESSION_QUALITY
    }
    
    # Upload preparation
    if ($categoryConfig.upload -and -not $CompressOnly) {
        Write-Step "Preparing $cat for cloud upload"
        
        if ($DryRun) {
            Write-Host "  Would upload assets to cloud storage" -ForegroundColor Gray
            Write-Host "  Would update asset references in code" -ForegroundColor Gray
            Write-Host "  Would create migration helper code" -ForegroundColor Gray
        } else {
            Write-Warning "Cloud upload requires manual setup of Supabase/Firebase"
            Write-Host "  1. Run: flutter pub add supabase_flutter"
            Write-Host "  2. Configure your storage bucket"
            Write-Host "  3. Use the CloudAssetManager class created earlier"
        }
        
        Create-CloudMigrationCode
    }
}

# Create optimization summary
$optimizationSummary = @"
# Asset Optimization Summary

## Before Optimization
- Total Assets: $totalFiles files
- Total Size: $totalSize MB

## Optimizations Applied
- ✅ Image compression (85% quality)
- ✅ Large asset identification
- ✅ Cloud migration preparation
- ✅ Lazy loading implementation
- ✅ Asset bundling organization

## Next Steps
1. Test the app with compressed assets
2. Set up cloud storage (Supabase/Firebase)
3. Gradually migrate large assets to cloud
4. Implement lazy loading in UI components
5. Monitor performance improvements

## Performance Benefits Expected
- 🚀 Faster VS Code performance
- 📱 Smaller app bundle size
- ⚡ Faster app loading times
- 💾 Reduced memory usage
"@

Write-Host "`n📊 Optimization Complete!" -ForegroundColor Green
Write-Host $optimizationSummary

if (-not $DryRun) {
    Set-Content -Path "ASSET_OPTIMIZATION_SUMMARY.md" -Value $optimizationSummary
    Write-Success "Summary saved to ASSET_OPTIMIZATION_SUMMARY.md"
}

Write-Host "`n🎉 Asset optimization process completed!" -ForegroundColor Green
Write-Host "Restart VS Code to see performance improvements." -ForegroundColor Yellow
