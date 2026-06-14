import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;

import '../../core/services/file_launcher_service.dart';
import 'app_snackbar.dart';

void showDownloadResultSnackBar(
  BuildContext context, {
  required String message,
  required String path,
}) {
  final directoryPath = p.dirname(path);
  final formattedMessage = message.contains(path)
      ? message.replaceAll(path, directoryPath)
      : 'Saved successfully to: $directoryPath';

  showAppSnackBar(
    context,
    message: formattedMessage,
    actionLabel: 'View',
    onActionPressed: () {
      unawaited(
        _openDownloadedDirectory(context, directoryPath: directoryPath),
      );
    },
  );
}

Future<void> _openDownloadedDirectory(
  BuildContext context, {
  required String directoryPath,
}) async {
  try {
    await context.read<FileLauncherService>().openFile(directoryPath);
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    showAppSnackBar(
      context,
      message: 'Unable to open location: $error',
      type: AppSnackBarType.error,
    );
  }
}
