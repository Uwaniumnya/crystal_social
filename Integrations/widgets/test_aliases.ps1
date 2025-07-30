# Test the table alias fixes
Write-Host "Testing table alias fixes..." -ForegroundColor Green

$content = Get-Content "04_widgets_security_policies.sql" -Raw

# Check if all auth.users references now have aliases
$unaliasedUsers = [regex]::Matches($content, "FROM auth\.users\s+WHERE", [Text.RegularExpressions.RegexOptions]::IgnoreCase)
if ($unaliasedUsers.Count -eq 0) {
    Write-Host "✓ All auth.users references now have table aliases" -ForegroundColor Green
} else {
    Write-Host "⚠️ Found $($unaliasedUsers.Count) auth.users references without aliases" -ForegroundColor Yellow
}

# Check for proper alias usage
$aliasedUsers = [regex]::Matches($content, "FROM auth\.users u", [Text.RegularExpressions.RegexOptions]::IgnoreCase)
Write-Host "Found $($aliasedUsers.Count) properly aliased auth.users references" -ForegroundColor Cyan

# Check for u.id usage
$uidReferences = [regex]::Matches($content, "u\.id\s*=\s*auth\.uid\(\)", [Text.RegularExpressions.RegexOptions]::IgnoreCase)
Write-Host "Found $($uidReferences.Count) explicit u.id = auth.uid() comparisons" -ForegroundColor Cyan

Write-Host "`n✓ Table alias validation complete!" -ForegroundColor Green
