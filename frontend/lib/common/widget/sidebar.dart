import 'package:flutter/material.dart';
import 'package:frontend/common/config/app_colors.dart';
import 'package:frontend/common/widget/sidebar_item.dart';

class Sidebar extends StatelessWidget {
  final bool isDark;
  final int selectedIndex;
  final Function(int) onItemSelected;
  final VoidCallback onOpenSettings;

  const Sidebar({
    super.key,
    required this.isDark,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      color: isDark ? const Color(0xFF1A1A1A) : AppColors.sidebarDark,
      child: Column(
        children: [
          const SizedBox(height: 12),

          /// Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const CircleAvatar(
              backgroundColor: Color(0xFF4CAF50),
              child: Text(
                'U',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// Chat
          SidebarItem(
            icon: Icons.chat_bubble,
            isSelected: selectedIndex == 0,
            onTap: () => onItemSelected(0),
          ),

          /// Contacts
          SidebarItem(
            icon: Icons.contacts_outlined,
            isSelected: selectedIndex == 2,
            onTap: () => onItemSelected(2),
          ),

          const Spacer(),

          /// Settings
          SidebarItem(
            icon: Icons.settings_outlined,
            isSelected: false,
            onTap: onOpenSettings,
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}