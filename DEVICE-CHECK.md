# Device check

Run this on a physical iPhone signed with team `JQ7J89B22A`. Bundle id stays `com.narrowroad.strikeapose`. Do not upload to TestFlight.

The podspec on disk for `google_mlkit_pose_detection` 0.14.1 sets `s.platform` and `s.ios.deployment_target` to 15.5 and depends on `GoogleMLKit/PoseDetection` `~> 9.0.0` plus `GoogleMLKit/PoseDetectionAccurate` `~> 9.0.0`. `google_mlkit_commons` 0.11.1 depends on `MLKitVision` `~> 10.0.0` and also requires 15.5. `camera_avfoundation` 0.9.23+2 allows iOS 13.0, so 15.5 is the binding minimum. The Podfile and the Xcode project are set to 15.5.

1. Open `ios/Runner.xcworkspace` and confirm the Runner target's iOS deployment target is 15.5. Run `pod install` if Xcode asks. The app should install on an iPhone that can run 15.5. It should refuse to build if that target is lowered under the ML Kit pods.
2. Fresh install. Launch. Confirm no permission prompt yet. Tap Play, add two names, tap Strike a pose. Read the mirror priming screen, then tap Continue. The only system prompt is the camera prompt, with the usage string from Info.plist. Allow it.
3. Stand about three big steps back. Confirm the front camera is mirrored, the foam wall is treatment A, and a Star Jump lights the limbs and can score. Hold the match for about one second. The snapshot stays in the app. Nothing asks to save to Photos, and nothing offers share.
4. Deny the camera on a second fresh install (or reset the permission). Continue after priming. The screen offers Open Settings and Play Referee mode. Open Settings should open the iOS Settings page for this app. Referee mode scores a turn with no camera.
5. Turn on Airplane mode and play a full game. There should be no network prompt and no Bluetooth or local-network prompt.
6. Play a Kids deck game, leave some snaps without a heart, and tap Done. Confirm the delete sheet. After you continue, those files are gone from the app's gallery and the kept ones remain. Force-quit a Kids game before the end, relaunch, and confirm that unfinished game left no files.
