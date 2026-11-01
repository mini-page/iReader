import 'dart:typed_data';

class Book {
  final String id;
  final String title;
  final String author;
  final Uint8List? cover;
  final List<BookChapter> chapters;
  final int currentChapterIndex;
  final int currentPosition;
  final DateTime updatedAt;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.cover,
    required this.chapters,
    this.currentChapterIndex = 0,
    this.currentPosition = 0,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'author': author,
    'cover': cover,
    'chapters': chapters.map((c) => c.toJson()).toList(),
    'currentChapterIndex': currentChapterIndex,
    'currentPosition': currentPosition,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Book.fromJson(Map<dynamic, dynamic> json) => Book(
    id: json['id'] as String,
    title: json['title'] as String,
    author: json['author'] as String,
    cover: json['cover'] as Uint8List?,
    chapters: (json['chapters'] as List).map((c) => BookChapter.fromJson(c as Map)).toList(),
    currentChapterIndex: json['currentChapterIndex'] as int,
    currentPosition: json['currentPosition'] as int,
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  Book copyWith({
    String? id,
    String? title,
    String? author,
    Uint8List? cover,
    List<BookChapter>? chapters,
    int? currentChapterIndex,
    int? currentPosition,
    DateTime? updatedAt,
  }) => Book(
    id: id ?? this.id,
    title: title ?? this.title,
    author: author ?? this.author,
    cover: cover ?? this.cover,
    chapters: chapters ?? this.chapters,
    currentChapterIndex: currentChapterIndex ?? this.currentChapterIndex,
    currentPosition: currentPosition ?? this.currentPosition,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class BookChapter {
  final String title;
  final String content;

  const BookChapter({
    required this.title,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
  };

  factory BookChapter.fromJson(Map<dynamic, dynamic> json) => BookChapter(
    title: json['title'] as String,
    content: json['content'] as String,
  );
}
