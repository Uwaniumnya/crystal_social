import 'package:flutter/material.dart';
import 'support_dashboard.dart';
import 'rewards_admin_screen.dart';

/// Quick Admin Access Widget - Can be added to any screen for development/testing
class QuickAdminAccess extends StatelessWidget {
  final bool showOnlyInDebug;
  
  const QuickAdminAccess({
    super.key,
    this.showOnlyInDebug = true,
  });

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode if specified
    if (showOnlyInDebug) {
      bool inDebugMode = false;
      assert(inDebugMode = true);
      if (!inDebugMode) return const SizedBox.shrink();
    }

    return FloatingActionButton(
      onPressed: () => _showAdminAccess(context),
      backgroundColor: Colors.purple,
      child: const Icon(Icons.admin_panel_settings, color: Colors.white),
      tooltip: 'Admin Access',
    );
  }

  void _showAdminAccess(BuildContext context) {
    final passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.purple),
            const SizedBox(width: 8),
            const Text('Quick Admin Access'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Access Support Dashboard:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
                hintText: 'Leave empty to skip',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openSupportDashboard(context);
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Support Dashboard'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openRewardsAdmin(context);
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rewards Admin'),
          ),
        ],
      ),
    );
  }

  void _openSupportDashboard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SupportDashboard(),
      ),
    );
  }

  void _openRewardsAdmin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RewardsAdminScreen(),
      ),
    );
  }
}

/// Admin Access Bottom Sheet - Alternative UI for admin access
class AdminAccessBottomSheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Icon and title
            Icon(
              Icons.admin_panel_settings,
              size: 48,
              color: Colors.purple,
            ),
            const SizedBox(height: 12),
            const Text(
              'Admin Tools',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Access administrative functions',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Support Dashboard Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SupportDashboard(),
                    ),
                  );
                },
                icon: const Icon(Icons.dashboard),
                label: const Text('Support Dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Rewards Admin Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RewardsAdminScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.star),
                label: const Text('Rewards Admin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Future admin tools can be added here
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User Management - Coming Soon!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                icon: const Icon(Icons.people),
                label: const Text('User Management (Coming Soon)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
