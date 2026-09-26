import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'engine/game.dart';

/// Burns the caption into a JPEG. The judge ribbon stays a UI overlay.
Uint8List renderSnapJpeg(Snap snap) {
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
  img.fillRect(
    canvas,
    x1: 130,
    y1: 120,
    x2: 950,
    y2: 980,
    color: img.ColorRgb8(232, 93, 76),
  );
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
