# Crystal Social Main Application System - SQL Integration Documentation
## File: 06_main_app_integration_documentation.md

### Overview
This documentation provides comprehensive information about the SQL integration for the Crystal Social main application system, covering app state management, device tracking, connectivity monitoring, push notifications, DID system integration, and error handling.

### Architecture Summary
The main application system is built around the core `main.dart` file (1628 lines) which implements:
- Advanced app state management using Riverpod
- Multi-user device tracking with smart auto-logout
- Comprehensive connectivity monitoring
- Push notification system (Firebase + OneSignal)
- DID system fronting changes with real-time notifications
- Theme management with 8 color schemes
- Error handling and reporting system
- App lifecycle management
- Device security and session management
- Background message processing
- Animated splash screen with progress indicators

### Database Schema Files

#### 1. Core Tables (`01_main_app_core_tables.sql`)
**Purpose**: Foundation database schema for main application system

**Key Tables**:
- `app_states`: Central app state management with connectivity, theme, and error tracking
- `app_configurations`: Global app configurations and settings
- `connectivity_logs`: Network connectivity monitoring and logging
- `app_lifecycle_events`: Comprehensive event tracking for app lifecycle
- `user_sessions`: Session management with auto-logout and timeout controls
- `user_devices`: Device registration and management with FCM tokens
- `multi_user_devices`: Shared device tracking and management
- `device_user_history`: Historical device usage tracking
- `app_initialization_logs`: App startup performance monitoring
- `fronting_changes`: DID system fronting alter tracking with notifications
- `background_messages`: Push notification and background message processing
- `push_notification_analytics`: Notification performance tracking
- `error_reports`: Comprehensive error tracking and reporting

**Features**:
- UUID primary keys for all tables
- Comprehensive indexing for performance
- User ID foreign key relationships
- Audit timestamps on all tables
- JSON metadata fields for flexibility

#### 2. Business Logic (`02_main_app_business_logic.sql`)
**Purpose**: Core business logic functions for app operations

**Key Functions**:
- `initialize_app_state()`: Initialize app state for new user sessions
- `update_app_state()`: Update app state with connectivity and theme changes
- `register_user_device()`: Register new user devices with security validation
- `track_multi_user_device()`: Track devices shared between multiple users
- `create_user_session()`: Create new user sessions with timeout management
- `log_connectivity_change()`: Log network connectivity changes
- `record_fronting_change()`: Record DID system alter changes
- `report_app_error()`: Report and categorize application errors
- `process_background_message()`: Process push notifications and background messages
- `end_user_session()`: End user sessions with cleanup and logging
- `get_active_fronting_alter()`: Get current fronting alter for DID system
- `check_device_security()`: Validate device security and detect violations
- `cleanup_old_sessions()`: Clean up expired and old sessions
- `sync_user_preferences()`: Sync user preferences across devices

**Business Rules**:
- Automatic session timeout handling
- Multi-user device detection and management
- Security violation tracking and alerting
- Comprehensive error categorization and reporting
- Real-time fronting change notifications

#### 3. Views and Analytics (`03_main_app_views_analytics.sql`)
**Purpose**: Analytics views and reporting for app performance monitoring

**Key Views**:
- `app_states_overview`: Current app states with user and device information
- `user_session_analytics`: Session duration, activity patterns, and usage metrics
- `connectivity_quality_overview`: Network connectivity quality and reliability metrics
- `error_reports_summary`: Error frequency, types, and resolution tracking
- `fronting_changes_analytics`: DID system usage patterns and statistics
- `push_notification_performance`: Notification delivery and engagement metrics
- `app_health_dashboard`: Overall app health and performance indicators
- `platform_usage_distribution`: Usage distribution across platforms and devices

**Analytics Features**:
- Real-time app performance monitoring
- User engagement and retention metrics
- Error tracking and resolution monitoring
- Network connectivity quality assessment
- Device and platform usage analytics
- DID system usage patterns
- Push notification effectiveness tracking

#### 4. Security Policies (`04_main_app_security_policies.sql`)
**Purpose**: Row Level Security (RLS) policies and security functions

**Security Features**:
- Row Level Security on all tables
- User-based data isolation
- Device security validation
- Session security monitoring
- API rate limiting
- Security audit logging
- GDPR compliance functions

**Key Policies**:
- Users can only access their own app states and sessions
- Device registration requires valid authentication
- Error reports are user-isolated with admin override
- Fronting changes are user-specific with system verification
- Background messages are user-scoped with processing controls

**Security Functions**:
- `validate_device_security()`: Comprehensive device security validation
- `validate_session_security()`: Session security and timeout validation
- `check_api_rate_limit()`: API rate limiting and abuse prevention
- `log_main_app_security_event()`: Security event logging and monitoring
- `anonymize_user_data()`: GDPR-compliant data anonymization
- `export_user_data()`: GDPR data export functionality

#### 5. Triggers and Automation (`05_main_app_triggers_automation.sql`)
**Purpose**: Database triggers and automated processes

**Key Triggers**:
- `app_state_change_trigger`: Handles app state changes and real-time notifications
- `user_device_trigger`: Manages device registration and multi-user tracking
- `user_session_trigger`: Handles session lifecycle and security monitoring
- `fronting_changes_trigger`: Processes fronting changes and notifications
- `error_reports_trigger`: Manages error reporting and alerting
- `background_messages_trigger`: Handles background message processing

**Automation Features**:
- Real-time notifications via pg_notify
- Automatic session timeout handling
- Error spike detection and alerting
- Multi-user device tracking updates
- Automated data cleanup and maintenance
- Daily metrics calculation and refresh

**Maintenance Functions**:
- `automated_cleanup()`: Daily cleanup of old data
- `handle_session_timeouts()`: Session timeout management
- `update_daily_metrics()`: Daily metrics calculation
- `send_realtime_notification()`: Real-time notification system

### Integration Points

#### Flutter App Integration
```dart
// App State Management
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});

// Device Registration
await DatabaseService.registerDevice(
  userId: user.id,
  deviceId: deviceInfo.id,
  platform: Platform.operatingSystem,
  fcmToken: fcmToken,
);

// Session Management
final session = await DatabaseService.createSession(
  userId: user.id,
  deviceId: deviceInfo.id,
  autoLogoutEnabled: true,
);

// Fronting Changes (DID System)
await DatabaseService.recordFrontingChange(
  userId: user.id,
  alterName: newAlter,
  previousAlter: currentAlter,
  changeType: 'manual',
);
```

#### Supabase Configuration
```sql
-- Enable realtime for key tables
ALTER publication supabase_realtime ADD TABLE app_states;
ALTER publication supabase_realtime ADD TABLE fronting_changes;
ALTER publication supabase_realtime ADD TABLE user_sessions;
ALTER publication supabase_realtime ADD TABLE background_messages;
```

#### Push Notification Setup
```javascript
// Firebase Cloud Functions integration
exports.processBackgroundMessage = functions.database.ref('/background_messages/{messageId}')
  .onCreate(async (snapshot, context) => {
    const message = snapshot.val();
    // Process notification based on message_type
    return sendPushNotification(message);
  });
```

### Performance Considerations

#### Indexing Strategy
- Primary keys on all tables (UUID)
- Foreign key indexes for relationships
- Composite indexes for common query patterns
- JSON indexes for metadata searches
- Time-based indexes for analytics queries

#### Query Optimization
- Use views for complex analytical queries
- Implement pagination for large result sets
- Cache frequently accessed configuration data
- Use materialized views for heavy analytics

#### Monitoring and Alerting
- Error spike detection (10+ errors in 10 minutes)
- Session timeout monitoring
- Device security violation tracking
- Performance metric thresholds
- Real-time notification system health

### Security Considerations

#### Data Protection
- Row Level Security on all tables
- User data isolation
- Device fingerprinting protection
- Session security validation
- Encrypted sensitive data storage

#### Privacy Compliance
- GDPR data export functionality
- User data anonymization
- Consent tracking
- Data retention policies
- Right to be forgotten implementation

#### Access Control
- Authentication required for all operations
- Role-based access control
- API rate limiting
- Security audit logging
- Suspicious activity detection

### Deployment Instructions

#### 1. Database Setup
```sql
-- Run files in order:
\i 01_main_app_core_tables.sql
\i 02_main_app_business_logic.sql
\i 03_main_app_views_analytics.sql
\i 04_main_app_security_policies.sql
\i 05_main_app_triggers_automation.sql
```

#### 2. Supabase Configuration
- Enable Row Level Security
- Configure realtime subscriptions
- Set up edge functions for background processing
- Configure storage policies

#### 3. Application Configuration
- Update database connection strings
- Configure push notification credentials
- Set up error reporting services
- Initialize app configuration values

#### 4. Monitoring Setup
- Configure database performance monitoring
- Set up error alerting
- Enable security event logging
- Configure backup and recovery

### Testing Strategy

#### Unit Tests
- Test all business logic functions
- Validate security policies
- Test trigger functionality
- Verify constraint enforcement

#### Integration Tests
- Test Flutter app database integration
- Validate real-time subscription functionality
- Test push notification delivery
- Verify session management

#### Performance Tests
- Load test with multiple concurrent users
- Test query performance under load
- Validate trigger performance
- Test cleanup and maintenance functions

#### Security Tests
- Test RLS policy enforcement
- Validate authentication requirements
- Test rate limiting functionality
- Verify data isolation

### Maintenance Procedures

#### Daily Maintenance
- Automated cleanup of old data
- Daily metrics calculation
- Session timeout processing
- Error report analysis

#### Weekly Maintenance
- Performance metric review
- Security audit log review
- Database health monitoring
- Backup verification

#### Monthly Maintenance
- Comprehensive performance analysis
- Security policy review
- Data retention policy enforcement
- System optimization

### Troubleshooting Guide

#### Common Issues
1. **Session Timeout Problems**: Check inactivity timeout settings
2. **Device Registration Failures**: Verify FCM token validity
3. **Fronting Change Notifications**: Check realtime subscription status
4. **Error Spike Alerts**: Review error categorization and thresholds
5. **Performance Issues**: Analyze query execution plans and indexes

#### Debugging Tools
- Enable query logging for performance analysis
- Use database monitoring tools
- Check trigger execution logs
- Monitor real-time subscription health
- Review error categorization accuracy

### API Documentation

#### Core Endpoints
- `/api/app-state`: App state management
- `/api/devices`: Device registration and management
- `/api/sessions`: Session lifecycle management
- `/api/fronting`: DID system fronting changes
- `/api/errors`: Error reporting and tracking
- `/api/notifications`: Push notification management

#### Real-time Channels
- `app_state_changes`: App state updates
- `fronting_changes`: DID system alter changes
- `user_sessions`: Session lifecycle events
- `critical_errors`: Critical error alerts
- `background_message_queue`: Message processing queue

### Future Enhancements

#### Planned Features
- Advanced analytics dashboard
- Machine learning-based error prediction
- Enhanced device security scoring
- Automated performance optimization
- Advanced DID system features

#### Scalability Considerations
- Database sharding strategies
- Read replica implementation
- Caching layer optimization
- Queue-based message processing
- Microservices architecture migration

---

**Implementation Status**: ✅ Complete
**Last Updated**: [Current Date]
**Maintainer**: Crystal Social Development Team
**Version**: 1.0.0
