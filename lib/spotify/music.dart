import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'spotify.dart'; // Our custom Spotify SDK wrapper
import 'services/spotify_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:math' as math;

/// Enhanced Music Listening Experience with Advanced Social Features
class EnhancedMusicScreen extends StatefulWidget {
  final String userId;
  final String? roomId;
  
  const EnhancedMusicScreen({
    super.key,
    required this.userId,
    this.roomId,
  });

  @override
  State<EnhancedMusicScreen> createState() => _EnhancedMusicScreenState();
}

class _EnhancedMusicScreenState extends State<EnhancedMusicScreen>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();
  
  // State variables
  // spotify.PlayerState? _playerState; // Will switch to proper objects once structure is stable
  Map<String, dynamic>? _playerState; // Temporary placeholder with proper structure
  List<Map<String, dynamic>> _queue = [];
  List<Map<String, dynamic>> _rooms = [];
  List<Map<String, dynamic>> _listeners = [];
  String? _currentRoomId;
  bool _isHost = false;
  bool _isSearching = false;
  int _currentPage = 0;
  
  // New enhanced features
  List<Map<String, dynamic>> _searchResults = [];
  List<String> _musicReactions = ['🎵', '🔥', '❤️', '😍', '🎉', '👏', '💃', '🕺'];
  Map<String, int> _trackVotes = {};
  bool _autoPlayEnabled = true;
  bool _shuffleMode = false;
  bool _repeatMode = false;
  String _currentMood = 'Vibing';
  
  // Animation controllers
  late AnimationController _beatController;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _particleController;
  late AnimationController _reactionController;
  late AnimationController _spinController;
  
  // Enhanced visualizer data
  List<double> _beatBars = List.generate(30, (index) => 0.1);
  List<double> _spectrumData = List.generate(64, (index) => 0.0);
  Timer? _beatTimer;
  Timer? _syncTimer;
  
  // Crystal pet states
  bool _petIsHappy = true;
  String _petEmotion = '😊';
  List<String> _petEmotions = ['😊', '😴', '🥳', '😍', '🤔', '😎', '🥰', '🎵'];

  @override
  void initState() {
    super.initState();
    _currentRoomId = widget.roomId;
    _initializeAnimations();
    _loadUserPreferences();
    _checkSpotifyConnection(); // Re-enabled
    _loadRooms();
    if (_currentRoomId != null) {
      _joinRoom(_currentRoomId!);
    }
  }

  void _initializeAnimations() {
    _beatController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _waveController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _reactionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _spinController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    _startEnhancedVisualizer();
    _startPetAnimation();
  }

  void _startEnhancedVisualizer() {
    _beatTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (mounted && _playerState != null && _playerState!['isPaused'] != true) {
        setState(() {
          // Enhanced beat visualization with frequency spectrum
          for (int i = 0; i < _beatBars.length; i++) {
            final baseIntensity = 0.1 + math.Random().nextDouble() * 0.9;
            final frequencyMultiplier = 1.0 - (i / _beatBars.length) * 0.5;
            _beatBars[i] = baseIntensity * frequencyMultiplier;
          }
          
          // Spectrum analyzer simulation
          for (int i = 0; i < _spectrumData.length; i++) {
            _spectrumData[i] = math.Random().nextDouble();
          }
          
          _beatController.forward().then((_) => _beatController.reverse());
        });
      }
    });
  }

  void _startPetAnimation() {
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _petEmotion = _petEmotions[math.Random().nextInt(_petEmotions.length)];
          _petIsHappy = _playerState != null && _playerState!['isPaused'] != true;
        });
      }
    });
  }

  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoPlayEnabled = prefs.getBool('auto_play_enabled') ?? true;
      _shuffleMode = prefs.getBool('shuffle_mode') ?? false;
      _repeatMode = prefs.getBool('repeat_mode') ?? false;
      _currentMood = prefs.getString('current_mood') ?? 'Vibing';
    });
  }

  Future<void> _saveUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_play_enabled', _autoPlayEnabled);
    await prefs.setBool('shuffle_mode', _shuffleMode);
    await prefs.setBool('repeat_mode', _repeatMode);
    await prefs.setString('current_mood', _currentMood);
  }

  Future<void> _checkSpotifyConnection() async {
    try {
      final spotifyService = SpotifyService.instance;
      final connected = await spotifyService.checkConnection();
      if (!connected) {
        await spotifyService.initialize();
        _subscribeToPlayerState();
      } else {
        _subscribeToPlayerState();
      }
    } catch (e) {
      print('Error checking Spotify connection: $e');
      _showSpotifyConnectDialog();
    }
  }

  void _subscribeToPlayerState() {
    try {
      final spotifyService = SpotifyService.instance;
      spotifyService.playerStateStream.listen((playerState) {
        if (mounted) {
          setState(() {
            _playerState = {
              'track': {
                'name': playerState.track?.name ?? 'Unknown Track',
                'uri': playerState.track?.uri ?? '',
                'imageUri': playerState.track?.imageUri.raw ?? '',
                'artist': {
                  'name': playerState.track?.artist.name ?? 'Unknown Artist',
                },
              },
              'isPaused': playerState.isPaused,
              'playbackPosition': playerState.playbackPosition,
            };
          });
          
          // Auto-sync with room
          if (_currentRoomId != null && _isHost) {
            _syncPlaybackWithRoom();
          }
        }
      });
    } catch (e) {
      print('Error subscribing to player state: $e');
    }
  }

  Future<void> _syncPlaybackWithRoom() async {
    if (_playerState != null && _playerState!['track'] != null) {
      try {
        await supabase.from('room_sync').upsert({
          'room_id': _currentRoomId,
          'track_uri': _playerState!['track']['uri'],
          'position_ms': _playerState!['playbackPosition'] ?? 0,
          'is_playing': _playerState!['isPaused'] != true,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        print('Error syncing playback with room: $e');
      }
    }
  }

  Future<void> _connectToSpotify() async {
    try {
      final spotifyService = SpotifyService.instance;
      final connected = await spotifyService.initialize();
      
      if (connected) {
        _subscribeToPlayerState();
        _showSuccessSnackBar('Connected to Spotify! 🎵');
      } else {
        _showErrorSnackBar('Failed to connect to Spotify');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to connect to Spotify: $e');
    }
  }

  Future<void> _searchSpotifyTracks(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() => _isSearching = true);
    
    try {
      final spotifyService = SpotifyService.instance;
      final tracks = await spotifyService.searchTracks(query, limit: 20);
      
      setState(() {
        _searchResults = tracks.map((track) => {
          'name': track.name,
          'artist': track.artist.name,
          'uri': track.uri,
          'image': track.imageUri.raw,
          'duration': track.duration,
        }).toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      _showErrorSnackBar('Search failed: $e');
      
      // Fallback to demo data if search fails
      setState(() {
        _searchResults = [
          {
            'name': 'Sample Song 1',
            'artist': 'Sample Artist',
            'uri': 'spotify:track:sample1',
            'image': 'https://via.placeholder.com/300x300',
            'duration': 180000,
          },
          {
            'name': 'Sample Song 2',
            'artist': 'Another Artist',
            'uri': 'spotify:track:sample2',
            'image': 'https://via.placeholder.com/300x300',
            'duration': 210000,
          },
        ];
      });
    }
  }

  Future<void> _loadRooms() async {
    try {
      final response = await supabase
          .from('music_rooms')
          .select('*, host_id, listener_count, current_track')
          .order('created_at', ascending: false);
      
      setState(() {
        _rooms = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading rooms: $e');
    }
  }

  Future<void> _createRoom(String roomName, String description) async {
    try {
      final response = await supabase.from('music_rooms').insert([
        {
          'name': roomName,
          'description': description,
          'host_id': widget.userId,
          'mood': _currentMood,
          'created_at': DateTime.now().toIso8601String(),
        }
      ]).select().single();
      
      await _joinRoom(response['id']);
      _showSuccessSnackBar('Room created! 🎉');
    } catch (e) {
      _showErrorSnackBar('Failed to create room: $e');
    }
  }

  Future<void> _joinRoom(String roomId) async {
    try {
      setState(() {
        _currentRoomId = roomId;
        _isHost = _rooms.any((room) => 
          room['id'] == roomId && room['host_id'] == widget.userId);
      });
      
      // Join the room
      await supabase.from('room_participants').upsert({
        'room_id': roomId,
        'user_id': widget.userId,
        'joined_at': DateTime.now().toIso8601String(),
      });
      
      _subscribeToRoom();
      _loadRoomData();
      _showSuccessSnackBar('Joined room! 🎵');
    } catch (e) {
      _showErrorSnackBar('Failed to join room: $e');
    }
  }

  void _subscribeToRoom() {
    if (_currentRoomId == null) return;
    
    // Subscribe to chat messages
    supabase
        .from('music_chat:room_id=eq.$_currentRoomId')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .listen((data) => _handleChatUpdate(data));
    
    // Subscribe to queue changes
    supabase
        .from('music_queue:room_id=eq.$_currentRoomId')
        .stream(primaryKey: ['id'])
        .order('queue_position')
        .listen((data) => _handleQueueUpdate(data));
    
    // Subscribe to room sync
    supabase
        .from('room_sync:room_id=eq.$_currentRoomId')
        .stream(primaryKey: ['room_id'])
        .listen((data) => _handleSyncUpdate(data));
  }

  void _handleChatUpdate(List<Map<String, dynamic>> data) {
    // Chat functionality can be implemented later if needed
    setState(() {
      // Update UI if needed
    });
  }

  void _handleQueueUpdate(List<Map<String, dynamic>> data) {
    setState(() {
      _queue = data;
    });
  }

  void _handleSyncUpdate(List<Map<String, dynamic>> data) {
    if (data.isNotEmpty && !_isHost) {
      final syncData = data.first;
      // Sync playback for non-host users
      _syncToHost(syncData);
    }
  }

  Future<void> _syncToHost(Map<String, dynamic> syncData) async {
    try {
      if (syncData['track_uri'] != _playerState?['track']?['uri']) {
        final spotifyService = SpotifyService.instance;
        await spotifyService.play(trackUri: syncData['track_uri']);
      }
      
      if (syncData['is_playing'] && _playerState?['isPaused'] == true) {
        final spotifyService = SpotifyService.instance;
        await spotifyService.resume();
      } else if (!syncData['is_playing'] && _playerState?['isPaused'] == false) {
        final spotifyService = SpotifyService.instance;
        await spotifyService.pause();
      }
    } catch (e) {
      print('Sync error: $e');
    }
  }

  Future<void> _loadRoomData() async {
    if (_currentRoomId == null) return;
    
    try {
      // Load participants
      final participants = await supabase
          .from('room_participants')
          .select('user_id, profiles(display_name, avatar_url)')
          .eq('room_id', _currentRoomId!);
      
      setState(() {
        _listeners = List<Map<String, dynamic>>.from(participants);
      });
    } catch (e) {
      print('Error loading room data: $e');
    }
  }

  Future<void> _addToQueue(Map<String, dynamic> track) async {
    if (_currentRoomId == null) return;
    
    try {
      await supabase.from('music_queue').insert([
        {
          'room_id': _currentRoomId,
          'track_uri': track['uri'],
          'track_name': track['name'],
          'artist_name': track['artist'],
          'image_url': track['image'],
          'duration': track['duration'],
          'added_by': widget.userId,
          'queue_position': _queue.length,
        }
      ]);
      
      _showSuccessSnackBar('Added to queue! ✅');
      HapticFeedback.lightImpact();
    } catch (e) {
      _showErrorSnackBar('Failed to add to queue: $e');
    }
  }

  Future<void> _voteForTrack(String trackId, bool isUpvote) async {
    try {
      await supabase.from('track_votes').upsert({
        'track_id': trackId,
        'user_id': widget.userId,
        'is_upvote': isUpvote,
      });
      
      // Update local vote count
      setState(() {
        _trackVotes[trackId] = (_trackVotes[trackId] ?? 0) + (isUpvote ? 1 : -1);
      });
      
      HapticFeedback.selectionClick();
    } catch (e) {
      print('Vote error: $e');
    }
  }

  Future<void> _sendReaction(String reaction) async {
    if (_currentRoomId == null) return;
    
    try {
      await supabase.from('music_reactions').insert([
        {
          'room_id': _currentRoomId,
          'user_id': widget.userId,
          'reaction': reaction,
          'track_uri': _playerState?['track']?['uri'],
        }
      ]);
      
      // Animate reaction
      _reactionController.forward().then((_) => _reactionController.reset());
      HapticFeedback.lightImpact();
    } catch (e) {
      print('Reaction error: $e');
    }
  }

  void _showSpotifyConnectDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.music_note, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text('Connect Spotify', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Connect your Spotify account to start listening with friends!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _connectToSpotify();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
            ),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _showCreateRoomDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Create Music Room', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Room Name',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.pinkAccent),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.pinkAccent),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createRoom(nameController.text, descController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _beatController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _particleController.dispose();
    _reactionController.dispose();
    _spinController.dispose();
    _beatTimer?.cancel();
    _syncTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Enhanced animated background
          _buildEnhancedBackground(),
          
          // Main content with page view
          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: [
              _buildPlayerPage(),
              _buildRoomsPage(),
              _buildSearchPage(),
              _buildQueuePage(),
            ],
          ),
          
          // Enhanced floating elements
          _buildFloatingPet(),
          _buildFloatingControls(),
        ],
      ),
      bottomNavigationBar: _buildEnhancedBottomNav(),
    );
  }

  Widget _buildEnhancedBackground() {
    return Stack(
      children: [
        // Base gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A1A2E),
                const Color(0xFF16213E),
                const Color(0xFF0F3460),
              ],
            ),
          ),
        ),
        
        // Enhanced particle system
        ...List.generate(25, (index) => _buildEnhancedParticle(index)),
        
        // Audio reactive waves
        AnimatedBuilder(
          animation: _waveController,
          builder: (context, child) {
            return CustomPaint(
              painter: EnhancedWavePainter(
                _waveController.value,
                _beatBars,
                _playerState?['isPaused'] != true,
              ),
              size: Size.infinite,
            );
          },
        ),
        
        // Spectrum overlay
        if (_playerState?['isPaused'] != true)
          AnimatedBuilder(
            animation: _beatController,
            builder: (context, child) {
              return CustomPaint(
                painter: SpectrumPainter(_spectrumData, _beatController.value),
                size: Size.infinite,
              );
            },
          ),
      ],
    );
  }

  Widget _buildEnhancedParticle(int index) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final progress = (_particleController.value + index * 0.08) % 1.0;
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        
        // Different particle behaviors
        double x, y;
        if (index % 3 == 0) {
          // Floating upward
          x = (screenWidth * (index * 0.12) % 1.0);
          y = screenHeight * (1.2 - progress);
        } else if (index % 3 == 1) {
          // Circular motion
          final angle = progress * 2 * math.pi + index;
          x = screenWidth * 0.5 + math.cos(angle) * 100;
          y = screenHeight * 0.5 + math.sin(angle) * 100;
        } else {
          // Diagonal drift
          x = screenWidth * progress;
          y = screenHeight * 0.5 + math.sin(progress * 4 * math.pi) * 50;
        }
        
        return Positioned(
          left: x,
          top: y,
          child: Container(
            width: 3 + (index % 4),
            height: 3 + (index % 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: [
                Colors.pinkAccent,
                Colors.purpleAccent,
                Colors.blueAccent,
                Colors.cyanAccent,
              ][index % 4].withOpacity(0.6 + progress * 0.4),
              boxShadow: [
                BoxShadow(
                  color: [
                    Colors.pinkAccent,
                    Colors.purpleAccent,
                    Colors.blueAccent,
                    Colors.cyanAccent,
                  ][index % 4].withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerPage() {
    final track = _playerState?['track'];
    
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 60),
          
          // Enhanced visualizer
          _buildEnhancedVisualizer(),
          
          const SizedBox(height: 20),
          
          // Album art with enhanced animations
          if (track != null) ...[
            _buildEnhancedAlbumArt(track),
            const SizedBox(height: 20),
            _buildTrackInfo(track),
            const SizedBox(height: 20),
            _buildPlaybackControls(),
            const SizedBox(height: 20),
            _buildReactionBar(),
          ] else
            _buildNoMusicPlaying(),
          
          const SizedBox(height: 20),
          
          // Current listeners
          if (_listeners.isNotEmpty) _buildListenersRow(),
        ],
      ),
    );
  }

  Widget _buildEnhancedVisualizer() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(_beatBars.length, (index) {
          return AnimatedBuilder(
            animation: _beatController,
            builder: (context, child) {
              final height = _beatBars[index] * 100;
              final animatedHeight = height * (1 + _beatController.value * 0.4);
              
              return Container(
                width: 6,
                height: animatedHeight,
                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.pinkAccent,
                      Colors.purpleAccent,
                      Colors.blueAccent,
                      Colors.cyanAccent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pinkAccent.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildEnhancedAlbumArt(dynamic track) {
    return AnimatedBuilder(
      animation: _spinController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.pinkAccent.withOpacity(0.6),
                blurRadius: 30 * (1 + _pulseController.value * 0.5),
                spreadRadius: 10,
              ),
            ],
          ),
          child: Transform.rotate(
            angle: _playerState?['isPaused'] != true ? _spinController.value * 2 * math.pi : 0,
            child: ClipOval(
              child: Image.network(
                track?['imageUri'] ?? 'https://via.placeholder.com/250x250/6a1b9a/white?text=Music',
                height: 250,
                width: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    width: 250,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.pinkAccent, Colors.purpleAccent],
                      ),
                    ),
                    child: const Icon(Icons.music_note, size: 80, color: Colors.white),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrackInfo(dynamic track) {
    return Column(
      children: [
        Text(
          track?['name'] ?? 'Unknown Track',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.pinkAccent,
                blurRadius: 10,
              ),
            ],
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          track?['artist']?['name'] ?? 'Unknown Artist',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        // Track voting
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => _voteForTrack(track.uri, false),
              icon: const Icon(Icons.thumb_down, color: Colors.redAccent),
            ),
            Text(
              '${_trackVotes[track.uri] ?? 0}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            IconButton(
              onPressed: () => _voteForTrack(track.uri, true),
              icon: const Icon(Icons.thumb_up, color: Colors.greenAccent),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaybackControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () async {
            setState(() => _shuffleMode = !_shuffleMode);
            await _saveUserPreferences();
            final spotifyService = SpotifyService.instance;
            await spotifyService.setShuffle(_shuffleMode);
          },
          icon: Icon(
            Icons.shuffle,
            color: _shuffleMode ? Colors.greenAccent : Colors.white54,
            size: 28,
          ),
        ),
        const SizedBox(width: 20),
        IconButton(
          onPressed: () async {
            final spotifyService = SpotifyService.instance;
            await spotifyService.skipPrevious();
          },
          icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36),
        ),
        const SizedBox(width: 20),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Colors.pinkAccent, Colors.purpleAccent],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.pinkAccent.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: IconButton(
            onPressed: () async {
              final spotifyService = SpotifyService.instance;
              if (_playerState?['isPaused'] == true) {
                await spotifyService.resume();
              } else {
                await spotifyService.pause();
              }
            },
            icon: Icon(
              _playerState?['isPaused'] == true ? Icons.play_arrow : Icons.pause,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        const SizedBox(width: 20),
        IconButton(
          onPressed: () async {
            final spotifyService = SpotifyService.instance;
            await spotifyService.skipNext();
          },
          icon: const Icon(Icons.skip_next, color: Colors.white, size: 36),
        ),
        const SizedBox(width: 20),
        IconButton(
          onPressed: () async {
            setState(() => _repeatMode = !_repeatMode);
            await _saveUserPreferences();
            final spotifyService = SpotifyService.instance;
            await spotifyService.setRepeatMode(_repeatMode ? 1 : 0); // 0 = off, 1 = track, 2 = context
          },
          icon: Icon(
            Icons.repeat,
            color: _repeatMode ? Colors.greenAccent : Colors.white54,
            size: 28,
          ),
        ),
      ],
    );
  }

  Widget _buildReactionBar() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _musicReactions.length,
        itemBuilder: (context, index) {
          final reaction = _musicReactions[index];
          return GestureDetector(
            onTap: () => _sendReaction(reaction),
            child: AnimatedBuilder(
              animation: _reactionController,
              builder: (context, child) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    onPressed: () => _sendReaction(reaction),
                    icon: Text(
                      reaction,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoMusicPlaying() {
    return Container(
      height: 300,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_off,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'No music playing',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _connectToSpotify,
            icon: const Icon(Icons.music_note),
            label: const Text('Connect Spotify'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListenersRow() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Listening Together (${_listeners.length})',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _listeners.length,
              itemBuilder: (context, index) {
                final listener = _listeners[index];
                final profile = listener['profiles'];
                
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: profile?['avatar_url'] != null
                            ? NetworkImage(profile['avatar_url'])
                            : null,
                        child: profile?['avatar_url'] == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile?['display_name'] ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsPage() {
    return Column(
      children: [
        const SizedBox(height: 60),
        // Header with create button
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Text(
                'Music Rooms',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              FloatingActionButton(
                mini: true,
                onPressed: _showCreateRoomDialog,
                backgroundColor: Colors.pinkAccent,
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        
        // Rooms list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _rooms.length,
            itemBuilder: (context, index) {
              final room = _rooms[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.music_note,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    room['name'] ?? 'Unnamed Room',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (room['description'] != null)
                        Text(
                          room['description'],
                          style: TextStyle(color: Colors.white.withOpacity(0.7)),
                        ),
                      Row(
                        children: [
                          Icon(Icons.people, size: 14, color: Colors.white.withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Text(
                            '${room['listener_count'] ?? 0} listening',
                            style: TextStyle(color: Colors.white.withOpacity(0.7)),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${room['mood'] ?? 'Vibing'}',
                            style: const TextStyle(color: Colors.pinkAccent),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  onTap: () => _joinRoom(room['id']),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchPage() {
    return Column(
      children: [
        const SizedBox(height: 60),
        // Search bar
        Padding(
          padding: const EdgeInsets.all(20),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search for songs, artists, albums...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _isSearching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      onPressed: () => _searchSpotifyTracks(_searchController.text),
                      icon: const Icon(Icons.search, color: Colors.pinkAccent),
                    ),
            ),
            onSubmitted: _searchSpotifyTracks,
          ),
        ),
        
        // Search results
        Expanded(
          child: _searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search,
                        size: 80,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Search for music to add to queue',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final track = _searchResults[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            track['image'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey,
                                child: const Icon(Icons.music_note),
                              );
                            },
                          ),
                        ),
                        title: Text(
                          track['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          track['artist'],
                          style: TextStyle(color: Colors.white.withOpacity(0.7)),
                        ),
                        trailing: IconButton(
                          onPressed: () => _addToQueue(track),
                          icon: const Icon(Icons.add_circle, color: Colors.pinkAccent),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildQueuePage() {
    return Column(
      children: [
        const SizedBox(height: 60),
        // Queue header
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Text(
                'Queue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_queue.length} songs',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            ],
          ),
        ),
        
        // Queue list
        Expanded(
          child: _queue.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.queue_music,
                        size: 80,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Queue is empty',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add songs from the search page',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _queue.length,
                  onReorder: (oldIndex, newIndex) {
                    // Handle reordering
                  },
                  itemBuilder: (context, index) {
                    final track = _queue[index];
                    return Container(
                      key: ValueKey(track['id']),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        title: Text(
                          track['track_name'] ?? 'Unknown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          track['artist_name'] ?? 'Unknown Artist',
                          style: TextStyle(color: Colors.white.withOpacity(0.7)),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _voteForTrack(track['id'], true),
                              icon: const Icon(Icons.thumb_up, color: Colors.greenAccent, size: 20),
                            ),
                            if (_isHost)
                              IconButton(
                                onPressed: () {
                                  // Remove from queue
                                },
                                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFloatingPet() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          bottom: 120 + math.sin(_particleController.value * 2 * math.pi) * 15,
          right: 20,
          child: GestureDetector(
            onTap: () {
              // Pet interaction
              setState(() {
                _petEmotion = _petEmotions[math.Random().nextInt(_petEmotions.length)];
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _petIsHappy
                      ? [Colors.pinkAccent, Colors.purpleAccent]
                      : [Colors.grey, Colors.blueGrey],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pinkAccent.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Text(
                _petEmotion,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingControls() {
    return Positioned(
      top: 50,
      right: 20,
      child: Column(
        children: [
          FloatingActionButton(
            mini: true,
            heroTag: 'mood',
            onPressed: () {
              // Mood selector
            },
            backgroundColor: Colors.purpleAccent.withOpacity(0.8),
            child: const Icon(Icons.mood),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            mini: true,
            heroTag: 'settings',
            onPressed: () {
              // Settings
            },
            backgroundColor: Colors.blueAccent.withOpacity(0.8),
            child: const Icon(Icons.settings),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentPage,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.white.withOpacity(0.7),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'Player',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Rooms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.queue_music),
            label: 'Queue',
          ),
        ],
      ),
    );
  }
}

// Enhanced Wave Painter with audio reactivity
class EnhancedWavePainter extends CustomPainter {
  final double animationValue;
  final List<double> beatData;
  final bool isPlaying;

  EnhancedWavePainter(this.animationValue, this.beatData, this.isPlaying);

  @override
  void paint(Canvas canvas, Size size) {
    if (!isPlaying) return;

    // Multiple wave layers with different frequencies
    _drawWaveLayer(canvas, size, Colors.pinkAccent.withOpacity(0.3), 1.0, 0);
    _drawWaveLayer(canvas, size, Colors.purpleAccent.withOpacity(0.2), 1.5, 0.5);
    _drawWaveLayer(canvas, size, Colors.blueAccent.withOpacity(0.1), 2.0, 1.0);
  }

  void _drawWaveLayer(Canvas canvas, Size size, Color color, double frequency, double offset) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    final waveHeight = 40.0;
    final waveLength = size.width / (2 * frequency);

    path.moveTo(0, size.height / 2);

    for (double x = 0; x <= size.width; x += 2) {
      final beatIndex = ((x / size.width) * beatData.length).floor();
      final beatMultiplier = beatIndex < beatData.length ? beatData[beatIndex] : 0.5;
      
      final y = size.height / 2 +
          waveHeight *
              beatMultiplier *
              math.sin((x / waveLength * 2 * math.pi) + 
                      (animationValue * 2 * math.pi) + offset);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Spectrum Painter for frequency visualization
class SpectrumPainter extends CustomPainter {
  final List<double> spectrumData;
  final double animationValue;

  SpectrumPainter(this.spectrumData, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final barWidth = size.width / spectrumData.length;

    for (int i = 0; i < spectrumData.length; i++) {
      final height = spectrumData[i] * size.height * 0.3 * (1 + animationValue * 0.5);
      final hue = (i / spectrumData.length) * 360;
      
      paint.color = HSVColor.fromAHSV(0.6, hue, 1.0, 1.0).toColor();
      
      canvas.drawRect(
        Rect.fromLTWH(
          i * barWidth,
          size.height - height,
          barWidth - 1,
          height,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
