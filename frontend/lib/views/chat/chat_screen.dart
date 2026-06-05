import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../features/calling/screens/call_screen.dart';
import '../../models/call_model.dart';
import '../../models/chat/conversation.dart';
import '../../providers/call_provider.dart';
import '../../models/chat/message.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/typing_indicator.dart';
import 'group_info_screen.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late ChatProvider _chatProvider;

  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  // Typing indicator
  bool _isTyping = false;
  String? _typingUserId;
  Timer? _typingTimer;

  // Reply
  Message? _replyToMessage;

  // Track IDs đã load từ history — không animate
  final Set<String> _historyIds = {};
  bool _historyLoaded = false;

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversation.id != widget.conversation.id) {
      _historyIds.clear();
      _historyLoaded = false;
      _scrolledToUnread = false;
      _initialUnreadCount = 0;
      // Wide-screen: conversation thay đổi nhưng widget không rebuild lại từ đầu,
      // cần trigger lại visibility để reset badge và markAsRead đúng lúc
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<ChatProvider>().setConversationVisible(true);
        }
      });
    }
  }

  // Scroll tracking
  int _prevMessageCount = 0;
  bool _initialScrollDone = false;
  bool _showScrollToBottom = false;

  // Jump-to-reply: GlobalKey per message + highlight
  final Map<String, GlobalKey> _messageKeys = {};
  String? _highlightedMessageId;

  // Unread tracking
  int _initialUnreadCount = 0;
  bool _scrolledToUnread = false;
  final GlobalKey _firstUnreadKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatProvider = context.read<ChatProvider>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMessages();
    _setupScrollListener();
    _setupSignalR();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ChatProvider>().setConversationVisible(true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final provider = context.read<ChatProvider>();
    if (state == AppLifecycleState.resumed) {
      provider.setConversationVisible(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      provider.setConversationVisible(false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatProvider
      ..setConversationVisible(false)
      ..closeConversation();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // reverse: true → offset 0 = bottom (tin mới nhất)
      final atBottom = _scrollController.offset <= 80;
      if (atBottom && _showScrollToBottom) {
        setState(() => _showScrollToBottom = false);
      } else if (!atBottom && !_showScrollToBottom) {
        setState(() => _showScrollToBottom = true);
      }
    });
  }

  void _setupSignalR() {
    // ChatProvider handles all SignalR events via its callbacks.
    // State is synced in build() via context.watch<ChatProvider>().
  }

  Future<void> _loadMessages() async {
    // openConversation() was already called from ChatListView before navigating here.
    // Messages will arrive via ChatProvider notifyListeners() → build() sync below.
    _scrollToBottom();
  }

  void _handleReceiveMessage(Message message) {
    if (message.conversationId == widget.conversation.id) {
      setState(() {
        _messages.add(message);
      });
      _scrollToBottom();

      // Mark as read
      // chatService.signalRService.markAsRead(widget.conversation.id, message.id);
    }
  }

  void _handleUserTyping(String conversationId, String userId, bool isTyping) {
    if (conversationId == widget.conversation.id) {
      setState(() {
        _isTyping = isTyping;
        _typingUserId = userId;
      });
    }
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    _messageController.clear();
    final replyId = _replyToMessage?.id;
    setState(() => _replyToMessage = null);

    await context.read<ChatProvider>().sendMessage(
      content: content,
      replyToMessageId: replyId,
    );
    _scrollToBottom();
  }

  void _onTyping() {
    context.read<ChatProvider>().sendTyping(true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      context.read<ChatProvider>().sendTyping(false);
    });
  }

  Future<void> _jumpToMessage(String messageId) async {
    final key = _messageKeys[messageId];
    if (key?.currentContext == null) return;

    // Scroll đến tin nhắn gốc (instant)
    await Scrollable.ensureVisible(
      key!.currentContext!,
      alignment: 0.3,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );

    // Highlight flash → fade
    if (!mounted) return;
    setState(() => _highlightedMessageId = messageId);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _highlightedMessageId = null);
  }

  void _scrollToBottom({bool instant = false}) {
    if (!_scrollController.hasClients) return;
    // reverse: true → "bottom" (tin mới nhất) = minScrollExtent (0)
    if (instant) {
      _scrollController.jumpTo(0);
    } else {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sync state from provider on each rebuild triggered by ChatProvider.notifyListeners()
    final chat = context.watch<ChatProvider>();
    _messages = chat.messages;
    _isTyping = chat.isOtherTyping;
    _typingUserId = chat.typingUserId;
    _isLoading = chat.messagesState == ChatLoadingState.loading;

    // Đánh dấu toàn bộ tin nhắn đã load là history (không animate)
    if (!_historyLoaded && chat.messagesState == ChatLoadingState.success) {
      _historyIds.addAll(_messages.map((m) => m.id));
      _initialUnreadCount = chat.openedWithUnreadCount;
      _historyLoaded = true;
    }

    // Scroll đến tin chưa đọc đầu tiên (1 lần duy nhất)
    if (_historyLoaded && !_scrolledToUnread && _messages.isNotEmpty) {
      _scrolledToUnread = true;
      if (_initialUnreadCount > 0 && _initialUnreadCount < _messages.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_firstUnreadKey.currentContext != null) {
            Scrollable.ensureVisible(
              _firstUnreadKey.currentContext!,
              alignment: 0.2,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }

    // Scroll to bottom khi:
    // 1. Lần đầu messages load xong
    // 2. Có tin nhắn mới (count tăng)
    final currentCount = _messages.length;
    if (currentCount > 0 &&
        (!_initialScrollDone || currentCount > _prevMessageCount)) {
      _prevMessageCount = currentCount;
      if (!_initialScrollDone) _initialScrollDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
    // Scroll khi typing indicator xuất hiện
    if (_isTyping) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          context.read<ChatProvider>().setConversationVisible(false);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFE8ECF1),
        resizeToAvoidBottomInset: true,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            if ((chat.activeConversation ?? widget.conversation).pinnedMessageId != null)
              _buildPinnedMessage(chat.activeConversation ?? widget.conversation),

            Expanded(
              child: Stack(
                children: [
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildMessageList(),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    right: 12,
                    bottom: _showScrollToBottom ? 12 : -56,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _showScrollToBottom ? 1.0 : 0.0,
                      child: GestureDetector(
                        onTap: _scrollToBottom,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF0068FF),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_replyToMessage != null) _buildReplyPreview(),

            _buildInputArea(),
          ],
        ),
      ), // end Scaffold
    ); // end PopScope
  }

  PreferredSizeWidget _buildAppBar() {
    final isOnline =
        widget.conversation.type == 'private' &&
        widget.conversation.otherUserId != null &&
        context.read<ChatProvider>().isUserOnline(
          widget.conversation.otherUserId!,
        );

    return AppBar(
      backgroundColor: const Color(0xFF0068FF),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: InkWell(
        onTap: _openConversationInfo,
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundImage: widget.conversation.displayAvatar.isNotEmpty
                      ? NetworkImage(widget.conversation.displayAvatar)
                      : null,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  child: widget.conversation.displayAvatar.isEmpty
                      ? Text(
                          widget.conversation.displayName.isNotEmpty
                              ? widget.conversation.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00CC44),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0068FF),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversation.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isOnline
                        ? 'Đang hoạt động'
                        : widget.conversation.displayStatus,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.call_outlined, color: Colors.white, size: 22),
          onPressed: _startVoiceCall,
        ),
        IconButton(
          icon: const Icon(
            Icons.videocam_outlined,
            color: Colors.white,
            size: 24,
          ),
          onPressed: _startVideoCall,
        ),
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white, size: 22),
          onPressed: _openConversationInfo,
        ),
      ],
    );
  }

  Widget _buildPinnedMessage(Conversation conv) {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          Container(width: 3, height: 40, color: const Color(0xFF0068FF)),
          const SizedBox(width: 10),
          const Icon(Icons.push_pin_rounded, size: 13, color: Color(0xFF0068FF)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Tin nhắn đã ghim', style: TextStyle(fontSize: 10, color: Color(0xFF0068FF), fontWeight: FontWeight.w600)),
                Text(
                  conv.pinnedMessageContent ?? '',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _unpinMessage,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: const Icon(Icons.close, size: 16, color: Color(0xFFAAAAAA)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty && !_isTyping) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Chưa có tin nhắn nào',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Gửi tin nhắn để bắt đầu cuộc trò chuyện',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // reverse: true — index 0 = bottom (tin mới nhất / typing indicator)
    // Khi bàn phím mở, bottom luôn visible → không cần scroll thủ công
    final totalItems = _messages.length + (_isTyping ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        // index 0 = bottom = typing indicator (nếu có)
        if (_isTyping && index == 0) {
          return const TypingIndicator(key: ValueKey('typing'));
        }

        // Tính index thực trong _messages (0 = cũ nhất, length-1 = mới nhất)
        final msgIndex = _messages.length - 1 - (_isTyping ? index - 1 : index);
        if (msgIndex < 0 || msgIndex >= _messages.length)
          return const SizedBox.shrink();

        final message = _messages[msgIndex];
        final prev = msgIndex > 0 ? _messages[msgIndex - 1] : null; // cũ hơn
        final next = msgIndex < _messages.length - 1
            ? _messages[msgIndex + 1]
            : null; // mới hơn

        final sameAsPrev =
            prev != null &&
            prev.senderId == message.senderId &&
            message.createdAt.difference(prev.createdAt).inMinutes < 3;
        final sameAsNext =
            next != null &&
            next.senderId == message.senderId &&
            next.createdAt.difference(message.createdAt).inMinutes < 3;

        final isLastInGroup = !sameAsNext;
        final isFirstInGroup = !sameAsPrev;

        // Date separator: hiện ở trên tin nhắn CŨ NHẤT của mỗi ngày
        final showDateSeparator =
            prev == null ||
            prev.createdAt.day != message.createdAt.day ||
            prev.createdAt.month != message.createdAt.month ||
            prev.createdAt.year != message.createdAt.year;

        // Tạo / tái dùng GlobalKey cho mỗi message
        final msgKey = _messageKeys.putIfAbsent(message.id, () => GlobalKey());

        // Kiểm tra tin reply-to có phải của mình không
        final replyToIsMine =
            message.replyToMessageId != null &&
            _messages.any((m) => m.id == message.replyToMessageId && m.isMine);

        final bubble = MessageBubble(
          key: msgKey,
          message: message,
          showAvatar: !message.isMine && isLastInGroup,
          showSenderName:
              !message.isMine &&
              isFirstInGroup &&
              widget.conversation.type == 'group',
          showMeta: isLastInGroup,
          isGroupTop: isFirstInGroup && sameAsNext,
          isGroupMiddle: sameAsPrev && sameAsNext,
          isGroupBottom: sameAsPrev && isLastInGroup,
          highlighted: _highlightedMessageId == message.id,
          replyToIsMine: replyToIsMine,
          onReplyPreviewTap: message.replyToMessageId != null
              ? () => _jumpToMessage(message.replyToMessageId!)
              : null,
          onReact: (emoji) => _reactToMessage(message.id, emoji),
          onPin: () async {
            try {
              await context.read<ChatProvider>().pinMessage(message.id, message.content);
            } catch (e) {
              debugPrint('[pin] error: $e');
              if (mounted) _showError('Pin lỗi: $e');
            }
          },
          onReply: () => setState(() => _replyToMessage = message),
          onForward: () => _forwardMessage(message),
          onCopy: () => _copyMessage(message),
          onEdit: () => _editMessage(message),
          onDelete: () => _deleteMessage(message),
          onHideForMe: () =>
              context.read<ChatProvider>().hideMessageForMe(message.id),
          onInfo: () => _showMessageInfo(message),
        );

        final isNew = !_historyIds.contains(message.id);
        final bubbleWidget = isNew
            ? _AnimatedBubble(isMine: message.isMine, child: bubble)
            : bubble;

        // Hiện divider "X tin chưa đọc" tại tin chưa đọc đầu tiên
        final isFirstUnread =
            _initialUnreadCount > 0 &&
            msgIndex == _messages.length - _initialUnreadCount;

        return Column(
          key: isFirstUnread ? _firstUnreadKey : ValueKey(message.id),
          children: [
            if (showDateSeparator) _buildDateSeparator(message.createdAt),
            if (isFirstUnread) _buildUnreadDivider(_initialUnreadCount),
            _SwipeToReplyWrapper(
              isMine: message.isMine,
              onReply: () => setState(() => _replyToMessage = message),
              child: bubbleWidget,
            ),
          ],
        );
      },
    );
  }

  Widget _buildUnreadDivider(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.red.shade300, thickness: 0.8)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$count tin nhắn chưa đọc',
              style: TextStyle(
                fontSize: 11,
                color: Colors.red.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.red.shade300, thickness: 0.8)),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _formatDate(date),
            style: const TextStyle(fontSize: 11, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          Container(width: 3, height: 48, color: const Color(0xFF0068FF)),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Trả lời ${_replyToMessage!.senderName}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0068FF)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _replyToMessage!.content,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _replyToMessage = null),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Icon(Icons.close, size: 18, color: Color(0xFFAAAAAA)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final hasText = _messageController.text.trim().isNotEmpty;
    const iconColor = Color(0xFF707070);

    Widget iconBtn(IconData icon, VoidCallback onTap, {double size = 22}) =>
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: 38,
              height: 38,
              child: Icon(icon, color: iconColor, size: size),
            ),
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: const Color(0xFFEEEEEE), width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // + button bên trái
              iconBtn(Icons.add_circle_outline_rounded, _showAttachmentOptions, size: 26),

              // Text field giữa
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 38, maxHeight: 120),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          onChanged: (_) { _onTyping(); setState(() {}); },
                          decoration: const InputDecoration(
                            hintText: 'Aa',
                            hintStyle: TextStyle(color: Color(0xFFBBBBBB), fontSize: 15),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 15, height: 1.4),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      // Emoji icon bên phải trong field
                      Padding(
                        padding: const EdgeInsets.only(right: 4, bottom: 2),
                        child: InkWell(
                          onTap: _showEmojiPicker,
                          borderRadius: BorderRadius.circular(16),
                          child: const SizedBox(
                            width: 34,
                            height: 34,
                            child: Icon(Icons.emoji_emotions_outlined, color: Color(0xFF999999), size: 21),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bên phải: khi chưa gõ → sticker + ảnh + mic; khi gõ → send
              if (hasText) ...[
                GestureDetector(
                  onTap: _sendMessage,
                  child: _isSending
                      ? const SizedBox(
                          width: 38, height: 38,
                          child: Padding(padding: EdgeInsets.all(9), child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0068FF))),
                        )
                      : Container(
                          width: 38, height: 38,
                          decoration: const BoxDecoration(color: Color(0xFF0068FF), shape: BoxShape.circle),
                          child: const Icon(Icons.send_rounded, color: Colors.white, size: 19),
                        ),
                ),
              ] else ...[
                iconBtn(Icons.image_outlined, _pickImageFromGallery, size: 23),
                iconBtn(Icons.mic_none_rounded, _recordAudio, size: 23),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputIconBtn(IconData icon, {required VoidCallback onPressed}) {
    return SizedBox(
      width: 40,
      height: 40,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Icon(icon, color: const Color(0xFF606060), size: 22),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Hôm nay';
    } else if (messageDate == yesterday) {
      return 'Hôm qua';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _getTypingUserName() {
    final participant = widget.conversation.participants.firstWhere(
      (p) => p.userId == _typingUserId,
      orElse: () => widget.conversation.participants.first,
    );
    return participant.displayName;
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.photo_library,
                  label: 'Thư viện',
                  color: Colors.purple,
                  onTap: _pickImageFromGallery,
                ),
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: Colors.red,
                  onTap: _pickImageFromCamera,
                ),
                _buildAttachmentOption(
                  icon: Icons.videocam,
                  label: 'Video',
                  color: Colors.orange,
                  onTap: _pickVideo,
                ),
                _buildAttachmentOption(
                  icon: Icons.insert_drive_file,
                  label: 'Tệp',
                  color: Colors.blue,
                  onTap: _pickFile,
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.mic,
                  label: 'Ghi âm',
                  color: Colors.green,
                  onTap: _recordAudio,
                ),
                _buildAttachmentOption(
                  icon: Icons.location_on,
                  label: 'Vị trí',
                  color: Colors.teal,
                  onTap: _shareLocation,
                ),
                _buildAttachmentOption(
                  icon: Icons.person,
                  label: 'Danh bạ',
                  color: Colors.indigo,
                  onTap: _shareContact,
                ),
                _buildAttachmentOption(
                  icon: Icons.emoji_emotions,
                  label: 'Sticker',
                  color: Colors.amber,
                  onTap: _showStickerPicker,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // Actions
  void _openConversationInfo() {
    if (widget.conversation.type == 'group') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              GroupInfoScreen(conversation: widget.conversation),
        ),
      );
    } else {
      // Open user profile
    }
  }

  void _startVideoCall() => _startCall(isVideo: true);
  void _startVoiceCall() => _startCall(isVideo: false);

  Future<void> _startCall({required bool isVideo}) async {
    final conv = widget.conversation;
    final otherUserId = conv.otherUserId;
    if (otherUserId == null) return;

    final chatProvider = context.read<ChatProvider>();
    final callProvider = context.read<CallProvider>();
    final myUid = chatProvider.currentUid ?? '';

    final call = CallModel(
      conversationId: conv.id,
      callerId: myUid,
      calleeId: otherUserId,
      remoteName: conv.displayName,
      remoteAvatar: conv.displayAvatar,
      isVideo: isVideo,
      isIncoming: false,
      status: CallStatus.dialing,
    );

    final me = conv.participants.where((p) => p.userId == myUid).firstOrNull;
    final firebaseUser = FirebaseAuth.instance.currentUser;
    debugPrint('[Call] myUid=$myUid');
    debugPrint('[Call] me.displayName=${me?.displayName}');
    debugPrint('[Call] cachedSenderName=${chatProvider.cachedSenderName}');
    debugPrint('[Call] firebaseEmail=${firebaseUser?.email}');
    debugPrint(
      '[Call] participants=${conv.participants.map((p) => "${p.userId}:${p.userName}").join(", ")}',
    );

    final myName = [
      me?.displayName,
      chatProvider.cachedSenderName,
      firebaseUser?.displayName,
      firebaseUser?.email?.split('@').first,
      myUid,
    ].firstWhere((s) => s != null && s.isNotEmpty, orElse: () => myUid)!;
    debugPrint('[Call] myName=$myName');
    final myAvatar = me?.avatar ?? chatProvider.cachedSenderAvatar ?? '';

    // Báo cho đối phương qua SignalR
    await chatProvider.initiateCall(
      conversationId: conv.id,
      calleeId: otherUserId,
      callType: isVideo ? 'video' : 'voice',
      callerName: myName,
      callerAvatar: myAvatar,
    );

    callProvider.startOutgoingCall(call);

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CallScreen(call: call),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'search':
        _showInfo('Tính năng tìm kiếm đang được phát triển');
        break;
      case 'mute':
        _showInfo(
          'Đã ${widget.conversation.isMuted ? "bật" : "tắt"} thông báo',
        );
        break;
      case 'media':
        _showInfo('Tính năng xem ảnh/video đang được phát triển');
        break;
      case 'clear':
        _confirmClearHistory();
        break;
    }
  }

  void _unpinMessage() {
    context.read<ChatProvider>().unpinMessage().catchError((e) {
      if (mounted) _showError('Không thể bỏ ghim tin nhắn');
    });
  }

  void _reactToMessage(String messageId, String emoji) {
    context.read<ChatProvider>().reactToMessage(messageId, emoji);
  }

  void _forwardMessage(Message message) {
    _showInfo('Tính năng chuyển tiếp đang được phát triển');
  }

  void _copyMessage(Message message) {
    // TODO: Copy to clipboard
    _showInfo('Đã sao chép');
  }

  void _editMessage(Message message) {
    _messageController.text = message.content;
    _focusNode.requestFocus();
  }

  void _deleteMessage(Message message) {
    context.read<ChatProvider>().deleteMessage(message.id);
  }

  void _showMessageInfo(Message message) {
    _showInfo('Tính năng thông tin tin nhắn đang được phát triển');
  }

  void _showEmojiPicker() {
    _showInfo('Tính năng emoji picker đang được phát triển');
  }

  void _sendLike() {
    // TODO: Send like emoji
    _showInfo('Đã gửi like');
  }

  void _pickImageFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // TODO: Upload and send
      _showInfo('Đang gửi hình ảnh...');
    }
  }

  void _pickImageFromCamera() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      // TODO: Upload and send
      _showInfo('Đang gửi hình ảnh...');
    }
  }

  void _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      // TODO: Upload and send
      _showInfo('Đang gửi video...');
    }
  }

  void _pickFile() async {
    // TODO: Implement file picker when package is added
    // final result = await FilePicker.platform.pickFiles();
    // if (result != null) {
    //   // TODO: Upload and send
    //   _showInfo('Đang gửi tệp...');
    // }
    _showInfo('Tính năng chọn tệp đang được phát triển');
  }

  void _recordAudio() {
    _showInfo('Tính năng ghi âm đang được phát triển');
  }

  void _shareLocation() {
    _showInfo('Tính năng chia sẻ vị trí đang được phát triển');
  }

  void _shareContact() {
    _showInfo('Tính năng chia sẻ danh bạ đang được phát triển');
  }

  void _showStickerPicker() {
    _showInfo('Tính năng sticker đang được phát triển');
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa lịch sử trò chuyện'),
        content: Text('Bạn có chắc chắn muốn xóa toàn bộ lịch sử trò chuyện?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccess('Đã xóa lịch sử trò chuyện');
            },
            child: Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Swipe-to-reply: kéo phải (tin người khác) hoặc kéo trái (tin mình)
class _SwipeToReplyWrapper extends StatefulWidget {
  final Widget child;
  final bool isMine;
  final VoidCallback? onReply;

  const _SwipeToReplyWrapper({
    required this.child,
    required this.isMine,
    this.onReply,
  });

  @override
  State<_SwipeToReplyWrapper> createState() => _SwipeToReplyWrapperState();
}

class _SwipeToReplyWrapperState extends State<_SwipeToReplyWrapper>
    with SingleTickerProviderStateMixin {
  double _offset = 0;
  bool _triggered = false;
  late final AnimationController _ctrl;
  Animation<double>? _returnAnim;

  static const double _threshold = 56;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _ctrl.addListener(() {
      if (mounted && _returnAnim != null) {
        setState(() => _offset = _returnAnim!.value);
      }
    });
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _offset = 0;
          _triggered = false;
          _returnAnim = null;
        });
        _ctrl.reset();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onUpdate(DragUpdateDetails d) {
    if (_ctrl.isAnimating) return;
    final dx = d.delta.dx;
    // isMine: chỉ kéo trái (dx < 0), other: chỉ kéo phải (dx > 0)
    if (widget.isMine && dx > 0) return;
    if (!widget.isMine && dx < 0) return;

    setState(() {
      _offset += dx;
      final max = _threshold * 1.3;
      _offset = widget.isMine ? _offset.clamp(-max, 0) : _offset.clamp(0, max);
    });

    if (_offset.abs() >= _threshold && !_triggered) {
      _triggered = true;
      HapticFeedback.mediumImpact();
      widget.onReply?.call();
    }
  }

  void _onEnd(DragEndDetails _) {
    _returnAnim = Tween<double>(
      begin: _offset,
      end: 0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_offset.abs() / _threshold).clamp(0.0, 1.0);

    return GestureDetector(
      onHorizontalDragUpdate: _onUpdate,
      onHorizontalDragEnd: _onEnd,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Icon reply xuất hiện phía sau khi kéo
          Positioned(
            left: widget.isMine ? null : 10,
            right: widget.isMine ? 10 : null,
            top: 0,
            bottom: 0,
            child: Center(
              child: Opacity(
                opacity: progress,
                child: Transform.scale(
                  scale: 0.5 + 0.5 * progress,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.reply_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Bubble trượt theo ngón tay
          Transform.translate(offset: Offset(_offset, 0), child: widget.child),
        ],
      ),
    );
  }
}

/// Slide + fade animation cho tin nhắn mới xuất hiện
class _AnimatedBubble extends StatefulWidget {
  final Widget child;
  final bool isMine;

  const _AnimatedBubble({required this.child, required this.isMine});

  @override
  State<_AnimatedBubble> createState() => _AnimatedBubbleState();
}

class _AnimatedBubbleState extends State<_AnimatedBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    // Slide từ bên phải (mine) hoặc bên trái + nhẹ từ dưới lên
    _slide = Tween<Offset>(
      begin: Offset(widget.isMine ? 0.25 : -0.25, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _fade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}
