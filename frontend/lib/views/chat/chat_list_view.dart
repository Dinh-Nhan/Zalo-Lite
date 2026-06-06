import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_callkeep/flutter_callkeep.dart';
import 'package:frontend/apps/app_locale.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/dark_mode_config.dart';
import 'package:frontend/features/calling/screens/call_screen.dart';
import 'package:frontend/features/calling/screens/incoming_call_screen.dart';
import 'package:frontend/features/feedback/screens/feedback_screen.dart';
import 'package:frontend/features/friends/friends.dart';
import 'package:frontend/features/friends/screens/contact_main_screen.dart';
import 'package:frontend/features/newfeed/screens/newfeed_screen.dart';
import 'package:frontend/features/profile/screens/profile_screen.dart';
import 'package:frontend/models/call_model.dart';
import 'package:frontend/models/chat/conversation.dart';
import 'package:frontend/providers/call_provider.dart';
import 'package:frontend/providers/chat_provider.dart';
import 'package:frontend/services/call_notification_service.dart';
import 'package:frontend/services/message_notification_service.dart';
import 'package:frontend/utils/app_localizations.dart';
import 'package:frontend/views/chat/chat_screen.dart';
import 'package:frontend/views/chat/new_conversation_screen.dart';
import 'package:frontend/views/contacts/contacts_view.dart';
import 'package:frontend/widgets/search_overlay_screen.dart';
import 'package:frontend/component/friend_search_page.dart';
import 'package:provider/provider.dart';

class ChatListView extends StatefulWidget {
  const ChatListView({super.key});

  @override
  State<ChatListView> createState() => ChatListViewState();
}

class ChatListViewState extends State<ChatListView> {
  String _filterMode = 'all';
  int _selectedNavIndex = 0;
  Conversation? _selectedConversation;
  bool? _wasWideScreen;
  bool _coldStartCallHandled = false;
  bool _callScreenOpened = false;

  void switchTab(int index) {
    setState(() => _selectedNavIndex = index);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      const hasPendingFeedbackEvaluation = true;
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
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      final provider = context.read<FriendProvider>();
      if (uid.isNotEmpty) {
        provider.setCurrentUid(uid); // set uid + loadAll()
      } else {
        provider.loadAll();
      }
      provider.startRealtime();

      if (uid.isNotEmpty) {
        final chatProvider = context.read<ChatProvider>();
        chatProvider.setContext(context);
        chatProvider.init(uid);
      }

      if (mounted) CallNotificationService.checkPendingCall(_handleFcmCall);
      _pollActiveCalls();
      MessageNotificationService.onNotificationTap = _openConversationById;
      MessageNotificationService.checkInitialMessage();
    });

    context.read<CallProvider>().addListener(_onCallStateChanged);
    CallNotificationService.acceptedCall.addListener(_onCallAcceptedNotifier);
    CallNotificationService.declinedCall.addListener(_onCallDeclinedNotifier);
    if (CallNotificationService.acceptedCall.value != null) {
      Future.microtask(_onCallAcceptedNotifier);
    }
  }

  @override
  void dispose() {
    MessageNotificationService.onNotificationTap = null;
    context.read<CallProvider>().removeListener(_onCallStateChanged);
    CallNotificationService.acceptedCall.removeListener(_onCallAcceptedNotifier);
    CallNotificationService.declinedCall.removeListener(_onCallDeclinedNotifier);
    super.dispose();
  }

  Future<void> _openConversationById(String conversationId) async {
    if (!mounted) return;
    final chatProvider = context.read<ChatProvider>();
    Conversation? conv = chatProvider.conversations.where((c) => c.id == conversationId).firstOrNull;
    conv ??= await chatProvider.fetchConversation(conversationId);
    if (conv == null || !mounted) return;
    await chatProvider.openConversation(conv);
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv!)));
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

  Future<void> _pollActiveCalls() async {
    for (int i = 0; i < 5; i++) {
      if (!mounted || _coldStartCallHandled) return;
      try {
        final activeCalls = await CallKeep.instance.activeCalls();
        if (activeCalls.isNotEmpty) {
          _coldStartCallHandled = true;
          final event = activeCalls.first;
          await CallKeep.instance.endAllCalls();
          if (mounted) _handleCallAccepted(event);
          return;
        }
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  void _onCallAcceptedNotifier() {
    final event = CallNotificationService.acceptedCall.value;
    if (event == null || !mounted) return;
    CallNotificationService.acceptedCall.value = null;
    _handleCallAccepted(event);
  }

  void _onCallDeclinedNotifier() {
    final event = CallNotificationService.declinedCall.value;
    if (event == null || !mounted) return;
    CallNotificationService.declinedCall.value = null;
    _handleCallDeclined(event);
  }

  void _handleCallAccepted(CallEvent event) {
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
          _callScreenOpened = false;
          _coldStartCallHandled = false;
        });
  }

  void _handleCallDeclined(CallEvent event) {
    if (!mounted) return;
    final extra = event.extra ?? {};
    final chat = context.read<ChatProvider>();
    chat.rejectCall(extra['conversation_id'] ?? '', extra['caller_id'] ?? '', reason: 'rejected');
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
        MaterialPageRoute(builder: (_) => ChatScreen(conversation: conversation)),
      );
    }
  }

  void _showFeedbackFlow(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const FeedbackFlowModal(),
    );
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
                    if (_wasWideScreen != null && _wasWideScreen != isWideScreen) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!isWideScreen) {
                          setState(() => _selectedConversation = null);
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
                                  : ChatScreen(conversation: _selectedConversation!),
                            ),
                          ] else if (_selectedNavIndex == 1)
                            const Expanded(child: ContactsView(isWideScreen: true))
                          else if (_selectedNavIndex == 2)
                            const Expanded(child: NewfeedScreen())
                          else if (_selectedNavIndex == 3)
                            const Expanded(child: ProfileScreen())
                          else ...[
                            _buildChatListPanelWide(t, isDark),
                            Expanded(
                              child: _selectedConversation == null
                                  ? _buildWelcomePanel(t, isDark)
                                  : ChatScreen(conversation: _selectedConversation!),
                            ),
                          ],
                        ],
                      );
                    }
                    return _buildMobileView(t, isDark);
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
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
            ),
            child: const CircleAvatar(
              backgroundColor: Color(0xFF4CAF50),
              child: Text('U', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
          _buildSidebarItem(Icons.chat_bubble, 0, isDark),
          _buildSidebarItem(Icons.contacts_outlined, 1, isDark),
          _buildSidebarItem(Icons.auto_stories, 2, isDark),
          _buildSidebarItem(Icons.person_outline, 3, isDark),
          const Spacer(),
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
          color: isSelected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          onPressed: () {
            setState(() {
              _selectedNavIndex = index;
              _selectedConversation = null;
            });
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
        border: Border(right: BorderSide(color: AppColors.getDivider(isDark), width: 1)),
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

  Widget _buildSearchHeader(AppLocalizations t, bool isDark, {bool isMobile = false}) {
    if (isMobile) {
      final headerBg = isDark ? const Color(0xFF1A1A1A) : AppColors.primaryBlue;
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
                    color: isDark ? const Color(0xFF2A2A2A) : Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      Icon(Icons.search, color: Colors.white.withValues(alpha: 0.8), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t.get('searchPlaceholder'),
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 14),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildHeaderIconButton(Icons.qr_code_scanner, isDark, () {}, iconColor: Colors.white),
            _buildHeaderIconButton(
              Icons.add,
              isDark,
              () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NewConversationScreen(type: 'group')),
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
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(Icons.search, color: AppColors.getTextSecondary(isDark), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t.get('searchPlaceholder'),
                        style: TextStyle(color: AppColors.getTextSecondary(isDark), fontSize: 14),
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
              MaterialPageRoute(builder: (_) => const NewConversationScreen(type: 'group')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton(IconData icon, bool isDark, VoidCallback onTap, {Color? iconColor}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: iconColor ?? AppColors.getTextSecondary(isDark), size: 20),
        ),
      ),
    );
  }

  void _openSearchOverlay(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => const FriendSearchPage(),
      ),
    );
  }

  Widget _buildFilterTabs(AppLocalizations t, bool isDark) {
    return Container(
      color: AppColors.getSurface(isDark),
      height: 44,
      child: Row(
        children: [
          _buildFilterTab(t.get('all'), 'all', isDark),
          _buildFilterTab(t.get('unread'), 'unread', isDark),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String value, bool isDark) {
    final isSelected = _filterMode == value;
    return GestureDetector(
      onTap: () => setState(() => _filterMode = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primaryBlue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppColors.primaryBlue : AppColors.getTextSecondary(isDark),
          ),
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
                  const Text('Không thể tải cuộc trò chuyện', style: TextStyle(fontWeight: FontWeight.w600)),
                  if (chat.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      chat.errorMessage!,
                      style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(isDark)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextButton(onPressed: () => chat.loadConversations(), child: const Text('Thử lại')),
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
                  color: AppColors.getTextSecondary(isDark).withValues(alpha: 0.4),
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
                    color: AppColors.getTextSecondary(isDark).withValues(alpha: 0.7),
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
            itemBuilder: (context, index) {
              final conversation = list[index];
              return _buildConversationTileModel(conversation, t, isDark);
            },
          ),
        );
      },
    );
  }

  Widget _buildConversationTileModel(Conversation conversation, AppLocalizations t, bool isDark) {
    final name = conversation.displayName;
    final lastMessage = conversation.lastMessage?.content ?? '';
    final unreadCount = conversation.unreadCount;
    final isGroup = conversation.type == 'group';
    final memberCount = conversation.participants.length;
    final isSelected = _selectedConversation?.id == conversation.id;

    return InkWell(
      onTap: () => _onConversationTap(conversation),
      child: Container(
        color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.08) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: conversation.displayAvatar.isNotEmpty
                      ? NetworkImage(conversation.displayAvatar)
                      : null,
                  backgroundColor: const Color(0xFF4CAF50),
                  child: conversation.displayAvatar.isEmpty
                      ? Text(
                          _getInitials(name),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
                if (isGroup)
                  Positioned(
                    left: -4,
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.getSurface(isDark), width: 2),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.w500,
                            color: AppColors.getTextPrimary(isDark),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatConversationTime(conversation.updatedAt, t),
                        style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(isDark)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage.isEmpty ? 'Chưa có tin nhắn nào' : lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: unreadCount > 0 ? AppColors.getTextPrimary(isDark) : AppColors.getTextSecondary(isDark),
                            fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
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
    );
  }

  String _formatConversationTime(DateTime updatedAt, AppLocalizations t) {
    final now = DateTime.now();
    final diff = now.difference(updatedAt);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${updatedAt.day}/${updatedAt.month}';
  }

  Widget _buildWelcomePanel(AppLocalizations t, bool isDark) {
    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.backgroundGray,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 72, color: Color(0xFFBDBDBD)),
            const SizedBox(height: 16),
            Text(
              t.get('messages'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimary(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chọn một cuộc trò chuyện để bắt đầu',
              style: TextStyle(color: AppColors.getTextSecondary(isDark)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileView(AppLocalizations t, bool isDark) {
    return Column(
      children: [
        Expanded(
          child: IndexedStack(
            index: _selectedNavIndex,
            children: [
              _buildChatListPanel(t, isDark),
              const ContactsMainScreen(),
              const NewfeedScreen(),
              const ProfileScreen(),
            ],
          ),
        ),
        _buildBottomNavigation(isDark),
      ],
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        border: Border(top: BorderSide(color: AppColors.getDivider(isDark), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _buildBottomNavItem(Icons.chat_bubble, Icons.chat_bubble_outline, 0, 'Tin nhắn', isDark),
              _buildBottomNavItem(Icons.contacts, Icons.contacts_outlined, 1, 'Bạn bè', isDark),
              _buildBottomNavItem(Icons.auto_stories, Icons.auto_stories_outlined, 2, 'Bảng tin', isDark),
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
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
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
