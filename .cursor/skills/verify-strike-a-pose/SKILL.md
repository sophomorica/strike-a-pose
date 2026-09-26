# Verify Strike a Pose

This app is Flutter. The harness is `flutter test` and `flutter analyze`. There is no browser and no iOS simulator on this machine.

## Launch

```bash
export PATH="$HOME/sdk/flutter/bin:$PATH"
cd /workspace
flutter pub get
```

## Doctor

```bash
flutter analyze
```

Clean means no issues. The iOS target check is `test/platform_contract_test.dart`.

## Drive

One pass through the first-play path, which does not use the camera plugin:

```bash
flutter test test/widget_test.dart --name "first play" --reporter expanded
```

That test adds Jess and Theo, opens the deck, and lands on the mirror priming screen.

The scoring drive is:

```bash
flutter test test/engine_test.dart --reporter expanded
```

The photo and undo checks are `test/snap_image_test.dart` (fixture pixels are mirrored and are not the drawn stage) and the engine test `a deleted snap file is gone after the 5 second undo`.

## Evidence

Screenshots of each screen are written by `flutter test test/golden_test.dart` to `artifacts/screens/` and `/opt/cursor/artifacts/screens/`. The design-pack mock PNGs were not on disk, so there is no side-by-side composite.

Keep the analyzer and test logs from the last full run. Do not delete `artifacts/screens/`.

## Cleanup

`flutter test` does not start a server. Nothing to stop. Do not run `flutter clean` as part of a check. It only throws away the build cache.

## Helpers

- Widget tests construct `StrikeShell` with `driveClock: false` and `boot: false` when they only need a still screen. They drive `GameSession` with `synthesizePose` frames. They do not construct `FakePoseSource`.
- `FakePoseSource` throws unless the build is debug and `FAKE_POSE` is true. The production path is `MlKitPoseSource` in `lib/mlkit_pose_source.dart`, imported only from `lib/main.dart`.
