import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/models/admin_feedback.dart';
import '../domain/feedback_repository.dart';

// ============================================================
// FEEDBACKS FEATURE - Repository Implementation
// ============================================================

class FeedbackRepositoryImpl implements FeedbackRepository {
  final FirebaseFirestore _db;
  static const _col = AppConstants.feedbacksCollection;

  FeedbackRepositoryImpl(this._db);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(_col);

  @override
  Stream<List<AdminFeedback>> watchFeedbacks({String? statusFilter}) {
    Query<Map<String, dynamic>> query =
        _collection.orderBy('created_at', descending: true);

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query.snapshots().map(
        (snap) => snap.docs.map(AdminFeedback.fromFirestore).toList());
  }

  @override
  Stream<AdminFeedback?> watchFeedback(String feedbackId) {
    return _collection.doc(feedbackId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AdminFeedback.fromFirestore(snap);
    });
  }

  @override
  Future<void> replyFeedback(
    String feedbackId, {
    required String reply,
    required String repliedBy,
  }) async {
    try {
      await _collection.doc(feedbackId).update({
        'admin_reply': reply,
        'replied_by': repliedBy,
        'replied_at': FieldValue.serverTimestamp(),
        'status': AppConstants.feedbackResolved,
      });
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to reply');
    }
  }

  @override
  Future<void> markResolved(String feedbackId) async {
    try {
      await _collection.doc(feedbackId).update({
        'status': AppConstants.feedbackResolved,
      });
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to mark resolved');
    }
  }

  @override
  Future<void> reopenFeedback(String feedbackId) async {
    try {
      await _collection
          .doc(feedbackId)
          .update({'status': AppConstants.feedbackOpen});
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to reopen');
    }
  }

  @override
  Future<int> getOpenFeedbackCount() async {
    final snap = await _collection
        .where('status', isEqualTo: AppConstants.feedbackOpen)
        .count()
        .get();
    return snap.count ?? 0;
  }
}

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepositoryImpl(FirebaseFirestore.instance);
});
