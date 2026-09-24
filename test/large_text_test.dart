import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strike_a_pose/home_screen.dart';
import 'package:strike_a_pose/match_screen.dart';
import 'package:strike_a_pose/pose_catalog.dart';
import 'package:strike_a_pose/round.dart';

void main() {
  const pixelRatio = 3.0;
  const phones = [
    (size: Size(375, 812), textScale: 1.0),
    (size: Size(375, 812), textScale: 53 / 17),
    (size: Size(430, 932), textScale: 1.0),
  ];

  Future<void> pumpOnPhone(
    WidgetTester tester,
    Widget screen, {
    required Size size,
    required double textScale,
  }) {
    tester.view.devicePixelRatio = pixelRatio;
    tester.view.physicalSize = size * pixelRatio;
    tester.view.padding = const FakeViewPadding(
      top: 50 * pixelRatio,
      bottom: 34 * pixelRatio,
    );
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    return tester.pumpWidget(MaterialApp(home: screen));
  }

  String phone(Size size, double textScale) {
    return '${size.width.toInt()} by ${size.height.toInt()} '
        'at text scale ${textScale.toStringAsFixed(2)}';
  }

  for (final (:size, :textScale) in phones) {
    testWidgets('Home keeps Practice tappable at ${phone(size, textScale)}', (
      tester,
    ) async {
      await pumpOnPhone(
        tester,
        const HomeScreen(),
        size: size,
        textScale: textScale,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Practice').hitTestable(), findsOneWidget);
    });
  }

  final poseWithLongestName = PoseCatalog.all.reduce(
    (a, b) => b.name.length > a.name.length ? b : a,
  );
  for (final (:size, :textScale) in phones) {
    testWidgets('Match keeps Strike tappable at ${phone(size, textScale)}', (
      tester,
    ) async {
      await pumpOnPhone(
        tester,
        MatchScreen(
          plan: RoundPlan([poseWithLongestName]),
          elapsed: () => Duration.zero,
        ),
        size: size,
        textScale: textScale,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Strike').hitTestable(), findsOneWidget);
    });
  }
}
