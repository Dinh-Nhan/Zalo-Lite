import 'package:dio/dio.dart';
import 'package:frontend/services/dio_client.dart';
import '../../models/chat/conversation.dart';
import '../../models/chat/message.dart';

class ChatService {
  final Dio _dio = DioClient.instance;

  ChatService();

  Future<List<Conversation>> getConversations() async {
    final response = await _dio.get('/api/chat/conversations');
    final data = response.data['result'] as List;
    return data.map((json) => Conversation.fromJson(json)).toList();
  }

  Future<Conversation> getConversation(String conversationId) async {
    final response = await _dio.get('/api/chat/conversations/$conversationId');
    return Conversation.fromJson(response.data['result']);
  }

  Future<List<Message>> getMessages(
    String conversationId, {
    int limit = 50,
    String? beforeMessageId,
  }) async {
    final response = await _dio.get(
      '/api/chat/conversations/$conversationId/messages',
      queryParameters: {
        'limit': limit,
        if (beforeMessageId != null) 'beforeMessageId': beforeMessageId,
      },
    );
    final data = response.data['result'] as List;
    return data.map((json) => Message.fromJson(json)).toList();
  }

  Future<Message> sendMessage({
    required String conversationId,
    required String type,
    required String content,
    String? mediaUrl,
    String? thumbnailUrl,
    String? fileName,
    int? fileSize,
    String? replyToMessageId,
    bool isForwarded = false,
  }) async {
    final response = await _dio.post(
      '/api/chat/messages',
      data: {
        'conversationId': conversationId,
        'type': type,
        'content': content,
        'isForwarded': isForwarded,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        if (fileName != null) 'fileName': fileName,
        if (fileSize != null) 'fileSize': fileSize,
        if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      },
    );
    return Message.fromJson(response.data['result']);
  }

  Future<Conversation> createConversation({
    required String type,
    required List<String> participantIds,
    String? groupName,
    String? groupAvatarUrl,
    String? groupDescription,
  }) async {
    final response = await _dio.post(
      '/api/chat/conversations',
      data: {
        'type': type,
        'participantIds': participantIds,
        if (groupName != null) 'groupName': groupName,
        if (groupAvatarUrl != null) 'groupAvatarUrl': groupAvatarUrl,
        if (groupDescription != null) 'groupDescription': groupDescription,
      },
    );
    return Conversation.fromJson(response.data['result']);
  }

  Future<Message> updateMessage({
    required String conversationId,
    required String messageId,
    required String newContent,
  }) async {
    final response = await _dio.put(
      '/api/chat/messages',
      data: {
        'conversationId': conversationId,
        'messageId': messageId,
        'newContent': newContent,
      },
    );
    return Message.fromJson(response.data['result']);
  }

  Future<void> deleteMessage(String conversationId, String messageId) async {
    await _dio.delete(
      '/api/chat/conversations/$conversationId/messages/$messageId',
    );
  }

  Future<void> reactToMessage({
    required String conversationId,
    required String messageId,
    required String emoji,
  }) async {
    await _dio.post(
      '/api/chat/messages/react',
      data: {
        'conversationId': conversationId,
        'messageId': messageId,
        'emoji': emoji,
      },
    );
  }

  Future<void> markAsRead(String conversationId, String messageId) async {
    await _dio.post(
      '/api/chat/conversations/$conversationId/messages/$messageId/read',
    );
  }

  Future<void> markAsDelivered(String conversationId, String messageId) async {
    await _dio.post(
      '/api/chat/conversations/$conversationId/messages/$messageId/delivered',
    );
  }

  Future<Conversation> updateGroup({
    required String conversationId,
    String? groupName,
    String? groupAvatarUrl,
    String? groupDescription,
  }) async {
    final response = await _dio.put(
      '/api/chat/conversations/group',
      data: {
        'conversationId': conversationId,
        if (groupName != null) 'groupName': groupName,
        if (groupAvatarUrl != null) 'groupAvatarUrl': groupAvatarUrl,
        if (groupDescription != null) 'groupDescription': groupDescription,
      },
    );
    return Conversation.fromJson(response.data['result']);
  }

  Future<Conversation> addParticipants({
    required String conversationId,
    required List<String> userIds,
  }) async {
    final response = await _dio.post(
      '/api/chat/conversations/participants',
      data: {'conversationId': conversationId, 'userIds': userIds},
    );
    return Conversation.fromJson(response.data['result']);
  }

  Future<void> removeParticipant({
    required String conversationId,
    required String userId,
  }) async {
    await _dio.delete(
      '/api/chat/conversations/$conversationId/participants/$userId',
    );
  }

  Future<void> deleteConversation(String conversationId) async {
    await _dio.delete('/api/chat/conversations/$conversationId');
  }

  Future<void> hideMessageForMe(String conversationId, String messageId) async {
    await _dio.post(
      '/api/chat/conversations/$conversationId/messages/$messageId/hide',
    );
  }

  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final response = await _dio.get('/api/user/$userId');
    return response.data['result'] as Map<String, dynamic>;
  }

  Future<void> saveFcmToken(String token) async {
    await _dio.post('/api/user/fcm-token', data: {'token': token});
  }

  // ── Pin message ───────────────────────────────────────────────

  Future<Conversation> pinMessage(String conversationId, String messageId) async {
    final response = await _dio.post(
      '/api/chat/conversations/$conversationId/pin/$messageId',
    );
    return Conversation.fromJson(response.data['result']);
  }

  Future<Conversation> unpinMessage(String conversationId) async {
    final response = await _dio.delete(
      '/api/chat/conversations/$conversationId/pin',
    );
    return Conversation.fromJson(response.data['result']);
  }

  // ── Conversation settings ─────────────────────────────────────

  Future<Map<String, dynamic>> getConversationSettings(String conversationId) async {
    final response = await _dio.get(
      '/api/chat/conversations/$conversationId/settings',
    );
    return response.data['result'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateConversationSettings(
    String conversationId, {
    bool? isNotificationEnabled,
    String? theme,
    String? backgroundUrl,
    String? emojiSet,
    bool? autoDownloadMedia,
  }) async {
    final response = await _dio.put(
      '/api/chat/conversations/$conversationId/settings',
      data: {
        if (isNotificationEnabled != null) 'isNotificationEnabled': isNotificationEnabled,
        if (theme != null) 'theme': theme,
        if (backgroundUrl != null) 'backgroundUrl': backgroundUrl,
        if (emojiSet != null) 'emojiSet': emojiSet,
        if (autoDownloadMedia != null) 'autoDownloadMedia': autoDownloadMedia,
      },
    );
    return response.data['result'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> setDisappearingDuration(
    String conversationId, {
    required int durationSeconds,
  }) async {
    final response = await _dio.put(
      '/api/chat/conversations/$conversationId/settings/disappearing',
      data: {'durationSeconds': durationSeconds},
    );
    return response.data['result'] as Map<String, dynamic>;
  }

  // ── Nickname ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> setNickname(
    String conversationId,
    String userId, {
    String? nickname,
  }) async {
    final response = await _dio.put(
      '/api/chat/conversations/$conversationId/members/$userId/nickname',
      data: {'nickname': nickname},
    );
    return response.data['result'] as Map<String, dynamic>;
  }

  // ── Group settings ────────────────────────────────────────────

  Future<Conversation> updateGroupSettings(
    String conversationId, {
    bool? onlyAdminCanSend,
    bool? onlyAdminCanEditInfo,
    bool? approvalRequiredToJoin,
  }) async {
    final response = await _dio.put(
      '/api/chat/conversations/$conversationId/group-settings',
      data: {
        if (onlyAdminCanSend != null) 'onlyAdminCanSend': onlyAdminCanSend,
        if (onlyAdminCanEditInfo != null) 'onlyAdminCanEditInfo': onlyAdminCanEditInfo,
        if (approvalRequiredToJoin != null) 'approvalRequiredToJoin': approvalRequiredToJoin,
      },
    );
    return Conversation.fromJson(response.data['result']);
  }

  // ── Join requests ─────────────────────────────────────────────

  Future<Map<String, dynamic>> createJoinRequest(String conversationId) async {
    final response = await _dio.post(
      '/api/chat/conversations/$conversationId/join-requests',
    );
    return response.data['result'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getJoinRequests(String conversationId) async {
    final response = await _dio.get(
      '/api/chat/conversations/$conversationId/join-requests',
    );
    return (response.data['result'] as List).cast<Map<String, dynamic>>();
  }

  Future<void> approveJoinRequest(String conversationId, String userId) async {
    await _dio.post(
      '/api/chat/conversations/$conversationId/join-requests/$userId/approve',
    );
  }

  Future<void> rejectJoinRequest(String conversationId, String userId) async {
    await _dio.post(
      '/api/chat/conversations/$conversationId/join-requests/$userId/reject',
    );
  }
}
