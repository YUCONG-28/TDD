import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_diary/models/todo_item.dart';
import 'package:todo_diary/services/database_service.dart';
import 'package:todo_diary/theme/app_theme.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  String _selectedFilter = '全部';
  final List<String> _filters = ['全部', '待办', '已完成', '今天到期', '已过期'];
  
  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    
    return Column(
      children: [
        // 筛选器
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              final filter = _filters[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: FilterChip(
                  label: Text(filter),
                  selected: _selectedFilter == filter,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                ),
              );
            },
          ),
        ),
        
        // 待办事项列表
        Expanded(
          child: FutureBuilder<List<TodoItem>>(
            future: _getTodosByFilter(dbService, _selectedFilter),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Text('加载失败: ${snapshot.error}'),
                );
              }
              
              final todos = snapshot.data ?? [];
              
              if (todos.isEmpty) {
                return _buildEmptyState();
              }
              
              return ListView.builder(
                itemCount: todos.length,
                itemBuilder: (context, index) {
                  final todo = todos[index];
                  return _buildTodoItem(todo, dbService);
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  Future<List<TodoItem>> _getTodosByFilter(
    DatabaseService dbService, 
    String filter
  ) async {
    switch (filter) {
      case '全部':
        return dbService.getAllTodos();
      case '待办':
        return dbService.getAllTodos(completed: false);
      case '已完成':
        return dbService.getAllTodos(completed: true);
      case '今天到期':
        return dbService.getTodosDueToday();
      case '已过期':
        return dbService.getOverdueTodos();
      default:
        return dbService.getAllTodos();
    }
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无待办事项',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击右下角"+"按钮添加',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTodoItem(TodoItem todo, DatabaseService dbService) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Checkbox(
          value: todo.completed,
          onChanged: (value) async {
            await dbService.toggleTodoCompletion(todo.id!, value!);
            setState(() {});
          },
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.completed 
                ? TextDecoration.lineThrough 
                : TextDecoration.none,
            color: todo.completed ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (todo.description.isNotEmpty)
              Text(
                todo.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: todo.completed ? Colors.grey : null,
                ),
              ),
            if (todo.dueDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  todo.formattedDueDate,
                  style: TextStyle(
                    color: todo.isOverdue ? Colors.red : Colors.grey,
                    fontWeight: todo.isOverdue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            if (todo.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  children: todo.tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
        trailing: Icon(
          Icons.circle,
          color: todo.priority.color,
          size: 16,
        ),
        onTap: () {
          _showTodoDetails(todo, dbService);
        },
        onLongPress: () {
          _showDeleteDialog(todo, dbService);
        },
      ),
    );
  }
  
  void _showTodoDetails(TodoItem todo, DatabaseService dbService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(todo.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (todo.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(todo.description),
                ),
              
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('截止日期'),
                trailing: Text(
                  todo.dueDate == null 
                      ? '无' 
                      : todo.formattedDueDate,
                ),
              ),
              
              ListTile(
                leading: const Icon(Icons.priority_high),
                title: const Text('优先级'),
                trailing: Text(todo.priority.displayName),
              ),
              
              if (todo.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('标签:'),
                Wrap(
                  spacing: 4,
                  children: todo.tags.map((tag) {
                    return Chip(label: Text(tag));
                  }).toList(),
                ),
              ],
              
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('创建时间'),
                trailing: Text(
                  '${todo.createdAt.year}/${todo.createdAt.month}/${todo.createdAt.day}',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 实现编辑功能
            },
            child: const Text('编辑'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteDialog(TodoItem todo, DatabaseService dbService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除待办事项'),
        content: Text('确定要删除"${todo.title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              await dbService.deleteTodo(todo.id!);
              if (mounted) {
                setState(() {});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已删除')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}