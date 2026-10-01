import 'dart:typed_data';

/// A tightly packed BGRA frame, upright, not yet mirrored.
class StillFrame {
  StillFrame({
    required this.width,
    required this.height,
    required this.bgra,
  }) {
    final expected = width * height * 4;
    if (width <= 0 || height <= 0 || bgra.length != expected) {
      throw ArgumentError('still is ${width}x$height with ${bgra.length} bytes');
    }
  }

  final int width;
  final int height;
  final Uint8List bgra;

  StillFrame copy() => StillFrame(
        width: width,
        height: height,
        bgra: Uint8List.fromList(bgra),
      );
}

/// Copies a camera buffer into an upright still. Rows may be padded.
/// [sensorOrientation] is the quarter-turn clockwise rotation the preview applies.
StillFrame stillFromCamera({
  required Uint8List bytes,
  required int width,
  required int height,
  required int bytesPerRow,
  required int sensorOrientation,
}) {
  if (width <= 0 || height <= 0 || bytesPerRow < width * 4) {
    throw ArgumentError('camera frame is ${width}x$height stride $bytesPerRow');
  }
  final packed = Uint8List(width * height * 4);
  final rowBytes = width * 4;
  for (var y = 0; y < height; y++) {
    final start = y * bytesPerRow;
    if (start + rowBytes > bytes.length) {
      throw ArgumentError('camera buffer ended at row $y');
    }
    packed.setRange(y * rowBytes, y * rowBytes + rowBytes, bytes, start);
  }
  final turns = ((sensorOrientation % 360) ~/ 90) % 4;
  return _rotateClockwise(packed, width, height, turns);
}

StillFrame _rotateClockwise(Uint8List src, int width, int height, int turns) {
  var pixels = src;
  var w = width;
  var h = height;
  for (var turn = 0; turn < turns; turn++) {
    final next = Uint8List(w * h * 4);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final dx = h - 1 - y;
        final dy = x;
        final from = (y * w + x) * 4;
        final to = (dy * h + dx) * 4;
        next[to] = pixels[from];
        next[to + 1] = pixels[from + 1];
        next[to + 2] = pixels[from + 2];
        next[to + 3] = pixels[from + 3];
      }
    }
    pixels = next;
    final swap = w;
    w = h;
    h = swap;
  }
  return StillFrame(width: w, height: h, bgra: pixels);
}
