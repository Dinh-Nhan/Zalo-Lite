import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:frontend/config/api_config.dart';
import 'package:frontend/models/call_model.dart';
import 'package:frontend/models/chat/conversation.dart';
import 'package:frontend/models/chat/message.dart';
import 'package:frontend/providers/call_provider.dart';
import 'package:frontend/services/call_notification_service.dart';
import 'package:frontend/services/chat/chat_service.dart';
import 'package:frontend/services/chat/signalr_service.dart';
import 'package:frontend/services/message_notification_service.dart';
import 'package:provider/provider.dart';

enum ChatLoadingState { idle, loading, success, error }

class ChatProvider extends ChangeNotifier with WidgetsBindingObserver {
  // ── State ──────────────────────────────────────────────────────

  List<Conversation> _conversations = [];
  ChatLoadingState _conversationsState = ChatLoadingState.idle;

  List<Message> _messages = [];
  ChatLoadingState _messagesState = ChatLoadingState.idle;
  Conversation? _activeConversation;

  bool _isOtherTyping = false;
  bool _chatVisible = false; // true chỉ khi ChatScreen đang hiển thị trực tiếp
  String? _typingUserId;
  String? _errorMessage;
  String? _currentUid;
  String? _cachedSenderName;
  String? _cachedSenderAvatar;

  // Online statuses realtime: userId → isOnline
  final Map<String, bool> _onlineStatuses = {};
  // Mốc thời gian của lần cập nhật trạng thái online gần nhất đã áp dụng cho mỗi
  // userId — dùng để loại event đến muộn/sai thứ tự (xem _onUserStatusChanged).
  final Map<String, DateTime> _lastSeenAt = {};

  // Chống double-save log cuộc gọi (cả _onCallEnded lẫn Agora onUserOffline đều có thể save)
  bool _callLogSaved = false;
  bool get callLogSaved => _callLogSaved;
  void markCallLogSaved() => _callLogSaved = true;

  // Số tin chưa đọc lúc mở conversation (để scroll + divider)
  int _openedWithUnreadCount = 0;

  // Heartbeat timer — refresh Redis TTL mỗi 3 phút
  Timer? _heartbeatTimer;

  // ── Services ───────────────────────────────────────────────────

  final ChatService _chatService = ChatService();
  SignalRService? _signalR;
  BuildContext? _context; // dùng để access CallProvider

  void setContext(BuildContext ctx) => _context = ctx;

  // ── Getters ────────────────────────────────────────────────────

  List<Conversation> get conversations => List.unmodifiable(_conversations);
  Conversation? get activeConversation => _activeConversation;
  List<Message> get messages => List.unmodifiable(_messages);
  ChatLoadingState get conversationsState => _conversationsState;
  ChatLoadingState get messagesState => _messagesState;
  bool get isOtherTyping => _isOtherTyping;
  String? get typingUserId => _typingUserId;
  String? get errorMessage => _errorMessage;

  bool isUserOnline(String userId) => _onlineStatuses[userId] ?? false;
  int get openedWithUnreadCount => _openedWithUnreadCount;
  String? get cachedSenderName => _cachedSenderName;
  String? get cachedSenderAvatar => _cachedSenderAvatar;

  // ── Init ───────────────────────────────────────────────────────

  Future<void> init(String uid) async {
    if (_currentUid == uid) return;
    _currentUid = uid;
    _signalR = SignalRService(baseUrl: ApiConfig.baseUrl, userId: uid);
    WidgetsBinding.instance.addObserver(this);
    // Connect SignalR ngay, load sender info async (chỉ cần cho cuộc gọi)
    _loadSenderInfo(uid);
    await _connectSignalR();
    await loadConversations();
    _startHeartbeat();
    // Lưu FCM token để nhận cuộc gọi khi app tắt
    CallNotificationService.saveTokenToServer();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      _signalR?.heartbeat();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _signalR?.setOnline();
      // Refresh conversations để lấy lại unread count từ server —
      // tin nhắn đến khi background không được SignalR deliver nên local state bị stale
      loadConversations();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _signalR?.setOffline();
    }
  }

  Future<void> _loadSenderInfo(String uid) async {
    try {
      final user = await _chatService.getUserProfile(uid);
      final firstName = user['first_name'] as String? ?? '';
      final lastName = user['last_name'] as String? ?? '';
      final fullName = '$firstName $lastName'.trim();
      _cachedSenderName = fullName.isNotEmpty ? fullName : uid;
      _cachedSenderAvatar = user['avatar'] as String? ?? '';
    } catch (_) {}
  }

  Future<void> _connectSignalR() async {
    final signalR = _signalR;
    if (signalR == null) return;

    signalR.onReceiveMessage = _onReceiveMessage;
    signalR.onMessageSent = _onMessageSent;
    signalR.onUserTyping = _onUserTyping;
    signalR.onMessageDeleted = _onMessageDeleted;
    signalR.onMessageUpdated = _onMessageUpdated;
    signalR.onMessageReactionUpdated = _onReactionUpdated;
    signalR.onMessageRead = _onMessageRead;
    signalR.onMessageDelivered = _onMessageDelivered;
    signalR.onConversationCreated = _onConversationCreated;
    signalR.onGroupUpdated = _onGroupUpdated;
    signalR.onParticipantRemoved = _onParticipantRemoved;
    signalR.onRemovedFromConversation = _onRemovedFromConversation;
    signalR.onUserStatusChanged = _onUserStatusChanged;
    signalR.onIncomingCall = _onIncomingCall;
    signalR.onCallAccepted = _onCallAccepted;
    signalR.onCallRejected = _onCallRejected;
    signalR.onCallEnded = _onCallEnded;
    signalR.onConnectionLost = _onConnectionLost;
    signalR.onError = _onSignalRError;

    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken(false);
      debugPrint('===== FIREBASE TOKEN (dùng cho Swagger) =====');
      debugPrint(token ?? 'null');
      debugPrint('=============================================');
      await signalR.connect(accessToken: token);
      await signalR.setOnline(); // mark online ngay sau khi connect lần đầu
      debugPrint('[ChatProvider] SignalR connected + online');
    } catch (e) {
      debugPrint('[ChatProvider] SignalR connection failed: $e');
    }
  }

  // ── Conversations ──────────────────────────────────────────────

  Future<void> loadConversations() async {
    _conversationsState = ChatLoadingState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _conversations = await _chatService.getConversations();
      _conversationsState = ChatLoadingState.success;
      // Seed trạng thái online ban đầu từ REST — SignalR UserStatusChanged
      // sẽ cập nhật tiếp theo thời gian thực sau đó. Mốc thời gian seed cũng được
      // ghi nhận để loại các event SignalR đến muộn từ trước thời điểm fetch này.
      final seededAt = DateTime.now();
      for (final c in _conversations) {
        if (c.type == 'private' && c.otherUserId != null && c.otherUserOnline != null) {
          _onlineStatuses[c.otherUserId!] = c.otherUserOnline!;
          _lastSeenAt[c.otherUserId!] = seededAt;
        }
      }
    } catch (e) {
      _conversationsState = ChatLoadingState.error;
      _errorMessage = e.toString();
      debugPrint('[ChatProvider] loadConversations error: $e');
    }
    notifyListeners();
  }

  Future<Conversation?> fetchConversation(String conversationId) async {
    try {
      return await _chatService.getConversation(conversationId);
    } catch (e) {
      debugPrint('[ChatProvider] fetchConversation error: $e');
      return null;
    }
  }

  Future<void> openConversation(Conversation conv) async {
    _chatVisible = false; // reset — ChatScreen sẽ set true sau khi render
    _openedWithUnreadCount = conv.unreadCount;
    _activeConversation = conv;
    MessageNotificationService.activeConversationId = conv.id;
    _messages = [];
    _isOtherTyping = false;
    _typingUserId = null;
    notifyListeners();
    await loadMessages(conv.id);
  }

  void _resetUnreadCount(String conversationId) {
    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx == -1 || _conversations[idx].unreadCount == 0) return;
    final list = List<Conversation>.from(_conversations);
    list[idx] = list[idx].copyWith(unreadCount: 0);
    _conversations = list;
  }

  /// Gọi từ ChatScreen khi màn hình thực sự hiển thị / ẩn
  void setConversationVisible(bool visible) {
    _chatVisible = visible;
    if (visible && _activeConversation != null) {
      // Reset badge chỉ khi user thực sự thấy màn hình chat
      _resetUnreadCount(_activeConversation!.id);
      // Mark read nếu messages đã load xong
      if (_messagesState == ChatLoadingState.success) {
        _autoMarkRead(_activeConversation!.id);
      }
    }
  }

  void closeConversation() {
    _chatVisible = false;
    _activeConversation = null;
    MessageNotificationService.activeConversationId = null;
    _messages = [];
    _messagesState = ChatLoadingState.idle;
    _isOtherTyping = false;
    _typingUserId = null;
    notifyListeners();
  }

  // ── Messages ───────────────────────────────────────────────────

  Future<void> loadMessages(String conversationId) async {
    _messagesState = ChatLoadingState.loading;
    notifyListeners();
    try {
      _messages = await _chatService.getMessages(conversationId);
      _messagesState = ChatLoadingState.success;
      notifyListeners();
      if (_chatVisible) _autoMarkRead(conversationId);
    } catch (e) {
      _messagesState = ChatLoadingState.error;
      _errorMessage = e.toString();
      debugPrint('[ChatProvider] loadMessages error: $e');
      notifyListeners();
    }
  }

  void _autoMarkRead(String conversationId) {
    final unread = _messages
        .where((m) => !m.isMine && m.status != 'read')
        .toList();
    if (unread.isEmpty) return;
    final latest = unread.last;
    _signalR?.markAsRead(conversationId, latest.id);
  }

  Future<void> sendMessage({
    required String content,
    String? replyToMessageId,
    String type = 'text',
    String? mediaUrl,
    String? thumbnailUrl,
    String? fileName,
    int? fileSize,
    int? duration,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    debugPrint('[ChatProvider] sendMessage called. Type: $type, ContentLength: ${content.length}');
    final conv = _activeConversation;
    if (conv == null) {
      debugPrint('[ChatProvider] sendMessage error: No active conversation');
      return;
    }

    // ── Optimistic UI: hiện tin nhắn ngay lập tức ──────────────
    final tempId = '_pending_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = Message(
      id: tempId,
      conversationId: conv.id,
      senderId: _currentUid ?? '',
      senderName: 'Bạn',
      senderAvatar: '',
      type: type,
      content: content,
      mediaUrl: mediaUrl,
      thumbnailUrl: thumbnailUrl,
      fileName: fileName,
      fileSize: fileSize,
      duration: duration,
      replyToMessageId: replyToMessageId,
      isForwarded: false,
      isDeleted: false,
      isEdited: false,
      status: 'sending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isMine: true,
      totalReactions: 0,
      latitude: latitude,
      longitude: longitude,
      address: address,
    );
    _messages = [..._messages, optimistic];
    notifyListeners();

    await _trySendViaSignalR(
      tempId: tempId,
      conversationId: conv.id,
      type: type,
      content: content,
      mediaUrl: mediaUrl,
      thumbnailUrl: thumbnailUrl,
      fileName: fileName,
      fileSize: fileSize,
      duration: duration,
      replyToMessageId: replyToMessageId,
      latitude: latitude,
      longitude: longitude,
      address: address,
    );
  }

  Future<void> _trySendViaSignalR({
    required String tempId,
    required String conversationId,
    required String type,
    required String content,
    String? mediaUrl,
    String? thumbnailUrl,
    String? fileName,
    int? fileSize,
    int? duration,
    String? replyToMessageId,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    debugPrint('[ChatProvider] _trySendViaSignalR called for tempId: $tempId, type: $type');
    try {
      await _signalR?.sendMessage(
        conversationId: conversationId,
        type: type,
        content: content,
        clientTempId: tempId,
        mediaUrl: mediaUrl,
        thumbnailUrl: thumbnailUrl,
        fileName: fileName,
        fileSize: fileSize,
        duration: duration,
        replyToMessageId: replyToMessageId,
        latitude: latitude, // thêm
        longitude: longitude, // thêm
        address: address,
      );
      debugPrint('[ChatProvider] _trySendViaSignalR invoke completed for tempId: $tempId');
    } catch (e) {
      // Giữ message trên UI, đánh dấu gửi lỗi để user có thể nhấn gửi lại
      _messages = _messages
          .map((m) => m.id == tempId ? m.copyWith(status: 'failed') : m)
          .toList();
      _errorMessage = e.toString();
      debugPrint('[ChatProvider] _trySendViaSignalR error: $e');
      notifyListeners();
    }
  }

  /// Gửi lại một tin nhắn đã ở trạng thái 'failed'.
  Future<void> retrySendMessage(String tempId) async {
    debugPrint('[ChatProvider] retrySendMessage called for tempId: $tempId');
    final msg = _messages.firstWhere(
      (m) => m.id == tempId,
      orElse: () => Message(
        id: '',
        conversationId: '',
        senderId: '',
        senderName: '',
        senderAvatar: '',
        type: 'text',
        content: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    if (msg.id.isEmpty) {
      debugPrint('[ChatProvider] retrySendMessage error: Message not found');
      return;
    }
    if (msg.status != 'failed') {
      debugPrint('[ChatProvider] retrySendMessage ignored: Message status is ${msg.status}');
      return;
    }

    _messages = _messages
        .map((m) => m.id == tempId ? m.copyWith(status: 'sending') : m)
        .toList();
    notifyListeners();

    // Ảnh hoặc Audio chưa upload xong lần trước (lỗi ngay từ bước upload) → thử lại từ đầu
    if (msg.mediaUrl == null && msg.localFilePath != null) {
      debugPrint('[ChatProvider] retrySendMessage: File local chưa upload. Bắt đầu upload lại cho type: ${msg.type}');
      if (msg.type == 'image') {
        await _uploadAndSendImage(
          tempId: tempId,
          conversationId: msg.conversationId,
          localFilePath: msg.localFilePath!,
        );
      } else if (msg.type == 'audio') {
        await _uploadAndSendAudio(
          tempId: tempId,
          conversationId: msg.conversationId,
          localFilePath: msg.localFilePath!,
          duration: msg.duration ?? 0,
        );
      }
      return;
    }

    await _trySendViaSignalR(
      tempId: tempId,
      conversationId: msg.conversationId,
      type: msg.type,
      content: msg.content,
      mediaUrl: msg.mediaUrl,
      thumbnailUrl: msg.thumbnailUrl,
      fileName: msg.fileName,
      fileSize: msg.fileSize,
      duration: msg.duration,
      replyToMessageId: msg.replyToMessageId,
    );
  }

  /// Gửi ảnh: hiện preview local NGAY (① render trước), upload + gửi ở nền (② call API sau).
  Future<void> sendImageMessage(File imageFile) async {
    debugPrint('[ChatProvider] sendImageMessage called. FilePath: ${imageFile.path}');
    final conv = _activeConversation;
    if (conv == null) {
      debugPrint('[ChatProvider] sendImageMessage error: No active conversation');
      return;
    }

    // ① Optimistic UI: hiện ảnh local ngay lập tức, chưa cần URL từ Cloudinary
    final tempId = '_pending_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = Message(
      id: tempId,
      conversationId: conv.id,
      senderId: _currentUid ?? '',
      senderName: 'Bạn',
      senderAvatar: '',
      type: 'image',
      content: 'Hình ảnh',
      localFilePath: imageFile.path,
      isForwarded: false,
      isDeleted: false,
      isEdited: false,
      status: 'sending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isMine: true,
      totalReactions: 0,
    );
    _messages = [..._messages, optimistic];
    notifyListeners();

    // ② Upload + gửi ở nền
    await _uploadAndSendImage(
      tempId: tempId,
      conversationId: conv.id,
      localFilePath: imageFile.path,
    );
  }

  Future<void> _uploadAndSendImage({
    required String tempId,
    required String conversationId,
    required String localFilePath,
  }) async {
    debugPrint('[ChatProvider] _uploadAndSendImage called for tempId: $tempId');
    try {
      final result = await _chatService.uploadMedia(
        conversationId: conversationId,
        file: File(localFilePath),
      );
      debugPrint('[ChatProvider] _uploadAndSendImage upload success: $result');
      await _trySendViaSignalR(
        tempId: tempId,
        conversationId: conversationId,
        type: result['media_type'] ?? result['mediaType'] ?? 'image',
        content: 'Hình ảnh',
        mediaUrl: result['media_url'] ?? result['mediaUrl'],
        fileName: result['file_name'] ?? result['fileName'],
        fileSize: result['file_size'] ?? result['fileSize'],
      );
    } catch (e) {
      // Upload lỗi — đánh dấu failed giống lúc gửi text lỗi, giữ localFilePath để retry
      _messages = _messages
          .map((m) => m.id == tempId ? m.copyWith(status: 'failed') : m)
          .toList();
      _errorMessage = e.toString();
      debugPrint('[ChatProvider] _uploadAndSendImage error: $e');
      notifyListeners();
    }
  }

  /// Gửi tin nhắn thoại: hiện preview local và duration NGAY, upload + gửi ở nền.
  Future<void> sendAudioMessage(File audioFile, int durationSeconds) async {
    debugPrint('[ChatProvider] sendAudioMessage called. Path: ${audioFile.path}, Duration: $durationSeconds s');
    final conv = _activeConversation;
    if (conv == null) {
      debugPrint('[ChatProvider] sendAudioMessage error: No active conversation');
      return;
    }

    // ① Optimistic UI: hiện audio local ngay lập tức
    final tempId = '_pending_${DateTime.now().millisecondsSinceEpoch}';
    final fileSize = await audioFile.length();
    final optimistic = Message(
      id: tempId,
      conversationId: conv.id,
      senderId: _currentUid ?? '',
      senderName: 'Bạn',
      senderAvatar: '',
      type: 'audio',
      content: 'Tin nhắn thoại',
      localFilePath: audioFile.path,
      fileSize: fileSize,
      duration: durationSeconds,
      isForwarded: false,
      isDeleted: false,
      isEdited: false,
      status: 'sending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isMine: true,
      totalReactions: 0,
    );
    _messages = [..._messages, optimistic];
    notifyListeners();

    // ② Upload + gửi ở nền
    await _uploadAndSendAudio(
      tempId: tempId,
      conversationId: conv.id,
      localFilePath: audioFile.path,
      duration: durationSeconds,
    );
  }

  Future<void> _uploadAndSendAudio({
    required String tempId,
    required String conversationId,
    required String localFilePath,
    required int duration,
  }) async {
    debugPrint('[ChatProvider] _uploadAndSendAudio called for tempId: $tempId');
    try {
      final file = File(localFilePath);
      if (!await file.exists()) {
        throw Exception('Không tìm thấy tệp ghi âm local tại đường dẫn: $localFilePath');
      }
      final result = await _chatService.uploadMedia(
        conversationId: conversationId,
        file: file,
      );
      debugPrint('[ChatProvider] _uploadAndSendAudio upload success: $result');
      await _trySendViaSignalR(
        tempId: tempId,
        conversationId: conversationId,
        type: 'audio',
        content: 'Tin nhắn thoại',
        mediaUrl: result['media_url'] ?? result['mediaUrl'],
        fileName: result['file_name'] ?? result['fileName'],
        fileSize: result['file_size'] ?? result['fileSize'],
        duration: duration,
      );
    } catch (e) {
      // Upload lỗi — đánh dấu failed giống lúc gửi text lỗi, giữ localFilePath và duration để retry
      _messages = _messages
          .map((m) => m.id == tempId ? m.copyWith(status: 'failed') : m)
          .toList();
      _errorMessage = e.toString();
      debugPrint('[ChatProvider] _uploadAndSendAudio error: $e');
      notifyListeners();
    }
  }

  void sendTyping(bool isTyping) {
    final conv = _activeConversation;
    if (conv == null) return;
    _signalR?.userTyping(conv.id, isTyping);
  }

  Future<void> deleteMessage(String messageId) async {
    final conv = _activeConversation;
    if (conv == null) return;

    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    final original = _messages[idx];

    // Optimistic: đánh dấu thu hồi ngay
    final updated = List<Message>.from(_messages);
    updated[idx] = original.copyWith(
      isDeleted: true,
      content: 'Tin nhắn đã bị thu hồi',
    );
    _messages = updated;
    // Nếu là tin cuối → update lastMessage trong conversation list
    if (_messages.isNotEmpty && _messages.last.id == messageId) {
      _updateConversationLastMessage(_messages.last);
    }
    notifyListeners();

    try {
      await _signalR?.deleteMessage(conv.id, messageId);
    } catch (e) {
      // Rollback: khôi phục lại tin nhắn gốc
      final rollbackIdx = _messages.indexWhere((m) => m.id == messageId);
      if (rollbackIdx != -1) {
        final rolledBack = List<Message>.from(_messages);
        rolledBack[rollbackIdx] = original;
        _messages = rolledBack;
        if (_messages.isNotEmpty && _messages.last.id == messageId) {
          _updateConversationLastMessage(original);
        }
      }
      _errorMessage = e.toString();
      debugPrint('[ChatProvider] deleteMessage error: $e');
      notifyListeners();
    }
  }

  Future<void> hideMessageForMe(String messageId) async {
    final conv = _activeConversation;
    if (conv == null) return;

    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    final original = _messages[idx];

    // Ẩn ngay khỏi UI — không chờ API
    final updated = List<Message>.from(_messages)..removeAt(idx);
    _messages = updated;
    notifyListeners();

    // Gọi API background để persist
    try {
      await _chatService.hideMessageForMe(conv.id, messageId);
    } catch (e) {
      // Rollback: chèn lại đúng vị trí cũ
      final restored = List<Message>.from(_messages);
      restored.insert(idx.clamp(0, restored.length), original);
      _messages = restored;
      _errorMessage = e.toString();
      debugPrint('[ChatProvider] hideMessageForMe error: $e');
      notifyListeners();
    }
  }

  Future<void> reactToMessage(String messageId, String emoji) async {
    final conv = _activeConversation;
    final uid = _currentUid;
    if (conv == null || uid == null) return;

    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    final original = _messages[idx];

    // Optimistic toggle — mirror đúng logic server (ChatService.ReactToMessageAsync)
    final reactions = original.reactions == null
        ? <String, List<String>>{}
        : original.reactions!.map((k, v) => MapEntry(k, List<String>.from(v)));
    final reactors = reactions[emoji];
    if (reactors != null) {
      reactors.contains(uid) ? reactors.remove(uid) : reactors.add(uid);
      if (reactors.isEmpty) reactions.remove(emoji);
    } else {
      reactions[emoji] = [uid];
    }

    final updated = List<Message>.from(_messages);
    updated[idx] = original.copyWith(
      reactions: reactions,
      totalReactions: reactions.values.fold<int>(0, (sum, v) => sum + v.length),
    );
    _messages = updated;
    notifyListeners();

    try {
      await _signalR?.reactToMessage(
        conversationId: conv.id,
        messageId: messageId,
        emoji: emoji,
      );
    } catch (e) {
      // Rollback về reactions gốc nếu gửi lỗi
      final rollbackIdx = _messages.indexWhere((m) => m.id == messageId);
      if (rollbackIdx != -1) {
        final rolledBack = List<Message>.from(_messages);
        rolledBack[rollbackIdx] = original;
        _messages = rolledBack;
      }
      _errorMessage = e.toString();
      debugPrint('[ChatProvider] reactToMessage error: $e');
      notifyListeners();
    }
  }

  Future<void> pinMessage(String messageId, String content) async {
    final conv = _activeConversation;
    if (conv == null) return;
    final original = conv;

    // Optimistic: hiện banner pin ngay, không chờ network
    _applyConversationUpdate(
      conv.copyWith(pinnedMessageId: messageId, pinnedMessageContent: content),
    );

    try {
      final updated = await _chatService.pinMessage(conv.id, messageId);
      _applyConversationUpdate(updated);
    } catch (e) {
      _applyConversationUpdate(original);
      rethrow;
    }
  }

  Future<void> unpinMessage() async {
    final conv = _activeConversation;
    if (conv == null) return;
    final original = conv;

    // Optimistic: ẩn banner pin ngay
    _applyConversationUpdate(conv.copyWith(clearPinnedMessage: true));

    try {
      final updated = await _chatService.unpinMessage(conv.id);
      _applyConversationUpdate(updated);
    } catch (e) {
      _applyConversationUpdate(original);
      rethrow;
    }
  }

  void _applyConversationUpdate(Conversation conv) {
    _conversations = _conversations
        .map((c) => c.id == conv.id ? conv : c)
        .toList();
    if (_activeConversation?.id == conv.id) _activeConversation = conv;
    notifyListeners();
  }

  // ── Realtime event handlers ────────────────────────────────────

  void _onReceiveMessage(Message message) {
    final m = message.withCurrentUser(_currentUid ?? '');
    if (m.conversationId == _activeConversation?.id) {
      _messages = [..._messages, m];
      if (_chatVisible && m.type != 'call') {
        _signalR?.markAsRead(_activeConversation!.id, m.id);
      }
    }
    _updateConversationLastMessage(m);
    notifyListeners();
  }

  void _onMessageSent(Message message) {
    final m = message.withCurrentUser(_currentUid ?? '');
    if (m.conversationId == _activeConversation?.id) {
      // Khớp đúng optimistic message theo clientTempId do server echo lại
      // (không còn dựa vào thứ tự gửi — tránh gán nhầm khi confirm không đúng thứ tự)
      final idx = m.clientTempId != null
          ? _messages.indexWhere((msg) => msg.id == m.clientTempId)
          : -1;
      if (idx != -1) {
        final updated = List<Message>.from(_messages);
        updated[idx] = m;
        _messages = updated;
      } else {
        _messages = [..._messages, m];
      }
    }
    _updateConversationLastMessage(m);
    notifyListeners();
  }

  /// Server từ chối/lỗi một thao tác (vd SendMessage) — đánh dấu optimistic
  /// message tương ứng là 'failed' thay vì để kẹt mãi ở 'sending'.
  void _onSignalRError(String message, String? clientTempId, String? context) {
    debugPrint('[ChatProvider] SignalR error ($context): $message');
    if (clientTempId == null) return;
    final idx = _messages.indexWhere((m) => m.id == clientTempId);
    if (idx == -1) return;
    final updated = List<Message>.from(_messages);
    updated[idx] = updated[idx].copyWith(status: 'failed');
    _messages = updated;
    notifyListeners();
  }

  void _onUserTyping(String conversationId, String userId, bool isTyping) {
    if (conversationId == _activeConversation?.id && userId != _currentUid) {
      _isOtherTyping = isTyping;
      _typingUserId = isTyping ? userId : null;
      notifyListeners();
    }
  }

  void _onMessageDeleted(String conversationId, String messageId) {
    if (conversationId == _activeConversation?.id) {
      _messages = _messages
          .map(
            (m) => m.id == messageId
                ? m.copyWith(isDeleted: true, content: 'Tin nhắn đã bị thu hồi')
                : m,
          )
          .toList();
      // Nếu là tin cuối → update lastMessage
      if (_messages.isNotEmpty && _messages.last.id == messageId) {
        _updateConversationLastMessage(_messages.last);
      }
      notifyListeners();
    }
  }

  void _onMessageUpdated(Message message) {
    if (message.conversationId == _activeConversation?.id) {
      final m = message.withCurrentUser(_currentUid ?? '');
      _messages = _messages.map((msg) => msg.id == m.id ? m : msg).toList();
      notifyListeners();
    }
  }

  void _onReactionUpdated(
    String conversationId,
    String messageId,
    Map<String, List<String>> reactions,
  ) {
    if (conversationId == _activeConversation?.id) {
      _messages = _messages
          .map(
            (m) => m.id == messageId
                ? m.copyWith(
                    reactions: reactions,
                    totalReactions: reactions.values.fold<int>(
                      0,
                      (sum, v) => sum + v.length,
                    ),
                  )
                : m,
          )
          .toList();
      notifyListeners();
    }
  }

  void _onConversationCreated(Conversation conv) {
    if (!_conversations.any((c) => c.id == conv.id)) {
      _conversations = [conv, ..._conversations];
      notifyListeners();
    }
  }

  void _onGroupUpdated(Conversation conv) {
    _conversations = _conversations
        .map((c) => c.id == conv.id ? conv : c)
        .toList();
    if (_activeConversation?.id == conv.id) _activeConversation = conv;
    notifyListeners();
  }

  void _onParticipantRemoved(String conversationId, String removedUserId) {
    if (removedUserId == _currentUid) {
      _conversations = _conversations
          .where((c) => c.id != conversationId)
          .toList();
      if (_activeConversation?.id == conversationId) closeConversation();
    }
    notifyListeners();
  }

  void _onMessageRead(String conversationId, String messageId, String readBy) {
    if (conversationId != _activeConversation?.id) return;
    // Tìm index của tin nhắn được đọc
    final readIdx = _messages.indexWhere((m) => m.id == messageId);
    final cutoff = readIdx >= 0 ? _messages[readIdx].createdAt : DateTime.now();
    // Đánh dấu tất cả tin của mình từ đầu đến tin được đọc là "read"
    _messages = _messages.map((m) {
      if (m.isMine && m.status != 'read' && !m.createdAt.isAfter(cutoff)) {
        return m.copyWith(status: 'read');
      }
      return m;
    }).toList();
    notifyListeners();
  }

  void _onMessageDelivered(
    String conversationId,
    String messageId,
    String deliveredTo,
  ) {
    if (conversationId != _activeConversation?.id) return;
    _messages = _messages.map((m) {
      if (m.isMine && m.id == messageId && m.status == 'sent') {
        return m.copyWith(status: 'delivered');
      }
      return m;
    }).toList();
    notifyListeners();
  }

  // ── Call signaling ─────────────────────────────────────────────

  SignalRService? get signalR => _signalR;
  String? get currentUid => _currentUid;

  void _onIncomingCall(
    String conversationId,
    String callerId,
    String callerName,
    String callerAvatar,
    String callType,
  ) {
    final callProvider = _context != null
        ? Provider.of<CallProvider>(_context!, listen: false)
        : null;
    if (callProvider == null) return;

    // Lấy tên caller từ conv.otherUserName — backend đã tính sẵn cho current user
    final conv = _conversations
        .where((c) => c.id == conversationId)
        .firstOrNull;
    final resolvedName = (conv?.otherUserName?.isNotEmpty == true)
        ? conv!.otherUserName!
        : (callerName.isNotEmpty && callerName != callerId
              ? callerName
              : callerId);
    final resolvedAvatar = (conv?.otherUserAvatar?.isNotEmpty == true)
        ? conv!.otherUserAvatar!
        : callerAvatar;

    _callLogSaved = false;
    final call = CallModel(
      conversationId: conversationId,
      callerId: callerId,
      calleeId: _currentUid ?? '',
      remoteName: resolvedName,
      remoteAvatar: resolvedAvatar,
      isVideo: callType == 'video',
      isIncoming: true,
      status: CallStatus.ringing,
    );
    callProvider.receiveIncomingCall(call);
  }

  void _onCallAccepted(String conversationId) {
    _context != null
        ? Provider.of<CallProvider>(_context!, listen: false).onCallAccepted()
        : null;
  }

  void _onCallRejected(String conversationId, String reason) {
    final callProvider = _context != null
        ? Provider.of<CallProvider>(_context!, listen: false)
        : null;
    if (callProvider == null) return;

    // Chỉ caller (không phải incoming) mới lưu tin nhắn lịch sử
    final call = callProvider.currentCall;
    if (call != null && !call.isIncoming) {
      saveCallMessage(
        conversationId: conversationId,
        callType: call.isVideo ? 'video' : 'voice',
        status: reason,
        durationSeconds: 0,
      );
    }
    callProvider.onCallRejected();
  }

  void _onCallEnded(String conversationId) {
    final callProvider = _context != null
        ? Provider.of<CallProvider>(_context!, listen: false)
        : null;
    if (callProvider == null) return;

    // Luôn ghi log qua phía caller (bất kể ai chủ động kết thúc). Đây là lớp
    // dự phòng cho phía caller trong trường hợp sự kiện CallEnded (SignalR)
    // tới trước khi CallScreen phát hiện remote rời qua Agora.
    final call = callProvider.currentCall;
    if (call != null &&
        !call.isIncoming &&
        call.status == CallStatus.active &&
        !_callLogSaved) {
      _callLogSaved = true;
      saveCallMessage(
        conversationId: conversationId,
        callType: call.isVideo ? 'video' : 'voice',
        status: 'answered',
        durationSeconds: callProvider.seconds,
      );
    }
    callProvider.onCallEnded();
  }

  /// Mất kết nối SignalR giữa cuộc gọi (mất mạng) — backend cũng đã tự dọn phiên gọi
  /// và báo phía đối phương khi phát hiện disconnect, nên kết thúc cục bộ ở đây luôn
  /// để không bị treo ở trạng thái "active" cho tới khi reconnect xong.
  void _onConnectionLost() {
    final callProvider = _context != null
        ? Provider.of<CallProvider>(_context!, listen: false)
        : null;
    final call = callProvider?.currentCall;
    if (callProvider == null || call == null) return;

    if (call.status == CallStatus.active && !_callLogSaved) {
      _callLogSaved = true;
      saveCallMessage(
        conversationId: call.conversationId,
        callType: call.isVideo ? 'video' : 'voice',
        status: 'answered',
        durationSeconds: callProvider.seconds,
      );
    }
    callProvider.onCallEnded();
  }

  Future<void> initiateCall({
    required String conversationId,
    required String calleeId,
    required String callType,
    String? callerName,
    String? callerAvatar,
  }) async {
    _callLogSaved = false;
    // Khi caller timeout 30s (không ai bắt), lưu tin nhắn nhỡ phía caller
    if (_context != null) {
      final callProvider = Provider.of<CallProvider>(_context!, listen: false);
      callProvider.onCallMissed = (convId, type) {
        saveCallMessage(
          conversationId: convId,
          callType: type,
          status: 'missed',
          durationSeconds: 0,
        );
      };
    }
    await _signalR?.initiateCall(
      conversationId: conversationId,
      calleeId: calleeId,
      callType: callType,
      callerName: callerName ?? _cachedSenderName ?? _currentUid ?? '',
      callerAvatar: callerAvatar ?? _cachedSenderAvatar ?? '',
    );
  }

  Future<void> acceptCall(String conversationId, String callerId) async {
    await _signalR?.acceptCall(conversationId, callerId);
  }

  Future<void> rejectCall(
    String conversationId,
    String callerId, {
    String reason = 'rejected',
  }) async {
    await _signalR?.rejectCall(conversationId, callerId, reason: reason);
  }

  Future<void> endCallSignal(String conversationId, String otherUserId) async {
    await _signalR?.endCallSignal(conversationId, otherUserId);
  }

  /// Lưu lịch sử cuộc gọi vào conversation
  Future<void> saveCallMessage({
    required String conversationId,
    required String callType,
    required String status, // answered | missed | rejected
    required int durationSeconds,
  }) async {
    String content;
    if (status == 'answered') {
      final m = durationSeconds ~/ 60;
      final s = durationSeconds % 60;
      content = callType == 'video'
          ? 'Cuộc gọi video • ${m > 0 ? "${m}p " : ""}${s}s'
          : 'Cuộc gọi thoại • ${m > 0 ? "${m}p " : ""}${s}s';
    } else if (status == 'missed') {
      content = callType == 'video'
          ? 'Cuộc gọi video nhỡ'
          : 'Cuộc gọi thoại nhỡ';
    } else if (status == 'busy') {
      content = callType == 'video'
          ? 'Cuộc gọi video • Máy đang bận'
          : 'Cuộc gọi thoại • Máy đang bận';
    } else if (status == 'cancelled') {
      content = callType == 'video'
          ? 'Cuộc gọi video đã hủy'
          : 'Cuộc gọi thoại đã hủy';
    } else {
      content = callType == 'video'
          ? 'Cuộc gọi video bị từ chối'
          : 'Cuộc gọi thoại bị từ chối';
    }

    try {
      final saved = await _chatService.sendMessage(
        conversationId: conversationId,
        type: 'call',
        content: content,
      );
      // Caller tự cập nhật UI — REST API không gửi MessageSent về sender
      final m = saved.withCurrentUser(_currentUid ?? '');
      if (_activeConversation?.id == conversationId) {
        _messages = [..._messages, m];
      }
      _updateConversationLastMessage(m);
      notifyListeners();
    } catch (e) {
      debugPrint('[ChatProvider] saveCallMessage error: $e');
    }
  }

  void _onUserStatusChanged(String userId, bool isOnline, DateTime? lastSeen) {
    // Disconnect/reconnect liên tiếp nhanh ở phía đối phương có thể khiến 2 event
    // (offline rồi online) tới không đúng thứ tự do độ trễ Firestore phía backend
    // khác nhau giữa 2 lần gọi — bỏ qua event cũ hơn event đã ghi nhận để tránh bị
    // "kẹt" sai trạng thái.
    final ts = lastSeen ?? DateTime.now();
    final prev = _lastSeenAt[userId];
    if (prev != null && ts.isBefore(prev)) return;
    _lastSeenAt[userId] = ts;
    _onlineStatuses[userId] = isOnline;
    notifyListeners();
  }

  void _onRemovedFromConversation(String conversationId) {
    _conversations = _conversations
        .where((c) => c.id != conversationId)
        .toList();
    if (_activeConversation?.id == conversationId) closeConversation();
    notifyListeners();
  }

  void _updateConversationLastMessage(Message message) {
    final idx = _conversations.indexWhere(
      (c) => c.id == message.conversationId,
    );
    if (idx == -1) return;
    final conv = _conversations[idx];

    // Tăng unread nếu tin không phải của mình VÀ (conv này không phải active HOẶC chat không đang hiển thị)
    // Dùng _chatVisible thay vì chỉ isActive: khi user thoát chat nhưng _activeConversation chưa kịp null,
    // hoặc khi nhận tin trong lúc navigate về, badge vẫn phải được đếm đúng.
    final isActive = _activeConversation?.id == message.conversationId;
    final newUnread = (!message.isMine && !(isActive && _chatVisible))
        ? conv.unreadCount + 1
        : conv.unreadCount;

    final updated = conv.copyWith(
      lastMessage: message,
      updatedAt: message.createdAt,
      unreadCount: newUnread,
    );
    final list = List<Conversation>.from(_conversations)..removeAt(idx);
    _conversations = [updated, ...list];
  }

  // ── Dispose ────────────────────────────────────────────────────

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _signalR?.setOffline();
    _signalR?.disconnect();
    super.dispose();
  }
}
