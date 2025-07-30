import 'package:flutter/material.dart';

class LazyShopGrid extends StatefulWidget {
  final List<ShopItem> shopItems;
  final Function(ShopItem)? onItemTap;
  
  const LazyShopGrid({
    Key? key,
    required this.shopItems,
    this.onItemTap,
  }) : super(key: key);
  
  @override
  State<LazyShopGrid> createState() => _LazyShopGridState();
}

class _LazyShopGridState extends State<LazyShopGrid> {
  final ScrollController _scrollController = ScrollController();
  final List<ShopItem> _loadedItems = [];
  int _currentPage = 0;
  static const int _itemsPerPage = 20;
  bool _isLoading = false;
  bool _hasMoreItems = true;
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMoreItems();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }
  
  Future<void> _loadMoreItems() async {
    if (_isLoading || !_hasMoreItems) return;
    
    setState(() {
      _isLoading = true;
    });
    
    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, widget.shopItems.length);
    
    if (startIndex >= widget.shopItems.length) {
      setState(() {
        _hasMoreItems = false;
        _isLoading = false;
      });
      return;
    }
    
    final newItems = widget.shopItems.sublist(startIndex, endIndex);
    
    setState(() {
      _loadedItems.addAll(newItems);
      _currentPage++;
      _isLoading = false;
      _hasMoreItems = endIndex < widget.shopItems.length;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshItems,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < _loadedItems.length) {
                  return LazyShopItemCard(
                    item: _loadedItems[index],
                    onTap: () => widget.onItemTap?.call(_loadedItems[index]),
                  );
                }
                return null;
              },
              childCount: _loadedItems.length,
            ),
          ),
          
          // Loading indicator
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          
          // End message
          if (!_hasMoreItems && _loadedItems.isNotEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    '✨ You\'ve seen all items!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Future<void> _refreshItems() async {
    setState(() {
      _loadedItems.clear();
      _currentPage = 0;
      _hasMoreItems = true;
    });
    await _loadMoreItems();
  }
}

class LazyShopItemCard extends StatelessWidget {
  final ShopItem item;
  final VoidCallback? onTap;
  
  const LazyShopItemCard({
    Key? key,
    required this.item,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lazy loaded image
            LazyShopImage(
              imagePath: item.imagePath,
              height: 120,
            ),
            
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${item.price}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (item.discount > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${item.discount}% OFF',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LazyShopImage extends StatefulWidget {
  final String imagePath;
  final double? height;
  final double? width;
  
  const LazyShopImage({
    Key? key,
    required this.imagePath,
    this.height,
    this.width,
  }) : super(key: key);
  
  @override
  State<LazyShopImage> createState() => _LazyShopImageState();
}

class _LazyShopImageState extends State<LazyShopImage> {
  bool _isInView = false;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height ?? 120,
      width: widget.width ?? double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: _isInView
          ? ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: Image.asset(
                widget.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              ),
            )
          : InkWell(
              onTap: () {
                setState(() {
                  _isInView = true;
                });
              },
              child: const Center(
                child: Icon(Icons.image, color: Colors.grey),
              ),
            ),
    );
  }
}

// Data models
class ShopItem {
  final String id;
  final String name;
  final double price;
  final String imagePath;
  final int discount;
  final String category;
  
  ShopItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imagePath,
    this.discount = 0,
    required this.category,
  });
}
