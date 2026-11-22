import 'dart:async';

/// simple frame ticker.
///
/// provides a stream of time deltas delivered at a specific frequency.
///
/// the frequency is not exact, and time deltas can exceed the expected microseconds per frame.
/// updates are scheduled into the dart event queue and can be delayed by long-running code.
/// see: https://dart.dev/language/concurrency#event-loop
class Ticker {
  /// generate a stream that ticks [frequency] times per second (Hz).
  ///
  /// call `listen()` on the stream to set a tick callback and receive a [StreamSubscription] that can be used to cancel the stream.
  ///
  /// the value delivered at each tick to the callback is the time delta since last tick in seconds, with microsecond precision.
  static Stream<double> herz({int frequency = 1}) {
    final Stopwatch watch = Stopwatch();
    final Duration period = Duration(microseconds: (1.0 / frequency * 1000 * 1000).round());
    final StreamController<double> controller = StreamController<double>();
    int lastTick = 0;
    controller.onListen = () {
      watch.start();
      void tick(_) {
        final int now = watch.elapsedMicroseconds;
        final int elapsed = now - lastTick;
        lastTick = now;
        controller.add(elapsed * 0.000001);
      }

      final Timer timer = Timer.periodic(period, tick);
      controller.onCancel = () {
        timer.cancel();
        watch.stop();
      };
    };
    return controller.stream;
  }
}
