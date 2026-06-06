import 'package:flutter/material.dart';
import 'package:frontend/apps/app_locale.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/dark_mode_config.dart';
import 'package:frontend/features/friends/screens/add_friend_screen.dart';
import 'package:frontend/features/friends/screens/friend_list_screen.dart';
import 'package:frontend/features/friends/screens/friend_requests_screen.dart';
import 'package:frontend/utils/app_localizations.dart';
import 'package:frontend/widgets/search_overlay_screen.dart';
import 'package:frontend/component/friend_search_page.dart';

/// Màn hình Danh bạ - Contacts View
/// Giao diện nhỏ (mobile): hiển thị tabs Bạn bè / Nhóm
/// Giao diện lớn (wide): hiển thị sidebar menu + content panel
class ContactsView extends StatefulWidget {
  final bool isWideScreen;

  const ContactsView({super.key, this.isWideScreen = false});

  @override
  State<ContactsView> createState() => _ContactsViewState();
}

class _ContactsViewState extends State<ContactsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedMenuIndex = 0;

  // NOTE: _mockContacts sẽ được thay bằng FriendListScreen (API thật).
  // Chỉ giữ _mockGroups cho tab Nhóm chưa có API.

  // Mock groups data
  final List<Map<String, dynamic>> _mockGroups = [
    {
      'id': 'g_001',
      'name': 'Nhóm Đồ Ăn',
      'avatar': null,
      'avatarColor': const Color(0xFF9C27B0),
      'memberCount': 5,
    },
    {
      'id': 'g_002',
      'name': 'Nhóm Lớp K18',
      'avatar': null,
      'avatarColor': const Color(0xFFFF9800),
      'memberCount': 45,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, child) {
        return ValueListenableBuilder(
          valueListenable: localeNotifier,
          builder: (context, locale, child) {
            final t = AppLocalizations(locale);
            if (widget.isWideScreen) {
              return _buildWideLayout(t, isDark);
            }
            return _buildMobileLayout(t, isDark);
          },
        );
      },
    );
  }

  // ============================================
  // MOBILE LAYOUT
  // ============================================
  Widget _buildMobileLayout(AppLocalizations t, bool isDark) {
    return Column(
      children: [
        _buildMobileHeader(t, isDark),
        _buildMobileTabs(t, isDark),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFriendListMobile(t, isDark),
              _buildGroupListMobile(t, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeader(AppLocalizations t, bool isDark) {
    final Color headerBg =
        isDark ? const Color(0xFF1A1A1A) : AppColors.primaryBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: headerBg,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _openSearchOverlay(context),
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    Icon(
                      Icons.search,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t.get('searchPlaceholder'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildIconBtn(
            Icons.person_add_outlined,
            Colors.white,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddFriendScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTabs(AppLocalizations t, bool isDark) {
    return Container(
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primaryBlue,
        unselectedLabelColor: AppColors.getTextSecondary(isDark),
        indicatorColor: AppColors.primaryBlue,
        indicatorWeight: 2,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        tabs: [
          Tab(text: t.get('friends')),
          Tab(text: t.get('groups')),
        ],
      ),
    );
  }

  Widget _buildFriendListMobile(AppLocalizations t, bool isDark) {
    // Sử dụng FriendListScreen thật thay vì mock data
    return const FriendListScreen();
  }

  Widget _buildGroupListMobile(AppLocalizations t, bool isDark) {
    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.backgroundGray,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          ..._mockGroups.map((group) => _buildGroupTile(group, t, isDark)),
        ],
      ),
    );
  }

  Widget _buildGroupTile(
    Map<String, dynamic> group,
    AppLocalizations t,
    bool isDark,
  ) {
    return Container(
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: group['avatarColor'],
          child: Text(
            _getInitials(group['name']),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(
          group['name'],
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.getTextPrimary(isDark),
          ),
        ),
        subtitle: Text(
          '${group['memberCount']} ${t.get('members')}',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.getTextSecondary(isDark),
          ),
        ),
        trailing: Icon(
          Icons.more_horiz,
          color: AppColors.getTextSecondary(isDark),
        ),
        onTap: () {},
      ),
    );
  }

  // ============================================
  // WIDE LAYOUT (Desktop)
  // ============================================
  Widget _buildWideLayout(AppLocalizations t, bool isDark) {
    return Row(
      children: [
        // Left sidebar menu
        _buildWideSidebar(t, isDark),
        // Right content panel
        Expanded(child: _buildWideContent(t, isDark)),
      ],
    );
  }

  Widget _buildWideSidebar(AppLocalizations t, bool isDark) {
    final menuItems = [
      {'icon': Icons.people_outline, 'label': t.get('friendList')},
      {'icon': Icons.groups_outlined, 'label': t.get('groupAndCommunity')},
      {'icon': Icons.person_add_alt_outlined, 'label': t.get('friendRequest')},
      {'icon': Icons.group_add_outlined, 'label': t.get('groupInvitation')},
    ];

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border(
          right: BorderSide(color: AppColors.getDivider(isDark), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // Search bar (opens overlay on tap)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: GestureDetector(
              onTap: () => _openSearchOverlay(context),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(
                      Icons.search,
                      color: AppColors.getTextSecondary(isDark),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t.get('searchPlaceholder'),
                        style: TextStyle(
                          color: AppColors.getTextSecondary(isDark),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Menu items
          ...menuItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = _selectedMenuIndex == index;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              child: Material(
                color: isSelected
                    ? (isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFE8F0FE))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                child: InkWell(
                  onTap: () => setState(() => _selectedMenuIndex = index),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 20,
                          color: isSelected
                              ? AppColors.primaryBlue
                              : AppColors.getTextSecondary(isDark),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item['label'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : AppColors.getTextPrimary(isDark),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWideContent(AppLocalizations t, bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header title
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF242424) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.getDivider(isDark),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(_getContentIcon(), size: 20, color: AppColors.primaryBlue),
                const SizedBox(width: 10),
                Text(
                  _getContentTitle(t),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimary(isDark),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(child: _buildContentByMenu(t, isDark)),
        ],
      ),
    );
  }

  IconData _getContentIcon() {
    switch (_selectedMenuIndex) {
      case 0:
        return Icons.people_outline;
      case 1:
        return Icons.groups_outlined;
      case 2:
        return Icons.person_add_alt_outlined;
      case 3:
        return Icons.group_add_outlined;
      default:
        return Icons.people_outline;
    }
  }

  String _getContentTitle(AppLocalizations t) {
    switch (_selectedMenuIndex) {
      case 0:
        return t.get('friendList');
      case 1:
        return t.get('groupAndCommunity');
      case 2:
        return t.get('friendRequest');
      case 3:
        return t.get('groupInvitation');
      default:
        return t.get('friendList');
    }
  }

  Widget _buildContentByMenu(AppLocalizations t, bool isDark) {
    switch (_selectedMenuIndex) {
      case 0:
        // Danh sách bạn bè thật từ API
        return const FriendListScreen();
      case 1:
        return _buildWideGroupList(t, isDark);
      case 2:
        // Lời mời kết bạn thật từ API
        return const FriendRequestsScreen();
      case 3:
        return _buildWideGroupInvitations(t, isDark);
      default:
        return const FriendListScreen();
    }
  }

  Widget _buildWideGroupList(AppLocalizations t, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _mockGroups
          .map((group) => _buildWideGroupTile(group, t, isDark))
          .toList(),
    );
  }

  Widget _buildWideGroupTile(
    Map<String, dynamic> group,
    AppLocalizations t,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: group['avatarColor'],
            child: Text(
              _getInitials(group['name']),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group['name'],
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getTextPrimary(isDark),
                  ),
                ),
                Text(
                  '${group['memberCount']} ${t.get('members')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getTextSecondary(isDark),
                  ),
                ),
              ],
            ),
          ),
          _buildIconBtn(
            Icons.call_outlined,
            AppColors.getTextSecondary(isDark),
            () {},
          ),
          const SizedBox(width: 4),
          _buildIconBtn(
            Icons.videocam_outlined,
            AppColors.getTextSecondary(isDark),
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildWideFriendRequests(AppLocalizations t, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mark_email_read_outlined,
            size: 64,
            color: AppColors.getTextSecondary(isDark).withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            t.get('noFriendRequest'),
            style: TextStyle(
              fontSize: 15,
              color: AppColors.getTextSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideGroupInvitations(AppLocalizations t, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppColors.getTextSecondary(isDark).withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            t.get('noGroupInvitation'),
            style: TextStyle(
              fontSize: 15,
              color: AppColors.getTextSecondary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Khi nào tải được lời mời?',
            style: TextStyle(fontSize: 13, color: AppColors.primaryBlue),
          ),
        ],
      ),
    );
  }

  // ============================================
  // SHARED HELPERS
  // ============================================
  Widget _buildIconBtn(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  void _openSearchOverlay(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => const FriendSearchPage(),
      ),
    );
  }
}
