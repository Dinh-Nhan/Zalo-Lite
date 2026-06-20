import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
// FEEDBACKS FEATURE - Domain Model
// Schema design (new collection: 'feedbacks')
// ============================================================

/// Firestore Document Schema: feedbacks/{feedbackId}
/// {
///   "user_id": "string",
///   "user_display_name": "string",
///   "user_avatar": "string",
///   "subject": "string",
///   "message": "string",
///   "admin_reply": "string | null",
///   "replied_by": "string | null",   // admin display name
///   "replied_at": "Timestamp | null",
///   "status": "open" | "resolved",
///   "created_at": "Timestamp"
/// }

class AdminFeedback {
  final String id;
  final String userId;
  final String userDisplayName;
  final String userAvatar;
  final String subject;
  final String message;
  final String? adminReply;
  final String? repliedBy;
  final DateTime? repliedAt;
  final String status; // 'open' | 'resolved'
  final DateTime createdAt;

  const AdminFeedback({
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
  bool get hasReply => adminReply != null && adminReply!.isNotEmpty;

  factory AdminFeedback.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminFeedback(
      id: doc.id,
      userId: data['user_id'] as String? ?? '',
      userDisplayName: data['user_display_name'] as String? ?? 'Unknown',
      userAvatar: data['user_avatar'] as String? ?? '',
      subject: data['subject'] as String? ?? '(No subject)',
      message: data['message'] as String? ?? '',
      adminReply: data['admin_reply'] as String?,
      repliedBy: data['replied_by'] as String?,
      repliedAt: (data['replied_at'] as Timestamp?)?.toDate(),
      status: data['status'] as String? ?? 'open',
      createdAt:
          (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
