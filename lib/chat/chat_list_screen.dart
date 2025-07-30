import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import 'chat_screen.dart';
import '../tabs/settings_screen.dart';
import '../utils/navigation_helper.dart';
import 'chat_production_config.dart';

class EnhancedChatListScreen extends StatefulWidget {
  final String username;

  const EnhancedChatListScreen({super.key, required this.username});

  @override
  State<EnhancedChatListScreen> createState() => _EnhancedChatListScreenState();
}

class _EnhancedChatListScreenState extends State<EnhancedChatListScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  List<Map<String, dynamic>> _recentChats = [];
  List<Map<String, dynamic>> _onlineUsers = [];
  Map<String, String> _lastMessages = {};
  Map<String, int> _unreadCounts = {};
  Map<String, DateTime> _lastSeen = {};
  
  late AnimationController _refreshController;
  late AnimationController _searchController2;
  late Timer _onlineStatusTimer;
  
  bool _isSearching = false;
  bool _showOnlineOnly = false;
  String _sortBy = 'recent'; // recent, alphabetical, online
  
  @override
  void initState() {
    super.initState();
    _setupAnimationControllers();
    _loadInitialData();
    _setupRealTimeUpdates();
    _startOnlineStatusTimer();
  }

  void _setupAnimationControllers() {
    _refreshController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _searchController2 = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  void _startOnlineStatusTimer() {
    _onlineStatusTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateOnlineStatus();
    });
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadUsers(),
      _loadRecentChats(),
      _loadLastMessages(),
      _loadUnreadCounts(),
      _updateOnlineStatus(),
    ]);
  }

  Future<void> _loadUsers() async {
    try {
      final response = await supabase
          .from('profiles')
          .select('id, avatar_url, username, full_name, status, last_seen')
          .neq('id', widget.username);
      
      setState(() {
        _allUsers = List<Map<String, dynamic>>.from(response);
        // Map the fields to match expected format
        for (var user in _allUsers) {
          user['display_name'] = user['full_name'] ?? user['username'] ?? user['id'];
        }
        _filteredUsers = List.from(_allUsers);
      });
      
      _applyFiltersAndSort();
    } catch (e) {
      ChatDebugUtils.logError('ChatListScreen', 'Failed to load users: $e');
      _showErrorSnackBar('Failed to load users');
    }
  }

  Future<void> _loadRecentChats() async {
    try {
      final response = await supabase
          .from('messages')
          .select('chat_id, created_at, sender_id, content')
          .or('sender_id.eq.${widget.username},recipient_id.eq.${widget.username}')
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .limit(50);
      
      final Map<String, Map<String, dynamic>> chatMap = {};
      
      for (final message in response) {
        final chatId = message['chat_id'] as String;
        if (!chatMap.containsKey(chatId)) {
          chatMap[chatId] = message;
        }
      }
      
      setState(() {
        _recentChats = chatMap.values.toList();
      });
    } catch (e) {
      ChatDebugUtils.logError('ChatListScreen', 'Failed to load recent chats: $e');
      _showErrorSnackBar('Failed to load recent chats');
    }
  }

  Future<void> _loadLastMessages() async {
    try {
      for (final user in _allUsers) {
        final chatId = generateChatId(widget.username, user['id']);
        final response = await supabase
            .from('messages')
            .select('content, created_at, sender_id')
            .eq('chat_id', chatId)
            .eq('is_deleted', false)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        
        if (response != null) {
          final isMe = response['sender_id'] == widget.username;
          final prefix = isMe ? 'You: ' : '';
          final content = response['content'] ?? '';
          _lastMessages[user['id']] = '$prefix$content';
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      ChatDebugUtils.logError('ChatListScreen', 'Error loading last messages: $e');
    }
  }

  Future<void> _loadUnreadCounts() async {
    try {
      for (final user in _allUsers) {
        final chatId = generateChatId(widget.username, user['id']);
        
        // Use the get_unread_count function from our SQL integration
        final response = await supabase
            .rpc('get_unread_count', params: {
              'p_chat_id': chatId,
              'p_user_id': widget.username,
            });
        
        _unreadCounts[user['id']] = response ?? 0;
      }
      if (mounted) setState(() {});
    } catch (e) {
      ChatDebugUtils.logError('ChatListScreen', 'Error loading unread counts: $e');
      // Fallback to manual count if RPC fails
      await _loadUnreadCountsFallback();
    }
  }
  
  Future<void> _loadUnreadCountsFallback() async {
    try {
      for (final user in _allUsers) {
        final chatId = generateChatId(widget.username, user['id']);
        final response = await supabase
            .from('messages')
            .select('id')
            .eq('chat_id', chatId)
            .neq('sender_id', widget.username)
            .eq('is_deleted', false);
        
        // Count messages that don't have read status for current user
        int unreadCount = 0;
        for (final message in response) {
          final statusCheck = await supabase
              .from('message_status')
              .select('id')
              .eq('message_id', message['id'])
              .eq('user_id', widget.username)
              .eq('status', 'read')
              .maybeSingle();
          
          if (statusCheck == null) {
            unreadCount++;
          }
        }
        
        _unreadCounts[user['id']] = unreadCount;
      }
      if (mounted) setState(() {});
    } catch (e) {
      ChatDebugUtils.logError('ChatListScreen', 'Error in unread count fallback: $e');
    }
  }

  Future<void> _updateOnlineStatus() async {
    try {
      // Update current user's last seen in user_presence table
      await supabase
          .from('user_presence')
          .upsert({
            'user_id': widget.username,
            'status': 'online',
            'last_seen': DateTime.now().toIso8601String(),
          });
      
      // Get online users (active in last 5 minutes)
      final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
      final response = await supabase
          .from('user_presence')
          .select('user_id, last_seen, status')
          .neq('user_id', widget.username)
          .or('status.eq.online,last_seen.gte.${fiveMinutesAgo.toIso8601String()}');
      
      setState(() {
        _onlineUsers = List<Map<String, dynamic>>.from(response);
        // Map user_id to id for compatibility
        for (var user in _onlineUsers) {
          user['id'] = user['user_id'];
        }
        
        // Update last seen times
        for (final user in _allUsers) {
          final userData = response.firstWhere(
            (u) => u['user_id'] == user['id'],
            orElse: () => {'last_seen': user['last_seen']},
          );
          if (userData['last_seen'] != null) {
            _lastSeen[user['id']] = DateTime.parse(userData['last_seen']);
          }
        }
      });
    } catch (e) {
      ChatDebugUtils.logError('ChatListScreen', 'Error updating online status: $e');
    }
  }

  void _setupRealTimeUpdates() {
    // Listen for new messages
    supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .listen((data) {
          _loadLastMessages();
          _loadUnreadCounts();
        });
    
    // Listen for user status changes
    supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .listen((data) {
          _updateOnlineStatus();
        });
  }

  void _applyFiltersAndSort() {
    List<Map<String, dynamic>> filtered = List.from(_allUsers);
    
    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((user) {
        final displayName = user['display_name']?.toString().toLowerCase() ?? '';
        final username = user['username']?.toString().toLowerCase() ?? '';
        final userId = user['id']?.toString().toLowerCase() ?? '';
        return displayName.contains(query) || 
               username.contains(query) || 
               userId.contains(query);
      }).toList();
    }
    
    // Apply online filter
    if (_showOnlineOnly) {
      final onlineIds = _onlineUsers.map((u) => u['id']).toSet();
      filtered = filtered.where((user) => onlineIds.contains(user['id'])).toList();
    }
    
    // Apply sorting
    switch (_sortBy) {
      case 'recent':
        filtered.sort((a, b) {
          final aTime = _getLastMessageTime(a['id']);
          final bTime = _getLastMessageTime(b['id']);
          return bTime.compareTo(aTime);
        });
        break;
      case 'alphabetical':
        filtered.sort((a, b) {
          final aName = a['display_name']?.toString() ?? a['id']?.toString() ?? '';
          final bName = b['display_name']?.toString() ?? b['id']?.toString() ?? '';
          return aName.compareTo(bName);
        });
        break;
      case 'online':
        final onlineIds = _onlineUsers.map((u) => u['id']).toSet();
        filtered.sort((a, b) {
          final aOnline = onlineIds.contains(a['id']) ? 1 : 0;
          final bOnline = onlineIds.contains(b['id']) ? 1 : 0;
          return bOnline.compareTo(aOnline);
        });
        break;
    }
    
    setState(() {
      _filteredUsers = filtered;
    });
  }

  DateTime _getLastMessageTime(String userId) {
    // Try to find from recent chats first
    final chatId = generateChatId(widget.username, userId);
    final recentChat = _recentChats.firstWhere(
      (chat) => chat['chat_id'] == chatId,
      orElse: () => <String, dynamic>{},
    );
    
    if (recentChat.isNotEmpty && recentChat['created_at'] != null) {
      return DateTime.parse(recentChat['created_at']);
    }
    
    // Fallback to user's last seen time
    return _lastSeen[userId] ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  bool _isUserOnline(String userId) {
    return _onlineUsers.any((user) => user['id'] == userId);
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              _refreshData();
            },
          ),
        ),
      );
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
    });
    
    if (_isSearching) {
      _searchController2.forward();
    } else {
      _searchController2.reverse();
      _searchController.clear();
      _applyFiltersAndSort();
    }
  }

  void _showFilterMenu() {
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
            
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Filter & Sort',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            
            SwitchListTile(
              title: const Text('Show Online Only'),
              subtitle: Text('${_onlineUsers.length} users online'),
              value: _showOnlineOnly,
              activeColor: Colors.pinkAccent,
              onChanged: (value) {
                setState(() => _showOnlineOnly = value);
                _applyFiltersAndSort();
                Navigator.pop(context);
              },
            ),
            
            const Divider(),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sort by',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            
            ...['recent', 'alphabetical', 'online'].map((sortOption) {
              final titles = {
                'recent': 'Recent Activity',
                'alphabetical': 'Name (A-Z)',
                'online': 'Online Status',
              };
              
              return RadioListTile<String>(
                title: Text(titles[sortOption]!),
                value: sortOption,
                groupValue: _sortBy,
                activeColor: Colors.pinkAccent,
                onChanged: (value) {
                  setState(() => _sortBy = value!);
                  _applyFiltersAndSort();
                  Navigator.pop(context);
                },
              );
            }).toList(),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    _refreshController.repeat();
    await _loadInitialData();
    _refreshController.stop();
    _refreshController.reset();
  }

  String generateChatId(String userA, String userB) {
    final sorted = [userA, userB]..sort();
    return "${sorted[0]}_${sorted[1]}";
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshController.dispose();
    _searchController2.dispose();
    _onlineStatusTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.pinkAccent,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isSearching
              ? TextField(
                  key: const ValueKey('search'),
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search users...',
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => _applyFiltersAndSort(),
                )
              : Row(
                  key: const ValueKey('title'),
                  children: [
                    Text('Chats'),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_filteredUsers.length}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
        ),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _toggleSearch,
            )
          else ...[
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _toggleSearch,
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterMenu,
            ),
            RotationTransition(
              turns: _refreshController,
              child: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshData,
              ),
            ),
          ],
        ],
      ),
      
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pinkAccent, Colors.pink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 30, color: Colors.pinkAccent),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Welcome',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    widget.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.pinkAccent),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EnhancedSettingsScreen(userId: widget.username),
                  ),
                );
              },
            ),
            
            ListTile(
              leading: Badge(
                isLabelVisible: _onlineUsers.isNotEmpty,
                label: Text('${_onlineUsers.length}'),
                child: const Icon(Icons.people, color: Colors.pinkAccent),
              ),
              title: const Text('Online Users'),
              subtitle: Text('${_onlineUsers.length} users online'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _showOnlineOnly = !_showOnlineOnly;
                });
                _applyFiltersAndSort();
              },
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.pinkAccent),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Crystal Social'),
                    content: const Text(
                      'Enhanced chat experience with real-time features, '
                      'online status, and smart filtering.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: Colors.pinkAccent,
        child: _filteredUsers.isEmpty
            ? _buildEmptyState()
            : _buildUserList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_isSearching && _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search terms',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    } else if (_showOnlineOnly) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No users online',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later or show all users',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No other users yet',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Invite friends to start chatting!',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildUserList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        final userId = user['id'] as String? ?? '';
        if (userId.isEmpty) return const SizedBox.shrink();
        
        final displayName = user['display_name'] as String?;
        final avatarUrl = user['avatar_url'] as String?;
        final isOnline = _isUserOnline(userId);
        final lastMessage = _lastMessages[userId];
        final unreadCount = _unreadCounts[userId] ?? 0;
        final lastSeen = _lastSeen[userId];
        final chatId = generateChatId(widget.username, userId);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.pink.shade100,
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  onBackgroundImageError: avatarUrl != null ? (_, __) {
                    ChatDebugUtils.logWarning('ChatListScreen', 'Failed to load avatar: $avatarUrl');
                  } : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? Text(
                          (displayName ?? userId).isNotEmpty 
                              ? (displayName ?? userId).substring(0, 1).toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.pinkAccent,
                          ),
                        )
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    displayName ?? userId,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lastMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    lastMessage,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isOnline ? Icons.circle : Icons.access_time,
                      size: 12,
                      color: isOnline ? Colors.green : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOnline 
                          ? 'Online' 
                          : lastSeen != null 
                              ? 'Last seen ${_getRelativeTime(lastSeen)}'
                              : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: isOnline ? Colors.green : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
            
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    currentUser: widget.username,
                    otherUser: userId,
                    chatId: chatId,
                  ),
                ),
              ).then((_) {
                // Refresh data when returning from chat
                _loadLastMessages();
                _loadUnreadCounts();
              });
            },
            
            onLongPress: () {
              _showUserOptions(user);
            },
          ),
        );
      },
    );
  }

  void _showUserOptions(Map<String, dynamic> user) {
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
            
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.pink.shade100,
                backgroundImage: user['avatar_url'] != null && 
                    (user['avatar_url'] as String).isNotEmpty
                    ? NetworkImage(user['avatar_url'])
                    : null,
                child: user['avatar_url'] == null || 
                    (user['avatar_url'] as String).isEmpty
                    ? Text(
                        ((user['display_name'] ?? user['id'] ?? '?') as String)
                            .isNotEmpty 
                                ? ((user['display_name'] ?? user['id'] ?? '?') as String)
                                    .substring(0, 1).toUpperCase()
                                : '?',
                        style: const TextStyle(color: Colors.pinkAccent),
                      )
                    : null,
              ),
              title: Text(user['display_name'] ?? user['id'] ?? 'Unknown User'),
              subtitle: Text(_isUserOnline(user['id'] ?? '') ? 'Online' : 'Offline'),
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.pinkAccent),
              title: const Text('Open Chat'),
              onTap: () {
                Navigator.pop(context);
                final userId = user['id'] as String? ?? '';
                if (userId.isNotEmpty) {
                  final chatId = generateChatId(widget.username, userId);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        currentUser: widget.username,
                        otherUser: userId,
                        chatId: chatId,
                      ),
                    ),
                  );
                }
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.purple),
              title: const Text('Shared Media'),
              onTap: () {
                Navigator.pop(context);
                final chatId = generateChatId(widget.username, user['id']);
                NavigationHelper.navigateToSharedMedia(
                  context,
                  chatId: chatId,
                  currentUserId: widget.username,
                );
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to user profile
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Profile for ${user['id']}')),
                );
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
