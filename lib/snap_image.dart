import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'engine/game.dart';
import 'engine/still.dart';

const snapPhotoLeft = 130;
const snapPhotoTop = 120;
const snapPhotoRight = 950;
const snapPhotoBottom = 980;

/// Burns the caption into a JPEG. A camera still is mirrored to match the
/// preview. With no still, the referee path draws the foam-wall stage.
/// The judge ribbon stays a UI overlay.
Uint8List renderSnapJpeg(Snap snap, {StillFrame? still}) {
  const width = 1080;
  const height = 1350;
  final canvas = img.Image(width: width, height: height);
  img.fill(canvas, color: img.ColorRgb8(23, 15, 46));
  img.fillRect(
    canvas,
    x1: 90,
    y1: 80,
    x2: 990,
    y2: 1180,
    color: img.ColorRgb8(255, 253, 247),
  );
  if (still == null) {
    img.fillRect(
      canvas,
      x1: snapPhotoLeft,
      y1: snapPhotoTop,
      x2: snapPhotoRight,
      y2: snapPhotoBottom,
      color: img.ColorRgb8(232, 93, 76),
    );
  } else {
    final photo = _mirroredPhoto(
      still,
      snapPhotoRight - snapPhotoLeft,
      snapPhotoBottom - snapPhotoTop,
    );
    img.compositeImage(canvas, photo, dstX: snapPhotoLeft, dstY: snapPhotoTop);
  }
  final caption = '${snap.playerName} · ${snap.poseName}';
  final points = snap.matched ? '+${snap.points}  ${snap.fitPercent}% FIT' : snap.stamp;
  img.drawString(
    canvas,
    caption,
    font: img.arial48,
    x: 140,
    y: 1010,
    color: img.ColorRgb8(27, 18, 48),
  );
  img.drawString(
    canvas,
    points,
    font: img.arial48,
    x: 140,
    y: 1080,
    color: img.ColorRgb8(27, 18, 48),
  );
  img.drawString(
    canvas,
    snap.footer,
    font: img.arial24,
    x: 140,
    y: 1220,
    color: img.ColorRgb8(247, 241, 227),
  );
  return Uint8List.fromList(img.encodeJpg(canvas, quality: 85));
}

img.Image _mirroredPhoto(StillFrame still, int dstW, int dstH) {
  final bytes = Uint8List.fromList(still.bgra);
  final source = img.Image.fromBytes(
    width: still.width,
    height: still.height,
    bytes: bytes.buffer,
    numChannels: 4,
    order: img.ChannelOrder.bgra,
  );
  final flipped = img.flipHorizontal(source);
  final scale = math.max(dstW / flipped.width, dstH / flipped.height);
  final resized = img.copyResize(
    flipped,
    width: math.max(dstW, (flipped.width * scale).round()),
    height: math.max(dstH, (flipped.height * scale).round()),
  );
  final cropX = math.max(0, (resized.width - dstW) ~/ 2);
  final cropY = math.max(0, (resized.height - dstH) ~/ 2);
  return img.copyCrop(resized, x: cropX, y: cropY, width: dstW, height: dstH);
}
