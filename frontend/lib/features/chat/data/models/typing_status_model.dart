import 'package:cloud_firestore/cloud_firestore.dart';

class TypingStatusModel {
  final String userId;
  final bool isTyping;
  final DateTime updatedAt;

  TypingStatusModel({
    required this.userId,
    required this.isTyping,
    required this.updatedAt,
  });

  factory TypingStatusModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TypingStatusModel(
      userId: doc.id,
      isTyping: data['isTyping'] as bool? ?? false,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'isTyping': isTyping,
        'updatedAt': Timestamp.fromDate(updatedAt.toUtc()),
      };
}
