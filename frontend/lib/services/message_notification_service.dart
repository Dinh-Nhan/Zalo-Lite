import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// ID channel Android cho tin nhắn thường
const _kMsgChannelId   = 'messages';
const _kMsgChannelName = 'Tin nhắn';

/// Background handler — app bị kill hoặc background, FCM đến
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandlerMessage(RemoteMessage message) async {
  // Hệ thống tự hiện notification khi có notification field → không cần xử lý thêm
  debugPrint('[FCM-BG] message notification: ${message.data}');
}

class MessageNotificationService {
  static final _local = FlutterLocalNotificationsPlugin();

  /// ConversationId đang mở — set bởi ChatProvider để tránh hiện notification khi đang xem
  static String? activeConversationId;

  /// Caller set callback này để điều hướng khi tap notification
  static void Function(String conversationId)? onNotificationTap;

  static Future<void> initialize() async {
    // Khởi tạo flutter_local_notifications (dùng cho foreground)
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (details) {
        final convId = details.payload ?? '';
        if (convId.isNotEmpty) onNotificationTap?.call(convId);
      },
    );

    // Tạo notification channel Android 8+
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _kMsgChannelId,
          _kMsgChannelName,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ));

    // Foreground: FCM đến khi app đang mở → dùng local notification
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // Background: user tap notification → điều hướng
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
  }

  /// Kiểm tra notification tồn đọng khi app vừa mở từ killed state
  static Future<void> checkInitialMessage() async {
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null && initial.data['type'] == 'new_message') {
      _handleTap(initial);
    }
  }

  static void _handleForeground(RemoteMessage message) {
    if (message.data['type'] != 'new_message') return;

    final convId = message.data['conversation_id'] ?? '';
    // Không hiện nếu đang xem đúng conversation đó
    if (convId == activeConversationId) return;

    final title  = message.notification?.title ?? message.data['sender_name'] ?? '';
    final body   = message.notification?.body   ?? '';
    _showLocal(title, body, convId);
  }

  static void _handleTap(RemoteMessage message) {
    if (message.data['type'] != 'new_message') return;
    final convId = message.data['conversation_id'] ?? '';
    if (convId.isNotEmpty) onNotificationTap?.call(convId);
  }

  static Future<void> _showLocal(String title, String body, String convId) async {
    await _local.show(
      convId.hashCode & 0x7FFFFFFF, // int ID
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _kMsgChannelId,
          _kMsgChannelName,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(presentSound: true),
      ),
      payload: convId,
    );
  }
}
