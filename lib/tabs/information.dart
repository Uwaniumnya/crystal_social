import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;

class EnhancedCollaborativeWritingTab extends StatefulWidget {
  const EnhancedCollaborativeWritingTab({super.key});

  @override
  _EnhancedCollaborativeWritingTabState createState() =>
      _EnhancedCollaborativeWritingTabState();
}

class _EnhancedCollaborativeWritingTabState extends State<EnhancedCollaborativeWritingTab>
    with TickerProviderStateMixin {
  
  // Controllers & State
  final quill.QuillController _controller = quill.QuillController.basic();
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _documentTitleController = TextEditingController();
  
  // Animation Controllers
  late AnimationController _sidebarController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  
  // Animations
  late Animation<double> _sidebarAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  
  // Realtime
  late RealtimeChannel _channel;
  Timer? _autoSaveTimer;
  Timer? _typingTimer;
  
  // Document Management
  String? _currentDocumentId;
  List<Map<String, dynamic>> _documents = [];
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategory;
  
  // Collaboration
  List<Map<String, dynamic>> _collaborators = [];
  List<Map<String, dynamic>> _typingUsers = [];
  Map<String, dynamic>? _currentUser;
  
  // Drawing
  bool _isDrawingMode = false;
  Color _penColor = Colors.black;
  double _penStrokeWidth = 3.0;
  PenStyle _penStyle = PenStyle.solid;
  List<DrawingStroke> _drawingStrokes = [];
  DrawingStroke? _currentStroke;
  
  // UI State
  bool _isSidebarOpen = true;
  bool _isLoading = false;
  bool _isDarkMode = false;
  DocumentView _currentView = DocumentView.editor;
  SortOption _sortOption = SortOption.modified;
  
  // Colors
  final List<Color> _crystalColors = [
    const Color(0xFF8A2BE2), // Blue Violet
    const Color(0xFF9370DB), // Medium Purple
    const Color(0xFFBA55D3), // Medium Orchid
    const Color(0xFFDA70D6), // Orchid
    const Color(0xFFEE82EE), // Violet
    const Color(0xFFDDA0DD), // Plum
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeUser();
    _loadCategories();
    _loadDocuments();
    _startAutoSave();
  }

  void _initializeAnimations() {
    _sidebarController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _sidebarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sidebarController, curve: Curves.easeInOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _sidebarController.forward();
    _fadeController.forward();
    _pulseController.repeat(reverse: true);
  }

  Future<void> _initializeUser() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response = await supabase
            .from('users')
            .select('*')
            .eq('id', user.id)
            .single();
        
        setState(() {
          _currentUser = response;
        });
      }
    } catch (e) {
      debugPrint('Error initializing user: $e');
    }
  }

  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_currentDocumentId != null) {
        _saveDocument();
      }
    });
  }

  Future<void> _loadCategories() async {
    try {
      final response = await supabase
          .from('document_categories')
          .select('*')
          .order('name');
      
      setState(() {
        _categories = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _loadDocuments() async {
    try {
      String query = 'id, title, content, category_id, created_at, updated_at, created_by, collaborators, is_public';
      
      var queryBuilder = supabase.from('documents').select(query);
      
      if (_selectedCategory != null) {
        queryBuilder = queryBuilder.eq('category_id', _selectedCategory!);
      }
      
      // Apply sorting
      final response = await queryBuilder;
      List<Map<String, dynamic>> documents = List<Map<String, dynamic>>.from(response);
      
      // Sort in Dart instead of SQL for better type safety
      switch (_sortOption) {
        case SortOption.title:
          documents.sort((a, b) => (a['title'] ?? '').compareTo(b['title'] ?? ''));
          break;
        case SortOption.created:
          documents.sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
          break;
        case SortOption.modified:
          documents.sort((a, b) => (b['updated_at'] ?? '').compareTo(a['updated_at'] ?? ''));
          break;
      }
      
      setState(() {
        _documents = documents;
      });
    } catch (e) {
      print('Error loading documents: $e');
    }
  }

  Future<void> _createCategory(String name, Color color, IconData icon) async {
    try {
      await supabase.from('document_categories').insert({
        'name': name,
        'color': color.value,
        'icon': icon.codePoint,
        'created_by': _currentUser?['id'],
      });
      
      _loadCategories();
      _showSuccessMessage('Category "$name" created successfully!');
    } catch (e) {
      _showErrorMessage('Error creating category: $e');
    }
  }

  Future<void> _createDocument(String title, String? categoryId) async {
    try {
      final response = await supabase.from('documents').insert({
        'title': title,
        'content': json.encode(_controller.document.toDelta().toJson()),
        'category_id': categoryId,
        'created_by': _currentUser?['id'],
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();
      
      setState(() {
        _currentDocumentId = response['id'];
        _documentTitleController.text = title;
      });
      
      _loadDocuments();
      _subscribeToDocument(response['id']);
      _showSuccessMessage('Document "$title" created successfully!');
    } catch (e) {
      _showErrorMessage('Error creating document: $e');
    }
  }

  Future<void> _loadDocument(String documentId) async {
    try {
      setState(() => _isLoading = true);
      
      final response = await supabase
          .from('documents')
          .select('*')
          .eq('id', documentId)
          .single();
      
      setState(() {
        _currentDocumentId = documentId;
        _documentTitleController.text = response['title'] ?? '';
        
        if (response['content'] != null) {
          _controller.document = quill.Document.fromJson(
            json.decode(response['content']),
          );
        }
        
        if (response['drawing_data'] != null) {
          _loadDrawingData(response['drawing_data']);
        }
        
        _isLoading = false;
      });
      
      _subscribeToDocument(documentId);
      _loadCollaborators(documentId);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('Error loading document: $e');
    }
  }

  void _subscribeToDocument(String documentId) {
    _channel = supabase.channel('document_$documentId')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        table: 'documents',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: documentId,
        ),
        callback: (payload) {
          if (mounted) {
            _handleDocumentUpdate(payload.newRecord);
          }
        },
      )
      .onBroadcast(
        event: 'typing',
        callback: (payload) {
          if (mounted) {
            _handleTypingUpdate(payload);
          }
        },
      )
      .onBroadcast(
        event: 'drawing',
        callback: (payload) {
          if (mounted) {
            _handleDrawingUpdate(payload);
          }
        },
      )
      .subscribe();
  }

  void _handleDocumentUpdate(Map<String, dynamic> data) {
    if (data['content'] != null) {
      setState(() {
        _controller.document = quill.Document.fromJson(
          json.decode(data['content']),
        );
      });
    }
  }

  void _handleTypingUpdate(Map<String, dynamic> payload) {
    final userId = payload['user_id'];
    final isTyping = payload['is_typing'] as bool;
    
    setState(() {
      if (isTyping) {
        if (!_typingUsers.any((u) => u['id'] == userId)) {
          _typingUsers.add({'id': userId, 'name': payload['user_name']});
        }
      } else {
        _typingUsers.removeWhere((u) => u['id'] == userId);
      }
    });
  }

  void _handleDrawingUpdate(Map<String, dynamic> payload) {
    if (payload['stroke_data'] != null) {
      final strokeData = json.decode(payload['stroke_data']);
      final stroke = DrawingStroke.fromJson(strokeData);
      
      setState(() {
        _drawingStrokes.add(stroke);
      });
    }
  }

  Future<void> _loadCollaborators(String documentId) async {
    try {
      final response = await supabase
          .from('document_collaborators')
          .select('user_id, users(id, username, avatar_url)')
          .eq('document_id', documentId);
      
      setState(() {
        _collaborators = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading collaborators: $e');
    }
  }

  Future<void> _saveDocument() async {
    if (_currentDocumentId == null) return;
    
    try {
      await supabase.from('documents').update({
        'content': json.encode(_controller.document.toDelta().toJson()),
        'drawing_data': json.encode(_drawingStrokes.map((s) => s.toJson()).toList()),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', _currentDocumentId!);
    } catch (e) {
      print('Error saving document: $e');
    }
  }

  void _loadDrawingData(String drawingData) {
    try {
      final List<dynamic> strokesJson = json.decode(drawingData);
      setState(() {
        _drawingStrokes = strokesJson.map((s) => DrawingStroke.fromJson(s)).toList();
      });
    } catch (e) {
      print('Error loading drawing data: $e');
    }
  }

  void _broadcastTyping(bool isTyping) {
    if (_currentDocumentId != null) {
      _channel.sendBroadcastMessage(
        event: 'typing',
        payload: {
          'user_id': _currentUser?['id'],
          'user_name': _currentUser?['username'],
          'is_typing': isTyping,
        },
      );
    }
  }

  void _onTextChanged() {
    _broadcastTyping(true);
    
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1000), () {
      _broadcastTyping(false);
    });
    
    if (_currentDocumentId != null) {
      _saveDocument();
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedBuilder(
      animation: _sidebarAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(-300 * (1 - _sidebarAnimation.value), 0),
          child: Container(
            width: 300,
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[900] : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSidebarHeader(),
                _buildCategoryTabs(),
                _buildSearchBar(),
                _buildSortOptions(),
                Expanded(child: _buildDocumentsList()),
                _buildSidebarFooter(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _crystalColors.take(2).toList(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Icon(
                  Icons.auto_stories,
                  color: Colors.white,
                  size: 32,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crystal Docs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Collaborative Writing',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: _showCreateDocumentDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : Colors.grey[800],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.add_circle_outline, size: 20),
                  onPressed: _showCreateCategoryDialog,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip(null, 'All', Icons.folder_open, Colors.grey),
                ..._categories.map((category) => _buildCategoryChip(
                  category['id'],
                  category['name'],
                  IconData(category['icon'], fontFamily: 'MaterialIcons'),
                  Color(category['color']),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String? categoryId, String name, IconData icon, Color color) {
    final isSelected = _selectedCategory == categoryId;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = categoryId;
        });
        _loadDocuments();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? color : Colors.grey),
            const SizedBox(width: 4),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? color : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search documents...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          // Implement search functionality
          _loadDocuments();
        },
      ),
    );
  }

  Widget _buildSortOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            'Sort by:',
            style: TextStyle(
              fontSize: 14,
              color: _isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<SortOption>(
            value: _sortOption,
            underline: const SizedBox(),
            items: SortOption.values.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(
                  option.toString().split('.').last.toUpperCase(),
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _sortOption = value!;
              });
              _loadDocuments();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList() {
    if (_documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No documents yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first document to get started',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        final document = _documents[index];
        final isSelected = _currentDocumentId == document['id'];
        
        return GestureDetector(
          onTap: () => _loadDocument(document['id']),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? _crystalColors.first.withOpacity(0.1)
                  : (_isDarkMode ? Colors.grey[800] : Colors.white),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected 
                    ? _crystalColors.first
                    : Colors.grey.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document['title'] ?? 'Untitled',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isSelected ? _crystalColors.first : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _getDocumentPreview(document['content']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(document['updated_at']),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                    const Spacer(),
                    if (document['collaborators'] != null && 
                        (document['collaborators'] as List).isNotEmpty)
                      Icon(
                        Icons.people,
                        size: 12,
                        color: _crystalColors.first,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          if (_currentUser != null) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: _crystalColors.first,
              child: Text(
                _currentUser!['username']?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _currentUser!['username'] ?? 'User',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_currentDocumentId == null) {
      return _buildWelcomeScreen();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildDocumentHeader(),
          _buildToolbar(),
          Expanded(
            child: Stack(
              children: [
                _buildEditor(),
                if (_isDrawingMode) _buildDrawingCanvas(),
                if (_isLoading) _buildLoadingOverlay(),
              ],
            ),
          ),
          _buildStatusBar(),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Icon(
                  Icons.auto_stories,
                  size: 128,
                  color: _crystalColors.first.withOpacity(0.3),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to Crystal Docs',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: _crystalColors.first,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Create and collaborate on documents in real-time',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showCreateDocumentDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Your First Document'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _crystalColors.first,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[900] : Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _documentTitleController,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: 'Document Title',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                // Auto-save title
                if (_currentDocumentId != null) {
                  Timer(const Duration(milliseconds: 500), () {
                    supabase.from('documents').update({
                      'title': value,
                    }).eq('id', _currentDocumentId!);
                  });
                }
              },
            ),
          ),
          _buildCollaboratorAvatars(),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _showShareDialog,
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: _showDocumentMenu,
          ),
        ],
      ),
    );
  }

  Widget _buildCollaboratorAvatars() {
    if (_collaborators.isEmpty) return const SizedBox.shrink();
    
    return Row(
      children: [
        const SizedBox(width: 8),
        ...List.generate(
          math.min(_collaborators.length, 3),
          (index) {
            final collaborator = _collaborators[index];
            final user = collaborator['users'];
            
            return Container(
              margin: const EdgeInsets.only(left: 4),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: _crystalColors[index % _crystalColors.length],
                child: Text(
                  user['username']?.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
        if (_collaborators.length > 3)
          Container(
            margin: const EdgeInsets.only(left: 4),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[400],
              child: Text(
                '+${_collaborators.length - 3}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[850] : Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          _buildFormatButton(Icons.format_bold, 'bold'),
          _buildFormatButton(Icons.format_italic, 'italic'),
          _buildFormatButton(Icons.format_underlined, 'underline'),
          const SizedBox(width: 16),
          IconButton(
            icon: Icon(Icons.insert_emoticon),
            onPressed: _showEmojiPicker,
            tooltip: 'Insert Emoji',
          ),
          IconButton(
            icon: Icon(
              _isDrawingMode ? Icons.edit : Icons.draw,
              color: _isDrawingMode ? _crystalColors.first : null,
            ),
            onPressed: _toggleDrawingMode,
            tooltip: 'Toggle Drawing Mode',
          ),
          if (_isDrawingMode) ...[
            const SizedBox(width: 8),
            _buildDrawingTools(),
          ],
          const Spacer(),
          _buildViewToggle(),
        ],
      ),
    );
  }

  Widget _buildFormatButton(IconData icon, String format) {
    return IconButton(
      icon: Icon(icon),
      onPressed: () => _formatText(format),
      tooltip: format.toUpperCase(),
    );
  }

  Widget _buildDrawingTools() {
    return Row(
      children: [
        GestureDetector(
          onTap: _showColorPicker,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _penColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Slider(
            value: _penStrokeWidth,
            min: 1.0,
            max: 10.0,
            onChanged: (value) {
              setState(() {
                _penStrokeWidth = value;
              });
            },
          ),
        ),
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: _clearDrawing,
          tooltip: 'Clear Drawing',
        ),
      ],
    );
  }

  Widget _buildViewToggle() {
    return SegmentedButton<DocumentView>(
      segments: [
        ButtonSegment(
          value: DocumentView.editor,
          icon: Icon(Icons.edit),
          label: Text('Edit'),
        ),
        ButtonSegment(
          value: DocumentView.preview,
          icon: Icon(Icons.preview),
          label: Text('Preview'),
        ),
      ],
      selected: {_currentView},
      onSelectionChanged: (views) {
        setState(() {
          _currentView = views.first;
        });
      },
    );
  }

  Widget _buildEditor() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: quill.QuillEditor.basic(
        controller: _controller,
      ),
    );
  }

  Widget _buildDrawingCanvas() {
    return Positioned.fill(
      child: EnhancedDrawingCanvas(
        strokes: _drawingStrokes,
        currentStroke: _currentStroke,
        penColor: _penColor,
        penStrokeWidth: _penStrokeWidth,
        penStyle: _penStyle,
        onStrokeStart: (stroke) {
          setState(() {
            _currentStroke = stroke;
          });
        },
        onStrokeUpdate: (stroke) {
          setState(() {
            _currentStroke = stroke;
          });
        },
        onStrokeEnd: (stroke) {
          setState(() {
            _drawingStrokes.add(stroke);
            _currentStroke = null;
          });
          _broadcastDrawingUpdate(stroke);
        },
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(_crystalColors.first),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[900] : Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          if (_typingUsers.isNotEmpty) ...[
            Icon(
              Icons.edit,
              size: 16,
              color: _crystalColors.first,
            ),
            const SizedBox(width: 4),
            Text(
              '${_typingUsers.map((u) => u['name']).join(', ')} typing...',
              style: TextStyle(
                fontSize: 12,
                color: _crystalColors.first,
                fontStyle: FontStyle.italic,
              ),
            ),
            const Spacer(),
          ] else
            const Spacer(),
          Text(
            'Auto-saved',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.cloud_done,
            size: 16,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  void _showCreateDocumentDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateDocumentDialog(
        categories: _categories,
        onCreateDocument: (title, categoryId) {
          _createDocument(title, categoryId);
        },
      ),
    );
  }

  void _showCreateCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateCategoryDialog(
        onCreateCategory: (name, color, icon) {
          _createCategory(name, color, icon);
        },
      ),
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => EnhancedEmojiPicker(
        onEmojiSelected: (emoji) {
          _controller.replaceText(
            _controller.selection.start,
            0,
            emoji,
            TextSelection.collapsed(offset: _controller.selection.start + emoji.length),
          );
          _onTextChanged();
        },
      ),
    );
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ColorPickerBottomSheet(
        currentColor: _penColor,
        onColorSelected: (color) {
          setState(() {
            _penColor = color;
          });
        },
      ),
    );
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => ShareDocumentDialog(
        documentId: _currentDocumentId!,
        onShare: (userId) {
          // Add collaborator logic
        },
      ),
    );
  }

  void _showDocumentMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => DocumentMenuBottomSheet(
        onExport: _exportDocument,
        onDelete: _deleteDocument,
        onDuplicate: _duplicateDocument,
      ),
    );
  }

  void _toggleDrawingMode() {
    setState(() {
      _isDrawingMode = !_isDrawingMode;
    });
    HapticFeedback.lightImpact();
  }

  void _clearDrawing() {
    setState(() {
      _drawingStrokes.clear();
      _currentStroke = null;
    });
    _saveDocument();
  }

  void _formatText(String format) {
    final selection = _controller.selection;
    if (selection.isCollapsed) return;

    try {
      switch (format) {
        case 'bold':
          _controller.formatSelection(quill.Attribute.bold);
          break;
        case 'italic':
          _controller.formatSelection(quill.Attribute.italic);
          break;
        case 'underline':
          _controller.formatSelection(quill.Attribute.underline);
          break;
      }
      _onTextChanged();
    } catch (e) {
      print('Error formatting text: $e');
    }
  }

  void _broadcastDrawingUpdate(DrawingStroke stroke) {
    if (_currentDocumentId != null) {
      _channel.sendBroadcastMessage(
        event: 'drawing',
        payload: {
          'stroke_data': json.encode(stroke.toJson()),
          'user_id': _currentUser?['id'],
        },
      );
    }
  }

  String _getDocumentPreview(String? content) {
    if (content == null) return 'No content';
    try {
      final doc = quill.Document.fromJson(json.decode(content));
      return doc.toPlainText().trim().replaceAll('\n', ' ');
    } catch (e) {
      return 'Content preview unavailable';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  void _exportDocument() {
    // Implement export functionality
  }

  void _deleteDocument() {
    // Implement delete functionality
  }

  void _duplicateDocument() {
    // Implement duplicate functionality
  }

  @override
  void dispose() {
    _sidebarController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _autoSaveTimer?.cancel();
    _typingTimer?.cancel();
    _channel.unsubscribe();
    _searchController.dispose();
    _categoryController.dispose();
    _documentTitleController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.grey[50],
      body: Row(
        children: [
          if (_isSidebarOpen) _buildSidebar(),
          Expanded(child: _buildMainContent()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isSidebarOpen = !_isSidebarOpen;
          });
          if (_isSidebarOpen) {
            _sidebarController.forward();
          } else {
            _sidebarController.reverse();
          }
        },
        backgroundColor: _crystalColors.first,
        child: Icon(
          _isSidebarOpen ? Icons.chevron_left : Icons.chevron_right,
          color: Colors.white,
        ),
      ),
    );
  }
}

// Supporting Classes and Enums
enum DocumentView { editor, preview }
enum SortOption { title, created, modified }
enum PenStyle { solid, dashed, dotted }

class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final PenStyle style;
  final String id;

  DrawingStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.style,
    required this.id,
  });

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'color': color.value,
      'strokeWidth': strokeWidth,
      'style': style.toString().split('.').last,
      'id': id,
    };
  }

  static DrawingStroke fromJson(Map<String, dynamic> json) {
    return DrawingStroke(
      points: (json['points'] as List)
          .map((p) => Offset(p['x'], p['y']))
          .toList(),
      color: Color(json['color']),
      strokeWidth: json['strokeWidth'],
      style: PenStyle.values.firstWhere(
        (s) => s.toString().split('.').last == json['style'],
        orElse: () => PenStyle.solid,
      ),
      id: json['id'],
    );
  }
}

// Additional Widgets would be defined here...
// For brevity, I'll create the main dialog widgets

class CreateDocumentDialog extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final Function(String title, String? categoryId) onCreateDocument;

  const CreateDocumentDialog({
    super.key,
    required this.categories,
    required this.onCreateDocument,
  });

  @override
  _CreateDocumentDialogState createState() => _CreateDocumentDialogState();
}

class _CreateDocumentDialogState extends State<CreateDocumentDialog> {
  final _titleController = TextEditingController();
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create New Document'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Document Title',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCategoryId,
            decoration: InputDecoration(
              labelText: 'Category (Optional)',
              border: OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: null, child: Text('No Category')),
              ...widget.categories.map((category) => DropdownMenuItem(
                value: category['id'],
                child: Text(category['name']),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategoryId = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.trim().isNotEmpty) {
              widget.onCreateDocument(_titleController.text.trim(), _selectedCategoryId);
              Navigator.pop(context);
            }
          },
          child: Text('Create'),
        ),
      ],
    );
  }
}

class CreateCategoryDialog extends StatefulWidget {
  final Function(String name, Color color, IconData icon) onCreateCategory;

  const CreateCategoryDialog({
    super.key,
    required this.onCreateCategory,
  });

  @override
  _CreateCategoryDialogState createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<CreateCategoryDialog> {
  final _nameController = TextEditingController();
  Color _selectedColor = Colors.blue;
  IconData _selectedIcon = Icons.folder;

  final List<Color> _colors = [
    Colors.blue, Colors.red, Colors.green, Colors.orange,
    Colors.purple, Colors.teal, Colors.pink, Colors.amber,
  ];

  final List<IconData> _icons = [
    Icons.folder, Icons.work, Icons.school, Icons.favorite,
    Icons.star, Icons.lightbulb, Icons.code, Icons.brush,
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create Category'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Category Name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          Text('Color'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _colors.map((color) => GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _selectedColor == color ? Colors.black : Colors.grey,
                    width: _selectedColor == color ? 3 : 1,
                  ),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
          Text('Icon'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _icons.map((icon) => GestureDetector(
              onTap: () => setState(() => _selectedIcon = icon),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedIcon == icon ? _selectedColor : Colors.grey,
                    width: _selectedIcon == icon ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  icon,
                  color: _selectedIcon == icon ? _selectedColor : Colors.grey,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              widget.onCreateCategory(_nameController.text.trim(), _selectedColor, _selectedIcon);
              Navigator.pop(context);
            }
          },
          child: Text('Create'),
        ),
      ],
    );
  }
}

// Additional supporting widgets would be implemented similarly...
class EnhancedDrawingCanvas extends StatefulWidget {
  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;
  final Color penColor;
  final double penStrokeWidth;
  final PenStyle penStyle;
  final Function(DrawingStroke) onStrokeStart;
  final Function(DrawingStroke) onStrokeUpdate;
  final Function(DrawingStroke) onStrokeEnd;

  const EnhancedDrawingCanvas({
    super.key,
    required this.strokes,
    required this.currentStroke,
    required this.penColor,
    required this.penStrokeWidth,
    required this.penStyle,
    required this.onStrokeStart,
    required this.onStrokeUpdate,
    required this.onStrokeEnd,
  });

  @override
  _EnhancedDrawingCanvasState createState() => _EnhancedDrawingCanvasState();
}

class _EnhancedDrawingCanvasState extends State<EnhancedDrawingCanvas> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        final stroke = DrawingStroke(
          points: [details.localPosition],
          color: widget.penColor,
          strokeWidth: widget.penStrokeWidth,
          style: widget.penStyle,
          id: DateTime.now().millisecondsSinceEpoch.toString(),
        );
        widget.onStrokeStart(stroke);
      },
      onPanUpdate: (details) {
        if (widget.currentStroke != null) {
          final updatedStroke = DrawingStroke(
            points: [...widget.currentStroke!.points, details.localPosition],
            color: widget.currentStroke!.color,
            strokeWidth: widget.currentStroke!.strokeWidth,
            style: widget.currentStroke!.style,
            id: widget.currentStroke!.id,
          );
          widget.onStrokeUpdate(updatedStroke);
        }
      },
      onPanEnd: (details) {
        if (widget.currentStroke != null) {
          widget.onStrokeEnd(widget.currentStroke!);
        }
      },
      child: CustomPaint(
        size: Size.infinite,
        painter: EnhancedDrawingPainter(
          widget.strokes,
          widget.currentStroke,
        ),
      ),
    );
  }
}

class EnhancedDrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;

  EnhancedDrawingPainter(this.strokes, this.currentStroke);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    
    // Draw current stroke
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }
  }

  void _drawStroke(Canvas canvas, DrawingStroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = stroke.color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = stroke.strokeWidth
      ..style = PaintingStyle.stroke;

    if (stroke.style == PenStyle.dashed) {
      _drawDashedPath(canvas, stroke.points, paint);
    } else {
      final path = Path();
      path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
      
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      
      canvas.drawPath(path, paint);
    }
  }

  void _drawDashedPath(Canvas canvas, List<Offset> points, Paint paint) {
    // Simple dashed line implementation
    for (int i = 0; i < points.length - 1; i += 2) {
      if (i + 1 < points.length) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Simple implementations for remaining dialogs
class EnhancedEmojiPicker extends StatelessWidget {
  final Function(String) onEmojiSelected;

  const EnhancedEmojiPicker({super.key, required this.onEmojiSelected});

  @override
  Widget build(BuildContext context) {
    final emojis = [
      '😀', '😂', '😍', '😎', '😭', '😡', '👍', '👎', '❤️', '💯', '🔥', '✨',
      '🎉', '🎊', '🎈', '🎁', '🎂', '🎃', '🎄', '🎅', '🎆', '🎇', '🌟', '⭐',
    ];
    
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Choose Emoji', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: emojis.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    onEmojiSelected(emojis[index]);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(emojis[index], style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ColorPickerBottomSheet extends StatelessWidget {
  final Color currentColor;
  final Function(Color) onColorSelected;

  const ColorPickerBottomSheet({
    super.key,
    required this.currentColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.black, Colors.red, Colors.blue, Colors.green,
      Colors.yellow, Colors.purple, Colors.orange, Colors.pink,
      Colors.brown, Colors.grey, Colors.cyan, Colors.lime,
    ];
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Select Pen Color', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: colors.map((color) {
              return GestureDetector(
                onTap: () {
                  onColorSelected(color);
                  Navigator.pop(context);
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: currentColor == color ? Colors.black : Colors.grey,
                      width: currentColor == color ? 3 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class ShareDocumentDialog extends StatelessWidget {
  final String documentId;
  final Function(String) onShare;

  const ShareDocumentDialog({
    super.key,
    required this.documentId,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Share Document'),
      content: Text('Share functionality would be implemented here'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    );
  }
}

class DocumentMenuBottomSheet extends StatelessWidget {
  final VoidCallback onExport;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const DocumentMenuBottomSheet({
    super.key,
    required this.onExport,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.file_download),
            title: Text('Export'),
            onTap: () {
              Navigator.pop(context);
              onExport();
            },
          ),
          ListTile(
            leading: Icon(Icons.copy),
            title: Text('Duplicate'),
            onTap: () {
              Navigator.pop(context);
              onDuplicate();
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
        ],
      ),
    );
  }
}
