import 'exit_code.dart';

/// interface requirements for being able to host a [TerminalApp]
abstract interface class TerminalAppHost {
  /// request the application terminate with optional exit code.
  /// see [ExitCode].
  void stop({int exitCode = ExitCode.ok});
}

/// interface requirements for being runnable by [TerminalAppRunner]
abstract interface class TerminalApp {
  /// accept references to app host apis. guaranteed to be called before event handlers become active.
  void acceptHostAPIs(TerminalAppHost host, TerminalScreen screen);

  /// implement to receive notification of key presses with a bit record representing key enum and modifiers.
  /// see [KeyRecord], [KeyID], [ModFlags].
  void onKeyRecord(int keyRecord);

  /// implement to recieve notification of screen resizing with new width and height
  void onResize(int w, int h);

  /// implement to recieve frame update notifications with time delta as portion of a second.
  /// return `false` if app should halt and exit, `true` to continue running
  bool onUpdate(double dt);
}

/// interface provided by a [TerminalAppHost] providing drawing and ui commands
/// for rendering grid-based characters in a screen buffer
abstract interface class TerminalScreen {
  /// horizontal screen dimension in characters
  int get cols;

  /// vertical screen dimension in characters
  int get rows;
}
