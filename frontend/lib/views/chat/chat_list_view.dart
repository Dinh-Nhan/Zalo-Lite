import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/features/calling/screens/incoming_call_screen.dart';
import 'package:frontend/features/friends/screens/qr_friend_screen.dart';
import 'package:frontend/models/call_model.dart';
import 'package:frontend/providers/call_provider.dart';
import 'package:flutter_callkeep/flutter_callkeep.dart';
import 'package:frontend/features/calling/screens/call_screen.dart';
import 'package:frontend/services/call_notification_service.dart';
import 'package:frontend/services/message_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/apps/app_locale.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/dark_mode_config.dart';
import 'package:frontend/features/feedback/screens/feedback_screen.dart';
import 'package:frontend/features/friends/friends.dart';
import 'package:frontend/features/friends/screens/contact_main_screen.dart';
import 'package:frontend/models/chat/conversation.dart';
import 'package:frontend/providers/chat_provider.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/utils/app_localizations.dart';
import 'package:frontend/services/chat/chat_service.dart';
import 'package:frontend/views/chat/chat_screen.dart';
import 'package:frontend/views/contacts/contacts_view.dart';
import 'package:frontend/views/settings/settings_dialog.dart';
import 'package:frontend/widgets/search_overlay_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:frontend/views/chat/new_conversation_screen.dart';

/// Man hinh danh sach tin nhan - Thiet ke giong Zalo Web
class ChatListView extends StatefulWidget {
  const ChatListView({super.key});

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  String _filterMode = 'all';
  int _selectedNavIndex = 0;
  Conversation? _selectedConversation;
  bool? _wasWideScreen;

  @override
  void initState() {
    super.initState();
    // Đợi giao diện dựng xong hoàn toàn rồi mới hiển thị Modal
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Giả sử bạn có một biến hoặc hàm check xem có feedback nào cần đánh giá không
    bool hasPendingFeedbackEvaluation = true; // Logic check từ DB/API của bạn
    
    if (hasPendingFeedbackEvaluation) {
      _showFeedbackFlow(context);
    }
  });
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    Future.microtask(() {
      final provider = context.read<FriendProvider>();
      provider.loadFriends();
      provider.loadRequests();
      provider.startRealtime();

      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isNotEmpty) {
        final chatProvider = context.read<ChatProvider>();
        chatProvider.setContext(context);
        chatProvider.init(uid);
      }

      if (mounted) CallNotificationService.checkPendingCall(_handleFcmCall);
      _pollActiveCalls();

      // Điều hướng khi tap notification tin nhắn
      MessageNotificationService.onNotificationTap = _openConversationById;
      MessageNotificationService.checkInitialMessage();
    });

    context.read<CallProvider>().addListener(_onCallStateChanged);
    CallNotificationService.acceptedCall.addListener(_onCallAcceptedNotifier);
    CallNotificationService.declinedCall.addListener(_onCallDeclinedNotifier);
    // Check ngay nếu có event đang chờ
    if (CallNotificationService.acceptedCall.value != null) {
      Future.microtask(_onCallAcceptedNotifier);
    }
  }

  @override
  void dispose() {
    MessageNotificationService.onNotificationTap = null;
    context.read<CallProvider>().removeListener(_onCallStateChanged);
    CallNotificationService.acceptedCall.removeListener(
      _onCallAcceptedNotifier,
    );
    CallNotificationService.declinedCall.removeListener(
      _onCallDeclinedNotifier,
    );
    super.dispose();
  }

  /// Mở conversation từ notification tap — tìm trong danh sách hoặc fetch từ API
  Future<void> _openConversationById(String conversationId) async {
    if (!mounted) return;
    final chatProvider = context.read<ChatProvider>();

    // Tìm trong danh sách đã load
    Conversation? conv = chatProvider.conversations
        .where((c) => c.id == conversationId)
        .firstOrNull;

    // Nếu chưa có, fetch từ API
    conv ??= await chatProvider.fetchConversation(conversationId);
    if (conv == null || !mounted) return;

    chatProvider.openConversation(conv);
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv!)));
  }

  void _onCallStateChanged() {
    final call = context.read<CallProvider>().currentCall;
    if (call != null && call.isIncoming && call.status == CallStatus.ringing) {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => IncomingCallScreen(call: call),
          fullscreenDialog: true,
        ),
      );
    }
  }

  void _setupCallKeepEvents() {
    // Không cần setup thêm — dùng ValueNotifier listeners ở initState
  }

  /// Khi app cold start từ việc nhấn Accept trên CallKeep native UI,
  /// EventChannel đã mất → query activeCalls để lấy cuộc gọi đang active
  bool _coldStartCallHandled = false;

  /// Poll activeCalls vài lần — phòng race giữa native ghi ACTIVE_CALLS và app query
  Future<void> _pollActiveCalls() async {
    for (int i = 0; i < 5; i++) {
      if (!mounted || _coldStartCallHandled) return;
      try {
        final activeCalls = await CallKeep.instance.activeCalls();
        debugPrint(
          '[ChatList] poll[$i] activeCalls count=${activeCalls.length}',
        );
        if (activeCalls.isNotEmpty) {
          _coldStartCallHandled = true;
          final event = activeCalls.first;
          debugPrint(
            '[ChatList] coldstart call: ${event.callerName} extra=${event.extra}',
          );
          await CallKeep.instance.endAllCalls(); // clear để không re-trigger
          if (mounted) _handleCallAccepted(event);
          return;
        }
      } catch (e) {
        debugPrint('[ChatList] _pollActiveCalls error: $e');
      }
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  void _onCallAcceptedNotifier() {
    final event = CallNotificationService.acceptedCall.value;
    debugPrint(
      '[ChatList] _onCallAcceptedNotifier: event=${event?.callerName} mounted=$mounted',
    );
    if (event == null || !mounted) return;
    CallNotificationService.acceptedCall.value = null; // consume
    _handleCallAccepted(event);
  }

  void _onCallDeclinedNotifier() {
    final event = CallNotificationService.declinedCall.value;
    if (event == null || !mounted) return;
    CallNotificationService.declinedCall.value = null;
    _handleCallDeclined(event);
  }

  bool _callScreenOpened = false;

  void _handleCallAccepted(CallEvent event) {
    debugPrint('[ChatList] _handleCallAccepted: extra=${event.extra}');
    if (!mounted || _callScreenOpened) return;
    _callScreenOpened = true;
    _coldStartCallHandled = true;
    final extra = event.extra ?? {};
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final call = CallModel(
      conversationId: extra['conversation_id'] ?? '',
      callerId: extra['caller_id'] ?? '',
      calleeId: currentUid,
      remoteName: extra['caller_name'] ?? event.callerName ?? '',
      remoteAvatar: extra['caller_avatar'] ?? '',
      isVideo: extra['call_type'] == 'video',
      isIncoming: true,
      status: CallStatus.active,
    );

    context.read<CallProvider>().acceptCall();
    context.read<ChatProvider>().acceptCall(call.conversationId, call.callerId);

    Navigator.of(context, rootNavigator: true)
        .push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => CallScreen(call: call),
          ),
        )
        .then((_) {
          // Reset khi CallScreen đóng → cuộc gọi sau hoạt động lại
          _callScreenOpened = false;
          _coldStartCallHandled = false;
        });
  }

  void _handleCallDeclined(CallEvent event) {
    if (!mounted) return;
    final extra = event.extra ?? {};
    final chat = context.read<ChatProvider>();
    chat.rejectCall(
      extra['conversation_id'] ?? '',
      extra['caller_id'] ?? '',
      reason: 'rejected',
    );
    context.read<CallProvider>().rejectCall();
  }

  void _handleFcmCall(Map<String, String> data) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final callModel = CallModel(
      conversationId: data['conversation_id'] ?? '',
      callerId: data['caller_id'] ?? '',
      calleeId: currentUid,
      remoteName: data['caller_name'] ?? '',
      remoteAvatar: data['caller_avatar'] ?? '',
      isVideo: data['call_type'] == 'video',
      isIncoming: true,
      status: CallStatus.ringing,
    );

    context.read<CallProvider>().receiveIncomingCall(callModel);

    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => IncomingCallScreen(call: callModel),
        fullscreenDialog: true,
      ),
    );
  }

  void _onConversationTap(Conversation conversation) {
    context.read<ChatProvider>().openConversation(conversation);
    final isWideScreen = MediaQuery.of(context).size.width >= 700;

    if (isWideScreen) {
      setState(() => _selectedConversation = conversation);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(conversation: conversation),
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
void _showFeedbackFlow(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // Bắt buộc tương tác qua nút bấm trong modal
    builder: (context) => const FeedbackFlowModal(),
  );
}
  void _openAppearanceSettings() {
    SettingsDialog.showAppearance(context);
  }

  Future<void> _logout() async {
    final friendProvider = context.read<FriendProvider>();
    await friendProvider.disposeRealtime();
    friendProvider.clear();
    await AuthService.logout();

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
                                  : ChatScreen(
                                      conversation: _selectedConversation!,
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
                                  : ChatScreen(
                                      conversation: _selectedConversation!,
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
      final Color headerBg = isDark
          ? const Color(0xFF1A1A1A)
          : AppColors.primaryBlue;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: headerBg,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _openSearchOverlay(context),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : Colors.white.withValues(alpha: 0.25),
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
                        child: Text(
                          t.get('searchPlaceholder'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
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
            const SizedBox(width: 8),
            _buildHeaderIconButton(
              Icons.qr_code_scanner,
              isDark,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const QrFriendScreen(),
                  ),
                );
              },
              iconColor: Colors.white,
            ),
            _buildHeaderIconButton(
              Icons.add,
              isDark,
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NewConversationScreen(type: 'group'),
                ),
              ),
              iconColor: Colors.white,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.getSurface(isDark),
      child: Row(
        children: [
          Expanded(
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
          const SizedBox(width: 8),
          _buildHeaderIconButton(Icons.person_add_outlined, isDark, () {}),
          _buildHeaderIconButton(
            Icons.group_add_outlined,
            isDark,
            () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const NewConversationScreen(type: 'group'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openSearchOverlay(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => SearchOverlayScreen(
          onBack: () => Navigator.of(context).pop(),
          onSearchResultTap: ({required userId, required name, avatar}) async {
            Navigator.of(context).pop();
            final chatProvider = context.read<ChatProvider>();
            final conversation = await ChatService().createConversation(
              type: 'private',
              participantIds: [userId],
            );
            if (!context.mounted) return;
            unawaited(chatProvider.openConversation(conversation));
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(conversation: conversation),
              ),
            );
          },
          recentContacts: const [],
          onRecentContactTap: (_) {},
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  Color _avatarColor(String name) {
    final colors = [
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFFE91E63),
      const Color(0xFF00BCD4),
      const Color(0xFF795548),
      const Color(0xFF607D8B),
    ];
    if (name.isEmpty) return colors[0];
    return colors[name.codeUnitAt(0) % colors.length];
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
    return Consumer<ChatProvider>(
      builder: (context, chat, _) {
        if (chat.conversationsState == ChatLoadingState.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (chat.conversationsState == ChatLoadingState.error) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    'Không thể tải cuộc trò chuyện',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (chat.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      chat.errorMessage!,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.getTextSecondary(isDark),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => chat.loadConversations(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        final list = _filterMode == 'unread'
            ? chat.conversations.where((c) => c.unreadCount > 0).toList()
            : chat.conversations;

        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: AppColors.getTextSecondary(
                    isDark,
                  ).withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có cuộc trò chuyện nào',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getTextSecondary(isDark),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tìm kiếm bạn bè để bắt đầu nhắn tin',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.getTextSecondary(
                      isDark,
                    ).withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primaryBlue,
          onRefresh: () => chat.loadConversations(),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: list.length,
            itemBuilder: (context, index) =>
                _buildConversationTileFromModel(list[index], t, isDark),
          ),
        );
      },
    );
  }

  String _formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút';
    if (diff.inHours < 24)
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff.inDays == 1) return 'Hôm qua';
    if (diff.inDays < 7) return '${dt.day}/${dt.month}';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatLastMessage(Conversation conv) {
    final msg = conv.lastMessage;
    if (msg == null) return '';

    final String prefix;
    if (msg.isMine) {
      prefix = 'Bạn';
    } else {
      // Ưu tiên dùng tên từ conversation (đúng hơn senderName trong message)
      final resolvedName = conv.type == 'private'
          ? (conv.otherUserName ?? msg.senderName)
          : msg.senderName;
      final parts = resolvedName.trim().split(' ');
      // Lấy từ CUỐI (tên người Việt thường là tên riêng ở cuối)
      prefix = parts.isNotEmpty ? parts.last : resolvedName;
    }

    final String content;
    if (msg.isDeleted) {
      content = 'Tin nhắn đã bị thu hồi';
    } else {
      switch (msg.type) {
        case 'image':
          content = '[Hình ảnh]';
          break;
        case 'video':
          content = '[Video]';
          break;
        case 'audio':
          content = '[Tin nhắn thoại]';
          break;
        case 'file':
          content = '[Tệp: ${msg.fileName ?? 'đính kèm'}]';
          break;
        case 'sticker':
          content = '[Sticker]';
          break;
        default:
          content = msg.content;
      }
    }

    return '$prefix: $content';
  }

  Widget _buildConversationTileFromModel(
    Conversation conv,
    AppLocalizations t,
    bool isDark,
  ) {
    final String name = conv.displayName;
    final Color avatarColor = _avatarColor(name);
    final String lastMessage = _formatLastMessage(conv);
    final int unreadCount = conv.unreadCount;
    final bool isGroup = conv.type == 'group';
    final int memberCount = conv.participants.length;
    final String lastMessageTime = _formatRelativeTime(
      conv.lastMessage?.createdAt ?? conv.updatedAt,
    );

    final isOnline = !isGroup && conv.otherUserId != null &&
        context.read<ChatProvider>().isUserOnline(conv.otherUserId!);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onConversationTap(conv),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Avatar stack
              SizedBox(
                width: 52, height: 52,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    conv.displayAvatar.isNotEmpty
                        ? CircleAvatar(radius: 26, backgroundImage: NetworkImage(conv.displayAvatar))
                        : CircleAvatar(
                            radius: 26,
                            backgroundColor: avatarColor,
                            child: Text(_getInitials(name), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17)),
                          ),
                    // Group member count badge
                    if (isGroup)
                      Positioned(
                        right: -2, bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8C00),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.getSurface(isDark), width: 1.5),
                          ),
                          child: Text(memberCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    // Online dot
                    if (isOnline)
                      Positioned(
                        right: 1, bottom: 1,
                        child: Container(
                          width: 13, height: 13,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00CC44),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.getSurface(isDark), width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Text content
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
                              fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
                              color: AppColors.getTextPrimary(isDark),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          lastMessageTime,
                          style: TextStyle(
                            fontSize: 11,
                            color: unreadCount > 0 ? AppColors.primaryBlue : AppColors.getTextSecondary(isDark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                              color: unreadCount > 0
                                  ? AppColors.getTextPrimary(isDark)
                                  : AppColors.getTextSecondary(isDark),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(minWidth: 20),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
            if (trailing != null) trailing,
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
              // const ContactsView(isWideScreen: false),
              ContactsMainScreen(),
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
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.getDivider(isDark), width: 0.5),
        ),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _buildBottomNavItem(Icons.chat_bubble, Icons.chat_bubble_outline, 0, 'Tin nhắn', isDark),
              _buildBottomNavItem(Icons.contacts, Icons.contacts_outlined, 1, 'Danh bạ', isDark),
              _buildBottomNavItem(Icons.auto_stories, Icons.auto_stories_outlined, 2, 'Khám phá', isDark),
              _buildBottomNavItem(Icons.person, Icons.person_outline, 3, 'Cá nhân', isDark),
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
    String label,
    bool isDark,
  ) {
    final isSelected = _selectedNavIndex == index;
    final color = isSelected ? AppColors.primaryBlue : AppColors.getTextSecondary(isDark);
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedNavIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? activeIcon : inactiveIcon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
          ],
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
