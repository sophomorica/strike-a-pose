import 'package:flutter_test/flutter_test.dart';
import 'package:strike_a_pose/fake_pose.dart';
import 'package:strike_a_pose/pose_catalog.dart';
import 'package:strike_a_pose/round.dart';

void main() {
  RoundPlan onePose() => RoundPlan([PoseCatalog.all.first]);

  RoundPlan twoPoses() => RoundPlan([PoseCatalog.all[0], PoseCatalog.all[1]]);

  test('an empty plan throws', () {
    expect(() => RoundPlan([]), throwsArgumentError);
  });

  test('beginRound opens the first pose at the six second deadline', () {
    final state = beginRound(onePose(), at: Duration.zero);
    expect(state, isA<PoseOpen>());
    final open = state as PoseOpen;
    expect(open.index, 0);
    expect(open.score, 0);
    expect(open.deadline, const Duration(seconds: 6));
    expect(open.observedAt, Duration.zero);
  });

  test('a fake strike at one second flashes a hit', () {
    final open = beginRound(onePose()) as PoseOpen;
    final next = reduceRound(
      open,
      StrikeSubmitted(
        poseIndex: 0,
        at: const Duration(seconds: 1),
        reading: fakePoseReading(open.target),
      ),
    );
    expect(next, isA<PoseHitFlash>());
    final flash = next as PoseHitFlash;
    expect(flash.score, 1);
    expect(flash.until, const Duration(milliseconds: 1400));
    expect(flash.index, 0);
  });

  test('a second strike during the hit flash is ignored', () {
    final open = beginRound(onePose()) as PoseOpen;
    final flash = reduceRound(
      open,
      StrikeSubmitted(
        poseIndex: 0,
        at: const Duration(seconds: 1),
        reading: fakePoseReading(open.target),
      ),
    ) as PoseHitFlash;
    final again = reduceRound(
      flash,
      StrikeSubmitted(
        poseIndex: flash.index,
        at: const Duration(milliseconds: 1200),
        reading: fakePoseReading(flash.target),
      ),
    );
    expect(identical(again, flash), isTrue);
    expect((again as PoseHitFlash).score, 1);
  });

  test('a strike at exactly six seconds misses', () {
    final open = beginRound(onePose()) as PoseOpen;
    final next = reduceRound(
      open,
      StrikeSubmitted(
        poseIndex: 0,
        at: const Duration(seconds: 6),
        reading: fakePoseReading(open.target),
      ),
    );
    expect(next, isA<PoseMissed>());
    expect((next as PoseMissed).score, 0);
  });

  test('a clock tick at six seconds misses', () {
    final next = reduceRound(
      beginRound(onePose()),
      const ClockTicked(Duration(seconds: 6)),
    );
    expect(next, isA<PoseMissed>());
    final missed = next as PoseMissed;
    expect(missed.score, 0);
    expect(missed.until, const Duration(milliseconds: 6400));
  });

  test('a miss flash on a one-pose plan ends the round', () {
    final missed = reduceRound(
      beginRound(onePose()),
      const ClockTicked(Duration(seconds: 6)),
    );
    final next = reduceRound(
      missed,
      const ClockTicked(Duration(milliseconds: 6400)),
    );
    expect(next, isA<RoundOver>());
    final over = next as RoundOver;
    expect(over.score, 0);
    expect(over.total, 1);
  });

  test('a miss flash on a two-pose plan opens the next pose', () {
    final missed = reduceRound(
      beginRound(twoPoses()),
      const ClockTicked(Duration(seconds: 6)),
    );
    final next = reduceRound(
      missed,
      const ClockTicked(Duration(milliseconds: 6400)),
    );
    expect(next, isA<PoseOpen>());
    final open = next as PoseOpen;
    expect(open.index, 1);
    expect(open.score, 0);
    expect(open.observedAt, const Duration(milliseconds: 6400));
    expect(open.deadline, const Duration(milliseconds: 6400) + poseWindow);
  });

  test('a hit flash on the last pose ends the round with a point', () {
    final open = beginRound(onePose()) as PoseOpen;
    final flash = reduceRound(
      open,
      StrikeSubmitted(
        poseIndex: 0,
        at: const Duration(seconds: 1),
        reading: fakePoseReading(open.target),
      ),
    ) as PoseHitFlash;
    final next = reduceRound(flash, ClockTicked(flash.until));
    expect(next, isA<RoundOver>());
    final over = next as RoundOver;
    expect(over.score, 1);
    expect(over.total, 1);
  });

  test('a clock tick before the deadline stays on the open pose', () {
    final next = reduceRound(
      beginRound(onePose()),
      const ClockTicked(Duration(seconds: 2)),
    );
    expect(next, isA<PoseOpen>());
    final open = next as PoseOpen;
    expect(open.index, 0);
    expect(open.score, 0);
    expect(open.deadline, const Duration(seconds: 6));
    expect(open.observedAt, const Duration(seconds: 2));
  });

  test('a clock tick older than observedAt is ignored', () {
    final moved = reduceRound(
      beginRound(onePose()),
      const ClockTicked(Duration(seconds: 2)),
    );
    final ignored = reduceRound(moved, const ClockTicked(Duration(seconds: 1)));
    expect(identical(ignored, moved), isTrue);
  });

  test('practiceRound deals five distinct poses', () {
    final poses = practiceRound(7).poses;
    expect(poses.length, 5);
    expect(poses.map((pose) => pose.name).toSet().length, 5);
  });
}
