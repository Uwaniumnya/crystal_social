# Test script to identify type mismatch errors
Write-Host "Searching for potential text = uuid type mismatches..." -ForegroundColor Green

$content = Get-Content "04_widgets_security_policies.sql" -Raw

# Look for patterns that might cause text = uuid errors
$patterns = @(
    "= message_id",
    "= user_id", 
    "= created_by",
    "= id",
    "= p_user_id",
    "= p_resource_id"
)

foreach ($pattern in $patterns) {
    $matches = [regex]::Matches($content, $pattern, [Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($matches.Count -gt 0) {
        Write-Host "Found $($matches.Count) instances of '$pattern'" -ForegroundColor Cyan
    }
}

# Check for specific problematic comparisons
$problematicPatterns = @(
    "TEXT.*=.*UUID",
    "UUID.*=.*TEXT",
    "p_resource_id\s*=",
    "resource_id.*="
)

foreach ($pattern in $problematicPatterns) {
    $matches = [regex]::Matches($content, $pattern, [Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($matches.Count -gt 0) {
        Write-Host "⚠️ Found $($matches.Count) potentially problematic pattern: '$pattern'" -ForegroundColor Yellow
    }
}

Write-Host "`nChecking for function parameter usage..." -ForegroundColor Cyan
$resourceIdUsage = [regex]::Matches($content, "p_resource_id", [Text.RegularExpressions.RegexOptions]::IgnoreCase)
Write-Host "Found $($resourceIdUsage.Count) uses of p_resource_id parameter" -ForegroundColor White

Write-Host "`nType mismatch analysis complete!" -ForegroundColor Green
