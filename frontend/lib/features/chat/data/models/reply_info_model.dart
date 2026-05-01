/// Snapshot của tin nhắn được reply — lưu thẳng vào message để tránh extra read.
class ReplyInfoModel {
  final String messageId;
  final String senderId;
  final String content; // text hoặc caption ảnh
  final String type;    // 'text' | 'image' | ...

  ReplyInfoModel({
    required this.messageId,
    required this.senderId,
    required this.content,
    required this.type,
  });

  factory ReplyInfoModel.fromJson(Map<String, dynamic> json) {
    return ReplyInfoModel(
      messageId: json['messageId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      type: json['type'] as String? ?? 'text',
    );
  }

  Map<String, dynamic> toJson() => {
        'messageId': messageId,
        'senderId': senderId,
        'content': content,
        'type': type,
      };
}
