import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  String _currentTheme = 'Ocean Blue'; // Default theme

  String get currentTheme => _currentTheme;

  // Available themes with their color schemes
  static const Map<String, AppTheme> themes = {
    'Ocean Blue': AppTheme(
      name: 'Ocean Blue',
      primaryColor: Color(0xFF021024),
      secondaryColor: Color(0xFF052659),
      accentColor: Color(0xFF5B8DEF),
      backgroundColor: Color(0xFF021024),
      surfaceColor: Color(0xFF052659),
      cardColor: Color(0xFF0A2C5C),
      textColor: Colors.white,
      subtextColor: Color(0xFFB0C4DE),
      buttonColor: Color(0xFF5B8DEF),
      successColor: Color(0xFF4CAF50),
      warningColor: Color(0xFFFF9800),
      errorColor: Color(0xFFF44336),
      gradientColors: [Color(0xFF021024), Color(0xFF052659), Color(0xFF5B8DEF)],
    ),
    'Forest Green': AppTheme(
      name: 'Forest Green',
      primaryColor: Color(0xFF1B4332),
      secondaryColor: Color(0xFF2D5A3D),
      accentColor: Color(0xFF40916C),
      backgroundColor: Color(0xFF1B4332),
      surfaceColor: Color(0xFF2D5A3D),
      cardColor: Color(0xFF52B788),
      textColor: Colors.white,
      subtextColor: Color(0xFFD8F3DC),
      buttonColor: Color(0xFF40916C),
      successColor: Color(0xFF52B788),
      warningColor: Color(0xFFFFB700),
      errorColor: Color(0xFFDC2626),
      gradientColors: [Color(0xFF1B4332), Color(0xFF2D5A3D), Color(0xFF40916C)],
    ),
    'Sunset Orange': AppTheme(
      name: 'Sunset Orange',
      primaryColor: Color(0xFF7C2D12),
      secondaryColor: Color(0xFF9A3412),
      accentColor: Color(0xFFEA580C),
      backgroundColor: Color(0xFF7C2D12),
      surfaceColor: Color(0xFF9A3412),
      cardColor: Color(0xFFC2410C),
      textColor: Colors.white,
      subtextColor: Color(0xFFFED7AA),
      buttonColor: Color(0xFFEA580C),
      successColor: Color(0xFF16A34A),
      warningColor: Color(0xFFFBBF24),
      errorColor: Color(0xFFDC2626),
      gradientColors: [Color(0xFF7C2D12), Color(0xFF9A3412), Color(0xFFEA580C)],
    ),
    'Purple Night': AppTheme(
      name: 'Purple Night',
      primaryColor: Color(0xFF4C1D95),
      secondaryColor: Color(0xFF5B21B6),
      accentColor: Color(0xFF8B5CF6),
      backgroundColor: Color(0xFF4C1D95),
      surfaceColor: Color(0xFF5B21B6),
      cardColor: Color(0xFF7C3AED),
      textColor: Colors.white,
      subtextColor: Color(0xFFDDD6FE),
      buttonColor: Color(0xFF8B5CF6),
      successColor: Color(0xFF10B981),
      warningColor: Color(0xFFF59E0B),
      errorColor: Color(0xFFEF4444),
      gradientColors: [Color(0xFF4C1D95), Color(0xFF5B21B6), Color(0xFF8B5CF6)],
    ),
  };

  AppTheme get currentAppTheme =>
      themes[_currentTheme] ?? themes['Ocean Blue']!;

  void setTheme(String themeName) {
    if (themes.containsKey(themeName)) {
      _currentTheme = themeName;
      notifyListeners();
    }
  }

  ThemeData getThemeData() {
    final appTheme = currentAppTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: _createMaterialColor(appTheme.primaryColor),
      primaryColor: appTheme.primaryColor,
      hintColor: appTheme.accentColor,
      scaffoldBackgroundColor: appTheme.backgroundColor,
      cardColor: appTheme.cardColor,
      appBarTheme: AppBarTheme(
        backgroundColor: appTheme.primaryColor,
        foregroundColor: appTheme.textColor,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: appTheme.buttonColor,
          foregroundColor: appTheme.textColor,
          elevation: 2,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: appTheme.cardColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: appTheme.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: appTheme.accentColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: appTheme.subtextColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: appTheme.accentColor, width: 2),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
            color: appTheme.textColor,
            fontSize: 32,
            fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(
            color: appTheme.textColor,
            fontSize: 28,
            fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(
            color: appTheme.textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold),
        titleLarge: TextStyle(
            color: appTheme.textColor,
            fontSize: 22,
            fontWeight: FontWeight.w600),
        titleMedium: TextStyle(
            color: appTheme.textColor,
            fontSize: 18,
            fontWeight: FontWeight.w500),
        titleSmall: TextStyle(
            color: appTheme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: appTheme.textColor, fontSize: 16),
        bodyMedium: TextStyle(color: appTheme.subtextColor, fontSize: 14),
        bodySmall: TextStyle(color: appTheme.subtextColor, fontSize: 12),
        labelLarge: TextStyle(
            color: appTheme.textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500),
      ),
      iconTheme: IconThemeData(
        color: appTheme.textColor,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.all(appTheme.textColor),
        trackColor: MaterialStateProperty.resolveWith((states) {
          return states.contains(MaterialState.selected)
              ? appTheme.successColor
              : appTheme.subtextColor;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: appTheme.accentColor,
        inactiveTrackColor: appTheme.subtextColor,
        thumbColor: appTheme.textColor,
        overlayColor: appTheme.accentColor.withOpacity(0.2),
      ),
    );
  }

  MaterialColor _createMaterialColor(Color color) {
    List<double> strengths = <double>[.05];
    final Map<int, Color> swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }

    for (double strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }

    return MaterialColor(color.value, swatch);
  }
}

class AppTheme {
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color cardColor;
  final Color textColor;
  final Color subtextColor;
  final Color buttonColor;
  final Color successColor;
  final Color warningColor;
  final Color errorColor;
  final List<Color> gradientColors;

  const AppTheme({
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.cardColor,
    required this.textColor,
    required this.subtextColor,
    required this.buttonColor,
    required this.successColor,
    required this.warningColor,
    required this.errorColor,
    required this.gradientColors,
  });
}
