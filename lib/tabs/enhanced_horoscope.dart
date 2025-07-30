import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import '../tabs/tarot_reading.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../rewards/rewards_manager.dart';

void main() {
  runApp(MaterialApp(
    home: EnhancedCrystalHoroscopeTab(),
  ));
}

// Advanced Particle System for Cosmic Effects
class ParticleSystem extends StatefulWidget {
  final int particleCount;
  final Color particleColor;
  final double maxSize;
  final double speed;
  final bool isStars;

  const ParticleSystem({
    super.key,
    this.particleCount = 50,
    this.particleColor = Colors.white,
    this.maxSize = 3.0,
    this.speed = 1.0,
    this.isStars = true,
  });

  @override
  _ParticleSystemState createState() => _ParticleSystemState();
}

class _ParticleSystemState extends State<ParticleSystem>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  List<Particle> particles = [];
  late Timer _particleTimer;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: Duration(milliseconds: 16), // 60 FPS
      vsync: this,
    )..repeat();

    _initializeParticles();
    
    _particleTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      _updateParticles();
    });
  }

  void _initializeParticles() {
    final random = Random();
    particles.clear();
    
    for (int i = 0; i < widget.particleCount; i++) {
      particles.add(Particle(
        x: random.nextDouble() * 400,
        y: random.nextDouble() * 800,
        size: random.nextDouble() * widget.maxSize + 1,
        speed: random.nextDouble() * widget.speed + 0.5,
        opacity: random.nextDouble() * 0.8 + 0.2,
        twinkleSpeed: random.nextDouble() * 2 + 0.5,
        color: widget.particleColor,
        isStarShape: widget.isStars,
      ));
    }
  }

  void _updateParticles() {
    setState(() {
      for (var particle in particles) {
        particle.update();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _particleTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ParticlePainter(particles),
      size: Size.infinite,
    );
  }
}

class Particle {
  double x, y, size, speed, opacity, twinkleSpeed;
  Color color;
  bool isStarShape;
  double twinklePhase = 0;
  double driftX = 0;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.twinkleSpeed,
    required this.color,
    this.isStarShape = true,
  }) {
    driftX = Random().nextDouble() * 0.5 - 0.25;
  }

  void update() {
    y += speed;
    x += driftX;
    twinklePhase += twinkleSpeed * 0.1;
    
    // Reset particle when it goes off screen
    if (y > 800) {
      y = -10;
      x = Random().nextDouble() * 400;
    }
    
    // Wrap horizontally
    if (x < 0) x = 400;
    if (x > 400) x = 0;
  }

  double getTwinkleOpacity() {
    return opacity * (0.5 + 0.5 * sin(twinklePhase));
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.getTwinkleOpacity())
        ..style = PaintingStyle.fill;

      if (particle.isStarShape) {
        _drawStar(canvas, Offset(particle.x, particle.y), particle.size, paint);
      } else {
        canvas.drawCircle(
          Offset(particle.x, particle.y),
          particle.size,
          paint,
        );
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final angle = pi / 5;
    
    for (int i = 0; i < 10; i++) {
      final radius = i.isEven ? size : size * 0.5;
      final x = center.dx + radius * cos(i * angle - pi / 2);
      final y = center.dy + radius * sin(i * angle - pi / 2);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// Floating Crystal Animation Widget
class FloatingCrystal extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;

  const FloatingCrystal({
    super.key,
    this.color = Colors.purple,
    this.size = 30,
    this.duration = const Duration(seconds: 3),
  });

  @override
  _FloatingCrystalState createState() => _FloatingCrystalState();
}

class _FloatingCrystalState extends State<FloatingCrystal>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _rotateController;
  late AnimationController _glowController;
  late Animation<double> _floatAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    _floatController = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(
      begin: -10,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));

    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(_rotateController);

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _floatController.dispose();
    _rotateController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatAnimation, _rotateAnimation, _glowAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Transform.rotate(
            angle: _rotateAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(_glowAnimation.value),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: CustomPaint(
                painter: CrystalPainter(widget.color, _glowAnimation.value),
                size: Size(widget.size, widget.size),
              ),
            ),
          ),
        );
      },
    );
  }
}

class CrystalPainter extends CustomPainter {
  final Color color;
  final double glowIntensity;

  CrystalPainter(this.color, this.glowIntensity);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = color.withOpacity(glowIntensity * 0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5);

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    
    // Create diamond/crystal shape
    path.moveTo(center.dx, center.dy - size.height * 0.4);
    path.lineTo(center.dx + size.width * 0.3, center.dy - size.height * 0.1);
    path.lineTo(center.dx + size.width * 0.2, center.dy + size.height * 0.4);
    path.lineTo(center.dx - size.width * 0.2, center.dy + size.height * 0.4);
    path.lineTo(center.dx - size.width * 0.3, center.dy - size.height * 0.1);
    path.close();

    // Draw glow effect
    canvas.drawPath(path, glowPaint);
    
    // Draw main crystal
    canvas.drawPath(path, paint);
    
    // Add inner facets
    final facetPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    canvas.drawLine(
      Offset(center.dx, center.dy - size.height * 0.4),
      Offset(center.dx, center.dy + size.height * 0.1),
      facetPaint,
    );
    
    canvas.drawLine(
      Offset(center.dx - size.width * 0.15, center.dy),
      Offset(center.dx + size.width * 0.15, center.dy),
      facetPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// Cosmic Energy Wave Animation
class CosmicWaveAnimation extends StatefulWidget {
  final Color color;
  final double amplitude;
  final Duration duration;

  const CosmicWaveAnimation({
    super.key,
    this.color = Colors.deepPurpleAccent,
    this.amplitude = 50,
    this.duration = const Duration(seconds: 4),
  });

  @override
  _CosmicWaveAnimationState createState() => _CosmicWaveAnimationState();
}

class _CosmicWaveAnimationState extends State<CosmicWaveAnimation>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    
    _waveController = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();

    _waveAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(_waveController);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: CosmicWavePainter(
            widget.color,
            _waveAnimation.value,
            widget.amplitude,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class CosmicWavePainter extends CustomPainter {
  final Color color;
  final double phase;
  final double amplitude;

  CosmicWavePainter(this.color, this.phase, this.amplitude);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final waveLength = size.width / 4;
    
    for (int i = 0; i < 3; i++) {
      path.reset();
      final yOffset = size.height * 0.3 + i * size.height * 0.2;
      
      for (double x = 0; x <= size.width; x += 1) {
        final y = yOffset + amplitude * sin((x / waveLength) + phase + i * 0.5);
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      
      paint.color = color.withOpacity(0.3 - i * 0.1);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// Moon Phase Tracking Tab - NEW FEATURE
class MoonPhaseTrackingTab extends StatefulWidget {
  final String? userId;
  final SupabaseClient? supabase;

  const MoonPhaseTrackingTab({
    super.key,
    this.userId,
    this.supabase,
  });

  @override
  _MoonPhaseTrackingTabState createState() => _MoonPhaseTrackingTabState();
}

class _MoonPhaseTrackingTabState extends State<MoonPhaseTrackingTab>
    with TickerProviderStateMixin {
  String currentMoonPhase = "";
  String moonDescription = "";
  double moonIllumination = 0.0;
  String moonSign = "";
  String moonInfluence = "";
  List<String> moonAdvice = [];
  List<String> moonRituals = [];
  String moonElement = "";
  Color moonColor = Colors.white;
  
  late AnimationController _moonController;
  late AnimationController _glowController;
  late Animation<double> _moonAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    _moonController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);

    _moonAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _moonController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _loadMoonPhaseData();
  }

  @override
  void dispose() {
    _moonController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _loadMoonPhaseData() {
    final now = DateTime.now();
    final moonData = _calculateMoonPhase(now);
    
    setState(() {
      currentMoonPhase = moonData['phase'];
      moonDescription = moonData['description'];
      moonIllumination = moonData['illumination'];
      moonSign = moonData['sign'];
      moonInfluence = moonData['influence'];
      moonAdvice = List<String>.from(moonData['advice']);
      moonRituals = List<String>.from(moonData['rituals']);
      moonElement = moonData['element'];
      moonColor = moonData['color'];
    });
  }

  Map<String, dynamic> _calculateMoonPhase(DateTime date) {
    // Simplified moon phase calculation
    final daysSinceNewMoon = (date.millisecondsSinceEpoch ~/ 86400000) % 29.53;
    final illumination = (1 - cos(2 * pi * daysSinceNewMoon / 29.53)) / 2;
    
    String phase;
    String description;
    String influence;
    List<String> advice;
    List<String> rituals;
    String element;
    Color color;

    if (daysSinceNewMoon < 1) {
      phase = "🌑 New Moon";
      description = "A time of new beginnings and fresh starts. The moon's energy is subtle but powerful for manifestation.";
      influence = "Perfect for setting intentions, planning new projects, and releasing old patterns that no longer serve you.";
      advice = [
        "Write down your goals and intentions",
        "Practice meditation and introspection",
        "Start new projects or habits",
        "Cleanse your space and energy"
      ];
      rituals = [
        "New Moon manifestation ceremony",
        "Intention setting with crystals",
        "Sacred water blessing ritual",
        "Vision board creation"
      ];
      element = "Earth";
      color = Color(0xFF1A1A2E);
    } else if (daysSinceNewMoon < 7.4) {
      phase = "🌒 Waxing Crescent";
      description = "Growth energy builds as the moon becomes more visible. Time to take action on your intentions.";
      influence = "Your plans gain momentum. Focus on building foundations and taking small, consistent steps forward.";
      advice = [
        "Take concrete steps toward your goals",
        "Build supportive routines and habits",
        "Connect with like-minded people",
        "Practice patience with your progress"
      ];
      rituals = [
        "Candle magic for growth",
        "Plant seeds (literal or metaphorical)",
        "Energy charging ceremonies",
        "Prosperity and abundance rituals"
      ];
      element = "Air";
      color = Color(0xFF2D3748);
    } else if (daysSinceNewMoon < 14.8) {
      phase = "🌓 First Quarter";
      description = "Half the moon is illuminated. A time for decision-making and overcoming obstacles.";
      influence = "Challenges may arise, but they provide opportunities for growth. Stay focused and determined.";
      advice = [
        "Make important decisions with confidence",
        "Push through obstacles and resistance",
        "Evaluate your progress and adjust plans",
        "Practice perseverance and determination"
      ];
      rituals = [
        "Strength and courage ceremonies",
        "Obstacle clearing rituals",
        "Decision-making divination",
        "Protection and grounding practices"
      ];
      element = "Fire";
      color = Color(0xFF4A5568);
    } else if (daysSinceNewMoon < 22.1) {
      phase = "🌕 Full Moon";
      description = "The moon is at its brightest and most powerful. Peak energy for manifestation and release.";
      influence = "Emotions and intuition are heightened. Perfect time for gratitude, celebration, and letting go.";
      advice = [
        "Celebrate your achievements and progress",
        "Release what no longer serves you",
        "Trust your intuition completely",
        "Express gratitude for your blessings"
      ];
      rituals = [
        "Full moon charging ceremony",
        "Gratitude and appreciation rituals",
        "Energy cleansing and clearing",
        "Psychic enhancement practices"
      ];
      element = "Water";
      color = Color(0xFFE2E8F0);
    } else {
      phase = "🌘 Waning Moon";
      description = "The moon's light decreases. Time for release, healing, and inner reflection.";
      influence = "Focus on letting go, healing, and preparing for the next cycle. Wisdom comes through reflection.";
      advice = [
        "Release negative thoughts and patterns",
        "Practice forgiveness and healing",
        "Reflect on lessons learned",
        "Prepare for new beginnings"
      ];
      rituals = [
        "Banishing and release ceremonies",
        "Healing and restoration rituals",
        "Shadow work and introspection",
        "Cord cutting and cleansing"
      ];
      element = "Earth";
      color = Color(0xFF718096);
    }

    // Generate random moon sign for variety
    final moonSigns = ['Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 
                      'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'];
    final randomSign = moonSigns[date.day % 12];

    return {
      'phase': phase,
      'description': description,
      'illumination': illumination,
      'sign': randomSign,
      'influence': influence,
      'advice': advice,
      'rituals': rituals,
      'element': element,
      'color': color,
    };
  }

  Map<String, String> _getMoonSignInfluence(String moonSign) {
    final influences = {
      'Aries': 'Bold action and new initiatives are favored. Your pioneering spirit is amplified.',
      'Taurus': 'Focus on stability, comfort, and material manifestations. Ground your energy.',
      'Gemini': 'Communication and learning are highlighted. Share your ideas freely.',
      'Cancer': 'Emotions and intuition are heightened. Trust your inner wisdom.',
      'Leo': 'Creative expression and confidence shine. Let your authentic self radiate.',
      'Virgo': 'Organization and attention to detail bring success. Perfect practical tasks.',
      'Libra': 'Harmony and balance in relationships are emphasized. Seek diplomatic solutions.',
      'Scorpio': 'Deep transformation and emotional healing are possible. Embrace change.',
      'Sagittarius': 'Adventure and philosophical insights expand your horizons. Seek truth.',
      'Capricorn': 'Discipline and long-term planning yield results. Build lasting foundations.',
      'Aquarius': 'Innovation and humanitarian causes align with cosmic energy. Think big.',
      'Pisces': 'Intuition and spiritual connection are at their peak. Trust your dreams.',
    };
    
    return {
      'influence': influences[moonSign] ?? 'The cosmic energy supports your journey.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0D1117),
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Background particle system
          Positioned.fill(
            child: ParticleSystem(
              particleCount: 60,
              particleColor: Colors.white.withOpacity(0.6),
              maxSize: 2.5,
              speed: 0.8,
              isStars: true,
            ),
          ),
          
          // Cosmic wave animations
          Positioned.fill(
            child: CosmicWaveAnimation(
              color: moonColor.withOpacity(0.4),
              amplitude: 30,
              duration: Duration(seconds: 6),
            ),
          ),
          
          // Floating crystals
          Positioned(
            top: 100,
            right: 30,
            child: FloatingCrystal(
              color: Colors.purpleAccent,
              size: 25,
              duration: Duration(seconds: 4),
            ),
          ),
          Positioned(
            top: 200,
            left: 40,
            child: FloatingCrystal(
              color: Colors.blueAccent,
              size: 20,
              duration: Duration(seconds: 5),
            ),
          ),
          Positioned(
            bottom: 150,
            right: 50,
            child: FloatingCrystal(
              color: Colors.tealAccent,
              size: 30,
              duration: Duration(seconds: 3),
            ),
          ),
          
          // Main content
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Header with enhanced animation
                Container(
                  margin: EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      Text(
                        "Moon Phase Tracking",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: moonColor.withOpacity(0.8),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Align with lunar cycles for enhanced spiritual growth",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white60,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 30),

                // Enhanced Moon Visualization with particle effects
                Container(
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Moon orbital particles
                      ...List.generate(8, (index) {
                        final angle = (index * pi * 2) / 8;
                        final radius = 80.0;
                        return AnimatedBuilder(
                          animation: _moonController,
                          builder: (context, child) {
                            final animatedAngle = angle + (_moonController.value * 2 * pi);
                            return Positioned(
                              left: MediaQuery.of(context).size.width / 2 - 8 + radius * cos(animatedAngle),
                              top: 110 - 8 + radius * sin(animatedAngle),
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: moonColor.withOpacity(0.6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: moonColor.withOpacity(0.4),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }),
                      
                      // Main moon visualization
                      _buildEnhancedMoonVisualization(),
                    ],
                  ),
                ),
                
                SizedBox(height: 20),

                // Enhanced Current Phase with animations
                AnimatedContainer(
                  duration: Duration(milliseconds: 800),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFF1A1A2E).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: moonColor.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: moonColor.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        currentMoonPhase,
                        style: TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: moonColor.withOpacity(0.6),
                              blurRadius: 5,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.brightness_1, color: moonColor, size: 16),
                          SizedBox(width: 8),
                          Text(
                            "Illumination: ${(moonIllumination * 100).toStringAsFixed(1)}%",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star_border, color: Colors.deepPurpleAccent, size: 16),
                          SizedBox(width: 8),
                          Text(
                            "Moon in $moonSign | Element: $moonElement",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 25),

                // Enhanced info cards with stagger animation
                _buildEnhancedInfoCard(
                  "Current Energy",
                  moonDescription,
                  Icons.auto_fix_high,
                  Colors.deepPurpleAccent,
                  0,
                ),

                _buildEnhancedInfoCard(
                  "Lunar Influence",
                  moonInfluence,
                  Icons.nightlight_round,
                  Colors.indigoAccent,
                  1,
                ),

                _buildEnhancedInfoCard(
                  "Moon in $moonSign",
                  _getMoonSignInfluence(moonSign)['influence']!,
                  Icons.star_border,
                  Colors.deepPurpleAccent,
                  2,
                ),

                _buildEnhancedAdviceList(
                  "Lunar Guidance",
                  moonAdvice,
                  Icons.lightbulb_outline,
                  Colors.amberAccent,
                  3,
                ),

                _buildEnhancedAdviceList(
                  "Recommended Rituals",
                  moonRituals,
                  Icons.auto_stories,
                  Colors.tealAccent,
                  4,
                ),

                SizedBox(height: 20),

                // Enhanced Moon Phase Calendar with animations
                _buildEnhancedPhaseCalendar(),

                SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedMoonVisualization() {
    return AnimatedBuilder(
      animation: _moonAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _moonAnimation.value,
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: moonColor,
                  boxShadow: [
                    BoxShadow(
                      color: moonColor.withOpacity(_glowAnimation.value),
                      blurRadius: 40,
                      spreadRadius: 15,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.4),
                      blurRadius: 60,
                      spreadRadius: 25,
                    ),
                    BoxShadow(
                      color: moonColor.withOpacity(0.6),
                      blurRadius: 80,
                      spreadRadius: 30,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    currentMoonPhase.split(' ')[0], // Just the emoji
                    style: TextStyle(
                      fontSize: 70,
                      shadows: [
                        Shadow(
                          color: Colors.white.withOpacity(0.8),
                          blurRadius: 10,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEnhancedInfoCard(String title, String content, IconData icon, Color color, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 600 + (index * 100)),
      curve: Curves.easeOutBack,
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A2E).withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedAdviceList(String title, List<String> items, IconData icon, Color color, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 600 + (index * 100)),
      curve: Curves.easeOutBack,
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A2E).withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...items.asMap().entries.map((entry) {
            final itemIndex = entry.key;
            final item = entry.value;
            return AnimatedContainer(
              duration: Duration(milliseconds: 400 + (itemIndex * 50)),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 6, right: 8),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.6),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildEnhancedPhaseCalendar() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 800),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A2E).withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(
                  'assets/icons/notes.png',
                  width: 24,
                  height: 24,
                  color: Colors.purpleAccent,
                ),
              ),
              SizedBox(width: 12),
              Text(
                "Upcoming Moon Phases",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.purpleAccent.withOpacity(0.5),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildEnhancedPhasePreview("🌑", "New Moon", "In 3 days", "New beginnings", 0),
          _buildEnhancedPhasePreview("🌓", "First Quarter", "In 10 days", "Decision time", 1),
          _buildEnhancedPhasePreview("🌕", "Full Moon", "In 17 days", "Peak energy", 2),
          _buildEnhancedPhasePreview("🌗", "Last Quarter", "In 24 days", "Release & reflect", 3),
        ],
      ),
    );
  }

  Widget _buildEnhancedPhasePreview(String emoji, String phase, String timing, String description, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutBack,
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF0D1117).withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.purpleAccent.withOpacity(0.1),
            ),
            child: Center(
              child: Text(
                emoji, 
                style: TextStyle(
                  fontSize: 24,
                  shadows: [
                    Shadow(
                      color: Colors.white.withOpacity(0.8),
                      blurRadius: 5,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phase,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purpleAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              timing,
              style: TextStyle(
                color: Colors.purpleAccent,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EnhancedCrystalHoroscopeTab extends StatefulWidget {
  final String? userId;
  final SupabaseClient? supabase;

  const EnhancedCrystalHoroscopeTab({
    super.key,
    this.userId,
    this.supabase,
  });

  @override
  _EnhancedCrystalHoroscopeTabState createState() => _EnhancedCrystalHoroscopeTabState();
}

class _EnhancedCrystalHoroscopeTabState extends State<EnhancedCrystalHoroscopeTab> {
  int _selectedIndex = 0;
  late RewardsManager _rewardsManager;
  int _coinBalance = 0;

  @override
  void initState() {
    super.initState();
    if (widget.supabase != null) {
      _rewardsManager = RewardsManager(widget.supabase!);
      _loadUserBalance();
    }
  }

  Future<void> _loadUserBalance() async {
    if (widget.userId != null) {
      try {
        final rewards = await _rewardsManager.getUserRewards(widget.userId!);
        setState(() {
          _coinBalance = rewards['coins'] ?? 0;
        });
      } catch (e) {
        debugPrint('Error loading user balance: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D1117),
      appBar: AppBar(
        title: Text(
          'Crystal Horoscope',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Color(0xFF1A1A2E),
        elevation: 0,
        centerTitle: true,
        actions: [
          if (widget.userId != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                  SizedBox(width: 4),
                  Text(
                    '$_coinBalance',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          EnhancedDailyHoroscopeTab(
            userId: widget.userId,
            supabase: widget.supabase,
            onCoinsUpdated: _loadUserBalance,
          ),
          WeeklyHoroscopeTab(
            userId: widget.userId,
            supabase: widget.supabase,
          ),
          MoonPhaseTrackingTab(
            userId: widget.userId,
            supabase: widget.supabase,
          ),
          AstronomicalEventsTab(),
          ZodiacCompatibilityTab(),
          CrystalGuidanceTab(),
          TarotNavigationTab(
            userId: widget.userId,
            supabase: widget.supabase,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.deepPurpleAccent,
          unselectedItemColor: Colors.white54,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
          items: [
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/icons/horoscope.png',
                width: 24,
                height: 24,
                color: _selectedIndex == 0 ? Colors.deepPurpleAccent : Colors.white54,
              ),
              label: 'Daily',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/icons/notes.png',
                width: 24,
                height: 24,
                color: _selectedIndex == 1 ? Colors.deepPurpleAccent : Colors.white54,
              ),
              label: 'Weekly',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/icons/heaven.png',
                width: 24,
                height: 24,
                color: _selectedIndex == 2 ? Colors.deepPurpleAccent : Colors.white54,
              ),
              label: 'Moon Phase',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/icons/void.png',
                width: 24,
                height: 24,
                color: _selectedIndex == 3 ? Colors.deepPurpleAccent : Colors.white54,
              ),
              label: 'Astro Events',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/icons/hearts.png',
                width: 24,
                height: 24,
                color: _selectedIndex == 4 ? Colors.deepPurpleAccent : Colors.white54,
              ),
              label: 'Compatibility',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/icons/crystal.png',
                width: 24,
                height: 24,
                color: _selectedIndex == 5 ? Colors.deepPurpleAccent : Colors.white54,
              ),
              label: 'Crystal Guide',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/icons/tarot.png',
                width: 24,
                height: 24,
                color: _selectedIndex == 6 ? Colors.deepPurpleAccent : Colors.white54,
              ),
              label: 'Tarot',
            ),
          ],
        ),
      ),
    );
  }
}

// Astronomical Events Tab - NEW FEATURE
class AstronomicalEventsTab extends StatefulWidget {
  @override
  _AstronomicalEventsTabState createState() => _AstronomicalEventsTabState();
}

class _AstronomicalEventsTabState extends State<AstronomicalEventsTab>
    with TickerProviderStateMixin {
  List<AstronomicalEvent> currentEvents = [];
  String currentMoonPhase = "";
  double moonIllumination = 0.0;
  String nextMajorEvent = "";
  late AnimationController _moonController;
  late AnimationController _starController;
  late Animation<double> _moonAnimation;
  late Animation<double> _starAnimation;

  @override
  void initState() {
    super.initState();
    
    _moonController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );
    
    _starController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    
    _moonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _moonController, curve: Curves.easeInOut),
    );
    
    _starAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _starController, curve: Curves.easeInOut),
    );
    
    _loadAstronomicalData();
    _moonController.repeat(reverse: true);
    _starController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _moonController.dispose();
    _starController.dispose();
    super.dispose();
  }

  void _loadAstronomicalData() {
    // Calculate current moon phase
    final now = DateTime.now();
    final moonPhaseData = _calculateMoonPhase(now);
    
    setState(() {
      currentMoonPhase = moonPhaseData['phase'];
      moonIllumination = moonPhaseData['illumination'];
      currentEvents = _generateCurrentEvents();
      nextMajorEvent = _getNextMajorEvent();
    });
  }

  Map<String, dynamic> _calculateMoonPhase(DateTime date) {
    // Simplified moon phase calculation
    final daysSinceNewMoon = (date.millisecondsSinceEpoch / (1000 * 60 * 60 * 24)) % 29.53;
    
    String phase;
    double illumination;
    
    if (daysSinceNewMoon < 1.84) {
      phase = "New Moon";
      illumination = 0.0;
    } else if (daysSinceNewMoon < 5.53) {
      phase = "Waxing Crescent";
      illumination = 0.25;
    } else if (daysSinceNewMoon < 9.22) {
      phase = "First Quarter";
      illumination = 0.5;
    } else if (daysSinceNewMoon < 12.91) {
      phase = "Waxing Gibbous";
      illumination = 0.75;
    } else if (daysSinceNewMoon < 16.61) {
      phase = "Full Moon";
      illumination = 1.0;
    } else if (daysSinceNewMoon < 20.30) {
      phase = "Waning Gibbous";
      illumination = 0.75;
    } else if (daysSinceNewMoon < 23.99) {
      phase = "Last Quarter";
      illumination = 0.5;
    } else {
      phase = "Waning Crescent";
      illumination = 0.25;
    }
    
    return {'phase': phase, 'illumination': illumination};
  }

  List<AstronomicalEvent> _generateCurrentEvents() {
    final Random random = Random();
    
    // Predefined astronomical events
    final eventTemplates = [
      AstronomicalEvent(
        name: "Mercury in Retrograde",
        description: "Communication and technology may be affected. Time for reflection and review.",
        date: DateTime.now().add(Duration(days: random.nextInt(30))),
        type: AstronomicalEventType.planetary,
        significance: "High",
        crystalRecommendation: "Clear Quartz for clarity",
      ),
      AstronomicalEvent(
        name: "Perseid Meteor Shower",
        description: "Peak viewing of one of the year's most spectacular meteor showers.",
        date: DateTime.now().add(Duration(days: random.nextInt(60))),
        type: AstronomicalEventType.meteorShower,
        significance: "Medium",
        crystalRecommendation: "Moldavite for cosmic connection",
      ),
      AstronomicalEvent(
        name: "Venus-Jupiter Conjunction",
        description: "A beautiful alignment bringing harmony and abundance energies.",
        date: DateTime.now().add(Duration(days: random.nextInt(90))),
        type: AstronomicalEventType.conjunction,
        significance: "High",
        crystalRecommendation: "Rose Quartz and Citrine combination",
      ),
      AstronomicalEvent(
        name: "Lunar Eclipse",
        description: "A powerful time for release and transformation. Emotions may run high.",
        date: DateTime.now().add(Duration(days: random.nextInt(120))),
        type: AstronomicalEventType.eclipse,
        significance: "Very High",
        crystalRecommendation: "Moonstone for lunar energy",
      ),
      AstronomicalEvent(
        name: "Saturn Return",
        description: "A major life cycle completion and new beginning period.",
        date: DateTime.now().add(Duration(days: random.nextInt(180))),
        type: AstronomicalEventType.planetary,
        significance: "Very High",
        crystalRecommendation: "Garnet for grounding and strength",
      ),
    ];
    
    // Select 2-4 random events
    final selectedEvents = eventTemplates..shuffle();
    return selectedEvents.take(3 + random.nextInt(2)).toList();
  }

  String _getNextMajorEvent() {
    if (currentEvents.isNotEmpty) {
      final nextEvent = currentEvents.first;
      final daysUntil = nextEvent.date.difference(DateTime.now()).inDays;
      return "${nextEvent.name} in $daysUntil days";
    }
    return "No major events in the near future";
  }

  String _getMoonPhaseEmoji() {
    switch (currentMoonPhase) {
      case "New Moon":
        return "🌑";
      case "Waxing Crescent":
        return "🌒";
      case "First Quarter":
        return "🌓";
      case "Waxing Gibbous":
        return "🌔";
      case "Full Moon":
        return "🌕";
      case "Waning Gibbous":
        return "🌖";
      case "Last Quarter":
        return "🌗";
      case "Waning Crescent":
        return "🌘";
      default:
        return "🌙";
    }
  }

  Color _getEventTypeColor(AstronomicalEventType type) {
    switch (type) {
      case AstronomicalEventType.planetary:
        return Colors.deepPurpleAccent;
      case AstronomicalEventType.lunar:
        return Colors.blueAccent;
      case AstronomicalEventType.eclipse:
        return Colors.redAccent;
      case AstronomicalEventType.meteorShower:
        return Colors.greenAccent;
      case AstronomicalEventType.conjunction:
        return Colors.orangeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0D1117),
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Title with animated stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _starAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_starAnimation.value * 0.3),
                      child: Text("✨", style: TextStyle(fontSize: 20)),
                    );
                  },
                ),
                SizedBox(width: 10),
                Text(
                  "Celestial Events",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 10),
                AnimatedBuilder(
                  animation: _starAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_starAnimation.value * 0.3),
                      child: Text("✨", style: TextStyle(fontSize: 20)),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 30),

            // Current Moon Phase Card
            Container(
              margin: EdgeInsets.only(bottom: 25),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A2E).withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.nightlight_round, color: Colors.blueAccent, size: 24),
                      SizedBox(width: 8),
                      Text(
                        "Current Moon Phase",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  AnimatedBuilder(
                    animation: _moonAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_moonAnimation.value * 0.1),
                        child: Text(
                          _getMoonPhaseEmoji(),
                          style: TextStyle(fontSize: 60),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 10),
                  Text(
                    currentMoonPhase,
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "${(moonIllumination * 100).toStringAsFixed(0)}% Illuminated",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // Next Major Event Card
            if (nextMajorEvent.isNotEmpty)
              Container(
                margin: EdgeInsets.only(bottom: 25),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF1A1A2E).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.amber, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Next Major Event",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            nextMajorEvent,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.amber,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Current Events List
            Text(
              "Upcoming Astronomical Events",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),

            ...currentEvents.map((event) => Container(
              margin: EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A2E).withOpacity(0.9),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _getEventTypeColor(event.type).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getEventTypeColor(event.type).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.type.toString().split('.').last.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: _getEventTypeColor(event.type),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Spacer(),
                      Text(
                        "${event.date.difference(DateTime.now()).inDays} days",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    event.name,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.diamond, color: Colors.tealAccent, size: 16),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.crystalRecommendation,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.tealAccent,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}

// Data models for astronomical events
class AstronomicalEvent {
  final String name;
  final String description;
  final DateTime date;
  final AstronomicalEventType type;
  final String significance;
  final String crystalRecommendation;

  AstronomicalEvent({
    required this.name,
    required this.description,
    required this.date,
    required this.type,
    required this.significance,
    required this.crystalRecommendation,
  });
}

enum AstronomicalEventType {
  planetary,
  lunar,
  eclipse,
  meteorShower,
  conjunction,
}

// Weekly Horoscope Tab - NEW FEATURE
class WeeklyHoroscopeTab extends StatefulWidget {
  final String? userId;
  final SupabaseClient? supabase;

  const WeeklyHoroscopeTab({
    super.key,
    this.userId,
    this.supabase,
  });

  @override
  _WeeklyHoroscopeTabState createState() => _WeeklyHoroscopeTabState();
}

class _WeeklyHoroscopeTabState extends State<WeeklyHoroscopeTab>
    with TickerProviderStateMixin {
  String? selectedZodiacSign;
  Map<String, String> weeklyForecast = {};
  List<DailyPrediction> weeklyPredictions = [];
  Map<String, dynamic> weeklyThemes = {};
  String personalizedMessage = "";
  bool isLoading = false;
  late AnimationController _cardController;
  late AnimationController _fadeController;
  late Animation<double> _cardAnimation;
  late Animation<double> _fadeAnimation;

  final List<String> zodiacSigns = [
    "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
    "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"
  ];

  final Map<String, String> signEmojis = {
    "Aries": "♈", "Taurus": "♉", "Gemini": "♊", "Cancer": "♋",
    "Leo": "♌", "Virgo": "♍", "Libra": "♎", "Scorpio": "♏",
    "Sagittarius": "♐", "Capricorn": "♑", "Aquarius": "♒", "Pisces": "♓"
  };

  final Map<String, Color> signColors = {
    "Aries": Colors.redAccent,
    "Taurus": Colors.green,
    "Gemini": Colors.yellowAccent,
    "Cancer": Colors.blueAccent,
    "Leo": Colors.orangeAccent,
    "Virgo": Colors.brown,
    "Libra": Colors.pinkAccent,
    "Scorpio": Colors.deepPurpleAccent,
    "Sagittarius": Colors.purple,
    "Capricorn": Colors.grey,
    "Aquarius": Colors.cyanAccent,
    "Pisces": Colors.tealAccent,
  };

  @override
  void initState() {
    super.initState();
    
    _cardController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _loadUserZodiacSign();
  }

  @override
  void dispose() {
    _cardController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserZodiacSign() async {
    if (widget.userId != null && widget.supabase != null) {
      try {
        // Try to load user's zodiac sign from profile
        final response = await widget.supabase!
            .from('profiles')
            .select('zodiac_sign')
            .eq('id', widget.userId!)
            .single();
        
        if (response['zodiac_sign'] != null) {
          setState(() {
            selectedZodiacSign = response['zodiac_sign'];
          });
          _generateWeeklyForecast();
        }
      } catch (e) {
        debugPrint('Error loading user zodiac sign: $e');
        // If no zodiac sign is stored, user will need to select one
      }
    }
  }

  Future<void> _saveUserZodiacSign(String sign) async {
    if (widget.userId != null && widget.supabase != null) {
      try {
        await widget.supabase!
            .from('profiles')
            .upsert({'id': widget.userId!, 'zodiac_sign': sign});
      } catch (e) {
        print('Error saving user zodiac sign: $e');
      }
    }
  }

  void _generateWeeklyForecast() {
    if (selectedZodiacSign == null) return;
    
    setState(() {
      isLoading = true;
    });
    
    _cardController.reset();
    _fadeController.reset();
    
    Future.delayed(Duration(milliseconds: 500), () {
      final forecasts = _getWeeklyForecasts();
      final predictions = _generateDailyPredictions();
      final themes = _getWeeklyThemes();
      final message = _getPersonalizedMessage();
      
      setState(() {
        weeklyForecast = forecasts;
        weeklyPredictions = predictions;
        weeklyThemes = themes;
        personalizedMessage = message;
        isLoading = false;
      });
      
      _cardController.forward();
      _fadeController.forward();
    });
  }

  Map<String, String> _getWeeklyForecasts() {
    final forecasts = {
      "Aries": {
        "overview": "A week of dynamic energy and new beginnings awaits you. Your natural leadership qualities will shine through challenging situations.",
        "love": "Venus brings romantic opportunities mid-week. Single Aries may encounter someone special through work or social circles.",
        "career": "Mars energizes your professional sector. Take initiative on projects that have been stalling. Tuesday is especially favorable for presentations.",
        "health": "High energy levels throughout the week. Channel your vitality into physical activities. Watch for minor stress-related headaches on Thursday.",
        "finance": "Investment opportunities arise Wednesday. Trust your instincts but seek advice from trusted sources before major decisions."
      },
      "Taurus": {
        "overview": "Stability and growth characterize this week. Your patient approach to challenges will yield significant rewards by weekend.",
        "love": "Earth energy supports committed relationships. Plan a special evening with your partner. Focus on emotional security and comfort.",
        "career": "Steady progress in ongoing projects. Your reliability impresses superiors. Friday brings recognition for past efforts and dedication.",
        "health": "Maintain consistent routines. Your body craves nourishing foods and regular sleep patterns. Gentle yoga supports your wellbeing.",
        "finance": "Practical financial decisions favor long-term security. Review investments and savings plans. Avoid impulsive purchases mid-week."
      },
      "Gemini": {
        "overview": "Communication and learning take center stage. Your curiosity leads to exciting discoveries and meaningful connections this week.",
        "love": "Mercury enhances romantic conversations. Express your feelings openly. Social gatherings bring potential romantic encounters.",
        "career": "Networking proves invaluable. Your ideas gain traction through collaborative efforts. Wednesday favors important meetings and negotiations.",
        "health": "Mental stimulation energizes you. Balance screen time with nature walks. Stay hydrated and maintain regular meal schedules.",
        "finance": "Multiple income streams show promise. Research new opportunities but avoid spreading resources too thin. Seek expert advice."
      },
      "Cancer": {
        "overview": "Emotional intuition guides you toward nurturing opportunities. Home and family matters receive positive cosmic support this week.",
        "love": "Moon phases favor deep emotional connections. Cooking together or home-based activities strengthen relationships with loved ones.",
        "career": "Your empathetic nature resolves workplace conflicts. Leadership recognizes your team-building skills. Trust your professional instincts.",
        "health": "Listen to your body's needs. Emotional eating patterns may surface. Focus on comfort foods that truly nourish your soul.",
        "finance": "Home-related investments show promise. Family financial discussions yield positive outcomes. Save for future security needs."
      },
      "Leo": {
        "overview": "Your natural charisma attracts opportunities and admiration. Creative projects flourish under favorable stellar influences this week.",
        "love": "Sun energy illuminates your romantic sector. Grand gestures and heartfelt expressions strengthen bonds. Confidence attracts love.",
        "career": "Leadership opportunities emerge unexpectedly. Your creative solutions impress decision-makers. Thursday brings exciting project proposals.",
        "health": "Vitality peaks mid-week. Engage in activities that bring joy and laughter. Regular exercise supports your radiant energy levels.",
        "finance": "Luxury purchases tempt you. Balance desires with practical needs. Investments in personal development pay long-term dividends."
      },
      "Virgo": {
        "overview": "Attention to detail and methodical planning lead to significant accomplishments. Your analytical skills solve complex problems effortlessly.",
        "love": "Practical expressions of love resonate deeply. Small, thoughtful gestures create lasting impact. Focus on quality over quantity.",
        "career": "Organization and efficiency earn recognition. Your problem-solving abilities are in high demand. Monday brings important deadlines.",
        "health": "Stress management requires attention. Create detailed wellness schedules. Digestive health benefits from mindful eating practices.",
        "finance": "Budget analysis reveals optimization opportunities. Your methodical approach to finances yields steady growth and security."
      },
      "Libra": {
        "overview": "Balance and harmony influence all life areas. Diplomatic skills help resolve conflicts and create peaceful, productive environments.",
        "love": "Venus blesses partnerships with grace and beauty. Aesthetic experiences shared with loved ones deepen emotional connections significantly.",
        "career": "Collaboration and teamwork flourish. Your diplomatic nature resolves tensions. Partnership opportunities arise through professional networks.",
        "health": "Seek balance in all wellness aspects. Beauty treatments and aesthetic pleasures support emotional wellbeing and self-confidence.",
        "finance": "Joint financial ventures show promise. Partnership investments require careful consideration. Seek win-win financial arrangements."
      },
      "Scorpio": {
        "overview": "Transformation and renewal characterize this powerful week. Hidden truths surface, leading to profound personal and professional insights.",
        "love": "Intense emotions create deeper intimacy. Honest conversations transform relationships. Passion and mystery heighten romantic attraction significantly.",
        "career": "Research and investigation reveal important information. Your intuitive insights guide strategic decisions. Trust your professional instincts completely.",
        "health": "Emotional healing supports physical wellness. Address underlying stress patterns. Detoxification and renewal practices prove beneficial.",
        "finance": "Investment research yields valuable insights. Hidden opportunities emerge through careful analysis. Avoid impulsive financial decisions."
      },
      "Sagittarius": {
        "overview": "Adventure and expansion beckon from multiple directions. Your optimistic outlook attracts opportunities for growth and learning experiences.",
        "love": "Foreign connections or long-distance relationships feature prominently. Adventure shared with partners strengthens bonds through novel experiences.",
        "career": "International opportunities or higher education advancements emerge. Your philosophical approach inspires colleagues and superiors alike.",
        "health": "Outdoor activities and travel support wellbeing. Vary exercise routines to prevent boredom. Maintain flexibility in health approaches.",
        "finance": "International investments or education funding requires attention. Long-term growth potential exceeds short-term gains. Research thoroughly."
      },
      "Capricorn": {
        "overview": "Ambition and determination drive significant achievements. Your practical approach to goals yields concrete, measurable results this productive week.",
        "love": "Commitment and responsibility strengthen relationships. Traditional romantic gestures resonate deeply. Plan for shared future goals together.",
        "career": "Authority and recognition come through persistent effort. Your reputation for reliability opens new doors. Saturday brings advancement opportunities.",
        "health": "Structured wellness routines support long-term vitality. Joint health requires attention. Consistency in health habits pays dividends.",
        "finance": "Conservative investments prove wise. Your disciplined approach to money management yields steady growth. Avoid speculative ventures."
      },
      "Aquarius": {
        "overview": "Innovation and humanitarian concerns capture your attention. Unique solutions to collective problems earn recognition and support from others.",
        "love": "Friendship forms the foundation of romantic connections. Unconventional relationship approaches work surprisingly well. Embrace authentic expression.",
        "career": "Technology and group projects flourish. Your innovative ideas revolutionize traditional processes. Tuesday favors team-based initiatives.",
        "health": "Group fitness activities or alternative wellness practices appeal. Experiment with new health technologies. Maintain social wellness connections.",
        "finance": "Cryptocurrency or technology investments show potential. Group investment opportunities arise. Balance innovation with practical considerations."
      },
      "Pisces": {
        "overview": "Intuition and creativity flow abundantly. Your compassionate nature attracts opportunities to help others while advancing personal spiritual growth.",
        "love": "Romantic idealism and fantasy enhance relationships. Artistic or spiritual activities shared with partners deepen emotional and soul connections.",
        "career": "Creative projects gain momentum and recognition. Your empathetic leadership style inspires teams. Trust intuitive insights about workplace dynamics.",
        "health": "Water activities and meditation support wellness. Emotional health requires gentle attention. Artistic expression aids healing and personal growth.",
        "finance": "Intuitive investments require careful research. Charitable giving or artistic investments appeal. Balance generosity with practical financial needs."
      }
    };
    
    return forecasts[selectedZodiacSign!] ?? forecasts["Aries"]!;
  }

  List<DailyPrediction> _generateDailyPredictions() {
    final random = Random();
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final predictions = <DailyPrediction>[];
    
    final energyLevels = ['High', 'Medium', 'Low', 'Very High'];
    final luckLevels = ['Excellent', 'Good', 'Fair', 'Outstanding'];
    final focuses = ['Career', 'Love', 'Health', 'Finance', 'Creativity', 'Family', 'Spirituality'];
    
    for (int i = 0; i < 7; i++) {
      predictions.add(DailyPrediction(
        day: days[i],
        energy: energyLevels[random.nextInt(energyLevels.length)],
        luck: luckLevels[random.nextInt(luckLevels.length)],
        focus: focuses[random.nextInt(focuses.length)],
        luckyNumber: random.nextInt(30) + 1,
        luckyColor: _getRandomColor(),
        tip: _getDailyTip(days[i], selectedZodiacSign!),
      ));
    }
    
    return predictions;
  }

  String _getRandomColor() {
    final colors = ['Purple', 'Blue', 'Green', 'Red', 'Gold', 'Silver', 'Pink', 'Orange'];
    return colors[Random().nextInt(colors.length)];
  }

  String _getDailyTip(String day, String sign) {
    final tips = {
      'Monday': [
        'Start the week with clear intentions',
        'Morning meditation sets positive energy',
        'Wear your lucky colors for confidence',
        'Connect with earth energy through grounding'
      ],
      'Tuesday': [
        'Mars energy favors bold actions',
        'Assert yourself in important matters',
        'Physical exercise boosts vitality',
        'Red crystals enhance courage'
      ],
      'Wednesday': [
        'Mercury supports clear communication',
        'Important conversations flow smoothly',
        'Learning opportunities present themselves',
        'Yellow enhances mental clarity'
      ],
      'Thursday': [
        'Jupiter expands opportunities',
        'Generosity returns tenfold',
        'Seek wisdom from mentors',
        'Purple connects to higher wisdom'
      ],
      'Friday': [
        'Venus blesses love and beauty',
        'Artistic pursuits flourish',
        'Social connections strengthen',
        'Green harmonizes relationships'
      ],
      'Saturday': [
        'Saturn rewards patient effort',
        'Complete unfinished projects',
        'Practical matters need attention',
        'Blue promotes focus and discipline'
      ],
      'Sunday': [
        'Solar energy recharges your spirit',
        'Family time brings joy',
        'Reflect on weekly achievements',
        'Gold amplifies personal power'
      ]
    };
    
    final dayTips = tips[day]!;
    return dayTips[Random().nextInt(dayTips.length)];
  }

  Map<String, dynamic> _getWeeklyThemes() {
    final themes = {
      'primaryTheme': 'Cosmic Alignment and Personal Growth',
      'secondaryTheme': 'Relationship Harmony and Communication',
      'weeklyKeywords': ['Transformation', 'Abundance', 'Clarity', 'Connection'],
      'spiritualGuidance': 'Trust the cosmic timing of your life. The universe is aligning events for your highest good.',
      'weeklyAffirmation': 'I am open to receiving all the good that the universe has in store for me this week.',
      'crystalOfTheWeek': _getWeeklyCrystal(selectedZodiacSign!),
      'planetaryInfluence': _getPlanetaryInfluence(selectedZodiacSign!),
    };
    
    return themes;
  }

  String _getWeeklyCrystal(String sign) {
    final crystals = {
      'Aries': 'Carnelian - ignites passion and courage',
      'Taurus': 'Rose Quartz - enhances love and stability',
      'Gemini': 'Citrine - stimulates communication and clarity',
      'Cancer': 'Moonstone - amplifies intuition and emotional healing',
      'Leo': 'Sunstone - radiates confidence and personal power',
      'Virgo': 'Amazonite - promotes organization and healing',
      'Libra': 'Prehnite - balances heart and mind energies',
      'Scorpio': 'Obsidian - provides protection and transformation',
      'Sagittarius': 'Turquoise - expands wisdom and adventure',
      'Capricorn': 'Garnet - grounds ambition and manifests goals',
      'Aquarius': 'Amethyst - enhances innovation and spiritual insight',
      'Pisces': 'Aquamarine - deepens intuition and emotional flow'
    };
    
    return crystals[sign] ?? crystals['Aries']!;
  }

  String _getPlanetaryInfluence(String sign) {
    final influences = {
      'Aries': 'Mars brings dynamic energy and leadership opportunities',
      'Taurus': 'Venus enhances beauty, love, and material abundance',
      'Gemini': 'Mercury accelerates communication and learning',
      'Cancer': 'Moon deepens emotional connections and intuition',
      'Leo': 'Sun radiates confidence and creative expression',
      'Virgo': 'Mercury sharpens analytical skills and organization',
      'Libra': 'Venus harmonizes relationships and artistic pursuits',
      'Scorpio': 'Pluto transforms through depth and regeneration',
      'Sagittarius': 'Jupiter expands horizons and philosophical understanding',
      'Capricorn': 'Saturn structures goals and long-term achievements',
      'Aquarius': 'Uranus innovates through unique perspectives and technology',
      'Pisces': 'Neptune inspires through dreams and spiritual connection'
    };
    
    return influences[sign] ?? influences['Aries']!;
  }

  String _getPersonalizedMessage() {
    final messages = {
      'Aries': 'Your pioneering spirit leads you toward exciting new territories this week. Trust your instincts and take calculated risks.',
      'Taurus': 'Steady progress and patient nurturing of your goals will yield beautiful results. Your persistence is your greatest strength.',
      'Gemini': 'Your gift for communication opens doors and hearts this week. Share your ideas freely and connect with like-minded souls.',
      'Cancer': 'Your emotional wisdom guides you toward nurturing opportunities. Trust your intuitive insights about people and situations.',
      'Leo': 'Your natural magnetism attracts abundance and admiration. Shine your light brightly and inspire others with your confidence.',
      'Virgo': 'Your attention to detail and practical wisdom solve complex challenges. Your methodical approach yields perfect results.',
      'Libra': 'Your diplomatic nature creates harmony in chaos. Balance is your superpower, and others seek your peaceful guidance.',
      'Scorpio': 'Your transformative power turns challenges into triumphs. Embrace change as your pathway to profound personal growth.',
      'Sagittarius': 'Your adventurous spirit discovers new horizons and possibilities. Your optimism is contagious and opens unexpected doors.',
      'Capricorn': 'Your disciplined approach to goals attracts recognition and advancement. Your reputation for reliability precedes you.',
      'Aquarius': 'Your innovative thinking revolutionizes traditional approaches. Your unique perspective offers solutions others cannot see.',
      'Pisces': 'Your compassionate heart and creative soul inspire healing and beauty. Your intuitive gifts guide you toward meaningful purpose.'
    };
    
    return messages[selectedZodiacSign!] ?? messages['Aries']!;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0D1117),
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Title
            Text(
              "Weekly Horoscope",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),

            // Zodiac Sign Selector
            Container(
              margin: EdgeInsets.only(bottom: 25),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A2E).withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selectedZodiacSign != null 
                    ? signColors[selectedZodiacSign]!.withOpacity(0.5)
                    : Colors.deepPurpleAccent.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: selectedZodiacSign != null 
                      ? signColors[selectedZodiacSign]!.withOpacity(0.2)
                      : Colors.deepPurpleAccent.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        "Your Zodiac Sign",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedZodiacSign,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFF0D1117),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      hintText: "Select your zodiac sign",
                      hintStyle: TextStyle(color: Colors.white54),
                    ),
                    dropdownColor: Color(0xFF1A1A2E),
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    items: zodiacSigns.map((sign) => DropdownMenuItem(
                      value: sign,
                      child: Row(
                        children: [
                          Text(signEmojis[sign]!, style: TextStyle(fontSize: 24)),
                          SizedBox(width: 12),
                          Text(sign, style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedZodiacSign = value;
                      });
                      if (value != null) {
                        _saveUserZodiacSign(value);
                        _generateWeeklyForecast();
                      }
                    },
                  ),
                ],
              ),
            ),

            // Loading indicator
            if (isLoading)
              Container(
                padding: EdgeInsets.all(40),
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Consulting the stars...",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

            // Weekly forecast content
            if (selectedZodiacSign != null && !isLoading && weeklyForecast.isNotEmpty) ...[
              // Personalized message
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 25),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Color(0xFF1A1A2E).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: signColors[selectedZodiacSign]!.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: signColors[selectedZodiacSign]!.withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                signEmojis[selectedZodiacSign]!,
                                style: TextStyle(fontSize: 30),
                              ),
                              SizedBox(width: 10),
                              Text(
                                selectedZodiacSign!,
                                style: TextStyle(
                                  fontSize: 22,
                                  color: signColors[selectedZodiacSign],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 15),
                          Text(
                            personalizedMessage,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              height: 1.5,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Weekly themes
              if (weeklyThemes.isNotEmpty)
                AnimatedBuilder(
                  animation: _cardAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _cardAnimation.value,
                      child: Container(
                        margin: EdgeInsets.only(bottom: 25),
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Color(0xFF1A1A2E).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.auto_awesome, color: Colors.deepPurpleAccent, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  "Weekly Themes",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 15),
                            _buildThemeItem("Crystal of the Week", weeklyThemes['crystalOfTheWeek'], Icons.diamond),
                            _buildThemeItem("Planetary Influence", weeklyThemes['planetaryInfluence'], Icons.public),
                            _buildThemeItem("Spiritual Guidance", weeklyThemes['spiritualGuidance'], Icons.self_improvement),
                            Container(
                              margin: EdgeInsets.only(top: 15),
                              padding: EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.deepPurpleAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Weekly Affirmation",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.deepPurpleAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    weeklyThemes['weeklyAffirmation'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontStyle: FontStyle.italic,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              // Daily predictions
              Text(
                "Daily Predictions",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),

              ...weeklyPredictions.map((prediction) => AnimatedBuilder(
                animation: _cardAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _cardAnimation.value,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF1A1A2E).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: signColors[selectedZodiacSign]!.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                prediction.day,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: signColors[selectedZodiacSign],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: signColors[selectedZodiacSign]!.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Lucky #${prediction.luckyNumber}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: signColors[selectedZodiacSign],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildPredictionDetail("Energy", prediction.energy, Icons.battery_charging_full),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _buildPredictionDetail("Luck", prediction.luck, Icons.star),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildPredictionDetail("Focus", prediction.focus, Icons.center_focus_strong),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _buildPredictionDetail("Color", prediction.luckyColor, Icons.palette),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.lightbulb, color: Colors.amber, size: 16),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    prediction.tip,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )).toList(),

              // Weekly forecast sections
              ...weeklyForecast.entries.map((entry) => AnimatedBuilder(
                animation: _cardAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _cardAnimation.value,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Color(0xFF1A1A2E).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: _getSectionColor(entry.key).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(_getSectionIcon(entry.key), color: _getSectionColor(entry.key), size: 24),
                              SizedBox(width: 8),
                              Text(
                                entry.key.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _getSectionColor(entry.key),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThemeItem(String title, String content, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.deepPurpleAccent, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.deepPurpleAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionDetail(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSectionColor(String section) {
    switch (section.toLowerCase()) {
      case 'overview':
        return Colors.deepPurpleAccent;
      case 'love':
        return Colors.pinkAccent;
      case 'career':
        return Colors.blueAccent;
      case 'health':
        return Colors.greenAccent;
      case 'finance':
        return Colors.amber;
      default:
        return Colors.white70;
    }
  }

  IconData _getSectionIcon(String section) {
    switch (section.toLowerCase()) {
      case 'overview':
        return Icons.auto_awesome;
      case 'love':
        return Icons.favorite;
      case 'career':
        return Icons.work;
      case 'health':
        return Icons.health_and_safety;
      case 'finance':
        return Icons.monetization_on;
      default:
        return Icons.star;
    }
  }
}

// Data model for daily predictions
class DailyPrediction {
  final String day;
  final String energy;
  final String luck;
  final String focus;
  final int luckyNumber;
  final String luckyColor;
  final String tip;

  DailyPrediction({
    required this.day,
    required this.energy,
    required this.luck,
    required this.focus,
    required this.luckyNumber,
    required this.luckyColor,
    required this.tip,
  });
}

// Enhanced Daily Horoscope Tab
class EnhancedDailyHoroscopeTab extends StatefulWidget {
  final String? userId;
  final SupabaseClient? supabase;
  final VoidCallback? onCoinsUpdated;

  const EnhancedDailyHoroscopeTab({
    super.key,
    this.userId,
    this.supabase,
    this.onCoinsUpdated,
  });

  @override
  _EnhancedDailyHoroscopeTabState createState() => _EnhancedDailyHoroscopeTabState();
}

class _EnhancedDailyHoroscopeTabState extends State<EnhancedDailyHoroscopeTab>
    with TickerProviderStateMixin {
  // Dynamic content generation instead of JSON loading
  String? selectedZodiacSign;
  Map<String, dynamic> dailyReading = {};
  String horoscopeMessage = "Loading your cosmic guidance...";
  String luckyEmoji = "✨";
  String luckyNumber = "7";
  String todaysCrystal = "Amethyst";
  String todaysColor = "Purple";
  String energyLevel = "High";
  String weeklyTheme = "Transformation";
  List<String> dailyAdvice = [];
  Color backgroundColor = Colors.purple.shade100;
  bool _hasReceivedDailyBlessing = false;
  int _streakCount = 0;
  late RewardsManager _rewardsManager;

  // Enhanced astronomical influence
  String astronomicalInfluence = "";
  
  final List<String> zodiacSigns = [
    "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
    "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"
  ];

  final Map<String, String> signEmojis = {
    "Aries": "♈", "Taurus": "♉", "Gemini": "♊", "Cancer": "♋",
    "Leo": "♌", "Virgo": "♍", "Libra": "♎", "Scorpio": "♏",
    "Sagittarius": "♐", "Capricorn": "♑", "Aquarius": "♒", "Pisces": "♓"
  };

  AnimationController? fadeController;
  AnimationController? emojiController;
  AnimationController? textController;
  AnimationController? crystalController;

  @override
  void initState() {
    super.initState();
    
    if (widget.supabase != null) {
      _rewardsManager = RewardsManager(widget.supabase!);
    }
    
    // Initialize animation controllers
    fadeController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    emojiController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    textController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    crystalController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
    
    _loadDailyData();
    _checkDailyBlessingStatus();
    _loadAstronomicalInfluence();
    _loadUserZodiacSign();
  }

  @override
  void dispose() {
    fadeController?.dispose();
    emojiController?.dispose();
    textController?.dispose();
    crystalController?.dispose();
    super.dispose();
  }

  Future<void> _loadUserZodiacSign() async {
    if (widget.userId != null && widget.supabase != null) {
      try {
        // Try to load user's zodiac sign from profile
        final response = await widget.supabase!
            .from('profiles')
            .select('zodiac_sign')
            .eq('id', widget.userId!)
            .single();
        
        if (response['zodiac_sign'] != null) {
          setState(() {
            selectedZodiacSign = response['zodiac_sign'];
          });
          _generateDailyReading();
        }
      } catch (e) {
        debugPrint('Error loading user zodiac sign: $e');
        // If no zodiac sign is stored, user will need to select one
      }
    }
  }

  Future<void> _saveUserZodiacSign(String sign) async {
    if (widget.userId != null && widget.supabase != null) {
      try {
        await widget.supabase!
            .from('profiles')
            .upsert({'id': widget.userId!, 'zodiac_sign': sign});
      } catch (e) {
        print('Error saving user zodiac sign: $e');
      }
    }
  }

  Future<void> _loadDailyData() async {
    setState(() {
      backgroundColor = _generateRandomPastelColor();
    });
    
    if (selectedZodiacSign != null) {
      _generateDailyReading();
    }
  }

  void _generateDailyReading() {
    if (selectedZodiacSign == null) return;
    
    final reading = _generateZodiacDailyReading(selectedZodiacSign!);
    
    setState(() {
      dailyReading = reading;
      horoscopeMessage = reading['message'];
      luckyEmoji = reading['luckyEmoji'];
      luckyNumber = reading['luckyNumber'].toString();
      todaysCrystal = reading['crystal'];
      todaysColor = reading['color'];
      energyLevel = reading['energy'];
      weeklyTheme = reading['theme'];
      dailyAdvice = List<String>.from(reading['advice']);
      backgroundColor = _generateRandomPastelColor();
    });
  }

  Map<String, dynamic> _generateZodiacDailyReading(String zodiacSign) {
    final now = DateTime.now();
    
    // Generate user-specific seed for individual daily readings
    // Combines date, zodiac sign, and user ID for unique personalization
    final userHash = widget.userId?.hashCode ?? 'guest_user'.hashCode;
    final dateSeed = now.day + now.month * 31 + now.year * 365;
    final seed = dateSeed + zodiacSign.hashCode + userHash;
    final personalRandom = Random(seed);
    
    final zodiacData = _getZodiacSignData(zodiacSign);
    final dailyThemes = _getDailyThemes();
    final crystalData = _getCrystalRecommendations();
    final colorData = _getLuckyColors();
    
    // Generate personalized daily reading unique to each user
    final theme = dailyThemes[personalRandom.nextInt(dailyThemes.length)];
    final message = _generatePersonalizedMessage(zodiacSign, theme, personalRandom);
    final crystal = crystalData[zodiacSign]![personalRandom.nextInt(crystalData[zodiacSign]!.length)];
    final color = colorData[personalRandom.nextInt(colorData.length)];
    
    return {
      'message': message,
      'luckyEmoji': zodiacData['emoji'],
      'luckyNumber': personalRandom.nextInt(31) + 1,
      'crystal': crystal,
      'color': color,
      'energy': _getEnergyLevel(zodiacSign, personalRandom),
      'theme': theme,
      'advice': _generateDailyAdvice(zodiacSign, theme, personalRandom),
      'compatibility': _getDailyCompatibility(zodiacSign, personalRandom),
      'affirmation': _generateDailyAffirmation(zodiacSign, personalRandom),
      'personalElement': _getPersonalElement(zodiacSign, personalRandom),
      'lifePhase': _getCurrentLifePhase(personalRandom),
      'cosmicNumber': _getCosmicNumber(personalRandom),
    };
  }

  Map<String, dynamic> _getZodiacSignData(String sign) {
    final zodiacData = {
      'Aries': {
        'emoji': '♈',
        'element': 'Fire',
        'planet': 'Mars',
        'traits': ['pioneering', 'energetic', 'courageous', 'determined'],
        'colors': ['Red', 'Orange', 'Yellow']
      },
      'Taurus': {
        'emoji': '♉',
        'element': 'Earth',
        'planet': 'Venus',
        'traits': ['reliable', 'patient', 'practical', 'devoted'],
        'colors': ['Green', 'Pink', 'Earth tones']
      },
      'Gemini': {
        'emoji': '♊',
        'element': 'Air',
        'planet': 'Mercury',
        'traits': ['versatile', 'curious', 'communicative', 'witty'],
        'colors': ['Yellow', 'Silver', 'Light Blue']
      },
      'Cancer': {
        'emoji': '♋',
        'element': 'Water',
        'planet': 'Moon',
        'traits': ['nurturing', 'intuitive', 'protective', 'emotional'],
        'colors': ['Silver', 'White', 'Sea Blue']
      },
      'Leo': {
        'emoji': '♌',
        'element': 'Fire',
        'planet': 'Sun',
        'traits': ['confident', 'generous', 'creative', 'dramatic'],
        'colors': ['Gold', 'Orange', 'Bright Yellow']
      },
      'Virgo': {
        'emoji': '♍',
        'element': 'Earth',
        'planet': 'Mercury',
        'traits': ['analytical', 'helpful', 'precise', 'reliable'],
        'colors': ['Navy Blue', 'Grey', 'Brown']
      },
      'Libra': {
        'emoji': '♎',
        'element': 'Air',
        'planet': 'Venus',
        'traits': ['diplomatic', 'fair', 'social', 'peaceful'],
        'colors': ['Pink', 'Light Blue', 'Lavender']
      },
      'Scorpio': {
        'emoji': '♏',
        'element': 'Water',
        'planet': 'Pluto',
        'traits': ['intense', 'passionate', 'mysterious', 'transformative'],
        'colors': ['Deep Red', 'Black', 'Maroon']
      },
      'Sagittarius': {
        'emoji': '♐',
        'element': 'Fire',
        'planet': 'Jupiter',
        'traits': ['adventurous', 'optimistic', 'philosophical', 'freedom-loving'],
        'colors': ['Purple', 'Turquoise', 'Light Blue']
      },
      'Capricorn': {
        'emoji': '♑',
        'element': 'Earth',
        'planet': 'Saturn',
        'traits': ['ambitious', 'disciplined', 'practical', 'responsible'],
        'colors': ['Black', 'Brown', 'Dark Green']
      },
      'Aquarius': {
        'emoji': '♒',
        'element': 'Air',
        'planet': 'Uranus',
        'traits': ['innovative', 'independent', 'humanitarian', 'eccentric'],
        'colors': ['Electric Blue', 'Silver', 'Turquoise']
      },
      'Pisces': {
        'emoji': '♓',
        'element': 'Water',
        'planet': 'Neptune',
        'traits': ['intuitive', 'compassionate', 'artistic', 'dreamy'],
        'colors': ['Sea Green', 'Lavender', 'Aqua']
      },
    };
    
    return zodiacData[sign] ?? zodiacData['Aries']!;
  }

  List<String> _getDailyThemes() {
    return [
      'Love and Relationships',
      'Career and Success',
      'Health and Wellness',
      'Spiritual Growth',
      'Financial Abundance',
      'Creative Expression',
      'Family Harmony',
      'Personal Transformation',
      'Adventure and Travel',
      'Learning and Wisdom',
      'Communication and Connection',
      'Inner Peace and Balance',
    ];
  }

  Map<String, List<String>> _getCrystalRecommendations() {
    return {
      'Aries': ['Carnelian', 'Red Jasper', 'Bloodstone', 'Diamond'],
      'Taurus': ['Rose Quartz', 'Emerald', 'Malachite', 'Selenite'],
      'Gemini': ['Citrine', 'Agate', 'Chrysocolla', 'Howlite'],
      'Cancer': ['Moonstone', 'Pearl', 'Labradorite', 'Amazonite'],
      'Leo': ['Sunstone', 'Citrine', 'Pyrite', 'Tiger Eye'],
      'Virgo': ['Amazonite', 'Moss Agate', 'Sodalite', 'Fluorite'],
      'Libra': ['Prehnite', 'Lepidolite', 'Tourmaline', 'Opal'],
      'Scorpio': ['Obsidian', 'Garnet', 'Malachite', 'Topaz'],
      'Sagittarius': ['Turquoise', 'Lapis Lazuli', 'Sodalite', 'Amethyst'],
      'Capricorn': ['Garnet', 'Onyx', 'Jet', 'Magnetite'],
      'Aquarius': ['Amethyst', 'Aquamarine', 'Fluorite', 'Labradorite'],
      'Pisces': ['Aquamarine', 'Amethyst', 'Fluorite', 'Moonstone'],
    };
  }

  List<String> _getLuckyColors() {
    return [
      'Cosmic Purple', 'Mystic Blue', 'Enchanted Gold', 'Sacred Silver',
      'Divine White', 'Healing Green', 'Passionate Red', 'Spiritual Indigo',
      'Peaceful Turquoise', 'Loving Pink', 'Wise Violet', 'Energetic Orange'
    ];
  }

  String _generatePersonalizedMessage(String zodiacSign, String theme, Random random) {
    final messageTemplates = _getMessageTemplates();
    final signData = _getZodiacSignData(zodiacSign);
    final traits = signData['traits'] as List<String>;
    
    // Get theme-specific templates
    final templates = messageTemplates[theme]!;
    final template = templates[random.nextInt(templates.length)];
    final trait = traits[random.nextInt(traits.length)];
    
    // Add personal elements for uniqueness
    final personalElement = _getPersonalElement(zodiacSign, random);
    final lifePhase = _getCurrentLifePhase(random);
    
    return template
        .replaceAll('{sign}', zodiacSign)
        .replaceAll('{trait}', trait)
        .replaceAll('{element}', signData['element'])
        .replaceAll('{planet}', signData['planet'])
        .replaceAll('{personalElement}', personalElement)
        .replaceAll('{lifePhase}', lifePhase);
  }

  Map<String, List<String>> _getMessageTemplates() {
    return {
      'Love and Relationships': [
        'Your {trait} nature attracts deep connections today, dear {sign}. Venus smiles upon your romantic endeavors.',
        'The cosmic energy of {planet} enhances your ability to express love authentically. Your heart chakra glows with {element} energy.',
        'Relationships flourish under today\'s stellar influence. Your {trait} spirit creates harmony in all connections.',
        'Love flows to you naturally today, {sign}. Your {element} energy magnetizes soulful partnerships.',
        'In this {lifePhase} phase, your {trait} heart opens to new romantic possibilities. {personalElement} guides your choices.',
        'The universe aligns hearts today through your {trait} authenticity. Your {element} nature creates lasting bonds.',
        'Emotional connections deepen as your {trait} soul recognizes kindred spirits. {personalElement} illuminates the path forward.',
        'Your {planet} influence brings clarity to relationship matters. Trust your {trait} instincts about love.',
      ],
      'Career and Success': [
        'Your {trait} approach to work impresses influential people today. {planet} empowers your professional ambitions.',
        'Career opportunities align with your {element} energy, bringing recognition and advancement, dear {sign}.',
        'Success follows your {trait} efforts today. The universe rewards your dedication and perseverance.',
        'Professional growth accelerates under {planet}\'s influence. Your {element} nature guides wise decisions.',
        'In this {lifePhase} period, your {trait} talents shine brightly. {personalElement} opens new professional doors.',
        'Workplace dynamics favor your {trait} approach today. Your {element} wisdom navigates challenges gracefully.',
        'Career momentum builds through your {trait} persistence. {personalElement} attracts the right opportunities.',
        'Your {planet} energy amplifies professional recognition. Trust your {trait} vision for the future.',
      ],
      'Health and Wellness': [
        'Your {element} energy promotes healing and vitality today. Listen to your {trait} inner wisdom about wellness.',
        'Physical and emotional balance harmonizes under {planet}\'s guidance. Your body responds to {trait} self-care.',
        'Wellness practices amplify your natural {element} energy, dear {sign}. Trust your intuitive health choices.',
        'Your {trait} approach to health brings remarkable results today. {planet} supports your healing journey.',
        'During this {lifePhase} time, your {trait} body seeks balance. {personalElement} guides healing choices.',
        'Vitality flows through your {element} essence today. Your {trait} instincts know what nourishes you.',
        'Health consciousness expands through your {trait} awareness. {personalElement} illuminates wellness paths.',
        'Your {planet} influence strengthens mind-body connection. Embrace your {trait} approach to self-care.',
      ],
      'Spiritual Growth': [
        'Spiritual insights flow through your {trait} consciousness today. {planet} opens pathways to higher wisdom.',
        'Your {element} energy connects you to divine guidance, dear {sign}. Meditation reveals profound truths.',
        'Sacred knowledge awakens within your {trait} spirit. The cosmos shares its secrets with you today.',
        'Enlightenment touches your soul through {element} energy. Your {trait} nature embraces spiritual evolution.',
        'In this {lifePhase} journey, your {trait} soul seeks deeper meaning. {personalElement} reveals spiritual truths.',
        'Divine connection strengthens through your {trait} practice. Your {element} nature channels cosmic wisdom.',
        'Spiritual awakening unfolds through your {trait} awareness. {personalElement} guides inner transformation.',
        'Your {planet} energy opens mystical doorways. Trust your {trait} connection to the divine.',
      ],
      'Financial Abundance': [
        'Prosperity flows to your {trait} efforts today, {sign}. {planet} brings opportunities for financial growth.',
        'Your {element} energy attracts abundance naturally. Trust your {trait} instincts about money matters.',
        'Wealth consciousness expands through your {trait} mindset. The universe provides for your material needs.',
        'Financial wisdom guides your {element} nature today. {planet} supports your abundance manifestations.',
        'During this {lifePhase} cycle, your {trait} approach creates wealth. {personalElement} attracts prosperity.',
        'Money flows through your {trait} endeavors today. Your {element} energy magnetizes financial opportunities.',
        'Abundance consciousness grows through your {trait} perspective. {personalElement} unlocks wealth potential.',
        'Your {planet} influence brings financial clarity. Trust your {trait} judgment in money decisions.',
      ],
      'Creative Expression': [
        'Artistic inspiration flows through your {trait} soul today. {element} energy fuels creative breakthroughs.',
        'Your {trait} imagination channels divine creativity, dear {sign}. {planet} blesses your artistic endeavors.',
        'Creative projects flourish under today\'s cosmic influence. Your {element} nature expresses beauty uniquely.',
        'Inspiration strikes your {trait} mind repeatedly today. The muses dance with your {element} energy.',
        'In this {lifePhase} moment, your {trait} creativity soars. {personalElement} inspires artistic expression.',
        'Creative flow activates through your {trait} vision. Your {element} essence births beautiful manifestations.',
        'Artistic gifts awaken through your {trait} passion. {personalElement} channels divine inspiration.',
        'Your {planet} energy amplifies creative power. Trust your {trait} artistic instincts completely.',
      ],
      'Family Harmony': [
        'Family bonds strengthen through your {trait} love today. {element} energy creates peaceful home atmosphere.',
        'Your {trait} nature nurtures family connections beautifully. {planet} blesses household harmony and joy.',
        'Generational healing flows through your {element} energy, dear {sign}. Family relationships transform positively.',
        'Home becomes a sanctuary through your {trait} care. {planet} supports loving family communications.',
        'During this {lifePhase} time, your {trait} heart heals family wounds. {personalElement} restores harmony.',
        'Family unity grows through your {trait} wisdom. Your {element} nature bridges generational gaps.',
        'Home energy transforms through your {trait} presence. {personalElement} creates lasting family peace.',
        'Your {planet} influence harmonizes family dynamics. Trust your {trait} ability to heal relationships.',
      ],
      'Personal Transformation': [
        'Profound changes align with your {trait} evolution today. {element} energy supports your metamorphosis.',
        'Your {trait} spirit embraces transformation courageously. {planet} guides your personal revolution.',
        'Old patterns dissolve through your {element} wisdom, dear {sign}. New possibilities emerge from change.',
        'Transformation accelerates through your {trait} willingness to grow. The universe celebrates your evolution.',
        'In this {lifePhase} period, your {trait} soul transforms. {personalElement} catalyzes profound change.',
        'Personal evolution unfolds through your {trait} courage. Your {element} nature embraces metamorphosis.',
        'Inner revolution begins through your {trait} awakening. {personalElement} guides transformational journey.',
        'Your {planet} energy accelerates personal growth. Trust your {trait} capacity for reinvention.',
      ],
      'Adventure and Travel': [
        'New horizons call to your {trait} spirit today. {element} energy propels you toward exciting journeys.',
        'Adventure beckons your {trait} soul, dear {sign}. {planet} opens pathways to thrilling experiences.',
        'Travel opportunities align with your {element} desires. Your {trait} nature seeks expanding experiences.',
        'Exploration feeds your {trait} curiosity today. {planet} supports adventures that broaden perspectives.',
        'During this {lifePhase} chapter, your {trait} spirit yearns for adventure. {personalElement} calls you forward.',
        'Wanderlust awakens through your {trait} essence. Your {element} nature craves new experiences.',
        'Journey consciousness expands through your {trait} vision. {personalElement} opens adventure pathways.',
        'Your {planet} energy activates travel desires. Trust your {trait} call to explore unknown territories.',
      ],
      'Learning and Wisdom': [
        'Knowledge flows to your {trait} mind effortlessly today. {element} energy enhances learning abilities.',
        'Wisdom traditions resonate with your {trait} understanding. {planet} illuminates paths to greater knowledge.',
        'Your {element} nature absorbs cosmic teachings today, dear {sign}. Ancient wisdom speaks to your soul.',
        'Educational opportunities align with your {trait} interests. The universe becomes your classroom today.',
        'In this {lifePhase} journey, your {trait} mind expands. {personalElement} unlocks hidden knowledge.',
        'Learning accelerates through your {trait} curiosity. Your {element} nature absorbs wisdom naturally.',
        'Intellectual growth unfolds through your {trait} inquiry. {personalElement} reveals profound insights.',
        'Your {planet} energy sharpens mental faculties. Trust your {trait} capacity for understanding.',
      ],
      'Communication and Connection': [
        'Your {trait} voice carries powerful truth today. {element} energy amplifies meaningful communications.',
        'Conversations flow with {trait} authenticity, dear {sign}. {planet} facilitates important connections.',
        'Words become bridges through your {element} wisdom. Your {trait} nature creates understanding.',
        'Communication channels open wide today. {planet} blesses your {trait} expressions with clarity.',
        'During this {lifePhase} moment, your {trait} words heal. {personalElement} enhances communication power.',
        'Connection deepens through your {trait} expression. Your {element} nature speaks from the heart.',
        'Dialogue transforms through your {trait} honesty. {personalElement} creates meaningful exchanges.',
        'Your {planet} energy clarifies communication. Trust your {trait} ability to connect authentically.',
      ],
      'Inner Peace and Balance': [
        'Serenity fills your {trait} heart today. {element} energy creates perfect inner harmony and balance.',
        'Peace flows through your {trait} being naturally. {planet} supports your journey to emotional equilibrium.',
        'Your {element} nature finds balance effortlessly today, dear {sign}. Inner tranquility guides all decisions.',
        'Harmony aligns within your {trait} soul. The cosmos bestows peaceful energy upon your spirit.',
        'In this {lifePhase} phase, your {trait} spirit finds center. {personalElement} restores inner balance.',
        'Equilibrium emerges through your {trait} practice. Your {element} nature seeks harmonious states.',
        'Inner calm expands through your {trait} awareness. {personalElement} creates lasting peace.',
        'Your {planet} energy harmonizes emotional currents. Trust your {trait} path to serenity.',
      ],
    };
  }

  String _getEnergyLevel(String zodiacSign, Random random) {
    final energyLevels = ['Very High', 'High', 'Moderate', 'Gentle', 'Intense', 'Flowing'];
    return energyLevels[random.nextInt(energyLevels.length)];
  }

  List<String> _generateDailyAdvice(String zodiacSign, String theme, Random random) {
    final adviceBank = _getAdviceBank();
    final signAdvice = adviceBank[zodiacSign]!;
    final themeAdvice = adviceBank[theme] ?? [];
    
    final allAdvice = [...signAdvice, ...themeAdvice];
    allAdvice.shuffle(random);
    
    return allAdvice.take(3).toList();
  }

  Map<String, List<String>> _getAdviceBank() {
    return {
      'Aries': [
        'Channel your natural leadership energy into meaningful projects today',
        'Take initiative in situations where others hesitate',
        'Your courage inspires others to be their best selves',
        'Trust your first instincts - they rarely lead you astray',
      ],
      'Taurus': [
        'Slow and steady progress yields the most beautiful results',
        'Indulge in sensory pleasures that nourish your soul',
        'Your persistence creates lasting foundations for success',
        'Ground yourself in nature to restore your energy',
      ],
      'Gemini': [
        'Share your ideas freely - they spark inspiration in others',
        'Curiosity leads you to unexpected discoveries today',
        'Multiple interests create rich tapestries of experience',
        'Communication bridges differences and builds understanding',
      ],
      'Cancer': [
        'Trust your intuitive insights about people and situations',
        'Nurture yourself as lovingly as you care for others',
        'Home and family provide your greatest sources of strength',
        'Emotional wisdom guides you toward the right choices',
      ],
      'Leo': [
        'Let your authentic self shine brightly today',
        'Creative expression feeds your soul and inspires others',
        'Generosity of spirit returns to you multiplied',
        'Your confidence gives others permission to be confident too',
      ],
      'Virgo': [
        'Attention to detail creates perfection in all endeavors',
        'Service to others fulfills your deepest purpose',
        'Organization brings clarity to chaotic situations',
        'Your practical wisdom solves complex problems elegantly',
      ],
      'Libra': [
        'Seek harmony and balance in all life areas today',
        'Beauty and aesthetics uplift your spirit significantly',
        'Diplomatic skills resolve conflicts peacefully',
        'Partnership energy multiplies your personal power',
      ],
      'Scorpio': [
        'Embrace transformation as your pathway to power',
        'Depth and intensity create meaningful connections',
        'Trust your investigative instincts completely',
        'Your healing energy transforms others profoundly',
      ],
      'Sagittarius': [
        'Adventure and exploration feed your optimistic soul',
        'Share your philosophical insights with seekers',
        'Freedom and independence fuel your creativity',
        'Teaching others brings you unexpected joy today',
      ],
      'Capricorn': [
        'Discipline and structure create lasting achievements',
        'Your reputation for reliability opens new doors',
        'Long-term planning yields exceptional results',
        'Authority comes naturally to your mature wisdom',
      ],
      'Aquarius': [
        'Innovation and originality set you apart beautifully',
        'Humanitarian causes align with your higher purpose',
        'Technology amplifies your unique contributions',
        'Group collaboration manifests revolutionary changes',
      ],
      'Pisces': [
        'Intuition and empathy guide your interactions today',
        'Artistic expression channels divine inspiration',
        'Compassion heals wounds in yourself and others',
        'Dreams and imagination reveal practical solutions',
      ],
    };
  }

  String _getDailyCompatibility(String zodiacSign, Random random) {
    final compatibilityData = {
      'Aries': ['Leo', 'Sagittarius', 'Gemini', 'Aquarius'],
      'Taurus': ['Virgo', 'Capricorn', 'Cancer', 'Pisces'],
      'Gemini': ['Libra', 'Aquarius', 'Aries', 'Leo'],
      'Cancer': ['Scorpio', 'Pisces', 'Taurus', 'Virgo'],
      'Leo': ['Aries', 'Sagittarius', 'Gemini', 'Libra'],
      'Virgo': ['Taurus', 'Capricorn', 'Cancer', 'Scorpio'],
      'Libra': ['Gemini', 'Aquarius', 'Leo', 'Sagittarius'],
      'Scorpio': ['Cancer', 'Pisces', 'Virgo', 'Capricorn'],
      'Sagittarius': ['Aries', 'Leo', 'Libra', 'Aquarius'],
      'Capricorn': ['Taurus', 'Virgo', 'Scorpio', 'Pisces'],
      'Aquarius': ['Gemini', 'Libra', 'Sagittarius', 'Aries'],
      'Pisces': ['Cancer', 'Scorpio', 'Capricorn', 'Taurus'],
    };
    
    final compatibleSigns = compatibilityData[zodiacSign]!;
    final luckySign = compatibleSigns[random.nextInt(compatibleSigns.length)];
    return 'Best compatibility today with $luckySign ${signEmojis[luckySign]}';
  }

  String _generateDailyAffirmation(String zodiacSign, Random random) {
    final affirmations = {
      'Aries': [
        'I am a powerful force of positive change in the world',
        'My courage and determination create unlimited possibilities',
        'I trust my ability to lead and inspire others',
        'Every challenge strengthens my pioneering spirit',
      ],
      'Taurus': [
        'I am grounded in abundance and surrounded by beauty',
        'My patience and persistence create lasting success',
        'I trust the natural timing of my life\'s unfolding',
        'Stability and comfort flow to me effortlessly',
      ],
      'Gemini': [
        'I communicate my truth with clarity and wisdom',
        'My curiosity opens doors to endless learning',
        'I adapt gracefully to life\'s changing rhythms',
        'My versatility is my greatest strength',
      ],
      'Cancer': [
        'I trust my intuition to guide me perfectly',
        'My nurturing nature creates healing wherever I go',
        'I am safe, loved, and emotionally fulfilled',
        'My sensitivity is a gift that serves the world',
      ],
      'Leo': [
        'I shine my authentic light brightly and confidently',
        'My creativity brings joy and inspiration to others',
        'I am worthy of love, admiration, and respect',
        'My generous heart creates abundance for all',
      ],
      'Virgo': [
        'I serve others with love, precision, and excellence',
        'My attention to detail creates perfect outcomes',
        'I am helpful, healing, and wholly appreciated',
        'Organization and clarity flow through all I do',
      ],
      'Libra': [
        'I create harmony and balance in all relationships',
        'Beauty and peace surround me naturally',
        'I make decisions with wisdom and fairness',
        'My diplomatic nature resolves conflicts gracefully',
      ],
      'Scorpio': [
        'I embrace transformation as my path to power',
        'My intensity creates deep and meaningful connections',
        'I trust my ability to regenerate and renew',
        'Mystery and magic flow through my authentic being',
      ],
      'Sagittarius': [
        'I explore life with optimism and boundless curiosity',
        'My philosophical nature inspires and enlightens others',
        'Freedom and adventure align with my highest good',
        'I trust the journey and embrace all possibilities',
      ],
      'Capricorn': [
        'I achieve my goals through discipline and determination',
        'My practical wisdom creates lasting foundations',
        'Success and recognition come to me naturally',
        'I am a responsible steward of my gifts and talents',
      ],
      'Aquarius': [
        'I innovate and create positive change in the world',
        'My unique perspective offers valuable solutions',
        'I connect with like-minded souls for collective good',
        'Freedom and independence support my highest expression',
      ],
      'Pisces': [
        'I trust my intuition and follow my heart\'s wisdom',
        'My compassion heals and transforms the world',
        'I channel divine inspiration through creative expression',
        'Love and spirituality guide all my actions',
      ],
    };
    
    final signAffirmations = affirmations[zodiacSign]!;
    return signAffirmations[random.nextInt(signAffirmations.length)];
  }

  // Enhanced personalization methods for individual user experiences
  String _getPersonalElement(String zodiacSign, Random random) {
    final personalElements = {
      'Fire': ['Passion', 'Ambition', 'Creativity', 'Leadership', 'Innovation'],
      'Earth': ['Stability', 'Growth', 'Abundance', 'Healing', 'Wisdom'],
      'Air': ['Communication', 'Ideas', 'Freedom', 'Learning', 'Connection'],
      'Water': ['Intuition', 'Emotion', 'Flow', 'Depth', 'Transformation']
    };
    
    final zodiacData = _getZodiacSignData(zodiacSign);
    final element = zodiacData['element'] as String;
    final elements = personalElements[element]!;
    
    return elements[random.nextInt(elements.length)];
  }

  String _getCurrentLifePhase(Random random) {
    final lifePhases = [
      'Planting Seeds', 'Growing', 'Blooming', 'Harvesting', 'Reflecting',
      'Renewing', 'Discovering', 'Building', 'Sharing', 'Transforming'
    ];
    
    return lifePhases[random.nextInt(lifePhases.length)];
  }

  int _getCosmicNumber(Random random) {
    // Generate a special cosmic number between 1-99
    return random.nextInt(99) + 1;
  }

  // New: Load astronomical influence
  void _loadAstronomicalInfluence() {
    final influences = [
      "🌕 Full Moon energy amplifies your intuition today",
      "🌙 New Moon brings fresh opportunities for manifestation",
      "⭐ Mercury retrograde encourages reflection and review",
      "🪐 Saturn's influence brings focus and discipline",
      "♃ Jupiter expands your luck and abundance today",
      "♀ Venus enhances love and creativity in your life",
      "♂ Mars energy boosts your courage and determination",
      "🌟 Stellar alignment favors new beginnings",
      "🌠 Cosmic winds carry messages of transformation",
      "🔮 Planetary dance creates mystical synchronicities",
    ];
    
    final random = Random();
    setState(() {
      astronomicalInfluence = influences[random.nextInt(influences.length)];
    });
  }

  Future<void> _checkDailyBlessingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastBlessingDate = prefs.getString('last_blessing_date');
    
    setState(() {
      _hasReceivedDailyBlessing = lastBlessingDate == today;
      _streakCount = prefs.getInt('blessing_streak') ?? 0;
    });
  }

  Future<void> _saveDailyBlessingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final yesterday = DateTime.now().subtract(Duration(days: 1)).toIso8601String().split('T')[0];
    final lastBlessingDate = prefs.getString('last_blessing_date');
    
    // Update streak
    int newStreak = 1;
    if (lastBlessingDate == yesterday) {
      newStreak = _streakCount + 1;
    }
    
    await prefs.setString('last_blessing_date', today);
    await prefs.setInt('blessing_streak', newStreak);
    
    setState(() {
      _hasReceivedDailyBlessing = true;
      _streakCount = newStreak;
    });

    // Award coins for daily blessing
    if (widget.userId != null && widget.supabase != null) {
      try {
        await _rewardsManager.trackAction(widget.userId!, 'daily_blessing', context);
        widget.onCoinsUpdated?.call();
      } catch (e) {
        print('Error awarding daily blessing coins: $e');
      }
    }
  }

  Color _generateRandomPastelColor() {
    Random random = Random();
    int red = random.nextInt(128) + 128;
    int green = random.nextInt(128) + 128;
    int blue = random.nextInt(128) + 128;
    return Color.fromRGBO(red, green, blue, 1);
  }

  void _receiveDailyBlessing() async {
    if (_hasReceivedDailyBlessing) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You have already received your daily blessing! ✨'),
          backgroundColor: Colors.deepPurpleAccent,
        ),
      );
      return;
    }

    if (fadeController == null || textController == null || emojiController == null) {
      return;
    }
    
    HapticFeedback.mediumImpact();
    
    setState(() {
      fadeController!.forward(from: 0.0);
    });

    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          backgroundColor = _generateRandomPastelColor();
          // Generate new reading only if zodiac sign is selected
          if (selectedZodiacSign != null) {
            _generateDailyReading();
          }
          _loadAstronomicalInfluence(); // Refresh astronomical influence
        });

        fadeController!.reverse();
        textController!.forward();
        crystalController!.forward();

        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            emojiController!.forward();
          }
        });

        _saveDailyBlessingStatus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor.withOpacity(0.8),
            backgroundColor.withOpacity(0.6),
            Color(0xFF0D1117),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Background particle system
          Positioned.fill(
            child: ParticleSystem(
              particleCount: 80,
              particleColor: Colors.white.withOpacity(0.4),
              maxSize: 2.0,
              speed: 0.6,
              isStars: true,
            ),
          ),
          
          // Cosmic wave animations
          if (selectedZodiacSign != null)
            Positioned.fill(
              child: CosmicWaveAnimation(
                color: backgroundColor.withOpacity(0.3),
                amplitude: 25,
                duration: Duration(seconds: 8),
              ),
            ),
          
          // Floating crystals
          if (selectedZodiacSign != null) ...[
            Positioned(
              top: 150,
              right: 20,
              child: FloatingCrystal(
                color: Colors.pinkAccent,
                size: 28,
                duration: Duration(seconds: 4),
              ),
            ),
            Positioned(
              top: 300,
              left: 30,
              child: FloatingCrystal(
                color: Colors.blueAccent,
                size: 22,
                duration: Duration(seconds: 6),
              ),
            ),
            Positioned(
              bottom: 200,
              right: 40,
              child: FloatingCrystal(
                color: Colors.purpleAccent,
                size: 26,
                duration: Duration(seconds: 5),
              ),
            ),
          ],
          
          // Main content
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Enhanced Zodiac Sign Selector
                if (selectedZodiacSign == null)
                  AnimatedContainer(
                    duration: Duration(milliseconds: 800),
                    curve: Curves.easeOutBack,
                    margin: EdgeInsets.only(bottom: 25),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Color(0xFF1A1A2E).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurpleAccent.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.deepPurpleAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Image.asset(
                                'assets/icons/horoscope.png',
                                width: 24,
                                height: 24,
                                color: Colors.deepPurpleAccent,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Select Your Zodiac Sign",
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.deepPurpleAccent.withOpacity(0.5),
                                    blurRadius: 5,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 15),
                        Text(
                          "Choose your zodiac sign to receive personalized daily guidance",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Color(0xFF0D1117),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurpleAccent.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedZodiacSign,
                              hint: Text(
                                'Choose your sign...',
                                style: TextStyle(color: Colors.white54),
                              ),
                              isExpanded: true,
                              dropdownColor: Color(0xFF1A1A2E),
                              style: TextStyle(color: Colors.white, fontSize: 16),
                              items: zodiacSigns.map((sign) => DropdownMenuItem(
                                value: sign,
                                child: Row(
                                  children: [
                                    Text(signEmojis[sign]!, style: TextStyle(fontSize: 20)),
                                    SizedBox(width: 12),
                                    Text(sign, style: TextStyle(color: Colors.white)),
                                  ],
                                ),
                              )).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    selectedZodiacSign = value;
                                  });
                                  _saveUserZodiacSign(value);
                                  _generateDailyReading();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Enhanced content when zodiac sign is selected
                if (selectedZodiacSign != null) ...[
                  // Enhanced Zodiac Sign Header with animations
                  AnimatedContainer(
                    duration: Duration(milliseconds: 600),
                    curve: Curves.easeOutBack,
                    margin: EdgeInsets.only(bottom: 20),
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Color(0xFF1A1A2E).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurpleAccent.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.deepPurpleAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            signEmojis[selectedZodiacSign!]!,
                            style: TextStyle(
                              fontSize: 32,
                              shadows: [
                                Shadow(
                                  color: Colors.white.withOpacity(0.8),
                                  blurRadius: 10,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedZodiacSign!,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.deepPurpleAccent.withOpacity(0.6),
                                    blurRadius: 5,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "Daily Cosmic Guidance",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Streak counter
              if (_streakCount > 0)
                Container(
                  margin: EdgeInsets.only(bottom: 20),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department, color: Colors.amber, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '$_streakCount day streak!',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

              // NEW: Astronomical Influence Card
              if (astronomicalInfluence.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(bottom: 20),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF1A1A2E).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurpleAccent.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/icons/heaven.png',
                        width: 24,
                        height: 24,
                        color: Colors.deepPurpleAccent,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Celestial Influence",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              astronomicalInfluence,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.deepPurpleAccent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Main blessing button
              Container(
                margin: EdgeInsets.only(bottom: 30),
                child: ElevatedButton.icon(
                  onPressed: _receiveDailyBlessing,
                  icon: _hasReceivedDailyBlessing 
                    ? Icon(Icons.check_circle)
                    : Image.asset(
                        'assets/icons/horoscope.png',
                        width: 20,
                        height: 20,
                        color: Colors.white,
                      ),
                  label: Text(_hasReceivedDailyBlessing ? "Blessing Received" : "Receive Daily Blessing"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                    backgroundColor: _hasReceivedDailyBlessing ? Colors.green : Colors.deepPurpleAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 8,
                  ),
                ),
              ),

              // Horoscope message card
              if (fadeController != null && textController != null)
                AnimatedBuilder(
                  animation: textController!,
                  builder: (context, child) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 20),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Color(0xFF1A1A2E).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurpleAccent.withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/icons/horoscope.png',
                            width: 30,
                            height: 30,
                            color: Colors.deepPurpleAccent,
                          ),
                          SizedBox(height: 15),
                          Text(
                            horoscopeMessage,
                            style: TextStyle(
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),

              // Lucky elements row
              Row(
                children: [
                  // Lucky Emoji
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: 8),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF1A1A2E).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.pinkAccent.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Lucky Emoji",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          if (emojiController != null)
                            AnimatedBuilder(
                              animation: emojiController!,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: 1.0 + (emojiController!.value * 0.2),
                                  child: Text(
                                    luckyEmoji,
                                    style: TextStyle(fontSize: 32),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Lucky Number
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF1A1A2E).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Lucky Number",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            luckyNumber,
                            style: TextStyle(
                              fontSize: 28,
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Crystal recommendation
              if (crystalController != null)
                AnimatedBuilder(
                  animation: crystalController!,
                  builder: (context, child) {
                    return Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Color(0xFF1A1A2E).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.tealAccent.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/icons/crystal.png',
                                width: 24,
                                height: 24,
                                color: Colors.tealAccent,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Today's Crystal Guide",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            todaysCrystal,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.tealAccent,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                        );
                      },
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}// Keep the existing tabs with minimal modifications
class ZodiacCompatibilityTab extends StatefulWidget {
  @override
  _ZodiacCompatibilityTabState createState() => _ZodiacCompatibilityTabState();
}

class _ZodiacCompatibilityTabState extends State<ZodiacCompatibilityTab> {
  String? selectedSign1;
  String? selectedSign2;
  String compatibilityResult = "";
  
  final List<String> zodiacSigns = [
    "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
    "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"
  ];

  final Map<String, String> signEmojis = {
    "Aries": "♈", "Taurus": "♉", "Gemini": "♊", "Cancer": "♋",
    "Leo": "♌", "Virgo": "♍", "Libra": "♎", "Scorpio": "♏",
    "Sagittarius": "♐", "Capricorn": "♑", "Aquarius": "♒", "Pisces": "♓"
  };

  void _checkCompatibility() {
    if (selectedSign1 != null && selectedSign2 != null) {
      final compatibilityMessages = [
        "A divine cosmic connection! Your energies dance in perfect harmony. ✨",
        "Strong potential for growth together. The stars smile upon this pairing. 🌟",
        "An intriguing combination with exciting possibilities. 💫",
        "Different energies that can complement each other beautifully. 🌙",
        "A challenging but rewarding connection that encourages growth. ⭐",
      ];
      
      Random random = Random();
      setState(() {
        compatibilityResult = compatibilityMessages[random.nextInt(compatibilityMessages.length)];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF0D1117)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Zodiac Compatibility",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 30),
            
            // First sign selector
            Container(
              margin: EdgeInsets.only(bottom: 20),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.pinkAccent.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    "First Sign",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedSign1,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFF0D1117),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    dropdownColor: Color(0xFF1A1A2E),
                    style: TextStyle(color: Colors.white),
                    items: zodiacSigns.map((sign) => DropdownMenuItem(
                      value: sign,
                      child: Row(
                        children: [
                          Text(signEmojis[sign]!, style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text(sign),
                        ],
                      ),
                    )).toList(),
                    onChanged: (value) => setState(() => selectedSign1 = value),
                  ),
                ],
              ),
            ),

            // Second sign selector
            Container(
              margin: EdgeInsets.only(bottom: 20),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    "Second Sign",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedSign2,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFF0D1117),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    dropdownColor: Color(0xFF1A1A2E),
                    style: TextStyle(color: Colors.white),
                    items: zodiacSigns.map((sign) => DropdownMenuItem(
                      value: sign,
                      child: Row(
                        children: [
                          Text(signEmojis[sign]!, style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text(sign),
                        ],
                      ),
                    )).toList(),
                    onChanged: (value) => setState(() => selectedSign2 = value),
                  ),
                ],
              ),
            ),

            // Check compatibility button
            ElevatedButton.icon(
              onPressed: (selectedSign1 != null && selectedSign2 != null) ? _checkCompatibility : null,
              icon: Icon(Icons.favorite),
              label: Text("Check Compatibility"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
            ),

            // Results
            if (compatibilityResult.isNotEmpty)
              Container(
                margin: EdgeInsets.only(top: 30),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.pinkAccent.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(signEmojis[selectedSign1!]!, style: TextStyle(fontSize: 30)),
                        SizedBox(width: 10),
                        Icon(Icons.favorite, color: Colors.pinkAccent, size: 30),
                        SizedBox(width: 10),
                        Text(signEmojis[selectedSign2!]!, style: TextStyle(fontSize: 30)),
                      ],
                    ),
                    SizedBox(height: 15),
                    Text(
                      compatibilityResult,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Crystal Guidance Tab (unchanged)
class CrystalGuidanceTab extends StatefulWidget {
  @override
  _CrystalGuidanceTabState createState() => _CrystalGuidanceTabState();
}

class _CrystalGuidanceTabState extends State<CrystalGuidanceTab> {
  String selectedMood = "";
  String crystalRecommendation = "";
  
  final Map<String, Map<String, String>> crystalGuide = {
    "Stressed": {
      "crystal": "Amethyst",
      "description": "Known for its calming properties, Amethyst helps reduce stress and promotes tranquility. Place it near your pillow for peaceful sleep.",
      "emoji": "💜"
    },
    "Anxious": {
      "crystal": "Black Tourmaline",
      "description": "A powerful protective stone that shields against negative energy and promotes grounding. Carry it for emotional stability.",
      "emoji": "🖤"
    },
    "Unmotivated": {
      "crystal": "Citrine",
      "description": "The success stone that brings joy, abundance, and motivation. Keep it in your workspace for enhanced creativity.",
      "emoji": "💛"
    },
    "Heartbroken": {
      "crystal": "Rose Quartz",
      "description": "The stone of unconditional love that heals emotional wounds and opens the heart to new possibilities.",
      "emoji": "💖"
    },
    "Confused": {
      "crystal": "Clear Quartz",
      "description": "The master healer that amplifies clarity and helps you see situations from a higher perspective.",
      "emoji": "🤍"
    },
    "Tired": {
      "crystal": "Carnelian",
      "description": "An energizing stone that boosts vitality and motivation. Wear it for sustained energy throughout the day.",
      "emoji": "🧡"
    },
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF0D1117)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Crystal Guidance",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            Text(
              "How are you feeling today?",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 30),

            // Mood selection grid
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.5,
              ),
              itemCount: crystalGuide.keys.length,
              itemBuilder: (context, index) {
                final mood = crystalGuide.keys.elementAt(index);
                final isSelected = selectedMood == mood;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedMood = mood;
                      crystalRecommendation = mood;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.tealAccent.withOpacity(0.2) : Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isSelected ? Colors.tealAccent : Colors.tealAccent.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        mood,
                        style: TextStyle(
                          color: isSelected ? Colors.tealAccent : Colors.white,
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Crystal recommendation
            if (crystalRecommendation.isNotEmpty)
              Container(
                margin: EdgeInsets.only(top: 30),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          crystalGuide[crystalRecommendation]!["emoji"]!,
                          style: TextStyle(fontSize: 40),
                        ),
                        SizedBox(width: 15),
                        Text(
                          crystalGuide[crystalRecommendation]!["crystal"]!,
                          style: TextStyle(
                            color: Colors.tealAccent,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Text(
                      crystalGuide[crystalRecommendation]!["description"]!,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Tarot Navigation Tab (unchanged)
class TarotNavigationTab extends StatelessWidget {
  final String? userId;
  final SupabaseClient? supabase;

  const TarotNavigationTab({
    super.key,
    this.userId,
    this.supabase,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF0D1117)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurpleAccent.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/icons/tarot.png',
                    width: 80,
                    height: 80,
                    color: Colors.deepPurpleAccent,
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Mystical Tarot Reading",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 15),
                  Text(
                    "Unlock the secrets of your future with personalized tarot deck designs from your collection",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 25),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TarotReadingTab(
                            userId: userId ?? 'demo_user',
                            supabase: supabase ?? Supabase.instance.client,
                          ),
                        ),
                      );
                    },
                    icon: Image.asset(
                      'assets/icons/tarot.png',
                      width: 20,
                      height: 20,
                      color: Colors.white,
                    ),
                    label: Text("Begin Reading"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
