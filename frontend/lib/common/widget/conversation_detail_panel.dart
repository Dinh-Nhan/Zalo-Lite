import 'package:flutter/material.dart';
import 'package:frontend/common/widget/welcome_panel_widget.dart';
import 'package:frontend/utils/app_localizations.dart';
import 'package:frontend/views/chat/chat_detail_view.dart';

class ConversationDetailPanel extends StatelessWidget {
  final Map<String, dynamic>? conversation;
  final AppLocalizations t;
  final bool isDark;
  final VoidCallback onOpenAppearance;

  const ConversationDetailPanel({
    super.key,
    required this.conversation,
    required this.t,
    required this.isDark,
    required this.onOpenAppearance,
  });

  @override
  Widget build(BuildContext context) {
    if (conversation == null) {
      return WelcomePanel(
        t: t,
        isDark: isDark,
        onOpenAppearance: onOpenAppearance,
      );
    }

    return ChatDetailView(
      conversationId: conversation!['id'],
      contactName: conversation!['name'],
      avatarColor: conversation!['avatarColor'],
      isGroup: conversation!['isGroup'] ?? false,
      memberCount: conversation!['memberCount'],
      showBackButton: false,
    );
  }
}