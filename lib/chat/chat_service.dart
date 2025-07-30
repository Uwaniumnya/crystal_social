import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:io';
import '../services/enhanced_push_notification_integration.dart';
import 'chat_production_config.dart';

/// Centralized Chat Service that coordinates all chat-related functionality
/// This service acts as the single source of truth for all chat operations
class ChatService extends ChangeNotifier {
  static ChatService? _instance;
  static ChatService get instance {
    _instance ??= ChatService._internal();
    return _instance!;
  }

  ChatService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // State management
  bool _isInitialized = false;
  String? _currentUserId;
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _recentChats = [];
  List<Map<String, dynamic>> _onlineUsers = [];
  Map<String, String> _lastMessages = {};
  Map<String, int> _unreadCounts = {};
  Map<String, DateTime> _lastSeen = {};
  Map<String, List<Map<String, dynamic>>> _chatMessages = {};
  Map<String, RealtimeChannel> _chatSubscriptions = {};
  Map<String, bool> _typingStatus = {};
  bool _isLoading = false;
  String? _error;

  // Chat settings
  Map<String, dynamic> _chatSettings = {};
  String _currentChatTheme = 'classic';
  String? _globalChatBackground;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentUserId => _currentUserId;
  List<Map<String, dynamic>> get allUsers => List.from(_allUsers);
  List<Map<String, dynamic>> get recentChats => List.from(_recentChats);
  List<Map<String, dynamic>> get onlineUsers => List.from(_onlineUsers);
  Map<String, String> get lastMessages => Map.from(_lastMessages);
  Map<String, int> get unreadCounts => Map.from(_unreadCounts);
  Map<String, DateTime> get lastSeen => Map.from(_lastSeen);
  String get currentChatTheme => _currentChatTheme;
  String? get globalChatBackground => _globalChatBackground;
  Map<String, dynamic> get chatSettings => Map.from(_chatSettings);

  /// Initialize the chat service with a user
  Future<void> initialize(String userId) async {
    if (_isInitialized && _currentUserId == userId) return;

    try {
      _setLoading(true);
      _clearError();

      _currentUserId = userId;

      // Load all chat data in parallel
      await Future.wait([
        _loadAllUsers(),
        _loadRecentChats(),
        _loadOnlineUsers(),
        _loadChatSettings(),
        _loadGlobalChatBackground(),
      ]);

      // Load additional data
      await Future.wait([
        _loadLastMessages(),
        _loadUnreadCounts(),
        _loadLastSeen(),
      ]);

      _isInitialized = true;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize chat service: $e');
      _setLoading(false);
      ChatDebugUtils.logError('ChatService', 'ChatService initialization error: $e');
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    if (!_isInitialized || _currentUserId == null) return;
    await initialize(_currentUserId!);
  }

  /// Load all users
  Future<void> _loadAllUsers() async {
    try {
      final data = await _supabase
          .from('users')
          .select('id, username, avatarUrl, is_online, last_seen')
          .neq('id', _currentUserId!);

      _allUsers = data;
    } catch (e) {
      ChatDebugUtils.logError('ChatService', 'Error loading all users: $e');
    }
  }

  /// Load recent chats
  Future<void> _loadRecentChats() async {
    try {
      final response = await _supabase
          .from('messages')
          .select('chat_id, text, timestamp, sender_id, receiver_id')
          .or('sender_id.eq.$_currentUserId,receiver_id.eq.$_currentUserId')
          .order('timestamp', ascending: false)
          .limit(50);

      final Map<String, Map<String, dynamic>> chatMap = {};

      for (final message in response) {
        final chatId = message['chat_id'] as String;
        if (!chatMap.containsKey(chatId)) {
          chatMap[chatId] = message;
        }
      }

      _recentChats = chatMap.values.toList();
    } catch (e) {
      ChatDebugUtils.logError('ChatService', 'Error loading recent chats: $e');
    }
  }

  /// Load online users
  Future<void> _loadOnlineUsers() async {
    try {
      final data = await _supabase
          .from('users')
          .select('id, username, avatarUrl, last_seen')
          .eq('is_online', true)
          .neq('id', _currentUserId!);

      _onlineUsers = data;
    } catch (e) {
      ChatDebugUtils.logError('ChatService', 'Error loading online users: $e');
    }
  }

  /// Load last messages for all users
  Future<void> _loadLastMessages() async {
    try {
      for (final user in _allUsers) {
        final chatId = generateChatId(_currentUserId!, user['id']);
        final response = await _supabase
            .from('messages')
            .select('text, timestamp, sender_id')
            .eq('chat_id', chatId)
            .order('timestamp', ascending: false)
            .limit(1)
            .maybeSingle();

        if (response != null) {
          final isMe = response['sender_id'] == _currentUserId;
          final prefix = isMe ? 'You: ' : '';
          _lastMessages[user['id']] = '$prefix${response['text'] ?? ''}';
        }
      }
    } catch (e) {
      ChatDebugUtils.logError('ChatService', 'Error loading last messages: $e');
    }
  }

  /// Load unread counts
  Future<void> _loadUnreadCounts() async {
    try {
      for (final user in _allUsers) {
        final chatId = generateChatId(_currentUserId!, user['id']);
        final response = await _supabase
            .from('messages')
            .select('id')
            .eq('chat_id', chatId)
            .eq('receiver_id', _currentUserId!)
            .eq('is_read', false);

        _unreadCounts[user['id']] = response.length;
      }
    } catch (e) {
      ChatDebugUtils.logError('ChatService', 'Error loading unread counts: $e');
    }
  }

  /// Load last seen times
  Future<void> _loadLastSeen() async {
    try {
      for (final user in _allUsers) {
        if (user['last_seen'] != null) {
          _lastSeen[user['id']] = DateTime.parse(user['last_seen']);
        }
      }
    } catch (e) {
      ChatDebugUtils.logError('ChatService', 'Error loading last seen: $e');
    }
  }

  /// Load chat settings
  Future<void> _loadChatSettings() async {
    try {
      final data = await _supabase
          .from('chat_settings')
          .select('*')
          .eq('user_id', _currentUserId!)
          .maybeSingle();

      if (data != null) {
        _chatSettings = data;
        _currentChatTheme = data['theme'] ?? 'classic';
      }
    } catch (e) {
      ChatDebugUtils.logError('ChatService', 'Error loading chat settings: $e');
    }
  }

  /// Load global chat background
  Future<void> _loadGlobalChatBackground() async {
    try {
      final data = await _supabase
          .from('users')
          .select('global_chat_background')
          .eq('id', _currentUserId!)
          .maybeSingle();

      _globalChatBackground = data?['global_chat_background'];
    } catch (e) {
      ChatDebugUtils.logError('ChatService', 'Error loading global chat background: $e');
    }
  }

  /// Get messages for a specific chat
  List<Map<String, dynamic>> getChatMessages(String chatId) {
    return _chatMessages[chatId] ?? [];
  }

  /// Load messages for a specific chat
  Future<void> loadChatMessages(String chatId) async {
    try {
      final data = await _supabase
          .from('messages')
          .select('*')
          .eq('chat_id', chatId)
          .order('timestamp', ascending: true);

      _chatMessages[chatId] = data;
      notifyListeners();
    } catch (e) {
      ChatDebugUtils.logError('ChatService', 'Error loading chat messages: $e');
    }
  }

  /// Send a message
  Future<bool> sendMessage({
    required String chatId,
    required String receiverId,
    required String text,
    String? mediaUrl,
    String? mediaType,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized || _currentUserId == null) return false;

    try {
      final messageData = {
        'id': generateMessageId(),
        'chat_id': chatId,
        'sender_id': _currentUserId!,
        'receiver_id': receiverId,
        'text': text,
        'timestamp': DateTime.now().toIso8601String(),
        'is_read': false,
        'media_url': mediaUrl,
        'media_type': mediaType,
        'metadata': metadata,
      };

      await _supabase.from('messages').insert(messageData);

      // Add to local cache
      if (_chatMessages[chatId] == null) {
        _chatMessages[chatId] = [];
      }
      _chatMessages[chatId]!.add(messageData);

      // Update last message
      _lastMessages[receiverId] = 'You: $text';

      // 🔔 SEND PUSH NOTIFICATION
      // Get the sender's username for the notification
      final senderData = await _supabase
          .from('users')
          .select('username')
          .eq('id', _currentUserId!)
          .maybeSingle();
      
      if (senderData != null) {
        final senderUsername = senderData['username'] as String;
        
        // Send notification with exact schema: "Receiver: You have a message from Sender"
        await EnhancedPushNotificationIntegration.instance.sendMessageNotification(
          receiverUserId: receiverId,
          senderUsername: senderUsername,
        );
        
        ChatDebugUtils.log('ChatService', 'Push notification sent to $receiverId from $senderUsername');
      }

      notifyListeners();
      return true;
    } catch (e) {
      ChatDebugUtils.logError('ChatService', 'Error sending message: $e');
      return false;
    }
  }

  /// Mark messages as read
  Future<bool> markMessagesAsRead(String chatId, String senderId) async {
    if (!_isInitialized || _currentUserId == null) return false;

    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('chat_id', chatId)
          .eq('sender_id', senderId)
          .eq('receiver_id', _currentUserId!);

      // Update local unread count
      _unreadCounts[senderId] = 0;
      notifyListeners();
      return true;
    } catch (e) {
      ChatDebugUtils.logError('ChatService', 'Error marking messages as read: $e');
      return false;
    }
  }

  /// Subscribe to real-time updates for a chat
  void subscribeToChat(String chatId) {
    if (_chatSubscriptions.containsKey(chatId)) return;

    final subscription = _supabase
        .channel('messages:$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) {
            final newMessage = payload.newRecord;
            if (_chatMessages[chatId] == null) {
              _chatMessages[chatId] = [];
            }
            _chatMessages[chatId]!.add(newMessage);

            // Update unread count if message is from other user
            if (newMessage['sender_id'] != _currentUserId) {
              final senderId = newMessage['sender_id'];
              _unreadCounts[senderId] = (_unreadCounts[senderId] ?? 0) + 1;
              _lastMessages[senderId] = newMessage['text'] ?? '';
            }

            notifyListeners();
          },
        )
        .subscribe();

    _chatSubscriptions[chatId] = subscription;
  }

  /// Unsubscribe from chat updates
  void unsubscribeFromChat(String chatId) {
    _chatSubscriptions[chatId]?.unsubscribe();
    _chatSubscriptions.remove(chatId);
  }

  /// Update typing status
  Future<void> updateTypingStatus(String chatId, bool isTyping) async {
    try {
      await _supabase.from('typing_status').upsert({
        'chat_id': chatId,
        'user_id': _currentUserId!,
        'is_typing': isTyping,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      ChatDebugUtils.logError('ChatService', 'Error updating typing status: $e');
    }
  }

  /// Get typing status for a user
  bool isUserTyping(String userId) {
    return _typingStatus[userId] ?? false;
  }

  /// Update chat theme
  Future<bool> updateChatTheme(String theme) async {
    if (!_isInitialized || _currentUserId == null) return false;

    try {
      await _supabase.from('chat_settings').upsert({
        'user_id': _currentUserId!,
        'theme': theme,
      });

      _currentChatTheme = theme;
      _chatSettings['theme'] = theme;
      notifyListeners();
      return true;
    } catch (e) {
      ChatDebugUtils.logError('ChatService', 'Error updating chat theme: $e');
      return false;
    }
  }

  /// Update global chat background
  Future<bool> updateGlobalChatBackground(String? backgroundUrl) async {
    if (!_isInitialized || _currentUserId == null) return false;

    try {
      await _supabase
          .from('users')
          .update({'global_chat_background': backgroundUrl})
          .eq('id', _currentUserId!);

      _globalChatBackground = backgroundUrl;
      notifyListeners();
      return true;
    } catch (e) {
      ChatDebugUtils.logError('ChatService', 'Error updating global chat background: $e');
      return false;
    }
  }

  /// Upload media file
  Future<String?> uploadMediaFile(File file, String chatId) async {
    if (!_isInitialized || _currentUserId == null) return null;

    try {
      final fileExt = file.path.split('.').last;
      final fileName = '${generateMessageId()}.$fileExt';
      final filePath = 'chat_media/$chatId/$fileName';

      await _supabase.storage.from('user_content').upload(filePath, file);

      return _supabase.storage.from('user_content').getPublicUrl(filePath);
    } catch (e) {
      ChatDebugUtils.logError('ChatService', 'Error uploading media file: $e');
      return null;
    }
  }

  /// Generate chat ID from two user IDs
  String generateChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  /// Generate unique message ID
  String generateMessageId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_currentUserId}_${DateTime.now().microsecond}';
  }

  /// Search users
  List<Map<String, dynamic>> searchUsers(String query) {
    if (query.isEmpty) return _allUsers;

    final lowercaseQuery = query.toLowerCase();
    return _allUsers.where((user) {
      final username = (user['username'] ?? '').toString().toLowerCase();
      final displayName = (user['display_name'] ?? '').toString().toLowerCase();
      return username.contains(lowercaseQuery) || displayName.contains(lowercaseQuery);
    }).toList();
  }

  /// Get filtered chats based on criteria
  List<Map<String, dynamic>> getFilteredChats({
    bool onlineOnly = false,
    String sortBy = 'recent',
  }) {
    var chats = List<Map<String, dynamic>>.from(_recentChats);

    if (onlineOnly) {
      final onlineUserIds = _onlineUsers.map((user) => user['id']).toSet();
      chats = chats.where((chat) {
        final otherUserId = chat['sender_id'] == _currentUserId
            ? chat['receiver_id']
            : chat['sender_id'];
        return onlineUserIds.contains(otherUserId);
      }).toList();
    }

    switch (sortBy) {
      case 'alphabetical':
        chats.sort((a, b) {
          final userA = _allUsers.firstWhere(
            (user) => user['id'] == (a['sender_id'] == _currentUserId ? a['receiver_id'] : a['sender_id']),
            orElse: () => {'username': ''},
          );
          final userB = _allUsers.firstWhere(
            (user) => user['id'] == (b['sender_id'] == _currentUserId ? b['receiver_id'] : b['sender_id']),
            orElse: () => {'username': ''},
          );
          return (userA['username'] ?? '').compareTo(userB['username'] ?? '');
        });
        break;
      case 'online':
        chats.sort((a, b) {
          final userAId = a['sender_id'] == _currentUserId ? a['receiver_id'] : a['sender_id'];
          final userBId = b['sender_id'] == _currentUserId ? b['receiver_id'] : b['sender_id'];
          final userAOnline = _onlineUsers.any((user) => user['id'] == userAId);
          final userBOnline = _onlineUsers.any((user) => user['id'] == userBId);
          return userBOnline.toString().compareTo(userAOnline.toString());
        });
        break;
      case 'recent':
      default:
        chats.sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
        break;
    }

    return chats;
  }

  // Helper methods
  void _setLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// Clear all data (for logout)
  void clear() {
    _isInitialized = false;
    _currentUserId = null;
    _allUsers.clear();
    _recentChats.clear();
    _onlineUsers.clear();
    _lastMessages.clear();
    _unreadCounts.clear();
    _lastSeen.clear();
    _chatMessages.clear();
    _typingStatus.clear();
    _chatSettings.clear();
    _globalChatBackground = null;
    _currentChatTheme = 'classic';

    // Cancel all subscriptions
    for (final subscription in _chatSubscriptions.values) {
      subscription.unsubscribe();
    }
    _chatSubscriptions.clear();

    _clearError();
    notifyListeners();
  }
}






