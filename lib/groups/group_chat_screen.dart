import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

import '../widgets/message_bubble.dart';
import '../widgets/sticker_picker.dart';
import 'groups_integration.dart';
import 'group_message_service.dart';
import 'groups_production_config.dart';
import '../chat/media_viewer.dart'; 
import '../rewards/rewards_manager.dart'; 

class GroupChatScreen extends StatefulWidget {
  final String currentUserId;
  final String chatId;

  const GroupChatScreen({
    super.key,
    required this.currentUserId,
    required this.chatId,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final supabase = Supabase.instance.client;

  String groupName = 'Group Chat';
  bool loadingGroupInfo = true;
  bool showSearch = false;
  bool showStickerPicker = false;
  String _searchQuery = '';

  Map<String, String> memberNames = {};
  Map<String, String> memberAvatars = {};
  Map<String, String> personalNicknames = {};
  Map<String, bool> typingUsers = {};

  String? _replyToMessageId;
  String? _replyToText;
  String? _replyToSenderName;
  String? myDecorationPath;
  String? otherDecorationPath;

  String? _reactingToMessageId;
  String? _editingMessageId;
  Offset? _pickerPosition;

  // Pet-related variables
  List<Map<String, dynamic>> userPets = [];
  final Map<String, AnimationController> _petAnimations = {};
  bool _petsVisible = false;

  // Enhanced messaging service
  GroupMessageService? _messageService;
  
  // Enhanced rewards system integration
  late RewardsManager _rewardsManager;

  List<Map<String, dynamic>> messages = [];
  List<Map<String, dynamic>> get filteredMessages {
    if (_searchQuery.isEmpty) return messages;
    final query = _searchQuery.toLowerCase();
    return messages.where((msg) {
      final text = (msg['text'] ?? '').toString().toLowerCase();
      final senderName = (memberNames[msg['sender_id']] ?? '').toLowerCase();
      return text.contains(query) || senderName.contains(query);
    }).toList();
  }

  late RealtimeChannel _realtimeChannel;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _rewardsManager = RewardsManager(supabase);
    _initializeMessageService();
    _loadGroupData();
    _loadPersonalNicknames();
    _subscribeToMessages();
    _loadUserDecorationPath();
    _loadUserPets();
    
    // Add text change listener for search
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  /// Initialize the enhanced message service
  void _initializeMessageService() {
    _messageService = GroupMessageService(
      groupId: widget.chatId,
      currentUserId: widget.currentUserId,
      context: context,
    );
    
    // Listen to message service updates
    _messageService!.addListener(() {
      if (mounted) {
        setState(() {
          // Update messages from service if available
          if (_messageService!.messages.isNotEmpty) {
            messages = _messageService!.messages;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _realtimeChannel.unsubscribe();
    _controller.dispose();
    _searchController.dispose();
    _typingTimer?.cancel();
    
    // Dispose message service
    _messageService?.dispose();
    
    // Dispose pet animations
    for (var controller in _petAnimations.values) {
      controller.dispose();
    }
    
    super.dispose();
  }

  // Load user's pets from the home space
  Future<void> _loadUserPets() async {
    try {
      final homeData = await supabase
          .from('user_home')
          .select('*')
          .eq('user_id', widget.currentUserId)
          .maybeSingle();

      if (homeData != null) {
        final placeables = await supabase
            .from('placeable_items')
            .select('*')
            .eq('category_id', 3); // Pets are category_id 3

        List<Map<String, dynamic>> pets = [];
        for (var item in placeables) {
          final key = item['name'].toString().toLowerCase().replaceAll(" ", "_");
          if (homeData[key] == true) {
            pets.add(item);
            
            // Create animation controller for this pet
            final controller = AnimationController(
              vsync: this,
              duration: const Duration(milliseconds: 300),
              lowerBound: 0.0,
              upperBound: 1.0,
            );
            _petAnimations[key] = controller;
            _startPetAnimation(key);
          }
        }

        setState(() {
          userPets = pets;
          _petsVisible = pets.isNotEmpty;
        });
      }
    } catch (e) {
      print('Error loading pets: $e');
    }
  }

  // Start bouncing animation for pets
  void _startPetAnimation(String key) {
    Timer.periodic(Duration(seconds: 3 + (userPets.length * 2)), (timer) {
      if (!mounted || !_petAnimations.containsKey(key)) {
        timer.cancel();
        return;
      }
      _petAnimations[key]?.forward(from: 0.0);
    });
  }

  // Load the user's decoration path from Supabase
  Future<void> _loadUserDecorationPath() async {
    final user = await supabase
        .from('users')
        .select('avatar_decoration')
        .eq('id', widget.currentUserId)
        .maybeSingle();

    if (user != null && user['avatar_decoration'] != null) {
      setState(() {
        myDecorationPath = user['avatar_decoration'];
      });
    }
  }

  Future<void> _loadGroupData() async {
    final chat = await supabase
        .from('chats')
        .select('name, members')
        .eq('id', widget.chatId)
        .single();

    groupName = chat['name'] ?? groupName;

    for (final uid in List<String>.from(chat['members'])) {
      final user = await supabase
          .from('users')
          .select('username, avatarUrl')
          .eq('id', uid)
          .maybeSingle();
      if (user != null) {
        memberNames[uid] = user['username'] ?? 'Unknown';
        memberAvatars[uid] = user['avatarUrl'] ?? '';
      }
    }

    setState(() => loadingGroupInfo = false);
  }

  Future<void> _loadPersonalNicknames() async {
    final nick = await supabase
        .from('group_nicknames')
        .select('nicknames')
        .eq('chat_id', widget.chatId)
        .eq('user_id', widget.currentUserId)
        .maybeSingle();

    if (nick != null) {
      personalNicknames = Map<String, String>.from(nick['nicknames'] ?? {});
    }
  }

  void _subscribeToMessages() {
    _realtimeChannel = supabase.channel('public:messages')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        table: 'messages',
        callback: (payload) {
          if (payload.newRecord['chat_id'] == widget.chatId) {
            setState(() {
              messages.insert(0, payload.newRecord);
            });
          }
        },
      )
      .subscribe();

    _loadInitialMessages();
  }

  Future<void> _loadInitialMessages() async {
    final res = await supabase
        .from('messages')
        .select()
        .eq('chat_id', widget.chatId)
        .order('timestamp', ascending: false)
        .limit(100);

    setState(() {
      messages = res;
    });
  }

  // Save edited message
  Future<void> _saveEditedMessage() async {
    if (_editingMessageId != null && _controller.text.trim().isNotEmpty) {
      await supabase.from('messages').update({
        'text': _controller.text.trim(),
        'isEdited': true,
      }).eq('id', _editingMessageId!);
      
      _controller.clear();
      setState(() {
        _editingMessageId = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message updated')),
      );
    }
  }

  // Enhanced send message with enhanced analysis and gem unlocking
  Future<void> _sendMessage({String? imageUrl, String? stickerUrl}) async {
    final text = _controller.text.trim();
    if (text.isEmpty && imageUrl == null && stickerUrl == null) return;

    // If editing, save the edited message instead
    if (_editingMessageId != null) {
      await _saveEditedMessage();
      return;
    }

    try {
      bool success = false;
      
      if (imageUrl != null || stickerUrl != null) {
        // Handle media messages through enhanced service
        if (_messageService != null) {
          // For now, use legacy method for media until service supports it better
          await _sendLegacyMessage(text: text, imageUrl: imageUrl, stickerUrl: stickerUrl);
          success = true;
        } else {
          await _sendLegacyMessage(text: text, imageUrl: imageUrl, stickerUrl: stickerUrl);
          success = true;
        }
      } else {
        // Use enhanced service for text messages with analysis and gem unlocking
        if (_messageService != null) {
          success = await _messageService!.sendMessage(text, replyToId: _replyToMessageId);
        } else {
          // Fallback to legacy method
          await _sendLegacyMessage(text: text);
          success = true;
        }
        
        // Track message sending for enhanced leveling system (2 points per message)
        await _rewardsManager.trackMessageSent(widget.currentUserId, context);
      }

      if (success) {
        _controller.clear();
        setState(() {
          _replyToMessageId = null;
          _replyToText = null;
          _replyToSenderName = null;
          showStickerPicker = false;
        });

        _scroll.animateTo(0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } catch (e) {
      GroupsDebugUtils.logError('GroupChatScreen', 'Error sending message: $e');
      // Show error to user if needed
    }
  }

  // Legacy message sending method for compatibility
  Future<void> _sendLegacyMessage({
    String? text,
    String? imageUrl,
    String? stickerUrl,
  }) async {
    final mentions = text != null
        ? RegExp(r'@(\w+)')
            .allMatches(text)
            .map((m) => m.group(1))
            .whereType<String>()
            .toList()
        : <String>[];

    await supabase.from('messages').insert({
      'chat_id': widget.chatId,
      'sender_id': widget.currentUserId,
      'text': text?.isEmpty == true ? null : text,
      'imageUrl': imageUrl,
      'stickerUrl': stickerUrl,
      'timestamp': DateTime.now().toIso8601String(),
      'effect': null,
      'isSecret': false,
      'reactions': {},
      'mentions': mentions,
      'replyTo': _replyToMessageId,
    });
  }

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);
    final bytes = await file.readAsBytes();
    final filename =
        '${widget.chatId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await supabase.storage.from('chat_images').uploadBinary(filename, bytes);

    final url = supabase.storage.from('chat_images').getPublicUrl(filename);
    _sendMessage(imageUrl: url);
  }

  Future<String?> _getReplyPreview(String? replyToId) async {
    if (replyToId == null) return null;
    final reply = await supabase
        .from('messages')
        .select('text, imageUrl')
        .eq('id', replyToId)
        .maybeSingle();

    return reply?['text'] ?? (reply?['imageUrl'] != null ? '📷 Image' : null);
  }

  // Add the missing _pickSticker method with enhanced functionality
  Future<void> _pickSticker() async {
    setState(() {
      showStickerPicker = !showStickerPicker;
    });
  }

  // Enhanced message options
  void _showMessageOptions(BuildContext context, Map<String, dynamic> msg, String displayName) {
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
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.reply, color: Colors.blue),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _replyToMessageId = msg['id'];
                  _replyToText = msg['text'] ?? '📷 Image';
                  _replyToSenderName = displayName;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.green),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: msg['text'] ?? ''));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message copied to clipboard')),
                );
              },
            ),
            if (msg['sender_id'] == widget.currentUserId) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.orange),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(msg);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(msg['id']);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.add_reaction_outlined, color: Colors.purple),
              title: const Text('Add Reaction'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _reactingToMessageId = msg['id'];
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // Edit message functionality
  void _editMessage(Map<String, dynamic> msg) {
    _controller.text = msg['text'] ?? '';
    setState(() {
      _editingMessageId = msg['id'];
    });
  }

  // Delete message functionality
  Future<void> _deleteMessage(String messageId) async {
    await supabase.from('messages').delete().eq('id', messageId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message deleted')),
    );
  }

  // Add typing indicator functionality
  void _onTextChanged(String text) {
    if (text.isNotEmpty && typingUsers[widget.currentUserId] != true) {
      // Send typing indicator
      supabase.from('typing_indicators').upsert({
        'chat_id': widget.chatId,
        'user_id': widget.currentUserId,
        'is_typing': true,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      setState(() {
        typingUsers[widget.currentUserId] = true;
      });
    }

    // Cancel previous timer
    _typingTimer?.cancel();
    
    // Set new timer to stop typing indicator
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        supabase.from('typing_indicators').upsert({
          'chat_id': widget.chatId,
          'user_id': widget.currentUserId,
          'is_typing': false,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        setState(() {
          typingUsers[widget.currentUserId] = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: showSearch 
          ? TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search messages...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
              autofocus: true,
            )
          : Text(groupName),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                showSearch = !showSearch;
                if (!showSearch) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'media':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EnhancedSharedMediaViewer(
                        chatId: widget.chatId,
                        currentUserId: widget.currentUserId,
                      ),
                    ),
                  );
                  break;
                case 'video_call':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Video call feature coming soon!')),
                  );
                  break;
                case 'voice_call':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Voice call feature coming soon!')),
                  );
                  break;
                case 'settings':
                  // Use integrated navigation
                  GroupsIntegration.navigateToGroupSettings(
                    context,
                    currentUserId: widget.currentUserId,
                    chatId: widget.chatId,
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'media',
                child: ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('View Media'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'video_call',
                child: ListTile(
                  leading: Icon(Icons.videocam),
                  title: Text('Video Call'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'voice_call',
                child: ListTile(
                  leading: Icon(Icons.call),
                  title: Text('Voice Call'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Group Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: loadingGroupInfo
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        reverse: true,
                        controller: _scroll,
                        itemCount: filteredMessages.length,
                        itemBuilder: (context, index) {
                          final msg = filteredMessages[index];
                          final isMe = msg['sender_id'] == widget.currentUserId;
                          final text = msg['text'];
                          final imageUrl = msg['imageUrl'];
                          final senderId = msg['sender_id'];
                          final displayName = personalNicknames[senderId] ??
                              memberNames[senderId] ??
                              'Unknown';
                          final timestamp =
                              DateTime.tryParse(msg['timestamp'] ?? '');
                          final effect = msg['effect'];
                          final isSecret = msg['isSecret'] ?? false;
                          final replyTo = msg['replyTo'];
                          final reactions = Map<String, List<String>>.from(
                              msg['reactions'] ?? {});
                          final hasMention = text?.contains(
                                  '@${memberNames[widget.currentUserId]}') ??
                              false;

                          return FutureBuilder<String?>(
                            // Load reply preview
                            future: _getReplyPreview(replyTo),
                            builder: (context, snap) {
                              // Use enhanced message service if available
                              if (_messageService != null) {
                                final enhancedMessage = {
                                  'id': msg['id'],
                                  'text': text,
                                  'sender_id': senderId,
                                  'timestamp': timestamp,
                                  'reactions': reactions,
                                  'reply_to_id': replyTo,
                                  'media_url': imageUrl,
                                  'media_type': imageUrl != null ? 'image' : null,
                                  'mentions': msg['mentions'] ?? [],
                                  'edited_at': null,
                                  'deleted_at': null,
                                  'enhanced_features': {
                                    'enhanced_display': true,
                                    'gem_triggers': [],
                                    'sentiment_score': 0.0,
                                    'creativity_score': 0.0,
                                    'group_context': {},
                                    'smart_reactions': [],
                                  },
                                };
                                
                                return _messageService!.buildEnhancedMessageBubble(enhancedMessage);
                              } else {
                                // Fallback to original implementation
                                return MessageBubbleEnhanced(
                                  text: text,
                                  imageUrl: imageUrl,
                                  isMe: isMe,
                                  timestamp: timestamp,
                                  avatarUrl:
                                      isMe ? null : memberAvatars[senderId],
                                  decorationPath: isMe
                                      ? myDecorationPath ?? ''
                                      : otherDecorationPath ?? '',
                                  effect: hasMention ? 'pulse' : effect,
                                  isSecret: isSecret,
                                  reactions: reactions,
                                  username: !isMe ? displayName : null,
                                  replyToText: snap.data,
                                  auraColor: 'default',
                                  messageId: msg['id'],
                                  onReactTap: (emoji) async {
                                    final newReactions =
                                        Map<String, List<String>>.from(reactions);
                                    newReactions.update(
                                      emoji,
                                      (list) => list
                                              .contains(widget.currentUserId)
                                          ? (list..remove(widget.currentUserId))
                                          : (list..add(widget.currentUserId)),
                                      ifAbsent: () => [widget.currentUserId],
                                    );

                                    await supabase
                                        .from('messages')
                                        .update({'reactions': newReactions}).eq(
                                            'id', msg['id']);
                                  },
                                  onLongPress: () {
                                    _showMessageOptions(context, msg, displayName);
                                  },
                                  onTap: () {
                                    setState(() {
                                      _replyToMessageId = msg['id'];
                                      _replyToText = msg['text'] ?? '📷 Image';
                                      _replyToSenderName = displayName;
                                    });
                                  },
                                );
                              }
                            },
                          );
                        },
                      ),
              ),
              if (_replyToMessageId != null)
                Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '↪ ${_replyToSenderName ?? 'Someone'}: "${_replyToText ?? ''}"',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _replyToMessageId = null;
                            _replyToText = null;
                            _replyToSenderName = null;
                          });
                        },
                      )
                    ],
                  ),
                ),
              if (_editingMessageId != null)
                Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Editing message...',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.orange),
                        onPressed: () {
                          setState(() {
                            _editingMessageId = null;
                            _controller.clear();
                          });
                        },
                      )
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.photo),
                      onPressed: _pickAndSendImage,
                    ),
                    // Enhanced sticker picker button
                    IconButton(
                      icon: Icon(
                        Icons.sticky_note_2_outlined,
                        color: showStickerPicker ? Colors.pink : Colors.pinkAccent,
                      ),
                      onPressed: _pickSticker,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onChanged: _onTextChanged,
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: _editingMessageId != null 
                            ? 'Editing message...' 
                            : 'Type a message...',
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, 
                            vertical: 12,
                          ),
                          suffixIcon: _editingMessageId != null 
                            ? IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: _saveEditedMessage,
                              )
                            : null,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _editingMessageId != null 
                          ? Icons.check 
                          : Icons.send,
                        color: _editingMessageId != null 
                          ? Colors.green 
                          : Colors.blue,
                      ),
                      onPressed: () => _sendMessage(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_reactingToMessageId != null && _pickerPosition != null)
            Positioned(
              bottom: 60,
              left: 20,
              right: 20,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) async {
                  final currentMsg = messages
                      .firstWhere((m) => m['id'] == _reactingToMessageId);
                  final current = Map<String, List<String>>.from(
                      currentMsg['reactions'] ?? {});
                  current.update(
                    emoji.emoji,
                    (list) => list.contains(widget.currentUserId)
                        ? (list..remove(widget.currentUserId))
                        : (list..add(widget.currentUserId)),
                    ifAbsent: () => [widget.currentUserId],
                  );

                  await supabase.from('messages').update(
                      {'reactions': current}).eq('id', _reactingToMessageId!);

                  setState(() => _reactingToMessageId = null);
                },
              ),
            ),
          if (showStickerPicker)
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Container(
                height: 300,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: StickerPicker(
                  onStickerSelected: (stickerUrl) {
                    _sendMessage(stickerUrl: stickerUrl);
                  },
                ),
              ),
            ),
          
          // Floating pets display
          if (_petsVisible && userPets.isNotEmpty) 
            ..._buildFloatingPets(),
        ],
      ),
    );
  }

  // Build floating pets that appear on screen
  List<Widget> _buildFloatingPets() {
    List<Widget> petWidgets = [];
    
    for (int i = 0; i < userPets.length && i < 5; i++) {
      final pet = userPets[i];
      final key = pet['name'].toString().toLowerCase().replaceAll(" ", "_");
      final imageUrl = pet['image_url'];
      
      // Position pets around the screen
      double? left, right, top, bottom;
      
      switch (i) {
        case 0:
          right = 20;
          top = 100;
          break;
        case 1:
          left = 20;
          top = 200;
          break;
        case 2:
          right = 20;
          bottom = 150;
          break;
        case 3:
          left = 20;
          bottom = 250;
          break;
        case 4:
          right = 80;
          top = 300;
          break;
      }
      
      if (_petAnimations[key] != null) {
        petWidgets.add(
          Positioned(
            left: left,
            right: right,
            top: top,
            bottom: bottom,
            child: GestureDetector(
              onTap: () => _interactWithPet(pet, key),
              child: AnimatedBuilder(
                animation: _petAnimations[key]!,
                builder: (_, child) {
                  final bounce = sin(_petAnimations[key]!.value * 3.14159);
                  return Transform.translate(
                    offset: Offset(0, -10 * bounce),
                    child: child,
                  );
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.pink.shade100,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Icon(
                            Icons.pets,
                            color: Colors.pink,
                            size: 30,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    
    return petWidgets;
  }

  // Interact with a pet
  void _interactWithPet(Map<String, dynamic> pet, String key) {
    // Trigger pet animation
    _petAnimations[key]?.forward(from: 0.0);
    
    // Show interaction feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${pet['name']} is happy to see you! 🐾'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.pink,
      ),
    );
    
    // Send a pet interaction message to the group
    final originalText = _controller.text;
    _controller.text = '🐾 ${pet['name']} says hello to everyone!';
    _sendMessage();
    _controller.text = originalText;
  }
}
