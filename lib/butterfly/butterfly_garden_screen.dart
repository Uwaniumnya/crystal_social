import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'butterfly_production_config.dart';

enum ButterflyRarity { common, uncommon, rare, epic, legendary, mythical }

class Butterfly {
  final String id;
  final String name;
  final String imagePath;
  final ButterflyRarity rarity;
  final String description;
  final List<String> habitats;

  Butterfly({
    required this.id, 
    required this.name, 
    required this.imagePath,
    this.rarity = ButterflyRarity.common,
    this.description = "A beautiful butterfly waiting to be discovered...",
    this.habitats = const ["Garden", "Forest"],
  });

  Color get rarityColor {
    switch (rarity) {
      case ButterflyRarity.common: return Colors.grey;
      case ButterflyRarity.uncommon: return Colors.green;
      case ButterflyRarity.rare: return Colors.blue;
      case ButterflyRarity.epic: return Colors.purple;
      case ButterflyRarity.legendary: return Colors.orange;
      case ButterflyRarity.mythical: return Colors.pink;
    }
  }

  String get rarityText {
    switch (rarity) {
      case ButterflyRarity.common: return "Common";
      case ButterflyRarity.uncommon: return "Uncommon";
      case ButterflyRarity.rare: return "Rare";
      case ButterflyRarity.epic: return "Epic";
      case ButterflyRarity.legendary: return "Legendary";
      case ButterflyRarity.mythical: return "Mythical";
    }
  }
}

final List<Butterfly> allButterflies = [
  // First 25 butterflies with detailed descriptions
  Butterfly(id: 'b1', name: 'Azure Whisper', imagePath: 'assets/butterfly/butterfly1.webp', 
    rarity: ButterflyRarity.common, description: 'A gentle blue butterfly that dances on morning breezes.', habitats: ['Garden', 'Meadow']),
  Butterfly(id: 'b2', name: 'Sunflare Wing', imagePath: 'assets/butterfly/butterfly2.webp', 
    rarity: ButterflyRarity.uncommon, description: 'Golden wings that shimmer like captured sunlight.', habitats: ['Sunny Garden', 'Flower Fields']),
  Butterfly(id: 'b3', name: 'Pink Mirage', imagePath: 'assets/butterfly/butterfly3.webp', 
    rarity: ButterflyRarity.common, description: 'Soft pink wings like cherry blossoms in spring.', habitats: ['Cherry Grove', 'Rose Garden']),
  Butterfly(id: 'b4', name: 'Twilight Ember', imagePath: 'assets/butterfly/butterfly4.webp', 
    rarity: ButterflyRarity.rare, description: 'Wings that glow like embers at dusk.', habitats: ['Evening Garden', 'Candlelit Path']),
  Butterfly(id: 'b5', name: 'Lunar Dust', imagePath: 'assets/butterfly/butterfly5.webp', 
    rarity: ButterflyRarity.epic, description: 'Silvery wings that sparkle with moonlight.', habitats: ['Night Garden', 'Moonbeam Grove']),
  Butterfly(id: 'b6', name: 'Mint Dream', imagePath: 'assets/butterfly/butterfly6.webp', rarity: ButterflyRarity.common),
  Butterfly(id: 'b7', name: 'Lavender Mist', imagePath: 'assets/butterfly/butterfly7.webp', rarity: ButterflyRarity.uncommon),
  Butterfly(id: 'b8', name: 'Golden Breeze', imagePath: 'assets/butterfly/butterfly8.webp', rarity: ButterflyRarity.rare),
  Butterfly(id: 'b9', name: 'Coral Glow', imagePath: 'assets/butterfly/butterfly9.webp', rarity: ButterflyRarity.common),
  Butterfly(id: 'b10', name: 'Opal Dusk', imagePath: 'assets/butterfly/butterfly10.webp', rarity: ButterflyRarity.legendary),
  Butterfly(id: 'b11', name: 'Cherry Blossom', imagePath: 'assets/butterfly/butterfly11.webp', rarity: ButterflyRarity.uncommon),
  Butterfly(id: 'b12', name: 'Frosted Sky', imagePath: 'assets/butterfly/butterfly12.webp', rarity: ButterflyRarity.rare),
  Butterfly(id: 'b13', name: 'Emerald Song', imagePath: 'assets/butterfly/butterfly13.webp', rarity: ButterflyRarity.epic),
  Butterfly(id: 'b14', name: 'Peach Fizz', imagePath: 'assets/butterfly/butterfly14.webp', rarity: ButterflyRarity.common),
  Butterfly(id: 'b15', name: 'Violet Veil', imagePath: 'assets/butterfly/butterfly15.webp', rarity: ButterflyRarity.rare),
  Butterfly(id: 'b16', name: 'Lemon Zest', imagePath: 'assets/butterfly/butterfly16.webp', rarity: ButterflyRarity.common),
  Butterfly(id: 'b17', name: 'Sapphire Shine', imagePath: 'assets/butterfly/butterfly17.webp', rarity: ButterflyRarity.legendary),
  Butterfly(id: 'b18', name: 'Rose Quartz', imagePath: 'assets/butterfly/butterfly18.webp', rarity: ButterflyRarity.epic),
  Butterfly(id: 'b19', name: 'Amber Spark', imagePath: 'assets/butterfly/butterfly19.webp', rarity: ButterflyRarity.rare),
  Butterfly(id: 'b20', name: 'Celestial Wave', imagePath: 'assets/butterfly/butterfly20.webp', rarity: ButterflyRarity.mythical),
  Butterfly(id: 'b21', name: 'Jade Ripple', imagePath: 'assets/butterfly/butterfly21.webp', rarity: ButterflyRarity.uncommon),
  Butterfly(id: 'b22', name: 'Sunset Gleam', imagePath: 'assets/butterfly/butterfly22.webp', rarity: ButterflyRarity.rare),
  Butterfly(id: 'b23', name: 'Berry Bliss', imagePath: 'assets/butterfly/butterfly23.webp', rarity: ButterflyRarity.common),
  Butterfly(id: 'b24', name: 'Moonlit Dew', imagePath: 'assets/butterfly/butterfly24.webp', rarity: ButterflyRarity.epic),
  Butterfly(id: 'b25', name: 'Tangerine Dream', imagePath: 'assets/butterfly/butterfly25.webp', rarity: ButterflyRarity.uncommon),
  
  // Additional butterflies 26-90 to match all assets in your folder
  Butterfly(id: 'b26', name: 'Crystal Prism', imagePath: 'assets/butterfly/butterfly26.webp', rarity: ButterflyRarity.rare),
  Butterfly(id: 'b27', name: 'Ocean Spray', imagePath: 'assets/butterfly/butterfly27.webp', rarity: ButterflyRarity.common),
  Butterfly(id: 'b28', name: 'Autumn Flame', imagePath: 'assets/butterfly/butterfly28.webp', rarity: ButterflyRarity.uncommon),
  Butterfly(id: 'b29', name: 'Starlight Shimmer', imagePath: 'assets/butterfly/butterfly29.webp', rarity: ButterflyRarity.epic),
  Butterfly(id: 'b30', name: 'Forest Whisper', imagePath: 'assets/butterfly/butterfly30.webp', rarity: ButterflyRarity.common),
  Butterfly(id: 'b31', name: 'Ruby Flash', imagePath: 'assets/butterfly/butterfly31.webp', rarity: ButterflyRarity.legendary),
  Butterfly(id: 'b32', name: 'Snow Crystal', imagePath: 'assets/butterfly/butterfly32.webp', rarity: ButterflyRarity.rare),
  Butterfly(id: 'b33', name: 'Honey Glow', imagePath: 'assets/butterfly/butterfly33.webp', rarity: ButterflyRarity.uncommon),
  Butterfly(id: 'b34', name: 'Mystic Purple', imagePath: 'assets/butterfly/butterfly34.webp', rarity: ButterflyRarity.epic),
  Butterfly(id: 'b35', name: 'Dawn Light', imagePath: 'assets/butterfly/butterfly35.webp', rarity: ButterflyRarity.common),
  Butterfly(id: 'b36', name: 'Copper Wing', imagePath: 'assets/butterfly/butterfly36.webp', rarity: ButterflyRarity.rare),
  Butterfly(id: 'b37', name: 'Silver Moon', imagePath: 'assets/butterfly/butterfly37.webp', rarity: ButterflyRarity.legendary),
  Butterfly(id: 'b38', name: 'Gentle Breeze', imagePath: 'assets/butterfly/butterfly38.webp', rarity: ButterflyRarity.common),
  Butterfly(id: 'b39', name: 'Crimson Sunset', imagePath: 'assets/butterfly/butterfly39.webp', rarity: ButterflyRarity.uncommon),
  Butterfly(id: 'b40', name: 'Diamond Dust', imagePath: 'assets/butterfly/butterfly40.webp', rarity: ButterflyRarity.mythical),
  Butterfly(id: 'b41', name: 'Meadow Song', imagePath: 'assets/butterfly/butterfly41.webp', rarity: ButterflyRarity.common),
  Butterfly(id: 'b42', name: 'Thunder Cloud', imagePath: 'assets/butterfly/butterfly42.webp', rarity: ButterflyRarity.rare),
  Butterfly(id: 'b43', name: 'Spring Bloom', imagePath: 'assets/butterfly/butterfly43.webp', rarity: ButterflyRarity.uncommon),
  Butterfly(id: 'b44', name: 'Cosmic Dance', imagePath: 'assets/butterfly/butterfly44.webp', rarity: ButterflyRarity.epic),
  Butterfly(id: 'b45', name: 'Willow Grace', imagePath: 'assets/butterfly/butterfly45.webp', rarity: ButterflyRarity.common),
  Butterfly(id: 'b46', name: 'Phoenix Fire', imagePath: 'assets/butterfly/butterfly46.webp', rarity: ButterflyRarity.legendary),
  Butterfly(id: 'b47', name: 'Morning Dew', imagePath: 'assets/butterfly/butterfly47.webp', rarity: ButterflyRarity.rare),
  Butterfly(id: 'b48', name: 'Velvet Touch', imagePath: 'assets/butterfly/butterfly48.webp', rarity: ButterflyRarity.uncommon),
  Butterfly(id: 'b49', name: 'Rainbow Mist', imagePath: 'assets/butterfly/butterfly49.webp', rarity: ButterflyRarity.epic),
  Butterfly(id: 'b50', name: 'Twilight Star', imagePath: 'assets/butterfly/butterfly50.webp', rarity: ButterflyRarity.mythical),
  Butterfly(id: 'b51', name: 'Garden Light', imagePath: 'assets/butterfly/butterfly51.webp', rarity: ButterflyRarity.common),
  Butterfly(id: 'b52', name: 'Storm Wing', imagePath: 'assets/butterfly/butterfly52.webp', rarity: ButterflyRarity.rare),
  Butterfly(id: 'b53', name: 'Petal Dance', imagePath: 'assets/butterfly/butterfly53.webp', rarity: ButterflyRarity.uncommon),
  Butterfly(id: 'b54', name: 'Galaxy Swirl', imagePath: 'assets/butterfly/butterfly54.webp', rarity: ButterflyRarity.legendary),
  Butterfly(id: 'b55', name: 'Sunshine Ray', imagePath: 'assets/butterfly/butterfly55.webp', rarity: ButterflyRarity.common),
  Butterfly(id: 'b56', name: 'Ice Crystal', imagePath: 'assets/butterfly/butterfly56.webp', rarity: ButterflyRarity.epic),
  Butterfly(id: 'b57', name: 'Flower Spirit', imagePath: 'assets/butterfly/butterfly57.webp', rarity: ButterflyRarity.rare),
  Butterfly(id: 'b58', name: 'Wind Dancer', imagePath: 'assets/butterfly/butterfly58.webp', rarity: ButterflyRarity.uncommon),
  Butterfly(id: 'b59', name: 'Starfall', imagePath: 'assets/butterfly/butterfly59.webp', rarity: ButterflyRarity.mythical),
  Butterfly(id: 'b60', name: 'Dewdrop', imagePath: 'assets/butterfly/butterfly60.webp', rarity: ButterflyRarity.common),
  Butterfly(id: 'b61', name: 'Fire Opal', imagePath: 'assets/butterfly/butterfly61.webp', rarity: ButterflyRarity.legendary),
  Butterfly(id: 'b62', name: 'Sky Blue', imagePath: 'assets/butterfly/butterfly62.webp', rarity: ButterflyRarity.rare),
  Butterfly(id: 'b63', name: 'Soft Whisper', imagePath: 'assets/butterfly/butterfly63.webp', rarity: ButterflyRarity.uncommon),
  Butterfly(id: 'b64', name: 'Prism Light', imagePath: 'assets/butterfly/butterfly64.webp', rarity: ButterflyRarity.epic),
  Butterfly(id: 'b65', name: 'Grass Green', imagePath: 'assets/butterfly/butterfly65.webp', rarity: ButterflyRarity.common),
  Butterfly(id: 'b66', name: 'Thunder Strike', imagePath: 'assets/butterfly/butterfly66.webp', rarity: ButterflyRarity.rare),
  Butterfly(id: 'b67', name: 'Rose Petal', imagePath: 'assets/butterfly/butterfly67.webp', rarity: ButterflyRarity.uncommon),
  Butterfly(id: 'b68', name: 'Nebula Drift', imagePath: 'assets/butterfly/butterfly68.webp', rarity: ButterflyRarity.mythical),
  Butterfly(id: 'b69', name: 'Lily White', imagePath: 'assets/butterfly/butterfly69.webp', rarity: ButterflyRarity.common),
  Butterfly(id: 'b70', name: 'Dragon Fire', imagePath: 'assets/butterfly/butterfly70.webp', rarity: ButterflyRarity.legendary),
  Butterfly(id: 'b71', name: 'Ocean Wave', imagePath: 'assets/butterfly/butterfly71.webp', rarity: ButterflyRarity.epic),
  Butterfly(id: 'b72', name: 'Breeze Flow', imagePath: 'assets/butterfly/butterfly72.webp', rarity: ButterflyRarity.rare),
  Butterfly(id: 'b73', name: 'Sweet Dream', imagePath: 'assets/butterfly/butterfly73.webp', rarity: ButterflyRarity.uncommon),
  Butterfly(id: 'b74', name: 'Solar Flare', imagePath: 'assets/butterfly/butterfly74.webp', rarity: ButterflyRarity.common),
  Butterfly(id: 'b75', name: 'Frost Wing', imagePath: 'assets/butterfly/butterfly75.webp', rarity: ButterflyRarity.rare),
  Butterfly(id: 'b76', name: 'Angel Wing', imagePath: 'assets/butterfly/butterfly76.webp', rarity: ButterflyRarity.mythical),
  Butterfly(id: 'b77', name: 'Earth Song', imagePath: 'assets/butterfly/butterfly77.webp', rarity: ButterflyRarity.uncommon),
  Butterfly(id: 'b78', name: 'Spirit Dance', imagePath: 'assets/butterfly/butterfly78.webp', rarity: ButterflyRarity.epic),
  Butterfly(id: 'b79', name: 'Sun Beam', imagePath: 'assets/butterfly/butterfly79.webp', rarity: ButterflyRarity.common),
  Butterfly(id: 'b80', name: 'Dark Moon', imagePath: 'assets/butterfly/butterfly80.webp', rarity: ButterflyRarity.legendary),
  Butterfly(id: 'b81', name: 'Cloud Walker', imagePath: 'assets/butterfly/butterfly81.webp', rarity: ButterflyRarity.rare),
  Butterfly(id: 'b82', name: 'Gentle Rain', imagePath: 'assets/butterfly/butterfly82.webp', rarity: ButterflyRarity.uncommon),
  Butterfly(id: 'b83', name: 'Light Bearer', imagePath: 'assets/butterfly/butterfly83.webp', rarity: ButterflyRarity.epic),
  Butterfly(id: 'b84', name: 'Moon Glow', imagePath: 'assets/butterfly/butterfly84.webp', rarity: ButterflyRarity.common),
  Butterfly(id: 'b85', name: 'Fire Storm', imagePath: 'assets/butterfly/butterfly85.webp', rarity: ButterflyRarity.legendary),
  Butterfly(id: 'b86', name: 'Mist Walker', imagePath: 'assets/butterfly/butterfly86.webp', rarity: ButterflyRarity.rare),
  Butterfly(id: 'b87', name: 'Dream Weaver', imagePath: 'assets/butterfly/butterfly87.webp', rarity: ButterflyRarity.mythical),
  Butterfly(id: 'b88', name: 'Star Dust', imagePath: 'assets/butterfly/butterfly88.webp', rarity: ButterflyRarity.epic),
  Butterfly(id: 'b89', name: 'Wind Song', imagePath: 'assets/butterfly/butterfly89.webp', rarity: ButterflyRarity.uncommon),
  Butterfly(id: 'b90', name: 'Eternal Light', imagePath: 'assets/butterfly/butterfly90.webp', rarity: ButterflyRarity.mythical),
];

class EnhancedButterflyGardenScreen extends StatefulWidget {
  final String userId;
  final bool earnedFromButterflyMode;

  const EnhancedButterflyGardenScreen({
    super.key,
    required this.userId,
    this.earnedFromButterflyMode = false,
  });

  @override
  State<EnhancedButterflyGardenScreen> createState() => _EnhancedButterflyGardenScreenState();
}

class _EnhancedButterflyGardenScreenState extends State<EnhancedButterflyGardenScreen> 
    with TickerProviderStateMixin {
  List<String> unlockedIds = [];
  List<String> favoriteIds = [];
  bool loading = true;
  final supabase = Supabase.instance.client;
  late AudioPlayer _player;
  late AudioPlayer _effectPlayer;
  late List<AnimationController> _controllers;
  late List<Animation<double>> _shakes;
  late List<bool> _isShaking;
  late List<Timer> _timers;
  late AnimationController _sparkleController;
  late Animation<double> _sparkleAnimation;
  
  // Enhanced features
  String _searchQuery = '';
  ButterflyRarity? _selectedRarity;
  bool _showOnlyFavorites = false;
  bool _showStats = false;
  int _dailyDiscoveries = 0;
  DateTime? _lastDailyReward;
  
  // Collection stats
  int get totalUnlocked => unlockedIds.length;
  double get collectionProgress => totalUnlocked / allButterflies.length;
  
  Map<ButterflyRarity, int> get rarityStats {
    Map<ButterflyRarity, int> stats = {};
    for (var rarity in ButterflyRarity.values) {
      stats[rarity] = unlockedIds.where((id) {
        final butterfly = allButterflies.firstWhere((b) => b.id == id);
        return butterfly.rarity == rarity;
      }).length;
    }
    return stats;
  }

  List<Butterfly> get filteredButterflies {
    List<Butterfly> filtered = List.from(allButterflies);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((b) => 
        b.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    
    // Apply rarity filter
    if (_selectedRarity != null) {
      filtered = filtered.where((b) => b.rarity == _selectedRarity).toList();
    }
    
    // Apply favorites filter
    if (_showOnlyFavorites) {
      filtered = filtered.where((b) => favoriteIds.contains(b.id)).toList();
    }
    
    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _loadUnlockedButterflies();
    _loadFavorites();
    _checkDailyReward();
    
    // Audio setup
    _player = AudioPlayer();
    _effectPlayer = AudioPlayer();
    _player.setAsset('assets/butterfly/chimes.mp3');
    _player.setLoopMode(LoopMode.all);
    _player.play();

    // Sparkle animation setup
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut));
    _sparkleController.repeat();

    // Init butterfly animations and shake logic
    _controllers = [];
    _shakes = [];
    _isShaking = List.filled(allButterflies.length, false);
    _timers = [];
    final rng = Random();
    for (int i = 0; i < allButterflies.length; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
      final animation = Tween<double>(begin: -2.0, end: 2.0)
          .chain(CurveTween(curve: Curves.easeInOut))
          .animate(controller);
      _controllers.add(controller);
      _shakes.add(animation);
      // Timer to randomly trigger shake
      _timers.add(
        Timer.periodic(Duration(seconds: 2 + rng.nextInt(5)), (timer) {
          if (mounted) {
            _controllers[i].forward(from: 0);
            setState(() {
              _isShaking[i] = true;
            });
            Future.delayed(const Duration(milliseconds: 600), () {
              if (mounted) {
                setState(() {
                  _isShaking[i] = false;
                });
              }
            });
          }
        }),
      );
    }

    // Pre-cache unlocked butterfly images for smoother experience
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (int i = 0; i < allButterflies.length; i++) {
        final butterfly = allButterflies[i];
        if (unlockedIds.contains(butterfly.id)) {
          precacheImage(AssetImage(butterfly.imagePath), context);
        }
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final t in _timers) {
      t.cancel();
    }
    _player.dispose();
    _effectPlayer.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  Future<void> _loadUnlockedButterflies() async {
    final response = await supabase
        .from('butterfly_album')
        .select('butterfly_id')
        .eq('user_id', widget.userId);

    unlockedIds = response.map((b) => b['butterfly_id'] as String).toList();

    if (widget.earnedFromButterflyMode) {
      await _unlockRandomButterfly();
    }

    setState(() => loading = false);
  }

  Future<void> _loadFavorites() async {
    try {
      final response = await supabase
          .from('butterfly_favorites')
          .select('butterfly_id')
          .eq('user_id', widget.userId);
      
      favoriteIds = response.map((b) => b['butterfly_id'] as String).toList();
    } catch (e) {
      // Table might not exist yet, that's okay
      favoriteIds = [];
    }
  }

  Future<void> _checkDailyReward() async {
    // Check if user can get daily reward
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (_lastDailyReward == null || _lastDailyReward!.isBefore(today)) {
      _dailyDiscoveries = 3; // Give 3 daily discoveries
      _lastDailyReward = today;
    }
  }

  Future<void> _unlockRandomButterfly() async {
    final locked = allButterflies.where((b) => !unlockedIds.contains(b.id)).toList();
    if (locked.isEmpty) return;

    final newButterfly = locked[Random().nextInt(locked.length)];

    await supabase.from('butterfly_album').insert({
      'user_id': widget.userId,
      'butterfly_id': newButterfly.id,
    });

    unlockedIds.add(newButterfly.id);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.pink.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('🌸 New Butterfly Appeared!'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: newButterfly.rarityColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: newButterfly.rarityColor),
              ),
              child: Text(
                newButterfly.rarityText,
                style: TextStyle(
                  color: newButterfly.rarityColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: newButterfly.rarityColor.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Image.asset(newButterfly.imagePath, height: 100),
            ),
            const SizedBox(height: 10),
            Text(
              newButterfly.name,
              style: TextStyle(
                fontFamily: 'DancingScript',
                fontSize: 22,
                color: newButterfly.rarityColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              newButterfly.description,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('✨ Beautiful!'),
          )
        ],
      ),
    );
  }

  Future<void> _toggleFavorite(String butterflyId) async {
    try {
      if (favoriteIds.contains(butterflyId)) {
        await supabase
            .from('butterfly_favorites')
            .delete()
            .eq('user_id', widget.userId)
            .eq('butterfly_id', butterflyId);
        favoriteIds.remove(butterflyId);
      } else {
        await supabase.from('butterfly_favorites').insert({
          'user_id': widget.userId,
          'butterfly_id': butterflyId,
        });
        favoriteIds.add(butterflyId);
      }
      setState(() {});
    } catch (e) {
      // Handle error gracefully
      ButterflyErrorHandler.handleDatabaseError('ToggleFavorite', e);
    }
  }

  Future<void> _playInteractionSound(ButterflyRarity rarity) async {
    String soundPath = 'assets/butterfly/chimes.mp3';
    switch (rarity) {
      case ButterflyRarity.epic:
        soundPath = 'assets/butterfly/magical_chime.mp3';
        break;
      case ButterflyRarity.legendary:
        soundPath = 'assets/butterfly/legendary_bell.mp3';
        break;
      case ButterflyRarity.mythical:
        soundPath = 'assets/butterfly/mythical_sparkle.mp3';
        break;
      default:
        soundPath = 'assets/butterfly/chimes.mp3';
    }
    
    try {
      await _effectPlayer.setAsset(soundPath);
      await _effectPlayer.play();
    } catch (e) {
      // Fallback to default sound
      await _effectPlayer.setAsset('assets/butterfly/chimes.mp3');
      await _effectPlayer.play();
    }
  }

  void _showButterflyDetails(Butterfly butterfly) {
    final isUnlocked = unlockedIds.contains(butterfly.id);
    final isFavorite = favoriteIds.contains(butterfly.id);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Expanded(
              child: Text(
                isUnlocked ? butterfly.name : '???',
                style: TextStyle(
                  fontFamily: 'DancingScript',
                  fontSize: 24,
                  color: butterfly.rarityColor,
                ),
              ),
            ),
            if (isUnlocked)
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: Colors.pink,
                ),
                onPressed: () => _toggleFavorite(butterfly.id),
              ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                butterfly.imagePath,
                height: 120,
                opacity: isUnlocked ? null : const AlwaysStoppedAnimation(0.3),
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: butterfly.rarityColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: butterfly.rarityColor),
              ),
              child: Text(
                butterfly.rarityText,
                style: TextStyle(
                  color: butterfly.rarityColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isUnlocked) ...[
              const SizedBox(height: 10),
              Text(
                butterfly.description,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 5,
                children: butterfly.habitats.map((habitat) => 
                  Chip(
                    label: Text(habitat, style: const TextStyle(fontSize: 12)),
                    backgroundColor: Colors.green.withOpacity(0.1),
                  )).toList(),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (isUnlocked) {
                _playInteractionSound(butterfly.rarity);
              }
            },
            child: Text(isUnlocked ? '✨ Beautiful!' : '🔒 Locked'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '🦋 Crystal Butterfly Garden',
                  style: TextStyle(
                    fontFamily: 'DancingScript',
                    fontSize: 28,
                    color: Color(0xffb35dd3),
                    shadows: [
                      Shadow(color: Colors.white, blurRadius: 10),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(_showStats ? Icons.grid_view : Icons.analytics),
                onPressed: () => setState(() => _showStats = !_showStats),
              ),
            ],
          ),
          if (_showStats) _buildStatsPanel(),
          const SizedBox(height: 10),
          _buildSearchAndFilters(),
        ],
      ),
    );
  }

  Widget _buildStatsPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Collected', '$totalUnlocked/${allButterflies.length}'),
              _buildStatItem('Progress', '${(collectionProgress * 100).toInt()}%'),
              _buildStatItem('Daily', '$_dailyDiscoveries left'),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: collectionProgress,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Search butterflies...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.8),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<ButterflyRarity?>(
                value: _selectedRarity,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.8),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                hint: const Text('Filter by rarity'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Rarities')),
                  ...ButterflyRarity.values.map((rarity) => 
                    DropdownMenuItem(
                      value: rarity,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: allButterflies.first.rarityColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(rarity.name.toUpperCase()),
                        ],
                      ),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _selectedRarity = value),
              ),
            ),
            const SizedBox(width: 10),
            FilterChip(
              label: const Icon(Icons.favorite, size: 18),
              selected: _showOnlyFavorites,
              onSelected: (selected) => setState(() => _showOnlyFavorites = selected),
              selectedColor: Colors.pink.withOpacity(0.3),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildButterflyCard(Butterfly butterfly, int index) {
    final isUnlocked = unlockedIds.contains(butterfly.id);
    final isFavorite = favoriteIds.contains(butterfly.id);
    
    return GestureDetector(
      onTap: () => _showButterflyDetails(butterfly),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? Colors.white.withOpacity(0.6)
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isUnlocked ? butterfly.rarityColor.withOpacity(0.8) : Colors.grey.shade300,
                width: 2,
              ),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: butterfly.rarityColor.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 1,
                      )
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background jar
                    Image.asset(
                      'assets/butterfly/jar.png',
                      height: 100,
                      cacheWidth: 200,
                      cacheHeight: 100,
                    ),
                    // Butterfly with animation - positioned inside jar
                    Positioned(
                      top: 25, // Move butterfly down into jar
                      child: _isShaking[index]
                          ? AnimatedBuilder(
                              animation: _shakes[index],
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(_shakes[index].value, 0),
                                  child: child,
                                );
                              },
                              child: _buildButterflyImage(butterfly, isUnlocked),
                            )
                          : _buildButterflyImage(butterfly, isUnlocked),
                    ),
                    // Favorite indicator
                    if (isUnlocked && isFavorite)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Icon(Icons.favorite, color: Colors.pink, size: 16),
                      ),
                    // Rarity indicator
                    if (isUnlocked)
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: butterfly.rarityColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isUnlocked ? butterfly.name : "???",
                  style: TextStyle(
                    fontFamily: 'DancingScript',
                    fontSize: 16,
                    color: isUnlocked ? butterfly.rarityColor : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (isUnlocked)
                  Text(
                    butterfly.rarityText,
                    style: TextStyle(
                      fontSize: 10,
                      color: butterfly.rarityColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButterflyImage(Butterfly butterfly, bool isUnlocked) {
    return Opacity(
      opacity: isUnlocked ? 1 : 0.2,
      child: Image.asset(
        butterfly.imagePath,
        height: 35, // Slightly smaller to fit better inside jar
        width: 35,
        cacheWidth: 70,
        cacheHeight: 70,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Enhanced gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xfffef1f6), 
                  Color(0xffe7f0fd),
                  Color(0xfff0e7fd),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Animated sparkle overlay
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _sparkleAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.1 * _sparkleAnimation.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          SafeArea(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: filteredButterflies.length,
                          itemBuilder: (context, index) {
                            final butterfly = filteredButterflies[index];
                            final originalIndex = allButterflies.indexOf(butterfly);
                            return _buildButterflyCard(butterfly, originalIndex);
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
