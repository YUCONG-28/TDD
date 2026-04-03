import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

/// 字体管理服务 - 支持预置字体和动态下载
class FontService {
  static const String _prefKeyFonts = 'available_fonts';
  static const String _prefKeySelectedFont = 'selected_font_family';
  static const String _prefKeyDownloadedFonts = 'downloaded_fonts';
  
  // 预置字体列表
  static final List<FontDefinition> _presetFonts = [
    FontDefinition(
      family: 'KaiTi',
      displayName: '楷体',
      type: FontType.preset,
      isDownloadable: true,
      downloadUrl: 'https://fonts.example.com/kaiti.ttf', // 示例URL
    ),
    FontDefinition(
      family: 'XingKai',
      displayName: '行楷',
      type: FontType.preset,
      isDownloadable: true,
      downloadUrl: 'https://fonts.example.com/xingkai.ttf',
    ),
    FontDefinition(
      family: 'HeiTi',
      displayName: '黑体',
      type: FontType.preset,
      isDownloadable: true,
      downloadUrl: 'https://fonts.example.com/heiti.ttf',
    ),
    FontDefinition(
      family: 'SongTi',
      displayName: '宋体',
      type: FontType.preset,
      isDownloadable: true,
      downloadUrl: 'https://fonts.example.com/songti.ttf',
    ),
    FontDefinition(
      family: 'MicrosoftYaHei',
      displayName: '微软雅黑',
      type: FontType.preset,
      isDownloadable: true,
      downloadUrl: 'https://fonts.example.com/yahei.ttf',
    ),
    // 系统字体
    FontDefinition(
      family: 'Roboto',
      displayName: 'Roboto (系统)',
      type: FontType.system,
      isDownloadable: false,
    ),
    FontDefinition(
      family: 'Arial',
      displayName: 'Arial (系统)',
      type: FontType.system,
      isDownloadable: false,
    ),
  ];
  
  List<FontDefinition> _availableFonts = [];
  String _selectedFontFamily = 'MicrosoftYaHei';
  
  // 单例模式
  static final FontService _instance = FontService._internal();
  factory FontService() => _instance;
  FontService._internal();
  
  // 获取当前选中的字体
  String get selectedFontFamily => _selectedFontFamily;
  
  // 获取可用字体列表
  List<FontDefinition> get availableFonts => List.unmodifiable(_availableFonts);
  
  // 获取已下载的字体
  List<FontDefinition> get downloadedFonts => _availableFonts
      .where((font) => font.type == FontType.downloaded)
      .toList();
  
  // 初始化字体服务
  Future<void> initialize() async {
    await _loadAvailableFonts();
    await _loadSelectedFont();
    
    // 检查预置字体文件是否存在
    await _checkPresetFonts();
  }
  
  // 加载可用字体列表
  Future<void> _loadAvailableFonts() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 首先添加预置字体
    _availableFonts = List.from(_presetFonts);
    
    // 加载已下载的字体
    final downloadedFontsJson = prefs.getString(_prefKeyDownloadedFonts);
    if (downloadedFontsJson != null) {
      try {
        final data = jsonDecode(downloadedFontsJson) as List<dynamic>;
        for (final item in data) {
          final font = FontDefinition.fromJson(item as Map<String, dynamic>);
          // 避免重复
          if (!_availableFonts.any((f) => f.family == font.family)) {
            _availableFonts.add(font);
          }
        }
      } catch (e) {
        print('加载已下载字体失败: $e');
      }
    }
  }
  
  // 加载选中的字体
  Future<void> _loadSelectedFont() async {
    final prefs = await SharedPreferences.getInstance();
    final selected = prefs.getString(_prefKeySelectedFont);
    if (selected != null && selected.isNotEmpty) {
      _selectedFontFamily = selected;
    }
  }
  
  // 检查预置字体文件是否存在
  Future<void> _checkPresetFonts() async {
    for (final font in _presetFonts) {
      if (font.type == FontType.preset) {
        final filePath = await _getFontFilePath(font.family);
        final file = File(filePath);
        font.isAvailable = await file.exists();
      }
    }
  }
  
  // 切换字体
  Future<void> switchFont(String fontFamily) async {
    // 检查字体是否可用
    final font = _availableFonts.firstWhere(
      (f) => f.family == fontFamily,
      orElse: () => _availableFonts.first,
    );
    
    if (!font.isAvailable && font.isDownloadable) {
      // 字体不可用但可下载，提示用户
      throw FontNotAvailableException(fontFamily);
    }
    
    _selectedFontFamily = fontFamily;
    
    // 保存选择
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeySelectedFont, fontFamily);
  }
  
  // 下载字体
  Future<FontDownloadResult> downloadFont(String fontFamily) async {
    try {
      // 查找字体定义
      final font = _availableFonts.firstWhere(
        (f) => f.family == fontFamily,
        orElse: () => throw Exception('字体未找到: $fontFamily'),
      );
      
      if (!font.isDownloadable) {
        throw Exception('字体不可下载: $fontFamily');
      }
      
      if (font.downloadUrl == null) {
        throw Exception('字体下载URL为空: $fontFamily');
      }
      
      // 下载字体文件
      final response = await http.get(Uri.parse(font.downloadUrl!));
      if (response.statusCode != 200) {
        throw Exception('字体下载失败: HTTP ${response.statusCode}');
      }
      
      // 保存字体文件
      final filePath = await _getFontFilePath(fontFamily);
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      
      // 更新字体状态
      font.type = FontType.downloaded;
      font.isAvailable = true;
      font.localPath = filePath;
      
      // 保存到已下载字体列表
      await _saveDownloadedFonts();
      
      return FontDownloadResult(
        success: true,
        fontFamily: fontFamily,
        filePath: filePath,
        message: '字体下载成功',
      );
    } catch (e) {
      return FontDownloadResult(
        success: false,
        fontFamily: fontFamily,
        error: e.toString(),
        message: '字体下载失败: $e',
      );
    }
  }
  
  // 删除已下载字体
  Future<void> deleteDownloadedFont(String fontFamily) async {
    try {
      final font = downloadedFonts.firstWhere(
        (f) => f.family == fontFamily,
        orElse: () => throw Exception('未找到已下载字体: $fontFamily'),
      );
      
      // 删除字体文件
      if (font.localPath != null) {
        final file = File(font.localPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      // 从列表中移除
      _availableFonts.removeWhere((f) => f.family == fontFamily);
      
      // 如果当前选中了被删除的字体，切换到默认字体
      if (_selectedFontFamily == fontFamily) {
        await switchFont('MicrosoftYaHei');
      }
      
      // 更新存储
      await _saveDownloadedFonts();
    } catch (e) {
      print('删除字体失败: $e');
      rethrow;
    }
  }
  
  // 获取字体文件路径
  Future<String> _getFontFilePath(String fontFamily) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/fonts/$fontFamily.ttf';
  }
  
  // 保存已下载字体列表
  Future<void> _saveDownloadedFonts() async {
    final prefs = await SharedPreferences.getInstance();
    final downloaded = downloadedFonts.map((f) => f.toJson()).toList();
    final json = jsonEncode(downloaded);
    await prefs.setString(_prefKeyDownloadedFonts, json);
  }
  
  // 导入自定义字体
  Future<FontDefinition> importFont(File fontFile, String fontFamily, String displayName) async {
    try {
      // 复制字体文件到应用目录
      final filePath = await _getFontFilePath(fontFamily);
      await fontFile.copy(filePath);
      
      // 创建字体定义
      final font = FontDefinition(
        family: fontFamily,
        displayName: displayName,
        type: FontType.imported,
        isDownloadable: false,
        isAvailable: true,
        localPath: filePath,
      );
      
      // 添加到列表
      _availableFonts.add(font);
      await _saveDownloadedFonts();
      
      return font;
    } catch (e) {
      print('导入字体失败: $e');
      rethrow;
    }
  }
  
  // 获取字体的TextStyle
  TextStyle getTextStyle({
    String? fontFamily,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.black,
    double? letterSpacing,
    double? height,
  }) {
    final family = fontFamily ?? _selectedFontFamily;
    
    // 如果是Google Fonts字体
    if (family.startsWith('GoogleFonts.')) {
      final googleFont = family.replaceFirst('GoogleFonts.', '');
      try {
        return GoogleFonts.getFont(
          googleFont,
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          letterSpacing: letterSpacing,
          height: height,
        );
      } catch (e) {
        print('加载Google字体失败: $e');
      }
    }
    
    // 自定义字体
    return TextStyle(
      fontFamily: family,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
  
  // 检查字体是否存在
  Future<bool> isFontAvailable(String fontFamily) async {
    final font = _availableFonts.firstWhere(
      (f) => f.family == fontFamily,
      orElse: () => FontDefinition(
        family: fontFamily,
        displayName: fontFamily,
        type: FontType.system,
        isDownloadable: false,
      ),
    );
    
    if (font.type == FontType.preset || font.type == FontType.downloaded) {
      final filePath = await _getFontFilePath(fontFamily);
      final file = File(filePath);
      return await file.exists();
    }
    
    return true;
  }
  
  // 获取字体预览
  Widget getFontPreview(String fontFamily, String previewText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[100],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            previewText,
            style: getTextStyle(
              fontFamily: fontFamily,
              fontSize: 16,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            fontFamily,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  // 获取字体文件大小
  Future<int> getFontFileSize(String fontFamily) async {
    try {
      final filePath = await _getFontFilePath(fontFamily);
      final file = File(filePath);
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.size;
      }
    } catch (e) {
      print('获取字体文件大小失败: $e');
    }
    return 0;
  }
  
  // 清理字体缓存
  Future<void> clearFontCache() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fontDir = Directory('${dir.path}/fonts');
      if (await fontDir.exists()) {
        await fontDir.delete(recursive: true);
      }
      
      // 重新创建目录
      await fontDir.create(recursive: true);
      
      // 重置字体状态
      for (final font in _availableFonts) {
        if (font.type == FontType.downloaded) {
          font.isAvailable = false;
          font.localPath = null;
        }
      }
      
      // 更新存储
      await _saveDownloadedFonts();
    } catch (e) {
      print('清理字体缓存失败: $e');
    }
  }
}

/// 字体类型
enum FontType {
  system,    // 系统字体
  preset,    // 预置字体（需要下载）
  downloaded,// 已下载字体
  imported,  // 用户导入字体
  google,    // Google Fonts字体
}

/// 字体定义
class FontDefinition {
  final String family;
  final String displayName;
  FontType type;
  final bool isDownloadable;
  bool isAvailable;
  String? downloadUrl;
  String? localPath;
  
  FontDefinition({
    required this.family,
    required this.displayName,
    required this.type,
    required this.isDownloadable,
    this.isAvailable = false,
    this.downloadUrl,
    this.localPath,
  });
  
  // 从JSON创建
  factory FontDefinition.fromJson(Map<String, dynamic> json) {
    return FontDefinition(
      family: json['family'],
      displayName: json['displayName'] ?? json['family'],
      type: FontType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => FontType.system,
      ),
      isDownloadable: json['isDownloadable'] ?? false,
      isAvailable: json['isAvailable'] ?? false,
      downloadUrl: json['downloadUrl'],
      localPath: json['localPath'],
    );
  }
  
  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'family': family,
      'displayName': displayName,
      'type': type.toString().split('.').last,
      'isDownloadable': isDownloadable,
      'isAvailable': isAvailable,
      'downloadUrl': downloadUrl,
      'localPath': localPath,
    };
  }
  
  // 获取字体状态描述
  String get statusDescription {
    if (!isAvailable) {
      return '需要下载';
    }
    switch (type) {
      case FontType.system:
        return '系统字体';
      case FontType.preset:
        return '预置字体';
      case FontType.downloaded:
        return '已下载';
      case FontType.imported:
        return '自定义字体';
      case FontType.google:
        return 'Google字体';
    }
  }
  
  // 获取操作按钮文本
  String get actionText {
    if (!isAvailable && isDownloadable) {
      return '下载';
    }
    if (type == FontType.downloaded || type == FontType.imported) {
      return '删除';
    }
    return '使用';
  }
}

/// 字体下载结果
class FontDownloadResult {
  final bool success;
  final String fontFamily;
  final String? filePath;
  final String? error;
  final String message;
  
  FontDownloadResult({
    required this.success,
    required this.fontFamily,
    this.filePath,
    this.error,
    required this.message,
  });
}

/// 字体不可用异常
class FontNotAvailableException implements Exception {
  final String fontFamily;
  
  FontNotAvailableException(this.fontFamily);
  
  @override
  String toString() => '字体"$fontFamily"不可用，请先下载';
}

/// 字体选择器组件
class FontPicker extends StatelessWidget {
  final FontService fontService;
  final ValueChanged<String> onFontSelected;
  final String? selectedFontFamily;
  final bool showDownloadButtons;
  
  const FontPicker({
    super.key,
    required this.fontService,
    required this.onFontSelected,
    this.selectedFontFamily,
    this.showDownloadButtons = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '选择字体:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...fontService.availableFonts.map((font) {
          return _buildFontItem(context, font);
        }),
      ],
    );
  }
  
  Widget _buildFontItem(BuildContext context, FontDefinition font) {
    final isSelected = selectedFontFamily == font.family;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Icon(
          _getFontIcon(font.type),
          color: _getFontColor(font),
        ),
        title: Text(
          font.displayName,
          style: fontService.getTextStyle(
            fontFamily: font.family,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          font.statusDescription,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: _buildActionButton(context, font),
        onTap: () {
          if (font.isAvailable) {
            onFontSelected(font.family);
          } else {
            _showDownloadDialog(context, font);
          }
        },
      ),
    );
  }
  
  Widget _buildActionButton(BuildContext context, FontDefinition font) {
    if (!font.isAvailable && font.isDownloadable && showDownloadButtons) {
      return ElevatedButton(
        onPressed: () => _showDownloadDialog(context, font),
        child: const Text('下载'),
      );
    }
    
    if (font.type == FontType.downloaded || font.type == FontType.imported) {
      return IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => _showDeleteDialog(context, font),
      );
    }
    
    return Container();
  }
  
  IconData _getFontIcon(FontType type) {
    switch (type) {
      case FontType.system:
        return Icons.computer;
      case FontType.preset:
        return Icons.font_download_outlined;
      case FontType.downloaded:
        return Icons.cloud_done;
      case FontType.imported:
        return Icons.upload_file;
      case FontType.google:
        return Icons.cloud;
    }
  }
  
  Color _getFontColor(FontDefinition font) {
    if (!font.isAvailable) {
      return Colors.orange;
    }
    switch (font.type) {
      case FontType.system:
        return Colors.blue;
      case FontType.preset:
        return Colors.green;
      case FontType.downloaded:
        return Colors.purple;
      case FontType.imported:
        return Colors.deepOrange;
      case FontType.google:
        return Colors.red;
    }
  }
  
  void _showDownloadDialog(BuildContext context, FontDefinition font) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('下载字体'),
          content: Text('您需要下载"${font.displayName}"字体才能使用。是否现在下载？（约5-10MB）'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _downloadFont(context, font);
              },
              child: const Text('下载'),
            ),
          ],
        );
      },
    );
  }
  
  void _showDeleteDialog(BuildContext context, FontDefinition font) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除字体'),
          content: Text('确定要删除"${font.displayName}"字体吗？删除后需要重新下载才能使用。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteFont(context, font);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _downloadFont(BuildContext context, FontDefinition font) async {
    try {
      final result = await fontService.downloadFont(font.family);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('字体"${font.displayName}"下载成功'),
            backgroundColor: Colors.green,
          ),
        );
        onFontSelected(font.family);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('字体下载失败: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('字体下载失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _deleteFont(BuildContext context, FontDefinition font) async {
    try {
      await fontService.deleteDownloadedFont(font.family);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('字体"${font.displayName}"已删除'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('删除字体失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}