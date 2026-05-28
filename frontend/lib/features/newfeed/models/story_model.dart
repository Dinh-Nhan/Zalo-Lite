class StoryModel {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int viewCount;
  final bool isOwner;
  final bool isSeen;

  StoryModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.imageUrl,
    required this.createdAt,
    this.expiresAt,
    this.viewCount = 0,
    this.isOwner = false,
    this.isSeen = false,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    // Backend nested structure: Author, Content (Media list), Stats
    final author = json['author'] as Map<String, dynamic>?;
    final content = json['content'] as Map<String, dynamic>?;
    final stats = json['stats'] as Map<String, dynamic>?;
    final media = content?['media'] as List<dynamic>?;

    String imgUrl = '';
    if (media != null && media.isNotEmpty) {
      final firstMedia = media.first as Map<String, dynamic>?;
      imgUrl = firstMedia?['url']?.toString() ?? firstMedia?['Url']?.toString() ?? '';
    }

    if (imgUrl.isEmpty) {
      imgUrl = 'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=800'; // Aesthetic gradient background
    }

    return StoryModel(
      id: json['id']?.toString() ?? '',
      userId: author?['userId']?.toString() ?? '',
      userName: author?['name']?.toString() ?? '',
      userAvatar: author?['avatarUrl']?.toString() ?? '',
      imageUrl: imgUrl,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
      viewCount: stats?['viewCount'] ?? 0,
      isOwner: json['isOwner'] ?? false,
      isSeen: stats?['isSeen'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'viewCount': viewCount,
      'isOwner': isOwner,
      'isSeen': isSeen,
    };
  }

  StoryModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? viewCount,
    bool? isOwner,
    bool? isSeen,
  }) {
    return StoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      viewCount: viewCount ?? this.viewCount,
      isOwner: isOwner ?? this.isOwner,
      isSeen: isSeen ?? this.isSeen,
    );
  }

  bool get isExpired {
    if (expiresAt == null) {
      return DateTime.now().difference(createdAt).inHours >= 24;
    }
    return DateTime.now().isAfter(expiresAt!);
  }
}

class UserStory {
  final String oderId; // userId
  final String userName;
  final String userAvatar;
  final List<StoryModel> stories;
  final bool isOwner;

  UserStory({
    required this.oderId,
    required this.userName,
    required this.userAvatar,
    required this.stories,
    this.isOwner = false,
  });

  factory UserStory.fromJson(Map<String, dynamic> json) {
    return UserStory(
      oderId: json['oderId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      userAvatar: json['userAvatar']?.toString() ?? '',
      stories: (json['stories'] as List<dynamic>?)
              ?.map((e) => StoryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isOwner: json['isOwner'] ?? false,
    );
  }

  bool get hasUnseenStories {
    return stories.any((s) => !s.isSeen && !isOwner);
  }
}
