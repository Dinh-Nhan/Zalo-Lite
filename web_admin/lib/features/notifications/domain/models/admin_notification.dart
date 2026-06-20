import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
// NOTIFICATIONS FEATURE - Domain Model
// Schema design (new collection: 'admin_notifications')
// ============================================================

/// Firestore Document Schema: admin_notifications/{notifId}
/// {
///   "title": "string",
///   "body": "string",
///   "target_audience": "all" | "specific",
///   "target_user_id": "string | null",
///   "status": "draft" | "sent" | "scheduled",
///   "scheduled_at": "Timestamp | null",
///   "sent_at": "Timestamp | null",
///   "created_by": "string",   // admin display name
///   "created_at": "Timestamp"
/// }
///
/// Cloud Function Trigger: onDocumentCreated('admin_notifications/{id}')
///   → if status == 'sent', immediately push FCM
///   → if status == 'scheduled', schedule FCM via Cloud Tasks

class AdminNotification {
  final String id;
  final String title;
  final String body;
  final String targetAudience; // 'all' | 'specific'
  final String? targetUserId;
  final String status; // 'draft' | 'sent' | 'scheduled'
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final String createdBy;
  final DateTime createdAt;

  const AdminNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.targetAudience,
    this.targetUserId,
    required this.status,
    this.scheduledAt,
    this.sentAt,
    required this.createdBy,
    required this.createdAt,
  });

  bool get isDraft => status == 'draft';
  bool get isSent => status == 'sent';
  bool get isScheduled => status == 'scheduled';

  factory AdminNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminNotification(
      id: doc.id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      targetAudience: data['target_audience'] as String? ?? 'all',
      targetUserId: data['target_user_id'] as String?,
      status: data['status'] as String? ?? 'draft',
      scheduledAt: (data['scheduled_at'] as Timestamp?)?.toDate(),
      sentAt: (data['sent_at'] as Timestamp?)?.toDate(),
      createdBy: data['created_by'] as String? ?? 'Admin',
      createdAt:
          (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
