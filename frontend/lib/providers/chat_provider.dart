import 'dart:async';
import 'dart:collection';
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

  bool _isSending = false;
  bool _isOtherTyping = false;
  bool _chatVisible = false; // true chỉ khi ChatScreen đang hiển thị trực tiếp
  String? _typingUserId;
  String? _errorMessage;
  String? _currentUid;
  String? _cachedSenderName;
  String? _cachedSenderAvatar;

  // Online statuses realtime: userId → isOnline
  final Map<String, bool> _onlineStatuses = {};

  // FIFO queue — track thứ tự pending messages để match đúng khi server confirm
  final Queue<String> _pendingQueue = Queue<String>();

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
  bool get isSending => _isSending;
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
      final lastName  = user['last_name']  as String? ?? '';
      final fullName  = '$firstName $lastName'.trim();
      _cachedSenderName   = fullName.isNotEmpty ? fullName : uid;
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
    signalR.onIncomingCall  = _onIncomingCall;
    signalR.onCallAccepted  = _onCallAccepted;
    signalR.onCallRejected  = _onCallRejected;
    signalR.onCallEnded     = _onCallEnded;

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
    _pendingQueue.clear();
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
  }) async {
    final conv = _activeConversation;
    if (conv == null) return;

    // ── Optimistic UI: hiện tin nhắn ngay lập tức ──────────────
    final tempId = '_pending_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = Message(
      id: tempId,
      conversationId: conv.id,
      senderId: _currentUid ?? '',
      senderName: 'Bạn',
      senderAvatar: '',
      type: 'text',
      content: content,
      replyToMessageId: replyToMessageId,
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
    _pendingQueue.add(tempId); // FIFO: đăng ký thứ tự gửi
    notifyListeners();

    // ── Gửi qua SignalR ─────────────────────────────────────────
    try {
      await _signalR?.sendMessage(
        conversationId: conv.id,
        type: 'text',
        content: content,
        replyToMessageId: replyToMessageId,
      );
    } catch (e) {
      // Xóa tin nhắn optimistic nếu lỗi
      _pendingQueue.remove(tempId); // rollback khỏi queue
      _messages = _messages.where((m) => m.id != tempId).toList();
      _errorMessage = e.toString();
      debugPrint('[ChatProvider] sendMessage error: $e');
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

    // Optimistic: đánh dấu thu hồi ngay
    _messages = _messages
        .map((m) => m.id == messageId
            ? m.copyWith(isDeleted: true, content: 'Tin nhắn đã bị thu hồi')
            : m)
        .toList();
    // Nếu là tin cuối → update lastMessage trong conversation list
    final deleted = _messages.firstWhere((m) => m.id == messageId,
        orElse: () => _messages.last);
    if (_messages.isNotEmpty && _messages.last.id == messageId) {
      _updateConversationLastMessage(deleted);
    }
    notifyListeners();

    try {
      await _signalR?.deleteMessage(conv.id, messageId);
    } catch (e) {
      debugPrint('[ChatProvider] deleteMessage error: $e');
    }
  }

  Future<void> hideMessageForMe(String messageId) async {
    final conv = _activeConversation;
    if (conv == null) return;

    // Ẩn ngay khỏi UI — không chờ API
    _messages = _messages.where((m) => m.id != messageId).toList();
    notifyListeners();

    // Gọi API background để persist
    try {
      await _chatService.hideMessageForMe(conv.id, messageId);
    } catch (e) {
      debugPrint('[ChatProvider] hideMessageForMe error: $e');
    }
  }

  Future<void> reactToMessage(String messageId, String emoji) async {
    final conv = _activeConversation;
    if (conv == null) return;
    try {
      await _signalR?.reactToMessage(
        conversationId: conv.id,
        messageId: messageId,
        emoji: emoji,
      );
    } catch (e) {
      debugPrint('[ChatProvider] reactToMessage error: $e');
    }
  }

  Future<void> pinMessage(String messageId, String content) async {
    final conv = _activeConversation;
    debugPrint('[pin] activeConversation=${conv?.id}');
    if (conv == null) return;
    debugPrint('[pin] calling API: conversationId=${conv.id}, messageId=$messageId');
    final updated = await _chatService.pinMessage(conv.id, messageId);
    debugPrint('[pin] success: pinnedMessageId=${updated.pinnedMessageId}');
    _applyConversationUpdate(updated);
  }

  Future<void> unpinMessage() async {
    final conv = _activeConversation;
    if (conv == null) return;
    final updated = await _chatService.unpinMessage(conv.id);
    _applyConversationUpdate(updated);
  }

  void _applyConversationUpdate(Conversation conv) {
    _conversations = _conversations.map((c) => c.id == conv.id ? conv : c).toList();
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
      if (_pendingQueue.isNotEmpty) {
        // Lấy đúng pending ID theo thứ tự gửi (FIFO)
        final pendingId = _pendingQueue.removeFirst();
        final idx = _messages.indexWhere((msg) => msg.id == pendingId);
        if (idx != -1) {
          final updated = List<Message>.from(_messages);
          updated[idx] = m;
          _messages = updated;
        } else {
          _messages = [..._messages, m];
        }
      } else {
        _messages = [..._messages, m];
      }
    }
    _updateConversationLastMessage(m);
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
          .map((m) => m.id == messageId
              ? m.copyWith(isDeleted: true, content: 'Tin nhắn đã bị thu hồi')
              : m)
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
          .map((m) => m.id == messageId
              ? m.copyWith(
                  reactions: reactions,
                  totalReactions: reactions.values
                      .fold<int>(0, (sum, v) => sum + v.length),
                )
              : m)
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
    _conversations = _conversations.map((c) => c.id == conv.id ? conv : c).toList();
    if (_activeConversation?.id == conv.id) _activeConversation = conv;
    notifyListeners();
  }

  void _onParticipantRemoved(String conversationId, String removedUserId) {
    if (removedUserId == _currentUid) {
      _conversations = _conversations.where((c) => c.id != conversationId).toList();
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

  void _onMessageDelivered(String conversationId, String messageId, String deliveredTo) {
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

  void _onIncomingCall(String conversationId, String callerId,
      String callerName, String callerAvatar, String callType) {
    final callProvider = _context != null
        ? Provider.of<CallProvider>(_context!, listen: false)
        : null;
    if (callProvider == null) return;

    // Lấy tên caller từ conv.otherUserName — backend đã tính sẵn cho current user
    final conv = _conversations.where((c) => c.id == conversationId).firstOrNull;
    final resolvedName = (conv?.otherUserName?.isNotEmpty == true)
        ? conv!.otherUserName!
        : (callerName.isNotEmpty && callerName != callerId ? callerName : callerId);
    final resolvedAvatar = (conv?.otherUserAvatar?.isNotEmpty == true)
        ? conv!.otherUserAvatar!
        : callerAvatar;

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
    _context != null
        ? Provider.of<CallProvider>(_context!, listen: false).onCallEnded()
        : null;
  }

  Future<void> initiateCall({
    required String conversationId,
    required String calleeId,
    required String callType,
    String? callerName,
    String? callerAvatar,
  }) async {
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

  Future<void> rejectCall(String conversationId, String callerId, {String reason = 'rejected'}) async {
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
      content = callType == 'video' ? 'Cuộc gọi video nhỡ' : 'Cuộc gọi thoại nhỡ';
    } else {
      content = callType == 'video' ? 'Cuộc gọi video bị từ chối' : 'Cuộc gọi thoại bị từ chối';
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
    _onlineStatuses[userId] = isOnline;
    notifyListeners();
  }

  void _onRemovedFromConversation(String conversationId) {
    _conversations = _conversations.where((c) => c.id != conversationId).toList();
    if (_activeConversation?.id == conversationId) closeConversation();
    notifyListeners();
  }

  void _updateConversationLastMessage(Message message) {
    final idx = _conversations.indexWhere((c) => c.id == message.conversationId);
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
