import 'package:flutter/material.dart';

enum AppSnackBarType { info, warning, error }

void showAppSnackBar(
  BuildContext context, {
  required String message,
  AppSnackBarType type = AppSnackBarType.info,
  String? actionLabel,
  VoidCallback? onActionPressed,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    buildAppSnackBar(
      context,
      message: message,
      type: type,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      onCancel: messenger.hideCurrentSnackBar,
    ),
  );
}

SnackBar buildAppSnackBar(
  BuildContext context, {
  required String message,
  AppSnackBarType type = AppSnackBarType.info,
  String? actionLabel,
  VoidCallback? onActionPressed,
  VoidCallback? onCancel,
}) {
  final theme = Theme.of(context);
  final color = _borderColor(theme, type);
  final foregroundColor = theme.colorScheme.onSurface;
  final hasAction = actionLabel != null && onActionPressed != null;
  final dismissSnackBar =
      onCancel ?? ScaffoldMessenger.of(context).hideCurrentSnackBar;

  return SnackBar(
    behavior: SnackBarBehavior.floating,
    dismissDirection: DismissDirection.horizontal,
    backgroundColor: theme.colorScheme.surface,
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: color, width: 1.4),
    ),
    content: Row(
      children: <Widget>[
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        if (hasAction)
          TextButton(
            onPressed: () {
              dismissSnackBar();
              onActionPressed();
            },
            style: TextButton.styleFrom(
              foregroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(44, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel),
          )
        else
          IconButton(
            onPressed: dismissSnackBar,
            tooltip: 'Dismiss',
            icon: const Icon(Icons.close),
            color: color,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          ),
      ],
    ),
  );
}

Color _borderColor(ThemeData theme, AppSnackBarType type) {
  return switch (type) {
    AppSnackBarType.info => const Color(0xFF1F8B4C),
    AppSnackBarType.warning => const Color(0xFFC88719),
    AppSnackBarType.error => theme.colorScheme.error,
  };
}
