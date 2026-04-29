import 'package:flutter/material.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/dark_mode_config.dart';
import 'package:provider/provider.dart';

import '../providers/friend_provider.dart';
import '../services/friend_service.dart';
import '../widgets/friend_action_button.dart';
import '../widgets/friend_avatar.dart';
import 'add_friend_screen.dart';

/// Màn hình danh sách bạn bè — dùng trong ContactsView (tab Bạn bè).
/// Hiển thị danh sách bạn bè nhóm theo chữ cái, có thanh tìm kiếm.
class FriendListScreen extends StatefulWidget {
  const FriendListScreen({super.key});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  final TextEditingController _filterCtrl = TextEditingController();
  String _filterText = '';

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, _) {
        return ChangeNotifierProvider(
          create: (_) {
            final provider = FriendProvider();
            provider.loadAll();
            provider.startRealtime();
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
            builder: (ctx, provider, _) => _buildContent(ctx, isDark, provider),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext ctx, bool isDark, FriendProvider provider) {
    if (provider.friendsState == LoadingState.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    if (provider.friendsState == LoadingState.error) {
      return _buildError(isDark, provider);
    }

    // Filter theo text
    final filtered =
        provider.friends
            .where(
              (f) =>
                  _filterText.isEmpty ||
                  f.fullName.toLowerCase().contains(_filterText.toLowerCase()),
            )
            .toList()
          ..sort((a, b) => a.fullName.compareTo(b.fullName));

    return Column(
      children: [
        _buildHeader(isDark, provider, ctx),
        Expanded(child: _buildList(filtered, isDark, provider, ctx)),
      ],
    );
  }

  // ── HEADER ────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark, FriendProvider provider, BuildContext ctx) {
    final bg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = AppColors.getDivider(isDark);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Row(
        children: [
          // Search box
          Expanded(
            child: Container(
              height: 34,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextField(
                controller: _filterCtrl,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.getTextPrimary(isDark),
                ),
                decoration: InputDecoration(
                  hintText: 'Tìm bạn',
                  hintStyle: TextStyle(
                    color: AppColors.getTextSecondary(isDark),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.getTextSecondary(isDark),
                    size: 18,
                  ),
                  suffixIcon: _filterText.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _filterCtrl.clear();
                            setState(() => _filterText = '');
                          },
                          child: Icon(
                            Icons.close,
                            color: AppColors.getTextSecondary(isDark),
                            size: 16,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (v) => setState(() => _filterText = v),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Friend request badge button
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.person_add_outlined,
                  color: AppColors.getTextSecondary(isDark),
                  size: 22,
                ),
                onPressed: () => _openAddFriend(ctx),
              ),
              if (provider.pendingReceivedCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        provider.pendingReceivedCount > 9
                            ? '9+'
                            : '${provider.pendingReceivedCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── LIST ──────────────────────────────────────────────────────
  Widget _buildList(
    List<FriendSummaryModel> friends,
    bool isDark,
    FriendProvider provider,
    BuildContext ctx,
  ) {
    if (friends.isEmpty && _filterText.isEmpty) {
      return _buildEmptyState(isDark, ctx);
    }
    if (friends.isEmpty) {
      return _buildNoSearchResult(isDark);
    }

    // Group by first letter
    final grouped = <String, List<FriendSummaryModel>>{};
    for (final f in friends) {
      final letter = f.fullName.isNotEmpty ? f.fullName[0].toUpperCase() : '#';
      grouped.putIfAbsent(letter, () => []).add(f);
    }
    final letters = grouped.keys.toList()..sort();

    // Pending requests banner
    final items = <Widget>[];

    if (provider.pendingReceivedCount > 0 && _filterText.isEmpty) {
      items.add(_buildRequestsBanner(isDark, provider, ctx));
    }

    // Friend count
    if (_filterText.isEmpty) {
      items.add(_buildFriendCountRow(isDark, friends.length));
    }

    for (final letter in letters) {
      items.add(_buildLetterHeader(letter, isDark));
      for (final f in grouped[letter]!) {
        items.add(_buildFriendTile(f, isDark, provider, ctx));
        items.add(
          Divider(height: 1, indent: 68, color: AppColors.getDivider(isDark)),
        );
      }
    }

    return ListView(padding: EdgeInsets.zero, children: items);
  }

  Widget _buildRequestsBanner(
    bool isDark,
    FriendProvider provider,
    BuildContext ctx,
  ) {
    final bg = isDark ? AppColors.darkSurface : Colors.white;
    return Container(
      color: bg,
      child: InkWell(
        onTap: () => _openAddFriend(ctx),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.person_add,
                  color: AppColors.primaryBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lời mời kết bạn (${provider.pendingReceivedCount})',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextPrimary(isDark),
                      ),
                    ),
                    Text(
                      'Bạn có lời mời chờ chấp nhận',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.getTextSecondary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.getTextSecondary(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendCountRow(bool isDark, int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      color: isDark ? AppColors.darkBackground : const Color(0xFFF5F5F5),
      child: Text(
        'Bạn bè ($count)',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.getTextSecondary(isDark),
        ),
      ),
    );
  }

  Widget _buildLetterHeader(String letter, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      color: isDark ? AppColors.darkBackground : const Color(0xFFF5F5F5),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.getTextSecondary(isDark),
        ),
      ),
    );
  }

  Widget _buildFriendTile(
    FriendSummaryModel friend,
    bool isDark,
    FriendProvider provider,
    BuildContext ctx,
  ) {
    final bg = isDark ? AppColors.darkSurface : Colors.white;
    final isLoading = provider.isActionLoading(friend.friendId);

    return Material(
      color: bg,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              FriendAvatar(
                name: friend.fullName,
                avatarUrl: friend.avatar.isNotEmpty ? friend.avatar : null,
                radius: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  friend.fullName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.getTextPrimary(isDark),
                  ),
                ),
              ),
              // Quick actions
              _buildQuickActions(friend, isDark, provider, isLoading, ctx),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(
    FriendSummaryModel friend,
    bool isDark,
    FriendProvider provider,
    bool isLoading,
    BuildContext ctx,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _circleIconBtn(
          icon: Icons.call_outlined,
          color: AppColors.getTextSecondary(isDark),
          onTap: () {},
        ),
        const SizedBox(width: 2),
        _circleIconBtn(
          icon: Icons.videocam_outlined,
          color: AppColors.getTextSecondary(isDark),
          onTap: () {},
        ),
        const SizedBox(width: 2),
        _circleIconBtn(
          icon: Icons.more_horiz,
          color: AppColors.getTextSecondary(isDark),
          onTap: () => _showFriendOptions(friend, isDark, provider, ctx),
        ),
      ],
    );
  }

  Widget _circleIconBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  // ── EMPTY / ERROR STATES ──────────────────────────────────────
  Widget _buildEmptyState(bool isDark, BuildContext ctx) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: AppColors.getTextSecondary(isDark).withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có bạn bè nào',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tìm và kết bạn với mọi người',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.getTextSecondary(isDark),
            ),
          ),
          const SizedBox(height: 20),
          FriendActionButton(
            label: 'Thêm bạn bè',
            icon: Icons.person_add_outlined,
            style: FriendActionStyle.primary,
            height: 40,
            onTap: () => _openAddFriend(ctx),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResult(bool isDark) {
    return Center(
      child: Text(
        'Không tìm thấy bạn bè',
        style: TextStyle(
          fontSize: 14,
          color: AppColors.getTextSecondary(isDark),
        ),
      ),
    );
  }

  Widget _buildError(bool isDark, FriendProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.getTextSecondary(isDark).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Không thể tải danh sách bạn bè',
            style: TextStyle(color: AppColors.getTextPrimary(isDark)),
          ),
          TextButton(
            onPressed: provider.loadFriends,
            child: const Text(
              'Thử lại',
              style: TextStyle(color: AppColors.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  // ── BOTTOM SHEET OPTIONS ──────────────────────────────────────
  void _showFriendOptions(
    FriendSummaryModel friend,
    bool isDark,
    FriendProvider provider,
    BuildContext ctx,
  ) {
    final bg = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = AppColors.getTextPrimary(isDark);
    final subColor = AppColors.getTextSecondary(isDark);

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.getDivider(isDark),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  FriendAvatar(
                    name: friend.fullName,
                    avatarUrl: friend.avatar.isNotEmpty ? friend.avatar : null,
                    radius: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    friend.fullName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.getDivider(isDark)),
            _optionTile(
              icon: Icons.chat_bubble_outline,
              label: 'Nhắn tin',
              color: textColor,
              onTap: () => Navigator.pop(ctx),
            ),
            _optionTile(
              icon: Icons.call_outlined,
              label: 'Gọi thoại',
              color: textColor,
              onTap: () => Navigator.pop(ctx),
            ),
            _optionTile(
              icon: Icons.videocam_outlined,
              label: 'Gọi video',
              color: textColor,
              onTap: () => Navigator.pop(ctx),
            ),
            Divider(height: 1, color: AppColors.getDivider(isDark)),
            _optionTile(
              icon: Icons.person_remove_outlined,
              label: 'Huỷ kết bạn',
              color: const Color(0xFFE53935),
              onTap: () {
                Navigator.pop(ctx);
                _confirmUnfriend(friend, provider, ctx);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _optionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(fontSize: 15, color: color)),
          ],
        ),
      ),
    );
  }

  void _confirmUnfriend(
    FriendSummaryModel friend,
    FriendProvider provider,
    BuildContext ctx,
  ) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Huỷ kết bạn'),
        content: Text('Bạn có muốn huỷ kết bạn với ${friend.fullName} không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.unfriend(friend.friendId);
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

  void _openAddFriend(BuildContext ctx) {
    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => const AddFriendScreenWrapper()),
    );
  }
}

// Wrapper để navigate sang AddFriendScreen riêng biệt
// (tránh share state với FriendListScreen)
class AddFriendScreenWrapper extends StatelessWidget {
  const AddFriendScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const AddFriendScreen();
  }
}
