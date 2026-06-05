import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
// FEEDS FEATURE - Domain Model
// ============================================================

class FeedMedia {
  final String url;
  final String type; // 'image' | 'video'

  const FeedMedia({required this.url, required this.type});

  factory FeedMedia.fromMap(Map<String, dynamic> map) => FeedMedia(
        url: map['url'] as String? ?? '',
        type: map['type'] as String? ?? 'image',
      );
}

class AdminFeed {
  final String id;
  final String userId;
  final String type; // 'post' | 'story'
  final String caption;
  final List<FeedMedia> media;
  final String privacy;
  final bool isExpired;
  final DateTime? expiresAt;
  final List<String> views;   // list of user_ids
  final List<String> likes;   // list of user_ids
  final DateTime createdAt;
  final bool isEnabled; // true = visible, false = disabled/hidden
  // Denormalized (may not exist in older docs)
  final String? authorName;
  final String? authorAvatar;

  const AdminFeed({
    required this.id,
    required this.userId,
    required this.type,
    required this.caption,
    required this.media,
    required this.privacy,
    required this.isExpired,
    this.expiresAt,
    required this.views,
    required this.likes,
    required this.createdAt,
    required this.isEnabled,
    this.authorName,
    this.authorAvatar,
  });

  bool get isDisabled => !isEnabled;
  int get likeCount => likes.length;
  int get viewCount => views.length;
  bool get hasMedia => media.isNotEmpty;

  factory AdminFeed.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final contentMap = data['content'] as Map<String, dynamic>? ?? {};
    final mediaList = (contentMap['media'] as List<dynamic>? ?? [])
        .map((m) => FeedMedia.fromMap(m as Map<String, dynamic>))
        .toList();

    final settingsMap = data['settings'] as Map<String, dynamic>? ?? {};
    final statsMap = data['stats'] as Map<String, dynamic>? ?? {};

    return AdminFeed(
      id: doc.id,
      userId: data['user_id'] as String? ?? '',
      type: data['type'] as String? ?? 'post',
      caption: contentMap['caption'] as String? ?? '',
      media: mediaList,
      privacy: data['privacy'] as String? ?? 'public',
      isExpired: settingsMap['is_expired'] as bool? ?? false,
      expiresAt: (settingsMap['expires_at'] as Timestamp?)?.toDate(),
      views: List<String>.from(statsMap['views'] as List? ?? []),
      likes: List<String>.from(statsMap['likes'] as List? ?? []),
      createdAt:
          (data['create_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      // Existing docs without 'is_enable' field default to true (enabled)
      isEnabled: data['is_enable'] as bool? ?? true,
      authorName: data['author_name'] as String?,
      authorAvatar: data['author_avatar'] as String?,
    );
  }
}
