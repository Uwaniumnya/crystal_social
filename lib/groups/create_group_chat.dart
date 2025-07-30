import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'group_chat_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  final String currentUserId;
  final List<User> allUsers;

  const CreateGroupScreen({
    super.key,
    required this.currentUserId,
    required this.allUsers,
  });

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedUserIds = {};
  
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedEmoji = '💬';
  File? _groupIcon;
  bool _isPublic = false;
  bool _allowInvites = true;
  bool _isCreating = false;
  
  final List<String> _availableEmojis = [
    '💬', '👥', '🎉', '💕', '🌟', '🔥', '💎', '⚡', '🌈', '🎨',
    '🎵', '🎮', '📚', '☕', '🍕', '🏠', '💼', '🎯', '🚀', '💡'
  ];

  List<User> get filteredUsers {
    if (_searchQuery.isEmpty) return widget.allUsers;
    return widget.allUsers.where((user) => 
      user.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  void initState() {
    super.initState();
    _selectedUserIds.add(widget.currentUserId); // auto-include self
    _tabController = TabController(length: 2, vsync: this);
    
    // Add search listener
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      _showError('Please enter a group name');
      return;
    }
    
    if (_selectedUserIds.length < 2) {
      _showError('Please select at least one other member');
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final groupId = const Uuid().v4();
      String? groupIconUrl;

      // Upload group icon if selected
      if (_groupIcon != null) {
        final bytes = await _groupIcon!.readAsBytes();
        final filename = 'group_icons/${groupId}.jpg';
        
        await Supabase.instance.client.storage
            .from('group_icons')
            .uploadBinary(filename, bytes);
            
        groupIconUrl = Supabase.instance.client.storage
            .from('group_icons')
            .getPublicUrl(filename);
      }

      await Supabase.instance.client.from('chats').insert({
        'id': groupId,
        'name': groupName,
        'description': _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        'is_group': true,
        'members': _selectedUserIds.toList(),
        'created_at': DateTime.now().toIso8601String(),
        'owner_id': widget.currentUserId,
        'admins': [widget.currentUserId],
        'emoji': _selectedEmoji,
        'icon_url': groupIconUrl,
        'is_public': _isPublic,
        'allow_member_invites': _allowInvites,
        'member_count': _selectedUserIds.length,
      });

      if (mounted) {
        // Navigate directly to the new group chat
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GroupChatScreen(
              currentUserId: widget.currentUserId,
              chatId: groupId,
            ),
          ),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Group "$groupName" created successfully!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View All Groups',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pop(context); // Go back to group list
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to create group: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _pickGroupIcon() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    
    if (picked != null) {
      setState(() {
        _groupIcon = File(picked.path);
      });
    }
  }

  void _showEmojiPicker() {
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
            itemCount: _availableEmojis.length,
            itemBuilder: (context, index) {
              final emoji = _availableEmojis[index];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedEmoji = emoji;
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: _selectedEmoji == emoji 
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group Chat'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Details'),
            Tab(icon: Icon(Icons.people), text: 'Members'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildMembersTab(),
              ],
            ),
          ),
          _buildCreateButton(),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Icon Section
          Center(
            child: GestureDetector(
              onTap: _pickGroupIcon,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.pink.shade50,
                  border: Border.all(color: Colors.pink.shade200, width: 2),
                ),
                child: _groupIcon != null
                    ? ClipOval(
                        child: Image.file(
                          _groupIcon!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 30,
                            color: Colors.pink.shade300,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add Photo',
                            style: TextStyle(
                              color: Colors.pink.shade300,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Group Name
          TextField(
            controller: _groupNameController,
            decoration: InputDecoration(
              labelText: 'Group Name *',
              hintText: 'Enter group name',
              prefixIcon: const Icon(Icons.group),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLength: 50,
          ),
          const SizedBox(height: 16),

          // Group Description
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description (Optional)',
              hintText: 'What\'s this group about?',
              prefixIcon: const Icon(Icons.description),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 3,
            maxLength: 200,
          ),
          const SizedBox(height: 16),

          // Emoji Selector
          ListTile(
            leading: const Icon(Icons.emoji_emotions),
            title: const Text('Group Emoji'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: _showEmojiPicker,
          ),
          const Divider(),

          // Settings
          SwitchListTile(
            title: const Text('Public Group'),
            subtitle: const Text('Anyone can find and join this group'),
            value: _isPublic,
            onChanged: (value) {
              setState(() {
                _isPublic = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Allow Member Invites'),
            subtitle: const Text('Let members invite others to the group'),
            value: _allowInvites,
            onChanged: (value) {
              setState(() {
                _allowInvites = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        // Selected Members Count
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.pink.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.people, color: Colors.pink.shade600),
              const SizedBox(width: 8),
              Text(
                '${_selectedUserIds.length} members selected',
                style: TextStyle(
                  color: Colors.pink.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Members List
        Expanded(
          child: ListView.builder(
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              final isSelected = _selectedUserIds.contains(user.id);
              final isCurrentUser = user.id == widget.currentUserId;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: CheckboxListTile(
                  secondary: CircleAvatar(
                    backgroundColor: Colors.pink.shade100,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: Colors.pink.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: isCurrentUser 
                      ? const Text('You (Group Admin)') 
                      : null,
                  value: isSelected,
                  onChanged: isCurrentUser 
                      ? null 
                      : (val) {
                          setState(() {
                            if (val == true) {
                              _selectedUserIds.add(user.id);
                            } else {
                              _selectedUserIds.remove(user.id);
                            }
                          });
                        },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pinkAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          onPressed: _isCreating ? null : _createGroup,
          child: _isCreating
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Creating Group...'),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_selectedEmoji),
                    const SizedBox(width: 8),
                    const Text(
                      'Create Group',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// Local User model (not Supabase AuthUser)
class User {
  final String id;
  final String name;

  User({required this.id, required this.name});
}
