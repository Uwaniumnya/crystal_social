import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'profile_service.dart';

/// Profile Provider that wraps the ProfileService for easier access in widgets
class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService.instance;

  ProfileProvider() {
    // Listen to ProfileService changes and notify widgets
    _profileService.addListener(_onServiceUpdate);
  }

  void _onServiceUpdate() {
    notifyListeners();
  }

  @override
  void dispose() {
    _profileService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  // Delegate all getters to the service
  bool get isInitialized => _profileService.isInitialized;
  bool get isLoading => _profileService.isLoading;
  String? get error => _profileService.error;
  String? get currentUserId => _profileService.currentUserId;
  Map<String, dynamic> get userProfile => _profileService.userProfile;
  Map<String, dynamic> get userStats => _profileService.userStats;
  List<Map<String, dynamic>> get avatarDecorations => _profileService.avatarDecorations;
  Map<String, dynamic> get soundSettings => _profileService.soundSettings;

  // Quick access getters
  String? get username => _profileService.username;
  String? get avatarUrl => _profileService.avatarUrl;
  String? get bio => _profileService.bio;
  String? get displayName => _profileService.displayName;
  String? get location => _profileService.location;
  String? get website => _profileService.website;
  String? get zodiacSign => _profileService.zodiacSign;
  List<String>? get interests => _profileService.interests;
  Map<String, dynamic>? get socialLinks => _profileService.socialLinks;
  String? get avatarDecoration => _profileService.avatarDecoration;
  bool get isPrivateProfile => _profileService.isPrivateProfile;

  // Methods
  Future<void> initialize(String userId) => _profileService.initialize(userId);
  Future<void> refresh() => _profileService.refresh();
  Future<bool> updateProfile(Map<String, dynamic> updates) => _profileService.updateProfile(updates);
  Future<String?> uploadAvatar(File imageFile) => _profileService.uploadAvatar(imageFile);
  Future<bool> setAvatarDecoration(String? decorationPath) => _profileService.setAvatarDecoration(decorationPath);
  Future<bool> updateSoundSettings({String? defaultRingtone, Map<String, dynamic>? notificationPreferences}) => 
      _profileService.updateSoundSettings(defaultRingtone: defaultRingtone, notificationPreferences: notificationPreferences);
  Future<bool> setPerUserRingtone(String senderId, String ringtone) => _profileService.setPerUserRingtone(senderId, ringtone);
  Future<String?> getPerUserRingtone(String senderId) => _profileService.getPerUserRingtone(senderId);
  Future<bool> updateStats(Map<String, dynamic> stats) => _profileService.updateStats(stats);
  Future<bool> incrementStat(String statName, [int amount = 1]) => _profileService.incrementStat(statName, amount);
  double getProfileCompletionPercentage() => _profileService.getProfileCompletionPercentage();
  bool ownsDecoration(String decorationId) => _profileService.ownsDecoration(decorationId);
  Future<bool> purchaseDecoration(String decorationId, int cost) => _profileService.purchaseDecoration(decorationId, cost);
  void clear() => _profileService.clear();
  String getDisplayName() => _profileService.getDisplayName();
  int getUserLevel() => _profileService.getUserLevel();
  int getActivityScore() => _profileService.getActivityScore();
}

/// Mixin to easily access ProfileProvider in widgets
mixin ProfileMixin<T extends StatefulWidget> on State<T> {
  ProfileProvider get profileProvider => Provider.of<ProfileProvider>(context, listen: false);
  ProfileProvider get watchProfile => Provider.of<ProfileProvider>(context);
}

/// Extension to access ProfileProvider from BuildContext
extension ProfileContext on BuildContext {
  ProfileProvider get profile => Provider.of<ProfileProvider>(this, listen: false);
  ProfileProvider get watchProfile => Provider.of<ProfileProvider>(this);
}

/// Widget builder that rebuilds when profile data changes
class ProfileBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ProfileProvider profile) builder;
  final Widget? child;

  const ProfileBuilder({
    super.key,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profile, child) => builder(context, profile),
      child: child,
    );
  }
}

/// Widget that shows loading state while profile is being loaded
class ProfileLoadingWrapper extends StatelessWidget {
  final Widget child;
  final Widget? loadingWidget;
  final Widget Function(String error)? errorBuilder;

  const ProfileLoadingWrapper({
    super.key,
    required this.child,
    this.loadingWidget,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileBuilder(
      builder: (context, profile) {
        if (profile.error != null && errorBuilder != null) {
          return errorBuilder!(profile.error!);
        }
        
        if (profile.isLoading && !profile.isInitialized) {
          return loadingWidget ?? const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        return child;
      },
    );
  }
}

/// Convenient widgets for common profile operations
class ProfileAvatar extends StatelessWidget {
  final double radius;
  final VoidCallback? onTap;
  final bool showDecoration;

  const ProfileAvatar({
    super.key,
    this.radius = 30,
    this.onTap,
    this.showDecoration = true,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileBuilder(
      builder: (context, profile) {
        Widget avatar = CircleAvatar(
          radius: radius,
          backgroundImage: profile.avatarUrl != null 
              ? NetworkImage(profile.avatarUrl!) 
              : null,
          child: profile.avatarUrl == null 
              ? Icon(Icons.person, size: radius) 
              : null,
        );

        if (showDecoration && profile.avatarDecoration != null) {
          avatar = Stack(
            children: [
              avatar,
              Positioned.fill(
                child: Image.asset(
                  profile.avatarDecoration!,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          );
        }

        if (onTap != null) {
          avatar = GestureDetector(
            onTap: onTap,
            child: avatar,
          );
        }

        return avatar;
      },
    );
  }
}

class ProfileDisplayName extends StatelessWidget {
  final TextStyle? style;

  const ProfileDisplayName({
    super.key,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileBuilder(
      builder: (context, profile) {
        return Text(
          profile.getDisplayName(),
          style: style,
        );
      },
    );
  }
}

class ProfileCompletionIndicator extends StatelessWidget {
  final double height;
  final Color? backgroundColor;
  final Color? progressColor;

  const ProfileCompletionIndicator({
    super.key,
    this.height = 4,
    this.backgroundColor,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileBuilder(
      builder: (context, profile) {
        final completion = profile.getProfileCompletionPercentage();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile ${(completion * 100).toInt()}% complete',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: completion,
              backgroundColor: backgroundColor ?? Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(
                progressColor ?? Theme.of(context).primaryColor,
              ),
              minHeight: height,
            ),
          ],
        );
      },
    );
  }
}
