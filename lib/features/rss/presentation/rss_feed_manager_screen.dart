import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../providers/rss_providers.dart';
import '../data/rss_feed_repository.dart';
import 'package:ireader/core/providers/app_providers.dart';

class RssFeedManagerScreen extends ConsumerStatefulWidget {
  const RssFeedManagerScreen({super.key});

  @override
  ConsumerState<RssFeedManagerScreen> createState() => _RssFeedManagerScreenState();
}

class _RssFeedManagerScreenState extends ConsumerState<RssFeedManagerScreen> {
  final _urlController = TextEditingController();
  bool _isValidating = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _addFeed() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isValidating = true);
    try {
      final rssService = ref.read(rssServiceProvider);
      final result = await rssService.fetchFeed(url);
      
      if (result.isSuccess) {
        // We need the feed title, let's assume the service could provide it or we just use the URL for now
        // Actually, the current RssService.fetchFeed returns List<RssFeedItem>.
        // Let's improve RssService to return feed metadata too if possible, or just use a default.
        final feed = RssFeed(
          id: const Uuid().v4(),
          title: RssFeed.extractSource(url),
          url: url,
          addedAt: DateTime.now(),
        );
        await ref.read(rssFeedsProvider.notifier).addFeed(feed);
        _urlController.clear();
        if (mounted) Navigator.pop(context);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.failure?.message ?? 'Invalid RSS Feed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding feed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Add RSS Feed'),
            content: TextField(
              controller: _urlController,
              decoration: const InputDecoration(hintText: 'https://example.com/rss'),
              autofocus: true,
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: _isValidating ? null : _addFeed,
                child: _isValidating 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Text('Add'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedsAsync = ref.watch(rssFeedsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('RSS FEEDS', style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 18, color: onSurface)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(LucideIcons.arrow_left, color: onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: feedsAsync.when(
        data: (feeds) => feeds.isEmpty 
            ? _buildEmptyState(onSurface) 
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: feeds.length,
                itemBuilder: (context, index) {
                  final feed = feeds[index];
                  return _buildFeedCard(feed, onSurface, isDark);
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFFFF3B3B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(Color onSurface) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.rss, size: 64, color: onSurface.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          Text('No feeds yet', style: TextStyle(color: onSurface.withValues(alpha: 0.4), fontSize: 16)),
          const SizedBox(height: 8),
          Text('Add your first RSS feed to start reading', style: TextStyle(color: onSurface.withValues(alpha: 0.2), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildFeedCard(RssFeed feed, Color onSurface, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () => context.push('/rss/feed', extra: feed),
        title: Text(feed.title, style: TextStyle(fontWeight: FontWeight.bold, color: onSurface)),
        subtitle: Text(feed.url, style: TextStyle(color: onSurface.withValues(alpha: 0.4), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          icon: Icon(LucideIcons.trash_2, color: const Color(0xFFFF3B3B).withValues(alpha: 0.5), size: 20),
          onPressed: () => ref.read(rssFeedsProvider.notifier).deleteFeed(feed.id),
        ),
      ),
    );
  }
}
