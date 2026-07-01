import 'dart:math';

import 'package:playcado/services/logger_service.dart';

/// Executes [action] with retry and exponential backoff with jitter.
///
/// Returns the first successful result, or throws after [maxAttempts].
Future<T> retryWithBackoff<T extends Object>(
  Future<T> Function() action, {
  int maxAttempts = 3,
  Duration baseDelay = const Duration(milliseconds: 500),
  String? label,
}) async {
  final random = Random();

  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      final stopwatch = Stopwatch()..start();
      final result = await action();
      stopwatch.stop();
      LoggerService.api.fine(
        '[API: ${label ?? 'Unknown'}] [Status: Success] [Latency: ${stopwatch.elapsedMilliseconds}ms]',
      );
      return result;
    } on Exception catch (e, s) {
      if (attempt == maxAttempts) {
        LoggerService.api.severe(
          '[Retry: ${label ?? 'API'}] [Status: Exhausted] [Attempts: $maxAttempts]',
          e,
          s,
        );
        rethrow;
      }

      final delayMs = baseDelay.inMilliseconds * (1 << (attempt - 1));
      final jitter = random.nextInt(delayMs ~/ 2);
      final totalDelay = Duration(milliseconds: delayMs + jitter);

      LoggerService.api.info(
        '[Retry: ${label ?? 'API'}] [Attempt: $attempt] [Delay: ${totalDelay.inMilliseconds}ms]',
      );

      await Future<void>.delayed(totalDelay);
    }
  }

  throw Exception('Retry exhausted');
}
