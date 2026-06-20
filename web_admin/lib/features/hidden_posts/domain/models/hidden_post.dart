import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
// HIDDEN POSTS FEATURE - Domain Model
// ============================================================

class HiddenPost {
  final String id;
  final String viewerId; // field in Firestore: viewer_id
  final String postId;
  final DateTime createdAt; // field in Firestore: created_at

  const HiddenPost({
    required this.id,
    required this.viewerId,
    required this.postId,
    required this.createdAt,
  });

  factory HiddenPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HiddenPost(
      id: doc.id,
      viewerId: data['viewer_id'] as String? ?? '',
      postId: data['post_id'] as String? ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
