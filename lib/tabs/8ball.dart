import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class Magic8BallAnswer {
  final String answer;
  final String category;
  final Color color;
  final IconData icon;
  final int rarity; // 1=common, 2=rare, 3=legendary

  Magic8BallAnswer({
    required this.answer,
    required this.category,
    required this.color,
    required this.icon,
    this.rarity = 1,
  });
}

class LuckyNumbers {
  final List<int> numbers;
  final String meaning;
  final Color color;

  LuckyNumbers({
    required this.numbers,
    required this.meaning,
    required this.color,
  });
}

class PredictionTracking {
  final String question;
  final String answer;
  final DateTime date;
  bool? cameTrue;
  String? feedback;

  PredictionTracking({
    required this.question,
    required this.answer,
    required this.date,
    this.cameTrue,
    this.feedback,
  });

  Map<String, dynamic> toJson() => {
    'question': question,
    'answer': answer,
    'date': date.toIso8601String(),
    'cameTrue': cameTrue,
    'feedback': feedback,
  };

  static PredictionTracking fromJson(Map<String, dynamic> json) => PredictionTracking(
    question: json['question'],
    answer: json['answer'],
    date: DateTime.parse(json['date']),
    cameTrue: json['cameTrue'],
    feedback: json['feedback'],
  );
}

class Magic8BallScreen extends StatefulWidget {
  final String userId;

  const Magic8BallScreen({
    super.key,
    required this.userId,
  });

  @override
  State<Magic8BallScreen> createState() => _Magic8BallScreenState();
}

class _Magic8BallScreenState extends State<Magic8BallScreen>
    with TickerProviderStateMixin {
  late AnimationController _ballController;
  late AnimationController _shakeController;
  late AnimationController _answerController;
  late AnimationController _bubbleController;
  
  late Animation<double> _ballRotation;
  late Animation<double> _ballScale;
  late Animation<Offset> _shakeAnimation;
  late Animation<double> _answerOpacity;
  late Animation<double> _answerScale;
  late Animation<double> _bubbleAnimation;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isShaking = false;
  Magic8BallAnswer? _currentAnswer;
  String _currentQuestion = '';
  List<String> _questionHistory = [];
  int _dailyQuestions = 0;
  bool _soundEnabled = true;
  bool _hapticEnabled = true;
  int _totalShakes = 0;
  
  // Enhanced features
  String _currentMode = '8ball'; // '8ball', 'fortune', 'numbers'
  String _currentMood = 'neutral'; // 'happy', 'sad', 'anxious', 'excited', 'neutral'
  String _currentTheme = 'dark'; // 'dark', 'cosmic', 'neon', 'classic'
  int _streakDays = 0;
  List<String> _favoriteAnswers = [];
  List<PredictionTracking> _predictionHistory = [];
  LuckyNumbers? _currentLuckyNumbers;
  bool _showParticles = true;
  int _totalRareAnswers = 0;
  int _totalLegendaryAnswers = 0;
  DateTime? _lastUsageDate;

  final TextEditingController _questionController = TextEditingController();

  // Classic Magic 8 Ball answers with enhanced rarity system
  final List<Magic8BallAnswer> _answers = [
    // Positive answers (green) - Common
    Magic8BallAnswer(
      answer: "It is certain",
      category: "positive",
      color: Colors.green,
      icon: Icons.check_circle,
      rarity: 1,
    ),
    Magic8BallAnswer(
      answer: "Without a doubt",
      category: "positive",
      color: Colors.green,
      icon: Icons.verified,
      rarity: 1,
    ),
    Magic8BallAnswer(
      answer: "Yes definitely",
      category: "positive",
      color: Colors.green,
      icon: Icons.thumb_up,
      rarity: 1,
    ),
    Magic8BallAnswer(
      answer: "You may rely on it",
      category: "positive",
      color: Colors.green,
      icon: Icons.handshake,
      rarity: 1,
    ),
    Magic8BallAnswer(
      answer: "As I see it, yes",
      category: "positive",
      color: Colors.green,
      icon: Icons.visibility,
      rarity: 1,
    ),
    Magic8BallAnswer(
      answer: "Most likely",
      category: "positive",
      color: Colors.green,
      icon: Icons.trending_up,
      rarity: 1,
    ),
    Magic8BallAnswer(
      answer: "Outlook good",
      category: "positive",
      color: Colors.green,
      icon: Icons.sunny,
      rarity: 1,
    ),
    Magic8BallAnswer(
      answer: "Yes",
      category: "positive",
      color: Colors.green,
      icon: Icons.done,
      rarity: 1,
    ),
    Magic8BallAnswer(
      answer: "Signs point to yes",
      category: "positive",
      color: Colors.green,
      icon: Icons.arrow_forward,
      rarity: 1,
    ),

    // Rare Positive (Gold)
    Magic8BallAnswer(
      answer: "The stars align in your favor! ✨",
      category: "positive",
      color: Colors.amber,
      icon: Icons.auto_awesome,
      rarity: 2,
    ),
    Magic8BallAnswer(
      answer: "Destiny whispers 'yes' to your soul",
      category: "positive",
      color: Colors.amber,
      icon: Icons.favorite,
      rarity: 2,
    ),

    // Legendary Positive (Rainbow)
    Magic8BallAnswer(
      answer: "🌈 COSMIC FORTUNE SMILES UPON YOU! The universe conspires for your success! 🌈",
      category: "positive",
      color: Colors.purple,
      icon: Icons.celebration,
      rarity: 3,
    ),

    // Negative answers (red) - Common
    Magic8BallAnswer(
      answer: "Don't count on it",
      category: "negative",
      color: Colors.red,
      icon: Icons.cancel,
      rarity: 1,
    ),
    Magic8BallAnswer(
      answer: "My reply is no",
      category: "negative",
      color: Colors.red,
      icon: Icons.close,
      rarity: 1,
    ),
    Magic8BallAnswer(
      answer: "My sources say no",
      category: "negative",
      color: Colors.red,
      icon: Icons.block,
      rarity: 1,
    ),
    Magic8BallAnswer(
      answer: "Outlook not so good",
      category: "negative",
      color: Colors.red,
      icon: Icons.cloud,
      rarity: 1,
    ),
    Magic8BallAnswer(
      answer: "Very doubtful",
      category: "negative",
      color: Colors.red,
      icon: Icons.help_outline,
      rarity: 1,
    ),

    // Rare Negative
    Magic8BallAnswer(
      answer: "The cosmic winds suggest patience",
      category: "negative",
      color: Colors.deepOrange,
      icon: Icons.hourglass_empty,
      rarity: 2,
    ),

    // Neutral/Non-committal answers (yellow/orange) - Common
    Magic8BallAnswer(
      answer: "Reply hazy, try again",
      category: "neutral",
      color: Colors.orange,
      icon: Icons.blur_on,
      rarity: 1,
    ),
    Magic8BallAnswer(
      answer: "Ask again later",
      category: "neutral",
      color: Colors.orange,
      icon: Icons.schedule,
      rarity: 1,
    ),
    Magic8BallAnswer(
      answer: "Better not tell you now",
      category: "neutral",
      color: Colors.orange,
      icon: Icons.lock,
      rarity: 1,
    ),
    Magic8BallAnswer(
      answer: "Cannot predict now",
      category: "neutral",
      color: Colors.orange,
      icon: Icons.hourglass_empty,
      rarity: 1,
    ),
    Magic8BallAnswer(
      answer: "Concentrate and ask again",
      category: "neutral",
      color: Colors.orange,
      icon: Icons.center_focus_strong,
      rarity: 1,
    ),

    // Legendary Neutral
    Magic8BallAnswer(
      answer: "🔮 THE MYSTIC VEIL CLOUDS THE ANSWER - DESTINY REMAINS UNWRITTEN 🔮",
      category: "neutral",
      color: Colors.cyan,
      icon: Icons.psychology,
      rarity: 3,
    ),
  ];

  // Fortune Cookie Wisdom
  final List<Magic8BallAnswer> _fortuneAnswers = [
    Magic8BallAnswer(
      answer: "A journey of a thousand miles begins with a single step",
      category: "wisdom",
      color: Colors.deepPurple,
      icon: Icons.directions_walk,
      rarity: 1,
    ),
    Magic8BallAnswer(
      answer: "Your future is created by what you do today",
      category: "wisdom",
      color: Colors.indigo,
      icon: Icons.today,
      rarity: 1,
    ),
    Magic8BallAnswer(
      answer: "The best time to plant a tree was 20 years ago. The second best time is now",
      category: "wisdom",
      color: Colors.green,
      icon: Icons.eco,
      rarity: 1,
    ),
    Magic8BallAnswer(
      answer: "Kindness is a language the deaf can hear and the blind can see",
      category: "wisdom",
      color: Colors.pink,
      icon: Icons.favorite,
      rarity: 1,
    ),
    Magic8BallAnswer(
      answer: "The greatest glory is not in never falling, but in rising every time we fall",
      category: "wisdom",
      color: Colors.orange,
      icon: Icons.trending_up,
      rarity: 1,
    ),
    Magic8BallAnswer(
      answer: "✨ Your inner light shines brighter than any external darkness ✨",
      category: "wisdom",
      color: Colors.amber,
      icon: Icons.lightbulb,
      rarity: 2,
    ),
    Magic8BallAnswer(
      answer: "🌟 THE UNIVERSE HAS BEEN PREPARING YOU FOR SOMETHING MAGNIFICENT 🌟",
      category: "wisdom",
      color: Colors.purple,
      icon: Icons.auto_awesome,
      rarity: 3,
    ),
  ];

  final List<String> _funQuestions = [
    "Will I find love today?",
    "Should I eat that extra slice of pizza?",
    "Will it rain tomorrow?",
    "Is my crush thinking about me?",
    "Should I take that job offer?",
    "Will I win the lottery?",
    "Is today my lucky day?",
    "Should I call in sick?",
    "Will my team win?",
    "Is it time for a vacation?",
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadDailyData();
  }

  void _setupAnimations() {
    // Ball rotation and scale animation
    _ballController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Shake animation
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Answer reveal animation
    _answerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Bubble animation for background effect
    _bubbleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _ballRotation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _ballController,
      curve: Curves.easeInOut,
    ));

    _ballScale = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _ballController,
      curve: Curves.elasticOut,
    ));

    _shakeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.1, 0),
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticInOut,
    ));

    _answerOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _answerController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    ));

    _answerScale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _answerController,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
    ));

    _bubbleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _bubbleController,
      curve: Curves.linear,
    ));

    // Start bubble animation
    _bubbleController.repeat();
  }

  Future<void> _loadDailyData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toString().split(' ')[0];
    
    setState(() {
      _dailyQuestions = prefs.getInt('8ball_questions_$today') ?? 0;
      _questionHistory = prefs.getStringList('8ball_history') ?? [];
      _soundEnabled = prefs.getBool('8ball_sound_enabled') ?? true;
      _hapticEnabled = prefs.getBool('8ball_haptic_enabled') ?? true;
      _totalShakes = prefs.getInt('8ball_total_shakes') ?? 0;
      
      // Enhanced features
      _currentMode = prefs.getString('8ball_mode') ?? '8ball';
      _currentMood = prefs.getString('8ball_mood') ?? 'neutral';
      _currentTheme = prefs.getString('8ball_theme') ?? 'dark';
      _streakDays = prefs.getInt('8ball_streak') ?? 0;
      _favoriteAnswers = prefs.getStringList('8ball_favorites') ?? [];
      _showParticles = prefs.getBool('8ball_particles') ?? true;
      _totalRareAnswers = prefs.getInt('8ball_rare_count') ?? 0;
      _totalLegendaryAnswers = prefs.getInt('8ball_legendary_count') ?? 0;
      
      // Load prediction history
      final historyJson = prefs.getStringList('8ball_predictions') ?? [];
      _predictionHistory = historyJson.map((json) {
        try {
          return PredictionTracking.fromJson(Map<String, dynamic>.from(
            Map.fromEntries(json.split('|').map((e) => MapEntry(e.split(':')[0], e.split(':')[1])))
          ));
        } catch (e) {
          return null;
        }
      }).where((p) => p != null).cast<PredictionTracking>().toList();
    });

    // Update streak
    await _updateStreak();
  }

  Future<void> _shake8Ball() async {
    if (_isShaking) return;

    String question = _questionController.text.trim();
    if (question.isEmpty) {
      // Use a random fun question
      question = _funQuestions[Random().nextInt(_funQuestions.length)];
      _questionController.text = question;
    }

    if (_hapticEnabled) {
      HapticFeedback.heavyImpact();
    }

    setState(() {
      _isShaking = true;
      _currentAnswer = null;
      _currentQuestion = question;
      _currentLuckyNumbers = null;
    });

    // Play shake sound
    if (_soundEnabled) {
      try {
        await _audioPlayer.play(AssetSource('sounds/shake.mp3'));
      } catch (e) {
        // Sound file doesn't exist, continue without sound
      }
    }

    // Start animations
    _ballController.forward(from: 0);
    _shakeController.forward(from: 0);

    // Simulate thinking time based on mode
    final thinkingTime = _currentMode == 'numbers' ? 2000 : 
                        _currentMode == 'fortune' ? 2500 : 1500;
    await Future.delayed(Duration(milliseconds: thinkingTime));

    if (_currentMode == 'numbers') {
      await _generateLuckyNumbers();
    } else {
      await _generateAnswer();
    }

    setState(() {
      _isShaking = false;
    });

    // Animate answer reveal
    _answerController.forward(from: 0);

    // Additional haptic feedback for answer
    if (_hapticEnabled) {
      await Future.delayed(const Duration(milliseconds: 300));
      HapticFeedback.lightImpact();
    }

    // Save question and answer
    await _saveQuestion(question);

    // Clear question field for next use
    _questionController.clear();
  }

  Future<void> _generateAnswer() async {
    final random = Random();
    final answerPool = _currentMode == 'fortune' ? _fortuneAnswers : _answers;
    
    // Apply mood and streak bonuses for rare answers
    double rareChance = 0.1; // 10% base chance
    double legendaryChance = 0.01; // 1% base chance
    
    // Mood bonuses
    if (_currentMood == 'happy') {
      rareChance += 0.05;
      legendaryChance += 0.005;
    } else if (_currentMood == 'excited') {
      rareChance += 0.1;
      legendaryChance += 0.01;
    }
    
    // Streak bonuses
    if (_streakDays >= 7) {
      rareChance += 0.1;
      legendaryChance += 0.02;
    }
    if (_streakDays >= 30) {
      rareChance += 0.2;
      legendaryChance += 0.05;
    }

    // Determine rarity
    final rarityRoll = random.nextDouble();
    int targetRarity = 1;
    if (rarityRoll < legendaryChance) {
      targetRarity = 3;
    } else if (rarityRoll < rareChance) {
      targetRarity = 2;
    }

    // Filter answers by rarity
    var filteredAnswers = answerPool.where((a) => a.rarity == targetRarity).toList();
    if (filteredAnswers.isEmpty) {
      filteredAnswers = answerPool.where((a) => a.rarity == 1).toList();
    }

    final selectedAnswer = filteredAnswers[random.nextInt(filteredAnswers.length)];
    
    // Track rare answers
    if (selectedAnswer.rarity == 2) {
      _totalRareAnswers++;
      await SharedPreferences.getInstance().then((prefs) => 
        prefs.setInt('8ball_rare_count', _totalRareAnswers));
    } else if (selectedAnswer.rarity == 3) {
      _totalLegendaryAnswers++;
      await SharedPreferences.getInstance().then((prefs) => 
        prefs.setInt('8ball_legendary_count', _totalLegendaryAnswers));
      
      // Special celebration for legendary
      if (_hapticEnabled) {
        for (int i = 0; i < 3; i++) {
          await Future.delayed(const Duration(milliseconds: 100));
          HapticFeedback.heavyImpact();
        }
      }
    }

    setState(() {
      _currentAnswer = selectedAnswer;
    });
  }

  Future<void> _generateLuckyNumbers() async {
    final random = Random();
    final numbers = <int>[];
    
    // Generate 6 lucky numbers based on current mood and question
    final baseNumbers = [1, 7, 13, 21, 33, 42]; // Base lucky numbers
    
    for (int i = 0; i < 6; i++) {
      int number;
      if (_currentMood == 'happy') {
        number = random.nextInt(50) + 1; // 1-50 for happy
      } else if (_currentMood == 'excited') {
        number = random.nextInt(99) + 1; // 1-99 for excited
      } else {
        number = random.nextInt(30) + 1; // 1-30 for neutral/others
      }
      
      if (!numbers.contains(number)) {
        numbers.add(number);
      } else {
        i--; // Retry if duplicate
      }
    }
    
    numbers.sort();
    
    final meanings = [
      "These numbers carry the energy of new beginnings",
      "Fortune favors these mystical digits",
      "The cosmic alignment points to these numbers",
      "Your spiritual guides whisper these numbers",
      "These numbers vibrate with your current energy",
    ];
    
    setState(() {
      _currentLuckyNumbers = LuckyNumbers(
        numbers: numbers,
        meaning: meanings[random.nextInt(meanings.length)],
        color: _currentMood == 'happy' ? Colors.amber : 
               _currentMood == 'excited' ? Colors.pink : 
               Colors.purple,
      );
    });
  }

  Future<void> _updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = today.toString().split(' ')[0];
    final lastUsage = prefs.getString('8ball_last_usage');
    
    if (lastUsage == null || lastUsage != todayStr) {
      // Check if yesterday
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayStr = yesterday.toString().split(' ')[0];
      
      if (lastUsage == yesterdayStr) {
        // Continue streak
        setState(() {
          _streakDays++;
        });
        await prefs.setInt('8ball_streak', _streakDays);
      } else {
        // Reset streak
        setState(() {
          _streakDays = 1;
        });
        await prefs.setInt('8ball_streak', 1);
      }
      
      await prefs.setString('8ball_last_usage', todayStr);
    }
  }

  Future<void> _saveQuestion(String question) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toString().split(' ')[0];
    
    // Update daily count
    final newCount = _dailyQuestions + 1;
    await prefs.setInt('8ball_questions_$today', newCount);
    
    // Update total shakes
    final newTotal = _totalShakes + 1;
    await prefs.setInt('8ball_total_shakes', newTotal);
    
    // Add to history
    final updatedHistory = [question, ..._questionHistory];
    if (updatedHistory.length > 20) {
      updatedHistory.removeLast();
    }
    await prefs.setStringList('8ball_history', updatedHistory);
    
    setState(() {
      _dailyQuestions = newCount;
      _totalShakes = newTotal;
      _questionHistory = updatedHistory;
    });
  }

  void _clearAnswer() {
    setState(() {
      _currentAnswer = null;
      _currentLuckyNumbers = null;
    });
    _answerController.reset();
    _ballController.reset();
    _shakeController.reset();
  }

  void _toggleFavorite(String answer) async {
    setState(() {
      if (_favoriteAnswers.contains(answer)) {
        _favoriteAnswers.remove(answer);
      } else {
        _favoriteAnswers.add(answer);
      }
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('8ball_favorites', _favoriteAnswers);
    
    if (_hapticEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  void _shareAnswer() {
    if (_currentAnswer != null) {
      final text = 'Magic 8-Ball says: "${_currentAnswer!.answer}"\nQuestion: $_currentQuestion\n\nShared from Crystal Social 🎱';
      Clipboard.setData(ClipboardData(text: text));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Answer copied to clipboard!'),
          backgroundColor: _currentAnswer!.color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareNumbers() {
    if (_currentLuckyNumbers != null) {
      final numbersText = _currentLuckyNumbers!.numbers.join(', ');
      final text = 'My Lucky Numbers: $numbersText\n${_currentLuckyNumbers!.meaning}\nQuestion: $_currentQuestion\n\nShared from Crystal Social 🔢';
      Clipboard.setData(ClipboardData(text: text));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lucky numbers copied to clipboard!'),
          backgroundColor: _currentLuckyNumbers!.color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _copyNumbers() {
    if (_currentLuckyNumbers != null) {
      final numbersText = _currentLuckyNumbers!.numbers.join(', ');
      Clipboard.setData(ClipboardData(text: numbersText));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Numbers copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showPredictionTracking() {
    if (_currentAnswer == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Track This Prediction',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question: $_currentQuestion',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Answer: "${_currentAnswer!.answer}"',
              style: TextStyle(
                color: _currentAnswer!.color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'We\'ll remind you to check if this prediction came true!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _addPredictionTracking();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentAnswer!.color,
              foregroundColor: Colors.white,
            ),
            child: const Text('Track It'),
          ),
        ],
      ),
    );
  }

  void _addPredictionTracking() async {
    if (_currentAnswer == null) return;
    
    final prediction = PredictionTracking(
      question: _currentQuestion,
      answer: _currentAnswer!.answer,
      date: DateTime.now(),
    );
    
    setState(() {
      _predictionHistory.add(prediction);
    });
    
    // Save to preferences (simplified format)
    final prefs = await SharedPreferences.getInstance();
    final historyJson = _predictionHistory.map((p) => 
      'question:${p.question}|answer:${p.answer}|date:${p.date.toIso8601String()}'
    ).toList();
    await prefs.setStringList('8ball_predictions', historyJson);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Prediction added to tracking!'),
        backgroundColor: _currentAnswer!.color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            border: Border.all(
              color: Colors.purple.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(8),
                height: 4,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.history, color: Colors.purple.shade300),
                    const SizedBox(width: 10),
                    const Text(
                      'Question History',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _questionHistory.isEmpty
                    ? Center(
                        child: Text(
                          'No questions asked yet.\nShake the 8-ball to start!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _questionHistory.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _questionHistory[index],
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.settings, color: _getThemeColors().first),
            const SizedBox(width: 10),
            const Text(
              'Settings & Preferences',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sound & Haptics
              SwitchListTile(
                title: const Text(
                  'Sound Effects',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Play sounds when shaking',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                value: _soundEnabled,
                activeColor: _getThemeColors().first,
                onChanged: (value) async {
                  setState(() {
                    _soundEnabled = value;
                  });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('8ball_sound_enabled', value);
                },
              ),
              SwitchListTile(
                title: const Text(
                  'Haptic Feedback',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Vibrate on interactions',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                value: _hapticEnabled,
                activeColor: _getThemeColors().first,
                onChanged: (value) async {
                  setState(() {
                    _hapticEnabled = value;
                  });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('8ball_haptic_enabled', value);
                },
              ),
              SwitchListTile(
                title: const Text(
                  'Particle Effects',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Show magical particles',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                value: _showParticles,
                activeColor: _getThemeColors().first,
                onChanged: (value) async {
                  setState(() {
                    _showParticles = value;
                  });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('8ball_particles', value);
                },
              ),
              
              const Divider(color: Colors.white24),
              
              // Theme Selector
              ListTile(
                title: const Text(
                  'Visual Theme',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  _getThemeName(),
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                trailing: Icon(Icons.palette, color: _getThemeColors().first),
                onTap: () => _showThemeSelector(),
              ),
              
              const Divider(color: Colors.white24),
              
              // Statistics
              ListTile(
                title: const Text(
                  'View Statistics',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Detailed usage stats',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                trailing: Icon(Icons.bar_chart, color: _getThemeColors().first),
                onTap: () {
                  Navigator.pop(context);
                  _showDetailedStats();
                },
              ),
              
              ListTile(
                title: const Text(
                  'Prediction History',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${_predictionHistory.length} tracked predictions',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                trailing: Icon(Icons.track_changes, color: _getThemeColors().first),
                onTap: () {
                  Navigator.pop(context);
                  _showPredictionHistory();
                },
              ),
              
              const Divider(color: Colors.white24),
              
              // Reset Options
              ListTile(
                title: const Text(
                  'Reset All Data',
                  style: TextStyle(color: Colors.red),
                ),
                subtitle: Text(
                  'Clear history and preferences',
                  style: TextStyle(color: Colors.red.withOpacity(0.7)),
                ),
                trailing: const Icon(Icons.delete_forever, color: Colors.red),
                onTap: () => _showResetConfirmation(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: _getThemeColors().first),
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Choose Theme', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption('dark', 'Dark Magic', [Colors.purple, Colors.blue]),
            _buildThemeOption('cosmic', 'Cosmic Dreams', [Colors.deepPurple, Colors.indigo, Colors.blue]),
            _buildThemeOption('neon', 'Neon Glow', [Colors.cyan, Colors.pink, Colors.purple]),
            _buildThemeOption('classic', 'Classic Mystic', [Colors.brown, Colors.amber, Colors.orange]),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(String theme, String name, List<Color> colors) {
    final isSelected = _currentTheme == theme;
    return GestureDetector(
      onTap: () => _setTheme(theme),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.first : Colors.white.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? colors.first : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              Icon(Icons.check, color: colors.first),
            ],
          ],
        ),
      ),
    );
  }

  String _getThemeName() {
    switch (_currentTheme) {
      case 'cosmic': return 'Cosmic Dreams';
      case 'neon': return 'Neon Glow';
      case 'classic': return 'Classic Mystic';
      default: return 'Dark Magic';
    }
  }

  void _setTheme(String theme) async {
    setState(() {
      _currentTheme = theme;
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('8ball_theme', theme);
    
    Navigator.pop(context);
    
    if (_hapticEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  void _showDetailedStats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.bar_chart, color: _getThemeColors().first),
            const SizedBox(width: 10),
            const Text('Your Statistics', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Total Questions Asked', _totalShakes.toString()),
            _buildStatRow('Current Streak', '$_streakDays days'),
            _buildStatRow('Rare Answers Found', _totalRareAnswers.toString()),
            _buildStatRow('Legendary Answers', _totalLegendaryAnswers.toString()),
            _buildStatRow('Favorite Answers', _favoriteAnswers.length.toString()),
            _buildStatRow('Tracked Predictions', _predictionHistory.length.toString()),
            _buildStatRow('Question History', _questionHistory.length.toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: _getThemeColors().first)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
          Text(
            value,
            style: TextStyle(
              color: _getThemeColors().first,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showPredictionHistory() {
    // Implementation for prediction history view
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Prediction history feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset All Data?', style: TextStyle(color: Colors.red)),
        content: const Text(
          'This will permanently delete all your questions, history, favorites, and reset your streak. This action cannot be undone.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              _resetAllData();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _resetAllData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Clear all 8-ball related data
    final keys = prefs.getKeys().where((key) => key.startsWith('8ball')).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
    
    // Reset state
    setState(() {
      _dailyQuestions = 0;
      _questionHistory.clear();
      _totalShakes = 0;
      _streakDays = 0;
      _favoriteAnswers.clear();
      _predictionHistory.clear();
      _totalRareAnswers = 0;
      _totalLegendaryAnswers = 0;
      _currentAnswer = null;
      _currentLuckyNumbers = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All data has been reset!'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _ballController.dispose();
    _shakeController.dispose();
    _answerController.dispose();
    _bubbleController.dispose();
    _questionController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F0F23),
              const Color(0xFF16213E),
              const Color(0xFF1A1A2E),
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
                    _buildStatsCard(),
                    const SizedBox(height: 30),
                    _buildMagic8Ball(),
                    const SizedBox(height: 30),
                    _buildAnswerDisplay(),
                    const SizedBox(height: 30),
                    _buildQuestionInput(),
                    const SizedBox(height: 20),
                    _buildQuickQuestions(),
                    const SizedBox(height: 30),
                    _buildActionButtons(),
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
              Colors.cyan.shade300,
            ],
          ).createShader(bounds),
          child: const Text(
            'Magic 8-Ball',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
        centerTitle: true,
      ),
      actions: [
        IconButton(
          onPressed: _showHistory,
          icon: const Icon(Icons.history, color: Colors.white70),
        ),
        IconButton(
          onPressed: _showSettings,
          icon: const Icon(Icons.settings, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getThemeColors().first.withOpacity(0.2),
            _getThemeColors().last.withOpacity(0.2),
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
          // Mode Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildModeButton('8ball', '🎱', 'Magic 8-Ball'),
              _buildModeButton('fortune', '🥠', 'Fortune Cookie'),
              _buildModeButton('numbers', '🔢', 'Lucky Numbers'),
            ],
          ),
          const SizedBox(height: 20),
          
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('Today', _dailyQuestions.toString(), Icons.today),
              _buildStat('Streak', '${_streakDays} days', Icons.local_fire_department),
              _buildStat('Total', _totalShakes.toString(), Icons.all_inclusive),
            ],
          ),
          
          // Achievements
          if (_totalRareAnswers > 0 || _totalLegendaryAnswers > 0) ...[
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (_totalRareAnswers > 0)
                  _buildAchievement('⭐ Rare', _totalRareAnswers.toString(), Colors.amber),
                if (_totalLegendaryAnswers > 0)
                  _buildAchievement('🌟 Legendary', _totalLegendaryAnswers.toString(), Colors.purple),
                _buildAchievement('💫 Favorites', _favoriteAnswers.length.toString(), Colors.pink),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeButton(String mode, String emoji, String label) {
    final isSelected = _currentMode == mode;
    return GestureDetector(
      onTap: () => _switchMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Colors.white.withOpacity(0.5) : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: TextStyle(
                fontSize: isSelected ? 24 : 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(isSelected ? 1.0 : 0.7),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievement(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getThemeColors() {
    switch (_currentTheme) {
      case 'cosmic':
        return [Colors.deepPurple, Colors.indigo, Colors.blue];
      case 'neon':
        return [Colors.cyan, Colors.pink, Colors.purple];
      case 'classic':
        return [Colors.brown, Colors.amber, Colors.orange];
      default: // dark
        return [Colors.purple, Colors.blue];
    }
  }

  void _switchMode(String mode) async {
    setState(() {
      _currentMode = mode;
      _currentAnswer = null;
      _currentLuckyNumbers = null;
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('8ball_mode', mode);
    
    if (_hapticEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.7),
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMagic8Ball() {
    return GestureDetector(
      onTap: _shake8Ball,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _ballController,
          _shakeController,
          _bubbleController,
        ]),
        builder: (context, child) {
          return SlideTransition(
            position: _shakeAnimation,
            child: Transform.scale(
              scale: _ballScale.value,
              child: Transform.rotate(
                angle: _ballRotation.value,
                child: Container(
                  height: 250,
                  width: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Enhanced magical bubble effects
                      if (_showParticles) ...[
                        ...List.generate(8, (index) {
                          final offset = Offset(
                            cos((_bubbleAnimation.value * 2 * pi) + (index * pi / 4)) * 90,
                            sin((_bubbleAnimation.value * 2 * pi) + (index * pi / 4)) * 90,
                          );
                          return Transform.translate(
                            offset: offset,
                            child: Container(
                              width: 6 + (index % 3) * 2,
                              height: 6 + (index % 3) * 2,
                              decoration: BoxDecoration(
                                color: _getThemeColors()[index % _getThemeColors().length].withOpacity(0.6),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _getThemeColors()[index % _getThemeColors().length].withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                      
                      // Outer glow with theme colors
                      Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _getThemeColors().first.withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                      
                      // Main 8-ball with enhanced visual
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: _currentMode == 'fortune' ? [
                              Colors.brown.shade600,
                              Colors.brown.shade800,
                            ] : _currentMode == 'numbers' ? [
                              Colors.indigo.shade600,
                              Colors.indigo.shade900,
                            ] : [
                              Colors.grey.shade800,
                              Colors.black,
                            ],
                            stops: const [0.3, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.6),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Enhanced highlight
                            Positioned(
                              top: 30,
                              left: 50,
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.6),
                                      Colors.white.withOpacity(0.2),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            
                            // Center window with mode-specific content
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF001122),
                                border: Border.all(
                                  color: _getThemeColors().first.withOpacity(0.8),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getThemeColors().first.withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _buildCenterContent(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Enhanced loading indicator when shaking
                      if (_isShaking)
                        Container(
                          width: 220,
                          height: 220,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getThemeColors().first,
                            ),
                          ),
                        ),
                      
                      // Rarity effects for special answers
                      if (_currentAnswer?.rarity == 2)
                        Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.8),
                              width: 3,
                            ),
                          ),
                        ),
                      if (_currentAnswer?.rarity == 3)
                        Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.purple.withOpacity(0.9),
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCenterContent() {
    if (_currentMode == 'fortune') {
      return Text(
        '🥠',
        style: TextStyle(
          fontSize: 32,
          shadows: [
            Shadow(
              color: Colors.orange.withOpacity(0.5),
              blurRadius: 10,
            ),
          ],
        ),
      );
    } else if (_currentMode == 'numbers') {
      return Text(
        '🔢',
        style: TextStyle(
          fontSize: 32,
          shadows: [
            Shadow(
              color: Colors.cyan.withOpacity(0.5),
              blurRadius: 10,
            ),
          ],
        ),
      );
    } else {
      return Text(
        '8',
        style: TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: _getThemeColors().first.withOpacity(0.5),
              blurRadius: 10,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildAnswerDisplay() {
    if (_currentAnswer == null && _currentLuckyNumbers == null) {
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
              _currentMode == 'numbers' ? Icons.casino : 
              _currentMode == 'fortune' ? Icons.cookie :
              Icons.help_outline,
              color: Colors.white.withOpacity(0.3),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _isShaking 
                  ? _currentMode == 'numbers' ? 'Generating your lucky numbers...' :
                    _currentMode == 'fortune' ? 'Opening your fortune cookie...' :
                    'The magic 8-ball is thinking...'
                  : _currentMode == 'numbers' ? 'Ask a question to reveal your lucky numbers' :
                    _currentMode == 'fortune' ? 'Ask a question to receive ancient wisdom' :
                    'Ask a question and shake the 8-ball',
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

    if (_currentLuckyNumbers != null) {
      return _buildLuckyNumbersDisplay();
    }

    return FadeTransition(
      opacity: _answerOpacity,
      child: ScaleTransition(
        scale: _answerScale,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _currentAnswer!.color.withOpacity(0.2),
                _currentAnswer!.color.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _currentAnswer!.color.withOpacity(0.5),
              width: _currentAnswer!.rarity > 1 ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _currentAnswer!.color.withOpacity(0.3),
                blurRadius: _currentAnswer!.rarity == 3 ? 25 : 15,
                spreadRadius: _currentAnswer!.rarity == 3 ? 4 : 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _currentAnswer!.icon,
                    color: _currentAnswer!.color,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _currentMode == 'fortune' ? 'Ancient Wisdom:' : 'The 8-Ball Says:',
                    style: TextStyle(
                      color: _currentAnswer!.color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_currentAnswer!.rarity > 1) ...[
                    const SizedBox(width: 8),
                    Text(
                      _currentAnswer!.rarity == 2 ? '⭐' : '🌟',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 15),
              Text(
                '"${_currentAnswer!.answer}"',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _currentAnswer!.rarity == 3 ? 22 : 20,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              if (_currentQuestion.isNotEmpty) ...[
                const SizedBox(height: 15),
                Text(
                  'Question: $_currentQuestion',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 15),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAnswerAction(
                    icon: _favoriteAnswers.contains(_currentAnswer!.answer) 
                        ? Icons.favorite : Icons.favorite_border,
                    label: 'Favorite',
                    onTap: () => _toggleFavorite(_currentAnswer!.answer),
                    color: Colors.pink,
                  ),
                  _buildAnswerAction(
                    icon: Icons.share,
                    label: 'Share',
                    onTap: () => _shareAnswer(),
                    color: Colors.blue,
                  ),
                  _buildAnswerAction(
                    icon: Icons.track_changes,
                    label: 'Track',
                    onTap: () => _showPredictionTracking(),
                    color: Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLuckyNumbersDisplay() {
    return FadeTransition(
      opacity: _answerOpacity,
      child: ScaleTransition(
        scale: _answerScale,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _currentLuckyNumbers!.color.withOpacity(0.2),
                _currentLuckyNumbers!.color.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _currentLuckyNumbers!.color.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _currentLuckyNumbers!.color.withOpacity(0.3),
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
                  Icon(
                    Icons.casino,
                    color: _currentLuckyNumbers!.color,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Your Lucky Numbers:',
                    style: TextStyle(
                      color: _currentLuckyNumbers!.color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Numbers display
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: _currentLuckyNumbers!.numbers.map((number) {
                  return Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _currentLuckyNumbers!.color.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: _currentLuckyNumbers!.color,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        number.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 20),
              Text(
                _currentLuckyNumbers!.meaning,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              
              if (_currentQuestion.isNotEmpty) ...[
                const SizedBox(height: 15),
                Text(
                  'Question: $_currentQuestion',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              
              const SizedBox(height: 15),
              
              // Action buttons for numbers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAnswerAction(
                    icon: Icons.copy,
                    label: 'Copy',
                    onTap: () => _copyNumbers(),
                    color: Colors.blue,
                  ),
                  _buildAnswerAction(
                    icon: Icons.share,
                    label: 'Share',
                    onTap: () => _shareNumbers(),
                    color: Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionInput() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Ask Your Question',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _buildMoodSelector(),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _questionController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: _getHintTextForMode(),
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                suffixIcon: IconButton(
                  onPressed: () {
                    if (_questionController.text.isNotEmpty) {
                      _shake8Ball();
                    }
                  },
                  icon: Icon(
                    Icons.send,
                    color: _getThemeColors().first,
                  ),
                ),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _shake8Ball(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSelector() {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getMoodColor().withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getMoodColor().withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_getMoodEmoji(), style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              _currentMood,
              style: TextStyle(
                color: _getMoodColor(),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      color: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        _buildMoodMenuItem('neutral', '😐', 'Neutral'),
        _buildMoodMenuItem('happy', '😊', 'Happy'),
        _buildMoodMenuItem('sad', '😢', 'Sad'),
        _buildMoodMenuItem('excited', '🤩', 'Excited'),
        _buildMoodMenuItem('anxious', '😰', 'Anxious'),
        _buildMoodMenuItem('curious', '🤔', 'Curious'),
      ],
      onSelected: (mood) => _setMood(mood),
    );
  }

  PopupMenuItem<String> _buildMoodMenuItem(String mood, String emoji, String label) {
    return PopupMenuItem<String>(
      value: mood,
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: mood == _currentMood ? _getMoodColor() : Colors.white,
              fontWeight: mood == _currentMood ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _getHintTextForMode() {
    switch (_currentMode) {
      case 'fortune':
        return 'Seek ancient wisdom...';
      case 'numbers':
        return 'Ask for your lucky numbers...';
      default:
        return 'Type your question here...';
    }
  }

  String _getMoodEmoji() {
    switch (_currentMood) {
      case 'happy': return '😊';
      case 'sad': return '😢';
      case 'excited': return '🤩';
      case 'anxious': return '😰';
      case 'curious': return '🤔';
      default: return '😐';
    }
  }

  Color _getMoodColor() {
    switch (_currentMood) {
      case 'happy': return Colors.yellow;
      case 'sad': return Colors.blue;
      case 'excited': return Colors.pink;
      case 'anxious': return Colors.orange;
      case 'curious': return Colors.purple;
      default: return Colors.grey;
    }
  }

  void _setMood(String mood) async {
    setState(() {
      _currentMood = mood;
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('8ball_mood', mood);
    
    if (_hapticEnabled) {
      HapticFeedback.selectionClick();
    }
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _funQuestions.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    _questionController.text = _funQuestions[index];
                    _shake8Ball();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.purple.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _funQuestions[index],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _shake8Ball,
              icon: const Icon(Icons.shuffle),
              label: const Text('Shake 8-Ball'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (_currentAnswer != null)
            ElevatedButton(
              onPressed: _clearAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Icon(Icons.refresh),
            ),
        ],
      ),
    );
  }
}
