class Artist {
  final String name;
  final String? uri;

  Artist({
    required this.name,
    this.uri,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      name: json['name'] ?? 'Unknown Artist',
      uri: json['uri'],
    );
  }

  factory Artist.fromMap(Map<String, dynamic> map) {
    return Artist(
      name: map['name'] ?? 'Unknown Artist',
      uri: map['uri'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'uri': uri,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'uri': uri,
    };
  }
}
