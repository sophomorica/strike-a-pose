import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:strike_a_pose/engine/game.dart';
import 'package:strike_a_pose/engine/score.dart';
import 'package:strike_a_pose/engine/still.dart';
import 'package:strike_a_pose/snap_image.dart';

void main() {
  test('a snapshot jpeg burns in the player, pose, points, and stamp', () {
    final bytes = renderSnapJpeg(Snap(
      id: 's1',
      round: 1,
      playerId: 'p1',
      playerName: 'Jess',
      poseId: 'star_jump',
      poseName: 'Star Jump',
      points: 120,
      fitPercent: 96,
      stamp: 'PERFECT FIT',
      matched: true,
      sudden: false,
      seq: 1,
      at: DateTime(2026, 9, 25),
      footer: 'R1 · POSE 1 · SEP 25',
      breakdown: const ScoreBreakdown(
        fitPoints: 96,
        holdBonus: 10,
        wallBonus: 14,
        multiplier: 1,
        total: 120,
        perfect: true,
        matched: true,
        fitPercent: 96,
        stamp: 'PERFECT FIT',
      ),
    ));
    expect(bytes[0], 0xFF);
    expect(bytes[1], 0xD8);
    final decoded = img.decodeJpg(bytes)!;
    expect(decoded.width, 1080);
    var ink = 0;
    for (var y = 1000; y < 1160; y += 3) {
      for (var x = 140; x < 900; x += 6) {
        final pixel = decoded.getPixel(x, y);
        if (pixel.r < 230 || pixel.g < 230 || pixel.b < 230) ink += 1;
      }
    }
    expect(ink, greaterThan(20));
    final stage = decoded.getPixel(snapPhotoLeft + 80, snapPhotoTop + 80);
    expect(stage.r, greaterThan(200));
    expect(stage.g, lessThan(140));
    expect(stage.b, lessThan(120));
  });

  test('a snapshot jpeg is the mirrored camera frame, not the drawn stage', () {
    final still = _splitStill();
    final decoded = img.decodeJpg(renderSnapJpeg(_snap(), still: still))!;
    final left = decoded.getPixel(_sampleX(0.15), _sampleY());
    final right = decoded.getPixel(_sampleX(0.85), _sampleY());
    expect(left.b, greaterThan(left.r + 40));
    expect(left.b, greaterThan(left.g));
    expect(right.g, greaterThan(right.r + 40));
    expect(right.g, greaterThan(right.b));
    expect(left.r, lessThan(200));
    expect(right.b, lessThan(80));
  });

  test('stillFromCamera packs rows and rotates the sensor clockwise', () {
    final raw = Uint8List(2 * 16);
    raw[0] = 10;
    raw[1] = 20;
    raw[2] = 30;
    raw[3] = 255;
    final upright = stillFromCamera(
      bytes: raw,
      width: 2,
      height: 2,
      bytesPerRow: 16,
      sensorOrientation: 0,
    );
    expect(upright.width, 2);
    expect(upright.bgra[0], 10);
    expect(upright.bgra[8], 0);
    final turned = stillFromCamera(
      bytes: raw,
      width: 2,
      height: 2,
      bytesPerRow: 16,
      sensorOrientation: 90,
    );
    expect(turned.bgra[4], 10);
    expect(turned.bgra[5], 20);
    expect(turned.bgra[0], 0);
  });
}

Snap _snap() {
  return Snap(
    id: 's1',
    round: 1,
    playerId: 'p1',
    playerName: 'Jess',
    poseId: 'star_jump',
    poseName: 'Star Jump',
    points: 120,
    fitPercent: 96,
    stamp: 'PERFECT FIT',
    matched: true,
    sudden: false,
    seq: 1,
    at: DateTime(2026, 9, 25),
    footer: 'R1 · POSE 1 · SEP 25',
    breakdown: const ScoreBreakdown(
      fitPoints: 96,
      holdBonus: 10,
      wallBonus: 14,
      multiplier: 1,
      total: 120,
      perfect: true,
      matched: true,
      fitPercent: 96,
      stamp: 'PERFECT FIT',
    ),
  );
}

StillFrame _splitStill() {
  final bgra = Uint8List(8 * 8 * 4);
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      final i = (y * 8 + x) * 4;
      final green = x < 4;
      bgra[i] = green ? 0 : 255;
      bgra[i + 1] = green ? 255 : 0;
      bgra[i + 2] = 0;
      bgra[i + 3] = 255;
    }
  }
  return StillFrame(width: 8, height: 8, bgra: bgra);
}

int _sampleX(double across) => snapPhotoLeft + ((snapPhotoRight - snapPhotoLeft) * across).round();

int _sampleY() => snapPhotoTop + ((snapPhotoBottom - snapPhotoTop) * 0.5).round();
