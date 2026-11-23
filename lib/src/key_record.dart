import 'key_id.dart';
import 'ucd.dart' as ucd;

/// utility struct for holding and serializing keyboard modifier flags.
///
/// follows Kitty Keyboard Protocol conventions,
/// see: https://sw.kovidgoyal.net/kitty/keyboard-protocol/#modifiers
///
/// bit layout:
/// ```
///  76543210 bits
///  00000000
///  │││││││└╴hasShift  ⇧ Shift
///  ││││││└╴hasAlt     ⌥ Option (mac), Alt (win)
///  │││││└╴hasCtrl     ⌃ Control
///  ││││└╴hasSuper     ⌘ Command (mac), ⊞ Windows (win)
///  │││└╴hasHyper        (custom assignment)
///  ││└╴hasMeta          (custom assignment)
///  │└╴hasCaps         ⇪ Caps Lock
///  └╴hasNuml          ⇭ Num Lock
/// ```
class ModFlags {
  /// was one of the _Shift_ keys presssed?
  /// check [KeyID] to monitor left and right shift keys explicitly
  bool hasShift = false;

  /// was one of the _Alt_ keys presssed (_Option_ on mac)?
  /// check [KeyID] to monitor left and right alt keys explicitly
  bool hasAlt = false;

  /// was one of the _Control_ keys presssed?
  /// check [KeyID] to monitor left and right control keys explicitly
  bool hasCtrl = false;

  /// was a _Super_ key presssed (win: ⊞ _Windows_, mac: ⌘ _Command_)?
  /// check [KeyID] to monitor left and right super keys explicitly
  bool hasSuper = false;

  /// was a _Hyper_ key presssed?
  bool hasHyper = false;

  /// was a _Meta_ key presssed?
  bool hasMeta = false;

  /// is the _CapsLock_ key active?
  bool hasCaps = false;

  /// is the _NumLock_ key active?
  bool hasNuml = false;

  /// serialize to bits
  int get bits => ModFlags.toBits(this);

  /// serialize to bit string
  String get bitString => ModFlags.toBitString(bits);

  /// set all flags to false
  void clear() => ModFlags.clearFlags(this);

  /// set all flags to false
  static void clearFlags(ModFlags flags) => fromBits(0, flags);

  /// serialize from struct to bits
  static int toBits(ModFlags flags) =>
      0x00 |
      (flags.hasShift ? 0x01 : 0) |
      (flags.hasAlt ? 0x02 : 0) |
      (flags.hasCtrl ? 0x04 : 0) |
      (flags.hasSuper ? 0x08 : 0) |
      (flags.hasHyper ? 0x10 : 0) |
      (flags.hasMeta ? 0x20 : 0) |
      (flags.hasCaps ? 0x40 : 0) |
      (flags.hasNuml ? 0x80 : 0);

  /// deserialize from bits to struct
  static void fromBits(int bits, ModFlags flags) {
    flags.hasShift = (bits & 0x01 == 0x01);
    flags.hasAlt = (bits & 0x02 == 0x02);
    flags.hasCtrl = (bits & 0x04 == 0x04);
    flags.hasSuper = (bits & 0x08 == 0x08);
    flags.hasHyper = (bits & 0x10 == 0x10);
    flags.hasMeta = (bits & 0x20 == 0x20);
    flags.hasCaps = (bits & 0x40 == 0x40);
    flags.hasNuml = (bits & 0x80 == 0x80);
  }

  /// generate a binary string of `0`s and `1`s from the given [bits].
  static String toBitString(int bits, {int depth = 8}) => bits.toRadixString(2).padLeft(depth, '0');

  /// generate a summary string representation of the given [flags].
  static String toSummary(ModFlags flags) {
    final StringBuffer sb = StringBuffer();
    if (flags.hasShift) {
      sb.write('Shift+');
    }
    if (flags.hasAlt) {
      sb.write('Alt+');
    }
    if (flags.hasCtrl) {
      sb.write('Ctrl+');
    }
    if (flags.hasSuper) {
      sb.write('Super+');
    }
    if (flags.hasHyper) {
      sb.write('Hyper+');
    }
    if (flags.hasMeta) {
      sb.write('Meta+');
    }
    if (flags.hasCaps) {
      sb.write('Caps+');
    }
    if (flags.hasNuml) {
      sb.write('Numl+');
    }
    return sb.toString();
  }
}

/// platform agnostic bit record for keyboard events that can be reported by
/// the [TerminalAppHost] and recognized by a [TerminalApp].
///
/// provides storage and serialization of rune code, key id, and active modifiers,
/// sending all three values in a single 32-bit int.
///
/// serialization bit layout:
/// ```
///  1 00000000 0000000 0000000000000000      downMask = 0x80000000
///  0 11111111 0000000 0000000000000000      modsMask = 0x7f800000
///  0 00000000 1111111 0000000000000000        idMask = 0x007f0000
///  0 00000000 0000000 1111111111111111      runeMask = 0x0000ffff
///
///  0 00000000 0000000 0000000000000000      b
///  │ │        │       └╴printable rune =>   b & runeMask
///  │ │        └╴non-printing key enum  =>  (b & idMask) >>> idShift
///  │ └╴modifier flags                  =>  (b & modsMask) >>> modsShift
///  └╴is down (if 1)                    => ((b & downMask) >>> downShift) == 1
/// ```
///
/// when the rune is printable, key id will be [KeyID.none].
class KeyRecord {
  final ModFlags _modFlags;

  /// `true` when key is first pressed down, `false` when released up
  bool down;

  /// enum representing the key pressed or released.
  KeyID keyID;

  /// unicode code point for the character resulting from the key event.
  /// can be converted to String with `String.fromCharCode(rune)`.
  int rune;

  /// construct a new key record instance from values.
  KeyRecord(this._modFlags, {this.down = false, this.keyID = KeyID.none, this.rune = 0});

  /// deserialize a key record bit field in to a new key record instance.
  factory KeyRecord.fromBits(int bits) {
    final ModFlags flags = ModFlags();
    toFlags(bits, flags);
    return KeyRecord(flags, down: toDown(bits), keyID: toID(bits), rune: toRune(bits));
  }

  /// retrieve a struct holding the modifier values for this key event.
  ModFlags get modFlags => _modFlags;

  /// serialize the record info to bit flags in a 32-bit integer.
  int get bits => toBits(_modFlags, down: down, id: keyID, rune: rune);

  /// `true` if the record represents a C0 or C1 control code.
  bool get isControl => isControlCode(bits);

  /// `true` if the record represents a private use code.
  bool get isPrivateUse => isPrivateUseCode(bits);

  /// `true` if the record represents a printable string character.
  bool get isPrintable => isPrintableCode(bits);

  /// print the record as a binary string of `0`s and `1`s.
  String get bitString => toBitString(bits);

  /// generate a visualization string for the key record
  String get summary => toSummary(this);

  // 32 bits
  // -------
  //  1 bit to indicate press vs release
  //  8 bits needed for  8 modifier flags
  //  7 bits gives     128 values to id 65 non-printing keys (isPrintable can be computed when needed by checking rune range))
  // TODO: 7 bits is now enough for all 104 keys
  // 16 bits gives  65,536 values for keyboard-emittable printable glyphs in the Basic Multilingual Plane (BMP): unicode range of U+00020 to U+0ffff (65,503 chars)

  /// bitmask for the down bit
  static const int downMask = 0x80000000;

  /// bitshift for the down bit
  static const int downShift = 31;

  /// bitmask for the modifier bits
  static const int modsMask = 0x7f800000;

  /// bitshift for the modifier bits
  static const int modsShift = 23;

  /// bitmask for the key id bits
  static const int idMask = 0x007f0000;

  /// bitshift for the key id bits
  static const int idShift = 16;

  /// bitmask for the rune bits (no shift is needed as they are already the low bits)
  static const int runeMask = 0x0000ffff;

  /// check if encoded rune is a C0 or C1 control code
  static bool isControlCode(int bits) => ucd.isControlCode(bits & runeMask);

  /// check if encoded rune is from the unicode private use area
  static bool isPrivateUseCode(int bits) => ucd.isPrivateUseCode(bits & runeMask);

  /// check if encoded rune produces a printable string character.
  static bool isPrintableCode(int bits) => ucd.isPrintableCode(bits & runeMask);

  /// serialize key event info into KeyRecord bits.
  ///
  /// [flags] tracks active modifiers. use [id] for non-printing codes, and [rune] for printable glyphs
  /// throws [RangeError] if [rune] is out of valid unicode range as determined by [isValidUnicode()].
  static int toBits(ModFlags flags, {bool down = true, KeyID id = KeyID.none, int rune = 0}) {
    if (ucd.isNotValidUnicode(rune)) {
      ucd.invalidRune(rune);
    }
    final int bit = down ? 1 : 0;
    return (bit << downShift) |
        (ModFlags.toBits(flags) << modsShift) |
        (id.index << idShift) |
        rune;
  }

  /// deserialize the bit representing if the key is pressed down.
  static bool toDown(int bits) => (((bits & downMask) >>> downShift) == 1);

  /// deserialize the bits representing modifier flags.
  ///
  /// extracted flag values are set on the provided [ModFlags] object
  static void toFlags(int bits, ModFlags flags) {
    final int flagBits = (bits & modsMask) >>> modsShift;
    ModFlags.fromBits(flagBits, flags);
  }

  /// deserialize the bits representing key id.
  ///
  /// if the key record bits have the printable flag set, printable numpad keys will have an id, and all others will have [KeyID.none].
  static KeyID toID(int bits) {
    final int index = (bits & idMask) >>> idShift;
    return KeyID.values[index];
  }

  /// deserialize the bits representing rune (an integer character code `U+0000`..`U+FFFF`).
  ///
  /// see [ucd.getPrintableCode()] for converting runes to printable glyph codes.
  static int toRune(int bits) => bits & runeMask;

  /// generate a binary string of `0`s and `1`s from the given [bits].
  static String toBitString(int bits, {int depth = 32}) =>
      bits.toRadixString(2).padLeft(depth, '0');

  /// generate a summary string representation of the given [KeyRecord].
  ///
  /// string format is:
  /// ```
  /// ↓|↑ ●|◌ [modifiers]glyph KeyID codepoint
  /// ```
  ///
  /// ex:
  /// pressing the G key (a printable key, indicated with ●, followed by glyph,
  /// KeyID enum value, and codepoint in hexadeciaml format):
  /// `↓ ● g <none> 0x0067`
  /// releasing the G key
  /// `↑ ● g <none> 0x0067`
  /// pressing the left Control key (a non-printable key, indicated with ◌):
  /// `↓ ◌ Ctrl+G <lcontrol> 0x0000` //FIXME - kitty vs win
  /// `↓ ◌ Ctrl+␀ <lcontrol> 0x0000` //FIXME - win vs kitty
  /// pressing the left Control, Alt, Shift and G keys:
  /// `↓ ● Shift+Alt+Ctrl+G`               //FIXME - kitty vs win
  /// `↓ ◌ Shift+Alt+Ctrl+␀ <none> 0x0000` //FIXME - win vs kitty
  static String toSummary(KeyRecord keyRecord) {
    final int bits = keyRecord.bits;
    final int rune = toRune(bits);
    final bool down = toDown(bits);
    final bool printable = ucd.isPrintableCode(rune);
    final String flags = ModFlags.toSummary(keyRecord.modFlags);
    final String key = String.fromCharCode(ucd.getPrintableCode(rune));
    final String id = ' <${keyRecord.keyID.name}>';
    return '${down ? '↓' : '↑'} ${printable ? '●' : '◌'} ${flags}${key}${id} ${ucd.hexString(rune)}';
  }

  /// parse from list of kitty keyboard protocol bytes to [KeyRecord].
  ///
  /// expects byte sequences that follow the Kitty Keyboard Protocol with
  /// all enhancements enabled (`0b11111` = `CSI > 31 u`).
  /// https://sw.kovidgoyal.net/kitty/keyboard-protocol/#progressive-enhancement
  ///
  /// the Kitty keyboard protocol format for a key event record when all enhancements are enabled
  /// starts with the control sequence introducer (CSI), which is the bytes `\x1b` (`ESC`) and `\x5b` (`[`),
  /// followed by up to three fields separated by semi-colon `\x3b` (`;`), followed by `\x75` (`u`) or one of `~ABCDFHPQS`.
  /// the first two fields can have subfields separated by a colon `\x3a` (`:`).
  /// not all subfields or fields are present for every event:
  /// ```
  ///                 field 1 (key)                 field 2 (mod)         field 3 (txt)
  ///     ╭──────────────────────────────────╮   ╭──────────────────╮   ╭────────────────╮
  ///
  /// CSI unicode-key-code:alternate-key-codes ; modifiers:event-type ; text-as-codepoints u
  ///
  ///     ╰──────────────╯ ╰─────────────────╯   ╰───────╯ ╰────────╯
  ///       subfield 1.1   subfields 1.2 & 1.3      2.1       2.2
  /// ```
  /// https://sw.kovidgoyal.net/kitty/keyboard-protocol/#an-overview
  ///
  static void parseKittyKeyBytes(List<int> bytes, KeyRecord keyRecord, {bool debug = true}) {
    // set defaults
    keyRecord.keyID = KeyID.none;
    keyRecord.rune = 0;

    // all kitty codes will have at least three bytes, and start with CSI ( `ESC [`)
    final int n = bytes.length;
    if (n < 3 || bytes[0] != 0x1b || bytes[1] != 0x5b) {
      return;
    }

    //TODO: is there a smarter, more efficient way to do the parsing?

    // convert bytes after CSI and before terminal byte into string for processing
    // separate first into fields while running through bytes (this allows simpler handling of repeated delimiters)
    const int fieldSeparator = 0x3b; // ';'
    const String subfieldSeparator = ':';
    final StringBuffer keyField = StringBuffer();
    final StringBuffer modField = StringBuffer();
    final StringBuffer txtField = StringBuffer();
    final List<StringBuffer> fields = <StringBuffer>[keyField, modField, txtField];
    int f = 0;
    for (int b = 2; b < n - 1; b++) {
      if (bytes[b] == fieldSeparator) {
        f++;
        continue;
      }
      fields[f].writeCharCode(bytes[b]);
    }
    // extract terminating character (~ABCDFHPQSu) as final byte
    final String terminator = String.fromCharCode(bytes.last);

    // then separate fields into subfields
    final List<String> keys = keyField.isNotEmpty
        ? keyField.toString().split(subfieldSeparator)
        : <String>[];
    final List<String> mods = modField.isNotEmpty
        ? modField.toString().split(subfieldSeparator)
        : <String>[];
    final List<String> txt = txtField.isNotEmpty ? <String>[txtField.toString()] : <String>[];

    // set press / release boolean
    final bool isRelease = ((mods.length > 1) && (mods[1] == '3'));
    keyRecord.down = !isRelease;

    if (debug) {
      print(
        'kitty record: ${isRelease ? '↑' : '↓'} CSI key${keys} mod${mods} txt${txt} ${terminator}',
      );
    }

    // finally, retrieve rune and modifiers, and determine key id
    final int rune = (keys.isEmpty) ? 0 : int.parse(keys.first);
    final int modBits = (mods.isEmpty) ? 0 : int.parse(mods.first);
    ModFlags.fromBits((modBits > 0) ? modBits - 1 : 0, keyRecord.modFlags);

    // printing keys have KeyID.none, just need the rune set
    if (ucd.isNotControlCode(rune) && ucd.isNotPrivateUseCode(rune)) {
      keyRecord.rune = rune;
      return;
    }

    // non-printing keys need to be mapped to KeyID enum values
    if (terminator == '~') {
      switch (rune) {
        case 13:
          keyRecord.keyID = KeyID.f3;
          return;
        case 15:
          keyRecord.keyID = KeyID.f5;
          return;
        case 17:
          keyRecord.keyID = KeyID.f6;
          return;
        case 18:
          keyRecord.keyID = KeyID.f7;
          return;
        case 19:
          keyRecord.keyID = KeyID.f8;
          return;
        case 20:
          keyRecord.keyID = KeyID.f9;
          return;
        case 21:
          keyRecord.keyID = KeyID.f10;
          return;
        case 23:
          keyRecord.keyID = KeyID.f11;
          return;
        case 24:
          keyRecord.keyID = KeyID.f12;
          return;
      }
      // no return here, since other matches are still possible
    } else if ((rune == 0 || rune == 1) && terminator != 'u') {
      // legacy letter terminators can appear for omitted runes that default to 0 (press), and for rune 1 (release)
      switch (terminator) {
        case 'A':
          keyRecord.keyID = KeyID.up;
          return;
        case 'B':
          keyRecord.keyID = KeyID.down;
          return;
        case 'C':
          keyRecord.keyID = KeyID.right;
          return;
        case 'D':
          keyRecord.keyID = KeyID.left;
          return;
        case 'E':
          keyRecord.keyID = KeyID.numpadBegin;
          return;
        case 'F':
          keyRecord.keyID = KeyID.end;
          return;
        case 'H':
          keyRecord.keyID = KeyID.home;
          return;
        case 'P':
          keyRecord.keyID = KeyID.f1;
          return;
        case 'Q':
          keyRecord.keyID = KeyID.f2;
          return;
        case 'R':
          keyRecord.keyID = KeyID.f3;
          return;
        case 'S':
          keyRecord.keyID = KeyID.f4;
          return;
      }
      // no return here, since other matches are still possible
    }

    switch (rune) {
      case 2:
        keyRecord.keyID = KeyID.insert;
        return;
      case 3:
        keyRecord.keyID = KeyID.delete;
        return;
      case 5:
        keyRecord.keyID = KeyID.pageUp;
        return;
      case 6:
        keyRecord.keyID = KeyID.pageDown;
        return;
      case 9:
        keyRecord.keyID = KeyID.tab;
        return;
      case 13:
        keyRecord.keyID = KeyID.enter; // '13 u', vs f3 key '13 ~' captured above
        return;
      case 27:
        keyRecord.keyID = KeyID.escape;
        return;
      case 127:
        keyRecord.keyID = KeyID.backspace;
        return;
      case 57358:
        keyRecord.keyID = KeyID.capital;
        return;
      case 57359:
        keyRecord.keyID = KeyID.scroll;
        return;
      case 57360:
        keyRecord.keyID = KeyID.numlock;
        return;
      case 57361:
        keyRecord.keyID = KeyID.snapshot;
        return;
      case 57362:
        keyRecord.keyID = KeyID.pause;
        return;
      case 57399:
        keyRecord.keyID = KeyID.numpad0;
        return;
      case 57400:
        keyRecord.keyID = KeyID.numpad1;
        return;
      case 57401:
        keyRecord.keyID = KeyID.numpad2;
        return;
      case 57402:
        keyRecord.keyID = KeyID.numpad3;
        return;
      case 57403:
        keyRecord.keyID = KeyID.numpad4;
        return;
      case 57404:
        keyRecord.keyID = KeyID.numpad5;
        return;
      case 57405:
        keyRecord.keyID = KeyID.numpad6;
        return;
      case 57406:
        keyRecord.keyID = KeyID.numpad7;
        return;
      case 57407:
        keyRecord.keyID = KeyID.numpad8;
        return;
      case 57408:
        keyRecord.keyID = KeyID.numpad9;
        return;
      case 57409:
        keyRecord.keyID = KeyID.numpadDecimal;
        return;
      case 57410:
        keyRecord.keyID = KeyID.numpadDivide;
        return;
      case 57411:
        keyRecord.keyID = KeyID.numpadMultiply;
        return;
      case 57412:
        keyRecord.keyID = KeyID.numpadSubtract;
        return;
      case 57413:
        keyRecord.keyID = KeyID.numpadAdd;
        return;
      case 57414:
        keyRecord.keyID = KeyID.numpadEnter;
        return;
      //case 57415: // numpad equals; not a standard 101 key; found on Mac numpads
      //case 57416: // numpad separator; locale version of numpad decimal; not sure how this works
      case 57417:
        keyRecord.keyID = KeyID.numpadLeft;
        return;
      case 57418:
        keyRecord.keyID = KeyID.numpadRight;
        return;
      case 57419:
        keyRecord.keyID = KeyID.numpadUp;
        return;
      case 57420:
        keyRecord.keyID = KeyID.numpadDown;
        return;
      case 57421:
        keyRecord.keyID = KeyID.numpadPageUp;
        // FIXME: reporting bytes correctly, but not creating a proper keyRecord (showing ◌ Shift+␀ <none>)
        return;
      case 57422:
        keyRecord.keyID = KeyID.numpadPageDown;
        return;
      case 57423:
        keyRecord.keyID = KeyID.numpadHome;
        return;
      case 57424:
        keyRecord.keyID = KeyID.numpadEnd;
        return;
      case 57425:
        keyRecord.keyID = KeyID.numpadInsert;
        return;
      case 57426:
        keyRecord.keyID = KeyID.numpadDelete;
        return;
      case 57427:
        keyRecord.keyID = KeyID.numpadBegin;
        return;
      case 57441:
        keyRecord.keyID = KeyID.lshift;
        return;
      case 57447:
        keyRecord.keyID = KeyID.rshift;
        return;
      case 57442:
        keyRecord.keyID = KeyID.lcontrol;
        return;
      case 57443:
        keyRecord.keyID = KeyID.lmenu;
        return;
      case 57448:
        keyRecord.keyID = KeyID.rcontrol;
        return;
      case 57449:
        keyRecord.keyID = KeyID.rmenu;
        return;
    }
  }

  /// parse from list of posix keyboard bytes to [KeyRecord].
  ///
  /// expects byte sequences that follow legacy posix conventions, i.e. xterm
  /// https://www.xfree86.org/current/ctlseqs.html
  static void parsePosixKeyBytes(List<int> bytes, KeyRecord keyRecord) {
    // set defaults
    keyRecord.keyID = KeyID.none;
    keyRecord.rune = 0;
    keyRecord.down = true;

    final int n = bytes.length;
    // single bytes indicate C0 control codes, but may have been typed as Ctrl + printable glyph
    if (n == 1) {
      keyRecord.rune = bytes[0];
      switch (bytes[0]) {
        case 0x08:
          keyRecord.keyID = KeyID.backspace; //  // also Ctrl + H
          keyRecord.rune = 0;
          return;
        case 0x09:
          keyRecord.keyID = KeyID.tab; // also Ctrl + I
          keyRecord.rune = 0;
          return;
        case 0x0a:
          keyRecord.keyID = KeyID.enter; // LF reported on linux; also Ctrl + J
          keyRecord.rune = 0;
          return;
        case 0x0d:
          keyRecord.keyID = KeyID.enter; // CR reported on windows; also Ctrl + M
          keyRecord.rune = 0;
          return;
        case 0x1b:
          keyRecord.keyID = KeyID.escape; // also Ctrl + [
          keyRecord.rune = 0;
          return;
        case >= 0 && < 0x20:
          keyRecord.modFlags.hasCtrl = true;
          keyRecord.rune = bytes[0] + 0x40;
          return;
        case >= 0x21 && <= 0x2b && != 0x27:
          // ! " # $ % & ' ( ) * +
          keyRecord.modFlags.hasShift = true;
          return;
        case >= 0x3a && <= 0x3f && != 0x3b && != 0x3d:
          // : ; < = > ?
          keyRecord.modFlags.hasShift = true;
          return;
        case >= 0x40 && <= 0x5a || == 0x5e || == 0x5f:
          // @ A B C D E F G H I J K L M N O P Q R S T U V W X Y Z  and  ^ _
          keyRecord.modFlags.hasShift = true;
          return;
        case >= 0x7b && <= 0x7e:
          // { | } ~
          keyRecord.modFlags.hasShift = true;
          return;
        case 0x7f:
          keyRecord.keyID = KeyID
              .backspace; // BS is 0x08, but some keyboards send DEL 0x7f, and send ESC [ 3 ~ for DEL
          keyRecord.rune = 0;
          return;
      }
      return;
    }

    // non-printing keys (C1 control codes) start with an introducer like [CSI] and must have 3 or more bytes
    if (n < 3 || bytes.first != 0x1b) {
      return;
    }

    // CSI sequences start with ` 0x1b 0x5b .. ` (` ESC [ ..`)
    if (bytes[1] == 0x5b) {
      switch (bytes[2]) {
        case 0x41:
          keyRecord.keyID = KeyID.up; //    [ 0x1b, 0x5b, 0x41 ] :: ESC [ A :: Up Arrow
          return;
        case 0x42:
          keyRecord.keyID = KeyID.down; //  [ 0x1b, 0x5b, 0x42 ] :: ESC [ B :: Down Arrow
          return;
        case 0x43:
          keyRecord.keyID = KeyID.right; // [ 0x1b, 0x5b, 0x43 ] :: ESC [ C :: Right Arrow
          return;
        case 0x44:
          keyRecord.keyID = KeyID.left; //  [ 0x1b, 0x5b, 0x44 ] :: ESC [ D :: Left Arrow
          return;
        case 0x46:
          keyRecord.keyID = KeyID.end; //   [ 0x1b, 0x5b, 0x46 ] :: ESC [ F :: End
          return;
        case 0x48:
          keyRecord.keyID = KeyID.home; //  [ 0x1b, 0x5b, 0x48 ] :: ESC [ H :: Home
          return;
        case 0x31:
          if (n == 5 && bytes.last == 0x7e) {
            switch (bytes[3]) {
              case 0x35:
                keyRecord.keyID = KeyID.f5; // [ 0x1b, 0x5b, 0x31, 0x35, 0x7e ] :: ESC [ 1 5 ~ :: F5
                return;
              case 0x37:
                keyRecord.keyID = KeyID.f6; // [ 0x1b, 0x5b, 0x31, 0x37, 0x7e ] :: ESC [ 1 7 ~ :: F6
                return;
              case 0x38:
                keyRecord.keyID = KeyID.f7; // [ 0x1b, 0x5b, 0x31, 0x38, 0x7e ] :: ESC [ 1 8 ~ :: F7
                return;
              case 0x39:
                keyRecord.keyID = KeyID.f8; // [ 0x1b, 0x5b, 0x31, 0x39, 0x7e ] :: ESC [ 1 9 ~ :: F8
                return;
            }
          }
          break;
        case 0x32:
          if (bytes.last == 0x7e) {
            if (n == 4) {
              keyRecord.keyID = KeyID.insert; //  [ 0x1b, 0x5b, 0x32, 0x7e ] :: ESC [ 2 ~ :: Insert
              return;
            }
            if (n == 5) {
              switch (bytes[3]) {
                case 0x30:
                  keyRecord.keyID =
                      KeyID.f9; //  [ 0x1b, 0x5b, 0x32, 0x30, 0x7e ] :: ESC [ 2 0 ~ :: F9
                  return;
                case 0x31:
                  keyRecord.keyID =
                      KeyID.f10; // [ 0x1b, 0x5b, 0x32, 0x31, 0x7e ] :: ESC [ 2 1 ~ :: F10
                  return;
                case 0x33:
                  keyRecord.keyID =
                      KeyID.f11; // [ 0x1b, 0x5b, 0x32, 0x33, 0x7e ] :: ESC [ 2 3 ~ :: F11
                  return;
                case 0x34:
                  keyRecord.keyID =
                      KeyID.f12; // [ 0x1b, 0x5b, 0x32, 0x34, 0x7e ] :: ESC [ 2 4 ~ :: F12
                  return;
              }
            }
          }
          break;
        case 0x33:
          if (n == 4 && bytes.last == 0x7e) {
            keyRecord.keyID = KeyID.delete; //   [ 0x1b, 0x5b, 0x33, 0x7e ] :: ESC [ 3 ~ :: Delete
            return;
          }
          break;
        case 0x35:
          if (n == 4 && bytes.last == 0x7e) {
            keyRecord.keyID = KeyID.pageUp; //   [ 0x1b, 0x5b, 0x35, 0x7e ] :: ESC [ 5 ~ :: PgUp
            return;
          }
          break;
        case 0x36:
          if (n == 4 && bytes.last == 0x7e) {
            keyRecord.keyID = KeyID.pageDown; // [ 0x1b, 0x5b, 0x36, 0x7e ] :: ESC [ 6 ~ :: PgDn
            return;
          }
          break;
      }
    }
    // SS3 sequences start with ` 0x1b 0x4f .. ` (` ESC O ..`)
    else if (bytes[1] == 0x4f) {
      switch (bytes[2]) {
        case 0x50:
          keyRecord.keyID = KeyID.f1; // [ 0x1b, 0x4f, 0x50 ] :: ESC O P :: F1
          return;
        case 0x51:
          keyRecord.keyID = KeyID.f2; // [ 0x1b, 0x4f, 0x51 ] :: ESC O Q :: F2
          return;
        case 0x52:
          keyRecord.keyID = KeyID.f3; // [ 0x1b, 0x4f, 0x52 ] :: ESC O R :: F3
          return;
        case 0x53:
          keyRecord.keyID = KeyID.f4; // [ 0x1b, 0x4f, 0x53 ] :: ESC O S :: F4
          return;
      }
    }
  }
}
