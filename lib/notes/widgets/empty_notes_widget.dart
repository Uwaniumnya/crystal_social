import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget displayed when there are no notes
class EmptyNotesWidget extends StatelessWidget {
  final VoidCallback onCreateNote;

  const EmptyNotesWidget({
    super.key,
    required this.onCreateNote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animation or illustration
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Icon(
                Icons.note_add_outlined,
                size: 80,
                color: theme.colorScheme.primary.withOpacity(0.6),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Title
            Text(
              'No Notes Yet',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Description
            Text(
              'Create your first note to get started.\nOrganize your thoughts, ideas, and memories.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Create button
            FilledButton.icon(
              onPressed: onCreateNote,
              icon: const Icon(Icons.add),
              label: Text(
                'Create Note',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Tips
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Quick Tips',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTip(context, '• Use categories to organize notes'),
                  _buildTip(context, '• Pin important notes to the top'),
                  _buildTip(context, '• Add tags for easy searching'),
                  _buildTip(context, '• Use rich text formatting'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(BuildContext context, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          tip,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ),
    );
  }
}
