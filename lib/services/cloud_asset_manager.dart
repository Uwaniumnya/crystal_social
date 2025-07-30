import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class CloudAssetManager {
  static const String TAROT_BUCKET = 'tarot-cards';
  static const String SHOP_BUCKET = 'shop-items';
  
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Cache for downloaded assets
  static final Map<String, String> _localCache = {};
  
  /// Upload tarot assets to Supabase Storage
  Future<bool> uploadTarotAssets() async {
    try {
      final tarotDir = Directory('assets/tarot');
      if (!await tarotDir.exists()) return false;
      
      final files = await tarotDir.list(recursive: true).toList();
      
      for (final file in files) {
        if (file is File && _isImageFile(file.path)) {
          final relativePath = file.path.replaceFirst('assets/tarot/', '');
          
          // Compress before upload
          final compressedBytes = await _compressImage(file);
          
          await _supabase.storage
              .from(TAROT_BUCKET)
              .uploadBinary(relativePath, Uint8List.fromList(compressedBytes));
          
          print('✅ Uploaded: $relativePath');
        }
      }
      
      return true;
    } catch (e) {
      print('❌ Upload failed: $e');
      return false;
    }
  }
  
  /// Get tarot card image with caching
  Future<String?> getTarotCardUrl(String cardName) async {
    try {
      // Check local cache first
      if (_localCache.containsKey(cardName)) {
        final cachedPath = _localCache[cardName]!;
        if (await File(cachedPath).exists()) {
          return cachedPath;
        }
      }
      
      // Download from cloud
      final response = await _supabase.storage
          .from(TAROT_BUCKET)
          .download('$cardName.webp');
      
      // Save to local cache
      final localPath = await _saveToCache(cardName, response);
      _localCache[cardName] = localPath;
      
      return localPath;
    } catch (e) {
      print('❌ Failed to get tarot card: $e');
      return null;
    }
  }
  
  /// Save downloaded asset to local cache
  Future<String> _saveToCache(String assetName, List<int> bytes) async {
    final cacheDir = await getTemporaryDirectory();
    final assetCacheDir = Directory('${cacheDir.path}/asset_cache');
    
    if (!await assetCacheDir.exists()) {
      await assetCacheDir.create(recursive: true);
    }
    
    final file = File('${assetCacheDir.path}/$assetName.webp');
    await file.writeAsBytes(bytes);
    
    return file.path;
  }
  
  /// Compress image to WebP format
  Future<List<int>> _compressImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) return bytes;
      
      // Resize if too large (max 1024px width)
      final resized = image.width > 1024 
          ? img.copyResize(image, width: 1024)
          : image;
      
      // Convert to JPG with 85% quality (WebP not available in current image package)
      final compressedBytes = img.encodeJpg(resized, quality: 85);
      
      print('📦 Compressed ${imageFile.path}: ${bytes.length} → ${compressedBytes.length} bytes');
      
      return compressedBytes;
    } catch (e) {
      print('⚠️ Compression failed for ${imageFile.path}: $e');
      return await imageFile.readAsBytes();
    }
  }
  
  bool _isImageFile(String path) {
    final extensions = ['.png', '.jpg', '.jpeg', '.gif', '.webp'];
    return extensions.any((ext) => path.toLowerCase().endsWith(ext));
  }
}

/// Widget for cloud-based tarot cards
class CloudTarotCard extends StatefulWidget {
  final String cardName;
  final double? width;
  final double? height;
  
  const CloudTarotCard({
    Key? key,
    required this.cardName,
    this.width,
    this.height,
  }) : super(key: key);
  
  @override
  State<CloudTarotCard> createState() => _CloudTarotCardState();
}

class _CloudTarotCardState extends State<CloudTarotCard> {
  String? _imagePath;
  bool _isLoading = true;
  bool _hasError = false;
  
  @override
  void initState() {
    super.initState();
    _loadImage();
  }
  
  Future<void> _loadImage() async {
    try {
      final cloudManager = CloudAssetManager();
      final imagePath = await cloudManager.getTarotCardUrl(widget.cardName);
      
      if (mounted) {
        setState(() {
          _imagePath = imagePath;
          _isLoading = false;
          _hasError = imagePath == null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.width ?? 100,
        height: widget.height ?? 150,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_hasError || _imagePath == null) {
      return Container(
        width: widget.width ?? 100,
        height: widget.height ?? 150,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.error, color: Colors.red),
      );
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(_imagePath!),
        width: widget.width,
        height: widget.height,
        fit: BoxFit.cover,
      ),
    );
  }
}
