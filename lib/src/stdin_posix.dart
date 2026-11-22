import 'dart:async';
import 'dart:io';

import 'key_record.dart';
import 'ucd.dart' as ucd;

/// handles Posix keyboard input and translates it to [KeyRecord] bits.
///
/// this is used on non-Windows systems like Linus and MacOS.
///
/// see [StdinWin32] for the Windows analogue.
class StdinPosix extends Stream<int> {
  /// whether this stream is set up to parse key events per the Kitty Keyboard Protocol
  /// https://sw.kovidgoyal.net/kitty/keyboard-protocol/#an-overview
  final bool withKittyProtocol;

  late final ModFlags _modFlags;
  late final KeyRecord _keyRecord;
  late final StreamTransformer<List<int>, int> _transformer;
  late final Stream<int> _stream;

  StdinPosix({this.withKittyProtocol = false}) {
    _modFlags = ModFlags();
    _keyRecord = KeyRecord(_modFlags);
    _transformer = StreamTransformer<List<int>, int>.fromHandlers(
      handleData: (List<int> keyBytes, EventSink<int> sink) {
        sink.add(_getKeyBitRecord(keyBytes, _keyRecord, useKittyParser: withKittyProtocol));
      },
    );
    _stream = stdin.transform<int>(_transformer);
  }

  @override
  StreamSubscription<int> listen(
    void Function(int event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  static int _getKeyBitRecord(
    List<int> keyBytes,
    KeyRecord keyRecord, {
    bool useKittyParser = false,
    bool debug = true,
  }) {
    // TODO: collect modifiers
    keyRecord.modFlags.hasShift = false;
    keyRecord.modFlags.hasAlt = false;
    keyRecord.modFlags.hasCtrl = false;
    keyRecord.modFlags.hasSuper = false; // command / apple key
    keyRecord.modFlags.hasHyper =
        false; // not a standard 104-key key, but may be assigned via os config
    keyRecord.modFlags.hasMeta =
        false; // not a standard 104-key key, but may be assigned via os config
    keyRecord.modFlags.hasCaps = false;
    keyRecord.modFlags.hasNuml = false;

    if (debug) {
      final List<String> codes = <String>[];
      final List<String> chars = <String>[];
      for (final int b in keyBytes) {
        codes.add(ucd.hexString(b));
        chars.add(String.fromCharCode(ucd.getPrintableCode(b)).padLeft(4, ' '));
      }
      print('${codes.join(' ')}\n${chars.join(' ')}');
    }

    if (useKittyParser) {
      KeyRecord.parseKittyKeyBytes(keyBytes, keyRecord);
    } else {
      KeyRecord.parsePosixKeyBytes(keyBytes, keyRecord);
    }

    return keyRecord.bits;
  }
}
