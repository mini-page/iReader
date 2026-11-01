import 'package:hive_flutter/hive_flutter.dart';

class RssFeed {
  final String id;
  final String title;
  final String url;
  final String? description;
  final String? imageUrl;
  final DateTime addedAt;

  RssFeed({
    required this.id,
    required this.title,
    required this.url,
    this.description,
    this.imageUrl,
    required this.addedAt,
  });

  RssFeed copyWith({
    String? id,
    String? title,
    String? url,
    String? description,
    String? imageUrl,
    DateTime? addedAt,
  }) => RssFeed(
    id: id ?? this.id,
    title: title ?? this.title,
    url: url ?? this.url,
    description: description ?? this.description,
    imageUrl: imageUrl ?? this.imageUrl,
    addedAt: addedAt ?? this.addedAt,
  );

  static String extractSource(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.replaceAll('www.', '');
      final part = host.split('.').first;
      if (part.isEmpty) return 'RSS Feed';
      return part[0].toUpperCase() + part.substring(1);
    } catch (_) {
      return 'RSS Feed';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'url': url,
    'description': description,
    'imageUrl': imageUrl,
    'addedAt': addedAt.toIso8601String(),
  };

  factory RssFeed.fromJson(Map<dynamic, dynamic> json) => RssFeed(
    id: json['id'] as String,
    title: json['title'] as String,
    url: json['url'] as String,
    description: json['description'] as String?,
    imageUrl: json['imageUrl'] as String?,
    addedAt: DateTime.parse(json['addedAt'] as String),
  );
}

class RssFeedRepository {
  static const boxName = 'rss_feeds';

  Future<Box> _box() async =>
      Hive.isBoxOpen(boxName) ? Hive.box(boxName) : await Hive.openBox(boxName);

  Future<List<RssFeed>> getAll() async {
    final box = await _box();
    return box.values
        .map((e) => RssFeed.fromJson(Map<dynamic, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  }

  Future<void> add(RssFeed feed) async {
    final box = await _box();
    await box.put(feed.id, feed.toJson());
  }

  Future<void> delete(String id) async {
    final box = await _box();
    await box.delete(id);
  }
}
