import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/main/presentation/main_scaffold.dart';
import 'features/reader/presentation/reader_screen.dart';
import 'features/settings/presentation/settings_controller.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/settings/presentation/love_gallery_screen.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';

import 'features/home/presentation/preview_screen.dart';
import 'features/bookmarks/presentation/bookmark_session_screen.dart';
import 'features/rss/presentation/rss_feed_manager_screen.dart';
import 'features/rss/presentation/rss_article_list_screen.dart';
import 'features/rss/presentation/rss_article_reader_screen.dart';
import 'features/rss/presentation/rss_category_screen.dart';
import 'features/rss/data/rss_feed_repository.dart';
import 'features/library/presentation/book_reader_screen.dart';
import 'features/settings/presentation/support_screen.dart';
import 'shared/models/book.dart';
import 'core/services/rss_service.dart';

final _routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
          path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/', builder: (context, state) => const MainScaffold()),
      GoRoute(
        path: '/preview',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>?;
          return PreviewScreen(
            initialTitle: extras?['title'] ?? '',
            initialContent: extras?['content'] ?? '',
          );
        },
      ),
      GoRoute(
          path: '/reader', builder: (context, state) => const ReaderScreen()),
      GoRoute(
          path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(
          path: '/support', builder: (context, state) => const SupportScreen()),
      GoRoute(
          path: '/love-gallery', builder: (context, state) => const LoveGalleryScreen()),
      GoRoute(
        path: '/bookmarks/:sessionId',
        builder: (context, state) => BookmarkSessionScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
      GoRoute(
        path: '/rss',
        builder: (context, state) => const RssFeedManagerScreen(),
        routes: [
          GoRoute(
            path: 'feed',
            builder: (context, state) => RssArticleListScreen(feed: state.extra as RssFeed),
          ),
          GoRoute(
            path: 'reader',
            builder: (context, state) => RssArticleReaderScreen(item: state.extra as RssFeedItem),
          ),
          GoRoute(
            path: 'category',
            builder: (context, state) => RssCategoryScreen(category: state.extra as String),
          ),
        ],
      ),
      GoRoute(
        path: '/books',
        redirect: (context, state) => '/books/reader',
        routes: [
          GoRoute(
            path: 'reader',
            builder: (context, state) => BookReaderScreen(book: state.extra as Book),
          ),
        ],
      ),
    ],
  );
});

class IReaderApp extends ConsumerWidget {
  const IReaderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(_routerProvider);

    return MaterialApp.router(
      title: 'iReader: READ FAST, THINK DEEP',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
    );
  }
}
