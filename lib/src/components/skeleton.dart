import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../theme/panel_motion.dart';
import '../theme/panel_theme.dart';

/// A pulsing placeholder for content that has not arrived.
///
/// It fades between full and 45% opacity, 700ms each way. Under reduced
/// motion it holds still at 70%: unlike a spinner, a still skeleton does not
/// read as hung, because it is a shape where content will be.
///
/// A placeholder is a picture of absent content, so it is hidden from screen
/// readers unless [semanticLabel] is set, which announces it as a busy
/// indicator. Label one skeleton per region, not all of them.
///
/// ```dart
/// const PanelSkeleton(width: 160, height: 16)
/// const PanelSkeleton.circle(size: 40)
/// ```
class PanelSkeleton extends StatefulWidget {
  /// A rounded-rectangle placeholder.
  const PanelSkeleton({
    super.key,
    this.width,
    this.height,
    this.radius,
    this.semanticLabel,
  }) : circle = false;

  /// A circular placeholder, for an avatar.
  const PanelSkeleton.circle({
    super.key,
    required double size,
    this.semanticLabel,
  }) : width = size,
       height = size,
       radius = null,
       circle = true;

  /// The width. Null spans the width the parent gives.
  final double? width;

  /// The height.
  final double? height;

  /// The corner radius. Defaults to the theme's `md` step.
  final double? radius;

  /// Whether the placeholder is a circle.
  final bool circle;

  /// What is loading, for screen readers.
  final String? semanticLabel;

  @override
  State<PanelSkeleton> createState() => _PanelSkeletonState();
}

/// One half of the pulse.
const Duration _pulseDuration = Duration(milliseconds: 700);

/// How far down the pulse goes.
const double _pulseFloor = 0.45;

/// Where the pulse rests when it is not running: between its two ends, so a
/// still skeleton looks like the same placeholder rather than a solid block.
const double _restingOpacity = 0.7;

class _PanelSkeletonState extends State<PanelSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: _pulseDuration,
  );
  late final Animation<double> _opacity = _pulse
      .drive(CurveTween(curve: panelEase))
      .drive(Tween(begin: 1.0, end: _pulseFloor));
  bool? _reduced;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = panelReduceMotion(context);
    if (reduced == _reduced) return;
    _reduced = reduced;
    if (reduced) {
      _pulse.stop();
    } else {
      _pulse
        ..value = 0
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    // With no width, a childless Container spans the width its parent gives
    // and collapses where that is unbounded, as a view with no width does.
    final box = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: theme.colors.skeleton,
        shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: widget.circle
            ? null
            : BorderRadius.circular(widget.radius ?? theme.radii.md),
      ),
    );
    // A pulsing placeholder repaints every frame; keep that local.
    final Widget placeholder = RepaintBoundary(
      child: _reduced!
          ? Opacity(opacity: _restingOpacity, child: box)
          : FadeTransition(opacity: _opacity, child: box),
    );
    if (widget.semanticLabel == null) {
      return ExcludeSemantics(child: placeholder);
    }
    return Semantics(
      container: true,
      role: SemanticsRole.loadingSpinner,
      label: widget.semanticLabel,
      child: placeholder,
    );
  }
}
