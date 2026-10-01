import 'package:audioplayers/audioplayers.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'sound.dart';
import 'wake.dart';

class AssetSound implements SoundBoard {
  final AudioPlayer _player = AudioPlayer();

  @override
  void play(String cue) {
    _player.play(AssetSource('sfx/$cue.wav'));
  }
}

class WakelockStay implements StayAwake {
  @override
  Future<void> enable() => WakelockPlus.enable();

  @override
  Future<void> disable() => WakelockPlus.disable();
}
