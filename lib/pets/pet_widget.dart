// File: pet_widget.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import 'updated_pet_list.dart';
import 'pet_state_provider.dart';
import 'pet_details_screen.dart';

class PetWidget extends StatefulWidget {
  final Stream<String> incomingMessages;
  final VoidCallback? onPetTapped;
  final String? userId;
  final VoidCallback? onLevelUp;
  final Function(String)? onPetSpeech;
  final bool enableEmotions;
  final bool enableRandomMovement;

  const PetWidget({
    super.key,
    required this.incomingMessages,
    this.onPetTapped,
    this.userId,
    this.onLevelUp,
    this.onPetSpeech,
    this.enableEmotions = true,
    this.enableRandomMovement = true,
  });

  @override
  State<PetWidget> createState() => _PetWidgetState();
}

class _PetWidgetState extends State<PetWidget> with TickerProviderStateMixin {
  // Animation controllers
  late final AnimationController _wagController;
  late final AnimationController _angryController;
  late final AnimationController _squishController;
  late final AnimationController _breathingController;
  late final AnimationController _floatController;
  late final AnimationController _glowController;
  late final AnimationController _emotionController;
  late final AnimationController _walkController;
  
  // Confetti controller
  late final ConfettiController _confettiController;
  
  // Animations
  late final Animation<double> _wagAnimation;
  late final Animation<double> _angryAnimation;
  late final Animation<double> _squishAnimation;
  late final Animation<double> _breathingAnimation;
  late final Animation<double> _floatAnimation;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _emotionAnimation;
  late final Animation<Offset> _walkAnimation;
  
  // State variables
  bool _showLevelUp = false;
  int _lastLevel = 0;
  String _currentEmotion = 'happy';
  bool _isWalking = false;
  double _horizontalPosition = 8.0;
  
  // Timers
  Timer? _idleTimer;
  Timer? _speechBubbleTimer;
  Timer? _tapTimer;
  Timer? _emotionTimer;
  Timer? _walkTimer;
  Timer? _randomActionTimer;
  
  // Interaction state
  int _tapCount = 0;
  bool _isInactive = false;
  String? _speechText;
  bool _showHeartEffect = false;
  
  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Pet emotions and their effects
  final Map<String, Color> _emotionColors = {
    'happy': Colors.yellow,
    'excited': Colors.orange,
    'love': Colors.pink,
    'angry': Colors.red,
    'sad': Colors.blue,
    'sleepy': Colors.purple,
    'playful': Colors.green,
  };
  
  final Map<String, IconData> _emotionIcons = {
    'happy': Icons.sentiment_very_satisfied,
    'excited': Icons.star,
    'love': Icons.favorite,
    'angry': Icons.sentiment_very_dissatisfied,
    'sad': Icons.sentiment_dissatisfied,
    'sleepy': Icons.bedtime,
    'playful': Icons.sports_esports,
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupMessageListener();
    _startTimers();
  }

  void _initializeAnimations() {
    // Basic animations
    _wagController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _wagAnimation = Tween<double>(begin: -0.1, end: 0.1)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_wagController);

    _angryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _angryAnimation = Tween<double>(begin: -4.0, end: 4.0)
        .chain(CurveTween(curve: Curves.linear))
        .animate(_angryController);

    _squishController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _squishAnimation = Tween<double>(begin: 1.0, end: 0.85)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_squishController);

    _breathingController = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.05)
        .animate(CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut));

    // Enhanced animations
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -2.0, end: 2.0)
        .animate(CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));

    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

    _emotionController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _emotionAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _emotionController, curve: Curves.elasticOut));

    _walkController = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _walkAnimation = Tween<Offset>(begin: Offset.zero, end: const Offset(100, 0))
        .animate(CurvedAnimation(parent: _walkController, curve: Curves.easeInOut));

    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  void _setupMessageListener() {
    widget.incomingMessages.listen((msg) {
      _handleMessage(msg);
    });
  }

  void _startTimers() {
    _startInactivityTimer();
    _startSpeechBubbleTimer();
    _startRandomActionTimer();
  }

  void _handleMessage(String msg) {
    msg = msg.toLowerCase();
    setState(() => _isInactive = false);
    _startInactivityTimer();

    final petState = Provider.of<PetState>(context, listen: false);
    int oldLevel = petState.bondLevel;
    petState.increaseBondXP(5);
    int newLevel = petState.bondLevel;

    if (newLevel > oldLevel) _triggerLevelUp(newLevel);

    // Enhanced message handling with emotions
    if (msg.contains("love") || msg.contains("❤️") || msg.contains("💕")) {
      _triggerEmotion('love');
      _wagController.repeat(reverse: true);
      _playSound('wag.mp3');
      _showHeartEffect = true;
      setState(() {});
      Future.delayed(const Duration(seconds: 2), () {
        _wagController.stop();
        _showHeartEffect = false;
        setState(() {});
      });
    } else if (msg.contains("fuck") || msg.contains("angry") || msg.contains("😡")) {
      _triggerEmotion('angry');
      _angryController.repeat(reverse: true);
      _playSound('angry.mp3');
      Future.delayed(const Duration(milliseconds: 800), () => _angryController.stop());
    } else if (msg.contains("play") || msg.contains("fun") || msg.contains("game")) {
      _triggerEmotion('playful');
      _startRandomWalk();
      _playSound('bounce.mp3');
    } else if (msg.contains("sad") || msg.contains("😢") || msg.contains("cry")) {
      _triggerEmotion('sad');
      _playSound('whimper.mp3');
    } else if (msg.contains("sleep") || msg.contains("tired") || msg.contains("😴")) {
      _triggerEmotion('sleepy');
      _breathingController.duration = const Duration(seconds: 5);
    } else if (msg.contains("excited") || msg.contains("wow") || msg.contains("amazing")) {
      _triggerEmotion('excited');
      _playSound('excited.mp3');
      _triggerFloatAnimation();
    } else {
      _triggerEmotion('happy');
      _playSound('bounce.mp3');
    }

    HapticFeedback.lightImpact();
  }

  void _triggerEmotion(String emotion) {
    if (!widget.enableEmotions) return;
    
    setState(() {
      _currentEmotion = emotion;
    });
    
    _emotionController.forward(from: 0.0);
    _emotionTimer?.cancel();
    _emotionTimer = Timer(const Duration(seconds: 5), () {
      setState(() {
        _currentEmotion = 'happy';
      });
    });
  }

  void _triggerFloatAnimation() {
    _floatController.forward(from: 0.0).then((_) {
      _floatController.reverse();
    });
  }

  void _startRandomWalk() {
    if (!widget.enableRandomMovement || _isWalking) return;
    
    setState(() {
      _isWalking = true;
    });
    
    final targetPosition = (MediaQuery.of(context).size.width - 100) * (0.1 + 0.8 * (DateTime.now().millisecond / 1000));
    
    _walkController.reset();
    _walkAnimation = Tween<Offset>(
      begin: Offset(_horizontalPosition, 0),
      end: Offset(targetPosition, 0),
    ).animate(CurvedAnimation(parent: _walkController, curve: Curves.easeInOut));
    
    _walkController.forward().then((_) {
      setState(() {
        _horizontalPosition = targetPosition;
        _isWalking = false;
      });
    });
  }

  void _startRandomActionTimer() {
    _randomActionTimer?.cancel();
    _randomActionTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (!_isInactive && widget.enableRandomMovement) {
        final actions = ['walk', 'float', 'emotion'];
        final randomAction = actions[DateTime.now().second % actions.length];
        
        switch (randomAction) {
          case 'walk':
            _startRandomWalk();
            break;
          case 'float':
            _triggerFloatAnimation();
            break;
          case 'emotion':
            final emotions = ['happy', 'playful', 'excited'];
            _triggerEmotion(emotions[DateTime.now().second % emotions.length]);
            break;
        }
      }
    });
  }

  void _triggerLevelUp(int newLevel) {
    _confettiController.play();
    _playSound('level_up.mp3');
    setState(() {
      _showLevelUp = true;
      _lastLevel = newLevel;
    });
    
    // Enhanced level up effects
    _glowController.repeat(reverse: true);
    _triggerEmotion('excited');
    HapticFeedback.heavyImpact();
    
    Future.delayed(const Duration(seconds: 3), () {
      setState(() => _showLevelUp = false);
      _glowController.stop();
    });

    // Notify parent widget
    widget.onLevelUp?.call();

    // Unlock accessories at specific levels with enhanced dialog
    if (newLevel == 1 || newLevel == 3 || newLevel == 5) {
      final Map<int, String> levelRewards = {
        1: "Bow 🎀",
        3: "Scarf 🧣", 
        5: "Crown 👑"
      };
      
      final accessory = levelRewards[newLevel]!;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.celebration, color: Colors.orange, size: 30),
              const SizedBox(width: 8),
              const Text("🎁 Level Up Reward!", style: TextStyle(fontSize: 20)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade100, Colors.pink.shade100],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      "Level $newLevel Achieved!",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "You unlocked: $accessory",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Awesome! 🎉"),
            )
          ],
        ),
      );
    }
  }

  void _startInactivityTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(minutes: 1), () {
      setState(() => _isInactive = true);
    });
  }

  void _startSpeechBubbleTimer() {
    _speechBubbleTimer?.cancel();
    _speechBubbleTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      if (!_isInactive) {
        final petState = Provider.of<PetState>(context, listen: false);
        final pet = availablePets.firstWhere((p) => p.id == petState.selectedPetId);
        if (pet.speechLines.isNotEmpty) {
          final speechLine = (pet.speechLines..shuffle()).first;
          setState(() => _speechText = speechLine);
          
          // Notify parent widget of speech
          widget.onPetSpeech?.call(speechLine);
          
          Future.delayed(const Duration(seconds: 4), () {
            if (mounted) {
              setState(() => _speechText = null);
            }
          });
        }
      }
    });
  }

  Future<void> _playSound(String fileName) async {
    final petState = Provider.of<PetState>(context, listen: false);
    if (!petState.isMuted) {
      try {
        // Try pets/sounds folder first, then fallback to general sounds
        String soundPath = 'pets/sounds/$fileName';
        await _audioPlayer.play(AssetSource(soundPath));
      } catch (e) {
        try {
          // Fallback to general sounds folder
          await _audioPlayer.play(AssetSource('sounds/$fileName'));
        } catch (e) {
          // Ignore audio errors silently
          debugPrint('Could not play sound: $fileName');
        }
      }
    }
  }

  void _handleTap() {
    _tapCount++;
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(milliseconds: 400), () {
      final petState = Provider.of<PetState>(context, listen: false);
      int oldLevel = petState.bondLevel;
      petState.increaseBondXP(10);
      int newLevel = petState.bondLevel;
      if (newLevel > oldLevel) _triggerLevelUp(newLevel);

      if (_tapCount >= 3) {
        // Triple tap opens pet details
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => PetDetailsScreen(userId: widget.userId),
        ));
      } else {
        // Single/double tap effects
        _squishController.forward(from: 0.0);
        _playSound('pet.mp3');
        _triggerEmotion('happy');
        
        // Random positive reaction
        final reactions = ['Yay!', 'Wee!', '*purrs*', 'Happy!', '✨'];
        setState(() {
          _speechText = reactions[DateTime.now().millisecond % reactions.length];
        });
        
        Future.delayed(const Duration(milliseconds: 300), () => _squishController.reverse());
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _speechText = null);
        });
        
        widget.onPetTapped?.call();
        HapticFeedback.mediumImpact();
      }
      _tapCount = 0;
    });
  }

  @override
  void dispose() {
    // Dispose animation controllers
    _wagController.dispose();
    _angryController.dispose();
    _squishController.dispose();
    _breathingController.dispose();
    _floatController.dispose();
    _glowController.dispose();
    _emotionController.dispose();
    _walkController.dispose();
    _confettiController.dispose();
    
    // Cancel timers
    _idleTimer?.cancel();
    _speechBubbleTimer?.cancel();
    _tapTimer?.cancel();
    _emotionTimer?.cancel();
    _walkTimer?.cancel();
    _randomActionTimer?.cancel();
    
    // Dispose audio
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final petState = Provider.of<PetState>(context);
    final pet = petState.currentPet;

    if (!petState.isEnabled || pet == null) return const SizedBox.shrink();

    // Construct the pet image path with accessory if equipped
    String renderedPath = petState.currentPetAssetPath;
    if (petState.selectedAccessory != 'None') {
      // Replace the file extension with accessory suffix
      // Example: cat.png -> cat_bow.png
      final basePath = renderedPath.replaceAll('.png', '');
      renderedPath = '${basePath}_${petState.selectedAccessory.toLowerCase()}.png';
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      bottom: _isInactive ? -5 : 8,
      left: _isWalking ? null : _horizontalPosition,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _isInactive ? 0.5 : 1.0,
        child: GestureDetector(
          onTap: _handleTap,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Confetti effect
              ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 30,
                emissionFrequency: 0.1,
                maxBlastForce: 25,
                minBlastForce: 8,
                gravity: 0.2,
                colors: const [Colors.pink, Colors.purple, Colors.yellow, Colors.blue],
              ),
              
              // Glow effect
              if (_showLevelUp)
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.yellow.withOpacity(_glowAnimation.value * 0.6),
                            blurRadius: 20,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              
              // Main pet widget with all animations
              AnimatedBuilder(
                animation: Listenable.merge([
                  _wagController,
                  _angryController,
                  _squishController,
                  _breathingController,
                  _floatController,
                  _walkController,
                ]),
                builder: (context, child) {
                  double rotate = _wagAnimation.value;
                  double shake = _angryAnimation.value;
                  double scale = _squishAnimation.value * _breathingAnimation.value;
                  double floatOffset = _floatAnimation.value;
                  
                  Offset walkOffset = _isWalking ? _walkAnimation.value : Offset.zero;

                  return Transform.translate(
                    offset: Offset(shake + walkOffset.dx, floatOffset + walkOffset.dy),
                    child: Transform.rotate(
                      angle: rotate,
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(36),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            renderedPath,
                            width: 72,
                            height: 72,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade100,
                                  borderRadius: BorderRadius.circular(36),
                                ),
                                child: const Icon(Icons.pets, size: 36, color: Colors.purple),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // Emotion indicator
              if (widget.enableEmotions && _currentEmotion != 'happy')
                Positioned(
                  top: -15,
                  right: -5,
                  child: AnimatedBuilder(
                    animation: _emotionAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _emotionAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _emotionColors[_currentEmotion]?.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _emotionIcons[_currentEmotion],
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Rarity indicator for legendary pets
              if (pet.isLegendary)
                Positioned(
                  top: -10,
                  left: -5,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: PetUtils.getRarityColor(pet.rarity),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: PetUtils.getRarityColor(pet.rarity).withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      pet.rarity == PetRarity.mythical ? Icons.auto_awesome : Icons.star,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              
              // Heart effect for love emotion
              if (_showHeartEffect)
                Positioned(
                  top: -10,
                  child: AnimatedBuilder(
                    animation: _emotionController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -_emotionAnimation.value * 20),
                        child: Opacity(
                          opacity: 1.0 - _emotionAnimation.value,
                          child: const Text('💕', style: TextStyle(fontSize: 20)),
                        ),
                      );
                    },
                  ),
                ),
              
              // Speech bubble with enhanced styling
              if (_speechText != null)
                Positioned(
                  top: -50,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 120),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.purple.shade50],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.purple.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _speechText!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.purple.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              
              // Level up indicator with enhanced styling
              if (_showLevelUp)
                Positioned(
                  top: -70,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange, Colors.yellow],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "Level $_lastLevel!",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}