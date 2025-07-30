import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';

/// Device Registration Service
/// Tracks all devices where users have ever logged in
/// Enables sending notifications to all user devices even when not logged in
class DeviceRegistrationService {
  static DeviceRegistrationService? _instance;
  static DeviceRegistrationService get instance {
    _instance ??= DeviceRegistrationService._internal();
    return _instance!;
  }

  DeviceRegistrationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Register the current device for a user
  Future<void> registerDevice(String userId) async {
    try {
      // Get FCM token
      final fcmToken = await _messaging.getToken();
      if (fcmToken == null) {
        debugPrint('❌ Could not get FCM token');
        return;
      }

      // Get device information
      final deviceInfo = await _getDeviceInfo();
      final deviceId = await _getOrCreateDeviceId();

      // Check if this device is already registered for this user
      final existingRegistration = await _supabase
          .from('user_devices')
          .select('id, fcm_token, is_active')
          .eq('user_id', userId)
          .eq('device_id', deviceId)
          .maybeSingle();

      final now = DateTime.now().toIso8601String();

      if (existingRegistration != null) {
        // Update existing registration
        await _supabase.from('user_devices').update({
          'fcm_token': fcmToken,
          'device_info': deviceInfo,
          'is_active': true,
          'last_active': now,
          'updated_at': now,
        }).eq('id', existingRegistration['id']);
        
        debugPrint('✅ Updated device registration for user $userId');
      } else {
        // Create new registration
        await _supabase.from('user_devices').insert({
          'user_id': userId,
          'device_id': deviceId,
          'fcm_token': fcmToken,
          'device_info': deviceInfo,
          'is_active': true,
          'first_login': now,
          'last_active': now,
          'created_at': now,
          'updated_at': now,
        });
        
        debugPrint('✅ Registered new device for user $userId');
      }

      // Store device registration locally
      await _storeLocalDeviceInfo(userId, deviceId, fcmToken);
      
    } catch (e) {
      debugPrint('❌ Failed to register device: $e');
    }
  }

  /// Deactivate device registration when user logs out
  Future<void> deactivateDevice(String userId) async {
    try {
      final deviceId = await _getOrCreateDeviceId();
      
      await _supabase.from('user_devices').update({
        'is_active': false,
        'last_active': DateTime.now().toIso8601String(),
      }).eq('user_id', userId).eq('device_id', deviceId);
      
      debugPrint('✅ Deactivated device for user $userId');
    } catch (e) {
      debugPrint('❌ Failed to deactivate device: $e');
    }
  }

  /// Get all active devices for a user
  Future<List<Map<String, dynamic>>> getUserDevices(String userId) async {
    try {
      final response = await _supabase
          .from('user_devices')
          .select('*')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('last_active', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Failed to get user devices: $e');
      return [];
    }
  }

  /// Update FCM token for current device
  Future<void> updateFcmToken(String userId, String newToken) async {
    try {
      final deviceId = await _getOrCreateDeviceId();
      
      await _supabase.from('user_devices').update({
        'fcm_token': newToken,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId).eq('device_id', deviceId);
      
      debugPrint('✅ Updated FCM token for user $userId');
    } catch (e) {
      debugPrint('❌ Failed to update FCM token: $e');
    }
  }

  /// Clean up old/inactive devices
  Future<void> cleanupOldDevices() async {
    try {
      // Remove devices that haven't been active for 90 days
      final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
      
      await _supabase
          .from('user_devices')
          .delete()
          .lt('last_active', cutoffDate.toIso8601String());
      
      debugPrint('✅ Cleaned up old devices');
    } catch (e) {
      debugPrint('❌ Failed to cleanup old devices: $e');
    }
  }

  /// Get device information
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        return {
          'platform': 'Android',
          'model': 'Android Device',
          'manufacturer': 'Unknown',
          'version': 'Unknown',
          'device': 'android_device',
        };
      } else if (Platform.isIOS) {
        return {
          'platform': 'iOS',
          'model': 'iOS Device',
          'name': 'iPhone/iPad',
          'system_name': 'iOS',
          'system_version': 'Unknown',
        };
      } else {
        return {
          'platform': 'Unknown',
          'model': 'Unknown',
        };
      }
    } catch (e) {
      debugPrint('❌ Failed to get device info: $e');
      return {
        'platform': 'Unknown',
        'model': 'Unknown',
        'error': e.toString(),
      };
    }
  }

  /// Get or create a unique device ID
  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('crystal_device_id');
    
    if (deviceId == null) {
      // Generate a new device ID
      deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 10000).toString().padLeft(4, '0')}';
      await prefs.setString('crystal_device_id', deviceId);
    }
    
    return deviceId;
  }

  /// Store device information locally
  Future<void> _storeLocalDeviceInfo(String userId, String deviceId, String fcmToken) async {
    final prefs = await SharedPreferences.getInstance();
    
    final deviceInfo = {
      'user_id': userId,
      'device_id': deviceId,
      'fcm_token': fcmToken,
      'registered_at': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString('crystal_device_registration', jsonEncode(deviceInfo));
  }

  /// Get locally stored device information
  Future<Map<String, dynamic>?> getLocalDeviceInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceInfoString = prefs.getString('crystal_device_registration');
      
      if (deviceInfoString != null) {
        return jsonDecode(deviceInfoString);
      }
    } catch (e) {
      debugPrint('❌ Failed to get local device info: $e');
    }
    
    return null;
  }

  /// Initialize device registration service
  Future<void> initialize() async {
    try {
      // Listen for FCM token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('📱 FCM token refreshed: $newToken');
        
        // Get current user and update token
        final user = _supabase.auth.currentUser;
        if (user != null) {
          await updateFcmToken(user.id, newToken);
        }
      });

      debugPrint('✅ Device Registration Service initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize Device Registration Service: $e');
    }
  }

  /// Check if user has devices registered
  Future<bool> hasRegisteredDevices(String userId) async {
    try {
      final response = await _supabase
          .from('user_devices')
          .select('id')
          .eq('user_id', userId)
          .eq('is_active', true)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Failed to check registered devices: $e');
      return false;
    }
  }

  /// Get device count for user
  Future<int> getDeviceCount(String userId) async {
    try {
      final response = await _supabase
          .from('user_devices')
          .select('id')
          .eq('user_id', userId)
          .eq('is_active', true);

      return response.length;
    } catch (e) {
      debugPrint('❌ Failed to get device count: $e');
      return 0;
    }
  }

  /// Get all users who have ever logged in on this device
  Future<List<String>> getUsersOnThisDevice() async {
    try {
      final deviceId = await _getOrCreateDeviceId();
      
      final response = await _supabase
          .from('user_devices')
          .select('user_id')
          .eq('device_id', deviceId)
          .eq('is_active', true);

      return response.map<String>((device) => device['user_id'] as String).toList();
    } catch (e) {
      debugPrint('❌ Failed to get users on this device: $e');
      return [];
    }
  }
}
