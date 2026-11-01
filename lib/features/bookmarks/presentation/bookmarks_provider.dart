import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ireader/core/providers/app_providers.dart';
import '../domain/bookmark.dart';

final bookmarksProvider = AsyncNotifierProvider<BookmarksNotifier, List<Bookmark>>(BookmarksNotifier.new);

class BookmarksNotifier extends AsyncNotifier<List<Bookmark>> {
  @override
  Future<List<Bookmark>> build() async {
    return ref.watch(bookmarkRepositoryProvider).getAll();
  }

  Future<void> addBookmark(Bookmark b) async {
    await ref.read(bookmarkRepositoryProvider).add(b);
    state = AsyncData(await ref.read(bookmarkRepositoryProvider).getAll());
  }

  Future<void> deleteBookmark(String id) async {
    await ref.read(bookmarkRepositoryProvider).delete(id);
    state = AsyncData(await ref.read(bookmarkRepositoryProvider).getAll());
  }

  Future<void> clearAll() async {
    await ref.read(bookmarkRepositoryProvider).clearAll();
    state = const AsyncData([]);
  }
}
