import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/chat/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool showAvatar;
  final bool showSenderName;
  final bool showMeta;
  final bool isGroupTop;
  final bool isGroupMiddle;
  final bool isGroupBottom;
  final bool highlighted;
  final bool replyToIsMine;        // true → hiện "Tôi" thay vì tên gửi
  final VoidCallback? onReplyPreviewTap;
  final Function(String emoji)? onReact;
  final VoidCallback? onReply;
  final VoidCallback? onForward;
  final VoidCallback? onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;       // Gỡ tin cho tất cả (sender only)
  final VoidCallback? onHideForMe;    // Xóa ở phía mình (bất kỳ ai)
  final VoidCallback? onInfo;

  const MessageBubble({
    super.key,
    required this.message,
    this.showAvatar = true,
    this.showSenderName = false,
    this.showMeta = true,
    this.isGroupTop = false,
    this.isGroupMiddle = false,
    this.isGroupBottom = false,
    this.highlighted = false,
    this.replyToIsMine = false,
    this.onReplyPreviewTap,
    this.onReact,
    this.onReply,
    this.onForward,
    this.onCopy,
    this.onEdit,
    this.onDelete,
    this.onHideForMe,
    this.onInfo,
  });

  static const _zaloBlue    = Color(0xFF0068FF);  // sender bg
  static const _receivedBg     = Color(0xFFFFFFFF);
  static const _receivedBorder = Color(0xFFE8E8E8);

  @override
  Widget build(BuildContext context) {
    // Spacing dày hơn khi bắt đầu nhóm mới, mỏng khi cùng nhóm
    final topPad = (isGroupBottom || isGroupMiddle) ? 1.0 : 6.0;
    final bottomPad = showMeta ? 1.0 : 1.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      color: highlighted
          ? const Color(0xFFD6E8FF) // xanh nhạt rõ trên nền xám
          : Colors.transparent,
      child: GestureDetector(
        onLongPress: () => _showMessageActions(context),
        child: Padding(
          padding: EdgeInsets.fromLTRB(10, topPad, 10, bottomPad),
        child: Row(
          mainAxisAlignment:
              message.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!message.isMine) ...[
              // Avatar chỉ hiện ở tin CUỐI nhóm
              showAvatar ? _buildAvatar() : const SizedBox(width: 28),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: message.isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!message.isMine && showSenderName)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 3),
                      child: Text(
                        message.senderName,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF666666),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  _buildBubble(),
                  if (showMeta) ...[
                    const SizedBox(height: 2),
                    _buildMetaRow(),
                  ],
                  if (message.reactions != null &&
                      message.reactions!.isNotEmpty)
                    _buildReactions(),
                ],
              ),
            ),
            if (message.isMine) const SizedBox(width: 4),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 14,
      backgroundColor: const Color(0xFFCCCCCC),
      backgroundImage: message.senderAvatar.isNotEmpty
          ? NetworkImage(message.senderAvatar)
          : null,
      child: message.senderAvatar.isEmpty
          ? Text(
              message.senderName.isNotEmpty
                  ? message.senderName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            )
          : null,
    );
  }

  Widget _buildBubble() {
    final isMine = message.isMine;

    // Góc nhỏ (5) ở phía nối với tin trước/sau cùng nhóm
    const r = Radius.circular(18);
    const rSmall = Radius.circular(5);
    final radius = isMine
        ? BorderRadius.only(
            topLeft: r,
            topRight: isGroupBottom || isGroupMiddle ? rSmall : r,
            bottomLeft: r,
            bottomRight: isGroupTop || isGroupMiddle ? rSmall : rSmall,
          )
        : BorderRadius.only(
            topLeft: isGroupBottom || isGroupMiddle ? rSmall : r,
            topRight: r,
            bottomLeft: isGroupTop || isGroupMiddle ? rSmall : rSmall,
            bottomRight: r,
          );

    if (message.isDeleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: radius,
          border: Border.all(color: const Color(0xFFDDDDDD)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.remove_circle_outline,
                size: 14, color: Colors.grey[500]),
            const SizedBox(width: 5),
            Text(
              'Tin nhắn đã được thu hồi',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isMine ? _zaloBlue : _receivedBg,
        borderRadius: radius,
        border: isMine ? null : Border.all(color: _receivedBorder, width: 0.5),
        boxShadow: isMine
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.replyToMessageId != null) _buildReplyPreview(),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (message.type) {
      case 'image':
        return _buildImageContent();
      case 'video':
        return _buildVideoContent();
      case 'audio':
        return _buildAudioContent();
      case 'file':
        return _buildFileContent();
      case 'sticker':
        return _buildStickerContent();
      case 'call':
        return _buildCallContent();
      default:
        return _buildTextContent();
    }
  }

  Widget _buildTextContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      child: Text(
        message.content,
        style: TextStyle(
          fontSize: 14.5,
          color: message.isMine ? Colors.white : const Color(0xFF1A1A1A),
          height: 1.35,
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        message.mediaUrl ?? '',
        width: 220,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 220,
          height: 180,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 220,
            height: 180,
            color: Colors.grey[300],
            child: message.thumbnailUrl != null
                ? Image.network(message.thumbnailUrl!, fit: BoxFit.cover)
                : const Icon(Icons.videocam, size: 48, color: Colors.grey),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Colors.black45,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
        ),
      ],
    );
  }

  Widget _buildAudioContent() {
    final iconColor = message.isMine ? Colors.white : _zaloBlue;
    final textColor = message.isMine ? Colors.white : Colors.black87;
    final subColor  = message.isMine ? Colors.white70 : Colors.grey[600]!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_circle_fill, color: iconColor, size: 30),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tin nhắn thoại',
                  style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w500)),
              if (message.duration != null)
                Text(_formatDuration(message.duration!),
                    style: TextStyle(fontSize: 11, color: subColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFileContent() {
    final iconBg    = message.isMine ? Colors.white.withValues(alpha: 0.2) : _zaloBlue.withValues(alpha: 0.1);
    final iconColor = message.isMine ? Colors.white : _zaloBlue;
    final textColor = message.isMine ? Colors.white : Colors.black87;
    final subColor  = message.isMine ? Colors.white70 : Colors.grey[600]!;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.insert_drive_file_outlined, color: iconColor, size: 22),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.fileName ?? 'Tệp đính kèm',
                  style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (message.fileSize != null)
                  Text(_formatFileSize(message.fileSize!),
                      style: TextStyle(fontSize: 11, color: subColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallContent() {
    final isMissed = message.content.contains('nhỡ') || message.content.contains('từ chối');
    final isVideo  = message.content.contains('video');

    // Sender (nền xanh): trắng cho tất cả — đỏ không đọc được trên nền xanh
    // Receiver (nền xám): đỏ cho nhỡ/từ chối, xanh cho bình thường
    final Color iconColor;
    final Color textColor;
    if (message.isMine) {
      iconColor = Colors.white;
      textColor = Colors.white;
    } else {
      iconColor = isMissed ? Colors.red.shade400 : _zaloBlue;
      textColor = isMissed ? Colors.red.shade400 : const Color(0xFF1A1A1A);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isVideo ? Icons.videocam_rounded : Icons.call_rounded,
              color: iconColor, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(message.content,
                style: TextStyle(fontSize: 14, color: textColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildStickerContent() {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Image.network(
        message.mediaUrl ?? '',
        width: 100,
        height: 100,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            const SizedBox(width: 100, height: 100),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return GestureDetector(
      onTap: onReplyPreviewTap,
      child: _buildReplyPreviewContent(),
    );
  }

  Widget _buildReplyPreviewContent() {
    // Sender (xanh): preview nền trắng mờ, viền trắng
    // Receiver (xám): preview nền trắng nhạt, viền xanh
    final bgColor     = message.isMine ? Colors.white.withValues(alpha: 0.18) : const Color(0xFFF0F4FF);
    final borderColor = message.isMine ? Colors.white60 : _zaloBlue;
    final nameColor   = message.isMine ? Colors.white : _zaloBlue;
    final bodyColor   = message.isMine ? Colors.white70 : Colors.grey[700]!;

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: borderColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replyToIsMine ? 'Tôi' : (message.replyToSenderName ?? ''),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: nameColor),
          ),
          const SizedBox(height: 2),
          Text(
            message.replyToContent ?? '',
            style: TextStyle(fontSize: 12, color: bodyColor),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow() {
    return Padding(
      padding: EdgeInsets.only(
        left: message.isMine ? 0 : 4,
        right: message.isMine ? 4 : 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('HH:mm').format(message.createdAt),
            style: const TextStyle(fontSize: 10, color: Color(0xFFAAAAAA)),
          ),
          if (message.isMine) ...[
            const SizedBox(width: 3),
            _buildStatusIcon(),
          ],
          if (message.isEdited) ...[
            const SizedBox(width: 4),
            const Text('• đã sửa',
                style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFFAAAAAA),
                    fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (message.status) {
      case 'read':
        return const Icon(Icons.done_all, size: 13, color: _zaloBlue);
      case 'delivered':
        return Icon(Icons.done_all, size: 13, color: Colors.grey[400]);
      default:
        return Icon(Icons.done, size: 13, color: Colors.grey[400]);
    }
  }

  Widget _buildReactions() {
    return Container(
      margin: EdgeInsets.only(
        top: 3,
        left: message.isMine ? 0 : 4,
        right: message.isMine ? 4 : 0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: message.reactions!.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Row(
              children: [
                Text(e.key, style: const TextStyle(fontSize: 13)),
                if (e.value.length > 1)
                  Text(' ${e.value.length}',
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF888888))),
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
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Quick reactions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['❤️', '👍', '😂', '😮', '😢', '😡'].map((e) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onReact?.call(e);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                          child: Text(e,
                              style: const TextStyle(fontSize: 22))),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            _actionTile(Icons.reply_rounded, 'Trả lời', () {
              Navigator.pop(context);
              onReply?.call();
            }),
            _actionTile(Icons.shortcut_rounded, 'Chuyển tiếp', () {
              Navigator.pop(context);
              onForward?.call();
            }),
            _actionTile(Icons.copy_rounded, 'Sao chép', () {
              Navigator.pop(context);
              onCopy?.call();
            }),
            if (message.isMine && message.type == 'text')
              _actionTile(Icons.edit_rounded, 'Chỉnh sửa', () {
                Navigator.pop(context);
                onEdit?.call();
              }),
            _actionTile(Icons.info_outline_rounded, 'Thông tin', () {
              Navigator.pop(context);
              onInfo?.call();
            }),
            // Xóa ở phía mình — ai cũng có thể làm
            _actionTile(Icons.delete_outline_rounded, 'Xóa ở phía bạn', () {
              Navigator.pop(context);
              onHideForMe?.call();
            }, color: Colors.red),
            // Gỡ tin cho tất cả — chỉ người gửi và tin chưa bị gỡ
            if (message.isMine && !message.isDeleted)
              _actionTile(Icons.remove_circle_outline_rounded, 'Gỡ tin nhắn', () {
                Navigator.pop(context);
                onDelete?.call();
              }, color: Colors.red),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    final c = color ?? const Color(0xFF333333);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: c, size: 22),
            const SizedBox(width: 16),
            Text(label,
                style: TextStyle(
                    fontSize: 15, color: c, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
