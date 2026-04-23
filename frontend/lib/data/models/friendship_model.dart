enum FriendshipStatus { pending, accepted, blocked, declined }
class FriendshipModel {
  final String? id;
  final String senderId;
  final String addresseeId;
  final FriendshipStatus status;
  final String sourceType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FriendshipModel({
    this.id,
    required this.senderId,
    required this.addresseeId,
    required this.status,
    required this.sourceType,
    this.createdAt,
    this.updatedAt,
  });

  factory FriendshipModel.fromJson(Map<String, dynamic> json) {
    return FriendshipModel(
      id: json['_id'],
      senderId: json['send_id'] ?? '',
      addresseeId: json['addressee_id'] ?? '',
      status: FriendshipStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => FriendshipStatus.pending,
      ),
      sourceType: json['source_type'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'send_id': senderId,
      'addressee_id': addresseeId,
      'status': status,
      'source_type': sourceType,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}