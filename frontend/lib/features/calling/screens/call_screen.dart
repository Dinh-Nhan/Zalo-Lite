import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '/../config/agora_config.dart';

class CallScreen extends StatefulWidget {
  // final String uid1;
  // final String uid2;

  // const CallScreen({super.key, required this.uid1, required this.uid2});
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late RtcEngine _engine;
  late String _channelName;
  int? _remoteUid;
  bool _localJoined = false;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _channelName = AgoraConfig.generateChannelName("test", "channel");
    _initAgora();
  }

  Future<void> _initAgora() async {
    await [Permission.camera, Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: AgoraConfig.appId));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          setState(() => _localJoined = true);
        },
        onUserJoined: (connection, uid, elapsed) {
          setState(() => _remoteUid = uid);
        },
        onUserOffline: (connection, uid, reason) {
          setState(() => _remoteUid = null);
        },
      ),
    );

    await _engine.enableVideo();
    await _engine.startPreview();
    await _engine.joinChannel(
      token: AgoraConfig.generateToken(_channelName),
      channelId: _channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  void _endCall() {
    _engine.leaveChannel();
    _engine.release();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video đối phương (toàn màn hình)
          _remoteUid != null
              ? AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: _engine,
                    canvas: VideoCanvas(uid: _remoteUid),
                    connection: RtcConnection(channelId: _channelName),
                  ),
                )
              : const Center(
                  child: Text(
                    'Đang chờ người kia kết nối...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),

          // Video bản thân (góc trên phải)
          if (_localJoined)
            Positioned(
              top: 50,
              right: 16,
              width: 110,
              height: 160,
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

          // Nút điều khiển
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Tắt/bật mic
                GestureDetector(
                  onTap: () {
                    setState(() => _muted = !_muted);
                    _engine.muteLocalAudioStream(_muted);
                  },
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      _muted ? Icons.mic_off : Icons.mic,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Cúp máy
                GestureDetector(
                  onTap: _endCall,
                  child: const CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.red,
                    child: Icon(Icons.call_end, color: Colors.white, size: 30),
                  ),
                ),
                // Đổi camera
                GestureDetector(
                  onTap: () => _engine.switchCamera(),
                  child: const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.flip_camera_ios, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
