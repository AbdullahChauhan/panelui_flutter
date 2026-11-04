import 'package:flutter/widgets.dart';

import '../theme/panel_theme.dart';

/// Fades the edges of a scrollable.
///
/// Content running past a boundary reads better fading out than cut off, and
/// the fade doubles as a sign: an edge that fades has more content behind it.
/// Each fade appears as the content scrolls away from its edge, fully shown
/// 24pt in, and neither shows when the content fits.
///
/// ```dart
/// PanelScrollFade(
///   child: ListView(scrollDirection: Axis.horizontal, children: chips),
/// )
/// ```
class PanelScrollFade extends StatefulWidget {
  /// Fades the edges of the scrollable [child].
  const PanelScrollFade({
    super.key,
    required this.child,
    this.size = 48,
    this.start = true,
    this.end = true,
    this.color,
  });

  /// A scrollable: a `ListView`, a `SingleChildScrollView`, a `GridView`.
  final Widget child;

  /// Depth of each fade.
  final double size;

  /// Fade the leading edge.
  final bool start;

  /// Fade the trailing edge.
  final bool end;

  /// The colour the fade resolves to, normally whatever is behind the
  /// scrollable. Defaults to the `background` token.
  final Color? color;

  @override
  State<PanelScrollFade> createState() => _PanelScrollFadeState();
}

class _PanelScrollFadeState extends State<PanelScrollFade> {
  static const _fadeInDistance = 24.0;

  double _leading = 0;
  double _trailing = 0;
  Axis _axis = Axis.vertical;
  AxisDirection _direction = AxisDirection.down;

  bool _handle(ScrollMetrics metrics) {
    final leading =
        ((metrics.pixels - metrics.minScrollExtent) / _fadeInDistance).clamp(
          0.0,
          1.0,
        );
    final trailing =
        ((metrics.maxScrollExtent - metrics.pixels) / _fadeInDistance).clamp(
          0.0,
          1.0,
        );
    if (leading != _leading ||
        trailing != _trailing ||
        metrics.axis != _axis ||
        metrics.axisDirection != _direction) {
      setState(() {
        _leading = leading;
        _trailing = trailing;
        _axis = metrics.axis;
        _direction = metrics.axisDirection;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? PanelTheme.of(context).colors.background;
    final clear = color.withValues(alpha: 0);
    final horizontal = _axis == Axis.horizontal;
    // Which physical side the scroll's leading edge is on.
    final reversed =
        _direction == AxisDirection.up || _direction == AxisDirection.left;

    Widget fade(bool atLeading, double opacity) {
      final atStartSide = atLeading != reversed;
      final begin = horizontal
          ? (atStartSide ? Alignment.centerLeft : Alignment.centerRight)
          : (atStartSide ? Alignment.topCenter : Alignment.bottomCenter);
      final gradient = IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: begin,
                end: -begin,
                colors: [color, clear],
              ),
            ),
          ),
        ),
      );
      return horizontal
          ? Positioned(
              top: 0,
              bottom: 0,
              width: widget.size,
              left: atStartSide ? 0 : null,
              right: atStartSide ? null : 0,
              child: gradient,
            )
          : Positioned(
              left: 0,
              right: 0,
              height: widget.size,
              top: atStartSide ? 0 : null,
              bottom: atStartSide ? null : 0,
              child: gradient,
            );
    }

    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => n.depth == 0 && _handle(n.metrics),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => n.depth == 0 && _handle(n.metrics),
        child: Stack(
          children: [
            widget.child,
            if (widget.start) fade(true, _leading),
            if (widget.end) fade(false, _trailing),
          ],
        ),
      ),
    );
  }
}
