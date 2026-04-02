import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/file_launcher_service.dart';

void showDownloadResultSnackBar(
  BuildContext context, {
  required String message,
  required String path,
}) {
  final messenger = ScaffoldMessenger.of(context);

  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      action: SnackBarAction(
        label: 'View',
        onPressed: () {
          unawaited(_openDownloadedFile(context, path: path));
        },
      ),
    ),
  );
}

Future<void> _openDownloadedFile(
  BuildContext context, {
  required String path,
}) async {
  try {
    await context.read<FileLauncherService>().openFile(path);
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Unable to open file: $error')));
  }
}
