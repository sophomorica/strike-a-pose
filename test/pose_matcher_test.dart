import 'package:flutter_test/flutter_test.dart';
import 'package:strike_a_pose/fake_pose.dart';
import 'package:strike_a_pose/pose.dart';
import 'package:strike_a_pose/pose_catalog.dart';
import 'package:strike_a_pose/pose_matcher.dart';

void main() {
  PoseReading readingOf(
    PoseSkeleton skeleton, {
    Joint? head,
    Joint? wristL,
    Joint? ankleR,
    double shiftX = 0,
  }) {
    Joint shifted(Joint joint) => Joint(joint.x + shiftX, joint.y, joint.z);
    return PoseReading(
      PoseSkeleton(
        head: head ?? shifted(skeleton.head),
        shoulderL: shifted(skeleton.shoulderL),
        shoulderR: shifted(skeleton.shoulderR),
        elbowL: shifted(skeleton.elbowL),
        elbowR: shifted(skeleton.elbowR),
        wristL: wristL ?? shifted(skeleton.wristL),
        wristR: shifted(skeleton.wristR),
        hipL: shifted(skeleton.hipL),
        hipR: shifted(skeleton.hipR),
        kneeL: shifted(skeleton.kneeL),
        kneeR: shifted(skeleton.kneeR),
        ankleL: shifted(skeleton.ankleL),
        ankleR: ankleR ?? shifted(skeleton.ankleR),
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

  test('a left wrist moved 0.05 in depth is a hit', () {
    final pose = PoseCatalog.all.first;
    final wrist = pose.skeleton.wristL;
    expect(
      matchPose(
        target: pose,
        reading: readingOf(
          pose.skeleton,
          wristL: Joint(wrist.x, wrist.y, wrist.z + 0.05),
        ),
      ),
      PoseVerdict.hit,
    );
  });

  test('a left wrist moved 0.12 in depth is a miss', () {
    final pose = PoseCatalog.all.first;
    final wrist = pose.skeleton.wristL;
    expect(
      matchPose(
        target: pose,
        reading: readingOf(
          pose.skeleton,
          wristL: Joint(wrist.x, wrist.y, wrist.z + 0.12),
        ),
      ),
      PoseVerdict.miss,
    );
  });

  test('a right ankle off by 0.25 is a miss', () {
    final pose = PoseCatalog.all.first;
    final ankle = pose.skeleton.ankleR;
    expect(
      matchPose(
        target: pose,
        reading: readingOf(
          pose.skeleton,
          ankleR: Joint(ankle.x + 0.25, ankle.y, ankle.z),
        ),
      ),
      PoseVerdict.miss,
    );
  });

  test('every joint shifted 0.05 in x is a hit', () {
    final pose = PoseCatalog.all.first;
    expect(
      matchPose(target: pose, reading: readingOf(pose.skeleton, shiftX: 0.05)),
      PoseVerdict.hit,
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
