# Daily Use

`Daily Use` is a Flutter app with four main tabs:

- `Credential`
- `Expense`
- `Task`
- `Settings`

It uses local storage, feature-based organization, and Bloc-driven UI flow to keep each module separated but still part of one app shell.

## What The App Does

- `Credential`: stores encrypted credentials locally, asks for an encryption key only when the user first opens the Credential tab, and keeps credential settings inside the Credential area.
- `Expense`: tracks money flow, banks, categories, analytics, and exports.
- `Task`: manages daily tasks, categories, completion, and analytics.
- `Settings`: keeps app-wide preferences such as theme, notifications, and export folder settings.

## Tech Stack

- `Flutter`
- `flutter_bloc`
- `drift`
- `flutter_secure_storage`
- `local_auth`
- `equatable`
- `intl`
- `pdf`
- `csv`

## Top-Level Folder Structure

This is the main project layout at the repo root:

```text
android/     Android project files
ios/         iOS project files
lib/         Main Flutter application code
linux/       Linux desktop runner
macos/       macOS desktop runner
test/        Widget/unit tests
web/         Web runner
windows/     Windows desktop runner
build/       Generated build output
README.md    Project overview
pubspec.yaml Flutter dependencies and package config
```

## `lib/` Structure

Top-level Dart folders:

```text
lib/
  core/         App-wide blocs, router, services, theme, shell widgets
  data/         Shared database and repository implementations
  domain/       Shared use-cases and entities
  features/     Feature-first modules such as credential, expense, tasks, settings
  presentation/ Older shared finance presentation layer used by the app
  shared/       Reusable UI widgets
```

Feature folders generally follow this pattern:

```text
features/
  <feature>/
    data/
    domain/
    presentation/
```

## Important App Areas

- `lib/core/widgets/app_shell.dart`: bottom navigation shell for all tabs
- `lib/core/router/app_router.dart`: route definitions
- `lib/features/credentials/`: encrypted credential flow and credential settings
- `lib/features/expense/`: expense tracking, analytics, entries, and settings
- `lib/features/tasks/`: task list, task editor, analytics, and settings
- `lib/features/settings/`: app-wide settings UI

## Getting Started

1. Run `flutter pub get`
2. Run `dart run build_runner build --delete-conflicting-outputs`
3. Run `flutter run`

## Useful Commands

- `flutter analyze`
- `flutter test`

## Notes

- Credential data is stored locally and protected with an encryption key.
- Biometric unlock can be enabled from Credential settings when supported on the device.
- Expense, Credential, and Task settings are handled inside their own modules, while global app preferences stay in Settings.
