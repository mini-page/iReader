import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:ireader/features/settings/presentation/settings_controller.dart';
import 'package:ireader/features/reader/presentation/reader_controller.dart';

class ReaderAppBar extends ConsumerWidget {
  final VoidCallback onToggleSettings;
  final bool isSettingsOpen;

  const ReaderAppBar({
    super.key,
    required this.onToggleSettings,
    required this.isSettingsOpen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(readerProvider);
    final settings = ref.watch(settingsProvider);
    final isDark = settings.themeMode == ThemeMode.dark;
    final onSurface = isDark ? Colors.white : Colors.black;
    final progressPercent = (state.progress * 100).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleButton(Icons.arrow_back_rounded, () => context.pop(), onSurface: onSurface),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Text(
                    state.title.toUpperCase(),
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${state.index} / ${state.tokens.length} • $progressPercent%',
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.4),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildCircleButton(
            LucideIcons.sparkles, 
            onToggleSettings, 
            isSelected: isSettingsOpen,
            secondaryIcon: Icons.tune_rounded,
            onSurface: onSurface,
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap, {bool isSelected = false, IconData? secondaryIcon, required Color onSurface}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? onSurface : onSurface.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: isSelected ? (onSurface == Colors.white ? Colors.black : Colors.white) : onSurface, size: 18),
            if (secondaryIcon != null)
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected ? (onSurface == Colors.white ? Colors.black : Colors.white) : const Color(0xFFFF3B3B),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(secondaryIcon, color: isSelected ? onSurface : Colors.white, size: 8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ReaderBottomControls extends ConsumerWidget {
  const ReaderBottomControls({super.key});

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(readerProvider);
    final controller = ref.read(readerProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final isDark = settings.themeMode == ThemeMode.dark;
    final onSurface = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 40, top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFatProgressBar(context, state, controller, onSurface),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(state.currentDurationSeconds),
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _formatDuration(state.totalDurationSeconds),
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  final nextWpm = (state.wpm + 100);
                  controller.setWpm(nextWpm > 1000 ? 200 : nextWpm.toDouble());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: onSurface.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${state.wpm} WPM',
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildControlIcon(LucideIcons.skip_back, controller.skipBackward, onSurface),
                  const SizedBox(width: 24),
                  GestureDetector(
                    onTap: state.isPlaying ? controller.pause : controller.play,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B3B),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF3B3B).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  _buildControlIcon(LucideIcons.skip_forward, controller.skipForward, onSurface),
                ],
              ),
              GestureDetector(
                onTap: () {
                  controller.setMode(state.mode == ReadingMode.rsvp ? ReadingMode.scroll : ReadingMode.rsvp);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: onSurface.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    state.mode == ReadingMode.rsvp ? LucideIcons.zap : LucideIcons.align_start_horizontal,
                    color: onSurface,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlIcon(IconData icon, VoidCallback onTap, Color onSurface) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: onSurface.withValues(alpha: 0.7), size: 32),
    );
  }

  Widget _buildFatProgressBar(BuildContext context, ReaderState state, ReaderController controller, Color onSurface) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (details) {
        final box = context.findRenderObject() as RenderBox;
        final localPos = box.globalToLocal(details.globalPosition);
        final percent = (localPos.dx / box.size.width).clamp(0.0, 1.0);
        controller.seekTo(percent, persist: false);
      },
      onHorizontalDragEnd: (details) {
        final percent = state.progress;
        controller.seekTo(percent, persist: true);
      },
      child: Container(
        height: 12,
        width: double.infinity,
        decoration: BoxDecoration(
          color: onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: state.progress,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFF3B3B),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF3B3B).withValues(alpha: 0.3),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
