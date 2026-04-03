import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_diary/services/sync_service.dart';
import 'package:todo_diary/services/notification_service.dart';
import 'package:todo_diary/theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false;
  bool _autoSync = true;
  bool _enableNotifications = true;
  TimeOfDay? _dailyReminderTime;
  
  @override
  Widget build(BuildContext context) {
    final syncService = Provider.of<SyncService>(context);
    final notificationService = Provider.of<NotificationService>(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '设置',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // 同步设置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🔄 数据同步',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // 同步状态
                  ListTile(
                    leading: const Icon(Icons.sync),
                    title: const Text('同步状态'),
                    subtitle: Text(syncService.getSyncStatusMessage()),
                    trailing: syncService.isSyncing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                  ),
                  
                  // 同步配置
                  if (syncService.isConfigured)
                    Column(
                      children: [
                        SwitchListTile(
                          title: const Text('启用同步'),
                          value: syncService.syncEnabled,
                          onChanged: (value) {
                            syncService.setSyncEnabled(value);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.cloud_sync),
                          title: const Text('立即同步'),
                          onTap: () async {
                            final result = await syncService.sync();
                            _showSnackBar(context, result.message);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete),
                          title: const Text('清除同步配置'),
                          textColor: Colors.red,
                          onTap: () {
                            _showDeleteSyncConfigDialog(context, syncService);
                          },
                        ),
                      ],
                    )
                  else
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('配置同步'),
                      onTap: () {
                        _showSyncConfigDialog(context, syncService);
                      },
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 通知设置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🔔 通知设置',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  SwitchListTile(
                    title: const Text('启用通知'),
                    value: _enableNotifications,
                    onChanged: (value) {
                      setState(() {
                        _enableNotifications = value;
                      });
                    },
                  ),
                  
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('每日日记提醒'),
                    subtitle: Text(
                      _dailyReminderTime == null
                          ? '未设置'
                          : '每天 ${_dailyReminderTime!.format(context)}',
                    ),
                    onTap: () {
                      _selectDailyReminderTime(context, notificationService);
                    },
                  ),
                  
                  if (_dailyReminderTime != null)
                    ListTile(
                      leading: const Icon(Icons.delete),
                      title: const Text('清除提醒'),
                      onTap: () {
                        setState(() {
                          _dailyReminderTime = null;
                        });
                        notificationService.cancelDailyDiaryReminder();
                        _showSnackBar(context, '已清除每日提醒');
                      },
                    ),
                  
                  ListTile(
                    leading: const Icon(Icons.notification_important),
                    title: const Text('测试通知'),
                    onTap: () async {
                      await notificationService.testNotification();
                      _showSnackBar(context, '测试通知已发送');
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 外观设置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎨 外观设置',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  SwitchListTile(
                    title: const Text('深色模式'),
                    value: _darkMode,
                    onChanged: (value) {
                      setState(() {
                        _darkMode = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 数据管理
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💾 数据管理',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  ListTile(
                    leading: const Icon(Icons.backup),
                    title: const Text('备份数据'),
                    onTap: () {
                      _showSnackBar(context, '备份功能开发中...');
                    },
                  ),
                  
                  ListTile(
                    leading: const Icon(Icons.restore),
                    title: const Text('恢复数据'),
                    onTap: () {
                      _showSnackBar(context, '恢复功能开发中...');
                    },
                  ),
                  
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('清除所有数据', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      _showClearDataDialog(context);
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 关于
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ℹ️ 关于',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('版本'),
                    subtitle: const Text('1.0.0'),
                  ),
                  
                  ListTile(
                    leading: const Icon(Icons.code),
                    title: const Text('开发者'),
                    subtitle: const Text('Todo & Diary Team'),
                  ),
                  
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('反馈'),
                    onTap: () {
                      _showSnackBar(context, '反馈功能开发中...');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
  void _showSyncConfigDialog(BuildContext context, SyncService syncService) {
    final urlController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('配置同步'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'WebDAV服务器URL',
                  hintText: 'https://example.com/webdav',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: '用户名',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '密码',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '支持的服务器：坚果云、Nextcloud、OwnCloud等',
                style: TextStyle(fontSize: 12, color: Colors.grey),
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
            onPressed: () async {
              if (urlController.text.isEmpty ||
                  usernameController.text.isEmpty ||
                  passwordController.text.isEmpty) {
                _showSnackBar(context, '请填写所有字段');
                return;
              }
              
              final config = SyncConfig(
                url: urlController.text,
                username: usernameController.text,
                password: passwordController.text,
              );
              
              await syncService.saveConfig(config);
              await syncService.setSyncEnabled(true);
              
              if (mounted) {
                Navigator.pop(context);
                _showSnackBar(context, '同步配置已保存');
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteSyncConfigDialog(BuildContext context, SyncService syncService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除同步配置'),
        content: const Text('确定要清除同步配置吗？这将删除所有同步设置。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              await syncService.deleteConfig();
              if (mounted) {
                Navigator.pop(context);
                _showSnackBar(context, '同步配置已清除');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _selectDailyReminderTime(
    BuildContext context,
    NotificationService notificationService,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (picked != null) {
      setState(() {
        _dailyReminderTime = picked;
      });
      
      await notificationService.scheduleDailyDiaryReminder(picked);
      _showSnackBar(context, '每日提醒已设置为 ${picked.format(context)}');
    }
  }
  
  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除所有数据'),
        content: const Text('确定要清除所有数据吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: 实现清除所有数据
              if (mounted) {
                Navigator.pop(context);
                _showSnackBar(context, '数据已清除');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }
}
