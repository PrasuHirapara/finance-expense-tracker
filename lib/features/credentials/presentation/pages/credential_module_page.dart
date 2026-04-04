import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/blocs/module_navigation_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/app_preferences.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../data/services/credential_service.dart';
import '../../domain/models/credential_models.dart';
import '../widgets/credential_auth_dialog.dart';
import '../widgets/credential_key_setup_dialog.dart';
import 'credential_detail_page.dart';
import 'credential_settings_page.dart';

class CredentialModulePage extends StatefulWidget {
  const CredentialModulePage({super.key});

  @override
  State<CredentialModulePage> createState() => _CredentialModulePageState();
}

class _CredentialModulePageState extends State<CredentialModulePage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isConfigured = false;
  bool _checkingConfiguration = true;
  bool _hasPromptedOnFirstOpen = false;
  bool _isCheckingConfiguration = false;
  bool _isLoadingInsights = false;
  CredentialSecurityReport? _securityReport;
  _CredentialInsightFilter? _selectedInsightFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final module = context.read<ModuleNavigationBloc>().state.module;
      if (module == AppModule.credential) {
        _handleCredentialTabOpened();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<ModuleNavigationBloc, ModuleNavigationState>(
      listenWhen: (previous, current) => previous.module != current.module,
      listener: (context, state) {
        if (state.module == AppModule.credential) {
          _handleCredentialTabOpened();
        }
      },
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Credential',
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Credential settings',
                  onPressed: _openCredentialSettings,
                  icon: const Icon(Icons.settings_outlined),
                ),
                IconButton(
                  tooltip: 'Add credential',
                  onPressed: !_isConfigured
                      ? null
                      : () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.credentialEditor),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_checkingConfiguration)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (!_isConfigured)
              AppPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Encryption Key Required',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set your credential encryption key to start storing secure entries.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _promptForFirstTimeSetup,
                      icon: const Icon(Icons.key_rounded),
                      label: const Text('Set Encryption Key'),
                    ),
                  ],
                ),
              )
            else ...<Widget>[
              _CredentialInsightsPanel(
                report: _securityReport,
                isLoading: _isLoadingInsights,
                onUnlock: _unlockInsights,
                onClose: _closeInsights,
                selectedFilter: _selectedInsightFilter,
                onFilterSelected: _handleInsightFilterSelected,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search by title',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 18),
              StreamBuilder<List<CredentialRecord>>(
                stream: context.read<CredentialService>().watchCredentials(
                  query: _searchController.text,
                ),
                builder: (context, snapshot) {
                  final credentials =
                      snapshot.data ?? const <CredentialRecord>[];

                  if (credentials.isEmpty) {
                    return const AppPanel(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(
                          child: Text(
                            'No credentials yet. Add your first secure entry.',
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: credentials
                        .map(
                          (credential) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CredentialListCard(credential: credential),
                          ),
                        )
                        .toList(growable: false),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleCredentialTabOpened() async {
    if (_isCheckingConfiguration) {
      return;
    }

    _isCheckingConfiguration = true;
    final shouldPrompt = !_hasPromptedOnFirstOpen;
    _hasPromptedOnFirstOpen = true;
    await _checkConfiguration(promptIfNeeded: shouldPrompt);
    _isCheckingConfiguration = false;
  }

  Future<void> _openCredentialSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const CredentialSettingsPage(),
      ),
    );

    if (!mounted) {
      return;
    }

    await _checkConfiguration();
  }

  Future<void> _checkConfiguration({bool promptIfNeeded = false}) async {
    if (mounted) {
      setState(() {
        _checkingConfiguration = true;
      });
    }

    final configured = await context
        .read<CredentialService>()
        .hasEncryptionKey();
    if (!mounted) {
      return;
    }

      setState(() {
        _isConfigured = configured;
        _checkingConfiguration = false;
        if (!configured) {
          _securityReport = null;
          _selectedInsightFilter = null;
        }
      });

    if (promptIfNeeded && !configured && mounted) {
      await _promptForFirstTimeSetup();
    }
  }

  Future<void> _promptForFirstTimeSetup() async {
    final configured = await showCredentialKeySetupDialog(context);
    if (!mounted) {
      return;
    }
    setState(() {
      _isConfigured = configured == true;
      _checkingConfiguration = false;
    });
  }

  Future<void> _unlockInsights() async {
    setState(() {
      _isLoadingInsights = true;
    });

    try {
      final encryptionKey = await showCredentialAuthenticationDialog(
        context,
        title: 'Unlock Security Insights',
        reason: 'Authenticate to review reused passwords and expiry reminders.',
      );
      if (encryptionKey == null || !mounted) {
        return;
      }

      final report = await context.read<CredentialService>().buildSecurityReport(
        encryptionKey: encryptionKey,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _securityReport = report;
        _selectedInsightFilter = _defaultInsightFilter(report);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInsights = false;
        });
      }
    }
  }

  void _closeInsights() {
    setState(() {
      _securityReport = null;
      _selectedInsightFilter = null;
    });
  }

  void _handleInsightFilterSelected(_CredentialInsightFilter filter) {
    setState(() {
      _selectedInsightFilter = filter;
    });
  }

  _CredentialInsightFilter _defaultInsightFilter(
    CredentialSecurityReport report,
  ) {
    if (report.reusedPasswords.isNotEmpty) {
      return _CredentialInsightFilter.reused;
    }
    if (report.expiredItems.isNotEmpty) {
      return _CredentialInsightFilter.expired;
    }
    return _CredentialInsightFilter.dueSoon;
  }
}

class _CredentialListCard extends StatelessWidget {
  const _CredentialListCard({required this.credential});

  final CredentialRecord credential;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  credential.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const Icon(Icons.lock_rounded),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Encrypted data hidden until authentication.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: () async {
                await Navigator.of(context).pushNamed(
                  AppRoutes.credentialDetail,
                  arguments: CredentialDetailArgs(credentialId: credential.id),
                );
              },
              icon: const Icon(Icons.visibility_rounded),
              label: const Text('View Securely'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CredentialInsightsPanel extends StatelessWidget {
  const _CredentialInsightsPanel({
    required this.report,
    required this.isLoading,
    required this.onUnlock,
    required this.onClose,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  final CredentialSecurityReport? report;
  final bool isLoading;
  final Future<void> Function() onUnlock;
  final VoidCallback onClose;
  final _CredentialInsightFilter? selectedFilter;
  final ValueChanged<_CredentialInsightFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Security & Expiry Check',
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: isLoading
                    ? null
                    : () {
                        if (report == null) {
                          onUnlock();
                        } else {
                          onClose();
                        }
                      },
                icon: isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        report == null
                            ? Icons.shield_outlined
                            : Icons.close_rounded,
                      ),
                label: Text(report == null ? 'Unlock' : 'Close'),
              ),
            ],
          ),
          if (report != null) ...<Widget>[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _InsightChip(
                  label: 'Reused',
                  value: report!.reusedPasswords.length.toString(),
                  isSelected: selectedFilter == _CredentialInsightFilter.reused,
                  onTap: () => onFilterSelected(_CredentialInsightFilter.reused),
                ),
                _InsightChip(
                  label: 'Expired',
                  value: report!.expiredItems.length.toString(),
                  isSelected: selectedFilter == _CredentialInsightFilter.expired,
                  onTap: () => onFilterSelected(_CredentialInsightFilter.expired),
                ),
                _InsightChip(
                  label: 'Due Soon',
                  value: report!.expiringSoonItems.length.toString(),
                  isSelected: selectedFilter == _CredentialInsightFilter.dueSoon,
                  onTap: () => onFilterSelected(_CredentialInsightFilter.dueSoon),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              title: _sectionTitle(selectedFilter),
              items: _sectionItems(report!, selectedFilter),
              emptyLabel: _emptyLabel(selectedFilter),
            ),
          ],
        ],
      ),
    );
  }

  String _sectionTitle(_CredentialInsightFilter? filter) {
    return switch (filter) {
      _CredentialInsightFilter.reused => 'Reused Passwords',
      _CredentialInsightFilter.expired => 'Expired Items',
      _CredentialInsightFilter.dueSoon => 'Due Soon',
      null => 'Insights',
    };
  }

  List<String> _sectionItems(
    CredentialSecurityReport report,
    _CredentialInsightFilter? filter,
  ) {
    return switch (filter) {
      _CredentialInsightFilter.reused => report.reusedPasswords
          .map((item) => '${item.credentialTitle} - ${item.fieldLabel}')
          .toList(growable: false),
      _CredentialInsightFilter.expired => report.expiredItems
          .map(
            (item) =>
                '${item.credentialTitle} - expired ${AppConstants.shortDateFormat.format(item.expiryDate)}',
          )
          .toList(growable: false),
      _CredentialInsightFilter.dueSoon => report.expiringSoonItems
          .map(
            (item) =>
                '${item.credentialTitle} - due ${AppConstants.shortDateFormat.format(item.expiryDate)}',
          )
          .toList(growable: false),
      null => const <String>[],
    };
  }

  String _emptyLabel(_CredentialInsightFilter? filter) {
    return switch (filter) {
      _CredentialInsightFilter.reused => 'No reused passwords found.',
      _CredentialInsightFilter.expired => 'No expired items found.',
      _CredentialInsightFilter.dueSoon => 'No upcoming expiry items found.',
      null => 'No insights available.',
    };
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<String> items,
    required String emptyLabel,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(
            emptyLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(item, style: theme.textTheme.bodyMedium),
            ),
          ),
      ],
    );
  }
}

class _InsightChip extends StatelessWidget {
  const _InsightChip({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color backgroundColor = isSelected
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55);
    final Color textColor = isSelected
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(value, style: theme.textTheme.titleMedium),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _CredentialInsightFilter { reused, expired, dueSoon }
