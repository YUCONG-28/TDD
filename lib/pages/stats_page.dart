import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_diary/services/database_service.dart';
import 'package:todo_diary/theme/app_theme.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  Map<String, dynamic>? _stats;
  
  @override
  void initState() {
    super.initState();
    _loadStats();
  }
  
  Future<void> _loadStats() async {
    final dbService = Provider.of<DatabaseService>(
      context,
      listen: false,
    );
    
    final stats = await dbService.getStats();
    setState(() {
      _stats = stats;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '统计概览',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_stats == null)
            const Center(child: CircularProgressIndicator())
          else
            _buildStatsContent(),
          
          const SizedBox(height: 32),
          const Text(
            '使用建议',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          _buildSuggestions(),
        ],
      ),
    );
  }
  
  Widget _buildStatsContent() {
    final todoStats = _stats!['todo'] as Map<String, dynamic>;
    final diaryStats = _stats!['diary'] as Map<String, dynamic>;
    
    return Column(
      children: [
        // 待办事项统计卡片
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📋 待办事项统计',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(
                      '总数',
                      todoStats['total'].toString(),
                      Colors.blue,
                    ),
                    _buildStatItem(
                      '已完成',
                      todoStats['completed'].toString(),
                      Colors.green,
                    ),
                    _buildStatItem(
                      '待处理',
                      todoStats['pending'].toString(),
                      Colors.orange,
                    ),
                    _buildStatItem(
                      '已过期',
                      todoStats['overdue'].toString(),
                      Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: todoStats['total'] > 0
                      ? (todoStats['completed'] as int) / (todoStats['total'] as int)
                      : 0,
                  backgroundColor: Colors.grey[200],
                  color: Colors.green,
                ),
                const SizedBox(height: 8),
                Text(
                  '完成率: ${todoStats['total'] > 0 ? ((todoStats['completed'] as int) / (todoStats['total'] as int) * 100).toStringAsFixed(1) : 0}%',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 日记统计卡片
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📖 日记统计',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(
                      '总篇数',
                      diaryStats['total'].toString(),
                      Colors.purple,
                    ),
                    _buildStatItem(
                      '收藏',
                      diaryStats['favorites'].toString(),
                      Colors.pink,
                    ),
                    _buildStatItem(
                      '记录天数',
                      diaryStats['daysWithEntries'].toString(),
                      Colors.amber,
                    ),
                    _buildStatItem(
                      '平均字数',
                      _calculateAverageWords(diaryStats).toString(),
                      Colors.teal,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (diaryStats['daysWithEntries'] > 0)
                  Text(
                    '活跃度: ${(diaryStats['daysWithEntries'] as int) > 7 ? '高' : (diaryStats['daysWithEntries'] as int) > 3 ? '中' : '低'}',
                    style: const TextStyle(fontSize: 14),
                  ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 最近活动卡片
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📈 最近活动',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<dynamic>>(
                  future: _getRecentActivity(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final activities = snapshot.data ?? [];
                    
                    if (activities.isEmpty) {
                      return const Center(
                        child: Text('暂无最近活动'),
                      );
                    }
                    
                    return Column(
                      children: activities.take(5).map((activity) {
                        return ListTile(
                          leading: Icon(activity['icon']),
                          title: Text(activity['title']),
                          subtitle: Text(activity['subtitle']),
                          trailing: Text(activity['time']),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
  
  int _calculateAverageWords(Map<String, dynamic> diaryStats) {
    // 这里需要实际计算平均字数
    // 简化版：假设每篇日记平均200字
    final total = diaryStats['total'] as int;
    return total > 0 ? (total * 200) ~/ total : 0;
  }
  
  Future<List<Map<String, dynamic>>> _getRecentActivity() async {
    // 这里应该从数据库获取最近的活动
    // 简化版：返回模拟数据
    
    return [
      {
        'icon': Icons.check_circle,
        'title': '完成待办事项',
        'subtitle': '完成"项目会议准备"',
        'time': '2小时前',
      },
      {
        'icon': Icons.book,
        'title': '添加日记',
        'subtitle': '记录"美好的一天"',
        'time': '今天',
      },
      {
        'icon': Icons.notifications,
        'title': '设置提醒',
        'subtitle': '为"购物清单"设置提醒',
        'time': '昨天',
      },
      {
        'icon': Icons.favorite,
        'title': '收藏日记',
        'subtitle': '收藏"重要回忆"',
        'time': '2天前',
      },
    ];
  }
  
  Widget _buildSuggestions() {
    final todoStats = _stats?['todo'] as Map<String, dynamic>?;
    final diaryStats = _stats?['diary'] as Map<String, dynamic>?;
    
    final suggestions = <String>[];
    
    if (todoStats != null) {
      final overdue = todoStats['overdue'] as int;
      final pending = todoStats['pending'] as int;
      
      if (overdue > 0) {
        suggestions.add('您有 $overdue 个已过期待办事项，请及时处理。');
      }
      
      if (pending > 5) {
        suggestions.add('您有 $pending 个待处理事项，建议优先处理重要事项。');
      }
      
      if (todoStats['total'] == 0) {
        suggestions.add('开始添加您的第一个待办事项吧！');
      }
    }
    
    if (diaryStats != null) {
      final daysWithEntries = diaryStats['daysWithEntries'] as int;
      
      if (daysWithEntries < 3) {
        suggestions.add('最近记录较少，坚持写日记有助于记录生活点滴。');
      }
      
      if (diaryStats['total'] == 0) {
        suggestions.add('写下您的第一篇日记，记录此刻的心情。');
      }
    }
    
    if (suggestions.isEmpty) {
      suggestions.add('继续保持良好的使用习惯！');
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  '个性化建议',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...suggestions.map((suggestion) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(suggestion),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 当依赖项变化时重新加载数据
    _loadStats();
  }
}