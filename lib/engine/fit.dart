import 'body.dart';

class Tolerance {
  final double fullMarks;
  final double zero;

  const Tolerance(this.fullMarks, this.zero);

  static const normal = Tolerance(15, 45);
  static const kids = Tolerance(22, 55);
  static const hard = Tolerance(10, 35);
}

enum BodyMode { full, upper }

enum LimbId { lArm, rArm, lLeg, rLeg }

enum LimbStatus { unknown, red, amber, green }

enum FitZone { unknown, cold, close, match }

class LimbScore {
  final LimbId id;
  final double score;
  final LimbStatus status;
  final bool visible;

  const LimbScore({
    required this.id,
    required this.score,
    required this.status,
    required this.visible,
  });
}

class FitReading {
  final double fit;
  final int percent;
  final bool inTolerance;
  final FitZone zone;
  final Map<LimbId, LimbScore> limbs;
  final String? coach;
  final bool canSee;

  const FitReading({
    required this.fit,
    required this.percent,
    required this.inTolerance,
    required this.zone,
    required this.limbs,
    required this.coach,
    required this.canSee,
  });

  LimbScore limb(LimbId id) => limbs[id]!;
}

double angleDelta(double a, double b) {
  var d = (a - b).abs() % 360;
  if (d > 180) d = 360 - d;
  return d;
}

double jointCloseness(double delta, Tolerance tolerance) {
  if (delta <= tolerance.fullMarks) return 1;
  if (delta >= tolerance.zero) return 0;
  return 1 - (delta - tolerance.fullMarks) / (tolerance.zero - tolerance.fullMarks);
}

double _bendPenalty(Bend? target, Bend? actual, double interiorDelta) {
  if (target == null) return interiorDelta;
  if (actual == null || actual != target) return interiorDelta + 90;
  return interiorDelta;
}

LimbStatus nextLimbStatus(LimbStatus? previous, double score, bool visible) {
  if (!visible) return LimbStatus.unknown;
  if (previous == null || previous == LimbStatus.unknown) {
    if (score >= 0.80) return LimbStatus.green;
    if (score >= 0.50) return LimbStatus.amber;
    return LimbStatus.red;
  }
  switch (previous) {
    case LimbStatus.green:
      if (score >= 0.75) return LimbStatus.green;
      if (score >= 0.50) return LimbStatus.amber;
      return LimbStatus.red;
    case LimbStatus.amber:
      if (score >= 0.80) return LimbStatus.green;
      if (score < 0.45) return LimbStatus.red;
      return LimbStatus.amber;
    case LimbStatus.red:
      if (score >= 0.80) return LimbStatus.green;
      if (score >= 0.55) return LimbStatus.amber;
      return LimbStatus.red;
    case LimbStatus.unknown:
      return LimbStatus.red;
  }
}

class _JointPair {
  final double proximal;
  final double distal;
  final bool visible;
  const _JointPair(this.proximal, this.distal, this.visible);
}

FitReading evaluateFit({
  required MeasuredPose measured,
  required PoseAngles target,
  required Tolerance tolerance,
  required BodyMode mode,
  Map<LimbId, LimbStatus> previous = const {},
}) {
  final angles = measured.angles;
  _JointPair arm(bool visible, double sh, double el, double tSh, double tEl, Bend? tBend, Bend? aBend) {
    if (!visible) return const _JointPair(0, 0, false);
    final shScore = jointCloseness(angleDelta(sh, tSh), tolerance);
    final elDelta = _bendPenalty(tBend, aBend, angleDelta(el, tEl));
    final elScore = jointCloseness(elDelta, tolerance);
    return _JointPair(shScore, elScore, true);
  }

  final pairs = {
    LimbId.lArm: arm(measured.lArm, angles.lSh, angles.lEl, target.lSh, target.lEl, target.lElBend, angles.lElBend),
    LimbId.rArm: arm(measured.rArm, angles.rSh, angles.rEl, target.rSh, target.rEl, target.rElBend, angles.rElBend),
    LimbId.lLeg: arm(measured.lLeg, angles.lHip, angles.lKn, target.lHip, target.lKn, target.lKnBend, angles.lKnBend),
    LimbId.rLeg: arm(measured.rLeg, angles.rHip, angles.rKn, target.rHip, target.rKn, target.rKnBend, angles.rKnBend),
  };

  final limbs = <LimbId, LimbScore>{};
  for (final id in LimbId.values) {
    final pair = pairs[id]!;
    final raw = pair.visible ? 0.6 * pair.proximal + 0.4 * pair.distal : 0.0;
    final status = nextLimbStatus(previous[id], raw, pair.visible);
    limbs[id] = LimbScore(id: id, score: raw, status: status, visible: pair.visible);
  }

  final scored = mode == BodyMode.upper
      ? [LimbId.lArm, LimbId.rArm]
      : LimbId.values;
  final includeLean = mode == BodyMode.upper || target.specifiesLean;
  var weight = 0.0;
  var total = 0.0;
  for (final id in scored) {
    total += limbs[id]!.score;
    weight += 1;
  }
  if (includeLean) {
    final leanScore = measured.leanVisible
        ? jointCloseness(angleDelta(angles.lean, target.lean), tolerance)
        : 0.0;
    total += leanScore * 0.5;
    weight += 0.5;
  }
  final fit = weight == 0 ? 0.0 : total / weight;
  final percent = (fit * 100).round().clamp(0, 100);
  final scoredLimbs = scored.map((id) => limbs[id]!).toList();
  final anyRed = scoredLimbs.any((limb) => limb.status == LimbStatus.red);
  final canSee = mode == BodyMode.upper
      ? measured.shouldersVisible
      : measured.confidentCount >= 8;
  final inTolerance = canSee && fit >= 0.85 && !anyRed;
  final zone = !canSee
      ? FitZone.unknown
      : inTolerance
          ? FitZone.match
          : percent >= 50
              ? FitZone.close
              : FitZone.cold;
  return FitReading(
    fit: fit,
    percent: percent,
    inTolerance: inTolerance,
    zone: zone,
    limbs: limbs,
    coach: _coach(limbs, measured, target, mode, canSee),
    canSee: canSee,
  );
}

String? _coach(
  Map<LimbId, LimbScore> limbs,
  MeasuredPose measured,
  PoseAngles target,
  BodyMode mode,
  bool canSee,
) {
  if (!canSee) return "Can't see you";
  final considered = mode == BodyMode.upper
      ? [LimbId.lArm, LimbId.rArm]
      : LimbId.values.toList();
  LimbId? worst;
  var worstScore = 2.0;
  for (final id in considered) {
    final limb = limbs[id]!;
    if (!limb.visible) {
      return "Can't see your ${_limbName(id).toLowerCase()}.";
    }
    if (limb.score < worstScore) {
      worst = id;
      worstScore = limb.score;
    }
  }
  if (worst == null || worstScore >= 0.8) return null;
  final angles = measured.angles;
  final name = _limbName(worst);
  if (worst == LimbId.lLeg || worst == LimbId.rLeg) {
    final hip = worst == LimbId.lLeg ? angles.lHip : angles.rHip;
    final targetHip = worst == LimbId.lLeg ? target.lHip : target.rHip;
    if (hip < targetHip - 8) return '$name — kick it out wider!';
    if (hip > targetHip + 8) return '$name — bring it in!';
    return '$name — match the knee!';
  }
  final sh = worst == LimbId.lArm ? angles.lSh : angles.rSh;
  final targetSh = worst == LimbId.lArm ? target.lSh : target.rSh;
  if (sh < targetSh - 8) return '$name — lift it higher!';
  if (sh > targetSh + 8) return '$name — bring it down!';
  return '$name — straighten it!';
}

String _limbName(LimbId id) {
  return switch (id) {
    LimbId.lArm => 'Left arm',
    LimbId.rArm => 'Right arm',
    LimbId.lLeg => 'Left leg',
    LimbId.rLeg => 'Right leg',
  };
}

String limbChip(LimbId id) {
  return switch (id) {
    LimbId.lArm => 'L ARM',
    LimbId.rArm => 'R ARM',
    LimbId.lLeg => 'L LEG',
    LimbId.rLeg => 'R LEG',
  };
}
