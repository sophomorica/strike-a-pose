import 'dart:math' as math;

import 'vec.dart';

enum LandmarkId {
  lShoulder,
  rShoulder,
  lElbow,
  rElbow,
  lWrist,
  rWrist,
  lHip,
  rHip,
  lKnee,
  rKnee,
  lAnkle,
  rAnkle,
}

enum Bend { up, down, inward }

class Landmark {
  final double x;
  final double y;
  final double likelihood;

  const Landmark(this.x, this.y, [this.likelihood = 1]);

  static const missing = Landmark(0, 0, 0);

  Vec get vec => Vec(x, y);
  bool get confident => likelihood >= 0.5;
}

class PoseFrame {
  final Map<LandmarkId, Landmark> points;
  final double imageWidth;
  final double imageHeight;

  const PoseFrame({
    required this.points,
    this.imageWidth = 400,
    this.imageHeight = 700,
  });

  Landmark point(LandmarkId id) => points[id] ?? Landmark.missing;

  int get confidentCount =>
      LandmarkId.values.where((id) => point(id).confident).length;
}

class PoseAngles {
  final double lSh;
  final double rSh;
  final double lEl;
  final double rEl;
  final double lHip;
  final double rHip;
  final double lKn;
  final double rKn;
  final double lean;
  final Bend? lElBend;
  final Bend? rElBend;
  final Bend? lKnBend;
  final Bend? rKnBend;

  const PoseAngles({
    required this.lSh,
    required this.rSh,
    required this.lEl,
    required this.rEl,
    required this.lHip,
    required this.rHip,
    required this.lKn,
    required this.rKn,
    this.lean = 0,
    this.lElBend,
    this.rElBend,
    this.lKnBend,
    this.rKnBend,
  });

  bool get specifiesLean => lean.abs() > 0.5;

  PoseAngles lerp(PoseAngles toward, double alpha) {
    double m(double a, double b) => a + (b - a) * alpha;
    return PoseAngles(
      lSh: m(lSh, toward.lSh),
      rSh: m(rSh, toward.rSh),
      lEl: m(lEl, toward.lEl),
      rEl: m(rEl, toward.rEl),
      lHip: m(lHip, toward.lHip),
      rHip: m(rHip, toward.rHip),
      lKn: m(lKn, toward.lKn),
      rKn: m(rKn, toward.rKn),
      lean: m(lean, toward.lean),
      lElBend: toward.lElBend ?? lElBend,
      rElBend: toward.rElBend ?? rElBend,
      lKnBend: toward.lKnBend ?? lKnBend,
      rKnBend: toward.rKnBend ?? rKnBend,
    );
  }
}

class MeasuredPose {
  final PoseAngles angles;
  final bool lArm;
  final bool rArm;
  final bool lLeg;
  final bool rLeg;
  final bool leanVisible;
  final int confidentCount;
  final bool shouldersVisible;
  final double torsoLength;
  final Vec bodyCenter;
  final Landmark leftAnkle;
  final Landmark rightAnkle;
  final double imageWidth;
  final double imageHeight;
  final double meanLikelihood;

  const MeasuredPose({
    required this.angles,
    required this.lArm,
    required this.rArm,
    required this.lLeg,
    required this.rLeg,
    required this.leanVisible,
    required this.confidentCount,
    required this.shouldersVisible,
    required this.torsoLength,
    required this.bodyCenter,
    required this.leftAnkle,
    required this.rightAnkle,
    required this.imageWidth,
    required this.imageHeight,
    required this.meanLikelihood,
  });
}

const _up = Vec(0, -1);

Vec lateralFromTorso(Vec torsoUp, Vec shoulderRight) {
  var lateral = Vec(-torsoUp.y, torsoUp.x);
  if (lateral.dot(shoulderRight) < 0) lateral = -lateral;
  return lateral.normalized();
}

Bend? classifyBend(Vec boneDir, Vec distalDir, Vec torsoUp, Vec lateral) {
  final deviation = angleBetween(boneDir, distalDir);
  if (deviation <= 20) return null;
  final axis = boneDir.normalized();
  final along = axis * distalDir.dot(axis);
  final perp = (distalDir - along).normalized();
  if (perp.length < 0.5) return null;
  final armDown = -torsoUp;
  final scores = {
    Bend.up: perp.dot(torsoUp),
    Bend.down: perp.dot(armDown),
    Bend.inward: perp.dot(-lateral),
  };
  Bend best = Bend.up;
  var bestScore = -999.0;
  scores.forEach((bend, score) {
    if (score > bestScore) {
      best = bend;
      bestScore = score;
    }
  });
  return best;
}

MeasuredPose measurePose(PoseFrame frame) {
  final ls = frame.point(LandmarkId.lShoulder);
  final rs = frame.point(LandmarkId.rShoulder);
  final le = frame.point(LandmarkId.lElbow);
  final re = frame.point(LandmarkId.rElbow);
  final lw = frame.point(LandmarkId.lWrist);
  final rw = frame.point(LandmarkId.rWrist);
  final lh = frame.point(LandmarkId.lHip);
  final rh = frame.point(LandmarkId.rHip);
  final lk = frame.point(LandmarkId.lKnee);
  final rk = frame.point(LandmarkId.rKnee);
  final la = frame.point(LandmarkId.lAnkle);
  final ra = frame.point(LandmarkId.rAnkle);

  final midHip = ls.confident && rs.confident && lh.confident && rh.confident
      ? (lh.vec + rh.vec) * 0.5
      : Vec.zero;
  final midShoulder = (ls.vec + rs.vec) * 0.5;
  var torsoUp = (midShoulder - ((lh.vec + rh.vec) * 0.5));
  if (torsoUp.length < 1e-3) torsoUp = _up;
  torsoUp = torsoUp.normalized();
  final shoulderRight = rs.vec - ls.vec;
  final lateral = lateralFromTorso(torsoUp, shoulderRight);
  final armDown = -torsoUp;

  double shoulderAngle(Vec shoulder, Vec elbow, Vec side) {
    final upper = elbow - shoulder;
    return degrees(math.atan2(upper.dot(side), upper.dot(armDown)));
  }

  double hipAngle(Vec hip, Vec knee, Vec side) {
    final thigh = knee - hip;
    return degrees(math.atan2(thigh.dot(side), thigh.dot(armDown)));
  }

  double interior(Vec proximal, Vec joint, Vec distal) {
    return angleBetween(proximal - joint, distal - joint);
  }

  final lArm = ls.confident && le.confident && lw.confident;
  final rArm = rs.confident && re.confident && rw.confident;
  final lLeg = lh.confident && lk.confident && la.confident;
  final rLeg = rh.confident && rk.confident && ra.confident;
  final leanVisible = ls.confident && rs.confident && lh.confident && rh.confident;

  final lean = leanVisible
      ? degrees(math.atan2(torsoUp.dot(lateral), torsoUp.dot(_up)))
      : 0.0;

  final angles = PoseAngles(
    lSh: lArm ? shoulderAngle(ls.vec, le.vec, -lateral) : 0,
    rSh: rArm ? shoulderAngle(rs.vec, re.vec, lateral) : 0,
    lEl: lArm ? interior(ls.vec, le.vec, lw.vec) : 180,
    rEl: rArm ? interior(rs.vec, re.vec, rw.vec) : 180,
    lHip: lLeg ? hipAngle(lh.vec, lk.vec, -lateral) : 0,
    rHip: rLeg ? hipAngle(rh.vec, rk.vec, lateral) : 0,
    lKn: lLeg ? interior(lh.vec, lk.vec, la.vec) : 180,
    rKn: rLeg ? interior(rh.vec, rk.vec, ra.vec) : 180,
    lean: lean,
    lElBend: lArm ? classifyBend(le.vec - ls.vec, lw.vec - le.vec, torsoUp, -lateral) : null,
    rElBend: rArm ? classifyBend(re.vec - rs.vec, rw.vec - re.vec, torsoUp, lateral) : null,
    lKnBend: lLeg ? classifyBend(lk.vec - lh.vec, la.vec - lk.vec, torsoUp, -lateral) : null,
    rKnBend: rLeg ? classifyBend(rk.vec - rh.vec, ra.vec - rk.vec, torsoUp, lateral) : null,
  );

  final visible = LandmarkId.values.where((id) => frame.point(id).confident);
  final mean = visible.isEmpty
      ? 0.0
      : visible.map((id) => frame.point(id).likelihood).reduce((a, b) => a + b) /
          visible.length;

  return MeasuredPose(
    angles: angles,
    lArm: lArm,
    rArm: rArm,
    lLeg: lLeg,
    rLeg: rLeg,
    leanVisible: leanVisible,
    confidentCount: frame.confidentCount,
    shouldersVisible: ls.confident && rs.confident,
    torsoLength: leanVisible ? (midShoulder - midHip).length : 0,
    bodyCenter: leanVisible ? midShoulder : Vec.zero,
    leftAnkle: la,
    rightAnkle: ra,
    imageWidth: frame.imageWidth,
    imageHeight: frame.imageHeight,
    meanLikelihood: mean,
  );
}

/// Builds a body whose measured angles match [target]. Fixtures and the wall hole share this.
PoseFrame synthesizePose(
  PoseAngles target, {
  double torso = 180,
  double shoulderHalf = 48,
  Vec origin = const Vec(200, 420),
  double imageWidth = 400,
  double imageHeight = 700,
  double likelihood = 1,
  Map<LandmarkId, double>? likelihoods,
}) {
  final torsoUp = (_up * math.cos(radians(target.lean)) +
          const Vec(1, 0) * math.sin(radians(target.lean)))
      .normalized();
  final lateral = Vec(-torsoUp.y, torsoUp.x).normalized();
  final armDown = -torsoUp;
  final midHip = origin;
  final midShoulder = origin + torsoUp * torso;
  final lShoulder = midShoulder + (-lateral) * shoulderHalf;
  final rShoulder = midShoulder + lateral * shoulderHalf;
  final lHip = midHip + (-lateral) * (shoulderHalf * 0.55);
  final rHip = midHip + lateral * (shoulderHalf * 0.55);

  Vec limbEnd(Vec joint, Vec boneDir, double interior, Bend? bend, Vec side, double length) {
    final phi = radians(180 - interior);
    final bendAxis = switch (bend) {
      Bend.up => torsoUp,
      Bend.down => armDown,
      Bend.inward => -side,
      null => side,
    };
    final dir = (boneDir.normalized() * math.cos(phi) + bendAxis.normalized() * math.sin(phi))
        .normalized();
    final safe = dir.length < 0.5 ? boneDir.normalized() : dir;
    return joint + safe * length;
  }

  Vec placeProximal(Vec joint, double angle, Vec side, double length) {
    final dir = armDown * math.cos(radians(angle)) + side * math.sin(radians(angle));
    return joint + dir.normalized() * length;
  }

  final lElbow = placeProximal(lShoulder, target.lSh, -lateral, torso * 0.42);
  final rElbow = placeProximal(rShoulder, target.rSh, lateral, torso * 0.42);
  final lWrist = limbEnd(lElbow, lElbow - lShoulder, target.lEl, target.lElBend, -lateral, torso * 0.38);
  final rWrist = limbEnd(rElbow, rElbow - rShoulder, target.rEl, target.rElBend, lateral, torso * 0.38);
  final lKnee = placeProximal(lHip, target.lHip, -lateral, torso * 0.52);
  final rKnee = placeProximal(rHip, target.rHip, lateral, torso * 0.52);
  final lAnkle = limbEnd(lKnee, lKnee - lHip, target.lKn, target.lKnBend, -lateral, torso * 0.48);
  final rAnkle = limbEnd(rKnee, rKnee - rHip, target.rKn, target.rKnBend, lateral, torso * 0.48);

  Landmark mark(LandmarkId id, Vec v) =>
      Landmark(v.x, v.y, likelihoods?[id] ?? likelihood);

  return PoseFrame(
    imageWidth: imageWidth,
    imageHeight: imageHeight,
    points: {
      LandmarkId.lShoulder: mark(LandmarkId.lShoulder, lShoulder),
      LandmarkId.rShoulder: mark(LandmarkId.rShoulder, rShoulder),
      LandmarkId.lElbow: mark(LandmarkId.lElbow, lElbow),
      LandmarkId.rElbow: mark(LandmarkId.rElbow, rElbow),
      LandmarkId.lWrist: mark(LandmarkId.lWrist, lWrist),
      LandmarkId.rWrist: mark(LandmarkId.rWrist, rWrist),
      LandmarkId.lHip: mark(LandmarkId.lHip, lHip),
      LandmarkId.rHip: mark(LandmarkId.rHip, rHip),
      LandmarkId.lKnee: mark(LandmarkId.lKnee, lKnee),
      LandmarkId.rKnee: mark(LandmarkId.rKnee, rKnee),
      LandmarkId.lAnkle: mark(LandmarkId.lAnkle, lAnkle),
      LandmarkId.rAnkle: mark(LandmarkId.rAnkle, rAnkle),
    },
  );
}

PoseFrame neutralFrame() {
  return synthesizePose(
    const PoseAngles(
      lSh: 0,
      rSh: 0,
      lEl: 180,
      rEl: 180,
      lHip: 0,
      rHip: 0,
      lKn: 180,
      rKn: 180,
    ),
  );
}

PoseFrame emptyFrame() {
  return PoseFrame(
    points: {for (final id in LandmarkId.values) id: Landmark.missing},
  );
}
