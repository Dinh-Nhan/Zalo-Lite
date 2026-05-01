class ReactionModel {
  final String userId;
  final String emoji;
  final DateTime reactedAt;

  ReactionModel({
    required this.userId,
    required this.emoji,
    required this.reactedAt,
  });

  factory ReactionModel.fromJson(Map<String, dynamic> json) {
    return ReactionModel(
      userId: json['userId'] as String,
      emoji: json['emoji'] as String,
      reactedAt: DateTime.parse(json['reactedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'emoji': emoji,
        'reactedAt': reactedAt.toIso8601String(),
      };

  ReactionModel copyWith({String? userId, String? emoji, DateTime? reactedAt}) {
    return ReactionModel(
      userId: userId ?? this.userId,
      emoji: emoji ?? this.emoji,
      reactedAt: reactedAt ?? this.reactedAt,
    );
  }
}
