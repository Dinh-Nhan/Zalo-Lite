import 'package:flutter/material.dart';
import 'package:frontend/apps/app_locale.dart';
import 'package:frontend/utils/app_localizations.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/dark_mode_config.dart';

/// Dialog cài đặt giống Zalo Web
class SettingsDialog extends StatefulWidget {
  final int initialTabIndex;
  final VoidCallback? onLogout;

  const SettingsDialog({super.key, this.initialTabIndex = 0, this.onLogout});

  static void show(BuildContext context, {int initialTabIndex = 0, VoidCallback? onLogout}) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => SettingsDialog(initialTabIndex: initialTabIndex, onLogout: onLogout),
    );
  }
  
  /// Mở Settings Dialog tại tab Appearance (Dark Mode)
  static void showAppearance(BuildContext context) {
    show(context, initialTabIndex: 1);
  }

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late int _selectedMenuIndex;

  @override
  void initState() {
    super.initState();
    _selectedMenuIndex = widget.initialTabIndex;
  }

  final List<_SettingsMenuItem> _menuItems = [
    _SettingsMenuItem(icon: Icons.settings_outlined, label: 'generalSettings'),
    _SettingsMenuItem(icon: Icons.palette_outlined, label: 'appearance'),
    _SettingsMenuItem(icon: Icons.language, label: 'language'),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, _) {
        return ValueListenableBuilder(
          valueListenable: localeNotifier,
          builder: (context, locale, _) {
            final t = AppLocalizations(locale);
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: 680,
                height: 480,
                decoration: BoxDecoration(
                  color: AppColors.getSurface(isDark),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // Header
                    _buildHeader(t, isDark),
                    // Content
                    Expanded(
                      child: Row(
                        children: [
                          // Left menu
                          _buildLeftMenu(t, isDark),
                          // Divider
                          Container(
                            width: 1,
                            color: AppColors.getDivider(isDark),
                          ),
                          // Right content
                          Expanded(
                            child: _buildContent(t, isDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(AppLocalizations t, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.getDivider(isDark)),
        ),
      ),
      child: Row(
        children: [
          Text(
            t.get('settings'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close,
              color: AppColors.getTextSecondary(isDark),
              size: 22,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftMenu(AppLocalizations t, bool isDark) {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: isDark ? const Color(0xFF1A1A1A) : null,
      child: Column(
        children: [
          ...List.generate(_menuItems.length, (index) {
            final item = _menuItems[index];
            final isSelected = _selectedMenuIndex == index;
            return _buildMenuItem(
              icon: item.icon,
              label: t.get(item.label),
              isSelected: isSelected,
              isDark: isDark,
              onTap: () => setState(() => _selectedMenuIndex = index),
            );
          }),
          const Spacer(),
          // Logout button
          _buildMenuItem(
            icon: Icons.logout,
            label: t.get('logout'),
            isSelected: false,
            isDark: isDark,
            isLogout: true,
            onTap: () {
              Navigator.pop(context);

              if (widget.onLogout != null) {
                widget.onLogout!();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isDark,
    bool isLogout = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? AppColors.darkCard : AppColors.backgroundGray)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isLogout 
                  ? Colors.red 
                  : (isSelected 
                      ? AppColors.primaryBlue 
                      : AppColors.getTextSecondary(isDark)),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isLogout 
                    ? Colors.red 
                    : (isSelected 
                        ? AppColors.primaryBlue 
                        : AppColors.getTextPrimary(isDark)),
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations t, bool isDark) {
    switch (_selectedMenuIndex) {
      case 0:
        return _buildGeneralSettings(t, isDark);
      case 1:
        return _buildAppearanceSettings(t, isDark);
      case 2:
        return _buildLanguageSettings(t, isDark);
      default:
        return const SizedBox();
    }
  }

  Widget _buildGeneralSettings(AppLocalizations t, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.get('generalSettings'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            t.get('generalSettingsDesc'),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getTextSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSettings(AppLocalizations t, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.get('appearance'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.get('appearanceDesc'),
            style: TextStyle(
              fontSize: 13,
              color: AppColors.getTextSecondary(isDark),
            ),
          ),
          const SizedBox(height: 24),
          
          // Light mode option
          _buildAppearanceOption(
            title: t.get('lightMode'),
            isSelected: !isDark,
            isDark: isDark,
            onTap: () => setDarkMode(false),
          ),
          const SizedBox(height: 12),
          
          // Dark mode option
          _buildAppearanceOption(
            title: t.get('darkMode'),
            isSelected: isDark,
            isDark: isDark,
            onTap: () => setDarkMode(true),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceOption({
    required String title,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.getDivider(isDark),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.getTextPrimary(isDark),
                ),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primaryBlue : AppColors.getDivider(isDark),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSettings(AppLocalizations t, bool isDark) {
    final currentLang = AppLocalizations(localeNotifier.value).displayName;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.get('language'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 24),
          
          // Language selector - vertical layout
          Text(
            t.get('changeLanguage'),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              border: Border.all(color: AppColors.getDivider(isDark)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButton<String>(
              value: currentLang,
              underline: const SizedBox(),
              isDense: true,
              dropdownColor: isDark ? AppColors.darkCard : Colors.white,
              icon: Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.getTextPrimary(isDark)),
              items: AppLocalizations.supportedLanguages.map((lang) {
                return DropdownMenuItem(
                  value: lang,
                  child: Text(
                    lang,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.getTextPrimary(isDark),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  localeNotifier.value = AppLocalizations.localeFromDisplayName(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsMenuItem {
  final IconData icon;
  final String label;

  _SettingsMenuItem({required this.icon, required this.label});
}
