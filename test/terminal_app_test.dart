import 'package:test/test.dart';
import 'package:terminal_app/src/key_maps.dart';
import 'package:terminal_app/src/ucd.dart' as ucd;
import 'package:terminal_app/src/vts.dart' as vts;

void main() {
  group('virtual terminal sequences', () {
    test('provide convenience fields for common ANSI control sequences', () {
      expect(vts.csi.runes, <int>[0x1b, 0x5b]);
    });
  });

  group('unicode character database', () {
    test('can pretty print key codes as hex values', () {
      expect(ucd.hexString(127), '0x007f');
    });
    test('can provide printable runes for unprintable character codes', () {
      expect(String.fromCharCode(ucd.getPrintableCode(0)), '␀');
      expect(String.fromCharCode(ucd.getPrintableCode(0x1b)), '␛');
      expect(String.fromCharCode(ucd.getPrintableCode(0x20)), '␠');
      expect(String.fromCharCode(ucd.getPrintableCode(0x9b)), '␦');
      expect(String.fromCharCode(ucd.getPrintableCode(0xa0)), '␢');
      expect(String.fromCharCode(ucd.getPrintableCode(57442)), '');
      expect(String.fromCharCode(ucd.getPrintableCode(0xfdd0)), '�');
      expect(String.fromCharCode(ucd.getPrintableCode(0x61)), 'a');
    });
    test('can identify C0 control code points', () {
      expect(ucd.isC0Code(0x1b), isTrue);
      expect(ucd.isC0Code(0x20), isFalse);
    });
    test('can identify C1 control code points', () {
      expect(ucd.isC1Code(0x9b), isTrue);
      expect(ucd.isC1Code(0xa2), isFalse);
    });
    test('can identify invisible spaces and formatting codes', () {
      expect(ucd.isInvisibleCode(0xa0), isTrue);
      expect(ucd.isInvisibleCode(0xad), isTrue);
    });
    test('can identify private use code points', () {
      expect(ucd.isPrivateUseCode(0xe000), isTrue);
      expect(ucd.isPrivateUseCode(0xebbb), isTrue);
      expect(ucd.isPrivateUseCode(0xf8ff), isTrue);
    });
    test('can identify non-character code points', () {
      expect(ucd.isNonCharacterCode(0xfffd), isFalse);
      expect(ucd.isNonCharacterCode(0xfffe), isTrue);
      expect(ucd.isNonCharacterCode(0xffff), isTrue);
    });
    test('can identify reserved code points', () {
      expect(ucd.isReservedCodeBMP(0x0377), isFalse);
      expect(ucd.isReservedCodeBMP(0x0378), isTrue);
      expect(ucd.isReservedCodeBMP(0x0529), isFalse);
      expect(ucd.isReservedCodeBMP(0x0530), isTrue);
      expect(ucd.isReservedCodeBMP(0x05f4), isFalse);
      expect(ucd.isReservedCodeBMP(0x05f5), isTrue);
      expect(ucd.isReservedCodeBMP(0x05ff), isTrue);
      expect(ucd.isReservedCodeBMP(0x0600), isFalse);
      expect(ucd.isReservedCodeBMP(0x09d6), isTrue);
      expect(ucd.isReservedCodeBMP(0x09d7), isFalse);
      expect(ucd.isReservedCodeBMP(0x09d8), isTrue);
    });
    test('can identify surrogate code points', () {
      expect(ucd.isSurrogateCode(0xd7ff), isFalse);
      expect(ucd.isSurrogateCode(0xd800), isTrue);
    });
  });

  group('key modifier flags', () {
    test('can print as string of bits', () {
      final ModFlags mf = ModFlags();
      expect(mf.bitString, '00000000');
      mf.hasShift = true;
      expect(mf.bitString, '00000001');
      mf.hasAlt = true;
      expect(mf.bitString, '00000011');
      mf.hasCtrl = true;
      expect(mf.bitString, '00000111');
      mf.hasSuper = true;
      expect(mf.bitString, '00001111');
      mf.hasHyper = true;
      expect(mf.bitString, '00011111');
      mf.hasMeta = true;
      expect(mf.bitString, '00111111');
      mf.hasCaps = true;
      expect(mf.bitString, '01111111');
      mf.hasNuml = true;
      expect(mf.bitString, '11111111');
    });
    test('can serialize to bits', () {
      final ModFlags mf = ModFlags();
      mf.hasNuml = true;
      mf.hasHyper = true;
      mf.hasAlt = true;
      final int b = ModFlags.toBits(mf);
      expect(b, 0x92);
      expect(ModFlags.toBitString(b), '10010010');
    });
    test('can de-serialize from bits', () {
      final ModFlags mf = ModFlags();
      expect(mf.bitString, '00000000');
      expect(mf.hasShift, isFalse);
      expect(mf.hasAlt, isFalse);
      expect(mf.hasCtrl, isFalse);
      expect(mf.hasSuper, isFalse);
      expect(mf.hasHyper, isFalse);
      expect(mf.hasMeta, isFalse);
      expect(mf.hasCaps, isFalse);
      expect(mf.hasNuml, isFalse);
      ModFlags.fromBits(0xff, mf);
      expect(mf.bitString, '11111111');
      expect(mf.hasShift, isTrue);
      expect(mf.hasAlt, isTrue);
      expect(mf.hasCtrl, isTrue);
      expect(mf.hasSuper, isTrue);
      expect(mf.hasHyper, isTrue);
      expect(mf.hasMeta, isTrue);
      expect(mf.hasCaps, isTrue);
      expect(mf.hasNuml, isTrue);
    });
    test('can clear its flags', () {
      final ModFlags mf = ModFlags();
      ModFlags.fromBits(0xff, mf);
      expect(mf.bitString, '11111111');
      mf.clear();
      expect(mf.bitString, '00000000');
    });
  });

  group('key record bit field', () {
    test('can serialize to bits', () {
      final ModFlags mf = ModFlags();
      mf.hasCtrl = true;
      mf.hasShift = true;
      final int b = KeyRecord.toBits(mf, rune: 'a'.runes.first);
      expect(KeyRecord.toBitString(b), '10000010100000000000000001100001');
    });
    test('throws exception for invalid rune', () {
      expect(() => KeyRecord.toBits(ModFlags(), rune: -1), throwsA(isRangeError));
    });
    test('can test if key is printable', () {
      final int bY = KeyRecord.toBits(ModFlags(), rune: 'a'.runes.first);
      final int bN = KeyRecord.toBits(ModFlags(), id: KeyID.tab);
      expect(KeyRecord.isPrintableCode(bY), isTrue);
      expect(KeyRecord.isPrintableCode(bN), isFalse);
    });
    test('can test if key is a control', () {
      final int bY = KeyRecord.toBits(ModFlags(), id: KeyID.tab);
      final int bN = KeyRecord.toBits(ModFlags(), rune: 'a'.runes.first);
      expect(KeyRecord.isControlCode(bY), isTrue);
      expect(KeyRecord.isControlCode(bN), isFalse);
    });
    test('can extract the pressed bit', () {
      final int bY = KeyRecord.toBits(ModFlags(), pressed: true, id: KeyID.down);
      final int bN = KeyRecord.toBits(ModFlags(), pressed: false, id: KeyID.down);
      expect(KeyRecord.toPressed(bY), isTrue);
      expect(KeyRecord.toPressed(bN), isFalse);
    });
    test('can extract the key id', () {
      final int b = KeyRecord.toBits(ModFlags(), id: KeyID.up);
      expect(KeyRecord.toID(b), KeyID.up);
    });
    test('can extract the rune', () {
      final int r = 'a'.runes.first;
      final int b = KeyRecord.toBits(ModFlags(), rune: r);
      expect(KeyRecord.toRune(b), r);
    });
    test('can extract the flags', () {
      final ModFlags mf1 = ModFlags();
      final ModFlags mf2 = ModFlags();
      mf1.hasCtrl = true;
      mf1.hasShift = true;
      final int b = KeyRecord.toBits(mf1, rune: 'a'.runes.first);
      KeyRecord.toFlags(b, mf2);
      expect(ModFlags.toBitString(mf1.bits), ModFlags.toBitString(mf2.bits));
    });
  });
}
