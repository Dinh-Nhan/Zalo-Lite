import 'package:flutter/material.dart';
import 'package:frontend/apps/app_locale.dart';
import 'package:frontend/models/call_model.dart';
import 'package:frontend/providers/call_provider.dart';
import 'package:frontend/utils/app_localizations.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/dark_mode_config.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Màn hình chi tiết tin nhắn
class ChatDetailView extends StatefulWidget {
  final String conversationId;
  final String contactName;
  final Color avatarColor;
  final bool isGroup;
  final int? memberCount;
  final bool showBackButton;

  const ChatDetailView({
    super.key,
    required this.conversationId,
    required this.contactName,
    required this.avatarColor,
    this.isGroup = false,
    this.memberCount,
    this.showBackButton = true,
  });

  @override
  State<ChatDetailView> createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends State<ChatDetailView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showSendButton = false;

  // Mock messages data
  late List<Map<String, dynamic>> _messages;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onMessageChanged);
    _loadMockMessages();
  }

  void _loadMockMessages() {
    // Mock messages cho chat cá nhân (friend)
    if (!widget.isGroup) {
      _messages = [
        {
          'id': 'msg_001',
          'content': 'Chào bạn! Bạn khỏe không?',
          'isMe': false,
          'time': '14:35',
          'date': 'today',
          'senderName': widget.contactName,
          'senderAvatar': widget.avatarColor,
        },
        {
          'id': 'msg_002',
          'content': 'Mình khỏe, cảm ơn bạn nha 😊',
          'isMe': true,
          'time': '14:36',
          'date': 'today',
        },
        {
          'id': 'msg_003',
          'content': 'Cuối tuần này bạn có rảnh không? Đi chơi nhé!',
          'isMe': false,
          'time': '14:37',
          'date': 'today',
          'senderName': widget.contactName,
          'senderAvatar': widget.avatarColor,
        },
        {
          'id': 'msg_004',
          'content': 'Nice to meet you',
          'isMe': true,
          'time': '14:39',
          'date': 'today',
        },
        {
          'id': 'msg_005',
          'content': 'Nice to meet you too',
          'isMe': false,
          'time': '14:39',
          'date': 'today',
          'senderName': widget.contactName,
          'senderAvatar': widget.avatarColor,
        },
      ];
    } else {
      // Mock messages cho chat nhóm (group)
      _messages = [
        {
          'id': 'msg_001',
          'content': 'Chào cả nhóm! 👋',
          'isMe': false,
          'time': '14:30',
          'date': 'today',
          'senderName': 'Minh Anh',
          'senderAvatar': const Color(0xFF2196F3),
        },
        {
          'id': 'msg_002',
          'content': 'Hi mọi người!',
          'isMe': false,
          'time': '14:31',
          'date': 'today',
          'senderName': 'Tuấn Kiệt',
          'senderAvatar': const Color(0xFFFF9800),
        },
        {
          'id': 'msg_003',
          'content': 'Chào cả nhà 😄',
          'isMe': true,
          'time': '14:32',
          'date': 'today',
        },
        {
          'id': 'msg_004',
          'content': 'Hôm nay nhóm mình họp lúc mấy giờ nhỉ?',
          'isMe': false,
          'time': '14:35',
          'date': 'today',
          'senderName': 'Minh Anh',
          'senderAvatar': const Color(0xFF2196F3),
        },
        {
          'id': 'msg_005',
          'content': '3 giờ chiều nhé các bạn',
          'isMe': true,
          'time': '14:36',
          'date': 'today',
        },
        {
          'id': 'msg_006',
          'content': 'Ok, mình sẽ có mặt đúng giờ 👍',
          'isMe': false,
          'time': '14:37',
          'date': 'today',
          'senderName': 'Tuấn Kiệt',
          'senderAvatar': const Color(0xFFFF9800),
        },
        {
          'id': 'msg_007',
          'content': 'Nice to meet you',
          'isMe': true,
          'time': '14:39',
          'date': 'today',
        },
        {
          'id': 'msg_008',
          'content': 'Nice to meet you too',
          'isMe': false,
          'time': '14:39',
          'date': 'today',
          'senderName': 'Hà Linh',
          'senderAvatar': const Color(0xFFE91E63),
        },
      ];
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onMessageChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _showSendButton) {
      setState(() => _showSendButton = hasText);
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'id': 'msg_${DateTime.now().millisecondsSinceEpoch}',
        'content': _messageController.text.trim(),
        'isMe': true,
        'time': _getCurrentTime(),
        'date': 'today',
      });
      _messageController.clear();
      _showSendButton = false;
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
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
            return Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: AppColors.getDivider(isDark),
                    width: 1,
                  ),
                ),
              ),
              child: Scaffold(
                backgroundColor: isDark
                    ? AppColors.darkBackground
                    : const Color(0xFFD9D9D9),
                body: SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(t, isDark),
                      Expanded(child: _buildMessageList(t, isDark)),
                      _buildInputArea(t, isDark),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(AppLocalizations t, bool isDark) {
    // On mobile (showBackButton), use blue header (dark mode: black); on wide screen, keep white/dark
    final bool isMobileHeader = widget.showBackButton;
    final Color headerBg = isMobileHeader
        ? (isDark ? const Color(0xFF1A1A1A) : AppColors.primaryBlue)
        : (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final Color headerIconColor = isMobileHeader
        ? Colors.white
        : (isDark ? Colors.white : AppColors.textPrimary);
    final Color headerTextColor = isMobileHeader
        ? Colors.white
        : (isDark ? Colors.white : AppColors.textPrimary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: headerBg,
        border: isMobileHeader
            ? null
            : Border(
                left: BorderSide(color: AppColors.getDivider(isDark), width: 1),
                bottom: BorderSide(color: AppColors.getDivider(isDark), width: 1),
              ),
      ),
      child: Row(
        children: [
          if (widget.showBackButton) ...[
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back,
                color: headerIconColor,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
          ] else
            const SizedBox(width: 8),
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: widget.avatarColor,
            child: Text(
              _getInitials(widget.contactName),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contactName,
                  style: TextStyle(
                    color: headerTextColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.isGroup && widget.memberCount != null)
                  Text(
                    '${widget.memberCount} ${t.get('members')}',
                    style: TextStyle(
                      color: isMobileHeader
                          ? Colors.white.withValues(alpha: 0.8)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.8)
                              : AppColors.textSecondary),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.call_outlined,
              color: headerIconColor,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.videocam_outlined,
              color: headerIconColor,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.menu,
              color: headerIconColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Check if two messages are in the same group
  /// (same sender, within 5 minutes)
  bool _isSameGroup(Map<String, dynamic> msg1, Map<String, dynamic> msg2) {
    if (msg1['isMe'] != msg2['isMe']) return false;
    // For group chats, also check sender name
    if (widget.isGroup && !msg1['isMe']) {
      if (msg1['senderName'] != msg2['senderName']) return false;
    }
    // Parse time (HH:mm format) and check if within 5 minutes
    try {
      final parts1 = msg1['time'].split(':');
      final parts2 = msg2['time'].split(':');
      final min1 = int.parse(parts1[0]) * 60 + int.parse(parts1[1]);
      final min2 = int.parse(parts2[0]) * 60 + int.parse(parts2[1]);
      return (min2 - min1).abs() <= 5;
    } catch (_) {
      return false;
    }
  }

  Widget _buildMessageList(AppLocalizations t, bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: _messages.length + 1, // +1 for date header
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildDateDivider(t, isDark);
        }
        final msgIndex = index - 1;
        final message = _messages[msgIndex];

        // Determine if this is the last message in a consecutive group
        final bool isLastInGroup = msgIndex == _messages.length - 1 ||
            !_isSameGroup(message, _messages[msgIndex + 1]);
        final bool isFirstInGroup = msgIndex == 0 ||
            !_isSameGroup(_messages[msgIndex - 1], message);

        return _buildMessageBubble(
          message,
          isDark,
          showTime: isLastInGroup,
          isFirstInGroup: isFirstInGroup,
          isLastInGroup: isLastInGroup,
        );
      },
    );
  }

  Widget _buildDateDivider(AppLocalizations t, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '14:39 - ${t.get('today')}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> message,
    bool isDark, {
    bool showTime = true,
    bool isFirstInGroup = true,
    bool isLastInGroup = true,
  }) {
    final bool isMe = message['isMe'];
    final String content = message['content'];
    final String time = message['time'];
    final Color? senderAvatar = message['senderAvatar'];
    final String? senderName = message['senderName'];

    // Tighter spacing for grouped messages
    final double bottomPadding = isLastInGroup ? 12.0 : 3.0;

    // Show avatar only on last message of group for non-me messages
    final bool showAvatar = !isMe && isLastInGroup;
    // Reserve avatar space for alignment
    final double avatarSpace = !isMe ? 44.0 : 0.0; // 18*2 radius + 8 spacing

    // Adjust border radius for grouped bubbles
    late BorderRadius bubbleRadius;
    if (isMe) {
      bubbleRadius = BorderRadius.only(
        topLeft: const Radius.circular(18),
        topRight: Radius.circular(isFirstInGroup ? 18 : 6),
        bottomLeft: const Radius.circular(18),
        bottomRight: Radius.circular(isLastInGroup ? 4 : 6),
      );
    } else {
      bubbleRadius = BorderRadius.only(
        topLeft: Radius.circular(isFirstInGroup ? 18 : 6),
        topRight: const Radius.circular(18),
        bottomLeft: Radius.circular(isLastInGroup ? 4 : 6),
        bottomRight: const Radius.circular(18),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            if (showAvatar)
              CircleAvatar(
                radius: 18,
                backgroundColor: senderAvatar ?? widget.avatarColor,
                child: Text(
                  _getInitials(senderName ?? widget.contactName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              const SizedBox(width: 36), // placeholder for avatar alignment
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Show sender name only on first message of group in group chats
                if (!isMe && widget.isGroup && senderName != null && isFirstInGroup) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Text(
                      senderName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: EdgeInsets.only(
                    left: 12,
                    right: 12,
                    top: 8,
                    bottom: showTime ? 4 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? (isDark
                              ? const Color(0xFF3A5A80)
                              : const Color(0xFFD6EAF8))
                        : (isDark ? AppColors.darkCard : Colors.white),
                    borderRadius: bubbleRadius,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (showTime) ...[
                        const SizedBox(height: 2),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 11,
                            color: isMe
                                ? (isDark
                                    ? Colors.white.withValues(alpha: 0.6)
                                    : AppColors.primaryBlue.withValues(alpha: 0.7))
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary.withValues(alpha: 0.6)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(AppLocalizations t, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.insert_emoticon_outlined,
              color: AppColors.getTextSecondary(isDark),
              size: 26,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBackground
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: t.get('messageHint'),
                        hintStyle: TextStyle(
                          color: AppColors.getTextSecondary(isDark),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      style: TextStyle(
                        color: AppColors.getTextPrimary(isDark),
                        fontSize: 15,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (!_showSendButton) ...[
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.more_horiz,
                color: AppColors.getTextSecondary(isDark),
                size: 26,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.mic_none,
                color: AppColors.getTextSecondary(isDark),
                size: 26,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.image_outlined,
                color: AppColors.getTextSecondary(isDark),
                size: 26,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ] else
            IconButton(
              onPressed: _sendMessage,
              icon: const Icon(
                Icons.send,
                color: AppColors.primaryBlue,
                size: 26,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
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
