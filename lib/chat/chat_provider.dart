import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'chat_service.dart';

/// Chat Provider that wraps the ChatService for easier access in widgets
class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService.instance;

  ChatProvider() {
    // Listen to ChatService changes and notify widgets
    _chatService.addListener(_onServiceUpdate);
  }

  void _onServiceUpdate() {
    notifyListeners();
  }

  @override
  void dispose() {
    _chatService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  // Delegate all getters to the service
  bool get isInitialized => _chatService.isInitialized;
  bool get isLoading => _chatService.isLoading;
  String? get error => _chatService.error;
  String? get currentUserId => _chatService.currentUserId;
  List<Map<String, dynamic>> get allUsers => _chatService.allUsers;
  List<Map<String, dynamic>> get recentChats => _chatService.recentChats;
  List<Map<String, dynamic>> get onlineUsers => _chatService.onlineUsers;
  Map<String, String> get lastMessages => _chatService.lastMessages;
  Map<String, int> get unreadCounts => _chatService.unreadCounts;
  Map<String, DateTime> get lastSeen => _chatService.lastSeen;
  String get currentChatTheme => _chatService.currentChatTheme;
  String? get globalChatBackground => _chatService.globalChatBackground;
  Map<String, dynamic> get chatSettings => _chatService.chatSettings;

  // Methods
  Future<void> initialize(String userId) => _chatService.initialize(userId);
  Future<void> refresh() => _chatService.refresh();
  List<Map<String, dynamic>> getChatMessages(String chatId) => _chatService.getChatMessages(chatId);
  Future<void> loadChatMessages(String chatId) => _chatService.loadChatMessages(chatId);
  
  Future<bool> sendMessage({
    required String chatId,
    required String receiverId,
    required String text,
    String? mediaUrl,
    String? mediaType,
    Map<String, dynamic>? metadata,
  }) => _chatService.sendMessage(
    chatId: chatId,
    receiverId: receiverId,
    text: text,
    mediaUrl: mediaUrl,
    mediaType: mediaType,
    metadata: metadata,
  );

  Future<bool> markMessagesAsRead(String chatId, String senderId) => 
      _chatService.markMessagesAsRead(chatId, senderId);
  
  void subscribeToChat(String chatId) => _chatService.subscribeToChat(chatId);
  void unsubscribeFromChat(String chatId) => _chatService.unsubscribeFromChat(chatId);
  
  Future<void> updateTypingStatus(String chatId, bool isTyping) => 
      _chatService.updateTypingStatus(chatId, isTyping);
  
  bool isUserTyping(String userId) => _chatService.isUserTyping(userId);
  
  Future<bool> updateChatTheme(String theme) => _chatService.updateChatTheme(theme);
  Future<bool> updateGlobalChatBackground(String? backgroundUrl) => 
      _chatService.updateGlobalChatBackground(backgroundUrl);
  
  Future<String?> uploadMediaFile(File file, String chatId) => 
      _chatService.uploadMediaFile(file, chatId);
  
  String generateChatId(String userId1, String userId2) => 
      _chatService.generateChatId(userId1, userId2);
  
  String generateMessageId() => _chatService.generateMessageId();
  
  List<Map<String, dynamic>> searchUsers(String query) => _chatService.searchUsers(query);
  
  List<Map<String, dynamic>> getFilteredChats({
    bool onlineOnly = false,
    String sortBy = 'recent',
  }) => _chatService.getFilteredChats(onlineOnly: onlineOnly, sortBy: sortBy);
  
  void clear() => _chatService.clear();
}

/// Mixin to easily access ChatProvider in widgets
mixin ChatMixin<T extends StatefulWidget> on State<T> {
  ChatProvider get chatProvider => Provider.of<ChatProvider>(context, listen: false);
  ChatProvider get watchChat => Provider.of<ChatProvider>(context);
}

/// Extension to access ChatProvider from BuildContext
extension ChatContext on BuildContext {
  ChatProvider get chat => Provider.of<ChatProvider>(this, listen: false);
  ChatProvider get watchChat => Provider.of<ChatProvider>(this);
}

/// Widget builder that rebuilds when chat data changes
class ChatBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ChatProvider chat) builder;
  final Widget? child;

  const ChatBuilder({
    super.key,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chat, child) => builder(context, chat),
      child: child,
    );
  }
}

/// Widget that shows loading state while chat is being loaded
class ChatLoadingWrapper extends StatelessWidget {
  final Widget child;
  final Widget? loadingWidget;
  final Widget Function(String error)? errorBuilder;

  const ChatLoadingWrapper({
    super.key,
    required this.child,
    this.loadingWidget,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ChatBuilder(
      builder: (context, chat) {
        if (chat.error != null && errorBuilder != null) {
          return errorBuilder!(chat.error!);
        }
        
        if (chat.isLoading && !chat.isInitialized) {
          return loadingWidget ?? const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        return child;
      },
    );
  }
}

/// Convenient widgets for common chat operations
class ChatUserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onTap;
  final bool showLastMessage;
  final bool showUnreadBadge;
  final bool showOnlineStatus;

  const ChatUserTile({
    super.key,
    required this.user,
    this.onTap,
    this.showLastMessage = true,
    this.showUnreadBadge = true,
    this.showOnlineStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    return ChatBuilder(
      builder: (context, chat) {
        final userId = user['id'] as String;
        final username = user['username'] as String? ?? 'Unknown';
        final avatarUrl = user['avatarUrl'] as String?;
        final lastMessage = chat.lastMessages[userId];
        final unreadCount = chat.unreadCounts[userId] ?? 0;
        final isOnline = chat.onlineUsers.any((u) => u['id'] == userId);
        final lastSeen = chat.lastSeen[userId];

        return ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null ? Text(username[0].toUpperCase()) : null,
              ),
              if (showOnlineStatus && isOnline)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            username,
            style: TextStyle(
              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showLastMessage && lastMessage != null)
                Text(
                  lastMessage.length > 30 
                      ? '${lastMessage.substring(0, 30)}...' 
                      : lastMessage,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              if (!isOnline && lastSeen != null)
                Text(
                  'Last seen ${_formatLastSeen(lastSeen)}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          trailing: showUnreadBadge && unreadCount > 0
              ? Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
          onTap: onTap,
        );
      },
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    }
  }
}

class ChatThemeSelector extends StatelessWidget {
  final String currentTheme;
  final Function(String) onThemeChanged;

  const ChatThemeSelector({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final themes = [
      {'id': 'classic', 'name': 'Classic', 'color': Colors.blue},
      {'id': 'neon', 'name': 'Neon', 'color': Colors.cyan},
      {'id': 'nature', 'name': 'Nature', 'color': Colors.green},
      {'id': 'space', 'name': 'Space', 'color': Colors.purple},
      {'id': 'ocean', 'name': 'Ocean', 'color': Colors.teal},
      {'id': 'sunset', 'name': 'Sunset', 'color': Colors.orange},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chat Theme',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: themes.map((theme) {
            final isSelected = theme['id'] == currentTheme;
            return GestureDetector(
              onTap: () => onThemeChanged(theme['id'] as String),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? (theme['color'] as Color).withOpacity(0.3)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                        ? (theme['color'] as Color)
                        : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: Text(
                  theme['name'] as String,
                  style: TextStyle(
                    color: isSelected 
                        ? (theme['color'] as Color)
                        : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class TypingIndicator extends StatefulWidget {
  final String userId;

  const TypingIndicator({
    super.key,
    required this.userId,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChatBuilder(
      builder: (context, chat) {
        final isTyping = chat.isUserTyping(widget.userId);
        
        if (!isTyping) {
          return const SizedBox.shrink();
        }

        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Typing',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(3, (index) {
                        return AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            final delay = index * 0.2;
                            final value = (_animationController.value - delay).clamp(0.0, 1.0);
                            return Transform.translate(
                              offset: Offset(0, -4 * value),
                              child: Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Colors.grey[600],
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
