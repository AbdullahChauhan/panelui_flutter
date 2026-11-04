import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../theme/panel_theme.dart';

/// A step on the elevation ladder.
enum PanelSurfaceVariant {
  /// The `surface` token, one step from the background: PanelUI's `default`.
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

  /// 16pt: PanelUI's `default`.
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
/// On iOS the corners are continuous (Apple's squircle), as PanelUI asks for
/// with `borderCurve: 'continuous'`; elsewhere they are circular arcs.
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

  /// The content, clipped to the surface's corners.
  final Widget child;

  /// The step on the ladder.
  final PanelSurfaceVariant variant;

  /// Inner spacing.
  final PanelSurfacePadding padding;

  /// A hairline border. A surface the same colour as what it sits on needs
  /// one to read as a plane of its own.
  final bool bordered;

  /// A soft shadow lifting the surface off the page. Off by default: a nested
  /// surface reads its depth from its fill, not from a shadow it would only
  /// cast onto its parent.
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
    final radius = theme.radii.xxxl;
    final side = bordered ? BorderSide(color: c.border) : BorderSide.none;
    // The content is clipped inside the border, as PanelUI's `overflow-hidden`
    // clips: a bled image clipped to the outer edge would paint over the
    // border where the corners curve.
    final inner = BorderRadius.circular(radius - side.width);
    final content = Padding(
      padding: EdgeInsets.all(padding.value),
      child: child,
    );
    final continuous = defaultTargetPlatform == TargetPlatform.iOS;
    return Container(
      width: width,
      height: height,
      decoration: ShapeDecoration(
        color: fill,
        shape: continuous
            ? RoundedSuperellipseBorder(
                side: side,
                borderRadius: BorderRadius.circular(radius),
              )
            : RoundedRectangleBorder(
                side: side,
                borderRadius: BorderRadius.circular(radius),
              ),
        shadows: elevated ? theme.shadows.sm : null,
      ),
      child: continuous
          ? ClipRSuperellipse(borderRadius: inner, child: content)
          : ClipRRect(borderRadius: inner, child: content),
    );
  }
}
