import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// Enhanced Emoticon Picker with categories, search, favorites, animations, creation, and cloud sync
class EnhancedEmoticonPicker extends StatefulWidget {
  final Function(String)? onEmoticonSelected;
  final Function(String)? onEmoticonCopied;
  final Function(String)? onEmoticonCreated;
  final bool showCategories;
  final bool showSearch;
  final bool showFavorites;
  final bool showRecentlyUsed;
  final bool enableCreation;
  final bool enableCloudSync;
  final String? userId;
  final String? initialCategory;
  final Color? primaryColor;
  final Color? backgroundColor;

  const EnhancedEmoticonPicker({
    super.key,
    this.onEmoticonSelected,
    this.onEmoticonCopied,
    this.onEmoticonCreated,
    this.showCategories = true,
    this.showSearch = true,
    this.showFavorites = true,
    this.showRecentlyUsed = true,
    this.enableCreation = true,
    this.enableCloudSync = false,
    this.userId,
    this.initialCategory,
    this.primaryColor,
    this.backgroundColor,
  });

  @override
  State<EnhancedEmoticonPicker> createState() => _EnhancedEmoticonPickerState();
}

class _EnhancedEmoticonPickerState extends State<EnhancedEmoticonPicker>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _favorites = <String>{};
  final List<String> _recentlyUsed = <String>[];
  final List<String> _customEmoticons = <String>[];
  String _searchQuery = '';
  String _selectedCategory = 'Happy';
  bool _isLoading = false;
  bool _isSyncing = false;

  // Categorized emoticons for better organization
  static const Map<String, List<String>> _categorizedEmoticons = {
    'Happy': [
      '(•‿•)', '(◑‿◐)', '٩(◕‿◕)۶', '(ツ)', '(っ˘ڡ˘ς)', '( ๑‾̀◡‾́)σ',
      '(✪㉨✪)', '(๏ᆺ๏υ)', 'ʘ‿ʘ', '(＾▽＾)', '(•̩̥̀‿•̩̥̀✿)', '(ᴗᵔᴥᵔ)',
      '(◕ᗜ◕)', '(✿╹◡╹)', '(˃ᆺ˂✿)', '٩( ᗒᗨᗕ )۶', '(✿〇∀〇)', '(〃ω〃)',
      'ꉂ (´∀｀)ʱªʱªʱª', '( ^_^)／', '(*￣Ｏ￣)ノ', 'Good ヽ(o≧ω≦o)ﾉ Morning ﾟ.:｡+ﾟ',
      '( ◕‿◕)', '(◠‿◠)', '(¬‿¬)', '(⌒‿⌒)', '(´∀｀)', '(╯✧▽✧)╯',
    ],
    'Love': [
      '(づ ◕‿◕ )づ', '（。ˇ ⊖ˇ）♡', '( ♥ ͜ʖ ♥)', '(>‿♥)', '(♥ω♥*)',
      '( ﾟ∀ﾟ)ﾉ【I LOVE U】', '❤️ (•́ ω •̀๑)', '( ͡♥ 3 ͡♥)', '( ˘ ³˘)♥',
      '★⌒ヽ( ͡° ε ͡°)♥', '(♡‿♡)', '(♡°▽°♡)', '♡(˃͈ દ ˂͈ ༶ )', '(´∀｀)♡',
      '(◍•ᴗ•◍)❤', '♡(˃͈ દ ˂͈ ༶ )', '(˘▾˘)♡', '(ღ˘⌣˘ღ)', '♡(◡ ‿ ◡)',
      '(つ ♡ ͜ʖ ♡)つ', '(人 •͈ᴗ•͈)', '( ˶ˆ꒳ˆ˵ )', '♡(.◜ω◝.)♡',
    ],
    'Funny': [
      '( ͡° ͜ʖ ͡°)', '(≖ ͜ʖ≖)', '(☭ ͜ʖ ☭)', '(⌐▀͡ ̯ʖ▀)', '(¬‿¬)',
      '( ✧≖ ͜ʖ≖)', '¯\\_(ツ)_/¯', '┐_㋡_┌', '└(・。・)┘', '( ͡~ ͜ʖ ͡° )',
      '(~_^)', '◕‿↼)', '(^_-)-☆', '★~(◠‿◕✿)', '⊂(▀¯▀⊂ )', '(⌐▨_▨)',
      '◪_◪', '( ノ・・)ノ', '¯\\_(ಠ_ಠ)_/¯', '(╯°□°）╯︵ ┻━┻', '┬─┬ノ( º _ ºノ)',
      '(ಠ_ಠ)', '(¬_¬)', '( ͠° ͟ʖ ͠°)', '(▰˘◡˘▰)', '(☞ﾟヮﾟ)☞',
    ],
    'Sad': [
      'ಥ‿ಥ', '(ᗒᗣᗕ)՞', 'ू(ʚ̴̶̷́ .̠ ʚ̴̶̷̥̀ ू)', '(´⊙ω⊙`)！', '(⋟﹏⋞)',
      '༼☯﹏☯༽', '(◞‸◟ㆀ)', 'ᇂ_ᇂ', '(ಥ ͜ʖಥ)', '● ﹏ ●', '(◡︵◡)',
      'Sorry (◞‸◟ㆀ)', 'ʱªʱªʱª(˃̣̣̥˂̣̣̥)', '( ′～‵ )', '(・_・;)',
      '(つд⊂)', '(╥﹏╥)', '(´;ω;`)', '(｡•́︿•̀｡)', '(ᵕ̣̣̣̣̣̣﹏ᵕ̣̣̣̣̣̣)',
      '(╯︵╰)', '(个_个)', '(╥﹏╥)', '(;へ:)', '(｡╯︵╰｡)',
    ],
    'Cool': [
      'ᕙ(⇀‸↼‶)ᕗ', '(シ_ _)シ', 'm(_ _)m', '┏ ( ˘ω˘ )┛', '(◣_◢)',
      '┌∩┐(◣_◢)┌∩┐', '（＞д＜）', '( ⋋ · ⋌ ) very anger', 'ಠ ''ಠ', 'ಠ෴ಠ',
      '(￣￢￣ヾ)', '（￣ ｗ￣) ', '╭( ๐_๐)╮', '(⚆ᗝ⚆)', '(⁰ ◕〜◕ ⁰)',
      '(▀̿Ĺ̯▀̿ ̿)', '( ͡°( ͡° ͜ʖ( ͡° ͜ʖ ͡°)ʖ ͡°) ͡°)', '(╯°□°）╯︵ ┻━┻',
      '(¬‿¬)', '(￣ー￣)', '(-_-)', 'ಠ_ಠ', '(｡◕‿◕｡)', '¯\\_(ツ)_/¯',
    ],
    'Animals': [
      'ʕ̡̢̡ʘ̅͟͜͡ʘ̲̅ʔ̢̡̢', '=＾● ⋏ ●＾=', '（ΦωΦ）', '▼・ᴥ・▼', 'ʕっ•ᴥ•ʔっ',
      'V✪ω✪V', 'V✪⋏✪V', '(❍ᴥ❍ʋ)', '=^∇^*', '(=˃ᆺ˂=)', 'ᶠᵉᵉᵈ ᵐᵉ /ᐠ-ⱉ-ᐟ\\ﾉ',
      'ʕ´• ᴥ•̥`ʔ', 'ʕ/ ·ᴥ·ʔ/', '(=^‥^=)', '(^._.^)ﾉ', '₍˄·͈༝·͈˄₎◞ ̑̑',
      'ʕ •ᴥ•ʔ', '(´・ω・`)', '◉_◉', '(°o°)', '(◐‿◑)﻿', '(ﾟДﾟ)',
      '(=ↀωↀ=)', 'ฅ^•ﻌ•^ฅ', '(^◡^)', '◔◡◔', 'ʕ◉.◉ʔ',
    ],
    'Special': [
      '(-‿◦☀)', '( ˇ෴ˇ )', '༼ つ ‿ ༽つ╰⋃╯', 'ε=ε=ε=ε=(ノ*´Д｀)ノ', '(ノ*´Д｀)ノ',
      '༼ຈل͜ຈ༽', '༼ ͡ಠ ͜ʖ ͡ಠ ༽', 'ヽ༼ ͠ ͡° ͜ʖ ͡° ༽ﾉ', '༼ ♛‿♛ ༽',
      '༼ °👅 ͡°༽', 'ʕ༼◕ ౪ ◕✿༽ʔ', '༼ ͒ ̶ ͒ ༽', '( ︶｡︶✽)',
      'Zzz..(ˇ㉨ˇ๑) Good night☆', '〜ɢᵒᵒᵈ ɴⁱᵍᵗʰ( ᵕᴗᵕ)*･☪︎·̩͙',
      '(◔_◔)🍔🍕', '༼つ ◕_◕ ༽つ', 'ლ(◕ω◕ლ)', '(¬_¬)ﾉ', '(－_－) zzZ',
      '(●´⌓`●)', '(˵¯͒〰¯͒˵)', '(,,◕　⋏　◕,,)', '(´つヮ⊂)', '( ͡°⁄ ⁄ ͜⁄ ⁄ʖ⁄ ⁄ ͡°)',
    ],
    'Actions': [
      'ᕙ(⇀‸↼‶)ᕗ', '(づ ◕‿◕ )づ', '༼つ ◕_◕ ༽つ', 'ლ(◕ω◕ლ)', '( ^_^)／',
      '(¬_¬)ﾉ', '(*￣Ｏ￣)ノ', '┏ ( ˘ω˘ )┛', '(ノ*´Д｀)ノ', '( ノ・・)ノ',
      '└(・。・)┘', 'm(_ _)m', '(シ_ _)シ', '(╯°□°）╯︵ ┻━┻', '┬─┬ノ( º _ ºノ)',
      '¯\\_(ツ)_/¯', '┐_㋡_┌', '⊂(▀¯▀⊂ )', '(⌐▨_▨)', '◪_◪',
      '(☞ﾟヮﾟ)☞', '☜(ﾟヮﾟ☜)', '(งᵔ ͜ʖᵔ)ง', '(ง •̀_•́)ง', '(ง°ل͜°)ง',
      '＼(^o^)／', 'ヽ(´▽`)/', '٩( ᗒᗨᗕ )۶', '\\o/', '╰( ͡° ͜ʖ ͡° )つ──☆*:・ﾟ',
    ],
    'Custom': [], // Will be populated with user-created emoticons
  };

  static const List<String> _allEmoticons = [
    // Flattened list for search functionality
    '(•‿•)', '(◑‿◐)', '(-‿◦☀)', 'ಥ‿ಥ', '(づ ◕‿◕ )づ', '٩(◕‿◕)۶',
    '( ˇ෴ˇ )', '(ツ)', 'ᕙ(⇀‸↼‶)ᕗ', '(っ˘ڡ˘ς)', '( ๑‾̀◡‾́)σ',
    'ʕ̡̢̡ʘ̅͟͜͡ʘ̲̅ʔ̢̡̢', '(✪㉨✪)', '(๏ᆺ๏υ)', '(✦థ ｪ థ)', '=＾● ⋏ ●＾=',
    '（ΦωΦ）', '(●´⌓`●)', '(シ_ _)シ', 'm(_ _)m', '(ᗒᗣᗕ)՞',
    'ू(ʚ̴̶̷́ .̠ ʚ̴̶̷̥̀ ू)', '(´⊙ω⊙`)！', '(˵¯͒〰¯͒˵)', '(,,◕　⋏　◕,,)',
    '（。ˇ ⊖ˇ）♡', 'ʘ‿ʘ', '( ͡° ͜ʖ ͡° )', '(－_－) zzZ', '༼ つ ‿ ༽つ╰⋃╯',
    '(≖ ͜ʖ≖)', '(☭ ͜ʖ ☭)', '(ु*´З`)ू', '( ͡♥ 3 ͡♥)', '( ˘ ³˘)♥',
    '★⌒ヽ( ͡° ε ͡°)♥', 'ε=ε=ε=ε=(ノ*´Д｀)ノ', '(ノ*´Д｀)ノ', '┏ ( ˘ω˘ )┛',
    '( ͡~ ͜ʖ ͡° )', '(~_^)', '◕‿↼)', '(^_-)-☆', '★~(◠‿◕✿)', '(⌐▀͡ ̯ʖ▀)',
    '⊂(▀¯▀⊂ )', '(⌐▨_▨)', '◪_◪', '( ノ・・)ノ', '(¬‿¬)', '( ✧≖ ͜ʖ≖)',
    '(＾▽＾)', 'ღවꇳවღ', '(•̩̥̀‿•̩̥̀✿)', '(ᴗᵔᴥᵔ)', '( ♥ ͜ʖ ♥)', '(>‿♥)',
    '(♥ω♥*)', '( ﾟ∀ﾟ)ﾉ【I LOVE U】', '❤️ (•́ ω •̀๑)', '¯\\_(ツ)_/¯',
    '┐_㋡_┌', '└(・。・)┘', '༼ຈل͜ຈ༽', '༼ ͡ಠ ͜ʖ ͡ಠ ༽', 'ヽ༼ ͠ ͡° ͜ʖ ͡° ༽ﾉ',
    '༼ ♛‿♛ ༽', '༼ °👅 ͡°༽', 'ʕ༼◕ ౪ ◕✿༽ʔ', '༼ ͒ ̶ ͒ ༽', '(◣_◢)',
    '┌∩┐(◣_◢)┌∩┐', '（＞д＜）', '( ⋋ · ⋌ ) very anger', '(´つヮ⊂)',
    '(◞‸◟ㆀ)', 'ᇂ_ᇂ', 'ಠ ''ಠ', '(ಥ ͜ʖಥ)', 'ಠ෴ಠ', '▼・ᴥ・▼', 'ʕっ•ᴥ•ʔっ',
    'V✪ω✪V', 'V✪⋏✪V', '(❍ᴥ❍ʋ)', '=^∇^*', '(=˃ᆺ˂=)',
    'ᶠᵉᵉᵈ ᵐᵉ /ᐠ-ⱉ-ᐟ\\ﾉ', 'ʕ´• ᴥ•̥`ʔ', 'ʕ/ ·ᴥ·ʔ/', '(⋟﹏⋞)', '༼☯﹏☯༽',
    '(￣￢￣ヾ)', '（￣ ｗ￣) ', '( ︶｡︶✽)', 'Zzz..(ˇ㉨ˇ๑) Good night☆',
    '〜ɢᵒᵒᵈ ɴⁱᵍᵗʰ( ᵕᴗᵕ)*･☪︎·̩͙', 'Good ヽ(o≧ω≦o)ﾉ Morning ﾟ.:｡+ﾟ',
    '(◕ᗜ◕)', '(✿╹◡╹)', '(˃ᆺ˂✿)', '٩( ᗒᗨᗕ )۶', 'ꉂ (´∀｀)ʱªʱªʱª',
    'ʱªʱªʱª(˃̣̣̥˂̣̣̥)', '( ′～‵ )', '╭( ๐_๐)╮', '(⚆ᗝ⚆)', '(✿〇∀〇)',
    '(〃ω〃)', '(・_・;)', '( ͡°⁄ ⁄ ͜⁄ ⁄ʖ⁄ ⁄ ͡°)', '(⁰ ◕〜◕ ⁰)', '● ﹏ ●',
    '(◡︵◡)', 'Sorry (◞‸◟ㆀ)', '(◔_◔)🍔🍕', '༼つ ◕_◕ ༽つ', 'ლ(◕ω◕ლ)',
    '( ^_^)／', '(¬_¬)ﾉ', '(*￣Ｏ￣)ノ',
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize tab controller
    final categories = _getTabCategories();
    _tabController = TabController(length: categories.length, vsync: this);
    
    // Set initial category
    if (widget.initialCategory != null) {
      final index = categories.indexOf(widget.initialCategory!);
      if (index != -1) {
        _tabController.index = index;
        _selectedCategory = widget.initialCategory!;
      }
    }
    
    // Initialize pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticOut),
    );
    
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedCategory = categories[_tabController.index];
        });
      }
    });
    
    // Load data from local storage and cloud
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Load data from local storage and cloud
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _loadLocalData();
      
      if (widget.enableCloudSync && widget.userId != null) {
        await _syncFromCloud();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Load data from local SharedPreferences
  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load favorites
    final favoritesJson = prefs.getStringList('emoticon_favorites') ?? [];
    _favorites.addAll(favoritesJson);
    
    // Load recently used
    final recentJson = prefs.getStringList('emoticon_recent') ?? [];
    _recentlyUsed.addAll(recentJson);
    
    // Load custom emoticons
    final customJson = prefs.getStringList('emoticon_custom') ?? [];
    _customEmoticons.addAll(customJson);
    
    // Update categorized emoticons with custom ones
    _categorizedEmoticons['Custom'] = List.from(_customEmoticons);
    
    setState(() {});
  }

  /// Save data to local SharedPreferences
  Future<void> _saveLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setStringList('emoticon_favorites', _favorites.toList());
    await prefs.setStringList('emoticon_recent', _recentlyUsed);
    await prefs.setStringList('emoticon_custom', _customEmoticons);
  }

  /// Sync data from cloud storage
  Future<void> _syncFromCloud() async {
    if (!widget.enableCloudSync || widget.userId == null) return;
    
    setState(() {
      _isSyncing = true;
    });

    try {
      // Simulate cloud API call - replace with actual implementation
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock cloud data - replace with actual cloud service integration
      final cloudData = await _fetchCloudData(widget.userId!);
      
      if (cloudData != null) {
        setState(() {
          _favorites.clear();
          _favorites.addAll(cloudData['favorites'] ?? []);
          
          _customEmoticons.clear();
          _customEmoticons.addAll(cloudData['custom'] ?? []);
          
          _categorizedEmoticons['Custom'] = List.from(_customEmoticons);
        });
        
        await _saveLocalData();
      }
    } catch (e) {
      debugPrint('Error syncing from cloud: $e');
      _showErrorSnackBar('Failed to sync from cloud: ${e.toString()}');
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  /// Sync data to cloud storage
  Future<void> _syncToCloud() async {
    if (!widget.enableCloudSync || widget.userId == null) return;
    
    setState(() {
      _isSyncing = true;
    });

    try {
      // Simulate cloud API call - replace with actual implementation
      await Future.delayed(const Duration(seconds: 1));
      
      final cloudData = {
        'userId': widget.userId!,
        'favorites': _favorites.toList(),
        'custom': _customEmoticons,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      await _uploadCloudData(widget.userId!, cloudData);
      
      _showSuccessSnackBar('Data synced to cloud successfully! ☁️');
    } catch (e) {
      debugPrint('Error syncing to cloud: $e');
      _showErrorSnackBar('Failed to sync to cloud: ${e.toString()}');
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  /// Mock function to fetch cloud data - replace with actual implementation
  Future<Map<String, dynamic>?> _fetchCloudData(String userId) async {
    // This would integrate with your actual cloud service (Firebase, Supabase, etc.)
    // For now, returning mock data
    return {
      'favorites': ['(•‿•)', '(ツ)', '❤️ (•́ ω •̀๑)'],
      'custom': ['＼(￣▽￣)／', '(☆▽☆)', '◕‿◕✨'],
    };
  }

  /// Mock function to upload cloud data - replace with actual implementation
  Future<void> _uploadCloudData(String userId, Map<String, dynamic> data) async {
    // This would integrate with your actual cloud service
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Show emoticon creation dialog
  Future<void> _showCreateEmoticonDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _EmoticonCreationDialog(
        primaryColor: widget.primaryColor,
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      await _addCustomEmoticon(result);
    }
  }

  /// Add a custom emoticon
  Future<void> _addCustomEmoticon(String emoticon) async {
    if (_customEmoticons.contains(emoticon)) {
      _showErrorSnackBar('This emoticon already exists! (╯°□°）╯');
      return;
    }
    
    setState(() {
      _customEmoticons.insert(0, emoticon);
      _categorizedEmoticons['Custom'] = List.from(_customEmoticons);
    });
    
    await _saveLocalData();
    
    if (widget.enableCloudSync && widget.userId != null) {
      await _syncToCloud();
    }
    
    widget.onEmoticonCreated?.call(emoticon);
    
    _showSuccessSnackBar('Custom emoticon "$emoticon" created! ✨');
    HapticFeedback.lightImpact();
  }

  /// Delete a custom emoticon
  Future<void> _deleteCustomEmoticon(String emoticon) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Emoticon'),
        content: Text('Are you sure you want to delete "$emoticon"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        _customEmoticons.remove(emoticon);
        _favorites.remove(emoticon);
        _recentlyUsed.remove(emoticon);
        _categorizedEmoticons['Custom'] = List.from(_customEmoticons);
      });
      
      await _saveLocalData();
      
      if (widget.enableCloudSync && widget.userId != null) {
        await _syncToCloud();
      }
      
      _showSuccessSnackBar('Emoticon deleted! 🗑️');
      HapticFeedback.lightImpact();
    }
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show emoticon options dialog for custom emoticons
  Future<void> _showEmoticonOptionsDialog(String emoticon) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Emoticon: $emoticon'),
        content: const Text('What would you like to do with this custom emoticon?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'favorite'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _favorites.contains(emoticon) ? Icons.favorite : Icons.favorite_border,
                  size: 16,
                  color: Colors.red,
                ),
                const SizedBox(width: 4),
                Text(_favorites.contains(emoticon) ? 'Unfavorite' : 'Favorite'),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete, size: 16),
                SizedBox(width: 4),
                Text('Delete'),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    
    if (result == 'favorite') {
      _toggleFavorite(emoticon);
    } else if (result == 'delete') {
      await _deleteCustomEmoticon(emoticon);
    }
  }

  List<String> _getTabCategories() {
    final categories = <String>[];
    
    if (widget.showFavorites && _favorites.isNotEmpty) {
      categories.add('Favorites');
    }
    
    if (widget.showRecentlyUsed && _recentlyUsed.isNotEmpty) {
      categories.add('Recent');
    }
    
    categories.addAll(_categorizedEmoticons.keys.where((key) {
      if (key == 'Custom') {
        return widget.enableCreation && _customEmoticons.isNotEmpty;
      }
      return true;
    }));
    
    return categories;
  }

  List<String> _getFilteredEmoticons() {
    List<String> emoticons;
    
    if (_selectedCategory == 'Favorites') {
      emoticons = _favorites.toList();
    } else if (_selectedCategory == 'Recent') {
      emoticons = _recentlyUsed;
    } else {
      emoticons = _categorizedEmoticons[_selectedCategory] ?? [];
    }
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      emoticons = emoticons.where((emoticon) {
        return emoticon.toLowerCase().contains(query) ||
               _getEmoticonTags(emoticon).any((tag) => tag.contains(query));
      }).toList();
    }
    
    return emoticons;
  }

  List<String> _getEmoticonTags(String emoticon) {
    // Simple tagging system for better search
    const tags = {
      '(•‿•)': ['happy', 'smile', 'cute'],
      '(づ ◕‿◕ )づ': ['hug', 'love', 'cute', 'affection'],
      'ಥ‿ಥ': ['sad', 'cry', 'tears'],
      '( ͡° ͜ʖ ͡°)': ['lenny', 'meme', 'funny', 'cool'],
      '¯\\_(ツ)_/¯': ['shrug', 'dunno', 'whatever'],
      '(ツ)': ['happy', 'smile', 'simple'],
      '❤️': ['love', 'heart', 'romance'],
      'ʕ•ᴥ•ʔ': ['bear', 'cute', 'animal'],
    };
    
    return tags[emoticon] ?? [];
  }

  void _handleEmoticonTap(String emoticon) {
    // Add to recently used
    if (!_recentlyUsed.contains(emoticon)) {
      setState(() {
        _recentlyUsed.insert(0, emoticon);
        if (_recentlyUsed.length > 20) {
          _recentlyUsed.removeLast();
        }
      });
      
      // Save to local storage
      _saveLocalData();
    }
    
    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: emoticon));
    
    // Trigger pulse animation
    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });
    
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied "$emoticon" to clipboard! ◕‿↼)'),
        duration: const Duration(seconds: 1),
        backgroundColor: widget.primaryColor ?? Colors.pink.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    
    // Trigger callbacks
    widget.onEmoticonSelected?.call(emoticon);
    widget.onEmoticonCopied?.call(emoticon);
    
    // Haptic feedback
    HapticFeedback.lightImpact();
  }

  void _toggleFavorite(String emoticon) {
    setState(() {
      if (_favorites.contains(emoticon)) {
        _favorites.remove(emoticon);
      } else {
        _favorites.add(emoticon);
      }
    });
    
    // Save to local storage
    _saveLocalData();
    
    // Sync to cloud if enabled
    if (widget.enableCloudSync && widget.userId != null) {
      _syncToCloud();
    }
    
    HapticFeedback.selectionClick();
  }

  Widget _buildSearchBar() {
    if (!widget.showSearch) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search emoticons... (◕‿◕)',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade600),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),
          
          // Cloud sync button
          if (widget.enableCloudSync && widget.userId != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: _isSyncing ? null : _syncToCloud,
              icon: _isSyncing 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          widget.primaryColor ?? Colors.pink.shade400,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.cloud_sync,
                      color: widget.primaryColor ?? Colors.pink.shade400,
                    ),
              tooltip: _isSyncing ? 'Syncing...' : 'Sync to Cloud',
            ),
          ],
          
          // Create emoticon button
          if (widget.enableCreation) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: _showCreateEmoticonDialog,
              icon: Icon(
                Icons.add_circle,
                color: widget.primaryColor ?? Colors.pink.shade400,
              ),
              tooltip: 'Create Custom Emoticon',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    if (!widget.showCategories) return const SizedBox.shrink();
    
    final categories = _getTabCategories();
    
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: widget.primaryColor ?? Colors.pink.shade400,
        labelColor: widget.primaryColor ?? Colors.pink.shade600,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: categories.map((category) {
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _getCategoryIcon(category),
                const SizedBox(width: 8),
                Text(category),
                if (category == 'Favorites' && _favorites.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_favorites.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _getCategoryIcon(String category) {
    const icons = {
      'Favorites': Icons.favorite,
      'Recent': Icons.history,
      'Happy': Icons.sentiment_very_satisfied,
      'Love': Icons.favorite,
      'Funny': Icons.sentiment_very_satisfied_outlined,
      'Sad': Icons.sentiment_very_dissatisfied,
      'Cool': Icons.sentiment_neutral,
      'Animals': Icons.pets,
      'Special': Icons.star,
      'Actions': Icons.pan_tool,
      'Custom': Icons.edit,
    };
    
    return Icon(
      icons[category] ?? Icons.emoji_emotions,
      size: 18,
    );
  }

  Widget _buildEmoticonGrid() {
    final emoticons = _getFilteredEmoticons();
    
    if (emoticons.isEmpty) {
      return Center(
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
              _searchQuery.isNotEmpty
                  ? 'No emoticons found for "$_searchQuery" (╯°□°）╯'
                  : 'No emoticons in this category yet ¯\\_(ツ)_/¯',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Try searching for: happy, sad, love, funny, cool',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: emoticons.length,
      itemBuilder: (context, index) {
        final emoticon = emoticons[index];
        final isFavorited = _favorites.contains(emoticon);
        final isRecentlyUsed = _recentlyUsed.contains(emoticon);
        
        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return GestureDetector(
              onTap: () => _handleEmoticonTap(emoticon),
              onLongPress: () {
                if (_selectedCategory == 'Custom' && _customEmoticons.contains(emoticon)) {
                  _showEmoticonOptionsDialog(emoticon);
                } else {
                  _toggleFavorite(emoticon);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: widget.backgroundColor ?? Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFavorited
                        ? Colors.red.shade300
                        : isRecentlyUsed
                            ? Colors.blue.shade300
                            : _selectedCategory == 'Custom'
                                ? Colors.purple.shade300
                                : Colors.grey.shade200,
                    width: isFavorited || isRecentlyUsed || _selectedCategory == 'Custom' ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Transform.scale(
                        scale: _pulseAnimation.value,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            emoticon,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (isFavorited)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Icon(
                          Icons.favorite,
                          size: 12,
                          color: Colors.red.shade400,
                        ),
                      ),
                    if (isRecentlyUsed && !isFavorited)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Icon(
                          Icons.history,
                          size: 12,
                          color: Colors.blue.shade400,
                        ),
                      ),
                    if (_selectedCategory == 'Custom' && _customEmoticons.contains(emoticon))
                      Positioned(
                        top: 2,
                        left: 2,
                        child: Icon(
                          Icons.edit,
                          size: 12,
                          color: Colors.purple.shade400,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRandomEmoticonButton() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: FloatingActionButton(
        mini: true,
        backgroundColor: widget.primaryColor ?? Colors.pink.shade400,
        onPressed: () {
          final random = Random();
          final randomEmoticon = _allEmoticons[random.nextInt(_allEmoticons.length)];
          _handleEmoticonTap(randomEmoticon);
        },
        child: const Icon(Icons.shuffle, color: Colors.white),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.favorite,
            count: _favorites.length,
            label: 'Favorites',
            color: Colors.red.shade400,
          ),
          _buildStatItem(
            icon: Icons.history,
            count: _recentlyUsed.length,
            label: 'Recent',
            color: Colors.blue.shade400,
          ),
          if (widget.enableCreation)
            _buildStatItem(
              icon: Icons.edit,
              count: _customEmoticons.length,
              label: 'Custom',
              color: Colors.purple.shade400,
            ),
          _buildStatItem(
            icon: Icons.emoji_emotions,
            count: _allEmoticons.length + _customEmoticons.length,
            label: 'Total',
            color: Colors.green.shade400,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading emoticons... ◕‿◕'),
            ],
          ),
        ),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Search bar
          _buildSearchBar(),
          
          // Category tabs
          _buildCategoryTabs(),
          
          // Emoticon grid
          Expanded(
            child: Stack(
              children: [
                _buildEmoticonGrid(),
                _buildRandomEmoticonButton(),
              ],
            ),
          ),
          
          // Stats bar
          _buildStatsBar(),
        ],
      ),
    );
  }
}

/// Dialog for creating custom emoticons
class _EmoticonCreationDialog extends StatefulWidget {
  final Color? primaryColor;
  
  const _EmoticonCreationDialog({
    this.primaryColor,
  });
  
  @override
  State<_EmoticonCreationDialog> createState() => _EmoticonCreationDialogState();
}

class _EmoticonCreationDialogState extends State<_EmoticonCreationDialog> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _commonSymbols = [
    '(', ')', '[', ']', '{', '}', '•', '◕', '◔', '○', '●', '◉', '◎', '⊙',
    '‿', '⌒', '▽', '∀', '∩', '∪', '⋏', '⋎', '｡', '､', '＾', '～', '‾',
    '¯', '_', '-', '=', '+', '*', '/', '\\', '|', '!', '?', ':', ';', ',',
    '.', '"', "'", '`', '´', '¨', '^', '~', '°', '¬', '¿', '¡', '£', '€',
    '¥', '₹', '₩', '₽', '¢', '§', '¶', '†', '‡', '•', '‰', '′', '″', '‴',
    '※', '‼', '⁇', '⁈', '⁉', '⁏', '؟', '؛', '٪', '٭', '۔', '܀', '܁', '܂',
    '♀', '♂', '♠', '♣', '♥', '♦', '♪', '♫', '♬', '♭', '♮', '♯', '☀', '☁',
    '☂', '☃', '☄', '★', '☆', '☉', '☎', '☏', '☐', '☑', '☒', '☓', '☔', '☕',
    '☖', '☗', '☘', '☙', '☚', '☛', '☜', '☝', '☞', '☟', '☠', '☡', '☢', '☣',
    '☤', '☥', '☦', '☧', '☨', '☩', '☪', '☫', '☬', '☭', '☮', '☯', '☰', '☱',
  ];
  
  final List<String> _recentSymbols = [];
  String _preview = '';
  
  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _preview = _controller.text;
      });
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _addSymbol(String symbol) {
    final currentPosition = _controller.selection.baseOffset;
    final text = _controller.text;
    final newText = text.substring(0, currentPosition) + 
                   symbol + 
                   text.substring(currentPosition);
    
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: currentPosition + symbol.length),
    );
    
    // Add to recent symbols
    if (!_recentSymbols.contains(symbol)) {
      setState(() {
        _recentSymbols.insert(0, symbol);
        if (_recentSymbols.length > 20) {
          _recentSymbols.removeLast();
        }
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.create,
                  color: widget.primaryColor ?? Colors.pink.shade400,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Create Custom Emoticon',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  const Text(
                    'Preview',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _preview.isEmpty ? '( ◕‿◕ )' : _preview,
                    style: const TextStyle(fontSize: 32),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Text input
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter your emoticon',
                hintText: 'e.g., (◕‿◕)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _controller.clear();
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
              ),
              maxLength: 50,
              style: const TextStyle(fontSize: 18),
            ),
            
            const SizedBox(height: 16),
            
            // Symbol picker
            const Text(
              'Common Symbols',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            
            const SizedBox(height: 8),
            
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: widget.primaryColor ?? Colors.pink.shade400,
                      tabs: const [
                        Tab(text: 'All Symbols'),
                        Tab(text: 'Recent'),
                      ],
                    ),
                    
                    Expanded(
                      child: TabBarView(
                        children: [
                          // All symbols
                          GridView.builder(
                            padding: const EdgeInsets.all(8),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 8,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                            ),
                            itemCount: _commonSymbols.length,
                            itemBuilder: (context, index) {
                              final symbol = _commonSymbols[index];
                              return GestureDetector(
                                onTap: () => _addSymbol(symbol),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Center(
                                    child: Text(
                                      symbol,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          // Recent symbols
                          _recentSymbols.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No recent symbols\nTap symbols to add them!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.all(8),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 8,
                                    crossAxisSpacing: 4,
                                    mainAxisSpacing: 4,
                                  ),
                                  itemCount: _recentSymbols.length,
                                  itemBuilder: (context, index) {
                                    final symbol = _recentSymbols[index];
                                    return GestureDetector(
                                      onTap: () => _addSymbol(symbol),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.blue.shade200),
                                        ),
                                        child: Center(
                                          child: Text(
                                            symbol,
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _controller.text.trim().isEmpty
                        ? null
                        : () => Navigator.pop(context, _controller.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.primaryColor ?? Colors.pink.shade400,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Create'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
