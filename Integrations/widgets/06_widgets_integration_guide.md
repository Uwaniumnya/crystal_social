# Crystal Social Widgets System Integration Guide

## Overview
This guide provides comprehensive instructions for integrating the Crystal Social Widgets System SQL schema into your PostgreSQL/Supabase database. The widgets system provides advanced UI components including sticker management, emoticon creation, background customization, message effects, analytics tracking, and performance optimization.

## Prerequisites
- PostgreSQL 13+ or Supabase project
- Row Level Security (RLS) enabled
- Authentication system in place (Supabase Auth recommended)
- Required extensions: `uuid-ossp`, `pgcrypto`

## Files Overview

### 1. Core Database Schema
**File: `01_widgets_core_tables.sql`**
- Creates 20+ core tables for widget system
- Includes sticker management, emoticon system, backgrounds, messages
- Sets up analytics and performance tracking infrastructure

### 2. Business Logic Functions
**File: `02_widgets_business_logic.sql`**
- 25+ functions for widget operations
- Handles sticker approval, emoticon creation, background management
- Includes advanced features like batch operations and smart recommendations

### 3. Analytics and Views
**File: `03_widgets_views_analytics.sql`**
- Comprehensive analytics views for usage tracking
- Performance monitoring and optimization insights
- Popular content and user behavior analysis

### 4. Security Policies
**File: `04_widgets_security_policies.sql`**
- Row Level Security (RLS) policies for all tables
- User permission management and rate limiting
- Content moderation and security monitoring

### 5. Triggers and Automation
**File: `05_widgets_triggers_automation.sql`**
- Database triggers for lifecycle management
- Automated cache invalidation and cleanup
- Performance tracking and error handling

## Installation Steps

### Step 1: Install Required Extensions
```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
```

### Step 2: Execute SQL Files in Order
Execute the SQL files in the following order:

1. **Core Tables**
   ```bash
   psql -d your_database < 01_widgets_core_tables.sql
   ```

2. **Business Logic**
   ```bash
   psql -d your_database < 02_widgets_business_logic.sql
   ```

3. **Analytics Views**
   ```bash
   psql -d your_database < 03_widgets_views_analytics.sql
   ```

4. **Security Policies**
   ```bash
   psql -d your_database < 04_widgets_security_policies.sql
   ```

5. **Triggers and Automation**
   ```bash
   psql -d your_database < 05_widgets_triggers_automation.sql
   ```

### Step 3: Verify Installation
Run this query to verify all tables are created:
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE '%sticker%' 
   OR table_name LIKE '%emoticon%' 
   OR table_name LIKE '%background%' 
   OR table_name LIKE '%widget%'
   OR table_name LIKE '%glimmer%';
```

## Configuration

### Environment Variables
Set these in your application environment:

```env
# Widget System Configuration
WIDGET_STICKER_MAX_SIZE=5MB
WIDGET_EMOTICON_MAX_COUNT=100
WIDGET_CACHE_TTL=3600
WIDGET_ANALYTICS_ENABLED=true
WIDGET_MODERATION_AUTO_APPROVE=false

# File Storage (for Supabase)
SUPABASE_STORAGE_BUCKET_STICKERS=widget-stickers
SUPABASE_STORAGE_BUCKET_BACKGROUNDS=chat-backgrounds
SUPABASE_STORAGE_BUCKET_EMOTICONS=custom-emoticons
```

### User Roles Setup
Configure user roles in your auth system:

```sql
-- Add user roles to auth.users metadata
UPDATE auth.users 
SET raw_user_meta_data = raw_user_meta_data || '{"role": "user"}'
WHERE raw_user_meta_data->>'role' IS NULL;

-- Create admin users (example)
UPDATE auth.users 
SET raw_user_meta_data = raw_user_meta_data || '{"role": "admin"}'
WHERE email = 'admin@crystalsocial.com';

-- Create moderator users (example)
UPDATE auth.users 
SET raw_user_meta_data = raw_user_meta_data || '{"role": "moderator"}'
WHERE email IN ('mod1@crystalsocial.com', 'mod2@crystalsocial.com');
```

## Flutter Integration

### 1. Required Dependencies
Add to your `pubspec.yaml`:
```yaml
dependencies:
  supabase_flutter: ^2.0.0
  cached_network_image: ^3.3.0
  image_picker: ^1.0.4
  file_picker: ^6.1.1
  path_provider: ^2.1.1
  sqflite: ^2.3.0
  hive: ^2.2.3
  animations: ^2.0.8
```

### 2. Initialize Widget System
```dart
// In your main.dart or widget initialization
await WidgetSystem.initialize(
  supabaseClient: Supabase.instance.client,
  cacheEnabled: true,
  analyticsEnabled: true,
);
```

### 3. Core Widget Usage Examples

#### Sticker Picker Widget
```dart
StickerPicker(
  onStickerSelected: (sticker) {
    // Handle sticker selection
    print('Selected sticker: ${sticker.name}');
  },
  categories: ['popular', 'recent', 'favorites'],
  enableSearch: true,
  enableGifSupport: true,
)
```

#### Emoticon Picker Widget
```dart
EmoticonPicker(
  onEmoticonSelected: (emoticon) {
    // Handle emoticon selection
    print('Selected emoticon: ${emoticon.unicode}');
  },
  enableCustomCreation: true,
  showFavorites: true,
  categories: EmoticonCategory.values,
)
```

#### Background Picker Widget
```dart
BackgroundPicker(
  currentBackgroundId: chatBackgroundId,
  onBackgroundSelected: (background) {
    // Apply background to chat
    ChatService.setBackground(chatId, background.id);
  },
  enableCustomBackgrounds: true,
  showPresets: true,
)
```

## API Usage Examples

### Sticker Management
```dart
// Get user's stickers
final stickers = await WidgetService.getUserStickers(userId);

// Upload new sticker
final sticker = await WidgetService.uploadSticker(
  userId: userId,
  file: imageFile,
  name: 'My Sticker',
  category: 'custom',
  isPublic: false,
);

// Get popular stickers
final popularStickers = await WidgetService.getPopularStickers(
  category: 'all',
  limit: 20,
);
```

### Emoticon System
```dart
// Create custom emoticon
final emoticon = await WidgetService.createCustomEmoticon(
  userId: userId,
  unicode: '😀',
  name: 'Happy Face',
  categoryId: categoryId,
  isPublic: true,
);

// Get user's favorite emoticons
final favorites = await WidgetService.getFavoriteEmoticons(userId);

// Track emoticon usage
await WidgetService.trackEmoticonUsage(userId, emoticonId);
```

### Message Effects
```dart
// Send message with effects
final message = await MessageService.sendMessage(
  chatId: chatId,
  content: 'Hello!',
  effects: {
    'animation': 'bounce',
    'color': '#FF6B6B',
    'duration': 2000,
  },
);

// Add reaction to message
await MessageService.addReaction(
  messageId: messageId,
  userId: userId,
  reactionType: 'heart',
  customEmoticonId: emoticonId,
);
```

### Analytics Integration
```dart
// Track widget usage
await AnalyticsService.trackWidgetUsage(
  userId: userId,
  widgetType: 'sticker_picker',
  actionType: 'sticker_selected',
  metadata: {
    'sticker_id': stickerId,
    'category': category,
    'source': 'search',
  },
);

// Get user widget analytics
final analytics = await AnalyticsService.getUserWidgetAnalytics(
  userId: userId,
  timeRange: Duration(days: 30),
);
```

## Database Maintenance

### Daily Maintenance Script
Set up a cron job to run daily maintenance:

```sql
-- Run daily maintenance (add to cron)
SELECT daily_widget_maintenance();
```

### Manual Cleanup Commands
```sql
-- Clean expired cache
SELECT cleanup_expired_cache();

-- Aggregate yesterday's statistics
SELECT aggregate_daily_widget_stats();

-- Optimize cache based on usage
SELECT optimize_widget_cache();

-- Clean old analytics (older than 90 days)
DELETE FROM widget_usage_analytics 
WHERE usage_timestamp < NOW() - INTERVAL '90 days';
```

## Performance Optimization

### 1. Database Indexes
Key indexes are automatically created, but monitor these for performance:
```sql
-- Check index usage
SELECT schemaname, tablename, indexname, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
AND (tablename LIKE '%widget%' OR tablename LIKE '%sticker%');
```

### 2. Cache Strategy
- Enable Redis/Memcached for frequently accessed data
- Use local caching for user preferences
- Implement CDN for static assets (stickers, backgrounds)

### 3. Monitoring Queries
```sql
-- Top used widgets
SELECT widget_type, COUNT(*) as usage_count
FROM widget_usage_analytics
WHERE usage_timestamp >= NOW() - INTERVAL '24 hours'
GROUP BY widget_type
ORDER BY usage_count DESC;

-- Performance metrics
SELECT * FROM widget_performance_summary
WHERE date >= CURRENT_DATE - INTERVAL '7 days';

-- Popular content
SELECT * FROM popular_stickers_view LIMIT 10;
SELECT * FROM popular_emoticons_view LIMIT 10;
SELECT * FROM popular_backgrounds_view LIMIT 10;
```

## Security Considerations

### 1. Content Moderation
- All user-generated content goes through automatic moderation
- Implement manual review workflow for flagged content
- Monitor user behavior for suspicious activity

### 2. Rate Limiting
```sql
-- Check if user is within rate limits
SELECT check_widget_rate_limit(
    user_id, 
    'sticker_picker', 
    'sticker_upload',
    INTERVAL '1 hour',
    10 -- max 10 uploads per hour
);
```

### 3. File Upload Security
- Validate file types and sizes
- Scan for malicious content
- Use secure file storage with proper permissions

## Troubleshooting

### Common Issues

1. **RLS Policy Conflicts**
   ```sql
   -- Check policy conflicts
   SELECT * FROM pg_policies 
   WHERE tablename LIKE '%widget%' OR tablename LIKE '%sticker%';
   ```

2. **Performance Issues**
   ```sql
   -- Check slow queries
   SELECT query, mean_exec_time, calls
   FROM pg_stat_statements
   WHERE query LIKE '%widget%' OR query LIKE '%sticker%'
   ORDER BY mean_exec_time DESC;
   ```

3. **Cache Issues**
   ```sql
   -- Clear all widget caches
   SELECT invalidate_widget_cache('all');
   
   -- Check cache hit rates
   SELECT * FROM widget_cache_performance;
   ```

### Debug Mode
Enable debug widgets only in development:
```dart
// In debug builds only
if (kDebugMode) {
  // Show debug widgets
  PushNotificationTestWidget(),
  DeviceUserTrackingDebugWidget(),
}
```

## Migration from Previous Systems

### Data Migration Script
```sql
-- Example migration from old sticker system
INSERT INTO stickers (user_id, name, file_url, category, is_public, created_at)
SELECT user_id, sticker_name, image_url, 'imported', false, upload_date
FROM old_stickers_table
WHERE is_valid = true;

-- Migrate user preferences
INSERT INTO user_widget_preferences (user_id, widget_type, preferences)
SELECT user_id, 'sticker_picker', 
       jsonb_build_object('favorite_categories', favorite_sticker_categories)
FROM old_user_preferences
WHERE favorite_sticker_categories IS NOT NULL;
```

## Support and Documentation

### API Documentation
- All functions include comprehensive documentation comments
- Use `\df+ function_name` in psql to see function details
- Check `COMMENT ON` statements for table/column descriptions

### Performance Monitoring
- Monitor `widget_performance_metrics` table for optimization opportunities
- Use `widget_analytics_summary` view for usage insights
- Set up alerts for error rates and performance degradation

### Logging
- All widget actions are logged in `widget_usage_analytics`
- Security events logged in `widget_security_events`
- Error handling via `handle_widget_error()` function

## Contact and Support
For issues or questions regarding the widgets system integration:
- Check the function documentation in SQL files
- Review the Flutter widget implementations
- Monitor analytics for usage patterns and optimization opportunities

---

**Integration completed successfully!** The Crystal Social Widgets System provides a comprehensive foundation for advanced UI widget functionality with robust analytics, security, and performance optimization.
