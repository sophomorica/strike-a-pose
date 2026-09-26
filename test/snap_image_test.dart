import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:strike_a_pose/engine/game.dart';
import 'package:strike_a_pose/engine/score.dart';
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
  });
}
