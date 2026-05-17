import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/app_preferences.dart';
import '../constants/legal_constants.dart';
import '../router/app_router.dart';
import '../services/app_settings_repository.dart';
import '../../features/credentials/presentation/pages/credential_module_page.dart';
import '../../features/expense/presentation/pages/expense_module_page.dart';
import '../../features/settings/presentation/pages/settings_module_page.dart';
import '../../features/settings/presentation/widgets/privacy_policy_consent_dialog.dart';
import '../../features/tasks/presentation/pages/tasks_module_page.dart';
import '../blocs/module_navigation_bloc.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final PageController _pageController;
  bool _dialogCheckStarted = false;
  bool _dialogVisible = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _moduleIndex(AppModule.expense),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dialogCheckStarted) {
      return;
    }
    _dialogCheckStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _showPrivacyDialogIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return BlocConsumer<ModuleNavigationBloc, ModuleNavigationState>(
      listenWhen: (previous, current) => previous.module != current.module,
      listener: (context, state) {
        final selectedIndex = _moduleIndex(state.module);
        if (!_pageController.hasClients) {
          return;
        }
        final currentPage = _pageController.page?.round();
        if (currentPage == selectedIndex) {
          return;
        }
        _pageController.animateToPage(
          selectedIndex,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      },
      builder: (context, state) {
        final selectedIndex = _moduleIndex(state.module);

        void onDestinationSelected(int index) {
          context.read<ModuleNavigationBloc>().add(
            ModuleSelected(_moduleForIndex(index)),
          );
        }

        final content = PageView(
          controller: _pageController,
          onPageChanged: onDestinationSelected,
          children: const <Widget>[
            CredentialModulePage(),
            ExpenseModulePage(),
            TasksModulePage(),
            SettingsModulePage(),
          ],
        );

        if (width >= 1100) {
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: NavigationRail(
                      selectedIndex: selectedIndex,
                      onDestinationSelected: onDestinationSelected,
                      extended: width >= 1320,
                      destinations: const <NavigationRailDestination>[
                        NavigationRailDestination(
                          icon: Icon(Icons.vpn_key_outlined),
                          selectedIcon: Icon(Icons.vpn_key_rounded),
                          label: Text('Credential'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.account_balance_wallet_outlined),
                          selectedIcon: Icon(
                            Icons.account_balance_wallet_rounded,
                          ),
                          label: Text('Expense'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.task_alt_outlined),
                          selectedIcon: Icon(Icons.task_alt_rounded),
                          label: Text('Task'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.settings_outlined),
                          selectedIcon: Icon(Icons.settings_rounded),
                          label: Text('Settings'),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1600),
                        child: content,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: content,
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.vpn_key_outlined),
                selectedIcon: Icon(Icons.vpn_key_rounded),
                label: 'Credential',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Expense',
              ),
              NavigationDestination(
                icon: Icon(Icons.task_alt_outlined),
                selectedIcon: Icon(Icons.task_alt_rounded),
                label: 'Task',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }

  int _moduleIndex(AppModule module) {
    return switch (module) {
      AppModule.credential => 0,
      AppModule.expense => 1,
      AppModule.tasks => 2,
      AppModule.settings => 3,
    };
  }

  AppModule _moduleForIndex(int index) {
    return switch (index) {
      0 => AppModule.credential,
      1 => AppModule.expense,
      2 => AppModule.tasks,
      _ => AppModule.settings,
    };
  }

  Future<void> _showPrivacyDialogIfNeeded() async {
    if (!mounted || _dialogVisible) {
      return;
    }

    final settingsRepository = context.read<AppSettingsRepository>();
    final settings = await settingsRepository.getSettings();
    if (!mounted ||
        settings.acceptedPrivacyPolicyVersion ==
            LegalConstants.privacyPolicyVersion) {
      return;
    }

    _dialogVisible = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PrivacyPolicyConsentDialog(
          lastUpdatedLabel: LegalConstants.privacyPolicyLastUpdatedLabel,
          onViewFullPolicy: () {
            Navigator.of(dialogContext).pushNamed(AppRoutes.privacyPolicy);
          },
          onAccept: () async {
            await settingsRepository.acceptPrivacyPolicy(
              LegalConstants.privacyPolicyVersion,
            );
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }
          },
        );
      },
    );
    _dialogVisible = false;
  }
}
