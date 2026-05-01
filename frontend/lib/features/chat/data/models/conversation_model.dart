import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend/features/chat/data/models/enums/conversation_type.dart';

import 'conversation_settings_model.dart';
import 'last_message_model.dart';
import 'participant_model.dart';

class ConversationModel {
  final String id;
  final ConversationType type;
  final List<ParticipantModel> participants;
  final LastMessageModel? lastMessage;
  final ConversationSettingsModel settings;
  final DateTime updatedAt;

  // ── Group-only fields ──────────────────────────────────────
  final String? groupName;
  final String? groupAvatarUrl;
  final String? pinnedMessageId;

  ConversationModel({
    required this.id,
    required this.type,
    required this.participants,
    this.lastMessage,
    required this.settings,
    required this.updatedAt,
    this.groupName,
    this.groupAvatarUrl,
    this.pinnedMessageId,
  });

  // ─── Helpers ────────────────────────────────────────────────
  bool get isGroup => type == ConversationType.group;

  String displayName(String currentUserId) {
    if (isGroup) return groupName ?? 'Group';
    final other = participants.firstWhere(
      (p) => p.userId != currentUserId,
      orElse: () => participants.first,
    );
    return other.userId; // replace with user display name if available
  }

  // ─── Firestore ──────────────────────────────────────────────
  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ConversationModel(
      id: doc.id,
      type: ConversationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ConversationType.private,
      ),
      participants: (data['participants'] as List<dynamic>? ?? [])
          .map((p) => ParticipantModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      lastMessage: data['last_message'] != null
          ? LastMessageModel.fromJson(data['last_message'])
          : null,
      settings: ConversationSettingsModel.fromJson(data['settings'] ?? {}),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
      groupName: data['groupName'] as String?,
      groupAvatarUrl: data['groupAvatarUrl'] as String?,
      pinnedMessageId: data['pinnedMessageId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'type': type.name,
    'participants': participants.map((p) => p.toJson()).toList(),
    'last_message': lastMessage?.toJson(),
    'settings': settings.toJson(),
    'updated_at': Timestamp.fromDate(updatedAt),
    if (groupName != null) 'groupName': groupName,
    if (groupAvatarUrl != null) 'groupAvatarUrl': groupAvatarUrl,
    if (pinnedMessageId != null) 'pinnedMessageId': pinnedMessageId,
  };

  ConversationModel copyWith({
    String? id,
    ConversationType? type,
    List<ParticipantModel>? participants,
    LastMessageModel? lastMessage,
    ConversationSettingsModel? settings,
    DateTime? updatedAt,
    String? groupName,
    String? groupAvatarUrl,
    String? pinnedMessageId,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      settings: settings ?? this.settings,
      updatedAt: updatedAt ?? this.updatedAt,
      groupName: groupName ?? this.groupName,
      groupAvatarUrl: groupAvatarUrl ?? this.groupAvatarUrl,
      pinnedMessageId: pinnedMessageId ?? this.pinnedMessageId,
    );
  }

  @override
  String toString() =>
      'ConversationModel(id: $id, type: ${type.name}, '
      'participants: ${participants.length}, updatedAt: $updatedAt)';
}
