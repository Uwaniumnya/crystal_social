import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'shiny_gem_animation.dart';
import 'gemstone_model.dart';

class EnhancedGemUnlockPopup extends StatefulWidget {
  final Gemstone gem;
  final String? customUnlockMessage;
  final bool? customIsRareUnlock;
  final VoidCallback? onClose;
  final bool showStats;
  final bool playSound;
  final bool showElementInfo;
  final bool showTags;
  
  const EnhancedGemUnlockPopup({
    super.key,
    required this.gem,
    this.customUnlockMessage,
    this.customIsRareUnlock,
    this.onClose,
    this.showStats = true,
    this.playSound = true,
    this.showElementInfo = true,
    this.showTags = false,
  });

  @override
  State<EnhancedGemUnlockPopup> createState() => _EnhancedGemUnlockPopupState();
}

class _EnhancedGemUnlockPopupState extends State<EnhancedGemUnlockPopup>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _contentController;
  late AnimationController _confettiController;
  late AnimationController _pulseController;
  late AnimationController _textController;
  
  late Animation<double> _backgroundScale;
  late Animation<double> _contentFade;
  late Animation<double> _contentScale;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _textTypewriter;
  
  List<ConfettiParticle> confettiParticles = [];
  List<StarParticle> starParticles = [];
  Timer? _autoCloseTimer;
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    _setupAnimationControllers();
    _setupAnimations();
    _generateParticles();
    _startSequence();
    
    if (widget.playSound) {
      HapticFeedback.mediumImpact();
    }
  }

  void _setupAnimationControllers() {
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _confettiController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _textController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
  }

  void _setupAnimations() {
    _backgroundScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.elasticOut,
    ));

    _contentFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _contentScale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
    ));

    _textTypewriter = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    ));
  }

  void _generateParticles() {
    final random = Random();
    
    // Generate confetti particles
    confettiParticles = List.generate(30, (index) {
      return ConfettiParticle(
        position: Offset(
          random.nextDouble(),
          -0.1 - random.nextDouble() * 0.1,
        ),
        velocity: Offset(
          (random.nextDouble() - 0.5) * 2,
          random.nextDouble() * 3 + 2,
        ),
        color: _getRandomConfettiColor(),
        size: random.nextDouble() * 8 + 4,
        rotation: random.nextDouble() * 2 * pi,
        rotationSpeed: (random.nextDouble() - 0.5) * 8,
      );
    });

    // Generate star particles
    starParticles = List.generate(15, (index) {
      return StarParticle(
        position: Offset(
          random.nextDouble(),
          random.nextDouble(),
        ),
        delay: random.nextDouble() * 2,
        size: random.nextDouble() * 6 + 2,
        color: Colors.white.withOpacity(0.8),
      );
    });
  }

  Color _getRandomConfettiColor() {
    final colors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFFC0C0C0), // Silver
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.pink,
    ];
    return colors[Random().nextInt(colors.length)];
  }

  void _startSequence() async {
    // Start background animation
    await _backgroundController.forward();
    
    // Show content after a brief delay
    setState(() => _showContent = true);
    
    // Start content animations
    _contentController.forward();
    _confettiController.forward();
    
    // Start pulse animation
    await Future.delayed(const Duration(milliseconds: 500));
    _pulseController.repeat(reverse: true);
    
    // Start text typewriter effect
    await Future.delayed(const Duration(milliseconds: 300));
    _textController.forward();
    
    // Haptic feedback for rare unlocks
    if (_isRareUnlock) {
      await Future.delayed(const Duration(milliseconds: 800));
      HapticFeedback.heavyImpact();
    }
    
    // Auto-close timer
    _autoCloseTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) _closePopup();
    });
  }

  void _closePopup() {
    widget.onClose?.call();
    Navigator.of(context).pop();
  }

  // Helper getters for integrated gem properties
  bool get _isRareUnlock => widget.customIsRareUnlock ?? widget.gem.isRareUnlock;
  String get _unlockMessage => widget.customUnlockMessage ?? widget.gem.unlockMessage;
  GemRarity get _gemRarity => widget.gem.rarityEnum;
  Color get _rarityColor => widget.gem.rarityColor;

  GemRarity _getGemRarity() {
    return _gemRarity;
  }

  Color _getRarityColor() {
    return _rarityColor;
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _contentController.dispose();
    _confettiController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _closePopup,
      child: Scaffold(
        backgroundColor: Colors.black54,
        body: Stack(
          children: [
            // Animated background overlay
            AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) => Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: _backgroundScale.value * 2,
                    colors: [
                      _getRarityColor().withOpacity(0.3 * _backgroundScale.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Confetti particles
            AnimatedBuilder(
              animation: _confettiController,
              builder: (context, child) => CustomPaint(
                painter: ConfettiPainter(confettiParticles, _confettiController.value),
                size: MediaQuery.of(context).size,
              ),
            ),

            // Star particles
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) => CustomPaint(
                painter: StarPainter(starParticles, _pulseController.value),
                size: MediaQuery.of(context).size,
              ),
            ),

            // Main content
            Center(
              child: _showContent ? _buildContent() : const SizedBox.shrink(),
            ),

            // Close button
            Positioned(
              top: 50,
              right: 20,
              child: AnimatedBuilder(
                animation: _contentController,
                builder: (context, child) => Opacity(
                  opacity: _contentFade.value * 0.7,
                  child: IconButton(
                    onPressed: _closePopup,
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return AnimatedBuilder(
      animation: Listenable.merge([_contentController, _pulseController, _textController]),
      builder: (context, child) => Opacity(
        opacity: _contentFade.value,
        child: Transform.scale(
          scale: _contentScale.value,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _getRarityColor().withOpacity(0.6),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getRarityColor().withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Rarity indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getRarityColor(),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getGemRarity().name.toUpperCase(),
                      style: GoogleFonts.orbitron(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Enhanced gem animation
                  Transform.scale(
                    scale: _pulseAnimation.value,
                    child: widget.gem.createAnimation(
                      size: 120,
                      animationType: _isRareUnlock 
                        ? widget.gem.preferredAnimation 
                        : widget.gem.elementAnimation,
                      showParticles: _isRareUnlock,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Unlock message with typewriter effect
                  _buildTypewriterText(
                    '${_unlockMessage} ${widget.gem.name}!',
                    GoogleFonts.orbitron(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: _getRarityColor(),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Gem description
                  AnimatedOpacity(
                    opacity: _textController.value > 0.7 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      widget.gem.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  if (widget.showStats) ...[
                    const SizedBox(height: 20),
                    _buildStatsSection(),
                  ],

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        'View Collection',
                        Icons.collections,
                        () {
                          _closePopup();
                          // Navigate to collection
                        },
                      ),
                      _buildActionButton(
                        'Share',
                        Icons.share,
                        () {
                          // Share functionality
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypewriterText(String text, TextStyle style) {
    final displayLength = (_textTypewriter.value * text.length).round();
    final displayText = text.substring(0, displayLength);
    
    return Text(
      displayText,
      style: style,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStatsSection() {
    return AnimatedOpacity(
      opacity: _textController.value > 0.8 ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            // Main stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Rarity', _getGemRarity().name.toUpperCase()),
                _buildStatItem('Power', widget.gem.power.toString()),
                _buildStatItem('Value', widget.gem.value.toString()),
              ],
            ),
            
            // Element info if enabled
            if (widget.showElementInfo) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.gem.elementColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.gem.elementColor.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.gem.elementIcon,
                      color: widget.gem.elementColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.gem.element.toUpperCase(),
                      style: GoogleFonts.orbitron(
                        fontSize: 14,
                        color: widget.gem.elementColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Tags if enabled
            if (widget.showTags && widget.gem.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.gem.tags.take(3).map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRarityColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.orbitron(
            fontSize: 18,
            color: _getRarityColor(),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: _getRarityColor().withOpacity(0.8),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

// Keep original for backward compatibility
class GemUnlockPopup extends StatelessWidget {
  final Gemstone gem;
  final String? unlockMessage;
  final bool? isRareUnlock;
  final VoidCallback? onClose;
  
  const GemUnlockPopup({
    super.key,
    required this.gem,
    this.unlockMessage,
    this.isRareUnlock,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedGemUnlockPopup(
      gem: gem,
      customUnlockMessage: unlockMessage,
      customIsRareUnlock: isRareUnlock,
      onClose: onClose,
    );
  }
}

// Particle system classes
class ConfettiParticle {
  Offset position;
  final Offset velocity;
  final Color color;
  final double size;
  double rotation;
  final double rotationSpeed;

  ConfettiParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class StarParticle {
  final Offset position;
  final double delay;
  final double size;
  final Color color;

  StarParticle({
    required this.position,
    required this.delay,
    required this.size,
    required this.color,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      // Update particle position
      particle.position += particle.velocity * 0.016; // 60fps approximation
      particle.rotation += particle.rotationSpeed * 0.016;

      // Reset particle if it's off screen
      if (particle.position.dy > 1.2) {
        particle.position = Offset(
          Random().nextDouble(),
          -0.1,
        );
      }

      final paint = Paint()
        ..color = particle.color.withOpacity(0.8)
        ..style = PaintingStyle.fill;

      final center = Offset(
        particle.position.dx * size.width,
        particle.position.dy * size.height,
      );

      // Draw confetti piece
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(particle.rotation);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.6,
          ),
          Radius.circular(particle.size * 0.3),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class StarPainter extends CustomPainter {
  final List<StarParticle> particles;
  final double progress;

  StarPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final animationProgress = ((progress + particle.delay) % 1.0);
      final opacity = (sin(animationProgress * 2 * pi) + 1) / 2;

      if (opacity > 0.1) {
        final paint = Paint()
          ..color = particle.color.withOpacity(opacity)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

        final center = Offset(
          particle.position.dx * size.width,
          particle.position.dy * size.height,
        );

        // Draw star shape
        final path = Path();
        const numPoints = 5;
        final outerRadius = particle.size;
        final innerRadius = particle.size * 0.4;

        for (int i = 0; i < numPoints * 2; i++) {
          final angle = (i * pi / numPoints);
          final radius = (i % 2 == 0) ? outerRadius : innerRadius;
          final point = Offset(
            center.dx + cos(angle) * radius,
            center.dy + sin(angle) * radius,
          );

          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        path.close();

        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
