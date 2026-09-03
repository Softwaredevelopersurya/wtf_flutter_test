import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../models/models.dart';
import '../services/log_service.dart';
import '../services/call_service.dart';
import '../services/agora_sdk_service.dart';
import '../utils/app_config.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_strings.dart';
import '../utils/app_typography.dart';
import 'custom_badge.dart';

/// Pre-Join Device Check Sheet
class PreJoinDeviceCheckModal extends StatefulWidget {
  final User currentUser;
  final CallRequest callRequest;
  final VoidCallback onJoin;

  const PreJoinDeviceCheckModal({
    super.key,
    required this.currentUser,
    required this.callRequest,
    required this.onJoin,
  });

  @override
  State<PreJoinDeviceCheckModal> createState() => _PreJoinDeviceCheckModalState();
}

class _PreJoinDeviceCheckModalState extends State<PreJoinDeviceCheckModal> {
  bool _isMicOn = true;
  bool _isCameraOn = true;

  @override
  Widget build(BuildContext context) {
    final isTrainer = widget.currentUser.role == UserRole.trainer;
    final primaryColor = isTrainer ? AppColors.trainerPrimary : AppColors.guruPrimary;

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: const BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pre-Join Device Check',
                style: AppTypography.h2.copyWith(color: AppColors.darkText),
              ),
              CustomBadge(
                text: isTrainer ? 'Agora Role: Trainer' : 'Agora Role: Member',
                backgroundColor: primaryColor,
              ),
            ],
          ),
          AppSpacing.gapV8,
          Text(
            AppStrings.joinPrompt,
            style: AppTypography.bodySmall.copyWith(color: AppColors.darkTextMuted),
          ),
          AppSpacing.gapV16,

          // Camera Preview Box
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.darkSurfaceVariant),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isCameraOn)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: Container(
                      color: Colors.blueGrey.shade900,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundImage: widget.currentUser.avatarUrl != null
                                  ? NetworkImage(widget.currentUser.avatarUrl!)
                                  : null,
                              child: widget.currentUser.avatarUrl == null
                                  ? Text(widget.currentUser.name[0], style: AppTypography.h1)
                                  : null,
                            ),
                            AppSpacing.gapV8,
                            Text(
                              widget.currentUser.name,
                              style: AppTypography.bodyMediumSemiBold.copyWith(color: Colors.white),
                            ),
                            AppSpacing.gapV4,
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                AppSpacing.gapH4,
                                Text(
                                  'Agora HD Video & Audio Ready',
                                  style: TextStyle(fontSize: 11, color: Colors.green.shade300),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_off_rounded, size: 40, color: AppColors.darkTextMuted),
                      AppSpacing.gapV8,
                      Text('Camera is turned off', style: AppTypography.bodySmall.copyWith(color: AppColors.darkTextMuted)),
                    ],
                  ),
              ],
            ),
          ),

          AppSpacing.gapV16,

          // Toggles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDeviceToggle(
                icon: _isMicOn ? Icons.mic : Icons.mic_off,
                label: _isMicOn ? 'Mic On' : 'Muted',
                isActive: _isMicOn,
                onTap: () => setState(() => _isMicOn = !_isMicOn),
              ),
              _buildDeviceToggle(
                icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
                label: _isCameraOn ? 'Camera On' : 'Camera Off',
                isActive: _isCameraOn,
                onTap: () => setState(() => _isCameraOn = !_isCameraOn),
              ),
            ],
          ),

          AppSpacing.gapV24,

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.video_call_rounded, color: Colors.white),
            label: const Text('Join Video Call Now'),
            onPressed: () {
              Navigator.pop(context);
              widget.onJoin();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceToggle({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.darkSurfaceVariant : Colors.red.shade900.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isActive ? AppColors.darkSurfaceVariant : Colors.red.shade700,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isActive ? Colors.white : Colors.redAccent),
            AppSpacing.gapH8,
            Text(label, style: TextStyle(fontSize: 13, color: isActive ? Colors.white : Colors.redAccent)),
          ],
        ),
      ),
    );
  }
}

/// Active In-Call Video Conference Screen (Agora RTC Engine Grid Layout & Real-Time Stream Chat)
class ActiveVideoCallScreen extends StatefulWidget {
  final User currentUser;
  final User peerUser;
  final CallRequest callRequest;
  final Future<void> Function(DateTime startedAt, DateTime endedAt) onCallEnded;

  const ActiveVideoCallScreen({
    super.key,
    required this.currentUser,
    required this.peerUser,
    required this.callRequest,
    required this.onCallEnded,
  });

  @override
  State<ActiveVideoCallScreen> createState() => _ActiveVideoCallScreenState();
}

class _ActiveVideoCallScreenState extends State<ActiveVideoCallScreen> {
  final LogService _logger = LogService();
  final CallService _callService = CallService();
  final AgoraSdkService _agoraSdkService = AgoraSdkService();

  late DateTime _callStartedAt;
  Timer? _durationTimer;
  int _elapsedSeconds = 0;

  bool _isMicMuted = false;
  bool _isVideoDisabled = false;
  bool _isFrontCamera = true;
  bool _isReconnecting = false;
  bool _showInCallChat = false;

  final TextEditingController _inCallMsgController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _callStartedAt = DateTime.now();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });

    _joinAgoraChannel();
  }

  Future<void> _joinAgoraChannel() async {
    final channelName = widget.callRequest.roomId ?? AppConfig.agoraDefaultChannel;
    const uid = 0;

    final token = await _callService.fetchAgoraToken(
      userId: widget.currentUser.id,
      channelName: channelName,
      uid: uid,
      role: widget.currentUser.role == UserRole.trainer ? 'publisher' : 'broadcaster',
    );

    await _agoraSdkService.joinChannel(
      channelName: channelName,
      token: token,
      uid: uid,
      userName: widget.currentUser.name,
    );
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _inCallMsgController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _simulateNetworkGlitch() {
    setState(() => _isReconnecting = true);
    _logger.logRtc('Network glitch detected: Agora auto-reconnecting...', isError: true);

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isReconnecting = false);
        _logger.logRtc('Agora connection successfully restored');
      }
    });
  }

  Future<void> _handleEndCall() async {
    final callEndedAt = DateTime.now();
    _durationTimer?.cancel();

    if (widget.currentUser.role == UserRole.trainer) {
      await _agoraSdkService.endRoomForAll();
    } else {
      await _agoraSdkService.leaveChannel();
    }

    await widget.onCallEnded(_callStartedAt, callEndedAt);
  }

  void _sendInCallMessage() {
    final text = _inCallMsgController.text.trim();
    if (text.isEmpty) return;
    _agoraSdkService.sendInCallMessage(
      text,
      senderName: widget.currentUser.name,
      senderId: widget.currentUser.id,
    );
    _inCallMsgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isTrainer = widget.currentUser.role == UserRole.trainer;
    final channelName = widget.callRequest.roomId ?? 'channel_agora_live_01';

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top In-Call Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  color: AppColors.darkSurface.withValues(alpha: 0.8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            ),
                            AppSpacing.gapH4,
                            Text(
                              'LIVE ${_formatDuration(_elapsedSeconds)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.gapH12,
                      Expanded(
                        child: Text(
                          'Agora Channel: $channelName',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.darkTextMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _showInCallChat ? Icons.chat_bubble : Icons.chat_bubble_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        tooltip: 'In-Call Agora Chat',
                        onPressed: () => setState(() => _showInCallChat = !_showInCallChat),
                      ),
                      IconButton(
                        icon: const Icon(Icons.wifi_tethering_error_rounded, color: AppColors.warning, size: 20),
                        tooltip: 'Test Network Resilience',
                        onPressed: _simulateNetworkGlitch,
                      ),
                    ],
                  ),
                ),

                // 2-Participant Video Grid
                Expanded(
                  child: StreamBuilder<List<AgoraPeer>>(
                    stream: _agoraSdkService.peersStream,
                    builder: (context, snapshot) {
                      final remotePeers = _agoraSdkService.remotePeers;
                      final remotePeer = remotePeers.isNotEmpty ? remotePeers.first : null;
                      final remoteUid = _agoraSdkService.remoteUids.isNotEmpty
                          ? _agoraSdkService.remoteUids.first
                          : null;

                      return Padding(
                        padding: AppSpacing.paddingSm,
                        child: Column(
                          children: [
                            // Peer Tile (Remote)
                            Expanded(
                              child: _buildParticipantTile(
                                user: widget.peerUser,
                                isSelf: false,
                                isVideoOff: remotePeer?.isVideoMuted ?? false,
                                isMuted: remotePeer?.isAudioMuted ?? false,
                                remoteUid: remoteUid,
                                channelId: channelName,
                              ),
                            ),
                            AppSpacing.gapV8,
                            // Self Tile (Local)
                            Expanded(
                              child: _buildParticipantTile(
                                user: widget.currentUser,
                                isSelf: true,
                                isVideoOff: _isVideoDisabled,
                                isMuted: _isMicMuted,
                                channelId: channelName,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // In-Call Chat Overlay Drawer (if opened)
                if (_showInCallChat) _buildInCallChatSection(),

                // In-Call Bottom Control Toolbar
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: AppSpacing.md),
                  color: AppColors.darkSurface,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mute / Unmute
                      _buildControlButton(
                        icon: _isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        label: _isMicMuted ? 'Unmute' : 'Mute',
                        isActive: !_isMicMuted,
                        onTap: () async {
                          await _agoraSdkService.toggleMic();
                          setState(() => _isMicMuted = _agoraSdkService.isMicMuted);
                        },
                      ),

                      // Video On / Off
                      _buildControlButton(
                        icon: _isVideoDisabled ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                        label: _isVideoDisabled ? 'Start Video' : 'Stop Video',
                        isActive: !_isVideoDisabled,
                        onTap: () async {
                          await _agoraSdkService.toggleCamera();
                          setState(() => _isVideoDisabled = _agoraSdkService.isVideoMuted);
                        },
                      ),

                      // Flip Camera
                      _buildControlButton(
                        icon: Icons.flip_camera_ios_rounded,
                        label: _isFrontCamera ? 'Flip' : 'Front',
                        isActive: _isFrontCamera,
                        onTap: () async {
                          await _agoraSdkService.switchCamera();
                          setState(() => _isFrontCamera = _agoraSdkService.isFrontCamera);
                        },
                      ),

                      // End Call
                      _buildControlButton(
                        icon: Icons.call_end_rounded,
                        label: isTrainer ? 'End Call' : 'Leave Call',
                        isDanger: true,
                        onTap: _handleEndCall,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Network Reconnection Overlay
            if (_isReconnecting)
              Container(
                color: Colors.black.withValues(alpha: 0.8),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.warning),
                      AppSpacing.gapV16,
                      Text(
                        'Reconnecting to Agora RTC...',
                        style: AppTypography.h3.copyWith(color: Colors.white),
                      ),
                      AppSpacing.gapV4,
                      Text(
                        'Restoring audio and video stream',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.darkTextMuted),
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

  Widget _buildInCallChatSection() {
    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.darkSurfaceVariant,
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<AgoraInCallMessage>>(
              stream: _agoraSdkService.inCallMessagesStream,
              initialData: _agoraSdkService.inCallMessages,
              builder: (context, snapshot) {
                final msgs = snapshot.data ?? [];
                if (msgs.isEmpty) {
                  return Center(
                    child: Text('No in-call Agora messages yet.', style: AppTypography.caption.copyWith(color: AppColors.darkTextMuted)),
                  );
                }
                return ListView.builder(
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    final msg = msgs[index];
                    return Text(
                      '${msg.senderName}: ${msg.message}',
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    );
                  },
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inCallMsgController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Type in-call Agora message...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  onSubmitted: (_) => _sendInCallMessage(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: AppColors.guruPrimary, size: 18),
                onPressed: _sendInCallMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantTile({
    required User user,
    required bool isSelf,
    required bool isVideoOff,
    required bool isMuted,
    int? remoteUid,
    required String channelId,
  }) {
    final roleColor = user.role == UserRole.trainer ? AppColors.trainerPrimary : AppColors.guruPrimary;
    final rtcEngine = _agoraSdkService.engine;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.darkSurfaceVariant),
      ),
      child: Stack(
        children: [
          if (!isVideoOff && rtcEngine != null && isSelf)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: rtcEngine,
                  canvas: const VideoCanvas(uid: 0),
                ),
              ),
            )
          else if (!isVideoOff && rtcEngine != null && !isSelf && remoteUid != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: rtcEngine,
                  canvas: VideoCanvas(uid: remoteUid),
                  connection: RtcConnection(channelId: channelId),
                ),
              ),
            )
          else if (!isVideoOff)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Container(
                color: isSelf ? const Color(0xFF1E2630) : const Color(0xFF282C34),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                        child: user.avatarUrl == null ? Text(user.name[0], style: AppTypography.h1) : null,
                      ),
                      AppSpacing.gapV8,
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                          ),
                          AppSpacing.gapH4,
                          const Text('Agora Live Video Stream Active', style: TextStyle(fontSize: 10, color: Colors.greenAccent)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam_off_rounded, color: AppColors.darkTextMuted, size: 36),
                  AppSpacing.gapV4,
                  Text('Video Paused', style: AppTypography.caption.copyWith(color: AppColors.darkTextMuted)),
                ],
              ),
            ),

          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isSelf ? '${user.name} (You)' : user.name,
                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  AppSpacing.gapH4,
                  CustomBadge(
                    text: user.role == UserRole.trainer ? 'Trainer' : 'Member',
                    backgroundColor: roleColor,
                  ),
                ],
              ),
            ),
          ),

          if (isMuted)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic_off_rounded, size: 14, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    bool isDanger = false,
    required VoidCallback onTap,
  }) {
    Color btnColor;
    if (isDanger) {
      btnColor = AppColors.error;
    } else if (isActive) {
      btnColor = AppColors.darkSurfaceVariant;
    } else {
      btnColor = Colors.red.shade900;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: btnColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          AppSpacing.gapV4,
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted),
          ),
        ],
      ),
    );
  }
}
