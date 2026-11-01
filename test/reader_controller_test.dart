import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ireader/core/models/service_result.dart';
import 'package:ireader/core/services/ai_service.dart';
import 'package:ireader/core/services/secure_storage_service.dart';
import 'package:ireader/features/bookmarks/data/bookmark_repository.dart';
import 'package:ireader/features/bookmarks/domain/bookmark.dart';
import 'package:ireader/features/reader/presentation/reader_controller.dart';
import 'package:ireader/features/settings/presentation/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoAiStorage extends SecureStorageService {
  @override
  Future<String?> getGeminiKey() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Hive.close();
    tempDir = await Directory.systemTemp.createTemp('ireader_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('loadText preserves provided session id and restores bookmarks', () async {
    final bookmarkRepo = BookmarkRepository();
    await bookmarkRepo.add(
      Bookmark(
        id: 'session-1_2',
        word: 'three',
        index: 2,
        sessionId: 'session-1',
        sessionTitle: 'Sample',
        createdAt: DateTime.now(),
      ),
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(readerProvider.notifier).loadText(
          'Sample',
          'one two three four',
          sessionId: 'session-1',
          start: 1,
        );

    final state = container.read(readerProvider);
    expect(state.sessionId, 'session-1');
    expect(state.index, 1);
    expect(state.bookmarks, contains(2));
  });

  test('transformWithResult clears persisted bookmarks and resets reading state',
      () async {
    final bookmarkRepo = BookmarkRepository();
    await bookmarkRepo.add(
      Bookmark(
        id: 'session-2_1',
        word: 'two',
        index: 1,
        sessionId: 'session-2',
        sessionTitle: 'Transform Me',
        createdAt: DateTime.now(),
      ),
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(readerProvider.notifier).loadText(
          'Transform Me',
          'one two three four',
          sessionId: 'session-2',
          start: 2,
        );

    final error = await container.read(readerProvider.notifier).transformWithResult(
          () async => ServiceResult.success('alpha beta'),
        );

    final state = container.read(readerProvider);
    final storedBookmarks = await bookmarkRepo.bySession('session-2');

    expect(error, isNull);
    expect(state.content, 'alpha beta');
    expect(state.index, 0);
    expect(state.bookmarks, isEmpty);
    expect(storedBookmarks, isEmpty);
  });

  test('AI service returns null provider when no Gemini key is stored', () async {
    final service = AIService(_NoAiStorage());
    expect(await service.getProvider(), isNull);
  });

  test('settings controller hydrates loaded state from shared preferences',
      () async {
    SharedPreferences.setMockInitialValues({
      'hasCompletedOnboarding': true,
      'defaultWpm': 420,
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(settingsProvider);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final settings = container.read(settingsProvider);
    expect(settings.isLoaded, isTrue);
    expect(settings.hasCompletedOnboarding, isTrue);
    expect(settings.defaultWpm, 420);
  });
}
