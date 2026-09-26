import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'engine/body.dart';
import 'engine/mirror.dart';
import 'pose_feed.dart';

/// Front camera plus ML Kit stream mode, base model. Tests never import this file.
class MlKitPoseSource implements PoseFeed {
  CameraController? _camera;
  PoseDetector? _detector;
  final _frames = StreamController<PoseFrame>.broadcast();
  final _changes = FeedSignal();
  var _seen = 0;
  var _busy = false;
  var _running = false;

  @override
  Stream<PoseFrame> get frames => _frames.stream;

  @override
  Listenable get changes => _changes;

  @override
  Widget? buildPreview() {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) return null;
    return Transform.flip(
      flipX: true,
      child: CameraPreview(camera),
    );
  }

  @override
  Future<bool> start() async {
    if (_running) return true;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return false;
      final front = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );
      _camera = controller;
      await controller.initialize();
      _detector ??= PoseDetector(
        options: PoseDetectorOptions(
          model: PoseDetectionModel.base,
          mode: PoseDetectionMode.stream,
        ),
      );
      _running = true;
      await controller.startImageStream((image) => _onFrame(image, front.sensorOrientation));
      _changes.ping();
      return true;
    } catch (_) {
      await stop();
      return false;
    }
  }

  Future<void> _onFrame(CameraImage image, int sensorOrientation) async {
    _seen += 1;
    if (_seen.isOdd || _busy || _detector == null) return;
    _busy = true;
    try {
      final frame = await _detect(image, sensorOrientation);
      if (!_frames.isClosed) _frames.add(frame);
    } catch (_) {
      if (!_frames.isClosed) {
        _frames.add(_empty(image.width.toDouble(), image.height.toDouble()));
      }
    } finally {
      _busy = false;
    }
  }

  Future<PoseFrame> _detect(CameraImage image, int sensorOrientation) async {
    final rotation = switch (rotationFromSensor(sensorOrientation)) {
      InputRotation.deg0 => InputImageRotation.rotation0deg,
      InputRotation.deg90 => InputImageRotation.rotation90deg,
      InputRotation.deg180 => InputImageRotation.rotation180deg,
      InputRotation.deg270 => InputImageRotation.rotation270deg,
    };
    final plane = image.planes.first;
    final input = InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.bgra8888,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
    final poses = await _detector!.processImage(input);
    if (poses.isEmpty) return _empty(image.width.toDouble(), image.height.toDouble());
    final pose = poses.first;
    Landmark mapOne(PoseLandmarkType type) {
      final mark = pose.landmarks[type];
      if (mark == null) return Landmark.missing;
      return Landmark(mark.x, mark.y, mark.likelihood);
    }

    return PoseFrame(
      imageWidth: image.width.toDouble(),
      imageHeight: image.height.toDouble(),
      points: {
        LandmarkId.lShoulder: mapOne(PoseLandmarkType.leftShoulder),
        LandmarkId.rShoulder: mapOne(PoseLandmarkType.rightShoulder),
        LandmarkId.lElbow: mapOne(PoseLandmarkType.leftElbow),
        LandmarkId.rElbow: mapOne(PoseLandmarkType.rightElbow),
        LandmarkId.lWrist: mapOne(PoseLandmarkType.leftWrist),
        LandmarkId.rWrist: mapOne(PoseLandmarkType.rightWrist),
        LandmarkId.lHip: mapOne(PoseLandmarkType.leftHip),
        LandmarkId.rHip: mapOne(PoseLandmarkType.rightHip),
        LandmarkId.lKnee: mapOne(PoseLandmarkType.leftKnee),
        LandmarkId.rKnee: mapOne(PoseLandmarkType.rightKnee),
        LandmarkId.lAnkle: mapOne(PoseLandmarkType.leftAnkle),
        LandmarkId.rAnkle: mapOne(PoseLandmarkType.rightAnkle),
      },
    );
  }

  PoseFrame _empty(double width, double height) {
    return PoseFrame(
      imageWidth: width,
      imageHeight: height,
      points: {for (final id in LandmarkId.values) id: Landmark.missing},
    );
  }

  @override
  Future<void> stop() async {
    _running = false;
    final camera = _camera;
    _camera = null;
    if (camera != null) {
      if (camera.value.isStreamingImages) {
        await camera.stopImageStream();
      }
      await camera.dispose();
    }
    _changes.ping();
  }

  Future<void> close() async {
    await stop();
    await _detector?.close();
    _detector = null;
    await _frames.close();
  }
}
