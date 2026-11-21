/// utilities to work with virtual terminal code sequences (i.e. ANSI escape codes)
///
/// ANSI references:
/// - C0 defined in ECMA-6: https://ecma-international.org/publications-and-standards/standards/ecma-6/
/// - C1 defined in ECMA-48: https://ecma-international.org/publications-and-standards/standards/ecma-48/
/// - general: https://ghostty.org/docs/vt/concepts/sequences
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

/// ANSI C1 `0x9d` - Operating System Command ` ESC ] `
const String osc = '${esc}]';

/// ANSI C1 `0x9f` - Application Program Command ` ESC _ `
const String apc = '${esc}_';
