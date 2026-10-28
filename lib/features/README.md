# Features Layer

Feature-first modules, one folder per vertical slice.

## Modules

- **dashboard/** — Home overview.
- **calendar/** — Monthly workout history.
- **workouts/** — Create/edit/run workouts.
- **exercises/** — Exercise library.
- **progress/** — Analytics and charts.
- **body/** — Body measurement tracking.
- **prs/** — Personal records.
- **settings/** — App preferences.

## Structure per feature

```
feature/
  presentation/  — widgets + screens
  providers/     — Riverpod providers
  data/          — feature-specific repositories
```

Features may import `core/`, `models/` and `services/`.
