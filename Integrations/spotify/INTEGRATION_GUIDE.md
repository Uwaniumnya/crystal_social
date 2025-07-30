# Crystal Social Spotify Integration - Complete Setup Guide

## Overview

This guide provides comprehensive instructions for implementing the Crystal Social Spotify integration system. The integration includes a complete music social platform with real-time listening rooms, queue management, voting systems, reactions, and advanced analytics.

## 📁 File Structure

```
Integrations/spotify/
├── 01_spotify_core_tables.sql       # Core database tables and infrastructure
├── 02_spotify_business_logic.sql    # Business logic functions and procedures
├── 03_spotify_views_queries.sql     # Views and optimized queries
├── 04_spotify_security_rls.sql      # Security policies and Row Level Security
├── 05_spotify_realtime_triggers.sql # Real-time features and triggers
└── INTEGRATION_GUIDE.md            # This file
```

## 🎯 System Features

### Core Functionality
- **Spotify Account Integration**: Secure OAuth authentication and token management
- **Music Rooms**: Collaborative listening spaces with real-time synchronization
- **Queue Management**: Democratic queue system with voting and reordering
- **Real-time Sync**: Synchronized playback across all room participants
- **Social Features**: Reactions, chat, and user interactions during music playback
- **Analytics**: Comprehensive listening analytics and room performance metrics

### Advanced Features
- **Voting System**: Democratic track queue management with upvotes/downvotes
- **Live Reactions**: Real-time emoji reactions with floating animations
- **Music Discovery**: Popular tracks, recommendations, and user similarity matching
- **Caching System**: Optimized Spotify API caching for performance
- **Rate Limiting**: Abuse prevention and API protection
- **Security**: Comprehensive Row Level Security and audit logging

## 🚀 Installation Instructions

### Prerequisites

1. **PostgreSQL Database**: Version 12+ with Supabase
2. **Required Extensions**: Ensure these PostgreSQL extensions are available:
   ```sql
   CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
   CREATE EXTENSION IF NOT EXISTS "pg_trgm";
   CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
   ```

3. **Existing Tables**: The following tables must exist:
   - `auth.users` (Supabase authentication)
   - `user_profiles` (Crystal Social user profiles)

### Step 1: Database Setup

Execute the SQL files in order:

```bash
# 1. Core tables and infrastructure
psql -d your_database -f 01_spotify_core_tables.sql

# 2. Business logic functions
psql -d your_database -f 02_spotify_business_logic.sql

# 3. Views and queries
psql -d your_database -f 03_spotify_views_queries.sql

# 4. Security and RLS policies
psql -d your_database -f 04_spotify_security_rls.sql

# 5. Real-time features and triggers
psql -d your_database -f 05_spotify_realtime_triggers.sql
```

### Step 2: Verification

After installation, verify the setup:

```sql
-- Check tables created
SELECT COUNT(*) as spotify_tables 
FROM information_schema.tables 
WHERE table_name LIKE '%spotify%' OR table_name LIKE '%music%' OR table_name LIKE '%room%';

-- Check functions created
SELECT COUNT(*) as spotify_functions 
FROM information_schema.routines 
WHERE routine_name LIKE '%spotify%' OR routine_name LIKE '%room%' OR routine_name LIKE '%music%';

-- Check triggers created
SELECT COUNT(*) as spotify_triggers 
FROM information_schema.triggers 
WHERE trigger_name LIKE '%spotify%' OR trigger_name LIKE '%room%' OR trigger_name LIKE '%music%';

-- Check policies created
SELECT COUNT(*) as spotify_policies 
FROM pg_policies 
WHERE tablename LIKE '%spotify%' OR tablename LIKE '%music%' OR tablename LIKE '%room%';
```

## 🔧 Flutter Integration

### Required Dependencies

Add to your `pubspec.yaml`:

```yaml
dependencies:
  spotify_sdk: ^2.3.0
  supabase_flutter: ^1.10.0
  web_socket_channel: ^2.4.0
  json_annotation: ^4.8.1
  uuid: ^3.0.7

dev_dependencies:
  json_serializable: ^6.7.1
  build_runner: ^2.4.7
```

### Spotify SDK Configuration

The existing files in `lib/spotify/` are already configured for this database schema:

- `lib/spotify/spotify.dart` - Main exports
- `lib/spotify/spotify_sdk.dart` - SDK wrapper with platform channel
- `lib/spotify/music.dart` - Complete music screen UI
- `lib/spotify/models/` - Data models (Artist, Track, PlayerState)
- `lib/spotify/services/spotify_service.dart` - Service integration

### Database Service Integration

Create a new service file `lib/services/spotify_database_service.dart`:

```dart
class SpotifyDatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Room management
  Future<String> createRoom(String name, String description) async {
    final result = await _supabase.rpc('create_music_room', params: {
      'p_host_id': _supabase.auth.currentUser?.id,
      'p_name': name,
      'p_description': description,
    });
    return result as String;
  }
  
  Future<bool> joinRoom(String roomId, String? password) async {
    final result = await _supabase.rpc('join_music_room', params: {
      'p_user_id': _supabase.auth.currentUser?.id,
      'p_room_id': roomId,
      'p_password': password,
    });
    return result as bool;
  }
  
  // Queue management
  Future<String> addTrackToQueue(String roomId, Track track) async {
    final result = await _supabase.rpc('add_track_to_queue', params: {
      'p_room_id': roomId,
      'p_user_id': _supabase.auth.currentUser?.id,
      'p_track_uri': track.uri,
      'p_track_name': track.name,
      'p_artist_name': track.artists.first.name,
      'p_duration_ms': track.durationMs,
    });
    return result as String;
  }
  
  // Real-time subscriptions
  Stream<Map<String, dynamic>> subscribeToRoom(String roomId) {
    return _supabase
        .channel('room_$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'room_sync',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
        )
        .subscribe()
        .stream;
  }
}
```

## 🔄 Real-time Features Setup

### WebSocket Channels

The system uses PostgreSQL NOTIFY/LISTEN for real-time updates:

- `room_{room_id}` - Room-specific updates
- `user_{user_id}` - User-specific notifications
- `rooms_global` - Global room updates

### Flutter Real-time Integration

```dart
class RealtimeSpotifyService {
  late RealtimeChannel _roomChannel;
  
  void subscribeToRoom(String roomId) {
    _roomChannel = Supabase.instance.client
        .channel('room_$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'room_sync',
          callback: (payload) {
            // Handle real-time sync updates
            _handleRoomSync(payload.newRecord);
          },
        )
        .subscribe();
  }
  
  void _handleRoomSync(Map<String, dynamic> syncData) {
    // Update local player state
    // Trigger UI updates
    // Synchronize playback position
  }
}
```

## 📊 Analytics and Monitoring

### Built-in Analytics

The system includes comprehensive analytics:

1. **User Analytics**:
   - Daily listening statistics
   - Discovery metrics
   - Completion rates
   - Social activity tracking

2. **Room Analytics**:
   - Engagement scoring
   - Peak concurrent users
   - Track popularity
   - Session duration metrics

3. **System Analytics**:
   - Performance monitoring
   - Cache hit rates
   - Real-time connection status
   - Error tracking

### Viewing Analytics

Use the provided views for analytics:

```sql
-- User dashboard
SELECT * FROM v_user_listening_dashboard WHERE user_id = $1;

-- Room performance
SELECT * FROM v_room_analytics_summary ORDER BY engagement_score DESC;

-- Popular tracks
SELECT * FROM v_popular_tracks_global LIMIT 20;

-- System metrics
SELECT * FROM v_spotify_system_metrics;
```

## 🔒 Security Configuration

### Row Level Security (RLS)

All tables have RLS enabled with policies for:

- **User Data**: Users can only access their own data
- **Room Access**: Based on participation and room visibility
- **Admin Access**: Moderators can access aggregated data
- **System Functions**: Service role for automated operations

### Rate Limiting

Built-in rate limiting prevents abuse:

```sql
-- Check rate limit before action
SELECT check_rate_limit(user_id, 'create_room', 5, 60); -- 5 rooms per hour
SELECT check_rate_limit(user_id, 'add_track', 20, 60);  -- 20 tracks per hour
```

### Audit Logging

All significant actions are logged in `spotify_audit_log`:

- Room creation/modification
- Participant changes
- Spotify account connections
- Moderation actions

## 🛠 Maintenance and Operations

### Automated Maintenance

The system includes automated maintenance functions:

```sql
-- Run daily (recommended via cron job)
SELECT daily_spotify_maintenance();

-- Run hourly
SELECT hourly_maintenance();

-- Run every minute
SELECT minute_maintenance();
```

### Performance Optimization

1. **Indexes**: All tables have optimized indexes for common queries
2. **Caching**: Spotify API responses are cached with configurable TTL
3. **Cleanup**: Automatic cleanup of expired data and inactive sessions
4. **Connection Pooling**: Use connection pooling for high-traffic scenarios

### Monitoring Queries

```sql
-- Active rooms and participants
SELECT active_rooms, total_listeners FROM v_spotify_system_metrics;

-- Performance metrics
SELECT 
    table_name,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE tablename LIKE '%spotify%' OR tablename LIKE '%music%'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Cache efficiency
SELECT 
    COUNT(*) as cached_tracks,
    AVG(access_count) as avg_access_count,
    COUNT(*) FILTER (WHERE last_accessed_at >= CURRENT_DATE) as accessed_today
FROM spotify_tracks_cache;
```

## 🎵 Usage Examples

### Creating a Music Room

```dart
// Flutter
final roomId = await spotifyDatabaseService.createRoom(
  'Chill Vibes Room',
  'Relaxing music for studying and work'
);

// SQL Direct
SELECT create_music_room(
  p_host_id := auth.uid(),
  p_name := 'Chill Vibes Room',
  p_description := 'Relaxing music for studying and work',
  p_mood := 'Chill'
);
```

### Adding Tracks to Queue

```dart
// Flutter
await spotifyDatabaseService.addTrackToQueue(roomId, track);

// SQL Direct
SELECT add_track_to_queue(
  p_room_id := 'room-uuid',
  p_user_id := auth.uid(),
  p_track_uri := 'spotify:track:4iV5W9uYEdYUVa79Axb7Rh',
  p_track_name := 'Song Name',
  p_artist_name := 'Artist Name'
);
```

### Voting on Tracks

```dart
// Flutter - Upvote a track
await spotifyDatabaseService.voteOnTrack(trackId, true);

// SQL Direct
SELECT vote_on_track(
  p_user_id := auth.uid(),
  p_track_id := 'track-uuid',
  p_is_upvote := true
);
```

## 🚨 Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure RLS policies are correctly configured
2. **Real-time Not Working**: Check WebSocket connections and channel subscriptions
3. **Sync Issues**: Verify room_sync table triggers are active
4. **Performance**: Monitor query performance and index usage

### Debug Queries

```sql
-- Check user permissions
SELECT validate_room_access(auth.uid(), 'room-uuid', 'listener');

-- Check Spotify connection
SELECT validate_spotify_connection(auth.uid());

-- View recent activity
SELECT * FROM spotify_audit_log ORDER BY created_at DESC LIMIT 10;

-- Check real-time status
SELECT * FROM spotify_realtime_status ORDER BY updated_at DESC LIMIT 1;
```

## 📞 Support

For issues with this integration:

1. Check the database logs for error messages
2. Verify all SQL files executed successfully
3. Ensure proper permissions are granted
4. Test with the provided verification queries

## 🔄 Updates and Migration

When updating the schema:

1. Always backup the database first
2. Test migrations on a development environment
3. Use transaction blocks for safety
4. Update version numbers in comments

## 📈 Performance Recommendations

1. **Connection Pooling**: Use pgBouncer or similar for connection management
2. **Monitoring**: Set up monitoring for key metrics and performance
3. **Scaling**: Consider read replicas for high-traffic analytics queries
4. **Indexing**: Monitor and add indexes based on actual usage patterns
5. **Caching**: Implement application-level caching for frequently accessed data

---

**Integration Complete!** 🎉

Your Crystal Social Spotify system is now fully configured with comprehensive music social features, real-time synchronization, and robust analytics. The system supports unlimited concurrent rooms, democratic queue management, and advanced social listening features.
