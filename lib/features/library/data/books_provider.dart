import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ireader/core/providers/app_providers.dart';
import 'package:ireader/shared/models/book.dart';

final booksProvider = AsyncNotifierProvider<BooksNotifier, List<Book>>(BooksNotifier.new);

class BooksNotifier extends AsyncNotifier<List<Book>> {
  @override
  Future<List<Book>> build() async {
    return ref.watch(bookRepositoryProvider).all();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(bookRepositoryProvider).all());
  }

  Future<void> deleteBook(String id) async {
    await ref.read(bookRepositoryProvider).delete(id);
    await refresh();
  }
}
