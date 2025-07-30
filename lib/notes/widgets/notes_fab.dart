import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Floating Action Button for creating new notes
class NotesFab extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isSelectionMode;

  const NotesFab({
    super.key,
    required this.onPressed,
    required this.isSelectionMode,
  });

  @override
  Widget build(BuildContext context) {
    if (isSelectionMode) {
      return const SizedBox(); // Hide FAB during selection mode
    }

    return FloatingActionButton.extended(
      onPressed: onPressed,
      elevation: 8,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: Text(
        'New Note',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
