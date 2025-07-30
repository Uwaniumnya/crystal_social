# 📝 Manual Credential Update Instructions

If you prefer to update manually, here are the exact changes needed:

## 🔑 **Your New Credentials**
```
NEW_PROJECT_URL: https://YOUR_NEW_PROJECT_ID.supabase.co
NEW_ANON_KEY: eyJhbGciOiJIUzI1NiI... (your new anon key)
```

## 📁 **Files to Update**

### 1. **lib/config/environment_config.dart** (MAIN FILE)
Replace **3 instances** of:
```dart
// OLD
defaultValue: 'https://syymhweqggvpdseugwvi.supabase.co',

// NEW  
defaultValue: 'https://YOUR_NEW_PROJECT_ID.supabase.co',
```

Replace **3 instances** of:
```dart
// OLD
defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN5eW1od2VxZ2d2cGRzZXVnd3ZpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI1ODUwMTgsImV4cCI6MjA2ODE2MTAxOH0.5sQ0UH_FLR6UxC9WR7UOz0v6wrFW8SUsJA0dW8iKzwY',

// NEW
defaultValue: 'YOUR_NEW_ANON_KEY',
```

### 2. **lib/rewards/shop_sync_main.dart**
Replace:
```dart
// OLD
url: 'https://syymhweqggvpdseugwvi.supabase.co',
anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN5eW1od2VxZ2d2cGRzZXVnd3ZpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI1ODUwMTgsImV4cCI6MjA2ODE2MTAxOH0.5sQ0UH_FLR6UxC9WR7UOz0v6wrFW8SUsJA0dW8iKzwY',

// NEW
url: 'https://YOUR_NEW_PROJECT_ID.supabase.co',
anonKey: 'YOUR_NEW_ANON_KEY',
```

### 3. **lib/widgets/sticker_picker.dart**
Replace **6 instances** of:
```dart
// OLD
'https://syymhweqggvpdseugwvi.supabase.co/storage/v1/object/public/stickers/

// NEW
'https://YOUR_NEW_PROJECT_ID.supabase.co/storage/v1/object/public/stickers/
```

### 4. **lib/chat/chat_screen.dart**
Replace **2 instances** of:
```dart
// OLD
'https://your-supabase-url.supabase.co/functions/v1/generate-agora-token'

// NEW
'https://zdsjtjbzhiejvpuahnlk.supabase.co/functions/v1/generate-agora-token'
```

## ✅ **Quick Checklist**
- [ ] environment_config.dart: 3 URLs + 3 keys updated
- [ ] shop_sync_main.dart: 1 URL + 1 key updated  
- [ ] sticker_picker.dart: 6 URLs updated
- [ ] chat_screen.dart: 2 URLs updated

## 🚀 **After Updates**
1. Build your app: `flutter build apk --debug --target-platform android-arm64`
2. Import the 4 CLEAN SQL files into your new Supabase project
3. Test signup - should work perfectly! 🎉
