import 'package:flutter/material.dart';
import 'package:frontend/common/widget/conversation_tile.dart';
import 'package:frontend/utils/app_localizations.dart';

class ConversationList extends StatelessWidget {
  final List<Map<String, dynamic>> conversations;
  final Function(Map<String, dynamic>) onTap;
  final AppLocalizations t;
  final bool isDark;

  const ConversationList({
    super.key,
    required this.conversations,
    required this.onTap,
    required this.t,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conv = conversations[index];

        return ConversationTile(
          conversation: conv,
          t: t,
          isDark: isDark,
          onTap: () => onTap(conv),
        );
      },
    );
  }
}