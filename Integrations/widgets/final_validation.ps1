# Final validation for ambiguous column references
Write-Host "Final validation for ambiguous column reference fixes..." -ForegroundColor Green

$content = Get-Content "03_widgets_views_analytics.sql" -Raw

# Test specific fixes we made
Write-Host "`nChecking specific fixes:" -ForegroundColor Cyan

# Check emoticon_stats fix
if ($content -match "SELECT\s+ce\.user_id,\s+COUNT\(DISTINCT ce\.id\) as custom_emoticons") {
    Write-Host "✓ emoticon_stats subquery properly uses ce.user_id" -ForegroundColor Green
} else {
    Write-Host "✗ emoticon_stats subquery fix not found" -ForegroundColor Red
}

# Check message_stats fix  
if ($content -match "SELECT\s+mb\.user_id,\s+COUNT\(DISTINCT mb\.id\) as messages_sent") {
    Write-Host "✓ message_stats subquery properly uses mb.user_id" -ForegroundColor Green
} else {
    Write-Host "✗ message_stats subquery fix not found" -ForegroundColor Red
}

# Check for remaining ambiguous references in FULL OUTER JOINs
$problematicJoins = [regex]::Matches($content, "GROUP BY\s+user_id.*FULL OUTER JOIN", [Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [Text.RegularExpressions.RegexOptions]::Singleline)
if ($problematicJoins.Count -eq 0) {
    Write-Host "✓ No ambiguous user_id references in FULL OUTER JOIN queries" -ForegroundColor Green
} else {
    Write-Host "✗ Found $($problematicJoins.Count) potentially problematic FULL OUTER JOIN queries" -ForegroundColor Red
}

Write-Host "`n✓ Ambiguous column reference validation complete!" -ForegroundColor Green
