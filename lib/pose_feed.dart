import 'package:flutter/widgets.dart';

import 'engine/body.dart';

class FeedSignal extends ChangeNotifier {
  void ping() => notifyListeners();
}

abstract class PoseFeed {
  Future<bool> start();
  Future<void> stop();
  Stream<PoseFrame> get frames;
  Widget? buildPreview();
  Listenable get changes;
}
