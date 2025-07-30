import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'gemstone_model.dart';
import 'gem_service.dart';
import 'shiny_gem_animation.dart';

/// Gem Provider - Reactive state management for the gem system
/// Provides easy access to gem data and operations throughout the app
class GemProvider extends ChangeNotifier {
  final GemService _gemService = GemService();
  
  late StreamSubscription<List<Gemstone>> _gemsSubscription;
  late StreamSubscription<Map<String, dynamic>> _statsSubscription;
  late StreamSubscription<Gemstone> _unlockSubscription;
  
  List<Gemstone> _gems = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;
  String? _error;
  
  // Filters and sorting
  String _searchQuery = '';
  GemRarity? _selectedRarity;
  String? _selectedElement;
  String _sortBy = 'name';
  bool _ascending = true;
  bool _showUserOnly = false;

  // Getters
  List<Gemstone> get gems => _gems;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _gemService.isInitialized;
  
  String get searchQuery => _searchQuery;
  GemRarity? get selectedRarity => _selectedRarity;
  String? get selectedElement => _selectedElement;
  String get sortBy => _sortBy;
  bool get ascending => _ascending;
  bool get showUserOnly => _showUserOnly;

  // Filtered gems based on current settings
  List<Gemstone> get filteredGems {
    return _gemService.getFilteredGems(
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      rarity: _selectedRarity,
      element: _selectedElement,
      sortBy: _sortBy,
      ascending: _ascending,
      userOnly: _showUserOnly,
    );
  }

  // Quick access to user statistics
  int get totalGems => _stats['total_gems'] ?? 0;
  int get totalPossible => _stats['total_possible'] ?? 0;
  double get completionPercentage => _stats['completion_percentage'] ?? 0.0;
  int get totalValue => _stats['total_value'] ?? 0;
  int get totalPower => _stats['total_power'] ?? 0;
  int get favoritesCount => _stats['favorites_count'] ?? 0;

  GemProvider() {
    _initializeSubscriptions();
  }

  void _initializeSubscriptions() {
    _gemsSubscription = _gemService.gemsStream.listen((gems) {
      _gems = gems;
      notifyListeners();
    });

    _statsSubscription = _gemService.statsStream.listen((stats) {
      _stats = stats;
      notifyListeners();
    });

    _unlockSubscription = _gemService.unlockStream.listen((gem) {
      // Handle new gem unlocks
      notifyListeners();
    });
  }

  /// Initialize the gem system for a user
  Future<void> initialize(String userId) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _gemService.initialize(userId);
    } catch (e) {
      _setError('Failed to initialize gem system: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Unlock a new gem
  Future<bool> unlockGem(String gemId, {Map<String, dynamic>? context}) async {
    try {
      final success = await _gemService.unlockGem(gemId, context: context);
      if (success) {
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Failed to unlock gem: $e');
      return false;
    }
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(String gemId) async {
    try {
      return await _gemService.toggleFavorite(gemId);
    } catch (e) {
      _setError('Failed to toggle favorite: $e');
      return false;
    }
  }

  /// Update search query
  void updateSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  /// Update rarity filter
  void updateRarityFilter(GemRarity? rarity) {
    if (_selectedRarity != rarity) {
      _selectedRarity = rarity;
      notifyListeners();
    }
  }

  /// Update element filter
  void updateElementFilter(String? element) {
    if (_selectedElement != element) {
      _selectedElement = element;
      notifyListeners();
    }
  }

  /// Update sorting
  void updateSorting(String sortBy, {bool? ascending}) {
    bool changed = false;
    
    if (_sortBy != sortBy) {
      _sortBy = sortBy;
      changed = true;
    }
    
    if (ascending != null && _ascending != ascending) {
      _ascending = ascending;
      changed = true;
    }
    
    if (changed) {
      notifyListeners();
    }
  }

  /// Toggle user only filter
  void toggleUserOnly() {
    _showUserOnly = !_showUserOnly;
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    bool changed = false;
    
    if (_searchQuery.isNotEmpty) {
      _searchQuery = '';
      changed = true;
    }
    
    if (_selectedRarity != null) {
      _selectedRarity = null;
      changed = true;
    }
    
    if (_selectedElement != null) {
      _selectedElement = null;
      changed = true;
    }
    
    if (changed) {
      notifyListeners();
    }
  }

  /// Get random gem for rewards
  Gemstone? getRandomGem({GemRarity? rarity, bool excludeOwned = true}) {
    return _gemService.getRandomGem(rarity: rarity, excludeOwned: excludeOwned);
  }

  /// Generate random reward
  Gemstone? generateRandomReward() {
    return _gemService.generateRandomReward();
  }

  /// Check if user has gem
  bool hasGem(String gemId) {
    return _gemService.hasGem(gemId);
  }

  /// Get gems by rarity
  List<Gemstone> getGemsByRarity(GemRarity rarity, {bool userOnly = false}) {
    return _gemService.getGemsByRarity(rarity, userOnly: userOnly);
  }

  /// Get gems by element
  List<Gemstone> getGemsByElement(String element, {bool userOnly = false}) {
    return _gemService.getGemsByElement(element, userOnly: userOnly);
  }

  /// Refresh data
  Future<void> refresh() async {
    _setLoading(true);
    try {
      await _gemService.refresh();
    } catch (e) {
      _setError('Failed to refresh: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _gemsSubscription.cancel();
    _statsSubscription.cancel();
    _unlockSubscription.cancel();
    super.dispose();
  }
}

/// Gem Builder Widget - Reactive widget for building UI based on gem state
class GemBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, GemProvider gems) builder;

  const GemBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GemProvider>(
      builder: (context, gems, child) => builder(context, gems),
    );
  }
}

/// Gem Mixin - Easy access to gem provider from any StatefulWidget
mixin GemMixin<T extends StatefulWidget> on State<T> {
  GemProvider get gemProvider => Provider.of<GemProvider>(context, listen: false);
}

/// Context extension for easy gem access
extension GemContext on BuildContext {
  GemProvider get gems => Provider.of<GemProvider>(this, listen: false);
  GemProvider get gemsListen => Provider.of<GemProvider>(this, listen: true);
}

/// Pre-built UI Components for common gem operations

/// Gem Statistics Card
class GemStatsCard extends StatelessWidget {
  final bool showDetailedStats;
  final EdgeInsets padding;

  const GemStatsCard({
    super.key,
    this.showDetailedStats = true,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return GemBuilder(
      builder: (context, gems) {
        return Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1a1a2e).withOpacity(0.8),
                const Color(0xFF16213e).withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Collection Stats',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      label: 'Collected',
                      value: '${gems.totalGems}',
                      color: Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
                      label: 'Total',
                      value: '${gems.totalPossible}',
                      color: Colors.grey,
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
                      label: 'Progress',
                      value: '${gems.completionPercentage.toStringAsFixed(1)}%',
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              if (showDetailedStats) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: 'Power',
                        value: '${gems.totalPower}',
                        color: Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        label: 'Value',
                        value: '${gems.totalValue}',
                        color: Colors.yellow,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        label: 'Favorites',
                        value: '${gems.favoritesCount}',
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Gem Filter Chips
class GemFilterChips extends StatelessWidget {
  const GemFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    return GemBuilder(
      builder: (context, gems) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // User Only Toggle
            FilterChip(
              label: Text('My Collection'),
              selected: gems.showUserOnly,
              onSelected: (_) => gems.toggleUserOnly(),
              backgroundColor: Colors.grey.withOpacity(0.2),
              selectedColor: Colors.blue.withOpacity(0.3),
              labelStyle: TextStyle(color: Colors.white),
            ),
            
            // Rarity Filters
            ...GemRarity.values.map((rarity) => FilterChip(
              label: Text(rarity.name.toUpperCase()),
              selected: gems.selectedRarity == rarity,
              onSelected: (selected) => gems.updateRarityFilter(selected ? rarity : null),
              backgroundColor: Colors.grey.withOpacity(0.2),
              selectedColor: _getRarityColor(rarity).withOpacity(0.3),
              labelStyle: TextStyle(color: Colors.white),
            )),
            
            // Clear Filters
            if (gems.searchQuery.isNotEmpty || 
                gems.selectedRarity != null || 
                gems.selectedElement != null)
              ActionChip(
                label: Text('Clear Filters'),
                onPressed: gems.clearFilters,
                backgroundColor: Colors.red.withOpacity(0.2),
                labelStyle: TextStyle(color: Colors.white),
              ),
          ],
        );
      },
    );
  }

  Color _getRarityColor(GemRarity rarity) {
    switch (rarity) {
      case GemRarity.legendary:
        return const Color(0xFFFFD700);
      case GemRarity.epic:
        return const Color(0xFF8E44AD);
      case GemRarity.rare:
        return const Color(0xFF3498DB);
      case GemRarity.uncommon:
        return const Color(0xFF27AE60);
      case GemRarity.common:
        return const Color(0xFF7F8C8D);
    }
  }
}

/// Gem Search Bar
class GemSearchBar extends StatefulWidget {
  final String? hintText;
  final EdgeInsets padding;

  const GemSearchBar({
    super.key,
    this.hintText,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<GemSearchBar> createState() => _GemSearchBarState();
}

class _GemSearchBarState extends State<GemSearchBar> with GemMixin {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: gemProvider.searchQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: TextField(
        controller: _controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Search gems...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.6)),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.6)),
                  onPressed: () {
                    _controller.clear();
                    gemProvider.updateSearchQuery('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) => gemProvider.updateSearchQuery(value),
      ),
    );
  }
}

/// Loading indicator for gem operations
class GemLoadingIndicator extends StatelessWidget {
  final String? message;

  const GemLoadingIndicator({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
