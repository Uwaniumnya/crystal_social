import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'dart:async';

class CrystalConfessionalScreen extends StatefulWidget {
  const CrystalConfessionalScreen({super.key});

  @override
  _CrystalConfessionalScreenState createState() =>
      _CrystalConfessionalScreenState();
}

class _CrystalConfessionalScreenState extends State<CrystalConfessionalScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SupabaseClient supabase = Supabase.instance.client;
  final FocusNode _focusNode = FocusNode();

  // Enhanced state management
  List<Map<String, dynamic>> messages = [];
  String? backgroundImage;
  bool _isLoading = false;
  bool _isPosting = false;
  String _selectedMood = 'mysterious';
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _sparkleController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _sparkleAnimation;
  
  // Confession statistics
  int _totalConfessions = 0;
  int _userConfessions = 0;
  String _mostPopularEmoji = '💋';
  
  // Auto-refresh timer
  Timer? _refreshTimer;
  
  // Enhanced emoji categories
  final Map<String, List<String>> _emojiCategories = {
    'mysterious': [
      '🌹🔮✨', '🖤🌙⚡', '💜🦋🌟', '🔮💫🌸', '🌹🕷️💎',
      '🖤⛓️🌹', '💀🌹🖤', '🔮🌙💜', '⚡💎🌟', '🌸🖤💫'
    ],
    'romantic': [
      '💋❤️🌹', '💕💖✨', '🌹💋💄', '❤️‍🔥💫🌹', '💋🥰💕',
      '🌹💖✨', '💄💋🌹', '💕🦋💖', '🌹❤️💫', '💋💕🌸'
    ],
    'dark': [
      '🖤💀⚡', '⛓️🔪💔', '💀🕷️🖤', '🔥💀⚡', '⛓️💔🌑',
      '💀🖤🕸️', '🔪💔⚡', '🖤⛓️💀', '🌑💔🕷️', '💀🔥🖤'
    ],
    'playful': [
      '😈💋🎭', '😏🌶️✨', '😉💃🎪', '🎭💋😈', '🌶️😏💫',
      '💃😉🎪', '😈🎭💋', '💫😏🌶️', '🎪💃😉', '💋😈🎭'
    ],
    'ethereal': [
      '🌙⭐💫', '✨🦋🌸', '🌟💎🌙', '💫⭐✨', '🌸🦋🌟',
      '💎🌙✨', '⭐💫🌸', '🌟🦋💎', '🌙✨💫', '🦋🌸⭐'
    ]
  };
  
  // Confession mood themes
  final Map<String, Map<String, Color>> _moodThemes = {
    'mysterious': {
      'primary': Color(0xFF6A1B9A),
      'secondary': Color(0xFF9C27B0),
      'accent': Color(0xFFE1BEE7),
      'background': Color(0xFF1A0033),
      'card': Color(0xFF2D1B4E),
      'text': Colors.white,
    },
    'romantic': {
      'primary': Color(0xFFC2185B),
      'secondary': Color(0xFFE91E63),
      'accent': Color(0xFFF8BBD9),
      'background': Color(0xFF2D0A1F),
      'card': Color(0xFF4A1B3A),
      'text': Colors.white,
    },
    'dark': {
      'primary': Color(0xFF212121),
      'secondary': Color(0xFF424242),
      'accent': Color(0xFF757575),
      'background': Color(0xFF0D0D0D),
      'card': Color(0xFF1C1C1C),
      'text': Colors.white,
    },
    'playful': {
      'primary': Color(0xFFFF6F00),
      'secondary': Color(0xFFFF8F00),
      'accent': Color(0xFFFFCC02),
      'background': Color(0xFF1A0D00),
      'card': Color(0xFF2D1A00),
      'text': Colors.white,
    },
    'ethereal': {
      'primary': Color(0xFF1976D2),
      'secondary': Color(0xFF2196F3),
      'accent': Color(0xFFBBDEFB),
      'background': Color(0xFF0A1929),
      'card': Color(0xFF1A2B42),
      'text': Colors.white,
    }
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchMessages();
    _calculateStatistics();
    _setupAutoRefresh();
    backgroundImage = 'assets/tabs/confession.png';
  }
  
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    
    _sparkleController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeOut),
    );
    
    _fadeController.forward();
  }
  
  void _setupAutoRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _fetchMessages();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _sparkleController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Enhanced method to fetch messages with error handling and statistics
  Future<void> _fetchMessages() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await supabase
          .from('confessions')
          .select('*')
          .order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          messages = List<Map<String, dynamic>>.from(response as List);
          _isLoading = false;
        });
        _calculateStatistics();
        _slideController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load confessions. Please try again.');
      }
    }
  }
  
  void _calculateStatistics() {
    _totalConfessions = messages.length;
    
    // Calculate most popular emoji
    Map<String, int> emojiCount = {};
    for (var message in messages) {
      String emoji = message['emoji'] ?? '';
      emojiCount[emoji] = (emojiCount[emoji] ?? 0) + 1;
    }
    
    if (emojiCount.isNotEmpty) {
      _mostPopularEmoji = emojiCount.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }
  }

  // Enhanced method to send confession with animations and validation
  Future<void> _sendConfession(String message) async {
    if (message.trim().isEmpty || _isPosting) return;
    
    setState(() {
      _isPosting = true;
    });
    
    try {
      final randomEmoji = _getRandomEmojiForMood(_selectedMood);
      
      await supabase.from('confessions').insert({
        'message': message.trim(),
        'emoji': randomEmoji,
        'mood': _selectedMood,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      setState(() {
        _userConfessions++;
      });
      
      // Trigger sparkle animation
      _sparkleController.forward().then((_) {
        _sparkleController.reset();
      });
      
      // Add haptic feedback
      HapticFeedback.lightImpact();
      
      await _fetchMessages();
      
      // Auto-scroll to top to show new confession
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      
      _showSuccessSnackBar('Your confession has been shared! ✨');
      
    } catch (e) {
      _showErrorSnackBar('Failed to share confession. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }
  
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _moodThemes[_selectedMood]!['primary'],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Enhanced emoji selection based on mood
  String _getRandomEmojiForMood(String mood) {
    final emojisForMood = _emojiCategories[mood] ?? _emojiCategories['mysterious']!;
    final random = Random();
    return emojisForMood[random.nextInt(emojisForMood.length)];
  }
  
  // Helper method to format timestamp
  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return timestamp;
    }
  }
  
  // Method to change mood theme
  void _changeMood(String newMood) {
    setState(() {
      _selectedMood = newMood;
    });
    HapticFeedback.selectionClick();
    
    // Trigger fade animation
    _fadeController.reset();
    _fadeController.forward();
  }
  
  // Method to refresh messages manually
  Future<void> _refreshMessages() async {
    HapticFeedback.lightImpact();
    await _fetchMessages();
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = _moodThemes[_selectedMood]!;
    
    return Scaffold(
      backgroundColor: currentTheme['background'],
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: currentTheme['accent'],
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Crystal Confessional',
                    style: TextStyle(
                      color: currentTheme['text'],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        backgroundColor: currentTheme['primary'],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: currentTheme['accent']),
            onPressed: _refreshMessages,
            tooltip: 'Refresh confessions',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.palette, color: currentTheme['accent']),
            onSelected: _changeMood,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'mysterious', child: Text('🔮 Mysterious')),
              PopupMenuItem(value: 'romantic', child: Text('💕 Romantic')),
              PopupMenuItem(value: 'dark', child: Text('🖤 Dark')),
              PopupMenuItem(value: 'playful', child: Text('😈 Playful')),
              PopupMenuItem(value: 'ethereal', child: Text('✨ Ethereal')),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              currentTheme['background']!,
              currentTheme['primary']!.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: Column(
          children: [
            // Statistics Header
            _buildStatisticsHeader(currentTheme),
            
            // Mood Selector
            _buildMoodSelector(currentTheme),
            
            // Messages List
            Expanded(
              child: _isLoading
                  ? _buildLoadingWidget(currentTheme)
                  : _buildMessagesList(currentTheme),
            ),
            
            // Input Field
            _buildInputField(currentTheme),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatisticsHeader(Map<String, Color> theme) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme['card']!.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme['accent']!.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', _totalConfessions.toString(), '💫', theme),
          _buildStatItem('Yours', _userConfessions.toString(), '✨', theme),
          _buildStatItem('Popular', _mostPopularEmoji, '🔥', theme),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, String icon, Map<String, Color> theme) {
    return Column(
      children: [
        Text(
          icon,
          style: TextStyle(fontSize: 20),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme['accent'],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme['text']!.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMoodSelector(Map<String, Color> theme) {
    return Container(
      height: 60,
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _emojiCategories.keys.map((mood) {
          final isSelected = mood == _selectedMood;
          return GestureDetector(
            onTap: () => _changeMood(mood),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(horizontal: 4),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? theme['accent'] : theme['card'],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? theme['primary']! : theme['accent']!.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getRandomEmojiForMood(mood).split('').first,
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    mood.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? theme['background'] : theme['text'],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildLoadingWidget(Map<String, Color> theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(theme['accent']),
          ),
          SizedBox(height: 16),
          Text(
            'Loading confessions...',
            style: TextStyle(
              color: theme['text']!.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessagesList(Map<String, Color> theme) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '🌙',
              style: TextStyle(fontSize: 64),
            ),
            SizedBox(height: 16),
            Text(
              'No confessions yet...',
              style: TextStyle(
                fontSize: 18,
                color: theme['text']!.withValues(alpha: 0.7),
              ),
            ),
            Text(
              'Be the first to share your secret!',
              style: TextStyle(
                fontSize: 14,
                color: theme['text']!.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _refreshMessages,
        color: theme['accent'],
        backgroundColor: theme['card'],
        child: ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            return SlideTransition(
              position: _slideAnimation,
              child: _buildConfessionCard(messages[index], theme, index),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildConfessionCard(Map<String, dynamic> message, Map<String, Color> theme, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Card(
        color: theme['card']!.withValues(alpha: 0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme['accent']!.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme['primary']!.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message['emoji'] ?? '💫',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme['accent']!.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (message['mood'] ?? 'mysterious').toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme['accent'],
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _formatTimestamp(message['created_at']),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme['text']!.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                message['message'] ?? '',
                style: TextStyle(
                  fontSize: 16,
                  color: theme['text'],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInputField(Map<String, Color> theme) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme['card']!.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: theme['accent']!.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: TextStyle(color: theme['text']),
              maxLines: null,
              maxLength: 280,
              decoration: InputDecoration(
                hintText: 'Share your confession... ✨',
                hintStyle: TextStyle(color: theme['text']!.withValues(alpha: 0.6)),
                filled: true,
                fillColor: theme['background']!.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: theme['accent']!.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: theme['accent']!, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                counterStyle: TextStyle(color: theme['text']!.withValues(alpha: 0.5)),
              ),
            ),
          ),
          SizedBox(width: 12),
          AnimatedBuilder(
            animation: _sparkleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_sparkleAnimation.value * 0.1),
                child: FloatingActionButton(
                  onPressed: _isPosting ? null : () async {
                    if (_controller.text.trim().isNotEmpty) {
                      await _sendConfession(_controller.text);
                      _controller.clear();
                      _focusNode.unfocus();
                    }
                  },
                  backgroundColor: _isPosting ? theme['accent']!.withValues(alpha: 0.5) : theme['accent'],
                  child: _isPosting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(theme['background']),
                          ),
                        )
                      : Icon(
                          Icons.send,
                          color: theme['background'],
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
