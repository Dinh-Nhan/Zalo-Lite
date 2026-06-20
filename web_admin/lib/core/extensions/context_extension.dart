import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// ============================================================
// CORE - Context Extensions
// ============================================================

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  bool get isDesktop => screenWidth >= 1200;
  bool get isTablet => screenWidth >= 768 && screenWidth < 1200;
  bool get isMobile => screenWidth < 768;

  void showSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline
                  : isSuccess
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
              color: isError
                  ? AppColors.error
                  : isSuccess
                      ? AppColors.success
                      : AppColors.info,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
