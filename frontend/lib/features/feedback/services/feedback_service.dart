import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feedback_model.dart';

class FeedbackService {
  static final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  static const String _collection =
      'feedbacks';

  // ============================
  // CREATE
  // ============================

  static Future<String> createFeedback({
    required String userId,
    required String userDisplayName,
    required String userAvatar,
    required String subject,
    required String message,
  }) async {
    final docRef =
        await _db.collection(_collection).add({
      'user_id': userId,
      'user_display_name':
          userDisplayName,
      'user_avatar': userAvatar,
      'subject': subject,
      'message': message,
      'admin_reply': null,
      'replied_by': null,
      'replied_at': null,
      'status': 'open',
      'created_at':
          FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  // ============================
  // GET ALL OF USER
  // ============================

  static Future<List<FeedbackModel>>
      getUserFeedbacks(
    String userId,
  ) async {
    final snapshot = await _db
        .collection(_collection)
        .where(
          'user_id',
          isEqualTo: userId,
        )
        .orderBy(
          'created_at',
          descending: true,
        )
        .get();

    return snapshot.docs
        .map(
          (doc) =>
              FeedbackModel.fromFirestore(
                  doc),
        )
        .toList();
  }

  // ============================
  // STREAM REALTIME
  // ============================

  static Stream<List<FeedbackModel>>
      streamUserFeedbacks(
    String userId,
  ) {
    return _db
        .collection(_collection)
        .where(
          'user_id',
          isEqualTo: userId,
        )
        .orderBy(
          'created_at',
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    FeedbackModel
                        .fromFirestore(
                            doc),
              )
              .toList(),
        );
  }

  // ============================
  // GET ONE
  // ============================

  static Future<FeedbackModel?>
      getFeedbackById(
    String feedbackId,
  ) async {
    final doc = await _db
        .collection(_collection)
        .doc(feedbackId)
        .get();

    if (!doc.exists) return null;

    return FeedbackModel.fromFirestore(
      doc,
    );
  }

  // ============================
  // UPDATE
  // ============================

  static Future<void> updateFeedback({
    required String feedbackId,
    required String subject,
    required String message,
  }) async {
    await _db
        .collection(_collection)
        .doc(feedbackId)
        .update({
      'subject': subject,
      'message': message,
    });
  }

  // ============================
  // DELETE
  // ============================

  static Future<void> deleteFeedback(
    String feedbackId,
  ) async {
    await _db
        .collection(_collection)
        .doc(feedbackId)
        .delete();
  }

  // ============================
  // ADMIN REPLY
  // ============================

  static Future<void> replyFeedback({
    required String feedbackId,
    required String adminReply,
    required String adminName,
  }) async {
    await _db
        .collection(_collection)
        .doc(feedbackId)
        .update({
      'admin_reply': adminReply,
      'replied_by': adminName,
      'replied_at':
          FieldValue.serverTimestamp(),
      'status': 'resolved',
    });
  }
}