import 'models/admin_feedback.dart';

// ============================================================
// FEEDBACKS FEATURE - Repository Interface
// ============================================================

abstract interface class FeedbackRepository {
  Stream<List<AdminFeedback>> watchFeedbacks({String? statusFilter});

  Stream<AdminFeedback?> watchFeedback(String feedbackId);

  Future<void> replyFeedback(
    String feedbackId, {
    required String reply,
    required String repliedBy,
  });

  Future<void> markResolved(String feedbackId);

  Future<void> reopenFeedback(String feedbackId);

  Future<int> getOpenFeedbackCount();
}
