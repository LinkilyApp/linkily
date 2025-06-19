class GeoCodingUtils {
  /// Encodes a single LatLng coordinate into a compact string
  static String encodeLatLng(LatLng point) {
    final lat = (point.latitude * 1E5).round();
    final lng = (point.longitude * 1E5).round();
    return '${_encodeValue(lat)}|${_encodeValue(lng)}';
  }

  /// Decodes a string back into a LatLng coordinate
  static LatLng decodeLatLng(String encoded) {
    final parts = encoded.split('|');
    if (parts.length != 2) throw FormatException('Invalid encoded LatLng format');
    
    return LatLng(
      _decodeValue(parts[0]) / 1E5,
      _decodeValue(parts[1]) / 1E5,
    );
  }

  // Helper method for encoding a single value
  static String _encodeValue(int value) {
    value = value < 0 ? ~(value << 1) : value << 1;
    final buffer = StringBuffer();
    while (value >= 0x20) {
      buffer.writeCharCode(((0x20 | (value & 0x1f)) + 63));
      value >>= 5;
    }
    buffer.writeCharCode((value + 63));
    return buffer.toString();
  }

  // Helper method for decoding a single value
  static int _decodeValue(String value) {
    int index = 0;
    int result = 0;
    int shift = 0;
    int b;
    
    do {
      b = value.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20 && index < value.length);
    
    return (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
  }
}

class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  @override
  String toString() => 'LatLng($latitude, $longitude)';
}