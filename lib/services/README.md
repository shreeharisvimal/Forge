# Services Layer

Application services that orchestrate persistence and business rules.

## Responsibilities

- Hive-backed CRUD for each aggregate (workouts, exercises, progress).
- Riverpod providers exposing state to features.
- Pure logic stays in models/utils; services own I/O and state.
