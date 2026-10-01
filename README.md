# Strike a Pose

One iPhone, passed around the room. Players copy the hole in a foam wall. The phone scores the pose and keeps the snapshot in the app.

This is the v1 game. The old practice round is gone.

## Clone

```bash
git clone https://github.com/sophomorica/strike-a-pose.git
cd strike-a-pose
flutter pub get
```

Flutter 3.47.5 matches `.metadata`.

## Run the tests

```bash
flutter analyze
flutter test
```

Pose scoring is pure Dart behind `PoseFeed`. `MlKitPoseSource` is the only production detector, and tests never import it.

## Run it on an iPhone

See [DEVICE-CHECK.md](DEVICE-CHECK.md). Deployment target is iOS 15.5, team `JQ7J89B22A`, bundle id `com.narrowroad.strikeapose`.

```bash
flutter run
```

A debug build can use the scripted body only with both conditions true: a debug build, and `--dart-define=FAKE_POSE=true`. Release builds cannot construct that source.
