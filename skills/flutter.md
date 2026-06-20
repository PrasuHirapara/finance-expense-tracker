Daily Use — Flutter Module Reference
Single source of truth for the `finance_analytics_app` Flutter module, maintained from the current codebase.
`Daily Use` is a Flutter application targeting Android (primary) and iOS (future-ready) built for personal finance, credential management, task tracking, and investment analytics. It uses a feature-based folder structure, local-first storage via Drift (SQLite), Firebase Cloud Sync as an optional encrypted backup layer, and BLoC-driven UI flow to keep each module separated inside a single unified app shell.
This file describes the tech stack, strict coding and typing rules, feature integration steps, the layered data-flow pattern, state management guidelines, all cross-cutting concerns (authentication via biometric/encryption key, cross-tab state sync, idle logout, global theme, forms, and the widget wrapping rule), and a migration guide explaining how and where to upgrade the current project structure to match this reference.
---
1. Tech Stack
Concern	Choice
Language	Dart SDK `^3.10.4`
Framework	Flutter (`uses-material-design: true`)
Target Platforms	Android (primary), iOS (future)
State Management	`flutter_bloc ^9.1.1` — Cubit for simple states, full BLoC for complex event-driven flows
Local Database	`drift ^2.28.2` on top of `sqlite3_flutter_libs ^0.5.39`
Code Generation	`build_runner ^2.4.2`, `drift_dev ^2.28.2`
HTTP	`http ^1.2.0` — used only for Firebase REST calls not covered by Firebase SDK
Auth / Biometrics	`local_auth ^2.3.0` — fingerprint / face unlock gate for the Credential tab
Encryption	`cryptography ^2.7.0` + `flutter_secure_storage ^9.2.4` for encrypted credential vault
Cloud Sync	`firebase_core ^4.6.0`, `firebase_auth ^6.3.0`, `cloud_firestore ^6.2.0`, `google_sign_in ^7.2.0`
Background Tasks	`workmanager ^0.9.0+3` — background sync & notification scheduling
Notifications	`flutter_local_notifications ^21.0.0` + `timezone ^0.11.0` + `flutter_timezone ^5.0.1`
File I/O	`path_provider ^2.1.5`, `path ^1.9.1`, `file_picker ^10.3.2`, `open_filex ^4.7.0`
Export	`excel ^4.0.6`, `csv ^6.0.0`, `pdf ^3.11.3`, `archive ^3.6.1`, `xml ^6.6.1`
Charts	`fl_chart ^1.1.1`
Routing	`go_router ^16.2.1`
UI Fonts	`google_fonts ^6.3.2`
Equality	`equatable ^2.0.7`
Internationalisation	`intl ^0.20.2`
Linting	`flutter_lints ^6.0.0`
Tests	`flutter_test` (SDK), `build_runner` code-gen validation
App version is `1.0.0+1`. The CI pipeline runs `flutter analyze && flutter test` — lint or type errors fail the pipeline.
All UI strings are plain English by default with no i18n layer unless explicitly added.
---
2. Strict Coding Rules & Guidelines
Every developer/AI must adhere to these coding, naming, and design rules.
2.1 Dart Typing & Safety
No dynamic usage: The `dynamic` type is forbidden unless absolutely required by a third-party API contract. If the type is unknown, use `Object?` and resolve via `is` type checks or explicit casting with null guards.
Explicit types everywhere: All class fields, function parameters, return types, and local variables must carry explicit type annotations. Never rely on inference alone where the type is non-obvious.
Null safety: The codebase is fully null-safe. Avoid the `!` (bang) operator. Prefer null-aware operators (`??`, `?.`, `?..`), early returns, or explicit null checks via `if (value != null)`.
Named parameters: All non-trivial constructors and functions must use named parameters with explicit `required` markers or documented defaults.
Immutability: Prefer `final` for all local variables and class fields that do not change after construction. Use `const` constructors wherever possible for widget trees to improve render performance.
Const constructors: Every `StatelessWidget`, data class, and configuration object should use `const` constructors where feasible. Pass `const` keyword at the call site where the widget tree is fully compile-time constant.
Enum style: Use Dart `enum` (not string constants) for all finite-state types. For enums with metadata, use enhanced enum syntax:
```dart
  enum RequestStatus { idle, loading, succeeded, failed }

  enum BrokerType {
    zerodha('Zerodha'),
    angelOne('Angel One'),
    motilalOswal('Motilal Oswal'),
    groww('Groww'),
    upstox('Upstox');

    const BrokerType(this.displayName);
    final String displayName;
  }
  ```
Equatable: All BLoC `State` and `Event` classes must extend `Equatable` and override `props`. Do not override `==` or `hashCode` manually.
Import ordering: Follow the Dart linting standard — `dart:` imports first, `package:` imports second, relative imports last. Always use relative imports within the same feature folder and package imports across feature boundaries.
2.2 Flutter & Widget Rules
StatelessWidget by default: Prefer `StatelessWidget`. Only reach for `StatefulWidget` when local, non-BLoC ephemeral state is needed (e.g., scroll controllers, animation controllers, focus nodes).
No business logic in widgets: Widgets must contain zero business logic. All data transformation, filtering, and formatting must happen in the BLoC, Cubit, or a dedicated helper function before reaching the widget.
BuildContext usage: Never store or capture `BuildContext` across async gaps. After an `await`, always check `if (!mounted) return` before using `context`.
Widget decomposition: Pages must be decomposed into focused child widgets. A single widget file must not exceed ~250 lines. Extract sub-components into separate files within the feature's `widgets/` subfolder.
Theme only — no hardcoded colors: All colors must come from `Theme.of(context).colorScheme` or the app's custom `AppTheme` extension. Never hardcode `Color(0xFF...)` values inside widget files.
TextStyle from theme: All `TextStyle` usages must use `Theme.of(context).textTheme.*` or `GoogleFonts.*` applied through the theme, not inline.
2.3 BLoC/Cubit Conventions
BLoC for event-driven flows: Use `BLoC` when the feature has multiple distinct user-triggered events with complex transition logic (e.g., form submission, multi-step wizards, background sync lifecycle).
Cubit for simple states: Use `Cubit` for straightforward toggle states, filter selections, and single-data-load patterns.
No UI code in BLoC/Cubit: BLoC/Cubit classes must never reference `BuildContext`, `Navigator`, or any Flutter widget. Navigation and UI effects are handled in the widget layer via `BlocListener`.
Closed streams: Always close BLoCs in the widget `dispose()` or let `BlocProvider` handle lifecycle. Never leave a BLoC open after its owning widget is removed from the tree.
Error state: Every BLoC/Cubit that performs async operations must expose a `failure` or `error` state variant containing a human-readable message string.
---
3. Project Structure
```
lib/
├── main.dart                          # Entry point — DI setup, Firebase init, WorkManager init
├── app/
│   ├── app.dart                       # Root MaterialApp.router with GoRouter + ThemeProvider
│   ├── router/
│   │   ├── app_router.dart            # All GoRouter routes and shell route definition
│   │   └── app_routes.dart            # Route path constants (never hardcode paths)
│   └── theme/
│       ├── app_theme.dart             # ThemeData light + dark, ColorScheme, TextTheme
│       ├── app_colors.dart            # Centralized color palette constants
│       └── app_text_styles.dart       # Named TextStyle references
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart         # App-wide magic values (timeouts, limits, keys)
│   │   ├── storage_keys.dart          # All FlutterSecureStorage / SharedPreferences keys
│   │   └── firestore_collections.dart # Firestore collection/document path constants
│   ├── database/
│   │   ├── app_database.dart          # Drift database definition (@DriftDatabase)
│   │   ├── app_database.g.dart        # Generated by build_runner (do not edit)
│   │   └── tables/                    # One file per Drift table
│   │       ├── credentials_table.dart
│   │       ├── expenses_table.dart
│   │       ├── expense_categories_table.dart
│   │       ├── banks_table.dart
│   │       ├── tasks_table.dart
│   │       ├── task_categories_table.dart
│   │       ├── investments_table.dart
│   │       ├── brokers_table.dart
│   │       └── ...
│   ├── di/
│   │   └── service_locator.dart       # GetIt or manual singleton registry
│   ├── errors/
│   │   ├── app_exception.dart         # Base exception class hierarchy
│   │   └── failure.dart               # Sealed failure types (DatabaseFailure, NetworkFailure, etc.)
│   ├── extensions/
│   │   ├── datetime_extensions.dart
│   │   ├── double_extensions.dart     # Indian number formatting (₹ system: lakh, crore)
│   │   └── string_extensions.dart
│   ├── services/
│   │   ├── encryption_service.dart    # cryptography wrapper for credential vault
│   │   ├── biometric_service.dart     # local_auth wrapper
│   │   ├── notification_service.dart  # flutter_local_notifications + timezone setup
│   │   ├── export_service.dart        # Excel / CSV / PDF generation orchestrator
│   │   └── sync/
│   │       ├── firebase_sync_service.dart  # Firestore read/write operations
│   │       └── sync_worker.dart            # WorkManager background task handler
│   ├── utils/
│   │   ├── date_utils.dart
│   │   ├── number_utils.dart          # Indian comma formatting, P&L calculations
│   │   └── file_utils.dart            # path_provider helpers, file open via open_filex
│   └── widgets/
│       ├── app_bottom_nav_bar.dart    # Shared bottom navigation shell
│       ├── app_drawer.dart            # Optional side drawer
│       ├── app_bar_widget.dart        # Consistent AppBar wrapper
│       ├── loading_indicator.dart
│       ├── error_widget.dart
│       ├── empty_state_widget.dart
│       └── confirmation_dialog.dart
│
├── features/
│   ├── credential/                    # Tab 1
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── credential_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── credential_model.dart
│   │   │   └── repositories/
│   │   │       └── credential_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── credential.dart
│   │   │   ├── repositories/
│   │   │   │   └── credential_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_credentials_usecase.dart
│   │   │       ├── save_credential_usecase.dart
│   │   │       └── delete_credential_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── credential_bloc.dart
│   │       │   ├── credential_event.dart
│   │       │   └── credential_state.dart
│   │       ├── pages/
│   │       │   ├── credential_list_page.dart
│   │       │   └── credential_detail_page.dart
│   │       └── widgets/
│   │           ├── credential_card.dart
│   │           └── credential_form.dart
│   │
│   ├── expense/                       # Tab 2
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── expense_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── expense_model.dart
│   │   │   │   ├── bank_model.dart
│   │   │   │   └── expense_category_model.dart
│   │   │   └── repositories/
│   │   │       └── expense_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── bloc/
│   │       ├── pages/
│   │       │   ├── expense_list_page.dart
│   │       │   ├── expense_add_page.dart
│   │       │   ├── bank_list_page.dart
│   │       │   ├── split_expense_page.dart
│   │       │   ├── lent_borrowed_page.dart
│   │       │   └── expense_analytics_page.dart
│   │       └── widgets/
│   │
│   ├── task/                          # Tab 3
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── bloc/
│   │       ├── pages/
│   │       │   ├── task_list_page.dart
│   │       │   ├── task_add_page.dart
│   │       │   └── task_analytics_page.dart
│   │       └── widgets/
│   │
│   ├── investment/                    # Tab 4
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── investment_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── investment_model.dart
│   │   │   │   ├── broker_model.dart
│   │   │   │   └── sell_entry_model.dart
│   │   │   └── repositories/
│   │   │       └── investment_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── bloc/
│   │       ├── pages/
│   │       │   ├── investment_list_page.dart
│   │       │   ├── investment_add_page.dart
│   │       │   ├── investment_detail_page.dart
│   │       │   ├── broker_list_page.dart
│   │       │   └── portfolio_analytics_page.dart
│   │       └── widgets/
│   │
│   └── settings/                     # Tab 5
│       ├── data/
│       ├── domain/
│       └── presentation/
│           ├── cubit/
│           │   ├── settings_cubit.dart
│           │   └── settings_state.dart
│           ├── pages/
│           │   ├── settings_page.dart
│           │   ├── theme_settings_page.dart
│           │   ├── notification_settings_page.dart
│           │   ├── export_settings_page.dart
│           │   └── cloud_sync_settings_page.dart
│           └── widgets/
│
└── l10n/                              # Reserved for future localisation artefacts
```
---
4. Feature Integration Steps
When adding a new feature or extending an existing one, follow this checklist in order.
4.1 Step-by-Step Integration
Database Table:
How: Add a `Table` class in `core/database/tables/<feature>_table.dart`. Register it in the `@DriftDatabase(tables: [...])` annotation in `app_database.dart`, then run `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate `.g.dart` files.
When: Every new persistent entity needs a Drift table. Never write raw SQL strings outside of Drift query definitions.
Domain Entity:
How: Create a plain Dart class (not a Drift companion) in `features/<feature>/domain/entities/<entity>.dart`. Extend `Equatable` and list all fields in `props`. This entity is the single contract between layers.
When: Every feature that stores or queries data must define its own domain entity, isolated from database models.
Repository Contract:
How: Declare an abstract class in `features/<feature>/domain/repositories/<feature>_repository.dart` with method signatures returning `Future<Either<Failure, T>>` or `Stream<Either<Failure, List<T>>>`.
When: Always define the interface before the implementation. The BLoC depends on the abstract repository, never on the concrete implementation.
Data Model & Datasource:
How: Create `<feature>_model.dart` in `data/models/`. This extends or wraps the Drift-generated companion type. Add a `fromDrift()` factory and a `toDriftCompanion()` method. Create `<feature>_local_datasource.dart` in `data/datasources/` that wraps Drift DAO calls and returns models.
When: The datasource handles all raw I/O. It must not contain business logic.
Repository Implementation:
How: Create `<feature>_repository_impl.dart` in `data/repositories/`. It implements the domain repository interface, calls the datasource, maps models to entities, and wraps results in `Either<Failure, T>`.
When: Create the impl after both the contract and datasource are done. Register it in the DI container.
Use Cases:
How: Create one file per use case in `domain/usecases/`. Each use case has a single `call()` method. Use cases compose repository calls and may enforce business rules.
When: Always use use cases as the entry point from the BLoC into the domain layer. Never call the repository directly from a BLoC.
BLoC / Cubit:
How: Create `<feature>_bloc.dart`, `<feature>_event.dart`, `<feature>_state.dart` under `presentation/bloc/`. All states and events must extend `Equatable`. Track async lifecycle with `RequestStatus` enum.
When: Create a BLoC for event-driven features and a Cubit for simpler unidirectional data flows.
Routes & Pages:
How: Add route path constants in `app/router/app_routes.dart`. Register `GoRoute` entries in `app/router/app_router.dart`. Create the page widget in `presentation/pages/`.
When: Every navigable screen must be registered in the central router. Never use `Navigator.push` directly from a widget; always use `context.go()` or `context.push()`.
Dependency Injection:
How: Register the datasource, repository implementation, use cases, and BLoC/Cubit in `core/di/service_locator.dart`.
When: All dependencies must be registered before `runApp()` is called in `main.dart`.
4.2 Reusability Guidelines
Shared widgets (used across more than one feature tab) belong in `core/widgets/`.
Pure utility functions (date formatting, number formatting, file path helpers) belong in `core/utils/`.
Cross-feature services (encryption, biometrics, notifications, export, sync) belong in `core/services/`.
Feature-specific widgets belong in `features/<feature>/presentation/widgets/`.
Keep widget files stateless and dumb: they receive data and callbacks as constructor parameters and do not access BLoC or services directly.
---
5. Layer Responsibilities
Layer	Belongs here	Does NOT belong here
`presentation/pages/`	BlocProvider setup, BlocListener for nav/snackbar, BlocBuilder for UI tree	Business rules, direct DB/network calls
`presentation/widgets/`	Stateless UI building blocks, receive typed props	BLoC access, use cases, services
`presentation/bloc/`	Event→State transitions, use case calls, error wrapping	BuildContext, Navigator, Widget APIs
`domain/usecases/`	Business rule orchestration, repository delegation	DB queries, HTTP, Flutter APIs
`domain/repositories/`	Abstract interface contracts only	Implementation, Drift, HTTP
`data/repositories/`	Interface implementation, model↔entity mapping, failure wrapping	Business logic, navigation
`data/datasources/`	Drift DAO calls, raw file I/O	Entity types, business logic
`data/models/`	Drift companion wrappers, `fromDrift()` / `toDriftCompanion()`	Domain entities, UI types
`core/database/`	Drift table definitions, DAOs, generated code	Feature logic, BLoC
`core/services/`	Encryption, biometrics, notifications, export, sync	Widget rendering
`core/utils/`	Pure functions — no side effects	Flutter imports, services
`core/constants/`	App-wide constants, storage keys, route paths, collection names	Logic, instantiation
`app/router/`	GoRouter config, shell route, redirect guards	UI widgets, business logic
`app/theme/`	ThemeData, ColorScheme, TextTheme, font setup	Feature-specific styles
---
6. Data Flow — The Layered Pattern
Every user action or data load flows through the same chain:
```
Page (BlocBuilder/BlocListener)
   │  dispatch Event / call method
   ▼
BLoC / Cubit
   │  call Use Case
   ▼
Use Case
   │  call Repository (abstract)
   ▼
Repository Implementation
   │  call Local Datasource
   ▼
Local Datasource (Drift DAO)
   │  read/write SQLite
   ▼
Drift Database (SQLite via sqlite3_flutter_libs)
   │
   └──▶ [optional] Firebase Sync Service
            │  Firestore encrypted document
            ▼
         Cloud Firestore
```
On the return path, `Drift` rows are mapped to `Model` → `Entity` → `BLoC State` → `Widget` rebuild.
6.1 Failure & Error Handling
All repository methods return `Either<Failure, T>` (using a minimal Either implementation or `fpdart` if added). The BLoC unwraps this and emits:
`fold(left: (f) => emit(ErrorState(f.message)), right: (data) => emit(SuccessState(data)))`
`Failure` is a sealed class:
```dart
sealed class Failure {
  final String message;
  const Failure(this.message);
}

final class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

final class EncryptionFailure extends Failure {
  const EncryptionFailure(super.message);
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

final class BiometricFailure extends Failure {
  const BiometricFailure(super.message);
}
```
6.2 Local-First Data Pattern
All reads and writes hit the local Drift database first. Cloud sync is asynchronous and optional. The app is fully functional offline. The sync service runs in the background via `WorkManager` and reconciles local changes with Firestore when connectivity is available.
---
7. State Management
7.1 BLoC Conventions
Every BLoC/Cubit that performs async I/O tracks a `RequestStatus` field:
```dart
enum RequestStatus { idle, loading, succeeded, failed }
```
State classes follow this pattern:
```dart
final class ExpenseState extends Equatable {
  final List<Expense> expenses;
  final RequestStatus status;
  final String? errorMessage;

  const ExpenseState({
    this.expenses = const [],
    this.status = RequestStatus.idle,
    this.errorMessage,
  });

  ExpenseState copyWith({
    List<Expense>? expenses,
    RequestStatus? status,
    String? errorMessage,
  }) => ExpenseState(
    expenses: expenses ?? this.expenses,
    status: status ?? this.status,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [expenses, status, errorMessage];
}
```
7.2 BLoC Slice Registry
Feature	BLoC/Cubit	Notes
`credential`	`CredentialBloc`	Unlocked only after biometric/key gate passes
`expense`	`ExpenseBloc`, `BankCubit`, `CategoryCubit`	Separate Cubits for bank and category lists
`task`	`TaskBloc`, `TaskCategoryCubit`	Checklist completion via individual events
`investment`	`InvestmentBloc`, `BrokerCubit`	Sells tracked as child records of a buy entry
`settings`	`SettingsCubit`	Persists to `FlutterSecureStorage` + local prefs
`cloud_sync`	`CloudSyncCubit`	Tracks sync status, last-synced timestamp, errors
`theme`	`ThemeCubit`	Light / dark / system; persisted to secure storage
7.3 BlocProvider Placement
App-wide BLoCs (theme, settings, cloud sync) are provided at the root in `app.dart`.
Feature BLoCs are provided at the route level using `BlocProvider` inside the page's `GoRoute.builder`, so they are automatically closed when the route is popped.
Never use `BlocProvider.value` unless you explicitly need to pass an existing BLoC down the tree across routes.
---
8. Authentication & Security
8.1 Credential Tab Gate
The Credential tab is guarded by a two-factor local gate:
Biometric authentication via `local_auth`. If the device has biometrics enrolled, the user must authenticate before the encrypted vault is unlocked.
Encryption key prompt on first open (or after key rotation). The key is stored securely in `FlutterSecureStorage` after being derived from user input via `cryptography`.
The BLoC manages the vault lock state. On app backgrounding (`AppLifecycleState.paused`), the vault re-locks automatically after `CREDENTIAL_LOCK_TIMEOUT_MS` (configurable in `AppConstants`).
8.2 Encryption Strategy
All credential records are encrypted at rest using AES-256-GCM via the `cryptography` package before being written to Drift.
The encryption key is stored in `FlutterSecureStorage` (backed by Android Keystore / iOS Secure Enclave).
The Drift `CredentialsTable` stores only ciphertext blobs and IVs. Plaintext never touches the SQLite file.
When synced to Firestore, documents are encrypted client-side before upload. The server never sees plaintext.
8.3 Firebase Auth
Google Sign-In (`google_sign_in`) is used for Firebase authentication when cloud sync is enabled.
Authentication state is observed via `FirebaseAuth.instance.authStateChanges()` stream.
The app functions fully without signing in — cloud sync is always opt-in.
---
9. Routing
The app uses `go_router` with a `ShellRoute` for the bottom navigation bar and nested `GoRoute` entries for each feature's sub-pages.
9.1 Route Constants (`app/router/app_routes.dart`)
All path strings are defined as `static const String` fields. Never hardcode a path string in a widget or BLoC.
Tab / Feature	Route Name → Path
Shell	`/`
`credential`	`credential → /credential`
`credential.detail`	`credentialDetail → /credential/:id`
`credential.add`	`credentialAdd → /credential/add`
`expense`	`expense → /expense`
`expense.add`	`expenseAdd → /expense/add`
`expense.analytics`	`expenseAnalytics → /expense/analytics`
`expense.banks`	`banks → /expense/banks`
`expense.split`	`splitExpense → /expense/split`
`expense.lentBorrowed`	`lentBorrowed → /expense/lent-borrowed`
`task`	`task → /task`
`task.add`	`taskAdd → /task/add`
`task.analytics`	`taskAnalytics → /task/analytics`
`investment`	`investment → /investment`
`investment.add`	`investmentAdd → /investment/add`
`investment.detail`	`investmentDetail → /investment/:id`
`investment.analytics`	`portfolioAnalytics → /investment/analytics`
`investment.brokers`	`brokers → /investment/brokers`
`settings`	`settings → /settings`
`settings.theme`	`themeSettings → /settings/theme`
`settings.notifications`	`notificationSettings → /settings/notifications`
`settings.export`	`exportSettings → /settings/export`
`settings.cloudSync`	`cloudSyncSettings → /settings/cloud-sync`
9.2 Navigation Rules
Use `context.go()` to replace the current route (tab switches).
Use `context.push()` for detail pages and forms that should be dismissible with the back button.
Use `context.pop()` to return from pushed routes, optionally with a result.
The `ShellRoute` widget host (`core/widgets/app_bottom_nav_bar.dart`) persists BLoC state across tab switches using `IndexedStack`.
---
10. Database (Drift)
10.1 Table Definitions
Each table is defined as a class extending `Table` in `core/database/tables/`. Column names use `camelCase` in Dart but are stored as `snake_case` in SQLite by Drift's default convention.
All tables must include:
`IntColumn get id => integer().autoIncrement()();` as primary key.
`DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();`
`DateTimeColumn get updatedAt => dateTime().nullable()();`
10.2 DAOs
Each feature's datasource accesses the database only through a dedicated Drift DAO (`@DriftAccessor`). DAOs are colocated with their table definitions. Raw SQL queries are only used when Drift's query builder cannot express the required join or aggregate.
10.3 Code Generation
After any change to a Drift table, entity, or DAO, regenerate code:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
The generated file `app_database.g.dart` must never be manually edited.
---
11. Cloud Sync & Backup
11.1 Architecture
Cloud sync is fully opt-in and non-blocking. The sync flow:
Local write completes to Drift → emits success state to UI immediately.
`CloudSyncService.enqueueSync()` marks the record as `pendingSync = true` in a local sync queue table.
`WorkManager` periodic task picks up pending records, encrypts them client-side, and writes to Firestore under `users/{uid}/dailyuse/{feature}/{docId}`.
On success, the sync queue entry is cleared and `lastSyncedAt` is updated in settings.
11.2 Conflict Resolution
Last-write-wins based on `updatedAt` timestamp. The `FirebaseSyncService` compares local `updatedAt` against the Firestore document `updatedAt` field before writing. If the remote document is newer, the local record is updated and the user is notified via a local notification.
11.3 Encryption in Transit and at Rest
All Firestore documents are encrypted client-side using AES-256-GCM before upload. The Firestore document schema stores only `ciphertext`, `iv`, and `checksum` fields. No plaintext data ever leaves the device unencrypted.
---
12. Notifications
All scheduling and display go through `core/services/notification_service.dart`, which wraps `flutter_local_notifications`.
Timezone-aware scheduling uses `flutter_timezone` to get the device's current IANA timezone and `timezone` package for offset calculations.
Task reminder notifications are scheduled when a task is created or updated with a due date.
Sync status notifications are triggered by the `WorkManager` background task.
All notification channels are registered in `NotificationService.initialize()`, which must be called in `main.dart` before `runApp()`.
---
13. Export
All export operations are orchestrated by `core/services/export_service.dart`.
Format	Package	Notes
Excel (`.xlsx`)	`excel`	Multi-sheet export, Indian number formatting applied
CSV	`csv`	Comma-separated, UTF-8, BOM prefix for Excel compatibility
PDF	`pdf`	`pw.Document` with custom page layouts; no hardcoded colors
ZIP archive	`archive`	Bundles all formats into one downloadable archive
Export files are written to the user-configured export folder via `path_provider`. After writing, `open_filex` opens the file in the OS file manager or a compatible viewer. The export folder path defaults to `getExternalStorageDirectory()` on Android and `getApplicationDocumentsDirectory()` on iOS.
---
14. Global Theme (Light / Dark Mode)
`ThemeCubit` (in `features/settings/presentation/cubit/`) manages the theme mode: `ThemeMode.light`, `ThemeMode.dark`, or `ThemeMode.system`.
The root `MaterialApp.router` in `app/app.dart` reads `themeMode` from `BlocBuilder<ThemeCubit, ThemeState>`.
`AppTheme.lightTheme` and `AppTheme.darkTheme` in `app/theme/app_theme.dart` are the single source of truth for all `ThemeData`.
All feature widgets use `Theme.of(context).colorScheme.*` and `Theme.of(context).textTheme.*`. Hardcoded `Color` literals inside widget files are a linting violation.
The selected theme mode is persisted to `FlutterSecureStorage` via `StorageKeys.themeMode`.
---
15. Investment Module — Domain Rules
The Investment tab has specific business logic rules that must be enforced at the use case layer, not in the widget or BLoC.
15.1 Buy Entry
`buyPrice`, `quantity`, and `buyDate` are required.
`broker` is required and must be a valid `BrokerType` enum value.
`instrumentType` distinguishes `stock` from `mutualFund`.
Indian number formatting (lakh/crore system) is applied to all monetary display values via `double_extensions.dart`.
No currency symbol (`₹`) is stored in the database. Formatting is a display-only concern applied in the widget layer.
15.2 Sell Entry
Each sell is a child record linked to a buy entry.
Partial sells are supported: `sellQuantity <= remainingQuantity`.
P&L, PAT, and XIRR are computed values — never stored. They are derived on read inside the use case or a pure utility function.
Tax computation applies the broker's `TaxProfile` (STCG/LTCG rates, STT, brokerage) sourced from `BrokerType`'s associated tax constants.
15.3 Portfolio Analytics
Displayed metrics: total invested, current value (if live prices are added), realised P&L, unrealised P&L, XIRR.
All analytics are computed client-side from the local database.
`fl_chart` is used for visualisations: pie chart for sector allocation, line chart for portfolio value over time.
---
16. Android & iOS Configuration Notes
16.1 Android
`minSdkVersion` must be set to support all dependencies. Check `local_auth` (requires API 23+) and `flutter_secure_storage` (requires API 18+). Set `minSdkVersion 23` in `android/app/build.gradle`.
`flutter_local_notifications` requires the `SCHEDULE_EXACT_ALARM` permission on Android 12+. Declare it in `AndroidManifest.xml`.
`WorkManager` requires the `RECEIVE_BOOT_COMPLETED` permission if background sync should resume after reboot.
Firebase configuration goes in `google-services.json` at `android/app/google-services.json`.
16.2 iOS (Future)
`local_auth` requires `NSFaceIDUsageDescription` in `Info.plist`.
`flutter_local_notifications` requires notification permission request at runtime via `requestPermissions()`.
Firebase configuration goes in `GoogleService-Info.plist` at `ios/Runner/`.
`flutter_secure_storage` on iOS uses the Keychain. No additional config is needed beyond adding the entitlements file.
The Podfile's platform must be set to `platform :ios, '13.0'` or higher to support all dependencies.
Background sync via `WorkManager` maps to iOS `BGTaskScheduler` on iOS 13+.
---
18. Migrating the Current Project Structure
This section describes how and where to move or restructure existing code to match the target architecture defined in this reference. It does not describe what to build — only where existing files belong and how the directory layout upgrades.
Each subsection maps a category of existing code to its new home.
---
18.1 Entry Point & App Root
Current location: `lib/main.dart` likely contains `runApp()`, possibly inline `MaterialApp`, and scattered initialisation calls.
How to upgrade:
Keep `lib/main.dart` as the entry point but limit it to: `WidgetsFlutterBinding.ensureInitialized()`, service initialisation calls (`NotificationService.initialize()`, `WorkManager.initialize()`, `Firebase.initializeApp()`), DI registration (`ServiceLocator.setup()`), and the final `runApp(const App())`.
Extract the `MaterialApp` (or `MaterialApp.router`) and all `BlocProvider` wrappers into `lib/app/app.dart` as the `App` widget.
The `app.dart` file is the only place that composes root-level `MultiBlocProvider`, `GoRouter`, and `ThemeCubit`.
---
18.2 Routing
Current location: Navigation calls are likely scattered across widget files using `Navigator.push()` / `MaterialPageRoute`, or a single flat list of routes in `MaterialApp(routes: {...})`.
How to upgrade:
Create `lib/app/router/app_routes.dart`. Move every hardcoded path string into `static const String` fields on an `AppRoutes` class.
Create `lib/app/router/app_router.dart`. Move all route definitions into a `GoRouter` instance with a `ShellRoute` for the bottom nav shell and nested `GoRoute` entries per feature. The `GoRouter` instance is constructed once and passed to `MaterialApp.router(routerConfig: ...)` in `app.dart`.
In every widget that currently calls `Navigator.push(...)`, replace with `context.push(AppRoutes.routeName)`. For tab switches, replace with `context.go(AppRoutes.routeName)`.
Delete all `routes:` or `onGenerateRoute:` entries from `MaterialApp` after migration.
---
18.3 Theme
Current location: `ThemeData` is likely defined inline inside `MaterialApp` in `main.dart` or `app.dart`, possibly with hardcoded `Color(0xFF...)` values.
How to upgrade:
Create `lib/app/theme/app_colors.dart` and move all colour constants there as `static const Color` fields on an `AppColors` class.
Create `lib/app/theme/app_theme.dart` with two `static ThemeData` getters: `lightTheme` and `darkTheme`. Move all `ThemeData(...)` construction here. Replace every `Color(0xFF...)` literal in the theme with a reference to `AppColors.*`.
Create `lib/app/theme/app_text_styles.dart` for any named `TextStyle` constants.
In `app.dart`, replace the inline `ThemeData` arguments with `AppTheme.lightTheme` and `AppTheme.darkTheme`.
Create `lib/features/settings/presentation/cubit/theme_cubit.dart` and `theme_state.dart`. Wrap `MaterialApp.router` in `BlocBuilder<ThemeCubit, ThemeState>` inside `app.dart` so `themeMode` is reactive.
Every `Color(0xFF...)` or raw `Colors.*` reference inside widget files must be replaced with `Theme.of(context).colorScheme.*`.
---
18.4 Constants & Magic Values
Current location: String literals, integer limits, timeout values, `FlutterSecureStorage` key strings, and Firestore collection paths are likely scattered inline across service files, widget files, and BLoC files.
How to upgrade:
Create `lib/core/constants/app_constants.dart`. Move all numeric limits, duration values, and timeout constants here as `static const` fields.
Create `lib/core/constants/storage_keys.dart`. Move every `FlutterSecureStorage` key string and `SharedPreferences` key string here.
Create `lib/core/constants/firestore_collections.dart`. Move every Firestore collection name string and document path template here.
After creating each constants file, do a project-wide find for the raw string or value and replace with the constant reference.
---
18.5 Database Layer
Current location: SQLite access is either via raw `sqflite` calls scattered across service or repository files, or Drift tables defined in a single monolithic file.
How to upgrade:
Create `lib/core/database/tables/` and split each table definition into its own file (e.g. `expenses_table.dart`, `tasks_table.dart`). One `Table` class per file.
The `@DriftDatabase(tables: [...])` annotation and the `AppDatabase` class live in `lib/core/database/app_database.dart`. Import all table files here.
Run `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate `app_database.g.dart` after any structural move.
Each feature's database access moves into a dedicated Drift DAO annotated with `@DriftAccessor`. Place the DAO class inside the same file as its table or in `lib/core/database/tables/<feature>_table.dart`. Register it under `daos:` in `@DriftDatabase`.
Remove all `sqflite` direct calls. The `AppDatabase` singleton is the only entry point to SQLite in the entire project.
---
18.6 Feature Code
Current location: Feature logic (e.g. expense tracking, task management) likely lives in a flat mix of `screens/`, `models/`, `services/`, or `providers/` folders at the `lib/` root, with business logic inside widget `build()` methods or `setState` callbacks.
How to upgrade:
For each feature tab (`credential`, `expense`, `task`, `investment`, `settings`):
Create the feature folder at `lib/features/<feature>/` with the three sub-layers: `data/`, `domain/`, `presentation/`.
Domain entity: Extract the plain data class from any existing model file. Strip all Drift/JSON annotations from it. Place the clean entity at `lib/features/<feature>/domain/entities/<entity>.dart`. It extends `Equatable`.
Repository interface: Create `lib/features/<feature>/domain/repositories/<feature>_repository.dart` as an abstract class. Move all method signatures (currently in a service or provider) into this abstract class, changing return types to `Future<Either<Failure, T>>`.
Data model: Keep the Drift-annotated or JSON-annotated version of the class in `lib/features/<feature>/data/models/<feature>_model.dart`. Add `fromDrift()` and `toDriftCompanion()` (or `fromJson()`/`toJson()`) as the only serialisation methods.
Datasource: Move all raw database calls (currently in a service or repository) into `lib/features/<feature>/data/datasources/<feature>_local_datasource.dart`. This class receives the Drift DAO as a constructor argument.
Repository implementation: Create `lib/features/<feature>/data/repositories/<feature>_repository_impl.dart`. It receives the datasource, calls its methods, maps models to domain entities, and wraps results in `Either<Failure, T>`.
Use cases: For every named operation (get list, add item, delete item, etc.), create one file in `lib/features/<feature>/domain/usecases/`. Move the corresponding logic out of the existing service or BLoC.
BLoC / Cubit: Move the existing `ChangeNotifier`, `Provider`, or raw `setState` logic into `lib/features/<feature>/presentation/bloc/` as a `BLoC` or `Cubit`. Replace direct datasource/service calls with use case calls.
Pages: Move screen widgets from `screens/` or `pages/` into `lib/features/<feature>/presentation/pages/`. The page widget is responsible only for providing a `BlocProvider`, listening with `BlocListener`, and rendering with `BlocBuilder`.
Widgets: Extract any inline sub-widget (currently defined inside a `build()` method or as a private function) into its own file under `lib/features/<feature>/presentation/widgets/`.
---
18.7 Shared / Core Widgets
Current location: Reusable widgets (loading spinners, empty states, error banners, the bottom nav bar) likely live either in `lib/widgets/`, `lib/common/`, or scattered inside feature screen files.
How to upgrade:
Create `lib/core/widgets/` if it does not exist.
Move every widget used by more than one feature into `lib/core/widgets/`. One widget class per file, using the `snake_case.dart` naming convention.
Delete the old `lib/widgets/` or `lib/common/` folder after all imports are updated.
Update import paths in all files that referenced the old location.
---
18.8 Services
Current location: Encryption, biometrics, notifications, export, and sync logic likely live in `lib/services/` as a flat collection of files, sometimes mixed with repository logic.
How to upgrade:
Create `lib/core/services/` and move each cross-feature service file there, renaming to match the convention: `encryption_service.dart`, `biometric_service.dart`, `notification_service.dart`, `export_service.dart`.
Move sync-specific files into `lib/core/services/sync/`: `firebase_sync_service.dart` and `sync_worker.dart` (the WorkManager callback handler).
Services must have no dependency on BLoC or `BuildContext`. If a service currently calls `Navigator` or `showDialog`, extract that call site into a widget-layer `BlocListener` instead.
Update all import paths project-wide after the move.
---
18.9 Utilities
Current location: Helper functions (date formatting, number formatting, file path builders) likely live inline inside widget `build()` methods, inside BLoC `mapEventToState`, or in an ad-hoc `utils.dart` file.
How to upgrade:
Create `lib/core/utils/` with one file per concern: `date_utils.dart`, `number_utils.dart`, `file_utils.dart`.
Move every pure function (no Flutter imports, no side effects) into these files.
For formatting helpers that are called on instances of `DateTime`, `double`, or `String`, convert them to Dart extension methods in `lib/core/extensions/` (`datetime_extensions.dart`, `double_extensions.dart`, `string_extensions.dart`).
After moving, do a project-wide search for the function name and update call sites to use the new path or the extension method syntax.
---
18.10 Dependency Injection
Current location: Singletons are created with `get_it`, manual `static` instances, or passed down the widget tree via `InheritedWidget` / `Provider`.
How to upgrade:
Create `lib/core/di/service_locator.dart` with a single `setup()` async function.
Register dependencies in this order: database → datasources → repository implementations → use cases → BLoC/Cubit factories.
Call `ServiceLocator.setup()` once in `main.dart` before `runApp()`.
Replace all inline `MyService()` instantiations and `static instance` patterns with `ServiceLocator.get<MyService>()` (or the equivalent `get_it` call).
Feature BLoCs registered as factories (not singletons) so each route gets a fresh instance and the BLoC is garbage-collected when the route is popped.
---
18.11 Error Types
Current location: Errors are likely surfaced as raw `Exception` strings, `try/catch` with `print()`, or bare `.toString()` calls shown in snackbars.
How to upgrade:
Create `lib/core/errors/failure.dart` with the sealed `Failure` class hierarchy (see §6.1).
Create `lib/core/errors/app_exception.dart` for any thrown exception types that need to be caught and converted to a `Failure` at the repository layer.
In every datasource `try/catch` block, convert the caught exception into a `Failure` subtype before returning it via `Left(failure)`.
Remove all `print()` calls. Replace with `debugPrint()` in dev or structured logging.
---
18.12 Tests
Current location: Tests (if any) live in `test/` with no consistent folder mirroring.
How to upgrade:
Mirror the `lib/` structure under `test/`. For example: `lib/features/expense/domain/usecases/get_expenses_usecase.dart` → `test/features/expense/domain/usecases/get_expenses_usecase_test.dart`.
Shared widget tests go in `test/core/widgets/`.
BLoC tests go in `test/features/<feature>/presentation/bloc/`.
Use case unit tests go in `test/features/<feature>/domain/usecases/`.
Datasource tests (with a Drift in-memory database) go in `test/features/<feature>/data/datasources/`.
---
18.13 Migration Order
Migrate in this sequence to avoid breaking the running app at any intermediate step:
`app/theme/` — isolated, no dependencies on other code.
`core/constants/` — pure constants, update import sites last.
`core/errors/` — sealed failure types, needed by repositories.
`core/database/` — split tables and add DAOs; regenerate `.g.dart`.
`core/services/` — move service files, update imports.
`core/utils/` and `core/extensions/` — move pure helpers.
`core/widgets/` — move shared widgets, update imports.
`core/di/` — create `service_locator.dart`, wire all registrations.
Feature layers one tab at a time: `domain/` → `data/` → `presentation/`.
`app/router/` — migrate routing last, after all pages are in place.
`main.dart` — trim to the minimal bootstrap form once all the above are done.
---
17. Coding Conventions Reference
Pattern	Rule
Async in BLoC	Always `await` use case calls inside `emit`-guarded try/catch. Emit loading before the call, success/failure after.
`mounted` check	After every `await` inside a `State`, check `if (!mounted) return` before accessing `context`.
`const` widgets	Use `const` constructor at call site whenever the widget subtree is compile-time constant.
No `BuildContext` in BLoC	Navigation and snackbars are triggered via `BlocListener` in the page, never inside the BLoC.
Import aliases	Never use relative `../` imports across feature boundaries. Use package-relative imports: `package:finance_analytics_app/...`
File naming	All files use `snake_case.dart`. Classes use `PascalCase`. Constants use `lowerCamelCase` for local, `SCREAMING_SNAKE` for top-level globals.
Widget tests	Every shared widget in `core/widgets/` must have a corresponding widget test in `test/core/widgets/`.
No `print()`	Use `debugPrint()` in debug builds only. All `print()` calls are a lint violation.
`copyWith`	Every state class must implement `copyWith()` for clean partial state updates.
Drift migration	Every schema change requires a `MigrationStrategy` entry. Never delete or rename columns without a migration.
