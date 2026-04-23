import 'package:flutter/material.dart';
import 'package:frontend/common/config/app_colors.dart';
import 'package:frontend/common/widget/bottom_nav_item.dart';

class BottomNavigation extends StatelessWidget {
  final bool isDark;
  final int selectedIndex;
  final Function(int) onItemSelected;

  const BottomNavigation({
    super.key,
    required this.isDark,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : AppColors.getSurface(isDark),
        border: Border(
          top: BorderSide(
            color: AppColors.getDivider(isDark),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              BottomNavItem(
                activeIcon: Icons.chat_bubble,
                inactiveIcon: Icons.chat_bubble_outline,
                index: 0,
                isSelected: selectedIndex == 0,
                isDark: isDark,
                onTap: onItemSelected,
              ),
              BottomNavItem(
                activeIcon: Icons.contacts,
                inactiveIcon: Icons.contacts_outlined,
                index: 1,
                isSelected: selectedIndex == 1,
                isDark: isDark,
                onTap: onItemSelected,
              ),
              BottomNavItem(
                activeIcon: Icons.auto_stories,
                inactiveIcon: Icons.auto_stories_outlined,
                index: 2,
                isSelected: selectedIndex == 2,
                isDark: isDark,
                onTap: onItemSelected,
              ),
              BottomNavItem(
                activeIcon: Icons.person,
                inactiveIcon: Icons.person_outline,
                index: 3,
                isSelected: selectedIndex == 3,
                isDark: isDark,
                onTap: onItemSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}