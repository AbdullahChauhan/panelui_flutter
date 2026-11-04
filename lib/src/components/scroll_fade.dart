import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../theme/panel_theme.dart';

/// Fades the edges of a scrollable.
///
/// Content running past a boundary reads better fading out than cut off, and
/// the fade doubles as a sign: an edge that fades has more content behind it.
/// Each fade appears as the content scrolls away from its edge, fully shown
/// [fadeInDistance] in, and neither shows when the content fits.
///
/// ```dart
/// PanelScrollFade(
///   child: ListView(scrollDirection: Axis.horizontal, children: chips),
/// )
/// ```
///
/// The fades follow the scroll without rebuilding the scrollable.
class PanelScrollFade extends StatefulWidget {
  /// Fades the edges of the scrollable [child].
  const PanelScrollFade({
    super.key,
    required this.child,
    this.size = 48,
    this.start = true,
    this.end = true,
    this.color,
    this.fadeInDistance = 24,
  });

  /// A scrollable: a `ListView`, a `SingleChildScrollView`, a `GridView`. The
  /// fades take its axis and direction from it.
  final Widget child;

  /// Depth of each fade.
  final double size;

  /// Fade the leading edge. PanelUI's `edges: 'end'` is this off.
  final bool start;

  /// Fade the trailing edge. PanelUI's `edges: 'start'` is this off.
  final bool end;

  /// The colour the fade resolves to, normally whatever is behind the
  /// scrollable. Defaults to the `background` token. It is drawn opaque at
  /// the edge whatever its alpha.
  final Color? color;

  /// How far the content has to scroll from an edge before that edge's fade
  /// is fully shown.
  final double fadeInDistance;

  @override
  State<PanelScrollFade> createState() => _PanelScrollFadeState();
}

class _PanelScrollFadeState extends State<PanelScrollFade> {
  final ValueNotifier<double> _leading = ValueNotifier(0);
  final ValueNotifier<double> _trailing = ValueNotifier(0);
  Axis _axis = Axis.vertical;
  bool _reversed = false;

  @override
  void dispose() {
    _leading.dispose();
    _trailing.dispose();
    super.dispose();
  }

  bool _handle(ScrollMetrics metrics, int depth) {
    if (depth != 0) return false;
    final distance = widget.fadeInDistance;
    _leading.value = ((metrics.pixels - metrics.minScrollExtent) / distance)
        .clamp(0.0, 1.0);
    _trailing.value = ((metrics.maxScrollExtent - metrics.pixels) / distance)
        .clamp(0.0, 1.0);
    final reversed = axisDirectionIsReversed(metrics.axisDirection);
    if (metrics.axis != _axis || reversed != _reversed) {
      setState(() {
        _axis = metrics.axis;
        _reversed = reversed;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final color = (widget.color ?? PanelTheme.of(context).colors.background)
        .withValues(alpha: 1);
    Widget fade(ValueNotifier<double> opacity, {required bool leading}) =>
        _EdgeFade(
          opacity: opacity,
          color: color,
          size: widget.size,
          axis: _axis,
          // A reversed scrollable leads from the bottom or the right.
          atStartSide: leading != _reversed,
        );

    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => _handle(n.metrics, n.depth),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => _handle(n.metrics, n.depth),
        child: Stack(
          children: [
            widget.child,
            if (widget.start) fade(_leading, leading: true),
            if (widget.end) fade(_trailing, leading: false),
          ],
        ),
      ),
    );
  }
}

/// One edge's gradient, opaque at the edge and clear inwards, shown as far
/// as the content has scrolled away from that edge.
class _EdgeFade extends StatelessWidget {
  const _EdgeFade({
    required this.opacity,
    required this.color,
    required this.size,
    required this.axis,
    required this.atStartSide,
  });

  final ValueListenable<double> opacity;
  final Color color;
  final double size;
  final Axis axis;

  /// Whether the fade sits on the top or left side rather than the bottom or
  /// right.
  final bool atStartSide;

  @override
  Widget build(BuildContext context) {
    final horizontal = axis == Axis.horizontal;
    final edge = horizontal
        ? (atStartSide ? Alignment.centerLeft : Alignment.centerRight)
        : (atStartSide ? Alignment.topCenter : Alignment.bottomCenter);
    final gradient = IgnorePointer(
      child: ValueListenableBuilder<double>(
        valueListenable: opacity,
        // A transparent stop of the same colour: a clear black would draw a
        // grey smear through the middle of the fade.
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: edge,
              end: -edge,
              colors: [color, color.withValues(alpha: 0)],
            ),
          ),
        ),
        builder: (context, value, child) =>
            Opacity(opacity: value, child: child),
      ),
    );
    return horizontal
        ? Positioned(
            top: 0,
            bottom: 0,
            width: size,
            left: atStartSide ? 0 : null,
            right: atStartSide ? null : 0,
            child: gradient,
          )
        : Positioned(
            left: 0,
            right: 0,
            height: size,
            top: atStartSide ? 0 : null,
            bottom: atStartSide ? null : 0,
            child: gradient,
          );
  }
}
