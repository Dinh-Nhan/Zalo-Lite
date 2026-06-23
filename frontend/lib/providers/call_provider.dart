import 'dart:async';
import 'package:flutter/material.dart';
import '../models/call_model.dart';

class CallProvider with ChangeNotifier {
  CallModel? _currentCall;
  int _seconds = 0;
  Timer? _timer;
  Timer? _timeoutTimer;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isVideoOff = false;

  // Gọi bởi ChatProvider khi caller timeout 30s (không có ai bắt)
  Function(String conversationId, String callType)? onCallMissed;

  CallModel? get currentCall => _currentCall;
  int get seconds => _seconds;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isVideoOff => _isVideoOff;
  bool get hasActiveCall => _currentCall != null;

  String get formattedDuration {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Caller side ──────────────────────────────────────────────────

  void startOutgoingCall(CallModel call) {
    _currentCall = call;
    _seconds = 0;
    _isMuted = false;
    _isSpeakerOn = false;
    _isVideoOff = false;
    notifyListeners();

    // Timeout 30s nếu không ai bắt
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (_currentCall?.status == CallStatus.dialing) {
        final convId = _currentCall!.conversationId;
        final callType = _currentCall!.isVideo ? 'video' : 'voice';
        _currentCall!.status = CallStatus.missed;
        notifyListeners();
        onCallMissed?.call(convId, callType);
        Future.delayed(const Duration(seconds: 2), endCall);
      }
    });
  }

  // ── Callee side ──────────────────────────────────────────────────

  void receiveIncomingCall(CallModel call) {
    _currentCall = call;
    notifyListeners();
  }

  // ── Both sides ───────────────────────────────────────────────────

  /// Gọi khi đối phương chấp nhận (caller nhận CallAccepted)
  void onCallAccepted() {
    if (_currentCall == null) return;
    _timeoutTimer?.cancel();
    _currentCall!.status = CallStatus.active;
    _startTimer();
    notifyListeners();
  }

  /// Gọi khi callee bấm chấp nhận
  void acceptCall() {
    if (_currentCall == null) return;
    _timeoutTimer?.cancel();
    _currentCall!.status = CallStatus.active;
    _startTimer();
    notifyListeners();
  }

  /// Gọi khi reject
  void rejectCall() {
    _currentCall?.status = CallStatus.rejected;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 500), endCall);
  }

  /// Đối phương từ chối
  void onCallRejected() {
    if (_currentCall == null) return;
    _timeoutTimer?.cancel(); // tránh double-save nếu timer chưa kịp fire
    _currentCall!.status = CallStatus.rejected;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 500), endCall);
  }

  /// Đối phương kết thúc cuộc gọi
  void onCallEnded() {
    if (_currentCall == null) return;
    _currentCall!.status = CallStatus.ended;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 500), endCall);
  }

  void endCall() {
    _timer?.cancel();
    _timeoutTimer?.cancel();
    _currentCall = null;
    _seconds = 0;
    notifyListeners();
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    notifyListeners();
  }

  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    notifyListeners();
  }

  void toggleVideo() {
    _isVideoOff = !_isVideoOff;
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _seconds++;
      notifyListeners();
    });
  }
}
