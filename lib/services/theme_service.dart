import 'package:flutter/material.dart';

class AppTheme {
  final String name;
  final Color primary;
  final Color primaryLight;
  final Color primaryLighter;
  final Color secondary;
  final Color darkBg;

  AppTheme({
    required this.name,
    required this.primary,
    required this.primaryLight,
    required this.primaryLighter,
    required this.secondary,
    required this.darkBg,
  });
}

class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  
  factory ThemeService() {
    return _instance;
  }
  
  ThemeService._internal();

  late AppTheme _currentTheme;
  final List<AppTheme> themes = [
    // Monochromatic Blue
    AppTheme(
      name: 'Monochromatic Blue',
      primary: const Color(0xFF2563EB),
      primaryLight: const Color(0xFF7DD3FC),
      primaryLighter: const Color(0xFFE0F2FE),
      secondary: const Color(0xFF1E3A8A),
      darkBg: const Color(0xFF0F172A),
    ),
    // Monochromatic Teal
    AppTheme(
      name: 'Monochromatic Teal',
      primary: const Color(0xFF0D9488),
      primaryLight: const Color(0xFF5EEAD4),
      primaryLighter: const Color(0xFFCCFBF1),
      secondary: const Color(0xFF0F766E),
      darkBg: const Color(0xFF134E4A),
    ),
    // Monochromatic Purple
    AppTheme(
      name: 'Monochromatic Purple',
      primary: const Color(0xFF7C3AED),
      primaryLight: const Color(0xFFC084FC),
      primaryLighter: const Color(0xFFF3E8FF),
      secondary: const Color(0xFF5B21B6),
      darkBg: const Color(0xFF3B0764),
    ),
  ];

  void initialize() {
    _currentTheme = themes[0]; // Default to Blue
  }

  AppTheme get currentTheme => _currentTheme;

  void setTheme(String themeName) {
    try {
      _currentTheme = themes.firstWhere((t) => t.name == themeName);
    } catch (e) {
      _currentTheme = themes[0];
    }
  }

  AppTheme getThemeByName(String name) {
    return themes.firstWhere(
      (t) => t.name == name,
      orElse: () => themes[0],
    );
  }
}