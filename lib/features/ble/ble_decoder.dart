import 'dart:typed_data';

/// Decodes a 4-byte little-endian unsigned int from [bytes] into milliseconds.
/// Throws [ArgumentError] if [bytes] has fewer than 4 elements.
int decodeChugDuration(List<int> bytes) {
  if (bytes.length < 4) {
    throw ArgumentError('Expected at least 4 bytes, got ${bytes.length}');
  }
  final byteData =
      ByteData.sublistView(Uint8List.fromList(bytes.sublist(0, 4)));
  return byteData.getUint32(0, Endian.little);
}
