enum ConversationType { private, group }

class ConversationParticipant {
  final String userId;
  final String role;

  ConversationParticipant({
    required this.userId,
    required this.role,
  });

  factory ConversationParticipant.fromMap(Map<String, dynamic> map) {
    return ConversationParticipant(
      userId: map['user_id'] ?? '',
      role: map['role'] ?? 'member',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'role': role,
    };
  }
}

class LastMessage {
  final String messageId;
  final String content;
  final String type;
  final String senderId;
  final DateTime sentAt;

  LastMessage({
    required this.messageId,
    required this.content,
    required this.type,
    required this.senderId,
    required this.sentAt,
  });

  factory LastMessage.fromMap(Map<String, dynamic> map) {
    return LastMessage(
      messageId: map['message_id'] ?? '',
      content: map['content'] ?? '',
      type: map['type'] ?? 'text',
      senderId: map['sender_id'] ?? '',
      sentAt: map['sent_at'] is DateTime 
          ? map['sent_at'] 
          : DateTime.parse(map['sent_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message_id': messageId,
      'content': content,
      'type': type,
      'sender_id': senderId,
      'sent_at': sentAt,
    };
  }
}

class ConversationSettings {
  final bool isMuted;
  final String theme;

  ConversationSettings({
    required this.isMuted,
    required this.theme,
  });

  factory ConversationSettings.fromMap(Map<String, dynamic> map) {
    return ConversationSettings(
      isMuted: map['is_muted'] ?? false,
      theme: map['theme'] ?? 'classic',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'is_muted': isMuted,
      'theme': theme,
    };
  }
}

class ConversationModel {
  final String id;
  final String type;
  final List<ConversationParticipant> participants;
  final LastMessage? lastMessage;
  final ConversationSettings settings;
  final DateTime updatedAt;

  ConversationModel({
    required this.id,
    required this.type,
    required this.participants,
    this.lastMessage,
    required this.settings,
    required this.updatedAt,
  });

  factory ConversationModel.fromMap(Map<String, dynamic> map) {
    return ConversationModel(
      id: map['_id'] ?? '',
      type: map['type'] ?? 'private',
      participants: (map['participants'] as List?)
          ?.map((p) => ConversationParticipant.fromMap(p as Map<String, dynamic>))
          .toList() ?? [],
      lastMessage: map['last_message'] != null
          ? LastMessage.fromMap(map['last_message'] as Map<String, dynamic>)
          : null,
      settings: map['settings'] != null
          ? ConversationSettings.fromMap(map['settings'] as Map<String, dynamic>)
          : ConversationSettings(isMuted: false, theme: 'classic'),
      updatedAt: map['updated_at'] is DateTime
          ? map['updated_at']
          : DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'type': type,
      'participants': participants.map((p) => p.toMap()).toList(),
      'last_message': lastMessage?.toMap(),
      'settings': settings.toMap(),
      'updated_at': updatedAt,
    };
  }
}
