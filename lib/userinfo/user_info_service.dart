import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Data models for user info categories
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

  // Copy constructor for immutable updates
  InfoCategory copyWith({
    String? title,
    IconData? icon,
    Color? color,
    List<String>? items,
    bool? isExpanded,
  }) {
    return InfoCategory(
      title: title ?? this.title,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      items: items ?? List<String>.from(this.items),
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}

/// User data model with avatar decorations and basic info
class UserInfo {
  final String id;
  final String username;
  final String? avatarUrl;
  final String? avatarDecoration;
  final String? bio;
  final List<InfoCategory> categories;
  final String freeText;

  UserInfo({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.avatarDecoration,
    this.bio,
    required this.categories,
    this.freeText = '',
  });

  UserInfo copyWith({
    String? id,
    String? username,
    String? avatarUrl,
    String? avatarDecoration,
    String? bio,
    List<InfoCategory>? categories,
    String? freeText,
  }) {
    return UserInfo(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarDecoration: avatarDecoration ?? this.avatarDecoration,
      bio: bio ?? this.bio,
      categories: categories ?? this.categories,
      freeText: freeText ?? this.freeText,
    );
  }
}

/// Centralized service for user info management
class UserInfoService {
  static final UserInfoService _instance = UserInfoService._internal();
  factory UserInfoService() => _instance;
  UserInfoService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get default categories for new users
  List<InfoCategory> getDefaultCategories() {
    return [
      // Core Identity
      InfoCategory(
        title: 'Role',
        icon: Icons.badge,
        color: Colors.blue,
        items: [],
      ),
      InfoCategory(
        title: 'Pronouns',
        icon: Icons.person,
        color: Colors.purple,
        items: [],
      ),
      InfoCategory(
        title: 'Age',
        icon: Icons.cake,
        color: Colors.orange,
        items: [],
      ),
      InfoCategory(
        title: 'Sexuality',
        icon: Icons.favorite,
        color: Colors.pink,
        items: [],
      ),
      
      // System/Collective Related
      InfoCategory(
        title: 'Animal embodied',
        icon: Icons.pets,
        color: Colors.brown,
        items: [],
      ),
      InfoCategory(
        title: 'Fronting Frequency',
        icon: Icons.schedule,
        color: Colors.indigo,
        items: [],
      ),
      InfoCategory(
        title: 'Rank',
        icon: Icons.military_tech,
        color: Colors.amber,
        items: [],
      ),
      InfoCategory(
        title: 'Barrier level',
        icon: Icons.shield,
        color: Colors.grey,
        items: [],
      ),
      
      // Personality & Psychology
      InfoCategory(
        title: 'Personality',
        icon: Icons.psychology,
        color: Colors.teal,
        items: [],
      ),
      InfoCategory(
        title: 'MBTI',
        icon: Icons.psychology_alt,
        color: Colors.deepPurple,
        items: [],
      ),
      InfoCategory(
        title: 'Alignment chart',
        icon: Icons.grid_on,
        color: Colors.blueGrey,
        items: [],
      ),
      InfoCategory(
        title: 'Trigger',
        icon: Icons.warning,
        color: Colors.red,
        items: [],
      ),
      
      // Beliefs & Social
      InfoCategory(
        title: 'Belief system',
        icon: Icons.auto_awesome,
        color: Colors.deepOrange,
        items: [],
      ),
      InfoCategory(
        title: 'Cliques',
        icon: Icons.group,
        color: Colors.green,
        items: [],
      ),
      InfoCategory(
        title: 'Purpose',
        icon: Icons.star,
        color: Colors.yellow,
        items: [],
      ),
      
      // Personal/Intimate
      InfoCategory(
        title: 'Sex positioning',
        icon: Icons.bedtime,
        color: Colors.pinkAccent,
        items: [],
      ),
      InfoCategory(
        title: 'Song',
        icon: Icons.music_note,
        color: Colors.cyan,
        items: [],
      ),
    ];
  }

  /// Fetch user basic data (username, avatar, bio)
  Future<Map<String, dynamic>> fetchUserData(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id, username, avatarUrl, avatar_decoration, bio')
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      rethrow;
    }
  }

  /// Fetch all user info (categories and free text)
  Future<UserInfo> fetchUserInfo(String userId) async {
    try {
      // Get basic user data
      final userData = await fetchUserData(userId);
      
      // Get user info categories and free text
      final userInfoResponse = await _supabase
          .from('user_info')
          .select('category, content, info_type')
          .eq('user_id', userId);

      // Initialize categories
      List<InfoCategory> categories = getDefaultCategories();
      String freeText = '';

      // Populate categories with saved data
      for (var item in userInfoResponse) {
        if (item['info_type'] == 'category') {
          final categoryIndex = categories.indexWhere(
            (cat) => cat.title == item['category']
          );
          if (categoryIndex >= 0) {
            categories[categoryIndex].items.add(item['content']);
          }
        } else if (item['info_type'] == 'free_text') {
          freeText = item['content'] ?? '';
        }
      }

      return UserInfo(
        id: userData['id'],
        username: userData['username'] ?? 'Unknown User',
        avatarUrl: userData['avatarUrl'],
        avatarDecoration: userData['avatar_decoration'],
        bio: userData['bio'],
        categories: categories,
        freeText: freeText,
      );
    } catch (e) {
      debugPrint('Error fetching user info: $e');
      rethrow;
    }
  }

  /// Fetch all users for the community list
  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    try {
      final response = await _supabase.from('users').select('*');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching users: $e');
      rethrow;
    }
  }

  /// Add item to a specific category
  Future<void> addCategoryItem(String userId, String categoryTitle, String content) async {
    try {
      await _supabase.from('user_info').insert([
        {
          'user_id': userId,
          'category': categoryTitle,
          'content': content,
          'info_type': 'category',
          'timestamp': DateTime.now().toIso8601String()
        },
      ]);
    } catch (e) {
      debugPrint('Error adding category item: $e');
      rethrow;
    }
  }

  /// Save free text content
  Future<void> saveFreeText(String userId, String content) async {
    try {
      // First, delete existing free text entry
      await _supabase
          .from('user_info')
          .delete()
          .eq('user_id', userId)
          .eq('info_type', 'free_text');

      // Then insert new content if not empty
      if (content.isNotEmpty) {
        await _supabase.from('user_info').insert([
          {
            'user_id': userId,
            'content': content,
            'info_type': 'free_text',
            'timestamp': DateTime.now().toIso8601String()
          },
        ]);
      }
    } catch (e) {
      debugPrint('Error saving free text: $e');
      rethrow;
    }
  }

  /// Remove item from a category
  Future<void> removeCategoryItem(String userId, String categoryTitle, String content) async {
    try {
      await _supabase
          .from('user_info')
          .delete()
          .eq('user_id', userId)
          .eq('category', categoryTitle)
          .eq('content', content)
          .eq('info_type', 'category');
    } catch (e) {
      debugPrint('Error removing category item: $e');
      rethrow;
    }
  }

  /// Get avatar decoration icon
  IconData getAvatarDecorationIcon(String? decoration) {
    if (decoration == null) return Icons.auto_awesome;
    
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

  /// Validate category item content
  String? validateCategoryItem(String content) {
    if (content.trim().isEmpty) {
      return 'Content cannot be empty';
    }
    if (content.length > 200) {
      return 'Content must be less than 200 characters';
    }
    return null;
  }

  /// Validate free text content
  String? validateFreeText(String content) {
    if (content.length > 2000) {
      return 'Free text must be less than 2000 characters';
    }
    return null;
  }

  /// Search users by username or bio
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await fetchAllUsers();
      }

      final response = await _supabase
          .from('users')
          .select('*')
          .or('username.ilike.%$query%,bio.ilike.%$query%');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error searching users: $e');
      rethrow;
    }
  }

  /// Get category statistics for a user
  Future<Map<String, int>> getUserCategoryStats(String userId) async {
    try {
      final response = await _supabase
          .from('user_info')
          .select('category')
          .eq('user_id', userId)
          .eq('info_type', 'category');

      Map<String, int> stats = {};
      for (var item in response) {
        final category = item['category'] as String;
        stats[category] = (stats[category] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      debugPrint('Error fetching category stats: $e');
      return {};
    }
  }

  /// Get total items count for a user
  Future<int> getUserTotalItems(String userId) async {
    try {
      final response = await _supabase
          .from('user_info')
          .select('id')
          .eq('user_id', userId)
          .eq('info_type', 'category');

      return response.length;
    } catch (e) {
      debugPrint('Error fetching total items: $e');
      return 0;
    }
  }

  /// Check if user has free text content
  Future<bool> userHasFreeText(String userId) async {
    try {
      final response = await _supabase
          .from('user_info')
          .select('id')
          .eq('user_id', userId)
          .eq('info_type', 'free_text')
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking free text: $e');
      return false;
    }
  }
}
