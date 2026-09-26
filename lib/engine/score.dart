class HoldTimer {
  double held = 0;
  double dip = 0;

  bool get complete => held >= 1 - 1e-9;
  bool get draining => dip >= 0.150 && held > 0 && held < 1;

  void advance(double dt, bool inTolerance) {
    if (dt <= 0) return;
    if (inTolerance) {
      dip = 0;
      held = (held + dt).clamp(0.0, 1.0);
      return;
    }
    final before = dip;
    dip += dt;
    if (dip > 0.150) {
      final drainable = dip - (before > 0.150 ? before : 0.150);
      held = (held - 2 * drainable).clamp(0.0, 1.0);
    }
  }

  void reset() {
    held = 0;
    dip = 0;
  }
}

class ScoreBreakdown {
  final int fitPoints;
  final int holdBonus;
  final int wallBonus;
  final int multiplier;
  final int total;
  final bool perfect;
  final bool matched;
  final int fitPercent;
  final String stamp;

  const ScoreBreakdown({
    required this.fitPoints,
    required this.holdBonus,
    required this.wallBonus,
    required this.multiplier,
    required this.total,
    required this.perfect,
    required this.matched,
    required this.fitPercent,
    required this.stamp,
  });
}

/// Beat-the-wall uses 5 points per second, rounded, capped at 25.
/// Mock-05 shows 2.8s left as +14. The spec's "per full second" cannot yield 14.
ScoreBreakdown scoreMatched({
  required double fit,
  required double secondsLeft,
  required int multiplier,
}) {
  final fitPoints = (fit * 100).round().clamp(0, 100);
  const holdBonus = 10;
  final wallBonus = (secondsLeft * 5).round().clamp(0, 25);
  final safeMultiplier = multiplier < 1 ? 1 : multiplier;
  return ScoreBreakdown(
    fitPoints: fitPoints * safeMultiplier,
    holdBonus: holdBonus * safeMultiplier,
    wallBonus: wallBonus * safeMultiplier,
    multiplier: safeMultiplier,
    total: (fitPoints + holdBonus + wallBonus) * safeMultiplier,
    perfect: fit >= 0.95,
    matched: true,
    fitPercent: fitPoints,
    stamp: fit >= 0.95 ? 'PERFECT FIT' : 'MATCH',
  );
}

ScoreBreakdown scoreMissed(int bestFitPercent) {
  final percent = bestFitPercent.clamp(0, 100);
  return ScoreBreakdown(
    fitPoints: 0,
    holdBonus: 0,
    wallBonus: 0,
    multiplier: 1,
    total: 0,
    perfect: false,
    matched: false,
    fitPercent: percent,
    stamp: 'SO CLOSE · $percent%',
  );
}

ScoreBreakdown scoreReferee({required int multiplier}) {
  final safe = multiplier < 1 ? 1 : multiplier;
  return ScoreBreakdown(
    fitPoints: 100 * safe,
    holdBonus: 0,
    wallBonus: 0,
    multiplier: safe,
    total: 100 * safe,
    perfect: true,
    matched: true,
    fitPercent: 100,
    stamp: 'PERFECT FIT',
  );
}

const judgePickBonus = 50;
