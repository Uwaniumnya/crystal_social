import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/enhanced_push_notification_integration.dart';

/// Integration Test for Push Notifications
/// Add this to any screen to test the notification system
/// Only visible in debug mode for security
class PushNotificationTestButton extends StatelessWidget {
  final String? testUserId;
  
  const PushNotificationTestButton({
    Key? key,
    this.testUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }
    
    return FloatingActionButton.extended(
      onPressed: () => _showTestDialog(context),
      label: const Text('Test Push'),
      icon: const Icon(Icons.notifications),
      backgroundColor: Colors.purple,
    );
  }

  void _showTestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Push Notifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Test the push notification system:'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Send a test notification
                  final success = await EnhancedPushNotificationIntegration
                      .instance
                      .sendMessageNotification(
                    receiverUserId: testUserId ?? 'test_user_123',
                    senderUsername: 'TestBot',
                    messagePreview: 'Hello! This is a test notification 🔔',
                  );

                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success 
                            ? '✅ Test notification sent!' 
                            : '❌ Failed to send notification'
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Send Test Notification'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Schema: "Receiver: You have a message from Sender"',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
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
  }
}

/// Helper widget to show notification status
class NotificationStatusIndicator extends StatelessWidget {
  const NotificationStatusIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_active, size: 16, color: Colors.green),
          SizedBox(width: 4),
          Text(
            'Push Notifications Active',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
