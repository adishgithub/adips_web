import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Small, width-limited snackbars for desktop. Use these for every
/// success / error / info message instead of calling Get.snackbar directly.
class AdipsToast {
  AdipsToast._();

  static void success(String message) =>
      _show('Success', message, const Color(0xFF1D7A4F), Icons.check_circle_outline);

  static void error(String message) =>
      _show('Something went wrong', message, const Color(0xFFC0392B), Icons.error_outline);

  static void info(String message) =>
      _show('Notice', message, const Color(0xFF2C5282), Icons.info_outline);

  static void _show(String title, String message, Color color, IconData icon) {
    if (Get.context == null) return;
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      maxWidth: 420,
      margin: const EdgeInsets.all(16),
      backgroundColor: color,
      colorText: Colors.white,
      icon: Icon(icon, color: Colors.white),
      duration: const Duration(seconds: 4),
    );
  }
}
