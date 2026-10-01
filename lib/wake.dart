abstract class StayAwake {
  Future<void> enable();
  Future<void> disable();
}

class NoWake implements StayAwake {
  bool on = false;

  @override
  Future<void> enable() async => on = true;

  @override
  Future<void> disable() async => on = false;
}
