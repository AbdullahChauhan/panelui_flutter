import 'package:flutter/widgets.dart';

import '../theme/panel_theme.dart';

/// How a keyboard focus ring is drawn. PanelUI's web package uses a handful
/// of rings; each is a style here.
@immutable
class PanelFocusRingStyle {
  /// Creates a ring style.
  const PanelFocusRingStyle({
    this.width = 3,
    this.gap = 0,
    this.opacity = 0.4,
    this.inside = false,
  });

  /// The web button's ring, and the default: 3pt in the `ring` colour at 40%,
  /// against the edge (`focus-visible:ring-[3px] ring-ring/40`).
  static const PanelFocusRingStyle soft = PanelFocusRingStyle();

  /// Most web controls' ring: 2pt in the full `ring` colour, held 2pt off the
  /// control by a band of the page background
  /// (`ring-2 ring-ring ring-offset-2 ring-offset-background`).
  static const PanelFocusRingStyle offset = PanelFocusRingStyle(
    width: 2,
    gap: 2,
    opacity: 1,
  );

  /// 2pt in the full `ring` colour, against the edge (`ring-2 ring-ring`).
  static const PanelFocusRingStyle tight = PanelFocusRingStyle(
    width: 2,
    opacity: 1,
  );

  /// 2pt in the full `ring` colour inside the edge, for a control its
  /// container clips: a joined segment, a tab.
  static const PanelFocusRingStyle inset = PanelFocusRingStyle(
    width: 2,
    opacity: 1,
    inside: true,
  );

  /// The ring's thickness.
  final double width;

  /// Clear space between the control and the ring, filled with the page
  /// background.
  final double gap;

  /// The share of the `ring` colour's opacity the ring is drawn at.
  final double opacity;

  /// Draws the ring inside the control's edge rather than outside it.
  final bool inside;

  @override
  bool operator ==(Object other) =>
      other is PanelFocusRingStyle &&
      other.width == width &&
      other.gap == gap &&
      other.opacity == opacity &&
      other.inside == inside;

  @override
  int get hashCode => Object.hash(width, gap, opacity, inside);
}

/// Draws a keyboard focus ring around [child] while [visible].
///
/// `PanelPressable` draws one round the whole control; use this directly to
/// ring a part of one instead, such as a radio's disc.
class PanelFocusRing extends StatelessWidget {
  /// Rings [child] in [style] while [visible].
  const PanelFocusRing({
    super.key,
    required this.visible,
    required this.borderRadius,
    required this.child,
    this.style = PanelFocusRingStyle.soft,
    this.color,
  });

  /// Whether the ring shows.
  final bool visible;

  /// The ring's corners, the control's own.
  final BorderRadius borderRadius;

  /// The control.
  final Widget child;

  /// How the ring is drawn.
  final PanelFocusRingStyle style;

  /// The ring's colour, used as given. Defaults to the `ring` token at the
  /// style's opacity.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (!visible) return child;
    final colors = PanelTheme.of(context).colors;
    final ring =
        color ?? colors.ring.withValues(alpha: colors.ring.a * style.opacity);

    Widget band(Widget child, Color color, double width, double strokeAlign) =>
        DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(
              color: color,
              width: width,
              strokeAlign: strokeAlign,
            ),
          ),
          child: child,
        );

    if (style.inside) {
      return band(child, ring, style.width, BorderSide.strokeAlignInside);
    }
    // A stroke aligned at 1 + 2·gap/width runs from `gap` to `gap + width`
    // outside the edge.
    final ringed = band(
      child,
      ring,
      style.width,
      1 + 2 * style.gap / style.width,
    );
    if (style.gap <= 0) return ringed;
    return band(
      ringed,
      colors.background,
      style.gap,
      BorderSide.strokeAlignOutside,
    );
  }
}
