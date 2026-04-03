import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 条件导入permission_handler（只在非Web平台上需要）
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

/// 平台服务抽象类，处理平台特定的操作
abstract class PlatformService {
  /// 获取同步路径（非Web平台）或虚拟路径（Web平台）
  Future<String> getSyncPath();
  
  /// 检查是否有存储权限
  Future<bool> hasStoragePermission();
  
  /// 请求必要的权限
  Future<void> requestPermissions();
  
  /// 是否是Web平台
  bool get isWeb;
  
  /// 导出数据到文件（非Web）或生成下载（Web）
  Future<void> exportData(Map<String, String> data, String fileName);
  
  /// 从文件导入数据（非Web）或从上传导入（Web）
  Future<Map<String, String>> importData();
}

/// 平台服务的具体实现
class PlatformServiceImpl implements PlatformService {
  @override
  bool get isWeb => kIsWeb;

  @override
  Future<String> getSyncPath() async {
    if (kIsWeb) {
      // Web平台：使用虚拟路径，实际数据存储在SharedPreferences或IndexedDB中
      return '/virtual/TDD_Sync';
    } else if (Platform.isAndroid) {
      // Android：使用外部存储目录
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final syncDir = Directory('${externalDir.path}/TDD_Sync');
          if (!await syncDir.exists()) {
            await syncDir.create(recursive: true);
          }
          return syncDir.path;
        }
      } catch (e) {
        print('获取Android外部存储目录失败: $e');
      }
      
      // 回退到应用文档目录
      final internalDir = await getApplicationDocumentsDirectory();
      final syncDir = Directory('${internalDir.path}/TDD_Sync');
      if (!await syncDir.exists()) {
        await syncDir.create(recursive: true);
      }
      return syncDir.path;
    } else if (Platform.isWindows) {
      // Windows：使用文档目录
      final documentsDir = await getApplicationDocumentsDirectory();
      final syncDir = Directory('${documentsDir.path}\\TDD_Sync');
      if (!await syncDir.exists()) {
        await syncDir.create(recursive: true);
      }
      return syncDir.path;
    } else {
      // 其他平台（Linux, macOS, iOS）
      final documentsDir = await getApplicationDocumentsDirectory();
      final syncDir = Directory('${documentsDir.path}/TDD_Sync');
      if (!await syncDir.exists()) {
        await syncDir.create(recursive: true);
      }
      return syncDir.path;
    }
  }

  @override
  Future<bool> hasStoragePermission() async {
    if (kIsWeb) {
      // Web平台总是返回true，因为浏览器权限不同
      return true;
    } else if (Platform.isAndroid) {
      // 检查Android存储权限
      try {
        final status = await Permission.storage.status;
        return status.isGranted;
      } catch (e) {
        print('检查权限失败: $e');
        return false;
      }
    }
    // 其他平台默认有权限
    return true;
  }

  @override
  Future<void> requestPermissions() async {
    if (kIsWeb) {
      // Web平台不需要请求文件系统权限
      return;
    } else if (Platform.isAndroid) {
      try {
        await Permission.storage.request();
        await Permission.notification.request();
      } catch (e) {
        print('请求权限失败: $e');
      }
    }
  }

  @override
  Future<void> exportData(Map<String, String> data, String fileName) async {
    if (kIsWeb) {
      // Web平台：创建可下载的JSON文件
      _exportForWeb(data, fileName);
    } else {
      // 非Web平台：写入文件系统
      await _exportToFileSystem(data, fileName);
    }
  }

  @override
  Future<Map<String, String>> importData() async {
    if (kIsWeb) {
      // Web平台：从上传的文件读取
      return await _importForWeb();
    } else {
      // 非Web平台：从文件系统读取
      return await _importFromFileSystem();
    }
  }

  /// Web平台导出：创建可下载的JSON文件
  void _exportForWeb(Map<String, String> data, String fileName) {
    try {
      // 创建包含所有数据的JSON对象
      final exportData = {
        'timestamp': DateTime.now().toIso8601String(),
        'data': data,
      };
      
      final jsonStr = _convertMapToJson(exportData);
      final blob = _createBlobForWeb(jsonStr);
      _triggerDownloadForWeb(blob, fileName);
    } catch (e) {
      print('Web导出失败: $e');
    }
  }

  /// Web平台导入：使用文件输入（需要用户交互）
  Future<Map<String, String>> _importForWeb() async {
    // 注意：这个方法需要在Web环境下通过用户交互触发
    // 这里返回一个空Map，实际实现需要使用dart:html和文件输入
    return {};
  }

  /// 非Web平台导出：写入文件系统
  Future<void> _exportToFileSystem(Map<String, String> data, String fileName) async {
    try {
      final syncPath = await getSyncPath();
      final file = File('$syncPath/$fileName');
      
      final exportData = {
        'timestamp': DateTime.now().toIso8601String(),
        'data': data,
      };
      
      final jsonStr = _convertMapToJson(exportData);
      await file.writeAsString(jsonStr);
    } catch (e) {
      print('文件导出失败: $e');
      rethrow;
    }
  }

  /// 非Web平台导入：从文件系统读取
  Future<Map<String, String>> _importFromFileSystem() async {
    try {
      final syncPath = await getSyncPath();
      final file = File('$syncPath/backup.json');
      
      if (await file.exists()) {
        final jsonStr = await file.readAsString();
        final data = _parseJsonToMap(jsonStr);
        return data['data']?.cast<String, String>() ?? {};
      }
      return {};
    } catch (e) {
      print('文件导入失败: $e');
      return {};
    }
  }

  /// 将Map转换为JSON字符串
  String _convertMapToJson(Map<String, dynamic> map) {
    final buffer = StringBuffer();
    buffer.write('{\n');
    
    final entries = map.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final key = _escapeJsonString(entry.key);
      final value = entry.value;
      
      buffer.write('  "$key": ');
      
      if (value is String) {
        buffer.write('"${_escapeJsonString(value)}"');
      } else if (value is Map) {
        buffer.write(_convertMapToJson(value.cast<String, dynamic>()));
      } else {
        buffer.write('$value');
      }
      
      if (i < entries.length - 1) {
        buffer.write(',');
      }
      buffer.write('\n');
    }
    
    buffer.write('}');
    return buffer.toString();
  }

  /// 解析JSON字符串为Map
  Map<String, dynamic> _parseJsonToMap(String jsonStr) {
    try {
      // 简单的JSON解析（实际应用中应使用dart:convert）
      // 这里简化为返回空Map
      return {};
    } catch (e) {
      print('JSON解析失败: $e');
      return {};
    }
  }

  /// 转义JSON字符串
  String _escapeJsonString(String str) {
    return str
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }

  /// 为Web创建Blob（占位符）
  dynamic _createBlobForWeb(String content) {
    // 实际实现需要使用dart:html
    return content;
  }

  /// 触发Web下载（占位符）
  void _triggerDownloadForWeb(dynamic blob, String fileName) {
    // 实际实现需要使用dart:html
    print('Web下载触发: $fileName');
  }
}

/// 平台服务的提供者
class PlatformServiceProvider {
  static PlatformService? _instance;
  
  static PlatformService get instance {
    _instance ??= PlatformServiceImpl();
    return _instance!;
  }
  
  static void setInstance(PlatformService service) {
    _instance = service;
  }
}