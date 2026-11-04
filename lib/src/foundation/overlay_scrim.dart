import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';

/// The layer behind a modal overlay, which makes the screen behind it recede.
///
/// PanelUI's `Scrim` primitive: a 50% black dim by default, or with [blur] a
/// frost, where the screen behind stays legible as shape and colour while
/// losing its detail. It takes no touches; the route's modal barrier above it
/// is what dismisses the overlay.
///
/// [progress] runs from 0 (gone) to 1 (fully in). The dim and the frost's
/// tint follow it as opacity, and the blur radius itself follows it rather
/// than a finished blur being faded in, the way PanelUI's progress-driven
/// scrim animates the blur's intensity.
///
/// Internal to the overlay components; not exported from the package.
class PanelOverlayScrim extends StatelessWidget {
  /// Creates a scrim drawn at [progress].
  const PanelOverlayScrim({
    super.key,
    required this.progress,
    this.blur = false,
  });

  /// How far in the scrim is, from 0 to 1. Values outside are clamped.
  final double progress;

  /// Frost the screen behind instead of dimming it.
  final bool blur;

  /// The dim, `bg-black/50`.
  static const Color dim = Color(0x80000000);

  /// The blur's standard deviation at full strength. PanelUI blurs at
  /// `expo-blur` intensity 24, which that package draws on the web as a
  /// `blur(4.8px)` backdrop filter.
  static const double blurSigma = 4.8;

  /// The frost's own tint, `expo-blur`'s default tint at intensity 24
  /// (white at 30% of 24%).
  static const Color frostTint = Color(0x12FFFFFF);

  /// The faint dim under the frost, `bg-black/10`, so it has something to
  /// sit on: a pure blur over a dark scene is nearly invisible.
  static const Color frostDim = Color(0x1A000000);

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);
    if (t == 0) return const SizedBox.expand();
    Widget layer;
    if (blur) {
      final sigma = blurSigma * t;
      layer = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: ColoredBox(
          color: frostTint.withValues(alpha: frostTint.a * t),
          child: ColoredBox(
            color: frostDim.withValues(alpha: frostDim.a * t),
            child: const SizedBox.expand(),
          ),
        ),
      );
    } else {
      layer = ColoredBox(
        color: dim.withValues(alpha: dim.a * t),
        child: const SizedBox.expand(),
      );
    }
    return IgnorePointer(child: ExcludeSemantics(child: layer));
  }
}
