import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:strike_a_pose/engine/body.dart';
import 'package:strike_a_pose/engine/catalog.dart';
import 'package:strike_a_pose/engine/fit.dart';
import 'package:strike_a_pose/engine/game.dart';
import 'package:strike_a_pose/engine/mirror.dart';
import 'package:strike_a_pose/engine/retention.dart';
import 'package:strike_a_pose/engine/score.dart';
import 'package:strike_a_pose/engine/still.dart';
import 'package:strike_a_pose/pose_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('joint closeness hits the locked tolerance bands', () {
    expect(jointCloseness(0, Tolerance.normal), 1);
    expect(jointCloseness(15, Tolerance.normal), 1);
    expect(jointCloseness(30, Tolerance.normal), closeTo(0.5, 0.001));
    expect(jointCloseness(45, Tolerance.normal), 0);
    expect(jointCloseness(22, Tolerance.kids), 1);
    expect(jointCloseness(55, Tolerance.kids), 0);
    expect(jointCloseness(10, Tolerance.hard), 1);
    expect(jointCloseness(22.5, Tolerance.hard), closeTo(0.5, 0.001));
    expect(jointCloseness(35, Tolerance.hard), 0);
  });

  test('a synthesized star jump measures back and matches', () {
    final pose = poseById('star_jump');
    final measured = measurePose(synthesizePose(pose.angles));
    expect((measured.angles.lSh - pose.angles.lSh).abs(), lessThan(8));
    expect((measured.angles.rHip - pose.angles.rHip).abs(), lessThan(8));
    expect((measured.angles.lEl - 180).abs(), lessThan(8));
    final fit = evaluateFit(
      measured: measured,
      target: pose.angles,
      tolerance: Tolerance.normal,
      mode: BodyMode.full,
    );
    expect(fit.inTolerance, isTrue);
    expect(fit.zone, FitZone.match);
    expect(fit.percent, greaterThanOrEqualTo(85));
  });

  test('neutral arms-down never matches star jump, t-pose, or victory', () {
    final neutral = measurePose(neutralFrame());
    for (final id in ['star_jump', 't_pose', 'victory_v']) {
      final pose = poseById(id);
      final fit = evaluateFit(
        measured: neutral,
        target: pose.angles,
        tolerance: Tolerance.normal,
        mode: BodyMode.full,
      );
      expect(fit.inTolerance, isFalse, reason: id);
      expect(fit.percent, lessThan(85), reason: id);
    }
  });

  test('kids tolerance is wider and hard tolerance is tighter', () {
    final target = poseById('star_jump').angles;
    final off = PoseAngles(
      lSh: target.lSh - 20,
      rSh: target.rSh,
      lEl: target.lEl,
      rEl: target.rEl,
      lHip: target.lHip,
      rHip: target.rHip,
      lKn: target.lKn,
      rKn: target.rKn,
    );
    final measured = measurePose(synthesizePose(off));
    final kids = evaluateFit(
      measured: measured,
      target: target,
      tolerance: Tolerance.kids,
      mode: BodyMode.full,
    );
    final hard = evaluateFit(
      measured: measured,
      target: target,
      tolerance: Tolerance.hard,
      mode: BodyMode.full,
    );
    expect(kids.fit, greaterThan(hard.fit));
    expect(kids.limb(LimbId.lArm).score, greaterThan(hard.limb(LimbId.lArm).score));
  });

  test('fit at 85 with a red limb stays CLOSE', () {
    final target = poseById('star_jump').angles;
    final off = PoseAngles(
      lSh: target.lSh,
      rSh: target.rSh,
      lEl: target.lEl,
      rEl: target.rEl,
      lHip: target.lHip,
      rHip: target.rHip - 40.5,
      lKn: target.lKn,
      rKn: target.rKn,
    );
    final reading = evaluateFit(
      measured: measurePose(synthesizePose(off)),
      target: target,
      tolerance: Tolerance.normal,
      mode: BodyMode.full,
    );
    expect(reading.fit, greaterThanOrEqualTo(0.85));
    expect(reading.limb(LimbId.rLeg).status, LimbStatus.red);
    expect(reading.inTolerance, isFalse);
    expect(reading.zone, FitZone.close);
  });

  test('a hidden arm scores zero and is unknown', () {
    final frame = synthesizePose(
      poseById('star_jump').angles,
      likelihoods: {LandmarkId.lWrist: 0.1},
    );
    final fit = evaluateFit(
      measured: measurePose(frame),
      target: poseById('star_jump').angles,
      tolerance: Tolerance.normal,
      mode: BodyMode.full,
    );
    expect(fit.limb(LimbId.lArm).visible, isFalse);
    expect(fit.limb(LimbId.lArm).score, 0);
    expect(fit.limb(LimbId.lArm).status, LimbStatus.unknown);
    expect(fit.inTolerance, isFalse);
    expect(fit.coach, contains('left arm'));
  });

  test('upper body ignores the legs', () {
    final pose = poseById('star_jump');
    final frame = synthesizePose(
      pose.angles,
      likelihoods: {
        LandmarkId.lKnee: 0,
        LandmarkId.rKnee: 0,
        LandmarkId.lAnkle: 0,
        LandmarkId.rAnkle: 0,
      },
    );
    final fit = evaluateFit(
      measured: measurePose(frame),
      target: pose.angles,
      tolerance: Tolerance.normal,
      mode: BodyMode.upper,
    );
    expect(fit.inTolerance, isTrue);
  });

  test('limb status uses hysteresis so a boundary does not flicker', () {
    expect(nextLimbStatus(null, 0.80, true), LimbStatus.green);
    expect(nextLimbStatus(LimbStatus.green, 0.76, true), LimbStatus.green);
    expect(nextLimbStatus(LimbStatus.green, 0.74, true), LimbStatus.amber);
    expect(nextLimbStatus(LimbStatus.red, 0.54, true), LimbStatus.red);
    expect(nextLimbStatus(LimbStatus.red, 0.55, true), LimbStatus.amber);
    expect(nextLimbStatus(LimbStatus.amber, 0.44, true), LimbStatus.red);
  });

  test('hold completes at 1s, ignores a short dip, and drains a long one at 2x', () {
    final hold = HoldTimer();
    hold.advance(1, true);
    expect(hold.complete, isTrue);

    final dip = HoldTimer()..held = 0.6;
    dip.advance(0.149, false);
    expect(dip.held, closeTo(0.6, 0.001));
    dip.advance(0.2, false);
    expect(dip.held, lessThan(0.6));
    final drained = 0.6 - dip.held;
    expect(drained, closeTo(0.4, 0.05));
  });

  test('mock-05 score is 96 + 10 + 14 and hard mode doubles every part', () {
    final normal = scoreMatched(fit: 0.96, secondsLeft: 2.8, multiplier: 1);
    expect(normal.fitPoints, 96);
    expect(normal.holdBonus, 10);
    expect(normal.wallBonus, 14);
    expect(normal.total, 120);
    expect(normal.perfect, isTrue);
    expect(normal.stamp, 'PERFECT FIT');

    final hard = scoreMatched(fit: 0.96, secondsLeft: 2.8, multiplier: 2);
    expect(hard.total, 240);
    expect(hard.fitPoints, 192);
    expect(hard.holdBonus, 20);
    expect(hard.wallBonus, 28);

    final missed = scoreMissed(58);
    expect(missed.total, 0);
    expect(missed.stamp, 'SO CLOSE · 58%');
    expect(judgePickBonus, 50);
  });

  test('angle smoothing moves a third of the way toward the new sample', () {
    const start = PoseAngles(
      lSh: 0, rSh: 0, lEl: 180, rEl: 180, lHip: 0, rHip: 0, lKn: 180, rKn: 180,
    );
    const next = PoseAngles(
      lSh: 100, rSh: 0, lEl: 180, rEl: 180, lHip: 0, rHip: 0, lKn: 180, rKn: 180,
    );
    expect(start.lerp(next, 0.35).lSh, closeTo(35, 0.001));
  });

  test('mirror mapping puts an image-right landmark on the left of the view', () {
    final point = mirrorLandmark(
      x: 80,
      y: 40,
      imageW: 100,
      imageH: 100,
      viewW: 100,
      viewH: 100,
    );
    expect(point.x, closeTo(20, 0.001));
    expect(point.y, closeTo(40, 0.001));
    expect(
      ankleInsideMarker(
        x: 200,
        y: 546,
        imageW: 400,
        imageH: 700,
        viewW: 400,
        viewH: 700,
      ),
      isTrue,
    );
  });

  test('launch set matches the deck counts and has no duo', () {
    expect(posesIn(DeckId.classics), hasLength(8));
    expect(posesIn(DeckId.silly), hasLength(8));
    expect(posesIn(DeckId.sports), hasLength(6));
    expect(posesIn(DeckId.animals), hasLength(6));
    expect(posesIn(DeckId.hard), hasLength(6));
    expect(posesIn(DeckId.kids), hasLength(10));
    expect(launchPoses.map((pose) => pose.deck).contains(DeckId.hard), isTrue);
    expect(launchPoses.any((pose) => pose.id.contains('duo')), isFalse);
    expect(launchPoses.where((pose) => pose.deck != DeckId.kids && pose.upperOk), hasLength(16));
    expect(posesIn(DeckId.hard).every((pose) => pose.pointsMultiplier == 2), isTrue);
    expect(deckEnabled(DeckId.hard, BodyMode.upper), isFalse);
    expect(suddenDeathPool(kidsGame: true, mode: BodyMode.full), hasLength(10));
    expect(
      suddenDeathPool(kidsGame: false, mode: BodyMode.upper).every((pose) => pose.upperOk),
      isTrue,
    );
    expect(suddenDeathTolerance(kidsGame: true, mode: BodyMode.full).fullMarks, 22);
    expect(suddenDeathTolerance(kidsGame: false, mode: BodyMode.full).fullMarks, 10);
  });

  test('fresh settings are the locked defaults', () {
    final settings = Settings();
    expect(settings.windowSeconds, 7);
    expect(settings.posesPerTurn, 5);
    expect(settings.rounds, 3);
    expect(settings.body, BodyMode.full);
    expect(settings.judgeOn, isTrue);
  });

  test('release config cannot construct FakePoseSource', () {
    expect(allowsFakePose(debugMode: false, define: true), isFalse);
    expect(allowsFakePose(debugMode: true, define: false), isFalse);
    expect(allowsFakePose(debugMode: true, define: true), isTrue);
    expect(() => FakePoseSource(), throwsStateError);
    expect(() => FakePoseSource(debugMode: false, define: true), throwsStateError);
    expect(FakePoseSource(debugMode: true, define: true), isNotNull);
  });

  test('judge rotates, hides their own snaps, and adds 50 once', () {
    final session = _family(rounds: 1, poses: 1);
    _playPerfectPose(session);
    expect(session.phase, Phase.handoff);
    session.imReady();
    _playPerfectPose(session);
    session.imReady();
    _playPerfectPose(session);
    expect(session.phase, Phase.judgeHandoff);
    expect(session.judge!.name, 'Jess');
    session.imReady();
    expect(session.phase, Phase.judgePick);
    final own = session.snaps.firstWhere((snap) => snap.playerId == 'p1');
    session.toggleJudgeSelection(own.id);
    expect(session.selectedSnapId, isNull);
    final dad = session.snaps.firstWhere((snap) => snap.playerName == 'Dad');
    final before = session.players.firstWhere((player) => player.name == 'Dad').score;
    session.toggleJudgeSelection(dad.id);
    session.confirmJudge();
    expect(session.players.firstWhere((player) => player.name == 'Dad').score, before + 50);
    expect(session.judgePicks, hasLength(1));
    expect(session.judgePicks.single.ownerId, dad.playerId);
    session.tick(2, null);
    expect(session.phase, Phase.results);
  });

  test('judge is skipped for two players, when off, and in referee mode', () {
    final two = _family(players: 2, rounds: 1, poses: 1);
    _playPerfectPose(two);
    two.imReady();
    _playPerfectPose(two);
    expect(two.phase, isNot(Phase.judgeHandoff));
    expect(two.phase, Phase.tie);

    final off = _family(rounds: 1, poses: 1)..settings.judgeOn = false;
    _finishRound(off);
    expect(off.judgePicks, isEmpty);
    expect(off.phase, Phase.tie);

    final referee = _family(rounds: 1, poses: 1)..primed = true;
    referee.playReferee();
    referee.tick(2.5, null);
    referee.nailedIt();
    referee.tick(3, null);
    referee.imReady();
    referee.tick(2.5, null);
    referee.nailedIt();
    referee.tick(3, null);
    referee.imReady();
    referee.tick(2.5, null);
    referee.nailedIt();
    referee.tick(3, null);
    expect(referee.judgePicks, isEmpty);
    expect(referee.phase, Phase.results);
    expect(referee.crownNote, 'shared');
  });

  test('equal top scores open dead heat and sudden death does not change points', () {
    final session = _family(players: 2, rounds: 1, poses: 1, judge: false);
    _playPerfectPose(session);
    session.imReady();
    _playPerfectPose(session);
    expect(session.phase, Phase.tie);
    expect(session.ranks().first.label, '1=');
    final before = session.players.map((player) => player.score).toList();
    session.suddenDeath();
    expect(session.suddenPose, isNotNull);
    final pose = session.suddenPose!;
    expect(session.phase, Phase.suddenHandoff);
    session.imReady();
    _throughFraming(session);
    expect(session.phase, Phase.countdown);
    session.tick(2.5, synthesizePose(pose.angles));
    expect(session.phase, Phase.suddenWindow);
    final good = synthesizePose(pose.angles);
    session.tick(7, good);
    expect(session.phase, Phase.snapshot);
    session.tick(1.5, null);
    session.imReady();
    _throughFraming(session);
    session.tick(2.5, neutralFrame());
    session.tick(7, neutralFrame());
    session.tick(1.5, null);
    expect(session.phase, Phase.results);
    expect(session.winners, ['p1']);
    expect(session.players.map((player) => player.score).toList(), before);
    expect(session.crownNote, 'sudden');
  });

  test('the same sudden-death fit shares the crown', () {
    final session = _family(players: 2, rounds: 1, poses: 1, judge: false);
    _missBoth(session);
    session.suddenDeath();
    final pose = session.suddenPose!;
    for (var i = 0; i < 2; i++) {
      session.imReady();
      _throughFraming(session);
      session.tick(2.5, synthesizePose(pose.angles));
      session.tick(7, synthesizePose(pose.angles));
      session.tick(1.5, null);
    }
    expect(session.winners, ['p1', 'p2']);
    expect(session.crownNote, 'shared');
    expect(session.players.every((player) => player.score == 0), isTrue);
  });

  test('share the crown skips sudden death', () {
    final session = _family(players: 2, rounds: 1, poses: 1, judge: false);
    _missBoth(session);
    session.shareCrown();
    expect(session.phase, Phase.results);
    expect(session.winners, ['p1', 'p2']);
    expect(session.suddenPose, isNull);
  });

  test('a kids game draws sudden death from the kids pool', () {
    final session = _family(players: 2, rounds: 1, poses: 1, judge: false);
    session.decks
      ..clear()
      ..add(DeckId.kids);
    _missBoth(session);
    session.suddenDeath();
    expect(session.suddenPose!.deck, DeckId.kids);
  });

  test('leaving the frame pauses, caps at 2s, and scores nothing', () {
    final session = _family(rounds: 1, poses: 1);
    final frame = synthesizePose(session.currentPose!.angles);
    session.tick(0.8, frame);
    expect(session.phase, Phase.countdown);
    session.tick(0.25, emptyFrame());
    expect(session.outOfFrame, isFalse);
    final ran = session.elapsed;
    session.tick(0.1, emptyFrame());
    expect(session.outOfFrame, isTrue);
    expect(session.elapsed, closeTo(ran, 0.001));
    session.tick(3, emptyFrame());
    expect(session.pauseUsed, closeTo(2, 0.05));
    expect(session.elapsed, greaterThan(ran));
    expect(session.bestFit, 0);
    expect(session.hold.held, 0);
  });

  test('framing passes after 0.8s of a full body and not before', () {
    final session = _family(rounds: 1, poses: 1);
    final frame = synthesizePose(session.currentPose!.angles);
    session.tick(0.7, frame);
    expect(session.phase, Phase.framing);
    session.tick(0.1, frame);
    expect(session.phase, Phase.countdown);
    expect(session.partHead, isTrue);
  });

  test('skip pose awards nothing and saves no snapshot', () {
    final session = _family(rounds: 1, poses: 2);
    final frame = synthesizePose(session.currentPose!.angles);
    session.tick(0.8, frame);
    session.tick(2.5, frame);
    expect(session.phase, Phase.window);
    session.pause();
    session.skipPose();
    expect(session.snaps, isEmpty);
    expect(session.players.first.score, 0);
    expect(session.phase, Phase.countdown);
  });

  test('kids end deletes unkept snaps, including near misses, and keeps the rest', () async {
    final root = await Directory.systemTemp.createTemp('snaps');
    final store = FileSnapStore(root);
    final session = _family(players: 2, rounds: 1, poses: 1, judge: false);
    session.decks
      ..clear()
      ..add(DeckId.kids);
    session.gameId = 'kids1';
    _missBoth(session);
    expect(session.phase, Phase.tie);
    session.shareCrown();
    expect(session.kidsGame, isTrue);
    expect(session.snaps.every((snap) => snap.stamp.startsWith('SO CLOSE')), isTrue);
    for (final snap in session.snaps) {
      await store.writeJpeg(session.gameId, snap.fileName, [0xFF, 0xD8, 0xFF, 0xD9]);
    }
    final keptName = session.snaps.first.fileName;
    session.toggleKeep(session.snaps.first.id);
    await store.applyKidsEnd(session);
    final dir = Directory('${root.path}/snaps/kids1');
    final files = dir.listSync().whereType<File>().map((file) => file.path.split('/').last).toList();
    expect(files.where((name) => name.endsWith('.jpg')), [keptName]);
    final record = await store.loadGame('kids1');
    expect(record!.finished, isTrue);
    expect(record.snaps, hasLength(1));
    await root.delete(recursive: true);
  });

  test('an unfinished kids game is swept on the next launch', () async {
    final root = await Directory.systemTemp.createTemp('snaps-sweep');
    final store = FileSnapStore(root);
    final session = _family(players: 2, rounds: 1, poses: 1, judge: false);
    session.decks
      ..clear()
      ..add(DeckId.kids);
    session.gameId = 'kids-open';
    session.finished = false;
    await store.saveGame(session);
    await store.writeJpeg(session.gameId, 'r1_p1_star_1.jpg', [1, 2, 3]);
    final removed = await store.sweepUnfinishedKids();
    expect(removed, ['kids-open']);
    expect(File('${root.path}/snaps/kids-open/game.json').existsSync(), isFalse);
    expect(Directory('${root.path}/snaps/kids-open').existsSync(), isFalse);
    await root.delete(recursive: true);
  });

  test('other decks stay until deleted, and delete all empties snaps', () async {
    final root = await Directory.systemTemp.createTemp('snaps-keep');
    final store = FileSnapStore(root);
    final session = _family(players: 2, rounds: 1, poses: 1, judge: false);
    session.gameId = 'classic1';
    _missBoth(session);
    session.shareCrown();
    await store.saveGame(session);
    await store.writeJpeg(session.gameId, session.snaps.first.fileName, [9]);
    final swept = await store.sweepUnfinishedKids();
    expect(swept, isEmpty);
    expect(File('${root.path}/snaps/classic1/${session.snaps.first.fileName}').existsSync(), isTrue);
    await store.deleteAll();
    expect(await store.totalBytes(), 0);
    expect(storageNotice(500 * 1024 * 1024 + 1), isTrue);
    expect(storageNotice(100), isFalse);
    await root.delete(recursive: true);
  });

  test('a camera still is copied onto the snap and a referee snap has none', () {
    final session = _family(players: 2, rounds: 1, poses: 1, judge: false);
    final still = StillFrame(width: 2, height: 2, bgra: Uint8List(16)..fillRange(0, 16, 40));
    session.latestStill = still;
    _playPerfectPose(session);
    final kept = session.stills[session.snaps.first.id]!;
    expect(kept.bgra[0], 40);
    still.bgra[0] = 7;
    expect(kept.bgra[0], 40);

    final ref = GameSession(random: Random(1), now: () => DateTime(2026, 9, 25, 21));
    ref.addPlayer('Jess');
    ref.addPlayer('Theo');
    ref.settings.rounds = 1;
    ref.settings.posesPerTurn = 1;
    ref.latestStill = still;
    ref.playReferee();
    ref.tick(2.5, null);
    ref.nailedIt();
    expect(ref.snaps, isNotEmpty);
    expect(ref.stills, isEmpty);
  });

  test('a deleted snap file is gone after the 5 second undo', () async {
    final root = await Directory.systemTemp.createTemp('undo');
    final store = FileSnapStore(root);
    final session = GameSession();
    session.addPlayer('Jess');
    session.addPlayer('Theo');
    session.gameId = 'gundo';
    final snap = Snap(
      id: 's1',
      round: 1,
      playerId: 'p1',
      playerName: 'Jess',
      poseId: 'star_jump',
      poseName: 'Star Jump',
      points: 0,
      fitPercent: 40,
      stamp: 'SO CLOSE · 40%',
      matched: false,
      sudden: false,
      seq: 1,
      at: DateTime(2026, 9, 25),
      footer: 'R1 · POSE 1 · SEP 25',
      breakdown: scoreMissed(40),
    );
    session.snaps.add(snap);
    await store.writeJpeg(session.gameId, snap.fileName, [0xFF, 0xD8, 0xFF]);
    final file = File('${root.path}/snaps/gundo/${snap.fileName}');
    expect(file.existsSync(), isTrue);
    session.deleteSnapRequested(snap.id);
    session.tick(4.9, null);
    await store.applyExpiredUndo(session);
    expect(file.existsSync(), isTrue);
    expect(session.snaps, hasLength(1));
    session.tick(0.2, null);
    await store.applyExpiredUndo(session);
    expect(file.existsSync(), isFalse);
    expect(session.snaps.where((item) => item.id == snap.id), isEmpty);
    await root.delete(recursive: true);
  });

  test('lower-place ties render as a shared rank', () {
    final session = _family();
    session.players[0].score = 100;
    session.players[1].score = 40;
    session.players[2].score = 40;
    final rows = session.ranks();
    expect(rows.first.label, '1');
    expect(rows[1].label, '2=');
    expect(rows[2].label, '2=');
  });
}

GameSession _family({
  int players = 3,
  int rounds = 1,
  int poses = 1,
  bool judge = true,
}) {
  final session = GameSession(
    random: Random(1),
    now: () => DateTime(2026, 9, 25, 21),
  );
  for (final name in ['Jess', 'Theo', 'Dad', 'Nana'].take(players)) {
    session.addPlayer(name);
  }
  session.settings.rounds = rounds;
  session.settings.posesPerTurn = poses;
  session.settings.judgeOn = judge;
  session.primed = true;
  session.strikeAPose();
  return session;
}

void _throughFraming(GameSession session) {
  final pose = session.currentPose ?? session.turnQueue.first;
  session.tick(0.8, synthesizePose(pose.angles));
}

void _playPerfectPose(GameSession session) {
  expect(session.phase, Phase.framing);
  final pose = session.currentPose!;
  final frame = synthesizePose(pose.angles);
  session.tick(0.8, frame);
  expect(session.phase, Phase.countdown);
  session.tick(2.5, frame);
  expect(session.phase, anyOf(Phase.window, Phase.hold));
  session.tick(1.2, frame);
  expect(session.phase, Phase.snapshot);
  session.tick(3, null);
}

void _finishRound(GameSession session) {
  while (session.phase != Phase.tie &&
      session.phase != Phase.results &&
      session.phase != Phase.judgeHandoff) {
    if (session.phase == Phase.framing) {
      _playPerfectPose(session);
    } else if (session.phase == Phase.handoff) {
      session.imReady();
    } else {
      fail('stuck in ${session.phase}');
    }
  }
}

void _missTurn(GameSession session) {
  final pose = session.currentPose!;
  final frame = synthesizePose(pose.angles);
  if (session.phase == Phase.framing) session.tick(0.8, frame);
  if (session.phase == Phase.countdown) session.tick(2.5, frame);
  expect(session.phase, anyOf(Phase.window, Phase.hold));
  session.tick(9, emptyFrame());
  expect(session.phase, Phase.snapshot);
  session.tick(2, null);
}

void _missBoth(GameSession session) {
  _missTurn(session);
  expect(session.phase, Phase.handoff);
  session.imReady();
  _missTurn(session);
}
