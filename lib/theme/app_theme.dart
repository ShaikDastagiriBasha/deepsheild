import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundColor = Color(0xFF081120);
  static const Color cardColor = Color(0xFF0F172A);
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color primaryAccent = Color(0xFF60A5FA);
  static const Color successColor = Colors.greenAccent;
  static const Color errorColor = Colors.redAccent;

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundColor,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      surface: cardColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
    ),
  );
}

extension ColorUtils on Color {
  Color withOpacityVal(double opacity) {
    return withValues(alpha: opacity);
  }
}
