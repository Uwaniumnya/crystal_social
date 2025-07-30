import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:math';
import 'dart:async';
import '../rewards/rewards_manager.dart';

// Data models for enhanced features
class GlitterPost {
  final String id;
  final String userId;
  final String text;
  final String? imageUrl;
  final String mood;
  final int likesCount;
  final int commentsCount;
  final String? userAvatar;
  final String? userName;
  final DateTime createdAt;
  final List<String> tags;
  final bool isPinned;
  final String? location;

  GlitterPost({
    required this.id,
    required this.userId,
    required this.text,
    this.imageUrl,
    required this.mood,
    required this.likesCount,
    required this.commentsCount,
    this.userAvatar,
    this.userName,
    required this.createdAt,
    this.tags = const [],
    this.isPinned = false,
    this.location,
  });

  factory GlitterPost.fromMap(Map<String, dynamic> map) {
    return GlitterPost(
      id: map['id'].toString(),
      userId: map['user_id'].toString(),
      text: map['text'] ?? '',
      imageUrl: map['image_url'],
      mood: map['mood'] ?? '✨',
      likesCount: map['likes_count'] ?? 0,
      commentsCount: map['comments_count'] ?? 0,
      userAvatar: map['user_avatar'],
      userName: map['user_name'] ?? 'Anonymous',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      tags: (map['tags'] as String?)?.split(',').where((t) => t.isNotEmpty).toList() ?? [],
      isPinned: map['is_pinned'] ?? false,
      location: map['location'],
    );
  }
}

class GlitterComment {
  final String id;
  final String postId;
  final String userId;
  final String text;
  final String? userAvatar;
  final String? userName;
  final DateTime createdAt;
  int likesCount; // Made non-final so it can be updated
  final String? parentCommentId;

  GlitterComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.text,
    this.userAvatar,
    this.userName,
    required this.createdAt,
    required this.likesCount,
    this.parentCommentId,
  });

  factory GlitterComment.fromMap(Map<String, dynamic> map) {
    return GlitterComment(
      id: map['id'].toString(),
      postId: map['post_id'].toString(),
      userId: map['user_id'].toString(),
      text: map['text'] ?? '',
      userAvatar: map['user_avatar'],
      userName: map['user_name'] ?? 'Anonymous',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      likesCount: map['likes_count'] ?? 0,
      parentCommentId: map['parent_comment_id']?.toString(),
    );
  }
}

class GlitterBoardScreen extends StatefulWidget {
  final String userId;

  const GlitterBoardScreen({super.key, required this.userId});

  @override
  _GlitterBoardScreenState createState() => _GlitterBoardScreenState();
}

class _GlitterBoardScreenState extends State<GlitterBoardScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SupabaseClient supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  
  // Enhanced features state
  late AnimationController _sparkleController;
  late AnimationController _heartController;
  late AnimationController _floatingSparkleController;
  late AnimationController _commentController_anim;
  // Note: _tagController for future hashtag animations
  
  bool _isTyping = false;
  String _selectedMood = '✨';
  List<String> _moods = ['✨', '💖', '🌟', '🦄', '🌈', '💫', '🔮', '👑', '🎭', '🌸', '🦋', '⭐'];
  Map<String, Set<String>> _postLikes = {};
  Map<String, Set<String>> _commentLikes = {};
  Map<String, List<GlitterComment>> _postComments = {};
  Map<String, bool> _showComments = {};
  Map<String, bool> _isLoadingComments = {};
  String? _replyingToComment;
  String? _replyingToPost;
  
  bool _isDarkMode = false;
  bool _showHashtagSuggestions = false;
  List<String> _suggestedTags = [];
  String _currentTag = '';
  
  // Enhanced filters and features (for future implementation)
  // These will be used in upcoming filter UI updates
  
  // Pet-related variables
  List<Map<String, dynamic>> userPets = [];
  final Map<String, AnimationController> _petAnimations = {};
  bool _petsVisible = false;
  
  // Enhanced rewards system integration
  late RewardsManager _rewardsManager;

  @override
  void initState() {
    super.initState();
    _rewardsManager = RewardsManager(supabase);
    _setupAnimations();
    _setupListeners();
    _loadInitialData();
    _loadUserPets();
  }
  
  void _setupAnimations() {
    _sparkleController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _heartController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _floatingSparkleController = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    )..repeat();
    
    _commentController_anim = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    // _tagController initialization removed for now - will be added with hashtag features
  }
  
  void _setupListeners() {
    _controller.addListener(() {
      setState(() {
        _isTyping = _controller.text.isNotEmpty;
      });
      
      // Check for hashtag input
      final text = _controller.text;
      final cursorPosition = _controller.selection.baseOffset;
      if (cursorPosition > 0) {
        final beforeCursor = text.substring(0, cursorPosition);
        final words = beforeCursor.split(' ');
        final lastWord = words.isNotEmpty ? words.last : '';
        
        if (lastWord.startsWith('#') && lastWord.length > 1) {
          _currentTag = lastWord.substring(1);
          _showHashtagSuggestions = true;
          _loadHashtagSuggestions(_currentTag);
        } else {
          _showHashtagSuggestions = false;
        }
      }
    });
  }
  
  void _loadInitialData() {
    // Load initial posts and setup real-time subscriptions
  }
  
  // Load user's pets from the home space
  Future<void> _loadUserPets() async {
    try {
      final homeData = await supabase
          .from('user_home')
          .select('*')
          .eq('user_id', widget.userId)
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
    Timer.periodic(Duration(seconds: 4 + (userPets.length * 2)), (timer) {
      if (!mounted || !_petAnimations.containsKey(key)) {
        timer.cancel();
        return;
      }
      _petAnimations[key]?.forward(from: 0.0);
    });
  }
  
  void _loadHashtagSuggestions(String query) {
    // Mock hashtag suggestions - in real app, fetch from database
    final suggestions = [
      'sparkle', 'glitter', 'mood', 'vibes', 'magic', 'dreams', 'inspiration',
      'selfie', 'ootd', 'blessed', 'grateful', 'love', 'happy', 'life',
      'beautiful', 'amazing', 'wonderful', 'perfect', 'cute', 'fun'
    ].where((tag) => tag.toLowerCase().contains(query.toLowerCase())).take(5).toList();
    
    setState(() {
      _suggestedTags = suggestions;
    });
  }

  // Enhanced method to add a new post with tags and location
  void _addPost(String text, String imageUrl) async {
    try {
      // Extract hashtags from text
      final hashtags = RegExp(r'#\w+').allMatches(text)
          .map((match) => match.group(0)!.substring(1))
          .toList();
      
      await supabase.from('glitter_board').insert([
        {
          'user_id': widget.userId,
          'text': text,
          'image_url': imageUrl,
          'mood': _selectedMood,
          'likes_count': 0,
          'comments_count': 0,
          'tags': hashtags.join(','),
          'is_pinned': false,
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);

      // Track content creation activity for enhanced leveling system
      await _rewardsManager.trackActivity(widget.userId, 'content_posted', context, customPoints: 8);

      _controller.clear();
      setState(() {
        _selectedImage = null;
        _selectedMood = '✨';
        _showHashtagSuggestions = false;
      });
      
      // Trigger celebration animation
      _sparkleController.forward().then((_) => _sparkleController.repeat());
      HapticFeedback.lightImpact();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: [
              Text('Post shared successfully! '),
              Text(_selectedMood, style: TextStyle(fontSize: 18)),
              if (hashtags.isNotEmpty) ...[
                SizedBox(width: 8),
                Text('${hashtags.length} tags added'),
              ],
            ],
          ),
          backgroundColor: _isDarkMode ? Colors.purple[700] : Colors.pink[300],
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error posting: $e'),
          backgroundColor: Colors.red[300],
        ));
      }
    }
  }

  // Method to add a comment to a post
  Future<void> _addComment(String postId, String text, {String? parentCommentId}) async {
    try {
      await supabase.from('glitter_comments').insert([
        {
          'post_id': postId,
          'user_id': widget.userId,
          'text': text,
          'parent_comment_id': parentCommentId,
          'likes_count': 0,
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);

      // Update comment count on the post
      await supabase.rpc('increment_comment_count', params: {
        'post_id': postId,
      });

      // Reload comments for this post
      _loadCommentsForPost(postId);
      
      // Track comment activity for enhanced leveling system
      await _rewardsManager.trackActivity(widget.userId, 'comment_posted', context);
      
      _commentController.clear();
      setState(() {
        _replyingToComment = null;
        _replyingToPost = null;
      });

      HapticFeedback.lightImpact();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Comment added! ✨'),
          backgroundColor: _isDarkMode ? Colors.purple[700] : Colors.pink[300],
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error adding comment: $e'),
          backgroundColor: Colors.red[300],
        ));
      }
    }
  }

  // Method to load comments for a specific post
  Future<void> _loadCommentsForPost(String postId) async {
    setState(() {
      _isLoadingComments[postId] = true;
    });

    try {
      final response = await supabase
          .from('glitter_comments')
          .select('''
            id, post_id, user_id, text, likes_count, parent_comment_id, created_at,
            user_profiles!inner(username, avatar_url)
          ''')
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      final comments = response.map((comment) {
        return GlitterComment.fromMap({
          ...comment,
          'user_name': comment['user_profiles']['username'],
          'user_avatar': comment['user_profiles']['avatar_url'],
        });
      }).toList();

      setState(() {
        _postComments[postId] = comments;
        _isLoadingComments[postId] = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingComments[postId] = false;
      });
      debugPrint('Error loading comments: $e');
    }
  }

  // Method to toggle comments visibility
  void _toggleComments(String postId) {
    final isCurrentlyShowing = _showComments[postId] ?? false;
    
    setState(() {
      _showComments[postId] = !isCurrentlyShowing;
    });

    if (!isCurrentlyShowing && (_postComments[postId]?.isEmpty ?? true)) {
      _loadCommentsForPost(postId);
    }

    _commentController_anim.forward().then((_) => _commentController_anim.reverse());
  }

  // Method to toggle comment like
  void _toggleCommentLike(String commentId) async {
    try {
      final userIdStr = widget.userId.toString();
      final isLiked = _commentLikes[commentId]?.contains(userIdStr) ?? false;
      
      if (isLiked) {
        await supabase.rpc('decrement_comment_likes', params: {
          'comment_id': commentId,
        });
        
        setState(() {
          _commentLikes[commentId]?.remove(userIdStr);
        });
      } else {
        await supabase.rpc('increment_comment_likes', params: {
          'comment_id': commentId,
        });
        
        setState(() {
          _commentLikes[commentId] ??= <String>{};
          _commentLikes[commentId]!.add(userIdStr);
        });
        
        // Track comment like activity for enhanced leveling system
        await _rewardsManager.trackActivity(widget.userId, 'content_liked', context);
        
        HapticFeedback.selectionClick();
      }
    } catch (e) {
      debugPrint('Error toggling comment like: $e');
    }
  }

  // Method to toggle like on a post
  void _toggleLike(String postId) async {
    try {
      final userIdStr = widget.userId.toString();
      final isLiked = _postLikes[postId]?.contains(userIdStr) ?? false;
      
      if (isLiked) {
        // Unlike the post
        await supabase.from('glitter_board').update({
          'likes_count': (await supabase
              .from('glitter_board')
              .select('likes_count')
              .eq('id', postId)
              .single())['likes_count'] - 1,
        }).eq('id', postId);
        
        setState(() {
          _postLikes[postId]?.remove(userIdStr);
        });
      } else {
        // Like the post
        await supabase.from('glitter_board').update({
          'likes_count': (await supabase
              .from('glitter_board')
              .select('likes_count')
              .eq('id', postId)
              .single())['likes_count'] + 1,
        }).eq('id', postId);
        
        setState(() {
          _postLikes[postId] ??= <String>{};
          _postLikes[postId]!.add(userIdStr);
        });
        
        // Track like activity for enhanced leveling system
        await _rewardsManager.trackActivity(widget.userId, 'content_liked', context);
        
        // Animate heart
        _heartController.forward().then((_) => _heartController.reverse());
        HapticFeedback.selectionClick();
      }
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  // Method to show mood selector
  void _showMoodSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _isDarkMode ? Color(0xFF1A1A1A) : Colors.white, // Dark black-gray
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose your mood',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 20),
            Wrap(
              spacing: 15,
              runSpacing: 15,
              children: _moods.map((mood) => GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMood = mood;
                  });
                  Navigator.pop(context);
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _selectedMood == mood 
                        ? (_isDarkMode ? Color(0xFF3A3A3A) : Colors.pink[200]) // Dark gray for selected
                        : (_isDarkMode ? Color(0xFF2A2A2A) : Colors.grey[100]), // Dark gray
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: _selectedMood == mood 
                          ? (_isDarkMode ? Colors.purple[200]! : Colors.pink[400]!)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(mood, style: TextStyle(fontSize: 24)),
                  ),
                ),
              )).toList(),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper method to format timestamps
  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    
    try {
      final DateTime postTime = DateTime.parse(timestamp);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(postTime);

      if (difference.inMinutes < 1) {
        return 'just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${postTime.day}/${postTime.month}/${postTime.year}';
      }
    } catch (e) {
      return '';
    }
  }

  // Enhanced method to fetch real-time posts
  Stream<List<dynamic>> _getLivePosts() {
    return supabase
        .from('glitter_board')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  // Image Picker method
  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Upload image to Supabase Storage
  Future<String> _uploadImage(File image) async {
    try {
      // Upload the image to the "glitter-board-images" bucket
      final fileName = DateTime.now().toIso8601String(); // Create a unique file name
      
      await supabase.storage
          .from('glitter-board-images')
          .upload(fileName, image);

      // Get the public URL for the uploaded image
      final imageUrl = supabase.storage
          .from('glitter-board-images')
          .getPublicUrl(fileName);
      
      return imageUrl;
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }


  // Sparkle animation for each post
  Widget _buildSparkleEffect(Widget child) {
    return AnimatedBuilder(
      animation: _sparkleController,
      builder: (context, _) {
        return Stack(
          children: [
            // Main card with subtle scale animation
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.8, end: 1.0),
              duration: Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: child,
            ),
            // Subtle sparkle particles
            if (_isTyping)
              ...List.generate(3, (index) {
                return Positioned(
                  top: 20.0 + (index * 15),
                  right: 10.0 + (index * 8),
                  child: Transform.rotate(
                    angle: _sparkleController.value * 6.28 + (index * 2),
                    child: Opacity(
                      opacity: (0.3 + (0.4 * _sparkleController.value)).clamp(0.0, 0.7),
                      child: Icon(
                        Icons.auto_awesome,
                        size: 12 + (4 * _sparkleController.value),
                        color: _isDarkMode ? Colors.purple[300] : Colors.pink[300],
                      ),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  // Enhanced Post Input UI with hashtag suggestions
  Widget _buildPostInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: _isDarkMode ? Color(0xFF1A1A1A) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: _isDarkMode ? Color(0xFF2A2A2A) : Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Enhanced mood indicator row
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isDarkMode 
                  ? [Color(0xFF2A2A2A), Color(0xFF3A3A3A)]
                  : [Colors.pink[50]!, Colors.purple[50]!],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isDarkMode ? Colors.purple[300]! : Colors.pink[200]!,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.mood,
                  size: 16,
                  color: _isDarkMode ? Colors.purple[300] : Colors.pink[400],
                ),
                SizedBox(width: 8),
                Text(
                  'Mood: ',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(_selectedMood, style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: _showMoodSelector,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _isDarkMode ? Colors.purple[400] : Colors.pink[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          
          // Image preview section
          if (_selectedImage != null)
            Container(
              height: 120,
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: _isDarkMode ? Colors.purple[400]! : Colors.pink[200]!,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isDarkMode ? Colors.purple[400]! : Colors.pink[200]!).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Image.file(
                      _selectedImage!,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Enhanced close button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImage = null;
                        });
                        HapticFeedback.lightImpact();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                        ),
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  // Image info overlay
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Image ready',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Enhanced input row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Enhanced image picker button
              Container(
                margin: EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isDarkMode 
                      ? [Colors.purple[400]!, Colors.purple[600]!]
                      : [Colors.pink[300]!, Colors.pink[400]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (_isDarkMode ? Colors.purple[400]! : Colors.pink[300]!).withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.add_photo_alternate, color: Colors.white),
                  onPressed: _pickImage,
                  tooltip: 'Add image',
                ),
              ),
              
              // Enhanced text input
              Expanded(
                child: Column(
                  children: [
                    TextField(
                      controller: _controller,
                      maxLines: null,
                      minLines: 1,
                      maxLength: 500,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: "Share your sparkly thought... ✨\nTry adding #hashtags!",
                        hintStyle: TextStyle(
                          color: _isDarkMode ? Colors.white54 : Colors.black54,
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: _isDarkMode ? Colors.purple[300]! : Colors.pink[200]!,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: _isDarkMode ? Colors.purple[300]! : Colors.pink[200]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: _isDarkMode ? Colors.purple[400]! : Colors.pink[400]!,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: _isDarkMode ? Color(0xFF2A2A2A) : Colors.pink[50],
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        counterStyle: TextStyle(
                          color: _isDarkMode ? Colors.white54 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    
                    // Hashtag suggestions
                    if (_showHashtagSuggestions && _suggestedTags.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(top: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isDarkMode ? Color(0xFF2A2A2A) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isDarkMode ? Colors.purple[300]! : Colors.pink[200]!,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.tag,
                                  size: 16,
                                  color: _isDarkMode ? Colors.purple[300] : Colors.pink[400],
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Suggested hashtags:',
                                  style: TextStyle(
                                    color: _isDarkMode ? Colors.white70 : Colors.black54,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: _suggestedTags.map((tag) => GestureDetector(
                                onTap: () {
                                  final text = _controller.text;
                                  final cursorPosition = _controller.selection.baseOffset;
                                  final beforeCursor = text.substring(0, cursorPosition);
                                  final afterCursor = text.substring(cursorPosition);
                                  final words = beforeCursor.split(' ');
                                  words.last = '#$tag ';
                                  final newText = words.join(' ') + afterCursor;
                                  
                                  _controller.text = newText;
                                  _controller.selection = TextSelection.fromPosition(
                                    TextPosition(offset: words.join(' ').length),
                                  );
                                  
                                  setState(() {
                                    _showHashtagSuggestions = false;
                                  });
                                  
                                  HapticFeedback.selectionClick();
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _isDarkMode ? Colors.purple[700] : Colors.pink[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '#$tag',
                                    style: TextStyle(
                                      color: _isDarkMode ? Colors.white : Colors.pink[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              
              // Enhanced send button with sparkle animation
              Container(
                margin: EdgeInsets.only(left: 8),
                child: AnimatedBuilder(
                  animation: _sparkleController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isTyping ? 1.0 + (0.1 * _sparkleController.value) : 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isDarkMode 
                              ? [Colors.purple[400]!, Colors.purple[600]!]
                              : [Colors.pink[300]!, Colors.pink[500]!],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: (_isDarkMode ? Colors.purple[400]! : Colors.pink[300]!).withOpacity(0.4),
                              blurRadius: _isTyping ? 12 : 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.send, color: Colors.white),
                              if (_isTyping) ...[
                                SizedBox(width: 4),
                                Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                              ],
                            ],
                          ),
                          onPressed: _isTyping || _selectedImage != null ? () async {
                            if (_controller.text.isNotEmpty || _selectedImage != null) {
                              String imageUrl = '';
                              if (_selectedImage != null) {
                                try {
                                  // Show upload progress
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Row(
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
                                        Text('Uploading image...'),
                                      ],
                                    ),
                                    backgroundColor: _isDarkMode ? Colors.purple[700] : Colors.pink[300],
                                    duration: Duration(seconds: 10),
                                  ));
                                  
                                  imageUrl = await _uploadImage(_selectedImage!);
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text('Failed to upload image: $e'),
                                      backgroundColor: Colors.red[300],
                                    ));
                                  }
                                  return;
                                }
                              }
                              _addPost(_controller.text, imageUrl);
                            }
                          } : null,
                          tooltip: 'Share your sparkle',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // User info display above the post
  Widget _buildUserHeader(Map post) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25.0,
            backgroundColor: _isDarkMode ? Color(0xFF3A3A3A) : Colors.pink[200], // Dark gray
            backgroundImage: post['user_avatar'] != null && post['user_avatar'].isNotEmpty
                ? NetworkImage(post['user_avatar'])
                : null,
            child: post['user_avatar'] == null || post['user_avatar'].isEmpty
                ? Icon(
                    Icons.person,
                    color: _isDarkMode ? Colors.white54 : Colors.pink[800],
                  )
                : null,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post['user_name'] ?? 'Anonymous User',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                    color: _isDarkMode ? Colors.purple[300] : Colors.pink[400],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Sparkling with feelings...',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 12.0,
                    color: _isDarkMode ? Colors.white54 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced comments section widget
  Widget _buildCommentsSection(String postId) {
    final comments = _postComments[postId] ?? [];
    final isLoading = _isLoadingComments[postId] ?? false;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isDarkMode ? Color(0xFF0F0F0F) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDarkMode ? Color(0xFF3A3A3A) : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comments header
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: _isDarkMode ? Colors.purple[300] : Colors.pink[400],
              ),
              SizedBox(width: 6),
              Text(
                'Comments',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white70 : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              if (isLoading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isDarkMode ? Colors.purple[300]! : Colors.pink[400]!,
                    ),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: 8),
          
          // Comments list
          if (comments.isNotEmpty) ...[
            ...comments.map((comment) => _buildCommentItem(comment)).toList(),
            SizedBox(height: 8),
          ] else if (!isLoading) ...[
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 32,
                    color: _isDarkMode ? Colors.white30 : Colors.grey[400],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No comments yet',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white54 : Colors.black54,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Be the first to share your thoughts!',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white30 : Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Comment input
          if (_replyingToPost == postId || _replyingToPost == null) ...[
            Container(
              margin: EdgeInsets.only(top: 8),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isDarkMode ? Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isDarkMode ? Colors.purple[400]! : Colors.pink[200]!,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // User avatar
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _isDarkMode ? Color(0xFF3A3A3A) : Colors.pink[200],
                    child: Icon(
                      Icons.person,
                      size: 18,
                      color: _isDarkMode ? Colors.white54 : Colors.pink[800],
                    ),
                  ),
                  SizedBox(width: 8),
                  
                  // Comment input field
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: _replyingToComment != null 
                            ? 'Reply to comment...' 
                            : 'Add a comment...',
                        hintStyle: TextStyle(
                          color: _isDarkMode ? Colors.white54 : Colors.black54,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      maxLines: null,
                      minLines: 1,
                      onTap: () {
                        setState(() {
                          _replyingToPost = postId;
                        });
                      },
                    ),
                  ),
                  
                  // Send comment button
                  GestureDetector(
                    onTap: () {
                      if (_commentController.text.isNotEmpty) {
                        _addComment(
                          postId, 
                          _commentController.text,
                          parentCommentId: _replyingToComment,
                        );
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isDarkMode 
                            ? [Colors.purple[400]!, Colors.purple[600]!]
                            : [Colors.pink[300]!, Colors.pink[500]!],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.send,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Cancel reply button
          if (_replyingToComment != null) ...[
            SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                setState(() {
                  _replyingToComment = null;
                  _replyingToPost = null;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'Cancel reply',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.red[300] : Colors.red[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Individual comment item widget
  Widget _buildCommentItem(GlitterComment comment) {
    final isReplying = _replyingToComment == comment.id;
    
    return Container(
      margin: EdgeInsets.only(
        bottom: 8,
        left: comment.parentCommentId != null ? 20 : 0, // Indent replies
      ),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _isDarkMode ? Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isReplying
              ? (_isDarkMode ? Colors.purple[400]! : Colors.pink[300]!)
              : (_isDarkMode ? Color(0xFF2A2A2A) : Colors.grey[200]!),
          width: isReplying ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comment header
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: _isDarkMode ? Color(0xFF3A3A3A) : Colors.pink[200],
                backgroundImage: comment.userAvatar != null && comment.userAvatar!.isNotEmpty
                    ? NetworkImage(comment.userAvatar!)
                    : null,
                child: comment.userAvatar == null || comment.userAvatar!.isEmpty
                    ? Icon(
                        Icons.person,
                        size: 14,
                        color: _isDarkMode ? Colors.white54 : Colors.pink[800],
                      )
                    : null,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.userName ?? 'Anonymous',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.purple[300] : Colors.pink[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatTimestamp(comment.createdAt.toIso8601String()),
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white30 : Colors.grey[500],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Comment actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Like comment button
                  GestureDetector(
                    onTap: () => _toggleCommentLike(comment.id),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (_commentLikes[comment.id]?.contains(widget.userId.toString()) ?? false)
                            ? (_isDarkMode ? Color(0xFF4A1A1A) : Colors.red[100])
                            : (_isDarkMode ? Color(0xFF2A2A2A) : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            (_commentLikes[comment.id]?.contains(widget.userId.toString()) ?? false)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 12,
                            color: (_commentLikes[comment.id]?.contains(widget.userId.toString()) ?? false)
                                ? Colors.red[600]
                                : (_isDarkMode ? Colors.white54 : Colors.black54),
                          ),
                          if (comment.likesCount > 0) ...[
                            SizedBox(width: 2),
                            Text(
                              '${comment.likesCount}',
                              style: TextStyle(
                                color: _isDarkMode ? Colors.white70 : Colors.black87,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 4),
                  
                  // Reply button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _replyingToComment = isReplying ? null : comment.id;
                        _replyingToPost = comment.postId;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isReplying
                            ? (_isDarkMode ? Colors.purple[700] : Colors.pink[200])
                            : (_isDarkMode ? Color(0xFF2A2A2A) : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.reply,
                        size: 12,
                        color: isReplying
                            ? Colors.white
                            : (_isDarkMode ? Colors.white54 : Colors.black54),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          SizedBox(height: 6),
          
          // Comment text
          Text(
            comment.text,
            style: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Color(0xFF0A0A0A) : null, // Deep black-gray
      appBar: AppBar(
        title: Row(
          children: [
            Text('✨ GlitterBoard'),
            SizedBox(width: 8),
            Text(_selectedMood, style: TextStyle(fontSize: 20)),
          ],
        ),
        backgroundColor: _isDarkMode ? Color(0xFF1A1A1A) : Colors.pink[200], // Dark black-gray
        foregroundColor: _isDarkMode ? Colors.white : Colors.black,
        actions: [
          // Mood selector button
          IconButton(
            icon: Icon(Icons.mood),
            onPressed: _showMoodSelector,
            tooltip: 'Choose mood',
          ),
          // Dark mode toggle
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
              HapticFeedback.selectionClick();
            },
            tooltip: _isDarkMode ? 'Light mode' : 'Dark mode',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildPostInput(),
              Expanded(
                child: StreamBuilder<List<dynamic>>(
                  stream: _getLivePosts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final posts = snapshot.data ?? [];

                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _buildSparkleEffect(
                      Card(
                        margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                        elevation: _isDarkMode ? 8.0 : 2.0, // Higher elevation for dark mode
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        color: _isDarkMode ? Color(0xFF1A1A1A) : Colors.pink[50], // Dark black-gray
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildUserHeader(post),
                              SizedBox(height: 10),
                              // Mood display
                              if (post['mood'] != null)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _isDarkMode ? Color(0xFF2A2A2A) : Colors.pink[100], // Dark gray
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(post['mood'], style: TextStyle(fontSize: 16)),
                                      SizedBox(width: 4),
                                      Text(
                                        'mood',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _isDarkMode ? Colors.white70 : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              SizedBox(height: 8),
                              Text(
                                post['text'] ?? '',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: _isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              if (post['image_url'] != null && post['image_url'] != '')
                                Padding(
                                  padding: const EdgeInsets.only(top: 10.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      post['image_url'],
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          height: 100,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: _isDarkMode ? Color(0xFF2A2A2A) : Colors.grey[300], // Dark gray
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.broken_image,
                                                size: 40,
                                                color: _isDarkMode ? Colors.white54 : Colors.black54,
                                              ),
                                              Text(
                                                'Image not available',
                                                style: TextStyle(
                                                  color: _isDarkMode ? Colors.white54 : Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          height: 100,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                              color: _isDarkMode ? Colors.purple[300] : Colors.pink[300],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              SizedBox(height: 12),
                              // Enhanced like and interaction row
                              Row(
                                children: [
                                  // Like button with animation
                                  AnimatedBuilder(
                                    animation: _heartController,
                                    builder: (context, child) {
                                      final isLiked = _postLikes[post['id'].toString()]?.contains(widget.userId.toString()) ?? false;
                                      return Transform.scale(
                                        scale: isLiked ? 1.0 + (0.3 * _heartController.value) : 1.0,
                                        child: GestureDetector(
                                          onTap: () => _toggleLike(post['id'].toString()),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: isLiked 
                                                  ? (_isDarkMode ? Color(0xFF4A1A1A) : Colors.red[100])
                                                  : (_isDarkMode ? Color(0xFF2A2A2A) : Colors.grey[200]),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: isLiked 
                                                  ? Colors.red[300]!
                                                  : (_isDarkMode ? Colors.purple[300]! : Colors.pink[200]!),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                                  color: isLiked 
                                                      ? Colors.red[600] 
                                                      : (_isDarkMode ? Colors.white54 : Colors.black54),
                                                  size: 18,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  '${post['likes_count'] ?? 0}',
                                                  style: TextStyle(
                                                    color: _isDarkMode ? Colors.white : Colors.black,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  
                                  SizedBox(width: 8),
                                  
                                  // Enhanced comment button
                                  GestureDetector(
                                    onTap: () => _toggleComments(post['id'].toString()),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: (_showComments[post['id'].toString()] ?? false)
                                            ? (_isDarkMode ? Color(0xFF2A3A4A) : Colors.blue[100])
                                            : (_isDarkMode ? Color(0xFF2A2A2A) : Colors.grey[200]),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: (_showComments[post['id'].toString()] ?? false)
                                            ? Colors.blue[300]!
                                            : (_isDarkMode ? Colors.purple[300]! : Colors.pink[200]!),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.chat_bubble_outline,
                                            color: (_showComments[post['id'].toString()] ?? false)
                                                ? Colors.blue[600]
                                                : (_isDarkMode ? Colors.white54 : Colors.black54),
                                            size: 18,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            '${post['comments_count'] ?? 0}',
                                            style: TextStyle(
                                              color: _isDarkMode ? Colors.white : Colors.black,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  
                                  SizedBox(width: 8),
                                  
                                  // Share button
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text('Share feature coming soon! ✨'),
                                        backgroundColor: _isDarkMode ? Colors.purple[700] : Colors.pink[300],
                                        behavior: SnackBarBehavior.floating,
                                      ));
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _isDarkMode ? Color(0xFF2A2A2A) : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _isDarkMode ? Colors.purple[300]! : Colors.pink[200]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.share,
                                        color: _isDarkMode ? Colors.white54 : Colors.black54,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  
                                  Spacer(),
                                  
                                  // Enhanced timestamp
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _isDarkMode ? Color(0xFF2A2A2A) : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _formatTimestamp(post['created_at']),
                                      style: TextStyle(
                                        color: _isDarkMode ? Colors.white54 : Colors.black54,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Comments section
                              if (_showComments[post['id'].toString()] ?? false) ...[
                                SizedBox(height: 12),
                                _buildCommentsSection(post['id'].toString()),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // Floating pets display
      if (_petsVisible && userPets.isNotEmpty) 
        ..._buildFloatingPets(),
      // Floating sparkles overlay
      if (_isDarkMode) _buildFloatingSparkles(),
    ],
  ),
    );
  }

  // Floating sparkles that appear randomly around the screen
  Widget _buildFloatingSparkles() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _floatingSparkleController,
        builder: (context, child) {
          return Stack(
            children: List.generate(12, (index) {
              // Create different sparkle positions and timings with more variety
              final progress = (_floatingSparkleController.value + (index * 0.083)) % 1.0;
              final opacity = (0.2 + 0.6 * (1 - (progress - 0.5).abs() * 2)).clamp(0.0, 0.7);
              final size = 6.0 + (16.0 * (1 - (progress - 0.5).abs() * 2));
              
              // Different movement patterns for each sparkle
              final xOffset = index % 2 == 0 
                  ? (30.0 + index * 35.0) % MediaQuery.of(context).size.width
                  : MediaQuery.of(context).size.width - ((30.0 + index * 35.0) % MediaQuery.of(context).size.width);
              
              final yOffset = 80.0 + (progress * MediaQuery.of(context).size.height * 0.8) + 
                  (20.0 * (index % 3 - 1)); // Add some horizontal drift
              
              return Positioned(
                left: xOffset,
                top: yOffset,
                child: IgnorePointer(
                  child: Transform.rotate(
                    angle: progress * 6.28 * 3 + (index * 1.57), // Triple rotation speed with offset
                    child: Opacity(
                      opacity: opacity,
                      child: Icon(
                        [
                          Icons.auto_awesome, 
                          Icons.star, 
                          Icons.diamond,
                          Icons.lens,
                          Icons.scatter_plot,
                          Icons.brightness_1
                        ][index % 6],
                        size: size,
                        color: [
                          Colors.purple[300]!.withOpacity(0.8),
                          Colors.pink[300]!.withOpacity(0.8),
                          Colors.blue[300]!.withOpacity(0.8),
                          Colors.amber[300]!.withOpacity(0.8),
                          Colors.cyan[300]!.withOpacity(0.8),
                          Colors.deepPurple[300]!.withOpacity(0.8),
                        ][index % 6],
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  // Build floating pets that appear on screen
  List<Widget> _buildFloatingPets() {
    List<Widget> petWidgets = [];
    
    for (int i = 0; i < userPets.length && i < 4; i++) {
      final pet = userPets[i];
      final key = pet['name'].toString().toLowerCase().replaceAll(" ", "_");
      final imageUrl = pet['image_url'];
      
      // Position pets around the screen edges
      double? left, right, top, bottom;
      
      switch (i) {
        case 0:
          right = 20;
          top = 120;
          break;
        case 1:
          left = 20;
          top = 250;
          break;
        case 2:
          right = 20;
          bottom = 200;
          break;
        case 3:
          left = 20;
          bottom = 300;
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
                    offset: Offset(0, -8 * bounce),
                    child: child,
                  );
                },
                child: Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(27.5),
                    boxShadow: [
                      BoxShadow(
                        color: (_isDarkMode ? Colors.purple[400]! : Colors.pink[300]!).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(27.5),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isDarkMode 
                                ? [Colors.purple[400]!, Colors.purple[600]!]
                                : [Colors.pink[200]!, Colors.pink[400]!],
                            ),
                            borderRadius: BorderRadius.circular(27.5),
                          ),
                          child: const Icon(
                            Icons.pets,
                            color: Colors.white,
                            size: 28,
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
        content: Row(
          children: [
            Text('${pet['name']} wants to sparkle with you! '),
            Text('🐾✨', style: TextStyle(fontSize: 18)),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: _isDarkMode ? Colors.purple[700] : Colors.pink[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
    
    // Add some sparkle effects
    _sparkleController.forward().then((_) => _sparkleController.repeat());
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _sparkleController.dispose();
    _heartController.dispose();
    _floatingSparkleController.dispose();
    _commentController.dispose();
    
    // Dispose pet animations
    for (var controller in _petAnimations.values) {
      controller.dispose();
    }
    
    super.dispose();
  }
}
