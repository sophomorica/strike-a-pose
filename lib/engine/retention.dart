import 'dart:convert';
import 'dart:io';

import 'catalog.dart';
import 'fit.dart';
import 'game.dart';

class GameRecord {
  final String id;
  final bool kidsGame;
  final bool finished;
  final List<String> kept;
  final List<Map<String, Object?>> snaps;
  final Map<String, int> scores;
  final List<Map<String, Object?>> judgePicks;
  final List<String> decks;
  final String? tie;

  const GameRecord({
    required this.id,
    required this.kidsGame,
    required this.finished,
    required this.kept,
    required this.snaps,
    required this.scores,
    required this.judgePicks,
    required this.decks,
    required this.tie,
  });

  List<String> get unkeptIds => kidsGame
      ? snaps
          .map((snap) => snap['id'] as String)
          .where((id) => !kept.contains(id))
          .toList()
      : const [];

  bool get sweepOnLaunch => kidsGame && !finished;

  Map<String, Object?> toJson() => {
        'id': id,
        'kidsGame': kidsGame,
        'finished': finished,
        'kept': kept,
        'snaps': snaps,
        'scores': scores,
        'judgePicks': judgePicks,
        'decks': decks,
        'tie': tie,
      };

  static GameRecord fromJson(Map<String, Object?> json) {
    return GameRecord(
      id: json['id'] as String,
      kidsGame: json['kidsGame'] as bool? ?? false,
      finished: json['finished'] as bool? ?? false,
      kept: (json['kept'] as List?)?.cast<String>() ?? const [],
      snaps: ((json['snaps'] as List?) ?? const [])
          .map((item) => Map<String, Object?>.from(item as Map))
          .toList(),
      scores: ((json['scores'] as Map?) ?? const {}).map(
        (key, value) => MapEntry(key as String, value as int),
      ),
      judgePicks: ((json['judgePicks'] as List?) ?? const [])
          .map((item) => Map<String, Object?>.from(item as Map))
          .toList(),
      decks: (json['decks'] as List?)?.cast<String>() ?? const [],
      tie: json['tie'] as String?,
    );
  }
}

GameRecord recordFrom(GameSession session) {
  return GameRecord(
    id: session.gameId,
    kidsGame: session.kidsGame,
    finished: session.finished,
    kept: session.kept.toList(),
    snaps: session.snaps
        .map((snap) => {
              'id': snap.id,
              'round': snap.round,
              'playerId': snap.playerId,
              'playerName': snap.playerName,
              'poseId': snap.poseId,
              'poseName': snap.poseName,
              'points': snap.points,
              'fitPercent': snap.fitPercent,
              'stamp': snap.stamp,
              'sudden': snap.sudden,
              'fileName': snap.fileName,
            })
        .toList(),
    scores: {for (final player in session.players) player.id: player.score},
    judgePicks: session.judgePicks
        .map((pick) => {
              'round': pick.round,
              'judgeId': pick.judgeId,
              'snapId': pick.snapId,
              'ownerId': pick.ownerId,
            })
        .toList(),
    decks: session.decks.map((deck) => deck.name).toList(),
    tie: session.crownNote.isEmpty ? null : session.crownNote,
  );
}

class SavedSettings {
  final Settings settings;
  final List<Player> players;
  final bool primed;
  final Set<DeckId> decks;

  const SavedSettings({
    required this.settings,
    required this.players,
    required this.primed,
    required this.decks,
  });
}

class FileSnapStore {
  FileSnapStore(this.root);

  final Directory root;

  Directory get snapsRoot => Directory('${root.path}/snaps');

  Future<void> saveSettings(GameSession session) async {
    final file = File('${root.path}/settings.json');
    await file.parent.create(recursive: true);
    final payload = {
      'primed': session.primed,
      'rounds': session.settings.rounds,
      'posesPerTurn': session.settings.posesPerTurn,
      'windowSeconds': session.settings.windowSeconds,
      'body': session.settings.body.name,
      'judgeOn': session.settings.judgeOn,
      'sound': session.settings.sound,
      'haptics': session.settings.haptics,
      'reduceMotion': session.settings.reduceMotion,
      'decks': session.decks.map((deck) => deck.name).toList(),
      'players': session.players
          .map((player) => {
                'id': player.id,
                'name': player.name,
                'color': player.color,
              })
          .toList(),
    };
    await file.writeAsString(jsonEncode(payload));
  }

  Future<void> loadSettings(GameSession session) async {
    final file = File('${root.path}/settings.json');
    if (!file.existsSync()) return;
    final json = jsonDecode(await file.readAsString()) as Map<String, Object?>;
    session.primed = json['primed'] as bool? ?? false;
    session.settings.rounds = json['rounds'] as int? ?? 3;
    session.settings.posesPerTurn = json['posesPerTurn'] as int? ?? 5;
    session.settings.windowSeconds = json['windowSeconds'] as int? ?? 7;
    session.settings.body = json['body'] == 'upper' ? BodyMode.upper : BodyMode.full;
    session.settings.judgeOn = json['judgeOn'] as bool? ?? true;
    session.settings.sound = json['sound'] as bool? ?? true;
    session.settings.haptics = json['haptics'] as bool? ?? true;
    session.settings.reduceMotion = json['reduceMotion'] as bool? ?? false;
    session.players.clear();
    for (final raw in (json['players'] as List?) ?? const []) {
      final map = Map<String, Object?>.from(raw as Map);
      session.players.add(Player(
        id: map['id'] as String,
        name: map['name'] as String,
        color: map['color'] as String,
      ));
    }
    final decks = (json['decks'] as List?)?.cast<String>() ?? const ['classics'];
    session.decks
      ..clear()
      ..addAll(DeckId.values.where((deck) => decks.contains(deck.name)));
    if (session.decks.isEmpty) session.decks.add(DeckId.classics);
  }

  Future<void> saveGame(GameSession session) async {
    final record = recordFrom(session);
    final dir = Directory('${snapsRoot.path}/${record.id}');
    await dir.create(recursive: true);
    await File('${dir.path}/game.json').writeAsString(jsonEncode(record.toJson()));
  }

  Future<void> writeJpeg(String gameId, String fileName, List<int> bytes) async {
    final dir = Directory('${snapsRoot.path}/$gameId');
    await dir.create(recursive: true);
    await File('${dir.path}/$fileName').writeAsBytes(bytes, flush: true);
  }

  Future<GameRecord?> loadGame(String gameId) async {
    final file = File('${snapsRoot.path}/$gameId/game.json');
    if (!file.existsSync()) return null;
    return GameRecord.fromJson(
      Map<String, Object?>.from(jsonDecode(await file.readAsString()) as Map),
    );
  }

  Future<List<String>> listGameIds() async {
    if (!snapsRoot.existsSync()) return const [];
    return snapsRoot
        .listSync()
        .whereType<Directory>()
        .map((dir) => dir.path.split(Platform.pathSeparator).last)
        .toList();
  }

  Future<void> applyExpiredUndo(GameSession session) async {
    if (session.undoSnapId == null || session.undoLeft > 0) return;
    final id = session.undoSnapId!;
    String? name;
    for (final snap in session.snaps) {
      if (snap.id == id) name = snap.fileName;
    }
    final doomed = session.takeCommittedDeletes();
    if (name != null && doomed.contains(id)) {
      await deleteJpeg(session.gameId, name);
    }
  }

  Future<void> deleteJpeg(String gameId, String fileName) async {
    final file = File('${snapsRoot.path}/$gameId/$fileName');
    if (file.existsSync()) await file.delete();
  }

  Future<void> deleteGame(String gameId) async {
    final dir = Directory('${snapsRoot.path}/$gameId');
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  Future<void> deleteAll() async {
    if (snapsRoot.existsSync()) await snapsRoot.delete(recursive: true);
    await snapsRoot.create(recursive: true);
  }

  Future<int> totalBytes() async {
    if (!snapsRoot.existsSync()) return 0;
    var total = 0;
    await for (final entity in snapsRoot.list(recursive: true)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  Future<List<String>> sweepUnfinishedKids() async {
    final removed = <String>[];
    for (final id in await listGameIds()) {
      final record = await loadGame(id);
      if (record != null && record.sweepOnLaunch) {
        await deleteGame(id);
        removed.add(id);
      }
    }
    return removed;
  }

  Future<void> applyKidsEnd(GameSession session) async {
    final record = recordFrom(session);
    if (!record.kidsGame) {
      session.finished = true;
      await saveGame(session);
      return;
    }
    for (final id in record.unkeptIds) {
      final snap = session.snaps.cast<Snap?>().firstWhere(
            (item) => item!.id == id,
            orElse: () => null,
          );
      if (snap != null) await deleteJpeg(session.gameId, snap.fileName);
    }
    session.snaps.removeWhere((snap) => record.unkeptIds.contains(snap.id));
    session.finished = true;
    await saveGame(session);
  }
}

bool storageNotice(int bytes) => bytes > 500 * 1024 * 1024;
