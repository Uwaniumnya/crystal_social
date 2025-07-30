import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Enhanced Sticker Picker widget with categories, search, animations, and GIF support
class StickerPicker extends StatefulWidget {
  final Function(String) onStickerSelected;

  const StickerPicker({super.key, required this.onStickerSelected});

  @override
  State<StickerPicker> createState() => _StickerPickerState();
}

class _StickerPickerState extends State<StickerPicker>
    with TickerProviderStateMixin {
  // Animation controllers
  late TabController _tabController;
  late AnimationController _uploadController;
  late Animation<double> _uploadAnimation;

  // State variables
  bool _isLoading = false;
  bool _isUploading = false;
  String _searchQuery = '';

  // Sticker categories with GIF support
  final Map<String, List<Map<String, dynamic>>> _stickerCategories = {
    'Emotions': [
      {
        'url': 'https://ttvgpvtgtymgzzqtkrmn.supabase.co/storage/v1/object/public/stickers//image.jpg',
        'isGif': false,
        'name': 'happy_face'
      },
      {
        'url': 'https://ttvgpvtgtymgzzqtkrmn.supabase.co/storage/v1/object/public/stickers//IMG_3443.png',
        'isGif': false,
        'name': 'love_eyes'
      },
    ],
    'Animals': [
      {
        'url': 'https://ttvgpvtgtymgzzqtkrmn.supabase.co/storage/v1/object/public/stickers//IMG_3444.png',
        'isGif': false,
        'name': 'cute_cat'
      },
      {
        'url': 'https://ttvgpvtgtymgzzqtkrmn.supabase.co/storage/v1/object/public/stickers//IMG_3455.png',
        'isGif': false,
        'name': 'dog_wag'
      },
    ],
    'Nature': [
      {
        'url': 'https://ttvgpvtgtymgzzqtkrmn.supabase.co/storage/v1/object/public/stickers//IMG_3456.png',
        'isGif': false,
        'name': 'flower_bloom'
      },
      {
        'url': 'https://ttvgpvtgtymgzzqtkrmn.supabase.co/storage/v1/object/public/stickers//IMG_3466.png',
        'isGif': false,
        'name': 'tree_sway'
      },
    ],
  };

  // User stickers organized by category with metadata
  Map<String, List<Map<String, dynamic>>> _userStickers = {};
  List<Map<String, dynamic>> _recentStickers = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _uploadController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _uploadAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _uploadController,
      curve: Curves.elasticOut,
    ));

    _fetchUserStickers();
    _loadRecentStickers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _uploadController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Enhanced fetch user stickers with categories and metadata
  Future<void> _fetchUserStickers() async {
    setState(() => _isLoading = true);
    
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('stickers')
          .select('sticker_url, category, is_gif, sticker_name, file_size, created_at')
          .eq('user_id', userId);

      if (response.isNotEmpty) {
        final Map<String, List<Map<String, dynamic>>> categorizedStickers = {};
        
        for (final sticker in response) {
          final category = sticker['category'] as String? ?? 'Other';
          final stickerData = {
            'url': sticker['sticker_url'] as String,
            'isGif': sticker['is_gif'] as bool? ?? false,
            'name': sticker['sticker_name'] as String? ?? 'Unknown',
            'fileSize': sticker['file_size'] as int? ?? 0,
            'createdAt': sticker['created_at'] as String?,
          };
          
          categorizedStickers.putIfAbsent(category, () => []);
          categorizedStickers[category]!.add(stickerData);
        }

        setState(() {
          _userStickers = categorizedStickers;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error fetching stickers: $e');
    }
  }

  // Load recently used stickers with metadata
  Future<void> _loadRecentStickers() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('recent_stickers')
          .select('''
            sticker_url,
            used_at,
            stickers!inner(
              is_gif,
              sticker_name,
              category
            )
          ''')
          .eq('user_id', userId)
          .order('used_at', ascending: false)
          .limit(20);

      if (response.isNotEmpty) {
        setState(() {
          _recentStickers = response.map<Map<String, dynamic>>((e) => {
            'url': e['sticker_url'] as String,
            'isGif': e['stickers']['is_gif'] as bool? ?? false,
            'name': e['stickers']['sticker_name'] as String? ?? 'Unknown',
            'category': e['stickers']['category'] as String? ?? 'Other',
            'usedAt': e['used_at'] as String,
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading recent stickers: $e');
    }
  }

  // Save sticker to recent list with enhanced metadata
  Future<void> _saveToRecent(String stickerUrl) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client.from('recent_stickers').upsert({
        'user_id': userId,
        'sticker_url': stickerUrl,
        'used_at': DateTime.now().toIso8601String(),
      });

      // Update local recent list
      final existingIndex = _recentStickers.indexWhere((s) => s['url'] == stickerUrl);
      if (existingIndex != -1) {
        final existing = _recentStickers.removeAt(existingIndex);
        _recentStickers.insert(0, existing);
      }
      
      if (_recentStickers.length > 20) {
        _recentStickers = _recentStickers.take(20).toList();
      }
      
      setState(() {});
    } catch (e) {
      debugPrint('Error saving to recent: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRecentTab(),
                _buildCategoryTab('Emotions'),
                _buildCategoryTab('Animals'),
                _buildUserStickersTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildUploadFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Sticker Gallery',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.pinkAccent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _fetchUserStickers,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search stickers...',
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade400),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
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
          setState(() => _searchQuery = value.toLowerCase());
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.pinkAccent,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.pinkAccent,
        indicatorWeight: 3,
        tabs: const [
          Tab(icon: Icon(Icons.access_time), text: 'Recent'),
          Tab(icon: Icon(Icons.emoji_emotions), text: 'Emotions'),
          Tab(icon: Icon(Icons.pets), text: 'Animals'),
          Tab(icon: Icon(Icons.person), text: 'My Stickers'),
        ],
      ),
    );
  }

  Widget _buildRecentTab() {
    if (_recentStickers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No Recent Stickers',
        subtitle: 'Your recently used stickers will appear here',
      );
    }

    return _buildStickerGrid(_recentStickers);
  }

  Widget _buildCategoryTab(String category) {
    final stickers = _stickerCategories[category] ?? [];
    
    if (stickers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.category,
        title: 'No $category Stickers',
        subtitle: 'Coming soon!',
      );
    }

    return _buildStickerGrid(stickers);
  }

  Widget _buildUserStickersTab() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.pinkAccent),
            SizedBox(height: 16),
            Text('Loading your stickers...'),
          ],
        ),
      );
    }

    final allUserStickers = _userStickers.values
        .expand((list) => list)
        .toList();

    if (allUserStickers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.add_photo_alternate,
        title: 'No Personal Stickers',
        subtitle: 'Tap the + button to upload your own stickers and GIFs!',
      );
    }

    return _buildStickerGrid(allUserStickers);
  }

  Widget _buildStickerGrid(List<Map<String, dynamic>> stickers) {
    final filteredStickers = _searchQuery.isEmpty
        ? stickers
        : stickers.where((sticker) =>
            sticker['name']?.toString().toLowerCase().contains(_searchQuery) == true ||
            sticker['url']?.toString().toLowerCase().contains(_searchQuery) == true).toList();

    if (filteredStickers.isEmpty && _searchQuery.isNotEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        title: 'No Results',
        subtitle: 'Try a different search term',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: filteredStickers.length,
        itemBuilder: (context, index) {
          return _buildStickerCard(filteredStickers[index], index);
        },
      ),
    );
  }

  Widget _buildStickerCard(Map<String, dynamic> stickerData, int index) {
    final stickerUrl = stickerData['url'] as String;
    final isGif = stickerData['isGif'] as bool? ?? false;
    final stickerName = stickerData['name'] as String? ?? 'Unknown';

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: GestureDetector(
            onTap: () => _onStickerTap(stickerUrl),
            onLongPress: () => _showStickerOptions(stickerUrl, stickerName, isGif),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: isGif ? Border.all(
                  color: Colors.orange,
                  width: 2,
                ) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: stickerUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => Container(
                        height: 80,
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.pinkAccent,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 80,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  // GIF indicator
                  if (isGif)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'GIF',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadFAB() {
    return ScaleTransition(
      scale: _uploadAnimation,
      child: FloatingActionButton(
        onPressed: _isUploading ? null : () => _showUploadOptions(),
        backgroundColor: Colors.pinkAccent,
        child: _isUploading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _onStickerTap(String stickerUrl) {
    HapticFeedback.lightImpact();
    _saveToRecent(stickerUrl);
    widget.onStickerSelected(stickerUrl);
    Navigator.pop(context);
  }

  void _showStickerOptions(String stickerUrl, String stickerName, bool isGif) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  stickerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isGif) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'GIF',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.send, color: Colors.pinkAccent),
              title: const Text('Send Sticker'),
              onTap: () {
                Navigator.pop(context);
                _onStickerTap(stickerUrl);
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite_border, color: Colors.red),
              title: const Text('Add to Favorites'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement favorites functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: const Text('Share Sticker'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement share functionality
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Upload Sticker or GIF',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('From Gallery'),
              subtitle: const Text('Support for images and GIFs'),
              onTap: () {
                Navigator.pop(context);
                _pickSticker(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Take Photo'),
              subtitle: const Text('Capture a new image'),
              onTap: () {
                Navigator.pop(context);
                _pickSticker(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Enhanced method to pick and upload custom stickers with GIF support
  Future<void> _pickSticker(ImageSource source) async {
    setState(() => _isUploading = true);
    _uploadController.forward();

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final fileExtension = pickedFile.path.split('.').last.toLowerCase();
        final isGif = fileExtension == 'gif';
        final fileName = 'sticker_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
        final uploadPath = 'user_stickers/$fileName';

        // Upload to Supabase storage
        final storageResponse = await Supabase.instance.client.storage
            .from('stickers')
            .uploadBinary(uploadPath, bytes);

        if (storageResponse.isNotEmpty) {
          // Get public URL for the uploaded sticker
          final publicUrl = Supabase.instance.client.storage
              .from('stickers')
              .getPublicUrl(uploadPath);

          // Show category selection dialog
          final selectedCategory = await _showCategoryDialog();
          final stickerName = await _showNameDialog();

          // Insert metadata into database with enhanced fields
          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (userId != null) {
            await Supabase.instance.client.from('stickers').insert({
              'user_id': userId,
              'sticker_url': publicUrl,
              'category': selectedCategory ?? 'Other',
              'is_gif': isGif,
              'sticker_name': stickerName ?? 'My Sticker',
              'file_size': bytes.length,
              'file_type': fileExtension,
              'created_at': DateTime.now().toIso8601String(),
            });

            // Update local state
            setState(() {
              _userStickers.putIfAbsent(selectedCategory ?? 'Other', () => []);
              _userStickers[selectedCategory ?? 'Other']!.add({
                'url': publicUrl,
                'isGif': isGif,
                'name': stickerName ?? 'My Sticker',
                'fileSize': bytes.length,
                'createdAt': DateTime.now().toIso8601String(),
              });
            });

            _showSuccessSnackBar(isGif 
                ? 'GIF uploaded successfully! 🎉' 
                : 'Sticker uploaded successfully! ✨');
            
            // Auto-select the uploaded sticker
            _onStickerTap(publicUrl);
          }
        } else {
          _showErrorSnackBar('Failed to upload ${isGif ? "GIF" : "sticker"}');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error uploading: $e');
    } finally {
      setState(() => _isUploading = false);
      _uploadController.reverse();
    }
  }

  // Category selection dialog
  Future<String?> _showCategoryDialog() async {
    final categories = ['Emotions', 'Animals', 'Nature', 'Funny', 'Reactions', 'Other'];
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Choose Category',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: categories.map((category) => 
            ListTile(
              leading: Icon(_getCategoryIcon(category), color: Colors.pinkAccent),
              title: Text(category),
              onTap: () => Navigator.pop(context, category),
            ),
          ).toList(),
        ),
      ),
    );
  }

  // Name input dialog
  Future<String?> _showNameDialog() async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name Your Sticker'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter sticker name...',
            border: OutlineInputBorder(),
          ),
          maxLength: 30,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Emotions':
        return Icons.emoji_emotions;
      case 'Animals':
        return Icons.pets;
      case 'Nature':
        return Icons.nature;
      case 'Funny':
        return Icons.sentiment_very_satisfied;
      case 'Reactions':
        return Icons.psychology;
      default:
        return Icons.category;
    }
  }
}

// Enhanced StickerButton widget that opens the sticker picker
class StickerButton extends StatefulWidget {
  final String currentUser;
  final String chatId;

  const StickerButton({
    required this.currentUser,
    required this.chatId,
    super.key,
  });

  @override
  State<StickerButton> createState() => _StickerButtonState();
}

class _StickerButtonState extends State<StickerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _sendSticker(String stickerUrl) async {
    try {
      await Supabase.instance.client.from('messages').insert({
        'chat_id': widget.chatId,
        'sender_id': widget.currentUser,
        'message': stickerUrl,
        'type': 'sticker',
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Show success feedback
      HapticFeedback.lightImpact();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sticker sent! 🎉'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send sticker: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _animationController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _animationController.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _animationController.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isPressed 
                ? Colors.pinkAccent.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.emoji_emotions_outlined,
              color: Colors.pinkAccent,
              size: 24,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      StickerPicker(
                    onStickerSelected: (stickerUrl) {
                      _sendSticker(stickerUrl);
                    },
                  ),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    const begin = Offset(0.0, 1.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOutCubic;

                    var tween = Tween(begin: begin, end: end)
                        .chain(CurveTween(curve: curve));

                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
            tooltip: 'Send Sticker',
          ),
        ),
      ),
    );
  }
}
