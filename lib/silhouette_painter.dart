import 'package:flutter/material.dart';

import 'pose.dart';

const _bone = Color(0xFFF4EFE6);

class SilhouettePainter extends CustomPainter {
  final PoseSkeleton skeleton;

  SilhouettePainter(this.skeleton);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide * 0.42;
    final center = Offset(size.width / 2, size.height * 0.52);
    Offset mapJoint(Joint joint) {
      return Offset(center.dx + joint.x * scale, center.dy - joint.y * scale);
    }

    final torso = Path()
      ..moveTo(mapJoint(skeleton.shoulderL).dx, mapJoint(skeleton.shoulderL).dy)
      ..lineTo(mapJoint(skeleton.shoulderR).dx, mapJoint(skeleton.shoulderR).dy)
      ..lineTo(mapJoint(skeleton.hipR).dx, mapJoint(skeleton.hipR).dy)
      ..lineTo(mapJoint(skeleton.hipL).dx, mapJoint(skeleton.hipL).dy)
      ..close();
    canvas.drawPath(torso, Paint()..color = _bone);

    final limbs = [
      _Limb(skeleton.shoulderL, skeleton.elbowL),
      _Limb(skeleton.elbowL, skeleton.wristL),
      _Limb(skeleton.shoulderR, skeleton.elbowR),
      _Limb(skeleton.elbowR, skeleton.wristR),
      _Limb(skeleton.hipL, skeleton.kneeL),
      _Limb(skeleton.kneeL, skeleton.ankleL),
      _Limb(skeleton.hipR, skeleton.kneeR),
      _Limb(skeleton.kneeR, skeleton.ankleR),
    ]..sort((a, b) => a.averageZ.compareTo(b.averageZ));

    for (final limb in limbs) {
      final width = (16 * (1 - 0.35 * limb.averageZ)).clamp(8.0, 22.0);
      final paint = Paint()
        ..color = _bone
        ..style = PaintingStyle.stroke
        ..strokeWidth = width.toDouble()
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(mapJoint(limb.start), mapJoint(limb.end), paint);
    }

    canvas.drawCircle(
      mapJoint(skeleton.head),
      scale * 0.08,
      Paint()..color = _bone,
    );
  }

  @override
  bool shouldRepaint(covariant SilhouettePainter oldDelegate) {
    final previous = oldDelegate.skeleton.joints;
    final next = skeleton.joints;
    for (var i = 0; i < next.length; i++) {
      final a = previous[i];
      final b = next[i];
      if (a.x != b.x || a.y != b.y || a.z != b.z) {
        return true;
      }
    }
    return false;
  }
}

class _Limb {
  final Joint start;
  final Joint end;

  const _Limb(this.start, this.end);

  double get averageZ => (start.z + end.z) / 2;
}
