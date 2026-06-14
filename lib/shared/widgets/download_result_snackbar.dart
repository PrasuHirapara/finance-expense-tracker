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
      unawaited(_openDownloadedFile(context, path: path));
    },
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
    showAppSnackBar(
      context,
      message: 'Unable to open file: $error',
      type: AppSnackBarType.error,
    );
  }
}
