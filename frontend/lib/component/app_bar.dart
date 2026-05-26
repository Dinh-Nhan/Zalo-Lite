import 'package:flutter/material.dart';

// Header xanh chuẩn Zalo
class ZaloAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final bool showBackButton;

  const ZaloAppBar({super.key, required this.title, this.actions, this.showBackButton = false});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF0088FF),
      leading: showBackButton ? const BackButton(color: Colors.white) : const Icon(Icons.search, color: Colors.white),
      titleSpacing: 0,
      title: title,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// Item dòng trong danh sách (Dùng cho cả Bạn bè, Nhóm)
class ZaloItemTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const ZaloItemTile({super.key, required this.leading, required this.title, this.subtitle, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: leading,
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
      subtitle: subtitle != null ? Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
      trailing: trailing,
    );
  }
}