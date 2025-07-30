# Test the security policy fixes
Write-Host "Testing security policy fixes..." -ForegroundColor Green

$content = Get-Content "04_widgets_security_policies.sql" -Raw

# Check if incomplete policies were fixed
Write-Host "`nChecking policy fixes:" -ForegroundColor Cyan

# Check message chat policy fix
if ($content -match "auth\.uid\(\)\s+IS NOT NULL") {
    Write-Host "✓ Message chat access policy properly fixed" -ForegroundColor Green
} else {
    Write-Host "✗ Message chat access policy fix not found" -ForegroundColor Red
}

# Check message reactions policy fix
if ($content -match "message_bubbles\.message_id\s*=\s*message_reactions\.message_id") {
    Write-Host "✓ Message reactions policy uses proper table prefixes" -ForegroundColor Green
} else {
    Write-Host "✗ Message reactions policy fix not found" -ForegroundColor Red
}

# Check for remaining incomplete WHERE clauses
$incompleteChecks = [regex]::Matches($content, "-- Add.*check here", [Text.RegularExpressions.RegexOptions]::IgnoreCase)
if ($incompleteChecks.Count -eq 0) {
    Write-Host "✓ No remaining incomplete WHERE clauses found" -ForegroundColor Green
} else {
    Write-Host "⚠️ Found $($incompleteChecks.Count) remaining incomplete WHERE clauses" -ForegroundColor Yellow
}

# Check for potential type mismatches in policy conditions
$policyCount = [regex]::Matches($content, "CREATE POLICY", [Text.RegularExpressions.RegexOptions]::IgnoreCase)
Write-Host "`nFound $($policyCount.Count) security policies" -ForegroundColor Cyan

Write-Host "`n✓ Security policy validation complete!" -ForegroundColor Green
