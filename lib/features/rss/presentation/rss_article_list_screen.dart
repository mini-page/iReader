import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:ireader/core/services/rss_provider.dart';
import 'package:ireader/core/services/rss_service.dart';
import 'package:ireader/shared/widgets/skeleton_loaders.dart';
import 'package:ireader/shared/utils/text_utils.dart';
import 'package:ireader/features/settings/presentation/settings_controller.dart';
import 'package:ireader/shared/widgets/motion.dart';
import '../data/rss_feed_repository.dart';

enum RssArticleSort { newest, oldest, title, length }

class RssArticleListScreen extends ConsumerStatefulWidget {
  final RssFeed feed;

  const RssArticleListScreen({
    super.key,
    required this.feed,
  });

  @override
  ConsumerState<RssArticleListScreen> createState() => _RssArticleListScreenState();
}

class _RssArticleListScreenState extends ConsumerState<RssArticleListScreen> {
  RssArticleSort _sortType = RssArticleSort.newest;

  List<RssFeedItem> _getSortedItems(List<RssFeedItem> items) {
    final sorted = List<RssFeedItem>.from(items);
    switch (_sortType) {
      case RssArticleSort.newest:
        sorted.sort((a, b) => (b.pubDate ?? DateTime(0)).compareTo(a.pubDate ?? DateTime(0)));
        break;
      case RssArticleSort.oldest:
        sorted.sort((a, b) => (a.pubDate ?? DateTime(0)).compareTo(b.pubDate ?? DateTime(0)));
        break;
      case RssArticleSort.title:
        sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case RssArticleSort.length:
        sorted.sort((a, b) => (b.description?.length ?? 0).compareTo(a.description?.length ?? 0));
        break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final rssAsync = ref.watch(rssFeedProvider(widget.feed.url));
    final settings = ref.watch(settingsProvider);
    final isDark = settings.themeMode == ThemeMode.dark;
    final onSurface = isDark ? Colors.white : Colors.black;

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
          widget.feed.title.toUpperCase(),
          style: GoogleFonts.lexend(
            color: onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
           IconButton(
             icon: Icon(Icons.sort_rounded, color: onSurface.withValues(alpha: 0.6)),
             onPressed: () => _showSortMenu(context),
           ),
           const SizedBox(width: 8),
        ],
      ),
      body: rssAsync.when(
        data: (result) {
          if (!result.isSuccess) {
            return _buildErrorState(
              context,
              ref,
              onSurface,
              result.failure?.message ?? 'Network error or invalid feed.',
            );
          }

          final items = _getSortedItems(result.requireData);
          if (items.isEmpty) {
             return Center(child: Text('No articles found', style: TextStyle(color: onSurface.withValues(alpha: 0.4))));
          }
          
          return ListView.builder(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildRssItem(context, item, onSurface, isDark);
            },
          );
        },
        loading: () => Padding(
          padding: const EdgeInsets.all(20),
          child: SkeletonList(isDark: isDark),
        ),
        error: (e, _) => _buildErrorState(context, ref, onSurface, 'Network error or invalid feed.'),
      ),
    );
  }

  void _showSortMenu(BuildContext context) {
    final isDark = ref.read(settingsProvider).themeMode == ThemeMode.dark;
    final onSurface = isDark ? Colors.white : Colors.black;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'RssSortMenu',
      barrierColor: Colors.black.withValues(alpha: 0.2),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, __, child) {
        return OverlayMenu(
          alignment: Alignment.topRight,
          child: Stack(
            children: [
              Positioned(
                top: kToolbarHeight + MediaQuery.of(context).padding.top,
                right: 20,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 200,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 40, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSortTile('Newest First', RssArticleSort.newest, LucideIcons.calendar, onSurface),
                        _buildSortTile('Oldest First', RssArticleSort.oldest, LucideIcons.history, onSurface),
                        _buildSortTile('Title (A-Z)', RssArticleSort.title, LucideIcons.type, onSurface),
                        _buildSortTile('Article Length', RssArticleSort.length, LucideIcons.align_start_horizontal, onSurface),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortTile(String label, RssArticleSort type, IconData icon, Color onSurface) {
    final isSelected = _sortType == type;
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(icon, size: 18, color: isSelected ? const Color(0xFFFF3B3B) : onSurface.withValues(alpha: 0.4)),
      title: Text(label, style: TextStyle(color: isSelected ? const Color(0xFFFF3B3B) : onSurface, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _sortType = type);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Color onSurface, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.wifi_off,
              color: onSurface.withValues(alpha: 0.2), size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: onSurface.withValues(alpha: 0.4)),
            textAlign: TextAlign.center,
          ),
          TextButton(
            onPressed: () => ref.invalidate(rssFeedProvider(widget.feed.url)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildRssItem(BuildContext context, RssFeedItem item, Color onSurface, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: onSurface.withValues(alpha: 0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ScaleButton(
        onTap: () {
          HapticFeedback.lightImpact();
          if (item.link != null) {
            context.push('/rss/reader', extra: item);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    item.imageUrl!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              if (item.imageUrl != null) const SizedBox(height: 16),
              Text(
                item.title,
                style: TextStyle(
                  color: onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              if (item.description != null)
                Text(
                  stripHtml(item.description!),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.5),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(LucideIcons.clock, size: 12, color: onSurface.withValues(alpha: 0.3)),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(item.pubDate),
                    style: TextStyle(color: onSurface.withValues(alpha: 0.3), fontSize: 11),
                  ),
                  const Spacer(),
                  const Text(
                    'Read Article',
                    style: TextStyle(color: Color(0xFFFF3B3B), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';
    return "${date.day}/${date.month}/${date.year}";
  }
}
