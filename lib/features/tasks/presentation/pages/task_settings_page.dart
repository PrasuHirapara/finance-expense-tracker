import 'package:flutter/material.dart';

import '../widgets/task_settings_body.dart';

class TaskSettingsPage extends StatelessWidget {
  const TaskSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Settings')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: TaskSettingsBody(),
      ),
    );
  }
}
