import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_diary/models/todo_item.dart';
import 'package:todo_diary/services/database_service.dart';
import 'package:todo_diary/theme/app_theme.dart';
import 'todo_page.dart';
import 'diary_page.dart';
import 'stats_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const TodoPage(),
    const DiaryPage(),
    const StatsPage(),
    const SettingsPage(),
  ];
  
  final List<String> _pageTitles = [
    '待办事项',
    '日记',
    '统计',
    '设置',
  ];
  
  @override
  void initState() {
    super.initState();
  }
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        centerTitle: true,
        actions: [
          if (_selectedIndex == 0 || _selectedIndex == 1) ...[
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                // 根据当前页面执行不同的添加操作
                if (_selectedIndex == 0) {
                  _showAddTodoDialog(context);
                } else if (_selectedIndex == 1) {
                  _navigateToAddDiary(context);
                }
              },
            ),
          ],
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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
            icon: Icon(Icons.analytics),
            label: '统计',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton(
        onPressed: () => _showAddTodoDialog(context),
        child: const Icon(Icons.add),
      ) : null,
    );
  }
  
  void _showAddTodoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddTodoDialog(
        onTodoAdded: () {
          // 刷新待办事项列表
          final dbService = Provider.of<DatabaseService>(context, listen: false);
          // 这里可以通过其他方式通知页面刷新
        },
      ),
    );
  }
  
  void _navigateToAddDiary(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddDiaryPage(),
      ),
    );
  }
}

// 简单的添加待办事项对话框（简化版）
class AddTodoDialog extends StatefulWidget {
  final VoidCallback onTodoAdded;
  
  const AddTodoDialog({super.key, required this.onTodoAdded});
  
  @override
  State<AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<AddTodoDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  Priority _selectedPriority = Priority.medium;
  DateTime? _dueDate;
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }
  
  Future<void> _saveTodo() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入标题')),
      );
      return;
    }
    
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    
    final todo = TodoItem(
      title: _titleController.text,
      description: _descriptionController.text,
      dueDate: _dueDate,
      priority: _selectedPriority,
      tags: [],
    );
    
    await dbService.insertTodo(todo);
    
    widget.onTodoAdded();
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('待办事项已添加')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加待办事项'),
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
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '描述（可选）',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Priority>(
              value: _selectedPriority,
              onChanged: (value) {
                setState(() {
                  _selectedPriority = value!;
                });
              },
              items: Priority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(priority.displayName),
                );
              }).toList(),
              decoration: const InputDecoration(
                labelText: '优先级',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _dueDate == null
                        ? '无截止日期'
                        : '截止日期: ${_dueDate!.toString().substring(0, 10)}',
                  ),
                ),
                TextButton(
                  onPressed: () => _selectDueDate(context),
                  child: const Text('选择日期'),
                ),
              ],
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
          onPressed: _saveTodo,
          child: const Text('保存'),
        ),
      ],
    );
  }
}