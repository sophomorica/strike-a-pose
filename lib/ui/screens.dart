import 'package:flutter/material.dart';

import '../engine/body.dart';
import '../engine/catalog.dart';
import '../engine/fit.dart';
import '../engine/game.dart';
import '../engine/retention.dart';
import '../theme.dart';
import 'chrome.dart';
import 'stage.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onPlay,
    required this.onHow,
    required this.onGallery,
    required this.onSettings,
  });

  final VoidCallback onPlay;
  final VoidCallback onHow;
  final VoidCallback onGallery;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return PartyBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 56, 22, 24),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: onSettings,
                icon: const Icon(Icons.settings, color: Sap.cream),
                tooltip: 'Settings',
              ),
            ),
            const Spacer(),
            const Icon(Icons.accessibility_new, color: Sap.sun, size: 42),
            FittedBox(
              child: Text('STRIKE\nA POSE', textAlign: TextAlign.center, style: displayStyle(84)),
            ),
            const SizedBox(height: 8),
            Text('One phone. Pass it around.', style: bodyStyle(16, color: Sap.cream)),
            const Spacer(),
            LipButton(label: 'Play', onPressed: onPlay),
            const SizedBox(height: 10),
            LipButton(label: 'How to play', onPressed: onHow, filled: false),
            const SizedBox(height: 10),
            LipButton(label: 'Gallery', onPressed: onGallery, filled: false),
          ],
        ),
      ),
    );
  }
}

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({
    super.key,
    required this.session,
    required this.onChanged,
    required this.onBack,
  });

  final GameSession session;
  final VoidCallback onChanged;
  final VoidCallback onBack;

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final onChanged = widget.onChanged;
    return PartyBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 56, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WHO\'S PLAYING?', style: displayStyle(42)),
            Text('Two to eight. Pass the phone in this order.', style: bodyStyle(14)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  for (var i = 0; i < session.players.length; i++)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: avatarColor(session.players[i].color),
                        child: Text(session.players[i].name.characters.first.toUpperCase(), style: uiStyle(16, color: Sap.ink)),
                      ),
                      title: Text(session.players[i].name, style: uiStyle(18)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: i == 0
                                ? null
                                : () {
                                    session.movePlayer(i, i - 1);
                                    onChanged();
                                  },
                            icon: const Icon(Icons.arrow_upward, color: Sap.cream),
                          ),
                          IconButton(
                            onPressed: () {
                              session.removePlayer(session.players[i].id);
                              onChanged();
                            },
                            icon: const Icon(Icons.close, color: Sap.cream),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          textCapitalization: TextCapitalization.words,
                          style: uiStyle(18),
                          decoration: const InputDecoration(
                            hintText: 'Add a name',
                            hintStyle: TextStyle(color: Colors.white54),
                          ),
                          onSubmitted: (value) {
                            session.addPlayer(value);
                            controller.clear();
                            onChanged();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      LipButton(
                        label: 'Add',
                        expand: false,
                        onPressed: () {
                          session.addPlayer(controller.text);
                          controller.clear();
                          onChanged();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            LipButton(
              label: 'Let\'s pick a deck',
              onPressed: session.players.length >= 2
                  ? () {
                      session.donePlayers();
                      onChanged();
                    }
                  : null,
            ),
            TextButton(onPressed: widget.onBack, child: Text('Back', style: bodyStyle(14))),
          ],
        ),
      ),
    );
  }
}

class DeckScreen extends StatelessWidget {
  const DeckScreen({
    super.key,
    required this.session,
    required this.onChanged,
    required this.onSettings,
  });

  final GameSession session;
  final VoidCallback onChanged;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return PartyBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 52, 16, 12),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.accessibility_new, color: Sap.sun),
                const SizedBox(width: 6),
                Flexible(
                  child: Text('STRIKE A POSE', maxLines: 1, overflow: TextOverflow.ellipsis, style: uiStyle(16)),
                ),
                IconButton(
                  onPressed: onSettings,
                  icon: const Icon(Icons.settings, color: Sap.cream),
                  tooltip: 'Settings',
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(child: Text('PICK A DECK', style: displayStyle(48))),
            ),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final player in session.players)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: AvatarChip(name: player.name, colorName: player.color),
                    ),
                  IconButton(
                    onPressed: () {
                      session.phase = Phase.players;
                      onChanged();
                    },
                    icon: const Icon(Icons.add_circle_outline, color: Sap.cream),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.35,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  for (final id in deckOrder) _DeckTile(session: session, id: id, onChanged: onChanged),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _Pill(
                    label: 'Full body',
                    selected: session.settings.body == BodyMode.full,
                    onTap: () {
                      session.setBody(BodyMode.full);
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Pill(
                    label: 'Upper body',
                    selected: session.settings.body == BodyMode.upper,
                    onTap: () {
                      session.setBody(BodyMode.upper);
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RoundButton(
                  icon: Icons.remove,
                  onTap: session.settings.rounds > 1
                      ? () {
                          session.setRounds(session.settings.rounds - 1);
                          onChanged();
                        }
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('${session.settings.rounds} rounds', style: uiStyle(16)),
                ),
                _RoundButton(
                  icon: Icons.add,
                  onTap: session.settings.rounds < 5
                      ? () {
                          session.setRounds(session.settings.rounds + 1);
                          onChanged();
                        }
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            LipButton(
              label: 'Strike a pose!',
              onPressed: session.players.length >= 2 && session.decks.isNotEmpty
                  ? () {
                      session.strikeAPose();
                      onChanged();
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckTile extends StatelessWidget {
  const _DeckTile({required this.session, required this.id, required this.onChanged});
  final GameSession session;
  final DeckId id;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final info = deckInfo(id);
    final enabled = deckEnabled(id, session.settings.body);
    final selected = session.decks.contains(id);
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: Color(info.color),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: enabled
              ? () {
                  session.toggleDeck(id);
                  onChanged();
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.badge, style: bodyStyle(10, color: Sap.ink)),
                const Spacer(),
                Text(info.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: displayStyle(26, color: Sap.ink, height: 1)),
                Text(
                  enabled ? info.pitch : 'Needs full body',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bodyStyle(11, color: Sap.ink),
                ),
                Row(
                  children: [
                    Text('${info.poseCount} POSES', style: bodyStyle(10, color: Sap.ink)),
                    const Spacer(),
                    if (selected) const Icon(Icons.check_circle, color: Sap.ink, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Sap.paper : Sap.indigo,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 44,
          child: Center(child: Text(label, style: uiStyle(15, color: selected ? Sap.ink : Sap.cream))),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onTap,
      icon: Icon(icon),
      style: IconButton.styleFrom(backgroundColor: Sap.indigo, foregroundColor: Sap.cream),
    );
  }
}

class PrimingScreen extends StatelessWidget {
  const PrimingScreen({super.key, required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return PartyBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
        child: Column(
          children: [
            const Spacer(),
            Text('YOUR PHONE\nIS THE MIRROR', textAlign: TextAlign.center, style: displayStyle(52)),
            const SizedBox(height: 16),
            Text(
              'Prop it at about waist height, about three big steps away. The camera scores the pose on this iPhone. Nothing is saved to Photos and nothing is uploaded.',
              textAlign: TextAlign.center,
              style: bodyStyle(16),
            ),
            const Spacer(),
            LipButton(label: 'Continue', onPressed: onContinue),
          ],
        ),
      ),
    );
  }
}

class CameraOffScreen extends StatelessWidget {
  const CameraOffScreen({super.key, required this.onSettings, required this.onReferee});
  final VoidCallback onSettings;
  final VoidCallback onReferee;

  @override
  Widget build(BuildContext context) {
    return PartyBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
        child: Column(
          children: [
            const Spacer(),
            const Icon(Icons.no_photography, color: Sap.sun, size: 64),
            const SizedBox(height: 12),
            Text('CAMERA IS OFF', textAlign: TextAlign.center, style: displayStyle(48)),
            const SizedBox(height: 12),
            Text(
              'Strike a Pose needs the front camera to see the pose. You can open Settings, or play Referee mode with no camera.',
              textAlign: TextAlign.center,
              style: bodyStyle(16),
            ),
            const Spacer(),
            LipButton(label: 'Open Settings', onPressed: onSettings),
            const SizedBox(height: 10),
            LipButton(label: 'Play Referee mode', onPressed: onReferee, filled: false),
          ],
        ),
      ),
    );
  }
}

class PlayScreen extends StatelessWidget {
  const PlayScreen({
    super.key,
    required this.session,
    required this.onChanged,
    this.preview,
    this.showDebugDots = false,
  });

  final GameSession session;
  final VoidCallback onChanged;
  final Widget? preview;
  final bool showDebugDots;

  @override
  Widget build(BuildContext context) {
    final pose = session.currentPose;
    final player = session.currentPlayer;
    final target = pose == null ? neutralFrame() : synthesizePose(pose.angles);
    final live = session.liveFrame;
    final showNeon = session.phase == Phase.window || session.phase == Phase.hold || session.phase == Phase.suddenWindow;
    final fit = session.liveFit;
    return Stack(
      fit: StackFit.expand,
      children: [
        StageBackdrop(
          target: target,
          player: live != null && live.confidentCount >= 4 ? live : target,
          limbs: fit?.limbs.map((key, value) => MapEntry(key, value.status)) ?? const {},
          neon: showNeon,
          greenRim: session.phase == Phase.hold,
          preview: preview,
          showDebugDots: showDebugDots,
          wallShift: session.poseIndex,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 52, 16, 16),
          child: Column(
            children: [
              if (player != null)
                Row(
                  children: [
                    AvatarChip(name: player.name, colorName: player.color, score: player.score),
                    const Spacer(),
                    if (session.phase == Phase.window)
                      Text(_clock(session.secondsLeft), style: uiStyle(16)),
                    if (!session.chromeHidden && session.phase == Phase.window)
                      IconButton(
                        onPressed: () {
                          session.pause();
                          onChanged();
                        },
                        icon: const Icon(Icons.pause_circle_filled, color: Sap.cream, size: 32),
                        tooltip: 'Pause',
                      ),
                  ],
                ),
              if (session.phase == Phase.framing) ...[
                Text('FIND YOUR SPOT', style: displayStyle(36)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _PartChip('Head', session.partHead),
                    _PartChip('Arms', session.partArms),
                    if (session.settings.body == BodyMode.full) _PartChip('Legs', session.partLegs),
                  ],
                ),
              ],
              if (pose != null && session.phase != Phase.framing)
                FittedBox(child: Text(pose.name.toUpperCase(), style: displayStyle(40))),
              if (session.phase == Phase.countdown) _CountdownBadge(session: session),
              if (session.phase == Phase.hold) ...[
                Text('HOLD IT!', style: displayStyle(56, color: Sap.match)),
                if (fit != null)
                  FitMeter(percent: fit.percent, zone: fit.zone, canSee: fit.canSee),
              ],
              const Spacer(),
              if (showNeon && fit != null && !session.chromeHidden)
                FitMeter(percent: fit.percent, zone: fit.zone, canSee: fit.canSee),
              if (showNeon && !session.chromeHidden) _LimbRow(session),
              if (session.phase == Phase.hold) HoldRing(held: session.hold.held),
              if (session.phase == Phase.framing) _FloorCue(green: session.markerGreen, prompt: session.framingPrompt),
              if (session.phase == Phase.countdown)
                _CoachBubble('Copy the shape before the wall hits!'),
              if (fit?.coach != null && session.phase == Phase.window)
                _CoachBubble(fit!.coach!),
              if (session.phase == Phase.window && session.referee)
                LipButton(
                  label: 'Nailed it',
                  onPressed: () {
                    session.nailedIt();
                    onChanged();
                  },
                ),
            ],
          ),
        ),
        if (session.outOfFrame && session.phase != Phase.framing)
          const _StepBack(),
        if (session.userPaused)
          _PauseSheet(session: session, onChanged: onChanged),
      ],
    );
  }
}

String _clock(double seconds) {
  final whole = seconds.ceil().clamp(0, 99);
  return '0:${whole.toString().padLeft(2, '0')}';
}

class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({required this.session});
  final GameSession session;

  @override
  Widget build(BuildContext context) {
    final numeral = session.countdownNumeral;
    final label = session.countdownGo ? 'GO' : '${numeral ?? 3}';
    return Container(
      width: 120,
      height: 120,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Sap.coral, shape: BoxShape.circle),
      child: Text(label, style: displayStyle(72, color: Sap.paper)),
    );
  }
}

class _PartChip extends StatelessWidget {
  const _PartChip(this.label, this.on);
  final String label;
  final bool on;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(on ? Icons.check_circle : Icons.circle_outlined, color: on ? Sap.match : Sap.cream, size: 16),
      label: Text(label, style: uiStyle(13, color: Sap.ink)),
      backgroundColor: Sap.paper,
    );
  }
}

class _LimbRow extends StatelessWidget {
  const _LimbRow(this.session);
  final GameSession session;

  @override
  Widget build(BuildContext context) {
    final fit = session.liveFit;
    if (fit == null) return const SizedBox.shrink();
    final ids = session.settings.body == BodyMode.upper
        ? const [LimbId.lArm, LimbId.rArm]
        : LimbId.values;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 6,
        children: [
          for (final id in ids)
            Chip(
              label: Text(limbChip(id), style: uiStyle(11, color: Sap.ink)),
              backgroundColor: switch (fit.limb(id).status) {
                LimbStatus.green => Sap.match,
                LimbStatus.amber => Sap.close,
                LimbStatus.red => Sap.miss,
                LimbStatus.unknown => Sap.cream,
              },
            ),
        ],
      ),
    );
  }
}

class _FloorCue extends StatelessWidget {
  const _FloorCue({required this.green, required this.prompt});
  final bool green;
  final String prompt;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: green ? Sap.match : Sap.sun,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(green ? 'STAND HERE' : 'STAND HERE', style: uiStyle(16, color: Sap.ink)),
        ),
        const SizedBox(height: 8),
        _CoachBubble(prompt),
      ],
    );
  }
}

class _CoachBubble extends StatelessWidget {
  const _CoachBubble(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Sap.paper, borderRadius: BorderRadius.circular(24)),
      child: Text(text, textAlign: TextAlign.center, style: uiStyle(16, color: Sap.ink)),
    );
  }
}

class _StepBack extends StatelessWidget {
  const _StepBack();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Sap.miss.withValues(alpha: 0.72),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('STEP BACK IN!', textAlign: TextAlign.center, style: displayStyle(52)),
              const SizedBox(height: 8),
              Text('Timer paused', style: uiStyle(18)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PauseSheet extends StatelessWidget {
  const _PauseSheet({required this.session, required this.onChanged});
  final GameSession session;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Sap.indigoDeep, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('PAUSED', style: displayStyle(40)),
              const SizedBox(height: 12),
              LipButton(
                label: 'Resume',
                onPressed: () {
                  session.resume();
                  onChanged();
                },
              ),
              const SizedBox(height: 8),
              LipButton(
                label: 'Skip pose',
                filled: false,
                onPressed: () {
                  session.skipPose();
                  onChanged();
                },
              ),
              const SizedBox(height: 8),
              LipButton(
                label: 'End game',
                filled: false,
                onPressed: () {
                  session.endGame();
                  onChanged();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SnapshotScreen extends StatelessWidget {
  const SnapshotScreen({super.key, required this.session, required this.onChanged});
  final GameSession session;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final snap = session.lastSnap;
    final score = session.lastScore;
    return PartyBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 64, 20, 16),
        child: Column(
          children: [
            if (snap != null)
              Expanded(child: PolaroidCard(snap: snap))
            else
              const Spacer(),
            if (score != null && score.matched) ...[
              _ScoreRow('Fit score · ${score.fitPercent}%', '+${score.fitPoints}'),
              _ScoreRow('Held it 1.0 sec', '+${score.holdBonus}'),
              _ScoreRow('Beat the wall', '+${score.wallBonus}'),
            ],
            if (score != null && !score.matched)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(score.stamp, style: displayStyle(28, color: Sap.miss)),
              ),
            const SizedBox(height: 8),
            LipButton(
              label: 'Next pose',
              onPressed: () {
                session.nextFromSnapshot();
                onChanged();
              },
            ),
            Text(
              'Auto-next · Saved in the app\'s gallery (not Photos)',
              style: bodyStyle(11, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: bodyStyle(15))),
          Text(value, style: uiStyle(18, color: Sap.match)),
        ],
      ),
    );
  }
}

class HandoffScreen extends StatelessWidget {
  const HandoffScreen({super.key, required this.session, required this.onChanged});
  final GameSession session;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final player = session.phase == Phase.judgeHandoff ? session.judge : session.currentPlayer;
    final name = player?.name ?? 'NEXT';
    final judging = session.phase == Phase.judgeHandoff;
    return PartyBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 64, 20, 20),
        child: Column(
          children: [
            Text(
              judging ? 'ROUND ${session.round} OF ${session.settings.rounds} · JUDGE' : 'ROUND ${session.round} OF ${session.settings.rounds}',
              style: bodyStyle(13),
            ),
            const Spacer(),
            const Icon(Icons.smartphone, color: Sap.coral, size: 72),
            const SizedBox(height: 12),
            Text(judging ? 'Pass the phone to the judge' : 'Pass the phone to', style: uiStyle(18)),
            FittedBox(child: Text(name.toUpperCase(), style: displayStyle(72))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white38),
              ),
              child: Text('No peeking — camera\'s paused', style: bodyStyle(13)),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final other in session.players)
                  AvatarChip(
                    name: other.name,
                    colorName: other.color,
                    score: other.score,
                    selected: other.id == player?.id,
                    caption: other.id == player?.id ? '${other.name.toUpperCase()}\nUP NEXT' : null,
                  ),
              ],
            ),
            const Spacer(),
            LipButton(
              label: 'I\'m $name — let\'s go!',
              onPressed: () {
                session.imReady();
                onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class JudgeScreen extends StatelessWidget {
  const JudgeScreen({super.key, required this.session, required this.onChanged});
  final GameSession session;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final judge = session.judge;
    final snaps = session.snapsForRound(session.round, exceptPlayer: judge?.id);
    Snap? selected;
    for (final snap in snaps) {
      if (snap.id == session.selectedSnapId) selected = snap;
    }
    return PartyBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 52, 12, 12),
        child: Column(
          children: [
            Text('ROUND ${session.round} OF ${session.settings.rounds} · JUDGE', style: bodyStyle(12)),
            Text('JUDGE\'S PICK', style: displayStyle(40)),
            Text('${judge?.name ?? 'Judge'}, tap your favorite snap', style: bodyStyle(14)),
            const SizedBox(height: 4),
            Text('Your own snaps are hidden · no self-picks', style: bodyStyle(12, color: Sap.sun)),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: [
                  for (final snap in snaps)
                    PolaroidCard(
                      snap: snap,
                      selected: snap.id == session.selectedSnapId,
                      onTap: () {
                        session.toggleJudgeSelection(snap.id);
                        onChanged();
                      },
                    ),
                ],
              ),
            ),
            LipButton(
              label: selected == null ? 'Pick a snap · +50' : 'Crown ${selected.playerName}\'s ${selected.poseName} · +50',
              onPressed: selected == null
                  ? null
                  : () {
                      session.confirmJudge();
                      onChanged();
                    },
            ),
            Text('${snaps.length} snaps from round ${session.round}', style: bodyStyle(11)),
          ],
        ),
      ),
    );
  }
}

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({
    super.key,
    required this.session,
    required this.onChanged,
    required this.onGallery,
    required this.onAgain,
    required this.onDone,
  });

  final GameSession session;
  final VoidCallback onChanged;
  final VoidCallback onGallery;
  final VoidCallback onAgain;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    if (session.kidsGame) {
      return KidsKeepScreen(session: session, onChanged: onChanged, onAgain: onAgain, onDone: onDone);
    }
    final winner = session.winners.isEmpty
        ? null
        : session.players.cast<Player?>().firstWhere(
              (player) => player!.id == session.winners.first,
              orElse: () => null,
            );
    final hero = winner == null ? null : session.bestSnap(winner.id);
    final shared = session.winners.length > 1;
    return PartyBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 56, 16, 12),
        child: Column(
          children: [
            Text('AND TONIGHT\'S WINNER IS...', style: bodyStyle(12)),
            FittedBox(
              child: Text(
                shared ? 'SHARED CROWN' : '${(winner?.name ?? 'YOU').toUpperCase()} WINS!',
                style: displayStyle(48),
              ),
            ),
            if (hero != null)
              Expanded(
                child: PolaroidCard(
                  snap: hero,
                  ribbon: session.judgePicks.any((pick) => pick.snapId == hero.id),
                ),
              )
            else
              const Spacer(),
            Text('THE GALLERY', style: uiStyle(14)),
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final snap in session.snaps.take(8))
                    SizedBox(
                      width: 88,
                      child: PolaroidCard(
                        snap: snap,
                        ribbon: session.judgePicks.any((pick) => pick.snapId == snap.id),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _RankStrip(session: session),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: LipButton(label: 'Gallery', filled: false, onPressed: onGallery)),
                const SizedBox(width: 8),
                Expanded(child: LipButton(label: 'Play again', onPressed: onAgain)),
              ],
            ),
            Text('Snaps stay inside the app · never saved to Photos', style: bodyStyle(10, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _RankStrip extends StatelessWidget {
  const _RankStrip({required this.session});
  final GameSession session;

  @override
  Widget build(BuildContext context) {
    final rows = session.ranks();
    return Wrap(
      spacing: 6,
      children: [
        for (final row in rows)
          AvatarChip(
            name: session.players.firstWhere((player) => player.id == row.playerId).name,
            colorName: session.players.firstWhere((player) => player.id == row.playerId).color,
            caption: '${row.label} ${row.score}',
          ),
      ],
    );
  }
}

class TieScreen extends StatelessWidget {
  const TieScreen({super.key, required this.session, required this.onChanged});
  final GameSession session;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final tied = session.players.where((player) => session.tiedIds.contains(player.id)).toList();
    return PartyBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
        child: Column(
          children: [
            Text('FINAL SCORES ARE IN...', style: bodyStyle(12)),
            Text('DEAD HEAT!', style: displayStyle(56)),
            Expanded(
              child: Row(
                children: [
                  for (final player in tied.take(2))
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: session.bestSnap(player.id) == null
                            ? Text(player.name, style: uiStyle(18))
                            : PolaroidCard(snap: session.bestSnap(player.id)!),
                      ),
                    ),
                ],
              ),
            ),
            Text('${tied.map((player) => player.name).join(' & ')} are tied on points', style: bodyStyle(14)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Sap.paper, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SUDDEN DEATH', style: displayStyle(28, color: Sap.ink)),
                  Text('One pose · same for both · highest fit % in 7 s', style: bodyStyle(13, color: Sap.ink)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: LipButton(
                    label: 'Share the crown',
                    filled: false,
                    onPressed: () {
                      session.shareCrown();
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LipButton(
                    label: 'Sudden death!',
                    onPressed: session.referee
                        ? null
                        : () {
                            session.suddenDeath();
                            onChanged();
                          },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class KidsKeepScreen extends StatelessWidget {
  const KidsKeepScreen({
    super.key,
    required this.session,
    required this.onChanged,
    required this.onAgain,
    required this.onDone,
  });

  final GameSession session;
  final VoidCallback onChanged;
  final VoidCallback onAgain;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final kept = session.snaps.where((snap) => session.kept.contains(snap.id)).length;
    return PartyBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 52, 12, 12),
        child: Column(
          children: [
            Text('KIDS DECK GAME · THE GALLERY', style: bodyStyle(11)),
            Text('KEEP YOUR FAVES', style: displayStyle(36)),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Sap.sun, borderRadius: BorderRadius.circular(14)),
              child: Text(
                'Tap ♥ to keep a snap. Snaps without a ♥ are deleted when this game ends.',
                style: bodyStyle(13, color: Sap.ink),
              ),
            ),
            Row(
              children: [
                Text('♥ $kept kept of ${session.snaps.length}', style: uiStyle(13)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    session.keepAll();
                    onChanged();
                  },
                  child: Text('Keep all', style: uiStyle(14, color: Sap.sun)),
                ),
              ],
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: [
                  for (final snap in session.snaps)
                    PolaroidCard(
                      snap: snap,
                      heart: session.kept.contains(snap.id),
                      onTap: () {
                        session.toggleKeep(snap.id);
                        onChanged();
                      },
                    ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(child: LipButton(label: 'Play again', filled: false, onPressed: onAgain)),
                const SizedBox(width: 8),
                Expanded(child: LipButton(label: 'Done', onPressed: onDone)),
              ],
            ),
            Text('Kept snaps stay in the app\'s gallery · never saved to Photos', style: bodyStyle(10)),
          ],
        ),
      ),
    );
  }
}

class KeepConfirmSheet extends StatelessWidget {
  const KeepConfirmSheet({super.key, required this.count, required this.onBack, required this.onDelete});
  final int count;
  final VoidCallback onBack;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
              Text('Delete $count unkept snaps?', style: uiStyle(20, color: Sap.ink)),
              const SizedBox(height: 12),
              LipButton(label: 'Back to keep', onPressed: onBack),
              const SizedBox(height: 8),
              LipButton(label: 'Delete and continue', filled: false, onPressed: onDelete),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.session,
    required this.onChanged,
    required this.onClose,
    required this.onDeleteAll,
    required this.storageBytes,
  });

  final GameSession session;
  final VoidCallback onChanged;
  final VoidCallback onClose;
  final VoidCallback onDeleteAll;
  final int storageBytes;

  @override
  Widget build(BuildContext context) {
    final settings = session.settings;
    return PartyBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 52, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(child: FittedBox(child: Text('SETTINGS', style: displayStyle(40)))),
                IconButton(onPressed: onClose, icon: const Icon(Icons.close, color: Sap.cream)),
              ],
            ),
            Expanded(
              child: ListView(
                children: [
                  Text('Rounds  ${settings.rounds}', style: uiStyle(16)),
                  Slider(
                    value: settings.rounds.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: '${settings.rounds}',
                    onChanged: (value) {
                      session.setRounds(value.round());
                      onChanged();
                    },
                  ),
                  Text('Poses per turn', style: uiStyle(16)),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final count in const [3, 5, 8])
                        ChoiceChip(
                          label: Text('$count'),
                          selected: settings.posesPerTurn == count,
                          onSelected: (_) {
                            session.setPosesPerTurn(count);
                            onChanged();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Window', style: uiStyle(16)),
                  Wrap(
                    spacing: 8,
                    children: [
                      _WindowChip(session, 10, 'Chill 10', onChanged),
                      _WindowChip(session, 7, 'Normal 7', onChanged),
                      _WindowChip(session, 5, 'Spicy 5', onChanged),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Full body', style: uiStyle(16)),
                    subtitle: Text(
                      settings.body == BodyMode.upper ? 'Upper body is on' : 'Upper body is off',
                      style: bodyStyle(12),
                    ),
                    value: settings.body == BodyMode.full,
                    onChanged: (full) {
                      session.setBody(full ? BodyMode.full : BodyMode.upper);
                      onChanged();
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Judge\'s pick', style: uiStyle(16)),
                    value: settings.judgeOn,
                    onChanged: (value) {
                      settings.judgeOn = value;
                      onChanged();
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Sound', style: uiStyle(16)),
                    value: settings.sound,
                    onChanged: (value) {
                      settings.sound = value;
                      onChanged();
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Haptics', style: uiStyle(16)),
                    value: settings.haptics,
                    onChanged: (value) {
                      settings.haptics = value;
                      onChanged();
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Reduce motion', style: uiStyle(16)),
                    value: settings.reduceMotion,
                    onChanged: (value) {
                      settings.reduceMotion = value;
                      onChanged();
                    },
                  ),
                  if (storageNotice(storageBytes))
                    Text(
                      'Snaps are over 500 MB. Delete a game to free space.',
                      style: bodyStyle(14, color: Sap.sun),
                    ),
                  const SizedBox(height: 8),
                  LipButton(label: 'Delete all', filled: false, onPressed: onDeleteAll),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WindowChip extends StatelessWidget {
  const _WindowChip(this.session, this.seconds, this.label, this.onChanged);
  final GameSession session;
  final int seconds;
  final String label;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: session.settings.windowSeconds == seconds,
      onSelected: (_) {
        session.setWindow(seconds);
        onChanged();
      },
    );
  }
}

class HowToScreen extends StatelessWidget {
  const HowToScreen({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return PartyBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 56, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HOW TO PLAY', style: displayStyle(42)),
            const SizedBox(height: 12),
            const _HowCard('1', 'Pass one iPhone', 'Everybody plays on this phone. There is no second device and no account.'),
            const _HowCard('2', 'Copy the hole', 'Match the shape in the foam wall before the timer runs out.'),
            const _HowCard('3', 'Hold for one second', 'Stay in the pose for 1.0 s. The phone keeps the snap in the app.'),
            const Spacer(),
            LipButton(label: 'Got it', onPressed: onClose),
          ],
        ),
      ),
    );
  }
}

class _HowCard extends StatelessWidget {
  const _HowCard(this.step, this.title, this.body);
  final String step;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Sap.indigo, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(step, style: displayStyle(22, color: Sap.sun)),
          Text(title, style: uiStyle(18)),
          Text(body, style: bodyStyle(14)),
        ],
      ),
    );
  }
}

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({
    super.key,
    required this.session,
    required this.games,
    required this.onClose,
    required this.onDeleteSnap,
    required this.onUndo,
    required this.onDeleteGame,
  });

  final GameSession session;
  final List<GameRecord> games;
  final VoidCallback onClose;
  final void Function(Snap snap) onDeleteSnap;
  final VoidCallback onUndo;
  final void Function(String gameId) onDeleteGame;

  @override
  Widget build(BuildContext context) {
    return PartyBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 52, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('GALLERY', style: displayStyle(40)),
                const Spacer(),
                IconButton(onPressed: onClose, icon: const Icon(Icons.close, color: Sap.cream)),
              ],
            ),
            if (session.undoSnapId != null)
              Row(
                children: [
                  const Expanded(child: Text('Snap deleted')),
                  TextButton(onPressed: onUndo, child: const Text('Undo')),
                ],
              ),
            Expanded(
              child: ListView(
                children: [
                  if (session.snaps.isNotEmpty) Text('This game', style: uiStyle(16)),
                  for (final snap in session.snaps)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${snap.playerName} · ${snap.poseName}', style: uiStyle(16)),
                      subtitle: Text(snap.matched ? '+${snap.points}' : snap.stamp, style: bodyStyle(12)),
                      trailing: session.kidsGame
                          ? Icon(
                              session.kept.contains(snap.id) ? Icons.favorite : Icons.favorite_border,
                              color: Sap.miss,
                            )
                          : IconButton(
                              onPressed: () => onDeleteSnap(snap),
                              icon: const Icon(Icons.delete_outline, color: Sap.cream),
                            ),
                    ),
                  for (final game in games)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(game.id, style: uiStyle(16)),
                      subtitle: Text('${game.snaps.length} snaps', style: bodyStyle(12)),
                      trailing: IconButton(
                        onPressed: () => onDeleteGame(game.id),
                        icon: const Icon(Icons.delete_outline, color: Sap.cream),
                      ),
                    ),
                  if (session.snaps.isEmpty && games.isEmpty)
                    Text('No snaps yet. Play a round and they stay in the app.', style: bodyStyle(16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
