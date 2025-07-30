import 'package:flutter/material.dart';
import 'user_info_service.dart';

/// Provider for user info state management with reactive UI
class UserInfoProvider extends ChangeNotifier {
  final UserInfoService _service = UserInfoService();

  // State variables
  UserInfo? _currentUserInfo;
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = false;
  bool _isLoadingUsers = false;
  String? _error;
  String _searchQuery = '';
  Map<String, int> _categoryStats = {};

  // Getters
  UserInfo? get currentUserInfo => _currentUserInfo;
  List<Map<String, dynamic>> get allUsers => _allUsers;
  List<Map<String, dynamic>> get filteredUsers => _filteredUsers;
  bool get isLoading => _isLoading;
  bool get isLoadingUsers => _isLoadingUsers;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  Map<String, int> get categoryStats => _categoryStats;

  /// Load user info for a specific user
  Future<void> loadUserInfo(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUserInfo = await _service.fetchUserInfo(userId);
      _categoryStats = await _service.getUserCategoryStats(userId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading user info: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load all users for the community list
  Future<void> loadAllUsers() async {
    _isLoadingUsers = true;
    _error = null;
    notifyListeners();

    try {
      _allUsers = await _service.fetchAllUsers();
      _filteredUsers = List.from(_allUsers);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading users: $e');
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  /// Add item to a category
  Future<bool> addCategoryItem(String userId, String categoryTitle, String content) async {
    try {
      // Validate content
      final validationError = _service.validateCategoryItem(content);
      if (validationError != null) {
        _error = validationError;
        notifyListeners();
        return false;
      }

      await _service.addCategoryItem(userId, categoryTitle, content);
      
      // Update local state
      if (_currentUserInfo != null && _currentUserInfo!.id == userId) {
        final updatedCategories = List<InfoCategory>.from(_currentUserInfo!.categories);
        final categoryIndex = updatedCategories.indexWhere((cat) => cat.title == categoryTitle);
        
        if (categoryIndex >= 0) {
          updatedCategories[categoryIndex] = updatedCategories[categoryIndex].copyWith(
            items: [...updatedCategories[categoryIndex].items, content]
          );
          
          _currentUserInfo = _currentUserInfo!.copyWith(categories: updatedCategories);
          
          // Update stats
          _categoryStats[categoryTitle] = (_categoryStats[categoryTitle] ?? 0) + 1;
          notifyListeners();
        }
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding category item: $e');
      notifyListeners();
      return false;
    }
  }

  /// Save free text content
  Future<bool> saveFreeText(String userId, String content) async {
    try {
      // Validate content
      final validationError = _service.validateFreeText(content);
      if (validationError != null) {
        _error = validationError;
        notifyListeners();
        return false;
      }

      await _service.saveFreeText(userId, content);
      
      // Update local state
      if (_currentUserInfo != null && _currentUserInfo!.id == userId) {
        _currentUserInfo = _currentUserInfo!.copyWith(freeText: content);
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error saving free text: $e');
      notifyListeners();
      return false;
    }
  }

  /// Remove item from a category
  Future<bool> removeCategoryItem(String userId, String categoryTitle, String content) async {
    try {
      await _service.removeCategoryItem(userId, categoryTitle, content);
      
      // Update local state
      if (_currentUserInfo != null && _currentUserInfo!.id == userId) {
        final updatedCategories = List<InfoCategory>.from(_currentUserInfo!.categories);
        final categoryIndex = updatedCategories.indexWhere((cat) => cat.title == categoryTitle);
        
        if (categoryIndex >= 0) {
          final updatedItems = List<String>.from(updatedCategories[categoryIndex].items);
          updatedItems.remove(content);
          
          updatedCategories[categoryIndex] = updatedCategories[categoryIndex].copyWith(
            items: updatedItems
          );
          
          _currentUserInfo = _currentUserInfo!.copyWith(categories: updatedCategories);
          
          // Update stats
          _categoryStats[categoryTitle] = (_categoryStats[categoryTitle] ?? 1) - 1;
          if (_categoryStats[categoryTitle]! <= 0) {
            _categoryStats.remove(categoryTitle);
          }
          notifyListeners();
        }
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error removing category item: $e');
      notifyListeners();
      return false;
    }
  }

  /// Toggle category expansion
  void toggleCategoryExpansion(String categoryTitle) {
    if (_currentUserInfo != null) {
      final updatedCategories = List<InfoCategory>.from(_currentUserInfo!.categories);
      final categoryIndex = updatedCategories.indexWhere((cat) => cat.title == categoryTitle);
      
      if (categoryIndex >= 0) {
        updatedCategories[categoryIndex] = updatedCategories[categoryIndex].copyWith(
          isExpanded: !updatedCategories[categoryIndex].isExpanded
        );
        
        _currentUserInfo = _currentUserInfo!.copyWith(categories: updatedCategories);
        notifyListeners();
      }
    }
  }

  /// Search users
  Future<void> searchUsers(String query) async {
    _searchQuery = query;
    
    try {
      if (query.trim().isEmpty) {
        _filteredUsers = List.from(_allUsers);
      } else {
        _filteredUsers = await _service.searchUsers(query);
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error searching users: $e');
    }
    
    notifyListeners();
  }

  /// Clear search and show all users
  void clearSearch() {
    _searchQuery = '';
    _filteredUsers = List.from(_allUsers);
    notifyListeners();
  }

  /// Refresh user data
  Future<void> refreshUserInfo(String userId) async {
    await loadUserInfo(userId);
  }

  /// Refresh users list
  Future<void> refreshUsers() async {
    await loadAllUsers();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get category by title
  InfoCategory? getCategoryByTitle(String title) {
    if (_currentUserInfo == null) return null;
    
    try {
      return _currentUserInfo!.categories.firstWhere((cat) => cat.title == title);
    } catch (e) {
      return null;
    }
  }

  /// Get total items count for current user
  int get totalCategoryItems {
    if (_currentUserInfo == null) return 0;
    return _currentUserInfo!.categories.fold(0, (sum, category) => sum + category.items.length);
  }

  /// Check if current user has any content
  bool get hasUserContent {
    if (_currentUserInfo == null) return false;
    return totalCategoryItems > 0 || _currentUserInfo!.freeText.isNotEmpty;
  }

  /// Get completion percentage for current user
  double get profileCompletionPercentage {
    if (_currentUserInfo == null) return 0.0;
    
    double score = 0.0;
    
    // Basic info (40 points max)
    if (_currentUserInfo!.username.isNotEmpty) score += 10;
    if (_currentUserInfo!.avatarUrl != null && _currentUserInfo!.avatarUrl!.isNotEmpty) score += 10;
    if (_currentUserInfo!.bio != null && _currentUserInfo!.bio!.isNotEmpty) score += 20;
    
    // Categories (40 points max - about 6.7 points per category)
    final categoriesWithItems = _currentUserInfo!.categories.where((cat) => cat.items.isNotEmpty).length;
    score += (categoriesWithItems * 6.7).clamp(0, 40);
    
    // Free text (20 points max)
    if (_currentUserInfo!.freeText.isNotEmpty) score += 20;
    
    return (score / 100.0).clamp(0.0, 1.0);
  }

  /// Get avatar decoration icon
  IconData getAvatarDecorationIcon(String? decoration) {
    return _service.getAvatarDecorationIcon(decoration);
  }

  /// Get default categories
  List<InfoCategory> getDefaultCategories() {
    return _service.getDefaultCategories();
  }

  /// Reset all state
  void reset() {
    _currentUserInfo = null;
    _allUsers = [];
    _filteredUsers = [];
    _isLoading = false;
    _isLoadingUsers = false;
    _error = null;
    _searchQuery = '';
    _categoryStats = {};
    notifyListeners();
  }
}
