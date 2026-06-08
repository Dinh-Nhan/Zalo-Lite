import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../../models/chat/message.dart';
import '../../models/chat/conversation.dart';

class SignalRService {
  HubConnection? _hubConnection;
  final String baseUrl;
  final String userId;

  // Callbacks
  Function(Message)? onReceiveMessage;
  Function(Message)? onMessageSent;
  Function(String conversationId, String userId, bool isTyping)? onUserTyping;
  Function(String conversationId, String messageId, String userId)?
  onMessageRead;
  Function(String conversationId, String messageId, String userId)?
  onMessageDelivered;
  Function(
    String conversationId,
    String messageId,
    Map<String, List<String>> reactions,
  )?
  onMessageReactionUpdated;
  Function(String conversationId, String messageId)? onMessageDeleted;
  Function(Message)? onMessageUpdated;
  Function(String userId, bool isOnline, DateTime? lastSeen)?
  onUserStatusChanged;
  Function(Conversation)? onConversationCreated;
  Function(Conversation)? onGroupUpdated;
  Function(String conversationId, List<dynamic> newParticipants)?
  onParticipantsAdded;
  Function(String conversationId, String removedUserId)? onParticipantRemoved;
  Function(String conversationId)? onRemovedFromConversation;
  Function(String message)? onError;

  // Call callbacks
  Function(String conversationId, String callerId, String callerName,
      String callerAvatar, String callType)? onIncomingCall;
  Function(String conversationId)? onCallAccepted;
  Function(String conversationId, String reason)? onCallRejected;
  Function(String conversationId)? onCallEnded;

  SignalRService({required this.baseUrl, required this.userId});

  Future<void> connect({String? accessToken}) async {
    final url = accessToken != null
        ? '$baseUrl/hubs/chat?userId=$userId&access_token=$accessToken'
        : '$baseUrl/hubs/chat?userId=$userId';

    _hubConnection = HubConnectionBuilder()
        .withUrl(
          url,
          options: HttpConnectionOptions(
            transport: HttpTransportType.WebSockets,
            skipNegotiation: true,
          ),
        )
        .withAutomaticReconnect(retryDelays: [2000, 5000, 10000, 30000])
        .build();
    // Register event handlers
    _hubConnection!.on('ReceiveMessage', (args) => _handleReceiveMessage(args));
    _hubConnection!.on('MessageSent', (args) => _handleMessageSent(args));
    _hubConnection!.on('UserTyping', (args) => _handleUserTyping(args));
    _hubConnection!.on('MessageRead', (args) => _handleMessageRead(args));
    _hubConnection!.on(
      'MessageDelivered',
      (args) => _handleMessageDelivered(args),
    );
    _hubConnection!.on(
      'MessageReactionUpdated',
      (args) => _handleMessageReactionUpdated(args),
    );
    _hubConnection!.on('MessageDeleted', (args) => _handleMessageDeleted(args));
    _hubConnection!.on('MessageUpdated', (args) => _handleMessageUpdated(args));
    _hubConnection!.on(
      'UserStatusChanged',
      (args) => _handleUserStatusChanged(args),
    );
    _hubConnection!.on(
      'ConversationCreated',
      (args) => _handleConversationCreated(args),
    );
    _hubConnection!.on('GroupUpdated', (args) => _handleGroupUpdated(args));
    _hubConnection!.on(
      'ParticipantsAdded',
      (args) => _handleParticipantsAdded(args),
    );
    _hubConnection!.on(
      'ParticipantRemoved',
      (args) => _handleParticipantRemoved(args),
    );
    _hubConnection!.on(
      'RemovedFromConversation',
      (args) => _handleRemovedFromConversation(args),
    );
    _hubConnection!.on('Error', (args) => _handleError(args));
    _hubConnection!.on('IncomingCall', (args) => _handleIncomingCall(args));
    _hubConnection!.on('CallAccepted', (args) => _handleCallAccepted(args));
    _hubConnection!.on('CallRejected', (args) => _handleCallRejected(args));
    _hubConnection!.on('CallEnded', (args) => _handleCallEnded(args));

    await _hubConnection!.start();
    debugPrint('SignalR Connected');
  }

  Future<void> disconnect() async {
    await _hubConnection?.stop();
    debugPrint('SignalR Disconnected');
  }

  Future<void> setOnline() async {
    await _hubConnection?.invoke('SetOnline', args: [userId]);
  }

  Future<void> setOffline() async {
    await _hubConnection?.invoke('SetOffline', args: [userId]);
  }

  Future<void> heartbeat() async {
    await _hubConnection?.invoke('Heartbeat', args: [userId]);
  }

  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;

  Future<void> sendMessage({
    required String conversationId,
    required String type,
    required String content,
    String? mediaUrl,
    String? thumbnailUrl,
    String? fileName,
    int? fileSize,
    int? duration,
    String? replyToMessageId,
    bool isForwarded = false,
  }) async {
    await _hubConnection?.send(
      'SendMessage',
      args: [
        {
          'conversation_id': conversationId,
          'type': type,
          'content': content,
          'media_url': mediaUrl,
          'thumbnail_url': thumbnailUrl,
          'file_name': fileName,
          'file_size': fileSize,
          'duration': duration,
          'reply_to_message_id': replyToMessageId,
          'is_forwarded': isForwarded,
        },
        userId,
      ],
    );
  }

  // User typing
  Future<void> userTyping(String conversationId, bool isTyping) async {
    await _hubConnection?.invoke(
      'UserTyping',
      args: [conversationId, userId, isTyping],
    );
  }

  // Mark as read
  Future<void> markAsRead(String conversationId, String messageId) async {
    await _hubConnection?.invoke(
      'MarkAsRead',
      args: [conversationId, messageId, userId],
    );
  }

  // Mark as delivered
  Future<void> markAsDelivered(String conversationId, String messageId) async {
    await _hubConnection?.invoke(
      'MarkAsDelivered',
      args: [conversationId, messageId, userId],
    );
  }

  // React to message
  Future<void> reactToMessage({
    required String conversationId,
    required String messageId,
    required String emoji,
  }) async {
    await _hubConnection?.invoke(
      'ReactToMessage',
      args: [
        {
          'conversation_id': conversationId,
          'message_id': messageId,
          'emoji': emoji,
        },
        userId,
      ],
    );
  }

  // Delete message
  Future<void> deleteMessage(String conversationId, String messageId) async {
    await _hubConnection?.invoke(
      'DeleteMessage',
      args: [conversationId, messageId, userId],
    );
  }

  // Update message
  Future<void> updateMessage({
    required String conversationId,
    required String messageId,
    required String newContent,
  }) async {
    await _hubConnection?.invoke(
      'UpdateMessage',
      args: [
        {
          'conversation_id': conversationId,
          'message_id': messageId,
          'new_content': newContent,
        },
        userId,
      ],
    );
  }

  // Create conversation
  Future<void> createConversation({
    required String type,
    required List<String> participantIds,
    String? groupName,
    String? groupAvatarUrl,
    String? groupDescription,
  }) async {
    await _hubConnection?.invoke(
      'CreateConversation',
      args: [
        {
          'type': type,
          'participant_ids': participantIds,
          if (groupName != null) 'group_name': groupName,
          if (groupAvatarUrl != null) 'group_avatar_url': groupAvatarUrl,
          if (groupDescription != null) 'group_description': groupDescription,
        },
        userId,
      ],
    );
  }

  // Add participants
  Future<void> addParticipants({
    required String conversationId,
    required List<String> userIds,
  }) async {
    await _hubConnection?.invoke(
      'AddParticipants',
      args: [
        {'conversation_id': conversationId, 'user_ids': userIds},
        userId,
      ],
    );
  }

  // Remove participant
  Future<void> removeParticipant({
    required String conversationId,
    required String userIdToRemove,
  }) async {
    await _hubConnection?.invoke(
      'RemoveParticipant',
      args: [conversationId, userIdToRemove, userId],
    );
  }

  // Update group
  Future<void> updateGroup({
    required String conversationId,
    String? groupName,
    String? groupAvatarUrl,
    String? groupDescription,
  }) async {
    await _hubConnection?.invoke(
      'UpdateGroup',
      args: [
        {
          'conversation_id': conversationId,
          'group_name': ?groupName,
          'group_avatar_url': ?groupAvatarUrl,
          'group_description': ?groupDescription,
        },
        userId,
      ],
    );
  }

  // Event handlers
  void _handleReceiveMessage(List<Object?>? args) {
    if (args != null && args.isNotEmpty) {
      final messageJson = _toMap(args[0]);
      final message = Message.fromJson(messageJson);
      onReceiveMessage?.call(message);
    }
  }

  void _handleMessageSent(List<Object?>? args) {
    if (args != null && args.isNotEmpty) {
      final messageJson = _toMap(args[0]);
      final message = Message.fromJson(messageJson);
      onMessageSent?.call(message);
    }
  }

  void _handleUserTyping(List<Object?>? args) {
    if (args != null && args.isNotEmpty) {
      final data = _toMap(args[0]);
      onUserTyping?.call(
        data['conversation_id'] ?? data['ConversationId'],
        data['user_id'] ?? data['UserId'],
        data['is_typing'] ?? data['IsTyping'],
      );
    }
  }

  void _handleMessageRead(List<Object?>? args) {
    if (args != null && args.isNotEmpty) {
      final data = _toMap(args[0]);
      onMessageRead?.call(
        data['conversation_id'] ?? data['ConversationId'],
        data['message_id'] ?? data['MessageId'],
        data['read_by'] ?? data['ReadBy'],
      );
    }
  }

  void _handleMessageDelivered(List<Object?>? args) {
    if (args != null && args.isNotEmpty) {
      final data = _toMap(args[0]);
      onMessageDelivered?.call(
        data['conversation_id'] ?? data['ConversationId'],
        data['message_id'] ?? data['MessageId'],
        data['delivered_to'] ?? data['DeliveredTo'],
      );
    }
  }

  void _handleMessageReactionUpdated(List<Object?>? args) {
    if (args != null && args.isNotEmpty) {
      final data = _toMap(args[0]);
      final reactions = data['reactions'] ?? data['Reactions'];
      onMessageReactionUpdated?.call(
        data['conversation_id'] ?? data['ConversationId'],
        data['message_id'] ?? data['MessageId'],
        Map<String, List<String>>.from(reactions),
      );
    }
  }

  void _handleMessageDeleted(List<Object?>? args) {
    if (args != null && args.isNotEmpty) {
      final data = _toMap(args[0]);
      onMessageDeleted?.call(
        data['conversation_id'] ?? data['ConversationId'],
        data['message_id'] ?? data['MessageId'],
      );
    }
  }

  void _handleMessageUpdated(List<Object?>? args) {
    if (args != null && args.isNotEmpty) {
      final messageJson = _toMap(args[0]);
      final message = Message.fromJson(messageJson);
      onMessageUpdated?.call(message);
    }
  }

  void _handleUserStatusChanged(List<Object?>? args) {
    if (args != null && args.isNotEmpty) {
      final data = _toMap(args[0]);
      final lastSeenStr = data['last_seen'] ?? data['LastSeen'];
      onUserStatusChanged?.call(
        data['user_id'] ?? data['UserId'],
        data['is_online'] ?? data['IsOnline'],
        lastSeenStr != null ? DateTime.parse(lastSeenStr) : null,
      );
    }
  }

  void _handleConversationCreated(List<Object?>? args) {
    if (args != null && args.isNotEmpty) {
      final convJson = _toMap(args[0]);
      final conversation = Conversation.fromJson(convJson);
      onConversationCreated?.call(conversation);
    }
  }

  void _handleGroupUpdated(List<Object?>? args) {
    if (args != null && args.isNotEmpty) {
      final convJson = _toMap(args[0]);
      final conversation = Conversation.fromJson(convJson);
      onGroupUpdated?.call(conversation);
    }
  }

  void _handleParticipantsAdded(List<Object?>? args) {
    if (args != null && args.isNotEmpty) {
      final data = _toMap(args[0]);
      onParticipantsAdded?.call(
        data['conversation_id'] ?? data['ConversationId'],
        data['new_participants'] ?? data['NewParticipants'],
      );
    }
  }

  void _handleParticipantRemoved(List<Object?>? args) {
    if (args != null && args.isNotEmpty) {
      final data = _toMap(args[0]);
      onParticipantRemoved?.call(
        data['conversation_id'] ?? data['ConversationId'],
        data['removed_user_id'] ?? data['RemovedUserId'],
      );
    }
  }

  void _handleRemovedFromConversation(List<Object?>? args) {
    if (args != null && args.isNotEmpty) {
      final data = _toMap(args[0]);
      onRemovedFromConversation?.call(
        data['conversation_id'] ?? data['ConversationId'],
      );
    }
  }

  void _handleError(List<Object?>? args) {
    if (args != null && args.isNotEmpty) {
      final error = _toMap(args[0]);
      final message = error['message'] ?? error['Message'] ?? 'Unknown error';
      print('SignalR Error: $message');
      onError?.call(message);
    }
  }

  // ── Call event handlers ──────────────────────────────────────────

  void _handleIncomingCall(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final d = _toMap(args[0]);
    onIncomingCall?.call(
      d['conversation_id'] ?? '',
      d['caller_id'] ?? '',
      d['caller_name'] ?? '',
      d['caller_avatar'] ?? '',
      d['call_type'] ?? 'voice',
    );
  }

  void _handleCallAccepted(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final d = _toMap(args[0]);
    onCallAccepted?.call(d['conversation_id'] ?? '');
  }

  void _handleCallRejected(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final d = _toMap(args[0]);
    onCallRejected?.call(
      d['conversation_id'] ?? '',
      d['reason'] ?? 'rejected',
    );
  }

  void _handleCallEnded(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final d = _toMap(args[0]);
    onCallEnded?.call(d['conversation_id'] ?? '');
  }

  // ── Helpers ─────────────────────────────────────────────────────

  // signalr_netcore có thể trả về Map<Object?, Object?> thay vì Map<String, dynamic>
  Map<String, dynamic> _toMap(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  // ── Call signaling methods ───────────────────────────────────────

  Future<void> initiateCall({
    required String conversationId,
    required String calleeId,
    required String callType,
    required String callerName,
    required String callerAvatar,
  }) async {
    await _hubConnection?.send('InitiateCall', args: [
      conversationId, calleeId, callType, userId, callerName, callerAvatar,
    ]);
  }

  Future<void> acceptCall(String conversationId, String callerId) async {
    await _hubConnection?.send('AcceptCall', args: [conversationId, callerId]);
  }

  Future<void> rejectCall(String conversationId, String callerId, {String reason = 'rejected'}) async {
    await _hubConnection?.send('RejectCall', args: [conversationId, callerId, reason]);
  }

  Future<void> endCallSignal(String conversationId, String otherUserId) async {
    await _hubConnection?.send('EndCall', args: [conversationId, otherUserId]);
  }
}
