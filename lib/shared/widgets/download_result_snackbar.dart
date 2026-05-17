import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/file_launcher_service.dart';
import 'app_snackbar.dart';

void showDownloadResultSnackBar(
  BuildContext context, {
  required String message,
  required String path,
}) {
  showAppSnackBar(
    context,
    message: message,
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
