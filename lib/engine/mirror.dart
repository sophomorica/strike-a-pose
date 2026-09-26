import 'dart:math' as math;

class ScreenPoint {
  final double x;
  final double y;

  const ScreenPoint(this.x, this.y);
}

/// Maps an unmirrored image landmark into a cover-fit mirrored view.
/// `x = W - (x * s + dx)`, `y = y * s + dy`, `s = max(W/w, H/h)`.
ScreenPoint mirrorLandmark({
  required double x,
  required double y,
  required double imageW,
  required double imageH,
  required double viewW,
  required double viewH,
}) {
  final s = math.max(viewW / imageW, viewH / imageH);
  final dx = (viewW - imageW * s) / 2;
  final dy = (viewH - imageH * s) / 2;
  return ScreenPoint(viewW - (x * s + dx), y * s + dy);
}

class FloorMarker {
  final double cx;
  final double cy;
  final double rx;
  final double ry;

  const FloorMarker({
    this.cx = 0.5,
    this.cy = 0.78,
    this.rx = 0.20,
    this.ry = 0.055,
  });

  bool containsNormalized(double nx, double ny) {
    final dx = (nx - cx) / rx;
    final dy = (ny - cy) / ry;
    return dx * dx + dy * dy <= 1;
  }
}

bool ankleInsideMarker({
  required double x,
  required double y,
  required double imageW,
  required double imageH,
  required double viewW,
  required double viewH,
  FloorMarker marker = const FloorMarker(),
}) {
  final p = mirrorLandmark(
    x: x,
    y: y,
    imageW: imageW,
    imageH: imageH,
    viewW: viewW,
    viewH: viewH,
  );
  return marker.containsNormalized(p.x / viewW, p.y / viewH);
}

InputRotation rotationFromSensor(int sensorOrientation) {
  switch (sensorOrientation) {
    case 90:
      return InputRotation.deg90;
    case 180:
      return InputRotation.deg180;
    case 270:
      return InputRotation.deg270;
    default:
      return InputRotation.deg0;
  }
}

enum InputRotation { deg0, deg90, deg180, deg270 }
