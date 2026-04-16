import 'package:flutter/material.dart';

/// Bảng màu chính của ứng dụng Zalo Lite
class AppColors {
  // Màu chính Zalo
  static const Color primaryBlue = Color(0xFF0068FF);
  static const Color lightBlue = Color(0xFF4A9EFF);
  static const Color darkBlue = Color(0xFF0052CC);

  // Màu nền - Light
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF5F5F5);

  // Màu nền - Dark
  static const Color darkBackground = Color(0xFF1A1A2E);
  static const Color darkSurface = Color(0xFF242438);
  static const Color darkCard = Color(0xFF2D2D44);

  // Màu sidebar
  static const Color sidebarDark = Color(0xFF005AE0);
  static const Color sidebarLight = Color(0xFF0068FF);

  // Màu text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textBlue = Color(0xFF0068FF);

  // Màu text - Dark
  static const Color darkTextPrimary = Color(0xFFE4E6EB);
  static const Color darkTextSecondary = Color(0xFFB0B3B8);

  // Màu viền
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);
  static const Color darkDivider = Color(0xFF3A3A4D);

  //Call Color
  static const Color callRed = Color(0xFFE53935);
  static const Color callGreen = Color(0xFF4CAF50);
  static const Color callBackground = Color(0xFF1A1A1A);
  static const Color whiteOpacity = Colors.white24;

  // Helper methods
  static Color getBackground(bool isDark) => isDark ? darkBackground : backgroundWhite;
  static Color getSurface(bool isDark) => isDark ? darkSurface : backgroundWhite;
  static Color getTextPrimary(bool isDark) => isDark ? darkTextPrimary : textPrimary;
  static Color getTextSecondary(bool isDark) => isDark ? darkTextSecondary : textSecondary;
  static Color getDivider(bool isDark) => isDark ? darkDivider : divider;
}
