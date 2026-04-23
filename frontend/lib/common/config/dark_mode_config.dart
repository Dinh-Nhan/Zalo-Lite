import 'package:flutter/material.dart';

/// Dark mode notifier - quản lý trạng thái dark mode toàn app
final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier<bool>(false);

/// Toggle dark mode
void toggleDarkMode() {
  isDarkModeNotifier.value = !isDarkModeNotifier.value;
}

/// Set dark mode
void setDarkMode(bool value) {
  isDarkModeNotifier.value = value;
}
