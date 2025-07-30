import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../services/notes_database.dart';
import 'package:uuid/uuid.dart';

/// Provider for managing notes state and operations
class NotesProvider extends ChangeNotifier {
  final NotesDatabase _notesDatabase;
  final String _userId;

  List<NoteModel> _notes = [];
  List<NoteModel> _filteredNotes = [];
  String _searchQuery = '';
  String? _selectedCategory;
  bool _showFavoritesOnly = false;
  bool _showPinnedOnly = false;
  bool _isLoading = false;
  String? _error;
  
  // Sort options
  NoteSortOption _sortOption = NoteSortOption.updatedDesc;
  
  NotesProvider({
    required NotesDatabase notesDatabase,
    required String userId,
  }) : _notesDatabase = notesDatabase, _userId = userId {
    loadNotes();
  }

  // Getters
  List<NoteModel> get notes => _filteredNotes;
  List<NoteModel> get allNotes => _notes;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  bool get showFavoritesOnly => _showFavoritesOnly;
  bool get showPinnedOnly => _showPinnedOnly;
  bool get isLoading => _isLoading;
  String? get error => _error;
  NoteSortOption get sortOption => _sortOption;

  // Categories and tags
  List<String> get categories {
    final categories = <String>{};
    for (final note in _notes) {
      if (note.category != null && note.category!.isNotEmpty) {
        categories.add(note.category!);
      }
    }
    return categories.toList()..sort();
  }

  List<String> get tags {
    final tags = <String>{};
    for (final note in _notes) {
      tags.addAll(note.tags);
    }
    return tags.toList()..sort();
  }

  /// Load all notes from database
  Future<void> loadNotes() async {
    _setLoading(true);
    _setError(null);

    try {
      _notes = await _notesDatabase.getNotes(_userId);
      _applyFilters();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new note
  Future<NoteModel?> createNote({
    String title = '',
    String content = '',
    String? category,
    List<String> tags = const [],
    Color? color,
  }) async {
    try {
      final now = DateTime.now();
      final note = NoteModel(
        id: const Uuid().v4(),
        title: title,
        content: content,
        category: category,
        tags: tags,
        color: color,
        createdAt: now,
        updatedAt: now,
        userId: _userId,
      );

      final createdNote = await _notesDatabase.createNote(note);
      _notes.insert(0, createdNote);
      _applyFilters();
      return createdNote;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  /// Update an existing note
  Future<bool> updateNote(NoteModel note) async {
    try {
      final updatedNote = note.copyWith(updatedAt: DateTime.now());
      await _notesDatabase.updateNote(updatedNote);
      
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = updatedNote;
        _applyFilters();
      }
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Delete a note
  Future<bool> deleteNote(String noteId) async {
    try {
      await _notesDatabase.deleteNote(noteId);
      _notes.removeWhere((note) => note.id == noteId);
      _applyFilters();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Toggle favorite status of a note
  Future<bool> toggleFavorite(String noteId) async {
    final note = _notes.firstWhere((n) => n.id == noteId);
    return await updateNote(note.copyWith(isFavorite: !note.isFavorite));
  }

  /// Toggle pinned status of a note
  Future<bool> togglePinned(String noteId) async {
    final note = _notes.firstWhere((n) => n.id == noteId);
    return await updateNote(note.copyWith(isPinned: !note.isPinned));
  }

  /// Search notes
  void searchNotes(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  /// Filter by category
  void filterByCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
  }

  /// Toggle favorites filter
  void toggleFavoritesFilter() {
    _showFavoritesOnly = !_showFavoritesOnly;
    if (_showFavoritesOnly) _showPinnedOnly = false;
    _applyFilters();
  }

  /// Toggle pinned filter
  void togglePinnedFilter() {
    _showPinnedOnly = !_showPinnedOnly;
    if (_showPinnedOnly) _showFavoritesOnly = false;
    _applyFilters();
  }

  /// Change sort option
  void setSortOption(NoteSortOption option) {
    _sortOption = option;
    _applyFilters();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _showFavoritesOnly = false;
    _showPinnedOnly = false;
    _applyFilters();
  }

  /// Apply current filters and sorting
  void _applyFilters() {
    var filtered = List<NoteModel>.from(_notes);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((note) => note.matchesSearch(_searchQuery)).toList();
    }

    // Apply category filter
    if (_selectedCategory != null) {
      filtered = filtered.where((note) => note.category == _selectedCategory).toList();
    }

    // Apply favorites filter
    if (_showFavoritesOnly) {
      filtered = filtered.where((note) => note.isFavorite).toList();
    }

    // Apply pinned filter
    if (_showPinnedOnly) {
      filtered = filtered.where((note) => note.isPinned).toList();
    }

    // Apply sorting
    switch (_sortOption) {
      case NoteSortOption.updatedDesc:
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case NoteSortOption.updatedAsc:
        filtered.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
      case NoteSortOption.createdDesc:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case NoteSortOption.createdAsc:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case NoteSortOption.titleAsc:
        filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case NoteSortOption.titleDesc:
        filtered.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
    }

    // Ensure pinned notes are always at the top (unless specifically filtering)
    if (!_showPinnedOnly && !_showFavoritesOnly) {
      final pinnedNotes = filtered.where((note) => note.isPinned).toList();
      final unpinnedNotes = filtered.where((note) => !note.isPinned).toList();
      filtered = [...pinnedNotes, ...unpinnedNotes];
    }

    _filteredNotes = filtered;
    notifyListeners();
  }

  /// Bulk operations
  Future<bool> bulkDelete(List<String> noteIds) async {
    try {
      await _notesDatabase.bulkDeleteNotes(noteIds);
      _notes.removeWhere((note) => noteIds.contains(note.id));
      _applyFilters();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> bulkToggleFavorite(List<String> noteIds, bool isFavorite) async {
    try {
      final notesToUpdate = _notes
          .where((note) => noteIds.contains(note.id))
          .map((note) => note.copyWith(isFavorite: isFavorite, updatedAt: DateTime.now()))
          .toList();

      await _notesDatabase.bulkUpdateNotes(notesToUpdate);
      
      for (final updatedNote in notesToUpdate) {
        final index = _notes.indexWhere((n) => n.id == updatedNote.id);
        if (index != -1) {
          _notes[index] = updatedNote;
        }
      }
      
      _applyFilters();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> bulkSetCategory(List<String> noteIds, String? category) async {
    try {
      final notesToUpdate = _notes
          .where((note) => noteIds.contains(note.id))
          .map((note) => note.copyWith(category: category, updatedAt: DateTime.now()))
          .toList();

      await _notesDatabase.bulkUpdateNotes(notesToUpdate);
      
      for (final updatedNote in notesToUpdate) {
        final index = _notes.indexWhere((n) => n.id == updatedNote.id);
        if (index != -1) {
          _notes[index] = updatedNote;
        }
      }
      
      _applyFilters();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Statistics
  int get totalNotes => _notes.length;
  int get favoriteNotesCount => _notes.where((note) => note.isFavorite).length;
  int get pinnedNotesCount => _notes.where((note) => note.isPinned).length;
  int get totalWordCount => _notes.fold(0, (sum, note) => sum + note.wordCount);

  /// Get notes statistics by category
  Map<String, int> get notesByCategory {
    final Map<String, int> categoryCount = {};
    for (final note in _notes) {
      final category = note.category ?? 'Uncategorized';
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }
    return categoryCount;
  }
}

/// Sorting options for notes
enum NoteSortOption {
  updatedDesc('Last Updated'),
  updatedAsc('Oldest Updated'),
  createdDesc('Newest'),
  createdAsc('Oldest'),
  titleAsc('Title A-Z'),
  titleDesc('Title Z-A');

  const NoteSortOption(this.label);
  final String label;
}
