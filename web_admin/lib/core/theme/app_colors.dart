import 'package:flutter/material.dart';

// ============================================================
// CORE - App Colors (Minimal Dark Mode Palette)
// ============================================================

class AppColors {
  AppColors._();

  // --- Primary Brand ---
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF8B85FF);
  static const Color primaryDark = Color(0xFF4A42D8);
  static const Color primaryContainer = Color(0xFF1E1A3E);

  // --- Background ---
  static const Color background = Color(0xFF0F1117);
  static const Color surface = Color(0xFF1A1D27);
  static const Color surfaceVariant = Color(0xFF21263A);
  static const Color surfaceElevated = Color(0xFF252A3E);

  // --- Sidebar ---
  static const Color sidebar = Color(0xFF13151F);
  static const Color sidebarSelected = Color(0xFF1E1A3E);

  // --- Text ---
  static const Color textPrimary = Color(0xFFE8EAF0);
  static const Color textSecondary = Color(0xFF9BA3BF);
  static const Color textMuted = Color(0xFF5A6080);
  static const Color textInverse = Color(0xFF0F1117);

  // --- Border ---
  static const Color border = Color(0xFF2A2F45);
  static const Color borderLight = Color(0xFF353A55);

  // --- Status Colors ---
  static const Color success = Color(0xFF22C55E);
  static const Color successContainer = Color(0xFF0F2E1A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFF2E1F0A);
  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFF2E0F0F);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoContainer = Color(0xFF0F1E2E);

  // --- Chart Colors ---
  static const Color chart1 = Color(0xFF6C63FF);
  static const Color chart2 = Color(0xFF22C55E);
  static const Color chart3 = Color(0xFFF59E0B);
  static const Color chart4 = Color(0xFFEF4444);
  static const Color chart5 = Color(0xFF3B82F6);

  // --- Gradients ---
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
  );

  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
  );

  static const LinearGradient infoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
  );
}
