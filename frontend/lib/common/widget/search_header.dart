import 'package:flutter/material.dart';
import 'package:frontend/common/config/app_colors.dart';
import 'package:frontend/utils/app_localizations.dart';

class SearchHeader extends StatelessWidget {
  final bool isDark;
  final bool isMobile;
  final TextEditingController controller;
  final Function(String) onChanged;
  final AppLocalizations t;

  const SearchHeader({
    super.key,
    required this.isDark,
    required this.isMobile,
    required this.controller,
    required this.onChanged,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return isMobile
        ? _buildMobileHeader()
        : _buildDesktopHeader();
  }

  /// ================= MOBILE =================
  Widget _buildMobileHeader() {
    final Color bgColor =
        isDark ? const Color(0xFF1A1A1A) : AppColors.primaryBlue;

    final searchBg = isDark
        ? const Color(0xFF2A2A2A)
        : Colors.white.withValues(alpha: 0.25);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: bgColor,
      child: Row(
        children: [
          Expanded(
            child: _buildSearchBox(
              searchBg: searchBg,
              iconColor: Colors.white.withValues(alpha: 0.8),
              textColor: Colors.white,
              hintColor: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 8),

          _buildIconButton(
            Icons.qr_code_scanner,
            color: Colors.white,
          ),
          _buildIconButton(
            Icons.add,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  /// ================= DESKTOP =================
  Widget _buildDesktopHeader() {
    final searchBg =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.getSurface(isDark),
      child: Row(
        children: [
          Expanded(
            child: _buildSearchBox(
              searchBg: searchBg,
              iconColor: AppColors.getTextSecondary(isDark),
              textColor: AppColors.getTextPrimary(isDark),
              hintColor: AppColors.getTextSecondary(isDark),
            ),
          ),
          const SizedBox(width: 8),

          _buildIconButton(Icons.person_add_outlined),
          _buildIconButton(Icons.group_add_outlined),
        ],
      ),
    );
  }

  /// ================= SEARCH BOX =================
  Widget _buildSearchBox({
    required Color searchBg,
    required Color iconColor,
    required Color textColor,
    required Color hintColor,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: searchBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(Icons.search, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: t.get('searchPlaceholder'),
                hintStyle: TextStyle(
                  color: hintColor,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
    );
  }

  /// ================= ICON =================
  Widget _buildIconButton(
    IconData icon, {
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: color ?? AppColors.getTextSecondary(isDark),
            size: 20,
          ),
        ),
      ),
    );
  }
}