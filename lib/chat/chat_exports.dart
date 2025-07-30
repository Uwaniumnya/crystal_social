// Crystal Social Chat System - Production Export Management
// Centralized exports for all chat-related functionality

// Core chat system
export 'chat_service.dart';
export 'chat_provider.dart';
export 'chat_screen.dart';

// Media handling
export 'media_viewer.dart';

// Production infrastructure
export 'chat_production_config.dart';
export 'chat_performance_optimizer.dart';
export 'chat_validator.dart';

// Import required classes for the utility class
import 'chat_production_config.dart';
import 'chat_validator.dart';
import 'chat_performance_optimizer.dart';

// Chat utilities and models
class ChatSystemExports {
  // Production configuration
  static const String version = '1.0.0';
  static const String buildDate = '2025-07-27';
  
  // Feature flags for production
  static const bool enableRealTimeMessaging = true;
  static const bool enableMediaSharing = true;
  static const bool enableChatBackgrounds = true;
  static const bool enableTypingIndicators = true;
  static const bool enableReadReceipts = true;
  static const bool enablePushNotifications = true;
  static const bool enableChatThemes = true;
  static const bool enableStickerSupport = true;
  static const bool enableEmojiReactions = true;
  static const bool enableVoiceMessages = true;
  
  // Performance settings
  static const int maxMessagesPerPage = 50;
  static const int maxCachedChats = 100;
  static const int messageRetentionDays = 365;
  static const Duration typingIndicatorTimeout = Duration(seconds: 3);
  static const Duration messageDeliveryTimeout = Duration(seconds: 30);
  
  // Media limits
  static const int maxImageSizeMB = 10;
  static const int maxVideoSizeMB = 50;
  static const int maxAudioSizeMB = 25;
  static const int maxDocumentSizeMB = 100;
  
  // Security settings
  static const bool enableMessageEncryption = true;
  static const bool enableContentModeration = true;
  static const bool enableSpamDetection = true;
  static const bool enableBlockedUsers = true;
  
  // System health indicators
  static bool get isSystemHealthy {
    try {
      // Validate core chat components
      return ChatProductionConfig.isProduction &&
             ChatProductionConfig.enableMediaSharing &&
             ChatProductionConfig.enableStickers;
    } catch (e) {
      ChatDebugUtils.logError('ChatSystemExports', 'Health check failed: $e');
      return false;
    }
  }
  
  // Production readiness check
  static Future<bool> validateProductionReadiness() async {
    try {
      final result = await ChatValidator.validateProductionReadiness();
      return result['isValid'] ?? false;
    } catch (e) {
      ChatDebugUtils.logError('ChatSystemExports', 'Production validation failed: $e');
      return false;
    }
  }
  
  // Initialize chat system for production
  static Future<void> initializeForProduction() async {
    try {
      ChatDebugUtils.log('ChatSystemExports', 'Initializing chat system for production...');
      
      // Initialize performance optimizer
      final optimizer = ChatPerformanceOptimizer();
      optimizer.initialize();
      
      // Validate system readiness
      final isReady = await validateProductionReadiness();
      if (!isReady) {
        throw Exception('Chat system not ready for production');
      }
      
      ChatDebugUtils.logSuccess('ChatSystemExports', 'Chat system initialized successfully');
    } catch (e) {
      ChatDebugUtils.logError('ChatSystemExports', 'Failed to initialize chat system: $e');
      rethrow;
    }
  }
  
  // System diagnostics
  static Map<String, dynamic> getDiagnostics() {
    return {
      'version': version,
      'buildDate': buildDate,
      'isProduction': ChatProductionConfig.isProduction,
      'featuresEnabled': {
        'realTimeMessaging': enableRealTimeMessaging,
        'mediaSharing': enableMediaSharing,
        'chatBackgrounds': enableChatBackgrounds,
        'typingIndicators': enableTypingIndicators,
        'readReceipts': enableReadReceipts,
        'pushNotifications': enablePushNotifications,
        'chatThemes': enableChatThemes,
        'stickerSupport': enableStickerSupport,
        'emojiReactions': enableEmojiReactions,
        'voiceMessages': enableVoiceMessages,
      },
      'limits': {
        'maxMessagesPerPage': maxMessagesPerPage,
        'maxCachedChats': maxCachedChats,
        'messageRetentionDays': messageRetentionDays,
        'maxImageSizeMB': maxImageSizeMB,
        'maxVideoSizeMB': maxVideoSizeMB,
        'maxAudioSizeMB': maxAudioSizeMB,
        'maxDocumentSizeMB': maxDocumentSizeMB,
      },
      'security': {
        'messageEncryption': enableMessageEncryption,
        'contentModeration': enableContentModeration,
        'spamDetection': enableSpamDetection,
        'blockedUsers': enableBlockedUsers,
      },
      'health': isSystemHealthy,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
