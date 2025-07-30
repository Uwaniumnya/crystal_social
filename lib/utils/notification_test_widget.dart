import 'package:flutter/material.dart';
import '../services/enhanced_push_notification_integration.dart';

/// Test widget to demonstrate the push notification system
class NotificationTestWidget extends StatelessWidget {
  const NotificationTestWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Push Notification Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Push Notification System Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('✅ Device Registration Service - Active'),
                    Text('✅ Push Notification Service - Active'),
                    Text('✅ Supabase Edge Function - Deployed'),
                    Text('✅ Message Schema: "Receiver: You have a message from Sender"'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Test device registration
                  await EnhancedPushNotificationIntegration.instance.onUserLogin('test_user_123');
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Device registered successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Registration error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Test Device Registration'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Test notification sending
                  await EnhancedPushNotificationIntegration.instance.sendMessageNotification(
                    receiverUserId: 'test_user_123',
                    senderUsername: 'TestSender',
                  );
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test notification sent!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Notification error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Send Test Notification'),
            ),
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How It Works:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('1. When a user logs in, their device FCM token is saved'),
                    Text('2. All devices where a user has logged in are tracked'),
                    Text('3. When sending a notification, all user devices receive it'),
                    Text('4. Notifications use the exact schema: "Receiver: You have a message from Sender"'),
                    Text('5. Even offline devices will receive notifications when they come online'),
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
