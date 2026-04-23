import 'package:flutter/material.dart';
import 'package:frontend/common/config/app_colors.dart';
import 'package:frontend/utils/app_localizations.dart';

class FilterTabs extends StatelessWidget {
  final String currentFilter;
  final Function(String) onChanged;
  final bool isDark;
  final AppLocalizations t;

  const FilterTabs({
    super.key,
    required this.currentFilter,
    required this.onChanged,
    required this.isDark,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: AppColors.getSurface(isDark),
      child: Row(
        children: [
          buildTab(t.get('all'), 'all'),
          const SizedBox(width: 16),
          buildTab(t.get('unread'), 'unread'),
          const Spacer(),
          PopupMenuButton<String>(
            offset: const Offset(0, 30),
            child: Row(
              children: [
                Text(
                  t.get('category'),
                  style: TextStyle(
                    color: AppColors.getTextSecondary(isDark),
                    fontSize: 13,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.getTextSecondary(isDark),
                  size: 18,
                ),
              ],
            ),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'all', child: Text(t.get('all'))),
              PopupMenuItem(value: 'friends', child: Text(t.get('friends'))),
              PopupMenuItem(value: 'groups', child: Text(t.get('groups'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildTab(String label, String value) {
    final isSelected = currentFilter == value;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected
              ? AppColors.primaryBlue
              : AppColors.getTextSecondary(isDark),
        ),
      ),
    );
  }
}