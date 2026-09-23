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

    await tester.tap(find.text('Strike'));
    await tester.pump();
    expect(find.text('Score 1'), findsOneWidget);
    expect(find.text('Strike'), findsNothing);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      const Color(0xFF1F8A4C),
    );

    elapsed = const Duration(milliseconds: 400);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('1 of 1'), findsOneWidget);
  });

  testWidgets('the deadline shows a miss and keeps the score', (tester) async {
    var elapsed = Duration.zero;
    await pumpMatch(tester, elapsed: () => elapsed);
    elapsed = const Duration(seconds: 6);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Miss'), findsOneWidget);
    expect(find.text('Score 0'), findsOneWidget);
  });

  testWidgets('practice opens the strike button', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.tap(find.text('Practice'));
    await tester.pump();
    expect(find.text('Strike'), findsOneWidget);
  });
}
