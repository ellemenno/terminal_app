/// [KeyID] to byte list lookup table for key presses of non-printing keys
/// use: `final List<int> bytes = keyToPressBytes[keyID.index];`
const List<List<int>> keyToPressBytes = <List<int>>[
  EscSeq.escapeP,

  EscSeq.f1P,
  EscSeq.f2P,
  EscSeq.f3P,
  EscSeq.f4P,
  EscSeq.f5P,
  EscSeq.f6P,
  EscSeq.f7P,
  EscSeq.f8P,
  EscSeq.f9P,
  EscSeq.f10P,
  EscSeq.f11P,
  EscSeq.f12P,

  EscSeq.snapshotP,
  EscSeq.scrollP,
  EscSeq.pauseP,

  EscSeq.backspaceP,
  EscSeq.tabP,
  EscSeq.enterP,
  EscSeq.capitalP,

  EscSeq.lshiftP,
  EscSeq.rshiftP,
  EscSeq.lcontrolP,
  EscSeq.rcontrolP,
  EscSeq.lmenuP,
  EscSeq.rmenuP,

  EscSeq.insertP,
  EscSeq.deleteP,
  EscSeq.homeP,
  EscSeq.endP,
  EscSeq.pageUpP,
  EscSeq.pageDownP,

  EscSeq.leftP,
  EscSeq.upP,
  EscSeq.rightP,
  EscSeq.downP,

  EscSeq.numlockP,
  EscSeq.numpadDivideP,
  EscSeq.numpadMultiplyP,
  EscSeq.numpadSubtractP,
  EscSeq.numpadAddP,
  EscSeq.numpadEnterP,
  EscSeq.numpadDecimalP,
  EscSeq.numpad0P,
  EscSeq.numpad1P,
  EscSeq.numpad2P,
  EscSeq.numpad3P,
  EscSeq.numpad4P,
  EscSeq.numpad5P,
  EscSeq.numpad6P,
  EscSeq.numpad7P,
  EscSeq.numpad8P,
  EscSeq.numpad9P,
];

/// [KeyID] to byte list lookup table for releases of non-printing keys
/// use: `final List<int> bytes = keyToReleaseBytes[keyID.index];`
const List<List<int>> keyToReleaseBytes = <List<int>>[
  EscSeq.escapeR,

  EscSeq.f1R,
  EscSeq.f2R,
  EscSeq.f3R,
  EscSeq.f4R,
  EscSeq.f5R,
  EscSeq.f6R,
  EscSeq.f7R,
  EscSeq.f8R,
  EscSeq.f9R,
  EscSeq.f10R,
  EscSeq.f11R,
  EscSeq.f12R,

  EscSeq.snapshotR,
  EscSeq.scrollR,
  EscSeq.pauseR,

  EscSeq.backspaceR,
  EscSeq.tabR,
  EscSeq.enterR,
  EscSeq.capitalR,

  EscSeq.lshiftR,
  EscSeq.rshiftR,
  EscSeq.lcontrolR,
  EscSeq.rcontrolR,
  EscSeq.lmenuR,
  EscSeq.rmenuR,

  EscSeq.insertR,
  EscSeq.deleteR,
  EscSeq.homeR,
  EscSeq.endR,
  EscSeq.pageUpR,
  EscSeq.pageDownR,

  EscSeq.leftR,
  EscSeq.upR,
  EscSeq.rightR,
  EscSeq.downR,

  EscSeq.numlockR,
  EscSeq.numpadDivideR,
  EscSeq.numpadMultiplyR,
  EscSeq.numpadSubtractR,
  EscSeq.numpadAddR,
  EscSeq.numpadEnterR,
  EscSeq.numpadDecimalR,
  EscSeq.numpad0R,
  EscSeq.numpad1R,
  EscSeq.numpad2R,
  EscSeq.numpad3R,
  EscSeq.numpad4R,
  EscSeq.numpad5R,
  EscSeq.numpad6R,
  EscSeq.numpad7R,
  EscSeq.numpad8R,
  EscSeq.numpad9R,
];

/// byte sequences for non-printing keyboard keys.
///
/// matches the Kitty Keyboard Protocol with all enhancements enabled (`0b11111` = `CSI > 31 u`)
/// to report all keys as escape codes for press and release:
/// https://sw.kovidgoyal.net/kitty/keyboard-protocol/#report-all-keys-as-escape-codes
///
/// sequences for non-printing character are pre-defined as constants, in press (`*P`) and release (`*R`) variants.
class EscSeq {
  /// generate a sequence of bytes following Kitty Keyboard Protocol to represent a key event:
  ///
  /// ```
  /// CSI       key-code:    alternate-key-codes     ;    modifiers :    type ;    text     u
  ///  .         .            .                            .              .         .       .
  /// ╭┴──────╮ ╭┴─────────╮ ╭┴─────────────────────────╮ ╭┴───────────╮ ╭┴──────╮ ╭┴────╮ ╭┴─╮
  ///
  /// ESC  [    keyRune :    shiftRune :    baseRune ;    modifiers :    type ;    txtRune u
  /// ---- ---- ------- ---- --------- ---- -------- ---- --------- ---- ---- ---- ------- ----
  /// 0x1b 0x5b keyRune 0x3a shiftRune 0x3a baseRune 0x3b modifiers 0x3a type 0x3b txtRune 0x75
  /// ```
  ///
  /// there are four different rune values (unicode code points) that can be supplied:
  /// - [keyRune] - the unshifted character represented by the key, e.g. `1` when the `[1 !]` key is pressed
  /// - [shiftRune] - the shifted character represented by the key, e.g. `!` when the `[1 !]` key is pressed while the shift modifier key is held down
  /// - [baseRune] - the physical key of the keyboard, before regional layout mapping converts it to `keyRune`, e.g. `z` for the bottom-left key labeled `Y` on a German QWERTZ layout
  /// - [txtRune] - the display text implied by the key event, e.g. a shifted or accented character
  ///
  /// ..but only the `keyRune` byte is required, and optional bytes are omitted if they match defaults.
  ///
  /// [mods] is an integer formed by ANDing bit flags together and adding 1 (e.g. ctrl+shift = 6); see also [ModFlags] for assistance:
  /// ```
  /// none      0b00000000 (0)   +1 =   1  (default)
  /// shift     0b00000001 (1)   +1 =   2
  /// alt       0b00000010 (2)   +1 =   3  mac: ⌥ Option
  /// ctrl      0b00000100 (4)   +1 =   5
  /// super     0b00001000 (8)   +1 =   9  mac: ⌘ Command, win: ⊞ Windows
  /// hyper     0b00010000 (16)  +1 =  17
  /// meta      0b00100000 (32)  +1 =  33
  /// caps_lock 0b01000000 (64)  +1 =  65
  /// num_lock  0b10000000 (128) +1 = 129
  /// ```
  /// https://sw.kovidgoyal.net/kitty/keyboard-protocol/#modifiers
  ///
  /// [type] is `1` for press (default), `2` for repeat, `3` for release.
  /// https://sw.kovidgoyal.net/kitty/keyboard-protocol/#event-types
  static List<int> kittyEventBytes(
    int keyRune, {
    int shiftRune = 0,
    int baseRune = 0,
    int mods = 1,
    int type = 1,
    int txtRune = 0,
  }) {
    // FIXME: runes, mods, type all need to be converted to decimal and emitted as individual digits
    final List<int> bytes = <int>[0x1b, 0x5b, keyRune];
    if (shiftRune > 0) {
      bytes.add(0x3a);
      bytes.add(shiftRune);
    }
    if (baseRune > 0) {
      bytes.add(0x3a);
      bytes.add(baseRune);
    }
    if (mods > 1) {
      bytes.add(0x3b);
      bytes.add(mods);
    }
    if (type > 1) {
      bytes.add(0x3a);
      bytes.add(type);
    }
    if (txtRune > 0) {
      bytes.add(0x3a);
      bytes.add(txtRune);
    }
    bytes.add(0x75);
    return bytes;
  }

  // TODO: find a less littery way to work with printable characters than creating lots of lists
  //       so far, opting not to pre-define since that would require enumerating all keyboard layouts
  //       but maybe lists could be pre-allocated (max 14 entries) and re-used

  /// convenience method to retrieve kitty protocol bytes for the press of a common printable key
  static List<int> charPressBytes(int rune) =>
      kittyEventBytes(rune, txtRune: rune); // ESC [ <rune> ; ; <rune> u

  /// convenience method to retrieve kitty protocol bytes for the release of a common printable key
  static List<int> charReleaseBytes(int rune) =>
      kittyEventBytes(rune, type: 3); // ESC [ <rune> ; 1 : 3 u

  static const List<int> escapeP = <int>[0x1b, 0x5b, 0x1b, 0x75]; // ESC [ 27 u
  static const List<int> escapeR = <int>[
    0x1b,
    0x5b,
    0x1b,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 27 ; 1 : 3 u

  static const List<int> f1P = <int>[0x1b, 0x5b, 0x50]; // ESC [ P
  static const List<int> f1R = <int>[
    0x1b,
    0x5b,
    0x01,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x50,
  ]; // ESC [ 1 ; 1 : 3 P
  static const List<int> f2P = <int>[0x1b, 0x5b, 0x51]; // ESC [ Q
  static const List<int> f2R = <int>[
    0x1b,
    0x5b,
    0x01,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x51,
  ]; // ESC [ 1 ; 1 : 3 Q
  static const List<int> f3P = <int>[0x1b, 0x5b, 0x0d, 0x7e]; // ESC [ 13 ~
  static const List<int> f3R = <int>[
    0x1b,
    0x5b,
    0x0d,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x7e,
  ]; // ESC [ 13 ; 1 : 3 ~
  static const List<int> f4P = <int>[0x1b, 0x5b, 0x53]; // ESC [ S
  static const List<int> f4R = <int>[
    0x1b,
    0x5b,
    0x01,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x53,
  ]; // ESC [ 1 ; 1 : 3 S
  static const List<int> f5P = <int>[0x1b, 0x5b, 0x0f, 0x7e]; // ESC [ 15 ~
  static const List<int> f5R = <int>[
    0x1b,
    0x5b,
    0x0f,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x7e,
  ]; // ESC [ 15 ; 1 : 3 ~
  static const List<int> f6P = <int>[0x1b, 0x5b, 0x11, 0x7e]; // ESC [ 17 ~
  static const List<int> f6R = <int>[
    0x1b,
    0x5b,
    0x11,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x7e,
  ]; // ESC [ 17 ; 1 : 3 ~
  static const List<int> f7P = <int>[0x1b, 0x5b, 0x12, 0x7e]; // ESC [ 18 ~
  static const List<int> f7R = <int>[
    0x1b,
    0x5b,
    0x12,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x7e,
  ]; // ESC [ 18 ; 1 : 3 ~
  static const List<int> f8P = <int>[0x1b, 0x5b, 0x13, 0x7e]; // ESC [ 19 ~
  static const List<int> f8R = <int>[
    0x1b,
    0x5b,
    0x13,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x7e,
  ]; // ESC [ 19 ; 1 : 3 ~
  static const List<int> f9P = <int>[0x1b, 0x5b, 0x14, 0x7e]; // ESC [ 20 ~
  static const List<int> f9R = <int>[
    0x1b,
    0x5b,
    0x14,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x7e,
  ]; // ESC [ 20 ; 1 : 3 ~
  static const List<int> f10P = <int>[0x1b, 0x5b, 0x15, 0x7e]; // ESC [ 21 ~
  static const List<int> f10R = <int>[
    0x1b,
    0x5b,
    0x15,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x7e,
  ]; // ESC [ 21 ; 1 : 3 ~
  static const List<int> f11P = <int>[0x1b, 0x5b, 0x17, 0x7e]; // ESC [ 23 ~
  static const List<int> f11R = <int>[
    0x1b,
    0x5b,
    0x17,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x7e,
  ]; // ESC [ 23 ; 1 : 3 ~
  static const List<int> f12P = <int>[0x1b, 0x5b, 0x18, 0x7e]; // ESC [ 24 ~
  static const List<int> f12R = <int>[
    0x1b,
    0x5b,
    0x18,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x7e,
  ]; // ESC [ 24 ; 1 : 3 ~

  static const List<int> snapshotP = <int>[0x1b, 0x5b, 0xe011, 0x75]; // ESC [ 57361 u
  static const List<int> snapshotR = <int>[
    0x1b,
    0x5b,
    0xe011,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 57361 ; 1 : 3 u
  static const List<int> scrollP = <int>[0x1b, 0x5b, 0xe00f, 0x75]; // ESC [ 57359 u
  static const List<int> scrollR = <int>[
    0x1b,
    0x5b,
    0xe00f,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 57359 ; 1 : 3 u
  static const List<int> pauseP = <int>[0x1b, 0x5b, 0xe012, 0x75]; // ESC [ 57362 u
  static const List<int> pauseR = <int>[
    0x1b,
    0x5b,
    0xe012,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 57362 ; 1 : 3 u

  static const List<int> backspaceP = <int>[
    0x1b,
    0x5b,
    0x7f,
    0x75,
  ]; // ESC [ 127 u   | note:BS is 0x08, but keyboards send DEL 0x7f, and send ESC [ 3 ~ for DEL
  static const List<int> backspaceR = <int>[
    0x1b,
    0x5b,
    0x7f,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 127 ; 1 : 3 u
  static const List<int> tabP = <int>[0x1b, 0x5b, 0x09, 0x75]; // ESC [ 9 u
  static const List<int> tabR = <int>[
    0x1b,
    0x5b,
    0x09,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 9 ; 1 : 3 u
  static const List<int> enterP = <int>[0x1b, 0x5b, 0x0d, 0x75]; // ESC [ 13 u
  static const List<int> enterR = <int>[
    0x1b,
    0x5b,
    0x0d,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 13 ; 1 : 3 u
  static const List<int> capitalP = <int>[
    0x1b,
    0x5b,
    0xe00e,
    0x3b,
    0x41,
    0x75,
  ]; // ESC [ 57358 ; 65 u
  static const List<int> capitalR = <int>[
    0x1b,
    0x5b,
    0xe00e,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 57358 ; 1 : 3 u

  static const List<int> lshiftP = <int>[0x1b, 0x5b, 0xe061, 0x3b, 0x02, 0x75]; // ESC [ 57441 ; 2 u
  static const List<int> lshiftR = <int>[
    0x1b,
    0x5b,
    0xe061,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 57441 ; 1 : 3 u
  static const List<int> rshiftP = <int>[0x1b, 0x5b, 0xe067, 0x3b, 0x02, 0x75]; // ESC [ 57447 ; 2 u
  static const List<int> rshiftR = <int>[
    0x1b,
    0x5b,
    0xe067,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 57447 ; 1 : 3 u
  static const List<int> lcontrolP = <int>[
    0x1b,
    0x5b,
    0xe062,
    0x3b,
    0x02,
    0x75,
  ]; // ESC [ 57442 ; 2 u
  static const List<int> lcontrolR = <int>[
    0x1b,
    0x5b,
    0xe062,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 57442 ; 1 : 3 u
  static const List<int> rcontrolP = <int>[
    0x1b,
    0x5b,
    0xe068,
    0x3b,
    0x02,
    0x75,
  ]; // ESC [ 57448 ; 2 u
  static const List<int> rcontrolR = <int>[
    0x1b,
    0x5b,
    0xe068,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 57448 ; 1 : 3 u
  static const List<int> lmenuP = <int>[0x1b, 0x5b, 0xe063, 0x3b, 0x02, 0x75]; // ESC [ 57443 ; 2 u
  static const List<int> lmenuR = <int>[
    0x1b,
    0x5b,
    0xe063,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 57443 ; 1 : 3 u
  static const List<int> rmenuP = <int>[0x1b, 0x5b, 0xe069, 0x3b, 0x02, 0x75]; // ESC [ 57449 ; 2 u
  static const List<int> rmenuR = <int>[
    0x1b,
    0x5b,
    0xe069,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 57449 ; 1 : 3 u

  static const List<int> insertP = <int>[0x1b, 0x5b, 0x02, 0x7e]; // ESC [ 2 ~
  static const List<int> insertR = <int>[
    0x1b,
    0x5b,
    0x02,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x7e,
  ]; // ESC [ 2 ; 1 : 3 ~
  static const List<int> deleteP = <int>[0x1b, 0x5b, 0x03, 0x7e]; // ESC [ 3 ~
  static const List<int> deleteR = <int>[
    0x1b,
    0x5b,
    0x03,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x7e,
  ]; // ESC [ 3 ; 1 : 3 ~
  static const List<int> homeP = <int>[0x1b, 0x5b, 0x48]; // ESC [ H
  static const List<int> homeR = <int>[
    0x1b,
    0x5b,
    0x01,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x48,
  ]; // ESC [ 1 ; 1 : 3 H
  static const List<int> endP = <int>[0x1b, 0x5b, 0x46]; // ESC [ F
  static const List<int> endR = <int>[
    0x1b,
    0x5b,
    0x01,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x46,
  ]; // ESC [ 1 ; 1 : 3 F
  static const List<int> pageUpP = <int>[0x1b, 0x5b, 0x05, 0x7e]; // ESC [ 5 ~
  static const List<int> pageUpR = <int>[
    0x1b,
    0x5b,
    0x05,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x7e,
  ]; // ESC [ 5 ; 1 : 3 ~
  static const List<int> pageDownP = <int>[0x1b, 0x5b, 0x06, 0x7e]; // ESC [ 6 ~
  static const List<int> pageDownR = <int>[
    0x1b,
    0x5b,
    0x06,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x7e,
  ]; // ESC [ 6 ; 1 : 3 ~

  static const List<int> leftP = <int>[0x1b, 0x5b, 0x44]; // ESC [ D
  static const List<int> leftR = <int>[
    0x1b,
    0x5b,
    0x01,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x44,
  ]; // ESC [ 1 ; 1 : 3 D
  static const List<int> upP = <int>[0x1b, 0x5b, 0x41]; // ESC [ A
  static const List<int> upR = <int>[
    0x1b,
    0x5b,
    0x01,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x41,
  ]; // ESC [ 1 ; 1 : 3 A
  static const List<int> rightP = <int>[0x1b, 0x5b, 0x43]; // ESC [ C
  static const List<int> rightR = <int>[
    0x1b,
    0x5b,
    0x01,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x43,
  ]; // ESC [ 1 ; 1 : 3 C
  static const List<int> downP = <int>[0x1b, 0x5b, 0x42]; // ESC [ B
  static const List<int> downR = <int>[
    0x1b,
    0x5b,
    0x01,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x42,
  ]; // ESC [ 1 ; 1 : 3 B

  static const List<int> numlockP = <int>[0x1b, 0x5b, 0xe010, 0x75]; // ESC [ 57360 u
  static const List<int> numlockR = <int>[
    0x1b,
    0x5b,
    0xe010,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 57360 ; 1 : 3 u
  static const List<int> numpadDivideP = <int>[
    0x1b,
    0x5b,
    0xe042,
    0x3b,
    0x3b,
    0x2f,
    0x75,
  ]; // ESC [ 57410 ; ; 47 u
  static const List<int> numpadDivideR = <int>[
    0x1b,
    0x5b,
    0xe042,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 57410 ; 1 : 3 u
  static const List<int> numpadMultiplyP = <int>[
    0x1b,
    0x5b,
    0xe043,
    0x3b,
    0x3b,
    0x2a,
    0x75,
  ]; // ESC [ 57411 ; ; 42 u
  static const List<int> numpadMultiplyR = <int>[
    0x1b,
    0x5b,
    0xe043,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 57411 ; 1 : 3 u
  static const List<int> numpadSubtractP = <int>[
    0x1b,
    0x5b,
    0xe044,
    0x3b,
    0x3b,
    0x2d,
    0x75,
  ]; // ESC [ 57412 ; ; 45 u
  static const List<int> numpadSubtractR = <int>[
    0x1b,
    0x5b,
    0xe044,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 57412 ; 1 : 3 u
  static const List<int> numpadAddP = <int>[
    0x1b,
    0x5b,
    0xe043,
    0x3b,
    0x3b,
    0x2b,
    0x75,
  ]; // ESC [ 57413 ; ; 43 u
  static const List<int> numpadAddR = <int>[
    0x1b,
    0x5b,
    0xe043,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 57413 ; 1 : 3 u
  static const List<int> numpadEnterP = <int>[0x1b, 0x5b, 0xe046, 0x75]; // ESC [ 57414 u
  static const List<int> numpadEnterR = <int>[
    0x1b,
    0x5b,
    0xe046,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 57414 ; 1 : 3 u
  static const List<int> numpadDecimalP = <int>[
    0x1b,
    0x5b,
    0xe041,
    0x3b,
    0x3b,
    0x2e,
    0x75,
  ]; // ESC [ 57409 ; ; 46 u
  static const List<int> numpadDecimalR = <int>[
    0x1b,
    0x5b,
    0xe041,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 57409 ; 1 : 3 u
  static const List<int> numpad0P = <int>[
    0x1b,
    0x5b,
    0xe037,
    0x3b,
    0x3b,
    0x30,
    0x75,
  ]; // ESC [ 57399 ; ; 48 u
  static const List<int> numpad0R = <int>[
    0x1b,
    0x5b,
    0xe037,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 57399 ; 1 : 3 u
  static const List<int> numpad1P = <int>[
    0x1b,
    0x5b,
    0xe038,
    0x3b,
    0x3b,
    0x31,
    0x75,
  ]; // ESC [ 57400 ; ; 49 u
  static const List<int> numpad1R = <int>[
    0x1b,
    0x5b,
    0xe038,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 57400 ; 1 : 3 u
  static const List<int> numpad2P = <int>[
    0x1b,
    0x5b,
    0xe039,
    0x3b,
    0x3b,
    0x32,
    0x75,
  ]; // ESC [ 57401 ; ; 50 u
  static const List<int> numpad2R = <int>[
    0x1b,
    0x5b,
    0xe039,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 57401 ; 1 : 3 u
  static const List<int> numpad3P = <int>[
    0x1b,
    0x5b,
    0xe03a,
    0x3b,
    0x3b,
    0x33,
    0x75,
  ]; // ESC [ 57402 ; ; 51 u
  static const List<int> numpad3R = <int>[
    0x1b,
    0x5b,
    0xe03a,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 57402 ; 1 : 3 u
  static const List<int> numpad4P = <int>[
    0x1b,
    0x5b,
    0xe03b,
    0x3b,
    0x3b,
    0x34,
    0x75,
  ]; // ESC [ 57403 ; ; 52 u
  static const List<int> numpad4R = <int>[
    0x1b,
    0x5b,
    0xe03b,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 57403 ; 1 : 3 u
  static const List<int> numpad5P = <int>[
    0x1b,
    0x5b,
    0xe03c,
    0x3b,
    0x3b,
    0x35,
    0x75,
  ]; // ESC [ 57404 ; ; 53 u
  static const List<int> numpad5R = <int>[
    0x1b,
    0x5b,
    0xe03c,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 57404 ; 1 : 3 u
  static const List<int> numpad6P = <int>[
    0x1b,
    0x5b,
    0xe03d,
    0x3b,
    0x3b,
    0x36,
    0x75,
  ]; // ESC [ 57405 ; ; 54 u
  static const List<int> numpad6R = <int>[
    0x1b,
    0x5b,
    0xe03d,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 57405 ; 1 : 3 u
  static const List<int> numpad7P = <int>[
    0x1b,
    0x5b,
    0xe03e,
    0x3b,
    0x3b,
    0x37,
    0x75,
  ]; // ESC [ 57406 ; ; 55 u
  static const List<int> numpad7R = <int>[
    0x1b,
    0x5b,
    0xe03e,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 57406 ; 1 : 3 u
  static const List<int> numpad8P = <int>[
    0x1b,
    0x5b,
    0xe03f,
    0x3b,
    0x3b,
    0x38,
    0x75,
  ]; // ESC [ 57407 ; ; 56 u
  static const List<int> numpad8R = <int>[
    0x1b,
    0x5b,
    0xe03f,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 57407 ; 1 : 3 u
  static const List<int> numpad9P = <int>[
    0x1b,
    0x5b,
    0xe040,
    0x3b,
    0x3b,
    0x39,
    0x75,
  ]; // ESC [ 57408 ; ; 57 u
  static const List<int> numpad9R = <int>[
    0x1b,
    0x5b,
    0xe040,
    0x3b,
    0x01,
    0x3a,
    0x03,
    0x75,
  ]; // ESC [ 57408 ; 1 : 3 u
}
