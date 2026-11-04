import 'dart:ui' show ColorFilter, ImageFilter;

import 'package:flutter/widgets.dart';

import '../theme/panel_motion.dart';

/// The layer behind a modal overlay, which makes the screen behind it recede:
/// PanelUI's `Scrim` primitive.
///
/// It dims the screen with 50% black or, with [blur], frosts it, so the
/// screen stays legible as shape and colour while losing its detail. It takes
/// no touches and is hidden from screen readers: the route's modal barrier
/// above it is what dismisses the overlay.
///
/// As PanelUI's does, it fades itself in when it mounts, over 150ms when it
/// dims and 180ms when it frosts. That fade is multiplied by [opacity], the
/// opacity of the overlay layer the scrim sits in, which the overlay drives:
/// a dialog's own fade, or how far a sheet has risen.
///
/// The frost is `expo-blur`'s at the intensity PanelUI asks for (24), as that
/// package draws it on the web: a 4.8pt blur of the page saturated to 180%,
/// under a faint white tint, with PanelUI's 10% black on top. Its radius,
/// saturation and tint grow with the scrim's opacity rather than a finished
/// frost being faded in over the page, which would show the page sharp and
/// soft at once until it landed; this is how PanelUI's progress-driven scrim
/// moves its blur.
///
/// PanelUI draws an opaque surface instead of the frost for someone who has
/// Reduce Transparency on. Flutter does not report that setting, and PanelUI
/// treats a platform that cannot report it as one where blur is allowed, so
/// the frost is always drawn.
///
/// Internal to the overlay components; not exported from the package.
class PanelOverlayScrim extends StatefulWidget {
  /// Creates a scrim inside a layer at [opacity].
  const PanelOverlayScrim({
    super.key,
    required this.opacity,
    this.blur = false,
  });

  /// The opacity of the overlay layer around the scrim, from 0 to 1. Values
  /// outside are clamped.
  final double opacity;

  /// Frost the screen behind instead of dimming it.
  final bool blur;

  @override
  State<PanelOverlayScrim> createState() => _PanelOverlayScrimState();
}

class _PanelOverlayScrimState extends State<PanelOverlayScrim>
    with SingleTickerProviderStateMixin {
  /// The scrim's own fade-in: `FadeIn.duration(150)` for the dim and
  /// `FadeIn.duration(180)` for the frost, on Reanimated's default easing.
  late final AnimationController _fadeIn = AnimationController(
    vsync: this,
    duration: widget.blur
        ? const Duration(milliseconds: 180)
        : PanelDurations.fadeIn,
  )..forward();

  @override
  void dispose() {
    _fadeIn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _fadeIn,
          builder: (context, _) => _ScrimLayer(
            progress:
                widget.opacity.clamp(0.0, 1.0) *
                panelEase.transform(_fadeIn.value),
            blur: widget.blur,
          ),
        ),
      ),
    );
  }
}

/// The scrim drawn at [progress], from gone (0) to fully in (1).
class _ScrimLayer extends StatelessWidget {
  const _ScrimLayer({required this.progress, required this.blur});

  final double progress;
  final bool blur;

  /// The dim, `bg-black/50`.
  static const Color _dim = Color.from(alpha: 0.5, red: 0, green: 0, blue: 0);

  /// The frost's blur at full strength. `expo-blur` draws intensity 24 on the
  /// web as `blur(4.8px)`, a Gaussian of that standard deviation.
  static const double _frostSigma = 4.8;

  /// The frost's saturation at full strength, `expo-blur`'s `saturate(180%)`.
  static const double _frostSaturation = 1.8;

  /// The frost's own tint: `expo-blur`'s default tint at intensity 24, white
  /// at 30% of 24%.
  static const Color _frostTint = Color.from(
    alpha: 0.3 * 0.24,
    red: 1,
    green: 1,
    blue: 1,
  );

  /// The faint dim over the frost, `bg-black/10`, so it has something to sit
  /// on: a pure blur over a dark scene is nearly invisible.
  static const Color _frostDim = Color.from(
    alpha: 0.1,
    red: 0,
    green: 0,
    blue: 0,
  );

  @override
  Widget build(BuildContext context) {
    if (progress <= 0) return const SizedBox.expand();
    if (!blur) return _fill(_dim, const SizedBox.expand());
    final sigma = _frostSigma * progress;
    return BackdropFilter(
      filter: ImageFilter.compose(
        outer: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        inner: ColorFilter.matrix(
          _saturate(1 + (_frostSaturation - 1) * progress),
        ),
      ),
      child: _fill(_frostTint, _fill(_frostDim, const SizedBox.expand())),
    );
  }

  Widget _fill(Color color, Widget child) => ColoredBox(
    color: color.withValues(alpha: color.a * progress),
    child: child,
  );

  /// CSS's `saturate()` as a colour matrix, from the Filter Effects spec.
  static List<double> _saturate(double s) => [
    0.213 + 0.787 * s, 0.715 - 0.715 * s, 0.072 - 0.072 * s, 0, 0, //
    0.213 - 0.213 * s, 0.715 + 0.285 * s, 0.072 - 0.072 * s, 0, 0, //
    0.213 - 0.213 * s, 0.715 - 0.715 * s, 0.072 + 0.928 * s, 0, 0, //
    0, 0, 0, 1, 0,
  ];
}
