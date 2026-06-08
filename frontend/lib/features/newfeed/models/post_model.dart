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
    final author = (json['author'] ?? json['Author']) as Map<String, dynamic>?;
    final content = (json['content'] ?? json['Content']) as Map<String, dynamic>?;
    final stats = (json['stats'] ?? json['Stats']) as Map<String, dynamic>?;
    final media = (content?['media'] ?? content?['Media']) as List<dynamic>?;

    return PostModel(
      id: (json['id'] ?? json['Id'])?.toString() ?? '',
      userId: (author?['user_id'] ?? author?['userId'] ?? author?['UserId'])?.toString() ?? '',
      userName: (author?['name'] ?? author?['Name'])?.toString() ?? '',
      userAvatar: (author?['avatar_url'] ?? author?['avatarUrl'] ?? author?['AvatarUrl'])?.toString() ?? '',
      content: (content?['caption'] ?? content?['Caption'])?.toString() ?? '',
      mediaUrls: media
              ?.map((e) => ((e['url'] ?? e['Url'] ?? e['media_url'] ?? e['mediaUrl']) ?? e.toString()).toString())
              .toList() ??
          [],
      visibility: (json['privacy'] ?? json['Privacy'])?.toString() ?? 'public',
      allowedUserIds: ((json['allowed_user_ids'] ?? json['allowedUserIds'] ?? json['AllowedUserIds']) as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: (json['created_at'] ?? json['createdAt'] ?? json['CreateAt']) != null
          ? DateTime.tryParse((json['created_at'] ?? json['createdAt'] ?? json['CreateAt']).toString()) ?? DateTime.now()
          : DateTime.now(),
      likeCount: (stats?['like_count'] ?? stats?['likeCount'] ?? stats?['LikeCount']) ?? 0,
      commentCount: (stats?['comment_count'] ?? stats?['commentCount'] ?? stats?['comments_count'] ?? stats?['commentsCount']) ?? 0,
      isLiked: (stats?['is_liked'] ?? stats?['isLiked'] ?? stats?['IsLiked']) ?? false,
      isOwner: (json['is_owner'] ?? json['isOwner'] ?? json['IsOwner']) ?? false,
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
