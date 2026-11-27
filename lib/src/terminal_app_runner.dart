import 'dart:async';
import 'dart:io';

import 'exit_code.dart';
import 'interfaces.dart';
//import 'terminal_state.dart';
import 'terminal.dart';
import 'terminal_buffer.dart';
import 'ticker.dart';

/// handles event setup and forwarding for a [TerminalApp]
///
/// initializes an update ticker, key and screen size event handlers,
/// and forwards their events to the matching methods of the [TerminalApp] provided to [run()].
class TerminalAppRunner implements TerminalAppHost {
  //final TerminalState _priorState = TerminalState();
  //final TerminalState _runningState = TerminalState(hideCursor: true, useAlternateScreen: true);

  late final TerminalApp _app;
  late final TerminalBuffer _screen;
  late final Stream<double> _ticker;
  late final StreamSubscription<double> _ticking;
  late final StreamSubscription<int> _typing;
  late final StreamSubscription<ProcessSignal> _resizing;
  late final StreamSubscription<ProcessSignal> _canceling;
  late final StreamSubscription<ProcessSignal> _terminating;
  late final String _title;

  bool _supportsKitty = false;

  /// creates a runner that will tick at a frequency of [fps] and forward events when [run()] is called.
  TerminalAppRunner({int fps = 1, this._title = ''}) {
    //Terminal.captureState(_priorState);
    _screen = TerminalBuffer(80, 24);
    _ticker = Ticker.herz(frequency: fps);
  }

  /// connects event handlers to the hosted [app] and starts ticking and forwarding events.
  /// to stop running (and terminate), the app should return `false` from its `onUpdate()` method.
  void run(TerminalApp app) async {
    if (!Terminal.meetsRequirements()) _cleanExit(ExitCode.err);

    // disable echo and line mode on stdin; we will receive input directly
    // also check if that input can be delivered in kitty keyboard protocol format
    Terminal.rawMode();
    _supportsKitty = await Terminal.supportsKittyEnhancements();

    // set title and enter app's own buffer
    if (_title.isNotEmpty) {
      Terminal.setTitle(_title);
    }
    Terminal.enterAltBuffer();

    // connect hosted app with event handlers, and activate event streams
    _app = app;
    _app.acceptHostAPIs((this as TerminalAppHost), (_screen as TerminalScreen));
    _typing = Terminal.getKeyRecordStream(useKittyParser: _supportsKitty).listen(_onType);
    _resizing = Terminal.getResizeSignalStream().listen(_onResize);
    _canceling = Terminal.getInterruptSignalStream().listen(_onInterrupt);
    _terminating = Terminal.getTerminateSignalStream().listen(_onTerminate);
    _ticking = _ticker.listen(_onTick);
  }

  @override
  void stop({int exitCode = ExitCode.ok}) {
    _stop(exitCode);
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

  void _onResize(ProcessSignal signal) {
    // notification of term window size change --> sigwinch
    if (signal != ProcessSignal.sigwinch) return;
    try {
      final int w = Terminal.cols;
      final int h = Terminal.rows;
      print('[TerminalAppRunner._onResize()] ${w}x${h}');
      _app.onResize(w, h);
    } catch (e, stackTrace) {
      _stopOnError(e, stackTrace);
    }
  }

  void _onInterrupt(ProcessSignal signal) {
    // process interrupt from keyboard, e.g. ctrl-c --> sigint
    if (signal != ProcessSignal.sigint) return;
    print('[TerminalAppRunner._onInterrupt()] ${signal}');
    //TODO: forward event to app?
    _stop(ExitCode.sigint);
  }

  void _onTerminate(ProcessSignal signal) {
    // process termination politely requested --> sigterm
    if (signal != ProcessSignal.sigterm) return;
    print('[TerminalAppRunner._onTerminate()] ${signal}');
    _stop(ExitCode.sigterm);
  }

  Future<Never> _stopOnError(Object e, StackTrace stackTrace) {
    print(e);
    print(stackTrace);
    return _stop(ExitCode.err);
  }

  Future<Never> _stop(int exitCode) async {
    // disable event subsriptions
    await Future.wait(<Future<void>>[
      _ticking.cancel(),
      _typing.cancel(),
      _resizing.cancel(),
      _terminating.cancel(),
      _canceling.cancel(),
    ]);
    // return user's console to previous state; re-enable echo and line mode on stdin
    //Terminal.applyState(_priorState); // restore user's previous config
    if (_supportsKitty) {
      Terminal.disableKittyEnhancements();
    }
    Terminal.leaveAltBuffer();
    Terminal.cookedMode();
    return _cleanExit(exitCode);
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
