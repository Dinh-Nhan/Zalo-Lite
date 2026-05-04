import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/apps/app_locale.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/dark_mode_config.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/utils/app_localizations.dart';
import 'package:frontend/views/chat/chat_detail_view.dart';
import 'package:frontend/views/contacts/contacts_view.dart';
import 'package:frontend/views/settings/settings_dialog.dart';
import 'package:go_router/go_router.dart';

/// Man hinh danh sach tin nhan - Thiet ke giong Zalo Web
class ChatListView extends StatefulWidget {
  const ChatListView({super.key});

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterMode = 'all';
  int _selectedNavIndex = 0;
  Map<String, dynamic>? _selectedConversation;
  bool? _wasWideScreen; // Track previous screen size

  final List<Map<String, dynamic>> _mockConversations = [
    {
      'id': 'conv_001',
      'name': 'Đình Nhân',
      'avatar': null,
      'avatarColor': const Color(0xFF4CAF50),
      'lastMessageKey': 'youPrefix',
      'lastMessageContent': 'Nice to meet you',
      'lastMessageTimeValue': 5,
      'lastMessageTimeUnit': 'minutes',
      'unreadCount': 0,
      'isPinned': false,
      'isGroup': false,
    },
    {
      'id': 'conv_002',
      'name': 'Nhóm Dự Án',
      'avatar': null,
      'avatarColor': const Color(0xFF9C27B0),
      'lastMessageKey': 'youPrefix',
      'lastMessageContent': 'Nice to meet you',
      'lastMessageTimeValue': 10,
      'lastMessageTimeUnit': 'minutes',
      'unreadCount': 3,
      'isPinned': false,
      'isGroup': true,
      'memberCount': 5,
    },
    {
      'id': 'conv_003',
      'name': 'Minh Anh',
      'avatar': null,
      'avatarColor': const Color(0xFF2196F3),
      'lastMessageKey': '',
      'lastMessageContent': 'Chào bạn!',
      'lastMessageTimeValue': 30,
      'lastMessageTimeUnit': 'minutes',
      'unreadCount': 0,
      'isPinned': false,
      'isGroup': false,
    },
    {
      'id': 'conv_004',
      'name': 'Nhóm Lớp K18',
      'avatar': null,
      'avatarColor': const Color(0xFFFF9800),
      'lastMessageKey': '',
      'lastMessageContent': 'Ai có tài liệu không?',
      'lastMessageTimeValue': 1,
      'lastMessageTimeUnit': 'hours',
      'unreadCount': 12,
      'isPinned': false,
      'isGroup': true,
      'memberCount': 45,
    },
    {
      'id': 'conv_005',
      'name': 'Tuấn Kiệt',
      'avatar': null,
      'avatarColor': const Color(0xFFE91E63),
      'lastMessageKey': 'youPrefix',
      'lastMessageContent': 'Ok bạn',
      'lastMessageTimeValue': 2,
      'lastMessageTimeUnit': 'hours',
      'unreadCount': 0,
      'isPinned': false,
      'isGroup': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredConversations {
    var list = _mockConversations;
    if (_filterMode == 'unread') {
      list = list.where((conv) => conv['unreadCount'] > 0).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list
          .where(
            (conv) =>
                conv['name'].toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
    return list;
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
  }

  void _onConversationTap(Map<String, dynamic> conversation) {
    // Check if we're on wide screen
    final isWideScreen = MediaQuery.of(context).size.width >= 700;

    if (isWideScreen) {
      // On wide screen, update selected conversation to show in right panel
      setState(() {
        _selectedConversation = conversation;
      });
    } else {
      // On mobile, navigate to full screen chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailView(
            conversationId: conversation['id'],
            contactName: conversation['name'],
            avatarColor: conversation['avatarColor'],
            isGroup: conversation['isGroup'] ?? false,
            memberCount: conversation['memberCount'],
          ),
        ),
      );
    }
  }

  void _openSettings() {
  SettingsDialog.show(
    context,
    onLogout: () async {
      await _logout();
    },
  );
}

  void _openAppearanceSettings() {
    SettingsDialog.showAppearance(context);
  }

  Future<void> _logout() async {
     print("LOGOUT CLICKED");
  await AuthService.logout();
  print("LOGOUT DONE");

  if (!mounted) return;
  context.go('/');

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
            return Scaffold(
              backgroundColor: AppColors.getBackground(isDark),
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWideScreen = constraints.maxWidth >= 700;

                    // Convert index when screen size changes
                    if (_wasWideScreen != null &&
                        _wasWideScreen != isWideScreen) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (isWideScreen) {
                          // Mobile → Wide conversion
                          setState(() {
                            if (_selectedNavIndex == 0) {
                              _selectedNavIndex = 0; // Chat → Chat
                            } else if (_selectedNavIndex == 1) {
                              _selectedNavIndex = 2; // Contacts → Contacts
                            } else {
                              _selectedNavIndex = 0; // Discover/Profile → Chat
                            }
                            // Keep selected conversation when switching to wide
                            _selectedConversation = _selectedConversation;
                          });
                        } else {
                          // Wide → Mobile conversion
                          setState(() {
                            if (_selectedNavIndex == 0) {
                              _selectedNavIndex = 0; // Chat → Chat
                            } else if (_selectedNavIndex == 2) {
                              _selectedNavIndex = 1; // Contacts → Contacts
                            } else {
                              _selectedNavIndex = 0; // Settings → Chat
                            }
                            // Clear selected conversation when switching to mobile
                            // because mobile uses full-screen navigation
                            _selectedConversation = null;
                          });
                        }
                      });
                    }
                    _wasWideScreen = isWideScreen;

                    if (isWideScreen) {
                      return Row(
                        children: [
                          _buildSidebar(isDark),
                          if (_selectedNavIndex == 0) ...[
                            _buildChatListPanelWide(t, isDark),
                            Expanded(
                              child: _selectedConversation == null
                                  ? _buildWelcomePanel(t, isDark)
                                  : ChatDetailView(
                                      conversationId:
                                          _selectedConversation!['id'],
                                      contactName:
                                          _selectedConversation!['name'],
                                      avatarColor:
                                          _selectedConversation!['avatarColor'],
                                      isGroup:
                                          _selectedConversation!['isGroup'] ??
                                          false,
                                      memberCount:
                                          _selectedConversation!['memberCount'],
                                      showBackButton: false,
                                    ),
                            ),
                          ] else if (_selectedNavIndex == 2)
                            const Expanded(
                              child: ContactsView(isWideScreen: true),
                            )
                          else ...[
                            // Default to chat panel for any other index
                            _buildChatListPanelWide(t, isDark),
                            Expanded(
                              child: _selectedConversation == null
                                  ? _buildWelcomePanel(t, isDark)
                                  : ChatDetailView(
                                      conversationId:
                                          _selectedConversation!['id'],
                                      contactName:
                                          _selectedConversation!['name'],
                                      avatarColor:
                                          _selectedConversation!['avatarColor'],
                                      isGroup:
                                          _selectedConversation!['isGroup'] ??
                                          false,
                                      memberCount:
                                          _selectedConversation!['memberCount'],
                                      showBackButton: false,
                                    ),
                            ),
                          ],
                        ],
                      );
                    } else {
                      return _buildMobileView(t, isDark);
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSidebar(bool isDark) {
    return Container(
      width: 64,
      color: isDark ? const Color(0xFF1A1A1A) : AppColors.sidebarDark,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const CircleAvatar(
              backgroundColor: Color(0xFF4CAF50),
              child: Text(
                'U',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSidebarItem(Icons.chat_bubble, 0, isDark),
          _buildSidebarItem(Icons.contacts_outlined, 2, isDark),
          const Spacer(),
          _buildSidebarItem(Icons.settings_outlined, 1, isDark),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, int index, bool isDark) {
    final isSelected = _selectedNavIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          onPressed: () {
            if (index == 1) {
              SettingsDialog.show(
                context,
                onLogout: () async {
                  await _logout();
                },
              );
            } else {
              setState(() {
                _selectedNavIndex = index;
                _selectedConversation = null;
              });
            }
          },
          icon: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildChatListPanel(AppLocalizations t, bool isDark) {
    return Column(
      children: [
        _buildSearchHeader(t, isDark, isMobile: true),
        Expanded(child: _buildConversationList(t, isDark)),
      ],
    );
  }

  Widget _buildChatListPanelWide(AppLocalizations t, bool isDark) {
    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        border: Border(
          right: BorderSide(color: AppColors.getDivider(isDark), width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildSearchHeader(t, isDark, isMobile: false),
          _buildFilterTabs(t, isDark),
          Expanded(child: _buildConversationList(t, isDark)),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(
    AppLocalizations t,
    bool isDark, {
    bool isMobile = false,
  }) {
    if (isMobile) {
      // Mobile: blue background (dark mode: black) with white search bar and white icons
      final Color mobileHeaderBg = isDark
          ? const Color(0xFF1A1A1A)
          : AppColors.primaryBlue;
      final searchBg = isDark
          ? const Color(0xFF2A2A2A)
          : Colors.white.withValues(alpha: 0.25);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: mobileHeaderBg,
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: searchBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(
                      Icons.search,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: t.get('searchPlaceholder'),
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
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
            _buildHeaderIconButton(
              Icons.qr_code_scanner,
              isDark,
              () {},
              iconColor: Colors.white,
            ),
            _buildHeaderIconButton(
              Icons.add,
              isDark,
              () {},
              iconColor: Colors.white,
            ),
          ],
        ),
      );
    }

    // Wide screen: keep original white/dark style
    final searchBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.getSurface(isDark),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: searchBg,
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
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
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
          _buildHeaderIconButton(Icons.person_add_outlined, isDark, () {}),
          _buildHeaderIconButton(Icons.group_add_outlined, isDark, () {}),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton(
    IconData icon,
    bool isDark,
    VoidCallback onTap, {
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: iconColor ?? AppColors.getTextSecondary(isDark),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs(AppLocalizations t, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: AppColors.getSurface(isDark),
      child: Row(
        children: [
          _buildFilterTab(t.get('all'), 'all', isDark),
          const SizedBox(width: 16),
          _buildFilterTab(t.get('unread'), 'unread', isDark),
          const Spacer(),
          PopupMenuButton<String>(
            offset: const Offset(0, 30),
            child: Row(
              children: [
                Text(
                  t.get('category'),
                  style: TextStyle(
                    color: AppColors.getTextSecondary(isDark),
                    fontSize: 13,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.getTextSecondary(isDark),
                  size: 18,
                ),
              ],
            ),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'all', child: Text(t.get('all'))),
              PopupMenuItem(value: 'friends', child: Text(t.get('friends'))),
              PopupMenuItem(value: 'groups', child: Text(t.get('groups'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String mode, bool isDark) {
    final isSelected = _filterMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _filterMode = mode),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected
              ? AppColors.primaryBlue
              : AppColors.getTextSecondary(isDark),
        ),
      ),
    );
  }

  Widget _buildConversationList(AppLocalizations t, bool isDark) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _filteredConversations.length,
      itemBuilder: (context, index) {
        final conversation = _filteredConversations[index];
        return _buildConversationTile(conversation, t, isDark);
      },
    );
  }

  String _formatTimeAgo(int value, String unit, AppLocalizations t) {
    if (unit == 'minutes') {
      return t.isVietnamese ? '$value phút' : '$value min';
    } else if (unit == 'hours') {
      return t.isVietnamese ? '$value giờ' : '$value hr';
    } else if (unit == 'days') {
      return t.isVietnamese ? '$value ngày' : '$value d';
    }
    return '';
  }

  Widget _buildConversationTile(
    Map<String, dynamic> conversation,
    AppLocalizations t,
    bool isDark,
  ) {
    final String name = conversation['name'];
    final Color avatarColor = conversation['avatarColor'];
    final String messageKey = conversation['lastMessageKey'] ?? '';
    final String messageContent = conversation['lastMessageContent'] ?? '';
    final int timeValue = conversation['lastMessageTimeValue'] ?? 0;
    final String timeUnit = conversation['lastMessageTimeUnit'] ?? '';
    final int unreadCount = conversation['unreadCount'];
    final bool isGroup = conversation['isGroup'] ?? false;
    final int? memberCount = conversation['memberCount'];

    // Format message with localization
    final String lastMessage = messageKey.isNotEmpty
        ? '${t.get(messageKey)} $messageContent'
        : messageContent;
    final String lastMessageTime = _formatTimeAgo(timeValue, timeUnit, t);

    return InkWell(
      onTap: () => _onConversationTap(conversation),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: avatarColor,
                  child: Text(
                    _getInitials(name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isGroup && memberCount != null)
                  Positioned(
                    left: -4,
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.getSurface(isDark),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        memberCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: AppColors.getTextPrimary(isDark),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lastMessageTime.isNotEmpty)
                        Text(
                          lastMessageTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.getTextSecondary(isDark),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsPanel(AppLocalizations t, bool isDark) {
    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.backgroundGray,
      child: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.getSurface(isDark),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.get('settings'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextPrimary(isDark),
                ),
              ),
              const SizedBox(height: 24),
              _buildSettingsItem(
                icon: isDark ? Icons.light_mode : Icons.dark_mode,
                title: t.get('darkMode'),
                subtitle: isDark ? t.get('darkModeOn') : t.get('darkModeOff'),
                isDark: isDark,
                trailing: Switch(
                  value: isDark,
                  onChanged: (value) => isDarkModeNotifier.value = value,
                  activeThumbColor: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 16),
              _buildSettingsItem(
                icon: Icons.language,
                title: t.get('language'),
                subtitle: AppLocalizations(localeNotifier.value).displayName,
                isDark: isDark,
                onTap: () => _showLanguageDialog(t, isDark),
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppColors.getTextSecondary(isDark),
                ),
              ),
              const SizedBox(height: 16),
              _buildSettingsItem(
                icon: Icons.logout,
                title: t.get('logout'),
                subtitle: t.get('logoutSubtitle'),
                isDark: isDark,
                onTap: () async {
                  await _logout();
                },
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppColors.getTextSecondary(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.backgroundGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primaryBlue, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.getTextPrimary(isDark),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(AppLocalizations t, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getSurface(isDark),
        title: Text(
          t.get('selectLanguage'),
          style: TextStyle(color: AppColors.getTextPrimary(isDark)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLocalizations.supportedLanguages.map((lang) {
            final isSelected =
                AppLocalizations(localeNotifier.value).displayName == lang;
            return ListTile(
              title: Text(
                lang,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primaryBlue
                      : AppColors.getTextPrimary(isDark),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: AppColors.primaryBlue)
                  : null,
              onTap: () {
                localeNotifier.value = AppLocalizations.localeFromDisplayName(
                  lang,
                );
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildWelcomePanel(AppLocalizations t, bool isDark) {
    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.backgroundGray,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              t.get('welcomeTitle'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimary(isDark),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                t.get('welcomeDescription'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.getTextSecondary(isDark),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: 320,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.getSurface(isDark),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A1A2E), Color(0xFF2D2D44)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.dark_mode,
                                size: 48,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Dark Mode',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 16,
                          top: 16,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.nightlight_round,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.get('darkModeTitle'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.get('darkModeDescription'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _openAppearanceSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      t.get('tryNow'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mobile view with bottom navigation switching between tabs
  Widget _buildMobileView(AppLocalizations t, bool isDark) {
    return Column(
      children: [
        Expanded(
          child: IndexedStack(
            index: _selectedNavIndex,
            children: [
              // Tab 0: Chat List
              _buildChatListPanel(t, isDark),
              // Tab 1: Contacts
              const ContactsView(isWideScreen: false),
              // Tab 2: Discover (placeholder)
              _buildPlaceholderTab(
                t.get('discover'),
                Icons.explore_outlined,
                isDark,
              ),
              // Tab 3: Profile (placeholder)
              _buildPlaceholderTab(
                t.get('profile'),
                Icons.person_outline,
                isDark,
              ),
            ],
          ),
        ),
        _buildBottomNavigation(isDark),
      ],
    );
  }

  Widget _buildPlaceholderTab(String title, IconData icon, bool isDark) {
    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.backgroundGray,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.getTextSecondary(isDark).withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextSecondary(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon...',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.getTextSecondary(
                  isDark,
                ).withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : AppColors.getSurface(isDark),
        border: Border(
          top: BorderSide(color: AppColors.getDivider(isDark), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                Icons.chat_bubble,
                Icons.chat_bubble_outline,
                0,
                isDark,
              ),
              _buildBottomNavItem(
                Icons.contacts,
                Icons.contacts_outlined,
                1,
                isDark,
              ),
              _buildBottomNavItem(
                Icons.auto_stories,
                Icons.auto_stories_outlined,
                2,
                isDark,
              ),
              _buildBottomNavItem(
                Icons.person,
                Icons.person_outline,
                3,
                isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
    IconData activeIcon,
    IconData inactiveIcon,
    int index,
    bool isDark,
  ) {
    final isSelected = _selectedNavIndex == index;
    return IconButton(
      onPressed: () {
        setState(() => _selectedNavIndex = index);
      },
      icon: Icon(
        isSelected ? activeIcon : inactiveIcon,
        color: isSelected
            ? AppColors.primaryBlue
            : AppColors.getTextSecondary(isDark),
        size: 26,
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
