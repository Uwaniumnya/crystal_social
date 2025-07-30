# Comprehensive type mismatch detection script
Write-Host "Performing comprehensive type mismatch analysis..." -ForegroundColor Green

$content = Get-Content "04_widgets_security_policies.sql" -Raw

# Extract all comparison operations that could cause text = uuid issues
$lines = $content -split "`r?`n"
$lineNumber = 0
$issues = @()

foreach ($line in $lines) {
    $lineNumber++
    
    # Look for potential problematic patterns
    if ($line -match "=\s*auth\.uid\(\)" -and $line -notmatch "user_id\s*=\s*auth\.uid\(\)" -and $line -notmatch "created_by\s*=\s*auth\.uid\(\)") {
        $issues += "Line $lineNumber`: Potential type mismatch - $($line.Trim())"
    }
    
    if ($line -match "auth\.uid\(\)\s*=" -and $line -notmatch "auth\.uid\(\)\s*=\s*user_id" -and $line -notmatch "auth\.uid\(\)\s*=\s*created_by") {
        $issues += "Line $lineNumber`: Potential type mismatch - $($line.Trim())"
    }
    
    # Check for comparisons with literal strings that should be UUIDs
    if ($line -match "=\s*'[a-f0-9\-]{36}'" -or $line -match "'[a-f0-9\-]{36}'\s*=") {
        $issues += "Line $lineNumber`: UUID string literal - $($line.Trim())"
    }
    
    # Check for role comparisons
    if ($line -match "auth\.role\(\)" -and $line -notmatch "auth\.role\(\)\s*=\s*'service_role'") {
        $issues += "Line $lineNumber`: Potential auth.role() issue - $($line.Trim())"
    }
}

if ($issues.Count -gt 0) {
    Write-Host "`n⚠️ Found $($issues.Count) potential type mismatch issues:" -ForegroundColor Yellow
    foreach ($issue in $issues) {
        Write-Host "  $issue" -ForegroundColor Red
    }
} else {
    Write-Host "✓ No obvious type mismatch patterns found" -ForegroundColor Green
}

# Check specific function calls that might have type issues
$functionCalls = [regex]::Matches($content, "log_widget_security_event\s*\([^)]+\)", [Text.RegularExpressions.RegexOptions]::Singleline)
Write-Host "`nFound $($functionCalls.Count) calls to log_widget_security_event" -ForegroundColor Cyan

$triggerCalls = [regex]::Matches($content, "INSERT INTO widget_security_events", [Text.RegularExpressions.RegexOptions]::IgnoreCase)
Write-Host "Found $($triggerCalls.Count) direct inserts to widget_security_events" -ForegroundColor Cyan

Write-Host "`nType mismatch analysis complete!" -ForegroundColor Green
