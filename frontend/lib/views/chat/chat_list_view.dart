import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/app/app_locale.dart';
import 'package:frontend/common/widget/bottom_nav.dart';
import 'package:frontend/common/widget/chat_list_panel.dart';
import 'package:frontend/common/widget/conversation_detail_panel.dart';
import 'package:frontend/common/widget/sidebar.dart';
import 'package:frontend/controller/user_controller.dart';
import 'package:frontend/utils/app_localizations.dart';
import 'package:frontend/common/config/dark_mode_config.dart';
import 'package:frontend/utils/constant.dart';
import 'package:frontend/views/settings/settings_dialog.dart';
import 'package:frontend/views/chat/chat_detail_view.dart';
import 'package:frontend/common/config/app_colors.dart';
import 'package:frontend/views/contacts/contacts_view.dart';
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
  final UserController userController = UserController();
  
  List<Map<String, dynamic>> _mockConversations = AppConstant.dataConversations;

  @override
  void initState() {
    super.initState();
    print("LOAD USERS CALLED");
    //Mock data thật
    userController.loadUsers();
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

  void _openAppearanceSettings() {
    SettingsDialog.showAppearance(context);
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
                    if (_wasWideScreen != null && _wasWideScreen != isWideScreen) {
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
                            _selectedConversation = null;
                          });
                        }
                      });
                    }
                    _wasWideScreen = isWideScreen;
                    
                    if (isWideScreen) {
                      return Row(
                        children: [
                          // _buildSidebar(isDark),
                          Sidebar(
                            isDark: isDark,
                            selectedIndex: _selectedNavIndex,
                            onItemSelected: (index) {
                              setState(() {
                                _selectedNavIndex = index;
                                _selectedConversation = null;
                              });
                            },
                            onOpenSettings: () {
                              SettingsDialog.show(context);
                            },
                          ),
                          if (_selectedNavIndex == 0) ...[
                            ChatListPanel(
                              isWide: true, // hoặc false
                              isDark: isDark,
                              t: t,
                              controller: _searchController,
                              onSearchChanged: _onSearchChanged,
                              conversations: _filteredConversations,
                              onTap: _onConversationTap,
                              filterMode: _filterMode,
                              onFilterChanged: (v) => setState(() => _filterMode = v),
                            ),
                            Expanded(
                              child: ConversationDetailPanel(
                                conversation: _selectedConversation,
                                isDark: isDark,
                                t: t,
                                onOpenAppearance: _openAppearanceSettings,
                              ),
                            ),
                          ] else if (_selectedNavIndex == 2)
                            const Expanded(
                              child: ContactsView(isWideScreen: true),
                            )
                          else ...[
                            // Default to chat panel for any other index
                            ChatListPanel(
                              isWide: true, // hoặc false
                              isDark: isDark,
                              t: t,
                              controller: _searchController,
                              onSearchChanged: _onSearchChanged,
                              conversations: _filteredConversations,
                              onTap: _onConversationTap,
                              filterMode: _filterMode,
                              onFilterChanged: (v) => setState(() => _filterMode = v),
                            ),
                            Expanded(
                              child: ConversationDetailPanel(
                                conversation: _selectedConversation,
                                isDark: isDark,
                                t: t,
                                onOpenAppearance: _openAppearanceSettings,
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
  /// Mobile view with bottom navigation switching between tabs
  Widget _buildMobileView(AppLocalizations t, bool isDark) {
    return Column(
      children: [
        Expanded(
          child: IndexedStack(
            index: _selectedNavIndex,
            children: [
              // Tab 0: Chat List
              ChatListPanel(
                isWide: false, // hoặc false
                isDark: isDark,
                t: t,
                controller: _searchController,
                onSearchChanged: _onSearchChanged,
                conversations: _filteredConversations,
                onTap: _onConversationTap,
                filterMode: _filterMode,
                onFilterChanged: (v) => setState(() => _filterMode = v),
              ),
              // Tab 1: Contacts
              const ContactsView(isWideScreen: false),
              // Tab 2: Discover (placeholder)
              _buildPlaceholderTab(t.get('discover'), Icons.explore_outlined, isDark),
              // Tab 3: Profile (placeholder)
              _buildPlaceholderTab(t.get('profile'), Icons.person_outline, isDark),
            ],
          ),
        ),
        // _buildBottomNavigation(isDark),
        BottomNavigation(
          isDark: isDark,
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) {
            setState(() => _selectedNavIndex = index);
          },
        ),
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
                color: AppColors.getTextSecondary(isDark).withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}