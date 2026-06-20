import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
// REPORTS FEATURE - Domain Model
// ============================================================

class AdminReport {
  final String id;
  final String reporterId;
  final String targetType; // 'user' | 'post'
  final String targetId;
  final String reason;    // 'spam' | 'harassment' | 'inappropriate' | 'other'
  final String description;
  final String status;    // 'pending' | 'resolved' | 'rejected'
  final String adminNote;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const AdminReport({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.description,
    required this.status,
    required this.adminNote,
    required this.createdAt,
    this.resolvedAt,
  });

  bool get isPending => status == 'pending';
  bool get isResolved => status == 'resolved';
  bool get isRejected => status == 'rejected';

  factory AdminReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminReport(
      id: doc.id,
      reporterId: data['reporter_id'] as String? ?? '',
      targetType: data['target_type'] as String? ?? 'post',
      targetId: data['target_id'] as String? ?? '',
      reason: data['reason'] as String? ?? 'other',
      description: data['description'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      adminNote: data['admin_note'] as String? ?? '',
      createdAt:
          (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolved_at'] as Timestamp?)?.toDate(),
    );
  }
}
