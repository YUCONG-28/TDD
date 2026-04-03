import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF6750A4);
  static const Color secondaryColor = Color(0xFF625B71);
  static const Color tertiaryColor = Color(0xFF7D5260);
  
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);
  
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: lightColorScheme,
    fontFamily: 'Roboto',
    
    // 组件主题
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 2,
    ),
    
    cardTheme: CardTheme(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 4,
    ),
    
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: lightColorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: lightColorScheme.primary, width: 2),
      ),
      filled: true,
      fillColor: lightColorScheme.surfaceVariant.withOpacity(0.5),
    ),
    
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 4,
    ),
  );
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: darkColorScheme,
    fontFamily: 'Roboto',
    
    // 组件主题
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 2,
    ),
    
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 4,
    ),
    
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: darkColorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: darkColorScheme.primary, width: 2),
      ),
      filled: true,
      fillColor: darkColorScheme.surfaceVariant.withOpacity(0.5),
    ),
    
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 4,
    ),
  );
  
  // 生成动态颜色方案
  static ColorScheme lightColorScheme = ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: Brightness.light,
    primary: primaryColor,
    secondary: secondaryColor,
    tertiary: tertiaryColor,
  );
  
  static ColorScheme darkColorScheme = ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: Brightness.dark,
    primary: primaryColor,
    secondary: secondaryColor,
    tertiary: tertiaryColor,
  );
  
  // 工具方法
  static Color getPriorityColor(int priorityIndex) {
    switch (priorityIndex) {
      case 0: // 高优先级
        return errorColor;
      case 1: // 中优先级
        return warningColor;
      case 2: // 低优先级
        return successColor;
      default:
        return secondaryColor;
    }
  }
  
  static Color getMoodColor(String mood) {
    const moodColors = {
      'happy': Color(0xFFFFD700), // 金色
      'sad': Color(0xFF2196F3),   // 蓝色
      'angry': Color(0xFFF44336), // 红色
      'excited': Color(0xFFFF9800), // 橙色
      'tired': Color(0xFF9E9E9E), // 灰色
      'neutral': Color(0xFF607D8B), // 蓝灰色
      'love': Color(0xFFE91E63), // 粉红色
      'surprised': Color(0xFF9C27B0), // 紫色
      'confused': Color(0xFF795548), // 棕色
      'proud': Color(0xFF4CAF50), // 绿色
    };
    return moodColors[mood] ?? tertiaryColor;
  }
  
  static TextStyle get titleStyle => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.15,
  );
  
  static TextStyle get subtitleStyle => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
  
  static TextStyle get bodyStyle => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
  );
  
  static TextStyle get captionStyle => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
  );
  
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: lightColorScheme.surface,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  static BoxDecoration get selectedCardDecoration => BoxDecoration(
    color: lightColorScheme.primaryContainer,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: lightColorScheme.primary,
      width: 2,
    ),
  );
  
  // 间距常量
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 16.0;
  static const double largeSpacing = 24.0;
  static const double extraLargeSpacing = 32.0;
  
  // 圆角常量
  static const double smallRadius = 8.0;
  static const double mediumRadius = 12.0;
  static const double largeRadius = 16.0;
  static const double extraLargeRadius = 24.0;
  
  // 动画时长
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
}