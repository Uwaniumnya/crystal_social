import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'gem_provider.dart';
import 'gemstone_model.dart';

class EnhancedGemCollectionScreen extends StatefulWidget {
  final String userId;
  final String? title;

  const EnhancedGemCollectionScreen({
    super.key,
    required this.userId,
    this.title,
  });

  @override
  State<EnhancedGemCollectionScreen> createState() => _EnhancedGemCollectionScreenState();
}

class _EnhancedGemCollectionScreenState extends State<EnhancedGemCollectionScreen>
    with TickerProviderStateMixin, GemMixin {
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String _viewMode = 'grid'; // grid, list, detailed
  bool _showStats = true;
  bool _showFilters = false;
  Gemstone? _selectedGem;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeGemSystem();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _initializeGemSystem() async {
    await gemProvider.initialize(widget.userId);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f23),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildHeader(),
                  if (_showStats) _buildStatsSection(),
                  if (_showFilters) _buildFiltersSection(),
                  Expanded(child: _buildGemDisplay()),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActions(),
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
              widget.title ?? 'Crystal Gemdex',
              style: GoogleFonts.orbitron(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'stats',
                child: Row(
                  children: [
                    Icon(_showStats ? Icons.visibility_off : Icons.visibility),
                    const SizedBox(width: 8),
                    Text(_showStats ? 'Hide Stats' : 'Show Stats'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'filters',
                child: Row(
                  children: [
                    Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
                    const SizedBox(width: 8),
                    Text(_showFilters ? 'Hide Filters' : 'Show Filters'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'random',
                child: Row(
                  children: [
                    Icon(Icons.casino),
                    SizedBox(width: 8),
                    Text('Random Gem'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GemStatsCard(
        showDetailedStats: true,
        padding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GemSearchBar(
            hintText: 'Search your gem collection...',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          const GemFilterChips(),
          const SizedBox(height: 12),
          _buildViewToggle(),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Row(
      children: [
        Text(
          'View:',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        const SizedBox(width: 12),
        ToggleButtons(
          isSelected: [
            _viewMode == 'grid',
            _viewMode == 'list',
            _viewMode == 'detailed',
          ],
          onPressed: (index) {
            setState(() {
              _viewMode = ['grid', 'list', 'detailed'][index];
            });
          },
          borderRadius: BorderRadius.circular(8),
          selectedColor: Colors.purple,
          fillColor: Colors.purple.withOpacity(0.2),
          children: const [
            Tooltip(
              message: 'Grid View',
              child: Icon(Icons.grid_view, size: 20),
            ),
            Tooltip(
              message: 'List View',
              child: Icon(Icons.view_list, size: 20),
            ),
            Tooltip(
              message: 'Detailed View',
              child: Icon(Icons.view_agenda, size: 20),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGemDisplay() {
    return GemBuilder(
      builder: (context, gems) {
        if (gems.isLoading) {
          return const GemLoadingIndicator(
            message: 'Loading your gem collection...',
          );
        }

        if (gems.error != null) {
          return _buildErrorState(gems.error!);
        }

        final filteredGems = gems.filteredGems;

        if (filteredGems.isEmpty) {
          return _buildEmptyState();
        }

        switch (_viewMode) {
          case 'list':
            return _buildListView(filteredGems);
          case 'detailed':
            return _buildDetailedView(filteredGems);
          default:
            return _buildGridView(filteredGems);
        }
      },
    );
  }

  Widget _buildGridView(List<Gemstone> gems) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: gems.length,
        itemBuilder: (context, index) {
          final gem = gems[index];
          return _buildGemCard(gem, compact: true);
        },
      ),
    );
  }

  Widget _buildListView(List<Gemstone> gems) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: gems.length,
      itemBuilder: (context, index) {
        final gem = gems[index];
        return _buildGemListTile(gem);
      },
    );
  }

  Widget _buildDetailedView(List<Gemstone> gems) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        itemCount: gems.length,
        itemBuilder: (context, index) {
          final gem = gems[index];
          return _buildGemCard(gem, compact: false);
        },
      ),
    );
  }

  Widget _buildGemCard(Gemstone gem, {required bool compact}) {
    final isSelected = _selectedGem?.id == gem.id;
    
    return GestureDetector(
      onTap: () => _selectGem(gem),
      onLongPress: () => _showGemDetails(gem),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(compact ? 8 : 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? gem.rarityColor 
                : gem.rarityColor.withOpacity(0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: gem.rarityColor.withOpacity(0.4),
                blurRadius: 16,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Column(
          children: [
            // Gem Animation
            Expanded(
              flex: compact ? 3 : 2,
              child: Center(
                child: gem.isUnlocked
                    ? gem.createAnimation(
                        size: compact ? 60 : 80,
                        showParticles: gem.isRareUnlock,
                      )
                    : Container(
                        width: compact ? 60 : 80,
                        height: compact ? 60 : 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock,
                          color: Colors.grey,
                          size: compact ? 24 : 32,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Gem Info
            Expanded(
              flex: compact ? 2 : 3,
              child: Column(
                children: [
                  Text(
                    gem.name,
                    style: GoogleFonts.orbitron(
                      fontSize: compact ? 12 : 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: gem.rarityColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      gem.rarity.toUpperCase(),
                      style: TextStyle(
                        fontSize: compact ? 8 : 10,
                        color: gem.rarityColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  if (!compact) ...[
                    const SizedBox(height: 4),
                    Text(
                      gem.element.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          'PWR: ${gem.power}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.orange,
                          ),
                        ),
                        Text(
                          'VAL: ${gem.value}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.yellow,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  if (gem.isFavorite)
                    Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: compact ? 12 : 16,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGemListTile(Gemstone gem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: gem.rarityColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Gem Animation
          SizedBox(
            width: 60,
            height: 60,
            child: gem.isUnlocked
                ? gem.createAnimation(
                    size: 50,
                    showParticles: false,
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Colors.grey,
                      size: 24,
                    ),
                  ),
          ),
          
          const SizedBox(width: 16),
          
          // Gem Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        gem.name,
                        style: GoogleFonts.orbitron(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (gem.isFavorite)
                      const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  gem.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: gem.rarityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        gem.rarity.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: gem.rarityColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      gem.elementIcon,
                      size: 16,
                      color: gem.elementColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      gem.element.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: gem.elementColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'PWR: ${gem.power}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'VAL: ${gem.value}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.yellow,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Actions
          Column(
            children: [
              IconButton(
                icon: Icon(
                  gem.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: gem.isFavorite ? Colors.red : Colors.white.withOpacity(0.6),
                ),
                onPressed: () => _toggleFavorite(gem),
              ),
              IconButton(
                icon: Icon(
                  Icons.info_outline,
                  color: Colors.white.withOpacity(0.6),
                ),
                onPressed: () => _showGemDetails(gem),
              ),
            ],
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
            Icons.diamond_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No gems found',
            style: GoogleFonts.orbitron(
              fontSize: 24,
              color: Colors.white.withOpacity(0.6),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your gem collection awaits discovery',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _generateRandomGem,
            icon: const Icon(Icons.casino),
            label: const Text('Discover Random Gem'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Gems',
            style: GoogleFonts.orbitron(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => gemProvider.refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'search',
          onPressed: () {
            setState(() {
              _showFilters = !_showFilters;
            });
          },
          backgroundColor: Colors.purple,
          child: Icon(_showFilters ? Icons.search_off : Icons.search),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'random',
          onPressed: _generateRandomGem,
          backgroundColor: Colors.orange,
          child: const Icon(Icons.casino),
        ),
      ],
    );
  }

  void _selectGem(Gemstone gem) {
    setState(() {
      _selectedGem = _selectedGem?.id == gem.id ? null : gem;
    });
  }

  void _showGemDetails(Gemstone gem) {
    if (gem.isUnlocked) {
      showDialog(
        context: context,
        builder: (context) => gem.createUnlockPopup(
          onClose: () {
            // Update gem as viewed
            setState(() {
              // Increment view count logic could go here
            });
          },
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This gem hasn\'t been unlocked yet!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _toggleFavorite(Gemstone gem) async {
    final success = await gemProvider.toggleFavorite(gem.id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            gem.isFavorite 
                ? 'Removed from favorites' 
                : 'Added to favorites',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _generateRandomGem() {
    final randomGem = gemProvider.generateRandomReward();
    if (randomGem != null) {
      _unlockRandomGem(randomGem);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No new gems available for discovery!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _unlockRandomGem(Gemstone gem) async {
    final success = await gemProvider.unlockGem(
      gem.id,
      context: {
        'trigger_type': 'random_discovery',
        'source': 'collection_screen',
      },
    );

    if (success) {
      // Show unlock animation
      showDialog(
        context: context,
        builder: (context) => gem.createUnlockPopup(),
      );
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'stats':
        setState(() {
          _showStats = !_showStats;
        });
        break;
      case 'filters':
        setState(() {
          _showFilters = !_showFilters;
        });
        break;
      case 'refresh':
        gemProvider.refresh();
        break;
      case 'random':
        _generateRandomGem();
        break;
    }
  }
}
