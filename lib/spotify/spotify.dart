// Spotify SDK for Crystal Social
// Main exports for easy importing

// Core SDK
export 'spotify_sdk.dart';

// Models
export 'models/artist.dart';
export 'models/track.dart';
export 'models/player_state.dart';

// Services
export 'services/spotify_service.dart';

// Type aliases for backward compatibility
import 'models/player_state.dart' as spotify;
import 'models/track.dart' as spotify;
import 'models/artist.dart' as spotify;

// Export with spotify namespace for existing code compatibility
typedef PlayerState = spotify.PlayerState;
typedef Track = spotify.Track;
typedef Artist = spotify.Artist;
