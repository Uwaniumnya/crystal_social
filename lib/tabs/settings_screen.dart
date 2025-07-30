import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

import '../profile/enhanced_profile_screen.dart';
import '../profile/avatar_picker.dart';
import '../widgets/background_picker.dart';
import '../admin/support_dashboard.dart';
import '../admin/admin_access.dart';
import '../services/notification_preferences_service.dart';
import 'notification_preferences_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

/// Enhanced Settings Screen with advanced customization and social features
class EnhancedSettingsScreen extends StatefulWidget {
  final String userId;
  const EnhancedSettingsScreen({super.key, required this.userId});

  @override
  State<EnhancedSettingsScreen> createState() => _EnhancedSettingsScreenState();
}

class _EnhancedSettingsScreenState extends State<EnhancedSettingsScreen>
    with TickerProviderStateMixin {
  // Enhanced notification settings
  NotificationPreferences? _notificationPreferences;
  bool _loadingNotificationPrefs = false;
  
  // Existing settings
  bool _isDark = false;
  bool _loadingSettings = true;
  bool _isSleepy = false;
  bool _sleepyAutoReply = false;
  String? selectedRingtone;
  
  // New enhanced settings
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _readReceiptsEnabled = true;
  bool _onlineStatusVisible = true;
  bool _typingIndicatorEnabled = true;
  bool _animationsEnabled = true;
  bool _hapticsEnabled = true;
  double _fontSize = 16.0;
  double _chatBubbleOpacity = 1.0;
  String _selectedLanguage = 'English';
  String _statusMessage = '';
  String _selectedThemeAccent = 'Pink';
  String _selectedThemeColor = 'kawaii_pink'; // New theme color setting
  bool _autoDownloadMedia = false;
  bool _compressMedia = true;
  int _messageHistoryDays = 30;
  
  // Background settings
  String? _currentBackgroundUrl;
  String? _currentBackgroundPreset;
  double _backgroundOpacity = 1.0;
  double _backgroundBlur = 0.0;
  
  final supabase = Supabase.instance.client;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late TabController _tabController;
  
  // Enhanced ringtone options
  List<String> builtInRingtones = [
    'default_ringtone.mp3',
    'bubblepop.mp3',
    'sparklebell.mp3',
    'mystic_chime.mp3',
    'crystal_melody.mp3',
    'starlight_tune.mp3',
    'dream_whisper.mp3',
  ];
  
  List<String> languages = [
    'English', 'Spanish', 'French', 'German', 'Italian', 
    'Portuguese', 'Japanese', 'Korean', 'Chinese', 'Russian'
  ];
  
  List<String> themeAccents = [
    'Pink', 'Purple', 'Blue', 'Green', 'Orange', 'Red', 'Teal', 'Indigo'
  ];

  // Available theme colors with display names and descriptions
  List<Map<String, dynamic>> themeColors = [
    {
      'key': 'kawaii_pink',
      'name': 'Kawaii Pink',
      'description': 'Cute and adorable pink theme',
      'primaryColor': const Color(0xFFFFB6C1),
      'accentColor': const Color(0xFFFF69B4),
    },
    {
      'key': 'blood_red',
      'name': 'Blood Red',
      'description': 'Intense crimson red theme',
      'primaryColor': const Color(0xFFDC143C),
      'accentColor': const Color(0xFFB22222),
    },
    {
      'key': 'ice_blue',
      'name': 'Ice Blue',
      'description': 'Cool arctic blue theme',
      'primaryColor': const Color(0xFF87CEEB),
      'accentColor': const Color(0xFF00BFFF),
    },
    {
      'key': 'forest_green',
      'name': 'Forest Green',
      'description': 'Natural forest green theme',
      'primaryColor': const Color(0xFF228B22),
      'accentColor': const Color(0xFF00C851),
    },
    {
      'key': 'royal_purple',
      'name': 'Royal Purple',
      'description': 'Majestic purple theme',
      'primaryColor': const Color(0xFF6A0DAD),
      'accentColor': const Color(0xFF8A2BE2),
    },
    {
      'key': 'sunset_orange',
      'name': 'Sunset Orange',
      'description': 'Warm sunset orange theme',
      'primaryColor': const Color(0xFFFF4500),
      'accentColor': const Color(0xFFFFA500),
    },
    {
      'key': 'midnight_black',
      'name': 'Midnight Black',
      'description': 'Sleek dark theme',
      'primaryColor': const Color(0xFF2C2C2C),
      'accentColor': const Color(0xFF666666),
    },
    {
      'key': 'ocean_teal',
      'name': 'Ocean Teal',
      'description': 'Deep ocean teal theme',
      'primaryColor': const Color(0xFF008B8B),
      'accentColor': const Color(0xFF00CED1),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllSettings();
    _loadNotificationPreferences();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadAllSettings() async {
    setState(() => _loadingSettings = true);
    
    await Future.wait([
      _loadBasicSettings(),
      _loadNotificationSettings(),
      _loadChatSettings(),
      _loadPrivacySettings(),
      _loadAppearanceSettings(),
      _loadBackgroundSettings(),
      _loadNotificationPreferences(),
    ]);
    
    setState(() => _loadingSettings = false);
  }

  /// Load notification preferences from database
  Future<void> _loadNotificationPreferences() async {
    setState(() => _loadingNotificationPrefs = true);
    
    try {
      final preferences = await NotificationPreferencesService.instance.getPreferences(widget.userId);
      if (mounted) {
        setState(() {
          _notificationPreferences = preferences;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading notification preferences: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingNotificationPrefs = false);
      }
    }
  }

  /// Update notification preference
  Future<void> _updateNotificationPreference(String key, dynamic value) async {
    if (_notificationPreferences == null) return;
    
    NotificationPreferences updatedPrefs;
    
    switch (key) {
      case 'messages':
        updatedPrefs = _notificationPreferences!.copyWith(messages: value);
        break;
      case 'achievements':
        updatedPrefs = _notificationPreferences!.copyWith(achievements: value);
        break;
      case 'support':
        updatedPrefs = _notificationPreferences!.copyWith(support: value);
        break;
      case 'system':
        updatedPrefs = _notificationPreferences!.copyWith(system: value);
        break;
      case 'friend_requests':
        updatedPrefs = _notificationPreferences!.copyWith(friendRequests: value);
        break;
      case 'pet_interactions':
        updatedPrefs = _notificationPreferences!.copyWith(petInteractions: value);
        break;
      case 'sound':
        updatedPrefs = _notificationPreferences!.copyWith(sound: value);
        break;
      case 'vibrate':
        updatedPrefs = _notificationPreferences!.copyWith(vibrate: value);
        break;
      case 'quiet_hours_enabled':
        updatedPrefs = _notificationPreferences!.copyWith(quietHoursEnabled: value);
        break;
      case 'quiet_hours_start':
        updatedPrefs = _notificationPreferences!.copyWith(quietHoursStart: value);
        break;
      case 'quiet_hours_end':
        updatedPrefs = _notificationPreferences!.copyWith(quietHoursEnd: value);
        break;
      case 'show_preview':
        updatedPrefs = _notificationPreferences!.copyWith(showPreview: value);
        break;
      case 'group_notifications':
        updatedPrefs = _notificationPreferences!.copyWith(groupNotifications: value);
        break;
      case 'max_notifications_per_hour':
        updatedPrefs = _notificationPreferences!.copyWith(maxNotificationsPerHour: value);
        break;
      default:
        return;
    }
    
    setState(() {
      _notificationPreferences = updatedPrefs;
    });
    
    final success = await NotificationPreferencesService.instance.updatePreferences(widget.userId, updatedPrefs);
    
    if (success) {
      if (_hapticsEnabled) HapticFeedback.lightImpact();
      _showSuccessSnackBar('Notification preferences updated! 🔔');
    } else {
      _showErrorSnackBar('Failed to update notification preferences');
      // Revert the change
      await _loadNotificationPreferences();
    }
  }

  Future<void> _loadBasicSettings() async {
    final data = await supabase
        .from('users')
        .select('prefersDarkMode, isSleepyModeOn, sleepyAutoReply, default_ringtone, status_message')
        .eq('id', widget.userId)
        .maybeSingle();

    if (!mounted || data == null) return;

    setState(() {
      _isDark = data['prefersDarkMode'] ?? false;
      _isSleepy = data['isSleepyModeOn'] ?? false;
      _sleepyAutoReply = data['sleepyAutoReply'] ?? false;
      selectedRingtone = data['default_ringtone'] ?? 'default_ringtone.mp3';
      _statusMessage = data['status_message'] ?? '';
    });
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    });
  }

  Future<void> _loadChatSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _readReceiptsEnabled = prefs.getBool('read_receipts_enabled') ?? true;
      _typingIndicatorEnabled = prefs.getBool('typing_indicator_enabled') ?? true;
      _autoDownloadMedia = prefs.getBool('auto_download_media') ?? false;
      _compressMedia = prefs.getBool('compress_media') ?? true;
      _messageHistoryDays = prefs.getInt('message_history_days') ?? 30;
    });
  }

  Future<void> _loadPrivacySettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _onlineStatusVisible = prefs.getBool('online_status_visible') ?? true;
    });
  }

  Future<void> _loadAppearanceSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _animationsEnabled = prefs.getBool('animations_enabled') ?? true;
      _hapticsEnabled = prefs.getBool('haptics_enabled') ?? true;
      _fontSize = prefs.getDouble('font_size') ?? 16.0;
      _chatBubbleOpacity = prefs.getDouble('chat_bubble_opacity') ?? 1.0;
      _selectedLanguage = prefs.getString('selected_language') ?? 'English';
      _selectedThemeAccent = prefs.getString('theme_accent') ?? 'Pink';
      _selectedThemeColor = prefs.getString('selected_theme_color') ?? 'kawaii_pink';
    });
  }

  Future<void> _loadBackgroundSettings() async {
    try {
      final data = await supabase
          .from('chats')
          .select('background_url, background_preset, background_opacity, background_blur')
          .eq('chat_id', 'global_${widget.userId}')
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _currentBackgroundUrl = data['background_url'] as String?;
          _currentBackgroundPreset = data['background_preset'] as String?;
          _backgroundOpacity = (data['background_opacity'] as num?)?.toDouble() ?? 1.0;
          _backgroundBlur = (data['background_blur'] as num?)?.toDouble() ?? 0.0;
        });
      }
    } catch (e) {
      // If chat record doesn't exist, that's okay - use defaults
      debugPrint('Background settings not found, using defaults');
    }
  }

  Color get _accentColor {
    // First try to get color from selected theme color
    final currentTheme = themeColors.firstWhere(
      (theme) => theme['key'] == _selectedThemeColor,
      orElse: () => themeColors.first,
    );
    
    // Return the accent color from the current theme
    return currentTheme['accentColor'] as Color;
  }

  Future<void> _updateBasicSetting(String field, dynamic value) async {
    await supabase.from('users').update({field: value}).eq('id', widget.userId);
    if (_hapticsEnabled) HapticFeedback.lightImpact();
  }

  Future<void> _updateLocalSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
    if (_hapticsEnabled) HapticFeedback.lightImpact();
  }

  Future<void> _updateThemeColor(String colorKey) async {
    setState(() {
      _selectedThemeColor = colorKey;
    });
    
    await _updateLocalSetting('selected_theme_color', colorKey);
    
    // Show success feedback
    _showSuccessSnackBar('🎨 Theme color updated! Restart the app to see changes.');
  }

  Future<void> _uploadCustomRingtone() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a'],
    );
    if (result == null) return;

    final file = File(result.files.single.path!);
    final fileName = path.basename(file.path);
    final storagePath = '${widget.userId}/ringtones/$fileName';

    try {
      await supabase.storage
          .from('user_content')
          .uploadBinary(storagePath, await file.readAsBytes());

      final publicUrl = supabase.storage.from('user_content').getPublicUrl(storagePath);

      setState(() => selectedRingtone = publicUrl);
      await _updateBasicSetting('default_ringtone', publicUrl);
      
      _showSuccessSnackBar('Custom ringtone uploaded successfully! 🎵');
    } catch (e) {
      _showErrorSnackBar('Failed to upload ringtone: $e');
    }
  }

  Future<void> _previewRingtone(String ringtone) async {
    try {
      if (ringtone.startsWith('http')) {
        await _audioPlayer.play(UrlSource(ringtone));
      } else {
        await _audioPlayer.play(AssetSource('sounds/$ringtone'));
      }
    } catch (e) {
      _showErrorSnackBar('Could not preview ringtone');
    }
  }

  void _openChatBackgroundPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.wallpaper, color: _accentColor, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Chat Background',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              const Divider(),
              
              // Background picker
              Expanded(
                child: EnhancedChatBackgroundPicker(
                  chatId: 'global_${widget.userId}',
                  onBackgroundChanged: (backgroundUrl) {
                    Navigator.pop(context);
                    _loadBackgroundSettings(); // Refresh the preview
                    _showSuccessSnackBar('Background updated! ✨');
                    if (_hapticsEnabled) {
                      HapticFeedback.lightImpact();
                    }
                  },
                  primaryColor: _accentColor,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  showPresets: true,
                  showEffects: true,
                  showCustomization: true,
                  enableCloudSync: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EnhancedProfileScreen(
          userId: widget.userId,
        ),
      ),
    );
  }

  void _openNotificationPreferences() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationPreferencesScreen(
          userId: widget.userId,
        ),
      ),
    ).then((_) {
      // Refresh notification preferences when returning
      _loadNotificationPreferences();
    });
  }

  void _resetAllSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Settings'),
        content: const Text('Are you sure you want to reset all settings to default? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performReset();
            },
            child: Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _performReset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    await supabase.from('users').update({
      'prefersDarkMode': false,
      'isSleepyModeOn': false,
      'sleepyAutoReply': false,
      'default_ringtone': 'default_ringtone.mp3',
      'status_message': '',
    }).eq('id', widget.userId);
    
    await _loadAllSettings();
    _showSuccessSnackBar('Settings reset to default! 🔄');
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

  Widget _buildQuickBackgroundOption(String name, dynamic background, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                gradient: background is LinearGradient ? background : null,
                color: background is Color ? background : null,
              ),
              child: background == null
                  ? const Icon(Icons.close, color: Colors.grey, size: 16)
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setQuickBackground(String? presetId) async {
    try {
      // Update the background in the database
      await supabase.from('chats').upsert({
        'chat_id': 'global_${widget.userId}',
        'background_preset': presetId,
        'background_url': null,
        'background_opacity': 1.0,
        'background_blur': 0.0,
        'background_effect': 'none',
      });

      // Refresh the background preview
      await _loadBackgroundSettings();

      _showSuccessSnackBar(presetId == null 
          ? 'Background reset to default! 🔄'
          : 'Quick background applied! ✨');
      
      if (_hapticsEnabled) {
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update background: $e');
    }
  }

  Widget _buildBackgroundPreview() {
    // If there's a custom background URL
    if (_currentBackgroundUrl != null) {
      return Stack(
        children: [
          Image.network(
            _currentBackgroundUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultPreview();
            },
          ),
          const Center(
            child: Text(
              'Custom Background',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 3,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    
    // If there's a preset
    if (_currentBackgroundPreset != null) {
      return _buildPresetPreview(_currentBackgroundPreset!);
    }
    
    // Default background
    return _buildDefaultPreview();
  }

  Widget _buildPresetPreview(String presetId) {
    LinearGradient? gradient;
    Color? color;
    String text = 'Preset Background';
    
    switch (presetId) {
      case 'gradient_sunset':
        gradient = const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D), Color(0xFF4ECDC4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        text = 'Sunset 🌅';
        break;
      case 'gradient_ocean':
        gradient = const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        text = 'Ocean 🌊';
        break;
      case 'gradient_forest':
        gradient = const LinearGradient(
          colors: [Color(0xFF134E5E), Color(0xFF71B280)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        text = 'Forest 🌲';
        break;
      case 'gradient_space':
        gradient = const LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF4A00E0), Color(0xFF8E2DE2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        text = 'Space 🌌';
        break;
      case 'solid_lavender':
        color = const Color(0xFFE6E6FA);
        text = 'Lavender 💜';
        break;
      case 'solid_mint':
        color = const Color(0xFFF0FFF0);
        text = 'Mint 🌿';
        break;
      default:
        return _buildDefaultPreview();
    }
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        color: color,
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3,
                color: Colors.black54,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultPreview() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey.shade100,
      child: const Center(
        child: Text(
          'Default Background',
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: _accentColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'General'),
            Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
            Tab(icon: Icon(Icons.chat), text: 'Chat'),
            Tab(icon: Icon(Icons.palette), text: 'Appearance'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllSettings,
            tooltip: 'Refresh Settings',
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Reset All Settings'),
                onTap: _resetAllSettings,
              ),
            ],
          ),
        ],
      ),
      body: _loadingSettings
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGeneralTab(),
                _buildNotificationsTab(),
                _buildChatTab(),
                _buildAppearanceTab(),
              ],
            ),
    );
  }

  Widget _buildGeneralTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Avatar Section
        Center(
          child: Column(
            children: [
              AvatarPicker(userId: widget.userId),
              const SizedBox(height: 16),
              Text(
                'Tap to change avatar',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Profile Section
        _buildSectionHeader('Profile', Icons.person),
        ListTile(
          leading: Icon(Icons.person, color: _accentColor),
          title: const Text('Username & Profile'),
          subtitle: const Text('Manage your profile information'),
          trailing: Icon(Icons.arrow_forward_ios, color: _accentColor, size: 16),
          onTap: _openProfile,
        ),
        
        // Status Message
        ListTile(
          leading: Icon(Icons.message, color: _accentColor),
          title: const Text('Status Message'),
          subtitle: Text(_statusMessage.isEmpty ? 'Tap to set status' : _statusMessage),
          trailing: Icon(Icons.edit, color: _accentColor, size: 16),
          onTap: () => _showStatusMessageDialog(),
        ),

        const SizedBox(height: 16),

        // Sleep Mode Section
        _buildSectionHeader('Sleep Mode', Icons.bedtime),
        SwitchListTile(
          secondary: Icon(Icons.bedtime, color: _accentColor),
          title: const Text('Sleepy Mode 😴'),
          subtitle: const Text('Do Not Disturb with fluffy vibes'),
          value: _isSleepy,
          activeColor: _accentColor,
          onChanged: (value) async {
            setState(() => _isSleepy = value);
            await _updateBasicSetting('isSleepyModeOn', value);
          },
        ),
        SwitchListTile(
          secondary: Icon(Icons.auto_awesome, color: _accentColor),
          title: const Text('Auto-reply while sleeping 💌'),
          subtitle: const Text('Send sleepy messages automatically'),
          value: _sleepyAutoReply,
          activeColor: _accentColor,
          onChanged: _isSleepy ? (value) async {
            setState(() => _sleepyAutoReply = value);
            await _updateBasicSetting('sleepyAutoReply', value);
          } : null,
        ),

        const SizedBox(height: 16),

        // Language Section
        _buildSectionHeader('Language & Region', Icons.language),
        ListTile(
          leading: Icon(Icons.language, color: _accentColor),
          title: const Text('Language'),
          subtitle: Text(_selectedLanguage),
          trailing: DropdownButton<String>(
            value: _selectedLanguage,
            underline: const SizedBox(),
            items: languages.map((lang) => DropdownMenuItem(
              value: lang,
              child: Text(lang),
            )).toList(),
            onChanged: (value) async {
              setState(() => _selectedLanguage = value!);
              await _updateLocalSetting('selected_language', value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsTab() {
    if (_loadingNotificationPrefs || _notificationPreferences == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading notification preferences...'),
          ],
        ),
      );
    }

    final prefs = _notificationPreferences!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Main Notification Toggle
        _buildSectionHeader('Master Controls', Icons.notifications_active),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _accentColor.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              SwitchListTile(
                secondary: Icon(Icons.notifications, color: _accentColor),
                title: const Text('Enable Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Master control for all notifications'),
                value: _notificationsEnabled,
                activeColor: _accentColor,
                onChanged: (value) async {
                  setState(() => _notificationsEnabled = value);
                  await _updateLocalSetting('notifications_enabled', value);
                },
              ),
              if (_notificationsEnabled) ...[
                const Divider(),
                SwitchListTile(
                  secondary: Icon(Icons.vibration, color: _accentColor),
                  title: const Text('Vibration'),
                  subtitle: const Text('Vibrate for notifications'),
                  value: prefs.vibrate,
                  activeColor: _accentColor,
                  onChanged: (value) => _updateNotificationPreference('vibrate', value),
                ),
                SwitchListTile(
                  secondary: Icon(Icons.preview, color: _accentColor),
                  title: const Text('Show Message Preview'),
                  subtitle: const Text('Display message content in notifications'),
                  value: prefs.showPreview,
                  activeColor: _accentColor,
                  onChanged: (value) => _updateNotificationPreference('show_preview', value),
                ),
              ],
            ],
          ),
        ),

        if (_notificationsEnabled) ...[
          const SizedBox(height: 24),

          // Advanced Notification Settings
          _buildSectionHeader('Advanced Settings', Icons.settings),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Detailed Notification Control',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Access advanced notification preferences including quiet hours, sound selection, and detailed type controls.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.notifications_active),
                    label: const Text('Open Notification Preferences'),
                    onPressed: () => _openNotificationPreferences(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Notification Types
          _buildSectionHeader('Notification Types', Icons.category),
          _buildNotificationTypeCard(
            icon: Icons.message,
            title: 'Messages',
            subtitle: 'Chat messages and direct messages',
            value: prefs.messages,
            onChanged: (value) => _updateNotificationPreference('messages', value),
          ),
          _buildNotificationTypeCard(
            icon: Icons.emoji_events,
            title: 'Achievements',
            subtitle: 'Level ups, rewards, and accomplishments',
            value: prefs.achievements,
            onChanged: (value) => _updateNotificationPreference('achievements', value),
          ),
          _buildNotificationTypeCard(
            icon: Icons.person_add,
            title: 'Friend Requests',
            subtitle: 'New friend requests and acceptances',
            value: prefs.friendRequests,
            onChanged: (value) => _updateNotificationPreference('friend_requests', value),
          ),
          _buildNotificationTypeCard(
            icon: Icons.pets,
            title: 'Pet Interactions',
            subtitle: 'Pet care reminders and interactions',
            value: prefs.petInteractions,
            onChanged: (value) => _updateNotificationPreference('pet_interactions', value),
          ),
          _buildNotificationTypeCard(
            icon: Icons.support_agent,
            title: 'Support & System',
            subtitle: 'Support responses and system updates',
            value: prefs.support,
            onChanged: (value) => _updateNotificationPreference('support', value),
          ),
          _buildNotificationTypeCard(
            icon: Icons.info,
            title: 'System Notifications',
            subtitle: 'App updates and important announcements',
            value: prefs.system,
            onChanged: (value) => _updateNotificationPreference('system', value),
          ),

          const SizedBox(height: 24),

          // Sound Settings
          _buildSectionHeader('Sound & Audio', Icons.volume_up),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.music_note, color: _accentColor),
                  title: const Text('Notification Sound'),
                  subtitle: Text(prefs.sound == 'default' ? 'Default notification sound' : prefs.sound),
                  trailing: IconButton(
                    icon: Icon(Icons.play_arrow, color: _accentColor),
                    onPressed: () => _previewRingtone(prefs.sound),
                  ),
                ),
                const Divider(),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Choose Sound',
                    border: OutlineInputBorder(),
                  ),
                  value: builtInRingtones.contains(prefs.sound) ? prefs.sound : 'default_ringtone.mp3',
                  items: [
                    const DropdownMenuItem(value: 'default', child: Text('Default')),
                    ...builtInRingtones.map((sound) => DropdownMenuItem(
                      value: sound,
                      child: Text(sound.replaceAll('_', ' ').replaceAll('.mp3', '')),
                    )),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      _updateNotificationPreference('sound', value);
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quiet Hours
          _buildSectionHeader('Quiet Hours', Icons.bedtime),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(Icons.bedtime, color: Colors.purple),
                  title: const Text('Enable Quiet Hours'),
                  subtitle: const Text('Silence notifications during specified hours'),
                  value: prefs.quietHoursEnabled,
                  activeColor: Colors.purple,
                  onChanged: (value) => _updateNotificationPreference('quiet_hours_enabled', value),
                ),
                if (prefs.quietHoursEnabled) ...[
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.schedule, color: Colors.purple),
                    title: const Text('Start Time'),
                    subtitle: Text('Quiet hours start at ${prefs.quietHoursStart}'),
                    trailing: Icon(Icons.edit, color: Colors.purple),
                    onTap: () => _showTimePickerDialog('start', prefs.quietHoursStart),
                  ),
                  ListTile(
                    leading: Icon(Icons.schedule_outlined, color: Colors.purple),
                    title: const Text('End Time'),
                    subtitle: Text('Quiet hours end at ${prefs.quietHoursEnd}'),
                    trailing: Icon(Icons.edit, color: Colors.purple),
                    onTap: () => _showTimePickerDialog('end', prefs.quietHoursEnd),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.purple.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'During quiet hours, only support and system notifications will be shown',
                            style: TextStyle(
                              color: Colors.purple.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Test Notification
          _buildSectionHeader('Test Notifications', Icons.bug_report),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accentColor.withOpacity(0.1), _accentColor.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _accentColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Test Your Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _accentColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Send a test notification to make sure everything is working correctly.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.send),
                        label: const Text('Send Test Notification'),
                        onPressed: () => _sendTestNotification(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChatTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Chat Features', Icons.chat),
        SwitchListTile(
          secondary: Icon(Icons.done_all, color: _accentColor),
          title: const Text('Read Receipts'),
          subtitle: const Text('Show when messages are read'),
          value: _readReceiptsEnabled,
          activeColor: _accentColor,
          onChanged: (value) async {
            setState(() => _readReceiptsEnabled = value);
            await _updateLocalSetting('read_receipts_enabled', value);
          },
        ),
        SwitchListTile(
          secondary: Icon(Icons.edit, color: _accentColor),
          title: const Text('Typing Indicators'),
          subtitle: const Text('Show when someone is typing'),
          value: _typingIndicatorEnabled,
          activeColor: _accentColor,
          onChanged: (value) async {
            setState(() => _typingIndicatorEnabled = value);
            await _updateLocalSetting('typing_indicator_enabled', value);
          },
        ),

        const SizedBox(height: 16),

        _buildSectionHeader('Media & Storage', Icons.photo),
        SwitchListTile(
          secondary: Icon(Icons.download, color: _accentColor),
          title: const Text('Auto-download Media'),
          subtitle: const Text('Automatically download images and videos'),
          value: _autoDownloadMedia,
          activeColor: _accentColor,
          onChanged: (value) async {
            setState(() => _autoDownloadMedia = value);
            await _updateLocalSetting('auto_download_media', value);
          },
        ),
        SwitchListTile(
          secondary: Icon(Icons.compress, color: _accentColor),
          title: const Text('Compress Media'),
          subtitle: const Text('Reduce file sizes when sending'),
          value: _compressMedia,
          activeColor: _accentColor,
          onChanged: (value) async {
            setState(() => _compressMedia = value);
            await _updateLocalSetting('compress_media', value);
          },
        ),

        const SizedBox(height: 16),

        _buildSectionHeader('Chat Appearance', Icons.wallpaper),
        
        // Background Picker - Make it more prominent
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: _accentColor.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                _accentColor.withOpacity(0.1),
                _accentColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.wallpaper,
                color: Colors.white,
                size: 24,
              ),
            ),
            title: const Text(
              'Chat Background',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: const Text(
              'Customize your chat appearance with presets, gradients, and custom images',
              style: TextStyle(fontSize: 12),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Customize',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: _openChatBackgroundPicker,
          ),
        ),

        // Quick Background Options
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Background Options',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickBackgroundOption(
                      'Default',
                      Colors.grey.shade100,
                      () => _setQuickBackground(null),
                    ),
                    _buildQuickBackgroundOption(
                      'Sunset',
                      const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
                      ),
                      () => _setQuickBackground('gradient_sunset'),
                    ),
                    _buildQuickBackgroundOption(
                      'Ocean',
                      const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      () => _setQuickBackground('gradient_ocean'),
                    ),
                    _buildQuickBackgroundOption(
                      'Forest',
                      const LinearGradient(
                        colors: [Color(0xFF134E5E), Color(0xFF71B280)],
                      ),
                      () => _setQuickBackground('gradient_forest'),
                    ),
                    _buildQuickBackgroundOption(
                      'Space',
                      const LinearGradient(
                        colors: [Color(0xFF2C3E50), Color(0xFF4A00E0)],
                      ),
                      () => _setQuickBackground('gradient_space'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        _buildSectionHeader('Data Management', Icons.storage),
        ListTile(
          leading: Icon(Icons.history, color: _accentColor),
          title: const Text('Message History'),
          subtitle: Text('Keep messages for $_messageHistoryDays days'),
          trailing: DropdownButton<int>(
            value: _messageHistoryDays,
            underline: const SizedBox(),
            items: [7, 30, 90, 365].map((days) => DropdownMenuItem(
              value: days,
              child: Text('$days days'),
            )).toList(),
            onChanged: (value) async {
              setState(() => _messageHistoryDays = value!);
              await _updateLocalSetting('message_history_days', value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Theme', Icons.palette),
        SwitchListTile(
          secondary: Icon(Icons.dark_mode, color: _accentColor),
          title: const Text('Dark Mode'),
          subtitle: const Text('Enable darker theme'),
          value: _isDark,
          activeColor: _accentColor,
          onChanged: (value) async {
            setState(() => _isDark = value);
            await _updateBasicSetting('prefersDarkMode', value);
          },
        ),
        
        ListTile(
          leading: Icon(Icons.color_lens, color: _accentColor),
          title: const Text('Accent Color'),
          subtitle: Text(_selectedThemeAccent),
          trailing: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _accentColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          children: themeAccents.map((accent) {
            Color color;
            switch (accent) {
              case 'Purple': color = Colors.deepPurpleAccent; break;
              case 'Blue': color = Colors.blueAccent; break;
              case 'Green': color = Colors.greenAccent; break;
              case 'Orange': color = Colors.orangeAccent; break;
              case 'Red': color = Colors.redAccent; break;
              case 'Teal': color = Colors.tealAccent; break;
              case 'Indigo': color = Colors.indigoAccent; break;
              default: color = Colors.pinkAccent;
            }
            
            return FilterChip(
              selected: _selectedThemeAccent == accent,
              label: Text(accent),
              avatar: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              onSelected: (selected) async {
                if (selected) {
                  setState(() => _selectedThemeAccent = accent);
                  await _updateLocalSetting('theme_accent', accent);
                }
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Theme Color Selection
        _buildSectionHeader('Theme Colors', Icons.color_lens),
        ListTile(
          leading: Icon(Icons.palette, color: _accentColor),
          title: const Text('App Color Theme'),
          subtitle: Text(themeColors.firstWhere((theme) => theme['key'] == _selectedThemeColor)['name']),
          trailing: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: themeColors.firstWhere((theme) => theme['key'] == _selectedThemeColor)['primaryColor'],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
          ),
        ),
        
        // Theme Color Grid
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose your theme color:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _accentColor,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: themeColors.length,
                itemBuilder: (context, index) {
                  final theme = themeColors[index];
                  final isSelected = _selectedThemeColor == theme['key'];
                  
                  return InkWell(
                    onTap: () => _updateThemeColor(theme['key']),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? theme['accentColor'] : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        color: isSelected ? theme['primaryColor'].withOpacity(0.1) : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: theme['primaryColor'],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  theme['name'],
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 12,
                                    color: isSelected ? theme['accentColor'] : null,
                                  ),
                                ),
                                Text(
                                  theme['description'],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: theme['accentColor'],
                              size: 16,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Theme changes will be applied when you restart the app.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        _buildSectionHeader('Chat Appearance', Icons.chat_bubble),
        
        // Background preview and quick access
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.wallpaper, color: _accentColor, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Chat Background',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _openChatBackgroundPicker,
                    child: Text(
                      'Customize',
                      style: TextStyle(color: _accentColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: _buildBackgroundPreview(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap "Customize" to access full background options including presets, effects, and custom uploads.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              if (_backgroundOpacity < 1.0 || _backgroundBlur > 0.0) ...[
                const SizedBox(height: 4),
                Text(
                  'Effects: Opacity ${(_backgroundOpacity * 100).toInt()}%, Blur ${_backgroundBlur.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: _accentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        _buildSectionHeader('Text & Display', Icons.text_fields),
        ListTile(
          leading: Icon(Icons.format_size, color: _accentColor),
          title: const Text('Font Size'),
          subtitle: Text('${_fontSize.toInt()}sp'),
        ),
        Slider(
          value: _fontSize,
          min: 12.0,
          max: 24.0,
          divisions: 12,
          activeColor: _accentColor,
          onChanged: (value) async {
            setState(() => _fontSize = value);
            await _updateLocalSetting('font_size', value);
          },
        ),

        ListTile(
          leading: Icon(Icons.opacity, color: _accentColor),
          title: const Text('Chat Bubble Opacity'),
          subtitle: Text('${(_chatBubbleOpacity * 100).toInt()}%'),
        ),
        Slider(
          value: _chatBubbleOpacity,
          min: 0.3,
          max: 1.0,
          activeColor: _accentColor,
          onChanged: (value) async {
            setState(() => _chatBubbleOpacity = value);
            await _updateLocalSetting('chat_bubble_opacity', value);
          },
        ),

        const SizedBox(height: 16),

        _buildSectionHeader('Interactions', Icons.touch_app),
        SwitchListTile(
          secondary: Icon(Icons.animation, color: _accentColor),
          title: const Text('Animations'),
          subtitle: const Text('Enable smooth animations'),
          value: _animationsEnabled,
          activeColor: _accentColor,
          onChanged: (value) async {
            setState(() => _animationsEnabled = value);
            await _updateLocalSetting('animations_enabled', value);
          },
        ),
        SwitchListTile(
          secondary: Icon(Icons.vibration, color: _accentColor),
          title: const Text('Haptic Feedback'),
          subtitle: const Text('Vibrate on button presses'),
          value: _hapticsEnabled,
          activeColor: _accentColor,
          onChanged: (value) async {
            setState(() => _hapticsEnabled = value);
            await _updateLocalSetting('haptics_enabled', value);
          },
        ),
        SwitchListTile(
          secondary: Icon(Icons.visibility, color: _accentColor),
          title: const Text('Show Online Status'),
          subtitle: const Text('Let others see when you\'re online'),
          value: _onlineStatusVisible,
          activeColor: _accentColor,
          onChanged: (value) async {
            setState(() => _onlineStatusVisible = value);
            await _updateLocalSetting('online_status_visible', value);
          },
        ),

        const SizedBox(height: 24),

        // Support Section
        _buildSectionHeader('Support', Icons.help_outline),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _accentColor.withOpacity(0.1),
                _accentColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _accentColor.withOpacity(0.3)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.support_agent,
                color: Colors.white,
                size: 24,
              ),
            ),
            title: const Text(
              'Contact Support',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: const Text(
              'Report bugs, request features, or ask questions',
              style: TextStyle(fontSize: 12),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Help',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: _showSupportDialog,
          ),
        ),

        const SizedBox(height: 16),

        // Admin Section (for development/testing)
        _buildSectionHeader('Admin', Icons.admin_panel_settings),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.withOpacity(0.1),
                Colors.purple.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.withOpacity(0.3)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.dashboard,
                color: Colors.white,
                size: 24,
              ),
            ),
            title: const Text(
              'Support Dashboard',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: const Text(
              'View and manage user support requests (Admin only)',
              style: TextStyle(fontSize: 12),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: _showAdminAccess,
          ),
        ),
        
        // Rewards Admin Option
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.amber.withOpacity(0.1),
                Colors.amber.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.star,
                color: Colors.white,
                size: 24,
              ),
            ),
            title: const Text(
              'Rewards Admin',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: const Text(
              'Sync shop items and manage rewards system (Admin only)',
              style: TextStyle(fontSize: 12),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () => AdminAccessBottomSheet.show(context),
          ),
        ),
      ],
    );
  }

  /// Build notification type card widget
  Widget _buildNotificationTypeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value ? _accentColor.withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? _accentColor.withOpacity(0.3) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value ? _accentColor.withOpacity(0.2) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: value ? _accentColor : Colors.grey.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: value ? _accentColor : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: _accentColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  /// Show time picker dialog for quiet hours
  void _showTimePickerDialog(String type, String currentTime) {
    final timeParts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _accentColor,
            ),
          ),
          child: child!,
        );
      },
    ).then((selectedTime) {
      if (selectedTime != null) {
        final timeString = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
        
        if (type == 'start') {
          _updateNotificationPreference('quiet_hours_start', timeString);
        } else {
          _updateNotificationPreference('quiet_hours_end', timeString);
        }
      }
    });
  }

  /// Send test notification
  Future<void> _sendTestNotification() async {
    try {
      // Simple test notification without complex imports
      _showSuccessSnackBar('🧪 Test notification feature coming soon!');
      
      if (_hapticsEnabled) {
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to send test notification: $e');
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Row(
        children: [
          Icon(icon, color: _accentColor, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _accentColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusMessageDialog() {
    final controller = TextEditingController(text: _statusMessage);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Status Message'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'What\'s on your mind?',
            border: OutlineInputBorder(),
          ),
          maxLength: 100,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              setState(() => _statusMessage = controller.text.trim());
              await _updateBasicSetting('status_message', _statusMessage);
              Navigator.pop(context);
              _showSuccessSnackBar('Status updated! ✨');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'Bug Report';
    
    final categories = [
      'Bug Report',
      'Feature Request',
      'General Question',
      'Account Issue',
      'Technical Problem',
      'Feedback',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.support_agent, color: _accentColor),
              const SizedBox(width: 8),
              const Text('Contact Support'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Selection
                const Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: categories.map((category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    )).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategory = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title Field
                const Text(
                  'Subject',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    hintText: 'Brief description of your issue',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 100,
                ),
                const SizedBox(height: 16),
                
                // Description Field
                const Text(
                  'Details',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    hintText: 'Please provide detailed information about your issue or request',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  maxLength: 500,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final description = descriptionController.text.trim();
                
                if (title.isEmpty || description.isEmpty) {
                  _showErrorSnackBar('Please fill in all fields');
                  return;
                }
                
                Navigator.pop(context);
                await _submitSupportRequest(selectedCategory, title, description);
              },
              style: TextButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitSupportRequest(String category, String title, String description) async {
    try {
      // Get user info for context
      final userResponse = await supabase
          .from('users')
          .select('username, email')
          .eq('id', widget.userId)
          .maybeSingle();

      final userData = userResponse ?? {};

      // Submit support request
      await supabase.from('support_requests').insert({
        'user_id': widget.userId,
        'username': userData['username'] ?? 'Unknown User',
        'email': userData['email'] ?? '',
        'category': category,
        'subject': title,
        'description': description,
        'status': 'open',
        'priority': _determinePriority(category),
        'created_at': DateTime.now().toIso8601String(),
        'device_info': await _getDeviceInfo(),
        'app_version': '1.0.0', // You can update this with your actual app version
      });

      _showSuccessSnackBar('🎫 Support request submitted! We\'ll get back to you soon.');
      
      if (_hapticsEnabled) {
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to submit support request: $e');
    }
  }

  String _determinePriority(String category) {
    switch (category) {
      case 'Bug Report':
      case 'Technical Problem':
        return 'high';
      case 'Account Issue':
        return 'medium';
      case 'Feature Request':
      case 'Feedback':
      case 'General Question':
      default:
        return 'low';
    }
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    // Basic device info - you can expand this with platform-specific packages
    return {
      'platform': Theme.of(context).platform.name,
      'theme_mode': _isDark ? 'dark' : 'light',
      'theme_color': _selectedThemeColor,
      'language': _selectedLanguage,
      'app_settings': {
        'notifications_enabled': _notificationsEnabled,
        'animations_enabled': _animationsEnabled,
        'font_size': _fontSize,
      },
    };
  }

  void _showAdminAccess() {
    final passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.purple),
            const SizedBox(width: 8),
            const Text('Admin Access'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter admin password to access the support dashboard:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Admin Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              onSubmitted: (value) => _checkAdminPassword(value, context),
            ),
            const SizedBox(height: 8),
            Text(
              'For development: Use "admin123" or tap "Skip for Testing"',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openSupportDashboard();
            },
            child: const Text('Skip for Testing'),
          ),
          TextButton(
            onPressed: () => _checkAdminPassword(passwordController.text, context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Access'),
          ),
        ],
      ),
    );
  }

  void _checkAdminPassword(String password, BuildContext dialogContext) {
    // Simple password check - in production, you'd want proper authentication
    const validPasswords = ['admin123', 'admin', 'password', 'support'];
    
    if (validPasswords.contains(password.toLowerCase())) {
      Navigator.pop(dialogContext);
      _openSupportDashboard();
    } else {
      _showErrorSnackBar('Invalid admin password');
    }
  }

  void _openSupportDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SupportDashboard(),
      ),
    ).then((_) {
      // Refresh any data if needed when returning from dashboard
      if (mounted) {
        _showSuccessSnackBar('🔙 Returned from Support Dashboard');
      }
    });
  }
}
