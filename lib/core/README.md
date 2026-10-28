# Core Layer

Reusable, framework-agnostic building blocks shared across every feature.

## Responsibilities

- **constants/** — App-wide constant values (colors, sizes, strings, ids).
- **theme/** — Material 3 theme, color palette and typography definitions.
- **router/** — GoRouter route configuration and navigation helpers.
- **utils/** — Pure helper functions (date math, formatting, validation).
- **widgets/** — Generic reusable widgets (buttons, cards, empty states).
- **services/** — Reusable services and engines: error handling (`Result`,
  `ForgeFailure`), logging, validation, dates, search, haptics, device,
  connectivity, lifecycle, permissions, notifications, analytics, file
  access, preferences, clipboard, sharing, image processing, and the
  data bundle / export / import / backup engines built on
  `data_registry.dart`.

## Services layer

Every fallible service returns a `Result<T>` — either `Success(value)` or
`Failure(ForgeFailure)` — instead of throwing, so feature code never
handles raw platform exceptions. See `services/error_handling/`.

`data_registry.dart` is the single source of truth mapping every Hive box
to a JSON-safe encoder/decoder. Export, import and backup all speak one
versioned, checksummed envelope (`data_bundle.dart`): export captures the
dataset, import validates/merges it back with a conflict policy, and backup
wraps the same bundle in a timestamped, optionally gzip-compressed file.

Service providers are wired in `lib/services/providers.dart`; engine
providers there depend on the overridden `databaseServiceProvider`.

## Services architecture

```
                    ┌─────────────────────────────────────────────┐
                    │            Feature / Presentation           │
                    └───────────────┬─────────────────────────────┘
                                    │  await service.op(...) -> Result<T>
                   ┌────────────────▼─────────────┐
                   │   Reusable service layer      │   result.dart /
                   │   (logger, date, validation,  │   forge_failures.dart
                   │   search, device, connectivity│   = shared types
                   │   lifecycle, haptics,         │
                   │   permissions, notifications, │
                   │   analytics, file, storage,   │
                   │   clipboard, share, image)    │
                   └───────────────┬───────────────┘
                                   │  Result<T> + typed ForgeFailure
        ┌──────────────────────────▼──────────────────────────┐
        │  data_registry.dart  (box -> encoder/decoder)       │
        │  data_bundle.dart    (versioned, checksummed envelope│
        └───────┬────────────────────────────┬────────────────┘
                │ capture()/apply()          │ gzip + file I/O
   ┌────────────▼───────────┐   ┌────────────▼──────────────┐
   │  ExportEngine          │   │  BackupEngine              │
   │  ImportEngine          │   │  (.forgebak / .forgebak.gz)│
   └────────────┬───────────┘   └───────────────────────────┘
                │ HiveDataSnapshotSource
     ┌──────────▼──────────┐
     │  Hive boxes          │
     │  (database_service)  │
     └─────────────────────┘
```

All service providers live in `lib/services/providers.dart`.

## Rules

- No feature-specific logic lives here.
- Core must not import from `features/`.
- Core may import `models/` and `database/` only inside the services layer
  (snapshot serialization) — everything else stays clean.
- All operations return `Result`; no `print()`, no thrown leaks at the edge.
