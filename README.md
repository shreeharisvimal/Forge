# Forge

An offline-first gym tracker. Built for Android, with everything stored locally — no login, no cloud, no internet required.

## Stack

- Flutter (Material 3, dark AMOLED theme)
- Riverpod for state management
- GoRouter for navigation
- Hive for local persistence

## Getting started

```sh
flutter pub get
flutter run
```

## Architecture

```
lib/
├── core/       # theme, router, design system, constants, utils, widgets
│   └── services/   # reusable services + export/import/backup engines
├── database/   # Hive setup, box names, migrations
├── models/     # domain models
├── services/   # persistence repositories + Riverpod provider hub
└── features/   # feature-first modules (dashboard, calendar, workouts, ...)
```

Run analysis and tests with:

```sh
flutter analyze
flutter test
```
