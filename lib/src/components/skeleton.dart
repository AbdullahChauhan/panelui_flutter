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
/// readers unless [semanticLabel] is set. Label one skeleton per region, not
/// all of them.
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

  /// The width. Null fills the width available.
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

class _PanelSkeletonState extends State<PanelSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
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
      _pulse.repeat(reverse: true);
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
    final box = Container(
      width: widget.width ?? double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        color: theme.colors.skeleton,
        shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: widget.circle
            ? null
            : BorderRadius.circular(widget.radius ?? theme.radii.md),
      ),
    );
    final Widget animated = (_reduced ?? false)
        ? Opacity(opacity: 0.7, child: box)
        : FadeTransition(
            opacity: Tween<double>(
              begin: 1,
              end: 0.45,
            ).animate(CurvedAnimation(parent: _pulse, curve: panelEase)),
            child: box,
          );
    if (widget.semanticLabel == null) {
      return ExcludeSemantics(child: animated);
    }
    return Semantics(label: widget.semanticLabel, child: animated);
  }
}
