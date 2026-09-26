import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'device_services.dart';
import 'engine/game.dart';
import 'engine/retention.dart';
import 'mlkit_pose_source.dart';
import 'pose_feed.dart';
import 'pose_gate.dart';
import 'shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final docs = await getApplicationDocumentsDirectory();
  final store = FileSnapStore(Directory(docs.path));
  await store.sweepUnfinishedKids();
  final session = GameSession();
  await store.loadSettings(session);
  final games = <GameRecord>[];
  for (final id in await store.listGameIds()) {
    final record = await store.loadGame(id);
    if (record != null) games.add(record);
  }
  final bytes = await store.totalBytes();
  runApp(StrikeShell(
    session: session,
    store: store,
    feed: createPoseSource(),
    sound: AssetSound(),
    wake: WakelockStay(),
    storageBytes: bytes,
    games: games,
    showDebugDots: const bool.fromEnvironment('DEBUG_LANDMARKS'),
  ));
}

PoseFeed createPoseSource() {
  if (allowsFakePose()) return FakePoseSource();
  return MlKitPoseSource();
}
