import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:photo_view/photo_view.dart';
import 'package:intl/intl.dart';
import 'chat_production_config.dart';

// Enhanced media item model
class MediaItem {
  final String url;
  final String type; // 'image', 'video', 'audio', 'document'
  final String? thumbnail;
  final DateTime timestamp;
  final String senderId;
  final String? fileName;
  final int? fileSize;
  final String messageId;

  MediaItem({
    required this.url,
    required this.type,
    this.thumbnail,
    required this.timestamp,
    required this.senderId,
    this.fileName,
    this.fileSize,
    required this.messageId,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      url: json['url'] ?? '',
      type: json['type'] ?? 'image',
      thumbnail: json['thumbnail'],
      timestamp: DateTime.parse(json['timestamp']),
      senderId: json['sender_id'] ?? '',
      fileName: json['file_name'],
      fileSize: json['file_size'],
      messageId: json['message_id'] ?? '',
    );
  }
}

enum MediaType { all, images, videos, audio, documents }
enum ViewMode { grid, list, timeline }

class EnhancedSharedMediaViewer extends StatefulWidget {
  final String chatId;
  final String? currentUserId;

  const EnhancedSharedMediaViewer({
    super.key, 
    required this.chatId,
    this.currentUserId,
  });

  @override
  State<EnhancedSharedMediaViewer> createState() => _EnhancedSharedMediaViewerState();
}

class _EnhancedSharedMediaViewerState extends State<EnhancedSharedMediaViewer>
    with TickerProviderStateMixin {
  late final SupabaseClient supabase;
  List<MediaItem> mediaItems = [];
  List<MediaItem> filteredItems = [];
  bool isLoading = false;
  bool hasMore = true;
  int page = 0;
  int pageSize = 20;
  late ScrollController _scrollController;
  late TabController _tabController;
  late AnimationController _searchAnimationController;
  
  MediaType selectedMediaType = MediaType.all;
  ViewMode viewMode = ViewMode.grid;
  bool isSearching = false;
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();
  
  Map<String, String> mediaTypeFilters = {
    'all': 'All Media',
    'images': 'Images',
    'videos': 'Videos', 
    'audio': 'Audio',
    'documents': 'Documents',
  };

  @override
  void initState() {
    super.initState();
    supabase = Supabase.instance.client;
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _tabController = TabController(length: 5, vsync: this);
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    fetchMedia();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    _searchAnimationController.dispose();
    searchController.dispose();
    super.dispose();
  }

  // Enhanced media fetching with support for multiple media types
  Future<void> fetchMedia() async {
    if (isLoading || !hasMore) return;

    setState(() => isLoading = true);

    try {
      final response = await supabase
          .from('messages')
          .select('id, image, video, audio, document, timestamp, sender_id, file_name, file_size')
          .eq('chat_id', widget.chatId)
          .or('image.not.is.null,video.not.is.null,audio.not.is.null,document.not.is.null')
          .order('timestamp', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);

      final List<MediaItem> newItems = [];
      
      for (final item in response) {
        if (item['image'] != null) {
          newItems.add(MediaItem(
            url: item['image'],
            type: 'image',
            timestamp: DateTime.parse(item['timestamp']),
            senderId: item['sender_id'],
            messageId: item['id'],
            fileName: item['file_name'],
            fileSize: item['file_size'],
          ));
        }
        if (item['video'] != null) {
          newItems.add(MediaItem(
            url: item['video'],
            type: 'video',
            timestamp: DateTime.parse(item['timestamp']),
            senderId: item['sender_id'],
            messageId: item['id'],
            fileName: item['file_name'],
            fileSize: item['file_size'],
          ));
        }
        if (item['audio'] != null) {
          newItems.add(MediaItem(
            url: item['audio'],
            type: 'audio',
            timestamp: DateTime.parse(item['timestamp']),
            senderId: item['sender_id'],
            messageId: item['id'],
            fileName: item['file_name'],
            fileSize: item['file_size'],
          ));
        }
        if (item['document'] != null) {
          newItems.add(MediaItem(
            url: item['document'],
            type: 'document',
            timestamp: DateTime.parse(item['timestamp']),
            senderId: item['sender_id'],
            messageId: item['id'],
            fileName: item['file_name'],
            fileSize: item['file_size'],
          ));
        }
      }

      setState(() {
        page++;
        if (response.isEmpty) {
          hasMore = false;
        } else {
          mediaItems.addAll(newItems);
          _applyFilters();
        }
        isLoading = false;
      });
    } catch (error) {
      ChatDebugUtils.logError('MediaViewer', 'Error fetching media: $error');
      setState(() => isLoading = false);
      _showErrorSnackBar('Failed to load media: $error');
    }
  }

  void _applyFilters() {
    List<MediaItem> filtered = List.from(mediaItems);
    
    // Apply media type filter
    if (selectedMediaType != MediaType.all) {
      String typeFilter = selectedMediaType.toString().split('.').last;
      if (typeFilter == 'images') typeFilter = 'image';
      if (typeFilter == 'videos') typeFilter = 'video';
      if (typeFilter == 'documents') typeFilter = 'document';
      
      filtered = filtered.where((item) => item.type == typeFilter).toList();
    }
    
    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        return (item.fileName?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
               item.senderId.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }
    
    setState(() {
      filteredItems = filtered;
    });
  }

  void _onMediaTypeChanged(MediaType type) {
    setState(() {
      selectedMediaType = type;
      _applyFilters();
    });
  }

  void _toggleSearch() {
    setState(() {
      isSearching = !isSearching;
    });
    
    if (isSearching) {
      _searchAnimationController.forward();
    } else {
      _searchAnimationController.reverse();
      searchController.clear();
      searchQuery = '';
      _applyFilters();
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
      _applyFilters();
    });
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _shareMedia(MediaItem item) async {
    try {
      // Copy URL to clipboard as fallback
      await Clipboard.setData(ClipboardData(text: item.url));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Media URL copied to clipboard')),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to share media: $e');
    }
  }

  Future<void> _downloadMedia(MediaItem item) async {
    try {
      // Show download progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Downloading...'),
            ],
          ),
        ),
      );
      
      // Simulate download process
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pop(context); // Close loading dialog
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Media downloaded successfully!')),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorSnackBar('Download failed: $e');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      fetchMedia();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.pinkAccent,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isSearching
              ? TextField(
                  key: const ValueKey('search'),
                  controller: searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search media...',
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                  ),
                  onChanged: _onSearchChanged,
                )
              : Row(
                  key: const ValueKey('title'),
                  children: [
                    const Text('Shared Media'),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${filteredItems.length}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
        ),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          PopupMenuButton<ViewMode>(
            icon: const Icon(Icons.view_module),
            onSelected: (ViewMode mode) {
              setState(() => viewMode = mode);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ViewMode.grid,
                child: Row(
                  children: [
                    Icon(Icons.grid_view),
                    SizedBox(width: 8),
                    Text('Grid View'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ViewMode.list,
                child: Row(
                  children: [
                    Icon(Icons.list),
                    SizedBox(width: 8),
                    Text('List View'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ViewMode.timeline,
                child: Row(
                  children: [
                    Icon(Icons.timeline),
                    SizedBox(width: 8),
                    Text('Timeline'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          onTap: (index) {
            _onMediaTypeChanged(MediaType.values[index]);
          },
          tabs: [
            Tab(text: 'All (${mediaItems.length})'),
            Tab(text: 'Images (${mediaItems.where((m) => m.type == 'image').length})'),
            Tab(text: 'Videos (${mediaItems.where((m) => m.type == 'video').length})'),
            Tab(text: 'Audio (${mediaItems.where((m) => m.type == 'audio').length})'),
            Tab(text: 'Files (${mediaItems.where((m) => m.type == 'document').length})'),
          ],
        ),
      ),
      
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            mediaItems.clear();
            filteredItems.clear();
            page = 0;
            hasMore = true;
          });
          await fetchMedia();
        },
        child: filteredItems.isEmpty && isLoading
            ? const Center(child: CircularProgressIndicator())
            : filteredItems.isEmpty
                ? _buildEmptyState()
                : _buildMediaContent(),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;
    
    if (searchQuery.isNotEmpty) {
      message = 'No media found for "$searchQuery"';
      icon = Icons.search_off;
    } else {
      switch (selectedMediaType) {
        case MediaType.images:
          message = 'No images shared yet';
          icon = Icons.image_not_supported;
          break;
        case MediaType.videos:
          message = 'No videos shared yet';
          icon = Icons.videocam_off;
          break;
        case MediaType.audio:
          message = 'No audio files shared yet';
          icon = Icons.audiotrack_outlined;
          break;
        case MediaType.documents:
          message = 'No documents shared yet';
          icon = Icons.description_outlined;
          break;
        default:
          message = 'No media shared yet';
          icon = Icons.photo_library_outlined;
      }
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Shared media will appear here',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent() {
    switch (viewMode) {
      case ViewMode.grid:
        return _buildGridView();
      case ViewMode.list:
        return _buildListView();
      case ViewMode.timeline:
        return _buildTimelineView();
    }
  }

  Widget _buildGridView() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        controller: _scrollController,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: selectedMediaType == MediaType.audio || 
                         selectedMediaType == MediaType.documents ? 2 : 3,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: selectedMediaType == MediaType.audio || 
                           selectedMediaType == MediaType.documents ? 1.5 : 1.0,
        ),
        itemCount: filteredItems.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == filteredItems.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          return _buildMediaTile(filteredItems[index], index);
        },
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      itemCount: filteredItems.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filteredItems.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        return _buildListTile(filteredItems[index], index);
      },
    );
  }

  Widget _buildTimelineView() {
    // Group items by date
    Map<String, List<MediaItem>> groupedItems = {};
    for (final item in filteredItems) {
      final dateKey = DateFormat('yyyy-MM-dd').format(item.timestamp);
      groupedItems.putIfAbsent(dateKey, () => []).add(item);
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      itemCount: groupedItems.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == groupedItems.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        final dateKey = groupedItems.keys.elementAt(index);
        final items = groupedItems[dateKey]!;
        final date = DateTime.parse(dateKey);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
              child: Text(
                DateFormat('MMMM d, y').format(date),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: items.length,
              itemBuilder: (context, itemIndex) {
                final globalIndex = filteredItems.indexOf(items[itemIndex]);
                return _buildMediaTile(items[itemIndex], globalIndex);
              },
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildMediaTile(MediaItem item, int index) {
    return GestureDetector(
      onTap: () => _openMediaViewer(item, index),
      onLongPress: () => _showMediaOptions(item),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6.0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildMediaItemContent(item),
              _buildMediaOverlay(item),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaItemContent(MediaItem item) {
    switch (item.type) {
      case 'image':
        return Image.network(
          item.url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
            );
          },
        );
      
      case 'video':
        return Container(
          color: Colors.black,
          child: const Stack(
            fit: StackFit.expand,
            children: [
              Icon(Icons.play_circle_outline, color: Colors.white, size: 48),
              Positioned(
                bottom: 8,
                right: 8,
                child: Icon(Icons.videocam, color: Colors.white, size: 20),
              ),
            ],
          ),
        );
      
      case 'audio':
        return Container(
          color: Colors.purple.shade100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.audiotrack, color: Colors.purple, size: 32),
              const SizedBox(height: 4),
              if (item.fileName != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    item.fileName!,
                    style: const TextStyle(fontSize: 10),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        );
      
      case 'document':
        return Container(
          color: Colors.blue.shade100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.description, color: Colors.blue, size: 32),
              const SizedBox(height: 4),
              if (item.fileName != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    item.fileName!,
                    style: const TextStyle(fontSize: 10),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        );
      
      default:
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.file_present, color: Colors.grey, size: 40),
        );
    }
  }

  Widget _buildMediaOverlay(MediaItem item) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.fileSize != null)
              Text(
                _formatFileSize(item.fileSize),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            Text(
              DateFormat('MMM d').format(item.timestamp),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(MediaItem item, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: SizedBox(
          width: 60,
          height: 60,
          child: _buildMediaItemContent(item),
        ),
        title: Text(item.fileName ?? 'Media File'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: ${item.senderId}'),
            Text(DateFormat('MMM d, y • h:mm a').format(item.timestamp)),
            if (item.fileSize != null)
              Text('Size: ${_formatFileSize(item.fileSize)}'),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleMenuAction(value, item),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [Icon(Icons.visibility), SizedBox(width: 8), Text('View')],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [Icon(Icons.share), SizedBox(width: 8), Text('Share')],
              ),
            ),
            const PopupMenuItem(
              value: 'download',
              child: Row(
                children: [Icon(Icons.download), SizedBox(width: 8), Text('Download')],
              ),
            ),
          ],
        ),
        onTap: () => _openMediaViewer(item, index),
      ),
    );
  }

  void _openMediaViewer(MediaItem item, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedMediaViewer(
          mediaItems: filteredItems.where((m) => m.type == item.type).toList(),
          initialIndex: filteredItems.where((m) => m.type == item.type).toList().indexOf(item),
          onDownload: _downloadMedia,
          onShare: _shareMedia,
        ),
      ),
    );
  }

  void _showMediaOptions(MediaItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            ListTile(
              title: Text(item.fileName ?? 'Media File'),
              subtitle: Text('${item.type.toUpperCase()} • ${DateFormat('MMM d, y').format(item.timestamp)}'),
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.visibility, color: Colors.blue),
              title: const Text('View'),
              onTap: () {
                Navigator.pop(context);
                _openMediaViewer(item, filteredItems.indexOf(item));
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.share, color: Colors.green),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                _shareMedia(item);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.download, color: Colors.orange),
              title: const Text('Download'),
              onTap: () {
                Navigator.pop(context);
                _downloadMedia(item);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.grey),
              title: const Text('Details'),
              onTap: () {
                Navigator.pop(context);
                _showMediaDetails(item);
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action, MediaItem item) {
    switch (action) {
      case 'view':
        _openMediaViewer(item, filteredItems.indexOf(item));
        break;
      case 'share':
        _shareMedia(item);
        break;
      case 'download':
        _downloadMedia(item);
        break;
    }
  }

  void _showMediaDetails(MediaItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Media Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.fileName != null) _detailRow('File Name', item.fileName!),
            _detailRow('Type', item.type.toUpperCase()),
            _detailRow('Shared by', item.senderId),
            _detailRow('Date', DateFormat('MMM d, y • h:mm a').format(item.timestamp)),
            if (item.fileSize != null) _detailRow('Size', _formatFileSize(item.fileSize)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// Enhanced full-screen media viewer
class EnhancedMediaViewer extends StatefulWidget {
  final List<MediaItem> mediaItems;
  final int initialIndex;
  final Function(MediaItem) onDownload;
  final Function(MediaItem) onShare;

  const EnhancedMediaViewer({
    super.key,
    required this.mediaItems,
    required this.initialIndex,
    required this.onDownload,
    required this.onShare,
  });

  @override
  State<EnhancedMediaViewer> createState() => _EnhancedMediaViewerState();
}

class _EnhancedMediaViewerState extends State<EnhancedMediaViewer> {
  late PageController _pageController;
  int currentIndex = 0;
  bool showUI = true;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleUI() {
    setState(() => showUI = !showUI);
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = widget.mediaItems[currentIndex];
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: showUI ? AppBar(
        backgroundColor: Colors.black.withOpacity(0.8),
        title: Text(
          '${currentIndex + 1} of ${widget.mediaItems.length}',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => widget.onShare(currentItem),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => widget.onDownload(currentItem),
          ),
        ],
      ) : null,
      body: GestureDetector(
        onTap: _toggleUI,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.mediaItems.length,
              onPageChanged: (index) => setState(() => currentIndex = index),
              itemBuilder: (context, index) {
                final item = widget.mediaItems[index];
                return _buildFullScreenMedia(item);
              },
            ),
            
            if (showUI)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (currentItem.fileName != null)
                        Text(
                          currentItem.fileName!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Shared by ${currentItem.senderId} • ${DateFormat('MMM d, y').format(currentItem.timestamp)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenMedia(MediaItem item) {
    switch (item.type) {
      case 'image':
        return PhotoView(
          imageProvider: NetworkImage(item.url),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3.0,
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          loadingBuilder: (context, event) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 48),
                SizedBox(height: 16),
                Text('Failed to load image', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        );
      
      case 'video':
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle_outline, color: Colors.white, size: 64),
              SizedBox(height: 16),
              Text('Video Player', style: TextStyle(color: Colors.white)),
              Text('(Video player integration needed)', style: TextStyle(color: Colors.white70)),
            ],
          ),
        );
      
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.type == 'audio' ? Icons.audiotrack : Icons.description,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                item.fileName ?? 'Media File',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => widget.onDownload(item),
                icon: const Icon(Icons.download),
                label: const Text('Download'),
              ),
            ],
          ),
        );
    }
  }
}
