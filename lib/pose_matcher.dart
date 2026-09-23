import 'pose.dart';

const double _hitTolerance = 0.08;

PoseVerdict matchPose({
  required PoseDefinition target,
  required PoseReading reading,
}) {
  final targets = target.skeleton.joints;
  final readings = reading.skeleton.joints;
  final toleranceSquared = _hitTolerance * _hitTolerance;
  var maxSquared = 0.0;
  for (var i = 0; i < targets.length; i++) {
    final squared = _distanceSquared(targets[i], readings[i]);
    if (squared > maxSquared) {
      maxSquared = squared;
    }
  }
  if (maxSquared <= toleranceSquared) {
    return PoseVerdict.hit;
  }
  return PoseVerdict.miss;
}

double _distanceSquared(Joint a, Joint b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  final dz = a.z - b.z;
  return dx * dx + dy * dy + dz * dz;
}
