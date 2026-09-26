import 'dart:math' as math;

import 'body.dart';
import 'catalog.dart';
import 'fit.dart';
import 'mirror.dart';
import 'score.dart';

enum Phase {
  home,
  players,
  deck,
  priming,
  awaitingPermission,
  cameraOff,
  framing,
  countdown,
  window,
  hold,
  snapshot,
  handoff,
  judgeHandoff,
  judgePick,
  judgeReveal,
  tie,
  suddenHandoff,
  suddenWindow,
  results,
}

enum PoseMode { match, sudden }

class Settings {
  int rounds;
  int posesPerTurn;
  int windowSeconds;
  BodyMode body;
  bool judgeOn;
  bool sound;
  bool haptics;
  bool reduceMotion;

  Settings({
    this.rounds = 3,
    this.posesPerTurn = 5,
    this.windowSeconds = 7,
    this.body = BodyMode.full,
    this.judgeOn = true,
    this.sound = true,
    this.haptics = true,
    this.reduceMotion = false,
  });

  Settings copy() => Settings(
        rounds: rounds,
        posesPerTurn: posesPerTurn,
        windowSeconds: windowSeconds,
        body: body,
        judgeOn: judgeOn,
        sound: sound,
        haptics: haptics,
        reduceMotion: reduceMotion,
      );
}

const avatarColorNames = [
  'sun',
  'sky',
  'sage',
  'lavender',
  'bubblegum',
  'teal',
  'coral',
  'cream',
];

class Player {
  final String id;
  String name;
  final String color;
  int score;

  Player({
    required this.id,
    required this.name,
    required this.color,
    this.score = 0,
  });
}

class Snap {
  final String id;
  final int round;
  final String playerId;
  final String playerName;
  final String poseId;
  final String poseName;
  final int points;
  final int fitPercent;
  final String stamp;
  final bool matched;
  final bool sudden;
  final int seq;
  final DateTime at;
  final String footer;
  final ScoreBreakdown breakdown;

  const Snap({
    required this.id,
    required this.round,
    required this.playerId,
    required this.playerName,
    required this.poseId,
    required this.poseName,
    required this.points,
    required this.fitPercent,
    required this.stamp,
    required this.matched,
    required this.sudden,
    required this.seq,
    required this.at,
    required this.footer,
    required this.breakdown,
  });

  String get fileName => 'r${round}_${playerId}_${poseId}_$seq.jpg';
}

class JudgePick {
  final int round;
  final String judgeId;
  final String snapId;
  final String ownerId;

  const JudgePick({
    required this.round,
    required this.judgeId,
    required this.snapId,
    required this.ownerId,
  });
}

class RankRow {
  final String playerId;
  final String label;
  final int score;
  final bool shared;

  const RankRow({
    required this.playerId,
    required this.label,
    required this.score,
    required this.shared,
  });
}

class GameSession {
  GameSession({
    math.Random? random,
    Settings? settings,
    DateTime Function()? now,
    String? gameId,
  })  : random = random ?? math.Random(),
        settings = settings ?? Settings(),
        now = now ?? DateTime.now,
        gameId = gameId ?? 'game';

  final math.Random random;
  final DateTime Function() now;
  Settings settings;

  Phase phase = Phase.home;
  final List<Player> players = [];
  final Set<DeckId> decks = {DeckId.classics};
  bool primed = false;
  bool referee = false;
  String gameId;
  int round = 1;
  int turn = 0;
  int poseIndex = 0;
  List<PoseDef> turnQueue = [];
  final List<Snap> snaps = [];
  final List<JudgePick> judgePicks = [];
  final Set<String> usedPoseIds = {};
  final Set<String> kept = {};

  double elapsed = 0;
  double pauseUsed = 0;
  double outAccum = 0;
  double backAccum = 0;
  bool outOfFrame = false;
  bool userPaused = false;
  final HoldTimer hold = HoldTimer();
  double bestFit = 0;
  FitReading? liveFit;
  MeasuredPose? liveMeasure;
  PoseFrame? liveFrame;
  PoseAngles? smoothed;
  final Map<LimbId, LimbStatus> limbStatus = {};
  double framingHeld = 0;
  bool recheck = false;
  double lowLightFor = 0;
  String framingPrompt = 'Lean the phone at about waist height, about 2 m (3 big steps) away.';
  bool markerGreen = false;
  bool partHead = false;
  bool partArms = false;
  bool partLegs = false;
  ScoreBreakdown? lastScore;
  Snap? lastSnap;
  double snapshotLeft = 0;
  double revealLeft = 0;
  String? selectedSnapId;
  List<String> tiedIds = [];
  PoseDef? suddenPose;
  int suddenCursor = 0;
  final Map<String, int> suddenPeaks = {};
  List<String> winners = [];
  String crownNote = '';
  bool onePoser = false;
  double onePoserLeft = 0;
  double lastTorso = 0;
  PoseMode poseMode = PoseMode.match;
  bool holdGrace = false;
  bool finished = false;
  int _seq = 0;
  int _playerSeq = 0;
  String? undoSnapId;
  double undoLeft = 0;
  bool askDeleteUnkept = false;
  double viewW = 393;
  double viewH = 852;
  double bodyScale = 180;

  bool get kidsGame => decks.contains(DeckId.kids);

  bool get judgeEnabled =>
      settings.judgeOn && players.length >= 3 && !referee;

  Player? get currentPlayer =>
      players.isEmpty || turn < 0 || turn >= players.length ? null : players[turn];

  PoseDef? get currentPose {
    if (poseMode == PoseMode.sudden) return suddenPose;
    if (turnQueue.isEmpty || poseIndex < 0 || poseIndex >= turnQueue.length) {
      return null;
    }
    return turnQueue[poseIndex];
  }

  double get windowLimit =>
      poseMode == PoseMode.sudden ? 7 : settings.windowSeconds.toDouble();

  double get secondsLeft => math.max(0, windowLimit - elapsed);

  Player? get judge =>
      players.isEmpty ? null : players[(round - 1) % players.length];

  Player? get nextJudge {
    if (players.isEmpty) return null;
    return players[round % players.length];
  }

  bool get chromeHidden =>
      phase == Phase.countdown || phase == Phase.hold || phase == Phase.framing;

  int? get countdownNumeral {
    if (phase != Phase.countdown || outOfFrame) return null;
    if (elapsed < 0.7) return 3;
    if (elapsed < 1.4) return 2;
    if (elapsed < 2.1) return 1;
    return null;
  }

  bool get countdownGo => phase == Phase.countdown && !outOfFrame && elapsed >= 2.1;

  String get outHint {
    final frame = liveFrame;
    final measured = liveMeasure;
    if (frame == null || measured == null) return 'Step back';
    if (settings.body == BodyMode.full &&
        (!measured.leftAnkle.confident || !measured.rightAnkle.confident)) {
      return 'Step back';
    }
    final screenX = frame.imageWidth - measured.bodyCenter.x;
    if (screenX > frame.imageWidth * 0.62) return 'We lost you · move left';
    if (screenX < frame.imageWidth * 0.38) return 'We lost you · move right';
    return 'Step back';
  }

  List<Snap> snapsForRound(int roundNumber, {String? exceptPlayer}) {
    return snaps.where((snap) {
      if (snap.round != roundNumber || snap.sudden) return false;
      if (exceptPlayer != null && snap.playerId == exceptPlayer) return false;
      return true;
    }).toList();
  }

  List<RankRow> ranks() {
    final ordered = [...players]..sort((a, b) => b.score.compareTo(a.score));
    final rows = <RankRow>[];
    var index = 0;
    while (index < ordered.length) {
      final score = ordered[index].score;
      var end = index;
      while (end < ordered.length && ordered[end].score == score) {
        end++;
      }
      final shared = end - index > 1;
      final place = index + 1;
      for (var i = index; i < end; i++) {
        rows.add(RankRow(
          playerId: ordered[i].id,
          label: shared ? '$place=' : '$place',
          score: score,
          shared: shared,
        ));
      }
      index = end;
    }
    return rows;
  }

  Snap? bestSnap(String playerId) {
    final mine = snaps.where((snap) => snap.playerId == playerId && !snap.sudden).toList();
    if (mine.isEmpty) {
      return snaps.cast<Snap?>().firstWhere(
            (snap) => snap!.playerId == playerId,
            orElse: () => null,
          );
    }
    mine.sort((a, b) {
      final points = b.points.compareTo(a.points);
      if (points != 0) return points;
      final fit = b.fitPercent.compareTo(a.fitPercent);
      if (fit != 0) return fit;
      return a.at.compareTo(b.at);
    });
    return mine.first;
  }

  void tapPlay() {
    phase = players.isEmpty ? Phase.players : Phase.deck;
  }

  void addPlayer(String rawName) {
    final name = rawName.trim();
    if (name.isEmpty || players.length >= 8) return;
    _playerSeq += 1;
    players.add(Player(
      id: 'p$_playerSeq',
      name: name.length > 16 ? name.substring(0, 16) : name,
      color: avatarColorNames[(players.length) % avatarColorNames.length],
    ));
  }

  void removePlayer(String id) {
    players.removeWhere((player) => player.id == id);
  }

  void movePlayer(int from, int to) {
    if (from < 0 || to < 0 || from >= players.length || to >= players.length) return;
    final player = players.removeAt(from);
    players.insert(to, player);
  }

  void donePlayers() {
    if (players.length >= 2) phase = Phase.deck;
  }

  void toggleDeck(DeckId deck) {
    if (!deckEnabled(deck, settings.body)) return;
    if (decks.contains(deck)) {
      decks.remove(deck);
    } else {
      decks.add(deck);
    }
  }

  void setBody(BodyMode mode) {
    settings.body = mode;
    if (mode == BodyMode.upper) decks.remove(DeckId.hard);
  }

  void setRounds(int rounds) {
    settings.rounds = rounds.clamp(1, 5);
  }

  void setPosesPerTurn(int count) {
    if (count == 3 || count == 5 || count == 8) settings.posesPerTurn = count;
  }

  void setWindow(int seconds) {
    if (seconds == 10 || seconds == 7 || seconds == 5) settings.windowSeconds = seconds;
  }

  void strikeAPose() {
    if (players.length < 2 || decks.isEmpty) return;
    referee = false;
    if (!primed) {
      phase = Phase.priming;
      return;
    }
    _startGame();
  }

  void continuePriming() {
    primed = true;
    phase = Phase.awaitingPermission;
  }

  void onPermission(bool granted) {
    if (granted) {
      _startGame();
    } else {
      phase = Phase.cameraOff;
    }
  }

  void playReferee() {
    referee = true;
    primed = true;
    _startGame();
  }

  void openSettings() {}

  void imReady() {
    if (phase == Phase.judgeHandoff) {
      selectedSnapId = null;
      phase = Phase.judgePick;
      return;
    }
    if (phase == Phase.handoff || phase == Phase.suddenHandoff) {
      if (referee) {
        _beginCountdown();
        return;
      }
      phase = Phase.framing;
      recheck = true;
      elapsed = 0;
      framingHeld = 0;
      _clearLive();
    }
  }

  void nailedIt() {
    if (!referee || (phase != Phase.window && phase != Phase.hold)) return;
    final pose = currentPose;
    final player = currentPlayer;
    if (pose == null || player == null) return;
    final breakdown = scoreReferee(multiplier: pose.pointsMultiplier);
    player.score += breakdown.total;
    lastScore = breakdown;
    _addSnap(player, pose, breakdown, sudden: poseMode == PoseMode.sudden);
    phase = Phase.snapshot;
    snapshotLeft = 3;
  }

  void pause() {
    if (phase == Phase.window) userPaused = true;
  }

  void resume() {
    userPaused = false;
  }

  void skipPose() {
    if (phase != Phase.window && !userPaused) return;
    userPaused = false;
    lastScore = scoreMissed(0);
    _advancePose();
  }

  void endGame() {
    userPaused = false;
    _tally(skipJudge: true);
  }

  void nextFromSnapshot() {
    if (phase == Phase.snapshot) _advancePose();
  }

  void toggleJudgeSelection(String snapId) {
    if (phase != Phase.judgePick) return;
    final judgeId = judge?.id;
    final snap = snaps.cast<Snap?>().firstWhere(
          (item) => item!.id == snapId,
          orElse: () => null,
        );
    if (snap == null || snap.playerId == judgeId) return;
    selectedSnapId = selectedSnapId == snapId ? null : snapId;
  }

  void confirmJudge() {
    if (phase != Phase.judgePick || selectedSnapId == null) return;
    final judgePlayer = judge;
    final snap = snaps.cast<Snap?>().firstWhere(
          (item) => item!.id == selectedSnapId,
          orElse: () => null,
        );
    if (judgePlayer == null || snap == null || snap.playerId == judgePlayer.id) return;
    final owner = players.firstWhere((player) => player.id == snap.playerId);
    owner.score += judgePickBonus;
    judgePicks.add(JudgePick(
      round: round,
      judgeId: judgePlayer.id,
      snapId: snap.id,
      ownerId: owner.id,
    ));
    phase = Phase.judgeReveal;
    revealLeft = 2;
  }

  void suddenDeath() {
    if (phase != Phase.tie || referee) return;
    final pool = suddenDeathPool(kidsGame: kidsGame, mode: settings.body);
    suddenPose = pool[random.nextInt(pool.length)];
    suddenPeaks.clear();
    suddenCursor = 0;
    poseMode = PoseMode.sudden;
    turn = players.indexWhere((player) => player.id == tiedIds.first);
    phase = Phase.suddenHandoff;
  }

  void shareCrown() {
    if (phase != Phase.tie) return;
    winners = [...tiedIds];
    crownNote = 'shared';
    finished = false;
    phase = Phase.results;
  }

  void toggleKeep(String snapId) {
    if (!kidsGame) return;
    if (kept.contains(snapId)) {
      kept.remove(snapId);
    } else {
      kept.add(snapId);
    }
  }

  void keepAll() {
    if (!kidsGame) return;
    kept.addAll(snaps.map((snap) => snap.id));
  }

  int get unkeptCount => snaps.where((snap) => !kept.contains(snap.id)).length;

  bool requestLeave() {
    if (kidsGame && unkeptCount > 0) {
      askDeleteUnkept = true;
      return false;
    }
    _finish();
    return true;
  }

  void cancelLeave() {
    askDeleteUnkept = false;
  }

  void confirmDeleteAndLeave() {
    askDeleteUnkept = false;
    _finish();
  }

  void deleteSnapRequested(String id) {
    undoSnapId = id;
    undoLeft = 5;
  }

  void undoDelete() {
    undoSnapId = null;
    undoLeft = 0;
  }

  List<String> takeCommittedDeletes() {
    if (undoSnapId != null && undoLeft <= 0) {
      final id = undoSnapId!;
      snaps.removeWhere((snap) => snap.id == id);
      kept.remove(id);
      undoSnapId = null;
      return [id];
    }
    return const [];
  }

  void tick(double dt, PoseFrame? frame, {double? viewWidth, double? viewHeight}) {
    if (viewWidth != null) viewW = viewWidth;
    if (viewHeight != null) viewH = viewHeight;
    if (undoLeft > 0 && undoSnapId != null) {
      undoLeft -= dt;
    }
    if (onePoserLeft > 0) {
      onePoserLeft -= dt;
      if (onePoserLeft <= 0) onePoser = false;
    }
    if (userPaused) return;
    switch (phase) {
      case Phase.framing:
        _tickFraming(dt, frame);
      case Phase.countdown:
        _tickCountdown(dt, frame);
      case Phase.window:
      case Phase.hold:
        _tickActive(dt, frame);
      case Phase.suddenWindow:
        _tickSudden(dt, frame);
      case Phase.snapshot:
        snapshotLeft -= dt;
        if (snapshotLeft <= 0) _advancePose();
      case Phase.judgeReveal:
        revealLeft -= dt;
        if (revealLeft <= 0) _afterJudge();
      default:
        break;
    }
  }

  void _startGame() {
    gameId = 'g${now().millisecondsSinceEpoch}';
    round = 1;
    turn = 0;
    snaps.clear();
    judgePicks.clear();
    usedPoseIds.clear();
    kept.clear();
    winners = [];
    crownNote = '';
    finished = false;
    tiedIds = [];
    suddenPose = null;
    poseMode = PoseMode.match;
    askDeleteUnkept = false;
    for (final player in players) {
      player.score = 0;
    }
    _dealTurn();
    poseIndex = 0;
    if (referee) {
      _beginCountdown();
    } else {
      phase = Phase.framing;
      recheck = false;
      elapsed = 0;
      framingHeld = 0;
      _clearLive();
    }
  }

  void _dealTurn() {
    final pool = poolFor(decks: decks, mode: settings.body);
    turnQueue = dealTurn(
      pool: pool,
      used: usedPoseIds,
      count: settings.posesPerTurn,
      nextInt: random.nextInt,
    );
    poseIndex = 0;
  }

  void _beginCountdown() {
    phase = Phase.countdown;
    elapsed = 0;
    pauseUsed = 0;
    outAccum = 0;
    backAccum = 0;
    outOfFrame = false;
    hold.reset();
    bestFit = 0;
    holdGrace = false;
    smoothed = null;
    limbStatus.clear();
    userPaused = false;
  }

  void _clearLive() {
    liveFit = null;
    liveFrame = null;
    liveMeasure = null;
  }

  void _rememberFrame(PoseFrame? frame) {
    liveFrame = frame;
    if (frame == null) {
      liveMeasure = null;
      liveFit = null;
      return;
    }
    final measured = measurePose(frame);
    liveMeasure = measured;
    if (measured.torsoLength > 1) {
      if (lastTorso > 1 && (measured.torsoLength - lastTorso).abs() / lastTorso > 0.35) {
        onePoser = true;
        onePoserLeft = 2;
      }
      lastTorso = measured.torsoLength;
      bodyScale = measured.torsoLength;
    }
    final pose = currentPose;
    if (pose == null) return;
    final raw = measured.angles;
    smoothed = smoothed == null ? raw : smoothed!.lerp(raw, 0.35);
    final reading = evaluateFit(
      measured: MeasuredPose(
        angles: smoothed!,
        lArm: measured.lArm,
        rArm: measured.rArm,
        lLeg: measured.lLeg,
        rLeg: measured.rLeg,
        leanVisible: measured.leanVisible,
        confidentCount: measured.confidentCount,
        shouldersVisible: measured.shouldersVisible,
        torsoLength: measured.torsoLength,
        bodyCenter: measured.bodyCenter,
        leftAnkle: measured.leftAnkle,
        rightAnkle: measured.rightAnkle,
        imageWidth: measured.imageWidth,
        imageHeight: measured.imageHeight,
        meanLikelihood: measured.meanLikelihood,
      ),
      target: pose.angles,
      tolerance: poseMode == PoseMode.sudden
          ? suddenDeathTolerance(kidsGame: kidsGame, mode: settings.body)
          : pose.tolerance,
      mode: settings.body,
      previous: limbStatus,
    );
    liveFit = reading;
    limbStatus
      ..clear()
      ..addAll({for (final entry in reading.limbs.entries) entry.key: entry.value.status});
  }

  bool _rawOut(PoseFrame? frame) {
    if (frame == null) return true;
    final measured = measurePose(frame);
    if (settings.body == BodyMode.upper) return !measured.shouldersVisible;
    return measured.confidentCount < 8;
  }

  bool _backIn(PoseFrame? frame) {
    if (frame == null) return false;
    final measured = measurePose(frame);
    if (settings.body == BodyMode.upper) {
      return measured.lArm && measured.rArm && measured.leanVisible;
    }
    return measured.confidentCount >= 10;
  }

  double _applyOut(double dt, PoseFrame? frame) {
    if (referee) return 0;
    final raw = _rawOut(frame);
    if (outOfFrame) {
      if (_backIn(frame)) {
        backAccum += dt;
        outAccum = 0;
        if (backAccum >= 0.300) {
          outOfFrame = false;
          backAccum = 0;
        }
      } else {
        backAccum = 0;
        outAccum += dt;
      }
    } else if (raw) {
      outAccum += dt;
      backAccum = 0;
      if (outAccum > 0.300) outOfFrame = true;
    } else {
      outAccum = 0;
      backAccum = 0;
    }
    if (!outOfFrame) return 0;
    final room = math.max(0.0, 2.0 - pauseUsed);
    final paused = math.min(dt, room);
    pauseUsed += paused;
    return paused;
  }

  void _tickFraming(double dt, PoseFrame? frame) {
    elapsed += dt;
    _rememberFrame(frame);
    final measured = liveMeasure;
    partHead = measured?.shouldersVisible ?? false;
    partArms = (measured?.lArm ?? false) && (measured?.rArm ?? false);
    partLegs = (measured?.lLeg ?? false) && (measured?.rLeg ?? false);
    final required = settings.body == BodyMode.upper
        ? partHead && partArms
        : partHead && partArms && partLegs;
    markerGreen = false;
    if (measured != null &&
        measured.leftAnkle.confident &&
        measured.rightAnkle.confident) {
      markerGreen = ankleInsideMarker(
            x: measured.leftAnkle.x,
            y: measured.leftAnkle.y,
            imageW: measured.imageWidth,
            imageH: measured.imageHeight,
            viewW: viewW,
            viewH: viewH,
          ) &&
          ankleInsideMarker(
            x: measured.rightAnkle.x,
            y: measured.rightAnkle.y,
            imageW: measured.imageWidth,
            imageH: measured.imageHeight,
            viewW: viewW,
            viewH: viewH,
          );
    }
    if (measured != null && measured.meanLikelihood < 0.6) {
      lowLightFor += dt;
    } else {
      lowLightFor = 0;
    }
    framingPrompt = _framingPrompt(measured, required);
    if (required) {
      framingHeld += dt;
    } else {
      framingHeld = 0;
    }
    final found = framingHeld >= 0.8 - 1e-6;
    if (found || (recheck && elapsed >= 1.5)) {
      if (found && measured != null && measured.torsoLength > 1) {
        bodyScale = measured.torsoLength;
      }
      _beginCountdown();
    }
  }

  String _framingPrompt(MeasuredPose? measured, bool required) {
    const tip = 'Lean the phone at about waist height, about 2 m (3 big steps) away.';
    if (measured == null) return tip;
    if (settings.body == BodyMode.full &&
        (!measured.leftAnkle.confident || !measured.rightAnkle.confident)) {
      return "Step back, we can't see your feet";
    }
    final center = measured.imageWidth / 2;
    final screenX = measured.imageWidth - measured.bodyCenter.x;
    if ((screenX - center).abs() > measured.imageWidth * 0.15 || !markerGreen) {
      if (screenX > center) return 'Scoot left onto the marker';
      if (screenX < center) return 'Scoot right onto the marker';
    }
    if (lowLightFor > 2) return 'More light, please!';
    if (required) return 'Hold still';
    return tip;
  }

  void _tickCountdown(double dt, PoseFrame? frame) {
    _rememberFrame(frame);
    final paused = _applyOut(dt, frame);
    if (outOfFrame) {
      hold.advance(dt, false);
    }
    elapsed += dt - paused;
    if (elapsed >= 2.5) {
      elapsed = 0;
      pauseUsed = math.min(pauseUsed, 2);
      phase = poseMode == PoseMode.sudden ? Phase.suddenWindow : Phase.window;
    }
  }

  void _tickActive(double dt, PoseFrame? frame) {
    _rememberFrame(frame);
    final start = elapsed;
    final paused = _applyOut(dt, frame);
    final run = dt - paused;
    final fit = liveFit;
    final inTol = !outOfFrame && (fit?.inTolerance ?? false);
    if (!outOfFrame && fit != null && fit.canSee && fit.fit > bestFit) {
      bestFit = fit.fit;
    }
    if (outOfFrame && phase == Phase.hold) {
      hold.advance(dt, false);
    }
    elapsed = start + run;
    if (phase == Phase.window && inTol && (windowLimit - elapsed) >= 0.3) {
      phase = Phase.hold;
      holdGrace = true;
    }
    if (phase == Phase.hold && !outOfFrame) {
      final need = 1 - hold.held;
      if (inTol && run >= need) {
        elapsed = start + need;
        hold.held = 1;
        _completeMatch();
        return;
      }
      hold.advance(run, inTol);
      if (hold.complete) {
        _completeMatch();
        return;
      }
    }
    final expired = elapsed >= windowLimit - 1e-9;
    if (phase == Phase.hold && holdGrace && elapsed < windowLimit + 1 && hold.held > 0) {
      return;
    }
    if (!expired) return;
    _completeMiss();
  }

  void _tickSudden(double dt, PoseFrame? frame) {
    _rememberFrame(frame);
    final paused = _applyOut(dt, frame);
    final fit = liveFit;
    if (!outOfFrame && fit != null && fit.canSee) {
      final peak = (fit.fit * 100).round();
      final player = currentPlayer;
      if (player != null) {
        final prior = suddenPeaks[player.id] ?? 0;
        if (peak > prior) suddenPeaks[player.id] = peak;
      }
      if (fit.fit > bestFit) bestFit = fit.fit;
    }
    elapsed += dt - paused;
    if (elapsed >= 7) _finishSuddenTurn();
  }

  void _completeMatch() {
    final pose = currentPose;
    final player = currentPlayer;
    if (pose == null || player == null) return;
    final fit = (liveFit?.fit ?? bestFit).clamp(0.0, 1.0);
    final breakdown = scoreMatched(
      fit: fit,
      secondsLeft: secondsLeft,
      multiplier: pose.pointsMultiplier,
    );
    player.score += breakdown.total;
    lastScore = breakdown;
    _addSnap(player, pose, breakdown, sudden: false);
    phase = Phase.snapshot;
    snapshotLeft = 3;
    poseMode = PoseMode.match;
  }

  void _completeMiss() {
    final pose = currentPose;
    final player = currentPlayer;
    if (pose == null || player == null) return;
    final breakdown = scoreMissed((bestFit * 100).round());
    lastScore = breakdown;
    _addSnap(player, pose, breakdown, sudden: false);
    phase = Phase.snapshot;
    snapshotLeft = 1.5;
  }

  void _addSnap(Player player, PoseDef pose, ScoreBreakdown breakdown, {required bool sudden}) {
    _seq += 1;
    final stamp = sudden
        ? 'SUDDEN DEATH · ${breakdown.fitPercent}%'
        : breakdown.stamp;
    final snap = Snap(
      id: 's$_seq',
      round: round,
      playerId: player.id,
      playerName: player.name,
      poseId: pose.id,
      poseName: pose.name,
      points: sudden ? 0 : breakdown.total,
      fitPercent: breakdown.fitPercent,
      stamp: stamp,
      matched: breakdown.matched && !sudden,
      sudden: sudden,
      seq: _seq,
      at: now(),
      footer: 'R$round · POSE ${poseIndex + 1} · ${_month(now())}',
      breakdown: breakdown,
    );
    snaps.add(snap);
    lastSnap = snap;
  }

  void _advancePose() {
    if (poseMode == PoseMode.sudden) {
      _advanceSudden();
      return;
    }
    poseIndex += 1;
    if (poseIndex < turnQueue.length) {
      _beginCountdown();
      return;
    }
    turn += 1;
    if (turn < players.length) {
      _dealTurn();
      phase = Phase.handoff;
      return;
    }
    if (judgeEnabled) {
      phase = Phase.judgeHandoff;
      return;
    }
    _afterJudge();
  }

  void _afterJudge() {
    if (round < settings.rounds) {
      round += 1;
      turn = 0;
      _dealTurn();
      poseMode = PoseMode.match;
      phase = Phase.handoff;
      return;
    }
    _tally(skipJudge: true);
  }

  void _tally({required bool skipJudge}) {
    final top = players.map((player) => player.score).reduce(math.max);
    tiedIds = players.where((player) => player.score == top).map((player) => player.id).toList();
    if (tiedIds.length >= 2 && !referee) {
      phase = Phase.tie;
      return;
    }
    winners = [...tiedIds];
    crownNote = tiedIds.length >= 2 ? 'shared' : '';
    phase = Phase.results;
  }

  void _finishSuddenTurn() {
    final player = currentPlayer;
    final pose = suddenPose;
    if (player != null && pose != null) {
      final peak = suddenPeaks[player.id] ?? 0;
      final breakdown = scoreMissed(peak);
      lastScore = breakdown;
      _addSnap(player, pose, breakdown, sudden: true);
    }
    suddenCursor += 1;
    phase = Phase.snapshot;
    snapshotLeft = 1.5;
  }

  void _advanceSudden() {
    if (suddenCursor >= tiedIds.length) {
      _resolveSudden();
      return;
    }
    turn = players.indexWhere((player) => player.id == tiedIds[suddenCursor]);
    phase = Phase.suddenHandoff;
  }

  void _resolveSudden() {
    var best = -1;
    for (final id in tiedIds) {
      best = math.max(best, suddenPeaks[id] ?? 0);
    }
    winners = tiedIds.where((id) => (suddenPeaks[id] ?? 0) == best).toList();
    crownNote = winners.length > 1 ? 'shared' : 'sudden';
    poseMode = PoseMode.match;
    phase = Phase.results;
  }

  void _finish() {
    finished = true;
    phase = Phase.home;
  }

  static String _month(DateTime date) {
    const names = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${names[date.month - 1]} ${date.day}';
  }
}
