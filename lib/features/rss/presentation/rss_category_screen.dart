import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../data/suggested_feeds.dart';
import '../data/rss_feed_repository.dart';
import '../providers/rss_providers.dart';

class RssCategoryScreen extends ConsumerWidget {
  final String category;

  const RssCategoryScreen({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feeds = suggestedFeeds.where((f) => f.category == category).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : Colors.black;
    final userFeeds = ref.watch(rssFeedsProvider).value ?? [];

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrow_left, color: onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          category.toUpperCase(),
          style: GoogleFonts.lexend(
            color: onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: feeds.length,
        itemBuilder: (context, index) {
          final feed = feeds[index];
          final isAdded = userFeeds.any((f) => f.url == feed.url);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              title: Text(feed.title, style: TextStyle(fontWeight: FontWeight.bold, color: onSurface)),
              subtitle: Text(feed.url, style: TextStyle(color: onSurface.withValues(alpha: 0.4), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: Icon(
                  isAdded ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                  color: isAdded ? Colors.green : const Color(0xFFFF3B3B),
                ),
                onPressed: isAdded ? null : () => _addFeed(ref, feed),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _addFeed(WidgetRef ref, SuggestedFeed suggested) async {
    final feed = RssFeed(
      id: const Uuid().v4(),
      title: suggested.title,
      url: suggested.url,
      addedAt: DateTime.now(),
    );
    await ref.read(rssFeedsProvider.notifier).addFeed(feed);
  }
}
