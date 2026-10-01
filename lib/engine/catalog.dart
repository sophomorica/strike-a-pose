import 'body.dart';
import 'fit.dart';

enum DeckId { classics, silly, sports, animals, kids, hard }

class DeckInfo {
  final DeckId id;
  final String name;
  final String pitch;
  final String badge;
  final int color;
  final Tolerance tolerance;
  final int multiplier;
  final int poseCount;

  const DeckInfo({
    required this.id,
    required this.name,
    required this.pitch,
    required this.badge,
    required this.color,
    required this.tolerance,
    required this.multiplier,
    required this.poseCount,
  });
}

class PoseDef {
  final String id;
  final String name;
  final DeckId deck;
  final int difficulty;
  final bool upperOk;
  final PoseAngles angles;
  final Tolerance tolerance;
  final int pointsMultiplier;

  const PoseDef({
    required this.id,
    required this.name,
    required this.deck,
    required this.difficulty,
    required this.upperOk,
    required this.angles,
    required this.tolerance,
    required this.pointsMultiplier,
  });
}

const deckOrder = [
  DeckId.classics,
  DeckId.silly,
  DeckId.sports,
  DeckId.animals,
  DeckId.kids,
  DeckId.hard,
];

DeckInfo deckInfo(DeckId id) {
  return switch (id) {
    DeckId.classics => const DeckInfo(
        id: DeckId.classics,
        name: 'CLASSICS',
        pitch: 'The greatest hits',
        badge: 'FULL BODY',
        color: 0xFFE85D4C,
        tolerance: Tolerance.normal,
        multiplier: 1,
        poseCount: 8,
      ),
    DeckId.silly => const DeckInfo(
        id: DeckId.silly,
        name: 'SILLY',
        pitch: 'Teapots & robots',
        badge: 'UPPER OK',
        color: 0xFFFFC845,
        tolerance: Tolerance.normal,
        multiplier: 1,
        poseCount: 8,
      ),
    DeckId.sports => const DeckInfo(
        id: DeckId.sports,
        name: 'SPORTS',
        pitch: 'Game-day moves',
        badge: 'FULL BODY',
        color: 0xFF4FB7F0,
        tolerance: Tolerance.normal,
        multiplier: 1,
        poseCount: 6,
      ),
    DeckId.animals => const DeckInfo(
        id: DeckId.animals,
        name: 'ANIMALS',
        pitch: 'Bears, crabs, cranes',
        badge: 'FULL BODY',
        color: 0xFF2EC4B6,
        tolerance: Tolerance.normal,
        multiplier: 1,
        poseCount: 6,
      ),
    DeckId.kids => const DeckInfo(
        id: DeckId.kids,
        name: 'KIDS',
        pitch: 'Little legs welcome',
        badge: 'UPPER OK',
        color: 0xFFF7A8C8,
        tolerance: Tolerance.kids,
        multiplier: 1,
        poseCount: 10,
      ),
    DeckId.hard => const DeckInfo(
        id: DeckId.hard,
        name: 'HARD MODE',
        pitch: 'Wobbly · double points',
        badge: 'FULL BODY',
        color: 0xFF170F2E,
        tolerance: Tolerance.hard,
        multiplier: 2,
        poseCount: 6,
      ),
  };
}

PoseAngles _a(
  double lSh,
  double rSh,
  double lEl,
  double rEl,
  double lHip,
  double rHip,
  double lKn,
  double rKn, {
  double lean = 0,
  Bend? lElBend,
  Bend? rElBend,
  Bend? lKnBend,
  Bend? rKnBend,
}) {
  return PoseAngles(
    lSh: lSh,
    rSh: rSh,
    lEl: lEl,
    rEl: rEl,
    lHip: lHip,
    rHip: rHip,
    lKn: lKn,
    rKn: rKn,
    lean: lean,
    lElBend: lElBend,
    rElBend: rElBend,
    lKnBend: lKnBend,
    rKnBend: rKnBend,
  );
}

PoseDef _pose(
  String id,
  String name,
  DeckId deck,
  int difficulty,
  bool upperOk,
  PoseAngles angles,
) {
  final info = deckInfo(deck);
  return PoseDef(
    id: id,
    name: name,
    deck: deck,
    difficulty: difficulty,
    upperOk: upperOk,
    angles: angles,
    tolerance: info.tolerance,
    pointsMultiplier: info.multiplier,
  );
}

final List<PoseDef> launchPoses = List.unmodifiable([
  _pose('star_jump', 'Star Jump', DeckId.classics, 1, true, _a(135, 135, 180, 180, 25, 25, 180, 180)),
  _pose('t_pose', 'T-Pose', DeckId.classics, 1, true, _a(90, 90, 180, 180, 5, 5, 180, 180)),
  _pose('victory_v', 'Victory V', DeckId.classics, 1, true, _a(155, 155, 180, 180, 8, 8, 180, 180)),
  _pose('double_flex', 'Double Flex', DeckId.classics, 1, true, _a(90, 90, 70, 70, 10, 10, 175, 175, lElBend: Bend.up, rElBend: Bend.up)),
  _pose('goal', 'Goal!', DeckId.classics, 1, true, _a(90, 90, 90, 90, 10, 10, 180, 180, lElBend: Bend.up, rElBend: Bend.up)),
  _pose('point_sky', 'Point to the Sky', DeckId.classics, 1, true, _a(20, 170, 170, 180, 8, 8, 180, 180)),
  _pose('tree', 'Tree', DeckId.classics, 2, false, _a(170, 170, 140, 140, 0, 50, 180, 60, lElBend: Bend.up, rElBend: Bend.up, rKnBend: Bend.inward)),
  _pose('airplane', 'Airplane', DeckId.classics, 2, false, _a(90, 90, 180, 180, 0, 30, 180, 180, lean: 20)),
  _pose('teapot', "I'm a Little Teapot", DeckId.silly, 1, true, _a(40, 120, 70, 150, 10, 10, 180, 180, lean: 20, lElBend: Bend.inward)),
  _pose('flamingo', 'Flamingo', DeckId.silly, 2, false, _a(100, 100, 150, 150, 0, 80, 180, 60)),
  _pose('robot', 'Robot', DeckId.silly, 1, true, _a(90, 90, 90, 90, 10, 10, 180, 180, lElBend: Bend.up, rElBend: Bend.down)),
  _pose('disco', 'Disco Point', DeckId.silly, 1, false, _a(35, 150, 70, 180, 5, 20, 180, 170, lean: -8, lElBend: Bend.inward)),
  _pose('chicken', 'The Chicken', DeckId.silly, 1, false, _a(45, 45, 30, 30, 15, 15, 150, 150, lElBend: Bend.inward, rElBend: Bend.inward)),
  _pose('scarecrow', 'Scarecrow', DeckId.silly, 1, true, _a(90, 90, 90, 90, 10, 10, 180, 180, lean: 10, lElBend: Bend.down, rElBend: Bend.down)),
  _pose('pencil', 'Pencil Dive', DeckId.silly, 1, true, _a(180, 180, 170, 170, 0, 0, 180, 180)),
  _pose('surfer', 'Surfer', DeckId.silly, 2, false, _a(80, 100, 170, 170, 30, 30, 130, 130, lean: 15)),
  _pose('free_throw', 'Free Throw', DeckId.sports, 1, true, _a(150, 160, 90, 110, 5, 5, 150, 150, lElBend: Bend.up, rElBend: Bend.up)),
  _pose('goalie', 'Goalie Save', DeckId.sports, 1, false, _a(150, 150, 170, 170, 40, 40, 140, 140)),
  _pose('archer', 'Archer', DeckId.sports, 1, true, _a(90, 90, 180, 30, 25, 25, 180, 180, rElBend: Bend.inward)),
  _pose('weightlifter', 'Weightlifter', DeckId.sports, 1, true, _a(170, 170, 150, 150, 25, 25, 170, 170)),
  _pose('tennis', 'Tennis Trophy', DeckId.sports, 2, true, _a(170, 100, 170, 70, 10, 10, 170, 150, rElBend: Bend.up)),
  _pose('touchdown', 'Touchdown Spike', DeckId.sports, 2, false, _a(20, 170, 180, 180, 60, 5, 90, 180, lKnBend: Bend.up)),
  _pose('bear', 'Bear Roar', DeckId.animals, 1, false, _a(110, 110, 90, 90, 25, 25, 140, 140, lElBend: Bend.up, rElBend: Bend.up)),
  _pose('crab', 'Crab Stance', DeckId.animals, 2, false, _a(90, 90, 90, 90, 50, 50, 100, 100, lElBend: Bend.up, rElBend: Bend.up)),
  _pose('penguin', 'Penguin', DeckId.animals, 1, true, _a(15, 15, 180, 180, 0, 0, 180, 180)),
  _pose('monkey', 'Monkey', DeckId.animals, 1, false, _a(170, 45, 50, 60, 20, 20, 140, 140, lElBend: Bend.up, rElBend: Bend.inward)),
  _pose('eagle', 'Eagle', DeckId.animals, 1, true, _a(100, 100, 160, 160, 10, 10, 180, 180)),
  _pose('kangaroo', 'Kangaroo', DeckId.animals, 1, false, _a(40, 40, 60, 60, 15, 15, 140, 140, lElBend: Bend.up, rElBend: Bend.up)),
  _pose('one_leg_star', 'One-Leg Star', DeckId.hard, 3, false, _a(135, 135, 180, 180, 0, 60, 180, 180, lean: 10)),
  _pose('lightning', 'Lightning Bolt', DeckId.hard, 3, false, _a(150, 40, 180, 170, 30, -10, 150, 150, lean: 15)),
  _pose('starfish_tilt', 'Starfish Tilt', DeckId.hard, 3, false, _a(170, 30, 180, 180, 0, 45, 180, 180, lean: 30)),
  _pose('asym_robot', 'Asymmetric Robot', DeckId.hard, 3, false, _a(90, 150, 90, 90, 20, 40, 180, 120, lean: -10, lElBend: Bend.down, rElBend: Bend.up)),
  _pose('warrior', 'Warrior Reach', DeckId.hard, 3, false, _a(150, 30, 180, 180, 40, 20, 110, 180, lean: -15)),
  _pose('crane_twist', 'Crane Twist', DeckId.hard, 3, false, _a(170, 60, 180, 90, 0, 70, 180, 60, rElBend: Bend.down)),
  _pose('kids_starfish', 'Starfish', DeckId.kids, 1, false, _a(135, 135, 180, 180, 20, 20, 180, 180)),
  _pose('kids_tall_tree', 'Tall Tree', DeckId.kids, 1, true, _a(170, 170, 160, 160, 5, 5, 180, 180)),
  _pose('kids_fly', 'Superhero Fly', DeckId.kids, 1, true, _a(30, 170, 90, 180, 10, 10, 180, 180, lElBend: Bend.inward)),
  _pose('kids_robot', 'Robot', DeckId.kids, 1, true, _a(90, 90, 90, 90, 10, 10, 180, 180, lElBend: Bend.up, rElBend: Bend.down)),
  _pose('kids_teapot', 'Teapot', DeckId.kids, 1, true, _a(40, 120, 70, 150, 10, 10, 180, 180, lean: 20, lElBend: Bend.inward)),
  _pose('kids_bunny', 'Bunny Ears', DeckId.kids, 1, true, _a(170, 170, 40, 40, 5, 5, 180, 180, lElBend: Bend.up, rElBend: Bend.up)),
  _pose('kids_y', 'Letter Y', DeckId.kids, 1, true, _a(150, 150, 180, 180, 5, 5, 180, 180)),
  _pose('kids_airplane', 'Airplane', DeckId.kids, 1, true, _a(90, 90, 180, 180, 5, 5, 180, 180, lean: 15)),
  _pose('kids_frog', 'Frog', DeckId.kids, 2, false, _a(30, 30, 150, 150, 60, 60, 70, 70)),
  _pose('kids_penguin', 'Penguin', DeckId.kids, 1, true, _a(15, 15, 180, 180, 0, 0, 180, 180)),
]);

List<PoseDef> posesIn(DeckId deck) =>
    launchPoses.where((pose) => pose.deck == deck).toList();

PoseDef poseById(String id) => launchPoses.firstWhere((pose) => pose.id == id);

bool deckEnabled(DeckId deck, BodyMode mode) {
  if (mode == BodyMode.upper && deck == DeckId.hard) return false;
  return true;
}

List<PoseDef> poolFor({
  required Set<DeckId> decks,
  required BodyMode mode,
}) {
  return launchPoses.where((pose) {
    if (!decks.contains(pose.deck)) return false;
    if (mode == BodyMode.upper && !pose.upperOk) return false;
    return true;
  }).toList();
}

/// Poses 1–2 easy, 3–4 medium, and the last of a 5+ turn is a wildcard.
/// The deck reshuffles only after every pose in the pool has been used.
List<PoseDef> dealTurn({
  required List<PoseDef> pool,
  required Set<String> used,
  required int count,
  required int Function(int max) nextInt,
}) {
  if (pool.isEmpty || count <= 0) return const [];

  List<PoseDef> options(bool Function(PoseDef pose) pred) {
    final fresh = pool.where((pose) => pred(pose) && !used.contains(pose.id)).toList();
    if (fresh.isNotEmpty) return fresh;
    final any = pool.where(pred).toList();
    if (any.isNotEmpty) return any;
    return pool;
  }

  final dealt = <PoseDef>[];
  for (var i = 0; i < count; i++) {
    final choices = i <= 1
        ? options((pose) => pose.difficulty == 1)
        : i <= 3
            ? options((pose) => pose.difficulty == 2)
            : options((pose) => true);
    final pick = choices[nextInt(choices.length)];
    used.add(pick.id);
    dealt.add(pick);
    if (used.length >= pool.length) {
      final kept = dealt.map((pose) => pose.id).toSet();
      used
        ..clear()
        ..addAll(kept);
    }
  }
  return dealt;
}

List<PoseDef> suddenDeathPool({
  required bool kidsGame,
  required BodyMode mode,
}) {
  if (kidsGame && mode == BodyMode.upper) {
    return posesIn(DeckId.kids).where((pose) => pose.upperOk).toList();
  }
  if (kidsGame) return posesIn(DeckId.kids);
  if (mode == BodyMode.upper) {
    return launchPoses
        .where((pose) => pose.deck != DeckId.kids && pose.deck != DeckId.hard && pose.upperOk)
        .toList();
  }
  return posesIn(DeckId.hard);
}

Tolerance suddenDeathTolerance({
  required bool kidsGame,
  required BodyMode mode,
}) {
  if (kidsGame) return Tolerance.kids;
  return Tolerance.hard;
}
