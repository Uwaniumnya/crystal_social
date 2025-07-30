import 'package:flutter/material.dart';
import '../chat/chat_screen.dart';
import '../chat/chat_list_screen.dart';
import '../chat/media_viewer.dart';
import '../tabs/settings_screen.dart';

/// Unified navigation helper for Crystal Social app
/// Provides consistent navigation patterns across all screens
class NavigationHelper {
  
  // Chat Navigation
  static void navigateToChat(
    BuildContext context, {
    required String currentUser,
    required String otherUser,
    required String chatId,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          currentUser: currentUser,
          otherUser: otherUser,
          chatId: chatId,
        ),
      ),
    );
  }

  static void navigateToChatList(
    BuildContext context, {
    required String username,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EnhancedChatListScreen(username: username),
      ),
    );
  }

  // Media Navigation
  static void navigateToSharedMedia(
    BuildContext context, {
    required String chatId,
    required String currentUserId,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EnhancedSharedMediaViewer(
          chatId: chatId,
          currentUserId: currentUserId,
        ),
      ),
    );
  }

  // Settings Navigation
  static void navigateToSettings(
    BuildContext context, {
    required String userId,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EnhancedSettingsScreen(userId: userId),
      ),
    );
  }

  // Utility Methods
  static String generateChatId(String userA, String userB) {
    final sorted = [userA, userB]..sort();
    return "${sorted[0]}_${sorted[1]}";
  }

  // Show consistent success messages
  static void showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Show consistent error messages
  static void showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Show consistent info messages
  static void showInfoMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Show consistent loading dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message ?? 'Loading...'),
          ],
        ),
      ),
    );
  }

  // Close loading dialog
  static void closeLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  // Show confirmation dialog
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // Show bottom sheet with options
  static void showOptionsBottomSheet(
    BuildContext context, {
    required String title,
    required List<BottomSheetOption> options,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            
            ...options.map((option) => ListTile(
              leading: Icon(option.icon, color: option.color),
              title: Text(option.title),
              subtitle: option.subtitle != null ? Text(option.subtitle!) : null,
              onTap: () {
                Navigator.pop(context);
                option.onTap();
              },
            )).toList(),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Helper class for bottom sheet options
class BottomSheetOption {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? color;
  final VoidCallback onTap;

  BottomSheetOption({
    required this.icon,
    required this.title,
    this.subtitle,
    this.color,
    required this.onTap,
  });
}
