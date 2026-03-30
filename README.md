# Ledger Lens

Ledger Lens is a Flutter personal finance app with two isolated modules:

- `Expense`
- `Tasks`

The app uses a fixed bottom navigation bar, feature-based architecture, Drift for local storage, and Bloc for state management.

## Architecture

```text
lib/
  core/
    blocs/
    router/
    theme/
    widgets/
  data/
    database/
  features/
    expense/
      data/
      domain/
      presentation/
    tasks/
      data/
      domain/
      presentation/
  shared/
    widgets/
```

## Expense module

- Existing expense tracking flow retained under the `Expense` module
- Added `Investment` category
- Bank name CRUD in Expense Settings
- Default banks: `Axis`, `BOB`, `SBI`, `HDFC`, `Kotak`
- Optional bank selection on expense entries
- Bank-based filtering on dashboard and analytics
- Independent expense analytics for credit/debit, borrowed/lent, category spend, and trends

## Tasks module

- CRUD for tasks with title, description, category, date, priority, daily toggle, and completion state
- Horizontally scrollable date selector
- Date-filtered task list
- Daily task auto-replication to the next day
- Independent analytics for completed vs pending, priority distribution, daily streak, and category breakdown

## State management

Bloc is used for:

- bottom module navigation
- expense dashboard
- expense form
- bank CRUD
- expense analytics
- task list and selected date
- task editor
- task analytics

## Key dependencies

- `flutter_bloc`
- `equatable`
- `drift`
- `sqlite3_flutter_libs`
- `fl_chart`
- `intl`
- `path_provider`
- `pdf`
- `csv`
- `google_fonts`

## Setup

1. `flutter pub get`
2. `dart run build_runner build --delete-conflicting-outputs`
3. `flutter run`

## Validation

- `flutter analyze`
- `flutter test`
