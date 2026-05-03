import 'package:flutter/material.dart';

class AppColors {
  // Bento Palette
  static const Color primary = Color(0xFFBAE6FD); // Friendly Light Blue
  static const Color secondary = Color(0xFF0EA5E9);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);
  static const Color surface = Color(0xFFF0F9FF);
  static const Color text = Color(0xFF111827);

  // Neutrals
  static const Color black = Color(0xFF000000);
  static const Color background = Color.fromARGB(255, 232, 236, 244);
  static const Color white = Colors.white;
  static const Color grey = Color(0xFF9CA3AF);
  static const Color greyLight = Color(0xFFE5E7EB);
  static const Color greyDark = Color(0xFF4B5563);

  // Gradients
  static const List<Color> primaryGradient = [
    Color(0xFFBAE6FD),
    Color(0xFF7DD3FC),
  ];
  static const List<Color> secondaryGradient = [
    Color(0xFF0EA5E9),
    Color(0xFF0284C7),
  ];
  static const List<Color> surfaceGradient = [
    Color(0xFFF0F9FF),
    Color(0xFFE0F2FE),
  ];
}
