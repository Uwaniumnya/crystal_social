import 'track.dart';

class PlayerState {
  final Track? track;
  final bool isPaused;
  final int playbackPosition; // in milliseconds
  final bool isShuffling;
  final int repeatMode; // 0 = off, 1 = track, 2 = context

  PlayerState({
    this.track,
    required this.isPaused,
    required this.playbackPosition,
    required this.isShuffling,
    required this.repeatMode,
  });

  factory PlayerState.fromJson(Map<String, dynamic> json) {
    return PlayerState(
      track: json['track'] != null ? Track.fromJson(json['track']) : null,
      isPaused: json['isPaused'] ?? json['is_paused'] ?? true,
      playbackPosition: json['playbackPosition'] ?? json['position_ms'] ?? 0,
      isShuffling: json['isShuffling'] ?? json['is_shuffling'] ?? false,
      repeatMode: json['repeatMode'] ?? json['repeat_mode'] ?? 0,
    );
  }

  factory PlayerState.fromMap(Map<String, dynamic> map) {
    return PlayerState(
      track: map['track'] != null ? Track.fromMap(map['track']) : null,
      isPaused: map['isPaused'] ?? map['is_paused'] ?? true,
      playbackPosition: map['playbackPosition'] ?? map['position_ms'] ?? 0,
      isShuffling: map['isShuffling'] ?? map['is_shuffling'] ?? false,
      repeatMode: map['repeatMode'] ?? map['repeat_mode'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'track': track?.toJson(),
      'isPaused': isPaused,
      'is_paused': isPaused,
      'playbackPosition': playbackPosition,
      'position_ms': playbackPosition,
      'isShuffling': isShuffling,
      'is_shuffling': isShuffling,
      'repeatMode': repeatMode,
      'repeat_mode': repeatMode,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'track': track?.toMap(),
      'isPaused': isPaused,
      'is_paused': isPaused,
      'playbackPosition': playbackPosition,
      'position_ms': playbackPosition,
      'isShuffling': isShuffling,
      'is_shuffling': isShuffling,
      'repeatMode': repeatMode,
      'repeat_mode': repeatMode,
    };
  }

  // Helper method to convert to the Map format used in music.dart
  Map<String, dynamic> toCompatibleMap() {
    return {
      'track': track?.toMap(),
      'isPaused': isPaused,
      'playbackPosition': playbackPosition,
      'isShuffling': isShuffling,
      'repeatMode': repeatMode,
    };
  }
}
