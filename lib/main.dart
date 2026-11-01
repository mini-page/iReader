import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ireader/core/providers/app_providers.dart';
import 'package:audio_service/audio_service.dart';
import 'package:ireader/core/services/audio_handler.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Hive.initFlutter();
    
    ReaderAudioHandler audioHandler;
    
    try {
      audioHandler = await AudioService.init(
        builder: () => IReaderAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.ireader.app.channel.audio',
          androidNotificationChannelName: 'iReader Playback',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      ) as ReaderAudioHandler;
    } catch (e) {
      print('AudioService initialization failed, using stub: $e');
      audioHandler = StubAudioHandler();
    }

    final container = ProviderContainer(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
    );

    if (audioHandler is IReaderAudioHandler) {
      audioHandler.setContainer(container);
    }
    
    // Attempt stats init, but don't let it block forever
    await container.read(statsRepositoryProvider).init().timeout(
      const Duration(seconds: 2),
      onTimeout: () => print('Stats init timed out'),
    );
    
    runApp(UncontrolledProviderScope(
      container: container,
      child: const IReaderApp(),
    ));
  } catch (e, stack) {
    print('Critical initialization error: $e');
    print(stack);
    
    runApp(MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text('Startup Error', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(e.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => main(), 
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
