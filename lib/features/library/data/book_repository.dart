import 'package:hive_flutter/hive_flutter.dart';
import 'package:ireader/shared/models/book.dart';

class BookRepository {
  static const boxName = 'books';

  Future<Box> _box() async =>
      Hive.isBoxOpen(boxName) ? Hive.box(boxName) : await Hive.openBox(boxName);

  Future<List<Book>> all() async {
    final box = await _box();
    return box.values
        .map((e) => Book.fromJson(Map<dynamic, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> create(Book book) async {
    final box = await _box();
    await box.put(book.id, book.toJson());
  }

  Future<void> update(Book book) async {
    final box = await _box();
    await box.put(book.id, book.toJson());
  }

  Future<void> delete(String id) async {
    final box = await _box();
    await box.delete(id);
  }

  Future<void> clearAll() async {
    final box = await _box();
    await box.clear();
  }
}
