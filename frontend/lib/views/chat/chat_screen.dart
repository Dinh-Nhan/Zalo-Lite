import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/chat/conversation.dart';
import '../../models/chat/message.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/typing_indicator.dart';
import '../../widgets/emoji_picker_widget.dart';
import 'group_info_screen.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _showScrollToBottom = false;
  bool _showEmojiKeyboard = false;

  // Typing indicator
  bool _isTyping = false;
  String? _typingUserId;
  Timer? _typingTimer;

  // Reply
  Message? _replyToMessage;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupScrollListener();
    _setupSignalR();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.offset > 200) {
        if (!_showScrollToBottom) {
          setState(() => _showScrollToBottom = true);
        }
      } else {
        if (_showScrollToBottom) {
          setState(() => _showScrollToBottom = false);
        }
      }
    });
  }

  void _setupSignalR() {
    // TODO: Setup SignalR listeners
    // chatService.signalRService.onReceiveMessage = _handleReceiveMessage;
    // chatService.signalRService.onUserTyping = _handleUserTyping;
    // chatService.signalRService.onMessageRead = _handleMessageRead;
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Load from API
      // final messages = await chatService.getMessages(widget.conversation.id);

      // Mock data for demo
      await Future.delayed(Duration(seconds: 1));

      setState(() {
        _messages = [];
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Không thể tải tin nhắn');
    }
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

    setState(() => _isSending = true);

    try {
      // TODO: Send via SignalR
      // await chatService.signalRService.sendMessage(
      //   conversationId: widget.conversation.id,
      //   type: 'text',
      //   content: content,
      //   replyToMessageId: _replyToMessage?.id,
      // );

      _messageController.clear();
      setState(() {
        _replyToMessage = null;
        _isSending = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isSending = false);
      _showError('Không thể gửi tin nhắn');
    }
  }

  void _onTyping() {
    // TODO: Send typing indicator
    // chatService.signalRService.userTyping(widget.conversation.id, true);

    _typingTimer?.cancel();
    _typingTimer = Timer(Duration(seconds: 2), () {
      // chatService.signalRService.userTyping(widget.conversation.id, false);
    });
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _insertEmoji(String emoji) {
    final text = _messageController.text;
    final selection = _messageController.selection;
    
    if (selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, emoji);
      final newPosition = selection.start + emoji.length;
      
      _messageController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newPosition),
      );
    } else {
      _messageController.text += emoji;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Pinned message
          if (widget.conversation.pinnedMessageId != null)
            _buildPinnedMessage(),

          // Messages
          Expanded(
            child: Stack(
              children: [
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _buildMessageList(),

                // Scroll to bottom button
                if (_showScrollToBottom)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.white,
                      onPressed: _scrollToBottom,
                      child: Icon(Icons.arrow_downward, color: Colors.blue),
                    ),
                  ),
              ],
            ),
          ),

          // Typing indicator
          if (_isTyping && _typingUserId != null)
            TypingIndicator(userName: _getTypingUserName()),

          // Reply preview
          if (_replyToMessage != null) _buildReplyPreview(),

          // Input area
          _buildInputArea(),
          
          if (_showEmojiKeyboard)
            EmojiPickerWidget(
              onEmojiSelected: _insertEmoji,
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: InkWell(
        onTap: _openConversationInfo,
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: widget.conversation.displayAvatar.isNotEmpty
                      ? NetworkImage(widget.conversation.displayAvatar)
                      : null,
                  backgroundColor: Colors.grey[300],
                  child: widget.conversation.displayAvatar.isEmpty
                      ? Text(
                          widget.conversation.displayName[0].toUpperCase(),
                          style: TextStyle(fontSize: 16),
                        )
                      : null,
                ),
                if (widget.conversation.type == 'private' &&
                    widget.conversation.otherUserOnline == true)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversation.displayName,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.conversation.displayStatus,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.videocam, color: Colors.black),
          onPressed: _startVideoCall,
        ),
        IconButton(
          icon: Icon(Icons.call, color: Colors.black),
          onPressed: _startVoiceCall,
        ),
        PopupMenuButton(
          icon: Icon(Icons.more_vert, color: Colors.black),
          itemBuilder: (context) => [
            PopupMenuItem(value: 'search', child: Text('Tìm kiếm')),
            PopupMenuItem(
              value: 'mute',
              child: Text(
                'Bật thông báo' : 'Tắt thông báo',
              ),
            ),
            PopupMenuItem(value: 'media', child: Text('Xem ảnh/video')),
            PopupMenuItem(value: 'clear', child: Text('Xóa lịch sử')),
          ],
          onSelected: _handleMenuAction,
        ),
      ],
    );
  }

  Widget _buildPinnedMessage() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.blue[100]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.push_pin, size: 16, color: Colors.blue),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.conversation.pinnedMessageContent ?? 'Tin nhắn đã ghim',
              style: TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18),
            onPressed: _unpinMessage,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text(
              'Chưa có tin nhắn nào',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              'Gửi tin nhắn để bắt đầu cuộc trò chuyện',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final showDateSeparator = _shouldShowDateSeparator(index);

        return Column(
          children: [
            if (showDateSeparator) _buildDateSeparator(message.createdAt),
            MessageBubble(
              message: message,
              onReact: (emoji) => _reactToMessage(message.id, emoji),
              onReply: () => _replyToMessage = message,
              onForward: () => _forwardMessage(message),
              onCopy: () => _copyMessage(message),
              onEdit: () => _editMessage(message),
              onDelete: () => _deleteMessage(message),
              onInfo: () => _showMessageInfo(message),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatDate(date),
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
          left: BorderSide(color: Colors.blue, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trả lời ${_replyToMessage!.senderName}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _replyToMessage!.content,
                  style: TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 20),
            onPressed: () => setState(() => _replyToMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Colors.blue),
            onPressed: _showAttachmentOptions,
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      onChanged: (_) => _onTyping(),
                      onTap: () {
                        setState(() {
                          _showEmojiKeyboard = false;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Aa',
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.emoji_emotions_outlined,
                      color: _showEmojiKeyboard ? Colors.blue : Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        _showEmojiKeyboard = !_showEmojiKeyboard;
                        if (_showEmojiKeyboard) {
                          _focusNode.unfocus();
                        }
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8),
          _isSending
              ? SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    _messageController.text.trim().isEmpty
                        ? Icons.thumb_up
                        : Icons.send,
                    color: Colors.blue,
                  ),
                  onPressed: _messageController.text.trim().isEmpty
                      ? _sendLike
                      : _sendMessage,
                ),
        ],
      ),
    );
  }

  bool _shouldShowDateSeparator(int index) {
    if (index == 0) return true;

    final currentDate = _messages[index].createdAt;
    final previousDate = _messages[index - 1].createdAt;

    return currentDate.day != previousDate.day ||
        currentDate.month != previousDate.month ||
        currentDate.year != previousDate.year;
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

  void _startVideoCall() {
    _showInfo('Tính năng gửi video đang được phát triển');
  }

  void _startVoiceCall() {
    _showInfo('Tính năng gửi thoại đang được phát triển');
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
    _showInfo('Đã bỏ ghim tin nhắn');
  }

  void _reactToMessage(String messageId, String emoji) {
    // TODO: React via SignalR
    _showInfo('Đã thu cắm xúc');
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thu hồi tin nhắn'),
        content: Text('Bạn có chắc chắn muốn thu hồi tin nhắn này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Delete via SignalR
              Navigator.pop(context);
              _showSuccess('Đã thu hồi tin nhắn');
            },
            child: Text('Thu hồi', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showMessageInfo(Message message) {
    _showInfo('Tính năng đánh dấu tin nhắn đang được phát triển');
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
