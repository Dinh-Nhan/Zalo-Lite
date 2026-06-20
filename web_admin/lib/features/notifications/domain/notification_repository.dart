import 'models/admin_notification.dart';

// ============================================================
// NOTIFICATIONS FEATURE - Repository Interface
// ============================================================

abstract interface class NotificationRepository {
  Stream<List<AdminNotification>> watchNotifications({String? statusFilter});

  /// Create notification as 'sent' → triggers Cloud Function immediately
  Future<void> sendNow({
    required String title,
    required String body,
    required String targetAudience,
    String? targetUserId,
    required String createdBy,
  });

  /// Create notification as 'scheduled' → Cloud Function sends at scheduledAt
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required String targetAudience,
    String? targetUserId,
    required DateTime scheduledAt,
    required String createdBy,
  });

  /// Save as draft (no sending)
  Future<void> saveDraft({
    required String title,
    required String body,
    required String targetAudience,
    String? targetUserId,
    required String createdBy,
  });

  Future<void> deleteNotification(String notifId);
}
