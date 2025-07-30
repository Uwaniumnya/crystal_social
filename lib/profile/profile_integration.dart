// Profile Module - Unified Integration
// This file provides a centralized export for all profile-related components

// Core Services
export 'profile_service.dart';
export 'profile_provider.dart';

// Main Screens
export 'enhanced_profile_screen.dart';
export 'enhanced_edit_profile_screen.dart';

// Specialized Components
export 'avatar_decoration.dart';
export 'stats_dashboard.dart';
export 'notification_sound_picker.dart';
export 'ringtone_picker_screen.dart';

// Legacy screens (for backward compatibility) - hide conflicting names

export 'avatar_picker.dart';

/// Integration Summary:
/// 
/// The profile system now uses a centralized architecture with:
/// 
/// 1. ProfileService - Singleton service managing all profile data and operations
/// 2. ProfileProvider - Provider wrapper for reactive UI updates
/// 3. Enhanced screens that use the centralized service
/// 4. Smooth integration between all profile components
/// 
/// Key Features:
/// - Centralized state management
/// - Real-time profile updates
/// - Avatar decoration system
/// - Sound customization
/// - Statistics tracking
/// - Profile completion indicators
/// - Cross-component data sharing
/// 
/// Usage:
/// ```dart
/// // Initialize profile service
/// await ProfileService.instance.initialize(userId);
/// 
/// // Use in widgets with Provider
/// Consumer<ProfileProvider>(
///   builder: (context, profile, _) => ProfileAvatar(),
/// )
/// 
/// // Access via context extensions
/// context.profile.updateProfile(data);
/// ```
