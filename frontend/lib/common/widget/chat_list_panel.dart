import 'package:flutter/material.dart';
import 'package:frontend/common/config/app_colors.dart';
import 'package:frontend/common/widget/chat_filter_tabs.dart';
import 'package:frontend/common/widget/conversation_list.dart';
import 'package:frontend/common/widget/search_header.dart';
import 'package:frontend/utils/app_localizations.dart';

class ChatListPanel extends StatelessWidget {
  final bool isWide;
  final bool isDark;
  final AppLocalizations t;
  final TextEditingController controller;
  final Function(String) onSearchChanged;
  final List<Map<String, dynamic>> conversations;
  final Function(Map<String, dynamic>) onTap;
  final String filterMode;
  final Function(String)? onFilterChanged;

  const ChatListPanel({
    super.key,
    required this.isWide,
    required this.isDark,
    required this.t,
    required this.controller,
    required this.onSearchChanged,
    required this.conversations,
    required this.onTap,
    required this.filterMode,
    this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        SearchHeader(
          isDark: isDark,
          isMobile: !isWide,
          controller: controller,
          onChanged: onSearchChanged,
          t: t,
        ),

        if (isWide)
          FilterTabs(
            currentFilter: filterMode,
            onChanged: onFilterChanged!,
            isDark: isDark,
            t: t,
          ),

        Expanded(
          child: ConversationList(
            conversations: conversations,
            onTap: onTap,
            t: t,
            isDark: isDark,
          ),
        ),
      ],
    );

    if (!isWide) return content;

    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        border: Border(
          right: BorderSide(color: AppColors.getDivider(isDark)),
        ),
      ),
      child: content,
    );
  }
}