import 'package:flutter/material.dart';

/// Model class representing a note
class NoteModel {
  final String id;
  final String title;
  final String content;
  final String? category;
  final List<String> tags;
  final bool isFavorite;
  final bool isPinned;
  final Color? color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final String? audioPath;
  final List<String> attachments;

  const NoteModel({
    required this.id,
    required this.title,
    required this.content,
    this.category,
    this.tags = const [],
    this.isFavorite = false,
    this.isPinned = false,
    this.color,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    this.audioPath,
    this.attachments = const [],
  });

  /// Create a copy of this note with updated fields
  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    List<String>? tags,
    bool? isFavorite,
    bool? isPinned,
    Color? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    String? audioPath,
    List<String>? attachments,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      isPinned: isPinned ?? this.isPinned,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      audioPath: audioPath ?? this.audioPath,
      attachments: attachments ?? this.attachments,
    );
  }

  /// Convert to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'tags': tags,
      'is_favorite': isFavorite,
      'is_pinned': isPinned,
      'color': color?.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_id': userId,
      'audio_path': audioPath,
      'attachments': attachments,
    };
  }

  /// Create from JSON from database
  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      category: json['category'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      isFavorite: json['is_favorite'] as bool? ?? false,
      isPinned: json['is_pinned'] as bool? ?? false,
      color: json['color'] != null ? Color(json['color'] as int) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userId: json['user_id'] as String,
      audioPath: json['audio_path'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  /// Check if note matches search query
  bool matchesSearch(String query) {
    final lowercaseQuery = query.toLowerCase();
    return title.toLowerCase().contains(lowercaseQuery) ||
           content.toLowerCase().contains(lowercaseQuery) ||
           tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery)) ||
           (category?.toLowerCase().contains(lowercaseQuery) ?? false);
  }

  /// Get preview text (first few lines of content)
  String get preview {
    final lines = content.split('\n');
    if (lines.isEmpty) return '';
    
    final firstLine = lines.first.trim();
    if (firstLine.length <= 150) return firstLine;
    
    return '${firstLine.substring(0, 147)}...';
  }

  /// Get word count
  int get wordCount {
    if (content.trim().isEmpty) return 0;
    return content.trim().split(RegExp(r'\s+')).length;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NoteModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'NoteModel(id: $id, title: $title, createdAt: $createdAt)';
  }
}

/// Model for note categories
class NoteCategoryModel {
  final String id;
  final String name;
  final Color color;
  final IconData icon;
  final String userId;
  final DateTime createdAt;

  const NoteCategoryModel({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.userId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
      'icon': icon.codePoint,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory NoteCategoryModel.fromJson(Map<String, dynamic> json) {
    return NoteCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      color: Color(json['color'] as int),
      icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  NoteCategoryModel copyWith({
    String? id,
    String? name,
    Color? color,
    IconData? icon,
    String? userId,
    DateTime? createdAt,
  }) {
    return NoteCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NoteCategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
