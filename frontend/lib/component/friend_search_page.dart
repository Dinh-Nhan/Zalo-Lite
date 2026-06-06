import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/features/friends/friends.dart';
import 'package:frontend/features/profile/screens/profile_screen.dart';
import 'package:frontend/providers/chat_provider.dart';
import 'package:frontend/services/chat/chat_service.dart';
import 'package:frontend/views/chat/chat_screen.dart';
import 'package:provider/provider.dart';

class FriendSearchPage extends StatefulWidget {
  const FriendSearchPage({super.key});

  @override
  State<FriendSearchPage> createState() => _FriendSearchPageState();
}

class _FriendSearchPageState extends State<FriendSearchPage> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  List<UserSearchModel> _results = [];
  bool _isSearching = false;
  bool _hasError = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    debugPrint('[Search] _performSearch start: $query');
    setState(() {
      _isSearching = true;
      _hasError = false;
    });

    try {
      final results = await FriendService.searchUsers(query);
      debugPrint('[Search] API returned ${results.length} results');

      if (!mounted) return;

      setState(() {
        _results = results;
        _isSearching = false;
        _hasSearched = true;
      });
      debugPrint('[Search] state updated: _results=${_results.length}, _hasSearched=$_hasSearched');
    } catch (e) {
      debugPrint('[Search] error: $e');
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

  void _openProfile(String userId) {
    debugPrint('[FriendSearchPage] _openProfile called: $userId');
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(targetUserId: userId),
      ),
    );
  }

  void _openChat(String userId) async {
    final chatProvider = context.read<ChatProvider>();
    final conversation = await ChatService().createConversation(
      type: 'private',
      participantIds: [userId],
    );
    if (!mounted) return;
    unawaited(chatProvider.openConversation(conversation));
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(conversation: conversation),
      ),
    );
  }

  void _declineRequest(String userId) {
    context.read<FriendProvider>().declineFriendRequest(userId);
  }

  void _acceptRequest(String userId) {
    context.read<FriendProvider>().acceptFriendRequest(userId);
  }

  void _cancelRequest(String userId) {
    context.read<FriendProvider>().cancelFriendRequest(userId);
  }

  void _sendRequest(String userId) {
    context.read<FriendProvider>().sendFriendRequest(userId);
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final provider = context.watch<FriendProvider>();

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
              hintText: 'Tim ban be, email...',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
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
          if (_isSearching)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _buildBody(currentUid, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(String currentUid, FriendProvider provider) {
    if (_hasError) {
      return const Center(child: Text('Khong the ket noi'));
    }

    if (_isSearching && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasSearched && _results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Khong tim thay nguoi dung', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final user = _results[index];
        return _SearchResultTile(
          user: user,
          currentUid: currentUid,
          isFriend: provider.isFriend(user.id),
          hasReceivedRequest: provider.getReceivedRequest(user.id) != null,
          hasSentRequest: provider.pendingSent.any((f) => f.addresseeId == user.id),
          onTap: () => _openProfile(user.id),
          onChat: () => _openChat(user.id),
          onDecline: () => _declineRequest(user.id),
          onAccept: () => _acceptRequest(user.id),
          onCancel: () => _cancelRequest(user.id),
          onSend: () => _sendRequest(user.id),
        );
      },
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final UserSearchModel user;
  final String currentUid;
  final bool isFriend;
  final bool hasReceivedRequest;
  final bool hasSentRequest;
  final VoidCallback onTap;
  final VoidCallback onChat;
  final VoidCallback onDecline;
  final VoidCallback onAccept;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  const _SearchResultTile({
    required this.user,
    required this.currentUid,
    required this.isFriend,
    required this.hasReceivedRequest,
    required this.hasSentRequest,
    required this.onTap,
    required this.onChat,
    required this.onDecline,
    required this.onAccept,
    required this.onCancel,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelf = user.id == currentUid;
    final String displayName = user.fullName.isNotEmpty ? user.fullName : user.email;
    final String avatarChar = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: CircleAvatar(
                  radius: 24,
                  backgroundImage: user.avatar.isNotEmpty ? NetworkImage(user.avatar) : null,
                  child: user.avatar.isEmpty ? Text(avatarChar) : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildAction(isSelf),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAction(bool isSelf) {
    if (isSelf) return const SizedBox(width: 1);
    if (isFriend) {
      return IconButton(
        icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryBlue, size: 22),
        onPressed: onChat,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      );
    }
    if (hasReceivedRequest) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onDecline,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            icon: const Icon(Icons.check, size: 18),
            onPressed: onAccept,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      );
    }
    if (hasSentRequest) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Text('Da gui', style: TextStyle(fontSize: 12, color: Colors.grey)),
      );
    }
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 32),
      ),
      onPressed: onSend,
      child: const Text('Ket ban', style: TextStyle(fontSize: 12)),
    );
  }
}
