import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math' as math;
import 'dart:async';

class CursedPollScreen extends StatefulWidget {
  const CursedPollScreen({super.key});

  @override
  _CursedPollScreenState createState() => _CursedPollScreenState();
}

class _CursedPollScreenState extends State<CursedPollScreen> with TickerProviderStateMixin {
  final TextEditingController _pollController = TextEditingController();
  final TextEditingController _option1Controller = TextEditingController();
  final TextEditingController _option2Controller = TextEditingController();
  final TextEditingController _option3Controller = TextEditingController();
  final TextEditingController _option4Controller = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Enhanced state management
  bool _isPollCreated = false;
  bool _isVoting = false;
  bool _showVotingResults = false;
  final List<int> _votes = [0, 0, 0, 0];
  List<String> _options = [];
  int? _userVote;
  String _dramaticMessage = '';
  
  // Theme system
  String _selectedTheme = 'mystic_purple';
  final List<String> _themes = [
    'mystic_purple', 'blood_moon', 'forest_witch', 'cosmic_void', 'toxic_green'
  ];
  
  final Map<String, IconData> _themeIcons = {
    'mystic_purple': Icons.auto_awesome,
    'blood_moon': Icons.nights_stay,
    'forest_witch': Icons.nature,
    'cosmic_void': Icons.blur_circular,
    'toxic_green': Icons.local_fire_department,
  };
  
  final Map<String, Map<String, Color>> _themeColors = {
    'mystic_purple': {
      'primary': Color(0xFF4A148C),
      'secondary': Color(0xFF7B1FA2),
      'accent': Color(0xFFE1BEE7),
      'background': Color(0xFF1A0033),
      'text': Colors.white,
    },
    'blood_moon': {
      'primary': Color(0xFF8B0000),
      'secondary': Color(0xFFDC143C),
      'accent': Color(0xFFFF6B6B),
      'background': Color(0xFF2D0000),
      'text': Colors.white,
    },
    'forest_witch': {
      'primary': Color(0xFF2E7D32),
      'secondary': Color(0xFF388E3C),
      'accent': Color(0xFF81C784),
      'background': Color(0xFF0D2818),
      'text': Colors.white,
    },
    'cosmic_void': {
      'primary': Color(0xFF1A237E),
      'secondary': Color(0xFF303F9F),
      'accent': Color(0xFF9FA8DA),
      'background': Color(0xFF000051),
      'text': Colors.white,
    },
    'toxic_green': {
      'primary': Color(0xFF33691E),
      'secondary': Color(0xFF689F38),
      'accent': Color(0xFFAED581),
      'background': Color(0xFF1B5E20),
      'text': Colors.white,
    },
  };
  
  // Animation controllers for dramatic effects
  late AnimationController _sparkleController;
  late AnimationController _revealController;
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late AnimationController _floatController;
  
  // Animations
  late Animation<double> _sparkleAnimation;
  late Animation<double> _revealAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _floatAnimation;
  
  // Dramatic effects
  List<Map<String, dynamic>> _floatingEmojis = [];
  Timer? _emojiTimer;
  
  final List<String> _dramaticMessages = [
    'The cosmos have spoken! ✨',
    'Destiny unfolds before us! 🌟',
    'The ancient powers stir! ⚡',
    'Fate weaves its tapestry! 🌙',
    'The spirits whisper truth! 👻',
    'Time reveals its secrets! ⏰',
    'The void echoes with answers! 🌌',
    'Magic courses through reality! 🔮',
    'The eternal dance continues! 💫',
    'Wisdom flows like starlight! ⭐'
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _sparkleController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    
    _revealController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _shakeController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    
    _floatController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    // Initialize animations
    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeOut),
    );
    
    _revealAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.elasticOut),
    );
    
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticInOut),
    );
    
    _shakeAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    
    _floatAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    
    // Start the floating animation and reveal when poll is created
    _revealController.forward();
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    _revealController.dispose();
    _pulseController.dispose();
    _shakeController.dispose();
    _floatController.dispose();
    _audioPlayer.dispose();
    _emojiTimer?.cancel();
    super.dispose();
  }

  // Enhanced method to create sparkle explosion with floating emojis
  void _showSparkleExplosion() {
    // Create floating emojis
    _floatingEmojis.clear();
    List<String> emojis = ['✨', '🌟', '⚡', '💫', '🔮', '🌙', '👻', '🎭'];
    
    for (int i = 0; i < 8; i++) {
      String randomEmoji = emojis[math.Random().nextInt(emojis.length)];
      _floatingEmojis.add({
        'emoji': randomEmoji,
        'x': math.Random().nextDouble() * 300,
        'y': math.Random().nextDouble() * 100 + 100,
      });
    }
    
    // Trigger sparkle animation
    _sparkleController.forward().then((_) {
      _sparkleController.reset();
      _floatingEmojis.clear();
      setState(() {});
    });
    
    // Generate dramatic message
    _dramaticMessage = _dramaticMessages[math.Random().nextInt(_dramaticMessages.length)];
    
    // Show dramatic notification
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_dramaticMessage),
          backgroundColor: _themeColors[_selectedTheme]!['primary'],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // Enhanced method to play dramatic sound effects
  Future<void> _playDramaticSound() async {
    try {
      // Play a dramatic sound effect
      await _audioPlayer.play(AssetSource('audio/dramatic_reveal.mp3'));
      
      // Add haptic feedback for extra drama
      HapticFeedback.heavyImpact();
      
      // Trigger multiple animations
      _sparkleController.forward();
      _revealController.forward();
      _shakeController.forward().then((_) => _shakeController.reset());
    } catch (e) {
      debugPrint('Could not play dramatic sound: $e');
      // Still provide haptic feedback even if sound fails
      HapticFeedback.heavyImpact();
      
      // Show dramatic message
      List<String> messages = [
        'The universe resonates with your choice! 🌟',
        'Cosmic forces align with your decision! ⚡',
        'The spirits approve of your selection! 👻',
        'Reality bends to acknowledge your vote! 💫',
        'The ancient powers witness your choice! 🔮'
      ];
      _dramaticMessage = messages[math.Random().nextInt(messages.length)];
      
      // Show notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_dramaticMessage),
          backgroundColor: _themeColors[_selectedTheme]!['primary'],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // Enhanced method to create the poll with theme and drama
  Future<void> _createPoll() async {
    if (_pollController.text.isEmpty ||
        _option1Controller.text.isEmpty ||
        _option2Controller.text.isEmpty) {
      _showErrorMessage('Please fill in at least the question and first two options! 🔮');
      return;
    }

    setState(() {
      _isVoting = true;
    });

    _options = [
      _option1Controller.text,
      _option2Controller.text,
      _option3Controller.text.isEmpty ? '' : _option3Controller.text,
      _option4Controller.text.isEmpty ? '' : _option4Controller.text,
    ];

    try {
      await supabase.from('polls').insert([
        {
          'question': _pollController.text,
          'options': _options,
          'votes': _votes,
          'theme': _selectedTheme,
          'created_at': DateTime.now().toString(),
        }
      ]);

      setState(() {
        _isPollCreated = true;
        _isVoting = false;
      });
      
      // Dramatic poll creation effect
      _pulseController.forward().then((_) => _pulseController.reverse());
      HapticFeedback.mediumImpact();
      
      _showSuccessMessage('Your cursed poll has been unleashed! 🌟');
      
    } catch (e) {
      debugPrint('Error creating poll: $e');
      setState(() {
        _isVoting = false;
      });
      _showErrorMessage('The cosmic forces rejected your poll! Try again! ⚡');
    }
  }

  // Enhanced voting with dramatic effects and user tracking
  Future<void> _voteOnPoll(int index) async {
    if (_userVote != null) {
      _showErrorMessage('You have already cast your vote! The universe remembers! 👻');
      return;
    }

    setState(() {
      _isVoting = true;
      _userVote = index;
      _votes[index]++;
    });

    try {
      // Save the votes to Supabase
      await supabase.from('polls').upsert([
        {
          'question': _pollController.text,
          'votes': _votes,
          'theme': _selectedTheme,
        }
      ]);

      // Dramatic reveal sequence
      await Future.delayed(Duration(milliseconds: 500));
      
      setState(() {
        _showVotingResults = true;
        _isVoting = false;
      });

      // Epic reveal effects
      _playDramaticSound();
      _showSparkleExplosion();
      
    } catch (e) {
      debugPrint('Error saving vote: $e');
      // Still show results even if save fails
      setState(() {
        _showVotingResults = true;
        _isVoting = false;
      });
      _playDramaticSound();
      _showSparkleExplosion();
    }
  }
  
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  
  void _resetPoll() {
    setState(() {
      _isPollCreated = false;
      _showVotingResults = false;
      _userVote = null;
      _isVoting = false;
      _dramaticMessage = '';
      for (int i = 0; i < _votes.length; i++) {
        _votes[i] = 0;
      }
      _options.clear();
    });
    
    // Clear controllers
    _pollController.clear();
    _option1Controller.clear();
    _option2Controller.clear();
    _option3Controller.clear();
    _option4Controller.clear();
    
    // Reset animations
    _revealController.reset();
    _sparkleController.reset();
    _shakeController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _themeColors[_selectedTheme]!['background'],
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatAnimation.value * 5),
              child: Row(
                children: [
                  Icon(_themeIcons[_selectedTheme]!, 
                       color: _themeColors[_selectedTheme]!['accent']),
                  SizedBox(width: 8),
                  Text(
                    'Cursed Polls 🔮',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _themeColors[_selectedTheme]!['text'],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        backgroundColor: _themeColors[_selectedTheme]!['primary'],
        elevation: 0,
        actions: [
          if (_isPollCreated)
            IconButton(
              icon: Icon(Icons.refresh, color: _themeColors[_selectedTheme]!['accent']),
              onPressed: _resetPoll,
              tooltip: 'Create new poll',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _themeColors[_selectedTheme]!['background']!,
              _themeColors[_selectedTheme]!['primary']!.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Theme selector
              if (!_isPollCreated) ...[
                Card(
                  color: _themeColors[_selectedTheme]!['primary']!.withValues(alpha: 0.8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Your Cursed Theme:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _themeColors[_selectedTheme]!['text'],
                          ),
                        ),
                        SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: _themes.map((theme) => 
                            FilterChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_themeIcons[theme]!, 
                                       size: 16, 
                                       color: _selectedTheme == theme 
                                         ? _themeColors[theme]!['background'] 
                                         : _themeColors[theme]!['accent']),
                                  SizedBox(width: 4),
                                  Text(theme.replaceAll('_', ' ').toUpperCase()),
                                ],
                              ),
                              selected: _selectedTheme == theme,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedTheme = theme;
                                  });
                                  HapticFeedback.lightImpact();
                                }
                              },
                              backgroundColor: _themeColors[theme]!['primary']!.withValues(alpha: 0.3),
                              selectedColor: _themeColors[theme]!['accent'],
                              checkmarkColor: _themeColors[theme]!['background'],
                            ),
                          ).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],

              // Poll creation form
              if (!_isPollCreated) ...[
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_pulseAnimation.value * 0.05),
                      child: Card(
                        color: _themeColors[_selectedTheme]!['primary']!.withValues(alpha: 0.9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 8,
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Craft Your Cursed Question:',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _themeColors[_selectedTheme]!['text'],
                                ),
                              ),
                              SizedBox(height: 16),
                              TextField(
                                controller: _pollController,
                                style: TextStyle(color: _themeColors[_selectedTheme]!['text']),
                                decoration: InputDecoration(
                                  hintText: 'Ask something mysterious...',
                                  hintStyle: TextStyle(color: _themeColors[_selectedTheme]!['text']!.withValues(alpha: 0.6)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: _themeColors[_selectedTheme]!['accent']!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: _themeColors[_selectedTheme]!['accent']!, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: _themeColors[_selectedTheme]!['background']!.withValues(alpha: 0.3),
                                ),
                                maxLines: 2,
                              ),
                              SizedBox(height: 20),
                              Text(
                                'Cursed Options:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _themeColors[_selectedTheme]!['text'],
                                ),
                              ),
                              SizedBox(height: 12),
                              _buildOptionField(_option1Controller, 'First option (required)', true),
                              _buildOptionField(_option2Controller, 'Second option (required)', true),
                              _buildOptionField(_option3Controller, 'Third option (optional)', false),
                              _buildOptionField(_option4Controller, 'Fourth option (optional)', false),
                              SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isVoting ? null : _createPoll,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _themeColors[_selectedTheme]!['accent'],
                                    foregroundColor: _themeColors[_selectedTheme]!['background'],
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 8,
                                  ),
                                  child: _isVoting
                                    ? Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation(_themeColors[_selectedTheme]!['background']),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text('Summoning Poll...', style: TextStyle(fontSize: 18)),
                                        ],
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(_themeIcons[_selectedTheme]!, size: 24),
                                          SizedBox(width: 8),
                                          Text('Unleash the Poll!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],

              // Voting interface
              if (_isPollCreated && !_showVotingResults) ...[
                AnimatedBuilder(
                  animation: _revealController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _revealAnimation.value,
                      child: Opacity(
                        opacity: _revealAnimation.value,
                        child: Card(
                          color: _themeColors[_selectedTheme]!['primary']!.withValues(alpha: 0.9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 12,
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(_themeIcons[_selectedTheme]!, 
                                         color: _themeColors[_selectedTheme]!['accent'], 
                                         size: 32),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _pollController.text,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: _themeColors[_selectedTheme]!['text'],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 24),
                                ..._options.asMap().entries.where((entry) => entry.value.isNotEmpty).map((entry) {
                                  int index = entry.key;
                                  String option = entry.value;
                                  bool isSelected = _userVote == index;
                                  
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 12),
                                    child: AnimatedBuilder(
                                      animation: _shakeController,
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(_shakeAnimation.value * (isSelected ? 10 : 0), 0),
                                          child: SizedBox(
                                            width: double.infinity,
                                            height: 60,
                                            child: ElevatedButton(
                                              onPressed: _isVoting ? null : () => _voteOnPoll(index),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isSelected 
                                                  ? _themeColors[_selectedTheme]!['accent']
                                                  : _themeColors[_selectedTheme]!['primary']!.withValues(alpha: 0.6),
                                                foregroundColor: _themeColors[_selectedTheme]!['text'],
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                elevation: isSelected ? 8 : 4,
                                                side: BorderSide(
                                                  color: _themeColors[_selectedTheme]!['accent']!,
                                                  width: isSelected ? 3 : 1,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                                                    color: _themeColors[_selectedTheme]!['accent'],
                                                  ),
                                                  SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      option,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                      ),
                                                    ),
                                                  ),
                                                  if (_isVoting && isSelected)
                                                    SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor: AlwaysStoppedAnimation(_themeColors[_selectedTheme]!['text']),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],

              // Results display
              if (_showVotingResults) ...[
                Card(
                  color: _themeColors[_selectedTheme]!['primary']!.withValues(alpha: 0.9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 12,
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(_themeIcons[_selectedTheme]!, 
                                 color: _themeColors[_selectedTheme]!['accent'], 
                                 size: 32),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'The Fates Have Decided!',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: _themeColors[_selectedTheme]!['accent'],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          _pollController.text,
                          style: TextStyle(
                            fontSize: 18,
                            color: _themeColors[_selectedTheme]!['text'],
                          ),
                        ),
                        SizedBox(height: 24),
                        ..._buildResultsWidgets(),
                        if (_dramaticMessage.isNotEmpty) ...[
                          SizedBox(height: 20),
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _themeColors[_selectedTheme]!['accent']!.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _themeColors[_selectedTheme]!['accent']!),
                            ),
                            child: Text(
                              _dramaticMessage,
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: _themeColors[_selectedTheme]!['text'],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              // Floating emoji effects
              AnimatedBuilder(
                animation: _sparkleController,
                builder: (context, child) {
                  return _floatingEmojis.isNotEmpty
                    ? Stack(
                        children: _floatingEmojis.map((emoji) => 
                          Positioned(
                            left: emoji['x'],
                            top: emoji['y'] - (_sparkleAnimation.value * 100),
                            child: Opacity(
                              opacity: 1.0 - _sparkleAnimation.value,
                              child: Text(
                                emoji['emoji'],
                                style: TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                        ).toList(),
                      )
                    : Container();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionField(TextEditingController controller, String hint, bool required) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: TextStyle(color: _themeColors[_selectedTheme]!['text']),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: _themeColors[_selectedTheme]!['text']!.withValues(alpha: 0.6)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _themeColors[_selectedTheme]!['accent']!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _themeColors[_selectedTheme]!['accent']!, width: 2),
          ),
          filled: true,
          fillColor: _themeColors[_selectedTheme]!['background']!.withValues(alpha: 0.3),
          prefixIcon: Icon(
            required ? Icons.star : Icons.star_border,
            color: _themeColors[_selectedTheme]!['accent'],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildResultsWidgets() {
    return _options.asMap().entries.where((entry) => entry.value.isNotEmpty).map((entry) {
      int index = entry.key;
      String option = entry.value;
      int totalVotes = _votes.reduce((a, b) => a + b);
      double percentage = totalVotes > 0 ? (_votes[index] / totalVotes) : 0;
      bool isWinner = _votes[index] == _votes.reduce((a, b) => a > b ? a : b);
      bool isUserChoice = _userVote == index;
      
      return Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isWinner 
                ? _themeColors[_selectedTheme]!['accent']!
                : _themeColors[_selectedTheme]!['text']!.withValues(alpha: 0.3),
              width: isWinner ? 3 : 1,
            ),
            color: _themeColors[_selectedTheme]!['background']!.withValues(alpha: 0.3),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isWinner) 
                      Icon(Icons.workspace_premium, 
                           color: _themeColors[_selectedTheme]!['accent'], 
                           size: 20),
                    if (isUserChoice)
                      Icon(Icons.person, 
                           color: _themeColors[_selectedTheme]!['accent'], 
                           size: 20),
                    if (isWinner || isUserChoice) SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                          color: _themeColors[_selectedTheme]!['text'],
                        ),
                      ),
                    ),
                    Text(
                      '${_votes[index]} votes (${(percentage * 100).toInt()}%)',
                      style: TextStyle(
                        fontSize: 14,
                        color: _themeColors[_selectedTheme]!['accent'],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: _themeColors[_selectedTheme]!['text']!.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(_themeColors[_selectedTheme]!['accent']),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}
