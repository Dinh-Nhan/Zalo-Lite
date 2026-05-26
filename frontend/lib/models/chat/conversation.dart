import 'message.dart';
import 'participant.dart';

class Conversation {
  final String id;
  final String type;
  final List<Participant> participants;
  final Message? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Group specific
  final String? groupName;
  final String? groupAvatarUrl;
  final String? groupDescription;
  final String? createdBy;
  final bool onlyAdminCanSend;
  final bool onlyAdminCanEditInfo;

  // Private chat - other user
  final String? otherUserId;
  final String? otherUserName;
  final String? otherUserAvatar;
  final bool? otherUserOnline;
  final DateTime? otherUserLastSeen;

  // User specific
  final bool isMuted;
  final bool isPinned;
  final int unreadCount;
  final bool isArchived;

  final String? pinnedMessageId;
  final String? pinnedMessageContent;

  Conversation({
    required this.id,
    required this.type,
    required this.participants,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    this.groupName,
    this.groupAvatarUrl,
    this.groupDescription,
    this.createdBy,
    this.onlyAdminCanSend = false,
    this.onlyAdminCanEditInfo = false,
    this.otherUserId,
    this.otherUserName,
    this.otherUserAvatar,
    this.otherUserOnline,
    this.otherUserLastSeen,
    this.isMuted = false,
    this.isPinned = false,
    this.unreadCount = 0,
    this.isArchived = false,
    this.pinnedMessageId,
    this.pinnedMessageContent,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? '',
      type: json['type'] ?? 'private',
      participants:
          (json['participants'] as List?)
              ?.map((p) => Participant.fromJson(p))
              .toList() ??
          [],
      lastMessage: json['last_message'] != null
          ? Message.fromJson(json['last_message'])
          : null,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      groupName: json['group_name'],
      groupAvatarUrl: json['group_avatar_url'],
      groupDescription: json['group_description'],
      createdBy: json['created_by'],
      onlyAdminCanSend: json['only_admin_can_send'] ?? false,
      onlyAdminCanEditInfo: json['only_admin_can_edit_info'] ?? false,
      otherUserId: json['other_user_id'],
      otherUserName: json['other_user_name'],
      otherUserAvatar: json['other_user_avatar'],
      otherUserOnline: json['other_user_online'],
      otherUserLastSeen: json['other_user_last_seen'] != null
          ? DateTime.parse(json['other_user_last_seen'])
          : null,
      isMuted: json['is_muted'] ?? false,
      isPinned: json['is_pinned'] ?? false,
      unreadCount: json['unread_count'] ?? 0,
      isArchived: json['is_archived'] ?? false,
      pinnedMessageId: json['pinned_message_id'],
      pinnedMessageContent: json['pinned_message_content'],
    );
  }

  String get displayName {
    if (type == 'group') {
      return groupName ?? 'Nhóm';
    }
    return otherUserName ?? 'Người dùng';
  }

  String get displayAvatar {
    if (type == 'group') {
      return groupAvatarUrl ?? '';
    }
    return otherUserAvatar ?? '';
  }

  String get displayStatus {
    if (type == 'group') {
      return '${participants.length} thành viên';
    }
    if (otherUserOnline == true) {
      return 'Đang hoạt động';
    }
    if (otherUserLastSeen != null) {
      return _formatLastSeen(otherUserLastSeen!);
    }
    return 'Không hoạt động';
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else {
      return '${difference.inDays} ngày trước';
    }
  }
}
