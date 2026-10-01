import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'engine/body.dart';
import 'engine/catalog.dart';
import 'engine/still.dart';
import 'pose_feed.dart';

/// Release builds fail closed. The debug fake also needs `--dart-define=FAKE_POSE=true`.
bool allowsFakePose({bool? debugMode, bool? define}) {
  final debug = debugMode ?? kDebugMode;
  final flag = define ?? const bool.fromEnvironment('FAKE_POSE');
  return debug && flag;
}

class FakePoseSource implements PoseFeed {
  FakePoseSource({bool? debugMode, bool? define}) {
    if (!allowsFakePose(debugMode: debugMode, define: define)) {
      throw StateError(
        'FakePoseSource is only constructed in debug with --dart-define=FAKE_POSE=true',
      );
    }
  }

  final _frames = StreamController<PoseFrame>.broadcast();
  final _changes = FeedSignal();
  Timer? _timer;
  bool _running = false;

  @override
  Stream<PoseFrame> get frames => _frames.stream;

  @override
  Listenable get changes => _changes;

  @override
  Widget? buildPreview() => null;

  @override
  StillFrame? get latestStill => null;

  @override
  Future<bool> start() async {
    _timer?.cancel();
    _running = true;
    final pose = poseById('star_jump');
    _timer = Timer.periodic(const Duration(milliseconds: 66), (_) {
      if (_frames.isClosed) return;
      _frames.add(synthesizePose(pose.angles));
    });
    _changes.ping();
    return true;
  }

  @override
  Future<void> stop() async {
    _running = false;
    _timer?.cancel();
    _timer = null;
    _changes.ping();
  }

  bool get running => _running;
}
