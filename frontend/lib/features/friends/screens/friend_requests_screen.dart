import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/dark_mode_config.dart';
import 'package:provider/provider.dart';

import '../providers/friend_provider.dart';
import '../services/friend_service.dart';
import '../widgets/friend_action_button.dart';
import '../widgets/friend_avatar.dart';

/// Màn hình Lời mời kết bạn — hiển thị 2 tab:
/// • Đã nhận: chấp nhận / từ chối
/// • Đã gửi: huỷ lời mời
class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
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
            provider.loadRequests();
            provider.startRealtime();
            provider.onRealtimeNotify = (msg, {isSuccess = false}) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msg),
                  backgroundColor:
                      isSuccess ? const Color(0xFF4CAF50) : const Color(0xFF0068FF),
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
            builder: (ctx, provider, _) =>
                _buildScaffold(ctx, isDark, provider),
          ),
        );
      },
    );
  }

  Widget _buildScaffold(
    BuildContext ctx,
    bool isDark,
    FriendProvider provider,
  ) {
    final headerBg = isDark ? const Color(0xFF1A1A1A) : AppColors.primaryBlue;
    final tabBg = isDark ? AppColors.darkSurface : Colors.white;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: headerBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(ctx),
        ),
        title: const Text(
          'Lời mời kết bạn',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(42),
          child: Container(
            color: headerBg,
            child: TabBar(
              controller: _tabs,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Đã nhận'),
                      if (provider.pendingReceivedCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${provider.pendingReceivedCount}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Đã gửi'),
                      if (provider.pendingSent.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white30,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${provider.pendingSent.length}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildReceivedTab(isDark, provider),
          _buildSentTab(isDark, provider),
        ],
      ),
    );
  }

  // ── TAB: ĐÃ NHẬN ─────────────────────────────────────────────
  Widget _buildReceivedTab(bool isDark, FriendProvider provider) {
    if (provider.requestsState == LoadingState.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    if (provider.pendingReceived.isEmpty) {
      return _buildEmptyReceived(isDark);
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: provider.pendingReceived.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, color: AppColors.getDivider(isDark)),
      itemBuilder: (_, i) =>
          _buildReceivedTile(provider.pendingReceived[i], isDark, provider),
    );
  }

  Widget _buildReceivedTile(
    FriendshipModel f,
    bool isDark,
    FriendProvider provider,
  ) {
    final bg = isDark ? AppColors.darkSurface : Colors.white;
    final isLoading = provider.isActionLoading(f.senderId);
    final displayName =
        (f.senderName?.isNotEmpty == true) ? f.senderName! : f.senderId;
    final avatarUrl =
        (f.senderAvatar?.isNotEmpty == true) ? f.senderAvatar : null;

    return Container(
      color: bg,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FriendAvatar(name: displayName, avatarUrl: avatarUrl, radius: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + time
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextPrimary(isDark),
                        ),
                      ),
                    ),
                    Text(
                      _formatTime(f.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.getTextSecondary(isDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                // Source badge
                _buildSourceBadge(f.sourceType, isDark),
                const SizedBox(height: 10),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: FriendActionButton(
                        label: 'Từ chối',
                        style: FriendActionStyle.ghost,
                        isLoading: isLoading,
                        height: 34,
                        onTap: () => provider.declineFriendRequest(f.senderId),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FriendActionButton(
                        label: 'Chấp nhận',
                        style: FriendActionStyle.primary,
                        isLoading: isLoading,
                        height: 34,
                        onTap: () => provider.acceptFriendRequest(f.senderId),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceBadge(String sourceType, bool isDark) {
    String label;
    switch (sourceType) {
      case 'phone_contact':
        label = '📱 Từ danh bạ';
        break;
      case 'group':
        label = '👥 Từ nhóm';
        break;
      case 'qr_code':
        label = '📷 Quét QR';
        break;
      default:
        label = '🔍 Tìm kiếm';
    }

    return Text(
      label,
      style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark)),
    );
  }

  Widget _buildEmptyReceived(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mark_email_read_outlined,
            size: 72,
            color: AppColors.getTextSecondary(isDark).withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Không có lời mời kết bạn',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Khi ai đó gửi lời mời, bạn sẽ thấy ở đây',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.getTextSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB: ĐÃ GỬI ──────────────────────────────────────────────
  Widget _buildSentTab(bool isDark, FriendProvider provider) {
    if (provider.requestsState == LoadingState.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    if (provider.pendingSent.isEmpty) {
      return _buildEmptySent(isDark);
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: provider.pendingSent.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, color: AppColors.getDivider(isDark)),
      itemBuilder: (_, i) =>
          _buildSentTile(provider.pendingSent[i], isDark, provider),
    );
  }

  Widget _buildSentTile(
    FriendshipModel f,
    bool isDark,
    FriendProvider provider,
  ) {
    final bg = isDark ? AppColors.darkSurface : Colors.white;
    final isLoading = provider.isActionLoading(f.addresseeId);

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          FriendAvatar(name: f.addresseeId, radius: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.addresseeId,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getTextPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Đang chờ chấp nhận • ${_formatTime(f.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getTextSecondary(isDark),
                  ),
                ),
              ],
            ),
          ),
          FriendActionButton(
            label: 'Huỷ lời mời',
            style: FriendActionStyle.ghost,
            isLoading: isLoading,
            onTap: () => provider.cancelFriendRequest(f.addresseeId),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySent(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.send_outlined,
            size: 72,
            color: AppColors.getTextSecondary(isDark).withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa gửi lời mời nào',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tìm bạn bè và gửi lời mời kết bạn',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.getTextSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────
  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
