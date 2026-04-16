enum MessageType { text, image, audio, video, call_log }
enum MessageStatus { sending, sent, seen, failed }

class MessageMetadata {
  final int? width;
  final int? height;
  final String? size;
  final String? callId;
  final String? callType;
  final int? duration;
  final String? callStatus;

  MessageMetadata({
    this.width,
    this.height,
    this.size,
    this.callId,
    this.callType,
    this.duration,
    this.callStatus,
  });

  factory MessageMetadata.fromMap(Map<String, dynamic> map) {
    return MessageMetadata(
      width: map['width'] as int?,
      height: map['height'] as int?,
      size: map['size'] as String?,
      callId: map['call_id'] as String?,
      callType: map['call_type'] as String?,
      duration: map['duration'] as int?,
      callStatus: map['status'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (size != null) 'size': size,
      if (callId != null) 'call_id': callId,
      if (callType != null) 'call_type': callType,
      if (duration != null) 'duration': duration,
      if (callStatus != null) 'status': callStatus,
    };
  }
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String type;
  final String content;
  final String? status;
  final DateTime createdAt;
  final MessageMetadata? metadata;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    required this.content,
    this.status,
    required this.createdAt,
    this.metadata,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['_id'] ?? '',
      conversationId: map['conversation_id'] ?? '',
      senderId: map['sender_id'] ?? '',
      type: map['type'] ?? 'text',
      content: map['content'] ?? '',
      status: map['status'] as String?,
      createdAt: map['created_at'] is DateTime
          ? map['created_at']
          : DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      metadata: map['metadata'] != null
          ? MessageMetadata.fromMap(map['metadata'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'type': type,
      'content': content,
      if (status != null) 'status': status,
      'created_at': createdAt,
      if (metadata != null) 'metadata': metadata!.toMap(),
    };
  }
}
