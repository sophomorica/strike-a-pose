# Strike a Pose

This repo is the Strike a Pose practice round for Narrow Road Studios.

## Run tests

`flutter test` runs the matcher, the round, and the match screen.

```bash
flutter test
```

## Run on iPhone

Connect an iPhone and run the app. The bundle id is `com.narrowroad.strike_a_pose`. The target is iOS 16. The app is iPhone only and portrait only.

```bash
flutter run
```

## Practice

The practice round uses a stand-in camera. Five poses stay up for six seconds each. Strike scores a point. Waiting out the clock misses.

## Out of scope

This kick does not open the camera, does not use Bluetooth, and does not ship accounts or purchases.

## SDK

Flutter 3.47.5 is the SDK this project was generated with.
