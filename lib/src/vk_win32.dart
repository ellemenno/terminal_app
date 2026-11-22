/// utilities for working with Virtual Terminal Sequences, aka key codes.
///
/// utlities are provided for
/// tools are provided for converting Windows and Posix codes into a platform agnostic bit record
/// for higer performance handling than dealing with lists of bytes or strings. [KeyRecord]s can be
/// converted to enums for non-printing keys, and to string rune codes for printing keys.
library;

import 'key_id.dart';

/// labels for win32 scan codes reported by the Console API
///
/// https://learn.microsoft.com/en-us/windows/win32/inputdev/about-keyboard-input
extension Win32SC on int {
  static const int lshift = 0x2a;
  static const int rshift = 0x36;
}

/// labels for win32 virtual key codes reported by the Console API
///
/// see: https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
extension Win32VK on int {
  static const int escape = 0x1b;

  static const int f1 = 0x70;
  static const int f2 = 0x71;
  static const int f3 = 0x72;
  static const int f4 = 0x73;
  static const int f5 = 0x74;
  static const int f6 = 0x75;
  static const int f7 = 0x76;
  static const int f8 = 0x77;
  static const int f9 = 0x78;
  static const int f10 = 0x79;
  static const int f11 = 0x7a; // triggers full screen (not passed through)
  static const int f12 = 0x7b;

  static const int snapshot = 0x2c; // PrtScr (not passed through)
  static const int scroll = 0x91;
  static const int pause = 0x13;

  static const int backspace = 0x08;
  static const int tab = 0x09;
  static const int enter = 0x0d;

  static const int shift = 0x10;
  static const int control = 0x11;
  static const int menu = 0x12; // aka Alt
  static const int capital = 0x14; // Caps Lock

  static const int lshift = 0xa0; //  left shift. not triggered; use scan code
  static const int rshift = 0xa1; // right shift. not triggered; use scan code
  static const int lcontrol = 0xa2; //  left control. not triggered; indicated in ControlKeyState
  static const int rcontrol = 0xa3; // right control. not triggered; indicated in ControlKeyState
  static const int lmenu = 0xa4; //  left alt. not triggered; indicated in ControlKeyState
  static const int rmenu = 0xa5; // right alt. not triggered; indicated in ControlKeyState
  static const int lwin = 0x5b; //  left windows logo key, aka super. not passed through
  static const int rwin = 0x5c; // right windows logo key, aka super. not passed through

  static const int insert = 0x2d;
  static const int delete = 0x2e;
  static const int home = 0x24;
  static const int end = 0x23;
  static const int pageUp = 0x21;
  static const int pageDown = 0x22;

  static const int left = 0x25;
  static const int up = 0x26;
  static const int right = 0x27;
  static const int down = 0x28;

  static const int numlock = 0x90;
  static const int numpadDivide = 0x6F;
  static const int numpadMultiply = 0x6A;
  static const int numpadSubtract = 0x6D;
  static const int numpadAdd = 0x6B;
  //               numpadEnter doesn't have a unique VK code (reports 0x0D, same as enter); it must be detected by checking the enhancedKey bit on the key record
  static const int numpadDecimal = 0x6E; // numpadDelete when numlock off
  static const int numpad0 = 0x60; // numpadInsert when numlock off
  static const int numpad1 = 0x61; // numpadEnd when numlock off
  static const int numpad2 = 0x62; // numpadDown when numlock off
  static const int numpad3 = 0x63; // numpadPageDown when numlock off
  static const int numpad4 = 0x64; // numpadLeft when numlock off
  static const int numpad5 = 0x65; // numpadBegin when numlock off
  static const int numpad6 = 0x66; // numpadRight when numlock off
  static const int numpad7 = 0x67; // numpadHome when numlock off
  static const int numpad8 = 0x68; // numpadUp when numlock off
  static const int numpad9 = 0x69; // numpadPageUp when numlock off
}

/// rune code lookup map from [Win32VK] virtual key codes
///
/// https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
const Map<int, int> win32ToRune = <int, int>{
  0xc0: 0x60, // `
  0x31: 0x31, // 1
  0x32: 0x32, // 2
  0x33: 0x33, // 3
  0x34: 0x34, // 4
  0x35: 0x35, // 5
  0x36: 0x36, // 6
  0x37: 0x37, // 7
  0x38: 0x38, // 8
  0x39: 0x39, // 9
  0x30: 0x30, // 0
  0xbd: 0x2d, // -
  0xbb: 0x3d, // =
  0xba: 0x3b, // ;
  0xde: 0x27, // '
  0xbc: 0x2c, // ,
  0xbe: 0x2e, // .
  0xbf: 0x2f, // /
};

/// [KeyID] lookup map from [Win32VK] virtual key codes when numlock is not active
const Map<int, KeyID> win32ToUnNumlock = <int, KeyID>{
  Win32VK.numpadDecimal: KeyID.numpadDelete,
  Win32VK.numpad0: KeyID.numpadInsert,
  Win32VK.numpad1: KeyID.numpadEnd,
  Win32VK.numpad2: KeyID.numpadDown,
  Win32VK.numpad3: KeyID.numpadPageDown,
  Win32VK.numpad4: KeyID.numpadLeft,
  Win32VK.numpad5: KeyID.numpadBegin,
  Win32VK.numpad6: KeyID.numpadRight,
  Win32VK.numpad7: KeyID.numpadHome,
  Win32VK.numpad8: KeyID.numpadUp,
  Win32VK.numpad9: KeyID.numpadPageUp,
};

/// [KeyID] lookup map from [Win32VK] virtual key codes
const Map<int, KeyID> win32ToKey = <int, KeyID>{
  Win32VK.escape: KeyID.escape,

  Win32VK.f1: KeyID.f1,
  Win32VK.f2: KeyID.f2,
  Win32VK.f3: KeyID.f3,
  Win32VK.f4: KeyID.f4,
  Win32VK.f5: KeyID.f5,
  Win32VK.f6: KeyID.f6,
  Win32VK.f7: KeyID.f7,
  Win32VK.f8: KeyID.f8,
  Win32VK.f9: KeyID.f9,
  Win32VK.f10: KeyID.f10,
  Win32VK.f11: KeyID.f11,
  Win32VK.f12: KeyID.f12,

  Win32VK.snapshot: KeyID.snapshot,
  Win32VK.scroll: KeyID.scroll,
  Win32VK.pause: KeyID.pause,

  Win32VK.backspace: KeyID.backspace,
  Win32VK.tab: KeyID.tab,
  Win32VK.enter: KeyID.enter,
  Win32VK.capital: KeyID.capital,

  Win32VK.lshift: KeyID.lshift,
  Win32VK.rshift: KeyID.rshift,
  Win32VK.lcontrol: KeyID.lcontrol,
  Win32VK.rcontrol: KeyID.rcontrol,
  Win32VK.lmenu: KeyID.lmenu,
  Win32VK.rmenu: KeyID.rmenu,

  Win32VK.insert: KeyID.insert,
  Win32VK.delete: KeyID.delete,
  Win32VK.home: KeyID.home,
  Win32VK.end: KeyID.end,
  Win32VK.pageUp: KeyID.pageUp,
  Win32VK.pageDown: KeyID.pageDown,

  Win32VK.left: KeyID.left,
  Win32VK.up: KeyID.up,
  Win32VK.right: KeyID.right,
  Win32VK.down: KeyID.down,

  Win32VK.numlock: KeyID.numlock,
  Win32VK.numpadDivide: KeyID.numpadDivide,
  Win32VK.numpadMultiply: KeyID.numpadMultiply,
  Win32VK.numpadSubtract: KeyID.numpadSubtract,
  Win32VK.numpadAdd: KeyID.numpadAdd,
  //      numpadEnter doesn't have a unique VK code; it must be detected by checking the enhancedKey bit on the key record
  Win32VK.numpadDecimal: KeyID.numpadDecimal,
  Win32VK.numpad0: KeyID.numpad0,
  Win32VK.numpad1: KeyID.numpad1,
  Win32VK.numpad2: KeyID.numpad2,
  Win32VK.numpad3: KeyID.numpad3,
  Win32VK.numpad4: KeyID.numpad4,
  Win32VK.numpad5: KeyID.numpad5,
  Win32VK.numpad6: KeyID.numpad6,
  Win32VK.numpad7: KeyID.numpad7,
  Win32VK.numpad8: KeyID.numpad8,
  Win32VK.numpad9: KeyID.numpad9,
};
