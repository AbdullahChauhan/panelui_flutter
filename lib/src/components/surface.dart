import 'package:flutter/widgets.dart';

import '../theme/panel_theme.dart';

/// A step on the elevation ladder.
enum PanelSurfaceVariant {
  /// The `surface` token, one step from the background.
  primary,

  /// The `surfaceSecondary` token, two steps.
  secondary,

  /// The `surfaceTertiary` token, three steps.
  tertiary,

  /// No fill.
  transparent,
}

/// Inner spacing of a [PanelSurface].
enum PanelSurfacePadding {
  /// None, for a surface wrapping a bled image or a chart.
  none(0),

  /// 10pt.
  sm(10),

  /// 16pt, the default.
  md(16),

  /// 24pt.
  lg(24);

  const PanelSurfacePadding(this.value);

  /// The padding in logical pixels.
  final double value;
}

/// An elevated container.
///
/// The variants form a ladder rather than a palette: each step is one level
/// further from the background, so nesting surfaces builds depth without a
/// colour being chosen anywhere. Both the fill and the corner radius follow
/// the theme, so Moon's surfaces are tight and Grass's are soft.
///
/// ```dart
/// PanelSurface(
///   child: PanelSurface(
///     variant: PanelSurfaceVariant.secondary,
///     child: Text('Nested'),
///   ),
/// )
/// ```
class PanelSurface extends StatelessWidget {
  /// Creates a surface.
  const PanelSurface({
    super.key,
    required this.child,
    this.variant = PanelSurfaceVariant.primary,
    this.padding = PanelSurfacePadding.md,
    this.bordered = false,
    this.elevated = false,
    this.width,
    this.height,
  });

  /// The content.
  final Widget child;

  /// The step on the ladder.
  final PanelSurfaceVariant variant;

  /// Inner spacing.
  final PanelSurfacePadding padding;

  /// A hairline border, for a surface the same colour as what it sits on.
  final bool bordered;

  /// A soft shadow lifting the surface off the page.
  final bool elevated;

  /// An optional fixed width.
  final double? width;

  /// An optional fixed height.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final fill = switch (variant) {
      PanelSurfaceVariant.primary => c.surface,
      PanelSurfaceVariant.secondary => c.surfaceSecondary,
      PanelSurfaceVariant.tertiary => c.surfaceTertiary,
      PanelSurfaceVariant.transparent => const Color(0x00000000),
    };
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.all(padding.value),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(theme.radii.xxxl),
        border: bordered ? Border.all(color: c.border) : null,
        boxShadow: elevated ? theme.shadows.sm : null,
      ),
      child: child,
    );
  }
}
