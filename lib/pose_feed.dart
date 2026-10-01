import 'package:flutter/widgets.dart';

import 'engine/body.dart';
import 'engine/still.dart';

class FeedSignal extends ChangeNotifier {
  void ping() => notifyListeners();
}

abstract class PoseFeed {
  Future<bool> start();
  Future<void> stop();
  Stream<PoseFrame> get frames;
  Widget? buildPreview();
  Listenable get changes;

  /// Upright camera frame from the last processed buffer. Null when there is no camera.
  StillFrame? get latestStill;
}
