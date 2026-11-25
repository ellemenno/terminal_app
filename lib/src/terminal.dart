import 'dart:async';
import 'dart:io';

import 'stdin_posix.dart';
import 'stdin_win32.dart';
import 'vts.dart' as vts;

//import 'terminal_state.dart';

/// utilities for managing terminal state and listening to keyboard signals.
///
/// the terminal is a virtual teletype (tty) device, that includes posix file descriptors for
/// input (keyboard) and output (screen and screen commands):
/// - stdin ([StdIn]) - reacts to keyboard signals and provides a stream of key code bytes following various protocols.
/// - stdout ([StdOut]) - writes characters to the terminal screen, with support for ANSI display codes and screen commands.
/// - stderr ([StdOut]) - not used here. prefer a logger to write info to file instead of requiring the user to redirect stderr.
class Terminal {
  static final Stdout _termOut = stdout;
  static final Stdin _termIn = stdin;

  /// check terminal readiness based on specific requirements:
  /// - [stdoutTerm] requires a terminal (i.e. character display) attached to stdout
  /// - [stdoutAnsi] requires stdout to support ansi escape sequences (e.g. for coloring, cursor control, window title, etc.)
  /// - [stdinTerm] requires a terminal (e.g. keyboard, mouse) attached to stdin
  /// - [stdinAnsi] requires stdin to support ansi escape sequences (e.g. for arrow and function key reporting)
  ///
  /// _note:_
  /// - Dart through at least v3.12 running in Windows Terminal does not report ansi escape sequence support
  /// - (see [issue #48329](https://github.com/dart-lang/sdk/issues/48329)), so we compensate via [StdinWin32]
  static bool meetsRequirements({
    bool stdinTerm = true,
    bool stdinAnsi = false,
    bool stdoutTerm = true,
    bool stdoutAnsi = true,
  }) {
    bool ready = true;
    if (stdinTerm) ready = ready && _termIn.hasTerminal;
    if (stdinAnsi) ready = ready && _termIn.supportsAnsiEscapes;
    if (stdoutTerm) ready = ready && _termOut.hasTerminal;
    if (stdoutAnsi) ready = ready && _termOut.supportsAnsiEscapes;
    return ready;
  }

  /// disable [Stdin.lineMode] and [Stdin.echoMode] so a program can intercept and react to user input.
  static void rawMode() => changeMode(targetEchoMode: false, targetLineMode: false);

  /// enable [Stdin.lineMode] and [Stdin.echoMode], returning the terminal to canonical mode for use by the user.
  static void cookedMode() => changeMode(targetEchoMode: true, targetLineMode: true);

  /// set [Stdin.lineMode] and [Stdin.echoMode], respecting quirks of system OS.
  ///
  /// when line mode is enabled, characters are buffered to allow editing until newline is read,
  /// and then entire line is submitted for processing.
  /// disabling line mode allows a program to recieve the characters as they are typed, for more responsive and granular interactions.
  ///
  /// when echo mode is enabled, typed characters are echoed to the terminal screen device for the user to read.
  /// disabling echo mode allows a program to decide what to show the user.
  ///
  /// this method assumes `input.hasTerminal` is true.
  static void changeMode({bool targetEchoMode = true, bool targetLineMode = true}) {
    // on windows, can only change echoMode when lineMode is enabled
    // https://github.com/dart-lang/sdk/issues/28599#issuecomment-277370165
    if (_termIn.echoMode != targetEchoMode) {
      if (!_termIn.lineMode) _termIn.lineMode = true;
      _termIn.echoMode = targetEchoMode;
    }
    if (_termIn.lineMode != targetLineMode) {
      _termIn.lineMode = targetLineMode;
    }
  }

  /// ask the terminal a question.
  ///
  /// returns the response bytes up to and including the first of any encountered termination bytes.
  /// the terminal must be in [rawMode] so that queries and results are not awaiting newlines from the user.
  static Future<List<int>> submitQuery(
    List<int> query, {
    int findToken = 0,
    int finalToken = 0,
  }) async {
    final List<int> response = <int>[];
    bool capturing = true;
    int readByte = 0;

    try {
      _termOut.add(query);
      await _termOut.flush();
      while (readByte > -1) {
        // readByte only returns -1 at end of file, so need to see finalToken when receiving query results
        readByte = _termIn.readByteSync();
        if (capturing) {
          response.add(readByte);
        }
        if (readByte == findToken) {
          capturing = false;
        }
        if (readByte == finalToken) {
          break;
        }
      }
      print('submitQuery - got response ${response}');
    } catch (e) {
      print('submitQuery - response so far: ${response}\nerror: ${e}');
    }

    return response;
  }

  /// ask if the terminal supports the Kitty Keyboard Protocol.
  static Future<bool> supportsKittyEnhancements() async {
    final List<int> response = await submitQuery(
      vts.kittyQuery,
      findToken: vts.kittyYes,
      finalToken: vts.kittyNo,
    );
    return (response.last == vts.kittyYes);
  }

  /// requests the terminal to enable the indicated Kitty Keyboard Protocol enhancement flags.
  ///
  /// the request is made as a push onto the config stack for easy removal in [disableKittyEnhancements]:
  static void enableKittyEnhancements({
    bool disambiguate = false,
    bool events = false,
    bool alternates = false,
    bool allKeys = false,
    bool andText = false,
    bool all = false,
  }) {
    final int flags = all
        ? 0x1f
        : 0x00 |
              (disambiguate ? 0x01 : 0) |
              (events ? 0x02 : 0) |
              (alternates ? 0x04 : 0) |
              (allKeys ? 0x08 : 0) |
              (andText ? 0x10 : 0);
    _termOut.write(vts.kittyPush(flags: flags));
  }

  /// requests the terminal to discard previously requested kitty enhancement flags.
  ///
  /// the request is made as a pop from the config stack for whatever was added in [enableKittyEnhancements]:
  static void disableKittyEnhancements() {
    _termOut.add(vts.kittyPop1);
  }

  /// requests the terminal to set window and/or icon titles, based on [mode]:
  /// - mode 0 - set window title and icon name
  /// - mode 1 - set icon name
  /// - mode 2 - set window title
  static void setTitle(String title, {int mode = 0}) {
    _termOut.write(vts.titleSet(title, mode: mode));
  }

  /// requests the terminal to enter an alternate blank buffer (leaving the previous one untouched),
  /// hiding the cursor, and moving the cursor location to 1,1 (upper left corner).
  static void enterAltBuffer() {
    _termOut.add(vts.cursorHide);
    _termOut.add(vts.altScreenEnter);
    _termOut.write(vts.cursorPos(col: 1, row: 1));
  }

  /// requests the terminal to leave the alternate buffer (returning to the previous one),
  /// and show the cursor.
  static void leaveAltBuffer() {
    _termOut.add(vts.altScreenLeave);
    _termOut.add(vts.cursorShow);
  }

  /// retrieve a stream for listening to stdin key events as [KeyRecord] bit records.
  ///
  /// stdout may be sent commands to enable protocol options, e.g. kitty keyboard protocol
  /// when [useKittyParser] is true,.
  ///
  /// Windows Terminal added support for Kitty Keyboard Protocol in 1.25.3131.0,
  /// but in cmd.exe it does not send bytes for many important non-printing keys:
  /// - arrow keys, f1..f12, insert, delete, home, end, page up, page down
  /// so, [preferWin32] can be set `true` to pick [StdinWin32] over [StdinPosix] w/ kitty
  static Stream<int> getKeyRecordStream({
    bool useKittyParser = false,
    bool preferWin32 = true,
  }) {
    if (useKittyParser) {
      if (preferWin32 && Platform.isWindows) {
        return StdinWin32();
      }
      enableKittyEnhancements(all: true);
      return StdinPosix(withKittyProtocol: true);
    }
    return (Platform.isWindows) ? StdinWin32() : StdinPosix();
  }
}
