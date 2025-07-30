# Crystal Social Tabs System - SQL Integration Guide

## Overview

This comprehensive SQL integration provides complete database schema and functionality for the Crystal Social tabs navigation system. The system covers all aspects of the tabs functionality including navigation management, social media platform (Glitter Board), entertainment features (horoscope, tarot, oracle, Magic 8-Ball), polling system, confessions, home screen management, and real-time notifications.

## File Structure

```
Integrations/tabs/
├── 01_tabs_core_tables.sql          # Core database schema and tables
├── 02_tabs_business_logic.sql       # Stored procedures and business functions
├── 03_tabs_views_analytics.sql      # Views and analytics for reporting
├── 04_tabs_security_policies.sql    # Security policies and triggers
├── 05_tabs_realtime_subscriptions.sql # Real-time notifications and subscriptions
└── README.md                        # This integration guide
```

## Feature Coverage

### ✅ Core Tab Management System
- **Tab Definitions**: Dynamic tab configuration with production readiness flags
- **User Preferences**: Personalized tab settings, favorites, hiding, custom ordering
- **Usage Analytics**: Comprehensive tracking of tab usage patterns and performance
- **Daily Summaries**: Automated daily usage statistics and engagement metrics

### ✅ Home Screen App Grid
- **Home Screen Apps**: Dynamic app grid with custom positioning and styling
- **User Customization**: Personal layout preferences, pinning, hiding, custom sizes
- **Launch Tracking**: Analytics for app usage and user engagement patterns

### ✅ Glitter Board Social Platform (2045 lines covered)
- **Posts System**: Rich text posts with mood indicators, images, tags, locations
- **Comments System**: Threaded comments with reply support and engagement tracking
- **Reactions System**: Multiple reaction types (like, love, laugh) for posts and comments
- **Trending Algorithm**: Time-weighted engagement scoring for viral content discovery
- **User Activity**: Comprehensive social activity tracking and analytics

### ✅ Enhanced Horoscope System (4799 lines covered)
- **Zodiac Signs**: Complete zodiac system with elements, qualities, and characteristics
- **Daily Readings**: Personalized horoscope readings with multiple life aspects
- **User Preferences**: Zodiac sign setup, notification preferences, reading history
- **Streak Tracking**: Daily reading streaks with coin rewards and achievements
- **Analytics**: Engagement tracking by zodiac sign and reading patterns

### ✅ Tarot Reading System (1379 lines covered)
- **Tarot Decks**: Multiple deck support with card management
- **Reading Types**: Various spread types (single, three-card, Celtic cross, etc.)
- **Interpretations**: AI-generated interpretations with guidance messages
- **Reading History**: Personal tarot reading history and progress tracking

### ✅ Oracle Consultation System (1979 lines covered)
- **Oracle Messages**: Wisdom messages categorized by themes and energy levels
- **Consultations**: Question-based oracle guidance with emotional state consideration
- **User Feedback**: Rating system and helpfulness tracking for message quality
- **Crystal Recommendations**: Associated crystal suggestions with oracle messages

### ✅ Magic 8-Ball Entertainment
- **Response System**: Diverse response types (positive, negative, neutral)
- **Consultation Tracking**: Question categorization and mood-based responses
- **Visual Customization**: Custom colors and styling for response presentation

### ✅ Confessions System
- **Anonymous Confessions**: Privacy-protected confession sharing
- **Categories**: Organized confession topics with mood indicators
- **Moderation**: Content filtering and community guidelines enforcement

### ✅ Community Polling System
- **Poll Creation**: Flexible poll creation with multiple choice support
- **Voting System**: Anonymous and public voting with result tracking
- **Analytics**: Detailed voting patterns and engagement analytics
- **Expiration Management**: Time-based poll expiration and lifecycle management

### ✅ Video Calling Integration (1061 lines covered)
- **Call Management**: Video call session tracking and management
- **User Activity**: Call history and engagement metrics

### ✅ Settings and Preferences (1933 lines covered)
- **User Settings**: Comprehensive user preference management
- **Personalization**: Custom themes, notification settings, privacy controls
- **Profile Management**: User profile customization and data management

## Database Schema Features

### Security and Privacy
- **Row Level Security (RLS)**: Comprehensive data access controls
- **Content Moderation**: Automated content filtering and safety measures
- **Rate Limiting**: User action throttling to prevent abuse
- **Audit Logging**: Complete audit trail for sensitive operations
- **Anonymous Protection**: Secure handling of anonymous content

### Performance Optimization
- **Materialized Views**: Pre-computed analytics for fast reporting
- **Strategic Indexing**: Optimized database performance for high-traffic queries
- **Efficient Pagination**: Large dataset handling with proper pagination
- **Query Optimization**: Tuned queries for complex social media interactions

### Real-time Features
- **Live Notifications**: Real-time update system with WebSocket support
- **Channel Subscriptions**: User-configurable notification preferences
- **Event Triggers**: Automatic notifications for social interactions
- **Achievement System**: Real-time achievement notifications and rewards

### Analytics and Insights
- **User Engagement**: Comprehensive engagement scoring and analytics
- **Content Analytics**: Post performance, trending content, user interactions
- **Usage Patterns**: Tab usage analytics, session tracking, behavior analysis
- **Entertainment Metrics**: Horoscope, tarot, and oracle usage statistics

## Installation Instructions

### Prerequisites
- PostgreSQL 12+ with Supabase
- UUID extension enabled
- Row Level Security support
- Real-time subscriptions capability

### Step 1: Execute Core Schema
```sql
-- Execute files in order:
\i 01_tabs_core_tables.sql
```
This creates all tables, indexes, and basic constraints.

### Step 2: Install Business Logic
```sql
\i 02_tabs_business_logic.sql
```
This adds all stored procedures, functions, and business rules.

### Step 3: Create Views and Analytics
```sql
\i 03_tabs_views_analytics.sql
```
This creates views, materialized views, and analytics functions.

### Step 4: Apply Security Policies
```sql
\i 04_tabs_security_policies.sql
```
This enables RLS, creates security policies, and sets up content moderation.

### Step 5: Enable Real-time Features
```sql
\i 05_tabs_realtime_subscriptions.sql
```
This sets up notification channels, triggers, and real-time subscriptions.

## Usage Examples

### Tab Management
```sql
-- Register a new tab
SELECT register_tab(
    'meditation_tab',
    'Meditation Corner',
    'Peaceful meditation and mindfulness features',
    '/assets/meditation-icon.png',
    15,
    true,
    true
);

-- Update user tab preferences
SELECT update_tab_preferences(
    auth.uid(),
    'horoscope_tab',
    true, -- is_favorite
    false, -- is_hidden
    1, -- custom_order
    true -- notifications_enabled
);

-- Track tab usage
SELECT track_tab_usage(
    auth.uid(),
    'glitter_board',
    300, -- session_duration_seconds
    25, -- interactions_count
    1200 -- load_time_ms
);
```

### Social Media Features
```sql
-- Create a Glitter Board post
SELECT create_glitter_post(
    auth.uid(),
    'Feeling grateful for this beautiful day! ✨',
    '😊',
    'https://example.com/sunset.jpg',
    ARRAY['gratitude', 'sunset', 'peace'],
    'Beach Sunset Point',
    'public'
);

-- Add a comment
SELECT add_glitter_comment(
    auth.uid(),
    'post-uuid-here',
    'This is so beautiful! Thanks for sharing 💖'
);

-- React to a post
SELECT add_glitter_reaction(
    auth.uid(),
    'post',
    'post-uuid-here',
    'love'
);
```

### Entertainment Features
```sql
-- Set up user horoscope
SELECT setup_user_horoscope(
    auth.uid(),
    'Leo',
    true, -- daily_notifications
    '09:00:00' -- preferred_reading_time
);

-- Get daily horoscope
SELECT * FROM get_daily_horoscope(auth.uid());

-- Perform tarot reading
SELECT perform_tarot_reading(
    auth.uid(),
    'deck-uuid-here',
    'three_card',
    'What should I focus on this week?',
    '["card1", "card2", "card3"]'::jsonb
);

-- Get oracle guidance
SELECT * FROM get_oracle_guidance(
    auth.uid(),
    'life_guidance',
    'peaceful'
);

-- Ask Magic 8-Ball
SELECT * FROM get_8ball_response(
    auth.uid(),
    'Will today be a good day?',
    'daily_life',
    'hopeful'
);
```

### Community Features
```sql
-- Create a poll
SELECT create_poll(
    auth.uid(),
    'What''s your favorite time for meditation?',
    'Help us understand community preferences',
    'wellness',
    false, -- is_multiple_choice
    false, -- is_anonymous_voting
    NOW() + INTERVAL '7 days',
    ARRAY['Morning', 'Afternoon', 'Evening', 'Night']
);

-- Vote on a poll
SELECT vote_on_poll(
    auth.uid(),
    'poll-uuid-here',
    ARRAY['option-uuid-here'],
    false -- is_anonymous
);

-- Submit a confession
SELECT submit_confession(
    auth.uid(),
    'Sometimes I feel overwhelmed by social media, but this app feels different - more mindful and positive.',
    'social_media',
    '😌',
    false -- is_anonymous
);
```

### Analytics and Insights
```sql
-- Get user engagement summary
SELECT * FROM user_engagement_summary 
WHERE user_id = auth.uid();

-- View trending posts
SELECT * FROM trending_glitter_posts LIMIT 10;

-- Get daily system overview
SELECT * FROM daily_system_overview;

-- Check tab performance
SELECT * FROM tab_performance_analytics 
ORDER BY total_minutes DESC;
```

### Real-time Notifications
```sql
-- Subscribe to notification channel
SELECT subscribe_to_channel(
    auth.uid(),
    'social_activity',
    '{"email": true, "push": true}'::jsonb
);

-- Get unread notifications
SELECT * FROM get_unread_notifications(auth.uid(), 20);

-- Mark notification as read
SELECT mark_notification_read('notification-uuid', auth.uid());
```

## Maintenance and Monitoring

### Daily Maintenance
```sql
-- Run daily maintenance
SELECT daily_tabs_maintenance();

-- Clean expired notifications
SELECT cleanup_expired_notifications();

-- Update notification statistics
SELECT update_notification_stats();

-- Refresh materialized views
SELECT refresh_daily_tabs_stats();
```

### Weekly Maintenance
```sql
-- Refresh weekly analytics
SELECT refresh_weekly_user_activity();

-- Clean old audit logs
SELECT cleanup_old_audit_logs();

-- Clean old rate limit records
SELECT cleanup_old_rate_limits();
```

## Integration with Flutter App

### Connection Configuration
```dart
// In your Supabase configuration
final supabase = Supabase.initialize(
  url: 'https://zdsjtjbzhiejvpuahnlk.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpkc2p0amJ6aGllanZwdWFobmxrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4MjAyMzYsImV4cCI6MjA2OTM5NjIzNn0.CSPzbngxKJHrHD8oNMFaYzvKXzNzMENFtaWu9Vy2rV0',
  realtimeClientOptions: RealtimeClientOptions(
    logLevel: RealtimeLogLevel.info,
  ),
);
```

### Real-time Subscriptions
```dart
// Subscribe to notifications
final subscription = supabase
  .channel('notifications_${user.id}')
  .on(
    RealtimeListenTypes.postgresChanges,
    ChannelFilter(
      event: 'INSERT',
      schema: 'public',
      table: 'realtime_notifications',
      filter: 'target_user_id=eq.${user.id}',
    ),
    (payload) {
      // Handle real-time notification
      final notification = payload['new'];
      showNotification(notification);
    },
  )
  .subscribe();
```

### Function Calls
```dart
// Call database functions from Flutter
final response = await supabase
  .rpc('create_glitter_post', params: {
    'p_user_id': user.id,
    'p_text_content': 'Hello world!',
    'p_mood': '😊',
    'p_visibility': 'public',
  });
```

## Performance Considerations

### Optimization Features
1. **Materialized Views**: Daily and weekly stats pre-computed
2. **Indexed Queries**: Strategic indexing for common queries
3. **Rate Limiting**: Prevents system abuse and ensures fair usage
4. **Content Caching**: Efficient caching strategies for frequently accessed data
5. **Pagination**: Proper pagination for large datasets

### Monitoring Metrics
- Active user count and engagement rates
- Tab usage patterns and popular features
- Social interaction volumes and trends
- Entertainment feature adoption rates
- Real-time notification delivery rates
- Database performance and query optimization

## Security Features

### Data Protection
- **Row Level Security**: User data isolation and access control
- **Content Moderation**: Automated filtering of inappropriate content
- **Anonymous Protection**: Secure handling of anonymous contributions
- **Audit Logging**: Complete audit trail for compliance and debugging
- **Rate Limiting**: Protection against abuse and spam

### Privacy Controls
- User-controlled visibility settings
- Anonymous posting options
- Data retention policies
- GDPR compliance features
- Secure data deletion

## Support and Troubleshooting

### Common Issues
1. **Permission Errors**: Ensure RLS policies are correctly configured
2. **Real-time Issues**: Check notification channel subscriptions
3. **Performance**: Monitor materialized view refresh schedules
4. **Data Consistency**: Use provided maintenance functions regularly

### Debugging Tools
- Audit log analysis for tracking changes
- Performance analytics for identifying bottlenecks
- User engagement metrics for feature optimization
- Error logging and monitoring

## Future Enhancements

### Planned Features
1. **AI-Enhanced Content**: Improved tarot interpretations and oracle messages
2. **Advanced Analytics**: Machine learning insights for user behavior
3. **Social Features**: Group chats, events, and community building tools
4. **Personalization**: AI-driven content recommendations
5. **Wellness Tracking**: Mood tracking and wellness insights

### Scalability Improvements
1. **Database Sharding**: For handling larger user bases
2. **Caching Layers**: Redis integration for improved performance
3. **CDN Integration**: For media content delivery
4. **Microservices**: Breaking down into specialized services

---

This SQL integration provides a robust, scalable, and feature-rich foundation for the Crystal Social tabs system, supporting all current functionality while providing room for future growth and enhancement.
