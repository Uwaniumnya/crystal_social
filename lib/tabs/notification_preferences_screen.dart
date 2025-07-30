import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/notification_preferences_service.dart';
import '../services/push_notification_service.dart';

/// Dedicated notification preferences screen
class NotificationPreferencesScreen extends StatefulWidget {
  final String userId;
  
  const NotificationPreferencesScreen({
    super.key, 
    required this.userId,
  });

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  NotificationPreferences? _preferences;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _loading = true);
    
    try {
      final prefs = await NotificationPreferencesService.instance.getPreferences(widget.userId);
      if (mounted) {
        setState(() {
          _preferences = prefs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showSnackBar('Error loading preferences: $e', isError: true);
      }
    }
  }

  Future<void> _updatePreference<T>(T value, NotificationPreferences Function(NotificationPreferences, T) updater) async {
    if (_preferences == null || _saving) return;
    
    setState(() => _saving = true);
    
    try {
      final updatedPrefs = updater(_preferences!, value);
      
      final success = await NotificationPreferencesService.instance.updatePreferences(widget.userId, updatedPrefs);
      
      if (success && mounted) {
        setState(() {
          _preferences = updatedPrefs;
          _saving = false;
        });
        
        HapticFeedback.lightImpact();
        _showSnackBar('Preferences updated! 🔔');
      } else {
        throw Exception('Failed to save preferences');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showSnackBar('Failed to update preferences: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade400 : Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    try {
      await PushNotificationService.instance.sendTestNotification(widget.userId);
      _showSnackBar('🧪 Test notification sent! Check your device.');
    } catch (e) {
      _showSnackBar('Failed to send test notification: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _preferences == null
              ? const Center(child: Text('Failed to load preferences'))
              : _buildPreferencesBody(),
    );
  }

  Widget _buildPreferencesBody() {
    final prefs = _preferences!;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Notification Types Section
        _buildSection(
          title: 'Notification Types',
          icon: Icons.category,
          children: [
            _buildPreferenceCard(
              icon: Icons.message,
              title: 'Messages',
              subtitle: 'Chat messages and direct messages',
              value: prefs.messages,
              onChanged: (value) => _updatePreference(
                value,
                (prefs, val) => prefs.copyWith(messages: val),
              ),
            ),
            _buildPreferenceCard(
              icon: Icons.emoji_events,
              title: 'Achievements',
              subtitle: 'Level ups, rewards, and accomplishments',
              value: prefs.achievements,
              onChanged: (value) => _updatePreference(
                value,
                (prefs, val) => prefs.copyWith(achievements: val),
              ),
            ),
            _buildPreferenceCard(
              icon: Icons.person_add,
              title: 'Friend Requests',
              subtitle: 'New friend requests and acceptances',
              value: prefs.friendRequests,
              onChanged: (value) => _updatePreference(
                value,
                (prefs, val) => prefs.copyWith(friendRequests: val),
              ),
            ),
            _buildPreferenceCard(
              icon: Icons.pets,
              title: 'Pet Interactions',
              subtitle: 'Pet care reminders and interactions',
              value: prefs.petInteractions,
              onChanged: (value) => _updatePreference(
                value,
                (prefs, val) => prefs.copyWith(petInteractions: val),
              ),
            ),
            _buildPreferenceCard(
              icon: Icons.support_agent,
              title: 'Support',
              subtitle: 'Support responses and help',
              value: prefs.support,
              onChanged: (value) => _updatePreference(
                value,
                (prefs, val) => prefs.copyWith(support: val),
              ),
            ),
            _buildPreferenceCard(
              icon: Icons.info,
              title: 'System Notifications',
              subtitle: 'App updates and announcements',
              value: prefs.system,
              onChanged: (value) => _updatePreference(
                value,
                (prefs, val) => prefs.copyWith(system: val),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Sound & Vibration Section
        _buildSection(
          title: 'Sound & Vibration',
          icon: Icons.volume_up,
          children: [
            _buildPreferenceCard(
              icon: Icons.vibration,
              title: 'Vibration',
              subtitle: 'Vibrate for notifications',
              value: prefs.vibrate,
              onChanged: (value) => _updatePreference(
                value,
                (prefs, val) => prefs.copyWith(vibrate: val),
              ),
            ),
            _buildPreferenceCard(
              icon: Icons.preview,
              title: 'Show Message Preview',
              subtitle: 'Display message content in notifications',
              value: prefs.showPreview,
              onChanged: (value) => _updatePreference(
                value,
                (prefs, val) => prefs.copyWith(showPreview: val),
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.music_note, color: Colors.purple.shade600),
                title: const Text('Notification Sound'),
                subtitle: Text('Current: ${prefs.sound}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showSoundPicker(prefs.sound),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Quiet Hours Section
        _buildSection(
          title: 'Quiet Hours',
          icon: Icons.bedtime,
          children: [
            _buildPreferenceCard(
              icon: Icons.bedtime,
              title: 'Enable Quiet Hours',
              subtitle: 'Silence notifications during specified hours',
              value: prefs.quietHoursEnabled,
              onChanged: (value) => _updatePreference(
                value,
                (prefs, val) => prefs.copyWith(quietHoursEnabled: val),
              ),
            ),
            if (prefs.quietHoursEnabled) ...[
              Card(
                child: ListTile(
                  leading: Icon(Icons.schedule, color: Colors.purple.shade600),
                  title: const Text('Start Time'),
                  subtitle: Text('Quiet hours start at ${prefs.quietHoursStart}'),
                  trailing: const Icon(Icons.edit, size: 16),
                  onTap: () => _showTimePicker('start', prefs.quietHoursStart),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(Icons.schedule_outlined, color: Colors.purple.shade600),
                  title: const Text('End Time'),
                  subtitle: Text('Quiet hours end at ${prefs.quietHoursEnd}'),
                  trailing: const Icon(Icons.edit, size: 16),
                  onTap: () => _showTimePicker('end', prefs.quietHoursEnd),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade200),
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
        
        const SizedBox(height: 24),
        
        // Test Section
        _buildSection(
          title: 'Test Notifications',
          icon: Icons.bug_report,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade100, Colors.purple.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test Your Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Send a test notification to make sure everything is working correctly.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.send),
                      label: const Text('Send Test Notification'),
                      onPressed: _sendTestNotification,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(icon, color: Colors.purple.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildPreferenceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        secondary: Icon(icon, color: value ? Colors.purple.shade600 : Colors.grey),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        value: value,
        activeColor: Colors.purple.shade600,
        onChanged: _saving ? null : onChanged,
      ),
    );
  }

  void _showSoundPicker(String currentSound) {
    final sounds = [
      'default',
      'bubblepop.mp3',
      'sparklebell.mp3',
      'mystic_chime.mp3',
      'crystal_melody.mp3',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Notification Sound'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: sounds.map((sound) => RadioListTile<String>(
            title: Text(sound.replaceAll('.mp3', '').replaceAll('_', ' ')),
            value: sound,
            groupValue: currentSound,
            onChanged: (value) {
              Navigator.pop(context);
              if (value != null) {
                _updatePreference(
                  value,
                  (prefs, val) => prefs.copyWith(sound: val),
                );
              }
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showTimePicker(String type, String currentTime) {
    final timeParts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    showTimePicker(
      context: context,
      initialTime: initialTime,
    ).then((selectedTime) {
      if (selectedTime != null) {
        final timeString = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
        
        if (type == 'start') {
          _updatePreference(
            timeString,
            (prefs, val) => prefs.copyWith(quietHoursStart: val),
          );
        } else {
          _updatePreference(
            timeString,
            (prefs, val) => prefs.copyWith(quietHoursEnd: val),
          );
        }
      }
    });
  }
}
