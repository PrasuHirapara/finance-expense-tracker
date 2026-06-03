import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/credentials/presentation/pages/credential_detail_page.dart';
import '../../features/credentials/presentation/pages/credential_editor_page.dart';
import '../../features/expense/data/repositories/expense_repository.dart';
import '../../features/expense/domain/models/expense_models.dart';
import '../../features/expense/presentation/blocs/expense_analytics/expense_analytics_bloc.dart';
import '../../features/expense/presentation/blocs/expense_form/expense_form_bloc.dart';
import '../../features/expense/presentation/pages/expense_analytics_page.dart';
import '../../features/expense/presentation/pages/expense_entry_detail_page.dart';
import '../../features/expense/presentation/pages/expense_entry_page.dart';
import '../../features/expense/presentation/pages/expense_entries_page.dart';
import '../../features/expense/presentation/pages/expense_settings_page.dart';
import '../../features/settings/presentation/pages/privacy_policy_page.dart';
import '../../features/settings/presentation/pages/settings_info_pages.dart';
import '../../features/settings/presentation/pages/terms_conditions_page.dart';
import '../../features/tasks/data/repositories/task_repository.dart';
import '../../features/tasks/domain/models/task_models.dart';
import '../../features/tasks/presentation/blocs/task_analytics/task_analytics_bloc.dart';
import '../../features/tasks/presentation/blocs/task_editor/task_editor_bloc.dart';
import '../../features/tasks/presentation/pages/task_analytics_page.dart';
import '../../features/tasks/presentation/pages/task_editor_page.dart';
import '../../features/tasks/presentation/pages/task_settings_page.dart';
import '../../features/investment/data/repositories/investment_repository.dart';
import '../../features/investment/domain/models/investment_models.dart';
import '../../features/investment/presentation/blocs/investment_form/investment_form_bloc.dart';
import '../../features/investment/presentation/pages/investment_entry_form_page.dart';
import '../../features/investment/presentation/pages/sell_entry_form_page.dart';
import '../../features/investment/presentation/pages/investment_entry_detail_page.dart';
import '../../features/investment/presentation/pages/investment_analytics_page.dart';
import '../../features/investment/presentation/pages/investment_settings_page.dart';
import '../../features/expense/presentation/pages/expense_import_preview_page.dart';
import '../../features/credentials/presentation/pages/credential_import_preview_page.dart';
import '../../features/investment/presentation/pages/investment_import_preview_page.dart';
import '../../core/services/module_data_import_service.dart';
import '../../core/services/app_settings_repository.dart';

class AppRoutes {
  AppRoutes._();

  static const String expenseAdd = '/expense/add';
  static const String expenseAnalytics = '/expense/analytics';
  static const String expenseDetail = '/expense/detail';
  static const String expenseEntries = '/expense/entries';
  static const String expenseSettings = '/expense/settings';
  static const String credentialEditor = '/credential/editor';
  static const String credentialDetail = '/credential/detail';
  static const String taskAnalytics = '/tasks/analytics';
  static const String taskEditor = '/tasks/editor';
  static const String taskSettings = '/tasks/settings';
  static const String investmentAdd = '/investment/add';
  static const String investmentSellAdd = '/investment/sell/add';
  static const String investmentDetail = '/investment/detail';
  static const String investmentAnalytics = '/investment/analytics';
  static const String investmentSettings = '/investment/settings';
  static const String expenseImportPreview = '/expense/import/preview';
  static const String credentialImportPreview = '/credential/import/preview';
  static const String investmentImportPreview = '/investment/import/preview';
  static const String userSettingsInfo = '/settings/user-settings';
  static const String appSettingsInfo = '/settings/app-settings';
  static const String backupSettingsInfo = '/settings/backup-settings';
  static const String privacyPolicy = '/settings/privacy-policy';
  static const String termsAndConditions = '/settings/terms-and-conditions';
}

class TaskEditorArgs {
  const TaskEditorArgs({required this.selectedDate, this.task});

  final DateTime selectedDate;
  final TaskItem? task;
}

class ExpenseEditorArgs {
  const ExpenseEditorArgs({this.entry});

  final ExpenseRecord? entry;
}

class ExpenseDetailArgs {
  const ExpenseDetailArgs({required this.entryId});

  final int entryId;
}

class ExpenseEntriesArgs {
  const ExpenseEntriesArgs({this.initialDate, this.title});

  final DateTime? initialDate;
  final String? title;
}

class InvestmentEditorArgs {
  const InvestmentEditorArgs({this.entry});
  final InvestmentEntry? entry;
}

class SellEditorArgs {
  const SellEditorArgs({
    required this.buyEntryId,
    required this.symbol,
    required this.remainingUnsoldQty,
  });
  final int buyEntryId;
  final String symbol;
  final double remainingUnsoldQty;
}

class InvestmentDetailArgs {
  const InvestmentDetailArgs({required this.symbol});
  final String symbol;
}

class InvestmentImportPreviewArgs {
  const InvestmentImportPreviewArgs({required this.previewData});
  final InvestmentImportPreviewData previewData;
}

class ExpenseImportPreviewArgs {
  const ExpenseImportPreviewArgs({required this.previewData});
  final ExpenseImportPreviewData previewData;
}

class CredentialImportPreviewArgs {
  const CredentialImportPreviewArgs({
    required this.previewData,
    required this.encryptionKey,
  });
  final CredentialImportPreviewData previewData;
  final String encryptionKey;
}

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.credentialEditor:
        final args = settings.arguments as CredentialEditorArgs?;
        return MaterialPageRoute<void>(
          builder: (context) =>
              CredentialEditorPage(args: args ?? const CredentialEditorArgs()),
        );
      case AppRoutes.credentialDetail:
        final args = settings.arguments as CredentialDetailArgs;
        return MaterialPageRoute<bool>(
          builder: (context) => CredentialDetailPage(args: args),
        );
      case AppRoutes.expenseAdd:
        final args = settings.arguments as ExpenseEditorArgs?;
        return MaterialPageRoute<void>(
          builder: (context) => BlocProvider(
            create: (context) =>
                ExpenseFormBloc(context.read<ExpenseRepository>())
                  ..add(ExpenseFormInitialized(existingExpense: args?.entry)),
            child: const ExpenseEntryPage(),
          ),
        );
      case AppRoutes.expenseAnalytics:
        return MaterialPageRoute<void>(
          builder: (context) => BlocProvider(
            create: (context) =>
                ExpenseAnalyticsBloc(context.read<ExpenseRepository>())
                  ..add(const ExpenseAnalyticsRequested()),
            child: const ExpenseAnalyticsPage(),
          ),
        );
      case AppRoutes.expenseDetail:
        final args = settings.arguments as ExpenseDetailArgs;
        return MaterialPageRoute<void>(
          builder: (context) => ExpenseEntryDetailPage(args: args),
        );
      case AppRoutes.expenseEntries:
        final args = settings.arguments as ExpenseEntriesArgs?;
        return MaterialPageRoute<void>(
          builder: (context) => ExpenseEntriesPage(
            initialDate: args?.initialDate,
            title: args?.title,
          ),
        );
      case AppRoutes.expenseSettings:
        return MaterialPageRoute<void>(
          builder: (context) => const ExpenseSettingsPage(),
        );
      case AppRoutes.taskAnalytics:
        return MaterialPageRoute<void>(
          builder: (context) => BlocProvider(
            create: (context) =>
                TaskAnalyticsBloc(context.read<TaskRepository>())
                  ..add(const TaskAnalyticsRequested()),
            child: const TaskAnalyticsPage(),
          ),
        );
      case AppRoutes.taskEditor:
        final args = settings.arguments as TaskEditorArgs;
        return MaterialPageRoute<void>(
          builder: (context) => BlocProvider(
            create: (context) =>
                TaskEditorBloc(context.read<TaskRepository>())..add(
                  TaskEditorInitialized(
                    selectedDate: args.selectedDate,
                    existingTask: args.task,
                  ),
                ),
            child: const TaskEditorPage(),
          ),
        );
      case AppRoutes.taskSettings:
        return MaterialPageRoute<void>(
          builder: (context) => const TaskSettingsPage(),
        );
      case AppRoutes.investmentAdd:
        final args = settings.arguments as InvestmentEditorArgs?;
        return MaterialPageRoute<void>(
          builder: (context) => BlocProvider(
            create: (context) =>
                InvestmentFormBloc(
                  context.read<InvestmentRepository>(),
                  context.read<AppSettingsRepository>(),
                )..add(InvestmentFormInit(existingEntry: args?.entry)),
            child: const InvestmentEntryFormPage(),
          ),
        );
      case AppRoutes.investmentSellAdd:
        final args = settings.arguments as SellEditorArgs;
        return MaterialPageRoute<void>(
          builder: (context) => BlocProvider(
            create: (context) =>
                InvestmentFormBloc(
                  context.read<InvestmentRepository>(),
                  context.read<AppSettingsRepository>(),
                )..add(InvestmentFormSellInit(
                    buyEntryId: args.buyEntryId,
                    symbol: args.symbol,
                    remainingUnsoldQty: args.remainingUnsoldQty,
                  )),
            child: const SellEntryFormPage(),
          ),
        );
      case AppRoutes.investmentDetail:
        final args = settings.arguments as InvestmentDetailArgs;
        return MaterialPageRoute<void>(
          builder: (context) => InvestmentEntryDetailPage(args: args),
        );
      case AppRoutes.investmentAnalytics:
        return MaterialPageRoute<void>(
          builder: (context) => const InvestmentAnalyticsPage(),
        );
      case AppRoutes.investmentSettings:
        return MaterialPageRoute<void>(
          builder: (context) => const InvestmentSettingsPage(),
        );
      case AppRoutes.expenseImportPreview:
        final args = settings.arguments as ExpenseImportPreviewArgs;
        return MaterialPageRoute<void>(
          builder: (context) => ExpenseImportPreviewPage(args: args),
        );
      case AppRoutes.credentialImportPreview:
        final args = settings.arguments as CredentialImportPreviewArgs;
        return MaterialPageRoute<void>(
          builder: (context) => CredentialImportPreviewPage(args: args),
        );
      case AppRoutes.investmentImportPreview:
        final args = settings.arguments as InvestmentImportPreviewArgs;
        return MaterialPageRoute<void>(
          builder: (context) => InvestmentImportPreviewPage(args: args),
        );
      case AppRoutes.userSettingsInfo:
        return MaterialPageRoute<void>(
          builder: (context) => const UserSettingsInfoPage(),
        );
      case AppRoutes.appSettingsInfo:
        return MaterialPageRoute<void>(
          builder: (context) => const AppSettingsInfoPage(),
        );
      case AppRoutes.backupSettingsInfo:
        return MaterialPageRoute<void>(
          builder: (context) => const BackupSettingsInfoPage(),
        );
      case AppRoutes.privacyPolicy:
        return MaterialPageRoute<void>(
          builder: (context) => const PrivacyPolicyPage(),
        );
      case AppRoutes.termsAndConditions:
        return MaterialPageRoute<void>(
          builder: (context) => const TermsConditionsPage(),
        );
      default:
        return MaterialPageRoute<void>(
          builder: (context) => const SizedBox.shrink(),
        );
    }
  }
}
