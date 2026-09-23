import 'pose.dart';

PoseReading fakePoseReading(PoseDefinition target) {
  final skeleton = target.skeleton;
  return PoseReading(
    PoseSkeleton(
      head: _shift(skeleton.head),
      shoulderL: _shift(skeleton.shoulderL),
      shoulderR: _shift(skeleton.shoulderR),
      elbowL: _shift(skeleton.elbowL),
      elbowR: _shift(skeleton.elbowR),
      wristL: _shift(skeleton.wristL),
      wristR: _shift(skeleton.wristR),
      hipL: _shift(skeleton.hipL),
      hipR: _shift(skeleton.hipR),
      kneeL: _shift(skeleton.kneeL),
      kneeR: _shift(skeleton.kneeR),
      ankleL: _shift(skeleton.ankleL),
      ankleR: _shift(skeleton.ankleR),
    ),
  );
}

Joint _shift(Joint joint) => Joint(joint.x + 0.02, joint.y, joint.z);
