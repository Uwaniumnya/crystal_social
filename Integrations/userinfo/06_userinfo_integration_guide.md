# Crystal Social UserInfo System - Integration Guide

## Overview
This document provides a comprehensive guide for integrating the UserInfo SQL system with the Crystal Social Flutter application. The system manages user profile information with 17 specialized categories for system/collective identity, profile completion tracking, discovery settings, analytics, and content moderation.

## Table of Contents
1. [Database Schema Overview](#database-schema-overview)
2. [Integration Steps](#integration-steps)
3. [API Integration](#api-integration)
4. [Frontend Integration](#frontend-integration)
5. [Security Implementation](#security-implementation)
6. [Real-time Features](#real-time-features)
7. [Analytics and Monitoring](#analytics-and-monitoring)
8. [Maintenance and Operations](#maintenance-and-operations)
9. [Testing Guidelines](#testing-guidelines)
10. [Troubleshooting](#troubleshooting)

## Database Schema Overview

### Core Tables
- **user_info** - Main table storing user profile information and content
- **user_info_categories** - Predefined categories with 17 specialized options
- **user_category_preferences** - User-specific category customizations
- **user_discovery_settings** - Privacy and discoverability controls
- **user_profile_completion** - Automated completion tracking and scoring
- **user_info_interactions** - Profile viewing and interaction tracking
- **user_info_analytics** - Daily analytics and engagement metrics
- **user_info_moderation** - Content moderation and approval system

### Key Features
- **17 Specialized Categories**: Role, Pronouns, Age, Sexuality, Animal embodied, Fronting Frequency, Rank, Barrier level, Personality, MBTI, Alignment chart, Trigger, Belief system, Cliques, Purpose, Sex positioning, Song
- **Automatic Profile Completion Tracking** (0-100%)
- **Quality Scoring System** (1-10 scale)
- **Real-time Analytics and Engagement Metrics**
- **Content Moderation with Automated Scoring**
- **Discovery and Privacy Controls**
- **Comprehensive Security Policies**

## Integration Steps

### 1. Database Setup

#### Run SQL Files in Order
```sql
-- Execute in Supabase SQL Editor or psql
\i 01_userinfo_core_tables.sql
\i 02_userinfo_business_logic.sql
\i 03_userinfo_views_analytics.sql
\i 04_userinfo_security_policies.sql
\i 05_userinfo_triggers_automation.sql
```

#### Verify Installation
```sql
-- Check tables are created
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE 'user_info%';

-- Check categories are populated
SELECT category_name, display_name, category_group 
FROM user_info_categories 
WHERE is_active = true 
ORDER BY category_order;

-- Test basic functions
SELECT check_content_moderation_required('Test content with https://example.com');
SELECT get_user_profile_summary('00000000-0000-0000-0000-000000000000'::uuid);
```

### 2. Environment Configuration

#### Supabase Configuration
```dart
// lib/config/supabase_config.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://zdsjtjbzhiejvpuahnlk.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpkc2p0amJ6aGllanZwdWFobmxrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4MjAyMzYsImV4cCI6MjA2OTM5NjIzNn0.CSPzbngxKJHrHD8oNMFaYzvKXzNzMENFtaWu9Vy2rV0';
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
}
```

#### Database Permissions
```sql
-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_info TO authenticated;
GRANT SELECT ON user_info_categories TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_category_preferences TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_discovery_settings TO authenticated;
GRANT SELECT ON user_profile_completion TO authenticated;
```

## API Integration

### 1. UserInfo Service Updates

#### Enhanced Database Operations
```dart
// lib/userinfo/user_info_service.dart - Add to existing service

class UserInfoService {
  final SupabaseClient _client = SupabaseConfig.client;
  
  // Get user profile with completion data
  Future<Map<String, dynamic>?> getUserProfileComplete(String userId) async {
    try {
      final response = await _client
          .from('user_profile_overview')
          .select('*')
          .eq('user_id', userId)
          .single();
      
      return response;
    } catch (e) {
      print('Error getting complete profile: $e');
      return null;
    }
  }
  
  // Get user category summary
  Future<List<Map<String, dynamic>>> getUserCategories(String userId) async {
    try {
      final response = await _client
          .from('user_category_summary')
          .select('*')
          .eq('user_id', userId)
          .order('custom_order, category_order');
      
      return response;
    } catch (e) {
      print('Error getting user categories: $e');
      return [];
    }
  }
  
  // Add user info with automatic moderation
  Future<Map<String, dynamic>?> addUserInfo({
    required String userId,
    required String category,
    required String content,
    String infoType = 'category',
  }) async {
    try {
      // Check rate limit first
      final canAdd = await _client.rpc('check_user_rate_limit', params: {
        'user_id': userId,
        'action_type': 'create_user_info'
      });
      
      if (!canAdd) {
        throw Exception('Rate limit exceeded. Please try again later.');
      }
      
      final response = await _client
          .from('user_info')
          .insert({
            'user_id': userId,
            'category': category,
            'content': content,
            'info_type': infoType,
          })
          .select()
          .single();
      
      return response;
    } catch (e) {
      print('Error adding user info: $e');
      rethrow;
    }
  }
  
  // Update user discovery settings
  Future<void> updateDiscoverySettings({
    required String userId,
    bool? isDiscoverable,
    String? privacyLevel,
    bool? allowProfileViews,
    bool? showCompletionPercentage,
  }) async {
    try {
      await _client
          .from('user_discovery_settings')
          .upsert({
            'user_id': userId,
            if (isDiscoverable != null) 'is_discoverable': isDiscoverable,
            if (privacyLevel != null) 'privacy_level': privacyLevel,
            if (allowProfileViews != null) 'allow_profile_views': allowProfileViews,
            if (showCompletionPercentage != null) 
              'show_completion_percentage': showCompletionPercentage,
          });
    } catch (e) {
      print('Error updating discovery settings: $e');
      rethrow;
    }
  }
  
  // Record profile interaction
  Future<void> recordProfileInteraction({
    required String viewerUserId,
    required String viewedUserId,
    String interactionType = 'profile_view',
    String? categoryName,
    int? viewDurationSeconds,
  }) async {
    try {
      await _client
          .from('user_info_interactions')
          .insert({
            'viewer_user_id': viewerUserId,
            'viewed_user_id': viewedUserId,
            'interaction_type': interactionType,
            'category_name': categoryName,
            'view_duration_seconds': viewDurationSeconds,
          });
    } catch (e) {
      print('Error recording interaction: $e');
      // Don't rethrow - interactions are not critical
    }
  }
  
  // Get discoverable users
  Future<List<Map<String, dynamic>>> getDiscoverableUsers({
    int limit = 20,
    int offset = 0,
    String? searchTerm,
  }) async {
    try {
      var query = _client
          .from('discoverable_users')
          .select('*');
      
      if (searchTerm != null && searchTerm.isNotEmpty) {
        query = query.ilike('username', '%$searchTerm%');
      }
      
      final response = await query
          .range(offset, offset + limit - 1)
          .order('engagement_score', ascending: false);
      
      return response;
    } catch (e) {
      print('Error getting discoverable users: $e');
      return [];
    }
  }
  
  // Get trending categories
  Future<List<Map<String, dynamic>>> getTrendingCategories({int limit = 10}) async {
    try {
      final response = await _client
          .from('trending_content')
          .select('*')
          .eq('trend_type', 'category')
          .order('trending_score', ascending: false)
          .limit(limit);
      
      return response;
    } catch (e) {
      print('Error getting trending categories: $e');
      return [];
    }
  }
}
```

### 2. Provider Updates

#### Enhanced State Management
```dart
// lib/userinfo/user_info_provider.dart - Add to existing provider

class UserInfoProvider extends ChangeNotifier {
  final UserInfoService _service = UserInfoService();
  
  // New properties for enhanced features
  Map<String, dynamic>? _profileCompletion;
  List<Map<String, dynamic>> _userCategories = [];
  Map<String, dynamic>? _discoverySettings;
  bool _isLoading = false;
  
  // Getters
  Map<String, dynamic>? get profileCompletion => _profileCompletion;
  List<Map<String, dynamic>> get userCategories => _userCategories;
  Map<String, dynamic>? get discoverySettings => _discoverySettings;
  bool get isLoading => _isLoading;
  
  // Get completion percentage
  double get completionPercentage {
    return _profileCompletion?['completion_percentage']?.toDouble() ?? 0.0;
  }
  
  // Get quality score
  double get qualityScore {
    return _profileCompletion?['profile_quality_score']?.toDouble() ?? 0.0;
  }
  
  // Load complete user profile
  Future<void> loadCompleteProfile(String userId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Load profile completion data
      final profile = await _service.getUserProfileComplete(userId);
      _profileCompletion = profile;
      
      // Load user categories
      _userCategories = await _service.getUserCategories(userId);
      
      // Load discovery settings
      final settings = await _service._client
          .from('user_discovery_settings')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();
      _discoverySettings = settings;
      
    } catch (e) {
      print('Error loading complete profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update discovery settings
  Future<void> updateDiscoverySettings({
    bool? isDiscoverable,
    String? privacyLevel,
    bool? allowProfileViews,
    bool? showCompletionPercentage,
  }) async {
    final userId = _getCurrentUserId();
    if (userId == null) return;
    
    try {
      await _service.updateDiscoverySettings(
        userId: userId,
        isDiscoverable: isDiscoverable,
        privacyLevel: privacyLevel,
        allowProfileViews: allowProfileViews,
        showCompletionPercentage: showCompletionPercentage,
      );
      
      // Reload settings
      await loadCompleteProfile(userId);
    } catch (e) {
      print('Error updating discovery settings: $e');
      rethrow;
    }
  }
  
  // Get category by name
  Map<String, dynamic>? getCategoryData(String categoryName) {
    return _userCategories.firstWhere(
      (cat) => cat['category_name'] == categoryName,
      orElse: () => {},
    );
  }
  
  // Check if category is favorite
  bool isCategoryFavorite(String categoryName) {
    final category = getCategoryData(categoryName);
    return category?['is_favorite'] ?? false;
  }
  
  // Toggle category favorite
  Future<void> toggleCategoryFavorite(String categoryName) async {
    final userId = _getCurrentUserId();
    if (userId == null) return;
    
    final currentFavorite = isCategoryFavorite(categoryName);
    
    try {
      await _service._client
          .from('user_category_preferences')
          .upsert({
            'user_id': userId,
            'category_name': categoryName,
            'is_favorite': !currentFavorite,
          });
      
      // Update local state
      final categoryIndex = _userCategories.indexWhere(
        (cat) => cat['category_name'] == categoryName
      );
      if (categoryIndex != -1) {
        _userCategories[categoryIndex]['is_favorite'] = !currentFavorite;
        notifyListeners();
      }
    } catch (e) {
      print('Error toggling category favorite: $e');
      rethrow;
    }
  }
  
  String? _getCurrentUserId() {
    return SupabaseConfig.client.auth.currentUser?.id;
  }
}
```

## Frontend Integration

### 1. Profile Completion Widget

```dart
// lib/widgets/profile_completion_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../userinfo/user_info_provider.dart';

class ProfileCompletionWidget extends StatelessWidget {
  const ProfileCompletionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<UserInfoProvider>(
      builder: (context, provider, child) {
        final completion = provider.completionPercentage;
        final quality = provider.qualityScore;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Profile Completion',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${completion.toInt()}%',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _getCompletionColor(completion),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: completion / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getCompletionColor(completion),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      _getQualityIcon(quality),
                      size: 16,
                      color: _getQualityColor(quality),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Quality: ${quality.toStringAsFixed(1)}/10',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getQualityColor(quality),
                      ),
                    ),
                  ],
                ),
                if (completion < 100) ...[
                  const SizedBox(height: 8),
                  Text(
                    _getCompletionTip(completion),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
  
  Color _getCompletionColor(double completion) {
    if (completion >= 80) return Colors.green;
    if (completion >= 50) return Colors.orange;
    if (completion >= 20) return Colors.blue;
    return Colors.red;
  }
  
  Color _getQualityColor(double quality) {
    if (quality >= 8) return Colors.green;
    if (quality >= 6) return Colors.orange;
    if (quality >= 4) return Colors.blue;
    return Colors.red;
  }
  
  IconData _getQualityIcon(double quality) {
    if (quality >= 8) return Icons.star;
    if (quality >= 6) return Icons.thumb_up;
    if (quality >= 4) return Icons.info;
    return Icons.warning;
  }
  
  String _getCompletionTip(double completion) {
    if (completion < 20) {
      return 'Add more categories to improve your profile visibility';
    } else if (completion < 50) {
      return 'Consider adding a profile photo and bio';
    } else if (completion < 80) {
      return 'Add free-text content to express yourself';
    } else {
      return 'Great profile! Consider exploring more categories';
    }
  }
}
```

### 2. Discovery Settings Screen

```dart
// lib/userinfo/discovery_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_info_provider.dart';

class DiscoverySettingsScreen extends StatefulWidget {
  const DiscoverySettingsScreen({Key? key}) : super(key: key);

  @override
  State<DiscoverySettingsScreen> createState() => _DiscoverySettingsScreenState();
}

class _DiscoverySettingsScreenState extends State<DiscoverySettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discovery Settings'),
      ),
      body: Consumer<UserInfoProvider>(
        builder: (context, provider, child) {
          final settings = provider.discoverySettings;
          
          if (settings == null) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile Visibility',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      
                      SwitchListTile(
                        title: const Text('Make Profile Discoverable'),
                        subtitle: const Text('Allow others to find your profile'),
                        value: settings['is_discoverable'] ?? true,
                        onChanged: _isLoading ? null : (value) => _updateSetting(
                          provider, 'is_discoverable', value
                        ),
                      ),
                      
                      SwitchListTile(
                        title: const Text('Allow Profile Views'),
                        subtitle: const Text('Let others view your profile details'),
                        value: settings['allow_profile_views'] ?? true,
                        onChanged: _isLoading ? null : (value) => _updateSetting(
                          provider, 'allow_profile_views', value
                        ),
                      ),
                      
                      SwitchListTile(
                        title: const Text('Show Completion Percentage'),
                        subtitle: const Text('Display your profile completion to others'),
                        value: settings['show_completion_percentage'] ?? true,
                        onChanged: _isLoading ? null : (value) => _updateSetting(
                          provider, 'show_completion_percentage', value
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Privacy Level',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      
                      RadioListTile<String>(
                        title: const Text('Public'),
                        subtitle: const Text('Anyone can view your profile'),
                        value: 'public',
                        groupValue: settings['privacy_level'] ?? 'public',
                        onChanged: _isLoading ? null : (value) => _updateSetting(
                          provider, 'privacy_level', value
                        ),
                      ),
                      
                      RadioListTile<String>(
                        title: const Text('Friends Only'),
                        subtitle: const Text('Only connections can view your profile'),
                        value: 'friends_only',
                        groupValue: settings['privacy_level'] ?? 'public',
                        onChanged: _isLoading ? null : (value) => _updateSetting(
                          provider, 'privacy_level', value
                        ),
                      ),
                      
                      RadioListTile<String>(
                        title: const Text('Private'),
                        subtitle: const Text('Profile not visible to others'),
                        value: 'private',
                        groupValue: settings['privacy_level'] ?? 'public',
                        onChanged: _isLoading ? null : (value) => _updateSetting(
                          provider, 'privacy_level', value
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Future<void> _updateSetting(
    UserInfoProvider provider,
    String setting,
    dynamic value,
  ) async {
    setState(() => _isLoading = true);
    
    try {
      final updates = <String, dynamic>{setting: value};
      await provider.updateDiscoverySettings(**updates);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
```

## Real-time Features

### 1. Profile Interaction Tracking

```dart
// lib/userinfo/interaction_tracker.dart
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class InteractionTracker {
  static final InteractionTracker _instance = InteractionTracker._internal();
  factory InteractionTracker() => _instance;
  InteractionTracker._internal();
  
  final SupabaseClient _client = Supabase.instance.client;
  Timer? _durationTimer;
  DateTime? _viewStartTime;
  String? _currentViewedUserId;
  
  // Start tracking profile view
  void startProfileView(String viewedUserId, {String? categoryName}) {
    _currentViewedUserId = viewedUserId;
    _viewStartTime = DateTime.now();
    
    // Record initial interaction
    _recordInteraction(
      viewedUserId: viewedUserId,
      interactionType: 'profile_view',
      categoryName: categoryName,
    );
  }
  
  // End tracking and record duration
  void endProfileView() {
    if (_currentViewedUserId != null && _viewStartTime != null) {
      final duration = DateTime.now().difference(_viewStartTime!).inSeconds;
      
      if (duration > 2) {  // Only record if viewed for more than 2 seconds
        _recordInteraction(
          viewedUserId: _currentViewedUserId!,
          interactionType: 'profile_view',
          viewDurationSeconds: duration,
        );
      }
    }
    
    _cleanup();
  }
  
  // Record category view
  void recordCategoryView(String viewedUserId, String categoryName) {
    _recordInteraction(
      viewedUserId: viewedUserId,
      interactionType: 'category_view',
      categoryName: categoryName,
    );
  }
  
  // Record search appearance
  void recordSearchAppearance(String viewedUserId) {
    _recordInteraction(
      viewedUserId: viewedUserId,
      interactionType: 'search',
    );
  }
  
  Future<void> _recordInteraction({
    required String viewedUserId,
    required String interactionType,
    String? categoryName,
    int? viewDurationSeconds,
  }) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null || currentUserId == viewedUserId) return;
    
    try {
      await _client.from('user_info_interactions').insert({
        'viewer_user_id': currentUserId,
        'viewed_user_id': viewedUserId,
        'interaction_type': interactionType,
        'category_name': categoryName,
        'view_duration_seconds': viewDurationSeconds,
      });
    } catch (e) {
      print('Error recording interaction: $e');
    }
  }
  
  void _cleanup() {
    _durationTimer?.cancel();
    _durationTimer = null;
    _viewStartTime = null;
    _currentViewedUserId = null;
  }
}
```

### 2. Real-time Notifications

```dart
// lib/services/realtime_notifications.dart
import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class RealtimeNotifications {
  static final RealtimeNotifications _instance = RealtimeNotifications._internal();
  factory RealtimeNotifications() => _instance;
  RealtimeNotifications._internal();
  
  final SupabaseClient _client = Supabase.instance.client;
  RealtimeChannel? _profileChannel;
  RealtimeChannel? _moderationChannel;
  
  final StreamController<Map<String, dynamic>> _profileInteractionsController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _moderationUpdatesController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get profileInteractions => _profileInteractionsController.stream;
  Stream<Map<String, dynamic>> get moderationUpdates => _moderationUpdatesController.stream;
  
  void initialize() {
    _setupProfileInteractions();
    _setupModerationUpdates();
  }
  
  void _setupProfileInteractions() {
    _profileChannel = _client.channel('user_profile_interactions')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'user_info_interactions',
        callback: (payload) {
          final data = payload.newRecord;
          if (data['viewed_user_id'] == _client.auth.currentUser?.id) {
            _profileInteractionsController.add({
              'type': 'profile_interaction',
              'data': data,
            });
          }
        },
      )
      ..subscribe();
  }
  
  void _setupModerationUpdates() {
    _moderationChannel = _client.channel('content_moderation_updates')
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'user_info_moderation',
        callback: (payload) {
          final data = payload.newRecord;
          _moderationUpdatesController.add({
            'type': 'moderation_update',
            'data': data,
          });
        },
      )
      ..subscribe();
  }
  
  void dispose() {
    _profileChannel?.unsubscribe();
    _moderationChannel?.unsubscribe();
    _profileInteractionsController.close();
    _moderationUpdatesController.close();
  }
}
```

## Analytics and Monitoring

### 1. Analytics Dashboard

```dart
// lib/admin/analytics_dashboard.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/supabase_config.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({Key? key}) : super(key: key);

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  Map<String, dynamic>? _analyticsData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final client = SupabaseConfig.client;
      
      // Get daily activity
      final dailyActivity = await client
          .from('daily_user_activity')
          .select('*')
          .order('activity_date', ascending: false)
          .limit(30);
      
      // Get category analytics
      final categoryAnalytics = await client
          .from('category_analytics')
          .select('*')
          .order('popularity_rank')
          .limit(10);
      
      // Get trending content
      final trending = await client
          .from('trending_content')
          .select('*')
          .limit(10);
      
      setState(() {
        _analyticsData = {
          'daily_activity': dailyActivity,
          'category_analytics': categoryAnalytics,
          'trending': trending,
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadAnalytics();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDailyActivityChart(),
            const SizedBox(height: 24),
            _buildCategoryPopularity(),
            const SizedBox(height: 24),
            _buildTrendingContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyActivityChart() {
    final dailyData = _analyticsData?['daily_activity'] as List<dynamic>? ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Active Users (Last 30 Days)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: dailyData.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          (entry.value['active_users'] ?? 0).toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPopularity() {
    final categories = _analyticsData?['category_analytics'] as List<dynamic>? ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Most Popular Categories',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...categories.take(5).map((category) {
              final name = category['display_name'] ?? 'Unknown';
              final users = category['unique_users'] ?? 0;
              final adoption = category['adoption_percentage'] ?? 0.0;
              
              return ListTile(
                leading: CircleAvatar(
                  child: Text('${category['popularity_rank'] ?? 0}'),
                ),
                title: Text(name),
                subtitle: Text('$users users'),
                trailing: Text('${adoption.toStringAsFixed(1)}%'),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingContent() {
    final trending = _analyticsData?['trending'] as List<dynamic>? ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trending Content',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...trending.map((item) {
              final name = item['item_name'] ?? 'Unknown';
              final score = item['trending_score'] ?? 0.0;
              final growth = item['growth_rate_7d'] ?? 0.0;
              
              return ListTile(
                title: Text(name),
                subtitle: Text('Growth: ${growth.toStringAsFixed(1)}%'),
                trailing: Chip(
                  label: Text(score.toStringAsFixed(1)),
                  backgroundColor: growth > 0 ? Colors.green[100] : Colors.grey[100],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
```

## Maintenance and Operations

### 1. Scheduled Maintenance

#### Setup Cron Jobs (Server-side)
```bash
# Add to server crontab
# Daily maintenance at 3 AM
0 3 * * * psql -d your_database -c "SELECT run_daily_maintenance();"

# Weekly maintenance on Sundays at 2 AM
0 2 * * 0 psql -d your_database -c "SELECT run_weekly_maintenance();"

# Refresh materialized views every 6 hours
0 */6 * * * psql -d your_database -c "SELECT refresh_daily_user_activity();"
```

#### Flutter Maintenance Service
```dart
// lib/services/maintenance_service.dart
import 'dart:async';
import '../config/supabase_config.dart';

class MaintenanceService {
  static final MaintenanceService _instance = MaintenanceService._internal();
  factory MaintenanceService() => _instance;
  MaintenanceService._internal();
  
  final SupabaseClient _client = SupabaseConfig.client;
  Timer? _maintenanceTimer;
  
  void startPeriodicMaintenance() {
    // Run maintenance checks every hour
    _maintenanceTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _runMaintenanceChecks(),
    );
  }
  
  Future<void> _runMaintenanceChecks() async {
    try {
      // Check for pending moderation items
      final pendingModeration = await _client
          .from('content_moderation_overview')
          .select('count', const FetchOptions(count: CountOption.exact))
          .eq('review_priority', 'high');
      
      // Trigger notifications if needed
      if (pendingModeration.count > 10) {
        _notifyAdmins('High priority moderation items: ${pendingModeration.count}');
      }
      
      // Check analytics health
      await _checkAnalyticsHealth();
      
    } catch (e) {
      print('Maintenance check error: $e');
    }
  }
  
  Future<void> _checkAnalyticsHealth() async {
    try {
      final today = DateTime.now();
      final todayAnalytics = await _client
          .from('user_info_analytics')
          .select('count', const FetchOptions(count: CountOption.exact))
          .eq('analysis_date', today.toIso8601String().split('T')[0]);
      
      if (todayAnalytics.count == 0) {
        print('Warning: No analytics data for today');
      }
    } catch (e) {
      print('Analytics health check error: $e');
    }
  }
  
  void _notifyAdmins(String message) {
    // Implement admin notification system
    print('ADMIN NOTIFICATION: $message');
  }
  
  void dispose() {
    _maintenanceTimer?.cancel();
  }
}
```

## Testing Guidelines

### 1. Database Testing

```sql
-- Test profile completion calculation
INSERT INTO user_info (user_id, category, content, info_type) VALUES
('test-user-id'::uuid, 'Role', 'Host', 'category'),
('test-user-id'::uuid, 'Pronouns', 'they/them', 'category'),
('test-user-id'::uuid, 'Age', '25', 'category');

-- Check completion calculation
SELECT * FROM user_profile_completion WHERE user_id = 'test-user-id'::uuid;

-- Test moderation system
INSERT INTO user_info (user_id, category, content, info_type) VALUES
('test-user-id'::uuid, 'Bio', 'Check out my website at https://scam.com', 'free_text');

-- Check moderation record
SELECT * FROM user_info_moderation WHERE user_info_id IN (
    SELECT id FROM user_info WHERE user_id = 'test-user-id'::uuid
);

-- Test rate limiting
SELECT check_user_rate_limit('test-user-id'::uuid, 'create_user_info');

-- Clean up test data
DELETE FROM user_info WHERE user_id = 'test-user-id'::uuid;
```

### 2. Flutter Testing

```dart
// test/userinfo/user_info_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:crystal_social/userinfo/user_info_service.dart';

void main() {
  group('UserInfoService', () {
    late UserInfoService service;
    
    setUp(() {
      service = UserInfoService();
    });
    
    test('should add user info with moderation', () async {
      const userId = 'test-user-id';
      const category = 'Role';
      const content = 'Test content';
      
      final result = await service.addUserInfo(
        userId: userId,
        category: category,
        content: content,
      );
      
      expect(result, isNotNull);
      expect(result!['user_id'], equals(userId));
      expect(result['category'], equals(category));
      expect(result['content'], equals(content));
    });
    
    test('should get user profile with completion data', () async {
      const userId = 'test-user-id';
      
      final result = await service.getUserProfileComplete(userId);
      
      expect(result, isNotNull);
      expect(result!['user_id'], equals(userId));
      expect(result['completion_percentage'], isA<double>());
    });
    
    test('should handle rate limiting', () async {
      const userId = 'test-user-id';
      
      // Try to add many items quickly (should hit rate limit)
      for (int i = 0; i < 25; i++) {
        try {
          await service.addUserInfo(
            userId: userId,
            category: 'Role',
            content: 'Content $i',
          );
        } catch (e) {
          expect(e.toString(), contains('Rate limit exceeded'));
          break;
        }
      }
    });
  });
}
```

## Troubleshooting

### Common Issues

#### 1. Profile Completion Not Updating
```sql
-- Check if triggers are enabled
SELECT tgname, tgenabled FROM pg_trigger WHERE tgname LIKE '%completion%';

-- Manually recalculate completion
SELECT update_profile_completion() 
FROM user_info WHERE user_id = 'your-user-id'::uuid LIMIT 1;
```

#### 2. Moderation Not Working
```sql
-- Check moderation records
SELECT * FROM user_info_moderation 
WHERE user_info_id IN (
    SELECT id FROM user_info WHERE created_at >= NOW() - INTERVAL '1 hour'
);

-- Test moderation function
SELECT check_content_moderation_required('Test content with https://example.com');
```

#### 3. Analytics Missing
```sql
-- Check analytics data
SELECT * FROM user_info_analytics 
WHERE analysis_date = CURRENT_DATE;

-- Manually refresh analytics
SELECT refresh_daily_user_activity();
```

#### 4. Rate Limiting Issues
```sql
-- Check rate limit function
SELECT check_user_rate_limit('user-id'::uuid, 'create_user_info');

-- View recent user activity
SELECT COUNT(*), MAX(created_at) 
FROM user_info 
WHERE user_id = 'user-id'::uuid 
AND created_at >= NOW() - INTERVAL '1 hour';
```

### Performance Optimization

#### Database Optimization
```sql
-- Add additional indexes if needed
CREATE INDEX IF NOT EXISTS idx_user_info_user_category 
ON user_info(user_id, category);

CREATE INDEX IF NOT EXISTS idx_interactions_viewed_user_date 
ON user_info_interactions(viewed_user_id, DATE(created_at));

-- Analyze table statistics
ANALYZE user_info;
ANALYZE user_info_interactions;
ANALYZE user_info_analytics;
```

#### Flutter Optimization
```dart
// Use pagination for large lists
Future<List<Map<String, dynamic>>> getDiscoverableUsersPaginated({
  int page = 0,
  int pageSize = 20,
}) async {
  final offset = page * pageSize;
  return await service.getDiscoverableUsers(
    limit: pageSize,
    offset: offset,
  );
}

// Cache frequently accessed data
class UserInfoCache {
  static final Map<String, Map<String, dynamic>> _profileCache = {};
  static const Duration cacheTimeout = Duration(minutes: 5);
  
  static Map<String, dynamic>? getCachedProfile(String userId) {
    final cached = _profileCache[userId];
    if (cached != null) {
      final cacheTime = DateTime.parse(cached['_cache_time']);
      if (DateTime.now().difference(cacheTime) < cacheTimeout) {
        return cached;
      }
    }
    return null;
  }
  
  static void cacheProfile(String userId, Map<String, dynamic> profile) {
    profile['_cache_time'] = DateTime.now().toIso8601String();
    _profileCache[userId] = profile;
  }
}
```

## Conclusion

This integration guide provides a comprehensive foundation for implementing the UserInfo SQL system in Crystal Social. The system includes:

- **Complete Database Schema** with 17 specialized categories
- **Automated Profile Completion Tracking** and quality scoring
- **Content Moderation System** with automated analysis
- **Discovery and Privacy Controls** for user visibility
- **Real-time Analytics** and engagement tracking
- **Security Policies** and GDPR compliance
- **Performance Optimization** and maintenance procedures

Follow the integration steps in order, test thoroughly, and monitor the system health using the provided analytics and maintenance tools. The modular design allows for gradual implementation and easy customization based on specific requirements.

For additional support or questions, refer to the SQL file comments and function documentation within each file.
