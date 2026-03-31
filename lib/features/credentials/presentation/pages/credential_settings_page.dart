import 'package:flutter/material.dart';

import '../../../settings/presentation/widgets/credential_settings_section.dart';

class CredentialSettingsPage extends StatelessWidget {
  const CredentialSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Credential Settings')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: <Widget>[CredentialSettingsSection()],
        ),
      ),
    );
  }
}
