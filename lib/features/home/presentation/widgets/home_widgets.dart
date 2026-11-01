import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ireader/shared/models/session.dart';
import 'package:ireader/shared/widgets/motion.dart';
import 'package:ireader/features/reader/presentation/reader_controller.dart';

class HomeActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color onSurface;
  final bool isDark;
  final VoidCallback onTap;

  const HomeActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.onSurface,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    return ScaleButton(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 120,
        height: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconBg == const Color(0xFFFF3B3B) ? Colors.white : onSurface, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: onSurface)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 10, color: onSurface.withValues(alpha: 0.4)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ContinueReadingCard extends ConsumerWidget {
  final Session session;
  final Color onSurface;
  final bool isDark;
  final VoidCallback onPlay;

  const ContinueReadingCard({
    super.key,
    required this.session,
    required this.onSurface,
    required this.isDark,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readerState = ref.watch(readerProvider);
    final readerCtrl = ref.read(readerProvider.notifier);
    final isThisSessionActive = readerState.sessionId == session.id;
    
    final totalWords = session.content.split(RegExp(r'\s+')).length;
    final progress = isThisSessionActive ? readerState.progress : ((session.position + 1) / totalWords).clamp(0.0, 1.0);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CONTINUE READING', style: TextStyle(fontSize: 12, letterSpacing: 1.5, color: onSurface.withValues(alpha: 0.3), fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          clipBehavior: Clip.antiAlias,
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
                          Text(session.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface)),
                          const SizedBox(height: 4),
                          Text('${(progress * 100).toInt()}% • $totalWords words', style: TextStyle(fontSize: 14, color: onSurface.withValues(alpha: 0.5))),
                        ],
                      ),
                    ),
                    ScaleButton(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        if (isThisSessionActive) {
                          if (readerState.isPlaying) {
                            readerCtrl.pause();
                          } else {
                            readerCtrl.play();
                          }
                        } else {
                          onPlay();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(color: Color(0xFFFF3B3B), shape: BoxShape.circle),
                        child: Icon(
                          (isThisSessionActive && readerState.isPlaying) ? Icons.pause_rounded : Icons.play_arrow_rounded, 
                          color: Colors.white, 
                          size: 24
                        ),
                      ),
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
      ],
    );
  }
}

class ProcessingOverlay extends StatelessWidget {
  final String label;

  const ProcessingOverlay({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                color: Color(0xFFFF3B3B),
                strokeWidth: 4,
              ),
            ),
            const SizedBox(height: 32),
            Text(label, style: const TextStyle(color: Color(0xFFFF3B3B), fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 14)),
            const SizedBox(height: 8),
            Text('Synthesizing content neurons...', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
