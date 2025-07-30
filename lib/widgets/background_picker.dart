import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

/// Enhanced Chat Background Picker with presets, effects, and advanced customization
class EnhancedChatBackgroundPicker extends StatefulWidget {
  final String chatId;
  final Function(String?)? onBackgroundChanged;
  final bool showPresets;
  final bool showEffects;
  final bool showCustomization;
  final bool enableCloudSync;
  final Color? primaryColor;
  final Color? backgroundColor;
  final List<String>? customPresets;

  const EnhancedChatBackgroundPicker({
    super.key,
    required this.chatId,
    this.onBackgroundChanged,
    this.showPresets = true,
    this.showEffects = true,
    this.showCustomization = true,
    this.enableCloudSync = true,
    this.primaryColor,
    this.backgroundColor,
    this.customPresets,
  });

  @override
  State<EnhancedChatBackgroundPicker> createState() => _EnhancedChatBackgroundPickerState();
}

class _EnhancedChatBackgroundPickerState extends State<EnhancedChatBackgroundPicker>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  String? _backgroundUrl;
  File? _backgroundFile;
  String? _selectedPreset;
  double _opacity = 1.0;
  double _blur = 0.0;
  String _selectedEffect = 'none';
  bool _isUploading = false;
  bool _isLoading = false;
  
  final List<String> _recentBackgrounds = [];
  final Set<String> _favoritePresets = {};

  // Predefined background presets
  static const List<BackgroundPreset> _presetBackgrounds = [
    BackgroundPreset(
      id: 'gradient_sunset',
      name: 'Sunset Gradient',
      type: BackgroundType.gradient,
      gradient: LinearGradient(
        colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D), Color(0xFF4ECDC4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      emoji: '🌅',
    ),
    BackgroundPreset(
      id: 'gradient_ocean',
      name: 'Ocean Waves',
      type: BackgroundType.gradient,
      gradient: LinearGradient(
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      emoji: '🌊',
    ),
    BackgroundPreset(
      id: 'gradient_forest',
      name: 'Forest Dream',
      type: BackgroundType.gradient,
      gradient: LinearGradient(
        colors: [Color(0xFF134E5E), Color(0xFF71B280)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      emoji: '🌲',
    ),
    BackgroundPreset(
      id: 'gradient_cherry',
      name: 'Cherry Blossom',
      type: BackgroundType.gradient,
      gradient: LinearGradient(
        colors: [Color(0xFFFFB6C1), Color(0xFFFFE4E1), Color(0xFFFFB6C1)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      emoji: '🌸',
    ),
    BackgroundPreset(
      id: 'gradient_space',
      name: 'Space Nebula',
      type: BackgroundType.gradient,
      gradient: LinearGradient(
        colors: [Color(0xFF2C3E50), Color(0xFF4A00E0), Color(0xFF8E2DE2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      emoji: '🌌',
    ),
    BackgroundPreset(
      id: 'gradient_aurora',
      name: 'Aurora Lights',
      type: BackgroundType.gradient,
      gradient: LinearGradient(
        colors: [Color(0xFF00C9FF), Color(0xFF92FE9D), Color(0xFFFFE6E6)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      emoji: '🌠',
    ),
    BackgroundPreset(
      id: 'solid_lavender',
      name: 'Soft Lavender',
      type: BackgroundType.solid,
      color: Color(0xFFE6E6FA),
      emoji: '💜',
    ),
    BackgroundPreset(
      id: 'solid_mint',
      name: 'Fresh Mint',
      type: BackgroundType.solid,
      color: Color(0xFFF0FFF0),
      emoji: '🌿',
    ),
    BackgroundPreset(
      id: 'solid_peach',
      name: 'Warm Peach',
      type: BackgroundType.solid,
      color: Color(0xFFFFDAB9),
      emoji: '🍑',
    ),
    BackgroundPreset(
      id: 'pattern_hearts',
      name: 'Floating Hearts',
      type: BackgroundType.pattern,
      pattern: 'hearts',
      color: Color(0xFFFFB6C1),
      emoji: '💕',
    ),
    BackgroundPreset(
      id: 'pattern_stars',
      name: 'Starry Night',
      type: BackgroundType.pattern,
      pattern: 'stars',
      color: Color(0xFF191970),
      emoji: '⭐',
    ),
    BackgroundPreset(
      id: 'pattern_bubbles',
      name: 'Soap Bubbles',
      type: BackgroundType.pattern,
      pattern: 'bubbles',
      color: Color(0xFFB0E0E6),
      emoji: '🫧',
    ),
  ];

  static const List<String> _effectTypes = [
    'none',
    'blur',
    'sepia',
    'grayscale',
    'vintage',
    'warm',
    'cool',
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize tab controller
    _tabController = TabController(length: 4, vsync: this);
    
    // Initialize pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticOut),
    );
    
    _loadBackground();
    _loadUserPreferences();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadBackground() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final res = await Supabase.instance.client
          .from('chats')
          .select('background_url, background_preset, background_opacity, background_blur, background_effect')
          .eq('chat_id', widget.chatId)
          .maybeSingle();

      if (res != null && mounted) {
        setState(() {
          _backgroundUrl = res['background_url'] as String?;
          _selectedPreset = res['background_preset'] as String?;
          _opacity = (res['background_opacity'] as num?)?.toDouble() ?? 1.0;
          _blur = (res['background_blur'] as num?)?.toDouble() ?? 0.0;
          _selectedEffect = res['background_effect'] as String? ?? 'none';
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load background: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final recent = prefs.getStringList('chat_recent_backgrounds') ?? [];
    final favorites = prefs.getStringList('chat_favorite_presets') ?? [];
    
    setState(() {
      _recentBackgrounds.addAll(recent);
      _favoritePresets.addAll(favorites);
    });
  }

  Future<void> _saveUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('chat_recent_backgrounds', _recentBackgrounds);
    await prefs.setStringList('chat_favorite_presets', _favoritePresets.toList());
  }

  Future<void> _pickAndUploadBackground({ImageSource source = ImageSource.gallery}) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (picked == null) return;

      final file = File(picked.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(picked.path)}';
      final storagePath = 'chat_backgrounds/${widget.chatId}/$fileName';

      // Trigger pulse animation
      _pulseController.forward().then((_) {
        _pulseController.reverse();
      });

      final storageRes = await Supabase.instance.client.storage
          .from('chat_backgrounds')
          .upload(storagePath, file,
              fileOptions: const FileOptions(upsert: true));

      if (storageRes.isNotEmpty) {
        final url = Supabase.instance.client.storage
            .from('chat_backgrounds')
            .getPublicUrl(storagePath);

        await _updateBackground(
          backgroundUrl: url,
          backgroundPreset: null,
        );

        // Add to recent backgrounds
        if (!_recentBackgrounds.contains(url)) {
          setState(() {
            _recentBackgrounds.insert(0, url);
            if (_recentBackgrounds.length > 10) {
              _recentBackgrounds.removeLast();
            }
          });
          await _saveUserPreferences();
        }

        setState(() {
          _backgroundFile = file;
          _backgroundUrl = url;
          _selectedPreset = null;
        });

        widget.onBackgroundChanged?.call(url);
        _showSuccessSnackBar("Background updated successfully! ✨");
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to upload background: ${e.toString()}');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _updateBackground({
    String? backgroundUrl,
    String? backgroundPreset,
  }) async {
    final updateData = {
      'background_url': backgroundUrl,
      'background_preset': backgroundPreset,
      'background_opacity': _opacity,
      'background_blur': _blur,
      'background_effect': _selectedEffect,
    };

    await Supabase.instance.client
        .from('chats')
        .update(updateData)
        .eq('chat_id', widget.chatId);
  }

  void _selectPreset(BackgroundPreset preset) async {
    setState(() {
      _selectedPreset = preset.id;
      _backgroundUrl = null;
      _backgroundFile = null;
    });

    await _updateBackground(
      backgroundUrl: null,
      backgroundPreset: preset.id,
    );

    widget.onBackgroundChanged?.call(preset.id);
    _showSuccessSnackBar("Preset applied! ${preset.emoji}");
    HapticFeedback.lightImpact();
  }

  void _toggleFavoritePreset(String presetId) async {
    setState(() {
      if (_favoritePresets.contains(presetId)) {
        _favoritePresets.remove(presetId);
      } else {
        _favoritePresets.add(presetId);
      }
    });
    
    await _saveUserPreferences();
    HapticFeedback.selectionClick();
  }

  void _updateOpacity(double value) async {
    setState(() {
      _opacity = value;
    });
    
    await _updateBackground(
      backgroundUrl: _backgroundUrl,
      backgroundPreset: _selectedPreset,
    );
  }

  void _updateBlur(double value) async {
    setState(() {
      _blur = value;
    });
    
    await _updateBackground(
      backgroundUrl: _backgroundUrl,
      backgroundPreset: _selectedPreset,
    );
  }

  void _updateEffect(String effect) async {
    setState(() {
      _selectedEffect = effect;
    });
    
    await _updateBackground(
      backgroundUrl: _backgroundUrl,
      backgroundPreset: _selectedPreset,
    );
    
    _showSuccessSnackBar("Effect applied! ✨");
  }

  void _clearBackground() async {
    setState(() {
      _backgroundUrl = null;
      _backgroundFile = null;
      _selectedPreset = null;
    });

    await _updateBackground(
      backgroundUrl: null,
      backgroundPreset: null,
    );

    widget.onBackgroundChanged?.call(null);
    _showSuccessSnackBar("Background cleared! 🧹");
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Gallery'),
              subtitle: const Text('Choose from your photos'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadBackground(source: ImageSource.gallery);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Camera'),
              subtitle: const Text('Take a new photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadBackground(source: ImageSource.camera);
              },
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildCurrentBackground() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.primaryColor ?? Colors.pinkAccent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Background content
            _buildBackgroundContent(),
            
            // Loading overlay
            if (_isUploading || _isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Processing...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Action buttons overlay
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: [
                  if (_backgroundUrl != null || _selectedPreset != null)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: _clearBackground,
                        tooltip: 'Clear Background',
                      ),
                    ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
                      onPressed: _showSourcePicker,
                      tooltip: 'Change Background',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundContent() {
    Widget content;
    
    if (_backgroundFile != null) {
      content = Image.file(_backgroundFile!, fit: BoxFit.cover);
    } else if (_backgroundUrl != null) {
      content = Image.network(_backgroundUrl!, fit: BoxFit.cover);
    } else if (_selectedPreset != null) {
      final preset = _presetBackgrounds.firstWhere((p) => p.id == _selectedPreset);
      content = _buildPresetBackground(preset);
    } else {
      content = Container(
        color: widget.backgroundColor ?? Colors.grey.shade100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wallpaper,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                "Tap to choose background 🎨",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Apply effects
    if (_blur > 0) {
      content = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: _blur, sigmaY: _blur),
        child: content,
      );
    }
    
    if (_opacity < 1.0) {
      content = Opacity(opacity: _opacity, child: content);
    }
    
    // Apply color effects
    if (_selectedEffect != 'none') {
      content = ColorFiltered(
        colorFilter: _getColorFilter(_selectedEffect),
        child: content,
      );
    }
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: content,
        );
      },
    );
  }

  Widget _buildPresetBackground(BackgroundPreset preset) {
    switch (preset.type) {
      case BackgroundType.gradient:
        return Container(
          decoration: BoxDecoration(
            gradient: preset.gradient,
          ),
        );
      case BackgroundType.solid:
        return Container(color: preset.color);
      case BackgroundType.pattern:
        return Container(
          color: preset.color,
          child: _buildPattern(preset.pattern!),
        );
    }
  }

  Widget _buildPattern(String pattern) {
    switch (pattern) {
      case 'hearts':
        return _buildHeartsPattern();
      case 'stars':
        return _buildStarsPattern();
      case 'bubbles':
        return _buildBubblesPattern();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHeartsPattern() {
    return Stack(
      children: List.generate(20, (index) {
        return Positioned(
          left: (index * 47) % 300,
          top: (index * 31) % 150,
          child: Transform.rotate(
            angle: (index * 0.5),
            child: Icon(
              Icons.favorite,
              color: Colors.white.withOpacity(0.3),
              size: 16 + (index % 8),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStarsPattern() {
    return Stack(
      children: List.generate(30, (index) {
        return Positioned(
          left: (index * 37) % 300,
          top: (index * 23) % 150,
          child: Icon(
            Icons.star,
            color: Colors.white.withOpacity(0.4),
            size: 12 + (index % 6),
          ),
        );
      }),
    );
  }

  Widget _buildBubblesPattern() {
    return Stack(
      children: List.generate(25, (index) {
        return Positioned(
          left: (index * 41) % 300,
          top: (index * 29) % 150,
          child: Container(
            width: 10 + (index % 15),
            height: 10 + (index % 15),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.3),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
        );
      }),
    );
  }

  ColorFilter _getColorFilter(String effect) {
    switch (effect) {
      case 'sepia':
        return const ColorFilter.matrix([
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'grayscale':
        return const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'vintage':
        return const ColorFilter.matrix([
          1.0, 0.0, 0.0, 0, 20,
          0.0, 1.0, 0.0, 0, 10,
          0.0, 0.0, 0.8, 0, 5,
          0, 0, 0, 1, 0,
        ]);
      case 'warm':
        return const ColorFilter.matrix([
          1.1, 0.0, 0.0, 0, 10,
          0.0, 1.0, 0.0, 0, 5,
          0.0, 0.0, 0.9, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'cool':
        return const ColorFilter.matrix([
          0.9, 0.0, 0.0, 0, 0,
          0.0, 1.0, 0.0, 0, 5,
          0.0, 0.0, 1.1, 0, 10,
          0, 0, 0, 1, 0,
        ]);
      default:
        return const ColorFilter.matrix([
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0, 0, 0, 1, 0,
        ]);
    }
  }

  Widget _buildPresetsTab() {
    final favoritePresets = _presetBackgrounds.where((p) => _favoritePresets.contains(p.id)).toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (favoritePresets.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.favorite, color: Colors.red.shade400, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Favorites',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: favoritePresets.length,
              itemBuilder: (context, index) {
                return _buildPresetTile(favoritePresets[index]);
              },
            ),
            const SizedBox(height: 24),
          ],
          
          const Text(
            'All Presets',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: _presetBackgrounds.length,
            itemBuilder: (context, index) {
              return _buildPresetTile(_presetBackgrounds[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPresetTile(BackgroundPreset preset) {
    final isSelected = _selectedPreset == preset.id;
    final isFavorite = _favoritePresets.contains(preset.id);
    
    return GestureDetector(
      onTap: () => _selectPreset(preset),
      onLongPress: () => _toggleFavoritePreset(preset.id),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? (widget.primaryColor ?? Colors.pinkAccent)
                : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              // Background preview
              Positioned.fill(
                child: _buildPresetBackground(preset),
              ),
              
              // Overlay with name
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        preset.emoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          preset.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Favorite indicator
              if (isFavorite)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(
                    Icons.favorite,
                    color: Colors.red.shade400,
                    size: 16,
                  ),
                ),
              
              // Selection indicator
              if (isSelected)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Icon(
                    Icons.check_circle,
                    color: widget.primaryColor ?? Colors.pinkAccent,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEffectsTab() {
    if (!widget.showEffects) {
      return const Center(
        child: Text('Effects are disabled'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Opacity slider
          const Text(
            'Opacity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.opacity, size: 20),
              Expanded(
                child: Slider(
                  value: _opacity,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  label: '${(_opacity * 100).round()}%',
                  activeColor: widget.primaryColor ?? Colors.pinkAccent,
                  onChanged: _updateOpacity,
                ),
              ),
              Text('${(_opacity * 100).round()}%'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Blur slider
          const Text(
            'Blur',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.blur_on, size: 20),
              Expanded(
                child: Slider(
                  value: _blur,
                  min: 0.0,
                  max: 10.0,
                  divisions: 20,
                  label: _blur.toStringAsFixed(1),
                  activeColor: widget.primaryColor ?? Colors.pinkAccent,
                  onChanged: _updateBlur,
                ),
              ),
              Text(_blur.toStringAsFixed(1)),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Color effects
          const Text(
            'Color Effects',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _effectTypes.map((effect) {
              final isSelected = _selectedEffect == effect;
              return FilterChip(
                label: Text(
                  effect == 'none' ? 'Original' : effect.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selected: isSelected,
                selectedColor: widget.primaryColor ?? Colors.pinkAccent,
                onSelected: (_) => _updateEffect(effect),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTab() {
    if (_recentBackgrounds.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No recent backgrounds',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Upload some images to see them here!',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: _recentBackgrounds.length,
      itemBuilder: (context, index) {
        final url = _recentBackgrounds[index];
        final isSelected = _backgroundUrl == url;
        
        return GestureDetector(
          onTap: () async {
            setState(() {
              _backgroundUrl = url;
              _selectedPreset = null;
              _backgroundFile = null;
            });
            
            await _updateBackground(backgroundUrl: url);
            widget.onBackgroundChanged?.call(url);
            _showSuccessSnackBar("Background applied! ✨");
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? (widget.primaryColor ?? Colors.pinkAccent)
                    : Colors.grey.shade300,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Image.network(
                    url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  if (isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(
                        Icons.check_circle,
                        color: widget.primaryColor ?? Colors.pinkAccent,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Upload section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload,
                  size: 48,
                  color: widget.primaryColor ?? Colors.pinkAccent,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Upload Custom Background',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose from gallery or take a photo',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickAndUploadBackground(source: ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.primaryColor ?? Colors.pinkAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickAndUploadBackground(source: ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: widget.primaryColor ?? Colors.pinkAccent,
                          side: BorderSide(color: widget.primaryColor ?? Colors.pinkAccent),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          if (widget.customPresets != null && widget.customPresets!.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Custom Presets',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: widget.customPresets!.length,
              itemBuilder: (context, index) {
                final url = widget.customPresets![index];
                final isSelected = _backgroundUrl == url;
                
                return GestureDetector(
                  onTap: () async {
                    setState(() {
                      _backgroundUrl = url;
                      _selectedPreset = null;
                      _backgroundFile = null;
                    });
                    
                    await _updateBackground(backgroundUrl: url);
                    widget.onBackgroundChanged?.call(url);
                    _showSuccessSnackBar("Custom preset applied! ✨");
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? (widget.primaryColor ?? Colors.pinkAccent)
                            : Colors.grey.shade300,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          Image.network(
                            url,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          if (isSelected)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Icon(
                                Icons.check_circle,
                                color: widget.primaryColor ?? Colors.pinkAccent,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading background settings...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Current background preview
        _buildCurrentBackground(),
        
        const SizedBox(height: 16),
        
        // Tab bar
        TabBar(
          controller: _tabController,
          labelColor: widget.primaryColor ?? Colors.pinkAccent,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: widget.primaryColor ?? Colors.pinkAccent,
          tabs: const [
            Tab(icon: Icon(Icons.palette), text: 'Presets'),
            Tab(icon: Icon(Icons.tune), text: 'Effects'),
            Tab(icon: Icon(Icons.history), text: 'Recent'),
            Tab(icon: Icon(Icons.upload), text: 'Custom'),
          ],
        ),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPresetsTab(),
              _buildEffectsTab(),
              _buildRecentTab(),
              _buildCustomTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// Data models
enum BackgroundType { gradient, solid, pattern }

class BackgroundPreset {
  final String id;
  final String name;
  final BackgroundType type;
  final LinearGradient? gradient;
  final Color? color;
  final String? pattern;
  final String emoji;

  const BackgroundPreset({
    required this.id,
    required this.name,
    required this.type,
    this.gradient,
    this.color,
    this.pattern,
    required this.emoji,
  });
}
