/// platform agnostic identifiers for function keys that can be reported by the [Terminal] and recognized by a [TerminalApp]
///
/// generally these identifiers refer to non-printing keys, with the exception of the numeric keypad digits and operators.
///
/// _note:_ to access by index value directly: `KeyID.values[idx];`
enum KeyID {
  none,

  escape,

  f1,
  f2,
  f3,
  f4,
  f5,
  f6,
  f7,
  f8,
  f9,
  f10,
  f11,
  f12,

  snapshot,
  scroll,
  pause,

  backspace,
  tab,
  enter,
  capital,

  lshift,
  rshift,
  lcontrol,
  rcontrol,
  lmenu,
  rmenu,

  insert,
  delete,
  home,
  end,
  pageUp,
  pageDown,

  left,
  up,
  right,
  down,

  numlock,
  numpadDivide,
  numpadMultiply,
  numpadSubtract,
  numpadAdd,
  numpadEnter,

  numpadDecimal,
  numpad0,
  numpad1,
  numpad2,
  numpad3,
  numpad4,
  numpad5,
  numpad6,
  numpad7,
  numpad8,
  numpad9,

  numpadDelete,
  numpadInsert,
  numpadEnd,
  numpadDown,
  numpadPageDown,
  numpadLeft,
  numpadBegin,
  numpadRight,
  numpadHome,
  numpadUp,
  numpadPageUp,
}
