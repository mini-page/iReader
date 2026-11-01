# MEMORY TRACK — iReader

## PURPOSE
Track all structural changes for rollback and debugging.

---

## FORMAT

### [TIMESTAMP]

ACTION:
- What changed

FILES:
- List of modified files

REASON:
- Why change was needed

IMPACT:
- Expected effect

ROLLBACK:
- Steps to undo

---

## RULES

- Update after EVERY change
- No skipped entries
- Keep concise

---

### [2026-05-03 02:05]

ACTION:
Implemented a comprehensive UX redesign for the Home screen and built a new
multi-page RSS management and reading system.

FILES:
- lib/features/home/presentation/home_screen.dart
- lib/features/home/presentation/widgets/home_widgets.dart
- lib/features/rss/data/rss_feed_repository.dart
- lib/features/rss/providers/rss_providers.dart
- lib/features/rss/presentation/rss_feed_manager_screen.dart
- lib/features/rss/presentation/rss_article_list_screen.dart
- lib/features/rss/presentation/rss_article_reader_screen.dart
- lib/app.dart

REASON:
Improve app engagement by prioritizing "Continue Reading", densifying action
access, and providing a professional-grade RSS ingestion and speed-reading
pipeline.

IMPACT:
Home screen layout is now more hierarchical and efficient. RSS is a fully
integrated feature with feed management, clean article extraction, and RSVP
overlay support. Codebase remains clean with no analyzer issues.

ROLLBACK:
Revert the layout changes in `home_screen.dart` and `home_widgets.dart`. Delete
the `lib/features/rss` directory and restore old RSS routes in `app.dart`.

---

### [2026-05-03 01:15]

ACTION:
Resolved all remaining lint issues, critical errors, and deprecated member
usage identified by `flutter analyze`.

FILES:
- lib/features/reader/presentation/widgets/quick_settings_popup.dart
- lib/features/stats/presentation/stats_screen.dart
- lib/features/home/presentation/home_screen.dart
- lib/features/library/presentation/library_screen.dart
- lib/features/settings/presentation/settings_screen.dart
- lib/core/services/dictionary_provider.dart
- lib/core/services/translation_provider.dart
- lib/features/bookmarks/presentation/widgets/bookmarks_section.dart
- lib/features/home/presentation/preview_screen.dart
- lib/features/main/presentation/main_scaffold.dart
- lib/features/reader/presentation/reader_controller.dart
- test/reader_controller_test.dart

REASON:
Codebase was carrying 22 issues, including a critical undefined `ref` error in
the reader UI and multiple async context usage violations.

IMPACT:
Clean `flutter analyze` report. Corrected reader UI stability for language
translation. Updated to modern Flutter color methods.

ROLLBACK:
Revert the specific code changes in each file. For `stats_screen.dart`, restore
`withOpacity`. For `quick_settings_popup.dart`, remove the `ref` parameter.

---

### [2026-05-03 00:05]

ACTION:
Added a shared infrastructure provider layer for repositories, services, and
audio player lifecycle management.

FILES:
- lib/core/providers/app_providers.dart

REASON:
Remove duplicated provider definitions across features and create one stable
dependency surface for the refactor.

IMPACT:
Enables consistent dependency injection, easier overrides in tests, and safer
modularization of optional capabilities.

ROLLBACK:
Delete `lib/core/providers/app_providers.dart` and restore local provider
definitions.

---

### [2026-05-03 00:10]

ACTION:
Rewired feature and service modules to consume the shared provider layer and
removed duplicate provider declarations.

FILES:
- lib/core/services/ai_service.dart
- lib/core/services/secure_storage_service.dart
- lib/features/stats/data/stats_repository.dart
- lib/core/services/rss_provider.dart
- lib/core/services/dictionary_provider.dart
- lib/core/services/translation_provider.dart
- lib/features/bookmarks/presentation/bookmarks_provider.dart
- lib/features/home/data/sessions_provider.dart
- lib/features/reader/presentation/reader_controller.dart

REASON:
Provider duplication was fragmenting dependency injection and making modular
fallbacks harder to implement safely.

IMPACT:
Dependencies now resolve from one shared graph, which improves consistency and
reduces accidental divergence between features.

ROLLBACK:
Restore the removed provider declarations in each file and remove shared
provider imports.

---

### [2026-05-03 00:16]

ACTION:
Fixed preview-to-reader session continuity and added reader cleanup for timer
and TTS lifecycle.

FILES:
- lib/features/library/data/session_repository.dart
- lib/features/reader/presentation/reader_controller.dart
- lib/features/home/presentation/preview_screen.dart

REASON:
Starting reading from preview was creating fresh session identities, which
broke resume semantics and bookmark continuity.

IMPACT:
Existing sessions keep their IDs, new sessions are created once, and reader
resources are released when the notifier is disposed.

ROLLBACK:
Restore `SessionRepository.create` to `Future<void>`, remove the optional
`sessionId` path from `loadText`, and remove the notifier disposal callback.

---

### [2026-05-03 00:21]

ACTION:
Added shared result and failure models for service-layer error handling.

FILES:
- lib/core/models/app_failure.dart
- lib/core/models/service_result.dart

REASON:
Network-backed and optional features were mixing `null`, empty data, and thrown
exceptions, which made graceful degradation inconsistent.

IMPACT:
Services can now return typed success/error outcomes with consistent messages.

ROLLBACK:
Delete the new core model files and restore service-specific ad hoc error
handling.

---

### [2026-05-03 00:31]

ACTION:
Moved Wikipedia and translation off the AI path, added typed transform handling
in the reader, and normalized content extraction to use service results.

FILES:
- lib/features/reader/presentation/reader_controller.dart
- lib/shared/widgets/reading_action_mixin.dart
- lib/features/reader/presentation/widgets/quick_settings_popup.dart
- lib/features/reader/presentation/reader_screen.dart

REASON:
Wikipedia fetch and translation should work even when no AI key is configured,
and transformed content should reset stale bookmark state safely.

IMPACT:
AI is now more isolated to summary/topic generation, while core reading inputs
remain available without AI configuration.

ROLLBACK:
Restore Wikipedia and translation to AI callbacks, remove
`transformWithResult`, and revert the reader transform overlay copy.

---

### [2026-05-03 00:38]

ACTION:
Added explicit settings hydration state and updated splash routing to wait for
real settings before deciding onboarding flow.

FILES:
- lib/shared/models/app_settings.dart
- lib/features/settings/presentation/settings_controller.dart
- lib/features/splash/presentation/splash_screen.dart

REASON:
Startup routing was reading default settings before persisted values finished
loading, which could misroute onboarding.

IMPACT:
Splash now waits for hydrated settings, so onboarding and theme state come from
persisted data rather than race-prone defaults.

ROLLBACK:
Remove `isLoaded` from `AppSettings`, stop setting it in the controller, and
revert splash navigation to the previous direct read.

---

### [2026-05-03 00:44]

ACTION:
Updated service consumers to read typed results, moved bookmark audio playback
to a shared provider, and corrected shared provider wiring/imports.

FILES:
- lib/features/home/presentation/rss_feed_screen.dart
- lib/features/bookmarks/presentation/bookmark_session_screen.dart
- lib/core/providers/app_providers.dart
- lib/features/settings/presentation/settings_screen.dart
- lib/features/reader/presentation/widgets/quick_settings_popup.dart

REASON:
Screens still expected old nullable service contracts, and one shared provider
constructor was still wired to the old AI service signature.

IMPACT:
UI error handling now matches the refactored service layer and avoids creating
disposable audio objects inside widget builds.

ROLLBACK:
Restore the previous consumer logic for RSS/bookmark details, reintroduce local
audio player creation, and revert provider/import wiring.

---

### [2026-05-03 00:50]

ACTION:
Completed data reset paths so library clearing and full reset also clear
bookmarks, stats, cached keys, and provider caches.

FILES:
- lib/features/stats/data/stats_repository.dart
- lib/features/settings/presentation/settings_screen.dart

REASON:
Reset actions previously left related app state behind, which made storage and
UI state inconsistent after destructive actions.

IMPACT:
Reset and clear operations now match their labels and leave the app in a clean,
predictable state.

ROLLBACK:
Remove stats/key/bookmark clearing from settings actions and delete the new
`StatsRepository.clear()` helper.

---

### [2026-05-03 01:02]

ACTION:
Added regression tests covering session continuity, transform cleanup, AI
absence handling, and settings hydration state.

FILES:
- test/reader_controller_test.dart

REASON:
The refactor changed several high-risk flows and needed targeted guard rails.

IMPACT:
Future changes now have direct tests for the session/bookmark/AI bootstrapping
behaviors corrected in this pass.

ROLLBACK:
Delete `test/reader_controller_test.dart`.

---

### [2026-05-03 01:08]

ACTION:
Removed obvious stale imports after the provider and service refactor.

FILES:
- lib/core/services/ai_service.dart
- lib/features/bookmarks/presentation/bookmarks_provider.dart
- lib/features/home/data/sessions_provider.dart
- lib/features/reader/presentation/reader_controller.dart

REASON:
Shared provider centralization left a few imports behind that no longer map to
runtime usage.

IMPACT:
Reduces trivial lint noise and lowers the chance of avoidable build failures.

ROLLBACK:
Re-add the removed imports if a downstream file still depends on them.

---

### [2026-05-02 16:30]

ACTION:
Massive overhaul and unification of the Reader UI.

FILES:
- lib/features/reader/presentation/reader_screen.dart
- lib/features/reader/presentation/reader_controller.dart
- lib/features/reader/presentation/widgets/reader_layout.dart
- lib/features/reader/presentation/widgets/reader_engine.dart (CREATED)
- lib/features/reader/presentation/widgets/quick_settings_popup.dart (REDESIGNED)
- lib/features/reader/presentation/widgets/rsvp_view.dart (REMOVED)
- lib/features/reader/presentation/widgets/scroll_mode_view.dart (REMOVED)

REASON:
Streamline user experience by centralizing AI actions and modes into a unified hub, simplifying navigation, and providing modern, high-utility controls (fat progress bar, toggleable context).

IMPACT:
Significantly reduced UI friction. Unified high-performance engine for RSVP and Scroll modes. Professional, high-contrast aesthetic with intuitive interactive seeking.

ROLLBACK:
Revert Reader feature directory to previous state via git.
