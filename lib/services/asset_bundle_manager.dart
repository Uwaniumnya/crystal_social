import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// Manages organized asset bundles for better performance
class AssetBundleManager {
  static const String _manifestPath = 'AssetManifest.json';
  static Map<String, dynamic>? _manifest;
  static final Map<String, List<String>> _categoryCache = {};
  
  /// Initialize the asset manager
  static Future<void> initialize() async {
    if (_manifest != null) return;
    
    try {
      final manifestString = await rootBundle.loadString(_manifestPath);
      _manifest = json.decode(manifestString);
      _organizeAssets();
    } catch (e) {
      print('❌ Failed to load asset manifest: $e');
      _manifest = {};
    }
  }
  
  /// Organize assets by category
  static void _organizeAssets() {
    if (_manifest == null) return;
    
    for (final assetPath in _manifest!.keys) {
      if (assetPath.startsWith('assets/')) {
        final parts = assetPath.split('/');
        if (parts.length >= 3) {
          final category = parts[1]; // e.g., 'tarot', 'shop', 'pets'
          
          _categoryCache.putIfAbsent(category, () => []);
          _categoryCache[category]!.add(assetPath);
        }
      }
    }
    
    print('📦 Organized ${_categoryCache.length} asset categories');
  }
  
  /// Get all assets for a specific category
  static List<String> getAssetsByCategory(String category) {
    return _categoryCache[category] ?? [];
  }
  
  /// Get categories with their asset counts
  static Map<String, int> getCategoryCounts() {
    return _categoryCache.map((key, value) => MapEntry(key, value.length));
  }
  
  /// Get assets matching a pattern
  static List<String> getAssetsMatching(String pattern) {
    if (_manifest == null) return [];
    
    final regex = RegExp(pattern);
    return _manifest!.keys
        .where((path) => regex.hasMatch(path))
        .cast<String>()
        .toList();
  }
  
  /// Preload specific asset category
  static Future<void> preloadCategory(String category) async {
    final assets = getAssetsByCategory(category);
    final futures = <Future>[];
    
    for (final assetPath in assets.take(10)) { // Limit to first 10
      if (_isImageAsset(assetPath)) {
        futures.add(precacheImage(AssetImage(assetPath), 
            WidgetsBinding.instance.rootElement!));
      }
    }
    
    await Future.wait(futures);
    print('✅ Preloaded $category assets');
  }
  
  /// Check if asset exists
  static bool assetExists(String path) {
    return _manifest?.containsKey(path) ?? false;
  }
  
  /// Get optimized asset path (returns compressed version if available)
  static String getOptimizedAssetPath(String originalPath) {
    // Check for WebP version first
    final webpPath = originalPath.replaceAll(RegExp(r'\.(png|jpg|jpeg)$'), '.webp');
    if (assetExists(webpPath)) {
      return webpPath;
    }
    
    // Check for compressed version
    final compressedPath = originalPath.replaceAll('/', '/compressed/');
    if (assetExists(compressedPath)) {
      return compressedPath;
    }
    
    return originalPath;
  }
  
  static bool _isImageAsset(String path) {
    final imageExtensions = ['.png', '.jpg', '.jpeg', '.gif', '.webp'];
    return imageExtensions.any((ext) => path.toLowerCase().endsWith(ext));
  }
}

/// Widget for efficiently displaying categorized assets
class CategoryAssetGrid extends StatefulWidget {
  final String category;
  final Function(String)? onAssetTap;
  final int crossAxisCount;
  
  const CategoryAssetGrid({
    Key? key,
    required this.category,
    this.onAssetTap,
    this.crossAxisCount = 3,
  }) : super(key: key);
  
  @override
  State<CategoryAssetGrid> createState() => _CategoryAssetGridState();
}

class _CategoryAssetGridState extends State<CategoryAssetGrid> {
  List<String> _assets = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadAssets();
  }
  
  Future<void> _loadAssets() async {
    await AssetBundleManager.initialize();
    
    setState(() {
      _assets = AssetBundleManager.getAssetsByCategory(widget.category);
      _isLoading = false;
    });
    
    // Preload first few assets
    AssetBundleManager.preloadCategory(widget.category);
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_assets.isEmpty) {
      return Center(
        child: Text('No assets found for ${widget.category}'),
      );
    }
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _assets.length,
      itemBuilder: (context, index) {
        final assetPath = _assets[index];
        final optimizedPath = AssetBundleManager.getOptimizedAssetPath(assetPath);
        
        return OptimizedAssetImage(
          assetPath: optimizedPath,
          onTap: () => widget.onAssetTap?.call(assetPath),
        );
      },
    );
  }
}

/// Optimized asset image widget
class OptimizedAssetImage extends StatefulWidget {
  final String assetPath;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  
  const OptimizedAssetImage({
    Key? key,
    required this.assetPath,
    this.onTap,
    this.width,
    this.height,
  }) : super(key: key);
  
  @override
  State<OptimizedAssetImage> createState() => _OptimizedAssetImageState();
}

class _OptimizedAssetImageState extends State<OptimizedAssetImage> {
  bool _isLoaded = false;
  bool _hasError = false;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _hasError
              ? const Icon(Icons.broken_image, color: Colors.red)
              : Image.asset(
                  widget.assetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _hasError = true;
                        });
                      }
                    });
                    return const Icon(Icons.broken_image, color: Colors.red);
                  },
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded || frame != null) {
                      if (!_isLoaded) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _isLoaded = true;
                            });
                          }
                        });
                      }
                      return child;
                    }
                    return const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

/// Asset bundle information widget
class AssetBundleInfo extends StatefulWidget {
  const AssetBundleInfo({Key? key}) : super(key: key);
  
  @override
  State<AssetBundleInfo> createState() => _AssetBundleInfoState();
}

class _AssetBundleInfoState extends State<AssetBundleInfo> {
  Map<String, int> _categoryCounts = {};
  
  @override
  void initState() {
    super.initState();
    _loadInfo();
  }
  
  Future<void> _loadInfo() async {
    await AssetBundleManager.initialize();
    setState(() {
      _categoryCounts = AssetBundleManager.getCategoryCounts();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Asset Bundle Overview',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            ..._categoryCounts.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key),
                  Text('${entry.value} assets'),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
