class Participant {
  final String userId;
  final String userName;
  final String avatar;
  final String role;
  final DateTime joinedAt;
  final DateTime? lastSeen;
  final String? nickname;
  final bool isOnline;

  Participant({
    required this.userId,
    required this.userName,
    required this.avatar,
    required this.role,
    required this.joinedAt,
    this.lastSeen,
    this.nickname,
    this.isOnline = false,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      userId: json['userId'] ?? json['user_id'] ?? '',
      userName: json['userName'] ?? json['user_name'] ?? '',
      avatar: json['avatar'] ?? '',
      role: json['role'] ?? 'member',
      joinedAt: DateTime.parse(
        json['joinedAt'] ?? json['joined_at'] ?? DateTime.now().toIso8601String(),
      ),
      lastSeen: (json['lastSeen'] ?? json['last_seen']) != null
          ? DateTime.parse(json['lastSeen'] ?? json['last_seen'])
          : null,
      nickname: json['nickname'],
      isOnline: json['isOnline'] ?? json['is_online'] ?? false,
    );
  }

  String get displayName => nickname ?? userName;
}
