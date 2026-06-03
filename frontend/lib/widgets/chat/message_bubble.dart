import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/chat/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final Function(String emoji)? onReact;
  final VoidCallback? onReply;
  final VoidCallback? onForward;
  final VoidCallback? onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onInfo;

  const MessageBubble({
    super.key,
    required this.message,
    this.onReact,
    this.onReply,
    this.onForward,
    this.onCopy,
    this.onEdit,
    this.onDelete,
    this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showMessageActions(context),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          mainAxisAlignment: message.isMine
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!message.isMine) ...[
              CircleAvatar(
                radius: 16,
                backgroundImage: message.senderAvatar.isNotEmpty
                    ? NetworkImage(message.senderAvatar)
                    : null,
                backgroundColor: Colors.grey[300],
                child: message.senderAvatar.isEmpty
                    ? Text(
                        message.senderName[0].toUpperCase(),
                        style: TextStyle(fontSize: 12),
                      )
                    : null,
              ),
              SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: message.isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!message.isMine)
                    Padding(
                      padding: EdgeInsets.only(left: 12, bottom: 4),
                      child: Text(
                        message.senderName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      color: message.isMine
                          ? Color(0xFF0084FF)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(message.isMine ? 18 : 4),
                        bottomRight: Radius.circular(message.isMine ? 4 : 18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Reply preview
                        if (message.replyToMessageId != null)
                          _buildReplyPreview(),

                        // Message content
                        _buildMessageContent(context),

                        // Message info (time, status)
                        _buildMessageInfo(),
                      ],
                    ),
                  ),

                  // Reactions
                  if (message.reactions != null &&
                      message.reactions!.isNotEmpty)
                    _buildReactions(),

                  // Edited indicator
                  if (message.isEdited)
                    Padding(
                      padding: EdgeInsets.only(top: 2, left: 8, right: 8),
                      child: Text(
                        'Đã chỉnh sửa',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (message.isMine) SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: message.isMine
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: message.isMine ? Colors.white : Colors.blue,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.replyToSenderName ?? 'Unknown',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: message.isMine ? Colors.white : Colors.blue,
            ),
          ),
          SizedBox(height: 2),
          Text(
            message.replyToContent ?? '',
            style: TextStyle(
              fontSize: 12,
              color: message.isMine ? Colors.white70 : Colors.grey[700],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    if (message.isDeleted) {
      return Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.block,
              size: 16,
              color: message.isMine ? Colors.white70 : Colors.grey[600],
            ),
            SizedBox(width: 6),
            Text(
              'Tin nhắn đã được thu hồi',
              style: TextStyle(
                fontSize: 14,
                color: message.isMine ? Colors.white70 : Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    switch (message.type) {
      case 'text':
        return _buildTextMessage();
      case 'image':
        return _buildImageMessage(context);
      case 'video':
        return _buildVideoMessage(context);
      case 'audio':
        return _buildAudioMessage();
      case 'file':
        return _buildFileMessage();
      case 'sticker':
        return _buildStickerMessage();
      default:
        return _buildTextMessage();
    }
  }

  Widget _buildTextMessage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        message.content,
        style: TextStyle(
          fontSize: 15,
          color: message.isMine ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildImageMessage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.content.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 15,
                color: message.isMine ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            message.mediaUrl ?? '',
            width: 200,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 200,
                height: 200,
                color: Colors.grey[300],
                child: Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              width: 200,
              height: 200,
              color: Colors.grey[300],
              child: Icon(Icons.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoMessage(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            message.thumbnailUrl ?? '',
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 200,
                height: 200,
                color: Colors.grey[300],
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              width: 200,
              height: 200,
              color: Colors.grey[300],
              child: Icon(Icons.videocam, size: 48),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.play_arrow, color: Colors.white, size: 32),
        ),
        if (message.duration != null)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _formatDuration(message.duration!),
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAudioMessage() {
    return Container(
      padding: EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_circle_filled,
            color: message.isMine ? Colors.white : Colors.blue,
            size: 32,
          ),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tin nhắn thoại',
                style: TextStyle(
                  fontSize: 14,
                  color: message.isMine ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (message.duration != null)
                Text(
                  _formatDuration(message.duration!),
                  style: TextStyle(
                    fontSize: 12,
                    color: message.isMine ? Colors.white70 : Colors.grey[600],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFileMessage() {
    return Container(
      padding: EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: message.isMine
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.insert_drive_file,
              color: message.isMine ? Colors.white : Colors.blue,
              size: 24,
            ),
          ),
          SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.fileName ?? 'File',
                  style: TextStyle(
                    fontSize: 14,
                    color: message.isMine ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (message.fileSize != null)
                  Text(
                    _formatFileSize(message.fileSize!),
                    style: TextStyle(
                      fontSize: 12,
                      color: message.isMine ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickerMessage() {
    return Padding(
      padding: EdgeInsets.all(4),
      child: Image.network(
        message.mediaUrl ?? '',
        width: 120,
        height: 120,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 120,
          height: 120,
          color: Colors.grey[300],
          child: Icon(Icons.error),
        ),
      ),
    );
  }

  Widget _buildMessageInfo() {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('HH:mm').format(message.createdAt),
            style: TextStyle(
              fontSize: 11,
              color: message.isMine ? Colors.white70 : Colors.grey[600],
            ),
          ),
          if (message.isMine) ...[SizedBox(width: 4), _buildStatusIcon()],
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    switch (message.status) {
      case 'read':
        icon = Icons.done_all;
        color = Colors.blue[300]!;
        break;
      case 'delivered':
        icon = Icons.done_all;
        color = Colors.white70;
        break;
      default:
        icon = Icons.done;
        color = Colors.white70;
    }

    return Icon(icon, size: 14, color: color);
  }

  Widget _buildReactions() {
    return Container(
      margin: EdgeInsets.only(top: 4, left: 8, right: 8),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: message.reactions!.entries.map((entry) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                Text(entry.key, style: TextStyle(fontSize: 14)),
                if (entry.value.length > 1)
                  Text(
                    ' ${entry.value.length}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showMessageActions(BuildContext context) {
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
            // Emoji reactions
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['❤️', '👍', '😂', '😮', '😢', '😡'].map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      onReact?.call(emoji);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Text(emoji, style: TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
            ),
            Divider(),

            // Actions
            _buildActionTile(
              icon: Icons.reply,
              title: 'Trả lời',
              onTap: () {
                Navigator.pop(context);
                onReply?.call();
              },
            ),
            _buildActionTile(
              icon: Icons.forward,
              title: 'Chuyển tiếp',
              onTap: () {
                Navigator.pop(context);
                onForward?.call();
              },
            ),
            _buildActionTile(
              icon: Icons.copy,
              title: 'Sao chép',
              onTap: () {
                Navigator.pop(context);
                onCopy?.call();
              },
            ),
            if (message.isMine && message.type == 'text') ...[
              _buildActionTile(
                icon: Icons.edit,
                title: 'Chỉnh sửa',
                onTap: () {
                  Navigator.pop(context);
                  onEdit?.call();
                },
              ),
              _buildActionTile(
                icon: Icons.delete,
                title: 'Thu hồi',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
              ),
            ],
            _buildActionTile(
              icon: Icons.info_outline,
              title: 'Thông tin',
              onTap: () {
                Navigator.pop(context);
                onInfo?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
