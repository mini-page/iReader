import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import '../bookmarks_provider.dart';
import '../../domain/bookmark.dart';

class BookmarksSection extends ConsumerStatefulWidget {
  const BookmarksSection({super.key});

  @override
  ConsumerState<BookmarksSection> createState() => _BookmarksSectionState();
}

class _BookmarksSectionState extends ConsumerState<BookmarksSection> {
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookmarksAsync = ref.watch(bookmarksProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BOOKMARKS',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.5,
                color: onSurface.withValues(alpha: 0.3),
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(
                _isSearchOpen ? LucideIcons.x : LucideIcons.search,
                size: 16,
                color: onSurface.withValues(alpha: 0.4),
              ),
              onPressed: () {
                setState(() {
                  _isSearchOpen = !_isSearchOpen;
                  if (!_isSearchOpen) {
                    _query = '';
                    _searchController.clear();
                  }
                });
              },
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _isSearchOpen
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    style: TextStyle(color: onSurface, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search bookmarked words...',
                      hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.2)),
                      prefixIcon: const Icon(LucideIcons.search, size: 14),
                      filled: true,
                      fillColor: onSurface.withValues(alpha: 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                )
              : const SizedBox(),
        ),
        bookmarksAsync.when(
          data: (bookmarks) {
            final filtered = bookmarks
                .where((b) => b.word.toLowerCase().contains(_query.toLowerCase()))
                .toList();

            if (filtered.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    _query.isEmpty ? 'No bookmarks yet.' : 'No matches found.',
                    style: TextStyle(color: onSurface.withValues(alpha: 0.2), fontSize: 13),
                  ),
                ),
              );
            }

            // Group by sessionId
            final Map<String, List<Bookmark>> grouped = {};
            for (var b in filtered) {
              grouped.putIfAbsent(b.sessionId, () => []).add(b);
            }

            return Column(
              children: grouped.entries.map((entry) {
                final sessionId = entry.key;
                final sessionBookmarks = entry.value;
                final title = sessionBookmarks.first.sessionTitle;

                return _buildSessionGroup(context, title, sessionId, sessionBookmarks, onSurface, isDark);
              }).toList(),
            );
          },
          loading: () => const Center(child: LinearProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  Widget _buildSessionGroup(
    BuildContext context,
    String title,
    String sessionId,
    List<Bookmark> bookmarks,
    Color onSurface,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: onSurface.withValues(alpha: 0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/bookmarks/$sessionId'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${bookmarks.length} word${bookmarks.length > 1 ? 's' : ''}',
                          style: TextStyle(color: onSurface.withValues(alpha: 0.4), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.chevron_right, size: 18, color: Color(0xFFFF3B3B)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 72, // Space for 2 rows of chips (approx 32 each) + spacing
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Wrap(
                    direction: Axis.vertical,
                    spacing: 8,
                    runSpacing: 8,
                    children: bookmarks.map((b) => _buildBookmarkChip(context, b, onSurface)).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookmarkChip(BuildContext context, Bookmark b, Color onSurface) {
    return GestureDetector(
      onTap: () => context.push('/bookmarks/${b.sessionId}', extra: b),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          b.word,
          style: TextStyle(color: onSurface.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
