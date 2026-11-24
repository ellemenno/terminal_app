import 'dart:async';
import 'dart:io';

import 'exit_code.dart';
import 'interfaces.dart';
import 'terminal_state.dart';
import 'terminal.dart';
import 'terminal_buffer.dart';
import 'ticker.dart';

/// handles event setup and forwarding for a [TerminalApp]
///
/// initializes an update ticker, key and screen size event handlers,
/// and forwards their events to the matching methods of the [TerminalApp] provided to [run()].
class TerminalAppRunner implements TerminalAppHost {
  final TerminalState _priorState = TerminalState();
  final TerminalState _runningState = TerminalState(hideCursor: true, useAlternateScreen: true);

  late final TerminalApp _app;
  late final TerminalBuffer _screen;
  late final Stream<double> _ticker;
  late final StreamSubscription<double> _ticking;
  late final StreamSubscription<int> _typing;

  bool _supportsKitty = false;

  /// creates a runner that ticks at a frequency of [fps]
  TerminalAppRunner({int fps = 1, String title = ''}) {
    Terminal.captureState(_priorState);
    if (title.isNotEmpty) _runningState.title = title;
    _screen = TerminalBuffer(80, 24);
    _ticker = Ticker.herz(frequency: fps);
  }

  /// starts ticking and forwarding events to the provided [TerminalApp].
  /// to stop running (and terminate), the app should return `false` from its `onUpdate()` method.
  void run(TerminalApp app) async {
    if (!Terminal.meetsRequirements(stdin, stdout)) _cleanExit(ExitCode.err);
    Terminal.rawMode(stdin); // disable echo and line mode on stdin; we will receive input directly

    _supportsKitty = await Terminal.supportsKittyEnhancements(stdin, stdout);
    print('supportsKittyEnhancements ? ${_supportsKitty}');

    _app = app;
    _app.acceptHostAPIs((this as TerminalAppHost), (_screen as TerminalScreen));
    _addSignalListeners();
    _typing = Terminal.getKeyRecordStream(stdout, useKittyParser: _supportsKitty).listen(_onType);
    _ticking = _ticker.listen(_onTick);
  }

  @override
  void stop({int exitCode = ExitCode.ok}) {
    _stop(exitCode);
  }

  void _addSignalListeners() {
    // https://api.dart.dev/dart-io/ProcessSignal/watch.html
    // notes:
    // - SIGINT (ctrl-c) is the only cross-platform signal supported by Dart
    // - SIGSTP (ctrl-z or Pause/Break) will terminate the process and cannot be intercepted for clean-up
    late final StreamSubscription<ProcessSignal> sigintSubscription;
    StreamSubscription<ProcessSignal>? sigtermSubscription;
    StreamSubscription<ProcessSignal>? sigwinchSubscription;
    try {
      sigintSubscription = ProcessSignal.sigint.watch().listen((ProcessSignal signal) {
        // process interrupt from keyboard, e.g. ctrl-c --> sigint
        sigwinchSubscription?.cancel();
        sigtermSubscription?.cancel();
        sigintSubscription.cancel();
        _stop(ExitCode.sigint);
      });

      if (Platform.isWindows) {
        //TODO: add screen event listener to win32_stdin
        sigwinchSubscription = null;
      } else {
        sigtermSubscription = ProcessSignal.sigterm.watch().listen((ProcessSignal signal) {
          // process termination politely requested --> sigterm
          sigwinchSubscription?.cancel();
          sigtermSubscription?.cancel();
          sigintSubscription.cancel();
          _stop(ExitCode.sigterm);
        });
        sigwinchSubscription = ProcessSignal.sigwinch.watch().listen((ProcessSignal signal) {
          // notification of term window size change --> sigwinch
          _onResize();
        });
      }
    } on SignalException catch (e) {
      //TODO: how best to signal non-fatal error?
      print('signal subscription exception: ${e.message}');
    }
  }

  void _onTick(double dt) {
    try {
      final bool keepRunning = _app.onUpdate(dt);
      if (!keepRunning) {
        _stop(ExitCode.ok);
      }
    } catch (e, stackTrace) {
      _stopOnError(e, stackTrace);
    }
  }

  void _onType(int keyRecord) {
    try {
      _app.onKeyRecord(keyRecord);
    } catch (e, stackTrace) {
      _stopOnError(e, stackTrace);
    }
  }

  void _onResize() {
    try {
      print('[TerminalAppRunner._onResize()]');
      //TODO: update screen dimensions
      //TODO: _app.onResize();
    } catch (e, stackTrace) {
      _stopOnError(e, stackTrace);
    }
  }

  void _stop(int exitCode) async {
    if (_supportsKitty) {
      Terminal.disableKittyEnhancements(stdout);
    }
    Terminal.cookedMode(stdin); // re-enable echo and line mode on stdin
    Terminal.applyState(_priorState); // restore user's previous config
    await _ticking.cancel();
    await _typing.cancel();
    _cleanExit(exitCode);
  }

  void _stopOnError(Object e, StackTrace stackTrace) {
    print(e);
    print(stackTrace);
    _stop(ExitCode.err);
  }

  static Future<Never> _cleanExit(int appStatus) async {
    int exitCode = appStatus;
    try {
      // TODO: flush any loggers
      await stdout.flush();
      await stderr.flush();
    } catch (e) {
      // TODO: implement file logger
      print('flush error: ${e}');
      exitCode = ExitCode.err;
    } finally {
      exit(exitCode);
    }
  }
}
