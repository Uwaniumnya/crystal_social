import 'package:flutter_test/flutter_test.dart';
import 'package:crystal_social/admin/admin_access.dart';
import 'package:crystal_social/admin/rewards_admin_screen.dart';
import 'package:crystal_social/scripts/sync_shop_items.dart';

void main() {
  group('Rewards Admin Integration Tests', () {
    test('Admin access widgets are available', () {
      expect(QuickAdminAccess, isNotNull);
      expect(AdminAccessBottomSheet, isNotNull);
    });

    test('Rewards admin screen is available', () {
      expect(RewardsAdminScreen, isNotNull);
    });

    test('Shop sync script is available', () {
      expect(ShopItemSyncScript, isNotNull);
      expect(ShopItemSyncButton, isNotNull);
    });
  });
}
