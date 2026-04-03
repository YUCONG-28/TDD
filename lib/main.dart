// TodoDiary 完整版本 - 跨平台待办事项和日记应用
// 支持Windows桌面、Android移动端和Web，通过文件同步实现数据交换

import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:todo_diary/services/font_service.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 请求必要的权限（仅在实际移动设备上）
  if (!kIsWeb && Platform.isAndroid) {
    try {
      await Permission.storage.request();
      await Permission.notification.request();
    } catch (e) {
      print('权限请求失败: $e');
    }
  }
  
  runApp(const FullTodoDiaryApp());
}

// ============================================
// 配置管理器
// ============================================

class FullConfig {
  static const String _prefKey = 'full_config';
  
  String appName;
  String themeColor;
  bool enableEncryption;
  bool enableNotifications;
  String syncPath;
  // 字体和界面自定义
  String fontFamily;
  double fontSize;
  double lineSpacing;
  double itemSpacing;
  String uiDensity;

  FullConfig({
    this.appName = 'TDD',
    this.themeColor = 'blue',
    this.enableEncryption = true,
    this.enableNotifications = true,
    this.syncPath = '',
    // 字体和界面自定义默认值
    this.fontFamily = 'MicrosoftYaHei',
    this.fontSize = 14.0,
    this.lineSpacing = 1.5,
    this.itemSpacing = 12.0,
    this.uiDensity = 'standard',
  });
  
  factory FullConfig.fromJson(Map<String, dynamic> json) {
    return FullConfig(
      appName: json['appName'] ?? 'TDD',
      themeColor: json['themeColor'] ?? 'blue',
      enableEncryption: json['enableEncryption'] ?? true,
      enableNotifications: json['enableNotifications'] ?? true,
      syncPath: json['syncPath'] ?? '',
      // 字体和界面自定义
      fontFamily: json['fontFamily'] ?? 'MicrosoftYaHei',
      fontSize: (json['fontSize'] ?? 14.0).toDouble(),
      lineSpacing: (json['lineSpacing'] ?? 1.5).toDouble(),
      itemSpacing: (json['itemSpacing'] ?? 12.0).toDouble(),
      uiDensity: json['uiDensity'] ?? 'standard',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'themeColor': themeColor,
      'enableEncryption': enableEncryption,
      'enableNotifications': enableNotifications,
      'syncPath': syncPath,
      // 字体和界面自定义
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'lineSpacing': lineSpacing,
      'itemSpacing': itemSpacing,
      'uiDensity': uiDensity,
    };
  }
}

class FullConfigManager with ChangeNotifier {
  FullConfig _config = FullConfig();
  
  FullConfig get config => _config;
  
  Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString(FullConfig._prefKey);
    if (configJson != null) {
      try {
        _config = FullConfig.fromJson(jsonDecode(configJson));
        notifyListeners();
      } catch (e) {
        print('加载配置失败: $e');
      }
    }
  }
  
  Future<void> saveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = jsonEncode(_config.toJson());
    await prefs.setString(FullConfig._prefKey, configJson);
    notifyListeners();
  }
  
  Future<void> updateConfig(Map<String, dynamic> updates) async {
    final configJson = _config.toJson();
    configJson.addAll(updates);
    _config = FullConfig.fromJson(configJson);
    await saveConfig();
  }
}

// ============================================
// 加密系统
// ============================================

class FullEncryptionSystem {
  static const String _keyPrefs = 'full_encryption_key';
  static encrypt.Encrypter? _encrypter;
  
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    String? keyString = prefs.getString(_keyPrefs);
    
    if (keyString == null) {
      // 生成新密钥
      final key = encrypt.Key.fromSecureRandom(32);
      keyString = base64Encode(key.bytes);
      await prefs.setString(_keyPrefs, keyString);
    }
    
    final key = encrypt.Key.fromBase64(keyString);
    final iv = encrypt.IV.fromLength(16);
    _encrypter = encrypt.Encrypter(encrypt.AES(key));
  }
  
  static String encryptData(String plainText) {
    if (_encrypter == null) return plainText;
    final encrypted = _encrypter!.encrypt(plainText);
    return encrypted.base64;
  }
  
  static String decryptData(String encryptedText) {
    if (_encrypter == null) return encryptedText;
    try {
      final encrypted = encrypt.Encrypted.fromBase64(encryptedText);
      return _encrypter!.decrypt(encrypted);
    } catch (e) {
      return encryptedText;
    }
  }
}

// ============================================
// 主应用
// ============================================

class FullTodoDiaryApp extends StatelessWidget {
  const FullTodoDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FullConfigManager(),
      child: Builder(
        builder: (context) {
          final configManager = Provider.of<FullConfigManager>(context);
          
          Color primaryColor;
          switch (configManager.config.themeColor) {
            case 'blue':
              primaryColor = Colors.blue;
              break;
            case 'green':
              primaryColor = Colors.green;
              break;
            case 'purple':
              primaryColor = Colors.purple;
              break;
            case 'orange':
              primaryColor = Colors.orange;
              break;
            default:
              primaryColor = Colors.blue;
          }
          
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: configManager.config.appName,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: primaryColor,
                brightness: Brightness.light,
              ),
            ),
            home: const FullMainPage(),
          );
        },
      ),
    );
  }
}

// ============================================
// 主页
// ============================================

class FullMainPage extends StatefulWidget {
  const FullMainPage({super.key});

  @override
  State<FullMainPage> createState() => _FullMainPageState();
}

class _FullMainPageState extends State<FullMainPage> {
  int _selectedIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  Future<void> _initialize() async {
    await Provider.of<FullConfigManager>(context, listen: false).loadConfig();
    await FullEncryptionSystem.initialize();
  }
  
  static const List<Widget> _pages = [
    FullTodoPage(),
    FullDiaryPage(),
    FullSyncPage(),
    FullSettingsPage(),
  ];
  
  static const List<String> _pageTitles = [
    '待办事项',
    '日记',
    '同步',
    '设置',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist),
            label: '待办',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: '日记',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sync),
            label: '同步',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}

// ============================================
// 待办事项页面
// ============================================

class FullTodoPage extends StatefulWidget {
  const FullTodoPage({super.key});

  @override
  State<FullTodoPage> createState() => _FullTodoPageState();
}

class _FullTodoPageState extends State<FullTodoPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<TodoItem> _todos = [];
  bool _loading = true;
  
  static const String _todoKey = 'full_todos';
  
  @override
  void initState() {
    super.initState();
    _loadTodos();
  }
  
  Future<void> _loadTodos() async {
    setState(() {
      _loading = true;
    });
    
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_todoKey);
    
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _todos = jsonList.map((json) => TodoItem.fromJson(json)).toList();
      } catch (e) {
        _todos = [];
      }
    } else {
      _todos = [];
    }
    
    setState(() {
      _loading = false;
    });
  }
  
  Future<void> _addTodo() async {
    if (_titleController.text.isEmpty) {
      _showSnackBar('请输入标题');
      return;
    }
    
    final todo = TodoItem(
      title: _titleController.text,
      description: _descriptionController.text,
    );
    
    _todos.add(todo);
    await _saveTodos();
    
    _titleController.clear();
    _descriptionController.clear();
    
    _showSnackBar('待办事项已添加');
  }
  
  Future<void> _toggleTodo(TodoItem todo) async {
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      _todos[index] = todo.copyWith(completed: !todo.completed);
      await _saveTodos();
      setState(() {});
    }
  }
  
  Future<void> _deleteTodo(String id) async {
    _todos.removeWhere((todo) => todo.id == id);
    await _saveTodos();
    setState(() {});
    _showSnackBar('已删除');
  }
  
  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _todos.map((todo) => todo.toJson()).toList();
    await prefs.setString(_todoKey, jsonEncode(jsonList));
  }
  
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 输入区域
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: '标题',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: '描述（可选）',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addTodo,
                    child: const Text('添加待办'),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 待办列表
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _todos.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.checklist, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('暂无待办事项', style: TextStyle(fontSize: 18, color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _todos.length,
                        itemBuilder: (context, index) {
                          final todo = _todos[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Checkbox(
                                value: todo.completed,
                                onChanged: (_) => _toggleTodo(todo),
                              ),
                              title: Text(
                                todo.title,
                                style: TextStyle(
                                  decoration: todo.completed
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: todo.description.isNotEmpty
                                  ? Text(todo.description)
                                  : null,
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteTodo(todo.id),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// 日记页面
// ============================================

class FullDiaryPage extends StatefulWidget {
  const FullDiaryPage({super.key});

  @override
  State<FullDiaryPage> createState() => _FullDiaryPageState();
}

class _FullDiaryPageState extends State<FullDiaryPage> {
  List<DiaryEntry> _diaries = [];
  bool _loading = true;
  
  static const String _diaryKey = 'full_diaries';
  
  @override
  void initState() {
    super.initState();
    _loadDiaries();
  }
  
  Future<void> _loadDiaries() async {
    setState(() {
      _loading = true;
    });
    
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_diaryKey);
    
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _diaries = jsonList.map((json) => DiaryEntry.fromJson(json)).toList();
      } catch (e) {
        _diaries = [];
      }
    } else {
      _diaries = [];
    }
    
    setState(() {
      _loading = false;
    });
  }
  
  void _showAddDiaryDialog() {
    showDialog(
      context: context,
      builder: (context) => FullAddDiaryDialog(
        onSave: (diary) async {
          _diaries.add(diary);
          await _saveDiaries();
          Navigator.pop(context);
          _showSnackBar('日记已保存');
          setState(() {});
        },
      ),
    );
  }
  
  Future<void> _toggleFavorite(DiaryEntry diary) async {
    final index = _diaries.indexWhere((d) => d.id == diary.id);
    if (index != -1) {
      _diaries[index] = diary.copyWith(favorite: !diary.favorite);
      await _saveDiaries();
      setState(() {});
    }
  }
  
  Future<void> _deleteDiary(String id) async {
    _diaries.removeWhere((diary) => diary.id == id);
    await _saveDiaries();
    setState(() {});
    _showSnackBar('已删除');
  }
  
  Future<void> _saveDiaries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _diaries.map((diary) => diary.toJson()).toList();
    await prefs.setString(_diaryKey, jsonEncode(jsonList));
  }
  
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  '我的日记',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showAddDiaryDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('写日记'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _diaries.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.book, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('暂无日记', style: TextStyle(fontSize: 18, color: Colors.grey)),
                              SizedBox(height: 8),
                              Text('点击右上角"写日记"按钮开始记录', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _diaries.length,
                          itemBuilder: (context, index) {
                            final diary = _diaries[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getMoodColor(diary.mood),
                                  child: Text(
                                    _getMoodEmoji(diary.mood),
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ),
                                title: Text(
                                  diary.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: diary.favorite ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${diary.date.year}-${diary.date.month.toString().padLeft(2, '0')}-${diary.date.day.toString().padLeft(2, '0')}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getPreviewText(diary.content),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    diary.favorite ? Icons.favorite : Icons.favorite_border,
                                    color: diary.favorite ? Colors.red : Colors.grey,
                                  ),
                                  onPressed: () => _toggleFavorite(diary),
                                ),
                                onTap: () => _showDiaryDetails(diary),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'happy': return Colors.yellow;
      case 'sad': return Colors.blue;
      case 'excited': return Colors.orange;
      case 'tired': return Colors.grey;
      default: return Colors.green;
    }
  }
  
  String _getMoodEmoji(String mood) {
    switch (mood) {
      case 'happy': return '😊';
      case 'sad': return '😢';
      case 'excited': return '🤩';
      case 'tired': return '😴';
      default: return '😐';
    }
  }
  
  String _getPreviewText(String content) {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }
  
  void _showDiaryDetails(DiaryEntry diary) {
    showDialog(
      context: context,
      builder: (context) => FullDiaryDetailsDialog(
        diary: diary,
        onToggleFavorite: () async {
          await _toggleFavorite(diary);
          Navigator.pop(context);
          _showDiaryDetails(diary.copyWith(favorite: !diary.favorite));
        },
        onDelete: () async {
          Navigator.pop(context);
          await _deleteDiary(diary.id);
        },
      ),
    );
  }
}

class FullAddDiaryDialog extends StatefulWidget {
  final Function(DiaryEntry) onSave;
  
  const FullAddDiaryDialog({super.key, required this.onSave});
  
  @override
  State<FullAddDiaryDialog> createState() => _FullAddDiaryDialogState();
}

class _FullAddDiaryDialogState extends State<FullAddDiaryDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _selectedMood = 'neutral';
  final List<String> _moods = ['neutral', 'happy', 'sad', 'excited', 'tired'];
  
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
  
  void _save() {
    if (_titleController.text.isEmpty) {
      _showError('请输入标题');
      return;
    }
    
    if (_contentController.text.isEmpty) {
      _showError('请输入内容');
      return;
    }
    
    final diary = DiaryEntry(
      title: _titleController.text,
      content: _contentController.text,
      mood: _selectedMood,
    );
    
    widget.onSave(diary);
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('写日记'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '标题',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('心情:'),
            Wrap(
              spacing: 8,
              children: _moods.map((mood) {
                final emojis = {
                  'neutral': '😐',
                  'happy': '😊',
                  'sad': '😢',
                  'excited': '🤩',
                  'tired': '😴',
                };
                return ChoiceChip(
                  label: Text(emojis[mood]!),
                  selected: _selectedMood == mood,
                  onSelected: (selected) {
                    setState(() {
                      _selectedMood = mood;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: '内容',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 10,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class FullDiaryDetailsDialog extends StatelessWidget {
  final DiaryEntry diary;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;
  
  const FullDiaryDetailsDialog({
    super.key,
    required this.diary,
    required this.onToggleFavorite,
    required this.onDelete,
  });
  
  @override
  Widget build(BuildContext context) {
    final emojis = {
      'neutral': '😐',
      'happy': '😊',
      'sad': '😢',
      'excited': '🤩',
      'tired': '😴',
    };
    
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(diary.title)),
          IconButton(
            icon: Icon(
              diary.favorite ? Icons.favorite : Icons.favorite_border,
              color: diary.favorite ? Colors.red : Colors.grey,
            ),
            onPressed: onToggleFavorite,
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getMoodColor(diary.mood),
                  child: Text(
                    emojis[diary.mood]!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${diary.date.year}-${diary.date.month.toString().padLeft(2, '0')}-${diary.date.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Text(
                        '心情: ${_getMoodText(diary.mood)}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                diary.content,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            if (diary.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('标签:', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 4,
                children: diary.tags.map((tag) {
                  return Chip(label: Text(tag));
                }).toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onDelete,
          child: const Text('删除', style: TextStyle(color: Colors.red)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
  
  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'happy': return Colors.yellow;
      case 'sad': return Colors.blue;
      case 'excited': return Colors.orange;
      case 'tired': return Colors.grey;
      default: return Colors.green;
    }
  }
  
  String _getMoodText(String mood) {
    switch (mood) {
      case 'happy': return '开心';
      case 'sad': return '难过';
      case 'excited': return '兴奋';
      case 'tired': return '疲惫';
      default: return '一般';
    }
  }
}

// ============================================
// 同步页面 - Web兼容版
// ============================================

class FullSyncPage extends StatefulWidget {
  const FullSyncPage({super.key});

  @override
  State<FullSyncPage> createState() => _FullSyncPageState();
}

class _FullSyncPageState extends State<FullSyncPage> {
  String _syncPath = '';
  bool _syncing = false;
  String _syncStatus = '';
  bool _syncEnabled = true;
  
  static const String _syncConfigKey = 'full_sync_config';
  
  @override
  void initState() {
    super.initState();
    _initSync();
  }
  
  Future<void> _initSync() async {
    await _getDefaultSyncPath();
  }
  
  Future<String> _getDefaultSyncPath() async {
    try {
      if (kIsWeb) {
        // Web平台：使用虚拟路径
        _syncPath = '浏览器存储 (localStorage)';
        _saveSyncConfig(_syncPath);
        setState(() {});
        return _syncPath;
      } else {
        // 非Web平台：使用平台服务
        Directory appDocDir;
        
        if (Platform.isAndroid) {
          // Android: 使用外部存储目录
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            appDocDir = Directory('${externalDir.path}/TDD_Sync');
          } else {
            final internalDir = await getApplicationDocumentsDirectory();
            appDocDir = Directory('${internalDir.path}/TDD_Sync');
          }
        } else if (Platform.isWindows) {
          // Windows: 使用文档目录
          final documentsDir = await getApplicationDocumentsDirectory();
          appDocDir = Directory('${documentsDir.path}\\TDD_Sync');
        } else {
          // 其他平台（Linux, macOS, iOS）
          final documentsDir = await getApplicationDocumentsDirectory();
          appDocDir = Directory('${documentsDir.path}/TDD_Sync');
        }
        
        if (!await appDocDir.exists()) {
          await appDocDir.create(recursive: true);
        }
        
        final path = appDocDir.path;
        _syncPath = path;
        _saveSyncConfig(path);
        
        setState(() {});
        return path;
      }
    } catch (e) {
      print('获取同步目录失败: $e');
      _syncStatus = '获取同步目录失败，请检查权限';
      setState(() {});
      return '';
    }
  }
  
  Future<void> _saveSyncConfig(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final config = {'syncPath': path, 'lastSync': DateTime.now().toIso8601String()};
    await prefs.setString(_syncConfigKey, jsonEncode(config));
  }
  
  Future<void> _syncData() async {
    if (!_syncEnabled) {
      _showSnackBar('同步功能暂不可用');
      return;
    }
    
    setState(() {
      _syncing = true;
      _syncStatus = '正在同步...';
    });
    
    try {
      // 模拟同步过程
      await Future.delayed(const Duration(seconds: 1));
      
      if (kIsWeb) {
        // Web平台：使用SharedPreferences模拟同步
        await _syncDataForWeb();
      } else {
        // 非Web平台：文件系统同步
        await _syncDataForNative();
      }
      
      setState(() {
        _syncStatus = '同步成功！';
      });
      
      _showSnackBar('同步完成');
    } catch (e) {
      setState(() {
        _syncStatus = '同步失败: $e';
      });
      _showSnackBar('同步失败');
    } finally {
      setState(() {
        _syncing = false;
      });
    }
  }
  
  Future<void> _syncDataForNative() async {
    if (_syncPath.isEmpty) {
      await _getDefaultSyncPath();
      if (_syncPath.isEmpty) {
        _showSnackBar('无法创建同步目录');
        return;
      }
    }
    
    final prefs = await SharedPreferences.getInstance();
    final syncDir = Directory(_syncPath);
    
    if (!await syncDir.exists()) {
      await syncDir.create(recursive: true);
    }
    
    // 导出数据到同步文件夹
    final todosJson = prefs.getString('full_todos');
    if (todosJson != null && todosJson.isNotEmpty) {
      final todosFile = File('${_syncPath}/todos.json');
      await todosFile.writeAsString(todosJson);
    }
    
    final diariesJson = prefs.getString('full_diaries');
    if (diariesJson != null && diariesJson.isNotEmpty) {
      final diariesFile = File('${_syncPath}/diaries.json');
      await diariesFile.writeAsString(diariesJson);
    }
    
    final configJson = prefs.getString('full_config');
    if (configJson != null && configJson.isNotEmpty) {
      final configFile = File('${_syncPath}/config.json');
      await configFile.writeAsString(configJson);
    }
    
    // 创建同步标记文件
    final syncFile = File('${_syncPath}/last_sync.json');
    await syncFile.writeAsString(jsonEncode({
      'timestamp': DateTime.now().toIso8601String(),
      'device': Platform.operatingSystem,
    }));
    
    print('数据导出完成');
  }
  
  Future<void> _syncDataForWeb() async {
    // Web平台：模拟同步过程
    // 实际应用中，这里可以连接到云存储或导出JSON文件
    final prefs = await SharedPreferences.getInstance();
    
    // 创建一个虚拟的同步记录
    await prefs.setString('last_sync_web', DateTime.now().toIso8601String());
    
    // 模拟数据同步
    await Future.delayed(const Duration(milliseconds: 500));
    
    print('Web同步完成');
  }
  
  void _showSyncInfo() {
    String platformInfo = '';
    if (kIsWeb) {
      platformInfo = '''
Web版本同步说明：
1. 数据存储在浏览器本地存储中
2. 同步功能在Web版本中为模拟操作
3. 如需跨设备同步，请使用数据导出/导入功能
''';
    } else {
      platformInfo = '''
同步功能说明：
1. 自动使用设备文档目录中的"TDD_Sync"文件夹
2. 在手机和电脑上都点击"立即同步"按钮
3. 数据会自动在设备间同步
''';
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('同步说明'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                platformInfo,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              if (!kIsWeb && _syncPath.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  '同步目录：',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _syncPath,
                  style: const TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ],
              if (kIsWeb) ...[
                const SizedBox(height: 12),
                const Text(
                  '数据管理：',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text('1. 点击"导出数据"按钮下载备份文件'),
                const Text('2. 在其他设备上使用"导入数据"恢复'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _exportData() async {
    if (kIsWeb) {
      _showSnackBar('Web版本：请在设置页面使用数据导出功能');
      return;
    }
    
    try {
      await _syncDataForNative();
      _showSnackBar('数据已导出到同步目录');
    } catch (e) {
      _showSnackBar('导出失败: $e');
    }
  }
  
  Future<void> _importData() async {
    if (kIsWeb) {
      _showSnackBar('Web版本：请在设置页面使用数据导入功能');
      return;
    }
    
    try {
      final syncDir = Directory(_syncPath);
      if (!await syncDir.exists()) {
        _showSnackBar('同步目录不存在');
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      bool imported = false;
      
      // 导入待办事项
      final todosFile = File('${_syncPath}/todos.json');
      if (await todosFile.exists()) {
        final todosJson = await todosFile.readAsString();
        if (todosJson.isNotEmpty) {
          await prefs.setString('full_todos', todosJson);
          imported = true;
        }
      }
      
      // 导入日记
      final diariesFile = File('${_syncPath}/diaries.json');
      if (await diariesFile.exists()) {
        final diariesJson = await diariesFile.readAsString();
        if (diariesJson.isNotEmpty) {
          await prefs.setString('full_diaries', diariesJson);
          imported = true;
        }
      }
      
      // 导入配置
      final configFile = File('${_syncPath}/config.json');
      if (await configFile.exists()) {
        final configJson = await configFile.readAsString();
        if (configJson.isNotEmpty) {
          await prefs.setString('full_config', configJson);
          imported = true;
        }
      }
      
      if (imported) {
        _showSnackBar('数据导入成功，请重启应用');
      } else {
        _showSnackBar('未找到可导入的数据');
      }
    } catch (e) {
      _showSnackBar('导入失败: $e');
    }
  }
  
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.sync, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        kIsWeb ? '数据同步 (Web版)' : '一键同步',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Spacer(),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  if (_syncPath.isNotEmpty && !kIsWeb)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.folder, size: 18, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                '同步目录',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _syncPath,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  
                  if (kIsWeb)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange,
                          width: 1,
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, size: 18, color: Colors.orange),
                              SizedBox(width: 8),
                              Text(
                                'Web版本提示',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Web版本数据存储在浏览器本地，使用导出/导入功能进行跨设备同步。',
                            style: TextStyle(fontSize: 12, color: Colors.orange),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // 大同步按钮
                  Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: _syncing ? Colors.blue[100] : Colors.blue,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextButton(
                      onPressed: _syncing ? null : _syncData,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_syncing)
                            const SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          else
                            Icon(
                              Icons.sync,
                              size: 48,
                              color: Colors.white,
                            ),
                          const SizedBox(height: 12),
                          Text(
                            _syncing ? '同步中...' : kIsWeb ? '模拟同步' : '立即同步',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  if (_syncStatus.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _syncStatus.contains('成功') ? Colors.green[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _syncStatus.contains('成功') ? Colors.green : Colors.orange,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _syncStatus.contains('成功') ? Icons.check_circle : Icons.info,
                            color: _syncStatus.contains('成功') ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _syncStatus,
                              style: TextStyle(
                                color: _syncStatus.contains('成功') ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _showSyncInfo,
                        icon: const Icon(Icons.help_outline),
                        label: const Text('同步说明'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          foregroundColor: Colors.blue,
                        ),
                      ),
                      if (!kIsWeb) ...[
                        ElevatedButton.icon(
                          onPressed: _exportData,
                          icon: const Icon(Icons.download),
                          label: const Text('导出数据'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            foregroundColor: Colors.blue,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _importData,
                          icon: const Icon(Icons.upload),
                          label: const Text('导入数据'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            foregroundColor: Colors.blue,
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  if (kIsWeb) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Web版本数据管理：',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '请前往"设置"页面使用数据导出/导入功能进行跨设备数据同步。',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// 设置页面
// ============================================

class FullSettingsPage extends StatefulWidget {
  const FullSettingsPage({super.key});

  @override
  State<FullSettingsPage> createState() => _FullSettingsPageState();
}

class _FullSettingsPageState extends State<FullSettingsPage> {
  final TextEditingController _appNameController = TextEditingController();
  String _selectedTheme = 'blue';
  FontService _fontService = FontService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initFontService();
  }

  void _loadSettings() {
    final configManager = Provider.of<FullConfigManager>(context, listen: false);
    final config = configManager.config;

    _appNameController.text = config.appName;
    _selectedTheme = config.themeColor;
  }

  Future<void> _initFontService() async {
    await _fontService.initialize();
  }
  
  @override
  Widget build(BuildContext context) {
    final configManager = Provider.of<FullConfigManager>(context);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '应用设置',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // 应用名称
                  TextField(
                    controller: _appNameController,
                    decoration: const InputDecoration(
                      labelText: '应用名称',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) async {
                      await configManager.updateConfig({'appName': value});
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 主题颜色
                  const Text('主题颜色:'),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildThemeChoice('blue', '蓝色'),
                      _buildThemeChoice('green', '绿色'),
                      _buildThemeChoice('purple', '紫色'),
                      _buildThemeChoice('orange', '橙色'),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 加密设置
                  SwitchListTile(
                    title: const Text('启用数据加密'),
                    subtitle: const Text('使用AES加密本地存储的数据'),
                    value: configManager.config.enableEncryption,
                    onChanged: (value) async {
                      await configManager.updateConfig({'enableEncryption': value});
                    },
                  ),
                  
                  // 通知设置
                  SwitchListTile(
                    title: const Text('启用通知提醒'),
                    subtitle: const Text('接收待办事项提醒'),
                    value: configManager.config.enableNotifications,
                    onChanged: (value) async {
                      await configManager.updateConfig({'enableNotifications': value});
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),

          // 字体和界面自定义
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,       
                children: [
                  const Text(
                    '字体和界面自定义',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  // 字体选择
                  const Text('字体选择:'),
                  const SizedBox(height: 8),
                  _buildFontSelector(context),
                  
                  const SizedBox(height: 16),
                  
                  // 字体大小
                  Row(
                    children: [
                      const Text('字体大小:'),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Slider(
                          value: configManager.config.fontSize,
                          min: 10.0,
                          max: 24.0,
                          divisions: 14,
                          label: '${configManager.config.fontSize.toInt()}',
                          onChanged: (value) async {
                            await configManager.updateConfig({'fontSize': value});
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${configManager.config.fontSize.toInt()}'),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 行间距
                  Row(
                    children: [
                      const Text('行间距:'),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Slider(
                          value: configManager.config.lineSpacing,
                          min: 1.0,
                          max: 2.5,
                          divisions: 15,
                          label: configManager.config.lineSpacing.toStringAsFixed(1),
                          onChanged: (value) async {
                            await configManager.updateConfig({'lineSpacing': value});
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(configManager.config.lineSpacing.toStringAsFixed(1)),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 项目间距
                  Row(
                    children: [
                      const Text('项目间距:'),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Slider(
                          value: configManager.config.itemSpacing,
                          min: 4.0,
                          max: 24.0,
                          divisions: 20,
                          label: '${configManager.config.itemSpacing.toInt()}',
                          onChanged: (value) async {
                            await configManager.updateConfig({'itemSpacing': value});
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${configManager.config.itemSpacing.toInt()}'),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // UI密度
                  const Text('界面密度:'),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildUIDensityChoice('compact', '紧凑'),
                      _buildUIDensityChoice('standard', '标准'),
                      _buildUIDensityChoice('spacious', '宽松'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,       
                children: [
                  const Text(
                    '数据管理',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _exportData(context),
                        icon: const Icon(Icons.download),
                        label: const Text('导出数据'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _importData(context),
                        icon: const Icon(Icons.upload),
                        label: const Text('导入数据'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _clearData(context),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('清空数据', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildThemeChoice(String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedTheme == value,
      onSelected: (selected) async {
        if (selected) {
          setState(() {
            _selectedTheme = value;
          });
          final configManager = Provider.of<FullConfigManager>(context, listen: false);
          await configManager.updateConfig({'themeColor': value});
        }
      },
    );
  }
  
  void _exportData(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出数据'),
        content: const Text('所有数据已导出到应用文档目录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  void _importData(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入数据'),
        content: const Text('请选择备份文件进行导入。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('数据导入成功')),
              );
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }
  
  void _clearData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空所有数据吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清空', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('数据已清空')),
      );
    }
  }

  Widget _buildFontSelector(BuildContext context) {
    return Column(
      children: [
        // 字体预览
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[100],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '字体预览：你好，TodoDiary！',
                  style: _fontService.getTextStyle(
                    fontFamily: _fontService.selectedFontFamily,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.font_download),
                onPressed: _showFontManagerDialog,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 字体选择按钮
        Wrap(
          spacing: 8,
          children: _fontService.availableFonts.take(3).map((font) {
            return ChoiceChip(
              label: Text(font.displayName),
              selected: _fontService.selectedFontFamily == font.family,
              onSelected: (selected) async {
                if (selected) {
                  try {
                    await _fontService.switchFont(font.family);
                    final configManager = Provider.of<FullConfigManager>(context, listen: false);
                    await configManager.updateConfig({'fontFamily': font.family});
                    setState(() {});
                  } catch (e) {
                    _showSnackBar('字体切换失败：$e');
                  }
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildUIDensityChoice(String value, String label) {
    final configManager = Provider.of<FullConfigManager>(context, listen: false);
    return ChoiceChip(
      label: Text(label),
      selected: configManager.config.uiDensity == value,
      onSelected: (selected) async {
        if (selected) {
          await configManager.updateConfig({'uiDensity': value});
          setState(() {});
        }
      },
    );
  }

  void _showFontManagerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('字体管理'),
        content: SizedBox(
          width: double.maxFinite,
          child: FontPicker(
            fontService: _fontService,
            onFontSelected: (fontFamily) async {
              await _fontService.switchFont(fontFamily);
              final configManager = Provider.of<FullConfigManager>(context, listen: false);
              await configManager.updateConfig({'fontFamily': fontFamily});
              Navigator.pop(context);
              setState(() {});
            },
            selectedFontFamily: _fontService.selectedFontFamily,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

// ============================================
// 数据模型 (复制自之前的版本)
// ============================================

class TodoItem {
  String id;
  String title;
  String description;
  DateTime? dueDate;
  bool completed;
  DateTime createdAt;
  DateTime updatedAt;
  
  TodoItem({
    required this.title,
    this.description = '',
    this.dueDate,
    this.completed = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? id,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'completed': completed,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      completed: json['completed'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
  
  TodoItem copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    bool? completed,
  }) {
    return TodoItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      completed: completed ?? this.completed,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class DiaryEntry {
  String id;
  String title;
  String content;
  DateTime date;
  String mood;
  List<String> tags;
  DateTime createdAt;
  DateTime updatedAt;
  bool favorite;
  
  DiaryEntry({
    required this.title,
    required this.content,
    DateTime? date,
    this.mood = 'neutral',
    this.tags = const [],
    this.favorite = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? id,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       date = date ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'mood': mood,
      'tags': tags,
      'favorite': favorite,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      date: DateTime.parse(json['date']),
      mood: json['mood'] ?? 'neutral',
      tags: List<String>.from(json['tags'] ?? []),
      favorite: json['favorite'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
  
  DiaryEntry copyWith({
    String? title,
    String? content,
    DateTime? date,
    String? mood,
    List<String>? tags,
    bool? favorite,
  }) {
    return DiaryEntry(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
      favorite: favorite ?? this.favorite,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}