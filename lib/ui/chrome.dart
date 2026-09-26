import 'package:flutter/material.dart';

import '../engine/body.dart';
import '../engine/catalog.dart';
import '../engine/game.dart';
import '../theme.dart';
import 'stage.dart';

class PartyBackground extends StatelessWidget {
  const PartyBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.15,
          colors: [Sap.plum, Sap.indigoDeep, Sap.indigoNight],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(top: -40, left: -30, child: _Corner(color: Sap.coral)),
          const Positioned(bottom: -50, right: -40, child: _Corner(color: Sap.coral)),
          child,
        ],
      ),
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.4,
      child: Container(width: 120, height: 120, color: color),
    );
  }
}

class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 48,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 22),
        child: Row(
          children: [
            Text('9:41', style: TextStyle(fontFamily: Sap.body, fontWeight: FontWeight.w800, fontSize: 15, color: Sap.cream)),
            Spacer(),
            Icon(Icons.signal_cellular_alt, size: 16, color: Sap.cream),
            SizedBox(width: 4),
            Icon(Icons.wifi, size: 16, color: Sap.cream),
            SizedBox(width: 4),
            Icon(Icons.battery_full, size: 18, color: Sap.cream),
          ],
        ),
      ),
    );
  }
}

class LipButton extends StatelessWidget {
  const LipButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      height: 56,
      width: expand ? double.infinity : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: onPressed == null
              ? Sap.coral.withValues(alpha: 0.45)
              : (filled ? Sap.coral : Colors.transparent),
          borderRadius: BorderRadius.circular(28),
          border: filled ? null : Border.all(color: Sap.cream, width: 2),
          boxShadow: onPressed == null || !filled
              ? null
              : const [BoxShadow(color: Sap.coralDeep, offset: Offset(0, 4))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(28),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: uiStyle(20, color: filled ? Sap.paper : Sap.cream),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return button;
  }
}

class AvatarChip extends StatelessWidget {
  const AvatarChip({
    super.key,
    required this.name,
    required this.colorName,
    this.score,
    this.selected = false,
    this.caption,
  });

  final String name;
  final String colorName;
  final int? score;
  final bool selected;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final color = avatarColor(colorName);
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? Sap.paper : Sap.indigo.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? color : Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: color,
            child: Text(initial, style: uiStyle(12, color: Sap.ink)),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              caption ?? name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: uiStyle(12, color: selected ? Sap.ink : Sap.cream),
            ),
          ),
          if (score != null) ...[
            const SizedBox(width: 4),
            Text('★ $score', style: bodyStyle(11, color: selected ? Sap.ink : Sap.sun)),
          ],
        ],
      ),
    );
  }
}

class PolaroidCard extends StatelessWidget {
  const PolaroidCard({
    super.key,
    required this.snap,
    this.ribbon = false,
    this.selected = false,
    this.heart,
    this.onTap,
  });

  final Snap snap;
  final bool ribbon;
  final bool selected;
  final bool? heart;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Sap.paper,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? Sap.coral : Colors.transparent, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      StageBackdrop(
                        target: synthesizePose(poseAnglesFor(snap.poseId)),
                        wallShift: snap.seq,
                      ),
                      if (!snap.matched)
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            color: Sap.miss,
                            child: Text(
                              snap.stamp,
                              style: uiStyle(8, color: Sap.paper),
                            ),
                          ),
                        ),
                      if (ribbon)
                        const Positioned(
                          top: 4,
                          left: 4,
                          child: Text('★ JUDGE\'S PICK +50', style: TextStyle(fontFamily: Sap.ui, fontSize: 8, color: Sap.sun, fontWeight: FontWeight.w800)),
                        ),
                      if (heart != null)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Icon(
                            heart! ? Icons.favorite : Icons.favorite_border,
                            color: Sap.miss,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${snap.playerName.toUpperCase()} · ${snap.poseName.toUpperCase()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: Sap.marker, fontSize: 11, color: Sap.ink),
              ),
              Text(
                snap.matched ? '+${snap.points}  ${snap.fitPercent}% FIT' : '0',
                style: bodyStyle(10, color: Sap.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

PoseAngles poseAnglesFor(String poseId) {
  for (final pose in launchPoses) {
    if (pose.id == poseId) return pose.angles;
  }
  return const PoseAngles(
    lSh: 0,
    rSh: 0,
    lEl: 180,
    rEl: 180,
    lHip: 0,
    rHip: 0,
    lKn: 180,
    rKn: 180,
  );
}
