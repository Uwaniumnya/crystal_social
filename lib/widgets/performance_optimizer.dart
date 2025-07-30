import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// Performance optimization utilities for Crystal Social widgets
class WidgetPerformanceOptimizer {
  
  /// Optimized ListView builder for large lists
  static Widget optimizedListView({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    ScrollController? controller,
    bool shrinkWrap = false,
    EdgeInsets? padding,
  }) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      controller: controller,
      shrinkWrap: shrinkWrap,
      padding: padding,
      // Performance optimizations
      cacheExtent: 500.0, // Cache 500 pixels above/below viewport
      addAutomaticKeepAlives: false, // Don't keep items alive unnecessarily
      addRepaintBoundaries: true, // Isolate repaints
      addSemanticIndexes: true, // Better accessibility
    );
  }
  
  /// Optimized GridView builder for image grids
  static Widget optimizedGridView({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    required SliverGridDelegate gridDelegate,
    ScrollController? controller,
    bool shrinkWrap = false,
    EdgeInsets? padding,
  }) {
    return GridView.builder(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      gridDelegate: gridDelegate,
      controller: controller,
      shrinkWrap: shrinkWrap,
      padding: padding,
      // Performance optimizations
      cacheExtent: 1000.0, // Larger cache for grids
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      addSemanticIndexes: true,
    );
  }
  
  /// Memory-efficient image widget with caching
  static Widget optimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    bool enableMemoryCache = true,
  }) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      // Performance optimizations
      cacheWidth: width?.round(),
      cacheHeight: height?.round(),
      errorBuilder: errorWidget != null 
        ? (context, error, stackTrace) => errorWidget
        : null,
      loadingBuilder: placeholder != null
        ? (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return placeholder;
          }
        : null,
      // Memory management
      isAntiAlias: true,
      filterQuality: FilterQuality.medium,
    );
  }
  
  /// Debounced search input to prevent excessive API calls
  static Widget debouncedSearchField({
    required ValueChanged<String> onSearchChanged,
    String? hintText,
    Duration debounceTime = const Duration(milliseconds: 500),
    TextEditingController? controller,
  }) {
    return _DebouncedSearchField(
      onSearchChanged: onSearchChanged,
      hintText: hintText,
      debounceTime: debounceTime,
      controller: controller,
    );
  }
  
  /// Lazy loading container for expensive widgets
  static Widget lazyWidget({
    required Widget Function() builder,
    Widget? placeholder,
    bool condition = true,
  }) {
    if (!condition) {
      return placeholder ?? const SizedBox.shrink();
    }
    
    return _LazyWidget(
      builder: builder,
      placeholder: placeholder,
    );
  }
  
  /// Performance monitoring wrapper (debug only)
  static Widget performanceMonitor({
    required Widget child,
    String? name,
  }) {
    if (kDebugMode && name != null) {
      return _PerformanceMonitor(
        name: name,
        child: child,
      );
    }
    return child;
  }
}

/// Debounced search field implementation
class _DebouncedSearchField extends StatefulWidget {
  final ValueChanged<String> onSearchChanged;
  final String? hintText;
  final Duration debounceTime;
  final TextEditingController? controller;
  
  const _DebouncedSearchField({
    required this.onSearchChanged,
    this.hintText,
    required this.debounceTime,
    this.controller,
  });
  
  @override
  State<_DebouncedSearchField> createState() => _DebouncedSearchFieldState();
}

class _DebouncedSearchFieldState extends State<_DebouncedSearchField> {
  late TextEditingController _controller;
  Timer? _debounceTimer;
  
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }
  
  void _onTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceTime, () {
      widget.onSearchChanged(_controller.text);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Lazy loading widget implementation
class _LazyWidget extends StatefulWidget {
  final Widget Function() builder;
  final Widget? placeholder;
  
  const _LazyWidget({
    required this.builder,
    this.placeholder,
  });
  
  @override
  State<_LazyWidget> createState() => _LazyWidgetState();
}

class _LazyWidgetState extends State<_LazyWidget> {
  Widget? _cachedWidget;
  bool _isBuilt = false;
  
  @override
  Widget build(BuildContext context) {
    if (!_isBuilt) {
      // Build widget on first access
      _cachedWidget = widget.builder();
      _isBuilt = true;
    }
    
    return _cachedWidget ?? (widget.placeholder ?? const SizedBox.shrink());
  }
}

/// Performance monitoring widget (debug only)
class _PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final String name;
  
  const _PerformanceMonitor({
    required this.child,
    required this.name,
  });
  
  @override
  State<_PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<_PerformanceMonitor> {
  late Stopwatch _stopwatch;
  
  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _stopwatch.stop();
      debugPrint('Widget "${widget.name}" build time: ${_stopwatch.elapsedMilliseconds}ms');
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
