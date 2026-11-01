import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/rss_feed_repository.dart';

final rssFeedRepositoryProvider = Provider((ref) => RssFeedRepository());

final rssFeedsProvider = AsyncNotifierProvider<RssFeedsNotifier, List<RssFeed>>(RssFeedsNotifier.new);

class RssFeedsNotifier extends AsyncNotifier<List<RssFeed>> {
  @override
  Future<List<RssFeed>> build() async {
    return ref.watch(rssFeedRepositoryProvider).getAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(rssFeedRepositoryProvider).getAll());
  }

  Future<void> addFeed(RssFeed feed) async {
    var finalFeed = feed;
    if (finalFeed.title == 'RSS Feed' || finalFeed.title == 'New Feed') {
      final title = RssFeed.extractSource(feed.url);
      finalFeed = feed.copyWith(title: title);
    }
    await ref.read(rssFeedRepositoryProvider).add(finalFeed);
    await refresh();
  }

  Future<void> deleteFeed(String id) async {
    await ref.read(rssFeedRepositoryProvider).delete(id);
    await refresh();
  }
}
