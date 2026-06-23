class CommentModel {
  final String id;
  final String feedId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final String imageUrl;
  final int likeCount;
  final bool isLiked;
  final DateTime createdAt;
  final int commentCount;

  CommentModel({
    required this.id,
    required this.feedId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.imageUrl,
    required this.likeCount,
    required this.isLiked,
    required this.createdAt,
    this.commentCount = 0,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? '',
      feedId: json['feed_id'] ?? json['feedId'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      userName: json['user_name'] ?? json['userName'] ?? 'User',
      userAvatar: json['user_avatar'] ?? json['userAvatar'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      likeCount: json['like_count'] ?? json['likeCount'] ?? 0,
      isLiked: json['is_liked'] ?? json['isLiked'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      commentCount: json['comment_count'] ?? json['commentCount'] ?? 0,
    );
  }

  CommentModel copyWith({
    String? id,
    String? feedId,
    String? userId,
    String? userName,
    String? userAvatar,
    String? content,
    String? imageUrl,
    int? likeCount,
    bool? isLiked,
    DateTime? createdAt,
    int? commentCount,
  }) {
    return CommentModel(
      id: id ?? this.id,
      feedId: feedId ?? this.feedId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
      commentCount: commentCount ?? this.commentCount,
    );
  }
}
