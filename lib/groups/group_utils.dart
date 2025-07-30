import 'package:flutter/material.dart';

class GroupConstants {
  // Colors
  static const Color primaryColor = Colors.pink;
  static Color primaryLightColor = Colors.pink.shade100;
  static Color primaryDarkColor = Colors.pink.shade700;
  
  // Text Styles
  static const TextStyle groupNameStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  
  static const TextStyle groupDescriptionStyle = TextStyle(
    fontSize: 13,
    color: Colors.grey,
  );
  
  static const TextStyle memberCountStyle = TextStyle(
    fontSize: 12,
    color: Colors.grey,
  );
  
  // Dimensions
  static const double groupAvatarSize = 56.0;
  static const double cardElevation = 2.0;
  static const double cardRadius = 12.0;
  
  // Animation Durations
  static const Duration animationDuration = Duration(milliseconds: 300);
  
  // Validation
  static const int minGroupNameLength = 1;
  static const int maxGroupNameLength = 100;
  static const int maxGroupDescriptionLength = 500;
  static const int minGroupMembers = 2; // Including creator
  static const int maxGroupMembers = 256;
}

class GroupUtils {
  static String formatMemberCount(int count) {
    if (count == 1) return '1 member';
    return '$count members';
  }
  
  static String formatLastSeen(String? lastSeenStr) {
    if (lastSeenStr == null) return 'Never';
    
    final lastSeen = DateTime.tryParse(lastSeenStr);
    if (lastSeen == null) return 'Unknown';
    
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()}w ago';
    if (difference.inDays < 365) return '${(difference.inDays / 30).floor()}mo ago';
    
    return '${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
  }
  
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
  
  static bool isValidGroupName(String name) {
    return name.trim().length >= GroupConstants.minGroupNameLength &&
           name.trim().length <= GroupConstants.maxGroupNameLength;
  }
  
  static bool isValidGroupDescription(String description) {
    return description.length <= GroupConstants.maxGroupDescriptionLength;
  }
  
  static Color getAvatarColor(String text) {
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
    ];
    
    final hash = text.hashCode;
    return colors[hash.abs() % colors.length];
  }
  
  static String getInitials(String name) {
    if (name.isEmpty) return '?';
    
    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    
    return words.take(2)
        .map((word) => word.isNotEmpty ? word.substring(0, 1).toUpperCase() : '')
        .join();
  }
  
  static bool isImageFile(String? url) {
    if (url == null) return false;
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.jpg') ||
           lowerUrl.endsWith('.jpeg') ||
           lowerUrl.endsWith('.png') ||
           lowerUrl.endsWith('.gif') ||
           lowerUrl.endsWith('.webp');
  }
  
  static bool isVideoFile(String? url) {
    if (url == null) return false;
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.mp4') ||
           lowerUrl.endsWith('.mov') ||
           lowerUrl.endsWith('.avi') ||
           lowerUrl.endsWith('.mkv') ||
           lowerUrl.endsWith('.webm');
  }
  
  static bool isAudioFile(String? url) {
    if (url == null) return false;
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.mp3') ||
           lowerUrl.endsWith('.wav') ||
           lowerUrl.endsWith('.aac') ||
           lowerUrl.endsWith('.ogg') ||
           lowerUrl.endsWith('.m4a');
  }
  
  static MediaType getMediaType(String? url) {
    if (isImageFile(url)) return MediaType.image;
    if (isVideoFile(url)) return MediaType.video;
    if (isAudioFile(url)) return MediaType.audio;
    return MediaType.unknown;
  }
}

enum MediaType { image, video, audio, unknown }

enum GroupRole { owner, admin, member }

class GroupPermissions {
  static bool canEditGroup(GroupRole role) {
    return role == GroupRole.owner || role == GroupRole.admin;
  }
  
  static bool canManageMembers(GroupRole role) {
    return role == GroupRole.owner || role == GroupRole.admin;
  }
  
  static bool canDeleteGroup(GroupRole role) {
    return role == GroupRole.owner;
  }
  
  static bool canPromoteMembers(GroupRole role) {
    return role == GroupRole.owner;
  }
  
  static bool canChangeSettings(GroupRole role) {
    return role == GroupRole.owner || role == GroupRole.admin;
  }
}
