import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_provider.dart';
import 'stats_dashboard.dart';
import 'enhanced_edit_profile_screen.dart';
import 'ringtone_picker_screen.dart';
import 'notification_sound_picker.dart';
import 'avatar_decoration.dart';

class EnhancedProfileScreen extends StatefulWidget {
  final String userId;
  final String? username;
  final String? avatarUrl;

  const EnhancedProfileScreen({
    super.key,
    required this.userId,
    this.username,
    this.avatarUrl,
  });

  @override
  State<EnhancedProfileScreen> createState() => _EnhancedProfileScreenState();
}

class _EnhancedProfileScreenState extends State<EnhancedProfileScreen> 
    with TickerProviderStateMixin, ProfileMixin {
  
  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final String currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutBack,
    ));
    
    // Initialize profile service
    _initializeProfile();
    
    // Start animations
    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _cardAnimationController.forward();
    });
  }

  Future<void> _initializeProfile() async {
    await profileProvider.initialize(widget.userId);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  bool get isOwnProfile => widget.userId == currentUserId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: ProfileLoadingWrapper(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildProfileHeader(),
                        const SizedBox(height: 20),
                        _buildStatsSection(),
                        const SizedBox(height: 20),
                        _buildQuickActions(),
                        const SizedBox(height: 20),
                        _buildProfileCompletion(),
                        const SizedBox(height: 20),
                        _buildActivitySection(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF16213e),
      flexibleSpace: FlexibleSpaceBar(
        title: ProfileBuilder(
          builder: (context, profile) {
            return Text(
              profile.getDisplayName(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            );
          },
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF16213e), Color(0xFF1a1a2e)],
            ),
          ),
        ),
      ),
      actions: [
        if (isOwnProfile)
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => _navigateToEditProfile(),
          ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () => _showOptionsMenu(),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return ProfileBuilder(
      builder: (context, profile) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF16213e),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Avatar with decoration
              Stack(
                children: [
                  ProfileAvatar(
                    radius: 50,
                    showDecoration: true,
                    onTap: isOwnProfile ? () => _navigateToAvatarPicker() : null,
                  ),
                  if (profile.isLoading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Display name and username
              Text(
                profile.getDisplayName(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (profile.username != null)
                Text(
                  '@${profile.username}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
              
              const SizedBox(height: 12),
              
              // Bio
              if (profile.bio != null && profile.bio!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a2e),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    profile.bio!,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // User level and activity score
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatChip(
                    'Level ${profile.getUserLevel()}',
                    Icons.star,
                    Colors.amber,
                  ),
                  _buildStatChip(
                    '${profile.getActivityScore()} Activity',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return ProfileBuilder(
      builder: (context, profile) {
        final stats = profile.userStats;
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF16213e),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Activity Stats',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Messages',
                      '${stats['total_messages'] ?? 0}',
                      Icons.message,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Logins',
                      '${stats['total_logins'] ?? 0}',
                      Icons.login,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Groups',
                      '${stats['groups_joined'] ?? 0}',
                      Icons.group,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Stats Dashboard',
                  Icons.dashboard,
                  Colors.cyan,
                  () => _navigateToStatsBoard(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Sound Settings',
                  Icons.volume_up,
                  Colors.orange,
                  () => _navigateToSoundSettings(),
                ),
              ),
            ],
          ),
          if (isOwnProfile) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Edit Profile',
                    Icons.edit,
                    Colors.green,
                    () => _navigateToEditProfile(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Avatar Picker',
                    Icons.face,
                    Colors.pink,
                    () => _navigateToAvatarPicker(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCompletion() {
    if (!isOwnProfile) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Completion',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          ProfileCompletionIndicator(height: 6),
        ],
      ),
    );
  }

  Widget _buildActivitySection() {
    return ProfileBuilder(
      builder: (context, profile) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF16213e),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile Info',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (profile.zodiacSign != null)
                _buildInfoRow(Icons.star, 'Zodiac Sign', profile.zodiacSign!),
              if (profile.location != null)
                _buildInfoRow(Icons.location_on, 'Location', profile.location!),
              if (profile.website != null)
                _buildInfoRow(Icons.link, 'Website', profile.website!),
              if (profile.interests?.isNotEmpty == true)
                _buildInterestsRow(profile.interests!),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsRow(List<String> interests) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.interests, color: Colors.grey[400], size: 20),
              const SizedBox(width: 12),
              Text(
                'Interests:',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: interests.map((interest) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.5)),
              ),
              child: Text(
                interest,
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // Navigation methods
  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedEditProfileScreen(
          userId: widget.userId,
        ),
      ),
    );
  }

  void _navigateToStatsBoard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatsDashboardScreen(
          supabaseClient: Supabase.instance.client,
        ),
      ),
    );
  }

  void _navigateToSoundSettings() {
    if (!isOwnProfile) {
      // For other users, show per-user ringtone picker
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PerUserRingtonePicker(
            ownerId: currentUserId,
            senderId: widget.userId,
            senderName: watchProfile.getDisplayName(),
          ),
        ),
      );
    } else {
      // For own profile, show notification sound picker
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationSoundPicker(
            userId: widget.userId,
          ),
        ),
      );
    }
  }

  void _navigateToAvatarPicker() {
    // For now, navigate to avatar decoration screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AvatarCustomizationScreen(
          userId: widget.userId,
          avatarUrl: watchProfile.avatarUrl ?? '',
          currentDecorationPath: watchProfile.avatarDecoration ?? '',
          onDecorationSelected: (decorationPath) {
            profileProvider.setAvatarDecoration(decorationPath);
          },
        ),
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.white),
              title: const Text('Refresh Profile', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                profileProvider.refresh();
              },
            ),
            if (!isOwnProfile)
              ListTile(
                leading: const Icon(Icons.report, color: Colors.red),
                title: const Text('Report User', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: const Text('Report User', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Report functionality would be implemented here.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }
}

// Keep the old ProfileScreen as a wrapper for backward compatibility
class ProfileScreen extends StatelessWidget {
  final String userId;
  final String username;
  final String? avatarUrl;

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.username,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileProvider(),
      child: EnhancedProfileScreen(
        userId: userId,
        username: username,
        avatarUrl: avatarUrl,
      ),
    );
  }
}
