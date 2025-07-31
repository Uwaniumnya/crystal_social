# Auto Git Commit Script with Incremental Versioning
# Usage: Run this script to automatically add, commit with incremental version, and push

# Define the version file path
$versionFile = "commit_version.txt"

# Function to read current version
function Get-CurrentVersion {
    if (Test-Path $versionFile) {
        $versionContent = Get-Content $versionFile -Raw
        $versionString = $versionContent.Trim()
        try {
            return [double]::Parse($versionString, [System.Globalization.CultureInfo]::InvariantCulture)
        } catch {
            Write-Host "Error parsing version from file, resetting to 1.0" -ForegroundColor Yellow
            return 1.0
        }
    } else {
        # Start with version 1.0 if file doesn't exist
        return 1.0
    }
}

# Function to increment version
function Get-NextVersion {
    param([double]$currentVersion)
    
    $newVersion = $currentVersion + 0.1
    
    # Round to one decimal place to avoid floating point precision issues
    $newVersion = [Math]::Round($newVersion, 1)
    
    return $newVersion
}

# Function to save version
function Set-CurrentVersion {
    param([double]$version)
    $versionString = $version.ToString("F1", [System.Globalization.CultureInfo]::InvariantCulture)
    $versionString | Out-File -FilePath $versionFile -Encoding UTF8 -NoNewline
}

try {
    # Get current version
    $currentVersion = Get-CurrentVersion
    Write-Host "Current version: $currentVersion" -ForegroundColor Cyan
    
    # Debug: Show what's in the version file
    if (Test-Path $versionFile) {
        $fileContent = Get-Content $versionFile -Raw
        Write-Host "Version file content: '$fileContent'" -ForegroundColor DarkGray
    }
    
    # Calculate next version
    $nextVersion = Get-NextVersion -currentVersion $currentVersion
    Write-Host "Next version: $nextVersion" -ForegroundColor Green
    
    # Step 1: Git add .
    Write-Host "Adding files to git..." -ForegroundColor Yellow
    git add .
    
    if ($LASTEXITCODE -ne 0) {
        throw "Git add failed with exit code $LASTEXITCODE"
    }
    
    Write-Host "Files added successfully!" -ForegroundColor Green
    
    # Step 2: Git commit with incremental version
    Write-Host "Committing with version $nextVersion..." -ForegroundColor Yellow
    git commit -m "$nextVersion"
    
    if ($LASTEXITCODE -ne 0) {
        throw "Git commit failed with exit code $LASTEXITCODE"
    }
    
    Write-Host "Commit successful!" -ForegroundColor Green
    
    # Step 3: Git push origin main
    Write-Host "Pushing to origin main..." -ForegroundColor Yellow
    git push origin main
    
    if ($LASTEXITCODE -ne 0) {
        throw "Git push failed with exit code $LASTEXITCODE"
    }
    
    Write-Host "Push successful!" -ForegroundColor Green
    
    # Update version file for next run
    Set-CurrentVersion -version $nextVersion
    Write-Host "Version updated to $nextVersion for next run" -ForegroundColor Cyan
    
    Write-Host "`nAll operations completed successfully!" -ForegroundColor Green
    Write-Host "- Files added to git" -ForegroundColor White
    Write-Host "- Committed with message: '$nextVersion'" -ForegroundColor White
    Write-Host "- Pushed to origin main" -ForegroundColor White
    Write-Host "- Next version will be: $([Math]::Round($nextVersion + 0.1, 1))" -ForegroundColor White
    
} catch {
    Write-Host "Error occurred: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Pause to see results (optional - remove if you don't want the pause)
Write-Host "`nPress any key to continue..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
