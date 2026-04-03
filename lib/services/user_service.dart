import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart';
import 'package:http/http.dart' as http;

class UserService extends ChangeNotifier {
  static const String _prefKeyUserData = 'user_data';
  static const String _prefKeyAuthToken = 'user_auth_token';
  static const String _prefKeyUserId = 'user_id';
  static const String _prefKeyIsLoggedIn = 'user_is_logged_in';
  static const String _prefKeyLastSync = 'user_last_sync_time';
  
  // 模拟后端API地址（实际项目中需要替换为真实API）
  static const String _apiBaseUrl = 'https://api.your-todo-diary.com';
  
  User? _currentUser;
  String? _authToken;
  bool _isLoading = false;
  String? _lastError;
  DateTime? _lastSyncTime;
  
  UserService() {
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final isLoggedIn = prefs.getBool(_prefKeyIsLoggedIn) ?? false;
    _authToken = prefs.getString(_prefKeyAuthToken);
    _lastSyncTime = prefs.getString(_prefKeyLastSync) != null
        ? DateTime.parse(prefs.getString(_prefKeyLastSync)!)
        : null;
    
    if (isLoggedIn && _authToken != null) {
      final userDataJson = prefs.getString(_prefKeyUserData);
      if (userDataJson != null) {
        try {
          _currentUser = User.fromJson(jsonDecode(userDataJson));
        } catch (e) {
          debugPrint('Failed to load user data: $e');
          // 数据损坏，清除用户数据
          await _clearUserData();
        }
      }
    }
    
    notifyListeners();
  }
  
  Future<LoginResult> login(String email, String password) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    
    try {
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      
      // 这里应该是真实的API调用
      /*
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _authToken = data['token'];
        _currentUser = User.fromJson(data['user']);
      } else {
        throw Exception('登录失败: ${response.statusCode}');
      }
      */
      
      // 模拟成功登录
      _authToken = 'mock_auth_token_${DateTime.now().millisecondsSinceEpoch}';
      _currentUser = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        username: email.split('@')[0],
        displayName: '用户${email.split('@')[0]}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // 保存到本地存储
      await _saveUserData();
      
      _isLoading = false;
      notifyListeners();
      
      return LoginResult(
        success: true,
        message: '登录成功',
        user: _currentUser!,
      );
    } catch (e) {
      _isLoading = false;
      _lastError = e.toString();
      notifyListeners();
      
      return LoginResult(
        success: false,
        message: '登录失败: $e',
      );
    }
  }
  
  Future<RegisterResult> register(String email, String password, String username) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    
    try {
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      
      // 这里应该是真实的API调用
      /*
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'username': username,
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _authToken = data['token'];
        _currentUser = User.fromJson(data['user']);
      } else {
        throw Exception('注册失败: ${response.statusCode}');
      }
      */
      
      // 模拟成功注册
      _authToken = 'mock_auth_token_${DateTime.now().millisecondsSinceEpoch}';
      _currentUser = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        username: username,
        displayName: username,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // 保存到本地存储
      await _saveUserData();
      
      _isLoading = false;
      notifyListeners();
      
      return RegisterResult(
        success: true,
        message: '注册成功',
        user: _currentUser!,
      );
    } catch (e) {
      _isLoading = false;
      _lastError = e.toString();
      notifyListeners();
      
      return RegisterResult(
        success: false,
        message: '注册失败: $e',
      );
    }
  }
  
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // 模拟API调用注销
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 清除本地用户数据
      await _clearUserData();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _lastError = e.toString();
      notifyListeners();
    }
  }
  
  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (_currentUser != null) {
      await prefs.setString(_prefKeyUserData, jsonEncode(_currentUser!.toJson()));
    }
    
    if (_authToken != null) {
      await prefs.setString(_prefKeyAuthToken, _authToken!);
    }
    
    await prefs.setBool(_prefKeyIsLoggedIn, true);
    
    if (_currentUser != null && _currentUser!.id != null) {
      await prefs.setString(_prefKeyUserId, _currentUser!.id!);
    }
    
    _lastSyncTime = DateTime.now();
    await prefs.setString(_prefKeyLastSync, _lastSyncTime!.toIso8601String());
  }
  
  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove(_prefKeyUserData);
    await prefs.remove(_prefKeyAuthToken);
    await prefs.remove(_prefKeyUserId);
    await prefs.remove(_prefKeyIsLoggedIn);
    await prefs.remove(_prefKeyLastSync);
    
    _currentUser = null;
    _authToken = null;
    _lastSyncTime = null;
  }
  
  Future<User?> getCurrentUser() async {
    if (_currentUser == null) {
      await _loadUserData();
    }
    return _currentUser;
  }
  
  Future<bool> isLoggedIn() async {
    if (_currentUser == null || _authToken == null) {
      await _loadUserData();
    }
    return _currentUser != null && _authToken != null;
  }
  
  Future<void> updateProfile(User updatedUser) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    
    try {
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      
      // 更新用户信息
      _currentUser = updatedUser;
      
      // 保存到本地存储
      await _saveUserData();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _lastError = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  Future<void> changePassword(String oldPassword, String newPassword) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    
    try {
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      
      // 这里应该是真实的API调用
      /*
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('修改密码失败');
      }
      */
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _lastError = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  Future<void> syncUserData() async {
    if (!await isLoggedIn()) {
      return;
    }
    
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    
    try {
      // 模拟API调用同步数据
      await Future.delayed(const Duration(seconds: 2));
      
      // 更新最后同步时间
      _lastSyncTime = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyLastSync, _lastSyncTime!.toIso8601String());
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _lastError = e.toString();
      notifyListeners();
    }
  }
  
  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get authToken => _authToken;
  
  // 用户统计信息
  Future<UserStats> getUserStats() async {
    // 这里应该从API获取用户统计信息
    // 暂时返回模拟数据
    return UserStats(
      totalTodos: 24,
      completedTodos: 18,
      totalDiaries: 12,
      streakDays: 7,
      lastActive: DateTime.now(),
    );
  }
}

class User {
  final String? id;
  final String email;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? preferences;
  
  User({
    this.id,
    required this.email,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    this.preferences,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'preferences': preferences,
    };
  }
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
