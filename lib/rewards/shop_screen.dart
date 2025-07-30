import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'rewards_provider.dart';


class ShopScreen extends StatefulWidget {
  final String userId;
  final SupabaseClient supabase;

  const ShopScreen({super.key, required this.userId, required this.supabase});

  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin, RewardsMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  int _page = 1;
  final int _itemsPerPage = 10;
  bool _isLoading = false;
  bool _isInitialLoading = true;
  final List<Map<String, dynamic>> _items = [];
  List<int> _ownedItemIds = [];
  List<int> _wishlistItemIds = [];
  late TabController _tabController;
  late AnimationController _animationController;
  
  int _selectedCategoryId = 1;
  String _searchQuery = '';
  String _selectedSort = 'name_asc';
  int _minPrice = 0;
  int _maxPrice = 1000;
  bool _showOnlyAffordable = false;

  final List<Map<String, dynamic>> _categories = [
    {'id': 1, 'name': 'Aura'},
    {'id': 2, 'name': 'Background'},
    {'id': 3, 'name': 'Pet'},
    {'id': 7, 'name': 'Booster'},
    {'id': 8, 'name': 'Decorations'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedCategoryId = _categories[_tabController.index]['id'];
          _items.clear();
          _page = 1;
          _searchQuery = '';
          _searchController.clear();
        });
        _loadItems();
      }
    });
    
    _searchController.addListener(() {
      _filterItems();
    });
    
    _initializeShop();
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadItems();
      }
    });
  }

  Future<void> _initializeShop() async {
    await initializeRewards(widget.userId);
    await _loadUserInfo();
    await _loadItems();
    await _loadWishlist();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _giveHapticFeedback() {
    HapticFeedback.selectionClick();
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      _isInitialLoading = true;
    });
    
    try {
      final owned = rewardsService.userInventory;
      setState(() {
        _ownedItemIds = owned.map<int>((item) => item['id'] as int? ?? 0).toList();
        _isInitialLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading user info: $e');
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadWishlist() async {
    // Load wishlist from local storage or database
    // For now, we'll simulate with empty list
    setState(() {
      _wishlistItemIds = [];
    });
  }

  void _filterItems() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  List<Map<String, dynamic>> _getFilteredItems() {
    List<Map<String, dynamic>> filtered = List.from(_items);
    
    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        return item['name'].toString().toLowerCase().contains(_searchQuery);
      }).toList();
    }
    
    // Price range filter
    filtered = filtered.where((item) {
      int price = item['price'] ?? 0;
      return price >= _minPrice && price <= _maxPrice;
    }).toList();
    
    // Affordable filter
    if (_showOnlyAffordable) {
      final currentCoins = rewardsService.userRewards['coins'] ?? 0;
      filtered = filtered.where((item) {
        return item['price'] <= currentCoins;
      }).toList();
    }
    
    // Sort
    switch (_selectedSort) {
      case 'name_asc':
        filtered.sort((a, b) => a['name'].compareTo(b['name']));
        break;
      case 'name_desc':
        filtered.sort((a, b) => b['name'].compareTo(a['name']));
        break;
      case 'price_asc':
        filtered.sort((a, b) => (a['price'] ?? 0).compareTo(b['price'] ?? 0));
        break;
      case 'price_desc':
        filtered.sort((a, b) => (b['price'] ?? 0).compareTo(a['price'] ?? 0));
        break;
      case 'rarity':
        filtered.sort((a, b) => _getRarityWeight(b['rarity']).compareTo(_getRarityWeight(a['rarity'])));
        break;
    }
    
    return filtered;
  }

  int _getRarityWeight(String? rarity) {
    switch (rarity?.toLowerCase()) {
      case 'legendary': return 4;
      case 'epic': return 3;
      case 'rare': return 2;
      case 'common': return 1;
      default: return 0;
    }
  }

  void _toggleWishlist(int itemId) {
    setState(() {
      if (_wishlistItemIds.contains(itemId)) {
        _wishlistItemIds.remove(itemId);
      } else {
        _wishlistItemIds.add(itemId);
      }
    });
    _giveHapticFeedback();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Color(0xFFFFF1F5),
              title: Text('Filter & Sort', style: TextStyle(color: Colors.pink.shade700)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sort options
                    Text('Sort by:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    DropdownButton<String>(
                      value: _selectedSort,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(value: 'name_asc', child: Text('Name (A-Z)')),
                        DropdownMenuItem(value: 'name_desc', child: Text('Name (Z-A)')),
                        DropdownMenuItem(value: 'price_asc', child: Text('Price (Low to High)')),
                        DropdownMenuItem(value: 'price_desc', child: Text('Price (High to Low)')),
                        DropdownMenuItem(value: 'rarity', child: Text('Rarity')),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedSort = value!;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Price range
                    Text('Price range:', style: TextStyle(fontWeight: FontWeight.bold)),
                    RangeSlider(
                      values: RangeValues(_minPrice.toDouble(), _maxPrice.toDouble()),
                      min: 0,
                      max: 1000,
                      divisions: 20,
                      labels: RangeLabels(_minPrice.toString(), _maxPrice.toString()),
                      onChanged: (values) {
                        setDialogState(() {
                          _minPrice = values.start.round();
                          _maxPrice = values.end.round();
                        });
                      },
                    ),
                    
                    // Show only affordable
                    CheckboxListTile(
                      title: Text('Show only affordable'),
                      value: _showOnlyAffordable,
                      onChanged: (value) {
                        setDialogState(() {
                          _showOnlyAffordable = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pink.shade400),
                  child: Text('Apply', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showItemDetails(Map<String, dynamic> item) {
    final isOwned = _ownedItemIds.contains(item['id']);
    final isWishlisted = _wishlistItemIds.contains(item['id']);
    final rarityColor = _getRarityColor(item['rarity']);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFFFFF1F5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: rarityColor, width: 3),
            ),
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Item image
                Hero(
                  tag: 'item_${item['id']}',
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: rarityColor.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        item['image_url'],
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                
                // Item name
                Text(
                  item['name'],
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                
                // Rarity badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: rarityColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item['rarity']?.toUpperCase() ?? 'COMMON',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                
                // Description
                if (item['description'] != null)
                  Text(
                    item['description'],
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                SizedBox(height: 16),
                
                // Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.monetization_on, color: Colors.orange),
                    SizedBox(width: 4),
                    Text(
                      '${item['price']} Coins',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Wishlist button
                    IconButton(
                      onPressed: () => _toggleWishlist(item['id']),
                      icon: Icon(
                        isWishlisted ? Icons.favorite : Icons.favorite_border,
                        color: isWishlisted ? Colors.red : Colors.grey,
                        size: 28,
                      ),
                    ),
                    
                    // Purchase button
                    if (isOwned)
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.green.shade200,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          "Owned",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _confirmPurchase(item);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink.shade400,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text("Purchase", style: TextStyle(fontSize: 16)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmPurchase(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFFFFF1F5),
          title: Text('Confirm Purchase'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Are you sure you want to purchase "${item['name']}"?'),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monetization_on, color: Colors.orange),
                  SizedBox(width: 4),
                  Text(
                    '${item['price']} Coins',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                'Remaining balance: ${(rewardsService.userRewards['coins'] ?? 0) - item['price']} coins',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink.shade400),
              child: Text('Purchase', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _giveHapticFeedback();
      
      try {
        bool success;
        if (item['category_id'] == 7) {
          // For booster packs, use openBoosterPack method
          final items = await rewardsService.openBoosterPack(item);
          success = items != null;
        } else {
          // For regular items, use purchaseItem method
          success = await rewardsService.purchaseItem(item, context);
        }
        
        if (success) {
          _showSparkleEffect();
          await _loadUserInfo();
          showPurchaseSuccess(item['name']);
        } else {
          showPurchaseError('Purchase failed');
        }
      } catch (e) {
        showPurchaseError(e.toString());
      }
    }
  }

  Future<void> _loadItems() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final newItems = await rewardsService.rewardsManager.getShopItemsByCategoryWithPagination(
        _selectedCategoryId,
        _page,
        _itemsPerPage,
      );

      setState(() {
        _isLoading = false;
        _page++;
        _items.addAll(newItems);
      });
    } catch (e) {
      debugPrint('Error loading items: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getRarityColor(String? rarity) {
    switch (rarity?.toLowerCase()) {
      case 'common':
        return Colors.grey;
      case 'rare':
        return Colors.blue;
      case 'epic':
        return Colors.purple;
      case 'legendary':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showSparkleEffect() {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => Center(
        child: Icon(Icons.auto_awesome, color: Colors.pinkAccent, size: 100),
      ),
    );
    Future.delayed(Duration(milliseconds: 1000), () {
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _getFilteredItems();
    
    return Scaffold(
      backgroundColor: Color(0xFFFFF1F5),
      appBar: AppBar(
        backgroundColor: Color(0xFFFFC1D9),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Crystal Shop",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            RewardsBuilder(
              builder: (context, rewards) {
                final coins = rewards.userRewards['coins'] ?? 0;
                return Row(
                  children: [
                    Icon(Icons.monetization_on, color: Colors.yellowAccent),
                    SizedBox(width: 4),
                    Text('$coins',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                );
              },
              loadingWidget: Row(
                children: [
                  Icon(Icons.monetization_on, color: Colors.yellowAccent),
                  SizedBox(width: 4),
                  Text('...',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(140),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Search items...',
                          prefixIcon: Icon(Icons.search, color: Colors.pink.shade300),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      onPressed: _showFilterDialog,
                      icon: Icon(Icons.tune, color: Colors.white, size: 28),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.pink.shade300,
                        shape: CircleBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Category tabs
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: _categories.map((c) => Tab(text: c['name'].toUpperCase())).toList(),
              ),
            ],
          ),
        ),
      ),
      body: _isInitialLoading 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.pinkAccent),
                SizedBox(height: 16),
                Text(
                  'Loading shop items...',
                  style: TextStyle(color: Colors.pink.shade300, fontSize: 16),
                ),
              ],
            ),
          )
        : filteredItems.isEmpty && _searchQuery.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Colors.pink.shade200,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No items found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.pink.shade300,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Try adjusting your search or filters',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _items.clear();
                  _page = 1;
                });
                await refreshRewards();
                await _loadItems();
                await _loadUserInfo();
              },
              color: Colors.pinkAccent,
              child: GridView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 0.8,
                ),
                itemCount: filteredItems.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == filteredItems.length) {
                    return Center(
                      child: CircularProgressIndicator(color: Colors.pinkAccent),
                    );
                  }

                  final item = filteredItems[index];
                  final isOwned = _ownedItemIds.contains(item['id']);
                  final isWishlisted = _wishlistItemIds.contains(item['id']);
                  final rarityColor = _getRarityColor(item['rarity']);
                  final canAfford = (rewardsService.userRewards['coins'] ?? 0) >= item['price'];

                  return GestureDetector(
                    onTap: () => _showItemDetails(item),
                    child: Hero(
                      tag: 'item_${item['id']}',
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(
                              color: rarityColor,
                              width: 3,
                            ),
                          ),
                          color: Color(0xFFFFDDE4),
                          shadowColor: Colors.pink.withOpacity(0.3),
                          child: Stack(
                            children: [
                              // Main content
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Item image
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.network(
                                            item['image_url'],
                                            height: 80,
                                            width: 80,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Container(
                                                height: 80,
                                                width: 80,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Center(
                                                  child: CircularProgressIndicator(
                                                    color: Colors.pinkAccent,
                                                    strokeWidth: 2,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        // Rarity indicator
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: Container(
                                            padding: EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: rarityColor,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.auto_awesome,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    
                                    // Item name
                                    Text(
                                      item['name'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.pink.shade700,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 4),
                                    
                                    // Price
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.monetization_on,
                                          color: canAfford ? Colors.orange : Colors.red,
                                          size: 16,
                                        ),
                                        SizedBox(width: 2),
                                        Text(
                                          '${item['price']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: canAfford ? Colors.orange : Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    
                                    // Status/Action button
                                    if (isOwned)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 4, horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade200,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          "Owned",
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      )
                                    else
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: canAfford ? () async {
                                            await _confirmPurchase(item);
                                          } : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: canAfford 
                                              ? Colors.pink.shade400 
                                              : Colors.grey.shade300,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            padding: EdgeInsets.symmetric(vertical: 8),
                                          ),
                                          child: Text(
                                            canAfford ? "Buy" : "Need ${item['price'] - (rewardsService.userRewards['coins'] ?? 0)}",
                                            style: TextStyle(fontSize: 10),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              
                              // Wishlist button
                              Positioned(
                                top: 8,
                                left: 8,
                                child: GestureDetector(
                                  onTap: () => _toggleWishlist(item['id']),
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isWishlisted ? Icons.favorite : Icons.favorite_border,
                                      color: isWishlisted ? Colors.red : Colors.grey,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Sold out overlay (if needed)
                              if (!canAfford && !isOwned)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
