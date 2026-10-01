import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:strike_a_pose/engine/body.dart';
import 'package:strike_a_pose/engine/catalog.dart';
import 'package:strike_a_pose/engine/fit.dart';
import 'package:strike_a_pose/engine/game.dart';
import 'package:strike_a_pose/engine/score.dart';
import 'package:strike_a_pose/shell.dart';
import 'package:strike_a_pose/sound.dart';
import 'package:strike_a_pose/wake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('writes a screenshot for every screen', (tester) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(393 * 2, 852 * 2);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final shots = <String, GameSession>{
      'mock-01-deck': _deck(),
      'mock-02-countdown': _countdown(),
      'mock-03-lining': _window(),
      'mock-04-hold': _hold(),
      'mock-05-snapshot': _snapshot(),
      'mock-06-handoff': _handoff(),
      'mock-07-results': _results(),
      'mock-08-tie': _tie(),
      'mock-09-judge': _judge(),
      'mock-10-framing': _framing(),
      'mock-10-step-back': _stepBack(),
      'mock-11-kids-keep': _kids(),
      'home': _home(),
      'settings': _home(),
      'camera-off': _cameraOff(),
    };

    final out = Directory('/workspace/artifacts/screens');
    out.createSync(recursive: true);
    final opt = Directory('/opt/cursor/artifacts/screens');
    opt.createSync(recursive: true);

    for (final entry in shots.entries) {
      await tester.pumpWidget(StrikeShell(
        session: entry.value,
        sound: SilentSound(),
        wake: NoWake(),
        driveClock: false,
        boot: false,
      ));
      await tester.pump();
      if (entry.key == 'settings') {
        await tester.tap(find.byTooltip('Settings'));
        await tester.pump();
      }
      final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot')));
      final bytes = await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        return data!.buffer.asUint8List();
      });
      expect(bytes, isNotNull);
      final file = File('${out.path}/${entry.key}.png');
      file.writeAsBytesSync(bytes!);
      File('${opt.path}/${entry.key}.png').writeAsBytesSync(bytes);
      _besideMock(entry.key, bytes, out);
      expect(bytes.length, greaterThan(1000));
      await tester.pump();
    }
  });
}

void _besideMock(String name, List<int> shot, Directory out) {
  final candidates = [
    '/workspace/strike-a-pose-redesign/v1/$name.png',
    '/home/workdir/attachments/$name.png',
    '/workspace/uploads/$name.png',
  ];
  for (final path in candidates) {
    final mock = File(path);
    if (!mock.existsSync()) continue;
    final left = img.decodePng(Uint8List.fromList(shot));
    final right = img.decodeImage(mock.readAsBytesSync());
    if (left == null || right == null) return;
    final scaled = img.copyResize(right, height: left.height);
    final sheet = img.Image(width: left.width + scaled.width + 16, height: left.height);
    img.fill(sheet, color: img.ColorRgb8(20, 16, 32));
    img.compositeImage(sheet, left, dstX: 0, dstY: 0);
    img.compositeImage(sheet, scaled, dstX: left.width + 16, dstY: 0);
    File('${out.path}/$name-beside-mock.png').writeAsBytesSync(img.encodePng(sheet));
    return;
  }
}

GameSession _people() {
  final session = GameSession(random: Random(1), now: () => DateTime(2026, 9, 25, 21));
  session.addPlayer('Jess');
  session.addPlayer('Theo');
  session.addPlayer('Dad');
  session.addPlayer('Nana');
  session.players[0].score = 120;
  return session;
}

GameSession _home() => GameSession();

GameSession _deck() {
  final session = _people();
  session.phase = Phase.deck;
  return session;
}

GameSession _cameraOff() {
  final session = _people();
  session.phase = Phase.cameraOff;
  return session;
}

GameSession _framing() {
  final session = _people();
  session.phase = Phase.framing;
  session.turnQueue = [poseById('star_jump')];
  session.liveFrame = synthesizePose(poseById('star_jump').angles);
  session.partHead = true;
  session.partArms = true;
  session.partLegs = true;
  session.markerGreen = true;
  session.framingPrompt = 'Hold still';
  return session;
}

GameSession _countdown() {
  final session = _framing();
  session.phase = Phase.countdown;
  session.elapsed = 0.8;
  return session;
}

GameSession _window() {
  final session = _countdown();
  session.phase = Phase.window;
  session.elapsed = 3;
  session.liveFit = FitReading(
    fit: 0.68,
    percent: 68,
    inTolerance: false,
    zone: FitZone.close,
    canSee: true,
    coach: 'Right leg — kick it out wider!',
    limbs: {
      LimbId.lArm: _limb(LimbId.lArm, LimbStatus.green, 0.9),
      LimbId.rArm: _limb(LimbId.rArm, LimbStatus.amber, 0.6),
      LimbId.lLeg: _limb(LimbId.lLeg, LimbStatus.green, 0.92),
      LimbId.rLeg: _limb(LimbId.rLeg, LimbStatus.red, 0.2),
    },
  );
  return session;
}

GameSession _hold() {
  final session = _window();
  session.phase = Phase.hold;
  session.hold.held = 0.6;
  session.liveFit = FitReading(
    fit: 0.94,
    percent: 94,
    inTolerance: true,
    zone: FitZone.match,
    canSee: true,
    coach: null,
    limbs: {
      for (final id in LimbId.values) id: _limb(id, LimbStatus.green, 1),
    },
  );
  return session;
}

LimbScore _limb(LimbId id, LimbStatus status, double score) {
  return LimbScore(id: id, score: score, status: status, visible: true);
}

Snap _snap(String id, String playerId, String name, {int points = 120, bool matched = true, String stamp = 'PERFECT FIT'}) {
  return Snap(
    id: id,
    round: 1,
    playerId: playerId,
    playerName: name,
    poseId: 'star_jump',
    poseName: 'Star Jump',
    points: points,
    fitPercent: matched ? 96 : 58,
    stamp: stamp,
    matched: matched,
    sudden: false,
    seq: 1,
    at: DateTime(2026, 9, 25),
    footer: 'R1 · POSE 1 · SEP 25',
    breakdown: const ScoreBreakdown(
      fitPoints: 96,
      holdBonus: 10,
      wallBonus: 14,
      multiplier: 1,
      total: 120,
      perfect: true,
      matched: true,
      fitPercent: 96,
      stamp: 'PERFECT FIT',
    ),
  );
}

GameSession _snapshot() {
  final session = _people();
  session.phase = Phase.snapshot;
  session.lastSnap = _snap('s1', 'p1', 'Jess');
  session.lastScore = session.lastSnap!.breakdown;
  return session;
}

GameSession _handoff() {
  final session = _people();
  session.phase = Phase.handoff;
  session.turn = 1;
  session.round = 2;
  return session;
}

GameSession _results() {
  final session = _people();
  session.phase = Phase.results;
  session.winners = ['p4'];
  session.players[3].score = 1240;
  session.snaps.add(_snap('n', 'p4', 'Nana', points: 128));
  session.snaps.add(_snap('j', 'p1', 'Jess'));
  return session;
}

GameSession _tie() {
  final session = _people();
  session.phase = Phase.tie;
  session.tiedIds = ['p1', 'p4'];
  session.players[0].score = 1240;
  session.players[3].score = 1240;
  session.snaps.add(_snap('j', 'p1', 'Jess'));
  session.snaps.add(_snap('n', 'p4', 'Nana', points: 128));
  return session;
}

GameSession _judge() {
  final session = _people();
  session.phase = Phase.judgePick;
  session.round = 2;
  session.snaps.add(_snap('a', 'p1', 'Jess'));
  session.snaps.add(_snap('b', 'p3', 'Dad', matched: false, stamp: 'SO CLOSE · 61%'));
  session.snaps.add(_snap('c', 'p4', 'Nana', points: 104));
  return session;
}

GameSession _stepBack() {
  final session = _window();
  session.outOfFrame = true;
  return session;
}

GameSession _kids() {
  final session = _people();
  session.decks.add(DeckId.kids);
  session.phase = Phase.results;
  session.snaps.add(_snap('a', 'p1', 'Jess'));
  session.snaps.add(_snap('b', 'p2', 'Theo', matched: false, stamp: 'SO CLOSE · 63%'));
  session.snaps.add(_snap('c', 'p4', 'Nana'));
  session.kept.add('a');
  return session;
}
