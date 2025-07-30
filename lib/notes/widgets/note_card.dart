import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/note_model.dart';

/// Card widget for displaying individual notes
class NoteCard extends StatelessWidget {
  final NoteModel note;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onPinToggle;
  final VoidCallback onDelete;

  const NoteCard({
    super.key,
    required this.note,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onFavoriteToggle,
    required this.onPinToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: note.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.primary 
                : (note.color != null 
                    ? Colors.transparent 
                    : theme.colorScheme.outline.withOpacity(0.2)),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with title and actions
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pinned indicator
                      if (note.isPinned)
                        Container(
                          margin: const EdgeInsets.only(right: 8, top: 2),
                          child: Icon(
                            Icons.push_pin,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      
                      // Title
                      Expanded(
                        child: Text(
                          note.title.isEmpty ? 'Untitled' : note.title,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: note.title.isEmpty 
                                ? theme.colorScheme.onSurface.withOpacity(0.5)
                                : _getTextColor(context),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // Selection indicator
                      if (isSelectionMode)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          child: Icon(
                            isSelected 
                                ? Icons.check_circle 
                                : Icons.circle_outlined,
                            color: isSelected 
                                ? theme.colorScheme.primary 
                                : theme.colorScheme.outline,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  
                  // Content preview
                  if (note.content.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      note.preview,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _getTextColor(context).withOpacity(0.8),
                        height: 1.4,
                      ),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  // Tags
                  if (note.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: note.tags.take(3).map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#$tag',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                  
                  // Footer with metadata
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Category
                      if (note.category != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            note.category!,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      
                      // Date
                      Expanded(
                        child: Text(
                          _formatDate(note.updatedAt),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _getTextColor(context).withOpacity(0.6),
                          ),
                        ),
                      ),
                      
                      // Word count
                      if (note.wordCount > 0)
                        Text(
                          '${note.wordCount} words',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: _getTextColor(context).withOpacity(0.5),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Action buttons (when not in selection mode)
            if (!isSelectionMode)
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Favorite button
                    InkWell(
                      onTap: onFavoriteToggle,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          note.isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: note.isFavorite 
                              ? Colors.red 
                              : _getTextColor(context).withOpacity(0.5),
                        ),
                      ),
                    ),
                    
                    // More options
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        size: 16,
                        color: _getTextColor(context).withOpacity(0.5),
                      ),
                      onSelected: (value) => _handleMenuAction(value),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'pin',
                          child: Row(
                            children: [
                              Icon(note.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                              const SizedBox(width: 8),
                              Text(note.isPinned ? 'Unpin' : 'Pin'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getTextColor(BuildContext context) {
    if (note.color != null) {
      // Calculate if we need light or dark text based on background color
      final luminance = note.color!.computeLuminance();
      return luminance > 0.5 ? Colors.black87 : Colors.white;
    }
    return Theme.of(context).colorScheme.onSurface;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final noteDate = DateTime(date.year, date.month, date.day);

    if (noteDate == today) {
      return DateFormat('HH:mm').format(date);
    } else if (noteDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'pin':
        onPinToggle();
        break;
      case 'delete':
        onDelete();
        break;
    }
  }
}
