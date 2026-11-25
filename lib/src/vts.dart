/// utilities to work with virtual terminal code sequences (i.e. ANSI escape codes)
///
/// ANSI references:
/// - C0 defined in ECMA-6: https://ecma-international.org/publications-and-standards/standards/ecma-6/
/// - C1 defined in ECMA-48: https://ecma-international.org/publications-and-standards/standards/ecma-48/
/// - general:
///   - https://ansi.tools/lookup
///   - https://ghostty.org/docs/vt/concepts/sequences
library;

/// ANSI Escape `0x1b`
const String esc = '\x1b';

/// ANSI C1 `0x8e` - Single Shift Two ` ESC N `
const String ss2 = '${esc}N';

/// ANSI C1 `0x8f` - Single Shift Three ` ESC O `
const String ss3 = '${esc}O';

/// ANSI C1 `0x90` - Device Control Sequence ` ESC P `
const String dcs = '${esc}P';

/// ANSI C1 `0x9b` - Control Sequence Introducer ` ESC [ `
const String csi = '${esc}[';

/// ANSI C1 `0x9c` - String Terminator ` ESC \ `
const String st = '${esc}\\';

/// Legacy xterm String Terminator ` BEL `
const String st7 = '\x07';

/// ANSI C1 `0x9d` - Operating System Command ` ESC ] `
const String osc = '${esc}]';

/// ANSI C1 `0x9f` - Application Program Command ` ESC _ `
const String apc = '${esc}_';

/// DEC command `1049h` - enable alternate screen buffer (cursor save/restore):
///```
/// ESC [ ? 1 0 4 9 h
///```
const List<int> altScreenEnter = <int>[0x1b, 0x5b, 0x3f, 0x31, 0x30, 0x34, 0x39, 0x68];

/// DEC command `1049l` - disable alternate screen buffer (cursor save/restore):
///```
/// ESC [ ? 1 0 4 9 l
///```
const List<int> altScreenLeave = <int>[0x1b, 0x5b, 0x3f, 0x31, 0x30, 0x34, 0x39, 0x6c];

/// DEC command `25h` - enable show cursor:
///```
/// ESC [ ? 2 5 h
///```
const List<int> cursorShow = <int>[0x1b, 0x5b, 0x3f, 0x32, 0x35, 0x68];

/// DEC command `25l` - disable show cursor:
///```
/// ESC [ ? 2 5 l
///```
const List<int> cursorHide = <int>[0x1b, 0x5b, 0x3f, 0x32, 0x35, 0x6c];

/// CSI command `CUP` - move cursor pos:
///```
/// ESC [ <row> ; <col> H
///```
///
/// [col] and [row] value ranges are `[1..terminalColumns]` and `[1..terminalLines]`
String cursorPos({int col = 1, int row = 1}) => '${csi}${row};${col}H';

/// CSI command `2J` - selective erase: entire screen:
///```
/// ESC [ 2 J
///```
const List<int> screenClear = <int>[0x1b, 0x5b, 0x32, 0x4A];

/// Kitty Keyboard Protocol command `<1` - pop 1 entry from the flag stack:
/// ```
/// ESC [ < 1 u
/// ```
const List<int> kittyPop1 = <int>[0x1b, 0x5b, 0x3c, 0x31, 0x75];

/// ask if the terminal supports the Kitty Keyboard Protocol.
/// ```
/// ESC [ ? u ESC [ c
/// ```
///
/// the above is a combination of two queries, the second widely supported.
/// if only a response to the second is recieved, kitty is not supported:
/// ```
/// 1. ESC [ ? u  ==> CSI ? <flags> u                      (response ends in 'u')
/// 2. ESC [ c    ==> CSI ? 6 1 ; <attr1> ; .. <attrN> c   (response ends in 'c')
///
/// ```
///
/// ref:
/// - KKB (Kitty keyboard protocol) - `CSI ? u`
///   - https://sw.kovidgoyal.net/kitty/keyboard-protocol/#detection-of-support-for-this-protocol
///   - https://sw.kovidgoyal.net/kitty/keyboard-protocol/#progressive-enhancement
/// - DA1 (primary device attributes) - `CSI c`
///   - https://vt100.net/docs/vt510-rm/DA1.html
const List<int> kittyQuery = <int>[0x1b, 0x5b, 0x3f, 0x75, 0x1b, 0x5b, 0x63];

/// the find token value to use when submitting a [kittyQuery].
///
/// if the query is submitted, and the response returns [kittyYes] before a
/// [kittyNo] is seen,the Kitty Keyboard Protocol is supported.
const int kittyYes = 0x75; // 'u'.runes.first

/// the final token value to use when submitting a [kittyQuery].
///
/// if the query is submitted, and the response returns [kittyNo] before a
/// [kittyYes] is seen, the Kitty Keyboard Protocol is not supported.
const int kittyNo = 0x63; // 'c'runes.first

/// CSI Kitty Keyboard Protocol command `<` - pop [n] entries from the flag stack:
/// ```
/// ESC [ < <n> u
/// ```
///
/// see: https://sw.kovidgoyal.net/kitty/keyboard-protocol/#progressive-enhancement
String kittyPop({int n = 1}) => '${csi}<${n}u';

/// CSI Kitty Keyboard Protocol command `>` - push a [flags] entry onto the flag stack:
/// ```
/// ESC [ > <flags> u
/// ```
///
/// see: https://sw.kovidgoyal.net/kitty/keyboard-protocol/#progressive-enhancement
String kittyPush({int flags = 0}) => '${csi}>${flags}u';

/// OSC command `0`, `1`, or `2` - set window and/or icon titles, based on [mode]:
/// - `0` - set window title and icon name
/// - `1` - set icon name
/// - `2` - set window title
///
/// ```
/// ESC ] <mode> ; <title> ST
/// ```
String titleSet(String title, {int mode = 0}) => '${osc}${mode};${title}${st}';
