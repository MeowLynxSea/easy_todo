# Repository Guidelines

## Project Structure & Module Organization

- `lib/`: Flutter/Dart source.
  - `main.dart`: app entrypoint.
  - `screens/`, `widgets/`: UI layers.
  - `providers/`: state management (Provider).
  - `services/`, `adapters/`: API/storage integrations.
  - `models/`, `utils/`, `theme/`, `l10n/`: shared types, helpers, styling, localization.
- `assets/l10n/`: ARB localization files (e.g. `app_en.arb`, `app_zh.arb`).
- `test/`: Dart unit/widget tests (currently minimal; add tests here).
- Platform folders: `android/`, `ios/`, `macos/`, `linux/`, `windows/`, `web/`.

## Build, Test, and Development Commands

- `flutter pub get`: install dependencies.
- `flutter run`: run the app on a connected device/simulator.
- `flutter test`: run unit/widget tests in `test/`.
- `flutter test --coverage`: generate coverage in `coverage/`.
- `flutter analyze`: static analysis using `analysis_options.yaml` (`flutter_lints`).
- `dart format .`: auto-format Dart code (run before pushing).
- `dart run build_runner build --delete-conflicting-outputs`: regenerate code (Hive, JSON).
- `flutter gen-l10n`: regenerate localization output (also runs via `flutter generate` as configured).

## Coding Style & Naming Conventions

- Follow `flutter_lints`; keep `flutter analyze` clean.
- Formatting: use `dart format` (don’t hand-align).
- Dart conventions: `lowerCamelCase` for members, `UpperCamelCase` for types, `snake_case.dart` for files.
- Keep UI logic in `screens/`/`widgets/`; keep I/O in `services/` and state in `providers/`.

## Testing Guidelines

- Use `flutter_test` for widget/unit tests and `mocktail` for mocking.
- Name tests `*_test.dart`; mirror library paths when practical (e.g. `test/services/api_service_test.dart`).
- Prefer fast unit tests; add widget tests for critical UI flows and regressions.

## Commit & Pull Request Guidelines

- Commit history is currently minimal and uses simple imperative messages (e.g. “Initial commit”); keep commits readable and scoped.
- PRs should include: summary, testing notes (`flutter test`/`flutter analyze`), and screenshots/screen recordings for UI changes.
- Link related issues/tasks and call out any migration steps (e.g. new permissions, new build_runner outputs).

## Configuration & Security Tips

- Don’t commit secrets. Keep API keys out of source; prefer build-time defines (e.g. `--dart-define=KEY=...`) or ignored local files.
- Treat platform-specific files like `android/local.properties` as machine-specific; avoid editing unless necessary.
