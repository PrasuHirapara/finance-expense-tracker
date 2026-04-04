import 'dart:async';

class AppCancellationToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }

  void throwIfCancelled([String message = 'Operation canceled.']) {
    if (_isCancelled) {
      throw AppTaskCancelledException(message);
    }
  }
}

class AppTaskCancelledException implements Exception {
  const AppTaskCancelledException(this.message);

  final String message;

  @override
  String toString() => message;
}

Future<void> cancellableUiYield(AppCancellationToken? token) async {
  token?.throwIfCancelled();
  await Future<void>.delayed(Duration.zero);
  token?.throwIfCancelled();
}
