import 'package:flutter/material.dart';

/// Avatar tròn có badge online, dùng chung khắp màn hình bạn bè.
class FriendAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double radius;
  final bool? isOnline;
  final Color? backgroundColor;

  const FriendAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.radius = 22,
    this.isOnline,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor ?? _colorFromName(name),
          backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
              ? NetworkImage(avatarUrl!)
              : null,
          child: avatarUrl == null || avatarUrl!.isEmpty
              ? Text(
                  _initials(name),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: radius * 0.6,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
        ),
        if (isOnline != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.55,
              height: radius * 0.55,
              decoration: BoxDecoration(
                color: isOnline!
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF9E9E9E),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  String _initials(String n) {
    final parts = n.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return n.isNotEmpty ? n[0].toUpperCase() : '?';
  }

  Color _colorFromName(String n) {
    const colors = [
      Color(0xFF4CAF50),
      Color(0xFF2196F3),
      Color(0xFFE91E63),
      Color(0xFF9C27B0),
      Color(0xFFFF9800),
      Color(0xFF00BCD4),
      Color(0xFF795548),
      Color(0xFF607D8B),
      Color(0xFFFF5722),
      Color(0xFF3F51B5),
    ];
    return colors[n.codeUnitAt(0) % colors.length];
  }
}
