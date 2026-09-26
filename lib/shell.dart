import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'engine/body.dart';
import 'engine/game.dart';
import 'engine/retention.dart';
import 'pose_feed.dart';
import 'snap_image.dart';
import 'sound.dart';
import 'theme.dart';
import 'ui/chrome.dart';
import 'ui/screens.dart';
import 'wake.dart';

enum _Overlay { none, settings, howTo, gallery }

class StrikeShell extends StatefulWidget {
  const StrikeShell({
    super.key,
    required this.session,
    required this.sound,
    required this.wake,
    this.store,
    this.feed,
    this.driveClock = true,
    this.boot = true,
    this.storageBytes = 0,
    this.showDebugDots = false,
    this.games = const [],
    this.textScaler,
  });

  final GameSession session;
  final SoundBoard sound;
  final StayAwake wake;
  final FileSnapStore? store;
  final PoseFeed? feed;
  final bool driveClock;
  final bool boot;
  final int storageBytes;
  final bool showDebugDots;
  final List<GameRecord> games;
  final TextScaler? textScaler;

  @override
  State<StrikeShell> createState() => _StrikeShellState();
}

class _StrikeShellState extends State<StrikeShell> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  _Overlay overlay = _Overlay.none;
  bool confirmDeleteAll = false;
  bool leaveAgain = false;
  bool _askedPermission = false;
  bool _cameraOn = false;
  PoseFrame? _latest;
  Phase? _lastPhase;
  final Set<String> _written = {};
  List<GameRecord> _games = [];

  static const _live = {
    Phase.framing,
    Phase.countdown,
    Phase.window,
    Phase.hold,
    Phase.suddenWindow,
  };

  @override
  void initState() {
    super.initState();
    _games = [...widget.games];
    _ticker = createTicker(_onTick);
    if (widget.driveClock) _ticker.start();
    widget.feed?.frames.listen((frame) => _latest = frame);
    widget.feed?.changes.addListener(_refresh);
    if (widget.boot) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    widget.feed?.changes.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (dt <= 0 || dt > 0.25) return;
    final size = context.size;
    widget.session.tick(
      dt,
      _cameraOn ? _latest : null,
      viewWidth: size?.width,
      viewHeight: size?.height,
    );
    _afterTick();
    if (mounted) setState(() {});
  }

  void changed() {
    setState(() {});
    _sync();
  }

  Future<void> _sync() async {
    final session = widget.session;
    _cue(session.phase);
    final awake = session.phase != Phase.home && session.phase != Phase.players && session.phase != Phase.deck;
    if (awake) {
      await widget.wake.enable();
    } else {
      await widget.wake.disable();
    }
    await _syncCamera();
    await _persist();
    if (mounted) setState(() {});
  }

  void _cue(Phase phase) {
    if (_lastPhase == phase) return;
    final previous = _lastPhase;
    _lastPhase = phase;
    if (!widget.session.settings.sound || previous == null) return;
    final cue = switch (phase) {
      Phase.countdown => 'tick',
      Phase.hold => 'thump',
      Phase.snapshot => 'shutter',
      Phase.judgeReveal => 'pop',
      Phase.results => 'fanfare',
      _ => null,
    };
    if (cue != null) widget.sound.play(cue);
    if (widget.session.settings.haptics && cue != null) {
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _syncCamera() async {
    final feed = widget.feed;
    final session = widget.session;
    if (session.referee) return;
    if (session.phase == Phase.awaitingPermission && !_askedPermission) {
      _askedPermission = true;
      if (feed == null) {
        session.onPermission(false);
        return;
      }
      final granted = await feed.start();
      _cameraOn = granted;
      session.onPermission(granted);
      return;
    }
    if (feed == null) return;
    final live = _live.contains(session.phase);
    if (live && !_cameraOn) {
      _cameraOn = await feed.start();
      if (!_cameraOn) session.onPermission(false);
    } else if (!live && _cameraOn && session.phase != Phase.awaitingPermission) {
      _cameraOn = false;
      _latest = null;
      await feed.stop();
    }
  }

  Future<void> _persist() async {
    final store = widget.store;
    if (store == null) return;
    await store.saveSettings(widget.session);
    for (final snap in widget.session.snaps) {
      if (_written.add(snap.id)) {
        await store.writeJpeg(widget.session.gameId, snap.fileName, renderSnapJpeg(snap));
      }
    }
    if (widget.session.snaps.isNotEmpty) await store.saveGame(widget.session);
    String? pendingName;
    final pendingId = widget.session.undoSnapId;
    if (pendingId != null && widget.session.undoLeft <= 0) {
      pendingName = _fileFor(pendingId);
    }
    final doomed = widget.session.takeCommittedDeletes();
    if (pendingName != null && doomed.isNotEmpty) {
      await store.deleteJpeg(widget.session.gameId, pendingName);
    }
  }

  String? _fileFor(String id) {
    for (final snap in widget.session.snaps) {
      if (snap.id == id) return snap.fileName;
    }
    return null;
  }

  void _afterTick() {
    _persist();
    _cue(widget.session.phase);
  }

  Future<void> _leave({required bool again}) async {
    final session = widget.session;
    if (session.kidsGame && session.unkeptCount > 0) {
      setState(() {
        session.askDeleteUnkept = true;
        leaveAgain = again;
      });
      return;
    }
    await _commitLeave(again);
  }

  Future<void> _commitLeave(bool again) async {
    final session = widget.session;
    await widget.store?.applyKidsEnd(session);
    session.askDeleteUnkept = false;
    session.finished = true;
    session.phase = again ? Phase.deck : Phase.home;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: sapTheme(),
      builder: (context, child) {
        final scaler = widget.textScaler;
        if (scaler == null) return child!;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scaler),
          child: child!,
        );
      },
      home: Scaffold(
        backgroundColor: Sap.indigoNight,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: RepaintBoundary(
              key: const ValueKey('shot'),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const PartyBackground(child: SizedBox.expand()),
                  _body(),
                  const StatusBar(),
                  if (widget.session.askDeleteUnkept)
                    KeepConfirmSheet(
                      count: widget.session.unkeptCount,
                      onBack: () => setState(() => widget.session.cancelLeave()),
                      onDelete: () => _commitLeave(leaveAgain),
                    ),
                  if (confirmDeleteAll) _deleteAllSheet(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (overlay == _Overlay.settings) {
      return SettingsScreen(
        session: widget.session,
        storageBytes: widget.storageBytes,
        onChanged: changed,
        onClose: () => setState(() => overlay = _Overlay.none),
        onDeleteAll: () => setState(() => confirmDeleteAll = true),
      );
    }
    if (overlay == _Overlay.howTo) {
      return HowToScreen(onClose: () => setState(() => overlay = _Overlay.none));
    }
    if (overlay == _Overlay.gallery) {
      return GalleryScreen(
        session: widget.session,
        games: _games,
        onClose: () => setState(() => overlay = _Overlay.none),
        onDeleteSnap: (snap) {
          widget.session.deleteSnapRequested(snap.id);
          changed();
        },
        onUndo: () {
          widget.session.undoDelete();
          changed();
        },
        onDeleteGame: (id) async {
          await widget.store?.deleteGame(id);
          setState(() => _games.removeWhere((game) => game.id == id));
        },
      );
    }
    final session = widget.session;
    return switch (session.phase) {
      Phase.home => HomeScreen(
          onPlay: () {
            session.tapPlay();
            changed();
          },
          onHow: () => setState(() => overlay = _Overlay.howTo),
          onGallery: () => setState(() => overlay = _Overlay.gallery),
          onSettings: () => setState(() => overlay = _Overlay.settings),
        ),
      Phase.players => PlayersScreen(
          session: session,
          onChanged: changed,
          onBack: () {
            session.phase = Phase.home;
            changed();
          },
        ),
      Phase.deck => DeckScreen(
          session: session,
          onChanged: changed,
          onSettings: () => setState(() => overlay = _Overlay.settings),
        ),
      Phase.priming => PrimingScreen(
          onContinue: () {
            session.continuePriming();
            changed();
          },
        ),
      Phase.awaitingPermission => const _WaitingForCamera(),
      Phase.cameraOff => CameraOffScreen(
          onSettings: _openSystemSettings,
          onReferee: () {
            session.playReferee();
            changed();
          },
        ),
      Phase.framing || Phase.countdown || Phase.window || Phase.hold || Phase.suddenWindow => PlayScreen(
          session: session,
          onChanged: changed,
          preview: _cameraOn ? widget.feed?.buildPreview() : null,
          showDebugDots: widget.showDebugDots,
        ),
      Phase.snapshot => SnapshotScreen(session: session, onChanged: changed),
      Phase.handoff || Phase.judgeHandoff || Phase.suddenHandoff => HandoffScreen(session: session, onChanged: changed),
      Phase.judgePick || Phase.judgeReveal => JudgeScreen(session: session, onChanged: changed),
      Phase.tie => TieScreen(session: session, onChanged: changed),
      Phase.results => ResultsScreen(
          session: session,
          onChanged: changed,
          onGallery: () => setState(() => overlay = _Overlay.gallery),
          onAgain: () => _leave(again: true),
          onDone: () => _leave(again: false),
        ),
    };
  }

  Widget _deleteAllSheet() {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Sap.paper, borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Delete every snap?', style: uiStyle(20, color: Sap.ink)),
              const SizedBox(height: 12),
              LipButton(
                label: 'Delete all',
                onPressed: () async {
                  await widget.store?.deleteAll();
                  widget.session.snaps.clear();
                  setState(() {
                    confirmDeleteAll = false;
                    _games = [];
                  });
                },
              ),
              const SizedBox(height: 8),
              LipButton(
                label: 'Back',
                filled: false,
                onPressed: () => setState(() => confirmDeleteAll = false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSystemSettings() async {
    const channel = MethodChannel('strikeapose/settings');
    try {
      await channel.invokeMethod<void>('open');
    } on MissingPluginException {
      // This VM and widget tests have no iOS settings URL.
    }
  }
}

class _WaitingForCamera extends StatelessWidget {
  const _WaitingForCamera();

  @override
  Widget build(BuildContext context) {
    return PartyBackground(
      child: Center(child: Text('Waiting for the camera', style: displayStyle(32))),
    );
  }
}
