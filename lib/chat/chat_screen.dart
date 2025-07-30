import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:crystal_social/tabs/call_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'chat_production_config.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../widgets/message_bubble.dart';
import '../utils/navigation_helper.dart';
import '../rewards/rewards_manager.dart';

// Enhanced enums for new features
enum ChatTheme { classic, neon, nature, space, ocean, sunset }
enum MessageStatus { sending, sent, delivered, read, failed }
enum TypingStatus { none, typing, recording, thinking } 


class ChatScreen extends StatefulWidget {
  final String currentUser;
  final String otherUser;
  final String chatId;

  const ChatScreen({
    required this.currentUser,
    required this.otherUser,
    required this.chatId,
    super.key,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  String _searchQuery = '';
  List<Map<String, dynamic>> get filteredMessages {
    if (_searchQuery.isEmpty) return messages;
    final query = _searchQuery.toLowerCase();
    return messages.where((msg) {
      final text = (msg['content'] ?? '').toString().toLowerCase();
      return text.contains(query);
    }).toList();
  }
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final supabase = Supabase.instance.client;
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  AudioPlayer? _ringtonePlayer;
  Timer? _typingTimer;
  Timer? _incomingCallTimeout;
  StreamSubscription? _accelerometerSub;
  String? myAvatarUrl;
  String? otherAvatarUrl;
  String? _chatBackgroundUrl;
  String? _globalChatBackgroundUrl;
  String _customSleepyReply = "\u{1F4A4} I’m in Sleepy Mode... I’ll get right back to you!";
  bool _butterflyVisible = false;
  bool _isSecretMode = false;
  String? myDecorationPath; // Track user's decoration path
  String? otherDecorationPath; // Track other user's decoration path
  Map<String, dynamic>? _replyToMessage; // Track message being replied to
  DateTime? _stillSince;
  List<Map<String, dynamic>> messages = [];
  
  // Enhanced features for advanced chat functionality
  bool _isTyping = false;
  bool _showTypingIndicator = false;
  ChatTheme _currentTheme = ChatTheme.classic;
  TypingStatus _otherUserTypingStatus = TypingStatus.none;
  late AnimationController _butterflyController;
  late AnimationController _typingController;
  late AnimationController _themeController;
  Timer? _typingIndicatorTimer;
  Timer? _messageAnimationTimer;
  List<String> _quickReplies = ['👍', '😊', '❤️', 'Thanks!', 'Sure!', 'On my way!'];
  bool _enableMessageEffects = true;
  bool _enableSoundEffects = true;
  double _chatFontSize = 16.0;
  
  // Enhanced rewards system integration
  late RewardsManager _rewardsManager;
  


  @override
  void initState() {
    super.initState();
    _rewardsManager = RewardsManager(supabase);
    _setupAnimationControllers();
    _loadUserAvatars();
    _loadChatBackground();
    _loadGlobalChatBackground();
    _loadOtherUserSleepyReply();
    _loadMessages();
    _listenToButterflyMode();
    _listenForIncomingCalls();
    _loadUserDecoration(); // Load the current user's decoration path
    _loadOtherUserDecoration(); // Load the other user's decoration path
    _setupTypingListener();
    _listenToTypingStatus(); // Listen for other user's typing status
    _setupChatTheme();
    _loadChatSettings();
  }

  void _setupAnimationControllers() {
    _butterflyController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _themeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _butterflyController.repeat(reverse: true);
  }

  void _setupTypingListener() {
    _controller.addListener(() {
      if (_controller.text.isNotEmpty && !_isTyping) {
        _isTyping = true;
        _broadcastTypingStatus(TypingStatus.typing);
        
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 2), () {
          _isTyping = false;
          _broadcastTypingStatus(TypingStatus.none);
        });
      }
    });
  }

  void _setupChatTheme() async {
    final themeData = await supabase
        .from('chat_settings')
        .select('theme')
        .eq('user_id', widget.currentUser)
        .eq('chat_id', widget.chatId)
        .maybeSingle();
    
    if (themeData != null && themeData['theme'] != null) {
      final themeIndex = int.tryParse(themeData['theme']) ?? 0;
      setState(() {
        _currentTheme = ChatTheme.values[themeIndex.clamp(0, ChatTheme.values.length - 1)];
      });
    }
  }

  void _loadChatSettings() async {
    final settings = await supabase
        .from('chat_settings')
        .select('font_size, enable_effects, enable_sounds')
        .eq('user_id', widget.currentUser)
        .maybeSingle();
    
    if (settings != null) {
      setState(() {
        _chatFontSize = (settings['font_size'] ?? 16.0).toDouble();
        _enableMessageEffects = settings['enable_effects'] ?? true;
        _enableSoundEffects = settings['enable_sounds'] ?? true;
      });
    }
  }

  // Enhanced typing status broadcasting
  void _broadcastTypingStatus(TypingStatus status) async {
    await supabase.from('typing_status').upsert({
      'chat_id': widget.chatId,
      'user_id': widget.currentUser,
      'status': status.index,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Listen for other user's typing status
  void _listenToTypingStatus() {
    supabase
        .from('typing_status')
        .stream(primaryKey: ['chat_id', 'user_id'])
        .listen((data) {
          final relevantData = data.where((row) => 
            row['chat_id'] == widget.chatId && 
            row['user_id'] == widget.otherUser
          ).toList();
          
          if (relevantData.isNotEmpty) {
            final statusIndex = relevantData.first['status'] ?? 0;
            setState(() {
              _otherUserTypingStatus = TypingStatus.values[statusIndex.clamp(0, TypingStatus.values.length - 1)];
              _showTypingIndicator = _otherUserTypingStatus != TypingStatus.none;
            });

            if (_showTypingIndicator) {
              _typingController.repeat();
              _typingIndicatorTimer?.cancel();
              _typingIndicatorTimer = Timer(const Duration(seconds: 3), () {
                setState(() {
                  _showTypingIndicator = false;
                  _otherUserTypingStatus = TypingStatus.none;
                });
                _typingController.stop();
              });
            }
          }
        });
  }

  // Enhanced theme management
  void _changeTheme(ChatTheme newTheme) async {
    setState(() => _currentTheme = newTheme);
    
    // Save theme preference
    await supabase.from('chat_settings').upsert({
      'user_id': widget.currentUser,
      'chat_id': widget.chatId,
      'theme': newTheme.index.toString(),
    });
    
    // Animate theme transition
    _themeController.forward().then((_) {
      _themeController.reverse();
    });
    
    if (_enableSoundEffects) {
      _playNotificationSound('theme_change');
    }
  }

  // Sound effects system
  void _playNotificationSound(String soundType) async {
    if (!_enableSoundEffects) return;
    
    final soundMap = {
      'message_send': 'sounds/send.mp3',
      'message_receive': 'sounds/receive.mp3',
      'theme_change': 'sounds/theme.mp3',
      'reaction': 'sounds/reaction.mp3',
    };
    
    final soundPath = soundMap[soundType];
    if (soundPath != null) {
      final player = AudioPlayer();
      await player.play(AssetSource(soundPath));
    }
  }

  // Quick reply system
  Widget _buildQuickReplies() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _quickReplies.length,
        itemBuilder: (context, index) {
          final reply = _quickReplies[index];
          return GestureDetector(
            onTap: () => _sendMessage(reply),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getThemeColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getThemeColor()),
              ),
              child: Center(
                child: Text(
                  reply,
                  style: TextStyle(
                    color: _getThemeColor(),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Theme color system
  Color _getThemeColor() {
    switch (_currentTheme) {
      case ChatTheme.classic:
        return Colors.pinkAccent;
      case ChatTheme.neon:
        return Colors.cyan;
      case ChatTheme.nature:
        return Colors.green;
      case ChatTheme.space:
        return Colors.indigo;
      case ChatTheme.ocean:
        return Colors.blue;
      case ChatTheme.sunset:
        return Colors.orange;
    }
  }

  // Open media viewer for this chat
  void _openMediaViewer() {
    NavigationHelper.navigateToSharedMedia(
      context,
      chatId: widget.chatId,
      currentUserId: widget.currentUser,
    );
  }

  // Toggle search functionality
  void _toggleSearch() {
    setState(() {
      if (_searchQuery.isEmpty) {
        // Start searching - could show search overlay
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Search functionality - swipe down to access search bar'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        _searchQuery = '';
      }
    });
  }

  // Enhanced settings panel
  void _showChatSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Settings content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chat Settings',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    
                    // Theme selector
                    const Text('Theme', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Container(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: ChatTheme.values.length,
                        itemBuilder: (context, index) {
                          final theme = ChatTheme.values[index];
                          final isSelected = _currentTheme == theme;
                          
                          return GestureDetector(
                            onTap: () => _changeTheme(theme),
                            child: Container(
                              width: 60,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: _getThemeColorForIndex(index),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? Colors.black : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  theme.name.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Font size slider
                    Text('Font Size: ${_chatFontSize.toInt()}', 
                         style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    Slider(
                      value: _chatFontSize,
                      min: 12.0,
                      max: 24.0,
                      divisions: 6,
                      activeColor: _getThemeColor(),
                      onChanged: (value) {
                        setState(() => _chatFontSize = value);
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Settings toggles
                    SwitchListTile(
                      title: const Text('Message Effects'),
                      subtitle: const Text('Animations and visual effects'),
                      value: _enableMessageEffects,
                      activeColor: _getThemeColor(),
                      onChanged: (value) {
                        setState(() => _enableMessageEffects = value);
                      },
                    ),
                    
                    SwitchListTile(
                      title: const Text('Sound Effects'),
                      subtitle: const Text('Notification sounds'),
                      value: _enableSoundEffects,
                      activeColor: _getThemeColor(),
                      onChanged: (value) {
                        setState(() => _enableSoundEffects = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getThemeColorForIndex(int index) {
    final themes = [
      Colors.pinkAccent,
      Colors.cyan,
      Colors.green,
      Colors.indigo,
      Colors.blue,
      Colors.orange,
    ];
    return themes[index.clamp(0, themes.length - 1)];
  }


  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _typingTimer?.cancel();
    _typingIndicatorTimer?.cancel();
    _messageAnimationTimer?.cancel();
    _accelerometerSub?.cancel();
    _butterflyController.dispose();
    _typingController.dispose();
    _themeController.dispose();
    super.dispose();
  }

  // Method to send a sticker message
  Future<void> _sendSticker(String stickerUrl) async {
    try {
      await supabase.from('messages').insert({
        'chat_id': widget.chatId,
        'sender_id': widget.currentUser,
        'content': stickerUrl,
        'message_type': 'sticker', // Mark this as a sticker message
        'created_at': DateTime.now().toIso8601String(),
        'status': 'sent',
      });

      ChatDebugUtils.log('ChatScreen', 'Sticker sent successfully');
    } catch (e) {
      ChatDebugUtils.logError('ChatScreen', 'Error sending sticker: $e');
    }
  }



  // Method to pick a sticker from gallery
  Future<void> _pickSticker() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      await supabase.storage.from('stickers').uploadBinary(
            'user_stickers/${pickedFile.name}',
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      final publicUrl = supabase.storage.from('stickers').getPublicUrl('user_stickers/${pickedFile.name}');
      _sendSticker(publicUrl);
    }
  }

    // Method to load messages from Supabase
  Future<void> _loadMessages() async {
    final response = await supabase
        .from('messages')
        .select()
        .eq('chat_id', widget.chatId)
        .order('created_at', ascending: true);
    
    setState(() {
      messages = List<Map<String, dynamic>>.from(response);
    });
  }

  void _showEmoticonPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          decoration: const BoxDecoration(
            color: Color(0xFFFED8E6),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select Emoticon',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 6,
                  padding: const EdgeInsets.all(16),
                  children: [
                    '😀', '😃', '🥰', '😍', '😘', '😊',
                    '😢', '😡', '🤔', '😴', '🤤', '😵',
                    '🥺', '🤯', '🤡', '🥳', '😎', '🤩',
                    '🙄', '😬', '🤫', '🤭', '😇', '😷',
                  ].map((emoji) => GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _controller.text += emoji;
                    },
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleMicTap() async {
    if (!_isRecording) {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) return;
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/${const Uuid().v4()}.m4a';
      await _recorder.start(RecordConfig(), path: filePath);
      setState(() => _isRecording = true);
    } else {
      final path = await _recorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        final audioFile = File(path);
        final fileName = path.split('/').last;
        final storageRef = 'chats/${widget.chatId}/$fileName';
        await supabase.storage.from('chat_audio').uploadBinary(storageRef, await audioFile.readAsBytes());
        final audioUrl = supabase.storage.from('chat_audio').getPublicUrl(storageRef);
        await supabase.from('messages').insert({
          'chat_id': widget.chatId,
          'sender_id': widget.currentUser,
          'audio_url': audioUrl,
          'created_at': DateTime.now().toIso8601String(),
          'status': 'sent',
          'message_type': 'audio',
        });
        _loadMessages();
      }
    }
  }

    // Method to load the user's decoration path from Supabase
  Future<void> _loadUserDecoration() async {
    final user = await supabase
        .from('profiles')
        .select('avatar_decoration')
        .eq('id', widget.currentUser)
        .maybeSingle();

    if (user != null && user['avatar_decoration'] != null) {
      setState(() {
        myDecorationPath =
            user['avatar_decoration']; // Save the decoration path
      });
    }
  }

    // Method to load the other user's decoration path
  Future<void> _loadOtherUserDecoration() async {
    final user = await supabase
        .from('profiles')
        .select('avatar_decoration')
        .eq('id', widget.otherUser)
        .maybeSingle();

    if (user != null && user['avatar_decoration'] != null) {
      setState(() {
        otherDecorationPath =
            user['avatar_decoration']; // Save the decoration path
      });
    }
  }

  void _listenToButterflyMode() {
    _accelerometerSub = accelerometerEvents.listen((event) {
      final double magnitude =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      final bool isStill = (magnitude - 9.8).abs() < 0.05;

      if (isStill) {
        _stillSince ??= DateTime.now();
        if (!_butterflyVisible &&
            DateTime.now().difference(_stillSince!) >
                const Duration(seconds: 5)) {
          setState(() => _butterflyVisible = true);
        }
      } else {
        _stillSince = null;
        if (_butterflyVisible) setState(() => _butterflyVisible = false);
      }
    });
  }

  Future<void> _loadUserAvatars() async {
    final current = await supabase
        .from('profiles')
        .select('avatar_url')
        .eq('id', widget.currentUser)
        .maybeSingle();
    final other = await supabase
        .from('profiles')
        .select('avatar_url')
        .eq('id', widget.otherUser)
        .maybeSingle();

    setState(() {
      myAvatarUrl = current?['avatar_url'];
      otherAvatarUrl = other?['avatar_url'];
    });
  }

  Future<void> _loadChatBackground() async {
    final doc = await supabase
        .from('chats')
        .select('backgroundUrl')
        .eq('id', widget.chatId)
        .maybeSingle();
    setState(() => _chatBackgroundUrl = doc?['backgroundUrl']);
  }

  Future<void> _loadGlobalChatBackground() async {
    final doc = await supabase
        .from('profiles')
        .select('global_chat_background_url')
        .eq('id', widget.currentUser)
        .maybeSingle();
    setState(() => _globalChatBackgroundUrl = doc?['global_chat_background_url']);
  }

  Future<void> _loadOtherUserSleepyReply() async {
    final doc = await supabase
        .from('profiles')
        .select('sleepy_auto_reply_text')
        .eq('id', widget.otherUser)
        .maybeSingle();
    if (doc?['sleepy_auto_reply_text'] != null) {
      setState(() => _customSleepyReply = doc!['sleepy_auto_reply_text']);
    }
  }

  // Load custom ringtone for a specific caller
  Future<String?> _loadCustomRingtone(String callerId) async {
    try {
      final result = await supabase
          .from('user_ringtones')
          .select('sound')
          .eq('owner_id', widget.currentUser)
          .eq('sender_id', callerId)
          .maybeSingle();

      if (result != null && result['sound'] != null) {
        // Return the full asset path for notification sounds
        return 'notification_sounds/${result['sound']}';
      }
      return null; // Use default ringtone
    } catch (e) {
      ChatDebugUtils.logError('ChatScreen', 'Error loading custom ringtone: $e');
      return null;
    }
  }

  Future<void> _maybeSendSleepyAutoReply() async {
    final doc = await supabase
        .from('profiles')
        .select('is_sleepy_mode_on, sleepy_auto_reply, sleepy_auto_reply_text')
        .eq('id', widget.otherUser)
        .maybeSingle();

    if (doc != null &&
        doc['is_sleepy_mode_on'] == true &&
        doc['sleepy_auto_reply'] == true) {
      final reply = doc['sleepy_auto_reply_text'] ?? _customSleepyReply;
      await supabase.from('messages').insert({
        'chat_id': widget.chatId,
        'sender_id': widget.otherUser,
        'content': reply,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'sent',
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final messageData = <String, dynamic>{
      'chat_id': widget.chatId,
      'sender_id': widget.currentUser,
      'content': text.trim(),
      'created_at': DateTime.now().toIso8601String(),
      'status': 'sent',
      'is_secret': _isSecretMode,
    };

    // Add reply information if replying to a message
    if (_replyToMessage != null) {
      messageData['reply_to_message_id'] = _replyToMessage!['id'];
      messageData['reply_to_content'] = _replyToMessage!['content'];
      messageData['reply_to_username'] = _replyToMessage!['sender_id'] == widget.currentUser 
          ? widget.currentUser 
          : widget.otherUser;
    }

    await supabase.from('messages').insert(messageData);

    // Track message sending for enhanced leveling system (2 points per message)
    await _rewardsManager.trackMessageSent(widget.currentUser, context);

    await _maybeSendSleepyAutoReply();
    
    // Track message activity for gem unlocking
    trackMessageActivity(text.trim(), DateTime.now());

    _controller.clear();
    setState(() {
      _isSecretMode = false;
      _replyToMessage = null; // Clear reply state
    });

    _scroll.animateTo(
      _scroll.position.maxScrollExtent + 80,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    _loadMessages();
  }
void trackMessageActivity(String message, DateTime timestamp) {
  if (_containsSupportiveWords(message)) {
    _unlockGem('Amethyst');
  } else if (_containsDrama(message)) {
    _unlockGem('Ruby');
  } else if (_containsCreativeWords(message)) {
    _unlockGem('Emerald');
  }

  if (timestamp.hour >= 0 && timestamp.hour <= 4) {
    _unlockGem('Sapphire');
  }
}

  Map<String, dynamic>? replyToMessage;

void onReply(Map<String, dynamic> message) {
  setState(() {
    replyToMessage = message;
  });
}

void cancelReply() {
  setState(() {
    replyToMessage = null;
  });
}

// Helper methods for gem tracking
bool _containsSupportiveWords(String message) {
  final supportiveWords = ['support', 'help', 'love', 'care', 'comfort', 'encouragement'];
  return supportiveWords.any((word) => message.toLowerCase().contains(word));
}

bool _containsDrama(String message) {
  final dramaWords = ['drama', 'fight', 'argue', 'conflict', 'angry', 'upset'];
  return dramaWords.any((word) => message.toLowerCase().contains(word));
}

bool _containsCreativeWords(String message) {
  final creativeWords = ['art', 'create', 'design', 'imagine', 'inspiration', 'creative'];
  return creativeWords.any((word) => message.toLowerCase().contains(word));
}

Future<void> _unlockGem(String gemType) async {
  try {
    await supabase.from('user_gems').insert({
      'user_id': widget.currentUser,
      'gem_type': gemType,
      'unlocked_at': DateTime.now().toIso8601String(),
    });
  } catch (e) {
    ChatDebugUtils.logError('ChatScreen', 'Error unlocking gem: $e');
  }
}


Future<void> _tryUnlockButterfly(String userId) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('butterfly_album')
      .select('butterfly_id')
      .eq('user_id', userId);

  final unlockedIds = (response as List).map((e) => e['butterfly_id'] as String).toList();
  
  // Simple butterfly types for demo
  final allButterflyTypes = ['monarch', 'blue_morpho', 'swallowtail', 'admiral', 'painted_lady'];
  final locked = allButterflyTypes.where((b) => !unlockedIds.contains(b)).toList();

  if (locked.isEmpty) return;

  final newButterfly = locked[Random().nextInt(locked.length)];

  await supabase.from('butterfly_album').insert({
    'user_id': userId,
    'butterfly_id': newButterfly,
  });

  // Optional: Show toast or animation
  Fluttertoast.showToast(
    msg: "✨ You discovered a '$newButterfly' butterfly!",
    toastLength: Toast.LENGTH_SHORT,
  );
}



  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final file = File(image.path);
    final fileName = path.basename(image.path);
    final storageRef = 'chats/${widget.chatId}/$fileName';

    await supabase.storage
        .from('chat_images')
        .uploadBinary(storageRef, await file.readAsBytes());

    final imageUrl =
        supabase.storage.from('chat_images').getPublicUrl(storageRef);

    await supabase.from('messages').insert({
      'chat_id': widget.chatId,
      'sender_id': widget.currentUser,
      'image_url': imageUrl,
      'created_at': DateTime.now().toIso8601String(),
      'status': 'sent',
      'message_type': 'image',
    });

    _scroll.jumpTo(_scroll.position.maxScrollExtent + 200);

    _loadMessages();
  }

  Future<void> _sendButterflyMessage() async {
  setState(() => _butterflyVisible = false);

  await supabase.from('messages').insert({
    'chat_id': widget.chatId,
    'sender_id': widget.currentUser,
    'content': '� Peaceful Vibe',
    'created_at': DateTime.now().toIso8601String(),
    'status': 'sent',
    'message_type': 'butterfly',
  });

  // Try unlocking a butterfly
  await _tryUnlockButterfly(widget.currentUser);
  
  // Scroll to bottom and reload messages
  _scroll.animateTo(
    _scroll.position.maxScrollExtent + 80,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOut,
  );

  _loadMessages();
}

  

  Future<void> _toggleReaction(String messageId, String emoji) async {
    final msg = await supabase
        .from('messages')
        .select('reactions')
        .eq('id', messageId)
        .single();

    final current = Map<String, List<String>>.from(msg['reactions'] ?? {});
    final users = current[emoji] ?? [];

    if (users.contains(widget.currentUser)) {
      users.remove(widget.currentUser);
      if (users.isEmpty) {
        current.remove(emoji);
      } else {
        current[emoji] = users;
      }
    } else {
      users.add(widget.currentUser);
      current[emoji] = users;
    }

    await supabase
        .from('messages')
        .update({'reactions': current}).eq('id', messageId);

    _loadMessages();
  }

  void _listenForIncomingCalls() {
    final userId = widget.currentUser;

    supabase
        .from('calls')
        .stream(primaryKey: ['id'])
        .listen((calls) {
          final incomingCalls = calls.where((call) =>
              call['receiver_id'] == userId &&
              call['accepted'] == false &&
              call['ended'] == false).toList();
          
          if (incomingCalls.isEmpty) return;
          final call = incomingCalls.last;
          _showIncomingCallDialog(call);
        });
  }

  Future<void> _showIncomingCallDialog(Map call) async {
    _ringtonePlayer = AudioPlayer();
    await _ringtonePlayer!.setReleaseMode(ReleaseMode.loop);
    
    // Load custom ringtone for this caller
    final customRingtone = await _loadCustomRingtone(call['caller_id']);
    final ringtoneAsset = customRingtone ?? 'sounds/ringtone.mp3';
    
    await _ringtonePlayer!.play(AssetSource(ringtoneAsset));

    _incomingCallTimeout?.cancel();
    _incomingCallTimeout = Timer(const Duration(seconds: 30), () async {
      await _ringtonePlayer?.stop();
      await supabase.from('calls').update({'ended': true}).eq('id', call['id']);
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text("Incoming ${call['is_video'] ? 'Video' : 'Audio'} Call"),
        content: FutureBuilder(
          future: supabase
              .from('users')
              .select('avatarUrl')
              .eq('id', call['caller_id'])
              .maybeSingle(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            final avatarUrl = snapshot.data?['avatarUrl'] ?? '';

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(avatarUrl),
                  radius: 32,
                ),
                const SizedBox(height: 8),
                Text("From: ${call['caller_id']}"),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () async {
              _incomingCallTimeout?.cancel();
              await _ringtonePlayer?.stop();
              await supabase
                  .from('calls')
                  .update({'ended': true}).eq('id', call['id']);
              Navigator.pop(context);
            },
            child: const Text("Decline"),
          ),
          ElevatedButton(
            onPressed: () async {
              _incomingCallTimeout?.cancel();
              await _ringtonePlayer?.stop();

              final response = await http.post(
                Uri.parse(
                    'https://ttvgpvtgtymgzzqtkrmn.supabase.co/functions/v1/generate-agora-token'),
                headers: {
                  'Authorization':
                      'Bearer ${supabase.auth.currentSession?.accessToken}',
                  'Content-Type': 'application/json',
                },
                body: json.encode({
                  'channelName': call['channel_id'],
                  'uid': '1',
                }),
              );

              final token = json.decode(response.body)['token'];

              await supabase
                  .from('calls')
                  .update({'accepted': true}).eq('id', call['id']);

              Navigator.pop(context); // close dialog
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CallScreen(
                    channelId: call['channel_id'],
                    token: token,
                    isVideo: call['is_video'],
                    callerId: call['caller_id'],
                    receiverId: call['receiver_id'],
                  ),
                ),
              );
            },
            child: const Text("Accept"),
          ),
        ],
      ),
    );
  }




  void _showEmojiPicker(String messageId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => EmojiPicker(
        onEmojiSelected: (category, emoji) {
          Navigator.pop(context);
          _toggleReaction(messageId, emoji.emoji);
        },
        config: Config(
          emojiViewConfig: EmojiViewConfig(
            columns: 7,
            emojiSizeMax: 32.0,
            backgroundColor: const Color(0xFFFED8E6),
          ),
          categoryViewConfig: const CategoryViewConfig(
            indicatorColor: Colors.pinkAccent,
          ),
        ),
      ),
    );
  }

  void _showEffectPicker(String messageId) async {
    final effect = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("Pick a message effect"),
        children: [
          SimpleDialogOption(
              child: const Text("🎉 Bounce"),
              onPressed: () => Navigator.pop(context, "bounce")),
          SimpleDialogOption(
              child: const Text("💓 Pulse"),
              onPressed: () => Navigator.pop(context, "pulse")),
          SimpleDialogOption(
              child: const Text("🕊 Float"),
              onPressed: () => Navigator.pop(context, "float")),
          SimpleDialogOption(
              child: const Text("❁ERemove effect"),
              onPressed: () => Navigator.pop(context, null)),
        ],
      ),
    );

    await supabase
        .from('messages')
        .update({'effect': effect}).eq('id', messageId);

    _loadMessages();
  }

  // Enhanced message handling methods
  void _handleReply(Map<String, dynamic> messageData) {
    setState(() {
      _replyToMessage = messageData;
    });
    // Focus on text input
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _handleEdit(Map<String, dynamic> messageData) {
    if (messageData['sender_id'] != widget.currentUser) return;
    
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: messageData['content'] ?? '');
        return AlertDialog(
          title: const Text('Edit Message'),
          content: TextField(
            controller: controller,
            maxLines: null,
            decoration: const InputDecoration(
              hintText: 'Enter new message...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await supabase
                    .from('messages')
                    .update({
                      'content': controller.text,
                      'is_edited': true,
                    })
                    .eq('id', messageData['id']);
                
                Navigator.pop(context);
                _loadMessages();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _handleDelete(Map<String, dynamic> messageData) {
    if (messageData['sender_id'] != widget.currentUser) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await supabase
                  .from('messages')
                  .delete()
                  .eq('id', messageData['id']);
              
              Navigator.pop(context);
              _loadMessages();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _handleForward(Map<String, dynamic> messageData) {
    // TODO: Implement forward functionality
    // This would show a user/chat selection dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Forward feature coming soon!')),
    );
  }

  void _handleCopy(Map<String, dynamic> messageData) {
    final text = messageData['content'] ?? '';
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Message copied to clipboard'),
          backgroundColor: _getThemeColor(),
        ),
      );
    }
  }

  void _showUserProfile(String userId) {
    // TODO: Navigate to user profile screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Show profile for $userId')),
    );
  }

  void _handleMentionTap(String mention) {
    // TODO: Handle mention tap (e.g., show user profile or start chat)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tapped mention: $mention')),
    );
  }

  void _handleHashtagTap(String hashtag) {
    // TODO: Handle hashtag tap (e.g., show related messages or trending)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tapped hashtag: $hashtag')),
    );
  }

  // TODO: Moved CrystalGarden class to separate file to fix structure issues
  // The CrystalGarden functionality needs to be refactored

  // Build message UI based on type
  Widget _buildMessage(Map<String, dynamic> data) {
    final isMe = data['sender_id'] == widget.currentUser;

    // Check for sticker message
    if (data['message_type'] == 'sticker') {
      return GestureDetector(
        onTap: () {
          _sendSticker(data['content']);
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.network(data['content']), // Display sticker image
        ),
      );
    } else {
      // Use the enhanced MessageBubble widget
      return MessageBubbleEnhanced(
        text: data['content'],
        imageUrl: data['image_url'],
        audioUrl: data['audio_url'],
        videoUrl: data['video_url'],
        gifUrl: data['gif_url'],
        stickerUrl: data['sticker_url'],
        isMe: isMe,
        timestamp: DateTime.tryParse(data['created_at'] ?? ''),
        status: data['status'] ?? 'sent',
        avatarUrl: isMe ? myAvatarUrl : otherAvatarUrl,
        reactions: Map<String, List<String>>.from(data['reactions'] ?? {}),
        effect: data['effect'],
        isSecret: data['is_secret'] == true,
        username: isMe ? widget.currentUser : widget.otherUser,
        messageId: data['id']?.toString() ?? '',
        replyToMessageId: data['reply_to_message_id']?.toString(),
        replyToText: data['reply_to_content'],
        replyToUsername: data['reply_to_username'],
        isEdited: data['is_edited'] == true,
        isForwarded: data['is_forwarded'] == true,
        forwardCount: data['forward_count'],
        isImportant: data['is_important'] == true,
        mood: data['mood'],
        mentions: data['mentions'] != null ? List<String>.from(data['mentions']) : null,
        hashtags: data['hashtags'] != null ? List<String>.from(data['hashtags']) : null,
        metadata: data['metadata'],
        decorationPath: isMe ? myDecorationPath ?? '' : otherDecorationPath ?? '',
        auraColor: data['aura_color'] ?? '',
        onReactTap: (emoji) => _toggleReaction(data['id']?.toString() ?? '', emoji),
        onReply: (msg) => _handleReply(data),
        onReact: (msg) => _showEmojiPicker(data['id']?.toString() ?? ''),
        onEffect: (msg) => _showEffectPicker(data['id']?.toString() ?? ''),
        onEdit: (msg) => _handleEdit(data),
        onDelete: (msg) => _handleDelete(data),
        onForward: (msg) => _handleForward(data),
        onCopy: (msg) => _handleCopy(data),
        onAvatarTap: () => _showUserProfile(isMe ? widget.currentUser : widget.otherUser),
        onMentionTap: (mention) => _handleMentionTap(mention),
        onHashtagTap: (hashtag) => _handleHashtagTap(hashtag),
      );
    }
  }

  Future<void> startCall({required bool isVideo}) async {
    final user = supabase.auth.currentUser;
    final String callerId = user!.id;
    final String receiverId = widget.otherUser;
    final String channelId =
        '${callerId}_${receiverId}_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Create a call entry in Supabase
    await supabase.from('calls').insert({
      'caller_id': callerId,
      'receiver_id': receiverId,
      'channel_id': channelId,
      'is_video': isVideo,
      'accepted': false,
      'ended': false,
    });

    // 2. Request token from the Edge Function
    final response = await http.post(
      Uri.parse('https://ttvgpvtgtymgzzqtkrmn.supabase.co/functions/v1/generate-agora-token'),
      headers: {
        'Authorization': 'Bearer ${supabase.auth.currentSession?.accessToken}',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'channelName': channelId,
        'uid': '0',
      }),
    );

    final token = json.decode(response.body)['token'];

    // 3. Navigate to call screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          channelId: channelId,
          token: token,
          isVideo: isVideo,
          callerId: callerId,
          receiverId: receiverId,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: otherAvatarUrl != null ? NetworkImage(otherAvatarUrl!) : null,
              child: otherAvatarUrl == null ? Text(widget.otherUser[0].toUpperCase()) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (_showTypingIndicator)
                    AnimatedBuilder(
                      animation: _typingController,
                      builder: (context, child) {
                        return Text(
                          _getTypingText(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: _getThemeColor(),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: () => _openMediaViewer(),
            tooltip: 'Shared Media',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'media':
                  _openMediaViewer();
                  break;
                case 'settings':
                  _showChatSettings();
                  break;
                case 'search':
                  _toggleSearch();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'media',
                child: Row(
                  children: [
                    Icon(Icons.photo_library),
                    SizedBox(width: 8),
                    Text('Shared Media'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'search',
                child: Row(
                  children: [
                    Icon(Icons.search),
                    SizedBox(width: 8),
                    Text('Search Messages'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Chat Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          image: _chatBackgroundUrl != null
              ? DecorationImage(image: NetworkImage(_chatBackgroundUrl!), fit: BoxFit.cover)
              : _globalChatBackgroundUrl != null
                  ? DecorationImage(image: NetworkImage(_globalChatBackgroundUrl!), fit: BoxFit.cover)
                  : null,
          gradient: _chatBackgroundUrl == null && _globalChatBackgroundUrl == null
              ? _getThemeGradient()
              : null,
        ),
        child: Column(
          children: [
            // Enhanced search bar
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search messages...",
                  prefixIcon: Icon(Icons.search, color: _getThemeColor()),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
            
            // Quick replies (show when not searching)
            if (_searchQuery.isEmpty) _buildQuickReplies(),
            
            // Messages list
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                itemCount: filteredMessages.length,
                itemBuilder: (context, i) => _buildMessage(filteredMessages[i]),
              ),
            ),
            
            // Enhanced input area
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Reply preview section
                  if (_replyToMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border(
                          left: BorderSide(color: _getThemeColor(), width: 4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Replying to ${_replyToMessage!['sender_id'] == widget.currentUser ? 'yourself' : widget.otherUser}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getThemeColor(),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  (_replyToMessage!['text'] ?? '').length > 50
                                      ? '${(_replyToMessage!['text'] ?? '').substring(0, 50)}...'
                                      : (_replyToMessage!['text'] ?? ''),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() => _replyToMessage = null),
                          ),
                        ],
                      ),
                    ),
                  
                  // Input row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        // Media buttons
                        IconButton(
                          icon: Icon(Icons.image, color: _getThemeColor()),
                          onPressed: _sendImage,
                        ),
                        IconButton(
                          icon: Icon(Icons.emoji_emotions_outlined, color: _getThemeColor()),
                          onPressed: _showEmoticonPicker,
                        ),
                        IconButton(
                          icon: Icon(Icons.sticky_note_2_outlined, color: _getThemeColor()),
                          onPressed: _pickSticker,
                        ),
                        
                        // Text input
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextField(
                              controller: _controller,
                              style: TextStyle(fontSize: _chatFontSize),
                              decoration: InputDecoration(
                                hintText: _isRecording 
                                    ? "Recording..." 
                                    : _isSecretMode 
                                        ? "Type secret message... \u{1F512}" 
                                        : _replyToMessage != null
                                            ? "Reply to message..."
                                            : "Type your message...",
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              maxLines: null,
                            ),
                          ),
                        ),
                        
                        // Action buttons
                        IconButton(
                          icon: Icon(
                            _isSecretMode ? Icons.lock : Icons.lock_open,
                            color: _isSecretMode ? _getThemeColor() : Colors.grey,
                          ),
                          onPressed: () => setState(() => _isSecretMode = !_isSecretMode),
                        ),
                        IconButton(
                          icon: Icon(Icons.send, color: _getThemeColor()),
                          onPressed: () => _sendMessage(_controller.text),
                        ),
                        IconButton(
                          icon: Icon(
                            _isRecording ? Icons.stop_circle : Icons.mic,
                            color: _isRecording ? Colors.red : _getThemeColor(),
                          ),
                          onPressed: _handleMicTap,
                        ),
                        
                        // Call buttons
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: _getThemeColor()),
                          onSelected: (value) {
                            switch (value) {
                              case 'audio_call':
                                startCall(isVideo: false);
                                break;
                              case 'video_call':
                                startCall(isVideo: true);
                                break;
                              case 'butterfly_garden':
                                _sendButterflyMessage();
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'audio_call',
                              child: Row(
                                children: [
                                  Icon(Icons.call),
                                  SizedBox(width: 8),
                                  Text('Audio Call'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'video_call',
                              child: Row(
                                children: [
                                  Icon(Icons.videocam),
                                  SizedBox(width: 8),
                                  Text('Video Call'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'butterfly_garden',
                              child: Row(
                                children: [
                                  Text('�E�'),
                                  SizedBox(width: 8),
                                  Text('Butterfly Garden'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypingText() {
    switch (_otherUserTypingStatus) {
      case TypingStatus.typing:
        return 'typing...';
      case TypingStatus.recording:
        return 'recording...';
      case TypingStatus.thinking:
        return 'thinking...';
      default:
        return '';
    }
  }

  LinearGradient _getThemeGradient() {
    switch (_currentTheme) {
      case ChatTheme.classic:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFED8E6), Color(0xFFFFF1F5)],
        );
      case ChatTheme.neon:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE0F7FF), Color(0xFF00E5FF)],
        );
      case ChatTheme.nature:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8F5E8), Color(0xFFC8E6C9)],
        );
      case ChatTheme.space:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        );
      case ChatTheme.ocean:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
        );
      case ChatTheme.sunset:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF3E0), Color(0xFFFFCC80)],
        );
    }
  }
}


