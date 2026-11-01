import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ireader/core/providers/app_providers.dart';
import 'package:ireader/core/models/service_result.dart';
import '../services/rss_service.dart';

final rssFeedProvider =
    FutureProvider.family<ServiceResult<List<RssFeedItem>>, String>(
  (ref, url) async {
  final service = ref.read(rssServiceProvider);
  return service.fetchFeed(url);
});
