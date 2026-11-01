import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ireader/features/reader/presentation/reader_controller.dart';

abstract class ReaderAudioHandler extends BaseAudioHandler {
  void setContainer(ProviderContainer container);
  void updateMetadata({required String title, required String author});
}

/// A fallback handler for when the native AudioService fails to initialize.
class StubAudioHandler extends ReaderAudioHandler with SeekHandler {
  @override
  void setContainer(ProviderContainer container) {}
  @override
  void updateMetadata({required String title, required String author}) {}
}

class IReaderAudioHandler extends ReaderAudioHandler with SeekHandler {
  ProviderContainer? _container;

  @override
  void setContainer(ProviderContainer container) {
    _container = container;
  }

  @override
  void updateMetadata({required String title, required String author}) {
    mediaItem.add(MediaItem(
      id: 'ireader_tts',
      album: 'iReader',
      title: title,
      artist: author,
    ));
  }

  @override
  Future<void> play() async {
    if (_container == null) return;
    final controller = _container!.read(readerProvider.notifier);
    controller.play();
    playbackState.add(playbackState.value.copyWith(
      playing: true,
      controls: [MediaControl.pause, MediaControl.stop],
    ));
  }

  @override
  Future<void> pause() async {
    if (_container == null) return;
    final controller = _container!.read(readerProvider.notifier);
    controller.pause();
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      controls: [MediaControl.play, MediaControl.stop],
    ));
  }

  @override
  Future<void> stop() async {
    if (_container == null) return;
    final controller = _container!.read(readerProvider.notifier);
    controller.pause();
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
  }
}
