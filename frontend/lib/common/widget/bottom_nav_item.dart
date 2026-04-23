import 'package:flutter/material.dart';
import 'package:frontend/common/config/app_colors.dart';

class BottomNavItem extends StatelessWidget {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final int index;
  final bool isSelected;
  final bool isDark;
  final Function(int) onTap;

  const BottomNavItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.index,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => onTap(index),
      icon: Icon(
        isSelected ? activeIcon : inactiveIcon,
        color: isSelected
            ? AppColors.primaryBlue
            : AppColors.getTextSecondary(isDark),
        size: 26,
      ),
    );
  }
}