import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ConnectionQuality { excellent, good, poor, bad, unknown }

class CallScreen extends StatefulWidget {
  final String channelId;
  final String token;
  final bool isVideo;
  final String callerId;
  final String receiverId;

  const CallScreen({
    required this.channelId,
    required this.token,
    required this.isVideo,
    required this.callerId,
    required this.receiverId,
    super.key,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  late RtcEngine _engine;
  int? _remoteUid;
  DateTime? _startTime;
  Timer? _callDurationTimer;
  int _callSeconds = 0;
  bool _isMuted = false;
  bool _isScreenSharing = false;
  bool _isFrontCamera = true;
  bool _isVideoEnabled = true;
  bool _isSpeakerEnabled = false;
  bool _isRecording = false;
  bool _isConnected = false;
  bool _isConnecting = true;
  Map<String, dynamic>? callerData;
  Map<String, dynamic>? receiverData;
  
  // Enhanced state management
  ConnectionQuality _connectionQuality = ConnectionQuality.excellent;
  double _localVideoScale = 1.0;
  Offset _localVideoPosition = const Offset(20, 100);
  bool _showControls = true;
  Timer? _hideControlsTimer;
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _connectionController;
  late AnimationController _recordingController;
  late AnimationController _fadeController;
  
  // Animations
  late Animation<double> _pulseAnimation;
  late Animation<double> _connectionAnimation;
  late Animation<double> _recordingAnimation;
  late Animation<double> _fadeAnimation;
  
  // Audio levels for visualization
  double _localAudioLevel = 0.0;
  double _remoteAudioLevel = 0.0;
  Timer? _audioLevelTimer;
  
  // Call statistics
  Map<String, dynamic> _callStats = {};
  Timer? _statsTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startTime = DateTime.now();
    _loadUserInfo();
    _initializeAgora();
    _startControlsTimer();
    _startAudioLevelMonitoring();
    _startStatsCollection();
  }

  void _setupAnimations() {
    // Pulse animation for connection indicators
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Connection quality animation
    _connectionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _connectionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _connectionController, curve: Curves.elasticOut),
    );

    // Recording pulse animation
    _recordingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _recordingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _recordingController, curve: Curves.easeInOut),
    );

    // Fade animation for controls
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: 1.0,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Start connection animation
    _connectionController.forward();
  }

  void _startControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _showControls) {
        setState(() {
          _showControls = false;
        });
        _fadeController.reverse();
      }
    });
  }

  void _toggleControlsVisibility() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _fadeController.forward();
      _startControlsTimer();
    } else {
      _fadeController.reverse();
    }
  }

  void _startAudioLevelMonitoring() {
    _audioLevelTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        // Simulate audio levels (in real implementation, get from Agora)
        setState(() {
          _localAudioLevel = _isMuted ? 0.0 : math.Random().nextDouble() * 0.8;
          _remoteAudioLevel = _remoteUid != null ? math.Random().nextDouble() * 0.8 : 0.0;
        });
      }
    });
  }

  void _startStatsCollection() {
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        // Update call statistics
        _updateCallStats();
      }
    });
  }

  void _updateCallStats() {
    setState(() {
      _callStats = {
        'duration': _callSeconds,
        'quality': _connectionQuality.name,
        'participants': _remoteUid != null ? 2 : 1,
        'isRecording': _isRecording,
        'videoEnabled': _isVideoEnabled,
        'audioEnabled': !_isMuted,
      };
    });
  }

  Future<void> _initializeAgora() async {
    setState(() {
      _isConnecting = true;
      _isConnected = false;
    });

    await [Permission.microphone, if (widget.isVideo) Permission.camera].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: 'YOUR_AGORA_APP_ID'));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          setState(() {
            _isConnecting = false;
            _isConnected = true;
            _connectionQuality = ConnectionQuality.excellent;
            _startTime = DateTime.now();
            _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
              setState(() => _callSeconds += 1);
            });
          });
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() {
            _remoteUid = remoteUid;
            _connectionQuality = ConnectionQuality.good;
          });
          _connectionController.forward();
        },
        onUserOffline: (connection, remoteUid, reason) {
          setState(() {
            _remoteUid = null;
            _connectionQuality = ConnectionQuality.poor;
          });
        },
        onConnectionStateChanged: (connection, state, reason) {
          setState(() {
            switch (state) {
              case ConnectionStateType.connectionStateConnected:
                _isConnected = true;
                _isConnecting = false;
                _connectionQuality = ConnectionQuality.excellent;
                break;
              case ConnectionStateType.connectionStateReconnecting:
                _isConnecting = true;
                _connectionQuality = ConnectionQuality.poor;
                break;
              case ConnectionStateType.connectionStateFailed:
                _isConnected = false;
                _isConnecting = false;
                _connectionQuality = ConnectionQuality.bad;
                break;
              default:
                _connectionQuality = ConnectionQuality.unknown;
            }
          });
        },
        onNetworkQuality: (connection, remoteUid, txQuality, rxQuality) {
          setState(() {
            if (txQuality == QualityType.qualityExcellent && rxQuality == QualityType.qualityExcellent) {
              _connectionQuality = ConnectionQuality.excellent;
            } else if (txQuality == QualityType.qualityGood || rxQuality == QualityType.qualityGood) {
              _connectionQuality = ConnectionQuality.good;
            } else if (txQuality == QualityType.qualityPoor || rxQuality == QualityType.qualityPoor) {
              _connectionQuality = ConnectionQuality.poor;
            } else {
              _connectionQuality = ConnectionQuality.bad;
            }
          });
        },
      ),
    );

    await _engine.enableAudio();
    if (widget.isVideo) {
      await _engine.enableVideo();
      await _engine.startPreview();
      setState(() {
        _isVideoEnabled = true;
      });
    }

    await _engine.joinChannel(
      token: widget.token,
      channelId: widget.channelId,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  Future<void> _endCall() async {
    _callDurationTimer?.cancel();
    final duration = _startTime != null ? DateTime.now().difference(_startTime!).inSeconds : 0;

    await Supabase.instance.client.from('calls').update({
      'ended': true,
      'ended_at': DateTime.now().toIso8601String(),
      'duration': duration,
      'type': 'outgoing',
    }).eq('channel_id', widget.channelId);

    await _engine.leaveChannel();
    await _engine.release();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _loadUserInfo() async {
    final caller = await Supabase.instance.client
        .from('users')
        .select('display_name, avatarUrl')
        .eq('id', widget.callerId)
        .maybeSingle();

    final receiver = await Supabase.instance.client
        .from('users')
        .select('display_name, avatarUrl')
        .eq('id', widget.receiverId)
        .maybeSingle();

    setState(() {
      callerData = caller;
      receiverData = receiver;
    });
  }

  @override
  void dispose() {
    _callDurationTimer?.cancel();
    _audioLevelTimer?.cancel();
    _statsTimer?.cancel();
    _hideControlsTimer?.cancel();
    
    // Dispose animation controllers
    _pulseController.dispose();
    _connectionController.dispose();
    _recordingController.dispose();
    _fadeController.dispose();
    
    Future.microtask(() async {
      await _engine.leaveChannel();
      await _engine.release();
    });
    super.dispose();
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _engine.muteLocalAudioStream(_isMuted);
    HapticFeedback.lightImpact();
  }

  void _toggleVideo() {
    setState(() => _isVideoEnabled = !_isVideoEnabled);
    _engine.muteLocalVideoStream(!_isVideoEnabled);
    HapticFeedback.lightImpact();
  }

  void _switchCamera() {
    _engine.switchCamera();
    setState(() => _isFrontCamera = !_isFrontCamera);
    HapticFeedback.lightImpact();
  }

  void _toggleSpeaker() {
    setState(() => _isSpeakerEnabled = !_isSpeakerEnabled);
    _engine.setEnableSpeakerphone(_isSpeakerEnabled);
    HapticFeedback.mediumImpact();
  }

  void _toggleRecording() {
    setState(() => _isRecording = !_isRecording);
    if (_isRecording) {
      _recordingController.repeat();
      // Start recording logic here
    } else {
      _recordingController.stop();
      // Stop recording logic here
    }
    HapticFeedback.heavyImpact();
  }

  void _toggleScreenShare() {
    setState(() => _isScreenSharing = !_isScreenSharing);
    if (_isScreenSharing) {
      // Start screen sharing
      _engine.startScreenCapture(const ScreenCaptureParameters2());
    } else {
      // Stop screen sharing
      _engine.stopScreenCapture();
    }
    HapticFeedback.mediumImpact();
  }

  Widget _buildRemoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelId),
        ),
      );
    } else {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            "Waiting for user to join...",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final peerInfo = (currentUser != null && widget.callerId == currentUser.id)
        ? receiverData
        : callerData;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControlsVisibility,
        child: Stack(
          children: [
            // Background video
            if (widget.isVideo) _buildRemoteVideo(),
            
            // Connection status overlay
            if (_isConnecting) _buildConnectionOverlay(),
            
            // Local video with enhanced positioning
            if (widget.isVideo && _isVideoEnabled) _buildEnhancedLocalVideo(),
            
            // Audio-only mode
            if (!widget.isVideo || !_isVideoEnabled) _buildAudioOnlyMode(peerInfo),
            
            // Top status bar
            _buildTopStatusBar(peerInfo),
            
            // Controls overlay
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: _buildControlsOverlay(),
                );
              },
            ),
            
            // Recording indicator
            if (_isRecording) _buildRecordingIndicator(),
            
            // Connection quality indicator
            _buildConnectionQualityIndicator(),
            
            // Audio level visualizer
            _buildAudioLevelVisualizer(),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Connecting...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedLocalVideo() {
    return Positioned(
      left: _localVideoPosition.dx,
      top: _localVideoPosition.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _localVideoPosition = Offset(
              (_localVideoPosition.dx + details.delta.dx).clamp(0, MediaQuery.of(context).size.width - 120),
              (_localVideoPosition.dy + details.delta.dy).clamp(0, MediaQuery.of(context).size.height - 160),
            );
          });
        },
        onTap: () {
          setState(() {
            _localVideoScale = _localVideoScale == 1.0 ? 1.5 : 1.0;
          });
        },
        child: AnimatedScale(
          scale: _localVideoScale,
          duration: const Duration(milliseconds: 300),
          child: Container(
            width: 120,
            height: 160,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: _engine,
                  canvas: const VideoCanvas(uid: 0),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAudioOnlyMode(Map<String, dynamic>? peerInfo) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1a1a2e),
            Color(0xFF16213e),
            Color(0xFF0f3460),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.9 + (_pulseAnimation.value * 0.2),
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 75,
                      backgroundImage: peerInfo?['avatarUrl'] != null
                          ? NetworkImage(peerInfo!['avatarUrl'])
                          : null,
                      child: peerInfo?['avatarUrl'] == null
                          ? Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white.withOpacity(0.7),
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              peerInfo?['display_name'] ?? 'Unknown User',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDuration(_callSeconds),
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopStatusBar(Map<String, dynamic>? peerInfo) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: _endCall,
            ),
            const SizedBox(width: 8),
            if (peerInfo?['avatarUrl'] != null)
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(peerInfo!['avatarUrl']),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    peerInfo?['display_name'] ?? 'Unknown User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _formatDuration(_callSeconds),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    if (!_showControls) return const SizedBox.shrink();
    
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Primary controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  isActive: !_isMuted,
                  onPressed: _toggleMute,
                  color: _isMuted ? Colors.red : Colors.white,
                ),
                if (widget.isVideo)
                  _buildControlButton(
                    icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                    isActive: _isVideoEnabled,
                    onPressed: _toggleVideo,
                    color: _isVideoEnabled ? Colors.white : Colors.red,
                  ),
                _buildControlButton(
                  icon: Icons.call_end,
                  isActive: false,
                  onPressed: _endCall,
                  color: Colors.red,
                  size: 60,
                ),
                if (widget.isVideo)
                  _buildControlButton(
                    icon: Icons.flip_camera_ios,
                    isActive: true,
                    onPressed: _switchCamera,
                  ),
                _buildControlButton(
                  icon: _isSpeakerEnabled ? Icons.volume_up : Icons.volume_down,
                  isActive: _isSpeakerEnabled,
                  onPressed: _toggleSpeaker,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Secondary controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: _isRecording ? Icons.stop : Icons.fiber_manual_record,
                  isActive: _isRecording,
                  onPressed: _toggleRecording,
                  color: _isRecording ? Colors.red : Colors.white,
                  size: 40,
                ),
                _buildControlButton(
                  icon: _isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
                  isActive: _isScreenSharing,
                  onPressed: _toggleScreenShare,
                  size: 40,
                ),
                _buildControlButton(
                  icon: Icons.more_horiz,
                  isActive: false,
                  onPressed: () => _showCallOptions(context),
                  size: 40,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    Color? color,
    double size = 50,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive 
              ? Colors.white.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: color ?? Colors.white,
          size: size * 0.4,
        ),
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 16,
      child: AnimatedBuilder(
        animation: _recordingAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: 0.5 + (_recordingAnimation.value * 0.5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'REC',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionQualityIndicator() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      right: 16,
      child: AnimatedBuilder(
        animation: _connectionAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _connectionAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getConnectionColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getConnectionColor(),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getConnectionIcon(),
                    color: _getConnectionColor(),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _connectionQuality.name.toUpperCase(),
                    style: TextStyle(
                      color: _getConnectionColor(),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAudioLevelVisualizer() {
    final callStatsInfo = 'Participants: ${_callStats['participants'] ?? 1}, Recording: ${_callStats['isRecording'] ? "Yes" : "No"}';
    
    return Positioned(
      bottom: 200,
      left: 16,
      child: Column(
        children: [
          _buildAudioBar('You', _localAudioLevel, Colors.blue),
          const SizedBox(height: 8),
          if (_remoteUid != null)
            _buildAudioBar('Remote', _remoteAudioLevel, Colors.green),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              callStatsInfo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioBar(String label, double level, Color color) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 50,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: level,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getConnectionColor() {
    switch (_connectionQuality) {
      case ConnectionQuality.excellent:
        return Colors.green;
      case ConnectionQuality.good:
        return Colors.blue;
      case ConnectionQuality.poor:
        return Colors.orange;
      case ConnectionQuality.bad:
        return Colors.red;
      case ConnectionQuality.unknown:
        return Colors.grey;
    }
  }

  IconData _getConnectionIcon() {
    switch (_connectionQuality) {
      case ConnectionQuality.excellent:
        return Icons.signal_wifi_4_bar;
      case ConnectionQuality.good:
        return Icons.signal_wifi_4_bar;
      case ConnectionQuality.poor:
        return Icons.network_wifi;
      case ConnectionQuality.bad:
        return Icons.signal_wifi_bad;
      case ConnectionQuality.unknown:
        return Icons.signal_wifi_off;
    }
  }

  void _showCallOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Call Options',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionTile(
              icon: Icons.settings,
              title: 'Call Settings',
              onTap: () => Navigator.pop(context),
            ),
            _buildOptionTile(
              icon: Icons.info,
              title: 'Call Statistics',
              subtitle: 'Quality: ${_connectionQuality.name}, Duration: ${_formatDuration(_callSeconds)}${_isConnected ? " • Connected" : " • Disconnected"}',
              onTap: () => Navigator.pop(context),
            ),
            _buildOptionTile(
              icon: Icons.bug_report,
              title: 'Report Issue',
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            )
          : null,
      onTap: onTap,
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
  }
}
