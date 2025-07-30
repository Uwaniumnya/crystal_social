import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_production_config.dart';

class PerUserRingtonePicker extends StatefulWidget {
  final String ownerId; // current user
  final String senderId; // user to assign sound for
  final String? senderName; // optional sender name for display

  const PerUserRingtonePicker({
    super.key,
    required this.ownerId,
    required this.senderId,
    this.senderName,
  });

  @override
  State<PerUserRingtonePicker> createState() => _PerUserRingtonePickerState();
}

class _PerUserRingtonePickerState extends State<PerUserRingtonePicker> 
    with TickerProviderStateMixin {
  final player = AudioPlayer();
  String? selectedSound;
  bool _isLoading = true;
  bool _isPlaying = false;
  String? _currentlyPlayingSound;
  double _volume = 0.7;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Enhanced sound list with metadata
  final List<Map<String, dynamic>> availableSounds = [
    // Original notification sounds (in root notifications folder)
    {
      'filename': 'sparkle.mp3',
      'displayName': 'Sparkle',
      'description': 'Magical sparkle sound',
      'icon': Icons.auto_awesome,
      'color': Colors.pink,
      'category': 'Magical',
      'isRingtone': false,
      'folderPath': 'root', // assets/notification_sounds/
    },
    {
      'filename': 'bubblepop.mp3',
      'displayName': 'Bubble Pop',
      'description': 'Playful bubble popping',
      'icon': Icons.bubble_chart,
      'color': Colors.blue,
      'category': 'Playful',
      'isRingtone': false,
      'folderPath': 'root',
    },
    {
      'filename': 'mystic_chime.mp3',
      'displayName': 'Mystic Chime',
      'description': 'Mystical wind chime',
      'icon': Icons.music_note,
      'color': Colors.purple,
      'category': 'Mystical',
      'isRingtone': false,
      'folderPath': 'root',
    },
    {
      'filename': 'dreamy_ping.mp3',
      'displayName': 'Dreamy Ping',
      'description': 'Soft dreamy notification',
      'icon': Icons.nights_stay,
      'color': Colors.indigo,
      'category': 'Dreamy',
      'isRingtone': false,
      'folderPath': 'root',
    },
    {
      'filename': 'crystal_bell.mp3',
      'displayName': 'Crystal Bell',
      'description': 'Clear crystal bell tone',
      'icon': Icons.notifications_active,
      'color': Colors.teal,
      'category': 'Classic',
      'isRingtone': false,
      'folderPath': 'root',
    },
    {
      'filename': 'fairy_whisper.mp3',
      'displayName': 'Fairy Whisper',
      'description': 'Gentle fairy-like sound',
      'icon': Icons.flutter_dash,
      'color': Colors.green,
      'category': 'Magical',
      'isRingtone': false,
      'folderPath': 'root',
    },
    
    // New notification sounds (in notifications subfolder)
    {
      'filename': 'message.mp3',
      'displayName': 'Message',
      'description': 'Classic message notification',
      'icon': Icons.message,
      'color': Colors.blue,
      'category': 'Classic',
      'isRingtone': false,
      'folderPath': 'notifications',
    },
    {
      'filename': 'whistle.mp3',
      'displayName': 'Whistle',
      'description': 'Clear whistle sound',
      'icon': Icons.sports_soccer,
      'color': Colors.orange,
      'category': 'Fun',
      'isRingtone': false,
      'folderPath': 'notifications',
    },
    {
      'filename': 'cute_magical_bell.mp3',
      'displayName': 'Cute Magical Bell',
      'description': 'Adorable magical bell tone',
      'icon': Icons.pets,
      'color': Colors.pink,
      'category': 'Cute',
      'isRingtone': false,
      'folderPath': 'notifications',
    },
    {
      'filename': 'bubble_pop.mp3',
      'displayName': 'Bubble Pop',
      'description': 'Fun bubble popping sound',
      'icon': Icons.bubble_chart,
      'color': Colors.cyan,
      'category': 'Playful',
      'isRingtone': false,
      'folderPath': 'notifications',
    },
    {
      'filename': 'squid_game_notificatio.mp3',
      'displayName': 'Squid Game',
      'description': 'Iconic Squid Game notification',
      'icon': Icons.games,
      'color': Colors.red,
      'category': 'Gaming',
      'isRingtone': false,
      'folderPath': 'notifications',
    },
    {
      'filename': 'mario_coin.mp3',
      'displayName': 'Mario Coin',
      'description': 'Classic Mario coin sound',
      'icon': Icons.monetization_on,
      'color': Colors.yellow,
      'category': 'Gaming',
      'isRingtone': false,
      'folderPath': 'notifications',
    },
    {
      'filename': 'gta_notifaction_bell.mp3',
      'displayName': 'GTA Bell',
      'description': 'GTA-style notification bell',
      'icon': Icons.car_rental,
      'color': Colors.grey,
      'category': 'Gaming',
      'isRingtone': false,
      'folderPath': 'notifications',
    },
    {
      'filename': 'cute_sound.mp3',
      'displayName': 'Cute Sound',
      'description': 'Sweet and cute notification',
      'icon': Icons.favorite,
      'color': Colors.pink,
      'category': 'Cute',
      'isRingtone': false,
      'folderPath': 'notifications',
    },
    {
      'filename': 'bewwitched.mp3',
      'displayName': 'Bewitched',
      'description': 'Magical bewitching sound',
      'icon': Icons.auto_fix_high,
      'color': Colors.purple,
      'category': 'Mystical',
      'isRingtone': false,
      'folderPath': 'notifications',
    },
    {
      'filename': 'kill_bill.mp3',
      'displayName': 'Kill Bill',
      'description': 'Iconic Kill Bill whistle',
      'icon': Icons.music_note,
      'color': Colors.black,
      'category': 'Movie',
      'isRingtone': false,
      'folderPath': 'notifications',
    },
    
    // Ringtones (in ringtones subfolder)
    {
      'filename': 'kawaii.mp3',
      'displayName': 'Kawaii',
      'description': 'Cute and adorable tune',
      'icon': Icons.favorite,
      'color': Colors.pink,
      'category': 'K-Pop',
      'isRingtone': true,
      'folderPath': 'ringtones',
    },
    {
      'filename': 'calm.mp3',
      'displayName': 'Calm',
      'description': 'Peaceful and relaxing melody',
      'icon': Icons.spa,
      'color': Colors.blue,
      'category': 'Chill',
      'isRingtone': true,
      'folderPath': 'ringtones',
    },
    {
      'filename': 'cute_circus.mp3',
      'displayName': 'Cute Circus',
      'description': 'Playful circus-themed melody',
      'icon': Icons.celebration,
      'color': Colors.orange,
      'category': 'Playful',
      'isRingtone': true,
      'folderPath': 'ringtones',
    },
    {
      'filename': 'perfect_night.mp3',
      'displayName': 'Perfect Night',
      'description': 'Beautiful evening vibe',
      'icon': Icons.nightlight,
      'color': Colors.purple,
      'category': 'K-Pop',
      'isRingtone': true,
      'folderPath': 'ringtones',
    },
    {
      'filename': 'cupid_twin_ver.mp3',
      'displayName': 'Cupid (Twin Ver)',
      'description': 'Romantic twin version',
      'icon': Icons.favorite_border,
      'color': Colors.red,
      'category': 'K-Pop',
      'isRingtone': true,
      'folderPath': 'ringtones',
    },
    {
      'filename': 'our_date.mp3',
      'displayName': 'Our Date',
      'description': 'Sweet romantic melody',
      'icon': Icons.date_range,
      'color': Colors.pink,
      'category': 'Romance',
      'isRingtone': true,
      'folderPath': 'ringtones',
    },
    {
      'filename': 'hazelnut_cheesecake.mp3',
      'displayName': 'Hazelnut Cheesecake',
      'description': 'Sweet and delightful tune',
      'icon': Icons.cake,
      'color': Colors.brown,
      'category': 'Cute',
      'isRingtone': true,
      'folderPath': 'ringtones',
    },
    {
      'filename': 'pastel.mp3',
      'displayName': 'Pastel',
      'description': 'Soft pastel vibes',
      'icon': Icons.palette,
      'color': Colors.teal,
      'category': 'Chill',
      'isRingtone': true,
      'folderPath': 'ringtones',
    },
    {
      'filename': 'super_shy.mp3',
      'displayName': 'Super Shy',
      'description': 'Adorably shy melody',
      'icon': Icons.face,
      'color': Colors.pink,
      'category': 'K-Pop',
      'isRingtone': true,
      'folderPath': 'ringtones',
    },
    {
      'filename': 'new_jeans.mp3',
      'displayName': 'New Jeans',
      'description': 'Fresh and trendy sound',
      'icon': Icons.style,
      'color': Colors.indigo,
      'category': 'K-Pop',
      'isRingtone': true,
      'folderPath': 'ringtones',
    },
    {
      'filename': 'magnetic.mp3',
      'displayName': 'Magnetic',
      'description': 'Irresistibly catchy tune',
      'icon': Icons.attractions,
      'color': Colors.purple,
      'category': 'K-Pop',
      'isRingtone': true,
      'folderPath': 'ringtones',
    },
    {
      'filename': 'money.mp3',
      'displayName': 'Money',
      'description': 'Bold and confident beat',
      'icon': Icons.attach_money,
      'color': Colors.green,
      'category': 'Hip-Hop',
      'isRingtone': true,
      'folderPath': 'ringtones',
    },
    {
      'filename': 'forever.mp3',
      'displayName': 'Forever',
      'description': 'Eternal and beautiful melody',
      'icon': Icons.all_inclusive,
      'color': Colors.deepPurple,
      'category': 'Romance',
      'isRingtone': true,
      'folderPath': 'ringtones',
    },
    {
      'filename': 'crazy.mp3',
      'displayName': 'Crazy',
      'description': 'Wild and energetic beat',
      'icon': Icons.flash_on,
      'color': Colors.red,
      'category': 'Energetic',
      'isRingtone': true,
      'folderPath': 'ringtones',
    },
    {
      'filename': 'drip.mp3',
      'displayName': 'Drip',
      'description': 'Cool and stylish vibe',
      'icon': Icons.water_drop,
      'color': Colors.cyan,
      'category': 'Hip-Hop',
      'isRingtone': true,
      'folderPath': 'ringtones',
    },
  ];

  String _selectedCategory = 'All';
  List<String> get categories => ['All', ...availableSounds.map((s) => s['category'] as String).toSet().toList()];
  
  List<Map<String, dynamic>> get filteredSounds {
    if (_selectedCategory == 'All') return availableSounds;
    return availableSounds.where((s) => s['category'] == _selectedCategory).toList();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _loadCustomRingtone();
    _animationController.forward();
    
    // Set initial volume
    player.setVolume(_volume);
  }

  @override
  void dispose() {
    _animationController.dispose();
    player.dispose();
    super.dispose();
  }

  Future<void> _loadCustomRingtone() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final res = await Supabase.instance.client
          .from('user_ringtones')
          .select('sound')
          .eq('owner_id', widget.ownerId)
          .eq('sender_id', widget.senderId)
          .maybeSingle();

      setState(() {
        selectedSound = res?['sound'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      ProfileDebugUtils.logError('loadCustomRingtone', e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCustomRingtone(String soundFilename) async {
    try {
      await Supabase.instance.client.from('user_ringtones').upsert({
        'owner_id': widget.ownerId,
        'sender_id': widget.senderId,
        'sound': soundFilename,
        'updated_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        selectedSound = soundFilename;
      });
      
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ Ringtone saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error saving custom ringtone: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to save ringtone'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _playPreview(String assetName) async {
    if (_isPlaying) {
      await player.stop();
      setState(() {
        _isPlaying = false;
        _currentlyPlayingSound = null;
      });
      return;
    }

    try {
      setState(() {
        _isPlaying = true;
        _currentlyPlayingSound = assetName;
      });

      // Find the sound data to determine the correct folder path
      final soundData = availableSounds.firstWhere(
        (sound) => sound['filename'] == assetName,
        orElse: () => {'folderPath': 'root'},
      );
      
      final folderPath = soundData['folderPath'] as String? ?? 'root';
      String assetPath;
      
      switch (folderPath) {
        case 'notifications':
          assetPath = 'assets/notification_sounds/notifications/$assetName';
          break;
        case 'ringtones':
          assetPath = 'assets/notification_sounds/ringtones/$assetName';
          break;
        case 'root':
        default:
          assetPath = 'assets/notification_sounds/$assetName';
          break;
      }

      await player.setAsset(assetPath);
      await player.setVolume(_volume);
      await player.play();
      
      // Auto-stop after playback
      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() {
            _isPlaying = false;
            _currentlyPlayingSound = null;
          });
        }
      });
    } catch (e) {
      print('❌ Failed to play preview: $e');
      setState(() {
        _isPlaying = false;
        _currentlyPlayingSound = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to play sound preview'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showVolumeSlider() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.volume_up, color: Colors.pink),
            SizedBox(width: 8),
            Text('Volume Settings'),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Preview Volume: ${(_volume * 100).round()}%'),
              Slider(
                value: _volume,
                onChanged: (value) {
                  setDialogState(() {
                    _volume = value;
                  });
                  setState(() {
                    _volume = value;
                  });
                  player.setVolume(_volume);
                },
                activeColor: Colors.pink,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Done'),
          ),
        ],
      ),
    );
  }

  void _resetToDefault() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.refresh, color: Colors.orange),
            SizedBox(width: 8),
            Text('Reset Ringtone'),
          ],
        ),
        content: Text('Reset to default notification sound for this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Supabase.instance.client
                    .from('user_ringtones')
                    .delete()
                    .eq('owner_id', widget.ownerId)
                    .eq('sender_id', widget.senderId);
                
                setState(() {
                  selectedSound = null;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🔄 Reset to default ringtone'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Failed to reset ringtone'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Custom Ringtone",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (widget.senderName != null)
              Text(
                "for ${widget.senderName}",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.volume_up),
            onPressed: _showVolumeSlider,
            tooltip: 'Volume Settings',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetToDefault,
            tooltip: 'Reset to Default',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.pink),
                  SizedBox(height: 16),
                  Text('Loading ringtones...'),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Category Filter
                  Container(
                    height: 60,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = category == _selectedCategory;
                        
                        return Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                            selectedColor: Colors.pink.withOpacity(0.2),
                            checkmarkColor: Colors.pink,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.pink : Colors.grey[700],
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Current Selection Info
                  if (selectedSound != null)
                    Container(
                      margin: EdgeInsets.all(16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.pink.shade50, Colors.purple.shade50],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.pink.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.pink),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Currently Selected',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.pink,
                                  ),
                                ),
                                Text(
                                  _getSoundDisplayName(selectedSound!),
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _currentlyPlayingSound == selectedSound && _isPlaying
                                  ? Icons.stop_circle
                                  : Icons.play_circle,
                              color: Colors.pink,
                            ),
                            onPressed: () => _playPreview(selectedSound!),
                          ),
                        ],
                      ),
                    ),

                  // Sound List
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: filteredSounds.length,
                      itemBuilder: (context, index) {
                        final soundData = filteredSounds[index];
                        final filename = soundData['filename'] as String;
                        final isSelected = filename == selectedSound;
                        final isCurrentlyPlaying = _currentlyPlayingSound == filename && _isPlaying;

                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          child: Card(
                            elevation: isSelected ? 8 : 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected ? Colors.pink : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: (soundData['color'] as Color).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  soundData['icon'] as IconData,
                                  color: soundData['color'] as Color,
                                  size: 28,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    soundData['displayName'] as String,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.pink : null,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  if (soundData['isRingtone'] == true)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.purple,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'RINGTONE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'NOTIFICATION',
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
                                  Text(soundData['description'] as String),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.category, size: 14, color: Colors.grey),
                                      SizedBox(width: 4),
                                      Text(
                                        soundData['category'] as String,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.pink,
                                      size: 28,
                                    ),
                                  SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(
                                      isCurrentlyPlaying ? Icons.stop : Icons.play_arrow,
                                      color: isCurrentlyPlaying ? Colors.red : Colors.pink,
                                    ),
                                    onPressed: () => _playPreview(filename),
                                    tooltip: isCurrentlyPlaying ? 'Stop' : 'Preview',
                                  ),
                                ],
                              ),
                              onTap: () => _saveCustomRingtone(filename),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      
      // Bottom info panel
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tap to select • Press play to preview • Long press for volume',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSoundDisplayName(String filename) {
    final soundData = availableSounds.firstWhere(
      (sound) => sound['filename'] == filename,
      orElse: () => {'displayName': filename.replaceAll('.mp3', '')},
    );
    return soundData['displayName'] as String;
  }
}
