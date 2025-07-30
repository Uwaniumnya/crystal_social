import 'artist.dart';

class ImageUri {
  final String raw;

  ImageUri({required this.raw});

  factory ImageUri.fromJson(Map<String, dynamic> json) {
    return ImageUri(
      raw: json['raw'] ?? json['url'] ?? 'https://via.placeholder.com/250x250/6a1b9a/white?text=Music',
    );
  }

  factory ImageUri.fromMap(Map<String, dynamic> map) {
    return ImageUri(
      raw: map['raw'] ?? map['url'] ?? 'https://via.placeholder.com/250x250/6a1b9a/white?text=Music',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'raw': raw,
      'url': raw,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'raw': raw,
      'url': raw,
    };
  }
}

class Track {
  final String name;
  final String uri;
  final Artist artist;
  final ImageUri imageUri;
  final int duration; // in milliseconds

  Track({
    required this.name,
    required this.uri,
    required this.artist,
    required this.imageUri,
    required this.duration,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      name: json['name'] ?? 'Unknown Track',
      uri: json['uri'] ?? '',
      artist: Artist.fromJson(json['artist'] ?? {}),
      imageUri: ImageUri.fromJson(json['imageUri'] ?? json['album']?['images']?[0] ?? {}),
      duration: json['duration'] ?? json['duration_ms'] ?? 0,
    );
  }

  factory Track.fromMap(Map<String, dynamic> map) {
    return Track(
      name: map['name'] ?? 'Unknown Track',
      uri: map['uri'] ?? '',
      artist: Artist.fromMap(map['artist'] ?? {}),
      imageUri: ImageUri.fromMap(map['imageUri'] ?? map['album']?['images']?[0] ?? {}),
      duration: map['duration'] ?? map['duration_ms'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'uri': uri,
      'artist': artist.toJson(),
      'imageUri': imageUri.toJson(),
      'duration': duration,
      'duration_ms': duration,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'uri': uri,
      'artist': artist.toMap(),
      'imageUri': imageUri.toMap(),
      'duration': duration,
      'duration_ms': duration,
    };
  }
}
