# Fix all auth.uid() comparisons with explicit UUID casting
Write-Host "Adding UUID casting to all auth.uid() comparisons..." -ForegroundColor Green

$content = Get-Content "04_widgets_security_policies.sql" -Raw

# Replace auth.uid() = user_id with auth.uid()::UUID = user_id
$content = $content -replace "auth\.uid\(\)\s*=\s*user_id", "auth.uid()::UUID = user_id"

# Replace user_id = auth.uid() with user_id = auth.uid()::UUID
$content = $content -replace "user_id\s*=\s*auth\.uid\(\)", "user_id = auth.uid()::UUID"

# Replace auth.uid() = created_by with auth.uid()::UUID = created_by
$content = $content -replace "auth\.uid\(\)\s*=\s*created_by", "auth.uid()::UUID = created_by"

# Replace created_by = auth.uid() with created_by = auth.uid()::UUID
$content = $content -replace "created_by\s*=\s*auth\.uid\(\)", "created_by = auth.uid()::UUID"

# Also fix the message bubbles comparison
$content = $content -replace "message_bubbles\.user_id\s*=\s*auth\.uid\(\)", "message_bubbles.user_id = auth.uid()::UUID"

# Also fix the u.id comparisons in auth.users subqueries
$content = $content -replace "u\.id\s*=\s*auth\.uid\(\)", "u.id = auth.uid()::UUID"

Set-Content -Path "04_widgets_security_policies.sql" -Value $content

Write-Host "✓ Added UUID casting to all auth.uid() comparisons" -ForegroundColor Green

# Verify the changes
$updatedContent = Get-Content "04_widgets_security_policies.sql" -Raw
$castingCount = [regex]::Matches($updatedContent, "auth\.uid\(\)::UUID", [Text.RegularExpressions.RegexOptions]::IgnoreCase)
Write-Host "Found $($castingCount.Count) auth.uid()::UUID casts in file" -ForegroundColor Cyan

$remainingUncast = [regex]::Matches($updatedContent, "auth\.uid\(\)\s*=", [Text.RegularExpressions.RegexOptions]::IgnoreCase)
Write-Host "Remaining uncast auth.uid() comparisons: $($remainingUncast.Count)" -ForegroundColor Cyan

Write-Host "`nUUID casting fix complete!" -ForegroundColor Green
