import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/features/friends/friends.dart';
import 'package:frontend/providers/chat_provider.dart';
import 'package:frontend/services/chat/chat_service.dart';
import 'package:frontend/views/chat/chat_screen.dart';
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
  List<UserSearchModel> _results = [];
  bool _isSearching = false;
  bool _hasError = false;
  bool _hasSearched = false;

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

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
      _hasError = false;
    });

    try {
      final provider = context.read<FriendProvider>();
      final keyword = query.trim().toLowerCase();
      final localFriends = provider.friends.where((f) {
        return f.fullName.toLowerCase().contains(keyword);
      }).toList();
      final results = await FriendService.searchUsers(query);

      if (!mounted) return;

      setState(() {
        _filteredFriends = localFriends;
        _results = results.where((u) => !provider.isFriend(u.id)).toList();
        _isSearching = false;
        _hasSearched = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _isSearching = false;
        _hasError = true;
        _hasSearched = true;
      });
    }
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final keyword = value.trim();

    if (keyword.isEmpty) {
      final provider = context.read<FriendProvider>();
      setState(() {
        _filteredFriends = provider.friends;
        _results = [];
        _hasSearched = false;
        _hasError = false;
        _isSearching = false;
      });
      return;
    }

    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => _performSearch(keyword),
    );
  }

  void _clear() {
    final provider = context.read<FriendProvider>();
    _controller.clear();
    setState(() {
      _filteredFriends = provider.friends;
      _results = [];
      _hasSearched = false;
      _hasError = false;
      _isSearching = false;
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
        border: Border(bottom: BorderSide(color: Color(0xFFEAEAEA))),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage:
                  avatar.isNotEmpty ? NetworkImage(avatar) : null,
              child: avatar.isEmpty
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                    )
                  : null,
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

  Widget _friendTile(FriendSummaryModel f) {
    return _buildUserTile(
      name: f.fullName,
      avatar: f.avatar,
      subtitle: 'Bạn bè',
      trailing: IconButton(
        icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryBlue),
        onPressed: () async {
          final chatProvider = context.read<ChatProvider>();
          final conversation = await ChatService().createConversation(
            type: 'private',
            participantIds: [f.friendId],
          );
          if (!mounted) return;
          unawaited(chatProvider.openConversation(conversation));
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(conversation: conversation),
            ),
          );
        },
      ),
    );
  }

  // ================= SEARCH TILE =================

  Widget _searchTile(UserSearchModel user) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isSelf = user.id == currentUid;
    final provider = context.watch<FriendProvider>();
    final sent = provider.pendingSent.any((f) => f.addresseeId == user.id);
    final received = provider.getReceivedRequest(user.id);
    final isFriend = provider.isFriend(user.id);

    Widget action;

    if (isSelf) {
      action = const SizedBox.shrink();
    } else if (isFriend) {
      action = IconButton(
        icon: const Icon(
          Icons.chat_bubble_outline,
          color: AppColors.primaryBlue,
        ),
        onPressed: () async {
          final chatProvider = context.read<ChatProvider>();
          final conversation = await ChatService().createConversation(
            type: 'private',
            participantIds: [user.id],
          );
          if (!mounted) return;
          unawaited(chatProvider.openConversation(conversation));
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(conversation: conversation),
            ),
          );
        },
      );
    } else if (received != null) {
      action = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              provider.declineFriendRequest(user.id);
            },
          ),
          IconButton(
            icon: const Icon(Icons.check, size: 18),
            onPressed: () {
              provider.acceptFriendRequest(user.id);
            },
          ),
        ],
      );
    } else if (sent) {
      action = SizedBox(
        height: 32,
        child: OutlinedButton(
          onPressed: () {
            provider.cancelFriendRequest(user.id);
          },
          child: const Text(
            'Thu hồi',
            style: TextStyle(fontSize: 12),
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
          ),
          onPressed: () {
            provider.sendFriendRequest(user.id);
          },
          child: const Text(
            'Kết bạn',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      );
    }

    return _buildUserTile(
      name: user.fullName.isNotEmpty ? user.fullName : user.email,
      avatar: user.avatar,
      subtitle: user.email,
      trailing: action,
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        titleSpacing: 0,
        leading: const BackButton(color: Colors.white),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: 'Tìm bạn bè, email...',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.search,
                color: Colors.white.withValues(alpha: 0.8),
                size: 20,
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      onPressed: _clear,
                      icon: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white70,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                    )
                  : null,
            ),
            onChanged: (v) {
              setState(() {});
              _onChanged(v);
            },
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8, left: 8),
            child: IconButton(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearching) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: ListView(
              children: [
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
                if (_results.isNotEmpty) ...[
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
                  ..._results.map(_searchTile),
                ],
                if (_hasSearched &&
                    _results.isEmpty &&
                    _filteredFriends.isEmpty &&
                    !_hasError)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Không tìm thấy kết quả')),
                  ),
                if (_hasError)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Có lỗi xảy ra khi tìm kiếm')),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
