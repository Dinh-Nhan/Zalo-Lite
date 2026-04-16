import 'package:flutter/material.dart';
import 'package:frontend/apps/app_locale.dart';
import 'package:frontend/utils/app_localizations.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/dark_mode_config.dart';

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

  // Mock contacts data
  final List<Map<String, dynamic>> _mockContacts = [
    {
      'id': 'c_001',
      'name': 'Đình Nhân',
      'avatar': null,
      'avatarColor': const Color(0xFF4CAF50),
      'isOnline': true,
    },
    {
      'id': 'c_002',
      'name': 'Minh Anh',
      'avatar': null,
      'avatarColor': const Color(0xFF2196F3),
      'isOnline': false,
    },
    {
      'id': 'c_003',
      'name': 'Tuấn Kiệt',
      'avatar': null,
      'avatarColor': const Color(0xFFE91E63),
      'isOnline': true,
    },
    {
      'id': 'c_004',
      'name': 'Anh Sơn',
      'avatar': null,
      'avatarColor': const Color(0xFF9C27B0),
      'isOnline': false,
    },
    {
      'id': 'c_005',
      'name': 'Bảo',
      'avatar': null,
      'avatarColor': const Color(0xFFFF9800),
      'isOnline': true,
    },
  ];

  // Mock groups data
  final List<Map<String, dynamic>> _mockGroups = [
    {
      'id': 'g_001',
      'name': 'Nhóm Dự Án',
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
      builder: (context, isDark, _) {
        return ValueListenableBuilder(
          valueListenable: localeNotifier,
          builder: (context, locale, _) {
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
        // Blue header with search
        _buildMobileHeader(t, isDark),
        // Tabs: Bạn bè | Nhóm
        _buildMobileTabs(t, isDark),
        // Tab content
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
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: t.get('searchPlaceholder'),
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 18,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildIconBtn(Icons.person_add_outlined, Colors.white, () {}),
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
        unselectedLabelStyle:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        tabs: [
          Tab(text: t.get('friends')),
          Tab(text: t.get('groups')),
        ],
      ),
    );
  }

  Widget _buildFriendListMobile(AppLocalizations t, bool isDark) {
    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.backgroundGray,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Friend request section
          _buildFriendRequestBanner(t, isDark),
          // Filter chips
          _buildFilterChips(t, isDark),
          // Contact list
          ..._mockContacts.map(
            (contact) => _buildContactTile(contact, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupListMobile(AppLocalizations t, bool isDark) {
    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.backgroundGray,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          ..._mockGroups.map(
            (group) => _buildGroupTile(group, t, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendRequestBanner(AppLocalizations t, bool isDark) {
    return Container(
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
          child: const Icon(
            Icons.person_add,
            color: AppColors.primaryBlue,
            size: 20,
          ),
        ),
        title: Text(
          '${t.get('friendRequest')} (4)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.getTextPrimary(isDark),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.getTextSecondary(isDark),
        ),
        onTap: () {},
      ),
    );
  }

  Widget _buildFilterChips(AppLocalizations t, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: Row(
        children: [
          _buildChip(
            '${t.get('allContacts')} ${_mockContacts.length}',
            true,
            isDark,
          ),
          const SizedBox(width: 8),
          _buildChip(t.get('recentAccess'), false, isDark),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark
                ? AppColors.primaryBlue.withValues(alpha: 0.2)
                : AppColors.primaryBlue.withValues(alpha: 0.1))
            : (isDark ? AppColors.darkCard : AppColors.backgroundGray),
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.3), width: 1)
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected
              ? AppColors.primaryBlue
              : AppColors.getTextSecondary(isDark),
        ),
      ),
    );
  }

  Widget _buildContactTile(Map<String, dynamic> contact, bool isDark) {
    return Container(
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: contact['avatarColor'],
          child: Text(
            _getInitials(contact['name']),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(
          contact['name'],
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.getTextPrimary(isDark),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
        onTap: () {},
      ),
    );
  }

  Widget _buildGroupTile(Map<String, dynamic> group, AppLocalizations t, bool isDark) {
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
          // Search header with action icons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        Icon(Icons.search, color: AppColors.getTextSecondary(isDark), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            style: TextStyle(
                              color: AppColors.getTextPrimary(isDark),
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: t.get('searchPlaceholder'),
                              hintStyle: TextStyle(
                                color: AppColors.getTextSecondary(isDark),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildIconBtnSidebar(Icons.person_add_outlined, isDark, () {}),
                _buildIconBtnSidebar(Icons.group_add_outlined, isDark, () {}),
              ],
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w400,
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
                bottom:
                    BorderSide(color: AppColors.getDivider(isDark), width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getContentIcon(),
                  size: 20,
                  color: AppColors.primaryBlue,
                ),
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
        return _buildWideFriendList(t, isDark);
      case 1:
        return _buildWideGroupList(t, isDark);
      case 2:
        return _buildWideFriendRequests(t, isDark);
      case 3:
        return _buildWideGroupInvitations(t, isDark);
      default:
        return _buildWideFriendList(t, isDark);
    }
  }

  Widget _buildWideFriendList(AppLocalizations t, bool isDark) {
    // Group contacts alphabetically
    final sorted = List<Map<String, dynamic>>.from(_mockContacts)
      ..sort(
          (a, b) => (a['name'] as String).compareTo(b['name'] as String));

    String? currentLetter;
    final List<Widget> items = [];

    // Search and filter bar
    items.add(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF242424) : Colors.white,
          border: Border(
            bottom: BorderSide(color: AppColors.getDivider(isDark), width: 1),
          ),
        ),
        child: Row(
          children: [
            // Search field
            Expanded(
              flex: 3,
              child: Container(
                height: 34,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: TextField(
                  style: TextStyle(
                    color: AppColors.getTextPrimary(isDark),
                    fontSize: 14,
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
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Sort dropdown
            Expanded(
              flex: 2,
              child: Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sort,
                      size: 16,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tên (A-Z)',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.getTextPrimary(isDark),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Filter dropdown
            Expanded(
              flex: 2,
              child: Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      size: 16,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tất cả',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.getTextPrimary(isDark),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Friend count header
    items.add(
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          '${t.get('friends')} (${_mockContacts.length})',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.getTextPrimary(isDark),
          ),
        ),
      ),
    );

    // "Bạn mới" section
    items.add(
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          'Bạn mới',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.getTextPrimary(isDark),
          ),
        ),
      ),
    );
    // Mock new friend
    if (sorted.isNotEmpty) {
      items.add(_buildWideContactTile(sorted.first, isDark, isNew: true));
    }

    for (final contact in sorted) {
      final firstLetter = (contact['name'] as String)[0].toUpperCase();
      if (firstLetter != currentLetter) {
        currentLetter = firstLetter;
        items.add(
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              currentLetter,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.getTextSecondary(isDark),
              ),
            ),
          ),
        );
      }
      items.add(_buildWideContactTile(contact, isDark));
    }

    return Container(
      color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
      child: ListView(
        padding: EdgeInsets.zero,
        children: items,
      ),
    );
  }

  Widget _buildWideContactTile(Map<String, dynamic> contact, bool isDark, {bool isNew = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: contact['avatarColor'],
                backgroundImage: contact['avatar'] != null
                    ? NetworkImage(contact['avatar'] as String)
                    : null,
                child: contact['avatar'] == null
                    ? Text(
                        _getInitials(contact['name']),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  contact['name'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.getTextPrimary(isDark),
                  ),
                ),
              ),
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.more_horiz,
                    color: AppColors.getTextSecondary(isDark),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWideGroupList(AppLocalizations t, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _mockGroups
          .map((group) => _buildWideGroupTile(group, t, isDark))
          .toList(),
    );
  }

  Widget _buildWideGroupTile(Map<String, dynamic> group, AppLocalizations t, bool isDark) {
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
          Icon(
            Icons.more_horiz,
            color: AppColors.getTextSecondary(isDark),
            size: 20,
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
            'Khi nào tôi nhận được lời mời?',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.primaryBlue,
            ),
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

  Widget _buildIconBtnSidebar(IconData icon, bool isDark, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: AppColors.getTextSecondary(isDark),
            size: 20,
          ),
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
}
