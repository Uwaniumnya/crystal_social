# Test script for view syntax validation
Write-Host "Validating 03_widgets_views_analytics.sql for syntax issues..." -ForegroundColor Green

$content = Get-Content "03_widgets_views_analytics.sql" -Raw

# Check for CREATE VIEW statements
$viewCreations = [regex]::Matches($content, "CREATE OR REPLACE VIEW", [Text.RegularExpressions.RegexOptions]::IgnoreCase)
Write-Host "Found $($viewCreations.Count) view definitions" -ForegroundColor Cyan

# Check for SELECT statements with ambiguous columns
$suspiciousSelects = [regex]::Matches($content, "SELECT\s+[^A-Z]*\b(user_id|id|created_at)\b(?!\s*as\s)", [Text.RegularExpressions.RegexOptions]::IgnoreCase)
if ($suspiciousSelects.Count -gt 0) {
    Write-Host "⚠️ Found $($suspiciousSelects.Count) potentially ambiguous column references" -ForegroundColor Yellow
} else {
    Write-Host "✓ No obvious ambiguous column references found" -ForegroundColor Green
}

# Check for FULL OUTER JOIN patterns
$fullJoins = [regex]::Matches($content, "FULL OUTER JOIN", [Text.RegularExpressions.RegexOptions]::IgnoreCase)
Write-Host "Found $($fullJoins.Count) FULL OUTER JOIN statements" -ForegroundColor Cyan

# Check for GROUP BY without table prefixes in complex queries
$groupByWithoutPrefix = [regex]::Matches($content, "GROUP BY\s+(?!.*\.)user_id", [Text.RegularExpressions.RegexOptions]::IgnoreCase)
if ($groupByWithoutPrefix.Count -gt 0) {
    Write-Host "⚠️ Found $($groupByWithoutPrefix.Count) GROUP BY clauses without table prefixes" -ForegroundColor Yellow
} else {
    Write-Host "✓ GROUP BY clauses appear to use proper table prefixes" -ForegroundColor Green
}

# Check basic SQL structure
$viewEnds = [regex]::Matches($content, ";[\r\n\s]*(?=--|\$|CREATE)", [Text.RegularExpressions.RegexOptions]::IgnoreCase)
Write-Host "Found $($viewEnds.Count) view statement endings" -ForegroundColor Cyan

Write-Host "`n✓ View syntax validation complete!" -ForegroundColor Green
