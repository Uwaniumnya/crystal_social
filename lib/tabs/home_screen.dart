import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../chat/chat_list_screen.dart';
import '../groups/group_list_screen.dart';
import '../profile/enhanced_profile_screen.dart';
import '../tabs/glitter_board.dart';
import '../tabs/glimmer_wall_screen.dart';
import '../tabs/settings_screen.dart';
import '../userinfo/user_profile_screen.dart';
import '../pets/pet_details_screen.dart';
import '../pets/pet_care_screen.dart';
import '../butterfly/butterfly_garden_screen.dart';
import '../garden/crystal_garden.dart';
import '../rewards/shop_screen.dart';
import '../rewards/unified_rewards_screen.dart';
import '../rewards/inventory_screen.dart';
import '../rewards/currency_earning_screen.dart';
import '../rewards/reward_archivement.dart';
import '../rewards/booster.dart';
import '../rewards/bestie_bond.dart';
import '../notes/screens/notes_home_screen.dart';
import '../tabs/cursed_poll_screen.dart';
import '../tabs/enhanced_horoscope.dart';
import '../tabs/tarot_reading.dart';
import '../tabs/oracle.dart';
import '../admin/admin_access.dart';
import '../tabs/8ball.dart';
import '../tabs/front.dart';
import '../userinfo/user_list.dart';
import '../tabs/information.dart';
import '../tabs/confession.dart';

// Data model for app items
class AppItem {
  final String title;
  final String subtitle;
  final String iconPath;
  final Color color;
  final bool isNew;
  final bool isPremium;
  final int notificationCount;
  final VoidCallback onTap;

  const AppItem({
    required this.title,
    required this.subtitle,
    required this.iconPath,
    required this.color,
    this.isNew = false,
    this.isPremium = false,
    this.notificationCount = 0,
    required this.onTap,
  });
}

// Data model for categories
class AppCategory {
  final String title;
  final String subtitle;
  final String iconPath;
  final Color color;
  final List<AppItem> items;

  const AppCategory({
    required this.title,
    required this.subtitle,
    required this.iconPath,
    required this.color,
    required this.items,
  });
}

class HomeScreen extends StatefulWidget {
  final String currentUserId;

  const HomeScreen({super.key, required this.currentUserId});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String? _username;
  String? _avatarUrl;
  bool _loading = true;
  
  // Animation controllers for enhanced UI
  late AnimationController _backgroundController;
  late AnimationController _cardController;
  late AnimationController _headerController;
  late AnimationController _fabController;
  
  // Animations
  late Animation<double> _backgroundAnimation;
  late Animation<double> _cardAnimation;
  late Animation<Offset> _headerAnimation;
  late Animation<double> _fabAnimation;
  
  // UI state
  bool _showQuickActions = false;
  String _currentGreeting = '';
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fetchProfileData();
    _updateGreeting();
  }
  
  void _setupAnimations() {
    // Background gradient animation
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));
    
    // Card entrance animation
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _cardAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.elasticOut,
    ));
    
    // Header slide animation
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _headerAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutBack,
    ));
    
    // FAB animation
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    ));
    
    // Start animations
    _backgroundController.repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 300), () {
      _headerController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      _cardController.forward();
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      _fabController.forward();
    });
  }
  
  void _updateGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _currentGreeting = 'Good Morning';
    } else if (hour < 17) {
      _currentGreeting = 'Good Afternoon';
    } else {
      _currentGreeting = 'Good Evening';
    }
  }
  
  @override
  void dispose() {
    _backgroundController.dispose();
    _cardController.dispose();
    _headerController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileData() async {
    final data = await Supabase.instance.client
        .from('users')
        .select(
            'username, avatarUrl, avatar_decoration') // Fetch decoration as well
        .eq('id', widget.currentUserId)
        .maybeSingle();

    setState(() {
      _username = data?['username'] ?? widget.currentUserId;
      _avatarUrl = data?['avatarUrl'];
      _loading = false;
    });
  }

  Widget _buildPlaceholderScreen(String title) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Coming Soon!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.shade100,
                Colors.pink.shade100,
                Colors.blue.shade100,
              ],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 20),
                Text(
                  'Loading your Crystal experience...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(Colors.purple.shade200, Colors.indigo.shade300, _backgroundAnimation.value)!,
                  Color.lerp(Colors.pink.shade200, Colors.purple.shade300, _backgroundAnimation.value)!,
                  Color.lerp(Colors.blue.shade200, Colors.teal.shade300, _backgroundAnimation.value)!,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Enchanted Header
                  SlideTransition(
                    position: _headerAnimation,
                    child: _buildEnchantedHeader(context),
                  ),
                  
                  // Quick Stats Bar
                  _buildQuickStatsBar(),
                  
                  // Category Selector
                  _buildCategorySelector(),
                  
                  // Main Content
                  Expanded(
                    child: _buildMainContent(context),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: _showQuickActions 
        ? _buildQuickActionsFAB()
        : ScaleTransition(
            scale: _fabAnimation,
            child: FloatingActionButton.extended(
              onPressed: () => _toggleQuickActions(),
              backgroundColor: Colors.white.withValues(alpha: 0.9),
              foregroundColor: Colors.purple.shade700,
              label: const Text('Quick Actions'),
              icon: const Icon(Icons.rocket_launch),
            ),
          ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
  
  Widget _buildEnchantedHeader(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        // Secret admin access via long press on header
        if (kDebugMode) {
          HapticFeedback.heavyImpact();
          AdminAccessBottomSheet.show(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20.0),
        margin: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with glow effect
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 32,
                backgroundImage: _avatarUrl != null 
                  ? NetworkImage(_avatarUrl!) 
                  : null,
                child: _avatarUrl == null 
                  ? Icon(Icons.person, size: 35, color: Colors.grey.shade400)
                  : null,
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Welcome text with shimmer effect
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentGreeting,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.white.withValues(alpha: 0.8),
                      Colors.white,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    _username ?? 'Crystal User',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Welcome to your Crystal world ✨',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          
          // Settings button
          IconButton(
            onPressed: () => _showSettingsMenu(context),
            icon: const Icon(Icons.settings, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
  
  Widget _buildQuickStatsBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.chat_bubble_outline, 'Messages', '42'),
          _buildStatItem(Icons.group_outlined, 'Groups', '7'),
          _buildStatItem(Icons.games_outlined, 'Games', '156'),
          _buildStatItem(Icons.star_outline, 'Level', '24'),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildCategorySelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _getCategories().length + 1, // +1 for "All" option
        itemBuilder: (context, index) {
        if (index == 0) {
          return _buildCategoryChip(
            'All',
            'assets/icons/AppIconsCrystalAPp.png',
            _selectedCategory == 'all',
            () => setState(() => _selectedCategory = 'all'),
          );
        }          final category = _getCategories()[index - 1];
          final isSelected = _selectedCategory == category.title.toLowerCase();
          
          return _buildCategoryChip(
            category.title,
            category.iconPath,
            isSelected,
            () => setState(() => _selectedCategory = category.title.toLowerCase()),
          );
        },
      ),
    );
  }
  
  Widget _buildCategoryChip(String title, String iconPath, bool isSelected, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected 
                ? Colors.white.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                iconPath,
                width: 18,
                height: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMainContent(BuildContext context) {
    final items = _getFilteredItems();
    
    return Container(
      margin: const EdgeInsets.all(16.0),
      child: AnimatedBuilder(
        animation: _cardAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _cardAnimation.value,
            child: LayoutBuilder(
              builder: (context, constraints) {
                int columns = constraints.maxWidth > 600 ? 3 : 2;
                
                return GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildEnchantedCard(context, item, index);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildEnchantedCard(BuildContext context, AppItem item, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _navigateToScreen(context, item);
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.2),
                      Colors.white.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: item.isPremium 
                      ? Colors.amber.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.3),
                    width: item.isPremium ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Premium indicator
                    if (item.isPremium)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    
                    // Notification badge
                    if (item.notificationCount > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.notificationCount > 99 ? '99+' : '${item.notificationCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    
                    // Main content
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon with glow effect
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.2),
                            boxShadow: [
                              BoxShadow(
                                color: item.color.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            item.iconPath,
                            width: 32,
                            height: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Title
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        
                        // Subtitle
                        Text(
                          item.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        // Badge if new
                        if (item.isNew) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  // Helper methods
  void _toggleQuickActions() {
    setState(() {
      _showQuickActions = !_showQuickActions;
    });
  }
  
  Widget _buildQuickActionsFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Admin Dashboard Quick Access (only show in debug mode)
        if (kDebugMode) ...[
          FloatingActionButton(
            heroTag: "admin",
            onPressed: () => AdminAccessBottomSheet.show(context),
            backgroundColor: Colors.purple.withValues(alpha: 0.9),
            foregroundColor: Colors.white,
            child: const Icon(Icons.admin_panel_settings),
          ),
          const SizedBox(height: 12),
        ],
        
        // Quick action buttons
        FloatingActionButton(
          heroTag: "search",
          onPressed: () => _showSearchDialog(),
          backgroundColor: Colors.blue.withValues(alpha: 0.9),
          foregroundColor: Colors.white,
          child: const Icon(Icons.search),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: "notifications",
          onPressed: () {
            // Implement notifications
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications feature coming soon!')),
            );
          },
          backgroundColor: Colors.orange.withValues(alpha: 0.9),
          foregroundColor: Colors.white,
          child: const Icon(Icons.notifications),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: "add",
          onPressed: () {
            // Implement add content
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add content feature coming soon!')),
            );
          },
          backgroundColor: Colors.green.withValues(alpha: 0.9),
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 16),
        // Main FAB to close
        FloatingActionButton.extended(
          heroTag: "main",
          onPressed: () => _toggleQuickActions(),
          backgroundColor: Colors.red.withValues(alpha: 0.9),
          foregroundColor: Colors.white,
          label: const Text('Close'),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
  
  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
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
              'Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Dark Mode'),
              trailing: Switch(
                value: false,
                onChanged: (value) {},
              ),
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
              ),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help & Support'),
              onTap: () => Navigator.pop(context),
            ),
            
            // Admin Access (only in debug mode)
            if (kDebugMode) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Colors.purple),
                title: const Text('Admin Dashboard', style: TextStyle(color: Colors.purple)),
                onTap: () {
                  Navigator.pop(context);
                  AdminAccessBottomSheet.show(context);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Search Crystal Social',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search for features, friends, content...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                onSubmitted: (value) {
                  Navigator.pop(context);
                  // Implement search logic here
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Searching for: $value')),
                  );
                },
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper methods for categories and filtering
  List<AppCategory> _getCategories() {
    return [
      AppCategory(
        title: 'Social',
        subtitle: 'Connect with friends',
        iconPath: 'assets/icons/social.png',
        color: Colors.blue,
        items: [
          AppItem(
            title: 'Chats',
            subtitle: 'Message your friends',
            iconPath: 'assets/icons/chat.png',
            color: Colors.blue,
            notificationCount: 3,
            onTap: () => _navigateToChat(),
          ),
          AppItem(
            title: 'Groups',
            subtitle: 'Join conversations',
            iconPath: 'assets/icons/group.png',
            color: Colors.green,
            notificationCount: 7,
            onTap: () => _navigateToGroups(),
          ),
          AppItem(
            title: 'Profile',
            subtitle: 'Your Crystal identity',
            iconPath: 'assets/icons/profile.png',
            color: Colors.purple,
            onTap: () => _navigateToProfile(),
          ),
          AppItem(
            title: 'Alter Profiles',
            subtitle: 'Browse user info',
            iconPath: 'assets/icons/alter_profiles.png',
            color: Colors.indigo,
            onTap: () => _navigateToUserProfile(),
          ),
          AppItem(
            title: 'Glitter Board',
            subtitle: 'Share your moments',
            iconPath: 'assets/icons/glitterboard.png',
            color: Colors.pink,
            onTap: () => _navigateToGlitterBoard(),
          ),
          AppItem(
            title: 'Glimmer Wall',
            subtitle: 'Pinterest-style image board',
            iconPath: 'assets/icons/glimmer_wall.png',
            color: Colors.purple,
            isNew: true,
            onTap: () => _navigateToGlimmerWall(),
          ),
          AppItem(
            title: 'Cursed Polls',
            subtitle: 'Vote on mystical questions',
            iconPath: 'assets/icons/cursed_polls.png',
            color: Colors.deepPurple,
            isNew: true,
            onTap: () => _navigateToCursedPoll(),
          ),
          AppItem(
            title: 'Confessions',
            subtitle: 'Share your secrets',
            iconPath: 'assets/icons/confessions.png',
            color: Colors.purple,
            onTap: () => _navigateToConfessions(),
          ),
        ],
      ),
      AppCategory(
        title: 'Lifestyle',
        subtitle: 'Personal tools',
        iconPath: 'assets/icons/lifestyle.png',
        color: Colors.teal,
        items: [
          AppItem(
            title: 'Crystal Notes',
            subtitle: 'Write and organize',
            iconPath: 'assets/icons/notes.png',
            color: Colors.amber,
            onTap: () => _navigateToNotes(),
          ),
          AppItem(
            title: 'Music Player',
            subtitle: 'Listen to music',
            iconPath: 'assets/icons/music.png',
            color: Colors.indigo,
            onTap: () => _navigateToMusic(),
          ),
          AppItem(
            title: 'Mood Tracker',
            subtitle: 'Track your feelings',
            iconPath: 'assets/icons/mood_tracker.png',
            color: Colors.pink,
            onTap: () => _navigateToMoodTracker(),
          ),
          AppItem(
            title: 'Settings',
            subtitle: 'Customize your experience',
            iconPath: 'assets/icons/settings.png',
            color: Colors.grey,
            onTap: () => _navigateToSettings(),
          ),
        ],
      ),
      AppCategory(
        title: 'Alters',
        subtitle: 'Identity & community',
        iconPath: 'assets/icons/alters.png',
        color: Colors.deepOrange,
        items: [
          AppItem(
            title: 'Fronting Alter',
            subtitle: 'Track fronting status',
            iconPath: 'assets/icons/fronting.png',
            color: Colors.orange,
            onTap: () => _navigateToFrontingAlter(),
          ),
          AppItem(
            title: 'Community List',
            subtitle: 'Browse all users',
            iconPath: 'assets/icons/users.png',
            color: Colors.blue,
            onTap: () => _navigateToUserList(),
          ),
          AppItem(
            title: 'Collaborative Writing',
            subtitle: 'Write together',
            iconPath: 'assets/icons/notes.png',
            color: Colors.teal,
            isNew: true,
            onTap: () => _navigateToCollaborativeWriting(),
          ),
        ],
      ),
      AppCategory(
        title: 'Pets',
        subtitle: 'Virtual companions',
        iconPath: 'assets/icons/pets.png',
        color: Colors.green,
        items: [
          AppItem(
            title: 'Pet Care',
            subtitle: 'Take care of your pets',
            iconPath: 'assets/icons/pet_care.png',
            color: Colors.green,
            onTap: () => _navigateToPetCare(),
          ),
          AppItem(
            title: 'Pet Details',
            subtitle: 'View pet information',
            iconPath: 'assets/icons/pet_details.png',
            color: Colors.lightGreen,
            onTap: () => _navigateToPetDetails(),
          ),
          
        ],
      ),
      AppCategory(
        title: 'Mystic',
        subtitle: 'Spiritual guidance',
        iconPath: 'assets/icons/mystic.png',
        color: Colors.purple,
        items: [
          AppItem(
            title: 'Crystal Oracle',
            subtitle: 'Mystical guidance & wisdom',
            iconPath: 'assets/icons/oracle.png',
            color: Colors.deepPurple,
            isNew: true,
            onTap: () => _navigateToOracle(),
          ),
          AppItem(
            title: 'Magic 8-Ball',
            subtitle: 'Ask the mystical sphere',
            iconPath: 'assets/icons/8ball.png',
            color: Colors.indigo,
            isNew: true,
            onTap: () => _navigateToMagic8Ball(),
          ),
          AppItem(
            title: 'Daily Horoscope',
            subtitle: 'Your cosmic forecast',
            iconPath: 'assets/icons/daily_horoscope.png',
            color: Colors.deepPurple,
            onTap: () => _navigateToHoroscope(),
          ),
          AppItem(
            title: 'Weekly Horoscope',
            subtitle: 'Week-long predictions',
            iconPath: 'assets/icons/weekly_horoscope.png',
            color: Colors.indigo,
            onTap: () => _navigateToWeeklyHoroscope(),
          ),
          AppItem(
            title: 'Moon Phases',
            subtitle: 'Lunar guidance & rituals',
            iconPath: 'assets/icons/moon_phases.png',
            color: Colors.blueGrey,
            onTap: () => _navigateToMoonPhase(),
          ),
          AppItem(
            title: 'Astro Events',
            subtitle: 'Celestial happenings',
            iconPath: 'assets/icons/astro_events.png',
            color: Colors.teal,
            onTap: () => _navigateToAstroEvents(),
          ),
          AppItem(
            title: 'Zodiac Match',
            subtitle: 'Check compatibility',
            iconPath: 'assets/icons/zodiac_match.png',
            color: Colors.pink,
            onTap: () => _navigateToZodiacCompatibility(),
          ),
          AppItem(
            title: 'Tarot Reading',
            subtitle: 'Divine insights',
            iconPath: 'assets/icons/tarot.png',
            color: Colors.purple,
            isPremium: true,
            onTap: () => _navigateToTarot(),
          ),
        ],
      ),
      AppCategory(
        title: 'Virtual Spaces',
        subtitle: 'Magical environments',
        iconPath: 'assets/icons/virtual_spaaces.png',
        color: Colors.green,
        items: [
          AppItem(
            title: 'Butterfly Garden',
            subtitle: 'Collect beautiful butterflies',
            iconPath: 'assets/icons/butterfly_garden.png',
            color: Colors.orange,
            isNew: true,
            onTap: () => _navigateToButterflyGarden(),
          ),
          AppItem(
            title: 'Crystal Garden',
            subtitle: 'Grow magical flowers',
            iconPath: 'assets/icons/crystal_garden.png',
            color: Colors.green,
            onTap: () => _navigateToCrystalGarden(),
          ),
          AppItem(
            title: 'Gemstone Collection',
            subtitle: 'Discover precious gems',
            iconPath: 'assets/icons/gemstone_collection.png',
            color: Colors.purple,
            isPremium: true,
            onTap: () => _navigateToGemstones(),
          ),
         
        ],
      ),
      AppCategory(
        title: 'Shop & Rewards',
        subtitle: 'Earn and spend',
        iconPath: 'assets/icons/shop_and_rewards.png',
        color: Colors.purple,
        items: [
          AppItem(
            title: 'Shop',
            subtitle: 'Buy items and upgrades',
            iconPath: 'assets/icons/shop.png',
            color: Colors.purple,
            onTap: () => _navigateToShop(),
          ),
          AppItem(
            title: 'Rewards',
            subtitle: 'Daily rewards & achievements',
            iconPath: 'assets/icons/rewards.png',
            color: Colors.orange,
            onTap: () => _navigateToRewards(),
          ),
          AppItem(
            title: 'Inventory',
            subtitle: 'Manage your items',
            iconPath: 'assets/icons/inventory.png',
            color: Colors.brown,
            onTap: () => _navigateToInventory(),
          ),
          AppItem(
            title: 'Currency Hub',
            subtitle: 'Earn coins & currency',
            iconPath: 'assets/icons/currency.png', // Using currency icon temporarily
            color: Colors.amber,
            isNew: true,
            onTap: () => _navigateToCurrencyEarning(),
          ),
          AppItem(
            title: 'Achievements',
            subtitle: 'Complete challenges',
            iconPath: 'assets/icons/achievements.png', // Using achievements icon for achievements
            color: const Color.fromARGB(255, 223, 202, 17),
            onTap: () => _navigateToAchievements(),
          ),
          AppItem(
            title: 'Booster Packs',
            subtitle: 'Open mystery packs',
            iconPath: 'assets/icons/booster.png', // Using games icon temporarily
            color: Colors.indigo,
            onTap: () => _navigateToBoosterPacks(),
          ),
          AppItem(
            title: 'Bestie Bonds',
            subtitle: 'Friendship rewards',
            iconPath: 'assets/icons/bestie_bonds.png', // This icon already exists!
            color: Colors.pink,
            isNew: true,
            onTap: () => _navigateToBestieBonds(),
          ),
        ],
      ),
      AppCategory(
        title: 'Crystal Games',
        subtitle: 'Play exciting games',
        iconPath: 'assets/icons/crystal_games.png',
        color: Colors.orange,
        items: [
          AppItem(
            title: 'Crystal Games',
            subtitle: 'Launch gaming app',
            iconPath: 'assets/icons/crystal_games.png',
            color: Colors.orange,
            isNew: true,
            onTap: () => _navigateToCrystalGames(),
          ),
        ],
      ),
    ];
  }
  
  List<AppItem> _getFilteredItems() {
    if (_selectedCategory == 'all') {
      return _getCategories().expand((category) => category.items).toList();
    } else {
      final category = _getCategories().firstWhere(
        (cat) => cat.title.toLowerCase() == _selectedCategory,
        orElse: () => _getCategories().first,
      );
      return category.items;
    }
  }
  
  void _navigateToScreen(BuildContext context, AppItem item) {
    item.onTap();
  }
  
  void _navigateToChat() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => EnhancedChatListScreen(
          username: _username ?? 'User',
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }
  
  void _navigateToGroups() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => GroupListScreen(
          currentUserId: widget.currentUserId,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }
  
  void _navigateToProfile() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => EnhancedProfileScreen(
          userId: widget.currentUserId,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }
  
  void _navigateToGlitterBoard() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => GlitterBoardScreen(
          userId: widget.currentUserId,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }

  void _navigateToGlimmerWall() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => GlimmerWallScreen(
          currentUserId: widget.currentUserId,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }

  void _navigateToMusic() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => _buildPlaceholderScreen('Music Player'),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }
  
  void _navigateToNotes() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => NotesHomeScreen(
          userId: widget.currentUserId,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }
  
  void _navigateToMoodTracker() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => _buildPlaceholderScreen('Mood Tracker'),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }
  
  void _navigateToHoroscope() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => EnhancedCrystalHoroscopeTab(
          userId: widget.currentUserId,
          supabase: Supabase.instance.client,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }
  
  void _navigateToOracle() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => OracleScreen(
          userId: widget.currentUserId,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }
  
  void _navigateToMagic8Ball() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Magic8BallScreen(
          userId: widget.currentUserId,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }
  
  void _navigateToTarot() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => TarotReadingTab(
          userId: widget.currentUserId,
          supabase: Supabase.instance.client,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }

  void _navigateToWeeklyHoroscope() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
          backgroundColor: Color(0xFF0D1117),
          appBar: AppBar(
            title: Text('Weekly Horoscope', style: TextStyle(color: Colors.white)),
            backgroundColor: Color(0xFF1A1A2E),
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: WeeklyHoroscopeTab(
            userId: widget.currentUserId,
            supabase: Supabase.instance.client,
          ),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }

  void _navigateToMoonPhase() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
          backgroundColor: Color(0xFF0D1117),
          appBar: AppBar(
            title: Text('Moon Phase Tracker', style: TextStyle(color: Colors.white)),
            backgroundColor: Color(0xFF1A1A2E),
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: MoonPhaseTrackingTab(
            userId: widget.currentUserId,
            supabase: Supabase.instance.client,
          ),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }

  void _navigateToAstroEvents() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
          backgroundColor: Color(0xFF0D1117),
          appBar: AppBar(
            title: Text('Astronomical Events', style: TextStyle(color: Colors.white)),
            backgroundColor: Color(0xFF1A1A2E),
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: AstronomicalEventsTab(),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }

  void _navigateToZodiacCompatibility() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
          backgroundColor: Color(0xFF0D1117),
          appBar: AppBar(
            title: Text('Zodiac Compatibility', style: TextStyle(color: Colors.white)),
            backgroundColor: Color(0xFF1A1A2E),
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: ZodiacCompatibilityTab(),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }

    void _navigateToSettings() {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => EnhancedSettingsScreen(
            userId: widget.currentUserId,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    }

    void _navigateToUserProfile() {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => UserProfileScreen(
            userId: widget.currentUserId,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    }

    void _navigateToPetCare() {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => PetCareScreen(
            userId: widget.currentUserId,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    }

    void _navigateToPetDetails() {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => PetDetailsScreen(
            userId: widget.currentUserId,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    }

    void _navigateToShop() {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ShopScreen(
            userId: widget.currentUserId,
            supabase: Supabase.instance.client,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    }

    void _navigateToRewards() {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => UnifiedRewardsScreen(
            userId: widget.currentUserId,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    }

    void _navigateToInventory() {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => InventoryScreen(
            userId: widget.currentUserId,
            supabase: Supabase.instance.client,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    }

    void _navigateToCurrencyEarning() {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => CurrencyEarningScreen(
            userId: widget.currentUserId,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    }

    void _navigateToAchievements() {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => AchievementsScreen(
            userId: widget.currentUserId,
            supabase: Supabase.instance.client,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    }

    void _navigateToBoosterPacks() {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => BoosterPackScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    }

    void _navigateToBestieBonds() {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => BestieBondManager(
            userId: widget.currentUserId,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    }

    void _navigateToCursedPoll() {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => CursedPollScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    }

    void _navigateToFrontingAlter() {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => FrontingAlterTab(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    }

    void _navigateToUserList() {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => UserListScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    }

    void _navigateToCollaborativeWriting() {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => EnhancedCollaborativeWritingTab(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    }

    void _navigateToConfessions() {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => CrystalConfessionalScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    }

    void _navigateToButterflyGarden() {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => EnhancedButterflyGardenScreen(
            userId: widget.currentUserId,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    }

    void _navigateToCrystalGarden() {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => EnhancedCrystalGardenScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    }

    void _navigateToGemstones() {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => _buildPlaceholderScreen('Gemstone Collection'),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    }

    

    void _navigateToCrystalGames() async {
      // STEP 1: Replace 'crystalgames' with your actual URL scheme
      const String crystalGamesUrl = 'crystalgames://launch';
      
      // STEP 2: Replace these with your actual package identifiers
      const String androidPackageId = 'com.yourcompany.crystalgames';  // Replace with your Android package name
      const String iosAppStoreId = '1234567890';  // Replace with your iOS App Store ID
      
      try {
        final Uri url = Uri.parse(crystalGamesUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          // App not installed, redirect to store
          await _redirectToAppStore(androidPackageId, iosAppStoreId);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error launching Crystal Games: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
    
    // Helper method to redirect to app store
    Future<void> _redirectToAppStore(String androidPackageId, String iosAppStoreId) async {
      String storeUrl;
      
      if (Theme.of(context).platform == TargetPlatform.android) {
        storeUrl = 'https://play.google.com/store/apps/details?id=$androidPackageId';
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        storeUrl = 'https://apps.apple.com/app/id$iosAppStoreId';
      } else {
        // Fallback for other platforms
        storeUrl = 'https://play.google.com/store/apps/details?id=$androidPackageId';
      }
      
      try {
        await launchUrl(Uri.parse(storeUrl), mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Crystal Games app not available. Please check app stores.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

