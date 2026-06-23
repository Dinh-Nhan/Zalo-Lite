import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/features/friends/providers/friend_provider.dart';
import 'package:frontend/features/friends/services/friend_service.dart';
import 'package:frontend/features/friends/widgets/friend_avatar.dart';
import 'package:frontend/features/profile/screens/profile_screen.dart';
import 'package:frontend/providers/chat_provider.dart';
import 'package:frontend/services/chat/chat_service.dart';
import 'package:frontend/views/chat/chat_screen.dart';
import 'package:provider/provider.dart';

class FriendListScreen extends StatelessWidget {
  const FriendListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendProvider>(
      builder: (context, provider, _) {
        final friends = provider.friends;

        if (friends.isEmpty) {
          return const Center(child: Text('Chưa có bạn bè nào'));
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: friends.length,
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
          ),
          itemBuilder: (context, index) {
            final friend = friends[index];
            return _FriendRowItem(
              friend: friend,
              onRowTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(targetUserId: friend.friendId),
                  ),
                );
              },
              onMessageTap: () async {
                if (friend.friendId.isEmpty) return;
                final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
                if (currentUid.isEmpty) return;
                final conversation = await ChatService().createConversation(
                  type: 'private',
                  participantIds: [friend.friendId],
                );
                if (!context.mounted) return;
                await context.read<ChatProvider>().openConversation(conversation);
                if (!context.mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(conversation: conversation),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _FriendRowItem extends StatelessWidget {
  final FriendSummaryModel friend;
  final VoidCallback onRowTap;
  final VoidCallback onMessageTap;

  const _FriendRowItem({
    required this.friend,
    required this.onRowTap,
    required this.onMessageTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = friend.fullName.isNotEmpty
        ? friend.fullName
        : (friend.firstName.isNotEmpty || friend.lastName.isNotEmpty
            ? '${friend.firstName} ${friend.lastName}'.trim()
            : 'Người dùng');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onRowTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              FriendAvatar(
                name: displayName,
                avatarUrl: friend.avatar.isNotEmpty ? friend.avatar : null,
                radius: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onMessageTap,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
