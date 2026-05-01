import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

import 'friend_service.dart';

/// Các sự kiện realtime từ FriendHub
enum FriendHubEvent {
  friendRequestReceived, // có người gửi lời mời cho mình
  friendRequestAccepted, // lời mời của mình được chấp nhận
  friendRequestDeclined, // lời mời của mình bị từ chối
}

/// Payload nhận từ server khi có sự kiện realtime
class FriendRealtimeEvent {
  final FriendHubEvent type;
  final FriendshipModel friendship;

  const FriendRealtimeEvent({required this.type, required this.friendship});
}

/// Service quản lý kết nối SignalR đến FriendHub.
///
/// Cách dùng:
///   final hub = FriendHubService();
///   await hub.connect();
///   hub.events.listen((e) { ... });
///   // khi dispose:
///   await hub.disconnect();
class FriendHubService {
  static const String _baseUrl = 'http://10.0.2.2:5244';
  static const String _hubPath = '/hubs/friend';

  HubConnection? _connection;
  final _controller = StreamController<FriendRealtimeEvent>.broadcast();

  /// Stream phát ra sự kiện khi có thay đổi realtime
  Stream<FriendRealtimeEvent> get events => _controller.stream;

  bool get isConnected =>
      _connection?.state == HubConnectionState.Connected;

  /// Kết nối đến FriendHub với Firebase token.
  /// Tự động reconnect khi mất kết nối.
  Future<void> connect() async {
    if (isConnected) return;

    final token = await _getToken();
    if (token == null) {
      debugPrint('[FriendHub] Không lấy được token, bỏ qua kết nối');
      return;
    }

    final url = '$_baseUrl$_hubPath?access_token=$token';

    _connection = HubConnectionBuilder()
        .withUrl(
          url,
          options: HttpConnectionOptions(
            transport: HttpTransportType.WebSockets,
            skipNegotiation: true,
          ),
        )
        .withAutomaticReconnect(
          retryDelays: [2000, 5000, 10000, 30000],
        )
        .build();

    // ── Lắng nghe sự kiện từ server ──────────────────────────────

    _connection!.on('FriendRequestReceived', (args) {
      final data = _parseArgs(args);
      if (data == null) return;
      _emit(FriendHubEvent.friendRequestReceived, data);
    });

    _connection!.on('FriendRequestAccepted', (args) {
      final data = _parseArgs(args);
      if (data == null) return;
      _emit(FriendHubEvent.friendRequestAccepted, data);
    });

    _connection!.on('FriendRequestDeclined', (args) {
      final data = _parseArgs(args);
      if (data == null) return;
      _emit(FriendHubEvent.friendRequestDeclined, data);
    });

    _connection!.onclose(({error}) {
      debugPrint('[FriendHub] Đã đóng kết nối. Error: $error');
    });

    _connection!.onreconnecting(({error}) {
      debugPrint('[FriendHub] Đang kết nối lại... Error: $error');
    });

    _connection!.onreconnected(({connectionId}) {
      debugPrint('[FriendHub] Đã kết nối lại. Id=$connectionId');
    });

    try {
      await _connection!.start();
      debugPrint('[FriendHub] Đã kết nối thành công');
    } catch (e) {
      debugPrint('[FriendHub] Lỗi kết nối: $e');
    }
  }

  /// Ngắt kết nối và giải phóng resources
  Future<void> disconnect() async {
    await _connection?.stop();
    _connection = null;
    debugPrint('[FriendHub] Đã ngắt kết nối');
  }

  void dispose() {
    _controller.close();
    disconnect();
  }

  // ── Private helpers ───────────────────────────────────────────

  Future<String?> _getToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken(false);
    } catch (e) {
      debugPrint('[FriendHub] Lỗi lấy token: $e');
      return null;
    }
  }

  void _emit(FriendHubEvent type, FriendshipModel friendship) {
    if (!_controller.isClosed) {
      _controller.add(FriendRealtimeEvent(type: type, friendship: friendship));
    }
  }

  FriendshipModel? _parseArgs(List<Object?>? args) {
    if (args == null || args.isEmpty) return null;
    try {
      final raw = args[0];
      if (raw is Map<String, dynamic>) {
        return FriendshipModel.fromJson(raw);
      }
      // signalr_netcore có thể trả về Map<Object?, Object?>
      if (raw is Map) {
        final json = raw.map(
          (k, v) => MapEntry(k.toString(), v),
        );
        return FriendshipModel.fromJson(json);
      }
    } catch (e) {
      debugPrint('[FriendHub] Lỗi parse event: $e');
    }
    return null;
  }
}
