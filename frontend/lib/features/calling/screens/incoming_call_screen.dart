import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:provider/provider.dart';
import '../../../models/call_model.dart';
import '../../../providers/call_provider.dart';
import '../../../providers/chat_provider.dart';
import 'call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final CallModel call;

  const IncomingCallScreen({super.key, required this.call});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  Timer? _timeoutTimer;
  int _remainingSeconds = 30;
  Timer? _countdownTimer;
  bool _isClosing = false; // ngăn double-pop

  @override
  void initState() {
    super.initState();
    context.read<CallProvider>().addListener(_onCallChanged);
    _startRingtone();
    _startTimeout();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _countdownTimer?.cancel();
    FlutterRingtonePlayer().stop();
    context.read<CallProvider>().removeListener(_onCallChanged);
    super.dispose();
  }

  void _startRingtone() {
    FlutterRingtonePlayer().playRingtone(looping: true);
  }

  void _startTimeout() {
    // Đếm ngược 30 giây
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) t.cancel();
    });

    // Hết 30s → tự ngắt như "nhỡ máy"
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted) return;
      _missedCall();
    });
  }

  void _close({required void Function(ChatProvider, CallProvider) action}) {
    if (_isClosing || !mounted) return;
    _isClosing = true;
    _timeoutTimer?.cancel();
    _countdownTimer?.cancel();
    FlutterRingtonePlayer().stop();

    // Capture providers trước khi pop
    final chatProvider = context.read<ChatProvider>();
    final callProvider = context.read<CallProvider>();

    Navigator.of(context, rootNavigator: true).pop();

    // Thực hiện action sau khi đã đóng màn hình
    action(chatProvider, callProvider);
  }

  void _missedCall() {
    _close(action: (chat, callProv) {
      callProv.rejectCall();
      chat.rejectCall(widget.call.conversationId, widget.call.callerId, reason: 'missed');
    });
  }

  void _onCallChanged() {
    if (!mounted || _isClosing) return;
    if (!context.read<CallProvider>().hasActiveCall) {
      _close(action: (_, __) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final call = widget.call;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            Column(
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: Colors.white24,
                  backgroundImage: call.remoteAvatar.isNotEmpty
                      ? NetworkImage(call.remoteAvatar)
                      : null,
                  child: call.remoteAvatar.isEmpty
                      ? Text(
                          call.remoteName.isNotEmpty
                              ? call.remoteName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 40,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(height: 20),
                Text(
                  call.remoteName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  call.isVideo ? 'Cuộc gọi video đến...' : 'Cuộc gọi thoại đến...',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7), fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tự động từ chối sau $_remainingSeconds giây',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
                ),
              ],
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallButton(
                    icon: Icons.call_end,
                    color: Colors.red,
                    label: 'Từ chối',
                    onTap: () => _rejectCall(context),
                  ),
                  _CallButton(
                    icon: call.isVideo ? Icons.videocam : Icons.call,
                    color: Colors.green,
                    label: 'Chấp nhận',
                    onTap: () => _acceptCall(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _rejectCall(BuildContext ctx) {
    _close(action: (chat, callProv) {
      callProv.rejectCall();
      chat.rejectCall(call.conversationId, call.callerId, reason: 'rejected');
    });
  }

  void _acceptCall(BuildContext ctx) {
    if (_isClosing || !mounted) return;
    _isClosing = true;
    _timeoutTimer?.cancel();
    _countdownTimer?.cancel();
    FlutterRingtonePlayer().stop();

    final chatProvider = ctx.read<ChatProvider>();
    chatProvider.acceptCall(call.conversationId, call.callerId);
    ctx.read<CallProvider>().acceptCall();

    Navigator.of(ctx, rootNavigator: true).pushReplacement(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CallScreen(call: call),
      ),
    );
  }

  CallModel get call => widget.call;
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _CallButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: CircleAvatar(
            radius: 36,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }
}
