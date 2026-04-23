import 'package:flutter/material.dart';
import 'package:frontend/common/config/app_colors.dart';
import 'package:frontend/common/config/dark_mode_config.dart';
import 'package:frontend/utils/app_localizations.dart';

class SettingsPanel extends StatelessWidget {
  final AppLocalizations t;
  final bool isDark;
  final VoidCallback onLogout;
  final VoidCallback onChangeLanguage;

  const SettingsPanel({
    super.key,
    required this.t,
    required this.isDark,
    required this.onLogout,
    required this.onChangeLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.backgroundGray,
      child: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.getSurface(isDark),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.get('settings'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextPrimary(isDark),
                ),
              ),
              const SizedBox(height: 24),

              /// Dark mode
              SettingsItem(
                icon: isDark ? Icons.light_mode : Icons.dark_mode,
                title: t.get('darkMode'),
                subtitle: isDark ? t.get('darkModeOn') : t.get('darkModeOff'),
                isDark: isDark,
                trailing: Switch(
                  value: isDark,
                  onChanged: (value) => isDarkModeNotifier.value = value,
                  activeColor: AppColors.primaryBlue,
                ),
              ),

              const SizedBox(height: 16),

              /// Language
              SettingsItem(
                icon: Icons.language,
                title: t.get('language'),
                subtitle: t.displayName,
                isDark: isDark,
                onTap: onChangeLanguage,
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppColors.getTextSecondary(isDark),
                ),
              ),

              const SizedBox(height: 16),

              /// Logout
              SettingsItem(
                icon: Icons.logout,
                title: t.get('logout'),
                subtitle: t.get('logoutSubtitle'),
                isDark: isDark,
                onTap: onLogout,
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppColors.getTextSecondary(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.backgroundGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primaryBlue, size: 22),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.getTextPrimary(isDark),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                  ),
                ],
              ),
            ),

            if (trailing != null) ...[
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}