import 'package:flutter_test/flutter_test.dart';
import 'package:strike_a_pose/fake_pose.dart';
import 'package:strike_a_pose/pose.dart';
import 'package:strike_a_pose/pose_catalog.dart';
import 'package:strike_a_pose/pose_matcher.dart';

void main() {
  PoseReading readingOf(PoseSkeleton skeleton, {Joint? head}) {
    return PoseReading(
      PoseSkeleton(
        head: head ?? skeleton.head,
        shoulderL: skeleton.shoulderL,
        shoulderR: skeleton.shoulderR,
        elbowL: skeleton.elbowL,
        elbowR: skeleton.elbowR,
        wristL: skeleton.wristL,
        wristR: skeleton.wristR,
        hipL: skeleton.hipL,
        hipR: skeleton.hipR,
        kneeL: skeleton.kneeL,
        kneeR: skeleton.kneeR,
        ankleL: skeleton.ankleL,
        ankleR: skeleton.ankleR,
      ),
    );
  }

  test('a fake reading of the first pose is a hit', () {
    final pose = PoseCatalog.all.first;
    expect(
      matchPose(target: pose, reading: fakePoseReading(pose)),
      PoseVerdict.hit,
    );
  });

  test('a wrist shifted by 0.25 is a miss', () {
    final pose = PoseCatalog.all.first;
    final skeleton = pose.skeleton;
    final shifted = PoseSkeleton(
      head: skeleton.head,
      shoulderL: skeleton.shoulderL,
      shoulderR: skeleton.shoulderR,
      elbowL: skeleton.elbowL,
      elbowR: skeleton.elbowR,
      wristL: Joint(
        skeleton.wristL.x + 0.25,
        skeleton.wristL.y,
        skeleton.wristL.z,
      ),
      wristR: skeleton.wristR,
      hipL: skeleton.hipL,
      hipR: skeleton.hipR,
      kneeL: skeleton.kneeL,
      kneeR: skeleton.kneeR,
      ankleL: skeleton.ankleL,
      ankleR: skeleton.ankleR,
    );
    expect(
      matchPose(target: pose, reading: PoseReading(shifted)),
      PoseVerdict.miss,
    );
  });

  test('a NaN head x is a miss', () {
    final pose = PoseCatalog.all.first;
    final head = pose.skeleton.head;
    expect(
      matchPose(target: pose, reading: readingOf(pose.skeleton)),
      PoseVerdict.hit,
    );
    expect(
      matchPose(
        target: pose,
        reading: readingOf(
          pose.skeleton,
          head: Joint(double.nan, head.y, head.z),
        ),
      ),
      PoseVerdict.miss,
    );
  });

  test('an infinite head x is a miss', () {
    final pose = PoseCatalog.all.first;
    final head = pose.skeleton.head;
    expect(
      matchPose(
        target: pose,
        reading: readingOf(
          pose.skeleton,
          head: Joint(double.infinity, head.y, head.z),
        ),
      ),
      PoseVerdict.miss,
    );
  });

  test('the first pose against the second skeleton is a miss', () {
    expect(
      matchPose(
        target: PoseCatalog.all[0],
        reading: PoseReading(PoseCatalog.all[1].skeleton),
      ),
      PoseVerdict.miss,
    );
  });

  test('every distinct catalog pair is a miss', () {
    final all = PoseCatalog.all;
    for (var i = 0; i < all.length; i++) {
      for (var j = i + 1; j < all.length; j++) {
        expect(
          matchPose(target: all[i], reading: PoseReading(all[j].skeleton)),
          PoseVerdict.miss,
          reason: '${all[i].name} vs ${all[j].name}',
        );
        expect(
          matchPose(target: all[j], reading: PoseReading(all[i].skeleton)),
          PoseVerdict.miss,
          reason: '${all[j].name} vs ${all[i].name}',
        );
      }
    }
  });
}
