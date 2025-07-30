// File: pet_care_screen.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import 'updated_pet_list.dart';
import 'pet_state_provider.dart';
import 'pet_mini_games.dart';
import 'pets_integration.dart';
import 'pets_production_config.dart';

class PetCareScreen extends StatefulWidget {
  final String? userId;

  const PetCareScreen({
    super.key,
    this.userId,
  });

  @override
  State<PetCareScreen> createState() => _PetCareScreenState();
}

class _PetCareScreenState extends State<PetCareScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _petAnimationController;
  late AnimationController _feedingAnimationController;
  late AnimationController _playAnimationController;
  late AnimationController _statsAnimationController;
  late AnimationController _heartAnimationController;
  
  // Animations
  late Animation<double> _petBounceAnimation;
  late Animation<double> _feedingScaleAnimation;
  late Animation<double> _playRotationAnimation;
  late Animation<double> _statsOpacityAnimation;
  late Animation<double> _heartScaleAnimation;
  
  // Confetti controller for celebrations
  late ConfettiController _confettiController;
  
  // Audio player
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // UI state
  bool _isFeeding = false;
  bool _isPlaying = false;
  bool _showFoodSelection = false;
  bool _showPlaySelection = false;
  Timer? _animationTimer;
  String? _currentMessage;
  
  // Get available food items from the comprehensive pet food list
  List<PetFood> get _availableFoodItems {
    // Filter foods by category for easier selection or return a curated list
    return [
      // Quick Access Drinks
      ...availableFoods.where((food) => 
        food.category == FoodCategory.drinks && 
        [
          'Fresh Water',
          'Milk', 
          'Chocolate Milk',
          'Orange Juice',
          'Tea',
          'Energy Drink'
        ].contains(food.name)
      ),
      
      // Popular Meals
      ...availableFoods.where((food) => 
        food.category == FoodCategory.meals && 
        food.rarity != PetRarity.legendary // Exclude super rare foods
      ),
      
      // Fruits & Vegetables
      ...availableFoods.where((food) => 
        food.category == FoodCategory.fruits_and_vegetables &&
        food.rarity != PetRarity.mythical
      ),
      
      // Meat options
      ...availableFoods.where((food) => 
        food.category == FoodCategory.meat &&
        food.rarity == PetRarity.common || food.rarity == PetRarity.uncommon
      ),
      
      // Sweet treats
      ...availableFoods.where((food) => 
        food.category == FoodCategory.sweets &&
        food.price <= 25.0 // Affordable treats
      ),
    ].take(20).toList(); // Limit to 20 items for UI performance
  }
  
  // Play activities - now interactive mini-games
  final List<PlayActivity> _playActivities = [
    PlayActivity(
      id: 'ball_catch',
      name: 'Ball Catch Game',
      icon: Icons.sports_baseball,
      color: Colors.red,
      happinessBoost: 0.25,
      energyCost: 0.1,
      healthBoost: 0.08,
      description: 'Interactive ball catching game!',
    ),
    PlayActivity(
      id: 'puzzle_slider',
      name: 'Puzzle Game',
      icon: Icons.extension,
      color: Colors.blue,
      happinessBoost: 0.18,
      energyCost: 0.03,
      healthBoost: 0.05,
      description: 'Solve the sliding puzzle!',
    ),
    PlayActivity(
      id: 'memory_match',
      name: 'Memory Match',
      icon: Icons.psychology,
      color: Colors.purple,
      happinessBoost: 0.20,
      energyCost: 0.02,
      healthBoost: 0.04,
      description: 'Match the card pairs!',
    ),
    PlayActivity(
      id: 'fetch_game',
      name: 'Fetch Game',
      icon: Icons.launch,
      color: Colors.green,
      happinessBoost: 0.35,
      energyCost: 0.15,
      healthBoost: 0.1,
      description: 'Interactive fetch with your pet!',
    ),
    PlayActivity(
      id: 'cuddle',
      name: 'Cuddle Time',
      icon: Icons.favorite,
      color: Colors.pink,
      happinessBoost: 0.2,
      energyCost: -0.05, // Actually restores energy
      healthBoost: 0.03,
      description: 'Relaxing cuddle session!',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startIdleAnimations();
  }

  void _initializeAnimations() {
    // Pet animation (idle bouncing)
    _petAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _petBounceAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _petAnimationController, curve: Curves.easeInOut),
    );

    // Feeding animation
    _feedingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _feedingScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _feedingAnimationController, curve: Curves.elasticOut),
    );

    // Play animation
    _playAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _playRotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _playAnimationController, curve: Curves.easeInOut),
    );

    // Stats animation
    _statsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _statsOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _statsAnimationController, curve: Curves.easeInOut),
    );

    // Heart animation
    _heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _heartScaleAnimation = Tween<double>(begin: 0.0, end: 1.5).animate(
      CurvedAnimation(parent: _heartAnimationController, curve: Curves.elasticOut),
    );

    // Confetti controller
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));

    // Start stats animation
    _statsAnimationController.forward();
  }

  void _startIdleAnimations() {
    _petAnimationController.repeat(reverse: true);
  }

  void _feedPet(PetFood food) async {
    final petState = Provider.of<PetState>(context, listen: false);
    
    setState(() {
      _isFeeding = true;
      _showFoodSelection = false;
      _currentMessage = food.description;
    });

    // Trigger feeding animation
    _feedingAnimationController.forward(from: 0.0);
    
    // Play feeding sound
    _playSound('feed.mp3');
    
    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Use the PetFood directly with the enhanced feeding system
    petState.feedPetWithFood(food);
    petState.increaseBondXP(15);
    
    // Show heart animation
    _heartAnimationController.forward(from: 0.0);

    // Auto-save
    if (widget.userId != null) {
      await petState.saveToSupabase(widget.userId!);
    }

    // Reset feeding state after animation
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isFeeding = false;
          _currentMessage = null;
        });
        _feedingAnimationController.reverse();
        _heartAnimationController.reverse();
      }
    });
  }

  // Helper methods for food categories and rarity
  Color _getCategoryColor(FoodCategory category) {
    switch (category) {
      case FoodCategory.drinks:
        return Colors.blue;
      case FoodCategory.fruits_and_vegetables:
        return Colors.green;
      case FoodCategory.meals:
        return Colors.orange;
      case FoodCategory.meat:
        return Colors.red;
      case FoodCategory.sweets:
        return Colors.pink;
    }
  }

  IconData _getCategoryIcon(FoodCategory category) {
    switch (category) {
      case FoodCategory.drinks:
        return Icons.local_drink;
      case FoodCategory.fruits_and_vegetables:
        return Icons.eco;
      case FoodCategory.meals:
        return Icons.restaurant;
      case FoodCategory.meat:
        return Icons.fastfood;
      case FoodCategory.sweets:
        return Icons.cake;
    }
  }

  Color _getRarityColor(PetRarity rarity) {
    switch (rarity) {
      case PetRarity.common:
        return Colors.grey;
      case PetRarity.uncommon:
        return Colors.green;
      case PetRarity.rare:
        return Colors.blue;
      case PetRarity.epic:
        return Colors.purple;
      case PetRarity.legendary:
        return Colors.orange;
      case PetRarity.mythical:
        return Colors.red;
    }
  }

  void _playWithPet(PlayActivity activity) async {
    setState(() {
      _isPlaying = true;
      _showPlaySelection = false;
      _currentMessage = activity.description;
    });

    // Check if this is an interactive mini-game
    if (activity.id == 'ball_catch' || 
        activity.id == 'puzzle_slider' || 
        activity.id == 'memory_match' || 
        activity.id == 'fetch_game') {
      _startMiniGame(activity);
      return;
    }

    // Handle simple activities (like cuddle)
    _playSimpleActivity(activity);
  }

  void _startMiniGame(PlayActivity activity) {
    Widget gameWidget;
    
    switch (activity.id) {
      case 'ball_catch':
        gameWidget = BallCatchGame(
          onGameComplete: (result) => _onGameComplete(result, activity),
          audioPlayer: _audioPlayer,
        );
        break;
      case 'puzzle_slider':
        gameWidget = PuzzleSliderGame(
          onGameComplete: (result) => _onGameComplete(result, activity),
          audioPlayer: _audioPlayer,
        );
        break;
      case 'memory_match':
        gameWidget = MemoryMatchGame(
          onGameComplete: (result) => _onGameComplete(result, activity),
          audioPlayer: _audioPlayer,
        );
        break;
      case 'fetch_game':
        gameWidget = FetchGame(
          onGameComplete: (result) => _onGameComplete(result, activity),
          audioPlayer: _audioPlayer,
        );
        break;
      default:
        _playSimpleActivity(activity);
        return;
    }

    // Navigate to mini-game
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(activity.name),
            backgroundColor: activity.color,
            foregroundColor: Colors.white,
          ),
          body: gameWidget,
        ),
      ),
    );
  }

  void _onGameComplete(GameResult result, PlayActivity activity) {
    Navigator.pop(context); // Close game screen

    // Update pet stats based on game result
    final petState = Provider.of<PetState>(context, listen: false);
    petState.updateStats(
      happinessChange: result.happinessBoost,
      energyChange: -result.energyCost,
      healthChange: result.healthBoost,
    );
    
    // Bonus XP for successful games
    if (result.isSuccess) {
      petState.increaseBondXP(30);
    } else {
      petState.increaseBondXP(15);
    }
    
    petState.lastPlayed = DateTime.now();

    // Show game result
    _showGameResult(result);

    // Auto-save
    if (widget.userId != null) {
      petState.saveToSupabase(widget.userId!);
    }

    // Reset play state
    setState(() {
      _isPlaying = false;
      _currentMessage = null;
    });
  }

  void _playSimpleActivity(PlayActivity activity) async {
    // Trigger play animation
    _playAnimationController.forward(from: 0.0);
    
    // Play activity sound
    _playSound('play.mp3');
    
    // Haptic feedback
    HapticFeedback.heavyImpact();

    // Update pet stats
    final petState = Provider.of<PetState>(context, listen: false);
    petState.updateStats(
      happinessChange: activity.happinessBoost,
      energyChange: -activity.energyCost,
      healthChange: activity.healthBoost,
    );
    petState.increaseBondXP(20);
    
    // Custom play method with activity type
    petState.lastPlayed = DateTime.now();
    
    // Show confetti for high-energy activities
    if (activity.energyCost > 0.1) {
      _confettiController.play();
    }

    // Auto-save
    if (widget.userId != null) {
      await petState.saveToSupabase(widget.userId!);
    }

    // Reset play state after animation
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentMessage = null;
        });
        _playAnimationController.reverse();
      }
    });
  }

  void _showGameResult(GameResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              result.isSuccess ? Icons.star : Icons.thumb_up,
              color: result.isSuccess ? Colors.amber : Colors.blue,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              result.isSuccess ? 'Great Job!' : 'Well Played!',
              style: TextStyle(
                color: result.isSuccess ? Colors.amber.shade700 : Colors.blue.shade700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.message,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Text('Game: ${result.gameType}'),
            Text('Score: ${result.score.round()}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('❤️ +${(result.happinessBoost * 100).round()}%'),
                const SizedBox(width: 12),
                Text('⚡ -${(result.energyCost * 100).round()}%'),
                const SizedBox(width: 12),
                Text('💚 +${(result.healthBoost * 100).round()}%'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _playSound(String fileName) async {
    try {
      await _audioPlayer.play(AssetSource('pets/sounds/$fileName'));
    } catch (e) {
      // Ignore audio errors
      PetsDebugUtils.logError('playSound', 'Could not play sound: $fileName');
    }
  }

  void _onPetTapped(PetState petState) {
    // Use integrated sound system
    PetsIntegration.playPetSound(petState.selectedPetId);
    
    // Add small happiness boost for interaction
    petState.updateStats(happinessChange: 0.02);
    
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    // Trigger a small bounce animation
    _heartAnimationController.forward(from: 0.0).then((_) {
      _heartAnimationController.reverse();
    });
    
    // Show interaction message
    setState(() {
      _currentMessage = _getRandomPetResponse(petState.currentMood);
    });
    
    // Clear message after a short time
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _currentMessage = null;
        });
      }
    });
  }

  String _getRandomPetResponse(String mood) {
    final responses = {
      'happy': ['😊 *purrs*', '😊 *happy chirp*', '😊 *contented sigh*', '😊 *tail wag*'],
      'excited': ['🤩 *excited bark*', '🤩 *playful chirp*', '🤩 *bouncy purr*', '🤩 *happy squeak*'],
      'love': ['🥰 *loving purr*', '🥰 *gentle coo*', '🥰 *affectionate mew*', '🥰 *content rumble*'],
      'sad': ['😢 *sad whimper*', '😢 *quiet mew*', '😢 *soft sigh*', '😢 *gentle whine*'],
      'sleepy': ['😴 *sleepy yawn*', '😴 *drowsy purr*', '😴 *tired chirp*', '😴 *lazy stretch*'],
      'playful': ['😄 *playful bark*', '😄 *excited chirp*', '😄 *bouncy mew*', '😄 *energetic squeak*'],
    };
    
    final moodResponses = responses[mood] ?? responses['happy']!;
    return moodResponses[math.Random().nextInt(moodResponses.length)];
  }

  void _showRecommendation(PetState petState) {
    String recommendation = '';
    IconData icon = Icons.info;
    Color color = Colors.blue;

    if (petState.needsAttention) {
      if (petState.happiness < 0.3) {
        recommendation = "Your ${petState.petName} is sad! Try playing together or giving treats.";
        icon = Icons.sentiment_dissatisfied;
        color = Colors.orange;
      } else if (petState.energy < 0.3) {
        recommendation = "Your ${petState.petName} is tired. Feed them something nutritious!";
        icon = Icons.battery_0_bar;
        color = Colors.red;
      } else if (petState.health < 0.3) {
        recommendation = "Your ${petState.petName} needs health care. Try fresh vegetables!";
        icon = Icons.health_and_safety;
        color = Colors.green;
      }
    } else if (petState.energy > 0.7 && petState.happiness < 0.8) {
      recommendation = "Your ${petState.petName} has energy to play! Try fetch or ball games.";
      icon = Icons.sports_esports;
      color = Colors.purple;
    } else if (petState.overallWellbeing > 0.9) {
      recommendation = "Your ${petState.petName} is perfectly cared for! Great job! 🌟";
      icon = Icons.star;
      color = Colors.amber;
    }

    if (recommendation.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(recommendation)),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void dispose() {
    _petAnimationController.dispose();
    _feedingAnimationController.dispose();
    _playAnimationController.dispose();
    _statsAnimationController.dispose();
    _heartAnimationController.dispose();
    _confettiController.dispose();
    _animationTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade300,
              Colors.pink.shade300,
              Colors.blue.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<PetState>(
            builder: (context, petState, child) {
              return Stack(
                children: [
                  // Confetti effect
                  Positioned.fill(
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      shouldLoop: false,
                      numberOfParticles: 30,
                      emissionFrequency: 0.1,
                      colors: const [Colors.pink, Colors.purple, Colors.yellow, Colors.blue],
                    ),
                  ),
                  
                  // Main content
                  Column(
                    children: [
                      _buildAppBar(petState),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildPetDisplay(petState),
                              const SizedBox(height: 24),
                              _buildStatsSection(petState),
                              const SizedBox(height: 24),
                              _buildActionButtons(petState),
                              const SizedBox(height: 24),
                              _buildCareHistory(petState),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Food selection overlay
                  if (_showFoodSelection) _buildFoodSelection(),
                  
                  // Play selection overlay
                  if (_showPlaySelection) _buildPlaySelection(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(PetState petState) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${petState.petName} Care',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Level ${petState.bondLevel} • ${petState.petAge}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () => _showRecommendation(petState),
          ),
        ],
      ),
    );
  }

  Widget _buildPetDisplay(PetState petState) {
    final pet = availablePets.firstWhere((p) => p.id == petState.selectedPetId);
    final renderedPath = petState.selectedAccessory == 'None'
        ? pet.assetPath
        : pet.assetPath.replaceFirst('.png', '_${petState.selectedAccessory.toLowerCase()}.png');

    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pet image with animations
          GestureDetector(
            onTap: () => _onPetTapped(petState),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _petBounceAnimation,
                  _feedingScaleAnimation,
                  _playRotationAnimation,
                ]),
                builder: (context, child) {
                  double scale = _petBounceAnimation.value;
                  if (_isFeeding) scale *= _feedingScaleAnimation.value;
                  
                  double rotation = 0.0;
                  if (_isPlaying) rotation = _playRotationAnimation.value * 0.1;

                  return Transform.scale(
                    scale: scale,
                    child: Transform.rotate(
                      angle: rotation,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(60),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          renderedPath,
                          width: 120,
                          height: 120,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.purple.shade100,
                                borderRadius: BorderRadius.circular(60),
                              ),
                              child: const Icon(Icons.pets, size: 60, color: Colors.purple),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Heart animation overlay
          AnimatedBuilder(
            animation: _heartScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _heartScaleAnimation.value,
                child: Opacity(
                  opacity: 1.0 - _heartScaleAnimation.value,
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 50,
                  ),
                ),
              );
            },
          ),
          
          // Current message bubble
          if (_currentMessage != null)
            Positioned(
              top: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Text(
                  _currentMessage!,
                  style: TextStyle(
                    color: Colors.purple.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          
          // Mood indicator
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getMoodColor(petState.currentMood),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getMoodEmoji(petState.currentMood),
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(PetState petState) {
    return AnimatedBuilder(
      animation: _statsOpacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _statsOpacityAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildStatBar('Happiness', petState.happiness, Colors.yellow),
                const SizedBox(height: 12),
                _buildStatBar('Energy', petState.energy, Colors.green),
                const SizedBox(height: 12),
                _buildStatBar('Health', petState.health, Colors.red),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatChip('Overall', '${(petState.overallWellbeing * 100).round()}%', Colors.purple),
                    _buildStatChip('Streak', '${petState.currentStreak} days', Colors.orange),
                    _buildStatChip('XP', '${petState.bondXP}', Colors.blue),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(PetState petState) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Feed Pet',
            Icons.restaurant,
            Colors.orange,
            () => setState(() => _showFoodSelection = true),
            isEnabled: !_isFeeding && !_isPlaying,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            'Play',
            Icons.sports_esports,
            Colors.green,
            () => setState(() => _showPlaySelection = true),
            isEnabled: !_isFeeding && !_isPlaying && petState.energy > 0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
    {bool isEnabled = true}
  ) {
    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
      child: Column(
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildCareHistory(PetState petState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Care History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          _buildHistoryItem(
            'Last Fed',
            petState.lastFed != null
                ? _formatTimeAgo(petState.lastFed!)
                : 'Never',
            Icons.restaurant,
            Colors.orange,
          ),
          _buildHistoryItem(
            'Last Played',
            petState.lastPlayed != null
                ? _formatTimeAgo(petState.lastPlayed!)
                : 'Never',
            Icons.sports_esports,
            Colors.green,
          ),
          _buildHistoryItem(
            'Total Interactions',
            '${petState.totalInteractions}',
            Icons.touch_app,
            Colors.blue,
          ),
          _buildHistoryItem(
            'Achievements',
            '${petState.achievements.length}',
            Icons.star,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.grey[600])),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodSelection() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Choose Food',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _showFoodSelection = false),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...(_availableFoodItems.map((food) => _buildFoodItem(food)).toList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodItem(PetFood food) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: () => _feedPet(food),
        style: ElevatedButton.styleFrom(
          backgroundColor: _getCategoryColor(food.category).withValues(alpha: 0.1),
          foregroundColor: _getCategoryColor(food.category),
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: _getCategoryColor(food.category).withValues(alpha: 0.3)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getCategoryColor(food.category).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  food.assetPath,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      _getCategoryIcon(food.category),
                      size: 20,
                      color: _getCategoryColor(food.category),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          food.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getRarityColor(food.rarity),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          food.rarity.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    food.description,
                    style: const TextStyle(fontSize: 12),
                  ),
                  Row(
                    children: [
                      Text('❤️ +${food.happinessBoost}'),
                      const SizedBox(width: 8),
                      Text('⚡ +${food.energyBoost}'),
                      const SizedBox(width: 8),
                      Text('💚 +${food.healthBoost}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaySelection() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Choose Activity',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _showPlaySelection = false),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...(_playActivities.map((activity) => _buildPlayItem(activity)).toList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayItem(PlayActivity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: () => _playWithPet(activity),
        style: ElevatedButton.styleFrom(
          backgroundColor: activity.color.withValues(alpha: 0.1),
          foregroundColor: activity.color,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: activity.color.withValues(alpha: 0.3)),
          ),
        ),
        child: Row(
          children: [
            Icon(activity.icon, size: 32, color: activity.color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    activity.description,
                    style: const TextStyle(fontSize: 12),
                  ),
                  Row(
                    children: [
                      Text('❤️ +${(activity.happinessBoost * 100).round()}%'),
                      const SizedBox(width: 8),
                      Text(activity.energyCost > 0 
                          ? '⚡ -${(activity.energyCost * 100).round()}%'
                          : '⚡ +${(-activity.energyCost * 100).round()}%'),
                      const SizedBox(width: 8),
                      Text('💚 +${(activity.healthBoost * 100).round()}%'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'happy': return Colors.yellow;
      case 'excited': return Colors.orange;
      case 'love': return Colors.pink;
      case 'sad': return Colors.blue;
      case 'angry': return Colors.red;
      case 'sleepy': return Colors.purple;
      case 'playful': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getMoodEmoji(String mood) {
    switch (mood) {
      case 'happy': return '😊';
      case 'excited': return '🤩';
      case 'love': return '🥰';
      case 'sad': return '😢';
      case 'angry': return '😠';
      case 'sleepy': return '😴';
      case 'playful': return '😄';
      default: return '😐';
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

// Data models for food and play activities
class PlayActivity {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final double happinessBoost;
  final double energyCost;
  final double healthBoost;
  final String description;

  PlayActivity({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.happinessBoost,
    required this.energyCost,
    required this.healthBoost,
    required this.description,
  });
}
