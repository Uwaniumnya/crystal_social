import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../rewards/shop_item_sync.dart';

/// Script to sync all shop items from Dart to Supabase
/// Run this once after setting up the rewards system
class ShopItemSyncScript {
  static Future<void> runSync() async {
    try {
      print('🚀 Starting shop item synchronization...');
      
      // Initialize Supabase client (make sure it's already initialized in your main app)
      final supabase = Supabase.instance.client;
      
      // Create the sync service
      final syncService = ShopItemSyncService(supabase);
      
      // Run the sync with progress tracking
      final result = await syncService.uploadAndSyncShopItems(
        onProgress: (message) {
          print('📦 $message');
        },
      );
      
      // Print results
      print('\n✅ Shop item sync completed!');
      print('📊 Results:');
      print('   - Created: ${result.created.length} items');
      print('   - Updated: ${result.updated.length} items');
      print('   - Skipped: ${result.skipped.length} items');
      print('   - Errors: ${result.errors.length} items');
      print('   - Warnings: ${result.warnings.length} items');
      print('   - Total Processed: ${result.totalProcessed} items');
      
      if (result.hasErrors) {
        print('\n❌ Errors encountered:');
        for (final error in result.errors) {
          print('   - $error');
        }
      }
      
      if (result.hasWarnings) {
        print('\n⚠️  Warnings:');
        for (final warning in result.warnings) {
          print('   - $warning');
        }
      }
      
      print('\n🎉 Shop items are now synchronized with the database!');
      
    } catch (e, stackTrace) {
      print('❌ Error during sync: $e');
      print('Stack trace: $stackTrace');
    }
  }
}

/// Widget to trigger sync from UI
class ShopItemSyncButton extends StatefulWidget {
  @override
  _ShopItemSyncButtonState createState() => _ShopItemSyncButtonState();
}

class _ShopItemSyncButtonState extends State<ShopItemSyncButton> {
  bool _syncing = false;
  String _result = '';

  Future<void> _runSync() async {
    setState(() {
      _syncing = true;
      _result = 'Syncing...';
    });

    try {
      await ShopItemSyncScript.runSync();
      setState(() {
        _result = 'Sync completed successfully!';
      });
    } catch (e) {
      setState(() {
        _result = 'Sync failed: $e';
      });
    } finally {
      setState(() {
        _syncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _syncing ? null : _runSync,
          child: _syncing 
            ? CircularProgressIndicator() 
            : Text('Sync Shop Items'),
        ),
        if (_result.isNotEmpty) 
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(_result),
          ),
      ],
    );
  }
}
