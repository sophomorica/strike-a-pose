import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory.current.path;

  test('Info.plist asks only for the camera, with the spec string', () {
    final plist = File('$root/ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains('NSCameraUsageDescription'));
    expect(
      plist,
      contains(
        'Strike a Pose uses the front camera as a mirror so it can see your pose and score it. Video is processed on this iPhone and is never recorded or uploaded.',
      ),
    );
    for (final banned in [
      'NSPhotoLibrary',
      'NSPhotoLibraryUsageDescription',
      'NSMicrophone',
      'NSBluetooth',
      'NSLocalNetwork',
      'NSBonjour',
    ]) {
      expect(plist.contains(banned), isFalse, reason: banned);
    }
  });

  test('deployment target is 15.5 and the bundle id is unchanged', () {
    final podfile = File('$root/ios/Podfile').readAsStringSync();
    final project = File('$root/ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    expect(podfile, contains("platform :ios, '15.5'"));
    expect(project.contains('IPHONEOS_DEPLOYMENT_TARGET = 16'), isFalse);
    expect('15.5'.allMatches(project).isNotEmpty, isTrue);
    expect(project, contains('PRODUCT_BUNDLE_IDENTIFIER = com.narrowroad.strikeapose;'));
    expect(project, contains('DEVELOPMENT_TEAM = JQ7J89B22A;'));
    expect(project, contains('EXCLUDED_ARCHS = armv7'));
  });

  test('the source has no save, share, vision, or multipeer path', () {
    final files = Directory('$root/lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();
    final joined = files.map((file) => file.readAsStringSync()).join('\n');
    for (final banned in [
      'PHPhotoLibrary',
      'UIActivityViewController',
      'UIImageWriteToSavedPhotosAlbum',
      'image_gallery_saver',
      'photo_manager',
      'image_picker',
      'share_plus',
      'MultipeerConnectivity',
      'VNDetectHumanBodyPose',
      'Duo',
    ]) {
      expect(joined.contains(banned), isFalse, reason: banned);
    }
    final mlkit = File('$root/lib/mlkit_pose_source.dart').readAsStringSync();
    expect(mlkit, contains('PoseDetectionModel.base'));
    expect(mlkit, contains('PoseDetectionMode.stream'));
    expect(mlkit, contains('ResolutionPreset.medium'));
    expect(mlkit, contains('ImageFormatGroup.bgra8888'));
    expect(mlkit, contains('enableAudio: false'));
    final tests = Directory('$root/test')
        .listSync()
        .whereType<File>()
        .where((file) =>
            file.path.endsWith('.dart') &&
            !file.path.endsWith('engine_test.dart') &&
            !file.path.endsWith('platform_contract_test.dart'))
        .map((file) => file.readAsStringSync())
        .join('\n');
    expect(tests.contains('google_mlkit_pose_detection'), isFalse);
    expect(tests.contains('FakePoseSource'), isFalse);
  });

  test('pubspec pins the camera and the pose plugin', () {
    final pubspec = File('$root/pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('camera:'));
    expect(pubspec, contains('google_mlkit_pose_detection:'));
    expect(pubspec.contains('share_plus'), isFalse);
    expect(pubspec.contains('image_picker'), isFalse);
  });
}
