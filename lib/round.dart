import 'pose.dart';
import 'pose_matcher.dart';

class RoundPlan {
  final List<PoseDefinition> poses;

  RoundPlan(List<PoseDefinition> poses) : poses = List.unmodifiable(poses) {
    if (this.poses.isEmpty) {
      throw ArgumentError('A round needs at least one pose');
    }
  }
}

sealed class RoundState {
  const RoundState._();
}

class PoseOpen extends RoundState {
  final RoundPlan plan;
  final int index;
  final int score;
  final Duration observedAt;
  final Duration deadline;

  const PoseOpen({
    required this.plan,
    required this.index,
    required this.score,
    required this.observedAt,
    required this.deadline,
  }) : super._();

  PoseDefinition get target => plan.poses[index];
}

class PoseHitFlash extends RoundState {
  final RoundPlan plan;
  final int index;
  final int score;
  final Duration observedAt;
  final Duration until;

  const PoseHitFlash({
    required this.plan,
    required this.index,
    required this.score,
    required this.observedAt,
    required this.until,
  }) : super._();

  PoseDefinition get target => plan.poses[index];
}

class PoseMissed extends RoundState {
  final RoundPlan plan;
  final int index;
  final int score;
  final Duration observedAt;
  final Duration until;

  const PoseMissed({
    required this.plan,
    required this.index,
    required this.score,
    required this.observedAt,
    required this.until,
  }) : super._();

  PoseDefinition get target => plan.poses[index];
}

class RoundOver extends RoundState {
  final int score;
  final int total;

  const RoundOver({required this.score, required this.total}) : super._();
}

sealed class RoundEvent {
  const RoundEvent._();
}

class ClockTicked extends RoundEvent {
  final Duration at;

  const ClockTicked(this.at) : super._();
}

class StrikeSubmitted extends RoundEvent {
  final int poseIndex;
  final Duration at;
  final PoseReading reading;

  const StrikeSubmitted({
    required this.poseIndex,
    required this.at,
    required this.reading,
  }) : super._();
}

const poseWindow = Duration(seconds: 6);
const flashHold = Duration(milliseconds: 400);

RoundState beginRound(RoundPlan plan, {Duration at = Duration.zero}) {
  return PoseOpen(
    plan: plan,
    index: 0,
    score: 0,
    observedAt: at,
    deadline: at + poseWindow,
  );
}

RoundState reduceRound(RoundState state, RoundEvent event) {
  return switch (state) {
    RoundOver() => state,
    PoseOpen() => _reduceOpen(state, event),
    PoseHitFlash() => _reduceSettled(
      state: state,
      event: event,
      observedAt: state.observedAt,
      until: state.until,
      plan: state.plan,
      index: state.index,
      score: state.score,
    ),
    PoseMissed() => _reduceSettled(
      state: state,
      event: event,
      observedAt: state.observedAt,
      until: state.until,
      plan: state.plan,
      index: state.index,
      score: state.score,
    ),
  };
}

RoundState _reduceOpen(PoseOpen state, RoundEvent event) {
  final at = _eventAt(event);
  if (at < state.observedAt) {
    return state;
  }
  switch (event) {
    case StrikeSubmitted(:final poseIndex, :final reading):
      if (poseIndex != state.index) {
        return state;
      }
      if (at >= state.deadline) {
        return _miss(state, at);
      }
      final verdict = matchPose(target: state.target, reading: reading);
      if (verdict == PoseVerdict.hit) {
        return PoseHitFlash(
          plan: state.plan,
          index: state.index,
          score: state.score + 1,
          observedAt: at,
          until: at + flashHold,
        );
      }
      return PoseOpen(
        plan: state.plan,
        index: state.index,
        score: state.score,
        observedAt: at,
        deadline: state.deadline,
      );
    case ClockTicked():
      if (at < state.deadline) {
        return PoseOpen(
          plan: state.plan,
          index: state.index,
          score: state.score,
          observedAt: at,
          deadline: state.deadline,
        );
      }
      return _miss(state, at);
  }
}

RoundState _reduceSettled({
  required RoundState state,
  required RoundEvent event,
  required Duration observedAt,
  required Duration until,
  required RoundPlan plan,
  required int index,
  required int score,
}) {
  final at = _eventAt(event);
  if (at < observedAt) {
    return state;
  }
  return switch (event) {
    StrikeSubmitted() => state,
    ClockTicked() =>
      at < until
          ? state
          : _advance(plan: plan, index: index, score: score, at: at),
  };
}

PoseMissed _miss(PoseOpen state, Duration at) {
  return PoseMissed(
    plan: state.plan,
    index: state.index,
    score: state.score,
    observedAt: at,
    until: at + flashHold,
  );
}

RoundState _advance({
  required RoundPlan plan,
  required int index,
  required int score,
  required Duration at,
}) {
  final next = index + 1;
  if (next < plan.poses.length) {
    return PoseOpen(
      plan: plan,
      index: next,
      score: score,
      observedAt: at,
      deadline: at + poseWindow,
    );
  }
  return RoundOver(score: score, total: plan.poses.length);
}

Duration _eventAt(RoundEvent event) {
  return switch (event) {
    ClockTicked(:final at) => at,
    StrikeSubmitted(:final at) => at,
  };
}
