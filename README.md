# Ledger Lens

Ledger Lens is a production-style Flutter personal finance analytics app built with clean architecture, Drift, Riverpod, Freezed, go_router, and fl_chart.

## Features

- Expense tracking with title, amount, category, date, payment mode, and notes
- Borrowed and lent transaction handling aligned with credit/debit logic
- Weekly, monthly, and yearly analytics
- Category distribution, trendline, credit/debit, and borrowed vs lent insights
- CSV export
- PDF export with timestamp, tables, transaction list, and chart snapshots
- Material 3 UI with tablet-friendly responsive navigation
- Seeded sample dataset for quick testing

## Architecture

```text
lib/
  core/
    constants/
    extensions/
    router/
    theme/
  data/
    database/
    mappers/
    models/
    repositories/
    services/
  domain/
    entities/
    repositories/
    usecases/
  presentation/
    controllers/
    screens/
    widgets/
```

## Dependencies

- `flutter_riverpod`
- `go_router`
- `drift`
- `sqlite3_flutter_libs`
- `freezed_annotation`
- `intl`
- `fl_chart`
- `pdf`
- `csv`
- `google_fonts`
- `path`
- `path_provider`
- `cupertino_icons`

### Dev dependencies

- `build_runner`
- `drift_dev`
- `freezed`
- `flutter_lints`
- `flutter_test`

## Setup

1. Install Flutter 3.38+ and Dart 3.10+.
2. Run `flutter pub get`.
3. Run `dart run build_runner build --delete-conflicting-outputs`.
4. Launch with `flutter run`.

## Notes

- SQLite data is stored locally via Drift.
- Export files are written to the app documents directory under `exports/`.
- Default categories and sample transactions are seeded on first launch.
- The current build targets mobile and desktop Flutter platforms with local SQLite storage.

## Validation

- `flutter analyze`
- `flutter test`
