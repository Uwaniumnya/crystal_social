import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';

import '../models/note_model.dart';
import '../providers/notes_provider.dart';

/// Screen for creating and editing notes
class NoteEditorScreen extends StatefulWidget {
  final String userId;
  final NoteModel? note;

  const NoteEditorScreen({
    super.key,
    required this.userId,
    this.note,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late QuillController _quillController;
  late TextEditingController _titleController;
  late FocusNode _titleFocusNode;
  late FocusNode _contentFocusNode;
  
  String? _selectedCategory;
  List<String> _tags = [];
  Color? _noteColor;
  bool _isFavorite = false;
  bool _isPinned = false;
  bool _hasChanges = false;
  bool _isLoading = false;

  final List<Color> _noteColors = [
    Colors.white,
    Colors.red.shade100,
    Colors.orange.shade100,
    Colors.yellow.shade100,
    Colors.green.shade100,
    Colors.blue.shade100,
    Colors.purple.shade100,
    Colors.pink.shade100,
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadNoteData();
  }

  void _initializeControllers() {
    _titleController = TextEditingController();
    _titleFocusNode = FocusNode();
    _contentFocusNode = FocusNode();
    _quillController = QuillController.basic();

    // Listen for changes
    _titleController.addListener(_onContentChanged);
    _quillController.addListener(_onContentChanged);
  }

  void _loadNoteData() {
    if (widget.note != null) {
      final note = widget.note!;
      _titleController.text = note.title;
      _selectedCategory = note.category;
      _tags = List.from(note.tags);
      _noteColor = note.color;
      _isFavorite = note.isFavorite;
      _isPinned = note.isPinned;

      // Load content into Quill editor
      try {
        if (note.content.isNotEmpty) {
          _quillController.document = Document.fromJson(
            // Try to parse as JSON, fallback to plain text
            _tryParseJson(note.content) ?? [{'insert': note.content + '\n'}],
          );
        }
      } catch (e) {
        // Fallback to plain text
        _quillController.document = Document()..insert(0, note.content);
      }
    } else {
      // New note - focus on title
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _titleFocusNode.requestFocus();
      });
    }
  }

  dynamic _tryParseJson(String content) {
    try {
      return jsonDecode(content);
    } catch (e) {
      return null;
    }
  }

  void _onContentChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    _quillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvoked: (didPop) async {
        if (!didPop && _hasChanges) {
          final shouldPop = await _showDiscardDialog();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: _noteColor ?? Theme.of(context).colorScheme.surface,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            // Title input
            _buildTitleInput(),
            
            // Toolbar
            _buildToolbar(),
            
            // Content editor
            Expanded(child: _buildContentEditor()),
            
            // Bottom bar with actions
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => _handleBack(),
      ),
      title: Text(
        widget.note != null ? 'Edit Note' : 'New Note',
        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
      actions: [
        // Pin toggle
        IconButton(
          icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined),
          onPressed: () => setState(() => _isPinned = !_isPinned),
          tooltip: _isPinned ? 'Unpin' : 'Pin',
        ),
        
        // Favorite toggle
        IconButton(
          icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
          color: _isFavorite ? Colors.red : null,
          onPressed: () => setState(() => _isFavorite = !_isFavorite),
          tooltip: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
        ),
        
        // Color picker
        PopupMenuButton<Color?>(
          icon: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _noteColor ?? Colors.grey.shade300,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade400),
            ),
          ),
          onSelected: (color) => setState(() => _noteColor = color),
          itemBuilder: (context) => _noteColors
              .map((color) => PopupMenuItem<Color?>(
                    value: color == Colors.white ? null : color,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                    ),
                  ))
              .toList(),
        ),
        
        // Save button
        if (_hasChanges)
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveNote,
            tooltip: 'Save',
          ),
      ],
    );
  }

  Widget _buildTitleInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        controller: _titleController,
        focusNode: _titleFocusNode,
        style: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          hintText: 'Note title...',
          hintStyle: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade400,
          ),
          border: InputBorder.none,
        ),
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => _contentFocusNode.requestFocus(),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildToolbarButton(Icons.format_bold, () => _toggleFormat(Attribute.bold)),
              _buildToolbarButton(Icons.format_italic, () => _toggleFormat(Attribute.italic)),
              _buildToolbarButton(Icons.format_underlined, () => _toggleFormat(Attribute.underline)),
              const SizedBox(width: 8),
              _buildToolbarButton(Icons.format_list_bulleted, () => _toggleFormat(Attribute.ul)),
              _buildToolbarButton(Icons.format_list_numbered, () => _toggleFormat(Attribute.ol)),
              const SizedBox(width: 8),
              _buildToolbarButton(Icons.format_clear, () => _clearFormatting()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, size: 20),
      onPressed: onPressed,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: const EdgeInsets.all(4),
    );
  }

  void _toggleFormat(Attribute attribute) {
    _quillController.formatSelection(attribute);
  }

  void _clearFormatting() {
    _quillController.formatSelection(Attribute.clone(Attribute.bold, null));
    _quillController.formatSelection(Attribute.clone(Attribute.italic, null));
    _quillController.formatSelection(Attribute.clone(Attribute.underline, null));
  }

  Widget _buildContentEditor() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: QuillEditor.basic(
        controller: _quillController,
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category and tags row
          Row(
            children: [
              // Category
              Expanded(
                child: _buildCategorySelector(),
              ),
              const SizedBox(width: 16),
              // Tags
              Expanded(
                child: _buildTagsInput(),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              // Word count
              Text(
                '${_getWordCount()} words',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              
              const Spacer(),
              
              // Share button
              TextButton.icon(
                onPressed: _shareNote,
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
              
              const SizedBox(width: 8),
              
              // Delete button (if editing)
              if (widget.note != null)
                TextButton.icon(
                  onPressed: _deleteNote,
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return InkWell(
      onTap: _showCategoryPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.folder, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedCategory ?? 'Category',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: _selectedCategory != null
                      ? Colors.black87
                      : Colors.grey.shade600,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsInput() {
    return InkWell(
      onTap: _showTagsDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.label, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _tags.isEmpty
                    ? 'Tags'
                    : _tags.length == 1
                        ? _tags.first
                        : '${_tags.length} tags',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: _tags.isNotEmpty
                      ? Colors.black87
                      : Colors.grey.shade600,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  // Helper methods
  int _getWordCount() {
    final plainText = _quillController.document.toPlainText();
    if (plainText.trim().isEmpty) return 0;
    return plainText.trim().split(RegExp(r'\s+')).length;
  }

  String _getContentAsJson() {
    try {
      return jsonEncode(_quillController.document.toDelta().toJson());
    } catch (e) {
      return _quillController.document.toPlainText();
    }
  }

  // Action methods
  Future<void> _handleBack() async {
    if (_hasChanges) {
      final shouldSave = await _showSaveDialog();
      if (shouldSave == true) {
        await _saveNote();
      } else if (shouldSave == false) {
        if (mounted) Navigator.of(context).pop();
      }
      // If null (cancelled), stay on the page
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _showDiscardDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<bool?> _showSaveDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save changes?'),
        content: const Text('Do you want to save your changes before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveNote() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final notesProvider = Provider.of<NotesProvider>(context, listen: false);
      final title = _titleController.text.trim();
      final content = _getContentAsJson();

      if (widget.note != null) {
        // Update existing note
        final updatedNote = widget.note!.copyWith(
          title: title,
          content: content,
          category: _selectedCategory,
          tags: _tags,
          color: _noteColor,
          isFavorite: _isFavorite,
          isPinned: _isPinned,
          updatedAt: DateTime.now(),
        );
        
        final success = await notesProvider.updateNote(updatedNote);
        if (success) {
          setState(() => _hasChanges = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Note saved')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to save note')),
            );
          }
        }
      } else {
        // Create new note
        final newNote = await notesProvider.createNote(
          title: title,
          content: content,
          category: _selectedCategory,
          tags: _tags,
          color: _noteColor,
        );
        
        if (newNote != null) {
          setState(() => _hasChanges = false);
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to create note')),
            );
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteNote() async {
    if (widget.note == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note? This action cannot be undone.'),
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
      final success = await notesProvider.deleteNote(widget.note!.id);
      
      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  void _shareNote() {
    final title = _titleController.text.trim();
    final content = _quillController.document.toPlainText().trim();
    
    String shareText = '';
    if (title.isNotEmpty) {
      shareText = title;
      if (content.isNotEmpty) {
        shareText += '\n\n$content';
      }
    } else if (content.isNotEmpty) {
      shareText = content;
    } else {
      shareText = 'Empty note';
    }
    
    // Add metadata
    if (_tags.isNotEmpty) {
      shareText += '\n\nTags: ${_tags.map((tag) => '#$tag').join(' ')}';
    }
    
    if (_selectedCategory != null) {
      shareText += '\nCategory: $_selectedCategory';
    }
    
    shareText += '\n\nShared from Crystal Notes';
    
    Share.share(shareText, subject: title.isNotEmpty ? title : 'Note from Crystal');
  }

  void _showCategoryPicker() {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final existingCategories = notesProvider.categories;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Category',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Create new category
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Create New Category'),
                  onTap: () => _showCreateCategoryDialog(),
                ),
                
                // No category option
                ListTile(
                  leading: Icon(
                    Icons.clear,
                    color: _selectedCategory == null ? Theme.of(context).colorScheme.primary : null,
                  ),
                  title: const Text('No Category'),
                  trailing: _selectedCategory == null ? const Icon(Icons.check) : null,
                  onTap: () {
                    setState(() => _selectedCategory = null);
                    Navigator.pop(context);
                  },
                ),
                
                const Divider(),
                
                // Existing categories
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: existingCategories.length,
                    itemBuilder: (context, index) {
                      final category = existingCategories[index];
                      final isSelected = _selectedCategory == category;
                      
                      return ListTile(
                        leading: Icon(
                          Icons.folder,
                          color: isSelected ? Theme.of(context).colorScheme.primary : null,
                        ),
                        title: Text(category),
                        trailing: isSelected ? const Icon(Icons.check) : null,
                        onTap: () {
                          setState(() => _selectedCategory = category);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateCategoryDialog() {
    Navigator.pop(context); // Close category picker
    
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'New Category',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Category name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final categoryName = controller.text.trim();
              if (categoryName.isNotEmpty) {
                setState(() => _selectedCategory = categoryName);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showTagsDialog() {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final existingTags = notesProvider.tags;
    final selectedTags = Set<String>.from(_tags);
    final controller = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            builder: (context, scrollController) => Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Tags',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Add new tag
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: 'Add new tag',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.tag),
                          ),
                          textCapitalization: TextCapitalization.words,
                          onSubmitted: (value) {
                            final tag = value.trim();
                            if (tag.isNotEmpty && !selectedTags.contains(tag)) {
                              setModalState(() => selectedTags.add(tag));
                              controller.clear();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          final tag = controller.text.trim();
                          if (tag.isNotEmpty && !selectedTags.contains(tag)) {
                            setModalState(() => selectedTags.add(tag));
                            controller.clear();
                          }
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Selected tags
                  if (selectedTags.isNotEmpty) ...[
                    Text(
                      'Selected Tags',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedTags.map((tag) => Chip(
                        label: Text('#$tag'),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => setModalState(() => selectedTags.remove(tag)),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Existing tags
                  if (existingTags.isNotEmpty) ...[
                    Text(
                      'Available Tags',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: existingTags.length,
                        itemBuilder: (context, index) {
                          final tag = existingTags[index];
                          final isSelected = selectedTags.contains(tag);
                          
                          return CheckboxListTile(
                            title: Text('#$tag'),
                            value: isSelected,
                            onChanged: (checked) {
                              setModalState(() {
                                if (checked == true) {
                                  selectedTags.add(tag);
                                } else {
                                  selectedTags.remove(tag);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                  
                  // Action buttons
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _tags = selectedTags.toList());
                          Navigator.pop(context);
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
