import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Data models for user info categories
class InfoCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;
  bool isExpanded;

  InfoCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    this.isExpanded = false,
  });
}

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late Future<Map<String, dynamic>> userData;
  final TextEditingController _freeWritingController = TextEditingController();
  final TextEditingController _categoryItemController = TextEditingController();
  
  // Animation controllers
  late AnimationController _headerAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<Offset> _contentSlideAnimation;
  
  // Categories data
  List<InfoCategory> _categories = [];
  bool _isEditingFreeText = false;
  String _freeTextContent = '';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    userData = _fetchUserData();
    _loadUserInfo();
  }
  
  void _setupAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutBack,
    ));
    
    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _contentAnimationController.forward();
    });
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    final response = await supabase
        .from('users')
        .select('id, username, avatarUrl, avatar_decoration, bio')
        .eq('id', widget.userId)
        .single();
    return response;
  }
  
  Future<void> _loadUserInfo() async {
    try {
      // Load categories and free text from user_info table
      final response = await supabase
          .from('user_info')
          .select('category, content, info_type')
          .eq('user_id', widget.userId);
      
      // Initialize default categories
      _categories = [
        InfoCategory(
          title: 'Personal Info',
          icon: Icons.person,
          color: Colors.blue,
          items: [],
        ),
        InfoCategory(
          title: 'Interests & Hobbies',
          icon: Icons.favorite,
          color: Colors.pink,
          items: [],
        ),
        InfoCategory(
          title: 'Skills & Talents',
          icon: Icons.star,
          color: Colors.amber,
          items: [],
        ),
        InfoCategory(
          title: 'Goals & Dreams',
          icon: Icons.rocket_launch,
          color: Colors.purple,
          items: [],
        ),
        InfoCategory(
          title: 'Favorites',
          icon: Icons.thumb_up,
          color: Colors.green,
          items: [],
        ),
        InfoCategory(
          title: 'Life Experiences',
          icon: Icons.explore,
          color: Colors.orange,
          items: [],
        ),
      ];
      
      // Populate categories with saved data
      for (var item in response) {
        if (item['info_type'] == 'category') {
          final categoryIndex = _categories.indexWhere(
            (cat) => cat.title == item['category']
          );
          if (categoryIndex >= 0) {
            _categories[categoryIndex].items.add(item['content']);
          }
        } else if (item['info_type'] == 'free_text') {
          _freeTextContent = item['content'] ?? '';
          _freeWritingController.text = _freeTextContent;
        }
      }
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading user info: $e');
    }
  }

  @override
  void dispose() {
    _freeWritingController.dispose();
    _categoryItemController.dispose();
    _headerAnimationController.dispose();
    _contentAnimationController.dispose();
    super.dispose();
  }

  Future<void> _addCategoryItem(String category, String content) async {
    try {
      await supabase.from('user_info').insert([
        {
          'user_id': widget.userId,
          'category': category,
          'content': content,
          'info_type': 'category',
          'timestamp': DateTime.now().toIso8601String()
        },
      ]);
      
      // Update local state
      final categoryIndex = _categories.indexWhere((cat) => cat.title == category);
      if (categoryIndex >= 0) {
        setState(() {
          _categories[categoryIndex].items.add(content);
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added successfully!')),
        );
      }
    } catch (error) {
      debugPrint('Error adding category item: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding item: $error')),
        );
      }
    }
  }
  
  Future<void> _saveFreeText() async {
    try {
      // First, delete existing free text entry
      await supabase
          .from('user_info')
          .delete()
          .eq('user_id', widget.userId)
          .eq('info_type', 'free_text');
      
      // Then insert new content if not empty
      if (_freeWritingController.text.isNotEmpty) {
        await supabase.from('user_info').insert([
          {
            'user_id': widget.userId,
            'content': _freeWritingController.text,
            'info_type': 'free_text',
            'timestamp': DateTime.now().toIso8601String()
          },
        ]);
      }
      
      setState(() {
        _freeTextContent = _freeWritingController.text;
        _isEditingFreeText = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Free text saved successfully!')),
        );
      }
    } catch (error) {
      debugPrint('Error saving free text: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving text: $error')),
        );
      }
    }
  }
  
  void _showAddItemDialog(InfoCategory category) {
    _categoryItemController.clear();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                category.color.withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(category.icon, color: category.color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add to ${category.title}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _categoryItemController,
                autofocus: true,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter your ${category.title.toLowerCase()}...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (_categoryItemController.text.isNotEmpty) {
                        _addCategoryItem(category.title, _categoryItemController.text);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: category.color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: userData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.purple.shade100,
                    Colors.blue.shade50,
                  ],
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Loading user profile...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.purple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
                    const SizedBox(height: 20),
                    Text('Error: ${snapshot.error}'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => setState(() => userData = _fetchUserData()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          
          if (!snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(title: const Text('Not Found')),
              body: const Center(child: Text('User not found.')),
            );
          }

          var user = snapshot.data!;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.purple.shade100,
                  Colors.blue.shade50,
                  Colors.white,
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
            child: CustomScrollView(
              slivers: [
                // Custom App Bar with User Header
                SliverAppBar(
                  expandedHeight: 280,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: AnimatedBuilder(
                      animation: _headerAnimation,
                      child: _buildUserHeader(user),
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _headerAnimation.value,
                          child: Opacity(
                            opacity: _headerAnimation.value,
                            child: child,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                // Main Content
                SliverToBoxAdapter(
                  child: SlideTransition(
                    position: _contentSlideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Categories Section
                          _buildCategoriesSection(),
                          const SizedBox(height: 24),
                          
                          // Free Writing Section
                          _buildFreeWritingSection(),
                          const SizedBox(height: 100), // Bottom padding for FAB
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildUserHeader(Map<String, dynamic> user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Column(
        children: [
          // Avatar with decoration
          Stack(
            children: [
              // Main avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 55,
                    backgroundImage: user['avatarUrl'] != null && user['avatarUrl'].isNotEmpty
                        ? NetworkImage(user['avatarUrl'])
                        : null,
                    child: user['avatarUrl'] == null || user['avatarUrl'].isEmpty
                        ? Icon(Icons.person, size: 60, color: Colors.grey.shade400)
                        : null,
                  ),
                ),
              ),
              
              // Avatar decoration overlay
              if (user['avatar_decoration'] != null && user['avatar_decoration'].isNotEmpty)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amber,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _getDecorationIcon(user['avatar_decoration']),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Username
          Text(
            user['username'] ?? 'No Name',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: Offset(0, 2),
                  blurRadius: 4,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Bio
          if (user['bio'] != null && user['bio'].isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                user['bio'],
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
  
  IconData _getDecorationIcon(String decoration) {
    switch (decoration.toLowerCase()) {
      case 'crown':
        return Icons.diamond;
      case 'star':
        return Icons.star;
      case 'heart':
        return Icons.favorite;
      case 'diamond':
        return Icons.diamond;
      default:
        return Icons.auto_awesome;
    }
  }
  
  Widget _buildCategoriesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.blue.shade400],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Row(
              children: [
                Icon(Icons.category, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'Information Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Categories list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categories.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey.shade200,
            ),
            itemBuilder: (context, index) {
              final category = _categories[index];
              return _buildCategoryItem(category);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryItem(InfoCategory category) {
    return Container(
      decoration: BoxDecoration(
        color: category.isExpanded 
          ? category.color.withOpacity(0.05)
          : Colors.transparent,
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(category.icon, color: category.color, size: 20),
            ),
            title: Text(
              category.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('${category.items.length} items'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _showAddItemDialog(category),
                  icon: Icon(Icons.add, color: category.color),
                  style: IconButton.styleFrom(
                    backgroundColor: category.color.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  category.isExpanded 
                    ? Icons.keyboard_arrow_up 
                    : Icons.keyboard_arrow_down,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
            onTap: () {
              setState(() {
                category.isExpanded = !category.isExpanded;
              });
            },
          ),
          
          // Expanded content
          if (category.isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: category.items.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          category.icon,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No items in ${category.title} yet',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _showAddItemDialog(category),
                          icon: const Icon(Icons.add),
                          label: const Text('Add First Item'),
                          style: TextButton.styleFrom(
                            foregroundColor: category.color,
                          ),
                        ),
                      ],
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: category.items
                        .map((item) => _buildCategoryTag(item, category.color))
                        .toList(),
                  ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color.withOpacity(0.8),
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }
  
  Widget _buildFreeWritingSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade400, Colors.green.shade400],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.edit_note, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Free Writing Space',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isEditingFreeText = !_isEditingFreeText;
                    });
                  },
                  icon: Icon(
                    _isEditingFreeText ? Icons.visibility : Icons.edit,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(20),
            child: _isEditingFreeText
                ? Column(
                    children: [
                      TextField(
                        controller: _freeWritingController,
                        maxLines: 8,
                        decoration: InputDecoration(
                          hintText: 'Write anything you want to share about yourself...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              _freeWritingController.text = _freeTextContent;
                              setState(() {
                                _isEditingFreeText = false;
                              });
                            },
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _saveFreeText,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  )
                : _freeTextContent.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.edit_note,
                              size: 60,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Share your thoughts, experiences, or anything else you\'d like others to know about you.',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isEditingFreeText = true;
                                });
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Start Writing'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _freeTextContent,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
