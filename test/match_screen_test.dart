import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strike_a_pose/home_screen.dart';
import 'package:strike_a_pose/match_screen.dart';
import 'package:strike_a_pose/pose_catalog.dart';
import 'package:strike_a_pose/round.dart';

void main() {
  Future<void> pumpMatch(
    WidgetTester tester, {
    required Duration Function() elapsed,
  }) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    return tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(
          plan: RoundPlan([PoseCatalog.all.first]),
          elapsed: elapsed,
        ),
      ),
    );
  }

  testWidgets('a strike scores and the flash ends the round', (tester) async {
    var elapsed = Duration.zero;
    await pumpMatch(tester, elapsed: () => elapsed);
    expect(find.text('Score 0'), findsOneWidget);
    expect(find.text('Strike'), findsOneWidget);
    expect(find.byTooltip('Leave round'), findsOneWidget);
    expect(tester.getSize(find.byType(IconButton)), const Size(48, 48));

    await tester.tap(find.text('Strike'));
    await tester.pump();
    expect(find.text('Score 1'), findsOneWidget);
    expect(find.text('Strike'), findsNothing);
    expect(find.byTooltip('Leave round'), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      const Color(0xFF1B7A43),
    );

    elapsed = const Duration(milliseconds: 400);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('1 of 1'), findsOneWidget);
    expect(find.text('Leave'), findsOneWidget);
    expect(find.byTooltip('Leave round'), findsNothing);
  });

  testWidgets('the countdown reads 3.5s after 2.5 seconds', (tester) async {
    var elapsed = Duration.zero;
    await pumpMatch(tester, elapsed: () => elapsed);
    expect(find.text('6.0s'), findsOneWidget);
    elapsed = const Duration(milliseconds: 2500);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('3.5s'), findsOneWidget);
  });

  testWidgets('Leave on the result screen returns to the screen that opened '
      'the round', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var elapsed = Duration.zero;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => MatchScreen(
                      plan: RoundPlan([PoseCatalog.all.first]),
                      elapsed: () => elapsed,
                    ),
                  ),
                ),
                child: const Text('Practice'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Practice'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Strike'));
    await tester.pump();
    elapsed = const Duration(milliseconds: 400);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('1 of 1'), findsOneWidget);

    await tester.tap(find.text('Leave'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(MatchScreen), findsNothing);
    expect(find.text('Practice').hitTestable(), findsOneWidget);
  });

  testWidgets('the deadline shows a miss and keeps the score', (tester) async {
    var elapsed = Duration.zero;
    await pumpMatch(tester, elapsed: () => elapsed);
    elapsed = const Duration(seconds: 6);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Miss'), findsOneWidget);
    expect(find.text('Score 0'), findsOneWidget);
    expect(find.byTooltip('Leave round'), findsOneWidget);
  });

  testWidgets(
    'a pose window spent in the background does not expire the pose',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MatchScreen(plan: RoundPlan([PoseCatalog.all.first])),
        ),
      );
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.runAsync(
        () => Future<void>.delayed(poseWindow + const Duration(seconds: 1)),
      );
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Strike'), findsOneWidget);
      expect(find.text('Miss'), findsNothing);
    },
  );

  testWidgets('practice opens the strike button', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.tap(find.text('Practice'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Strike'), findsOneWidget);
  });
}
