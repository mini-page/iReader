import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:ireader/core/services/rss_service.dart';
import 'package:ireader/core/providers/app_providers.dart';
import 'package:ireader/core/services/article_service.dart';
import 'package:ireader/features/reader/presentation/reader_controller.dart';
import 'package:ireader/features/reader/presentation/widgets/reader_engine.dart';
import 'package:ireader/features/settings/presentation/settings_controller.dart';

class RssArticleReaderScreen extends ConsumerStatefulWidget {
  final RssFeedItem item;

  const RssArticleReaderScreen({
    super.key,
    required this.item,
  });

  @override
  ConsumerState<RssArticleReaderScreen> createState() => _RssArticleReaderScreenState();
}

class _RssArticleReaderScreenState extends ConsumerState<RssArticleReaderScreen> {
  ExtractedArticle? _article;
  bool _isLoading = true;
  String? _error;
  bool _showRsvpOverlay = false;
  final ScrollController _rsvpScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchArticle();
  }

  @override
  void dispose() {
    _rsvpScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchArticle() async {
    if (widget.item.link == null) {
      setState(() {
        _isLoading = false;
        _error = 'Invalid article link';
      });
      return;
    }

    final result = await ref.read(articleServiceProvider).extractFromUrl(widget.item.link!);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.isSuccess) {
          _article = result.requireData;
        } else {
          _error = result.failure?.message ?? 'Failed to extract content';
        }
      });
    }
  }

  void _startRsvp() {
    if (_article == null) return;
    
    // Load text into reader controller
    ref.read(readerProvider.notifier).loadText(
      _article!.title,
      _article!.content,
      wpm: ref.read(settingsProvider).defaultWpm,
    );
    ref.read(readerProvider.notifier).setMode(ReadingMode.rsvp);

    setState(() => _showRsvpOverlay = true);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDark = settings.themeMode == ThemeMode.dark;
    final onSurface = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrow_left, color: onSurface),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_article != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _startRsvp,
                icon: const Icon(LucideIcons.zap, size: 16, color: Color(0xFFFF3B3B)),
                label: const Text('Speed Read', style: TextStyle(color: Color(0xFFFF3B3B), fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            _buildErrorState(onSurface)
          else if (_article != null)
            _buildArticleContent(onSurface, isDark),
          
          if (_showRsvpOverlay)
            _buildRsvpOverlay(isDark, onSurface, settings),
        ],
      ),
    );
  }

  Widget _buildErrorState(Color onSurface) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.triangle_alert, color: onSurface.withValues(alpha: 0.2), size: 48),
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: onSurface.withValues(alpha: 0.4))),
          const SizedBox(height: 24),
          TextButton(onPressed: _fetchArticle, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildArticleContent(Color onSurface, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.item.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                widget.item.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          if (widget.item.imageUrl != null) const SizedBox(height: 32),
          Text(
            _article!.title,
            style: GoogleFonts.lexend(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_article!.siteName != null) ...[
                Text(_article!.siteName!, style: const TextStyle(color: Color(0xFFFF3B3B), fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 8),
                Text('•', style: TextStyle(color: onSurface.withValues(alpha: 0.2))),
                const SizedBox(width: 8),
              ],
              Text(
                '${(_article!.content.split(RegExp(r'\s+')).length / 250).ceil()} min read',
                style: TextStyle(color: onSurface.withValues(alpha: 0.4), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            _article!.content,
            style: TextStyle(
              fontSize: 18,
              color: onSurface.withValues(alpha: 0.8),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildRsvpOverlay(bool isDark, Color onSurface, dynamic settings) {
    final readerState = ref.watch(readerProvider);
    final readerCtrl = ref.read(readerProvider.notifier);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 40, offset: const Offset(0, -10))],
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: onSurface.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.zap, size: 14, color: Color(0xFFFF3B3B)),
                      const SizedBox(width: 8),
                      Text('RSVP MODE', style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2, color: const Color(0xFFFF3B3B))),
                    ],
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x, size: 20, color: onSurface.withValues(alpha: 0.4)),
                    onPressed: () {
                      readerCtrl.pause();
                      setState(() => _showRsvpOverlay = false);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ReaderEngineView(
                  scrollController: _rsvpScrollController,
                  fontSize: settings.fontSize,
                  orpColor: Color(settings.orpColorValue),
                  fontFamily: settings.fontFamily,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Column(
                children: [
                  _buildMiniProgressBar(readerState),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(LucideIcons.skip_back, size: 20, color: onSurface.withValues(alpha: 0.4)),
                        onPressed: () => readerCtrl.skipBackward(),
                      ),
                      const SizedBox(width: 24),
                      GestureDetector(
                        onTap: readerState.isPlaying ? readerCtrl.pause : readerCtrl.play,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3B3B),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: const Color(0xFFFF3B3B).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
                          ),
                          child: Icon(
                            readerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        icon: Icon(LucideIcons.skip_forward, size: 20, color: onSurface.withValues(alpha: 0.4)),
                        onPressed: () => readerCtrl.skipForward(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniProgressBar(ReaderState state) {
    return Container(
      height: 4,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(2),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: state.progress,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFF3B3B),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
