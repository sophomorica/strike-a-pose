abstract class SoundBoard {
  void play(String cue);
}

class SilentSound implements SoundBoard {
  final List<String> played = [];

  @override
  void play(String cue) => played.add(cue);
}
