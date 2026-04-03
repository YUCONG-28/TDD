import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum Priority { high, medium, low }

extension PriorityExtension on Priority {
  String get displayName {
    switch (this) {
      case Priority.high:
        return '高优先级';
      case Priority.medium:
        return '中优先级';
      case Priority.low:
        return '低优先级';
    }
  }

  Color get color {
    switch (this) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
  }
}

class TodoItem {
  int? id;
  String title;
  String description;
  DateTime? dueDate;
  bool completed;
  Priority priority;
  List<String> tags;
  DateTime createdAt;
  DateTime updatedAt;
  bool hasReminder;
  DateTime? reminderTime;
  String? category;

  TodoItem({
    this.id,
    required this.title,
    this.description = '',
    this.dueDate,
    this.completed = false,
    this.priority = Priority.medium,
    this.tags = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.hasReminder = false,
    this.reminderTime,
    this.category,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'completed': completed ? 1 : 0,
      'priority': priority.index,
      'tags': tags.join(','),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'hasReminder': hasReminder ? 1 : 0,
      'reminderTime': reminderTime?.toIso8601String(),
      'category': category,
    };
  }

  factory TodoItem.fromMap(Map<String, dynamic> map) {
    return TodoItem(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'])
          : null,
      completed: map['completed'] == 1,
      priority: Priority.values[map['priority'] ?? 1],
      tags: (map['tags'] ?? '').split(',').where((tag) => tag.isNotEmpty).toList(),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      hasReminder: map['hasReminder'] == 1,
      reminderTime: map['reminderTime'] != null
          ? DateTime.parse(map['reminderTime'])
          : null,
      category: map['category'],
    );
  }

  TodoItem copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? completed,
    Priority? priority,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? hasReminder,
    DateTime? reminderTime,
    String? category,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      completed: completed ?? this.completed,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderTime: reminderTime ?? this.reminderTime,
      category: category ?? this.category,
    );
  }

  String get formattedDueDate {
    if (dueDate == null) return '无截止日期';
    final now = DateTime.now();
    final difference = dueDate!.difference(now);
    
    if (difference.inDays == 0) {
      return '今天 ${DateFormat('HH:mm').format(dueDate!)}';
    } else if (difference.inDays == 1) {
      return '明天 ${DateFormat('HH:mm').format(dueDate!)}';
    } else if (difference.inDays == -1) {
      return '昨天 ${DateFormat('HH:mm').format(dueDate!)}';
    } else if (difference.inDays < 0) {
      return '已过期 ${DateFormat('MM/dd HH:mm').format(dueDate!)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天后 ${DateFormat('HH:mm').format(dueDate!)}';
    } else {
      return DateFormat('yyyy/MM/dd HH:mm').format(dueDate!);
    }
  }

  bool get isOverdue {
    if (dueDate == null) return false;
    return !completed && dueDate!.isBefore(DateTime.now());
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  @override
  String toString() {
    return 'TodoItem(id: $id, title: $title, completed: $completed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TodoItem &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.dueDate == dueDate &&
        other.completed == completed &&
        other.priority == priority &&
        listEquals(other.tags, tags);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      dueDate,
      completed,
      priority,
      Object.hashAll(tags),
    );
  }
}