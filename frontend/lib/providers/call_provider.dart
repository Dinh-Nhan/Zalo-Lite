import 'dart:async';
import 'package:flutter/material.dart';
import '../models/call_model.dart';

class CallProvider with ChangeNotifier {
  CallModel? _currentCall;
  int _seconds = 0;
  Timer? _timer;
  Timer? _timeoutTimer; // Timer cho thời gian chờ 20s
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  String _statusText = ""; // Thông báo trạng thái (ví dụ: "Người nhận không nhấc máy")
  CallModel? get currentCall => _currentCall;
  int get seconds => _seconds;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  String get statusText => _statusText;

  String get formattedDuration {
    final minutes = (_seconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  // void initCall(CallModel call) {
  //   _currentCall = call;
  //   _seconds = 0;
  //   _isMuted = false;
  //   _isSpeakerOn = false;
  //   notifyListeners();

  //   // 1. Thiết lập Timeout 20 giây
  //   _timeoutTimer?.cancel();
  //   _timeoutTimer = Timer(const Duration(seconds: 20), () {
  //     if (_currentCall?.status == CallStatus.dialing) {
  //       endCall(); // Tự kết thúc nếu sau 20s vẫn đang "dialing"
  //     }
  //   });

  //   // GIẢ LẬP: Sau 5 giây người kia bắt máy (Bạn có thể xóa đoạn này khi kết nối Backend)
  //   Future.delayed(const Duration(seconds: 5), () {
  //     if (_currentCall != null && _currentCall!.status == CallStatus.dialing) {
  //       acceptCall();
  //     }
  //   });
  // }
  void initCall(CallModel call) {
  _currentCall = call;
  _seconds = 0;
  notifyListeners();

  _timeoutTimer?.cancel();
  _timeoutTimer = Timer(const Duration(seconds: 20), () {
    if (_currentCall?.status == CallStatus.dialing) {
      _currentCall!.status = CallStatus.ended; // Hoặc thêm trạng thái noAnswer
      _statusText = "Người nhận không nhấc máy";
      notifyListeners();
      
      // Tự động thoát sau 3 giây hiển thị thông báo
      Future.delayed(const Duration(seconds: 3), () => endCall());
    }
  });
}

// Hàm xử lý khi người kia tắt máy (bận)
void setBusy() {
  if (_currentCall != null) {
    _currentCall!.status = CallStatus.ended;
    _statusText = "Người nhận hiện đang bận";
    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () => endCall());
  }
}
  void acceptCall() {
    if (_currentCall == null) return;
    _timeoutTimer?.cancel(); // Hủy đếm ngược timeout vì đã bắt máy
    _currentCall!.status = CallStatus.active;
    startTimer();
    notifyListeners();
  }

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _seconds++;
      notifyListeners();
    });
  }

  void endCall() {
    _timer?.cancel();
    _timeoutTimer?.cancel();
    _currentCall?.status = CallStatus.ended;
    _currentCall = null;
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
}