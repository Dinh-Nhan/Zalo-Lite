import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/features/friends/friends.dart';
import 'package:frontend/features/friends/screens/qr_friend_screen.dart';
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
class SearchResultItem {
  final String id;
  final String name;
  final String email;
  final String avatar;

  final bool isFriend;

  const SearchResultItem({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.isFriend,
  });
}
class _FriendSearchPageState extends State<FriendSearchPage> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  // List<UserSearchModel> _results = [];
  List<SearchResultItem> _results = [];

  bool _isSearching = false;
  bool _hasError = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }
  // Future<void> _performSearch(String query) async {
  //   setState(() {
  //     _isSearching = true;
  //     _hasError = false;
  //   });

  //   try {
  //     final results = await FriendService.searchUsers(query);

  //     if (!mounted) return;

  //     setState(() {
  //       _results = results;
  //       _isSearching = false;
  //       _hasSearched = true;
  //     });
  //   } catch (_) {
  //     if (!mounted) return;

  //     setState(() {
  //       _results = [];
  //       _isSearching = false;
  //       _hasError = true;
  //       _hasSearched = true;
  //     });
  //   }
  // }
  Future<void> _performSearch(String keyword) async {
    final provider = context.read<FriendProvider>();

    setState(() {
      _isSearching = true;
      _hasError = false;
    });

    try {
      final Map<String, SearchResultItem> merged = {};

      // =====================================
      // 1. TÌM TRONG BẠN BÈ
      // =====================================

      final friendMatches = provider.friends.where((f) {
        return f.fullName.toLowerCase().contains(
          keyword.toLowerCase(),
        );
      });

      for (final friend in friendMatches) {
        merged[friend.friendId] = SearchResultItem(
          id: friend.friendId,
          name: friend.fullName,
          email: '',
          avatar: friend.avatar,
          isFriend: true,
        );
      }

      // =====================================
      // 2. GỌI API SEARCH
      // =====================================

      final apiResults =
          await FriendService.searchUsers(keyword);

      for (final user in apiResults) {
        merged.putIfAbsent(
          user.id,
          () => SearchResultItem(
            id: user.id,
            name: user.fullName,
            email: user.email,
            avatar: user.avatar,
            isFriend: provider.isFriend(user.id),
          ),
        );
      }

      final results = merged.values.toList();

      // Bạn bè lên đầu

      results.sort((a, b) {
        if (a.isFriend == b.isFriend) return 0;

        return a.isFriend ? -1 : 1;
      });

      if (!mounted) return;

      setState(() {
        _results = results;
        _isSearching = false;
        _hasSearched = true;
      });
    } catch (e) {
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
      setState(() {
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
    _controller.clear();

    setState(() {
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
              child: avatar.isEmpty ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', ) : null,
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

  // ================= SEARCH TILE =================

  // Widget _searchTile(UserSearchModel user) {
  Widget _searchTile(SearchResultItem user) {
    final provider = context.watch<FriendProvider>();

    final sent = provider.pendingSent.any(
      (f) => f.addresseeId == user.id,
    );

    final received = provider.getReceivedRequest(user.id);

    // final isFriend = provider.isFriend(user.id);
    final isFriend = user.isFriend;
    Widget action;

    if (isFriend) {
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
          if (!context.mounted) return;
          unawaited(chatProvider.openConversation(conversation));
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ChatScreen(conversation: conversation)),
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
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return _buildUserTile(
      name: user.name,
      avatar: user.avatar,
      // subtitle: user.email,
      subtitle: user.isFriend
        ? 'Bạn bè'
        : user.email,
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
          // margin: const EdgeInsets.only(right: 8),
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
              prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.8), size: 20),
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
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const QrFriendScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          if (_isSearching)
            const LinearProgressIndicator(minHeight: 2),

          Expanded(
            child: Builder(
              builder: (_) {
                if (_hasError) {
                  return const Center(
                    child: Text('Không thể kết nối'),
                  );
                }

                if (_isSearching && _results.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (_hasSearched && _results.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Không tìm thấy người dùng',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (_, index) {
                    return _searchTile(_results[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}