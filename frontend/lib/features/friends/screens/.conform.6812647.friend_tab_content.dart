import 'package:flutter/material.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/features/friends/friends.dart';
import 'package:frontend/features/friends/screens/friend_birthday.dart';
import 'package:frontend/features/friends/screens/friend_request_screen.dart';
import 'package:frontend/views/chat/chat_detail_view.dart';
import 'package:frontend/views/chat/chat_screen.dart';
import 'package:provider/provider.dart';

class FriendTabView extends StatefulWidget {
  const FriendTabView({super.key});

  @override
  State<FriendTabView> createState() => _FriendTabViewState();
}

class _FriendTabViewState extends State<FriendTabView> {
  int _selectedFilterIndex = 0;
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
          "Lời mời kết bạn",
          trailing: "${provider.pendingReceived.length}",
        ),
        _buildActionTile(
          context,
          Icons.cake,
          const Color.fromARGB(255, 255, 255, 255),
          "Sinh nhật",
        ),
        const Divider(thickness: 8, color: Color(0xFFF4F5F7)),

        // Khu vực Filter Chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildFilterChip("Tất cả ${provider.friends.length}", 0),
              const SizedBox(width: 8),
            ],
          ),
        ),
        const Divider(thickness: 1, color: Color(0xFFEEEEEE), height: 1),

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
        ] else ...[
          _buildAlphabetHeader("Mới truy cập gần đây"),
        ],
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final provider = context.read<FriendProvider>();

      await provider.loadFriends();
    });
  }

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
          if (title == "Lời mời kết bạn") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FriendRequestScreen()),
            );
          }
          if (title == "Sinh nhật") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FriendBirthdayScreen()),
            );
          }
        },
        // Hiệu ứng highlight màu xám rất nhạt khi chạm nhanh
        highlightColor: Colors.black.withOpacity(0.05),
        splashColor: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
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
                  "($trailing)",
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                )
              : null,
        ),
      ),
    );
  }

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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatScreen()),
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
          ),
        ),
      ),
    );
  }

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
          ),
        ),
      ),
    );
  }
}
