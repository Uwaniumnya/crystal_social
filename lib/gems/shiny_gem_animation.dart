import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';

enum GemAnimationType {
  pulse,
  rotate,
  glow,
  shimmer,
  bounce,
  sparkle,
  float,
  rainbow,
}

enum GemRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

class EnhancedShinyGemAnimation extends StatefulWidget {
  final String imagePath;
  final double size;
  final GemAnimationType animationType;
  final GemRarity rarity;
  final bool showParticles;
  final bool showGlow;
  final bool enableRandomAnimation;
  final Duration animationDuration;
  final Color? customColor;

  const EnhancedShinyGemAnimation({
    super.key,
    required this.imagePath,
    this.size = 100,
    this.animationType = GemAnimationType.pulse,
    this.rarity = GemRarity.common,
    this.showParticles = true,
    this.showGlow = true,
    this.enableRandomAnimation = false,
    this.animationDuration = const Duration(milliseconds: 2000),
    this.customColor,
  });

  @override
  State<EnhancedShinyGemAnimation> createState() => _EnhancedShinyGemAnimationState();
}

class _EnhancedShinyGemAnimationState extends State<EnhancedShinyGemAnimation>
    with TickerProviderStateMixin {
  late AnimationController _primaryController;
  late AnimationController _secondaryController;
  late AnimationController _particleController;
  late AnimationController _shimmerController;
  
  late Animation<double> _scale;
  late Animation<double> _rotation;
  late Animation<double> _glow;
  late Animation<double> _bounce;
  late Animation<Offset> _float;
  late Animation<double> _shimmer;
  late Animation<Color?> _rainbow;
  
  List<GemParticle> particles = [];
  Timer? _animationSwitchTimer;
  GemAnimationType _currentAnimationType = GemAnimationType.pulse;

  @override
  void initState() {
    super.initState();
    _currentAnimationType = widget.animationType;
    _setupAnimationControllers();
    _setupAnimations();
    _generateParticles();
    _startAnimations();
    
    if (widget.enableRandomAnimation) {
      _startRandomAnimationSwitching();
    }
  }

  void _setupAnimationControllers() {
    _primaryController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _secondaryController = AnimationController(
      duration: Duration(milliseconds: (widget.animationDuration.inMilliseconds * 0.7).round()),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  void _setupAnimations() {
    // Scale animation for pulse and bounce
    _scale = Tween<double>(
      begin: 1.0,
      end: _getScaleMultiplier(),
    ).animate(CurvedAnimation(
      parent: _primaryController,
      curve: Curves.easeInOut,
    ));

    // Rotation animation
    _rotation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _primaryController,
      curve: Curves.linear,
    ));

    // Glow animation
    _glow = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _secondaryController,
      curve: Curves.easeInOut,
    ));

    // Bounce animation
    _bounce = Tween<double>(
      begin: 0.0,
      end: -20.0,
    ).animate(CurvedAnimation(
      parent: _primaryController,
      curve: Curves.bounceOut,
    ));

    // Float animation
    _float = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -0.1),
    ).animate(CurvedAnimation(
      parent: _primaryController,
      curve: Curves.easeInOut,
    ));

    // Shimmer animation
    _shimmer = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.linear,
    ));

    // Rainbow animation
    _rainbow = ColorTween(
      begin: _getRarityColor(),
      end: _getRainbowColor(),
    ).animate(CurvedAnimation(
      parent: _primaryController,
      curve: Curves.linear,
    ));
  }

  void _generateParticles() {
    if (!widget.showParticles) return;
    
    final particleCount = _getParticleCount();
    particles = List.generate(particleCount, (index) => GemParticle.random());
  }

  void _startAnimations() {
    switch (_currentAnimationType) {
      case GemAnimationType.pulse:
        _primaryController.repeat(reverse: true);
        _secondaryController.repeat(reverse: true);
        break;
      case GemAnimationType.rotate:
        _primaryController.repeat();
        break;
      case GemAnimationType.glow:
        _secondaryController.repeat(reverse: true);
        break;
      case GemAnimationType.shimmer:
        _shimmerController.repeat();
        _secondaryController.repeat(reverse: true);
        break;
      case GemAnimationType.bounce:
        _primaryController.repeat();
        break;
      case GemAnimationType.sparkle:
        _primaryController.repeat(reverse: true);
        _particleController.repeat();
        break;
      case GemAnimationType.float:
        _primaryController.repeat(reverse: true);
        break;
      case GemAnimationType.rainbow:
        _primaryController.repeat();
        _secondaryController.repeat(reverse: true);
        break;
    }
  }

  void _startRandomAnimationSwitching() {
    _animationSwitchTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _switchToRandomAnimation();
      }
    });
  }

  void _switchToRandomAnimation() {
    final animations = GemAnimationType.values;
    final random = Random();
    final newAnimation = animations[random.nextInt(animations.length)];
    
    if (newAnimation != _currentAnimationType) {
      setState(() {
        _currentAnimationType = newAnimation;
        _resetAnimations();
        _startAnimations();
      });
    }
  }

  void _resetAnimations() {
    _primaryController.reset();
    _secondaryController.reset();
    _particleController.reset();
    _shimmerController.reset();
  }

  double _getScaleMultiplier() {
    switch (widget.rarity) {
      case GemRarity.common:
        return 1.1;
      case GemRarity.uncommon:
        return 1.15;
      case GemRarity.rare:
        return 1.2;
      case GemRarity.epic:
        return 1.25;
      case GemRarity.legendary:
        return 1.3;
    }
  }

  int _getParticleCount() {
    switch (widget.rarity) {
      case GemRarity.common:
        return 3;
      case GemRarity.uncommon:
        return 5;
      case GemRarity.rare:
        return 8;
      case GemRarity.epic:
        return 12;
      case GemRarity.legendary:
        return 20;
    }
  }

  Color _getRarityColor() {
    if (widget.customColor != null) return widget.customColor!;
    
    switch (widget.rarity) {
      case GemRarity.common:
        return Colors.grey;
      case GemRarity.uncommon:
        return Colors.green;
      case GemRarity.rare:
        return Colors.blue;
      case GemRarity.epic:
        return Colors.purple;
      case GemRarity.legendary:
        return Colors.orange;
    }
  }

  Color _getRainbowColor() {
    final colors = [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple];
    return colors[Random().nextInt(colors.length)];
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    _particleController.dispose();
    _shimmerController.dispose();
    _animationSwitchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 1.5,
      height: widget.size * 1.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Particle effects background
          if (widget.showParticles && _currentAnimationType == GemAnimationType.sparkle)
            ...particles.map((particle) => AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) => _buildParticle(particle),
            )),

          // Glow effect
          if (widget.showGlow)
            AnimatedBuilder(
              animation: _glow,
              builder: (context, child) => Container(
                width: widget.size * 1.4,
                height: widget.size * 1.4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getRarityColor().withOpacity(_glow.value * 0.6),
                      blurRadius: 20 * _glow.value,
                      spreadRadius: 5 * _glow.value,
                    ),
                  ],
                ),
              ),
            ),

          // Main gem animation
          AnimatedBuilder(
            animation: Listenable.merge([
              _primaryController,
              _secondaryController,
              _shimmerController,
            ]),
            builder: (context, child) => _buildMainGem(),
          ),

          // Shimmer overlay
          if (_currentAnimationType == GemAnimationType.shimmer)
            AnimatedBuilder(
              animation: _shimmer,
              builder: (context, child) => _buildShimmerOverlay(),
            ),

          // Floating sparkles for legendary gems
          if (widget.rarity == GemRarity.legendary && _currentAnimationType != GemAnimationType.sparkle)
            ...List.generate(5, (index) => AnimatedBuilder(
              animation: _secondaryController,
              builder: (context, child) => _buildFloatingSparkle(index),
            )),
        ],
      ),
    );
  }

  Widget _buildMainGem() {
    Widget gem = Image.asset(
      widget.imagePath,
      height: widget.size,
      width: widget.size,
      fit: BoxFit.contain,
    );

    switch (_currentAnimationType) {
      case GemAnimationType.pulse:
        return ScaleTransition(scale: _scale, child: gem);
        
      case GemAnimationType.rotate:
        return RotationTransition(turns: _rotation, child: gem);
        
      case GemAnimationType.glow:
        return ColorFiltered(
          colorFilter: ColorFilter.mode(
            _getRarityColor().withOpacity(_glow.value * 0.3),
            BlendMode.overlay,
          ),
          child: gem,
        );
        
      case GemAnimationType.shimmer:
        return ScaleTransition(scale: _scale, child: gem);
        
      case GemAnimationType.bounce:
        return Transform.translate(
          offset: Offset(0, _bounce.value),
          child: gem,
        );
        
      case GemAnimationType.sparkle:
        return ScaleTransition(
          scale: _scale,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(_glow.value * 0.2),
              BlendMode.overlay,
            ),
            child: gem,
          ),
        );
        
      case GemAnimationType.float:
        return SlideTransition(position: _float, child: gem);
        
      case GemAnimationType.rainbow:
        return ColorFiltered(
          colorFilter: ColorFilter.mode(
            _rainbow.value ?? _getRarityColor(),
            BlendMode.overlay,
          ),
          child: ScaleTransition(scale: _scale, child: gem),
        );
    }
  }

  Widget _buildParticle(GemParticle particle) {
    final progress = (_particleController.value + particle.delay) % 1.0;
    final opacity = (sin(progress * 2 * pi) + 1) / 2;
    
    return Positioned(
      left: (widget.size * 0.75) + (particle.offset.dx * widget.size * 0.5),
      top: (widget.size * 0.75) + (particle.offset.dy * widget.size * 0.5),
      child: Opacity(
        opacity: opacity * particle.opacity,
        child: Container(
          width: particle.size,
          height: particle.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: particle.color,
            boxShadow: [
              BoxShadow(
                color: particle.color.withOpacity(0.5),
                blurRadius: particle.size * 0.5,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerOverlay() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.size / 2),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [
              (_shimmer.value - 0.3).clamp(0.0, 1.0),
              _shimmer.value.clamp(0.0, 1.0),
              (_shimmer.value + 0.3).clamp(0.0, 1.0),
            ],
            colors: [
              Colors.transparent,
              Colors.white.withOpacity(0.6),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingSparkle(int index) {
    final angle = (index * 2 * pi / 5) + (_secondaryController.value * 2 * pi);
    final radius = widget.size * 0.6;
    final x = cos(angle) * radius;
    final y = sin(angle) * radius;
    
    return Transform.translate(
      offset: Offset(x, y),
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: _getRarityColor().withOpacity(0.8),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class GemParticle {
  final Offset offset;
  final double size;
  final Color color;
  final double opacity;
  final double delay;

  GemParticle({
    required this.offset,
    required this.size,
    required this.color,
    required this.opacity,
    required this.delay,
  });

  factory GemParticle.random() {
    final random = Random();
    final angle = random.nextDouble() * 2 * pi;
    final distance = 0.3 + random.nextDouble() * 0.4;
    
    return GemParticle(
      offset: Offset(
        cos(angle) * distance,
        sin(angle) * distance,
      ),
      size: 2 + random.nextDouble() * 4,
      color: [
        Colors.white,
        Colors.yellow,
        Colors.cyan,
        Colors.pink,
        Colors.purple,
      ][random.nextInt(5)],
      opacity: 0.5 + random.nextDouble() * 0.5,
      delay: random.nextDouble(),
    );
  }
}

// Keep the original for backward compatibility
class ShinyGemAnimation extends StatelessWidget {
  final String imagePath;
  final double size;
  
  const ShinyGemAnimation({
    super.key,
    required this.imagePath,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedShinyGemAnimation(
      imagePath: imagePath,
      size: size,
      animationType: GemAnimationType.pulse,
      rarity: GemRarity.common,
    );
  }
}
