import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

Future<T> runWithBlockingLoadingOverlay<T>({
  required BuildContext context,
  required String statusText,
  required Future<T> Function() task,
  String title = 'Please wait',
  bool useRootNavigator = true,
  VoidCallback? onCancel,
  String cancelLabel = 'Cancel',
}) async {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  late final RawDialogRoute<void> route;
  route = createBlockingLoadingOverlayRoute<void>(
    title: title,
    statusText: statusText,
    cancelLabel: cancelLabel,
    onCancel: () {
      if (route.isActive) {
        navigator.removeRoute(route);
      }
      onCancel?.call();
    },
  );
  unawaited(navigator.push<void>(route));
  await Future<void>.delayed(Duration.zero);

  try {
    return await task();
  } finally {
    if (route.isActive) {
      navigator.removeRoute(route);
    }
  }
}

RawDialogRoute<T> createBlockingLoadingOverlayRoute<T>({
  required String statusText,
  String title = 'Please wait',
  required VoidCallback onCancel,
  String cancelLabel = 'Cancel',
}) {
  return RawDialogRoute<T>(
    barrierDismissible: false,
    barrierLabel: title,
    barrierColor: Colors.transparent,
    pageBuilder: (dialogContext, _, _) {
      return _BlockingLoadingOverlay(
        title: title,
        statusText: statusText,
        onCancel: onCancel,
        cancelLabel: cancelLabel,
      );
    },
  );
}

class _BlockingLoadingOverlay extends StatelessWidget {
  const _BlockingLoadingOverlay({
    required this.title,
    required this.statusText,
    required this.onCancel,
    required this.cancelLabel,
  });

  final String title;
  final String statusText;
  final VoidCallback onCancel;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                child: ColoredBox(
                  color: theme.colorScheme.scrim.withValues(alpha: 0.26),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: Column(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.topCenter,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(
                              alpha: 0.95,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: theme.colorScheme.shadow.withValues(
                                  alpha: 0.16,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const SizedBox(
                                  width: 34,
                                  height: 34,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  statusText,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 18),
                                FilledButton.tonal(
                                  onPressed: onCancel,
                                  child: Text(cancelLabel),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
