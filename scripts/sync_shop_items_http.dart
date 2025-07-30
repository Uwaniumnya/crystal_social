import 'dart:convert';
import 'dart:io';
import '../lib/rewards/shop_item_sync.dart';

/// Command line script to sync shop items using HTTP requests
/// Run with: dart run scripts/sync_shop_items_http.dart
void main() async {
  print('🚀 Crystal Social Shop Item Sync Tool (HTTP)');
  print('=============================================\n');

  try {
    final supabaseUrl = 'https://zdsjtjbzhiejvpuahnlk.supabase.co';
    final supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpkc2p0amJ6aGllanZwdWFobmxrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4MjAyMzYsImV4cCI6MjA2OTM5NjIzNn0.CSPzbngxKJHrHD8oNMFaYzvKXzNzMENFtaWu9Vy2rV0';
    
    final httpClient = HttpClient();
    final shopItemsUrl = '$supabaseUrl/rest/v1/shop_items';
    
    print('📦 Starting synchronization...\n');
    
    int created = 0;
    int updated = 0;
    int skipped = 0;
    int errors = 0;
    
    for (int i = 0; i < assetShopItems.length; i++) {
      final item = assetShopItems[i];
      final itemName = item['name'] ?? 'Unknown Item $i';
      
      try {
        print('Processing: $itemName (${i + 1}/${assetShopItems.length})');
        
        // Check if item exists
        final checkRequest = await httpClient.getUrl(Uri.parse('$shopItemsUrl?name=eq.$itemName&select=id,name,price'));
        checkRequest.headers.set('apikey', supabaseKey);
        checkRequest.headers.set('Authorization', 'Bearer $supabaseKey');
        
        final checkResponse = await checkRequest.close();
        final checkBody = await checkResponse.transform(utf8.decoder).join();
        final existingItems = jsonDecode(checkBody) as List;
        
        final itemData = {
          'name': item['name'],
          'description': item['description'],
          'price': item['price'],
          'asset_path': item['asset_path'],
          'file_name': item['file_name'],
          'category_id': item['category_id'],
          'rarity': item['rarity'],
          'tags': item['tags'] ?? [],
          'limited_time': item['limited_time'] ?? false,
          'max_per_user': item['max_per_user'],
          'requires_level': item['requires_level'] ?? 1,
          'is_available': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        if (existingItems.isNotEmpty) {
          // Update existing item
          final existingId = existingItems.first['id'];
          final updateRequest = await httpClient.patchUrl(Uri.parse('$shopItemsUrl?id=eq.$existingId'));
          updateRequest.headers.set('apikey', supabaseKey);
          updateRequest.headers.set('Authorization', 'Bearer $supabaseKey');
          updateRequest.headers.set('Content-Type', 'application/json');
          updateRequest.headers.set('Prefer', 'return=minimal');
          
          updateRequest.write(jsonEncode(itemData));
          final updateResponse = await updateRequest.close();
          
          if (updateResponse.statusCode == 204) {
            updated++;
            print('✅ Updated: $itemName');
          } else {
            final errorBody = await updateResponse.transform(utf8.decoder).join();
            throw Exception('Update failed: ${updateResponse.statusCode} - $errorBody');
          }
        } else {
          // Create new item
          final createRequest = await httpClient.postUrl(Uri.parse(shopItemsUrl));
          createRequest.headers.set('apikey', supabaseKey);
          createRequest.headers.set('Authorization', 'Bearer $supabaseKey');
          createRequest.headers.set('Content-Type', 'application/json');
          createRequest.headers.set('Prefer', 'return=minimal');
          
          createRequest.write(jsonEncode(itemData));
          final createResponse = await createRequest.close();
          
          if (createResponse.statusCode == 201) {
            created++;
            print('✨ Created: $itemName');
          } else {
            final errorBody = await createResponse.transform(utf8.decoder).join();
            throw Exception('Creation failed: ${createResponse.statusCode} - $errorBody');
          }
        }
        
        // Small delay to avoid overwhelming the API
        await Future.delayed(Duration(milliseconds: 200));
        
      } catch (e) {
        errors++;
        print('❌ Error processing $itemName: $e');
      }
    }
    
    httpClient.close();
    
    print('\n✅ Synchronization completed!');
    print('📊 Results:');
    print('   Created: $created');
    print('   Updated: $updated');
    print('   Skipped: $skipped');
    print('   Errors: $errors');
    print('   Total: ${created + updated + skipped}');
    
    if (errors > 0) {
      print('\n⚠️  Some items had errors. Check the output above for details.');
    } else {
      print('\n🎉 All items synced successfully!');
    }
    
  } catch (e, stackTrace) {
    print('❌ Fatal error: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
