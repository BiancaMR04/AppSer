import 'package:flutter/material.dart';

abstract final class AppColors {
    // Global solid background (requested)
    static const Color appBackground = Color(0xFFF5F6F2);

    // Navbar
    static const Color navbarTitle = Color(0xFF2F7888);

  static const Color brandTeal = Color(0xFF00A896);

  static const Color primaryBlue = Color.fromARGB(255, 70, 148, 166);

  static const Color textDark = Color(0xFF4A6363);

  static const Color sessionIconMuted = Color.fromARGB(255, 136, 187, 185);

  static const Color successGreen = Color.fromARGB(255, 0, 136, 100);

  static const Color actionGreen = Color.fromARGB(255, 0, 129, 71);

  // Authentication
    static const Color authBackground = appBackground;
  static const Color authPrimary = Color(0xFF77C79C);
  static const Color authText = Color(0xFF293738);
  static const Color authLink = Color.fromARGB(255, 0, 107, 55);

  // Home session list
  static const Color sessionTileEnabledBg = Color.fromARGB(255, 175, 210, 208);
  static const Color sessionTileDisabledBg = Color.fromARGB(255, 224, 224, 224);
  static const Color sessionTileEnabledBorder =
      Color.fromARGB(255, 198, 231, 234);
  static const Color sessionTileDisabledBorder =
      Color.fromARGB(255, 201, 201, 201);

  static const Color sessionBadgeDisabledBg =
      Color.fromARGB(255, 209, 209, 209);
  static const Color sessionBadgeEnabledBorder =
      Color.fromARGB(255, 115, 202, 214);
  static const Color sessionBadgeDisabledBorder =
      Color.fromARGB(255, 231, 231, 231);

  static const Color sessionTileTitle = Color.fromARGB(255, 62, 73, 73);
  static const Color sessionDottedLine = Color.fromARGB(255, 241, 209, 208);
}
