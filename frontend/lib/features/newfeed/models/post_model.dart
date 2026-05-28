class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final List<String> mediaUrls;
  final String? visibility;
  final List<String> allowedUserIds;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final bool isOwner;

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    this.mediaUrls = const [],
    this.visibility = 'public',
    this.allowedUserIds = const [],
    required this.createdAt,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    this.isOwner = false,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    // Backend nested structure: Author, Content, Stats
    final author = json['author'] as Map<String, dynamic>?;
    final content = json['content'] as Map<String, dynamic>?;
    final stats = json['stats'] as Map<String, dynamic>?;
    final media = content?['media'] as List<dynamic>?;

    return PostModel(
      id: json['id']?.toString() ?? '',
      userId: author?['userId']?.toString() ?? '',
      userName: author?['name']?.toString() ?? '',
      userAvatar: author?['avatarUrl']?.toString() ?? '',
      content: content?['caption']?.toString() ?? '',
      mediaUrls: media
              ?.map((e) => (e['url'] ?? e['Url'] ?? e.toString()).toString())
              .toList() ??
          [],
      visibility: json['privacy']?.toString() ?? 'public',
      allowedUserIds: (json['allowedUserIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      likeCount: stats?['likeCount'] ?? 0,
      commentCount: stats?['commentCount'] ?? stats?['commentsCount'] ?? 0,
      isLiked: stats?['isLiked'] ?? false,
      isOwner: json['isOwner'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'mediaUrls': mediaUrls,
      'visibility': visibility,
      'allowedUserIds': allowedUserIds,
      'createdAt': createdAt.toIso8601String(),
      'likeCount': likeCount,
      'commentCount': commentCount,
      'isLiked': isLiked,
      'isOwner': isOwner,
    };
  }

  PostModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? content,
    List<String>? mediaUrls,
    String? visibility,
    List<String>? allowedUserIds,
    DateTime? createdAt,
    int? likeCount,
    int? commentCount,
    bool? isLiked,
    bool? isOwner,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      visibility: visibility ?? this.visibility,
      allowedUserIds: allowedUserIds ?? this.allowedUserIds,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
      isOwner: isOwner ?? this.isOwner,
    );
  }
}
