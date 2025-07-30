import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';


class FrontingAlterTab extends StatefulWidget {
  const FrontingAlterTab({super.key});

  @override
  _FrontingAlterTabState createState() => _FrontingAlterTabState();
}

class _FrontingAlterTabState extends State<FrontingAlterTab> with TickerProviderStateMixin {
  User? currentUser;
  String? frontingAlterName;
  String? frontingAvatarUrl;
  String? frontingAvatarDecoration;
  List<Map<String, dynamic>> frontingHistory = [];
  DateTime? frontingStartTime;
  Timer? _timeUpdateTimer;
  
  // Enhanced state management
  bool _isDarkMode = false;
  bool _isLoading = false;
  String? _frontingNotes;
  String? _frontingMood;
  String? _frontingEnergy;
  List<Map<String, dynamic>> _availableAlters = [];
  Map<String, dynamic>? _currentFrontingData;
  late AnimationController _switchAnimationController;
  late AnimationController _pulseAnimationController;
  
  // Quick actions and mood tracking
  List<String> _moodOptions = ['😊 Happy', '😴 Tired', '😔 Sad', '😠 Angry', '😰 Anxious', '🤔 Confused', '💪 Strong', '🌟 Energetic'];
  List<String> _energyLevels = ['Very Low', 'Low', 'Medium', 'High', 'Very High'];
  
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupFCM();
    _getCurrentUser();
    _fetchFrontingHistory();
    _fetchCurrentFronting();
    _fetchAvailableAlters();
    _startTimeUpdateTimer();
  }
  
  void _setupAnimations() {
    _switchAnimationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }
  
  void _startTimeUpdateTimer() {
    _timeUpdateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Update UI every second to show live time
        });
      }
    });
  }

  // Setup FCM for receiving notifications
  void _setupFCM() async {
    // Request permissions (for iOS)
    await messaging.requestPermission();

    // Set background and foreground message handlers
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_firebaseMessagingForegroundHandler);

    // Subscribe to a topic
    messaging.subscribeToTopic('fronting_changes');
  }

  // Handle messages when app is in the background
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    debugPrint('Handling a background message: ${message.messageId}');
  }

  // Handle messages when app is in the foreground
  void _firebaseMessagingForegroundHandler(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
  }

  // Send push notification to all devices
  void _sendNotification(String name) async {
    // Typically, notifications are sent from the server, but you can subscribe to topics from the client
    messaging.subscribeToTopic('fronting_changes');
    // You'll need Firebase Cloud Functions or an HTTP request to trigger notifications
  }

  // Fetch the current logged-in user
  void _getCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUser = user;
      });
    }
  }

  // Fetch fronting alter history from the database (Firebase Realtime Database example)
  void _fetchFrontingHistory() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final ref = FirebaseDatabase.instance.ref().child('fronting_history');
      final snapshot = await ref.once();
      
      if (snapshot.snapshot.value != null) {
        final history = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        setState(() {
          frontingHistory = history.entries
              .map((e) => {
                    'id': e.key,
                    'name': (e.value['name'] ?? '').toString(),
                    'avatarUrl': (e.value['avatarUrl'] ?? '').toString(),
                    'time': (e.value['time'] ?? '').toString(),
                    'endTime': (e.value['endTime'] ?? '').toString(),
                    'notes': (e.value['notes'] ?? 'No notes').toString(),
                    'mood': (e.value['mood'] ?? '').toString(),
                    'energy': (e.value['energy'] ?? '').toString(),
                    'duration': (e.value['duration'] ?? 0),
                  })
              .toList()
              ..sort((a, b) => DateTime.parse(b['time']!).compareTo(DateTime.parse(a['time']!)));
        });
      }
    } catch (e) {
      debugPrint('Error fetching fronting history: $e');
      _showErrorSnackBar('Failed to load fronting history');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Fetch current fronting alter
  void _fetchCurrentFronting() async {
    try {
      final ref = FirebaseDatabase.instance.ref().child('current_fronting');
      final snapshot = await ref.once();
      
      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        setState(() {
          _currentFrontingData = data;
          frontingAlterName = data['name'];
          frontingAvatarUrl = data['avatarUrl'];
          frontingAvatarDecoration = data['avatarDecoration'];
          _frontingMood = data['mood'];
          _frontingEnergy = data['energy'];
          _frontingNotes = data['notes'];
          if (data['time'] != null) {
            frontingStartTime = DateTime.parse(data['time']);
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching current fronting: $e');
    }
  }
  
  // Fetch available alters from database
  void _fetchAvailableAlters() async {
    try {
      final ref = FirebaseDatabase.instance.ref().child('alters');
      final snapshot = await ref.once();
      
      if (snapshot.snapshot.value != null) {
        final alters = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        setState(() {
          _availableAlters = alters.entries
              .map((e) => {
                    'id': e.key,
                    'name': (e.value['name'] ?? '').toString(),
                    'avatarUrl': (e.value['avatarUrl'] ?? '').toString(),
                    'pronouns': (e.value['pronouns'] ?? '').toString(),
                    'role': (e.value['role'] ?? '').toString(),
                    'age': (e.value['age'] ?? '').toString(),
                    'description': (e.value['description'] ?? '').toString(),
                  })
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching alters: $e');
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Set the alter as fronting with enhanced data
  void setFrontingAlter(String name, String avatarUrl, String avatarDecoration, 
      {String? mood, String? energy, String? notes}) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // End current fronting session if exists
      if (frontingAlterName != null && frontingStartTime != null) {
        await _endCurrentFrontingSession();
      }
      
      final ref = FirebaseDatabase.instance.ref().child('current_fronting');
      final timeNow = DateTime.now();
      
      setState(() {
        frontingAlterName = name;
        frontingAvatarUrl = avatarUrl;
        frontingAvatarDecoration = avatarDecoration;
        frontingStartTime = timeNow;
        _frontingMood = mood ?? _frontingMood;
        _frontingEnergy = energy ?? _frontingEnergy;
        _frontingNotes = notes ?? _frontingNotes;
      });

      // Update Realtime Database to notify all devices
      await ref.set({
        'name': name,
        'avatarUrl': avatarUrl,
        'avatarDecoration': avatarDecoration,
        'time': timeNow.toIso8601String(),
        'mood': mood ?? _frontingMood,
        'energy': energy ?? _frontingEnergy,
        'notes': notes ?? _frontingNotes,
      });

      // Log this fronting alter in the history with a unique ID
      final historyRef = FirebaseDatabase.instance.ref().child('fronting_history').push();
      await historyRef.set({
        'name': name,
        'avatarUrl': avatarUrl,
        'time': timeNow.toIso8601String(),
        'mood': mood ?? _frontingMood,
        'energy': energy ?? _frontingEnergy,
        'notes': notes ?? 'User manually set as fronting alter',
        'sessionId': historyRef.key,
      });

      // Trigger switch animation
      _switchAnimationController.forward().then((_) => _switchAnimationController.reverse());
      
      // Send notification to other devices
      _sendNotification(name);
      
      // Haptic feedback
      HapticFeedback.lightImpact();
      
      _showSuccessSnackBar('$name is now fronting! 🌟');
      
    } catch (e) {
      debugPrint('Error setting fronting alter: $e');
      _showErrorSnackBar('Failed to set fronting alter');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // End current fronting session
  Future<void> _endCurrentFrontingSession() async {
    if (frontingAlterName == null || frontingStartTime == null) return;
    
    try {
      final endTime = DateTime.now();
      final duration = endTime.difference(frontingStartTime!).inMinutes;
      
      // Update the current session in history with end time
      final historyRef = FirebaseDatabase.instance.ref().child('fronting_history');
      final snapshot = await historyRef.orderByChild('name').equalTo(frontingAlterName).limitToLast(1).once();
      
      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        final latestEntry = data.entries.first;
        
        await historyRef.child(latestEntry.key).update({
          'endTime': endTime.toIso8601String(),
          'duration': duration,
        });
      }
    } catch (e) {
      debugPrint('Error ending fronting session: $e');
    }
  }
  
  // Quick switch to an alter
  void _quickSwitchAlter(Map<String, dynamic> alter) {
    _showAlterSwitchDialog(alter);
  }
  
  // Show alter switch dialog with mood and energy selection
  void _showAlterSwitchDialog(Map<String, dynamic> alter) {
    String? selectedMood;
    String? selectedEnergy;
    String notes = '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: alter['avatarUrl']?.isNotEmpty == true 
                        ? NetworkImage(alter['avatarUrl']!) 
                        : null,
                    child: alter['avatarUrl']?.isEmpty != false 
                        ? Icon(Icons.person) 
                        : null,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alter['name'] ?? 'Unknown'),
                        if (alter['pronouns']?.isNotEmpty == true)
                          Text(
                            alter['pronouns']!,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mood Selection
                    Text('How are you feeling?', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _moodOptions.map((mood) {
                        final isSelected = selectedMood == mood;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedMood = mood;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue[100] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey,
                              ),
                            ),
                            child: Text(
                              mood,
                              style: TextStyle(
                                color: isSelected ? Colors.blue[800] : Colors.black,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                    
                    // Energy Level
                    Text('Energy Level:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedEnergy,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _energyLevels.map((energy) => DropdownMenuItem(
                        value: energy,
                        child: Text(energy),
                      )).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedEnergy = value;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Notes
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        notes = value;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setFrontingAlter(
                      alter['name'] ?? 'Unknown',
                      alter['avatarUrl'] ?? '',
                      '',
                      mood: selectedMood,
                      energy: selectedEnergy,
                      notes: notes.isNotEmpty ? notes : null,
                    );
                  },
                  child: Text('Switch'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Track and display time spent fronting with enhanced formatting
  String _getTimeSpent() {
    if (frontingStartTime == null) {
      return 'No time recorded';
    }
    final timeSpent = DateTime.now().difference(frontingStartTime!);
    final hours = timeSpent.inHours;
    final minutes = timeSpent.inMinutes % 60;
    final seconds = timeSpent.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
  
  // Get time spent with color coding
  Color _getTimeColor() {
    if (frontingStartTime == null) return Colors.grey;
    final timeSpent = DateTime.now().difference(frontingStartTime!);
    final hours = timeSpent.inHours;
    
    if (hours < 1) return Colors.green;
    if (hours < 3) return Colors.orange;
    if (hours < 6) return Colors.red[300]!;
    return Colors.red[600]!;
  }

  // Enhanced history display with stats and filtering
  Widget _buildHistory() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading fronting history...'),
          ],
        ),
      );
    }
    
    if (frontingHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No fronting history yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              'Your fronting sessions will appear here',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // Stats header
        Container(
          padding: EdgeInsets.all(16),
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.grey[800] : Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Total Sessions', frontingHistory.length.toString(), Icons.timeline),
              _buildStatCard('Most Recent', _getMostRecentAlter(), Icons.person),
              _buildStatCard('Avg Duration', _getAverageDuration(), Icons.timer),
            ],
          ),
        ),
        
        // History list
        Expanded(
          child: ListView.builder(
            itemCount: frontingHistory.length,
            itemBuilder: (context, index) {
              final alter = frontingHistory[index];
              final startTime = DateTime.parse(alter['time']!);
              final endTime = alter['endTime'] != null ? DateTime.parse(alter['endTime']!) : null;
              final duration = alter['duration'] ?? 0;
              
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: 2,
                child: ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: alter['avatarUrl']?.isNotEmpty == true 
                            ? NetworkImage(alter['avatarUrl']!) 
                            : null,
                        child: alter['avatarUrl']?.isEmpty != false 
                            ? Icon(Icons.person) 
                            : null,
                      ),
                      if (alter['mood']?.isNotEmpty == true)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              alter['mood']!.split(' ')[0], // Get emoji part
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    alter['name'] ?? 'Unknown Alter',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Started: ${_formatDateTime(startTime)}'),
                      if (endTime != null) 
                        Text('Ended: ${_formatDateTime(endTime)}'),
                      if (duration > 0)
                        Text('Duration: ${_formatDuration(duration)}'),
                      if (alter['energy']?.isNotEmpty == true)
                        Text('Energy: ${alter['energy']}', 
                             style: TextStyle(color: Colors.blue[600])),
                      if (alter['notes']?.isNotEmpty == true && alter['notes'] != 'No notes')
                        Text(
                          '📝 ${alter['notes']}',
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: ListTile(
                          leading: Icon(Icons.switch_account),
                          title: Text('Switch to ${alter['name']}'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        onTap: () {
                          Future.delayed(Duration.zero, () {
                            setFrontingAlter(
                              alter['name'] ?? 'Unknown',
                              alter['avatarUrl'] ?? '',
                              '',
                            );
                          });
                        },
                      ),
                      PopupMenuItem(
                        child: ListTile(
                          leading: Icon(Icons.info_outline),
                          title: Text('View Details'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        onTap: () {
                          Future.delayed(Duration.zero, () {
                            _showSessionDetails(alter);
                          });
                        },
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
  
  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue[600], size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  String _getMostRecentAlter() {
    if (frontingHistory.isEmpty) return 'None';
    return frontingHistory.first['name'] ?? 'Unknown';
  }
  
  String _getAverageDuration() {
    if (frontingHistory.isEmpty) return '0m';
    final totalDuration = frontingHistory.fold<int>(0, (sum, session) => sum + ((session['duration'] ?? 0) as int));
    final avgMinutes = totalDuration / frontingHistory.length;
    return '${avgMinutes.round()}m';
  }
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }
  
  void _showSessionDetails(Map<String, dynamic> session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Session Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alter: ${session['name']}', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            if (session['mood']?.isNotEmpty == true)
              Text('Mood: ${session['mood']}'),
            if (session['energy']?.isNotEmpty == true)
              Text('Energy: ${session['energy']}'),
            if (session['duration'] != null)
              Text('Duration: ${_formatDuration(session['duration'])}'),
            if (session['notes']?.isNotEmpty == true)
              Text('Notes: ${session['notes']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.group, color: Colors.blue[600]),
            SizedBox(width: 8),
            Text('System Manager'),
          ],
        ),
        backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.white,
        foregroundColor: _isDarkMode ? Colors.white : Colors.black,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
              HapticFeedback.selectionClick();
            },
            tooltip: _isDarkMode ? 'Light mode' : 'Dark mode',
          ),
          if (frontingAlterName != null)
            IconButton(
              icon: Icon(Icons.stop_circle_outlined),
              onPressed: () => _showEndSessionDialog(),
              tooltip: 'End current session',
            ),
        ],
      ),
      body: Column(
        children: [
          // Current fronting status card
          _buildCurrentFrontingCard(),
          
          // Quick actions
          if (_availableAlters.isNotEmpty) _buildQuickActions(),
          
          // History section
          Expanded(
            child: Container(
              margin: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Fronting History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  Expanded(child: _buildHistory()),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAlterDialog(),
        icon: Icon(Icons.add),
        label: Text('Add Alter'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
    );
  }
  
  // Current fronting status card
  Widget _buildCurrentFrontingCard() {
    return Container(
      margin: EdgeInsets.all(12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: frontingAlterName != null 
              ? [Colors.blue[400]!, Colors.blue[600]!]
              : [Colors.grey[400]!, Colors.grey[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with pulse animation
              AnimatedBuilder(
                animation: _pulseAnimationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: frontingAlterName != null 
                        ? 1.0 + (0.1 * _pulseAnimationController.value)
                        : 1.0,
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 30,
                        backgroundImage: frontingAvatarUrl?.isNotEmpty == true
                            ? NetworkImage(frontingAvatarUrl!)
                            : null,
                        child: frontingAvatarUrl?.isEmpty != false
                            ? Icon(Icons.person, size: 32, color: Colors.grey[600])
                            : null,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(width: 16),
              
              // Fronting info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      frontingAlterName ?? 'No one fronting',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (frontingAlterName != null) ...[
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.timer, color: Colors.white70, size: 16),
                          SizedBox(width: 4),
                          Text(
                            _getTimeSpent(),
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (_frontingMood?.isNotEmpty == true) ...[
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Text(_frontingMood!, style: TextStyle(color: Colors.white70)),
                            if (_frontingEnergy?.isNotEmpty == true) ...[
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _frontingEnergy!,
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ] else ...[
                      Text(
                        'Tap an alter below to start fronting',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Status indicator
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: frontingAlterName != null ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (frontingAlterName != null ? Colors.green : Colors.red).withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Notes section
          if (_frontingNotes?.isNotEmpty == true) ...[
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '📝 ${_frontingNotes!}',
                style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  // Quick actions for switching alters
  Widget _buildQuickActions() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Quick Switch',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          Container(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _availableAlters.length,
              itemBuilder: (context, index) {
                final alter = _availableAlters[index];
                final isCurrentlyFronting = alter['name'] == frontingAlterName;
                
                return GestureDetector(
                  onTap: isCurrentlyFronting ? null : () => _quickSwitchAlter(alter),
                  child: Container(
                    width: 80,
                    margin: EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: isCurrentlyFronting ? Colors.blue[100] : Colors.grey[200],
                              backgroundImage: alter['avatarUrl']?.isNotEmpty == true
                                  ? NetworkImage(alter['avatarUrl']!)
                                  : null,
                              child: alter['avatarUrl']?.isEmpty != false
                                  ? Icon(Icons.person, color: isCurrentlyFronting ? Colors.blue : Colors.grey)
                                  : null,
                            ),
                            if (isCurrentlyFronting)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          alter['name'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isCurrentlyFronting ? FontWeight.bold : FontWeight.normal,
                            color: isCurrentlyFronting 
                                ? Colors.blue[600] 
                                : (_isDarkMode ? Colors.white : Colors.black),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
  
  // Show dialog to end current session
  void _showEndSessionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('End Fronting Session'),
        content: Text('Are you sure you want to end ${frontingAlterName}\'s fronting session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _endCurrentFrontingSession();
              setState(() {
                frontingAlterName = null;
                frontingAvatarUrl = null;
                frontingStartTime = null;
                _frontingMood = null;
                _frontingEnergy = null;
                _frontingNotes = null;
              });
              _showSuccessSnackBar('Fronting session ended');
            },
            child: Text('End Session'),
          ),
        ],
      ),
    );
  }
  
  // Show dialog to add new alter
  void _showAddAlterDialog() {
    // This would typically navigate to an alter management screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alter management feature coming soon!'),
        backgroundColor: Colors.blue[600],
      ),
    );
  }
  
  @override
  void dispose() {
    _timeUpdateTimer?.cancel();
    _switchAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }
}
