import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ireader/features/library/data/session_repository.dart';

void main() {
  late Directory tempDir;
  late SessionRepository repo;

  setUp(() async {
    await Hive.close();
    tempDir = await Directory.systemTemp.createTemp('session_test_');
    Hive.init(tempDir.path);
    repo = SessionRepository();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('create and retrieve session', () async {
    final session = await repo.create(
      title: 'Test Session',
      content: 'hello world',
      wpm: 300,
    );

    expect(session.id, isNotEmpty);
    expect(session.title, 'Test Session');
    expect(session.content, 'hello world');

    final all = await repo.all();
    expect(all.length, 1);
    expect(all.first.id, session.id);
  });

  test('update session position', () async {
    final session = await repo.create(
      title: 'Test',
      content: 'one two three',
      wpm: 250,
    );

    await repo.update(session.id, position: 2);

    final updated = (await repo.all()).first;
    expect(updated.position, 2);
  });

  test('delete session', () async {
    final s1 = await repo.create(title: 'A', content: 'a', wpm: 200);
    final s2 = await repo.create(title: 'B', content: 'b', wpm: 200);

    await repo.delete(s1.id);

    final all = await repo.all();
    expect(all.length, 1);
    expect(all.first.id, s2.id);
  });

  test('latest returns most recent session', () async {
    await repo.create(title: 'First', content: 'a', wpm: 200);
    await Future.delayed(const Duration(milliseconds: 10));
    final s2 = await repo.create(title: 'Second', content: 'b', wpm: 200);

    final latest = await repo.latest();
    expect(latest?.id, s2.id);
    expect(latest?.title, 'Second');
  });

  test('clearAll removes all sessions', () async {
    await repo.create(title: 'A', content: 'a', wpm: 200);
    await repo.create(title: 'B', content: 'b', wpm: 200);

    await repo.clearAll();

    expect(await repo.all(), isEmpty);
  });
}
