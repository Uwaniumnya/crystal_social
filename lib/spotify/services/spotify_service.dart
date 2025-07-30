import 'dart:async';
import '../spotify_sdk.dart';
import '../models/player_state.dart';
import '../models/track.dart';

class SpotifyService {
  static SpotifyService? _instance;
  static SpotifyService get instance => _instance ??= SpotifyService._();
  SpotifyService._();

  StreamController<PlayerState>? _playerStateController;
  PlayerState? _currentPlayerState;
  bool _isConnected = false;

  // Spotify App credentials - Replace with your actual credentials
  static const String clientId = '1288db98cd1e41a19bd18d721df20fae';
  static const String redirectUrl = 'crystalapp://callback';

  // Initialize Spotify connection
  Future<bool> initialize() async {
    try {
      _isConnected = await SpotifySdk.connectToSpotifyRemote(
        clientId: clientId,
        redirectUrl: redirectUrl,
      );

      if (_isConnected) {
        _subscribeToPlayerState();
      }

      return _isConnected;
    } catch (e) {
      print('Spotify initialization error: $e');
      return false;
    }
  }

  // Subscribe to player state changes
  void _subscribeToPlayerState() {
    SpotifySdk.subscribePlayerState().listen((playerState) {
      _currentPlayerState = playerState;
      _playerStateController?.add(playerState);
    });
  }

  // Get player state stream
  Stream<PlayerState> get playerStateStream {
    _playerStateController ??= StreamController<PlayerState>.broadcast();
    return _playerStateController!.stream;
  }

  // Get current player state
  PlayerState? get currentPlayerState => _currentPlayerState;

  // Player controls
  Future<void> play({String? trackUri}) async {
    if (!_isConnected) return;
    await SpotifySdk.play(spotifyUri: trackUri);
  }

  Future<void> pause() async {
    if (!_isConnected) return;
    await SpotifySdk.pause();
  }

  Future<void> resume() async {
    if (!_isConnected) return;
    await SpotifySdk.resume();
  }

  Future<void> skipNext() async {
    if (!_isConnected) return;
    await SpotifySdk.skipNext();
  }

  Future<void> skipPrevious() async {
    if (!_isConnected) return;
    await SpotifySdk.skipPrevious();
  }

  Future<void> seekToPosition(int positionMs) async {
    if (!_isConnected) return;
    await SpotifySdk.seekToPosition(positionMs);
  }

  Future<void> setShuffle(bool shuffle) async {
    if (!_isConnected) return;
    await SpotifySdk.setShuffle(shuffle);
  }

  Future<void> setRepeatMode(int repeatMode) async {
    if (!_isConnected) return;
    await SpotifySdk.setRepeatMode(repeatMode);
  }

  // Search functionality
  Future<List<Track>> searchTracks(String query, {int limit = 20}) async {
    try {
      return await SpotifyApi.searchTracks(query, limit: limit);
    } catch (e) {
      print('Search error: $e');
      return [];
    }
  }

  // Connection status
  bool get isConnected => _isConnected;

  // Check connection status
  Future<bool> checkConnection() async {
    _isConnected = await SpotifySdk.isConnected();
    return _isConnected;
  }

  // Disconnect
  Future<void> disconnect() async {
    await SpotifySdk.disconnect();
    _isConnected = false;
    _playerStateController?.close();
    _playerStateController = null;
    _currentPlayerState = null;
  }

  // Dispose
  void dispose() {
    _playerStateController?.close();
    _instance = null;
  }
}
