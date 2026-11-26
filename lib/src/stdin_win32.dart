import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'key_id.dart';
import 'key_record.dart';
import 'vk_win32.dart';
import 'ucd.dart' as ucd;

// ffi implementation based on:
// https://github.com/dart-lang/tools/blob/main/pkgs/cli_util/lib/src/windows/win32_stdin.dart
// Copyright (c) 2026, the Dart project authors
//
// modifications:
// - changed subscription data type from list of ints to just ints, merging key id, rune code, and modifiers into single record
// - added support for rest of non-printing keys (backspace, tab, caps & num lock, shifts, controls, alt/menu, insert, delete, f1 thru f12)
// - added differentiation of left and right shift, ctrl, and alt
// - added type annotations to pass 'always_specify_types' lint
// - removed dependency on meta package and @visibleForTesting annotations
// - removed dependency on math package for single min() call
// - edited / replaced some dart docs
// - TODO: add stream for listening to window resize events

/// handles Win32 keyboard input and translates it to [KeyRecord] bits.
///
/// this is used on Windows to work around issues where [stdin] doesn't forward
/// some non-printing keys like arrows or modifiers
/// e.g: https://github.com/dart-lang/sdk/issues/48329
///
/// ffi is used, but the only native dependency is _kernel32.dll_,
/// which is always present in every standard installation of Windows,
/// so no external compiler tools are required (`dart compile` or `dart run` are sufficient).
///
/// see [StdinPosix] for the non-Windows analogue.
class StdinWin32 extends Stream<int> {
  static final Map<int, StdinWin32> _instances = <int, StdinWin32>{};
  static const int eventBufferSize = 10;

  final int _inputHandle;
  final ModFlags _modFlags = ModFlags();
  final StreamController<int> _controller = StreamController<int>();
  bool _running = false;

  /// creates or retrieves a [StdinWin32] instance for the given console [handle].
  ///
  /// if [handle] is omitted, it defaults to the standard input handle
  /// (`STD_INPUT_HANDLE`).
  /// see: https://learn.microsoft.com/en-us/windows/console/console-handles
  ///
  /// instances are cached and reused for the same handle.
  factory StdinWin32([int? handle]) {
    final int consoleHandle = handle ?? Win32Console.instance.getStdHandle(_stdInputHandle);
    return _instances.putIfAbsent(
      consoleHandle,
      () => StdinWin32._create(consoleHandle),
    );
  }

  StdinWin32._create(this._inputHandle) {
    _controller.onCancel = _close;
  }

  @override
  StreamSubscription<int> listen(
    void Function(int event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    if (!_running) {
      _running = true;
      _eventLoop();
    }

    return _controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  Future<void> _eventLoop() async {
    await using((Arena arena) async {
      // allocate a buffer for up to eventBufferSize events at a time.
      final Pointer<InputRecord> pInputRecord = arena<InputRecord>(eventBufferSize);
      final Pointer<Uint32> pEventsTotal = arena<Uint32>();
      final Pointer<Uint32> pEventsRead = arena<Uint32>();

      while (_running) {
        // yield to Dart event loop between emitting events.
        await Future<void>.value();
        if (!_running) break;

        // check how many events are available; stop blocking thread if none
        final int eventsTotalCallResult = Win32Console.instance.getNumberOfConsoleInputEvents(
          _inputHandle,
          pEventsTotal,
        );
        if (eventsTotalCallResult == 0 || pEventsTotal.value == 0) {
          // error reading events or no events available, yield and try again.
          await Future<void>.delayed(const Duration(milliseconds: 50));
          continue;
        }

        // read up to eventBufferSize events at a time.
        final int eventsToRead = (pEventsTotal.value > eventBufferSize)
            ? eventBufferSize
            : pEventsTotal.value;
        final int eventsReadCallResult = Win32Console.instance.readConsoleInputW(
          _inputHandle,
          pInputRecord,
          eventsToRead,
          pEventsRead,
        );
        if (eventsReadCallResult == 0 || pEventsRead.value == 0) continue;

        for (int i = 0; i < pEventsRead.value; i++) {
          final InputRecord record = (pInputRecord + i).ref;

          switch (record.eventType) {
            case InputRecordEventType.keyEvent:
              final KeyEventRecord keyEvent = record.event.keyEvent;
              _controller.add(_getKeyBitRecord(keyEvent, _modFlags));
              break;
            case InputRecordEventType.windowBufferSizeEvent:
              //TODO: add resizeEvent support
              break;
            default: continue;
          }

        }
      }
    });
  }

  Future<void> _close() async {
    _running = false;
    await _controller.close();
    _instances.remove(_inputHandle);
  }

  static int _getKeyBitRecord(KeyEventRecord keyEvent, ModFlags modFlags, {bool debug = false}) {
    // collect modifiers
    modFlags.hasShift = keyEvent.shiftPressed;
    modFlags.hasAlt = keyEvent.altPressed;
    modFlags.hasCtrl = keyEvent.ctrlPressed;
    modFlags.hasSuper = false; // windows key events are consumed before this process gets them
    modFlags.hasHyper = false; // not supported by windows console key input record
    modFlags.hasMeta = false; // not supported by windows console key input record
    modFlags.hasCaps = keyEvent.capsLockOn;
    modFlags.hasNuml = keyEvent.numLockOn;

    // differentiate handedness for keys with multiple locations
    // ctrl and alt/menu don't seem to be reported via scan codes, so we use modifier info instead
    final int scanCode = keyEvent.wVirtualScanCode;
    int keyCode = keyEvent.wVirtualKeyCode;
    switch (keyEvent.wVirtualKeyCode) {
      case Win32VK.shift:
        if (scanCode == Win32SC.lshift) {
          keyCode = Win32VK.lshift;
        } else if (scanCode == Win32SC.rshift) {
          keyCode = Win32VK.rshift;
        }
        break;
      case Win32VK.control:
        if (keyEvent.leftCtrlPressed) {
          keyCode = Win32VK.lcontrol;
        } else if (keyEvent.rightCtrlPressed) {
          keyCode = Win32VK.rcontrol;
        }
        break;
      case Win32VK.menu:
        if (keyEvent.leftAltPressed) {
          keyCode = Win32VK.lmenu;
        } else if (keyEvent.rightAltPressed) {
          keyCode = Win32VK.rmenu;
        }
        break;
    }

    // default case: look up by VK code
    KeyID id = win32ToKey[keyCode] ?? KeyID.none;
    int glyphCode = keyEvent.uChar;

    // special cases
    //-- C0 codes from Ctrl modified presses
    if (keyEvent.ctrlPressed) {
      // if C0 code received, choose non-zero uChar glyph when ctrlPressed.
      if (keyEvent.uChar < 0x20 && keyEvent.uChar > 0) {
        glyphCode = keyEvent.uChar + 0x40;
      }
      // uChar is zero when key is a non-letter, so try to look up glyph
      // FIXME: Shift+Alt+Ctrl+G gives 0x47 ␀ -> ◌ Shift+Alt+Ctrl+Numl+<none>
      else {
        glyphCode = win32ToRune[keyCode] ?? 0;
      }
    }
    //-- numpad enter
    if (keyEvent.wVirtualKeyCode == Win32VK.enter && keyEvent.isEnhanced) {
      // numpad enter doesn't have a unique VK code (reports 0x0D, same as enter)
      // it must be detected by checking the enhancedKey bit on the key record
      id = KeyID.numpadEnter;
    }
    //-- numpad keys when numlock off
    if (!keyEvent.numLockOn && keyCode >= 0x60 && keyCode <= 0x69) {
      id = win32ToUnNumlock[keyCode] ?? KeyID.none;
    }

    final KeyRecord keyRecord = KeyRecord(modFlags, down: keyEvent.pressed, keyID: id, rune: glyphCode);
    final int bits = keyRecord.bits;
    if (debug) {
      print(
        '${ucd.hexString(keyCode)} ${String.fromCharCode(ucd.getPrintableCode(glyphCode))} -> ${keyRecord.summary}',
      );
    }
    return bits;
  }
}

// Windows API Constants

// https://learn.microsoft.com/en-us/windows/console/getstdhandle
const int _stdInputHandle = -10;

// https://learn.microsoft.com/en-us/windows/console/key-event-record-str
const int _rightAltPressed = 0x0001;
const int _leftAltPressed = 0x0002;
const int _rightCtrlPressed = 0x0004;
const int _leftCtrlPressed = 0x0008;
const int _shiftPressed = 0x0010;
const int _numLockOn = 0x0020;
const int _capsLockOn = 0x0080;
const int _enhancedKey = 0x0100;

/// Dart enum representing possible event types from input records.
///
/// https://learn.microsoft.com/en-us/windows/console/input-record-str
enum InputRecordEventType {
  keyEvent,
  mouseEvent,
  windowBufferSizeEvent,
  menuEvent,
  focusEvent,
  unknown;

  /// https://learn.microsoft.com/en-us/windows/console/input-record-str#members
  factory InputRecordEventType.fromInt(int value) => switch (value) {
    0x0001 => keyEvent,
    0x0002 => mouseEvent,
    0x0004 => windowBufferSizeEvent,
    0x0008 => menuEvent,
    0x0010 => focusEvent,
    _ => unknown,
  };
}

/// Windows console input record struct.
///
/// https://learn.microsoft.com/en-us/windows/console/input-record-str
final class InputRecord extends Struct {
  @Uint16()
  external int _eventType;
  external EventUnion event;

  /// Converts [_eventType] to an [InputRecordEventType].
  InputRecordEventType get eventType => InputRecordEventType.fromInt(_eventType);

  set eventType(InputRecordEventType type) {
    _eventType = switch (type) {
      InputRecordEventType.keyEvent => 0x0001,
      InputRecordEventType.mouseEvent => 0x0002,
      InputRecordEventType.windowBufferSizeEvent => 0x0004,
      InputRecordEventType.menuEvent => 0x0008,
      InputRecordEventType.focusEvent => 0x0010,
      InputRecordEventType.unknown => 0,
    };
  }
}

/// Union of event types for [InputRecord].
///
/// https://learn.microsoft.com/en-us/windows/console/input-record-str
final class EventUnion extends Union {
  /// Maps to [InputRecord.eventType == 1].
  external KeyEventRecord keyEvent;
}

/// Windows key event record struct.
///
/// https://learn.microsoft.com/en-us/windows/console/key-event-record-str
final class KeyEventRecord extends Struct {
  @Int32()
  external int bKeyDown;
  @Uint16()
  external int wRepeatCount;
  @Uint16()
  external int wVirtualKeyCode;
  @Uint16()
  external int wVirtualScanCode;
  @Uint16()
  external int uChar;
  @Uint32()
  external int dwControlKeyState;

  bool get pressed => bKeyDown != 0;
  bool get released => bKeyDown == 0;

  bool get altPressed => (dwControlKeyState & (_leftAltPressed | _rightAltPressed)) != 0;
  bool get ctrlPressed => (dwControlKeyState & (_leftCtrlPressed | _rightCtrlPressed)) != 0;
  bool get shiftPressed => (dwControlKeyState & _shiftPressed) != 0;
  bool get numLockOn => (dwControlKeyState & _numLockOn) != 0;
  bool get capsLockOn => (dwControlKeyState & _capsLockOn) != 0;

  bool get rightAltPressed => (dwControlKeyState & _rightAltPressed) != 0;
  bool get leftAltPressed => (dwControlKeyState & _leftAltPressed) != 0;
  bool get rightCtrlPressed => (dwControlKeyState & _rightCtrlPressed) != 0;
  bool get leftCtrlPressed => (dwControlKeyState & _leftCtrlPressed) != 0;

  bool get isEnhanced => (dwControlKeyState & _enhancedKey) != 0;
}

/// FFI Function binding to [Console.GetStdHandle](https://learn.microsoft.com/en-us/windows/console/getstdhandle)
typedef GetStdHandleDart = int Function(int nStdHandle);

/// FFI Function binding to [Console.ReadConsoleInput](https://learn.microsoft.com/en-us/windows/console/readconsoleinput)
typedef ReadConsoleInputDart =
    int Function(
      int hConsoleInput,
      Pointer<InputRecord> lpBuffer,
      int nLength,
      Pointer<Uint32> lpNumberOfEventsRead,
    );

/// FFI Function binding to [Console.GetNumberOfConsoleInputEvents](https://learn.microsoft.com/en-us/windows/console/getnumberofconsoleinputevents)
typedef GetNumberOfConsoleInputEventsDart =
    int Function(int hConsoleInput, Pointer<Uint32> lpcNumberOfEvents);

/// Lazy loader for Win32 console APIs.
class Win32Console {
  static Win32Console? _instance;
  static Win32Console get instance {
    // Tests may set a mock instance on non-windows.
    if (_instance case final Win32Console instance?) return instance;

    if (!Platform.isWindows) {
      throw StateError('Win32Console is only available on Windows');
    }
    return _instance = Win32Console._();
  }

  static set instance(Win32Console? value) => _instance = value;

  final GetStdHandleDart getStdHandle;
  final ReadConsoleInputDart readConsoleInputW;
  final GetNumberOfConsoleInputEventsDart getNumberOfConsoleInputEvents;

  factory Win32Console._() {
    final DynamicLibrary kernel32 = DynamicLibrary.open('kernel32.dll');
    return Win32Console.internal(
      kernel32.lookupFunction<IntPtr Function(Uint32), GetStdHandleDart>('GetStdHandle'),
      kernel32.lookupFunction<
        Int32 Function(IntPtr, Pointer<InputRecord>, Uint32, Pointer<Uint32>),
        ReadConsoleInputDart
      >('ReadConsoleInputW'),
      kernel32.lookupFunction<
        Int32 Function(IntPtr, Pointer<Uint32>),
        GetNumberOfConsoleInputEventsDart
      >('GetNumberOfConsoleInputEvents'),
    );
  }

  Win32Console.internal(
    this.getStdHandle,
    this.readConsoleInputW,
    this.getNumberOfConsoleInputEvents,
  );
}
