import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'updated_pet_list.dart';
import 'pets_integration.dart';

// Particle class for special effects
class Particle {
  final Offset position;
  final Offset velocity;
  final Color color;
  final double size;
  final double life;
  double currentLife;

  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.life,
  }) : currentLife = life;

  void update() {
    currentLife -= 0.016; // Approximately 60 FPS
  }

  bool get isDead => currentLife <= 0;
}

enum PetMood { happy, sad, excited, sleepy, angry, content, sick, energetic }
enum PetAction { idle, playing, feeding, bathing, sleeping, exercising, celebrating, dancing, thinking }

class AnimatedPet extends StatefulWidget {
  final PetAction petAction;
  final PetMood petMood;
  final bool isBathRoom;
  final String? petType;
  final String? petId; // Enhanced to use pet ID instead of just type
  final String? accessory;
  final double size;
  final bool enableParticles;
  final bool enableSounds;
  final bool enableHaptics;
  final Color? overlayColor;
  final Function()? onTap;
  final Function()? onLongPress;
  final bool autoIdleAnimation;
  final double health;
  final double happiness;
  final double energy;

  const AnimatedPet({
    super.key,
    this.petAction = PetAction.idle,
    this.petMood = PetMood.content,
    this.isBathRoom = false,
    this.petType,
    this.petId, // Enhanced parameter
    this.accessory,
    this.size = 150,
    this.enableParticles = true,
    this.enableSounds = false,
    this.enableHaptics = true,
    this.overlayColor,
    this.onTap,
    this.onLongPress,
    this.autoIdleAnimation = true,
    this.health = 100,
    this.happiness = 100,
    this.energy = 100,
  });

  @override
  State<AnimatedPet> createState() => _AnimatedPetState();
}

class _AnimatedPetState extends State<AnimatedPet> 
    with TickerProviderStateMixin {
  
  // Animation controllers
  late AnimationController _primaryController;
  late AnimationController _secondaryController;
  late AnimationController _idleController;
  late AnimationController _particleController;
  late AnimationController _moodController;
  
  // Animations
  late Animation<double> _scaleAnim;
  late Animation<double> _bounceAnim;
  late Animation<double> _rotationAnim;
  late Animation<double> _breathingAnim;
  late Animation<double> _wiggleAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _particleAnim;
  late Animation<Color?> _colorAnim;
  
  // Audio player
  late AudioPlayer _audioPlayer;
  
  // State variables
  bool _isPressed = false;
  bool _isHovered = false;
  List<Particle> _particles = [];
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
    _audioPlayer = AudioPlayer();
    _startAnimations();
  }

  void _initializeControllers() {
    // Primary controller for main actions
    _primaryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Secondary controller for additional effects
    _secondaryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    // Idle controller for continuous idle animations
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    // Particle controller for special effects
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    // Mood controller for mood-based effects
    _moodController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  void _initializeAnimations() {
    // Scale animation for main actions
    _scaleAnim = Tween<double>(
      begin: 1.0, 
      end: 1.2
    ).animate(CurvedAnimation(
      parent: _primaryController,
      curve: Curves.elasticOut,
    ));
    
    // Bounce animation for playing
    _bounceAnim = Tween<double>(
      begin: 0, 
      end: -30
    ).animate(CurvedAnimation(
      parent: _primaryController,
      curve: Curves.bounceOut,
    ));
    
    // Rotation animation for dancing/celebrating
    _rotationAnim = Tween<double>(
      begin: 0, 
      end: 2 * math.pi
    ).animate(CurvedAnimation(
      parent: _secondaryController,
      curve: Curves.easeInOut,
    ));
    
    // Breathing animation for idle state
    _breathingAnim = Tween<double>(
      begin: 0.98, 
      end: 1.02
    ).animate(CurvedAnimation(
      parent: _idleController,
      curve: Curves.easeInOut,
    ));
    
    // Wiggle animation for excited mood
    _wiggleAnim = Tween<double>(
      begin: -0.05, 
      end: 0.05
    ).animate(CurvedAnimation(
      parent: _moodController,
      curve: Curves.easeInOut,
    ));
    
    // Glow animation for health/energy indicators
    _glowAnim = Tween<double>(
      begin: 0.0, 
      end: 1.0
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeInOut,
    ));
    
    // Particle animation for special effects
    _particleAnim = Tween<double>(
      begin: 0.0, 
      end: 1.0
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeOut,
    ));
    
    // Color animation for mood changes
    _colorAnim = ColorTween(
      begin: Colors.transparent,
      end: _getMoodColor(),
    ).animate(CurvedAnimation(
      parent: _moodController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    if (widget.autoIdleAnimation) {
      _idleController.repeat(reverse: true);
    }
    _updateAnimationsForAction();
  }

  Color _getMoodColor() {
    switch (widget.petMood) {
      case PetMood.happy:
        return Colors.yellow.withValues(alpha: 0.3);
      case PetMood.excited:
        return Colors.orange.withValues(alpha: 0.3);
      case PetMood.sad:
        return Colors.blue.withValues(alpha: 0.3);
      case PetMood.angry:
        return Colors.red.withValues(alpha: 0.3);
      case PetMood.sleepy:
        return Colors.purple.withValues(alpha: 0.3);
      case PetMood.sick:
        return Colors.green.withValues(alpha: 0.3);
      case PetMood.energetic:
        return Colors.pink.withValues(alpha: 0.3);
      case PetMood.content:
        return Colors.transparent;
    }
  }

  void _updateAnimationsForAction() {
    // Stop all animations first
    _primaryController.reset();
    _secondaryController.reset();
    _particleController.reset();
    _moodController.reset();

    switch (widget.petAction) {
      case PetAction.playing:
        _primaryController.repeat(reverse: true);
        if (widget.enableParticles) {
          _particleController.repeat();
          _generatePlayParticles();
        }
        break;
      case PetAction.feeding:
        _primaryController.repeat(reverse: true);
        break;
      case PetAction.bathing:
        _primaryController.repeat(reverse: true);
        if (widget.enableParticles) {
          _generateBubbleParticles();
        }
        break;
      case PetAction.celebrating:
        _primaryController.forward();
        _secondaryController.repeat();
        if (widget.enableParticles) {
          _particleController.repeat();
          _generateCelebrationParticles();
        }
        break;
      case PetAction.dancing:
        _secondaryController.repeat();
        _moodController.repeat(reverse: true);
        break;
      case PetAction.sleeping:
        // Slow breathing animation
        break;
      case PetAction.exercising:
        _primaryController.repeat();
        _secondaryController.repeat(reverse: true);
        break;
      case PetAction.thinking:
        _moodController.repeat(reverse: true);
        break;
      case PetAction.idle:
        // Just idle breathing
        break;
    }

    // Start mood animation if needed
    if (widget.petMood != PetMood.content) {
      _moodController.repeat(reverse: true);
    }
  }

  void _generatePlayParticles() {
    final random = math.Random();
    for (int i = 0; i < 10; i++) {
      _particles.add(Particle(
        position: Offset(
          random.nextDouble() * widget.size,
          random.nextDouble() * widget.size,
        ),
        velocity: Offset(
          (random.nextDouble() - 0.5) * 2,
          (random.nextDouble() - 0.5) * 2,
        ),
        color: Colors.yellow,
        size: random.nextDouble() * 5 + 2,
        life: 2.0,
      ));
    }
  }

  void _generateBubbleParticles() {
    final random = math.Random();
    for (int i = 0; i < 8; i++) {
      _particles.add(Particle(
        position: Offset(
          random.nextDouble() * widget.size,
          widget.size * 0.8,
        ),
        velocity: Offset(
          (random.nextDouble() - 0.5) * 0.5,
          -random.nextDouble() * 2 - 1,
        ),
        color: Colors.lightBlue.withValues(alpha: 0.7),
        size: random.nextDouble() * 8 + 3,
        life: 3.0,
      ));
    }
  }

  void _generateCelebrationParticles() {
    final random = math.Random();
    final colors = [Colors.yellow, Colors.pink, Colors.purple, Colors.orange];
    for (int i = 0; i < 15; i++) {
      _particles.add(Particle(
        position: Offset(
          widget.size * 0.5,
          widget.size * 0.3,
        ),
        velocity: Offset(
          (random.nextDouble() - 0.5) * 4,
          -random.nextDouble() * 3 - 1,
        ),
        color: colors[random.nextInt(colors.length)],
        size: random.nextDouble() * 6 + 2,
        life: 2.5,
      ));
    }
  }

  void _triggerHaptic() {
    if (!widget.enableHaptics) return;
    HapticFeedback.lightImpact();
  }

  String _getPetImagePath() {
    // Use Pet model data if petId is provided
    if (widget.petId != null) {
      final pet = PetUtils.getPetById(widget.petId!);
      if (pet != null) {
        // Use accessory if specified
        if (widget.accessory != null) {
          return pet.getAssetPathWithAccessory(widget.accessory!);
        }
        // Return base pet asset
        return pet.assetPath;
      }
    }
    
    // Fallback to old logic for backward compatibility
    String basePath = 'assets/pets/';
    
    if (widget.petType != null) {
      basePath += '${widget.petType!}/';
    }
    
    switch (widget.petAction) {
      case PetAction.playing:
        return '${basePath}pet_playing.png';
      case PetAction.feeding:
        return '${basePath}pet_eating.png';
      case PetAction.bathing:
        return '${basePath}pet_bathing.png';
      case PetAction.sleeping:
        return '${basePath}pet_sleeping.png';
      case PetAction.celebrating:
        return '${basePath}pet_celebrating.png';
      case PetAction.dancing:
        return '${basePath}pet_dancing.png';
      case PetAction.exercising:
        return '${basePath}pet_exercising.png';
      case PetAction.thinking:
        return '${basePath}pet_thinking.png';
      case PetAction.idle:
        return '${basePath}pet_idle.png';
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedPet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.petAction != widget.petAction ||
        oldWidget.petMood != widget.petMood) {
      _updateAnimationsForAction();
    }
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    _idleController.dispose();
    _particleController.dispose();
    _moodController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap!();
        }
        _triggerHaptic();
        // Use integrated pet sound system
        if (widget.petId != null) {
          PetsIntegration.playPetSound(widget.petId!);
        } else if (widget.petType != null) {
          // Create a temporary ID for pet type
          PetsIntegration.playPetSound('${widget.petType}001');
        }
      },
      onLongPress: () {
        if (widget.onLongPress != null) {
          widget.onLongPress!();
        }
        _triggerHaptic();
        // Use integrated pet sound system for long press too
        if (widget.petId != null) {
          PetsIntegration.playPetSound(widget.petId!);
        } else if (widget.petType != null) {
          PetsIntegration.playPetSound('${widget.petType}001');
        }
      },
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            _isHovered = true;
          });
        },
        onExit: (_) {
          setState(() {
            _isHovered = false;
          });
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _primaryController,
            _secondaryController,
            _idleController,
            _moodController,
          ]),
          builder: (context, child) {
            return Container(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Health glow effect
                  if (widget.health < 30)
                    _buildHealthWarningGlow(),
                  
                  // Mood overlay
                  if (widget.petMood != PetMood.content)
                    _buildMoodOverlay(),
                  
                  // Main pet with all transformations
                  _buildMainPet(),
                  
                  // Accessory overlay
                  if (widget.accessory != null)
                    _buildAccessory(),
                  
                  // Particle effects
                  if (widget.enableParticles)
                    _buildParticleEffects(),
                  
                  // Status indicators
                  _buildStatusIndicators(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHealthWarningGlow() {
    return Container(
      width: widget.size * 1.2,
      height: widget.size * 1.2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3 * _glowAnim.value),
            blurRadius: 20,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildMoodOverlay() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _colorAnim.value,
      ),
    );
  }

  Widget _buildMainPet() {
    double scale = 1.0;
    double translateY = 0.0;
    double rotation = 0.0;
    
    // Apply idle breathing if enabled
    if (widget.autoIdleAnimation) {
      scale *= _breathingAnim.value;
    }
    
    // Apply action-specific transformations
    switch (widget.petAction) {
      case PetAction.playing:
        scale *= _scaleAnim.value;
        translateY = _bounceAnim.value;
        break;
      case PetAction.feeding:
        scale *= 1.0 + (_scaleAnim.value - 1.0) * 0.5;
        break;
      case PetAction.bathing:
        scale *= 1.0 + (_scaleAnim.value - 1.0) * 0.3;
        translateY = widget.isBathRoom ? 40 : 0;
        break;
      case PetAction.sleeping:
        scale *= 0.95;
        break;
      case PetAction.celebrating:
        scale *= _scaleAnim.value;
        rotation = _rotationAnim.value * 0.1; // Slight rotation
        break;
      case PetAction.dancing:
        rotation = _rotationAnim.value * 0.2;
        scale *= 1.0 + math.sin(_secondaryController.value * 2 * math.pi) * 0.1;
        break;
      case PetAction.exercising:
        scale *= 1.0 + (_scaleAnim.value - 1.0) * 0.7;
        translateY = math.sin(_secondaryController.value * 2 * math.pi) * 10;
        break;
      case PetAction.thinking:
        rotation = _wiggleAnim.value;
        break;
      case PetAction.idle:
        // Just breathing
        break;
    }
    
    // Apply mood effects
    if (widget.petMood == PetMood.excited) {
      rotation += _wiggleAnim.value * 0.5;
    }
    
    // Apply interaction effects
    if (_isPressed) {
      scale *= 0.95;
    }
    if (_isHovered) {
      scale *= 1.05;
    }
    
    return Transform.translate(
      offset: Offset(0, translateY),
      child: Transform.rotate(
        angle: rotation,
        child: Transform.scale(
          scale: scale,
          child: Container(
            decoration: widget.overlayColor != null
                ? BoxDecoration(
                    color: widget.overlayColor,
                    shape: BoxShape.circle,
                  )
                : null,
            child: Image.asset(
              _getPetImagePath(),
              width: widget.size,
              height: widget.size,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.pets,
                    size: widget.size * 0.6,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccessory() {
    return Transform.scale(
      scale: 1.0 + (_scaleAnim.value - 1.0) * 0.3,
      child: Image.asset(
        'assets/pets/accessories/${widget.accessory}.png',
        width: widget.size,
        height: widget.size,
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildParticleEffects() {
    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: ParticlePainter(
        particles: _particles,
        animationValue: _particleAnim.value,
      ),
    );
  }

  Widget _buildStatusIndicators() {
    return Positioned(
      top: 0,
      right: 0,
      child: Column(
        children: [
          if (widget.health < 50)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          if (widget.energy < 30)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          if (widget.happiness < 30)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Custom painter for particle effects
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  ParticlePainter({
    required this.particles,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      if (!particle.isDead) {
        final paint = Paint()
          ..color = particle.color.withValues(alpha: particle.currentLife / particle.life)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          particle.position,
          particle.size * (particle.currentLife / particle.life),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
