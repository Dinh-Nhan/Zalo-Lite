import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/dark_mode_config.dart';
import 'package:provider/provider.dart';

import '../providers/friend_provider.dart';
import '../services/friend_service.dart';
import '../widgets/friend_action_button.dart';
import '../widgets/friend_avatar.dart';

/// Màn hình "Thêm bạn" — copy giao diện Zalo.
/// Mở dưới dạng modal bottom sheet hoặc full-screen push route.
class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query, FriendProvider provider) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      provider.clearSearch();
      setState(() => _hasSearched = false);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      provider.searchUsers(query);
      setState(() => _hasSearched = true);
    });
  }

  void _clearSearch(FriendProvider provider) {
    _searchCtrl.clear();
    provider.clearSearch();
    setState(() => _hasSearched = false);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, _) {
        return ChangeNotifierProvider(
          create: (_) {
            final provider = FriendProvider();
            // Load data + kừởi động realtime
            provider.loadRequests();
            provider.startRealtime();
            // Gán callback hiển thị snackbar
            provider.onRealtimeNotify = (msg, {isSuccess = false}) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msg),
                  backgroundColor: isSuccess
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF0068FF),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            };
            return provider;
          },
          child: Consumer<FriendProvider>(
            builder: (context, provider, _) {
              return Scaffold(
                backgroundColor: AppColors.getBackground(isDark),
                appBar: _buildAppBar(isDark, provider),
                body: _buildBody(isDark, provider),
              );
            },
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, FriendProvider provider) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : AppColors.primaryBlue,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: _buildSearchBar(isDark, provider),
      actions: [
        // QR scan button
        IconButton(
          icon: const Icon(
            Icons.qr_code_scanner,
            color: Colors.white,
            size: 22,
          ),
          onPressed: () {},
          tooltip: 'Quét mã QR',
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isDark, FriendProvider provider) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextField(
        controller: _searchCtrl,
        focusNode: _focusNode,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Tìm theo tên hoặc email',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 14,
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 18),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? GestureDetector(
                  onTap: () => _clearSearch(provider),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 18,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 9,
          ),
          isDense: true,
        ),
        onChanged: (v) {
          setState(() {}); // rebuild để cập nhật clear button
          _onSearchChanged(v, provider);
        },
      ),
    );
  }

  Widget _buildBody(bool isDark, FriendProvider provider) {
    // Đang tìm kiếm
    if (_hasSearched) {
      return _buildSearchResults(isDark, provider);
    }
    // Màn hình mặc định: gợi ý + lời mời đang chờ
    return _buildDefaultContent(isDark, provider);
  }

  // ── DEFAULT CONTENT ───────────────────────────────────────────
  Widget _buildDefaultContent(bool isDark, FriendProvider provider) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Quick actions banner
        _buildQuickActions(isDark),
        const SizedBox(height: 8),
        // Lời mời đã nhận
        if (provider.pendingReceived.isNotEmpty)
          _buildPendingReceivedSection(isDark, provider),
        // Lời mời đã gửi
        if (provider.pendingSent.isNotEmpty)
          _buildPendingSentSection(isDark, provider),
        // Empty state nếu không có gì
        if (provider.pendingReceived.isEmpty && provider.pendingSent.isEmpty)
          _buildEmptyRequests(isDark),
      ],
    );
  }

  Widget _buildQuickActions(bool isDark) {
    final bg = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = AppColors.getTextPrimary(isDark);
    final subColor = AppColors.getTextSecondary(isDark);

    final actions = [
      {'icon': Icons.contacts_outlined, 'label': 'Danh bạ\nmáy'},
      {'icon': Icons.qr_code, 'label': 'Mã QR\ncủa tôi'},
      {'icon': Icons.link, 'label': 'Link\nkết bạn'},
      {'icon': Icons.near_me_outlined, 'label': 'Gần\ntôi'},
    ];

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: actions
            .map(
              (a) => GestureDetector(
                onTap: () {},
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCard
                            : const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        a['icon'] as IconData,
                        color: AppColors.primaryBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a['label'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: subColor),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildPendingReceivedSection(bool isDark, FriendProvider provider) {
    final bg = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = AppColors.getTextPrimary(isDark);
    final subColor = AppColors.getTextSecondary(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: bg,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(
            'Lời mời kết bạn (${provider.pendingReceived.length})',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
        ...provider.pendingReceived.map(
          (f) => _buildReceivedRequestTile(f, isDark, provider),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildReceivedRequestTile(
    FriendshipModel f,
    bool isDark,
    FriendProvider provider,
  ) {
    final bg = isDark ? AppColors.darkSurface : Colors.white;
    final isLoading = provider.isActionLoading(f.senderId);
    // Uu tien senderName từ API (enriched), fallback ve senderId
    final displayName = (f.senderName?.isNotEmpty == true)
        ? f.senderName!
        : f.senderId;
    final avatarUrl = (f.senderAvatar?.isNotEmpty == true)
        ? f.senderAvatar
        : null;

    return Container(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            FriendAvatar(name: displayName, avatarUrl: avatarUrl, radius: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.getTextPrimary(isDark),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Gửi lời mời kết bạn',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FriendActionButton(
                        label: 'Từ chối',
                        style: FriendActionStyle.ghost,
                        isLoading: isLoading,
                        onTap: () => provider.declineFriendRequest(f.senderId),
                      ),
                      const SizedBox(width: 8),
                      FriendActionButton(
                        label: 'Chấp nhận',
                        style: FriendActionStyle.primary,
                        isLoading: isLoading,
                        onTap: () => provider.acceptFriendRequest(f.senderId),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingSentSection(bool isDark, FriendProvider provider) {
    final bg = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = AppColors.getTextPrimary(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: bg,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(
            'Đã gửi lời mời (${provider.pendingSent.length})',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
        ...provider.pendingSent.map(
          (f) => _buildSentRequestTile(f, isDark, provider),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSentRequestTile(
    FriendshipModel f,
    bool isDark,
    FriendProvider provider,
  ) {
    final bg = isDark ? AppColors.darkSurface : Colors.white;
    final isLoading = provider.isActionLoading(f.addresseeId);

    return Container(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            FriendAvatar(name: f.addresseeName, radius: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    f.addresseeName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.getTextPrimary(isDark),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Đang chờ chấp nhận',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                  ),
                ],
              ),
            ),
            FriendActionButton(
              label: 'Huỷ',
              style: FriendActionStyle.ghost,
              isLoading: isLoading,
              onTap: () => provider.cancelFriendRequest(f.addresseeId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRequests(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 72,
            color: AppColors.getTextSecondary(isDark).withValues(alpha: 0.35),
          ),
          const SizedBox(height: 16),
          Text(
            'Tìm kiếm bạn bè theo tên hoặc email',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getTextSecondary(isDark),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hoặc dùng các gợi ý bên trên',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.getTextSecondary(isDark).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ── SEARCH RESULTS ────────────────────────────────────────────
  Widget _buildSearchResults(bool isDark, FriendProvider provider) {
    if (provider.searchState == LoadingState.loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppColors.primaryBlue,
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 16),
            Text(
              'Đang tìm kiếm...',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextSecondary(isDark),
              ),
            ),
          ],
        ),
      );
    }

    if (provider.searchState == LoadingState.error) {
      return _buildErrorState(isDark, provider);
    }

    if (provider.searchResults.isEmpty &&
        provider.searchState == LoadingState.success) {
      return _buildNoResults(isDark);
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: provider.searchResults.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, indent: 72, color: AppColors.getDivider(isDark)),
      itemBuilder: (context, i) =>
          _buildUserTile(provider.searchResults[i], isDark, provider),
    );
  }

  Widget _buildUserTile(
    UserSearchModel user,
    bool isDark,
    FriendProvider provider,
  ) {
    final bg = isDark ? AppColors.darkSurface : Colors.white;
    final isFriend = provider.isFriend(user.id);
    final sentReq = provider.getSentRequest(user.id);
    final receivedReq = provider.getReceivedRequest(user.id);
    final isLoading = provider.isActionLoading(user.id);

    return Container(
      color: bg,
      child: InkWell(
        onTap: () => _showUserBottomSheet(user, isDark, provider),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Avatar
              FriendAvatar(
                name: user.fullName.isEmpty ? user.email : user.fullName,
                avatarUrl: user.avatar.isNotEmpty ? user.avatar : null,
                radius: 24,
                isOnline: user.status,
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName.isNotEmpty ? user.fullName : user.email,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.getTextPrimary(isDark),
                      ),
                    ),
                    if (user.email.isNotEmpty && user.fullName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.getTextSecondary(isDark),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Action button
              _buildUserActionButton(
                user: user,
                isDark: isDark,
                isFriend: isFriend,
                sentReq: sentReq,
                receivedReq: receivedReq,
                isLoading: isLoading,
                provider: provider,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserActionButton({
    required UserSearchModel user,
    required bool isDark,
    required bool isFriend,
    required FriendshipModel? sentReq,
    required FriendshipModel? receivedReq,
    required bool isLoading,
    required FriendProvider provider,
  }) {
    if (isFriend) {
      return FriendActionButton(
        label: 'Bạn bè',
        icon: Icons.check,
        style: FriendActionStyle.ghost,
        onTap: () => _confirmUnfriend(user, provider),
      );
    }

    if (receivedReq != null) {
      // Người này đã gửi lời mời cho mình → cho phép chấp nhận/từ chối
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FriendActionButton(
            label: 'Từ chối',
            style: FriendActionStyle.ghost,
            isLoading: isLoading,
            onTap: () => provider.declineFriendRequest(user.id),
          ),
          const SizedBox(width: 6),
          FriendActionButton(
            label: 'Chấp nhận',
            style: FriendActionStyle.primary,
            isLoading: isLoading,
            onTap: () => provider.acceptFriendRequest(user.id),
          ),
        ],
      );
    }

    if (sentReq != null) {
      // Mình đã gửi lời mời → cho phép huỷ
      return FriendActionButton(
        label: 'Đã gửi',
        icon: Icons.schedule,
        style: FriendActionStyle.secondary,
        isLoading: isLoading,
        onTap: () => provider.cancelFriendRequest(user.id),
      );
    }

    // Chưa có quan hệ → Add friend
    return FriendActionButton(
      label: 'Kết bạn',
      icon: Icons.person_add_outlined,
      style: FriendActionStyle.primary,
      isLoading: isLoading,
      onTap: () => provider.sendFriendRequest(user.id),
    );
  }

  Widget _buildNoResults(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 72,
            color: AppColors.getTextSecondary(isDark).withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy người dùng',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Thử tìm bằng tên đầy đủ hoặc địa chỉ email',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.getTextSecondary(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark, FriendProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 56,
            color: AppColors.getTextSecondary(isDark).withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Không thể kết nối',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => provider.searchUsers(_searchCtrl.text),
            child: const Text(
              'Thử lại',
              style: TextStyle(color: AppColors.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  // ── DIALOGS & BOTTOM SHEETS ───────────────────────────────────

  void _confirmUnfriend(UserSearchModel user, FriendProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Huỷ kết bạn'),
        content: Text(
          'Bạn có muốn huỷ kết bạn với ${user.fullName.isNotEmpty ? user.fullName : user.email} không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.unfriend(user.id);
            },
            child: const Text(
              'Huỷ kết bạn',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserBottomSheet(
    UserSearchModel user,
    bool isDark,
    FriendProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          _UserProfileSheet(user: user, isDark: isDark, provider: provider),
    );
  }
}

// ── USER PROFILE BOTTOM SHEET ─────────────────────────────────
class _UserProfileSheet extends StatelessWidget {
  final UserSearchModel user;
  final bool isDark;
  final FriendProvider provider;

  const _UserProfileSheet({
    required this.user,
    required this.isDark,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final isFriend = provider.isFriend(user.id);
    final sentReq = provider.getSentRequest(user.id);
    final receivedReq = provider.getReceivedRequest(user.id);
    final isLoading = provider.isActionLoading(user.id);

    final bg = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = AppColors.getTextPrimary(isDark);
    final subColor = AppColors.getTextSecondary(isDark);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF444444) : const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          // Avatar
          FriendAvatar(
            name: user.fullName.isEmpty ? user.email : user.fullName,
            avatarUrl: user.avatar.isNotEmpty ? user.avatar : null,
            radius: 40,
            isOnline: user.status,
          ),
          const SizedBox(height: 12),
          // Name
          Text(
            user.fullName.isNotEmpty ? user.fullName : 'Chưa cập nhật tên',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          if (user.email.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                user.email,
                style: TextStyle(fontSize: 13, color: subColor),
              ),
            ),
          const SizedBox(height: 6),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: user.status
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: user.status
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF9E9E9E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  user.status ? 'Đang hoạt động' : 'Không hoạt động',
                  style: TextStyle(
                    fontSize: 12,
                    color: user.status
                        ? const Color(0xFF388E3C)
                        : const Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Action buttons row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildSheetActions(
              context,
              isFriend: isFriend,
              sentReq: sentReq,
              receivedReq: receivedReq,
              isLoading: isLoading,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSheetActions(
    BuildContext context, {
    required bool isFriend,
    required FriendshipModel? sentReq,
    required FriendshipModel? receivedReq,
    required bool isLoading,
  }) {
    if (isFriend) {
      return Row(
        children: [
          Expanded(
            child: FriendActionButton(
              label: 'Nhắn tin',
              icon: Icons.chat_bubble_outline,
              style: FriendActionStyle.secondary,
              height: 42,
              onTap: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FriendActionButton(
              label: 'Huỷ kết bạn',
              icon: Icons.person_remove_outlined,
              style: FriendActionStyle.danger,
              height: 42,
              onTap: () {
                Navigator.pop(context);
                provider.unfriend(user.id);
              },
            ),
          ),
        ],
      );
    }

    if (receivedReq != null) {
      return Row(
        children: [
          Expanded(
            child: FriendActionButton(
              label: 'Từ chối',
              style: FriendActionStyle.ghost,
              height: 42,
              isLoading: isLoading,
              onTap: () {
                provider.declineFriendRequest(user.id);
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FriendActionButton(
              label: 'Chấp nhận',
              icon: Icons.check,
              style: FriendActionStyle.primary,
              height: 42,
              isLoading: isLoading,
              onTap: () {
                provider.acceptFriendRequest(user.id);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      );
    }

    if (sentReq != null) {
      return SizedBox(
        width: double.infinity,
        child: FriendActionButton(
          label: 'Huỷ lời mời đã gửi',
          icon: Icons.cancel_outlined,
          style: FriendActionStyle.ghost,
          height: 42,
          isLoading: isLoading,
          onTap: () {
            provider.cancelFriendRequest(user.id);
            Navigator.pop(context);
          },
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FriendActionButton(
        label: 'Kết bạn',
        icon: Icons.person_add_outlined,
        style: FriendActionStyle.primary,
        height: 42,
        isLoading: isLoading,
        onTap: () {
          provider.sendFriendRequest(user.id);
          Navigator.pop(context);
        },
      ),
    );
  }
}
