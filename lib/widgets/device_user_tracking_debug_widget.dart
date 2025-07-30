import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/device_user_tracking_service.dart';

/// Debug widget to display device user tracking information
/// Shows how many users have logged in and auto-logout status
/// Only visible in debug mode for security
class DeviceUserTrackingDebugWidget extends StatefulWidget {
  const DeviceUserTrackingDebugWidget({Key? key}) : super(key: key);

  @override
  State<DeviceUserTrackingDebugWidget> createState() => _DeviceUserTrackingDebugWidgetState();
}

class _DeviceUserTrackingDebugWidgetState extends State<DeviceUserTrackingDebugWidget> {
  Map<String, dynamic> _deviceStats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceStats();
  }

  Future<void> _loadDeviceStats() async {
    setState(() => _loading = true);
    try {
      final stats = await DeviceUserTrackingService.instance.getDeviceStats();
      setState(() {
        _deviceStats = stats;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      debugPrint('Error loading device stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.devices, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Device User Tracking',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadDeviceStats,
                ),
              ],
            ),
            const Divider(),
            
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              _buildDeviceInfo(),
              
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showAllUsers,
                    icon: const Icon(Icons.people),
                    label: const Text('View All Users'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearDeviceHistory,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear History'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfo() {
    final totalUsers = _deviceStats['total_users'] ?? 0;
    final hasMultiple = _deviceStats['has_multiple_users'] ?? false;
    final currentUser = _deviceStats['current_user'] ?? 'None';
    final firstUser = _deviceStats['first_user'] ?? 'Unknown';
    final isOnlyUser = _deviceStats['is_current_only_user'] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          icon: Icons.person_outline,
          label: 'Total Users',
          value: totalUsers.toString(),
          color: totalUsers > 1 ? Colors.orange : Colors.green,
        ),
        
        _buildInfoRow(
          icon: Icons.person,
          label: 'Current User',
          value: currentUser.toString().substring(0, 
              currentUser.toString().length > 20 ? 20 : currentUser.toString().length),
          color: Colors.blue,
        ),
        
        _buildInfoRow(
          icon: Icons.star,
          label: 'First User',
          value: firstUser.toString().substring(0, 
              firstUser.toString().length > 20 ? 20 : firstUser.toString().length),
          color: Colors.purple,
        ),
        
        _buildInfoRow(
          icon: hasMultiple ? Icons.group : Icons.person_pin,
          label: 'Device Type',
          value: hasMultiple ? 'Multi-User Device' : 'Single-User Device',
          color: hasMultiple ? Colors.orange : Colors.green,
        ),
        
        _buildInfoRow(
          icon: hasMultiple ? Icons.lock : Icons.lock_open,
          label: 'Auto-Logout',
          value: hasMultiple ? 'ENABLED (30min)' : 'DISABLED',
          color: hasMultiple ? Colors.red : Colors.green,
        ),
        
        if (isOnlyUser)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You are the only user on this device. Auto-logout is disabled for your convenience.',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
        if (hasMultiple)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Multiple users detected. Auto-logout is enabled for privacy protection.',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAllUsers() async {
    try {
      final users = await DeviceUserTrackingService.instance.getAllDeviceUsers();
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('All Device Users'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total: ${users.length} user(s)'),
              const SizedBox(height: 16),
              if (users.isEmpty)
                const Text('No users found')
              else
                ...users.asMap().entries.map((entry) {
                  final index = entry.key;
                  final userId = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Text('${index + 1}. '),
                        Expanded(
                          child: Text(
                            userId.length > 30 
                                ? '${userId.substring(0, 30)}...' 
                                : userId,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading users: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearDeviceHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Device History'),
        content: const Text(
          'This will remove all device user history. '
          'Auto-logout will be disabled until multiple users log in again. '
          '\n\nAre you sure?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DeviceUserTrackingService.instance.clearDeviceUserHistory();
        await _loadDeviceStats();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Device history cleared successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing history: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
