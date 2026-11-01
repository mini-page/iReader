import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ireader/core/services/ai_service.dart';
import 'package:ireader/core/services/article_service.dart';
import 'package:ireader/core/services/dictionary_service.dart';
import 'package:ireader/core/services/rss_service.dart';
import 'package:ireader/core/services/secure_storage_service.dart';
import 'package:ireader/core/services/translation_service.dart';
import 'package:ireader/core/services/audio_handler.dart';
import 'package:ireader/core/services/wikipedia_service.dart';
import 'package:ireader/features/library/data/session_repository.dart';
import 'package:ireader/features/library/data/book_repository.dart';
import 'package:ireader/features/bookmarks/data/bookmark_repository.dart';
import 'package:ireader/features/stats/data/stats_repository.dart';

final audioHandlerProvider = Provider<ReaderAudioHandler>((ref) => throw UnimplementedError());

final sessionRepositoryProvider =
    Provider<SessionRepository>((ref) => SessionRepository());

final bookRepositoryProvider =
    Provider<BookRepository>((ref) => BookRepository());

final bookmarkRepositoryProvider =
    Provider<BookmarkRepository>((ref) => BookmarkRepository());

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository();
});

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final aiServiceProvider = Provider<AIService>((ref) {
  return AIService(ref.read(secureStorageProvider));
});
final articleServiceProvider = Provider<ArticleService>((ref) {
  return ArticleService();
});
final dictionaryServiceProvider = Provider<DictionaryService>((ref) {
  return DictionaryService();
});
final translationServiceProvider = Provider<TranslationService>((ref) {
  return TranslationService();
});
final wikipediaServiceProvider = Provider<WikipediaService>((ref) {
  return WikipediaService();
});
final rssServiceProvider = Provider<RssService>((ref) => RssService());

final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(player.dispose);
  return player;
});
