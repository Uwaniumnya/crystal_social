# SQL Schema Import Guide for Crystal Social

## Overview
This guide explains how to import the updated SQL schema that matches the current login implementation.

## Key Changes Made

### 1. Simple Users Table Added
- **Purpose**: Core user storage table that the app expects
- **Matches**: App's direct insertion logic in `enhanced_login_screen.dart`
- **Structure**: 
  ```sql
  CREATE TABLE users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255), -- Optional, auto-generated format
    password_hash VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
  );
  ```

### 2. Enhanced User Profiles Updated
- **Email made optional**: Changed `email VARCHAR(255) NOT NULL` to `email VARCHAR(255)`
- **Reason**: App auto-generates emails in format `username@crystalsocial.local`

### 3. Security & Performance Added
- **Row Level Security (RLS)**: Enabled on users table
- **Access Policies**: Users can only access their own records
- **Performance Indexes**: Added for username, email, and created_at fields
- **Automatic Timestamps**: Trigger updates `updated_at` on record changes

## Import Instructions

### For New Database Setup:
1. **Execute the SQL file**:
   ```sql
   -- In your Supabase SQL editor or PostgreSQL client:
   \i SQL/003_enhanced_login_screen_integration.sql
   ```

2. **Verify tables created**:
   ```sql
   -- Check if tables exist
   SELECT table_name FROM information_schema.tables 
   WHERE table_schema = 'public' 
   AND table_name IN ('users', 'enhanced_user_profiles');
   
   -- Check RLS is enabled
   SELECT schemaname, tablename, rowsecurity 
   FROM pg_tables 
   WHERE tablename = 'users';
   ```

### For Existing Database Upgrade:
1. **Backup existing data**:
   ```sql
   -- Export existing user data if any
   SELECT * FROM enhanced_user_profiles;
   ```

2. **Apply incremental changes**:
   ```sql
   -- Add users table if it doesn't exist
   CREATE TABLE IF NOT EXISTS users (
     id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
     username VARCHAR(50) UNIQUE NOT NULL,
     email VARCHAR(255),
     password_hash VARCHAR(255),
     created_at TIMESTAMPTZ DEFAULT NOW(),
     updated_at TIMESTAMPTZ DEFAULT NOW()
   );
   
   -- Make email optional in enhanced_user_profiles
   ALTER TABLE enhanced_user_profiles 
   ALTER COLUMN email DROP NOT NULL;
   
   -- Enable RLS on users table
   ALTER TABLE users ENABLE ROW LEVEL SECURITY;
   
   -- Add access policy
   CREATE POLICY "Users can access own records" ON users
     FOR ALL USING (auth.uid() = id);
   ```

3. **Add performance indexes**:
   ```sql
   CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
   CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
   CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at DESC);
   ```

4. **Add update trigger**:
   ```sql
   CREATE TRIGGER update_users_updated_at 
     BEFORE UPDATE ON users 
     FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
   ```

## App Integration Compatibility

### Current Login Screen Behavior:
- **Email Auto-Generation**: Uses format `{username}@crystalsocial.local`
- **Database Insertion**: Inserts directly into `users` table
- **Error Handling**: Falls back gracefully if database operations fail
- **No Email Required**: User only needs to provide username and password

### Database Schema Match:
- ✅ `users` table exists for direct app insertion
- ✅ Email field is optional (can be NULL)
- ✅ Auto-generated timestamps work with app logic
- ✅ RLS policies secure user data access
- ✅ Performance indexes speed up login queries

## Testing the Integration

### 1. Test User Creation:
```sql
-- Simulate app signup
INSERT INTO users (username, email, password_hash) 
VALUES ('testuser', 'testuser@crystalsocial.local', 'hashed_password_here');
```

### 2. Test User Login Query:
```sql
-- Simulate app login lookup
SELECT id, username, email, created_at 
FROM users 
WHERE username = 'testuser';
```

### 3. Verify RLS Protection:
```sql
-- This should work for authenticated user
SELECT * FROM users WHERE id = auth.uid();

-- This should fail for other users' records
SELECT * FROM users WHERE id != auth.uid();
```

## Migration Strategy

### Production Environment:
1. **Schedule maintenance window**
2. **Backup entire database**
3. **Apply schema changes incrementally**
4. **Test app functionality**
5. **Monitor for errors in first 24 hours**

### Development Environment:
1. **Drop and recreate from full SQL file** (recommended)
2. **Test all signup and login flows**
3. **Verify error handling works**

## Troubleshooting

### Common Issues:
1. **"Table 'users' doesn't exist"**:
   - Solution: Run the full SQL file or create users table manually

2. **"Column 'email' cannot be null"**:
   - Solution: Make email optional in enhanced_user_profiles table

3. **"Permission denied for table users"**:
   - Solution: Check RLS policies and ensure user is authenticated

4. **"Duplicate key value violates unique constraint"**:
   - Solution: Check for existing usernames before insertion

## File Structure
- **Main SQL File**: `SQL/003_enhanced_login_screen_integration.sql`
- **App Integration**: `lib/tabs/enhanced_login_screen.dart`
- **Android Config**: `android/app/build.gradle.kts`

## Support
- Check the SQL file execution logs for detailed error messages
- Verify Supabase project settings match the schema requirements
- Test with a single user account before bulk import

---
**Last Updated**: Schema aligned with enhanced_login_screen.dart implementation
**Compatibility**: Flutter 3.32.5, Supabase, Samsung Galaxy A23 Android 14
