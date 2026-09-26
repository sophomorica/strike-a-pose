import 'dart:math' as math;

class Vec {
  final double x;
  final double y;

  const Vec(this.x, this.y);

  static const zero = Vec(0, 0);

  Vec operator +(Vec o) => Vec(x + o.x, y + o.y);
  Vec operator -(Vec o) => Vec(x - o.x, y - o.y);
  Vec operator *(double s) => Vec(x * s, y * s);
  Vec operator -() => Vec(-x, -y);

  double dot(Vec o) => x * o.x + y * o.y;

  double get length => math.sqrt(x * x + y * y);

  Vec normalized() {
    final l = length;
    if (l < 1e-6) return Vec.zero;
    return this * (1 / l);
  }
}

double degrees(double radians) => radians * 180 / math.pi;

double radians(double degrees) => degrees * math.pi / 180;

double angleBetween(Vec a, Vec b) {
  final na = a.normalized();
  final nb = b.normalized();
  if (na.length < 0.5 || nb.length < 0.5) return 0;
  final d = na.dot(nb).clamp(-1.0, 1.0);
  return degrees(math.acos(d));
}

double signedAngle(Vec from, Vec to) {
  final a = from.normalized();
  final b = to.normalized();
  return degrees(math.atan2(a.x * b.y - a.y * b.x, a.dot(b)));
}
