import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

class AvatarPicker extends StatefulWidget {
  final String userId;
  final double radius;
  final bool showEditButton;
  final bool allowDecorations;
  final VoidCallback? onAvatarChanged;
  final String? currentDecorationPath;

  const AvatarPicker({
    super.key,
    required this.userId,
    this.radius = 40,
    this.showEditButton = true,
    this.allowDecorations = true,
    this.onAvatarChanged,
    this.currentDecorationPath,
  });

  @override
  AvatarPickerState createState() => AvatarPickerState();
}

class AvatarPickerState extends State<AvatarPicker>
    with TickerProviderStateMixin {
  File? _avatarImage;
  String? _avatarUrl;
  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _decorationPath;
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _scaleController;
  late AnimationController _bounceController;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Predefined avatar options
  final List<String> _presetAvatars = [
    'assets/avatars/avatar_1.png',
    'assets/avatars/avatar_2.png',
    'assets/avatars/avatar_3.png',
    'assets/avatars/avatar_4.png',
    'assets/avatars/avatar_5.png',
    'assets/avatars/avatar_6.png',
    'assets/avatars/magical_girl_1.png',
    'assets/avatars/magical_girl_2.png',
    'assets/avatars/kawaii_cat.png',
    'assets/avatars/crystal_fairy.png',
  ];

  // Avatar frames/decorations (loaded from user inventory)
  List<Map<String, String>> _avatarFrames = [
    {'name': 'None', 'path': '', 'icon': '⚪', 'id': 'none'},
  ];
  
  // Available decorations that can be equipped
  final List<Map<String, String>> _allDecorations = [
    {'name': 'Sparkle', 'path': 'assets/decorations/sparkle_frame.png', 'icon': '✨', 'id': 'sparkle_frame'},
    {'name': 'Hearts', 'path': 'assets/decorations/heart_frame.png', 'icon': '💖', 'id': 'heart_frame'},
    {'name': 'Stars', 'path': 'assets/decorations/star_frame.png', 'icon': '⭐', 'id': 'star_frame'},
    {'name': 'Flowers', 'path': 'assets/decorations/flower_frame.png', 'icon': '🌸', 'id': 'flower_frame'},
    {'name': 'Rainbow', 'path': 'assets/decorations/rainbow_frame.png', 'icon': '🌈', 'id': 'rainbow_frame'},
    {'name': 'Crystal', 'path': 'assets/decorations/crystal_frame.png', 'icon': '💎', 'id': 'crystal_frame'},
    {'name': 'Magic', 'path': 'assets/decorations/magic_frame.png', 'icon': '🔮', 'id': 'magic_frame'},
    {'name': 'Golden', 'path': 'assets/decorations/golden_frame.png', 'icon': '🥇', 'id': 'golden_frame'},
    {'name': 'Silver', 'path': 'assets/decorations/silver_frame.png', 'icon': '🥈', 'id': 'silver_frame'},
    {'name': 'Bronze', 'path': 'assets/decorations/bronze_frame.png', 'icon': '🥉', 'id': 'bronze_frame'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAvatar();
    _loadUserDecorations();
    _decorationPath = widget.currentDecorationPath;
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _rotateController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    _bounceAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _pulseController.repeat(reverse: true);
    _rotateController.repeat();
    _bounceController.forward();
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _scaleController.dispose();
    _bounceController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadAvatar() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final res = await Supabase.instance.client
          .from('users')
          .select('avatarUrl, avatar_decoration')
          .eq('id', widget.userId)
          .maybeSingle();
      
      if (!mounted) return;
      
      setState(() {
        _avatarUrl = res != null && res['avatarUrl'] is String 
            ? res['avatarUrl'] as String 
            : null;
        _decorationPath = res?['avatar_decoration'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load avatar: $e');
      }
    }
  }

  Future<void> _loadUserDecorations() async {
    try {
      // Load user's inventory to see which decorations they own
      final inventoryRes = await Supabase.instance.client
          .from('user_inventory')
          .select('item_id, item_type')
          .eq('user_id', widget.userId)
          .eq('item_type', 'decoration')
          .eq('equipped', false); // Only show unequipped decorations that can be equipped

      if (!mounted) return;

      final ownedDecorations = <String>{};
      for (final item in inventoryRes) {
        ownedDecorations.add(item['item_id'] as String);
      }

      // Filter decorations to only show owned ones
      final availableFrames = <Map<String, String>>[
        {'name': 'None', 'path': '', 'icon': '⚪', 'id': 'none'}, // Always available
      ];

      for (final decoration in _allDecorations) {
        if (ownedDecorations.contains(decoration['id'])) {
          availableFrames.add(decoration);
        }
      }

      if (mounted) {
        setState(() {
          _avatarFrames = availableFrames;
        });
      }
    } catch (e) {
      // If inventory loading fails, show only the "None" option
      if (mounted) {
        setState(() {
          _avatarFrames = [
            {'name': 'None', 'path': '', 'icon': '⚪', 'id': 'none'},
          ];
        });
      }
      print('Failed to load user decorations: $e');
    }
  }

  Future<void> _pickImage([ImageSource? source]) async {
    try {
      final picker = ImagePicker();
      final ImageSource selectedSource = source ?? ImageSource.gallery;
      
      final picked = await picker.pickImage(
        source: selectedSource,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (picked == null) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      final file = File(picked.path);
      await _uploadAvatarImage(file);
      
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  Future<void> _uploadAvatarImage(File file) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final storagePath = '${widget.userId}/$fileName';

      // Simulate upload progress
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 50));
        if (mounted) {
          setState(() {
            _uploadProgress = i / 100.0;
          });
        }
      }

      await Supabase.instance.client.storage
          .from('user_avatars')
          .uploadBinary(
            storagePath,
            await file.readAsBytes(),
            fileOptions: const FileOptions(upsert: true),
          );

      if (!mounted) return;

      final url = Supabase.instance.client.storage
          .from('user_avatars')
          .getPublicUrl(storagePath);

      await Supabase.instance.client
          .from('users')
          .update({'avatarUrl': url}).eq('id', widget.userId);

      if (!mounted) return;

      setState(() {
        _avatarImage = file;
        _avatarUrl = url;
      });

      widget.onAvatarChanged?.call();
      HapticFeedback.heavyImpact();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text("Avatar updated! You're extra cute now 💅🫶"),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to upload avatar: $e');
    }
  }

  Future<void> _showPresetAvatars() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
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
              Text(
                'Choose Preset Avatar',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _presetAvatars.length,
                  itemBuilder: (context, index) {
                    final avatarPath = _presetAvatars[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _selectPresetAvatar(avatarPath);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.purple.withOpacity(0.3)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            avatarPath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                              Container(
                                color: Colors.grey[200],
                                child: Icon(Icons.person, size: 40, color: Colors.grey),
                              ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectPresetAvatar(String avatarPath) async {
    try {
      setState(() {
        _isUploading = true;
      });

      // For preset avatars, we'll store the asset path directly
      await Supabase.instance.client
          .from('users')
          .update({'avatarUrl': avatarPath}).eq('id', widget.userId);

      if (!mounted) return;

      setState(() {
        _avatarUrl = avatarPath;
        _avatarImage = null; // Clear local image
      });

      widget.onAvatarChanged?.call();
      HapticFeedback.lightImpact();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Preset avatar selected! ✨'),
            ],
          ),
          backgroundColor: Colors.purple,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to select preset avatar: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _showAvatarFrames() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: _avatarFrames.length <= 4 ? 300 : 400,
        child: Column(
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
            Text(
              'Choose Avatar Frame',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 20),
            if (_avatarFrames.length == 1) // Only "None" available
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No Avatar Frames Available',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Collect decorations from the shop\nor complete challenges to unlock\navatar frames!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Navigate to shop or decorations page
                      },
                      icon: Icon(Icons.shopping_bag),
                      label: Text('Visit Shop'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _avatarFrames.length,
                  itemBuilder: (context, index) {
                    final frame = _avatarFrames[index];
                    final isSelected = _decorationPath == frame['path'];
                    
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _selectAvatarFrame(frame['path']!);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.purple : Colors.grey.withOpacity(0.3),
                            width: isSelected ? 3 : 1,
                          ),
                          color: isSelected ? Colors.purple.withOpacity(0.1) : Colors.transparent,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              frame['icon']!,
                              style: TextStyle(fontSize: 24),
                            ),
                            SizedBox(height: 4),
                            Text(
                              frame['name']!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.purple : Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectAvatarFrame(String framePath) async {
    try {
      await Supabase.instance.client
          .from('users')
          .update({'avatar_decoration': framePath.isEmpty ? null : framePath})
          .eq('id', widget.userId);

      if (!mounted) return;

      setState(() {
        _decorationPath = framePath.isEmpty ? null : framePath;
      });

      HapticFeedback.selectionClick();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text(framePath.isEmpty ? 'Frame removed!' : 'Frame applied! ✨'),
            ],
          ),
          backgroundColor: Colors.pink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to update frame: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.grey[700]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Avatar Picker',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_avatarUrl != null)
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _removeAvatar,
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.withOpacity(0.1),
              Colors.pink.withOpacity(0.1),
              Colors.orange.withOpacity(0.1),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Avatar Display Section
              AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _bounceAnimation.value,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.withOpacity(0.8),
                          Colors.pink.withOpacity(0.8),
                          Colors.orange.withOpacity(0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(4),
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: ClipOval(
                            child: _buildAvatarContent(),
                          ),
                        ),
                        if (_decorationPath != null) _buildAvatarDecoration(),
                        if (_isUploading) _buildUploadProgress(),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              Text(
                'Tap to change your avatar',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Action Buttons
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _slideAnimation.value * 50),
                  child: Column(
                    children: [
                      // Camera/Gallery Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.camera_alt,
                              label: 'Camera',
                              color: Colors.blue,
                              onTap: () => _pickImage(ImageSource.camera),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.photo_library,
                              label: 'Gallery',
                              color: Colors.green,
                              onTap: () => _pickImage(ImageSource.gallery),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 12),
                      
                      // Preset/Frame Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.face,
                              label: 'Presets',
                              color: Colors.purple,
                              onTap: _showPresetAvatars,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.auto_awesome,
                              label: 'Frames',
                              color: Colors.pink,
                              onTap: _showAvatarFrames,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Avatar Tips Card
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) => Opacity(
                  opacity: _fadeAnimation.value,
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Avatar Tips',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          '• Use a clear, well-lit photo for best results\n'
                          '• Square images work best for circular avatars\n'
                          '• Try our preset avatars for instant style\n'
                          '• Add frames to make your avatar unique',
                          style: TextStyle(
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarContent() {
    if (_isLoading) {
      return Container(
        color: Colors.grey[100],
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
          ),
        ),
      );
    }

    if (_avatarImage != null) {
      return Image.file(
        _avatarImage!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      if (_avatarUrl!.startsWith('assets/')) {
        return Image.asset(
          _avatarUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      } else {
        return Image.network(
          _avatarUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[100],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      }
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            size: 60,
            color: Colors.grey[400],
          ),
          SizedBox(height: 8),
          Text(
            'No Avatar',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarDecoration() {
    if (_decorationPath == null || _decorationPath!.isEmpty) return SizedBox.shrink();
    
    final frame = _avatarFrames.firstWhere(
      (frame) => frame['path'] == _decorationPath,
      orElse: () => {'icon': '✨', 'name': 'Unknown', 'path': '', 'id': 'unknown'},
    );
    
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.amber,
            width: 3,
          ),
        ),
        child: Align(
          alignment: Alignment.topRight,
          child: Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              frame['icon']!,
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.7),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value: _uploadProgress,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              backgroundColor: Colors.white.withOpacity(0.3),
            ),
            SizedBox(height: 8),
            Text(
              '${(_uploadProgress * 100).round()}%',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _removeAvatar() async {
    try {
      await Supabase.instance.client
          .from('users')
          .update({
            'avatarUrl': null,
            'avatar_decoration': null,
          })
          .eq('id', widget.userId);

      if (!mounted) return;

      setState(() {
        _avatarImage = null;
        _avatarUrl = null;
        _decorationPath = null;
      });

      widget.onAvatarChanged?.call();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Avatar removed'),
            ],
          ),
          backgroundColor: Colors.grey[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to remove avatar: $e');
    }
  }
}
