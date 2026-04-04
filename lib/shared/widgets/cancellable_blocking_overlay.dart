import 'dart:ui';

import 'package:flutter/material.dart';

Future<T?> showCancellableBlockingOverlay<T>({
  required BuildContext context,
  required String statusText,
  required VoidCallback onCancel,
  String title = 'Do not close the app',
  bool useRootNavigator = true,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  return navigator.push(
    createCancellableBlockingOverlayRoute<T>(
      title: title,
      statusText: statusText,
      onCancel: onCancel,
    ),
  );
}

RawDialogRoute<T> createCancellableBlockingOverlayRoute<T>({
  required String statusText,
  required VoidCallback onCancel,
  String title = 'Do not close the app',
}) {
  return RawDialogRoute<T>(
    barrierDismissible: false,
    barrierLabel: title,
    barrierColor: Colors.transparent,
    pageBuilder: (dialogContext, _, _) {
      return _CancellableBlockingOverlay(
        title: title,
        statusText: statusText,
        onCancel: onCancel,
      );
    },
  );
}

class _CancellableBlockingOverlay extends StatefulWidget {
  const _CancellableBlockingOverlay({
    required this.title,
    required this.statusText,
    required this.onCancel,
  });

  final String title;
  final String statusText;
  final VoidCallback onCancel;

  @override
  State<_CancellableBlockingOverlay> createState() =>
      _CancellableBlockingOverlayState();
}

class _CancellableBlockingOverlayState
    extends State<_CancellableBlockingOverlay> {
  bool _cancelRequested = false;

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
                        widget.title,
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
                                  widget.statusText,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 18),
                                FilledButton.tonal(
                                  onPressed: _cancelRequested
                                      ? null
                                      : () {
                                          setState(() {
                                            _cancelRequested = true;
                                          });
                                          widget.onCancel();
                                        },
                                  child: Text(
                                    _cancelRequested
                                        ? 'Cancelling...'
                                        : 'Cancel',
                                  ),
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
