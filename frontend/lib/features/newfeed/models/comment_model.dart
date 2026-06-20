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
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? '',
      feedId: json['feedId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'User',
      userAvatar: json['userAvatar'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      likeCount: json['likeCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
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
    );
  }
}
