# Crystal Social Firebase Setup Guide

## Required Files for Production Build

### Android
1. **google-services.json**
   - Download from Firebase Console → Project Settings → General → Your Apps → Android
   - Place in: `android/app/google-services.json`

### iOS  
1. **GoogleService-Info.plist**
   - Download from Firebase Console → Project Settings → General → Your Apps → iOS
   - Add to Xcode project in `ios/Runner/` folder

## Firebase Services Configuration

### 1. Authentication
- Enable Email/Password authentication
- Configure OAuth providers if needed (Google, Apple, etc.)

### 2. Firestore Database
- Create database in production mode
- Set up security rules for your data structure

### 3. Storage
- Enable Firebase Storage for file uploads
- Configure security rules for image/audio uploads

### 4. Cloud Messaging (FCM)
- Already configured in app
- Upload APNs certificates for iOS push notifications

### 5. Analytics & Crashlytics
- Will automatically start collecting data once files are added

## Security Rules Examples

### Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Public chat messages
    match /messages/{messageId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
  }
}
```

### Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /user_uploads/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /public_content/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

After adding these files, your app will have full Firebase functionality!
