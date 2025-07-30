# Crystal Social - Shop Items Sync Guide

## How to Access the Rewards Admin Panel

Your Crystal Social app already has a built-in admin panel that includes the shop items synchronization feature!

### Step-by-Step Instructions:

#### 1. **Access Admin Panel in Debug Mode**
   - Open your Crystal Social app in **debug mode** (running from your IDE)
   - On the home screen, look for the "Quick Actions" FAB (floating action button) at the bottom
   - Tap the "Quick Actions" button to expand the menu
   - You'll see a **purple admin button** with a settings icon

#### 2. **Open Rewards Admin**
   - Tap the purple admin button
   - This opens the Admin Tools bottom sheet
   - You'll see two options:
     - **Support Dashboard** (purple button)
     - **Rewards Admin** (amber/gold button)
   - Tap **"Rewards Admin"**

#### 3. **Sync Shop Items**
   - In the Rewards Admin screen, you'll see a card titled "Shop Items Synchronization"
   - Click the **"Sync Shop Items"** button
   - The sync process will start and show progress
   - You'll see results showing created, updated, and skipped items

#### 4. **Monitor Progress**
   - The sync button will show a loading indicator while running
   - Progress messages will appear
   - When complete, you'll see a success message or any errors

### Alternative Access Methods:

#### Option A: Quick Admin Access Widget
If you want to add admin access to any other screen, add this widget:
```dart
QuickAdminAccess(showOnlyInDebug: true)
```

#### Option B: Direct Bottom Sheet
Call this method from anywhere in your app:
```dart
AdminAccessBottomSheet.show(context);
```

### What Gets Synced:

The shop items sync will add/update:
- **25+ Auras** (Sunset Meadow, Ocean Breeze, Dragon Soul, etc.)
- **6 Booster Packs** (Avatar Decorations, Auras, Pets, etc.)
- **5 Tarot Decks** (Water-Colored, Merlin, Enchanted, etc.)
- **8+ Pet Accessories** (Royal Crown, Cat Ears, Flower Crown, etc.)
- All items include proper pricing, rarity, level requirements, and asset paths

### Verification:

After syncing, you can verify the integration worked by:
1. Checking your shop screens in the app
2. Looking at the database shop_items table
3. Testing item purchases and inventory

### Troubleshooting:

If you don't see the admin button:
1. Make sure you're running in **debug mode** (not release)
2. The admin button only appears when `kDebugMode` is true
3. Try expanding the Quick Actions menu by tapping the main FAB

The admin system is already fully integrated into your app - you just need to use it!
