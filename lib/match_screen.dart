import 'dart:async';

import 'package:flutter/material.dart';

import 'fake_pose.dart';
import 'pose.dart';
import 'round.dart';
import 'silhouette_painter.dart';

const _background = Color(0xFF141210);
const _ink = Color(0xFFF4EFE6);
const _strike = Color(0xFFE23D28);
const _strikeInk = Color(0xFF141210);
const _hit = Color(0xFF1F8A4C);
const _miss = Color(0xFFE26D5A);

class MatchScreen extends StatefulWidget {
  final RoundPlan plan;
  final Duration Function()? elapsed;

  const MatchScreen({super.key, required this.plan, this.elapsed});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  late RoundState _round;
  Stopwatch? _stopwatch;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _round = beginRound(widget.plan);
    if (widget.elapsed == null) {
      _stopwatch = Stopwatch()..start();
    }
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _onClock();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration _now() {
    final elapsed = widget.elapsed;
    if (elapsed != null) {
      return elapsed();
    }
    return _stopwatch!.elapsed;
  }

  void _onClock() {
    if (!mounted) {
      return;
    }
    final at = _now();
    setState(() {
      _round = reduceRound(_round, ClockTicked(at));
    });
    if (_round is RoundOver) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _onStrike() {
    final current = _round;
    if (current is! PoseOpen) {
      return;
    }
    final at = _now();
    final reading = fakePoseReading(current.target);
    final index = current.index;
    setState(() {
      _round = reduceRound(
        _round,
        StrikeSubmitted(poseIndex: index, at: at, reading: reading),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = _round;
    final background = switch (state) {
      PoseHitFlash() => _hit,
      _ => _background,
    };
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: switch (state) {
            PoseOpen() => _open(state),
            PoseHitFlash() => _hitFlash(state),
            PoseMissed() => _missed(state),
            RoundOver() => _over(state),
          },
        ),
      ),
    );
  }

  Widget _open(PoseOpen state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _leaveRound(),
        Text(
          state.target.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ink,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Score ${state.score}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _ink, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text(
          _countdown(state),
          textAlign: TextAlign.center,
          style: const TextStyle(color: _ink, fontSize: 18),
        ),
        Expanded(child: _silhouette(state.target.skeleton)),
        ElevatedButton(
          onPressed: _onStrike,
          style: ElevatedButton.styleFrom(
            backgroundColor: _strike,
            foregroundColor: _strikeInk,
            minimumSize: const Size.fromHeight(56),
            elevation: 0,
          ),
          child: const Text('Strike'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _hitFlash(PoseHitFlash state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _leaveRound(),
        Text(
          state.target.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ink,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Score ${state.score}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _ink, fontSize: 18),
        ),
        Expanded(child: _silhouette(state.target.skeleton)),
      ],
    );
  }

  Widget _missed(PoseMissed state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _leaveRound(),
        Text(
          'Score ${state.score}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _ink, fontSize: 18),
        ),
        const Spacer(),
        const Text(
          'Miss',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _miss,
            fontSize: 48,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _over(RoundOver state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Text(
          '${state.score} of ${state.total}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ink,
            fontSize: 40,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: _strike,
            foregroundColor: _strikeInk,
            minimumSize: const Size.fromHeight(56),
            elevation: 0,
          ),
          child: const Text('Leave'),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _leaveRound() {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        tooltip: 'Leave round',
        color: _ink,
        icon: const Icon(Icons.close),
      ),
    );
  }

  Widget _silhouette(PoseSkeleton skeleton) {
    return CustomPaint(
      painter: SilhouettePainter(skeleton),
      child: const SizedBox.expand(),
    );
  }

  String _countdown(PoseOpen state) {
    final remaining = state.deadline - state.observedAt;
    final microseconds = remaining < Duration.zero
        ? 0
        : remaining.inMicroseconds;
    final seconds = microseconds / Duration.microsecondsPerSecond;
    return '${seconds.toStringAsFixed(1)}s';
  }
}
