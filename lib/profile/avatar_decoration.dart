import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Enhanced Avatar Decoration class with metadata
class AvatarDecoration {
  final String id;
  final String name;
  final String imagePath;
  final String iconEmoji;
  final String category;
  final bool isPremium;
  final String? description;
  final Map<String, dynamic>? metadata;
  final bool isOwned;
  final bool isEquipped;

  AvatarDecoration({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.iconEmoji,
    this.category = 'general',
    this.isPremium = false,
    this.description,
    this.metadata,
    this.isOwned = false,
    this.isEquipped = false,
  });

  factory AvatarDecoration.fromJson(Map<String, dynamic> json) {
    return AvatarDecoration(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imagePath: json['imagePath'] ?? '',
      iconEmoji: json['iconEmoji'] ?? '✨',
      category: json['category'] ?? 'general',
      isPremium: json['isPremium'] ?? false,
      description: json['description'],
      metadata: json['metadata'],
      isOwned: json['isOwned'] ?? false,
      isEquipped: json['isEquipped'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
      'iconEmoji': iconEmoji,
      'category': category,
      'isPremium': isPremium,
      'description': description,
      'metadata': metadata,
      'isOwned': isOwned,
      'isEquipped': isEquipped,
    };
  }

  AvatarDecoration copyWith({
    String? id,
    String? name,
    String? imagePath,
    String? iconEmoji,
    String? category,
    bool? isPremium,
    String? description,
    Map<String, dynamic>? metadata,
    bool? isOwned,
    bool? isEquipped,
  }) {
    return AvatarDecoration(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      category: category ?? this.category,
      isPremium: isPremium ?? this.isPremium,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      isOwned: isOwned ?? this.isOwned,
      isEquipped: isEquipped ?? this.isEquipped,
    );
  }
}

// Enhanced decoration service with inventory integration
class AvatarDecorationService {
  static const List<Map<String, dynamic>> _baseDecorations = [
    // Cute Animals
    {
      'id': 'cat_white',
      'name': 'White Cat',
      'imagePath': 'assets/decorations/Cat_White.gif',
      'iconEmoji': '🐱',
      'category': 'cute',
      'description': 'Adorable white cat animation',
      'isPremium': false,
    },
    {
      'id': 'dog_brown_white',
      'name': 'Brown Dog',
      'imagePath': 'assets/decorations/Dog_Brown_&_White.gif',
      'iconEmoji': '🐕',
      'category': 'cute',
      'description': 'Playful brown and white dog',
      'isPremium': false,
    },
    {
      'id': 'pink_cat',
      'name': 'Pink Cat',
      'imagePath': 'assets/decorations/pink_cat.gif',
      'iconEmoji': '🐱',
      'category': 'cute',
      'description': 'Sweet pink cat decoration',
      'isPremium': false,
    },
    {
      'id': 'black_cat',
      'name': 'Black Cat',
      'imagePath': 'assets/decorations/black_cat.gif',
      'iconEmoji': '🐈‍⬛',
      'category': 'cute',
      'description': 'Mysterious black cat',
      'isPremium': false,
    },
    {
      'id': 'kitten',
      'name': 'Kitten',
      'imagePath': 'assets/decorations/kitten.gif',
      'iconEmoji': '🐾',
      'category': 'cute',
      'description': 'Playful kitten animation',
      'isPremium': false,
    },
    {
      'id': 'bunny',
      'name': 'Bunny',
      'imagePath': 'assets/decorations/bunny.gif',
      'iconEmoji': '🐰',
      'category': 'cute',
      'description': 'Cute bunny decoration',
      'isPremium': false,
    },
    {
      'id': 'easter_bunny',
      'name': 'Easter Bunny',
      'imagePath': 'assets/decorations/easter_bunny.gif',
      'iconEmoji': '🐰',
      'category': 'cute',
      'description': 'Special Easter bunny',
      'isPremium': false,
    },
    {
      'id': 'bear_frame',
      'name': 'Bear Frame',
      'imagePath': 'assets/decorations/bear_frame.gif',
      'iconEmoji': '🐻',
      'category': 'cute',
      'description': 'Adorable bear frame',
      'isPremium': false,
    },
    {
      'id': 'pink_bear_frame',
      'name': 'Pink Bear',
      'imagePath': 'assets/decorations/pink_bear_frame.gif',
      'iconEmoji': '🧸',
      'category': 'cute',
      'description': 'Pink teddy bear frame',
      'isPremium': false,
    },
    {
      'id': 'gummy_bears',
      'name': 'Gummy Bears',
      'imagePath': 'assets/decorations/gummy_bears.gif',
      'iconEmoji': '🧸',
      'category': 'cute',
      'description': 'Colorful gummy bears',
      'isPremium': false,
    },

    // Hearts & Love
    {
      'id': 'heart',
      'name': 'Heart',
      'imagePath': 'assets/decorations/heart.gif',
      'iconEmoji': '💖',
      'category': 'love',
      'description': 'Animated heart decoration',
      'isPremium': false,
    },
    {
      'id': 'hearts',
      'name': 'Hearts',
      'imagePath': 'assets/decorations/hearts.gif',
      'iconEmoji': '💕',
      'category': 'love',
      'description': 'Multiple floating hearts',
      'isPremium': false,
    },
    {
      'id': 'rotating_hearts',
      'name': 'Rotating Hearts',
      'imagePath': 'assets/decorations/rotating_hearts.gif',
      'iconEmoji': '💞',
      'category': 'love',
      'description': 'Beautiful rotating hearts',
      'isPremium': false,
    },
    {
      'id': 'in_love',
      'name': 'In Love',
      'imagePath': 'assets/decorations/in_love.gif',
      'iconEmoji': '�',
      'category': 'love',
      'description': 'Love-struck animation',
      'isPremium': false,
    },

    // Magical & Sparkly
    {
      'id': 'sparkle',
      'name': 'Sparkle',
      'imagePath': 'assets/decorations/sparkle.gif',
      'iconEmoji': '✨',
      'category': 'magical',
      'description': 'Magical sparkle effects',
      'isPremium': false,
    },
    {
      'id': 'purple_aura',
      'name': 'Purple Aura',
      'imagePath': 'assets/decorations/purple_aura.gif',
      'iconEmoji': '🔮',
      'category': 'magical',
      'description': 'Mystical purple aura',
      'isPremium': false,
    },
    {
      'id': 'shadow_essence',
      'name': 'Shadow Essence',
      'imagePath': 'assets/decorations/shadow_essence.gif',
      'iconEmoji': '🌙',
      'category': 'magical',
      'description': 'Dark magical essence',
      'isPremium': false,
    },
    {
      'id': 'gemstone_moon',
      'name': 'Gemstone Moon',
      'imagePath': 'assets/decorations/gemstone_moon.gif',
      'iconEmoji': '🌙',
      'category': 'magical',
      'description': 'Mystical gemstone moon',
      'isPremium': false,
    },

    // Bubbles & Water
    {
      'id': 'bubble',
      'name': 'Bubble',
      'imagePath': 'assets/decorations/bubble.gif',
      'iconEmoji': '🫧',
      'category': 'colorful',
      'description': 'Floating bubble animation',
      'isPremium': false,
    },
    {
      'id': 'pink_bubbles',
      'name': 'Pink Bubbles',
      'imagePath': 'assets/decorations/pink_bubbles.gif',
      'iconEmoji': '🫧',
      'category': 'colorful',
      'description': 'Sweet pink bubbles',
      'isPremium': false,
    },
    {
      'id': 'purple_bubbly',
      'name': 'Purple Bubbly',
      'imagePath': 'assets/decorations/purple_bubbly.gif',
      'iconEmoji': '🫧',
      'category': 'colorful',
      'description': 'Purple bubble effects',
      'isPremium': false,
    },
    {
      'id': 'rainbow_bubble',
      'name': 'Rainbow Bubble',
      'imagePath': 'assets/decorations/rainbow_bubble.gif',
      'iconEmoji': '🌈',
      'category': 'colorful',
      'description': 'Colorful rainbow bubbles',
      'isPremium': false,
    },
    {
      'id': 'rainbow_fish',
      'name': 'Rainbow Fish',
      'imagePath': 'assets/decorations/rainbow_fish.gif',
      'iconEmoji': '🐠',
      'category': 'colorful',
      'description': 'Beautiful rainbow fish',
      'isPremium': false,
    },

    // Nature & Flowers
    {
      'id': 'sakura',
      'name': 'Sakura',
      'imagePath': 'assets/decorations/sakura.gif',
      'iconEmoji': '🌸',
      'category': 'nature',
      'description': 'Beautiful cherry blossoms',
      'isPremium': false,
    },
    {
      'id': 'cherry_blossom_soft_pink',
      'name': 'Soft Cherry Blossom',
      'imagePath': 'assets/decorations/Cherry_Blossom_Soft_Pink.gif',
      'iconEmoji': '🌸',
      'category': 'nature',
      'description': 'Soft pink cherry blossoms',
      'isPremium': false,
    },
    {
      'id': 'cherry_blossom_dark_pink',
      'name': 'Dark Cherry Blossom',
      'imagePath': 'assets/decorations/Cherry_Blossom_Dark_Pink.gif',
      'iconEmoji': '🌸',
      'category': 'nature',
      'description': 'Dark pink cherry blossoms',
      'isPremium': false,
    },
    {
      'id': 'sunflowers',
      'name': 'Sunflowers',
      'imagePath': 'assets/decorations/sunflowers.gif',
      'iconEmoji': '🌻',
      'category': 'nature',
      'description': 'Bright sunflower decoration',
      'isPremium': false,
    },
    {
      'id': 'forest',
      'name': 'Forest',
      'imagePath': 'assets/decorations/Forest.gif',
      'iconEmoji': '�',
      'category': 'nature',
      'description': 'Mystical forest setting',
      'isPremium': false,
    },
    {
      'id': 'mushroom_pink',
      'name': 'Pink Mushroom',
      'imagePath': 'assets/decorations/Mushroom_Pink.gif',
      'iconEmoji': '🍄',
      'category': 'nature',
      'description': 'Cute pink mushroom',
      'isPremium': false,
    },
    {
      'id': 'mushroom_red',
      'name': 'Red Mushroom',
      'imagePath': 'assets/decorations/Mushroom_Red.gif',
      'iconEmoji': '🍄',
      'category': 'nature',
      'description': 'Classic red mushroom',
      'isPremium': false,
    },
    {
      'id': 'snowflake',
      'name': 'Snowflake',
      'imagePath': 'assets/decorations/snowflake.gif',
      'iconEmoji': '❄️',
      'category': 'nature',
      'description': 'Delicate snowflake animation',
      'isPremium': false,
    },

    // Futuristic & Tech
    {
      'id': 'futuristic_headphones_blue',
      'name': 'Blue Headphones',
      'imagePath': 'assets/decorations/Futuristic_Headphones_Blue.gif',
      'iconEmoji': '🎧',
      'category': 'futuristic',
      'description': 'Futuristic blue headphones',
      'isPremium': false,
    },
    {
      'id': 'futuristic_headphones_green',
      'name': 'Green Headphones',
      'imagePath': 'assets/decorations/Futuristic_Headphones_Green.gif',
      'iconEmoji': '🎧',
      'category': 'futuristic',
      'description': 'Futuristic green headphones',
      'isPremium': false,
    },
    {
      'id': 'futuristic_headphones_pink',
      'name': 'Pink Headphones',
      'imagePath': 'assets/decorations/Futuristic_Headphones_Pink.gif',
      'iconEmoji': '🎧',
      'category': 'futuristic',
      'description': 'Futuristic pink headphones',
      'isPremium': false,
    },
    {
      'id': 'futuristic_interface_blue',
      'name': 'Blue Interface',
      'imagePath': 'assets/decorations/Futuristic_Interface_Blue.gif',
      'iconEmoji': '�',
      'category': 'futuristic',
      'description': 'High-tech blue interface',
      'isPremium': false,
    },
    {
      'id': 'futuristic_interface_pink',
      'name': 'Pink Interface',
      'imagePath': 'assets/decorations/Futuristic_Interface_Pink.gif',
      'iconEmoji': '💻',
      'category': 'futuristic',
      'description': 'High-tech pink interface',
      'isPremium': false,
    },
    {
      'id': 'glitch',
      'name': 'Glitch',
      'imagePath': 'assets/decorations/glitch.gif',
      'iconEmoji': '⚡',
      'category': 'futuristic',
      'description': 'Digital glitch effect',
      'isPremium': false,
    },
    {
      'id': 'neon_dragon',
      'name': 'Neon Dragon',
      'imagePath': 'assets/decorations/neon_dragon.gif',
      'iconEmoji': '🐉',
      'category': 'futuristic',
      'description': 'Epic neon dragon',
      'isPremium': false,
    },

    // Gaming & Anime
    {
      'id': 'anime_effects',
      'name': 'Anime Effects',
      'imagePath': 'assets/decorations/anime_effects.gif',
      'iconEmoji': '💫',
      'category': 'anime',
      'description': 'Cool anime-style effects',
      'isPremium': false,
    },
    {
      'id': 'japanese',
      'name': 'Japanese',
      'imagePath': 'assets/decorations/japanese.gif',
      'iconEmoji': '🗾',
      'category': 'anime',
      'description': 'Japanese cultural decoration',
      'isPremium': false,
    },
    {
      'id': 'tokyo',
      'name': 'Tokyo',
      'imagePath': 'assets/decorations/tokyo.gif',
      'iconEmoji': '🏙️',
      'category': 'anime',
      'description': 'Tokyo city vibes',
      'isPremium': false,
    },
    {
      'id': 'oni',
      'name': 'Oni',
      'imagePath': 'assets/decorations/oni.gif',
      'iconEmoji': '�',
      'category': 'anime',
      'description': 'Japanese oni mask',
      'isPremium': false,
    },
    {
      'id': 'mask',
      'name': 'Mask',
      'imagePath': 'assets/decorations/mask.gif',
      'iconEmoji': '🎭',
      'category': 'anime',
      'description': 'Mysterious mask decoration',
      'isPremium': false,
    },

    // Emotions & Expressions
    {
      'id': 'flustered',
      'name': 'Flustered',
      'imagePath': 'assets/decorations/flustered.gif',
      'iconEmoji': '😳',
      'category': 'emotions',
      'description': 'Cute flustered expression',
      'isPremium': false,
    },
    {
      'id': 'angry_frame',
      'name': 'Angry',
      'imagePath': 'assets/decorations/angry_frame.gif',
      'iconEmoji': '😠',
      'category': 'emotions',
      'description': 'Fiery angry animation',
      'isPremium': false,
    },
    {
      'id': 'pink_angry_frame',
      'name': 'Pink Angry',
      'imagePath': 'assets/decorations/pink_angry_frame.gif',
      'iconEmoji': '😡',
      'category': 'emotions',
      'description': 'Pink angry expression',
      'isPremium': false,
    },

    // Special & Rare
    {
      'id': 'special_frame',
      'name': 'Special Frame',
      'imagePath': 'assets/decorations/special_frame.gif',
      'iconEmoji': '🌟',
      'category': 'special',
      'description': 'Exclusive special frame',
      'isPremium': false,
    },
    {
      'id': 'lightsabers',
      'name': 'Lightsabers',
      'imagePath': 'assets/decorations/lightsabers.gif',
      'iconEmoji': '⚔️',
      'category': 'special',
      'description': 'Epic lightsaber animation',
      'isPremium': false,
    },
    {
      'id': 'loading',
      'name': 'Loading',
      'imagePath': 'assets/decorations/loading.gif',
      'iconEmoji': '⏳',
      'category': 'tech',
      'description': 'Cool loading animation',
      'isPremium': false,
    },
  ];

  // Load user's available decorations based on inventory
  static Future<List<AvatarDecoration>> loadUserDecorations(String userId) async {
    try {
      // Get user's inventory
      final inventoryRes = await Supabase.instance.client
          .from('user_inventory')
          .select('item_id, equipped')
          .eq('user_id', userId)
          .eq('item_type', 'decoration');

      final ownedDecorations = <String, bool>{};
      for (final item in inventoryRes) {
        ownedDecorations[item['item_id']] = item['equipped'] ?? false;
      }

      // Map base decorations to include ownership status
      final decorations = _baseDecorations.map((decoration) {
        final isOwned = ownedDecorations.containsKey(decoration['id']);
        final isEquipped = ownedDecorations[decoration['id']] ?? false;
        
        return AvatarDecoration.fromJson({
          ...decoration,
          'isOwned': isOwned,
          'isEquipped': isEquipped,
        });
      }).toList();

      // Always include "None" option
      decorations.insert(0, AvatarDecoration(
        id: 'none',
        name: 'None',
        imagePath: '',
        iconEmoji: '⚪',
        category: 'basic',
        description: 'No decoration',
        isOwned: true,
      ));

      return decorations;
    } catch (e) {
      print('Error loading user decorations: $e');
      // Return basic decorations on error
      return [
        AvatarDecoration(
          id: 'none',
          name: 'None',
          imagePath: '',
          iconEmoji: '⚪',
          category: 'basic',
          description: 'No decoration',
          isOwned: true,
        ),
      ];
    }
  }

  // Get only owned decorations
  static Future<List<AvatarDecoration>> getOwnedDecorations(String userId) async {
    final allDecorations = await loadUserDecorations(userId);
    return allDecorations.where((decoration) => decoration.isOwned).toList();
  }

  // Get decorations by category
  static Future<List<AvatarDecoration>> getDecorationsByCategory(
    String userId, 
    String category
  ) async {
    final decorations = await loadUserDecorations(userId);
    return decorations.where((decoration) => 
      decoration.category == category && decoration.isOwned
    ).toList();
  }

  // Equip a decoration
  static Future<bool> equipDecoration(String userId, String decorationId) async {
    try {
      // First unequip all decorations
      await Supabase.instance.client
          .from('user_inventory')
          .update({'equipped': false})
          .eq('user_id', userId)
          .eq('item_type', 'decoration');

      // Then equip the selected decoration (if not "none")
      if (decorationId != 'none') {
        await Supabase.instance.client
            .from('user_inventory')
            .update({'equipped': true})
            .eq('user_id', userId)
            .eq('item_id', decorationId)
            .eq('item_type', 'decoration');
      }

      // Update user's avatar decoration
      final decorationPath = decorationId == 'none' ? null : 
          _baseDecorations.firstWhere(
            (d) => d['id'] == decorationId,
            orElse: () => {'imagePath': ''}
          )['imagePath'];

      await Supabase.instance.client
          .from('users')
          .update({'avatar_decoration': decorationPath})
          .eq('id', userId);

      return true;
    } catch (e) {
      print('Error equipping decoration: $e');
      return false;
    }
  }
}

// Function to load available decorations from the assets folder (legacy support)
Future<List<AvatarDecoration>> loadAvailableDecorations() async {
  // This is now a wrapper around the new service
  // For backward compatibility, we'll return static decorations
  return AvatarDecorationService._baseDecorations.map((decoration) {
    return AvatarDecoration.fromJson(decoration);
  }).toList();
}

// Enhanced Avatar widget that combines the avatar and decoration with animations
class AvatarWithDecoration extends StatefulWidget {
  final String avatarUrl;
  final String decorationPath;
  final double radius;
  final bool showAnimation;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;

  const AvatarWithDecoration({
    required this.avatarUrl,
    required this.decorationPath,
    this.radius = 40,
    this.showAnimation = true,
    this.onTap,
    this.showBorder = false,
    this.borderColor,
    super.key,
  });

  @override
  State<AvatarWithDecoration> createState() => _AvatarWithDecorationState();
}

class _AvatarWithDecorationState extends State<AvatarWithDecoration>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.showAnimation) {
      _pulseController = AnimationController(
        duration: const Duration(seconds: 2),
        vsync: this,
      );
      _rotateController = AnimationController(
        duration: const Duration(seconds: 8),
        vsync: this,
      );

      _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
      );
      _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _rotateController, curve: Curves.linear),
      );

      _pulseController.repeat(reverse: true);
      if (widget.decorationPath.isNotEmpty) {
        _rotateController.repeat();
      }
    }
  }

  @override
  void dispose() {
    if (widget.showAnimation) {
      _pulseController.dispose();
      _rotateController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget avatarWidget = Container(
      width: widget.radius * 2,
      height: widget.radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: widget.showBorder
            ? Border.all(
                color: widget.borderColor ?? Colors.purple,
                width: 3,
              )
            : null,
        boxShadow: [
          if (widget.decorationPath.isNotEmpty)
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main avatar
          CircleAvatar(
            radius: widget.radius,
            backgroundColor: Colors.grey[200],
            backgroundImage: widget.avatarUrl.isNotEmpty
                ? (widget.avatarUrl.startsWith('assets/')
                    ? AssetImage(widget.avatarUrl) as ImageProvider
                    : NetworkImage(widget.avatarUrl))
                : null,
            child: widget.avatarUrl.isEmpty
                ? Icon(
                    Icons.person,
                    size: widget.radius,
                    color: Colors.grey[400],
                  )
                : null,
          ),
          
          // Decoration overlay
          if (widget.decorationPath.isNotEmpty)
            Positioned.fill(
              child: widget.showAnimation
                  ? AnimatedBuilder(
                      animation: _rotateAnimation,
                      builder: (context, child) => Transform.rotate(
                        angle: _rotateAnimation.value * 2 * 3.14159,
                        child: _buildDecorationOverlay(),
                      ),
                    )
                  : _buildDecorationOverlay(),
            ),
        ],
      ),
    );

    // Apply pulse animation if enabled
    if (widget.showAnimation && widget.decorationPath.isNotEmpty) {
      avatarWidget = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) => Transform.scale(
          scale: _pulseAnimation.value,
          child: avatarWidget,
        ),
      );
    }

    // Make it tappable if onTap is provided
    if (widget.onTap != null) {
      avatarWidget = GestureDetector(
        onTap: widget.onTap,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  Widget _buildDecorationOverlay() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.amber.withOpacity(0.8),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Colors.transparent,
                Colors.purple.withOpacity(0.1),
                Colors.pink.withOpacity(0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Enhanced Avatar customization screen with modern UI and features
class AvatarCustomizationScreen extends StatefulWidget {
  final String userId;
  final String avatarUrl;
  final String currentDecorationPath;
  final Function(String) onDecorationSelected;

  const AvatarCustomizationScreen({
    required this.userId,
    required this.avatarUrl,
    required this.currentDecorationPath,
    required this.onDecorationSelected,
    super.key,
  });

  @override
  State<AvatarCustomizationScreen> createState() => _AvatarCustomizationScreenState();
}

class _AvatarCustomizationScreenState extends State<AvatarCustomizationScreen>
    with TickerProviderStateMixin {
  late String selectedDecoration;
  late Future<List<AvatarDecoration>> _availableDecorations;
  String selectedCategory = 'all';
  bool showOnlyOwned = true;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> categories = [
    'all',
    'cute',
    'love',
    'magical',
    'colorful',
    'nature',
    'futuristic',
    'anime',
    'emotions',
    'tech',
    'special',
  ];

  @override
  void initState() {
    super.initState();
    selectedDecoration = widget.currentDecorationPath;
    _loadDecorations();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _loadDecorations() {
    setState(() {
      _availableDecorations = AvatarDecorationService.loadUserDecorations(widget.userId);
    });
  }

  void _updateDecoration(String decorationPath, AvatarDecoration decoration) async {
    // Show loading
    setState(() {
      selectedDecoration = decorationPath;
    });

    // Equip the decoration
    final success = await AvatarDecorationService.equipDecoration(
      widget.userId, 
      decoration.id,
    );

    if (success) {
      widget.onDecorationSelected(decorationPath);
      HapticFeedback.heavyImpact();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(decoration.iconEmoji, style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Text('${decoration.name} equipped! ✨'),
              ],
            ),
            backgroundColor: Colors.purple,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Failed to equip decoration'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  List<AvatarDecoration> _filterDecorations(List<AvatarDecoration> decorations) {
    return decorations.where((decoration) {
      // Filter by category
      if (selectedCategory != 'all' && decoration.category != selectedCategory) {
        return false;
      }
      
      // Filter by ownership if enabled
      if (showOnlyOwned && !decoration.isOwned) {
        return false;
      }
      
      return true;
    }).toList();
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
          "Customize Avatar",
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              showOnlyOwned ? Icons.lock_open : Icons.lock,
              color: Colors.grey[700],
            ),
            onPressed: () {
              setState(() {
                showOnlyOwned = !showOnlyOwned;
              });
              HapticFeedback.selectionClick();
            },
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
        child: FutureBuilder<List<AvatarDecoration>>(
          future: _availableDecorations,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading decorations...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorState();
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            final allDecorations = snapshot.data!;
            final filteredDecorations = _filterDecorations(allDecorations);

            return AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) => FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      // Avatar Preview Section
                      _buildAvatarPreview(),
                      
                      // Category Filter
                      _buildCategoryFilter(),
                      
                      // Decorations Grid
                      Expanded(
                        child: _buildDecorationsGrid(filteredDecorations),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAvatarPreview() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          AvatarWithDecoration(
            avatarUrl: widget.avatarUrl,
            decorationPath: selectedDecoration,
            radius: 60,
            showAnimation: true,
            showBorder: true,
            borderColor: Colors.purple,
          ),
          SizedBox(height: 16),
          Text(
            'Preview Your Avatar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Choose a decoration to personalize your avatar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;
          
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                category == 'all' ? 'All' : category.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedCategory = category;
                });
                HapticFeedback.selectionClick();
              },
              backgroundColor: Colors.white,
              selectedColor: Colors.purple,
              elevation: isSelected ? 4 : 2,
              shadowColor: Colors.purple.withOpacity(0.3),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDecorationsGrid(List<AvatarDecoration> decorations) {
    if (decorations.isEmpty) {
      return _buildEmptyFilterState();
    }

    return Padding(
      padding: EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: decorations.length,
        itemBuilder: (context, index) {
          final decoration = decorations[index];
          final isSelected = selectedDecoration == decoration.imagePath;
          
          return _buildDecorationCard(decoration, isSelected);
        },
      ),
    );
  }

  Widget _buildDecorationCard(AvatarDecoration decoration, bool isSelected) {
    final isLocked = !decoration.isOwned;
    
    return GestureDetector(
      onTap: () {
        if (!isLocked) {
          _updateDecoration(decoration.imagePath, decoration);
        } else {
          _showLockedDecorationDialog(decoration);
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? Colors.purple 
                : isLocked 
                    ? Colors.grey.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.2),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? Colors.purple.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: isSelected ? 8 : 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Decoration Icon/Image
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isLocked ? Colors.grey[100] : Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: decoration.imagePath.isEmpty
                        ? Text(
                            decoration.iconEmoji,
                            style: TextStyle(
                              fontSize: 30,
                              color: isLocked ? Colors.grey : null,
                            ),
                          )
                        : ColorFiltered(
                            colorFilter: isLocked
                                ? ColorFilter.mode(Colors.grey, BlendMode.saturation)
                                : ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                            child: Image.asset(
                              decoration.imagePath,
                              width: 40,
                              height: 40,
                              errorBuilder: (context, error, stackTrace) => Text(
                                decoration.iconEmoji,
                                style: TextStyle(fontSize: 30),
                              ),
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 8),
                
                // Decoration Name
                Text(
                  decoration.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected 
                        ? Colors.purple 
                        : isLocked 
                            ? Colors.grey 
                            : Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                // Premium Badge
                if (decoration.isPremium && decoration.isOwned)
                  Container(
                    margin: EdgeInsets.only(top: 4),
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'PREMIUM',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            
            // Lock Overlay
            if (isLocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              
            // Selected Indicator
            if (isSelected && !isLocked)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Error Loading Decorations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please check your connection and try again',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadDecorations,
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No Decorations Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Visit the shop to get amazing decorations\nfor your avatar!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Navigate to shop
              Navigator.pop(context);
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
    );
  }

  Widget _buildEmptyFilterState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_alt_off,
            size: 48,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No decorations found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            showOnlyOwned
                ? 'Try changing filters or visit the shop'
                : 'Try selecting a different category',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showLockedDecorationDialog(AvatarDecoration decoration) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text(decoration.iconEmoji, style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                decoration.name,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (decoration.description != null)
              Text(
                decoration.description!,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This decoration is locked. Visit the shop to unlock it!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to shop
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: Text('Visit Shop'),
          ),
        ],
      ),
    );
  }
}
