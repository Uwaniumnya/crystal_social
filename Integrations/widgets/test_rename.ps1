# Test the function name conflict fix
Write-Host "Testing SQL file for function name conflicts..." -ForegroundColor Green

$content = Get-Content "02_widgets_business_logic.sql" -Raw

# Check if add_message_reaction was properly renamed
if ($content -match "CREATE OR REPLACE FUNCTION add_message_reaction\s*\(") {
    Write-Host "✗ Found old function name 'add_message_reaction' - should be renamed" -ForegroundColor Red
} else {
    Write-Host "✓ Function 'add_message_reaction' properly renamed" -ForegroundColor Green
}

# Check if the new function name exists
if ($content -match "CREATE OR REPLACE FUNCTION add_widget_message_reaction\s*\(") {
    Write-Host "✓ Found new function name 'add_widget_message_reaction'" -ForegroundColor Green
} else {
    Write-Host "✗ New function name 'add_widget_message_reaction' not found" -ForegroundColor Red
}

# Check GRANT statements
if ($content -match "GRANT EXECUTE ON FUNCTION add_message_reaction") {
    Write-Host "✗ Found old GRANT statement for 'add_message_reaction'" -ForegroundColor Red
} else {
    Write-Host "✓ Old GRANT statement removed" -ForegroundColor Green
}

if ($content -match "GRANT EXECUTE ON FUNCTION add_widget_message_reaction") {
    Write-Host "✓ Found new GRANT statement for 'add_widget_message_reaction'" -ForegroundColor Green
} else {
    Write-Host "✗ New GRANT statement not found" -ForegroundColor Red
}

# Check COMMENT statements
if ($content -match "COMMENT ON FUNCTION add_message_reaction") {
    Write-Host "✗ Found old COMMENT statement for 'add_message_reaction'" -ForegroundColor Red
} else {
    Write-Host "✓ Old COMMENT statement removed" -ForegroundColor Green
}

if ($content -match "COMMENT ON FUNCTION add_widget_message_reaction") {
    Write-Host "✓ Found new COMMENT statement for 'add_widget_message_reaction'" -ForegroundColor Green
} else {
    Write-Host "✗ New COMMENT statement not found" -ForegroundColor Red
}

Write-Host "`nFunction rename validation complete!" -ForegroundColor Cyan
