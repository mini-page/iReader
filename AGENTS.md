# Repository Guidelines

## Project Structure & Module Organization
`lib/` contains the app code. Follow the feature-first layout already in use:
`lib/features/<feature>/presentation|data|domain`, with shared cross-feature
code in `lib/shared/` and app-wide services, constants, and theme setup in
`lib/core/`. Entry points live in `lib/main.dart` and `lib/app.dart`.
Tests live in `test/` for unit and widget coverage and `integration_test/`
for end-to-end flows. Static assets are under `assets/` and must be registered
in `pubspec.yaml`. Platform folders (`android/`, `ios/`, `linux/`, `macos/`,
`web/`, `windows/`) should only change for platform-specific work.

## Build, Test, and Development Commands
Run these from the repo root:

- `flutter pub get` installs dependencies.
- `flutter analyze` runs Dart and Flutter lints from `analysis_options.yaml`.
- `dart format lib test integration_test` formats source and tests.
- `flutter test` runs unit and widget tests.
- `flutter test integration_test/` runs integration tests.
- `flutter run` launches the app on the current device or emulator.

## Coding Style & Naming Conventions
Use standard Dart style: 2-space indentation, trailing commas where helpful,
and keep lines readable. This repo uses `flutter_lints`; fix analyzer warnings
before opening a PR. Use `PascalCase` for classes, `camelCase` for members,
and `snake_case.dart` for files. Match existing names such as `SettingsScreen`,
`session_repository.dart`, and Riverpod providers ending in `Provider`.

## Testing Guidelines
Name tests `*_test.dart`. Keep pure logic in unit tests, UI behavior in
`testWidgets`, and multi-screen flows in `integration_test/`. Add or update
tests for any change to reader timing, persistence, routing, or settings.
Prefer focused assertions over broad smoke tests.

## Commit & Pull Request Guidelines
Recent history uses short, lowercase subjects with prefixes like `feat:`,
`fix:`, and `add:`. Keep that pattern, but make messages clearer:
`feat: add RSS feed preview screen`. PRs should include a brief summary,
testing notes (`flutter analyze`, `flutter test`), linked issues when
applicable, and screenshots or recordings for UI changes.

## Configuration & Assets
Do not commit secrets or local machine configuration. When adding images,
fonts, or icons, place them under `assets/` and update `pubspec.yaml` in the
same change.
