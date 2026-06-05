import 'package:flutter/material.dart';

// Widget cho từng dòng trong danh bạ/nhóm
class ZaloListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget leading;
  final List<Widget>? trailing;
  final VoidCallback? onTap;

  const ZaloListTile({
<<<<<<< HEAD
    super.key,
=======
>>>>>>> origin/dev
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: leading,
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
      subtitle: subtitle != null ? Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
      trailing: trailing != null ? Row(mainAxisSize: MainAxisSize.min, children: trailing!) : null,
    );
  }
}

// Avatar có bo góc hoặc tròn
class ZaloAvatar extends StatelessWidget {
  final String imageUrl;
  final bool isGroup;
<<<<<<< HEAD
  const ZaloAvatar({super.key, required this.imageUrl, this.isGroup = false});
=======
  const ZaloAvatar({required this.imageUrl, this.isGroup = false});
>>>>>>> origin/dev

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundImage: NetworkImage(imageUrl),
      backgroundColor: Colors.grey[200],
    );
  }
}