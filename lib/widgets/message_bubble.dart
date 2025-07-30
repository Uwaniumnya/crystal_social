import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../profile/avatar_decoration.dart';

class MessageBubbleEnhanced extends StatefulWidget {
  final String? text;
  final String? imageUrl;
  final String? audioUrl;
  final String? videoUrl;
  final String? gifUrl;
  final String? stickerUrl;
  final bool isMe;
  final DateTime? timestamp;
  final String? status;
  final String? avatarUrl;
  final String? effect;
  final bool isSecret;
  final String? username;
  final String? messageId;
  final String? replyToMessageId;
  final String? replyToText;
  final String? replyToUsername;
  final bool isEdited;
  final bool isForwarded;
  final int? forwardCount;
  final bool isImportant;
  final String? mood;
  final List<String>? mentions;
  final List<String>? hashtags;
  final Map<String, dynamic>? metadata;

  final Map<String, List<String>>? reactions;
  final VoidCallback? onLongPress;
  final Function(String emoji)? onReactTap;
  final Function()? onTap;
  final Function()? onDoubleTap;
  final Function(dynamic msg)? onReply;
  final Function(dynamic msg)? onReact;
  final Function(dynamic msg)? onEffect;
  final Function(dynamic msg)? onEdit;
  final Function(dynamic msg)? onDelete;
  final Function(dynamic msg)? onForward;
  final Function(dynamic msg)? onCopy;
  final Function()? onAvatarTap;
  final Function(String mention)? onMentionTap;
  final Function(String hashtag)? onHashtagTap;
  final String? decorationPath;
  final String auraColor;

  const MessageBubbleEnhanced({
    super.key,
    this.text,
    this.imageUrl,
    this.audioUrl,
    this.videoUrl,
    this.gifUrl,
    this.stickerUrl,
    required this.isMe,
    this.timestamp,
    this.status,
    this.avatarUrl,
    this.reactions,
    this.onLongPress,
    this.onReactTap,
    this.effect,
    this.isSecret = false,
    this.username,
    this.messageId,
    this.replyToMessageId,
    this.replyToText,
    this.replyToUsername,
    this.isEdited = false,
    this.isForwarded = false,
    this.forwardCount,
    this.isImportant = false,
    this.mood,
    this.mentions,
    this.hashtags,
    this.metadata,
    this.onTap,
    this.onDoubleTap,
    this.onReply,
    this.onReact,
    this.onEffect,
    this.onEdit,
    this.onDelete,
    this.onForward,
    this.onCopy,
    this.onAvatarTap,
    this.onMentionTap,
    this.onHashtagTap,
    this.decorationPath,
    required this.auraColor,
  });

  @override
  State<MessageBubbleEnhanced> createState() => _MessageBubbleEnhancedState();
}

class _MessageBubbleEnhancedState extends State<MessageBubbleEnhanced>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _scaleController;
  late AnimationController _shakeController;
  late Animation<double> _pulse;
  late Animation<Offset> _float;
  late Animation<double> _scale;
  late Animation<double> _shake;
  
  bool _revealed = false;
  bool _showFullText = false;

  AudioPlayer? _player;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _pulse = Tween<double>(begin: 1.0, end: 1.1)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_controller);

    _float = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.03))
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_controller);

    _scale = Tween<double>(begin: 1.0, end: 0.95)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_scaleController);

    _shake = Tween<double>(begin: 0.0, end: 10.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    if (widget.effect == 'pulse' || widget.effect == 'float') {
      _controller.repeat(reverse: true);
    }

    if (widget.effect == 'bounce') {
      _controller.forward().then((_) => _controller.reverse());
    }

    if (widget.effect == 'shake') {
      _shakeController.repeat(reverse: true);
    }

    if (widget.audioUrl != null) {
      _player = AudioPlayer();
      _player!.setUrl(widget.audioUrl!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scaleController.dispose();
    _shakeController.dispose();
    _player?.dispose();
    super.dispose();
  }

  String get formattedTime {
    if (widget.timestamp == null) return '';
    return DateFormat.jm().format(widget.timestamp!);
  }

  IconData getStatusIcon() {
    switch (widget.status) {
      case 'read':
        return Icons.done_all;
      case 'delivered':
        return Icons.done_all;
      case 'sent':
        return Icons.done;
      default:
        return Icons.access_time;
    }
  }

  Color getStatusColor() {
    switch (widget.status) {
      case 'read':
        return Colors.blueAccent;
      case 'delivered':
      case 'sent':
        return Colors.pink.shade300;
      default:
        return Colors.grey;
    }
  }

  Widget _wrapWithEffect(Widget child) {
    Widget wrappedChild = child;
    
    switch (widget.effect) {
      case 'pulse':
        wrappedChild = ScaleTransition(scale: _pulse, child: wrappedChild);
        break;
      case 'float':
        wrappedChild = SlideTransition(position: _float, child: wrappedChild);
        break;
      case 'bounce':
        wrappedChild = ScaleTransition(scale: _pulse, child: wrappedChild);
        break;
      case 'shake':
        wrappedChild = AnimatedBuilder(
          animation: _shake,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shake.value, 0),
              child: child,
            );
          },
          child: wrappedChild,
        );
        break;
    }

    // Add press scale animation
    return ScaleTransition(
      scale: _scale,
      child: wrappedChild,
    );
  }

  // Text processing for mentions, hashtags, and links
  Widget _buildRichText(String text) {
    final List<TextSpan> spans = [];
    final RegExp linkRegex = RegExp(r'https?://[^\s]+');
    final RegExp mentionRegex = RegExp(r'@[\w]+');
    final RegExp hashtagRegex = RegExp(r'#[\w]+');
    
    int lastIndex = 0;
    
    // Find all matches
    final List<RegExpMatch> allMatches = [
      ...linkRegex.allMatches(text),
      ...mentionRegex.allMatches(text),
      ...hashtagRegex.allMatches(text),
    ];
    
    // Sort matches by position
    allMatches.sort((a, b) => a.start.compareTo(b.start));
    
    for (final match in allMatches) {
      // Add normal text before match
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: TextStyle(
            color: widget.isMe ? Colors.white : Colors.pink.shade800,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ));
      }
      
      final matchText = match.group(0)!;
      
      if (linkRegex.hasMatch(matchText)) {
        // Link
        spans.add(TextSpan(
          text: matchText,
          style: TextStyle(
            color: widget.isMe ? Colors.blue.shade200 : Colors.blue.shade600,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _launchUrl(matchText),
        ));
      } else if (mentionRegex.hasMatch(matchText)) {
        // Mention
        spans.add(TextSpan(
          text: matchText,
          style: TextStyle(
            color: widget.isMe ? Colors.purple.shade200 : Colors.purple.shade600,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => widget.onMentionTap?.call(matchText),
        ));
      } else if (hashtagRegex.hasMatch(matchText)) {
        // Hashtag
        spans.add(TextSpan(
          text: matchText,
          style: TextStyle(
            color: widget.isMe ? Colors.orange.shade200 : Colors.orange.shade600,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => widget.onHashtagTap?.call(matchText),
        ));
      }
      
      lastIndex = match.end;
    }
    
    // Add remaining text
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: TextStyle(
          color: widget.isMe ? Colors.white : Colors.pink.shade800,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ));
    }
    
    return RichText(
      text: TextSpan(children: spans),
    );
  }

  void _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // Copy message text to clipboard
  void _copyMessage() {
    if (widget.text != null) {
      Clipboard.setData(ClipboardData(text: widget.text!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Message copied to clipboard'),
          backgroundColor: Colors.pink.shade400,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showMessageActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                
                // Quick reactions
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['❤️', '😂', '😮', '😢', '😡', '👍'].map((emoji) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          widget.onReactTap?.call(emoji);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.pink.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Text(emoji, style: const TextStyle(fontSize: 24)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                const Divider(),
                
                // Action buttons
                ListTile(
                  leading: const Icon(Icons.reply, color: Colors.pink),
                  title: const Text("Reply"),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onReply?.call(widget);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy, color: Colors.blue),
                  title: const Text("Copy"),
                  onTap: () {
                    Navigator.pop(context);
                    _copyMessage();
                  },
                ),
                if (widget.isMe) ...[
                  ListTile(
                    leading: const Icon(Icons.edit, color: Colors.green),
                    title: const Text("Edit"),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onEdit?.call(widget);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text("Delete"),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onDelete?.call(widget);
                    },
                  ),
                ],
                ListTile(
                  leading: const Icon(Icons.forward, color: Colors.purple),
                  title: const Text("Forward"),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onForward?.call(widget);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.auto_awesome, color: Colors.orange),
                  title: const Text("Add Effect"),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onEffect?.call(widget);
                  },
                ),
                if (widget.isImportant)
                  ListTile(
                    leading: const Icon(Icons.star, color: Colors.amber),
                    title: const Text("Important"),
                    enabled: false,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMediaContent() {
    // Audio message
    if (widget.audioUrl != null) {
      return _buildAudioPlayer();
    }
    
    // Video message
    if (widget.videoUrl != null) {
      return _buildVideoPlayer();
    }
    
    // GIF message
    if (widget.gifUrl != null) {
      return _buildGifPlayer();
    }
    
    // Sticker message
    if (widget.stickerUrl != null) {
      return _buildStickerDisplay();
    }
    
    // Image message
    if (widget.imageUrl != null) {
      return _buildImageDisplay();
    }
    
    // Text message (with rich text support)
    if (widget.text != null) {
      return _buildTextMessage();
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildTextMessage() {
    final text = widget.text!;
    final isLongText = text.length > 200;
    final displayText = isLongText && !_showFullText 
        ? '${text.substring(0, 200)}...' 
        : text;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isSecret && !_revealed)
          Text(
            "🔒 Tap to reveal",
            style: TextStyle(
              color: Colors.pink.shade800,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          )
        else
          _buildRichText(displayText),
        
        if (isLongText && _revealed)
          GestureDetector(
            onTap: () => setState(() => _showFullText = !_showFullText),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _showFullText ? 'Show less' : 'Show more',
                style: TextStyle(
                  color: widget.isMe ? Colors.white70 : Colors.pink.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageDisplay() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CachedNetworkImage(
        imageUrl: widget.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 200,
          color: Colors.pink.shade50,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.pink.shade400),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: 200,
          color: Colors.pink.shade50,
          child: Icon(Icons.error, color: Colors.pink.shade400),
        ),
      ),
    );
  }

  Widget _buildGifPlayer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: widget.gifUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 200,
              color: Colors.pink.shade50,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.pink.shade400),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'GIF',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickerDisplay() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: CachedNetworkImage(
        imageUrl: widget.stickerUrl!,
        width: 120,
        height: 120,
        fit: BoxFit.contain,
        placeholder: (context, url) => Container(
          width: 120,
          height: 120,
          color: Colors.pink.shade50,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.pink.shade400),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CachedNetworkImage(
            imageUrl: widget.videoUrl!, // Assuming thumbnail
            fit: BoxFit.cover,
            width: double.infinity,
            height: 200,
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.black26,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.white, size: 48),
              onPressed: () {
                // Implement video player
              },
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'VIDEO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer() {
    return _player == null
        ? const SizedBox.shrink()
        : Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.pink.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.audiotrack, color: Colors.pink.shade400, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Audio Message',
                      style: TextStyle(
                        color: Colors.pink.shade600,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StreamBuilder<PlayerState>(
                      stream: _player!.playerStateStream,
                      builder: (context, snapshot) {
                        final playing = snapshot.data?.playing ?? false;
                        return IconButton(
                          icon: Icon(
                            playing ? Icons.pause_circle : Icons.play_circle,
                            color: Colors.pink.shade400,
                            size: 32,
                          ),
                          onPressed: () {
                            if (playing) {
                              _player!.pause();
                            } else {
                              _player!.play();
                            }
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StreamBuilder<Duration>(
                        stream: _player!.positionStream,
                        builder: (context, posSnap) {
                          final position = posSnap.data ?? Duration.zero;
                          return StreamBuilder<Duration?>(
                            stream: _player!.durationStream,
                            builder: (context, durSnap) {
                              final duration = durSnap.data ?? Duration.zero;
                              final progress = duration.inMilliseconds > 0
                                  ? position.inMilliseconds / duration.inMilliseconds
                                  : 0.0;
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.pink.shade100,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.pink.shade400),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_format(position)} / ${_format(duration)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.pink.shade600,
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
  }

  String _format(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  Widget _buildReplySection() {
    if (widget.replyToMessageId == null || widget.replyToText == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.isMe ? Colors.pink.shade100 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: widget.isMe ? Colors.pink.shade400 : Colors.grey.shade400,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.replyToUsername != null)
            Text(
              widget.replyToUsername!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: widget.isMe ? Colors.pink.shade700 : Colors.grey.shade700,
              ),
            ),
          const SizedBox(height: 2),
          Text(
            widget.replyToText!.length > 50 
                ? '${widget.replyToText!.substring(0, 50)}...'
                : widget.replyToText!,
            style: TextStyle(
              fontSize: 12,
              color: widget.isMe ? Colors.pink.shade600 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor = widget.isMe ? Colors.pink.shade200 : Colors.pink.shade50;
    final align = widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    // Use AvatarWithDecoration instead of CircleAvatar
    final avatar = GestureDetector(
      onTap: widget.onAvatarTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Color(0xFFFFDDEE),
          shape: BoxShape.circle,
        ),
        child: AvatarWithDecoration(
          avatarUrl: widget.avatarUrl ?? '',
          decorationPath: widget.decorationPath ?? '',
        ),
      ),
    );

    final messageContent = GestureDetector(
      onTap: () {
        if (widget.isSecret && !_revealed) {
          setState(() => _revealed = true);
        }
        widget.onTap?.call();
      },
      onDoubleTap: () {
        _scaleController.forward().then((_) => _scaleController.reverse());
        widget.onDoubleTap?.call();
      },
      onLongPress: () {
        HapticFeedback.heavyImpact();
        _showMessageActions();
      },
      onTapDown: (_) {
        _scaleController.forward();
      },
      onTapUp: (_) {
        _scaleController.reverse();
      },
      onTapCancel: () {
        _scaleController.reverse();
      },
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: widget.isMe ? const Radius.circular(20) : Radius.zero,
            bottomRight: widget.isMe ? Radius.zero : const Radius.circular(20),
          ),
          boxShadow: [
            if (widget.auraColor.isNotEmpty)
              BoxShadow(
                color: Color(int.parse("0xFF${widget.auraColor.substring(1)}")),
                spreadRadius: 3,
                blurRadius: 8,
              ),
            BoxShadow(
              color: Colors.pinkAccent.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReplySection(),
            _buildMediaContent(),
            if (widget.isEdited)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'edited',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: widget.isMe ? Colors.white70 : Colors.grey.shade600,
                  ),
                ),
              ),
            if (widget.isForwarded)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.forward,
                      size: 16,
                      color: widget.isMe ? Colors.white70 : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.forwardCount != null && widget.forwardCount! > 1
                          ? 'Forwarded ${widget.forwardCount} times'
                          : 'Forwarded',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: widget.isMe ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );

    final reactionRow = (widget.reactions != null && widget.reactions!.isNotEmpty)
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: widget.reactions!.entries.map((entry) {
                final emoji = entry.key;
                final count = entry.value.length;
                return GestureDetector(
                  onTap: () => widget.onReactTap?.call(emoji),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      '$emoji $count',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                );
              }).toList(),
            ),
          )
        : const SizedBox.shrink();

    final timeAndStatus = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isImportant)
            Icon(
              Icons.star,
              size: 16,
              color: Colors.amber.shade600,
            ),
          if (widget.isImportant) const SizedBox(width: 4),
          Text(
            formattedTime,
            style: TextStyle(fontSize: 12, color: Colors.pink.shade300),
          ),
          if (widget.isMe && widget.status != null) ...[
            const SizedBox(width: 6),
            Icon(getStatusIcon(), size: 16, color: getStatusColor()),
          ],
        ],
      ),
    );

    final messageColumn = Column(
      crossAxisAlignment: align,
      children: [
        if (widget.username != null && !widget.isMe)
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 4),
            child: Text(
              widget.username!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
        _wrapWithEffect(messageContent),
        reactionRow,
        timeAndStatus,
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment:
            widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: widget.isMe
            ? [messageColumn, const SizedBox(width: 8), avatar]
            : [avatar, const SizedBox(width: 8), messageColumn],
      ),
    );
  }
}
