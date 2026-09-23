class Joint {
  final double x;
  final double y;
  final double z;

  const Joint(this.x, this.y, this.z);
}

class PoseSkeleton {
  final Joint head;
  final Joint shoulderL;
  final Joint shoulderR;
  final Joint elbowL;
  final Joint elbowR;
  final Joint wristL;
  final Joint wristR;
  final Joint hipL;
  final Joint hipR;
  final Joint kneeL;
  final Joint kneeR;
  final Joint ankleL;
  final Joint ankleR;

  const PoseSkeleton({
    required this.head,
    required this.shoulderL,
    required this.shoulderR,
    required this.elbowL,
    required this.elbowR,
    required this.wristL,
    required this.wristR,
    required this.hipL,
    required this.hipR,
    required this.kneeL,
    required this.kneeR,
    required this.ankleL,
    required this.ankleR,
  });

  List<Joint> get joints => [
    head,
    shoulderL,
    shoulderR,
    elbowL,
    wristL,
    elbowR,
    wristR,
    hipL,
    hipR,
    kneeL,
    ankleL,
    kneeR,
    ankleR,
  ];
}

class PoseDefinition {
  final String name;
  final PoseSkeleton skeleton;

  const PoseDefinition(this.name, this.skeleton);
}

class PoseReading {
  final PoseSkeleton skeleton;

  const PoseReading(this.skeleton);
}

enum PoseVerdict { hit, miss }
