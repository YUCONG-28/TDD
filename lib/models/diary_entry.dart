import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class DiaryEntry {
  int? id;
  String title;
  String content;
  DateTime date;
  String mood;
  List<String> tags;
  List<String> images;
  DateTime createdAt;
  DateTime updatedAt;
  bool favorite;
  String? location;
  String? weather;

  DiaryEntry({
    this.id,
    required this.title,
    required this.content,
    required this.date,
    this.mood = 'neutral',
    this.tags = const [],
    this.images = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.favorite = false,
    this.location,
    this.weather,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'mood': mood,
      'tags': tags.join(','),
      'images': images.join(','),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'favorite': favorite ? 1 : 0,
      'location': location,
      'weather': weather,
    };
  }

  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'],
      title: map['title'],
      content: map['content'] ?? '',
      date: DateTime.parse(map['date']),
      mood: map['mood'] ?? 'neutral',
      tags: (map['tags'] ?? '').split(',').where((tag) => tag.isNotEmpty).toList(),
      images: (map['images'] ?? '').split(',').where((image) => image.isNotEmpty).toList(),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      favorite: map['favorite'] == 1,
      location: map['location'],
      weather: map['weather'],
    );
  }

  DiaryEntry copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? date,
    String? mood,
    List<String>? tags,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? favorite,
    String? location,
    String? weather,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      favorite: favorite ?? this.favorite,
      location: location ?? this.location,
      weather: weather ?? this.weather,
    );
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return '今天 ${DateFormat('HH:mm').format(date)}';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      return '昨天 ${DateFormat('HH:mm').format(date)}';
    } else if (date.year == now.year) {
      return DateFormat('MM/dd HH:mm').format(date);
    } else {
      return DateFormat('yyyy/MM/dd HH:mm').format(date);
    }
  }

  String get shortDate {
    return DateFormat('yyyy/MM/dd').format(date);
  }

  String get time {
    return DateFormat('HH:mm').format(date);
  }

  bool get hasImages => images.isNotEmpty;

  int get wordCount {
    // 简单的中英文单词计数
    final englishWords = content.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
    final chineseCharacters = content.replaceAll(RegExp(r'[\s\p{P}]', unicode: true), '').length;
    return englishWords + chineseCharacters;
  }

  int get readTime {
    // 预估阅读时间（按每分钟300字计算）
    return (wordCount / 300).ceil();
  }

  String get moodEmoji {
    const moodEmojis = {
      'happy': '😊',
      'sad': '😢',
      'angry': '😠',
      'excited': '🤩',
      'tired': '😴',
      'neutral': '😐',
      'love': '❤️',
      'surprised': '😲',
      'confused': '😕',
      'proud': '🦚',
    };
    return moodEmojis[mood] ?? '😐';
  }

  @override
  String toString() {
    return 'DiaryEntry(id: $id, title: $title, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiaryEntry &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.date == date &&
        other.mood == mood &&
        listEquals(other.tags, tags) &&
        listEquals(other.images, images);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      content,
      date,
      mood,
      Object.hashAll(tags),
      Object.hashAll(images),
    );
  }
}