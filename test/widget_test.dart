import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strike_a_pose/engine/catalog.dart';
import 'package:strike_a_pose/engine/fit.dart';
import 'package:strike_a_pose/engine/game.dart';
import 'package:strike_a_pose/engine/retention.dart';
import 'package:strike_a_pose/engine/score.dart';
import 'package:strike_a_pose/shell.dart';
import 'package:strike_a_pose/sound.dart';
import 'package:strike_a_pose/ui/screens.dart';
import 'package:strike_a_pose/wake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home offers play, how to play, and gallery', (tester) async {
    await _pump(tester, GameSession());
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('How to play'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Duo'), findsNothing);
  });

  testWidgets('first play opens players, then the deck, then priming', (tester) async {
    final session = GameSession();
    await _pump(tester, session);
    await tester.tap(find.text('Play'));
    await tester.pump();
    expect(find.text('WHO\'S PLAYING?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Jess');
    await tester.tap(find.text('Add'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Theo');
    await tester.tap(find.text('Add'));
    await tester.pump();
    await tester.tap(find.text('Let\'s pick a deck'));
    await tester.pump();
    expect(find.text('PICK A DECK'), findsOneWidget);
    expect(find.text('CLASSICS'), findsOneWidget);
    expect(find.text('HARD MODE'), findsOneWidget);
    expect(find.text('Strike a pose!'), findsOneWidget);
    await tester.tap(find.text('Strike a pose!'));
    await tester.pump();
    expect(find.textContaining('IS THE MIRROR'), findsOneWidget);
    expect(session.phase, Phase.priming);
  });

  testWidgets('continuing priming without a camera offers referee mode', (tester) async {
    final session = _family();
    session.phase = Phase.priming;
    await _pump(tester, session);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Play Referee mode'), findsOneWidget);
    expect(find.text('Open Settings'), findsOneWidget);
  });

  testWidgets('framing shows the spot, the marker, and body chips', (tester) async {
    final session = _posed(Phase.framing);
    session.partHead = true;
    session.partArms = true;
    await _pump(tester, session);
    expect(find.text('FIND YOUR SPOT'), findsOneWidget);
    expect(find.text('STAND HERE'), findsOneWidget);
    expect(find.text('Head'), findsOneWidget);
    expect(find.text('Arms'), findsOneWidget);
    expect(find.text('Legs'), findsOneWidget);
    expect(find.byTooltip('Pause'), findsNothing);
  });

  testWidgets('countdown hides the pause button', (tester) async {
    final session = _posed(Phase.countdown);
    session.elapsed = 0.8;
    await _pump(tester, session);
    expect(find.text('STAR JUMP'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Copy the shape before the wall hits!'), findsOneWidget);
    expect(find.byTooltip('Pause'), findsNothing);
  });

  testWidgets('the pose window shows the meter, chips, coach, and pause', (tester) async {
    final session = _posed(Phase.window);
    session.liveFit = _offFit();
    await _pump(tester, session);
    expect(find.text('FIT'), findsOneWidget);
    expect(find.text('COLD'), findsWidgets);
    expect(find.text('CLOSE'), findsWidgets);
    expect(find.text('MATCH'), findsWidgets);
    expect(find.text('L ARM'), findsOneWidget);
    expect(find.text('R LEG'), findsOneWidget);
    expect(find.text('Right leg — kick it out wider!'), findsOneWidget);
    expect(find.byTooltip('Pause'), findsOneWidget);
    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('Skip pose'), findsOneWidget);
    expect(find.text('End game'), findsOneWidget);
  });

  testWidgets('hold keeps the holding line up and hides chrome', (tester) async {
    final session = _posed(Phase.hold);
    session.hold.held = 0.6;
    session.liveFit = _matchFit();
    await _pump(tester, session);
    expect(find.text('HOLD IT!'), findsOneWidget);
    expect(find.text('Keep holding!'), findsOneWidget);
    expect(find.byTooltip('Pause'), findsNothing);
    expect(find.text('L ARM'), findsNothing);
  });

  testWidgets('a miss snapshot shows the so close stamp', (tester) async {
    final session = _family();
    session.phase = Phase.snapshot;
    session.lastSnap = _snap(matched: false, stamp: 'SO CLOSE · 58%');
    session.lastScore = const ScoreBreakdown(
      fitPoints: 0,
      holdBonus: 0,
      wallBonus: 0,
      multiplier: 1,
      total: 0,
      perfect: false,
      matched: false,
      fitPercent: 58,
      stamp: 'SO CLOSE · 58%',
    );
    await _pump(tester, session);
    expect(find.textContaining('SO CLOSE'), findsWidgets);
    expect(find.text('Next pose'), findsOneWidget);
    expect(find.textContaining('not Photos'), findsOneWidget);
  });

  testWidgets('handoff names the next player and hides the camera line', (tester) async {
    final session = _family();
    session.phase = Phase.handoff;
    session.turn = 1;
    await _pump(tester, session);
    expect(find.text('Pass the phone to'), findsOneWidget);
    expect(find.text('THEO'), findsOneWidget);
    expect(find.textContaining('camera\'s paused'), findsOneWidget);
    expect(find.textContaining('I\'m Theo'), findsOneWidget);
  });

  testWidgets('judge grid hides the judge and crowns a snap', (tester) async {
    final session = _family();
    session.phase = Phase.judgePick;
    session.round = 1;
    session.snaps.add(_snap(id: 's1', playerId: 'p2', playerName: 'Theo'));
    session.snaps.add(_snap(id: 's2', playerId: 'p1', playerName: 'Jess'));
    await _pump(tester, session);
    expect(find.text('JUDGE\'S PICK'), findsOneWidget);
    expect(find.textContaining('no self-picks'), findsOneWidget);
    expect(find.textContaining('THEO'), findsWidgets);
    expect(find.textContaining('JESS'), findsNothing);
    await tester.tap(find.textContaining('THEO'));
    await tester.pump();
    expect(find.textContaining('+50'), findsOneWidget);
  });

  testWidgets('results name the winner and keep snaps in the app', (tester) async {
    final session = _family();
    session.phase = Phase.results;
    session.winners = ['p2'];
    session.players[1].score = 128;
    session.snaps.add(_snap(id: 's1', playerId: 'p2', playerName: 'Theo', points: 128));
    await _pump(tester, session);
    expect(find.textContaining('THEO WINS'), findsOneWidget);
    expect(find.text('Play again'), findsOneWidget);
    expect(find.textContaining('never saved to Photos'), findsOneWidget);
  });

  testWidgets('a tie offers sudden death and sharing the crown', (tester) async {
    final session = _family();
    session.phase = Phase.tie;
    session.tiedIds = ['p1', 'p2'];
    session.snaps.add(_snap(id: 'a', playerId: 'p1', playerName: 'Jess'));
    session.snaps.add(_snap(id: 'b', playerId: 'p2', playerName: 'Theo'));
    await _pump(tester, session);
    expect(find.text('DEAD HEAT!'), findsOneWidget);
    expect(find.text('Sudden death!'), findsOneWidget);
    expect(find.text('Share the crown'), findsOneWidget);
  });

  testWidgets('kids results ask to keep hearts', (tester) async {
    final session = _family();
    session.decks.add(DeckId.kids);
    session.phase = Phase.results;
    session.snaps.add(_snap(id: 'k1', playerId: 'p1', playerName: 'Jess'));
    await _pump(tester, session);
    expect(find.text('KEEP YOUR FAVES'), findsOneWidget);
    expect(find.textContaining('Tap ♥ to keep'), findsOneWidget);
    expect(find.text('Keep all'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    await tester.tap(find.text('Keep all'));
    await tester.pump();
    expect(session.kept, contains('k1'));
  });

  testWidgets('leaving kids results confirms the unkept delete', (tester) async {
    final session = _family();
    session.decks.add(DeckId.kids);
    session.phase = Phase.results;
    session.snaps.add(_snap(id: 'k1', playerId: 'p1', playerName: 'Jess'));
    await _pump(tester, session);
    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(find.text('Delete 1 unkept snaps?'), findsOneWidget);
    expect(find.text('Back to keep'), findsOneWidget);
    expect(find.text('Delete and continue'), findsOneWidget);
  });

  testWidgets('step back covers the play screen', (tester) async {
    final session = _posed(Phase.window);
    session.outOfFrame = true;
    await _pump(tester, session);
    expect(find.text('STEP BACK IN!'), findsOneWidget);
  });

  testWidgets('settings expose the locked defaults and no wall style', (tester) async {
    await _pump(tester, GameSession());
    await tester.tap(find.byTooltip('Settings'));
    await tester.pump();
    expect(find.text('Normal 7'), findsOneWidget);
    expect(find.text('Judge\'s pick'), findsOneWidget);
    expect(find.text('Delete all'), findsOneWidget);
    expect(find.textContaining('Wall'), findsNothing);
    expect(find.textContaining('Glow'), findsNothing);
  });

  testWidgets('how to play has three cards', (tester) async {
    await _pump(tester, GameSession());
    await tester.tap(find.text('How to play'));
    await tester.pump();
    expect(find.text('Pass one iPhone'), findsOneWidget);
    expect(find.text('Copy the hole'), findsOneWidget);
    expect(find.text('Hold for one second'), findsOneWidget);
  });

  testWidgets('gallery empty state and a stored game', (tester) async {
    final session = GameSession();
    await tester.pumpWidget(MaterialApp(
      home: GalleryScreen(
        session: session,
        games: [
          GameRecord(
            id: 'g1',
            kidsGame: false,
            finished: true,
            kept: const [],
            snaps: const [
              {'id': 'a'},
            ],
            scores: const {},
            judgePicks: const [],
            decks: const ['classics'],
            tie: null,
          ),
        ],
        onClose: () {},
        onDeleteSnap: (_) {},
        onUndo: () {},
        onDeleteGame: (_) {},
      ),
    ));
    expect(find.text('g1'), findsOneWidget);
    expect(find.text('1 snaps'), findsOneWidget);
  });

  testWidgets('large text does not throw on the deck', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(StrikeShell(
      session: _family()..phase = Phase.deck,
      sound: SilentSound(),
      wake: NoWake(),
      driveClock: false,
      textScaler: const TextScaler.linear(1.4),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('PICK A DECK'), findsOneWidget);
  });
}

Future<void> _pump(WidgetTester tester, GameSession session) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(StrikeShell(
    session: session,
    sound: SilentSound(),
    wake: NoWake(),
    driveClock: false,
  ));
  await tester.pump();
}

GameSession _family() {
  final session = GameSession(random: Random(1));
  session.addPlayer('Jess');
  session.addPlayer('Theo');
  session.addPlayer('Dad');
  return session;
}

GameSession _posed(Phase phase) {
  final session = _family();
  session.phase = phase;
  session.turnQueue = [poseById('star_jump')];
  session.players.first.score = 120;
  return session;
}

FitReading _offFit() {
  return FitReading(
    fit: 0.68,
    percent: 68,
    inTolerance: false,
    zone: FitZone.close,
    canSee: true,
    coach: 'Right leg — kick it out wider!',
    limbs: {
      for (final id in LimbId.values)
        id: LimbScore(
          id: id,
          score: id == LimbId.rLeg ? 0.2 : 0.9,
          status: id == LimbId.rLeg ? LimbStatus.red : LimbStatus.green,
          visible: true,
        ),
    },
  );
}

FitReading _matchFit() {
  return FitReading(
    fit: 0.94,
    percent: 94,
    inTolerance: true,
    zone: FitZone.match,
    canSee: true,
    coach: null,
    limbs: {
      for (final id in LimbId.values)
        id: LimbScore(id: id, score: 1, status: LimbStatus.green, visible: true),
    },
  );
}

Snap _snap({
  String id = 's1',
  String playerId = 'p1',
  String playerName = 'Jess',
  int points = 120,
  bool matched = true,
  String stamp = 'PERFECT FIT',
}) {
  return Snap(
    id: id,
    round: 1,
    playerId: playerId,
    playerName: playerName,
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
      fitPoints: 0,
      holdBonus: 0,
      wallBonus: 0,
      multiplier: 1,
      total: 0,
      perfect: false,
      matched: false,
      fitPercent: 58,
      stamp: 'SO CLOSE · 58%',
    ),
  );
}
