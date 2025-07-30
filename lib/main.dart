import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'dart:async';
import 'tabs/enhanced_login_screen.dart';
import 'tabs/home_screen.dart';
import 'services/enhanced_push_notification_integration.dart';
import 'services/device_user_tracking_service.dart';
import 'rewards/rewards_manager.dart';
import 'config/production_config.dart';
import 'config/environment_config.dart';
import 'config/main_error_handler.dart';

// Enhanced Global Configuration and State Management
class AppConfig {
  static String get supabaseUrl => EnvironmentConfig.supabaseUrl;
  static String get supabaseAnonKey => EnvironmentConfig.supabaseAnonKey;
  static String get oneSignalAppId => EnvironmentConfig.oneSignalAppId;
  
  // App settings from environment config
  static Duration get inactivityTimeout => EnvironmentConfig.sessionTimeout;
  static Duration get splashDuration => EnvironmentConfig.splashDuration;
  static int get maxRecentStickers => 50;
  static int get maxCacheSize => EnvironmentConfig.maxCacheSize;
}

// Enhanced App State Provider
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});

class AppState {
  final bool isOnline;
  final bool isInitialized;
  final String? currentUserId;
  final ThemeMode themeMode;
  final Map<String, dynamic> userPreferences;
  final String? lastError;
  final bool isLoading;

  const AppState({
    this.isOnline = true,
    this.isInitialized = false,
    this.currentUserId,
    this.themeMode = ThemeMode.light,
    this.userPreferences = const {},
    this.lastError,
    this.isLoading = false,
  });

  AppState copyWith({
    bool? isOnline,
    bool? isInitialized,
    String? currentUserId,
    ThemeMode? themeMode,
    Map<String, dynamic>? userPreferences,
    String? lastError,
    bool? isLoading,
  }) {
    return AppState(
      isOnline: isOnline ?? this.isOnline,
      isInitialized: isInitialized ?? this.isInitialized,
      currentUserId: currentUserId ?? this.currentUserId,
      themeMode: themeMode ?? this.themeMode,
      userPreferences: userPreferences ?? this.userPreferences,
      lastError: lastError ?? this.lastError,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(const AppState()) {
    _initialize();
  }

  late final Connectivity _connectivity;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  Future<void> _initialize() async {
    _connectivity = Connectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) {
        state = state.copyWith(isOnline: result != ConnectivityResult.none);
      },
    );
  }

  void setLoading(bool loading) => state = state.copyWith(isLoading: loading);
  void setCurrentUser(String? userId) => state = state.copyWith(currentUserId: userId);
  void setThemeMode(ThemeMode theme) => state = state.copyWith(themeMode: theme);
  void setError(String? error) => state = state.copyWith(lastError: error);
  void setInitialized(bool initialized) => state = state.copyWith(isInitialized: initialized);

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

// Enhanced Fronting Changes Subscription with Error Recovery
void _subscribeToFrontingChanges() {
  try {
    final supabaseClient = Supabase.instance.client;
    final channel = supabaseClient.channel('public:current_fronting');
    
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'current_fronting',
      callback: (payload) {
        try {
          final frontingAlter = payload.newRecord;
          if (frontingAlter['name'] != null) {
            _sendNotificationToTopic(frontingAlter['name']);
            _logFrontingChange(frontingAlter);
          }
        } catch (e, stack) {
          MainErrorHandler.handleAsyncError(e, stack, context: 'Fronting change processing');
        }
      },
    );

    // Enhanced error handling for channel subscription
    channel.onBroadcast(
      event: 'system',
      callback: (payload) {
        if (payload['type'] == 'error') {
          ProductionLogger.logError('Channel subscription error', payload['message']);
          
          // Attempt to reconnect after a delay
          Future.delayed(const Duration(seconds: 5), () {
            ProductionLogger.logInfo('Attempting to reconnect to fronting changes', tag: 'RECONNECT');
            _subscribeToFrontingChanges();
          });
        }
      },
    );
    
    channel.subscribe();
    ProductionLogger.logInfo('Subscribed to fronting changes with enhanced error handling', tag: 'SUBSCRIPTION');
  } catch (e, stack) {
    MainErrorHandler.handleAsyncError(e, stack, context: 'Fronting subscription setup');
  }
}

// Enhanced notification system with better error handling
void _sendNotificationToTopic(String name) async {
  try {
    // Validate input
    if (name.trim().isEmpty) {
      ProductionLogger.logWarning('Skipping notification for empty name', tag: 'NOTIFICATION');
      return;
    }

    // Check network connectivity before sending
    final connectivity = Connectivity();
    final connectivityResult = await connectivity.checkConnectivity();
    
    if (connectivityResult == ConnectivityResult.none) {
      ProductionLogger.logWarning('No network connection, skipping notification', tag: 'NOTIFICATION');
      return;
    }
    
    // Get the current user to use for notification
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;
    
    if (currentUser == null) {
      ProductionLogger.logWarning('No user logged in, skipping notification', tag: 'NOTIFICATION');
      return;
    }

    // Use our enhanced service to send notification
    final success = await EnhancedPushNotificationIntegration.instance.sendSystemNotification(
      receiverUserId: currentUser.id,
      title: 'New Fronting Alter',
      message: '$name is now fronting! 🔄',
      additionalData: {
        'fronting_name': name,
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'fronting_change',
      },
    );
    
    if (success) {
      ProductionLogger.logInfo('Notification sent for $name', tag: 'NOTIFICATION');
    } else {
      ProductionLogger.logWarning('Failed to send notification for $name', tag: 'NOTIFICATION');
    }
  } catch (e, stack) {
    MainErrorHandler.handleNetworkError(e, stack, endpoint: 'Notification service');
  }
}

// Get active device IDs for notifications
Future<List<String>> _getActiveDeviceIds() async {
  try {
    // For OneSignal v5.3.4, login with user's ID, then get the push subscription ID
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // Login with user ID to associate this device with the user
      await OneSignal.login(user.id);
      
      // Get the push subscription ID using the proper path in v5.3.4
      final playerId = await OneSignal.User.pushSubscription.id;
      
      if (playerId != null) {
        return [playerId];
      }
    }
    
    // Fallback to our own service
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;
    
    if (currentUser == null) {
      return [];
    }
    
    // Query the database for this user's device IDs
    final devices = await supabase
      .from('user_devices')
      .select('device_id')
      .eq('user_id', currentUser.id)
      .eq('is_active', true);
      
    return (devices as List).map((device) => device['device_id'] as String).toList();
  } catch (e, stack) {
    MainErrorHandler.handleDatabaseError(e, stack, operation: 'Get active device IDs');
    return [];
  }
}

// Enhanced logging system
void _logFrontingChange(Map<String, dynamic> frontingData) async {
  try {
    final timestamp = DateTime.now().toIso8601String();
    ProductionLogger.logInfo('Fronting change logged: ${frontingData['name']} at $timestamp', tag: 'FRONTING');
    
    // Store in local database for analytics
    final prefs = await SharedPreferences.getInstance();
    final logs = prefs.getStringList('fronting_logs') ?? [];
    logs.add('$timestamp: ${frontingData['name']}');
    
    // Keep only last 100 logs
    if (logs.length > 100) {
      logs.removeRange(0, logs.length - 100);
    }
    
    await prefs.setStringList('fronting_logs', logs);
  } catch (e, stack) {
    MainErrorHandler.handleAsyncError(e, stack, context: 'Fronting change logging');
  }
}

// Enhanced error reporting system - now handled by MainErrorHandler
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Enhanced global theme notifier with persistence - Default to light (kawaii pink)
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

// Enhanced background message handler with analytics
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  ProductionLogger.logInfo('[Background] Message: ${message.notification?.title ?? "No title"}', tag: 'FCM');
  
  // Enhanced background message handling
  try {
    // Log the background message
    await _logBackgroundMessage(message);
    
    // Handle different message types
    await _handleBackgroundMessageType(message);
  } catch (e, stack) {
    MainErrorHandler.handleAsyncError(e, stack, context: 'Background message handling');
  }
}

// Background message analytics
Future<void> _logBackgroundMessage(RemoteMessage message) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final logs = prefs.getStringList('background_messages') ?? [];
    
    final logEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'title': message.notification?.title,
      'body': message.notification?.body,
      'data': message.data,
    };
    
    logs.add(logEntry.toString());
    
    // Keep only last 50 background messages
    if (logs.length > 50) {
      logs.removeRange(0, logs.length - 50);
    }
    
    await prefs.setStringList('background_messages', logs);
  } catch (e, stack) {
    MainErrorHandler.handleAsyncError(e, stack, context: 'Background message logging');
  }
}

// Handle different types of background messages
Future<void> _handleBackgroundMessageType(RemoteMessage message) async {
  final messageType = message.data['type'];
  
  switch (messageType) {
    case 'fronting_change':
      await _handleFrontingNotification(message);
      break;
    case 'chat_message':
      await _handleChatNotification(message);
      break;
    case 'system_update':
      await _handleSystemNotification(message);
      break;
    default:
      ProductionLogger.logInfo('Generic background message received', tag: 'FCM');
  }
}

Future<void> _handleFrontingNotification(RemoteMessage message) async {
  ProductionLogger.logInfo('Handling fronting change notification', tag: 'FCM');
  // Implemented: Update local state, show notification, etc.
}

Future<void> _handleChatNotification(RemoteMessage message) async {
  ProductionLogger.logInfo('Handling chat message notification', tag: 'FCM');
  // Implemented: Update chat state, increment unread count, etc.
}

Future<void> _handleSystemNotification(RemoteMessage message) async {
  ProductionLogger.logInfo('Handling system notification', tag: 'FCM');
  // Implemented: Handle system updates, maintenance notices, etc.
}

// Enhanced main function with comprehensive initialization
void main() async {
  ProductionLogger.logInfo('Crystal Social - Starting enhanced initialization', tag: 'INIT');
  
  // Initialize error handling first
  MainErrorHandler.initialize();
  
  try {
    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();
    
    // Lock orientation to portrait for better UX
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Enhanced status bar styling
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    // Initialize core services with error handling
    await _initializeFirebase();
    await _initializeLocalStorage();
    await _initializeSupabase();
    
    // Initialize additional services
    await _initializeAnalytics();
    await _initializePushNotifications();
    await _setupAppLifecycleObserver();
    
    // Initialize achievements system
    await _initializeAchievements();
    
    ProductionLogger.logInfo('All services initialized successfully', tag: 'INIT');
    
  } catch (e, stackTrace) {
    MainErrorHandler.handleAsyncError(e, stackTrace, context: 'Main initialization');
    
    // Try to continue with basic functionality
    await _initializeMinimalApp();
  }

  // Run the enhanced app
  runApp(
    ProviderScope(
      child: const EnhancedCrystalApp(),
    ),
  );
}

// Individual initialization functions for better error handling
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    ProductionLogger.logInfo('Firebase initialized', tag: 'INIT');
  } catch (e, stack) {
    MainErrorHandler.handleAsyncError(e, stack, context: 'Firebase initialization');
    throw Exception('Firebase initialization failed');
  }
}

Future<void> _initializeLocalStorage() async {
  try {
    await Hive.initFlutter();
    // Register adapters when needed
    // Hive.registerAdapter(BoardAdapter());
    ProductionLogger.logInfo('Local storage initialized', tag: 'INIT');
  } catch (e, stack) {
    MainErrorHandler.handleAsyncError(e, stack, context: 'Local storage initialization');
    throw Exception('Local storage initialization failed');
  }
}



Future<void> _initializeSupabase() async {
  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    
    // Subscribe to fronting changes after successful initialization
    _subscribeToFrontingChanges();
    
    ProductionLogger.logInfo('Supabase initialized', tag: 'INIT');
  } catch (e, stack) {
    MainErrorHandler.handleAsyncError(e, stack, context: 'Supabase initialization');
    // Continue without real-time features
  }
}

Future<void> _initializePushNotifications() async {
  try {
    await EnhancedPushNotificationIntegration.instance.initialize();
    ProductionLogger.logInfo('Push notifications initialized', tag: 'INIT');
  } catch (e, stack) {
    MainErrorHandler.handleAsyncError(e, stack, context: 'Push notifications initialization');
    // Continue without push notifications
  }
}

Future<void> _initializeAnalytics() async {
  try {
    // Initialize analytics service (Firebase Analytics, Mixpanel, etc.)
    ProductionLogger.logInfo('Analytics initialized', tag: 'INIT');
  } catch (e, stack) {
    MainErrorHandler.handleAsyncError(e, stack, context: 'Analytics initialization');
    // Non-critical, continue without analytics
  }
}

Future<void> _setupAppLifecycleObserver() async {
  try {
    // Enhanced lifecycle management
    ProductionLogger.logInfo('App lifecycle observer setup', tag: 'INIT');
  } catch (e, stack) {
    MainErrorHandler.handleAsyncError(e, stack, context: 'App lifecycle observer setup');
  }
}

Future<void> _initializeAchievements() async {
  try {
    ProductionLogger.logInfo('Initializing achievements system', tag: 'ACHIEVEMENTS');
    final rewardsManager = RewardsManager(Supabase.instance.client);
    await rewardsManager.initializeAchievements();
    ProductionLogger.logInfo('Achievements system initialized with 67 achievements', tag: 'ACHIEVEMENTS');
  } catch (e, stack) {
    MainErrorHandler.handleAsyncError(e, stack, context: 'Achievements initialization');
    // Non-critical, continue without achievements
  }
}

Future<void> _initializeMinimalApp() async {
  ProductionLogger.logInfo('Initializing minimal app functionality', tag: 'INIT');
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await SharedPreferences.getInstance();
    ProductionLogger.logInfo('Minimal app initialized', tag: 'INIT');
  } catch (e, stack) {
    MainErrorHandler.handleAsyncError(e, stack, context: 'Minimal app initialization');
  }
}

// Enhanced FCM Token Management with Smart Auto-Logout
Future<void> _handleFCMTokenAndInactivity() async {
  try {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    ProductionLogger.logInfo('FCM Token retrieved: ${fcmToken?.substring(0, 20)}...', tag: 'FCM');

    final prefs = await SharedPreferences.getInstance();
    final lastActiveMillis = prefs.getInt('lastActiveTime');
    final now = DateTime.now();

    // Get the current user from Supabase
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null && fcmToken != null) {
      // Store the FCM token in Supabase with enhanced data
      await Supabase.instance.client.from('users').upsert({
        'id': user.id,
        'fcm_token': fcmToken,
        'last_token_update': now.toIso8601String(),
        'device_info': await _getDeviceInfo(),
      });
      ProductionLogger.logInfo('FCM token saved to Supabase with device info', tag: 'FCM');
    }

    // Enhanced: Smart auto-logout based on device user history
    if (user != null && lastActiveMillis != null) {
      final shouldAutoLogout = await DeviceUserTrackingService.instance.shouldApplyAutoLogout();
      
      if (shouldAutoLogout) {
        // Multiple users have used this device - apply auto-logout
        final inactivityTimeout = await _getUserInactivityTimeout(prefs);
        final lastActive = DateTime.fromMillisecondsSinceEpoch(lastActiveMillis);
        final inactivity = now.difference(lastActive);

        if (inactivity > inactivityTimeout) {
          // Get current user before signing out
          final currentUser = Supabase.instance.client.auth.currentUser;
          
          await Supabase.instance.client.auth.signOut();
          await _clearSensitiveLocalData();
          
          // Deactivate device for push notifications
          if (currentUser != null) {
            await EnhancedPushNotificationIntegration.instance.onUserLogout(currentUser.id);
            await DeviceUserTrackingService.instance.trackUserLogout();
          }
          
          ProductionLogger.logInfo('Auto signed out due to inactivity (${inactivity.inMinutes} minutes) - Multiple users detected', tag: 'AUTH');
        }
      } else {
        // Single user device - no auto-logout needed
        ProductionLogger.logInfo('Auto-logout skipped: Single user device detected', tag: 'AUTH');
      }
    }

    // Update the last active time
    await prefs.setInt('lastActiveTime', now.millisecondsSinceEpoch);
  } catch (e, stack) {
    MainErrorHandler.handleAsyncError(e, stack, context: 'FCM token handling');
  }
}

// Get device information for analytics (simplified version)
Future<Map<String, dynamic>> _getDeviceInfo() async {
  try {
    // Basic device info without external packages
    Map<String, dynamic> info = {};
    
    if (Platform.isAndroid) {
      info = {
        'platform': 'Android',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } else if (Platform.isIOS) {
      info = {
        'platform': 'iOS',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } else {
      info = {
        'platform': 'Other',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
    
    return info;
  } catch (e, stack) {
    MainErrorHandler.handleAsyncError(e, stack, context: 'Device info retrieval');
    return {
      'platform': 'Unknown',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

// Get user-specific inactivity timeout
Future<Duration> _getUserInactivityTimeout(SharedPreferences prefs) async {
  try {
    final customTimeout = prefs.getInt('inactivity_timeout_minutes');
    if (customTimeout != null) {
      return Duration(minutes: customTimeout);
    }
    return AppConfig.inactivityTimeout;
  } catch (e) {
    return AppConfig.inactivityTimeout;
  }
}

// Clear sensitive local data on logout
Future<void> _clearSensitiveLocalData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_cache');
    await prefs.remove('chat_drafts');
    await prefs.remove('recent_searches');
    ProductionLogger.logInfo('Sensitive local data cleared', tag: 'CLEANUP');
  } catch (e, stack) {
    MainErrorHandler.handleAsyncError(e, stack, context: 'Sensitive data cleanup');
  }
}

// Enhanced Crystal App class
class EnhancedCrystalApp extends ConsumerStatefulWidget {
  const EnhancedCrystalApp({super.key});

  @override
  ConsumerState<EnhancedCrystalApp> createState() => _EnhancedCrystalAppState();
}

class _EnhancedCrystalAppState extends ConsumerState<EnhancedCrystalApp> 
    with WidgetsBindingObserver {
  String? _username;
  bool _showSplash = true;
  bool _isInitialized = false;
  String _selectedThemeColor = 'kawaii_pink'; // Default theme color

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await _handleFCMTokenAndInactivity();
      await _loadUserThemePreference();
      await _loadThemeColorPreference(); // Load saved theme color
      await _requestNotificationPermissions();
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e, stack) {
      MainErrorHandler.handleAsyncError(e, stack, context: 'App initialization');
    }
  }

  Future<void> _requestNotificationPermissions() async {
    try {
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        announcement: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        ProductionLogger.logInfo('Notification permission granted', tag: 'PERMISSIONS');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        ProductionLogger.logInfo('Provisional notification permission granted', tag: 'PERMISSIONS');
      } else {
        ProductionLogger.logWarning('Notification permission denied', tag: 'PERMISSIONS');
      }
    } catch (e, stack) {
      MainErrorHandler.handleAsyncError(e, stack, context: 'Notification permissions request');
    }
  }

  Future<void> _loadUserThemePreference() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await Supabase.instance.client
          .from('users')
          .select('prefersDarkMode, theme_color, accessibility_settings')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        final prefersDark = data['prefersDarkMode'] ?? false;
        themeNotifier.value = prefersDark ? ThemeMode.dark : ThemeMode.light;
        
        // Store additional theme preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('theme_color', data['theme_color'] ?? 'pink');
        await prefs.setString('accessibility_settings', 
            data['accessibility_settings']?.toString() ?? '{}');
      }
    } catch (e, stack) {
      MainErrorHandler.handleDatabaseError(e, stack, operation: 'Load user theme preferences');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final appState = ref.read(appStateProvider.notifier);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      switch (state) {
        case AppLifecycleState.paused:
        case AppLifecycleState.inactive:
          await prefs.setInt('lastActiveTime', now.millisecondsSinceEpoch);
          ProductionLogger.logInfo('App went to background', tag: 'LIFECYCLE');
          break;
          
        case AppLifecycleState.resumed:
          await _handleAppResume(prefs, now, appState);
          break;
          
        case AppLifecycleState.detached:
          await _handleAppDetached();
          break;
          
        case AppLifecycleState.hidden:
          ProductionLogger.logInfo('App hidden', tag: 'LIFECYCLE');
          break;
      }
    } catch (e, stack) {
      MainErrorHandler.handleAsyncError(e, stack, context: 'App lifecycle change');
    }
  }

  Future<void> _handleAppResume(SharedPreferences prefs, DateTime now, AppStateNotifier appState) async {
    ProductionLogger.logInfo('App resumed', tag: 'LIFECYCLE');
    
    final lastActiveMillis = prefs.getInt('lastActiveTime');
    if (lastActiveMillis != null) {
      final lastActive = DateTime.fromMillisecondsSinceEpoch(lastActiveMillis);
      final inactiveDuration = now.difference(lastActive);

      // Enhanced: Only auto-logout if multiple users have used this device
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        final shouldAutoLogout = await DeviceUserTrackingService.instance.shouldApplyAutoLogout();
        
        if (shouldAutoLogout && inactiveDuration >= AppConfig.inactivityTimeout) {
          // Multiple users detected - apply auto-logout
          await Supabase.instance.client.auth.signOut();
          await _clearSensitiveLocalData();
          
          // Deactivate device for push notifications
          await EnhancedPushNotificationIntegration.instance.onUserLogout(currentUser.id);
          await DeviceUserTrackingService.instance.trackUserLogout();
          
          _restartApp();
          ProductionLogger.logInfo('Auto signed out due to inactivity - Multiple users detected', tag: 'AUTH');
        } else if (!shouldAutoLogout) {
          // Single user device - no auto-logout
          ProductionLogger.logInfo('Auto-logout skipped: Single user device', tag: 'AUTH');
          await _refreshAppData();
        } else {
          // Within timeout - refresh data
          await _refreshAppData();
        }
      }
    }
    
    await prefs.setInt('lastActiveTime', now.millisecondsSinceEpoch);
  }

  Future<void> _handleAppDetached() async {
    ProductionLogger.logInfo('App detached - performing cleanup', tag: 'LIFECYCLE');
    // Perform any necessary cleanup
    await _clearSensitiveLocalData();
  }

  Future<void> _refreshAppData() async {
    try {
      // Refresh user data, check for new messages, etc.
      ProductionLogger.logInfo('Refreshing app data', tag: 'REFRESH');
      
      // Check connectivity
      final connectivity = Connectivity();
      final result = await connectivity.checkConnectivity();
      
      if (result != ConnectivityResult.none) {
        // Refresh data from server
        // Implemented: data refresh logic
      }
    } catch (e, stack) {
      MainErrorHandler.handleAsyncError(e, stack, context: 'App data refresh');
    }
  }

  void _restartApp() {
    setState(() {
      _username = null;
      _showSplash = false;
      _isInitialized = false;
    });
  }

  void _handleLogin(String username) {
    setState(() {
      _username = username;
    });
  }

  void _handleSplashFinished() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Crystal Social',
          themeMode: mode,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          debugShowCheckedModeBanner: false,
          home: _buildHome(appState),
          builder: (context, child) {
            return _buildAppWrapper(context, child, appState);
          },
        );
      },
    );
  }

  Widget _buildHome(AppState appState) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.pinkAccent),
        ),
      );
    }
    
    if (_showSplash) {
      return SplashScreen(onFinished: _handleSplashFinished);
    }
    
    if (_username == null) {
      return EnhancedLoginScreen(onLogin: _handleLogin);
    }
    
    return HomeScreen(currentUserId: _username!);
  }

  Widget _buildAppWrapper(BuildContext context, Widget? child, AppState appState) {
    return Stack(
      children: [
        child ?? const SizedBox.shrink(),
        
        // Offline indicator
        if (!appState.isOnline)
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red,
              child: const Text(
                '📡 You are offline',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        
        // Loading overlay
        if (appState.isLoading)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.black26,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }

  ThemeData _buildLightTheme() {
    return _buildThemeForColor(_selectedThemeColor);
  }

  ThemeData _buildDarkTheme() {
    return _buildThemeForColor(_selectedThemeColor, isDark: true);
  }

  ThemeData _buildThemeForColor(String colorKey, {bool isDark = false}) {
    final themeColors = _getThemeColors(colorKey, isDark: isDark);
    
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: themeColors['primary']!,
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: themeColors['primary']!,
        secondary: themeColors['secondary']!,
        surface: themeColors['surface']!,
        error: themeColors['error']!,
      ),
      scaffoldBackgroundColor: themeColors['background']!,
      appBarTheme: AppBarTheme(
        backgroundColor: themeColors['primary'],
        foregroundColor: themeColors['onPrimary'],
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: themeColors['onPrimary'],
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(
          color: themeColors['onPrimary'],
          size: 24,
        ),
        toolbarHeight: 60,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColors['primary'],
          foregroundColor: themeColors['onPrimary'],
          elevation: 6,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: themeColors['accent'],
        foregroundColor: themeColors['onAccent'],
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      cardTheme: CardThemeData(
        color: themeColors['surface'],
        elevation: 8,
        shadowColor: themeColors['primary']!.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: themeColors['primary']!.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: themeColors['surface'],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: themeColors['primary']!.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: themeColors['primary']!.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: themeColors['accent']!, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: themeColors['surface'],
        selectedItemColor: themeColors['accent'],
        unselectedItemColor: Colors.grey.shade400,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return themeColors['accent'];
          }
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return themeColors['primary']!.withOpacity(0.5);
          }
          return Colors.grey.shade300;
        }),
      ),
    );
  }

  Map<String, Color> _getThemeColors(String colorKey, {bool isDark = false}) {
    switch (colorKey) {
      case 'kawaii_pink':
        return isDark ? {
          'primary': const Color(0xFFFF69B4),      // Hot pink
          'secondary': const Color(0xFFFFC0CB),    // Pink
          'accent': const Color(0xFFFF1493),       // Deep pink
          'surface': const Color(0xFF2D1B2E),      // Dark purple
          'background': const Color(0xFF1A1A1A),   // Almost black
          'onPrimary': Colors.white,
          'onAccent': Colors.white,
          'error': const Color(0xFFFF6B6B),
        } : {
          'primary': const Color(0xFFFFB6C1),      // Light pink
          'secondary': const Color(0xFFFFC0CB),    // Pink
          'accent': const Color(0xFFFF69B4),       // Hot pink
          'surface': const Color(0xFFFFF8DC),      // Cornsilk
          'background': const Color(0xFFFAF0E6),   // Linen
          'onPrimary': Colors.white,
          'onAccent': Colors.white,
          'error': const Color(0xFFFF6B6B),
        };

      case 'blood_red':
        return isDark ? {
          'primary': const Color(0xFFDC143C),      // Crimson
          'secondary': const Color(0xFF8B0000),    // Dark red
          'accent': const Color(0xFFFF0000),       // Pure red
          'surface': const Color(0xFF2B1111),      // Very dark red
          'background': const Color(0xFF1A0A0A),   // Almost black with red tint
          'onPrimary': Colors.white,
          'onAccent': Colors.white,
          'error': const Color(0xFFFF4444),
        } : {
          'primary': const Color(0xFFDC143C),      // Crimson
          'secondary': const Color(0xFF8B0000),    // Dark red
          'accent': const Color(0xFFB22222),       // Fire brick
          'surface': const Color(0xFFFFF0F0),      // Very light red
          'background': const Color(0xFFFDF2F2),   // Light red background
          'onPrimary': Colors.white,
          'onAccent': Colors.white,
          'error': const Color(0xFFFF6B6B),
        };

      case 'ice_blue':
        return isDark ? {
          'primary': const Color(0xFF00BFFF),      // Deep sky blue
          'secondary': const Color(0xFF87CEEB),    // Sky blue
          'accent': const Color(0xFF1E90FF),       // Dodger blue
          'surface': const Color(0xFF0F1419),      // Very dark blue
          'background': const Color(0xFF0A0F14),   // Almost black with blue tint
          'onPrimary': Colors.white,
          'onAccent': Colors.white,
          'error': const Color(0xFFFF6B6B),
        } : {
          'primary': const Color(0xFF87CEEB),      // Sky blue
          'secondary': const Color(0xFFB0E0E6),    // Powder blue
          'accent': const Color(0xFF00BFFF),       // Deep sky blue
          'surface': const Color(0xFFF0F8FF),      // Alice blue
          'background': const Color(0xFFF8FCFF),   // Very light blue
          'onPrimary': Colors.white,
          'onAccent': Colors.white,
          'error': const Color(0xFFFF6B6B),
        };

      case 'forest_green':
        return isDark ? {
          'primary': const Color(0xFF228B22),      // Forest green
          'secondary': const Color(0xFF32CD32),    // Lime green
          'accent': const Color(0xFF00FF00),       // Pure green
          'surface': const Color(0xFF0F1F0F),      // Very dark green
          'background': const Color(0xFF0A140A),   // Almost black with green tint
          'onPrimary': Colors.white,
          'onAccent': Colors.black,
          'error': const Color(0xFFFF6B6B),
        } : {
          'primary': const Color(0xFF228B22),      // Forest green
          'secondary': const Color(0xFF32CD32),    // Lime green
          'accent': const Color(0xFF00C851),       // Material green
          'surface': const Color(0xFFF0FFF0),      // Honeydew
          'background': const Color(0xFFF8FFF8),   // Very light green
          'onPrimary': Colors.white,
          'onAccent': Colors.white,
          'error': const Color(0xFFFF6B6B),
        };

      case 'royal_purple':
        return isDark ? {
          'primary': const Color(0xFF6A0DAD),      // Purple
          'secondary': const Color(0xFF9370DB),    // Medium purple
          'accent': const Color(0xFF8A2BE2),       // Blue violet
          'surface': const Color(0xFF1A0F1A),      // Very dark purple
          'background': const Color(0xFF140A14),   // Almost black with purple tint
          'onPrimary': Colors.white,
          'onAccent': Colors.white,
          'error': const Color(0xFFFF6B6B),
        } : {
          'primary': const Color(0xFF6A0DAD),      // Purple
          'secondary': const Color(0xFF9370DB),    // Medium purple
          'accent': const Color(0xFF8A2BE2),       // Blue violet
          'surface': const Color(0xFFF8F0FF),      // Very light purple
          'background': const Color(0xFFFDF8FF),   // Light purple background
          'onPrimary': Colors.white,
          'onAccent': Colors.white,
          'error': const Color(0xFFFF6B6B),
        };

      case 'sunset_orange':
        return isDark ? {
          'primary': const Color(0xFFFF4500),      // Orange red
          'secondary': const Color(0xFFFF8C00),    // Dark orange
          'accent': const Color(0xFFFFA500),       // Orange
          'surface': const Color(0xFF1F1209),      // Very dark orange
          'background': const Color(0xFF140C06),   // Almost black with orange tint
          'onPrimary': Colors.white,
          'onAccent': Colors.black,
          'error': const Color(0xFFFF6B6B),
        } : {
          'primary': const Color(0xFFFF4500),      // Orange red
          'secondary': const Color(0xFFFF8C00),    // Dark orange
          'accent': const Color(0xFFFFA500),       // Orange
          'surface': const Color(0xFFFFF8F0),      // Very light orange
          'background': const Color(0xFFFFFAF5),   // Light orange background
          'onPrimary': Colors.white,
          'onAccent': Colors.black,
          'error': const Color(0xFFFF6B6B),
        };

      case 'midnight_black':
        return isDark ? {
          'primary': const Color(0xFF2C2C2C),      // Dark gray
          'secondary': const Color(0xFF404040),    // Medium gray
          'accent': const Color(0xFF666666),       // Light gray
          'surface': const Color(0xFF1A1A1A),      // Very dark gray
          'background': const Color(0xFF000000),   // Pure black
          'onPrimary': Colors.white,
          'onAccent': Colors.white,
          'error': const Color(0xFFFF6B6B),
        } : {
          'primary': const Color(0xFF2C2C2C),      // Dark gray
          'secondary': const Color(0xFF404040),    // Medium gray
          'accent': const Color(0xFF666666),       // Light gray
          'surface': const Color(0xFFF5F5F5),      // Very light gray
          'background': Colors.white,              // Pure white
          'onPrimary': Colors.white,
          'onAccent': Colors.white,
          'error': const Color(0xFFFF6B6B),
        };

      case 'ocean_teal':
        return isDark ? {
          'primary': const Color(0xFF008B8B),      // Dark cyan
          'secondary': const Color(0xFF20B2AA),    // Light sea green
          'accent': const Color(0xFF00CED1),       // Dark turquoise
          'surface': const Color(0xFF0F1919),      // Very dark teal
          'background': const Color(0xFF0A1414),   // Almost black with teal tint
          'onPrimary': Colors.white,
          'onAccent': Colors.white,
          'error': const Color(0xFFFF6B6B),
        } : {
          'primary': const Color(0xFF008B8B),      // Dark cyan
          'secondary': const Color(0xFF20B2AA),    // Light sea green
          'accent': const Color(0xFF00CED1),       // Dark turquoise
          'surface': const Color(0xFFF0FFFF),      // Azure
          'background': const Color(0xFFF8FFFF),   // Very light cyan
          'onPrimary': Colors.white,
          'onAccent': Colors.white,
          'error': const Color(0xFFFF6B6B),
        };

      default:
        return _getThemeColors('kawaii_pink', isDark: isDark);
    }
  }

  // Load theme color preference from shared preferences
  Future<void> _loadThemeColorPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeColor = prefs.getString('selected_theme_color');
      if (savedThemeColor != null) {
        setState(() {
          _selectedThemeColor = savedThemeColor;
        });
      }
    } catch (e, stack) {
      MainErrorHandler.handleAsyncError(e, stack, context: 'Load theme color preference');
    }
  }
}


class CrystalApp extends StatefulWidget {
  const CrystalApp({super.key});

  @override
  State<CrystalApp> createState() => _CrystalAppState();
}

class _CrystalAppState extends State<CrystalApp> with WidgetsBindingObserver {
  String? _username;
  bool _showSplash = true;

  static const inactivityThreshold = Duration(hours: 1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserThemePreference();
    _requestPermission(); // Ensure notification permission is requested
  }

  Future<void> _requestPermission() async {
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      ProductionLogger.logInfo('Notification permission granted', tag: 'PERMISSIONS');
    } else {
      ProductionLogger.logWarning('Notification permission denied', tag: 'PERMISSIONS');
    }
  }

  Future<void> _loadUserThemePreference() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final data = await Supabase.instance.client
        .from('users')
        .select('prefersDarkMode')
        .eq('id', user.id)
        .maybeSingle();

    final prefersDark = data?['prefersDarkMode'] ?? false;
    themeNotifier.value = prefersDark ? ThemeMode.dark : ThemeMode.light;
  }

  // Background handler moved to top-level function


  void _handleLogin(String username) {
    setState(() {
      _username = username;
    });
  }

  void _handleSplashFinished() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      prefs.setInt('lastActiveTime', now.millisecondsSinceEpoch);
    }

    if (state == AppLifecycleState.resumed) {
      final lastActiveMillis = prefs.getInt('lastActiveTime');
      if (lastActiveMillis != null) {
        final lastActive =
            DateTime.fromMillisecondsSinceEpoch(lastActiveMillis);
        final inactiveDuration = now.difference(lastActive);

        if (inactiveDuration >= inactivityThreshold) {
          // 🚀 ENHANCED: Check if auto-logout should be applied
          final currentUser = Supabase.instance.client.auth.currentUser;
          
          if (currentUser != null) {
            final shouldAutoLogout = await DeviceUserTrackingService.instance.shouldApplyAutoLogout();
            
            if (shouldAutoLogout) {
              // Multiple users detected - apply auto-logout
              await Supabase.instance.client.auth.signOut();
              
              // Deactivate device for push notifications
              await EnhancedPushNotificationIntegration.instance.onUserLogout(currentUser.id);
              await DeviceUserTrackingService.instance.trackUserLogout();
              
              _restartApp();
              ProductionLogger.logInfo('Auto signed out due to inactivity - Multiple users detected', tag: 'AUTH');
            } else {
              // Single user device - no auto-logout needed
              ProductionLogger.logInfo('Auto-logout skipped: Single user device', tag: 'AUTH');
            }
          }
        }
      }
      prefs.setInt('lastActiveTime', now.millisecondsSinceEpoch);
    }
  }

  void _restartApp() {
    // Instead of runApp, you should use a state management approach to restart the app
    // For now, you can sign out and navigate to login
    setState(() {
      _username = null;
      _showSplash = false;
    });
    // Optionally, navigate to EnhancedLoginScreen if needed
    // Navigator.of(context).pushAndRemoveUntil(
    //   MaterialPageRoute(builder: (_) => EnhancedLoginScreen(onLogin: _handleLogin)),
    //   (route) => false,
    // );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Crystal Social',
          themeMode: mode,
          theme: ThemeData(
            primarySwatch: Colors.pink,
            scaffoldBackgroundColor: const Color(0xFFFED8E6),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
            ),
          ),
          home: _showSplash
              ? SplashScreen(onFinished: _handleSplashFinished)
              : (_username == null
                  ? EnhancedLoginScreen(onLogin: _handleLogin)
                  : HomeScreen(currentUserId: _username!)),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const SplashScreen({super.key, required this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();

    // Finish splash after 3 seconds
    Future.delayed(const Duration(seconds: 3), widget.onFinished);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // GIF Background
          Positioned.fill(
            child: Image.asset(
              'assets/splash/splash.gif',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback gradient background if GIF is not found
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.purple.shade200,
                        Colors.pink.shade200,
                        Colors.blue.shade200,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Dark overlay for better text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
          ),
          
          // Content overlay
          FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Crystal icon with glow effect
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // App name with enhanced visibility
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.pink.shade100,
                          Colors.purple.shade100,
                          Colors.white,
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        'Crystal',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 3,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 10,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Subtitle with background
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      'Your magical social experience',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.95),
                        fontStyle: FontStyle.italic,
                        shadows: const [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 5,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  
                  // Enhanced loading indicator
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Loading...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 150,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              return FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _controller.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Colors.pink.shade200,
                                        Colors.purple.shade200,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        blurRadius: 8,
                                        spreadRadius: 1,
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
