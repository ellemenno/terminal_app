import 'interfaces.dart';

class TerminalBuffer implements TerminalScreen {
  int _cols;
  int _rows;

  TerminalBuffer(this._cols, this._rows);

  @override
  int get cols => _cols;

  set cols(int value) {
    _cols = value;
  }

  @override
  int get rows => _rows;

  set rows(int value) {
    _rows = value;
  }
}
