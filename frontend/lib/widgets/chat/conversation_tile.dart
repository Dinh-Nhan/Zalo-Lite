import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/chat/conversation.dart';

class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final Function(String)? onDelete;
  final Function(String)? onPin;
  final Function(String)? onMute;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
    this.onDelete,
    this.onPin,
    this.onMute,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(conversation.id),
      background: _buildSwipeBackground(context, isLeft: true),
      secondaryBackground: _buildSwipeBackground(context, isLeft: false),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          onDelete?.call(conversation.id);
        } else {
          onPin?.call(conversation.id);
        }
        return false;
      },
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: conversation.isPinned ? Colors.grey[100] : Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  _buildAvatar(),
                  if (conversation.type == 'private' &&
                      conversation.otherUserOnline == true)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
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

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.displayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: conversation.unreadCount > 0
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation.isPinned)
                          Icon(
                            Icons.push_pin,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        if (conversation.isMuted)
                          Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.volume_off,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getLastMessagePreview(),
                            style: TextStyle(
                              fontSize: 14,
                              color: conversation.unreadCount > 0
                                  ? Colors.black87
                                  : Colors.grey[600],
                              fontWeight: conversation.unreadCount > 0
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(width: 8),

              // Right side
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(conversation.updatedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: conversation.unreadCount > 0
                          ? Theme.of(context).primaryColor
                          : Colors.grey[600],
                      fontWeight: conversation.unreadCount > 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  SizedBox(height: 4),
                  if (conversation.unreadCount > 0)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        conversation.unreadCount > 99
                            ? '99+'
                            : conversation.unreadCount.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (conversation.displayAvatar.isEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: Colors.blue[100],
        child: Text(
          conversation.displayName[0].toUpperCase(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 28,
      backgroundImage: NetworkImage(conversation.displayAvatar),
      backgroundColor: Colors.grey[200],
    );
  }

  Widget _buildSwipeBackground(BuildContext context, {required bool isLeft}) {
    return Container(
      color: isLeft ? Colors.blue : Colors.red,
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Icon(isLeft ? Icons.push_pin : Icons.delete, color: Colors.white),
    );
  }

  String _getLastMessagePreview() {
    if (conversation.lastMessage == null) {
      return 'Chưa có tin nhắn';
    }

    final msg = conversation.lastMessage!;
    String prefix = '';

    if (msg.isMine) {
      prefix = 'Bạn: ';
    } else if (conversation.type == 'group') {
      prefix = '${msg.senderName}: ';
    }

    String content = '';
    switch (msg.type) {
      case 'text':
        content = msg.content;
        break;
      case 'image':
        content = '📷 Hình ảnh';
        break;
      case 'video':
        content = '🎥 Video';
        break;
      case 'audio':
        content = '🎵 Tin nhắn thoại';
        break;
      case 'file':
        content = '📎 ${msg.fileName ?? "Tệp"}';
        break;
      case 'sticker':
        content = '😊 Sticker';
        break;
      case 'location':
        content = '📍 Vị trí';
        break;
      default:
        content = msg.content;
    }

    if (msg.isDeleted) {
      content = 'Tin nhắn đã được thu hồi';
    }

    return prefix + content;
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(time);
    } else if (messageDate == yesterday) {
      return 'Hôm qua';
    } else if (now.difference(time).inDays < 7) {
      return DateFormat('EEEE', 'vi').format(time);
    } else {
      return DateFormat('dd/MM/yyyy').format(time);
    }
  }
}
