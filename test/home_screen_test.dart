import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strike_a_pose/home_screen.dart';
import 'package:strike_a_pose/match_screen.dart';

void main() {
  Future<void> openPractice(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.tap(find.text('Practice'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Strike').hitTestable(), findsOneWidget);
  }

  testWidgets('an iOS edge swipe on a live pose goes back to Home', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await openPractice(tester);
      final swipe = await tester.startGesture(const Offset(5, 400));
      await swipe.moveBy(const Offset(300, 0));
      await swipe.up();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(MatchScreen), findsNothing);
      expect(find.text('Practice').hitTestable(), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('two taps on Practice before a frame open one round', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    // Navigator absorbs pointers from a push until the next frame, so only an
    // accessibility tap can reach Practice a second time before that frame.
    tester.semantics.tap(find.semantics.byLabel('Practice'));
    tester.semantics.tap(find.semantics.byLabel('Practice'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    // A covered route is built offstage, and the default finder skips it.
    expect(find.byType(MatchScreen, skipOffstage: false), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Leave round on a live pose goes back to Home', (tester) async {
    await openPractice(tester);
    await tester.tap(find.byTooltip('Leave round'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(MatchScreen), findsNothing);
    expect(find.text('Practice').hitTestable(), findsOneWidget);
  });
}
