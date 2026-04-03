import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_diary/models/diary_entry.dart';
import 'package:todo_diary/services/database_service.dart';
import 'package:todo_diary/theme/app_theme.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  String _selectedFilter = '全部';
  final List<String> _filters = ['全部', '收藏', '最近'];
  String _searchQuery = '';
  
  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    
    return Column(
      children: [
        // 搜索框和筛选器
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: '搜索日记...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
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
            ],
          ),
        ),
        
        // 日记列表
        Expanded(
          child: FutureBuilder<List<DiaryEntry>>(
            future: _getDiariesByFilter(dbService, _selectedFilter, _searchQuery),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Text('加载失败: ${snapshot.error}'),
                );
              }
              
              final diaries = snapshot.data ?? [];
              
              if (diaries.isEmpty) {
                return _buildEmptyState();
              }
              
              return ListView.builder(
                itemCount: diaries.length,
                itemBuilder: (context, index) {
                  final diary = diaries[index];
                  return _buildDiaryItem(diary, dbService);
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  Future<List<DiaryEntry>> _getDiariesByFilter(
    DatabaseService dbService, 
    String filter,
    String searchQuery
  ) async {
    List<DiaryEntry> diaries;
    
    if (searchQuery.isNotEmpty) {
      diaries = await dbService.searchDiaries(searchQuery);
    } else {
      switch (filter) {
        case '全部':
          diaries = await dbService.getAllDiaries();
          break;
        case '收藏':
          diaries = await dbService.getAllDiaries(favorite: true);
          break;
        case '最近':
          final now = DateTime.now();
          final weekAgo = now.subtract(const Duration(days: 7));
          diaries = await dbService.getDiariesByDateRange(weekAgo, now);
          break;
        default:
          diaries = await dbService.getAllDiaries();
      }
    }
    
    return diaries;
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无日记',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击右上角"+"按钮添加日记',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDiaryItem(DiaryEntry diary, DatabaseService dbService) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.getMoodColor(diary.mood),
          child: Text(
            diary.moodEmoji,
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
              diary.formattedDate,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              _getPreviewText(diary.content),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            if (diary.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  children: diary.tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            diary.favorite ? Icons.favorite : Icons.favorite_border,
            color: diary.favorite ? Colors.red : Colors.grey,
          ),
          onPressed: () async {
            await dbService.toggleDiaryFavorite(diary.id!, !diary.favorite);
            setState(() {});
          },
        ),
        onTap: () {
          _showDiaryDetails(diary, dbService);
        },
        onLongPress: () {
          _showDeleteDialog(diary, dbService);
        },
      ),
    );
  }
  
  String _getPreviewText(String content) {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }
  
  void _showDiaryDetails(DiaryEntry diary, DatabaseService dbService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(diary.title),
            const Spacer(),
            IconButton(
              icon: Icon(
                diary.favorite ? Icons.favorite : Icons.favorite_border,
                color: diary.favorite ? Colors.red : Colors.grey,
              ),
              onPressed: () async {
                await dbService.toggleDiaryFavorite(diary.id!, !diary.favorite);
                if (mounted) {
                  setState(() {});
                  Navigator.pop(context);
                  _showDiaryDetails(
                    diary.copyWith(favorite: !diary.favorite),
                    dbService,
                  );
                }
              },
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
                    backgroundColor: AppTheme.getMoodColor(diary.mood),
                    child: Text(
                      diary.moodEmoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          diary.formattedDate,
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        if (diary.location != null)
                          Text(
                            '地点: ${diary.location!}',
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
                const Text('标签:'),
                Wrap(
                  spacing: 4,
                  children: diary.tags.map((tag) {
                    return Chip(label: Text(tag));
                  }).toList(),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${diary.wordCount}字 · 阅读约${diary.readTime}分钟',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
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
  
  void _showDeleteDialog(DiaryEntry diary, DatabaseService dbService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除日记'),
        content: Text('确定要删除"${diary.title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              await dbService.deleteDiary(diary.id!);
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

// 简化版添加日记页面
class AddDiaryPage extends StatefulWidget {
  const AddDiaryPage({super.key});

  @override
  State<AddDiaryPage> createState() => _AddDiaryPageState();
}

class _AddDiaryPageState extends State<AddDiaryPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedMood = 'neutral';
  final List<String> _moods = ['happy', 'sad', 'neutral', 'excited', 'tired'];
  
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
  
  Future<void> _saveDiary() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入标题')),
      );
      return;
    }
    
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入内容')),
      );
      return;
    }
    
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    
    final diary = DiaryEntry(
      title: _titleController.text,
      content: _contentController.text,
      date: DateTime.now(),
      mood: _selectedMood,
      tags: [],
    );
    
    await dbService.insertDiary(diary);
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('日记已保存')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('写日记'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveDiary,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '标题',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('心情:'),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _moods.length,
                itemBuilder: (context, index) {
                  final mood = _moods[index];
                  final moodEmojis = {
                    'happy': '😊',
                    'sad': '😢',
                    'neutral': '😐',
                    'excited': '🤩',
                    'tired': '😴',
                  };
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(moodEmojis[mood] ?? '😐'),
                      selected: _selectedMood == mood,
                      onSelected: (selected) {
                        setState(() {
                          _selectedMood = mood;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: '内容',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 15,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}