import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/notes_provider.dart';
import '../models/note_model.dart';
import '../widgets/note_card.dart';
import '../widgets/notes_app_bar.dart';
import '../widgets/notes_drawer.dart';
import '../widgets/notes_fab.dart';
import '../widgets/empty_notes_widget.dart';
import '../widgets/notes_filter_chip.dart';
import 'note_editor_screen.dart';
import 'search_notes_screen.dart';

/// Main home screen for the Notes app
class NotesHomeScreen extends StatefulWidget {
  final String userId;

  const NotesHomeScreen({super.key, required this.userId});

  @override
  State<NotesHomeScreen> createState() => _NotesHomeScreenState();
}

class _NotesHomeScreenState extends State<NotesHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late AnimationController _filterAnimationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  bool _showFilters = false;
  bool _isGridView = true;
  final Set<String> _selectedNotes = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _filterAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _filterAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: NotesAppBar(
        onSearchTap: () => _navigateToSearch(),
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        onViewToggle: () => setState(() => _isGridView = !_isGridView),
        onFilterToggle: () => _toggleFilters(),
        isGridView: _isGridView,
        showFilters: _showFilters,
        isSelectionMode: _isSelectionMode,
        selectedCount: _selectedNotes.length,
        onClearSelection: () => _clearSelection(),
        onSelectAll: () => _selectAll(),
        onBulkDelete: () => _bulkDelete(),
        onBulkFavorite: () => _bulkToggleFavorite(),
      ),
      drawer: NotesDrawer(userId: widget.userId),
      body: Consumer<NotesProvider>(
        builder: (context, notesProvider, child) {
          return Column(
            children: [
              // Filter chips
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                child: _showFilters ? _buildFilterChips(notesProvider) : const SizedBox(),
              ),
              
              // Notes content
              Expanded(
                child: _buildNotesContent(notesProvider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimationController,
        child: NotesFab(
          onPressed: () => _createNewNote(),
          isSelectionMode: _isSelectionMode,
        ),
      ),
    );
  }

  Widget _buildFilterChips(NotesProvider notesProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // Categories
          ...notesProvider.categories.map((category) => NotesFilterChip(
            label: category,
            isSelected: notesProvider.selectedCategory == category,
            onTap: () => notesProvider.filterByCategory(
              notesProvider.selectedCategory == category ? null : category,
            ),
            icon: Icons.folder,
          )),
          
          // Special filters
          NotesFilterChip(
            label: 'Favorites',
            isSelected: notesProvider.showFavoritesOnly,
            onTap: () => notesProvider.toggleFavoritesFilter(),
            icon: Icons.favorite,
            color: Colors.red,
          ),
          NotesFilterChip(
            label: 'Pinned',
            isSelected: notesProvider.showPinnedOnly,
            onTap: () => notesProvider.togglePinnedFilter(),
            icon: Icons.push_pin,
            color: Colors.blue,
          ),
          
          // Clear filters
          if (notesProvider.selectedCategory != null ||
              notesProvider.showFavoritesOnly ||
              notesProvider.showPinnedOnly)
            NotesFilterChip(
              label: 'Clear',
              isSelected: false,
              onTap: () => notesProvider.clearFilters(),
              icon: Icons.clear,
              color: Colors.grey,
            ),
        ],
      ),
    );
  }

  Widget _buildNotesContent(NotesProvider notesProvider) {
    if (notesProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (notesProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading notes',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              notesProvider.error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => notesProvider.loadNotes(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (notesProvider.notes.isEmpty) {
      return EmptyNotesWidget(
        onCreateNote: () => _createNewNote(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => notesProvider.loadNotes(),
      child: _isGridView ? _buildGridView(notesProvider) : _buildListView(notesProvider),
    );
  }

  Widget _buildGridView(NotesProvider notesProvider) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: notesProvider.notes.length,
      itemBuilder: (context, index) {
        final note = notesProvider.notes[index];
        return _buildNoteCard(note);
      },
    );
  }

  Widget _buildListView(NotesProvider notesProvider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notesProvider.notes.length,
      itemBuilder: (context, index) {
        final note = notesProvider.notes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildNoteCard(note),
        );
      },
    );
  }

  Widget _buildNoteCard(NoteModel note) {
    final isSelected = _selectedNotes.contains(note.id);
    
    return NoteCard(
      note: note,
      isSelected: isSelected,
      isSelectionMode: _isSelectionMode,
      onTap: () => _handleNoteTap(note),
      onLongPress: () => _handleNoteLongPress(note),
      onFavoriteToggle: () => _toggleFavorite(note.id),
      onPinToggle: () => _togglePin(note.id),
      onDelete: () => _deleteNote(note.id),
    );
  }

  // Event handlers
  void _handleNoteTap(NoteModel note) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedNotes.contains(note.id)) {
          _selectedNotes.remove(note.id);
          if (_selectedNotes.isEmpty) {
            _isSelectionMode = false;
          }
        } else {
          _selectedNotes.add(note.id);
        }
      });
    } else {
      _editNote(note);
    }
  }

  void _handleNoteLongPress(NoteModel note) {
    if (!_isSelectionMode) {
      setState(() {
        _isSelectionMode = true;
        _selectedNotes.add(note.id);
      });
      HapticFeedback.mediumImpact();
    }
  }

  void _clearSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedNotes.clear();
    });
  }

  void _selectAll() {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    setState(() {
      _selectedNotes.addAll(notesProvider.notes.map((note) => note.id));
    });
  }

  // Navigation methods
  void _navigateToSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SearchNotesScreen(userId: widget.userId),
      ),
    );
  }

  Future<void> _createNewNote() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          userId: widget.userId,
        ),
      ),
    );

    if (result == true) {
      final notesProvider = Provider.of<NotesProvider>(context, listen: false);
      notesProvider.loadNotes();
    }
  }

  Future<void> _editNote(NoteModel note) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          userId: widget.userId,
          note: note,
        ),
      ),
    );

    if (result == true) {
      final notesProvider = Provider.of<NotesProvider>(context, listen: false);
      notesProvider.loadNotes();
    }
  }

  // Action methods
  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });

    if (_showFilters) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }
  }

  Future<void> _toggleFavorite(String noteId) async {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    await notesProvider.toggleFavorite(noteId);
  }

  Future<void> _togglePin(String noteId) async {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    await notesProvider.togglePinned(noteId);
  }

  Future<void> _deleteNote(String noteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final notesProvider = Provider.of<NotesProvider>(context, listen: false);
      await notesProvider.deleteNote(noteId);
    }
  }

  // Bulk actions
  Future<void> _bulkDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${_selectedNotes.length} Notes'),
        content: const Text('Are you sure you want to delete the selected notes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final notesProvider = Provider.of<NotesProvider>(context, listen: false);
      await notesProvider.bulkDelete(_selectedNotes.toList());
      _clearSelection();
    }
  }

  Future<void> _bulkToggleFavorite() async {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    await notesProvider.bulkToggleFavorite(_selectedNotes.toList(), true);
    _clearSelection();
  }
}
