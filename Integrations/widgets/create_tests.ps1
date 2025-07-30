# Isolate the type mismatch issue
Write-Host "Creating minimal test to isolate type mismatch..." -ForegroundColor Green

# Create a minimal test file with just the table creation and one policy
$testContent = @"
-- Test minimal security policy setup
-- Create a simple table first
CREATE TABLE IF NOT EXISTS test_widget_table (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE test_widget_table ENABLE ROW LEVEL SECURITY;

-- Simple policy that should work
CREATE POLICY "Users can view own test records"
ON test_widget_table FOR SELECT
USING (auth.uid() = user_id);

-- Test completion
SELECT 'Test policy created successfully' as result;
"@

Set-Content -Path "test_minimal.sql" -Value $testContent
Write-Host "Created test_minimal.sql for isolated testing" -ForegroundColor Cyan

# Also create a version with explicit casting
$testContentCast = @"
-- Test with explicit casting
CREATE TABLE IF NOT EXISTS test_widget_table_cast (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE test_widget_table_cast ENABLE ROW LEVEL SECURITY;

-- Policy with explicit UUID casting
CREATE POLICY "Users can view own test records with cast"
ON test_widget_table_cast FOR SELECT
USING (auth.uid()::UUID = user_id::UUID);

SELECT 'Test policy with casting created successfully' as result;
"@

Set-Content -Path "test_cast.sql" -Value $testContentCast
Write-Host "Created test_cast.sql with explicit type casting" -ForegroundColor Cyan

Write-Host "`nTest files created for debugging!" -ForegroundColor Green
