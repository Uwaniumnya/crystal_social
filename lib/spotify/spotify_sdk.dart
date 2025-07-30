import 'dart:async';
import 'package:flutter/services.dart';
import 'models/player_state.dart';
import 'models/track.dart';
import 'models/artist.dart';

class SpotifySdk {
  static const MethodChannel _channel = MethodChannel('spotify_sdk');
  static StreamController<PlayerState>? _playerStateController;

  // Spotify App Remote connection
  static Future<bool> connectToSpotifyRemote({
    required String clientId,
    required String redirectUrl,
  }) async {
    try {
      final result = await _channel.invokeMethod('connectToSpotifyRemote', {
        'clientId': clientId,
        'redirectUrl': redirectUrl,
      });
      return result == true;
    } catch (e) {
      print('Spotify connection error: $e');
      return false;
    }
  }

  static Future<void> disconnect() async {
    try {
      await _channel.invokeMethod('disconnect');
      _playerStateController?.close();
      _playerStateController = null;
    } catch (e) {
      print('Spotify disconnect error: $e');
    }
  }

  // Player controls
  static Future<void> play({String? spotifyUri}) async {
    try {
      await _channel.invokeMethod('play', {
        'spotifyUri': spotifyUri,
      });
    } catch (e) {
      print('Spotify play error: $e');
    }
  }

  static Future<void> pause() async {
    try {
      await _channel.invokeMethod('pause');
    } catch (e) {
      print('Spotify pause error: $e');
    }
  }

  static Future<void> resume() async {
    try {
      await _channel.invokeMethod('resume');
    } catch (e) {
      print('Spotify resume error: $e');
    }
  }

  static Future<void> skipNext() async {
    try {
      await _channel.invokeMethod('skipNext');
    } catch (e) {
      print('Spotify skip next error: $e');
    }
  }

  static Future<void> skipPrevious() async {
    try {
      await _channel.invokeMethod('skipPrevious');
    } catch (e) {
      print('Spotify skip previous error: $e');
    }
  }

  static Future<void> seekToPosition(int positionMs) async {
    try {
      await _channel.invokeMethod('seekToPosition', {
        'positionMs': positionMs,
      });
    } catch (e) {
      print('Spotify seek error: $e');
    }
  }

  static Future<void> setShuffle(bool shuffle) async {
    try {
      await _channel.invokeMethod('setShuffle', {
        'shuffle': shuffle,
      });
    } catch (e) {
      print('Spotify shuffle error: $e');
    }
  }

  static Future<void> setRepeatMode(int repeatMode) async {
    try {
      await _channel.invokeMethod('setRepeatMode', {
        'repeatMode': repeatMode,
      });
    } catch (e) {
      print('Spotify repeat error: $e');
    }
  }

  // Player state subscription
  static Stream<PlayerState> subscribePlayerState() {
    _playerStateController ??= StreamController<PlayerState>.broadcast();
    
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'playerStateChanged') {
        final data = Map<String, dynamic>.from(call.arguments);
        final playerState = PlayerState.fromMap(data);
        _playerStateController?.add(playerState);
      }
    });

    return _playerStateController!.stream;
  }

  // Get current player state
  static Future<PlayerState?> getPlayerState() async {
    try {
      final result = await _channel.invokeMethod('getPlayerState');
      if (result != null) {
        return PlayerState.fromMap(Map<String, dynamic>.from(result));
      }
      return null;
    } catch (e) {
      print('Get player state error: $e');
      return null;
    }
  }

  // Connection status
  static Future<bool> isConnected() async {
    try {
      final result = await _channel.invokeMethod('isConnected');
      return result == true;
    } catch (e) {
      print('Check connection error: $e');
      return false;
    }
  }
}

// SpotifyApi class for Web API operations (search, playlists, etc.)
class SpotifyApi {
  static const MethodChannel _channel = MethodChannel('spotify_api');

  static Future<void> setAccessToken(String accessToken) async {
    try {
      await _channel.invokeMethod('setAccessToken', {
        'accessToken': accessToken,
      });
    } catch (e) {
      print('Set access token error: $e');
    }
  }

  static Future<List<Track>> searchTracks(String query, {int limit = 20}) async {
    try {
      final result = await _channel.invokeMethod('searchTracks', {
        'query': query,
        'limit': limit,
      });
      
      if (result != null && result['tracks'] != null) {
        final List<dynamic> trackList = result['tracks']['items'];
        return trackList.map((trackData) => Track.fromMap(Map<String, dynamic>.from(trackData))).toList();
      }
      return [];
    } catch (e) {
      print('Search tracks error: $e');
      return [];
    }
  }

  static Future<void> seekToPosition(int positionMs) async {
    try {
      await _channel.invokeMethod('seekToPosition', {
        'positionMs': positionMs,
      });
    } catch (e) {
      print('API seek error: $e');
    }
  }
}
