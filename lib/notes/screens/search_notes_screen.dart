import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/notes_provider.dart';
import '../models/note_model.dart';
import '../widgets/note_card.dart';
import 'note_editor_screen.dart';

/// Screen for searching notes
class SearchNotesScreen extends StatefulWidget {
  final String userId;

  const SearchNotesScreen({super.key, required this.userId});

  @override
  State<SearchNotesScreen> createState() => _SearchNotesScreenState();
}

class _SearchNotesScreenState extends State<SearchNotesScreen> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  List<NoteModel> _searchResults = [];
  bool _isSearching = false;
  List<String> _recentSearches = [];
  List<String> _suggestedTags = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    
    // Focus on search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });

    // Load suggested tags
    _loadSuggestedTags();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _loadSuggestedTags() {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    setState(() {
      _suggestedTags = notesProvider.tags.take(10).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildSearchAppBar(),
      body: Column(
        children: [
          // Search suggestions
          if (_searchController.text.isEmpty) ...[
            _buildSearchSuggestions(),
          ] else ...[
            // Search results
            Expanded(child: _buildSearchResults()),
          ],
        ],
      ),
    );
  }

  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      title: Container(
        height: 40,
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: GoogleFonts.inter(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search notes...',
            hintStyle: GoogleFonts.inter(
              color: Colors.grey.shade500,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchResults.clear();
                      });
                    },
                  )
                : null,
          ),
          textInputAction: TextInputAction.search,
          onChanged: _performSearch,
          onSubmitted: _onSearchSubmitted,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterOptions,
          tooltip: 'Filter options',
        ),
      ],
    );
  }

  Widget _buildSearchSuggestions() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recent searches
            if (_recentSearches.isNotEmpty) ...[
              _buildSectionHeader('Recent Searches'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _recentSearches.map((search) => _buildSuggestionChip(
                  search,
                  Icons.history,
                  () => _applySearch(search),
                )).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Popular tags
            if (_suggestedTags.isNotEmpty) ...[
              _buildSectionHeader('Popular Tags'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestedTags.map((tag) => _buildSuggestionChip(
                  '#$tag',
                  Icons.tag,
                  () => _applySearch('#$tag'),
                )).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Quick actions
            _buildSectionHeader('Quick Filters'),
            const SizedBox(height: 12),
            _buildQuickFilters(),

            const SizedBox(height: 24),

            // Search tips
            _buildSearchTips(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSuggestionChip(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildQuickFilterCard(
                'Favorites',
                Icons.favorite,
                Colors.red,
                () => _applyQuickFilter('favorites'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickFilterCard(
                'Pinned',
                Icons.push_pin,
                Colors.blue,
                () => _applyQuickFilter('pinned'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickFilterCard(
                'Recent',
                Icons.access_time,
                Colors.green,
                () => _applyQuickFilter('recent'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickFilterCard(
                'Categories',
                Icons.folder,
                Colors.orange,
                () => _showCategoriesFilter(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickFilterCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Search Tips',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTip('Search by title, content, or tags'),
          _buildTip('Use #tag to search for specific tags'),
          _buildTip('Search is case-insensitive'),
          _buildTip('Use filters to narrow results'),
        ],
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_searchResults.isEmpty) {
      return _buildNoResults();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final note = _searchResults[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: NoteCard(
            note: note,
            isSelected: false,
            isSelectionMode: false,
            onTap: () => _openNote(note),
            onLongPress: () {},
            onFavoriteToggle: () => _toggleFavorite(note.id),
            onPinToggle: () => _togglePin(note.id),
            onDelete: () => _deleteNote(note.id),
          ),
        );
      },
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No notes found',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords or check your spelling',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchResults.clear();
                });
              },
              child: const Text('Clear search'),
            ),
          ],
        ),
      ),
    );
  }

  // Search methods
  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Simulate search delay
    Future.delayed(const Duration(milliseconds: 300), () {
      final notesProvider = Provider.of<NotesProvider>(context, listen: false);
      final results = notesProvider.allNotes
          .where((note) => note.matchesSearch(query.trim()))
          .toList();

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isNotEmpty && !_recentSearches.contains(query.trim())) {
      setState(() {
        _recentSearches.insert(0, query.trim());
        if (_recentSearches.length > 5) {
          _recentSearches.removeLast();
        }
      });
    }
  }

  void _applySearch(String query) {
    _searchController.text = query;
    _performSearch(query);
  }

  void _applyQuickFilter(String filter) {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    
    switch (filter) {
      case 'favorites':
        notesProvider.toggleFavoritesFilter();
        break;
      case 'pinned':
        notesProvider.togglePinnedFilter();
        break;
      case 'recent':
        notesProvider.setSortOption(NoteSortOption.updatedDesc);
        break;
    }
    
    Navigator.of(context).pop();
  }

  void _showCategoriesFilter() {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final categories = notesProvider.categories;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by Category',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (categories.isEmpty)
              const Text('No categories available')
            else
              ...categories.map((category) => ListTile(
                title: Text(category),
                onTap: () {
                  notesProvider.filterByCategory(category);
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              )),
          ],
        ),
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Options',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Favorites only'),
              onTap: () => _applyQuickFilter('favorites'),
            ),
            ListTile(
              leading: const Icon(Icons.push_pin),
              title: const Text('Pinned only'),
              onTap: () => _applyQuickFilter('pinned'),
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('By category'),
              onTap: () => _showCategoriesFilter(),
            ),
          ],
        ),
      ),
    );
  }

  // Note actions
  Future<void> _openNote(NoteModel note) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          userId: widget.userId,
          note: note,
        ),
      ),
    );

    if (result == true) {
      // Refresh search results
      _performSearch(_searchController.text);
    }
  }

  Future<void> _toggleFavorite(String noteId) async {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    await notesProvider.toggleFavorite(noteId);
    _performSearch(_searchController.text);
  }

  Future<void> _togglePin(String noteId) async {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    await notesProvider.togglePinned(noteId);
    _performSearch(_searchController.text);
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
      _performSearch(_searchController.text);
    }
  }
}
