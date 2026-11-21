import 'package:terminal_app/terminal_app.dart';
import 'package:terminal_app/src/key_maps.dart';

void main(List<String> args) {
  TerminalAppRunner(
    fps: 3,
    title: 'App Title',
  ).run(Example(args));
}

class Example implements TerminalApp {
  final int totalUpdates = 500;
  late final TerminalAppHost _host;
  late final TerminalScreen _screen;
  int _updates = 0;

  Example(List<String> args) {
    print('[Example.constructor] args: ${args}');
    _updates = totalUpdates;
  }

  @override
  void acceptHostAPIs(TerminalAppHost host, TerminalScreen screen) {
    print('[Example.acceptHostAPIs] received host and screen references');
    _host = host;
    _screen = screen;
  }

  @override
  void onKeyRecord(int recordBits) {
    final KeyRecord keyRecord = KeyRecord.fromBits(recordBits);
    print(keyRecord.summary);

    bool quit = false;
    if (keyRecord.isPrintable) {
      final int r = keyRecord.rune;
      if (r == 'q'.runes.first) {
        quit = true;
      }
    }
    if (quit) {
      print('[Example.onKeyBytes] quit - asking host to stop..');
      _host.stop();
    }
  }

  @override
  void onResize(int w, int h) {
    print('[Example.onResize] w: ${w}, h: ${h}');
  }

  @override
  bool onUpdate(double dt) {
    _updates--;
    if (_updates <= 3 || totalUpdates - _updates <= 3) {
      print('[Example.onUpdate] dt = ${dt}; ${_updates} updates left..');
    }
    return (_updates > 0);
  }
}
