import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom app bar for the Notes app
class NotesAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onMenuTap;
  final VoidCallback onViewToggle;
  final VoidCallback onFilterToggle;
  final bool isGridView;
  final bool showFilters;
  final bool isSelectionMode;
  final int selectedCount;
  final VoidCallback onClearSelection;
  final VoidCallback onSelectAll;
  final VoidCallback onBulkDelete;
  final VoidCallback onBulkFavorite;

  const NotesAppBar({
    super.key,
    required this.onSearchTap,
    required this.onMenuTap,
    required this.onViewToggle,
    required this.onFilterToggle,
    required this.isGridView,
    required this.showFilters,
    required this.isSelectionMode,
    required this.selectedCount,
    required this.onClearSelection,
    required this.onSelectAll,
    required this.onBulkDelete,
    required this.onBulkFavorite,
  });

  @override
  Widget build(BuildContext context) {
    if (isSelectionMode) {
      return _buildSelectionAppBar(context);
    }
    return _buildNormalAppBar(context);
  }

  Widget _buildNormalAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        'Notes',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: onMenuTap,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: onSearchTap,
          tooltip: 'Search notes',
        ),
        IconButton(
          icon: Icon(showFilters ? Icons.filter_list : Icons.filter_list_outlined),
          onPressed: onFilterToggle,
          tooltip: 'Filter notes',
        ),
        IconButton(
          icon: Icon(isGridView ? Icons.view_list : Icons.view_module),
          onPressed: onViewToggle,
          tooltip: isGridView ? 'List view' : 'Grid view',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSelectionAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: onClearSelection,
      ),
      title: Text(
        '$selectedCount selected',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        if (selectedCount > 0) ...[
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: onSelectAll,
            tooltip: 'Select all',
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: onBulkFavorite,
            tooltip: 'Add to favorites',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onBulkDelete,
            tooltip: 'Delete',
          ),
        ],
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
