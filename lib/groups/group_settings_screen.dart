import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'group_navigation_helper.dart';

class GroupSettingsScreen extends StatefulWidget {
  final String currentUserId;
  final String chatId;

  const GroupSettingsScreen({
    super.key,
    required this.currentUserId,
    required this.chatId,
  });

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> 
    with TickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _emojiController;
  late TabController _tabController;
  
  Map<String, String> personalNicknames = {};
  Map<String, dynamic> groupSettings = {};
  Map<String, Map<String, dynamic>> memberDetails = {};

  String avatarUrl = '';
  String bannerUrl = '';
  String ownerId = '';
  bool isLoading = true;
  bool isPrivate = false;
  bool allowMemberInvites = true;
  bool muteNotifications = false;
  bool showMediaPreview = true;
  bool allowMessageForwarding = true;
  bool requireAdminApproval = false;
  
  int messageCount = 0;
  int mediaCount = 0;
  DateTime? createdAt;
  DateTime? lastActivity;

  List<String> adminIds = [];
  List<String> memberIds = [];
  List<String> bannedUserIds = [];
  List<String> mutedUserIds = [];

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    _emojiController = TextEditingController();
    _tabController = TabController(length: 4, vsync: this);
    
    _loadGroup();
    _loadPersonalNicknames();
    _loadGroupStatistics();
    _loadMemberDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _emojiController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroup() async {
    try {
      final chat = await supabase
          .from('chats')
          .select('''
            *,
            message_count:messages(count),
            media_count:messages(count).not(imageUrl.is.null,videoUrl.is.null,audioUrl.is.null)
          ''')
          .eq('id', widget.chatId)
          .single();

      _nameController.text = chat['name'] ?? '';
      _descController.text = chat['description'] ?? '';
      _emojiController.text = chat['emoji'] ?? '💬';
      avatarUrl = chat['icon_url'] ?? '';
      bannerUrl = chat['banner_url'] ?? '';
      ownerId = chat['owner_id'] ?? '';
      adminIds = List<String>.from(chat['admins'] ?? []);
      memberIds = List<String>.from(chat['members'] ?? []);
      bannedUserIds = List<String>.from(chat['banned_users'] ?? []);
      mutedUserIds = List<String>.from(chat['muted_users'] ?? []);
      
      isPrivate = chat['is_private'] ?? false;
      allowMemberInvites = chat['allow_member_invites'] ?? true;
      muteNotifications = chat['mute_notifications'] ?? false;
      showMediaPreview = chat['show_media_preview'] ?? true;
      allowMessageForwarding = chat['allow_message_forwarding'] ?? true;
      requireAdminApproval = chat['require_admin_approval'] ?? false;
      
      createdAt = DateTime.tryParse(chat['created_at'] ?? '');
      lastActivity = DateTime.tryParse(chat['last_activity'] ?? '');

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading group: $e')),
        );
      }
    }
  }

  Future<void> _loadGroupStatistics() async {
    try {
      // Get message count
      final messageCountResult = await supabase
          .from('messages')
          .select('id')
          .eq('chat_id', widget.chatId);
      
      // Get media count
      final mediaCountResult = await supabase
          .from('messages')
          .select('id')
          .eq('chat_id', widget.chatId)
          .or('imageUrl.not.is.null,videoUrl.not.is.null,audioUrl.not.is.null');

      setState(() {
        messageCount = messageCountResult.length;
        mediaCount = mediaCountResult.length;
      });
    } catch (e) {
      // Handle error silently for statistics
    }
  }

  Future<void> _loadMemberDetails() async {
    try {
      final members = await supabase
          .from('users')
          .select('id, username, avatar_url, last_seen_at, is_online')
          .inFilter('id', memberIds);

      final Map<String, Map<String, dynamic>> details = {};
      for (final member in members) {
        details[member['id']] = member;
      }

      setState(() {
        memberDetails = details;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  // Enhanced settings update methods
  Future<void> _updateGroupSetting(String field, dynamic value) async {
    try {
      await supabase.from('chats').update({field: value}).eq('id', widget.chatId);
      
      setState(() {
        switch (field) {
          case 'is_private':
            isPrivate = value;
            break;
          case 'allow_member_invites':
            allowMemberInvites = value;
            break;
          case 'mute_notifications':
            muteNotifications = value;
            break;
          case 'show_media_preview':
            showMediaPreview = value;
            break;
          case 'allow_message_forwarding':
            allowMessageForwarding = value;
            break;
          case 'require_admin_approval':
            requireAdminApproval = value;
            break;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Setting updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating setting: $e')),
      );
    }
  }

  void _showGroupInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Group Information',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Created', createdAt != null 
                ? '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}' 
                : 'Unknown'),
            _buildInfoRow('Members', '${memberIds.length}'),
            _buildInfoRow('Admins', '${adminIds.length}'),
            _buildInfoRow('Messages', '$messageCount'),
            _buildInfoRow('Media Files', '$mediaCount'),
            _buildInfoRow('Group Type', isPrivate ? 'Private' : 'Public'),
            _buildInfoRow('Member Invites', allowMemberInvites ? 'Allowed' : 'Restricted'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Use integrated navigation
                GroupNavigationHelper.navigateToGroupMedia(
                  context,
                  chatId: widget.chatId,
                  currentUserId: widget.currentUserId,
                );
              },
              icon: const Icon(Icons.photo_library),
              label: const Text('View Shared Media'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Export Group Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.message, color: Colors.blue),
              title: const Text('Export Messages'),
              subtitle: const Text('Export all group messages as text'),
              onTap: () {
                Navigator.pop(context);
                _exportMessages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo, color: Colors.green),
              title: const Text('Export Media'),
              subtitle: const Text('Get list of all shared media URLs'),
              onTap: () {
                Navigator.pop(context);
                _exportMedia();
              },
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.orange),
              title: const Text('Export Member List'),
              subtitle: const Text('Export member information'),
              onTap: () {
                Navigator.pop(context);
                _exportMembers();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportMessages() async {
    try {
      final messages = await supabase
          .from('messages')
          .select('''
            text,
            timestamp,
            users!messages_sender_id_fkey(username)
          ''')
          .eq('chat_id', widget.chatId)
          .order('timestamp', ascending: true);

      String exportText = 'Group Chat Export\n';
      exportText += 'Group: ${_nameController.text}\n';
      exportText += 'Exported: ${DateTime.now()}\n\n';

      for (final message in messages) {
        final sender = message['users']?['username'] ?? 'Unknown';
        final text = message['text'] ?? '[Media]';
        final timestamp = DateTime.tryParse(message['timestamp'] ?? '');
        final timeStr = timestamp != null 
            ? '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}'
            : '';
        
        exportText += '[$timeStr] $sender: $text\n';
      }

      await Clipboard.setData(ClipboardData(text: exportText));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Messages exported to clipboard')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _exportMedia() async {
    try {
      final media = await supabase
          .from('messages')
          .select('imageUrl, videoUrl, audioUrl, timestamp')
          .eq('chat_id', widget.chatId)
          .or('imageUrl.not.is.null,videoUrl.not.is.null,audioUrl.not.is.null')
          .order('timestamp', ascending: true);

      String exportText = 'Group Media Export\n';
      exportText += 'Group: ${_nameController.text}\n\n';

      for (final item in media) {
        final url = item['imageUrl'] ?? item['videoUrl'] ?? item['audioUrl'];
        if (url != null) {
          exportText += '$url\n';
        }
      }

      await Clipboard.setData(ClipboardData(text: exportText));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Media URLs exported to clipboard')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _exportMembers() async {
    try {
      String exportText = 'Group Members Export\n';
      exportText += 'Group: ${_nameController.text}\n\n';

      for (final memberId in memberIds) {
        final details = memberDetails[memberId];
        final username = details?['username'] ?? 'Unknown';
        final role = memberId == ownerId 
            ? 'Owner' 
            : adminIds.contains(memberId) 
                ? 'Admin' 
                : 'Member';
        
        exportText += '$username - $role\n';
      }

      await Clipboard.setData(ClipboardData(text: exportText));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member list exported to clipboard')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _loadPersonalNicknames() async {
    final nickRes = await supabase
        .from('group_nicknames')
        .select('nicknames')
        .eq('chat_id', widget.chatId)
        .eq('user_id', widget.currentUserId)
        .maybeSingle();

    if (nickRes != null && nickRes['nicknames'] is Map) {
      personalNicknames = Map<String, String>.from(nickRes['nicknames']);
    }
  }

  Future<void> _saveField(String field, dynamic value) async {
    await supabase.from('chats').update({field: value}).eq('id', widget.chatId);
  }

  Future<void> _uploadImage(String field, ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null) return;

    final bytes = await File(picked.path).readAsBytes();
    final filename =
        '${widget.chatId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final bucket = field == 'avatar' ? 'group_avatars' : 'group_banners';

    await supabase.storage.from(bucket).uploadBinary(filename, bytes);
    final url = supabase.storage.from(bucket).getPublicUrl(filename);

    await _saveField('${field}Url', url);
    setState(() {
      if (field == 'avatar') avatarUrl = url;
      if (field == 'banner') bannerUrl = url;
    });
  }

  void _editNickname(String uid, String fallback, String? current) {
    final controller = TextEditingController(text: current ?? fallback);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Set Nickname'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final updated = controller.text.trim();
              personalNicknames[uid] = updated;
              await supabase.from('group_nicknames').upsert({
                'chat_id': widget.chatId,
                'user_id': widget.currentUserId,
                'nicknames': personalNicknames,
              });
              if (context.mounted) {
                setState(() {});
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAdmin(String uid, {required bool promote}) async {
    final updated = promote
        ? {...adminIds, uid}
        : adminIds.where((id) => id != uid).toSet();

    await _saveField('admins', updated.toList());
    await _loadGroup();
  }

  Future<void> _transferOwnership(String uid) async {
    final updatedAdmins = {...adminIds, uid}.toList();
    await supabase.from('chats').update({
      'ownerId': uid,
      'admins': updatedAdmins,
    }).eq('id', widget.chatId);
    await _loadGroup();
  }

  Future<void> _removeMember(String uid) async {
    final updated = memberIds.where((id) => id != uid).toList();
    await _saveField('members', updated);
    await _loadGroup();
  }

  Future<void> _showAddMembersDialog() async {
    final users = await supabase.from('users').select('id, username');
    final existing = memberIds.toSet();
    final selected = <String>{};

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Members'),
          content: SizedBox(
            height: 400,
            width: double.maxFinite,
            child: ListView(
              children: users
                  .where((u) => !existing.contains(u['id']))
                  .map((user) => CheckboxListTile(
                        value: selected.contains(user['id']),
                        onChanged: (val) {
                          setDialogState(() {
                            if (val == true) {
                              selected.add(user['id']);
                            } else {
                              selected.remove(user['id']);
                            }
                          });
                        },
                        title: Text(user['username'] ?? 'Unknown'),
                      ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final newMembers = [...existing, ...selected];
                await _saveField('members', newMembers);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  await _loadGroup();
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isOwner = widget.currentUserId == ownerId;
    final isAdmin = isOwner || adminIds.contains(widget.currentUserId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Settings'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showGroupInfo,
          ),
          if (isAdmin)
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'export',
                  child: ListTile(
                    leading: Icon(Icons.download),
                    title: Text('Export Data'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete Group', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'export') _showExportOptions();
                if (value == 'delete') _confirmDeleteGroup();
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Info'),
            Tab(icon: Icon(Icons.people), text: 'Members'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
            Tab(icon: Icon(Icons.security), text: 'Privacy'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(isAdmin),
          _buildMembersTab(isOwner, isAdmin),
          _buildSettingsTab(isAdmin),
          _buildPrivacyTab(isAdmin),
        ],
      ),
    );
  }

  Widget _buildInfoTab(bool isAdmin) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Banner Section
          Stack(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: bannerUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(bannerUrl), 
                          fit: BoxFit.cover,
                        )
                      : null,
                  gradient: bannerUrl.isEmpty 
                      ? LinearGradient(
                          colors: [Colors.pink.shade300, Colors.pink.shade500],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                ),
                child: bannerUrl.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, color: Colors.white, size: 48),
                            SizedBox(height: 8),
                            Text(
                              'No Banner Set',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : null,
              ),
              if (isAdmin)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    onPressed: () => _uploadImage('banner', ImageSource.gallery),
                    backgroundColor: Colors.black54,
                    child: const Icon(Icons.camera_alt, color: Colors.white),
                  ),
                ),
            ],
          ),

          // Group Info Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Group Avatar
                    Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.pink.shade100,
                            image: avatarUrl.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(avatarUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: avatarUrl.isEmpty
                              ? Center(
                                  child: Text(
                                    _emojiController.text,
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                )
                              : null,
                        ),
                        if (isAdmin)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _uploadImage('avatar', ImageSource.gallery),
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.pink,
                                ),
                                padding: const EdgeInsets.all(6),
                                child: const Icon(
                                  Icons.camera_alt, 
                                  color: Colors.white, 
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // Group Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _nameController,
                                  enabled: isAdmin,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    border: isAdmin 
                                        ? const UnderlineInputBorder()
                                        : InputBorder.none,
                                    hintText: 'Group Name',
                                  ),
                                  onSubmitted: (val) => _saveField('name', val.trim()),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: isAdmin ? _showEmojiPicker : null,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.pink.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _emojiController.text,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _descController,
                            enabled: isAdmin,
                            maxLines: 3,
                            decoration: InputDecoration(
                              border: isAdmin 
                                  ? const OutlineInputBorder()
                                  : InputBorder.none,
                              hintText: 'Group description...',
                              contentPadding: const EdgeInsets.all(12),
                            ),
                            onSubmitted: (val) => _saveField('description', val.trim()),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Quick Stats
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Group Statistics',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              icon: Icons.people,
                              label: 'Members',
                              value: '${memberIds.length}',
                            ),
                            _buildStatItem(
                              icon: Icons.message,
                              label: 'Messages',
                              value: '$messageCount',
                            ),
                            _buildStatItem(
                              icon: Icons.photo,
                              label: 'Media',
                              value: '$mediaCount',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Quick Actions
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.photo_library, color: Colors.pink),
                        title: const Text('Shared Media'),
                        subtitle: Text('$mediaCount files shared'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Use integrated navigation
                          GroupNavigationHelper.navigateToGroupMedia(
                            context,
                            chatId: widget.chatId,
                            currentUserId: widget.currentUserId,
                          );
                        },
                      ),
                      if (isAdmin) ...[
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.person_add, color: Colors.green),
                          title: const Text('Add Members'),
                          subtitle: const Text('Invite people to join'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _showAddMembersDialog,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.pink, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  void _showEmojiPicker() {
    final emojis = ['💬', '👥', '🎉', '💕', '🌟', '🔥', '💎', '⚡', '🌈', '🎨',
                  '🎵', '🎮', '📚', '☕', '🍕', '🏠', '💼', '🎯', '🚀', '💡'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Group Emoji'),
        content: SizedBox(
          width: double.maxFinite,
          height: 200,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: emojis.length,
            itemBuilder: (context, index) {
              final emoji = emojis[index];
              return GestureDetector(
                onTap: () {
                  _emojiController.text = emoji;
                  _saveField('emoji', emoji);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: _emojiController.text == emoji 
                        ? Colors.pink.withOpacity(0.2)
                        : Colors.transparent,
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text(
          'Are you sure you want to delete this group? This action cannot be undone and all messages will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _deleteGroup();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGroup() async {
    try {
      // Delete all messages first
      await supabase.from('messages').delete().eq('chat_id', widget.chatId);
      
      // Delete the group
      await supabase.from('chats').delete().eq('id', widget.chatId);
      
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting group: $e')),
        );
      }
    }
  }

  Widget _buildMembersTab(bool isOwner, bool isAdmin) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Add Members Section
          if (isAdmin)
            Card(
              margin: const EdgeInsets.all(16),
              child: ListTile(
                leading: const Icon(Icons.person_add, color: Colors.green),
                title: const Text('Add Members'),
                subtitle: const Text('Invite people to join the group'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showAddMembersDialog,
              ),
            ),

          // Members List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Members (${memberIds.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isAdmin)
                  TextButton.icon(
                    onPressed: _showBulkActions,
                    icon: const Icon(Icons.more_horiz),
                    label: const Text('Actions'),
                  ),
              ],
            ),
          ),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: memberIds.length,
            itemBuilder: (context, index) {
              final uid = memberIds[index];
              final memberDetail = memberDetails[uid];
              final name = memberDetail?['username'] ?? 'Unknown';
              final avatarUrl = memberDetail?['avatar_url'];
              final nickname = personalNicknames[uid];
              final isOnline = memberDetail?['is_online'] ?? false;
              final lastSeen = memberDetail?['last_seen_at'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundImage: avatarUrl != null
                            ? CachedNetworkImageProvider(avatarUrl)
                            : null,
                        backgroundColor: Colors.pink.shade100,
                        child: avatarUrl == null
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      if (isOnline)
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
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          nickname ?? name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (uid == ownerId)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '👑 Owner',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (uid != ownerId && adminIds.contains(uid))
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '🛡 Admin',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    isOnline 
                        ? 'Online' 
                        : lastSeen != null 
                            ? 'Last seen ${_formatLastSeen(lastSeen)}'
                            : 'Offline',
                    style: TextStyle(
                      color: isOnline ? Colors.green : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  trailing: (isOwner && uid != widget.currentUserId) ||
                          (isAdmin && uid != widget.currentUserId && uid != ownerId)
                      ? PopupMenuButton<String>(
                          onSelected: (value) => _handleMemberAction(value, uid, name, nickname),
                          itemBuilder: (_) => _buildMemberMenuItems(uid, isOwner),
                        )
                      : null,
                  onTap: () => _showMemberProfile(uid, name, nickname),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(bool isAdmin) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Group Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Mute Notifications'),
                    subtitle: const Text('Turn off notifications for this group'),
                    value: muteNotifications,
                    onChanged: (value) => _updateGroupSetting('mute_notifications', value),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Show Media Preview'),
                    subtitle: const Text('Show previews of shared images and videos'),
                    value: showMediaPreview,
                    onChanged: (value) => _updateGroupSetting('show_media_preview', value),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (isAdmin) ...[
              const Text(
                'Admin Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Allow Member Invites'),
                      subtitle: const Text('Let members invite others to join'),
                      value: allowMemberInvites,
                      onChanged: (value) => _updateGroupSetting('allow_member_invites', value),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Allow Message Forwarding'),
                      subtitle: const Text('Allow messages to be forwarded outside group'),
                      value: allowMessageForwarding,
                      onChanged: (value) => _updateGroupSetting('allow_message_forwarding', value),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Require Admin Approval'),
                      subtitle: const Text('New members need admin approval to join'),
                      value: requireAdminApproval,
                      onChanged: (value) => _updateGroupSetting('require_admin_approval', value),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Danger Zone
            Card(
              color: Colors.red.shade50,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.exit_to_app, color: Colors.red),
                    title: const Text('Leave Group'),
                    subtitle: const Text('You will no longer receive messages'),
                    onTap: _confirmLeaveGroup,
                  ),
                  if (isAdmin) ...[
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.clear_all, color: Colors.red),
                      title: const Text('Clear Chat History'),
                      subtitle: const Text('Delete all messages (cannot be undone)'),
                      onTap: _confirmClearHistory,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyTab(bool isAdmin) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy & Security',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  if (isAdmin)
                    SwitchListTile(
                      title: const Text('Private Group'),
                      subtitle: const Text('Only members can see group info and messages'),
                      value: isPrivate,
                      onChanged: (value) => _updateGroupSetting('is_private', value),
                    ),
                  
                  ListTile(
                    leading: const Icon(Icons.block, color: Colors.red),
                    title: const Text('Blocked Users'),
                    subtitle: Text('${bannedUserIds.length} users blocked'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showBlockedUsers,
                  ),
                  
                  const Divider(),
                  
                  ListTile(
                    leading: const Icon(Icons.volume_off, color: Colors.orange),
                    title: const Text('Muted Users'),
                    subtitle: Text('${mutedUserIds.length} users muted'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showMutedUsers,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.security, color: Colors.blue),
                    title: const Text('Group Permissions'),
                    subtitle: const Text('Manage what members can do'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showPermissionsDialog,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.history, color: Colors.green),
                    title: const Text('Activity Log'),
                    subtitle: const Text('View group activity history'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showActivityLog,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (isAdmin)
              Card(
                color: Colors.orange.shade50,
                child: ListTile(
                  leading: const Icon(Icons.backup, color: Colors.orange),
                  title: const Text('Export Group Data'),
                  subtitle: const Text('Download messages, media, and member info'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showExportOptions,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper methods for the new functionality
  String _formatLastSeen(String lastSeenStr) {
    final lastSeen = DateTime.tryParse(lastSeenStr);
    if (lastSeen == null) return 'Unknown';
    
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    
    return '${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
  }

  void _handleMemberAction(String action, String uid, String name, String? nickname) {
    switch (action) {
      case 'remove':
        _removeMember(uid);
        break;
      case 'nickname':
        _editNickname(uid, name, nickname);
        break;
      case 'makeAdmin':
        _toggleAdmin(uid, promote: true);
        break;
      case 'removeAdmin':
        _toggleAdmin(uid, promote: false);
        break;
      case 'transferOwner':
        _transferOwnership(uid);
        break;
      case 'mute':
        _muteUser(uid);
        break;
      case 'block':
        _blockUser(uid);
        break;
    }
  }

  List<PopupMenuItem<String>> _buildMemberMenuItems(String uid, bool isOwner) {
    final items = <PopupMenuItem<String>>[
      const PopupMenuItem(
        value: 'nickname',
        child: ListTile(
          leading: Icon(Icons.edit),
          title: Text('Set Nickname'),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    ];

    if (isOwner) {
      if (!adminIds.contains(uid)) {
        items.add(const PopupMenuItem(
          value: 'makeAdmin',
          child: ListTile(
            leading: Icon(Icons.admin_panel_settings, color: Colors.blue),
            title: Text('Promote to Admin'),
            contentPadding: EdgeInsets.zero,
          ),
        ));
      } else {
        items.add(const PopupMenuItem(
          value: 'removeAdmin',
          child: ListTile(
            leading: Icon(Icons.remove_moderator, color: Colors.orange),
            title: Text('Demote from Admin'),
            contentPadding: EdgeInsets.zero,
          ),
        ));
      }

      items.addAll([
        const PopupMenuItem(
          value: 'transferOwner',
          child: ListTile(
            leading: Icon(Icons.transfer_within_a_station, color: Colors.purple),
            title: Text('Transfer Ownership'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'mute',
          child: ListTile(
            leading: Icon(Icons.volume_off, color: Colors.orange),
            title: Text('Mute User'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'block',
          child: ListTile(
            leading: Icon(Icons.block, color: Colors.red),
            title: Text('Block User'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'remove',
          child: ListTile(
            leading: Icon(Icons.person_remove, color: Colors.red),
            title: Text('Remove from Group'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ]);
    }

    return items;
  }

  // Additional helper methods for new functionality
  void _showBulkActions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bulk actions coming soon!')),
    );
  }

  void _showMemberProfile(String uid, String name, String? nickname) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing profile for ${nickname ?? name}')),
    );
  }

  void _confirmLeaveGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _leaveGroup();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveGroup() async {
    try {
      final updatedMembers = memberIds.where((id) => id != widget.currentUserId).toList();
      await _saveField('members', updatedMembers);
      
      if (mounted) {
        // Navigate back to group list instead of just going to first route
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Left group successfully')),
        );
        
        // If we can find GroupListScreen in the route stack, refresh it
        // This is a simple approach - in a real app you might use state management
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error leaving group: $e')),
        );
      }
    }
  }

  void _confirmClearHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Clear history feature coming soon!')),
    );
  }

  void _showBlockedUsers() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Blocked users management coming soon!')),
    );
  }

  void _showMutedUsers() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Muted users management coming soon!')),
    );
  }

  void _showPermissionsDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Permissions management coming soon!')),
    );
  }

  void _showActivityLog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Activity log coming soon!')),
    );
  }

  Future<void> _muteUser(String uid) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User mute feature coming soon!')),
    );
  }

  Future<void> _blockUser(String uid) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User block feature coming soon!')),
    );
  }

}