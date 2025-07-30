import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note_model.dart';

/// Database service for managing notes with Supabase
class NotesDatabase {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all notes for a user
  Future<List<NoteModel>> getNotes(String userId) async {
    try {
      final response = await _supabase
          .from('notes')
          .select('*')
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      return (response as List)
          .map((json) => NoteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch notes: $e');
    }
  }

  /// Get a specific note by ID
  Future<NoteModel?> getNote(String noteId) async {
    try {
      final response = await _supabase
          .from('notes')
          .select('*')
          .eq('id', noteId)
          .maybeSingle();

      if (response == null) return null;
      return NoteModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch note: $e');
    }
  }

  /// Create a new note
  Future<NoteModel> createNote(NoteModel note) async {
    try {
      final response = await _supabase
          .from('notes')
          .insert(note.toJson())
          .select()
          .single();

      return NoteModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create note: $e');
    }
  }

  /// Update an existing note
  Future<NoteModel> updateNote(NoteModel note) async {
    try {
      final response = await _supabase
          .from('notes')
          .update(note.toJson())
          .eq('id', note.id)
          .select()
          .single();

      return NoteModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update note: $e');
    }
  }

  /// Delete a note
  Future<void> deleteNote(String noteId) async {
    try {
      await _supabase
          .from('notes')
          .delete()
          .eq('id', noteId);
    } catch (e) {
      throw Exception('Failed to delete note: $e');
    }
  }

  /// Search notes by title, content, or tags
  Future<List<NoteModel>> searchNotes(String userId, String query) async {
    try {
      final response = await _supabase
          .from('notes')
          .select('*')
          .eq('user_id', userId)
          .or('title.ilike.%$query%,content.ilike.%$query%,tags.cs.{$query}')
          .order('updated_at', ascending: false);

      return (response as List)
          .map((json) => NoteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search notes: $e');
    }
  }

  /// Get notes by category
  Future<List<NoteModel>> getNotesByCategory(String userId, String category) async {
    try {
      final response = await _supabase
          .from('notes')
          .select('*')
          .eq('user_id', userId)
          .eq('category', category)
          .order('updated_at', ascending: false);

      return (response as List)
          .map((json) => NoteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch notes by category: $e');
    }
  }

  /// Get favorite notes
  Future<List<NoteModel>> getFavoriteNotes(String userId) async {
    try {
      final response = await _supabase
          .from('notes')
          .select('*')
          .eq('user_id', userId)
          .eq('is_favorite', true)
          .order('updated_at', ascending: false);

      return (response as List)
          .map((json) => NoteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch favorite notes: $e');
    }
  }

  /// Get pinned notes
  Future<List<NoteModel>> getPinnedNotes(String userId) async {
    try {
      final response = await _supabase
          .from('notes')
          .select('*')
          .eq('user_id', userId)
          .eq('is_pinned', true)
          .order('updated_at', ascending: false);

      return (response as List)
          .map((json) => NoteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch pinned notes: $e');
    }
  }

  /// Get all unique categories for a user
  Future<List<String>> getCategories(String userId) async {
    try {
      final response = await _supabase
          .from('notes')
          .select('category')
          .eq('user_id', userId)
          .not('category', 'is', null);

      final categories = <String>{};
      for (final item in response as List) {
        final category = item['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  /// Get all unique tags for a user
  Future<List<String>> getTags(String userId) async {
    try {
      final response = await _supabase
          .from('notes')
          .select('tags')
          .eq('user_id', userId);

      final tags = <String>{};
      for (final item in response as List) {
        final noteTags = item['tags'] as List<dynamic>?;
        if (noteTags != null) {
          tags.addAll(noteTags.cast<String>());
        }
      }

      return tags.toList()..sort();
    } catch (e) {
      throw Exception('Failed to fetch tags: $e');
    }
  }

  /// Bulk operations for better performance
  Future<List<NoteModel>> bulkUpdateNotes(List<NoteModel> notes) async {
    try {
      final updates = notes.map((note) => note.toJson()).toList();
      final response = await _supabase
          .from('notes')
          .upsert(updates)
          .select();

      return (response as List)
          .map((json) => NoteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to bulk update notes: $e');
    }
  }

  /// Delete multiple notes
  Future<void> bulkDeleteNotes(List<String> noteIds) async {
    try {
      await _supabase
          .from('notes')
          .delete()
          .inFilter('id', noteIds);
    } catch (e) {
      throw Exception('Failed to bulk delete notes: $e');
    }
  }

  /// Initialize database tables (call this once during app setup)
  Future<void> initializeDatabase() async {
    try {
      // This would typically be done via Supabase dashboard/migrations
      // But we can check if the table exists and has the right structure
      await _supabase
          .from('notes')
          .select('id')
          .limit(1);
    } catch (e) {
      throw Exception('Database not properly initialized: $e');
    }
  }
}
