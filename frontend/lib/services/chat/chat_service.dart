import 'package:dio/dio.dart';
import '../../models/chat/conversation.dart';
import '../../models/chat/message.dart';

class ChatService {
  final Dio _dio;
  final String baseUrl;

  ChatService({required this.baseUrl})
    : _dio = Dio(BaseOptions(baseUrl: baseUrl));

  // Set auth token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Get conversations
  Future<List<Conversation>> getConversations() async {
    final response = await _dio.get('/api/chat/conversations');
    final data = response.data['data'] as List;
    return data.map((json) => Conversation.fromJson(json)).toList();
  }

  // Get conversation by ID
  Future<Conversation> getConversation(String conversationId) async {
    final response = await _dio.get('/api/chat/conversations/$conversationId');
    return Conversation.fromJson(response.data['data']);
  }

  // Get messages
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
    final data = response.data['data'] as List;
    return data.map((json) => Message.fromJson(json)).toList();
  }

  // Send message
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
        'conversation_id': conversationId,
        'type': type,
        'content': content,
        if (mediaUrl != null) 'media_url': mediaUrl,
        if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
        if (fileName != null) 'file_name': fileName,
        if (fileSize != null) 'file_size': fileSize,
        if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
        'is_forwarded': isForwarded,
      },
    );
    return Message.fromJson(response.data['data']);
  }

  // Create conversation
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
        'participant_ids': participantIds,
        if (groupName != null) 'group_name': groupName,
        if (groupAvatarUrl != null) 'group_avatar_url': groupAvatarUrl,
        if (groupDescription != null) 'group_description': groupDescription,
      },
    );
    return Conversation.fromJson(response.data['data']);
  }

  // Update message
  Future<Message> updateMessage({
    required String conversationId,
    required String messageId,
    required String newContent,
  }) async {
    final response = await _dio.put(
      '/api/chat/messages',
      data: {
        'conversation_id': conversationId,
        'message_id': messageId,
        'new_content': newContent,
      },
    );
    return Message.fromJson(response.data['data']);
  }

  // Delete message
  Future<void> deleteMessage(String conversationId, String messageId) async {
    await _dio.delete(
      '/api/chat/conversations/$conversationId/messages/$messageId',
    );
  }

  // React to message
  Future<void> reactToMessage({
    required String conversationId,
    required String messageId,
    required String emoji,
  }) async {
    await _dio.post(
      '/api/chat/messages/react',
      data: {
        'conversation_id': conversationId,
        'message_id': messageId,
        'emoji': emoji,
      },
    );
  }

  // Mark as read
  Future<void> markAsRead(String conversationId, String messageId) async {
    await _dio.post(
      '/api/chat/conversations/$conversationId/messages/$messageId/read',
    );
  }

  // Mark as delivered
  Future<void> markAsDelivered(String conversationId, String messageId) async {
    await _dio.post(
      '/api/chat/conversations/$conversationId/messages/$messageId/delivered',
    );
  }

  // Update group
  Future<Conversation> updateGroup({
    required String conversationId,
    String? groupName,
    String? groupAvatarUrl,
    String? groupDescription,
  }) async {
    final response = await _dio.put(
      '/api/chat/conversations/group',
      data: {
        'conversation_id': conversationId,
        if (groupName != null) 'group_name': groupName,
        if (groupAvatarUrl != null) 'group_avatar_url': groupAvatarUrl,
        if (groupDescription != null) 'group_description': groupDescription,
      },
    );
    return Conversation.fromJson(response.data['data']);
  }

  // Add participants
  Future<Conversation> addParticipants({
    required String conversationId,
    required List<String> userIds,
  }) async {
    final response = await _dio.post(
      '/api/chat/conversations/participants',
      data: {'conversation_id': conversationId, 'user_ids': userIds},
    );
    return Conversation.fromJson(response.data['data']);
  }

  // Remove participant
  Future<void> removeParticipant({
    required String conversationId,
    required String userId,
  }) async {
    await _dio.delete(
      '/api/chat/conversations/$conversationId/participants/$userId',
    );
  }

  // Delete conversation
  Future<void> deleteConversation(String conversationId) async {
    await _dio.delete('/api/chat/conversations/$conversationId');
  }
}
