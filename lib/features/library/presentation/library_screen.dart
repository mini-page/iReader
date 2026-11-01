import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:uuid/uuid.dart';

import 'package:ireader/features/reader/presentation/reader_controller.dart';
import 'package:ireader/features/settings/presentation/settings_controller.dart';
import 'package:ireader/shared/models/session.dart';
import 'package:ireader/shared/widgets/expandable_fab.dart';
import 'package:ireader/shared/widgets/reading_action_mixin.dart';
import 'package:ireader/features/home/presentation/widgets/home_widgets.dart';
import 'package:ireader/features/home/data/sessions_provider.dart';
import 'package:ireader/features/rss/providers/rss_providers.dart';
import 'package:ireader/features/rss/data/rss_feed_repository.dart';
import 'package:ireader/features/rss/data/suggested_feeds.dart';
import 'package:ireader/shared/widgets/motion.dart';
import 'library_mode_provider.dart';
import 'package:ireader/features/library/data/books_provider.dart';
import 'package:ireader/shared/models/book.dart';

enum LibrarySortType { size, progress, title, date }

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> with ReadingActionMixin {
  String _searchQuery = '';
  LibrarySortType _sortType = LibrarySortType.date;
  bool _isAscending = false;

  List<Session> _getFilteredSessions(List<Session> sessions) {
    List<Session> filtered = sessions.where((s) {
      final query = _searchQuery.toLowerCase();
      return s.title.toLowerCase().contains(query) ||
          s.content.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      int cmp;
      switch (_sortType) {
        case LibrarySortType.size:
          cmp = a.content.length.compareTo(b.content.length);
          break;
        case LibrarySortType.progress:
          final totalA = a.content.split(RegExp(r'\s+')).length;
          final totalB = b.content.split(RegExp(r'\s+')).length;
          final progressA = a.position / (totalA > 0 ? totalA : 1);
          final progressB = b.position / (totalB > 0 ? totalB : 1);
          cmp = progressA.compareTo(progressB);
          break;
        case LibrarySortType.title:
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case LibrarySortType.date:
          cmp = a.updatedAt.compareTo(b.updatedAt);
          break;
      }
      return _isAscending ? cmp : -cmp;
    });

    return filtered;
  }

  List<RssFeed> _getFilteredFeeds(List<RssFeed> feeds) {
    List<RssFeed> filtered = feeds.where((f) {
      final query = _searchQuery.toLowerCase();
      return f.title.toLowerCase().contains(query) ||
          f.url.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      int cmp;
      switch (_sortType) {
        case LibrarySortType.title:
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case LibrarySortType.date:
          cmp = a.addedAt.compareTo(b.addedAt);
          break;
        default:
          cmp = a.addedAt.compareTo(b.addedAt);
      }
      return _isAscending ? cmp : -cmp;
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(libraryModeProvider);
    final settings = ref.watch(settingsProvider);
    final isDark = settings.themeMode == ThemeMode.dark;
    final onSurface = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDark
          ? (settings.showOledBlack ? Colors.black : const Color(0xFF121212))
          : const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: Text(
          _getTitle(mode),
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 20, color: onSurface),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildModeToggle(onSurface, isDark),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _buildSearchAndSort(onSurface, isDark, mode),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0.1, 0),
                      end: Offset.zero,
                    ).animate(animation);
                    return SlideTransition(
                      position: slide,
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(mode),
                    child: Column(
                      children: [
                        if (mode == LibraryMode.feeds) ...[
                          const SizedBox(height: 16),
                          _buildSuggestedFeeds(onSurface, isDark),
                        ],
                        Expanded(
                          child: _buildMainContent(mode, onSurface, isDark),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (isProcessing) ProcessingOverlay(label: processingLabel),
        ],
      ),
      floatingActionButton: AnimatedSlide(
        offset: mode == LibraryMode.library ? Offset.zero : const Offset(0, 1.5),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: mode == LibraryMode.library ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 150),
          child: _buildLibraryFab(),
        ),
      ),
    );
  }

  String _getTitle(LibraryMode mode) {
    switch (mode) {
      case LibraryMode.library: return 'Your Library';
      case LibraryMode.feeds: return 'Your Feeds';
      case LibraryMode.books: return 'Your Books';
    }
  }

  Widget _buildMainContent(LibraryMode mode, Color onSurface, bool isDark) {
    switch (mode) {
      case LibraryMode.library: return _buildLibraryView(onSurface, isDark);
      case LibraryMode.feeds: return _buildFeedsView(onSurface, isDark);
      case LibraryMode.books: return _buildBooksView(onSurface, isDark);
    }
  }

  Widget _buildModeToggle(Color onSurface, bool isDark) {
    final mode = ref.watch(libraryModeProvider);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildToggleItem(
            icon: Icons.library_books_rounded,
            isSelected: mode == LibraryMode.library,
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(libraryModeProvider.notifier).state = LibraryMode.library;
            },
            onSurface: onSurface,
          ),
          _buildToggleItem(
            icon: LucideIcons.rss,
            isSelected: mode == LibraryMode.feeds,
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(libraryModeProvider.notifier).state = LibraryMode.feeds;
            },
            onSurface: onSurface,
          ),
          _buildToggleItem(
            icon: LucideIcons.book,
            isSelected: mode == LibraryMode.books,
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(libraryModeProvider.notifier).state = LibraryMode.books;
            },
            onSurface: onSurface,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color onSurface,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF3B3B) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : onSurface.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildSuggestedFeeds(Color onSurface, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('EXPLORE TOPICS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: onSurface.withValues(alpha: 0.3))),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            clipBehavior: Clip.none,
            children: [
              _buildCategoryCircle(
                label: 'Add Feed',
                icon: Icons.add_rounded,
                onTap: () => context.push('/rss'),
                onSurface: onSurface,
                isDark: isDark,
                isPrimary: true,
              ),
              ...feedCategories.map((cat) => _buildCategoryCircle(
                label: cat,
                icon: _getCategoryIcon(cat),
                onTap: () => _showCategoryFeeds(cat),
                onSurface: onSurface,
                isDark: isDark,
              )),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Tech': return LucideIcons.cpu;
      case 'News': return LucideIcons.newspaper;
      case 'Business': return LucideIcons.briefcase;
      case 'Science': return LucideIcons.beaker;
      case 'Health': return LucideIcons.heart_pulse;
      case 'Design': return LucideIcons.palette;
      case 'AI': return LucideIcons.brain_circuit;
      case 'Startups': return LucideIcons.rocket;
      default: return LucideIcons.rss;
    }
  }

  Widget _buildCategoryCircle({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required Color onSurface,
    required bool isDark,
    bool isPrimary = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isPrimary ? const LinearGradient(
                  colors: [Color(0xFFFF3B3B), Color(0xFFFF8A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ) : null,
                color: isPrimary ? null : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
                border: isPrimary ? null : Border.all(color: onSurface.withValues(alpha: 0.05), width: 1),
                boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 26,
                  color: isPrimary ? Colors.white : onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryFeeds(String category) {
    context.push('/rss/category', extra: category);
  }

  Widget _buildLibraryView(Color onSurface, bool isDark) {
    final sessionsAsync = ref.watch(sessionsProvider);
    return sessionsAsync.when(
      data: (sessions) {
        final filtered = _getFilteredSessions(sessions);
        if (filtered.isEmpty) return _buildEmptyState(onSurface, 'Library is empty');
        return ListView.builder(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 100),
          itemCount: filtered.length,
          itemBuilder: (context, index) => _buildSessionCard(filtered[index], onSurface, isDark),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildFeedsView(Color onSurface, bool isDark) {
    final feedsAsync = ref.watch(rssFeedsProvider);
    return feedsAsync.when(
      data: (feeds) {
        final query = _searchQuery.trim().toLowerCase();
        if (query.isEmpty) {
          final filtered = _getFilteredFeeds(feeds);
          if (filtered.isEmpty) return _buildEmptyState(onSurface, 'No feeds followed');
          return ListView.builder(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 100),
            itemCount: filtered.length,
            itemBuilder: (context, index) => _buildFeedCard(filtered[index], onSurface, isDark),
          );
        }

        // Search mode: show grouped results
        final userMatches = feeds.where((f) => f.title.toLowerCase().contains(query) || f.url.toLowerCase().contains(query)).toList();
        final suggestedMatches = suggestedFeeds.where((f) => f.title.toLowerCase().contains(query) || f.url.toLowerCase().contains(query)).toList();
        final categoryMatches = feedCategories.where((c) => c.toLowerCase().contains(query)).toList();

        if (userMatches.isEmpty && suggestedMatches.isEmpty && categoryMatches.isEmpty) {
          return _buildEmptyState(onSurface, 'No results found for "$_searchQuery"');
        }

        return ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 100),
          children: [
            if (userMatches.isNotEmpty) ...[
              _buildSearchHeader('YOUR FEEDS', onSurface),
              ...userMatches.map((f) => _buildFeedCard(f, onSurface, isDark)),
              const SizedBox(height: 24),
            ],
            if (suggestedMatches.isNotEmpty) ...[
              _buildSearchHeader('SUGGESTED FEEDS', onSurface),
              ...suggestedMatches.map((f) => _buildSuggestedMatchCard(f, onSurface, isDark)),
              const SizedBox(height: 24),
            ],
            if (categoryMatches.isNotEmpty) ...[
              _buildSearchHeader('CATEGORIES', onSurface),
              ...categoryMatches.map((c) => _buildCategoryMatchCard(c, onSurface, isDark)),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildBooksView(Color onSurface, bool isDark) {
    final booksAsync = ref.watch(booksProvider);
    return booksAsync.when(
      data: (books) {
        final query = _searchQuery.trim().toLowerCase();
        final filtered = books.where((b) => b.title.toLowerCase().contains(query) || b.author.toLowerCase().contains(query)).toList();
        
        if (filtered.isEmpty) return _buildEmptyState(onSurface, 'No books found');
        
        return GridView.builder(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) => _buildBookCard(filtered[index], onSurface, isDark),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildBookCard(Book book, Color onSurface, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    return ScaleButton(
      onTap: () => context.push('/books/reader', extra: book),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: onSurface.withValues(alpha: 0.05),
                ),
                child: book.cover != null 
                    ? Image.memory(book.cover!, fit: BoxFit.cover)
                    : Center(child: Icon(LucideIcons.book, size: 48, color: onSurface.withValues(alpha: 0.1))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title, style: TextStyle(fontWeight: FontWeight.bold, color: onSurface, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(book.author, style: TextStyle(color: onSurface.withValues(alpha: 0.4), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(String title, Color onSurface) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: onSurface.withValues(alpha: 0.3))),
    );
  }

  Widget _buildSuggestedMatchCard(SuggestedFeed suggested, Color onSurface, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final isAdded = (ref.read(rssFeedsProvider).value ?? []).any((f) => f.url == suggested.url);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        onTap: () => context.push('/rss/feed', extra: RssFeed(id: const Uuid().v4(), title: suggested.title, url: suggested.url, addedAt: DateTime.now())),
        title: Text(suggested.title, style: TextStyle(fontWeight: FontWeight.bold, color: onSurface, fontSize: 14)),
        subtitle: Text(suggested.url, style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.4)), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          icon: Icon(
            isAdded ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
            color: isAdded ? Colors.green : const Color(0xFFFF3B3B),
            size: 20,
          ),
          onPressed: isAdded ? null : () => _addSuggestedFeed(suggested),
        ),
      ),
    );
  }

  Widget _buildCategoryMatchCard(String category, Color onSurface, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        onTap: () => _showCategoryFeeds(category),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFFF3B3B).withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(LucideIcons.tag, color: Color(0xFFFF3B3B), size: 16),
        ),
        title: Text(category, style: TextStyle(fontWeight: FontWeight.bold, color: onSurface, fontSize: 14)),
        trailing: Icon(LucideIcons.chevron_right, color: onSurface.withValues(alpha: 0.2), size: 18),
      ),
    );
  }

  Future<void> _addSuggestedFeed(SuggestedFeed suggested) async {
    final feed = RssFeed(
      id: const Uuid().v4(),
      title: suggested.title,
      url: suggested.url,
      addedAt: DateTime.now(),
    );
    await ref.read(rssFeedsProvider.notifier).addFeed(feed);
  }

  Widget _buildSearchAndSort(Color onSurface, bool isDark, LibraryMode mode) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(color: onSurface, fontSize: 14),
              decoration: InputDecoration(
                hintText: mode == LibraryMode.library 
                    ? 'Search documents...' 
                    : (mode == LibraryMode.feeds ? 'Search feeds...' : 'Search books...'),
                hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.3)),
                prefixIcon: Icon(Icons.search_rounded, color: onSurface.withValues(alpha: 0.3), size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTapDown: (details) => _showSortPopup(details.globalPosition),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.sort_rounded, color: onSurface.withValues(alpha: 0.6), size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(Color onSurface, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_rounded, size: 64, color: onSurface.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: onSurface.withValues(alpha: 0.4), fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Session session, Color onSurface, bool isDark) {
    final totalWords = session.content.split(RegExp(r'\s+')).length;
    final progress = ((session.position + 1) / (totalWords > 0 ? totalWords : 1)).clamp(0.0, 1.0);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Slidable(
        key: ValueKey(session.id),
        startActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.2,
          children: [
            CustomSlidableAction(
              onPressed: (context) => _showDeleteDialog(session),
              backgroundColor: const Color(0xFFFF3B3B).withValues(alpha: 0.08),
              foregroundColor: const Color(0xFFFF3B3B),
              child: const Icon(Icons.delete_rounded, size: 28),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.2,
          children: [
            CustomSlidableAction(
              onPressed: (context) async {
                await context.push('/preview', extra: {'id': session.id, 'title': session.title, 'content': session.content});
                WidgetsBinding.instance.addPostFrameCallback((_) {
                   if (mounted) ref.read(sessionsProvider.notifier).refresh();
                });
              },
              backgroundColor: const Color(0xFF2196F3).withValues(alpha: 0.08),
              foregroundColor: const Color(0xFF2196F3),
              child: const Icon(Icons.edit_rounded, size: 28),
            ),
          ],
        ),
        child: InkWell(
          onTap: () async {
            await ref.read(readerProvider.notifier).loadSession(session);
            if (mounted) {
              await context.push('/reader');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                 if (mounted) ref.read(sessionsProvider.notifier).refresh();
              });
            }
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(session.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface)),
                          const SizedBox(height: 4),
                          Text('${(progress * 100).toInt()}% • $totalWords words', style: TextStyle(fontSize: 13, color: onSurface.withValues(alpha: 0.5))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: Color(0xFFFF3B3B), shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 20),
                child: Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(color: onSurface.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(3)),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(decoration: BoxDecoration(color: const Color(0xFFFF3B3B), borderRadius: BorderRadius.circular(3))),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedCard(RssFeed feed, Color onSurface, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Slidable(
        key: ValueKey(feed.id),
        startActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.2,
          children: [
            CustomSlidableAction(
              onPressed: (context) => ref.read(rssFeedsProvider.notifier).deleteFeed(feed.id),
              backgroundColor: const Color(0xFFFF3B3B).withValues(alpha: 0.08),
              foregroundColor: const Color(0xFFFF3B3B),
              child: const Icon(Icons.delete_rounded, size: 28),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => context.push('/rss/feed', extra: feed),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B3B).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.rss, color: Color(0xFFFF3B3B), size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(feed.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface)),
                      const SizedBox(height: 2),
                      Text(feed.url, style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.4)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevron_right, color: onSurface.withValues(alpha: 0.2), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryFab() {
    return ExpandableFab(
      distance: 70,
      children: [
        ActionButton(
          onPressed: () => context.push('/preview', extra: {'title': '', 'content': '', 'id': null}),
          icon: const Icon(LucideIcons.clipboard_paste, color: Color(0xFFFF3B3B), size: 20),
          label: 'Paste Text',
        ),
        ActionButton(
          onPressed: pickFiles,
          icon: const Icon(LucideIcons.file_up, color: Color(0xFFFF3B3B), size: 20),
          label: 'Upload File',
        ),
        ActionButton(
          onPressed: showTopicDialog,
          icon: const Icon(LucideIcons.sparkles, color: Color(0xFFFF3B3B), size: 20),
          label: 'AI Topic',
        ),
        ActionButton(
          onPressed: showWikiDialog,
          icon: const Icon(LucideIcons.globe, color: Color(0xFFFF3B3B), size: 20),
          label: 'Wikipedia',
        ),
        ActionButton(
          onPressed: showUrlDialog,
          icon: const Icon(LucideIcons.link, color: Color(0xFFFF3B3B), size: 20),
          label: 'URL Reader',
        ),
      ],
    );
  }

  void _showSortPopup(Offset tapPosition) {
    final settings = ref.read(settingsProvider);
    final isDark = settings.themeMode == ThemeMode.dark;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'SortPopup',
      barrierColor: Colors.black.withValues(alpha: 0.2),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: anim1,
            alignment: Alignment.topRight,
            child: Stack(
              children: [
                Positioned(
                  top: tapPosition.dy + 10,
                  right: 20,
                  child: Material(
                    color: Colors.transparent,
                    child: OverlayMenu(
                      child: Container(
                        width: 220,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 40, offset: const Offset(0, 10))],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildSortTile('Title', LibrarySortType.title),
                            _buildSortTile('Date', LibrarySortType.date),
                            if (ref.read(libraryModeProvider) == LibraryMode.library) ...[
                              _buildSortTile('Words Count', LibrarySortType.size),
                              _buildSortTile('Progress', LibrarySortType.progress),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortTile(String label, LibrarySortType type) {
    final isSelected = _sortType == type;
    final isDark = ref.read(settingsProvider).themeMode == ThemeMode.dark;
    final onSurface = isDark ? Colors.white : Colors.black;

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text(label, style: TextStyle(color: isSelected ? const Color(0xFFFF3B3B) : onSurface, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
      trailing: isSelected ? Icon(_isAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: const Color(0xFFFF3B3B), size: 16) : null,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (_sortType == type) {
            _isAscending = !_isAscending;
          } else {
            _sortType = type;
            _isAscending = true;
          }
        });
        Navigator.pop(context);
      },
    );
  }

  void _showDeleteDialog(Session session) {
    final isDark = ref.read(settingsProvider).themeMode == ThemeMode.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Session?'),
        content: Text('Are you sure you want to delete "${session.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF3B3B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              await ref.read(sessionsProvider.notifier).deleteSession(session.id);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
