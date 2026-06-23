import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/features/friends/providers/friend_provider.dart';
import 'package:frontend/features/friends/services/friend_service.dart';
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

  // Friends pagination
  static const int _initialShow = 6;
  static const int _pageSize = 20;
  int _shownCount = _initialShow;

  // Search state
  List<UserSearchModel> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  bool _hasError = false;

  bool get _isEmptyQuery => _controller.text.trim().isEmpty;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    // Reset shown friends count when query changes
    setState(() => _shownCount = _initialShow);
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _hasSearched = false;
        _hasError = false;
        _shownCount = _initialShow;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasError = false;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () => _performSearch(value));
  }

  Future<void> _performSearch(String query) async {
    try {
      final results = await FriendService.searchUsers(query.trim());

      if (!mounted) return;

      final provider = context.read<FriendProvider>();
      // Filter out only current user (friends still show with "Nhắn tin" button)
      final filtered = results
          .where((u) => u.id != FirebaseAuth.instance.currentUser?.uid)
          .toList();

      setState(() {
        _searchResults = filtered;
        _isSearching = false;
        _hasSearched = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _hasSearched = true;
        _hasError = true;
      });
    }
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    setState(() {
      _searchResults = [];
      _isSearching = false;
      _hasSearched = false;
      _hasError = false;
      _shownCount = _initialShow;
    });
  }

  // ================= BASE TILE =================

  Widget _buildUserTile({
    required String name,
    required String avatar,
    required Widget trailing,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFEAEAEA))),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                child: avatar.isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
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
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 110,
                child: Align(alignment: Alignment.centerRight, child: trailing),
              ),
            ],
          ),
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
      onTap: () => context.push('/profile', extra: f.friendId),
      trailing: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primaryBlue,
          borderRadius: BorderRadius.circular(18),
        ),
        child: IconButton(
          icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
          onPressed: () async {
            final chatProvider = context.read<ChatProvider>();
            final conversation = await ChatService().createConversation(
              type: 'private',
              participantIds: [f.friendId],
            );
            if (!context.mounted) return;
            unawaited(chatProvider.openConversation(conversation));
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(conversation: conversation),
              ),
            );
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          tooltip: 'Nhắn tin',
        ),
      ),
    );
  }

  // ================= SEARCH TILE =================

  Widget _searchTile(UserSearchModel user) {
    final provider = context.watch<FriendProvider>();
    final sent = provider.pendingSent.any((f) => f.addresseeId == user.id);
    final received = provider.getReceivedRequest(user.id);
    final isFriend = provider.isFriend(user.id);
    final isLoading = provider.isActionLoading(user.id);

    Widget action;

    if (isLoading) {
      action = const SizedBox(
        width: 34,
        height: 34,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else if (isFriend) {
      action = Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primaryBlue,
          borderRadius: BorderRadius.circular(18),
        ),
        child: IconButton(
          onPressed: () async {
            final chatProvider = context.read<ChatProvider>();
            final conversation = await ChatService().createConversation(
              type: 'private',
              participantIds: [user.id],
            );
            if (!context.mounted) return;
            unawaited(chatProvider.openConversation(conversation));
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(conversation: conversation),
              ),
            );
          },
          icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          tooltip: 'Nhắn tin',
        ),
      );
    } else if (received != null) {
      action = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => provider.declineFriendRequest(user.id),
            icon: Icon(Icons.close, color: Colors.grey.shade600, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: 'Từ chối',
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(18),
            ),
            child: IconButton(
              onPressed: () => provider.acceptFriendRequest(user.id),
              icon: const Icon(Icons.check, color: Colors.white, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              tooltip: 'Xác nhận',
            ),
          ),
        ],
      );
    } else if (sent) {
      action = Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(18),
        ),
        child: IconButton(
          onPressed: () => provider.cancelFriendRequest(user.id),
          icon: Icon(Icons.close, color: Colors.grey.shade700, size: 18),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          tooltip: 'Thu hồi',
        ),
      );
    } else {
      action = Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primaryBlue,
          borderRadius: BorderRadius.circular(18),
        ),
        child: IconButton(
          onPressed: () => provider.sendFriendRequest(user.id),
          icon: const Icon(Icons.person_add, color: Colors.white, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          tooltip: 'Kết bạn',
        ),
      );
    }

    return _buildUserTile(
      name: user.fullName.isNotEmpty ? user.fullName : user.email,
      avatar: user.avatar,
      subtitle: user.email,
      onTap: () => context.push('/profile', extra: user.id),
      trailing: action,
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FriendProvider>();
    final allFriends = provider.friends;
    final shownFriends = allFriends.take(_shownCount).toList();
    final hasMoreFriends = _shownCount < allFriends.length;

    return Scaffold(
      backgroundColor: Colors.white,
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
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.8), size: 20),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      onPressed: _clear,
                      icon: const Icon(Icons.close, size: 14, color: Colors.white70),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    )
                  : null,
            ),
            onChanged: _onTextChanged,
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
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                // Load more friends when not searching and scrolled to bottom
                if (!_isEmptyQuery) return false;
                if (!notification.metrics.atEdge) return false;
                if (notification.metrics.pixels < notification.metrics.maxScrollExtent - 100) return false;
                if (!hasMoreFriends) return false;

                setState(() {
                  _shownCount += _pageSize;
                });
                return false;
              },
              child: ListView(
                children: [
                  // ===== SECTION: FRIENDS (only when search is empty) =====
                  if (_isEmptyQuery && shownFriends.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Bạn bè (${allFriends.length})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          if (hasMoreFriends)
                            GestureDetector(
                              onTap: () => setState(() => _shownCount = allFriends.length),
                              child: const Text(
                                'Xem thêm',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    ...shownFriends.map(_friendTile),
                    if (hasMoreFriends)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: GestureDetector(
                            onTap: () => setState(() => _shownCount = allFriends.length),
                            child: const Text(
                              'Tải thêm bạn bè',
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],

                  // ===== SECTION: SEARCH RESULTS (only when searching) =====
                  if (!_isEmptyQuery && _searchResults.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: Text(
                        'Kết quả tìm kiếm',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ..._searchResults.map(_searchTile),
                  ],

                  // ===== EMPTY STATES =====
                  if (_hasSearched && _searchResults.isEmpty && !_isSearching && !_hasError) ...[
                    const SizedBox(height: 60),
                    const Center(
                      child: Column(
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'Không tìm thấy kết quả',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_hasError) ...[
                    const SizedBox(height: 60),
                    const Center(
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red),
                          SizedBox(height: 12),
                          Text(
                            'Có lỗi xảy ra khi tìm kiếm',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ===== NO FRIENDS STATE =====
                  if (_isEmptyQuery && allFriends.isEmpty && !_isSearching) ...[
                    const SizedBox(height: 60),
                    const Center(
                      child: Column(
                        children: [
                          Icon(Icons.person_add_alt_1, size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'Chưa có bạn bè nào',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tìm kiếm để kết bạn',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
