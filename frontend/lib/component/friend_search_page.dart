import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/features/friends/friends.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class FriendSearchPage extends StatefulWidget {
  const FriendSearchPage({super.key});

  @override
  State<FriendSearchPage> createState() => _FriendSearchPageState();
}

class _FriendSearchPageState extends State<FriendSearchPage> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  List<FriendSummaryModel> _filteredFriends = [];
  UserSearchModel? _searchedUser;

  bool _isSearching = false;

  @override
  void initState() {
    super.initState();

    final provider = context.read<FriendProvider>();
    _filteredFriends = provider.friends;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final provider = context.read<FriendProvider>();
      final keyword = value.trim().toLowerCase();

      if (keyword.isEmpty) {
        setState(() {
          _filteredFriends = provider.friends;
          _searchedUser = null;
        });
        return;
      }

      // LOCAL FILTER FRIENDS
      final localFriends = provider.friends.where((f) {
        return f.fullName.toLowerCase().contains(keyword);
      }).toList();

      UserSearchModel? user;
      final isEmail = keyword.contains('@') && keyword.contains('.');

      if (isEmail) {
        setState(() => _isSearching = true);

        user = await provider.findUserByEmail(keyword);

        setState(() => _isSearching = false);

        if (user != null && provider.isFriend(user.id)) {
          user = null;
        }
      }

      setState(() {
        _filteredFriends = localFriends;
        _searchedUser = user;
      });
    });
  }

  void _clear() {
    final provider = context.read<FriendProvider>();

    _controller.clear();

    setState(() {
      _filteredFriends = provider.friends;
      _searchedUser = null;
    });
  }

  // ================= USER TILE CORE =================

  Widget _buildUserTile({
    required String name,
    required String avatar,
    required Widget trailing,
    String? subtitle,
  }) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFEAEAEA)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage:
                  avatar.isNotEmpty ? NetworkImage(avatar) : null,
              child: avatar.isEmpty ? Text(name[0].toUpperCase()) : null,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            SizedBox(
              width: 120,
              child: Align(
                alignment: Alignment.centerRight,
                child: trailing,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= FRIEND TILE =================

  Widget _friendTile(FriendSummaryModel f) {
  return _buildUserTile(
    name: f.fullName,
    avatar: f.avatar,
    subtitle: 'Bạn bè',
    trailing: IconButton(
      icon: const Icon(
        Icons.chat_bubble_outline,
        color: AppColors.primaryBlue,
      ),
      onPressed: () {
        context.push(
          '/chat-detail',
          extra: {
            'conversationId': f.friendId,
            'contactName': f.fullName,
            'avatarColor': Colors.blue, // hoặc random/color theo user
            'isGroup': false,
            'memberCount': null,
          },
        );
      },
    ),
  );
}

  // ================= SEARCH TILE =================

  Widget _searchTile(UserSearchModel user) {
    final provider = context.watch<FriendProvider>();

    final sent = provider.pendingSent.any(
      (f) => f.addresseeId == user.id,
    );

    final received = provider.getReceivedRequest(user.id);
    final isFriend = provider.isFriend(user.id);

    Widget action;

    if (isFriend) {
      action = const Text(
        'Bạn bè',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      );
    } else if (received != null) {
      action = Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () =>
                provider.declineFriendRequest(user.id),
          ),
          IconButton(
            icon: const Icon(Icons.check, size: 18),
            onPressed: () =>
                provider.acceptFriendRequest(user.id),
          ),
        ],
      );
    } else if (sent) {
      action = SizedBox(
        height: 32,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            minimumSize: const Size(0, 32),
            side: const BorderSide(color: Colors.grey),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => provider.cancelFriendRequest(user.id),
          child: const Text(
            'Thu hồi',
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
      );
    } else {
      action = SizedBox(
        height: 32,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            minimumSize: const Size(0, 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => provider.sendFriendRequest(user.id),
          child: const Text(
            'Kết bạn',
            style: TextStyle(fontSize: 12, color: Colors.white),
          ),
        ),
      );
    }

    return _buildUserTile(
      name: user.fullName,
      avatar: user.avatar,
      subtitle: user.email,
      trailing: action,
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FriendProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        titleSpacing: 0,
        leading: const BackButton(color: Colors.white),

        title: Container(
          margin: const EdgeInsets.only(right: 8),
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: 'Tìm bạn bè, email...',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: _clear,
                    )
                  : null,
            ),
            onChanged: (v) {
              setState(() {});
              _onChanged(v);
            },
          ),
        ),
      ),

      body: Column(
        children: [
          if (_isSearching)
            const LinearProgressIndicator(minHeight: 2),

          Expanded(
            child: ListView(
              children: [
                // FRIENDS
                if (_filteredFriends.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Text(
                      'Bạn bè',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  ..._filteredFriends.map(_friendTile),
                ],

                // SEARCH USER
                if (_searchedUser != null) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Text(
                      'Kết quả tìm kiếm',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  _searchTile(_searchedUser!),
                ],

                // EMPTY
                if (_filteredFriends.isEmpty &&
                    _searchedUser == null &&
                    _controller.text.isNotEmpty &&
                    !_isSearching)
                  const Padding(
                    padding: EdgeInsets.only(top: 120),
                    child: Column(
                      children: [
                        Icon(Icons.search_off,
                            size: 70, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          'Không tìm thấy kết quả',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Thử tìm bằng email chính xác',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}