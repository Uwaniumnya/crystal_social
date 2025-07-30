/// Production-ready widget exports for Crystal Social
/// This file provides conditional exports for debug and production builds
library widgets_exports;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Core UI widgets - always available
export 'message_bubble.dart';
export 'emoticon_picker.dart';
export 'background_picker.dart';
export 'sticker_picker.dart';
export 'glimmer_upload_sheet.dart';
export 'coin_earning_widgets.dart';

// Data management widgets - always available
export 'local_user_store.dart';
export 'message_analyzer.dart';

// Debug widgets - only available in debug mode
export 'push_notification_test_widget.dart' show 
  PushNotificationTestButton;
export 'device_user_tracking_debug_widget.dart' show 
  DeviceUserTrackingDebugWidget;

/// Helper to conditionally show debug widgets
/// Returns the widget only in debug mode, otherwise returns empty space
Widget debugOnly(Widget Function() builder) {
  if (kDebugMode) {
    return builder();
  }
  return const SizedBox.shrink();
}

/// Helper to conditionally show production widgets  
/// Returns the widget only in release mode, otherwise returns empty space
Widget releaseOnly(Widget Function() builder) {
  if (kReleaseMode) {
    return builder();
  }
  return const SizedBox.shrink();
}

/// Production-safe debug print that only logs in debug mode
void safePrint(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

/// Production-safe assert that only runs in debug mode
void safeAssert(bool condition, [String? message]) {
  if (kDebugMode) {
    assert(condition, message);
  }
}
