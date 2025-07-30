import 'package:flutter/material.dart';
import '../scripts/sync_shop_items.dart';

/// Admin screen for managing rewards system
class RewardsAdminScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rewards System Admin'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Shop Items Synchronization',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sync all shop items from the app to the database. '
                      'This will create/update all auras, booster packs, '
                      'tarot decks, and accessories.',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ShopItemSyncButton(),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Instructions',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Make sure your rewards SQL files are imported\n'
                      '2. Click "Sync Shop Items" to populate the database\n'
                      '3. Verify items appear in the shop\n'
                      '4. Test purchasing and inventory functions',
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
