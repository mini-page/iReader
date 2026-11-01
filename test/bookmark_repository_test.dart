import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ireader/features/bookmarks/data/bookmark_repository.dart';
import 'package:ireader/features/bookmarks/domain/bookmark.dart';

void main() {
  late Directory tempDir;
  late BookmarkRepository repo;

  setUp(() async {
    await Hive.close();
    tempDir = await Directory.systemTemp.createTemp('bookmark_test_');
    Hive.init(tempDir.path);
    repo = BookmarkRepository();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('add and retrieve bookmark', () async {
    await repo.add(Bookmark(
      id: 'b1',
      word: 'hello',
      index: 0,
      sessionId: 's1',
      sessionTitle: 'Test',
      createdAt: DateTime.now(),
    ));

    final all = await repo.getAll();
    expect(all.length, 1);
    expect(all.first.word, 'hello');
  });

  test('bySession filters correctly', () async {
    await repo.add(Bookmark(
      id: 'b1', word: 'hello', index: 0, sessionId: 's1',
      sessionTitle: 'S1', createdAt: DateTime.now(),
    ));
    await repo.add(Bookmark(
      id: 'b2', word: 'world', index: 1, sessionId: 's2',
      sessionTitle: 'S2', createdAt: DateTime.now(),
    ));
    await repo.add(Bookmark(
      id: 'b3', word: 'foo', index: 2, sessionId: 's1',
      sessionTitle: 'S1', createdAt: DateTime.now(),
    ));

    final s1Bookmarks = await repo.bySession('s1');
    expect(s1Bookmarks.length, 2);
    expect(s1Bookmarks.every((b) => b.sessionId == 's1'), isTrue);
  });

  test('delete removes bookmark', () async {
    await repo.add(Bookmark(
      id: 'b1', word: 'hello', index: 0, sessionId: 's1',
      sessionTitle: 'Test', createdAt: DateTime.now(),
    ));

    await repo.delete('b1');
    expect(await repo.getAll(), isEmpty);
  });

  test('clearAll removes all bookmarks', () async {
    await repo.add(Bookmark(
      id: 'b1', word: 'a', index: 0, sessionId: 's1',
      sessionTitle: 'T', createdAt: DateTime.now(),
    ));
    await repo.add(Bookmark(
      id: 'b2', word: 'b', index: 1, sessionId: 's1',
      sessionTitle: 'T', createdAt: DateTime.now(),
    ));

    await repo.clearAll();
    expect(await repo.getAll(), isEmpty);
  });
}
