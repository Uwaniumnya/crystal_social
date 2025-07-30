import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/glimmer_upload_sheet.dart';
import '../services/glimmer_service.dart';
import 'dart:math' as math;

/// Glimmer Wall - Pinterest-style Image Board
/// Beautiful masonry layout with categories, search, and user-generated content
class GlimmerWallScreen extends StatefulWidget {
  final String currentUserId;

  const GlimmerWallScreen({
    Key? key,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<GlimmerWallScreen> createState() => _GlimmerWallScreenState();
}

class _GlimmerWallScreenState extends State<GlimmerWallScreen>
    with TickerProviderStateMixin {
  final GlimmerService _glimmerService = GlimmerService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<GlimmerPost> _posts = [];
  List<String> _categories = [
    'All',
    'Nature',
    'Art',
    'Photography',
    'Design',
    'Fashion',
    'Food',
    'Travel',
    'Architecture',
    'Anime',
    'Gaming',
    'Music',
    'Sports',
    'Animals',
    'Technology',
    'Space',
    'Vintage',
    'Minimalist',
    'Abstract',
    'Fantasy'
  ];
  
  String _selectedCategory = 'All';
  bool _isLoading = false;
  String _searchQuery = '';
  
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  void _setupAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _fabAnimationController.forward();
  }

  void _onScroll() {
    if (_scrollController.position.pixels > 100) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _glimmerService.getPosts(
        category: _selectedCategory,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        currentUserId: widget.currentUserId,
      );

      List<GlimmerPost> posts = response.map((json) => GlimmerPost.fromJson(json)).toList();

      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading posts: $e');
      // Fallback to mock data if there's an error
      await _loadMockData();
    }
  }

  // Fallback method for when database isn't set up yet
  Future<void> _loadMockData() async {
    setState(() => _isLoading = true);
    
    await Future.delayed(const Duration(seconds: 1));
    
    final mockPosts = [
      GlimmerPost(
        id: '1',
        title: 'Beautiful Sunset',
        description: 'Amazing sunset captured at the beach',
        imageUrl: 'https://picsum.photos/300/400?random=1',
        category: 'Nature',
        userId: 'user1',
        username: 'NatureExplorer',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        likesCount: 42,
        commentsCount: 8,
        tags: ['sunset', 'beach', 'nature'],
      ),
      GlimmerPost(
        id: '2',
        title: 'Digital Art Masterpiece',
        description: 'Created with love and pixels',
        imageUrl: 'https://picsum.photos/300/300?random=2',
        category: 'Art',
        userId: 'user2',
        username: 'PixelArtist',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        likesCount: 127,
        commentsCount: 23,
        tags: ['digital', 'art', 'creative'],
      ),
      GlimmerPost(
        id: '3',
        title: 'Mountain Adventure',
        description: 'Hiking through the Alps',
        imageUrl: 'https://picsum.photos/300/500?random=3',
        category: 'Travel',
        userId: 'user3',
        username: 'Wanderlust',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        likesCount: 89,
        commentsCount: 15,
        tags: ['mountains', 'hiking', 'adventure'],
      ),
      GlimmerPost(
        id: '4',
        title: 'Urban Photography',
        description: 'City lights at night',
        imageUrl: 'https://picsum.photos/300/350?random=4',
        category: 'Photography',
        userId: 'user4',
        username: 'CityShutter',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        likesCount: 156,
        commentsCount: 31,
        tags: ['urban', 'night', 'photography'],
      ),
    ];
    
    // Apply filters
    var filteredPosts = mockPosts;
    
    if (_selectedCategory != 'All') {
      filteredPosts = filteredPosts
          .where((post) => post.category == _selectedCategory)
          .toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      filteredPosts = filteredPosts
          .where((post) => 
              post.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              post.description.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    
    setState(() {
      _posts = filteredPosts;
      _isLoading = false;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),
          _buildSearchBar(),
          _buildCategoryChips(),
          _buildPostsGrid(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Colors.purple.shade400,
              Colors.pink.shade400,
              Colors.orange.shade400,
            ],
          ).createShader(bounds),
          child: const Text(
            'Glimmer Wall',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.shade100.withOpacity(0.8),
                Colors.pink.shade100.withOpacity(0.8),
                Colors.orange.shade100.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search Glimmer Wall...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      _loadPosts();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
            if (value.isEmpty || value.length > 2) {
              _debounceSearch();
            }
          },
        ),
      ),
    );
  }

  void _debounceSearch() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == _searchQuery) {
        _loadPosts();
      }
    });
  }

  Widget _buildCategoryChips() {
    return SliverToBoxAdapter(
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = category == _selectedCategory;
            
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedCategory = category);
                  _loadPosts();
                },
                backgroundColor: Colors.grey.shade100,
                selectedColor: Colors.purple.shade400,
                checkmarkColor: Colors.white,
                elevation: isSelected ? 4 : 1,
                pressElevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPostsGrid() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
          ),
        ),
      );
    }

    if (_posts.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_outlined,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No glimmers found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Be the first to share something beautiful!',
                style: TextStyle(
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(context),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return _buildPostCard(_posts[index]);
          },
          childCount: _posts.length,
        ),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 5;
    if (width > 800) return 4;
    if (width > 600) return 3;
    return 2;
  }

  Widget _buildPostCard(GlimmerPost post) {
    return Hero(
      tag: 'post_${post.id}',
      child: GestureDetector(
        onTap: () => _openPostDetail(post),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Image.network(
                  post.imageUrl,
                  width: double.infinity,
                  height: _getRandomHeight(),
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: _getRandomHeight(),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey.shade200,
                            Colors.grey.shade100,
                            Colors.grey.shade200,
                          ],
                        ),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: _getRandomHeight(),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey.shade300,
                            Colors.grey.shade200,
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    if (post.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        post.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    const SizedBox(height: 8),
                    
                    // User info and stats
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.purple.shade100,
                          backgroundImage: post.userAvatarUrl != null
                              ? NetworkImage(post.userAvatarUrl!)
                              : null,
                          child: post.userAvatarUrl == null
                              ? Text(
                                  post.username[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            post.username,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        // Like button
                        IconButton(
                          onPressed: () => _toggleLike(post),
                          icon: Icon(
                            Icons.favorite,
                            size: 18,
                            color: post.isLikedByUser 
                                ? Colors.red 
                                : Colors.grey.shade400,
                          ),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                        Text(
                          post.likesCount.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
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
      ),
    );
  }

  double _getRandomHeight() {
    final heights = [180.0, 220.0, 260.0, 200.0, 240.0];
    return heights[math.Random().nextInt(heights.length)];
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabAnimation.value,
          child: FloatingActionButton.extended(
            onPressed: _showUploadDialog,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Add Glimmer'),
            backgroundColor: Colors.purple.shade400,
            foregroundColor: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        );
      },
    );
  }

  void _showUploadDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => GlimmerUploadSheet(
        currentUserId: 'user123', // Replace with actual user ID
        categories: _categories,
        onUploadComplete: () {
          Navigator.pop(context);
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Glimmer shared successfully! ✨'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Refresh the posts here
          setState(() {
            _loadPosts(); // Reload posts from database
          });
        },
      ),
    );
  }

  void _openPostDetail(GlimmerPost post) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    post.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                post.description,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.favorite, color: Colors.red),
                  const SizedBox(width: 4),
                  Text('${post.likesCount}'),
                  const SizedBox(width: 16),
                  Icon(Icons.comment, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text('${post.commentsCount}'),
                  const Spacer(),
                  Text(
                    'by ${post.username}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleLike(GlimmerPost post) async {
    try {
      final newLikeStatus = await _glimmerService.toggleLike(
        postId: post.id,
        userId: widget.currentUserId,
        currentlyLiked: post.isLikedByUser,
      );

      setState(() {
        post.isLikedByUser = newLikeStatus;
        post.likesCount += newLikeStatus ? 1 : -1;
      });

      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Error toggling like: $e');
      _showErrorSnackBar('Failed to update like');
    }
  }
}

/// Data model for Glimmer posts
class GlimmerPost {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String category;
  final String userId;
  final String username;
  final String? userAvatarUrl;
  final DateTime createdAt;
  int likesCount;
  final int commentsCount;
  final List<String> tags;
  bool isLikedByUser;

  GlimmerPost({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.userId,
    required this.username,
    this.userAvatarUrl,
    required this.createdAt,
    required this.likesCount,
    required this.commentsCount,
    required this.tags,
    this.isLikedByUser = false,
  });

  factory GlimmerPost.fromJson(Map<String, dynamic> json) {
    return GlimmerPost(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      category: json['category'] ?? 'Art',
      userId: json['user_id'] ?? '',
      username: json['username'] ?? 'Unknown',
      userAvatarUrl: json['avatar_url']?.isNotEmpty == true ? json['avatar_url'] : null,
      createdAt: DateTime.parse(json['created_at']),
      likesCount: (json['likes_count'] ?? 0).toInt(),
      commentsCount: (json['comments_count'] ?? 0).toInt(),
      tags: List<String>.from(json['tags'] ?? []),
      isLikedByUser: json['is_liked_by_user'] ?? false,
    );
  }
}
