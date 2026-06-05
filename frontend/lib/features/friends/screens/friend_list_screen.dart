import 'package:flutter/material.dart';
import 'package:frontend/features/friends/providers/friend_provider.dart';
import 'package:frontend/providers/chat_provider.dart';
import 'package:frontend/services/chat/chat_service.dart';
import 'package:frontend/views/chat/chat_screen.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/friends/widgets/friend_avatar.dart';

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

        String? currentLetter;
        final List<Widget> items = [];

        for (final friend in friends) {
          final firstLetter = friend.fullName.isNotEmpty
              ? friend.fullName[0].toUpperCase()
              : '#';
          if (firstLetter != currentLetter) {
            currentLetter = firstLetter;
            items.add(
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  currentLetter,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                  ),
                ),
              ),
            );
          }
          items.add(
            ListTile(
              leading: FriendAvatar(
                name: friend.fullName,
                avatarUrl: friend.avatar.isNotEmpty ? friend.avatar : null,
                radius: 22,
              ),
              title: Text(friend.fullName),
              onTap: () async {
                final conversation = await ChatService().createConversation(
                  type: 'private',
                  participantIds: [friend.friendId],
                );
                if (!context.mounted) return;
                await context.read<ChatProvider>().openConversation(
                  conversation,
                );
                if (!context.mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(conversation: conversation),
                  ),
                );
              },
            ),
          );
        }

        return ListView(padding: EdgeInsets.zero, children: items);
      },
    );
  }
}
