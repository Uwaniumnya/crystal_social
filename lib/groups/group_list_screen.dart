import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';

import 'groups_integration.dart';
import 'create_group_chat.dart' as create_group;

class GroupListScreen extends StatefulWidget {
  final String currentUserId;

  const GroupListScreen({super.key, required this.currentUserId});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final supabase = Supabase.instance.client;
  
  late TabController _tabController;
  late RealtimeChannel _realtimeChannel;
  
  List<Map<String, dynamic>> allGroups = [];
  List<Map<String, dynamic>> filteredGroups = [];
  String _searchQuery = '';
  bool _isLoading = true;
  bool _showSearch = false;
  String _sortBy = 'recent'; // 'recent', 'name', 'members'
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadGroups();
    _setupRealtimeSubscription();
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        _filterGroups();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _realtimeChannel.unsubscribe();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await supabase
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
          .contains('members', [widget.currentUserId])
          .order('created_at', ascending: false);

      setState(() {
        allGroups = response;
        _filterGroups();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading groups: $e')),
        );
      }
    }
  }

  void _setupRealtimeSubscription() {
    _realtimeChannel = supabase.channel('groups_${widget.currentUserId}')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        table: 'chats',
        callback: (payload) {
          if (payload.newRecord['is_group'] == true &&
              (payload.newRecord['members'] as List?)?.contains(widget.currentUserId) == true) {
            _loadGroups();
          }
        },
      )
      .subscribe();
  }

  void _filterGroups() {
    filteredGroups = allGroups.where((group) {
      final name = (group['name'] ?? '').toString().toLowerCase();
      final description = (group['description'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) || description.contains(_searchQuery);
    }).toList();

    // Apply sorting
    switch (_sortBy) {
      case 'name':
        filteredGroups.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
        break;
      case 'members':
        filteredGroups.sort((a, b) => 
          ((b['members'] as List?)?.length ?? 0).compareTo(
            ((a['members'] as List?)?.length ?? 0)
          )
        );
        break;
      case 'recent':
      default:
        filteredGroups.sort((a, b) {
          final aTime = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(1970);
          final bTime = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(1970);
          return bTime.compareTo(aTime);
        });
        break;
    }
  }

  Future<void> _createNewGroup() async {
    // Get all users for group creation
    final usersResponse = await supabase
        .from('users')
        .select('id, username')
        .neq('id', widget.currentUserId);

    final allUsers = usersResponse.map((user) => create_group.User(
      id: user['id'],
      name: user['username'] ?? 'Unknown User',
    )).toList();

    if (mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => create_group.CreateGroupScreen(
            currentUserId: widget.currentUserId,
            allUsers: allUsers,
          ),
        ),
      );

      if (result != null) {
        _loadGroups(); // Refresh the list
      }
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sort Groups By',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.access_time,
                color: _sortBy == 'recent' ? Colors.pink : Colors.grey,
              ),
              title: const Text('Recent'),
              trailing: _sortBy == 'recent' ? const Icon(Icons.check, color: Colors.pink) : null,
              onTap: () {
                setState(() {
                  _sortBy = 'recent';
                  _filterGroups();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.sort_by_alpha,
                color: _sortBy == 'name' ? Colors.pink : Colors.grey,
              ),
              title: const Text('Name'),
              trailing: _sortBy == 'name' ? const Icon(Icons.check, color: Colors.pink) : null,
              onTap: () {
                setState(() {
                  _sortBy = 'name';
                  _filterGroups();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.people,
                color: _sortBy == 'members' ? Colors.pink : Colors.grey,
              ),
              title: const Text('Member Count'),
              trailing: _sortBy == 'members' ? const Icon(Icons.check, color: Colors.pink) : null,
              onTap: () {
                setState(() {
                  _sortBy = 'members';
                  _filterGroups();
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search groups...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                autofocus: true,
              )
            : const Text('Group Chats 💫'),
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _searchQuery = '';
                  _filterGroups();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortOptions,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGroups,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All Groups'),
            Tab(text: 'My Groups'),
            Tab(text: 'Public'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGroupsList(filteredGroups),
                _buildGroupsList(_getMyGroups()),
                _buildGroupsList(_getPublicGroups()),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewGroup,
        backgroundColor: Colors.pinkAccent,
        icon: const Icon(Icons.add),
        label: const Text('New Group'),
      ),
    );
  }

  List<Map<String, dynamic>> _getMyGroups() {
    return filteredGroups.where((group) => 
      group['owner_id'] == widget.currentUserId
    ).toList();
  }

  List<Map<String, dynamic>> _getPublicGroups() {
    return filteredGroups.where((group) => 
      group['is_public'] == true
    ).toList();
  }

  Widget _buildGroupsList(List<Map<String, dynamic>> groups) {
    if (groups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No groups found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Create a new group to get started!',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGroups,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return _buildGroupCard(group);
        },
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    final name = group['name'] ?? 'Unnamed Group';
    final description = group['description'] as String?;
    final memberCount = (group['members'] as List?)?.length ?? 0;
    final chatId = group['id'];
    final iconUrl = group['icon_url'] as String?;
    final emoji = group['emoji'] ?? '💬';
    final isOwner = group['owner_id'] == widget.currentUserId;
    final isPublic = group['is_public'] == true;
    final lastMessage = group['last_message'] as List?;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Use integrated navigation
          GroupsIntegration.navigateToGroupChat(
            context,
            currentUserId: widget.currentUserId,
            chatId: chatId,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Group Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.pink.shade50,
                ),
                child: iconUrl != null && iconUrl.isNotEmpty
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: iconUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.pink.shade100,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.pink.shade100,
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              
              // Group Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isOwner)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Owner',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        if (isPublic)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Public',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (description != null && description.isNotEmpty)
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$memberCount members',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        if (lastMessage != null && lastMessage.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Last: ${lastMessage.first['text'] ?? 'Media'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Quick Actions - Use integrated menu
              IconButton(
                icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                onPressed: () => GroupsIntegration.showGroupActionsMenu(
                  context,
                  groupId: group['id'],
                  currentUserId: widget.currentUserId,
                ),
              ),
              
              // Chevron
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
