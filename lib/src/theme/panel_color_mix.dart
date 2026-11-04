import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Colour mixing the way PanelUI's web package writes it.
extension PanelColorMix on Color {
  /// CSS's `color-mix(in oklab, this, other amount)`: [other] mixed into this
  /// colour by [amount], in Oklab with premultiplied alpha. PanelUI's web
  /// package writes its hover borders and fills this way. A plain RGB lerp of
  /// a translucent token comes out darker.
  Color mixOklab(Color other, double amount) => _mixOklab(this, other, amount);
}

Color _mixOklab(Color a, Color b, double t) {
  final alpha = a.a * (1 - t) + b.a * t;
  if (alpha <= 0) return const Color(0x00000000);
  // Premultiplied: each colour counts for as much as it is opaque.
  final wa = a.a * (1 - t) / alpha;
  final wb = b.a * t / alpha;
  final (l1, a1, b1) = _toOklab(a);
  final (l2, a2, b2) = _toOklab(b);
  return _fromOklab(
    l1 * wa + l2 * wb,
    a1 * wa + a2 * wb,
    b1 * wa + b2 * wb,
    alpha,
  );
}

/// [color] in Oklab, after Björn Ottosson's reference conversion.
(double, double, double) _toOklab(Color color) {
  double linear(double c) =>
      c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  double cbrt(double x) => math.pow(x, 1 / 3).toDouble();
  final r = linear(color.r);
  final g = linear(color.g);
  final b = linear(color.b);
  final l = cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
  final m = cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
  final s = cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
  return (
    0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
    1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
    0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
  );
}

/// The sRGB colour at Oklab ([lightness], [a], [b]), with [alpha].
Color _fromOklab(double lightness, double a, double b, double alpha) {
  double cube(double x) => x * x * x;
  double encode(double c) =>
      (c <= 0.0031308 ? 12.92 * c : 1.055 * math.pow(c, 1 / 2.4) - 0.055).clamp(
        0.0,
        1.0,
      );
  final l = cube(lightness + 0.3963377774 * a + 0.2158037573 * b);
  final m = cube(lightness - 0.1055613458 * a - 0.0638541728 * b);
  final s = cube(lightness - 0.0894841775 * a - 1.2914855480 * b);
  return Color.from(
    alpha: alpha,
    red: encode(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s),
    green: encode(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s),
    blue: encode(-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s),
  );
}
