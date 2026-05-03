import 'package:flutter_test/flutter_test.dart';
import 'package:smart_trichter/features/ble/ble_decoder.dart';

void main() {
  group('decodeChugDuration', () {
    test('decodes example from spec: 0xA3 0x0C 0x00 0x00 = 3235 ms', () {
      expect(decodeChugDuration([0xA3, 0x0C, 0x00, 0x00]), equals(3235));
    });

    test('decodes zero', () {
      expect(decodeChugDuration([0x00, 0x00, 0x00, 0x00]), equals(0));
    });

    test('decodes max uint32', () {
      expect(
        decodeChugDuration([0xFF, 0xFF, 0xFF, 0xFF]),
        equals(4294967295),
      );
    });

    test('decodes little-endian: 0x01 0x00 0x00 0x00 = 1', () {
      expect(decodeChugDuration([0x01, 0x00, 0x00, 0x00]), equals(1));
    });

    test('decodes little-endian: 0x00 0x01 0x00 0x00 = 256', () {
      expect(decodeChugDuration([0x00, 0x01, 0x00, 0x00]), equals(256));
    });

    test('ignores extra bytes beyond the first 4', () {
      expect(decodeChugDuration([0xA3, 0x0C, 0x00, 0x00, 0xFF, 0xFF]),
          equals(3235));
    });

    test('throws ArgumentError for exactly 3 bytes', () {
      expect(
        () => decodeChugDuration([0x01, 0x02, 0x03]),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for empty list', () {
      expect(() => decodeChugDuration([]), throwsArgumentError);
    });

    test('throws ArgumentError for 1 byte', () {
      expect(() => decodeChugDuration([0xFF]), throwsArgumentError);
    });
  });
}
