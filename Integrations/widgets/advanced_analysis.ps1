# Advanced type mismatch detector
Write-Host "Running advanced type mismatch detection..." -ForegroundColor Green

$content = Get-Content "04_widgets_security_policies.sql" -Raw
$lines = $content -split "`r?`n"
$lineNumber = 0
$issues = @()

foreach ($line in $lines) {
    $lineNumber++
    
    # Look for any equality comparisons that might involve mixed types
    if ($line -match "=") {
        # Check for auth.uid() comparisons
        if ($line -match "auth\.uid\(\)\s*=\s*[^u]" -or $line -match "[^y]\s*=\s*auth\.uid\(\)") {
            if ($line -notmatch "user_id\s*=\s*auth\.uid\(\)" -and $line -notmatch "created_by\s*=\s*auth\.uid\(\)" -and $line -notmatch "u\.id\s*=\s*auth\.uid\(\)") {
                $issues += "Line $lineNumber`: Potential auth.uid() type mismatch - $($line.Trim())"
            }
        }
        
        # Check for string literals being compared to potential UUID columns
        if ($line -match "=\s*'[^']*'" -and $line -notmatch "role|event_type|widget_type|action_type|severity|info|warning|error|critical|admin|moderator|analyst|developer|service_role") {
            $issues += "Line $lineNumber`: String literal comparison - $($line.Trim())"
        }
        
        # Check for role comparisons that might be problematic
        if ($line -match "auth\.role\(\)" -and $line -notmatch "'service_role'") {
            $issues += "Line $lineNumber`: auth.role() usage - $($line.Trim())"
        }
    }
    
    # Check for INSERT statements that might have type mismatches
    if ($line -match "INSERT INTO" -or $line -match "VALUES") {
        if ($line -match "NEW\." -and $line -notmatch "NEW\.user_id" -and $line -notmatch "NEW\.widget_type") {
            $issues += "Line $lineNumber`: NEW record field usage - $($line.Trim())"
        }
    }
}

if ($issues.Count -gt 0) {
    Write-Host "`n⚠️ Found $($issues.Count) potential issues:" -ForegroundColor Yellow
    foreach ($issue in $issues) {
        Write-Host "  $issue" -ForegroundColor Red
    }
} else {
    Write-Host "✓ No issues detected" -ForegroundColor Green
}

# Check for table alias consistency
$authUsersPattern = [regex]::Matches($content, "auth\.users[^u]", [Text.RegularExpressions.RegexOptions]::IgnoreCase)
if ($authUsersPattern.Count -gt 0) {
    Write-Host "`n⚠️ Found $($authUsersPattern.Count) auth.users references without alias" -ForegroundColor Yellow
}

Write-Host "`nAdvanced analysis complete!" -ForegroundColor Green
