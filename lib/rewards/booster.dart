import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

final supabase = Supabase.instance.client;
final audioPlayer = AudioPlayer();

class BoosterPackScreen extends StatefulWidget {
  final Map<String, dynamic>? boosterItem; // The booster pack item from shop
  
  const BoosterPackScreen({super.key, this.boosterItem});

  @override
  State<BoosterPackScreen> createState() => _BoosterPackScreenState();
}

class _BoosterPackScreenState extends State<BoosterPackScreen> 
    with TickerProviderStateMixin {
  final ConfettiController _confetti = ConfettiController(duration: const Duration(seconds: 4));
  final ConfettiController _goldConfetti = ConfettiController(duration: const Duration(seconds: 3));
  final ConfettiController _rareConfetti = ConfettiController(duration: const Duration(seconds: 2));
  List<Map<String, dynamic>> pulledItems = [];
  bool opened = false;
  bool isOpening = false;
  bool showReveal = false;
  int userCoins = 0;
  int totalPacksOpened = 0;
  int rareItemsFound = 0;
  bool showStatistics = false;
  List<Map<String, dynamic>> openingHistory = [];
  String selectedPackAnimation = 'default'; // default, epic, legendary
  
  // Animation controllers for spectacular effects
  late AnimationController _packController;
  late AnimationController _shakeController;
  late AnimationController _glowController;
  late AnimationController _cardRevealController;
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _sparkleController;
  
  // Animations
  late Animation<double> _packScale;
  late Animation<double> _shakeAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _sparkleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserInfo();
  }

  void _initializeAnimations() {
    _packController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _cardRevealController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _packScale = Tween<double>(begin: 1.0, end: 1.2)
        .animate(CurvedAnimation(parent: _packController, curve: Curves.elasticOut));
    
    _shakeAnimation = Tween<double>(begin: -5.0, end: 5.0)
        .animate(CurvedAnimation(parent: _shakeController, curve: Curves.elasticInOut));
    
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
    
    _floatAnimation = Tween<double>(begin: 0.0, end: -20.0)
        .animate(CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut));

    _colorAnimation = ColorTween(
      begin: Colors.purple,
      end: Colors.pink,
    ).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

    _floatController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
    _sparkleController.repeat(reverse: true);
    
    _loadPackStatistics();
  }

  Future<void> _loadUserInfo() async {
    final userId = supabase.auth.currentUser!.id;
    final userRes = await supabase.from('users').select('coins').eq('id', userId).single();
    setState(() {
      userCoins = userRes['coins'] ?? 0;
    });
  }

  // Load pack opening statistics
  Future<void> _loadPackStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        totalPacksOpened = prefs.getInt('total_packs_opened') ?? 0;
        rareItemsFound = prefs.getInt('rare_items_found') ?? 0;
        
        // Load opening history
        final historyJson = prefs.getString('opening_history');
        if (historyJson != null) {
          final List<dynamic> historyList = jsonDecode(historyJson);
          openingHistory = historyList.cast<Map<String, dynamic>>();
        }
      });
    } catch (e) {
      print('Error loading pack statistics: $e');
    }
  }

  // Save pack opening statistics
  Future<void> _savePackStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('total_packs_opened', totalPacksOpened);
      await prefs.setInt('rare_items_found', rareItemsFound);
      
      // Save opening history (keep last 50 entries)
      final limitedHistory = openingHistory.take(50).toList();
      await prefs.setString('opening_history', jsonEncode(limitedHistory));
    } catch (e) {
      print('Error saving pack statistics: $e');
    }
  }

  // Add opening to history
  void _addToHistory(List<Map<String, dynamic>> items) {
    final opening = {
      'timestamp': DateTime.now().toIso8601String(),
      'items': items.map((item) => {
        'name': item['name'],
        'rarity': item['rarity'],
        'type': item['type'],
      }).toList(),
      'pack_name': widget.boosterItem?['name'] ?? 'Unknown Pack',
    };
    
    setState(() {
      openingHistory.insert(0, opening);
      totalPacksOpened++;
      
      // Count rare items
      final rareCount = items.where((item) => 
        ['rare', 'epic', 'legendary'].contains(item['rarity']?.toLowerCase())
      ).length;
      rareItemsFound += rareCount;
    });
    
    _savePackStatistics();
  }

  // Show pack statistics dialog
  void _showPackStatistics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text(
          '📊 Pack Statistics',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatRow('Total Packs Opened', totalPacksOpened.toString(), Icons.inventory),
              _buildStatRow('Rare Items Found', rareItemsFound.toString(), Icons.star),
              _buildStatRow('Success Rate', 
                totalPacksOpened > 0 ? '${((rareItemsFound / totalPacksOpened) * 100).toStringAsFixed(1)}%' : '0%',
                Icons.trending_up),
              const SizedBox(height: 20),
              const Text(
                'Recent Openings:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: openingHistory.take(5).length,
                  itemBuilder: (context, index) {
                    final opening = openingHistory[index];
                    final items = opening['items'] as List<dynamic>;
                    return Card(
                      color: const Color(0xFF2a2a3e),
                      child: ListTile(
                        title: Text(
                          opening['pack_name'],
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        subtitle: Text(
                          '${items.length} items • ${items.where((item) => ['rare', 'epic', 'legendary'].contains(item['rarity'])).length} rare',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                        ),
                        trailing: Text(
                          _formatTimeAgo(DateTime.parse(opening['timestamp'])),
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.pink)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.pink, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.pink,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }

  // Show pack information dialog
  void _showPackInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text(
          widget.boosterItem?['name'] ?? 'Pack Information',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.boosterItem?['description'] ?? 'A mystical booster pack containing random items.',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'Drop Rates:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildDropRateRow('Common', '50%', Colors.grey),
            _buildDropRateRow('Rare', '30%', Colors.blue),
            _buildDropRateRow('Epic', '15%', Colors.purple),
            _buildDropRateRow('Legendary', '5%', Colors.orange),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.withOpacity(0.5)),
              ),
              child: const Text(
                '💡 Tip: Every 3rd pack is guaranteed to contain at least one rare item!',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.pink)),
          ),
        ],
      ),
    );
  }

  Widget _buildDropRateRow(String rarity, String rate, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(rarity, style: const TextStyle(color: Colors.white)),
            ],
          ),
          Text(
            rate,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Share epic pull feature
  void _shareEpicPull() {
    final rareItems = pulledItems.where((item) => 
      ['rare', 'epic', 'legendary'].contains(item['rarity']?.toLowerCase())
    ).toList();
    
    if (rareItems.isEmpty) return;
    
    String shareText = "🎉 Amazing booster pack pull! 🎉\n\n";
    shareText += "Pack: ${widget.boosterItem?['name'] ?? 'Mystery Pack'}\n";
    shareText += "Items obtained:\n";
    
    for (final item in rareItems) {
      final rarity = item['rarity']?.toUpperCase() ?? 'COMMON';
      String emoji = '';
      switch (rarity.toLowerCase()) {
        case 'legendary':
          emoji = '🌟';
          break;
        case 'epic':
          emoji = '⚡';
          break;
        case 'rare':
          emoji = '💎';
          break;
      }
      shareText += "• $emoji $rarity: ${item['name']}\n";
    }
    
    shareText += "\n#CrystalSocial #BoosterPack #LuckyPull";
    
    // Show share dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text(
          '📱 Share Your Epic Pull!',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                shareText,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'Copy the text above to share on your favorite social platform!',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: shareText));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Copied to clipboard!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('📋 Copy Text', style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.pink)),
          ),
        ],
      ),
    );
  }

  // Get rarity weight for item selection probability
  int _getRarityWeight(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common': return 50;  // 50% chance
      case 'rare': return 30;    // 30% chance  
      case 'epic': return 15;    // 15% chance
      case 'legendary': return 5; // 5% chance
      default: return 50;
    }
  }

  // Select items based on rarity weights with guaranteed rare system
  List<Map<String, dynamic>> _selectItemsByRarityEnhanced(List<Map<String, dynamic>> items, int count) {
    List<Map<String, dynamic>> selectedItems = [];
    List<Map<String, dynamic>> weightedItems = [];
    
    // Separate items by rarity for guaranteed system
    final rareItems = items.where((item) => (item['rarity'] ?? '').toLowerCase() == 'rare').toList();
    final epicItems = items.where((item) => (item['rarity'] ?? '').toLowerCase() == 'epic').toList();
    final legendaryItems = items.where((item) => (item['rarity'] ?? '').toLowerCase() == 'legendary').toList();
    
    Random rng = Random();
    Set<int> usedIds = {};
    
    // Guaranteed rare system - every 3rd pack should have at least one rare+
    final packNumber = totalPacksOpened + 1;
    bool guaranteedRare = packNumber % 3 == 0;
    
    if (guaranteedRare && (rareItems.isNotEmpty || epicItems.isNotEmpty || legendaryItems.isNotEmpty)) {
      // Add guaranteed rare item
      List<Map<String, dynamic>> rarePool = [...rareItems, ...epicItems, ...legendaryItems];
      if (rarePool.isNotEmpty) {
        final guaranteedItem = rarePool[rng.nextInt(rarePool.length)];
        selectedItems.add(guaranteedItem);
        usedIds.add(guaranteedItem['id']);
        count--;
      }
    }
    
    // Create weighted list for remaining items
    for (var item in items) {
      if (usedIds.contains(item['id'])) continue;
      
      int weight = _getRarityWeight(item['rarity'] ?? 'common');
      for (int i = 0; i < weight; i++) {
        weightedItems.add(item);
      }
    }
    
    // Select remaining items
    for (int i = 0; i < count && selectedItems.length < items.length; i++) {
      if (weightedItems.isEmpty) break;
      
      Map<String, dynamic> selectedItem;
      int attempts = 0;
      
      do {
        selectedItem = weightedItems[rng.nextInt(weightedItems.length)];
        attempts++;
      } while (usedIds.contains(selectedItem['id']) && attempts < 50);
      
      if (!usedIds.contains(selectedItem['id'])) {
        selectedItems.add(selectedItem);
        usedIds.add(selectedItem['id']);
        
        // Remove this item from weighted list to prevent duplicates
        weightedItems.removeWhere((item) => item['id'] == selectedItem['id']);
      }
    }
    
    return selectedItems;
  }

  Future<void> _openBoosterPack() async {
    if (widget.boosterItem == null) return;
    
    setState(() { isOpening = true; });
    
    // Start epic opening sequence
    HapticFeedback.mediumImpact();
    _startOpeningAnimation();
    
    try {
      final categoryReferenceId = widget.boosterItem!['category_reference_id'];
      final userId = supabase.auth.currentUser!.id;
      
      // Get items from the referenced category
      final items = await supabase
          .from('shop_items')
          .select('*')
          .eq('category_id', categoryReferenceId)
          .neq('category_id', 7); // Exclude other booster packs

      if (items.isEmpty) {
        _showError("No items available in this category!");
        return;
      }

      // Select 1-4 items based on rarity weights with guaranteed rare chance
      final itemsToGive = _selectItemsByRarityEnhanced(items, Random().nextInt(3) + 2);
      
      // Add dramatic delay for anticipation
      await Future.delayed(const Duration(seconds: 3));
      
      // Add items to inventory
      for (final item in itemsToGive) {
        await supabase.from('user_inventory').upsert({
          'user_id': userId,
          'item_id': item['id'],
          'quantity': 1,
          'obtained_from': 'booster_pack',
          'obtained_at': DateTime.now().toIso8601String(),
        });
      }

      // Add to opening history
      _addToHistory(itemsToGive);

      setState(() {
        pulledItems = itemsToGive;
        opened = true;
        isOpening = false;
        showReveal = true;
      });

      _startRevealAnimation();
      _playSpecialEffects();
      
    } catch (e) {
      _showError("Error opening booster pack: $e");
    }
  }

  void _startOpeningAnimation() async {
    // Shake effect
    for (int i = 0; i < 5; i++) {
      _shakeController.forward();
      await Future.delayed(const Duration(milliseconds: 100));
      _shakeController.reverse();
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    // Pack scale animation
    _packController.forward();
  }

  void _startRevealAnimation() {
    _cardRevealController.forward();
    _confetti.play();
    
    // Check for different rarities for enhanced effects
    bool hasLegendary = pulledItems.any((item) => 
        (item['rarity'] ?? '').toLowerCase() == 'legendary');
    bool hasEpic = pulledItems.any((item) => 
        (item['rarity'] ?? '').toLowerCase() == 'epic');
    bool hasRare = pulledItems.any((item) => 
        (item['rarity'] ?? '').toLowerCase() == 'rare');
    
    if (hasLegendary) {
      _goldConfetti.play();
      _rareConfetti.play();
      HapticFeedback.heavyImpact();
      selectedPackAnimation = 'legendary';
      _showSpecialMessage('LEGENDARY PULL! 🌟✨');
    } else if (hasEpic) {
      _goldConfetti.play();
      HapticFeedback.mediumImpact();
      selectedPackAnimation = 'epic';
      _showSpecialMessage('Epic Find! ⚡');
    } else if (hasRare) {
      _rareConfetti.play();
      HapticFeedback.lightImpact();
      _showSpecialMessage('Nice Pull! 💎');
    } else {
      HapticFeedback.selectionClick();
    }
  }

  void _showSpecialMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.purple.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _playSpecialEffects() async {
    await audioPlayer.play(AssetSource('sounds/booster_open.mp3'));
    
    // Screen flash effect
    if (mounted) {
      showDialog(
        context: context,
        barrierColor: Colors.white.withOpacity(0.8),
        barrierDismissible: false,
        builder: (context) => const SizedBox(),
      );
      
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _showError(String message) {
    setState(() { isOpening = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Color _getRarityColor(String? rarity) {
    switch (rarity?.toLowerCase()) {
      case 'common':
        return Colors.grey.shade300;
      case 'rare':
        return Colors.blue.shade300;
      case 'epic':
        return Colors.purple.shade300;
      case 'legendary':
        return Colors.orange.shade300;
      default:
        return Colors.grey.shade300;
    }
  }

  Color _getRarityGlowColor(String? rarity) {
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

  @override
  void dispose() {
    _confetti.dispose();
    _goldConfetti.dispose();
    _rareConfetti.dispose();
    _packController.dispose();
    _shakeController.dispose();
    _glowController.dispose();
    _cardRevealController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a1a), // Dark mystical background
      appBar: AppBar(
        title: Text(
          widget.boosterItem?['name'] ?? "Mystical Booster Pack",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1a1a2e),
        elevation: 0,
        actions: [
          // Statistics button
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white),
            onPressed: _showPackStatistics,
            tooltip: 'Pack Statistics',
          ),
          // Info button
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () => _showPackInfo(),
            tooltip: 'Pack Information',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF0a0a1a),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background particles
            ...List.generate(20, (index) => 
              AnimatedBuilder(
                animation: _floatController,
                builder: (context, child) => Positioned(
                  left: (index * 50.0) % MediaQuery.of(context).size.width,
                  top: (index * 80.0) % MediaQuery.of(context).size.height + _floatAnimation.value,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Confetti effects
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confetti,
                      blastDirectionality: BlastDirectionality.explosive,
                      shouldLoop: false,
                      colors: const [
                        Colors.pink,
                        Colors.purple,
                        Colors.blue,
                        Colors.orange,
                        Colors.yellow,
                      ],
                    ),
                  ),
                  
                  // Golden confetti for legendary items
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _goldConfetti,
                      blastDirectionality: BlastDirectionality.explosive,
                      shouldLoop: false,
                      colors: const [Colors.amber, Colors.orange, Colors.yellow],
                      emissionFrequency: 0.3,
                      numberOfParticles: 50,
                    ),
                  ),

                  if (!opened && !isOpening) ...[
                    // Pack statistics display
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.purple.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory, color: Colors.white.withOpacity(0.7), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Packs Opened: $totalPacksOpened',
                            style: TextStyle(color: Colors.white.withOpacity(0.7)),
                          ),
                          const SizedBox(width: 20),
                          Icon(Icons.star, color: Colors.orange.withOpacity(0.7), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Rare Found: $rareItemsFound',
                            style: TextStyle(color: Colors.white.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    ),
                    
                    // Enhanced booster pack with multiple animations
                    AnimatedBuilder(
                      animation: Listenable.merge([
                        _glowController, 
                        _shakeController, 
                        _packController,
                        _pulseController,
                      ]),
                      builder: (context, child) => Transform.translate(
                        offset: Offset(_shakeAnimation.value, 0),
                        child: Transform.scale(
                          scale: _packScale.value * _pulseAnimation.value,
                          child: Container(
                            width: 200,
                            height: 280,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _colorAnimation.value?.withOpacity(0.8) ?? Colors.purple.withOpacity(0.8),
                                  Colors.pink.withOpacity(0.8),
                                  Colors.blue.withOpacity(0.8),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_colorAnimation.value ?? Colors.purple).withOpacity(_glowAnimation.value * 0.8),
                                  blurRadius: 30 + (_glowAnimation.value * 20),
                                  spreadRadius: 10 + (_glowAnimation.value * 5),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Sparkle effects
                                ...List.generate(8, (index) => 
                                  AnimatedBuilder(
                                    animation: _sparkleController,
                                    builder: (context, child) => Positioned(
                                      left: 20 + (index * 20.0) + (_sparkleAnimation.value * 10),
                                      top: 30 + (index * 30.0) + (sin(_sparkleAnimation.value * 2 * pi + index) * 20),
                                      child: Opacity(
                                        opacity: _sparkleAnimation.value,
                                        child: const Icon(
                                          Icons.auto_awesome,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // Main content
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      size: 80,
                                      color: Colors.white.withOpacity(0.9 + (_glowAnimation.value * 0.1)),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      widget.boosterItem?['name'] ?? "Mystery Pack",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      "Tap to Open",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8 + (_pulseAnimation.value - 1.0) * 2),
                                        fontSize: 14,
                                      ),
                                    ),
                                    
                                    // Guaranteed rare indicator
                                    if ((totalPacksOpened + 1) % 3 == 0) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          '🌟 GUARANTEED RARE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Open button with glow
                    AnimatedBuilder(
                      animation: _glowController,
                      builder: (context, child) => Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withOpacity(_glowAnimation.value * 0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _openBoosterPack,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink.shade400,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            "🎁 OPEN PACK 🎁",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ] else if (isOpening) ...[
                    // Opening animation
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
                      strokeWidth: 6,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Opening Pack...",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Sparkle animation placeholder
                    Container(
                      height: 150,
                      child: Center(
                        child: Text(
                          "✨ 🎆 ✨",
                          style: TextStyle(
                            fontSize: 60,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ),
                  ] else if (opened && showReveal) ...[
                    // Reveal animation
                    const Text(
                      "✨ YOU GOT ✨",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Items reveal with spectacular effects
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: pulledItems.asMap().entries.map((entry) {
                            int index = entry.key;
                            Map<String, dynamic> item = entry.value;
                            
                            return AnimatedBuilder(
                              animation: _cardRevealController,
                              builder: (context, child) => Transform.scale(
                                scale: _cardRevealController.value,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - _cardRevealController.value) * 50),
                                  child: Container(
                                    margin: EdgeInsets.only(
                                      bottom: 20,
                                      top: index * 100.0 * (1 - _cardRevealController.value),
                                    ),
                                    padding: const EdgeInsets.all(20),
                                    width: MediaQuery.of(context).size.width - 40,
                                    decoration: BoxDecoration(
                                      color: _getRarityColor(item['rarity']),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _getRarityGlowColor(item['rarity']),
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _getRarityGlowColor(item['rarity']).withOpacity(0.6),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(15),
                                          child: Image.network(
                                            item['image_url'],
                                            height: 120,
                                            width: 120,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(height: 15),
                                        Text(
                                          item['name'],
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "✨ ${item['rarity']?.toUpperCase() ?? 'COMMON'} ✨",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: _getRarityGlowColor(item['rarity']),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          item['description'] ?? '',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white.withOpacity(0.8),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Open Another Pack button (if available)
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => BoosterPackScreen(boosterItem: widget.boosterItem),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade400,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text("🎁 Open Another"),
                        ),
                        
                        // Share Epic Pull button (only show for rare+ items)
                        if (pulledItems.any((item) => ['rare', 'epic', 'legendary'].contains(item['rarity']?.toLowerCase())))
                          ElevatedButton(
                            onPressed: () => _shareEpicPull(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade400,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text("📱 Share Pull"),
                          ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // This would navigate to inventory screen
                            // Navigator.pushNamed(context, '/inventory');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade400,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text("📦 Inventory"),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 10),
                    
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text("✅ AWESOME!"),
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