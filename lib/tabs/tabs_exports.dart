/// Production-ready exports for Crystal Social tabs
/// This file provides centralized access to all tab screens with production optimizations
library tabs_exports;

import 'package:flutter/foundation.dart';

// Core tab screens - always available
export 'home_screen.dart';
export 'glitter_board.dart';
export 'call_screen.dart';
export 'enhanced_horoscope.dart';
export '../spotify/music.dart';
export 'information.dart';
export 'settings_screen.dart';

// Entertainment and utility tabs
export 'tarot_reading.dart';
export 'oracle.dart' hide ParticlePainter;
export '8ball.dart';
export 'front.dart';
export 'confession.dart';
export 'cursed_poll_screen.dart';
export 'glimmer_wall_screen.dart';
export 'enhanced_login_screen.dart' hide Particle, ParticlePainter;

// User information subsystem
export '../userinfo/user_list.dart';
export '../userinfo/user_profile_screen.dart';
export '../userinfo/enhanced_user_list_screen.dart';
export '../userinfo/enhanced_user_profile_screen.dart';
export '../userinfo/user_info_service.dart' hide InfoCategory;
export '../userinfo/user_info_provider.dart';
export '../userinfo/userinfo_system.dart' hide InfoCategory;

// Notes subsystem
export '../notes/notes_main.dart';
export '../notes/integration_example.dart';

// Production configuration
export 'tabs_production_config.dart';

/// Helper to check if a tab should be visible in production
bool isTabAvailable(String tabName, {bool requireAuth = false}) {
  // In production, all tabs should be available
  if (kReleaseMode) {
    return _productionTabs.contains(tabName);
  }
  
  // In development, allow all tabs
  return _productionTabs.contains(tabName) || _developmentTabs.contains(tabName);
}

/// Production-ready tab names
const Set<String> _productionTabs = {
  'home_screen',
  'glitter_board',
  'call_screen',
  'enhanced_horoscope',
  'music',
  'information',
  'settings_screen',
  'tarot_reading',
  'oracle',
  '8ball',
  'front',
  'confession',
  'cursed_poll_screen',
  'glimmer_wall_screen',
  'user_profiles',
  'notes_system',
};

/// Development/experimental tabs
const Set<String> _developmentTabs = {
  'debug_dashboard',
  'test_features',
  'performance_monitor',
};

/// Get tab display configuration for the environment
Map<String, dynamic> getTabDisplayConfig(String tabName) {
  final baseConfig = {
    'showBadges': kReleaseMode,
    'enableNotifications': kReleaseMode,
    'enableAnalytics': kReleaseMode,
    'showLoadingStates': true,
    'enableOfflineMode': kReleaseMode,
  };
  
  switch (tabName) {
    case 'home_screen':
      return {
        ...baseConfig,
        'showWelcomeMessage': kReleaseMode,
        'enableQuickActions': true,
        'maxAppsInGrid': kReleaseMode ? 20 : 50,
      };
      
    case 'glitter_board':
      return {
        ...baseConfig,
        'enableImageUploads': true,
        'enableVideoUploads': kReleaseMode,
        'maxPostLength': kReleaseMode ? 500 : 1000,
        'enableHashtags': true,
      };
      
    case 'call_screen':
      return {
        ...baseConfig,
        'enableRecording': kReleaseMode,
        'enableScreenSharing': kReleaseMode,
        'maxParticipants': kReleaseMode ? 8 : 20,
        'enableBackgroundBlur': true,
      };
      
    case 'enhanced_horoscope':
      return {
        ...baseConfig,
        'enablePaidFeatures': kReleaseMode,
        'enableDailyNotifications': kReleaseMode,
        'enableCosmicAnimations': true,
        'maxDailyCoinReward': kReleaseMode ? 100 : 1000,
      };
      
    case 'music':
      return {
        ...baseConfig,
        'enableSpotifyIntegration': kReleaseMode,
        'enableVoiceChat': kReleaseMode,
        'maxRoomSize': kReleaseMode ? 50 : 100,
        'enableMusicSharing': true,
      };
      
    default:
      return baseConfig;
  }
}

/// Tab performance monitoring
class TabPerformanceTracker {
  static final Map<String, DateTime> _tabLoadTimes = {};
  static final Map<String, int> _tabUsageCount = {};
  
  static void trackTabLoad(String tabName) {
    _tabLoadTimes[tabName] = DateTime.now();
    _tabUsageCount[tabName] = (_tabUsageCount[tabName] ?? 0) + 1;
    
    if (kDebugMode) {
      debugPrint('[TAB TRACKER] $tabName loaded (usage: ${_tabUsageCount[tabName]})');
    }
  }
  
  static void trackTabDispose(String tabName) {
    final loadTime = _tabLoadTimes[tabName];
    if (loadTime != null && kDebugMode) {
      final duration = DateTime.now().difference(loadTime);
      debugPrint('[TAB TRACKER] $tabName disposed after ${duration.inSeconds}s');
      _tabLoadTimes.remove(tabName);
    }
  }
  
  static Map<String, dynamic> getPerformanceStats() {
    return {
      'totalTabsLoaded': _tabUsageCount.length,
      'mostUsedTab': _tabUsageCount.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key,
      'averageUsagePerTab': _tabUsageCount.isEmpty 
          ? 0 
          : _tabUsageCount.values.reduce((a, b) => a + b) / _tabUsageCount.length,
      'currentlyActiveTab': _tabLoadTimes.length,
    };
  }
}
