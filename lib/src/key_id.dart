/// platform agnostic identifiers for function keys that can be reported by
/// the [TerminalAppHost] and recognized by a [TerminalApp].
///
/// generally these identifiers refer to non-printing keys, with the exception
/// of the numeric keypad digits and operators.
///
/// may be found as part of a [KeyRecord].
///
/// _note:_ to access by index value directly:
/// ```dart
/// KeyID.values[idx];
/// ```
enum KeyID {
  // TODO: compare to flutter logicalKey labels
  // https://github.com/flutter/flutter/blob/main/packages/flutter/lib/src/services/keyboard_key.g.dart#L3054

  // TODO: just cover all the 104 keys on a standard 104-US-QWERTY layout,
  //       and then KeyRecord can always include an id (key) + modifiers and rune (character)

  /// indicates a non-function key, i.e. a printable key
  none,

  /// <kbd>Esc ⎋</kbd>, Escape - generates the escape character, `U+001B`, or `Ctrl+[`.
  /// typically interpreted as "stop", "cancel" or "exit".
  escape,

  /// <kbd>F1</kbd>, function key 1
  f1,

  /// <kbd>F2</kbd>, function key 2
  f2,

  /// <kbd>F3</kbd>, function key 3
  f3,

  /// <kbd>F4</kbd>, function key 4
  f4,

  /// <kbd>F5</kbd>, function key 5
  f5,

  /// <kbd>F6</kbd>, function key 6
  f6,

  /// <kbd>F7</kbd>, function key 7
  f7,

  /// <kbd>F8</kbd>, function key 8
  f8,

  /// <kbd>F9</kbd>, function key 9
  f9,

  /// <kbd>F10</kbd>, function key 10
  f10,

  /// <kbd>F11</kbd>, function key 11
  f11,

  /// <kbd>F12</kbd>, function key 12
  f12,

  /// <kbd>PrtScr</kbd>, Print Screen
  snapshot,

  /// <kbd>ScrLk</kbd>, Scroll Lock
  scroll,

  /// <kbd>Pause Break</kbd>, Pause
  pause,

  /// <kbd>Backspace ⌫</kbd> - delete character behind cursor (backward delete)
  /// see also [KeyID.delete].
  backspace,

  /// <kbd>Tab ↹</kbd> - move cursor to next tab stop or field, or complete partially entered input
  tab,

  /// <kbd>Enter ↩</kbd> (also <kbd>Return ↩</kbd> ) - add newline, accept selection, execute command.
  /// see also [KeyID.numpadEnter].
  enter,

  /// <kbd>CapsLock ⇪</kbd> - toggle between uppercase and lowercase letters
  capital,

  /// <kbd>Shift ⇧</kbd>, left side of keyboard - while pressed, toggle between uppercase and lowercase letters, expand selection or select multiple items.
  /// a modifier key; does not generate a glyph.
  lshift,

  /// <kbd>Shift ⇧</kbd>, right side of keyboard - while pressed, toggle between uppercase and lowercase letters, expand selection or select multiple items.
  /// a modifier key; does not generate a glyph.
  rshift,

  /// <kbd>Ctrl ⌃</kbd>, Control, left side of keyboard - paired with other keys to request special operations.
  /// a modifier key; does not generate a glyph.
  lcontrol,

  /// <kbd>Ctrl ⌃</kbd>, Control, right side of keyboard - paired with other keys to request special operations.
  /// a modifier key; does not generate a glyph
  rcontrol,

  /// <kbd>Alt ⌥</kbd>, Alternate (also <kbd>Opt ⌥</kbd>, Option on MacOS), left side of keyboard - paired with other keys to select alternate behavior.
  /// a modifier key; does not generate a glyph
  lmenu,

  /// <kbd>Alt ⌥</kbd>, Alternate (also <kbd>Opt ⌥</kbd>, Option on MacOS), right side of keyboard - paired with other keys to select alternate behavior.
  /// a modifier key; does not generate a glyph
  rmenu,

  /// <kbd>Ins</kbd>, Insert - toggle typing mode between overtype and insert; may change cursor appearance
  insert,

  /// <kbd>Del ⌦</kbd>, Delete - delete character ahead of cursor (forward delete)
  /// see also [KeyID.backspace].
  delete,

  /// <kbd>Home ⇱</kbd> - typically used to return the cursor to the beginning of the line.
  /// opposite of [KeyID.end].
  home,

  /// <kbd>End ⇲</kbd> - typically used to move the cursor to the end of the line.
  /// opposite of [KeyID.home].
  end,

  /// <kbd>PgUp ⇞</kbd>, Page Up - typically used to scroll up / back.
  /// opposite of [KeyID.pageDown].
  pageUp,

  /// <kbd>PgDn ⇟</kbd>, Page Down - typically used to scroll down / forward.
  /// opposite of [KeyID.pageUp].
  pageDown,

  /// <kbd>←</kbd>, Left - directional arrow left. typically used for cursor navigation.
  /// see also [KeyID.up], [KeyID.right], [KeyID.down].
  left,

  /// <kbd>↑</kbd>, Up - directional arrow up. typically used for cursor navigation.
  /// see also [KeyID.left], [KeyID.right], [KeyID.down].
  up,

  /// <kbd>→</kbd>, Right - directional arrow right. typically used for cursor navigation.
  /// see also [KeyID.left], [KeyID.up], [KeyID.down].
  right,

  /// <kbd>↓</kbd>, Down - directional arrow down. typically used for cursor navigation.
  /// see also [KeyID.left], [KeyID.up], [KeyID.right].
  down,

  /// <kbd>NumLk ⇭</kbd>, Number Lock - toggle number pad functionality.
  numlock,

  /// <kbd>/</kbd>, Divide - division key on the number pad.
  numpadDivide,

  /// <kbd>*</kbd>, Multiply - multiplication key on the number pad.
  numpadMultiply,

  /// <kbd>-</kbd>, Subtract - subtraction key on the number pad.
  numpadSubtract,

  /// <kbd>+</kbd>, Add - addition key on the number pad.
  numpadAdd,

  /// <kbd>Enter ↩</kbd> - enter key on the number pad.
  numpadEnter,

  /// <kbd>.</kbd>, Decimal - decimal separator key on the number pad (character may be locale-specific).
  /// when numlock is disabled, reports as [KeyID.numpadDelete].
  numpadDecimal,

  /// <kbd>0</kbd>, Zero - number pad zero key.
  /// when numlock is disabled, reports as [KeyID.numpadInsert].
  numpad0,

  /// <kbd>1</kbd>, One - number pad one key.
  /// when numlock is disabled, reports as [KeyID.numpadEnd].
  numpad1,

  /// <kbd>2</kbd>, Two - number pad two key.
  /// when numlock is disabled, reports as [KeyID.numpadDown].
  numpad2,

  /// <kbd>3</kbd>, Three - number pad three key.
  /// when numlock is disabled, reports as [KeyID.numpadPageDown].
  numpad3,

  /// <kbd>4</kbd>, Four - number pad four key.
  /// when numlock is disabled, reports as [KeyID.numpadLeft].
  numpad4,

  /// <kbd>5</kbd>, Five - number pad five key.
  numpad5,

  /// <kbd>6</kbd>, Six - number pad six key.
  /// when numlock is disabled, reports as [KeyID.numpadRight].
  numpad6,

  /// <kbd>7</kbd>, Seven - number pad seven key.
  /// when numlock is disabled, reports as [KeyID.numpadHome].
  numpad7,

  /// <kbd>8</kbd>, Eight - number pad eight key.
  /// when numlock is disabled, reports as [KeyID.numpadUp].
  numpad8,

  /// <kbd>9</kbd>, Nine - number pad nine key.
  /// when numlock is disabled, reports as [KeyID.numpadPageUp].
  numpad9,

  /// <kbd>Del ⌦</kbd>, Delete - number pad delete key.
  /// when numlock is enabled, reports as [KeyID.numpadDecimal].
  numpadDelete,

  /// <kbd>Ins</kbd>, Insert - number pad insert key.
  /// when numlock is enabled, reports as [KeyID.numpad0].
  numpadInsert,

  /// <kbd>End ⇲</kbd>, End - number pad end key.
  /// when numlock is enabled, reports as [KeyID.numpad1].
  numpadEnd,

  /// <kbd>↓</kbd>, Down - number pad down key.
  /// when numlock is enabled, reports as [KeyID.numpad2].
  numpadDown,

  /// <kbd>PgDn ⇟</kbd>, Page Down - number pad page down key.
  /// when numlock is enabled, reports as [KeyID.numpad3].
  numpadPageDown,

  /// when numlock is enabled, reports as [KeyID.numpad4].
  numpadLeft,

  /// Begin - number pad center key.
  /// not reported on all keyboards.
  /// when numlock is enabled, reports as [KeyID.numpad5].
  numpadBegin,

  /// <kbd>→</kbd>, Right - number pad directional arrow right.
  /// when numlock is enabled, reports as [KeyID.numpad6].
  numpadRight,

  /// <kbd>Home ⇱</kbd> - number pad Home key.
  /// when numlock is enabled, reports as [KeyID.numpad7].
  numpadHome,

  /// <kbd>↑</kbd>, Up - number pad directional arrow up.
  /// when numlock is enabled, reports as [KeyID.numpad8].
  numpadUp,

  /// <kbd>PgUp ⇞</kbd>, Page Up - number pad Page Up key.
  /// when numlock is enabled, reports as [KeyID.numpad9].
  numpadPageUp,
}
