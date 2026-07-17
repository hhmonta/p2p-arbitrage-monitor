import 'package:flutter/material.dart';

/// App theme configuration with dark and light modes
class AppTheme {
  AppTheme._();

  // Color constants
  static const Color _primaryColor = Color(0xFF6C63FF);
  static const Color _accentColor = Color(0xFF00E676);
  static const Color _dangerColor = Color(0xFFFF5252);
  static const Color _warningColor = Color(0xFFFFD740);
  static const Color _infoColor = Color(0xFF448AFF);

  // Dark theme colors
  static const Color _darkBg = Color(0xFF0D1117);
  static const Color _darkSurface = Color(0xFF161B22);
  static const Color _darkCard = Color(0xFF1C2333);
  static const Color _darkBorder = Color(0xFF30363D);
  static const Color _darkText = Color(0xFFE6EDF3);
  static const Color _darkTextSecondary = Color(0xFF8B949E);

  // Light theme colors
  static const Color _lightBg = Color(0xFFF6F8FA);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _lightBorder = Color(0xFFD0D7DE);
  static const Color _lightText = Color(0xFF1F2328);
  static const Color _lightTextSecondary = Color(0xFF656D76);

  // Exchange brand colors
  static const Color binanceColor = Color(0xFFF0B90B);
  static const Color bybitColor = Color(0xFFF7A600);
  static const Color bingxColor = Color(0xFF00D4AA);

  /// Get exchange color
  static Color getExchangeColor(String exchange) {
    switch (exchange) {
      case 'Binance': return binanceColor;
      case 'Bybit': return bybitColor;
      case 'BingX': return bingxColor;
      default: return _primaryColor;
    }
  }

  /// Get spread color based on value
  static Color getSpreadColor(double spread) {
    if (spread > 3) return _accentColor;
    if (spread > 1.5) return const Color(0xFF64DD17);
    if (spread > 0.5) return _warningColor;
    if (spread > 0) return const Color(0xFFFF9100);
    return _dangerColor;
  }

  /// Dark theme
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: _primaryColor,
      secondary: _accentColor,
      surface: _darkSurface,
      error: _dangerColor,
      onPrimary: Colors.white,
      onSecondary: _darkBg,
      onSurface: _darkText,
    ),
    scaffoldBackgroundColor: _darkBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkSurface,
      foregroundColor: _darkText,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: _darkText,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: _darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _darkBorder, width: 0.5),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _darkSurface,
      selectedItemColor: _primaryColor,
      unselectedItemColor: _darkTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: _primaryColor,
      unselectedLabelColor: _darkTextSecondary,
      indicatorColor: _primaryColor,
      indicatorSize: TabBarIndicatorSize.label,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _darkCard,
      selectedColor: _primaryColor.withOpacity(0.3),
      labelStyle: const TextStyle(color: _darkText, fontSize: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _darkBorder),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _darkText),
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: _darkText),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _darkText),
      bodyLarge: TextStyle(fontSize: 16, color: _darkText),
      bodyMedium: TextStyle(fontSize: 14, color: _darkText),
      bodySmall: TextStyle(fontSize: 12, color: _darkTextSecondary),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _darkText),
      labelMedium: TextStyle(fontSize: 12, color: _darkTextSecondary),
      labelSmall: TextStyle(fontSize: 10, color: _darkTextSecondary),
    ),
    dividerTheme: const DividerThemeData(
      color: _darkBorder,
      thickness: 0.5,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _darkCard,
      contentTextStyle: const TextStyle(color: _darkText),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );

  /// Light theme
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: _primaryColor,
      secondary: _accentColor,
      surface: _lightSurface,
      error: _dangerColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _lightText,
    ),
    scaffoldBackgroundColor: _lightBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: _lightSurface,
      foregroundColor: _lightText,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: _lightText,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: _lightCard,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _lightBorder, width: 0.5),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _lightSurface,
      selectedItemColor: _primaryColor,
      unselectedItemColor: _lightTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: _primaryColor,
      unselectedLabelColor: _lightTextSecondary,
      indicatorColor: _primaryColor,
      indicatorSize: TabBarIndicatorSize.label,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _lightBg,
      selectedColor: _primaryColor.withOpacity(0.2),
      labelStyle: const TextStyle(color: _lightText, fontSize: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _lightBorder),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _lightText),
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: _lightText),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _lightText),
      bodyLarge: TextStyle(fontSize: 16, color: _lightText),
      bodyMedium: TextStyle(fontSize: 14, color: _lightText),
      bodySmall: TextStyle(fontSize: 12, color: _lightTextSecondary),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _lightText),
      labelMedium: TextStyle(fontSize: 12, color: _lightTextSecondary),
      labelSmall: TextStyle(fontSize: 10, color: _lightTextSecondary),
    ),
    dividerTheme: const DividerThemeData(
      color: _lightBorder,
      thickness: 0.5,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _lightCard,
      contentTextStyle: const TextStyle(color: _lightText),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}
