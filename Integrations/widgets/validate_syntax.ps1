# PowerShell script to validate SQL syntax
# This script checks for basic SQL syntax issues

$sqlFile = "02_widgets_business_logic.sql"

Write-Host "Validating SQL syntax for $sqlFile..." -ForegroundColor Green

# Read the SQL file
$content = Get-Content $sqlFile -Raw

# Basic syntax checks
$errors = @()

# Check for unmatched parentheses
$openParens = ($content.ToCharArray() | Where-Object { $_ -eq '(' } | Measure-Object).Count
$closeParens = ($content.ToCharArray() | Where-Object { $_ -eq ')' } | Measure-Object).Count
if ($openParens -ne $closeParens) {
    $errors += "Unmatched parentheses: $openParens open, $closeParens close"
}

# Check for unmatched single quotes (basic check)
$singleQuotes = ($content.ToCharArray() | Where-Object { $_ -eq "'" } | Measure-Object).Count
if ($singleQuotes % 2 -ne 0) {
    $errors += "Unmatched single quotes: $singleQuotes found"
}

# Check for AS $$ pattern matching
$asPatterns = [regex]::Matches($content, "AS\s+\$\$")
$endPatterns = [regex]::Matches($content, "\$\$;")
if ($asPatterns.Count -ne $endPatterns.Count) {
    $errors += "Unmatched AS `$`$ patterns: $($asPatterns.Count) AS, $($endPatterns.Count) endings"
}

# Check for EXCEPTION syntax
$exceptionMatches = [regex]::Matches($content, "EXCEPTION\s+WHEN", [Text.RegularExpressions.RegexOptions]::IgnoreCase)
if ($exceptionMatches.Count -gt 0) {
    Write-Host "Found $($exceptionMatches.Count) EXCEPTION WHEN clauses" -ForegroundColor Yellow
}

# Check function completeness
$functionStarts = [regex]::Matches($content, "CREATE OR REPLACE FUNCTION", [Text.RegularExpressions.RegexOptions]::IgnoreCase)
Write-Host "Found $($functionStarts.Count) function definitions" -ForegroundColor Cyan

if ($errors.Count -eq 0) {
    Write-Host "✓ Basic syntax validation passed!" -ForegroundColor Green
    Write-Host "File appears to have correct syntax structure." -ForegroundColor Green
} else {
    Write-Host "✗ Syntax issues found:" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "  - $error" -ForegroundColor Red
    }
}

Write-Host "Validation complete." -ForegroundColor White
