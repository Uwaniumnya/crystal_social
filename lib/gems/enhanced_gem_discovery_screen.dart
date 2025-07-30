import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'dart:async';
import 'gem_provider.dart';
import 'gemstone_model.dart';

class EnhancedGemDiscoveryScreen extends StatefulWidget {
  final String userId;
  final String? title;

  const EnhancedGemDiscoveryScreen({
    super.key,
    required this.userId,
    this.title,
  });

  @override
  State<EnhancedGemDiscoveryScreen> createState() => _EnhancedGemDiscoveryScreenState();
}

class _EnhancedGemDiscoveryScreenState extends State<EnhancedGemDiscoveryScreen>
    with TickerProviderStateMixin, GemMixin {
  
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _sparkleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _sparkleAnimation;
  
  bool _isSearching = false;
  bool _canDiscover = true;
  int _discoveryEnergy = 100;
  Timer? _energyTimer;
  List<Gemstone> _availableGems = [];
  Gemstone? _discoveredGem;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeDiscovery();
    _startEnergyRegeneration();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.linear,
    ));

    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
    _rotateController.repeat();
  }

  Future<void> _initializeDiscovery() async {
    await gemProvider.initialize(widget.userId);
    _loadAvailableGems();
  }

  void _loadAvailableGems() {
    setState(() {
      _availableGems = gemProvider.filteredGems
          .where((gem) => !gemProvider.hasGem(gem.id))
          .toList();
    });
  }

  void _startEnergyRegeneration() {
    _energyTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_discoveryEnergy < 100) {
        setState(() {
          _discoveryEnergy = min(100, _discoveryEnergy + 5);
          _canDiscover = _discoveryEnergy >= 20;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _sparkleController.dispose();
    _energyTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f23),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
              Color(0xFF0f0f23),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildEnergyBar(),
              Expanded(child: _buildDiscoveryArea()),
              _buildStats(),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              widget.title ?? 'Gem Discovery',
              style: GoogleFonts.orbitron(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: _showHelp,
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Discovery Energy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$_discoveryEnergy/100',
                style: TextStyle(
                  color: _canDiscover ? Colors.green : Colors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _discoveryEnergy / 100,
            backgroundColor: Colors.grey.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              _canDiscover ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _canDiscover 
                ? 'Ready to discover gems!' 
                : 'Energy regenerating... (20 energy needed)',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryArea() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_discoveredGem != null) ...[
            _buildDiscoveredGemDisplay(),
          ] else ...[
            _buildDiscoveryOrb(),
            const SizedBox(height: 32),
            _buildDiscoveryInstructions(),
          ],
        ],
      ),
    );
  }

  Widget _buildDiscoveryOrb() {
    return GestureDetector(
      onTap: _canDiscover && !_isSearching ? _startDiscovery : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _rotateController, _sparkleController]),
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Transform.rotate(
              angle: _rotateAnimation.value,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.purple.withOpacity(0.8),
                      Colors.blue.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _canDiscover && !_isSearching 
                          ? Colors.purple.withOpacity(0.6)
                          : Colors.grey.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Inner orb
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _canDiscover && !_isSearching 
                            ? Colors.purple.withOpacity(0.4)
                            : Colors.grey.withOpacity(0.2),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: _isSearching
                            ? SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 3,
                                ),
                              )
                            : Icon(
                                Icons.diamond,
                                size: 60,
                                color: _canDiscover 
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                      ),
                    ),
                    
                    // Sparkle effects
                    if (_canDiscover && !_isSearching)
                      ...List.generate(8, (index) => _buildSparkle(index)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSparkle(int index) {
    final angle = (index * 2 * pi / 8) + (_sparkleAnimation.value * 2 * pi);
    final radius = 80 + (sin(_sparkleAnimation.value * 2 * pi) * 20);
    final x = cos(angle) * radius;
    final y = sin(angle) * radius;
    
    return Transform.translate(
      offset: Offset(x, y),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.6),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveryInstructions() {
    return Column(
      children: [
        Text(
          _canDiscover 
              ? 'Tap the Discovery Orb' 
              : 'Not enough energy',
          style: GoogleFonts.orbitron(
            fontSize: 20,
            color: _canDiscover ? Colors.white : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _canDiscover 
              ? 'Channel your energy to discover magical gemstones hidden in the mystical realm'
              : 'Wait for your discovery energy to regenerate, or complete activities to gain more energy',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        if (_canDiscover) ...[
          const SizedBox(height: 16),
          Text(
            'Cost: 20 Energy',
            style: TextStyle(
              fontSize: 12,
              color: Colors.yellow.withOpacity(0.8),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDiscoveredGemDisplay() {
    if (_discoveredGem == null) return const SizedBox.shrink();
    
    return Column(
      children: [
        Text(
          'GEM DISCOVERED!',
          style: GoogleFonts.orbitron(
            fontSize: 24,
            color: Colors.yellow,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 24),
        _discoveredGem!.createAnimation(
          size: 120,
          animationType: _discoveredGem!.preferredAnimation,
          showParticles: true,
        ),
        const SizedBox(height: 24),
        Text(
          _discoveredGem!.name,
          style: GoogleFonts.orbitron(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _discoveredGem!.rarityColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _discoveredGem!.rarityColor.withOpacity(0.4),
            ),
          ),
          child: Text(
            _discoveredGem!.rarity.toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              color: _discoveredGem!.rarityColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _discoveredGem!.description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _addToCollection,
              icon: const Icon(Icons.add_circle),
              label: const Text('Add to Collection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _viewDetails,
              icon: const Icon(Icons.info),
              label: const Text('View Details'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _discardGem,
          child: Text(
            'Discard',
            style: TextStyle(color: Colors.red.withOpacity(0.8)),
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return GemBuilder(
      builder: (context, gems) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                'Available',
                '${_availableGems.length}',
                Colors.blue,
              ),
              _buildStatItem(
                'Collected',
                '${gems.totalGems}',
                Colors.green,
              ),
              _buildStatItem(
                'Completion',
                '${gems.completionPercentage.toStringAsFixed(1)}%',
                Colors.purple,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _canDiscover && !_isSearching ? _startDiscovery : null,
              icon: Icon(_isSearching ? Icons.hourglass_empty : Icons.search),
              label: Text(_isSearching ? 'Searching...' : 'Discover Gem'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _canDiscover && !_isSearching 
                    ? Colors.purple 
                    : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _buyEnergy,
            icon: const Icon(Icons.battery_charging_full),
            label: const Text('Buy Energy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startDiscovery() async {
    if (!_canDiscover || _isSearching) return;

    setState(() {
      _isSearching = true;
      _discoveryEnergy -= 20;
      _canDiscover = _discoveryEnergy >= 20;
    });

    _sparkleController.repeat(reverse: true);

    // Simulate discovery time
    await Future.delayed(const Duration(seconds: 3));

    final discoveredGem = gemProvider.generateRandomReward();
    
    setState(() {
      _isSearching = false;
      _discoveredGem = discoveredGem;
    });

    _sparkleController.stop();
    _sparkleController.reset();

    if (discoveredGem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No new gems found this time. Try again!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _addToCollection() async {
    if (_discoveredGem == null) return;

    final success = await gemProvider.unlockGem(
      _discoveredGem!.id,
      context: {
        'trigger_type': 'discovery',
        'source': 'discovery_screen',
      },
    );

    if (success) {
      // Show unlock popup
      showDialog(
        context: context,
        builder: (context) => _discoveredGem!.createUnlockPopup(),
      );
      
      setState(() {
        _discoveredGem = null;
      });
      
      _loadAvailableGems();
    }
  }

  void _viewDetails() {
    if (_discoveredGem == null) return;
    
    showDialog(
      context: context,
      builder: (context) => _discoveredGem!.createUnlockPopup(
        showStats: true,
        playSound: false,
      ),
    );
  }

  void _discardGem() {
    setState(() {
      _discoveredGem = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gem discarded. You can discover it again later.'),
      ),
    );
  }

  void _buyEnergy() {
    // TODO: Implement energy purchase system
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Energy shop coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text(
          'Gem Discovery Help',
          style: GoogleFonts.orbitron(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔮 How to Discover Gems:',
              style: TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• Tap the Discovery Orb when you have enough energy\n'
              '• Each discovery costs 20 energy\n'
              '• Energy regenerates over time\n'
              '• Rarer gems are harder to find\n'
              '• Complete activities to gain bonus energy',
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
            const SizedBox(height: 16),
            Text(
              '💎 Discovery Tips:',
              style: TextStyle(
                color: Colors.yellow,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• Try discovering at different times\n'
              '• Some gems are only found under specific conditions\n'
              '• Share discoveries with friends for bonuses',
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}
