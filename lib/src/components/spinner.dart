import 'dart:math' as math;

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../theme/panel_motion.dart';
import '../theme/panel_theme.dart';

/// How big a [PanelSpinner] is.
enum PanelSpinnerSize {
  /// 16 × 16, a 2px ring.
  sm(16, 2),

  /// 24 × 24, a 2px ring: the default.
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
/// instead: a spinner that holds still reads as one that has hung, which is
/// the one thing a spinner exists to rule out.
///
/// A bare ring carries no words, so it is hidden from screen readers unless
/// [semanticLabel] is given, which announces it as a busy indicator. Leave it
/// unset where something nearby already says the wait is on, such as a
/// loading button; set it where the spinner is the only sign.
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

  /// The turning arc. Defaults to the `primary` token; set it where the
  /// spinner sits on a surface the theme did not choose, such as a photo.
  final Color? color;

  /// The ring under the arc. Defaults to the `muted` token. Worth setting
  /// with [color] on a dark or coloured surface, where the default ring can
  /// read as a second, fainter spinner.
  final Color? trackColor;

  /// What is loading, for screen readers.
  final String? semanticLabel;

  @override
  State<PanelSpinner> createState() => _PanelSpinnerState();
}

/// One full turn.
const Duration _spinDuration = Duration(milliseconds: 800);

/// One half of the fade that stands in for the turn under reduced motion.
const Duration _pulseDuration = Duration(milliseconds: 900);

/// How far down the fade goes: faint enough to read as a pulse, not a
/// flicker.
const double _pulseFloor = 0.35;

class _PanelSpinnerState extends State<PanelSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(vsync: this);
  late final Animation<double> _pulse = _progress
      .drive(CurveTween(curve: PanelCurves.inOutEase))
      .drive(Tween(begin: 1.0, end: _pulseFloor));
  bool? _reduced;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = panelReduceMotion(context);
    if (reduced == _reduced) return;
    _reduced = reduced;
    // The turn restarts where it began, since a full circle ends where it
    // started; the fade turns around, since a pulse that snapped back to full
    // would be the flicker the setting is there to avoid.
    _progress
      ..duration = reduced ? _pulseDuration : _spinDuration
      ..value = 0
      ..repeat(reverse: reduced);
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = PanelTheme.of(context).colors;
    final reduced = _reduced!;
    Widget ring = CustomPaint(
      size: Size.square(widget.size.dimension),
      painter: _SpinnerPainter(
        turn: reduced ? null : _progress,
        strokeWidth: widget.size.strokeWidth,
        color: widget.color ?? colors.primary,
        trackColor: widget.trackColor ?? colors.muted,
      ),
    );
    if (reduced) ring = FadeTransition(opacity: _pulse, child: ring);
    // It repaints every frame; keep that from spreading to the screen.
    ring = RepaintBoundary(child: ring);
    if (widget.semanticLabel == null) return ExcludeSemantics(child: ring);
    return Semantics(
      container: true,
      role: SemanticsRole.loadingSpinner,
      label: widget.semanticLabel,
      child: ring,
    );
  }
}

/// The track and the arc. It repaints from [turn] without a rebuild.
class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter({
    required this.turn,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
  }) : super(repaint: turn);

  /// How far round the arc has turned, 0 to 1. Null holds it at the top.
  final Animation<double>? turn;

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
    // The coloured top edge of a bordered circle (`border-t-primary`): a
    // quarter of the ring, centred on twelve o'clock.
    canvas.drawArc(
      rect,
      -3 * math.pi / 4 + (turn?.value ?? 0) * 2 * math.pi,
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
