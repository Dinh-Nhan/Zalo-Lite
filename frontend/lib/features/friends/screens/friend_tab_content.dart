<<<<<<< HEAD
=======
import 'dart:async';

>>>>>>> origin/dev
import 'package:flutter/material.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/features/friends/friends.dart';
import 'package:frontend/features/friends/screens/friend_birthday.dart';
import 'package:frontend/features/friends/screens/friend_request_screen.dart';
<<<<<<< HEAD
import 'package:frontend/features/profile/screens/profile_screen.dart';
import 'package:frontend/providers/chat_provider.dart';
import 'package:frontend/services/chat/chat_service.dart';
import 'package:frontend/views/chat/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
=======
import 'package:frontend/providers/chat_provider.dart';
import 'package:frontend/services/chat/chat_service.dart';
import 'package:frontend/views/chat/chat_screen.dart';
>>>>>>> origin/dev
import 'package:provider/provider.dart';

class FriendTabView extends StatefulWidget {
  const FriendTabView({super.key});

  @override
  State<FriendTabView> createState() => _FriendTabViewState();
}

class _FriendTabViewState extends State<FriendTabView> {
  int _selectedFilterIndex = 0;
<<<<<<< HEAD

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final provider = context.read<FriendProvider>();
      await provider.loadAll();
    });
  }

=======
>>>>>>> origin/dev
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FriendProvider>();
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildActionTile(
          context,
          Icons.people_alt,
          const Color.fromARGB(255, 255, 255, 255),
<<<<<<< HEAD
          'Lời mời kết bạn',
          trailing: '${provider.pendingReceived.length + provider.pendingSent.length}',
=======
          "Lời mời kết bạn",
          trailing: "${provider.pendingReceived.length + provider.pendingSent.length}",
>>>>>>> origin/dev
        ),
        _buildActionTile(
          context,
          Icons.cake,
          const Color.fromARGB(255, 255, 255, 255),
<<<<<<< HEAD
          'Sinh nhật',
        ),
        const Divider(thickness: 8, color: Color(0xFFF4F5F7)),
=======
          "Sinh nhật",
        ),
        const Divider(thickness: 8, color: Color(0xFFF4F5F7)),

        // Khu vực Filter Chips
>>>>>>> origin/dev
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
<<<<<<< HEAD
              _buildFilterChip('Tất cả ${provider.friends.length}', 0),
=======
              _buildFilterChip("Tất cả ${provider.friends.length}", 0),
>>>>>>> origin/dev
              const SizedBox(width: 8),
            ],
          ),
        ),
        const Divider(thickness: 1, color: Color(0xFFEEEEEE), height: 1),
<<<<<<< HEAD
=======

>>>>>>> origin/dev
        if (_selectedFilterIndex == 0) ...[
          if (provider.friendsState == LoadingState.loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (provider.friends.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Chưa có bạn bè')),
            )
          else if (_selectedFilterIndex == 0) ...[
            ...provider.friends.map((friend) => _buildContactItem(friend)),
          ],
<<<<<<< HEAD
=======
        ] else ...[
          _buildAlphabetHeader("Mới truy cập gần đây"),
>>>>>>> origin/dev
        ],
      ],
    );
  }

<<<<<<< HEAD
=======
  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final provider = context.read<FriendProvider>();

      await provider.loadAll();
    });
  }

>>>>>>> origin/dev
  Widget _buildActionTile(
    BuildContext context,
    IconData icon,
    Color color,
    String title, {
    String? trailing,
  }) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
<<<<<<< HEAD
          if (title == 'Lời mời kết bạn') {
=======
          if (title == "Lời mời kết bạn") {
>>>>>>> origin/dev
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FriendRequestScreen()),
            );
          }
<<<<<<< HEAD
          if (title == 'Sinh nhật') {
=======
          if (title == "Sinh nhật") {
>>>>>>> origin/dev
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FriendBirthdayScreen()),
            );
          }
        },
<<<<<<< HEAD
        highlightColor: Colors.black.withValues(alpha: 0.05),
        splashColor: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
=======
        // Hiệu ứng highlight màu xám rất nhạt khi chạm nhanh
        highlightColor: Colors.black.withOpacity(0.05),
        splashColor: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
>>>>>>> origin/dev
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.darkBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(title, style: const TextStyle(fontSize: 16)),
          trailing: trailing != null
              ? Text(
<<<<<<< HEAD
                  '($trailing)',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                )
              : const Icon(Icons.chevron_right),
=======
                  "($trailing)",
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                )
              : null,
>>>>>>> origin/dev
        ),
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : const Color(0xFFF1F2F4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.w500,
=======
  Widget _buildAlphabetHeader(String char) => Container(
    width: double.infinity,
    padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4, right: 16),
    color: const Color.fromARGB(255, 255, 255, 255),
    child: Text(
      char,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black54,
        fontSize: 13,
      ),
    ),
  );

  Widget _buildContactItem(FriendSummaryModel friend) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () async {
          final chatProvider = context.read<ChatProvider>();

          final cached = chatProvider.conversations.where((c) =>
            c.type == 'private' &&
            c.participants.any((p) => p.userId == friend.friendId),
          ).firstOrNull;

          final conversation = cached ?? await ChatService().createConversation(
            type: 'private',
            participantIds: [friend.friendId],
          );

          if (!context.mounted) return;

          unawaited(chatProvider.openConversation(conversation));

          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ChatScreen(conversation: conversation)),
          );
        },
        highlightColor: Colors.black.withOpacity(0.05),
        splashColor: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: FriendAvatar(
            name: friend.fullName,
            avatarUrl: friend.avatar.isNotEmpty ? friend.avatar : null,
            radius: 22,
          ),
          title: Text(friend.fullName, style: const TextStyle(fontSize: 16)),
          trailing: SizedBox(
            width: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.call_outlined,
                    color: Colors.black54,
                    size: 22,
                  ),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(
                    Icons.videocam_outlined,
                    color: Colors.black54,
                    size: 22,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
>>>>>>> origin/dev
          ),
        ),
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildContactItem(FriendSummaryModel friend) {
    final displayName = friend.fullName.isNotEmpty
        ? friend.fullName
        : (friend.firstName.isNotEmpty || friend.lastName.isNotEmpty
            ? '${friend.firstName} ${friend.lastName}'.trim()
            : 'Người dùng');

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileScreen(targetUserId: friend.friendId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF4CAF50),
                backgroundImage: friend.avatar.isNotEmpty ? NetworkImage(friend.avatar) : null,
                child: friend.avatar.isEmpty
                    ? Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
                  if (friend.friendId.isEmpty || currentUid.isEmpty) return;
                  final conversation = await ChatService().createConversation(
                    type: 'private',
                    participantIds: [currentUid, friend.friendId],
                  );
                  if (!context.mounted) return;
                  await context.read<ChatProvider>().openConversation(conversation);
                  if (!context.mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ChatScreen(conversation: conversation)),
                  );
                },
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
=======
  // 1. Widget Filter Chip có hiệu ứng nhấn
  Widget _buildFilterChip(String label, int index) {
    bool isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0091FF)
                : const Color(0xFFEEEEEE),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF0091FF) : Colors.black87,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
>>>>>>> origin/dev
          ),
        ),
      ),
    );
  }
}
