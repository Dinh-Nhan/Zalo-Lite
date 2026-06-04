import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;

  final String userId;
  final String userDisplayName;
  final String userAvatar;

  final String subject;
  final String message;

  final String? adminReply;
  final String? repliedBy;
  final DateTime? repliedAt;

  final String status;

  final DateTime createdAt;

  const FeedbackModel({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    required this.userAvatar,
    required this.subject,
    required this.message,
    this.adminReply,
    this.repliedBy,
    this.repliedAt,
    required this.status,
    required this.createdAt,
  });

  bool get isOpen => status == 'open';

  bool get isResolved => status == 'resolved';

  bool get hasReply =>
      adminReply != null &&
      adminReply!.trim().isNotEmpty;

  factory FeedbackModel.fromFirestore(
    DocumentSnapshot doc,
  ) {
    final data =
        doc.data() as Map<String, dynamic>;

    return FeedbackModel(
      id: doc.id,
      userId: data['user_id'] ?? '',
      userDisplayName:
          data['user_display_name'] ?? '',
      userAvatar: data['user_avatar'] ?? '',
      subject: data['subject'] ?? '',
      message: data['message'] ?? '',
      adminReply: data['admin_reply'],
      repliedBy: data['replied_by'],
      repliedAt:
          (data['replied_at'] as Timestamp?)
              ?.toDate(),
      status: data['status'] ?? 'open',
      createdAt:
          (data['created_at'] as Timestamp?)
                  ?.toDate() ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'user_display_name': userDisplayName,
      'user_avatar': userAvatar,
      'subject': subject,
      'message': message,
      'admin_reply': adminReply,
      'replied_by': repliedBy,
      'replied_at': repliedAt != null
          ? Timestamp.fromDate(repliedAt!)
          : null,
      'status': status,
      'created_at':
          Timestamp.fromDate(createdAt),
    };
  }

  FeedbackModel copyWith({
    String? id,
    String? userId,
    String? userDisplayName,
    String? userAvatar,
    String? subject,
    String? message,
    String? adminReply,
    String? repliedBy,
    DateTime? repliedAt,
    String? status,
    DateTime? createdAt,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userDisplayName:
          userDisplayName ??
          this.userDisplayName,
      userAvatar:
          userAvatar ?? this.userAvatar,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      adminReply:
          adminReply ?? this.adminReply,
      repliedBy: repliedBy ?? this.repliedBy,
      repliedAt: repliedAt ?? this.repliedAt,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}