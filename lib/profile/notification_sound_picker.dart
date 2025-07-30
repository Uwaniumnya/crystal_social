import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationSoundPicker extends StatefulWidget {
  final String userId;
  const NotificationSoundPicker({super.key, required this.userId});

  @override
  State<NotificationSoundPicker> createState() =>
      _NotificationSoundPickerState();
}

class _NotificationSoundPickerState extends State<NotificationSoundPicker>
    with TickerProviderStateMixin {
  final player = AudioPlayer();
  String? selectedSound;
  bool isLoading = true;
  bool isPlaying = false;
  String? currentlyPlayingSound;
  double volume = 0.7;
  String selectedCategory = 'All';
  bool showVolumeSlider = false;
  
  late AnimationController _fadeController;
  late AnimationController _bounceController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;

  final Map<String, List<Map<String, dynamic>>> categorizedSounds = {
    'Magical': [
      {
        'file': 'sparkle.mp3',
        'name': 'Crystal Sparkle',
        'description': 'Magical twinkling sound',
        'icon': Icons.auto_awesome,
        'color': Colors.purple,
        'duration': '2s',
        'premium': false,
      },
      {
        'file': 'mystic_chime.mp3',
        'name': 'Mystic Chime',
        'description': 'Enchanting mystical chime',
        'icon': Icons.music_note,
        'color': Colors.deepPurple,
        'duration': '3s',
        'premium': false,
      },
      {
        'file': 'fairy_bells.mp3',
        'name': 'Fairy Bells',
        'description': 'Delicate fairy bell melody',
        'icon': Icons.elderly,
        'color': Colors.pink,
        'duration': '2.5s',
        'premium': true,
      },
    ],
    'Cute': [
      {
        'file': 'bubblepop.mp3',
        'name': 'Bubble Pop',
        'description': 'Playful bubble popping',
        'icon': Icons.bubble_chart,
        'color': Colors.blue,
        'duration': '1.5s',
        'premium': false,
      },
      {
        'file': 'dreamy_ping.mp3',
        'name': 'Dreamy Ping',
        'description': 'Soft dreamy notification',
        'icon': Icons.cloud,
        'color': Colors.lightBlue,
        'duration': '2s',
        'premium': false,
      },
      {
        'file': 'kawaii_chirp.mp3',
        'name': 'Kawaii Chirp',
        'description': 'Adorable chirping sound',
        'icon': Icons.favorite,
        'color': Colors.pink,
        'duration': '1.8s',
        'premium': true,
      },
    ],
    'Nature': [
      {
        'file': 'wind_chimes.mp3',
        'name': 'Wind Chimes',
        'description': 'Peaceful wind chimes',
        'icon': Icons.air,
        'color': Colors.green,
        'duration': '4s',
        'premium': false,
      },
      {
        'file': 'rain_drops.mp3',
        'name': 'Rain Drops',
        'description': 'Gentle rain droplets',
        'icon': Icons.water_drop,
        'color': Colors.blueGrey,
        'duration': '3s',
        'premium': true,
      },
    ],
    'Classic': [
      {
        'file': 'gentle_bell.mp3',
        'name': 'Gentle Bell',
        'description': 'Classic notification bell',
        'icon': Icons.notifications,
        'color': Colors.amber,
        'duration': '2s',
        'premium': false,
      },
      {
        'file': 'soft_ding.mp3',
        'name': 'Soft Ding',
        'description': 'Simple notification ding',
        'icon': Icons.campaign,
        'color': Colors.orange,
        'duration': '1s',
        'premium': false,
      },
    ],
  };

  List<String> get categories => ['All', ...categorizedSounds.keys];

  List<Map<String, dynamic>> get filteredSounds {
    if (selectedCategory == 'All') {
      return categorizedSounds.values.expand((sounds) => sounds).toList();
    }
    return categorizedSounds[selectedCategory] ?? [];
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserPreference();
    _setupAudioPlayer();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _bounceAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    
    _fadeController.forward();
  }

  void _setupAudioPlayer() {
    player.setVolume(volume);
    player.playerStateStream.listen((state) {
      setState(() {
        isPlaying = state.playing;
        if (!state.playing) {
          currentlyPlayingSound = null;
        }
      });
    });
  }

  Future<void> _loadUserPreference() async {
    try {
      final res = await Supabase.instance.client
          .from('user_preferences')
          .select('notification_sound, notification_volume')
          .eq('user_id', widget.userId)
          .maybeSingle();

      setState(() {
        selectedSound = res?['notification_sound'] as String?;
        volume = (res?['notification_volume'] as double?) ?? 0.7;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveUserPreference(String soundFile) async {
    try {
      await Supabase.instance.client.from('user_preferences').upsert({
        'user_id': widget.userId,
        'notification_sound': soundFile,
        'notification_volume': volume,
        'updated_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        selectedSound = soundFile;
      });

      // Trigger bounce animation
      _bounceController.reset();
      _bounceController.forward();

      // Haptic feedback
      HapticFeedback.lightImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Notification sound updated!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preference: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _playPreview(Map<String, dynamic> soundData) async {
    try {
      final soundFile = soundData['file'] as String;
      
      // Stop current playback if any
      if (isPlaying) {
        await player.stop();
      }

      setState(() {
        currentlyPlayingSound = soundFile;
      });

      await player.setAsset('assets/notification_sounds/$soundFile');
      await player.setVolume(volume);
      await player.play();

      // Haptic feedback for premium sounds
      if (soundData['premium'] == true) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      setState(() {
        currentlyPlayingSound = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play preview: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _updateVolume(double newVolume) {
    setState(() {
      volume = newVolume;
    });
    player.setVolume(volume);
    
    // Save volume preference
    Supabase.instance.client.from('user_preferences').upsert({
      'user_id': widget.userId,
      'notification_volume': volume,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _bounceController.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade400,
              Colors.pink.shade400,
              Colors.deepPurple.shade500,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildVolumeControl(),
              _buildCategoryTabs(),
              Expanded(
                child: isLoading
                    ? _buildLoadingState()
                    : _buildSoundsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notification Sounds',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Choose your perfect sound',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              showVolumeSlider ? Icons.volume_up : Icons.volume_down,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                showVolumeSlider = !showVolumeSlider;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeControl() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height: showVolumeSlider ? 80 : 0,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedOpacity(
        opacity: showVolumeSlider ? 1.0 : 0.0,
        duration: Duration(milliseconds: 300),
        child: Card(
          color: Colors.white.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.volume_down, color: Colors.white),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white.withOpacity(0.3),
                      thumbColor: Colors.white,
                      overlayColor: Colors.white.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: volume,
                      onChanged: _updateVolume,
                      min: 0.0,
                      max: 1.0,
                    ),
                  ),
                ),
                Icon(Icons.volume_up, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  '${(volume * 100).round()}%',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = category;
              });
              HapticFeedback.selectionClick();
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              margin: EdgeInsets.only(right: 12),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white 
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.purple : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Loading your sounds...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundsList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: ListView.separated(
          padding: EdgeInsets.all(20),
          itemCount: filteredSounds.length,
          separatorBuilder: (_, __) => SizedBox(height: 12),
          itemBuilder: (context, index) {
            final soundData = filteredSounds[index];
            return _buildSoundTile(soundData);
          },
        ),
      ),
    );
  }

  Widget _buildSoundTile(Map<String, dynamic> soundData) {
    final soundFile = soundData['file'] as String;
    final isSelected = soundFile == selectedSound;
    final isCurrentlyPlaying = currentlyPlayingSound == soundFile && isPlaying;
    final isPremium = soundData['premium'] as bool;

    return ScaleTransition(
      scale: isSelected ? _bounceAnimation : 
             Tween<double>(begin: 1.0, end: 1.0).animate(_bounceController),
      child: Card(
        elevation: isSelected ? 8 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isSelected ? Colors.purple.shade50 : Colors.white,
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: (soundData['color'] as Color).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: isSelected 
                  ? Border.all(color: Colors.purple, width: 2)
                  : null,
            ),
            child: Icon(
              soundData['icon'] as IconData,
              color: soundData['color'] as Color,
              size: 24,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  soundData['name'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isSelected ? Colors.purple : Colors.black87,
                  ),
                ),
              ),
              if (isPremium)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'PREMIUM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Text(
                soundData['description'] as String,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.timer, size: 12, color: Colors.grey[500]),
                  SizedBox(width: 4),
                  Text(
                    soundData['duration'] as String,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  isCurrentlyPlaying ? Icons.stop : Icons.play_arrow,
                  color: soundData['color'] as Color,
                ),
                onPressed: () {
                  if (isCurrentlyPlaying) {
                    player.stop();
                  } else {
                    _playPreview(soundData);
                  }
                },
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Colors.purple,
                  size: 24,
                ),
            ],
          ),
          onTap: () => _saveUserPreference(soundFile),
        ),
      ),
    );
  }
}
