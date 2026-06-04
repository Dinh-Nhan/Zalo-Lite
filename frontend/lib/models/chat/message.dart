class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String type;
  final String content;

  // Media
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? fileName;
  final int? fileSize;
  final int? duration;

  // Reply
  final String? replyToMessageId;
  final String? replyToContent;
  final String? replyToSenderName;

  final bool isForwarded;

  // Reactions
  final Map<String, List<String>>? reactions;
  final int totalReactions;

  // Status
  final bool isDeleted;
  final DateTime? deletedAt;
  final bool isEdited;
  final DateTime? editedAt;

  final Map<String, DateTime>? readBy;
  final Map<String, DateTime>? deliveredTo;
  final String status; // sent, delivered, read

  final DateTime createdAt;
  final DateTime updatedAt;

  final bool isMine;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.type,
    required this.content,
    this.mediaUrl,
    this.thumbnailUrl,
    this.fileName,
    this.fileSize,
    this.duration,
    this.replyToMessageId,
    this.replyToContent,
    this.replyToSenderName,
    this.isForwarded = false,
    this.reactions,
    this.totalReactions = 0,
    this.isDeleted = false,
    this.deletedAt,
    this.isEdited = false,
    this.editedAt,
    this.readBy,
    this.deliveredTo,
    this.status = 'sent',
    required this.createdAt,
    required this.updatedAt,
    this.isMine = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      senderName: json['sender_name'] ?? '',
      senderAvatar: json['sender_avatar'] ?? '',
      type: json['type'] ?? 'text',
      content: json['content'] ?? '',
      mediaUrl: json['media_url'],
      thumbnailUrl: json['thumbnail_url'],
      fileName: json['file_name'],
      fileSize: json['file_size'],
      duration: json['duration'],
      replyToMessageId: json['reply_to_message_id'],
      replyToContent: json['reply_to_content'],
      replyToSenderName: json['reply_to_sender_name'],
      isForwarded: json['is_forwarded'] ?? false,
      reactions: json['reactions'] != null
          ? Map<String, List<String>>.from(
              (json['reactions'] as Map).map(
                (key, value) =>
                    MapEntry(key.toString(), List<String>.from(value)),
              ),
            )
          : null,
      totalReactions: json['total_reactions'] ?? 0,
      isDeleted: json['is_deleted'] ?? false,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'])
          : null,
      isEdited: json['is_edited'] ?? false,
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'])
          : null,
      readBy: json['read_by'] != null
          ? Map<String, DateTime>.from(
              (json['read_by'] as Map).map(
                (key, value) => MapEntry(key.toString(), DateTime.parse(value)),
              ),
            )
          : null,
      deliveredTo: json['delivered_to'] != null
          ? Map<String, DateTime>.from(
              (json['delivered_to'] as Map).map(
                (key, value) => MapEntry(key.toString(), DateTime.parse(value)),
              ),
            )
          : null,
      status: json['status'] ?? 'sent',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ).toLocal(),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ).toLocal(),
      isMine: json['is_mine'] ?? false,
    );
  }

  Message copyWith({
    Map<String, List<String>>? reactions,
    int? totalReactions,
    bool? isDeleted,
    String? content,
    bool? isEdited,
    String? status,
    bool? isMine,
  }) {
    return Message(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      type: type,
      content: content ?? this.content,
      mediaUrl: mediaUrl,
      thumbnailUrl: thumbnailUrl,
      fileName: fileName,
      fileSize: fileSize,
      duration: duration,
      replyToMessageId: replyToMessageId,
      replyToContent: replyToContent,
      replyToSenderName: replyToSenderName,
      isForwarded: isForwarded,
      reactions: reactions ?? this.reactions,
      totalReactions: totalReactions ?? this.totalReactions,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt,
      readBy: readBy,
      deliveredTo: deliveredTo,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isMine: isMine ?? this.isMine,
    );
  }

  /// Fix isMine dựa vào currentUserId thay vì tin server
  Message withCurrentUser(String currentUserId) =>
      copyWith(isMine: senderId == currentUserId);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'type': type,
      'content': content,
      'media_url': mediaUrl,
      'thumbnail_url': thumbnailUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'duration': duration,
      'reply_to_message_id': replyToMessageId,
      'reply_to_content': replyToContent,
      'reply_to_sender_name': replyToSenderName,
      'is_forwarded': isForwarded,
      'reactions': reactions,
      'total_reactions': totalReactions,
      'is_deleted': isDeleted,
      'deleted_at': deletedAt?.toIso8601String(),
      'is_edited': isEdited,
      'edited_at': editedAt?.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_mine': isMine,
    };
  }
}
