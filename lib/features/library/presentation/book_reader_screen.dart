import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:ireader/shared/models/book.dart';
import 'package:ireader/core/providers/app_providers.dart';
import 'package:ireader/features/settings/presentation/settings_controller.dart';

class BookReaderScreen extends ConsumerStatefulWidget {
  final Book book;

  const BookReaderScreen({
    super.key,
    required this.book,
  });

  @override
  ConsumerState<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends ConsumerState<BookReaderScreen> {
  late int _currentChapter;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentChapter = widget.book.currentChapterIndex;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _saveProgress() {
    final updatedBook = widget.book.copyWith(
      currentChapterIndex: _currentChapter,
      updatedAt: DateTime.now(),
    );
    ref.read(bookRepositoryProvider).update(updatedBook);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDark = settings.themeMode == ThemeMode.dark;
    final onSurface = isDark ? Colors.white : Colors.black;
    final chapter = widget.book.chapters[_currentChapter];

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrow_left, color: onSurface),
          onPressed: () {
            _saveProgress();
            context.pop();
          },
        ),
        title: Text(
          widget.book.title,
          style: GoogleFonts.lexend(fontSize: 14, color: onSurface.withValues(alpha: 0.5)),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.list, color: onSurface),
            onPressed: _showChapterPicker,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.title,
                    style: GoogleFonts.lexend(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF3B3B),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    chapter.content,
                    style: TextStyle(
                      fontSize: settings.fontSize * 0.6, // Smaller than RSVP
                      height: 1.8,
                      color: onSurface.withValues(alpha: 0.8),
                      fontFamily: settings.fontFamily,
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _buildNavigation(onSurface, isDark),
        ],
      ),
    );
  }

  Widget _buildNavigation(Color onSurface, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        border: Border(top: BorderSide(color: onSurface.withValues(alpha: 0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _currentChapter > 0 ? () => _changeChapter(_currentChapter - 1) : null,
            icon: const Icon(LucideIcons.chevron_left),
            color: const Color(0xFFFF3B3B),
          ),
          Text(
            'Chapter ${_currentChapter + 1} of ${widget.book.chapters.length}',
            style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: _currentChapter < widget.book.chapters.length - 1 ? () => _changeChapter(_currentChapter + 1) : null,
            icon: const Icon(LucideIcons.chevron_right),
            color: const Color(0xFFFF3B3B),
          ),
        ],
      ),
    );
  }

  void _changeChapter(int index) {
    setState(() {
      _currentChapter = index;
    });
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    _saveProgress();
  }

  void _showChapterPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: ListView.builder(
          itemCount: widget.book.chapters.length,
          itemBuilder: (context, i) => ListTile(
            onTap: () {
              Navigator.pop(context);
              _changeChapter(i);
            },
            title: Text(widget.book.chapters[i].title, style: TextStyle(
              fontWeight: i == _currentChapter ? FontWeight.bold : FontWeight.normal,
              color: i == _currentChapter ? const Color(0xFFFF3B3B) : null,
            )),
            trailing: i == _currentChapter ? const Icon(Icons.check_circle_rounded, color: Color(0xFFFF3B3B), size: 16) : null,
          ),
        ),
      ),
    );
  }
}
