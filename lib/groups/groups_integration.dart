// File: groups_integration.dart
// Central integration hub for all group functionality
// Provides unified API for group operations across the app

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

// Import all group components
import 'group_list_screen.dart';
import 'create_group_chat.dart' as create_group;
import 'group_navigation_helper.dart';
import 'group_utils.dart';

// Type alias to avoid conflicts with Supabase User
typedef AppUser = create_group.User;

/// Centralized Groups Integration Service
/// Manages all group-related operations with unified state management
class GroupsIntegration extends ChangeNotifier {
  static GroupsIntegration? _instance;
  static GroupsIntegration get instance {
    _instance ??= GroupsIntegration._internal();
    return _instance!;
  }

  GroupsIntegration._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // State management
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;

  // Group data
  List<Map<String, dynamic>> _allGroups = [];
  List<Map<String, dynamic>> _myGroups = [];
  List<Map<String, dynamic>> _publicGroups = [];
  Map<String, List<Map<String, dynamic>>> _groupMembers = {};
  Map<String, Map<String, dynamic>> _memberDetails = {};

  // Real-time subscriptions
  RealtimeChannel? _groupsChannel;
  final Map<String, RealtimeChannel> _groupChannels = {};

  // Search and filtering
  String _searchQuery = '';
  String _sortBy = 'recent';
  bool _showOnlyOwned = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentUserId => _currentUserId;
  List<Map<String, dynamic>> get allGroups => _allGroups;
  List<Map<String, dynamic>> get myGroups => _myGroups;
  List<Map<String, dynamic>> get publicGroups => _publicGroups;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;
  bool get showOnlyOwned => _showOnlyOwned;

  /// Initialize the groups system
  Future<void> initialize(String userId) async {
    if (_isInitialized && _currentUserId == userId) return;

    _setLoading(true);
    _currentUserId = userId;

    try {
      await _loadAllGroups();
      await _setupRealtimeSubscriptions();
      _isInitialized = true;
      _error = null;
    } catch (e) {
      _error = 'Failed to initialize groups: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Load all groups for the current user
  Future<void> _loadAllGroups() async {
    if (_currentUserId == null) return;

    final response = await _supabase
        .from('chats')
        .select('''
          *,
          last_message:messages(
            text,
            timestamp,
            sender_id,
            users!messages_sender_id_fkey(username)
          )
        ''')
        .eq('is_group', true)
        .contains('members', [_currentUserId])
        .order('created_at', ascending: false);

    _allGroups = List<Map<String, dynamic>>.from(response);
    _filterGroups();
    notifyListeners();
  }

  /// Filter groups based on search and sort criteria
  void _filterGroups() {
    List<Map<String, dynamic>> filtered = _allGroups;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((group) {
        final name = (group['name'] ?? '').toString().toLowerCase();
        final description = (group['description'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery.toLowerCase()) ||
               description.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply ownership filter
    if (_showOnlyOwned) {
      filtered = filtered.where((group) => 
        group['owner_id'] == _currentUserId
      ).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'name':
          return (a['name'] ?? '').toString()
              .compareTo((b['name'] ?? '').toString());
        case 'members':
          final aMembers = (a['members'] as List?)?.length ?? 0;
          final bMembers = (b['members'] as List?)?.length ?? 0;
          return bMembers.compareTo(aMembers);
        case 'recent':
        default:
          final aTime = DateTime.tryParse(a['updated_at'] ?? '') ?? DateTime.fromMicrosecondsSinceEpoch(0);
          final bTime = DateTime.tryParse(b['updated_at'] ?? '') ?? DateTime.fromMicrosecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
      }
    });

    // Separate my groups and public groups
    _myGroups = filtered.where((group) => 
      group['owner_id'] == _currentUserId
    ).toList();
    
    _publicGroups = filtered.where((group) => 
      group['is_public'] == true
    ).toList();
  }

  /// Set up real-time subscriptions for group updates
  Future<void> _setupRealtimeSubscriptions() async {
    if (_currentUserId == null) return;

    // Main groups channel
    _groupsChannel = _supabase.channel('groups_${_currentUserId}')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        table: 'chats',
        callback: (payload) {
          if (payload.newRecord['is_group'] == true &&
              (payload.newRecord['members'] as List?)?.contains(_currentUserId) == true) {
            _loadAllGroups();
          }
        },
      )
      .subscribe();
  }

  /// Subscribe to a specific group's updates
  Future<void> subscribeToGroup(String groupId) async {
    if (_groupChannels.containsKey(groupId)) return;

    final channel = _supabase.channel('group_$groupId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'chat_id',
          value: groupId,
        ),
        callback: (payload) {
          // Handle real-time message updates
          notifyListeners();
        },
      )
      .subscribe();

    _groupChannels[groupId] = channel;
  }

  /// Unsubscribe from a specific group's updates
  void unsubscribeFromGroup(String groupId) {
    final channel = _groupChannels.remove(groupId);
    channel?.unsubscribe();
  }

  /// Search groups
  void searchGroups(String query) {
    _searchQuery = query;
    _filterGroups();
    notifyListeners();
  }

  /// Set sort criteria
  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    _filterGroups();
    notifyListeners();
  }

  /// Toggle show only owned groups
  void toggleShowOnlyOwned() {
    _showOnlyOwned = !_showOnlyOwned;
    _filterGroups();
    notifyListeners();
  }

  /// Get group details by ID
  Map<String, dynamic>? getGroupById(String groupId) {
    try {
      return _allGroups.firstWhere((group) => group['id'] == groupId);
    } catch (e) {
      return null;
    }
  }

  /// Get group members
  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    if (_groupMembers.containsKey(groupId)) {
      return _groupMembers[groupId]!;
    }

    try {
      final group = getGroupById(groupId);
      if (group == null) return [];

      final memberIds = List<String>.from(group['members'] ?? []);
      
      final members = await _supabase
          .from('users')
          .select('id, username, avatar_url, last_seen_at, is_online')
          .inFilter('id', memberIds);

      _groupMembers[groupId] = List<Map<String, dynamic>>.from(members);
      
      // Cache member details
      for (final member in members) {
        _memberDetails[member['id']] = member;
      }

      notifyListeners();
      return _groupMembers[groupId]!;
    } catch (e) {
      return [];
    }
  }

  /// Create a new group
  Future<String?> createGroup({
    required String name,
    required String description,
    required List<String> memberIds,
    String emoji = '💬',
    bool isPublic = false,
    bool allowInvites = true,
  }) async {
    if (_currentUserId == null) return null;

    _setLoading(true);
    try {
      final allMembers = [_currentUserId!, ...memberIds];
      
      final response = await _supabase.from('chats').insert({
        'name': name,
        'description': description,
        'emoji': emoji,
        'is_group': true,
        'is_public': isPublic,
        'owner_id': _currentUserId,
        'members': allMembers,
        'settings': {
          'allow_member_invites': allowInvites,
        },
      }).select().single();

      await _loadAllGroups();
      return response['id'] as String;
    } catch (e) {
      _error = 'Failed to create group: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Join a public group
  Future<bool> joinGroup(String groupId) async {
    if (_currentUserId == null) return false;

    _setLoading(true);
    try {
      final group = getGroupById(groupId);
      if (group == null) return false;

      final currentMembers = List<String>.from(group['members'] ?? []);
      if (currentMembers.contains(_currentUserId)) return true;

      currentMembers.add(_currentUserId!);

      await _supabase
          .from('chats')
          .update({'members': currentMembers})
          .eq('id', groupId);

      await _loadAllGroups();
      return true;
    } catch (e) {
      _error = 'Failed to join group: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Leave a group
  Future<bool> leaveGroup(String groupId) async {
    if (_currentUserId == null) return false;

    _setLoading(true);
    try {
      final group = getGroupById(groupId);
      if (group == null) return false;

      final currentMembers = List<String>.from(group['members'] ?? []);
      currentMembers.remove(_currentUserId);

      await _supabase
          .from('chats')
          .update({'members': currentMembers})
          .eq('id', groupId);

      await _loadAllGroups();
      return true;
    } catch (e) {
      _error = 'Failed to leave group: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update group settings
  Future<bool> updateGroupSettings(String groupId, Map<String, dynamic> updates) async {
    _setLoading(true);
    try {
      await _supabase
          .from('chats')
          .update(updates)
          .eq('id', groupId);

      await _loadAllGroups();
      return true;
    } catch (e) {
      _error = 'Failed to update group: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Check if user is group owner
  bool isGroupOwner(String groupId) {
    final group = getGroupById(groupId);
    return group?['owner_id'] == _currentUserId;
  }

  /// Check if user is group admin
  bool isGroupAdmin(String groupId) {
    final group = getGroupById(groupId);
    if (group == null) return false;

    // Owner is always admin
    if (group['owner_id'] == _currentUserId) return true;

    // Check admin list
    final admins = List<String>.from(group['admins'] ?? []);
    return admins.contains(_currentUserId);
  }

  /// Check if user can perform action
  bool canPerformAction(String groupId, String action) {
    final group = getGroupById(groupId);
    if (group == null) return false;

    final isOwner = isGroupOwner(groupId);
    final isAdmin = isGroupAdmin(groupId);
    final isMember = (group['members'] as List?)?.contains(_currentUserId) ?? false;

    switch (action) {
      case 'delete_group':
        return isOwner;
      case 'edit_settings':
      case 'add_members':
      case 'remove_members':
      case 'promote_members':
        return isOwner || isAdmin;
      case 'send_messages':
      case 'view_media':
        return isMember;
      default:
        return false;
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Clean up resources
  @override
  void dispose() {
    _groupsChannel?.unsubscribe();
    for (final channel in _groupChannels.values) {
      channel.unsubscribe();
    }
    super.dispose();
  }

  // =============================================================================
  // STATIC CONVENIENCE METHODS
  // =============================================================================

  /// Wrap widget with groups provider
  static Widget wrapWithGroupsSystem({required Widget child}) {
    return ChangeNotifierProvider.value(
      value: GroupsIntegration.instance,
      child: child,
    );
  }

  /// Navigate to group chat
  static void navigateToGroupChat(
    BuildContext context, {
    required String currentUserId,
    required String chatId,
  }) {
    GroupNavigationHelper.navigateToGroupChat(
      context,
      currentUserId: currentUserId,
      chatId: chatId,
    );
  }

  /// Navigate to group settings
  static void navigateToGroupSettings(
    BuildContext context, {
    required String currentUserId,
    required String chatId,
  }) {
    GroupNavigationHelper.navigateToGroupSettings(
      context,
      currentUserId: currentUserId,
      chatId: chatId,
    );
  }

  /// Navigate to group list
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

  /// Navigate to create group
  static void navigateToCreateGroup(
    BuildContext context, {
    required String currentUserId,
    required List<AppUser> allUsers,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => create_group.CreateGroupScreen(
          currentUserId: currentUserId,
          allUsers: allUsers,
        ),
      ),
    );
  }

  /// Show group quick actions menu
  static void showGroupActionsMenu(
    BuildContext context, {
    required String groupId,
    required String currentUserId,
  }) {
    final integration = GroupsIntegration.instance;
    final group = integration.getGroupById(groupId);
    if (group == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              group['name'] ?? 'Group',
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
                navigateToGroupChat(
                  context,
                  currentUserId: currentUserId,
                  chatId: groupId,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Group Settings'),
              onTap: () {
                Navigator.pop(context);
                navigateToGroupSettings(
                  context,
                  currentUserId: currentUserId,
                  chatId: groupId,
                );
              },
            ),
            if (integration.canPerformAction(groupId, 'view_media'))
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('View Media'),
                onTap: () {
                  Navigator.pop(context);
                  GroupNavigationHelper.navigateToGroupMedia(
                    context,
                    chatId: groupId,
                    currentUserId: currentUserId,
                  );
                },
              ),
            if (!integration.isGroupOwner(groupId))
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                title: const Text('Leave Group', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showLeaveGroupDialog(context, groupId);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Show leave group confirmation dialog
  static void _showLeaveGroupDialog(BuildContext context, String groupId) {
    final integration = GroupsIntegration.instance;
    final group = integration.getGroupById(groupId);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: Text('Are you sure you want to leave "${group?['name'] ?? 'this group'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await integration.leaveGroup(groupId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Left group successfully' : 'Failed to leave group'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Format group stats
  static String formatGroupStats(Map<String, dynamic> group) {
    final memberCount = (group['members'] as List?)?.length ?? 0;
    final messageCount = group['message_count'] ?? 0;
    
    return GroupUtils.formatMemberCount(memberCount) + 
           (messageCount > 0 ? ' • $messageCount messages' : '');
  }

  /// Get group display emoji
  static String getGroupEmoji(Map<String, dynamic> group) {
    return group['emoji'] ?? '💬';
  }

  /// Check if group is active (has recent messages)
  static bool isGroupActive(Map<String, dynamic> group) {
    final lastMessage = group['last_message'];
    if (lastMessage == null) return false;
    
    final timestamp = DateTime.tryParse(lastMessage['timestamp'] ?? '');
    if (timestamp == null) return false;
    
    final daysSinceLastMessage = DateTime.now().difference(timestamp).inDays;
    return daysSinceLastMessage <= 7; // Active if message within 7 days
  }
}

/// Groups Consumer Widget - Easy way to build reactive UI
class GroupsConsumer extends StatelessWidget {
  final Widget Function(BuildContext context, GroupsIntegration groups) builder;

  const GroupsConsumer({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupsIntegration>(
      builder: (context, groups, child) => builder(context, groups),
    );
  }
}

/// Groups Builder Widget - Alternative reactive builder
class GroupsBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, GroupsIntegration groups) builder;
  final Widget? child;

  const GroupsBuilder({
    super.key,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupsIntegration>(
      builder: (context, groups, child) => builder(context, groups),
      child: child,
    );
  }
}

/// Context extension for easy groups access
extension GroupsContext on BuildContext {
  GroupsIntegration get groups => Provider.of<GroupsIntegration>(this, listen: false);
  GroupsIntegration get watchGroups => Provider.of<GroupsIntegration>(this, listen: true);
}

/// Mixin for easy groups access in StatefulWidgets
mixin GroupsMixin<T extends StatefulWidget> on State<T> {
  GroupsIntegration get groupsIntegration => Provider.of<GroupsIntegration>(context, listen: false);
}
