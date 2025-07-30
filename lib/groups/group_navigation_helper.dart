import 'package:flutter/material.dart';
import 'group_chat_screen.dart';
import 'group_settings_screen.dart';
import 'group_list_screen.dart';
import 'create_group_chat.dart' as create_group;
import '../utils/navigation_helper.dart';

class GroupNavigationHelper {
  static void navigateToGroupChat(
    BuildContext context, {
    required String currentUserId,
    required String chatId,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupChatScreen(
          currentUserId: currentUserId,
          chatId: chatId,
        ),
      ),
    );
  }

  static void navigateToGroupSettings(
    BuildContext context, {
    required String currentUserId,
    required String chatId,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupSettingsScreen(
          currentUserId: currentUserId,
          chatId: chatId,
        ),
      ),
    );
  }

  static void navigateToGroupMedia(
    BuildContext context, {
    required String chatId,
    required String currentUserId,
  }) {
    NavigationHelper.navigateToSharedMedia(
      context,
      chatId: chatId,
      currentUserId: currentUserId,
    );
  }

  static void navigateToGroupList(
    BuildContext context, {
    required String currentUserId,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupListScreen(currentUserId: currentUserId),
      ),
    );
  }

  static Future<String?> navigateToCreateGroup(
    BuildContext context, {
    required String currentUserId,
    required List<dynamic> allUsers,
  }) {
    return Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => create_group.CreateGroupScreen(
          currentUserId: currentUserId,
          allUsers: allUsers.cast<create_group.User>(),
        ),
      ),
    );
  }

  static void showGroupQuickActions(
    BuildContext context, {
    required String currentUserId,
    required String chatId,
    required String groupName,
    bool isAdmin = false,
    bool isOwner = false,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              groupName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Open Chat'),
              onTap: () {
                Navigator.pop(context);
                navigateToGroupChat(context, currentUserId: currentUserId, chatId: chatId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('View Media'),
              onTap: () {
                Navigator.pop(context);
                navigateToGroupMedia(context, chatId: chatId, currentUserId: currentUserId);
              },
            ),
            if (isAdmin || isOwner)
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Group Settings'),
                onTap: () {
                  Navigator.pop(context);
                  navigateToGroupSettings(context, currentUserId: currentUserId, chatId: chatId);
                },
              ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Group Info'),
              onTap: () {
                Navigator.pop(context);
                navigateToGroupSettings(context, currentUserId: currentUserId, chatId: chatId);
              },
            ),
          ],
        ),
      ),
    );
  }

  static void showSuccessSnackBar(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  static void showErrorSnackBar(
    BuildContext context, {
    required String message,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
