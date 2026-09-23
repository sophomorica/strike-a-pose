import 'package:flutter/material.dart';

import 'match_screen.dart';
import 'pose_catalog.dart';

const _background = Color(0xFF141210);
const _ink = Color(0xFFF4EFE6);
const _strike = Color(0xFFE23D28);
const _strikeInk = Color(0xFF141210);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _routeOpen = false;

  Future<void> _practice() async {
    if (_routeOpen) {
      return;
    }
    _routeOpen = true;
    try {
      final plan = practiceRound(DateTime.now().microsecondsSinceEpoch);
      await Navigator.push<void>(
        context,
        PageRouteBuilder<void>(
          pageBuilder: (context, animation, secondaryAnimation) {
            return MatchScreen(plan: plan);
          },
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _routeOpen = false;
        });
      } else {
        _routeOpen = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Text(
                'Narrow Road Studios',
                textAlign: TextAlign.center,
                style: TextStyle(color: _ink, fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                'Strike a Pose',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _ink,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Five silhouettes. Six seconds each. Strike while the pose is still up.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _ink, fontSize: 18, height: 1.4),
              ),
              const SizedBox(height: 12),
              const Text(
                'This practice round uses a stand-in camera.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _ink, fontSize: 16, height: 1.4),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _practice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _strike,
                  foregroundColor: _strikeInk,
                  minimumSize: const Size.fromHeight(56),
                  elevation: 0,
                ),
                child: const Text('Practice'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
