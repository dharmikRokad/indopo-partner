import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const Color blue1 = Color(0xFF38BDF8); // Sky blue
  static const Color blue2 = Color(0xFF1E40AF); // Royal/Indigo blue
  static const Color blue3 = Color(0xFF0F172A); // Dark navy
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFAB00);
  static const Color error  = Color(0xFFD50000);
  static const Color info   = Color(0xFF2979FF);
  static const Color surface = Color(0xFF1E293B); // Dark slate card surface
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  static const splashGradient = LinearGradient(
    colors: [blue1, blue2, blue3],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
