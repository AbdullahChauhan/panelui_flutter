import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/panel_motion.dart';
import '../theme/panel_theme.dart';

/// How big a [PanelSpinner] is.
enum PanelSpinnerSize {
  /// 16 × 16, a 2px ring.
  sm(16, 2),

  /// 24 × 24, a 2px ring.
  md(24, 2),

  /// 32 × 32, a 3px ring.
  lg(32, 3);

  const PanelSpinnerSize(this.dimension, this.strokeWidth);

  /// Width and height.
  final double dimension;

  /// Ring thickness.
  final double strokeWidth;
}

/// A rotating ring for work of unknown length.
///
/// A faint full ring (the track) with a quarter arc turning around it once
/// every 800ms. Under reduced motion it stops turning and fades in place
/// instead: a spinner that holds still reads as one that has hung.
///
/// A bare ring carries no words, so it is hidden from screen readers unless
/// [semanticLabel] is given. Leave it unset where something nearby already
/// says the wait is on, such as a loading button.
class PanelSpinner extends StatefulWidget {
  /// Creates a spinner.
  const PanelSpinner({
    super.key,
    this.size = PanelSpinnerSize.md,
    this.color,
    this.trackColor,
    this.semanticLabel,
  });

  /// The size.
  final PanelSpinnerSize size;

  /// The turning arc. Defaults to the `primary` token.
  final Color? color;

  /// The ring under the arc. Defaults to the `muted` token.
  final Color? trackColor;

  /// What is loading, for screen readers.
  final String? semanticLabel;

  @override
  State<PanelSpinner> createState() => _PanelSpinnerState();
}

class _PanelSpinnerState extends State<PanelSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  bool? _reduced;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = panelReduceMotion(context);
    if (reduced == _reduced) return;
    _reduced = reduced;
    _controller
      ..duration = Duration(milliseconds: reduced ? 900 : 800)
      ..repeat(reverse: reduced);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = PanelTheme.of(context).colors;
    final reduced = _reduced ?? false;
    final spinner = SizedBox.square(
      dimension: widget.size.dimension,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Opacity(
            opacity: reduced
                ? 1 - Curves.easeInOut.transform(t) * (1 - 0.35)
                : 1,
            child: CustomPaint(
              painter: _SpinnerPainter(
                turn: reduced ? 0 : t,
                strokeWidth: widget.size.strokeWidth,
                color: widget.color ?? colors.primary,
                trackColor: widget.trackColor ?? colors.muted,
              ),
            ),
          );
        },
      ),
    );
    if (widget.semanticLabel == null) return ExcludeSemantics(child: spinner);
    return Semantics(
      label: widget.semanticLabel,
      liveRegion: true,
      child: spinner,
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  const _SpinnerPainter({
    required this.turn,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
  });

  final double turn;
  final double strokeWidth;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawOval(rect, paint..color = trackColor);
    // The coloured top edge of a bordered circle: a quarter of the ring,
    // centred on twelve o'clock.
    canvas.drawArc(
      rect,
      -3 * math.pi / 4 + turn * 2 * math.pi,
      math.pi / 2,
      false,
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(_SpinnerPainter oldDelegate) =>
      oldDelegate.turn != turn ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}
