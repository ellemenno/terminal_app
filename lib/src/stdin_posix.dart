import 'dart:async';
import 'dart:io';

import 'key_record.dart';
import 'ucd.dart' as ucd;

/// handles Posix keyboard input and translates it to [KeyRecord] bits.
///
/// may be used on Windows in terminals that support the Kitty Keyboard Protocol.
///
/// without KKP support, this is the fallback parser on non-Windows systems like Linux and MacOS,
/// and [StdinWin32] is the fallback for Windows.
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
    bool debug = false,
  }) {
    keyRecord.modFlags.hasShift = false;
    keyRecord.modFlags.hasAlt = false;
    keyRecord.modFlags.hasCtrl = false;
    keyRecord.modFlags.hasSuper = false;
    keyRecord.modFlags.hasHyper = false;
    keyRecord.modFlags.hasMeta = false;
    keyRecord.modFlags.hasCaps = false;
    keyRecord.modFlags.hasNuml = false;

    if (debug) {
      final List<String> codes = <String>[];
      final List<String> chars = <String>[];
      for (final int b in keyBytes) {
        codes.add(ucd.hexString(b, w: 2, prefix: false));
        chars.add(String.fromCharCode(ucd.getPrintableCode(b)).padLeft(2, ' '));
      }
      print('bytes: ${codes.join(' ')}\n       ${chars.join(' ')}');
    }

    if (useKittyParser) {
      KeyRecord.parseKittyKeyBytes(keyBytes, keyRecord);
    } else {
      KeyRecord.parsePosixKeyBytes(keyBytes, keyRecord);
    }

    return keyRecord.bits;
  }
}
