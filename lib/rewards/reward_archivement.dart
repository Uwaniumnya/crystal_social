import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'rewards_manager.dart';

class AchievementsScreen extends StatefulWidget {
  final String userId;
  final SupabaseClient supabase;

  const AchievementsScreen({super.key, required this.userId, required this.supabase});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> 
    with TickerProviderStateMixin {
  late RewardsManager _rewardsManager;
  late AnimationController _animationController;
  late AnimationController _unlockAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  
  List<Map<String, dynamic>> _achievements = [];
  Map<String, dynamic> _userProgress = {};
  String _selectedCategory = 'All';
  bool _isLoading = true;
  String _searchQuery = '';
  
  final List<String> _categories = [
    'All', 'Social', 'Gaming', 'Collecting', 'Progress', 'Special'
  ];

  @override
  void initState() {
    super.initState();
    _rewardsManager = RewardsManager(widget.supabase);
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _unlockAnimationController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _unlockAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _loadAchievements();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _unlockAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadAchievements() async {
    try {
      setState(() => _isLoading = true);
      
      final achievements = await _rewardsManager.getAvailableAchievements();
      final userProgress = await _rewardsManager.getUserAchievementProgress(widget.userId);
      
      setState(() {
        _achievements = achievements;
        _userProgress = userProgress;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load achievements: $e')),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredAchievements {
    return _achievements.where((achievement) {
      bool matchesCategory = _selectedCategory == 'All' || 
          achievement['category'] == _selectedCategory;
      bool matchesSearch = _searchQuery.isEmpty ||
          achievement['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          achievement['description'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          "Achievements",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFFFFC1D9),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAchievements,
          ),
        ],
      ),
      body: _isLoading 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC1D9)),
                ),
                SizedBox(height: 16),
                Text('Loading achievements...'),
              ],
            ),
          )
        : AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    children: [
                      // Search and Filter Section
                      Container(
                        color: Colors.white,
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Search Bar
                            TextField(
                              onChanged: (value) => setState(() => _searchQuery = value),
                              decoration: InputDecoration(
                                hintText: 'Search achievements...',
                                prefixIcon: Icon(Icons.search, color: Colors.pink.shade300),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide(color: Colors.pink.shade200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide(color: Color(0xFFFFC1D9), width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                            ),
                            SizedBox(height: 16),
                            
                            // Category Filter
                            SizedBox(
                              height: 40,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _categories.length,
                                itemBuilder: (context, index) {
                                  final category = _categories[index];
                                  final isSelected = _selectedCategory == category;
                                  
                                  return Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(
                                        category,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.pink.shade700,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() => _selectedCategory = category);
                                      },
                                      backgroundColor: Colors.grey.shade100,
                                      selectedColor: Color(0xFFFFC1D9),
                                      checkmarkColor: Colors.white,
                                      elevation: isSelected ? 4 : 0,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Achievement Statistics Header
                      _buildStatsHeader(),
                      
                      // Achievements List
                      Expanded(
                        child: _filteredAchievements.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: EdgeInsets.all(16),
                                itemCount: _filteredAchievements.length,
                                itemBuilder: (context, index) {
                                  final achievement = _filteredAchievements[index];
                                  return _buildEnhancedAchievementCard(
                                    context, 
                                    achievement, 
                                    index,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  Widget _buildStatsHeader() {
    final completedCount = _achievements.where((a) => 
        _userProgress[a['id']?.toString()]?['completed'] == true).length;
    final totalCount = _achievements.length;
    final completionRate = totalCount > 0 ? completedCount / totalCount : 0.0;
    
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFC1D9), Color(0xFFFFB6C1)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFFC1D9).withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Completed', '$completedCount', Icons.check_circle),
              _buildStatItem('Total', '$totalCount', Icons.emoji_events),
              _buildStatItem('Rate', '${(completionRate * 100).toInt()}%', Icons.trending_up),
            ],
          ),
          SizedBox(height: 16),
          LinearProgressIndicator(
            value: completionRate,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
          SizedBox(height: 8),
          Text(
            'Achievement Progress',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'No achievements found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty 
                ? 'Try adjusting your search terms'
                : 'Achievements will appear here as they become available',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty) ...[
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() => _searchQuery = ''),
              child: Text('Clear Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFC1D9),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEnhancedAchievementCard(
    BuildContext context, 
    Map<String, dynamic> achievement, 
    int index,
  ) {
    final userAchievement = _userProgress[achievement['id']?.toString()];
    final isCompleted = userAchievement?['completed'] == true;
    final currentValue = userAchievement?['current_value'] ?? 0;
    final targetValue = achievement['target_value'] ?? 1;
    
    // Calculate actual progress
    final actualProgress = targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      margin: EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: isCompleted ? 8 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isCompleted 
              ? BorderSide(color: Colors.amber, width: 2)
              : BorderSide.none,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: isCompleted 
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.amber.withOpacity(0.1),
                      Colors.orange.withOpacity(0.05),
                    ],
                  )
                : null,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _handleAchievementTap(achievement, isCompleted),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Achievement Icon
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isCompleted
                                ? [Colors.amber, Colors.orange]
                                : [Colors.grey.shade300, Colors.grey.shade400],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isCompleted ? Colors.amber : Colors.grey).withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getAchievementIcon(achievement['category']),
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      SizedBox(width: 16),
                      
                      // Achievement Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    achievement['name'] ?? 'Unknown Achievement',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isCompleted 
                                          ? Colors.amber.shade700 
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                                if (isCompleted)
                                  AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _pulseAnimation.value,
                                        child: Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 24,
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              achievement['description'] ?? 'No description available',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 8),
                            
                            // Rewards
                            if (achievement['reward_coins'] != null || achievement['reward_points'] != null)
                              Row(
                                children: [
                                  if (achievement['reward_coins'] != null) ...[
                                    Icon(Icons.monetization_on, size: 16, color: Colors.orange),
                                    SizedBox(width: 4),
                                    Text(
                                      '${achievement['reward_coins']} coins',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  if (achievement['reward_coins'] != null && achievement['reward_points'] != null)
                                    SizedBox(width: 12),
                                  if (achievement['reward_points'] != null) ...[
                                    Icon(Icons.stars, size: 16, color: Colors.blue),
                                    SizedBox(width: 4),
                                    Text(
                                      '${achievement['reward_points']} points',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Progress Section
                  if (!isCompleted) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          '$currentValue / $targetValue',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: actualProgress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          actualProgress > 0.8 
                              ? Colors.green 
                              : actualProgress > 0.5 
                                  ? Colors.orange 
                                  : Color(0xFFFFC1D9),
                        ),
                        minHeight: 8,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${(actualProgress * 100).toInt()}% complete',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 16, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'Completed',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getAchievementIcon(String? category) {
    switch (category) {
      case 'Social':
        return Icons.people;
      case 'Gaming':
        return Icons.games;
      case 'Collecting':
        return Icons.collections;
      case 'Progress':
        return Icons.trending_up;
      case 'Special':
        return Icons.star;
      default:
        return Icons.emoji_events;
    }
  }

  void _handleAchievementTap(Map<String, dynamic> achievement, bool isCompleted) {
    if (isCompleted) {
      _showAchievementDetails(achievement);
    } else {
      _showProgressDetails(achievement);
    }
  }

  void _showAchievementDetails(Map<String, dynamic> achievement) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.amber.withOpacity(0.1), Colors.orange.withOpacity(0.05)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events,
                size: 60,
                color: Colors.amber,
              ),
              SizedBox(height: 16),
              Text(
                'Achievement Unlocked!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                achievement['name'] ?? 'Unknown Achievement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                achievement['description'] ?? 'No description available',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Awesome!'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProgressDetails(Map<String, dynamic> achievement) {
    final userAchievement = _userProgress[achievement['id']?.toString()];
    final currentValue = userAchievement?['current_value'] ?? 0;
    final targetValue = achievement['target_value'] ?? 1;
    final remaining = targetValue - currentValue;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getAchievementIcon(achievement['category']),
                size: 60,
                color: Color(0xFFFFC1D9),
              ),
              SizedBox(height: 16),
              Text(
                achievement['name'] ?? 'Unknown Achievement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                achievement['description'] ?? 'No description available',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Current Progress:'),
                        Text(
                          '$currentValue / $targetValue',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: targetValue > 0 ? currentValue / targetValue : 0,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC1D9)),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '$remaining more to go!',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Keep Going!'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFFC1D9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
