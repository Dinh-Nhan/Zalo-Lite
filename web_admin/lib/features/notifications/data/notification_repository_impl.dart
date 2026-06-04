import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/models/admin_notification.dart';
import '../domain/notification_repository.dart';

// ============================================================
// NOTIFICATIONS FEATURE - Repository Implementation
// Cloud Function auto-triggers on document creation when
// status = 'sent' | 'scheduled'
// ============================================================

class NotificationRepositoryImpl implements NotificationRepository {
  final FirebaseFirestore _db;
  static const _col = AppConstants.notificationsCollection;

  NotificationRepositoryImpl(this._db);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(_col);

  @override
  Stream<List<AdminNotification>> watchNotifications(
      {String? statusFilter}) {
    Query<Map<String, dynamic>> query =
        _collection.orderBy('created_at', descending: true).limit(100);

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query.snapshots().map((snap) =>
        snap.docs.map(AdminNotification.fromFirestore).toList());
  }

  @override
  Future<void> sendNow({
    required String title,
    required String body,
    required String targetAudience,
    String? targetUserId,
    required String createdBy,
  }) async {
    try {
      await _collection.add({
        'title': title,
        'body': body,
        'target_audience': targetAudience,
        'target_user_id': targetUserId,
        'status': AppConstants.notificationSent,
        'scheduled_at': null,
        'sent_at': FieldValue.serverTimestamp(),
        'created_by': createdBy,
        'created_at': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to send notification');
    }
  }

  @override
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required String targetAudience,
    String? targetUserId,
    required DateTime scheduledAt,
    required String createdBy,
  }) async {
    try {
      await _collection.add({
        'title': title,
        'body': body,
        'target_audience': targetAudience,
        'target_user_id': targetUserId,
        'status': AppConstants.notificationScheduled,
        'scheduled_at': Timestamp.fromDate(scheduledAt),
        'sent_at': null,
        'created_by': createdBy,
        'created_at': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw FirestoreException(
          e.message ?? 'Failed to schedule notification');
    }
  }

  @override
  Future<void> saveDraft({
    required String title,
    required String body,
    required String targetAudience,
    String? targetUserId,
    required String createdBy,
  }) async {
    try {
      await _collection.add({
        'title': title,
        'body': body,
        'target_audience': targetAudience,
        'target_user_id': targetUserId,
        'status': AppConstants.notificationDraft,
        'scheduled_at': null,
        'sent_at': null,
        'created_by': createdBy,
        'created_at': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to save draft');
    }
  }

  @override
  Future<void> deleteNotification(String notifId) async {
    try {
      await _collection.doc(notifId).delete();
    } on FirebaseException catch (e) {
      throw FirestoreException(
          e.message ?? 'Failed to delete notification');
    }
  }
}

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(FirebaseFirestore.instance);
});
