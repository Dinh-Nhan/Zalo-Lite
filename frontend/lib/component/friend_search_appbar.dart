import 'package:flutter/material.dart';
import 'package:frontend/config/app_colors.dart';

class FriendSearchAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final VoidCallback? onTap;

  const FriendSearchAppBar({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primaryBlue,
      elevation: 0,
      titleSpacing: 0,
      title: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(
                Icons.search,
                color: Colors.white70,
                size: 20,
              ),

              const SizedBox(width: 8),

              Text(
                'Tìm bạn bè',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.qr_code_scanner,
            color: Colors.white,
          ),
          onPressed: () {},
        ),
      ],
    );
  }

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight);
}