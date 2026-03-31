import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../data/services/credential_service.dart';
import '../../domain/models/credential_models.dart';
import 'credential_detail_page.dart';
import '../widgets/credential_key_setup_dialog.dart';

class CredentialModulePage extends StatefulWidget {
  const CredentialModulePage({super.key});

  @override
  State<CredentialModulePage> createState() => _CredentialModulePageState();
}

class _CredentialModulePageState extends State<CredentialModulePage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isConfigured = false;
  bool _checkingConfiguration = true;
  bool _setupDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkConfiguration();
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

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Credential Module',
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              FilledButton.icon(
                onPressed: !_isConfigured
                    ? null
                    : () => Navigator.of(context).pushNamed(
                          AppRoutes.credentialEditor,
                        ),
                icon: const Icon(Icons.add),
                label: const Text('Add Credential'),
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
                final credentials = snapshot.data ?? const <CredentialRecord>[];

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
    );
  }

  Future<void> _checkConfiguration() async {
    final configured = await context.read<CredentialService>().hasEncryptionKey();
    if (!mounted) {
      return;
    }
    setState(() {
      _isConfigured = configured;
      _checkingConfiguration = false;
    });

    if (!configured && !_setupDialogShown) {
      await _promptForFirstTimeSetup();
    }
  }

  Future<void> _promptForFirstTimeSetup() async {
    _setupDialogShown = true;
    final configured = await showCredentialKeySetupDialog(context);
    if (!mounted) {
      return;
    }
    setState(() {
      _isConfigured = configured == true;
      _checkingConfiguration = false;
    });
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
