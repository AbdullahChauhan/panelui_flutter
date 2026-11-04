import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// A step on PanelUI's type scale, with the line height it is paired with.
///
/// The values are Tailwind's (`text-xs` … `text-4xl`), which is what PanelUI
/// is styled with, so a size here renders the same box as its React Native
/// counterpart.
enum PanelTextSize {
  /// 12 / 16.
  xs(12, 16),

  /// 14 / 20.
  sm(14, 20),

  /// 16 / 24.
  base(16, 24),

  /// 18 / 28.
  lg(18, 28),

  /// 20 / 28.
  xl(20, 28),

  /// 24 / 32.
  xxl(24, 32),

  /// 30 / 36.
  xxxl(30, 36),

  /// 36 / 40.
  xxxxl(36, 40);

  const PanelTextSize(this.fontSize, this.lineHeight);

  /// Font size in logical pixels.
  final double fontSize;

  /// Line height in logical pixels.
  final double lineHeight;
}

/// Font families and the text styles built from them.
///
/// PanelUI draws in the platform's own face by default, so [fontFamily] is
/// null unless an app supplies one. Line height is distributed evenly above
/// and below the glyphs, which is how CSS and React Native place it; Flutter's
/// default puts it all above and pushes text below the middle of its box.
@immutable
class PanelTypography with Diagnosticable {
  /// Creates a typography set.
  const PanelTypography({
    this.fontFamily,
    this.fontFamilyFallback,
    this.monoFamily = 'monospace',
    this.monoFamilyFallback = const ['Menlo', 'Consolas', 'Roboto Mono'],
  });

  /// The body and UI font. Null uses the platform default.
  final String? fontFamily;

  /// Fallbacks for [fontFamily].
  final List<String>? fontFamilyFallback;

  /// The monospace font used by code and numeric displays.
  final String monoFamily;

  /// Fallbacks for [monoFamily].
  final List<String> monoFamilyFallback;

  /// A style at [size] with its paired line height.
  TextStyle style(
    PanelTextSize size, {
    FontWeight weight = FontWeight.w400,
    Color? color,
  }) {
    return TextStyle(
      inherit: false,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      fontSize: size.fontSize,
      height: size.lineHeight / size.fontSize,
      leadingDistribution: TextLeadingDistribution.even,
      fontWeight: weight,
      color: color,
      textBaseline: TextBaseline.alphabetic,
      decoration: TextDecoration.none,
    );
  }

  /// A style at an arbitrary [fontSize] that keeps the font's own line
  /// height, for a control whose box height is fixed (a button or a field).
  TextStyle sized(
    double fontSize, {
    FontWeight weight = FontWeight.w400,
    Color? color,
  }) {
    return TextStyle(
      inherit: false,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      fontSize: fontSize,
      leadingDistribution: TextLeadingDistribution.even,
      fontWeight: weight,
      color: color,
      textBaseline: TextBaseline.alphabetic,
      decoration: TextDecoration.none,
    );
  }

  /// A monospace style at [size].
  TextStyle mono(
    PanelTextSize size, {
    FontWeight weight = FontWeight.w400,
    Color? color,
  }) {
    return style(
      size,
      weight: weight,
      color: color,
    ).copyWith(fontFamily: monoFamily, fontFamilyFallback: monoFamilyFallback);
  }

  /// Returns a copy with the given fields replaced.
  PanelTypography copyWith({
    String? fontFamily,
    List<String>? fontFamilyFallback,
    String? monoFamily,
    List<String>? monoFamilyFallback,
  }) {
    return PanelTypography(
      fontFamily: fontFamily ?? this.fontFamily,
      fontFamilyFallback: fontFamilyFallback ?? this.fontFamilyFallback,
      monoFamily: monoFamily ?? this.monoFamily,
      monoFamilyFallback: monoFamilyFallback ?? this.monoFamilyFallback,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PanelTypography &&
        other.fontFamily == fontFamily &&
        listEquals(other.fontFamilyFallback, fontFamilyFallback) &&
        other.monoFamily == monoFamily &&
        listEquals(other.monoFamilyFallback, monoFamilyFallback);
  }

  @override
  int get hashCode => Object.hash(
    fontFamily,
    Object.hashAll(fontFamilyFallback ?? const []),
    monoFamily,
    Object.hashAll(monoFamilyFallback),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('fontFamily', fontFamily))
      ..add(StringProperty('monoFamily', monoFamily));
  }
}

/// Elevation shadows, on Tailwind's scale.
@immutable
class PanelShadows with Diagnosticable {
  /// Creates a shadow scale.
  const PanelShadows({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
  });

  /// Tailwind's `shadow-xs` … `shadow-xl`.
  static const PanelShadows standard = PanelShadows(
    xs: [
      BoxShadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0x0D000000)),
    ],
    sm: [
      BoxShadow(offset: Offset(0, 1), blurRadius: 3, color: Color(0x1A000000)),
      BoxShadow(
        offset: Offset(0, 1),
        blurRadius: 2,
        spreadRadius: -1,
        color: Color(0x1A000000),
      ),
    ],
    md: [
      BoxShadow(
        offset: Offset(0, 4),
        blurRadius: 6,
        spreadRadius: -1,
        color: Color(0x1A000000),
      ),
      BoxShadow(
        offset: Offset(0, 2),
        blurRadius: 4,
        spreadRadius: -2,
        color: Color(0x1A000000),
      ),
    ],
    lg: [
      BoxShadow(
        offset: Offset(0, 10),
        blurRadius: 15,
        spreadRadius: -3,
        color: Color(0x1A000000),
      ),
      BoxShadow(
        offset: Offset(0, 4),
        blurRadius: 6,
        spreadRadius: -4,
        color: Color(0x1A000000),
      ),
    ],
    xl: [
      BoxShadow(
        offset: Offset(0, 20),
        blurRadius: 25,
        spreadRadius: -5,
        color: Color(0x1A000000),
      ),
      BoxShadow(
        offset: Offset(0, 8),
        blurRadius: 10,
        spreadRadius: -6,
        color: Color(0x1A000000),
      ),
    ],
  );

  /// `shadow-xs`.
  final List<BoxShadow> xs;

  /// `shadow-sm`, the resting lift of buttons, cards and switch thumbs.
  final List<BoxShadow> sm;

  /// `shadow-md`.
  final List<BoxShadow> md;

  /// `shadow-lg`, dialogs and toasts.
  final List<BoxShadow> lg;

  /// `shadow-xl`.
  final List<BoxShadow> xl;

  /// Interpolates between two shadow scales.
  static PanelShadows lerp(PanelShadows a, PanelShadows b, double t) {
    if (identical(a, b)) return a;
    return PanelShadows(
      xs: BoxShadow.lerpList(a.xs, b.xs, t)!,
      sm: BoxShadow.lerpList(a.sm, b.sm, t)!,
      md: BoxShadow.lerpList(a.md, b.md, t)!,
      lg: BoxShadow.lerpList(a.lg, b.lg, t)!,
      xl: BoxShadow.lerpList(a.xl, b.xl, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PanelShadows &&
        listEquals(other.xs, xs) &&
        listEquals(other.sm, sm) &&
        listEquals(other.md, md) &&
        listEquals(other.lg, lg) &&
        listEquals(other.xl, xl);
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(xs),
    Object.hashAll(sm),
    Object.hashAll(md),
    Object.hashAll(lg),
    Object.hashAll(xl),
  );
}
