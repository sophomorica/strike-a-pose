import 'dart:math';

import 'pose.dart';
import 'round.dart';

const _head = Joint(0, 0.78, 0);
const _shoulderL = Joint(-0.20, 0.56, 0);
const _shoulderR = Joint(0.20, 0.56, 0);
const _hipL = Joint(-0.11, 0.02, 0);
const _hipR = Joint(0.11, 0.02, 0);

Joint _limbEnd(Joint origin, double degrees, double length, double z) {
  final r = degrees * pi / 180;
  return Joint(origin.x + length * sin(r), origin.y - length * cos(r), z);
}

class PoseCatalog {
  static final List<PoseDefinition> all = List.unmodifiable([
    _pose('Star', -140, -150, 140, 150, -25, -30, 25, 30, 0, 0),
    _pose('Cactus', -100, -170, 100, 170, -5, -5, 5, 5, 0, 0),
    _pose('Surfer', -90, -90, 90, 90, -20, 20, 20, -20, 0, 0),
    _pose('Archer', -80, -10, 20, 100, -8, -8, 8, 8, 0.35, -0.05),
    _pose('Tree', -160, -150, 160, 150, -5, -5, 70, 40, 0, 0),
    _pose('Disco', -170, -160, 40, 10, -30, -10, 15, 40, 0, 0),
    _pose('Hero', -40, -130, 40, 130, -6, -6, 6, 6, 0, 0),
    _pose('Flamingo', -100, -40, 100, 40, -4, -4, 90, 10, 0, 0),
    _pose('Airplane', -90, -90, 90, 90, 15, 20, -8, -8, 0.15, 0.15),
    _pose('Robot', -90, 0, 90, 0, -4, -4, 4, 4, 0, 0),
    _pose('Victory', -140, -140, 150, 150, -6, -6, 6, 6, 0, 0),
    _pose('Sprinter', -50, -20, 120, 150, 40, 10, -30, -50, 0, 0),
    _pose('Moon', -100, -200, 160, 200, -20, -40, 30, 10, 0, 0),
    _pose('Keeper', -100, -20, 100, 20, -45, 30, 45, -30, 0, 0),
    _pose('Boxer', -110, -40, 110, 40, -15, 5, 15, -5, 0.05, 0.35),
    _pose('Dancer', -160, -140, 30, 80, -10, -10, 50, 90, 0, 0),
    _pose('Scarecrow', -90, 70, 90, -70, -20, 10, 25, -5, 0, 0),
    _pose('Ski', 30, 50, -30, -50, -35, 10, 35, -10, 0, 0),
    _pose('Lunge', -20, -20, 20, 20, -50, -70, 40, 10, 0, 0),
    _pose('Tiptoe', -150, -60, 20, 70, -4, 25, 8, -30, 0, 0),
    _pose('Flex', -60, -160, 60, 160, -12, 8, 18, -8, 0, 0),
    _pose('Wave', -160, -90, 10, 10, -5, -5, 5, 5, 0, 0),
    _pose('Beam', -90, -90, 90, 90, -8, -8, 70, 70, 0, 0),
    _pose('Lightning', -60, 30, 140, 60, -10, 20, 10, -20, 0, 0),
    _pose('Kick', -40, -20, 40, 20, -5, -5, 100, 80, 0, 0),
    _pose('Squat', -40, -90, 40, -90, -55, 70, 55, -70, 0, 0),
    _pose('Jazz', -125, -175, 55, 90, -40, -15, 25, 55, 0, 0),
    _pose('Compass', -180, -180, 0, 0, -6, -6, 6, 6, 0, 0),
    _pose('Windmill', -170, -170, 10, 10, 20, 20, -20, -20, 0, 0),
    _pose('Rocket', -175, -175, 175, 175, -2, -2, 2, 2, 0, 0),
  ]);
}

PoseDefinition _pose(
  String name,
  double leftUpper,
  double leftFore,
  double rightUpper,
  double rightFore,
  double leftThigh,
  double leftShin,
  double rightThigh,
  double rightShin,
  double leftWristZ,
  double rightWristZ,
) {
  final elbowL = _limbEnd(_shoulderL, leftUpper, 0.30, 0);
  final elbowR = _limbEnd(_shoulderR, rightUpper, 0.30, 0);
  final kneeL = _limbEnd(_hipL, leftThigh, 0.42, 0);
  final kneeR = _limbEnd(_hipR, rightThigh, 0.42, 0);
  return PoseDefinition(
    name,
    PoseSkeleton(
      head: _head,
      shoulderL: _shoulderL,
      shoulderR: _shoulderR,
      elbowL: elbowL,
      elbowR: elbowR,
      wristL: _limbEnd(elbowL, leftFore, 0.28, leftWristZ),
      wristR: _limbEnd(elbowR, rightFore, 0.28, rightWristZ),
      hipL: _hipL,
      hipR: _hipR,
      kneeL: kneeL,
      kneeR: kneeR,
      ankleL: _limbEnd(kneeL, leftShin, 0.40, 0),
      ankleR: _limbEnd(kneeR, rightShin, 0.40, 0),
    ),
  );
}

RoundPlan practiceRound(int seed) {
  final copy = [...PoseCatalog.all];
  copy.shuffle(Random(seed));
  return RoundPlan(copy.take(5).toList());
}
