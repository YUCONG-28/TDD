import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 动态主题配置类 - 支持完全自定义
class DynamicThemeConfig {
  String themeName;
  bool isDefault;
  bool isDarkMode;
  
  // 基础颜色
  Color primaryColor;
  Color secondaryColor;
  Color tertiaryColor;
  Color backgroundColor;
  Color surfaceColor;
  Color errorColor;
  Color successColor;
  Color warningColor;
  
  // 文本颜色
  Color textPrimary;
  Color textSecondary;
  Color textHint;
  
  // 字体设置
  String fontFamily;
  double fontSizeScale; // 字体大小缩放因子
  
  // 间距设置
  double spacingUnit;
  double borderRadius;
  
  // 背景图片设置
  String? backgroundImagePath;
  List<String>? backgroundImagePaths; // 多张图片轮换
  int backgroundRotationInterval; // 轮换间隔（秒）
  double backgroundOpacity;
  BackgroundFit backgroundFit;
  
  // 组件样式
  double cardElevation;
  double buttonBorderRadius;
  double inputBorderRadius;
  
  // 动画设置
  Duration animationDuration;
  Curve animationCurve;
  
  // 自定义字段（用户可扩展）
  Map<String, dynamic> customProperties;
  
  DynamicThemeConfig({
    this.themeName = '自定义主题',
    this.isDefault = false,
    this.isDarkMode = false,
    
    // 基础颜色默认值
    this.primaryColor = const Color(0xFF6750A4),
    this.secondaryColor = const Color(0xFF625B71),
    this.tertiaryColor = const Color(0xFF7D5260),
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.surfaceColor = const Color(0xFFFEF7FF),
    this.errorColor = const Color(0xFFF44336),
    this.successColor = const Color(0xFF4CAF50),
    this.warningColor = const Color(0xFFFF9800),
    
    // 文本颜色默认值
    this.textPrimary = const Color(0xFF1C1B1F),
    this.textSecondary = const Color(0xFF49454F),
    this.textHint = const Color(0xFF79747E),
    
    // 字体设置默认值
    this.fontFamily = 'MicrosoftYaHei',
    this.fontSizeScale = 1.0,
    
    // 间距默认值
    this.spacingUnit = 8.0,
    this.borderRadius = 12.0,
    
    // 背景图片默认值
    this.backgroundImagePath,
    this.backgroundImagePaths,
    this.backgroundRotationInterval = 30,
    this.backgroundOpacity = 0.1,
    this.backgroundFit = BackgroundFit.cover,
    
    // 组件样式默认值
    this.cardElevation = 1.0,
    this.buttonBorderRadius = 8.0,
    this.inputBorderRadius = 8.0,
    
    // 动画默认值
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
    
    // 自定义字段
    this.customProperties = const {},
  });
  
  // 从JSON创建主题配置
  factory DynamicThemeConfig.fromJson(Map<String, dynamic> json) {
    return DynamicThemeConfig(
      themeName: json['themeName'] ?? '自定义主题',
      isDefault: json['isDefault'] ?? false,
      isDarkMode: json['isDarkMode'] ?? false,
      
      // 解析颜色
      primaryColor: _parseColor(json['primaryColor']),
      secondaryColor: _parseColor(json['secondaryColor']),
      tertiaryColor: _parseColor(json['tertiaryColor']),
      backgroundColor: _parseColor(json['backgroundColor']),
      surfaceColor: _parseColor(json['surfaceColor']),
      errorColor: _parseColor(json['errorColor']),
      successColor: _parseColor(json['successColor']),
      warningColor: _parseColor(json['warningColor']),
      
      // 文本颜色
      textPrimary: _parseColor(json['textPrimary']),
      textSecondary: _parseColor(json['textSecondary']),
      textHint: _parseColor(json['textHint']),
      
      // 字体设置
      fontFamily: json['fontFamily'] ?? 'MicrosoftYaHei',
      fontSizeScale: (json['fontSizeScale'] ?? 1.0).toDouble(),
      
      // 间距设置
      spacingUnit: (json['spacingUnit'] ?? 8.0).toDouble(),
      borderRadius: (json['borderRadius'] ?? 12.0).toDouble(),
      
      // 背景图片
      backgroundImagePath: json['backgroundImagePath'],
      backgroundImagePaths: json['backgroundImagePaths'] != null
          ? List<String>.from(json['backgroundImagePaths'])
          : null,
      backgroundRotationInterval: json['backgroundRotationInterval'] ?? 30,
      backgroundOpacity: (json['backgroundOpacity'] ?? 0.1).toDouble(),
      backgroundFit: BackgroundFit.values.firstWhere(
        (e) => e.toString().split('.').last == json['backgroundFit'],
        orElse: () => BackgroundFit.cover,
      ),
      
      // 组件样式
      cardElevation: (json['cardElevation'] ?? 1.0).toDouble(),
      buttonBorderRadius: (json['buttonBorderRadius'] ?? 8.0).toDouble(),
      inputBorderRadius: (json['inputBorderRadius'] ?? 8.0).toDouble(),
      
      // 动画设置
      animationDuration: Duration(milliseconds: json['animationDuration'] ?? 300),
      animationCurve: _parseCurve(json['animationCurve']),
      
      // 自定义字段
      customProperties: json['customProperties'] ?? {},
    );
  }
  
  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'themeName': themeName,
      'isDefault': isDefault,
      'isDarkMode': isDarkMode,
      
      // 颜色
      'primaryColor': _colorToString(primaryColor),
      'secondaryColor': _colorToString(secondaryColor),
      'tertiaryColor': _colorToString(tertiaryColor),
      'backgroundColor': _colorToString(backgroundColor),
      'surfaceColor': _colorToString(surfaceColor),
      'errorColor': _colorToString(errorColor),
      'successColor': _colorToString(successColor),
      'warningColor': _colorToString(warningColor),
      
      // 文本颜色
      'textPrimary': _colorToString(textPrimary),
      'textSecondary': _colorToString(textSecondary),
      'textHint': _colorToString(textHint),
      
      // 字体设置
      'fontFamily': fontFamily,
      'fontSizeScale': fontSizeScale,
      
      // 间距设置
      'spacingUnit': spacingUnit,
      'borderRadius': borderRadius,
      
      // 背景图片
      'backgroundImagePath': backgroundImagePath,
      'backgroundImagePaths': backgroundImagePaths,
      'backgroundRotationInterval': backgroundRotationInterval,
      'backgroundOpacity': backgroundOpacity,
      'backgroundFit': backgroundFit.toString().split('.').last,
      
      // 组件样式
      'cardElevation': cardElevation,
      'buttonBorderRadius': buttonBorderRadius,
      'inputBorderRadius': inputBorderRadius,
      
      // 动画设置
      'animationDuration': animationDuration.inMilliseconds,
      'animationCurve': animationCurve.toString().split('.').last,
      
      // 自定义字段
      'customProperties': customProperties,
    };
  }
  
  // 创建深色主题变体
  DynamicThemeConfig darkVariant() {
    return DynamicThemeConfig(
      themeName: '$themeName (深色)',
      isDarkMode: true,
      
      // 基础颜色（调整为深色）
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      tertiaryColor: tertiaryColor,
      backgroundColor: const Color(0xFF121212),
      surfaceColor: const Color(0xFF1E1E1E),
      errorColor: errorColor,
      successColor: successColor,
      warningColor: warningColor,
      
      // 文本颜色（调整为深色）
      textPrimary: const Color(0xFFFFFFFF),
      textSecondary: const Color(0xFFB0B0B0),
      textHint: const Color(0xFF707070),
      
      // 复制其他设置
      fontFamily: fontFamily,
      fontSizeScale: fontSizeScale,
      spacingUnit: spacingUnit,
      borderRadius: borderRadius,
      backgroundImagePath: backgroundImagePath,
      backgroundImagePaths: backgroundImagePaths,
      backgroundRotationInterval: backgroundRotationInterval,
      backgroundOpacity: backgroundOpacity,
      backgroundFit: backgroundFit,
      cardElevation: cardElevation,
      buttonBorderRadius: buttonBorderRadius,
      inputBorderRadius: inputBorderRadius,
      animationDuration: animationDuration,
      animationCurve: animationCurve,
      customProperties: Map.from(customProperties),
    );
  }
  
  // 生成Material3颜色方案
  ColorScheme toColorScheme() {
    return ColorScheme(
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      primary: primaryColor,
      onPrimary: isDarkMode ? Colors.black : Colors.white,
      primaryContainer: primaryColor.withOpacity(0.1),
      onPrimaryContainer: primaryColor,
      secondary: secondaryColor,
      onSecondary: isDarkMode ? Colors.black : Colors.white,
      secondaryContainer: secondaryColor.withOpacity(0.1),
      onSecondaryContainer: secondaryColor,
      tertiary: tertiaryColor,
      onTertiary: isDarkMode ? Colors.black : Colors.white,
      tertiaryContainer: tertiaryColor.withOpacity(0.1),
      onTertiaryContainer: tertiaryColor,
      error: errorColor,
      onError: isDarkMode ? Colors.black : Colors.white,
      errorContainer: errorColor.withOpacity(0.1),
      onErrorContainer: errorColor,
      background: backgroundColor,
      onBackground: textPrimary,
      surface: surfaceColor,
      onSurface: textPrimary,
      surfaceVariant: surfaceColor.withOpacity(0.5),
      onSurfaceVariant: textSecondary,
      outline: textHint,
      outlineVariant: textHint.withOpacity(0.5),
      shadow: Colors.black,
      scrim: Colors.black.withOpacity(0.5),
      inverseSurface: isDarkMode ? Colors.white : Colors.black,
      onInverseSurface: isDarkMode ? Colors.black : Colors.white,
      inversePrimary: primaryColor.withOpacity(0.5),
      surfaceTint: primaryColor,
    );
  }
  
  // 创建主题数据
  ThemeData toThemeData() {
    final colorScheme = toColorScheme();
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: fontFamily,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      
      // 文本主题
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 57 * fontSizeScale,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 45 * fontSizeScale,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 36 * fontSizeScale,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: 32 * fontSizeScale,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 28 * fontSizeScale,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 24 * fontSizeScale,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 22 * fontSizeScale,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16 * fontSizeScale,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 14 * fontSizeScale,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16 * fontSizeScale,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14 * fontSizeScale,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 12 * fontSizeScale,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14 * fontSizeScale,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 12 * fontSizeScale,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11 * fontSizeScale,
          fontWeight: FontWeight.w500,
          color: textHint,
        ),
      ),
      
      // 组件主题
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: cardElevation,
        centerTitle: true,
        scrolledUnderElevation: cardElevation * 2,
      ),
      
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: isDarkMode ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonBorderRadius),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: spacingUnit * 3,
            vertical: spacingUnit * 1.5,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonBorderRadius),
          ),
          side: BorderSide(color: primaryColor),
          padding: EdgeInsets.symmetric(
            horizontal: spacingUnit * 3,
            vertical: spacingUnit * 1.5,
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: BorderSide(color: errorColor),
        ),
        contentPadding: EdgeInsets.all(spacingUnit * 1.5),
      ),
      
      
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor.withOpacity(0.3),
        selectedColor: primaryColor.withOpacity(0.2),
        checkmarkColor: primaryColor,
        labelStyle: TextStyle(
          fontSize: 14 * fontSizeScale,
          color: textPrimary,
        ),
        secondaryLabelStyle: TextStyle(
          fontSize: 14 * fontSizeScale,
          color: textSecondary,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: spacingUnit,
          vertical: spacingUnit * 0.5,
        ),
        shape: StadiumBorder(
          side: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
      ),
      
      dividerTheme: DividerThemeData(
        color: textHint.withOpacity(0.3),
        thickness: 1,
        space: spacingUnit,
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: cardElevation * 2,
      ),
      
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        elevation: cardElevation * 2,
        type: BottomNavigationBarType.fixed,
      ),
      
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacingUnit * 2,
          vertical: spacingUnit,
        ),
        tileColor: surfaceColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: primaryColor.withOpacity(0.2),
        circularTrackColor: primaryColor.withOpacity(0.2),
      ),
      
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceColor,
        contentTextStyle: TextStyle(
          fontSize: 14 * fontSizeScale,
          color: textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: cardElevation * 2,
      ),
    );
  }
  
  // 辅助方法：解析颜色
  static Color _parseColor(dynamic value) {
    if (value == null) return const Color(0xFF6750A4);
    if (value is String) {
      // 格式：#AARRGGBB 或 #RRGGBB
      String hex = value.replaceFirst('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    }
    if (value is int) {
      return Color(value);
    }
    return const Color(0xFF6750A4);
  }
  
  // 辅助方法：颜色转字符串
  static String _colorToString(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }
  
  // 辅助方法：解析动画曲线
  static Curve _parseCurve(dynamic value) {
    if (value == null) return Curves.easeInOut;
    final curveName = value.toString();
    switch (curveName) {
      case 'linear': return Curves.linear;
      case 'ease': return Curves.ease;
      case 'easeIn': return Curves.easeIn;
      case 'easeOut': return Curves.easeOut;
      case 'easeInOut': return Curves.easeInOut;
      case 'fastOutSlowIn': return Curves.fastOutSlowIn;
      case 'bounceIn': return Curves.bounceIn;
      case 'bounceOut': return Curves.bounceOut;
      case 'bounceInOut': return Curves.bounceInOut;
      case 'elasticIn': return Curves.elasticIn;
      case 'elasticOut': return Curves.elasticOut;
      case 'elasticInOut': return Curves.elasticInOut;
      default: return Curves.easeInOut;
    }
  }
}

/// 背景图片适配方式
enum BackgroundFit {
  fill,
  contain,
  cover,
  fitWidth,
  fitHeight,
  none,
  scaleDown,
}

/// 动态主题管理器 - 提供主题切换和持久化
class DynamicThemeManager {
  static const String _prefKeyCurrentTheme = 'current_theme_config';
  static const String _prefKeyThemesList = 'saved_themes_list';
  
  DynamicThemeConfig _currentConfig;
  List<DynamicThemeConfig> _savedThemes = [];
  
  DynamicThemeManager({DynamicThemeConfig? initialConfig})
      : _currentConfig = initialConfig ?? DynamicThemeConfig();
  
  // 获取当前配置
  DynamicThemeConfig get currentConfig => _currentConfig;
  
  // 获取保存的主题列表
  List<DynamicThemeConfig> get savedThemes => List.unmodifiable(_savedThemes);
  
  // 加载配置
  Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 加载当前主题
    final currentThemeJson = prefs.getString(_prefKeyCurrentTheme);
    if (currentThemeJson != null) {
      try {
        final data = jsonDecode(currentThemeJson) as Map<String, dynamic>;
        _currentConfig = DynamicThemeConfig.fromJson(data);
      } catch (e) {
        print('加载当前主题失败: $e');
      }
    }
    
    // 加载保存的主题列表
    final themesListJson = prefs.getString(_prefKeyThemesList);
    if (themesListJson != null) {
      try {
        final data = jsonDecode(themesListJson) as List<dynamic>;
        _savedThemes = data.map((item) {
          return DynamicThemeConfig.fromJson(item as Map<String, dynamic>);
        }).toList();
      } catch (e) {
        print('加载主题列表失败: $e');
      }
    }
  }
  
  // 保存当前配置
  Future<void> saveCurrentConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_currentConfig.toJson());
    await prefs.setString(_prefKeyCurrentTheme, json);
  }
  
  // 保存主题到列表
  Future<void> saveThemeToList(DynamicThemeConfig config) async {
    // 检查是否已存在同名主题
    final index = _savedThemes.indexWhere((t) => t.themeName == config.themeName);
    if (index != -1) {
      _savedThemes[index] = config;
    } else {
      _savedThemes.add(config);
    }
    
    await _saveThemesList();
  }
  
  // 从列表删除主题
  Future<void> deleteThemeFromList(String themeName) async {
    _savedThemes.removeWhere((t) => t.themeName == themeName);
    await _saveThemesList();
  }
  
  // 切换当前主题
  Future<void> switchTheme(DynamicThemeConfig config) async {
    _currentConfig = config;
    await saveCurrentConfig();
  }
  
  // 切换深色/浅色模式
  Future<void> toggleDarkMode(bool isDark) async {
    if (isDark != _currentConfig.isDarkMode) {
      final newConfig = isDark 
          ? _currentConfig.darkVariant()
          : DynamicThemeConfig.fromJson(_currentConfig.toJson())..isDarkMode = false;
      await switchTheme(newConfig);
    }
  }
  
  // 切换字体
  Future<void> changeFontFamily(String fontFamily) async {
    _currentConfig.fontFamily = fontFamily;
    await saveCurrentConfig();
  }
  
  // 更新单个属性
  Future<void> updateConfig(Map<String, dynamic> updates) async {
    final json = _currentConfig.toJson();
    json.addAll(updates);
    _currentConfig = DynamicThemeConfig.fromJson(json);
    await saveCurrentConfig();
  }
  
  // 重置为默认配置
  Future<void> resetToDefault() async {
    _currentConfig = DynamicThemeConfig();
    await saveCurrentConfig();
  }
  
  // 导出主题配置
  String exportTheme(DynamicThemeConfig config) {
    return jsonEncode(config.toJson());
  }
  
  // 导入主题配置
  DynamicThemeConfig? importTheme(String jsonString) {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      return DynamicThemeConfig.fromJson(data);
    } catch (e) {
      print('导入主题失败: $e');
      return null;
    }
  }
  
  // 保存主题列表到存储
  Future<void> _saveThemesList() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _savedThemes.map((t) => t.toJson()).toList();
    final json = jsonEncode(jsonList);
    await prefs.setString(_prefKeyThemesList, json);
  }
  
  // 获取预置主题
  static List<DynamicThemeConfig> getPresetThemes() {
    return [
      // 默认主题
      DynamicThemeConfig(
        themeName: '默认主题',
        isDefault: true,
        primaryColor: const Color(0xFF6750A4),
        fontFamily: 'MicrosoftYaHei',
      ),
      
      // 蓝色主题
      DynamicThemeConfig(
        themeName: '蓝色主题',
        primaryColor: const Color(0xFF2196F3),
        secondaryColor: const Color(0xFF64B5F6),
        tertiaryColor: const Color(0xFF1976D2),
        fontFamily: 'HeiTi',
      ),
      
      // 绿色主题
      DynamicThemeConfig(
        themeName: '绿色主题',
        primaryColor: const Color(0xFF4CAF50),
        secondaryColor: const Color(0xFF81C784),
        tertiaryColor: const Color(0xFF388E3C),
        fontFamily: 'SongTi',
      ),
      
      // 橙色主题
      DynamicThemeConfig(
        themeName: '橙色主题',
        primaryColor: const Color(0xFFFF9800),
        secondaryColor: const Color(0xFFFFB74D),
        tertiaryColor: const Color(0xFFF57C00),
        fontFamily: 'KaiTi',
      ),
      
      // 紫色主题
      DynamicThemeConfig(
        themeName: '紫色主题',
        primaryColor: const Color(0xFF9C27B0),
        secondaryColor: const Color(0xFFBA68C8),
        tertiaryColor: const Color(0xFF7B1FA2),
        fontFamily: 'XingKai',
      ),
    ];
  }
}