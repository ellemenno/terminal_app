import 'dart:async';
import 'dart:io';

import 'stdin_posix.dart';
import 'stdin_win32.dart';
import 'terminal_state.dart';
import 'ucd.dart' as ucd;

/// utilities for managing terminal state and listening to keyboard signals.
///
/// the terminal is a virtual teletype (tty) device, that includes posix file descriptors for input (keyboard) and output (screen):
/// - stdin ([StdIn]) - reacts to keyboard signals and provides a stream of key code bytes following various protocols
/// - stdout ([StdOut]) - writes characters to the terminal screen, with support for ANSI display codes
/// - stderr ([StdOut]) - not used here. prefer a logger to write info to file instead of requiring the user to redirect stderr.
class Terminal {
  /// check terminal readiness based on specific requirements:
  /// - [stdoutTerm] requires a terminal (i.e. character display) attached to stdout
  /// - [stdoutAnsi] requires stdout to support ansi escape sequences (e.g. for coloring, cursor control, window title, etc.)
  /// - [stdinTerm] requires a terminal (e.g. keyboard, mouse) attached to stdin
  /// - [stdinAnsi] requires stdin to support ansi escape sequences (e.g. for arrow and function key reporting)
  ///
  /// _note:_
  /// - Dart through at least v3.12 running in Windows Terminal does not report ansi escape sequence support
  /// - (see [issue #48329](https://github.com/dart-lang/sdk/issues/48329)), so we compensate via [StdinWin32]
  static bool meetsRequirements(
    Stdin input,
    Stdout output, {
    bool stdinTerm = true,
    bool stdinAnsi = false,
    bool stdoutTerm = true,
    bool stdoutAnsi = true,
  }) {
    bool ready = true;
    if (stdinTerm) ready = ready && input.hasTerminal;
    if (stdinAnsi) ready = ready && (Platform.isWindows ? true : input.supportsAnsiEscapes);
    if (stdoutTerm) ready = ready && output.hasTerminal;
    if (stdoutAnsi) ready = ready && output.supportsAnsiEscapes;
    return ready;
  }

  /// disable [Stdin.lineMode] and [Stdin.echoMode] so a program can intercept and react to user input.
  static void rawMode(Stdin input) =>
      changeMode(input, targetEchoMode: false, targetLineMode: false);

  /// enable [Stdin.lineMode] and [Stdin.echoMode], returning the terminal to canonical mode for use by the user.
  static void cookedMode(Stdin input) =>
      changeMode(input, targetEchoMode: true, targetLineMode: true);

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
  static void changeMode(Stdin input, {bool targetEchoMode = true, bool targetLineMode = true}) {
    // on windows, can only change echoMode when lineMode is enabled
    // https://github.com/dart-lang/sdk/issues/28599#issuecomment-277370165
    if (input.echoMode != targetEchoMode) {
      if (!input.lineMode) input.lineMode = true;
      input.echoMode = targetEchoMode;
    }
    if (input.lineMode != targetLineMode) {
      input.lineMode = targetLineMode;
    }
  }

  /// ask the terminal a question. returns the response bytes up to and including the first of any encountered termination bytes.
  /// the terminal must be in [rawMode] so that queries and results are not awaiting newlines from the user.
  static Future<List<int>> submitQuery(
    Stdin input,
    Stdout output,
    String query, {
    int findToken = 0,
    int finalToken = 0,
  }) async {
    final List<int> response = <int>[];
    bool capturing = true;
    int readByte = 0;

    try {
      output.write(query);
      await output.flush();
      while (readByte > -1) {
        readByte = input
            .readByteSync(); // only returns -1 at end of file, else need to see finalToken
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
  ///
  /// this is done by combining two queries, the second widely supported, and checking for response terminators:
  /// ```
  /// 1. CSI ? u  ==> CSI ? <flags> u                      (response ends in 'u')
  /// 2. CSI c    ==> CSI ? 6 1 ; <attr1> ; .. <attrN> c   (response ends in 'c')
  /// ```
  ///
  /// ref:
  /// - KKB (Kitty keyboard protocol) - `CSI ? u`
  ///   - https://sw.kovidgoyal.net/kitty/keyboard-protocol/#detection-of-support-for-this-protocol
  ///   - https://sw.kovidgoyal.net/kitty/keyboard-protocol/#progressive-enhancement
  /// - DA1 (primary device attributes) - `CSI c`
  ///   - https://vt100.net/docs/vt510-rm/DA1.html
  static Future<bool> supportsKittyEnhancements(Stdin input, Stdout output) async {
    final String query = '\x1b[?u\x1b[c';
    final int uByte = 0x75, cByte = 0x63; // 'u'.runes.first, 'c'runes.first
    final List<int> response = await submitQuery(
      input,
      output,
      query,
      findToken: uByte,
      finalToken: cByte,
    );
    return (response.last == uByte);
  }

  /// requests the terminal to enable the indicated Kitty Keyboard Protocol enhancement flags.
  /// the request is made as a push onto the config stack for easy removal in [disableKittyEnhancements].
  ///
  /// see: https://sw.kovidgoyal.net/kitty/keyboard-protocol/#progressive-enhancement
  static void enableKittyEnhancements(
    Stdout output, {
    bool disambiguate = false,
    bool events = false,
    bool alternates = false,
    bool allKeys = false,
    bool andText = false,
    bool all = false,
  }) async {
    final int flags = all
        ? 0x1f
        : 0x00 |
              (disambiguate ? 0x01 : 0) |
              (events ? 0x02 : 0) |
              (alternates ? 0x04 : 0) |
              (allKeys ? 0x08 : 0) |
              (andText ? 0x10 : 0);
    print('enable kitty enhancements: push flags ${ucd.hexString(flags)} onto stack..');
    output.write('\x1b[>${flags}u');
    await output.flush();
  }

  /// requests the terminal to disable all enhancement flags.
  static void disableKittyEnhancements(Stdout output) async {
    print('disable kitty enhancements: pop flags from stack..');
    output.write('\x1b[<1u');
    await output.flush();
  }

  /// take a snapshot of terminal state, updating the provided [TerminalState] instance.
  static void captureState(TerminalState state) {
    //TODO: query terminal and parse responses for DEC 25, 1049, and kitty keyboard protocol enhancement flags
  }

  /// apply the provided [TerminalState] to the terminal
  static void applyState(TerminalState state) {
    //TODO: hide cursor, enter alternate buffer
    //TODO: apply DEC 25, 1049
  }

  /// retrieve a stream for listening to key events as [KeyRecord] bit records
  static Stream<int> getKeyRecordStream({bool useKittyParser = false}) {
    return (Platform.isWindows) ? StdinWin32() : StdinPosix(withKittyProtocol: useKittyParser);
  }
}
