# Vyro

**Stay Focused. Stay Consistent.**

Vyro is a modern productivity app combining task management, habit tracking, focus sessions (Pomodoro), journaling with mood tracking, and productivity analytics — built with Flutter + Material 3.

## Tech Stack

- Flutter (stable)
- Material 3
- flutter_riverpod (state management)
- hive / hive_flutter (local database)
- go_router (navigation)
- flutter_local_notifications (reminders)
- fl_chart (analytics charts)

## Run Locally

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

## Build APK via GitHub Actions

This repo includes `.github/workflows/build.yml`. Just push to `main` or `master`
(or run it manually from the **Actions** tab → "Build Vyro APK" → "Run workflow").

The workflow will:
1. Set up Flutter + Java
2. Run `flutter pub get`
3. Generate Hive adapters
4. Build a release APK
5. Upload it as an artifact named **vyro-release-apk**

Download the APK from the workflow run's **Artifacts** section once it completes.

## Project Structure

```
lib/
├── core/            # theme, constants, utils, router
├── features/
│   ├── home/
│   ├── tasks/
│   ├── habits/
│   ├── focus/
│   ├── journal/
│   ├── analytics/
│   └── settings/
├── shared/widgets/  # reusable UI components
├── services/        # database & notification services
├── models/          # Hive models + adapters
└── main.dart
```

## Notes

- App icon / launcher assets are using Flutter defaults; replace
  `android/app/src/main/res/mipmap-*` icons with your own before publishing.
- `android/local.properties` contains placeholder SDK paths — GitHub Actions
  generates its own via the Flutter setup action, so this is fine for CI builds.
  For local builds, update the paths to match your machine.
