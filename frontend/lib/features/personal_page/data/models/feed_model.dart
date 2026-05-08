/// Model cho một media (ảnh/video) trong feed
class MediaModel {
  final String url;
  final String type; // "image" | "video"

  const MediaModel({required this.url, required this.type});

  factory MediaModel.fromJson(Map<String, dynamic> json) => MediaModel(
        url: json['url'] ?? '',
        type: json['type'] ?? 'image',
      );

  Map<String, dynamic> toJson() => {'url': url, 'type': type};
}

/// Model cho nội dung feed (caption + media list)
class ContentModel {
  final String caption;
  final List<MediaModel> media;

  const ContentModel({required this.caption, required this.media});

  factory ContentModel.fromJson(Map<String, dynamic> json) => ContentModel(
        caption: json['caption'] ?? '',
        media: (json['media'] as List? ?? [])
            .map((m) => MediaModel.fromJson(m as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'caption': caption,
        'media': media.map((m) => m.toJson()).toList(),
      };
}

/// Model cho thống kê feed (views, likes)
class StatsModel {
  final int viewCount;
  final int likeCount;
  final bool isLiked;

  const StatsModel({
    required this.viewCount,
    required this.likeCount,
    required this.isLiked,
  });

  factory StatsModel.fromJson(Map<String, dynamic> json) => StatsModel(
        viewCount: json['viewCount'] ?? 0,
        likeCount: json['likeCount'] ?? 0,
        isLiked: json['isLiked'] ?? false,
      );
}

/// Model cho settings của feed
class SettingModel {
  final bool isExpired;
  final DateTime? expiresAt;

  const SettingModel({required this.isExpired, this.expiresAt});

  factory SettingModel.fromJson(Map<String, dynamic> json) => SettingModel(
        isExpired: json['isExpired'] ?? false,
        expiresAt: json['expiresAt'] != null
            ? DateTime.tryParse(json['expiresAt'])
            : null,
      );
}

/// Model cho một feed (post hoặc story)
class FeedModel {
  final String id;
  final String userId;
  final String type; // "post" | "story"
  final ContentModel content;
  final String privacy; // "public" | "friends" | "private"
  final StatsModel stats;
  final SettingModel? settings;
  final DateTime createdAt;
  final DateTime? deletedAt;

  const FeedModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.content,
    required this.privacy,
    required this.stats,
    this.settings,
    required this.createdAt,
    this.deletedAt,
  });

  factory FeedModel.fromJson(Map<String, dynamic> json) => FeedModel(
        id: json['id'] ?? '',
        userId: json['userId'] ?? '',
        type: json['type'] ?? 'post',
        content: ContentModel.fromJson(json['content'] ?? {}),
        privacy: json['privacy'] ?? 'public',
        stats: StatsModel.fromJson(json['stats'] ?? {}),
        settings: json['settings'] != null
            ? SettingModel.fromJson(json['settings'])
            : null,
        createdAt:
            DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        deletedAt: json['deletedAt'] != null
            ? DateTime.tryParse(json['deletedAt'])
            : null,
      );

  bool get isPost => type == 'post';
  bool get isStory => type == 'story';
}

/// Response wrapper cho newsfeed (chứa cả stories và posts)
class NewsfeedModel {
  final List<FeedModel> stories;
  final List<FeedModel> posts;

  const NewsfeedModel({required this.stories, required this.posts});

  factory NewsfeedModel.fromJson(Map<String, dynamic> json) => NewsfeedModel(
        stories: (json['stories'] as List? ?? [])
            .map((e) => FeedModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        posts: (json['posts'] as List? ?? [])
            .map((e) => FeedModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Like response model
class LikeResultModel {
  final bool isLiked;
  final int likeCount;

  const LikeResultModel({required this.isLiked, required this.likeCount});

  factory LikeResultModel.fromJson(Map<String, dynamic> json) =>
      LikeResultModel(
        isLiked: json['isLiked'] ?? false,
        likeCount: json['likeCount'] ?? 0,
      );
}

/// User profile model (dùng cho hiển thị avatar trong story bar)
class UserProfileModel {
  final String id;
  final String fullName;
  final String avatar;
  final String? email;

  const UserProfileModel({
    required this.id,
    required this.fullName,
    required this.avatar,
    this.email,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      UserProfileModel(
        id: json['id'] ?? json['uid'] ?? '',
        fullName: json['fullName'] ?? json['FullName'] ?? '',
        avatar: json['avatar'] ?? '',
        email: json['email'] as String?,
      );
}
