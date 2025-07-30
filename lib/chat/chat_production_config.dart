// File: chat_production_config.dart
// Production configuration and constants for the chat system

import 'package:flutter/foundation.dart';

/// Production configuration for chat system
class ChatProductionConfig {
  // Environment settings
  static const bool isProduction = kReleaseMode;
  static const bool enableDebugLogging = !kReleaseMode;
  static const bool enablePerformanceMonitoring = true;
  
  // Chat limits and constraints
  static const int maxMessageLength = 1000;
  static const int maxMediaSizeMB = 25;
  static const int maxChatsPerUser = 100;
  static const int maxMessagesInMemory = 500;
  static const int maxChatHistory = 1000;
  
  // Real-time messaging configuration
  static const Duration messageLoadBatchSize = Duration(seconds: 30);
  static const Duration typingIndicatorTimeout = Duration(seconds: 5);
  static const Duration messageCacheTimeout = Duration(hours: 2);
  static const Duration presenceUpdateInterval = Duration(minutes: 1);
  
  // Chat features settings
  static const bool enableMediaSharing = true;
  static const bool enableVoiceMessages = false;
  static const bool enableStickers = true;
  static const bool enableEmojis = true;
  static const bool enableTypingIndicators = true;
  static const bool enableReadReceipts = true;
  static const bool enableChatBackgrounds = true;
  
  // Notification settings
  static const bool enablePushNotifications = true;
  static const bool enableSoundNotifications = true;
  static const bool enableVibrationNotifications = true;
  static const Duration notificationCooldown = Duration(seconds: 30);
  
  // Performance optimization
  static const Duration connectionRetryDelay = Duration(seconds: 3);
  static const int maxConnectionRetries = 5;
  static const Duration subscriptionTimeout = Duration(seconds: 20);
  static const Duration messageRetryDelay = Duration(milliseconds: 1500);
  
  // Auto-moderation settings
  static const bool enableAutoModeration = true;
  static const int maxConsecutiveMessages = 10;
  static const Duration spamPreventionWindow = Duration(seconds: 30);
  static const List<String> bannedWords = [
    // Add moderation keywords as needed
  ];
  
  // File sharing configuration
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> allowedVideoFormats = ['mp4', 'mov', 'avi', 'mkv'];
  static const List<String> allowedAudioFormats = ['mp3', 'wav', 'aac', 'm4a'];
  static const List<String> allowedDocumentFormats = ['pdf', 'doc', 'docx', 'txt'];
  
  // UI/UX settings
  static const Duration animationDuration = Duration(milliseconds: 250);
  static const Duration loadingTimeout = Duration(seconds: 15);
  static const int maxRecentChats = 50;
  static const bool enableHapticFeedback = true;
  static const double defaultFontSize = 16.0;
  static const double minFontSize = 12.0;
  static const double maxFontSize = 24.0;
  
  // Security settings
  static const bool enableMessageEncryption = false;
  static const Duration sessionTimeout = Duration(hours: 12);
  static const bool enableAuditLogging = true;
  static const bool enableScreenshotDetection = false;
  
  // Backup and sync settings
  static const bool enableCloudBackup = true;
  static const Duration backupInterval = Duration(hours: 6);
  static const bool enableCrossDeviceSync = true;
}

/// Debug utilities for chat system
class ChatDebugUtils {
  static void log(String component, String message) {
    if (ChatProductionConfig.enableDebugLogging) {
      debugPrint('🔵 Chat[$component]: $message');
    }
  }
  
  static void logError(String component, String error) {
    if (ChatProductionConfig.enableDebugLogging) {
      debugPrint('🔴 Chat[$component] ERROR: $error');
    }
    // In production, you might want to send to crash reporting service
    // CrashReporting.recordError('Chat[$component]', error);
  }
  
  static void logWarning(String component, String warning) {
    if (ChatProductionConfig.enableDebugLogging) {
      debugPrint('🟡 Chat[$component] WARNING: $warning');
    }
  }
  
  static void logSuccess(String component, String message) {
    if (ChatProductionConfig.enableDebugLogging) {
      debugPrint('🟢 Chat[$component] SUCCESS: $message');
    }
  }
  
  static void logPerformance(String component, String operation, Duration duration) {
    if (ChatProductionConfig.enablePerformanceMonitoring) {
      debugPrint('⚡ Chat[$component] PERF: $operation took ${duration.inMilliseconds}ms');
    }
  }
}

/// Production-safe error handling for chat
class ChatErrorHandler {
  static void handleError(String context, dynamic error, {
    VoidCallback? onRetry,
    String? userMessage,
  }) {
    ChatDebugUtils.logError(context, error.toString());
    
    // In production, handle specific error types
    if (error.toString().contains('network')) {
      // Handle network errors
      if (onRetry != null) {
        Future.delayed(ChatProductionConfig.connectionRetryDelay, onRetry);
      }
    } else if (error.toString().contains('permission')) {
      // Handle permission errors
      ChatDebugUtils.logWarning(context, 'Permission denied for $context');
    } else if (error.toString().contains('storage')) {
      // Handle storage errors
      ChatDebugUtils.logWarning(context, 'Storage error in $context');
    }
    
    // Show user-friendly message if provided
    if (userMessage != null && !ChatProductionConfig.isProduction) {
      // Show snackbar or dialog in debug mode
    }
  }
  
  static Future<T?> safeExecute<T>(
    String context,
    Future<T> Function() operation, {
    T? fallback,
    bool silent = false,
  }) async {
    try {
      return await operation();
    } catch (e) {
      if (!silent) {
        handleError(context, e);
      }
      return fallback;
    }
  }
}

/// Chat system utilities
class ChatSystemUtils {
  /// Validate message content
  static bool isValidMessage(String content) {
    if (content.trim().isEmpty) return false;
    if (content.length > ChatProductionConfig.maxMessageLength) return false;
    
    // Check for banned words
    final lowerContent = content.toLowerCase();
    for (final bannedWord in ChatProductionConfig.bannedWords) {
      if (lowerContent.contains(bannedWord.toLowerCase())) return false;
    }
    
    return true;
  }
  
  /// Validate file format
  static bool isValidFileFormat(String fileName, String fileType) {
    final extension = fileName.split('.').last.toLowerCase();
    
    switch (fileType.toLowerCase()) {
      case 'image':
        return ChatProductionConfig.allowedImageFormats.contains(extension);
      case 'video':
        return ChatProductionConfig.allowedVideoFormats.contains(extension);
      case 'audio':
        return ChatProductionConfig.allowedAudioFormats.contains(extension);
      case 'document':
        return ChatProductionConfig.allowedDocumentFormats.contains(extension);
      default:
        return false;
    }
  }
  
  /// Get file type from extension
  static String getFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    
    if (ChatProductionConfig.allowedImageFormats.contains(extension)) return 'image';
    if (ChatProductionConfig.allowedVideoFormats.contains(extension)) return 'video';
    if (ChatProductionConfig.allowedAudioFormats.contains(extension)) return 'audio';
    if (ChatProductionConfig.allowedDocumentFormats.contains(extension)) return 'document';
    
    return 'unknown';
  }
  
  /// Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  /// Generate unique message ID
  static String generateMessageId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch % 1000}';
  }
}
