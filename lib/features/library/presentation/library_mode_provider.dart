import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LibraryMode { library, feeds, books }

class LibraryModeNotifier extends Notifier<LibraryMode> {
  @override
  LibraryMode build() => LibraryMode.library;

  @override
  set state(LibraryMode mode) => super.state = mode;
}

final libraryModeProvider = NotifierProvider<LibraryModeNotifier, LibraryMode>(LibraryModeNotifier.new);
