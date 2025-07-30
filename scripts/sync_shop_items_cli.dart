import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../lib/rewards/shop_item_sync.dart';
import '../lib/config/environment_config.dart';

/// Command line script to sync shop items
/// Run with: dart run scripts/sync_shop_items_cli.dart
void main() async {
  print('🚀 Crystal Social Shop Item Sync Tool');
  print('=====================================\n');

  try {
    // Initialize Supabase with actual credentials
    await Supabase.initialize(
      url: EnvironmentConfig.supabaseUrl,
      anonKey: EnvironmentConfig.supabaseAnonKey,
    );

    final supabase = Supabase.instance.client;
    final syncService = ShopItemSyncService(supabase);

    print('📦 Starting synchronization...\n');

    final result = await syncService.uploadAndSyncShopItems(
      onProgress: (message) {
        print('   $message');
      },
    );

    print('\n✅ Synchronization completed!');
    print('📊 Results:');
    print('   Created: ${result.created.length}');
    print('   Updated: ${result.updated.length}');
    print('   Skipped: ${result.skipped.length}');
    print('   Errors: ${result.errors.length}');
    print('   Total: ${result.totalProcessed}');

    if (result.hasErrors) {
      print('\n❌ Errors:');
      result.errors.forEach((error) => print('   - $error'));
    }

    if (result.hasWarnings) {
      print('\n⚠️  Warnings:');
      result.warnings.forEach((warning) => print('   - $warning'));
    }

    print('\n🎉 Done! Your shop items are now synced.');

  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
