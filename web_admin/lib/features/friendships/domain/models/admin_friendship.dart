import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
// FRIENDSHIPS FEATURE - Domain Model
// ============================================================

class AdminFriendship {
  final String id;
  final String senderId;
  final String addresseeId;
  final String status; // 'pending' | 'accepted' | 'declined' | 'blocked'
  final String sourceType; // 'search' | 'phone_contact' | 'group' | 'qr_code'
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? addresseeName;

  const AdminFriendship({
    required this.id,
    required this.senderId,
    required this.addresseeId,
    required this.status,
    required this.sourceType,
    required this.createdAt,
    required this.updatedAt,
    this.addresseeName,
  });

  bool get isAccepted => status == 'accepted';
  bool get isPending => status == 'pending';
  bool get isBlocked => status == 'blocked';

  factory AdminFriendship.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminFriendship(
      id: doc.id,
      senderId: data['sender_id'] as String? ?? '',
      addresseeId: data['addressee_id'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      sourceType: data['source_type'] as String? ?? 'search',
      createdAt:
          (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      addresseeName: data['addressee_name'] as String?,
    );
  }
}
