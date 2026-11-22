/// data structure to store terminal settings
class TerminalState {
  /// value to send to terminal for window title (OSC 0, `ESC ] 0 ; <title> \ a`)
  String title = '';

  /// whether the cursor is currently hidden in the terminal attached to [stdout] (DEC mode 25, queried with DECRQM `ESC [ ? 25 $ p`)
  bool hideCursor = false;

  /// whether the terminal attached to [stdout] has entered alternate screen buffer mode (DEC mode 1049, queried with DECRQM `ESC [ ? 1049 $ p`)
  bool useAlternateScreen = false;

  TerminalState({
    this.title = '',
    this.hideCursor = false,
    this.useAlternateScreen = false,
  });
}
