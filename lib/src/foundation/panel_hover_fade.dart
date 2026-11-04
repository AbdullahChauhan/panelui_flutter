import 'package:flutter/widgets.dart';

import '../theme/panel_motion.dart';

/// Eases a control into and out of its hover look, the way PanelUI's web
/// package does with a CSS `transition`.
///
/// [builder] is told how far into its hover look the control is, from 0 at
/// rest to 1 under the pointer, eased on Tailwind's standard curve. Blend the
/// colours that change on hover by it with `panelLerpColor`. Whatever changes
/// for another reason, such as being selected, can still land at once.
class PanelHoverFade extends StatelessWidget {
  /// Creates a hover fade.
  const PanelHoverFade({
    super.key,
    required this.hovered,
    this.duration = PanelDurations.hover,
    required this.builder,
    this.child,
  });

  /// Whether the pointer is over the control.
  final bool hovered;

  /// How long the fade takes: the web class's `duration-*`, and Tailwind's
  /// 150ms where it names none.
  final Duration duration;

  /// Builds the control `hover` of the way into its hover look, with
  /// [child].
  final ValueWidgetBuilder<double> builder;

  /// The part of the control the hover leaves alone, built once.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: hovered ? 1 : 0),
      duration: duration,
      curve: PanelCurves.standard,
      builder: builder,
      child: child,
    );
  }
}
