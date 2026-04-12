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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
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
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
          ] else
            const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contactName,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.isGroup && widget.memberCount != null)
                  Text(
                    '${widget.memberCount} ${t.get('members')}',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              final callData = CallModel(
                id: DateTime.now().toString(),
                remoteName: widget.contactName,
                remoteAvatar: '', // Thêm avatar nếu có
                isVideo: false,
              );
              context.read<CallProvider>().initCall(callData);

              // 2. Sau đó mới chuyển trang
              context.go('/call');
            },
            icon: Icon(
              Icons.call_outlined,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          IconButton(
            onPressed: () {
              final callData = CallModel(
                id: DateTime.now().toString(),
                remoteName: widget.contactName,
                remoteAvatar: '', // Thêm avatar nếu có
                isVideo: false,
              );
              context.read<CallProvider>().initCall(callData);

            },
            icon: Icon(
              Icons.videocam_outlined,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.menu,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
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
        final message = _messages[index - 1];
        return _buildMessageBubble(message, isDark);
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

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isDark) {
    final bool isMe = message['isMe'];
    final String content = message['content'];
    final String time = message['time'];
    final Color? senderAvatar = message['senderAvatar'];
    final String? senderName = message['senderName'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
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
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Hiển thị tên người gửi trong nhóm
                if (!isMe && widget.isGroup && senderName != null) ...[
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? (isDark
                              ? const Color(0xFF3A5A80)
                              : const Color(0xFFD6EAF8))
                        : (isDark ? AppColors.darkCard : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                  ),
                  child: Text(
                    content,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.only(
                    left: isMe ? 0 : 8,
                    right: isMe ? 8 : 0,
                  ),
                  child: Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary.withValues(alpha: 0.6),
                    ),
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
