@echo off
echo Crystal Social - Shop Items Sync
echo ==================================
echo.
echo This will sync all shop items from the Dart code to your Supabase database.
echo Make sure you have:
echo 1. Imported all the rewards SQL files
echo 2. Updated the Supabase credentials in the CLI script
echo.
pause
echo.
echo Running sync...
dart run scripts/sync_shop_items_cli.dart
echo.
pause
