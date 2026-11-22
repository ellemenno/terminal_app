/// command line exit codes
///
/// When a command line application terminates, the shell records a status value
/// indicating why it stopped running.
///
/// This value can be read from an environment variable in the shell:
/// - posix `$?`, see: https://tldp.org/LDP/abs/html/exitcodes.html
/// - cmd (win) `%ERRORLEVEL%`, see: https://ss64.com/nt/errorlevel.html
///
/// All posix signals can be listed with `kill -l`. Dart only supports listeners for [a few](https://api.dart.dev/dart-io/ProcessSignal/watch.html).
class ExitCode {
  /// **success** - execution completed normally (some output may have been logged to `stdout`)
  static const int ok = 0;

  /// **execution error** - execution encountered errors (these should be logged to `stderr`)
  static const int err = 1;

  /// **usage error** - user provided arguments were invalid
  static const int usage = 2;

  /// **hangup / config reload** - process received SIGHUP (Signal 1; 128 + 1 = 129)
  static const int sighup = 129;

  /// **process interrupt** - user typed ctrl-c; process received SIGINT (Signal 2; 128 + 2 = 130)
  static const int sigint = 130;

  /// **graceful termination** - process received SIGTERM (Signal 15; 128 + 15 = 143)
  static const int sigterm = 143;

  /// **process stopped** - user typed ctrl-z or hit Pause/Break key; process received SIGSTP (Signal 20; 128 + 20 = 148)
  static const int sigstp = 148;
}
