import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkeep/flutter_callkeep.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '/../config/agora_config.dart';
import '../../../models/call_model.dart';
import '../../../providers/call_provider.dart';
import '../../../providers/chat_provider.dart';

class CallScreen extends StatefulWidget {
  final CallModel call;

  const CallScreen({super.key, required this.call});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late RtcEngine _engine;
  late String _channelName;
  int? _remoteUid;
  bool _localJoined = false;
  bool _hasPopped = false; // chống double-pop

  @override
  void initState() {
    super.initState();
    final call = widget.call;
    _channelName = AgoraConfig.generateChannelName(call.callerId, call.calleeId);
    _initAgora().catchError((e) {
      debugPrint('[Agora] _initAgora failed: $e');
    });
  }

  Future<void> _initAgora() async {
    await [Permission.camera, Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: AgoraConfig.appId));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (conn, elapsed) {
          debugPrint('[Agora] joinChannel success — channel=${conn.channelId} uid=${conn.localUid}');
          setState(() => _localJoined = true);
        },
        onUserJoined: (_, uid, __) {
          debugPrint('[Agora] remote user joined: uid=$uid');
          setState(() => _remoteUid = uid);
        },
        onUserOffline: (_, uid, __) {
          debugPrint('[Agora] remote user offline: uid=$uid');
          setState(() => _remoteUid = null);
          _onRemoteLeft();
        },
        onError: (err, msg) {
          debugPrint('[Agora] ERROR: code=$err msg=$msg');
        },
      ),
    );

    if (widget.call.isVideo) {
      await _engine.enableVideo();
      await _engine.startPreview();
    } else {
      await _engine.enableAudio();
      await _engine.adjustRecordingSignalVolume(400);  // mic volume: 0-400, default 100
      await _engine.adjustPlaybackSignalVolume(400);   // speaker volume: 0-400, default 100
    }

    final token = AgoraConfig.appCertificate.isEmpty
        ? ''
        : AgoraConfig.generateToken(_channelName);
    debugPrint('[Agora] joining channel=$_channelName token=${token.isEmpty ? "(empty)" : "${token.substring(0, 20)}..."}');

    await _engine.joinChannel(
      token: token,
      channelId: _channelName,
      uid: 0,
      options: ChannelMediaOptions(
        publishCameraTrack: widget.call.isVideo,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  void _onRemoteLeft() {
    // Đối phương thoát → kết thúc cuộc gọi
    _endCall(remoteLeft: true);
  }

  Future<void> _endCall({bool remoteLeft = false}) async {
    if (_hasPopped) return; // đã đóng rồi
    _hasPopped = true;

    // Capture trước khi pop
    final callProvider = context.read<CallProvider>();
    final chatProvider = context.read<ChatProvider>();
    final call = widget.call;
    final durationSeconds = callProvider.seconds;
    final callStatus = call.status == CallStatus.active ? 'answered' : 'missed';

    // 1. Báo bên kia + lưu lịch sử (dùng provider đã capture, an toàn sau pop)
    if (!remoteLeft) {
      chatProvider.endCallSignal(call.conversationId, call.remoteUserId);
    }
    chatProvider.saveCallMessage(
      conversationId: call.conversationId,
      callType: call.isVideo ? 'video' : 'voice',
      status: callStatus,
      durationSeconds: durationSeconds,
    );

    // 2. Cleanup + đóng màn hình
    callProvider.endCall();
    await CallKeep.instance.endAllCalls(); // clear active calls khỏi CallKeep
    await _engine.leaveChannel();
    await _engine.release();
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callProvider = context.watch<CallProvider>();
    final call = widget.call;
    final isMuted = callProvider.isMuted;
    final isVideoOff = callProvider.isVideoOff;

    // Đóng màn hình khi: call null, hoặc bị từ chối/nhỡ/kết thúc
    final shouldClose = !callProvider.hasActiveCall ||
        call.status == CallStatus.rejected ||
        call.status == CallStatus.missed ||
        call.status == CallStatus.ended;
    if (shouldClose && !_hasPopped) {
      _hasPopped = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Video / background ──────────────────────────────────
          if (call.isVideo)
            _remoteUid != null
                ? AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: _engine,
                      canvas: VideoCanvas(uid: _remoteUid),
                      connection: RtcConnection(channelId: _channelName),
                    ),
                  )
                : Positioned.fill(child: _buildWaitingView(call))
          else
            Positioned.fill(child: _buildVoiceCallView(call, callProvider)),

          // Self-view (góc trên phải, chỉ video call)
          if (call.isVideo && _localJoined && !isVideoOff)
            Positioned(
              top: 60,
              right: 16,
              width: 100,
              height: 140,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _engine,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                ),
              ),
            ),

          // ── Controls ────────────────────────────────────────────
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Mic
                _ControlBtn(
                  icon: isMuted ? Icons.mic_off : Icons.mic,
                  label: isMuted ? 'Bật mic' : 'Tắt mic',
                  onTap: () {
                    callProvider.toggleMute();
                    _engine.muteLocalAudioStream(!isMuted);
                  },
                ),
                // Cúp máy
                _ControlBtn(
                  icon: Icons.call_end,
                  label: 'Cúp máy',
                  color: Colors.red,
                  size: 64,
                  onTap: () => _endCall(),
                ),
                // Camera (video) hoặc Speaker (voice)
                if (call.isVideo)
                  _ControlBtn(
                    icon: Icons.flip_camera_ios,
                    label: 'Đổi cam',
                    onTap: () => _engine.switchCamera(),
                  )
                else
                  _ControlBtn(
                    icon: callProvider.isSpeakerOn
                        ? Icons.volume_up
                        : Icons.hearing,
                    label: callProvider.isSpeakerOn ? 'Tai nghe' : 'Loa ngoài',
                    onTap: () {
                      callProvider.toggleSpeaker();
                      _engine.setEnableSpeakerphone(!callProvider.isSpeakerOn);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingView(CallModel call) {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 56,
            backgroundImage: call.remoteAvatar.isNotEmpty
                ? NetworkImage(call.remoteAvatar)
                : null,
            backgroundColor: Colors.white24,
            child: call.remoteAvatar.isEmpty
                ? Text(call.remoteName[0].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(height: 20),
          Text(call.remoteName,
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            call.isIncoming ? 'Đang kết nối...' : 'Đang gọi...',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceCallView(CallModel call, CallProvider provider) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0068FF), Color(0xFF004CC8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 64,
            backgroundImage: call.remoteAvatar.isNotEmpty
                ? NetworkImage(call.remoteAvatar)
                : null,
            backgroundColor: Colors.white24,
            child: call.remoteAvatar.isEmpty
                ? Text(call.remoteName[0].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 48,
                        color: Colors.white,
                        fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(height: 24),
          Text(call.remoteName,
              style: const TextStyle(
                  color: Colors.white, fontSize: 26, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text(
            call.status == CallStatus.active
                ? provider.formattedDuration
                : 'Đang gọi...',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _ControlBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white24,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: size / 2,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: size * 0.5),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}
