# Admin System SQL Integration

This folder contains SQL files for setting up the complete admin system for Crystal Social. These files should be executed in order to set up all admin-related functionality.

## Files Overview

### 01_support_requests.sql
- **Support ticket system** with full lifecycle management
- **Support categories** and FAQ system
- **File attachments** for support requests
- **Request updates** and history tracking
- **RLS policies** for secure access control

**Key Tables:**
- `support_requests` - Main support tickets
- `support_request_updates` - Change history
- `support_categories` - Configurable categories
- `support_attachments` - File uploads
- `support_faq` - Knowledge base

### 02_admin_user_management.sql
- **Admin roles** and permissions system
- **User moderation actions** (bans, warnings, etc.)
- **User reports** from community
- **Admin statistics** dashboard
- **Activity logging** for audit trails

**Key Tables:**
- `admin_roles` - Role definitions
- `admin_user_roles` - User role assignments
- `user_moderation_actions` - Moderation history
- `user_reports` - Community reports
- `admin_statistics` - Daily metrics

### 03_audit_logs.sql
- **Admin action logging** for complete audit trail
- **System event monitoring** 
- **Security event tracking**
- **Performance metrics** collection
- **Alert system** for automated monitoring

**Key Tables:**
- `admin_action_logs` - All admin actions
- `system_event_logs` - System events
- `security_logs` - Security-related events
- `admin_sessions` - Session tracking
- `admin_alerts` - Automated alerts

### 04_content_moderation.sql
- **Automated content filtering** with configurable rules
- **Moderation queue** for review workflow
- **AI content analysis** integration ready
- **Appeal system** for contested decisions
- **Community moderation** support

**Key Tables:**
- `moderation_rules` - Automated rules
- `content_moderation_queue` - Items awaiting review
- `content_analysis` - AI analysis results
- `content_appeals` - User appeals
- `moderation_statistics` - Performance metrics

### 05_admin_setup.sql
- **System configuration** management
- **Quick actions** for common admin tasks
- **Dashboard widgets** customization
- **Health monitoring** system
- **Initial setup** and utilities

**Key Tables:**
- `admin_config` - System settings
- `admin_quick_actions` - Shortcut actions
- `admin_dashboard_widgets` - Custom dashboards
- `system_health_checks` - Monitoring

## Installation Instructions

1. **Execute files in order** (01 through 05)
2. **Set up first admin user:**
   ```sql
   SELECT make_user_admin('your-user-uuid-here');
   ```
3. **Configure system settings** as needed
4. **Test health checks:**
   ```sql
   SELECT run_health_check(id) FROM system_health_checks;
   ```

## Key Features

### 🎫 Support System
- Multi-category support tickets
- File attachment support
- Admin response system
- Automatic status tracking
- FAQ knowledge base

### 👥 User Management
- Role-based permissions
- User moderation tools
- Community reporting
- Activity tracking
- Statistical insights

### 🔍 Content Moderation
- Automated content filtering
- AI-ready analysis framework
- Manual review workflow
- Appeal system
- Performance metrics

### 📊 Monitoring & Analytics
- Complete audit trails
- Real-time alerts
- Performance monitoring
- Security event tracking
- Custom dashboards

### ⚙️ System Administration
- Configuration management
- Health monitoring
- Quick action shortcuts
- Backup management
- Maintenance tools

## Security Features

- **Row Level Security (RLS)** on all tables
- **Admin-only access** to sensitive data
- **Audit logging** for all actions
- **Session management** with timeouts
- **Permission-based** function access

## Integration with Flutter App

The SQL schema is designed to work with the existing Flutter admin components:

- `lib/admin/admin_access.dart` - Quick admin access widget
- `lib/admin/support_dashboard.dart` - Support ticket management

### Required Profile Columns
The setup automatically adds these columns to the `profiles` table:
- `is_admin` - Boolean flag for admin users
- `is_moderator` - Boolean flag for moderators
- `admin_notes` - Internal admin notes
- `last_admin_action` - Timestamp of last admin activity

## Functions Reference

### Configuration
- `get_admin_config(key)` - Get configuration value
- `set_admin_config(key, value, admin_id)` - Set configuration value

### User Management
- `make_user_admin(user_id)` - Promote user to admin
- `check_admin_permission(user_id, permission_path)` - Check permissions
- `get_user_admin_permissions(user_id)` - Get all permissions

### Logging
- `log_admin_action(...)` - Log admin actions
- `log_system_event(...)` - Log system events
- `log_security_event(...)` - Log security events
- `log_user_activity(...)` - Log user activity

### Moderation
- `check_content_moderation(...)` - Check content against rules
- `process_moderation_action(...)` - Process moderation decisions

### Health & Monitoring
- `run_health_check(check_id)` - Execute health check
- `update_daily_admin_statistics()` - Update daily stats
- `get_admin_dashboard_summary()` - Get dashboard overview

## Customization

The system is highly configurable:

1. **Moderation Rules** - Add custom content filtering rules
2. **Admin Roles** - Define custom permission sets
3. **Quick Actions** - Add custom admin shortcuts
4. **Health Checks** - Monitor custom metrics
5. **Dashboard Widgets** - Create custom admin views

## Maintenance

Regular maintenance tasks:
- Run `cleanup_old_logs()` to manage log retention
- Execute `update_daily_admin_statistics()` for analytics
- Monitor `system_health_checks` for system status
- Review `admin_alerts` for system issues

## Support

For questions about this admin system integration:
1. Check the function documentation in each SQL file
2. Review the RLS policies for access control
3. Examine the trigger functions for automated behaviors
4. Test with the provided health check functions
