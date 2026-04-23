import 'package:flutter/material.dart';
import 'package:frontend/common/config/app_colors.dart';
import 'package:frontend/utils/app_localizations.dart';

class WelcomePanel extends StatelessWidget {
  final AppLocalizations t;
  final bool isDark;
  final VoidCallback onOpenAppearance;

  const WelcomePanel({
    super.key,
    required this.t,
    required this.isDark,
    required this.onOpenAppearance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.backgroundGray,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              t.get('welcomeTitle'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimary(isDark),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                t.get('welcomeDescription'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.getTextSecondary(isDark),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 40),

            /// Card
            Container(
              width: 320,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.getSurface(isDark),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A1A2E), Color(0xFF2D2D44)],
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.dark_mode, size: 48, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    t.get('darkModeTitle'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    t.get('darkModeDescription'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: onOpenAppearance,
                    child: Text(t.get('tryNow')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}