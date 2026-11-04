import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'panel_tokens.dart';
import 'panel_typography.dart';

/// Everything a PanelUI component reads from its theme: the colour tokens, the
/// radius scale, the type and the shadows.
///
/// It is a [ThemeExtension], so it can ride along inside a Material
/// [ThemeData] — which is what [toMaterialTheme] produces — and be animated by
/// [AnimatedTheme] when the app switches between light and dark. It can also
/// be provided on its own with a `PanelTheme` widget.
@immutable
class PanelThemeData extends ThemeExtension<PanelThemeData>
    with Diagnosticable {
  /// Creates a theme from its parts.
  const PanelThemeData({
    required this.brightness,
    required this.colors,
    this.radii = PanelRadii.panel,
    this.typography = const PanelTypography(),
    this.shadows = PanelShadows.standard,
  });

  /// Panel, the default family: neutral greys with a near-black accent.
  static const PanelThemeData panelLight = PanelThemeData(
    brightness: Brightness.light,
    colors: PanelColors.panelLight,
  );

  /// Panel in dark mode.
  static const PanelThemeData panelDark = PanelThemeData(
    brightness: Brightness.dark,
    colors: PanelColors.panelDark,
  );

  /// Moon: a lavender-blue accent, tight corners and a ladder of close greys.
  static const PanelThemeData moonLight = PanelThemeData(
    brightness: Brightness.light,
    colors: PanelColors.moonLight,
    radii: PanelRadii.moon,
  );

  /// Moon in dark mode.
  static const PanelThemeData moonDark = PanelThemeData(
    brightness: Brightness.dark,
    colors: PanelColors.moonDark,
    radii: PanelRadii.moon,
  );

  /// Grass: a green accent on warm-neutral greys, with soft corners.
  static const PanelThemeData grassLight = PanelThemeData(
    brightness: Brightness.light,
    colors: PanelColors.grassLight,
    radii: PanelRadii.grass,
  );

  /// Grass in dark mode.
  static const PanelThemeData grassDark = PanelThemeData(
    brightness: Brightness.dark,
    colors: PanelColors.grassDark,
    radii: PanelRadii.grass,
  );

  /// Whether this is a light or a dark theme.
  final Brightness brightness;

  /// The semantic colour tokens.
  final PanelColors colors;

  /// The corner-radius scale.
  final PanelRadii radii;

  /// Font families and text styles.
  final PanelTypography typography;

  /// Elevation shadows.
  final PanelShadows shadows;

  /// Whether this is a dark theme.
  bool get isDark => brightness == Brightness.dark;

  @override
  PanelThemeData copyWith({
    Brightness? brightness,
    PanelColors? colors,
    PanelRadii? radii,
    PanelTypography? typography,
    PanelShadows? shadows,
  }) {
    return PanelThemeData(
      brightness: brightness ?? this.brightness,
      colors: colors ?? this.colors,
      radii: radii ?? this.radii,
      typography: typography ?? this.typography,
      shadows: shadows ?? this.shadows,
    );
  }

  @override
  PanelThemeData lerp(covariant PanelThemeData? other, double t) {
    if (other == null || identical(this, other)) return this;
    return PanelThemeData(
      brightness: t < 0.5 ? brightness : other.brightness,
      colors: PanelColors.lerp(colors, other.colors, t),
      radii: PanelRadii.lerp(radii, other.radii, t),
      typography: t < 0.5 ? typography : other.typography,
      shadows: PanelShadows.lerp(shadows, other.shadows, t),
    );
  }

  /// A Material [ThemeData] carrying this theme as an extension, with the
  /// tokens mapped onto its [ColorScheme] so Material widgets used beside
  /// PanelUI components share the palette.
  ThemeData toMaterialTheme({ThemeData? base}) {
    final c = colors;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.primaryForeground,
      secondary: c.primary,
      onSecondary: c.primaryForeground,
      tertiary: c.chart2,
      onTertiary: c.primaryForeground,
      error: c.destructive,
      onError: c.destructiveSolidForeground,
      surface: c.background,
      onSurface: c.foreground,
      onSurfaceVariant: c.mutedForeground,
      surfaceContainerLowest: c.background,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surfaceSecondary,
      surfaceContainerHighest: c.surfaceTertiary,
      outline: Color.alphaBlend(c.input, c.background),
      outlineVariant: Color.alphaBlend(c.border, c.background),
      inverseSurface: c.foreground,
      onInverseSurface: c.background,
      inversePrimary: c.primaryForeground,
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      surfaceTint: const Color(0x00000000),
    );
    final material = (base ?? ThemeData(brightness: brightness)).copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      cardColor: c.card,
      dividerColor: c.border,
      hintColor: c.mutedForeground,
      disabledColor: c.mutedForeground,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.foreground,
        selectionColor: c.primary.withValues(alpha: 0.24),
        selectionHandleColor: c.primary,
      ),
      extensions: [this],
    );
    if (typography.fontFamily == null) return material;
    return material.copyWith(
      textTheme: material.textTheme.apply(fontFamily: typography.fontFamily),
      primaryTextTheme: material.primaryTextTheme.apply(
        fontFamily: typography.fontFamily,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PanelThemeData &&
        other.brightness == brightness &&
        other.colors == colors &&
        other.radii == radii &&
        other.typography == typography &&
        other.shadows == shadows;
  }

  @override
  int get hashCode =>
      Object.hash(brightness, colors, radii, typography, shadows);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<Brightness>('brightness', brightness))
      ..add(DiagnosticsProperty<PanelColors>('colors', colors))
      ..add(DiagnosticsProperty<PanelRadii>('radii', radii))
      ..add(DiagnosticsProperty<PanelTypography>('typography', typography));
  }
}

/// A light and dark pair of themes that belong together.
///
/// PanelUI ships three: [panel], [moon] and [grass]. An app picks a family and
/// lets the platform (or the user) pick the brightness.
@immutable
class PanelThemeFamily {
  /// Creates a family from its two themes.
  const PanelThemeFamily({
    required this.id,
    required this.name,
    required this.light,
    required this.dark,
  });

  /// The default family.
  static const PanelThemeFamily panel = PanelThemeFamily(
    id: 'panel',
    name: 'Panel',
    light: PanelThemeData.panelLight,
    dark: PanelThemeData.panelDark,
  );

  /// The Moon family.
  static const PanelThemeFamily moon = PanelThemeFamily(
    id: 'moon',
    name: 'Moon',
    light: PanelThemeData.moonLight,
    dark: PanelThemeData.moonDark,
  );

  /// The Grass family.
  static const PanelThemeFamily grass = PanelThemeFamily(
    id: 'grass',
    name: 'Grass',
    light: PanelThemeData.grassLight,
    dark: PanelThemeData.grassDark,
  );

  /// Every built-in family, in display order.
  static const List<PanelThemeFamily> values = [panel, moon, grass];

  /// A stable identifier, for persisting the user's choice.
  final String id;

  /// A display name.
  final String name;

  /// The light theme.
  final PanelThemeData light;

  /// The dark theme.
  final PanelThemeData dark;

  /// The theme for [brightness].
  PanelThemeData resolve(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  @override
  bool operator ==(Object other) =>
      other is PanelThemeFamily &&
      other.id == id &&
      other.light == light &&
      other.dark == dark;

  @override
  int get hashCode => Object.hash(id, light, dark);
}
