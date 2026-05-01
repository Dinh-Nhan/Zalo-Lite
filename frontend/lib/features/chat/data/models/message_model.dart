import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend/features/chat/data/models/enums/message_type.dart';

import 'reply_info_model.dart';

class MessageModel {
  final String messageId;
  final String conversationId;
  final String senderId;
  final MessageType type;
  final String content;
  final String status; // 'sending' | 'sent' | 'delivered' | 'seen'
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  // ── Reply / Quote ──────────────────────────────────────────
  final ReplyInfoModel? replyTo;

  // ── Reactions ──────────────────────────────────────────────
  /// key = userId, value = emoji string
  final Map<String, String> reactions;

  // ── Delete / Revoke ────────────────────────────────────────
  /// Danh sách userId đã xóa tin này ở phía họ
  final List<String> deletedFor;

  /// true = người gửi thu hồi (tất cả không thấy nội dung)
  final bool isRevoked;

  // ── Forward ────────────────────────────────────────────────
  final String? forwardedFromMessageId;

  // ── Seen ───────────────────────────────────────────────────
  /// key = userId, value = ISO timestamp họ đã seen
  final Map<String, String> seenBy;

  MessageModel({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    required this.type,
    required this.content,
    required this.status,
    this.metadata,
    required this.createdAt,
    this.replyTo,
    this.reactions = const {},
    this.deletedFor = const [],
    this.isRevoked = false,
    this.forwardedFromMessageId,
    this.seenBy = const {},
  });

  // ─── Helpers ────────────────────────────────────────────────
  bool isDeletedFor(String userId) => deletedFor.contains(userId);

  /// Gom reactions thành Map<emoji, count> để hiển thị
  Map<String, int> get reactionSummary {
    final summary = <String, int>{};
    for (final emoji in reactions.values) {
      summary[emoji] = (summary[emoji] ?? 0) + 1;
    }
    return summary;
  }

  // ─── Firestore ──────────────────────────────────────────────
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MessageModel(
      messageId: doc.id,
      conversationId: data['conversationId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      type: parseMessageType(data['type'] as String?),
      content: data['content'] as String? ?? '',
      status: data['status'] as String? ?? 'sent',
      metadata: (data['metadata'] as Map<String, dynamic>?)
          ?.cast<String, dynamic>(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      replyTo: data['replyTo'] != null
          ? ReplyInfoModel.fromJson(data['replyTo'] as Map<String, dynamic>)
          : null,
      reactions:
          (data['reactions'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as String),
          ) ??
          {},
      deletedFor: List<String>.from(data['deletedFor'] as List? ?? []),
      isRevoked: data['isRevoked'] as bool? ?? false,
      forwardedFromMessageId: data['forwardedFromMessageId'] as String?,
      seenBy:
          (data['seenBy'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as String),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toFirestore() => {
    'conversationId': conversationId,
    'senderId': senderId,
    'type': messageTypeToString(type),
    'content': content,
    'status': status,
    if (metadata != null) 'metadata': metadata,
    'createdAt': Timestamp.fromDate(createdAt.toUtc()),
    if (replyTo != null) 'replyTo': replyTo!.toJson(),
    'reactions': reactions,
    'deletedFor': deletedFor,
    'isRevoked': isRevoked,
    if (forwardedFromMessageId != null)
      'forwardedFromMessageId': forwardedFromMessageId,
    'seenBy': seenBy,
  };

  MessageModel copyWith({
    String? messageId,
    String? conversationId,
    String? senderId,
    MessageType? type,
    String? content,
    String? status,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    ReplyInfoModel? replyTo,
    Map<String, String>? reactions,
    List<String>? deletedFor,
    bool? isRevoked,
    String? forwardedFromMessageId,
    Map<String, String>? seenBy,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      content: content ?? this.content,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      replyTo: replyTo ?? this.replyTo,
      reactions: reactions ?? this.reactions,
      deletedFor: deletedFor ?? this.deletedFor,
      isRevoked: isRevoked ?? this.isRevoked,
      forwardedFromMessageId:
          forwardedFromMessageId ?? this.forwardedFromMessageId,
      seenBy: seenBy ?? this.seenBy,
    );
  }

  @override
  String toString() =>
      'MessageModel(messageId: $messageId, type: ${type.name}, '
      'senderId: $senderId, isRevoked: $isRevoked)';
}
