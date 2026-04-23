import 'package:flutter/material.dart';
import 'package:frontend/common/config/app_colors.dart';
import 'package:frontend/utils/app_localizations.dart';

class ConversationTile extends StatelessWidget {
  final Map<String, dynamic> conversation;
  final VoidCallback onTap;
  final AppLocalizations t;
  final bool isDark;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
    required this.t,
    required this.isDark,
  });

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatTimeAgo(int value, String unit) {
    if (unit == 'minutes') {
      return t.isVietnamese ? '$value phút' : '$value min';
    } else if (unit == 'hours') {
      return t.isVietnamese ? '$value giờ' : '$value hr';
    } else if (unit == 'days') {
      return t.isVietnamese ? '$value ngày' : '$value d';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final String name = conversation['name'];
    final Color avatarColor = conversation['avatarColor'];
    final String messageKey = conversation['lastMessageKey'] ?? '';
    final String messageContent = conversation['lastMessageContent'] ?? '';
    final int timeValue = conversation['lastMessageTimeValue'] ?? 0;
    final String timeUnit = conversation['lastMessageTimeUnit'] ?? '';
    final int unreadCount = conversation['unreadCount'];
    final bool isGroup = conversation['isGroup'] ?? false;
    final int? memberCount = conversation['memberCount'];

    final String lastMessage = messageKey.isNotEmpty
        ? '${t.get(messageKey)} $messageContent'
        : messageContent;

    final String lastMessageTime = _formatTimeAgo(timeValue, timeUnit);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: avatarColor,
                  child: Text(
                    _getInitials(name),
                    style: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isGroup && memberCount != null)
                  Positioned(
                    left: -4,
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.getSurface(isDark),
                          width: 2,
                        ),
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
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: AppColors.getTextPrimary(isDark),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lastMessageTime.isNotEmpty)
                        Text(
                          lastMessageTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.getTextSecondary(isDark),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}