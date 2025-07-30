import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'rewards_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'aura_service.dart';
import '../pets/updated_pet_list.dart';
import 'package:provider/provider.dart';
import '../pets/pet_state_provider.dart';

class InventoryScreen extends StatefulWidget {
  final String userId;
  final SupabaseClient supabase;

  const InventoryScreen({super.key, required this.userId, required this.supabase});

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with TickerProviderStateMixin, RewardsMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _fabAnimation;
  
  int _page = 1;
  final int _itemsPerPage = 12;
  bool _isLoading = false;
  final List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  bool _isEndOfList = false;
  String? _selectedAuraColor;
  late final AuraService _auraService;
  String _selectedFilter = 'all';
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _sortAscending = true;
  bool _showGridView = true;
  late TabController _tabController;

  final List<Map<String, dynamic>> _filters = [
    {'key': 'all', 'name': 'All Items', 'icon': Icons.inventory, 'color': Colors.purple},
    {'key': 'aura', 'name': 'Auras', 'icon': Icons.auto_awesome, 'color': Colors.amber},
    {'key': 'background', 'name': 'Backgrounds', 'icon': Icons.wallpaper, 'color': Colors.blue},
    {'key': 'pet_accessory', 'name': 'Pet Items', 'icon': Icons.pets, 'color': Colors.green},
    {'key': 'pet', 'name': 'Pets', 'icon': Icons.cruelty_free, 'color': Colors.pink},
  ];

  @override
  void initState() {
    super.initState();
    _auraService = AuraService(widget.supabase);
    _tabController = TabController(length: _filters.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedFilter = _filters[_tabController.index]['key'];
          _items.clear();
          _page = 1;
          _isEndOfList = false;
        });
        _loadItems();
      }
    });

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.elasticOut),
    );

    _getEquippedAura();
    _loadItems();
    
    // Initialize the rewards service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      rewardsService.initialize(widget.userId);
    });
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadItems();
      }
    });

    _animationController.forward();
    
    // Delay FAB animation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _fabAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _animationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    if (_isLoading || _isEndOfList) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Use the service's cached inventory data or refresh if needed
      final allItems = rewardsService.userInventory;
      _allItems = allItems;
      
      // Apply filters and search
      _applyFiltersAndSearch();

      // Simple pagination simulation
      final startIndex = (_page - 1) * _itemsPerPage;

      List<Map<String, dynamic>> filteredForType = _filteredItems;
      
      // Apply type filter
      if (_selectedFilter != 'all') {
        filteredForType = _filteredItems.where((item) {
          return item['type'] == _selectedFilter;
        }).toList();
      }

      // Get page items
      final pageItems = filteredForType.skip(startIndex).take(_itemsPerPage).toList();

      setState(() {
        if (_page == 1) {
          _items.clear();
        }
        _items.addAll(pageItems);
        _isEndOfList = pageItems.length < _itemsPerPage;
        _page++;
        _isLoading = false;
      });

      _cacheInventoryData(_items);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading inventory: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFiltersAndSearch() {
    _filteredItems = _allItems.where((item) {
      bool matchesSearch = true;
      bool matchesFilter = true;

      // Search filter
      if (_searchQuery.isNotEmpty) {
        matchesSearch = item['name']?.toLowerCase()?.contains(_searchQuery.toLowerCase()) ?? false;
      }

      // Type filter
      if (_selectedFilter != 'all') {
        matchesFilter = item['type'] == _selectedFilter;
      }

      return matchesSearch && matchesFilter;
    }).toList();

    // Apply sorting
    _filteredItems.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'name':
          comparison = (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString());
          break;
        case 'date':
          comparison = (a['created_at'] ?? '').toString().compareTo((b['created_at'] ?? '').toString());
          break;
        case 'rarity':
          final rarityOrder = {'common': 1, 'rare': 2, 'epic': 3, 'legendary': 4};
          comparison = (rarityOrder[a['rarity']] ?? 0).compareTo(rarityOrder[b['rarity']] ?? 0);
          break;
        case 'type':
          comparison = (a['type'] ?? '').toString().compareTo((b['type'] ?? '').toString());
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  Future<void> _refreshInventory() async {
    await rewardsService.refresh();
    setState(() {
      _page = 1;
      _isEndOfList = false;
      _items.clear();
    });
    
    await _loadItems();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _page = 1;
      _isEndOfList = false;
    });
    _applyFiltersAndSearch();
    _loadItems();
  }

  Future<void> _cacheInventoryData(List<Map<String, dynamic>> items) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String itemsJson = jsonEncode(items);
    prefs.setString('cached_inventory', itemsJson);
  }

  Future<void> _getEquippedAura() async {
    try {
      String? auraColor = await _auraService.fetchEquippedAura(widget.userId);
      setState(() {
        _selectedAuraColor = auraColor;
      });
    } catch (e) {
      print("Error fetching equipped aura: $e");
    }
  }

  Future<void> _equipAura(String auraColor) async {
    try {
      await _auraService.updateEquippedAura(widget.userId, auraColor);
      setState(() {
        _selectedAuraColor = auraColor;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Equipped $auraColor Aura')),
      );
    } catch (e) {
      print("Error equipping aura: $e");
    }
  }

  Future<void> _adoptPet(String petId) async {
    try {
      // Get the pet data
      final pet = PetUtils.getPetById(petId);
      if (pet == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet not found!')),
        );
        return;
      }

      // Update pet state if context has PetState provider
      if (context.mounted) {
        try {
          final petState = Provider.of<PetState>(context, listen: false);
          if (!petState.unlockedPets.contains(petId)) {
            petState.unlockedPets.add(petId);
            await petState.saveToSupabase(widget.userId);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${pet.name} has been adopted! 🎉')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${pet.name} is already adopted!')),
            );
          }
        } catch (e) {
          // PetState provider might not be available in this context
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${pet.name} is ready to be adopted!')),
          );
        }
      }
    } catch (e) {
      print("Error adopting pet: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error adopting pet')),
      );
    }
  }



  // Search dialog
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Inventory'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter search term...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: _onSearchChanged,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              _onSearchChanged('');
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Sort option handler
  void _handleSortOption(String option) {
    setState(() {
      switch (option) {
        case 'sort_name':
          _sortBy = 'name';
          break;
        case 'sort_date':
          _sortBy = 'date';
          break;
        case 'sort_rarity':
          _sortBy = 'rarity';
          break;
        case 'toggle_view':
          _showGridView = !_showGridView;
          break;
      }
      if (option.startsWith('sort_')) {
        _sortAscending = !_sortAscending;
        _applyFiltersAndSearch();
        _refreshInventory();
      }
    });
  }

  // Inventory options bottom sheet
  void _showInventoryOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Inventory Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.blue),
              title: const Text('Refresh Inventory'),
              onTap: () {
                Navigator.pop(context);
                _refreshInventory();
              },
            ),
            ListTile(
              leading: const Icon(Icons.clear_all, color: Colors.orange),
              title: const Text('Clear Search'),
              onTap: () {
                Navigator.pop(context);
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics, color: Colors.green),
              title: const Text('View Statistics'),
              onTap: () {
                Navigator.pop(context);
                _showInventoryStats();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Show inventory statistics
  void _showInventoryStats() {
    final stats = _calculateStats();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inventory Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Total Items', stats['total'].toString()),
            _buildStatRow('Auras', stats['aura'].toString()),
            _buildStatRow('Backgrounds', stats['background'].toString()),
            _buildStatRow('Pet Items', stats['pet_accessory'].toString()),
            _buildStatRow('Pets', stats['pet'].toString()),
            _buildStatRow('Accessories', stats['accessory'].toString()),
            _buildStatRow('Rarest Item', stats['rarest']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateStats() {
    final items = rewardsService.userInventory;
    Map<String, int> typeCounts = {};
    String rarest = 'common';
    
    for (var item in items) {
      String type = item['type'] ?? 'unknown';
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      
      String rarity = item['rarity'] ?? 'common';
      if (['legendary', 'epic', 'rare'].contains(rarity) && 
          ['legendary', 'epic', 'rare'].indexOf(rarity) < 
          ['legendary', 'epic', 'rare'].indexOf(rarest)) {
        rarest = rarity;
      }
    }

    return {
      'total': items.length,
      'aura': typeCounts['aura'] ?? 0,
      'background': typeCounts['background'] ?? 0,
      'pet_accessory': typeCounts['pet_accessory'] ?? 0,
      'pet': typeCounts['pet'] ?? 0,
      'accessory': typeCounts['accessory'] ?? 0,
      'rarest': rarest,
    };
  }

  @override
  Widget build(BuildContext context) {
    return RewardsProvider(
      userId: widget.userId,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF1F5),
        appBar: AppBar(
        backgroundColor: const Color(0xFFFFC1D9),
        elevation: 0,
        title: const Text("Your Inventory",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => _showSearchDialog(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.tune, color: Colors.white),
            onSelected: (value) => _handleSortOption(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sort_name',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha),
                    SizedBox(width: 8),
                    Text('Sort by Name'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sort_date',
                child: Row(
                  children: [
                    Icon(Icons.schedule),
                    SizedBox(width: 8),
                    Text('Sort by Date'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sort_rarity',
                child: Row(
                  children: [
                    Icon(Icons.star),
                    SizedBox(width: 8),
                    Text('Sort by Rarity'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'toggle_view',
                child: Row(
                  children: [
                    Icon(Icons.view_module),
                    SizedBox(width: 8),
                    Text('Toggle View'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _filters
              .map((filter) => Tab(
                icon: Icon(filter['icon']),
                text: filter['name'],
              ))
              .toList(),
        ),
      ),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Column(
                children: [
                  // Search bar (if search is active)
                  if (_searchQuery.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search your inventory...',
                          prefixIcon: const Icon(Icons.search, color: Colors.pink),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear, color: Colors.pink),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                    ),
                  
                  // Stats row
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: RewardsBuilder(
                      builder: (context, rewards) {
                        final totalItems = rewards.userInventory.length;
                        return Row(
                          children: [
                            _buildStatChip(
                              'Total Items',
                              totalItems.toString(),
                              Icons.inventory,
                              Colors.purple,
                            ),
                            const SizedBox(width: 12),
                            _buildStatChip(
                              'Filtered',
                              _filteredItems.length.toString(),
                              Icons.filter_list,
                              Colors.blue,
                            ),
                            const Spacer(),
                            // View toggle
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.pink.withOpacity(0.1),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.grid_view,
                                      color: _showGridView ? Colors.pink : Colors.grey,
                                    ),
                                    onPressed: () => setState(() => _showGridView = true),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.list,
                                      color: !_showGridView ? Colors.pink : Colors.grey,
                                    ),
                                    onPressed: () => setState(() => _showGridView = false),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  
                  // Main content
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refreshInventory,
                      color: Colors.pink,
                      child: RewardsBuilder(
                        builder: (context, rewards) {
                          // Use service inventory data or fallback to local items
                          final serviceInventory = rewards.userInventory;
                          final purchasedItems = serviceInventory.isNotEmpty ? serviceInventory : _items;

                          if (rewards.isLoading && purchasedItems.isEmpty) {
                            return const Center(
                              child: CircularProgressIndicator(color: Colors.pinkAccent),
                            );
                          }

                          if (rewards.error != null) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                                  const SizedBox(height: 16),
                                  Text('Error: ${rewards.error}'),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: _refreshInventory,
                                    child: const Text("Retry"),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (purchasedItems.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 80,
                                    color: Colors.pink.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No items in your inventory",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.pink.withOpacity(0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Visit the shop to get some items!",
                                    style: TextStyle(
                                      color: Colors.pink.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return _showGridView ? _buildGridView(purchasedItems) : _buildListView(purchasedItems);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton(
          onPressed: () => _showInventoryOptions(),
          backgroundColor: Colors.pink,
          child: const Icon(Icons.more_vert, color: Colors.white),
        ),
      ),
      ),
    );
  }

  // Helper methods for the enhanced UI
  Widget _buildStatChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
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

  Widget _buildGridView(List<Map<String, dynamic>> items) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.pinkAccent),
          );
        }

        final item = items[index];
        return _buildInventoryItem(item, index);
      },
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> items) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: items.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: Colors.pinkAccent),
            ),
          );
        }

        final item = items[index];
        return _buildInventoryListItem(item, index);
      },
    );
  }

  Widget _buildInventoryItem(Map<String, dynamic> item, int index) {
    final auraColor = item['aura_color'];
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutBack,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showItemDetails(item),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    image: item['image_url'] != null
                        ? DecorationImage(
                            image: NetworkImage(item['image_url']),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: item['image_url'] == null ? Colors.grey[200] : null,
                  ),
                  child: item['image_url'] == null
                      ? const Icon(Icons.image_not_supported, color: Colors.grey)
                      : null,
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] ?? 'Unknown Item',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (item['type'] == 'aura' && auraColor != null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pinkAccent,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              textStyle: const TextStyle(fontSize: 10),
                            ),
                            onPressed: () => _equipAura(auraColor),
                            child: Text(
                              _selectedAuraColor == auraColor ? 'Equipped' : 'Equip',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryListItem(Map<String, dynamic> item, int index) {
    final auraColor = item['aura_color'];
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutBack,
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: item['image_url'] != null
                  ? DecorationImage(
                      image: NetworkImage(item['image_url']),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: item['image_url'] == null ? Colors.grey[200] : null,
            ),
            child: item['image_url'] == null
                ? const Icon(Icons.image_not_supported, color: Colors.grey)
                : null,
          ),
          title: Text(
            item['name'] ?? 'Unknown Item',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type: ${item['type'] ?? 'Unknown'}'),
              if (item['rarity'] != null)
                Text('Rarity: ${item['rarity']}'),
            ],
          ),
          trailing: item['type'] == 'aura' && auraColor != null
              ? ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () => _equipAura(auraColor),
                  child: Text(
                    _selectedAuraColor == auraColor ? 'Equipped' : 'Equip',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                )
              : item['type'] == 'pet'
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onPressed: () => _adoptPet(item['pet_id'] ?? item['id'] ?? ''),
                      child: const Text(
                        'Adopt',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    )
                  : const Icon(Icons.chevron_right),
          onTap: () => _showItemDetails(item),
        ),
      ),
    );
  }

  void _showItemDetails(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['name'] ?? 'Item Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item['image_url'] != null)
              Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(item['image_url']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _buildDetailRow('Type', item['type'] ?? 'Unknown'),
            _buildDetailRow('Rarity', item['rarity'] ?? 'Common'),
            if (item['description'] != null)
              _buildDetailRow('Description', item['description']),
            if (item['aura_color'] != null)
              _buildDetailRow('Aura Color', item['aura_color']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (item['type'] == 'aura' && item['aura_color'] != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _equipAura(item['aura_color']);
              },
              child: Text(
                _selectedAuraColor == item['aura_color'] ? 'Equipped' : 'Equip',
              ),
            ),
          if (item['type'] == 'pet')
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: () {
                Navigator.pop(context);
                _adoptPet(item['pet_id'] ?? item['id'] ?? '');
              },
              child: const Text('Adopt Pet'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
