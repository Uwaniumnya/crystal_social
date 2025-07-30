import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class OracleMessage {
  final String message;
  final String type;
  final String element;
  final Color color;
  final IconData icon;

  OracleMessage({
    required this.message,
    required this.type,
    required this.element,
    required this.color,
    required this.icon,
  });
}

class OracleScreen extends StatefulWidget {
  final String userId;

  const OracleScreen({
    super.key,
    required this.userId,
  });

  @override
  State<OracleScreen> createState() => _OracleScreenState();
}

class _OracleScreenState extends State<OracleScreen>
    with TickerProviderStateMixin {
  late AnimationController _crystalController;
  late AnimationController _particleController;
  late AnimationController _messageController;
  late Animation<double> _crystalRotation;
  late Animation<double> _crystalPulse;
  late Animation<double> _particleAnimation;
  late Animation<double> _messageOpacity;
  late Animation<Offset> _messageSlide;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isConsulting = false;
  OracleMessage? _currentMessage;
  String _selectedQuestion = '';
  List<String> _recentMessages = [];
  int _dailyConsultations = 0;
  String? _todaysSpecialMessage;
  
  // Enhanced features
  String _oracleMode = 'crystal'; // crystal, tarot, runes, elements
  bool _soundEnabled = true;
  bool _hapticEnabled = true;
  int _streakDays = 0;
  List<String> _favoriteMessages = [];
  String _currentMood = 'neutral';
  Map<String, int> _elementalAffinities = {
    'Fire': 0,
    'Water': 0,
    'Earth': 0,
    'Air': 0,
    'Spirit': 0,
  };

  final List<String> _quickQuestions = [
    "What should I focus on today?",
    "What energy surrounds me now?",
    "What message do I need to hear?",
    "How can I find inner peace?",
    "What is my spiritual path?",
    "What blocks my growth?",
    "How can I manifest my dreams?",
    "What lesson am I learning?",
  ];

  final List<OracleMessage> _oracleMessages = [
    // Love & Relationships
    OracleMessage(
      message: "Love flows toward you like a gentle river. Open your heart to receive the abundance coming your way.",
      type: "Love",
      element: "Water",
      color: Colors.pink,
      icon: Icons.favorite,
    ),
    OracleMessage(
      message: "A soul connection awaits. Trust your intuition when meeting new people - your heart knows the truth.",
      type: "Love",
      element: "Air",
      color: Colors.pink.shade300,
      icon: Icons.favorite_border,
    ),
    OracleMessage(
      message: "Self-love is the foundation of all other loves. Nurture your relationship with yourself first.",
      type: "Love",
      element: "Earth",
      color: Colors.pink.shade400,
      icon: Icons.self_improvement,
    ),

    // Wisdom & Growth
    OracleMessage(
      message: "Every challenge is a teacher in disguise. What is this situation trying to teach you?",
      type: "Wisdom",
      element: "Fire",
      color: Colors.orange,
      icon: Icons.school,
    ),
    OracleMessage(
      message: "Your intuition is stronger than you realize. Trust the quiet voice within.",
      type: "Wisdom",
      element: "Spirit",
      color: Colors.purple,
      icon: Icons.visibility,
    ),
    OracleMessage(
      message: "Growth happens in spirals, not straight lines. You're exactly where you need to be.",
      type: "Wisdom",
      element: "Earth",
      color: Colors.green,
      icon: Icons.trending_up,
    ),

    // Abundance & Success
    OracleMessage(
      message: "Abundance is your birthright. Release limiting beliefs and watch opportunities unfold.",
      type: "Abundance",
      element: "Earth",
      color: Colors.green.shade600,
      icon: Icons.eco,
    ),
    OracleMessage(
      message: "Success comes through aligned action. Follow your passion with dedication and patience.",
      type: "Abundance",
      element: "Fire",
      color: Colors.orange.shade700,
      icon: Icons.star,
    ),
    OracleMessage(
      message: "Your unique gifts are needed in this world. Don't hide your light - let it shine brightly.",
      type: "Abundance",
      element: "Fire",
      color: Colors.amber,
      icon: Icons.lightbulb,
    ),

    // Healing & Peace
    OracleMessage(
      message: "Healing happens in layers. Be patient with yourself as you release what no longer serves you.",
      type: "Healing",
      element: "Water",
      color: Colors.blue.shade300,
      icon: Icons.healing,
    ),
    OracleMessage(
      message: "Peace is found in the present moment. Take a deep breath and feel the calm within.",
      type: "Healing",
      element: "Air",
      color: Colors.blue.shade200,
      icon: Icons.air,
    ),
    OracleMessage(
      message: "Your sensitivity is a superpower. Use it to help others while protecting your energy.",
      type: "Healing",
      element: "Water",
      color: Colors.teal,
      icon: Icons.shield,
    ),

    // Transformation & Change
    OracleMessage(
      message: "Like a butterfly emerging from its cocoon, you are transforming into your highest self.",
      type: "Transformation",
      element: "Air",
      color: Colors.purple.shade300,
      icon: Icons.transform,
    ),
    OracleMessage(
      message: "Change is the universe's way of upgrading your life. Embrace the unknown with excitement.",
      type: "Transformation",
      element: "Fire",
      color: Colors.deepPurple,
      icon: Icons.change_circle,
    ),
    OracleMessage(
      message: "You are shedding old patterns like a snake sheds its skin. Welcome your new chapter.",
      type: "Transformation",
      element: "Earth",
      color: Colors.indigo,
      icon: Icons.refresh,
    ),

    // Spiritual Guidance
    OracleMessage(
      message: "Your spirit guides are always with you. Ask for signs and watch for synchronicities.",
      type: "Spiritual",
      element: "Spirit",
      color: Colors.deepPurple.shade400,
      icon: Icons.auto_awesome,
    ),
    OracleMessage(
      message: "You are a divine being having a human experience. Remember your true nature.",
      type: "Spiritual",
      element: "Spirit",
      color: Colors.indigo.shade300,
      icon: Icons.psychology,
    ),
    OracleMessage(
      message: "The universe is conspiring in your favor. Trust the divine timing of your life.",
      type: "Spiritual",
      element: "All",
      color: Colors.cyan.shade300,
      icon: Icons.all_inclusive,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadDailyData();
  }

  void _setupAnimations() {
    _crystalController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _messageController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _crystalRotation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _crystalController,
      curve: Curves.linear,
    ));

    _crystalPulse = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _crystalController,
      curve: Curves.easeInOut,
    ));

    _particleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeOutCubic,
    ));

    _messageOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _messageController,
      curve: Curves.easeIn,
    ));

    _messageSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _messageController,
      curve: Curves.easeOutBack,
    ));

    _crystalController.repeat();
  }

  Future<void> _loadDailyData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toString().split(' ')[0];
    
    setState(() {
      _dailyConsultations = prefs.getInt('oracle_consultations_$today') ?? 0;
      _todaysSpecialMessage = prefs.getString('oracle_special_$today');
      _recentMessages = prefs.getStringList('oracle_recent') ?? [];
      _soundEnabled = prefs.getBool('oracle_sound_enabled') ?? true;
      _hapticEnabled = prefs.getBool('oracle_haptic_enabled') ?? true;
      _streakDays = prefs.getInt('oracle_streak_days') ?? 0;
      _favoriteMessages = prefs.getStringList('oracle_favorites') ?? [];
      _currentMood = prefs.getString('oracle_current_mood') ?? 'neutral';
      
      // Load elemental affinities
      _elementalAffinities['Fire'] = prefs.getInt('oracle_affinity_fire') ?? 0;
      _elementalAffinities['Water'] = prefs.getInt('oracle_affinity_water') ?? 0;
      _elementalAffinities['Earth'] = prefs.getInt('oracle_affinity_earth') ?? 0;
      _elementalAffinities['Air'] = prefs.getInt('oracle_affinity_air') ?? 0;
      _elementalAffinities['Spirit'] = prefs.getInt('oracle_affinity_spirit') ?? 0;
    });

    // Generate daily special message if none exists
    if (_todaysSpecialMessage == null) {
      final specialMessage = _generateDailyMessage();
      await prefs.setString('oracle_special_$today', specialMessage);
      setState(() {
        _todaysSpecialMessage = specialMessage;
      });
    }

    // Update streak
    await _updateStreak();
  }

  String _generateDailyMessage() {
    final random = Random();
    final dayMessages = [
      "Today, the cosmic energies align to bring you clarity and purpose.",
      "The universe whispers secrets of wisdom to those who listen with their heart.",
      "Your intuition is especially strong today - trust the messages you receive.",
      "A day of transformation awaits. Embrace change with an open spirit.",
      "The elements dance in harmony today, bringing balance to your path.",
    ];
    return dayMessages[random.nextInt(dayMessages.length)];
  }

  Future<void> _consultOracle([String? customQuestion]) async {
    if (_isConsulting) return;

    if (_hapticEnabled) {
      HapticFeedback.mediumImpact();
    }
    
    setState(() {
      _isConsulting = true;
      _currentMessage = null;
    });

    // Play mystical sound effect (if audio file exists and sound enabled)
    if (_soundEnabled) {
      try {
        await _audioPlayer.play(AssetSource('sounds/oracle_chime.mp3'));
      } catch (e) {
        // Audio file doesn't exist, continue without sound
      }
    }

    // Start consultation animation
    _particleController.forward(from: 0);

    // Simulate mystical consultation delay with mood consideration
    final consultationDelay = _currentMood == 'anxious' ? 1500 : 
                             _currentMood == 'excited' ? 2500 : 2000;
    await Future.delayed(Duration(milliseconds: consultationDelay));

    // Select message based on question, mood, and elemental affinities
    final random = Random();
    OracleMessage selectedMessage;

    if (customQuestion != null && customQuestion.isNotEmpty) {
      selectedMessage = _getSmartMessage(customQuestion, random);
    } else {
      // Use elemental affinity to bias selection
      selectedMessage = _getAffinityBasedMessage(random);
    }

    // Update elemental affinities
    _updateElementalAffinity(selectedMessage.element);

    setState(() {
      _currentMessage = selectedMessage;
      _isConsulting = false;
    });

    // Animate message appearance
    _messageController.forward(from: 0);

    // Save consultation data
    await _saveConsultation(selectedMessage);

    // Celebration for milestones
    if (_dailyConsultations == 1) {
      _showMilestoneDialog('First consultation of the day! 🌟');
    } else if (_dailyConsultations % 5 == 0) {
      _showMilestoneDialog('${_dailyConsultations} consultations today! You\'re on a spiritual journey! ✨');
    }

    // Award experience points (if rewards system is available)
    try {
      // Placeholder for future rewards integration
      // await RewardsManager.awardExperience(widget.userId, 10, 'Oracle Consultation');
    } catch (e) {
      // Continue if rewards system fails
    }
  }

  OracleMessage _getSmartMessage(String question, Random random) {
    final lowerQuestion = question.toLowerCase();
    
    // Enhanced question analysis
    if (lowerQuestion.contains(RegExp(r'\b(love|heart|relationship|partner|soulmate|romance)\b'))) {
      final loveMessages = _oracleMessages.where((m) => m.type == 'Love').toList();
      return loveMessages[random.nextInt(loveMessages.length)];
    } else if (lowerQuestion.contains(RegExp(r'\b(money|success|career|job|wealth|abundance|prosperity)\b'))) {
      final abundanceMessages = _oracleMessages.where((m) => m.type == 'Abundance').toList();
      return abundanceMessages[random.nextInt(abundanceMessages.length)];
    } else if (lowerQuestion.contains(RegExp(r'\b(healing|peace|calm|anxiety|stress|depression|health)\b'))) {
      final healingMessages = _oracleMessages.where((m) => m.type == 'Healing').toList();
      return healingMessages[random.nextInt(healingMessages.length)];
    } else if (lowerQuestion.contains(RegExp(r'\b(change|transform|growth|evolve|transition|new)\b'))) {
      final transformationMessages = _oracleMessages.where((m) => m.type == 'Transformation').toList();
      return transformationMessages[random.nextInt(transformationMessages.length)];
    } else if (lowerQuestion.contains(RegExp(r'\b(wisdom|learn|understand|guidance|insight|knowledge)\b'))) {
      final wisdomMessages = _oracleMessages.where((m) => m.type == 'Wisdom').toList();
      return wisdomMessages[random.nextInt(wisdomMessages.length)];
    } else if (lowerQuestion.contains(RegExp(r'\b(spirit|soul|divine|god|universe|cosmic|energy)\b'))) {
      final spiritualMessages = _oracleMessages.where((m) => m.type == 'Spiritual').toList();
      return spiritualMessages[random.nextInt(spiritualMessages.length)];
    }
    
    return _oracleMessages[random.nextInt(_oracleMessages.length)];
  }

  OracleMessage _getAffinityBasedMessage(Random random) {
    // Find strongest elemental affinity
    String strongestElement = 'Spirit';
    int maxAffinity = 0;
    
    _elementalAffinities.forEach((element, affinity) {
      if (affinity > maxAffinity) {
        maxAffinity = affinity;
        strongestElement = element;
      }
    });

    // Bias selection toward strongest element (70% chance) or random (30% chance)
    if (maxAffinity > 0 && random.nextDouble() < 0.7) {
      final elementMessages = _oracleMessages.where((m) => m.element == strongestElement).toList();
      if (elementMessages.isNotEmpty) {
        return elementMessages[random.nextInt(elementMessages.length)];
      }
    }
    
    return _oracleMessages[random.nextInt(_oracleMessages.length)];
  }

  void _updateElementalAffinity(String element) {
    setState(() {
      _elementalAffinities[element] = (_elementalAffinities[element] ?? 0) + 1;
    });
  }

  Future<void> _saveConsultation(OracleMessage message) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toString().split(' ')[0];
    
    // Update daily consultation count
    final newCount = _dailyConsultations + 1;
    await prefs.setInt('oracle_consultations_$today', newCount);
    
    // Add to recent messages
    final updatedRecent = [message.message, ..._recentMessages];
    if (updatedRecent.length > 5) {
      updatedRecent.removeLast();
    }
    await prefs.setStringList('oracle_recent', updatedRecent);
    
    // Save elemental affinities
    await prefs.setInt('oracle_affinity_fire', _elementalAffinities['Fire'] ?? 0);
    await prefs.setInt('oracle_affinity_water', _elementalAffinities['Water'] ?? 0);
    await prefs.setInt('oracle_affinity_earth', _elementalAffinities['Earth'] ?? 0);
    await prefs.setInt('oracle_affinity_air', _elementalAffinities['Air'] ?? 0);
    await prefs.setInt('oracle_affinity_spirit', _elementalAffinities['Spirit'] ?? 0);
    
    setState(() {
      _dailyConsultations = newCount;
      _recentMessages = updatedRecent;
    });
  }

  Future<void> _updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final todayStr = today.toString().split(' ')[0];
    final yesterdayStr = yesterday.toString().split(' ')[0];
    
    final lastConsultationDate = prefs.getString('oracle_last_consultation_date');
    
    if (lastConsultationDate == null) {
      // First time user
      setState(() {
        _streakDays = 1;
      });
      await prefs.setInt('oracle_streak_days', 1);
      await prefs.setString('oracle_last_consultation_date', todayStr);
    } else if (lastConsultationDate == yesterdayStr) {
      // Continuing streak
      final newStreak = _streakDays + 1;
      setState(() {
        _streakDays = newStreak;
      });
      await prefs.setInt('oracle_streak_days', newStreak);
      await prefs.setString('oracle_last_consultation_date', todayStr);
    } else if (lastConsultationDate != todayStr) {
      // Streak broken
      setState(() {
        _streakDays = 1;
      });
      await prefs.setInt('oracle_streak_days', 1);
      await prefs.setString('oracle_last_consultation_date', todayStr);
    }
  }

  void _showMilestoneDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A3A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.amber.shade300, size: 28),
            const SizedBox(width: 10),
            const Text(
              'Milestone!',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Continue',
              style: TextStyle(color: Colors.purple.shade300),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _crystalController.dispose();
    _particleController.dispose();
    _messageController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0A0A1A),
              const Color(0xFF1A1A3A),
              const Color(0xFF2A1A3A),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildDailyMessage(),
                    const SizedBox(height: 20),
                    _buildOracleCrystal(),
                    const SizedBox(height: 30),
                    _buildCurrentMessage(),
                    const SizedBox(height: 30),
                    _buildMoodSelector(),
                    const SizedBox(height: 20),
                    _buildElementalAffinities(),
                    const SizedBox(height: 30),
                    _buildQuickQuestions(),
                    const SizedBox(height: 20),
                    _buildCustomQuestion(),
                    const SizedBox(height: 30),
                    _buildRecentConsultations(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Colors.purple.shade300,
              Colors.blue.shade300,
              Colors.teal.shade300,
            ],
          ).createShader(bounds),
          child: const Text(
            'Crystal Oracle',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
        centerTitle: true,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.withOpacity(0.3),
                Colors.blue.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _showSettings(),
          icon: const Icon(Icons.settings, color: Colors.white70),
        ),
        IconButton(
          onPressed: () => _showOracleInfo(),
          icon: const Icon(Icons.info_outline, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildDailyMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.2),
            Colors.blue.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Colors.amber.shade300,
                size: 24,
              ),
              const SizedBox(width: 10),
              const Text(
                'Today\'s Cosmic Message',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_streakDays > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: Colors.orange.shade300,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_streakDays',
                        style: TextStyle(
                          color: Colors.orange.shade300,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            _todaysSpecialMessage ?? 'Loading your daily message...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDailyStat('Consultations', _dailyConsultations.toString(), Icons.psychology),
              _buildDailyStat('Streak', '${_streakDays} days', Icons.local_fire_department),
              _buildDailyStat('Favorites', _favoriteMessages.length.toString(), Icons.favorite),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyStat(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.7),
          size: 18,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildOracleCrystal() {
    return GestureDetector(
      onTap: () => _consultOracle(),
      child: AnimatedBuilder(
        animation: _crystalController,
        builder: (context, child) {
          return Container(
            height: 250,
            width: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Particle effects
                if (_isConsulting)
                  AnimatedBuilder(
                    animation: _particleAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(250, 250),
                        painter: ParticlePainter(_particleAnimation.value),
                      );
                    },
                  ),
                
                // Outer mystical glow
                Transform.scale(
                  scale: _crystalPulse.value,
                  child: Container(
                    height: 180,
                    width: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.purple.withOpacity(0.3),
                          Colors.blue.withOpacity(0.2),
                          Colors.cyan.withOpacity(0.1),
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.4, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
                
                // Crystal ball base/stand
                Positioned(
                  bottom: 45,
                  child: Container(
                    height: 25,
                    width: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey.shade800,
                          Colors.grey.shade600,
                          Colors.grey.shade800,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Main crystal ball
                Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.3, -0.5),
                      colors: [
                        Colors.white.withOpacity(0.8),
                        Colors.purple.shade200.withOpacity(0.6),
                        Colors.blue.shade300.withOpacity(0.7),
                        Colors.purple.shade400.withOpacity(0.8),
                        Colors.indigo.shade600.withOpacity(0.9),
                        Colors.black.withOpacity(0.3),
                      ],
                      stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Inner mystical swirls
                      Transform.rotate(
                        angle: _crystalRotation.value * 0.5,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                Colors.transparent,
                                Colors.purple.withOpacity(0.3),
                                Colors.transparent,
                                Colors.blue.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Highlight reflection
                      Positioned(
                        top: 20,
                        left: 30,
                        child: Container(
                          height: 40,
                          width: 25,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.8),
                                Colors.white.withOpacity(0.2),
                                Colors.transparent,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      
                      // Secondary smaller highlight
                      Positioned(
                        top: 35,
                        right: 40,
                        child: Container(
                          height: 15,
                          width: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      
                      // Central mystical symbol that rotates
                      Center(
                        child: Transform.rotate(
                          angle: _crystalRotation.value,
                          child: Icon(
                            Icons.auto_awesome,
                            color: Colors.white.withOpacity(0.7),
                            size: 35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Consultation overlay
                if (_isConsulting)
                  Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                
                // Floating mystical text
                if (!_isConsulting)
                  Positioned(
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.purple.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Touch to divine the future',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentMessage() {
    if (_currentMessage == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.touch_app,
              color: Colors.white.withOpacity(0.6),
              size: 40,
            ),
            const SizedBox(height: 15),
            Text(
              'Touch the crystal to receive guidance',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SlideTransition(
      position: _messageSlide,
      child: FadeTransition(
        opacity: _messageOpacity,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _currentMessage!.color.withOpacity(0.2),
                _currentMessage!.color.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _currentMessage!.color.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _currentMessage!.icon,
                    color: _currentMessage!.color,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _currentMessage!.type,
                    style: TextStyle(
                      color: _currentMessage!.color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _currentMessage!.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _currentMessage!.element,
                      style: TextStyle(
                        color: _currentMessage!.color,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                _currentMessage!.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMessageAction(
                    icon: Icons.favorite_border,
                    label: 'Save',
                    onPressed: () => _toggleFavoriteMessage(_currentMessage!.message),
                    isActive: _favoriteMessages.contains(_currentMessage!.message),
                  ),
                  _buildMessageAction(
                    icon: Icons.share,
                    label: 'Share',
                    onPressed: () => _shareMessage(_currentMessage!.message),
                  ),
                  _buildMessageAction(
                    icon: Icons.refresh,
                    label: 'New',
                    onPressed: () => _consultOracle(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickQuestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Quick Questions',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _quickQuestions.length,
            itemBuilder: (context, index) {
              final question = _quickQuestions[index];
              return Container(
                margin: const EdgeInsets.only(right: 10),
                child: ElevatedButton(
                  onPressed: () => _consultOracle(question),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: Text(
                    question,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMoodSelector() {
    final moods = {
      'neutral': {'icon': Icons.sentiment_neutral, 'color': Colors.grey},
      'happy': {'icon': Icons.sentiment_very_satisfied, 'color': Colors.yellow},
      'anxious': {'icon': Icons.sentiment_dissatisfied, 'color': Colors.orange},
      'excited': {'icon': Icons.celebration, 'color': Colors.pink},
      'peaceful': {'icon': Icons.spa, 'color': Colors.green},
      'curious': {'icon': Icons.psychology, 'color': Colors.purple},
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How are you feeling?',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: moods.length,
              itemBuilder: (context, index) {
                final moodKey = moods.keys.elementAt(index);
                final mood = moods[moodKey]!;
                final isSelected = _currentMood == moodKey;
                
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => _setMood(moodKey),
                    child: Container(
                      width: 60,
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? (mood['color'] as Color).withOpacity(0.2)
                          : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isSelected 
                            ? (mood['color'] as Color).withOpacity(0.5)
                            : Colors.white.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            mood['icon'] as IconData,
                            color: isSelected 
                              ? mood['color'] as Color
                              : Colors.white.withOpacity(0.7),
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            moodKey,
                            style: TextStyle(
                              color: isSelected 
                                ? mood['color'] as Color
                                : Colors.white.withOpacity(0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElementalAffinities() {
    final totalAffinities = _elementalAffinities.values.fold(0, (sum, value) => sum + value);
    
    if (totalAffinities == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Elemental Affinities',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          ..._elementalAffinities.entries.map((entry) {
            final percentage = totalAffinities > 0 ? (entry.value / totalAffinities) : 0.0;
            if (percentage == 0) return const SizedBox.shrink();
            
            Color elementColor = Colors.grey;
            IconData elementIcon = Icons.help;
            
            switch (entry.key) {
              case 'Fire':
                elementColor = Colors.red.shade300;
                elementIcon = Icons.local_fire_department;
                break;
              case 'Water':
                elementColor = Colors.blue.shade300;
                elementIcon = Icons.water_drop;
                break;
              case 'Earth':
                elementColor = Colors.green.shade300;
                elementIcon = Icons.eco;
                break;
              case 'Air':
                elementColor = Colors.cyan.shade300;
                elementIcon = Icons.air;
                break;
              case 'Spirit':
                elementColor = Colors.purple.shade300;
                elementIcon = Icons.auto_awesome;
                break;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(elementIcon, color: elementColor, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    entry.key,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(elementColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${(percentage * 100).round()}%',
                    style: TextStyle(
                      color: elementColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A3A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Oracle Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(
                _soundEnabled ? Icons.volume_up : Icons.volume_off,
                color: Colors.white70,
              ),
              title: const Text(
                'Sound Effects',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Switch(
                value: _soundEnabled,
                onChanged: (value) => _toggleSetting('sound', value),
                activeColor: Colors.purple.shade300,
              ),
            ),
            ListTile(
              leading: Icon(
                _hapticEnabled ? Icons.vibration : Icons.do_not_touch,
                color: Colors.white70,
              ),
              title: const Text(
                'Haptic Feedback',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Switch(
                value: _hapticEnabled,
                onChanged: (value) => _toggleSetting('haptic', value),
                activeColor: Colors.purple.shade300,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.white70),
              title: Text(
                'Favorite Messages (${_favoriteMessages.length})',
                style: const TextStyle(color: Colors.white),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
              onTap: () => _showFavoriteMessages(),
            ),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.white70),
              title: const Text(
                'Reset All Data',
                style: TextStyle(color: Colors.white),
              ),
              trailing: const Icon(Icons.warning, color: Colors.red),
              onTap: () => _showResetConfirmation(),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSetting(String setting, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      if (setting == 'sound') {
        _soundEnabled = value;
      } else if (setting == 'haptic') {
        _hapticEnabled = value;
      }
    });
    
    await prefs.setBool('oracle_${setting}_enabled', value);
    
    if (_hapticEnabled && setting == 'haptic') {
      HapticFeedback.lightImpact();
    }
  }

  void _showFavoriteMessages() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A3A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Favorite Messages',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: _favoriteMessages.isEmpty
            ? Center(
                child: Text(
                  'No favorite messages yet.\nSave messages you love!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                itemCount: _favoriteMessages.length,
                itemBuilder: (context, index) {
                  final message = _favoriteMessages[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.purple.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      message,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  );
                },
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: Colors.purple.shade300),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A3A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Reset Oracle Data',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This will reset all your Oracle data including:\n• Consultation history\n• Favorite messages\n• Elemental affinities\n• Streak counter\n\nThis action cannot be undone.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.purple.shade300),
            ),
          ),
          TextButton(
            onPressed: () async {
              await _resetAllData();
              Navigator.pop(context);
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAllData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Clear all oracle-related preferences
    final keys = prefs.getKeys().where((key) => key.startsWith('oracle_')).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
    
    // Reset state
    setState(() {
      _dailyConsultations = 0;
      _streakDays = 0;
      _recentMessages.clear();
      _favoriteMessages.clear();
      _currentMood = 'neutral';
      _elementalAffinities = {
        'Fire': 0,
        'Water': 0,
        'Earth': 0,
        'Air': 0,
        'Spirit': 0,
      };
      _currentMessage = null;
    });
    
    if (_hapticEnabled) {
      HapticFeedback.heavyImpact();
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Oracle data has been reset'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _setMood(String mood) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentMood = mood;
    });
    await prefs.setString('oracle_current_mood', mood);
    
    if (_hapticEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  Widget _buildCustomQuestion() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ask Your Own Question',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'What guidance do you seek?',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: Colors.purple.withOpacity(0.5),
                  width: 2,
                ),
              ),
              suffixIcon: IconButton(
                onPressed: () => _consultOracle(_selectedQuestion),
                icon: Icon(
                  Icons.send,
                  color: Colors.purple.shade300,
                ),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _selectedQuestion = value;
              });
            },
            onSubmitted: (value) => _consultOracle(value),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentConsultations() {
    if (_recentMessages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Recent Consultations',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 15),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _recentMessages.length,
          itemBuilder: (context, index) {
            final message = _recentMessages[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showOracleInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A3A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'About the Oracle',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'The Crystal Oracle connects you with ancient wisdom and spiritual guidance. Each consultation draws from the elements and cosmic energies to provide insights for your journey.\n\nElements:\n• Fire: Passion, Action, Transformation\n• Water: Emotion, Intuition, Healing\n• Earth: Stability, Growth, Abundance\n• Air: Communication, Ideas, Change\n• Spirit: Divine Connection, Universal Love',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: Colors.purple.shade300),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageAction({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
            ? Colors.purple.withOpacity(0.3)
            : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive 
              ? Colors.purple.withOpacity(0.5)
              : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive && icon == Icons.favorite_border ? Icons.favorite : icon,
              color: isActive ? Colors.purple.shade300 : Colors.white.withOpacity(0.8),
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.purple.shade300 : Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleFavoriteMessage(String message) async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      if (_favoriteMessages.contains(message)) {
        _favoriteMessages.remove(message);
      } else {
        _favoriteMessages.add(message);
        if (_favoriteMessages.length > 10) {
          _favoriteMessages.removeAt(0); // Keep only last 10 favorites
        }
      }
    });
    
    await prefs.setStringList('oracle_favorites', _favoriteMessages);
    
    if (_hapticEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  void _shareMessage(String message) {
    // Here you would implement sharing functionality
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Message copied: "${message.substring(0, 30)}..."'),
        backgroundColor: Colors.purple.withOpacity(0.8),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double animationValue;
  
  ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Main particles
    final mainPaint = Paint()
      ..color = Colors.purple.withOpacity(0.6 * (1 - animationValue))
      ..style = PaintingStyle.fill;

    // Secondary particles
    final secondaryPaint = Paint()
      ..color = Colors.blue.withOpacity(0.4 * (1 - animationValue))
      ..style = PaintingStyle.fill;

    // Mystical sparkles
    final sparklePaint = Paint()
      ..color = Colors.white.withOpacity(0.8 * (1 - animationValue))
      ..style = PaintingStyle.fill;

    // Draw main orbital particles
    for (int i = 0; i < 8; i++) {
      final angle = (i * pi * 2 / 8) + (animationValue * pi * 2);
      final radius = maxRadius * 0.7 * animationValue;
      final x = center.dx + cos(angle) * radius;
      final y = center.dy + sin(angle) * radius;
      
      canvas.drawCircle(
        Offset(x, y),
        6 * (1 - animationValue),
        mainPaint,
      );
    }

    // Draw secondary particles
    for (int i = 0; i < 12; i++) {
      final angle = (i * pi * 2 / 12) - (animationValue * pi * 1.5);
      final radius = maxRadius * 0.9 * animationValue;
      final x = center.dx + cos(angle) * radius;
      final y = center.dy + sin(angle) * radius;
      
      canvas.drawCircle(
        Offset(x, y),
        3 * (1 - animationValue),
        secondaryPaint,
      );
    }

    // Draw mystical sparkles
    for (int i = 0; i < 16; i++) {
      final angle = (i * pi * 2 / 16) + (animationValue * pi * 3);
      final radius = maxRadius * (0.5 + 0.3 * sin(animationValue * pi * 2)) * animationValue;
      final x = center.dx + cos(angle) * radius;
      final y = center.dy + sin(angle) * radius;
      
      // Draw cross-shaped sparkles
      final sparkleSize = 2 * (1 - animationValue);
      canvas.drawLine(
        Offset(x - sparkleSize, y),
        Offset(x + sparkleSize, y),
        sparklePaint..strokeWidth = 1,
      );
      canvas.drawLine(
        Offset(x, y - sparkleSize),
        Offset(x, y + sparkleSize),
        sparklePaint..strokeWidth = 1,
      );
    }

    // Draw flowing energy streams
    final streamPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.3 * animationValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 3; i++) {
      final path = Path();
      final startAngle = (i * pi * 2 / 3) + (animationValue * pi * 2);
      final startRadius = maxRadius * 0.3;
      final endRadius = maxRadius * 0.8 * animationValue;
      
      final startX = center.dx + cos(startAngle) * startRadius;
      final startY = center.dy + sin(startAngle) * startRadius;
      final endX = center.dx + cos(startAngle) * endRadius;
      final endY = center.dy + sin(startAngle) * endRadius;
      
      path.moveTo(startX, startY);
      path.quadraticBezierTo(
        center.dx + cos(startAngle + pi/4) * ((startRadius + endRadius) / 2),
        center.dy + sin(startAngle + pi/4) * ((startRadius + endRadius) / 2),
        endX,
        endY,
      );
      
      canvas.drawPath(path, streamPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
