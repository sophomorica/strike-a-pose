import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../engine/body.dart';
import '../engine/fit.dart';
import '../engine/mirror.dart';
import '../theme.dart';

class StageBackdrop extends StatelessWidget {
  const StageBackdrop({
    super.key,
    required this.target,
    this.player,
    this.limbs = const {},
    this.neon = false,
    this.greenRim = false,
    this.preview,
    this.showDebugDots = false,
    this.wallShift = 0,
  });

  final PoseFrame target;
  final PoseFrame? player;
  final Map<LimbId, LimbStatus> limbs;
  final bool neon;
  final bool greenRim;
  final Widget? preview;
  final bool showDebugDots;
  final int wallShift;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const CustomPaint(painter: RoomPainter(), child: SizedBox.expand()),
        if (preview != null) Positioned.fill(child: preview!),
        CustomPaint(
          painter: FoamWallPainter(
            target: target,
            player: player,
            limbs: limbs,
            neon: neon,
            greenRim: greenRim,
            showDebugDots: showDebugDots,
            wallShift: wallShift,
          ),
          child: const SizedBox.expand(),
        ),
      ],
    );
  }
}

class RoomPainter extends CustomPainter {
  const RoomPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final room = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF8E6B8A), Color(0xFF6E7C9A), Color(0xFFD7B48A)],
        stops: [0, 0.55, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, room);

    final floor = Paint()..color = const Color(0xFFC9894A);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.72, size.width, size.height), floor);
    final board = Paint()
      ..color = const Color(0xFFB87438)
      ..strokeWidth = 2;
    for (var x = 0.0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, size.height * 0.72), Offset(x - 20, size.height), board);
    }

    final window = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.08, size.height * 0.08, size.width * 0.28, size.height * 0.22),
      const Radius.circular(8),
    );
    canvas.drawRRect(window, Paint()..color = const Color(0xFF9FD0E8));
    canvas.drawLine(
      Offset(window.left, window.center.dy),
      Offset(window.right, window.center.dy),
      Paint()..color = const Color(0xFFF4E2C4),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.55, size.height * 0.28, size.width * 0.36, size.height * 0.16),
        const Radius.circular(16),
      ),
      Paint()..color = const Color(0xFF3E6B62),
    );
    canvas.drawCircle(Offset(size.width * 0.18, size.height * 0.48), 22, Paint()..color = const Color(0xFF2F6B45));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.14, size.height * 0.48, 18, 46),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFFE7D3B0),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.86),
        width: size.width * 0.7,
        height: size.height * 0.12,
      ),
      Paint()..color = const Color(0xFF5C4A86).withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(RoomPainter oldDelegate) => false;
}

class FoamWallPainter extends CustomPainter {
  FoamWallPainter({
    required this.target,
    this.player,
    this.limbs = const {},
    this.neon = false,
    this.greenRim = false,
    this.showDebugDots = false,
    this.wallShift = 0,
  });

  final PoseFrame target;
  final PoseFrame? player;
  final Map<LimbId, LimbStatus> limbs;
  final bool neon;
  final bool greenRim;
  final bool showDebugDots;
  final int wallShift;

  @override
  void paint(Canvas canvas, Size size) {
    final wallTop = size.height * 0.29;
    final wall = Rect.fromLTWH(0, wallTop, size.width, size.height - wallTop);
    canvas.saveLayer(wall, Paint());
    final wallColor = wallShift.isEven ? Sap.coral : const Color(0xFFC4476A);
    canvas.drawRect(
      wall,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [wallColor.withValues(alpha: 0.96), wallColor.withValues(alpha: 0.9)],
        ).createShader(wall),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, wallTop, size.width, 18),
      Paint()..color = Sap.cream,
    );
    final hole = Paint()
      ..blendMode = BlendMode.dstOut
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 34
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    _trace(canvas, size, target, hole, fillBody: true);
    canvas.restore();

    if (greenRim) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(wall.deflate(8), const Radius.circular(18)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..color = Sap.match,
      );
    }

    final shown = player ?? target;
    _trace(
      canvas,
      size,
      shown,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = neon ? 16 : 18
        ..strokeCap = StrokeCap.round
        ..color = neon ? Sap.cream : const Color(0xFFF2C14E),
      shirt: const Color(0xFFF2C14E),
    );
    if (neon) {
      _traceLimbs(canvas, size, shown);
    }
    if (showDebugDots) {
      for (final id in LandmarkId.values) {
        final mark = shown.point(id);
        if (!mark.confident) continue;
        final p = _map(size, shown, mark.x, mark.y);
        canvas.drawCircle(p, 5, Paint()..color = Sap.sky);
      }
    }
  }

  void _traceLimbs(Canvas canvas, Size size, PoseFrame frame) {
    void limb(LimbId id, LandmarkId a, LandmarkId b, LandmarkId c) {
      final status = limbs[id] ?? LimbStatus.unknown;
      final color = switch (status) {
        LimbStatus.green => Sap.match,
        LimbStatus.amber => Sap.close,
        LimbStatus.red => Sap.miss,
        LimbStatus.unknown => Colors.white24,
      };
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;
      final p1 = frame.point(a);
      final p2 = frame.point(b);
      final p3 = frame.point(c);
      if (!p1.confident || !p2.confident || !p3.confident) return;
      final path = Path()
        ..moveTo(_map(size, frame, p1.x, p1.y).dx, _map(size, frame, p1.x, p1.y).dy)
        ..lineTo(_map(size, frame, p2.x, p2.y).dx, _map(size, frame, p2.x, p2.y).dy)
        ..lineTo(_map(size, frame, p3.x, p3.y).dx, _map(size, frame, p3.x, p3.y).dy);
      canvas.drawPath(path, paint);
    }

    limb(LimbId.lArm, LandmarkId.lShoulder, LandmarkId.lElbow, LandmarkId.lWrist);
    limb(LimbId.rArm, LandmarkId.rShoulder, LandmarkId.rElbow, LandmarkId.rWrist);
    limb(LimbId.lLeg, LandmarkId.lHip, LandmarkId.lKnee, LandmarkId.lAnkle);
    limb(LimbId.rLeg, LandmarkId.rHip, LandmarkId.rKnee, LandmarkId.rAnkle);
  }

  void _trace(Canvas canvas, Size size, PoseFrame frame, Paint paint, {Color? shirt, bool fillBody = false}) {
    Offset? at(LandmarkId id) {
      final mark = frame.point(id);
      if (!mark.confident && !fillBody) return null;
      if (mark.likelihood <= 0 && !fillBody) return null;
      return _map(size, frame, mark.x, mark.y);
    }

    void bone(LandmarkId a, LandmarkId b) {
      final p = at(a);
      final q = at(b);
      if (p == null || q == null) return;
      canvas.drawLine(p, q, paint);
    }

    bone(LandmarkId.lWrist, LandmarkId.lElbow);
    bone(LandmarkId.lElbow, LandmarkId.lShoulder);
    bone(LandmarkId.rShoulder, LandmarkId.rElbow);
    bone(LandmarkId.rElbow, LandmarkId.rWrist);
    bone(LandmarkId.lShoulder, LandmarkId.rShoulder);
    bone(LandmarkId.lShoulder, LandmarkId.lHip);
    bone(LandmarkId.rShoulder, LandmarkId.rHip);
    bone(LandmarkId.lHip, LandmarkId.rHip);
    bone(LandmarkId.lHip, LandmarkId.lKnee);
    bone(LandmarkId.lKnee, LandmarkId.lAnkle);
    bone(LandmarkId.rHip, LandmarkId.rKnee);
    bone(LandmarkId.rKnee, LandmarkId.rAnkle);

    final ls = at(LandmarkId.lShoulder);
    final rs = at(LandmarkId.rShoulder);
    final lh = at(LandmarkId.lHip);
    final rh = at(LandmarkId.rHip);
    if (ls != null && rs != null && lh != null && rh != null && shirt != null) {
      final path = Path()
        ..moveTo(ls.dx, ls.dy)
        ..lineTo(rs.dx, rs.dy)
        ..lineTo(rh.dx, rh.dy)
        ..lineTo(lh.dx, lh.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = shirt);
      final head = Offset((ls.dx + rs.dx) / 2, (ls.dy + rs.dy) / 2 - 28);
      canvas.drawCircle(head, 18, Paint()..color = const Color(0xFFF3D2B5));
    }
  }

  Offset _map(Size size, PoseFrame frame, double x, double y) {
    final p = mirrorLandmark(
      x: x,
      y: y,
      imageW: frame.imageWidth,
      imageH: frame.imageHeight,
      viewW: size.width,
      viewH: size.height,
    );
    return Offset(p.x, p.y);
  }

  @override
  bool shouldRepaint(FoamWallPainter oldDelegate) => true;
}

class HoldRing extends StatelessWidget {
  const HoldRing({super.key, required this.held});

  final double held;

  @override
  Widget build(BuildContext context) {
    final shown = held.clamp(0, 1).toDouble();
    final label = shown.toStringAsFixed(1);
    final left = (1 - shown).clamp(0, 1).toStringAsFixed(1);
    return Row(
      children: [
        SizedBox(
          width: 92,
          height: 92,
          child: CustomPaint(
            painter: _RingPainter(shown),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: displayStyle(28, color: Sap.cream)),
                  Text('OF 1.0 SEC', style: bodyStyle(9, color: Sap.cream)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Sap.match,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Keep holding!', style: uiStyle(22, color: Sap.ink)),
                Text('$left s to go', style: bodyStyle(13, color: Sap.ink)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    canvas.drawCircle(center, size.width / 2, Paint()..color = Sap.indigoNight);
    final arc = Paint()
      ..color = Sap.match
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width / 2 - 6),
      -math.pi / 2,
      math.pi * 2 * t,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => oldDelegate.t != t;
}

class FitMeter extends StatelessWidget {
  const FitMeter({super.key, required this.percent, required this.zone, required this.canSee});

  final int percent;
  final FitZone zone;
  final bool canSee;

  @override
  Widget build(BuildContext context) {
    final color = switch (zone) {
      FitZone.match => Sap.match,
      FitZone.close => Sap.close,
      FitZone.cold => Sap.coralLight,
      FitZone.unknown => Colors.white24,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('FIT', style: bodyStyle(12, color: Sap.cream)),
            const SizedBox(width: 8),
            Text(
              canSee ? '$percent%' : '?',
              style: displayStyle(28, color: canSee ? color : Sap.cream),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: zone == FitZone.match ? Sap.match : Sap.sun,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                zone == FitZone.unknown || !canSee ? "CAN'T SEE YOU" : zone.name.toUpperCase(),
                style: uiStyle(12, color: Sap.ink),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 16,
          child: CustomPaint(
            painter: _MeterPainter(percent: canSee ? percent : 0, color: color),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('COLD', style: bodyStyle(10, color: zone == FitZone.cold ? Sap.cream : Colors.white54)),
            Text('CLOSE', style: bodyStyle(10, color: zone == FitZone.close ? Sap.cream : Colors.white54)),
            Text('MATCH', style: bodyStyle(10, color: zone == FitZone.match ? Sap.match : Colors.white54)),
          ],
        ),
      ],
    );
  }
}

class _MeterPainter extends CustomPainter {
  _MeterPainter({required this.percent, required this.color});
  final int percent;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const segments = 20;
    final gap = 3.0;
    final w = (size.width - gap * (segments - 1)) / segments;
    for (var i = 0; i < segments; i++) {
      final on = percent >= (i + 1) * 5;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(i * (w + gap), 2, w, size.height - 4),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, Paint()..color = on ? color : Colors.white24);
    }
    final notchX = size.width * 0.85;
    canvas.drawRect(Rect.fromLTWH(notchX - 1, 0, 2, size.height), Paint()..color = Sap.cream);
  }

  @override
  bool shouldRepaint(_MeterPainter oldDelegate) => oldDelegate.percent != percent || oldDelegate.color != color;
}
