import 'package:frontend/features/chat/data/models/enums/message_type.dart';

class LastMessageModel {
  final String messageId;
  final String content;
  final MessageType type;
  final String senderId;
  final DateTime sendAt;

  LastMessageModel({
    required this.messageId,
    required this.content,
    required this.type,
    required this.senderId,
    required this.sendAt,
  });

  factory LastMessageModel.fromJson(Map<String, dynamic> json) {
    return LastMessageModel(
      messageId: json['messageId'] as String,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      senderId: json['senderId'] as String,
      sendAt: DateTime.parse(json['sendAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'content': content,
      'type': messageTypeToString(type),
      'senderId': senderId,
      'sendAt': sendAt.toIso8601String(),
    };
  }
}
