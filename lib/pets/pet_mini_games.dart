// File: pet_mini_games.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'pets_production_config.dart';

// Game result data class
class GameResult {
  final String gameType;
  final double score;
  final double happinessBoost;
  final double energyCost;
  final double healthBoost;
  final String message;
  final bool isSuccess;

  GameResult({
    required this.gameType,
    required this.score,
    required this.happinessBoost,
    required this.energyCost,
    required this.healthBoost,
    required this.message,
    required this.isSuccess,
  });
}

// Abstract base class for mini-games
abstract class MiniGame extends StatefulWidget {
  final Function(GameResult) onGameComplete;
  final AudioPlayer audioPlayer;

  const MiniGame({
    super.key,
    required this.onGameComplete,
    required this.audioPlayer,
  });
}

// Ball Catch Game
class BallCatchGame extends MiniGame {
  const BallCatchGame({
    super.key,
    required super.onGameComplete,
    required super.audioPlayer,
  });

  @override
  State<BallCatchGame> createState() => _BallCatchGameState();
}

class _BallCatchGameState extends State<BallCatchGame>
    with TickerProviderStateMixin {
  late AnimationController _gameController;
  late AnimationController _ballController;
  late Animation<double> _ballAnimation;
  late ConfettiController _confettiController;

  int _score = 0;
  int _ballsCaught = 0;
  int _ballsDropped = 0;
  bool _gameActive = false;
  Timer? _gameTimer;
  Timer? _ballSpawnTimer;
  List<FallingBall> _balls = [];
  final int _gameDuration = 30; // seconds
  int _timeRemaining = 30;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _startGame();
  }

  void _initializeGame() {
    _gameController = AnimationController(
      duration: Duration(seconds: _gameDuration),
      vsync: this,
    );

    _ballController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _ballAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ballController, curve: Curves.easeIn),
    );

    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  void _startGame() {
    setState(() {
      _gameActive = true;
      _timeRemaining = _gameDuration;
    });

    // Game timer
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeRemaining--;
      });
      if (_timeRemaining <= 0) {
        _endGame();
      }
    });

    // Ball spawn timer
    _ballSpawnTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (_gameActive) {
        _spawnBall();
      }
    });

    _gameController.forward();
  }

  void _spawnBall() {
    final random = math.Random();
    final ball = FallingBall(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      x: random.nextDouble() * 0.8 + 0.1, // 10% to 90% of screen width
      startTime: DateTime.now(),
      color: _getRandomBallColor(),
    );

    setState(() {
      _balls.add(ball);
    });

    // Remove ball after fall duration
    Timer(const Duration(seconds: 3), () {
      if (_balls.contains(ball)) {
        setState(() {
          _balls.remove(ball);
          _ballsDropped++;
        });
      }
    });
  }

  Color _getRandomBallColor() {
    final colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple];
    return colors[math.Random().nextInt(colors.length)];
  }

  void _catchBall(FallingBall ball) {
    if (!_gameActive) return;

    setState(() {
      _balls.remove(ball);
      _ballsCaught++;
      _score += 10;
    });

    // Play catch sound
    _playSound('catch.mp3');
    
    // Haptic feedback
    HapticFeedback.lightImpact();

    // Show confetti for good catches
    if (_ballsCaught % 5 == 0) {
      _confettiController.play();
    }
  }

  void _endGame() {
    setState(() {
      _gameActive = false;
    });

    _gameTimer?.cancel();
    _ballSpawnTimer?.cancel();

    final accuracy = _ballsCaught / (_ballsCaught + _ballsDropped);
    final performance = accuracy * (_score / 100);

    GameResult result;
    if (performance > 0.7) {
      result = GameResult(
        gameType: 'Ball Catch',
        score: _score.toDouble(),
        happinessBoost: 0.3,
        energyCost: 0.1,
        healthBoost: 0.08,
        message: 'Amazing reflexes! 🏆',
        isSuccess: true,
      );
    } else if (performance > 0.4) {
      result = GameResult(
        gameType: 'Ball Catch',
        score: _score.toDouble(),
        happinessBoost: 0.2,
        energyCost: 0.08,
        healthBoost: 0.05,
        message: 'Good catching! 🎾',
        isSuccess: true,
      );
    } else {
      result = GameResult(
        gameType: 'Ball Catch',
        score: _score.toDouble(),
        happinessBoost: 0.1,
        energyCost: 0.05,
        healthBoost: 0.02,
        message: 'Nice try! Keep practicing! �E',
        isSuccess: false,
      );
    }

    widget.onGameComplete(result);
  }

  Future<void> _playSound(String fileName) async {
    try {
      await widget.audioPlayer.play(AssetSource('pets/sounds/$fileName'));
    } catch (e) {
      PetsDebugUtils.logError('playSound', 'Could not play sound: $fileName');
    }
  }

  @override
  void dispose() {
    _gameController.dispose();
    _ballController.dispose();
    _confettiController.dispose();
    _gameTimer?.cancel();
    _ballSpawnTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.lightBlue.shade100, Colors.green.shade100],
        ),
      ),
      child: Stack(
        children: [
          // Confetti
          Positioned.fill(
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
            ),
          ),

          // Game area
          Positioned.fill(
            child: Stack(
              children: _balls.map((ball) => _buildFallingBall(ball)).toList(),
            ),
          ),

          // UI
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text('Score: $_score', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Caught: $_ballsCaught', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Time: $_timeRemaining',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Instructions
          if (!_gameActive && _timeRemaining == _gameDuration)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sports_baseball, size: 48, color: Colors.orange),
                    SizedBox(height: 12),
                    Text(
                      'Ball Catch Game',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap the falling balls to catch them!\nGet as many as you can in 30 seconds.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallingBall(FallingBall ball) {
    return AnimatedBuilder(
      animation: _ballAnimation,
      builder: (context, child) {
        final elapsed = DateTime.now().difference(ball.startTime).inMilliseconds;
        final progress = (elapsed / 3000).clamp(0.0, 1.0);
        final screenHeight = MediaQuery.of(context).size.height;
        final y = progress * screenHeight;

        return Positioned(
          left: ball.x * MediaQuery.of(context).size.width - 25,
          top: y,
          child: GestureDetector(
            onTap: () => _catchBall(ball),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: ball.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.sports_baseball, color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}

// Puzzle Slider Game
class PuzzleSliderGame extends MiniGame {
  const PuzzleSliderGame({
    super.key,
    required super.onGameComplete,
    required super.audioPlayer,
  });

  @override
  State<PuzzleSliderGame> createState() => _PuzzleSliderGameState();
}

class _PuzzleSliderGameState extends State<PuzzleSliderGame> {
  List<int> _tiles = [];
  List<int> _solution = [];
  int _emptyIndex = 8;
  int _moves = 0;
  bool _gameComplete = false;
  late Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    _initializePuzzle();
    _stopwatch = Stopwatch()..start();
  }

  void _initializePuzzle() {
    _solution = List.generate(9, (index) => index);
    _tiles = List.from(_solution);
    
    // Shuffle the puzzle
    for (int i = 0; i < 1000; i++) {
      _makeRandomMove();
    }
    
    setState(() {
      _moves = 0;
    });
  }

  void _makeRandomMove() {
    final validMoves = _getValidMoves();
    if (validMoves.isNotEmpty) {
      final randomMove = validMoves[math.Random().nextInt(validMoves.length)];
      _moveTile(randomMove, false);
    }
  }

  List<int> _getValidMoves() {
    List<int> validMoves = [];
    int row = _emptyIndex ~/ 3;
    int col = _emptyIndex % 3;

    // Up
    if (row > 0) validMoves.add(_emptyIndex - 3);
    // Down
    if (row < 2) validMoves.add(_emptyIndex + 3);
    // Left
    if (col > 0) validMoves.add(_emptyIndex - 1);
    // Right
    if (col < 2) validMoves.add(_emptyIndex + 1);

    return validMoves;
  }

  void _moveTile(int tileIndex, bool countMove) {
    if (_gameComplete) return;

    final validMoves = _getValidMoves();
    if (validMoves.contains(tileIndex)) {
      setState(() {
        _tiles[_emptyIndex] = _tiles[tileIndex];
        _tiles[tileIndex] = 0;
        _emptyIndex = tileIndex;
        if (countMove) _moves++;
      });

      _playSound('move.mp3');
      HapticFeedback.selectionClick();

      if (_checkWin()) {
        _completeGame();
      }
    }
  }

  bool _checkWin() {
    for (int i = 0; i < 9; i++) {
      if (_tiles[i] != _solution[i]) return false;
    }
    return true;
  }

  void _completeGame() {
    setState(() {
      _gameComplete = true;
    });

    _stopwatch.stop();
    final timeInSeconds = _stopwatch.elapsed.inSeconds;

    GameResult result;
    if (_moves <= 20 && timeInSeconds <= 60) {
      result = GameResult(
        gameType: 'Puzzle Slider',
        score: (300 - _moves - timeInSeconds).toDouble(),
        happinessBoost: 0.25,
        energyCost: 0.03,
        healthBoost: 0.05,
        message: 'Puzzle master! 🧩',
        isSuccess: true,
      );
    } else if (_moves <= 50 && timeInSeconds <= 120) {
      result = GameResult(
        gameType: 'Puzzle Slider',
        score: (200 - _moves).toDouble(),
        happinessBoost: 0.18,
        energyCost: 0.04,
        healthBoost: 0.03,
        message: 'Well solved! 🎯',
        isSuccess: true,
      );
    } else {
      result = GameResult(
        gameType: 'Puzzle Slider',
        score: 50.0,
        happinessBoost: 0.12,
        energyCost: 0.02,
        healthBoost: 0.02,
        message: 'Good effort! 😊',
        isSuccess: false,
      );
    }

    Future.delayed(const Duration(seconds: 1), () {
      widget.onGameComplete(result);
    });
  }

  Future<void> _playSound(String fileName) async {
    try {
      await widget.audioPlayer.play(AssetSource('pets/sounds/$fileName'));
    } catch (e) {
      PetsDebugUtils.logError('playSound', 'Could not play sound: $fileName');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.purple.shade100, Colors.blue.shade100],
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'Sliding Puzzle',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('Moves: $_moves', style: const TextStyle(fontSize: 16)),
                    Text('Time: ${_stopwatch.elapsed.inSeconds}s', style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),

          // Puzzle Grid
          Expanded(
            child: Center(
              child: Container(
                width: 300,
                height: 300,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: 9,
                  itemBuilder: (context, index) {
                    return _buildTile(index);
                  },
                ),
              ),
            ),
          ),

          // Instructions
          Container(
            padding: const EdgeInsets.all(20),
            child: const Text(
              'Tap tiles next to the empty space to move them.\nArrange numbers 1-8 in order!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(int index) {
    final value = _tiles[index];
    final isEmpty = value == 0;

    return GestureDetector(
      onTap: isEmpty ? null : () => _moveTile(index, true),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isEmpty ? Colors.grey.shade300 : Colors.blue.shade400,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isEmpty ? null : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: isEmpty ? null : Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// Memory Match Game
class MemoryMatchGame extends MiniGame {
  const MemoryMatchGame({
    super.key,
    required super.onGameComplete,
    required super.audioPlayer,
  });

  @override
  State<MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _MemoryMatchGameState extends State<MemoryMatchGame> {
  List<MemoryCard> _cards = [];
  List<int> _flippedCards = [];
  int _matches = 0;
  int _moves = 0;
  bool _canFlip = true;
  late Stopwatch _stopwatch;

  final List<IconData> _icons = [
    Icons.pets, Icons.favorite, Icons.star, Icons.cake,
    Icons.diamond, Icons.emoji_emotions, Icons.sports_baseball, Icons.music_note,
  ];

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _stopwatch = Stopwatch()..start();
  }

  void _initializeGame() {
    _cards.clear();
    
    // Create pairs of cards
    for (int i = 0; i < _icons.length; i++) {
      _cards.add(MemoryCard(id: i * 2, icon: _icons[i], isFlipped: false, isMatched: false));
      _cards.add(MemoryCard(id: i * 2 + 1, icon: _icons[i], isFlipped: false, isMatched: false));
    }
    
    // Shuffle cards
    _cards.shuffle();
    
    setState(() {});
  }

  void _flipCard(int index) {
    if (!_canFlip || _cards[index].isFlipped || _cards[index].isMatched) return;

    setState(() {
      _cards[index].isFlipped = true;
      _flippedCards.add(index);
    });

    _playSound('flip.mp3');
    HapticFeedback.selectionClick();

    if (_flippedCards.length == 2) {
      _moves++;
      _canFlip = false;
      
      Future.delayed(const Duration(milliseconds: 1000), () {
        _checkMatch();
      });
    }
  }

  void _checkMatch() {
    final first = _flippedCards[0];
    final second = _flippedCards[1];

    if (_cards[first].icon == _cards[second].icon) {
      // Match found
      setState(() {
        _cards[first].isMatched = true;
        _cards[second].isMatched = true;
        _matches++;
      });
      
      _playSound('match.mp3');
      
      if (_matches == _icons.length) {
        _completeGame();
      }
    } else {
      // No match
      setState(() {
        _cards[first].isFlipped = false;
        _cards[second].isFlipped = false;
      });
    }

    _flippedCards.clear();
    _canFlip = true;
  }

  void _completeGame() {
    _stopwatch.stop();
    final timeInSeconds = _stopwatch.elapsed.inSeconds;

    GameResult result;
    if (_moves <= 16 && timeInSeconds <= 60) {
      result = GameResult(
        gameType: 'Memory Match',
        score: (500 - _moves * 10 - timeInSeconds).toDouble(),
        happinessBoost: 0.22,
        energyCost: 0.02,
        healthBoost: 0.04,
        message: 'Amazing memory! 🧠',
        isSuccess: true,
      );
    } else if (_moves <= 30 && timeInSeconds <= 120) {
      result = GameResult(
        gameType: 'Memory Match',
        score: (300 - _moves * 5).toDouble(),
        happinessBoost: 0.16,
        energyCost: 0.03,
        healthBoost: 0.03,
        message: 'Great memory! 🎯',
        isSuccess: true,
      );
    } else {
      result = GameResult(
        gameType: 'Memory Match',
        score: 50.0,
        happinessBoost: 0.10,
        energyCost: 0.02,
        healthBoost: 0.02,
        message: 'Good try! 😊',
        isSuccess: false,
      );
    }

    Future.delayed(const Duration(seconds: 1), () {
      widget.onGameComplete(result);
    });
  }

  Future<void> _playSound(String fileName) async {
    try {
      await widget.audioPlayer.play(AssetSource('pets/sounds/$fileName'));
    } catch (e) {
      PetsDebugUtils.logError('playSound', 'Could not play sound: $fileName');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.pink.shade100, Colors.purple.shade100],
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'Memory Match',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('Moves: $_moves', style: const TextStyle(fontSize: 16)),
                    Text('Matches: $_matches/${_icons.length}', style: const TextStyle(fontSize: 16)),
                    Text('Time: ${_stopwatch.elapsed.inSeconds}s', style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),

          // Game Grid
          Expanded(
            child: Center(
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    return _buildCard(index);
                  },
                ),
              ),
            ),
          ),

          // Instructions
          Container(
            padding: const EdgeInsets.all(20),
            child: const Text(
              'Flip cards to find matching pairs!\nRemember the positions and match all pairs.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(int index) {
    final card = _cards[index];
    
    return GestureDetector(
      onTap: () => _flipCard(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: card.isMatched 
              ? Colors.green.shade300
              : card.isFlipped 
                  ? Colors.white 
                  : Colors.blue.shade400,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: card.isFlipped || card.isMatched
              ? Icon(
                  card.icon,
                  size: 32,
                  color: card.isMatched ? Colors.white : Colors.purple,
                )
              : const Icon(
                  Icons.help,
                  size: 32,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}

// Fetch Game
class FetchGame extends MiniGame {
  const FetchGame({
    super.key,
    required super.onGameComplete,
    required super.audioPlayer,
  });

  @override
  State<FetchGame> createState() => _FetchGameState();
}

class _FetchGameState extends State<FetchGame> with TickerProviderStateMixin {
  late AnimationController _throwController;
  late AnimationController _returnController;
  late Animation<double> _throwAnimation;
  late Animation<double> _returnAnimation;
  
  bool _gameActive = false;
  bool _ballThrown = false;
  bool _ballReturning = false;
  int _successfulFetches = 0;
  int _totalThrows = 0;
  Timer? _gameTimer;
  Timer? _returnTimer;
  final int _gameDuration = 45;
  int _timeRemaining = 45;

  Offset _ballPosition = const Offset(0.5, 0.8);
  Offset _throwTarget = const Offset(0.5, 0.2);

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _startGame();
  }

  void _initializeGame() {
    _throwController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _returnController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _throwAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _throwController, curve: Curves.easeOut),
    );

    _returnAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _returnController, curve: Curves.easeInOut),
    );
  }

  void _startGame() {
    setState(() {
      _gameActive = true;
      _timeRemaining = _gameDuration;
    });

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeRemaining--;
      });
      if (_timeRemaining <= 0) {
        _endGame();
      }
    });
  }

  void _throwBall(Offset target) {
    if (_ballThrown || !_gameActive) return;

    setState(() {
      _ballThrown = true;
      _throwTarget = target;
      _totalThrows++;
    });

    _playSound('throw.mp3');
    _throwController.forward(from: 0.0);

    // Simulate fetch return
    _returnTimer = Timer(const Duration(milliseconds: 2000), () {
      if (_gameActive) {
        _returnBall();
      }
    });
  }

  void _returnBall() {
    setState(() {
      _ballReturning = true;
      _successfulFetches++;
    });

    _playSound('fetch.mp3');
    _returnController.forward(from: 0.0);

    Timer(const Duration(milliseconds: 2000), () {
      setState(() {
        _ballThrown = false;
        _ballReturning = false;
        _ballPosition = const Offset(0.5, 0.8);
      });
      
      _throwController.reset();
      _returnController.reset();
    });
  }

  void _endGame() {
    setState(() {
      _gameActive = false;
    });

    _gameTimer?.cancel();
    _returnTimer?.cancel();

    final successRate = _totalThrows > 0 ? _successfulFetches / _totalThrows : 0.0;
    
    GameResult result;
    if (successRate > 0.8 && _successfulFetches >= 8) {
      result = GameResult(
        gameType: 'Fetch Game',
        score: (_successfulFetches * 20).toDouble(),
        happinessBoost: 0.35,
        energyCost: 0.15,
        healthBoost: 0.1,
        message: 'Fetch champion! 🎾',
        isSuccess: true,
      );
    } else if (successRate > 0.5 && _successfulFetches >= 5) {
      result = GameResult(
        gameType: 'Fetch Game',
        score: (_successfulFetches * 15).toDouble(),
        happinessBoost: 0.25,
        energyCost: 0.12,
        healthBoost: 0.07,
        message: 'Great fetching! 🐕',
        isSuccess: true,
      );
    } else {
      result = GameResult(
        gameType: 'Fetch Game',
        score: (_successfulFetches * 10).toDouble(),
        happinessBoost: 0.15,
        energyCost: 0.08,
        healthBoost: 0.04,
        message: 'Good exercise! 🏃',
        isSuccess: false,
      );
    }

    widget.onGameComplete(result);
  }

  Future<void> _playSound(String fileName) async {
    try {
      await widget.audioPlayer.play(AssetSource('pets/sounds/$fileName'));
    } catch (e) {
      PetsDebugUtils.logError('playSound', 'Could not play sound: $fileName');
    }
  }

  @override
  void dispose() {
    _throwController.dispose();
    _returnController.dispose();
    _gameTimer?.cancel();
    _returnTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.green.shade200, Colors.blue.shade200],
        ),
      ),
      child: GestureDetector(
        onTapUp: (details) {
          if (_gameActive && !_ballThrown) {
            final screenSize = MediaQuery.of(context).size;
            final normalizedTarget = Offset(
              details.localPosition.dx / screenSize.width,
              details.localPosition.dy / screenSize.height,
            );
            _throwBall(normalizedTarget);
          }
        },
        child: Stack(
          children: [
            // Game UI
            Positioned(
              top: 40,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text('Fetches: $_successfulFetches', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Success: ${_totalThrows > 0 ? ((_successfulFetches / _totalThrows) * 100).round() : 0}%', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Time: $_timeRemaining',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // Ball
            AnimatedBuilder(
              animation: Listenable.merge([_throwAnimation, _returnAnimation]),
              builder: (context, child) {
                Offset currentPosition;
                
                if (_ballReturning) {
                  currentPosition = Offset.lerp(
                    _throwTarget,
                    const Offset(0.5, 0.8),
                    _returnAnimation.value,
                  )!;
                } else if (_ballThrown) {
                  currentPosition = Offset.lerp(
                    const Offset(0.5, 0.8),
                    _throwTarget,
                    _throwAnimation.value,
                  )!;
                } else {
                  currentPosition = _ballPosition;
                }

                return Positioned(
                  left: currentPosition.dx * MediaQuery.of(context).size.width - 25,
                  top: currentPosition.dy * MediaQuery.of(context).size.height - 25,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.yellow,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.sports_tennis, color: Colors.orange),
                  ),
                );
              },
            ),

            // Instructions
            if (!_ballThrown && _gameActive)
              const Positioned(
                bottom: 100,
                left: 20,
                right: 20,
                child: Center(
                  child: Text(
                    'Tap anywhere to throw the ball!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Data classes
class FallingBall {
  final String id;
  final double x;
  final DateTime startTime;
  final Color color;

  FallingBall({
    required this.id,
    required this.x,
    required this.startTime,
    required this.color,
  });
}

class MemoryCard {
  final int id;
  final IconData icon;
  bool isFlipped;
  bool isMatched;

  MemoryCard({
    required this.id,
    required this.icon,
    required this.isFlipped,
    required this.isMatched,
  });
}
